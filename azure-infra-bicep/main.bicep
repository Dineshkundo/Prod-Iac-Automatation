// iac
// ├── Jenkinsfile
// ├── main.bicep
// ├── modules
// │   ├── aks.bicep
// │   ├── keyvault.bicep
// │   ├── network.bicep
// │   ├── storage.bicep
// │   ├── virtual-machine.bicep
// │   └── others
// └── parameters
//     ├── dev.parameters.json
//     ├── dev.vm.variables.json
//     ├── prod.parameters.json
//    ├── prod.vm.variables.json
// └── README.md
// └
// // // // ///////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

@allowed([
  'keyvault'
  'storage'
  'aks'
  'sql'
  'Jenkins-vm'
  'Matching-Service'
  'RHEL-PROD-KAFKA'
  'network'
  'RedhatServerUAT'
  'Matching-Service-QA-Backup'
  'Boomi_Integration'


])

@description('Target service to deploy')
param targetService string

@description('Azure region for deployment')
param location string


@description('Service to deploy')
param serviceName string

@description('Tag suffix (environment tag or similar)')
param tagSuffix string = 'prod'

@description('Flag to create a new Key Vault (true) or use existing (false)')
param createKeyVault bool = false

@description('Name of the Key Vault to create or reference')
param keyVaultName string = ' '  // e.g., 'myKeyVault'

@description('Configuration object for Key Vault (used only if createKeyVault = true)')
param keyVaultConfig object = {}

@description('Mapping of secret names inside Key Vault')
param secretNames object = {}

@description('VM configuration (non-sensitive)')
param vmConfig object = {}


@description('Array of VM configurations')
//param vmConfigs array = []

//
// 1) Optional: Create Key Vault if requested
//
module kvModule './modules/Keyvault/keyvault.bicep' = if (createKeyVault) {
  name: 'kvCreate'
  params: {
    vaultName: keyVaultName
    location: keyVaultConfig.location
    skuName: keyVaultConfig.skuName
    enableRbac: keyVaultConfig.enableRbac
    enablePurgeProtection: keyVaultConfig.enablePurgeProtection
    softDeleteRetentionDays: keyVaultConfig.softDeleteRetentionDays
    virtualNetworkRules: keyVaultConfig.virtualNetworkRules
    accessPolicies: keyVaultConfig.accessPolicies
  }
}




//
// 2) Jenkins VM Deployment
//

module jenkins './modules/virtual-machines/CODA-PROD-Jenkins.bicep' = if (serviceName == 'Jenkins-vm') {
  name: 'deployJenkinsVm'
  params: {
    vmConfig: vmConfig
    tagSuffix: tagSuffix
    keyVaultName: keyVaultName
    secretNames: secretNames
  }
}

//
// Outputs//


// ---------------------------------------
// Deploy Matching Service VMs
// ---------------------------------------
param vm array = []
var vmsToDeploy = serviceName == 'Matching-Service' ? vm : []
module MatchingServicePROD './modules/virtual-machines/MatchingService-PROD.bicep' = [for vm in vmsToDeploy: {
  name: 'deploy-${vm.name}-${tagSuffix}'
  params: {
    vmConfig: vm
    tagSuffix: tagSuffix
    keyVaultName: keyVaultName
  }
}]
////////////////////////////////////////////////////////////////////


// Deploy RHEL Kafka VMs

var vmsToDeployRHELDevQa = serviceName == 'RHEL-PROD-KAFKA' ? vm : []
module vmRHELPRD './modules/virtual-machines/RHEL-PROD-KAFKA.bicep' = [for vm in vmsToDeployRHELDevQa: {
  name: 'deploy-${vm.vmName}-${tagSuffix}'
  params: {
    vmConfig: vm
    tagSuffix: tagSuffix
  }
}]

////////////////////////////////////////////////////////////////////
///// RedhatServerUAT ///
///////////////////////////////////////////////////////////////////          
param vms array = []

var vmsToDeployUAT = serviceName == 'RedhatServerUAT' ? vms : []

module RedhatServerUAT './modules/virtual-machines/RedhatServerUAT.bicep' = [for vm in vmsToDeployUAT: {
  name: '${vm.name}-deployment'
  params: {
    vmConfig: vm
    location: vm.location
    tagSuffix: tagSuffix
  }
}]

// ///////////////////////////////////////////////////////////
// Deploy Matching Service QA Backup VMs from configuration array  ////
// ///////////////////////////////////////////////////////////


var vmsToDeployQA = serviceName == 'Matching-Service-QA-Backup' ? vm : []

module MatchingService './modules/virtual-machines/Matching_Service_QA_Backup.bicep' = [for vm in vmsToDeployQA: {
  name: '${vm.name}-deploy'
  params: {
    location: location
    vmConfig: vm
  }
}]


/// ///////////////////////////////////////////////////////////
//               Boomi_Integration
///////////////////////////////////////////////////////////////

var vmsToDeployBoomi = serviceName == 'Boomi_Integration' ? vms : []

module Boomi './modules/virtual-machines/Boomi_Integration.bicep' = [for vm in vmsToDeployBoomi: {
  name: 'deploy-${vm.name}'
  params: {
    location: location
    vmConfig: vm
    tagSuffix: tagSuffix
  }
}]



///
// Networking
param vnetConfig object = {}


module vnetModule './modules/Network/CODA-Prod-VNet.bicep' = if (serviceName == 'network') {
  name: 'deployVNet'
  params: {
    config: vnetConfig
    tagSuffix: tagSuffix
  }
}


// -------------------------
// Deploy Storage if requested
// -------------------------
param storageConfig object = {}

module storage './modules/Storage/storage.bicep' = if (serviceName == 'storage') {
  name: 'storageModule'
  params: {
    storageConfig: storageConfig
    tagSuffix: tagSuffix
  }
}


///////////////////////////////////////////////////////////////
//               AKS Cluster Deployment
///////////////////////////////////////////////////////////////
// -----------------------------
// Module call
// -----------------------------
param aksConfig object = {}
module aks './modules/aks/aksCluster.bicep' = if (serviceName == 'aks') {
  name: 'aksModule'
  params: {
    aksConfig: aksConfig
    tagSuffix: tagSuffix
  }
}


/////

/////////


// Config objects
param sqlConfig object = {}

module sqlModule './modules/sql/coda-prod-sqldatabase-server.bicep' = if (serviceName == 'sql') {
  name: 'sqlModule'
  params: {
    sqlConfig: sqlConfig
    tagSuffix: tagSuffix
  }
}
