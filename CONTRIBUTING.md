# Contributing to 3-Tier Terraform Project

Guidelines for contributing to this Infrastructure as Code project.

## Code Standards

### Terraform Code
- Follow Terraform style guide
- Use `terraform fmt` before committing
- Add comments for complex logic
- Use consistent naming conventions
- Keep modules focused on single responsibility

### Python Code
- Follow PEP 8 style guide
- Add docstrings to functions and classes
- Use type hints where possible
- Keep functions small and focused
- Add error handling

### Variable Naming
- Use snake_case for all variables and resources
- Prefix sensitive variables with description
- Add meaningful descriptions to all variables
- Use default values where appropriate

## Project Structure

```
Keep the following structure:
- terraform/modules/ - Reusable modules
- terraform/environments/ - Environment-specific configs
- application/ - Application code (frontend, backend, database)
- monitoring/ - Monitoring stack configuration
- .github/workflows/ - CI/CD workflows
- Documentation files in root
```

## Testing

### Terraform Testing
```bash
# Format check
terraform fmt -recursive -check terraform/

# Validate
terraform validate

# Security scanning (optional)
tfsec terraform/
checkov -d terraform/

# Plan and review
terraform plan -var-file=terraform.tfvars
```

### Application Testing
```bash
# Backend API
cd application/backend
python -m pytest tests/

# Frontend validation
cd application/frontend
# HTML validation tools
```

## Commit Messages

Use clear, descriptive commit messages:

```
format: <type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

Example:
```
feat(rds): add backup retention parameter

- Add configurable backup retention days
- Update documentation
- Add to terraform.tfvars.example

Closes #123
```

## Pull Request Process

1. Create feature branch: `git checkout -b feature/descriptive-name`
2. Make changes following code standards
3. Test changes: `terraform plan -var-file=terraform.tfvars`
4. Commit with clear messages
5. Push to feature branch
6. Create Pull Request with description
7. Wait for GitHub Actions to pass
8. Address review comments
9. Squash and merge when approved

## Documentation

### Update README.md
- When adding new features
- When changing deployment procedures
- When modifying architecture

### Update ARCHITECTURE.md
- When changing infrastructure design
- When adding new components
- When updating data flow

### Update QUICK_REFERENCE.md
- When adding new commands
- When changing common procedures

## Module Development

When creating a new module:

1. Create module directory: `terraform/modules/<module-name>/`
2. Include standard files:
   - `main.tf` - Main configuration
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
3. Add meaningful descriptions
4. Use variable validation
5. Add comments for complex logic
6. Test module independently
7. Document in README

Example module structure:
```
terraform/modules/example/
├── main.tf          # Main resources
├── variables.tf     # Input variables with descriptions
├── outputs.tf       # Outputs for other modules
└── README.md        # Module documentation (optional)
```

## Security Considerations

- Never commit sensitive values:
  - Passwords
  - API keys
  - AWS credentials
  - Private keys

- Use `terraform.tfvars` (in .gitignore)
- Use AWS Secrets Manager for sensitive data
- Use IAM roles instead of access keys
- Enable encryption for all storage
- Review security group rules

## Performance Tips

- Use `target` for faster testing: `terraform apply -target=module.vpc`
- Minimize module dependencies
- Use `for_each` for multiple resources
- Consider lazy loading for optional components

## Common Mistakes to Avoid

- ❌ Committing terraform.tfvars with sensitive data
- ❌ Using hardcoded values instead of variables
- ❌ Not validating user input
- ❌ Ignoring Terraform plan output
- ❌ Running `destroy` without plan review
- ❌ Not testing in dev environment first
- ❌ Modifying state files directly
- ❌ Not updating documentation

## Version Control

### Branches
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `hotfix/*` - Hot fix branches

### Protected Branches
- Require pull request reviews
- Require status checks to pass
- Require up-to-date branches

## Code Review Checklist

Reviewers should verify:

- [ ] Code follows Terraform style guide
- [ ] Security best practices are followed
- [ ] No sensitive data is exposed
- [ ] Documentation is updated
- [ ] Changes are tested
- [ ] Naming is consistent
- [ ] Comments are clear
- [ ] No unnecessary complexity

## Release Process

1. Update version in documentation
2. Update CHANGELOG.md
3. Create release branch
4. Tag release: `git tag -a v1.0.0 -m "Version 1.0.0"`
5. Push tags: `git push origin --tags`
6. Create GitHub Release
7. Merge back to develop

## Support

For questions:
- Check existing documentation
- Review past issues and discussions
- Create new issue if needed
- Include error logs and context

## License

All contributions are under MIT License.

---

Thank you for contributing! 🚀
