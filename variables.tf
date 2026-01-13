# Main Configuration Variables
variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,32}$", var.project_name))
    error_message = "Project name must be 1-32 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# EC2/Launch Template Variables
variable "instance_type" {
  description = "EC2 instance type for the ASG instances"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID to use for instances. If null, will use latest Amazon Linux 2 AMI"
  type        = string
  default     = null
}

variable "ami_filter" {
  description = "AMI filter configuration for dynamic AMI selection"
  type = object({
    name        = string
    owner       = string
    virtualization_type = string
  })
  default = {
    name                = "amzn2-ami-hvm-*-x86_64-gp2"
    owner               = "amazon"
    virtualization_type = "hvm"
  }
}

variable "key_pair_name" {
  description = "SSH key pair name to associate with instances"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64 encoded user data script (overrides user_data)"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to associate with instances"
  type        = string
  default     = null
}

variable "monitoring" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable termination protection for instances"
  type        = bool
  default     = false
}

variable "metadata_options" {
  description = "IMDS metadata options for instances"
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    http_protocol_ipv6          = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }
}

variable "capacity_reservation_specification" {
  description = "Capacity reservation specification for instances"
  type = object({
    capacity_reservation_preference = string
    capacity_reservation_target    = map(string)
  })
  default = {
    capacity_reservation_preference = "open"
    capacity_reservation_target    = {}
  }
}

# EBS Volume Configuration
variable "block_device_mappings" {
  description = "Block device mappings for instances"
  type = list(object({
    device_name  = string
    ebs = object({
      delete_on_termination = bool
      encrypted             = bool
      iops                  = number
      kms_key_id            = string
      snapshot_id           = string
      throughput            = number
      volume_size           = number
      volume_type           = string
    })
  }))
  default = [
    {
      device_name = "/dev/xvda"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = null
        throughput            = null
        volume_size           = 20
        volume_type           = "gp3"
      }
    }
  ]
}

# Auto Scaling Group Variables
variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be at least 0."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 5
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = null
  validation {
    condition     = var.desired_capacity == null || (var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size)
    error_message = "Desired capacity must be between min_size and max_size."
  }
}

variable "default_instance_warmup" {
  description = "Default instance warmup time in seconds"
  type        = number
  default     = 300
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalancing for instances"
  type        = bool
  default     = false
}

variable "protect_from_scale_in" {
  description = "Protect instances from scale-in termination"
  type        = bool
  default     = false
}

variable "instance_refresh" {
  description = "Instance refresh configuration"
  type = object({
    strategy = string
    preferences = object({
      min_healthy_percentage = number
      instance_warmup        = number
    })
    triggers = list(string)
  })
  default = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }
}

variable "mixed_instances_policy" {
  description = "Mixed instances policy for using multiple instance types"
  type = object({
    instances_distribution = object({
      on_demand_base_capacity                  = number
      on_demand_percentage_above_base_capacity = number
      spot_allocation_strategy                 = string
      spot_instance_pools                      = number
      spot_max_price                           = string
    })
    override = list(object({
      instance_type     = string
      weighted_capacity = number
      launch_template = object({
        override = object({
          instance_type     = string
          weighted_capacity = number
        })
      })
    }))
  })
  default = null
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "subnet_type" {
  description = "Type of subnets (public or private)"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private"], var.subnet_type)
    error_message = "Subnet type must be either 'public' or 'private'."
  }
}

variable "enable_public_ip_address" {
  description = "Associate public IP addresses with instances"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with instances"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create a dedicated security group for the ASG"
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "Ingress rules for the security group (if create_security_group is true)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    self        = bool
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules for the security group (if create_security_group is true)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    self        = bool
  }))
  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      self        = false
    }
  ]
}

# Health Check Configuration
variable "health_check_type" {
  description = "Type of health checks (EC2, ELB, or both)"
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB", "EC2,ELB"], var.health_check_type)
    error_message = "Health check type must be EC2, ELB, or EC2,ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_enabled" {
  description = "Enable health checks"
  type        = bool
  default     = true
}

# Load Balancer Configuration
variable "target_group_arns" {
  description = "List of target group ARNs to attach to the ASG"
  type        = list(string)
  default     = []
}

variable "load_balancer_type" {
  description = "Type of load balancer (application, network, or gateway)"
  type        = string
  default     = null
  validation {
    condition     = var.load_balancer_type == null || contains(["application", "network", "gateway"], var.load_balancer_type)
    error_message = "Load balancer type must be application, network, or gateway."
  }
}

# Scaling Policies
variable "enable_scaling_policies" {
  description = "Enable automatic scaling policies"
  type        = bool
  default     = true
}

variable "target_tracking_scaling_policies" {
  description = "Target tracking scaling policy configurations"
  type = list(object({
    name                    = string
    target_metric           = string
    predefined_metric_type  = string
    customized_metric_spec  = object({
      metric_name = string
      namespace   = string
      statistic   = string
      unit        = string
    })
    target_value       = number
    disable_scale_in   = bool
    scale_in_cooldown  = number
    scale_out_cooldown = number
  }))
  default = [
    {
      name                   = "average-cpu"
      target_metric          = "predefined"
      predefined_metric_type = "ASGAverageCPUUtilization"
      customized_metric_spec = null
      target_value          = 70
      disable_scale_in      = false
      scale_in_cooldown     = 300
      scale_out_cooldown    = 300
    }
  ]
}

variable "step_scaling_policies" {
  description = "Step scaling policy configurations"
  type = list(object({
    name              = string
    adjustment_type   = string
    scaling_adjustment = number
    metric_aggregation_type = string
    cooldown         = number
    alarm_name       = string
  }))
  default = []
}

variable "scheduled_scaling_policies" {
  description = "Scheduled scaling policy configurations"
  type = list(object({
    name                 = string
    scheduled_action_name = string
    min_size            = number
    max_size            = number
    desired_capacity    = number
    recurrence          = string
    start_time          = string
    end_time            = string
  }))
  default = []
}

# Lifecycle Hooks
variable "lifecycle_hooks" {
  description = "Lifecycle hook configurations"
  type = list(object({
    name                    = string
    lifecycle_transition    = string
    default_result          = string
    heartbeat_timeout       = number
    lifecycle_hook_timeout  = number
    notification_target_arn = string
    notification_metadata   = string
    role_arn                = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Tags to apply to instances (merged with common tags)"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags that will override common tags"
  type        = map(string)
  default     = {}
}

# Monitoring and Alarms
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for the ASG"
  type        = bool
  default     = true
}

variable "cloudwatch_alarms" {
  description = "CloudWatch alarm configurations"
  type = list(object({
    name               = string
    description        = string
    comparison_operator = string
    evaluation_periods  = number
    period             = number
    statistic          = string
    threshold          = number
    metric_name        = string
    namespace          = string
    dimensions         = map(string)
    alarm_actions      = list(string)
    ok_actions         = list(string)
  }))
  default = []
}