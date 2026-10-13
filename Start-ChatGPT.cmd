@echo off
setlocal
set "launcher_powershell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "launcher_powershell=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%launcher_powershell%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-ChatGPT.ps1" %*
set "launcher_exit_code=%ERRORLEVEL%"
if not "%launcher_exit_code%"=="0" pause
exit /b %launcher_exit_code%
