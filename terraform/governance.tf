# ============================================================
# CloudTrail
# ============================================================

resource "aws_cloudtrail" "audit" {
  name           = "v4-audit-trail"
  s3_bucket_name = aws_s3_bucket.project.id
  kms_key_id     = aws_kms_key.v4.arn

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  is_organization_trail         = false

  advanced_event_selector {
    name = "Management events selector"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.project
  ]
}


# ============================================================
# AWS Config
# ============================================================

resource "aws_config_configuration_recorder" "main" {
  name = "default"

  role_arn = "arn:aws:iam::730140895184:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  recording_group {
    all_supported                 = false
    include_global_resource_types = false

    exclusion_by_resource_types {
      resource_types = [
        "AWS::IAM::Policy",
        "AWS::IAM::User",
        "AWS::IAM::Role",
        "AWS::IAM::Group"
      ]
    }

    recording_strategy {
      use_only = "EXCLUSION_BY_RESOURCE_TYPES"
    }
  }

  recording_mode {
    recording_frequency = "CONTINUOUS"
  }
}


resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.project.id

  depends_on = [
    aws_config_configuration_recorder.main
  ]
}


resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.main
  ]
}


# ============================================================
# AWS Budget
# ============================================================

resource "aws_budgets_budget" "zero_spend" {
  billing_view_arn = "arn:aws:billing::730140895184:billingview/primary"
  name             = "My Zero-Spend Budget"
  budget_type      = "COST"
  limit_amount     = "1.00"
  limit_unit       = "USD"
  time_unit        = "MONTHLY"

  time_period_start = "2026-09-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 0.01
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["zhangcj5@gmail.com"]
  }
}