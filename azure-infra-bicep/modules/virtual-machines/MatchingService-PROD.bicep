param vmConfig object
param tagSuffix string
param keyVaultName string

@description('API version for Key Vault secrets')
var kvApiVersion = '2016-10-01'

// Secret names expected
var secretNames = {
  username: ''
  password: ''
  ssh_key: 'matchingservice-prod-ssh-key' // adjust to your secret name if different
  reset_ssh: ''
  remove_user: ''
  expiration: ''
}

// Dynamically retrieve secrets from Key Vault
var secrets = {
  username: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.username), kvApiVersion).value
  password: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.password), kvApiVersion).value
  ssh_key: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.ssh_key), kvApiVersion).value
  reset_ssh: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.reset_ssh), kvApiVersion).value
  remove_user: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.remove_user), kvApiVersion).value
  expiration: listSecret(resourceId('Microsoft.KeyVault/vaults/secrets', keyVaultName, secretNames.expiration), kvApiVersion).value
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmConfig.name
  location: vmConfig.location
  zones: vmConfig.zones
  tags: union({
    Environment: tagSuffix
  }, vmConfig.tags)

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    storageProfile: {
      imageReference: vmConfig.image
      osDisk: {
        osType: vmConfig.osType
        name: '${vmConfig.name}_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: vmConfig.storageAccountType
        }
        diskSizeGB: vmConfig.osDiskSizeGB
        deleteOption: 'Detach'
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
              keyData: secrets.ssh_key
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmConfig.nicId
          properties: {
            deleteOption: 'Detach'
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

resource vmAccess 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: vm
  name: 'enablevmAccess'
  location: vmConfig.location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.5'
    protectedSettings: {
      username: secrets.username
      password: secrets.password
      ssh_key: secrets.ssh_key
      reset_ssh: secrets.reset_ssh
      remove_user: secrets.remove_user
      expiration: secrets.expiration
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
