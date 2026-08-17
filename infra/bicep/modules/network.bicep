@description('Environment name')
param env string
param location string
param vnetAddressSpace array = ['10.0.0.0/16']
param subnetWebPrefix string = '10.0.1.0/24'
param subnetDataPrefix string = '10.0.2.0/24'
param subnetBastionPrefix string = '10.0.4.0/27'
param subnetFirewallPrefix string = '10.0.5.0/26'
param subnetAppGwPrefix string = '10.0.6.0/24'
param logAnalyticsWorkspaceId string = ''
param tags object = {}

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-web-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-AppGW-HTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnetAppGwPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-data-${env}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-Web-DB'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnetWebPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5432'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-nodeapp-${env}'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: vnetAddressSpace }
    subnets: [
      {
        name: 'subnet-web'
        properties: {
          addressPrefix: subnetWebPrefix
          networkSecurityGroup: { id: nsgWeb.id }
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: subnetDataPrefix
          networkSecurityGroup: { id: nsgData.id }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: { addressPrefix: subnetBastionPrefix }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: { addressPrefix: subnetFirewallPrefix }
      }
      {
        name: 'subnet-appgw'
        properties: { addressPrefix: subnetAppGwPrefix }
      }
    ]
  }
}

output vnetId string = vnet.id
output webSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
output bastionSubnetId string = vnet.properties.subnets[2].id
output firewallSubnetId string = vnet.properties.subnets[3].id
output appGwSubnetId string = vnet.properties.subnets[4].id
output nsgWebId string = nsgWeb.id
output nsgDataId string = nsgData.id
