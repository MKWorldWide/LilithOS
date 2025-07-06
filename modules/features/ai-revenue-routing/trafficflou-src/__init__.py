"""
🚦 TrafficFlou - AI-Powered Organic Traffic Mimicry System

A sophisticated traffic redirection system designed to generate and redirect 
AI-powered traffic that mimics organic user behavior patterns to any target website.

Author: TrafficFlou Team
Version: 1.0.0
License: MIT
"""

__version__ = "1.0.0"
__author__ = "TrafficFlou Team"
__email__ = "support@trafficflou.com"
__description__ = "AI-Powered Organic Traffic Mimicry System"

# Core imports for easy access
from .core.traffic_flou import TrafficFlou
from .core.config import TrafficFlouConfig
from .core.exceptions import TrafficFlouError, ConfigurationError, AIModelError

# Analytics and monitoring
from .analytics.metrics import MetricsCollector
from .analytics.dashboard import AnalyticsDashboard

# AI Models
from .ai_models.base import BaseAIModel
from .ai_models.openai_model import OpenAIModel
from .ai_models.anthropic_model import AnthropicModel

# Traffic Generation
from .traffic.generator import TrafficGenerator
from .traffic.behavior import BehaviorSimulator
from .traffic.proxy_manager import ProxyManager

# Utilities
from .utils.logging import setup_logging
from .utils.security import SecurityManager

__all__ = [
    # Core
    "TrafficFlou",
    "TrafficFlouConfig",
    "TrafficFlouError",
    "ConfigurationError", 
    "AIModelError",
    
    # Analytics
    "MetricsCollector",
    "AnalyticsDashboard",
    
    # AI Models
    "BaseAIModel",
    "OpenAIModel", 
    "AnthropicModel",
    
    # Traffic
    "TrafficGenerator",
    "BehaviorSimulator",
    "ProxyManager",
    
    # Utils
    "setup_logging",
    "SecurityManager",
] 