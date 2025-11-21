# Azure DevOps Audit Logging Infrastructure - Terraform Deployment Guide

## Overview

This Terraform configuration deploys the infrastructure required to stream Azure DevOps audit logs to Azure Monitor Log Analytics workspace with 365-day retention.

### What This Deploys

- **Log Analytics Workspace**: Centralized logging with 365-day retention
- **Storage Account** (optional): Long-term backup storage for audit logs
- **Key Vault** (optional): Secure storage for Log Analytics credentials
- **Monitoring Alerts** (optional): Alerts for suspicious activities
- **Diagnostic Settings**: Compliance and backup configurations

---

## Prerequisites

### Required Tools

1. **Terraform** (v1.5.0 or later)
   ```bash
   # Download from: https://www.terraform.io/downloads
   # Verify installation:
   terraform version
   ```

2. **Azure CLI** (v2.50.0 or later)
   ```bash
   # Download from: https://docs.microsoft.com/cli/azure/install-azure-cli
   # Verify installation:
   az version
   ```

3. **Azure Subscription** with appropriate permissions:
   - Contributor or Owner role on the subscription
   - Ability to create Resource Groups, Log Analytics, Storage, Key Vault

4. **Azure DevOps Organization** with:
   - Organization Administrator access
   - Auditing feature enabled (requires Azure DevOps Services)

---

## Pre-Deployment Steps

### Step 1: Authenticate to Azure

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify current subscription
az account show
```

### Step 2: Clone or Download Terraform Files

Ensure you have all the following files in your working directory:
- `main.tf`
- `variables.tf`
- `provider.tf`
- `outputs.tf`
- `terraform.auto.tfvars`
- `README.md` (this file)

### Step 3: Update Configuration Variables

Edit `terraform.auto.tfvars` and update these **CRITICAL** values:

```hcl
# MUST BE GLOBALLY UNIQUE - Update these with your organization prefix
storage_account_name = "stadoauditprod001"  # Change to: st<yourorg>auditprod001
key_vault_name       = "kv-ado-audit-prod"  # Change to: kv-<yourorg>-audit-prod

# Update if needed
resource_group_name          = "rg-ado-audit-logs-prod"
log_analytics_workspace_name = "law-ado-audit-prod"
location                     = "eastus"  # Change to your preferred region

# Enable alerting if desired
enable_alerting     = false
alert_email_address = ""  # Add email if enabling alerts

# Add your Azure DevOps organization details (optional, for documentation)
azdo_organization_name = "your-org-name"
azdo_organization_url  = "https://dev.azure.com/your-org-name"
```

---

## Deployment Process (Hybrid Approach)

### Method 1: Manual Deployment (Recommended for Learning)

#### Step 1: Initialize Terraform

```bash
# Navigate to the directory containing the .tf files
cd /path/to/terraform/files

# Initialize Terraform (downloads required providers)
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
...
Terraform has been successfully initialized!
```

#### Step 2: Validate Configuration

```bash
# Validate the Terraform configuration
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

#### Step 3: Review Planned Changes

```bash
# Generate and review the execution plan
terraform plan -out=tfplan
```

**Review the output carefully:**
- Check that resources will be created in the correct subscription
- Verify resource names match your requirements
- Confirm the location is correct
- Note the estimated costs (if displayed)

#### Step 4: Apply Configuration

```bash
# Apply the configuration to create resources
terraform apply tfplan
```

**You'll see:**
- Progress as each resource is created
- Final output with important information

**Save the outputs!** They contain critical information needed for Azure DevOps configuration.

#### Step 5: Retrieve Sensitive Outputs

```bash
# Get the Log Analytics Workspace Key (needed for ADO configuration)
terraform output -raw log_analytics_primary_shared_key

# Save this key securely - you'll need it for Azure DevOps configuration
```

---

### Method 2: Automated Deployment Script

Create a deployment script for repeatable deployments:

```bash
#!/bin/bash
# deploy-ado-audit.sh

set -e  # Exit on error

echo "=========================================="
echo "Azure DevOps Audit Logging Deployment"
echo "=========================================="

# Step 1: Azure Login
echo "Step 1: Authenticating to Azure..."
az login

# Step 2: Set Subscription
read -p "Enter your Azure Subscription ID: " SUBSCRIPTION_ID
az account set --subscription "$SUBSCRIPTION_ID"
echo "Using subscription: $(az account show --query name -o tsv)"

# Step 3: Initialize Terraform
echo "Step 2: Initializing Terraform..."
terraform init

# Step 4: Validate
echo "Step 3: Validating configuration..."
terraform validate

# Step 5: Plan
echo "Step 4: Creating execution plan..."
terraform plan -out=tfplan

# Step 6: Confirmation
read -p "Do you want to apply this plan? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 7: Apply
echo "Step 5: Applying configuration..."
terraform apply tfplan

# Step 8: Display outputs
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
terraform output

# Step 9: Save sensitive outputs to a secure file
echo ""
echo "Saving sensitive outputs..."
terraform output -raw log_analytics_primary_shared_key > .workspace_key.txt
chmod 600 .workspace_key.txt
echo "Workspace key saved to .workspace_key.txt (secure permissions applied)"

echo ""
echo "Next steps:"
echo "1. Configure Azure DevOps audit streaming (see instructions below)"
echo "2. Wait 24-48 hours for initial data"
echo "3. Verify logs in Log Analytics workspace"
echo ""
terraform output -raw ado_configuration_instructions
```

Make the script executable and run it:

```bash
chmod +x deploy-ado-audit.sh
./deploy-ado-audit.sh
```

---

## Post-Deployment: Configure Azure DevOps

### Step 1: Enable Auditing in Azure DevOps

1. Navigate to your Azure DevOps organization: `https://dev.azure.com/YOUR_ORG`
2. Click **Organization Settings** (bottom left)
3. Under **Security**, click **Policies**
4. Enable **"Log Audit Events"**
5. Click **Save**

### Step 2: Configure Audit Stream to Azure Monitor

1. In **Organization Settings**, click **Auditing** (under Security)
2. Click the **Streams** tab
3. Click **"+ New stream"**
4. Select **"Azure Monitor Logs"** as the destination
5. Enter the connection details:

   ```
   Workspace ID: [Get from: terraform output log_analytics_workspace_id]
   Workspace Key: [Get from: terraform output -raw log_analytics_primary_shared_key]
   ```

6. Click **Save**

### Step 3: Verify Stream Configuration

1. The stream should show as "Connected"
2. Wait 24-48 hours for initial data population
3. Check for any error messages

---

## Verification and Testing

### Verify Log Analytics Workspace

```bash
# Get workspace details
az monitor log-analytics workspace show \
  --resource-group rg-ado-audit-logs-prod \
  --workspace-name law-ado-audit-prod \
  --query "{Name:name, RetentionDays:retentionInDays, Location:location}" \
  --output table
```

### Query Audit Logs (After 24-48 Hours)

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to your Log Analytics workspace
3. Click **Logs** in the left menu
4. Run this KQL query:

```kql
AzureDevOpsAuditing
| where TimeGenerated > ago(7d)
| summarize Count=count() by OperationName, bin(TimeGenerated, 1d)
| order by TimeGenerated desc
```

### Sample Queries

**View recent permission changes:**
```kql
AzureDevOpsAuditing
| where TimeGenerated > ago(24h)
| where CategoryDisplayName == "Permissions"
| project TimeGenerated, ActorDisplayName, OperationName, ScopeDisplayName, Data
| order by TimeGenerated desc
```

**Monitor project creation:**
```kql
AzureDevOpsAuditing
| where OperationName == "Project.Create"
| project TimeGenerated, ActorDisplayName, ProjectName=Data.ProjectName
| order by TimeGenerated desc
```

**Track administrative actions:**
```kql
AzureDevOpsAuditing
| where CategoryDisplayName in ("Permissions", "Auditing", "Policy")
| summarize count() by ActorDisplayName, OperationName
| order by count_ desc
```

---

## Common Issues and Troubleshooting

### Issue 1: "Workspace name already exists"

**Solution:**
```bash
# Update the workspace name in terraform.auto.tfvars
log_analytics_workspace_name = "law-ado-audit-prod-v2"

# Re-run terraform apply
terraform apply
```

### Issue 2: "Storage account name not globally unique"

**Solution:**
```bash
# Update storage account name with your unique identifier
storage_account_name = "stadoaudit<yourorg><random>"

# Re-run terraform apply
terraform apply
```

### Issue 3: No data appearing in Log Analytics

**Check:**
1. Verify audit stream is connected in Azure DevOps
2. Wait 24-48 hours for initial data
3. Verify the Workspace ID and Key are correct
4. Check audit stream status for errors

### Issue 4: Authentication failures

**Solution:**
```bash
# Re-authenticate to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

---

## Cost Estimation

Approximate monthly costs (East US region):

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| Log Analytics Workspace | Per GB ingestion + 365-day retention | $50-200/month* |
| Storage Account | GRS, 1TB/month | $25-50/month |
| Key Vault | Standard tier | $1-5/month |
| **Total Estimated** | | **$76-255/month** |

*Costs vary based on data ingestion volume (typical: 1-5GB/month for medium-sized organizations)

### Cost Optimization Tips

1. Start with 90-day retention, increase if needed
2. Disable storage backup if not required for compliance
3. Use commitment tiers for Log Analytics if ingestion >100GB/month
4. Monitor data ingestion patterns

---

## Security Best Practices

### 1. Protect Terraform State

**Option A: Azure Storage Backend**

Add to `provider.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique>"
    container_name       = "tfstate"
    key                  = "ado-audit-logging.tfstate"
  }
}
```

**Option B: Terraform Cloud**
```hcl
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "ado-audit-logging"
    }
  }
}
```

### 2. Secure Workspace Keys

- Never commit `.workspace_key.txt` to version control
- Add to `.gitignore`:
  ```
  .workspace_key.txt
  terraform.tfstate*
  .terraform/
  *.tfplan
  ```

### 3. Use Service Principal for Automation

```bash
# Create service principal
az ad sp create-for-rbac --name "sp-ado-audit-terraform" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Use in CI/CD:
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

### 4. Enable Key Vault for Production

In `terraform.auto.tfvars`:
```hcl
enable_key_vault                 = true
key_vault_network_default_action = "Deny"
```

Then configure Key Vault firewall to allow specific IPs.

---

## Maintenance and Updates

### Update Retention Period

```bash
# Edit terraform.auto.tfvars
log_retention_days = 730  # Change to desired value (30-730)

# Apply changes
terraform plan
terraform apply
```

### Enable Alerting After Initial Deployment

```bash
# Edit terraform.auto.tfvars
enable_alerting     = true
alert_email_address = "security-team@company.com"

# Apply changes
terraform apply
```

### Destroy Resources (Use with Caution!)

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**WARNING:** This will permanently delete all audit logs unless backed up to storage!

---

## CI/CD Integration

### Azure DevOps Pipeline Example

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - terraform/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-secrets  # Contains ARM_* variables

stages:
- stage: Plan
  jobs:
  - job: TerraformPlan
    steps:
    - task: TerraformInstaller@0
      inputs:
        terraformVersion: '1.5.0'
    
    - task: TerraformTaskV4@4
      inputs:
        command: 'init'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        backendServiceArm: 'Azure-Subscription'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate123'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'ado-audit-logging.tfstate'
    
    - task: TerraformTaskV4@4
      inputs:
        command: 'plan'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        environmentServiceNameAzureRM: 'Azure-Subscription'

- stage: Apply
  dependsOn: Plan
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: TerraformApply
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: TerraformTaskV4@4
            inputs:
              command: 'apply'
              workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
              environmentServiceNameAzureRM: 'Azure-Subscription'
```

---

## Support and Additional Resources

### Official Documentation

- [Azure DevOps Auditing](https://docs.microsoft.com/azure/devops/organizations/audit/azure-devops-auditing)
- [Azure Monitor Logs](https://docs.microsoft.com/azure/azure-monitor/logs/data-platform-logs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Useful Commands Reference

```bash
# Show all outputs
terraform output

# Show specific output (non-sensitive)
terraform output log_analytics_workspace_id

# Show sensitive output (e.g., workspace key)
terraform output -raw log_analytics_primary_shared_key

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources in state
terraform state list

# Import existing resource
terraform import azurerm_resource_group.audit_logs /subscriptions/SUB_ID/resourceGroups/RG_NAME
```

### Getting Help

If you encounter issues:

1. Check the error message carefully
2. Review the troubleshooting section above
3. Search for the error in [Terraform Azure Provider Issues](https://github.com/hashicorp/terraform-provider-azurerm/issues)
4. Contact your Azure or DevOps administrator
5. Review Azure Portal for resource creation status

---

## Checklist for Junior Engineers

Before deployment:
- [ ] Azure CLI installed and authenticated
- [ ] Terraform installed (v1.5.0+)
- [ ] Subscription permissions verified
- [ ] `terraform.auto.tfvars` updated with unique names
- [ ] Azure DevOps organization identified
- [ ] Cost estimates reviewed and approved

After deployment:
- [ ] Resources created successfully in Azure Portal
- [ ] Outputs saved securely
- [ ] Azure DevOps audit stream configured
- [ ] Verification queries run (after 24-48 hours)
- [ ] Documentation updated with actual values
- [ ] Team notified of new audit logging

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2024-11-21 | 1.0.0 | Initial release |

---

## License and Compliance

This infrastructure configuration is designed to meet common compliance requirements:
- **365-day log retention** (SOC 2, ISO 27001, HIPAA)
- **Immutable audit logs** (GDPR, PCI-DSS)
- **Encrypted storage** (All data encrypted at rest)
- **Access controls** (Key Vault, RBAC)

Review your organization's specific compliance requirements before deployment.

---

**End of README**
