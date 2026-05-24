# GitHub Actions Workflows Reference

## Quick Reference

### Workflow Files Location
```
.github/workflows/
├── terraform-validate.yml      # Plan & validate on PR
├── terraform-apply.yml         # Apply on merge to main
├── terraform-destroy.yml       # Manual destroy workflow
└── terraform-security.yml      # Security scanning
```

## Workflow Triggers & Events

| Workflow | Trigger | Condition |
|----------|---------|-----------|
| terraform-validate.yml | PR, Push to main/develop | Terraform files changed |
| terraform-apply.yml | Push to main | Terraform files changed |
| terraform-apply.yml | Manual dispatch | Anytime |
| terraform-destroy.yml | Manual dispatch | With confirmation |
| terraform-security.yml | PR, Push, Schedule | Terraform files changed or daily 2 AM |

## Required GitHub Secrets

Add these secrets to your GitHub repository:

1. **AWS_ACCESS_KEY_ID**
   - AWS IAM programmatic access key
   - Keep this secret ⚠️

2. **AWS_SECRET_ACCESS_KEY**
   - AWS IAM secret access key
   - Keep this secret ⚠️

3. **SLACK_WEBHOOK_URL** (Optional)
   - Slack incoming webhook URL
   - For deployment notifications

## Jobs Overview

### terraform-validate.yml

```yaml
Jobs:
  ├── validate
  │   ├── Format check
  │   ├── Terraform init
  │   ├── Validate syntax
  │   └── Generate plan
  │
  ├── security-scan
  │   └── Checkov scan
  │
  └── comment-pr
      └── Add plan to PR comment
```

### terraform-apply.yml

```yaml
Jobs:
  ├── plan
  │   ├── Terraform init
  │   ├── Generate plan
  │   └── Save artifacts
  │
  └── apply (depends on plan)
      ├── Initialize
      ├── Apply plan
      └── Export outputs
```

### terraform-destroy.yml

```yaml
Jobs:
  └── destroy
      ├── Validate confirmation
      ├── Generate destroy plan
      ├── Review plan
      └── Execute destroy
```

### terraform-security.yml

```yaml
Jobs:
  ├── tfsec
  │   └── TFSec scan
  │
  ├── checkov
  │   └── Checkov scan
  │
  ├── trivy
  │   └── Trivy scan
  │
  └── terraform-compliance
      └── Compliance check
```

## Environment Variables

Set in workflow files:
- `AWS_REGION` - Default: us-east-1
- `TERRAFORM_VERSION` - Default: 1.5.0

Override in repository settings or workflow file.

## Artifact Retention

| Artifact | Retention | Purpose |
|----------|-----------|---------|
| tfplan | 1 day | Plan file for apply |
| terraform-outputs | 1 day | Deployment outputs |
| Security reports | Default | Audit trail |

## Status Checks

✅ All workflows must pass before merge:
- Terraform validate
- Security scans
- Plan review

## Troubleshooting

### Workflow not triggering

1. Check file path filters in `on:` section
2. Verify branch is correct
3. Ensure `.github/workflows/` directory exists
4. Check GitHub Actions is enabled for repository

### AWS credential errors

1. Verify secrets are set correctly
2. Check IAM user permissions
3. Ensure credentials are not expired
4. Validate AWS region is correct

### Plan shows no changes

1. Verify terraform.tfvars is up to date
2. Check for uncommitted changes
3. Review Terraform state file

## Manual Actions

### Trigger Apply Manually

```
GitHub → Actions → Terraform Apply → Run workflow
Select environment: dev → Run workflow
```

### Trigger Destroy Manually

```
GitHub → Actions → Terraform Destroy → Run workflow
Select environment: dev
Confirmation: destroy-dev → Run workflow
```

## Permissions Required

Ensure GitHub Actions bot has:
- `pull-requests: write` (for PR comments)
- `contents: read` (for code checkout)
- `issues: write` (for issue comments)

## Cost Optimization

- Set retention to minimum needed
- Use larger runners only when necessary
- Cache Terraform plugins
- Schedule security scans off-peak

## Security Hardening

- ✅ Use OIDC instead of static credentials (when possible)
- ✅ Rotate credentials regularly
- ✅ Use branch protection rules
- ✅ Require PR reviews
- ✅ Monitor CloudTrail logs
- ✅ Enable audit logging
