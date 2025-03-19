resource "azurerm_storage_queue" "queues" {
  for_each = var.enable_storage_queues ? var.queues : {}

  name                 = each.value.name
  storage_account_name = var.use_existing_storage_account ? var.existing_storage_account_name : azurerm_storage_account.storageacc.name

  #  Metadata (Optional)
  dynamic "metadata" {
    for_each = length(each.value.metadata) > 0 ? [each.value.metadata] : []

    content {
      name  = metadata.key
      value = metadata.value
    }
  }

  #  Timeouts (Optional)
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azurerm_storage_account.storageacc]
}

#  Apply CORS, Logging, and Metrics to Queue
resource "azurerm_storage_account_queue_properties" "queue_properties" {
  count = var.enable_storage_queues ? 1 : 0

  storage_account_id = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id

  #  CORS Rules
  dynamic "cors_rule" {
    for_each = var.queue_properties.cors_rule == null ? [] : var.queue_properties.cors_rule

    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  #  Logging Settings
  dynamic "logging" {
    for_each = var.queue_properties.logging == null ? [] : [var.queue_properties.logging]

    content {
      delete                = logging.value.delete
      read                  = logging.value.read
      write                 = logging.value.write
      version               = logging.value.version
      retention_policy_days = logging.value.retention_policy_days
    }
  }

  depends_on = [azurerm_storage_account.storageacc]

}
