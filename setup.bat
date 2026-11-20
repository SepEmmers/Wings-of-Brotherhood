@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "NO_PAUSE=0"
for %%A in (%*) do (
    if /I "%%~A"=="-NoPause" set "NO_PAUSE=1"
    if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
)

if not exist "%~dp0tools\setup.ps1" (
    echo.
    echo [ERROR] Could not find "tools\setup.ps1".
    echo If you downloaded a ZIP from GitHub, please EXTRACT the entire folder first
    echo before double-clicking setup.bat.
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
)

set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" (
    for /f "delims=" %%P in ('where pwsh 2^>nul') do (
        set "PS_EXE=%%P"
        goto :found_ps
    )
    for /f "delims=" %%P in ('where powershell 2^>nul') do (
        set "PS_EXE=%%P"
        goto :found_ps
    )
    echo.
    echo [ERROR] PowerShell was not found on this Windows system.
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
)

:found_ps
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup.ps1" %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo [ERROR] Setup exited with code %EXITCODE%.
    if exist "%~dp0tools\setup.log" (
        echo         Diagnostic log saved to: tools\setup.log
    )
    echo.
    if "%NO_PAUSE%"=="0" pause
)

exit /b %EXITCODE%
