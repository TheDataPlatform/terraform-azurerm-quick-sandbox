variable "user_assigned_identity_name" {
  description = "Optional override for the user assigned identity name"
  type        = string
  default     = ""
}

locals {
  default_user_assigned_identity_name   = "user-assigned-id-${random_string.this.result}"
  user_assigned_identity_name           = var.user_assigned_identity_name != "" ? var.user_assigned_identity_name : local.default_user_assigned_identity_name
}

resource "azurerm_user_assigned_identity" "this" {
  location            = local.resource_group_location
  name                = local.user_assigned_identity_name
  resource_group_name = local.resource_group_name
}