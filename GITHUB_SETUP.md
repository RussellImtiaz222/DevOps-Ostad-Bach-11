# GitHub Repository Setup Guide

## Step 1: Create GitHub Repository

### Option A: Create New Repository (Recommended)

1. Go to https://github.com/new
2. Fill in repository details:
   - **Repository name:** `module-15-assignment`
   - **Description:** CI/CD Pipeline: Quality, Security & Performance
   - **Public** or **Private** (your choice)
   - ✅ **Add a README file** (can replace with ours)
   - ✅ **Add .gitignore** (select Python)
   - **License:** MIT (recommended)
3. Click **"Create repository"**

### Option B: Use Existing Repository
- If you already have a repository, skip to Step 3

---

## Step 2: Initialize Local Repository

### Clone Repository (if new)
```bash
git clone https://github.com/YOUR_USERNAME/module-15-assignment.git
cd module-15-assignment
```

### Initialize in Existing Directory
```bash
cd "c:\Users\iruss\Module 15 Assignment"
git init
git add .
git commit -m "Initial commit: CI/CD pipeline assignment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/module-15-assignment.git
git push -u origin main
```

---

## Step 3: Add Repository Secrets

**Required for CI/CD Pipeline:**

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Actions**
4. Click **"New repository secret"** for each:

### Secret 1: SONAR_TOKEN
- **Name:** `SONAR_TOKEN`
- **Value:** [Get from https://sonarcloud.io/account/security](https://sonarcloud.io/account/security)
- Click **"Add secret"**

### Secret 2: SONAR_ORGANIZATION
- **Name:** `SONAR_ORGANIZATION`
- **Value:** `russelllmtiaz222`
- Click **"Add secret"**

### Secret 3: API_KEY (Optional for testing)
- **Name:** `API_KEY`
- **Value:** `your-secret-api-key`
- Click **"Add secret"**

**Note:** `GITHUB_TOKEN` is automatically provided by GitHub Actions

---

## Step 4: Enable GitHub Actions

1. Go to your repository
2. Click **Actions** tab
3. If prompted, click **"I understand my workflows, go ahead and enable them"**

---

## Step 5: Configure Branch Protection (Optional but Recommended)

This ensures code quality before merging to main:

1. Go to **Settings** → **Branches**
2. Click **"Add rule"** under "Branch protection rules"
3. **Branch name pattern:** `main`
4. Enable these requirements:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require code reviews before merging (optional)
5. Under **Status checks that are required to pass:**
   - Select: `test-and-quality`
   - Select: `security-scan`
   - Select: `policy-validation`
6. Click **"Create"**

---

## Step 6: Push Code to GitHub

```bash
# Ensure you're in the project directory
cd "c:\Users\iruss\Module 15 Assignment"

# Check git status
git status

# Stage all files
git add .

# Commit
git commit -m "Add CI/CD pipeline: tests, security, load testing, OPA policies"

# Push to main branch
git push -u origin main
```

---

## Step 7: Verify Pipeline Execution

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see **"CI/CD Pipeline - Quality, Security & Performance"** running
4. Wait for all jobs to complete (~5-10 minutes)
5. Verify all jobs pass (green checkmarks)

### Pipeline Status
- ✅ **test-and-quality** - Unit tests & coverage
- ✅ **sonarcloud-analysis** - Code quality scan
- ✅ **security-scan** - Trivy & Bandit
- ✅ **load-testing** - Locust performance test
- ✅ **docker-build** - Container image (only on main)
- ✅ **policy-validation** - OPA policies
- ✅ **dependency-check** - Safety scan
- ✅ **ci-summary** - Final status

---

## Step 8: View Test Results

### In GitHub Actions

1. Click **Actions** tab
2. Click latest **"CI/CD Pipeline"** workflow run
3. Click job name to see details
4. View logs and artifacts

### Test Artifacts

Each workflow run generates:
- **test-results/** - pytest results
- **htmlcov/** - coverage report (HTML)
- **trivy-security-report** - vulnerability scan
- **bandit-security-report** - Python security issues
- **load-test-results/** - performance metrics
- **codecov-umbrella** - code coverage upload

### Download Artifacts

1. Go to workflow run details
2. Scroll to **Artifacts** section
3. Click artifact to download

---

## Step 9: View SonarCloud Results

After first workflow completes:

1. Go to https://sonarcloud.io/organizations/russelllmtiaz222
2. Click your project
3. View:
   - **Code coverage** percentage
   - **Quality gate** status
   - **Issues** (bugs, code smells, vulnerabilities)
   - **Hotspots** (security concerns)

---

## Step 10: Set Up Notifications (Optional)

### Email Notifications
1. Go to GitHub **Settings** → **Notifications**
2. Enable email for workflow failures

### Slack Notifications
1. Add GitHub Slack app to your workspace
2. In GitHub Settings, subscribe to workflow runs
3. Get notifications in Slack channel

### SonarCloud Notifications
1. Go to SonarCloud **Organization Settings**
2. Click **Webhooks**
3. Configure webhooks for Slack/Teams

---

## File Structure After Setup

```
your-repo/
├── .github/
│   └── workflows/
│       └── ci-cd-pipeline.yml      # Main workflow
├── app/
│   ├── __init__.py
│   └── app.py                      # Flask application
├── tests/
│   ├── __init__.py
│   └── test_app.py                 # 60+ unit tests
├── load_tests/
│   ├── __init__.py
│   └── locustfile.py               # Locust load tests
├── policies/
│   └── k8s-policy.rego             # OPA policies
├── config/
│   └── trivy.yaml                  # Trivy config
├── Dockerfile                       # Container image
├── docker-compose.yml              # Local dev setup
├── requirements.txt                # Python dependencies
├── pytest.ini                       # Pytest config
├── sonar-project.properties        # SonarCloud config
├── .env                            # Dev environment (local only)
├── .env.template                   # Template
├── .gitignore                       # Git ignore rules
├── README.md                        # Main documentation
├── SONARCLOUD_SETUP.md            # SonarCloud guide
├── SECURITY_REPORT.md             # Security findings
├── LOAD_TEST_RESULTS.md           # Load test report
└── GITHUB_SETUP.md                # This file
```

---

## Common Git Commands

### Basic Workflow
```bash
# Check status
git status

# Add changes
git add .

# Commit
git commit -m "Descriptive message"

# Push to GitHub
git push origin main

# Pull latest changes
git pull origin main
```

### Working with Branches
```bash
# Create feature branch
git checkout -b feature/new-feature

# Switch branches
git checkout main

# Merge feature into main
git merge feature/new-feature

# Delete branch
git branch -d feature/new-feature
```

### Viewing History
```bash
# View commit log
git log

# View detailed changes
git diff

# View specific commit
git show <commit-hash>
```

---

## Troubleshooting GitHub Setup

### Secret Not Found in Workflow
**Problem:** Workflow can't access secrets  
**Solution:** 
- Verify secret name matches exactly (case-sensitive)
- Check secret is saved (green checkmark)
- Restart workflow (push new commit)

### Workflow Not Triggering
**Problem:** Workflow doesn't run on push  
**Solution:**
- Verify GitHub Actions enabled (Settings → Actions)
- Check `.github/workflows/` path is correct
- Check workflow file YAML syntax
- Push to `main` branch (not other branches unless configured)

### SonarCloud Token Error
**Problem:** SonarCloud analysis fails  
**Solution:**
- Verify SONAR_TOKEN secret is added
- Verify token not expired (regenerate if needed)
- Check sonar-project.properties keys are correct

### Docker Build Fails
**Problem:** Docker build step fails in Actions  
**Solution:**
- This only runs on push to `main` (as configured)
- Check Dockerfile syntax
- Verify all required files copied
- Check image name format

### Tests Fail in CI but Pass Locally
**Problem:** Different test results  
**Solution:**
- Check Python version (3.10)
- Verify all dependencies installed
- Check environment variables set in CI
- Run same command locally: `pytest tests/ --cov=app`

---

## Protecting Your Code

### .gitignore Essentials
The `.gitignore` already includes:
- ✅ `.env` - Local secrets
- ✅ `__pycache__/` - Python cache
- ✅ `.pytest_cache/` - Test cache
- ✅ `htmlcov/` - Coverage reports
- ✅ `.vscode/` - IDE config
- ✅ `.idea/` - IDE config

### Sensitive Files Never to Commit
```bash
# These are protected by .gitignore:
.env                 # Secrets
*.key                # SSH/crypto keys
credentials.json     # API credentials
secret_tokens.txt    # Authentication tokens
```

### Verify Secrets Not Committed
```bash
# Check git history for secrets
git log --all -p | grep "API_KEY\|password\|token"

# This should return nothing if secrets are protected
```

---

## CI/CD Workflow Explanation

### What Happens When You Push

```
1. Code Push
    ↓
2. GitHub detects push to main
    ↓
3. Triggers ci-cd-pipeline.yml workflow
    ↓
4. Jobs run in parallel/sequence:
    - test-and-quality
    - sonarcloud-analysis
    - security-scan
    - load-testing
    - policy-validation
    - dependency-check
    - docker-build (main only)
    ↓
5. Results available in:
    - GitHub Actions tab
    - SonarCloud dashboard
    - Security tab (SARIF)
```

### Artifact Retention
By default, artifacts kept for **30 days**. Configure in workflow:
```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    retention-days: 90  # Keep for 90 days
```

---

## Creating Pull Requests

For collaborative development:

```bash
# Create feature branch
git checkout -b feature/add-logging

# Make changes and commit
git commit -m "Add request logging"

# Push branch
git push -u origin feature/add-logging

# Go to GitHub, create Pull Request
# Select: Compare & pull request
# Fill in title and description
# Click Create pull request

# Workflow runs automatically
# Fix any failures
# Merge when ready
```

---

## Monitoring & Maintenance

### Weekly Checks
- ✅ Review SonarCloud issues
- ✅ Check dependency updates
- ✅ Monitor test coverage trends
- ✅ Review security alerts

### Monthly Tasks
- ✅ Update dependencies
- ✅ Review GitHub security alerts
- ✅ Audit GitHub Secrets
- ✅ Review failed workflow runs

### Quarterly Tasks
- ✅ Review and update policies
- ✅ Load testing with new traffic patterns
- ✅ Security audit
- ✅ Performance optimization

---

## Next Steps

1. ✅ Create GitHub repository
2. ✅ Add repository secrets
3. ✅ Push code
4. ✅ Monitor first workflow run
5. ✅ View SonarCloud results
6. ✅ Review test reports
7. ✅ Celebrate! 🎉

---

## Resources

- [GitHub Repository Documentation](https://docs.github.com/en/repositories)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule)

---

**Ready to push? Let's go!** 🚀
