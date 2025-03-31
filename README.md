# PSRule DEMO

> After some research and [troubleshooting](https://github.com/Azure/PSRule.Rules.Azure/issues/3298), thanks to @BernieWhite, I managed to make it work. The work is in progress still.

This repository demonstrates a practical scenario where an Architect defines an Azure solution—typically as a high-level diagram (e.g., in Visio)—and an Engineer implements the infrastructure using Bicep templates.

The purpose of this repo is to provide a framework for validating whether the implemented infrastructure matches the original architectural design. It focuses on verifying the presence of required Azure resources, their proper configuration, and correct network integration—such as ensuring services are deployed into the right virtual networks and subnets, with appropriate private endpoints and connections.

This validation is performed using PSRule for Azure, enabling automated checks and alignment between design and deployment.

Addtionally it uses `draw.io` as part of the archotectue documentation, making the repo a single source for everything - architecture documentation, code, and infrastructure verification tests.

## Scenario

In this scenario we have a few people plaing different roles. First - is an `Architect`. He is responcible for putting otgether an architecture, based on various business, security and technical requiremens of an Organization. He produces everything in the [document](./docs/architecture/README.md) folder. it containd a diagran and a design document. After it is produced, we engage an `Engineer`, who's task is to implement the design using tools like [Bicep](https://github.com/Azure/bicep/tree/main) and [PowerShell](https://github.com/PowerShell/PowerShell). In our case the `Engineer` works in the [modules](./modules/) folder, which contains various bicep modules, and the [deployments](./deployments/non-prod/) folder contains an entry points fo the automation.

Sometimes, however, it may be quite difficult to properly explain the archtecture, even with a diagram. The more complex setup is, the bigger the problem. This is why when Bicep templates are ready, an `Architect` needs to ensure, that everythig was implemented as he intended. For that he wants to use [PSRule](https://github.com/Azure/PSRule.Rules.Azure) - a framework, which allows him to quickly create a set of rules, which would run on top the Bicep code and verify, that it does what was in the `Architect's` mind, and there was no misinterpretaion on the `Engeneer's` side. For this he creates a [.ps-rule](./.ps-rule/) folder, and develops a set of verification rules. Additionally he configures PSRule using [ps-rule.yaml](./ps-rule.yaml) file. Once it is done, the `Architect` can run the tool to make sure everything is correct.

Invocation example

```powershell
Invoke-PSRule -Format File -InputPath .
```

## Note

This repository has a `.devcontainer` configured, so you can try all this youself in Github Codespaces:

[![codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?repo=eosfor/psrule-demo&ref=main)
