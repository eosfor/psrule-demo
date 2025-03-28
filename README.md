# PSRule DEMO

> After some research and [troubleshooting](https://github.com/Azure/PSRule.Rules.Azure/issues/3298), thanks to @BernieWhite, I managed to make it work. The work is in progress still.

This repository demonstrates a practical scenario where an Architect defines an Azure solution—typically as a high-level diagram (e.g., in Visio)—and an Engineer implements the infrastructure using Bicep templates.

The purpose of this repo is to provide a framework for validating whether the implemented infrastructure matches the original architectural design. It focuses on verifying the presence of required Azure resources, their proper configuration, and correct network integration—such as ensuring services are deployed into the right virtual networks and subnets, with appropriate private endpoints and connections.

This validation is performed using PSRule for Azure, enabling automated checks and alignment between design and deployment. Still WIP.

Invocation example

```powershell
Invoke-PSRule -Format File -InputPath .
```
