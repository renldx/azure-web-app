targetScope = 'resourceGroup'

param environmentName string
param location string = resourceGroup().location

@secure()
param dbAdminUsername string

@secure()
param dbAdminPassword string

var tags = {}

// --- Foundation ---

module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    location: location
    name: 'law-${environmentName}'
    tags: tags
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    name: 'kv-${environmentName}-renldx'
    dbConnectionString: sqlServer.outputs.connectionString
    tags: tags
  }
}

// --- Monitoring ---

module appInsights 'modules/applicationinsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    name: 'ai-${environmentName}'
    workspaceId: logAnalytics.outputs.resourceId
    tags: tags
  }
}

// --- Data & Compute ---

module sqlServer 'modules/sql.bicep' = {
  name: 'sqlDeployment'
  params: {
    location: location
    serverName: 'sql-${environmentName}-renldx'
    // Pass Key Vault secrets or references here if needed
    dbAdminUsername: dbAdminUsername
    dbAdminPassword: dbAdminPassword
    tags: tags
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    appName: 'app-${environmentName}-renldx'
    keyVaultUri: keyVault.outputs.vaultUri
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    keyVaultId: keyVault.outputs.vaultId
    keyVaultName: keyVault.outputs.vaultName
    tags: tags
  }
}

// --- Alerts ---

module actionGroup 'modules/actiongroup.bicep' = {
  name: 'actionGroupDeployment'
  params: {
    name: 'ag-${environmentName}'
    tags: tags
  }
}

module smartAlerts 'modules/smartdetectionalerts.bicep' = {
  name: 'smartAlertsDeployment'
  params: {
    appInsightsName: appInsights.outputs.appInsightsName
    appInsightsId: appInsights.outputs.appInsightsId
    actionGroupId: actionGroup.outputs.resourceId
    tags: tags
  }
}
