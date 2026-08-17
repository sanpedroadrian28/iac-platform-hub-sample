using '../main.bicep'

param env = 'staging'
param location = 'australiaeast'
param resourceGroupName = 'rg-nodeapp-staging'

param subnetWebPrefix = '10.1.1.0/24'
param subnetDataPrefix = '10.1.2.0/24'
param subnetBastionPrefix = '10.1.4.0/27'
param subnetFirewallPrefix = '10.1.5.0/26'
param subnetAppGwPrefix = '10.1.6.0/24'

param vmssInstanceCount = 6
param vmssVmSize = 'Standard_D2s_v5'
param vmssAdminUsername = 'azureuser'
param sshPublicKey = readEnvironmentVariable('SSH_PUBLIC_KEY', '')
param goldenImageId = ''

param wafMode = 'Prevention'
param sslCertData = readEnvironmentVariable('SSL_CERT_DATA', '')
param sslCertPassword = readEnvironmentVariable('SSL_CERT_PASSWORD', '')
param customDomainHostName = 'staging.nodeapp.company.com'

param logAnalyticsSku = 'PerGB2018'
param logRetentionDays = 30
param alertEmail = 'devops-team@company.com'

param tags = {
  project: 'nodeapp'
  environment: 'staging'
  managedBy: 'bicep'
}
