# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

Write-Host "Time trigger function to deallocate Azure Firewall is starting."

$fws = Get-AzFirewall

# Process each Firewall
foreach ($fw in $fws) {
    Write-Host "Resource Group: "$fw.ResourceGroupName
    Write-Host "  Firewall: "$fw.Name
    if ($fw.provisioningState -eq "Succeeded") {
        Write-Host "  Firewall in Succeeded state."
        $properState = $true
    }
    else {
        Write-Host "  Firewall not in Succeeded state."
        $properState = $false
    }
    if ($properState) {
        if ($fw.IpConfigurations.PrivateIpAddress) {
            Write-Host "    Firewall has Private IP."
            Write-Host "      Deallocating Firewall."
            $fw.Deallocate()

            Write-Host "  Schedule change to Firewall."
                
            Set-AzFirewall -AzureFirewall $fw -AsJob
                
            Write-Host "    Firewall change scheduled."
        }
        else {
            Write-Host "    Firewall does not have Private IP."
            Write-Host "      Firewall already Deallocated."
        }
    }
}
 
$jobstats = Get-Job
if ($null -ne $jobstats) {
    Write-Host "Scheduled Job Status"
    foreach ($job in $jobstats) {
        Write-Host $job.name" "$job.state
    }
    Write-Host "Use togglefw/status API to check firewall state(s) in 3-10 minutes."
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
