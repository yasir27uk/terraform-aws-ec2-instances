# Advanced EC2 Auto Scaling Group Example
# This example demonstrates advanced features including load balancer integration, custom security groups, and scaling policies

provider "aws" {
  region = "us-east-1"
}

# Example: Assuming you have existing resources
# In a real scenario, you would create these with Terraform

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

# Example load balancer target group (would normally be created by your ALB module)
# variable "alb_target_group_arn" {
#   description = "ARN of the ALB target group"
#   type        = string
# }

module "advanced_asg" {
  source = "../.."
  
  # Required Configuration
  project_name = "advanced-api"
  environment  = "prod"
  region       = "us-east-1"
  
  # Network Configuration
  vpc_id       = data.aws_vpc.main.id
  subnet_ids   = data.aws_subnets.private.ids
  subnet_type  = "private"
  
  # Instance Configuration
  instance_type = "t3.xlarge"
  min_size      = 3
  max_size      = 15
  desired_capacity = 6
  
  # Custom AMI (using latest Amazon Linux 2)
  ami_id = null  # Will use dynamic AMI selection
  
  # SSH Key Pair
  key_pair_name = "my-ssh-key"  # Replace with your key pair name
  
  # IAM Instance Profile
  iam_instance_profile = "ec2-instance-profile"  # Replace with your instance profile
  
  # Detailed Monitoring
  monitoring = true
  
  # Security Group Configuration
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
      description = "Allow SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.1.0/24"]  # Replace with your bastion subnet
      self        = false
    }
  ]
  
  # Load Balancer Integration
  # target_group_arns = [var.alb_target_group_arn]
  # load_balancer_type = "application"
  health_check_type = "ELB"
  
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
    },
    {
      name                   = "request-count"
      target_metric          = "predefined"
      predefined_metric_type = "ALBRequestCountPerTarget"
      target_value          = 1000.0
      disable_scale_in      = false
      scale_in_cooldown     = 300
      scale_out_cooldown    = 60
    }
  ]
  
  # Step Scaling Policies (custom alarms)
  step_scaling_policies = [
    {
      name                  = "scale-out-high-memory"
      adjustment_type        = "ChangeInCapacity"
      scaling_adjustment     = 2
      metric_aggregation_type = "Average"
      cooldown              = 300
      alarm_name            = "high-memory-alarm"
    }
  ]
  
  # Scheduled Scaling Policies
  scheduled_scaling_policies = [
    {
      scheduled_action_name = "scale-up-business-hours"
      name                 = "business-hours-scale-up"
      min_size            = 5
      max_size            = 20
      desired_capacity    = 10
      recurrence          = "0 9 * * MON-FRI"
      start_time          = "2024-01-01T09:00:00Z"
    },
    {
      scheduled_action_name = "scale-down-after-hours"
      name                 = "after-hours-scale-down"
      min_size            = 3
      max_size            = 8
      desired_capacity    = 3
      recurrence          = "0 18 * * MON-FRI"
      start_time          = "2024-01-01T18:00:00Z"
    }
  ]
  
  # Instance Refresh for rolling updates
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }
  
  # Capacity Rebalancing for Spot instances (if using mixed instances)
  capacity_rebalance = false
  
  # CloudWatch Alarms
  enable_cloudwatch_alarms = true
  cloudwatch_alarms = [
    {
      name                = "high-cpu-alarm"
      description         = "Alert when CPU utilization is above 80%"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods   = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      dimensions = {
        AutoScalingGroupName = ""  # Will be dynamically set
      }
      alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]  # Replace with your SNS topic
      ok_actions    = []
    }
  ]
  
  # Tags
  tags = {
    Owner       = "Infrastructure"
    CostCenter  = "Platform"
    Application = "BackendAPI"
    Environment = "Production"
  }
  
  # Instance-specific tags
  instance_tags = {
    Component = "API Server"
    Tier      = "Backend"
  }
}

# Outputs
output "asg_configuration" {
  description = "Complete ASG configuration"
  value       = module.advanced_asg.asg_configuration
}

output "scaling_configuration" {
  description = "Scaling policy configuration"
  value       = module.advanced_asg.scaling_configuration
}

output "security_group_id" {
  description = "Security Group ID created by the module"
  value       = module.advanced_asg.security_group_id
}