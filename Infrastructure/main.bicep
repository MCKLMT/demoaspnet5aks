param webAppName string {
  minLength: 2
  default: 'AzureLinuxApp'
}

param location string {
  default: resourceGroup().location
}

var appServicePlanName = 'AppServicePlan-${webAppName}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|5.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITE_WEBDEPLOY_USE_SCM'
          value: 'true'
        }
      ]
    }
  }
}
