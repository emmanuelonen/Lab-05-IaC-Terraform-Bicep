location        = "eastus"
environment     = "prod"
hub_vnet_cidr   = ["10.0.0.0/16"]
spoke_vnet_cidr = ["10.1.0.0/16"]

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  Project     = "Global Logistics & Enterprise Services"
  Lab         = "Lab-05-IaC-Terraform-Bicep"
  Owner       = "Emmanuel Onen"
}
