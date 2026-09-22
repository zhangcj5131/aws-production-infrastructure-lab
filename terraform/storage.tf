resource "aws_s3_bucket" "project" {
  bucket        = "aws-prod-lab-v2-730140895184"
  force_destroy = true

  tags = {
    Project = "aws-prod-lab"
    Version = "V2"
  }
}

resource "aws_s3_bucket_versioning" "project" {
  bucket = aws_s3_bucket.project.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "project" {
  bucket = aws_s3_bucket.project.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "project" {
  bucket = aws_s3_bucket.project.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "project" {
  bucket = aws_s3_bucket.project.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "project" {
  bucket = aws_s3_bucket.project.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck20150319-69282f54-4fe1-4e92-a355-dd44396049e6"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.project.arn

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:us-east-1:730140895184:trail/v4-audit-trail"
          }
        }
      },

      {
        Sid    = "AWSCloudTrailWrite20150319-d1593770-a86c-4039-8e5c-91675900e2c7"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.project.arn}/AWSLogs/730140895184/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:us-east-1:730140895184:trail/v4-audit-trail"
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      },

      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"

        Principal = {
          Service = "config.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.project.arn

        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = "730140895184"
          }
        }
      },

      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"

        Principal = {
          Service = "config.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.project.arn}/AWSLogs/730140895184/Config/*"

        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = "730140895184"
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}