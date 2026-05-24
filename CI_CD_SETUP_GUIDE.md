# GitHub Actions CI/CD Pipeline - Setup & Configuration Guide

## Overview

This document provides step-by-step instructions to set up and configure the GitHub Actions CI/CD pipeline for Terraform deployments.

## Prerequisites

- GitHub account with a repository for this project
- AWS account with appropriate permissions
- GitHub repository with the Terraform code pushed

## Step 1: Create GitHub Repository

1. Create a new GitHub repository (or use existing)
2. Clone the repository to your local machine
3. Copy your Terraform code to the repository
4. Push the code to GitHub

```bash
git init
git add .
git commit -m "Initial commit: Terraform infrastructure"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

## Step 2: Configure AWS Credentials in GitHub Secrets

### Option A: Using IAM User with Programmatic Access (Recommended)

1. Go to GitHub Repository → Settings → Secrets and Variables → Actions
2. Add the following secrets:

   **AWS_ACCESS_KEY_ID**
   - Value: Your AWS Access Key ID
   - Click "New repository secret"

   **AWS_SECRET_ACCESS_KEY**
   - Value: Your AWS Secret Access Key
   - Click "New repository secret"

   **AWS_REGION** (Optional)
   - Value: us-east-1 (or your preferred region)

3. Never commit AWS credentials to the repository

### Option B: Using GitHub OIDC Provider (More Secure)

For enhanced security, use OpenID Connect:

```bash
# This requires AWS account setup with GitHub as OIDC provider
# See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
```

## Step 3: Update IAM Policy for GitHub Actions

Ensure your AWS IAM user has these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*",
        "ec2:*",
        "rds:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Step 4: Add Workflow Files to Repository

The following workflow files are already included in `.github/workflows/`:

1. **terraform-validate.yml** - Validates and plans Terraform changes
2. **terraform-apply.yml** - Applies Terraform changes to main branch
3. **terraform-destroy.yml** - Safely destroys infrastructure (manual trigger)
4. **terraform-security.yml** - Runs security scans on Terraform code

## Workflow Descriptions

### terraform-validate.yml

**Triggers:**
- Pull requests to any branch with Terraform changes
- Commits to main/develop with Terraform changes

**Jobs:**
1. **Validate** - Checks Terraform syntax and creates plan
2. **Security-scan** - Runs Checkov security scanner
3. **Comment-pr** - Adds plan results as comment on PR

**Usage:**
```
Automatically runs on PR creation or commits
```

### terraform-apply.yml

**Triggers:**
- Push to main branch with Terraform changes
- Manual workflow dispatch

**Jobs:**
1. **Plan** - Creates Terraform plan
2. **Apply** - Applies the plan to AWS

**Usage:**
```
Automatic on merge to main, or manual trigger:
- Go to Actions → Terraform Apply → Run workflow
- Select environment: dev/staging
```

### terraform-destroy.yml

**Triggers:**
- Manual workflow dispatch only

**Safety:**
- Requires confirmation phrase matching the environment

**Usage:**
```
1. Go to Actions → Terraform Destroy → Run workflow
2. Select environment: dev or staging
3. Type "destroy-{environment}" to confirm
4. Click "Run workflow"
```

### terraform-security.yml

**Triggers:**
- On every push and PR
- Daily scheduled scan (2 AM UTC)

**Scans:**
- TFSec - Terraform-specific security issues
- Checkov - Infrastructure as code best practices
- Trivy - Vulnerability scanning

## Step 5: Configure Optional Slack Notifications

To receive notifications when deployments complete:

1. Create a Slack Webhook URL:
   - Go to your Slack workspace
   - Create a new app or configure an existing one
   - Enable Incoming Webhooks
   - Create a webhook URL

2. Add to GitHub Secrets:
   - Secret name: `SLACK_WEBHOOK_URL`
   - Value: Your Slack webhook URL

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-validate.yml
│       ├── terraform-apply.yml
│       ├── terraform-destroy.yml
│       └── terraform-security.yml
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── terraform.tfvars
│   │   └── staging/
│   └── modules/
│       ├── vpc/
│       ├── ec2/
│       ├── rds/
│       ├── bastion/
│       └── security_groups/
├── CONTRIBUTING.md
├── README.md
└── .gitignore
```

## Best Practices Implemented

### 1. Modular Terraform Structure
- Separate modules for each component (VPC, EC2, RDS, etc.)
- Reusable variables and outputs
- Clean separation of concerns

### 2. Environment Management
- Separate directories for dev, staging, prod
- Environment-specific variable files
- Consistent naming conventions

### 3. Security
- No credentials in code
- Secrets stored in GitHub
- Security scanning on every change
- SARIF reports for vulnerability tracking

### 4. Code Quality
- Terraform format validation
- Plan review before apply
- Automated comments on PRs
- Artifact retention for audit trail

### 5. CI/CD Flow
```
Developer commits → GitHub receives code
              ↓
      Validate workflow runs
              ↓
  Format check, syntax validation, security scan
              ↓
    PR created with plan comment
              ↓
  Code review and approval
              ↓
      Merge to main
              ↓
      Apply workflow runs
              ↓
   Terraform apply executed
              ↓
  Infrastructure updated in AWS
              ↓
    Artifacts saved for audit
```

## Common Tasks

### Deploy Changes to Dev Environment

1. Create a new branch
   ```bash
   git checkout -b feature/my-changes
   ```

2. Make Terraform changes
   ```bash
   cd terraform/environments/dev
   vim main.tf
   ```

3. Validate locally (optional)
   ```bash
   terraform init
   terraform plan
   ```

4. Push branch and create PR
   ```bash
   git add .
   git commit -m "Add new resources"
   git push origin feature/my-changes
   ```

5. Review the validation workflow results
6. Get PR approval
7. Merge to main
8. Apply workflow automatically deploys

### Manually Trigger Apply

1. Go to GitHub Actions tab
2. Select "Terraform Apply" workflow
3. Click "Run workflow"
4. Select environment
5. Click "Run workflow"

### Review Security Scan Results

1. Go to Security tab → Code scanning alerts
2. Review Checkov, TFSec, and Trivy findings
3. Fix issues or mark as false positives

## Troubleshooting

### Workflow fails with AWS credential errors

- Verify secrets are correctly added
- Check IAM permissions
- Ensure AWS region is correct

### Terraform apply fails

- Check Plan output in artifacts
- Review AWS account limits
- Verify resource dependencies

### Security scan shows false positives

- Review finding in SARIF report
- Suppress if acceptable risk
- Document suppression reason

## Maintenance

### Update Terraform Version

1. Edit `.github/workflows/*.yml`
2. Change `TERRAFORM_VERSION: 1.5.0`
3. Commit and push changes

### Add New Module

1. Create module in `terraform/modules/`
2. Reference in environment configurations
3. Test locally with `terraform plan`
4. Push to repository
5. Workflows validate and deploy

## Security Considerations

⚠️ **Important:**
- Never commit `.tfvars` files with sensitive data
- Rotate AWS credentials regularly
- Review IAM policies for least privilege
- Enable branch protection rules
- Require PR reviews before merge
- Keep GitHub Actions secrets rotation schedule
- Monitor AWS CloudTrail for unauthorized actions

## Further Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform in Automation](https://www.terraform.io/cloud-docs/run/run-environment)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform Best Practices](https://www.terraform.io/language/values/variables)
