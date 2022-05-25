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

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' existing = {
  name: containerAppName
}

var imageName = '${containerRegistry.properties.loginServer}/playground/performance'
var mountPath = '/mnt'
var filePath = '${mountPath}/${fileName}'
// var createLogFilePath = '${mountPath}/create.log'


// move setup out? App, fileshare. Or create address as parameter? We can reuse on production then maybe?
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
    // do not do multi-taks commands like '/bin/sh' '-c' 'command1; command2' - it doesn't exit on its own
    // command: [
    //   '/bin/sh'
    //   '-c'
    //   'python /tests/data/create.py dimensional ${filePath} ${ilinesNumber} ${xlinesNumber} ${samplesNumber}'
    // ]
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
    // logFilePath: createLogFilePath
    location: location
    containerRegistryResourceName: containerRegistryResourceName
    storageResourceName: storageResourceName
    random: random
  }
  dependsOn: [
    fileShare
  ]
}

output serverURL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
