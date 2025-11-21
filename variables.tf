# variables.tf
# Variable definitions for Azure DevOps Audit Logging Infrastructure

# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group for audit logging infrastructure"
  type        = string
  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "centralus",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "australiaeast", "southeastasia", "japaneast"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

# Log Analytics Configuration
variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{4,63}$", var.log_analytics_workspace_name))
    error_message = "Workspace name must be 4-63 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerGB2018", "PerNode", "Premium", "Standalone", "Standard"], var.log_analytics_sku)
    error_message = "Invalid Log Analytics SKU."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics (30-730 days, 365 recommended for compliance)"
  type        = number
  default     = 365
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "enable_log_analytics_solution" {
  description = "Enable Azure DevOps Auditing solution in Log Analytics"
  type        = bool
  default     = true
}

# Storage Account Configuration
variable "enable_storage_backup" {
  description = "Enable storage account for long-term audit log backup"
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Name of the storage account for audit log backup (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

# Key Vault Configuration
variable "enable_key_vault" {
  description = "Enable Key Vault to store Log Analytics credentials securely"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique, 3-24 alphanumeric and hyphens)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters, start with letter, and contain only alphanumeric characters and hyphens."
  }
}

variable "key_vault_network_default_action" {
  description = "Default network action for Key Vault (Allow or Deny)"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "Key Vault network default action must be either 'Allow' or 'Deny'."
  }
}

# Alerting Configuration
variable "enable_alerting" {
  description = "Enable monitoring alerts for suspicious audit activities"
  type        = bool
  default     = false
}

variable "alert_email_address" {
  description = "Email address for audit alert notifications"
  type        = string
  default     = ""
  validation {
    condition     = var.alert_email_address == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email_address))
    error_message = "Must be a valid email address or empty string."
  }
}

# Tagging Configuration
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Production"
    Project     = "ADO-Audit-Logging"
  }
}

# Azure DevOps Configuration (for reference/documentation)
variable "azdo_organization_name" {
  description = "Azure DevOps organization name (for documentation purposes, not used in deployment)"
  type        = string
  default     = ""
}

variable "azdo_organization_url" {
  description = "Azure DevOps organization URL (for documentation purposes)"
  type        = string
  default     = ""
}
