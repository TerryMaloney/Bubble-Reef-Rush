# push_all.ps1 — stage every local change, commit, and push to the work branch.
#
# Run from PowerShell (in your local repo folder):
#     cd D:\BubbleReefRushArt\repo
#     powershell -ExecutionPolicy Bypass -File .\tools\push_all.ps1
#
# Optional: pass your own commit message:
#     powershell -ExecutionPolicy Bypass -File .\tools\push_all.ps1 -Message "My changes"

param(
    [string]$Message = "",
    [string]$Branch  = "claude/geometry-dash-game-brainstorm-m5Thu",
    [string]$Repo    = ""   # leave blank to use the current folder
)

$ErrorActionPreference = "Stop"

# --- locate the repo -----------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Repo)) { $Repo = (Get-Location).Path }
Set-Location $Repo

if (-not (Test-Path (Join-Path $Repo ".git"))) {
    Write-Host "ERROR: '$Repo' is not a git repository." -ForegroundColor Red
    Write-Host "cd into your local clone first, or pass -Repo C:\path\to\clone" -ForegroundColor Yellow
    exit 1
}

# --- make sure we're on the right branch (create it if needed) -----------
Write-Host "Fetching origin ..." -ForegroundColor Cyan
git fetch origin

$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) {
    Write-Host "Switching from '$current' to '$Branch' ..." -ForegroundColor Cyan
    git checkout $Branch 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Branch doesn't exist locally — create it tracking origin if present.
        git checkout -b $Branch 2>$null
    }
}

# Pull latest so the push is a fast-forward (ignore failure if branch is new).
git pull origin $Branch 2>$null

# --- stage everything ----------------------------------------------------
git add -A

# Nothing to commit? Stop cleanly.
$pending = git status --porcelain
if ([string]::IsNullOrWhiteSpace($pending)) {
    Write-Host "Nothing to commit — working tree is clean." -ForegroundColor Yellow
    Write-Host "Pushing anyway in case local commits are ahead ..." -ForegroundColor Cyan
} else {
    Write-Host "Staging these changes:" -ForegroundColor Green
    git status --short

    # --- commit ----------------------------------------------------------
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        $Message = "Update from local machine ($stamp)"
    }
    git commit -m $Message
}

# --- push with retry (handles flaky networks) ----------------------------
$maxTries = 4
$delay    = 2
for ($i = 1; $i -le $maxTries; $i++) {
    git push -u origin $Branch
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Pushed to $Branch." -ForegroundColor Cyan
        exit 0
    }
    if ($i -lt $maxTries) {
        Write-Host "Push failed (attempt $i/$maxTries). Retrying in ${delay}s ..." -ForegroundColor Yellow
        Start-Sleep -Seconds $delay
        $delay *= 2
    }
}

Write-Host "ERROR: push failed after $maxTries attempts." -ForegroundColor Red
exit 1
