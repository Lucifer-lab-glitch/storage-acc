#  Define Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each = var.enable_storage_containers ? var.containers : {}

  name                  = each.value.name
  storage_account_id    = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id
  container_access_type = each.value.container_access_type

  #  Metadata (Optional)
  dynamic "metadata" {
    for_each = length(each.value.metadata) > 0 ? [each.value.metadata] : []

    content {
      name  = metadata.key
      value = metadata.value
    }
  }

  #  Role Assignments (Optional)
  dynamic "role_assignments" {
    for_each = each.value.role_assignments == null ? [] : each.value.role_assignments

    content {
      role_definition_id_or_name             = role_assignments.value.role_definition_id_or_name
      principal_id                           = role_assignments.value.principal_id
      description                            = role_assignments.value.description
      skip_service_principal_aad_check       = role_assignments.value.skip_service_principal_aad_check
      condition                              = role_assignments.value.condition
      condition_version                      = role_assignments.value.condition_version
      delegated_managed_identity_resource_id = role_assignments.value.delegated_managed_identity_resource_id
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

#  Apply CORS, Retention Policy & Other Properties to Containers
resource "azurerm_storage_account_blob_properties" "container_properties" {
  count = var.enable_storage_containers ? 1 : 0

  storage_account_id = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id

  # 🔹 CORS Rules
  dynamic "cors_rule" {
    for_each = var.container_properties.cors_rule == null ? [] : var.container_properties.cors_rule

    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  #  Retention Policy
  dynamic "delete_retention_policy" {
    for_each = var.container_properties.delete_retention_policy == null ? [] : [var.container_properties.delete_retention_policy]

    content {
      days = delete_retention_policy.value.days
    }
  }

  # 🔹 Versioning & Change Feed (Optional)
  change_feed_enabled           = var.container_properties.change_feed_enabled
  change_feed_retention_in_days = var.container_properties.change_feed_retention_in_days
  last_access_time_enabled      = var.container_properties.last_access_time_enabled
  versioning_enabled            = var.container_properties.versioning_enabled

  depends_on = [azurerm_storage_account.storageacc]

}
