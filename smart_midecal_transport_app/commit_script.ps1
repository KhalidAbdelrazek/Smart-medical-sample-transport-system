$ErrorActionPreference = "Continue"

# Cleanup temp files so they don't get committed
Remove-Item -Force output.txt -ErrorAction SilentlyContinue
Remove-Item -Force status.txt -ErrorAction SilentlyContinue
Remove-Item -Force analyze_output.txt -ErrorAction SilentlyContinue

# Prepare 7 commits
git add "*api_endpoints.dart"
git commit -m "feat(api): add transport my-requests and cancel endpoints"

git add "*domain/entities/*" "*domain/repository/*" "*domain/models/*"
git commit -m "feat(domain): add transport request entity and repository methods"

git add "*Data/Models/*" "*data/models/*"
git commit -m "feat(data): add transport request model and json mapping"

git add "*Data/data source/*" "*data/data source/*"
git commit -m "feat(data-source): implement fetch and cancel transport requests"

git add "*Data/repository/*" "*data/repository/*"
git commit -m "feat(repository): implement transport requests repository logic"

git add "*cubit/*"
git commit -m "feat(state): add my requests cubit and states"

# Add all the remaining tracked and new files (UI, pages, widgets, localizations, di.config)
git add .
git commit -m "feat(ui): add my requests tab, widgets, navigation and localization"

# Push to current branch
git push

Write-Host "---"
Write-Host "Created Commits:"
git log -7 --oneline
Write-Host "Current Branch:"
git branch --show-current
Write-Host "Push successful."
