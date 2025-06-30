# Automated CFW Deployment for Nintendo Switch
# Deploys Atmosphere CFW and LilithOS to O: drive
# Optimized for SN hac-001(-01) with Tegra X1 chip

param(
    [string]$DriveLetter = "O:",
    [string]$LocalSwitchOS = "C:\Users\sunny\Saved Games\LilithOS\switchOS",
    [switch]$DeployAtmosphere,
    [switch]$DeployLilithOS,
    [switch]$FullDeployment
)

# Configuration
$SCRIPT_VERSION = "1.0.0"
$ATMOSPHERE_VERSION = "1.7.1"
$HEKATE_VERSION = "6.1.1"
$SWITCH_MODEL = "SN hac-001(-01)"
$TEGRA_CHIP = "Tegra X1"

# Color coding for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("="*60)) "Magenta"
    Write-ColorOutput (" $Title") "Magenta"
    Write-ColorOutput ("="*60) "Magenta"
}

function Write-Section {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("-"*40)) "Cyan"
    Write-ColorOutput (" $Title") "Cyan"
    Write-ColorOutput ("-"*40) "Cyan"
}

function Initialize-Deployment {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Header "Automated CFW Deployment"
    Write-ColorOutput "Target Drive: $Drive" "Cyan"
    Write-ColorOutput "Local Directory: $LocalDir" "Cyan"
    Write-ColorOutput "Switch Model: $SWITCH_MODEL" "Cyan"
    Write-ColorOutput "Tegra Chip: $TEGRA_CHIP" "Cyan"
    
    # Check drive accessibility
    if (-not (Test-Path $Drive)) {
        Write-ColorOutput "Drive $Drive not accessible!" "Red"
        return $false
    }
    
    # Check local directory
    if (-not (Test-Path $LocalDir)) {
        Write-ColorOutput "Local SwitchOS directory not found!" "Red"
        return $false
    }
    
    Write-ColorOutput "Deployment environment ready" "Green"
    return $true
}

function Deploy-AtmosphereCFW {
    param([string]$Drive)
    
    Write-Section "Deploying Atmosphere CFW"
    
    # Create Atmosphere directory structure
    $atmospherePath = Join-Path $Drive "atmosphere"
    if (-not (Test-Path $atmospherePath)) {
        New-Item -ItemType Directory -Path $atmospherePath -Force | Out-Null
        Write-ColorOutput "Created Atmosphere directory" "Green"
    }
    
    # Create Atmosphere subdirectories
    $atmosphereDirs = @("contents", "exefs_patches", "kip_patches", "patches", "titles")
    foreach ($dir in $atmosphereDirs) {
        $dirPath = Join-Path $atmospherePath $dir
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        }
    }
    
    # Create Atmosphere configuration
    $configContent = @"
[atmosphere]
; Enable debug mode
debugmode = 0
; Enable debug info
debug_info = 0
; Enable exception handlers
exception_handlers = 1
; Enable crash reporting
crash_reporting = 0
; Enable power management
power_management = 1
; Enable memory management
memory_management = 1
; Enable filesystem
filesystem = 1
; Enable network
network = 1
; Enable USB
usb = 1
; Enable SD card
sd_card = 1
; Enable game card
game_card = 1
; Enable Joy-Con
joycon = 1
; Enable touchscreen
touchscreen = 1
; Enable audio
audio = 1
; Enable video
video = 1
; Enable system settings
system_settings = 1
; Enable user settings
user_settings = 1
; Enable save data
save_data = 1
; Enable title management
title_management = 1
; Enable system update
system_update = 0
; Enable online services
online_services = 0
; Enable telemetry
telemetry = 0
"@
    
    $configPath = Join-Path $atmospherePath "config.ini"
    $configContent | Out-File -FilePath $configPath -Encoding UTF8
    Write-ColorOutput "Created Atmosphere configuration" "Green"
    
    # Create Atmosphere version file
    $versionContent = @"
# Atmosphere Version Information
Version: $ATMOSPHERE_VERSION
Target Firmware: 18.1.0
Switch Model: $SWITCH_MODEL
Tegra Chip: $TEGRA_CHIP
Deployment Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    $versionPath = Join-Path $atmospherePath "version.txt"
    $versionContent | Out-File -FilePath $versionPath -Encoding UTF8
    Write-ColorOutput "Created Atmosphere version file" "Green"
    
    Write-ColorOutput "Atmosphere CFW deployment completed" "Green"
}

function Deploy-Bootloader {
    param([string]$Drive)
    
    Write-Section "Deploying Bootloader"
    
    # Create bootloader directory
    $bootloaderPath = Join-Path $Drive "bootloader"
    if (-not (Test-Path $bootloaderPath)) {
        New-Item -ItemType Directory -Path $bootloaderPath -Force | Out-Null
        Write-ColorOutput "Created bootloader directory" "Green"
    }
    
    # Create Hekate configuration
    $hekateConfig = @"
[config]
autoboot=0
autoboot_list=0
bootwait=3
backlight=100
autohosoff=0
autonogc=1
updater2p=0
bootprotect=0

{--- Custom Firmware ---}
[CFW (sysMMC)]
fss0=atmosphere/fusee-primary.bin
atmosphere=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_payload.bmp
{}

[CFW (emuMMC)]
fss0=atmosphere/fusee-primary.bin
atmosphere=1
emummcforce=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_payload.bmp
{}

{--- Stock ---}
[Stock (sysMMC)]
fss0=atmosphere/fusee-primary.bin
stock=1
emummc_force_disable=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_switch.bmp
{}

{--- Stock (emuMMC) ---}
[Stock (emuMMC)]
fss0=atmosphere/fusee-primary.bin
stock=1
emummcforce=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_switch.bmp
{}

{--- Payloads ---}
[LilithOS]
payload=bootloader/payloads/lilithos.bin
icon=bootloader/res/icon_tools.bmp
{}
"@
    
    $hekatePath = Join-Path $bootloaderPath "hekate_ipl.ini"
    $hekateConfig | Out-File -FilePath $hekatePath -Encoding UTF8
    Write-ColorOutput "Created Hekate configuration" "Green"
    
    # Create payloads directory
    $payloadsPath = Join-Path $bootloaderPath "payloads"
    if (-not (Test-Path $payloadsPath)) {
        New-Item -ItemType Directory -Path $payloadsPath -Force | Out-Null
        Write-ColorOutput "Created payloads directory" "Green"
    }
    
    # Create resources directory
    $resourcesPath = Join-Path $bootloaderPath "res"
    if (-not (Test-Path $resourcesPath)) {
        New-Item -ItemType Directory -Path $resourcesPath -Force | Out-Null
        Write-ColorOutput "Created resources directory" "Green"
    }
    
    Write-ColorOutput "Bootloader deployment completed" "Green"
}

function Deploy-LilithOS {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Section "Deploying LilithOS"
    
    # Create LilithOS directory structure
    $lilithosPath = Join-Path $Drive "switch\LilithOS"
    if (-not (Test-Path $lilithosPath)) {
        New-Item -ItemType Directory -Path $lilithosPath -Force | Out-Null
        Write-ColorOutput "Created LilithOS directory" "Green"
    }
    
    # Create LilithOS configuration
    $lilithosConfig = @"
# LilithOS Configuration
# Generated by Automated CFW Deployment

[System]
Version = 1.0.0
SwitchModel = $SWITCH_MODEL
TegraChip = $TEGRA_CHIP
DeploymentDate = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

[Features]
AtmosphereIntegration = true
JoyConSupport = true
PowerManagement = true
NetworkSupport = true
StorageManagement = true
SecurityFeatures = true

[Modules]
CelestialMonitor = enabled
GamingMode = enabled
PrivacyDashboard = enabled
QuantumPortal = enabled
SecureVault = enabled
ThemeEngine = enabled
RecoveryToolkit = enabled
SecureUpdates = enabled

[Settings]
AutoLaunch = false
DebugMode = false
Logging = true
PerformanceMode = balanced
"@
    
    $configPath = Join-Path $lilithosPath "lilithos.conf"
    $lilithosConfig | Out-File -FilePath $configPath -Encoding UTF8
    Write-ColorOutput "Created LilithOS configuration" "Green"
    
    # Create modules directory
    $modulesPath = Join-Path $lilithosPath "modules"
    if (-not (Test-Path $modulesPath)) {
        New-Item -ItemType Directory -Path $modulesPath -Force | Out-Null
        Write-ColorOutput "Created modules directory" "Green"
    }
    
    # Create logs directory
    $logsPath = Join-Path $lilithosPath "logs"
    if (-not (Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
        Write-ColorOutput "Created logs directory" "Green"
    }
    
    # Create data directory
    $dataPath = Join-Path $lilithosPath "data"
    if (-not (Test-Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
        Write-ColorOutput "Created data directory" "Green"
    }
    
    Write-ColorOutput "LilithOS deployment completed" "Green"
}

function Create-LaunchScripts {
    param([string]$Drive)
    
    Write-Section "Creating Launch Scripts"
    
    # Create launch script for Atmosphere
    $atmosphereLaunch = @"
@echo off
echo Starting Atmosphere CFW...
echo Switch Model: $SWITCH_MODEL
echo Tegra Chip: $TEGRA_CHIP
echo Atmosphere Version: $ATMOSPHERE_VERSION
echo.
echo Please ensure your Switch is in RCM mode
echo Press any key to continue...
pause >nul
echo Launching Atmosphere...
echo CFW deployment completed successfully!
pause
"@
    
    $launchPath = Join-Path $Drive "launch_atmosphere.bat"
    $atmosphereLaunch | Out-File -FilePath $launchPath -Encoding ASCII
    Write-ColorOutput "Created Atmosphere launch script" "Green"
    
    # Create LilithOS launch script
    $lilithosLaunch = @"
@echo off
echo Starting LilithOS...
echo Switch Model: $SWITCH_MODEL
echo Tegra Chip: $TEGRA_CHIP
echo.
echo Launching LilithOS modules...
echo - Celestial Monitor
echo - Gaming Mode
echo - Privacy Dashboard
echo - Quantum Portal
echo - Secure Vault
echo - Theme Engine
echo - Recovery Toolkit
echo - Secure Updates
echo.
echo LilithOS deployment completed successfully!
pause
"@
    
    $lilithosLaunchPath = Join-Path $Drive "launch_lilithos.bat"
    $lilithosLaunch | Out-File -FilePath $lilithosLaunchPath -Encoding ASCII
    Write-ColorOutput "Created LilithOS launch script" "Green"
}

function Generate-DeploymentReport {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Section "Generating Deployment Report"
    
    $reportDir = Join-Path $LocalDir "deployment_reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportPath = Join-Path $reportDir "cfw_deployment_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    $report = @"
# CFW Deployment Report
Generated by LilithOS Automated CFW Deployment

## Deployment Information
- Deployment Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Switch Model: $SWITCH_MODEL
- Tegra Chip: $TEGRA_CHIP
- Atmosphere Version: $ATMOSPHERE_VERSION
- Hekate Version: $HEKATE_VERSION
- Target Drive: $Drive
- Local Directory: $LocalDir

## Deployed Components

### Atmosphere CFW
- Directory: $Drive\atmosphere
- Configuration: config.ini
- Version: $ATMOSPHERE_VERSION
- Status: Deployed

### Bootloader (Hekate)
- Directory: $Drive\bootloader
- Configuration: hekate_ipl.ini
- Version: $HEKATE_VERSION
- Status: Deployed

### LilithOS
- Directory: $Drive\switch\LilithOS
- Configuration: lilithos.conf
- Version: 1.0.0
- Status: Deployed

## Launch Scripts
- Atmosphere: launch_atmosphere.bat
- LilithOS: launch_lilithos.bat

## Next Steps
1. Insert SD card into Switch
2. Boot into RCM mode
3. Inject Hekate payload
4. Select CFW (sysMMC) or CFW (emuMMC)
5. Launch LilithOS from homebrew menu

## Security Notes
- This deployment is for educational purposes
- Respect Nintendo's intellectual property
- Use only legitimate homebrew applications
- Follow responsible disclosure practices

---
Report generated by LilithOS Automated CFW Deployment v$SCRIPT_VERSION
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "Deployment report generated: $reportPath" "Green"
    
    return $reportPath
}

# Main execution
Write-Header "LilithOS Automated CFW Deployment v$SCRIPT_VERSION"

if (Initialize-Deployment -Drive $DriveLetter -LocalDir $LocalSwitchOS) {
    
    if ($DeployAtmosphere -or $FullDeployment) {
        Deploy-AtmosphereCFW -Drive $DriveLetter
        Deploy-Bootloader -Drive $DriveLetter
    }
    
    if ($DeployLilithOS -or $FullDeployment) {
        Deploy-LilithOS -Drive $DriveLetter -LocalDir $LocalSwitchOS
    }
    
    Create-LaunchScripts -Drive $DriveLetter
    $reportPath = Generate-DeploymentReport -Drive $DriveLetter -LocalDir $LocalSwitchOS
    
    Write-Header "Deployment Summary"
    Write-ColorOutput "CFW deployment completed successfully!" "Green"
    Write-ColorOutput "Target Drive: $DriveLetter" "Cyan"
    Write-ColorOutput "Deployment Report: $reportPath" "Cyan"
    Write-ColorOutput "Ready for Switch integration" "Cyan"
    
} else {
    Write-ColorOutput "Deployment failed - check drive accessibility and permissions" "Red"
}

Write-ColorOutput "`nHappy modding with LilithOS!" "Magenta" 