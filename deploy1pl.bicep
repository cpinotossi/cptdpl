targetScope='resourceGroup'

param location1 string
param location2 string
param prefix string
param myobjectid string

// module sab 'azbicep/bicep/sab.bicep' = {
//   name: prefix
//   params: {
//     location: location1
//     myObjectId: myobjectid
//     postfix: '1'
//     prefix: prefix
//     skuname:'Standard_GRS'
//   }
// }

resource sab 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: prefix
}

resource vnet1 'Microsoft.ScVmm/virtualNetworks@2020-06-05-preview' existing = {
  name: '${prefix}vnet1'
}

resource vnet2 'Microsoft.ScVmm/virtualNetworks@2020-06-05-preview' existing = {
  name: '${prefix}vnet2'
}

module pe1 'azbicep/bicep/peblob.bicep' = {
  name: 'pe1deploy'
  params: {
    location: location1
    postfix: '1'
    prefix: prefix
    saname: sab.name
    vnetname: vnet1.name
    privateip: '192.168.5.5'
  }
  dependsOn:[
    sab
  ]
}

module pe2 'azbicep/bicep/peblob.bicep' = {
  name: 'pe2deploy'
  params: {
    location: location2
    postfix: '2'
    prefix: prefix
    saname: sab.name
    vnetname: vnet2.name
    privateip: '192.168.5.5'
  }
  dependsOn:[
    sab
  ]
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${prefix}.blob.core.windows.net'
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${prefix}1'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet1.id
    }
  }
}

resource privateDnsZoneLink2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${prefix}2'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet2.id
    }
  }
}

resource pe1DnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${prefix}1/${prefix}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: prefix
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn:[
    pe1
  ]
}

resource pe2DnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${prefix}2/${prefix}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: prefix
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn:[
    pe2
  ]
}
