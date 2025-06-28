# Launcher script for gesture control and touch screen emulation
# This script provides an easy way to start and manage the gesture control system

# Configuration
$LilithOSConfig = "C:\LilithOS"
$VenvPath = Join-Path $LilithOSConfig "venv"
$GestureControlScript = Join-Path $LilithOSConfig "gesture_control.py"
$TouchScreenScript = Join-Path $LilithOSConfig "touch_screen.py"
$ConfigGUIScript = Join-Path $LilithOSConfig "config_gui.py"

# Function to check Python environment
function Test-PythonEnvironment {
    $activateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
    if (-not (Test-Path $activateScript)) {
        Write-Host "Error: Python environment not found" -ForegroundColor Red
        Write-Host "Please run the setup script first: .\scripts\gesture-control.ps1" -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Function to start gesture control
function Start-GestureControl {
    Write-Host "Starting gesture control..." -ForegroundColor Cyan
    try {
        Start-Process python -ArgumentList $GestureControlScript -NoNewWindow
        Write-Host "✓ Gesture control started" -ForegroundColor Green
    }
    catch {
        Write-Host "Error starting gesture control: $_" -ForegroundColor Red
    }
}

# Function to start touch screen emulation
function Start-TouchScreen {
    Write-Host "Starting touch screen emulation..." -ForegroundColor Cyan
    try {
        Start-Process python -ArgumentList $TouchScreenScript -NoNewWindow
        Write-Host "✓ Touch screen emulation started" -ForegroundColor Green
    }
    catch {
        Write-Host "Error starting touch screen emulation: $_" -ForegroundColor Red
    }
}

# Function to start configuration GUI
function Start-ConfigGUI {
    Write-Host "Starting configuration GUI..." -ForegroundColor Cyan
    try {
        Start-Process python -ArgumentList $ConfigGUIScript -NoNewWindow
        Write-Host "✓ Configuration GUI started" -ForegroundColor Green
    }
    catch {
        Write-Host "Error starting configuration GUI: $_" -ForegroundColor Red
    }
}

# Main execution
try {
    # Check Python environment
    if (-not (Test-PythonEnvironment)) {
        exit 1
    }
    
    # Activate virtual environment
    $activateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
    . $activateScript
    
    # Display menu
    while ($true) {
        Write-Host "`nGesture Control System" -ForegroundColor Cyan
        Write-Host "1. Start Gesture Control" -ForegroundColor Yellow
        Write-Host "2. Start Touch Screen Emulation" -ForegroundColor Yellow
        Write-Host "3. Start Both" -ForegroundColor Yellow
        Write-Host "4. Open Configuration GUI" -ForegroundColor Yellow
        Write-Host "5. Exit" -ForegroundColor Yellow
        
        $choice = Read-Host "`nEnter your choice (1-5)"
        
        switch ($choice) {
            "1" { Start-GestureControl }
            "2" { Start-TouchScreen }
            "3" { 
                Start-GestureControl
                Start-TouchScreen
            }
            "4" { Start-ConfigGUI }
            "5" { 
                Write-Host "Exiting..." -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            }
        }
    }
}
catch {
    Write-Host "`nAn error occurred" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    exit 1
} 