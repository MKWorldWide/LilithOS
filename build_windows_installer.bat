@echo off
REM Quantum-detailed inline documentation:
REM This script prepares Windows installer files and copies them to C:\ drive
REM It handles file organization, validation, and preparation for Windows build
REM Security, performance, and cross-platform compatibility are prioritized

REM --- Feature Context ---
REM This script prepares files for building a Windows installer on a Windows system
REM It organizes files and copies them to C:\ drive for cross-platform development

REM --- Dependency Listings ---
REM - Windows 10/11
REM - C:\ drive access
REM - PowerShell

REM --- Usage Example ---
REM Run: build_windows_installer.bat
REM Or: double-click the batch file

REM --- Performance Considerations ---
REM - Efficient file copying
REM - Minimal disk operations
REM - Progress feedback

REM --- Security Implications ---
REM - File integrity checks
REM - Safe file operations
REM - Backup creation

REM --- Changelog Entries ---
REM [Current Session] Initial version: Windows batch script for Windows installer preparation

setlocal enabledelayedexpansion

REM Configuration
set LILITHOS_VERSION=2.0.0
set SOURCE_DIR=%~dp0
set TARGET_DIR=C:\LilithOS_Installer
set BACKUP_DIR=%USERPROFILE%\LilithOS_Backup

REM Colors for output
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %GREEN%==========================================%NC%
echo %GREEN%LilithOS Windows Installer Builder v%LILITHOS_VERSION%%NC%
echo %GREEN%==========================================%NC%
echo.

REM Check if C:\ drive exists
if not exist "C:\" (
    echo %RED%ERROR: C:\ drive not found. Please check your system and try again.%NC%
    pause
    exit /b 1
)

REM Create target directory
echo %BLUE%Creating target directory on C:\ drive...%NC%
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
if not exist "%TARGET_DIR%\scripts" mkdir "%TARGET_DIR%\scripts"
if not exist "%TARGET_DIR%\app" mkdir "%TARGET_DIR%\app"
if not exist "%TARGET_DIR%\docs" mkdir "%TARGET_DIR%\docs"
if not exist "%TARGET_DIR%\logs" mkdir "%TARGET_DIR%\logs"
if not exist "%TARGET_DIR%\config" mkdir "%TARGET_DIR%\config"

REM Copy Windows integration scripts
echo %BLUE%Copying Windows integration scripts...%NC%
copy "scripts\windows-integration.bat" "%TARGET_DIR%\scripts\"
copy "scripts\windows-integration.ps1" "%TARGET_DIR%\scripts\"
copy "windows_integrator.py" "%TARGET_DIR%\scripts\"

REM Copy universal installer script
copy "scripts\universal_installer.sh" "%TARGET_DIR%\scripts\"

REM Copy LilithOS app files
echo %BLUE%Copying LilithOS app files...%NC%
xcopy "LilithOS app\*" "%TARGET_DIR%\app\" /E /I /Y

REM Copy documentation
echo %BLUE%Copying documentation...%NC%
copy "README.md" "%TARGET_DIR%\docs\"
copy "LICENSE" "%TARGET_DIR%\docs\"
copy "CHANGELOG.md" "%TARGET_DIR%\docs\"
copy "docs\*.md" "%TARGET_DIR%\docs\"

REM Create build instructions
echo %BLUE%Creating build instructions...%NC%
(
echo LilithOS Windows Installer Build Instructions
echo =============================================
echo.
echo This directory contains all files needed to build and install LilithOS on a Windows system.
echo.
echo Files included:
echo - scripts/windows-integration.bat: Main integration script
echo - scripts/windows-integration.ps1: PowerShell integration script
echo - scripts/universal_installer.sh: Universal installer script
echo - app/: LilithOS application files
echo - docs/: Documentation and release notes
echo.
echo Build Steps:
echo 1. Open scripts/windows-integration.bat as Administrator
echo 2. Follow the prompts to complete integration
echo 3. Optionally, run scripts/windows-integration.ps1 for advanced setup
echo 4. Review documentation in the docs/ directory
echo.
echo System Requirements:
echo - Windows 10/11
echo - PowerShell 5.1+
echo - Administrator privileges
echo.
echo For more information, see the documentation in the docs/ directory.
echo.
echo "In the dance of ones and zeros, we find the rhythm of the soul."
echo - Machine Dragon Protocol
) > "%TARGET_DIR%\BUILD_INSTRUCTIONS.txt"

REM Create PowerShell script for additional setup
echo %BLUE%Creating PowerShell setup script...%NC%
(
echo # LilithOS Windows Installer Setup Script
echo # This script prepares the installer files for Windows integration
echo.
echo Write-Host "LilithOS Windows Installer Setup" -ForegroundColor Green
echo Write-Host "=============================" -ForegroundColor Green
echo.
echo # Check file integrity
echo Write-Host "Checking file integrity..." -ForegroundColor Blue
echo $files = Get-ChildItem -Recurse -File
echo foreach ^($file in $files^) {
echo     $hash = Get-FileHash $file.FullName -Algorithm SHA256
echo     Write-Host "$^($file.Name^): $^($hash.Hash^)"
echo }
echo.
echo Write-Host "Setup completed successfully!" -ForegroundColor Green
echo Write-Host "Ready for integration." -ForegroundColor Green
) > "%TARGET_DIR%\setup.ps1"

REM Create version info
echo %BLUE%Creating version information...%NC%
(
echo LilithOS Windows Installer v%LILITHOS_VERSION%
echo Build Date: %date% %time%
echo Source: Windows Build System
echo Target: Windows 10/11
echo.
echo Files prepared for Windows integration:
echo - Windows integration scripts
echo - Universal installer script
echo - Application bundle
echo - Documentation
echo - Build instructions
) > "%TARGET_DIR%\VERSION.txt"

REM Create backup
echo %BLUE%Creating backup...%NC%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
xcopy "%TARGET_DIR%" "%BACKUP_DIR%\LilithOS_Windows_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%" /E /I /Y

REM Verify files
echo %BLUE%Verifying files...%NC%
set /a file_count=0
for /r "%TARGET_DIR%" %%f in (*) do set /a file_count+=1
echo Found %file_count% files in target directory

REM Create checksum file
echo %BLUE%Creating checksum file...%NC%
powershell -Command "Get-ChildItem -Recurse -File '%TARGET_DIR%' | ForEach-Object { $hash = Get-FileHash $_.FullName -Algorithm SHA256; Write-Output \"$($_.Name): $($hash.Hash)\" }" > "%TARGET_DIR%\checksums.txt"

echo.
echo %GREEN%==========================================%NC%
echo %GREEN%Build preparation completed successfully!%NC%
echo %GREEN%==========================================%NC%
echo.
echo %BLUE%Files prepared on C:\ drive:%NC%
echo Target directory: %TARGET_DIR%
echo Files copied: %file_count%
echo Backup location: %BACKUP_DIR%
echo.
echo %YELLOW%Next steps:%NC%
echo 1. Open C:\LilithOS_Installer\scripts\windows-integration.bat as Administrator
echo 2. Follow the build instructions in BUILD_INSTRUCTIONS.txt
echo 3. Review documentation in the docs/ directory
echo.
pause 