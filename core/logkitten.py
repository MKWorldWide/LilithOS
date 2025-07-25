"""
LogKitten - Unified Logging System for LilithOS

A high-performance, structured logging system that provides:
- Unified logging across all system components
- Log rotation and retention policies
- Log levels and filtering
- Structured JSON logging
- Remote log shipping
- Log correlation IDs
- Performance metrics integration
"""

import asyncio
import json
import logging
import logging.handlers
import os
import sys
import time
import traceback
import zlib
from collections import deque
from dataclasses import asdict, dataclass, field
from datetime import datetime
from enum import Enum, auto
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import aiofiles
import aiofiles.os
import psutil
from typing_extensions import Self

# Import core components
from .divinebus import EventBus, event_bus

# Constants
DEFAULT_LOG_DIR = Path("/var/log/lilithos")
MAX_LOG_SIZE = 10 * 1024 * 1024  # 10MB per log file
BACKUP_COUNT = 5  # Number of backup log files to keep
LOG_QUEUE_SIZE = 1000  # In-memory log queue size
LOG_FLUSH_INTERVAL = 5.0  # Seconds between log flushes

class LogLevel(Enum):
    """Standard log levels with numeric values for comparison."""
    TRACE = 5
    DEBUG = 10
    INFO = 20
    NOTICE = 25
    WARNING = 30
    ERROR = 40
    CRITICAL = 50
    FATAL = 60

@dataclass
class LogEntry:
    """Structured log entry with metadata."""
    timestamp: float
    level: LogLevel
    message: str
    logger: str
    process_id: int
    thread_id: int
    module: str
    function: str
    line_no: int
    correlation_id: Optional[str] = None
    extra: Dict[str, Any] = field(default_factory=dict)
    exc_info: Optional[Dict[str, Any]] = None
    stack_info: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert log entry to a dictionary for JSON serialization."""
        return {
            "timestamp": self.timestamp,
            "iso_time": datetime.utcfromtimestamp(self.timestamp).isoformat() + "Z",
            "level": self.level.name,
            "level_no": self.level.value,
            "message": self.message,
            "logger": self.logger,
            "process_id": self.process_id,
            "thread_id": self.thread_id,
            "module": self.module,
            "function": self.function,
            "line_no": self.line_no,
            "correlation_id": self.correlation_id,
            "extra": self.extra,
            "exc_info": self.exc_info,
            "stack_info": self.stack_info,
        }
    
    @classmethod
    def from_record(cls, record: logging.LogRecord) -> 'LogEntry':
        """Create a LogEntry from a logging.LogRecord."""
        exc_info = None
        if record.exc_info:
            exc_info = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else None,
                "message": str(record.exc_info[1]) if record.exc_info[1] else None,
                "traceback": ''.join(traceback.format_exception(*record.exc_info)) if record.exc_info else None
            }
        
        return cls(
            timestamp=record.created,
            level=LogLevel(record.levelno),
            message=record.getMessage(),
            logger=record.name,
            process_id=record.process,
            thread_id=record.thread,
            module=record.module,
            function=record.funcName,
            line_no=record.lineno,
            correlation_id=getattr(record, 'correlation_id', None),
            extra=getattr(record, 'extra', {}),
            exc_info=exc_info,
            stack_info=record.stack_info
        )

class LogHandler(logging.Handler):
    """Custom log handler that forwards logs to LogKitten."""
    
    def __init__(self, logkitten: 'LogKitten', level=logging.NOTSET):
        super().__init__(level)
        self.logkitten = logkitten
    
    def emit(self, record):
        """Eit a record."""
        try:
            entry = LogEntry.from_record(record)
            self.logkitten._enqueue(entry)
        except Exception as e:
            sys.stderr.write(f"Error in LogHandler.emit: {e}\n")
            sys.stderr.write(f"Record: {record}\n")
            traceback.print_exc()

class LogKitten:
    """
    LogKitten - The purr-fect logging system for LilithOS.
    
    A high-performance, structured logging system that provides:
    - Unified logging across all system components
    - Log rotation and retention policies
    - Log levels and filtering
    - Structured JSON logging
    - Remote log shipping
    - Log correlation IDs
    - Performance metrics integration
    """
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self._initialized = True
        self._log_dir = DEFAULT_LOG_DIR
        self._log_file = self._log_dir / "lilithos.log"
        self._log_queue = asyncio.Queue(maxsize=LOG_QUEUE_SIZE)
        self._flush_task = None
        self._running = False
        self._loggers = {}
        self._handlers = {}
        self._log_level = LogLevel.INFO
        self._correlation_id = None
        self._context = {}
        self._event_bus = event_bus
        self._setup_directories()
        self._setup_event_handlers()
    
    def _setup_directories(self) -> None:
        """Ensure log directory exists."""
        try:
            self._log_dir.mkdir(parents=True, exist_ok=True, mode=0o755)
        except Exception as e:
            sys.stderr.write(f"Failed to create log directory {self._log_dir}: {e}\n")
            raise
    
    def _setup_event_handlers(self) -> None:
        """Set up event handlers for log-related events."""
        self._event_bus.subscribe("log.flush", self._on_flush_event)
        self._event_bus.subscribe("log.set_level", self._on_set_level_event)
        self._event_bus.subscribe("log.set_correlation_id", self._on_set_correlation_id)
    
    async def _on_flush_event(self, event) -> None:
        """Handle flush event."""
        await self.flush()
    
    async def _on_set_level_event(self, event) -> None:
        """Handle set log level event."""
        level = event.get("level")
        if isinstance(level, str):
            level = LogLevel[level.upper()]
        self.set_level(level)
    
    async def _on_set_correlation_id(self, event) -> None:
        """Handle set correlation ID event."""
        self.set_correlation_id(event.get("correlation_id"))
    
    def start(self) -> None:
        """Start the logging system."""
        if self._running:
            return
            
        self._running = True
        self._flush_task = asyncio.create_task(self._flush_loop())
        
        # Set up root logger
        self.get_logger("root")
        
        # Redirect stdout and stderr
        self._redirect_stdout_stderr()
    
    async def stop(self) -> None:
        """Stop the logging system and flush all logs."""
        if not self._running:
            return
            
        self._running = False
        
        if self._flush_task:
            self._flush_task.cancel()
            try:
                await self._flush_task
            except asyncio.CancelledError:
                pass
            
        # Flush any remaining logs
        await self.flush()
    
    def _redirect_stdout_stderr(self) -> None:
        """Redirect stdout and stderr to the logging system."""
        class StreamToLogger:
            def __init__(self, logger, level):
                self.logger = logger
                self.level = level
                self.buffer = ""
                self.last_flush = time.time()
                self.flush_interval = 0.1  # seconds
            
            def write(self, message):
                if not message.strip() and message != '\n':
                    return
                    
                self.buffer += message
                
                # Flush if we have a complete line or it's been a while
                now = time.time()
                if '\n' in self.buffer or (now - self.last_flush) > self.flush_interval:
                    self.flush()
            
            def flush(self):
                if not self.buffer:
                    return
                    
                # Split into lines and log each one
                for line in self.buffer.rstrip('\n').split('\n'):
                    if line.strip():
                        self.logger.log(self.level, line)
                
                self.buffer = ""
                self.last_flush = time.time()
        
        # Redirect stdout and stderr
        sys.stdout = StreamToLogger(self.get_logger("stdout"), LogLevel.INFO)
        sys.stderr = StreamToLogger(self.get_logger("stderr"), LogLevel.ERROR)
    
    def get_logger(self, name: str) -> 'KittenLogger':
        """Get or create a logger with the given name."""
        if name in self._loggers:
            return self._loggers[name]
            
        logger = KittenLogger(name, self)
        self._loggers[name] = logger
        return logger
    
    def set_level(self, level: Union[LogLevel, str, int]) -> None:
        """Set the minimum log level."""
        if isinstance(level, str):
            level = LogLevel[level.upper()]
        elif isinstance(level, int):
            level = LogLevel(level)
            
        self._log_level = level
        
        # Update all loggers
        for logger in self._loggers.values():
            logger.setLevel(level.value)
    
    def set_correlation_id(self, correlation_id: Optional[str]) -> None:
        """Set the current correlation ID for log correlation."""
        self._correlation_id = correlation_id
    
    def get_correlation_id(self) -> Optional[str]:
        """Get the current correlation ID."""
        return self._correlation_id
    
    def bind(self, **kwargs) -> 'LogContext':
        """Bind contextual information to log entries."""
        return LogContext(self, kwargs)
    
    async def _enqueue(self, entry: LogEntry) -> None:
        """Enqueue a log entry for processing."""
        try:
            # Add correlation ID if not set
            if entry.correlation_id is None and self._correlation_id is not None:
                entry.correlation_id = self._correlation_id
                
            # Add context to extra
            if self._context:
                entry.extra.update(self._context)
                
            # Add to queue
            await self._log_queue.put(entry)
            
            # Publish log event
            self._event_bus.publish("log.entry", entry.to_dict())
            
        except asyncio.QueueFull:
            # If queue is full, drop the log entry
            sys.stderr.write(f"Log queue full, dropping log entry: {entry.message}\n")
        except Exception as e:
            sys.stderr.write(f"Error enqueuing log entry: {e}\n")
    
    async def _flush_loop(self) -> None:
        """Background task that flushes logs to disk."""
        while self._running:
            try:
                await asyncio.sleep(LOG_FLUSH_INTERVAL)
                await self.flush()
            except asyncio.CancelledError:
                break
            except Exception as e:
                sys.stderr.write(f"Error in flush loop: {e}\n")
    
    async def flush(self) -> None:
        """Flush all pending logs to disk."""
        entries = []
        
        # Get all available entries from the queue
        while not self._log_queue.empty():
            try:
                entries.append(await self._log_queue.get())
            except asyncio.QueueEmpty:
                break
        
        if not entries:
            return
        
        # Write entries to log file
        try:
            # Create log directory if it doesn't exist
            self._log_dir.mkdir(parents=True, exist_ok=True)
            
            # Rotate log file if needed
            await self._rotate_logs()
            
            # Write entries to log file
            async with aiofiles.open(self._log_file, 'a') as f:
                for entry in entries:
                    await f.write(json.dumps(entry.to_dict()) + '\n')
            
        except Exception as e:
            sys.stderr.write(f"Error writing to log file: {e}\n")
    
    async def _rotate_logs(self) -> None:
        """Rotate log files if needed."""
        try:
            # Check if log file exists and needs rotation
            if not self._log_file.exists():
                return
                
            file_size = self._log_file.stat().st_size
            if file_size < MAX_LOG_SIZE:
                return
            
            # Rotate log files
            for i in range(BACKUP_COUNT - 1, 0, -1):
                src = self._log_file.with_suffix(f".{i}.log")
                dest = self._log_file.with_suffix(f".{i+1}.log")
                
                if src.exists():
                    if dest.exists():
                        await aiofiles.os.remove(dest)
                    await aiofiles.os.rename(src, dest)
            
            # Rotate current log
            await aiofiles.os.rename(self._log_file, self._log_file.with_suffix(".1.log"))
            
        except Exception as e:
            sys.stderr.write(f"Error rotating log files: {e}\n")

class KittenLogger:
    """Logger class for LogKitten."""
    
    def __init__(self, name: str, logkitten: 'LogKitten'):
        self.name = name
        self.logkitten = logkitten
        self.level = logging.INFO
        self.handlers = []
        self.propagate = True
        self.parent = None
    
    def setLevel(self, level: Union[int, str, LogLevel]) -> None:
        """Set the logging level for this logger."""
        if isinstance(level, str):
            level = LogLevel[level.upper()].value
        elif isinstance(level, LogLevel):
            level = level.value
            
        self.level = level
    
    def isEnabledFor(self, level: Union[int, LogLevel]) -> bool:
        """Check if this logger is enabled for the given level."""
        if isinstance(level, LogLevel):
            level = level.value
        return self.level <= level
    
    def log(self, level: Union[int, LogLevel, str], msg: str, *args, **kwargs):
        """Log a message with the specified level."""
        if isinstance(level, str):
            level = LogLevel[level.upper()]
        
        if not self.isEnabledFor(level):
            return
        
        # Get the calling frame info
        frame = sys._getframe(1)
        module = frame.f_globals.get('__name__', '')
        func_name = frame.f_code.co_name
        line_no = frame.f_lineno
        
        # Create a LogRecord
        record = logging.LogRecord(
            name=self.name,
            level=level.value if isinstance(level, LogLevel) else level,
            pathname=frame.f_globals.get('__file__', ''),
            lineno=line_no,
            msg=msg,
            args=args,
            exc_info=kwargs.get('exc_info'),
            func=func_name
        )
        
        # Add extra attributes
        for key, value in kwargs.items():
            if key not in ('exc_info', 'extra'):
                setattr(record, key, value)
        
        # Add extra dict if provided
        if 'extra' in kwargs and isinstance(kwargs['extra'], dict):
            for key, value in kwargs['extra'].items():
                setattr(record, key, value)
        
        # Add correlation ID if set
        if not hasattr(record, 'correlation_id') and self.logkitten.get_correlation_id() is not None:
            record.correlation_id = self.logkitten.get_correlation_id()
        
        # Enqueue the log entry
        asyncio.create_task(self.logkitten._enqueue(LogEntry.from_record(record)))
    
    def debug(self, msg: str, *args, **kwargs):
        """Log a debug message."""
        self.log(LogLevel.DEBUG, msg, *args, **kwargs)
    
    def info(self, msg: str, *args, **kwargs):
        """Log an info message."""
        self.log(LogLevel.INFO, msg, *args, **kwargs)
    
    def warning(self, msg: str, *args, **kwargs):
        """Log a warning message."""
        self.log(LogLevel.WARNING, msg, *args, **kwargs)
    
    def error(self, msg: str, *args, **kwargs):
        """Log an error message."""
        self.log(LogLevel.ERROR, msg, *args, **kwargs)
    
    def critical(self, msg: str, *args, **kwargs):
        """Log a critical message."""
        self.log(LogLevel.CRITICAL, msg, *args, **kwargs)
    
    def exception(self, msg: str, *args, exc_info=True, **kwargs):
        """Log an exception with traceback."""
        self.log(LogLevel.ERROR, msg, *args, exc_info=exc_info, **kwargs)

class LogContext:
    """Context manager for logging with bound context."""
    
    def __init__(self, logger: KittenLogger, context: Dict[str, Any]):
        self.logger = logger
        self.context = context
        self.old_context = {}
    
    def __enter__(self) -> 'LogContext':
        # Save old context
        self.old_context = getattr(self.logger.logkitten, '_context', {})
        # Update with new context
        new_context = self.old_context.copy()
        new_context.update(self.context)
        self.logger.logkitten._context = new_context
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        # Restore old context
        self.logger.logkitten._context = self.old_context

# Singleton instance
logkitten = LogKitten()

# Shortcut functions
def get_logger(name: str = None) -> KittenLogger:
    """Get a logger with the given name."""
    return logkitten.get_logger(name or __name__)

def set_level(level: Union[LogLevel, str, int]) -> None:
    """Set the minimum log level."""
    logkitten.set_level(level)

def set_correlation_id(correlation_id: str) -> None:
    """Set the current correlation ID for log correlation."""
    logkitten.set_correlation_id(correlation_id)

def bind(**kwargs) -> LogContext:
    """Bind contextual information to log entries."""
    return logkitten.bind(**kwargs)

# Initialize default logger
logger = get_logger(__name__)
