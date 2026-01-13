# Lifecycle Hooks Example
# This example demonstrates advanced lifecycle hook configuration for custom instance workflows

provider "aws" {
  region = "us-east-1"
}

# Assuming you have an SNS topic for notifications
# resource "aws_sns_topic" "lifecycle_notifications" {
#   name = "${var.project_name}-lifecycle-notifications"
# }

# Assuming you have an IAM role for lifecycle hooks
# resource "aws_iam_role" "lifecycle_hook_role" {
#   name = "${var.project_name}-lifecycle-hook-role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

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

module "lifecycle_hook_asg" {
  source = "../.."
  
  # Required Configuration
  project_name = "application-server"
  environment  = "prod"
  region       = "us-east-1"
  
  # Network Configuration
  vpc_id       = data.aws_vpc.main.id
  subnet_ids   = data.aws_subnets.private.ids
  subnet_type  = "private"
  
  # Instance Configuration
  instance_type = "t3.large"
  min_size      = 2
  max_size      = 10
  desired_capacity = 4
  
  # Lifecycle Hooks Configuration
  lifecycle_hooks = [
    {
      # Instance Launch Hook - Wait for application to be healthy
      name                   = "wait-for-app-health"
      default_result         = "CONTINUE"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
      heartbeat_timeout      = 600   # 10 minutes
      lifecycle_hook_timeout  = 900   # 15 minutes
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:lifecycle-notifications"  # Replace with your SNS topic
      notification_metadata  = "{&quot;event&quot;:&quot;instance_launch&quot;,&quot;action&quot;:&quot;wait_for_health&quot;}"
      role_arn               = "arn:aws:iam::123456789012:role/lifecycle-hook-role"  # Replace with your role ARN
    },
    {
      # Instance Termination Hook - Graceful shutdown
      name                   = "graceful-shutdown"
      default_result         = "CONTINUE"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
      heartbeat_timeout      = 300   # 5 minutes
      lifecycle_hook_timeout  = 600   # 10 minutes
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:lifecycle-notifications"  # Replace with your SNS topic
      notification_metadata  = "{&quot;event&quot;:&quot;instance_termination&quot;,&quot;action&quot;:&quot;graceful_shutdown&quot;}"
      role_arn               = "arn:aws:iam::123456789012:role/lifecycle-hook-role"  # Replace with your role ARN
    },
    {
      # Pre-scale-out Hook - Pre-warm cache
      name                   = "pre-scale-out-warmup"
      default_result         = "ABANDON"  # Abort scaling if warmup fails
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
      heartbeat_timeout      = 120   # 2 minutes
      lifecycle_hook_timeout  = 180   # 3 minutes
      notification_target_arn = "arn:aws:sns:us-east-1:123456789012:lifecycle-notifications"  # Replace with your SNS topic
      notification_metadata  = "{&quot;event&quot;:&quot;scale_out&quot;,&quot;action&quot;:&quot;cache_warmup&quot;}"
      role_arn               = "arn:aws:iam::123456789012:role/lifecycle-hook-role"  # Replace with your role ARN
    }
  ]
  
  # Security Group
  create_security_group = true
  ingress_rules = [
    {
      description = "Allow application traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = false
    }
  ]
  
  # Target Tracking Scaling Policies
  target_tracking_scaling_policies = [
    {
      name                   = "cpu-utilization"
      target_metric          = "predefined"
      predefined_metric_type = "ASGAverageCPUUtilization"
      target_value          = 70.0
      disable_scale_in      = false
      scale_in_cooldown     = 300
      scale_out_cooldown    = 60
    }
  ]
  
  # Instance Refresh
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 600  # Extended warmup for lifecycle hooks
    }
    triggers = ["tag"]
  }
  
  # Tags
  tags = {
    Application   = "ApplicationServer"
    LifecycleHook = "enabled"
  }
  
  instance_tags = {
    GracefulShutdown = "enabled"
  }
}

# Outputs
output "lifecycle_hooks" {
  description = "Lifecycle hooks configuration"
  value = {
    hook_ids   = module.lifecycle_hook_asg.lifecycle_hook_ids
    hook_names = module.lifecycle_hook_asg.lifecycle_hook_names
  }
}

output "asg_lifecycle_config" {
  description = "ASG lifecycle configuration summary"
  value = {
    asg_name = module.lifecycle_hook_asg.autoscaling_group_name
    instance_warmup = 600
    health_check_grace_period = 600
    lifecycle_hooks = [
      {
        name = "wait-for-app-health"
        transition = "launching"
        timeout = "15 minutes"
        action = "wait for application health"
      },
      {
        name = "graceful-shutdown"
        transition = "terminating"
        timeout = "10 minutes"
        action = "graceful shutdown"
      },
      {
        name = "pre-scale-out-warmup"
        transition = "launching"
        timeout = "3 minutes"
        action = "cache warmup"
      }
    ]
  }
}