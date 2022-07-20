# Azure Private Link Demos

## Setup Private Link with Storage Account

~~~ mermaid
classDiagram
plDNS --> spoke : link/resolve
plDNS: privatelink.core.windows.net
hub --> spoke : peering
hub --> onprem : peering
hub : bastion
hub : cidr 10.1.0.0/16
onprem : cidr 172.16.0.0/16
spoke : cidr 10.2.0.0/16
hub : vm 10.1.0.4
spoke : vm 10.2.0.4
spoke : pe 10.2.0.5
onprem : vm 172.16.0.4
~~~

Define variables:

~~~ bash
prefix=cptdpl
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing some RBAC roles to ourself.
~~~

Create foundation:

~~~ bash
az group delete -n $prefix -y
az group create -n $prefix -l $location
az deployment group create -n $prefix -g $prefix --mode incremental --template-file bicep/deploy.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
~~~

Create Hub-Spoke peering with Azure Network Manager:

~~~ bash
vnetnames=$(az network vnet list -g $prefix --query [].name)
az deployment group create -n $prefix -g $prefix --template-file bicep/deploy.vnm.bicep -p prefix=$prefix location=$location hubname=${prefix}hub vnetnames='("cptdplhub","cptdplspoke","cptdplop")' # todo how to provide this via variable
nwmconid=$(az network manager connect-config show --configuration-name $prefix -n $prefix -g $prefix --query id -o tsv) 
az network manager  post-commit --help-n $prefix --commit-type "Connectivity" --target-locations $location -g $prefix --configuration-ids $nwmconid # not working done via the portal for now.
~~~

Create private link and private dns

~~~ bash
az deployment group create -n $prefix -g $prefix --template-file bicep/pl.bicep -p prefix=$prefix location=$location vnetname=${prefix}spoke
az network private-dns zone list -g $prefix --query [].name # list all private dns zones
plz="privatelink.blob.core.windows.net."
az network private-dns record-set list -g $prefix -z $plz --query '[?type==`Microsoft.Network/privateDnsZones/A`].{aRecords:aRecords,fqdn:fqdn}' # list a records
~~~

Test DNS resolution:

~~~ bash
vmspokeid=$(az vm show -g $prefix -n ${prefix}spoke  --query id -o tsv) # linked to pdns
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmspokeid --auth-type password --username chpinoto
demo!pass123
dig cptdpl.privatelink.blob.core.windows.net. # expect  10.2.0.5
logout
vmhubid=$(az vm show -g $prefix -n ${prefix}hub  --query id -o tsv) # not linked to pdns
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmhubid --auth-type password --username chpinoto
demo!pass123
dig cptdpl.privatelink.blob.core.windows.net. # expect CNAME blob.blz21prdstr15a.store.core.windows.net.
~~~

Upload conent via public endpoint:

~~~ bash
az storage blob upload --data 'hello world' -c $prefix -n $prefix --account-name $prefix --auth-mode login
az storage blob list --auth-mode login --account-name $prefix --container-name $prefix
~~~

CONCLUSION:
Private link does provide access to Azure Storage Account services via a private IP but it does not restrict access via the public endpoint.

~~~ bash
az group delete -n $prefix -y
~~~

## Misc

### git

~~~ bash
gh repo create $prefix --public
git init
git remote add origin https://github.com/cpinotossi/$prefix.git
git status
git add *
git commit -m"private link with storage account"
git push origin main 
~~~