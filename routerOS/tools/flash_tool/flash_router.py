#!/usr/bin/env python3
"""
LilithOS Router Firmware Flashing Tool
Netgear Nighthawk R7000P

This tool provides a safe and user-friendly way to flash the custom
LilithOS firmware to the Netgear Nighthawk R7000P router.

Author: LilithOS Development Team
Version: 1.0.0
License: GPL v2
"""

import os
import sys
import time
import hashlib
import socket
import struct
import argparse
import subprocess
import threading
from pathlib import Path
from typing import Optional, Dict, List, Tuple

# ============================================================================
# CONFIGURATION
# ============================================================================

ROUTER_MODEL = "Netgear Nighthawk R7000P"
ROUTER_IP = "192.168.1.1"
ROUTER_USERNAME = "admin"
ROUTER_PASSWORD = "password"
FIRMWARE_PATH = "../firmware/lilithos_router_r7000p_1.0.0.bin"
BACKUP_PATH = "backup/"
TFTP_PORT = 69
HTTP_PORT = 80
SSH_PORT = 22

# ============================================================================
# COLOR OUTPUT
# ============================================================================

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_step(message: str):
    print(f"{Colors.BLUE}[STEP]{Colors.NC} {message}")

def print_success(message: str):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {message}")

def print_warning(message: str):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")

def print_error(message: str):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")

def print_info(message: str):
    print(f"{Colors.PURPLE}[INFO]{Colors.NC} {message}")

# ============================================================================
# ROUTER DETECTION
# ============================================================================

class RouterDetector:
    """Detect and identify the Netgear Nighthawk R7000P router"""
    
    def __init__(self):
        self.router_ip = ROUTER_IP
        self.router_found = False
        self.router_info = {}
    
    def ping_router(self) -> bool:
        """Ping the router to check if it's reachable"""
        try:
            # Use ping command
            if os.name == 'nt':  # Windows
                result = subprocess.run(['ping', '-n', '1', self.router_ip], 
                                      capture_output=True, text=True, timeout=10)
            else:  # Linux/Mac
                result = subprocess.run(['ping', '-c', '1', self.router_ip], 
                                      capture_output=True, text=True, timeout=10)
            
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False
    
    def check_http_interface(self) -> bool:
        """Check if router web interface is accessible"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.router_ip, HTTP_PORT))
            sock.close()
            return result == 0
        except:
            return False
    
    def get_router_info(self) -> Dict:
        """Get router information via HTTP"""
        try:
            import requests
            response = requests.get(f"http://{self.router_ip}/", timeout=10)
            if response.status_code == 200:
                # Parse router information from response
                return {
                    'model': ROUTER_MODEL,
                    'ip': self.router_ip,
                    'firmware': 'Unknown',
                    'uptime': 'Unknown'
                }
        except:
            pass
        return {}
    
    def detect_router(self) -> bool:
        """Detect if the router is available and accessible"""
        print_step("Detecting router...")
        
        if not self.ping_router():
            print_error(f"Router not reachable at {self.router_ip}")
            return False
        
        if not self.check_http_interface():
            print_error("Router web interface not accessible")
            return False
        
        self.router_info = self.get_router_info()
        self.router_found = True
        
        print_success(f"Router detected: {self.router_info.get('model', 'Unknown')}")
        print_info(f"Router IP: {self.router_ip}")
        return True

# ============================================================================
# FIRMWARE VALIDATION
# ============================================================================

class FirmwareValidator:
    """Validate firmware file before flashing"""
    
    def __init__(self, firmware_path: str):
        self.firmware_path = firmware_path
        self.firmware_size = 0
        self.firmware_hash = ""
    
    def check_file_exists(self) -> bool:
        """Check if firmware file exists"""
        if not os.path.exists(self.firmware_path):
            print_error(f"Firmware file not found: {self.firmware_path}")
            return False
        return True
    
    def validate_file_size(self) -> bool:
        """Validate firmware file size"""
        self.firmware_size = os.path.getsize(self.firmware_path)
        
        # Expected size range for router firmware (50MB - 200MB)
        min_size = 50 * 1024 * 1024  # 50MB
        max_size = 200 * 1024 * 1024  # 200MB
        
        if self.firmware_size < min_size:
            print_error(f"Firmware file too small: {self.firmware_size} bytes")
            return False
        
        if self.firmware_size > max_size:
            print_error(f"Firmware file too large: {self.firmware_size} bytes")
            return False
        
        print_info(f"Firmware size: {self.firmware_size / (1024*1024):.1f} MB")
        return True
    
    def calculate_hash(self) -> str:
        """Calculate SHA256 hash of firmware file"""
        print_step("Calculating firmware hash...")
        
        sha256_hash = hashlib.sha256()
        with open(self.firmware_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        
        self.firmware_hash = sha256_hash.hexdigest()
        print_info(f"Firmware hash: {self.firmware_hash[:16]}...")
        return self.firmware_hash
    
    def validate_firmware_header(self) -> bool:
        """Validate firmware file header"""
        try:
            with open(self.firmware_path, 'rb') as f:
                header = f.read(1024)
                
                # Check for common firmware signatures
                if b'DD-WRT' in header or b'LilithOS' in header:
                    print_success("Valid firmware header detected")
                    return True
                else:
                    print_warning("Unknown firmware header format")
                    return True  # Continue anyway
        except Exception as e:
            print_error(f"Error reading firmware header: {e}")
            return False
    
    def validate_firmware(self) -> bool:
        """Complete firmware validation"""
        print_step("Validating firmware file...")
        
        if not self.check_file_exists():
            return False
        
        if not self.validate_file_size():
            return False
        
        if not self.validate_firmware_header():
            return False
        
        self.calculate_hash()
        
        print_success("Firmware validation completed")
        return True

# ============================================================================
# BACKUP SYSTEM
# ============================================================================

class BackupManager:
    """Manage router configuration backups"""
    
    def __init__(self, backup_path: str):
        self.backup_path = Path(backup_path)
        self.backup_path.mkdir(exist_ok=True)
    
    def create_backup_filename(self) -> str:
        """Create timestamped backup filename"""
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        return f"router_backup_{timestamp}.tar.gz"
    
    def backup_configuration(self, router_ip: str) -> bool:
        """Backup current router configuration"""
        print_step("Creating configuration backup...")
        
        backup_file = self.backup_path / self.create_backup_filename()
        
        try:
            # Use curl to download configuration
            cmd = [
                'curl', '-s', '-o', str(backup_file),
                f'http://{router_ip}/backup.cgi'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0 and backup_file.exists():
                print_success(f"Configuration backed up to: {backup_file}")
                return True
            else:
                print_warning("Could not create automatic backup")
                return self.create_manual_backup(router_ip)
                
        except Exception as e:
            print_warning(f"Backup failed: {e}")
            return self.create_manual_backup(router_ip)
    
    def create_manual_backup(self, router_ip: str) -> bool:
        """Create manual backup instructions"""
        print_info("Manual backup required:")
        print_info(f"1. Open web browser and go to: http://{router_ip}")
        print_info("2. Login with admin credentials")
        print_info("3. Go to Administration > Backup Settings")
        print_info("4. Click 'Backup' to download configuration file")
        print_info("5. Save the file in a safe location")
        
        response = input("Have you completed the manual backup? (y/N): ")
        return response.lower() in ['y', 'yes']

# ============================================================================
# FIRMWARE FLASHING
# ============================================================================

class FirmwareFlasher:
    """Handle firmware flashing process"""
    
    def __init__(self, router_ip: str, firmware_path: str):
        self.router_ip = router_ip
        self.firmware_path = firmware_path
        self.flash_method = "http"
    
    def check_flash_methods(self) -> List[str]:
        """Check available flashing methods"""
        methods = []
        
        # Check HTTP method
        if self.check_http_flash():
            methods.append("http")
        
        # Check TFTP method
        if self.check_tftp_flash():
            methods.append("tftp")
        
        # Check SSH method
        if self.check_ssh_flash():
            methods.append("ssh")
        
        return methods
    
    def check_http_flash(self) -> bool:
        """Check if HTTP flashing is available"""
        try:
            import requests
            response = requests.get(f"http://{self.router_ip}/upgrade.cgi", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def check_tftp_flash(self) -> bool:
        """Check if TFTP flashing is available"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.settimeout(5)
            sock.sendto(b"", (self.router_ip, TFTP_PORT))
            return True
        except:
            return False
    
    def check_ssh_flash(self) -> bool:
        """Check if SSH flashing is available"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.router_ip, SSH_PORT))
            sock.close()
            return result == 0
        except:
            return False
    
    def flash_via_http(self) -> bool:
        """Flash firmware via HTTP interface"""
        print_step("Flashing firmware via HTTP...")
        
        try:
            import requests
            
            # Prepare firmware file
            with open(self.firmware_path, 'rb') as f:
                files = {'firmware': f}
                data = {'upgrade': '1'}
                
                # Upload firmware
                response = requests.post(
                    f"http://{self.router_ip}/upgrade.cgi",
                    files=files,
                    data=data,
                    timeout=300  # 5 minutes timeout
                )
                
                if response.status_code == 200:
                    print_success("Firmware upload completed")
                    return True
                else:
                    print_error(f"Upload failed with status: {response.status_code}")
                    return False
                    
        except Exception as e:
            print_error(f"HTTP flashing failed: {e}")
            return False
    
    def flash_via_tftp(self) -> bool:
        """Flash firmware via TFTP"""
        print_step("Flashing firmware via TFTP...")
        
        try:
            # Start TFTP server
            tftp_server = subprocess.Popen([
                'python3', '-m', 'http.server', '8080'
            ], cwd=os.path.dirname(self.firmware_path))
            
            # Wait for TFTP server to start
            time.sleep(2)
            
            # Trigger TFTP download on router
            # This would require router-specific commands
            
            print_warning("TFTP flashing requires manual intervention")
            print_info("Please configure router to download firmware via TFTP")
            
            tftp_server.terminate()
            return False
            
        except Exception as e:
            print_error(f"TFTP flashing failed: {e}")
            return False
    
    def flash_firmware(self) -> bool:
        """Main firmware flashing function"""
        print_step("Starting firmware flashing process...")
        
        # Check available methods
        methods = self.check_flash_methods()
        if not methods:
            print_error("No flashing methods available")
            return False
        
        print_info(f"Available flashing methods: {', '.join(methods)}")
        
        # Use HTTP method if available
        if "http" in methods:
            return self.flash_via_http()
        elif "tftp" in methods:
            return self.flash_via_tftp()
        else:
            print_error("No supported flashing methods available")
            return False

# ============================================================================
# POST-FLASH VERIFICATION
# ============================================================================

class PostFlashVerifier:
    """Verify successful firmware flashing"""
    
    def __init__(self, router_ip: str):
        self.router_ip = router_ip
        self.verification_timeout = 300  # 5 minutes
    
    def wait_for_router_reboot(self) -> bool:
        """Wait for router to reboot after flashing"""
        print_step("Waiting for router to reboot...")
        
        start_time = time.time()
        while time.time() - start_time < self.verification_timeout:
            if self.ping_router():
                print_success("Router is responding after reboot")
                return True
            time.sleep(5)
        
        print_error("Router did not respond after reboot")
        return False
    
    def ping_router(self) -> bool:
        """Ping router to check if it's responding"""
        try:
            if os.name == 'nt':  # Windows
                result = subprocess.run(['ping', '-n', '1', self.router_ip], 
                                      capture_output=True, text=True, timeout=10)
            else:  # Linux/Mac
                result = subprocess.run(['ping', '-c', '1', self.router_ip], 
                                      capture_output=True, text=True, timeout=10)
            
            return result.returncode == 0
        except:
            return False
    
    def verify_web_interface(self) -> bool:
        """Verify web interface is accessible"""
        print_step("Verifying web interface...")
        
        try:
            import requests
            response = requests.get(f"http://{self.router_ip}/", timeout=10)
            
            if response.status_code == 200:
                if "LilithOS" in response.text:
                    print_success("LilithOS web interface detected")
                    return True
                else:
                    print_warning("Web interface accessible but may not be LilithOS")
                    return True
            else:
                print_error(f"Web interface not accessible: {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Web interface verification failed: {e}")
            return False
    
    def verify_ssh_access(self) -> bool:
        """Verify SSH access is available"""
        print_step("Verifying SSH access...")
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            result = sock.connect_ex((self.router_ip, SSH_PORT))
            sock.close()
            
            if result == 0:
                print_success("SSH access verified")
                return True
            else:
                print_warning("SSH access not available")
                return False
                
        except Exception as e:
            print_error(f"SSH verification failed: {e}")
            return False
    
    def verify_flashing(self) -> bool:
        """Complete post-flash verification"""
        print_step("Verifying firmware flashing...")
        
        if not self.wait_for_router_reboot():
            return False
        
        if not self.verify_web_interface():
            return False
        
        self.verify_ssh_access()
        
        print_success("Firmware flashing verification completed")
        return True

# ============================================================================
# MAIN FLASHING PROCESS
# ============================================================================

class LilithOSRouterFlasher:
    """Main flashing orchestrator"""
    
    def __init__(self, firmware_path: str, router_ip: str = ROUTER_IP):
        self.firmware_path = firmware_path
        self.router_ip = router_ip
        self.detector = RouterDetector()
        self.validator = FirmwareValidator(firmware_path)
        self.backup_manager = BackupManager(BACKUP_PATH)
        self.flasher = FirmwareFlasher(router_ip, firmware_path)
        self.verifier = PostFlashVerifier(router_ip)
    
    def run_safety_checks(self) -> bool:
        """Run all safety checks before flashing"""
        print_step("Running safety checks...")
        
        # Check if running as administrator/root
        if os.name == 'nt':  # Windows
            try:
                import ctypes
                if not ctypes.windll.shell32.IsUserAnAdmin():
                    print_error("This tool must be run as Administrator")
                    return False
            except:
                print_warning("Could not verify administrator privileges")
        else:  # Linux/Mac
            if os.geteuid() != 0:
                print_error("This tool must be run as root")
                return False
        
        # Check network connectivity
        if not self.detector.ping_router():
            print_error("Router not reachable")
            return False
        
        # Validate firmware
        if not self.validator.validate_firmware():
            return False
        
        print_success("Safety checks passed")
        return True
    
    def confirm_flashing(self) -> bool:
        """Get user confirmation for flashing"""
        print_warning("WARNING: This will flash custom firmware to your router!")
        print_warning("This process may void your warranty and could potentially")
        print_warning("brick your router if interrupted.")
        print()
        print_info(f"Router: {ROUTER_MODEL}")
        print_info(f"Router IP: {self.router_ip}")
        print_info(f"Firmware: {self.firmware_path}")
        print()
        
        response = input("Do you want to continue with flashing? (yes/NO): ")
        return response.lower() == 'yes'
    
    def flash_router(self) -> bool:
        """Main flashing process"""
        print_info("Starting LilithOS Router Firmware Flashing Tool")
        print_info(f"Target: {ROUTER_MODEL}")
        print_info(f"Router IP: {self.router_ip}")
        print()
        
        # Run safety checks
        if not self.run_safety_checks():
            return False
        
        # Get user confirmation
        if not self.confirm_flashing():
            print_info("Flashing cancelled by user")
            return False
        
        # Create backup
        if not self.backup_manager.backup_configuration(self.router_ip):
            print_warning("Backup failed, but continuing with flashing")
        
        # Flash firmware
        if not self.flasher.flash_firmware():
            print_error("Firmware flashing failed")
            return False
        
        # Verify flashing
        if not self.verifier.verify_flashing():
            print_error("Firmware verification failed")
            return False
        
        print_success("LilithOS Router firmware flashing completed successfully!")
        print_info("Router is now running LilithOS firmware")
        print_info(f"Web interface: http://{self.router_ip}")
        print_info("Default credentials: admin / password")
        
        return True

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="LilithOS Router Firmware Flashing Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --firmware firmware.bin
  %(prog)s --router-ip 192.168.1.1 --firmware firmware.bin
  %(prog)s --check-only
        """
    )
    
    parser.add_argument(
        '--firmware', '-f',
        default=FIRMWARE_PATH,
        help='Path to firmware file (default: %(default)s)'
    )
    
    parser.add_argument(
        '--router-ip', '-r',
        default=ROUTER_IP,
        help='Router IP address (default: %(default)s)'
    )
    
    parser.add_argument(
        '--check-only', '-c',
        action='store_true',
        help='Only check router and firmware, do not flash'
    )
    
    parser.add_argument(
        '--backup-only', '-b',
        action='store_true',
        help='Only create backup, do not flash'
    )
    
    args = parser.parse_args()
    
    # Create flasher instance
    flasher = LilithOSRouterFlasher(args.firmware, args.router_ip)
    
    if args.check_only:
        # Only run checks
        print_info("Running router and firmware checks only...")
        flasher.run_safety_checks()
        return 0
    
    elif args.backup_only:
        # Only create backup
        print_info("Creating backup only...")
        if flasher.backup_manager.backup_configuration(args.router_ip):
            print_success("Backup completed successfully")
            return 0
        else:
            print_error("Backup failed")
            return 1
    
    else:
        # Full flashing process
        if flasher.flash_router():
            return 0
        else:
            return 1

if __name__ == "__main__":
    sys.exit(main()) 