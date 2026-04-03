param appInsightsName string
param appInsightsId string
param actionGroupId string
param tags object = {}

resource smartAlerts 'Microsoft.AlertsManagement/smartDetectorAlertRules@2021-04-01' = {
  name: 'Failure Anomalies - ${appInsightsName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT1M'
    detector: {
      id: 'FailureAnomaliesDetector'
    }
    scope: [
      appInsightsId 
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}
