sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y minizinc

# Install PowerShell dependencies
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;
if ($Null -eq (Get-PackageProvider -Name NuGet -ErrorAction Ignore)) {
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser;
}
if ($Null -eq (Get-InstalledModule -Name PowerShellGet -MinimumVersion 2.2.1 -ErrorAction Ignore)) {
    Install-Module PowerShellGet -MinimumVersion 2.2.1 -Scope CurrentUser -Force -AllowClobber;
}
if ($Null -eq (Get-InstalledModule -Name InvokeBuild -MinimumVersion 5.4.0 -ErrorAction Ignore)) {
    Install-Module InvokeBuild -MinimumVersion 5.4.0 -Scope CurrentUser -Force;
}
if ($Null -eq (Get-InstalledModule -Name PSRule.Rules.Azure  -ErrorAction Ignore)) {
    Install-Module PSRule.Rules.Azure -Scope CurrentUser -Force;
}

if ($Null -eq (Get-InstalledModule -Name Az  -ErrorAction Ignore)) {
    Install-Module Az -Scope CurrentUser -Force;
}