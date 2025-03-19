variable "location" {
  type        = string
  description = <<DESCRIPTION
Azure region where the resource should be deployed.
If null, the location will be inferred from the resource group location.
DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the resource."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters, valid characters are lowercase letters and numbers."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

#-----------------Azure Files Authentication----------

variable "enable_azure_files_authentication" {
  type        = bool
  default     = false
  description = "Enable Azure Files Authentication. If false, authentication will not be configured."
}

variable "azure_files_authentication" {
  type = object({
    directory_type                 = string
    default_share_level_permission = string
    active_directory = optional(object({
      domain_guid         = string
      domain_name         = string
      domain_sid          = string
      forest_name         = string
      netbios_domain_name = string
      storage_sid         = string
    }), null)
  })
  default     = null
  description = <<EOT
Configuration block for Azure Files Authentication.

- `directory_type` - (Required) The directory type to use for authentication. Valid values are:
  - `AADDS` (Azure Active Directory Domain Services)
  - `AD` (On-Prem Active Directory)

- `default_share_level_permission` - (Required) Default share-level permission for Azure Files.

- `active_directory` (Optional):
  - `domain_guid` - (Required) The GUID of the Active Directory domain.
  - `domain_name` - (Required) The name of the Active Directory domain.
  - `domain_sid` - (Required) The security identifier (SID) of the Active Directory domain.
  - `forest_name` - (Required) The name of the Active Directory forest.
  - `netbios_domain_name` - (Required) The NetBIOS domain name.
  - `storage_sid` - (Required) The security identifier (SID) of the storage account.

Example Usage:

enable_azure_files_authentication = true

azure_files_authentication = {
  directory_type                 = "AADDS"
  default_share_level_permission = "StorageAccountAdmin"
  active_directory = {
    domain_guid         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    domain_name         = "example.com"
    domain_sid          = "S-1-5-21-xxxxxxxxx-xxxxxxxxx-xxxxxxxxx"
    forest_name         = "example.com"
    netbios_domain_name = "EXAMPLE"
    storage_sid         = "S-1-5-21-xxxxxxxxx-xxxxxxxxx-xxxxxxxxx-1234"
  }
}
EOT
}

#--------------Identity------------

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

#---------------Network Rules-----------
variable "enable_network_rules" {
  type        = bool
  default     = false
  description = "Enable or disable network rules configuration."
}

variable "network_rules" {
  type = object({
    bypass                     = optional(set(string), ["AzureServices"])
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default = {}

  description = <<-EOT
 > Note the default value for this variable will block all public access to the storage account. If you want to disable all network rules, set this value to `null`.

 - `bypass` - (Optional) Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of `Logging`, `Metrics`, `AzureServices`, or `None`.
 - `default_action` - (Required) Specifies the default action of allow or deny when no other rules match. Valid options are `Deny` or `Allow`.
 - `ip_rules` - (Optional) List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges (as defined in [RFC 1918](https://tools.ietf.org/html/rfc1918#section-3)) are not allowed.
 - `storage_account_id` - (Required) Specifies the ID of the storage account. Changing this forces a new resource to be created.
 - `virtual_network_subnet_ids` - (Optional) A list of virtual network subnet ids to secure the storage account.

 ---
 `private_link_access` block supports the following:
 - `endpoint_resource_id` - (Required) The resource id of the resource access rule to be granted access.
 - `endpoint_tenant_id` - (Optional) The tenant id of the resource of the resource access rule to be granted access. Defaults to the current tenant id.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account.
EOT
}
#------------Routing----------
variable "enable_routing" {
  type        = bool
  default     = false
  description = "Enable or disable routing configuration."
}

variable "routing" {
  type = object({
    choice                      = optional(string, "MicrosoftRouting")
    publish_internet_endpoints  = optional(bool, false)
    publish_microsoft_endpoints = optional(bool, false)
  })
  default     = null
  description = <<-EOT
 - `choice` - (Optional) Specifies the kind of network routing opted by the user. Possible values are `InternetRouting` and `MicrosoftRouting`. Defaults to `MicrosoftRouting`.
 - `publish_internet_endpoints` - (Optional) Should internet routing storage endpoints be published? Defaults to `false`.
 - `publish_microsoft_endpoints` - (Optional) Should Microsoft routing storage endpoints be published? Defaults to `false`.
EOT
}

#-----------Role Assignments------------

# Enable or Disable Role Assignments
variable "enable_role_assignments" {
  type        = bool
  default     = false
  description = "Set to `true` to enable RBAC Role Assignments for the Storage Account."
}

# Role Assignments Configuration
variable "role_assignments" {
  type = map(object({
    principal_id                           = string
    role_definition_id                     = optional(string, null)
    role_definition_name                   = optional(string, null)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
  }))

  default     = {}
  description = <<EOT
Map of Role Assignments to apply on the Storage Account.

- `principal_id` (Required): The Azure AD object ID of the user, group, or managed identity.
- `role_definition_id` (Optional): The role ID to assign (if using ID).
- `role_definition_name` (Optional): The role name to assign (if using name).
- `condition` (Optional): The condition for role assignment.
- `condition_version` (Optional): The version of the condition.
- `delegated_managed_identity_resource_id` (Optional): If applicable, the delegated resource ID.
- `skip_service_principal_aad_check` (Optional): If `true`, skips service principal checks.

**Example Usage:**
```terraform
enable_role_assignments = true
role_assignments = {
  "blob_contributor" = {
    principal_id               = "00000000-0000-0000-0000-000000000000"
    role_definition_name       = "Storage Blob Data Contributor"
  }
  "queue_reader" = {
    principal_id               = "11111111-1111-1111-1111-111111111111"
    role_definition_id         = "/subscriptions/xxxxxx/providers/Microsoft.Authorization/roleDefinitions/yyyyyy"
  }
  EOT
}


variable "tags" {
  type        = map(string)
  default     = null
  description = "Custom tags to apply to the resource."
}


#------------------ Storage Account Configuration Variables--------------

variable "access_tier" {
  type        = string
  default     = "Hot"
  description = "(Optional) Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`."

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Invalid value for access tier. Valid options are 'Hot' or 'Cool'."
  }
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "(Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`."

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Invalid value for account kind. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`."
  }
}

  #Data Management----->Redundancy--->Replication Type Variable
variable "account_replication_type" {  
  type        = string
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`.  Defaults to `ZRS`"
  nullable    = false
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid value for replication type. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  }
}

variable "account_tier" {
  type        = string
  description = "(Required) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created."
  default     = "Standard"
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Invalid value for account tier. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created."
  }
}

variable "large_file_share_enabled" {
  type        = bool
  default     = false
  description = "Set to true to enable large file share. Needed only if large file share support is required."
}

variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Enables Hierarchical Namespace (HNS) for the Storage Account. Required for Data Lake Storage Gen2."
}


variable "allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "(Optional) Allow or disallow nested items within this Account to opt into being public. Defaults to `false`."
}

variable "allowed_copy_scope" {
  type        = string
  default     = null
  description = "(Optional) Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet. Possible values are `AAD` and `PrivateLink`."
}



variable "default_to_oauth_authentication" {
  type        = bool
  default     = null
  description = "(Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false`"
}


variable "https_traffic_only_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag which forces HTTPS if enabled, see [here](https://docs.microsoft.com/azure/storage/storage-require-secure-transfer/) for more information. Defaults to `true`."
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is infrastructure encryption enabled? Changing this forces a new resource to be created. Defaults to `false`."
}


variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "(Optional) The minimum supported TLS version for the storage account. Possible values are `TLS1_0`, `TLS1_1`, and `TLS1_2`. Defaults to `TLS1_2` for new storage accounts."
}


variable "nfsv3_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to `false`."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether the public network access is enabled? Defaults to `false`."
}

#----------SAS policy------------
variable "enable_sas_policy" {
  type        = bool
  default     = false
  description = "Enable or disable SAS policy for the storage account."
}

variable "sas_policy" {
  type = object({
    expiration_action = optional(string, "Log")
    expiration_period = string
  })
  default     = null
  description = <<-EOT
 - `expiration_action` - (Optional) The SAS expiration action. The only possible value is `Log` at this moment. Defaults to `Log`.
 - `expiration_period` - (Required) The SAS expiration period in format of `DD.HH:MM:SS`.
EOT
}

variable "sftp_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, enable SFTP for the storage account.  Defaults to `false`."
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `false`."
}

# -------Static Website Configuration ------------
variable "enable_static_website" {
  type        = bool
  default     = false
  description = "Set to `true` to enable static website hosting in the Storage Account."
}

# Static Website Configuration (Applies Only If Enabled)
variable "static_website" {
  type = object({
    index_document     = string
    error_404_document = optional(string, null)
  })
  default     = null
  description = <<EOT
Configuration for Azure Storage Account Static Website hosting.

- `index_document` (Required) - The default homepage (e.g., "index.html").
- `error_404_document` (Optional) - The error page for 404 responses.

**Example Usage:**
```terraform
enable_static_website = true
static_website = {
  index_document     = "index.html"
  error_404_document = "404.html"
  EOT
}


#----------Private End Point Variables----------

#  Toggle Private Endpoints
variable "enable_private_endpoints" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Private Endpoints for the Storage Account."
}

#  Private Endpoint Subnet ID
variable "private_endpoint_subnet_id" {
  type        = string
  description = "The subnet ID where the Private Endpoint should be deployed."
}

#  Private Endpoint Subresource Names
variable "private_endpoint_subresource_names" {
  type        = list(string)
  default     = ["blob"] # Customer can choose which subresources need a Private Endpoint
  description = "List of subresources for which to create Private Endpoints (e.g., `blob`, `file`, `queue`, `table`)."
}

#  Private DNS Zone Management Toggle
variable "private_dns_zone_manage" {
  type        = bool
  default     = true
  description = "Boolean flag to determine if Private DNS Zone should be managed."
}

#  Private DNS Zone Group Name
variable "private_dns_zone_group_name" {
  type        = string
  default     = "default"
  description = "Name of the Private DNS Zone Group."
}

#  Private DNS Zone Resource IDs
variable "private_dns_zone_resource_ids" {
  type        = list(string)
  default     = []
  description = "List of Private DNS Zone Resource IDs."
}

#  Private Endpoint IP Configurations
variable "private_endpoint_ip_configurations" {
  type = list(object({
    name               = string
    private_ip_address = optional(string, null)
    member_name        = optional(string, null)
    subresource_name   = optional(string, null)
  }))
  default     = []
  description = "List of IP configurations for the Private Endpoint."
}

#  Application Security Group Associations (Optional)
variable "application_security_group_association_ids" {
  type        = list(string)
  default     = []
  description = "List of Application Security Group IDs to associate with the Private Endpoint."
}

#-------------------Management Policy---------------

# variable "storage_management_policy_storage_account_id" {
#   type        = string
#   description = "(Required) Specifies the id of the storage account to apply the management policy to. Changing this forces a new resource to be created."
#   nullable    = false
# }
variable "enable_storage_management_policy" {
  type        = bool
  default     = false
  description = "Enable or disable Storage Account Management Policy."
}

variable "storage_management_policy_rule" {
  type = map(object({
    enabled = bool
    name    = string
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
    filters = object({
      blob_types   = set(string)
      prefix_match = optional(set(string))
      match_blob_index_tag = optional(set(object({
        name      = string
        operation = optional(string)
        value     = string
      })))
    })
  }))
  default     = {}
  nullable    = false
  description = <<-EOT
 - `enabled` - (Required) Boolean to specify whether the rule is enabled.
 - `name` - (Required) The name of the rule. Rule name is case-sensitive. It must be unique within a policy.

 ---
 `actions` block supports the following:

 ---
 `base_blob` block supports the following:
 - `auto_tier_to_hot_from_cool_enabled` - (Optional) Whether a blob should automatically be tiered from cool back to hot if it's accessed again after being tiered to cool. Defaults to `false`.
 - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob. Must be between `0` and `99999`. Defaults to `-1`.
 - `delete_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to delete the blob. Must be between `0` and `99999`. Defaults to `-1`.
 - `delete_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to delete the blob. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_creation_greater_than` - (Optional) The age in days after creation to archive storage. Supports blob currently at Hot or Cool tier. Must be between `0` and`99999`. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between `0` and`99999`. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cold_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cold_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cold storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cool_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cool storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cool_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cool_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to `-1`.

 ---
 `snapshot` block supports the following:
 - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to archive storage. Must be between 0 and 99999. Defaults to `-1`.
 - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to cool storage. Must be between 0 and 99999. Defaults to `-1`.
 - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob snapshot. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.

 ---
 `version` block supports the following:
 - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob version to archive storage. Must be between 0 and 99999. Defaults to `-1`.
 - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days creation create to tier blob version to cool storage. Must be between 0 and 99999. Defaults to `-1`.
 - `delete_after_days_since_creation` - (Optional) The age in days after creation to delete the blob version. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.

 ---
 `filters` block supports the following:
 - `blob_types` - (Required) An array of predefined values. Valid options are `blockBlob` and `appendBlob`.
 - `prefix_match` - (Optional) An array of strings for prefixes to be matched.

 ---
 `match_blob_index_tag` block supports the following:
 - `name` - (Required) The filter tag name used for tag based filtering for blob objects.
 - `operation` - (Optional) The comparison operator which is used for object comparison and filtering. Possible value is `==`. Defaults to `==`.
 - `value` - (Required) The filter tag value used for tag based filtering for blob objects.
EOT
}

variable "storage_management_policy_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Account Management Policy.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Account Management Policy.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account Management Policy.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Account Management Policy.
EOT
}

#-------------------File System----------------------

variable "enable_data_lake_gen2" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Azure Data Lake Gen2 Filesystem."
}

variable "storage_data_lake_gen2_filesystem" {
  type = object({
    default_encryption_scope = optional(string)
    group                    = optional(string)
    name                     = string
    owner                    = optional(string)
    properties               = optional(map(string))

    ace = optional(set(object({
      id          = optional(string)
      permissions = string
      scope       = optional(string)
      type        = string
    })), [])
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  description = <<-EOT
 - `default_encryption_scope` - (Optional) The default encryption scope to use for this filesystem. Changing this forces a new resource to be created.
 - `group` - (Optional) Specifies the Object ID of the Azure Active Directory Group to make the owning group of the root path (i.e. `/`). Possible values also include `$superuser`.
 - `name` - (Required) The name of the Data Lake Gen2 File System which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.
 - `owner` - (Optional) Specifies the Object ID of the Azure Active Directory User to make the owning user of the root path (i.e. `/`). Possible values also include `$superuser`.
 - `properties` - (Optional) A mapping of Key to Base64-Encoded Values which should be assigned to this Data Lake Gen2 File System.
 ---
 `ace` block supports the following:
 - `id` - (Optional) Specifies the Object ID of the Azure Active Directory User or Group that the entry relates to. Only valid for `user` or `group` entries.
 - `permissions` - (Required) Specifies the permissions for the entry in `rwx` form. For example, `rwx` gives full permissions but `r--` only gives read permissions.
 - `scope` - (Optional) Specifies whether the ACE represents an `access` entry or a `default` entry. Default value is `access`.
 - `type` - (Required) Specifies the type of entry. Can be `user`, `group`, `mask` or `other`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Data Lake Gen2 File System.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Data Lake Gen2 File System.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Data Lake Gen2 File System.
 - `update` - (Defaults to 30 minutes) Used when updating the Data Lake Gen2 File System.
EOT
  default     = null
}

