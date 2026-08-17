param env string
param location string
param firewallSubnetId string
param webSubnetId string
param logAnalyticsWorkspaceId string = ''
param tags object = {}

resource pipFw 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-fw-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIPAllocationMethod: 'Static' }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: 'fw-policy-nodeapp-${env}'
  location: location
  tags: tags
  properties: { sku: { tier: 'Standard' } }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: fwPolicy
  name: 'NodeAppEgressRules'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowNodeAppEgress'
        priority: 200
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AllowNpmRegistry'
            protocols: [{ protocolType: 'Https', port: 443 }]
            sourceAddresses: ['10.0.1.0/24']
            targetFqdns: ['registry.npmjs.org', '*.npmjs.org']
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowUbuntuRepos'
            protocols: [{ protocolType: 'Https', port: 443 }, { protocolType: 'Http', port: 80 }]
            sourceAddresses: ['10.0.1.0/24']
            targetFqdns: ['*.ubuntu.com', 'security.ubuntu.com']
          }
        ]
      }
    ]
  }
}

resource fw 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'fw-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  tags: tags
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Standard' }
    firewallPolicy: { id: fwPolicy.id }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: { id: firewallSubnetId }
          publicIPAddress: { id: pipFw.id }
        }
      }
    ]
  }
}

resource rtWeb 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-web-${env}'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: fw.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource rtAssoc 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: '${split(webSubnetId, '/')[8]}/${split(webSubnetId, '/')[10]}'
}

resource diagFw 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'diag-fw-${env}'
  scope: fw
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AzureFirewallApplicationRule', enabled: true }
      { category: 'AzureFirewallNetworkRule', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}

output firewallId string = fw.id
output firewallPrivateIp string = fw.properties.ipConfigurations[0].properties.privateIPAddress
output routeTableId string = rtWeb.id
