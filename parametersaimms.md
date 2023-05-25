@whaakman , as discussed yesterday in our meeting, I would sent you a list of questions as you have certain processes in place for aimms. Could you please help me answer these questions, or refer me to the person at Intercept that could answer this, or let me know if I should post the question to Vincent at aimms. Here are my current questions:

Questions adb bicep template Aimms

- [ ] Will we create new RG or use an existing RG? **- Create a new RG (rg-dbw-aimms-dev)**
- [ ] Is this the right **subscription ID** b6b9252d-06ac-4ea3-8c02-f52b5c7dc792 ? **- that is the tenant ID, subscription ID is 70c4df47-a533-4c74-9dc8-0537425cc325**
- [ ] What **name of RG** to use? **- rg-dbw-aimms-dev**
- [ ] What **location/region** to use to deploy adb / create RG? I am assuming WE? **- west Europe**
- [ ] Can you specify whether to deploy Azure Databricks workspace with **secure cluster connectivity (SCC)** enabled or not (No Public IP) ( Do we need public IP?) **- I would go for secure cluster (SCC)**
- [ ] Do we deploy Azure Databricks workspace in aimms own **Virtual Network (VNet)** i.e does it exist or not? **- yes, you will need to create one (vnet-dbw-aimms-dev)**
- [ ] What **pricing tier** to use for the adb workspace dev environment? options are "trial", "standard", "premium", the premium option has role bases access control FYI. **- this is up to you and the customer as you are the expert here.**
- [ ] What name to use for the **workspace** of ADB? **- dbw-aimms-dev**
- [ ] **Nsg Name** What name to use for the network Security Group? and do we need to create one are use an existing and which one if so? **- A new one will need to be created. naming nsg-dbw-aimms-dev**
- [ ] **Vnet Name** What name to use of the Virtual Network and do we need to create one are use an existing and which one if so? **- yes, you will need to create one (vnet-dbw-aimms-dev)**
- [ ] **Private Subnet Name** What name of the Private Subnet to use? and do we need to create one are use an existing and which one if so? **- yes, you will need to create one (sn-dbw-aimms-dev)**
- [ ] **Public Subnet Name** What name of the Public Subnet to use? and do we need to create one are use an existing and which one if so? - **do you need one if it is SCC? if you do use the name above but add -pub after sn-**
- [ ] **PrivateEndpointSubnetName** What name of the subnet to create the private endpoint in, and do we want to create the private endpoints already ? **- yes, you will need to create one (pl-dbw-aimms-dev)**
- [ ] **NSG Rules for workers** example:
  },
  "variables": {
    "managedResourceGroupName": "[format('databricks-rg-{0}-{1}', parameters('workspaceName'), uniqueString(parameters('workspaceName'), resourceGroup().id))]",
    "trimmedMRGName": "[substring(variables('managedResourceGroupName'), 0, min(length(variables('managedResourceGroupName')), 90))]",
    "managedResourceGroupId": "[concat(subscription().id, '/resourceGroups/', variables('trimmedMRGName'))]",
    "privateEndpointName": "[concat(parameters('workspaceName'), '-', 'pvtEndpoint')]",
    "privateDnsZoneName": "privatelink.azuredatabricks.net",
    "pvtEndpointDnsGroupName": "[concat(variables('privateEndpointName'),'/mydnsgroupname')]"
  },
  "functions": [],
  "resources": [
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2021-03-01",
      "name": "[parameters('nsgName')]",
      "location": "[parameters('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound",
            "properties": {
              "description": "Required for worker nodes communication within a cluster.",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "*",
              "sourceAddressPrefix": "VirtualNetwork",
              "destinationAddressPrefix": "VirtualNetwork",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
- [ ] Do we want to deploy ADB with load balancer? Then I need the following names of the parameters **Load Balancer Backend Pool Name** Name of the Backend Pool of the Load Balancer
**Load Balancer Frontend Config Name** Name of the Frontend Load Balancer configuration
**Load Balancer Name** Name of the Load Balancer
**Load Balancer Public IP Name** Name of the outbound Load Balancer Public IP
**- This  is up to you as the SME here**
- [ ] **Location** What location of the Data Center to use? **-west europe**
- [ ] **Vnet Cidr** Which Cidr Range of the Vnet to use? **- 172.16.20.x/x Not sure cidr space need as you are SME you should know this requirement.**
- [ ] **Private Subnet Cidr** which Cidr Range of the Private Subnet to use? **- This  is up to you as the SME here**
- [ ] **Public Subnet Cidr** which Cidr Range of the Public Subnet to use? **- This  is up to you as the SME here**
- [ ] By default, data stored on managed disks is encrypted at rest using server-side encryption with Microsoft-managed keys, however does aimms want to use their own **managed disk keys**? **- system managed keys are ok here.**
- [ ] Managed services data in the Azure Databricks control plane is encrypted at rest. After you add a customer-managed key encryption for a workspace, Azure Databricks uses your key to control access to the key that encrypts future write operations to your workspace’s managed services data. does aimms want to use their own **managed service key**, or ?    **- system managed keys are ok here.**
- [ ] In addition to the choice of the default encryption or your own managed key encryption, Azure Databricks DBFS root can also be encrypted with a second layer of encryption called **infrastructure encryption** using platform-managed key to achieve Double Encryption for DBFS root. Does aimss wat to enable infrastructre encrypted? This can not be changed afterw workspace creation. **- no**
- [ ] What **tags** to use for the azure databricks service? **- Environment:Dev**
- [ ] To  manage permissions in a fully automated setup I need to use Databricks Terraform provider and databricks_permissions for access control for **workspace**, **cluster**, **pool**, **jobs**, **table**, **token-based authentication**. Somebody has an idea how to integrate that? **- I believe only you and lisa have done databricks in the company**
- [ ] How far do we go with setting up ADB as in, is it just to deploy the workspace and aimms will add the cluster etc, or do we also set up the cluster, and arrange the access control to the cluster and the permissions as mentioned above etc? Also, do we create a storage account or do they create their own connections for storage etc? **- we set it all up for them**


##test parameters myself on Kaijisse Tenant and usbscription
## opted for enabling public access for dev as otherwise both workspace acces as databricks data plane access are not possible unless there is a VM in the VNET or going through VPN to access that workspace of ADB (that is somethingn to think about for production though)

it still deploying in 2 seperate Resource Groups ( so need to do it 1)
and we fix the private endpoint
and we fix the Virtual network 
