using '../main.bicep'

param env = 'dev'
param location = 'australiaeast'
param resourceGroupName = 'rg-nodeapp-dev'

param subnetWebPrefix = '10.0.1.0/24'
param subnetDataPrefix = '10.0.2.0/24'
param subnetBastionPrefix = '10.0.4.0/27'
param subnetFirewallPrefix = '10.0.5.0/26'
param subnetAppGwPrefix = '10.0.6.0/24'

param vmssInstanceCount = 6
param vmssVmSize = 'Standard_D2s_v5'
param vmssAdminUsername = 'azureuser'
param sshPublicKey = readEnvironmentVariable('SSH_PUBLIC_KEY', '')
param goldenImageId = ''

param wafMode = 'Detection'
param sslCertData = readEnvironmentVariable('SSL_CERT_DATA', '')
param sslCertPassword = readEnvironmentVariable('SSL_CERT_PASSWORD', '')
param customDomainHostName = ''

param logAnalyticsSku = 'PerGB2018'
param logRetentionDays = 30
param alertEmail = 'devops-team@company.com'

param tags = {
  project: 'nodeapp'
  environment: 'dev'
  managedBy: 'bicep'
}
