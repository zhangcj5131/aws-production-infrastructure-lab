resource "aws_kms_key" "v4" {
  description         = "V4 encryption key for AWS production infrastructure lab"
  enable_key_rotation = false

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-consolepolicy-3"

    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::730140895184:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },

      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::730140895184:user/lab-admin"
        }

        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:RotateKeyOnDemand"
        ]

        Resource = "*"
      },

      {
        Sid    = "Allow use of the key"
        Effect = "Allow"

        Principal = {
          AWS = [
            "arn:aws:iam::730140895184:role/v2-ec2-role",
            "arn:aws:iam::730140895184:user/lab-admin"
          ]
        }

        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]

        Resource = "*"
      },

      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"

        Principal = {
          AWS = [
            "arn:aws:iam::730140895184:role/v2-ec2-role",
            "arn:aws:iam::730140895184:user/lab-admin"
          ]
        }

        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]

        Resource = "*"

        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },

      {
        Sid    = "AllowCloudTrailToEncryptLogs"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:us-east-1:730140895184:trail/v4-audit-trail"
          }

          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:730140895184:trail/*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "v4" {
  name          = "alias/aws-prod-lab-v4"
  target_key_id = aws_kms_key.v4.key_id
}