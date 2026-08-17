// Log Analytics + Azure Monitor + Defender for Cloud
param env string
param location string
param logAnalyticsSku string = 'PerGB2018'
param logRetentionDays int = 30
param vmssId string = ''
param alertEmail string = 'devops-team@company.com'
param tags object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-nodeapp-${env}'
  location: location
  tags: tags
  properties: {
    sku: { name: logAnalyticsSku }
    retentionInDays: logRetentionDays
  }
}

resource vmInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${law.name})'
  location: location
  tags: tags
  plan: {
    name: 'VMInsights(${law.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: law.id
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-nodeapp-${env}'
  location: location
  tags: tags
  properties: {
    destinations: {
      logAnalytics: [
        { workspaceResourceId: law.id, name: 'law-destination' }
      ]
    }
    dataFlows: [
      { streams: ['Microsoft-Syslog', 'Microsoft-InsightsMetrics'], destinations: ['law-destination'] }
    ]
    dataSources: {
      syslog: [
        {
          name: 'syslog-datasource'
          streams: ['Microsoft-Syslog']
          facilityNames: ['auth', 'authpriv', 'daemon', 'syslog']
          logLevels: ['Warning', 'Error', 'Critical']
        }
      ]
      performanceCounters: [
        {
          name: 'perfcounter-datasource'
          streams: ['Microsoft-InsightsMetrics']
          samplingFrequencyInSeconds: 60
          counterSpecifiers: ['Processor(*)\\% Processor Time', 'Memory(*)\\% Used Memory']
        }
      ]
    }
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-nodeapp-ops-${env}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'nodeappops'
    enabled: true
    emailReceivers: [
      { name: 'ops-email', emailAddress: alertEmail, useCommonAlertSchema: true }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(vmssId)) {
  name: 'alert-high-cpu-${env}'
  location: 'global'
  tags: tags
  properties: {
    severity: 2
    enabled: true
    scopes: [vmssId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricNamespace: 'Microsoft.Compute/virtualMachineScaleSets'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      { actionGroupId: actionGroup.id }
    ]
  }
}

resource defenderWorkspaceSetting 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: law.id
    scope: subscription().id
  }
}

resource securityContact 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    emails: alertEmail
    notificationsByRole: {
      state: 'On'
      roles: ['Owner']
    }
    alertNotifications: {
      state: 'On'
      minimalSeverity: 'Medium'
    }
  }
}

output workspaceId string = law.id
output workspaceName string = law.name
output dcrId string = dcr.id
output actionGroupId string = actionGroup.id
