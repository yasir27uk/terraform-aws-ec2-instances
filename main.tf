# ------------------------------------------------------------------------------
# Security Group (Optional)
# ------------------------------------------------------------------------------
resource "aws_security_group" "asg" {
  count = var.create_security_group ? 1 : 0
  
  name_prefix = "${local.name_prefix}-asg-sg-"
  description = "Security group for ${var.project_name} ${var.environment} ASG"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-asg-sg"
      Type = "asg-security-group"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rules
resource "aws_security_group_rule" "ingress" {
  count = var.create_security_group ? length(var.ingress_rules) : 0
  
  description              = var.ingress_rules[count.index].description
  from_port                = var.ingress_rules[count.index].from_port
  to_port                  = var.ingress_rules[count.index].to_port
  protocol                 = var.ingress_rules[count.index].protocol
  cidr_blocks              = var.ingress_rules[count.index].cidr_blocks
  source_security_group_id = var.ingress_rules[count.index].self ? aws_security_group.asg[0].id : null
  self                     = var.ingress_rules[count.index].self
  security_group_id        = aws_security_group.asg[0].id
  type                     = "ingress"
}

# Egress rules
resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? length(var.egress_rules) : 0
  
  description       = var.egress_rules[count.index].description
  from_port         = var.egress_rules[count.index].from_port
  to_port           = var.egress_rules[count.index].to_port
  protocol          = var.egress_rules[count.index].protocol
  cidr_blocks       = var.egress_rules[count.index].cidr_blocks
  self              = var.egress_rules[count.index].self
  security_group_id = aws_security_group.asg[0].id
  type              = "egress"
}

# ------------------------------------------------------------------------------
# Launch Template
# ------------------------------------------------------------------------------
resource "aws_launch_template" "asg" {
  name_prefix   = "${local.name_prefix}-lt-"
  description   = "Launch template for ${var.project_name} ${var.environment} ASG"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  user_data     = local.user_data
  
  monitoring {
    enabled = var.monitoring
  }
  
  # IMDS metadata options
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    http_protocol_ipv6          = var.metadata_options.http_protocol_ipv6
  }
  
  # IAM instance profile
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [var.iam_instance_profile] : []
    content {
      name = iam_instance_profile.value
    }
  }
  
  # Capacity reservation specification
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference
      dynamic "capacity_reservation_target" {
        for_each = length(capacity_reservation_specification.value.capacity_reservation_target) > 0 ? [capacity_reservation_specification.value.capacity_reservation_target] : []
        content {
          capacity_reservation_id = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }
  
  # Block device mappings
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      ebs {
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
        encrypted             = block_device_mappings.value.ebs.encrypted
        iops                  = block_device_mappings.value.ebs.iops
        kms_key_id            = block_device_mappings.value.ebs.kms_key_id
        snapshot_id           = block_device_mappings.value.ebs.snapshot_id
        throughput            = block_device_mappings.value.ebs.throughput
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
      }
    }
  }
  
  # Network interfaces
  network_interfaces {
    associate_public_ip_address = var.enable_public_ip_address
    delete_on_termination       = true
    device_index                = 0
    security_groups             = local.security_group_ids
  }
  
  # Tag specifications
  dynamic "tag_specifications" {
    for_each = ["instance", "volume"]
    content {
      resource_type = tag_specifications.value
      tags = merge(
        local.instance_tags,
        {
          Name = "${local.name_prefix}-instance"
        }
      )
    }
  }
  
  # Termination protection
  dynamic "instance_market_options" {
    for_each = var.enable_termination_protection ? [1] : []
    content {
      spot_options {
        spot_instance_type = "one-time"
      }
    }
  }
  
  tags = local.common_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Auto Scaling Group
# ------------------------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  name_prefix = "${local.name_prefix}-asg-"
  
  # Capacity configuration
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  
  # Default instance warmup
  default_instance_warmup = var.default_instance_warmup
  
  # Launch template configuration
  dynamic "launch_template" {
    for_each = !local.use_mixed_instances ? [1] : []
    content {
      id      = aws_launch_template.asg.id
      version = "$Latest"
    }
  }
  
  # Mixed instances policy configuration
  dynamic "mixed_instances_policy" {
    for_each = local.use_mixed_instances ? [var.mixed_instances_policy] : []
    content {
      instances_distribution {
        on_demand_base_capacity                  = mixed_instances_policy.value.instances_distribution.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = mixed_instances_policy.value.instances_distribution.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = mixed_instances_policy.value.instances_distribution.spot_allocation_strategy
        spot_instance_pools                      = mixed_instances_policy.value.instances_distribution.spot_instance_pools
        spot_max_price                           = mixed_instances_policy.value.spot_max_price
      }
      
      launch_template {
        id      = aws_launch_template.asg.id
        version = "$Latest"
      }
      
      dynamic "override" {
        for_each = mixed_instances_policy.value.override
        content {
          instance_type     = override.value.instance_type
          weighted_capacity = override.value.weighted_capacity
        }
      }
    }
  }
  
  # Network configuration
  vpc_zone_identifier = var.subnet_ids
  
  # Health checks
  health_check_type    = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  
  # Target groups
  target_group_arns = local.valid_target_group_arns
  
  # Capacity rebalancing
  capacity_rebalance = var.capacity_rebalance
  
  # Protect from scale-in
  dynamic "initial_lifecycle_hook" {
    for_each = var.protect_from_scale_in ? [{
      name                    = "protect-from-scale-in"
      default_result          = "CONTINUE"
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
      heartbeat_timeout       = 300
      lifecycle_hook_timeout  = 300
      notification_target_arn = null
      notification_metadata   = null
      role_arn                = null
    }] : []
    content {
      name                    = initial_lifecycle_hook.value.name
      default_result          = initial_lifecycle_hook.value.default_result
      lifecycle_transition    = initial_lifecycle_hook.value.lifecycle_transition
      heartbeat_timeout       = initial_lifecycle_hook.value.heartbeat_timeout
      lifecycle_hook_timeout  = initial_lifecycle_hook.value.lifecycle_hook_timeout
      notification_target_arn = initial_lifecycle_hook.value.notification_target_arn
      notification_metadata   = initial_lifecycle_hook.value.notification_metadata
      role_arn                = initial_lifecycle_hook.value.role_arn
    }
  }
  
  # Instance refresh
  dynamic "instance_refresh" {
    for_each = local.instance_refresh_enabled ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      preferences {
        min_healthy_percentage = instance_refresh.value.preferences.min_healthy_percentage
        instance_warmup        = instance_refresh.value.preferences.instance_warmup
      }
      triggers = instance_refresh.value.triggers
    }
  }
  
  # Tags
  dynamic "tag" {
    for_each = local.instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  # Additional tags that don't propagate
  tags = [
    {
      key                 = "Name"
      value               = "${local.name_prefix}-asg"
      propagate_at_launch = false
    },
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = false
    }
  ]
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_capacity,
      target_group_arns
    ]
  }
}

# ------------------------------------------------------------------------------
# Lifecycle Hooks
# ------------------------------------------------------------------------------
resource "aws_autoscaling_lifecycle_hook" "main" {
  count = length(var.lifecycle_hooks)
  
  name                   = var.lifecycle_hooks[count.index].name
  autoscaling_group_name = aws_autoscaling_group.main.name
  default_result         = var.lifecycle_hooks[count.index].default_result
  heartbeat_timeout      = var.lifecycle_hooks[count.index].heartbeat_timeout
  lifecycle_transition   = var.lifecycle_hooks[count.index].lifecycle_transition
  lifecycle_hook_timeout  = var.lifecycle_hooks[count.index].lifecycle_hook_timeout
  notification_target_arn = var.lifecycle_hooks[count.index].notification_target_arn
  notification_metadata  = var.lifecycle_hooks[count.index].notification_metadata
  role_arn               = var.lifecycle_hooks[count.index].role_arn
}

# ------------------------------------------------------------------------------
# Scaling Policies
# ------------------------------------------------------------------------------

# Target Tracking Scaling Policies
resource "aws_autoscaling_policy" "target_tracking" {
  count                   = local.scaling_policies_enabled ? length(var.target_tracking_scaling_policies) : 0
  name                    = var.target_tracking_scaling_policies[count.index].name
  autoscaling_group_name  = aws_autoscaling_group.main.name
  policy_type             = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.target_tracking_scaling_policies[count.index].predefined_metric_type
    }
    target_value       = var.target_tracking_scaling_policies[count.index].target_value
    disable_scale_in   = var.target_tracking_scaling_policies[count.index].disable_scale_in
  }
}

# Step Scaling Policies
resource "aws_autoscaling_policy" "step_scaling" {
  count                   = length(var.step_scaling_policies)
  name                    = var.step_scaling_policies[count.index].name
  autoscaling_group_name  = aws_autoscaling_group.main.name
  policy_type             = "SimpleScaling"
  adjustment_type         = var.step_scaling_policies[count.index].adjustment_type
  scaling_adjustment      = var.step_scaling_policies[count.index].scaling_adjustment
  metric_aggregation_type = var.step_scaling_policies[count.index].metric_aggregation_type
  cooldown                = var.step_scaling_policies[count.index].cooldown
}

# Scheduled Scaling Policies
resource "aws_autoscaling_schedule" "main" {
  count                  = length(var.scheduled_scaling_policies)
  scheduled_action_name  = var.scheduled_scaling_policies[count.index].scheduled_action_name
  autoscaling_group_name = aws_autoscaling_group.main.name
  
  min_size              = var.scheduled_scaling_policies[count.index].min_size
  max_size              = var.scheduled_scaling_policies[count.index].max_size
  desired_capacity      = var.scheduled_scaling_policies[count.index].desired_capacity
  recurrence            = var.scheduled_scaling_policies[count.index].recurrence
  start_time            = var.scheduled_scaling_policies[count.index].start_time
  end_time              = var.scheduled_scaling_policies[count.index].end_time
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "main" {
  count = local.cloudwatch_alarms_enabled ? length(var.cloudwatch_alarms) : 0
  
  alarm_name          = var.cloudwatch_alarms[count.index].name
  alarm_description   = var.cloudwatch_alarms[count.index].description
  comparison_operator = var.cloudwatch_alarms[count.index].comparison_operator
  evaluation_periods  = var.cloudwatch_alarms[count.index].evaluation_periods
  period              = var.cloudwatch_alarms[count.index].period
  statistic           = var.cloudwatch_alarms[count.index].statistic
  threshold           = var.cloudwatch_alarms[count.index].threshold
  metric_name         = var.cloudwatch_alarms[count.index].metric_name
  namespace           = var.cloudwatch_alarms[count.index].namespace
  
  dynamic "dimensions" {
    for_each = var.cloudwatch_alarms[count.index].dimensions
    content {
      name  = dimensions.key
      value = dimensions.value
    }
  }
  
  alarm_actions = var.cloudwatch_alarms[count.index].alarm_actions
  ok_actions    = var.cloudwatch_alarms[count.index].ok_actions
  
  tags = local.common_tags
}