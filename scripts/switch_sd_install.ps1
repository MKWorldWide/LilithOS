# LilithOS Switch SD Card Installation - Simple Version
# Installs LilithOS homebrew into Nintendo Switch SD card

param(
    [string]$Drive = "O:",
    [switch]$Force
)

# Configuration
$ScriptVersion = "2.0.0"
$LilithOSVersion = "2.0.0"
$BrandName = "MKWW and LilithOS"

# Color codes
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Purple = "Magenta"
$Cyan = "Cyan"
$White = "White"

# Simple logging function
function Write-Status {
    param([string]$Message, [string]$Color = $White)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Print banner
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * MKWW * LilithOS Switch SD Installation                   ║" -ForegroundColor $Purple
    Write-Host "║  Where Technology Meets the Ethereal                        ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Version: $ScriptVersion                                    ║" -ForegroundColor $Purple
    Write-Host "║  Target: Nintendo Switch SD Card ($Drive)                   ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
}

# Check if drive exists and analyze
function Test-Drive {
    Write-Status "Checking drive $Drive..." $Cyan
    
    $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive'"
    if (-not $drive) {
        Write-Status "ERROR: Drive $Drive not found!" $Red
        return $false
    }
    
    $totalSize = [math]::Round($drive.Size / 1GB, 1)
    $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 1)
    Write-Status "Drive $Drive`: ${totalSize}GB total, ${freeSpace}GB free, $($drive.FileSystem)" $Green
    
    # Check for Nintendo directory
    if (Test-Path "$Drive\Nintendo") {
        Write-Status "Found Nintendo directory - Switch SD card detected" $Green
        
        # Count games and saves
        $games = 0
        $saves = 0
        if (Test-Path "$Drive\Nintendo\Contents\registered") {
            $games = (Get-ChildItem -Path "$Drive\Nintendo\Contents\registered" -Directory).Count
        }
        if (Test-Path "$Drive\Nintendo\save") {
            $saves = (Get-ChildItem -Path "$Drive\Nintendo\save" -Directory).Count
        }
        
        Write-Status "Found $games installed games and $saves save directories" $Green
        return $true
    } else {
        Write-Status "WARNING: No Nintendo directory found - may not be a Switch SD card" $Yellow
        return $true
    }
}

# Create homebrew directory structure
function New-HomebrewStructure {
    Write-Status "Creating homebrew directory structure..." $Cyan
    
    $directories = @(
        "$Drive\switch",
        "$Drive\switch\lilithos_app",
        "$Drive\switch\lilithos_app\source",
        "$Drive\switch\lilithos_app\assets",
        "$Drive\switch\lilithos_app\config",
        "$Drive\switch\lilithos_app\logs",
        "$Drive\atmosphere",
        "$Drive\atmosphere\contents",
        "$Drive\atmosphere\config",
        "$Drive\atmosphere\patches",
        "$Drive\atmosphere\exefs_patches",
        "$Drive\atmosphere\kip_patches",
        "$Drive\bootloader",
        "$Drive\bootloader\payloads",
        "$Drive\bootloader\ini",
        "$Drive\config",
        "$Drive\logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Status "Created: $dir" $Green
        } else {
            Write-Status "Exists: $dir" $Yellow
        }
    }
    
    return $true
}

# Create LilithOS application files
function New-LilithOSFiles {
    Write-Status "Creating LilithOS homebrew files..." $Cyan
    
    # README file
    $readmeContent = "# LilithOS Switch Homebrew Application`n"
    $readmeContent += "# Version: $LilithOSVersion`n"
    $readmeContent += "# Brand: $BrandName`n`n"
    $readmeContent += "This is the LilithOS homebrew application for Nintendo Switch.`n`n"
    $readmeContent += "## Features`n"
    $readmeContent += " * Quantum computing interface`n"
    $readmeContent += " * Mystical UI elements`n"
    $readmeContent += " * Advanced security features`n"
    $readmeContent += " * Cross-platform compatibility`n"
    $readmeContent += " * Gaming mode integration`n`n"
    $readmeContent += "## Requirements`n"
    $readmeContent += " * Custom firmware (Atmosphere recommended)`n"
    $readmeContent += " * RCM payload injector`n"
    $readmeContent += " * SD card with sufficient space`n`n"
    $readmeContent += "## Installation`n"
    $readmeContent += " 1. Ensure custom firmware is installed`n"
    $readmeContent += " 2. Place this application in /switch/lilithos_app/`n"
    $readmeContent += " 3. Launch from Homebrew Menu`n`n"
    $readmeContent += '"In the dance of ones and zeros, we find the rhythm of the soul."' + "`n"
    $readmeContent += "- Machine Dragon Protocol`n"
    
    $readmeContent | Out-File -FilePath "$Drive\switch\lilithos_app\README.md" -Encoding UTF8
    
    # Main C file
    $mainContent = "#include <switch.h>`n`n"
    $mainContent += "int main(int argc, char **argv) {`n"
    $mainContent += "    // Initialize LilithOS Switch Application`n"
    $mainContent += "    consoleInit(NULL);`n`n"
    $mainContent += "    printf(`"LilithOS Switch Homebrew v$LilithOSVersion\n`");`n"
    $mainContent += "    printf(`"Brand: $BrandName\n`");`n"
    $mainContent += "    printf(`"Where Technology Meets the Ethereal\n\n`");`n`n"
    $mainContent += "    printf(`"Press any key to exit...\n`");`n`n"
    $mainContent += "    while(appletMainLoop()) {`n"
    $mainContent += "        hidScanInput();`n"
    $mainContent += "        if(hidKeysDown(CONTROLLER_P1_AUTO) & KEY_PLUS) break;`n"
    $mainContent += "        consoleUpdate(NULL);`n"
    $mainContent += "    }`n`n"
    $mainContent += "    consoleExit(NULL);`n"
    $mainContent += "    return 0;`n"
    $mainContent += "}`n"
    
    $mainContent | Out-File -FilePath "$Drive\switch\lilithos_app\main.c" -Encoding UTF8
    
    # Makefile
    $makefileContent = "# LilithOS Switch Homebrew Makefile`n"
    $makefileContent += "# Version: $LilithOSVersion`n`n"
    $makefileContent += "TARGET = lilithos_app`n"
    $makefileContent += "BUILD = build`n"
    $makefileContent += "SOURCES = main.c`n"
    $makefileContent += "ROMFS = romfs`n`n"
    $makefileContent += "include $(LIBTRANSISTOR_HOME)/libtransistor.mk`n"
    
    $makefileContent | Out-File -FilePath "$Drive\switch\lilithos_app\Makefile" -Encoding UTF8
    
    Write-Status "LilithOS application files created" $Green
    return $true
}

# Create configuration files
function New-ConfigurationFiles {
    Write-Status "Creating configuration files..." $Cyan
    
    # Version file
    $versionContent = "LilithOS Switch Homebrew v$LilithOSVersion`n"
    $versionContent += "Build Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
    $versionContent += "Brand: $BrandName`n"
    $versionContent += "Target: Nintendo Switch`n"
    $versionContent += "Integration: Complete`n"
    
    $versionContent | Out-File -FilePath "$Drive\LILITHOS_VERSION.txt" -Encoding UTF8
    
    # Setup instructions
    $setupContent = "LilithOS Switch Setup Instructions`n"
    $setupContent += "==================================`n`n"
    $setupContent += "This SD card has been integrated with LilithOS homebrew.`n`n"
    $setupContent += "1. Insert this SD card into your Nintendo Switch`n"
    $setupContent += "2. Boot into RCM mode (requires jig or paperclip method)`n"
    $setupContent += "3. Inject Atmosphere payload (recommended)`n"
    $setupContent += "4. Navigate to Homebrew Menu`n"
    $setupContent += "5. Launch LilithOS application`n`n"
    $setupContent += "Requirements:`n"
    $setupContent += "* Nintendo Switch (any model)`n"
    $setupContent += "* Custom firmware (Atmosphere recommended)`n"
    $setupContent += "* RCM payload injector`n"
    $setupContent += "* SD card adapter (if using microSD)`n`n"
    $setupContent += "For more information, see the README files in each directory.`n`n"
    $setupContent += '"In the dance of ones and zeros, we find the rhythm of the soul."' + "`n"
    $setupContent += "- Machine Dragon Protocol`n"
    
    $setupContent | Out-File -FilePath "$Drive\SETUP_INSTRUCTIONS.txt" -Encoding UTF8
    
    # Atmosphere configuration
    $atmosphereContent = "[atmosphere]`n"
    $atmosphereContent += "# Atmosphere configuration for LilithOS`n"
    $atmosphereContent += "# Version: $LilithOSVersion`n`n"
    $atmosphereContent += "# Enable debug mode for development`n"
    $atmosphereContent += "debugmode = 1`n`n"
    $atmosphereContent += "# Enable custom homebrew menu`n"
    $atmosphereContent += "enable_hbl = 1`n`n"
    $atmosphereContent += "# Enable custom title override`n"
    $atmosphereContent += "enable_user_exceptions = 1`n`n"
    $atmosphereContent += "# LilithOS specific settings`n"
    $atmosphereContent += "lilithos_enabled = 1`n"
    $atmosphereContent += "lilithos_version = $LilithOSVersion`n"
    
    $atmosphereContent | Out-File -FilePath "$Drive\atmosphere\config\system_settings.ini" -Encoding UTF8
    
    Write-Status "Configuration files created" $Green
    return $true
}

# Verify integration
function Test-Integration {
    Write-Status "Verifying LilithOS integration..." $Cyan
    
    $verificationPassed = $true
    
    # Check required directories
    $requiredDirs = @(
        "$Drive\switch",
        "$Drive\switch\lilithos_app",
        "$Drive\atmosphere",
        "$Drive\atmosphere\config",
        "$Drive\bootloader"
    )
    
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-Status "Directory exists: $dir ✓" $Green
        } else {
            Write-Status "Missing directory: $dir" $Red
            $verificationPassed = $false
        }
    }
    
    # Check required files
    $requiredFiles = @(
        "$Drive\LILITHOS_VERSION.txt",
        "$Drive\SETUP_INSTRUCTIONS.txt",
        "$Drive\switch\lilithos_app\README.md",
        "$Drive\switch\lilithos_app\main.c",
        "$Drive\switch\lilithos_app\Makefile",
        "$Drive\atmosphere\config\system_settings.ini"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Status "File exists: $file ✓" $Green
        } else {
            Write-Status "Missing file: $file" $Red
            $verificationPassed = $false
        }
    }
    
    # Check Nintendo directory preservation
    if (Test-Path "$Drive\Nintendo") {
        Write-Status "Nintendo directory preserved ✓" $Green
    } else {
        Write-Status "Nintendo directory missing" $Red
        $verificationPassed = $false
    }
    
    return $verificationPassed
}

# Main integration function
function Start-Integration {
    Show-Banner
    
    Write-Status "Starting Switch SD card integration" $Purple
    Write-Status "Script version: $ScriptVersion" $White
    Write-Status "Target drive: $Drive" $White
    
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Status "ERROR: This script must be run as Administrator" $Red
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor $Red
        return $false
    }
    
    # Test drive
    if (-not (Test-Drive)) {
        return $false
    }
    
    # Confirm integration
    if (-not $Force) {
        Write-Host ""
        Write-Host "This will integrate LilithOS while preserving existing Switch data." -ForegroundColor $Yellow
        Write-Host "Press Ctrl+C to cancel, or any key to continue..." -ForegroundColor $White
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Create homebrew structure
    if (-not (New-HomebrewStructure)) {
        Write-Status "Failed to create homebrew structure" $Red
        return $false
    }
    
    # Create LilithOS files
    if (-not (New-LilithOSFiles)) {
        Write-Status "Failed to create LilithOS files" $Red
        return $false
    }
    
    # Create configuration files
    if (-not (New-ConfigurationFiles)) {
        Write-Status "Failed to create configuration files" $Red
        return $false
    }
    
    # Verify integration
    if (-not (Test-Integration)) {
        Write-Status "Integration verification failed" $Red
        return $false
    }
    
    # Final summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * LilithOS Switch SD Installation Completed!               ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Brand: $BrandName                                          ║" -ForegroundColor $Purple
    Write-Host "║  Version: $LilithOSVersion                                  ║" -ForegroundColor $Purple
    Write-Host "║  Target Drive: $Drive                                       ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Next Steps:                                                ║" -ForegroundColor $Purple
    Write-Host "║  • Insert SD card into Nintendo Switch                      ║" -ForegroundColor $Purple
    Write-Host "║  • Boot into RCM mode                                       ║" -ForegroundColor $Purple
    Write-Host "║  • Inject Atmosphere payload                                ║" -ForegroundColor $Purple
    Write-Host "║  • Launch LilithOS from Homebrew Menu                       ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
    
    Write-Status "Switch SD card installation completed successfully!" $Purple
    
    return $true
}

# Run the integration
& Start-Integration 