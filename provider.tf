# provider.tf
# Provider configuration and version constraints

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration for remote state storage
  # Uncomment and configure based on your organization's requirements
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatexxxxxx"
  #   container_name       = "tfstate"
  #   key                  = "ado-audit-logging.tfstate"
  # }
}

# Azure Provider configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  # Uncomment if using Service Principal authentication
  # subscription_id = var.azure_subscription_id
  # tenant_id       = var.azure_tenant_id
  # client_id       = var.azure_client_id
  # client_secret   = var.azure_client_secret
}

# Azure AD Provider (for future enhancements)
provider "azuread" {
  # tenant_id = var.azure_tenant_id
}
