param($todoFile)
(Get-Content $todoFile) -replace '^pick\s+c409e3c','squash c409e3c' | Set-Content $todoFile
(Get-Content $todoFile) -replace '^pick\s+51f1e4c','squash 51f1e4c' | Set-Content $todoFile
(Get-Content $todoFile) -replace '^pick\s+5f59347','reword 5f59347' | Set-Content $todoFile
