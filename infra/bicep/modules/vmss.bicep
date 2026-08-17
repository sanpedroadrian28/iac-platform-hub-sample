param location string
param env string
param instanceCount int = 6
param sshPublicKey string
param goldenImageId string
param webSubnetId string
param nsgWebId string
param lbPoolId string

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: 'vmss-nodeapp-${env}'
  location: location
  zones: ['1', '2', '3']
  sku: { name: 'Standard_D2s_v5', capacity: instanceCount }
  properties: {
    zoneBalance: true
    upgradePolicy: { mode: 'Rolling' }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'nodeapp'
        adminUsername: 'azureuser'
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: { publicKeys: [{ path: '/home/azureuser/.ssh/authorized_keys', keyData: sshPublicKey }] }
        }
      }
      storageProfile: { imageReference: { id: goldenImageId } }
      networkProfile: {
        networkInterfaceConfigurations: [{
          name: 'nic-web'
          properties: {
            primary: true
            networkSecurityGroup: { id: nsgWebId }
            ipConfigurations: [{
              name: 'ipconfig1'
              properties: {
                subnet: { id: webSubnetId }
                loadBalancerBackendAddressPools: [{ id: lbPoolId }]
              }
            }]
          }
        }]
      }
      extensionProfile: {
        extensions: [{
          name: 'AzureMonitorLinuxAgent'
          properties: {
            publisher: 'Microsoft.Azure.Monitor'
            type: 'AzureMonitorLinuxAgent'
            autoUpgradeMinorVersion: true
          }
        }]
      }
    }
  }
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscale-nodeapp'
  location: location
  properties: {
    targetResourceUri: vmss.id
    enabled: true
    profiles: [{
      name: 'default'
      capacity: { minimum: '6', maximum: '15', default: '6' }
      rules: [{
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
      }]
    }]
  }
}

output vmssId string = vmss.id

