# EC2 Auto Scaling Group Module - Deployment Guide

This comprehensive guide will help you deploy the EC2 Auto Scaling Group module in your AWS environment.

## 📋 Prerequisites

Before deploying, ensure you have:

### Required Tools
- **Terraform** >= 1.0.0
- **AWS CLI** configured with appropriate credentials
- **Git** for cloning the repository

### Required AWS Resources
- **VPC** with at least one subnet
- **IAM Role** (optional, for instance profiles)
- **Security Groups** (optional, can be created by module)
- **Load Balancer** (optional, for load balancer integration)
- **KMS Key** (optional, for encryption)

### Required Permissions
Your AWS account must have permissions to:
- Create and manage EC2 instances
- Create and manage Auto Scaling Groups
- Create and manage Security Groups
- Create and manage IAM roles (if using instance profiles)
- Create and manage CloudWatch alarms
- Create and manage SNS topics (if using notifications)

## 🚀 Quick Start Deployment

### 1. Clone the Repository

```bash
git clone <repository-url>
cd terraform-aws-ec2-asg
```

### 2. Configure AWS Credentials

```bash
# Using AWS CLI
aws configure

# Or using environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. Choose an Example

Start with one of the provided examples:

```bash
# Basic deployment
cd examples/basic-usage

# Advanced deployment
cd examples/advanced-usage

# Cost-optimized deployment
cd examples/mixed-instances

# Production deployment
cd examples/complete-production
```

### 4. Customize Configuration

Edit the `main.tf` file to match your requirements:

```hcl
module "my_asg" {
  source = "../.."
  
  # Required - Update these
  project_name = "my-application"
  environment  = "dev"
  vpc_id       = "vpc-1234567890abcdef0"  # Your VPC ID
  subnet_ids   = ["subnet-1234567890abcdef0"]  # Your subnet IDs
  
  # Optional - Customize as needed
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 5
}
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Preview Changes

```bash
terraform plan
```

Review the output to ensure resources will be created as expected.

### 7. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 8. Verify Deployment

```bash
# Check Terraform outputs
terraform output

# Verify ASG in AWS Console
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_name)

# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=my-application"
```

## 📊 Deployment Scenarios

### Scenario 1: Basic Web Application

**Use Case:** Simple web application without load balancer

**Configuration:**
```hcl
module "web_asg" {
  source = "../.."
  
  project_name = "web-app"
  environment  = "dev"
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids
  
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 4
}
```

**Resources Created:**
- Auto Scaling Group
- Launch Template
- EC2 Instances (2-4)
- Security Groups (if `create_security_group = true`)

### Scenario 2: Load Balanced Application

**Use Case:** Application behind an Application Load Balancer

**Configuration:**
```hcl
module "app_asg" {
  source = "../.."
  
  project_name = "api-app"
  environment  = "prod"
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids
  
  instance_type = "t3.medium"
  min_size      = 3
  max_size      = 10
  
  # Load Balancer Integration
  target_group_arns = [var.alb_target_group_arn]
  load_balancer_type = "application"
  health_check_type  = "ELB"
  
  # Scaling Policies
  target_tracking_scaling_policies = [
    {
      name                   = "cpu-target"
      target_metric          = "predefined"
      predefined_metric_type = "ASGAverageCPUUtilization"
      target_value          = 70.0
    }
  ]
}
```

**Resources Created:**
- Auto Scaling Group with ALB integration
- Launch Template
- Target tracking scaling policy
- EC2 Instances (3-10)

### Scenario 3: Cost-Optimized Batch Processing

**Use Case:** Batch processing with Spot instances for cost savings

**Configuration:**
```hcl
module "batch_asg" {
  source = "../.."
  
  project_name = "batch-jobs"
  environment  = "prod"
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids
  
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
    }
    override = [
      { instance_type = "t3.medium", weighted_capacity = 1 },
      { instance_type = "t3.large", weighted_capacity = 2 }
    ]
  }
  
  capacity_rebalance = true
}
```

**Resources Created:**
- Auto Scaling Group with mixed instances policy
- Launch Template
- Spot and On-Demand instances
- Capacity rebalancing enabled

### Scenario 4: Production Workload with Full Monitoring

**Use Case:** Production application with comprehensive monitoring

**Configuration:**
```hcl
module "prod_asg" {
  source = "../.."
  
  project_name = "production-app"
  environment  = "prod"
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids
  
  instance_type = "t3.xlarge"
  min_size      = 4
  max_size      = 20
  
  # Enhanced Security
  create_security_group = true
  ingress_rules = [
    {
      description = "HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
  
  # Monitoring
  enable_cloudwatch_alarms = true
  cloudwatch_alarms = [
    {
      name                = "high-cpu-alarm"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods   = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
    }
  ]
  
  # Lifecycle Hooks
  lifecycle_hooks = [
    {
      name                   = "wait-for-health"
      default_result         = "CONTINUE"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
      heartbeat_timeout      = 600
      lifecycle_hook_timeout  = 900
    }
  ]
}
```

**Resources Created:**
- Auto Scaling Group with full monitoring
- Launch Template
- Security Groups
- CloudWatch Alarms
- Lifecycle Hooks
- EC2 Instances with health checks

## 🔒 Security Best Practices

### 1. Use Private Subnets

```hcl
subnet_ids = var.private_subnet_ids  # Not public subnets
enable_public_ip_address = false
```

### 2. Enable IMDSv2

```hcl
metadata_options = {
  http_endpoint               = "enabled"
  http_tokens                 = "required"  # Force IMDSv2
  http_put_response_hop_limit = 1
}
```

### 3. Encrypt EBS Volumes

```hcl
block_device_mappings = [
  {
    device_name = "/dev/xvda"
    ebs = {
      encrypted  = true
      kms_key_id = var.kms_key_id  # Your KMS key
    }
  }
]
```

### 4. Use IAM Instance Profiles

```hcl
iam_instance_profile = "your-ec2-instance-profile"
```

### 5. Configure Security Groups

```hcl
create_security_group = true
ingress_rules = [
  {
    description = "HTTP from specific CIDR only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Restricted CIDR
  }
]
```

## 📈 Monitoring and Alerting

### CloudWatch Metrics

After deployment, monitor these key metrics:

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=$(terraform output -raw autoscaling_group_name) \
  --statistics Average \
  --period 300 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)
```

### Scaling Activities

```bash
# Check recent scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name $(terraform output -raw autoscaling_group_name) \
  --max-items 10
```

### Instance Health

```bash
# Check instance health status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_name) \
  --query 'AutoScalingGroups[0].Instances[*].{Id:InstanceId,State:LifecycleState,Health:HealthStatus}'
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Instance Launch Failures

**Symptoms:** Instances fail to launch or are terminated immediately

**Solutions:**
```bash
# Check scaling activities for error messages
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name $(terraform output -raw autoscaling_group_name)

# Verify AMI is available
aws ec2 describe-images --image-ids $(terraform output -raw ami_id)

# Check security group rules
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
```

#### 2. Scaling Not Working

**Symptoms:** Auto Scaling doesn't scale in or out

**Solutions:**
```bash
# Check scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name $(terraform output -raw autoscaling_group_name)

# Verify CloudWatch metrics are being collected
aws cloudwatch list-metrics \
  --namespace AWS/AutoScaling \
  --metric-name GroupInServiceInstances

# Check min/max size limits
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_name) \
  --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity]'
```

#### 3. Health Check Failures

**Symptoms:** Instances marked as unhealthy

**Solutions:**
```bash
# Check health check configuration
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw autoscaling_group_name) \
  --query 'AutoScalingGroups[0].[HealthCheckType,HealthCheckGracePeriod]'

# Increase grace period if needed
# Update health_check_grace_period variable and apply
```

## 🔄 Updating Deployments

### Rolling Updates

```bash
# Update instance type
# Modify instance_type in main.tf
terraform apply

# Instance refresh will automatically update instances
```

### Manual Instance Refresh

```bash
# Force instance refresh
terraform apply -replace=aws_launch_template.asg
```

### Changing Scaling Policies

```bash
# Update scaling policies in configuration
terraform plan  # Preview changes
terraform apply  # Apply new policies
```

## 🧹 Cleanup

### Destroy Infrastructure

```bash
terraform destroy
```

### Verify Cleanup

```bash
# Check for remaining resources
aws autoscaling describe-auto-scaling-groups
aws ec2 describe-instances --filters "Name=tag:Project,Values=my-application"

# Clean up any orphaned resources manually
```

## 📚 Additional Resources

- [Module README](README.md) - Complete module documentation
- [Examples](examples/README.md) - Additional deployment examples
- [AWS Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🆘 Support

For issues or questions:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review the [examples](examples/)
3. Open an issue on GitHub
4. Contact AWS Support for infrastructure issues

## 📝 Next Steps

After successful deployment:

1. **Set up monitoring**: Configure CloudWatch dashboards and alerts
2. **Optimize costs**: Review Spot instance usage and capacity
3. **Test scaling**: Simulate load to verify scaling behavior
4. **Document changes**: Update your infrastructure documentation
5. **Plan maintenance**: Schedule regular maintenance windows

---

**Happy Deploying! 🚀**