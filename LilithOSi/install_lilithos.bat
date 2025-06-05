@echo off
setlocal enabledelayedexpansion

echo [*] Starting LilithOS installation...

:: Check for IPSW
if not exist "build\LilithOS_9.3.6.ipsw" (
    echo [!] LilithOS IPSW not found. Please run build_lilithos.bat first.
    exit /b 1
)

:: Check for libimobiledevice
echo [*] Checking for libimobiledevice...
where ideviceinfo >nul 2>&1
if errorlevel 1 (
    echo [!] libimobiledevice not found. Please install it from https://github.com/libimobiledevice/win32/releases
    exit /b 1
)

:: Check device connection
echo [*] Checking device connection...
ideviceinfo >nul 2>&1
if errorlevel 1 (
    echo [!] No device connected. Please connect your iPhone 4S and try again.
    exit /b 1
)

:: Get device info
echo [*] Getting device information...
for /f "tokens=*" %%a in ('ideviceinfo -s ProductType') do set DEVICE_TYPE=%%a
for /f "tokens=*" %%a in ('ideviceinfo -s ProductVersion') do set DEVICE_VERSION=%%a

:: Verify device
if not "%DEVICE_TYPE%"=="iPhone4,1" (
    echo [!] Unsupported device: %DEVICE_TYPE%
    echo [!] This IPSW is only for iPhone 4S
    exit /b 1
)

:: Enter DFU mode
echo [*] Please follow these steps to enter DFU mode:
echo [1] Hold Power and Home buttons for 10 seconds
echo [2] Release Power button but keep holding Home for 5 more seconds
echo [3] Release Home button
echo.
echo Press any key when ready...
pause >nul

:: Install IPSW
echo [*] Installing LilithOS...
idevicerestore -d "build\LilithOS_9.3.6.ipsw"

echo [*] Installation completed!
echo [*] Your device will now boot into LilithOS 