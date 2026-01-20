data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id

  bucket_name = coalesce(var.bucket_name, "${var.name}-external-location")
  role_name   = coalesce(var.iam_role_name, "${var.name}-uc-extloc-role")

  storage_credential_name = coalesce(var.storage_credential_name, "${var.name}_storage_credential")
  external_location_name  = coalesce(var.external_location_name, "${var.name}_external_location")

  # Normalize prefix (no leading slash, allow empty)
  prefix = trim(var.s3_prefix, "/")

  external_location_url = local.prefix == "" ? "s3://${local.bucket_name}" : "s3://${local.bucket_name}/${local.prefix}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "DatabricksAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:role/${local.role_name}",
        "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# IAM permissions for Databricks to access the bucket/prefix.
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.this.arn]

    # If a prefix is provided, limit ListBucket to that prefix.
    dynamic "condition" {
      for_each = local.prefix == "" ? [] : [1]
      content {
        test     = "StringLike"
        variable = "s3:prefix"
        values = [
          local.prefix,
          "${local.prefix}/*"
        ]
      }
    }
  }

  statement {
    sid    = "ObjectRW"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]

    resources = local.prefix == "" ? [
      "${aws_s3_bucket.this.arn}/*"
      ] : [
      "${aws_s3_bucket.this.arn}/${local.prefix}/*"
    ]
  }

  # Optional KMS permissions if SSE-KMS is used
  dynamic "statement" {
    for_each = var.kms_key_arn == null ? [] : [1]
    content {
      sid    = "KmsForS3"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.name}-uc-extloc-s3-policy"
  policy = data.aws_iam_policy_document.s3_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# -----------------------------
# Databricks Unity Catalog objects
# -----------------------------

resource "databricks_storage_credential" "this" {
  name    = local.storage_credential_name
  comment = "Terraform-managed storage credential for ${var.name}"

  aws_iam_role {
    role_arn = aws_iam_role.this.arn
  }
}

resource "databricks_external_location" "this" {
  name            = local.external_location_name
  url             = local.external_location_url
  credential_name = databricks_storage_credential.this.id
  read_only       = var.read_only
  comment         = "Terraform-managed external location for ${var.name}"
  skip_validation = var.skip_validation

  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_iam_role_policy_attachment.this
  ]
}
