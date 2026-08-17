// orchestrates all modules
param env string = 'dev'
param location string = 'australiaeast'
param resourceGroupName string

param vnetAddressSpace array = ['10.0.0.0/16']
param subnetWebPrefix string = '10.0.1.0/24'
param subnetDataPrefix string = '10.0.2.0/24'
param subnetBastionPrefix string = '10.0.4.0/27'
param subnetFirewallPrefix string = '10.0.5.0/26'
param subnetAppGwPrefix string = '10.0.6.0/24'

param vmssInstanceCount int = 6
param vmssVmSize string = 'Standard_D2s_v5'
param vmssAdminUsername string = 'azureuser'
@secure()
param sshPublicKey string
param goldenImageId string = ''

param wafMode string = 'Prevention'
@secure()
param sslCertData string = ''
@secure()
param sslCertPassword string = ''
param customDomainHostName string = ''

param logAnalyticsSku string = 'PerGB2018'
param logRetentionDays int = 30
param alertEmail string = 'devops-team@company.com'

param tags object = {
  project: 'nodeapp'
  environment: env
  managedBy: 'bicep'
}

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring'
  scope: rg
  dependsOn: [
    rg
  ]
  params: {
    env: env
    location: location
    logAnalyticsSku: logAnalyticsSku
    logRetentionDays: logRetentionDays
    alertEmail: alertEmail
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'deploy-network'
  scope: rg
  params: {
    env: env
    location: location
    vnetAddressSpace: vnetAddressSpace
    subnetWebPrefix: subnetWebPrefix
    subnetDataPrefix: subnetDataPrefix
    subnetBastionPrefix: subnetBastionPrefix
    subnetFirewallPrefix: subnetFirewallPrefix
    subnetAppGwPrefix: subnetAppGwPrefix
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
}

module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  scope: rg
  params: {
    env: env
    location: location
    firewallSubnetId: network.outputs.firewallSubnetId
    webSubnetId: network.outputs.webSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  scope: rg
  params: {
    env: env
    location: location
    bastionSubnetId: network.outputs.bastionSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
}

module appgateway 'modules/appgateway.bicep' = {
  name: 'deploy-appgateway'
  scope: rg
  params: {
    env: env
    location: location
    appGwSubnetId: network.outputs.appGwSubnetId
    backendFqdns: []
    backendIpAddresses: []
    wafMode: wafMode
    sslCertData: sslCertData
    sslCertPassword: sslCertPassword
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
  dependsOn: [vmss]
}

module vmss 'modules/vmss.bicep' = {
  name: 'deploy-vmss'
  scope: rg
  params: {
    env: env
    location: location
    instanceCount: vmssInstanceCount
    vmSize: vmssVmSize
    adminUsername: vmssAdminUsername
    sshPublicKey: sshPublicKey
    goldenImageId: goldenImageId
    webSubnetId: network.outputs.webSubnetId
    nsgWebId: network.outputs.nsgWebId
    tags: tags
  }
  dependsOn: [firewall, bastion]
}

module frontdoor 'modules/frontdoor.bicep' = {
  name: 'deploy-frontdoor'
  scope: rg
  params: {
    env: env
    appGwPublicIp: appgateway.outputs.appGwPublicIp
    customDomainHostName: customDomainHostName
    wafMode: wafMode
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    tags: tags
  }
}

output vnetId string = network.outputs.vnetId
output vmssId string = vmss.outputs.vmssId
output appGwPublicIp string = appgateway.outputs.appGwPublicIp
output frontDoorEndpointHostname string = frontdoor.outputs.frontDoorEndpointHostname
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
