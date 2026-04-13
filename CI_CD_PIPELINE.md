# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions to automate testing, validation, and deployment workflows. The pipeline ensures code quality, enforces conventions, and prevents issues before they reach production.

## Pipeline Configuration

**Location**: `.github/workflows/ci-cd-pipeline.yml`

## Workflow Triggers

The CI/CD pipeline runs automatically when:

```yaml
on:
  push:
    branches:
      - main
      - develop
      - feature/*
      - bugfix/*
      - hotfix/*
  pull_request:
    branches:
      - main
      - develop
```

### Trigger Details

| Event | Branches | When |
|-------|----------|------|
| **push** | main, develop, feature/*, bugfix/*, hotfix/* | When you push commits to these branches |
| **pull_request** | main, develop | When creating or updating a PR to these branches |

## Pipeline Jobs

### 1. Validate Branch (validate-branch)

**Purpose**: Ensures branch names follow naming conventions

**Steps**:
1. Checkout repository code
2. Extract branch name from GitHub reference
3. Validate against allowed patterns
4. Report success or failure

**Validation Patterns**:
- `main` - Production branch
- `develop` - Development branch
- `feature/<name>` - Feature branches
- `bugfix/<name>` - Bug fix branches
- `hotfix/<name>` - Hotfix branches
- `docs/<name>` - Documentation branches
- `test/<name>` - Test branches
- `improvement/<name>` - Improvement branches
- `release/*` - Release branches

**Example Output**:
```
✅ Branch name is valid
Branch: feature/user-authentication
```

### 2. Code Quality Checks (code-quality)

**Purpose**: Analyzes code for quality issues and validates scripts

**Depends on**: validate-branch

**Steps**:
1. Check shell script syntax for all `.sh` files
2. Check PowerShell script syntax for all `.ps1` files
3. Verify README.md documentation exists
4. Count lines of documentation

**Example Output**:
```
🔍 Checking shell scripts...
Validating rebase_plan.sh...
✅ rebase_plan.sh is valid

✅ README.md exists
8521 README.md
```

### 3. Commit Message Validation (commit-message-validation)

**Purpose**: Validates all commit messages follow Conventional Commits format

**Depends on**: validate-branch

**Validation Checks**:
- Format: `<type>(<scope>): <subject>`
- Minimum subject length: 10 characters
- Allowed types: feat, fix, docs, style, refactor, perf, test, chore
- Skip merge commits automatically
- Allow `[skip ci]` flag

**Example Output**:
```
✅ Valid: 7d77934 - Add rebase editor scripts
✅ Merge commit: 404c1bb
❌ Invalid: 3a2c1f5 - Fixed bug
   Must follow: <type>(<scope>): <subject>
```

**Valid Message Examples**:
```
feat(auth): implement user authentication system
fix(login): resolve password reset issue
docs: update installation guide
test(api): add unit tests for API endpoints
refactor(core): improve code structure
chore(deps): update dependencies to latest versions
```

### 4. Test Scripts (test-scripts)

**Purpose**: Executes and validates all scripts in the repository

**Depends on**: validate-branch

**Tests**:
1. Execute shell scripts in syntax-check mode
2. Check PowerShell script validity
3. Search for outstanding TODO/FIXME/HACK comments
4. Verify no unresolved issues marked in code

**Example Output**:
```
🧪 Testing shell scripts...
Testing rebase_plan.sh...
✅ rebase_plan.sh passed syntax check

🔍 Checking for forbidden patterns...
✅ No outstanding TODOs found
```

### 5. CI/CD Summary (summary)

**Purpose**: Provides comprehensive report of all checks

**Depends on**: validate-branch, code-quality, commit-message-validation, test-scripts

**Reports**:
- Workflow name
- Trigger event (push/pull_request)
- Branch name
- Commit SHA
- Status of all previous jobs
- Overall pass/fail

**Example Output**:
```
==========================================
CI/CD Pipeline Execution Summary
==========================================
Workflow: CI/CD Pipeline
Event: push
Branch: feature/user-auth
Commit: 7d77934abc123def456
==========================================
✅ All checks passed!
```

## Pipeline Status Indicators

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| ✅ All checks passed | Code meets all standards | Ready to merge |
| ⏳ Running | Pipeline is executing | Wait for completion |
| ❌ Failed | One or more checks failed | Fix issues and push again |
| ⚠️ Warnings | Non-blocking issues found | Review and address if needed |

## Viewing Pipeline Results

### On GitHub

1. Go to your repository on GitHub
2. Click on the **Actions** tab
3. Select the workflow run you want to view
4. Click on a job to see detailed logs

### In Git Command Line

```bash
# View workflow status
gh workflow list

# View recent runs
gh run list --all

# View specific run details
gh run view <run-id>

# View logs for a specific job
gh run view <run-id> --log
```

## Pipeline Behavior by Branch

### feature/* branches

```
Trigger: Push to feature/name
Pipeline: Full validation
Status: Must pass all checks to merge to develop
PR Target: develop
```

### bugfix/* branches

```
Trigger: Push to bugfix/name
Pipeline: Full validation
Status: Must pass all checks to merge to develop
PR Target: develop
```

### hotfix/* branches

```
Trigger: Push to hotfix/name
Pipeline: Full validation
Status: Must pass all checks to merge to main
PR Target: main
```

### develop branch

```
Trigger: Push to develop
Pipeline: Full validation + integration tests
Status: Auto-validates all incoming changes
Protection: Requires PR review and passing checks
```

### main branch

```
Trigger: Push to main
Pipeline: Full validation + deployment checks
Status: Auto-validates all incoming changes
Protection: Requires PR review, passing checks, and branch up-to-date
Deployment: Triggers production release
```

## Common Scenarios

### Scenario 1: Feature Branch with Invalid Commit Message

```bash
# Branch: feature/new-login
# Commit: "Added login functionality"  # ❌ Invalid format

# Pipeline Output:
# ❌ validate-branch: PASSED
# ❌ code-quality: PASSED
# ❌ commit-message-validation: FAILED
#    Invalid: abc1234 - Added login functionality
#    Must follow: <type>(<scope>): <subject>
# ⏭️  test-scripts: SKIPPED (dependency failed)
# ❌ summary: FAILED

# Fix:
git commit --amend -m "feat(auth): implement login functionality"
git push --force-with-lease
```

### Scenario 2: Invalid Branch Name

```bash
# Branch: NewFeature  # ❌ Invalid (uppercase, no prefix)

# Pipeline Output:
# ❌ validate-branch: FAILED
#    Invalid branch name: NewFeature
#    Must follow conventions: feature/, bugfix/, hotfix/, etc.
# ⏭️  All other jobs: SKIPPED (dependency failed)
# ❌ summary: FAILED

# Fix:
git branch -m NewFeature feature/new-feature
git push --force-with-lease origin feature/new-feature
```

### Scenario 3: Documentation Only Change

```bash
# Branch: docs/api-guide
# Commit: "docs: update API documentation"
# Files: README.md (documentation only)

# Expected:
# ✅ All checks pass
# Can be merged to develop

# Optional: Skip CI if only documentation
git commit -m "docs: update guide [skip ci]"
```

### Scenario 4: Shell Script with Syntax Error

```bash
# File: rebase_plan.sh has syntax error

# Pipeline Output:
# ✅ validate-branch: PASSED
# ❌ code-quality: FAILED
#    Checking shell scripts...
#    rebase_plan.sh has errors
# ⏭️  Other jobs: May continue or skip based on settings
# ❌ summary: FAILED

# Fix:
# Correct the syntax in rebase_plan.sh
bash -n rebase_plan.sh  # Test locally
git add rebase_plan.sh
git commit -m "fix: correct shell script syntax"
git push
```

## Performance & Execution Time

| Job | Expected Duration | Factors |
|-----|-------------------|---------|
| validate-branch | < 1 min | Branch name parsing |
| code-quality | 1-2 min | Number of files, script size |
| commit-message-validation | < 1 min | Number of commits |
| test-scripts | 1-3 min | Script complexity, number of files |
| summary | < 1 min | Report generation |
| **Total** | **3-7 min** | Parallel execution reduces time |

## Best Practices

### 1. Run Local Validation Before Pushing

```bash
# Test branch naming
git rev-parse --abbrev-ref HEAD

# Test commit message
git log -1 --format=%B

# Test shell scripts
bash -n *.sh

# Test PowerShell scripts
pwsh -NoProfile -Command "[System.IO.Path]::GetFullPath('.')"
```

### 2. Keep Commits Atomic

- One logical change per commit
- Easier to understand in history
- Simpler to revert if needed

### 3. Use Meaningful Commit Messages

```bash
# Good
git commit -m "feat(payment): add stripe integration"

# Bad
git commit -m "stuff"
```

### 4. Resolve Issues Locally First

```bash
# Fix syntax before pushing
bash -n rebase_plan.sh
shellcheck rebase_plan.sh  # If installed

# Test message locally
git commit -m "feat(test): test message"  # Will trigger hook
```

### 5. Review Logs When Pipeline Fails

- Check the specific job that failed
- Look at error output
- Fix the issue
- Test locally
- Push again

## Debugging Pipeline Issues

### Enable Debug Logging

```yaml
# Add to workflow for debugging
env:
  ACTIONS_STEP_DEBUG: true
```

### View Full Logs

1. Go to GitHub Actions tab
2. Click the failed run
3. Click the failed job
4. Expand each step to see full output
5. Look for error messages

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Branch validation failed | Invalid branch name | Rename branch to follow conventions |
| Commit message validation failed | Wrong message format | Use `<type>(<scope>): <subject>` |
| Shell script syntax error | Syntax mistake in .sh file | Fix and test with `bash -n` |
| No README found | Missing documentation | Create/restore README.md |

## Disabling or Modifying Pipeline

### To Disable Specific Jobs

Edit `.github/workflows/ci-cd-pipeline.yml`:

```yaml
# Comment out the job
# commit-message-validation:
#   name: Validate Commit Messages
#   ...
```

### To Add Custom Checks

1. Edit `.github/workflows/ci-cd-pipeline.yml`
2. Add new job under `jobs:`
3. Specify dependencies and steps
4. Commit and push

### To Change Validation Rules

Edit the validation patterns in the workflow file:

```yaml
- run: |
    # Modify validation regex patterns
    if [[ $BRANCH_NAME =~ ^(custom|pattern).*$ ]]; then
```

## Integration with IDE

### VS Code

1. Install **GitHub Actions** extension
2. View pipeline status in sidebar
3. Click to view detailed logs
4. Directly in editor notifications

### GitHub Desktop

1. Top menu: **Repository** → **Open on GitHub**
2. Click **Actions** tab
3. View all workflow runs

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
