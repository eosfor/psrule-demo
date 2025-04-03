// functionapp.bicep
param location string
param functionName string
param planId string
param functionSubnetId string
param privateEndpointSubnetId string

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: planId
    siteConfig: {
      linuxFxVersion: 'DOTNET|6.0'
    }
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
  }
}

resource vnetIntegration 'Microsoft.Web/sites/networkConfig@2024-04-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: functionSubnetId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'function-pe'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'function-pe-connection'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: ['sites']
        }
      }
    ]
  }
}
