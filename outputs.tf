# outputs.tf
# Output values for Azure DevOps Audit Logging Infrastructure

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.audit_logs.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.audit_logs.location
}

output "resource_group_id" {
  description = "Resource ID of the resource group"
  value       = azurerm_resource_group.audit_logs.id
}

# Log Analytics Workspace Outputs
output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.ado_audit.name
}

output "log_analytics_workspace_id" {
  description = "Workspace ID for Azure DevOps audit streaming configuration"
  value       = azurerm_log_analytics_workspace.ado_audit.workspace_id
  sensitive   = false
}

output "log_analytics_workspace_resource_id" {
  description = "Azure Resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.ado_audit.id
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics workspace (SENSITIVE - use for ADO audit stream configuration)"
  value       = azurerm_log_analytics_workspace.ado_audit.primary_shared_key
  sensitive   = true
}

output "log_analytics_retention_days" {
  description = "Retention period configured for Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.ado_audit.retention_in_days
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account for audit backup"
  value       = var.enable_storage_backup ? azurerm_storage_account.audit_backup[0].name : "Not deployed"
}

output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = var.enable_storage_backup ? azurerm_storage_account.audit_backup[0].id : "Not deployed"
}

output "storage_container_name" {
  description = "Name of the storage container for audit logs"
  value       = var.enable_storage_backup ? azurerm_storage_container.audit_logs[0].name : "Not deployed"
}

# Key Vault Outputs
output "key_vault_name" {
  description = "Name of the Key Vault storing credentials"
  value       = var.enable_key_vault ? azurerm_key_vault.audit_secrets[0].name : "Not deployed"
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.audit_secrets[0].vault_uri : "Not deployed"
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.audit_secrets[0].id : "Not deployed"
}

# Alert Configuration Outputs
output "action_group_name" {
  description = "Name of the monitoring action group"
  value       = var.enable_alerting ? azurerm_monitor_action_group.audit_alerts[0].name : "Not deployed"
}

output "action_group_id" {
  description = "Resource ID of the action group"
  value       = var.enable_alerting ? azurerm_monitor_action_group.audit_alerts[0].id : "Not deployed"
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the deployed configuration"
  value = {
    log_analytics_workspace = azurerm_log_analytics_workspace.ado_audit.name
    retention_days          = azurerm_log_analytics_workspace.ado_audit.retention_in_days
    storage_backup_enabled  = var.enable_storage_backup
    key_vault_enabled       = var.enable_key_vault
    alerting_enabled        = var.enable_alerting
    location                = azurerm_resource_group.audit_logs.location
  }
}

# Azure DevOps Configuration Instructions
output "ado_configuration_instructions" {
  description = "Instructions for configuring Azure DevOps audit streaming"
  value = <<-EOT
    ========================================
    Azure DevOps Audit Stream Configuration
    ========================================
    
    1. Navigate to Azure DevOps Organization Settings
    2. Go to Auditing > Streams
    3. Click "New stream"
    4. Select "Azure Monitor Logs"
    5. Enter the following details:
       - Workspace ID: ${azurerm_log_analytics_workspace.ado_audit.workspace_id}
       - Workspace Key: (Run: terraform output -raw log_analytics_primary_shared_key)
    
    6. Save the stream configuration
    7. Wait 24-48 hours for initial data population
    
    To verify logs are flowing, run this KQL query in Log Analytics:
    
    AzureDevOpsAuditing
    | where TimeGenerated > ago(7d)
    | summarize count() by OperationName
    | order by count_ desc
    
    For secure key retrieval from Key Vault (if enabled):
    az keyvault secret show --vault-name ${var.enable_key_vault ? azurerm_key_vault.audit_secrets[0].name : "KEY_VAULT_NAME"} --name log-analytics-workspace-key --query value -o tsv
    
    ========================================
  EOT
}

# Deployment Timestamp
output "deployment_timestamp" {
  description = "Timestamp of the deployment"
  value       = timestamp()
}
