provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id                   = var.subscription_id
  resource_provider_registrations  = "none"
}

# Environment Variable: TF_VAR_subscription_id
variable "subscription_id" {
  description = "Azure Subscription ID to deploy into"
  type        = string
  default     = null
}

module "quick-sandbox" {
  source = "../"
}