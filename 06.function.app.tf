# ====================================================
# Function App
# ====================================================
variable "storage_account_function_name" {
  description = "Optional override for the storage account name"
  type        = string
  default     = ""
}

variable "azurerm_service_plan_name" {
  description = "Optional override for the storage app service plan name"
  type        = string
  default     = ""
}

variable "azurerm_linux_function_app_name" {
  description = "Optional override for the function app name"
  type        = string
  default     = ""
}


locals {
  default_storage_account_function_name   = "storageaccntfunc${random_string.this.result}"
  storage_account_function_name           = var.storage_account_function_name != "" ? var.storage_account_function_name : local.default_storage_account_function_name

  default_azurerm_service_plan_name       = "function-app-service-plan-${random_string.this.result}"
  azurerm_service_plan_name               = var.azurerm_service_plan_name != "" ? var.azurerm_service_plan_name : local.default_azurerm_service_plan_name

  default_azurerm_linux_function_app_name = "function-app-${random_string.this.result}"
  azurerm_linux_function_app_name         = var.azurerm_linux_function_app_name != "" ? var.azurerm_linux_function_app_name : local.default_azurerm_linux_function_app_name
}

variable "create_function" {
  description = "Whether to create the storage account"
  type        = bool
  default     = true
}

resource "azurerm_storage_account" "function" {
  for_each                  = var.create_function ? { "create" = true } : {}
  name                      = local.storage_account_function_name
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  tags = {
    description             = "storage account for function app configurations"
  }
}

# -------------------------------------------------
# Storage account connection string
# -------------------------------------------------

resource "azurerm_key_vault_secret" "storage-connection-string" {
  for_each      = var.create_function ? { "create" = true } : {}
  name          = "${azurerm_storage_account.function[each.key].name}-primary-connection-string" #"name" may only contain alphanumeric characters and dashes
  value         = azurerm_storage_account.function[each.key].primary_connection_string  
  key_vault_id  = azurerm_key_vault.this.id  
  depends_on    = [ 
    azurerm_storage_account.function,
    azurerm_role_assignment.keyvault_contributor_self
  ]  
}

resource "azurerm_service_plan" "this" {
  for_each                  = var.create_function ? { "create" = true } : {}
  name                      = local.azurerm_service_plan_name
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  os_type                   = "Linux"
  sku_name                  = "Y1"
}

resource "azurerm_linux_function_app" "this" {
  for_each                        = var.create_function ? { "create" = true } : {}
  name                            = local.azurerm_linux_function_app_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  service_plan_id                 = azurerm_service_plan.this[each.key].id
  storage_key_vault_secret_id     = azurerm_key_vault_secret.storage-connection-string[each.key].id # secret containing connection string  
  key_vault_reference_identity_id = azurerm_user_assigned_identity.this.id  # identity with access to keyvault

  identity {
    type                          = "UserAssigned"
    identity_ids                  =  [azurerm_user_assigned_identity.this.id ]
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage-connection-string[each.key].id})"
    AzureWebJobsStorage                       = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage-connection-string[each.key].id})"
    WEBSITE_SKIP_CONTENTSHARE_VALIDATION      = 1
  }

  site_config {
    application_insights_connection_string    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.app-insights-string[each.key].id})"
    use_32_bit_worker             = false
    application_stack {
        python_version            = 3.11
    }
  }
}