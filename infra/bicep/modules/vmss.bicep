param env string
param location string
param instanceCount int = 6
param vmSize string = 'Standard_D2s_v5'
param adminUsername string = 'azureuser'
@secure()
param sshPublicKey string
param goldenImageId string = ''
param webSubnetId string
param nsgWebId string
param appGwBackendPoolId string = ''
param tags object = {}

var useMarketplaceImage = empty(goldenImageId)

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: 'vmss-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  tags: tags
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    zoneBalance: true
    upgradePolicy: { mode: 'Rolling' }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'nodeapp'
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        imageReference: useMarketplaceImage ? {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        } : {
          id: goldenImageId
        }
        osDisk: {
          caching: 'ReadWrite'
          managedDisk: { storageAccountType: 'Premium_LRS' }
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-web'
            properties: {
              primary: true
              networkSecurityGroup: { id: nsgWebId }
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    primary: true
                    subnet: { id: webSubnetId }
                    applicationGatewayBackendAddressPools: empty(appGwBackendPoolId) ? [] : [
                      { id: appGwBackendPoolId }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'AzureMonitorLinuxAgent'
            properties: {
              publisher: 'Microsoft.Azure.Monitor'
              type: 'AzureMonitorLinuxAgent'
              typeHandlerVersion: '1.29'
              autoUpgradeMinorVersion: true
            }
          }
        ]
      }
    }
  }
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscale-nodeapp-${env}'
  location: location
  tags: tags
  properties: {
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'default'
        capacity: { minimum: '6', maximum: '15', default: string(instanceCount) }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: { direction: 'Increase', type: 'ChangeCount', value: '3', cooldown: 'PT5M' }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: { direction: 'Decrease', type: 'ChangeCount', value: '3', cooldown: 'PT10M' }
          }
        ]
      }
    ]
  }
}

output vmssId string = vmss.id
output vmssName string = vmss.name
