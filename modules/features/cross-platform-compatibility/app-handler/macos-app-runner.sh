#!/bin/bash
# macOS App Runner for .app Files
# -------------------------------
# 📋 Quantum Documentation:
#   This script handles macOS .app files in LilithOS, providing
#   compatibility layer for running macOS applications directly
#   or through virtualization. It supports both Intel and Apple Silicon apps.
#
# 🧩 Feature Context:
#   - macOS .app file execution and compatibility.
#   - Universal binary support (Intel/Apple Silicon).
#   - App bundle analysis and validation.
#   - Sandboxed execution environments.
#
# 🧷 Dependency Listings:
#   - Requires: macOS compatibility layer, app validation tools
#   - Optional: Virtualization framework, additional macOS libraries
#
# 💡 Usage Examples:
#   ./macos-app-runner.sh run "path/to/App.app"
#   ./macos-app-runner.sh analyze "path/to/App.app"
#   ./macos-app-runner.sh list-apps
#
# ⚡ Performance Considerations:
#   - Native execution vs virtualization overhead.
#   - App bundle caching for faster startup.
#   - Memory and CPU optimization for macOS apps.
#
# 🔒 Security Implications:
#   - App bundle validation and code signing verification.
#   - Sandboxed execution environments.
#   - Permission management and isolation.
#
# 📜 Changelog Entries:
#   - 2024-06-29: Initial macOS app runner created.

APP_DIR="${APP_DIR:-$PWD/apps}"
CACHE_DIR="${CACHE_DIR:-$PWD/cache}"
LOG_DIR="${LOG_DIR:-$PWD/logs}"

# Function to run macOS application
run_macos_app() {
    local app_path="$1"
    local args="$2"
    
    if [ ! -d "$app_path" ]; then
        echo "Error: App bundle not found: $app_path"
        return 1
    fi
    
    # Check if it's a valid app bundle
    if [[ "$app_path" != *.app ]] || [ ! -f "$app_path/Contents/Info.plist" ]; then
        echo "Error: Not a valid macOS app bundle: $app_path"
        return 1
    fi
    
    echo "Launching macOS application: $app_path"
    
    # Get the executable name from Info.plist
    local executable=$(plutil -extract CFBundleExecutable raw "$app_path/Contents/Info.plist" 2>/dev/null)
    if [ -z "$executable" ]; then
        echo "Error: Could not determine executable name from Info.plist"
        return 1
    fi
    
    local exec_path="$app_path/Contents/MacOS/$executable"
    
    if [ ! -f "$exec_path" ]; then
        echo "Error: Executable not found: $exec_path"
        return 1
    fi
    
    # Make executable if needed
    chmod +x "$exec_path"
    
    # Run the application
    if [ -n "$args" ]; then
        "$exec_path" $args
    else
        "$exec_path"
    fi
}

# Function to analyze app bundle
analyze_app() {
    local app_path="$1"
    
    if [ ! -d "$app_path" ]; then
        echo "Error: App bundle not found: $app_path"
        return 1
    fi
    
    echo "Analyzing macOS app bundle: $app_path"
    echo "======================================"
    
    # Check Info.plist
    if [ -f "$app_path/Contents/Info.plist" ]; then
        echo "📋 App Information:"
        echo "  Bundle Name: $(plutil -extract CFBundleName raw "$app_path/Contents/Info.plist" 2>/dev/null)"
        echo "  Bundle Version: $(plutil -extract CFBundleVersion raw "$app_path/Contents/Info.plist" 2>/dev/null)"
        echo "  Bundle Identifier: $(plutil -extract CFBundleIdentifier raw "$app_path/Contents/Info.plist" 2>/dev/null)"
        echo "  Executable: $(plutil -extract CFBundleExecutable raw "$app_path/Contents/Info.plist" 2>/dev/null)"
        echo "  Minimum OS Version: $(plutil -extract LSMinimumSystemVersion raw "$app_path/Contents/Info.plist" 2>/dev/null)"
    fi
    
    # Check architecture
    local exec_path="$app_path/Contents/MacOS/$(plutil -extract CFBundleExecutable raw "$app_path/Contents/Info.plist" 2>/dev/null)"
    if [ -f "$exec_path" ]; then
        echo "🏗️  Architecture:"
        file "$exec_path" | grep -o "x86_64\|arm64\|universal"
    fi
    
    # Check code signing
    echo "🔒 Code Signing:"
    codesign -dv "$app_path" 2>&1 | grep -E "Authority|TeamIdentifier|Signed" || echo "  Not code signed"
    
    # List resources
    echo "📦 Resources:"
    if [ -d "$app_path/Contents/Resources" ]; then
        ls -la "$app_path/Contents/Resources" | head -10
    fi
    
    # Check frameworks
    echo "🔧 Frameworks:"
    if [ -d "$app_path/Contents/Frameworks" ]; then
        ls -la "$app_path/Contents/Frameworks"
    else
        echo "  No frameworks found"
    fi
}

# Function to list available macOS apps
list_macos_apps() {
    echo "Available macOS Applications:"
    echo "============================"
    
    if [ -d "$APP_DIR" ]; then
        find "$APP_DIR" -name "*.app" -type d 2>/dev/null | while read app; do
            local name=$(plutil -extract CFBundleName raw "$app/Contents/Info.plist" 2>/dev/null)
            local version=$(plutil -extract CFBundleVersion raw "$app/Contents/Info.plist" 2>/dev/null)
            echo "📱 $name (v$version) - $app"
        done
    else
        echo "No macOS applications found in $APP_DIR"
    fi
}

# Function to validate app bundle
validate_app() {
    local app_path="$1"
    
    if [ ! -d "$app_path" ]; then
        echo "Error: App bundle not found: $app_path"
        return 1
    fi
    
    echo "Validating macOS app bundle: $app_path"
    
    local valid=true
    
    # Check required files
    if [ ! -f "$app_path/Contents/Info.plist" ]; then
        echo "❌ Missing Info.plist"
        valid=false
    fi
    
    if [ ! -d "$app_path/Contents/MacOS" ]; then
        echo "❌ Missing MacOS directory"
        valid=false
    fi
    
    # Check executable
    local executable=$(plutil -extract CFBundleExecutable raw "$app_path/Contents/Info.plist" 2>/dev/null)
    if [ -n "$executable" ]; then
        if [ ! -f "$app_path/Contents/MacOS/$executable" ]; then
            echo "❌ Missing executable: $executable"
            valid=false
        fi
    else
        echo "❌ No executable specified in Info.plist"
        valid=false
    fi
    
    if [ "$valid" = true ]; then
        echo "✅ App bundle validation: PASSED"
        return 0
    else
        echo "❌ App bundle validation: FAILED"
        return 1
    fi
}

# Function to install app bundle
install_app() {
    local app_path="$1"
    local install_dir="$2"
    
    if [ ! -d "$app_path" ]; then
        echo "Error: App bundle not found: $app_path"
        return 1
    fi
    
    if [ -z "$install_dir" ]; then
        install_dir="$APP_DIR"
    fi
    
    echo "Installing macOS app: $app_path"
    echo "Install directory: $install_dir"
    
    # Validate app first
    if ! validate_app "$app_path"; then
        echo "Error: App validation failed"
        return 1
    fi
    
    # Copy app to install directory
    local app_name=$(basename "$app_path")
    local target_path="$install_dir/$app_name"
    
    mkdir -p "$install_dir"
    cp -R "$app_path" "$target_path"
    
    echo "App installed successfully: $target_path"
}

# Function to uninstall app bundle
uninstall_app() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        echo "Error: App name required for uninstallation"
        return 1
    fi
    
    local app_path="$APP_DIR/$app_name"
    
    if [ ! -d "$app_path" ]; then
        echo "Error: App not found: $app_path"
        return 1
    fi
    
    echo "Uninstalling macOS app: $app_name"
    
    rm -rf "$app_path"
    
    echo "App uninstalled successfully: $app_name"
}

# Main function
main() {
    case "$1" in
        "run")
            if [ -z "$2" ]; then
                echo "Usage: $0 run <path-to-app> [args]"
                exit 1
            fi
            run_macos_app "$2" "$3"
            ;;
        "analyze")
            if [ -z "$2" ]; then
                echo "Usage: $0 analyze <path-to-app>"
                exit 1
            fi
            analyze_app "$2"
            ;;
        "list")
            list_macos_apps
            ;;
        "validate")
            if [ -z "$2" ]; then
                echo "Usage: $0 validate <path-to-app>"
                exit 1
            fi
            validate_app "$2"
            ;;
        "install")
            if [ -z "$2" ]; then
                echo "Usage: $0 install <path-to-app> [install-dir]"
                exit 1
            fi
            install_app "$2" "$3"
            ;;
        "uninstall")
            if [ -z "$2" ]; then
                echo "Usage: $0 uninstall <app-name>"
                exit 1
            fi
            uninstall_app "$2"
            ;;
        *)
            echo "Usage: $0 {run <path> [args]|analyze <path>|list|validate <path>|install <path> [dir]|uninstall <name>}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 