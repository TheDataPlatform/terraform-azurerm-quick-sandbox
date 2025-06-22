variable "sql_server_name" {
  description = "Optional override for the sql server name"
  type        = string
  default     = ""
}

variable "sql_server_admin_name" {
  description = "Optional override for the sql server admin name"
  type        = string
  default     = ""
}

variable "sql_server_database_name" {
  description = "Optional override for the sql server database name"
  type        = string
  default     = ""
}

locals {
  default_sql_server_name           = "sqlserver${random_string.this.result}"
  sql_server_name                   = var.sql_server_name != "" ? var.sql_server_name : local.default_sql_server_name

  default_sql_server_admin_name     = "adminuser"
  sql_server_admin_name             = var.sql_server_name != "" ? var.sql_server_admin_name : local.default_sql_server_admin_name

  default_sql_server_database_name  = "database${random_string.this.result}"
  sql_server_database_name          = var.sql_server_database_name != "" ? var.sql_server_database_name : local.default_sql_server_database_name
}

variable "create_sql_server" {
  description = "Whether to create sql server"
  type        = bool
  default     = true
}

resource "azurerm_key_vault_secret" "sql_server_admin_name" {
  name         = "sql-server-username"
  value        = local.sql_server_admin_name
  key_vault_id = azurerm_key_vault.this.id
  depends_on = [ local.sql_server_admin_name, azurerm_role_assignment.keyvault_contributor_self ]
}

resource "azurerm_mssql_server" "this" {
  for_each                      = var.create_sql_server ? { "create" = true } : {}
  name                          = local.sql_server_name
  resource_group_name           = local.resource_group_name
  location                      = local.resource_group_location
  version                       = "12.0"
  
  administrator_login           = local.sql_server_admin_name
  administrator_login_password  = random_password.password.result
}

resource "azurerm_mssql_database" "this" {
  for_each      = var.create_sql_server ? { "create" = true } : {}
  name          = local.sql_server_database_name
  server_id     = azurerm_mssql_server.this[each.key].id
  collation     = "SQL_Latin1_General_CP1_CI_AS"
  license_type  = "LicenseIncluded"
  max_size_gb   = 2
  sku_name      = "S0"
  enclave_type  = "VBS"

  lifecycle {
    prevent_destroy = false
  }
}