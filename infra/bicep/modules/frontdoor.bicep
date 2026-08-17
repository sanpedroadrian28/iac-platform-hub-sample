param env string
param appGwPublicIp string
param customDomainHostName string = ''
param wafMode string = 'Prevention'
param logAnalyticsWorkspaceId string = ''
param tags object = {}

resource fdProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'fd-nodeapp-${env}'
  location: 'global'
  tags: tags
  sku: { name: 'Premium_AzureFrontDoor' }
}

resource fdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: fdProfile
  name: 'fde-nodeapp-${env}'
  location: 'global'
  tags: tags
  properties: { enabledState: 'Enabled' }
}

resource fdOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: fdProfile
  name: 'og-appgw-${env}'
  properties: {
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
    healthProbeSettings: {
      probePath: '/healthz'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 30
    }
  }
}

resource fdOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: fdOriginGroup
  name: 'origin-appgw-${env}'
  properties: {
    hostName: appGwPublicIp
    originHostHeader: appGwPublicIp
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource fdRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: fdEndpoint
  name: 'route-nodeapp-${env}'
  properties: {
    originGroup: { id: fdOriginGroup.id }
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
  dependsOn: [fdOrigin]
}

resource fdWafPolicy 'Microsoft.Network/frontdoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: 'fdwaf${env}'
  location: 'global'
  tags: tags
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: {
    policySettings: { enabledState: 'Enabled', mode: wafMode }
    managedRules: {
      managedRuleSets: [
        { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1', ruleSetAction: 'Block' }
        { ruleSetType: 'Microsoft_BotManagerRuleSet', ruleSetVersion: '1.0', ruleSetAction: 'Block' }
      ]
    }
  }
}

resource fdSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: fdProfile
  name: 'fd-security-policy-${env}'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: { id: fdWafPolicy.id }
      associations: [
        {
          domains: [{ id: fdEndpoint.id }]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}

resource diagFd 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'diag-frontdoor-${env}'
  scope: fdProfile
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'FrontDoorAccessLog', enabled: true }
      { category: 'FrontDoorWebApplicationFirewallLog', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}

output frontDoorEndpointHostname string = fdEndpoint.properties.hostName
output frontDoorProfileId string = fdProfile.id
output wafPolicyId string = fdWafPolicy.id
