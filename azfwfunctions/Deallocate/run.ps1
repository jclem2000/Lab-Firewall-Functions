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
    
# Get all Firewalls in the Resource Group
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

            Write-Host "  Schedule change to Firewall."
            $body += "  Schedule change to Firewall."
            $body += "`n"
                
            Set-AzFirewall -AzureFirewall $fw -AsJob
                
            Write-Host "    Firewall change scheduled."
            $body += "    Firewall change scheduled."
            $body += "`n"
        }
        else {
            Write-Host "    Firewall does not have Private IP."
            Write-Host "      Firewall already Deallocated."
            $body += "    Firewall does not have Private IP.  Firewall already Deallocated."
            $body += "`n"
        }
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