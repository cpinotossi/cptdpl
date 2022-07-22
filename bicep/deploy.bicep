targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

module vnetopmodule 'vnetspoke.bicep' = {
  name: 'vnetopdeploy'
  params: {
    prefix: prefix
    postfix: 'op'
    location: location
    cidervnet: '172.16.0.0/16'
    cidersubnet: '172.16.0.0/24'
  }
}

module vnethubmodule 'vnethub.bicep' = {
  name: 'vnethubdeploy'
  params: {
    prefix: prefix
    postfix: 'hub'
    location: location
    cidervnet: '10.1.0.0/16'
    cidersubnet: '10.1.0.0/24'
    ciderbastion: '10.1.1.0/24'
    ciderdnsrin: '10.1.2.0/24'
    ciderdnsrout: '10.1.3.0/24'
  }
}

module vnetspoke1module 'vnetspoke.bicep' = {
  name: 'vnetspokedeploy'
  params: {
    prefix: prefix
    postfix: 'spoke1'
    location: location
    cidervnet: '10.2.0.0/16'
    cidersubnet: '10.2.0.0/24'
  }
}

module vmopmodule 'vm.bicep' = {
  name: 'vmopdeploy'
  params: {
    prefix: prefix
    postfix: 'op'
    vnetname: vnetopmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '172.16.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetopmodule
  ]
}

module vmhubmodule 'vm.bicep' = {
  name: 'vmhubdeploy'
  params: {
    prefix: prefix
    postfix: 'hub'
    vnetname: vnethubmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.1.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnethubmodule
  ]
}

module vmspoke1module 'vm.bicep' = {
  name: 'vmspoke1deploy'
  params: {
    prefix: prefix
    postfix: 'spoke1'
    vnetname: vnetspoke1module.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.2.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetspoke1module
  ]
}

module sab1 'sab.bicep' = {
  name: 'sab1deploy'
  params: {
    vnetname: '${prefix}spoke1'
    prefix: prefix
    postfix: '1'
    location: location
    myip: myip
    myObjectId: myobjectid
  }
}

module sab2 'sab.bicep' = {
  name: 'sab2deploy'
  params: {
    vnetname: '${prefix}spoke1'
    prefix: prefix
    postfix: '2'
    location: location
    myip: myip
    myObjectId: myobjectid
  }
}

module pl1 'pldns.bicep' = {
  name: 'pl1deploy'
  params: {
    prefix: prefix
    plname: '${prefix}pl1'
    location: location
    saname: '${prefix}1'
    vnetname: '${prefix}spoke1'
  }
  dependsOn:[
    vnetspoke1module
    sab1
  ]
}

module pl2 'pl.bicep' = {
  name: 'pl2deploy'
  params: {
    prefix: prefix
    plname: '${prefix}pl2'
    location: location
    saname: '${prefix}2'
    vnetname: '${prefix}spoke1'
  }
  dependsOn:[
    vnetspoke1module
    sab1
  ]
}

module pdnshub 'pdns.bicep' = {
  name: 'pdnshubdeploy'
  params: {
    prefix: prefix
    vnetname: '${prefix}hub'
    autoreg: false
    fqdn: 'privatelink.blob.core.windows.net'
  }
  dependsOn:[
    vnethubmodule
  ]
}

// module pdnsspoke1 'pdns.bicep' = {
//   name: 'pdnsspoke1deploy'
//   params: {
//     postfix: 'spoke1'
//     prefix: prefix
//     autoreg: true
//     fqdn: '${prefix}.org'
//   }
//   dependsOn:[
//     pdnshub
//   ]
// }
