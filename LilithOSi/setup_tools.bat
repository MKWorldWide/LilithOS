@echo off
setlocal enabledelayedexpansion

echo [*] Setting up LilithOS tools...

:: Create tools directory if it doesn't exist
if not exist tools mkdir tools

:: Download libimobiledevice using curl
echo [*] Downloading libimobiledevice...
curl -L "https://github.com/libimobiledevice/win32/releases/download/1.2.1/libimobiledevice-1.2.1-win32.zip" -o "tools\libimobiledevice.zip"

if not exist "tools\libimobiledevice.zip" (
    echo [!] Failed to download libimobiledevice. Please download manually from:
    echo https://github.com/libimobiledevice/win32/releases/download/1.2.1/libimobiledevice-1.2.1-win32.zip
    echo and extract the contents to the tools folder.
    exit /b 1
)

:: Extract libimobiledevice
echo [*] Extracting libimobiledevice...
powershell -Command "& {Expand-Archive -Path 'tools\libimobiledevice.zip' -DestinationPath 'tools' -Force}"

:: Add tools to PATH
echo [*] Adding tools to PATH...
setx PATH "%PATH%;%CD%\tools"

echo [*] Setup completed!
echo [*] Please restart your terminal and run install_lilithos.bat 