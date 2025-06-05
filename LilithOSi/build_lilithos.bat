@echo off
setlocal enabledelayedexpansion

echo [*] Starting LilithOS build process...

:: Create necessary directories
echo [*] Creating project structure...
if not exist build mkdir build
if not exist resources mkdir resources
if not exist tools mkdir tools
if not exist src mkdir src
if not exist src\kernel mkdir src\kernel
if not exist src\system mkdir src\system
if not exist src\patches mkdir src\patches

:: Check for Python
echo [*] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python not found. Please install Python 3.x
    exit /b 1
)

:: Install Python dependencies
echo [*] Installing Python dependencies...
pip install Pillow imageio

:: Check for base IPSW
echo [*] Checking for base IPSW...
if not exist "iPhone4,1_9.3.6_13G37_Restore.ipsw" (
    echo [!] Base IPSW not found. Please place iPhone4,1_9.3.6_13G37_Restore.ipsw in the current directory.
    exit /b 1
)

:: Create work directory
echo [*] Setting up work directory...
if exist work rmdir /s /q work
mkdir work

:: Extract IPSW
echo [*] Extracting IPSW...
powershell -command "Expand-Archive -Path 'iPhone4,1_9.3.6_13G37_Restore.ipsw' -DestinationPath 'work' -Force"

:: Create boot animation
echo [*] Creating boot animation...
python src\system\boot_animation.py resources

:: Copy modified files
echo [*] Copying modified files...
xcopy /y "build\boot_animation.gif" "work\System\Library\CoreServices\"
xcopy /y "build\BootAnimation.plist" "work\System\Library\CoreServices\"
xcopy /y "src\system\modifications.plist" "work\System\Library\LaunchDaemons\"

:: Create final IPSW
echo [*] Creating final IPSW...
powershell -command "Compress-Archive -Path 'work\*' -DestinationPath 'build\LilithOS_9.3.6.ipsw' -Force"

:: Cleanup
echo [*] Cleaning up...
rmdir /s /q work

echo [*] Build completed successfully!
echo [*] Output IPSW: build\LilithOS_9.3.6.ipsw
echo [*] To install LilithOS, run: install_lilithos.bat 