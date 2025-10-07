targetScope = 'resourceGroup'

@description('VM configuration object (non-sensitive).')
param vmConfig object

@description('Tag suffix')
param tagSuffix string = 'prod'

@description('Key Vault name that stores secrets (existing vault)')
param keyVaultName string
 

@description('Names of secrets inside Key Vault (not values)')
param secretNames object = {
  username: 'PROD-JENKINS-USERNAME'
  password: 'PROD-JENKINS-PASSWORD'
  sshKey:   'PROD-JENKINS-SSH-PUB' // adjust to your secret name if different
  reset_ssh: ''
  remove_user: ''
  expiration: ''
}

var getSecretApi = '2016-10-01' // API version for listSecret


// Read secrets at deployment time. If a mapping member is empty, treat as empty string.
var secretValues = {
  username: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.username), getSecretApi).value
  password: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.password), getSecretApi).value
  ssh_key: secretNames.sshKey != '' ? listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.sshKey), getSecretApi).value : ''
  reset_ssh: secretNames.reset_ssh != '' ? listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.reset_ssh), getSecretApi).value : ''
  remove_user: secretNames.remove_user != '' ? listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.remove_user), getSecretApi).value : ''
  expiration: secretNames.expiration != '' ? listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.expiration), getSecretApi).value : ''
}


resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmConfig.name
  location: vmConfig.location
  tags: {
    environment: tagSuffix
    role: 'jenkins'
  }
  zones: vmConfig.zones
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: vmConfig.image.publisher
        offer: vmConfig.image.offer
        sku: vmConfig.image.sku
        version: vmConfig.image.version
      }
      osDisk: {
        osType: 'Linux'
        name: '${vmConfig.name}_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          id: vmConfig.osDiskId
        }
        deleteOption: 'Delete'
        diskSizeGB: vmConfig.osDiskSizeGB
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: vmConfig.name
      adminUsername: vmConfig.adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmConfig.adminUsername}/.ssh/authorized_keys'
              keyData: secretValues.ssh_key
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmConfig.networkInterfaceId
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vmAccessExt 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: vm
  name: 'enablevmAccess'
  location: vmConfig.location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.5'
    settings: {}
    protectedSettings: {
      username: secretValues.username
      password: secretValues.password
      ssh_key: secretValues.ssh_key
      reset_ssh: secretValues.reset_ssh
      remove_user: secretValues.remove_user
      expiration: secretValues.expiration
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
output vmLocation string = vm.location
output vmPrivateIp string = vmConfig.privateIp
output vmPublicIp string = vmConfig.publicIp
output vmAdminUsername string = vmConfig.adminUsername
output vmSshKey string = secretValues.ssh_key
output vmOsDiskId string = vm.properties.storageProfile.osDisk.managedDisk.id
output vmIdentityPrincipalId string = vm.identity.principalId

