# ====================================================
# Databricks
# ====================================================

variable "databricks_name" {
  description = "Optional override for databricks name"
  type        = string
  default     = ""
}

locals {
  default_databricks_name = "databricks-workspace-${random_string.this.result}"
  databricks_name         = var.databricks_name != "" ? var.databricks_name : local.default_databricks_name
}

variable "create_databricks" {
  description = "Whether to create the databricks workspace"
  type        = bool
  default     = true
}

resource "azurerm_databricks_workspace" "this" {
  for_each                      = var.create_databricks ? { "create" = true } : {}
  name                          = local.databricks_name
  resource_group_name           = local.resource_group_name
  location                      = local.resource_group_location
  sku                           = "premium"
  managed_resource_group_name   = "databricks-managed-rg-${random_string.this.result}"
}