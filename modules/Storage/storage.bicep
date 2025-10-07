targetScope = 'resourceGroup'

@description('Storage configuration object')
param storageConfig object

@description('Tag suffix for resource tagging')
param tagSuffix string

// ==========================
// Compute dynamic IDs
// ==========================
var subnetIds = [
  for subnetName in storageConfig.subnetNames: resourceId('Microsoft.Network/virtualNetworks/subnets', storageConfig.vnetName, subnetName)
]

var factoryResourceIds = [
  for factoryName in storageConfig.factoryNames: resourceId('Microsoft.DataFactory/factories', factoryName)
]

// ==========================
// Generate valid storage account name
// ==========================
var maxBaseLength = 24 - 13 // 24 max - 13 from uniqueString
var baseName = toLower(substring(storageConfig.storageAccountName, 0, maxBaseLength))
var storageAccountNameUnique = '${baseName}${uniqueString(resourceGroup().id)}'

// ==========================
// Storage Account
// ==========================
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountNameUnique
  location: storageConfig.location
  sku: { name: storageConfig.sku.name }
  kind: storageConfig.kind
  identity: { type: 'SystemAssigned' }
  tags: union(storageConfig.tags, {
    Environment: tagSuffix
    Project: 'Storage'
    CreatedBy: 'iac-bicep'
  })
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    largeFileSharesState: 'Enabled'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    accessTier: storageConfig.accessTier
    encryption: {
      services: {
        blob: { keyType: 'Account', enabled: true }
        file: { keyType: 'Account', enabled: true }
        queue: { keyType: 'Account', enabled: true }
        table: { keyType: 'Account', enabled: true }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        for ip in storageConfig.allowedIpAddresses: {
          value: ip
        }
      ]
      virtualNetworkRules: [
        for subnetId in subnetIds: {
          id: subnetId
        }
      ]
      resourceAccessRules: [
        for factoryId in factoryResourceIds: {
          tenantId: subscription().tenantId
          resourceId: factoryId
        }
      ]
    }
  }
}

// ==========================
// Blob Service & Containers
// ==========================
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = [
  for containerName in storageConfig.blobContainers: {
    parent: blobService
    name: containerName
    properties: {
      publicAccess: 'None'
    }
  }
]

// ==========================
// File Service & Shares
// ==========================
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' = [
  for shareName in storageConfig.fileShares: {
    parent: fileService
    name: shareName
    properties: {
      accessTier: 'TransactionOptimized'
      shareQuota: 102400
      enabledProtocols: 'SMB'
    }
  }
]

// ==========================
// Outputs
// ==========================
output storageAccountResourceId string = storageAccount.id
output storageAccountName string = storageAccount.name
output principalId string = storageAccount.identity.principalId
output tags object = storageAccount.tags
output location string = storageAccount.location
output sku object = storageAccount.sku
output kind string = storageAccount.kind
