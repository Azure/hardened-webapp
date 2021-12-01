// Virtual Network Parameters
param virtualNetworkName string
param addressSpace string
param firewallSubnet string
param privateLinkSubnet string
param webAppSubnet string

// Azure Firewall Parameters
param firewallIpName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnet
        }
      }
      {
        name: 'subnet-privatelink'
        properties: {
          addressPrefix: privateLinkSubnet
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        
      }
      {
        name: 'subnet-webapp'
        properties: {
          addressPrefix: webAppSubnet
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource privatednszoneweb 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource privatednszonesql 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
}

resource privatednszonelinkweb 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatednszoneweb
  dependsOn: [
    virtualNetwork
  ]
  name: uniqueString('privatelink.azurewebsites.net', resourceGroup().name)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource privatednszonelinksql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatednszonesql
  dependsOn: [
    virtualNetwork
  ]
  name: uniqueString('privatelink.database.windows.net', resourceGroup().name)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource firewallip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: firewallIpName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}
