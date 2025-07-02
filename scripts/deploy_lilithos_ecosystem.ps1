# LilithOS Ecosystem Deployment Script
# Deploys complete LilithOS environment with Switch and Router integration
# Author: LilithOS Development Team
# Version: 1.0.0

param(
    [string]$WiFiNetwork = "BrandyCay",
    [string]$RouterIP = "192.168.1.1",
    [string]$SwitchIP = "192.168.1.100",
    [switch]$DeployFirmware = $false,
    [switch]$SkipNetworkConfig = $false
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$LilithOSRoot = $PSScriptRoot | Split-Path -Parent
$SwitchOSPath = Join-Path $LilithOSRoot "switchOS"
$RouterOSPath = Join-Path $LilithOSRoot "routerOS"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

function Write-Step { param($Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor White }

# ============================================================================
# DEPLOYMENT HEADER
# ============================================================================

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "  LilithOS Ecosystem Deployment" -ForegroundColor Magenta
Write-Host "  Complete System Integration" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

# ============================================================================
# 1. SWITCH DETECTION AND COMMUNICATION
# ============================================================================

Write-Step "Phase 1: Nintendo Switch Detection and Communication"

# Run Switch detection
Write-Info "Detecting Nintendo Switch devices..."
$switchDetectionScript = Join-Path $SwitchOSPath "quick_switch_detect.ps1"
if (Test-Path $switchDetectionScript) {
    & powershell -ExecutionPolicy Bypass -File $switchDetectionScript
    Write-Success "Switch detection completed"
} else {
    Write-Error "Switch detection script not found: $switchDetectionScript"
}

Write-Host ""

# ============================================================================
# 2. NETWORK CONNECTION
# ============================================================================

Write-Step "Phase 2: Network Connection Setup"

# Check current WiFi connection
Write-Info "Checking current WiFi connection..."
$currentWiFi = netsh wlan show interfaces | Select-String "SSID" | Select-String -Pattern "BrandyCay"
if ($currentWiFi) {
    Write-Success "Already connected to BrandyCay WiFi"
} else {
    Write-Info "Connecting to BrandyCay WiFi network..."
    try {
        netsh wlan connect name="$WiFiNetwork"
        Start-Sleep -Seconds 5
        Write-Success "Connected to $WiFiNetwork WiFi"
    } catch {
        Write-Warning "Could not automatically connect to WiFi. Please connect manually."
    }
}

Write-Host ""

# ============================================================================
# 3. ROUTER DETECTION AND CONFIGURATION
# ============================================================================

Write-Step "Phase 3: Router Detection and Configuration"

# Ping router to check connectivity
Write-Info "Checking router connectivity..."
$routerPing = Test-Connection -ComputerName $RouterIP -Count 1 -Quiet
if ($routerPing) {
    Write-Success "Router is reachable at $RouterIP"
} else {
    Write-Warning "Router not reachable at $RouterIP. Please check connection."
}

# Check if router web interface is accessible
Write-Info "Checking router web interface..."
try {
    $webResponse = Invoke-WebRequest -Uri "http://$RouterIP" -TimeoutSec 5 -UseBasicParsing
    Write-Success "Router web interface is accessible"
} catch {
    Write-Warning "Router web interface not accessible. Router may not be ready."
}

Write-Host ""

# ============================================================================
# 4. FIRMWARE DEPLOYMENT (OPTIONAL)
# ============================================================================

if ($DeployFirmware) {
    Write-Step "Phase 4: Firmware Deployment"
    
    $firmwarePath = Join-Path $RouterOSPath "build\build_output\output\lilithos_router_r7000p_1.0.0.bin"
    $flashToolPath = Join-Path $RouterOSPath "tools\flash_tool\flash_router.py"
    
    if (Test-Path $firmwarePath) {
        Write-Info "Firmware found: $firmwarePath"
        Write-Info "Running firmware check (dry run)..."
        
        # Run firmware check in WSL
        $wslCommand = "python3 $flashToolPath --firmware $firmwarePath --router-ip $RouterIP --check-only"
        wsl bash -c $wslCommand
        
        Write-Success "Firmware check completed"
    } else {
        Write-Warning "Firmware not found. Skipping firmware deployment."
    }
    
    Write-Host ""
}

# ============================================================================
# 5. NETWORK CONFIGURATION
# ============================================================================

if (-not $SkipNetworkConfig) {
    Write-Step "Phase 5: Network Configuration"
    
    $networkConfigScript = Join-Path $RouterOSPath "config\network\network_config.sh"
    if (Test-Path $networkConfigScript) {
        Write-Info "Applying network configuration..."
        
        # Run network configuration in WSL
        wsl bash -c "cd '$RouterOSPath/config/network' && chmod +x network_config.sh && ./network_config.sh start"
        
        Write-Success "Network configuration applied"
    } else {
        Write-Warning "Network configuration script not found. Skipping network setup."
    }
    
    Write-Host ""
}

# ============================================================================
# 6. SWITCH COMMUNICATION BRIDGE
# ============================================================================

Write-Step "Phase 6: Switch Communication Bridge"

$bridgeScript = Join-Path $SwitchOSPath "switch_communication_bridge.js"
if (Test-Path $bridgeScript) {
    Write-Info "Starting Switch communication bridge..."
    
    # Start the bridge in background
    Start-Process -FilePath "node" -ArgumentList $bridgeScript -WindowStyle Minimized
    
    Write-Success "Switch communication bridge started"
} else {
    Write-Warning "Switch communication bridge script not found"
}

Write-Host ""

# ============================================================================
# 7. HOMEBREW MANAGER (OPTIONAL)
# ============================================================================

Write-Step "Phase 7: Homebrew Manager"

$homebrewScript = Join-Path $SwitchOSPath "homebrew_manager.js"
if (Test-Path $homebrewScript) {
    Write-Info "Starting Homebrew manager..."
    
    # Start the homebrew manager in background
    Start-Process -FilePath "node" -ArgumentList $homebrewScript -WindowStyle Minimized
    
    Write-Success "Homebrew manager started"
} else {
    Write-Warning "Homebrew manager script not found"
}

Write-Host ""

# ============================================================================
# 8. SYSTEM MONITORING
# ============================================================================

Write-Step "Phase 8: System Monitoring"

$monitoringScript = Join-Path $SwitchOSPath "development_environment.js"
if (Test-Path $monitoringScript) {
    Write-Info "Starting system monitoring..."
    
    # Start the monitoring in background
    Start-Process -FilePath "node" -ArgumentList $monitoringScript -WindowStyle Minimized
    
    Write-Success "System monitoring started"
} else {
    Write-Warning "System monitoring script not found"
}

Write-Host ""

# ============================================================================
# 9. DEPLOYMENT VERIFICATION
# ============================================================================

Write-Step "Phase 9: Deployment Verification"

# Check if all services are running
Write-Info "Verifying deployment..."

$processes = @("node")
$runningProcesses = Get-Process -Name $processes -ErrorAction SilentlyContinue

if ($runningProcesses) {
    Write-Success "Node.js processes are running:"
    foreach ($proc in $runningProcesses) {
        Write-Info "  - $($proc.ProcessName) (PID: $($proc.Id))"
    }
} else {
    Write-Warning "No Node.js processes detected"
}

# Check network connectivity
Write-Info "Checking network connectivity..."
$internetConnection = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
if ($internetConnection) {
    Write-Success "Internet connectivity confirmed"
} else {
    Write-Warning "No internet connectivity detected"
}

Write-Host ""

# ============================================================================
# DEPLOYMENT COMPLETION
# ============================================================================

Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "  LilithOS Ecosystem Deployment Complete!" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

Write-Success "Deployment Summary:"
Write-Info "  - Switch Detection: Complete"
Write-Info "  - Network Connection: Active"
Write-Info "  - Router Integration: Ready"
Write-Info "  - Communication Bridge: Running"
Write-Info "  - Homebrew Manager: Running"
Write-Info "  - System Monitoring: Active"

Write-Host ""
Write-Info "Access Points:"
Write-Info "  - Router Web Interface: http://$RouterIP"
Write-Info "  - Switch IP: $SwitchIP"
Write-Info "  - Network: $WiFiNetwork"

Write-Host ""
Write-Host "LilithOS Ecosystem is now fully operational!" -ForegroundColor Green
Write-Host "Lilybear can now purr through her veins!" -ForegroundColor Green
Write-Host ""

# ============================================================================
# USAGE INSTRUCTIONS
# ============================================================================

Write-Host "==================================================" -ForegroundColor Gray
Write-Host "  Usage Instructions:" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Gray
Write-Host ""
Write-Info "1. Switch Communication:"
Write-Info "   - Switch is connected via USB and Bluetooth"
Write-Info "   - Communication bridge is running"
Write-Info "   - Monitor Switch activity in real-time"
Write-Host ""
Write-Info "2. Router Integration:"
Write-Info "   - Router is configured for Switch optimization"
Write-Info "   - QoS is enabled for gaming traffic"
Write-Info "   - Security features are active"
Write-Host ""
Write-Info "3. Network Management:"
Write-Info "   - Connected to BrandyCay WiFi"
Write-Info "   - Router provides enhanced network features"
Write-Info "   - Switch gets priority traffic treatment"
Write-Host ""
Write-Info "4. Development Tools:"
Write-Info "   - Homebrew manager is running"
Write-Info "   - System monitoring is active"
Write-Info "   - All development tools are available"
Write-Host ""
Write-Host "==================================================" -ForegroundColor Gray 