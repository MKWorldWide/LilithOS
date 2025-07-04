#!/bin/bash
# Optimized Unity Integration Launcher for LilithOS
# Incorporates 3DS R4 updates and focuses on efficiency

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
LILITHOS_ROOT="$(dirname "$(dirname "$(dirname "$MODULE_DIR")")")"

# Unity integration settings
UNITY_ENGINE_PY="$SCRIPT_DIR/unity_optimized_engine.py"
UNITY_GUI_PY="$SCRIPT_DIR/unity_gui.py"
UNITY_VISUAL_ENGINE_PY="$SCRIPT_DIR/unity_visual_engine.py"

# Performance monitoring
PERFORMANCE_LOG="$SCRIPT_DIR/performance.log"
INTEGRATION_LOG="$SCRIPT_DIR/integration.log"

# 3DS R4 integration paths
R4_PATH="$HOME/Saved Games/3DS R4"
R4_INTEGRATION_PATH="$R4_PATH/LilithOS_Integration_Engine"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  LilithOS Unity Integration${NC}"
    echo -e "${CYAN}  Optimized for Efficiency${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is required but not installed"
        exit 1
    fi
    
    # Check required Python packages
    local required_packages=("psutil" "yaml" "asyncio")
    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" 2>/dev/null; then
            print_warning "Python package '$package' not found, installing..."
            pip3 install "$package"
        fi
    done
    
    print_status "Dependencies check completed"
}

# Function to initialize Unity integration
initialize_unity_integration() {
    print_status "Initializing Unity integration..."
    
    # Create logs directory
    mkdir -p "$(dirname "$PERFORMANCE_LOG")"
    mkdir -p "$(dirname "$INTEGRATION_LOG")"
    
    # Initialize performance monitoring
    echo "$(date): Unity integration initialized" >> "$PERFORMANCE_LOG"
    
    # Check for Unity installations
    if python3 -c "
import sys
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine
engine = OptimizedUnityEngine()
version = engine.get_latest_unity_version()
print('Unity found:', version['version'] if version else 'None')
" 2>/dev/null; then
        print_status "Unity integration initialized successfully"
    else
        print_warning "Unity integration initialization failed"
    fi
}

# Function to load 3DS R4 integration data
load_3ds_r4_integration() {
    print_status "Loading 3DS R4 integration data..."
    
    if [ -d "$R4_PATH" ]; then
        print_status "3DS R4 directory found: $R4_PATH"
        
        # Check for integration engine
        if [ -d "$R4_INTEGRATION_PATH" ]; then
            print_status "LilithOS Integration Engine found"
            
            # Load integration report
            if [ -f "$R4_INTEGRATION_PATH/FINAL_INTEGRATION_REPORT.md" ]; then
                print_status "Loading integration report..."
                echo "$(date): 3DS R4 integration loaded" >> "$INTEGRATION_LOG"
            fi
            
            # Load configuration
            if [ -f "$R4_INTEGRATION_PATH/lilithos-test-config.ini" ]; then
                print_status "Loading TWiLight Menu++ configuration..."
            fi
        else
            print_warning "LilithOS Integration Engine not found in 3DS R4"
        fi
    else
        print_warning "3DS R4 directory not found: $R4_PATH"
    fi
}

# Function to start performance monitoring
start_performance_monitoring() {
    print_status "Starting performance monitoring..."
    
    # Start background performance monitoring
    python3 -c "
import sys
import time
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

engine = OptimizedUnityEngine()
while True:
    metrics = engine.monitor_performance()
    report = engine.get_performance_report()
    print(f'FPS: {metrics.fps:.2f}, Memory: {metrics.memory_usage:.2f}%, CPU: {metrics.cpu_usage:.2f}%')
    time.sleep(5)
" > "$PERFORMANCE_LOG" 2>&1 &
    
    PERFORMANCE_PID=$!
    echo $PERFORMANCE_PID > "$SCRIPT_DIR/performance.pid"
    
    print_status "Performance monitoring started (PID: $PERFORMANCE_PID)"
}

# Function to stop performance monitoring
stop_performance_monitoring() {
    if [ -f "$SCRIPT_DIR/performance.pid" ]; then
        local pid=$(cat "$SCRIPT_DIR/performance.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            print_status "Performance monitoring stopped"
        fi
        rm -f "$SCRIPT_DIR/performance.pid"
    fi
}

# Function to launch Unity GUI
launch_unity_gui() {
    print_status "Launching Unity integration GUI..."
    
    # Check if GUI file exists
    if [ -f "$UNITY_GUI_PY" ]; then
        print_status "Starting Unity GUI..."
        python3 "$UNITY_GUI_PY" &
        GUI_PID=$!
        echo $GUI_PID > "$SCRIPT_DIR/gui.pid"
        print_status "Unity GUI started (PID: $GUI_PID)"
    else
        print_error "Unity GUI file not found: $UNITY_GUI_PY"
        print_status "Falling back to command-line interface..."
        launch_command_line_interface
    fi
}

# Function to launch command-line interface
launch_command_line_interface() {
    print_status "Launching command-line interface..."
    
    python3 -c "
import sys
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

print('=== LilithOS Unity Integration CLI ===')
engine = OptimizedUnityEngine()

# Display Unity status
unity_version = engine.get_latest_unity_version()
if unity_version:
    print(f'Unity Version: {unity_version[\"version\"]}')
    print(f'Performance Score: {unity_version.get(\"performance_score\", 0):.2f}')
else:
    print('No Unity installation found')

# Display 3DS R4 integration status
print(f'3DS Integration: {engine.integration_settings.get(\"enable_3ds_support\", False)}')
print(f'Supported Platforms: {engine.integration_settings.get(\"supported_platforms\", [])}')

# Display performance metrics
metrics = engine.monitor_performance()
print(f'Current FPS: {metrics.fps:.2f}')
print(f'Memory Usage: {metrics.memory_usage:.2f}%')
print(f'CPU Usage: {metrics.cpu_usage:.2f}%')

# Display performance report
report = engine.get_performance_report()
print(f'Average FPS: {report[\"averages\"][\"fps\"]:.2f}')
print(f'System CPU Count: {report[\"system_info\"][\"cpu_count\"]}')

print('=== CLI Ready ===')
print('Commands:')
print('  status - Show current status')
print('  performance - Show performance metrics')
print('  create-project <name> <path> - Create new Unity project')
print('  launch-unity - Launch Unity with current project')
print('  exit - Exit CLI')
"
}

# Function to create Unity project
create_unity_project() {
    local project_name="$1"
    local project_path="$2"
    
    if [ -z "$project_name" ] || [ -z "$project_path" ]; then
        print_error "Usage: create-project <name> <path>"
        return 1
    fi
    
    print_status "Creating Unity project: $project_name at $project_path"
    
    python3 -c "
import sys
import asyncio
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

async def create_project():
    engine = OptimizedUnityEngine()
    try:
        project_settings = await engine.create_optimized_project('$project_name', '$project_path')
        print(f'Project created successfully: {project_settings}')
    except Exception as e:
        print(f'Error creating project: {e}')

asyncio.run(create_project())
"
}

# Function to launch Unity
launch_unity() {
    print_status "Launching Unity..."
    
    python3 -c "
import sys
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

engine = OptimizedUnityEngine()
if engine.current_project:
    success = engine.launch_unity_project(engine.current_project)
    if success:
        print('Unity launched successfully')
    else:
        print('Failed to launch Unity')
else:
    print('No project selected')
"
}

# Function to show status
show_status() {
    print_status "Current Unity integration status:"
    
    python3 -c "
import sys
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

engine = OptimizedUnityEngine()

print('Unity Versions:')
for version in engine.unity_versions:
    print(f'  - {version[\"version\"]} (Score: {version.get(\"performance_score\", 0):.2f})')

print('\\n3DS R4 Integration:')
for key, value in engine.integration_settings.items():
    print(f'  - {key}: {value}')

print('\\nPerformance Settings:')
for key, value in engine.performance_settings.items():
    print(f'  - {key}: {value}')

print('\\nLifelike Visual Settings:')
for key, value in list(engine.lifelike_visual_settings.items())[:10]:  # Show first 10
    print(f'  - {key}: {value}')
"
}

# Function to show performance metrics
show_performance() {
    print_status "Current performance metrics:"
    
    python3 -c "
import sys
sys.path.append('$SCRIPT_DIR')
from unity_optimized_engine import OptimizedUnityEngine

engine = OptimizedUnityEngine()
metrics = engine.monitor_performance()
report = engine.get_performance_report()

print(f'Current FPS: {metrics.fps:.2f}')
print(f'Memory Usage: {metrics.memory_usage:.2f}%')
print(f'CPU Usage: {metrics.cpu_usage:.2f}%')
print(f'GPU Usage: {metrics.gpu_usage:.2f}%')
print(f'Render Time: {metrics.render_time:.2f}ms')
print(f'Load Time: {metrics.load_time:.2f}s')

print('\\nAverages:')
print(f'  FPS: {report[\"averages\"][\"fps\"]:.2f}')
print(f'  Memory: {report[\"averages\"][\"memory_usage\"]:.2f}%')
print(f'  CPU: {report[\"averages\"][\"cpu_usage\"]:.2f}%')

print('\\nSystem Info:')
print(f'  CPU Count: {report[\"system_info\"][\"cpu_count\"]}')
print(f'  Total Memory: {report[\"system_info\"][\"memory_total\"] / (1024**3):.2f} GB')
print(f'  Unity Versions: {report[\"system_info\"][\"unity_versions\"]}')
"
}

# Function to handle cleanup
cleanup() {
    print_status "Cleaning up..."
    stop_performance_monitoring
    
    # Stop GUI if running
    if [ -f "$SCRIPT_DIR/gui.pid" ]; then
        local pid=$(cat "$SCRIPT_DIR/gui.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            print_status "GUI stopped"
        fi
        rm -f "$SCRIPT_DIR/gui.pid"
    fi
    
    print_status "Cleanup completed"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  gui              Launch Unity integration GUI"
    echo "  cli              Launch command-line interface"
    echo "  status           Show current status"
    echo "  performance      Show performance metrics"
    echo "  create-project   Create new Unity project"
    echo "  launch-unity     Launch Unity"
    echo "  monitor          Start performance monitoring"
    echo "  stop-monitor     Stop performance monitoring"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 gui                    # Launch GUI"
    echo "  $0 cli                    # Launch CLI"
    echo "  $0 create-project MyProject ./projects"
    echo "  $0 monitor               # Start monitoring"
}

# Main execution
main() {
    print_header
    
    # Set up signal handlers
    trap cleanup EXIT
    trap 'print_error "Interrupted"; exit 1' INT TERM
    
    # Check dependencies
    check_dependencies
    
    # Initialize Unity integration
    initialize_unity_integration
    
    # Load 3DS R4 integration
    load_3ds_r4_integration
    
    # Parse command line arguments
    case "${1:-gui}" in
        "gui")
            start_performance_monitoring
            launch_unity_gui
            wait
            ;;
        "cli")
            start_performance_monitoring
            launch_command_line_interface
            ;;
        "status")
            show_status
            ;;
        "performance")
            show_performance
            ;;
        "create-project")
            create_unity_project "$2" "$3"
            ;;
        "launch-unity")
            launch_unity
            ;;
        "monitor")
            start_performance_monitoring
            print_status "Performance monitoring started"
            ;;
        "stop-monitor")
            stop_performance_monitoring
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 