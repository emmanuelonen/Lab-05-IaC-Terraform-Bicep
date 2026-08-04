<#
.SYNOPSIS
    Task 1: Establish Secure Remote State Infrastructure in Azure
.DESCRIPTION
    Bootstraps an isolated Azure Storage Account and Blob Container dedicated to housing
    the Terraform state file securely with encryption, TLS 1.2, and disabled public blob access.
#>

# Log in to Azure and select active subscription
az login
az account set --subscription "YOUR_AZURE_SUBSCRIPTION_ID"

# Define deployment parameters
$RESOURCE_GROUP_NAME = "rg-terraform-state-eastus"
$LOCATION            = "eastus"
$STORAGE_ACCOUNT_NAME = "sttfstateprod$(Get-Random -Minimum 10000 -Maximum 99999)"
$CONTAINER_NAME       = "tfstate"

# 1. Create the Resource Group
az group create --name $RESOURCE_GROUP_NAME --location$LOCATION

# 2. Create the Storage Account (Encrypted, TLS 1.2, Public Access Disabled)
az storage account create `
  --resource-group $RESOURCE_GROUP_NAME `
  --name $STORAGE_ACCOUNT_NAME `
  --sku Standard_LRS `
  --encryption-services blob `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false

# 3. Create the Blob Container for Terraform State
az storage container create `
  --name $CONTAINER_NAME `
  --account-name $STORAGE_ACCOUNT_NAME

# 4. Display generated Storage Account name
Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "YOUR STORAGE ACCOUNT NAME IS: $STORAGE_ACCOUNT_NAME" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor Green
