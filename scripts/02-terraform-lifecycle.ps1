<#
.SYNOPSIS
    Task 2 & Task 3: Execute Terraform Lifecycle Commands & Validate State Locking
.DESCRIPTION
    Initializes the remote AzureRM backend, performs code syntax validation, compiles an
    execution blueprint, and provisions enterprise infrastructure on Azure.
#>

# Navigate to the Terraform configuration directory
cd ~/Lab-05-Terraform-Azure

# 1. Initialize working directory & download providers
terraform init

# 2. Validate syntactic correctness
terraform validate

# 3. Plan deployment & output binary execution blueprint
terraform plan -out=tfplan.binary

# 4. Apply configuration to live Azure cloud environment
terraform apply tfplan.binary
