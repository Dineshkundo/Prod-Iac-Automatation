@description('Configuration object for the SQL setup')
param sqlConfig object
@secure()
@description('Storage container path for vulnerability assessments (e.g., https://<storageaccount>.blob.core.windows.net/<container>)')
param vulnerabilityAssessmentsStoragePath string = ''

@description('Optional suffix for tagging (e.g., dev, qa, prod)')
param tagSuffix string = ''

// =====================================================================================
// 1️⃣ SQL Server
// =====================================================================================
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlConfig.serverName
  location: sqlConfig.location
  tags: union(sqlConfig.tags, {
    Environment: tagSuffix
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlConfig.adminLogin
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// =====================================================================================
// 2️⃣ SQL Server Firewall Rules (optional, if provided)
// =====================================================================================
@batchSize(1)
resource sqlFirewallRules 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = [for rule in sqlConfig.firewallRules: {
  parent: sqlServer
  name: rule.name
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

// =====================================================================================
// 3️⃣ SQL Database
// =====================================================================================
resource sqlDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: sqlConfig.databaseName
  location: sqlConfig.location
  sku: sqlConfig.databaseSku
  properties: sqlConfig.databaseProperties
  tags: sqlConfig.tags
}

// =====================================================================================
// 4️⃣ Vulnerability Assessment
// =====================================================================================
resource sqlDBVulnerability 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2024-05-01-preview' = {
  parent: sqlDB
  name: 'Default'
  properties: {
    recurringScans: sqlConfig.databaseVulnerabilityRecurringScans
    storageContainerPath: sqlConfig.vulnerabilityAssessmentsStoragePath
  }
}

// =====================================================================================
// 5️⃣ Outputs
// =====================================================================================
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDB.name
output sqlServerIdentityPrincipalId string = sqlServer.identity.principalId
