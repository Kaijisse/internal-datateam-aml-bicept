<#
This script serves as a wrapper script that sets some parameters and then runs the bicep deployments.This is customer specifici for AIMMS (i.e. variables set are for AIMMS databricks deployment)
/#>

[CmdletBinding(DefaultParametersetName = 'None')]
param(
    [string] [Parameter(Mandatory = $true)] $tenantID = "b6b9252d-06ac-4ea3-8c02-f52b5c7dc792", 
    [string] [Parameter(Mandatory = $true)] $subscriptionID = "70c4df47-a533-4c74-9dc8-0537425cc325",
    [string] [Parameter(Mandatory = $true)] $location = "westeurope",
    [string] [Parameter(Mandatory = $true)] $environmentType = "dev"
)


<# Deployment scripts (PowerShell) to load #>
$Path = "$PSScriptRoot\PowerShell\"
Get-ChildItem -Path $Path -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

$deploymentID = (New-Guid).Guid

<# Set Variables #>
az account set --subscription $subscriptionID --output none
if (!$?) {
    Write-Host "Something went wrong while setting the correct subscription. Please check and try again." -ForegroundColor Red
}

# Run section
CheckPermissions


<# deployment timer start #>
$location = $location.ToLower() -replace " ", ""
$starttime = [System.DateTime]::Now
$deployKV = $true
$deployPE = $true

Write-Host "  Running a Day One Bicep deployment with ID: '$deploymentID' for Environment: '$environmentType' with a 'WhatIf' check." -ForegroundColor Green
az deployment sub create `
    --name $deploymentID `
    --location $location `
    --template-file ./Bicep/mainadb.bicep `
    --parameters deployKV=$deployKV deployPE=$deployPE environmentType=$environmentType tenantId=$tenantId subscriptionId=$subscriptionID `
    --confirm-with-what-if `
    --output none
<# Deployment timer end #>
$endtime = [System.DateTime]::Now
$duration = $endtime - $starttime
Write-Host ('This deployment took : {0:mm} minutes {0:ss} seconds' -f $duration) -BackgroundColor Black  -ForegroundColor Magenta



