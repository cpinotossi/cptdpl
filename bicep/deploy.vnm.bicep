targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
param prefix string
param hubname string
param vnetnames array

module nwm 'nwm.bicep' = {
  name: 'nwmdeploy'
  params: {
    location: location
    prefix: prefix
    subid: subscription().subscriptionId
    hubname: hubname
    vnetnames: vnetnames
  }
}

output subid string = subscription().subscriptionId
