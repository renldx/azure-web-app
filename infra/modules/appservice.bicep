param location string
param appName string
param vaultUri string
param appInsightsConnectionString string
param vaultId string
param vaultName string
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
    // We only add 'reserved: true' if this were a Linux plan.
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
          name: 'KeyVaultUrl' // Used to fetch the DB connection string
          value: vaultUri
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

resource targetKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: vaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vaultId, appServiceApp.id, 'secret-reader-role')
  scope: targetKeyVault
  properties: {
    // 'Key Vault Secrets User' Role ID
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: appServiceApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
