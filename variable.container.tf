#  Enable or Disable Storage Containers
variable "enable_storage_containers" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Storage Container provisioning."
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

# Existing Storage Account ID (Used for Container Properties)
variable "existing_storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the existing Storage Account if using an existing one."
}

# 🔹 Storage Containers Configuration
variable "containers" {
  type = map(object({
    name                  = string
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})

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
Configuration for Azure Storage Containers.

- **`name`** (Required): Name of the Storage Container.
- **`container_access_type`** (Optional): Access level (`private`, `blob`, `container`).
- **`metadata`** (Optional): Key-Value metadata.
- **`role_assignments`** (Optional): Assign RBAC permissions.
- **`timeouts`** (Optional): Custom timeout durations.

**Example Usage:**
```terraform
enable_storage_containers = true
containers = {
  "example-container" = {
    name                  = "example-container"
    container_access_type = "blob"
    metadata              = { "env" = "prod" }

    role_assignments = {
      "admin" = {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }
  }
}
EOT
}