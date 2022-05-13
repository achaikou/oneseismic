@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

param location string = resourceGroup().location

@description('Storage account with the seismic data.')
param storageResourceName string = '${setupPrefix}0storage'
@description('Container registry where server images are stored.')
param containerRegistryResourceName string = '${setupPrefix}0containerRegistry'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryResourceName
}

var imageName = '${containerRegistry.properties.loginServer}/playground/performance'
var mountPath = '/mnt'
var fileName = 'temp.segy'
var filePath = '${mountPath}/${fileName}'

// impossible to run two commands
module cleanup 'job.bicep' = {
  name: 'cleanupContainerInstance'
  params: {
    name: '${setupPrefix}-cleanup-files-job'
    image: imageName
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    command: [
      'python'
      '/tests/data/azure.py'
      'delete_container'
      ';'

      'rm'
      filePath
    ]
    mountPath: mountPath
  }
}
