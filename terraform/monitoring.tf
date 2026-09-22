# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/aws-prod-lab/v2/nginx/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/aws-prod-lab/v2/nginx/error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-v4-web"
  retention_in_days = 7
}


# ============================================================
# CloudWatch Alarms
# ============================================================

resource "aws_cloudwatch_metric_alarm" "unhealthy_target" {
  alarm_name          = "v5-unhealthy-target-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.operations_alerts.arn
  ]

  metric_query {
    id          = "q1"
    expression  = "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE LoadBalancer = '${aws_lb.web.arn_suffix}' AND TargetGroup = '${aws_lb_target_group.web.arn_suffix}'"
    return_data = true
    period      = 300
  }

  warm_up_configuration {
    only_start_evaluating_after_warm_up_period_ends = true
    warm_up_period_duration_in_minutes              = 1
  }
}


resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "v5-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 80
  treat_missing_data  = "missing"

  alarm_actions = [
    aws_sns_topic.operations_alerts.arn
  ]

  metric_query {
    id          = "q1"
    expression  = "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${aws_autoscaling_group.web.name}'"
    return_data = true
    period      = 300
  }

  warm_up_configuration {
    only_start_evaluating_after_warm_up_period_ends = true
    warm_up_period_duration_in_minutes              = 5
  }
}


resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "v5-target-5xx-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.operations_alerts.arn
  ]

  metric_query {
    id          = "q1"
    expression  = "SELECT SUM(HTTPCode_Target_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) WHERE LoadBalancer = '${aws_lb.web.arn_suffix}'"
    return_data = true
    period      = 300
  }

  warm_up_configuration {
    only_start_evaluating_after_warm_up_period_ends = true
    warm_up_period_duration_in_minutes              = 1
  }
}


# ============================================================
# CloudWatch Dashboard
# ============================================================

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "v5-operations-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT AVG(mem_used_percent) FROM SCHEMA(CWAgent, AutoScalingGroupName,ImageId,InstanceId,InstanceType) WHERE AutoScalingGroupName = '${aws_autoscaling_group.web.name}'"
                label      = "mem_used_percent"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT AVG(StatusCheckFailed) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${aws_autoscaling_group.web.name}'"
                label      = "StatusCheckFailed"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${aws_autoscaling_group.web.name}'"
                label      = "CPUUtilization"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT AVG(GroupInServiceInstances) FROM \"AWS/AutoScaling\" WHERE AutoScalingGroupName = '${aws_autoscaling_group.web.name}'"
                label      = "GroupInServiceInstances"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT SUM(HTTPCode_Target_5XX_Count) FROM \"AWS/ApplicationELB\" WHERE LoadBalancer = '${aws_lb.web.arn_suffix}' AND TargetGroup = '${aws_lb_target_group.web.arn_suffix}'"
                label      = "HTTPCode_Target_5XX_Count"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT AVG(TargetResponseTime) FROM \"AWS/ApplicationELB\" WHERE LoadBalancer = '${aws_lb.web.arn_suffix}' AND TargetGroup = '${aws_lb_target_group.web.arn_suffix}'"
                label      = "TargetResponseTime"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT MIN(HealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE LoadBalancer = '${aws_lb.web.arn_suffix}' AND TargetGroup = '${aws_lb_target_group.web.arn_suffix}'"
                label      = "HealthyHostCount"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      },

      {
        type   = "metric"
        x      = 18
        y      = 6
        width  = 6
        height = 6

        properties = {
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              {
                expression = "SELECT SUM(RequestCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) WHERE LoadBalancer = '${aws_lb.web.arn_suffix}'"
                label      = "RequestCount"
                id         = "q1"
              }
            ]
          ]

          region = "us-east-1"
          stat   = "Average"
          period = 300
        }
      }
    ]
  })
}