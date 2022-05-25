@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

@description('Random value which will hopefully make containers to restart every time.')
param random string

@description('Name of the created segy file')
param fileName string

@description('GUID')
param guid string

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
var filePath = '${mountPath}/${fileName}'
//var cleanupLogFilePath = '${mountPath}/cleanup.log'

// impossible to run two commands
module cleanupContainer 'job.bicep' = {
  name: 'cleanupContainerInstance'
  params: {
    name: '${setupPrefix}-cleanup-container-job'
    image: imageName
    location: location
    // logFilePath: cleanupLogFilePath
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    command: [
      '/bin/sh'
      '-c'
      'rm ${filePath}; python /tests/data/cloud.py delete_container ${guid}'
    ]
    mountPath: mountPath
    random: random
  }
}




