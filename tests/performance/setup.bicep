@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

@description('Random value which will hopefully make containers to restart every time.')
param random string

@description('Data creation only: Number of ilines')
param ilinesNumber string

@description('Data creation only: Number of xlines')
param xlinesNumber string

@description('Data creation only: Number of samples')
param samplesNumber string

param location string = resourceGroup().location

/**
  * All the dependent existing resources.
  * At the moment all the below are expected in current resourceGroup.
  */
@description('Storage account with the seismic data.')
param storageResourceName string = '${setupPrefix}0storage'
@description('Container registry where server images are stored.')
param containerRegistryResourceName string = '${setupPrefix}0containerRegistry'
@description('Container app used for access.')
param containerAppName string = '${setupPrefix}-nginx'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryResourceName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageResourceName
}

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' existing = {
  name: containerAppName
}

var imageName = '${containerRegistry.properties.loginServer}/playground/performance'
var mountPath = '/mnt'
var fileName = 'temp.segy'
var filePath = '${mountPath}/${fileName}'

module fileShare 'support.bicep' = {
  name: 'fileShareSetup'
  params: {
    storageResourceName: storageResourceName
  }
}

module createFile 'job.bicep' = {
  name: 'fileCreationContainerInstance'
  params: {
    name: '${setupPrefix}-create-file-job'
    image: imageName
    command: [
      'python'
      '/tests/data/create.py'
      'dimensional'
      filePath
      ilinesNumber
      xlinesNumber
      samplesNumber
    ]
    mountPath: mountPath
    // ilinesNumber: ilinesNumber
    // xlinesNumber: xlinesNumber
    // samplesNumber: samplesNumber
    // sourceFileName: fileName
    random: random
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
  }
  dependsOn: [
    fileShare
  ]
}


module uploadFile 'job.bicep' = {
  name: 'fileUploadContainerInstance'
  params: {
    name: '${setupPrefix}-upload-file-job'
    image: imageName
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    command: [
      'python'
      '/tests/data/cloud.py'
      'upload_container'
      filePath
    ]
    mountPath: mountPath
    random: random
  }
  dependsOn: [
    createFile
  ]
}

output serverURL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
