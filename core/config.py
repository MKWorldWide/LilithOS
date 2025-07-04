"""
LilithOS Configuration Manager
=============================

Handles all system configuration including:
- YAML configuration files
- Environment variables
- Dynamic configuration reloading
- Configuration validation
- Default values management
"""

import os
import yaml
import json
import asyncio
import logging
from pathlib import Path
from typing import Dict, Any, Optional, List, Union
from dataclasses import dataclass, field
import threading
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

@dataclass
class ConfigSection:
    """Configuration section container"""
    name: str
    data: Dict[str, Any] = field(default_factory=dict)
    last_modified: float = 0.0
    is_valid: bool = True
    validation_errors: List[str] = field(default_factory=list)

class ConfigValidator:
    """Configuration validation utilities"""
    
    @staticmethod
    def validate_required_fields(config: Dict[str, Any], required_fields: List[str]) -> List[str]:
        """Validate that required fields are present"""
        errors = []
        for field in required_fields:
            if field not in config:
                errors.append(f"Required field '{field}' is missing")
        return errors
    
    @staticmethod
    def validate_type(value: Any, expected_type: type, field_name: str) -> Optional[str]:
        """Validate field type"""
        if not isinstance(value, expected_type):
            return f"Field '{field_name}' must be of type {expected_type.__name__}, got {type(value).__name__}"
        return None
    
    @staticmethod
    def validate_range(value: Union[int, float], min_val: Union[int, float], max_val: Union[int, float], field_name: str) -> Optional[str]:
        """Validate numeric range"""
        if value < min_val or value > max_val:
            return f"Field '{field_name}' must be between {min_val} and {max_val}, got {value}"
        return None

class ConfigWatcher(FileSystemEventHandler):
    """File system watcher for configuration changes"""
    
    def __init__(self, config_manager: 'ConfigManager'):
        self.config_manager = config_manager
        self.observer = Observer()
    
    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith(('.yaml', '.yml', '.json')):
            asyncio.create_task(self.config_manager.reload_config())
    
    def start_watching(self, path: str):
        """Start watching a directory for changes"""
        self.observer.schedule(self, path, recursive=False)
        self.observer.start()
    
    def stop_watching(self):
        """Stop watching for changes"""
        self.observer.stop()
        self.observer.join()

class ConfigManager:
    """
    LilithOS Configuration Manager
    
    Manages all system configuration with support for:
    - Multiple configuration files
    - Environment variable overrides
    - Dynamic reloading
    - Validation and error handling
    - Default values
    """
    
    def __init__(self, config_path: str = "config/core_config.yaml"):
        self.config_path = Path(config_path)
        self.config_dir = self.config_path.parent
        self.config_data: Dict[str, Any] = {}
        self.sections: Dict[str, ConfigSection] = {}
        self.defaults: Dict[str, Any] = {}
        self.validators: Dict[str, callable] = {}
        self.watcher = ConfigWatcher(self)
        self.lock = threading.RLock()
        self.logger = logging.getLogger("ConfigManager")
        
        # Initialize default configuration
        self._init_defaults()
        
        # Start file watcher
        if self.config_dir.exists():
            self.watcher.start_watching(str(self.config_dir))
    
    def _init_defaults(self):
        """Initialize default configuration values"""
        self.defaults = {
            "system": {
                "name": "LilithOS",
                "version": "2.0.0",
                "debug": False,
                "log_level": "INFO",
                "max_threads": 8,
                "memory_limit": "2GB"
            },
            "security": {
                "encryption_enabled": True,
                "auth_required": True,
                "session_timeout": 3600,
                "max_login_attempts": 3,
                "password_min_length": 8
            },
            "network": {
                "host": "localhost",
                "port": 8080,
                "ssl_enabled": False,
                "max_connections": 100,
                "timeout": 30
            },
            "storage": {
                "data_dir": "data",
                "backup_dir": "backups",
                "max_file_size": "100MB",
                "compression_enabled": True
            },
            "performance": {
                "cache_enabled": True,
                "cache_size": "512MB",
                "auto_optimization": True,
                "monitoring_interval": 60
            },
            "modules": {
                "auto_load": True,
                "load_timeout": 30,
                "dependency_check": True,
                "hot_reload": False
            }
        }
    
    async def load(self) -> bool:
        """Load configuration from files"""
        try:
            with self.lock:
                self.logger.info(f"Loading configuration from {self.config_path}")
                
                # Load main configuration file
                if self.config_path.exists():
                    with open(self.config_path, 'r', encoding='utf-8') as f:
                        self.config_data = yaml.safe_load(f) or {}
                else:
                    self.logger.warning(f"Configuration file {self.config_path} not found, using defaults")
                    self.config_data = {}
                
                # Merge with defaults
                self._merge_with_defaults()
                
                # Load environment variables
                self._load_environment_vars()
                
                # Validate configuration
                await self._validate_config()
                
                # Create sections
                self._create_sections()
                
                self.logger.info("Configuration loaded successfully")
                return True
                
        except Exception as e:
            self.logger.error(f"Failed to load configuration: {e}")
            return False
    
    def _merge_with_defaults(self):
        """Merge configuration with default values"""
        def merge_dicts(default: Dict[str, Any], config: Dict[str, Any]) -> Dict[str, Any]:
            result = default.copy()
            for key, value in config.items():
                if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                    result[key] = merge_dicts(result[key], value)
                else:
                    result[key] = value
            return result
        
        self.config_data = merge_dicts(self.defaults, self.config_data)
    
    def _load_environment_vars(self):
        """Load configuration from environment variables"""
        env_prefix = "LILITHOS_"
        
        for key, value in os.environ.items():
            if key.startswith(env_prefix):
                config_key = key[len(env_prefix):].lower()
                keys = config_key.split('_')
                
                # Navigate to nested dictionary
                current = self.config_data
                for k in keys[:-1]:
                    if k not in current:
                        current[k] = {}
                    current = current[k]
                
                # Set the value
                current[keys[-1]] = self._parse_env_value(value)
    
    def _parse_env_value(self, value: str) -> Union[str, int, float, bool]:
        """Parse environment variable value to appropriate type"""
        # Boolean values
        if value.lower() in ('true', 'false'):
            return value.lower() == 'true'
        
        # Integer values
        try:
            return int(value)
        except ValueError:
            pass
        
        # Float values
        try:
            return float(value)
        except ValueError:
            pass
        
        # String values
        return value
    
    async def _validate_config(self):
        """Validate configuration values"""
        errors = []
        
        # Validate system section
        system = self.config_data.get('system', {})
        errors.extend(ConfigValidator.validate_required_fields(system, ['name', 'version']))
        
        # Validate security section
        security = self.config_data.get('security', {})
        if 'session_timeout' in security:
            error = ConfigValidator.validate_range(security['session_timeout'], 60, 86400, 'session_timeout')
            if error:
                errors.append(error)
        
        # Validate network section
        network = self.config_data.get('network', {})
        if 'port' in network:
            error = ConfigValidator.validate_range(network['port'], 1, 65535, 'port')
            if error:
                errors.append(error)
        
        if errors:
            self.logger.error(f"Configuration validation errors: {errors}")
            raise ValueError(f"Configuration validation failed: {errors}")
    
    def _create_sections(self):
        """Create configuration sections"""
        for section_name, section_data in self.config_data.items():
            self.sections[section_name] = ConfigSection(
                name=section_name,
                data=section_data,
                last_modified=time.time(),
                is_valid=True
            )
    
    async def reload_config(self) -> bool:
        """Reload configuration from files"""
        return await self.load()
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value by key (supports dot notation)"""
        try:
            keys = key.split('.')
            value = self.config_data
            
            for k in keys:
                value = value[k]
            
            return value
        except (KeyError, TypeError):
            return default
    
    def set(self, key: str, value: Any) -> bool:
        """Set configuration value by key (supports dot notation)"""
        try:
            keys = key.split('.')
            current = self.config_data
            
            # Navigate to the parent of the target key
            for k in keys[:-1]:
                if k not in current:
                    current[k] = {}
                current = current[k]
            
            # Set the value
            current[keys[-1]] = value
            
            # Update sections
            if keys[0] in self.sections:
                self.sections[keys[0]].data = self.config_data[keys[0]]
                self.sections[keys[0]].last_modified = time.time()
            
            return True
        except Exception as e:
            self.logger.error(f"Failed to set configuration key '{key}': {e}")
            return False
    
    def get_section(self, section_name: str) -> Optional[ConfigSection]:
        """Get a configuration section"""
        return self.sections.get(section_name)
    
    def has_section(self, section_name: str) -> bool:
        """Check if a configuration section exists"""
        return section_name in self.sections
    
    def list_sections(self) -> List[str]:
        """List all configuration sections"""
        return list(self.sections.keys())
    
    async def save(self, path: Optional[str] = None) -> bool:
        """Save configuration to file"""
        try:
            save_path = Path(path) if path else self.config_path
            
            # Ensure directory exists
            save_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(save_path, 'w', encoding='utf-8') as f:
                yaml.dump(self.config_data, f, default_flow_style=False, indent=2)
            
            self.logger.info(f"Configuration saved to {save_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to save configuration: {e}")
            return False
    
    def export_json(self, path: str) -> bool:
        """Export configuration as JSON"""
        try:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(self.config_data, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to export JSON configuration: {e}")
            return False
    
    def get_all(self) -> Dict[str, Any]:
        """Get all configuration data"""
        return self.config_data.copy()
    
    def reset_to_defaults(self) -> bool:
        """Reset configuration to default values"""
        try:
            self.config_data = self.defaults.copy()
            self._create_sections()
            return True
        except Exception as e:
            self.logger.error(f"Failed to reset configuration: {e}")
            return False
    
    def cleanup(self):
        """Cleanup resources"""
        self.watcher.stop_watching() 