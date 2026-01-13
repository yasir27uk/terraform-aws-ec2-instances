# Makefile for Terraform EC2 ASG Module
# Provides convenient commands for common operations

.PHONY: help init validate fmt plan apply destroy test clean lint security

# Default target
help:
	@echo "Available targets:"
	@echo "  make init          - Initialize Terraform working directory"
	@echo "  make validate      - Validate Terraform configuration"
	@echo "  make fmt           - Format Terraform files"
	@echo "  make plan          - Preview Terraform changes"
	@echo "  make apply         - Apply Terraform changes"
	@echo "  make destroy       - Destroy Terraform resources"
	@echo "  make test          - Run module tests"
	@echo "  make clean         - Clean temporary files"
	@echo "  make lint          - Run Terraform linting"
	@echo "  make security      - Run security checks"
	@echo "  make docs          - Generate documentation"
	@echo "  make examples      - Test all examples"
	@echo "  make all           - Run all checks and tests"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init -upgrade

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Preview Terraform changes
plan:
	@echo "Planning Terraform changes..."
	terraform plan

# Apply Terraform changes
apply:
	@echo "Applying Terraform changes..."
	terraform apply

# Destroy Terraform resources
destroy:
	@echo "Destroying Terraform resources..."
	terraform destroy

# Run module tests
test:
	@echo "Running module tests..."
	./test.sh

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -rf .terraform/
	rm -rf .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f tfplan
	rm -f terraform.tfvars
	rm -f *.log
	rm -f TEST_REPORT.md
	@echo "Clean completed"

# Run Terraform linting
lint:
	@echo "Running Terraform linting..."
	@if command -v tflint > /dev/null 2>&1; then \
		tflint --init && tflint; \
	else \
		echo "tflint not installed. Install from https://github.com/terraform-linters/tflint"; \
	fi

# Run security checks
security:
	@echo "Running security checks..."
	@if command -v tfsec > /dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "tfsec not installed. Install from https://github.com/aquasecurity/tfsec"; \
	fi
	@if command -v checkov > /dev/null 2>&1; then \
		checkov -d .; \
	else \
		echo "checkov not installed. Install from https://github.com/bridgecrewio/checkov"; \
	fi

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v terraform-docs > /dev/null 2>&1; then \
		terraform-docs markdown table --output-file GENERATED_DOCUMENTATION.md .; \
		echo "Documentation generated: GENERATED_DOCUMENTATION.md"; \
	else \
		echo "terraform-docs not installed. Install from https://github.com/terraform-docs/terraform-docs"; \
	fi

# Test all examples
examples:
	@echo "Testing all examples..."
	@for dir in examples/*/; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Testing $$dir..."; \
			cd "$$dir" && \
			terraform init -upgrade > /dev/null 2>&1 && \
			terraform validate && \
			cd ../.. || echo "Failed: $$dir"; \
		fi; \
	done
	@echo "Example tests completed"

# Run all checks
all: init validate fmt lint security test
	@echo "All checks completed successfully!"

# Install development tools
install-tools:
	@echo "Installing development tools..."
	@go install github.com/terraform-linters/tflint/cmd/tflint@latest
	@go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
	@brew install checkov
	@brew install terraform-docs
	@echo "Development tools installed successfully"

# Update dependencies
update-deps:
	@echo "Updating Terraform provider dependencies..."
	terraform init -upgrade

# Show Terraform version
version:
	@echo "Terraform version:"
	@terraform version

# Show Terraform providers
providers:
	@echo "Terraform providers:"
	@terraform providers

# Import existing resources (requires RESOURCE_NAME and RESOURCE_ID)
import:
	@if [ -z "$(RESOURCE_NAME)" ] || [ -z "$(RESOURCE_ID)" ]; then \
		echo "Usage: make import RESOURCE_NAME=aws_autoscaling_group.main RESOURCE_ID=asg-123456"; \
		exit 1; \
	fi
	@echo "Importing $(RESOURCE_NAME) with ID $(RESOURCE_ID)..."
	terraform import $(RESOURCE_NAME) $(RESOURCE_ID)

# State management
state-list:
	@echo "Listing Terraform state resources..."
	terraform state list

state-rm:
	@if [ -z "$(RESOURCE)" ]; then \
		echo "Usage: make state-rm RESOURCE=aws_autoscaling_group.main"; \
		exit 1; \
	fi
	@echo "Removing $(RESOURCE) from state..."
	terraform state rm $(RESOURCE)

# Output management
outputs:
	@echo "Terraform outputs:"
	terraform output

output:
	@if [ -z "$(OUTPUT_NAME)" ]; then \
		echo "Usage: make output OUTPUT_NAME=autoscaling_group_id"; \
		exit 1; \
	fi
	@echo "Output $(OUTPUT_NAME):"
	terraform output $(OUTPUT_NAME)

# Workspace management
workspace-list:
	@echo "Listing workspaces..."
	terraform workspace list

workspace-new:
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "Usage: make workspace-new WORKSPACE=dev"; \
		exit 1; \
	fi
	@echo "Creating new workspace: $(WORKSPACE)"
	terraform workspace new $(WORKSPACE)

workspace-select:
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "Usage: make workspace-select WORKSPACE=prod"; \
		exit 1; \
	fi
	@echo "Selecting workspace: $(WORKSPACE)"
	terraform workspace select $(WORKSPACE)

# Graph generation
graph:
	@echo "Generating dependency graph..."
	terraform graph | dot -Tpng > dependency-graph.png
	@echo "Graph generated: dependency-graph.png"

# CI/CD targets
ci: init validate fmt lint security test
	@echo "CI/CD checks passed"

cd: ci apply
	@echo "CD deployment completed"