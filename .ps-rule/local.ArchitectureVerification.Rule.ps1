Rule 'local.Architecture.Verification' -Type 'Microsoft.Network/virtualNetworks' {
    # this aims to check if network exisists as a resource
    $Assert.HasFieldValue($TargetObject, 'name', 'vnetDeployment')
}