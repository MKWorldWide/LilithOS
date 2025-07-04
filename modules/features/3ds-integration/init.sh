#!/bin/bash

# 🌑 LilithOS 3DS Integration Module - Initialization Script
# Comprehensive 3DS R4 flashcard integration for LilithOS
# Supports R4 flashcard, Luma CFW, homebrew ecosystem, and network capabilities

set -e

# Configuration
MODULE_NAME="3ds-integration"
MODULE_VERSION="1.0.0"
LILITHOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MODULE_DIR="$LILITHOS_ROOT/modules/features/$MODULE_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Initialize module
init_module() {
    log_header "Initializing LilithOS 3DS Integration Module"
    
    # Create module directory structure
    create_directory_structure
    
    # Install dependencies
    install_dependencies
    
    # Configure system
    configure_system
    
    # Initialize components
    initialize_components
    
    log_success "3DS Integration Module initialized successfully"
}

# Create directory structure
create_directory_structure() {
    log_info "Creating module directory structure..."
    
    local dirs=(
        "gui"
        "core"
        "ftp"
        "games"
        "emulation"
        "multimedia"
        "network"
        "config"
        "docs"
        "tools"
        "backup"
        "logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$MODULE_DIR/$dir"
        log_info "Created directory: $dir"
    done
}

# Install dependencies
install_dependencies() {
    log_info "Installing 3DS integration dependencies..."
    
    # Check for required tools
    local required_tools=("python3" "curl" "wget" "unzip" "7z")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_warning "Required tool not found: $tool"
            # Install based on system
            if command -v apt-get &> /dev/null; then
                sudo apt-get install -y "$tool"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "$tool"
            elif command -v brew &> /dev/null; then
                brew install "$tool"
            fi
        fi
    done
    
    # Install Python dependencies
    if [ -f "$MODULE_DIR/requirements.txt" ]; then
        pip3 install -r "$MODULE_DIR/requirements.txt"
    fi
}

# Configure system
configure_system() {
    log_info "Configuring 3DS integration system..."
    
    # Create configuration files
    create_config_files
    
    # Set up network configuration
    setup_network_config
    
    # Configure file paths
    setup_file_paths
}

# Create configuration files
create_config_files() {
    log_info "Creating configuration files..."
    
    # Main configuration
    cat > "$MODULE_DIR/config/3ds_config.yaml" << 'EOF'
# LilithOS 3DS Integration Configuration

# System Configuration
system:
  target_firmware: "11.17.0-50U"
  device_type: "3DS XL"
  cfw_type: "Luma CFW"
  r4_version: "2016-08-30"

# Network Configuration
network:
  ftp_port: 5000
  ftp_timeout: 30
  auto_connect: true
  wifi_scan_interval: 60

# File Management
files:
  nds_directory: "/NDS/"
  gba_directory: "/GBA/"
  homebrew_directory: "/3ds/"
  multimedia_directory: "/moonshl2/"
  retroarch_directory: "/retroarch/"
  
# Game Management
games:
  auto_backup_saves: true
  save_backup_interval: 3600
  max_backup_count: 10
  rts_enabled: true

# Emulation Settings
emulation:
  gba_bios_path: "/retroarch/cores/system/gba_bios.bin"
  gbarunner2_path: "/GBA/GBARunner2_arm9dldi_ds.nds"
  retroarch_cores: ["snes", "n64", "gba"]
  
# Multimedia Settings
multimedia:
  supported_formats: ["mp3", "mp4", "jpg", "png", "gif"]
  plugin_support: true
  language_support: ["en", "zh", "ja", "fr", "de", "it", "es", "nl"]

# Security Settings
security:
  backup_before_modify: true
  verify_file_integrity: true
  log_all_operations: true
  encryption_enabled: false
EOF

    # FTP configuration
    cat > "$MODULE_DIR/config/ftp_config.yaml" << 'EOF'
# FTP Configuration for 3DS Integration

ftp:
  server:
    port: 5000
    timeout: 30
    max_connections: 5
    passive_mode: true
    
  client:
    retry_attempts: 3
    retry_delay: 5
    chunk_size: 8192
    progress_callback: true
    
  security:
    anonymous_access: true
    encryption: false
    log_transfers: true
EOF

    # Game database configuration
    cat > "$MODULE_DIR/config/games_db.yaml" << 'EOF'
# Game Database Configuration

database:
  type: "sqlite"
  path: "games.db"
  auto_backup: true
  
games:
  nds:
    save_format: ".sav"
    save_size: 524288
    rts_support: true
    
  gba:
    save_format: ".sav"
    save_size: 131072
    bios_required: true
    
  emulation:
    retroarch_cores: ["snes", "n64", "gba"]
    save_states: true
    cheats: true
EOF
}

# Setup network configuration
setup_network_config() {
    log_info "Setting up network configuration..."
    
    # Create network detection script
    cat > "$MODULE_DIR/network/network_detector.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS Network Detection Module
Detects and manages 3DS network connectivity
"""

import socket
import subprocess
import threading
import time
from typing import Dict, Optional

class NetworkDetector:
    def __init__(self):
        self.connected_devices = {}
        self.scan_interval = 60
        self.is_scanning = False
        
    def scan_network(self) -> Dict[str, Dict]:
        """Scan network for 3DS devices"""
        devices = {}
        
        # Scan common 3DS ports
        ports = [5000, 8080, 80]  # FTP, HTTP, standard
        
        # Get local network range
        local_ip = self.get_local_ip()
        if local_ip:
            network_base = '.'.join(local_ip.split('.')[:-1])
            
            for i in range(1, 255):
                ip = f"{network_base}.{i}"
                for port in ports:
                    if self.check_port(ip, port):
                        device_info = self.identify_device(ip, port)
                        if device_info:
                            devices[ip] = device_info
                            
        return devices
    
    def get_local_ip(self) -> Optional[str]:
        """Get local IP address"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return None
    
    def check_port(self, ip: str, port: int) -> bool:
        """Check if port is open on IP"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((ip, port))
            sock.close()
            return result == 0
        except:
            return False
    
    def identify_device(self, ip: str, port: int) -> Optional[Dict]:
        """Identify if device is a 3DS"""
        try:
            if port == 5000:
                # Try FTP connection
                return {"type": "3ds", "service": "ftp", "port": port}
            elif port == 8080:
                # Try HTTP connection
                return {"type": "3ds", "service": "http", "port": port}
        except:
            pass
        return None
    
    def start_scanning(self):
        """Start continuous network scanning"""
        self.is_scanning = True
        threading.Thread(target=self._scan_loop, daemon=True).start()
    
    def stop_scanning(self):
        """Stop network scanning"""
        self.is_scanning = False
    
    def _scan_loop(self):
        """Continuous scanning loop"""
        while self.is_scanning:
            self.connected_devices = self.scan_network()
            time.sleep(self.scan_interval)

if __name__ == "__main__":
    detector = NetworkDetector()
    detector.start_scanning()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        detector.stop_scanning()
EOF

    chmod +x "$MODULE_DIR/network/network_detector.py"
}

# Setup file paths
setup_file_paths() {
    log_info "Setting up file paths..."
    
    # Create file path configuration
    cat > "$MODULE_DIR/config/paths.yaml" << 'EOF'
# File Path Configuration

paths:
  # 3DS SD Card paths
  nds_games: "/NDS/"
  gba_games: "/GBA/"
  homebrew_apps: "/3ds/"
  multimedia: "/moonshl2/"
  retroarch: "/retroarch/"
  luma: "/luma/"
  
  # Local LilithOS paths
  local_backup: "./backup/"
  local_games: "./games/"
  local_config: "./config/"
  local_logs: "./logs/"
  
  # System files
  r4_dat: "/R4.dat"
  boot_3dsx: "/boot.3dsx"
  boot_firm: "/boot.firm"
  usm_bin: "/usm.bin"
  slots_bin: "/slots.bin"
EOF
}

# Initialize components
initialize_components() {
    log_info "Initializing 3DS integration components..."
    
    # Initialize FTP bridge
    init_ftp_bridge
    
    # Initialize game manager
    init_game_manager
    
    # Initialize emulation hub
    init_emulation_hub
    
    # Initialize multimedia system
    init_multimedia_system
    
    # Initialize network manager
    init_network_manager
}

# Initialize FTP bridge
init_ftp_bridge() {
    log_info "Initializing FTP bridge..."
    
    cat > "$MODULE_DIR/ftp/ftp_bridge.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS FTP Bridge Module
Manages FTP connections to 3DS devices
"""

import ftplib
import os
import threading
import time
from typing import Dict, List, Optional
from pathlib import Path

class FTPBridge:
    def __init__(self, host: str, port: int = 5000):
        self.host = host
        self.port = port
        self.connection = None
        self.is_connected = False
        self.transfer_progress = 0
        
    def connect(self, username: str = "", password: str = "") -> bool:
        """Connect to 3DS FTP server"""
        try:
            self.connection = ftplib.FTP()
            self.connection.connect(self.host, self.port, timeout=30)
            self.connection.login(username, password)
            self.is_connected = True
            return True
        except Exception as e:
            print(f"FTP connection failed: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from FTP server"""
        if self.connection:
            self.connection.quit()
            self.connection = None
            self.is_connected = False
    
    def list_files(self, path: str = "/") -> List[Dict]:
        """List files in directory"""
        if not self.is_connected:
            return []
        
        try:
            files = []
            self.connection.cwd(path)
            self.connection.retrlines('LIST', lambda x: files.append(self._parse_listing(x)))
            return files
        except Exception as e:
            print(f"Error listing files: {e}")
            return []
    
    def upload_file(self, local_path: str, remote_path: str, callback=None) -> bool:
        """Upload file to 3DS"""
        if not self.is_connected:
            return False
        
        try:
            with open(local_path, 'rb') as f:
                self.connection.storbinary(f'STOR {remote_path}', f, callback=callback)
            return True
        except Exception as e:
            print(f"Upload failed: {e}")
            return False
    
    def download_file(self, remote_path: str, local_path: str, callback=None) -> bool:
        """Download file from 3DS"""
        if not self.is_connected:
            return False
        
        try:
            with open(local_path, 'wb') as f:
                self.connection.retrbinary(f'RETR {remote_path}', f.write, callback=callback)
            return True
        except Exception as e:
            print(f"Download failed: {e}")
            return False
    
    def _parse_listing(self, line: str) -> Dict:
        """Parse FTP LIST output"""
        parts = line.split()
        if len(parts) >= 9:
            return {
                'permissions': parts[0],
                'size': parts[4],
                'date': ' '.join(parts[5:8]),
                'name': parts[8],
                'is_dir': parts[0].startswith('d')
            }
        return {'name': line}

class FTPManager:
    def __init__(self):
        self.bridges = {}
        self.active_transfers = {}
        
    def create_bridge(self, host: str, port: int = 5000) -> FTPBridge:
        """Create new FTP bridge"""
        bridge = FTPBridge(host, port)
        self.bridges[host] = bridge
        return bridge
    
    def get_bridge(self, host: str) -> Optional[FTPBridge]:
        """Get existing bridge"""
        return self.bridges.get(host)
    
    def close_bridge(self, host: str):
        """Close FTP bridge"""
        if host in self.bridges:
            self.bridges[host].disconnect()
            del self.bridges[host]
    
    def close_all(self):
        """Close all bridges"""
        for bridge in self.bridges.values():
            bridge.disconnect()
        self.bridges.clear()

if __name__ == "__main__":
    # Test FTP bridge
    manager = FTPManager()
    bridge = manager.create_bridge("192.168.1.100")
    
    if bridge.connect():
        print("Connected to 3DS FTP server")
        files = bridge.list_files("/NDS/")
        print(f"Found {len(files)} files in NDS directory")
        bridge.disconnect()
    else:
        print("Failed to connect to 3DS FTP server")
EOF

    chmod +x "$MODULE_DIR/ftp/ftp_bridge.py"
}

# Initialize game manager
init_game_manager() {
    log_info "Initializing game manager..."
    
    cat > "$MODULE_DIR/games/game_manager.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS Game Manager Module
Manages game libraries and save files
"""

import os
import sqlite3
import json
import shutil
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

class GameManager:
    def __init__(self, db_path: str = "games.db"):
        self.db_path = db_path
        self.init_database()
        
    def init_database(self):
        """Initialize game database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create games table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS games (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                platform TEXT NOT NULL,
                file_path TEXT NOT NULL,
                save_path TEXT,
                size INTEGER,
                added_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_played DATETIME,
                play_count INTEGER DEFAULT 0
            )
        ''')
        
        # Create saves table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS saves (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                game_id INTEGER,
                save_path TEXT NOT NULL,
                backup_path TEXT,
                created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (game_id) REFERENCES games (id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def scan_games(self, directory: str, platform: str) -> List[Dict]:
        """Scan directory for games"""
        games = []
        game_extensions = {
            'nds': ['.nds'],
            'gba': ['.gba', '.GBA'],
            '3ds': ['.3ds', '.cia']
        }
        
        if platform not in game_extensions:
            return games
        
        for ext in game_extensions[platform]:
            for file_path in Path(directory).rglob(f"*{ext}"):
                game_info = self._extract_game_info(file_path, platform)
                if game_info:
                    games.append(game_info)
        
        return games
    
    def _extract_game_info(self, file_path: Path, platform: str) -> Optional[Dict]:
        """Extract game information from file"""
        try:
            # Extract title from filename
            title = file_path.stem
            
            # Look for save file
            save_path = None
            if platform == 'nds':
                save_file = file_path.with_suffix('.sav')
                if save_file.exists():
                    save_path = str(save_file)
            elif platform == 'gba':
                save_file = file_path.with_suffix('.sav')
                if save_file.exists():
                    save_path = str(save_file)
            
            return {
                'title': title,
                'platform': platform,
                'file_path': str(file_path),
                'save_path': save_path,
                'size': file_path.stat().st_size
            }
        except Exception as e:
            print(f"Error extracting game info: {e}")
            return None
    
    def add_game(self, game_info: Dict) -> bool:
        """Add game to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO games (title, platform, file_path, save_path, size)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                game_info['title'],
                game_info['platform'],
                game_info['file_path'],
                game_info.get('save_path'),
                game_info.get('size', 0)
            ))
            
            game_id = cursor.lastrowid
            
            # Add save file if exists
            if game_info.get('save_path'):
                cursor.execute('''
                    INSERT INTO saves (game_id, save_path)
                    VALUES (?, ?)
                ''', (game_id, game_info['save_path']))
            
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"Error adding game: {e}")
            return False
    
    def get_games(self, platform: Optional[str] = None) -> List[Dict]:
        """Get games from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        if platform:
            cursor.execute('SELECT * FROM games WHERE platform = ?', (platform,))
        else:
            cursor.execute('SELECT * FROM games')
        
        games = []
        for row in cursor.fetchall():
            games.append({
                'id': row[0],
                'title': row[1],
                'platform': row[2],
                'file_path': row[3],
                'save_path': row[4],
                'size': row[5],
                'added_date': row[6],
                'last_played': row[7],
                'play_count': row[8]
            })
        
        conn.close()
        return games
    
    def backup_save(self, game_id: int, backup_dir: str) -> bool:
        """Backup game save file"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT save_path FROM saves WHERE game_id = ?', (game_id,))
            save_path = cursor.fetchone()
            
            if save_path and os.path.exists(save_path[0]):
                backup_path = os.path.join(
                    backup_dir,
                    f"save_{game_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sav"
                )
                shutil.copy2(save_path[0], backup_path)
                
                # Update database
                cursor.execute('''
                    UPDATE saves SET backup_path = ? WHERE game_id = ?
                ''', (backup_path, game_id))
                
                conn.commit()
                conn.close()
                return True
        except Exception as e:
            print(f"Error backing up save: {e}")
        
        return False

if __name__ == "__main__":
    # Test game manager
    manager = GameManager()
    
    # Scan for games
    nds_games = manager.scan_games("/NDS/", "nds")
    gba_games = manager.scan_games("/GBA/", "gba")
    
    print(f"Found {len(nds_games)} NDS games")
    print(f"Found {len(gba_games)} GBA games")
    
    # Add games to database
    for game in nds_games + gba_games:
        manager.add_game(game)
EOF

    chmod +x "$MODULE_DIR/games/game_manager.py"
}

# Initialize emulation hub
init_emulation_hub() {
    log_info "Initializing emulation hub..."
    
    cat > "$MODULE_DIR/emulation/emulation_hub.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS Emulation Hub Module
Manages multi-platform emulation
"""

import os
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Optional

class EmulationHub:
    def __init__(self):
        self.emulators = {
            'gba': {
                'name': 'GBARunner2',
                'file': 'GBARunner2_arm9dldi_ds.nds',
                'bios_required': True,
                'bios_file': 'gba_bios.bin'
            },
            'snes': {
                'name': 'RetroArch SNES',
                'core': 'snes9x_libretro.so',
                'bios_required': False
            },
            'n64': {
                'name': 'RetroArch N64',
                'core': 'mupen64plus_libretro.so',
                'bios_required': False
            }
        }
        
        self.retroarch_path = "/retroarch/"
        self.gba_path = "/GBA/"
        
    def get_available_emulators(self) -> List[str]:
        """Get list of available emulators"""
        available = []
        
        for platform, config in self.emulators.items():
            if self._check_emulator_available(platform, config):
                available.append(platform)
        
        return available
    
    def _check_emulator_available(self, platform: str, config: Dict) -> bool:
        """Check if emulator is available"""
        if platform == 'gba':
            gbarunner_path = os.path.join(self.gba_path, config['file'])
            bios_path = os.path.join(self.retroarch_path, "cores/system", config['bios_file'])
            
            return (os.path.exists(gbarunner_path) and 
                   (not config['bios_required'] or os.path.exists(bios_path)))
        
        elif platform in ['snes', 'n64']:
            core_path = os.path.join(self.retroarch_path, "cores", config['core'])
            return os.path.exists(core_path)
        
        return False
    
    def launch_game(self, game_path: str, platform: str) -> bool:
        """Launch game with appropriate emulator"""
        if platform not in self.emulators:
            print(f"Unsupported platform: {platform}")
            return False
        
        config = self.emulators[platform]
        
        if platform == 'gba':
            return self._launch_gba_game(game_path, config)
        elif platform in ['snes', 'n64']:
            return self._launch_retroarch_game(game_path, platform, config)
        
        return False
    
    def _launch_gba_game(self, game_path: str, config: Dict) -> bool:
        """Launch GBA game with GBARunner2"""
        try:
            gbarunner_path = os.path.join(self.gba_path, config['file'])
            
            # GBARunner2 expects the GBA file to be in the same directory
            game_dir = os.path.dirname(game_path)
            game_name = os.path.basename(game_path)
            
            # Launch GBARunner2 with the game
            cmd = [gbarunner_path, game_name]
            subprocess.Popen(cmd, cwd=game_dir)
            
            return True
        except Exception as e:
            print(f"Error launching GBA game: {e}")
            return False
    
    def _launch_retroarch_game(self, game_path: str, platform: str, config: Dict) -> bool:
        """Launch game with RetroArch"""
        try:
            retroarch_exe = os.path.join(self.retroarch_path, "retroarch")
            core_path = os.path.join(self.retroarch_path, "cores", config['core'])
            
            cmd = [retroarch_exe, "-L", core_path, game_path]
            subprocess.Popen(cmd)
            
            return True
        except Exception as e:
            print(f"Error launching RetroArch game: {e}")
            return False
    
    def get_game_compatibility(self, game_path: str, platform: str) -> Dict:
        """Check game compatibility"""
        compatibility = {
            'compatible': False,
            'emulator': None,
            'issues': []
        }
        
        if platform not in self.emulators:
            compatibility['issues'].append(f"Unsupported platform: {platform}")
            return compatibility
        
        config = self.emulators[platform]
        
        # Check if emulator is available
        if not self._check_emulator_available(platform, config):
            compatibility['issues'].append(f"Emulator not available: {config['name']}")
            return compatibility
        
        # Check if game file exists
        if not os.path.exists(game_path):
            compatibility['issues'].append("Game file not found")
            return compatibility
        
        # Check BIOS requirements
        if config.get('bios_required'):
            bios_path = os.path.join(self.retroarch_path, "cores/system", config['bios_file'])
            if not os.path.exists(bios_path):
                compatibility['issues'].append(f"BIOS file required: {config['bios_file']}")
                return compatibility
        
        compatibility['compatible'] = True
        compatibility['emulator'] = config['name']
        
        return compatibility
    
    def get_emulator_info(self, platform: str) -> Optional[Dict]:
        """Get emulator information"""
        if platform not in self.emulators:
            return None
        
        config = self.emulators[platform]
        available = self._check_emulator_available(platform, config)
        
        return {
            'platform': platform,
            'name': config['name'],
            'available': available,
            'bios_required': config.get('bios_required', False),
            'bios_file': config.get('bios_file')
        }

if __name__ == "__main__":
    # Test emulation hub
    hub = EmulationHub()
    
    available = hub.get_available_emulators()
    print(f"Available emulators: {available}")
    
    for platform in available:
        info = hub.get_emulator_info(platform)
        print(f"{platform}: {info}")
EOF

    chmod +x "$MODULE_DIR/emulation/emulation_hub.py"
}

# Initialize multimedia system
init_multimedia_system() {
    log_info "Initializing multimedia system..."
    
    cat > "$MODULE_DIR/multimedia/multimedia_manager.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS Multimedia Manager Module
Manages media playback and Moonshell2 integration
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional

class MultimediaManager:
    def __init__(self):
        self.moonshell_path = "/moonshl2/"
        self.supported_formats = {
            'audio': ['.mp3', '.wav', '.ogg', '.flac'],
            'video': ['.mp4', '.avi', '.mkv', '.mov'],
            'image': ['.jpg', '.jpeg', '.png', '.gif', '.bmp']
        }
        
    def scan_media_files(self, directory: str) -> Dict[str, List[str]]:
        """Scan directory for media files"""
        media_files = {
            'audio': [],
            'video': [],
            'image': []
        }
        
        for media_type, extensions in self.supported_formats.items():
            for ext in extensions:
                for file_path in Path(directory).rglob(f"*{ext}"):
                    media_files[media_type].append(str(file_path))
        
        return media_files
    
    def get_moonshell_config(self) -> Dict:
        """Get Moonshell2 configuration"""
        config_path = os.path.join(self.moonshell_path, "moonshl2.ini")
        config = {
            'language': 'en',
            'skin': 'default',
            'plugins_enabled': True,
            'font_path': None
        }
        
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    for line in f:
                        if '=' in line:
                            key, value = line.strip().split('=', 1)
                            config[key.lower()] = value
            except Exception as e:
                print(f"Error reading Moonshell2 config: {e}")
        
        return config
    
    def get_available_plugins(self) -> List[str]:
        """Get available Moonshell2 plugins"""
        plugins = []
        plugins_dir = os.path.join(self.moonshell_path, "plugins")
        
        if os.path.exists(plugins_dir):
            for item in os.listdir(plugins_dir):
                if item.endswith('.pak'):
                    plugins.append(item)
        
        return plugins
    
    def get_language_files(self) -> List[str]:
        """Get available language files"""
        languages = []
        lang_dir = os.path.join(self.moonshell_path, "language")
        
        if os.path.exists(lang_dir):
            for item in os.listdir(lang_dir):
                if item.endswith('.lng'):
                    languages.append(item.replace('.lng', ''))
        
        return languages
    
    def create_playlist(self, media_files: List[str], playlist_path: str) -> bool:
        """Create media playlist"""
        try:
            with open(playlist_path, 'w') as f:
                for file_path in media_files:
                    f.write(f"{file_path}\n")
            return True
        except Exception as e:
            print(f"Error creating playlist: {e}")
            return False
    
    def get_media_info(self, file_path: str) -> Optional[Dict]:
        """Get media file information"""
        try:
            path = Path(file_path)
            if not path.exists():
                return None
            
            # Determine media type
            media_type = None
            for mtype, extensions in self.supported_formats.items():
                if path.suffix.lower() in extensions:
                    media_type = mtype
                    break
            
            if not media_type:
                return None
            
            stat = path.stat()
            
            return {
                'path': str(path),
                'name': path.name,
                'type': media_type,
                'size': stat.st_size,
                'modified': stat.st_mtime
            }
        except Exception as e:
            print(f"Error getting media info: {e}")
            return None
    
    def organize_media(self, source_dir: str, target_dir: str) -> Dict[str, int]:
        """Organize media files by type"""
        organized = {'audio': 0, 'video': 0, 'image': 0, 'other': 0}
        
        for media_type, extensions in self.supported_formats.items():
            type_dir = os.path.join(target_dir, media_type)
            os.makedirs(type_dir, exist_ok=True)
            
            for ext in extensions:
                for file_path in Path(source_dir).rglob(f"*{ext}"):
                    try:
                        target_path = os.path.join(type_dir, file_path.name)
                        if not os.path.exists(target_path):
                            os.rename(str(file_path), target_path)
                            organized[media_type] += 1
                    except Exception as e:
                        print(f"Error organizing {file_path}: {e}")
        
        return organized

if __name__ == "__main__":
    # Test multimedia manager
    manager = MultimediaManager()
    
    # Scan for media files
    media_files = manager.scan_media_files("/moonshl2/")
    
    print("Media files found:")
    for media_type, files in media_files.items():
        print(f"{media_type}: {len(files)} files")
    
    # Get Moonshell2 config
    config = manager.get_moonshell_config()
    print(f"Moonshell2 config: {config}")
    
    # Get plugins
    plugins = manager.get_available_plugins()
    print(f"Available plugins: {plugins}")
    
    # Get languages
    languages = manager.get_language_files()
    print(f"Available languages: {languages}")
EOF

    chmod +x "$MODULE_DIR/multimedia/multimedia_manager.py"
}

# Initialize network manager
init_network_manager() {
    log_info "Initializing network manager..."
    
    cat > "$MODULE_DIR/network/network_manager.py" << 'EOF'
#!/usr/bin/env python3
"""
3DS Network Manager Module
Manages network connectivity and services
"""

import socket
import threading
import time
import subprocess
from typing import Dict, List, Optional

class NetworkManager:
    def __init__(self):
        self.connected_devices = {}
        self.services = {
            'ftp': {'port': 5000, 'active': False},
            'http': {'port': 8080, 'active': False},
            'ssh': {'port': 22, 'active': False}
        }
        self.scan_thread = None
        self.is_scanning = False
        
    def start_device_scanning(self):
        """Start scanning for 3DS devices"""
        if not self.is_scanning:
            self.is_scanning = True
            self.scan_thread = threading.Thread(target=self._scan_loop, daemon=True)
            self.scan_thread.start()
    
    def stop_device_scanning(self):
        """Stop scanning for devices"""
        self.is_scanning = False
        if self.scan_thread:
            self.scan_thread.join()
    
    def _scan_loop(self):
        """Continuous device scanning loop"""
        while self.is_scanning:
            self._scan_network()
            time.sleep(60)  # Scan every minute
    
    def _scan_network(self):
        """Scan network for 3DS devices"""
        # Get local network range
        local_ip = self._get_local_ip()
        if not local_ip:
            return
        
        network_base = '.'.join(local_ip.split('.')[:-1])
        
        for i in range(1, 255):
            if not self.is_scanning:
                break
                
            ip = f"{network_base}.{i}"
            device_info = self._check_device(ip)
            
            if device_info:
                self.connected_devices[ip] = device_info
    
    def _get_local_ip(self) -> Optional[str]:
        """Get local IP address"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return None
    
    def _check_device(self, ip: str) -> Optional[Dict]:
        """Check if IP has 3DS services"""
        device_info = {
            'ip': ip,
            'services': {},
            'last_seen': time.time()
        }
        
        for service, config in self.services.items():
            if self._check_port(ip, config['port']):
                device_info['services'][service] = {
                    'port': config['port'],
                    'active': True
                }
        
        # Only return if device has 3DS services
        if device_info['services']:
            return device_info
        
        return None
    
    def _check_port(self, ip: str, port: int) -> bool:
        """Check if port is open"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((ip, port))
            sock.close()
            return result == 0
        except:
            return False
    
    def get_connected_devices(self) -> Dict[str, Dict]:
        """Get currently connected devices"""
        # Remove stale devices (not seen in last 5 minutes)
        current_time = time.time()
        stale_devices = []
        
        for ip, device in self.connected_devices.items():
            if current_time - device['last_seen'] > 300:  # 5 minutes
                stale_devices.append(ip)
        
        for ip in stale_devices:
            del self.connected_devices[ip]
        
        return self.connected_devices
    
    def test_connection(self, ip: str, service: str = 'ftp') -> bool:
        """Test connection to specific service"""
        if service not in self.services:
            return False
        
        port = self.services[service]['port']
        return self._check_port(ip, port)
    
    def get_network_info(self) -> Dict:
        """Get network information"""
        local_ip = self._get_local_ip()
        
        return {
            'local_ip': local_ip,
            'connected_devices': len(self.connected_devices),
            'scanning_active': self.is_scanning,
            'services': self.services
        }

if __name__ == "__main__":
    # Test network manager
    manager = NetworkManager()
    
    print("Starting device scanning...")
    manager.start_device_scanning()
    
    try:
        while True:
            devices = manager.get_connected_devices()
            print(f"Connected devices: {len(devices)}")
            
            for ip, device in devices.items():
                print(f"  {ip}: {list(device['services'].keys())}")
            
            time.sleep(10)
    except KeyboardInterrupt:
        print("Stopping device scanning...")
        manager.stop_device_scanning()
EOF

    chmod +x "$MODULE_DIR/network/network_manager.py"
}

# Main execution
main() {
    log_header "LilithOS 3DS Integration Module"
    log_info "Module: $MODULE_NAME"
    log_info "Version: $MODULE_VERSION"
    log_info "Root: $LILITHOS_ROOT"
    
    # Check if running as root (for some operations)
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root - some operations may require elevated privileges"
    fi
    
    # Initialize module
    init_module
    
    log_success "3DS Integration Module setup complete!"
    log_info "Next steps:"
    log_info "1. Configure your 3DS device for FTP access"
    log_info "2. Run the GUI launcher: ./modules/features/3ds-integration/gui/launch.sh"
    log_info "3. Use the FTP bridge to connect to your 3DS"
    log_info "4. Manage games and save files through the integrated interface"
}

# Run main function
main "$@" 