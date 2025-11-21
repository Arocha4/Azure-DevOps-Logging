terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.12.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstateprod"
  #   container_name       = "tfstate"
  #   key                  = "ado-logging.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.management_subscription_id
}

provider "azuredevops" {
  org_service_url       = var.ado_organization_url
  personal_access_token = var.ado_pat_token
}

provider "azapi" {
  subscription_id = var.management_subscription_id
}