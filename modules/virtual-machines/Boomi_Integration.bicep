param location string
param tagSuffix string
param vmConfig object

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmConfig.name
  location: location
  // Merge vmConfig.tags with tagSuffix
  tags: union(
    vmConfig.tags,
    {
      TagSuffix: tagSuffix
    }
  )
  zones: vmConfig.zones
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    additionalCapabilities: vmConfig.additionalCapabilities
    storageProfile: {
      imageReference: vmConfig.imageReference
      osDisk: {
        osType: vmConfig.osDisk.osType
        name: vmConfig.osDisk.name
        createOption: 'FromImage'
        caching: vmConfig.osDisk.caching
        managedDisk: {
          storageAccountType: vmConfig.osDisk.storageAccountType
          id: vmConfig.osDisk.id
        }
        deleteOption: vmConfig.osDisk.deleteOption
        diskSizeGB: vmConfig.osDisk.diskSizeGB
      }
      dataDisks: vmConfig.dataDisks
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: vmConfig.osProfile.computerName
      adminUsername: vmConfig.osProfile.adminUsername
      linuxConfiguration: vmConfig.osProfile.linuxConfiguration
      windowsConfiguration: vmConfig.osProfile.windowsConfiguration
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      encryptionAtHost: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmConfig.nicId
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
    protectedSettings: vmConfig.extension.protectedSettings
  }
}

output vmId string = vm.id
output vmName string = vm.name
