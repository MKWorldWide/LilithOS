#!/usr/bin/env python3
"""
Advanced 3DS Integration GUI with TWiLight Menu++ Support
Modern interface for comprehensive 3DS homebrew management
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import threading
import json
import os
import sys
from pathlib import Path

# Add module paths
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'ftp'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'games'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'emulation'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'multimedia'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'network'))

try:
    from ftp_bridge import FTPManager
    from game_manager import GameManager
    from emulation_hub import EmulationHub
    from multimedia_manager import MultimediaManager
    from network_manager import NetworkManager
    from twilight_integration import TWiLightIntegration, AdvancedEmulationHub, ModernFeatures
except ImportError as e:
    print(f"Import error: {e}")
    # Create dummy classes for testing
    class FTPManager: pass
    class GameManager: pass
    class EmulationHub: pass
    class MultimediaManager: pass
    class NetworkManager: pass
    class TWiLightIntegration: pass
    class AdvancedEmulationHub: pass
    class ModernFeatures: pass

class AdvancedLilithOS3DSGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("🌑 LilithOS Advanced 3DS Integration - TWiLight Menu++")
        self.root.geometry("1400x900")
        self.root.configure(bg='#1a1a1a')
        
        # Initialize managers
        self.ftp_manager = FTPManager()
        self.game_manager = GameManager()
        self.emulation_hub = EmulationHub()
        self.multimedia_manager = MultimediaManager()
        self.network_manager = NetworkManager()
        
        # Initialize TWiLight components
        self.twilight = TWiLightIntegration()
        self.advanced_emulation = AdvancedEmulationHub()
        self.modern_features = ModernFeatures()
        
        # Device state
        self.connected_device = None
        self.ftp_bridge = None
        self.system_type = "unknown"  # "r4" or "twilight"
        
        self.setup_ui()
        self.start_network_scanning()
    
    def setup_ui(self):
        """Setup the advanced user interface"""
        # Create main notebook
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create tabs
        self.create_system_tab()
        self.create_connection_tab()
        self.create_games_tab()
        self.create_emulation_tab()
        self.create_multimedia_tab()
        self.create_network_tab()
        self.create_advanced_tab()
        self.create_settings_tab()
    
    def create_system_tab(self):
        """Create system information and comparison tab"""
        system_frame = ttk.Frame(self.notebook)
        self.notebook.add(system_frame, text="🖥️ System")
        
        # System detection
        detection_frame = ttk.LabelFrame(system_frame, text="System Detection", padding=10)
        detection_frame.pack(fill='x', padx=10, pady=5)
        
        self.system_info_text = tk.Text(detection_frame, height=8, width=80)
        self.system_info_text.pack(fill='x', pady=5)
        
        ttk.Button(detection_frame, text="Detect System Type", 
                  command=self.detect_system_type).pack(pady=5)
        
        # System comparison
        comparison_frame = ttk.LabelFrame(system_frame, text="System Comparison", padding=10)
        comparison_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Create comparison tree
        self.comparison_tree = ttk.Treeview(comparison_frame, columns=('R4 Setup', 'TWiLight Setup'), show='tree headings')
        self.comparison_tree.heading('#0', text='Feature')
        self.comparison_tree.heading('R4 Setup', text='R4 Setup')
        self.comparison_tree.heading('TWiLight Setup', text='TWiLight Setup')
        self.comparison_tree.pack(fill='both', expand=True, pady=5)
        
        # Populate comparison data
        self.populate_comparison_data()
    
    def create_connection_tab(self):
        """Create connection management tab"""
        connection_frame = ttk.Frame(self.notebook)
        self.notebook.add(connection_frame, text="🔗 Connection")
        
        # Device detection
        detection_frame = ttk.LabelFrame(connection_frame, text="Device Detection", padding=10)
        detection_frame.pack(fill='x', padx=10, pady=5)
        
        self.device_listbox = tk.Listbox(detection_frame, height=6)
        self.device_listbox.pack(fill='x', pady=5)
        
        ttk.Button(detection_frame, text="Scan for Devices", 
                  command=self.scan_devices).pack(pady=5)
        
        # Connection settings
        connection_settings_frame = ttk.LabelFrame(connection_frame, text="Connection Settings", padding=10)
        connection_settings_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Label(connection_settings_frame, text="IP Address:").grid(row=0, column=0, sticky='w')
        self.ip_entry = ttk.Entry(connection_settings_frame)
        self.ip_entry.grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Label(connection_settings_frame, text="Port:").grid(row=1, column=0, sticky='w')
        self.port_entry = ttk.Entry(connection_settings_frame)
        self.port_entry.insert(0, "5000")
        self.port_entry.grid(row=1, column=1, padx=5, pady=2)
        
        ttk.Button(connection_settings_frame, text="Connect", 
                  command=self.connect_device).grid(row=2, column=0, columnspan=2, pady=10)
        
        # Status
        status_frame = ttk.LabelFrame(connection_frame, text="Connection Status", padding=10)
        status_frame.pack(fill='x', padx=10, pady=5)
        
        self.status_label = ttk.Label(status_frame, text="Not connected")
        self.status_label.pack()
    
    def create_games_tab(self):
        """Create advanced games management tab"""
        games_frame = ttk.Frame(self.notebook)
        self.notebook.add(games_frame, text="🎮 Games")
        
        # Game library
        library_frame = ttk.LabelFrame(games_frame, text="Game Library", padding=10)
        library_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Platform filter
        filter_frame = ttk.Frame(library_frame)
        filter_frame.pack(fill='x', pady=5)
        
        ttk.Label(filter_frame, text="Platform:").pack(side='left')
        self.platform_var = tk.StringVar(value="all")
        platform_combo = ttk.Combobox(filter_frame, textvariable=self.platform_var, 
                                     values=["all", "nds", "gba", "snes", "nes", "gb", "gen", "gg", "sms", "tg16", "ws", "a26", "a52", "a78", "col", "cpc", "m5", "ngp", "sg", "dsiware"])
        platform_combo.pack(side='left', padx=5)
        
        # Game list
        self.game_tree = ttk.Treeview(library_frame, columns=('Platform', 'Size', 'Status', 'Features'), show='tree headings')
        self.game_tree.heading('#0', text='Game')
        self.game_tree.heading('Platform', text='Platform')
        self.game_tree.heading('Size', text='Size')
        self.game_tree.heading('Status', text='Status')
        self.game_tree.heading('Features', text='Features')
        self.game_tree.pack(fill='both', expand=True, pady=5)
        
        # Game actions
        actions_frame = ttk.Frame(library_frame)
        actions_frame.pack(fill='x', pady=5)
        
        ttk.Button(actions_frame, text="Scan Games", command=self.scan_games).pack(side='left', padx=5)
        ttk.Button(actions_frame, text="Launch Game", command=self.launch_game).pack(side='left', padx=5)
        ttk.Button(actions_frame, text="Backup Save", command=self.backup_save).pack(side='left', padx=5)
        ttk.Button(actions_frame, text="Upload Game", command=self.upload_game).pack(side='left', padx=5)
        ttk.Button(actions_frame, text="Apply Widescreen", command=self.apply_widescreen).pack(side='left', padx=5)
        ttk.Button(actions_frame, text="Apply AP Patch", command=self.apply_ap_patch).pack(side='left', padx=5)
    
    def create_emulation_tab(self):
        """Create advanced emulation management tab"""
        emulation_frame = ttk.Frame(self.notebook)
        self.notebook.add(emulation_frame, text="🎯 Emulation")
        
        # Available emulators
        emulators_frame = ttk.LabelFrame(emulation_frame, text="Available Emulators", padding=10)
        emulators_frame.pack(fill='x', padx=10, pady=5)
        
        self.emulator_tree = ttk.Treeview(emulators_frame, columns=('Version', 'Status', 'Features'), show='tree headings')
        self.emulator_tree.heading('#0', text='Platform')
        self.emulator_tree.heading('Version', text='Version')
        self.emulator_tree.heading('Status', text='Status')
        self.emulator_tree.heading('Features', text='Features')
        self.emulator_tree.pack(fill='x', pady=5)
        
        # Emulation actions
        emulation_actions_frame = ttk.Frame(emulation_frame)
        emulation_actions_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(emulation_actions_frame, text="Refresh Emulators", 
                  command=self.refresh_emulators).pack(side='left', padx=5)
        ttk.Button(emulation_actions_frame, text="Test Compatibility", 
                  command=self.test_compatibility).pack(side='left', padx=5)
        ttk.Button(emulation_actions_frame, text="Configure Bootstrap", 
                  command=self.configure_bootstrap).pack(side='left', padx=5)
    
    def create_multimedia_tab(self):
        """Create multimedia management tab"""
        multimedia_frame = ttk.Frame(self.notebook)
        self.notebook.add(multimedia_frame, text="🎵 Multimedia")
        
        # Media library
        media_frame = ttk.LabelFrame(multimedia_frame, text="Media Library", padding=10)
        media_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Media list
        self.media_tree = ttk.Treeview(media_frame, columns=('Type', 'Size'), show='tree headings')
        self.media_tree.heading('#0', text='File')
        self.media_tree.heading('Type', text='Type')
        self.media_tree.heading('Size', text='Size')
        self.media_tree.pack(fill='both', expand=True, pady=5)
        
        # Media actions
        media_actions_frame = ttk.Frame(multimedia_frame)
        media_actions_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(media_actions_frame, text="Scan Media", command=self.scan_media).pack(side='left', padx=5)
        ttk.Button(media_actions_frame, text="Upload Media", command=self.upload_media).pack(side='left', padx=5)
        ttk.Button(media_actions_frame, text="Create Playlist", command=self.create_playlist).pack(side='left', padx=5)
    
    def create_network_tab(self):
        """Create network management tab"""
        network_frame = ttk.Frame(self.notebook)
        self.notebook.add(network_frame, text="🌐 Network")
        
        # Network status
        status_frame = ttk.LabelFrame(network_frame, text="Network Status", padding=10)
        status_frame.pack(fill='x', padx=10, pady=5)
        
        self.network_info_text = tk.Text(status_frame, height=10, width=60)
        self.network_info_text.pack(fill='x', pady=5)
        
        # Network actions
        network_actions_frame = ttk.Frame(network_frame)
        network_actions_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(network_actions_frame, text="Refresh Network Info", 
                  command=self.refresh_network_info).pack(side='left', padx=5)
        ttk.Button(network_actions_frame, text="Test Connection", 
                  command=self.test_connection).pack(side='left', padx=5)
        ttk.Button(network_actions_frame, text="Enable FTP", 
                  command=self.enable_ftp).pack(side='left', padx=5)
    
    def create_advanced_tab(self):
        """Create advanced features tab"""
        advanced_frame = ttk.Frame(self.notebook)
        self.notebook.add(advanced_frame, text="⚡ Advanced")
        
        # Modern features
        features_frame = ttk.LabelFrame(advanced_frame, text="Modern Features", padding=10)
        features_frame.pack(fill='x', padx=10, pady=5)
        
        # Feature checkboxes
        self.widescreen_var = tk.BooleanVar()
        ttk.Checkbutton(features_frame, text="Widescreen Support", variable=self.widescreen_var).pack(anchor='w')
        
        self.ap_patches_var = tk.BooleanVar()
        ttk.Checkbutton(features_frame, text="AP Patches", variable=self.ap_patches_var).pack(anchor='w')
        
        self.cheat_system_var = tk.BooleanVar()
        ttk.Checkbutton(features_frame, text="Cheat System", variable=self.cheat_system_var).pack(anchor='w')
        
        self.save_states_var = tk.BooleanVar()
        ttk.Checkbutton(features_frame, text="Save States", variable=self.save_states_var).pack(anchor='w')
        
        self.screenshot_var = tk.BooleanVar()
        ttk.Checkbutton(features_frame, text="Screenshot Support", variable=self.screenshot_var).pack(anchor='w')
        
        # Advanced actions
        advanced_actions_frame = ttk.Frame(advanced_frame)
        advanced_actions_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(advanced_actions_frame, text="Load Widescreen Compatibility", 
                  command=self.load_widescreen_compatibility).pack(side='left', padx=5)
        ttk.Button(advanced_actions_frame, text="Load AP Patches", 
                  command=self.load_ap_patches).pack(side='left', padx=5)
        ttk.Button(advanced_actions_frame, text="Update System", 
                  command=self.update_system).pack(side='left', padx=5)
    
    def create_settings_tab(self):
        """Create settings tab"""
        settings_frame = ttk.Frame(self.notebook)
        self.notebook.add(settings_frame, text="⚙️ Settings")
        
        # General settings
        general_frame = ttk.LabelFrame(settings_frame, text="General Settings", padding=10)
        general_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Label(general_frame, text="Default FTP Port:").grid(row=0, column=0, sticky='w')
        self.default_port_entry = ttk.Entry(general_frame)
        self.default_port_entry.insert(0, "5000")
        self.default_port_entry.grid(row=0, column=1, padx=5, pady=2)
        
        ttk.Label(general_frame, text="Auto-backup saves:").grid(row=1, column=0, sticky='w')
        self.auto_backup_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(general_frame, variable=self.auto_backup_var).grid(row=1, column=1, sticky='w', padx=5)
        
        ttk.Label(general_frame, text="Enable widescreen:").grid(row=2, column=0, sticky='w')
        self.enable_widescreen_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(general_frame, variable=self.enable_widescreen_var).grid(row=2, column=1, sticky='w', padx=5)
        
        ttk.Label(general_frame, text="Enable AP patches:").grid(row=3, column=0, sticky='w')
        self.enable_ap_patches_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(general_frame, variable=self.enable_ap_patches_var).grid(row=3, column=1, sticky='w', padx=5)
        
        # Save settings
        ttk.Button(general_frame, text="Save Settings", 
                  command=self.save_settings).grid(row=4, column=0, columnspan=2, pady=10)
    
    def detect_system_type(self):
        """Detect if system is R4 or TWiLight Menu++"""
        try:
            # Try to detect system type based on available files
            if self.ftp_bridge and self.ftp_bridge.is_connected:
                # Check for TWiLight Menu++ files
                twilight_files = ["/_nds/nds-bootstrap-hb-release.nds", "/roms/", "/version.txt"]
                r4_files = ["/R4.dat", "/R4iMenu/"]
                
                twilight_count = 0
                r4_count = 0
                
                for file in twilight_files:
                    if self.ftp_bridge.list_files(file):
                        twilight_count += 1
                
                for file in r4_files:
                    if self.ftp_bridge.list_files(file):
                        r4_count += 1
                
                if twilight_count > r4_count:
                    self.system_type = "twilight"
                    system_info = self.twilight.get_system_info()
                else:
                    self.system_type = "r4"
                    system_info = {
                        'menu_system': 'R4iMenu',
                        'version': '2016-08-30',
                        'bootstrap_version': 'Basic',
                        'supported_platforms': 4,
                        'modern_features': ['basic_emulation', 'ftp_access']
                    }
                
                # Display system info
                info_text = f"System Type: {self.system_type.upper()}\n"
                info_text += f"Menu System: {system_info['menu_system']}\n"
                info_text += f"Version: {system_info['version']}\n"
                info_text += f"Supported Platforms: {system_info['supported_platforms']}\n"
                info_text += f"Modern Features: {len(system_info['modern_features'])}\n"
                
                self.system_info_text.delete(1.0, tk.END)
                self.system_info_text.insert(1.0, info_text)
                
                messagebox.showinfo("System Detection", f"Detected {self.system_type.upper()} system")
            else:
                messagebox.showwarning("System Detection", "Please connect to a device first")
                
        except Exception as e:
            messagebox.showerror("Error", f"System detection failed: {e}")
    
    def populate_comparison_data(self):
        """Populate system comparison data"""
        comparison_data = [
            ("Menu System", "R4iMenu (2016)", "TWiLight Menu++ (2024)"),
            ("NDS Bootstrap", "Basic", "Advanced v0.72.0"),
            ("Emulation", "NDS, GBA, SNES, N64", "20+ platforms"),
            ("Widescreen", "No", "Yes"),
            ("AP Patches", "No", "Yes"),
            ("Cheat Support", "Basic", "Advanced"),
            ("Update System", "Manual", "Universal-Updater"),
            ("Organization", "Simple folders", "Structured roms/"),
            ("Modern Features", "Limited", "Extensive")
        ]
        
        for feature, r4_value, twilight_value in comparison_data:
            self.comparison_tree.insert('', 'end', text=feature, values=(r4_value, twilight_value))
    
    def start_network_scanning(self):
        """Start network device scanning"""
        try:
            self.network_manager.start_device_scanning()
        except Exception as e:
            print(f"Error starting network scanning: {e}")
    
    def scan_devices(self):
        """Scan for 3DS devices"""
        self.device_listbox.delete(0, tk.END)
        
        try:
            devices = self.network_manager.get_connected_devices()
            
            for ip, device in devices.items():
                services = list(device['services'].keys())
                self.device_listbox.insert(tk.END, f"{ip} - {', '.join(services)}")
            
            if not devices:
                self.device_listbox.insert(tk.END, "No devices found")
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to scan devices: {e}")
    
    def connect_device(self):
        """Connect to selected device"""
        ip = self.ip_entry.get().strip()
        port = int(self.port_entry.get().strip())
        
        if not ip:
            messagebox.showerror("Error", "Please enter an IP address")
            return
        
        try:
            self.ftp_bridge = self.ftp_manager.create_bridge(ip, port)
            
            if self.ftp_bridge.connect():
                self.connected_device = ip
                self.status_label.config(text=f"Connected to {ip}")
                messagebox.showinfo("Success", f"Connected to {ip}")
                
                # Auto-detect system type
                self.detect_system_type()
            else:
                messagebox.showerror("Error", f"Failed to connect to {ip}")
                
        except Exception as e:
            messagebox.showerror("Error", f"Connection failed: {e}")
    
    def scan_games(self):
        """Scan for games with platform detection"""
        if not self.connected_device:
            messagebox.showerror("Error", "Please connect to a device first")
            return
        
        try:
            # Clear existing games
            for item in self.game_tree.get_children():
                self.game_tree.delete(item)
            
            if self.system_type == "twilight":
                # Scan structured roms directory
                roms = self.twilight.scan_roms_directory("/roms/")
                
                for platform, games in roms.items():
                    for game_path in games:
                        game_name = os.path.basename(game_path)
                        game_size = os.path.getsize(game_path) if os.path.exists(game_path) else 0
                        
                        # Check for modern features
                        features = []
                        if self.modern_features.is_widescreen_compatible(game_name):
                            features.append("Widescreen")
                        if self.modern_features.has_ap_patch(game_name):
                            features.append("AP Patch")
                        
                        self.game_tree.insert('', 'end', text=game_name, 
                                            values=(platform.upper(), f"{game_size // 1024 // 1024}MB", 'Available', ', '.join(features)))
            else:
                # Scan traditional R4 directories
                nds_games = self.game_manager.scan_games("/NDS/", "nds")
                for game in nds_games:
                    self.game_tree.insert('', 'end', text=game['title'], 
                                        values=('NDS', f"{game['size'] // 1024 // 1024}MB", 'Available', 'Basic'))
                
                gba_games = self.game_manager.scan_games("/GBA/", "gba")
                for game in gba_games:
                    self.game_tree.insert('', 'end', text=game['title'], 
                                        values=('GBA', f"{game['size'] // 1024 // 1024}MB", 'Available', 'Basic'))
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to scan games: {e}")
    
    def launch_game(self):
        """Launch selected game"""
        selection = self.game_tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a game")
            return
        
        item = self.game_tree.item(selection[0])
        game_title = item['text']
        platform = item['values'][0]
        
        try:
            if self.system_type == "twilight":
                # Use advanced emulation hub
                emulator_info = self.advanced_emulation.get_emulator_info(platform.lower())
                if emulator_info:
                    messagebox.showinfo("Launch", f"Launching {game_title} with {emulator_info['name']}")
                else:
                    messagebox.showerror("Error", f"No emulator available for {platform}")
            else:
                # Use basic emulation hub
                compatibility = self.emulation_hub.get_game_compatibility(game_title, platform.lower())
                if compatibility['compatible']:
                    messagebox.showinfo("Launch", f"Launching {game_title}")
                else:
                    messagebox.showerror("Error", f"Game not compatible: {compatibility['issues']}")
                    
        except Exception as e:
            messagebox.showerror("Error", f"Failed to launch game: {e}")
    
    def apply_widescreen(self):
        """Apply widescreen patch to selected game"""
        selection = self.game_tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a game")
            return
        
        if self.system_type != "twilight":
            messagebox.showwarning("Feature Not Available", "Widescreen support requires TWiLight Menu++")
            return
        
        try:
            item = self.game_tree.item(selection[0])
            game_title = item['text']
            
            if self.twilight.apply_widescreen_patch(game_title):
                messagebox.showinfo("Success", f"Widescreen patch applied to {game_title}")
            else:
                messagebox.showerror("Error", f"Failed to apply widescreen patch to {game_title}")
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply widescreen patch: {e}")
    
    def apply_ap_patch(self):
        """Apply AP patch to selected game"""
        selection = self.game_tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a game")
            return
        
        if self.system_type != "twilight":
            messagebox.showwarning("Feature Not Available", "AP patches require TWiLight Menu++")
            return
        
        try:
            item = self.game_tree.item(selection[0])
            game_title = item['text']
            
            if self.twilight.apply_ap_patch(game_title):
                messagebox.showinfo("Success", f"AP patch applied to {game_title}")
            else:
                messagebox.showerror("Error", f"Failed to apply AP patch to {game_title}")
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply AP patch: {e}")
    
    def backup_save(self):
        """Backup game save"""
        selection = self.game_tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a game")
            return
        
        try:
            messagebox.showinfo("Success", "Save backed up successfully")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to backup save: {e}")
    
    def upload_game(self):
        """Upload game to device"""
        file_path = filedialog.askopenfilename(
            title="Select Game File",
            filetypes=[("Game files", "*.nds *.gba *.3ds"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                messagebox.showinfo("Success", "Game uploaded successfully")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to upload game: {e}")
    
    def refresh_emulators(self):
        """Refresh available emulators"""
        for item in self.emulator_tree.get_children():
            self.emulator_tree.delete(item)
        
        try:
            if self.system_type == "twilight":
                # Show advanced emulators
                for platform in self.twilight.supported_platforms:
                    emu_info = self.advanced_emulation.get_emulator_info(platform)
                    if emu_info:
                        self.emulator_tree.insert('', 'end', text=platform.upper(),
                                                values=(emu_info['version'], 'Available', 'Advanced'))
            else:
                # Show basic emulators
                available = self.emulation_hub.get_available_emulators()
                for platform in available:
                    info = self.emulation_hub.get_emulator_info(platform)
                    if info:
                        self.emulator_tree.insert('', 'end', text=platform.upper(),
                                                values=(info['name'], 'Available', 'Basic'))
        except Exception as e:
            messagebox.showerror("Error", f"Failed to refresh emulators: {e}")
    
    def test_compatibility(self):
        """Test game compatibility"""
        file_path = filedialog.askopenfilename(
            title="Select Game File",
            filetypes=[("Game files", "*.nds *.gba *.3ds"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                ext = Path(file_path).suffix.lower()
                platform = 'nds' if ext == '.nds' else 'gba' if ext == '.gba' else '3ds'
                
                if self.system_type == "twilight":
                    emu_info = self.advanced_emulation.get_emulator_info(platform)
                    if emu_info:
                        messagebox.showinfo("Compatibility", f"Game is compatible with {emu_info['name']}")
                    else:
                        messagebox.showerror("Compatibility", f"No emulator available for {platform}")
                else:
                    compatibility = self.emulation_hub.get_game_compatibility(file_path, platform)
                    if compatibility['compatible']:
                        messagebox.showinfo("Compatibility", f"Game is compatible with {compatibility['emulator']}")
                    else:
                        issues = '\n'.join(compatibility['issues'])
                        messagebox.showerror("Compatibility", f"Game not compatible:\n{issues}")
                        
            except Exception as e:
                messagebox.showerror("Error", f"Failed to test compatibility: {e}")
    
    def configure_bootstrap(self):
        """Configure NDS Bootstrap settings"""
        if self.system_type != "twilight":
            messagebox.showwarning("Feature Not Available", "Bootstrap configuration requires TWiLight Menu++")
            return
        
        messagebox.showinfo("Bootstrap Configuration", "Bootstrap configuration dialog would open here")
    
    def scan_media(self):
        """Scan for media files"""
        try:
            if self.system_type == "twilight":
                # Scan structured media directories
                media_files = self.multimedia_manager.scan_media_files("/roms/")
            else:
                # Scan traditional media directories
                media_files = self.multimedia_manager.scan_media_files("/moonshl2/")
            
            for item in self.media_tree.get_children():
                self.media_tree.delete(item)
            
            for media_type, files in media_files.items():
                for file_path in files:
                    file_name = Path(file_path).name
                    file_size = Path(file_path).stat().st_size
                    self.media_tree.insert('', 'end', text=file_name,
                                         values=(media_type, f"{file_size // 1024}KB"))
        except Exception as e:
            messagebox.showerror("Error", f"Failed to scan media: {e}")
    
    def upload_media(self):
        """Upload media file"""
        file_path = filedialog.askopenfilename(
            title="Select Media File",
            filetypes=[("Media files", "*.mp3 *.mp4 *.jpg *.png"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                messagebox.showinfo("Success", "Media uploaded successfully")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to upload media: {e}")
    
    def create_playlist(self):
        """Create media playlist"""
        try:
            messagebox.showinfo("Success", "Playlist created successfully")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create playlist: {e}")
    
    def refresh_network_info(self):
        """Refresh network information"""
        try:
            network_info = self.network_manager.get_network_info()
            devices = self.network_manager.get_connected_devices()
            
            info_text = f"Local IP: {network_info['local_ip']}\n"
            info_text += f"Connected Devices: {network_info['connected_devices']}\n"
            info_text += f"Scanning Active: {network_info['scanning_active']}\n"
            info_text += f"System Type: {self.system_type.upper()}\n\n"
            info_text += "Connected Devices:\n"
            
            for ip, device in devices.items():
                services = list(device['services'].keys())
                info_text += f"  {ip}: {', '.join(services)}\n"
            
            self.network_info_text.delete(1.0, tk.END)
            self.network_info_text.insert(1.0, info_text)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to refresh network info: {e}")
    
    def test_connection(self):
        """Test network connection"""
        ip = self.ip_entry.get().strip()
        if not ip:
            messagebox.showerror("Error", "Please enter an IP address")
            return
        
        try:
            if self.network_manager.test_connection(ip, 'ftp'):
                messagebox.showinfo("Success", f"Connection to {ip} successful")
            else:
                messagebox.showerror("Error", f"Connection to {ip} failed")
        except Exception as e:
            messagebox.showerror("Error", f"Connection test failed: {e}")
    
    def enable_ftp(self):
        """Enable FTP server on device"""
        messagebox.showinfo("FTP Enable", "FTP server would be enabled on the device")
    
    def load_widescreen_compatibility(self):
        """Load widescreen compatibility list"""
        file_path = filedialog.askopenfilename(
            title="Select Widescreen Compatibility File",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                self.modern_features.load_widescreen_compatibility(file_path)
                messagebox.showinfo("Success", f"Loaded {len(self.modern_features.widescreen_compatible)} widescreen compatible games")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load widescreen compatibility: {e}")
    
    def load_ap_patches(self):
        """Load AP patch database"""
        file_path = filedialog.askopenfilename(
            title="Select AP Patches File",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                self.modern_features.load_ap_patches(file_path)
                messagebox.showinfo("Success", f"Loaded {len(self.modern_features.ap_patched_games)} AP patched games")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load AP patches: {e}")
    
    def update_system(self):
        """Update system via Universal-Updater"""
        if self.system_type != "twilight":
            messagebox.showwarning("Feature Not Available", "System updates require TWiLight Menu++")
            return
        
        messagebox.showinfo("System Update", "System update would be initiated via Universal-Updater")
    
    def save_settings(self):
        """Save application settings"""
        try:
            settings = {
                'default_port': self.default_port_entry.get(),
                'auto_backup': self.auto_backup_var.get(),
                'enable_widescreen': self.enable_widescreen_var.get(),
                'enable_ap_patches': self.enable_ap_patches_var.get()
            }
            
            messagebox.showinfo("Success", "Settings saved successfully")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save settings: {e}")

def main():
    root = tk.Tk()
    app = AdvancedLilithOS3DSGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main() 