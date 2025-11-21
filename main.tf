# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "logging" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# ============================================================================
# Log Analytics Workspace
# ============================================================================

resource "azurerm_log_analytics_workspace" "compliance" {
  name                = local.workspace_name
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_quota_gb

  tags = local.common_tags

  lifecycle {
    ignore_changes        = [tags["LastUpdated"]]
    prevent_destroy       = true
    create_before_destroy = true
  }
}

# ============================================================================
# Log Analytics Solutions
# ============================================================================

resource "azurerm_log_analytics_solution" "security" {
  solution_name         = "Security"
  location              = azurerm_resource_group.logging.location
  resource_group_name   = azurerm_resource_group.logging.name
  workspace_resource_id = azurerm_log_analytics_workspace.compliance.id
  workspace_name        = azurerm_log_analytics_workspace.compliance.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

resource "azurerm_log_analytics_solution" "updates" {
  solution_name         = "Updates"
  location              = azurerm_resource_group.logging.location
  resource_group_name   = azurerm_resource_group.logging.name
  workspace_resource_id = azurerm_log_analytics_workspace.compliance.id
  workspace_name        = azurerm_log_analytics_workspace.compliance.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# ============================================================================
# Key Vault for Storing Workspace Keys
# ============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "logging" {
  count = var.enable_key_vault ? 1 : 0

  name                        = local.key_vault_name
  location                    = azurerm_resource_group.logging.location
  resource_group_name         = azurerm_resource_group.logging.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  sku_name                    = var.key_vault_sku

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [] # Add your IP ranges if needed
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# Key Vault Access Policy for Current User/Service Principal
resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_key_vault ? 1 : 0

  key_vault_id = azurerm_key_vault.logging[0].id
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

# Store Log Analytics Workspace ID
resource "azurerm_key_vault_secret" "workspace_id" {
  count = var.enable_key_vault ? 1 : 0

  name         = "law-workspace-id"
  value        = azurerm_log_analytics_workspace.compliance.workspace_id
  key_vault_id = azurerm_key_vault.logging[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# Store Log Analytics Primary Shared Key
resource "azurerm_key_vault_secret" "workspace_key" {
  count = var.enable_key_vault ? 1 : 0

  name         = "law-workspace-primary-key"
  value        = azurerm_log_analytics_workspace.compliance.primary_shared_key
  key_vault_id = azurerm_key_vault.logging[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"], value]
  }
}

# ============================================================================
# Storage Account for Long-term Archive (Optional)
# ============================================================================

resource "azurerm_storage_account" "logs_archive" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.logging.name
  location                 = azurerm_resource_group.logging.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 365
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

resource "azurerm_storage_container" "logs_archive" {
  name                  = "audit-logs-archive"
  storage_account_name  = azurerm_storage_account.logs_archive.name
  container_access_type = "private"
}

# ============================================================================
# Azure Monitor Diagnostic Settings for Subscriptions
# ============================================================================

resource "azapi_resource" "subscription_diagnostic_settings" {
  for_each = toset(var.monitored_subscription_ids)

  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = local.diag_setting_name
  parent_id = "/subscriptions/${each.value}"

  body = jsonencode({
    properties = {
      workspaceId = azurerm_log_analytics_workspace.compliance.id
      logs = [
        for category in var.activity_log_categories : {
          category = category
          enabled  = true
          retentionPolicy = {
            enabled = false
            days    = 0
          }
        }
      ]
    }
  })

  depends_on = [azurerm_log_analytics_workspace.compliance]
}

# ============================================================================
# Azure DevOps Audit Stream Configuration
# ============================================================================

# Note: Azure DevOps audit streaming is configured via REST API
# This null_resource executes the API call using local-exec provisioner

resource "null_resource" "ado_audit_stream" {
  count = var.enable_ado_audit_stream ? 1 : 0

  triggers = {
    workspace_id   = azurerm_log_analytics_workspace.compliance.workspace_id
    workspace_key  = azurerm_log_analytics_workspace.compliance.primary_shared_key
    org_url        = var.ado_organization_url
    stream_name    = var.ado_audit_stream_name
    always_run     = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST \
        "${var.ado_organization_url}/_apis/audit/streams?api-version=7.1-preview.1" \
        -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n ':${var.ado_pat_token}' | base64)" \
        -d '{
          "consumerType": "AzureMonitorLogs",
          "consumerInputs": {
            "WorkspaceId": "${azurerm_log_analytics_workspace.compliance.workspace_id}",
            "SharedKey": "${azurerm_log_analytics_workspace.compliance.primary_shared_key}"
          },
          "displayName": "${var.ado_audit_stream_name}",
          "status": "enabled"
        }' || echo "Stream may already exist or ADO auditing not enabled"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [azurerm_log_analytics_workspace.compliance]
}

# ============================================================================
# RBAC Assignments
# ============================================================================

# Compliance Team - Log Analytics Reader
resource "azurerm_role_assignment" "compliance_team" {
  for_each = toset(var.compliance_team_object_ids)

  scope                = azurerm_log_analytics_workspace.compliance.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value
}

# Security Team - Log Analytics Reader
resource "azurerm_role_assignment" "security_team" {
  for_each = toset(var.security_team_object_ids)

  scope                = azurerm_log_analytics_workspace.compliance.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value
}

# Platform Team - Log Analytics Contributor
resource "azurerm_role_assignment" "platform_team" {
  for_each = toset(var.platform_team_object_ids)

  scope                = azurerm_log_analytics_workspace.compliance.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = each.value
}

# ============================================================================
# Action Group for Alerts
# ============================================================================

resource "azurerm_monitor_action_group" "compliance_alerts" {
  count = var.enable_monitoring_alerts && length(var.alert_email_addresses) > 0 ? 1 : 0

  name                = "ag-compliance-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.logging.name
  short_name          = "CompAlert"

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${index(var.alert_email_addresses, email_receiver.value)}"
      email_address = email_receiver.value
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# ============================================================================
# Scheduled Query Alert - Failed Deployments
# ============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_deployments" {
  count = var.enable_monitoring_alerts ? 1 : 0

  name                = "alert-failed-deployments-${var.environment}"
  resource_group_name = azurerm_resource_group.logging.name
  location            = azurerm_resource_group.logging.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.compliance.id]
  severity             = 2
  description          = "Alert when production deployments fail in Azure DevOps"

  criteria {
    query                   = <<-QUERY
      AzureDevOpsAuditing
      | where OperationName contains "Deployment"
      | where Data has "Failed" or Data has "PartiallySucceeded"
      | where Data contains "prod" or Data contains "production"
      | summarize FailureCount=count() by ProjectName, bin(TimeGenerated, 5m)
      | where FailureCount > 0
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = true
  workspace_alerts_storage_enabled = false

  dynamic "action" {
    for_each = var.enable_monitoring_alerts && length(var.alert_email_addresses) > 0 ? [1] : []
    content {
      action_groups = [azurerm_monitor_action_group.compliance_alerts[0].id]
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }

  depends_on = [
    azurerm_log_analytics_workspace.compliance,
    azurerm_monitor_action_group.compliance_alerts
  ]
}

# ============================================================================
# Scheduled Query Alert - High Data Ingestion
# ============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_ingestion" {
  count = var.enable_monitoring_alerts ? 1 : 0

  name                = "alert-high-data-ingestion-${var.environment}"
  resource_group_name = azurerm_resource_group.logging.name
  location            = azurerm_resource_group.logging.location

  evaluation_frequency = "PT1H"
  window_duration      = "P1D"
  scopes               = [azurerm_log_analytics_workspace.compliance.id]
  severity             = 3
  description          = "Alert when daily data ingestion exceeds expected threshold"

  criteria {
    query                   = <<-QUERY
      Usage
      | where IsBillable == true
      | summarize TotalGB = sum(Quantity) / 1000
      | where TotalGB > 100
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = true

  dynamic "action" {
    for_each = var.enable_monitoring_alerts && length(var.alert_email_addresses) > 0 ? [1] : []
    content {
      action_groups = [azurerm_monitor_action_group.compliance_alerts[0].id]
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# ============================================================================
# Resource Lock
# ============================================================================

resource "azurerm_management_lock" "workspace_lock" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "lock-${local.workspace_name}"
  scope      = azurerm_log_analytics_workspace.compliance.id
  lock_level = var.lock_level
  notes      = "Locked to prevent accidental deletion of compliance audit logs"

  depends_on = [azurerm_log_analytics_workspace.compliance]
}

# ============================================================================
# Data Collection Rule for Enhanced Filtering (Optional)
# ============================================================================

resource "azurerm_monitor_data_collection_rule" "ado_logs" {
  name                = "dcr-ado-audit-${var.environment}"
  resource_group_name = azurerm_resource_group.logging.name
  location            = azurerm_resource_group.logging.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.compliance.id
      name                  = "destination-log-analytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Table-AzureDevOpsAuditing"]
    destinations = ["destination-log-analytics"]
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}