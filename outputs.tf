# ------------------------------------------------------------------------------
# Auto Scaling Group Outputs
# ------------------------------------------------------------------------------
output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.min_size
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.desired_capacity
}

output "autoscaling_group_availability_zones" {
  description = "Availability zones used by the Auto Scaling Group"
  value       = aws_autoscaling_group.main.availability_zones
}

# ------------------------------------------------------------------------------
# Launch Template Outputs
# ------------------------------------------------------------------------------
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.asg.id
}

output "launch_template_name" {
  description = "Name of the Launch Template"
  value       = aws_launch_template.asg.name
}

output "launch_template_arn" {
  description = "ARN of the Launch Template"
  value       = aws_launch_template.asg.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.asg.latest_version
}

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------
output "security_group_id" {
  description = "ID of the ASG Security Group (if created)"
  value       = var.create_security_group ? aws_security_group.asg[0].id : null
}

output "security_group_name" {
  description = "Name of the ASG Security Group (if created)"
  value       = var.create_security_group ? aws_security_group.asg[0].name : null
}

output "security_group_arn" {
  description = "ARN of the ASG Security Group (if created)"
  value       = var.create_security_group ? aws_security_group.asg[0].arn : null
}

output "security_group_ids" {
  description = "List of security group IDs applied to instances"
  value       = local.security_group_ids
}

# ------------------------------------------------------------------------------
# Instance Outputs
# ------------------------------------------------------------------------------
output "instance_type" {
  description = "EC2 instance type used by the ASG"
  value       = var.instance_type
}

output "ami_id" {
  description = "AMI ID used for instances"
  value       = local.ami_id
}

output "instance_tags" {
  description = "Tags applied to instances"
  value       = local.instance_tags
}

# ------------------------------------------------------------------------------
# Scaling Policy Outputs
# ------------------------------------------------------------------------------
output "target_tracking_policy_ids" {
  description = "IDs of target tracking scaling policies"
  value       = aws_autoscaling_policy.target_tracking[*].id
}

output "target_tracking_policy_names" {
  description = "Names of target tracking scaling policies"
  value       = aws_autoscaling_policy.target_tracking[*].name
}

output "step_scaling_policy_ids" {
  description = "IDs of step scaling policies"
  value       = aws_autoscaling_policy.step_scaling[*].id
}

output "step_scaling_policy_names" {
  description = "Names of step scaling policies"
  value       = aws_autoscaling_policy.step_scaling[*].name
}

output "scheduled_scaling_policy_ids" {
  description = "IDs of scheduled scaling policies"
  value       = aws_autoscaling_schedule.main[*].id
}

output "scheduled_scaling_policy_names" {
  description = "Names of scheduled scaling policies"
  value       = aws_autoscaling_schedule.main[*].scheduled_action_name
}

# ------------------------------------------------------------------------------
# Lifecycle Hook Outputs
# ------------------------------------------------------------------------------
output "lifecycle_hook_ids" {
  description = "IDs of lifecycle hooks"
  value       = aws_autoscaling_lifecycle_hook.main[*].id
}

output "lifecycle_hook_names" {
  description = "Names of lifecycle hooks"
  value       = aws_autoscaling_lifecycle_hook.main[*].name
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm Outputs
# ------------------------------------------------------------------------------
output "cloudwatch_alarm_ids" {
  description = "IDs of CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.main[*].id
}

output "cloudwatch_alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.main[*].alarm_arn
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms"
  value       = aws_cloudwatch_metric_alarm.main[*].alarm_name
}

# ------------------------------------------------------------------------------
# Health Check Outputs
# ------------------------------------------------------------------------------
output "health_check_type" {
  description = "Health check type configured for the ASG"
  value       = aws_autoscaling_group.main.health_check_type
}

output "health_check_grace_period" {
  description = "Health check grace period in seconds"
  value       = aws_autoscaling_group.main.health_check_grace_period
}

# ------------------------------------------------------------------------------
# Load Balancer Outputs
# ------------------------------------------------------------------------------
output "target_group_arns" {
  description = "Target group ARNs attached to the ASG"
  value       = var.target_group_arns
}

output "load_balancer_type" {
  description = "Load balancer type configured"
  value       = var.load_balancer_type
}

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID where resources are created"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs where instances are launched"
  value       = var.subnet_ids
}

output "subnet_type" {
  description = "Type of subnets used (public/private)"
  value       = var.subnet_type
}

# ------------------------------------------------------------------------------
# Metadata Outputs
# ------------------------------------------------------------------------------
output "region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID where resources are created"
  value       = data.aws_caller_identity.current.account_id
}

output "project_name" {
  description = "Project name used for resources"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# ------------------------------------------------------------------------------
# Composite Outputs
# ------------------------------------------------------------------------------
output "asg_configuration" {
  description = "Complete ASG configuration object"
  value = {
    id               = aws_autoscaling_group.main.id
    name             = aws_autoscaling_group.main.name
    arn              = aws_autoscaling_group.main.arn
    min_size         = aws_autoscaling_group.main.min_size
    max_size         = aws_autoscaling_group.main.max_size
    desired_capacity = aws_autoscaling_group.main.desired_capacity
    instance_type    = var.instance_type
    ami_id           = local.ami_id
    security_groups  = local.security_group_ids
    subnets          = var.subnet_ids
    target_groups    = var.target_group_arns
  }
}

output "scaling_configuration" {
  description = "Scaling policy configuration object"
  value = {
    target_tracking = {
      ids   = aws_autoscaling_policy.target_tracking[*].id
      names = aws_autoscaling_policy.target_tracking[*].name
      count = length(aws_autoscaling_policy.target_tracking)
    }
    step_scaling = {
      ids   = aws_autoscaling_policy.step_scaling[*].id
      names = aws_autoscaling_policy.step_scaling[*].name
      count = length(aws_autoscaling_policy.step_scaling)
    }
    scheduled_scaling = {
      ids   = aws_autoscaling_schedule.main[*].id
      names = aws_autoscaling_schedule.main[*].scheduled_action_name
      count = length(aws_autoscaling_schedule.main)
    }
  }
}