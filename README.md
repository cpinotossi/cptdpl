# Azure Private Link Demos

## Setup Private Link with 1 Storage Account and 2 Service Endpoints in different Regions

~~~ mermaid
classDiagram

vnet1 <-- pe1 : inject
vnet2 <-- pe2 : inject
pe1 --> storage1 : private link
pe2 --> storage1 : private link
pDNS --> vnet1 : link/resolve
pDNS --> vnet2 : link/resolve
~~~

~~~ bash
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata
sudo chmod 600 ls -la azbicep/ssh/chpinoto.key
prefix=cptdpl
location1=westeurope
location2=northeurope
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing some RBAC roles to ourself.
~~~

### Create foundation:

~~~ bash
az group delete -n $prefix --yes
az group create -n $prefix -l $location1
az deployment group create -n $prefix -g $prefix --mode incremental --template-file deploy1.bicep -p prefix=$prefix myobjectid=$myobjectid location1=$location1 location2=$location2 myip=$myip
~~~

### Create Storage and Private Links (NOT WORKING)

~~~ bash
az deployment group create -n $prefix -g $prefix --mode incremental --template-file deploy1pl.bicep -p prefix=$prefix myobjectid=$myobjectid location1=$location1 location2=$location2
# Upload content
az storage blob upload --data 'hello world' -c $prefix -n $prefix --account-name $prefix --auth-mode login
az storage blob list --auth-mode login --account-name $prefix --container-name $prefix
~~~

### Test

#### Resolve Blob Storage domain from vm1:

~~~ bash
vm1id=$(az vm show -g $prefix -n ${prefix}vm1 --query id -o tsv)
az network bastion ssh -n ${prefix}vnet1 -g $prefix --target-resource-id $vm1id --auth-type ssh-key --username chpinoto --ssh-key azbicep/ssh/chpinoto.key
demo!pass123
dig cptdpl.blob.core.windows.net
curl -v https://cptdpl.blob.core.windows.net/cptdpl/cptdpl
logout
~~~

#### Resolve Blob Storage domain from vm2:

~~~ bash
vm2id=$(az vm show -g $prefix -n ${prefix}vm2 --query id -o tsv)
az network bastion ssh -n ${prefix}vnet2 -g $prefix --target-resource-id $vm2id --auth-type ssh-key --username chpinoto --ssh-key azbicep/ssh/chpinoto.key
demo!pass123
dig cptdpl.blob.core.windows.net
curl -v https://cptdpl.blob.core.windows.net/cptdpl/cptdpl
logout
sudo chmod 655 azbicep/ssh/chpinoto.key
~~~

#### Failover Storage

~~~ bash
az storage account show -n $prefix --expand geoReplicationStats --query "{failoverInProgress: failoverInProgress,geoReplicationStats:geoReplicationStats,lastGeoFailoverTime:lastGeoFailoverTime,location:location, statusOfPrimary:statusOfPrimary,statusOfSecondary:statusOfSecondary}"
~~~

Output:
~~~json
{
  "failoverInProgress": null,
  "geoReplicationStats": {
    "canFailover": true,
    "lastSyncTime": "2022-09-27T07:50:46+00:00",
    "status": "Live"
  },
  "lastGeoFailoverTime": null,
  "location": "westeurope",
  "statusOfPrimary": "available",
  "statusOfSecondary": "available"
}
~~~

~~~ bash
az storage account failover --name $prefix
~~~

~~~ bash
az network bastion ssh -n ${prefix}vnet1 -g $prefix --target-resource-id $vm1id --auth-type ssh-key --username chpinoto --ssh-key azbicep/ssh/chpinoto.key
demo!pass123
dig cptdpl.blob.core.windows.net
curl -v https://cptdpl.blob.core.windows.net/cptdpl/cptdpl # expect 200 OK
logout
~~~


Before storage failover WEU (AMS):
~~~ bash
;; ANSWER SECTION:
cptdpl.blob.core.windows.net. 0 IN      CNAME   cptdpl.privatelink.blob.core.windows.net.
cptdpl.privatelink.blob.core.windows.net. 0 IN CNAME blob.ams23prdstr06a.store.core.windows.net.
blob.ams23prdstr06a.store.core.windows.net. 0 IN A 20.150.76.228
~~~


After storage failover NEU (DUB)
~~~ bash
;; ANSWER SECTION:
cptdpl.blob.core.windows.net. 0 IN      CNAME   cptdpl.privatelink.blob.core.windows.net.
cptdpl.privatelink.blob.core.windows.net. 0 IN CNAME blob.dub21prdstr11b.store.core.windows.net.
blob.dub21prdstr11b.store.core.windows.net. 0 IN A 20.150.84.115
~~~


Inside the vnet before and after we do get the same result:
~~~ bash
;; ANSWER SECTION:
cptdpl.blob.core.windows.net. 60 IN     CNAME   cptdpl.privatelink.blob.core.windows.net.
cptdpl.privatelink.blob.core.windows.net. 9 IN A 192.168.5.5
~~~


## Setup Private Link with 2 Storage Account

~~~ mermaid
classDiagram

hub --> spoke1 : peering
hub --> onprem : peering
spoke1 <-- pe1 : inject
spoke1 <-- pe2 : inject 
pe1 --> plDNS
pe1 --> storage1 : private link
pe1: cptdpl1.blob.core.windows.net
pe2 --> storage2 : private link
pe2: cptdpl2.blob.core.windows.net
plDNS --> hub : link/resolve
plDNS --> spoke1 : link/resolve
plDNS: privatelink.blob.core.windows.net
hub : bastion
hub : cidr 10.1.0.0/16
hub : vm 10.1.0.4
onprem : cidr 172.16.0.0/16
onprem : vm 172.16.0.4
spoke1 : cidr 10.2.0.0/16
spoke1 : vm 10.2.0.4
spoke1 : pe1 10.2.0.5
spoke1 : pe2 10.2.0.6
storage1 : cptdpl1.blob.core.windows.net
storage2 : cptdp12.blob.core.windows.net
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
az group create -n $prefix -l $location
az deployment group create -n $prefix -g $prefix --mode incremental --template-file bicep/deploy.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
~~~

Create Hub-Spoke peering with Azure Network Manager:

~~~ bash
vnetnames=$(az network vnet list -g $prefix --query [].name | tr -d '\n' | tr -d ' ')
az deployment group create -n $prefix -g $prefix --template-file bicep/deploy.vnm.bicep -p prefix=$prefix location=$location hubname=${prefix}hub vnetnames=$vnetnames
nwmconid=$(az network manager connect-config show --configuration-name $prefix -n $prefix -g $prefix --query id -o tsv) 
# Commit needs to be done via REST API for now, the cli is not working yet.
nwmbody="{\"targetLocations\": [\"$location\"],\"configurationIds\": [\"$nwmconid\"],\"commitType\": \"Connectivity\"}"
subid=$(az account show --query id -o tsv)
az rest --method post -u https://management.azure.com/subscriptions/$subid/resourceGroups/$prefix/providers/Microsoft.Network/networkManagers/$prefix/commit --url-parameters api-version=2021-02-01-preview -b "$nwmbody"
~~~

List all devices of spoke vnet/subnet:

~~~ bash
az network vnet subnet show -g $prefix --vnet-name ${prefix}spoke1 -n $prefix --query ipConfigurations[].id -o tsv # expect 3 entries
~~~

List all vnet linked to the private dns zone:

~~~ bash
az network private-dns link vnet list -g $prefix -z $plz --query [].id # expect 2 links
~~~

List private link private dns entries:

~~~ bash
az network private-dns record-set list -g $prefix -z $plz --query '[?type==`Microsoft.Network/privateDnsZones/A`].{aRecords:aRecords[0].ipv4Address,fqdn:fqdn}' -o table # expect 1 a records
~~~

Result:

~~~ text
ARecords    Fqdn
----------  ------------------------------------------
10.2.0.5    cptdpl1.privatelink.blob.core.windows.net.
~~~


Test DNS resolution from inside spoke1 vnet:

~~~ bash
vmspokeid=$(az vm show -g $prefix -n ${prefix}spoke1  --query id -o tsv) # linked to pdns
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmspokeid --auth-type password --username chpinoto
demo!pass123
dig +noall +answer cptdpl1.blob.core.windows.net. # expect 10.2.0.6 or 10.2.0.5
dig +noall +answer cptdpl1.privatelink.blob.core.windows.net. # expect 10.2.0.6 or 10.2.0.5
logout
~~~

Test DNS resolution from inside hub vnet:

~~~ bash
vmhubid=$(az vm show -g $prefix -n ${prefix}hub  --query id -o tsv) # not linked to pdns
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmhubid --auth-type password --username chpinoto
demo!pass123
dig +noall +answer cptdpl1.privatelink.blob.core.windows.net. # expect 10.2.0.6 or 10.2.0.5
logout
~~~

### Privat link and public endpoint

Turning on private link on storage account does not restrict access via public endpoint.
Upload content via public endpoint:

~~~ bash
az storage blob upload --data 'hello world' -c $prefix -n $prefix --account-name ${prefix}1 --auth-mode login
az storage blob list --auth-mode login --account-name ${prefix}1 --container-name $prefix
~~~

### Private link and NX response

> Private networks already using the private DNS zone for a given type, can only connect to public resources if they don't have any private endpoint connections, otherwise a corresponding DNS configuration is required on the private DNS zone in order to complete the DNS resolution sequence.
> (source: https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns)

To confirm this we are going to send a DNS query for the second storage account:

~~~ bash
vmspokeid=$(az vm show -g $prefix -n ${prefix}spoke1  --query id -o tsv) # linked to pdns
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmspokeid --auth-type password --username chpinoto
demo!pass123
dig cptdpl2.blob.core.windows.net. # expect NXDOMAIN response
logout
~~~

To overcome this have a look at the following solution::
- https://github.com/cthoenes/azure-coredns-forwarder-sample

CONCLUSION:
- Private link does provide access to Azure Storage Account services via a private IP but it does not restrict access via the public endpoint.
- Private link does result into DNS NXDOMAIN response under certain cases.

Clean up:

~~~ bash
az group delete -n $prefix -y
~~~

## Private Link and Server Certificates

~~~bash
dig cptdazampls1.blob.core.windows.net
~~~

;; ANSWER SECTION:
cptdazampls1.blob.core.windows.net. 60 IN CNAME cptdazampls1.privatelink.blob.core.windows.net.
cptdazampls1.privatelink.blob.core.windows.net. 60 IN CNAME blob.fra24prdstr02a.store.core.windows.net.
blob.fra24prdstr02a.store.core.windows.net. 1146 IN A 20.209.32.1

~~~bash
# use openssl to get the certificate
echo quit | openssl s_client -connect cptdazampls1.blob.core.windows.net:443 -showcerts 2>/dev/null | openssl x509 -inform pem -noout -text
~~~

X509v3 Subject Alternative Name:
DNS:*.blob.core.windows.net, DNS:*.fra24prdstr02a.store.core.windows.net, DNS:*.blob.storage.azure.net, DNS:*.z1.blob.storage.azure.net, DNS:*.z2.blob.storage.azure.net, DNS:*.z3.blob.storage.azure.net, DNS:*.z4.blob.storage.azure.net, DNS:*.z5.blob.storage.azure.net, DNS:*.z6.blob.storage.azure.net, DNS:*.z7.blob.storage.azure.net, DNS:*.z8.blob.storage.azure.net, DNS:*.z9.blob.storage.azure.net, DNS:*.z10.blob.storage.azure.net, DNS:*.z11.blob.storage.azure.net, DNS:*.z12.blob.storage.azure.net, DNS:*.z13.blob.storage.azure.net, DNS:*.z14.blob.storage.azure.net, DNS:*.z15.blob.storage.azure.net, DNS:*.z16.blob.storage.azure.net, DNS:*.z17.blob.storage.azure.net, DNS:*.z18.blob.storage.azure.net, DNS:*.z19.blob.storage.azure.net, DNS:*.z20.blob.storage.azure.net, DNS:*.z21.blob.storage.azure.net, DNS:*.z22.blob.storage.azure.net, DNS:*.z23.blob.storage.azure.net, DNS:*.z24.blob.storage.azure.net, DNS:*.z25.blob.storage.azure.net, DNS:*.z26.blob.storage.azure.net, DNS:*.z27.blob.storage.azure.net, DNS:*.z28.blob.storage.azure.net, DNS:*.z29.blob.storage.azure.net, DNS:*.z30.blob.storage.azure.net, DNS:*.z31.blob.storage.azure.net, DNS:*.z32.blob.storage.azure.net, DNS:*.z33.blob.storage.azure.net, DNS:*.z34.blob.storage.azure.net, DNS:*.z35.blob.storage.azure.net, DNS:*.z36.blob.storage.azure.net, DNS:*.z37.blob.storage.azure.net, DNS:*.z38.blob.storage.azure.net, DNS:*.z39.blob.storage.azure.net, DNS:*.z40.blob.storage.azure.net, DNS:*.z41.blob.storage.azure.net, DNS:*.z42.blob.storage.azure.net, DNS:*.z43.blob.storage.azure.net, DNS:*.z44.blob.storage.azure.net, DNS:*.z45.blob.storage.azure.net, DNS:*.z46.blob.storage.azure.net, DNS:*.z47.blob.storage.azure.net, DNS:*.z48.blob.storage.azure.net, DNS:*.z49.blob.storage.azure.net, DNS:*.z50.blob.storage.azure.net

Would it work with cptdazampls1.blob.storage.azure.net?

~~~bash
dig cptdazampls1.blob.storage.azure.net # NXDOMAIN
nslookup cptdazampls1.blob.storage.azure.net
~~~



## Misc

### azure network manager

~~~ bash
az network manager post-commit --debug -n $prefix --commit-type "Connectivity" --target-locations $location -g $prefix --configuration-ids $nwmconid
~~~

### azure private links

~~~ bash
az network private-dns zone list -g $prefix --query [].name # list all private dns zones
plz="privatelink.blob.core.windows.net."
~~~
### git

~~~ bash
gh repo create $prefix --public
git init
git remote add origin https://github.com/cpinotossi/$prefix.git
git status
git add *
git commit -m"NXDOMAIN case"
git push origin main 

git remote add origin https://github.com/cpinotossi/$prefix.git
git submodule add https://github.com/cpinotossi/azbicep
git submodule init
git submodule update
git submodule update --init

# Update from remote
git fetch origin
git merge origin/main
~~~