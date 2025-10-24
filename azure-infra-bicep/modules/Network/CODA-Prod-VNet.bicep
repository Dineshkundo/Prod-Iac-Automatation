targetScope = 'resourceGroup'

@description('Full VNet configuration object')
param config object
param vnetConfig object 


@description('Tag suffix for resource tagging')
param tagSuffix string

// ==========================
// Resource: Virtual Network
// ==========================
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: config.vnetName
  location: config.location
  tags: union(config.tags, {
    Environment: tagSuffix
  })
  properties: {
    addressSpace: {
      addressPrefixes: config.addressSpace
    }

    // Safe-access usage for optional properties
    enableDdosProtection: config.?enableDdosProtection ?? false
    encryption: config.?encryption ?? {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }

    // Subnet definitions
    subnets: [
      for subnet in config.subnets: {
        name: subnet.name
        properties: {
          addressPrefixes: subnet.addressPrefixes
          networkSecurityGroup: subnet.?nsgId != null ? { id: subnet.nsgId } : null
          routeTable: subnet.?routeTableId != null ? { id: subnet.routeTableId } : null
          serviceEndpoints: subnet.?serviceEndpoints ?? []
          delegations: subnet.?delegations ?? []
          privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
          privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
        }
      }
    ]

    // Optional VNet peering (only if remoteVnetId provided)
    virtualNetworkPeerings: !empty(config.?remoteVnetId) ? [
      {
        name: '${config.vnetName}-peering'
        properties: {
          remoteVirtualNetwork: { id: config.remoteVnetId }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: true
          allowGatewayTransit: true
          useRemoteGateways: false
        }
      }
    ] : []
  }
}

// ==========================
// Outputs
// ==========================
output vnetId string = vnet.id
output subnetIds array = [for s in config.subnets: '${vnet.id}/subnets/${s.name}']
output subnet1Id string = vnet.properties.subnets[0].id
