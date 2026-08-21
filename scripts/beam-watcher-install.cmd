@echo off
REM ---------------------------------------------------------------------------
REM  beam-watcher-install.cmd
REM
REM  Installs the Beam auto-deploy watcher: kills any running instance,
REM  creates a Startup-folder shortcut so the watcher runs on login, and
REM  launches it immediately so you don't have to log out and back in.
REM
REM  Uninstall via beam-watcher-uninstall.cmd in this same folder.
REM ---------------------------------------------------------------------------

setlocal
set "HERE=%~dp0"
set "VBS=%HERE%beam-watcher.vbs"
set "PS1=%HERE%beam-watcher.ps1"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP%\Beam Watcher.lnk"

if not exist "%VBS%" (
    echo ERROR: beam-watcher.vbs not found next to this script.
    echo Expected at: %VBS%
    echo.
    pause
    exit /b 1
)
if not exist "%PS1%" (
    echo ERROR: beam-watcher.ps1 not found next to this script.
    echo Expected at: %PS1%
    echo.
    pause
    exit /b 1
)

echo === Beam watcher install ===
echo Repo scripts folder: %HERE%
echo.

REM Kill any running watcher first so the relaunch picks up the latest script
echo Stopping any running watcher...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.CommandLine -like '*beam-watcher.ps1*' } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; Write-Host ('  killed pid ' + $_.ProcessId) } catch {} }"

REM Create/replace Startup shortcut. Target: wscript.exe launching the .vbs.
echo Creating Startup shortcut: %SHORTCUT%
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('%SHORTCUT%'); $s.TargetPath = 'wscript.exe'; $s.Arguments = '\"%VBS%\"'; $s.WorkingDirectory = '%HERE%'; $s.WindowStyle = 7; $s.Description = 'Beam auto-deploy watcher'; $s.Save()"
if errorlevel 1 (
    echo Failed to create shortcut.
    pause
    exit /b 1
)

echo Launching watcher now...
start "" wscript.exe "%VBS%"

echo.
echo Beam watcher installed.
echo   - Runs on login from: %SHORTCUT%
echo   - Look for the cyan "B" icon in your notification area.
echo   - Right-click the icon for the menu (Push now / Show log / Quit).
echo.
pause
endlocal
