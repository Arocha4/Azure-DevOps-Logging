# ============================================================================
# Azure Subscription Configuration
# ============================================================================

# Management subscription where Log Analytics will be deployed
management_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Application subscriptions to monitor (add all app team subscriptions)
monitored_subscription_ids = [
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy", # app1-dev-sub
  "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz", # app1-prod-sub
  # Add more subscriptions as needed
]

# ============================================================================
# Azure DevOps Configuration
# ============================================================================

ado_organization_url  = "https://dev.azure.com/yourorgname"
ado_organization_name = "yourorgname"

# IMPORTANT: Do not commit PAT token to source control
# Set via environment variable: export TF_VAR_ado_pat_token="your-pat-token"
# Or use Azure Key Vault reference in pipeline
# ado_pat_token = "" # Leave empty, set via environment variable

# ============================================================================
# Resource Configuration
# ============================================================================

location        = "eastus"
environment     = "prod"
resource_prefix = "compliance"

# ============================================================================
# Log Analytics Configuration
# ============================================================================

log_analytics_sku   = "PerGB2018"
log_retention_days  = 730 # 2 years for compliance
daily_quota_gb      = -1  # Unlimited, adjust based on budget

# ============================================================================
# Key Vault Configuration
# ============================================================================

enable_key_vault = true
key_vault_sku    = "standard"

# ============================================================================
# Audit Stream Configuration
# ============================================================================

enable_ado_audit_stream = true
ado_audit_stream_name   = "LogAnalytics-Compliance-Stream"

# ============================================================================
# Diagnostic Settings
# ============================================================================

enable_activity_logs = true

activity_log_categories = [
  "Administrative",
  "Security",
  "Policy",
  "Alert",
  "Recommendation",
  "ResourceHealth"
]

# ============================================================================
# RBAC Configuration
# ============================================================================

# Add Azure AD Object IDs for teams
# Get Object IDs: az ad group show --group "GroupName" --query id -o tsv

compliance_team_object_ids = [
  # "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", # Compliance Team Group
]

security_team_object_ids = [
  # "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", # Security Team Group
]

platform_team_object_ids = [
  # "cccccccc-cccc-cccc-cccc-cccccccccccc", # Platform Team Group
]

# ============================================================================
# Monitoring & Alerts
# ============================================================================

enable_monitoring_alerts = true

alert_email_addresses = [
  # "compliance-team@company.com",
  # "platform-team@company.com",
]

# ============================================================================
# Resource Protection
# ============================================================================

enable_resource_lock = true
lock_level           = "CanNotDelete"

# ============================================================================
# Tagging
# ============================================================================

tags = {
  ManagedBy   = "Terraform"
  Purpose     = "Compliance-Audit-Logging"
  Environment = "Production"
  CostCenter  = "Platform"
  Criticality = "High"
  Owner       = "Platform-Team"
  Compliance  = "Required"
}

additional_tags = {
  # Project     = "Compliance-Initiative-2024"
  # Department  = "IT-Operations"
}