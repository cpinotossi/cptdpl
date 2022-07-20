targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

module vnetopmodule 'vnet.bicep' = {
  name: 'vnetopdeploy'
  params: {
    prefix: prefix
    postfix: 'op'
    location: location
    cidervnet: '172.16.0.0/16'
    cidersubnet: '172.16.0.0/24'
  }
}

module vnethubmodule 'vnet.bicep' = {
  name: 'vnethubdeploy'
  params: {
    prefix: prefix
    postfix: 'hub'
    location: location
    cidervnet: '10.1.0.0/16'
    cidersubnet: '10.1.0.0/24'
    ciderbastion: '10.1.1.0/24'
    bastionExist: true
  }
}

module vnetspokemodule 'vnet.bicep' = {
  name: 'vnetspokedeploy'
  params: {
    prefix: prefix
    postfix: 'spoke'
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
    vnetspokemodule
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
    vnetspokemodule
  ]
}

module vmspokemodule 'vm.bicep' = {
  name: 'vmspokedeploy'
  params: {
    prefix: prefix
    postfix: 'spoke'
    vnetname: vnetspokemodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: '10.2.0.4'
    imageRef: 'linux'
  }
  dependsOn:[
    vnetspokemodule
  ]
}

// module pdns 'pdns.bicep' = {
//   name: 'pdnsdeploy'
//   params: {
//     postfix: 'spoke'
//     prefix: prefix
//   }
//   dependsOn:[
//     vnetspokemodule
//   ]
// }

module sab 'sab.bicep' = {
  name: 'sabdeploy'
  params: {
    vnetname: '${prefix}hub'
    prefix: prefix
    location: location
    myip: myip
    myObjectId: myobjectid
  }
}
