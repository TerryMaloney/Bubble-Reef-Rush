# pull_latest.ps1 — pull Claude's latest commits to your local machine.
#
# Run from PowerShell in your local repo folder:
#     cd D:\BubbleReefRushArt\repo
#     powershell -ExecutionPolicy Bypass -File .\tools\pull_latest.ps1
#
# After it finishes: open Godot and reimport the project so the engine picks
# up any new/changed scenes and scripts.

param(
    [string]$Branch = "claude/geometry-dash-game-brainstorm-m5Thu",
    [string]$Repo   = ""   # leave blank to use the current folder
)

$ErrorActionPreference = "Stop"

# --- locate the repo ---------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Repo)) { $Repo = (Get-Location).Path }
Set-Location $Repo

if (-not (Test-Path (Join-Path $Repo ".git"))) {
    Write-Host "ERROR: '$Repo' is not a git repository." -ForegroundColor Red
    Write-Host "cd into your local clone first, or pass -Repo C:\path\to\clone" -ForegroundColor Yellow
    exit 1
}

# --- fetch latest refs -------------------------------------------------------
Write-Host "Fetching origin ..." -ForegroundColor Cyan
git fetch origin

# --- make sure we're on the right branch -------------------------------------
$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) {
    Write-Host "Switching from '$current' to '$Branch' ..." -ForegroundColor Cyan
    git checkout $Branch 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Branch doesn't exist locally yet — create it tracking origin.
        git checkout -b $Branch --track "origin/$Branch"
    }
}

# --- pull with retry (handles flaky networks) --------------------------------
$maxTries = 4
$delay    = 2
for ($i = 1; $i -le $maxTries; $i++) {
    git pull origin $Branch
    if ($LASTEXITCODE -eq 0) { break }
    if ($i -lt $maxTries) {
        Write-Host "Pull failed (attempt $i/$maxTries). Retrying in ${delay}s ..." -ForegroundColor Yellow
        Start-Sleep -Seconds $delay
        $delay *= 2
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: pull failed after $maxTries attempts." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All changes pulled from '$Branch'." -ForegroundColor Green
Write-Host ""
Write-Host "Next step: open Godot and reimport the project." -ForegroundColor Yellow
Write-Host "  Option A: Project menu → Reimport" -ForegroundColor Yellow
Write-Host "  Option B: Close and reopen the project.godot file" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then play the game — all fixes are live." -ForegroundColor Cyan
