variable "resource_group_name" {
  description = "Optional override for the RG name"
  type        = string
  default     = ""
}

variable "resource_group_location" {
  description   = "Location for the resource group"
  type          = string
  default       = ""
}

locals {
  default_resource_group_name     = "quick-sandbox-rg-${random_string.this.result}"
  resource_group_name             = var.resource_group_name != "" ? var.resource_group_name : local.default_resource_group_name

  default_resource_group_location = "East US 2"
  resource_group_location         = var.resource_group_location != "" ? var.resource_group_location : local.default_resource_group_location
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.resource_group_location
}