# Branch Naming Conventions Guide

## Overview

This document defines the branch naming conventions used in this repository for better organization, automated workflows, and team collaboration.

## Allowed Branch Patterns

### Feature Branches
**Pattern**: `feature/<feature-name>`

Used for developing new features or enhancements.

**Examples**:
- `feature/user-authentication`
- `feature/payment-system`
- `feature/dark-mode-ui`
- `feature/api-documentation`
- `feature/database-optimization`

**Rules**:
- Use present tense action words: "add", "implement", "create"
- Separate words with hyphens
- Be descriptive but concise (2-5 words)
- Lowercase only

**Workflow**:
```bash
git checkout -b feature/user-authentication develop
# ... make changes ...
git push origin feature/user-authentication
# Create PR to develop branch
```

---

### Bugfix Branches
**Pattern**: `bugfix/<bug-name>`

Used for fixing bugs in the develop branch or during development.

**Examples**:
- `bugfix/login-error`
- `bugfix/memory-leak`
- `bugfix/payment-timeout`
- `bugfix/ui-rendering-issue`
- `bugfix/incorrect-calculation`

**Rules**:
- Describe what is being fixed
- Be specific about the issue
- Separate words with hyphens
- Lowercase only

**Workflow**:
```bash
git checkout -b bugfix/login-error develop
# ... fix the bug ...
git push origin bugfix/login-error
# Create PR to develop branch
```

---

### Hotfix Branches
**Pattern**: `hotfix/<issue-name>`

Used for urgent fixes to production (main branch). Should be created from main, not develop.

**Examples**:
- `hotfix/critical-security-patch`
- `hotfix/data-loss-prevention`
- `hotfix/service-outage-fix`
- `hotfix/payment-failure`

**Rules**:
- Used only for critical, production issues
- Should be created from main branch
- Merged back to both main and develop
- Separate words with hyphens
- Lowercase only

**Workflow**:
```bash
git checkout -b hotfix/critical-security-patch main
# ... fix the critical issue ...
git push origin hotfix/critical-security-patch
# Create PR to main AND develop branches
```

**Important**: Always merge hotfixes back to both main and develop to prevent regression.

---

### Documentation Branches
**Pattern**: `docs/<description>`

Used for documentation updates, guides, and README changes.

**Examples**:
- `docs/api-documentation`
- `docs/setup-guide`
- `docs/deployment-instructions`
- `docs/architecture-overview`
- `docs/troubleshooting-guide`

**Rules**:
- Clearly describe what documentation is being updated
- Separate words with hyphens
- Lowercase only

**Workflow**:
```bash
git checkout -b docs/api-documentation develop
# ... update documentation ...
git push origin docs/api-documentation
# Create PR to develop branch
```

---

### Test Branches
**Pattern**: `test/<test-name>`

Used for creating tests, test automation, or testing new approaches.

**Examples**:
- `test/unit-tests`
- `test/integration-tests`
- `test/e2e-tests`
- `test/load-testing`
- `test/security-testing`

**Rules**:
- Describe what is being tested
- Separate words with hyphens
- Lowercase only

**Workflow**:
```bash
git checkout -b test/integration-tests develop
# ... create tests ...
git push origin test/integration-tests
# Create PR to develop branch
```

---

### Improvement Branches
**Pattern**: `improvement/<improvement-description>`

Used for code improvements, refactoring, and performance enhancements that don't add features.

**Examples**:
- `improvement/database-performance`
- `improvement/code-modularity`
- `improvement/error-handling`
- `improvement/logging-system`
- `improvement/caching-mechanism`

**Rules**:
- Describe the improvement being made
- Separate words with hyphens
- Lowercase only

**Workflow**:
```bash
git checkout -b improvement/database-performance develop
# ... make improvements ...
git push origin improvement/database-performance
# Create PR to develop branch
```

---

### Protected Branches

These branches are protected and should not be used for feature development.

#### `main`
- Production-ready code
- Only merge releases and hotfixes
- Must have passing CI/CD checks
- Requires code review and approval

#### `develop`
- Integration branch for features
- Acts as main development branch
- All features merge here first
- Must have passing CI/CD checks
- Requires code review and approval

#### `release/*`
- Release branches for version management
- **Pattern**: `release/v<major>.<minor>.<patch>`
- **Examples**:
  - `release/v1.0.0`
  - `release/v2.1.0`
  - `release/v3.0.0-beta`

**Workflow**:
```bash
# Create release branch from develop
git checkout -b release/v1.0.0 develop
# ... make release changes, update versions ...
git push origin release/v1.0.0
# Create PR to main for final review
```

---

## Naming Rules Summary

### Do's ✅

- ✅ Use lowercase letters only
- ✅ Use hyphens to separate words
- ✅ Be descriptive and specific
- ✅ Keep names concise (2-5 words)
- ✅ Use consistent naming patterns
- ✅ Include issue/ticket number if available

**Example**:
```
feature/user-authentication
bugfix/login-button-error
improvement/database-performance
```

### Don'ts ❌

- ❌ Do NOT use uppercase letters
- ❌ Do NOT use underscores
- ❌ Do NOT use spaces
- ❌ Do NOT use special characters (!@#$%^&*)
- ❌ Do NOT use vague names like "fix", "temp", "test"
- ❌ Do NOT deviate from standard patterns

**Invalid Examples**:
```
Feature/Authentication         # Uppercase letters
feature_authentication         # Underscore instead of hyphen
feature/user auth             # Space instead of hyphen
feature/a                     # Too vague
NewFeature                    # Missing pattern prefix
fix                          # No prefix, too vague
temp123                      # No pattern, unclear purpose
```

---

## Branch Naming with Issue Tracking

If your repository uses issue tracking (GitHub Issues, Jira, etc.), include the issue number:

**Pattern**: `<type>/<issue-number>-<description>`

**Examples**:
- `feature/123-user-authentication`
- `bugfix/456-login-error`
- `improvement/789-database-optimization`

**Workflow with Issue Tracking**:
```bash
# Reference issue #123 in branch name
git checkout -b feature/123-user-authentication develop

# Reference same issue in commit message for linking
git commit -m "feat(auth): implement user authentication (#123)"
```

---

## Workflow Examples

### Example 1: Developing a Feature

```bash
# Start from develop branch
git checkout develop
git pull origin develop

# Create feature branch with descriptive name
git checkout -b feature/user-authentication

# Make changes and commit
git add .
git commit -m "feat(auth): add login form component"
git commit -m "feat(auth): implement authentication service"
git commit -m "test(auth): add authentication tests"

# Push feature branch
git push origin feature/user-authentication

# On GitHub, create PR from feature/user-authentication → develop
# Get review, address feedback, merge when approved
```

### Example 2: Fixing a Bug

```bash
# Start from develop branch
git checkout develop
git pull origin develop

# Create bugfix branch
git checkout -b bugfix/login-button-error

# Fix bug and commit
git add .
git commit -m "fix(ui): resolve login button click handler"

# Push and create PR
git push origin bugfix/login-button-error
```

### Example 3: Hotfixing Production

```bash
# Start from main branch (production)
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/critical-security-patch

# Apply fix
git add .
git commit -m "fix(security): patch critical vulnerability"

# Push hotfix
git push origin hotfix/critical-security-patch

# Create TWO PRs:
# 1. hotfix/critical-security-patch → main (urgent)
# 2. hotfix/critical-security-patch → develop (prevent regression)

# After merging to main, also merge to develop
```

---

## Branch Cleanup

### List All Branches

```bash
# Local branches
git branch

# Remote branches
git branch -r

# All branches with last commit info
git branch -v
```

### Delete Merged Branches

```bash
# Delete local branch
git branch -d feature/user-auth

# Delete remote branch
git push origin --delete feature/user-auth

# Force delete if needed (use carefully!)
git branch -D feature/user-auth
```

### Archive Long-Lived Branches

For branches that won't be deleted but are no longer active:

```bash
# Tag the branch for archival
git tag archive/feature/old-feature feature/old-feature

# Delete the branch
git branch -d feature/old-feature
git push origin --delete feature/old-feature

# Reference later if needed
git log archive/feature/old-feature
```

---

## CI/CD Integration

The CI/CD pipeline validates branch names automatically:

- ✅ **Valid**: Pipeline runs all checks
- ❌ **Invalid**: Pipeline fails at first step

**CI/CD Output for Invalid Branch**:
```
❌ BRANCH NAME VALIDATION FAILED
Your branch 'NewFeature' does not follow naming conventions.

Allowed patterns:
  - feature/<feature-name>
  - bugfix/<bug-name>
  - hotfix/<issue-name>
  - docs/<description>
  - test/<test-name>
  - improvement/<improvement>
  - develop
  - main
  - release/*
```

---

## Team Communication

### When Naming Branches

1. **Clarity**: Make the name clear to other team members
2. **Consistency**: Follow established patterns
3. **Searchability**: Use terms that appear in issues/tickets
4. **Brevity**: Keep names reasonably short

### Examples of Good Communication

```bash
# Clear, follows pattern
git checkout -b feature/user-authentication

# Not ideal - unclear purpose
git checkout -b feature/stuff

# Audit trail
git push origin feature/user-authentication  # Links to issue tracking
```

---

## References

- [Git Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
