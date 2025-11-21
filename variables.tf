# ============================================================================
# Azure Subscription Variables
# ============================================================================

variable "management_subscription_id" {
  description = "The subscription ID for the management/platform subscription where Log Analytics will be deployed"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.management_subscription_id))
    error_message = "The subscription ID must be a valid GUID format."
  }
}

variable "monitored_subscription_ids" {
  description = "List of subscription IDs to configure diagnostic settings for (application subscriptions)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for sub_id in var.monitored_subscription_ids :
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", sub_id))
    ])
    error_message = "All subscription IDs must be valid GUID format."
  }
}

# ============================================================================
# Azure DevOps Variables
# ============================================================================

variable "ado_organization_url" {
  description = "Azure DevOps Organization URL (e.g., https://dev.azure.com/myorg)"
  type        = string

  validation {
    condition     = can(regex("^https://dev\\.azure\\.com/[a-zA-Z0-9-]+$", var.ado_organization_url))
    error_message = "ADO organization URL must be in format: https://dev.azure.com/orgname"
  }
}

variable "ado_organization_name" {
  description = "Azure DevOps Organization name (without URL)"
  type        = string
}

variable "ado_pat_token" {
  description = "Azure DevOps Personal Access Token with Auditing (Read) permissions"
  type        = string
  sensitive   = true
}

# ============================================================================
# Resource Configuration Variables
# ============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = contains(["eastus", "eastus2", "westus2", "westus3", "centralus", "northeurope", "westeurope", "uksouth", "southeastasia"], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "dev", "test", "staging", "uat"], var.environment)
    error_message = "Environment must be one of: prod, dev, test, staging, uat."
  }
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "compliance"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 3-10 lowercase alphanumeric characters."
  }
}

# ============================================================================
# Log Analytics Configuration
# ============================================================================

variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.log_analytics_sku)
    error_message = "SKU must be either PerGB2018 or CapacityReservation."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics (30-730 days)"
  type        = number
  default     = 730

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Retention days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb >= 1
    error_message = "Daily quota must be -1 (unlimited) or >= 1 GB."
  }
}

# ============================================================================
# Key Vault Configuration
# ============================================================================

variable "enable_key_vault" {
  description = "Enable Key Vault creation to store workspace keys"
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be either standard or premium."
  }
}

# ============================================================================
# Audit Stream Configuration
# ============================================================================

variable "enable_ado_audit_stream" {
  description = "Enable automatic creation of ADO audit stream to Log Analytics"
  type        = bool
  default     = true
}

variable "ado_audit_stream_name" {
  description = "Name for the Azure DevOps audit stream"
  type        = string
  default     = "LogAnalytics-Compliance-Stream"
}

# ============================================================================
# Diagnostic Settings Configuration
# ============================================================================

variable "enable_activity_logs" {
  description = "Enable Azure Activity Log collection"
  type        = bool
  default     = true
}

variable "activity_log_categories" {
  description = "Activity log categories to enable"
  type        = list(string)
  default = [
    "Administrative",
    "Security",
    "Policy",
    "Alert",
    "Recommendation",
    "ResourceHealth"
  ]
}

# ============================================================================
# RBAC Configuration
# ============================================================================

variable "compliance_team_object_ids" {
  description = "List of Azure AD object IDs for compliance team (Log Analytics Reader)"
  type        = list(string)
  default     = []
}

variable "security_team_object_ids" {
  description = "List of Azure AD object IDs for security team (Log Analytics Reader)"
  type        = list(string)
  default     = []
}

variable "platform_team_object_ids" {
  description = "List of Azure AD object IDs for platform team (Log Analytics Contributor)"
  type        = list(string)
  default     = []
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Purpose     = "Compliance-Audit-Logging"
    CostCenter  = "Platform"
    Criticality = "High"
  }
}

variable "additional_tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Advanced Configuration
# ============================================================================

variable "enable_monitoring_alerts" {
  description = "Enable default monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_email_addresses" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "enable_resource_lock" {
  description = "Enable resource lock on Log Analytics workspace"
  type        = bool
  default     = true
}

variable "lock_level" {
  description = "Lock level (CanNotDelete or ReadOnly)"
  type        = string
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be either CanNotDelete or ReadOnly."
  }
}