using '../main.bicep'

param environmentName = 'dev'

// Manual
param dbAdminGroupName = 'DB-Admins'
param dbAdminGroupId = 'f8a9fe81-efda-4a60-b96d-c2388725c97f'
param sqlProvisionerName = 'id-sql-provisioner' // Needs "DB-Admins" membership for deployment script
