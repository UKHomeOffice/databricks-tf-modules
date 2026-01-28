# Helpers so you can avoid hardcoding node type / runtime.
data "databricks_node_type" "default" {
  count      = var.node_type_id == null ? 1 : 0
  local_disk = true
}

data "databricks_spark_version" "default" {
  count             = var.spark_version == null ? 1 : 0
  long_term_support = true
}

locals {
  effective_node_type_id  = coalesce(var.node_type_id, try(data.databricks_node_type.default[0].id, null))
  effective_spark_version = coalesce(var.spark_version, try(data.databricks_spark_version.default[0].id, null))

  # If autoscale is set, Databricks ignores num_workers.
  use_autoscale = var.autoscale != null

  # Default tags are helpful for cost attribution.
  merged_tags = merge(
    {
      "terraform" = "true"
      "purpose"   = "all-purpose"
    },
    var.custom_tags
  )
}

resource "databricks_cluster" "this" {
  cluster_name            = "${var.resource_prefix}-${var.cluster_name}"
  spark_version           = local.effective_spark_version
  node_type_id            = local.effective_node_type_id
  autotermination_minutes = var.autotermination_minutes

  # All-purpose / interactive clusters should be "pinned" only if you truly want them to stick around.
  # (Pinned clusters can’t be terminated by auto-termination in some setups; behavior depends on workspace settings.)
  # Keep default false.
  is_pinned = var.is_pinned

  # Policy strongly recommended for guardrails.
  policy_id = var.policy_id

  # Fixed-size OR autoscale
  num_workers = local.use_autoscale ? null : var.num_workers

  dynamic "autoscale" {
    for_each = local.use_autoscale ? [var.autoscale] : []
    content {
      min_workers = autoscale.value.min_workers
      max_workers = autoscale.value.max_workers
    }
  }

  spark_conf     = var.spark_conf
  spark_env_vars = var.spark_env_vars

  # Optional: enforce single-user if you want "personal compute"-style clusters.
  # Common patterns:
  # - "SINGLE_USER" with single_user_name set
  # - "USER_ISOLATION" for shared clusters
  data_security_mode = var.data_security_mode
  single_user_name   = var.single_user_name

  custom_tags = local.merged_tags

  # AWS-specific cluster settings
  dynamic "aws_attributes" {
    for_each = var.aws_attributes == null ? [] : [var.aws_attributes]
    content {
      availability         = try(aws_attributes.value.availability, null) # "ON_DEMAND" / "SPOT" / "SPOT_WITH_FALLBACK"
      zone_id              = try(aws_attributes.value.zone_id, null)
      instance_profile_arn = try(aws_attributes.value.instance_profile_arn, null)

      ebs_volume_type  = try(aws_attributes.value.ebs_volume_type, null) # e.g. "GENERAL_PURPOSE_SSD"
      ebs_volume_count = try(aws_attributes.value.ebs_volume_count, null)
      ebs_volume_size  = try(aws_attributes.value.ebs_volume_size, null)
    }
  }

  # Optional init scripts
  dynamic "init_scripts" {
    for_each = var.init_scripts
    content {
      workspace {
        destination = init_scripts.value
      }
    }
  }

  # Optional: cluster logging
  dynamic "cluster_log_conf" {
    for_each = var.cluster_log_conf == null ? [] : [var.cluster_log_conf]
    content {
      dbfs {
        destination = cluster_log_conf.value.dbfs_destination
      }
    }
  }
}

# Optional permissions (make it shared/power-user, etc.)
resource "databricks_permissions" "cluster" {
  count = length(var.acl) == 0 ? 0 : 1

  cluster_id = databricks_cluster.this.id

  dynamic "access_control" {
    for_each = var.acl
    content {
      group_name             = try(access_control.value.group_name, null)
      user_name              = try(access_control.value.user_name, null)
      service_principal_name = try(access_control.value.service_principal_name, null)

      permission_level = access_control.value.permission_level
      # Typically: "CAN_ATTACH_TO" or "CAN_MANAGE"
    }
  }
}
