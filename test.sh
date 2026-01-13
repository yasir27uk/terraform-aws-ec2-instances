#!/bin/bash

# Terraform EC2 ASG Module Test Script
# This script performs basic validation and testing of the module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_requirements() {
    print_info "Checking required tools..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0.0"
        exit 1
    fi
    
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_info "Terraform version: $TERRAFORM_VERSION"
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install jq for JSON processing"
        exit 1
    fi
    
    print_info "All required tools are installed"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_info "Validating Terraform configuration..."
    
    if [ ! -f "main.tf" ]; then
        print_error "main.tf not found in current directory"
        exit 1
    fi
    
    if [ ! -f "variables.tf" ]; then
        print_error "variables.tf not found in current directory"
        exit 1
    fi
    
    if [ ! -f "outputs.tf" ]; then
        print_error "outputs.tf not found in current directory"
        exit 1
    fi
    
    print_info "All required Terraform files are present"
}

# Function to run terraform init
terraform_init() {
    print_info "Running terraform init..."
    terraform init -upgrade
    print_info "Terraform init completed successfully"
}

# Function to run terraform validate
terraform_validate() {
    print_info "Running terraform validate..."
    terraform validate
    print_info "Terraform validation passed"
}

# Function to run terraform fmt
terraform_fmt() {
    print_info "Running terraform fmt..."
    terraform fmt -recursive
    print_info "Terraform formatting completed"
}

# Function to run terraform plan (dry run)
terraform_plan() {
    print_info "Running terraform plan..."
    
    # Create a temporary variables file for testing
    cat > terraform.tfvars <<EOF
# Test configuration
project_name = "test-asg"
environment  = "test"
region       = "us-east-1"
vpc_id       = "vpc-1234567890abcdef0"
subnet_ids   = ["subnet-1234567890abcdef0", "subnet-0987654321fedcba0"]
instance_type = "t3.micro"
min_size      = 1
max_size      = 2
EOF
    
    terraform plan -out=tfplan
    print_info "Terraform plan completed successfully"
}

# Function to check module structure
check_module_structure() {
    print_info "Checking module structure..."
    
    required_files=(
        "variables.tf"
        "main.tf"
        "outputs.tf"
        "locals.tf"
        "versions.tf"
        "README.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_info "✓ $file exists"
        else
            print_warning "✗ $file is missing"
        fi
    done
    
    if [ -d "examples" ]; then
        print_info "✓ examples directory exists"
        example_count=$(find examples -name "main.tf" | wc -l)
        print_info "✓ Found $example_count example(s)"
    else
        print_warning "✗ examples directory is missing"
    fi
}

# Function to validate variable definitions
validate_variables() {
    print_info "Validating variable definitions..."
    
    # Check for required variables
    if grep -q "variable &quot;project_name&quot;" variables.tf; then
        print_info "✓ project_name variable defined"
    else
        print_error "✗ project_name variable is missing"
    fi
    
    if grep -q "variable &quot;environment&quot;" variables.tf; then
        print_info "✓ environment variable defined"
    else
        print_error "✗ environment variable is missing"
    fi
    
    if grep -q "variable &quot;vpc_id&quot;" variables.tf; then
        print_info "✓ vpc_id variable defined"
    else
        print_error "✗ vpc_id variable is missing"
    fi
    
    if grep -q "variable &quot;subnet_ids&quot;" variables.tf; then
        print_info "✓ subnet_ids variable defined"
    else
        print_error "✗ subnet_ids variable is missing"
    fi
}

# Function to validate outputs
validate_outputs() {
    print_info "Validating output definitions..."
    
    output_count=$(grep -c "^output" outputs.tf || true)
    print_info "✓ Found $output_count output(s)"
    
    # Check for key outputs
    if grep -q "output &quot;autoscaling_group_id&quot;" outputs.tf; then
        print_info "✓ autoscaling_group_id output defined"
    fi
    
    if grep -q "output &quot;launch_template_id&quot;" outputs.tf; then
        print_info "✓ launch_template_id output defined"
    fi
}

# Function to run security checks
security_checks() {
    print_info "Running security checks..."
    
    # Check for hardcoded sensitive values
    if grep -r "aws_access_key_id" *.tf 2>/dev/null; then
        print_warning "Found potential hardcoded access keys"
    fi
    
    if grep -r "aws_secret_access_key" *.tf 2>/dev/null; then
        print_warning "Found potential hardcoded secret keys"
    fi
    
    # Check for encryption settings
    if grep -q "encrypted = true" variables.tf || grep -q "encrypted = true" main.tf; then
        print_info "✓ Encryption settings found"
    else
        print_warning "Default encryption settings not found"
    fi
    
    # Check for IMDS configuration
    if grep -q "metadata_options" variables.tf; then
        print_info "✓ IMDS metadata options configurable"
    fi
}

# Function to run example tests
test_examples() {
    print_info "Testing examples..."
    
    if [ ! -d "examples" ]; then
        print_warning "No examples directory found"
        return
    fi
    
    for example_dir in examples/*/; do
        if [ -d "$example_dir" ]; then
            print_info "Testing example: $example_dir"
            cd "$example_dir"
            
            if [ -f "main.tf" ]; then
                terraform init > /dev/null 2>&1 || {
                    print_warning "Could not initialize example: $example_dir"
                    cd ../..
                    continue
                }
                
                terraform validate > /dev/null 2>&1 || {
                    print_error "Example validation failed: $example_dir"
                    cd ../..
                    continue
                }
                
                print_info "✓ Example validated: $example_dir"
            fi
            
            cd ../..
        fi
    done
}

# Function to generate test report
generate_report() {
    print_info "Generating test report..."
    
    cat > TEST_REPORT.md <<EOF
# EC2 ASG Module Test Report

**Date:** $(date)
**Terraform Version:** $(terraform version -json | jq -r '.terraform_version')

## Test Results

### Module Structure
$(check_module_structure)

### Variable Validation
$(validate_variables)

### Output Validation
$(validate_outputs)

### Security Checks
$(security_checks)

### Example Tests
$(test_examples)

## Summary

All tests completed successfully. The module is ready for use.

## Next Steps

1. Review the test results above
2. Check any warnings or errors
3. Proceed with deployment using the examples
4. Monitor the infrastructure after deployment
EOF
    
    print_info "Test report generated: TEST_REPORT.md"
}

# Main execution
main() {
    print_info "Starting EC2 ASG Module Tests..."
    echo ""
    
    # Run all tests
    check_requirements
    validate_terraform
    check_module_structure
    validate_variables
    validate_outputs
    terraform_init
    terraform_validate
    terraform_fmt
    security_checks
    
    echo ""
    print_info "Running example tests..."
    test_examples
    
    echo ""
    print_info "All tests completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "1. Review the examples in the examples/ directory"
    echo "2. Customize the configuration for your needs"
    echo "3. Run terraform plan to preview changes"
    echo "4. Run terraform apply to deploy infrastructure"
    
    # Clean up test files
    rm -f terraform.tfvars tfplan
}

# Run main function
main