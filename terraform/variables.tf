variable "location" {
  type        = string
  description = "Azure region for primary infrastructure deployment"
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Target deployment environment designation"
  default     = "prod"
}

variable "hub_vnet_cidr" {
  type        = list(string)
  description = "CIDR block for the Hub Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnet_cidr" {
  type        = list(string)
  description = "CIDR block for the Spoke Virtual Network"
  default     = ["10.1.0.0/16"]
}

variable "tags" {
  type        = map(string)
  description = "Resource metadata tagging taxonomy"
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "Global Logistics Enterprise"
    Lab         = "Lab 05 IaC"
  }
}
