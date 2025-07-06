"""
🤖 Anthropic Claude Model Integration

This module provides integration with Anthropic's Claude models for intelligent
behavior generation in the TrafficFlou system.

Author: TrafficFlou Team
Version: 1.0.0
"""

import json
import asyncio
from typing import Dict, List, Any, Optional
import time

import anthropic
import structlog

from .base import BaseAIModel, AIModelConfig, ModelType, BehaviorPattern, BehaviorType
from ..core.exceptions import AIModelError


class AnthropicConfig(AIModelConfig):
    """Configuration specific to Anthropic models."""
    
    api_version: str = "2023-06-01"
    max_input_tokens: int = 100000
    system_prompt: str = "You are an AI assistant that generates realistic user behavior patterns for web traffic simulation."
    response_format: str = "json"


class AnthropicModel(BaseAIModel):
    """
    🤖 Anthropic Claude Model Integration
    
    Provides integration with Anthropic's Claude models for intelligent behavior generation.
    Supports Claude-3 Sonnet, Claude-3 Haiku, and other Anthropic models with advanced
    behavior pattern generation capabilities.
    
    Attributes:
        client (anthropic.AsyncAnthropic): Async Anthropic client
        model_name (str): Name of the Anthropic model
        config (AnthropicConfig): Anthropic-specific configuration
    """
    
    def __init__(self, model_name: str, api_key: str, config: Optional[AnthropicConfig] = None):
        """
        Initialize Anthropic model integration.
        
        Args:
            model_name (str): Name of the Anthropic model
            api_key (str): Anthropic API key
            config (AnthropicConfig): Anthropic-specific configuration
        """
        if config is None:
            config = AnthropicConfig()
        
        config.model_name = model_name
        config.api_key = api_key
        
        super().__init__(model_name, config)
        
        # Initialize Anthropic client
        self.client = anthropic.AsyncAnthropic(
            api_key=api_key,
            api_version=config.api_version
        )
        
        self.logger.info("Anthropic model initialized", 
                        model_name=model_name,
                        api_version=config.api_version)
    
    @property
    def model_type(self) -> ModelType:
        """Return the type of this AI model."""
        return ModelType.ANTHROPIC
    
    async def _make_request(self, prompt: str, **kwargs) -> Dict[str, Any]:
        """
        Make a request to the Anthropic API.
        
        Args:
            prompt (str): Input prompt for the model
            **kwargs: Additional request parameters
            
        Returns:
            Dict[str, Any]: Raw response from Anthropic API
            
        Raises:
            AIModelError: If the request fails
        """
        max_retries = self.config.max_retries
        
        for attempt in range(max_retries + 1):
            try:
                # Prepare request parameters
                request_params = {
                    "model": self.model_name,
                    "max_tokens": self.config.max_tokens,
                    "temperature": self.config.temperature,
                    "system": self.config.system_prompt,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    "timeout": self.config.timeout * 1000,  # Convert to milliseconds
                }
                
                # Add any additional parameters
                request_params.update(kwargs)
                
                # Make the request
                response = await self.client.messages.create(**request_params)
                
                # Extract the response content
                if response.content and len(response.content) > 0:
                    content = response.content[0].text
                    
                    # Parse JSON response
                    try:
                        parsed_response = json.loads(content)
                        return {
                            "choices": [{"message": {"content": parsed_response}}],
                            "usage": {
                                "input_tokens": response.usage.input_tokens,
                                "output_tokens": response.usage.output_tokens,
                                "total_tokens": response.usage.input_tokens + response.usage.output_tokens
                            },
                            "model": response.model,
                            "id": response.id
                        }
                    except json.JSONDecodeError as e:
                        raise AIModelError(
                            f"Failed to parse JSON response: {e}",
                            model_name=self.model_name,
                            api_provider="anthropic"
                        )
                else:
                    raise AIModelError(
                        "Empty response from Anthropic API",
                        model_name=self.model_name,
                        api_provider="anthropic"
                    )
                    
            except anthropic.RateLimitError as e:
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
                        api_provider="anthropic"
                    )
                    
            except anthropic.APIError as e:
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
                        api_provider="anthropic"
                    )
                    
            except Exception as e:
                raise AIModelError(
                    f"Unexpected error: {e}",
                    model_name=self.model_name,
                    api_provider="anthropic"
                )
        
        # This should never be reached, but just in case
        raise AIModelError(
            f"Request failed after {max_retries} retries",
            model_name=self.model_name,
            api_provider="anthropic"
        )
    
    def _parse_response(self, response: Dict[str, Any]) -> List[BehaviorPattern]:
        """
        Parse the Anthropic API response into behavior patterns.
        
        Args:
            response (Dict[str, Any]): Raw response from Anthropic API
            
        Returns:
            List[BehaviorPattern]: Parsed behavior patterns
        """
        try:
            # Extract the content from the response
            if 'choices' in response and len(response['choices']) > 0:
                content = response['choices'][0]['message']['content']
            else:
                raise AIModelError(
                    "Invalid response format from Anthropic API",
                    model_name=self.model_name,
                    api_provider="anthropic"
                )
            
            # Parse the JSON content
            if isinstance(content, str):
                try:
                    content = json.loads(content)
                except json.JSONDecodeError as e:
                    raise AIModelError(
                        f"Failed to parse JSON content: {e}",
                        model_name=self.model_name,
                        api_provider="anthropic"
                    )
            
            # Extract behaviors from the response
            behaviors_data = content.get('behaviors', [])
            if not isinstance(behaviors_data, list):
                raise AIModelError(
                    "Invalid behaviors format in response",
                    model_name=self.model_name,
                    api_provider="anthropic"
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
                f"Failed to parse Anthropic response: {e}",
                model_name=self.model_name,
                api_provider="anthropic"
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
        """Get the prompt template for Anthropic models."""
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
Focus on natural, organic interactions that reflect real user behavior patterns.
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
- Organic page transitions
""",
            
            BehaviorType.CLICKING: """
Generate realistic clicking behavior patterns for {target_url}.
Focus on:
- Button and link clicks
- Menu navigation
- Interactive element interactions
- Natural click patterns and timing
- Hover and click sequences
""",
            
            BehaviorType.SCROLLING: """
Generate realistic scrolling behavior patterns for {target_url}.
Focus on:
- Natural scroll patterns
- Reading behavior (slow scrolling when reading)
- Quick navigation (fast scrolling when searching)
- Scroll depth and direction changes
- Pause patterns during reading
""",
            
            BehaviorType.FORM_FILLING: """
Generate realistic form filling behavior patterns for {target_url}.
Focus on:
- Input field interactions
- Form validation and corrections
- Natural typing patterns
- Form submission behavior
- Field navigation and tabbing
""",
            
            BehaviorType.ECOMMERCE: """
Generate realistic ecommerce behavior patterns for {target_url}.
Focus on:
- Product browsing and comparison
- Shopping cart interactions
- Checkout process
- Product reviews and ratings
- Wishlist and favorites
- Price comparison behavior
"""
        }
        
        template = behavior_templates.get(behavior_type, behavior_templates[BehaviorType.BROWSING])
        
        return template.format(target_url=target_url) + self._get_prompt_template()
    
    async def close(self):
        """Clean up Anthropic client resources."""
        await super().close()
        if hasattr(self, 'client'):
            await self.client.close() 