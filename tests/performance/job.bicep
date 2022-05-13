// one common file for all jobs, hence some jobs might not use some variables and so on

@description('Name for the container group')
param name string

@description('Executed command')
param command array

@description('Container image to deploy')
param image string

// @description('Segy file name')
// param sourceFileName string = 'test.segy'

@description('Mount share path')
param mountPath string

@description('Name of File Share used for temporary storing created files.')
param fileShareName string = 'performanceshare'

// @description('Data creation only: Number of samples')
// param samplesNumber string = '5'

// @description('Data creation only: Number of ilines')
// param ilinesNumber string = '5'

// @description('Data creation only: Number of xlines')
// param xlinesNumber string = '5'

@description('Random value which will hopefully make containers to restart every time.')
param random string

@description('Location for all resources.')
param location string = resourceGroup().location

/*
* All the dependent existing resources.
* At the moment all the below are expected in current resourceGroup.
*/
@description('Storage account (blob and file share) for temporary storing test data.')
param storageResourceName string
@description('Container registry where server images are stored.')
param containerRegistryResourceName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryResourceName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageResourceName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
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
            // {
            //   name: 'FILE_PATH'
            //   value: '${mountPath}/${sourceFileName}'
            // }
            // {
            //   name: 'SAMPLES_NUMBER'
            //   value: samplesNumber
            // }
            // {
            //   name: 'ILINES_NUMBER'
            //   value: ilinesNumber
            // }
            // {
            //   name: 'XLINES_NUMBER'
            //   value: xlinesNumber
            // }
            {
              name: 'UNUSED_RANDOM'
              value: random
            }
          ]
          image: image
          command: command
          volumeMounts: [
            {
              name: 'filesharevolume'
              mountPath: mountPath
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
    imageRegistryCredentials: [
      {
        server: containerRegistry.properties.loginServer
        username: containerRegistry.listCredentials().username
        password: containerRegistry.listCredentials().passwords[0].value
      }
    ]
    volumes: [
      {
        name: 'filesharevolume'
        azureFile: {
          shareName: fileShareName
          storageAccountName: storage.name
          storageAccountKey: storage.listKeys().keys[0].value
        }
      }
    ]
  }
}

