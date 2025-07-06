"""
🚨 TrafficFlou Custom Exceptions

This module defines all custom exceptions used throughout the TrafficFlou system
for proper error handling and debugging.

Author: TrafficFlou Team
Version: 1.0.0
"""

from typing import Optional, Dict, Any


class TrafficFlouError(Exception):
    """
    🚨 Base exception class for all TrafficFlou errors.
    
    This is the parent class for all custom exceptions in the TrafficFlou system.
    Provides consistent error handling and debugging information.
    """
    
    def __init__(
        self, 
        message: str, 
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        original_error: Optional[Exception] = None
    ):
        """
        Initialize TrafficFlouError.
        
        Args:
            message (str): Human-readable error message
            error_code (str): Optional error code for programmatic handling
            details (Dict[str, Any]): Additional error details
            original_error (Exception): Original exception that caused this error
        """
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.details = details or {}
        self.original_error = original_error
    
    def __str__(self) -> str:
        """Return string representation of the error."""
        if self.error_code:
            return f"[{self.error_code}] {self.message}"
        return self.message
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert error to dictionary for serialization."""
        return {
            "error_type": self.__class__.__name__,
            "message": self.message,
            "error_code": self.error_code,
            "details": self.details,
            "original_error": str(self.original_error) if self.original_error else None
        }


class ConfigurationError(TrafficFlouError):
    """
    ⚙️ Configuration-related errors.
    
    Raised when there are issues with system configuration, including:
    - Invalid configuration files
    - Missing required settings
    - Configuration validation failures
    """
    
    def __init__(
        self, 
        message: str, 
        config_key: Optional[str] = None,
        config_value: Optional[Any] = None,
        **kwargs
    ):
        super().__init__(message, error_code="CONFIG_ERROR", **kwargs)
        self.config_key = config_key
        self.config_value = config_value


class AIModelError(TrafficFlouError):
    """
    🤖 AI model-related errors.
    
    Raised when there are issues with AI model operations, including:
    - API authentication failures
    - Model unavailability
    - Response parsing errors
    - Rate limiting issues
    """
    
    def __init__(
        self, 
        message: str, 
        model_name: Optional[str] = None,
        api_provider: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="AI_MODEL_ERROR", **kwargs)
        self.model_name = model_name
        self.api_provider = api_provider


class TrafficGenerationError(TrafficFlouError):
    """
    🌐 Traffic generation errors.
    
    Raised when there are issues with traffic generation, including:
    - Network connectivity problems
    - Target website unavailability
    - Request failures
    - Rate limiting
    """
    
    def __init__(
        self, 
        message: str, 
        target_url: Optional[str] = None,
        request_id: Optional[str] = None,
        status_code: Optional[int] = None,
        **kwargs
    ):
        super().__init__(message, error_code="TRAFFIC_GENERATION_ERROR", **kwargs)
        self.target_url = target_url
        self.request_id = request_id
        self.status_code = status_code


class ProxyError(TrafficFlouError):
    """
    🔄 Proxy-related errors.
    
    Raised when there are issues with proxy management, including:
    - Proxy authentication failures
    - Proxy unavailability
    - Connection timeouts
    - Proxy rotation failures
    """
    
    def __init__(
        self, 
        message: str, 
        proxy_url: Optional[str] = None,
        proxy_type: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="PROXY_ERROR", **kwargs)
        self.proxy_url = proxy_url
        self.proxy_type = proxy_type


class SecurityError(TrafficFlouError):
    """
    🔒 Security-related errors.
    
    Raised when there are security issues, including:
    - Authentication failures
    - Authorization violations
    - Privacy protection failures
    - Security policy violations
    """
    
    def __init__(
        self, 
        message: str, 
        security_level: Optional[str] = None,
        violation_type: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="SECURITY_ERROR", **kwargs)
        self.security_level = security_level
        self.violation_type = violation_type


class AnalyticsError(TrafficFlouError):
    """
    📊 Analytics-related errors.
    
    Raised when there are issues with analytics and monitoring, including:
    - Metrics collection failures
    - Storage backend errors
    - Dashboard rendering issues
    - Data processing errors
    """
    
    def __init__(
        self, 
        message: str, 
        metric_name: Optional[str] = None,
        storage_backend: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="ANALYTICS_ERROR", **kwargs)
        self.metric_name = metric_name
        self.storage_backend = storage_backend


class BehaviorSimulationError(TrafficFlouError):
    """
    🎭 Behavior simulation errors.
    
    Raised when there are issues with behavior simulation, including:
    - Pattern generation failures
    - Behavior profile errors
    - Simulation engine failures
    """
    
    def __init__(
        self, 
        message: str, 
        behavior_profile: Optional[str] = None,
        pattern_type: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="BEHAVIOR_SIMULATION_ERROR", **kwargs)
        self.behavior_profile = behavior_profile
        self.pattern_type = pattern_type


class SessionError(TrafficFlouError):
    """
    📋 Session management errors.
    
    Raised when there are issues with session management, including:
    - Session creation failures
    - Session state corruption
    - Session cleanup errors
    """
    
    def __init__(
        self, 
        message: str, 
        session_id: Optional[str] = None,
        session_state: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="SESSION_ERROR", **kwargs)
        self.session_id = session_id
        self.session_state = session_state


class ValidationError(TrafficFlouError):
    """
    ✅ Validation errors.
    
    Raised when input validation fails, including:
    - Invalid URLs
    - Invalid parameters
    - Data type mismatches
    - Constraint violations
    """
    
    def __init__(
        self, 
        message: str, 
        field_name: Optional[str] = None,
        field_value: Optional[Any] = None,
        validation_rule: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="VALIDATION_ERROR", **kwargs)
        self.field_name = field_name
        self.field_value = field_value
        self.validation_rule = validation_rule


class RateLimitError(TrafficFlouError):
    """
    ⏱️ Rate limiting errors.
    
    Raised when rate limits are exceeded, including:
    - API rate limits
    - Request frequency limits
    - Concurrent connection limits
    """
    
    def __init__(
        self, 
        message: str, 
        limit_type: Optional[str] = None,
        limit_value: Optional[int] = None,
        retry_after: Optional[int] = None,
        **kwargs
    ):
        super().__init__(message, error_code="RATE_LIMIT_ERROR", **kwargs)
        self.limit_type = limit_type
        self.limit_value = limit_value
        self.retry_after = retry_after


class NetworkError(TrafficFlouError):
    """
    🌐 Network-related errors.
    
    Raised when there are network connectivity issues, including:
    - Connection timeouts
    - DNS resolution failures
    - SSL/TLS errors
    - Network unreachability
    """
    
    def __init__(
        self, 
        message: str, 
        host: Optional[str] = None,
        port: Optional[int] = None,
        protocol: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="NETWORK_ERROR", **kwargs)
        self.host = host
        self.port = port
        self.protocol = protocol


class ResourceError(TrafficFlouError):
    """
    💾 Resource management errors.
    
    Raised when there are resource-related issues, including:
    - Memory exhaustion
    - File system errors
    - Database connection failures
    - Resource cleanup failures
    """
    
    def __init__(
        self, 
        message: str, 
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        **kwargs
    ):
        super().__init__(message, error_code="RESOURCE_ERROR", **kwargs)
        self.resource_type = resource_type
        self.resource_id = resource_id


# Error code mapping for easy lookup
ERROR_CODES = {
    "CONFIG_ERROR": ConfigurationError,
    "AI_MODEL_ERROR": AIModelError,
    "TRAFFIC_GENERATION_ERROR": TrafficGenerationError,
    "PROXY_ERROR": ProxyError,
    "SECURITY_ERROR": SecurityError,
    "ANALYTICS_ERROR": AnalyticsError,
    "BEHAVIOR_SIMULATION_ERROR": BehaviorSimulationError,
    "SESSION_ERROR": SessionError,
    "VALIDATION_ERROR": ValidationError,
    "RATE_LIMIT_ERROR": RateLimitError,
    "NETWORK_ERROR": NetworkError,
    "RESOURCE_ERROR": ResourceError,
}


def create_error(error_code: str, message: str, **kwargs) -> TrafficFlouError:
    """
    Factory function to create errors by error code.
    
    Args:
        error_code (str): Error code from ERROR_CODES
        message (str): Error message
        **kwargs: Additional error parameters
        
    Returns:
        TrafficFlouError: Appropriate error instance
        
    Raises:
        ValueError: If error_code is not recognized
    """
    if error_code not in ERROR_CODES:
        raise ValueError(f"Unknown error code: {error_code}")
    
    error_class = ERROR_CODES[error_code]
    return error_class(message, **kwargs) 