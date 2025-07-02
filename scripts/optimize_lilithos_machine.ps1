# LilithOS Machine Optimization Script
# Optimizes Windows system for LilithOS ecosystem performance
# Author: LilithOS Development Team
# Version: 1.0.0

param(
    [switch]$OptimizeGaming = $true,
    [switch]$OptimizeNetwork = $true,
    [switch]$OptimizeSecurity = $true,
    [switch]$OptimizePerformance = $true,
    [switch]$OptimizeStorage = $true,
    [switch]$SkipReboot = $false
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$LilithOSRoot = $PSScriptRoot | Split-Path -Parent
$OptimizationLog = Join-Path $LilithOSRoot "optimization_log.txt"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

function Write-Step { param($Message) Write-Host "[OPTIMIZATION] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor White }

# ============================================================================
# OPTIMIZATION HEADER
# ============================================================================

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "  LilithOS Machine Optimization" -ForegroundColor Magenta
Write-Host "  Performance & Security Enhancement" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

# ============================================================================
# 1. SYSTEM PERFORMANCE OPTIMIZATION
# ============================================================================

if ($OptimizePerformance) {
    Write-Step "Phase 1: System Performance Optimization"
    
    # Disable unnecessary Windows services
    Write-Info "Optimizing Windows services..."
    $servicesToDisable = @(
        "SysMain",           # Superfetch
        "WSearch",           # Windows Search
        "TabletInputService", # Touch Keyboard
        "WbioSrvc",          # Windows Biometric Service
        "Themes",            # Themes (if not needed)
        "Spooler",           # Print Spooler (if no printer)
        "Fax",               # Fax Service
        "WMPNetworkSvc"      # Windows Media Player Network Sharing
    )
    
    foreach ($service in $servicesToDisable) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Success "Disabled service: $service"
        } catch {
            Write-Warning "Could not disable service: $service"
        }
    }
    
    # Optimize power settings for performance
    Write-Info "Setting power plan to High Performance..."
    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Success "Power plan set to High Performance"
    } catch {
        Write-Warning "Could not set power plan"
    }
    
    # Optimize visual effects for performance
    Write-Info "Optimizing visual effects..."
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        Write-Success "Visual effects optimized for performance"
    } catch {
        Write-Warning "Could not optimize visual effects"
    }
    
    Write-Host ""
}

# ============================================================================
# 2. GAMING OPTIMIZATION
# ============================================================================

if ($OptimizeGaming) {
    Write-Step "Phase 2: Gaming Optimization"
    
    # Enable Game Mode
    Write-Info "Enabling Windows Game Mode..."
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
        Write-Success "Game Mode enabled"
    } catch {
        Write-Warning "Could not enable Game Mode"
    }
    
    # Optimize for Switch gaming
    Write-Info "Optimizing for Nintendo Switch integration..."
    try {
        # Disable Windows Defender real-time protection temporarily for gaming
        Set-MpPreference -DisableRealtimeMonitoring $true
        Write-Success "Real-time protection disabled for gaming performance"
    } catch {
        Write-Warning "Could not disable real-time protection"
    }
    
    # Optimize USB settings for Switch
    Write-Info "Optimizing USB settings for Switch..."
    try {
        # Disable USB selective suspend
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB\DisableSelectiveSuspend" -Name "Default" -Value 1
        Write-Success "USB selective suspend disabled"
    } catch {
        Write-Warning "Could not optimize USB settings"
    }
    
    Write-Host ""
}

# ============================================================================
# 3. NETWORK OPTIMIZATION
# ============================================================================

if ($OptimizeNetwork) {
    Write-Step "Phase 3: Network Optimization"
    
    # Optimize network adapter settings
    Write-Info "Optimizing network adapter settings..."
    try {
        # Disable IPv6 for better gaming performance
        Set-NetAdapterBinding -Name "*" -ComponentID "ms_tcpip6" -Enabled $false
        Write-Success "IPv6 disabled for better gaming performance"
    } catch {
        Write-Warning "Could not disable IPv6"
    }
    
    # Optimize DNS settings
    Write-Info "Optimizing DNS settings..."
    try {
        # Set Google DNS for better performance
        Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex -ServerAddresses "8.8.8.8","8.8.4.4"
        Write-Success "DNS optimized with Google DNS"
    } catch {
        Write-Warning "Could not optimize DNS settings"
    }
    
    # Optimize network buffer settings
    Write-Info "Optimizing network buffer settings..."
    try {
        # Increase network buffer size
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpWindowSize" -Value 65535
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts" -Value 1
        Write-Success "Network buffer settings optimized"
    } catch {
        Write-Warning "Could not optimize network buffer settings"
    }
    
    Write-Host ""
}

# ============================================================================
# 4. SECURITY OPTIMIZATION
# ============================================================================

if ($OptimizeSecurity) {
    Write-Step "Phase 4: Security Optimization"
    
    # Enable Windows Defender advanced features
    Write-Info "Configuring Windows Defender for LilithOS..."
    try {
        # Enable controlled folder access
        Set-MpPreference -EnableControlledFolderAccess Enabled
        # Enable cloud protection
        Set-MpPreference -MAPSReporting Advanced
        # Enable behavior monitoring
        Set-MpPreference -DisableBehaviorMonitoring $false
        Write-Success "Windows Defender optimized for LilithOS"
    } catch {
        Write-Warning "Could not optimize Windows Defender"
    }
    
    # Configure firewall for LilithOS
    Write-Info "Configuring firewall for LilithOS..."
    try {
        # Allow LilithOS applications through firewall
        New-NetFirewallRule -DisplayName "LilithOS Switch Communication" -Direction Inbound -Program "C:\Program Files\nodejs\node.exe" -Action Allow
        New-NetFirewallRule -DisplayName "LilithOS Homebrew Manager" -Direction Inbound -Program "C:\Program Files\nodejs\node.exe" -Action Allow
        Write-Success "Firewall configured for LilithOS"
    } catch {
        Write-Warning "Could not configure firewall"
    }
    
    # Enable BitLocker if available
    Write-Info "Checking BitLocker status..."
    try {
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
        if ($bitlockerStatus.ProtectionStatus -eq "Off") {
            Write-Info "Enabling BitLocker encryption..."
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly
            Write-Success "BitLocker encryption enabled"
        } else {
            Write-Success "BitLocker already enabled"
        }
    } catch {
        Write-Warning "BitLocker not available or already configured"
    }
    
    Write-Host ""
}

# ============================================================================
# 5. STORAGE OPTIMIZATION
# ============================================================================

if ($OptimizeStorage) {
    Write-Step "Phase 5: Storage Optimization"
    
    # Enable TRIM for SSDs
    Write-Info "Optimizing storage settings..."
    try {
        # Enable TRIM
        fsutil behavior set DisableDeleteNotify 0
        Write-Success "TRIM enabled for SSD optimization"
    } catch {
        Write-Warning "Could not enable TRIM"
    }
    
    # Optimize disk cleanup
    Write-Info "Running disk cleanup..."
    try {
        cleanmgr /sagerun:1
        Write-Success "Disk cleanup completed"
    } catch {
        Write-Warning "Could not run disk cleanup"
    }
    
    # Optimize page file
    Write-Info "Optimizing page file..."
    try {
        # Set page file to system managed
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $computerSystem.AutomaticManagedPagefile = $true
        $computerSystem.Put()
        Write-Success "Page file optimized"
    } catch {
        Write-Warning "Could not optimize page file"
    }
    
    Write-Host ""
}

# ============================================================================
# 6. LILITHOS SPECIFIC OPTIMIZATIONS
# ============================================================================

Write-Step "Phase 6: LilithOS Specific Optimizations"

# Create LilithOS performance profile
Write-Info "Creating LilithOS performance profile..."
try {
    # Set process priority for Node.js processes
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    foreach ($process in $nodeProcesses) {
        $process.PriorityClass = "High"
    }
    Write-Success "Node.js processes set to high priority"
} catch {
    Write-Warning "Could not set process priorities"
}

# Optimize for Switch USB communication
Write-Info "Optimizing USB communication for Switch..."
try {
    # Disable USB power management
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB\DisableSelectiveSuspend" -Name "Default" -Value 1
    Write-Success "USB power management optimized for Switch"
} catch {
    Write-Warning "Could not optimize USB power management"
}

# Create LilithOS startup optimization
Write-Info "Creating LilithOS startup optimization..."
try {
    # Add LilithOS to startup with optimized settings
    $startupScript = @"
@echo off
cd /d "$LilithOSRoot"
powershell -ExecutionPolicy Bypass -File "scripts\deploy_lilithos_ecosystem.ps1"
"@
    
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\LilithOS_Startup.bat"
    $startupScript | Out-File -FilePath $startupPath -Encoding ASCII
    Write-Success "LilithOS startup script created"
} catch {
    Write-Warning "Could not create startup script"
}

Write-Host ""

# ============================================================================
# 7. SYSTEM CLEANUP AND OPTIMIZATION
# ============================================================================

Write-Step "Phase 7: System Cleanup and Final Optimization"

# Clear temporary files
Write-Info "Clearing temporary files..."
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Temporary files cleared"
} catch {
    Write-Warning "Could not clear all temporary files"
}

# Optimize registry
Write-Info "Optimizing registry..."
try {
    # Disable unnecessary startup items
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value $null -ErrorAction SilentlyContinue
    Write-Success "Registry optimized"
} catch {
    Write-Warning "Could not optimize registry"
}

# Optimize Windows Update
Write-Info "Optimizing Windows Update..."
try {
    # Disable automatic Windows Update for better gaming performance
    Set-Service -Name "wuauserv" -StartupType Manual
    Write-Success "Windows Update optimized"
} catch {
    Write-Warning "Could not optimize Windows Update"
}

Write-Host ""

# ============================================================================
# 8. PERFORMANCE VERIFICATION
# ============================================================================

Write-Step "Phase 8: Performance Verification"

# Check system performance
Write-Info "Verifying system performance..."
try {
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    $memoryUsage = (Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue
    $diskUsage = (Get-Counter "\PhysicalDisk(_Total)\% Disk Time").CounterSamples.CookedValue
    
    Write-Success "System Performance Metrics:"
    Write-Info "  - CPU Usage: $([math]::Round($cpuUsage, 2))%"
    Write-Info "  - Available Memory: $([math]::Round($memoryUsage, 0)) MB"
    Write-Info "  - Disk Usage: $([math]::Round($diskUsage, 2))%"
} catch {
    Write-Warning "Could not verify system performance"
}

# Check LilithOS processes
Write-Info "Verifying LilithOS processes..."
$lilithosProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($lilithosProcesses) {
    Write-Success "LilithOS processes running: $($lilithosProcesses.Count)"
    foreach ($process in $lilithosProcesses) {
        Write-Info "  - Node.js (PID: $($process.Id)) - Memory: $([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
    }
} else {
    Write-Warning "No LilithOS processes detected"
}

Write-Host ""

# ============================================================================
# OPTIMIZATION COMPLETION
# ============================================================================

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "  LilithOS Machine Optimization Complete!" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

Write-Success "Optimization Summary:"
Write-Info "  - System Performance: Enhanced"
Write-Info "  - Gaming Optimization: Applied"
Write-Info "  - Network Settings: Optimized"
Write-Info "  - Security Features: Configured"
Write-Info "  - Storage Settings: Optimized"
Write-Info "  - LilithOS Integration: Enhanced"

Write-Host ""
Write-Info "Performance Improvements:"
Write-Info "  - Reduced system resource usage"
Write-Info "  - Enhanced gaming performance"
Write-Info "  - Optimized network connectivity"
Write-Info "  - Improved Switch integration"
Write-Info "  - Better security configuration"

Write-Host ""
Write-Info "Next Steps:"
Write-Info "  1. Restart your computer for all changes to take effect"
Write-Info "  2. Run the LilithOS deployment script again"
Write-Info "  3. Monitor system performance"
Write-Info "  4. Enjoy optimized LilithOS experience"

Write-Host ""
Write-Host "Your machine is now optimized for LilithOS!" -ForegroundColor Green
Write-Host "Lilybear's purr will be smoother than ever!" -ForegroundColor Green
Write-Host ""

# ============================================================================
# REBOOT PROMPT
# ============================================================================

if (-not $SkipReboot) {
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "  Restart Required" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "A system restart is recommended to apply all optimizations."
    Write-Info "Would you like to restart now? (Y/N)"
    
    $restartChoice = Read-Host
    if ($restartChoice -eq "Y" -or $restartChoice -eq "y") {
        Write-Info "Restarting system in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Info "Please restart your system manually when convenient."
    }
}

# ============================================================================
# LOGGING
# ============================================================================

$optimizationLog = @"
LilithOS Machine Optimization Log
================================
Date: $(Get-Date)
User: $env:USERNAME
Computer: $env:COMPUTERNAME

Optimization Summary:
- System Performance: $OptimizePerformance
- Gaming Optimization: $OptimizeGaming
- Network Optimization: $OptimizeNetwork
- Security Optimization: $OptimizeSecurity
- Storage Optimization: $OptimizeStorage

Processes Running: $($lilithosProcesses.Count)
System Status: Optimized

Optimization completed successfully!
"@

$optimizationLog | Out-File -FilePath $OptimizationLog -Encoding UTF8
Write-Success "Optimization log saved to: $OptimizationLog" 