"""
🎭 Behavior Simulation Engine

This module provides sophisticated behavior simulation for the TrafficFlou system,
generating realistic user interaction patterns that mimic organic traffic.

Author: TrafficFlou Team
Version: 1.0.0
"""

import random
import time
import math
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum

import structlog

from ..core.config import TrafficFlouConfig
from .generator import BehaviorPattern, BehaviorType


class UserIntent(Enum):
    """Enumeration of user intents for behavior simulation."""
    BROWSING = "browsing"
    SHOPPING = "shopping"
    RESEARCH = "research"
    SOCIAL = "social"
    NEWS = "news"
    ENTERTAINMENT = "entertainment"
    WORK = "work"
    EDUCATION = "education"


class DeviceType(Enum):
    """Enumeration of device types for behavior simulation."""
    DESKTOP = "desktop"
    MOBILE = "mobile"
    TABLET = "tablet"


@dataclass
class UserProfile:
    """Represents a user profile for behavior simulation."""
    
    user_id: str
    intent: UserIntent
    device_type: DeviceType
    session_duration: int
    page_views_per_session: int
    bounce_rate: float
    reading_speed: float  # words per minute
    interaction_frequency: float  # interactions per minute
    patience_level: float  # 0.0 to 1.0
    technical_savvy: float  # 0.0 to 1.0
    
    # Behavioral preferences
    prefers_images: bool = True
    prefers_videos: bool = False
    social_media_active: bool = True
    ecommerce_ready: bool = False
    
    # Geographic and demographic data
    timezone: str = "UTC"
    language: str = "en-US"
    age_group: str = "25-34"
    income_level: str = "middle"


@dataclass
class PageElement:
    """Represents a page element for interaction simulation."""
    
    element_id: str
    element_type: str  # button, link, form, image, video, text
    selector: str  # CSS selector
    position: Tuple[int, int]  # x, y coordinates
    size: Tuple[int, int]  # width, height
    text_content: Optional[str] = None
    href: Optional[str] = None
    is_visible: bool = True
    is_interactive: bool = True
    importance_score: float = 0.5  # 0.0 to 1.0


class BehaviorSimulator:
    """
    🎭 Behavior Simulation Engine
    
    Generates realistic user behavior patterns for traffic simulation,
    including browsing patterns, interaction timing, and user intent simulation.
    
    Attributes:
        config (TrafficFlouConfig): System configuration
        logger (structlog.BoundLogger): Structured logging instance
        user_profiles (Dict[str, UserProfile]): Available user profiles
        behavior_templates (Dict[str, List[BehaviorPattern]]): Behavior templates
    """
    
    def __init__(self, config: TrafficFlouConfig):
        """
        Initialize the behavior simulator.
        
        Args:
            config (TrafficFlouConfig): System configuration
        """
        self.config = config
        self.logger = structlog.get_logger(__name__)
        
        # Initialize user profiles
        self.user_profiles: Dict[str, UserProfile] = {}
        self._initialize_user_profiles()
        
        # Initialize behavior templates
        self.behavior_templates: Dict[str, List[BehaviorPattern]] = {}
        self._initialize_behavior_templates()
        
        self.logger.info("Behavior simulator initialized")
    
    def _initialize_user_profiles(self):
        """Initialize default user profiles for different scenarios."""
        
        # Browsing profile
        self.user_profiles['casual_browser'] = UserProfile(
            user_id="casual_browser",
            intent=UserIntent.BROWSING,
            device_type=DeviceType.DESKTOP,
            session_duration=random.randint(300, 900),
            page_views_per_session=random.randint(3, 8),
            bounce_rate=0.4,
            reading_speed=200,
            interaction_frequency=2.0,
            patience_level=0.7,
            technical_savvy=0.6
        )
        
        # Shopping profile
        self.user_profiles['shopper'] = UserProfile(
            user_id="shopper",
            intent=UserIntent.SHOPPING,
            device_type=DeviceType.DESKTOP,
            session_duration=random.randint(600, 1800),
            page_views_per_session=random.randint(5, 15),
            bounce_rate=0.2,
            reading_speed=150,
            interaction_frequency=3.0,
            patience_level=0.8,
            technical_savvy=0.7,
            ecommerce_ready=True
        )
        
        # Research profile
        self.user_profiles['researcher'] = UserProfile(
            user_id="researcher",
            intent=UserIntent.RESEARCH,
            device_type=DeviceType.DESKTOP,
            session_duration=random.randint(900, 2400),
            page_views_per_session=random.randint(8, 20),
            bounce_rate=0.1,
            reading_speed=300,
            interaction_frequency=1.5,
            patience_level=0.9,
            technical_savvy=0.8
        )
        
        # Mobile user profile
        self.user_profiles['mobile_user'] = UserProfile(
            user_id="mobile_user",
            intent=UserIntent.BROWSING,
            device_type=DeviceType.MOBILE,
            session_duration=random.randint(180, 600),
            page_views_per_session=random.randint(2, 6),
            bounce_rate=0.5,
            reading_speed=150,
            interaction_frequency=1.5,
            patience_level=0.5,
            technical_savvy=0.4
        )
    
    def _initialize_behavior_templates(self):
        """Initialize behavior templates for different scenarios."""
        
        # Browsing behavior template
        self.behavior_templates['browsing'] = [
            BehaviorPattern(
                behavior_type=BehaviorType.BROWSING,
                action="Page load and initial scan",
                parameters={"duration": 2.0, "scroll_depth": 0.3},
                confidence=0.9
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.SCROLLING,
                action="Slow scroll to read content",
                parameters={"direction": "down", "speed": "slow", "distance": 0.5},
                confidence=0.8
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.CLICKING,
                action="Click on interesting link",
                parameters={"target_type": "link", "confidence": 0.7},
                confidence=0.7
            )
        ]
        
        # Shopping behavior template
        self.behavior_templates['shopping'] = [
            BehaviorPattern(
                behavior_type=BehaviorType.BROWSING,
                action="Product category exploration",
                parameters={"duration": 3.0, "scroll_depth": 0.7},
                confidence=0.9
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.CLICKING,
                action="Click on product",
                parameters={"target_type": "product", "confidence": 0.8},
                confidence=0.8
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.SCROLLING,
                action="Scroll through product details",
                parameters={"direction": "down", "speed": "medium", "distance": 0.8},
                confidence=0.8
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.FORM_FILLING,
                action="Add to cart interaction",
                parameters={"form_type": "add_to_cart", "confidence": 0.6},
                confidence=0.6
            )
        ]
        
        # Research behavior template
        self.behavior_templates['research'] = [
            BehaviorPattern(
                behavior_type=BehaviorType.SEARCH,
                action="Search for specific information",
                parameters={"query_type": "specific", "confidence": 0.9},
                confidence=0.9
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.BROWSING,
                action="Deep reading of content",
                parameters={"duration": 5.0, "scroll_depth": 0.9},
                confidence=0.8
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.SCROLLING,
                action="Slow scroll for reading",
                parameters={"direction": "down", "speed": "very_slow", "distance": 1.0},
                confidence=0.8
            ),
            BehaviorPattern(
                behavior_type=BehaviorType.CLICKING,
                action="Click on reference links",
                parameters={"target_type": "reference", "confidence": 0.7},
                confidence=0.7
            )
        ]
    
    async def generate_patterns(
        self,
        behavior_profile: str,
        user_profile: Optional[UserProfile] = None,
        page_elements: Optional[List[PageElement]] = None
    ) -> Dict[str, Any]:
        """
        Generate behavior patterns for a given profile.
        
        Args:
            behavior_profile (str): Behavior profile type
            user_profile (UserProfile): Optional specific user profile
            page_elements (List[PageElement]): Optional page elements for interaction
            
        Returns:
            Dict[str, Any]: Generated behavior patterns and metadata
        """
        # Select or create user profile
        if user_profile is None:
            user_profile = self._select_user_profile(behavior_profile)
        
        # Generate behavior patterns
        patterns = await self._generate_user_behaviors(user_profile, page_elements)
        
        # Add timing and interaction data
        behavior_data = {
            'user_profile': user_profile,
            'behavior_patterns': patterns,
            'session_duration': user_profile.session_duration,
            'page_views_per_session': user_profile.page_views_per_session,
            'bounce_rate': user_profile.bounce_rate,
            'interaction_timeline': self._generate_interaction_timeline(user_profile, patterns),
            'page_elements': page_elements or []
        }
        
        self.logger.info("Generated behavior patterns", 
                        profile=behavior_profile,
                        pattern_count=len(patterns),
                        session_duration=user_profile.session_duration)
        
        return behavior_data
    
    def _select_user_profile(self, behavior_profile: str) -> UserProfile:
        """Select an appropriate user profile based on behavior profile."""
        
        profile_mapping = {
            'organic': 'casual_browser',
            'browsing': 'casual_browser',
            'shopping': 'shopper',
            'research': 'researcher',
            'mobile': 'mobile_user',
            'ecommerce': 'shopper',
            'news': 'casual_browser',
            'social': 'casual_browser'
        }
        
        profile_key = profile_mapping.get(behavior_profile, 'casual_browser')
        base_profile = self.user_profiles[profile_key]
        
        # Add some randomization to make profiles more realistic
        return UserProfile(
            user_id=f"{profile_key}_{int(time.time())}",
            intent=base_profile.intent,
            device_type=base_profile.device_type,
            session_duration=int(base_profile.session_duration * random.uniform(0.8, 1.2)),
            page_views_per_session=int(base_profile.page_views_per_session * random.uniform(0.7, 1.3)),
            bounce_rate=base_profile.bounce_rate * random.uniform(0.8, 1.2),
            reading_speed=base_profile.reading_speed * random.uniform(0.9, 1.1),
            interaction_frequency=base_profile.interaction_frequency * random.uniform(0.8, 1.2),
            patience_level=base_profile.patience_level * random.uniform(0.9, 1.1),
            technical_savvy=base_profile.technical_savvy * random.uniform(0.9, 1.1),
            prefers_images=base_profile.prefers_images,
            prefers_videos=base_profile.prefers_videos,
            social_media_active=base_profile.social_media_active,
            ecommerce_ready=base_profile.ecommerce_ready,
            timezone=base_profile.timezone,
            language=base_profile.language,
            age_group=base_profile.age_group,
            income_level=base_profile.income_level
        )
    
    async def _generate_user_behaviors(
        self,
        user_profile: UserProfile,
        page_elements: Optional[List[PageElement]] = None
    ) -> List[BehaviorPattern]:
        """Generate realistic user behaviors based on profile."""
        
        behaviors = []
        template_key = user_profile.intent.value
        
        # Get base template
        base_template = self.behavior_templates.get(template_key, self.behavior_templates['browsing'])
        
        # Generate behaviors based on session characteristics
        for i in range(user_profile.page_views_per_session):
            # Add some randomness to behavior selection
            for template_behavior in base_template:
                if random.random() < template_behavior.confidence:
                    # Customize behavior based on user profile
                    customized_behavior = self._customize_behavior(template_behavior, user_profile, page_elements)
                    behaviors.append(customized_behavior)
            
            # Add some random behaviors
            random_behaviors = self._generate_random_behaviors(user_profile, page_elements)
            behaviors.extend(random_behaviors)
        
        return behaviors
    
    def _customize_behavior(
        self,
        template_behavior: BehaviorPattern,
        user_profile: UserProfile,
        page_elements: Optional[List[PageElement]] = None
    ) -> BehaviorPattern:
        """Customize a behavior pattern based on user profile."""
        
        customized = BehaviorPattern(
            behavior_type=template_behavior.behavior_type,
            target_element=template_behavior.target_element,
            action=template_behavior.action,
            parameters=template_behavior.parameters.copy(),
            confidence=template_behavior.confidence,
            reasoning=template_behavior.reasoning,
            timestamp=time.time()
        )
        
        # Adjust parameters based on user profile
        if customized.behavior_type == BehaviorType.SCROLLING:
            # Adjust scroll speed based on reading speed
            speed_multiplier = user_profile.reading_speed / 200.0
            if 'speed' in customized.parameters:
                if customized.parameters['speed'] == 'slow':
                    customized.parameters['speed'] = 'very_slow' if speed_multiplier > 1.5 else 'slow'
                elif customized.parameters['speed'] == 'medium':
                    customized.parameters['speed'] = 'slow' if speed_multiplier > 1.2 else 'medium'
        
        elif customized.behavior_type == BehaviorType.BROWSING:
            # Adjust browsing duration based on patience level
            if 'duration' in customized.parameters:
                duration_multiplier = user_profile.patience_level
                customized.parameters['duration'] *= duration_multiplier
        
        elif customized.behavior_type == BehaviorType.CLICKING:
            # Adjust click confidence based on technical savvy
            if 'confidence' in customized.parameters:
                customized.parameters['confidence'] *= user_profile.technical_savvy
        
        # Add target element if page elements are available
        if page_elements and customized.behavior_type in [BehaviorType.CLICKING, BehaviorType.FORM_FILLING]:
            target_element = self._select_target_element(customized.behavior_type, page_elements, user_profile)
            if target_element:
                customized.target_element = target_element.selector
                customized.parameters['element_id'] = target_element.element_id
        
        return customized
    
    def _generate_random_behaviors(
        self,
        user_profile: UserProfile,
        page_elements: Optional[List[PageElement]] = None
    ) -> List[BehaviorPattern]:
        """Generate random behaviors to add realism."""
        
        random_behaviors = []
        
        # Random scroll behavior
        if random.random() < 0.3:
            random_behaviors.append(BehaviorPattern(
                behavior_type=BehaviorType.SCROLLING,
                action="Random scroll",
                parameters={
                    "direction": random.choice(["up", "down"]),
                    "speed": random.choice(["slow", "medium", "fast"]),
                    "distance": random.uniform(0.1, 0.8)
                },
                confidence=random.uniform(0.5, 0.8),
                timestamp=time.time()
            ))
        
        # Random pause behavior
        if random.random() < 0.2:
            random_behaviors.append(BehaviorPattern(
                behavior_type=BehaviorType.BROWSING,
                action="Pause to think",
                parameters={"duration": random.uniform(1.0, 5.0)},
                confidence=random.uniform(0.6, 0.9),
                timestamp=time.time()
            ))
        
        # Random interaction with page elements
        if page_elements and random.random() < 0.4:
            interactive_elements = [e for e in page_elements if e.is_interactive]
            if interactive_elements:
                element = random.choice(interactive_elements)
                random_behaviors.append(BehaviorPattern(
                    behavior_type=BehaviorType.CLICKING,
                    target_element=element.selector,
                    action=f"Click on {element.element_type}",
                    parameters={
                        "target_type": element.element_type,
                        "confidence": random.uniform(0.4, 0.7)
                    },
                    confidence=random.uniform(0.4, 0.7),
                    timestamp=time.time()
                ))
        
        return random_behaviors
    
    def _select_target_element(
        self,
        behavior_type: BehaviorType,
        page_elements: List[PageElement],
        user_profile: UserProfile
    ) -> Optional[PageElement]:
        """Select an appropriate target element for interaction."""
        
        # Filter elements based on behavior type
        if behavior_type == BehaviorType.CLICKING:
            candidates = [e for e in page_elements if e.is_interactive and e.is_visible]
        elif behavior_type == BehaviorType.FORM_FILLING:
            candidates = [e for e in page_elements if e.element_type == 'form' and e.is_visible]
        else:
            candidates = page_elements
        
        if not candidates:
            return None
        
        # Score candidates based on user profile and importance
        scored_candidates = []
        for element in candidates:
            score = element.importance_score
            
            # Adjust score based on user preferences
            if user_profile.prefers_images and element.element_type == 'image':
                score *= 1.2
            if user_profile.prefers_videos and element.element_type == 'video':
                score *= 1.3
            if user_profile.ecommerce_ready and 'product' in element.element_id.lower():
                score *= 1.4
            
            scored_candidates.append((element, score))
        
        # Sort by score and select with some randomness
        scored_candidates.sort(key=lambda x: x[1], reverse=True)
        
        # Use weighted random selection
        total_score = sum(score for _, score in scored_candidates)
        if total_score == 0:
            return random.choice(candidates)
        
        random_value = random.uniform(0, total_score)
        current_sum = 0
        
        for element, score in scored_candidates:
            current_sum += score
            if current_sum >= random_value:
                return element
        
        return scored_candidates[0][0]
    
    def _generate_interaction_timeline(
        self,
        user_profile: UserProfile,
        behaviors: List[BehaviorPattern]
    ) -> List[Dict[str, Any]]:
        """Generate a timeline of interactions for the session."""
        
        timeline = []
        current_time = 0
        
        for behavior in behaviors:
            # Calculate timing based on behavior type and user profile
            if behavior.behavior_type == BehaviorType.BROWSING:
                duration = behavior.parameters.get('duration', 2.0)
                duration *= user_profile.patience_level
            elif behavior.behavior_type == BehaviorType.SCROLLING:
                speed = behavior.parameters.get('speed', 'medium')
                distance = behavior.parameters.get('distance', 0.5)
                duration = self._calculate_scroll_duration(speed, distance, user_profile)
            elif behavior.behavior_type == BehaviorType.CLICKING:
                duration = random.uniform(0.1, 0.5)
            else:
                duration = random.uniform(0.5, 2.0)
            
            timeline.append({
                'timestamp': current_time,
                'behavior': behavior,
                'duration': duration,
                'user_profile': user_profile.user_id
            })
            
            current_time += duration
            
            # Add random pauses between behaviors
            if random.random() < 0.3:
                pause_duration = random.uniform(0.5, 3.0)
                current_time += pause_duration
        
        return timeline
    
    def _calculate_scroll_duration(self, speed: str, distance: float, user_profile: UserProfile) -> float:
        """Calculate scroll duration based on speed, distance, and user profile."""
        
        base_speeds = {
            'very_slow': 0.5,
            'slow': 1.0,
            'medium': 2.0,
            'fast': 4.0,
            'very_fast': 8.0
        }
        
        base_speed = base_speeds.get(speed, 2.0)
        
        # Adjust for user reading speed
        speed_multiplier = user_profile.reading_speed / 200.0
        
        # Calculate duration
        duration = (distance * base_speed) / speed_multiplier
        
        return max(0.1, duration)  # Minimum 0.1 seconds
    
    def get_behavior_statistics(self, behaviors: List[BehaviorPattern]) -> Dict[str, Any]:
        """Get statistics about behavior patterns."""
        
        behavior_counts = {}
        total_confidence = 0
        
        for behavior in behaviors:
            behavior_type = behavior.behavior_type.value
            behavior_counts[behavior_type] = behavior_counts.get(behavior_type, 0) + 1
            total_confidence += behavior.confidence
        
        return {
            'total_behaviors': len(behaviors),
            'behavior_distribution': behavior_counts,
            'average_confidence': total_confidence / len(behaviors) if behaviors else 0,
            'most_common_behavior': max(behavior_counts.items(), key=lambda x: x[1])[0] if behavior_counts else None
        } 