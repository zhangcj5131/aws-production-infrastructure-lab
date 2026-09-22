data "aws_ami" "v4_web_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["v4-web-server-ami"]
  }
}


resource "aws_launch_template" "web" {
  name        = "v3-web-launch-template"
  description = "V4 web server template with Flask, Nginx, systemd auto-start, Secrets Manager, and RDS connectivity"

  image_id      = data.aws_ami.v4_web_server.id
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash

    sed -i 's|^SECRET_ARN = .*|SECRET_ARN = "${aws_db_instance.v4.master_user_secret[0].secret_arn}"|' /opt/v4-app/app.py
    sed -i 's|^RDS_ENDPOINT = .*|RDS_ENDPOINT = "${aws_db_instance.v4.address}"|' /opt/v4-app/app.py

    systemctl restart v4-app
  EOF
  )

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    arn = aws_iam_instance_profile.v2_ec2.arn
  }

  tags = {
    Project = "aws-prod-lab"
    Version = "V3"
  }
}


resource "aws_lb" "web" {
  name               = "v3-web-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a1.id,
    aws_subnet.public_b1.id
  ]

  tags = {
    Project = "aws-prod-lab"
    Version = "V3"
  }
}


resource "aws_lb_target_group" "web" {
  name        = "v3-web-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Project = "aws-prod-lab"
    Version = "V3"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate.web.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn

    forward {
      target_group {
        arn    = aws_lb_target_group.web.arn
        weight = 1
      }

      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}


resource "aws_autoscaling_group" "web" {
  name = "v3-web-asg"


  force_delete                     = false
  force_delete_warm_pool           = false
  ignore_failed_scaling_activities = false
  wait_for_capacity_timeout        = "10m"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.private_app_a2.id,
    aws_subnet.private_app_b2.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  default_cooldown = 300

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingRetainedCapacity",
    "GroupTerminatingRetainedInstances",
    "GroupTotalCapacity",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolPendingRetainedCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTerminatingRetainedCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity"
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  tag {
    key                 = "Name"
    value               = "v3-web-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "aws-prod-lab"
    propagate_at_launch = true
  }

  tag {
    key                 = "Version"
    value               = "V3"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "Target Tracking Policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = 0

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 50
    disable_scale_in = false
  }
}