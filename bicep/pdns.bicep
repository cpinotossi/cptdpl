targetScope = 'resourceGroup'

param vnetname string
param prefix string
param autoreg bool = false
param fqdn string


resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetname
}

resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: fqdn
  location: 'global'
}

resource pdnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: '${prefix}${vnetname}'
  location: 'global'
  properties: {
    registrationEnabled: autoreg
    virtualNetwork: {
      id: vnet.id
    }
  }
}
