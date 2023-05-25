
@description('whether the Managed Private Endpoints need to be deployed or not')
param deployPE bool = true


@description('The tenant ID')
param tenantId string = ''

@description('The subscription ID')
param subscriptionId string = ''





// Create a short, unique suffix, that will be unique to each resource group
// The default 'uniqueString' function will return a 13 char string, here, we're taking 
// the first 4 - which will reduce the uniqueness, but increase readability
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)



// This file can only be deployed at a subscription scope
targetScope = 'subscription'

/*
//Parameters and variables with default values where appropriate.
*/
@description('Logged in user details. Passed in from parent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, Production, etc. Passed in from parent "deployNow.ps1" script.')
@allowed([
  'test'
  'dev'
  'prod'
])
param environmentName string = 'test'

@description('The customer name.')
param customerName string = 'kaijisse'

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
])
param location string = 'westeurope'

@description('Location shortcode. Used for end of resource names.')
param locationshortcode string = 'weu'

// Resource Tags
@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentName
  Customer: customerName
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

// Resource Group parameters

@description('Array of resource Groups.')
param resourceGroupArray array = [
  {
    name: 'rg-aml-${customerName}-${environmentName}-${locationshortcode}'
    location: location
  }
]


// Container Registry Parameters

// ACR
@description('The name of the Azure Container Registry used for AKS.')
@minLength(5)
@maxLength(50)
param acrName string = 'acr${customerName}${replace(environmentName, '-', '')}${locationshortcode}'

@description('The sku for container registry.')
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param acrSKU string = 'Premium'

//ctrl click and then it brings you to where you need to go. 

// Application INsights PArameters
@description('The name of the Azure Application Insights')
@minLength(5)
@maxLength(50)
param applicationInsightsName string = 'applicationInsights${customerName}${replace(environmentName, '-', '')}${locationshortcode}'

// Virtual Networking parameters

// AML Vnet
@description('The details needed for the AKS vNet. Configure to your needs.')
var AMLVNetConfiguration = {
  name: 'vnet-AML-${environmentName}-${location}'
  test: {
    VNetAddressPrefixes: [
      '10.100.0.0/16'
    ]
    Subnets: [
      {
        name: 'amlsubnet'
        addressPrefix: '10.100.1.0/24'
      }
      {
        name: 'aml-acr-pe-subnet'
        addressPrefix: '10.100.2.0/24'
      }     
    ]
  }

}

//SA parameters
@description('The name of Storage Account')
param SAName string = 'sa-${customerName}-${environmentName}-${locationshortcode}'


// Key Vault PArameters
@description('The name of the KeyVaults')
param keyVaults array = [
  {
    name: 'kv-${customerName}-${environmentName}-${locationshortcode}'
    PurgeProtection: false
    sku: 'standard'
    enableRbacAuthorization: false
  }
]
/**/

/// Modules /// 

//note
//the name before param's is the deployment name not the resource name
//the name in params is the name of teh resource

// Deploy required Resource Groups
module resourceGroups '../modules/Microsoft.Resources/resourceGroups/deploy.bicep' = [for (resourceGroup, i) in resourceGroupArray: {
  name: 'rg-${i}'
  params: {
    name: resourceGroup.name
    location: resourceGroup.location
    tags: tags
  }
}]


// VNET
module AMLVNet '../modules/Microsoft.Network/virtualNetworks/deploy.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'deploy-AML-VNet'
  params:{
    location: location
    tags: tags
    subnets: AMLVNetConfiguration[environmentName].Subnets
    addressPrefixes:AMLVNetConfiguration[environmentName].VNetAddressPrefixes
    name: AMLVNetConfiguration.name
  }

  dependsOn: resourceGroups
}

//ACRPrivateDNSName parameter
@description('The name of Storage Account')
param ACRPrivateDNSName string = 'ACRPrivateDNSName-${customerName}-${environmentName}-${locationshortcode}'

// ctrl space for variables list


module acrprivateDNS '../modules/Microsoft.Network/privateDnsZones/deploy.bicep'={
  scope: resourceGroup(resourceGroupArray[0].name)
  name: ACRPrivateDNSName
  params:{
    name: ACRPrivateDNSName
    location: location
    virtualNetworkLinks:[{
      registrationEnabled: true
      virtualNetworkResourceId: AMLVNet.outputs.resourceId
  }]
  }
  }


// Container Registry // 
module acr '../modules/Microsoft.ContainerRegistry/registries/deploy.bicep' ={
  name: acrName 
  scope: resourceGroup(resourceGroupArray[0].name)
  params: {
    name: acrName 
    location: location
    acrSku: acrSKU
    tags: tags
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            acrprivateDNS.outputs.resourceId
          ]
        }
        service: 'registry'
        subnetResourceId: AMLVNet.outputs.subnetResourceIds[1]
        }
      
    ]

  }
}



// Application Insights
module applicationInsights '../modules/Microsoft.Insights/components/deploy.bicep' = {
  name: applicationInsightsName
  scope: resourceGroup(resourceGroupArray[0].name)
  params:{
    name: applicationInsightsName
    location: location
    workspaceResourceId:workspace.outputs.id
    tags: tags
  }
}

// Storage
module storage '../modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: SAName
  params:{
    name: SAName
    location: location
    vnet: AMLVNet.outputs.details
    tags: tags
  }
}

// Deploy required Key Vaults
module KeyVault '../modules/Microsoft.KeyVault/vaults/deploy.bicep' = [for (keyVault, i) in keyVaults: {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'keyVault-${i}'
  params: {
    location: location
    name: keyVault.name
    tags: tags
    vaultSku: keyVault.sku
    enablePurgeProtection: keyVault.PurgeProtection
  }
  dependsOn: resourceGroups
}]




// ML Workspace
module workspace '../modules/Microsoft.MachineLearningServices/workspaces/deploy.bicep' = {
  name: 'ml-workspace-deployment'
  params:{
    workspaceName: 'ws-${baseResourceName}-${uniqueSuffix}'
    storageId: storage.outputs.storageAccountId
    appInsightsId: ai.outputs.appInsightsId
    containerRegistryId: acr.outputs.acrId
    keyVaultId: keyvault.outputs.keyVaultId
    vnet: vnet.outputs.details
    tags: tags
  }
}

output workspaceName string = workspace.outputs.name
output workspaceId string = workspace.outputs.id


