# Azure-DevOps-Logging
# Azure DevOps Audit Logging - Terraform Configuration

This Terraform configuration deploys a centralized audit logging solution for Azure DevOps and Azure resource deployments.

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI >= 2.50.0
- Azure DevOps PAT token with Auditing (Read) permissions
- Appropriate Azure RBAC permissions (Contributor or Owner on target subscriptions)

## Features

- ✅ Centralized Log Analytics Workspace
- ✅ Azure DevOps audit stream configuration
- ✅ Activity log collection from multiple subscriptions
- ✅ Key Vault for secure credential storage
- ✅ RBAC configuration for compliance/security teams
- ✅ Automated alerts for failed deployments
- ✅ 2-year log retention for compliance
- ✅ Resource locks for protection
- ✅ Storage account for long-term archive

## Quick Start

### 1. Clone and Configure
```bash
git clone <repository>
cd terraform-ado-logging
```

### 2. Update Variables

Edit `terraform.auto.tfvars` with your values:
- Update subscription IDs
- Update ADO organization URL
- Update email addresses for alerts
- Update Azure AD object IDs for RBAC

### 3. Set Sensitive Variables
```bash
# Set PAT token via environment variable
export TF_VAR_ado_pat_token="your-pat-token-here"

# Or use Azure Key Vault in CI/CD
```

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Plan Deployment
```bash
terraform plan -out=tfplan
```

### 6. Apply Configuration
```bash
terraform apply tfplan
```

## File Structure
```
.
├── provider.tf              # Provider configurations
├── variables.tf             # Variable definitions
├── terraform.auto.tfvars    # Variable values
├── locals.tf                # Local values
├── main.tf                  # Main resource definitions
├── outputs.tf               # Output definitions
└── README.md                # This file
```

## Post-Deployment Steps

1. **Verify ADO Audit Stream**
```bash
   # Check stream status in ADO
   https://dev.azure.com/{org}/_settings/organizationAudit
```

2. **Test Log Ingestion**
```kql
   AzureDevOpsAuditing
   | where TimeGenerated > ago(1h)
   | take 10
```

3. **Configure Azure Workbooks**
   - Create compliance dashboard
   - Set up monthly reports

4. **Add Team Members**
   - Update object IDs in terraform.auto.tfvars
   - Re-run terraform apply

## Maintenance

### Update Retention Policy
```bash
# Edit variables.tf
log_retention_days = 365

# Apply changes
terraform apply
```

### Add More Subscriptions
```bash
# Edit terraform.auto.tfvars
monitored_subscription_ids = [
  "existing-sub-1",
  "existing-sub-2",
  "new-sub-3"  # Add new subscription
]

# Apply changes
terraform apply
```

### Rotate PAT Token
```bash
# Generate new PAT in ADO
export TF_VAR_ado_pat_token="new-pat-token"

# Recreate audit stream
terraform taint null_resource.ado_audit_stream[0]
terraform apply
```

## Cost Estimation

- Log Analytics: ~$2.76/GB ingested
- Expected monthly cost: $100-300 (small-medium org)
- Storage archive: ~$0.01/GB/month

## Troubleshooting

### ADO Audit Stream Not Working

1. Verify auditing is enabled in ADO organization
2. Check PAT token has correct permissions
3. Verify workspace ID and key are correct

### No Logs Appearing

1. Check diagnostic settings are deployed
2. Verify subscription IDs are correct
3. Wait 5-10 minutes for initial ingestion

### Permission Errors

1. Verify you have Owner/Contributor on subscriptions
2. Check Azure AD object IDs are correct
3. Ensure PAT token hasn't expired

## Security Considerations

- ⚠️ Never commit PAT tokens to source control
- ⚠️ Use environment variables or Key Vault references
- ⚠️ Enable soft delete on Key Vault
- ⚠️ Restrict Key Vault network access
- ⚠️ Regular PAT token rotation
- ⚠️ Monitor for unauthorized access

## Compliance

This configuration meets the following requirements:
- ✅ All deployment activities logged
- ✅ 2-year retention for compliance
- ✅ Immutable audit trail
- ✅ Role-based access control
- ✅ Centralized monitoring

## Support

For issues or questions:
1. Check Terraform output messages
2. Review Azure Activity Log
3. Contact platform team

## License

Internal use only - [Your Organization]