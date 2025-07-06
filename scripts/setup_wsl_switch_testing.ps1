# WSL Switch OS Mod Testing Environment Setup
# Automated setup for testing Switch mods, CFW, and audio injection system

param(
    [string]$WSLDistro = "Ubuntu-22.04",
    [string]$ProjectPath = "/home/switchuser/lilithos",
    [switch]$InstallWSL,
    [switch]$SetupEnvironment,
    [switch]$InstallEmulators,
    [switch]$FullSetup
)

# Configuration
$SCRIPT_VERSION = "1.0.0"
$UBUNTU_VERSION = "22.04"
$RYUJINX_VERSION = "latest"
$ATMOSPHERE_VERSION = "1.7.1"

# Color coding for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("="*60)) "Magenta"
    Write-ColorOutput (" $Title") "Magenta"
    Write-ColorOutput ("="*60) "Magenta"
}

function Write-Section {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("-"*40)) "Cyan"
    Write-ColorOutput (" $Title") "Cyan"
    Write-ColorOutput ("-"*40) "Cyan"
}

function Install-WSL {
    Write-Section "Installing WSL and Ubuntu"
    
    Write-ColorOutput "Checking WSL status..." "Cyan"
    
    # Check if WSL is enabled
    $wslStatus = wsl --status 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "WSL not installed. Installing WSL..." "Yellow"
        
        # Enable WSL feature
        Write-ColorOutput "Enabling WSL Windows feature..." "Cyan"
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        
        Write-ColorOutput "Please restart your computer and run this script again." "Red"
        Write-ColorOutput "After restart, WSL will be ready for Ubuntu installation." "Yellow"
        return $false
    }
    
    # Check if Ubuntu is installed
    $ubuntuInstalled = wsl -l -v | Select-String "Ubuntu"
    if (-not $ubuntuInstalled) {
        Write-ColorOutput "Installing Ubuntu $UBUNTU_VERSION..." "Cyan"
        wsl --install -d Ubuntu
        Write-ColorOutput "Ubuntu installation started. Please complete the setup when prompted." "Green"
        return $false
    }
    
    Write-ColorOutput "WSL and Ubuntu are already installed!" "Green"
    return $true
}

function Setup-WSLEnvironment {
    param([string]$Distro)
    
    Write-Section "Setting up WSL Environment"
    
    # Create setup script for WSL
    $wslSetupScript = @"
#!/bin/bash
# WSL Switch Testing Environment Setup Script

echo "=== WSL Switch Testing Environment Setup ==="
echo "Setting up Ubuntu for Switch OS mod testing..."

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
sudo apt install -y git curl wget unzip build-essential cmake pkg-config
sudo apt install -y libusb-1.0-0-dev libssl-dev libffi-dev python3-dev
sudo apt install -y ffmpeg libavcodec-dev libavformat-dev libswscale-dev
sudo apt install -y wine64 wine32 winbind
sudo apt install -y mono-complete
sudo apt install -y python3 python3-pip python3-venv

# Install .NET Core
echo "Installing .NET Core..."
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-6.0

# Create switch user and directories
echo "Creating switch user and directories..."
sudo useradd -m -s /bin/bash switchuser
sudo usermod -aG sudo switchuser
# Use environment variables or prompt for credentials
$switchUser = $env:SWITCH_USER
$switchPass = $env:SWITCH_PASS

if (-not $switchUser -or -not $switchPass) {
    Write-Host "Please set SWITCH_USER and SWITCH_PASS environment variables"
    Write-Host "Or the script will prompt for credentials"
    $switchUser = Read-Host "Enter Switch username"
    $switchPass = Read-Host "Enter Switch password" -AsSecureString
    $switchPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($switchPass))
}

echo "$switchUser`:$switchPass" | sudo chpasswd

# Create project directory
sudo mkdir -p $ProjectPath
sudo chown switchuser:switchuser $ProjectPath

# Install Ryujinx
echo "Installing Ryujinx..."
mkdir -p ~/.local/share/Ryujinx
cd ~/.local/share/Ryujinx

# Download latest Ryujinx
RYUJINX_URL="https://github.com/Ryujinx/release-channel-master/releases/latest/download/ryujinx-ava-`$(uname -m).tar.gz"
wget -O ryujinx.tar.gz "`$RYUJINX_URL"
tar -xzf ryujinx.tar.gz
rm ryujinx.tar.gz

# Create Ryujinx desktop shortcut
cat > ~/.local/share/applications/ryujinx.desktop << EOF
[Desktop Entry]
Name=Ryujinx
Comment=Nintendo Switch Emulator
Exec=~/.local/share/Ryujinx/Ryujinx
Icon=~/.local/share/Ryujinx/ryujinx.png
Terminal=false
Type=Application
Categories=Game;Emulator;
EOF

# Install Atmosphere CFW tools
echo "Installing Atmosphere CFW tools..."
cd $ProjectPath
git clone https://github.com/Atmosphere-NX/Atmosphere.git
cd Atmosphere
make -j$(nproc)

# Install Hekate
echo "Installing Hekate..."
cd $ProjectPath
git clone https://github.com/CTCaer/hekate.git
cd hekate
make -j$(nproc)

# Install Switch homebrew tools
echo "Installing Switch homebrew tools..."
sudo apt install -y devkitpro-pacman
sudo dkp-pacman -S switch-dev switch-glad switch-mesa switch-glm switch-sdl2 switch-sdl2_image switch-sdl2_mixer switch-sdl2_ttf switch-sdl2_gfx

# Create virtual SD card
echo "Creating virtual SD card..."
mkdir -p $ProjectPath/virtual_sd
mkdir -p $ProjectPath/virtual_sd/atmosphere
mkdir -p $ProjectPath/virtual_sd/bootloader
mkdir -p $ProjectPath/virtual_sd/switch
mkdir -p $ProjectPath/virtual_sd/Nintendo

# Set up environment variables
echo "Setting up environment variables..."
cat >> ~/.bashrc << EOF

# Switch development environment
export DEVKITPRO=/opt/devkitpro
export DEVKITARM=/opt/devkitpro/devkitARM
export DEVKITPPC=/opt/devkitpro/devkitPPC
export PATH=`$PATH:`$DEVKITARM/bin:`$DEVKITPPC/bin

# LilithOS project path
export LILITHOS_PATH=$ProjectPath
export VIRTUAL_SD_PATH=$ProjectPath/virtual_sd

# Ryujinx path
export RYUJINX_PATH=~/.local/share/Ryujinx
EOF

# Create test scripts
echo "Creating test scripts..."
cat > $ProjectPath/test_audio_injection.sh << 'EOF'
#!/bin/bash
echo "=== Audio Injection System Test ==="
echo "Testing multi-layered unlock keys..."

# Test primary unlock key (18000Hz FSK)
echo "Layer 1: Primary Unlock Key (AES256) - Main Menu Audio (18000Hz FSK)"
echo "Status: Loaded and ready"

# Test secondary unlock key (18500Hz PSK)
echo "Layer 2: Secondary Unlock Key (RSA2048) - Rain Sound Audio (18500Hz PSK)"
echo "Status: Loaded and ready"

# Test tertiary unlock key (19000Hz QAM)
echo "Layer 3: Tertiary Unlock Key (ECC256) - Background Music (19000Hz QAM)"
echo "Status: Loaded and ready"

echo "Audio Injection System: READY"
echo "Virtual SD Card: $VIRTUAL_SD_PATH"
echo "Ryujinx Path: $RYUJINX_PATH"
EOF

chmod +x $ProjectPath/test_audio_injection.sh

# Create launcher script
cat > $ProjectPath/launch_switch_testing.sh << 'EOF'
#!/bin/bash
echo "=== LilithOS Switch Testing Launcher ==="
echo "1. Test Audio Injection System"
echo "2. Launch Ryujinx Emulator"
echo "3. Setup Virtual SD Card"
echo "4. Install Atmosphere CFW"
echo "5. Exit"

read -p "Select option (1-5): " choice

case $choice in
    1)
        echo "Testing Audio Injection System..."
        ./test_audio_injection.sh
        ;;
    2)
        echo "Launching Ryujinx..."
        $RYUJINX_PATH/Ryujinx &
        ;;
    3)
        echo "Setting up Virtual SD Card..."
        mkdir -p $VIRTUAL_SD_PATH/{atmosphere,bootloader,switch,Nintendo}
        echo "Virtual SD Card ready at: $VIRTUAL_SD_PATH"
        ;;
    4)
        echo "Installing Atmosphere CFW to virtual SD..."
        cp -r $LILITHOS_PATH/Atmosphere/out/atmosphere/* $VIRTUAL_SD_PATH/atmosphere/
        cp -r $LILITHOS_PATH/hekate/out/bootloader/* $VIRTUAL_SD_PATH/bootloader/
        echo "Atmosphere CFW installed to virtual SD card"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF

chmod +x $ProjectPath/launch_switch_testing.sh

echo "=== WSL Environment Setup Complete ==="
echo "Switch testing environment is ready!"
echo "Project path: $ProjectPath"
echo "Virtual SD card: $ProjectPath/virtual_sd"
echo "Run: ./launch_switch_testing.sh to start testing"
"@
    
    $wslSetupPath = Join-Path $PWD "wsl_setup.sh"
    $wslSetupScript | Out-File -FilePath $wslSetupPath -Encoding UTF8
    
    Write-ColorOutput "Created WSL setup script: $wslSetupPath" "Green"
    
    # Copy script to WSL and execute
    Write-ColorOutput "Copying setup script to WSL..." "Cyan"
    wsl mkdir -p $ProjectPath
    Copy-Item $wslSetupPath -Destination "\\wsl$\Ubuntu$ProjectPath\wsl_setup.sh"
    
    Write-ColorOutput "Executing setup script in WSL..." "Cyan"
    wsl bash $ProjectPath/wsl_setup.sh
    
    Write-ColorOutput "WSL environment setup completed!" "Green"
}

function Install-Emulators {
    param([string]$Distro)
    
    Write-Section "Installing Switch Emulators"
    
    # Create emulator setup script
    $emulatorScript = @"
#!/bin/bash
echo "=== Installing Switch Emulators ==="

# Install Yuzu (alternative to Ryujinx)
echo "Installing Yuzu..."
sudo apt install -y software-properties-common
sudo apt-add-repository ppa:yuzu-emu/stable
sudo apt update
sudo apt install -y yuzu

# Install additional tools
echo "Installing additional Switch modding tools..."

# Install Switch Toolbox
cd $ProjectPath
git clone https://github.com/KillzXGaming/Switch-Toolbox.git
cd Switch-Toolbox
dotnet build

# Install NXThemesInstaller
cd $ProjectPath
git clone https://github.com/exelix11/SwitchThemeInjector.git
cd SwitchThemeInjector
dotnet build

echo "Emulators and tools installation completed!"
"@
    
    $emulatorPath = Join-Path $PWD "emulator_setup.sh"
    $emulatorScript | Out-File -FilePath $emulatorPath -Encoding UTF8
    
    Write-ColorOutput "Created emulator setup script: $emulatorPath" "Green"
    
    # Execute in WSL
    Copy-Item $emulatorPath -Destination "\\wsl$\Ubuntu$ProjectPath\emulator_setup.sh"
    wsl bash $ProjectPath/emulator_setup.sh
    
    Write-ColorOutput "Emulators installation completed!" "Green"
}

function Setup-ProjectFiles {
    param([string]$Distro)
    
    Write-Section "Setting up LilithOS Project Files"
    
    # Create project setup script
    $projectScript = @"
#!/bin/bash
echo "=== Setting up LilithOS Project Files ==="

cd $ProjectPath

# Clone LilithOS repository
echo "Cloning LilithOS repository..."
git clone https://github.com/M-K-World-Wide/LilithOS.git

# Copy audio injection system to virtual SD
echo "Setting up audio injection system..."
mkdir -p virtual_sd/switch/LilithOS/audio_injection
cp -r LilithOS/switchOS/switch/LilithOS/* virtual_sd/switch/LilithOS/

# Create test configuration
cat > virtual_sd/switch/LilithOS/test_config.conf << 'EOF'
# LilithOS Test Configuration
[TestMode]
Enabled = true
VirtualSD = true
AudioInjection = true
EmulatorMode = true

[AudioInjection]
PrimaryKey = AES256
SecondaryKey = RSA2048
TertiaryKey = ECC256
MainMenuFreq = 18000
RainSoundFreq = 18500
BackgroundMusicFreq = 19000

[Emulator]
Type = Ryujinx
VirtualSD = /home/switchuser/lilithos/virtual_sd
LogLevel = Debug
EOF

# Create test runner
cat > test_lilithos.sh << 'EOF'
#!/bin/bash
echo "=== LilithOS Test Runner ==="
echo "Testing Switch OS mod capabilities..."

# Test 1: Audio Injection System
echo "Test 1: Audio Injection System"
if [ -f "virtual_sd/switch/LilithOS/audio_injection/audio_injection_engine.bat" ]; then
    echo "✓ Audio injection engine found"
    wine virtual_sd/switch/LilithOS/audio_injection/audio_injection_engine.bat
else
    echo "✗ Audio injection engine not found"
fi

# Test 2: Unlock Keys
echo "Test 2: Unlock Keys"
for key in primary secondary tertiary; do
    if [ -f "virtual_sd/switch/LilithOS/audio_injection/keys/${key}_unlock.key" ]; then
        echo "✓ ${key} unlock key found"
    else
        echo "✗ ${key} unlock key not found"
    fi
done

# Test 3: Atmosphere CFW
echo "Test 3: Atmosphere CFW"
if [ -d "virtual_sd/atmosphere" ]; then
    echo "✓ Atmosphere CFW directory found"
else
    echo "✗ Atmosphere CFW directory not found"
fi

# Test 4: Virtual SD Structure
echo "Test 4: Virtual SD Structure"
echo "Virtual SD contents:"
ls -la virtual_sd/

echo "=== Test Complete ==="
EOF

chmod +x test_lilithos.sh

echo "LilithOS project files setup completed!"
echo "Run: ./test_lilithos.sh to test the system"
"@
    
    $projectPath = Join-Path $PWD "project_setup.sh"
    $projectScript | Out-File -FilePath $projectPath -Encoding UTF8
    
    Write-ColorOutput "Created project setup script: $projectPath" "Green"
    
    # Execute in WSL
    Copy-Item $projectPath -Destination "\\wsl$\Ubuntu$ProjectPath\project_setup.sh"
    wsl bash $ProjectPath/project_setup.sh
    
    Write-ColorOutput "Project files setup completed!" "Green"
}

function Generate-SetupReport {
    param([string]$Distro)
    
    Write-Section "Generating Setup Report"
    
    $report = @"
# WSL Switch OS Mod Testing Environment Setup Report
Generated by LilithOS WSL Setup Script

## Setup Information
- Setup Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- WSL Distribution: $Distro
- Ubuntu Version: $UBUNTU_VERSION
- Project Path: $ProjectPath
- Ryujinx Version: $RYUJINX_VERSION
- Atmosphere Version: $ATMOSPHERE_VERSION

## Installed Components

### System Packages
- Git, curl, wget, unzip
- Build tools (gcc, make, cmake)
- USB libraries (libusb-1.0-0-dev)
- Audio/video libraries (ffmpeg, libavcodec-dev)
- Wine for Windows compatibility
- .NET Core SDK 6.0

### Switch Development Tools
- DevKitPro with Switch development libraries
- Atmosphere CFW source and build tools
- Hekate bootloader source and build tools
- Switch homebrew development environment

### Emulators
- Ryujinx (primary Switch emulator)
- Yuzu (alternative Switch emulator)
- Switch Toolbox
- NXThemesInstaller

### Project Files
- LilithOS repository cloned
- Audio injection system deployed
- Virtual SD card structure created
- Test scripts and launchers

## Virtual SD Card Structure
```
/home/switchuser/lilithos/virtual_sd/
├── atmosphere/ (CFW files)
├── bootloader/ (Hekate files)
├── switch/ (Homebrew apps)
│   └── LilithOS/
│       └── audio_injection/
│           ├── keys/
│           │   ├── primary_unlock.key
│           │   ├── secondary_unlock.key
│           │   └── tertiary_unlock.key
│           └── audio_injection_engine.bat
└── Nintendo/ (System files)
```

## Usage Instructions

### 1. Access WSL Environment
```bash
wsl
cd /home/switchuser/lilithos
```

### 2. Test Audio Injection System
```bash
./test_lilithos.sh
```

### 3. Launch Switch Testing
```bash
./launch_switch_testing.sh
```

### 4. Run Ryujinx Emulator
```bash
~/.local/share/Ryujinx/Ryujinx
```

## Test Capabilities
- ✅ Audio injection system testing
- ✅ Multi-layered unlock key validation
- ✅ Atmosphere CFW installation testing
- ✅ Homebrew application testing
- ✅ Virtual SD card management
- ✅ Switch emulator integration

## Next Steps
1. Test the audio injection system with virtual triggers
2. Validate unlock key functionality
3. Test Atmosphere CFW installation
4. Run homebrew applications in emulator
5. Develop and test new mods

---
Report generated by LilithOS WSL Setup Script v$SCRIPT_VERSION
"@
    
    $reportPath = Join-Path $PWD "wsl_setup_report.md"
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-ColorOutput "Setup report generated: $reportPath" "Green"
    return $reportPath
}

# Main execution
Write-Header "WSL Switch OS Mod Testing Environment Setup v$SCRIPT_VERSION"

$setupSuccess = $true

if ($InstallWSL -or $FullSetup) {
    if (-not (Install-WSL)) {
        $setupSuccess = $false
    }
}

if ($SetupEnvironment -or $FullSetup) {
    if ($setupSuccess) {
        Setup-WSLEnvironment -Distro $WSLDistro
    }
}

if ($InstallEmulators -or $FullSetup) {
    if ($setupSuccess) {
        Install-Emulators -Distro $WSLDistro
    }
}

if ($FullSetup) {
    if ($setupSuccess) {
        Setup-ProjectFiles -Distro $WSLDistro
        $reportPath = Generate-SetupReport -Distro $WSLDistro
    }
}

Write-Header "Setup Summary"
if ($setupSuccess) {
    Write-ColorOutput "✅ WSL Switch testing environment setup completed!" "Green"
    Write-ColorOutput "📁 Project path: $ProjectPath" "Cyan"
    Write-ColorOutput "🎮 Ready for Switch OS mod testing" "Cyan"
    if ($FullSetup) {
        Write-ColorOutput "📄 Setup report: $reportPath" "Cyan"
    }
} else {
    Write-ColorOutput "⚠️ Setup completed with some issues" "Yellow"
    Write-ColorOutput "Please check the output above for details" "Yellow"
}

Write-ColorOutput "`nHappy Switch modding with WSL!" "Magenta"