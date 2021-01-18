param location string = resourceGroup().location
param dnsPrefix string = 'aks'
param clusterName string = '${uniqueString(resourceGroup().id)}'
param agentCount int {
  default: 1
  minValue: 1
  maxValue: 50
}
param agentVMSize string = 'Standard_D2_v3'

var identityName = 'scratch'
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // ACRpull
var roleAssignmentName = guid(identityName, roleDefinitionId)
var kubernetesVersion = '1.19.6'
var virtualNetworkName = 'vnet-01'
var addressPrefix = '20.0.0.0/16'
var subnetName = 'subnet-01'
var subnetPrefix = '20.0.0.0/23'
var nodeResourceGroup = '${resourceGroup().name}-managed'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  scope: containerRegistry
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: '${clusterName}acr'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}
resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}
resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool01'
        count: agentCount
        mode: 'System'
        vmSize: agentVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        vnetSubnetID: '${vn.id}/subnets/${subnetName}'
      }
    ]
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}
output resourceGroupOutput string = resourceGroup().name
output registryNameOutput string = containerRegistry.name
output aksName string = aks.name
