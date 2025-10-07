targetScope = 'resourceGroup'

@description('Key Vault name')
param vaultName string

@description('Location for Key Vault')
param location string = resourceGroup().location

@description('Sku name: Standard or Premium')
param skuName string = 'standard'

@description('Enable RBAC authorization on vault (recommended)')
param enableRbac bool = true

@description('Enable purge protection (recommended for production)')
param enablePurgeProtection bool = true

@description('Soft delete retention days')
param softDeleteRetentionDays int = 90

@description('Optional virtual network rules array of subnet resourceIds')
param virtualNetworkRules array = []

@description('Optional explicit access policies if you prefer policy model (not used with RBAC)')
param accessPolicies array = []

resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: vaultName
  location: location
  tags: {
    environment: 'prod'
    owner: 'platform'
  }
  properties: {
    sku: {
      family: 'A'
      name: toUpper(skuName)
    }
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: [ for v in virtualNetworkRules: { id: v } ]
    }
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbac
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVaultLocation string = keyVault.location
