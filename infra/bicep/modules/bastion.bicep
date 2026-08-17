param env string
param location string
param bastionSubnetId string
param logAnalyticsWorkspaceId string = ''
param tags object = {}

resource pipBastion 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-bastion-${env}'
  location: location
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'bastion-nodeapp-${env}'
  location: location
  tags: tags
  sku: { name: 'Standard' } // required for native/AAD SSH
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: { id: bastionSubnetId }
          publicIPAddress: { id: pipBastion.id }
        }
      }
    ]
  }
}

resource diagBastion 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'diag-bastion-${env}'
  scope: bastion
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [{ category: 'BastionAuditLogs', enabled: true }]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}

output bastionId string = bastion.id
output bastionName string = bastion.name
