variable "resource_group_name" {
  description   = "Name for the resource group"
  type          = string
  default       = "quick-sandbox-rg"
}

variable "user_assigned_identity_name" {
  description   = "User assigned identity"
  type          = string
  default       = "quick-deploy-user-assigned-identity"  
}

variable "resource_group_location" {
  description   = "Location for the resource group"
  type          = string
  default       = "East US 2"
}

