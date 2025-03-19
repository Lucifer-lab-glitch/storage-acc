#  Enable or Disable Storage Tables
variable "enable_storage_tables" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Storage Table provisioning."
}

# Use an Existing or New Storage Account
variable "use_existing_storage_account" {
  type        = bool
  default     = false
  description = "Set to `true` if using an existing Storage Account instead of creating a new one."
}

# Existing Storage Account Name
variable "existing_storage_account_name" {
  type        = string
  default     = null
  description = "The name of the existing Storage Account if using an existing one."
}

# Existing Storage Account ID (Used for Table Properties)
variable "existing_storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the existing Storage Account if using an existing one."
}

# 🔹 Storage Tables Configuration
variable "tables" {
  type = map(object({
    name     = string
    metadata = optional(map(string), {})

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

    timeouts = optional(object({
      create = optional(string, "30m")
      delete = optional(string, "30m")
      read   = optional(string, "5m")
      update = optional(string, "30m")
    }))
  }))

  default     = {}
  description = <<EOT
Configuration for Azure Storage Tables.

- **`name`** (Required): Name of the Storage Table.
- **`metadata`** (Optional): Key-Value metadata.
- **`role_assignments`** (Optional): Assign RBAC permissions.
- **`timeouts`** (Optional): Custom timeout durations.

**Example Usage:**
```terraform
enable_storage_tables = true
tables = {
  "example-table" = {
    name     = "example-table"
    metadata = { "env" = "prod" }

    role_assignments = {
      "admin" = {
        role_definition_id_or_name = "Storage Table Data Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }
  }
}
EOT
}