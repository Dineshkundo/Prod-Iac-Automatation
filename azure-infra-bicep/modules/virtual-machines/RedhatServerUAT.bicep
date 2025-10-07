@description('VM configuration object')
param vmConfig object

@description('Environment tag suffix (e.g. dev, qa, uat)')
param tagSuffix string

@description('Deployment location')
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: '${vmConfig.name}-${tagSuffix}'
  location: location
  tags: union(vmConfig.tags, {
    EnvSuffix: tagSuffix
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.size
    }
    storageProfile: {
      imageReference: vmConfig.imageReference
      osDisk: vmConfig.osDisk
      dataDisks: vmConfig.dataDisks
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: '${vmConfig.name}-${tagSuffix}'
      adminUsername: vmConfig.adminUsername
      linuxConfiguration: vmConfig.linuxConfiguration
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      encryptionAtHost: vmConfig.encryptionAtHost
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmConfig.nicId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: vmConfig.bootDiagnostics
      }
    }
  }
}

resource vmAccess 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = if (contains(vmConfig, 'extension')) {
  parent: vm
  name: vmConfig.extension.name
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: vmConfig.extension.publisher
    type: vmConfig.extension.type
    typeHandlerVersion: vmConfig.extension.typeHandlerVersion
    settings: vmConfig.extension.settings
    protectedSettings: {
      username: vmConfig.extension.protectedSettings.username
      password: vmConfig.extension.protectedSettings.password
      ssh_key: vmConfig.extension.protectedSettings.ssh_key
      reset_ssh: vmConfig.extension.protectedSettings.reset_ssh
      remove_user: vmConfig.extension.protectedSettings.remove_user
      expiration: vmConfig.extension.protectedSettings.expiration
    }
  }
}

output vmId string = vm.id
output vmName string = vm.name
