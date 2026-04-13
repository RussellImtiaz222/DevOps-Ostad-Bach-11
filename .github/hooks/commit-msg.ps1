# commit-msg hook: Enforce commit message format (Windows PowerShell version)
# Requires messages to follow: <type>(<scope>): <subject>
# Types: feat, fix, docs, style, refactor, perf, test, chore

param([string]$CommitMsgFile)

$commitMsg = Get-Content $CommitMsgFile -Raw

# Skip the hook for merge commits
if ($commitMsg -match "^Merge") {
    exit 0
}

# Pattern: type(scope): subject or type: subject
# Allow commits with just [skip ci] or merge commits
if ($commitMsg -match '^\s*(feat|fix|docs|style|refactor|perf|test|chore)(\(.+\))?: .{10,}' -or `
    $commitMsg -match '\[skip ci\]' -or `
    $commitMsg -match '^Merge') {
    Write-Host "✅ Commit message validation PASSED" -ForegroundColor Green
    exit 0
}

# If we get here, commit message format is invalid
Write-Host "❌ COMMIT MESSAGE VALIDATION FAILED" -ForegroundColor Red
Write-Host ""
Write-Host "Your commit message must follow this format:" -ForegroundColor Yellow
Write-Host "  <type>(<scope>): <subject>"
Write-Host ""
Write-Host "Allowed types:" -ForegroundColor Yellow
Write-Host "  - feat:     A new feature"
Write-Host "  - fix:      A bug fix"
Write-Host "  - docs:     Documentation only changes"
Write-Host "  - style:    Changes that don't affect code meaning (formatting, missing semicolons, etc)"
Write-Host "  - refactor: Code change that neither fixes a bug nor adds a feature"
Write-Host "  - perf:     Code change that improves performance"
Write-Host "  - test:     Adding or updating tests"
Write-Host "  - chore:    Changes to build process, dependency updates, etc"
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host "  feat(auth): implement user authentication"
Write-Host "  fix(login): resolve password reset issue"
Write-Host "  docs: update installation guide"
Write-Host "  test(api): add unit tests for API endpoints"
Write-Host ""
Write-Host "Your message:" -ForegroundColor Red
Write-Host "  $commitMsg"
Write-Host ""
exit 1
