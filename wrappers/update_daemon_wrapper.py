#!/usr/bin/env python3
"""
Update Daemon Wrapper for LilithOS

This script wraps the native C update daemon to provide integration with
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
from typing import Dict, Any, Optional

# Add the project root to the Python path
sys.path.append(str(Path(__file__).parent.parent))

# Import core components
from core.divinebus import DivineBus
from core.logkitten import LogKitten
from core.lilithkit import LilithKit, ProcessMonitor

# Configuration
UPDATE_DAEMON_PATH = "/opt/lilithos/bin/update_daemon"
LOG_DIR = "/var/log/lilithos"
PID_FILE = "/var/run/lilithos/update_daemon.pid"

class UpdateDaemonWrapper:
    """Wrapper for the native C update daemon with DivineBus and LogKitten integration."""
    
    def __init__(self):
        """Initialize the update daemon wrapper."""
        self.running = False
        self.daemon_process = None
        self.bus = DivineBus()
        self.logger = LogKitten(
            name="update_daemon_wrapper",
            log_dir=LOG_DIR,
            level="INFO"
        )
        self.lilith_kit = LilithKit.get_instance()
        
        # Register signal handlers
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)
        
        # Ensure required directories exist
        os.makedirs(LOG_DIR, exist_ok=True)
        os.makedirs(os.path.dirname(PID_FILE), exist_ok=True)
    
    def _handle_signal(self, signum, frame):
        """Handle termination signals."""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.stop()
    
    def _read_pid_file(self) -> Optional[int]:
        """Read the PID from the PID file.
        
        Returns:
            Optional[int]: The PID if the file exists and contains a valid PID, else None
        """
        try:
            with open(PID_FILE, 'r') as f:
                return int(f.read().strip())
        except (FileNotFoundError, ValueError):
            return None
    
    def _write_pid_file(self, pid: int):
        """Write the PID to the PID file.
        
        Args:
            pid: The process ID to write
        """
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
                # Daemon is not running, restart it
                self.logger.warning("Update daemon is not running, restarting...")
                self._start_daemon()
            time.sleep(5)
    
    def _start_daemon(self):
        """Start the native C daemon process."""
        if self.daemon_process is not None and self.daemon_process.poll() is None:
            self.logger.warning("Daemon is already running")
            return
        
        self.logger.info("Starting update daemon...")
        self.daemon_process = subprocess.Popen(
            [UPDATE_DAEMON_PATH],
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
            self._process_daemon_output(line.strip())
    
    def _process_daemon_output(self, line: str):
        """Process a line of output from the daemon and forward events to DivineBus.
        
        Args:
            line: A line of output from the daemon
        """
        try:
            # Try to parse the line as JSON
            data = json.loads(line)
            event_type = data.get("event")
            
            if event_type == "update_available":
                self.bus.publish("updates.available", data)
            elif event_type == "update_started":
                self.bus.publish("updates.started", data)
            elif event_type == "update_completed":
                self.bus.publish("updates.completed", data)
            elif event_type == "error":
                self.bus.publish("updates.error", data)
            
        except json.JSONDecodeError:
            # Not a JSON line, treat as a regular log message
            if any(keyword in line.lower() for keyword in ["error", "fail", "exception"]):
                self.bus.publish("updates.log.error", {"message": line})
            else:
                self.bus.publish("updates.log.info", {"message": line})
    
    def start(self):
        """Start the wrapper and the native daemon."""
        if self.running:
            self.logger.warning("Wrapper is already running")
            return
        
        self.running = True
        self.logger.info("Starting update daemon wrapper...")
        
        # Register with LilithKit
        self.lilith_kit.register_service(
            name="update_daemon",
            description="Handles OTA and USB updates for LilithOS",
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
        
        self.logger.info("Update daemon wrapper started")
    
    def stop(self):
        """Stop the wrapper and the native daemon."""
        if not self.running:
            return
        
        self.logger.info("Stopping update daemon wrapper...")
        self.running = False
        
        # Stop the daemon process
        if self.daemon_process and self.daemon_process.poll() is None:
            self.logger.info("Stopping update daemon...")
            self.daemon_process.terminate()
            try:
                self.daemon_process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.daemon_process.kill()
                self.daemon_process.wait()
        
        # Clean up PID file
        self._remove_pid_file()
        
        # Unregister from LilithKit
        self.lilith_kit.unregister_service("update_daemon")
        
        self.logger.info("Update daemon wrapper stopped")
    
    def restart(self):
        """Restart the native daemon."""
        self.logger.info("Restarting update daemon...")
        if self.daemon_process and self.daemon_process.poll() is None:
            self.daemon_process.terminate()
            try:
                self.daemon_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.daemon_process.kill()
                self.daemon_process.wait()
        
        self._start_daemon()
        self.logger.info("Update daemon restarted")
    
    def health_check(self) -> Dict[str, Any]:
        """Check the health of the update daemon.
        
        Returns:
            Dict[str, Any]: Health status information
        """
        is_running = self.daemon_process is not None and self.daemon_process.poll() is None
        
        return {
            "status": "running" if is_running else "stopped",
            "pid": self.daemon_process.pid if is_running else None,
            "uptime": None,  # Would need to track start time
            "last_error": None,  # Would track last error
            "metrics": {
                "updates_installed": 0,  # Would track metrics
                "last_update_time": None,
                "pending_updates": 0
            }
        }

def main():
    """Main entry point for the update daemon wrapper."""
    wrapper = UpdateDaemonWrapper()
    
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
