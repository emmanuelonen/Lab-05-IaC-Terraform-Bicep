targetScope = 'subscription'

param location string = 'eastus'
param environment string = 'prod'
param rgName string = 'rg-bicep-enterprise-${environment}-${location}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: {
    Environment: 'Production'
    ManagedBy: 'Bicep'
    Project: 'Global Logistics Enterprise'
    Lab: 'Lab-05-IaC-Terraform-Bicep'
  }
}

module storageModule 'storage.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storageDeployment'
  params: {
    location: location
    environment: environment
  }
}

output deployedResourceGroup string = rg.name

// Nested file: bicep/storage.bicep
param location string
param environment string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stbicep${environment}94021'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountId string = storageAccount.id
