variable "azurerm_cosmosdb_account_name" {
  description = "Optional override for cosmosdb account name"
  type        = string
  default     = ""
}

locals {
  default_azurerm_cosmosdb_account_name = "cosmosdb${random_string.this.result}"
  azurerm_cosmosdb_account_name         = var.azurerm_cosmosdb_account_name != "" ? var.azurerm_cosmosdb_account_name : local.default_azurerm_cosmosdb_account_name
}

variable "create_cosmosdb" {
  description = "Whether to create the cosmodb"
  type        = bool
  default     = true
}

resource "azurerm_cosmosdb_account" "this" {
    for_each            = var.create_cosmosdb ? { "create" = true } : {}
    name                = local.azurerm_cosmosdb_account_name
    location            = local.resource_group_location
    resource_group_name = local.resource_group_name
    offer_type          = "Standard"
    kind                = "GlobalDocumentDB" # SQL API

    free_tier_enabled   = true
    multiple_write_locations_enabled = false

    consistency_policy {
        consistency_level = "Session"
    }

  geo_location {
    location          = local.resource_group_location
    failover_priority = 0
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each            = var.create_cosmosdb ? { "create" = true } : {}
  name                = "cosmosdb"
  resource_group_name = local.resource_group_name
  account_name        = azurerm_cosmosdb_account.this[each.key].name
  throughput          = 400 # Minimum RU/s for provisioned throughput
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "container" {
    for_each                = var.create_cosmosdb ? { "create" = true } : {}
    name                    = "sqlcontainer"
    database_name           = azurerm_cosmosdb_sql_database.this[each.key].name
    resource_group_name     = local.resource_group_name
    account_name            = azurerm_cosmosdb_account.this[each.key].name
    partition_key_paths   = ["/definition/id"]
    partition_key_version   = 2
    throughput              = 400
}

# Role Assignment for User-Assigned Managed Identity
resource "azurerm_role_assignment" "uai_access" {
  for_each             = var.create_cosmosdb ? { "create" = true } : {}
  scope                = azurerm_cosmosdb_account.this[each.key].id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# Role Assignment for Yourself
resource "azurerm_role_assignment" "self_access" {
  for_each             = var.create_cosmosdb ? { "create" = true } : {}
  scope                = azurerm_cosmosdb_account.this[each.key].id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}