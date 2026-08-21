@echo off
REM ---------------------------------------------------------------------------
REM  beam-watcher-uninstall.cmd
REM
REM  Removes the Beam auto-deploy watcher: stops any running instance and
REM  deletes the Startup-folder shortcut so it will not launch on login.
REM ---------------------------------------------------------------------------

setlocal
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP%\Beam Watcher.lnk"

echo === Beam watcher uninstall ===
echo.
echo Stopping any running watcher...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.CommandLine -like '*beam-watcher.ps1*' } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; Write-Host ('  killed pid ' + $_.ProcessId) } catch {} }"

if exist "%SHORTCUT%" (
    del "%SHORTCUT%"
    echo Removed Startup shortcut: %SHORTCUT%
) else (
    echo No Startup shortcut found at: %SHORTCUT%
)

echo.
echo Beam watcher uninstalled.
echo   State + log kept at: %LOCALAPPDATA%\BeamWatcher\  (delete manually if you want a clean slate)
echo.
pause
endlocal
