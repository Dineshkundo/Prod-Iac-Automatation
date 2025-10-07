param pool object
param clusterName string
param vnetResourceId string

resource nodepool 'Microsoft.ContainerService/managedClusters/agentPools@2025-05-01' = {
  name: '${clusterName}/${pool.name}'  // child resource of cluster
  properties: {
    vmSize: pool.vmSize
    count: pool.count
    minCount: pool.minCount
    maxCount: pool.maxCount
    enableAutoScaling: pool.enableAutoScaling
    mode: pool.mode
    osType: 'Linux'
    osSKU: 'Ubuntu'
    vnetSubnetID: '${vnetResourceId}/subnets/${pool.subnetName}'
    maxPods: pool.maxPods
    nodeLabels: pool.nodeLabels
    nodeTaints: pool.nodeTaints
    availabilityZones: pool.availabilityZones
    osDiskSizeGB: pool.osDiskSizeGB
    osDiskType: pool.osDiskType
    kubeletDiskType: pool.kubeletDiskType
    enableEncryptionAtHost: pool.enableEncryptionAtHost
    enableUltraSSD: pool.enableUltraSSD
    enableFIPS: pool.enableFIPS
    upgradeSettings: pool.upgradeSettings
    scaleDownMode: pool.scaleDownMode
    enableNodePublicIP: pool.enableNodePublicIP
    securityProfile: pool.securityProfile
  }
}
