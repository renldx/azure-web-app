param location string
param appName string
param appInsightsInstrumentationKey string
param dbConnectionString string
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
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: dbConnectionString
        }
      ]
    }
  }
}
