variable "name" {
  description = "Base name used for bucket/role/UC objects (names will be derived from this)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to AWS resources."
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "Optional explicit S3 bucket name. If null, derived from var.name."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "If true, allows Terraform to delete the bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "s3_prefix" {
  description = "Prefix within the bucket for the External Location (no leading slash). Empty means bucket root."
  type        = string
  default     = ""
}

variable "storage_credential_name" {
  description = "Optional explicit UC storage credential name. If null, derived from var.name."
  type        = string
  default     = null
}

variable "external_location_name" {
  description = "Optional explicit UC external location name. If null, derived from var.name."
  type        = string
  default     = null
}

variable "read_only" {
  description = "If true, create the External Location as read-only."
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Optional explicit IAM role name. If null, derived from var.name."
  type        = string
  default     = null
}

variable "databricks_aws_account_id" {
  description = <<EOT
AWS account id used by Databricks to assume your IAM role (the 'Databricks AWS account ID' for your deployment).
Your platform team usually has this value; it is constant per Databricks deployment.
EOT
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN if your bucket uses SSE-KMS and you want this role to be able to use it."
  type        = string
  default     = null
}

variable "skip_validation" {
  description = "If true, skip Databricks validation on external location creation (useful if networking is not ready)."
  type        = bool
  default     = false
}
