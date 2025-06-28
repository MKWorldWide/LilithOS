# Install dependencies for gesture control system
Write-Host "Installing dependencies..." -ForegroundColor Cyan

# Activate virtual environment
$venvPath = "C:\LilithOS\venv"
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"

if (-not (Test-Path $venvPath)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv $venvPath
}

# Activate virtual environment
. $activateScript

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies one by one
Write-Host "Installing OpenCV..." -ForegroundColor Yellow
pip install opencv-python==4.7.0.72

Write-Host "Installing MediaPipe..." -ForegroundColor Yellow
pip install mediapipe==0.9.0.1

Write-Host "Installing NumPy..." -ForegroundColor Yellow
pip install numpy==1.23.5

Write-Host "Installing PyAutoGUI..." -ForegroundColor Yellow
pip install pyautogui==0.9.53

Write-Host "Installing PyQt6..." -ForegroundColor Yellow
pip install PyQt6==6.4.2

Write-Host "Installing SciPy..." -ForegroundColor Yellow
pip install scipy==1.9.3

Write-Host "`nDependencies installed successfully!" -ForegroundColor Green
Write-Host "You can now run the gesture control system using:" -ForegroundColor Yellow
Write-Host ".\scripts\start-gesture-control.ps1" -ForegroundColor Yellow 