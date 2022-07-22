param prefix string
param location string
param plname string
param vnetname  string
param saname string


resource sa 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: saname
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetname
}

resource pe 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: plname
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${plname}${saname}'
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [
            'blob'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${vnet.id}/subnets/${prefix}'
    }
    customDnsConfigs: []
  }
}

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource pedz 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: prefix
        properties: {
          privateDnsZoneId: pdns.id
        }
      }
    ]
  }
}

resource dnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: pdns
  name: 'pldspoke'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
