@minLength(1)
@maxLength(80)
param nsgName string
param securityRules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: resourceGroup().location
}

module securityRulesLoop 'nsgrules.bicep' = [for (rule, index) in securityRules: {
  name: 'securityRule${index}Deployment-${uniqueString(deployment().name)}'
  params: {
    nsgName: nsg.name
    ruleName: rule.ruleName
    description: rule.description
    access: rule.access
    protocol: rule.protocol
    direction: rule.direction
    priority: rule.priority
    sourceAddressPrefix: rule.sourceAddressPrefix
    sourcePortRange: rule.sourcePortRange
    destinationAddressPrefix: rule.destinationAddressPrefix
    destinationPortRange: rule.destinationPortRange
  }
}]
