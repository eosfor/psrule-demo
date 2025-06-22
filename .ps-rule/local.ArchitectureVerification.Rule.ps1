Import-Module PSQuickGraph

$global:vnetPrefix = '10.9.0.0/16'
$global:subnetNames = "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"
$global:subnetPrefixes = "10.9.1.0/24", "10.9.2.0/24"

# store VNET Id found in the template
$global:vnetId = $null
$global:webSites = @()
$global:connectionGraph = New-Graph
$global:pvtEndpointGraph = New-Graph

# Synopsis: Infrastructure should include a VNET
Rule 'local.Network.Exists' -Type 'Microsoft.Network/virtualNetworks' {
    # this aims to check if network exisists as a resource
    $TargetObject | Exists -Field name
    $TargetObject | Exists -Field id

    $Assert.HasFieldValue($TargetObject, 'properties.addressSpace.addressPrefixes[0]', $global:vnetPrefix)
}

# Synopsis: Infrastructure should include subnets: "my-vnet/function-integration-subnet", "my-vnet/private-endpoint-subnet"
Rule 'local.Network.Subnets.Exist' -Type 'Microsoft.Network/virtualNetworks' {
    # this aims to check if network has two subnets with matching names
    $subnetChecks = @()
    $TargetObject.resources.name | % {
        Write-Verbose "Subnet name: $_; Subnet names: $global:subnetNames; Test result: $($_ -in $global:subnetNames)"
        $subnetChecks += $_ -in $global:subnetNames
    }

    if ($subnetChecks -notcontains $false) {
        $Assert.Pass()
    }
    else {
        $Assert.Fail()
    }
}

# Synopsis: Subnets should have prefixes: "10.9.1.0/24", "10.9.2.0/24"
Rule 'local.Network.Subnets.Prefixes' -Type 'Microsoft.Network/virtualNetworks' {
    # this aims to check if network has two subnets with matching names
    $subnetChecks = @()
    $TargetObject.resources.properties.addressprefix | % {
        $subnetChecks += $_ -in $global:subnetPrefixes
    }

    if ($subnetChecks -notcontains $false) {
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
    $TargetObject | Exists -Field 'name'
}

# Synopsis: The ServiceBus should be of the Standard SKU/Tier
Rule 'local.ServiceBus.Sku' -Type 'Microsoft.ServiceBus/namespaces' {
    # this aims to check if network exisists as a resource
    $TargetObject | Match 'sku.name' 'Standard'
    $TargetObject | Match 'sku.tier' 'Standard'

    # $Assert.HasFieldValue($TargetObject, 'sku.name', 'Standard')
    # $Assert.HasFieldValue($TargetObject, 'sku.tier', 'Standard')
}

# Synopsis: Web Apps should have Public network access disabled
Rule "local.WebSite.PublicAccess.Disabled" -Type 'Microsoft.Web/sites' {
    $TargetObject | Match 'properties.publicNetworkAccess' 'Disabled'
}

# Synopsis: Web Apps should have VNET integration tuned on
Rule "local.WebSite.VnetIntegration.Configured" -Type 'Microsoft.Web/sites' {
    $TargetObject | Exists -Field name

    $vnetIntegrationObject = $TargetObject.resources |
    Where-Object { $_.Type -eq 'Microsoft.Web/sites/networkConfig' }

    # $vnetIntegrationObject | ConvertTo-Json -Depth 99 | Out-File xxx.json
    $Assert.NotNull($vnetIntegrationObject, 'name')
    $Assert.EndsWith($vnetIntegrationObject, 'properties.subnetResourceId', 'function-integration-subnet')
}

# Synopsis: All functions have to have a
Export-PSRuleConvention 'FullConnectivityTest' `
    -Process {
        Write-Verbose "Convention process block triggered"
        if ($TargetObject.type -eq 'Microsoft.Network/virtualNetworks') {
            Write-Verbose "Convention triggered for a VNET $($TargetObject.name)"

            $global:vnetId = $TargetObject.id

        foreach ($subnetResource in $TargetObject.resources) {
            # VNET -> Subnet
            Add-Edge -From $TargetObject.id -To $subnetResource.id -Graph $global:connectionGraph
            Add-Edge -From $TargetObject.id -To $subnetResource.id -Graph $global:pvtEndpointGraph
        }
        }

        if ($TargetObject.type -eq 'Microsoft.Web/sites') {
            $vnetIntegrationObject = $TargetObject.resources |
            Where-Object { $_.Type -eq 'Microsoft.Web/sites/networkConfig' }

            $global:webSites += $TargetObject.id

            Add-Vertex -Graph $global:connectionGraph -Vertex $TargetObject.id
            Add-Vertex -Graph $global:pvtEndpointGraph -Vertex $TargetObject.id

            #Add-Edge -From $TargetObject.id -To $vnetIntegrationObject.properties.subnetResourceId -Graph $global:connectionGraph
            Add-Edge -From $vnetIntegrationObject.properties.subnetResourceId -To $TargetObject.id -Graph $global:connectionGraph
        }

        if ($TargetObject.type -eq 'Microsoft.Network/privateEndpoints') {
            foreach ($subnet in $TargetObject.Properties.subnet) {
                Write-Verbose "Edge: $($TargetObject.id) -> $($TargetObject.Properties.subnet.id)"
                Add-Edge -From $TargetObject.id -To  $subnet.id -Graph $global:pvtEndpointGraph
            }

            foreach ($link in $TargetObject.Properties.privateLinkServiceConnections) {
                Write-Verbose "Edge: $($link.properties.privateLinkServiceId) -> $($TargetObject.id)"
                Add-Edge -From $link.properties.privateLinkServiceId -To $TargetObject.id -Graph $global:pvtEndpointGraph
            }

        }
    }`
    -End {
        Write-Verbose "Exporting graph"
        Export-Graph -Graph $global:connectionGraph -Format Vega_ForceDirected -Path ./output/graph.html
        Export-Graph -Graph $global:pvtEndpointGraph -Format Vega_ForceDirected -Path ./output/pvtEndpointGraph.html

        Export-Graph -Graph $global:connectionGraph -Format Vega_TreeLayout -Path ./output/graph.tree.html
        Export-Graph -Graph $global:pvtEndpointGraph -Format Vega_TreeLayout -Path ./output/pvtEndpointGraph.tree.html

        # There should be only one VNET
        if ($global:vnetId.Count -ne 1) {
            Throw "There should be exactly 1 VNET"
        }

        # All web apps should end up in the VNET via VNET Integration Path
        foreach($webApp in $global:webSites){
            $p = Get-GraphPath -From $webApp -To $global:vnetId -Graph $global:connectionGraph
            if ($null -eq $p) {
                Throw "There should be a path from a Function App to the VNET"
            }
        }

        # All web apps should have only one Private Endpoint Connection
        foreach($webApp in $global:webSites){
            $vertex = $global:pvtEndpointGraph.Vertices | ? { $_ -eq $webApp }
            $outEdges = $global:pvtEndpointGraph.OutEdges($vertex)
            if ($outEdges.Count -ne 1) {
                Throw "There should be exactly one Private Endpoint attached to a Web Site: $vertex"
            }
        }

        # All web apps should only have Private Endpoints in the specific VNET
        foreach($webApp in $global:webSites){
            $p = Get-GraphPath -From $webApp -To $global:vnetId -Graph $global:pvtEndpointGraph
            if ($null -eq $p) {
                Throw "There should be a path from a Function App to the VNET"
            }
        }
    }