@echo off
REM Quantum-detailed inline documentation:
REM This script prepares macOS installer files and copies them to O:\ drive
REM It handles file organization, validation, and preparation for Mac build
REM Security, performance, and cross-platform compatibility are prioritized

REM --- Feature Context ---
REM This script prepares files for building macOS installer on a Mac system
REM It organizes files and copies them to O:\ drive for cross-platform development

REM --- Dependency Listings ---
REM - Windows 10/11
REM - O:\ drive mounted
REM - Git for Windows
REM - PowerShell

REM --- Usage Example ---
REM Run: build_macos_installer.bat
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
REM [Current Session] Initial version: Windows batch script for macOS installer preparation

setlocal enabledelayedexpansion

REM Configuration
set LILITHOS_VERSION=1.0.0
set SOURCE_DIR=%~dp0
set TARGET_DIR=O:\LilithOS_MacOS_Installer
set BACKUP_DIR=%USERPROFILE%\LilithOS_Backup

REM Colors for output
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %GREEN%==========================================%NC%
echo %GREEN%LilithOS macOS Installer Builder v%LILITHOS_VERSION%%NC%
echo %GREEN%==========================================%NC%
echo.

REM Check if O:\ drive exists
if not exist "O:\" (
    echo %RED%ERROR: O:\ drive not found. Please mount the drive and try again.%NC%
    pause
    exit /b 1
)

REM Create target directory
echo %BLUE%Creating target directory on O:\ drive...%NC%
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
if not exist "%TARGET_DIR%\scripts" mkdir "%TARGET_DIR%\scripts"
if not exist "%TARGET_DIR%\app" mkdir "%TARGET_DIR%\app"
if not exist "%TARGET_DIR%\docs" mkdir "%TARGET_DIR%\docs"

REM Copy macOS installer script
echo %BLUE%Copying macOS installer script...%NC%
copy "macos_m3_installer.sh" "%TARGET_DIR%\scripts\"
if errorlevel 1 (
    echo %RED%ERROR: Failed to copy macos_m3_installer.sh%NC%
    pause
    exit /b 1
)

REM Copy DMG builder script
echo %BLUE%Copying DMG builder script...%NC%
copy "build_macos_dmg.sh" "%TARGET_DIR%\scripts\"
if errorlevel 1 (
    echo %RED%ERROR: Failed to copy build_macos_dmg.sh%NC%
    pause
    exit /b 1
)

REM Copy LilithOS app files
echo %BLUE%Copying LilithOS app files...%NC%
xcopy "LilithOS app\*" "%TARGET_DIR%\app\" /E /I /Y
if errorlevel 1 (
    echo %RED%ERROR: Failed to copy LilithOS app files%NC%
    pause
    exit /b 1
)

REM Copy documentation
echo %BLUE%Copying documentation...%NC%
copy "README.md" "%TARGET_DIR%\docs\"
copy "@memories.md" "%TARGET_DIR%\docs\"
copy "@lessons-learned.md" "%TARGET_DIR%\docs\"
copy "docs\*.md" "%TARGET_DIR%\docs\"

REM Create build instructions
echo %BLUE%Creating build instructions...%NC%
(
echo LilithOS macOS M3 Installer Build Instructions
echo ==============================================
echo.
echo This directory contains all files needed to build the LilithOS macOS installer
echo for MacBook Air M3 on a Mac system.
echo.
echo Files included:
echo - scripts/macos_m3_installer.sh: Main installer script
echo - scripts/build_macos_dmg.sh: DMG builder script
echo - app/: LilithOS application files
echo - docs/: Documentation and release notes
echo.
echo Build Steps:
echo 1. Transfer this directory to a Mac system
echo 2. Open Terminal and navigate to this directory
echo 3. Make scripts executable: chmod +x scripts/*.sh
echo 4. Run the DMG builder: ./scripts/build_macos_dmg.sh
echo 5. The DMG will be created in the dist/ directory
echo.
echo System Requirements:
echo - macOS 14.0+ ^(Sonoma^)
echo - Xcode Command Line Tools
echo - Homebrew ^(for create-dmg^)
echo - MacBook Air M3 ^(optimized^)
echo.
echo For more information, see the documentation in the docs/ directory.
echo.
echo "In the dance of ones and zeros, we find the rhythm of the soul."
echo - Machine Dragon Protocol
) > "%TARGET_DIR%\BUILD_INSTRUCTIONS.txt"

REM Create PowerShell script for additional setup
echo %BLUE%Creating PowerShell setup script...%NC%
(
echo # LilithOS macOS Installer Setup Script
echo # This script prepares the installer files for Mac build
echo.
echo Write-Host "LilithOS macOS Installer Setup" -ForegroundColor Green
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
echo Write-Host "Ready for transfer to Mac system." -ForegroundColor Green
) > "%TARGET_DIR%\setup.ps1"

REM Create version info
echo %BLUE%Creating version information...%NC%
(
echo LilithOS macOS Installer v%LILITHOS_VERSION%
echo Build Date: %date% %time%
echo Source: Windows Build System
echo Target: MacBook Air M3
echo.
echo Files prepared for Mac build:
echo - macOS installer script
echo - DMG builder script
echo - Application bundle
echo - Documentation
echo - Build instructions
) > "%TARGET_DIR%\VERSION.txt"

REM Create backup
echo %BLUE%Creating backup...%NC%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
xcopy "%TARGET_DIR%" "%BACKUP_DIR%\LilithOS_MacOS_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%" /E /I /Y

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
echo %BLUE%Files prepared on O:\ drive:%NC%
echo Target directory: %TARGET_DIR%
echo Files copied: %file_count%
echo Backup location: %BACKUP_DIR%
echo.
echo %YELLOW%Next steps:%NC%
echo 1. Transfer the files from O:\ to a Mac system
echo 2. Follow the build instructions in BUILD_INSTRUCTIONS.txt
echo 3. Run the DMG builder script on the Mac
echo.
echo %GREEN%Enjoy your sacred digital garden! 🌑%NC%
echo.
pause 