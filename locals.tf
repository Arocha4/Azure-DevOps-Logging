locals {
  # Naming conventions following Azure best practices
  resource_group_name = "rg-${var.resource_prefix}-logging-${var.environment}"
  
  workspace_name = "law-${var.resource_prefix}-audit-${var.environment}"
  
  key_vault_name = "kv-${var.resource_prefix}-${var.environment}-${substr(md5(var.management_subscription_id), 0, 6)}"
  
  storage_account_name = "st${var.resource_prefix}logs${var.environment}${substr(md5(var.management_subscription_id), 0, 4)}"

  # Merge tags
  common_tags = merge(
    var.tags,
    var.additional_tags,
    {
      Environment     = var.environment
      DeployedBy      = "Terraform"
      LastUpdated     = timestamp()
      WorkspaceRegion = var.location
    }
  )

  # ADO audit stream configuration
  ado_org_name = replace(var.ado_organization_url, "https://dev.azure.com/", "")

  # Diagnostic settings name
  diag_setting_name = "diag-to-law-${var.resource_prefix}"
}