# namespace for Azure Function execution
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Parse $Request for parameters
$funcName = $Request.Params.funcName
$fwName = $Request.Params.fwName

# Get User Assigned Managed Identity
Connect-AzAccount -Identity 

# Write to the Azure Functions log stream.
Write-Host "This HTTP triggered Azure function is beginning processing."
# Start the Web Response body
$body = "This HTTP triggered Azure function is beginning processing."
$body += "`n"
$body += "  Function Name: "
$body += $funcName
$body += ", Firewall Name: "
$body += $fwName
$body += "`n"

    
# Get all Firewalls in the Subscription
if ($fwName -ne "all") {
    $fws = Get-AzFirewall -Name $fwName
}
else {
    $fws = Get-AzFirewall
}

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
            Write-Host "    Firewall has Private IP.  Firewall is Allocated."
            $body += "    Firewall has Private IP.  Firewall is Allocated."
            $body += "`n"
        }
        else {
            Write-Host "    Firewall does not have Private IP.  Firewall is Deallocated."
            $body += "    Firewall does not have Private IP.  Firewall is Deallocated."
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
}

# Push Web Response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })          
