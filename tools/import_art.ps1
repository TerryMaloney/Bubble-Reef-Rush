# import_art.ps1 — copy generated art from the staging folder into the repo,
# then commit and push to the art branch.
#
# Run from PowerShell:
#     cd D:\BubbleReefRushArt
#     powershell -ExecutionPolicy Bypass -File .\import_art.ps1
#
# Adjust the two paths below if yours differ.

# --- paths ---------------------------------------------------------------
$Art    = "D:\BubbleReefRushArt\Pictures"          # where your downloaded PNGs live
$Repo   = "D:\BubbleReefRushArt\repo"              # local clone of the game repo
$Branch = "claude/geometry-dash-game-brainstorm-m5Thu"
$Url    = "https://github.com/TerryMaloney/Bubble-Reef-Rush.git"

# --- get the repo --------------------------------------------------------
if (-not (Test-Path (Join-Path $Repo ".git"))) {
    Write-Host "Cloning repo into $Repo ..." -ForegroundColor Cyan
    git clone $Url $Repo
}
Set-Location $Repo
git fetch origin
git checkout $Branch
git pull origin $Branch

# --- mapping: each destination + the keywords its source filename contains -
# (filenames came out flattened like 'assetsbackgroundsz1_bg_l0.png', so we
#  match by substring rather than exact name — tolerant of minor variations.)
$rules = @(
    @{ dest = "assets\backgrounds\z1_bg_l0.png";        needs = @("z1_bg_l0") },
    @{ dest = "assets\backgrounds\z1_bg_l1.png";        needs = @("z1_bg_l1") },
    @{ dest = "assets\backgrounds\z1_bg_l2.png";        needs = @("z1_bg_l2") },
    @{ dest = "assets\backgrounds\z1_bg_l3.png";        needs = @("z1_bg_l3") },
    @{ dest = "assets\backgrounds\z1_bg_l4.png";        needs = @("z1_bg_l4") },
    @{ dest = "assets\backgrounds\z1_bg_l5.png";        needs = @("z1_bg_l5") },
    @{ dest = "assets\characters\player.png";           needs = @("player_base") },
    @{ dest = "assets\characters\player_swim.png";      needs = @("player_swim") },
    @{ dest = "assets\characters\player_dive.png";      needs = @("player_dive") },
    @{ dest = "assets\characters\player_death.png";     needs = @("player_death") },
    @{ dest = "assets\obstacles\coral_spike_tip.png";   needs = @("coral_spike_tip") },
    @{ dest = "assets\obstacles\coral_spike_body.png";  needs = @("coral_spike_body") },
    @{ dest = "assets\obstacles\coral_spike_base.png";  needs = @("coral_spike_base") },
    @{ dest = "assets\obstacles\jellyfish_drift.png";   needs = @("jellyfish","drift") },
    @{ dest = "assets\obstacles\bubble_mine.png";       needs = @("bubble_mine") },
    @{ dest = "docs\art\style_ref.png";                 needs = @("style_ref") }
)

$all = Get-ChildItem -Path $Art -Filter *.png
$copied = 0
$missing = @()

foreach ($r in $rules) {
    $match = $all | Where-Object {
        $name = $_.Name.ToLower()
        $ok = $true
        foreach ($n in $r.needs) { if ($name -notlike "*$n*") { $ok = $false } }
        $ok
    } | Select-Object -First 1

    if ($null -eq $match) {
        $missing += $r.dest
        continue
    }
    $target = Join-Path $Repo $r.dest
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item $match.FullName $target -Force
    Write-Host ("  copied  {0,-40} <- {1}" -f $r.dest, $match.Name) -ForegroundColor Green
    $copied++
}

Write-Host ""
Write-Host "Copied $copied file(s)." -ForegroundColor Cyan
if ($missing.Count -gt 0) {
    Write-Host "Not found in staging (skipped):" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

# --- commit + push -------------------------------------------------------
git add assets docs
git commit -m "Add Zone 1 artwork (player, animations, backgrounds, obstacles)"
git push origin $Branch

Write-Host ""
Write-Host "Pushed to $Branch. Tell Claude it's pushed and it'll wire everything up." -ForegroundColor Cyan
