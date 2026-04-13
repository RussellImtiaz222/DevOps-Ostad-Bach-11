# pre-commit hook: Enforce branch naming conventions (Windows PowerShell version)
# Branch names must follow: feature/, bugfix/, hotfix/, develop, main, release/

$branchName = (git rev-parse --abbrev-ref HEAD).Trim()

# Allow commits to main, develop, and release branches
if ($branchName -match '^(main|develop|master|release/.*)$') {
    Write-Host "✅ Branch naming validation PASSED for branch: $branchName" -ForegroundColor Green
    exit 0
}

# Enforce branch naming conventions for feature/bugfix/hotfix branches
if ($branchName -match '^(feature|bugfix|hotfix|docs|test|improvement)/[a-z0-9\-]+$') {
    Write-Host "✅ Branch naming validation PASSED for branch: $branchName" -ForegroundColor Green
    exit 0
}

# If we get here, branch name is invalid
Write-Host "❌ BRANCH NAME VALIDATION FAILED" -ForegroundColor Red
Write-Host ""
Write-Host "Your branch '$branchName' does not follow naming conventions." -ForegroundColor Red
Write-Host ""
Write-Host "Allowed branch naming patterns:" -ForegroundColor Yellow
Write-Host "  - feature/<feature-name>     - New feature development"
Write-Host "  - bugfix/<bug-name>          - Bug fixes"
Write-Host "  - hotfix/<issue-name>        - Hotfixes for production"
Write-Host "  - docs/<description>         - Documentation updates"
Write-Host "  - test/<test-name>           - Testing branches"
Write-Host "  - improvement/<improvement>  - Code improvements"
Write-Host "  - develop                    - Main development branch"
Write-Host "  - main                       - Production branch"
Write-Host "  - release/*                  - Release branches"
Write-Host ""
Write-Host "Examples of valid branches:" -ForegroundColor Yellow
Write-Host "  - feature/user-authentication"
Write-Host "  - bugfix/login-error"
Write-Host "  - hotfix/critical-security-patch"
Write-Host "  - docs/api-documentation"
Write-Host ""
Write-Host "Tips:" -ForegroundColor Yellow
Write-Host "  - Use lowercase letters and hyphens"
Write-Host "  - Avoid spaces and underscores"
Write-Host "  - Keep names descriptive but concise"
Write-Host ""
exit 1
