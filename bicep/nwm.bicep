param prefix string
param location string
param subid string
param hubname string
param vnetnames array = [
  'cptdplop'
  'cptdplhub'
  'cptdplspoke'
]

//var condition = '{"allOf":[{"value": "${resourceGroup().name}","equals": "${prefix}"}]}'
//var condition = '{"allOf":[{"value": "cptdpl","equals": "${prefix}"}]}'
//var condition = '"{\n   \\"allOf\\": [\n      {\n         \\"value\\": \\"[resourceGroup().Name]\\",\n         \\"equals\\": \\"cptdpl\\"\n      }\n   ]\n}"'

resource hub 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: hubname
}

resource nwm 'Microsoft.Network/networkManagers@2022-04-01-preview' = {
  name: prefix
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subid}'
      ]
    }
  }
}

resource nwg 'Microsoft.Network/networkManagers/networkGroups@2021-02-01-preview' = {
  name: prefix
  parent: nwm
  properties: {
    //conditionalMembership: condition
    groupMembers:[for name in vnetnames:{
        resourceId: resourceId('Microsoft.Network/virtualNetworks', name)
      }]
    displayName: prefix
  }
}

resource nwmcon 'Microsoft.Network/networkManagers/connectivityConfigurations@2021-02-01-preview' = {
  name: prefix
  parent: nwm
  properties: {
    appliesToGroups: [
      {
        groupConnectivity: 'None'
        isGlobal: 'False'
        networkGroupId: nwg.id
        useHubGateway: 'False'
      }
    ]
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'True'
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: hub.id
      }
    ]
    isGlobal: 'False'
  }
}
