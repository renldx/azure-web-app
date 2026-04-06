param location string
param serverName string
param dbAdminGroupName string
param dbAdminGroupId string
param sqlProvisionerName string
param appServiceName string
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = {
  name: serverName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned' // Needs "Directory Readers" permission for user creation
  }
  properties: {
    administratorLogin: 'server-admin'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: dbAdminGroupName
      sid: dbAdminGroupId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01' = {
  name: 'AllowAzureServices'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: sqlServer
  name: 'my-sql-database'
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    capacity: 2
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    autoPauseDelay: 60
    minCapacity: json('0.5')
    requestedBackupStorageRedundancy: 'Local'
    
    // Keep these only if you are specifically using the "Azure Free" offer
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
  }
}

resource sqlProvisionerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sqlProvisionerName
}

resource createAppUser 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'sql-create-app-user'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sqlProvisionerIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '14.0'
    timeout: 'PT10M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'SQL_SERVER_NAME'
        value: sqlServer.name
      }
      {
        name: 'SQL_DATABASE_NAME'
        value: sqlDatabase.name
      }
      {
        name: 'APP_IDENTITY_NAME'
        value: appServiceName
      }
    ]
    scriptContent: '''
      Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber

      $server = $Env:SQL_SERVER_NAME
      $database = $Env:SQL_DATABASE_NAME
      $appIdentityName = $Env:APP_IDENTITY_NAME
      $token = (Get-AzAccessToken -ResourceUrl "https://database.windows.net/").Token

      $query = @"
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = '$appIdentityName'
)
BEGIN
    CREATE USER [$appIdentityName] FROM EXTERNAL PROVIDER;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
    WHERE r.name = 'db_datareader' AND u.name = '$appIdentityName'
)
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [$appIdentityName];
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
    WHERE r.name = 'db_datawriter' AND u.name = '$appIdentityName'
)
BEGIN
    ALTER ROLE db_datawriter ADD MEMBER [$appIdentityName];
END;

SELECT
    u.name AS principal_name,
    u.type_desc AS principal_type,
    r.name AS role_name
FROM sys.database_principals u
LEFT JOIN sys.database_role_members drm
    ON u.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r
    ON drm.role_principal_id = r.principal_id
WHERE u.name = '$appIdentityName';
"@

      $result = Invoke-Sqlcmd `
        -ServerInstance "$server.database.windows.net" `
        -Database $database `
        -AccessToken $token `
        -Query $query

      $rows = @($result)
      $first = $rows | Select-Object -First 1

      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['row_count'] = $rows.Count
      $DeploymentScriptOutputs['first_principal_name'] = [string]$first.principal_name
      $DeploymentScriptOutputs['first_principal_type'] = [string]$first.principal_type
      $DeploymentScriptOutputs['first_role_name'] = [string]$first.role_name
    '''
  }
}

output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default";'
