# main.tf
# Azure DevOps Audit Log Streaming Infrastructure
# This file contains all the core resources needed for streaming ADO audit logs

# Resource Group for the audit logging infrastructure
resource "azurerm_resource_group" "audit_logs" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    var.common_tags,
    {
      Purpose = "Azure DevOps Audit Logging"
    }
  )
}

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "ado_audit" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.audit_logs.location
  resource_group_name = azurerm_resource_group.audit_logs.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Component = "Log Analytics Workspace"
    }
  )
}

# Log Analytics Solution for Azure DevOps Auditing (optional but recommended)
resource "azurerm_log_analytics_solution" "ado_audit_solution" {
  count                 = var.enable_log_analytics_solution ? 1 : 0
  solution_name         = "AzureDevOpsAuditing"
  location              = azurerm_resource_group.audit_logs.location
  resource_group_name   = azurerm_resource_group.audit_logs.name
  workspace_resource_id = azurerm_log_analytics_workspace.ado_audit.id
  workspace_name        = azurerm_log_analytics_workspace.ado_audit.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureDevOpsAuditing"
  }

  tags = var.common_tags
}

# Storage Account for long-term audit log retention (optional backup)
resource "azurerm_storage_account" "audit_backup" {
  count                    = var.enable_storage_backup ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.audit_logs.name
  location                 = azurerm_resource_group.audit_logs.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 365
    }
  }

  tags = merge(
    var.common_tags,
    {
      Component = "Audit Log Backup Storage"
    }
  )
}

# Storage Container for audit logs
resource "azurerm_storage_container" "audit_logs" {
  count                 = var.enable_storage_backup ? 1 : 0
  name                  = "ado-audit-logs"
  storage_account_name  = azurerm_storage_account.audit_backup[0].name
  container_access_type = "private"
}

# Diagnostic Settings to export Log Analytics data to Storage (for compliance)
resource "azurerm_monitor_diagnostic_setting" "log_analytics_diagnostics" {
  count                      = var.enable_storage_backup ? 1 : 0
  name                       = "ado-audit-diagnostics"
  target_resource_id         = azurerm_log_analytics_workspace.ado_audit.id
  storage_account_id         = azurerm_storage_account.audit_backup[0].id

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Action Group for alerts (optional)
resource "azurerm_monitor_action_group" "audit_alerts" {
  count               = var.enable_alerting ? 1 : 0
  name                = "ado-audit-alerts"
  resource_group_name = azurerm_resource_group.audit_logs.name
  short_name          = "adoaudit"

  email_receiver {
    name                    = "SecurityTeam"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }

  tags = var.common_tags
}

# Scheduled Query Alert for suspicious activities (example)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_privilege_changes" {
  count               = var.enable_alerting ? 1 : 0
  name                = "ado-high-privilege-changes"
  resource_group_name = azurerm_resource_group.audit_logs.name
  location            = azurerm_resource_group.audit_logs.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_log_analytics_workspace.ado_audit.id]
  severity             = 2
  
  criteria {
    query                   = <<-QUERY
      AzureDevOpsAuditing
      | where CategoryDisplayName == "Permissions"
      | where OperationName in ("Security.ModifyPermission", "Security.RemovePermission")
      | where Data has "Allow"
      | summarize count() by OperationName, ActorDisplayName, ScopeDisplayName
      | where count_ > 5
    QUERY
    time_aggregation_method = "Count"
    threshold               = 1.0
    operator                = "GreaterThanOrEqual"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = false
  workspace_alerts_storage_enabled = false
  description                      = "Alert when multiple high-privilege changes occur within 5 minutes"
  display_name                     = "ADO High Privilege Changes"
  enabled                          = true
  skip_query_validation            = false

  action {
    action_groups = [azurerm_monitor_action_group.audit_alerts[0].id]
  }

  tags = var.common_tags
}

# Key Vault for storing sensitive information (workspace keys)
resource "azurerm_key_vault" "audit_secrets" {
  count                       = var.enable_key_vault ? 1 : 0
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.audit_logs.location
  resource_group_name         = azurerm_resource_group.audit_logs.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  sku_name                    = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = var.key_vault_network_default_action
  }

  tags = var.common_tags
}

# Store Log Analytics Workspace ID in Key Vault
resource "azurerm_key_vault_secret" "workspace_id" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "log-analytics-workspace-id"
  value        = azurerm_log_analytics_workspace.ado_audit.workspace_id
  key_vault_id = azurerm_key_vault.audit_secrets[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Store Log Analytics Primary Key in Key Vault
resource "azurerm_key_vault_secret" "workspace_key" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "log-analytics-workspace-key"
  value        = azurerm_log_analytics_workspace.ado_audit.primary_shared_key
  key_vault_id = azurerm_key_vault.audit_secrets[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Key Vault Access Policy for Terraform Service Principal
resource "azurerm_key_vault_access_policy" "terraform" {
  count        = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.audit_secrets[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}
