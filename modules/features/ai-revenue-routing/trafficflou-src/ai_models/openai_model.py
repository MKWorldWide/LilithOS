"""
🤖 OpenAI Model Integration

This module provides integration with OpenAI's GPT models for intelligent
behavior generation in the TrafficFlou system.

Author: TrafficFlou Team
Version: 1.0.0
"""

import json
import asyncio
from typing import Dict, List, Any, Optional
import time

import openai
import structlog
from pydantic import Field

from .base import BaseAIModel, AIModelConfig, ModelType, BehaviorPattern, BehaviorType
from ..core.exceptions import AIModelError


class OpenAIConfig(AIModelConfig):
    """Configuration specific to OpenAI models."""
    
    organization: Optional[str] = Field(default=None, description="OpenAI organization ID")
    api_base: Optional[str] = Field(default=None, description="Custom API base URL")
    deployment_id: Optional[str] = Field(default=None, description="Azure deployment ID")
    api_version: Optional[str] = Field(default=None, description="Azure API version")
    
    # Model-specific settings
    system_prompt: str = Field(
        default="You are an AI assistant that generates realistic user behavior patterns for web traffic simulation.",
        description="System prompt for the model"
    )
    response_format: str = Field(default="json_object", description="Response format")
    max_retries: int = Field(default=3, description="Maximum retry attempts for failed requests")


class OpenAIModel(BaseAIModel):
    """
    🤖 OpenAI Model Integration
    
    Provides integration with OpenAI's GPT models for intelligent behavior generation.
    Supports GPT-4, GPT-3.5-turbo, and other OpenAI models with advanced
    behavior pattern generation capabilities.
    
    Attributes:
        client: OpenAI client
        model_name (str): Name of the OpenAI model
        config (OpenAIConfig): OpenAI-specific configuration
    """
    
    def __init__(self, model_name: str, api_key: str, config: Optional[OpenAIConfig] = None):
        """
        Initialize OpenAI model integration.
        
        Args:
            model_name (str): Name of the OpenAI model (e.g., "gpt-4", "gpt-3.5-turbo")
            api_key (str): OpenAI API key
            config (OpenAIConfig): OpenAI-specific configuration
        """
        if config is None:
            config = OpenAIConfig()
        
        config.model_name = model_name
        config.api_key = api_key
        
        super().__init__(model_name, config)
        
        # Initialize OpenAI client (compatible with openai==0.28.1)
        openai.api_key = api_key
        if config.organization:
            openai.organization = config.organization
        if config.api_base:
            openai.api_base = config.api_base
        
        self.logger.info("OpenAI model initialized", 
                        model_name=model_name,
                        api_base=config.api_base)
    
    @property
    def model_type(self) -> ModelType:
        """Return the type of this AI model."""
        return ModelType.OPENAI
    
    async def _make_request(self, prompt: str, **kwargs) -> Dict[str, Any]:
        """
        Make a request to the OpenAI API.
        
        Args:
            prompt (str): Input prompt for the model
            **kwargs: Additional request parameters
            
        Returns:
            Dict[str, Any]: Raw response from OpenAI API
            
        Raises:
            AIModelError: If the request fails
        """
        max_retries = self.config.max_retries
        
        for attempt in range(max_retries + 1):
            try:
                # Prepare messages
                messages = [
                    {"role": "system", "content": self.config.system_prompt},
                    {"role": "user", "content": prompt}
                ]
                
                # Prepare request parameters
                request_params = {
                    "model": self.model_name,
                    "messages": messages,
                    "max_tokens": self.config.max_tokens,
                    "temperature": self.config.temperature,
                    "timeout": self.config.timeout,
                }
                
                # Add any additional parameters
                request_params.update(kwargs)
                
                # Make the request using the compatible API
                response = await openai.ChatCompletion.acreate(**request_params)
                
                # Extract the response content
                if response.choices and len(response.choices) > 0:
                    content = response.choices[0].message.content
                    
                    # Parse JSON response
                    try:
                        parsed_response = json.loads(content)
                        return {
                            "choices": [{"message": {"content": parsed_response}}],
                            "usage": response.usage,
                            "model": response.model,
                            "id": response.id
                        }
                    except json.JSONDecodeError as e:
                        raise AIModelError(
                            f"Failed to parse JSON response: {e}",
                            model_name=self.model_name,
                            api_provider="openai"
                        )
                else:
                    raise AIModelError(
                        "Empty response from OpenAI API",
                        model_name=self.model_name,
                        api_provider="openai"
                    )
                    
            except openai.RateLimitError as e:
                if attempt < max_retries:
                    wait_time = (2 ** attempt) * self.config.retry_delay
                    self.logger.warning("Rate limit hit, retrying", 
                                      attempt=attempt + 1,
                                      wait_time=wait_time,
                                      model_name=self.model_name)
                    await asyncio.sleep(wait_time)
                    continue
                else:
                    raise AIModelError(
                        f"Rate limit exceeded after {max_retries} retries: {e}",
                        model_name=self.model_name,
                        api_provider="openai"
                    )
                    
            except openai.APIError as e:
                if attempt < max_retries:
                    wait_time = (2 ** attempt) * self.config.retry_delay
                    self.logger.warning("API error, retrying", 
                                      attempt=attempt + 1,
                                      wait_time=wait_time,
                                      error=str(e),
                                      model_name=self.model_name)
                    await asyncio.sleep(wait_time)
                    continue
                else:
                    raise AIModelError(
                        f"API error after {max_retries} retries: {e}",
                        model_name=self.model_name,
                        api_provider="openai"
                    )
                    
            except Exception as e:
                raise AIModelError(
                    f"Unexpected error: {e}",
                    model_name=self.model_name,
                    api_provider="openai"
                )
        
        # This should never be reached, but just in case
        raise AIModelError(
            f"Request failed after {max_retries} retries",
            model_name=self.model_name,
            api_provider="openai"
        )
    
    def _parse_response(self, response: Dict[str, Any]) -> List[BehaviorPattern]:
        """
        Parse the OpenAI API response into behavior patterns.
        
        Args:
            response (Dict[str, Any]): Raw response from OpenAI API
            
        Returns:
            List[BehaviorPattern]: Parsed behavior patterns
        """
        try:
            # Extract the content from the response
            if 'choices' in response and len(response['choices']) > 0:
                content = response['choices'][0]['message']['content']
            else:
                raise AIModelError(
                    "Invalid response format from OpenAI API",
                    model_name=self.model_name,
                    api_provider="openai"
                )
            
            # Parse the JSON content
            if isinstance(content, str):
                try:
                    content = json.loads(content)
                except json.JSONDecodeError as e:
                    raise AIModelError(
                        f"Failed to parse JSON content: {e}",
                        model_name=self.model_name,
                        api_provider="openai"
                    )
            
            # Extract behaviors from the response
            behaviors_data = content.get('behaviors', [])
            if not isinstance(behaviors_data, list):
                raise AIModelError(
                    "Invalid behaviors format in response",
                    model_name=self.model_name,
                    api_provider="openai"
                )
            
            behavior_patterns = []
            
            for behavior_data in behaviors_data:
                try:
                    # Extract behavior type
                    behavior_type_str = behavior_data.get('type', '').lower()
                    behavior_type = self._parse_behavior_type(behavior_type_str)
                    
                    # Create behavior pattern
                    pattern = BehaviorPattern(
                        behavior_type=behavior_type,
                        target_element=behavior_data.get('target_element'),
                        action=behavior_data.get('action', ''),
                        parameters=behavior_data.get('parameters', {}),
                        confidence=float(behavior_data.get('confidence', 1.0)),
                        reasoning=behavior_data.get('reasoning', ''),
                        timestamp=time.time()
                    )
                    
                    # Validate confidence threshold
                    if pattern.confidence >= self.config.confidence_threshold:
                        behavior_patterns.append(pattern)
                    else:
                        self.logger.debug("Skipping low-confidence behavior", 
                                        confidence=pattern.confidence,
                                        threshold=self.config.confidence_threshold)
                        
                except Exception as e:
                    self.logger.warning("Failed to parse behavior pattern", 
                                      error=str(e),
                                      behavior_data=behavior_data)
                    continue
            
            self.logger.info("Parsed behavior patterns", 
                           count=len(behavior_patterns),
                           model_name=self.model_name)
            
            return behavior_patterns
            
        except Exception as e:
            raise AIModelError(
                f"Failed to parse OpenAI response: {e}",
                model_name=self.model_name,
                api_provider="openai"
            )
    
    def _parse_behavior_type(self, behavior_type_str: str) -> BehaviorType:
        """
        Parse behavior type string into BehaviorType enum.
        
        Args:
            behavior_type_str (str): Behavior type string
            
        Returns:
            BehaviorType: Parsed behavior type
            
        Raises:
            AIModelError: If behavior type is not recognized
        """
        behavior_type_mapping = {
            'browsing': BehaviorType.BROWSING,
            'clicking': BehaviorType.CLICKING,
            'scrolling': BehaviorType.SCROLLING,
            'form_filling': BehaviorType.FORM_FILLING,
            'navigation': BehaviorType.NAVIGATION,
            'search': BehaviorType.SEARCH,
            'social': BehaviorType.SOCIAL,
            'ecommerce': BehaviorType.ECOMMERCE,
        }
        
        if behavior_type_str in behavior_type_mapping:
            return behavior_type_mapping[behavior_type_str]
        else:
            # Default to browsing if unknown
            self.logger.warning("Unknown behavior type, defaulting to browsing", 
                              behavior_type=behavior_type_str)
            return BehaviorType.BROWSING
    
    def _get_prompt_template(self) -> str:
        """Get the prompt template for OpenAI models."""
        return """
You are an AI assistant that generates realistic user behavior patterns for web traffic simulation.

Target URL: {target_url}
User Intent: {user_intent}
Session Duration: {session_duration} seconds
Available Page Elements: {page_elements}
Behavior Types to Generate: {behavior_types}

Please generate realistic behavior patterns that a human user would perform on this website.
Each behavior should include:
1. Behavior type (browsing, clicking, scrolling, form_filling, navigation, search, social, ecommerce)
2. Target element (if applicable)
3. Action description
4. Parameters (coordinates, duration, etc.)
5. Confidence level (0.0-1.0)
6. Reasoning for the behavior

Generate {max_patterns_per_request} behavior patterns that mimic organic user behavior.
Focus on realistic interactions that would occur naturally during a {session_duration}-second session.

Consider the user intent and generate behaviors that align with their goals.
For example:
- If user_intent is "shopping", focus on ecommerce behaviors
- If user_intent is "research", focus on browsing and search behaviors
- If user_intent is "social", focus on social media interactions

Response format (JSON):
{{
    "behaviors": [
        {{
            "type": "behavior_type",
            "target_element": "element_selector_or_description",
            "action": "detailed_action_description",
            "parameters": {{"param1": "value1"}},
            "confidence": 0.85,
            "reasoning": "explanation_of_why_this_behavior_is_realistic"
        }}
    ]
}}

Ensure all behaviors are realistic and would be performed by actual human users.
"""
    
    async def generate_specialized_behavior(
        self,
        behavior_type: BehaviorType,
        target_url: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[BehaviorPattern]:
        """
        Generate specialized behavior patterns for a specific behavior type.
        
        Args:
            behavior_type (BehaviorType): Type of behavior to generate
            target_url (str): Target website URL
            context (Dict[str, Any]): Additional context
            
        Returns:
            List[BehaviorPattern]: Specialized behavior patterns
        """
        specialized_prompt = self._get_specialized_prompt(behavior_type, target_url, context)
        
        try:
            response = await self._make_request(specialized_prompt)
            return self._parse_response(response)
        except Exception as e:
            self.logger.error("Specialized behavior generation failed", 
                            behavior_type=behavior_type.value,
                            error=str(e))
            return []
    
    def _get_specialized_prompt(
        self,
        behavior_type: BehaviorType,
        target_url: str,
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """Get specialized prompt for specific behavior types."""
        
        behavior_templates = {
            BehaviorType.BROWSING: """
Generate realistic browsing behavior patterns for {target_url}.
Focus on:
- Page navigation and exploration
- Reading content and staying on pages
- Natural browsing flow
- Time spent on different sections
""",
            
            BehaviorType.CLICKING: """
Generate realistic clicking behavior patterns for {target_url}.
Focus on:
- Button and link clicks
- Menu navigation
- Interactive element interactions
- Natural click patterns and timing
""",
            
            BehaviorType.SCROLLING: """
Generate realistic scrolling behavior patterns for {target_url}.
Focus on:
- Natural scroll patterns
- Reading behavior (slow scrolling when reading)
- Quick navigation (fast scrolling when searching)
- Scroll depth and direction changes
""",
            
            BehaviorType.FORM_FILLING: """
Generate realistic form filling behavior patterns for {target_url}.
Focus on:
- Input field interactions
- Form validation and corrections
- Natural typing patterns
- Form submission behavior
""",
            
            BehaviorType.ECOMMERCE: """
Generate realistic ecommerce behavior patterns for {target_url}.
Focus on:
- Product browsing and comparison
- Shopping cart interactions
- Checkout process
- Product reviews and ratings
- Wishlist and favorites
"""
        }
        
        template = behavior_templates.get(behavior_type, behavior_templates[BehaviorType.BROWSING])
        
        return template.format(target_url=target_url) + self._get_prompt_template()
    
    async def close(self):
        """Clean up OpenAI client resources."""
        await super().close() 