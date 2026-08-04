<#
.SYNOPSIS
    Task 4: Alternate IaC Blueprint — Azure Native Bicep Deployment
.DESCRIPTION
    Demonstrates subscription-scoped Bicep module compilation, pre-flight what-if dry runs,
    and deployment using parameter files.
#>

# Create and enter dedicated Bicep workspace directory
mkdir -p ~/Lab-05-Bicep-Azure
cd ~/Lab-05-Bicep-Azure

# Validate Bicep code syntax and build template
az bicep build --file main.bicep

# Run pre-flight dry-run (What-If analysis)
az deployment sub what-if `
  --location eastus `
  --template-file main.bicep `
  --parameters main.bicepparam

# Execute deployment at subscription scope
az deployment sub create `
  --location eastus `
  --template-file main.bicep `
  --parameters main.bicepparam
