// main.bicep — DevSecOps demo infrastructure
// Secure-by-default patterns demonstrated here:
//  - System-assigned managed identity on App Service (no connection-string secrets)
//  - RBAC role assignments instead of API keys for OpenAI + AI Search
//  - HTTPS-only, TLS 1.2 minimum, no public FTP
//  - Diagnostic settings wired to Log Analytics for audit/monitoring
targetScope = 'resourceGroup'

@description('Short, unique suffix to disambiguate resource names')
param nameSuffix string = uniqueString(resourceGroup().id)

@description('Azure region for App Service / Log Analytics resources')
param location string = resourceGroup().location

@description('Azure region for AI resources (OpenAI, AI Search). Kept separate because Azure OpenAI SKU availability is region-gated per subscription and may differ from the general-purpose region above.')
param aiLocation string = 'eastus'

@description('Web app name; must be globally unique under azurewebsites.net. Pass explicitly from CI so the CD pipeline can target a known, fixed name.')
param webAppName string = 'app-devsecops-${nameSuffix}'

@description('Whether to assign data-plane RBAC roles (OpenAI User, Search Index Data Reader) to the web app identity. The CI deployment principal is intentionally scoped without Microsoft.Authorization/roleAssignments/write (to avoid granting it privilege-escalation rights), so these are applied out-of-band by a privileged operator on first deploy; set to true to let a sufficiently-privileged caller apply them inline instead.')
param deployRbacRoleAssignments bool = false

var appServicePlanName = 'asp-devsecops-${nameSuffix}'
var openAiName = 'aoai-devsecops-${nameSuffix}'
var searchName = 'srch-devsecops-${nameSuffix}'
var logAnalyticsName = 'log-devsecops-${nameSuffix}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      linuxFxVersion: 'PYTHON|3.12'
      appSettings: [
        { name: 'AZURE_OPENAI_ENDPOINT', value: openAi.properties.endpoint }
        { name: 'AZURE_OPENAI_DEPLOYMENT', value: 'gpt-4o-mini' }
        { name: 'AZURE_SEARCH_ENDPOINT', value: 'https://${search.name}.search.windows.net' }
        { name: 'AZURE_SEARCH_INDEX', value: 'demo-index' }
        { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT', value: 'true' }
      ]
    }
  }
}

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-webapp'
  scope: webApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: aiLocation
  kind: 'OpenAI'
  sku: { name: 'S0' }
  properties: {
    publicNetworkAccess: 'Enabled' // Demo only — restrict with private endpoints for production
    disableLocalAuth: true // Forces Entra ID auth; no API keys
  }
}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchName
  location: aiLocation
  sku: { name: 'basic' }
  properties: {
    disableLocalAuth: true // Forces Entra ID (RBAC) auth; no admin/query keys
  }
}

// RBAC: let the web app's managed identity call Azure OpenAI
resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployRbacRoleAssignments) {
  name: guid(openAi.id, webApp.id, 'Cognitive Services OpenAI User')
  scope: openAi
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
    )
  }
}

// RBAC: let the web app's managed identity query Azure AI Search
resource searchRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployRbacRoleAssignments) {
  name: guid(search.id, webApp.id, 'Search Index Data Reader')
  scope: search
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '1407120a-92aa-4202-b7e9-c0e197c71c8f' // Search Index Data Reader
    )
  }
}

output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output openAiEndpoint string = openAi.properties.endpoint
output searchEndpoint string = 'https://${search.name}.search.windows.net'
