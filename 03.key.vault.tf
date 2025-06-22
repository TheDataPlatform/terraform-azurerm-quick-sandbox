# ====================================================
# Key Vault
# ====================================================

data "azurerm_client_config" "current" {}

variable "key_vault_name" {
  description = "Optional override for the key vault name"
  type        = string
  default     = ""
}

locals {
  default_key_vault_name   = "keyvault${random_string.this.result}"
  key_vault_name           = var.key_vault_name != "" ? var.key_vault_name : local.default_key_vault_name
}

resource "azurerm_key_vault" "this" {
  name                          = local.key_vault_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  enabled_for_disk_encryption   = true
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  sku_name                      = "standard"
  enable_rbac_authorization     = true
}

resource "azurerm_role_assignment" "keyvault_contributor_self" {
  principal_id          = data.azurerm_client_config.current.object_id
  role_definition_name  = "Key Vault Secrets Officer"                           
  scope                 = azurerm_key_vault.this.id
}

resource "azurerm_role_assignment" "keyvault_contributor_uaid" {
  principal_id          = azurerm_user_assigned_identity.this.principal_id
  role_definition_name  = "Key Vault Secrets Officer"                           
  scope                 = azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "password" {
  name                  = "password"
  value                 = random_password.password.result
  key_vault_id          = azurerm_key_vault.this.id
  depends_on            = [ random_password.password, azurerm_role_assignment.keyvault_contributor_self ]
}