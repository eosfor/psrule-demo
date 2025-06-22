sudo apt-get update -y
sudo apt-get upgrade -y

Install-Module InvokeBuild -Scope CurrentUser -Force
Install-Module PSRule.Rules.Azure -Scope CurrentUser -Force
Install-Module Az -Scope CurrentUser -Force
Install-Module PSQuickGraph -Scope CurrentUser -Force