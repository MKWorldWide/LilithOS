# Gesture Control and Touch Screen Emulation for LilithOS
# This script enables webcam-based gesture control and touch screen emulation

# Configuration
$LilithOSConfig = "C:\LilithOS"
$GestureConfig = Join-Path $LilithOSConfig "config\gesture-control.conf"
$PythonPath = "python"
$Requirements = @"
opencv-python==4.7.0.72
mediapipe==0.9.0.1
numpy==1.23.5
pyautogui==0.9.53
PyQt6==6.4.2
scipy==1.9.3
"@

# Function to check for admin privileges
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to setup Python environment
function Setup-PythonEnvironment {
    Write-Host "Setting up Python environment..." -ForegroundColor Yellow
    
    try {
        # Create virtual environment
        $venvPath = Join-Path $LilithOSConfig "venv"
        if (-not (Test-Path $venvPath)) {
            & $PythonPath -m venv $venvPath
        }
        
        # Activate virtual environment
        $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
        . $activateScript
        
        # Install requirements
        $requirementsPath = Join-Path $LilithOSConfig "requirements.txt"
        $Requirements | Out-File -FilePath $requirementsPath -Encoding UTF8
        pip install -r $requirementsPath
        
        Write-Host "✓ Python environment setup completed" -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting up Python environment: $_" -ForegroundColor Red
        throw
    }
}

# Function to create gesture control configuration
function Setup-GestureConfig {
    Write-Host "Setting up gesture control configuration..." -ForegroundColor Yellow
    
    try {
        @"
# Gesture Control Configuration
[CAMERA]
CAMERA_INDEX=0
RESOLUTION_WIDTH=1280
RESOLUTION_HEIGHT=720
FPS=30

[CALIBRATION]
MATRIX_POINTS=9
CALIBRATION_GRID=3x3
TRANSFORMATION_MATRIX=[[1,0,0],[0,1,0],[0,0,1]]
PERSPECTIVE_CORRECTION=true

[GESTURE]
SENSITIVITY=0.7
SMOOTHING_FACTOR=0.5
GESTURE_THRESHOLD=0.3
ENABLE_TOUCH_EMULATION=true
ENABLE_GESTURE_CONTROL=true

# Gesture Mappings
GESTURE_POINT=click
GESTURE_SWIPE=scroll
GESTURE_PINCH=zoom
GESTURE_ROTATE=rotate
GESTURE_WAVE=next
GESTURE_FIST=previous
GESTURE_PALM=menu

[TOUCH]
SENSITIVITY=0.5
MULTI_TOUCH=true
TOUCH_AREA_X=0
TOUCH_AREA_Y=0
TOUCH_AREA_WIDTH=1920
TOUCH_AREA_HEIGHT=1080
TOUCH_DEADZONE=10

[ADVANCED]
ENABLE_AI_CORRECTION=true
PREDICTION_WINDOW=5
MOTION_SMOOTHING=true
GESTURE_RECOGNITION_MODE=advanced
"@ | Out-File -FilePath $GestureConfig -Encoding UTF8 -Force
        
        Write-Host "✓ Gesture control configuration created" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating gesture control configuration: $_" -ForegroundColor Red
        throw
    }
}

# Function to create configuration GUI
function Create-ConfigGUI {
    Write-Host "Creating configuration GUI..." -ForegroundColor Yellow
    
    try {
        $scriptPath = Join-Path $LilithOSConfig "config_gui.py"
        @"
import sys
import os
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                            QHBoxLayout, QLabel, QSlider, QCheckBox, QComboBox,
                            QPushButton, QTabWidget, QSpinBox, QDoubleSpinBox)
from PyQt6.QtCore import Qt
import configparser

class ConfigGUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.config = self.load_config()
        self.init_ui()
        
    def load_config(self):
        config = configparser.ConfigParser()
        config_path = os.path.join('C:', 'LilithOS', 'config', 'gesture-control.conf')
        config.read(config_path)
        return config
        
    def save_config(self):
        config_path = os.path.join('C:', 'LilithOS', 'config', 'gesture-control.conf')
        with open(config_path, 'w') as f:
            self.config.write(f)
            
    def init_ui(self):
        self.setWindowTitle('Gesture Control Configuration')
        self.setGeometry(100, 100, 800, 600)
        
        # Create tab widget
        tabs = QTabWidget()
        self.setCentralWidget(tabs)
        
        # Camera tab
        camera_tab = QWidget()
        camera_layout = QVBoxLayout()
        
        # Camera settings
        camera_layout.addWidget(QLabel('Camera Settings'))
        camera_index = QSpinBox()
        camera_index.setValue(int(self.config['CAMERA']['CAMERA_INDEX']))
        camera_layout.addWidget(QLabel('Camera Index:'))
        camera_layout.addWidget(camera_index)
        
        # Resolution
        res_layout = QHBoxLayout()
        res_layout.addWidget(QLabel('Resolution:'))
        width = QSpinBox()
        width.setValue(int(self.config['CAMERA']['RESOLUTION_WIDTH']))
        height = QSpinBox()
        height.setValue(int(self.config['CAMERA']['RESOLUTION_HEIGHT']))
        res_layout.addWidget(width)
        res_layout.addWidget(QLabel('x'))
        res_layout.addWidget(height)
        camera_layout.addLayout(res_layout)
        
        # FPS
        fps = QSpinBox()
        fps.setValue(int(self.config['CAMERA']['FPS']))
        camera_layout.addWidget(QLabel('FPS:'))
        camera_layout.addWidget(fps)
        
        camera_tab.setLayout(camera_layout)
        tabs.addTab(camera_tab, 'Camera')
        
        # Calibration tab
        calib_tab = QWidget()
        calib_layout = QVBoxLayout()
        
        # Calibration settings
        calib_layout.addWidget(QLabel('Calibration Settings'))
        
        # Matrix points
        matrix_points = QSpinBox()
        matrix_points.setValue(int(self.config['CALIBRATION']['MATRIX_POINTS']))
        calib_layout.addWidget(QLabel('Matrix Points:'))
        calib_layout.addWidget(matrix_points)
        
        # Perspective correction
        perspective = QCheckBox('Enable Perspective Correction')
        perspective.setChecked(self.config['CALIBRATION'].getboolean('PERSPECTIVE_CORRECTION'))
        calib_layout.addWidget(perspective)
        
        # Calibration button
        calibrate_btn = QPushButton('Start Calibration')
        calib_layout.addWidget(calibrate_btn)
        
        calib_tab.setLayout(calib_layout)
        tabs.addTab(calib_tab, 'Calibration')
        
        # Gesture tab
        gesture_tab = QWidget()
        gesture_layout = QVBoxLayout()
        
        # Gesture settings
        gesture_layout.addWidget(QLabel('Gesture Settings'))
        
        # Sensitivity
        sensitivity = QDoubleSpinBox()
        sensitivity.setValue(float(self.config['GESTURE']['SENSITIVITY']))
        gesture_layout.addWidget(QLabel('Sensitivity:'))
        gesture_layout.addWidget(sensitivity)
        
        # Smoothing
        smoothing = QDoubleSpinBox()
        smoothing.setValue(float(self.config['GESTURE']['SMOOTHING_FACTOR']))
        gesture_layout.addWidget(QLabel('Smoothing Factor:'))
        gesture_layout.addWidget(smoothing)
        
        # Gesture mappings
        gesture_layout.addWidget(QLabel('Gesture Mappings'))
        for gesture in ['POINT', 'SWIPE', 'PINCH', 'ROTATE', 'WAVE', 'FIST', 'PALM']:
            mapping = QComboBox()
            mapping.addItems(['click', 'scroll', 'zoom', 'rotate', 'next', 'previous', 'menu'])
            mapping.setCurrentText(self.config['GESTURE'][f'GESTURE_{gesture}'].lower())
            gesture_layout.addWidget(QLabel(f'{gesture}:'))
            gesture_layout.addWidget(mapping)
        
        gesture_tab.setLayout(gesture_layout)
        tabs.addTab(gesture_tab, 'Gestures')
        
        # Touch tab
        touch_tab = QWidget()
        touch_layout = QVBoxLayout()
        
        # Touch settings
        touch_layout.addWidget(QLabel('Touch Settings'))
        
        # Multi-touch
        multi_touch = QCheckBox('Enable Multi-touch')
        multi_touch.setChecked(self.config['TOUCH'].getboolean('MULTI_TOUCH'))
        touch_layout.addWidget(multi_touch)
        
        # Touch area
        touch_layout.addWidget(QLabel('Touch Area:'))
        area_layout = QHBoxLayout()
        for coord in ['X', 'Y', 'WIDTH', 'HEIGHT']:
            spin = QSpinBox()
            spin.setValue(int(self.config['TOUCH'][f'TOUCH_AREA_{coord}']))
            area_layout.addWidget(QLabel(coord))
            area_layout.addWidget(spin)
        touch_layout.addLayout(area_layout)
        
        touch_tab.setLayout(touch_layout)
        tabs.addTab(touch_tab, 'Touch')
        
        # Save button
        save_btn = QPushButton('Save Configuration')
        save_btn.clicked.connect(self.save_config)
        self.statusBar().addWidget(save_btn)
        
    def closeEvent(self, event):
        self.save_config()
        event.accept()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    gui = ConfigGUI()
    gui.show()
    sys.exit(app.exec())
"@ | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        
        Write-Host "✓ Configuration GUI created" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating configuration GUI: $_" -ForegroundColor Red
        throw
    }
}

# Function to create enhanced gesture control script
function Create-GestureControlScript {
    Write-Host "Creating enhanced gesture control script..." -ForegroundColor Yellow
    
    try {
        $scriptPath = Join-Path $LilithOSConfig "gesture_control.py"
        @"
import cv2
import mediapipe as mp
import numpy as np
import pyautogui
import configparser
import os
from pathlib import Path
from scipy.spatial import Delaunay
from scipy.interpolate import griddata

class GestureController:
    def __init__(self):
        self.config = self.load_config()
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        self.mp_draw = mp.solutions.drawing_utils
        self.cap = cv2.VideoCapture(int(self.config['CAMERA']['CAMERA_INDEX']))
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, int(self.config['CAMERA']['RESOLUTION_WIDTH']))
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, int(self.config['CAMERA']['RESOLUTION_HEIGHT']))
        self.cap.set(cv2.CAP_PROP_FPS, int(self.config['CAMERA']['FPS']))
        
        self.screen_width, self.screen_height = pyautogui.size()
        self.calibration_matrix = np.array(eval(self.config['CALIBRATION']['TRANSFORMATION_MATRIX']))
        self.perspective_correction = self.config['CALIBRATION'].getboolean('PERSPECTIVE_CORRECTION')
        
        # Initialize gesture tracking
        self.gesture_history = []
        self.prediction_window = int(self.config['ADVANCED']['PREDICTION_WINDOW'])
        self.motion_smoothing = self.config['ADVANCED'].getboolean('MOTION_SMOOTHING')
        
    def load_config(self):
        config = configparser.ConfigParser()
        config_path = os.path.join('C:', 'LilithOS', 'config', 'gesture-control.conf')
        config.read(config_path)
        return config
        
    def apply_calibration(self, point):
        if self.perspective_correction:
            # Apply perspective transformation
            point = np.dot(self.calibration_matrix, np.array([point[0], point[1], 1]))
            return point[:2] / point[2]
        return point
        
    def smooth_motion(self, points):
        if len(points) < 2:
            return points[-1]
        
        # Apply exponential smoothing
        alpha = float(self.config['GESTURE']['SMOOTHING_FACTOR'])
        smoothed = points[-1]
        for i in range(len(points)-2, -1, -1):
            smoothed = alpha * points[i] + (1 - alpha) * smoothed
        return smoothed
        
    def predict_motion(self, points):
        if len(points) < self.prediction_window:
            return points[-1]
            
        # Simple linear prediction
        velocities = np.diff(points, axis=0)
        avg_velocity = np.mean(velocities[-self.prediction_window:], axis=0)
        return points[-1] + avg_velocity
        
    def process_gestures(self):
        while True:
            success, img = self.cap.read()
            if not success:
                break
                
            img = cv2.flip(img, 1)
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            results = self.hands.process(img_rgb)
            
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Draw hand landmarks
                    self.mp_draw.draw_landmarks(
                        img, hand_landmarks, self.mp_hands.HAND_CONNECTIONS)
                    
                    # Process gestures with enhanced tracking
                    self.process_hand_gesture(hand_landmarks)
            
            # Display calibration grid if enabled
            if self.perspective_correction:
                self.draw_calibration_grid(img)
            
            # Display FPS and status
            cv2.putText(img, f"FPS: {self.cap.get(cv2.CAP_PROP_FPS):.1f}",
                       (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
            cv2.imshow("Gesture Control", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
                
        self.cleanup()
        
    def process_hand_gesture(self, landmarks):
        # Get all finger tips
        finger_tips = [8, 12, 16, 20]  # Index, middle, ring, pinky
        current_points = []
        
        for tip in finger_tips:
            finger = landmarks.landmark[tip]
            x, y = int(finger.x * self.screen_width), int(finger.y * self.screen_height)
            point = self.apply_calibration([x, y])
            current_points.append(point)
            
        # Update gesture history
        self.gesture_history.append(current_points)
        if len(self.gesture_history) > self.prediction_window:
            self.gesture_history.pop(0)
            
        # Apply motion smoothing and prediction
        if self.motion_smoothing:
            smoothed_points = [self.smooth_motion([p[i] for p in self.gesture_history])
                             for i in range(len(current_points))]
            predicted_points = [self.predict_motion([p[i] for p in self.gesture_history])
                              for i in range(len(current_points))]
            
            # Use predicted points for more responsive control
            current_points = predicted_points
            
        # Process gestures based on finger positions
        self.process_gesture_commands(current_points, landmarks)
            
    def process_gesture_commands(self, points, landmarks):
        # Get gesture type based on finger positions
        gesture = self.recognize_gesture(landmarks)
        
        # Map gesture to action
        action = self.config['GESTURE'][f'GESTURE_{gesture}'].lower()
        
        # Execute action
        if action == 'click':
            pyautogui.click()
        elif action == 'scroll':
            # Calculate scroll direction and amount
            direction = np.mean([p[1] - points[0][1] for p in points[1:]])
            pyautogui.scroll(int(direction * 100))
        elif action == 'zoom':
            # Calculate zoom factor based on finger distance
            distance = np.linalg.norm(np.array(points[0]) - np.array(points[1]))
            pyautogui.hotkey('ctrl', '+' if distance > 100 else '-')
        elif action == 'rotate':
            # Calculate rotation angle
            angle = np.arctan2(points[1][1] - points[0][1],
                             points[1][0] - points[0][0])
            pyautogui.hotkey('ctrl', 'r')
            
    def recognize_gesture(self, landmarks):
        # Enhanced gesture recognition
        thumb_tip = landmarks.landmark[4]
        index_tip = landmarks.landmark[8]
        middle_tip = landmarks.landmark[12]
        
        # Calculate distances and angles
        thumb_index_dist = np.linalg.norm(
            np.array([thumb_tip.x, thumb_tip.y]) -
            np.array([index_tip.x, index_tip.y]))
            
        # Determine gesture type
        if thumb_index_dist < 0.1:
            return 'FIST'
        elif thumb_tip.y < index_tip.y:
            return 'PALM'
        elif middle_tip.y < index_tip.y:
            return 'WAVE'
        else:
            return 'POINT'
            
    def draw_calibration_grid(self, img):
        # Draw 3x3 calibration grid
        h, w = img.shape[:2]
        for i in range(1, 3):
            cv2.line(img, (0, i*h//3), (w, i*h//3), (0, 255, 0), 1)
            cv2.line(img, (i*w//3, 0), (i*w//3, h), (0, 255, 0), 1)
            
    def cleanup(self):
        self.cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    controller = GestureController()
    controller.process_gestures()
"@ | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        
        Write-Host "✓ Enhanced gesture control script created" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating gesture control script: $_" -ForegroundColor Red
        throw
    }
}

# Function to create enhanced touch screen script
function Create-TouchScreenScript {
    Write-Host "Creating enhanced touch screen script..." -ForegroundColor Yellow
    
    try {
        $scriptPath = Join-Path $LilithOSConfig "touch_screen.py"
        @"
import cv2
import mediapipe as mp
import numpy as np
import pyautogui
import configparser
import os
from pathlib import Path
from scipy.spatial import Delaunay
from scipy.interpolate import griddata

class TouchScreenEmulator:
    def __init__(self):
        self.config = self.load_config()
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        self.mp_draw = mp.solutions.drawing_utils
        self.cap = cv2.VideoCapture(int(self.config['CAMERA']['CAMERA_INDEX']))
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, int(self.config['CAMERA']['RESOLUTION_WIDTH']))
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, int(self.config['CAMERA']['RESOLUTION_HEIGHT']))
        self.cap.set(cv2.CAP_PROP_FPS, int(self.config['CAMERA']['FPS']))
        
        self.screen_width, self.screen_height = pyautogui.size()
        self.calibration_matrix = np.array(eval(self.config['CALIBRATION']['TRANSFORMATION_MATRIX']))
        self.perspective_correction = self.config['CALIBRATION'].getboolean('PERSPECTIVE_CORRECTION')
        
        # Initialize touch tracking
        self.touch_points = []
        self.touch_history = []
        self.deadzone = int(self.config['TOUCH']['TOUCH_DEADZONE'])
        
    def load_config(self):
        config = configparser.ConfigParser()
        config_path = os.path.join('C:', 'LilithOS', 'config', 'gesture-control.conf')
        config.read(config_path)
        return config
        
    def apply_calibration(self, point):
        if self.perspective_correction:
            # Apply perspective transformation
            point = np.dot(self.calibration_matrix, np.array([point[0], point[1], 1]))
            return point[:2] / point[2]
        return point
        
    def process_touch(self):
        while True:
            success, img = self.cap.read()
            if not success:
                break
                
            img = cv2.flip(img, 1)
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            results = self.hands.process(img_rgb)
            
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Draw hand landmarks
                    self.mp_draw.draw_landmarks(
                        img, hand_landmarks, self.mp_hands.HAND_CONNECTIONS)
                    
                    # Process touch gestures
                    self.process_touch_gesture(hand_landmarks)
            
            # Display touch area
            self.draw_touch_area(img)
            
            # Display calibration grid if enabled
            if self.perspective_correction:
                self.draw_calibration_grid(img)
            
            cv2.imshow("Touch Screen Emulation", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
                
        self.cleanup()
        
    def process_touch_gesture(self, landmarks):
        # Get all finger tips
        finger_tips = [8, 12, 16, 20]  # Index, middle, ring, pinky
        current_points = []
        
        for tip in finger_tips:
            finger = landmarks.landmark[tip]
            x, y = int(finger.x * self.screen_width), int(finger.y * self.screen_height)
            point = self.apply_calibration([x, y])
            
            # Check if point is in touch area
            if (self.config['TOUCH'].getint('TOUCH_AREA_X') <= x <= 
                self.config['TOUCH'].getint('TOUCH_AREA_X') + 
                self.config['TOUCH'].getint('TOUCH_AREA_WIDTH') and
                self.config['TOUCH'].getint('TOUCH_AREA_Y') <= y <= 
                self.config['TOUCH'].getint('TOUCH_AREA_Y') + 
                self.config['TOUCH'].getint('TOUCH_AREA_HEIGHT')):
                
                current_points.append(point)
                
        # Update touch history
        self.touch_history.append(current_points)
        if len(self.touch_history) > 5:
            self.touch_history.pop(0)
            
        # Process touch points
        self.process_touch_points(current_points)
            
    def process_touch_points(self, points):
        # Handle multi-touch if enabled
        if self.config['TOUCH'].getboolean('MULTI_TOUCH'):
            for point in points:
                # Check for movement in deadzone
                if not any(np.linalg.norm(np.array(point) - np.array(p)) < self.deadzone 
                          for p in self.touch_points):
                    # Move to new position
                    pyautogui.moveTo(int(point[0]), int(point[1]))
                    pyautogui.mouseDown()
                    self.touch_points.append(point)
        else:
            # Single touch mode
            if points:
                point = points[0]
                if not any(np.linalg.norm(np.array(point) - np.array(p)) < self.deadzone 
                          for p in self.touch_points):
                    pyautogui.moveTo(int(point[0]), int(point[1]))
                    pyautogui.mouseDown()
                    self.touch_points = [point]
                    
        # Release touch if no points
        if not points:
            pyautogui.mouseUp()
            self.touch_points = []
            
    def draw_touch_area(self, img):
        # Draw touch area rectangle
        cv2.rectangle(img,
                     (self.config['TOUCH'].getint('TOUCH_AREA_X'),
                      self.config['TOUCH'].getint('TOUCH_AREA_Y')),
                     (self.config['TOUCH'].getint('TOUCH_AREA_X') +
                      self.config['TOUCH'].getint('TOUCH_AREA_WIDTH'),
                      self.config['TOUCH'].getint('TOUCH_AREA_Y') +
                      self.config['TOUCH'].getint('TOUCH_AREA_HEIGHT')),
                     (0, 255, 0), 2)
                     
    def draw_calibration_grid(self, img):
        # Draw 3x3 calibration grid
        h, w = img.shape[:2]
        for i in range(1, 3):
            cv2.line(img, (0, i*h//3), (w, i*h//3), (0, 255, 0), 1)
            cv2.line(img, (i*w//3, 0), (i*w//3, h), (0, 255, 0), 1)
            
    def cleanup(self):
        self.cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    emulator = TouchScreenEmulator()
    emulator.process_touch()
"@ | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        
        Write-Host "✓ Enhanced touch screen script created" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating touch screen script: $_" -ForegroundColor Red
        throw
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
    
    Write-Host "Starting enhanced gesture control setup..." -ForegroundColor Cyan
    
    Setup-PythonEnvironment
    Setup-GestureConfig
    Create-ConfigGUI
    Create-GestureControlScript
    Create-TouchScreenScript
    
    Write-Host "`nEnhanced gesture control setup completed successfully!" -ForegroundColor Green
    Write-Host "To start the system:" -ForegroundColor Yellow
    Write-Host "1. Configure settings:" -ForegroundColor Yellow
    Write-Host "   python C:\LilithOS\config_gui.py" -ForegroundColor Yellow
    Write-Host "2. Start gesture control:" -ForegroundColor Yellow
    Write-Host "   python C:\LilithOS\gesture_control.py" -ForegroundColor Yellow
    Write-Host "3. Start touch screen emulation:" -ForegroundColor Yellow
    Write-Host "   python C:\LilithOS\touch_screen.py" -ForegroundColor Yellow
    Write-Host "`nPress 'q' to quit any application" -ForegroundColor Yellow
}
catch {
    Write-Host "`nAn error occurred during setup" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    Write-Host "Please try running the script again as Administrator" -ForegroundColor Yellow
    exit 1
} 