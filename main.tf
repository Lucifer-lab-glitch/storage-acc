resource "azurerm_storage_account" "storageacc" {
  account_replication_type          = var.account_replication_type  #Data Management----->Redundancy--->Replication Type
  account_tier                      = var.account_tier
  location                          = var.location
  name                              = var.name
  resource_group_name               = var.resource_group_name
  access_tier                       = var.account_kind == "BlockBlobStorage" && var.account_tier == "Premium" ? null : var.access_tier
  account_kind                      = var.account_kind
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public ? true : false
  allowed_copy_scope                = var.allowed_copy_scope
  default_to_oauth_authentication   = var.default_to_oauth_authentication
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  is_hns_enabled                    = var.is_hns_enabled
  large_file_share_enabled          = var.large_file_share_enabled ? true : false
  min_tls_version                   = var.min_tls_version
  nfsv3_enabled                     = var.nfsv3_enabled ? true : false
  public_network_access_enabled     = var.public_network_access_enabled
  sftp_enabled                      = var.sftp_enabled ? true : false
  shared_access_key_enabled         = var.shared_access_key_enabled
  tags                              = var.tags

#----------------Azure Files Authentication----------
dynamic "azure_files_authentication" {
  for_each = var.enable_azure_files_authentication ? [var.azure_files_authentication] : []

  content {
    directory_type                 = azure_files_authentication.value.directory_type
    default_share_level_permission = azure_files_authentication.value.default_share_level_permission

#----------AAD -----------------
    dynamic "active_directory" {
      for_each = azure_files_authentication.value.active_directory == null ? [] : [
        azure_files_authentication.value.active_directory
      ]

      content {
        domain_guid         = active_directory.value.domain_guid
        domain_name         = active_directory.value.domain_name
        domain_sid          = active_directory.value.domain_sid
        forest_name         = active_directory.value.forest_name
        netbios_domain_name = active_directory.value.netbios_domain_name
        storage_sid         = active_directory.value.storage_sid
      }
    }
  }
}

  #---------Identity--------------
  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}

    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  #-------------Network Rules---------
dynamic "network_rules" {
  for_each = var.enable_network_rules ? [var.network_rules] : []

  content {
    default_action             = network_rules.value.default_action
    bypass                     = network_rules.value.bypass
    ip_rules                   = network_rules.value.ip_rules
    virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
  }
}

  #------------Routing--------------
  dynamic "routing" {
  for_each = var.enable_routing ? [var.routing] : []

  content {
    choice                      = routing.value.choice
    publish_internet_endpoints  = routing.value.publish_internet_endpoints
    publish_microsoft_endpoints = routing.value.publish_microsoft_endpoints
  }
}

  #--------------Sas Policy------------------
dynamic "sas_policy" {
  for_each = var.enable_sas_policy ? [var.sas_policy] : []

  content {
    expiration_period = sas_policy.value.expiration_period
    expiration_action = sas_policy.value.expiration_action
  }
}

}

#-----------Role Assignment-------------

resource "azurerm_role_assignment" "storage_account" {
  for_each = var.enable_role_assignments ? var.role_assignments : {}

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_storage_account.storageacc.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id

  # Directly assign role using ID or Name
  role_definition_id   = each.value.role_definition_id
  role_definition_name = each.value.role_definition_name

  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check

  depends_on = [azurerm_storage_account.storageacc]
}

# ----------------- Static Website Configuration-------------------
resource "azurerm_storage_account_static_website" "this" {
  count = var.enable_static_website ? 1 : 0  #  Deploy only if needed

  storage_account_id = azurerm_storage_account.storageacc.id
  index_document     = var.static_website.index_document
  error_404_document = var.static_website.error_404_document
}

#------------Storage Account Management Policy--------------

resource "azurerm_storage_management_policy" "this" {
  count = var.enable_storage_management_policy ? 1 : 0  #  Deploy only if enabled

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.storage_management_policy_rule

    content {
      enabled = rule.value.enabled
      name    = rule.value.name

      dynamic "actions" {
        for_each = [rule.value.actions]

        content {
          dynamic "base_blob" {
            for_each = actions.value.base_blob == null ? [] : [actions.value.base_blob]

            content {
              auto_tier_to_hot_from_cool_enabled                             = base_blob.value.auto_tier_to_hot_from_cool_enabled
              delete_after_days_since_creation_greater_than                  = base_blob.value.delete_after_days_since_creation_greater_than
              delete_after_days_since_last_access_time_greater_than          = base_blob.value.delete_after_days_since_last_access_time_greater_than
              delete_after_days_since_modification_greater_than              = base_blob.value.delete_after_days_since_modification_greater_than
              tier_to_archive_after_days_since_creation_greater_than         = base_blob.value.tier_to_archive_after_days_since_creation_greater_than
              tier_to_archive_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_archive_after_days_since_last_access_time_greater_than
              tier_to_archive_after_days_since_last_tier_change_greater_than = base_blob.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_archive_after_days_since_modification_greater_than     = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = base_blob.value.tier_to_cold_after_days_since_creation_greater_than
              tier_to_cold_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cold_after_days_since_last_access_time_greater_than
              tier_to_cold_after_days_since_modification_greater_than        = base_blob.value.tier_to_cold_after_days_since_modification_greater_than
              tier_to_cool_after_days_since_creation_greater_than            = base_blob.value.tier_to_cool_after_days_since_creation_greater_than
              tier_to_cool_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cool_after_days_since_last_access_time_greater_than
              tier_to_cool_after_days_since_modification_greater_than        = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            }
          }
          dynamic "snapshot" {
            for_each = actions.value.snapshot == null ? [] : [actions.value.snapshot]

            content {
              change_tier_to_archive_after_days_since_creation               = snapshot.value.change_tier_to_archive_after_days_since_creation
              change_tier_to_cool_after_days_since_creation                  = snapshot.value.change_tier_to_cool_after_days_since_creation
              delete_after_days_since_creation_greater_than                  = snapshot.value.delete_after_days_since_creation_greater_than
              tier_to_archive_after_days_since_last_tier_change_greater_than = snapshot.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = snapshot.value.tier_to_cold_after_days_since_creation_greater_than
            }
          }
          dynamic "version" {
            for_each = actions.value.version == null ? [] : [actions.value.version]

            content {
              change_tier_to_archive_after_days_since_creation               = version.value.change_tier_to_archive_after_days_since_creation
              change_tier_to_cool_after_days_since_creation                  = version.value.change_tier_to_cool_after_days_since_creation
              delete_after_days_since_creation                               = version.value.delete_after_days_since_creation
              tier_to_archive_after_days_since_last_tier_change_greater_than = version.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = version.value.tier_to_cold_after_days_since_creation_greater_than
            }
          }
        }
      }
      dynamic "filters" {
        for_each = [rule.value.filters]

        content {
          blob_types   = filters.value.blob_types
          prefix_match = filters.value.prefix_match

          dynamic "match_blob_index_tag" {
            for_each = filters.value.match_blob_index_tag == null ? [] : filters.value.match_blob_index_tag

            content {
              name      = match_blob_index_tag.value.name
              value     = match_blob_index_tag.value.value
              operation = match_blob_index_tag.value.operation
            }
          }
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.storage_management_policy_timeouts == null ? [] : [var.storage_management_policy_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}


#---------- data_lake_gen2_filesystem------------


resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  count = var.storage_data_lake_gen2_filesystem != null ? 1 : 0

  name                     = var.storage_data_lake_gen2_filesystem.name
  storage_account_id       = azurerm_storage_account.this.id
  default_encryption_scope = var.storage_data_lake_gen2_filesystem.default_encryption_scope
  group                    = var.storage_data_lake_gen2_filesystem.group
  owner                    = var.storage_data_lake_gen2_filesystem.owner
  properties               = var.storage_data_lake_gen2_filesystem.properties

  dynamic "ace" {
    for_each = var.storage_data_lake_gen2_filesystem.ace == null ? [] : var.storage_data_lake_gen2_filesystem.ace

    content {
      permissions = ace.value.permissions
      type        = ace.value.type
      id          = ace.value.id
      scope       = ace.value.scope
    }
  }
  dynamic "timeouts" {
    for_each = var.storage_data_lake_gen2_filesystem.timeouts == null ? [] : [var.storage_data_lake_gen2_filesystem.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azurerm_storage_account.this]
}






