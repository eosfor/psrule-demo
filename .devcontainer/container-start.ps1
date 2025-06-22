# Update modules
# Update-Module PSRule.Rules.Azure -Scope CurrentUser -Force;

# Определить ОС
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
    $os = "osx"
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
    $os = "linux"
} else {
    throw "Unsupported OS"
}

# Определить архитектуру
$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

switch ($arch) {
    "X64"   { $platform = "$os-x64" }
    "Arm64" { $platform = "$os-arm64" }
    default { throw "Unsupported architecture: $arch" }
}

# Скачать нужный бинарник
$version = "latest"
$bicepUrl = "https://github.com/Azure/bicep/releases/$version/download/bicep-$platform"
$destination = "$PWD/bicep"

Invoke-WebRequest -Uri $bicepUrl -OutFile $destination
chmod +x $destination
sudo mv $destination /usr/local/bin/bicep

bicep --version