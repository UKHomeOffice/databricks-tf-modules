output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the created S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "ARN of the created S3 bucket."
}

output "iam_role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN of the IAM role assumed by Databricks."
}

output "databricks_external_id" {
  value       = random_uuid.external_id.result
  description = "External ID used for sts:AssumeRole (also set in the storage credential)."
}

output "storage_credential_name" {
  value       = databricks_storage_credential.this.name
  description = "Unity Catalog storage credential name."
}

output "external_location_name" {
  value       = databricks_external_location.this.name
  description = "Unity Catalog external location name."
}

output "external_location_url" {
  value       = databricks_external_location.this.url
  description = "S3 URL for the external location."
}
