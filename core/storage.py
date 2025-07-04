"""
LilithOS Storage Manager
=======================

Handles data storage and management:
- File system operations
- Data caching and optimization
- Backup and recovery
- Storage monitoring and cleanup
- Database management
"""

import os
import asyncio
import logging
import threading
import time
import shutil
import hashlib
import json
import yaml
import sqlite3
import pickle
import gzip
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple, Union
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict
import aiosqlite

class StorageType(Enum):
    """Storage type enumeration"""
    FILE = "file"
    DATABASE = "database"
    CACHE = "cache"
    BACKUP = "backup"
    TEMP = "temp"

class FileType(Enum):
    """File type enumeration"""
    DATA = "data"
    CONFIG = "config"
    LOG = "log"
    CACHE = "cache"
    BACKUP = "backup"
    TEMP = "temp"

@dataclass
class StorageItem:
    """Storage item information"""
    path: str
    storage_type: StorageType
    file_type: FileType
    size: int
    created_at: float
    modified_at: float
    accessed_at: float
    checksum: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class CacheEntry:
    """Cache entry information"""
    key: str
    value: Any
    created_at: float
    expires_at: Optional[float] = None
    access_count: int = 0
    last_accessed: float = field(default_factory=time.time)

@dataclass
class StorageStats:
    """Storage statistics"""
    total_files: int = 0
    total_size: int = 0
    cache_hits: int = 0
    cache_misses: int = 0
    cache_size: int = 0
    backup_count: int = 0
    backup_size: int = 0

class FileManager:
    """Manages file system operations"""
    
    def __init__(self, storage_manager: 'StorageManager'):
        self.storage_manager = storage_manager
        self.base_path = Path("data")
        self.storage_paths: Dict[StorageType, Path] = {}
        self.file_registry: Dict[str, StorageItem] = {}
        self.lock = threading.RLock()
        
        # Initialize storage paths
        self._init_storage_paths()
    
    def _init_storage_paths(self):
        """Initialize storage directory paths"""
        self.storage_paths = {
            StorageType.FILE: self.base_path / "files",
            StorageType.DATABASE: self.base_path / "databases",
            StorageType.CACHE: self.base_path / "cache",
            StorageType.BACKUP: self.base_path / "backups",
            StorageType.TEMP: self.base_path / "temp"
        }
        
        # Create directories
        for path in self.storage_paths.values():
            path.mkdir(parents=True, exist_ok=True)
    
    async def save_file(self, file_path: str, data: Union[str, bytes], file_type: FileType = FileType.DATA, compress: bool = False) -> bool:
        """Save data to a file"""
        try:
            full_path = self.storage_paths[StorageType.FILE] / file_path
            
            # Ensure directory exists
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Prepare data
            if isinstance(data, str):
                data_bytes = data.encode('utf-8')
            else:
                data_bytes = data
            
            # Compress if requested
            if compress:
                data_bytes = gzip.compress(data_bytes)
            
            # Write file
            with open(full_path, 'wb') as f:
                f.write(data_bytes)
            
            # Calculate checksum
            checksum = hashlib.md5(data_bytes).hexdigest()
            
            # Update registry
            storage_item = StorageItem(
                path=str(full_path),
                storage_type=StorageType.FILE,
                file_type=file_type,
                size=len(data_bytes),
                created_at=time.time(),
                modified_at=time.time(),
                accessed_at=time.time(),
                checksum=checksum,
                metadata={"compressed": compress}
            )
            
            with self.lock:
                self.file_registry[str(full_path)] = storage_item
            
            self.storage_manager.logger.info(f"File saved: {file_path}")
            return True
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to save file {file_path}: {e}")
            return False
    
    async def load_file(self, file_path: str, decompress: bool = False) -> Optional[Union[str, bytes]]:
        """Load data from a file"""
        try:
            full_path = self.storage_paths[StorageType.FILE] / file_path
            
            if not full_path.exists():
                return None
            
            # Read file
            with open(full_path, 'rb') as f:
                data = f.read()
            
            # Decompress if needed
            if decompress:
                data = gzip.decompress(data)
            
            # Update access time
            with self.lock:
                if str(full_path) in self.file_registry:
                    self.file_registry[str(full_path)].accessed_at = time.time()
            
            # Return as string if it looks like text
            try:
                return data.decode('utf-8')
            except UnicodeDecodeError:
                return data
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to load file {file_path}: {e}")
            return None
    
    async def delete_file(self, file_path: str) -> bool:
        """Delete a file"""
        try:
            full_path = self.storage_paths[StorageType.FILE] / file_path
            
            if full_path.exists():
                full_path.unlink()
                
                # Remove from registry
                with self.lock:
                    if str(full_path) in self.file_registry:
                        del self.file_registry[str(full_path)]
                
                self.storage_manager.logger.info(f"File deleted: {file_path}")
                return True
            
            return False
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to delete file {file_path}: {e}")
            return False
    
    async def list_files(self, file_type: Optional[FileType] = None) -> List[StorageItem]:
        """List files in storage"""
        try:
            with self.lock:
                items = list(self.file_registry.values())
                
                if file_type:
                    items = [item for item in items if item.file_type == file_type]
                
                return items
                
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to list files: {e}")
            return []
    
    async def get_file_info(self, file_path: str) -> Optional[StorageItem]:
        """Get information about a file"""
        try:
            full_path = self.storage_paths[StorageType.FILE] / file_path
            
            with self.lock:
                return self.file_registry.get(str(full_path))
                
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to get file info: {e}")
            return None

class CacheManager:
    """Manages data caching"""
    
    def __init__(self, storage_manager: 'StorageManager', max_size: int = 1000, max_memory: int = 100 * 1024 * 1024):  # 100MB
        self.storage_manager = storage_manager
        self.max_size = max_size
        self.max_memory = max_memory
        self.cache: Dict[str, CacheEntry] = {}
        self.stats = StorageStats()
        self.lock = threading.RLock()
    
    async def get(self, key: str) -> Optional[Any]:
        """Get a value from cache"""
        try:
            with self.lock:
                if key in self.cache:
                    entry = self.cache[key]
                    
                    # Check if expired
                    if entry.expires_at and time.time() > entry.expires_at:
                        del self.cache[key]
                        self.stats.cache_misses += 1
                        return None
                    
                    # Update access info
                    entry.access_count += 1
                    entry.last_accessed = time.time()
                    
                    self.stats.cache_hits += 1
                    return entry.value
                else:
                    self.stats.cache_misses += 1
                    return None
                    
        except Exception as e:
            self.storage_manager.logger.error(f"Cache get failed: {e}")
            return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set a value in cache"""
        try:
            with self.lock:
                # Check if we need to evict items
                await self._evict_if_needed()
                
                # Create cache entry
                expires_at = None
                if ttl:
                    expires_at = time.time() + ttl
                
                entry = CacheEntry(
                    key=key,
                    value=value,
                    created_at=time.time(),
                    expires_at=expires_at,
                    access_count=0,
                    last_accessed=time.time()
                )
                
                self.cache[key] = entry
                self.stats.cache_size = len(self.cache)
                
                return True
                
        except Exception as e:
            self.storage_manager.logger.error(f"Cache set failed: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete a value from cache"""
        try:
            with self.lock:
                if key in self.cache:
                    del self.cache[key]
                    self.stats.cache_size = len(self.cache)
                    return True
                return False
                
        except Exception as e:
            self.storage_manager.logger.error(f"Cache delete failed: {e}")
            return False
    
    async def clear(self) -> bool:
        """Clear all cache entries"""
        try:
            with self.lock:
                self.cache.clear()
                self.stats.cache_size = 0
                return True
                
        except Exception as e:
            self.storage_manager.logger.error(f"Cache clear failed: {e}")
            return False
    
    async def _evict_if_needed(self):
        """Evict cache entries if needed"""
        if len(self.cache) >= self.max_size:
            # Remove least recently used items
            sorted_entries = sorted(
                self.cache.items(),
                key=lambda x: x[1].last_accessed
            )
            
            # Remove 20% of entries
            to_remove = int(self.max_size * 0.2)
            for key, _ in sorted_entries[:to_remove]:
                del self.cache[key]
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        return {
            "size": len(self.cache),
            "max_size": self.max_size,
            "hits": self.stats.cache_hits,
            "misses": self.stats.cache_misses,
            "hit_rate": self.stats.cache_hits / (self.stats.cache_hits + self.stats.cache_misses) if (self.stats.cache_hits + self.stats.cache_misses) > 0 else 0
        }

class DatabaseManager:
    """Manages database operations"""
    
    def __init__(self, storage_manager: 'StorageManager'):
        self.storage_manager = storage_manager
        self.databases: Dict[str, aiosqlite.Connection] = {}
        self.base_path = storage_manager.file_manager.storage_paths[StorageType.DATABASE]
    
    async def get_database(self, name: str) -> Optional[aiosqlite.Connection]:
        """Get or create a database connection"""
        try:
            if name not in self.databases:
                db_path = self.base_path / f"{name}.db"
                self.databases[name] = await aiosqlite.connect(str(db_path))
                
                # Enable foreign keys
                await self.databases[name].execute("PRAGMA foreign_keys = ON")
                
                self.storage_manager.logger.info(f"Database connection created: {name}")
            
            return self.databases[name]
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to get database {name}: {e}")
            return None
    
    async def execute_query(self, db_name: str, query: str, params: tuple = ()) -> Optional[List[tuple]]:
        """Execute a database query"""
        try:
            db = await self.get_database(db_name)
            if not db:
                return None
            
            cursor = await db.execute(query, params)
            result = await cursor.fetchall()
            await cursor.close()
            
            return result
            
        except Exception as e:
            self.storage_manager.logger.error(f"Database query failed: {e}")
            return None
    
    async def execute_transaction(self, db_name: str, queries: List[Tuple[str, tuple]]) -> bool:
        """Execute multiple queries in a transaction"""
        try:
            db = await self.get_database(db_name)
            if not db:
                return False
            
            async with db:
                for query, params in queries:
                    await db.execute(query, params)
                
                await db.commit()
                return True
                
        except Exception as e:
            self.storage_manager.logger.error(f"Database transaction failed: {e}")
            return False
    
    async def close_database(self, name: str) -> bool:
        """Close a database connection"""
        try:
            if name in self.databases:
                await self.databases[name].close()
                del self.databases[name]
                return True
            return False
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to close database {name}: {e}")
            return False
    
    async def close_all(self):
        """Close all database connections"""
        try:
            for name in list(self.databases.keys()):
                await self.close_database(name)
                
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to close databases: {e}")

class BackupManager:
    """Manages backup operations"""
    
    def __init__(self, storage_manager: 'StorageManager'):
        self.storage_manager = storage_manager
        self.backup_path = storage_manager.file_manager.storage_paths[StorageType.BACKUP]
        self.backup_retention_days = 30
    
    async def create_backup(self, source_path: str, backup_name: Optional[str] = None) -> bool:
        """Create a backup of a file or directory"""
        try:
            source = Path(source_path)
            if not source.exists():
                return False
            
            if not backup_name:
                timestamp = time.strftime("%Y%m%d_%H%M%S")
                backup_name = f"{source.name}_{timestamp}"
            
            backup_file = self.backup_path / f"{backup_name}.tar.gz"
            
            # Create compressed backup
            if source.is_file():
                # Single file backup
                with open(source, 'rb') as src, gzip.open(backup_file, 'wb') as dst:
                    shutil.copyfileobj(src, dst)
            else:
                # Directory backup
                shutil.make_archive(
                    str(backup_file.with_suffix('')),
                    'gztar',
                    source
                )
            
            self.storage_manager.logger.info(f"Backup created: {backup_name}")
            return True
            
        except Exception as e:
            self.storage_manager.logger.error(f"Backup creation failed: {e}")
            return False
    
    async def restore_backup(self, backup_name: str, target_path: str) -> bool:
        """Restore a backup"""
        try:
            backup_file = self.backup_path / f"{backup_name}.tar.gz"
            if not backup_file.exists():
                return False
            
            target = Path(target_path)
            
            # Restore from compressed backup
            if backup_file.suffix == '.gz':
                # Single file restore
                with gzip.open(backup_file, 'rb') as src, open(target, 'wb') as dst:
                    shutil.copyfileobj(src, dst)
            else:
                # Directory restore
                shutil.unpack_archive(str(backup_file), target)
            
            self.storage_manager.logger.info(f"Backup restored: {backup_name}")
            return True
            
        except Exception as e:
            self.storage_manager.logger.error(f"Backup restore failed: {e}")
            return False
    
    async def list_backups(self) -> List[str]:
        """List available backups"""
        try:
            backups = []
            for file in self.backup_path.glob("*.tar.gz"):
                backups.append(file.stem)
            return backups
            
        except Exception as e:
            self.storage_manager.logger.error(f"Failed to list backups: {e}")
            return []
    
    async def cleanup_old_backups(self) -> int:
        """Remove old backups"""
        try:
            current_time = time.time()
            cutoff_time = current_time - (self.backup_retention_days * 86400)
            
            removed_count = 0
            for backup_file in self.backup_path.glob("*.tar.gz"):
                if backup_file.stat().st_mtime < cutoff_time:
                    backup_file.unlink()
                    removed_count += 1
            
            if removed_count > 0:
                self.storage_manager.logger.info(f"Removed {removed_count} old backups")
            
            return removed_count
            
        except Exception as e:
            self.storage_manager.logger.error(f"Backup cleanup failed: {e}")
            return 0

class StorageManager:
    """
    LilithOS Storage Manager
    
    Manages data storage and caching:
    - File system operations
    - Data caching and optimization
    - Database management
    - Backup and recovery
    - Storage monitoring and cleanup
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("StorageManager")
        self.file_manager = FileManager(self)
        self.cache_manager = CacheManager(self)
        self.database_manager = DatabaseManager(self)
        self.backup_manager = BackupManager(self)
        self.stats = StorageStats()
        self.initialized = False
    
    async def initialize(self) -> bool:
        """Initialize the storage manager"""
        try:
            self.logger.info("Initializing Storage Manager...")
            
            # Initialize components
            await self._scan_storage()
            
            # Start maintenance task
            asyncio.create_task(self._maintenance_loop())
            
            self.initialized = True
            self.logger.info("Storage Manager initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Storage Manager: {e}")
            return False
    
    async def _scan_storage(self):
        """Scan existing storage and build registry"""
        try:
            # Scan file storage
            for file_path in self.file_manager.storage_paths[StorageType.FILE].rglob("*"):
                if file_path.is_file():
                    stat = file_path.stat()
                    
                    # Determine file type
                    file_type = FileType.DATA
                    if file_path.suffix in ['.yaml', '.yml', '.json', '.ini']:
                        file_type = FileType.CONFIG
                    elif file_path.suffix == '.log':
                        file_type = FileType.LOG
                    elif file_path.suffix == '.cache':
                        file_type = FileType.CACHE
                    elif file_path.suffix == '.backup':
                        file_type = FileType.BACKUP
                    
                    # Calculate checksum
                    with open(file_path, 'rb') as f:
                        checksum = hashlib.md5(f.read()).hexdigest()
                    
                    storage_item = StorageItem(
                        path=str(file_path),
                        storage_type=StorageType.FILE,
                        file_type=file_type,
                        size=stat.st_size,
                        created_at=stat.st_ctime,
                        modified_at=stat.st_mtime,
                        accessed_at=stat.st_atime,
                        checksum=checksum
                    )
                    
                    self.file_manager.file_registry[str(file_path)] = storage_item
            
            self.logger.info(f"Scanned {len(self.file_manager.file_registry)} files")
            
        except Exception as e:
            self.logger.error(f"Storage scan failed: {e}")
    
    async def _maintenance_loop(self):
        """Storage maintenance loop"""
        while True:
            try:
                # Update statistics
                await self._update_stats()
                
                # Cleanup old backups
                await self.backup_manager.cleanup_old_backups()
                
                # Cleanup temp files
                await self._cleanup_temp_files()
                
                await asyncio.sleep(3600)  # Run every hour
                
            except Exception as e:
                self.logger.error(f"Storage maintenance error: {e}")
                await asyncio.sleep(1800)  # 30 minutes
    
    async def _update_stats(self):
        """Update storage statistics"""
        try:
            # File stats
            files = await self.file_manager.list_files()
            self.stats.total_files = len(files)
            self.stats.total_size = sum(f.size for f in files)
            
            # Cache stats
            cache_stats = self.cache_manager.get_stats()
            self.stats.cache_hits = cache_stats["hits"]
            self.stats.cache_misses = cache_stats["misses"]
            self.stats.cache_size = cache_stats["size"]
            
            # Backup stats
            backups = await self.backup_manager.list_backups()
            self.stats.backup_count = len(backups)
            
            backup_size = 0
            for backup in backups:
                backup_file = self.backup_manager.backup_path / f"{backup}.tar.gz"
                if backup_file.exists():
                    backup_size += backup_file.stat().st_size
            self.stats.backup_size = backup_size
            
        except Exception as e:
            self.logger.error(f"Failed to update stats: {e}")
    
    async def _cleanup_temp_files(self):
        """Cleanup temporary files"""
        try:
            temp_path = self.file_manager.storage_paths[StorageType.TEMP]
            current_time = time.time()
            
            for temp_file in temp_path.glob("*"):
                if temp_file.is_file():
                    # Remove files older than 24 hours
                    if current_time - temp_file.stat().st_mtime > 86400:
                        temp_file.unlink()
                        
        except Exception as e:
            self.logger.error(f"Temp file cleanup failed: {e}")
    
    async def save_data(self, key: str, data: Any, storage_type: StorageType = StorageType.FILE, compress: bool = False) -> bool:
        """Save data to storage"""
        try:
            if storage_type == StorageType.CACHE:
                return await self.cache_manager.set(key, data)
            elif storage_type == StorageType.FILE:
                if isinstance(data, (dict, list)):
                    data = json.dumps(data, indent=2)
                elif not isinstance(data, (str, bytes)):
                    data = pickle.dumps(data)
                
                return await self.file_manager.save_file(key, data, compress=compress)
            else:
                self.logger.error(f"Unsupported storage type: {storage_type}")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to save data: {e}")
            return False
    
    async def load_data(self, key: str, storage_type: StorageType = StorageType.FILE) -> Optional[Any]:
        """Load data from storage"""
        try:
            if storage_type == StorageType.CACHE:
                return await self.cache_manager.get(key)
            elif storage_type == StorageType.FILE:
                data = await self.file_manager.load_file(key)
                if data is None:
                    return None
                
                # Try to parse as JSON or pickle
                if isinstance(data, str):
                    try:
                        return json.loads(data)
                    except json.JSONDecodeError:
                        return data
                else:
                    try:
                        return pickle.loads(data)
                    except (pickle.UnpicklingError, EOFError):
                        return data
            else:
                self.logger.error(f"Unsupported storage type: {storage_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"Failed to load data: {e}")
            return None
    
    def get_storage_stats(self) -> Dict[str, Any]:
        """Get storage statistics"""
        return {
            "total_files": self.stats.total_files,
            "total_size": self.stats.total_size,
            "cache_stats": self.cache_manager.get_stats(),
            "backup_count": self.stats.backup_count,
            "backup_size": self.stats.backup_size
        }
    
    async def cleanup(self):
        """Cleanup storage manager resources"""
        try:
            self.logger.info("Cleaning up Storage Manager...")
            
            # Close database connections
            await self.database_manager.close_all()
            
            # Clear cache
            await self.cache_manager.clear()
            
            self.logger.info("Storage Manager cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Storage Manager cleanup failed: {e}")
    
    async def run_maintenance(self) -> bool:
        """Run storage maintenance tasks"""
        try:
            # Update statistics
            await self._update_stats()
            
            # Cleanup old backups
            await self.backup_manager.cleanup_old_backups()
            
            # Cleanup temp files
            await self._cleanup_temp_files()
            
            self.logger.info("Storage maintenance completed")
            return True
            
        except Exception as e:
            self.logger.error(f"Storage maintenance failed: {e}")
            return False 