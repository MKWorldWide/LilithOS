"""
Error Handling System - Comprehensive Exception Management

Quantum-detailed: Implements a comprehensive error handling system with custom
exception hierarchy, error recovery mechanisms, graceful degradation, and
detailed error reporting for monitoring and debugging.

Features:
- Custom exception hierarchy
- Error recovery mechanisms
- Graceful degradation strategies
- Error reporting and monitoring
- Context-aware error handling
- Performance impact tracking

Author: TrafficFlou Refactoring Team
Version: 2.0.0
License: Apache-2.0
"""

import asyncio
import functools
import time
import traceback
from abc import ABC, abstractmethod
from contextlib import asynccontextmanager, contextmanager
from typing import (
    Any, Callable, Dict, List, Optional, Type, TypeVar, Union, 
    Awaitable, Coroutine
)
from dataclasses import dataclass, field
from enum import Enum
import structlog

from .exceptions import (
    TrafficFlouError, ConfigurationError, AIModelError, 
    SessionError, TrafficGenerationError
)


class ErrorSeverity(Enum):
    """Error severity levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ErrorCategory(Enum):
    """Error categories for classification."""
    CONFIGURATION = "configuration"
    AI_MODEL = "ai_model"
    TRAFFIC_GENERATION = "traffic_generation"
    NETWORK = "network"
    SECURITY = "security"
    PERFORMANCE = "performance"
    RESOURCE = "resource"
    VALIDATION = "validation"
    UNKNOWN = "unknown"


@dataclass
class ErrorContext:
    """Context information for error handling."""
    operation: str
    component: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    request_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    timestamp: float = field(default_factory=time.time)


@dataclass
class ErrorInfo:
    """Detailed error information."""
    error_type: Type[Exception]
    error_message: str
    severity: ErrorSeverity
    category: ErrorCategory
    context: ErrorContext
    stack_trace: str
    recovery_attempted: bool = False
    recovery_successful: bool = False
    performance_impact: float = 0.0


class ErrorRecoveryStrategy(ABC):
    """
    Abstract base class for error recovery strategies.
    
    Quantum-detailed: Defines the interface for error recovery strategies
    with standardized recovery mechanisms and performance monitoring.
    """
    
    def __init__(self, name: str, description: str):
        """
        Initialize error recovery strategy.
        
        Args:
            name: Strategy name
            description: Strategy description
        """
        self.name = name
        self.description = description
        self.logger = structlog.get_logger(f"{__name__}.{name}")
        self.success_count = 0
        self.failure_count = 0
        self.total_recovery_time = 0.0
    
    @abstractmethod
    async def can_recover(self, error: Exception, context: ErrorContext) -> bool:
        """
        Check if the error can be recovered using this strategy.
        
        Args:
            error: The exception that occurred
            context: Error context information
            
        Returns:
            True if recovery is possible, False otherwise
        """
        pass
    
    @abstractmethod
    async def recover(
        self, 
        error: Exception, 
        context: ErrorContext,
        **kwargs: Any
    ) -> Any:
        """
        Attempt to recover from the error.
        
        Args:
            error: The exception that occurred
            context: Error context information
            **kwargs: Additional recovery parameters
            
        Returns:
            Recovery result
            
        Raises:
            Exception: If recovery fails
        """
        pass
    
    def get_success_rate(self) -> float:
        """
        Get recovery success rate.
        
        Returns:
            Success rate as a percentage
        """
        total = self.success_count + self.failure_count
        return (self.success_count / total * 100) if total > 0 else 0.0
    
    def get_average_recovery_time(self) -> float:
        """
        Get average recovery time.
        
        Returns:
            Average recovery time in seconds
        """
        total_attempts = self.success_count + self.failure_count
        return (self.total_recovery_time / total_attempts) if total_attempts > 0 else 0.0


class RetryStrategy(ErrorRecoveryStrategy):
    """
    Retry-based error recovery strategy.
    
    Quantum-detailed: Implements retry logic with exponential backoff,
    maximum retry limits, and intelligent retry conditions.
    """
    
    def __init__(
        self, 
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        backoff_factor: float = 2.0
    ):
        """
        Initialize retry strategy.
        
        Args:
            max_retries: Maximum number of retry attempts
            base_delay: Base delay between retries in seconds
            max_delay: Maximum delay between retries in seconds
            backoff_factor: Exponential backoff factor
        """
        super().__init__(
            name="retry_strategy",
            description="Retry-based error recovery with exponential backoff"
        )
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.backoff_factor = backoff_factor
    
    async def can_recover(self, error: Exception, context: ErrorContext) -> bool:
        """Check if error is retryable."""
        # Don't retry on configuration or validation errors
        if isinstance(error, (ConfigurationError, TrafficFlouError)):
            return False
        
        # Don't retry on security errors
        if context.category == ErrorCategory.SECURITY:
            return False
        
        return True
    
    async def recover(
        self, 
        error: Exception, 
        context: ErrorContext,
        operation: Optional[Callable] = None,
        **kwargs: Any
    ) -> Any:
        """
        Attempt recovery through retries.
        
        Args:
            error: The exception that occurred
            context: Error context information
            operation: Operation to retry
            **kwargs: Additional parameters
            
        Returns:
            Operation result if successful
            
        Raises:
            Exception: If all retries fail
        """
        if not operation:
            raise ValueError("Operation function is required for retry strategy")
        
        start_time = time.time()
        last_error = error
        
        for attempt in range(self.max_retries + 1):
            try:
                if asyncio.iscoroutinefunction(operation):
                    result = await operation(**kwargs)
                else:
                    result = operation(**kwargs)
                
                # Success
                recovery_time = time.time() - start_time
                self.success_count += 1
                self.total_recovery_time += recovery_time
                
                self.logger.info(
                    "Recovery successful",
                    strategy=self.name,
                    attempt=attempt + 1,
                    recovery_time=recovery_time
                )
                
                return result
                
            except Exception as e:
                last_error = e
                
                if attempt < self.max_retries:
                    # Calculate delay with exponential backoff
                    delay = min(
                        self.base_delay * (self.backoff_factor ** attempt),
                        self.max_delay
                    )
                    
                    self.logger.warning(
                        "Retry attempt failed, retrying",
                        strategy=self.name,
                        attempt=attempt + 1,
                        max_retries=self.max_retries,
                        delay=delay,
                        error=str(e)
                    )
                    
                    await asyncio.sleep(delay)
                else:
                    # Final attempt failed
                    recovery_time = time.time() - start_time
                    self.failure_count += 1
                    self.total_recovery_time += recovery_time
                    
                    self.logger.error(
                        "All retry attempts failed",
                        strategy=self.name,
                        total_attempts=self.max_retries + 1,
                        recovery_time=recovery_time,
                        final_error=str(last_error)
                    )
        
        raise last_error


class ErrorHandler:
    """
    Main error handler for the TrafficFlou system.
    
    Quantum-detailed: Centralized error handling with multiple recovery
    strategies, error classification, and comprehensive monitoring.
    """
    
    def __init__(self):
        """Initialize error handler."""
        self.logger = structlog.get_logger(__name__)
        self.recovery_strategies: List[ErrorRecoveryStrategy] = []
        self.error_history: List[ErrorInfo] = []
        self.max_history_size = 1000
        
        # Register default recovery strategies
        self._register_default_strategies()
    
    def _register_default_strategies(self) -> None:
        """Register default error recovery strategies."""
        retry_strategy = RetryStrategy()
        self.register_recovery_strategy(retry_strategy)
    
    def register_recovery_strategy(self, strategy: ErrorRecoveryStrategy) -> None:
        """
        Register an error recovery strategy.
        
        Args:
            strategy: Error recovery strategy
        """
        self.recovery_strategies.append(strategy)
        self.logger.info(
            "Registered error recovery strategy",
            strategy_name=strategy.name,
            strategy_description=strategy.description
        )
    
    def classify_error(
        self, 
        error: Exception, 
        context: ErrorContext
    ) -> ErrorCategory:
        """
        Classify error based on type and context.
        
        Args:
            error: The exception
            context: Error context
            
        Returns:
            Error category
        """
        if isinstance(error, ConfigurationError):
            return ErrorCategory.CONFIGURATION
        elif isinstance(error, AIModelError):
            return ErrorCategory.AI_MODEL
        elif isinstance(error, TrafficGenerationError):
            return ErrorCategory.TRAFFIC_GENERATION
        elif isinstance(error, (ConnectionError, TimeoutError)):
            return ErrorCategory.NETWORK
        elif "security" in str(error).lower() or "auth" in str(error).lower():
            return ErrorCategory.SECURITY
        elif "performance" in str(error).lower() or "timeout" in str(error).lower():
            return ErrorCategory.PERFORMANCE
        elif "resource" in str(error).lower() or "memory" in str(error).lower():
            return ErrorCategory.RESOURCE
        elif "validation" in str(error).lower() or "invalid" in str(error).lower():
            return ErrorCategory.VALIDATION
        else:
            return ErrorCategory.UNKNOWN
    
    def determine_severity(
        self, 
        error: Exception, 
        category: ErrorCategory,
        context: ErrorContext
    ) -> ErrorSeverity:
        """
        Determine error severity.
        
        Args:
            error: The exception
            category: Error category
            context: Error context
            
        Returns:
            Error severity
        """
        if category == ErrorCategory.SECURITY:
            return ErrorSeverity.CRITICAL
        elif category == ErrorCategory.CONFIGURATION:
            return ErrorSeverity.HIGH
        elif category in [ErrorCategory.AI_MODEL, ErrorCategory.TRAFFIC_GENERATION]:
            return ErrorSeverity.MEDIUM
        elif category == ErrorCategory.NETWORK:
            return ErrorSeverity.LOW
        else:
            return ErrorSeverity.MEDIUM
    
    async def handle_error(
        self,
        error: Exception,
        context: ErrorContext,
        **kwargs: Any
    ) -> Optional[Any]:
        """
        Handle an error with recovery strategies.
        
        Args:
            error: The exception that occurred
            context: Error context information
            **kwargs: Additional parameters for recovery
            
        Returns:
            Recovery result if successful, None otherwise
        """
        # Classify and determine severity
        category = self.classify_error(error, context)
        severity = self.determine_severity(error, category, context)
        
        # Create error info
        error_info = ErrorInfo(
            error_type=type(error),
            error_message=str(error),
            severity=severity,
            category=category,
            context=context,
            stack_trace=traceback.format_exc()
        )
        
        # Log error
        self.logger.error(
            "Error occurred",
            error_type=error_info.error_type.__name__,
            error_message=error_info.error_message,
            severity=severity.value,
            category=category.value,
            operation=context.operation,
            component=context.component
        )
        
        # Store in history
        self.error_history.append(error_info)
        if len(self.error_history) > self.max_history_size:
            self.error_history.pop(0)
        
        # Try recovery strategies
        for strategy in self.recovery_strategies:
            try:
                if await strategy.can_recover(error, context):
                    error_info.recovery_attempted = True
                    
                    self.logger.info(
                        "Attempting error recovery",
                        strategy_name=strategy.name,
                        error_type=error_info.error_type.__name__
                    )
                    
                    result = await strategy.recover(error, context, **kwargs)
                    error_info.recovery_successful = True
                    
                    self.logger.info(
                        "Error recovery successful",
                        strategy_name=strategy.name,
                        error_type=error_info.error_type.__name__
                    )
                    
                    return result
                    
            except Exception as recovery_error:
                self.logger.error(
                    "Error recovery failed",
                    strategy_name=strategy.name,
                    error_type=error_info.error_type.__name__,
                    recovery_error=str(recovery_error)
                )
        
        # No recovery successful
        self.logger.error(
            "No error recovery strategy succeeded",
            error_type=error_info.error_type.__name__,
            error_message=error_info.error_message
        )
        
        return None
    
    def get_error_statistics(self) -> Dict[str, Any]:
        """
        Get error handling statistics.
        
        Returns:
            Error statistics
        """
        total_errors = len(self.error_history)
        if total_errors == 0:
            return {"total_errors": 0}
        
        # Count by category and severity
        category_counts = {}
        severity_counts = {}
        recovery_stats = {"attempted": 0, "successful": 0}
        
        for error_info in self.error_history:
            category = error_info.category.value
            severity = error_info.severity.value
            
            category_counts[category] = category_counts.get(category, 0) + 1
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
            
            if error_info.recovery_attempted:
                recovery_stats["attempted"] += 1
            if error_info.recovery_successful:
                recovery_stats["successful"] += 1
        
        # Strategy statistics
        strategy_stats = {}
        for strategy in self.recovery_strategies:
            strategy_stats[strategy.name] = {
                "success_rate": strategy.get_success_rate(),
                "average_recovery_time": strategy.get_average_recovery_time(),
                "total_attempts": strategy.success_count + strategy.failure_count
            }
        
        return {
            "total_errors": total_errors,
            "category_distribution": category_counts,
            "severity_distribution": severity_counts,
            "recovery_statistics": recovery_stats,
            "strategy_statistics": strategy_stats
        }


# Global error handler instance
_error_handler: Optional[ErrorHandler] = None


def get_error_handler() -> ErrorHandler:
    """
    Get the global error handler instance.
    
    Returns:
        Global error handler instance
    """
    global _error_handler
    if _error_handler is None:
        _error_handler = ErrorHandler()
    return _error_handler


# Decorators for error handling
T = TypeVar('T')


def handle_errors(
    operation: str,
    component: str,
    **context_kwargs: Any
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """
    Decorator for automatic error handling.
    
    Args:
        operation: Operation name
        component: Component name
        **context_kwargs: Additional context parameters
        
    Returns:
        Decorated function
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> T:
            context = ErrorContext(
                operation=operation,
                component=component,
                **context_kwargs
            )
            
            try:
                return await func(*args, **kwargs)
            except Exception as e:
                handler = get_error_handler()
                result = await handler.handle_error(e, context, func=func, *args, **kwargs)
                if result is not None:
                    return result
                raise
        
        @functools.wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> T:
            context = ErrorContext(
                operation=operation,
                component=component,
                **context_kwargs
            )
            
            try:
                return func(*args, **kwargs)
            except Exception as e:
                # For sync functions, we can't use async error handling
                # Just log and re-raise
                handler = get_error_handler()
                handler.logger.error(
                    "Sync function error (no recovery possible)",
                    error_type=type(e).__name__,
                    error_message=str(e),
                    operation=operation,
                    component=component
                )
                raise
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator


@asynccontextmanager
async def error_context(
    operation: str,
    component: str,
    **context_kwargs: Any
):
    """
    Context manager for error handling.
    
    Args:
        operation: Operation name
        component: Component name
        **context_kwargs: Additional context parameters
    """
    context = ErrorContext(
        operation=operation,
        component=component,
        **context_kwargs
    )
    
    try:
        yield context
    except Exception as e:
        handler = get_error_handler()
        await handler.handle_error(e, context)
        raise 