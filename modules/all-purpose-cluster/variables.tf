variable "resource_prefix" {
  description = "Prefix for the resource names."
  type        = string
}

variable "cluster_name" {
  type        = string
  description = "Human-friendly cluster name."
}

variable "spark_version" {
  type        = string
  default     = null
  description = "Databricks runtime version ID. If null, module picks latest LTS."
}

variable "node_type_id" {
  type        = string
  default     = null
  description = "Instance type (Databricks node type). If null, module picks a local-disk node type."
}

variable "num_workers" {
  type        = number
  default     = 2
  description = "Used when autoscale is not set."
}

variable "autoscale" {
  type = object({
    min_workers = number
    max_workers = number
  })
  default     = null
  description = "Optional autoscale config. If set, num_workers is ignored."
}

variable "autotermination_minutes" {
  type        = number
  default     = 30
  description = "Auto-terminate after inactivity."
}

variable "is_pinned" {
  type        = bool
  default     = false
  description = "Whether the cluster is pinned."
}

variable "policy_id" {
  type        = string
  default     = null
  description = "Optional cluster policy ID (recommended)."
}

variable "spark_conf" {
  type    = map(string)
  default = {}
}

variable "spark_env_vars" {
  type    = map(string)
  default = {}
}

variable "custom_tags" {
  type        = map(string)
  default     = {}
  description = "Additional cost/allocation tags."
}

# Unity Catalog / security posture
variable "data_security_mode" {
  type        = string
  default     = null
  description = "Examples: SINGLE_USER, USER_ISOLATION, NONE (depends on workspace)."
}

variable "single_user_name" {
  type        = string
  default     = null
  description = "Required when data_security_mode = SINGLE_USER."
}

# AWS attributes: keep it flexible
variable "aws_attributes" {
  type = object({
    availability         = optional(string)
    zone_id              = optional(string)
    instance_profile_arn = optional(string)
    ebs_volume_type      = optional(string)
    ebs_volume_count     = optional(number)
    ebs_volume_size      = optional(number)
  })
  default     = null
  description = "Optional AWS-specific cluster attributes."
}

variable "init_scripts" {
  type        = list(string)
  default     = []
  description = "Workspace init script paths (e.g. /Shared/init/setup.sh)."
}

variable "cluster_log_conf" {
  type = object({
    dbfs_destination = string
  })
  default     = null
  description = "Optional cluster log destination."
}

# ACL for cluster sharing
variable "acl" {
  type = list(object({
    group_name             = optional(string)
    user_name              = optional(string)
    service_principal_name = optional(string)
    permission_level       = string
  }))
  default     = []
  description = "Optional access controls. permission_level often: CAN_ATTACH_TO or CAN_MANAGE."
}
