<#
.SYNOPSIS
    Task 5: Drift Detection & Automated Tear-Down Cycle
.DESCRIPTION
    Audits active Azure resources, detects configuration drift, and executes an automated, state-aware tear-down.
#>

# 1. Audit deployed resource groups
az group list --output table

# 2. Verify Terraform-managed resources
az resource list --resource-group rg-iac-enterprise-prod-eastus --output table

# 3. Verify Bicep-managed resources
az resource list --resource-group rg-bicep-enterprise-prod-eastus --output table

# 4. Decommission Terraform-managed infrastructure
cd ~/Lab-05-Terraform-Azure
terraform destroy -auto-approve

# 5. Remove Bicep and Remote State resource groups asynchronously
az group delete --name rg-bicep-enterprise-prod-eastus --yes --no-wait
az group delete --name rg-terraform-state-eastus --yes --no-wait
