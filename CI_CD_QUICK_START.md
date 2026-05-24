# Quick Start: GitHub Actions CI/CD Deployment

## 5-Minute Setup

### 1. Create GitHub Repository
```bash
git init
git branch -M main
git remote add origin https://github.com/USERNAME/repo.git
git add .
git commit -m "Initial: Terraform infrastructure"
git push -u origin main
```

### 2. Add GitHub Secrets
**Go to**: Repository → Settings → Secrets and Variables → Actions

Add 2 required secrets:
- `AWS_ACCESS_KEY_ID` → Your AWS Access Key
- `AWS_SECRET_ACCESS_KEY` → Your AWS Secret Key

### 3. Optional: Add Slack
- `SLACK_WEBHOOK_URL` → Your Slack webhook (for notifications)

## What Happens Next?

### When Code is Pushed
✅ Format validation runs
✅ Syntax checking runs
✅ Security scanning runs
✅ Plan artifact created

### When PR is Created
✅ All validations run
✅ Plan results commented on PR
✅ Review and approve

### When Merged to Main
✅ Plan is generated
✅ Infrastructure is automatically deployed
✅ Terraform apply runs
✅ Outputs exported as JSON

## Workflows Included

| Workflow | When | What It Does |
|----------|------|------------|
| terraform-validate.yml | PR / Push | Validates Terraform |
| terraform-apply.yml | Push to main | Deploys infrastructure |
| terraform-destroy.yml | Manual | Destroys resources |
| terraform-security.yml | PR / Push / Daily | Security scans |

## Deployment Example

**Step 1: Create Branch**
```bash
git checkout -b feature/add-backup
```

**Step 2: Make Changes**
```bash
# Edit terraform files
vim terraform/environments/dev/main.tf
```

**Step 3: Commit**
```bash
git add .
git commit -m "Add backup policy"
git push origin feature/add-backup
```

**Step 4: Create PR**
- Go to GitHub
- Click "Create Pull Request"
- Add description
- Click "Create Pull Request"

**Step 5: Review Results**
- GitHub Actions runs validation
- Check PR for results
- If OK, request review

**Step 6: Approve & Merge**
- Get approval from team
- Click "Squash and merge"
- GitHub Actions deploys automatically

## Verification Checklist

- [ ] GitHub repository created
- [ ] Code pushed to main branch
- [ ] GitHub Secrets added (AWS keys)
- [ ] .github/workflows/ directory exists
- [ ] At least one workflow run completed
- [ ] Terraform resources deployed in AWS
- [ ] ALB endpoint accessible
- [ ] RDS database running
- [ ] Auto Scaling Group has instances

## Monitoring Deployments

**View Workflow Runs**
1. Go to Actions tab
2. Select workflow
3. Click run to see details
4. Check logs for any errors

**Check AWS Resources**
```bash
# List instances
aws ec2 describe-instances --region us-east-1

# Check RDS
aws rds describe-db-instances --region us-east-1

# Get load balancer
aws elbv2 describe-load-balancers --region us-east-1
```

## Troubleshooting

### Workflow not triggering?
- Verify files in `.github/workflows/`
- Check branch filters in workflow yml
- Ensure GitHub Actions is enabled

### AWS credential errors?
- Double-check secret names are exact
- Verify credentials are still valid
- Check IAM permissions

### Terraform apply failed?
- Review plan in artifacts
- Check AWS account limits
- Verify resources don't already exist

## Important Secrets

### Generate AWS Access Key

```bash
# Option 1: AWS Console
1. IAM → Users → Create User
2. Permissions → Attach policies
3. Security credentials → Create access key
4. Copy Access Key ID and Secret

# Option 2: AWS CLI
aws iam create-access-key --user-name github-actions
```

### Create Slack Webhook

```
1. Go to Slack workspace
2. Create app or use existing
3. Enable Incoming Webhooks
4. Create New Webhook
5. Copy webhook URL
```

## Environment Structure

```
terraform/environments/dev/
├── main.tf              # Your resources
├── variables.tf         # Variable definitions
├── outputs.tf           # Outputs
├── terraform.tfvars     # Variable values
└── terraform.lock.hcl   # Version pins
```

## Next Steps

1. **Setup Terraform State**
   - Move to S3 for team collaboration
   - See TERRAFORM_BEST_PRACTICES.md

2. **Add More Environments**
   - Create terraform/environments/staging/
   - Create terraform/environments/prod/
   - See GITHUB_SETUP_GUIDE.md

3. **Integrate Security**
   - Review security scan results
   - Fix critical issues
   - Set policies in terraform

4. **Monitor & Optimize**
   - Setup CloudWatch alarms
   - Enable logging
   - Review costs

## Documentation Files

- **CI_CD_SETUP_GUIDE.md** - Detailed setup instructions
- **GITHUB_SETUP_GUIDE.md** - GitHub configuration steps
- **GITHUB_WORKFLOWS_REFERENCE.md** - Workflow documentation
- **TERRAFORM_BEST_PRACTICES.md** - Infrastructure patterns
- **QUICK_REFERENCE.md** - Quick command reference
- **README.md** - Project overview

## Key Files

**GitHub Actions Workflows**
- `.github/workflows/terraform-validate.yml` - PR validation
- `.github/workflows/terraform-apply.yml` - Auto deployment
- `.github/workflows/terraform-destroy.yml` - Manual destroy
- `.github/workflows/terraform-security.yml` - Security scans

**Terraform Configuration**
- `terraform/environments/dev/main.tf` - Infrastructure definition
- `terraform/environments/dev/variables.tf` - Variable definitions
- `terraform/environments/dev/terraform.tfvars` - Variable values
- `terraform/modules/` - Reusable components

## Support Resources

- [GitHub Actions Docs](https://docs.github.com/actions)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## Summary

✅ **All workflows created**
✅ **Security scanning enabled**
✅ **Auto-deployment configured**
✅ **Documentation provided**

Your CI/CD pipeline is ready to use!
