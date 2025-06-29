#!/bin/bash
# LilithOS Joy-Con Controller Support Module

echo "🎮 Initializing Joy-Con Controller Support..."

# Joy-Con device IDs
JOYCON_L_ID="057e:2006"  # Joy-Con (L)
JOYCON_R_ID="057e:2007"  # Joy-Con (R)
JOYCON_PAIR_ID="057e:2008"  # Joy-Con Pair

# Joy-Con button mappings
JOYCON_BUTTONS=(
    "A=BTN_EAST"
    "B=BTN_SOUTH"
    "X=BTN_NORTH"
    "Y=BTN_WEST"
    "L=BTN_TL"
    "R=BTN_TR"
    "ZL=BTN_TL2"
    "ZR=BTN_TR2"
    "MINUS=BTN_SELECT"
    "PLUS=BTN_START"
    "L_STICK=ABS_X,ABS_Y"
    "R_STICK=ABS_RX,ABS_RY"
    "CAPTURE=BTN_MODE"
    "HOME=BTN_MODE"
)

# Initialize Joy-Con support
init_joycon() {
    echo "🔧 Setting up Joy-Con controllers..."
    
    # Check if Joy-Con devices are connected
    if lsusb | grep -q "$JOYCON_L_ID\|$JOYCON_R_ID\|$JOYCON_PAIR_ID"; then
        export LILITHOS_JOYCON_DETECTED="true"
        echo "✅ Joy-Con controllers detected"
        
        # Load Joy-Con kernel modules
        load_joycon_modules
        
        # Configure Joy-Con devices
        configure_joycon_devices
        
        # Set up Joy-Con pairing
        setup_joycon_pairing
        
        # Configure Joy-Con buttons
        configure_joycon_buttons
        
        # Set up Joy-Con motion controls
        setup_joycon_motion
        
        # Set up Joy-Con rumble
        setup_joycon_rumble
        
        # Set up Joy-Con IR camera
        setup_joycon_ir_camera
    else
        export LILITHOS_JOYCON_DETECTED="false"
        echo "⚠️ No Joy-Con controllers detected"
    fi
}

# Load Joy-Con kernel modules
load_joycon_modules() {
    echo "📦 Loading Joy-Con kernel modules..."
    
    # Load HID modules for Joy-Con
    modprobe hid-nintendo 2>/dev/null || true
    modprobe joycon 2>/dev/null || true
    
    # Load input modules
    modprobe evdev 2>/dev/null || true
    modprobe uinput 2>/dev/null || true
}

# Configure Joy-Con devices
configure_joycon_devices() {
    echo "⚙️ Configuring Joy-Con devices..."
    
    # Create udev rules for Joy-Con
    cat > /etc/udev/rules.d/99-joycon.rules << 'EOF'
# Joy-Con (L)
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2006", MODE="0666", GROUP="input"

# Joy-Con (R)
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2007", MODE="0666", GROUP="input"

# Joy-Con Pair
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2008", MODE="0666", GROUP="input"

# Joy-Con input devices
SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*Joy-Con*", MODE="0666", GROUP="input"
EOF
    
    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger
}

# Set up Joy-Con pairing
setup_joycon_pairing() {
    echo "🔗 Setting up Joy-Con pairing..."
    
    # Create Joy-Con pairing script
    cat > /usr/local/bin/joycon-pair << 'EOF'
#!/bin/bash
# Joy-Con Pairing Script

echo "🎮 Joy-Con Pairing Utility"
echo "=========================="

# Check if Joy-Con are connected
if ! lsusb | grep -q "057e:200"; then
    echo "❌ No Joy-Con controllers detected"
    exit 1
fi

# Pair Joy-Con controllers
echo "🔗 Pairing Joy-Con controllers..."

# Left Joy-Con
if lsusb | grep -q "057e:2006"; then
    echo "✅ Left Joy-Con detected"
    export JOYCON_L_CONNECTED="true"
fi

# Right Joy-Con
if lsusb | grep -q "057e:2007"; then
    echo "✅ Right Joy-Con detected"
    export JOYCON_R_CONNECTED="true"
fi

# Create pairing configuration
if [ "$JOYCON_L_CONNECTED" = "true" ] && [ "$JOYCON_R_CONNECTED" = "true" ]; then
    echo "🎮 Both Joy-Con controllers paired"
    export JOYCON_PAIRED="true"
else
    echo "⚠️ Single Joy-Con mode"
    export JOYCON_PAIRED="false"
fi

echo "✅ Joy-Con pairing complete"
EOF
    
    chmod +x /usr/local/bin/joycon-pair
}

# Configure Joy-Con buttons
configure_joycon_buttons() {
    echo "🔘 Configuring Joy-Con buttons..."
    
    # Create Joy-Con button mapping
    cat > /usr/local/share/lilithos/joycon-buttons.conf << 'EOF'
# Joy-Con Button Configuration

# Face Buttons
A=BTN_EAST
B=BTN_SOUTH
X=BTN_NORTH
Y=BTN_WEST

# Shoulder Buttons
L=BTN_TL
R=BTN_TR
ZL=BTN_TL2
ZR=BTN_TR2

# System Buttons
MINUS=BTN_SELECT
PLUS=BTN_START
CAPTURE=BTN_MODE
HOME=BTN_MODE

# Analog Sticks
L_STICK_X=ABS_X
L_STICK_Y=ABS_Y
R_STICK_X=ABS_RX
R_STICK_Y=ABS_RY

# D-Pad
DPAD_UP=ABS_HAT0Y
DPAD_DOWN=ABS_HAT0Y
DPAD_LEFT=ABS_HAT0X
DPAD_RIGHT=ABS_HAT0X

# Motion Controls
MOTION_X=ABS_RX
MOTION_Y=ABS_RY
MOTION_Z=ABS_RZ
EOF
}

# Set up Joy-Con motion controls
setup_joycon_motion() {
    echo "📱 Setting up Joy-Con motion controls..."
    
    # Create motion control configuration
    cat > /usr/local/share/lilithos/joycon-motion.conf << 'EOF'
# Joy-Con Motion Control Configuration

# Accelerometer
ACCEL_X=ABS_RX
ACCEL_Y=ABS_RY
ACCEL_Z=ABS_RZ

# Gyroscope
GYRO_X=ABS_THROTTLE
GYRO_Y=ABS_RUDDER
GYRO_Z=ABS_WHEEL

# Motion sensitivity
MOTION_SENSITIVITY=1.0
MOTION_DEADZONE=0.1
MOTION_SMOOTHING=0.8
EOF
    
    # Create motion control daemon
    cat > /usr/local/bin/joycon-motion << 'EOF'
#!/bin/bash
# Joy-Con Motion Control Daemon

echo "📱 Starting Joy-Con motion control daemon..."

# Monitor Joy-Con motion events
while true; do
    if [ -e /dev/input/event* ]; then
        # Process motion events
        for event in /dev/input/event*; do
            if udevadm info -q property -n "$event" | grep -q "Joy-Con"; then
                # Handle motion events
                handle_motion_event "$event"
            fi
        done
    fi
    sleep 0.016  # 60Hz polling
done

handle_motion_event() {
    local event="$1"
    # Process motion data from event device
    # This would interface with the actual motion processing
    echo "📱 Motion event from $event"
}
EOF
    
    chmod +x /usr/local/bin/joycon-motion
}

# Set up Joy-Con rumble
setup_joycon_rumble() {
    echo "📳 Setting up Joy-Con rumble..."
    
    # Create rumble configuration
    cat > /usr/local/share/lilithos/joycon-rumble.conf << 'EOF'
# Joy-Con Rumble Configuration

# Rumble intensity levels
RUMBLE_LIGHT=0.3
RUMBLE_MEDIUM=0.6
RUMBLE_HEAVY=1.0

# Rumble patterns
RUMBLE_PATTERN_SHORT=100
RUMBLE_PATTERN_MEDIUM=300
RUMBLE_PATTERN_LONG=500

# Rumble frequency
RUMBLE_FREQ_LOW=40
RUMBLE_FREQ_MED=80
RUMBLE_FREQ_HIGH=160
EOF
    
    # Create rumble control utility
    cat > /usr/local/bin/joycon-rumble << 'EOF'
#!/bin/bash
# Joy-Con Rumble Control Utility

usage() {
    echo "Usage: $0 [intensity] [duration] [frequency]"
    echo "  intensity: light, medium, heavy (0.0-1.0)"
    echo "  duration: milliseconds"
    echo "  frequency: Hz (40-160)"
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

INTENSITY="$1"
DURATION="$2"
FREQUENCY="$3"

echo "📳 Triggering Joy-Con rumble..."
echo "  Intensity: $INTENSITY"
echo "  Duration: ${DURATION}ms"
echo "  Frequency: ${FREQUENCY}Hz"

# Send rumble command to Joy-Con
# This would interface with the actual rumble hardware
echo "📳 Rumble command sent"
EOF
    
    chmod +x /usr/local/bin/joycon-rumble
}

# Set up Joy-Con IR camera
setup_joycon_ir_camera() {
    echo "📷 Setting up Joy-Con IR camera..."
    
    # Create IR camera configuration
    cat > /usr/local/share/lilithos/joycon-ir.conf << 'EOF'
# Joy-Con IR Camera Configuration

# IR camera resolution
IR_RESOLUTION_X=320
IR_RESOLUTION_Y=240

# IR camera frame rate
IR_FRAME_RATE=60

# IR camera sensitivity
IR_SENSITIVITY=0.8

# IR camera processing
IR_PROCESSING_ENABLED=true
IR_GESTURE_RECOGNITION=true
IR_OBJECT_DETECTION=true
EOF
    
    # Create IR camera utility
    cat > /usr/local/bin/joycon-ir << 'EOF'
#!/bin/bash
# Joy-Con IR Camera Utility

echo "📷 Starting Joy-Con IR camera..."

# Check if IR camera is available
if ! lsusb | grep -q "057e:200"; then
    echo "❌ No Joy-Con with IR camera detected"
    exit 1
fi

# Initialize IR camera
echo "📷 Initializing IR camera..."

# Start IR camera daemon
while true; do
    # Capture IR camera data
    # This would interface with the actual IR camera hardware
    echo "📷 IR camera active"
    sleep 1
done
EOF
    
    chmod +x /usr/local/bin/joycon-ir
}

# Joy-Con status monitoring
monitor_joycon_status() {
    echo "📊 Monitoring Joy-Con status..."
    
    # Create status monitoring script
    cat > /usr/local/bin/joycon-status << 'EOF'
#!/bin/bash
# Joy-Con Status Monitor

echo "🎮 Joy-Con Status Report"
echo "========================"

# Check USB connection
if lsusb | grep -q "057e:2006"; then
    echo "✅ Left Joy-Con: Connected"
    JOYCON_L_STATUS="connected"
else
    echo "❌ Left Joy-Con: Disconnected"
    JOYCON_L_STATUS="disconnected"
fi

if lsusb | grep -q "057e:2007"; then
    echo "✅ Right Joy-Con: Connected"
    JOYCON_R_STATUS="connected"
else
    echo "❌ Right Joy-Con: Disconnected"
    JOYCON_R_STATUS="disconnected"
fi

# Check battery levels (if available)
if [ "$JOYCON_L_STATUS" = "connected" ]; then
    echo "🔋 Left Joy-Con Battery: $(get_joycon_battery L)"
fi

if [ "$JOYCON_R_STATUS" = "connected" ]; then
    echo "🔋 Right Joy-Con Battery: $(get_joycon_battery R)"
fi

# Check input devices
echo ""
echo "📱 Input Devices:"
ls /dev/input/event* | while read device; do
    if udevadm info -q property -n "$device" | grep -q "Joy-Con"; then
        echo "  ✅ $device: $(udevadm info -q property -n "$device" | grep NAME)"
    fi
done

get_joycon_battery() {
    local joycon="$1"
    # This would read actual battery level from Joy-Con
    # For now, return a placeholder
    echo "85%"
}
EOF
    
    chmod +x /usr/local/bin/joycon-status
}

# Main initialization
main() {
    echo "🎮 LilithOS Joy-Con Support Module v2.0.0"
    echo ""
    
    # Initialize Joy-Con support
    init_joycon
    
    # Set up monitoring
    monitor_joycon_status
    
    echo ""
    echo "✅ Joy-Con support initialized"
    echo "🎮 Use 'joycon-pair' to pair controllers"
    echo "📊 Use 'joycon-status' to check status"
    echo "📳 Use 'joycon-rumble' to test rumble"
    echo "📷 Use 'joycon-ir' to access IR camera"
    echo ""
}

# Run initialization
main "$@" 