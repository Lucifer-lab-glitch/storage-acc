#  Toggle to Enable Storage Queues
variable "enable_storage_queues" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Storage Queue provisioning."
}

#  Toggle for Existing or New Storage Account
variable "use_existing_storage_account" {
  type        = bool
  default     = false
  description = "Set to `true` if using an existing Storage Account instead of creating a new one."
}

 #Existing Storage Account ID (If using an existing one)
variable "existing_storage_account_name" {
  type        = string
  default     = null
  description = "The name of the existing Storage Account if using an existing one."
}

# Existing Storage Account ID (Used for Queue Properties)
variable "existing_storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the existing Storage Account if using an existing one."
}

#  Storage Queues Configuration
variable "queues" {
  type = map(object({
    name     = string
    metadata = optional(map(string), {})

    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
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

    logging = optional(object({
      delete                = optional(bool, false)
      read                  = optional(bool, false)
      write                 = optional(bool, false)
      version               = optional(string, "1.0")
      retention_policy_days = optional(number, 7)
    }))

    timeouts = optional(object({
      create = optional(string, "30m")
      delete = optional(string, "30m")
      read   = optional(string, "5m")
      update = optional(string, "30m")
    }))
  }))

  default     = {}
  description = <<EOT
Configuration for Azure Storage Queues.

- `name` (Required) - Storage Queue Name.
- `metadata` (Optional) - Key-Value metadata.
- `cors_rules` (Optional) - Configure Cross-Origin Resource Sharing (CORS).
- `role_assignments` (Optional) - RBAC permissions.
- `logging` (Optional) - Configure logging settings.
- `timeouts` (Optional) - Custom timeout durations.

Example Usage:
```terraform
enable_storage_queues = true
queues = {
  "example-queue" = {
    name     = "example-queue"
    metadata = { "env" = "prod" }

    cors_rules = [{
      allowed_headers    = ["x-ms-meta-*"]
      allowed_methods    = ["GET", "POST", "OPTIONS"]
      allowed_origins    = ["https://example.com"]
      exposed_headers    = ["x-ms-meta-*"]
      max_age_in_seconds = 3600
    }]

    role_assignments = {
      "admin" = {
        role_definition_id_or_name = "Storage Queue Data Contributor"
        principal_id               = "00000000-0000-0000-0000-000000000000"
      }
    }

    logging = {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }
}
EOT
}


variable "queue_properties" {
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
Configuration block for Storage Queue Properties.

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