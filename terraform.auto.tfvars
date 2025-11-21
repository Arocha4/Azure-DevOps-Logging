# terraform.auto.tfvars
# Automatically loaded variable values for Azure DevOps Audit Logging Infrastructure
# IMPORTANT: Review and update these values before deployment

# Resource Group Configuration
resource_group_name = "rg-ado-audit-logs-prod"
location            = "eastus"

# Log Analytics Workspace Configuration
log_analytics_workspace_name = "law-ado-audit-prod"
log_analytics_sku            = "PerGB2018"
log_retention_days           = 365

# Enable/Disable Log Analytics Solution
enable_log_analytics_solution = true

# Storage Account Configuration for Backup
enable_storage_backup = true
# NOTE: Storage account name must be globally unique (3-24 lowercase alphanumeric)
# Update this to include your organization identifier
storage_account_name = "stadoauditprod001"

# Key Vault Configuration
enable_key_vault = true
# NOTE: Key Vault name must be globally unique (3-24 alphanumeric and hyphens)
# Update this to include your organization identifier
key_vault_name                     = "kv-ado-audit-prod"
key_vault_network_default_action   = "Allow"

# Alerting Configuration
enable_alerting      = false
alert_email_address  = ""  # Update with your security team email if alerting is enabled

# Azure DevOps Organization Details (for documentation)
azdo_organization_name = ""  # e.g., "contoso"
azdo_organization_url  = ""  # e.g., "https://dev.azure.com/contoso"

# Common Resource Tags
common_tags = {
  Environment  = "Production"
  Project      = "ADO-Audit-Logging"
  ManagedBy    = "Terraform"
  CostCenter   = "IT-Security"
  Compliance   = "Required"
  Owner        = "Security-Team"
  Department   = "IT"
  CreatedDate  = "2024"
}
