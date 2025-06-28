@echo off
echo Installing dependencies...

REM Create and activate virtual environment
if not exist "C:\LilithOS\venv" (
    echo Creating virtual environment...
    python -m venv C:\LilithOS\venv
)

REM Activate virtual environment and install packages
call C:\LilithOS\venv\Scripts\activate.bat

REM Upgrade pip
python -m pip install --upgrade pip

REM Install dependencies
echo Installing OpenCV...
pip install --only-binary :all: opencv-python==4.7.0.72

echo Installing MediaPipe...
pip install --only-binary :all: mediapipe==0.9.0.1

echo Installing NumPy...
pip install --only-binary :all: numpy==1.23.5

echo Installing PyAutoGUI...
pip install --only-binary :all: pyautogui==0.9.53

echo Installing PyQt6...
pip install --only-binary :all: PyQt6==6.4.2

echo Installing SciPy...
pip install --only-binary :all: scipy==1.9.3

echo.
echo Dependencies installed successfully!
echo You can now run the gesture control system using:
echo .\scripts\start-gesture-control.ps1

pause 