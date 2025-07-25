"""
LilithKit - The Soulbound Guardian

A system daemon that monitors, restores, and protects all LilithOS processes.
Implements process watching, health checks, and automatic recovery.
"""

import os
import sys
import time
import signal
import logging
import subprocess
import psutil
import json
from pathlib import Path
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, asdict
from datetime import datetime

# Import core components
from .events import EventBus
from .module_manager import ModuleManager
from .performance import SystemMetrics
from .security import SecureConfig

# Constants
LOG_DIR = Path("/var/lilithos/logs")
CONFIG_DIR = Path("/etc/lilithos")
PID_DIR = Path("/var/run/lilithos")
MAX_RESTARTS = 5  # Max restarts before giving up on a process
RESTART_WINDOW = 60  # Seconds to consider for rate limiting

@dataclass
class ProcessInfo:
    """Information about a monitored process."""
    name: str
    pid: int = -1
    start_time: float = 0.0
    restarts: int = 0
    last_restart: float = 0.0
    health_status: str = "healthy"
    last_check: float = 0.0

class LilithKit:
    """
    The Soulbound Guardian of LilithOS.
    
    Monitors system processes, restarts failed components, and maintains
    system health through divine intervention.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize the LilithKit daemon."""
        self.running = False
        self.config = self._load_config(config_path)
        self.event_bus = EventBus()
        self.metrics = SystemMetrics()
        self.secure_config = SecureConfig()
        self.processes: Dict[str, ProcessInfo] = {}
        self.watchdog_interval = 5.0  # seconds
        self._setup_logging()
        self._setup_directories()
        self._register_handlers()
    
    def _setup_logging(self) -> None:
        """Configure logging for the LilithKit daemon."""
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        log_file = LOG_DIR / "lilithkit.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s [%(levelname)s] %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger("LilithKit")
    
    def _setup_directories(self) -> None:
        """Ensure required directories exist."""
        for directory in [LOG_DIR, CONFIG_DIR, PID_DIR]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def _load_config(self, config_path: Optional[str] = None) -> dict:
        """Load configuration from file or use defaults."""
        default_config = {
            "monitored_processes": ["update_daemon", "ble_whisperer", "backup_daemon"],
            "max_cpu_percent": 80.0,
            "max_memory_percent": 85.0,
            "health_check_interval": 30,
            "enable_telemetry": True,
            "telemetry_endpoint": "https://athena.sovereign.systems/telemetry"
        }
        
        if not config_path:
            config_path = CONFIG_DIR / "lilithkit.json"
        
        try:
            if config_path.exists():
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    default_config.update(config)
        except Exception as e:
            self.logger.error(f"Error loading config: {e}")
        
        return default_config
    
    def _register_handlers(self) -> None:
        """Register signal and event handlers."""
        signal.signal(signal.SIGTERM, self._handle_shutdown)
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGHUP, self._handle_reload)
        
        # Register event handlers
        self.event_bus.subscribe("process.started", self._on_process_started)
        self.event_bus.subscribe("process.ended", self._on_process_ended)
        self.event_bus.subscribe("system.alert", self._on_system_alert)
    
    def _on_process_started(self, event: dict) -> None:
        """Handle process started event."""
        process_name = event.get("name")
        pid = event.get("pid")
        if process_name and pid:
            self.logger.info(f"Process started: {process_name} (PID: {pid})")
            if process_name in self.processes:
                self.processes[process_name].pid = pid
                self.processes[process_name].start_time = time.time()
    
    def _on_process_ended(self, event: dict) -> None:
        """Handle process ended event."""
        process_name = event.get("name")
        if process_name in self.processes:
            self.processes[process_name].health_status = "crashed"
            self.logger.warning(f"Process crashed: {process_name}")
            self._handle_process_failure(process_name)
    
    def _on_system_alert(self, event: dict) -> None:
        """Handle system alert event."""
        self.logger.warning(f"System alert: {event.get('message')}")
        # TODO: Implement alert handling logic
    
    def _handle_process_failure(self, process_name: str) -> None:
        """Handle a failed process and attempt recovery."""
        if process_name not in self.processes:
            return
            
        proc_info = self.processes[process_name]
        now = time.time()
        
        # Rate limiting
        if now - proc_info.last_restart < RESTART_WINDOW:
            proc_info.restarts += 1
        else:
            proc_info.restarts = 1
        
        proc_info.last_restart = now
        
        if proc_info.restarts > MAX_RESTARTS:
            self.logger.error(
                f"Process {process_name} failed too many times. Giving up."
            )
            proc_info.health_status = "failed"
            self.event_bus.publish("process.gave_up", {"name": process_name})
            return
        
        # Attempt to restart the process
        self.logger.info(f"Attempting to restart {process_name} (attempt {proc_info.restarts}/{MAX_RESTARTS})")
        self._restart_process(process_name)
    
    def _restart_process(self, process_name: str) -> bool:
        """Restart a monitored process."""
        # TODO: Implement process restart logic based on process_name
        # This would involve looking up the process in the ModuleManager
        # and calling the appropriate start method
        self.logger.info(f"Restarting process: {process_name}")
        return True
    
    def _check_system_health(self) -> None:
        """Perform system health checks."""
        cpu_percent = self.metrics.get_cpu_percent()
        memory_percent = self.metrics.get_memory_percent()
        
        if cpu_percent > self.config["max_cpu_percent"]:
            self.logger.warning(f"High CPU usage: {cpu_percent}%")
            self.event_bus.publish("system.alert", {
                "type": "high_cpu",
                "value": cpu_percent,
                "threshold": self.config["max_cpu_percent"]
            })
        
        if memory_percent > self.config["max_memory_percent"]:
            self.logger.warning(f"High memory usage: {memory_percent}%")
            self.event_bus.publish("system.alert", {
                "type": "high_memory",
                "value": memory_percent,
                "threshold": self.config["max_memory_percent"]
            })
    
    def _handle_shutdown(self, signum, frame) -> None:
        """Handle shutdown signals gracefully."""
        self.logger.info("Shutdown signal received. Cleaning up...")
        self.running = False
    
    def _handle_reload(self, signum, frame) -> None:
        """Handle reload signal to refresh configuration."""
        self.logger.info("Reloading configuration...")
        self.config = self._load_config()
    
    def start(self) -> None:
        """Start the LilithKit daemon."""
        if self.running:
            self.logger.warning("LilithKit is already running")
            return
        
        self.logger.info("Starting LilithKit - The Soulbound Guardian")
        self.running = True
        
        try:
            self._main_loop()
        except Exception as e:
            self.logger.critical(f"Fatal error in main loop: {e}", exc_info=True)
            raise
        finally:
            self.cleanup()
    
    def _main_loop(self) -> None:
        """Main monitoring loop."""
        last_health_check = 0
        
        while self.running:
            now = time.time()
            
            # Check system health periodically
            if now - last_health_check >= self.config["health_check_interval"]:
                self._check_system_health()
                last_health_check = now
            
            # Update process status
            self._update_process_status()
            
            # Sleep until next cycle
            time.sleep(self.watchdog_interval)
    
    def _update_process_status(self) -> None:
        """Check the status of all monitored processes."""
        for proc_info in self.processes.values():
            try:
                if proc_info.pid == -1:
                    continue
                    
                process = psutil.Process(proc_info.pid)
                if not process.is_running() or process.status() == psutil.STATUS_ZOMBIE:
                    self.event_bus.publish("process.ended", {
                        "name": proc_info.name,
                        "pid": proc_info.pid,
                        "exit_code": process.returncode,
                        "timestamp": time.time()
                    })
            except psutil.NoSuchProcess:
                self.event_bus.publish("process.ended", {
                    "name": proc_info.name,
                    "pid": proc_info.pid,
                    "exit_code": -1,
                    "timestamp": time.time()
                })
    
    def cleanup(self) -> None:
        """Clean up resources before shutdown."""
        self.logger.info("Cleaning up resources...")
        # TODO: Clean up any resources, save state, etc.
        self.running = False

def main():
    """Entry point for the LilithKit daemon."""
    try:
        kit = LilithKit()
        kit.start()
    except KeyboardInterrupt:
        print("\nShutting down gracefully...")
    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
