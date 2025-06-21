resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_storage_account" "this" {
  name                     = lower("storageaccount${random_string.random.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = [ random_string.random ]
}

resource "random_string" "random" {
  length           = 10
  special          = false
}