# ====================================================
# Data Factory
# ====================================================
variable "data_factory_name" {
  description = "Optional override for data factory name"
  type        = string
  default     = ""
}

locals {
  default_data_factory_name = "data-factory-${random_string.this.result}"
  data_factory_name         = var.data_factory_name != "" ? var.data_factory_name : local.default_data_factory_name
}

variable "create_data_factory" {
  description = "Whether to create the data factory"
  type        = bool
  default     = true
}

resource "azurerm_data_factory" "this" {
  for_each            = var.create_data_factory ? { "create" = true } : {}
  name                = local.data_factory_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  identity {
    type              = "UserAssigned"
    identity_ids      = [azurerm_user_assigned_identity.this.id]
  }
} 