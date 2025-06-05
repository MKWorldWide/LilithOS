@echo off
setlocal enabledelayedexpansion

echo [*] Starting LilithOS installation in DFU mode...

:: Check for IPSW
if not exist "build\LilithOS_9.3.6.ipsw" (
    echo [!] LilithOS IPSW not found. Please run build_lilithos.bat first.
    exit /b 1
)

:: Check for iTunes
if not exist "C:\Program Files\iTunes\iTunes.exe" (
    echo [!] iTunes not found. Please install iTunes first.
    exit /b 1
)

echo [*] Device detected in DFU mode
echo [*] Starting restore process...

:: Open iTunes and restore
start "" "C:\Program Files\iTunes\iTunes.exe"

echo [*] Please follow these steps in iTunes:
echo [1] When iTunes opens, it should detect your device in recovery mode
echo [2] Click "Restore" when prompted
echo [3] If not prompted, hold Shift and click Restore
echo [4] Select the file: build\LilithOS_9.3.6.ipsw
echo [5] Click "Restore" and wait for the process to complete
echo.
echo [*] The device will automatically exit DFU mode and boot into LilithOS
echo [*] This process may take several minutes. Please do not disconnect your device. 