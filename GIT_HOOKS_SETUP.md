# Git Hooks Configuration Guide

## Overview

This project uses Git hooks to enforce consistent commit messages and branch naming conventions. Git hooks are automatically triggered at key points in the Git workflow.

## Available Hooks

### 1. commit-msg Hook
**Purpose**: Validates commit message format following Conventional Commits
**Location**: `.github/hooks/commit-msg` (wrapper) and `.github/hooks/commit-msg.ps1` (PowerShell)
**When triggered**: When creating a commit
**Requirements**: Message must follow `<type>(<scope>): <subject>` format

### 2. pre-commit Hook
**Purpose**: Validates branch naming conventions
**Location**: `.github/hooks/pre-commit` (wrapper) and `.github/hooks/pre-commit.ps1` (PowerShell)
**When triggered**: Before committing changes
**Requirements**: Branch name must follow allowed patterns (feature/, bugfix/, hotfix/, etc.)

## Setup Instructions

### For Windows Users

The hooks are already configured for Windows. Git will automatically use the PowerShell versions when you run `git commit`.

#### Prerequisites
- Git 2.9+ (recommended: 2.40+)
- PowerShell 5.0+ (included in Windows 10+)
- Execution policy allowing script execution

#### Verify Hooks Are Enabled
```powershell
cd "C:\Users\iruss\DevOps Ostad 11"
git config core.hooksPath
# Output should show: .github/hooks
```

#### If hooks are not working, enable them:
```powershell
git config core.hooksPath .github/hooks
```

### For macOS/Linux Users

If adapting for Unix-like systems:

1. Update the shebang line in PowerShell scripts:
   ```bash
   # Change from: #!/bin/bash
   # To match your shell: #!/bin/bash or #!/bin/sh
   ```

2. Make scripts executable:
   ```bash
   chmod +x .github/hooks/commit-msg
   chmod +x .github/hooks/pre-commit
   ```

## Testing the Hooks

### Test Commit Message Validation

#### This will FAIL (invalid format):
```bash
git commit -m "Fixed login bug"
```

Expected error output:
```
❌ COMMIT MESSAGE VALIDATION FAILED
Your commit message must follow this format:
  <type>(<scope>): <subject>
```

#### This will SUCCEED (valid format):
```bash
git commit -m "fix(auth): resolve login error handling"
```

Expected success output:
```
✅ Commit message validation PASSED
```

### Test Branch Naming Validation

#### Create a properly named branch:
```bash
git checkout -b feature/test-feature
touch testfile.txt
git add testfile.txt
git commit -m "test: add test file"
# Should succeed
```

#### Try to commit from an invalid branch:
```bash
git checkout -b InvalidBranch
# This will fail when you run git commit
```

Expected error output:
```
❌ BRANCH NAME VALIDATION FAILED
Your branch 'InvalidBranch' does not follow naming conventions.
Allowed branch naming patterns:
  - feature/<feature-name>     - New feature development
  - bugfix/<bug-name>          - Bug fixes
  ...
```

## Troubleshooting

### Issue: Hook not executing or returning exit code 0

**Solution**: Verify hooks path is configured:
```bash
git config core.hooksPath
```

If not set, run:
```bash
git config core.hooksPath .github/hooks
```

### Issue: PowerShell execution policy error

**Solution**: On Windows PowerShell, you may need to adjust execution policy:
```powershell
# For current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# For current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Issue: Hooks not triggering on push

**Note**: Local hooks (pre-commit, commit-msg) only work on your local machine. Server-side validation is handled by GitHub Actions CI/CD pipeline.

To validate on the server:
- Push to a remote branch
- Create a pull request
- GitHub Actions will run the full validation pipeline

### Issue: Need to bypass hooks temporarily

**For commit-msg validation**:
```bash
git commit --no-verify -m "docs: update changelog"
```

**Warning**: Use `--no-verify` only for legitimate cases (documentation updates, emergency fixes).

## Hook Implementation Details

### Commit Message Hook Logic

1. Reads commit message from `.git/COMMIT_EDITMSG`
2. Skips validation for merge commits
3. Validates against pattern: `^(feat|fix|docs|style|refactor|perf|test|chore)(\(.+\))?: .{10,}`
4. Allows `[skip ci]` flag to bypass validation
5. Returns exit code 0 (success) or 1 (failure)

### Branch Naming Hook Logic

1. Gets current branch name using `git rev-parse --abbrev-ref HEAD`
2. Allows main, develop, and release/* branches as-is
3. Validates other branches against: `^(feature|bugfix|hotfix|docs|test|improvement)/[a-z0-9\-]+$`
4. Returns exit code 0 (success) or 1 (failure)

## Integration with CI/CD

- **Local Validation**: Hooks run on your machine before committing
- **CI/CD Validation**: GitHub Actions validates all commits and branches again
- **Branch Protection**: Main and develop branches have protection rules enabled
- **Pull Request Checks**: All PR merges require passing CI/CD checks

## Best Practices

1. **Always validate before pushing**
   - Hooks catch issues locally before they reach the repository

2. **Use meaningful commit messages**
   - Follow the format consistently
   - Be specific about what changed and why

3. **Use appropriate branch names**
   - Use feature/ for new features
   - Use bugfix/ for bug fixes
   - Use hotfix/ for critical production fixes

4. **Never use --no-verify in normal workflow**
   - It defeats the purpose of validation
   - Only use for legitimate edge cases

5. **Keep hooks updated**
   - Review hooks regularly
   - Update patterns if requirements change
   - Document any custom extensions

## Disabling Hooks Permanently

If you need to disable hooks (not recommended):

```bash
# Disable all hooks
git config core.hooksPath /dev/null

# Or remove the hooks path
git config --unset core.hooksPath
```

## Extending Hooks

To add custom validation:

1. Create a new hook file in `.github/hooks/`
2. Example: `.github/hooks/pre-push` for push validation
3. Make it executable: `chmod +x .github/hooks/pre-push`
4. Add your validation logic

## References

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
