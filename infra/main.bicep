targetScope = 'resourceGroup'

param environmentName string
param dbAdminGroupName string
param dbAdminGroupId string
param sqlProvisionerName string

param location string = resourceGroup().location

var appName = 'app-${environmentName}-renldx'

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
    dbAdminGroupName: dbAdminGroupName
    dbAdminGroupId: dbAdminGroupId
    sqlProvisionerName: sqlProvisionerName
    appServiceName: appName
    tags: tags
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    appName: appName
    keyVaultId: keyVault.outputs.vaultId
    keyVaultName: keyVault.outputs.vaultName
    keyVaultUri: keyVault.outputs.vaultUri
    dbConnectionString: sqlServer.outputs.connectionString
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
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
