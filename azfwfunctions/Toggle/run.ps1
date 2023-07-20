# namespace for Azure Function execution
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Get User Assigned Managed Identity
Connect-AzAccount -Identity 

# Write to the Azure Functions log stream.
Write-Host "This HTTP triggered Azure function is beginning processing."
# Start the Web Response body
$body = "This HTTP triggered Azure function is beginning processing."
$body += "`n"

# Get all Firewalls in the Subscription
$fws = Get-AzFirewall

# Process each Firewall
foreach ($fw in $fws) {
    Write-Host "Resource Group: "$fw.ResourceGroupName
    $body += "`n"
    $body += "Resource Group: "
    $body += $fw.ResourceGroupName
    $body += "`n"
    Write-Host "  Firewall: "$fw.Name
    $body += "Firewall: "
    $body += $fw.Name
    $body += "`n"
    if ($fw.provisioningState -eq "Succeeded") {
        Write-Host "  Firewall in Succeeded state."
        $body += "  Firewall in Succeeded state."
        $body += "`n"
        $properState = $true
    }
    else {
        Write-Host "  Firewall not in Succeeded state."
        $body += "  Firewall not in Succeeded state."
        $body += "`n"
        $body += "    State: "
        $body += $fw.provisioningState
        $body += "`n"
        $properState = $false
    }
    if ($properState) {
        if ($fw.IpConfigurations.PrivateIpAddress) {
            Write-Host "    Firewall has Private IP."
            Write-Host "      Deallocating Firewall."
            $body += "    Firewall has Private IP.  Deallocating FW."
            $body += "`n"
            $fw.Deallocate()
        }
        else {
            Write-Host "    Firewall does not have Private IP."
            Write-Host "      Allocating Firewall."
            $body += "    Firewall does not have Private IP.  Allocating FW."
            $body += "`n"
            $vnets = Get-AzVirtualNetwork -ResourceGroupName $fw.ResourceGroupName
            foreach ($vnet in $vnets) {
                Write-Host "        VNet: "$vnet.Name
                $body += "        VNet: "
                $body += $vnet.Name
                $body += "`n"
                $pips = Get-AzPublicIpAddress -ResourceGroupName $fw.ResourceGroupName
                foreach ($pip in $pips) {
                    if ($pip.Name -match $fw.Name) {
                        if ($pip.Name -match "mgmt") {
                            $manip = $pip
                        }
                        else {
                            $ip = $pip
                        }
                    }
                }
            }
            Write-Host "        ip: "$ip.Name
            Write-Host "        manip: "$manip.Name
            $body += "        ip: "
            $body += $ip.Name
            $body += "`n"
            $body += "        manip: "
            $body += $manip.Name
            $body += "`n"
            
            $fw.Allocate($vnet, $ip, $manip)
        }

        # Perform write to Firewall after Web Response to avoid timeout
        Write-Host "  Schedule change to Firewall."
        $body += "  Schedule change to Firewall."
        $body += "`n"
            
        #Start-ThreadJob -ScriptBlock { Set-AzFirewall -AzureFirewall $using:fw }
        Set-AzFirewall -AzureFirewall $fw -AsJob
        
        Write-Host "    Firewall update scheduled in background."
        $body += "    Firewall update scheduled in background."
        $body += "`n"
    }
}

$jobstats = Get-Job
if ($null -ne $jobstats) {
    Write-Host "Scheduled Job Status"
    $body += "`n"
    $body += "Scheduled Job Status"
    $body += "`n"
    foreach ($job in $jobstats) {
        Write-Host $job.name" "$job.state
        $body += $job.name
        $body += " "
        $body += $job.state
        $body += "`n"
    }
    Write-Host "Use togglefw/status API to check firewall state(s) in 3-10 minutes."
    $body += "`n"
    $body += "Use togglefw/status API to check firewall state(s) in 3-10 minutes."
    $body += "`n"
}

# Push Web Response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })          
