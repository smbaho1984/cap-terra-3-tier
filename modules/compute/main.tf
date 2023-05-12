# # Create the security group
# resource "aws_security_group" "web" {
#   name_prefix = "web_sg"
#   vpc_id      = var.vpc_id

#   # Only allow traffic from the load balancer and CloudWatch metrics
#   ingress {
#     from_port       = 0
#     to_port         = 65535
#     protocol        = "tcp"
#     security_groups = ["${aws_security_group.load_balancer.id}"]
#   }

#   ingress {
#     from_port       = 0
#     to_port         = 65535
#     protocol        = "tcp"
#     security_groups = ["${aws_security_group.cloudwatch.id}"]
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "${var.tags}-sg"
#   }
# }

# # Create the load balancer security group
# resource "aws_security_group" "load_balancer" {
# #   name_prefix = "load_balancer_sg_"
#   vpc_id      = var.vpc_id

#   # Allow traffic from the Internet on port 80 and 443
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "${var.tags}-lb-sg"
#   }
# }

# # Create the CloudWatch metrics security group
# resource "aws_security_group" "cloudwatch" {
# #   name_prefix = "cloudwatch_sg_"
#   vpc_id      = var.vpc_id

#   # Allow all inbound traffic from the VPC
#   ingress {
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr_block}"]
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "${var.tags}-cloudwatch-sg"
#   }
# }

# # Create the launch configuration
# resource "aws_launch_configuration" "web" {
# #   name_prefix                 = "web_lc_"
#   image_id                    = var.ami_id
#   instance_type               = var.instance_type
#   security_groups             = [aws_security_group.web.id]
#   associate_public_ip_address = true

#   # Add the CloudWatch agent to the instance
#   user_data = <<-EOF
#               #!/bin/bash
#               yum install -y awslogs
#               systemctl start awslogsd
#               EOF
# #   tags = {
# #     Name = "${var.tags}-launch-config"
# #   }
# }

# # Create the target group for the load balancer
# resource "aws_lb_target_group" "web" {
# #   name_prefix = "web_tg_"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   health_check {
#     interval            = 30
#     path                = "/"
#     port                = "traffic-port"
#     protocol            = "HTTP"
#     timeout             = 10
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }
#   tags = {
#     Name = "${var.tags}-target-group"
#   }
# }

# resource "aws_lb" "web" {
# #   name_prefix        = "web_lb_"
#   load_balancer_type = "application"
#   subnets            = var.subnet_ids
#   security_groups    = [aws_security_group.load_balancer.id]
# #   listener {
# #     port     = 80
# #     protocol = "TCP"
# #     default_action {
# #       type             = "forward"
# #       target_group_arn = aws_lb_target_group.web.arn
# #     }
# #   }
#   tags = {
#     Name = "${var.tags}-lb"
#   }
# }

# resource "aws_autoscaling_group" "web" {
# #   name_prefix               = "web_asg_"
#   name                        = "web_autoscaling_group"
#   launch_configuration      = aws_launch_configuration.web.name
#   min_size                  = var.min_size
#   max_size                  = var.max_size
#   desired_capacity          = var.desired_capacity
#   vpc_zone_identifier       = var.subnet_ids
#   health_check_type         = "EC2"
#   health_check_grace_period = 300
#   target_group_arns         = [aws_lb_target_group.web.arn]
#   termination_policies      = ["OldestInstance", "Default"]
#   tag {
#     key                 = "Name"
#     value               = "web"
#     propagate_at_launch = true
#   }
# #   tags = {
# #     Name = "${var.tags}-asg"
# #   }
# }

# resource "aws_cloudwatch_metric_alarm" "web" {
#   alarm_name          = "web_metric_alarm"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = 1
#   depends_on = [
#     aws_autoscaling_group.web
#   ]
#    dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.web.id
#   }
#   metric_name         = "GroupInServiceInstances"
#   namespace           = "AWS/AutoScaling"
#   period              = 60
#   statistic           = "Average"
#   threshold           = 1
#   alarm_description   = "Alarm when the number of instances in the Auto Scaling group falls below 1"
#   alarm_actions       = [aws_autoscaling_group.web.arn]
# }

# Create internal load balancer
resource "aws_lb" "internal" {
  name               = "${var.tags}-lb"
  internal           = true
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id = var.subnet_a
  }

  subnet_mapping {
    subnet_id = var.subnet_b
  }

  tags = {
    Name = "internal-lb"
  }
}


#create load balancer target group (Web_a and Web_b)
# Create target groups
resource "aws_lb_target_group" "web_a" {
  name_prefix = "web-a"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    interval            = 30
    # path                = "/health"
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-a-tg"
  }
}

resource "aws_lb_target_group" "web_b" {
  name_prefix = "web-b"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    interval            = 30
    # path                = "/health"
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-b-tg"
  }
}

# Create listeners network load balancer listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.web_a.arn
    type             = "forward"
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.internal.arn
#   port              = 80
#   protocol          = "http"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.web_a.arn
#   }
#   }

# Create security groups
#create load balancer security group
resource "aws_security_group" "lb_sg" {
  name_prefix = "lb-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg"
  }
}

#create web tier security group: incoming traffic from lb_sg
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  tags = {
    Name = "web-sg"
  }
}

#create database security group==>incoming traffic from web_sg
resource "aws_security_group" "db_sg" {
  name_prefix = "db-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = {
    Name = "db-sg"
  }
}


# # Create RDS resources
# #create db_subnet_group
# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "db-subnet-group"
#   subnet_ids = var.subnet_ids
# }

# resource "aws_db_instance" "db" {
#   identifier           = "my-db-instance"
#   engine               = var.db_engine
#   username = var.db_name
#   password = var.db_password
#   instance_class       = "db.m6gd.large"
#   allocated_storage    = var.db_allocated_storage
#   db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.db_sg.id]

#   tags = {
#     Name = "my-db-instance"
#   }
# }

# resource "aws_db_instance" "db_replica" {
#   identifier                = "my-db-instance-replica"
#   engine                    = var.db_engine
#   instance_class            = "db.m6gd.large"
#   allocated_storage         = var.db_allocated_storage
#   db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids    = [aws_security_group.db_sg.id]
#   #source_db_instance_identifier = aws_db_instance.db.id
#   copy_tags_to_snapshot     = true
#   multi_az                  = true

#   tags = {
#     Name = "my-db-instance-replica"
#   }
# }
resource "aws_key_pair" "my_key_pair" {
  key_name   =  var.key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/SXv2X3ENdfHJkvSk9ihsaEo4p64rfrE91CBoWVsfRiAO4qvmRBwRRZqGYYCNAzGNc0zLsPk10/jE1x0vZF/DO7vSDh5Iqcsb8rdgeDAx6c4n8Ls5TvtRldwC+h6TVcaYOoL3qCp/Ozh3fTMC0NN1jd7iYaj6qHHWBU+f3LyoLCqLgjo3DjdNK9lFl3Q3R2L6KCLXL5ZVm3OX1KEfhtmYBlfLidf76j8owF7Q5mewn4dqbnhdk11H0WuQC0Vah+CML11EfzPqqK80sGQaw/aqIDLmxTCvkaYlJ6i+5L8opCuB6vOmKWi/dBgVB8OmN6iB9YRxpHjWxQEwXTB5DfhhSl1BlNp7fB0rt8J0FdWC1yM2Kpt7UTMUwK+0Z9xhZJ3u0HTg/DYeRCWg7slfDgFmWp2wpJpf8pJl5rPdEd21GkUs+XmIufDw/lbVD7bEzDaWz87s1HbtKRrTX1OUhWgFWkHHXQSXy8R2HBIm95AHlkFsLYqCCEHKKcT7pbZ/ae0= user@DESKTOP-PH85Q5O"
}


# Create launch configuration and autoscaling group
resource "aws_launch_configuration" "web_lc" {
  name_prefix          = "web-lc"
  image_id             = var.ami_id
  instance_type       = var.instance_type
  security_groups      = [aws_security_group.web_sg.id]
  key_name              = aws_key_pair.my_key_pair.key_name
  user_data            = <<-EOF
              #!/bin/bash
              echo "Hello World!" > /var/www/html/index.html
              sudo yum install -y httpd
              sudo systemctl enable httpd
              sudo systemctl start httpd
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
#create autoscaling group
resource "aws_autoscaling_group" "web_asg" {
  name                  = "web-asg"
  launch_configuration = aws_launch_configuration.web_lc.name
  min_size              = var.min_size
  max_size              = var.max_size
  vpc_zone_identifier   = [var.subnet_a, var.subnet_b]
  health_check_type     = "EC2"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "my_autoscaling_policy" {
  name                   = "my_autoscaling_policy"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  # Scale out when CPU utilization exceeds 80%
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
    disable_scale_in = false
  }

  # # Scale in when CPU utilization drops below 30%
  # scaling_adjustment {
  #   name           = "cpu-idle"
  #   scaling_adjustment_type = "ChangeInCapacity"
  #   estimated_instance_warmup = 300
  #   step_adjustment {
  #     scaling_adjustment = -1
  #     metric_interval_lower_bound = 0
  #     metric_interval_upper_bound = 30
  #   }
  # }
}


 #Create an Alarm with Cloudwatch for scaling out
# Scaling out Alarm when CPU utilization is greater than 80%
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
 metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "Scale out if CPU utilization >= 80%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  } 
}

#Create an Alarm with Cloudwatch for scaling in
# Scaling in Alarm when CPU utilization is less than 30%
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30.0
  alarm_description   = "Scale in if CPU utilization <= 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  
  alarm_actions = [aws_autoscaling_policy.my_autoscaling_policy.arn]
}