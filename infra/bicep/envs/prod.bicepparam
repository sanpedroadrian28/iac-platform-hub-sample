using '../main.bicep'

param env = 'prod'
param location = 'australiaeast'
param resourceGroupName = 'rg-nodeapp-prod'

param subnetWebPrefix = '10.2.1.0/24'
param subnetDataPrefix = '10.2.2.0/24'
param subnetBastionPrefix = '10.2.4.0/27'
param subnetFirewallPrefix = '10.2.5.0/26'
param subnetAppGwPrefix = '10.2.6.0/24'

param vmssInstanceCount = 6
param vmssVmSize = 'Standard_D4s_v5'
param vmssAdminUsername = 'azureuser'
param sshPublicKey = readEnvironmentVariable('SSH_PUBLIC_KEY', '')
param goldenImageId = readEnvironmentVariable('GOLDEN_IMAGE_ID', '')

param wafMode = 'Prevention'
param sslCertData = readEnvironmentVariable('SSL_CERT_DATA', '')
param sslCertPassword = readEnvironmentVariable('SSL_CERT_PASSWORD', '')
param customDomainHostName = 'nodeapp.company.com'

param logAnalyticsSku = 'PerGB2018'
param logRetentionDays = 90
param alertEmail = 'devops-oncall@company.com'

param tags = {
  project: 'nodeapp'
  environment: 'prod'
  managedBy: 'bicep'
}
