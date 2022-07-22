targetScope = 'resourceGroup'

param prefix string
param postfix string
param location string
param cidervnet string
param cidersubnet string


resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${prefix}${postfix}'
  location: location
  properties: {
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: cidersubnet
          serviceEndpoints:[
            {
              locations:[
                location
              ]
              service:'Microsoft.Storage'
            }
          ]
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        cidervnet
      ]
    }
  }
}

@description('VNet Name')
output vnetname string = vnet.name



