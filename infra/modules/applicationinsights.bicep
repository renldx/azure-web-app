param location string
param name string
param workspaceId string
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    RetentionInDays: 90
  }
}

output appInsightsName string = appInsights.name
output appInsightsId string = appInsights.id
