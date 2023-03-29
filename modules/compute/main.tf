# Create the security group
resource "aws_security_group" "web" {
  name_prefix = "web_sg"
  vpc_id      = var.vpc_id

  # Only allow traffic from the load balancer and CloudWatch metrics
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.load_balancer.id}"]
  }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.cloudwatch.id}"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tags}-sg"
  }
}

# Create the load balancer security group
resource "aws_security_group" "load_balancer" {
#   name_prefix = "load_balancer_sg_"
  vpc_id      = var.vpc_id

  # Allow traffic from the Internet on port 80 and 443
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tags}-lb-sg"
  }
}

# Create the CloudWatch metrics security group
resource "aws_security_group" "cloudwatch" {
#   name_prefix = "cloudwatch_sg_"
  vpc_id      = var.vpc_id

  # Allow all inbound traffic from the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tags}-cloudwatch-sg"
  }
}

# Create the launch configuration
resource "aws_launch_configuration" "web" {
#   name_prefix                 = "web_lc_"
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.web.id]
  associate_public_ip_address = true

  # Add the CloudWatch agent to the instance
  user_data = <<-EOF
              #!/bin/bash
              yum install -y awslogs
              systemctl start awslogsd
              EOF
#   tags = {
#     Name = "${var.tags}-launch-config"
#   }
}

# Create the target group for the load balancer
resource "aws_lb_target_group" "web" {
#   name_prefix = "web_tg_"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "${var.tags}-target-group"
  }
}

resource "aws_lb" "web" {
#   name_prefix        = "web_lb_"
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.load_balancer.id]
#   listener {
#     port     = 80
#     protocol = "TCP"
#     default_action {
#       type             = "forward"
#       target_group_arn = aws_lb_target_group.web.arn
#     }
#   }
  tags = {
    Name = "${var.tags}-lb"
  }
}

resource "aws_autoscaling_group" "web" {
#   name_prefix               = "web_asg_"
  launch_configuration      = aws_launch_configuration.web.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.web.arn]
  termination_policies      = ["OldestInstance", "Default"]
  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
#   tags = {
#     Name = "${var.tags}-asg"
#   }
}

resource "aws_cloudwatch_metric_alarm" "web" {
  alarm_name          = "web_metric_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when the number of instances in the Auto Scaling group falls below 1"
  alarm_actions       = [aws_autoscaling_group.web.arn]
}
