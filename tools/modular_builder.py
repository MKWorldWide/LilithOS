#!/usr/bin/env python3
"""
LilithOS Universal Modular Builder
==================================

This tool builds LilithOS packages for any chip architecture by detecting
the target hardware and building appropriate modules dynamically.
"""

import os
import sys
import json
import subprocess
import platform
import shutil
from pathlib import Path
from typing import Dict, List, Optional
import yaml

class LilithOSBuilder:
    """Universal LilithOS builder for any chip architecture"""
    
    def __init__(self, target_arch: Optional[str] = None, output_dir: str = "build"):
        self.target_arch = target_arch or self.detect_architecture()
        self.output_dir = Path(output_dir)
        self.build_config = self.load_build_config()
        self.chip_info = self.detect_chip_info()
        
        # Ensure output directory exists
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"🌑 LilithOS Universal Builder")
        print(f"🎯 Target Architecture: {self.target_arch}")
        print(f"🔧 Chip Info: {self.chip_info}")
        print(f"📁 Output Directory: {self.output_dir}")
    
    def detect_architecture(self) -> str:
        """Detect the current system architecture"""
        arch = platform.machine().lower()
        
        # Map common architectures
        arch_map = {
            'x86_64': 'intel-x86',
            'amd64': 'intel-x86',
            'aarch64': 'arm64',
            'arm64': 'arm64',
            'armv7l': 'arm32',
            'armv8l': 'arm64'
        }
        
        return arch_map.get(arch, arch)
    
    def detect_chip_info(self) -> Dict:
        """Detect detailed chip information"""
        chip_info = {
            'architecture': self.target_arch,
            'model': self.get_chip_model(),
            'features': self.get_chip_features(),
            'performance': self.get_performance_profile(),
            'platform': self.detect_platform()
        }
        
        # Add Apple Silicon specific info
        if self.is_apple_silicon():
            chip_info.update({
                'neural_engine': True,
                'unified_memory': True,
                'secure_enclave': True
            })
        
        return chip_info
    
    def is_apple_silicon(self) -> bool:
        """Check if running on Apple Silicon"""
        if platform.system() != 'Darwin':
            return False
        
        try:
            result = subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], 
                                  capture_output=True, text=True)
            return 'Apple' in result.stdout
        except:
            return False
    
    def get_chip_model(self) -> str:
        """Get the specific chip model"""
        try:
            if platform.system() == 'Darwin':
                result = subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], 
                                      capture_output=True, text=True)
                return result.stdout.strip()
            else:
                # For Linux systems
                with open('/proc/cpuinfo', 'r') as f:
                    for line in f:
                        if line.startswith('model name'):
                            return line.split(':')[1].strip()
        except:
            pass
        
        return "Unknown"
    
    def get_chip_features(self) -> List[str]:
        """Get available chip features"""
        features = []
        
        try:
            if platform.system() == 'Darwin':
                # Check for Apple Silicon features
                if self.is_apple_silicon():
                    features.extend(['neural_engine', 'unified_memory', 'secure_enclave'])
            else:
                # Check for x86 features
                with open('/proc/cpuinfo', 'r') as f:
                    content = f.read()
                    if 'avx' in content.lower():
                        features.append('avx')
                    if 'sse' in content.lower():
                        features.append('sse')
                    if 'aes' in content.lower():
                        features.append('aes')
        except:
            pass
        
        return features
    
    def get_performance_profile(self) -> Dict:
        """Get performance profile for the chip"""
        try:
            cpu_count = os.cpu_count()
            memory_gb = self.get_memory_gb()
            
            return {
                'cpu_cores': cpu_count,
                'memory_gb': memory_gb,
                'performance_level': self.calculate_performance_level(cpu_count, memory_gb)
            }
        except:
            return {'performance_level': 'unknown'}
    
    def get_memory_gb(self) -> int:
        """Get system memory in GB"""
        try:
            if platform.system() == 'Darwin':
                result = subprocess.run(['sysctl', '-n', 'hw.memsize'], 
                                      capture_output=True, text=True)
                return int(result.stdout.strip()) // (1024**3)
            else:
                with open('/proc/meminfo', 'r') as f:
                    for line in f:
                        if line.startswith('MemTotal:'):
                            return int(line.split()[1]) // (1024**2)
        except:
            pass
        
        return 8  # Default assumption
    
    def calculate_performance_level(self, cpu_count: int, memory_gb: int) -> str:
        """Calculate performance level based on hardware"""
        if cpu_count >= 16 and memory_gb >= 32:
            return 'high'
        elif cpu_count >= 8 and memory_gb >= 16:
            return 'medium'
        else:
            return 'low'
    
    def detect_platform(self) -> str:
        """Detect the platform type"""
        system = platform.system().lower()
        
        if system == 'darwin':
            return 'macos'
        elif system == 'linux':
            return 'linux'
        elif system == 'windows':
            return 'windows'
        else:
            return 'unknown'
    
    def load_build_config(self) -> Dict:
        """Load build configuration"""
        config_path = Path("config/build_config.yaml")
        
        if config_path.exists():
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        else:
            return self.get_default_config()
    
    def get_default_config(self) -> Dict:
        """Get default build configuration"""
        return {
            'version': '2.0.0',
            'modules': {
                'core': {'required': True},
                'chips': {'required': True},
                'platforms': {'required': True},
                'features': {'required': False},
                'themes': {'required': False}
            },
            'optimizations': {
                'performance': True,
                'security': True,
                'power': True
            }
        }
    
    def build_package(self) -> str:
        """Build the complete LilithOS package"""
        print("🚀 Starting LilithOS build process...")
        
        # Build core components
        self.build_core()
        
        # Build chip-specific components
        self.build_chip_modules()
        
        # Build platform components
        self.build_platform_modules()
        
        # Build feature modules
        self.build_feature_modules()
        
        # Build theme modules
        self.build_theme_modules()
        
        # Create package
        package_path = self.create_package()
        
        print(f"✅ Build completed: {package_path}")
        return package_path
    
    def build_core(self):
        """Build core system components"""
        print("🔧 Building core system...")
        
        core_dir = self.output_dir / "core"
        core_dir.mkdir(exist_ok=True)
        
        # Copy core files
        self.copy_directory("core", core_dir)
        
        # Generate chip-agnostic configuration
        self.generate_core_config(core_dir)
        
        print("✅ Core system built")
    
    def build_chip_modules(self):
        """Build chip-specific modules"""
        print(f"🔧 Building chip modules for {self.target_arch}...")
        
        chip_dir = self.output_dir / "modules" / "chips"
        chip_dir.mkdir(parents=True, exist_ok=True)
        
        # Build target chip module
        target_chip_dir = chip_dir / self.target_arch
        target_chip_dir.mkdir(exist_ok=True)
        
        # Copy chip-specific files
        source_chip_dir = Path("modules/chips") / self.target_arch
        if source_chip_dir.exists():
            self.copy_directory(source_chip_dir, target_chip_dir)
        
        # Generate chip-specific configuration
        self.generate_chip_config(target_chip_dir)
        
        print(f"✅ Chip modules built for {self.target_arch}")
    
    def build_platform_modules(self):
        """Build platform-specific modules"""
        print(f"🔧 Building platform modules for {self.chip_info['platform']}...")
        
        platform_dir = self.output_dir / "modules" / "platforms"
        platform_dir.mkdir(parents=True, exist_ok=True)
        
        # Build target platform module
        target_platform = self.chip_info['platform']
        target_platform_dir = platform_dir / target_platform
        target_platform_dir.mkdir(exist_ok=True)
        
        # Copy platform-specific files
        source_platform_dir = Path("modules/platforms") / target_platform
        if source_platform_dir.exists():
            self.copy_directory(source_platform_dir, target_platform_dir)
        
        # Generate platform-specific configuration
        self.generate_platform_config(target_platform_dir)
        
        print(f"✅ Platform modules built for {target_platform}")
    
    def build_feature_modules(self):
        """Build feature modules"""
        print("🔧 Building feature modules...")
        
        features_dir = self.output_dir / "modules" / "features"
        features_dir.mkdir(parents=True, exist_ok=True)
        
        # Build security features
        security_dir = features_dir / "security"
        security_dir.mkdir(exist_ok=True)
        self.build_security_module(security_dir)
        
        # Build performance features
        performance_dir = features_dir / "performance"
        performance_dir.mkdir(exist_ok=True)
        self.build_performance_module(performance_dir)
        
        print("✅ Feature modules built")
    
    def build_theme_modules(self):
        """Build theme modules"""
        print("🎨 Building theme modules...")
        
        themes_dir = self.output_dir / "modules" / "themes"
        themes_dir.mkdir(parents=True, exist_ok=True)
        
        # Build dark glass theme
        dark_glass_dir = themes_dir / "dark-glass"
        dark_glass_dir.mkdir(exist_ok=True)
        self.build_dark_glass_theme(dark_glass_dir)
        
        print("✅ Theme modules built")
    
    def build_security_module(self, security_dir: Path):
        """Build security module"""
        # Create security configuration
        security_config = {
            'chip_security': self.chip_info.get('secure_enclave', False),
            'encryption': True,
            'firewall': True,
            'sandboxing': True
        }
        
        with open(security_dir / "config.json", 'w') as f:
            json.dump(security_config, f, indent=2)
        
        # Create security scripts
        self.create_security_scripts(security_dir)
    
    def build_performance_module(self, performance_dir: Path):
        """Build performance module"""
        # Create performance configuration
        perf_config = {
            'cpu_cores': self.chip_info['performance']['cpu_cores'],
            'memory_gb': self.chip_info['performance']['memory_gb'],
            'performance_level': self.chip_info['performance']['performance_level'],
            'optimizations': self.chip_info['features']
        }
        
        with open(performance_dir / "config.json", 'w') as f:
            json.dump(perf_config, f, indent=2)
        
        # Create performance scripts
        self.create_performance_scripts(performance_dir)
    
    def build_dark_glass_theme(self, theme_dir: Path):
        """Build dark glass theme"""
        # Create theme configuration
        theme_config = {
            'name': 'Dark Glass',
            'version': '1.0.0',
            'colors': {
                'background': 'rgba(0, 0, 0, 0.8)',
                'accent_gold': '#FFD700',
                'accent_red': '#8B0000',
                'text_primary': '#FFD700',
                'border': '#8B0000'
            }
        }
        
        with open(theme_dir / "theme.json", 'w') as f:
            json.dump(theme_config, f, indent=2)
        
        # Create CSS file
        self.create_theme_css(theme_dir)
    
    def create_security_scripts(self, security_dir: Path):
        """Create security scripts"""
        # Create security initialization script
        init_script = f"""#!/bin/bash
# LilithOS Security Module Initialization
# Generated for {self.target_arch}

echo "🔒 Initializing LilithOS Security Module..."

# Load chip-specific security
if [ -f "/modules/chips/{self.target_arch}/security.sh" ]; then
    source "/modules/chips/{self.target_arch}/security.sh"
fi

# Initialize security features
initialize_encryption
initialize_firewall
initialize_sandboxing

echo "✅ Security module initialized"
"""
        
        with open(security_dir / "init.sh", 'w') as f:
            f.write(init_script)
        
        os.chmod(security_dir / "init.sh", 0o755)
    
    def create_performance_scripts(self, performance_dir: Path):
        """Create performance scripts"""
        # Create performance optimization script
        perf_script = f"""#!/bin/bash
# LilithOS Performance Module
# Generated for {self.target_arch}

echo "⚡ Optimizing LilithOS Performance..."

# Load chip-specific optimizations
if [ -f "/modules/chips/{self.target_arch}/performance.sh" ]; then
    source "/modules/chips/{self.target_arch}/performance.sh"
fi

# Apply performance optimizations
optimize_cpu_scheduling
optimize_memory_management
optimize_power_management

echo "✅ Performance optimizations applied"
"""
        
        with open(performance_dir / "optimize.sh", 'w') as f:
            f.write(perf_script)
        
        os.chmod(performance_dir / "optimize.sh", 0o755)
    
    def create_theme_css(self, theme_dir: Path):
        """Create theme CSS file"""
        css_content = """/* LilithOS Dark Glass Theme */
:root {
  --lilithos-bg-primary: rgba(0, 0, 0, 0.8);
  --lilithos-bg-secondary: rgba(139, 0, 0, 0.3);
  --lilithos-accent-gold: #FFD700;
  --lilithos-accent-red: #8B0000;
  --lilithos-text-primary: #FFD700;
  --lilithos-border: #8B0000;
}

.lilithos-theme {
  background: var(--lilithos-bg-primary);
  color: var(--lilithos-text-primary);
  border: 1px solid var(--lilithos-border);
}

.lilithos-button {
  background: linear-gradient(135deg, rgba(139,0,0,0.8), rgba(0,0,0,0.9));
  border: 1px solid var(--lilithos-accent-gold);
  color: var(--lilithos-accent-gold);
  border-radius: 4px;
}

.lilithos-button:hover {
  background: linear-gradient(135deg, rgba(255,215,0,0.2), rgba(139,0,0,0.8));
}
"""
        
        with open(theme_dir / "theme.css", 'w') as f:
            f.write(css_content)
    
    def generate_core_config(self, core_dir: Path):
        """Generate core configuration"""
        config = {
            'version': self.build_config['version'],
            'architecture': self.target_arch,
            'chip_info': self.chip_info,
            'build_config': self.build_config
        }
        
        with open(core_dir / "config.json", 'w') as f:
            json.dump(config, f, indent=2)
    
    def generate_chip_config(self, chip_dir: Path):
        """Generate chip-specific configuration"""
        config = {
            'architecture': self.target_arch,
            'model': self.chip_info['model'],
            'features': self.chip_info['features'],
            'performance': self.chip_info['performance']
        }
        
        with open(chip_dir / "config.json", 'w') as f:
            json.dump(config, f, indent=2)
    
    def generate_platform_config(self, platform_dir: Path):
        """Generate platform-specific configuration"""
        config = {
            'platform': self.chip_info['platform'],
            'architecture': self.target_arch,
            'system': platform.system(),
            'release': platform.release()
        }
        
        with open(platform_dir / "config.json", 'w') as f:
            json.dump(config, f, indent=2)
    
    def copy_directory(self, source: Path, destination: Path):
        """Copy directory recursively"""
        if not source.exists():
            return
        
        if source.is_file():
            shutil.copy2(source, destination)
        else:
            shutil.copytree(source, destination, dirs_exist_ok=True)
    
    def create_package(self) -> str:
        """Create the final package"""
        print("📦 Creating package...")
        
        # Create package manifest
        manifest = {
            'name': 'lilithos-universal',
            'version': self.build_config['version'],
            'architecture': self.target_arch,
            'chip_info': self.chip_info,
            'build_date': self.get_build_date(),
            'modules': self.get_module_list()
        }
        
        with open(self.output_dir / "manifest.json", 'w') as f:
            json.dump(manifest, f, indent=2)
        
        # Create installer script
        self.create_installer_script()
        
        # Create package archive
        package_name = f"lilithos-{self.target_arch}-{self.build_config['version']}.tar.gz"
        package_path = self.output_dir.parent / package_name
        
        # Create tar.gz archive
        shutil.make_archive(
            str(package_path).replace('.tar.gz', ''),
            'gztar',
            self.output_dir
        )
        
        return str(package_path)
    
    def get_build_date(self) -> str:
        """Get current build date"""
        from datetime import datetime
        return datetime.now().isoformat()
    
    def get_module_list(self) -> List[str]:
        """Get list of included modules"""
        modules = []
        
        # Scan modules directory
        modules_dir = self.output_dir / "modules"
        if modules_dir.exists():
            for category in modules_dir.iterdir():
                if category.is_dir():
                    for module in category.iterdir():
                        if module.is_dir():
                            modules.append(f"{category.name}/{module.name}")
        
        return modules
    
    def create_installer_script(self):
        """Create universal installer script"""
        installer_script = f"""#!/bin/bash
# LilithOS Universal Installer
# Generated for {self.target_arch}

set -e

echo "🌑 LilithOS Universal Installer"
echo "🎯 Target Architecture: {self.target_arch}"
echo "🔧 Chip Model: {self.chip_info['model']}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This installer requires root privileges"
    exit 1
fi

# Install core system
echo "🔧 Installing core system..."
install_core_system

# Install chip-specific modules
echo "🔧 Installing chip modules..."
install_chip_modules

# Install platform modules
echo "🔧 Installing platform modules..."
install_platform_modules

# Install feature modules
echo "🔧 Installing feature modules..."
install_feature_modules

# Install theme modules
echo "🎨 Installing theme modules..."
install_theme_modules

# Configure system
echo "⚙️ Configuring system..."
configure_system

echo "✅ LilithOS installation completed!"
echo "🚀 You can now boot into your sacred digital garden."

install_core_system() {{
    # Install core components
    cp -r core/* /usr/local/lilithos/
    chmod +x /usr/local/lilithos/bin/*
}}

install_chip_modules() {{
    # Install chip-specific modules
    mkdir -p /usr/local/lilithos/modules/chips
    cp -r modules/chips/* /usr/local/lilithos/modules/chips/
}}

install_platform_modules() {{
    # Install platform modules
    mkdir -p /usr/local/lilithos/modules/platforms
    cp -r modules/platforms/* /usr/local/lilithos/modules/platforms/
}}

install_feature_modules() {{
    # Install feature modules
    mkdir -p /usr/local/lilithos/modules/features
    cp -r modules/features/* /usr/local/lilithos/modules/features/
}}

install_theme_modules() {{
    # Install theme modules
    mkdir -p /usr/local/lilithos/modules/themes
    cp -r modules/themes/* /usr/local/lilithos/modules/themes/
}}

configure_system() {{
    # Initialize modules
    /usr/local/lilithos/modules/features/security/init.sh
    /usr/local/lilithos/modules/features/performance/optimize.sh
    
    # Set default theme
    echo "dark-glass" > /usr/local/lilithos/config/default_theme
    
    # Create system links
    ln -sf /usr/local/lilithos/bin/lilithos /usr/local/bin/lilithos
}}
"""
        
        with open(self.output_dir / "install.sh", 'w') as f:
            f.write(installer_script)
        
        os.chmod(self.output_dir / "install.sh", 0o755)

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='LilithOS Universal Modular Builder')
    parser.add_argument('--arch', help='Target architecture (auto-detected if not specified)')
    parser.add_argument('--output', default='build', help='Output directory')
    parser.add_argument('--config', help='Build configuration file')
    
    args = parser.parse_args()
    
    # Create builder
    builder = LilithOSBuilder(target_arch=args.arch, output_dir=args.output)
    
    # Build package
    package_path = builder.build_package()
    
    print(f"\n🎉 Build completed successfully!")
    print(f"📦 Package: {package_path}")
    print(f"🔧 Architecture: {builder.target_arch}")
    print(f"💻 Chip: {builder.chip_info['model']}")
    print(f"🚀 Ready for distribution!")

if __name__ == "__main__":
    main() 