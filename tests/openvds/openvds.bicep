/* Once path-based routing is implemented in Container Apps, nginx wrapper can
 * be removed and file can be split into two - query and result one. It will
 * allow applications to scale separately.
 */

@description('Type of configuration')
@allowed([
  'test'
  'prod'
])
param environment string

@description('Id of revision in the container registry')
param revisionId string

@description('Name of oneseismic image in the container registry')
param containerImageName string = 'playground/openvds'


param location string = resourceGroup().location

/*
 * All the dependent existing resources.
 * At the moment all the below are expected in current resourceGroup.
 */
@description('Storage account with the seismic data.')
param storageResourceName string

param storageResourceGroupName string
@description('Container registry where server images are stored.')
param containerRegistryResourceName string
@description('Container Apps environment to which applications are associated')
param containerAppsEnvironmentResourceName string

var containerCPU = {
  // workaround: values are supposed to be floats, but bicep doesn't support it
  prod: 1
  test: 1
}
var containerMemory = {
  prod: '2Gi'
  test: '2Gi'
}

var minReplicas = {
  prod: 0
  test: 0
}

var maxReplicas = {
  prod: 10
  test: 10
}

/* Note: explicit passing of resource objects is in development, so
 * it would be possibe to define them once in the main file and
 * pass the resources themselves.
 */
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppsEnvironmentResourceName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryResourceName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageResourceName
  scope: resourceGroup(storageResourceGroupName)
}


var imagePath = '${containerRegistry.properties.loginServer}/${containerImageName}:${revisionId}'



resource flaskContainerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'openvdsflask'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 5000
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          // issue 153, containerRegistry.properties.loginServer expected
          server: '${toLower(containerRegistry.name)}.azurecr.io'
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      revisionSuffix: '12th'

      containers: [
        {
          name: 'flask'
          image: imagePath
          resources: {
            cpu: containerCPU[environment]
            memory: containerMemory[environment]
          }
          env: [
            {
              name: 'STORAGE_URL'
              value: storage.properties.primaryEndpoints.blob
            }
          ]
          command: [
            'python'
          ]
          args: [
            '/tests/openvds/server.py'
          ]
          // command: [
          //   '/bin/sh'
          // ]
          // args: [
          //   '-c'
          //   'python /tests/openvds/server.py'
          // ]
        }
      ]
      scale: {
        minReplicas: minReplicas[environment]
        maxReplicas: maxReplicas[environment]
        // rules: [
        //   {
        //     name: 'http-rule'
        //     http: {
        //       metadata: {
        //           concurrentRequests: '2'
        //       }
        //   }
        //   }
        // ]
      }
    }
  }
}

output serverURL string = 'https://${flaskContainerApp.properties.configuration.ingress.fqdn}'
