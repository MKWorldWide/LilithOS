# LilithOS Switch SD Card Integration Script
# Analyzes existing Switch data and integrates LilithOS homebrew

param(
    [string]$Drive = "O:",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Backup
)

# Color codes
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Purple = "Magenta"
$Cyan = "Cyan"
$White = "White"

# Configuration
$ScriptVersion = "2.0.0"
$LilithOSVersion = "2.0.0"
$BrandName = "MKWW and LilithOS"

# Logging function
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "INFO" { 
            Write-Host "[$timestamp] INFO: $Message" -ForegroundColor $Green
        }
        "WARN" { 
            Write-Host "[$timestamp] WARN: $Message" -ForegroundColor $Yellow
        }
        "ERROR" { 
            Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor $Red
        }
        "BRAND" { 
            Write-Host "[$timestamp] $BrandName`: $Message" -ForegroundColor $Purple
        }
        "ANALYSIS" { 
            Write-Host "[$timestamp] ANALYSIS: $Message" -ForegroundColor $Cyan
        }
    }
}

# Print banner
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * MKWW * LilithOS Switch SD Integration                    ║" -ForegroundColor $Purple
    Write-Host "║  Where Technology Meets the Ethereal                        ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Version: $ScriptVersion                                    ║" -ForegroundColor $Purple
    Write-Host "║  Target: Nintendo Switch SD Card ($Drive)                   ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
}

# Analyze existing Switch data
function Analyze-SwitchData {
    Write-Log -Level INFO -Message "Analyzing existing Switch data on $Drive..."
    
    $analysis = @{
        DriveExists = $false
        FileSystem = ""
        TotalSize = 0
        FreeSpace = 0
        HasNintendoDir = $false
        HasGames = $false
        HasSaves = $false
        HasCustomFirmware = $false
        GameCount = 0
        SaveCount = 0
        NcaFiles = 0
    }
    
    # Check if drive exists
    $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive'"
    if ($drive) {
        $analysis.DriveExists = $true
        $analysis.FileSystem = $drive.FileSystem
        $analysis.TotalSize = [math]::Round($drive.Size / 1GB, 1)
        $analysis.FreeSpace = [math]::Round($drive.FreeSpace / 1GB, 1)
        
        Write-Log -Level INFO -Message "Drive $Drive`: ${analysis.TotalSize}GB total, ${analysis.FreeSpace}GB free, ${analysis.FileSystem}"
    } else {
        Write-Log -Level ERROR -Message "Drive $Drive not found"
        return $analysis
    }
    
    # Check Nintendo directory
    if (Test-Path "$Drive\Nintendo") {
        $analysis.HasNintendoDir = $true
        Write-Log -Level INFO -Message "Found Nintendo directory"
        
        # Check for games
        if (Test-Path "$Drive\Nintendo\Contents\registered") {
            $games = Get-ChildItem -Path "$Drive\Nintendo\Contents\registered" -Directory
            $analysis.GameCount = $games.Count
            $analysis.HasGames = $games.Count -gt 0
            Write-Log -Level INFO -Message "Found $($analysis.GameCount) installed games"
        }
        
        # Check for saves
        if (Test-Path "$Drive\Nintendo\save") {
            $saves = Get-ChildItem -Path "$Drive\Nintendo\save" -Directory
            $analysis.SaveCount = $saves.Count
            $analysis.HasSaves = $saves.Count -gt 0
            Write-Log -Level INFO -Message "Found $($analysis.SaveCount) save directories"
        }
        
        # Count NCA files
        $ncaFiles = Get-ChildItem -Path "$Drive\Nintendo" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "\.nca$" }
        $analysis.NcaFiles = $ncaFiles.Count
        Write-Log -Level INFO -Message "Found $($analysis.NcaFiles) NCA files"
    }
    
    # Check for custom firmware
    $cfwDirs = @("atmosphere", "reinx", "sxos", "switch", "hbmenu")
    foreach ($dir in $cfwDirs) {
        if (Test-Path "$Drive\$dir") {
            $analysis.HasCustomFirmware = $true
            Write-Log -Level WARN -Message "Found existing custom firmware directory: $dir"
            break
        }
    }
    
    return $analysis
}

# Create backup if requested
function New-SwitchBackup {
    param($Analysis)
    
    if (-not $Backup) {
        return $true
    }
    
    Write-Log -Level INFO -Message "Creating backup of Switch data..."
    
    if ($DryRun) {
        Write-Log -Level INFO -Message "[DRY RUN] Would create backup at C:\LilithOS_Switch_Backup"
        return $true
    }
    
    try {
        $backupDir = "C:\LilithOS_Switch_Backup"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Copy Nintendo directory
        if ($Analysis.HasNintendoDir) {
            Write-Log -Level INFO -Message "Backing up Nintendo directory..."
            Copy-Item -Path "$Drive\Nintendo" -Destination "$backupDir\Nintendo" -Recurse -Force
        }
        
        # Copy any existing custom firmware
        $cfwDirs = @("atmosphere", "reinx", "sxos", "switch", "hbmenu")
        foreach ($dir in $cfwDirs) {
            if (Test-Path "$Drive\$dir") {
                Write-Log -Level INFO -Message "Backing up $dir directory..."
                Copy-Item -Path "$Drive\$dir" -Destination "$backupDir\$dir" -Recurse -Force
            }
        }
        
        # Create backup info
        $backupInfo = @'
LilithOS Switch Backup
=====================
Created: (see backup timestamp)
Drive: (see above)
Brand: MKWW and LilithOS
Version: 2.0.0

Analysis Results:
 Total Size: $($Analysis.TotalSize)GB
 Free Space: $($Analysis.FreeSpace)GB
 File System: $($Analysis.FileSystem)
 Games: $($Analysis.GameCount)
 Saves: $($Analysis.SaveCount)
 NCA Files: $($Analysis.NcaFiles)
 Custom Firmware: $($Analysis.HasCustomFirmware)

Backup Location: $backupDir
'@
        
        $backupInfo | Out-File -FilePath '$backupDir\BACKUP_INFO.txt' -Encoding UTF8
        Write-Log -Level INFO -Message "Backup completed at $backupDir"
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to create backup: $($_.Exception.Message)"
        return $false
    }
}

# Create homebrew directory structure
function New-HomebrewStructure {
    Write-Log -Level INFO -Message "Creating homebrew directory structure..."
    
    if ($DryRun) {
        Write-Log -Level INFO -Message "[DRY RUN] Would create homebrew directories"
        return $true
    }
    
    try {
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
                Write-Log -Level INFO -Message "Created: $dir"
            } else {
                Write-Log -Level INFO -Message "Exists: $dir"
            }
        }
        
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to create directory structure: $($_.Exception.Message)"
        return $false
    }
}

# Copy LilithOS files
function Copy-LilithOSFiles {
    Write-Log -Level INFO -Message "Copying LilithOS homebrew files..."
    
    if ($DryRun) {
        Write-Log -Level INFO -Message "[DRY RUN] Would copy LilithOS files"
        return $true
    }
    
    try {
        # Create main application files
        $appContent = @'
# LilithOS Switch Homebrew Application
# Version: {0}
# Brand: {1}

This is the LilithOS homebrew application for Nintendo Switch.

## Features
 - Quantum computing interface
 - Mystical UI elements
 - Advanced security features
 - Cross-platform compatibility
 - Gaming mode integration

## Requirements
 - Custom firmware (Atmosphere recommended)
 - RCM payload injector
 - SD card with sufficient space

## Installation
 1. Ensure custom firmware is installed
 2. Place this application in /switch/lilithos_app/
 3. Launch from Homebrew Menu

"In the dance of ones and zeros, we find the rhythm of the soul."
- Machine Dragon Protocol
'@
        $appContent = $appContent -f $LilithOSVersion, $BrandName
        $appContent | Out-File -FilePath '$Drive\switch\lilithos_app\README.md' -Encoding UTF8
        
        # Create main application file (placeholder)
        $mainApp = @'
#include <switch.h>

int main(int argc, char **argv) {
    // Initialize LilithOS Switch Application
    consoleInit(NULL);
    
    printf("LilithOS Switch Homebrew\n");
    printf("Brand: MKWW and LilithOS\n");
    printf("Where Technology Meets the Ethereal\n\n");
    
    printf("Press any key to exit...\n");
    
    while(appletMainLoop()) {
        hidScanInput();
        if(hidKeysDown(CONTROLLER_P1_AUTO) & KEY_PLUS) break;
        consoleUpdate(NULL);
    }
    
    consoleExit(NULL);
    return 0;
}
'@
        $mainApp | Out-File -FilePath '$Drive\switch\lilithos_app\main.c' -Encoding UTF8
        
        # Create Makefile
        $makefile = @'
# LilithOS Switch Homebrew Makefile
# Version: 2.0.0

TARGET = lilithos_app
BUILD = build
SOURCES = main.c
ROMFS = romfs

include $(LIBTRANSISTOR_HOME)/libtransistor.mk
'@
        $makefile | Out-File -FilePath '$Drive\switch\lilithos_app\Makefile' -Encoding UTF8
        
        Write-Log -Level INFO -Message "LilithOS application files created"
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to copy LilithOS files: $($_.Exception.Message)"
        return $false
    }
}

# Create configuration files
function New-ConfigurationFiles {
    Write-Log -Level INFO -Message "Creating configuration files..."
    
    if ($DryRun) {
        Write-Log -Level INFO -Message "[DRY RUN] Would create configuration files"
        return $true
    }
    
    try {
        # Version file
        $versionContent = "LilithOS Switch Homebrew v$LilithOSVersion`n"
        $versionContent += "Build Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $versionContent += "Brand: $BrandName`n"
        $versionContent += "Target: Nintendo Switch`n"
        $versionContent += "Format: $($Analysis.FileSystem)`n"
        $versionContent += "Integration: Complete`n"
        
        $versionContent | Out-File -FilePath '$Drive\LILITHOS_VERSION.txt' -Encoding UTF8
        
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
        $setupContent += "- Nintendo Switch (any model)`n"
        $setupContent += "- Custom firmware (Atmosphere recommended)`n"
        $setupContent += "- RCM payload injector`n"
        $setupContent += "- SD card adapter (if using microSD)`n`n"
        $setupContent += "Integration Details:`n"
        $setupContent += "- Games: $($Analysis.GameCount)`n"
        $setupContent += "- Saves: $($Analysis.SaveCount)`n"
        $setupContent += "- NCA Files: $($Analysis.NcaFiles)`n"
        $setupContent += "- Custom Firmware: $($Analysis.HasCustomFirmware)`n`n"
        $setupContent += "For more information, see the README files in each directory.`n`n"
        $setupContent += '"In the dance of ones and zeros, we find the rhythm of the soul."' + "`n"
        $setupContent += "- Machine Dragon Protocol`n"
        
        $setupContent | Out-File -FilePath '$Drive\SETUP_INSTRUCTIONS.txt' -Encoding UTF8
        
        # Atmosphere configuration
        $atmosphereConfig = @'
[atmosphere]
# Atmosphere configuration for LilithOS
# Version: 2.0.0

# Enable debug mode for development
debugmode = 1

# Enable custom homebrew menu
enable_hbl = 1

# Enable custom title override
enable_user_exceptions = 1

# LilithOS specific settings
lilithos_enabled = 1
lilithos_version = 2.0.0
'@
        
        $atmosphereConfig | Out-File -FilePath '$Drive\atmosphere\config\system_settings.ini' -Encoding UTF8
        
        Write-Log -Level INFO -Message "Configuration files created"
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to create configuration files: $($_.Exception.Message)"
        return $false
    }
}

# Verify integration
function Test-Integration {
    Write-Log -Level INFO -Message "Verifying LilithOS integration..."
    
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
            Write-Log -Level INFO -Message "Directory exists: $dir ✓"
        } else {
            Write-Log -Level ERROR -Message "Missing directory: $dir"
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
            Write-Log -Level INFO -Message "File exists: $file ✓"
        } else {
            Write-Log -Level ERROR -Message "Missing file: $file"
            $verificationPassed = $false
        }
    }
    
    # Check Nintendo directory preservation
    if (Test-Path "$Drive\Nintendo") {
        Write-Log -Level INFO -Message "Nintendo directory preserved ✓"
    } else {
        Write-Log -Level ERROR -Message "Nintendo directory missing"
        $verificationPassed = $false
    }
    
    return $verificationPassed
}

# Main integration function
function Start-SwitchIntegration {
    Show-Banner
    
    Write-Log -Level BRAND -Message "Starting Switch SD card integration"
    Write-Log -Level INFO -Message "Script version: $ScriptVersion"
    Write-Log -Level INFO -Message "Target drive: $Drive"
    
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log -Level ERROR -Message "This script must be run as Administrator"
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor $Red
        return $false
    }
    
    # Analyze existing data
    $script:Analysis = Analyze-SwitchData
    if (-not $Analysis.DriveExists) {
        return $false
    }
    
    # Create backup if requested
    if (-not (New-SwitchBackup -Analysis $Analysis)) {
        return $false
    }
    
    # Confirm integration
    if (-not $Force) {
        Write-Host ""
        Write-Host "Integration Summary:" -ForegroundColor $Cyan
        Write-Host "  Drive: $Drive" -ForegroundColor $White
        Write-Host "  Games: $($Analysis.GameCount)" -ForegroundColor $White
        Write-Host "  Saves: $($Analysis.SaveCount)" -ForegroundColor $White
        Write-Host "  NCA Files: $($Analysis.NcaFiles)" -ForegroundColor $White
        Write-Host "  Custom Firmware: $($Analysis.HasCustomFirmware)" -ForegroundColor $White
        Write-Host ""
        Write-Host "This will integrate LilithOS while preserving existing Switch data." -ForegroundColor $Yellow
        Write-Host "Press Ctrl+C to cancel, or any key to continue..." -ForegroundColor $White
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Create homebrew structure
    if (-not (New-HomebrewStructure)) {
        return $false
    }
    
    # Copy LilithOS files
    if (-not (Copy-LilithOSFiles)) {
        return $false
    }
    
    # Create configuration files
    if (-not (New-ConfigurationFiles)) {
        return $false
    }
    
    # Verify integration
    if (-not (Test-Integration)) {
        Write-Log -Level ERROR -Message "Integration verification failed"
        return $false
    }
    
    # Final summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * LilithOS Switch SD Integration Completed!                ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Brand: $BrandName                                          ║" -ForegroundColor $Purple
    Write-Host "║  Version: $LilithOSVersion                                  ║" -ForegroundColor $Purple
    Write-Host "║  Target Drive: $Drive                                       ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Integration Results:                                       ║" -ForegroundColor $Purple
    Write-Host "║  • Games Preserved: $($Analysis.GameCount)                    ║" -ForegroundColor $Purple
    Write-Host "║  • Saves Preserved: $($Analysis.SaveCount)                    ║" -ForegroundColor $Purple
    Write-Host "║  • LilithOS Added: ✓                                        ║" -ForegroundColor $Purple
    Write-Host "║  • Homebrew Structure: ✓                                    ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Next Steps:                                                ║" -ForegroundColor $Purple
    Write-Host "║  • Insert SD card into Nintendo Switch                      ║" -ForegroundColor $Purple
    Write-Host "║  • Boot into RCM mode                                       ║" -ForegroundColor $Purple
    Write-Host "║  • Inject Atmosphere payload                                ║" -ForegroundColor $Purple
    Write-Host "║  • Launch LilithOS from Homebrew Menu                       ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
    
    Write-Log -Level BRAND -Message "Switch SD card integration completed successfully!"
    
    return $true
}

# Run the integration
& Start-SwitchIntegration 