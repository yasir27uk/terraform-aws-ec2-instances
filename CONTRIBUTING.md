# Contributing to EC2 Auto Scaling Group Module

Thank you for your interest in contributing to the EC2 Auto Scaling Group Terraform module! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Review Process](#review-process)

## 🤝 Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other contributors

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have the following installed:

- Terraform >= 1.0.0
- Git
- Text editor (VS Code recommended)
- AWS CLI (for testing)

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Fork the repository on GitHub
   git clone https://github.com/your-username/terraform-aws-ec2-asg.git
   cd terraform-aws-ec2-asg
   ```

2. **Install development tools**
   ```bash
   make install-tools
   ```

3. **Set up your workspace**
   ```bash
   # Initialize Terraform
   make init
   
   # Validate the module
   make validate
   ```

## 🔄 Development Workflow

### 1. Create a Branch

Create a new branch for your contribution:
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test improvements
- `refactor/` - Code refactoring

### 2. Make Your Changes

Follow the coding standards outlined below.

### 3. Test Your Changes

```bash
# Run all tests
make test

# Run specific tests
make validate
make fmt
make lint
make security

# Test examples
make examples
```

### 4. Update Documentation

Ensure all relevant documentation is updated:
- Update README.md if adding new features
- Add examples for new functionality
- Update CHANGELOG.md
- Document any breaking changes

### 5. Commit Your Changes

Follow commit message conventions:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(security): add IMDSv2 enforcement

Add support for requiring IMDSv2 tokens for instance metadata
access. This enhances security by preventing unauthorized
metadata access.

Closes #123
```

### 6. Push Your Changes

```bash
git push origin feature/your-feature-name
```

## 📝 Coding Standards

### Terraform Best Practices

1. **Naming Conventions**
   - Resources: `aws_<resource>_<descriptive_name>`
   - Variables: `snake_case` with descriptive names
   - Outputs: `snake_case` with descriptive names
   - Locals: `local.<descriptive_name>`

2. **Structure**
   - Keep files under 500 lines
   - Use consistent indentation (2 spaces)
   - Group related resources together
   - Add descriptive comments for complex logic

3. **Variables**
   - Always include `description` for all variables
   - Use appropriate `type` constraints
   - Add `validation` where applicable
   - Provide sensible `default` values

4. **Outputs**
   - Include `description` for all outputs
   - Group related outputs together
   - Use descriptive names
   - Include documentation for complex values

5. **Security**
   - Never hardcode sensitive values
   - Use encryption for EBS volumes
   - Implement least privilege IAM policies
   - Enable security best practices by default

### Code Style

```hcl
# Good example
resource "aws_autoscaling_group" "main" {
  name_prefix = "${local.name_prefix}-asg-"
  min_size    = var.min_size
  max_size    = var.max_size
  
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-instance"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Bad example - lacks organization and comments
resource "aws_autoscaling_group" "main" {name_prefix="${local.name_prefix}-asg-" min_size=var.min_size max_size=var.max_size tag{key="Name" value="${local.name_prefix}-instance" propagate_at_launch=true}}
```

## 🧪 Testing Guidelines

### Unit Tests

- Test all new functionality
- Test edge cases and error conditions
- Ensure tests are idempotent
- Use descriptive test names

### Integration Tests

- Test module integration with other AWS resources
- Test in different regions
- Test with different configurations
- Validate CloudWatch metrics and alarms

### Example Testing

All examples must:
- Be syntactically correct
- Validate successfully
- Use realistic configurations
- Include necessary comments

## 📚 Documentation

### README.md

Update the README.md when:
- Adding new features
- Changing variable names or types
- Updating examples
- Changing default behavior

### Examples

Create new examples when:
- Demonstrating new features
- Showing common use cases
- Illustrating complex configurations
- Providing migration guides

### Inline Documentation

Add comments for:
- Complex logic
- Non-obvious decisions
- Workarounds for AWS limitations
- Important configuration notes

## 📤 Submitting Changes

### Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows the coding standards
- [ ] All tests pass successfully
- [ ] Documentation is updated
- [ ] Examples are tested and working
- [ ] CHANGELOG.md is updated
- [ ] Commit messages follow conventions
- [ ] No sensitive data is included
- [ ] No hardcoded values (except examples)

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Examples tested
- [ ] CHANGELOG updated

## Related Issues
Closes #(issue number)
```

## 👀 Review Process

### Review Timeline

- Initial review: 1-2 business days
- Feedback response: 3-5 business days
- Final approval: 1-2 business days

### Review Criteria

PRs are evaluated on:
- Code quality and style
- Test coverage
- Documentation completeness
- Backward compatibility
- Security implications
- Performance impact

### Approval Process

- At least one maintainer approval required
- All CI/CD checks must pass
- No outstanding review comments
- Documentation complete

## 🎯 Release Process

### Version Management

This project follows Semantic Versioning:
- Major version: Breaking changes
- Minor version: New features (backward compatible)
- Patch version: Bug fixes (backward compatible)

### Release Checklist

Before releasing:
- [ ] All tests passing
- [ ] Documentation complete
- [ ] CHANGELOG updated
- [ ] Examples validated
- [ ] Security review completed
- [ ] Performance tested

## 🆘 Getting Help

### Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Style Guide](https://github.com/hashicorp/terraform-style-guide)

### Contact

- Open an issue for bugs or questions
- Start a discussion for feature requests
- Join our community chat (if available)

## 📜 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for your contributions! 🎉