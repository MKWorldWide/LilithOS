# Windows Integration Script for LilithOS
# This script handles the integration of LilithOS with Windows systems
# and sets up the C: drive access and configuration

# Configuration
$LilithOSConfig = "C:\LilithOS"
$IntegrationLog = Join-Path $LilithOSConfig "logs\integration.log"
$ErrorLog = Join-Path $LilithOSConfig "logs\error.log"

# Function to check for admin privileges
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to create necessary directories
function Setup-Directories {
    Write-Host "Creating necessary directories..." -ForegroundColor Yellow
    
    try {
        if (-not (Test-Path $LilithOSConfig)) {
            New-Item -Path $LilithOSConfig -ItemType Directory -Force | Out-Null
        }
        
        $directories = @(
            (Join-Path $LilithOSConfig "logs"),
            (Join-Path $LilithOSConfig "config")
        )
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
        }
        
        Write-Host "✓ Directories created successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating directories: $_" -ForegroundColor Red
        throw
    }
}

# Function to setup integration
function Setup-Integration {
    Write-Host "Setting up Windows integration..." -ForegroundColor Yellow
    
    try {
        # Create integration config
        $configPath = Join-Path $LilithOSConfig "config\windows-integration.conf"
        @"
# Windows Integration Configuration
WINDOWS_DRIVE=C:
AUTO_MOUNT=true
SHARE_FILES=true
"@ | Out-File -FilePath $configPath -Encoding UTF8 -Force

        # Setup file sharing
        Write-Host "Configuring file sharing..." -ForegroundColor Yellow
        $shareName = "LilithOS"
        $sharePath = "C:\"
        
        # Remove existing share if it exists
        if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
            Remove-SmbShare -Name $shareName -Force
        }
        
        # Create new share
        New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Everyone" | Out-Null
        
        Write-Host "✓ Integration setup completed" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during integration setup: $_" -ForegroundColor Red
        throw
    }
}

# Function to verify installation
function Test-Installation {
    Write-Host "Verifying installation..." -ForegroundColor Yellow
    
    $success = $true
    
    # Check directories
    if (-not (Test-Path $LilithOSConfig)) {
        Write-Host "✗ Configuration directory not found" -ForegroundColor Red
        $success = $false
    }
    
    # Check config file
    $configPath = Join-Path $LilithOSConfig "config\windows-integration.conf"
    if (-not (Test-Path $configPath)) {
        Write-Host "✗ Configuration file not found" -ForegroundColor Red
        $success = $false
    }
    
    # Check network share
    if (-not (Get-SmbShare -Name "LilithOS" -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Network share not found" -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "✓ Installation verified successfully" -ForegroundColor Green
    }
    else {
        throw "Installation verification failed"
    }
}

# Main execution
try {
    # Check for admin privileges
    if (-not (Test-Administrator)) {
        Write-Host "Error: Please run this script as Administrator" -ForegroundColor Red
        Write-Host "Right-click and select 'Run with PowerShell'" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Starting Windows integration setup..." -ForegroundColor Cyan
    
    Setup-Directories
    Setup-Integration
    Test-Installation
    
    Write-Host "`nWindows integration completed successfully!" -ForegroundColor Green
    Write-Host "Configuration location: $LilithOSConfig" -ForegroundColor Yellow
    Write-Host "Integration logs: $IntegrationLog" -ForegroundColor Yellow
    Write-Host "You can now access your C: drive at C:\" -ForegroundColor Yellow
    Write-Host "Network share available at: \\localhost\LilithOS" -ForegroundColor Yellow
}
catch {
    Write-Host "`nAn error occurred during installation" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    Write-Host "Please try running the script again as Administrator" -ForegroundColor Yellow
    exit 1
} 