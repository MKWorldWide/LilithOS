"""
📝 Logging Configuration

This module provides structured logging configuration for the TrafficFlou system,
including console and file logging with different levels and formats.

Author: TrafficFlou Team
Version: 1.0.0
"""

import logging
import logging.handlers
import sys
from pathlib import Path
from typing import Optional

import structlog
from structlog.stdlib import LoggerFactory


def setup_logging(
    level: str = "INFO",
    format_type: str = "json",
    file_enabled: bool = True,
    file_path: str = "logs/trafficflou.log",
    max_file_size: int = 100,
    backup_count: int = 5,
    console_enabled: bool = True
) -> structlog.BoundLogger:
    """
    Setup structured logging for the TrafficFlou system.
    
    Args:
        level (str): Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        format_type (str): Log format type (json, text)
        file_enabled (bool): Enable file logging
        file_path (str): Path to log file
        max_file_size (int): Maximum log file size in MB
        backup_count (int): Number of backup log files
        console_enabled (bool): Enable console logging
        
    Returns:
        structlog.BoundLogger: Configured logger instance
    """
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer() if format_type == "json" else structlog.dev.ConsoleRenderer(),
        ],
        context_class=dict,
        logger_factory=LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Get the root logger
    logger = structlog.get_logger()
    
    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # Set log level
    log_level = getattr(logging, level.upper(), logging.INFO)
    logger.setLevel(log_level)
    
    # Create formatter
    if format_type == "json":
        formatter = logging.Formatter(
            '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "message": "%(message)s"}'
        )
    else:
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    # Console handler
    if console_enabled:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(log_level)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
    
    # File handler
    if file_enabled:
        try:
            # Create log directory if it doesn't exist
            log_path = Path(file_path)
            log_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Create rotating file handler
            file_handler = logging.handlers.RotatingFileHandler(
                file_path,
                maxBytes=max_file_size * 1024 * 1024,  # Convert MB to bytes
                backupCount=backup_count,
                encoding='utf-8'
            )
            file_handler.setLevel(log_level)
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
            
        except Exception as e:
            # Fallback to console logging if file logging fails
            print(f"Warning: Failed to setup file logging: {e}")
            if not console_enabled:
                console_handler = logging.StreamHandler(sys.stdout)
                console_handler.setLevel(log_level)
                console_handler.setFormatter(formatter)
                logger.addHandler(console_handler)
    
    return logger


def get_logger(name: str) -> structlog.BoundLogger:
    """
    Get a logger instance for a specific module.
    
    Args:
        name (str): Logger name (usually __name__)
        
    Returns:
        structlog.BoundLogger: Logger instance
    """
    return structlog.get_logger(name)


def log_performance(func):
    """
    Decorator to log function performance metrics.
    
    Args:
        func: Function to decorate
        
    Returns:
        Decorated function
    """
    import time
    import functools
    
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger = get_logger(func.__module__)
        start_time = time.time()
        
        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            logger.info(
                "Function executed successfully",
                function=func.__name__,
                execution_time=execution_time,
                success=True
            )
            
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            logger.error(
                "Function execution failed",
                function=func.__name__,
                execution_time=execution_time,
                error=str(e),
                success=False
            )
            
            raise
    
    return wrapper


def log_async_performance(func):
    """
    Decorator to log async function performance metrics.
    
    Args:
        func: Async function to decorate
        
    Returns:
        Decorated async function
    """
    import time
    import functools
    
    @functools.wraps(func)
    async def wrapper(*args, **kwargs):
        logger = get_logger(func.__module__)
        start_time = time.time()
        
        try:
            result = await func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            logger.info(
                "Async function executed successfully",
                function=func.__name__,
                execution_time=execution_time,
                success=True
            )
            
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            logger.error(
                "Async function execution failed",
                function=func.__name__,
                execution_time=execution_time,
                error=str(e),
                success=False
            )
            
            raise
    
    return wrapper


class LogContext:
    """
    Context manager for logging with additional context.
    
    Usage:
        with LogContext("session_id", session_id):
            # All logs in this context will include session_id
            logger.info("Processing request")
    """
    
    def __init__(self, **context):
        """
        Initialize log context.
        
        Args:
            **context: Key-value pairs for context
        """
        self.context = context
        self.logger = structlog.get_logger()
    
    def __enter__(self):
        """Enter the log context."""
        self.bound_logger = self.logger.bind(**self.context)
        return self.bound_logger
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit the log context."""
        pass


def setup_request_logging():
    """
    Setup request-specific logging middleware.
    
    Returns:
        Middleware function for request logging
    """
    def middleware(request, call_next):
        logger = get_logger("request")
        
        # Log request start
        start_time = time.time()
        logger.info(
            "Request started",
            method=request.method,
            url=str(request.url),
            client_ip=request.client.host if request.client else None
        )
        
        try:
            response = call_next(request)
            
            # Log request completion
            execution_time = time.time() - start_time
            logger.info(
                "Request completed",
                method=request.method,
                url=str(request.url),
                status_code=response.status_code,
                execution_time=execution_time
            )
            
            return response
            
        except Exception as e:
            # Log request error
            execution_time = time.time() - start_time
            logger.error(
                "Request failed",
                method=request.method,
                url=str(request.url),
                error=str(e),
                execution_time=execution_time
            )
            raise
    
    return middleware 