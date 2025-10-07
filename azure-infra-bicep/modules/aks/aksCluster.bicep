param aksConfig object
param tagSuffix string

// -----------------------------
// AKS Cluster Resource
// -----------------------------
resource aks 'Microsoft.ContainerService/managedClusters@2025-05-01' = {
  name: aksConfig.clusterName
  location: aksConfig.location
  tags: aksConfig.tags != null ? aksConfig.tags : {
    Environment: tagSuffix
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: aksConfig.kubernetesVersion
    dnsPrefix: aksConfig.clusterName
    enableRBAC: true
    disableLocalAccounts: false

    linuxProfile: {
      adminUsername: aksConfig.adminUsername
      ssh: {
        publicKeys: [
          { keyData: aksConfig.sshPublicKey }
        ]
      }
    }

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }

    apiServerAccessProfile: {
      authorizedIPRanges: aksConfig.authorizedIpRanges
    }

    networkProfile: aksConfig.networkProfile

    agentPoolProfiles: [
      {
        name: aksConfig.systemPool.name
        vmSize: aksConfig.systemPool.vmSize
        count: aksConfig.systemPool.count
        minCount: aksConfig.systemPool.minCount
        maxCount: aksConfig.systemPool.maxCount
        enableAutoScaling: aksConfig.systemPool.enableAutoScaling
        mode: aksConfig.systemPool.mode
        osType: 'Linux'
        osSKU: 'Ubuntu'
        vnetSubnetID: '${aksConfig.vnetResourceId}/subnets/${aksConfig.systemPool.subnetName}'
        maxPods: aksConfig.systemPool.maxPods
        nodeLabels: aksConfig.systemPool.nodeLabels
      }
    ]
  }
}

// -----------------------------
// User Node Pools (dynamic)
module userNodePools './nodePool.bicep' = [for pool in aksConfig.userPools: {
  name: '${aksConfig.clusterName}-${pool.name}'
  params: {
    pool: pool
    clusterName: aksConfig.clusterName
    vnetResourceId: aksConfig.vnetResourceId
  }
  dependsOn: [
    aks
  ]
}]
