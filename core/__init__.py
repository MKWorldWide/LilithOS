"""
LilithOS Core System - Modular Architecture
===========================================

This is the central core of the LilithOS operating system, providing:
- Modular plugin architecture
- Cross-platform compatibility
- Advanced security features
- Performance optimization
- Real-time monitoring
- Unified API interface

Author: LilithOS Development Team
Version: 2.0.0
License: MIT
"""

import os
import sys
import asyncio
import logging
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from enum import Enum
import json
import yaml
import psutil
import platform

# Core imports
from .config import ConfigManager
from .module_manager import ModuleManager
from .security import SecurityManager
from .performance import PerformanceMonitor
from .network import NetworkManager
from .storage import StorageManager
from .api import APIManager
from .events import EventManager
from .utils import SystemUtils, Logger

# Version information
__version__ = "2.0.0"
__author__ = "LilithOS Development Team"
__license__ = "MIT"

class SystemStatus(Enum):
    """System status enumeration"""
    INITIALIZING = "initializing"
    RUNNING = "running"
    MAINTENANCE = "maintenance"
    ERROR = "error"
    SHUTDOWN = "shutdown"

@dataclass
class SystemInfo:
    """System information container"""
    platform: str = ""
    version: str = ""
    architecture: str = ""
    cpu_count: int = 0
    memory_total: int = 0
    disk_total: int = 0
    uptime: float = 0.0
    load_average: List[float] = field(default_factory=list)

class LilithOSCore:
    """
    Main LilithOS Core System
    
    This class manages the entire LilithOS ecosystem, providing:
    - Module management and loading
    - System monitoring and optimization
    - Security and access control
    - Network and storage management
    - Event handling and API management
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize the LilithOS core system"""
        self.config_path = config_path or "config/core_config.yaml"
        self.status = SystemStatus.INITIALIZING
        self.start_time = time.time()
        
        # Initialize core components
        self.logger = Logger("LilithOSCore")
        self.config = ConfigManager(self.config_path)
        self.module_manager = ModuleManager(self)
        self.security = SecurityManager(self)
        self.performance = PerformanceMonitor(self)
        self.network = NetworkManager(self)
        self.storage = StorageManager(self)
        self.api = APIManager(self)
        self.events = EventManager(self)
        self.utils = SystemUtils(self)
        
        # System information
        self.system_info = self._get_system_info()
        
        # Module registry
        self.modules: Dict[str, Any] = {}
        self.active_modules: List[str] = []
        
        self.logger.info("LilithOS Core initialized successfully")
    
    def _get_system_info(self) -> SystemInfo:
        """Get current system information"""
        return SystemInfo(
            platform=platform.system(),
            version=platform.version(),
            architecture=platform.machine(),
            cpu_count=psutil.cpu_count(),
            memory_total=psutil.virtual_memory().total,
            disk_total=psutil.disk_usage('/').total if os.path.exists('/') else 0,
            uptime=time.time() - self.start_time,
            load_average=psutil.getloadavg() if hasattr(psutil, 'getloadavg') else [0, 0, 0]
        )
    
    async def start(self) -> bool:
        """Start the LilithOS core system"""
        try:
            self.logger.info("Starting LilithOS Core System...")
            self.status = SystemStatus.INITIALIZING
            
            # Initialize core services
            await self.config.load()
            await self.security.initialize()
            await self.performance.start()
            await self.network.initialize()
            await self.storage.initialize()
            await self.api.start()
            await self.events.start()
            
            # Load modules
            await self.module_manager.load_all_modules()
            
            self.status = SystemStatus.RUNNING
            self.logger.info("LilithOS Core System started successfully")
            return True
            
        except Exception as e:
            self.status = SystemStatus.ERROR
            self.logger.error(f"Failed to start LilithOS Core: {e}")
            return False
    
    async def stop(self) -> bool:
        """Stop the LilithOS core system"""
        try:
            self.logger.info("Stopping LilithOS Core System...")
            self.status = SystemStatus.SHUTDOWN
            
            # Stop all modules
            await self.module_manager.stop_all_modules()
            
            # Stop core services
            await self.events.stop()
            await self.api.stop()
            await self.storage.cleanup()
            await self.network.cleanup()
            await self.performance.stop()
            await self.security.cleanup()
            
            self.logger.info("LilithOS Core System stopped successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error stopping LilithOS Core: {e}")
            return False
    
    def get_module(self, module_name: str) -> Optional[Any]:
        """Get a loaded module by name"""
        return self.modules.get(module_name)
    
    def register_module(self, module_name: str, module_instance: Any) -> bool:
        """Register a new module"""
        try:
            self.modules[module_name] = module_instance
            self.active_modules.append(module_name)
            self.logger.info(f"Module '{module_name}' registered successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to register module '{module_name}': {e}")
            return False
    
    def unregister_module(self, module_name: str) -> bool:
        """Unregister a module"""
        try:
            if module_name in self.modules:
                del self.modules[module_name]
                if module_name in self.active_modules:
                    self.active_modules.remove(module_name)
                self.logger.info(f"Module '{module_name}' unregistered successfully")
                return True
            return False
        except Exception as e:
            self.logger.error(f"Failed to unregister module '{module_name}': {e}")
            return False
    
    def get_system_stats(self) -> Dict[str, Any]:
        """Get current system statistics"""
        return {
            "status": self.status.value,
            "uptime": time.time() - self.start_time,
            "active_modules": len(self.active_modules),
            "total_modules": len(self.modules),
            "memory_usage": psutil.virtual_memory().percent,
            "cpu_usage": psutil.cpu_percent(),
            "disk_usage": psutil.disk_usage('/').percent if os.path.exists('/') else 0,
            "system_info": self.system_info.__dict__
        }
    
    async def run_maintenance(self) -> bool:
        """Run system maintenance tasks"""
        try:
            self.logger.info("Running system maintenance...")
            self.status = SystemStatus.MAINTENANCE
            
            # Update system info
            self.system_info = self._get_system_info()
            
            # Run maintenance on all components
            await self.performance.run_maintenance()
            await self.storage.run_maintenance()
            await self.network.run_maintenance()
            await self.security.run_maintenance()
            
            self.status = SystemStatus.RUNNING
            self.logger.info("System maintenance completed successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Maintenance failed: {e}")
            self.status = SystemStatus.ERROR
            return False

# Global core instance
_core_instance: Optional[LilithOSCore] = None

def get_core() -> LilithOSCore:
    """Get the global core instance"""
    global _core_instance
    if _core_instance is None:
        _core_instance = LilithOSCore()
    return _core_instance

def initialize_core(config_path: Optional[str] = None) -> LilithOSCore:
    """Initialize the global core instance"""
    global _core_instance
    if _core_instance is None:
        _core_instance = LilithOSCore(config_path)
    return _core_instance

# Export main classes
__all__ = [
    'LilithOSCore',
    'SystemStatus',
    'SystemInfo',
    'get_core',
    'initialize_core',
    '__version__',
    '__author__',
    '__license__'
] 