@description('VM configuration object')
param vmConfig object
param location string

// ---------------- VM Resource ----------------
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmConfig.name
  location: location
  tags: vmConfig.tags
  zones: [
    vmConfig.zone
  ]
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
      imageReference: vmConfig.image
      osDisk: vmConfig.osDisk
      dataDisks: vmConfig.dataDisks
      diskControllerType: 'SCSI'
    }
    osProfile: vmConfig.osProfile
    securityProfile: vmConfig.securityProfile
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
    diagnosticsProfile: vmConfig.diagnostics
  }
}

// ---------------- Extension ----------------
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
