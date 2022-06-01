// one common file for all jobs, hence some jobs might not use some variables and so on

@description('Location for all resources.')
param location string = resourceGroup().location

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

var image = '${containerRegistry.properties.loginServer}/playground/performance'
var mountPath = '/mnt'
var filePath = '${mountPath}/${fileName}'

var command = [
  'python'
  '/tests/data/cloud.py'
  'full'
  filePath
  ilinesNumber
  xlinesNumber
  samplesNumber
]

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageResourceName
}


resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: 'cisetupjob'
  location: location
  properties: {
    containers: [
      {
        name: 'big-job'
        properties: {
          // variables are common for all the jobs
          environmentVariables: [
            {
              name: 'STORAGE_LOCATION'
              value: storage.properties.primaryEndpoints.blob
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT_KEY'
              secureValue: storage.listKeys().keys[0].value
            }
            {
              name: 'FORCE_CONTAINER_RESTART_ON_CREATION_CHEAT'
              value: random
            }
          ]
          image: image
          command: command
          volumeMounts: [
            {
              name: 'localthing'
              mountPath: mountPath
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 2
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
    sku: 'Standard'
    imageRegistryCredentials: [
      {
        server: containerRegistry.properties.loginServer
        username: containerRegistry.listCredentials().username
        password: containerRegistry.listCredentials().passwords[0].value
      }
    ]
    volumes: [
      {
        name: 'localthing'
        emptyDir: {}
      }
    ]
  }
}

output serverURL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
