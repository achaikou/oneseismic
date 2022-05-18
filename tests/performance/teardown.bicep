@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

@description('Random value which will hopefully make containers to restart every time.')
param random string

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
module deleteContainer 'job.bicep' = {
  name: 'deleteContainerContainerInstance'
  params: {
    name: '${setupPrefix}-delete-container-job'
    image: imageName
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    command: [
      'python'
      '/tests/data/cloud.py'
      'delete_container'
    ]
    mountPath: mountPath
    random: random
  }
}

module deleteFile 'job.bicep' = {
  name: 'deleteFileContainerInstance'
  params: {
    name: '${setupPrefix}-delete-file-job'
    image: imageName
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    command: [
      'rm'
      filePath
    ]
    mountPath: mountPath
    random: random
  }
}




