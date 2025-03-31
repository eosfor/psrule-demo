Import-Module PSQuickGraph

$global:vnetPrefix = '10.9.0.0/16'
$global:subnetNames = "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"
$global:subnetPrefixes = "10.9.1.0/24", "10.9.2.0/24"

# store VNET Id found in the template
$global:vnetId = $null
$global:connectionGraph = New-Graph

# Synopsis: Infrastructure should include a VNET
Rule 'local.Network.Exists' -Type 'Microsoft.Network/virtualNetworks'{
    # this aims to check if network exisists as a resource
    $TargetObject | Exists -Field name
    $TargetObject | Exists -Field id

    $global:vnetId = $TargetObject.id

    $Assert.HasFieldValue($TargetObject,'properties.addressSpace.addressPrefixes[0]', $global:vnetPrefix)
}

# Synopsis: Infrastructure should include subnets: "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"
Rule 'local.Network.Subnets.Exist' -Type 'Microsoft.Network/virtualNetworks'{
    # this aims to check if network has two subnets with matching names
    $subnetChecks = @()
    $TargetObject.resources.name | % {
        Write-Verbose "Subnet name: $_; Subnet names: $global:subnetNames; Test result: $($_ -in $global:subnetNames)"
        $subnetChecks +=  $_ -in $global:subnetNames
    }

    if ($subnetChecks  -notcontains $false){
        $Assert.Pass()
    }
    else {
        $Assert.Fail()
    }

    foreach ($subnetResource in $TargetObject.resources) {
        Add-Vertex -Graph $global:connectionGraph -Vertex $subnetResource.id
    }
}

# Synopsis: Subnets should have prefixes: "10.9.1.0/24", "10.9.2.0/24"
Rule 'local.Network.Subnets.Prefixes' -Type 'Microsoft.Network/virtualNetworks' {
    # this aims to check if network has two subnets with matching names
    $subnetChecks = @()
    $TargetObject.resources.properties.addressprefix | % {
        $subnetChecks +=  $_ -in $global:subnetPrefixes
    }

    if ($subnetChecks  -notcontains $false){
        $Assert.Pass()
    }
    else {
        $Assert.Fail()
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

# Synopsis: The infrastructure should contain a Web App with VNET integration enabled and connected to the function-integration-subnet
Rule "local.WebSite.VnetIntegration.Configured" -Type 'Microsoft.Web/sites' {
    $TargetObject | Exists -Field name

    $vnetIntegrationObject = $TargetObject.resources |
        Where-Object { $_.Type -eq 'Microsoft.Web/sites/networkConfig' }

    # $vnetIntegrationObject | ConvertTo-Json -Depth 99 | Out-File xxx.json
    $Assert.NotNull($vnetIntegrationObject, 'name')
    $Assert.EndsWith($vnetIntegrationObject, 'properties.subnetResourceId', 'function-integration-subnet')

    Add-Vertex -Graph $global:connectionGraph -Vertex $TargetObject.id
    Add-Edge -From $TargetObject.id -To $vnetIntegrationObject.properties.subnetResourceId -Graph $global:connectionGraph
}

# Synopsis: The infrastructure should contain a Web App connected to a VNET using Private endpoint
Rule "local.WebSite.PrivateEndpoint.Configured" -Type 'Microsoft.Network/privateEndpoints' {
    $TargetObject | Exists -Field name

    $subnetidCheck = $false
    $webAppCheck = $false

    foreach ($subnet in $TargetObject.Properties.subnet) {
        Write-Verbose "Edge: $($TargetObject.id) -> $($TargetObject.Properties.subnet.id)"
        Add-Edge -From $TargetObject.id -To  $subnet.id -Graph $global:connectionGraph
    }

    foreach ($link in $TargetObject.Properties.privateLinkServiceConnections) {
        Write-Verbose "Edge: $($link.properties.privateLinkServiceId) -> $($TargetObject.id)"
        Add-Edge -From $link.properties.privateLinkServiceId -To $TargetObject.id -Graph $global:connectionGraph
    }

    $Assert.Pass()

    Export-Graph -Graph $global:connectionGraph -Format MSAGL_SUGIYAMA -Path ./graph.svg
}