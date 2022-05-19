@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

@description('Random value which will hopefully make containers to restart every time.')
param random string

@description('Name of the created segy file')
param fileName string

param location string = resourceGroup().location

/**
  * All the dependent existing resources.
  * At the moment all the below are expected in current resourceGroup.
  */
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
var uploadLogFilePath = '${mountPath}/upload.log'


module uploadFile 'job.bicep' = {
  name: 'fileUploadContainerInstance'
  params: {
    name: '${setupPrefix}-upload-file-job'
    image: imageName
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    logFilePath: uploadLogFilePath
    command: [
      '/bin/sh'
      '-c'
      'echo python /tests/data/cloud.py upload_container ${filePath} > ${uploadLogFilePath}'
    ]
    mountPath: mountPath
    random: random
  }
}

