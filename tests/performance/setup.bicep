@description('Setup ID: a unique prefix for resource names.')
param setupPrefix string

@description('Random value which will hopefully make containers to restart every time.')
param random string

@description('Name of the created segy file')
param fileName string

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
var filePath = '${mountPath}/${fileName}'
var createLogFilePath = '${mountPath}/create.log'
var uploadLogFilePath = '${mountPath}/upload.log'

module fileShare 'support.bicep' = {
  name: 'fileShareSetup'
  params: {
    storageResourceName: storageResourceName
  }
}

// random thing doesn't work.  We try to force it to redeploy container every time
// we would need it due to parameters as they are different

module createFile 'job.bicep' = {
  name: 'fileCreationContainerInstance'
  params: {
    name: '${setupPrefix}-create-file-job'
    image: imageName
    command: [
      '/bin/sh'
      '-c'
      'echo python /tests/data/create.py dimensional ${filePath} ${ilinesNumber} ${xlinesNumber} ${samplesNumber} > ${createLogFilePath}'
    ]
    mountPath: mountPath
    logFilePath: createLogFilePath
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    random: random
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
    logFilePath: uploadLogFilePath
    command: [
      '/bin/sh'
      '-c'
      'echo python /tests/data/cloud.py upload_container ${filePath} > ${uploadLogFilePath}'
    ]
    mountPath: mountPath
    random: random
  }
  dependsOn: [
    createFile
  ]
}

output serverURL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
