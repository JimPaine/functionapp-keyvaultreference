# Grab source for demo app
git clone https://github.com/JimPaine/functionapp-keyvaultreference.git
cd functionapp-keyvaultreference

tag=$RANDOM
groupname=akvbug$tag
location=westeurope

az group create --name $groupname --location $location

# Create AKV and set access policy for current user
vault=$(az keyvault create --name vault$tag --resource-group $groupname | jq '.name' | sed "s/\"//g")
az keyvault set-policy --name $vault --object-id $(az ad signed-in-user show -o=json | jq '.objectId' | sed "s/\"//g") --secret-permissions get list set delete

# Add secret
secret=$(az keyvault secret set --name bug --vault-name $vault --value 'hello world')

###### LINUX ######

linuxgroupname=akvbuglinux$tag
az group create --name $linuxgroupname --location $location

# Create storage account for function
storageaccount=$(az storage account create --name linstore$tag --resource-group $linuxgroupname --sku Standard_LRS | jq '.id' | sed "s/\"//g")

# Create Linux function with MSI
linuxfunc=$(az functionapp create --name linfunc$tag --resource-group $linuxgroupname --os-type Linux --runtime dotnet --storage-account $storageaccount --consumption-plan-location $location)
linuxfuncname=$(echo $linuxfunc | jq '.name' | sed "s/\"//g")
linuxfuncmsi=$(az functionapp identity assign --name $linuxfuncname --resource-group $linuxgroupname)

# Create access policy for Linux MSI
az keyvault set-policy --name $vault --object-id $(echo $linuxfuncmsi | jq '.principalId' | sed "s/\"//g") --secret-permissions get list

# Update the Linux Func app settings with a pointer to the secret in AKV
az functionapp config appsettings set --name $linuxfuncname --resource-group $linuxgroupname --settings "bug=@Microsoft.KeyVault(SecretUri=$(echo $secret | jq '.id' | sed "s/\"//g"))"
az functionapp config appsettings set --name $linuxfuncname --resource-group $linuxgroupname --settings "secretUri=$(echo $secret | jq '.id' | sed "s/\"//g")"

# Deploy function
linuxoutput=$(func azure functionapp publish $linuxfuncname --dotnet-cli-params -- '-r linux-x64')

###### WINDOWS ######

windowsgroupname=akvbugwin$tag
az group create --name $windowsgroupname --location $location

# Create storage account for function
storageaccount=$(az storage account create --name winstore$tag --resource-group $windowsgroupname --sku Standard_LRS | jq '.id' | sed "s/\"//g")

# Create Windows function with MSI and set to 64bit
winfunc=$(az functionapp create --name winfunc$tag --resource-group $windowsgroupname --os-type Windows --runtime dotnet --storage-account $storageaccount --consumption-plan-location $location)
winfuncname=$(echo $winfunc | jq '.name' | sed "s/\"//g")
winfunccmsi=$(az functionapp identity assign --name $winfuncname --resource-group $windowsgroupname)
az functionapp config set --name $winfuncname --use-32bit-worker-process false --resource-group $windowsgroupname

# Create access policy for Windows MSI
az keyvault set-policy --name $vault --object-id $(echo $winfunccmsi | jq '.principalId' | sed "s/\"//g") --secret-permissions get list

# Update the Windows Func app settings with a pointer to the secret in AKV
az functionapp config appsettings set --name $winfuncname --resource-group $windowsgroupname --settings "bug=@Microsoft.KeyVault(SecretUri=$(echo $secret | jq '.id' | sed "s/\"//g"))"
az functionapp config appsettings set --name $winfuncname --resource-group $windowsgroupname --settings "secretUri=$(echo $secret | jq '.id' | sed "s/\"//g")"

# Deploy function
windowsoutput=$(func azure functionapp publish $winfuncname --dotnet-cli-params -- '-r win-x64')

# Func App details
echo "Function Should output 'Hello World'"
echo "Windows Function:"
curl $(echo $windowsoutput | grep 'Invoke url:' | sed "s/Invoke url: //g") 
echo "Linux Function:"
curl $(echo $linuxoutput | grep 'Invoke url:' | sed "s/Invoke url: //g") 
