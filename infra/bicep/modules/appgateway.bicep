param env string
param location string
param appGwSubnetId string
param backendFqdns array = []
param backendIpAddresses array = []
param wafMode string = 'Prevention'
@secure()
param sslCertData string = ''
@secure()
param sslCertPassword string = ''
param logAnalyticsWorkspaceId string = ''
param tags object = {}

resource pipAppGw 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-appgw-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIPAllocationMethod: 'Static' }
}

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: 'waf-policy-nodeapp-${env}'
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: wafMode
      fileUploadLimitInMb: 100
      maxRequestBodySizeInKb: 128
    }
    managedRules: {
      managedRuleSets: [{ ruleSetType: 'OWASP', ruleSetVersion: '3.2' }]
    }
  }
}

resource appgw 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: 'appgw-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  tags: tags
  properties: {
    sku: { name: 'WAF_v2', tier: 'WAF_v2' }
    autoscaleConfiguration: { minCapacity: 2, maxCapacity: 10 }
    firewallPolicy: { id: wafPolicy.id }
    gatewayIPConfigurations: [
      { name: 'appgw-ipconfig', properties: { subnet: { id: appGwSubnetId } } }
    ]
    frontendIPConfigurations: [
      { name: 'frontend-ipconfig', properties: { publicIPAddress: { id: pipAppGw.id } } }
    ]
    frontendPorts: [
      { name: 'frontend-port-443', properties: { port: 443 } }
    ]
    backendAddressPools: [
      {
        name: 'nodeapp-backend-pool'
        properties: {
          backendAddresses: [for fqdn in backendFqdns: { fqdn: fqdn }]
        }
      }
    ]
    probes: [
      {
        name: 'nodeapp-health-probe'
        properties: {
          protocol: 'Https'
          path: '/healthz'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          host: '127.0.0.1'
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'nodeapp-http-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          probe: { id: resourceId('Microsoft.Network/applicationGateways/probes', 'appgw-nodeapp-${env}', 'nodeapp-health-probe') }
        }
      }
    ]
    httpListeners: [
      {
        name: 'nodeapp-https-listener'
        properties: {
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'appgw-nodeapp-${env}', 'frontend-ipconfig') }
          frontendPort: { id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'appgw-nodeapp-${env}', 'frontend-port-443') }
          protocol: 'Https'
          sslCertificate: { id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'appgw-nodeapp-${env}', 'nodeapp-ssl-cert') }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'nodeapp-ssl-cert'
        properties: {
          data: sslCertData          // replace with keyVaultSecretId reference in prod
          password: sslCertPassword
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'nodeapp-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'appgw-nodeapp-${env}', 'nodeapp-https-listener') }
          backendAddressPool: { id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'appgw-nodeapp-${env}', 'nodeapp-backend-pool') }
          backendHttpSettings: { id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'appgw-nodeapp-${env}', 'nodeapp-http-settings') }
        }
      }
    ]
  }
}

resource diagAppGw 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'diag-appgw-${env}'
  scope: appgw
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'ApplicationGatewayAccessLog', enabled: true }
      { category: 'ApplicationGatewayFirewallLog', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}

output appGwId string = appgw.id
output appGwPublicIp string = pipAppGw.properties.ipAddress
output wafPolicyId string = wafPolicy.id
output backendPoolId string = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'appgw-nodeapp-${env}', 'nodeapp-backend-pool')
