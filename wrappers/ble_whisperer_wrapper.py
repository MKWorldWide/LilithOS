#!/usr/bin/env python3
"""
BLE Whisperer Wrapper for LilithOS

This script wraps the native C BLE Whisperer daemon to provide integration with
DivineBus for event-based communication and LogKitten for structured logging.
"""

import os
import sys
import json
import time
import signal
import subprocess
import threading
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple

# Add the project root to the Python path
sys.path.append(str(Path(__file__).parent.parent))

# Import core components
from core.divinebus import DivineBus
from core.logkitten import LogKitten
from core.lilithkit import LilithKit, ProcessMonitor

# Configuration
BLE_WHISPERER_PATH = "/opt/lilithos/bin/ble_whisperer"
LOG_DIR = "/var/log/lilithos"
PID_FILE = "/var/run/lilithos/ble_whisperer.pid"
WHISPER_BASE_PATH = "/ux0:/data/lilith/whisper/"

class BLEWhispererWrapper:
    """Wrapper for the native C BLE Whisperer daemon with DivineBus and LogKitten integration."""
    
    def __init__(self):
        """Initialize the BLE Whisperer wrapper."""
        self.running = False
        self.daemon_process = None
        self.bus = DivineBus()
        self.logger = LogKitten(
            name="ble_whisperer_wrapper",
            log_dir=LOG_DIR,
            level="INFO"
        )
        self.lilith_kit = LilithKit.get_instance()
        self.discovered_devices = []  # List of (name, address, rssi, last_seen)
        self.active_sessions = {}  # address -> session_info
        
        # Register signal handlers
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)
        
        # Ensure required directories exist
        os.makedirs(LOG_DIR, exist_ok=True)
        os.makedirs(os.path.dirname(PID_FILE), exist_ok=True)
        os.makedirs(WHISPER_BASE_PATH, exist_ok=True)
        
        # Subscribe to relevant events
        self.bus.subscribe("ble.scan.start", self._on_scan_start)
        self.bus.subscribe("ble.scan.stop", self._on_scan_stop)
        self.bus.subscribe("ble.device.connect", self._on_device_connect)
        self.bus.subscribe("ble.device.disconnect", self._on_device_disconnect)
        self.bus.subscribe("ble.data.send", self._on_data_send)
    
    def _handle_signal(self, signum, frame):
        """Handle termination signals."""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.stop()
    
    def _read_pid_file(self) -> Optional[int]:
        """Read the PID from the PID file."""
        try:
            with open(PID_FILE, 'r') as f:
                return int(f.read().strip())
        except (FileNotFoundError, ValueError):
            return None
    
    def _write_pid_file(self, pid: int):
        """Write the PID to the PID file."""
        with open(PID_FILE, 'w') as f:
            f.write(str(pid))
    
    def _remove_pid_file(self):
        """Remove the PID file if it exists."""
        try:
            os.remove(PID_FILE)
        except FileNotFoundError:
            pass
    
    def _monitor_daemon(self):
        """Monitor the daemon process and restart it if it fails."""
        while self.running:
            if self.daemon_process is None or self.daemon_process.poll() is not None:
                self.logger.warning("BLE Whisperer daemon is not running, restarting...")
                self._start_daemon()
            time.sleep(5)
    
    def _start_daemon(self):
        """Start the native C daemon process."""
        if self.daemon_process is not None and self.daemon_process.poll() is None:
            self.logger.warning("Daemon is already running")
            return
        
        self.logger.info("Starting BLE Whisperer daemon...")
        self.daemon_process = subprocess.Popen(
            [BLE_WHISPERER_PATH],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )
        self._write_pid_file(self.daemon_process.pid)
        
        # Start a thread to read the daemon's output
        threading.Thread(
            target=self._read_daemon_output,
            daemon=True
        ).start()
    
    def _read_daemon_output(self):
        """Read and process the daemon's output."""
        for line in iter(self.daemon_process.stdout.readline, ''):
            if not line:
                break
            
            # Log the daemon's output
            self.logger.info(f"[daemon] {line.strip()}")
            
            # Parse and forward events to DivineBus
            self._process_ble_output(line.strip())
    
    def _process_ble_output(self, line: str):
        """Process a line of output from the BLE daemon and forward events to DivineBus."""
        try:
            # Try to parse the line as JSON
            data = json.loads(line)
            event_type = data.get("event")
            
            if event_type == "device_discovered":
                self._handle_device_discovered(data)
            elif event_type == "device_connected":
                self._handle_device_connected(data)
            elif event_type == "device_disconnected":
                self._handle_device_disconnected(data)
            elif event_type == "data_received":
                self._handle_data_received(data)
            elif event_type == "error":
                self.bus.publish("ble.error", data)
            
        except json.JSONDecodeError:
            # Not a JSON line, treat as a regular log message
            if any(keyword in line.lower() for keyword in ["error", "fail", "exception"]):
                self.bus.publish("ble.log.error", {"message": line})
            else:
                self.bus.publish("ble.log.info", {"message": line})
    
    def _handle_device_discovered(self, data: Dict[str, Any]):
        """Handle device discovered event."""
        device = {
            "name": data.get("name", "unknown"),
            "address": data["address"],
            "rssi": data.get("rssi", 0),
            "last_seen": time.time()
        }
        
        # Update or add to discovered devices
        for i, dev in enumerate(self.discovered_devices):
            if dev["address"] == device["address"]:
                self.discovered_devices[i] = device
                break
        else:
            self.discovered_devices.append(device)
        
        # Publish event
        self.bus.publish("ble.device.discovered", device)
    
    def _handle_device_connected(self, data: Dict[str, Any]):
        """Handle device connected event."""
        address = data["address"]
        session_id = data.get("session_id")
        
        # Add to active sessions
        self.active_sessions[address] = {
            "session_id": session_id,
            "connected_at": time.time(),
            "last_activity": time.time()
        }
        
        # Publish event
        self.bus.publish("ble.device.connected", {
            "address": address,
            "session_id": session_id
        })
    
    def _handle_device_disconnected(self, data: Dict[str, Any]):
        """Handle device disconnected event."""
        address = data["address"]
        
        # Remove from active sessions
        if address in self.active_sessions:
            del self.active_sessions[address]
        
        # Publish event
        self.bus.publish("ble.device.disconnected", {"address": address})
    
    def _handle_data_received(self, data: Dict[str, Any]):
        """Handle data received event."""
        self.bus.publish("ble.data.received", data)
    
    # Event handlers for DivineBus events
    def _on_scan_start(self, event_data: Dict[str, Any]):
        """Handle scan start event."""
        self.logger.info("Starting BLE scan...")
        # Send command to daemon to start scanning
        # Implementation depends on how the C daemon accepts commands
    
    def _on_scan_stop(self, event_data: Dict[str, Any]):
        """Handle scan stop event."""
        self.logger.info("Stopping BLE scan...")
        # Send command to daemon to stop scanning
    
    def _on_device_connect(self, event_data: Dict[str, Any]):
        """Handle device connect event."""
        address = event_data.get("address")
        if not address:
            self.logger.error("No address provided for device connect")
            return
        
        self.logger.info(f"Connecting to device {address}...")
        # Send command to daemon to connect to device
    
    def _on_device_disconnect(self, event_data: Dict[str, Any]):
        """Handle device disconnect event."""
        address = event_data.get("address")
        if not address:
            self.logger.error("No address provided for device disconnect")
            return
        
        self.logger.info(f"Disconnecting from device {address}...")
        # Send command to daemon to disconnect from device
    
    def _on_data_send(self, event_data: Dict[str, Any]):
        """Handle data send event."""
        address = event_data.get("address")
        data = event_data.get("data")
        
        if not address or not data:
            self.logger.error("Missing address or data for send")
            return
        
        self.logger.debug(f"Sending data to {address}")
        # Send command to daemon to send data to device
    
    def start(self):
        """Start the wrapper and the native daemon."""
        if self.running:
            self.logger.warning("Wrapper is already running")
            return
        
        self.running = True
        self.logger.info("Starting BLE Whisperer wrapper...")
        
        # Register with LilithKit
        self.lilith_kit.register_service(
            name="ble_whisperer",
            description="Handles BLE communication for LilithOS",
            health_check=self.health_check,
            restart_callback=self.restart
        )
        
        # Start the daemon
        self._start_daemon()
        
        # Start the monitor thread
        threading.Thread(
            target=self._monitor_daemon,
            daemon=True
        ).start()
        
        self.logger.info("BLE Whisperer wrapper started")
    
    def stop(self):
        """Stop the wrapper and the native daemon."""
        if not self.running:
            return
        
        self.logger.info("Stopping BLE Whisperer wrapper...")
        self.running = False
        
        # Stop the daemon process
        if self.daemon_process and self.daemon_process.poll() is None:
            self.logger.info("Stopping BLE Whisperer daemon...")
            self.daemon_process.terminate()
            try:
                self.daemon_process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.daemon_process.kill()
                self.daemon_process.wait()
        
        # Clean up PID file
        self._remove_pid_file()
        
        # Unregister from LilithKit
        self.lilith_kit.unregister_service("ble_whisperer")
        
        self.logger.info("BLE Whisperer wrapper stopped")
    
    def restart(self):
        """Restart the native daemon."""
        self.logger.info("Restarting BLE Whisperer daemon...")
        if self.daemon_process and self.daemon_process.poll() is None:
            self.daemon_process.terminate()
            try:
                self.daemon_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.daemon_process.kill()
                self.daemon_process.wait()
        
        self._start_daemon()
        self.logger.info("BLE Whisperer daemon restarted")
    
    def health_check(self) -> Dict[str, Any]:
        """Check the health of the BLE Whisperer daemon."""
        is_running = self.daemon_process is not None and self.daemon_process.poll() is None
        
        return {
            "status": "running" if is_running else "stopped",
            "pid": self.daemon_process.pid if is_running else None,
            "uptime": None,  # Would need to track start time
            "last_error": None,  # Would track last error
            "discovered_devices": len(self.discovered_devices),
            "active_sessions": len(self.active_sessions),
            "metrics": {
                "devices_seen": len(self.discovered_devices),
                "data_received": 0,  # Would track metrics
                "data_sent": 0
            }
        }

def main():
    """Main entry point for the BLE Whisperer wrapper."""
    wrapper = BLEWhispererWrapper()
    
    try:
        wrapper.start()
        
        # Keep the main thread alive
        while wrapper.running:
            time.sleep(1)
            
    except KeyboardInterrupt:
        pass
    except Exception as e:
        wrapper.logger.error(f"Unhandled exception: {e}", exc_info=True)
    finally:
        wrapper.stop()

if __name__ == "__main__":
    main()
