# azfwfunctions

An Azure HTTP triggered Powershell function to provide status and control for allocating or deallocating Azure Firewalls.

## Overview

This folder contains the Azure Functions that are used to manage firewalls.  Each function searches the Subscription for all Azure Firewalls.  The resource is named "azfwfunctions" for this document.  The function app has a Managed Identity that has Contributor rights to the Subscription.  

## Deployment

Instructions on deploying an Azure Function from VSCode is available in Microsoft learning [here.](https://learn.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=powershell)

## Using the Functions

The functions are triggered by HTTP requests or by timer.  The functions are secured by a default function key.  The functions are written in Powershell.
Functions reside in an Azure Function resource.  

There are five API functions defined:

- Allocate
- Dailydeallocate
- Deallocate
- Status
- Toggle

### Allocate

This function sets the firewalls found to allocated.

```text
https://azfwfunctions.azurewebsites.net/api/allocate?code=[default function key]
```

### Dailydeallocate

This is a Timer function set to 02:00 UTC (9:00pm CDT) that will deallocate the firewalls found.  Timer configuration is found in the [function.json](Deallocate/function.json) file in the Dailydeallocate folder.

### Deallocate

This function sets the firewalls found to deallocated.

```text
https://azfwfunctions.azurewebsites.net/api/deallocate?code=[default function key]
```

### Status

This function returns the status of the firewalls found.

```text
https://azfwfunctions.azurewebsites.net/api/status?code=[default function key]
```

### Toggle

This function toggles the allocation state of the the firewalls found.

```text
https://azfwfunctions.azurewebsites.net/api/toggle?code=[default function key]
```
