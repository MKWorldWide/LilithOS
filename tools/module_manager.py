#!/usr/bin/env python3
"""
LilithOS Module Manager
=======================

Handles dynamic loading and management of LilithOS modules based on
detected hardware and user preferences.
"""

import os
import sys
import json
import importlib
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any
import yaml

class ModuleManager:
    """Manages LilithOS modules dynamically"""
    
    def __init__(self, base_path: str = "/usr/local/lilithos"):
        self.base_path = Path(base_path)
        self.registry = self.load_registry()
        self.loaded_modules = {}
        self.chip_info = self.detect_chip_info()
        
        print(f"🌑 LilithOS Module Manager")
        print(f"🔧 Chip: {self.chip_info['model']}")
        print(f"🏗️ Architecture: {self.chip_info['architecture']}")
    
    def load_registry(self) -> Dict:
        """Load module registry"""
        registry_path = self.base_path / "config" / "module_registry.json"
        
        if registry_path.exists():
            with open(registry_path, 'r') as f:
                return json.load(f)
        else:
            return self.get_default_registry()
    
    def get_default_registry(self) -> Dict:
        """Get default module registry"""
        return {
            "modules": {
                "core": {
                    "version": "2.0.0",
                    "dependencies": [],
                    "architectures": ["universal"],
                    "required": True
                },
                "apple-silicon": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "architectures": ["arm64"],
                    "features": ["neural_engine", "unified_memory", "secure_enclave"]
                },
                "intel-x86": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "architectures": ["x86_64"],
                    "features": ["avx", "turbo_boost"]
                },
                "arm64": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "architectures": ["arm64"],
                    "features": ["neon", "big_little"]
                },
                "desktop": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "platforms": ["desktop"],
                    "required": False
                },
                "mobile": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "platforms": ["mobile"],
                    "required": False
                },
                "security": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "required": True
                },
                "performance": {
                    "version": "2.0.0",
                    "dependencies": ["core"],
                    "required": False
                },
                "dark-glass": {
                    "version": "2.0.0",
                    "dependencies": ["desktop"],
                    "type": "theme",
                    "required": False
                }
            }
        }
    
    def detect_chip_info(self) -> Dict:
        """Detect chip information"""
        import platform
        
        arch = platform.machine().lower()
        system = platform.system()
        
        # Map architectures
        arch_map = {
            'x86_64': 'intel-x86',
            'amd64': 'intel-x86',
            'aarch64': 'arm64',
            'arm64': 'arm64'
        }
        
        chip_arch = arch_map.get(arch, arch)
        
        # Get chip model
        chip_model = self.get_chip_model()
        
        # Check for Apple Silicon
        is_apple_silicon = self.is_apple_silicon()
        
        return {
            'architecture': chip_arch,
            'model': chip_model,
            'system': system,
            'is_apple_silicon': is_apple_silicon,
            'features': self.get_chip_features(chip_arch, is_apple_silicon)
        }
    
    def is_apple_silicon(self) -> bool:
        """Check if running on Apple Silicon"""
        import platform
        
        if platform.system() != 'Darwin':
            return False
        
        try:
            result = subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], 
                                  capture_output=True, text=True)
            return 'Apple' in result.stdout
        except:
            return False
    
    def get_chip_model(self) -> str:
        """Get chip model"""
        import platform
        
        try:
            if platform.system() == 'Darwin':
                result = subprocess.run(['sysctl', '-n', 'machdep.cpu.brand_string'], 
                                      capture_output=True, text=True)
                return result.stdout.strip()
            else:
                with open('/proc/cpuinfo', 'r') as f:
                    for line in f:
                        if line.startswith('model name'):
                            return line.split(':')[1].strip()
        except:
            pass
        
        return "Unknown"
    
    def get_chip_features(self, arch: str, is_apple_silicon: bool) -> List[str]:
        """Get chip features"""
        features = []
        
        if is_apple_silicon:
            features.extend(['neural_engine', 'unified_memory', 'secure_enclave'])
        elif arch == 'intel-x86':
            try:
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
        elif arch == 'arm64':
            features.extend(['neon', 'big_little'])
        
        return features
    
    def get_compatible_modules(self) -> List[str]:
        """Get modules compatible with current chip"""
        compatible_modules = []
        
        for name, info in self.registry['modules'].items():
            # Check architecture compatibility
            if 'architectures' in info:
                if self.chip_info['architecture'] in info['architectures']:
                    compatible_modules.append(name)
            elif 'architectures' not in info or 'universal' in info['architectures']:
                compatible_modules.append(name)
        
        return compatible_modules
    
    def load_module(self, module_name: str) -> bool:
        """Load a module dynamically"""
        if module_name in self.loaded_modules:
            return True
        
        if module_name not in self.registry['modules']:
            print(f"❌ Module '{module_name}' not found in registry")
            return False
        
        module_info = self.registry['modules'][module_name]
        
        # Check dependencies
        for dep in module_info.get('dependencies', []):
            if not self.load_module(dep):
                print(f"❌ Failed to load dependency '{dep}' for module '{module_name}'")
                return False
        
        # Check compatibility
        if not self.is_module_compatible(module_name, module_info):
            print(f"❌ Module '{module_name}' not compatible with current system")
            return False
        
        # Load the module
        try:
            module_path = self.base_path / "modules" / module_name
            if module_path.exists():
                self.load_module_files(module_path, module_name)
                self.loaded_modules[module_name] = module_info
                print(f"✅ Loaded module: {module_name}")
                return True
            else:
                print(f"❌ Module files not found: {module_path}")
                return False
        except Exception as e:
            print(f"❌ Failed to load module '{module_name}': {e}")
            return False
    
    def is_module_compatible(self, module_name: str, module_info: Dict) -> bool:
        """Check if module is compatible with current system"""
        # Check architecture compatibility
        if 'architectures' in module_info:
            if self.chip_info['architecture'] not in module_info['architectures']:
                return False
        
        # Check platform compatibility
        if 'platforms' in module_info:
            platform = self.detect_platform()
            if platform not in module_info['platforms']:
                return False
        
        # Check feature requirements
        if 'required_features' in module_info:
            for feature in module_info['required_features']:
                if feature not in self.chip_info['features']:
                    return False
        
        return True
    
    def detect_platform(self) -> str:
        """Detect current platform"""
        import platform
        
        system = platform.system().lower()
        
        if system == 'darwin':
            return 'desktop'
        elif system == 'linux':
            return 'desktop'
        elif system == 'windows':
            return 'desktop'
        else:
            return 'unknown'
    
    def load_module_files(self, module_path: Path, module_name: str):
        """Load module files"""
        # Load configuration
        config_file = module_path / "config.json"
        if config_file.exists():
            with open(config_file, 'r') as f:
                config = json.load(f)
        
        # Execute initialization script
        init_script = module_path / "init.sh"
        if init_script.exists():
            subprocess.run([str(init_script)], check=True)
        
        # Load Python modules
        python_dir = module_path / "python"
        if python_dir.exists():
            sys.path.insert(0, str(python_dir))
    
    def load_required_modules(self):
        """Load all required modules"""
        print("🔧 Loading required modules...")
        
        for name, info in self.registry['modules'].items():
            if info.get('required', False):
                self.load_module(name)
    
    def load_chip_modules(self):
        """Load chip-specific modules"""
        print("🔧 Loading chip-specific modules...")
        
        chip_modules = []
        for name, info in self.registry['modules'].items():
            if 'architectures' in info and self.chip_info['architecture'] in info['architectures']:
                chip_modules.append(name)
        
        for module in chip_modules:
            self.load_module(module)
    
    def load_platform_modules(self):
        """Load platform-specific modules"""
        print("🔧 Loading platform modules...")
        
        platform = self.detect_platform()
        platform_modules = []
        
        for name, info in self.registry['modules'].items():
            if 'platforms' in info and platform in info['platforms']:
                platform_modules.append(name)
        
        for module in platform_modules:
            self.load_module(module)
    
    def get_loaded_modules(self) -> Dict[str, Dict]:
        """Get information about loaded modules"""
        return self.loaded_modules
    
    def get_module_status(self) -> Dict[str, str]:
        """Get status of all modules"""
        status = {}
        
        for name, info in self.registry['modules'].items():
            if name in self.loaded_modules:
                status[name] = "loaded"
            elif self.is_module_compatible(name, info):
                status[name] = "available"
            else:
                status[name] = "incompatible"
        
        return status
    
    def unload_module(self, module_name: str) -> bool:
        """Unload a module"""
        if module_name not in self.loaded_modules:
            return True
        
        try:
            # Execute cleanup script
            module_path = self.base_path / "modules" / module_name
            cleanup_script = module_path / "cleanup.sh"
            if cleanup_script.exists():
                subprocess.run([str(cleanup_script)], check=True)
            
            # Remove from loaded modules
            del self.loaded_modules[module_name]
            print(f"✅ Unloaded module: {module_name}")
            return True
        except Exception as e:
            print(f"❌ Failed to unload module '{module_name}': {e}")
            return False
    
    def reload_module(self, module_name: str) -> bool:
        """Reload a module"""
        if self.unload_module(module_name):
            return self.load_module(module_name)
        return False
    
    def install_module(self, module_name: str, module_path: str) -> bool:
        """Install a new module"""
        try:
            # Copy module files
            target_path = self.base_path / "modules" / module_name
            target_path.mkdir(parents=True, exist_ok=True)
            
            # Copy files
            import shutil
            shutil.copytree(module_path, target_path, dirs_exist_ok=True)
            
            # Update registry
            self.update_registry(module_name)
            
            print(f"✅ Installed module: {module_name}")
            return True
        except Exception as e:
            print(f"❌ Failed to install module '{module_name}': {e}")
            return False
    
    def update_registry(self, module_name: str):
        """Update module registry"""
        # This would typically read module metadata and update the registry
        # For now, we'll just reload the registry
        self.registry = self.load_registry()
    
    def create_module(self, module_name: str, module_type: str = "feature") -> bool:
        """Create a new module template"""
        try:
            module_path = self.base_path / "modules" / module_name
            module_path.mkdir(parents=True, exist_ok=True)
            
            # Create module structure
            (module_path / "python").mkdir(exist_ok=True)
            (module_path / "scripts").mkdir(exist_ok=True)
            (module_path / "config").mkdir(exist_ok=True)
            
            # Create configuration file
            config = {
                "name": module_name,
                "type": module_type,
                "version": "1.0.0",
                "description": f"LilithOS {module_type} module",
                "dependencies": ["core"],
                "architectures": ["universal"]
            }
            
            with open(module_path / "config.json", 'w') as f:
                json.dump(config, f, indent=2)
            
            # Create initialization script
            init_script = f"""#!/bin/bash
# LilithOS {module_name} Module Initialization

echo "🔧 Initializing {module_name} module..."

# Add your initialization code here

echo "✅ {module_name} module initialized"
"""
            
            with open(module_path / "init.sh", 'w') as f:
                f.write(init_script)
            
            os.chmod(module_path / "init.sh", 0o755)
            
            print(f"✅ Created module template: {module_name}")
            return True
        except Exception as e:
            print(f"❌ Failed to create module '{module_name}': {e}")
            return False

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='LilithOS Module Manager')
    parser.add_argument('--base-path', default='/usr/local/lilithos', help='Base path for LilithOS')
    parser.add_argument('--load', help='Load specific module')
    parser.add_argument('--unload', help='Unload specific module')
    parser.add_argument('--reload', help='Reload specific module')
    parser.add_argument('--status', action='store_true', help='Show module status')
    parser.add_argument('--install', help='Install module from path')
    parser.add_argument('--create', help='Create new module')
    parser.add_argument('--auto-load', action='store_true', help='Auto-load required modules')
    
    args = parser.parse_args()
    
    # Create module manager
    manager = ModuleManager(base_path=args.base_path)
    
    if args.load:
        manager.load_module(args.load)
    elif args.unload:
        manager.unload_module(args.unload)
    elif args.reload:
        manager.reload_module(args.reload)
    elif args.install:
        manager.install_module(args.install, args.install)
    elif args.create:
        manager.create_module(args.create)
    elif args.auto_load:
        manager.load_required_modules()
        manager.load_chip_modules()
        manager.load_platform_modules()
    elif args.status:
        status = manager.get_module_status()
        print("\n📊 Module Status:")
        for module, state in status.items():
            print(f"  {module}: {state}")
    else:
        # Default: show status
        status = manager.get_module_status()
        print("\n📊 Module Status:")
        for module, state in status.items():
            print(f"  {module}: {state}")

if __name__ == "__main__":
    main() 