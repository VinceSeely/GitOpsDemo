@echo off
REM Bootstrap wrapper script for Windows
REM Automatically runs the PowerShell version

echo ========================================
echo Terraform State Storage Bootstrap
echo ========================================
echo.
echo Running PowerShell bootstrap script...
echo.

REM Check if PowerShell is available
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using PowerShell Core (pwsh)
    pwsh -ExecutionPolicy Bypass -File "%~dp0bootstrap-state-storage.ps1" %*
) else (
    where powershell >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Using Windows PowerShell
        powershell -ExecutionPolicy Bypass -File "%~dp0bootstrap-state-storage.ps1" %*
    ) else (
        echo ERROR: PowerShell is not available
        echo Please install PowerShell from https://github.com/PowerShell/PowerShell
        exit /b 1
    )
)

exit /b %ERRORLEVEL%
