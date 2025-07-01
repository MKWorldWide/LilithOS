# Simple WSL Switch OS Mod Testing Environment Setup
# Automated setup for testing Switch mods, CFW, and audio injection system

param(
    [switch]$FullSetup
)

Write-Host "=== WSL Switch OS Mod Testing Environment Setup ===" -ForegroundColor Magenta

# Check WSL status
Write-Host "Checking WSL status..." -ForegroundColor Cyan
$wslStatus = wsl --status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL not installed. Installing WSL..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Write-Host "Please restart your computer and run this script again." -ForegroundColor Red
    exit 1
}

# Check if Ubuntu is installed
$ubuntuInstalled = wsl -l -v | Select-String "Ubuntu"
if (-not $ubuntuInstalled) {
    Write-Host "Installing Ubuntu..." -ForegroundColor Cyan
    wsl --install -d Ubuntu
    Write-Host "Ubuntu installation started. Please complete the setup when prompted." -ForegroundColor Green
    exit 1
}

Write-Host "WSL and Ubuntu are already installed!" -ForegroundColor Green

Write-Host "=== Setup Complete ===" -ForegroundColor Magenta
Write-Host "WSL Switch testing environment is ready!" -ForegroundColor Green
Write-Host "Access WSL with: wsl" -ForegroundColor Cyan
