$vnetId = $null
$subnetObj = $null
$subnetNames = "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"

# Synopsis: Infrastructure should include a VNET
Rule 'local.Network.Exists' -Type 'Microsoft.Network/virtualNetworks'{
    # this aims to check if network exisists as a resource
    $TargetObject | Exists -Field name
}

# Synopsis: Infrastructure should include subnets: "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"
Rule 'local.Network.Subnets' -Type 'Microsoft.Network/virtualNetworks'{
    # this aims to check if network has two subnets with matching names
    $subnetChecks = @()
    $TargetObject.resources.name | % {
        Write-Host "subnet is $_"
       $subnetCheck +=  $_ -in $subnetNames
    }

    if ($subnetChecks  -notcontains $false){
        $Assert.Pass()
    }
}

# Synopsis: Infrastructure should include a ServiceBus
Rule 'local.ServiceBus.Exists' -Type 'Microsoft.ServiceBus/namespaces' {
    # this aims to check if network exisists as a resource
    # $Assert.NotNull($TargetObject, "name")
    Exists -Field 'name'
}

# Synopsis: The ServiceBus should be of the Standard SKU/Tier
Rule 'local.ServiceBus.Sku' -Type 'Microsoft.ServiceBus/namespaces' {
    # this aims to check if network exisists as a resource
    $Assert.HasFieldValue($TargetObject, 'sku.name', 'Standard')
    $Assert.HasFieldValue($TargetObject, 'sku.tier', 'Standard')
}


# Synopsis: The archotecture should contain a Web App with a Vnet integration enabled
Rule "local.AppServicePlan.Exists" -Type 'Microsoft.Web/sites' {
    $TargetObject | Exists -Field name

    $vnetIntegrationObject = $TargetObject.resources |
        Where-Object { $_.Type -eq 'Microsoft.Web/sites/virtualNetworkConnections' }

    $Assert.NotNull($vnetIntegrationObject, 'name')
    $Assert.EndsWith($vnetIntegrationObject, 'properties.vnetResourceId', 'function-integration-subnet')
}

