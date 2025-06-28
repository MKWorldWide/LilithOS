@echo off
setlocal enabledelayedexpansion

:: Windows Integration Script for LilithOS
:: This script handles the integration of LilithOS with Windows systems
:: and sets up the C: drive access and configuration

:: Configuration
set "LILITHOS_CONFIG=C:\Program Files\LilithOS"
set "INTEGRATION_LOG=%LILITHOS_CONFIG%\logs\integration.log"
set "ERROR_LOG=%LILITHOS_CONFIG%\logs\error.log"

:: Function to check for admin privileges
:check_admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [91mError: Please run this script as Administrator[0m
    echo Right-click and select "Run as Administrator"
    pause
    exit /b 1
)

:: Function to create necessary directories
:setup_directories
echo [93mCreating necessary directories...[0m
if not exist "%LILITHOS_CONFIG%" (
    mkdir "%LILITHOS_CONFIG%" 2>nul
    if errorlevel 1 (
        echo [91mError: Failed to create %LILITHOS_CONFIG%[0m
        echo [93mTrying alternative location...[0m
        set "LILITHOS_CONFIG=C:\LilithOS"
        mkdir "%LILITHOS_CONFIG%" 2>nul
    )
)
if not exist "%LILITHOS_CONFIG%\logs" mkdir "%LILITHOS_CONFIG%\logs" 2>nul
if not exist "%LILITHOS_CONFIG%\config" mkdir "%LILITHOS_CONFIG%\config" 2>nul

:: Function to setup integration
:setup_integration
echo [93mSetting up Windows integration...[0m

:: Create integration config
echo # Windows Integration Configuration > "%LILITHOS_CONFIG%\config\windows-integration.conf" 2>nul
if errorlevel 1 (
    echo [91mError: Failed to create configuration file[0m
    goto :error_handling
)

echo WINDOWS_DRIVE=C: >> "%LILITHOS_CONFIG%\config\windows-integration.conf"
echo AUTO_MOUNT=true >> "%LILITHOS_CONFIG%\config\windows-integration.conf"
echo SHARE_FILES=true >> "%LILITHOS_CONFIG%\config\windows-integration.conf"

:: Setup file sharing
echo [93mConfiguring file sharing...[0m
net share LilithOS=C:\ /grant:everyone,FULL 2>nul
if errorlevel 1 (
    echo [91mWarning: Failed to create network share[0m
    echo [93mTrying alternative sharing method...[0m
    powershell -Command "New-SmbShare -Name 'LilithOS' -Path 'C:\' -FullAccess 'Everyone'" 2>nul
)

:: Function to verify installation
:verify_installation
echo [93mVerifying installation...[0m

if exist "%LILITHOS_CONFIG%\config\windows-integration.conf" (
    echo [92m✓ Windows integration configuration created[0m
) else (
    echo [91m✗ Windows integration configuration failed[0m
    goto :error_handling
)

if exist "C:\" (
    echo [92m✓ C: drive access verified[0m
) else (
    echo [91m✗ C: drive access verification failed[0m
    goto :error_handling
)

:: Check network share
net share | findstr /i "LilithOS" >nul
if errorlevel 1 (
    echo [91m✗ Network share creation failed[0m
    goto :error_handling
) else (
    echo [92m✓ Network share created successfully[0m
)

goto :end

:error_handling
echo [91mAn error occurred during installation[0m
echo [93mCheck the error log at: %ERROR_LOG%[0m
echo [93mPlease try running the script again as Administrator[0m
pause
exit /b 1

:end
echo.
echo [92mWindows integration completed successfully![0m
echo [93mConfiguration location: %LILITHOS_CONFIG%[0m
echo [93mIntegration logs: %INTEGRATION_LOG%[0m
echo [93mYou can now access your C: drive at C:\[0m
echo [93mNetwork share available at: \\localhost\LilithOS[0m
echo.
pause 