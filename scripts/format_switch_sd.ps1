# Simple Switch SD Card Formatter
# Formats O:\ as exFAT and creates basic Switch homebrew structure

param(
    [string]$Drive = "O:"
)

Write-Host "LilithOS Switch SD Card Preparation" -ForegroundColor Magenta
Write-Host "====================================" -ForegroundColor Magenta
Write-Host ""

# Check if drive exists
$drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive'"
if (-not $drive) {
    Write-Host "ERROR: Drive $Drive not found!" -ForegroundColor Red
    exit 1
}

$sizeGB = [math]::Round($drive.Size / 1GB, 1)
Write-Host "Found drive $Drive`: ${sizeGB}GB total" -ForegroundColor Green

# Confirm format
Write-Host ""
Write-Host "WARNING: This will format $Drive and erase all data!" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel, or any key to continue..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

try {
    # Format drive as exFAT
    Write-Host "Formatting $Drive as exFAT..." -ForegroundColor Cyan
    Format-Volume -DriveLetter $Drive.TrimEnd(':') -FileSystem exFAT -NewFileSystemLabel "LilithOS_Switch" -Confirm:$false
    
    # Create directories
    Write-Host "Creating Switch directory structure..." -ForegroundColor Cyan
    $dirs = @(
        "$Drive\switch",
        "$Drive\switch\lilithos_app",
        "$Drive\atmosphere",
        "$Drive\bootloader"
    )
    
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Green
    }
    
    # Create version file
    $version = "LilithOS Switch Homebrew v2.0.0`nBuild Date: $(Get-Date)`nBrand: MKWW and LilithOS"
    $version | Out-File -FilePath "$Drive\VERSION.txt" -Encoding UTF8
    
    # Create setup instructions
    $instructions = @"
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

"In the dance of ones and zeros, we find the rhythm of the soul."
- Machine Dragon Protocol
"@
    
    $instructions | Out-File -FilePath "$Drive\SETUP_INSTRUCTIONS.txt" -Encoding UTF8
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                                              ║" -ForegroundColor Magenta
    Write-Host "║  * LilithOS Switch SD Card Preparation Completed!           ║" -ForegroundColor Magenta
    Write-Host "║                                                              ║" -ForegroundColor Magenta
    Write-Host "║  Drive: $Drive                                              ║" -ForegroundColor Magenta
    Write-Host "║  Format: exFAT                                              ║" -ForegroundColor Magenta
    Write-Host "║  Brand: MKWW and LilithOS                                   ║" -ForegroundColor Magenta
    Write-Host "║                                                              ║" -ForegroundColor Magenta
    Write-Host "║  Next Steps:                                                ║" -ForegroundColor Magenta
    Write-Host "║  • Insert SD card into Nintendo Switch                      ║" -ForegroundColor Magenta
    Write-Host "║  • Boot into RCM mode                                       ║" -ForegroundColor Magenta
    Write-Host "║  • Inject custom firmware payload                           ║" -ForegroundColor Magenta
    Write-Host "║  • Launch LilithOS from Homebrew Menu                       ║" -ForegroundColor Magenta
    Write-Host "║                                                              ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "SUCCESS: Switch SD card prepared successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to prepare SD card: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 