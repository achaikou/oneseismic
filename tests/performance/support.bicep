@description('Short name prefix for all new deployments')
param setupPrefix string = ''

@description('Name of File Share used for temporary storing created files.')
param fileShareName string = 'performanceshare'

@description('Storage account with the seismic data.')
param storageResourceName string = '${setupPrefix}0storage'


resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageResourceName

  resource service 'fileServices' = {
    name: 'default'

    resource share 'shares' = {
      name: fileShareName
    }
  }
}

