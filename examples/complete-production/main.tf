# Complete Production-Ready EC2 ASG Example
# This example demonstrates a production-ready configuration with all features enabled

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Data sources for existing infrastructure
data "aws_vpc" "main" {
  default = false
  id      = "vpc-1234567890abcdef0"  # Replace with your VPC ID
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# Example: Application Load Balancer (would normally be created separately)
# resource "aws_lb" "main" {
#   name               = "${var.project_name}-alb"
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = data.aws_subnets.public.ids
# }

# Example: Target Group (would normally be created separately)
# resource "aws_lb_target_group" "main" {
#   name        = "${var.project_name}-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = data.aws_vpc.main.id
#   health_check {
#     enabled = true
#     path    = "/health"
#   }
# }

# Assume these exist or are created by other modules
# variable "alb_target_group_arn" {
#   description = "ARN of the ALB target group"
#   type        = string
# }

module "production_asg" {
  source = "../.."
  
  # ==============================================================================
  # REQUIRED CONFIGURATION
  # ==============================================================================
  project_name = "production-application"
  environment  = "prod"
  region       = "us-east-1"
  
  # ==============================================================================
  # NETWORK CONFIGURATION
  # ==============================================================================
  vpc_id       = data.aws_vpc.main.id
  subnet_ids   = data.aws_subnets.private.ids
  subnet_type  = "private"
  enable_public_ip_address = false
  
  # ==============================================================================
  # INSTANCE CONFIGURATION
  # ==============================================================================
  instance_type = "t3.xlarge"
  
  # Use latest Amazon Linux 2 AMI
  ami_id = null
  
  # SSH Key Pair for troubleshooting
  key_pair_name = "production-ssh-key"  # Replace with your key
  
  # IAM Instance Profile for application permissions
  iam_instance_profile = "production-ec2-profile"  # Replace with your profile
  
  # Enable detailed monitoring
  monitoring = true
  
  # Custom user data script
  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install CloudWatch agent
              yum install -y amazon-cloudwatch-agent
              
              # Start application
              systemctl start my-application
              systemctl enable my-application
              EOF
  
  # Enhanced security - IMDS configuration
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }
  
  # Enable termination protection
  enable_termination_protection = true
  
  # ==============================================================================
  # STORAGE CONFIGURATION
  # ==============================================================================
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        iops                  = 3000
        kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"  # Replace with your KMS key
        snapshot_id           = null
        throughput            = 125
        volume_size           = 50
        volume_type           = "gp3"
      }
    },
    {
      device_name = "/dev/sdb"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        iops                  = 5000
        kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
        snapshot_id           = null
        throughput            = 125
        volume_size           = 100
        volume_type           = "gp3"
      }
    }
  ]
  
  # ==============================================================================
  # AUTO SCALING CONFIGURATION
  # ==============================================================================
  min_size           = 4
  max_size           = 20
  desired_capacity   = 6
  default_instance_warmup = 600  # 10 minutes for full initialization
  
  # Enable capacity rebalancing
  capacity_rebalance = true
  
  # ==============================================================================
  # LOAD BALANCER INTEGRATION
  # ==============================================================================
  # target_group_arns = [var.alb_target_group_arn]
  # load_balancer_type = "application"
  health_check_type = "ELB"
  health_check_grace_period = 900  # 15 minutes for full health check
  
  # ==============================================================================
  # SECURITY GROUP CONFIGURATION
  # ==============================================================================
  create_security_group = true
  ingress_rules = [
    {
      description = "Allow HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = false
    },
    {
      description = "Allow HTTPS from ALB"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = false
    },
    {
      description = "Allow SSH from bastion hosts"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.1.0/24"]  # Replace with bastion subnet
      self        = false
    },
    {
      description = "Allow metrics collection"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = false
    }
  ]
  
  # ==============================================================================
  # SCALING POLICIES
  # ==============================================================================
  enable_scaling_policies = true
  
  # Target Tracking Scaling Policies
  target_tracking_scaling_policies = [
    {
      name                   = "cpu-utilization"
      target_metric          = "predefined"
      predefined_metric_type = "ASGAverageCPUUtilization"
      target_value          = 65.0
      disable_scale_in      = false
      scale_in_cooldown     = 600
      scale_out_cooldown    = 120
    },
    {
      name                   = "request-count-per-target"
      target_metric          = "predefined"
      predefined_metric_type = "ALBRequestCountPerTarget"
      target_value          = 2000.0
      disable_scale_in      = false
      scale_in_cooldown     = 600
      scale_out_cooldown    = 120
    }
  ]
  
  # Scheduled Scaling Policies
  scheduled_scaling_policies = [
    {
      scheduled_action_name = "weekday-morning-scale-up"
      name                 = "morning-scale-up"
      min_size            = 6
      max_size            = 20
      desired_capacity    = 12
      recurrence          = "0 6 * * MON-FRI"
      start_time          = "2024-01-01T06:00:00Z"
    },
    {
      scheduled_action_name = "weekday-evening-scale-down"
      name                 = "evening-scale-down"
      min_size            = 4
      max_size            = 12
      desired_capacity    = 6
      recurrence          = "0 20 * * MON-FRI"
      start_time          = "2024-01-01T20:00:00Z"
    },
    {
      scheduled_action_name = "weekend-scale-down"
      name                 = "weekend-scale-down"
      min_size            = 2
      max_size            = 6
      desired_capacity    = 3
      recurrence          = "0 22 * * SAT,SUN"
      start_time          = "2024-01-01T22:00:00Z"
    }
  ]
  
  # ==============================================================================
  # LIFECYCLE HOOKS
  # ==============================================================================
  lifecycle_hooks = [
    {
      name                   = "wait-for-application-health"
      default_result         = "CONTINUE"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
      heartbeat_timeout      = 600
      lifecycle_hook_timeout  = 900
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:production-notifications"
      notification_metadata  = "{&quot;event&quot;:&quot;launch&quot;,&quot;action&quot;:&quot;health_check&quot;}"
      role_arn               = "arn:aws:iam::123456789012:role/lifecycle-hook-role"
    },
    {
      name                   = "graceful-shutdown"
      default_result         = "CONTINUE"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
      heartbeat_timeout      = 300
      lifecycle_hook_timeout  = 600
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:production-notifications"
      notification_metadata  = "{&quot;event&quot;:&quot;termination&quot;,&quot;action&quot;:&quot;graceful_shutdown&quot;}"
      role_arn               = "arn:aws:iam::123456789012:role/lifecycle-hook-role"
    }
  ]
  
  # ==============================================================================
  # INSTANCE REFRESH
  # ==============================================================================
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 600
    }
    triggers = ["tag"]
  }
  
  # ==============================================================================
  # CLOUDWATCH MONITORING
  # ==============================================================================
  enable_cloudwatch_alarms = true
  cloudwatch_alarms = [
    {
      name                = "production-high-cpu-alarm"
      description         = "Alert when CPU utilization is above 80% for 10 minutes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods   = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      dimensions = {
        AutoScalingGroupName = ""  # Will be set dynamically
      }
      alarm_actions = [
        "arn:aws:sns:us-east-1:123456789012:production-alerts"
      ]
      ok_actions = [
        "arn:aws:sns:us-east-1:123456789012:production-recovery"
      ]
    },
    {
      name                = "production-high-memory-alarm"
      description         = "Alert when memory utilization is above 90%"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods   = 2
      period              = 300
      statistic           = "Average"
      threshold           = 90
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"
      dimensions = {
        AutoScalingGroupName = ""  # Will be set dynamically
      }
      alarm_actions = [
        "arn:aws:sns:us-east-1:123456789012:production-alerts"
      ]
      ok_actions = []
    }
  ]
  
  # ==============================================================================
  # TAGGING
  # ==============================================================================
  tags = {
    Project     = "ProductionApplication"
    Environment = "Production"
    Owner       = "PlatformTeam"
    CostCenter  = "Engineering"
    Compliance  = "PCI-DSS"
    Backup      = "enabled"
    Monitoring  = "enhanced"
  }
  
  instance_tags = {
    Application = "ProductionApp"
    Component   = "WebServer"
    Tier        = "Application"
    PatchGroup  = "production-weekly"
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
output "production_asg_summary" {
  description = "Production ASG summary"
  value = {
    name = module.production_asg.autoscaling_group_name
    id   = module.production_asg.autoscaling_group_id
    arn  = module.production_asg.autoscaling_group_arn
    
    capacity = {
      min           = module.production_asg.autoscaling_group_min_size
      max           = module.production_asg.autoscaling_group_max_size
      desired       = module.production_asg.autoscaling_group_desired_capacity
      availability_zones = module.production_asg.autoscaling_group_availability_zones
    }
    
    instance = {
      type      = module.production_asg.instance_type
      ami       = module.production_asg.ami_id
      template  = module.production_asg.launch_template_name
      security_groups = module.production_asg.security_group_ids
    }
    
    scaling = module.production_asg.scaling_configuration
    
    monitoring = {
      cloudwatch_alarms = module.production_asg.cloudwatch_alarm_names
      health_check_type = module.production_asg.health_check_type
      health_check_grace_period = module.production_asg.health_check_grace_period
    }
  }
}

output "production_lifecycle_hooks" {
  description = "Production lifecycle hooks"
  value = {
    hook_ids   = module.production_asg.lifecycle_hook_ids
    hook_names = module.production_asg.lifecycle_hook_names
  }
}

output "production_security_configuration" {
  description = "Production security configuration"
  value = {
    security_group_id = module.production_asg.security_group_id
    subnet_type       = module.production_asg.subnet_type
    public_ip         = false
    imds_tokens       = "required"
    encryption        = "enabled"
    termination_protection = true
  }
}