<#
.SYNOPSIS
    Sync the latest Beam changes from Cowork into this repo, commit, and push.

.DESCRIPTION
    One-shot workflow for Jacob's iteration loop with Claude / Cowork.

    Each iteration, Claude stages a push-ready drop in its Cowork outputs
    folder:
      - .beam-pending-commit.txt   (REQUIRED - tagline + description)
            Line 1     = commit tagline (becomes the commit subject)
            Line 2     = blank
            Line 3+    = commit description / body
      - any combination of app files (index.html, *.js, *.css, *.svg, etc.)

    Run from anywhere inside the beam clone, this script will:
      1. Auto-discover the most recently modified Cowork outputs folder
         that actually contains .beam-pending-commit.txt (so a second
         Cowork tab with a stale outputs folder can't hijack the push).
      2. Copy every app-level file in that outputs folder into the repo
         root - known names (index.html, README.md, CNAME) plus a glob
         of common web/static asset extensions.
      3. Pull the pending commit message into the system temp folder
         (NEVER committed - stays out of git history).
      4. Preview the tagline + description and the changes to be committed.
      5. Ask for confirmation.
      6. git add -A, git commit -F <msg>, git push.

    Recommended launcher: beam-push.cmd (double-click friendly; keeps
    the window open on both success and failure).

.EXAMPLE
    PS> .\scripts\beam-push.ps1

.NOTES
    Requires: PowerShell 5+ (built-in on Windows 10/11), git on PATH.
    ASCII-only on purpose so PowerShell 5.1 does not choke on encoding.
#>

$HOLD_OPEN = $true
$script:exitCode = 0

function Stop-Here([int]$code = 0) {
    $script:exitCode = $code
    if ($HOLD_OPEN) {
        Write-Host ""
        Write-Host "Press Enter to close..." -ForegroundColor DarkGray
        Read-Host | Out-Null
    }
    exit $code
}

try {
    $ErrorActionPreference = 'Stop'

    Write-Host ""
    Write-Host "=== Beam push ===" -ForegroundColor Cyan

    # -- Verify git is on PATH ---------------------------------------
    $gitExe = (Get-Command git -ErrorAction SilentlyContinue)
    if (-not $gitExe) {
        Write-Host "git is not on PATH. Install Git for Windows (https://git-scm.com/) and reopen your terminal." -ForegroundColor Red
        Stop-Here 1
    }

    # -- Locate the repo root (dir containing .git) ------------------
    $repoRoot = $null
    try { $repoRoot = (& git rev-parse --show-toplevel 2>$null) } catch {}
    if (-not $repoRoot) {
        Write-Host "Not inside a git repository." -ForegroundColor Red
        Write-Host "Current directory: $(Get-Location)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Put beam-push.cmd / beam-push.ps1 in your beam clone (ideally under scripts\)," -ForegroundColor Yellow
        Write-Host "and double-click the .cmd from there." -ForegroundColor Yellow
        Stop-Here 1
    }
    Set-Location $repoRoot
    Write-Host "Repo:   $repoRoot" -ForegroundColor Cyan

    # -- Auto-discover the right Cowork outputs folder ---------------
    # Prefer the most-recently-modified 'outputs' folder that ALSO
    # contains the commit-message stamp (.beam-pending-commit.txt).
    # That stamp is Claude's "I have staged a full push-ready drop
    # here" signal, so an otherwise-fresher but empty session (e.g.
    # a second Cowork tab) cannot hijack the push.
    $base = Join-Path $env:APPDATA "Claude\local-agent-mode-sessions"
    if (-not (Test-Path $base)) {
        Write-Host "Cowork sessions folder not found at: $base" -ForegroundColor Red
        Write-Host "Make sure Claude / Cowork has been opened at least once." -ForegroundColor Yellow
        Stop-Here 1
    }

    $outputsDir = Get-ChildItem -Path $base -Directory -Recurse -Filter 'outputs' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName '.beam-pending-commit.txt') } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $outputsDir) {
        Write-Host "No Cowork 'outputs' folder with .beam-pending-commit.txt found under:" -ForegroundColor Red
        Write-Host "  $base" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Ask Claude to emit .beam-pending-commit.txt (tagline + description)" -ForegroundColor Yellow
        Write-Host "into its outputs folder, then rerun." -ForegroundColor Yellow
        Stop-Here 1
    }

    $srcRoot   = $outputsDir.FullName
    $srcCommit = Join-Path $srcRoot '.beam-pending-commit.txt'

    Write-Host "Source: $srcRoot" -ForegroundColor Cyan
    Write-Host "        (modified $($outputsDir.LastWriteTime))" -ForegroundColor DarkGray

    # -- Copy files into repo ----------------------------------------
    # Everything in Cowork outputs that looks like an app file is copied
    # into the repo root. The commit-message file is excluded - it lives
    # in TEMP only, never in git history.
    #
    # No single file is strictly required: docs/scripts-only commits
    # work too. The git status preview below catches accidents.
    Write-Host ""
    Write-Host "Copying files into repo..." -ForegroundColor Cyan

    $copiedCount = 0
    $named       = @('index.html', 'README.md', 'CNAME', 'firestore.rules')
    foreach ($name in $named) {
        $src = Join-Path $srcRoot $name
        if (Test-Path $src) {
            Copy-Item -Force $src (Join-Path $repoRoot $name)
            $copiedCount++
            $padded = $name.PadRight(16)
            Write-Host "  $padded -> repo root" -ForegroundColor DarkGray
        }
    }

    $assetPatterns = @('*.js', '*.css', '*.json', '*.webmanifest', '*.png', '*.svg', '*.ico', '*.webp', '*.jpg', '*.jpeg', '*.html')
    foreach ($pat in $assetPatterns) {
        Get-ChildItem -Path $srcRoot -File -Filter $pat -ErrorAction SilentlyContinue |
            Where-Object { $named -notcontains $_.Name } |
            ForEach-Object {
                Copy-Item -Force $_.FullName (Join-Path $repoRoot $_.Name)
                $copiedCount++
                $padded = $_.Name.PadRight(16)
                Write-Host "  $padded -> repo root" -ForegroundColor DarkGray
            }
    }

    if ($copiedCount -eq 0) {
        Write-Host "  (nothing app-level to copy - will commit whatever is already uncommitted)" -ForegroundColor DarkGray
    }

    # Pull commit message into TEMP (not into the repo)
    $tmpCommitFile = Join-Path $env:TEMP 'beam-pending-commit.txt'
    Copy-Item -Force $srcCommit $tmpCommitFile

    # -- Preview commit message (tagline + description) --------------
    Write-Host ""
    Write-Host "=== Commit message ===" -ForegroundColor Cyan
    $lines = Get-Content $tmpCommitFile

    if ($lines.Count -ge 1) {
        Write-Host "  Tagline:" -ForegroundColor DarkCyan
        Write-Host "    $($lines[0])" -ForegroundColor White
    }
    # Skip line index 1 (the blank separator) when printing the description
    $descStart = 1
    if ($lines.Count -ge 2 -and [string]::IsNullOrWhiteSpace($lines[1])) {
        $descStart = 2
    }
    if ($lines.Count -gt $descStart) {
        Write-Host "  Description:" -ForegroundColor DarkCyan
        $printed = 0
        for ($i = $descStart; $i -lt $lines.Count -and $printed -lt 8; $i++) {
            Write-Host "    $($lines[$i])" -ForegroundColor DarkGray
            $printed++
        }
        if ($lines.Count - $descStart -gt 8) {
            Write-Host "    ... ($($lines.Count - $descStart) description lines total)" -ForegroundColor DarkGray
        }
    }

    # -- Show changes ------------------------------------------------
    Write-Host ""
    Write-Host "=== git status (short) ===" -ForegroundColor Cyan
    $status = git status --short
    if (-not $status) {
        Write-Host "  (no changes - nothing to commit)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Files on disk already match HEAD. If you expected" -ForegroundColor DarkGray
        Write-Host "changes, either:" -ForegroundColor DarkGray
        Write-Host "  - The build has not been updated in Cowork yet, OR" -ForegroundColor DarkGray
        Write-Host "  - A previous push already committed the diff." -ForegroundColor DarkGray
        Remove-Item $tmpCommitFile -ErrorAction SilentlyContinue
        Stop-Here 0
    }
    $status | ForEach-Object { Write-Host "  $_" }

    # -- Confirm -----------------------------------------------------
    Write-Host ""
    $confirm = Read-Host "Commit and push to origin? (y/N)"
    if ($confirm -notmatch '^(y|Y|yes|YES)$') {
        Write-Host "Aborted. Files copied into repo but NOT committed." -ForegroundColor Yellow
        Remove-Item $tmpCommitFile -ErrorAction SilentlyContinue
        Stop-Here 0
    }

    # -- Commit + push -----------------------------------------------
    Write-Host ""
    Write-Host "Committing..." -ForegroundColor Cyan
    # Stage everything currently unstaged in the working tree. The git
    # status preview above lets the user abort if anything unexpected is
    # present. Using -A keeps the script working for script/docs-only
    # commits that don't touch any file in Cowork outputs.
    git add -A
    git commit -F $tmpCommitFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Commit failed (exit $LASTEXITCODE). See git output above." -ForegroundColor Red
        Remove-Item $tmpCommitFile -ErrorAction SilentlyContinue
        Stop-Here $LASTEXITCODE
    }

    $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
    Write-Host ""
    Write-Host "Pushing to origin/$branch ..." -ForegroundColor Cyan
    git push origin $branch

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Pushed to origin/$branch. GitHub Pages will redeploy shortly." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Push failed (exit $LASTEXITCODE). Commit exists locally but was not pushed." -ForegroundColor Yellow
        Write-Host "Run git push manually once you resolve the issue above." -ForegroundColor DarkGray
        Remove-Item $tmpCommitFile -ErrorAction SilentlyContinue
        Stop-Here $LASTEXITCODE
    }

    Remove-Item $tmpCommitFile -ErrorAction SilentlyContinue
    Stop-Here 0
}
catch {
    Write-Host ""
    Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Stop-Here 1
}
