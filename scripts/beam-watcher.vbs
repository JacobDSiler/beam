' beam-watcher.vbs - hidden launcher for beam-watcher.ps1
'
' Launches PowerShell with -WindowStyle Hidden and a hidden shell window
' (SW_HIDE = 0). PowerShell still spawns a conhost process for the tray
' script's runtime, but no console ever becomes visible to the user.
'
' Usage: double-click this file, or point a Startup shortcut at it.
Option Explicit
Dim shell, fso, scriptDir, psScript, cmd
Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript  = scriptDir & "\beam-watcher.ps1"

If Not fso.FileExists(psScript) Then
    MsgBox "beam-watcher.ps1 not found at:" & vbCrLf & psScript, vbCritical, "Beam watcher"
    WScript.Quit 1
End If

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & psScript & """"
' Args: cmd, windowStyle (0=hidden), waitOnReturn (False=fire and forget)
shell.Run cmd, 0, False
