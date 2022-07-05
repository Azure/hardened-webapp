param randomString string = take(uniqueString(resourceGroup().name), 5)
param usePreviewFeatures bool = true

// Virtual Network Parameters
param virtualNetworkName string = 'vnet-${randomString}'
param addressSpace string = '10.235.235.0/24'
param firewallSubnet string = '10.235.235.0/26'
param privateLinkSubnet string = '10.235.235.64/27'
param webAppSubnet string = '10.235.235.96/27'

// Network Security Group
param nsgName string = 'nsg${randomString}'

// Azure Firewall Parameters
param firewallIpName string = 'firewallip${randomString}'
param firewallName string = 'firewall${randomString}'

// Web App Parameters
param webAppName string = 'webapp${randomString}'

// App Service Plan Parameters
param appServicePlanName string = 'appsp${randomString}'
param appServicePlanSku string = 'S1'
param appServicePlanSkuCode string = 'S'
param workerSize int = 0
param workerSizeId int = 0

// Front Door Parameters

param frontDoorName string = 'frontdoor${randomString}'
param customBackendFqdn string

// SQL Parameters
param sqlName string = 'sql${randomString}'
param sqlAdministratorLogin string = 'sql${randomString}admin'
@secure()
param sqladministratorLoginPassword string 

// Route Table name
param routeTableName string = 'routetable${randomString}'

module nsgDeployment 'nsg.bicep' = if(usePreviewFeatures){
  name: 'nsgDeployment'
  params: {
    nsgName: nsgName
    securityRules: [
      {
        ruleName: 'Allow-Firewall'
        description: 'Allow Firewall subnet'
        access: 'Allow'
        protocol: '*'
        direction: 'Inbound'
        priority: 100
        sourceAddressPrefix: '10.235.235.0/26'
        sourcePortRange: '*'
        destinationAddressPrefix: '10.235.235.64/27'
        destinationPortRange: '*'
      }
    ]
  }
}
module networkDeployment 'network.bicep' = {
  dependsOn: [
    nsgDeployment
  ]
  name: 'networkDeployment'
  params: {
    addressSpace: addressSpace
    firewallIpName: firewallIpName
    firewallSubnet: firewallSubnet
    privateLinkSubnet: privateLinkSubnet
    virtualNetworkName: virtualNetworkName
    webAppSubnet: webAppSubnet
    usePreviewFeatures: usePreviewFeatures
    nsgName: usePreviewFeatures ? nsgName : ''
  }
}

module webappDeployment 'webapp.bicep' = {
  dependsOn: [
    networkDeployment
  ]
  name: 'webappDeployment'
  params: {
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    appServicePlanSkuCode: appServicePlanSkuCode
    virtualNetworkName: virtualNetworkName
    webAppName: webAppName
    workerSize: workerSize
    workerSizeId: workerSizeId
  }
}

module firewallDeployment 'firewall.bicep' = {
  dependsOn: [
    networkDeployment
    webappDeployment
  ]
  name: 'firewallDeployment'
  params: {
    firewallIpName: firewallIpName
    firewallName: firewallName
    privateendpointnicname: webappDeployment.outputs.privateendpointnicname
    virtualNetworkName: virtualNetworkName
    webAppName: webAppName
  }
}

module frontDoorDeployment 'frontdoor.bicep' = {
  name: 'frontDoorDeployment'
  params: {
    customBackendFqdn: customBackendFqdn
    frontDoorName: frontDoorName
  }
}

module sqlDeployment 'sql.bicep' = {
  dependsOn: [
    networkDeployment
  ]
  name: 'sqlDeployment'
  params: {
    sqlAdministratorLogin: sqlAdministratorLogin
    sqladministratorLoginPassword: sqladministratorLoginPassword
    sqlName: sqlName
    virtualNetworkName: virtualNetworkName
  }
}

module routingDeployment 'routetable.bicep' = {
  dependsOn: [
    networkDeployment
    webappDeployment
    firewallDeployment
  ]
  name: 'routingDeployment'
  params: {
    firewallName: firewallName
    routetablename: routeTableName
    virtualNetworkName: virtualNetworkName
    webAppSubnet: webAppSubnet
  }
}

output firewallPublicIp string = firewallDeployment.outputs.firewallPublicIp
output customDomainVerificationId string = webappDeployment.outputs.customDomainVerificationId
output sqlFqdn string = '${sqlName}.database.windows.net'
