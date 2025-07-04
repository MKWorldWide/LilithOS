"""
LilithOS Module Manager
=======================

Handles dynamic module loading, dependency resolution, and lifecycle management:
- Automatic module discovery
- Dependency resolution and validation
- Hot reloading capabilities
- Module lifecycle management
- Performance monitoring
"""

import os
import sys
import asyncio
import importlib
import importlib.util
import inspect
import logging
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import yaml
import json
from concurrent.futures import ThreadPoolExecutor

@dataclass
class ModuleInfo:
    """Module information container"""
    name: str
    path: str
    version: str = ""
    description: str = ""
    author: str = ""
    dependencies: List[str] = field(default_factory=list)
    conflicts: List[str] = field(default_factory=list)
    category: str = ""
    priority: int = 0
    enabled: bool = True
    loaded: bool = False
    error_count: int = 0
    last_error: Optional[str] = None
    load_time: float = 0.0
    memory_usage: int = 0

class ModuleStatus(Enum):
    """Module status enumeration"""
    DISCOVERED = "discovered"
    LOADING = "loading"
    LOADED = "loaded"
    ERROR = "error"
    DISABLED = "disabled"
    UNLOADING = "unloading"

class ModuleDependencyResolver:
    """Handles module dependency resolution"""
    
    def __init__(self):
        self.dependency_graph: Dict[str, Set[str]] = {}
        self.reverse_dependencies: Dict[str, Set[str]] = {}
    
    def add_module(self, module_name: str, dependencies: List[str]):
        """Add a module and its dependencies to the graph"""
        self.dependency_graph[module_name] = set(dependencies)
        
        # Build reverse dependency graph
        for dep in dependencies:
            if dep not in self.reverse_dependencies:
                self.reverse_dependencies[dep] = set()
            self.reverse_dependencies[dep].add(module_name)
    
    def resolve_dependencies(self, module_name: str) -> List[str]:
        """Resolve dependencies for a module in load order"""
        visited = set()
        temp_visited = set()
        load_order = []
        
        def visit(node: str):
            if node in temp_visited:
                raise ValueError(f"Circular dependency detected: {node}")
            if node in visited:
                return
            
            temp_visited.add(node)
            
            # Visit dependencies first
            for dep in self.dependency_graph.get(node, set()):
                visit(dep)
            
            temp_visited.remove(node)
            visited.add(node)
            load_order.append(node)
        
        visit(module_name)
        return load_order
    
    def get_dependents(self, module_name: str) -> Set[str]:
        """Get all modules that depend on the given module"""
        return self.reverse_dependencies.get(module_name, set())
    
    def detect_circular_dependencies(self) -> List[List[str]]:
        """Detect circular dependencies in the graph"""
        cycles = []
        visited = set()
        temp_visited = set()
        
        def dfs(node: str, path: List[str]):
            if node in temp_visited:
                cycle_start = path.index(node)
                cycles.append(path[cycle_start:] + [node])
                return
            
            if node in visited:
                return
            
            temp_visited.add(node)
            path.append(node)
            
            for dep in self.dependency_graph.get(node, set()):
                dfs(dep, path)
            
            path.pop()
            temp_visited.remove(node)
            visited.add(node)
        
        for node in self.dependency_graph:
            if node not in visited:
                dfs(node, [])
        
        return cycles

class ModuleLoader:
    """Handles dynamic module loading"""
    
    def __init__(self, module_manager: 'ModuleManager'):
        self.module_manager = module_manager
        self.loaded_modules: Dict[str, Any] = {}
        self.module_specs: Dict[str, importlib.machinery.ModuleSpec] = {}
        self.executor = ThreadPoolExecutor(max_workers=4)
    
    async def load_module(self, module_info: ModuleInfo) -> bool:
        """Load a module dynamically"""
        try:
            module_info.loaded = False
            module_info.load_time = time.time()
            
            # Load module specification
            spec = importlib.util.spec_from_file_location(
                module_info.name,
                module_info.path
            )
            
            if spec is None or spec.loader is None:
                raise ImportError(f"Could not load module specification for {module_info.name}")
            
            # Load the module
            module = importlib.util.module_from_spec(spec)
            sys.modules[module_info.name] = module
            spec.loader.exec_module(module)
            
            # Store module and spec
            self.loaded_modules[module_info.name] = module
            self.module_specs[module_info.name] = spec
            
            # Initialize module if it has an initialize function
            if hasattr(module, 'initialize'):
                if asyncio.iscoroutinefunction(module.initialize):
                    await module.initialize(self.module_manager.core)
                else:
                    module.initialize(self.module_manager.core)
            
            module_info.loaded = True
            module_info.error_count = 0
            module_info.last_error = None
            
            self.module_manager.logger.info(f"Module '{module_info.name}' loaded successfully")
            return True
            
        except Exception as e:
            module_info.loaded = False
            module_info.error_count += 1
            module_info.last_error = str(e)
            self.module_manager.logger.error(f"Failed to load module '{module_info.name}': {e}")
            return False
    
    async def unload_module(self, module_name: str) -> bool:
        """Unload a module"""
        try:
            if module_name not in self.loaded_modules:
                return True
            
            module = self.loaded_modules[module_name]
            
            # Call cleanup function if it exists
            if hasattr(module, 'cleanup'):
                if asyncio.iscoroutinefunction(module.cleanup):
                    await module.cleanup()
                else:
                    module.cleanup()
            
            # Remove from sys.modules
            if module_name in sys.modules:
                del sys.modules[module_name]
            
            # Remove from loaded modules
            del self.loaded_modules[module_name]
            
            if module_name in self.module_specs:
                del self.module_specs[module_name]
            
            self.module_manager.logger.info(f"Module '{module_name}' unloaded successfully")
            return True
            
        except Exception as e:
            self.module_manager.logger.error(f"Failed to unload module '{module_name}': {e}")
            return False
    
    def reload_module(self, module_name: str) -> bool:
        """Reload a module"""
        try:
            if module_name in self.loaded_modules:
                module = self.loaded_modules[module_name]
                importlib.reload(module)
                self.module_manager.logger.info(f"Module '{module_name}' reloaded successfully")
                return True
            return False
        except Exception as e:
            self.module_manager.logger.error(f"Failed to reload module '{module_name}': {e}")
            return False

class ModuleManager:
    """
    LilithOS Module Manager
    
    Manages the loading, unloading, and lifecycle of all system modules:
    - Automatic module discovery
    - Dependency resolution
    - Hot reloading
    - Performance monitoring
    - Error handling and recovery
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("ModuleManager")
        self.modules: Dict[str, ModuleInfo] = {}
        self.dependency_resolver = ModuleDependencyResolver()
        self.loader = ModuleLoader(self)
        self.module_paths: List[str] = []
        self.discovery_running = False
        self.lock = threading.RLock()
        
        # Performance tracking
        self.load_times: Dict[str, float] = {}
        self.error_counts: Dict[str, int] = {}
        
        # Initialize module paths
        self._init_module_paths()
    
    def _init_module_paths(self):
        """Initialize module search paths"""
        base_path = Path(__file__).parent.parent
        self.module_paths = [
            str(base_path / "modules" / "features"),
            str(base_path / "modules" / "chips"),
            str(base_path / "modules" / "core"),
            str(base_path / "modules" / "extensions")
        ]
    
    async def discover_modules(self) -> Dict[str, ModuleInfo]:
        """Discover all available modules"""
        if self.discovery_running:
            return self.modules
        
        self.discovery_running = True
        discovered_modules = {}
        
        try:
            for module_path in self.module_paths:
                path = Path(module_path)
                if not path.exists():
                    continue
                
                # Scan for module directories
                for item in path.iterdir():
                    if item.is_dir() and not item.name.startswith('.'):
                        module_info = await self._analyze_module(item)
                        if module_info:
                            discovered_modules[module_info.name] = module_info
            
            self.modules = discovered_modules
            self.logger.info(f"Discovered {len(discovered_modules)} modules")
            
        except Exception as e:
            self.logger.error(f"Module discovery failed: {e}")
        finally:
            self.discovery_running = False
        
        return discovered_modules
    
    async def _analyze_module(self, module_path: Path) -> Optional[ModuleInfo]:
        """Analyze a module directory and extract information"""
        try:
            # Look for module configuration files
            config_files = ['module.yaml', 'module.yml', 'module.json', 'README.md']
            config_data = {}
            
            for config_file in config_files:
                config_path = module_path / config_file
                if config_path.exists():
                    if config_file.endswith('.yaml') or config_file.endswith('.yml'):
                        with open(config_path, 'r', encoding='utf-8') as f:
                            config_data = yaml.safe_load(f) or {}
                    elif config_file.endswith('.json'):
                        with open(config_path, 'r', encoding='utf-8') as f:
                            config_data = json.load(f)
                    elif config_file == 'README.md':
                        # Extract basic info from README
                        with open(config_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            config_data = self._extract_readme_info(content)
                    break
            
            # Look for main module file
            main_files = ['main.py', 'module.py', f"{module_path.name}.py"]
            main_file = None
            
            for main_file_name in main_files:
                potential_file = module_path / main_file_name
                if potential_file.exists():
                    main_file = potential_file
                    break
            
            if not main_file:
                return None
            
            # Create module info
            module_info = ModuleInfo(
                name=module_path.name,
                path=str(main_file),
                version=config_data.get('version', '1.0.0'),
                description=config_data.get('description', ''),
                author=config_data.get('author', ''),
                dependencies=config_data.get('dependencies', []),
                conflicts=config_data.get('conflicts', []),
                category=config_data.get('category', 'general'),
                priority=config_data.get('priority', 0),
                enabled=config_data.get('enabled', True)
            )
            
            # Add to dependency resolver
            self.dependency_resolver.add_module(module_info.name, module_info.dependencies)
            
            return module_info
            
        except Exception as e:
            self.logger.error(f"Failed to analyze module {module_path}: {e}")
            return None
    
    def _extract_readme_info(self, content: str) -> Dict[str, Any]:
        """Extract basic module information from README content"""
        info = {}
        
        # Extract version
        import re
        version_match = re.search(r'version[:\s]+([\d.]+)', content, re.IGNORECASE)
        if version_match:
            info['version'] = version_match.group(1)
        
        # Extract description (first paragraph)
        lines = content.split('\n')
        description_lines = []
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#'):
                description_lines.append(line)
                if len(description_lines) >= 3:  # Limit to first 3 lines
                    break
        
        if description_lines:
            info['description'] = ' '.join(description_lines)
        
        return info
    
    async def load_all_modules(self) -> bool:
        """Load all discovered modules"""
        try:
            # Discover modules first
            await self.discover_modules()
            
            # Sort modules by priority and dependencies
            load_order = self._get_load_order()
            
            # Load modules in order
            for module_name in load_order:
                module_info = self.modules.get(module_name)
                if module_info and module_info.enabled:
                    await self.load_module(module_name)
            
            self.logger.info(f"Loaded {len([m for m in self.modules.values() if m.loaded])} modules")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load modules: {e}")
            return False
    
    def _get_load_order(self) -> List[str]:
        """Get the order in which modules should be loaded"""
        # Check for circular dependencies
        cycles = self.dependency_resolver.detect_circular_dependencies()
        if cycles:
            self.logger.warning(f"Circular dependencies detected: {cycles}")
        
        # Sort by priority first
        sorted_modules = sorted(
            self.modules.values(),
            key=lambda m: (-m.priority, m.name)
        )
        
        # Resolve dependencies
        load_order = []
        loaded = set()
        
        for module_info in sorted_modules:
            if module_info.name not in loaded:
                deps = self.dependency_resolver.resolve_dependencies(module_info.name)
                for dep in deps:
                    if dep not in loaded and dep in self.modules:
                        load_order.append(dep)
                        loaded.add(dep)
        
        return load_order
    
    async def load_module(self, module_name: str) -> bool:
        """Load a specific module"""
        try:
            module_info = self.modules.get(module_name)
            if not module_info:
                self.logger.error(f"Module '{module_name}' not found")
                return False
            
            if module_info.loaded:
                self.logger.info(f"Module '{module_name}' already loaded")
                return True
            
            # Check conflicts
            for conflict in module_info.conflicts:
                if conflict in self.modules and self.modules[conflict].loaded:
                    self.logger.error(f"Module '{module_name}' conflicts with '{conflict}'")
                    return False
            
            # Load the module
            success = await self.loader.load_module(module_info)
            if success:
                self.load_times[module_name] = time.time() - module_info.load_time
            
            return success
            
        except Exception as e:
            self.logger.error(f"Failed to load module '{module_name}': {e}")
            return False
    
    async def unload_module(self, module_name: str) -> bool:
        """Unload a specific module"""
        try:
            # Check dependents
            dependents = self.dependency_resolver.get_dependents(module_name)
            loaded_dependents = [dep for dep in dependents if dep in self.modules and self.modules[dep].loaded]
            
            if loaded_dependents:
                self.logger.warning(f"Cannot unload '{module_name}': has dependents {loaded_dependents}")
                return False
            
            # Unload the module
            success = await self.loader.unload_module(module_name)
            if success and module_name in self.modules:
                self.modules[module_name].loaded = False
            
            return success
            
        except Exception as e:
            self.logger.error(f"Failed to unload module '{module_name}': {e}")
            return False
    
    async def stop_all_modules(self) -> bool:
        """Stop all loaded modules"""
        try:
            # Unload modules in reverse dependency order
            loaded_modules = [name for name, info in self.modules.items() if info.loaded]
            
            for module_name in reversed(loaded_modules):
                await self.unload_module(module_name)
            
            self.logger.info("All modules stopped successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to stop modules: {e}")
            return False
    
    def get_module_info(self, module_name: str) -> Optional[ModuleInfo]:
        """Get information about a module"""
        return self.modules.get(module_name)
    
    def list_modules(self, category: Optional[str] = None) -> List[ModuleInfo]:
        """List all modules, optionally filtered by category"""
        modules = list(self.modules.values())
        if category:
            modules = [m for m in modules if m.category == category]
        return modules
    
    def get_module_stats(self) -> Dict[str, Any]:
        """Get module statistics"""
        total_modules = len(self.modules)
        loaded_modules = len([m for m in self.modules.values() if m.loaded])
        error_modules = len([m for m in self.modules.values() if m.error_count > 0])
        
        return {
            "total_modules": total_modules,
            "loaded_modules": loaded_modules,
            "error_modules": error_modules,
            "load_success_rate": loaded_modules / total_modules if total_modules > 0 else 0,
            "average_load_time": sum(self.load_times.values()) / len(self.load_times) if self.load_times else 0
        }
    
    def reload_module(self, module_name: str) -> bool:
        """Reload a module"""
        return self.loader.reload_module(module_name)
    
    def enable_module(self, module_name: str) -> bool:
        """Enable a module"""
        if module_name in self.modules:
            self.modules[module_name].enabled = True
            return True
        return False
    
    def disable_module(self, module_name: str) -> bool:
        """Disable a module"""
        if module_name in self.modules:
            self.modules[module_name].enabled = False
            return True
        return False 