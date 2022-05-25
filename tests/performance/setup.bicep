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
// @description('Container app used for access.')
// param containerAppName string = '${setupPrefix}-nginx'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryResourceName
}


var imageName = '${containerRegistry.properties.loginServer}/playground/performance'
var mountPath = '/data'
var filePath = '${mountPath}/${fileName}'
// var createLogFilePath = '${mountPath}/create.log'

var createJob = 'python /tests/data/create.py dimensional ${filePath} ${ilinesNumber} ${xlinesNumber} ${samplesNumber}'
var uploadJob = 'python /tests/data/cloud.py upload_container ${filePath}'

module setup 'job.bicep' = {
  name: 'setupContainerInstance'
  params: {
    name: '${setupPrefix}-performance-setup-job'
    image: imageName
    command: [
      '/bin/sh'
      '-c'
      '${createJob}; ${uploadJob}'
    ]
    //mountPath: mountPath
    // logFilePath: createLogFilePath
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    random: random
  }
}

