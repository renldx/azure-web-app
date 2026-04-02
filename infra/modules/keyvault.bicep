param location string
param name string
param tags object = {}

@secure()
param dbConnectionString string

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
  }
}

resource sqlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ConnectionStrings--WeatherDb'
  properties: {
    value: dbConnectionString
  }
}

output vaultUri string = keyVault.properties.vaultUri
output vaultId string = keyVault.id
output vaultName string = keyVault.name
