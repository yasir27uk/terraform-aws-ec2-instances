# Mixed Instances Policy with Spot Instances Example
# This example demonstrates cost optimization using mixed instances policy with Spot instances

provider "aws" {
  region = "us-east-1"
}

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

module "spot_asg" {
  source = "../.."
  
  # Required Configuration
  project_name = "batch-processing"
  environment  = "prod"
  region       = "us-east-1"
  
  # Network Configuration
  vpc_id       = data.aws_vpc.main.id
  subnet_ids   = data.aws_subnets.private.ids
  subnet_type  = "private"
  
  # Instance Configuration (base type)
  instance_type = "t3.medium"
  
  # Capacity Configuration
  min_size      = 0        # Can scale to zero
  max_size      = 100      # High maximum for burst workloads
  desired_capacity = 10    # Initial capacity
  
  # Mixed Instances Policy Configuration
  mixed_instances_policy = {
    # Distribution of instances
    instances_distribution = {
      # No on-demand instances in base
      on_demand_base_capacity                  = 0
      # 20% on-demand above base, rest spot
      on_demand_percentage_above_base_capacity = 20
      # Use capacity-optimized strategy for spot instances
      spot_allocation_strategy                 = "capacity-optimized"
      # Use up to 10 spot instance pools
      spot_instance_pools                      = 10
      # No maximum price (use current spot price)
      spot_max_price                           = ""
    }
    
    # Override with multiple instance types
    override = [
      {
        instance_type     = "t3.medium"
        weighted_capacity = 1
        launch_template = {
          override = {
            instance_type     = "t3.medium"
            weighted_capacity = 1
          }
        }
      },
      {
        instance_type     = "t3.large"
        weighted_capacity = 2
        launch_template = {
          override = {
            instance_type     = "t3.large"
            weighted_capacity = 2
          }
        }
      },
      {
        instance_type     = "t3.xlarge"
        weighted_capacity = 4
        launch_template = {
          override = {
            instance_type     = "t3.xlarge"
            weighted_capacity = 4
          }
        }
      },
      {
        instance_type     = "t3.2xlarge"
        weighted_capacity = 8
        launch_template = {
          override = {
            instance_type     = "t3.2xlarge"
            weighted_capacity = 8
          }
        }
      }
    ]
  }
  
  # Enable capacity rebalancing to replace instances when spot interruption occurs
  capacity_rebalance = true
  
  # Security Group
  create_security_group = true
  ingress_rules = [
    {
      description = "Allow application traffic"
      from_port   = 8080
      to_port     = 8080
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
      target_value          = 80.0
      disable_scale_in      = false
      scale_in_cooldown     = 600
      scale_out_cooldown    = 120
    }
  ]
  
  # Instance Refresh for rolling updates
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 75  # Lower percentage for faster updates
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }
  
  # Tags
  tags = {
    CostOptimization  = "SpotInstances"
    WorkloadType      = "BatchProcessing"
    Interruptible     = "true"
  }
  
  instance_tags = {
    SpotInstance = "true"
  }
}

# Outputs
output "asg_details" {
  description = "ASG details"
  value = {
    name              = module.spot_asg.autoscaling_group_name
    id                = module.spot_asg.autoscaling_group_id
    min_size          = module.spot_asg.autoscaling_group_min_size
    max_size          = module.spot_asg.autoscaling_group_max_size
    desired_capacity  = module.spot_asg.autoscaling_group_desired_capacity
    instance_types    = ["t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"]
  }
}

output "cost_optimization_info" {
  description = "Cost optimization configuration"
  value = {
    strategy               = "mixed-instances-policy"
    spot_allocation_strategy = "capacity-optimized"
    capacity_rebalance     = true
    estimated_savings      = "70-90% compared to on-demand"
  }
}