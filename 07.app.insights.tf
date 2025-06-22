variable "app_insights_name" {
  description = "Optional override for application insights name"
  type        = string
  default     = ""
}

variable "log_analytics_name" {
  description = "Optional override for log analytics name"
  type        = string
  default     = ""
}

locals {
  default_app_insights_name = "app-insights-${random_string.this.result}"
  app_insights_name         = var.app_insights_name != "" ? var.app_insights_name : local.default_app_insights_name

  default_log_analytics_name = "log-analytics-${random_string.this.result}"
  log_analytics_name         = var.log_analytics_name != "" ? var.log_analytics_name : local.default_log_analytics_name
}

resource "azurerm_log_analytics_workspace" "this" {
  for_each            = var.create_function ? { "create" = true } : {}
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "this" {
  for_each            = var.create_function ? { "create" = true } : {}
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  workspace_id        = azurerm_log_analytics_workspace.this[each.key].id
  application_type    = "web"
}

resource "azurerm_key_vault_secret" "app-insights-string" {
  for_each      = var.create_function ? { "create" = true } : {}
  name          = "${azurerm_application_insights.this[each.key].name}-connection-string" #"name" may only contain alphanumeric characters and dashes
  value         = azurerm_application_insights.this[each.key].connection_string
  key_vault_id  = azurerm_key_vault.this.id  
  depends_on    = [ 
    azurerm_application_insights.this,
    azurerm_role_assignment.keyvault_contributor_self
  ]  
}