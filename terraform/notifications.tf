resource "aws_sns_topic" "operations_alerts" {
  name = "v5-operations-alerts"
}

resource "aws_sns_topic_policy" "operations_alerts" {
  arn = aws_sns_topic.operations_alerts.arn

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "__default_policy_ID"

    Statement = [
      {
        Sid    = "__default_statement_ID"
        Effect = "Allow"

        Principal = {
          AWS = "*"
        }

        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]

        Resource = aws_sns_topic.operations_alerts.arn

        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = "730140895184"
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "operations_email" {
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false
  topic_arn                       = aws_sns_topic.operations_alerts.arn
  protocol                        = "email"
  endpoint                        = "zhangcj200209@163.com"
}