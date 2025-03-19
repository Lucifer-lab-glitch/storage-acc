resource "azurerm_storage_share" "this" {
  for_each = var.enable_file_shares ? var.shares : {}

  name                 = each.value.name
  storage_account_id   = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id
  quota               = each.value.quota
  enabled_protocol    = each.value.enabled_protocol
  
 

  # 🛠️ Signed Identifiers - Shared Access Policy (Optional)
  dynamic "signed_identifiers" {
    for_each = each.value.signed_identifiers == null ? [] : each.value.signed_identifiers

    content {
      id = signed_identifiers.value.id

      dynamic "access_policy" {
        for_each = signed_identifiers.value.access_policy == null ? [] : [signed_identifiers.value.access_policy]

        content {
          expiry_time = access_policy.value.expiry_time
          permission  = access_policy.value.permission
          start_time  = access_policy.value.start_time
        }
      }
    }
  }
  

  # 📌 Metadata (Optional)
  dynamic "metadata" {
    for_each = length(each.value.metadata) > 0 ? [each.value.metadata] : []

    content {
      name  = metadata.key
      value = metadata.value
    }
  }

  # 🔹 Role Assignments (Optional) - Apply RBAC permissions if needed
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

  #  Timeouts (Optional) - Define custom timeout durations
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

#  **Share Properties for CORS, Retention, and SMB**
resource "azurerm_storage_account_share_properties" "this" {
  count = var.enable_file_shares && var.share_properties != null ? 1 : 0

  storage_account_id = var.use_existing_storage_account ? var.existing_storage_account_id : azurerm_storage_account.storageacc.id


  dynamic "cors_rule" {
    for_each = var.share_properties.cors_rule == null ? [] : var.share_properties.cors_rule

    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  dynamic "retention_policy" {
    for_each = var.share_properties.retention_policy == null ? [] : [var.share_properties.retention_policy]

    content {
      days = retention_policy.value.days
    }
  }

  dynamic "smb" {
    for_each = var.share_properties.smb == null ? [] : [var.share_properties.smb]

    content {
      authentication_types            = smb.value.authentication_types
      channel_encryption_type         = smb.value.channel_encryption_type
      kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
      multichannel_enabled            = smb.value.multichannel_enabled
      versions                        = smb.value.versions
    }
  }

   depends_on = [azurerm_storage_account.storageacc]
}
