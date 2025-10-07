@description('VM configuration object')
param vmConfig object

@description('Tag suffix for environment (e.g., dev, qa, uat)')
param tagSuffix string

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: '${vmConfig.vmName}-${tagSuffix}'
  location: vmConfig.location
  tags: union(vmConfig.tags, {
    TagSuffix: tagSuffix
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmConfig.vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmConfig.publisher
        offer: vmConfig.offer
        sku: vmConfig.sku
        version: vmConfig.version
      }
      osDisk: {
        osType: 'Linux'
        name: '${vmConfig.vmName}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          id: vmConfig.osDiskId
        }
        deleteOption: 'Detach'
        diskSizeGB: vmConfig.osDiskSizeGB
      }
      dataDisks: [
        {
          lun: 0
          name: '${vmConfig.vmName}-datadisk1'
          createOption: 'Attach'
          caching: 'None'
          managedDisk: {
            id: vmConfig.dataDiskId
          }
          deleteOption: 'Detach'
          diskSizeGB: vmConfig.dataDiskSizeGB
        }
      ]
    }
    osProfile: {
      computerName: vmConfig.vmName
      adminUsername: vmConfig.adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmConfig.nicId
        }
      ]
    }
  }
}

resource enableVmAccess 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = if (vmConfig.extensions != null) {
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
      username: vmConfig.extensions.username
      ssh_key: vmConfig.extensions.ssh_key
      reset_ssh: vmConfig.extensions.reset_ssh
      remove_user: vmConfig.extensions.remove_user
      expiration: vmConfig.extensions.expiration
    }
  }
}

output vmId string = vm.id
output vmName string = vm.name
