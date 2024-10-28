targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location1 string
param location2 string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

module vnet1module 'azbicep/bicep/vnet.bicep' = {
  name: 'vnet1deploy'
  params: {
    prefix: prefix
    postfix: 'vnet1'
    location: location1
    cidervnet: '192.168.5.0/24'
    cidersubnet: '192.168.5.0/26'
    ciderbastion: '192.168.5.64/26'
    serviceendpointarray:[
      {
        locations:[
          location1
        ]
        service:'Microsoft.Storage'
      }
    ]
  }
}

module vnet2module 'azbicep/bicep/vnet.bicep' = {
  name: 'vnet2deploy'
  params: {
    prefix: prefix
    postfix: 'vnet2'
    location: location2
    cidervnet: '192.168.5.0/24'
    cidersubnet: '192.168.5.0/26'
    ciderbastion: '192.168.5.64/26'
    serviceendpointarray:[
      {
        locations:[
          location1
        ]
        service:'Microsoft.Storage'
      }
    ]
  }
}

module vnet1vmmodule 'azbicep/bicep/vm.bicep' = {
  name: 'vnet1vmdeploy'
  params: {
    prefix: prefix
    postfix: 'vm1'
    vnetname: vnet1module.outputs.vnetname
    location: location1
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '192.168.5.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnet1module
  ]
}

module vnet2vmmodule 'azbicep/bicep/vm.bicep' = {
  name: 'vnet2vmdeploy'
  params: {
    prefix: prefix
    postfix: 'vm2'
    vnetname: vnet2module.outputs.vnetname
    location: location2
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '192.168.5.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnet2module
  ]
}

// module law1 'azbicep/bicep/law.bicep' = {
//   name: 'law1deploy'
//   params: {
//     location: location1
//     prefix: prefix
//     postfix: '1'
//   }
// }

// module law2 'azbicep/bicep/law.bicep' = {
//   name: 'law2deploy'
//   params: {
//     location: location2
//     prefix: prefix
//     postfix: '2'
//   }
// }

// resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: '${prefix}.blob.core.windows.net'
//   location: 'global'
//   properties: {}
// }

// resource privateDnsZoneLink1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   parent: privateDnsZone
//   name: '${prefix}1'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: vnet1module.outputs.id
//     }
//   }
// }

// resource privateDnsZoneLink2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   parent: privateDnsZone
//   name: '${prefix}2'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: vnet2module.outputs.id
//     }
//   }
// }

// resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
//   name: prefix
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: prefix
//         properties: {
//           privateDnsZoneId: privateDnsZone.id
//         }
//       }
//     ]
//   }
// }

