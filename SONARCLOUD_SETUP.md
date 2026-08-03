# SonarCloud Setup Guide

## Overview
This guide provides step-by-step instructions to set up and use SonarCloud for code quality analysis.

## Prerequisites
- GitHub account
- GitHub repository (public or private)
- This project code

## Step 1: Create SonarCloud Account

1. Visit https://sonarcloud.io
2. Click **"Log In"**
3. Select **"GitHub"** as the authentication method
4. Authorize SonarCloud to access your GitHub account
5. You'll be redirected to https://sonarcloud.io/organizations

## Step 2: Create an Organization

1. In SonarCloud, click **"Create Organization"**
2. Select **"GitHub"** as the provider
3. Choose **"Free"** plan
4. Name your organization: `russelllmtiaz222` (matching your GitHub username)
5. Click **"Create Organization"**

## Step 3: Add Your Repository

1. Go to https://sonarcloud.io/organizations/russelllmtiaz222/projects
2. Click **"Analyze new project"**
3. Select your GitHub repository (e.g., `YOUR_USERNAME/module-15-assignment`)
4. Click **"Set up"**

## Step 4: Generate SonarCloud Token

1. Go to https://sonarcloud.io/account/security
2. Under **"Generate Tokens"**, enter a token name: `github-actions`
3. Click **"Generate"**
4. **Copy the token immediately** (you can't see it again!)
5. Keep it safe - you'll need it for GitHub Secrets

## Step 5: Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Create two secrets:

### Secret 1: SONAR_TOKEN
- **Name:** `SONAR_TOKEN`
- **Value:** Paste the token from Step 4
- Click **"Add secret"**

### Secret 2: SONAR_ORGANIZATION
- **Name:** `SONAR_ORGANIZATION`
- **Value:** `russelllmtiaz222`
- Click **"Add secret"**

## Step 6: Verify Pipeline Configuration

The [.github/workflows/ci-cd-pipeline.yml](.github/workflows/ci-cd-pipeline.yml) already includes:

```yaml
- name: SonarCloud Scan
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.projectKey=ci-cd-pipeline
      -Dsonar.organization=russelllmtiaz222
```

This configuration:
- Uses your SONAR_TOKEN automatically
- Analyzes Python code in `app/` directory
- Excludes tests from coverage
- Generates quality gates

## Step 7: Push Code to GitHub

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: CI/CD pipeline with SonarCloud integration"

# Set branch to main
git branch -M main

# Add remote (replace with your URL)
git remote add origin https://github.com/YOUR_USERNAME/module-15-assignment.git

# Push to GitHub
git push -u origin main
```

## Step 8: Monitor Pipeline Execution

1. Go to your GitHub repository
2. Click **Actions**
3. You'll see the CI/CD pipeline running
4. Wait for the **SonarCloud Analysis** job to complete
5. Click on the job to see detailed output

## Step 9: View SonarCloud Results

Once the pipeline completes:

1. Go to https://sonarcloud.io/organizations/russelllmtiaz222/projects
2. Click on your project name
3. You'll see:
   - **Code Coverage** percentage
   - **Quality Gate** status (Passed/Failed)
   - **Bugs** found
   - **Code Smells** detected
   - **Vulnerabilities** identified
   - **Security Hotspots** flagged

## Understanding SonarCloud Metrics

### Code Coverage
- **Target:** >80% (we achieve ~90%)
- Shows which lines are tested
- Hover over code to see coverage

### Quality Gate
- **Passed** ✅: All quality criteria met
- **Failed** ❌: Needs fixes
- Default criteria:
  - Coverage >= 80%
  - No new bugs
  - No new security hotspots

### Bugs
- Actual coding errors
- Examples: null pointer dereference, type mismatch
- **Severity:** Blocker, Critical, Major, Minor

### Code Smells
- Quality issues (not bugs)
- Examples: duplicate code, long methods, unused variables
- **Severity:** Critical, Major, Minor, Info

### Vulnerabilities
- Security risks
- Examples: SQL injection, hardcoded secrets, weak authentication
- **Severity:** Blocker, Critical, Major, Minor

### Security Hotspots
- Code that might be vulnerable
- Requires manual review
- Examples: encryption, authentication, sensitive operations

## Fixing Issues

### Example Fix 1: Remove Unused Import

**Issue:** Import statement never used

**Before:**
```python
import json  # Unused
from flask import Flask

app = Flask(__name__)
```

**After:**
```python
from flask import Flask

app = Flask(__name__)
```

### Example Fix 2: Extract Hardcoded Value

**Issue:** Magic number without explanation

**Before:**
```python
def calculate_discount(amount, quantity):
    if quantity >= 10:
        return amount * 0.9  # Hardcoded discount
```

**After:**
```python
BULK_DISCOUNT_THRESHOLD = 10
BULK_DISCOUNT_RATE = 0.9

def calculate_discount(amount, quantity):
    if quantity >= BULK_DISCOUNT_THRESHOLD:
        return amount * BULK_DISCOUNT_RATE
```

### Example Fix 3: Add Type Hints

**Issue:** Missing type annotations

**Before:**
```python
def validate_email(email):
    if not email or '@' not in email:
        return False
    return True
```

**After:**
```python
def validate_email(email: str) -> bool:
    """Validate email format."""
    if not email or '@' not in email:
        return False
    return True
```

## Setting Up Quality Gates

1. In SonarCloud, go to your project
2. Click **Project Settings** → **Quality Gates**
3. Default gate is already applied
4. You can customize criteria:
   - Coverage threshold
   - Bugs allowed
   - Code smells allowed
   - Vulnerability severity

## Viewing Coverage Reports

1. In SonarCloud project, click **Coverage**
2. Shows:
   - Overall coverage percentage
   - Coverage by file
   - Lines covered/not covered
3. Click file to see which lines are tested

## Setting Up Pull Request Checks

1. SonarCloud integrates automatically with GitHub
2. For PRs, it:
   - Comments on code quality issues
   - Blocks merge if quality gate fails
   - Shows changed code coverage

To enable:
1. Go to SonarCloud Organization Settings
2. Click **General Settings**
3. Enable: "Analysis for pull requests"
4. Save

## Troubleshooting

### SonarCloud Analysis Not Running
- **Check 1:** Verify SONAR_TOKEN in GitHub Secrets
- **Check 2:** Verify GitHub Actions enabled in repository Settings
- **Check 3:** Check workflow file syntax in `.github/workflows/ci-cd-pipeline.yml`
- **Check 4:** View Actions tab for error messages

### No Coverage Data
- **Issue:** Coverage not being uploaded
- **Fix:** Ensure pytest-cov installed and coverage.xml generated
- **Fix:** Check sonar-project.properties has correct paths

### Quality Gate Failing
- **View Issues:** Go to SonarCloud project → Issues
- **Filter by Type:** Bugs, Code Smells, Vulnerabilities
- **Click Issue:** See code and suggested fix
- **Fix Code:** Push changes, pipeline re-runs automatically

### Organization Key Not Recognized
- **Fix:** Update workflow with correct organization key
- **Location:** `.github/workflows/ci-cd-pipeline.yml`
- **Key Parameter:** `-Dsonar.organization=russelllmtiaz222`

## Advanced Configuration

### Excluding Files from Analysis
Edit `sonar-project.properties`:
```properties
sonar.exclusions=load_tests/**,policies/**,config/**
```

### Custom Quality Profile
1. In SonarCloud, go to **Quality Profiles**
2. Click **Create**
3. Name it: `Custom Python Profile`
4. Customize rules
5. Apply to project

### Webhooks for Notifications
1. Go to Organization Settings → Webhooks
2. Add webhook to Slack/Teams
3. Get notified when analysis completes

## Next Steps

After setup:
1. ✅ Verify token is working
2. ✅ Check first analysis results
3. ✅ Review quality gate status
4. ✅ Fix critical issues
5. ✅ Set up branch protection rules
6. ✅ Configure notifications

## Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [GitHub Actions for SonarCloud](https://github.com/SonarSource/sonarcloud-github-action)
- [Quality Gate Documentation](https://docs.sonarcloud.io/improving/quality-gates/)
- [Coverage Reports](https://docs.sonarcloud.io/improving/improving-code-quality/)

---

**Happy analyzing!** 🎯
