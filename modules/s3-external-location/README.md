# Databricks AWS S3 External Location Module

This module is responsible for creating and managing S3 external locations in Databricks hosted on AWS.

## Usage

```hcl
module "s3_external_location" {
  source = "git::ssh://git@github.com/UKHomeOffice/databricks-tf-modules.git//modules/s3-external-location"

  name                    = "dsa-dev-databricks-raw-data-source-1"
  s3_prefix               = "databricks/raw"
  grant_principal_name    = "Data Engineering"
  force_destroy           = false
  read_only               = true
  skip_validation         = false

  databricks_aws_account_id = var.databricks_aws_account_id

  tags = {
    env  = var.env
    team = "dsa"
  }
}
```

## Validation
This module expects the variables to conform to the following:

- `name` - Must be a string between 1 and 256 characters.
- `bucket_name` - Must be a string that follows the standard conventions for AWS S3 bucket names.
