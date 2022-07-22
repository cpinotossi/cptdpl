targetScope = 'resourceGroup'

param postfix string
param prefix string
param location string
param cidervnet string
param cidersubnet string
param ciderbastion string
param ciderdnsrin string
param ciderdnsrout string


resource vnethub 'Microsoft.Network/virtualNetworks@2021-08-01' = {
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
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ciderbastion
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'dnsrin'
        properties: {
          addressPrefix: ciderdnsrin
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
          privateEndpointNetworkPolicies:'Disabled'
          privateLinkServiceNetworkPolicies:'Enabled'
        }
      }
      {
        name: 'dnsrout'
        properties: {
          addressPrefix: ciderdnsrout
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
          privateEndpointNetworkPolicies:'Disabled'
          privateLinkServiceNetworkPolicies:'Enabled'
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

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}${postfix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: '${prefix}${postfix}'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    dnsName:'${prefix}${postfix}.bastion.azure.com'
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${prefix}${postfix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnethub.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

@description('VNet Name')
output vnetname string = vnethub.name
