# 🔹 Define Storage Tables
resource "azurerm_storage_table" "tables" {
  for_each = var.enable_storage_tables ? var.tables : {}

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

  # 🔹 Role Assignments (Optional)
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

#  Apply CORS & Logging Properties to Tables
resource "azurerm_storage_account_table_properties" "table_properties" {
  count = var.enable_storage_tables ? 1 : 0

  storage_account_id = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id

  # 🔹 CORS Rules
  dynamic "cors_rule" {
    for_each = var.table_properties.cors_rule == null ? [] : var.table_properties.cors_rule

    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  # 🔹 Logging
  dynamic "logging" {
    for_each = var.table_properties.logging == null ? [] : [var.table_properties.logging]

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
