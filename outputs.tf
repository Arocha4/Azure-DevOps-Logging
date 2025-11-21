# ============================================================================
# Log Analytics Workspace Outputs
# ============================================================================

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.name
}

output "log_analytics_workspace_resource_id" {
  description = "The full resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.id
}

output "log_analytics_workspace_guid" {
  description = "The workspace GUID for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.workspace_id
  sensitive   = true
}

output "log_analytics_primary_shared_key" {
  description = "The primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.primary_shared_key
  sensitive   = true
}

output "log_analytics_secondary_shared_key" {
  description = "The secondary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.compliance.secondary_shared_key
  sensitive   = true
}

output "log_analytics_portal_url" {
  description = "Azure Portal URL for the Log Analytics Workspace"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_log_analytics_workspace.compliance.id}"
}

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.logging.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.logging.id
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.logging.location
}

# ============================================================================
# Key Vault Outputs
# ============================================================================

output "key_vault_id" {
  description = "The ID of the Key Vault (if enabled)"
  value       = var.enable_key_vault ? azurerm_key_vault.logging[0].id : null
}

output "key_vault_name" {
  description = "The name of the Key Vault (if enabled)"
  value       = var.enable_key_vault ? azurerm_key_vault.logging[0].name : null
}

output "key_vault_uri" {
  description = "The URI of the Key Vault (if enabled)"
  value       = var.enable_key_vault ? azurerm_key_vault.logging[0].vault_uri : null
}

# ============================================================================
# Storage Account Outputs
# ============================================================================

output "storage_account_name" {
  description = "The name of the storage account for log archives"
  value       = azurerm_storage_account.logs_archive.name
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.logs_archive.id
}

output "storage_container_name" {
  description = "The name of the storage container for archived logs"
  value       = azurerm_storage_container.logs_archive.name
}

# ============================================================================
# Azure DevOps Outputs
# ============================================================================

output "ado_audit_stream_configured" {
  description = "Whether ADO audit stream was configured"
  value       = var.enable_ado_audit_stream
}

output "ado_organization_name" {
  description = "The Azure DevOps organization name"
  value       = var.ado_organization_name
}

output "ado_audit_stream_name" {
  description = "The name of the ADO audit stream"
  value       = var.ado_audit_stream_name
}

# ============================================================================
# Monitoring Outputs
# ============================================================================

output "action_group_id" {
  description = "The ID of the action group for alerts (if enabled)"
  value       = var.enable_monitoring_alerts && length(var.alert_email_addresses) > 0 ? azurerm_monitor_action_group.compliance_alerts[0].id : null
}

output "monitoring_alerts_enabled" {
  description = "Whether monitoring alerts are enabled"
  value       = var.enable_monitoring_alerts
}

# ============================================================================
# Diagnostic Settings Outputs
# ============================================================================

output "monitored_subscriptions" {
  description = "List of subscription IDs with diagnostic settings configured"
  value       = var.monitored_subscription_ids
}

output "diagnostic_settings_name" {
  description = "The name used for diagnostic settings"
  value       = local.diag_setting_name
}

# ============================================================================
# Configuration Outputs
# ============================================================================

output "log_retention_days" {
  description = "Number of days logs are retained"
  value       = var.log_retention_days
}

output "resource_lock_enabled" {
  description = "Whether resource lock is enabled"
  value       = var.enable_resource_lock
}

output "lock_level" {
  description = "The level of resource lock applied"
  value       = var.enable_resource_lock ? var.lock_level : "None"
}

# ============================================================================
# Quick Access Queries
# ============================================================================

output "kusto_query_examples" {
  description = "Example KQL queries for common compliance scenarios"
  value = {
    recent_deployments = <<-QUERY
      AzureDevOpsAuditing
      | where OperationName contains "Deployment"
      | project TimeGenerated, ProjectName, ActorUPN, OperationName, Data
      | order by TimeGenerated desc
      | take 100
    QUERY

    failed_pipelines = <<-QUERY
      AzureDevOpsAuditing
      | where OperationName == "Release.DeploymentCompleted"
      | where Data has "Failed"
      | summarize FailureCount=count() by ProjectName, bin(TimeGenerated, 1h)
      | render timechart
    QUERY

    service_connection_usage = <<-QUERY
      AzureDevOpsAuditing
      | where OperationName == "Library.ServiceConnectionExecuted"
      | project TimeGenerated, ActorUPN, ProjectName, ServiceConnection=tostring(Data.ConnectionName)
      | order by TimeGenerated desc
    QUERY

    azure_deployments = <<-QUERY
      AzureActivity
      | where OperationNameValue contains "MICROSOFT.RESOURCES/DEPLOYMENTS"
      | project TimeGenerated, Caller, ResourceGroup, OperationNameValue, ActivityStatusValue
      | order by TimeGenerated desc
    QUERY
  }
}

# ============================================================================
# Next Steps Output
# ============================================================================

output "next_steps" {
  description = "Next steps after deployment"
  value = {
    step_1 = "Verify ADO audit stream: ${var.ado_organization_url}/_settings/organizationAudit"
    step_2 = "Access Log Analytics: ${azurerm_log_analytics_workspace.compliance.id}"
    step_3 = "Configure Workbooks for compliance dashboards"
    step_4 = "Add team members to RBAC roles"
    step_5 = "Test alert notifications"
    step_6 = "Schedule monthly compliance report reviews"
  }
}

# ============================================================================
# Summary Output
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    workspace_name            = azurerm_log_analytics_workspace.compliance.name
    workspace_location        = azurerm_log_analytics_workspace.compliance.location
    retention_days            = var.log_retention_days
    key_vault_enabled         = var.enable_key_vault
    ado_stream_enabled        = var.enable_ado_audit_stream
    monitored_subscriptions   = length(var.monitored_subscription_ids)
    alerts_enabled            = var.enable_monitoring_alerts
    resource_lock_enabled     = var.enable_resource_lock
    environment               = var.environment
  }
}