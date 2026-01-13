# Terraform EC2 Auto Scaling Group Module

A production-grade, highly reusable Terraform module for managing EC2 instances with Auto Scaling Group (ASG) capabilities. This module provides comprehensive configuration options for building scalable, resilient infrastructure on AWS.

## 🚀 Features

- **Flexible Instance Configuration**: Support for various EC2 instance types, AMI selection strategies, and advanced instance options
- **Advanced Scaling Policies**: Target tracking, step scaling, and scheduled scaling policies
- **Mixed Instances Policy**: Support for Spot instances and multiple instance types
- **Security Group Management**: Optional automatic security group creation with configurable rules
- **Load Balancer Integration**: Seamless integration with Application, Network, and Gateway Load Balancers
- **Lifecycle Hooks**: Configure lifecycle hooks for custom instance launch/termination workflows
- **Health Checks**: Comprehensive health check configuration for EC2 and ELB
- **Instance Refresh**: Automated rolling updates for instances
- **CloudWatch Monitoring**: Built-in CloudWatch alarms and monitoring
- **Cost Optimization**: Spot instance support and capacity rebalancing
- **Enhanced Security**: Encryption options, IMDS hardening, and termination protection

## 📋 Requirements

- Terraform >= 1.0.0
- AWS Provider >= 4.0.0
- AWS credentials configured

## 🔧 Installation

Copy this module to your Terraform project:

```bash
git clone <repository-url> modules/ec2-asg
```

Or reference it directly from your Terraform configuration:

```hcl
module "asg" {
  source = "./modules/ec2-asg"
  
  # Required variables
  project_name = "my-app"
  environment  = "prod"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]
  
  # Optional variables with defaults
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 10
}
```

## 📖 Usage Examples

### Basic Usage

```hcl
module "web_asg" {
  source = "./modules/ec2-asg"
  
  project_name = "web-app"
  environment  = "prod"
  region       = "us-east-1"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 10
  desired_capacity = 4
  
  tags = {
    Team        = "Infrastructure"
    Application = "WebApp"
  }
}
```

### Advanced Configuration with Load Balancer

```hcl
module "app_asg" {
  source = "./modules/ec2-asg"
  
  project_name = "application"
  environment  = "prod"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  instance_type = "t3.xlarge"
  min_size      = 3
  max_size      = 15
  desired_capacity = 6
  
  # Load Balancer Integration
  target_group_arns = [module.alb.target_group_arn]
  load_balancer_type = "application"
  health_check_type  = "ELB"
  
  # Security Group
  create_security_group = true
  ingress_rules = [
    {
      description = "Allow HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = false
    }
  ]
  
  # Custom AMI
  ami_id = "ami-1234567890abcdef0"
  
  # IAM Role
  iam_instance_profile = "ec2-instance-profile"
  
  # User Data
  user_data = templatefile("${path.module}/user_data.sh", {
    db_endpoint = module.rds.endpoint
  })
  
  tags = {
    Application = "BackendAPI"
  }
}
```

### Mixed Instances Policy with Spot Instances

```hcl
module "spot_asg" {
  source = "./modules/ec2-asg"
  
  project_name = "batch-processing"
  environment  = "prod"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  instance_type = "t3.medium"
  min_size      = 0
  max_size      = 100
  
  # Mixed Instances Policy
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
      spot_instance_pools                      = 10
      spot_max_price                           = ""
    }
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
      }
    ]
  }
  
  # Enable capacity rebalancing
  capacity_rebalance = true
  
  tags = {
    CostCenter = "Compute"
  }
}
```

### Custom Scaling Policies

```hcl
module "scaled_asg" {
  source = "./modules/ec2-asg"
  
  project_name = "microservices"
  environment  = "prod"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 20
  
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
      name                   = "memory-utilization"
      target_metric          = "customized"
      predefined_metric_type = null
      customized_metric_spec = {
        metric_name = "MemoryUtilization"
        namespace   = "CWAgent"
        statistic   = "Average"
        unit        = "Percent"
      }
      target_value          = 80.0
      disable_scale_in      = false
      scale_in_cooldown     = 300
      scale_out_cooldown    = 60
    }
  ]
  
  # Scheduled Scaling
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
      min_size            = 2
      max_size            = 5
      desired_capacity    = 2
      recurrence          = "0 18 * * MON-FRI"
      start_time          = "2024-01-01T18:00:00Z"
    }
  ]
  
  tags = {
    Scheduler = "BusinessHours"
  }
}
```

### Instance Refresh Configuration

```hcl
module "refresh_asg" {
  source = "./modules/ec2-asg"
  
  project_name = "api-server"
  environment  = "prod"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  instance_type = "t3.medium"
  min_size      = 4
  max_size      = 8
  
  # Instance Refresh for rolling updates
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }
  
  tags = {
    Component = "API"
  }
}
```

## 🔑 Input Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `project_name` | `string` | Project name used for tagging and naming resources |
| `environment` | `string` | Environment name (dev, staging, prod, test) |
| `vpc_id` | `string` | VPC ID where resources will be created |
| `subnet_ids` | `list(string)` | List of subnet IDs where instances will be launched |

### Instance Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_type` | `string` | `"t3.medium"` | EC2 instance type |
| `ami_id` | `string` | `null` | Custom AMI ID (null = uses latest Amazon Linux 2) |
| `ami_filter` | `object` | See defaults | AMI filter for dynamic selection |
| `key_pair_name` | `string` | `null` | SSH key pair name |
| `user_data` | `string` | `null` | User data script |
| `iam_instance_profile` | `string` | `null` | IAM instance profile |
| `monitoring` | `bool` | `false` | Enable detailed monitoring |
| `metadata_options` | `object` | See defaults | IMDS metadata options |

### Auto Scaling Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `min_size` | `number` | `1` | Minimum number of instances |
| `max_size` | `number` | `5` | Maximum number of instances |
| `desired_capacity` | `number` | `null` | Desired number of instances |
| `default_instance_warmup` | `number` | `300` | Instance warmup time in seconds |
| `capacity_rebalance` | `bool` | `false` | Enable capacity rebalancing |

### Scaling Policies

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_scaling_policies` | `bool` | `true` | Enable automatic scaling policies |
| `target_tracking_scaling_policies` | `list(object)` | See defaults | Target tracking policies |
| `step_scaling_policies` | `list(object)` | `[]` | Step scaling policies |
| `scheduled_scaling_policies` | `list(object)` | `[]` | Scheduled scaling policies |

### Network & Security

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `security_group_ids` | `list(string)` | `[]` | Security group IDs |
| `create_security_group` | `bool` | `false` | Create dedicated security group |
| `ingress_rules` | `list(object)` | `[]` | Ingress rules for security group |
| `egress_rules` | `list(object)` | See defaults | Egress rules for security group |

### Health Checks & Monitoring

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `health_check_type` | `string` | `"EC2"` | Health check type (EC2, ELB, or EC2,ELB) |
| `health_check_grace_period` | `number` | `300` | Health check grace period |
| `enable_cloudwatch_alarms` | `bool` | `true` | Enable CloudWatch alarms |
| `cloudwatch_alarms` | `list(object)` | `[]` | Custom CloudWatch alarm configurations |

### Additional Features

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `target_group_arns` | `list(string)` | `[]` | Target group ARNs for load balancer |
| `lifecycle_hooks` | `list(object)` | `[]` | Lifecycle hook configurations |
| `mixed_instances_policy` | `object` | `null` | Mixed instances policy configuration |
| `tags` | `map(string)` | `{}` | Common tags for all resources |
| `instance_tags` | `map(string)` | `{}` | Tags for instances |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `autoscaling_group_id` | ID of the Auto Scaling Group |
| `autoscaling_group_name` | Name of the Auto Scaling Group |
| `autoscaling_group_arn` | ARN of the Auto Scaling Group |
| `launch_template_id` | ID of the Launch Template |
| `launch_template_name` | Name of the Launch Template |
| `launch_template_arn` | ARN of the Launch Template |
| `security_group_id` | ID of the ASG Security Group (if created) |
| `security_group_ids` | List of security group IDs applied to instances |
| `target_tracking_policy_ids` | IDs of target tracking scaling policies |
| `step_scaling_policy_ids` | IDs of step scaling policies |
| `scheduled_scaling_policy_ids` | IDs of scheduled scaling policies |
| `cloudwatch_alarm_arns` | ARNs of CloudWatch alarms |
| `asg_configuration` | Complete ASG configuration object |
| `scaling_configuration` | Scaling policy configuration object |

## 🔒 Security Best Practices

This module implements several security best practices:

1. **IMDS Hardening**: Configures Instance Metadata Service (IMDS) with secure defaults
2. **Encryption**: EBS volume encryption enabled by default
3. **Security Groups**: Optional dedicated security group with configurable rules
4. **IAM Integration**: Support for instance profiles with least privilege
5. **Termination Protection**: Optional protection against accidental termination
6. **Network Isolation**: Support for private subnet deployment

## 💡 Tips and Best Practices

1. **Use Target Tracking Scaling**: Prefer target tracking policies over simple scaling for more responsive scaling
2. **Implement Mixed Instances Policy**: Use Spot instances for cost savings in appropriate workloads
3. **Configure Health Checks Properly**: Use ELB health checks when using load balancers
4. **Set Appropriate Warmup Times**: Configure instance warmup based on your application startup time
5. **Use Instance Refresh**: Enable instance refresh for rolling updates during deployments
6. **Monitor Scaling Activities**: Use CloudWatch logs to track scaling activities
7. **Test Scaling Policies**: Validate scaling policies in non-production environments first

## 🐛 Troubleshooting

### Instances Not Scaling
- Check scaling policy metrics are being collected
- Verify minimum and maximum size settings
- Review CloudWatch logs for scaling activities

### Health Check Failures
- Ensure health check grace period is sufficient for application startup
- Verify security groups allow health check traffic
- Check application health endpoints are accessible

### Instance Launch Failures
- Verify AMI is available in the target region
- Check subnet configurations and network ACLs
- Review IAM permissions for instance profiles

## 📚 Additional Resources

- [AWS Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [CloudWatch Metrics for Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-metrics.html)

## 📝 License

This module is provided as-is for use in your infrastructure projects.

## 🤝 Contributing

Contributions are welcome! Please ensure all changes follow Terraform best practices and include appropriate documentation.

## 📞 Support

For issues, questions, or contributions related to this module, please open an issue in the repository.