# EC2 Auto Scaling Group Module Examples

This directory contains comprehensive examples demonstrating various use cases and configurations of the EC2 Auto Scaling Group module.

## 📁 Example Directory Structure

```
examples/
├── basic-usage/           # Simple ASG configuration
├── advanced-usage/        # Advanced features with load balancer
├── mixed-instances/       # Cost optimization with Spot instances
├── lifecycle-hooks/       # Lifecycle hook configurations
├── complete-production/   # Full production-ready setup
└── README.md             # This file
```

## 🚀 Quick Start Examples

### 1. Basic Usage (`basic-usage/`)

**Best for:** Getting started with a simple ASG setup

**Features:**
- Basic instance configuration
- Simple capacity management
- Default security settings
- Basic scaling policies

**Run:**
```bash
cd basic-usage
terraform init
terraform plan
terraform apply
```

### 2. Advanced Usage (`advanced-usage/`)

**Best for:** Production applications requiring load balancer integration

**Features:**
- Load balancer integration
- Custom security groups
- Multiple scaling policies
- Detailed monitoring
- Instance refresh configuration

**Run:**
```bash
cd advanced-usage
terraform init
terraform plan
terraform apply
```

### 3. Mixed Instances (`mixed-instances/`)

**Best for:** Cost optimization with Spot instances

**Features:**
- Mixed instances policy
- Spot instance configuration
- Multiple instance types
- Capacity rebalancing
- Cost optimization

**Run:**
```bash
cd mixed-instances
terraform init
terraform plan
terraform apply
```

### 4. Lifecycle Hooks (`lifecycle-hooks/`)

**Best for:** Applications requiring custom launch/termination workflows

**Features:**
- Multiple lifecycle hooks
- SNS notifications
- Custom instance workflows
- Graceful shutdown
- Health check hooks

**Run:**
```bash
cd lifecycle-hooks
terraform init
terraform plan
terraform apply
```

### 5. Complete Production (`complete-production/`)

**Best for:** Production-ready infrastructure with all features

**Features:**
- Full production configuration
- Enhanced security settings
- Comprehensive monitoring
- Multiple scaling policies
- Scheduled scaling
- Advanced lifecycle management
- CloudWatch alarms
- Detailed tagging strategy

**Run:**
```bash
cd complete-production
terraform init
terraform plan
terraform apply
```

## 📋 Prerequisites

All examples require:

1. **AWS Credentials**: Configure AWS CLI or environment variables
   ```bash
   aws configure
   ```

2. **Terraform**: Install Terraform >= 1.0.0
   ```bash
   terraform version
   ```

3. **AWS Resources**: Ensure required AWS resources exist:
   - VPC
   - Subnets
   - Security Groups (if not creating automatically)
   - Load Balancers (if using load balancer integration)
   - IAM Roles (if using instance profiles)

4. **Provider Configuration**: Update provider configuration in each example

## 🔧 Customizing Examples

### Required Variables to Update

Before running any example, you must update these variables:

#### VPC Configuration
```hcl
# Replace with your VPC ID
vpc_id = "vpc-1234567890abcdef0"

# Replace with your subnet IDs
subnet_ids = [
  "subnet-1234567890abcdef0",
  "subnet-0987654321fedcba0"
]
```

#### Security Resources
```hcl
# Replace with your security group ID (if not creating automatically)
security_group_ids = ["sg-1234567890abcdef0"]

# Replace with your key pair name
key_pair_name = "your-ssh-key"
```

#### Load Balancer Integration
```hcl
# Replace with your target group ARN
target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/abcd1234"]

# Specify load balancer type
load_balancer_type = "application"
```

#### IAM Configuration
```hcl
# Replace with your instance profile
iam_instance_profile = "your-instance-profile"
```

#### Notification Configuration
```hcl
# Replace with your SNS topic ARN
notification_target_arn = "arn:aws:sns:us-east-1:123456789012:your-topic"
```

## 🎯 Example Use Cases

### Web Application Scaling
**Example:** `advanced-usage/` or `complete-production/`

**When to use:**
- Web servers behind an ALB
- Variable traffic patterns
- Need for high availability
- Load balancer integration

### Batch Processing
**Example:** `mixed-instances/`

**When to use:**
- Intermittent workloads
- Cost-sensitive applications
- Can handle interruptions
- No persistent connections

### API Services
**Example:** `advanced-usage/`

**When to use:**
- REST APIs
- Microservices
- Need for consistent performance
- Load balancer required

### Background Workers
**Example:** `basic-usage/` or `mixed-instances/`

**When to use:**
- Asynchronous job processing
- Queue consumers
- Scheduled tasks
- Cost optimization important

## 🔍 Testing Examples

### Plan and Review
```bash
# Preview changes without applying
terraform plan -out=tfplan

# Review the plan
terraform show tfplan
```

### Apply Changes
```bash
# Apply the configuration
terraform apply tfplan

# Or apply with auto-approval
terraform apply -auto-approve
```

### Verify Deployment
```bash
# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name>

# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=<project-name>"

# Check scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name>
```

## 📊 Monitoring Examples

### CloudWatch Metrics
After deploying, monitor these key metrics:

- **CPU Utilization**: `AWS/AutoScaling` namespace
- **Instance Count**: `AWS/AutoScaling` namespace
- **Health Check Status**: `AWS/AutoScaling` namespace
- **Scaling Activities**: CloudTrail logs

### CloudWatch Alarms
Examples include alarms for:
- High CPU utilization
- High memory usage
- Scaling activity anomalies
- Instance termination

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Remove all resources
terraform destroy

# Or with auto-approval
terraform destroy -auto-approve
```

### Clean Up Resources Manually
```bash
# Delete orphaned instances
aws ec2 terminate-instances --instance-ids <instance-id>

# Delete security groups
aws ec2 delete-security-group --group-id <sg-id>

# Remove SNS subscriptions
aws sns unsubscribe --subscription-arn <subscription-arn>
```

## 🐛 Troubleshooting Examples

### Common Issues

1. **VPC ID Not Found**
   - Verify VPC exists in the region
   - Check AWS credentials and region
   - Ensure VPC ID is correct

2. **Subnet Not Available**
   - Verify subnets exist in the VPC
   - Check subnet availability zones
   - Ensure subnet IDs are correct

3. **Instance Launch Failures**
   - Verify AMI is available in the region
   - Check security group rules
   - Review IAM permissions

4. **Scaling Not Working**
   - Check scaling policy metrics
   - Verify CloudWatch permissions
   - Review scaling activities in AWS Console

## 📚 Additional Resources

- [Module README](../README.md) - Complete module documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Auto Scaling Guide](https://docs.aws.amazon.com/autoscaling/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## 💡 Tips for Running Examples

1. **Start Simple**: Begin with `basic-usage/` before advanced examples
2. **Test in Dev**: Always test in non-production environments first
3. **Monitor Costs**: Set up budget alerts for AWS resources
4. **Review Outputs**: Check Terraform outputs after deployment
5. **Document Changes**: Keep track of customizations you make

## 🤝 Contributing

To contribute new examples:

1. Create a new directory under `examples/`
2. Add a `main.tf` file with clear comments
3. Include `README.md` with usage instructions
4. Update this `README.md` with your example
5. Follow Terraform best practices

## 📞 Support

For issues with examples:
1. Check the [Troubleshooting](#-troubleshooting-examples) section
2. Review Terraform logs: `terraform show`
3. Check AWS CloudTrail for API calls
4. Verify AWS resource limits and quotas