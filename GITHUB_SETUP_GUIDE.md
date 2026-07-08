# GitHub Repository Setup & Deployment Procedures

## Initial Repository Setup

### 1. Create GitHub Repository

```bash
# Option A: Using GitHub CLI
gh repo create terraform-aws-3tier --public --source=. --remote=origin --push

# Option B: Using git commands
git init
git branch -M main
git remote add origin https://github.com/USERNAME/terraform-aws-3tier.git
```

### 2. Configure Git

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 3. Prepare Files for Commit

Ensure these files are properly set up:

```bash
# Create .gitignore (if not exists)
touch .gitignore

# Create meaningful commit message
echo "Terraform 3-tier infrastructure with GitHub Actions CI/CD"
```

### 4. Initial Commit

```bash
git add .
git commit -m "Initial commit: Terraform infrastructure as code with CI/CD"
git push -u origin main
```

## GitHub Secrets Configuration

### Step 1: Navigate to Secrets Settings

1. Go to: Repository → Settings → Secrets and Variables → Actions
2. Click "New repository secret"

### Step 2: Add AWS Credentials

**Create AWS_ACCESS_KEY_ID Secret**
```
Name: AWS_ACCESS_KEY_ID
Value: YOUR_ACCESS_KEY_ID
Click: Add secret
```

**Create AWS_SECRET_ACCESS_KEY Secret**
```
Name: AWS_SECRET_ACCESS_KEY
Value: YOUR_SECRET_ACCESS_KEY
Click: Add secret
```

### Step 3: Optional - Add Slack Webhook

**Create SLACK_WEBHOOK_URL Secret**
```
Name: SLACK_WEBHOOK_URL
Value: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
Click: Add secret
```

### Verify Secrets

- Secrets should appear as:
  - ✓ AWS_ACCESS_KEY_ID
  - ✓ AWS_SECRET_ACCESS_KEY
  - ✓ SLACK_WEBHOOK_URL (optional)

## AWS IAM Setup

### Create IAM User for CI/CD

```bash
# Using AWS CLI
aws iam create-user --user-name github-actions

# Create access key
aws iam create-access-key --user-name github-actions
```

### Attach Required Policies

```bash
# Attach comprehensive policy
aws iam put-user-policy --user-name github-actions --policy-name terraform-policy --policy-document file://policy.json
```

### Required Permissions

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
        "autoscaling:*",
        "route53:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Branch Protection Setup

### 1. Configure Branch Protection Rules

Go to: Settings → Branches → Add rule

**Pattern**: main

### 2. Enable Protections

- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require code reviews before merging (1 reviewer minimum)
- ✅ Include administrators in restrictions

### 3. Select Required Status Checks

- ✅ terraform-validate / validate
- ✅ terraform-validate / security-scan
- ✅ GitHub Actions security scanning

## GitHub Actions Configuration

### 1. Enable GitHub Actions

Settings → Actions → Permissions
- ✅ Allow all actions and reusable workflows

### 2. Configure Runners

Settings → Actions → Runners
- Use default Ubuntu runners (ubuntu-latest)

### 3. Set Action Permissions

Settings → Actions → General
- ✅ Workflow permissions: Read and write permissions

## Deployment Workflow

### Standard Deployment Flow

```mermaid
1. Developer creates branch
   ↓
2. Makes Terraform changes
   ↓
3. Commits and pushes to GitHub
   ↓
4. GitHub Actions validates changes
   - Format check
   - Syntax validation
   - Security scanning
   ↓
5. Developer creates Pull Request
   ↓
6. Validation workflow results appear in PR
   ↓
7. Team reviews changes and plan
   ↓
8. Approves PR (requires 1+ review)
   ↓
9. Merge to main branch
   ↓
10. GitHub Actions apply workflow runs
    - Terraform plan
    - Terraform apply
    ↓
11. Infrastructure updated in AWS
    ↓
12. Optional: Slack notification sent
```

### Example Deployment Sequence

**Step 1: Create Feature Branch**
```bash
git checkout -b feature/add-rds-backup
```

**Step 2: Make Changes**
```bash
# Edit Terraform files
vim terraform/environments/dev/main.tf

# Verify locally (optional)
cd terraform/environments/dev
terraform init
terraform plan
```

**Step 3: Commit and Push**
```bash
git add terraform/
git commit -m "Add RDS automated backups for production

- Enable automated backups
- Set retention to 30 days
- Configure backup window to 2-4 AM UTC
"
git push origin feature/add-rds-backup
```

**Step 4: Create Pull Request**
```bash
# Via GitHub CLI
gh pr create --title "Add RDS automated backups" --body "See description above"

# Or via GitHub web interface
# - Go to repository
# - Click "Create pull request"
# - Select feature/add-rds-backup → main
```

**Step 5: Review Validation Results**
```
GitHub Actions will automatically run:
- terraform-validate job
- security-scan job
- Results appear in PR
```

**Step 6: Review and Approve**
```
- Request review from team members
- Address any feedback
- Get approval (at least 1 required)
```

**Step 7: Merge to Main**
```bash
# Via GitHub CLI
gh pr merge --squash

# Or via GitHub web interface
# - Click "Squash and merge"
# - Click "Confirm squash and merge"
```

**Step 8: Monitor Deployment**
```
GitHub Actions will automatically run:
- terraform-apply job
- Monitor progress in Actions tab
- Receive Slack notification (if configured)
```

## Reverting Deployments

### If Deployment Has Issues

**Option 1: Revert Commit**
```bash
git revert -n HEAD
git commit -m "Revert: Add RDS backup policy"
git push origin main
```

This triggers a new apply workflow that reverts the changes.

**Option 2: Manual Destroy and Re-apply**
```
GitHub Actions → Terraform Destroy → Run workflow
Select environment: dev
Confirmation: destroy-dev
```

## Monitoring & Troubleshooting

### Check Workflow Status

1. Go to: Actions tab
2. Select workflow name
3. View run history
4. Click run for details

### View Logs

```
Actions tab → workflow-name → run-name → job-name → view logs
```

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Workflow not triggering | Incorrect path filter | Verify `paths:` in yml |
| AWS credential error | Missing secrets | Add secrets to Settings |
| Terraform init fails | State lock | Clear terraform.lock.hcl |
| Plan shows huge diff | Variable mismatch | Review terraform.tfvars |
| Apply fails | Insufficient permissions | Check IAM policy |

## Security Best Practices

1. **Never Commit Secrets**
   ```bash
   # Use .gitignore
   echo "terraform.tfvars" >> .gitignore
   echo "*.pem" >> .gitignore
   ```

2. **Rotate Credentials Regularly**
   - Schedule quarterly rotation
   - Update GitHub Secrets
   - Deactivate old credentials

3. **Enable Audit Logging**
   ```bash
   aws cloudtrail create-trail --name terraform-trail --s3-bucket-name logging-bucket
   ```

4. **Monitor AWS Activities**
   ```bash
   aws cloudtrail look-up-events --event-name CreateStack
   ```

5. **Require Code Reviews**
   - Enforce 1+ approvals before merge
   - Different reviewer than author

## Cost Optimization

- GitHub Actions: Free for public repos, 2000 min/month for private
- Use matrix strategies for multiple environments
- Cache Terraform plugins between runs
- Use smaller instances for planning

## Advanced Configuration

### Deploy to Multiple Environments

Create environment-specific workflows:
```
.github/workflows/
├── terraform-apply-dev.yml
├── terraform-apply-staging.yml
└── terraform-apply-prod.yml
```

### Automated Testing

Add pre-deployment tests:
```bash
# Unit tests for Terraform
terraform validate

# Integration tests
pytest tests/infrastructure/

# Security tests
checkov -d terraform/
```

### Scheduled Deployments

Schedule deployments during low-traffic periods:
```yaml
schedule:
  - cron: '0 2 * * 0'  # Weekly at 2 AM UTC Sunday
```
