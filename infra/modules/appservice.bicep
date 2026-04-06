param location string
param appName string
param keyVaultId string
param keyVaultName string
param keyVaultUri string
param dbConnectionString string
param appInsightsConnectionString string
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app'
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    // Usually, for a basic plan, the properties block can be empty.
    // We only add "reserved: true" if this were a Linux plan.
  }
}

resource appServiceApp 'Microsoft.Web/sites@2025-03-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app'
  identity: {
    type: 'SystemAssigned' // Crucial for "passwordless" access to SQL/Key Vault
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      alwaysOn: false
      http20Enabled: true
      appSettings: [
        {
          name: 'KEY_VAULT_URL'
          value: keyVaultUri
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      connectionStrings: [
        {
          name: 'WeatherDb'
          connectionString: dbConnectionString
          type: 'SQLAzure'
        }
      ]
    }
  }
}

resource targetKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, appServiceApp.id, 'secret-reader-role')
  scope: targetKeyVault
  properties: {
    // "Key Vault Secrets User" Role ID
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: appServiceApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
