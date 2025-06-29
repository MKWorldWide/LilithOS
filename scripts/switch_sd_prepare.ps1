# LilithOS Nintendo Switch SD Card Preparation Script
# Automatically formats and prepares O:\ drive for Switch homebrew

param(
    [switch]$Force,
    [switch]$DryRun,
    [string]$TargetDrive = "O:"
)

# Set console encoding for proper Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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
            Write-Host "[$timestamp] $BrandName: $Message" -ForegroundColor $Purple
        }
    }
    
    # Write to log file
    $logMessage = "[$timestamp] $Level`: $Message"
    Add-Content -Path "$PSScriptRoot\switch_sd_prepare.log" -Value $logMessage
}

# Print banner
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * MKWW * LilithOS Switch SD Card Preparation               ║" -ForegroundColor $Purple
    Write-Host "║  Where Technology Meets the Ethereal                        ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Version: $ScriptVersion                                    ║" -ForegroundColor $Purple
    Write-Host "║  Target: Nintendo Switch SD Card ($TargetDrive)             ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
}

# Check if drive exists and is removable
function Test-SwitchDrive {
    Write-Log "INFO" "Checking target drive $TargetDrive..."
    
    $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$TargetDrive'"
    if (-not $drive) {
        Write-Log "ERROR" "Drive $TargetDrive not found"
        return $false
    }
    
    # Check if it's a removable drive (likely SD card)
    $physicalDrive = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.MediaType -like "*SD*" -or $_.MediaType -like "*Flash*" }
    if (-not $physicalDrive) {
        Write-Log "WARN" "Drive may not be an SD card - proceed with caution"
    }
    
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 1)
    $totalSpaceGB = [math]::Round($drive.Size / 1GB, 1)
    
    Write-Log "INFO" "Drive $TargetDrive found: ${totalSpaceGB}GB total, ${freeSpaceGB}GB free"
    return $true
}

# Format drive as exFAT
function Format-SwitchDrive {
    Write-Log "INFO" "Formatting $TargetDrive as exFAT for Nintendo Switch..."
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would format $TargetDrive as exFAT"
        return $true
    }
    
    try {
        # Format using PowerShell
        $formatParams = @{
            DriveLetter = $TargetDrive.TrimEnd(':')
            FileSystem = "exFAT"
            NewFileSystemLabel = "LilithOS_Switch"
            Confirm = $false
        }
        
        Format-Volume @formatParams
        Write-Log "INFO" "Drive formatted successfully as exFAT"
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to format drive: $($_.Exception.Message)"
        return $false
    }
}

# Create Switch homebrew directory structure
function New-SwitchDirectoryStructure {
    Write-Log "INFO" "Creating Switch homebrew directory structure..."
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would create directory structure on $TargetDrive"
        return $true
    }
    
    try {
        # Create main directories
        $directories = @(
            "$TargetDrive\switch",
            "$TargetDrive\switch\lilithos_app",
            "$TargetDrive\switch\lilithos_app\source",
            "$TargetDrive\switch\lilithos_app\assets",
            "$TargetDrive\switch\lilithos_app\config",
            "$TargetDrive\switch\lilithos_app\logs",
            "$TargetDrive\atmosphere",
            "$TargetDrive\atmosphere\contents",
            "$TargetDrive\atmosphere\config",
            "$TargetDrive\atmosphere\patches",
            "$TargetDrive\bootloader",
            "$TargetDrive\bootloader\payloads",
            "$TargetDrive\config",
            "$TargetDrive\logs"
        )
        
        foreach ($dir in $directories) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Write-Log "INFO" "Directory structure created successfully"
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to create directory structure: $($_.Exception.Message)"
        return $false
    }
}

# Copy LilithOS Switch files
function Copy-LilithOSSwitchFiles {
    Write-Log "INFO" "Copying LilithOS Switch homebrew files..."
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would copy LilithOS files to $TargetDrive"
        return $true
    }
    
    try {
        $sourceDir = "$PSScriptRoot\..\switch\homebrew\lilithos_app"
        
        if (Test-Path $sourceDir) {
            # Copy main application files
            Copy-Item -Path "$sourceDir\*" -Destination "$TargetDrive\switch\lilithos_app\" -Recurse -Force
            
            # Copy README and documentation
            if (Test-Path "$sourceDir\README.md") {
                Copy-Item -Path "$sourceDir\README.md" -Destination "$TargetDrive\switch\lilithos_app\README.md" -Force
            }
            
            Write-Log "INFO" "LilithOS Switch files copied successfully"
            return $true
        } else {
            Write-Log "WARN" "LilithOS Switch source directory not found, creating placeholder files"
            
            # Create placeholder files
            $placeholderContent = @"
# LilithOS Switch Homebrew Application
# Version: $LilithOSVersion
# Brand: $BrandName

This is the LilithOS homebrew application for Nintendo Switch.
Placeholder file - replace with actual application files.

"In the dance of ones and zeros, we find the rhythm of the soul."
- Machine Dragon Protocol
"@
            
            $placeholderContent | Out-File -FilePath "$TargetDrive\switch\lilithos_app\README.md" -Encoding UTF8
            Write-Log "INFO" "Placeholder files created"
            return $true
        }
    }
    catch {
        Write-Log "ERROR" "Failed to copy LilithOS files: $($_.Exception.Message)"
        return $false
    }
}

# Create version and info files
function New-VersionFiles {
    Write-Log "INFO" "Creating version and information files..."
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would create version files"
        return $true
    }
    
    try {
        # Version file
        $versionContent = @"
LilithOS Switch Homebrew v$LilithOSVersion
Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Brand: $BrandName
Target: Nintendo Switch
Format: exFAT
"@
        
        $versionContent | Out-File -FilePath "$TargetDrive\LILITHOS_VERSION.txt" -Encoding UTF8
        
        # Setup instructions
        $setupContent = @"
LilithOS Switch Setup Instructions
==================================

1. Insert this SD card into your Nintendo Switch
2. Boot into RCM mode (requires jig or paperclip method)
3. Inject payload (Atmosphere, ReiNX, or SXOS)
4. Navigate to Homebrew Menu
5. Launch LilithOS application

Requirements:
- Nintendo Switch (any model)
- Custom firmware (Atmosphere recommended)
- RCM payload injector
- SD card adapter (if using microSD)

For more information, see the README files in each directory.

"In the dance of ones and zeros, we find the rhythm of the soul."
- Machine Dragon Protocol
"@
        
        $setupContent | Out-File -FilePath "$TargetDrive\SETUP_INSTRUCTIONS.txt" -Encoding UTF8
        
        Write-Log "INFO" "Version and information files created"
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to create version files: $($_.Exception.Message)"
        return $false
    }
}

# Verify setup
function Test-SwitchSetup {
    Write-Log "INFO" "Verifying Switch SD card setup..."
    
    $verificationPassed = $true
    
    # Check if drive is formatted as exFAT
    $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$TargetDrive'"
    if ($drive.FileSystem -eq "exFAT") {
        Write-Log "INFO" "Drive format: exFAT ✓"
    } else {
        Write-Log "ERROR" "Drive format: $($drive.FileSystem) (should be exFAT)"
        $verificationPassed = $false
    }
    
    # Check directory structure
    $requiredDirs = @(
        "$TargetDrive\switch",
        "$TargetDrive\switch\lilithos_app",
        "$TargetDrive\atmosphere",
        "$TargetDrive\bootloader"
    )
    
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-Log "INFO" "Directory exists: $dir ✓"
        } else {
            Write-Log "ERROR" "Missing directory: $dir"
            $verificationPassed = $false
        }
    }
    
    # Check files
    $requiredFiles = @(
        "$TargetDrive\LILITHOS_VERSION.txt",
        "$TargetDrive\SETUP_INSTRUCTIONS.txt"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Log "INFO" "File exists: $file ✓"
        } else {
            Write-Log "ERROR" "Missing file: $file"
            $verificationPassed = $false
        }
    }
    
    return $verificationPassed
}

# Main function
function Start-SwitchPreparation {
    Show-Banner
    
    Write-Log "BRAND" "Starting Switch SD card preparation"
    Write-Log "INFO" "Script version: $ScriptVersion"
    Write-Log "INFO" "Target drive: $TargetDrive"
    
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "ERROR" "This script must be run as Administrator"
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor $Red
        return $false
    }
    
    # Check target drive
    if (-not (Test-SwitchDrive)) {
        return $false
    }
    
    # Confirm setup
    if (-not $Force) {
        Write-Host ""
        Write-Host "WARNING: This will format $TargetDrive and erase all data!" -ForegroundColor $Yellow
        Write-Host "   - Format drive as exFAT" -ForegroundColor $White
        Write-Host "   - Create Switch homebrew directory structure" -ForegroundColor $White
        Write-Host "   - Copy LilithOS files" -ForegroundColor $White
        Write-Host "   - Create setup instructions" -ForegroundColor $White
        Write-Host ""
        
        $confirmation = Read-Host "Do you want to continue? (y/N)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-Log "INFO" "Setup cancelled by user"
            return $false
        }
    }
    
    # Format drive
    if (-not (Format-SwitchDrive)) {
        return $false
    }
    
    # Create directory structure
    if (-not (New-SwitchDirectoryStructure)) {
        return $false
    }
    
    # Copy LilithOS files
    if (-not (Copy-LilithOSSwitchFiles)) {
        return $false
    }
    
    # Create version files
    if (-not (New-VersionFiles)) {
        return $false
    }
    
    # Verify setup
    if (-not (Test-SwitchSetup)) {
        Write-Log "ERROR" "Setup verification failed"
        return $false
    }
    
    # Final summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  * LilithOS Switch SD Card Preparation Completed!           ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Brand: $BrandName                                          ║" -ForegroundColor $Purple
    Write-Host "║  Version: $LilithOSVersion                                  ║" -ForegroundColor $Purple
    Write-Host "║  Target Drive: $TargetDrive                                 ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "║  Next Steps:                                                ║" -ForegroundColor $Purple
    Write-Host "║  • Insert SD card into Nintendo Switch                      ║" -ForegroundColor $Purple
    Write-Host "║  • Boot into RCM mode                                       ║" -ForegroundColor $Purple
    Write-Host "║  • Inject custom firmware payload                           ║" -ForegroundColor $Purple
    Write-Host "║  • Launch LilithOS from Homebrew Menu                       ║" -ForegroundColor $Purple
    Write-Host "║                                                              ║" -ForegroundColor $Purple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $Purple
    Write-Host ""
    
    Write-Log "BRAND" "Switch SD card preparation completed successfully!"
    Write-Log "INFO" "Log file: $PSScriptRoot\switch_sd_prepare.log"
    
    return $true
}

# Run the preparation
& Start-SwitchPreparation 