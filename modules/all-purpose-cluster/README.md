# Databricks Classic Compute Cluster (All-Purpose Compute) Module

This module is responsible for creating and managing all-purpose compute clusters in Databricks hosted on AWS.

## Usage

```hcl
provider "databricks" {
  alias      = "mws"
  host       = local.computed_databricks_provider_host
  account_id = var.databricks_account_id
}

module "databricks_mws_workspace" {
  source = "./modules/workspace"

  providers = {
    databricks = databricks.mws
  }

  ...
}

provider "databricks" {
  alias      = "created_workspace"
  host       = module.databricks_mws_workspace.workspace_url
  account_id = var.databricks_account_id
}

module "all_purpose_cluster" {
  source = "git::ssh://git@github.com/UKHomeOffice/databricks-tf-modules.git//modules/all-purpose-cluster"

  providers = {
    databricks = databricks.created_workspace
  }

  resource_prefix = "dsa-dev"
  cluster_name    = "shared-etl"

  autoscale = {
    min_workers = 1
    max_workers = 6
  }

  autotermination_minutes = 30

  # Optional but recommended: attach a cluster policy you manage in Terraform
  policy_id = var.shared_cluster_policy_id

  aws_attributes = {
    availability         = "SPOT_WITH_FALLBACK"
    instance_profile_arn = var.instance_profile_arn
    ebs_volume_type      = "GENERAL_PURPOSE_SSD"
    ebs_volume_count     = 1
    ebs_volume_size      = 200
  }

  acl = [
    { 
      group_name = "data-engineering", 
      permission_level = "CAN_ATTACH_TO" 
    },
    { 
      group_name = "platform-admins",  
      permission_level = "CAN_MANAGE" 
    }
  ]

  custom_tags = {
    "team" = "data-platform"
    "env"  = "dev"
  }
}
```




https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster
