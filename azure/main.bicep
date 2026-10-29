@description('Short lowercase prefix used in customer-owned Azure resource names.')
@minLength(3)
@maxLength(18)
param prefix string

@description('Customer-facing name recorded on the Azure resource group and resources.')
@minLength(3)
@maxLength(64)
param deploymentDisplayName string = 'Mission Shield Evaluation'

@description('Azure region for every resource in this evaluation deployment.')
param location string = resourceGroup().location

@allowed([
  'entra'
  'okta'
  'oidc'
])
@description('Identity provider used by this Mission Shield installation.')
param oidcProviderName string

@description('Exact HTTPS OIDC issuer. Entra must use one tenant ID, not common or organizations.')
param oidcIssuerUrl string

@description('OIDC application client ID.')
param oidcClientId string

@secure()
@description('OIDC application client secret.')
param oidcClientSecret string

@secure()
@minLength(32)
@description('Random secret used only for short-lived OIDC transaction state.')
param oidcTransactionSecret string

@description('Organization name used to create the first private workspace.')
@minLength(2)
@maxLength(160)
param initialOrganizationName string

@description('Email address of the first Workspace Owner.')
@minLength(3)
@maxLength(254)
param initialOwnerEmail string

@description('Microsoft Entra User Object ID for the first owner. Required for Entra deployments.')
@maxLength(200)
param initialOwnerDirectoryObjectId string = ''

@secure()
@minLength(20)
@description('Password for the customer-owned PostgreSQL administrator.')
param databaseAdministratorPassword string

@allowed([
  'Standard_B1ms'
  'Standard_B2s'
])
@description('PostgreSQL burstable compute size. B2s is the compatibility default; use B1ms only where Azure confirms it is available.')
param databaseSkuName string = 'Standard_B2s'

@minValue(7)
@maxValue(35)
@description('Days Azure retains PostgreSQL backups. Use 7 for a short evaluation and 14 to 35 for an ongoing workspace.')
param databaseBackupRetentionDays int = 7

@description('Role-managed email address for Azure database storage alerts. Leave blank to skip email alerts during a short evaluation.')
@maxLength(254)
param operationsContactEmail string = ''

@description('Published Mission Shield API container image pinned to the accepted release digest.')
param apiContainerImage string = 'ghcr.io/blam-labs/blamcore-mission-shield-api@sha256:06aa29d80e2166b31a2f27b88d2a419b734e623c25ce644b50518a007f68d7f2'

@description('Published Mission Shield web container image pinned to the accepted release digest.')
param webContainerImage string = 'ghcr.io/blam-labs/blamcore-mission-shield-web@sha256:1ab546d2d955a7379a7c707d03d22ba642309ff2cce1a3eef43611f2bf5687a0'

@description('Azure Container Apps environment resource name.')
param containerEnvironmentName string = '${prefix}-evaluation-environment'

@description('Mission Shield web container app resource name.')
param webAppName string = '${prefix}-web'

@description('Mission Shield API container app resource name.')
param apiAppName string = '${prefix}-api'

@description('Globally unique PostgreSQL Flexible Server resource name.')
param databaseName string = take('${prefix}-db-${uniqueString(resourceGroup().id)}', 63)

var resourceTags = {
  application: 'Mission Shield'
  deploymentName: deploymentDisplayName
  deploymentType: 'evaluation'
  customerOwned: 'true'
}
var webOrigin = 'https://${webAppName}.${environment.properties.defaultDomain}'
var apiOrigin = 'https://${apiAppName}.${environment.properties.defaultDomain}'
var databaseUrl = 'postgresql://missionshield:${uriComponent(databaseAdministratorPassword)}@${databaseName}.postgres.database.azure.com:5432/mission_shield?sslmode=require'
var emailAlertsEnabled = !empty(operationsContactEmail)
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvironmentName
  location: location
  tags: resourceTags
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    zoneRedundant: false
  }
}

resource databaseServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: databaseName
  location: location
  tags: resourceTags
  sku: {
    name: databaseSkuName
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'missionshield'
    administratorLoginPassword: databaseAdministratorPassword
    version: '16'
    createMode: 'Create'
    backup: {
      backupRetentionDays: databaseBackupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

resource operationsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (emailAlertsEnabled) {
  name: '${prefix}-operations'
  location: 'Global'
  tags: resourceTags
  properties: {
    groupShortName: take('${prefix}ops', 12)
    enabled: true
    emailReceivers: [
      {
        name: 'Mission Shield operations'
        emailAddress: operationsContactEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

resource databaseStorageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (emailAlertsEnabled) {
  name: '${prefix}-database-storage-warning'
  location: 'global'
  tags: resourceTags
  properties: {
    description: 'Mission Shield PostgreSQL storage is above 70 percent. Review capacity before the workspace is affected.'
    severity: 2
    enabled: true
    scopes: [
      databaseServer.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    autoMitigate: true
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    targetResourceRegion: location
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'StorageAboveSeventyPercent'
          metricName: 'storage_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 70
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          skipMetricValidation: false
        }
      ]
    }
    actions: [
      {
        actionGroupId: operationsActionGroup.id
      }
    ]
  }
}

resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: databaseServer
  name: 'AllowAzureServicesForEvaluation'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource applicationDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: databaseServer
  name: 'mission_shield'
  properties: {}
}

resource api 'Microsoft.App/containerApps@2024-03-01' = {
  name: apiAppName
  location: location
  tags: resourceTags
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      secrets: [
        #disable-next-line use-secure-value-for-secure-inputs
        { name: 'database-url', value: databaseUrl }
        { name: 'oidc-client-secret', value: oidcClientSecret }
        { name: 'oidc-transaction-secret', value: oidcTransactionSecret }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: apiContainerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            { name: 'API_ENV', value: 'staging' }
            { name: 'AUTH_MODE', value: 'oidc' }
            { name: 'DEMO_MODE_ENABLED', value: 'false' }
            { name: 'PUBLIC_BASE_URL', value: webOrigin }
            { name: 'API_BASE_URL', value: apiOrigin }
            { name: 'API_CORS_ORIGINS', value: webOrigin }
            { name: 'SECURE_COOKIES', value: 'true' }
            { name: 'SESSION_COOKIE_DOMAIN', value: environment.properties.defaultDomain }
            { name: 'SECURITY_HEADERS_ENABLED', value: 'true' }
            { name: 'STRUCTURED_REQUEST_LOGGING', value: 'true' }
            { name: 'RATE_LIMITING_ENABLED', value: 'true' }
            { name: 'OIDC_PROVIDER_NAME', value: oidcProviderName }
            { name: 'OIDC_ISSUER_URL', value: oidcIssuerUrl }
            { name: 'OIDC_CLIENT_ID', value: oidcClientId }
            { name: 'OIDC_CLIENT_SECRET', secretRef: 'oidc-client-secret' }
            { name: 'OIDC_TRANSACTION_SECRET', secretRef: 'oidc-transaction-secret' }
            { name: 'OIDC_REDIRECT_URL', value: '${apiOrigin}/v1/auth/callback' }
            { name: 'INITIAL_ORGANIZATION_NAME', value: initialOrganizationName }
            { name: 'INITIAL_OWNER_EMAIL', value: initialOwnerEmail }
            { name: 'INITIAL_OWNER_DIRECTORY_OBJECT_ID', value: initialOwnerDirectoryObjectId }
            { name: 'DATABASE_URL', secretRef: 'database-url' }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 2
        rules: [
          {
            name: 'http-demand'
            http: {
              metadata: {
                concurrentRequests: '25'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    applicationDatabase
    allowAzureServices
  ]
}

resource web 'Microsoft.App/containerApps@2024-03-01' = {
  name: webAppName
  location: location
  tags: resourceTags
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 3000
        transport: 'auto'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          name: 'web'
          image: webContainerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            { name: 'API_ENV', value: 'staging' }
            { name: 'API_INTERNAL_BASE_URL', value: apiOrigin }
            { name: 'NEXT_PUBLIC_API_BASE_URL', value: apiOrigin }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 2
        rules: [
          {
            name: 'http-demand'
            http: {
              metadata: {
                concurrentRequests: '25'
              }
            }
          }
        ]
      }
    }
  }
}

output webUrl string = webOrigin
output apiUrl string = apiOrigin
output oidcCallbackUrl string = '${apiOrigin}/v1/auth/callback'
output apiAppName string = api.name
output webAppName string = web.name
output databaseServerName string = databaseServer.name
output backupRetentionDays int = databaseBackupRetentionDays
output operationsEmailAlerts string = emailAlertsEnabled ? 'Enabled for the role-managed operations contact.' : 'Not configured. Add an operations contact before an ongoing pilot.'
output evaluationWarning string = 'Use fictional or non-sensitive test information only. This low-cost profile uses scale-to-zero containers and public Azure service endpoints.'
