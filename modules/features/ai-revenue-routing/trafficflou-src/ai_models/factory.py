"""
🏭 AI Model Factory

This module implements the Abstract Factory pattern for creating AI model instances.
It provides a centralized way to instantiate different AI models with proper
configuration and error handling.

Author: TrafficFlou Team
Version: 1.0.0
"""

import os
from typing import Dict, Type, Optional, List
import structlog

from .base import BaseAIModel, AIModelConfig, ModelType
from ..core.exceptions import AIModelError, ConfigurationError

# Conditional imports for different AI providers
try:
    from .openai_model import OpenAI, OpenAIConfig
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    OpenAI = None
    OpenAIConfig = None

try:
    from .anthropic_model import Anthropic, AnthropicConfig
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
    Anthropic = None
    AnthropicConfig = None

try:
    from .athena_model import Athena, AthenaConfig
    ATHENA_AVAILABLE = True
except ImportError:
    ATHENA_AVAILABLE = False
    Athena = None
    AthenaConfig = None

try:
    from .primal_genesis_model import PrimalGenesis, PrimalGenesisConfig
    PRIMAL_GENESIS_AVAILABLE = True
except ImportError:
    PRIMAL_GENESIS_AVAILABLE = False
    PrimalGenesis = None
    PrimalGenesisConfig = None

logger = structlog.get_logger(__name__)


class AIModelFactory:
    """
    Abstract Factory for creating AI model instances.
    
    This factory prioritizes the Primal Genesis (Source) model and falls back
    to other available models based on configuration and availability.
    """
    
    # Model priority order (highest to lowest)
    MODEL_PRIORITY = [
        ModelType.PRIMAL_GENESIS,  # Source - Highest priority
        ModelType.ATHENA,          # Secondary
        ModelType.OPENAI,          # Tertiary
        ModelType.ANTHROPIC        # Quaternary
    ]
    
    # Registry of available models
    _models: Dict[ModelType, Type[BaseAIModel]] = {}
    _configs: Dict[ModelType, Type[AIModelConfig]] = {}
    
    @classmethod
    def register_model(cls, model_type: ModelType, model_class: Type[BaseAIModel], config_class: Type[AIModelConfig]):
        """Register a model class with its configuration."""
        cls._models[model_type] = model_class
        cls._configs[model_type] = config_class
        logger.info("Model registered", model_type=model_type.value, model_class=model_class.__name__)
    
    @classmethod
    def get_available_models(cls) -> List[ModelType]:
        """Get list of available models in priority order."""
        available = []
        for model_type in cls.MODEL_PRIORITY:
            if model_type in cls._models:
                available.append(model_type)
        return available
    
    @classmethod
    def get_best_available_model(cls) -> Optional[ModelType]:
        """Get the highest priority available model."""
        available = cls.get_available_models()
        return available[0] if available else None
    
    @classmethod
    def create_model(cls, model_type: Optional[ModelType] = None, **config_kwargs) -> BaseAIModel:
        """
        Create an AI model instance.
        
        Args:
            model_type: Specific model type to create. If None, uses best available.
            **config_kwargs: Configuration parameters for the model.
            
        Returns:
            Configured AI model instance.
            
        Raises:
            AIModelError: If model creation fails.
            ConfigurationError: If no models are available.
        """
        try:
            # If no specific model requested, use best available
            if model_type is None:
                model_type = cls.get_best_available_model()
                if model_type is None:
                    raise ConfigurationError("No AI models available")
                logger.info("Using best available model", model_type=model_type.value)
            
            # Validate model type is available
            if model_type not in cls._models:
                available = cls.get_available_models()
                raise AIModelError(
                    f"Model type {model_type.value} not available. "
                    f"Available models: {[m.value for m in available]}"
                )
            
            # Get model and config classes
            model_class = cls._models[model_type]
            config_class = cls._configs[model_type]
            
            # Create configuration
            config = config_class(**config_kwargs)
            
            # Create and return model instance
            model = model_class(config)
            logger.info("Model created successfully", model_type=model_type.value, model_class=model_class.__name__)
            return model
            
        except Exception as e:
            logger.error("Failed to create AI model", error=str(e), model_type=model_type.value if model_type else None)
            raise AIModelError(f"Failed to create AI model: {str(e)}") from e
    
    @classmethod
    def create_model_with_fallback(cls, preferred_type: ModelType, **config_kwargs) -> BaseAIModel:
        """
        Create a model with fallback to other available models.
        
        Args:
            preferred_type: Preferred model type.
            **config_kwargs: Configuration parameters.
            
        Returns:
            Configured AI model instance (preferred or fallback).
        """
        available = cls.get_available_models()
        
        # Try preferred model first
        if preferred_type in available:
            try:
                return cls.create_model(preferred_type, **config_kwargs)
            except Exception as e:
                logger.warning("Preferred model failed, trying fallback", 
                             preferred_type=preferred_type.value, error=str(e))
        
        # Try other available models in priority order
        for model_type in available:
            if model_type != preferred_type:
                try:
                    logger.info("Trying fallback model", model_type=model_type.value)
                    return cls.create_model(model_type, **config_kwargs)
                except Exception as e:
                    logger.warning("Fallback model failed", model_type=model_type.value, error=str(e))
                    continue
        
        # If all models fail, raise error
        raise AIModelError("All available AI models failed to initialize")


# Initialize factory with available models
def _initialize_factory():
    """Initialize the factory with available models."""
    
    # Register OpenAI model if available
    if OPENAI_AVAILABLE and OpenAI and OpenAIConfig:
        AIModelFactory.register_model(ModelType.OPENAI, OpenAI, OpenAIConfig)
        logger.info("OpenAI model registered")
    
    # Register Anthropic model if available
    if ANTHROPIC_AVAILABLE and Anthropic and AnthropicConfig:
        AIModelFactory.register_model(ModelType.ANTHROPIC, Anthropic, AnthropicConfig)
        logger.info("Anthropic model registered")
    
    # Register Athena model if available
    if ATHENA_AVAILABLE and Athena and AthenaConfig:
        AIModelFactory.register_model(ModelType.ATHENA, Athena, AthenaConfig)
        logger.info("Athena model registered")
    
    # Register Primal Genesis model if available (highest priority)
    if PRIMAL_GENESIS_AVAILABLE and PrimalGenesis and PrimalGenesisConfig:
        AIModelFactory.register_model(ModelType.PRIMAL_GENESIS, PrimalGenesis, PrimalGenesisConfig)
        logger.info("Primal Genesis model registered (Source)")
    
    # Log available models
    available = AIModelFactory.get_available_models()
    logger.info("AI Model Factory initialized", 
                available_models=[m.value for m in available],
                total_models=len(available))


# Initialize factory on module import
_initialize_factory() 