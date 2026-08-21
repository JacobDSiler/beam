<#
.SYNOPSIS
    System-tray watcher that auto-pushes Beam when its version stamp bumps.

.DESCRIPTION
    Sits in the notification area as a small "B" icon. Every 5 seconds it
    scans the Cowork sessions folder for the most-recently-modified
    ".beam-version.json" and compares its "version" number to the last
    version this watcher saw. When the number goes up, it invokes
    scripts\beam-push.ps1 -Auto (non-interactive), which copies the
    outputs drop into the repo and commits + pushes to origin.

    The version JSON is Claude's explicit "please deploy" signal. Bumping
    it AFTER writing index.html + .beam-pending-commit.txt guarantees the
    watcher never fires on a half-staged drop.

    Contract for .beam-version.json (lives in the Cowork outputs folder
    next to .beam-pending-commit.txt):
        { "version": <int>, "bumpedAt": "<ISO date>", "note": "<free text>" }

    First run initializes lastSeenVersion from whatever is currently on
    disk so installation does not cause a spurious immediate push.
    Subsequent bumps trigger a push.

    Tray menu:
        Idle / Pushing / Push failed  (status label, disabled)
        Push now                       (manual trigger)
        Show log                       (opens watcher.log in Notepad)
        Open repo folder               (opens C:\dev\beam)
        Open latest outputs folder     (opens the source-of-truth drop)
        Quit                           (stops the watcher this session)

    State is kept in %LOCALAPPDATA%\BeamWatcher\state.json
    Log is at    %LOCALAPPDATA%\BeamWatcher\watcher.log

    A named mutex prevents a second instance from starting.

.NOTES
    Launched hidden via beam-watcher.vbs so no console window ever appears.
    Auto-starts on login when installed via beam-watcher-install.cmd.
#>

# ---- Single-instance guard -----------------------------------------
$mutexName = 'Global\BeamWatcher_Mutex_v1'
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Continue'

# ---- Paths / config ------------------------------------------------
$RepoRoot     = Split-Path $PSScriptRoot -Parent
$PushScript   = Join-Path $PSScriptRoot 'beam-push.ps1'
$SessionsBase = Join-Path $env:APPDATA 'Claude\local-agent-mode-sessions'
$StateDir     = Join-Path $env:LOCALAPPDATA 'BeamWatcher'
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
$StateFile    = Join-Path $StateDir 'state.json'
$LogFile      = Join-Path $StateDir 'watcher.log'
$PollMs       = 5000

function Write-Log($msg) {
    $line = "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] $msg"
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch {}
}

function Load-State {
    if (Test-Path $StateFile) {
        try { return Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    }
    return [pscustomobject]@{ lastSeenVersion = 0; lastPushed = $null; lastPushOk = $null }
}

function Save-State($state) {
    try { $state | ConvertTo-Json -Depth 4 | Set-Content -Path $StateFile -Encoding UTF8 } catch {}
}

function Find-LatestVersionJson {
    if (-not (Test-Path $SessionsBase)) { return $null }
    $latest = Get-ChildItem -Path $SessionsBase -Recurse -Filter '.beam-version.json' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    try {
        $obj = Get-Content $latest.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        return [pscustomobject]@{
            Path     = $latest.FullName
            Folder   = Split-Path $latest.FullName -Parent
            Version  = [int]$obj.version
            BumpedAt = $obj.bumpedAt
            Note     = $obj.note
        }
    } catch { return $null }
}

# ---- Tray icon (rendered in-code so nothing to ship) --------------
function New-BeamIcon($color, $letter = 'B') {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAlias'
    $bg = New-Object System.Drawing.SolidBrush $color
    $g.FillRectangle($bg, 0, 0, 32, 32)
    $font = New-Object System.Drawing.Font 'Segoe UI', 18, [System.Drawing.FontStyle]::Bold
    $g.DrawString($letter, $font, [System.Drawing.Brushes]::Black, 4, 1)
    $g.Dispose()
    $bg.Dispose(); $font.Dispose()
    $h = $bmp.GetHicon()
    return [System.Drawing.Icon]::FromHandle($h)
}
$colorIdle    = [System.Drawing.Color]::FromArgb(0, 228, 255)   # beam cyan
$colorPushing = [System.Drawing.Color]::FromArgb(255, 200, 0)   # amber
$colorError   = [System.Drawing.Color]::FromArgb(230, 90, 90)   # red
$iconIdle     = New-BeamIcon $colorIdle
$iconPushing  = New-BeamIcon $colorPushing
$iconError    = New-BeamIcon $colorError

$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon = $iconIdle
$ni.Text = 'Beam watcher - idle'
$ni.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$mStatus       = $menu.Items.Add('Idle');       $mStatus.Enabled = $false
$menu.Items.Add('-') | Out-Null
$mPushNow      = $menu.Items.Add('Push now')
$mOpenLog      = $menu.Items.Add('Show log')
$mOpenRepo     = $menu.Items.Add('Open repo folder')
$mOpenOutputs  = $menu.Items.Add('Open latest outputs folder')
$menu.Items.Add('-') | Out-Null
$mQuit         = $menu.Items.Add('Quit')
$ni.ContextMenuStrip = $menu

function Set-Status($text, $iconKind = 'idle') {
    $mStatus.Text = $text
    # Text is truncated by Windows to ~63 chars for the tooltip
    $ni.Text = ('Beam watcher - ' + $text).Substring(0, [Math]::Min(('Beam watcher - ' + $text).Length, 63))
    switch ($iconKind) {
        'idle'    { $ni.Icon = $iconIdle }
        'pushing' { $ni.Icon = $iconPushing }
        'error'   { $ni.Icon = $iconError }
    }
}

# ---- Push runner ---------------------------------------------------
$script:pushBusy = $false
function Run-Push($reason) {
    if ($script:pushBusy) { Write-Log "Push already in progress - skipping: $reason"; return $false }
    if (-not (Test-Path $PushScript)) {
        Write-Log "beam-push.ps1 not found at $PushScript"
        Set-Status 'Push script missing' 'error'
        $ni.ShowBalloonTip(6000, 'Beam watcher', "Push script not found:`n$PushScript", [System.Windows.Forms.ToolTipIcon]::Error)
        return $false
    }
    $script:pushBusy = $true
    try {
        Write-Log "Push triggered: $reason"
        Set-Status ("Pushing... " + $reason) 'pushing'
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PushScript -Auto 2>&1 | Out-String
        $code = $LASTEXITCODE
        Write-Log ("Push exit=$code")
        Write-Log ("--- push output ---`n" + $out + "--- end push output ---")
        if ($code -eq 0 -and $out -match 'Pushed to origin/') {
            Set-Status 'Idle (last push OK)' 'idle'
            $ni.ShowBalloonTip(3500, 'Beam deployed', "$reason`nGitHub Pages will redeploy shortly.", [System.Windows.Forms.ToolTipIcon]::Info)
            return $true
        } elseif ($code -eq 0) {
            Set-Status 'Idle (nothing to push)' 'idle'
            $ni.ShowBalloonTip(2500, 'Beam watcher', 'No changes to commit.', [System.Windows.Forms.ToolTipIcon]::Info)
            return $true
        } else {
            Set-Status ("Push failed (exit $code) - see log") 'error'
            $ni.ShowBalloonTip(6000, 'Beam push failed', "Exit $code. Right-click the tray icon and choose Show log.", [System.Windows.Forms.ToolTipIcon]::Error)
            return $false
        }
    } finally {
        $script:pushBusy = $false
    }
}

# ---- Menu handlers ------------------------------------------------
$mPushNow.Add_Click({ [void](Run-Push 'Manual push from tray') })
$mOpenLog.Add_Click({ if (Test-Path $LogFile) { Start-Process notepad.exe $LogFile } else { Start-Process notepad.exe } })
$mOpenRepo.Add_Click({ Start-Process explorer.exe $RepoRoot })
$mOpenOutputs.Add_Click({
    $v = Find-LatestVersionJson
    if ($v) { Start-Process explorer.exe $v.Folder }
    else { $ni.ShowBalloonTip(3000, 'Beam watcher', 'No .beam-version.json found yet.', [System.Windows.Forms.ToolTipIcon]::Info) }
})
$mQuit.Add_Click({
    Write-Log 'Watcher quitting via tray menu.'
    $script:done = $true
})

# ---- Initial state -------------------------------------------------
$state = Load-State
if (-not $state.lastSeenVersion -or $state.lastSeenVersion -eq 0) {
    $cur = Find-LatestVersionJson
    if ($cur) {
        $state.lastSeenVersion = $cur.Version
        Save-State $state
        Write-Log "First run: initialized lastSeenVersion = $($cur.Version) (from $($cur.Path))"
    } else {
        Write-Log 'First run: no .beam-version.json found yet.'
    }
}
Set-Status 'Idle' 'idle'
Write-Log "Watcher started. RepoRoot=$RepoRoot  Push=$PushScript"

# ---- Poll loop ----------------------------------------------------
# DoEvents keeps the tray responsive while we tick the poll interval.
$script:done = $false
$lastPoll = [DateTime]::MinValue
while (-not $script:done) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 200
    if (([DateTime]::Now - $lastPoll).TotalMilliseconds -lt $PollMs) { continue }
    $lastPoll = [DateTime]::Now

    try {
        $cur = Find-LatestVersionJson
        if (-not $cur) { continue }
        if ($cur.Version -gt [int]$state.lastSeenVersion) {
            Write-Log "Version bump: $($state.lastSeenVersion) -> $($cur.Version). Note: $($cur.Note)"
            $commitStamp = Join-Path $cur.Folder '.beam-pending-commit.txt'
            if (-not (Test-Path $commitStamp)) {
                Write-Log 'No .beam-pending-commit.txt alongside version bump - marking seen and skipping.'
                $state.lastSeenVersion = $cur.Version
                Save-State $state
                continue
            }
            $reason = "v$($cur.Version)"
            if ($cur.Note) { $reason = $reason + ' - ' + $cur.Note }
            $ok = Run-Push $reason
            # Mark seen regardless of success so we don't hammer on a broken bump.
            # Manual "Push now" from the tray menu lets you retry after fixing.
            $state.lastSeenVersion = $cur.Version
            $state.lastPushed      = [DateTime]::Now.ToString('o')
            $state.lastPushOk      = [bool]$ok
            Save-State $state
        }
    } catch {
        Write-Log ("Poll error: " + $_.Exception.Message)
    }
}

$ni.Visible = $false
$ni.Dispose()
try { $mutex.ReleaseMutex() } catch {}
