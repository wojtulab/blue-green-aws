@echo off
setlocal
cd /d "%~dp0"

echo Starting AWS RDS Blue/Green Deployment Manager...

REM 1. Unblock PowerShell scripts if downloaded from internet/Teams
powershell -NoProfile -Command "Get-ChildItem -Path '%~dp0*.ps1' -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"

REM 2. Prefer PowerShell 7 (pwsh) if installed, fallback to Windows PowerShell 5.1
where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0rds_bg_manager.ps1" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rds_bg_manager.ps1" %*
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo Script ended with exit code %ERRORLEVEL%.
    pause
)
