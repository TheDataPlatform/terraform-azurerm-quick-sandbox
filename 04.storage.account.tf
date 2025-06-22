variable "storage_account_name" {
  description = "Optional override for the storage account name"
  type        = string
  default     = ""
}

locals {
  default_storage_account_name = "storageaccount${random_string.this.result}"
  storage_account_name         = var.storage_account_name != "" ? var.storage_account_name : local.default_storage_account_name
}

variable "create_storage_account" {
  description = "Whether to create the storage account"
  type        = bool
  default     = true
}

resource "azurerm_storage_account" "this" {
  for_each = var.create_storage_account ? { "create" = true } : {}
  name                     = lower(local.storage_account_name)
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    description            = "basic storage account"
  }
}

resource "azurerm_storage_container" "eventcapture" {
  for_each              = var.create_storage_account ? { "create" = true } : {}
  name                  = "eventcapture"
  storage_account_id    = azurerm_storage_account.this[each.key].id
  container_access_type = "private"
}