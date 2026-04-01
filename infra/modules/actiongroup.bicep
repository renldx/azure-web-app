param name string
param tags object = {}

resource actionGroup 'Microsoft.Insights/actionGroups@2024-10-01-preview' = {
  name: name
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'SmartDetect'
    enabled: true
    armRoleReceivers: [
      {
        name: 'Admins'
        roleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa' // Monitoring Contributor
        useCommonAlertSchema: true
      }
      {
        name: 'Readers'
        roleId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05' // Monitoring Reader
        useCommonAlertSchema: true
      }
    ]
  }
}

output resourceId string = actionGroup.id
