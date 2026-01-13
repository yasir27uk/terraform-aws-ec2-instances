# Basic EC2 Auto Scaling Group Example
# This example demonstrates a simple ASG configuration with default settings

provider "aws" {
  region = "us-east-1"
}

module "basic_asg" {
  source = "../.."
  
  # Required Configuration
  project_name = "basic-web-app"
  environment  = "dev"
  region       = "us-east-1"
  
  # Network Configuration
  vpc_id     = "vpc-1234567890abcdef0"  # Replace with your VPC ID
  subnet_ids = [
    "subnet-1234567890abcdef0",  # Replace with your subnet IDs
    "subnet-0987654321fedcba0"
  ]
  
  # Instance Configuration
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 5
  
  # Tags
  tags = {
    Owner       = "DevOps"
    CostCenter  = "Engineering"
    Application = "WebApp"
  }
}

# Output the ASG details
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.basic_asg.autoscaling_group_name
}

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.basic_asg.autoscaling_group_id
}

output "launch_template_name" {
  description = "Name of the Launch Template"
  value       = module.basic_asg.launch_template_name
}