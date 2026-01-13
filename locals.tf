# Local variables for derived values and consistent resource naming

locals {
  # Common tags merged with additional tags
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
  
  # Final tags for instances (common + instance-specific)
  instance_tags = merge(
    local.common_tags,
    var.instance_tags,
    var.additional_tags
  )
  
  # Resource name prefix for consistent naming
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Dynamic AMI selection
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu[0].id
  
  # User data selection
  user_data = var.user_data_base64 != null ? var.user_data_base64 : (
    var.user_data != null ? base64encode(var.user_data) : null
  )
  
  # Security group handling
  security_group_ids = var.create_security_group ? [aws_security_group.asg[0].id] : var.security_group_ids
  
  # Target group ARNs validation
  valid_target_group_arns = var.load_balancer_type != null ? var.target_group_arns : []
  
  # Scaling policy enabled status
  scaling_policies_enabled = var.enable_scaling_policies
  
  # CloudWatch alarms enabled status
  cloudwatch_alarms_enabled = var.enable_cloudwatch_alarms
  
  # Mixed instances policy configuration
  use_mixed_instances = var.mixed_instances_policy != null
  
  # Instance refresh enabled status
  instance_refresh_enabled = var.instance_refresh != null
}

# Dynamic AMI data source
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_filter.owner]
  
  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }
  
  filter {
    name   = "virtualization-type"
    values = [var.ami_filter.virtualization_type]
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}