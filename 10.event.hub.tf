# ====================================================
# Event Hub: multiples eventhubs per namespace
# ====================================================
variable "eventhub_namespace_name" {
  description = "Optional override for eventhub namespace name"
  type        = string
  default     = ""
}

variable "eventhub_name" {
  description = "Optional override for eventhub name"
  type        = string
  default     = ""
}

locals {
  default_eventhub_namespace_name = "eventhub-namespace-${random_string.this.result}"
  eventhub_namespace_name         = var.eventhub_namespace_name != "" ? var.eventhub_namespace_name : local.default_eventhub_namespace_name

  default_eventhub_name           = "eventhub-${random_string.this.result}"
  eventhub_name                   = var.eventhub_name != "" ? var.eventhub_name : local.default_eventhub_name
}

variable "create_eventhub" {
  description = "Whether to create the databricks workspace"
  type        = bool
  default     = true
}


# Event Hubs Namespace (Standard Tier for Kafka and Event Capture)
resource "azurerm_eventhub_namespace" "this" {
  for_each            = var.create_eventhub ? { "create" = true } : {}
  name                = local.eventhub_namespace_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = "Standard" # Kafka support and Event Capture enabled
  capacity            = 1          # 1 Throughput Unit (minimum)
}


# Event Hub 
resource "azurerm_eventhub" "this" {
  for_each          = var.create_eventhub ? { "create" = true } : {}
  name              = local.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.this[each.key].id
  partition_count   = 2
  message_retention = 1

  capture_description {
    enabled               = true
    encoding              = "Avro"    # Options: "Avro" or "AvroDeflate"
    interval_in_seconds   = 60        # Capture interval between 60 and 900 seconds - default 300
    size_limit_in_bytes   = 314572800 # Capture size limit between 10 MB (10485760 bytes) and 500 MB (524288000 bytes)
    skip_empty_archives   = false     # Whether to skip empty archives

    destination {
      name                = "EventHubArchive.AzureBlockBlob" # Only "EventHubArchive.AzureBlockBlob" is supported
      storage_account_id  = azurerm_storage_account.this[each.key].id
      blob_container_name = azurerm_storage_container.eventcapture[each.key].name
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
    }
  }
}