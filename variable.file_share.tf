# Enable or Disable File Shares
variable "enable_file_shares" {
  type        = bool
  default     = false
  description = "Set to `true` to enable File Share provisioning."
}


# Choose between Existing or New Storage Account
variable "use_existing_storage_account" {
  type        = bool
  default     = false
  description = "Set to `true` if using an existing Storage Account instead of creating a new one."
}

# Existing Storage Account ID (If using an existing one)
variable "existing_storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the existing Storage Account if using an existing one."
}

# File Shares Configuration
variable "shares" {
  type = map(object({
    name             = string
    quota            = number
    enabled_protocol = optional(string, "SMB")
    metadata         = optional(map(string), {})
    signed_identifiers = optional(list(object({
      id = string
      access_policy = optional(object({
        expiry_time = string
        permission  = string
        start_time  = string
      }))
    })), [])
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
Configuration block for Azure File Shares.

- `name` (Required) - The name of the file share.
- `quota` (Required) - The max size of the share (in GB).
- `enabled_protocol` (Optional) - Defaults to `SMB`. Can be `NFS` for Linux.
- `metadata` (Optional) - Key-value metadata pairs.
- `signed_identifiers` (Optional) - Configure access policies.
- `role_assignments` (Optional) - RBAC permissions for file shares.
- `timeouts` (Optional) - Custom timeout durations.

Example Usage:
```terraform
enable_file_shares = true
shares = {
  "example-share" = {
    name             = "example-share"
    quota            = 100
    enabled_protocol = "SMB"
    metadata         = { "env" = "prod" }
    signed_identifiers = [{
      id = "read-access"
      access_policy = {
        expiry_time = "2025-12-31T23:59:59Z"
        permission  = "r"
        start_time  = "2024-01-01T00:00:00Z"
      }
    }]
    role_assignments = {
      "admin" = {
        role_definition_id_or_name = "Storage File Data SMB Share Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }
  }
}
EOT
}


variable "share_properties" {
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])

    logging = optional(object({
      delete                = bool
      read                  = bool
      write                 = bool
      version               = string
      retention_policy_days = number
    }), null)
  })

  default     = null
  description = <<EOT
Configuration block for Storage share Properties.

- **`cors_rule`** (Optional): List of CORS rules applied to the storage queue.
  - `allowed_headers` - List of headers allowed in CORS.
  - `allowed_methods` - Allowed HTTP methods (`GET`, `POST`, etc.).
  - `allowed_origins` - List of allowed origin domains.
  - `exposed_headers` - Headers exposed to CORS clients.
  - `max_age_in_seconds` - Cache expiration time.

- **`logging`** (Optional): Configures logging settings for storage queue.
  - `delete` - Enable logging for delete operations.
  - `read` - Enable logging for read operations.
  - `write` - Enable logging for write operations.
  - `version` - Storage API version.
  - `retention_policy_days` - Number of days to retain logs.

**Example Usage**
```terraform
queue_properties = {
  cors_rule = [{
    allowed_headers    = ["*"]
    allowed_methods    = ["GET", "POST", "DELETE"]
    allowed_origins    = ["https://example.com"]
    exposed_headers    = ["x-ms-meta-data"]
    max_age_in_seconds = 3600
  }]
  logging = {
    delete                = true
    read                  = true
    write                 = true
    version               = "1.0"
    retention_policy_days = 7
  }
}
EOT
}