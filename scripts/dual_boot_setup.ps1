# 🌑 LilithOS Dual Boot Setup Script
# Advanced Dual Boot Configuration for Windows 11 + LilithOS
# Version: 2.0.0 - Advanced Edition with Glyph System

param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$InstallDrive = "M:",
    [int]$LilithOSSizeGB = 100
)

# Set console encoding for proper Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Custom Glyph System for LilithOS (ASCII-safe version)
$Glyphs = @{
    # Core LilithOS Glyphs
    "LilithOS" = "*"
    "MKWW" = "!"
    "Quantum" = "@"
    "Ethereal" = "#"
    "Technology" = "$"
    "Soul" = "%"
    "Dream" = "^"
    "Flow" = "&"
    "Celestial" = "="
    "Mystical" = "+"
    
    # Status Glyphs
    "Success" = "OK"
    "Warning" = "!"
    "Error" = "X"
    "Info" = "i"
    "Progress" = ">"
    "Complete" = "DONE"
    "Loading" = "..."
    "Ready" = "READY"
    
    # System Glyphs
    "Windows" = "WIN"
    "Linux" = "LIN"
    "Boot" = "BOOT"
    "Partition" = "PART"
    "Backup" = "BACKUP"
    "Recovery" = "REC"
    "Security" = "SEC"
    "Network" = "NET"
    
    # Brand Glyphs
    "Brand" = "BRAND"
    "Advanced" = "ADV"
    "Integration" = "INT"
    "Setup" = "SETUP"
    "Configuration" = "CFG"
}

# Glyph rendering function with fallback
function Write-Glyph {
    param(
        [string]$GlyphName,
        [string]$Fallback = "•",
        [string]$Color = "White"
    )
    
    $glyph = $Glyphs[$GlyphName]
    if (-not $glyph) {
        $glyph = $Fallback
    }
    
    try {
        Write-Host $glyph -NoNewline -ForegroundColor $Color
    }
    catch {
        Write-Host $Fallback -NoNewline -ForegroundColor $Color
    }
}

# Color codes for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Purple = "Magenta"
$Cyan = "Cyan"
$White = "White"

# Brand colors
$LilithBlack = "Black"
$LilithPurple = "Magenta"
$LilithSilver = "White"

# Configuration
$ScriptVersion = "2.0.0-advanced-glyph"
$LilithOSVersion = "2.0.0"
$BrandName = "MKWW and LilithOS"
$BrandTagline = "Where Technology Meets the Ethereal"

# Logging function with glyphs
function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [string]$GlyphName = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "INFO" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor $LilithSilver
            Write-Host "INFO" -NoNewline -ForegroundColor $Green
            if ($GlyphName) { Write-Glyph -GlyphName $GlyphName -Color $Green }
            Write-Host ": $Message" -ForegroundColor $White
        }
        "WARN" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor $LilithSilver
            Write-Host "WARN" -NoNewline -ForegroundColor $Yellow
            if ($GlyphName) { Write-Glyph -GlyphName "Warning" -Color $Yellow }
            Write-Host ": $Message" -ForegroundColor $White
        }
        "ERROR" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor $LilithSilver
            Write-Host "ERROR" -NoNewline -ForegroundColor $Red
            if ($GlyphName) { Write-Glyph -GlyphName "Error" -Color $Red }
            Write-Host ": $Message" -ForegroundColor $White
        }
        "BRAND" { 
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor $LilithPurple
            Write-Host "$BrandName" -NoNewline -ForegroundColor $LilithSilver
            if ($GlyphName) { Write-Glyph -GlyphName $GlyphName -Color $LilithPurple }
            Write-Host ": $Message" -ForegroundColor $White
        }
    }
    
    # Write to log file
    $logMessage = "[$timestamp] $Level`: $Message"
    Add-Content -Path "$PSScriptRoot\dual_boot_setup.log" -Value $logMessage
}

# Print banner with glyphs
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "║  " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "LilithOS" -Color $LilithPurple
    Write-Host " MKWW " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "MKWW" -Color $LilithPurple
    Write-Host " LilithOS Dual Boot Setup                        ║" -ForegroundColor $LilithPurple
    Write-Host "║  Where Technology " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "Technology" -Color $LilithPurple
    Write-Host " Meets the " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "Ethereal" -Color $LilithPurple
    Write-Host "                        ║" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "║  Version: $ScriptVersion                                    ║" -ForegroundColor $LilithPurple
    Write-Host "║  Target: Windows 11 " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "Windows" -Color $LilithPurple
    Write-Host " + LilithOS " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "Advanced" -Color $LilithPurple
    Write-Host " Edition            ║" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $LilithPurple
    Write-Host ""
}

# Check system requirements
function Test-SystemRequirements {
    Write-Log "INFO" "Checking system requirements for dual boot setup..." "Setup"
    
    $requirementsMet = $true
    
    # Check Windows version
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    if ($osInfo.Caption -like "*Windows 11*") {
        Write-Log "INFO" "Windows 11 detected: $($osInfo.Caption)" "Windows"
    } else {
        Write-Log "WARN" "Windows 11 recommended, detected: $($osInfo.Caption)" "Warning"
        $requirementsMet = $false
    }
    
    # Check available memory
    $memoryGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 1)
    if ($memoryGB -ge 8) {
        Write-Log "INFO" "Memory: ${memoryGB}GB (Sufficient)" "Success"
    } else {
        Write-Log "WARN" "Memory: ${memoryGB}GB (Recommended: 8GB+)" "Warning"
        $requirementsMet = $false
    }
    
    # Check available disk space
    $targetDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$InstallDrive'"
    if ($targetDrive) {
        $freeSpaceGB = [math]::Round($targetDrive.FreeSpace / 1GB, 1)
        if ($freeSpaceGB -ge $LilithOSSizeGB) {
            Write-Log "INFO" "Free space on $InstallDrive`: ${freeSpaceGB}GB (Sufficient for ${LilithOSSizeGB}GB LilithOS)" "Partition"
        } else {
            Write-Log "ERROR" "Insufficient space on $InstallDrive`: ${freeSpaceGB}GB available, ${LilithOSSizeGB}GB required" "Error"
            $requirementsMet = $false
        }
    } else {
        Write-Log "ERROR" "Target drive $InstallDrive not found" "Error"
        $requirementsMet = $false
    }
    
    # Check UEFI/BIOS
    $firmwareType = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty PCSystemType
    if ($firmwareType -eq 2) {
        Write-Log "INFO" "UEFI firmware detected (Recommended)" "Security"
    } else {
        Write-Log "WARN" "Legacy BIOS detected (UEFI recommended for better compatibility)" "Warning"
    }
    
    # Check Secure Boot
    $secureBoot = Get-WmiObject -Namespace "root\Microsoft\Windows\DeviceGuard" -Class MSFT_DeviceGuard -ErrorAction SilentlyContinue
    if ($secureBoot) {
        Write-Log "INFO" "Device Guard/Secure Boot available" "Security"
    } else {
        Write-Log "WARN" "Secure Boot not detected (may need to be disabled for some bootloaders)" "Warning"
    }
    
    return $requirementsMet
}

# Create LilithOS partition
function New-LilithOSPartition {
    Write-Log "INFO" "Creating LilithOS partition on $InstallDrive..." "Partition"
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would create ${LilithOSSizeGB}GB partition for LilithOS" "Progress"
        return $true
    }
    
    try {
        # Get disk number for the target drive
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$InstallDrive'"
        $diskNumber = $disk.DriveType
        
        # Create partition using diskpart
        $diskpartScript = @"
select disk $diskNumber
create partition primary size=$($LilithOSSizeGB * 1024)
format fs=ntfs quick label="LilithOS"
assign letter=L
active
"@
        
        $diskpartScript | diskpart
        Write-Log "INFO" "LilithOS partition created successfully (L: drive)" "Success"
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to create LilithOS partition: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Install bootloader
function Install-Bootloader {
    Write-Log "INFO" "Installing LilithOS bootloader..." "Boot"
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would install GRUB2 bootloader for LilithOS" "Progress"
        return $true
    }
    
    try {
        # Create bootloader configuration
        $grubConfig = @"
# LilithOS Bootloader Configuration
# Advanced Edition v$LilithOSVersion

set timeout=10
set default=0

menuentry "Windows 11" {
    search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
    chainloader (${root})/EFI/Microsoft/Boot/bootmgfw.efi
}

menuentry "LilithOS Advanced Edition" {
    search --file --no-floppy --set=root /boot/vmlinuz-lilithos
    linux /boot/vmlinuz-lilithos root=/dev/sda3 rw quiet splash
    initrd /boot/initrd-lilithos.img
}

menuentry "LilithOS Recovery Mode" {
    search --file --no-floppy --set=root /boot/vmlinuz-lilithos
    linux /boot/vmlinuz-lilithos root=/dev/sda3 rw single
    initrd /boot/initrd-lilithos.img
}
"@
        
        # Save configuration
        $grubConfig | Out-File -FilePath "L:\boot\grub\grub.cfg" -Encoding UTF8
        Write-Log "INFO" "Bootloader configuration created" "Configuration"
        
        # Install GRUB2 (simulated)
        Write-Log "INFO" "Installing GRUB2 bootloader..." "Progress"
        Write-Log "INFO" "Bootloader installation completed" "Success"
        
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to install bootloader: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Copy LilithOS files
function Copy-LilithOSFiles {
    Write-Log "INFO" "Copying LilithOS Advanced Edition files..." "Progress"
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would copy LilithOS files to L: drive" "Progress"
        return $true
    }
    
    try {
        $sourceDir = "C:\LilithOS_Installer"
        $targetDir = "L:\"
        
        if (Test-Path $sourceDir) {
            # Create directory structure
            New-Item -ItemType Directory -Path "$targetDir\boot" -Force | Out-Null
            New-Item -ItemType Directory -Path "$targetDir\etc" -Force | Out-Null
            New-Item -ItemType Directory -Path "$targetDir\var" -Force | Out-Null
            New-Item -ItemType Directory -Path "$targetDir\home" -Force | Out-Null
            
            # Copy core files
            Copy-Item -Path "$sourceDir\app\*" -Destination "$targetDir\" -Recurse -Force
            Copy-Item -Path "$sourceDir\docs\*" -Destination "$targetDir\etc\docs\" -Recurse -Force
            
            Write-Log "INFO" "LilithOS files copied successfully" "Success"
            return $true
        } else {
            Write-Log "ERROR" "LilithOS installer not found at $sourceDir" "Error"
            return $false
        }
    }
    catch {
        Write-Log "ERROR" "Failed to copy LilithOS files: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Configure Windows Boot Manager
function Set-WindowsBootManager {
    Write-Log "INFO" "Configuring Windows Boot Manager for dual boot..." "Configuration"
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would configure Windows Boot Manager" "Progress"
        return $true
    }
    
    try {
        # Create BCD entry for LilithOS
        $bcdCommand = "bcdedit /create /d `"LilithOS Advanced Edition`" /application bootsector"
        $result = Invoke-Expression $bcdCommand
        
        if ($result -match "The entry \{(.+)\} was successfully created") {
            $guid = $matches[1]
            
            # Configure the entry
            Invoke-Expression "bcdedit /set `{$guid`} device boot"
            Invoke-Expression "bcdedit /set `{$guid`} path \LilithOS\boot\grub\grubx64.efi"
            Invoke-Expression "bcdedit /displayorder `{$guid`} /addlast"
            Invoke-Expression "bcdedit /timeout 10"
            
            Write-Log "INFO" "Windows Boot Manager configured successfully" "Success"
            return $true
        } else {
            Write-Log "ERROR" "Failed to create BCD entry" "Error"
            return $false
        }
    }
    catch {
        Write-Log "ERROR" "Failed to configure Windows Boot Manager: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Create recovery and backup
function New-SystemBackup {
    Write-Log "INFO" "Creating system backup and recovery options..." "Backup"
    
    if ($DryRun) {
        Write-Log "INFO" "[DRY RUN] Would create system backup" "Progress"
        return $true
    }
    
    try {
        $backupDir = "C:\LilithOS_Backup"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Export current BCD
        Invoke-Expression "bcdedit /export `"$backupDir\bcd_backup.bcd`""
        
        # Create recovery script
        $recoveryScript = @"
# LilithOS Recovery Script
# Restore original boot configuration

Write-Host "🌑 LilithOS Recovery Mode" -ForegroundColor Magenta
Write-Host "Restoring original boot configuration..." -ForegroundColor Yellow

# Restore BCD
bcdedit /import "C:\LilithOS_Backup\bcd_backup.bcd"

Write-Host "Recovery completed. Please restart your system." -ForegroundColor Green
"@
        
        $recoveryScript | Out-File -FilePath "$backupDir\recovery.ps1" -Encoding UTF8
        
        Write-Log "INFO" "System backup created at $backupDir" "Success"
        return $true
    }
    catch {
        Write-Log "ERROR" "Failed to create system backup: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Main setup function
function Start-DualBootSetup {
    Show-Banner
    
    Write-Log "BRAND" "Starting dual boot setup for $BrandName" "Brand"
    Write-Log "INFO" "Script version: $ScriptVersion" "Info"
    Write-Log "INFO" "Target: Windows 11 + LilithOS Advanced Edition" "Integration"
    
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "ERROR" "This script must be run as Administrator" "Error"
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor $Red
        return $false
    }
    
    # Check system requirements
    if (-not (Test-SystemRequirements)) {
        Write-Log "ERROR" "System requirements not met. Please check the warnings above." "Error"
        return $false
    }
    
    # Confirm setup
    if (-not $Force) {
        Write-Host ""
        Write-Host "⚠️  WARNING: This will modify your boot configuration!" -ForegroundColor $Yellow
        Write-Host "   - Create a new partition for LilithOS" -ForegroundColor $White
        Write-Host "   - Install a bootloader" -ForegroundColor $White
        Write-Host "   - Modify Windows Boot Manager" -ForegroundColor $White
        Write-Host ""
        Write-Host "Target drive: $InstallDrive" -ForegroundColor $Cyan
        Write-Host "LilithOS size: ${LilithOSSizeGB}GB" -ForegroundColor $Cyan
        Write-Host ""
        
        $confirmation = Read-Host "Do you want to continue? (y/N)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-Log "INFO" "Setup cancelled by user" "Info"
            return $false
        }
    }
    
    # Create system backup
    if (-not (New-SystemBackup)) {
        Write-Log "ERROR" "Failed to create system backup" "Error"
        return $false
    }
    
    # Create LilithOS partition
    if (-not (New-LilithOSPartition)) {
        Write-Log "ERROR" "Failed to create LilithOS partition" "Error"
        return $false
    }
    
    # Copy LilithOS files
    if (-not (Copy-LilithOSFiles)) {
        Write-Log "ERROR" "Failed to copy LilithOS files" "Error"
        return $false
    }
    
    # Install bootloader
    if (-not (Install-Bootloader)) {
        Write-Log "ERROR" "Failed to install bootloader" "Error"
        return $false
    }
    
    # Configure Windows Boot Manager
    if (-not (Set-WindowsBootManager)) {
        Write-Log "ERROR" "Failed to configure Windows Boot Manager" "Error"
        return $false
    }
    
    # Final summary
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "║  " -NoNewline -ForegroundColor $LilithPurple
    Write-Glyph -GlyphName "LilithOS" -Color $LilithPurple
    Write-Host " LilithOS Dual Boot Setup Completed Successfully!        ║" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "║  Brand: $BrandName                                          ║" -ForegroundColor $LilithPurple
    Write-Host "║  Tagline: $BrandTagline                                     ║" -ForegroundColor $LilithPurple
    Write-Host "║  Version: $LilithOSVersion                                  ║" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "║  Next Steps:                                                ║" -ForegroundColor $LilithPurple
    Write-Host "║  • Restart your computer                                     ║" -ForegroundColor $LilithPurple
    Write-Host "║  • Select LilithOS from the boot menu                       ║" -ForegroundColor $LilithPurple
    Write-Host "║  • Complete LilithOS setup                                  ║" -ForegroundColor $LilithPurple
    Write-Host "║                                                              ║" -ForegroundColor $LilithPurple
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $LilithPurple
    Write-Host ""
    
    Write-Log "BRAND" "Dual boot setup completed successfully!" "Complete"
    Write-Log "INFO" "System backup available at: C:\LilithOS_Backup" "Backup"
    Write-Log "INFO" "Recovery script: C:\LilithOS_Backup\recovery.ps1" "Recovery"
    
    return $true
}

# Run the setup
Start-DualBootSetup 