# Lab-Firewall-Functions

The Azure Firewall is a relatively expensive resource in Azure.  Using Azure Firewall in lab accounts can result in cost overruns.  I use my lab to simulate my customer environments that have secure Hub-and-Spoke topology.  I can have many Hub-and-Spoke workloads in my lab.  This can result in multiple Azure Firewalls that are required to be functional before any activity in the lab can occur.  The Azure Firewall has the capability of being deallocated to end platform billing.  However, the process cannot be performed using the Azure Portal, is cumbersome and not very scalable.  Therefore I have constructed a series of Azure Functions that perform functions needed to bring Azure Firewalls back online or take them out of productions as desired.  Further I wanted the ability to start the firewalls prior to logging into a Portal or other development tools so the environment will be functional by the time I'm ready for testing.  

I have developed the functions to query the entire subscription for all firewalls, and then test them for their state and their readiness for changes.  Changes cannot be performed when an Azure Firewall is in the state of "updating."  Some updates take 8-20 minutes.  There are 5 functions that are developed:

1. Status
1. Deallocate
1. Allocate
1. Toggle
1. Dailydeallocate

The first 4 functions are triggered by HTTP calls to the API exposed for Azure Functions.  The last one is a TIMED trigger function that ensures the deallocation of all firewalls in the subscription at each timed occurrence.  To ensure costs are minimized in my lab, I've set the timer to occur daily at 9:00pm.   HTTP triggered functions allow me to have a link in a document or OneNote with one click for each of the functions.

The functions are written in Powershell.  At this time, there is no capability for allocation/deallocation in Az CLI and no API calls to do this without re-deploying the entire firewall.  To allow the Azure Function to have permissions to change the firewalls, it is configured with a Managed Identity.  That Managed Identity must have Contributor role permission for the subscription.  The Azure Function is deployed with a Consumption model Application Service Plan and operates with the lowest cost configuration.

Each function initially connects with the Managed Identity to perform its tasks.  Then it obtains the configuration information for all the firewalls within the subscription.  Next, for each of the firewalls it determines if the firewall's provisioning state is "Succeeded." This is the only state in which changes can be made.  Next it determines the whether the firewall is able to allocated and able to process packets, or if it has been deallocated.  The presence of a Firewall Private IP is used to determine the allocation state.  The allocation or deallocation process can take between 3-20 minutes.  These long running azure platform calls are placed in the background.  This is needed as the Azure Function API has a response timeout of 4 minutes.  This is inherent in the API processing for the platform and is independent of the functionTimeout configured for any function.  Once the long running processes are spawned, the API returns information about the firewalls and the actions taken.

## Functions

The functions perform these activities.

### Status

For the Status function, the API call returns the provisioning state and allocation state for all firewalls in the subscription.  It also lists any background processes that may be associated with the firewall state.

### Deallocate

The Deallocate function is used to deallocate all firewalls in the subscription.  The API returns the provisioning state, allocation state and the action performed.   It also lists any background processes that may be associated with changing the firewall state.

### Allocate

The Allocate function is used to allocate all firewalls in the subscription.  The API returns the provisioning state, allocation state and the action performed.   It also lists any background processes that may be associated with changing the firewall state.

### Toggle

The Toggle function changes the allocation state for each of the firewalls in a subscription.  If any firewall is allocated, it is deallocated.  As well, if any firewall is deallocated, it allocates it.  The API returns the provisioning state, allocation state and the action performed.   It also lists any background processes that may be associated with changing the firewall state.

### Dailydeallocate

This timer function is controlled by a configuration file for scheduling.  The timer in Azure is based on Universal Coordinated Time.  To have the function triggered every day at 9:00pm CDT, time is converted to  2:00 UTC and supplied as "0 0 2 * * *" in cron notation to repeat every day.  It is configured as "schedule" in the bindings found in the function.json file for the function deployment.  The processing is the same as Deallocate.  It deallocates any firewall that is in an allocated state.

## Development

The function was developed using VSCode.  The Microsoft published Azure Functions extension is used to package and deploy the function(s) into the Azure platform.  The code is available in Github [here.](https://github.com/jclem2000/Lab-Firewall-Functions)

The Github Repo contains instructions for deployment and information about each of the functions.  More information is [here](azfwfunctions/README.md)
