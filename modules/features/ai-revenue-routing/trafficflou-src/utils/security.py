"""
🔒 Security and Privacy Utilities

This module provides security and privacy utilities for the TrafficFlou system,
including traffic obfuscation, user agent randomization, and privacy protection.

Author: TrafficFlou Team
Version: 1.0.0
"""

import hashlib
import random
import time
import uuid
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from urllib.parse import urlparse

import structlog


@dataclass
class SecurityConfig:
    """Configuration for security and privacy features."""
    
    traffic_obfuscation: bool = True
    user_agent_randomization: bool = True
    ip_rotation: bool = True
    fingerprint_randomization: bool = True
    cookie_management: bool = True
    rate_limiting: bool = True
    max_requests_per_minute: int = 60
    privacy_mode: str = "standard"  # standard, enhanced, maximum


class SecurityManager:
    """
    🔒 Security and Privacy Manager
    
    Manages security and privacy features for the TrafficFlou system,
    including traffic obfuscation, user agent randomization, and privacy protection.
    
    Attributes:
        config (SecurityConfig): Security configuration
        logger (structlog.BoundLogger): Structured logging instance
        user_agents (List[str]): Pool of user agent strings
        fingerprints (Dict[str, Any]): Browser fingerprint templates
        rate_limit_tokens (Dict[str, int]): Rate limiting tokens
    """
    
    def __init__(self, config: SecurityConfig):
        """
        Initialize the security manager.
        
        Args:
            config (SecurityConfig): Security configuration
        """
        self.config = config
        self.logger = structlog.get_logger(__name__)
        
        # Initialize user agent pool
        self.user_agents = self._initialize_user_agents()
        
        # Initialize browser fingerprints
        self.fingerprints = self._initialize_fingerprints()
        
        # Rate limiting
        self.rate_limit_tokens = {}
        self.rate_limit_last_reset = time.time()
        
        self.logger.info("Security manager initialized", 
                        privacy_mode=config.privacy_mode,
                        traffic_obfuscation=config.traffic_obfuscation)
    
    def _initialize_user_agents(self) -> List[str]:
        """Initialize a pool of realistic user agent strings."""
        return [
            # Chrome on Windows
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
            
            # Chrome on macOS
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            
            # Firefox on Windows
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0",
            
            # Firefox on macOS
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0",
            
            # Safari on macOS
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            
            # Edge on Windows
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0",
            
            # Mobile Chrome
            "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
        ]
    
    def _initialize_fingerprints(self) -> Dict[str, Any]:
        """Initialize browser fingerprint templates."""
        return {
            "chrome_windows": {
                "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "language": "en-US,en;q=0.9",
                "platform": "Win32",
                "hardwareConcurrency": 8,
                "deviceMemory": 8,
                "screen": {"width": 1920, "height": 1080},
                "timezone": "America/New_York",
                "webgl_vendor": "Google Inc. (Intel)",
                "webgl_renderer": "ANGLE (Intel, Intel(R) UHD Graphics 620 Direct3D11 vs_5_0 ps_5_0, D3D11)"
            },
            "firefox_macos": {
                "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0",
                "language": "en-US,en;q=0.5",
                "platform": "MacIntel",
                "hardwareConcurrency": 8,
                "deviceMemory": 16,
                "screen": {"width": 1440, "height": 900},
                "timezone": "America/Los_Angeles",
                "webgl_vendor": "Apple Inc.",
                "webgl_renderer": "Apple M1 Pro"
            },
            "safari_macos": {
                "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
                "language": "en-US,en;q=0.9",
                "platform": "MacIntel",
                "hardwareConcurrency": 10,
                "deviceMemory": 16,
                "screen": {"width": 2560, "height": 1600},
                "timezone": "America/Chicago",
                "webgl_vendor": "Apple Inc.",
                "webgl_renderer": "Apple M2"
            }
        }
    
    def get_random_user_agent(self) -> str:
        """
        Get a random user agent string.
        
        Returns:
            str: Random user agent string
        """
        if not self.config.user_agent_randomization:
            return self.user_agents[0]  # Return default user agent
        
        return random.choice(self.user_agents)
    
    def generate_fingerprint(self, fingerprint_type: Optional[str] = None) -> Dict[str, Any]:
        """
        Generate a randomized browser fingerprint.
        
        Args:
            fingerprint_type (str): Type of fingerprint to generate
            
        Returns:
            Dict[str, Any]: Generated browser fingerprint
        """
        if not self.config.fingerprint_randomization:
            return {}
        
        if fingerprint_type is None:
            fingerprint_type = random.choice(list(self.fingerprints.keys()))
        
        base_fingerprint = self.fingerprints[fingerprint_type].copy()
        
        # Add randomization
        if "hardwareConcurrency" in base_fingerprint:
            base_fingerprint["hardwareConcurrency"] = random.choice([4, 6, 8, 10, 12, 16])
        
        if "deviceMemory" in base_fingerprint:
            base_fingerprint["deviceMemory"] = random.choice([4, 8, 16, 32])
        
        if "screen" in base_fingerprint:
            # Randomize screen resolution slightly
            width = base_fingerprint["screen"]["width"]
            height = base_fingerprint["screen"]["height"]
            base_fingerprint["screen"]["width"] = width + random.randint(-100, 100)
            base_fingerprint["screen"]["height"] = height + random.randint(-100, 100)
        
        return base_fingerprint
    
    def obfuscate_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Obfuscate request data for privacy protection.
        
        Args:
            request_data (Dict[str, Any]): Original request data
            
        Returns:
            Dict[str, Any]: Obfuscated request data
        """
        if not self.config.traffic_obfuscation:
            return request_data
        
        obfuscated = request_data.copy()
        
        # Add random delays
        if "delay" not in obfuscated:
            obfuscated["delay"] = random.uniform(0.1, 2.0)
        
        # Randomize headers
        if "headers" in obfuscated:
            headers = obfuscated["headers"].copy()
            
            # Add random accept headers
            accept_headers = [
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
            ]
            headers["Accept"] = random.choice(accept_headers)
            
            # Add random accept-language
            languages = [
                "en-US,en;q=0.9",
                "en-US,en;q=0.8",
                "en-GB,en;q=0.9",
                "en-CA,en;q=0.9"
            ]
            headers["Accept-Language"] = random.choice(languages)
            
            # Add random accept-encoding
            encodings = [
                "gzip, deflate, br",
                "gzip, deflate",
                "gzip, br"
            ]
            headers["Accept-Encoding"] = random.choice(encodings)
            
            obfuscated["headers"] = headers
        
        return obfuscated
    
    def check_rate_limit(self, identifier: str) -> bool:
        """
        Check if a request is within rate limits.
        
        Args:
            identifier (str): Request identifier (IP, session, etc.)
            
        Returns:
            bool: True if request is allowed, False if rate limited
        """
        if not self.config.rate_limiting:
            return True
        
        current_time = time.time()
        
        # Reset tokens if a minute has passed
        if current_time - self.rate_limit_last_reset >= 60:
            self.rate_limit_tokens.clear()
            self.rate_limit_last_reset = current_time
        
        # Check current tokens
        current_tokens = self.rate_limit_tokens.get(identifier, 0)
        
        if current_tokens >= self.config.max_requests_per_minute:
            self.logger.warning("Rate limit exceeded", 
                              identifier=identifier,
                              limit=self.config.max_requests_per_minute)
            return False
        
        # Increment tokens
        self.rate_limit_tokens[identifier] = current_tokens + 1
        return True
    
    def generate_session_id(self) -> str:
        """
        Generate a unique session identifier.
        
        Returns:
            str: Unique session ID
        """
        # Generate a UUID and hash it for privacy
        session_uuid = str(uuid.uuid4())
        session_hash = hashlib.sha256(session_uuid.encode()).hexdigest()[:16]
        return f"session_{session_hash}"
    
    def sanitize_url(self, url: str) -> str:
        """
        Sanitize URL to remove sensitive information.
        
        Args:
            url (str): Original URL
            
        Returns:
            str: Sanitized URL
        """
        try:
            parsed = urlparse(url)
            
            # Remove query parameters that might contain sensitive data
            sensitive_params = ['token', 'key', 'password', 'secret', 'auth']
            if parsed.query:
                from urllib.parse import parse_qs, urlencode
                params = parse_qs(parsed.query)
                
                # Remove sensitive parameters
                for param in sensitive_params:
                    if param in params:
                        del params[param]
                
                # Rebuild query string
                if params:
                    new_query = urlencode(params, doseq=True)
                    parsed = parsed._replace(query=new_query)
                else:
                    parsed = parsed._replace(query='')
            
            return parsed.geturl()
            
        except Exception as e:
            self.logger.warning("Failed to sanitize URL", url=url, error=str(e))
            return url
    
    def generate_privacy_headers(self) -> Dict[str, str]:
        """
        Generate privacy-focused HTTP headers.
        
        Returns:
            Dict[str, str]: Privacy headers
        """
        headers = {
            "DNT": "1",  # Do Not Track
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
        }
        
        if self.config.privacy_mode in ["enhanced", "maximum"]:
            headers.update({
                "Sec-CH-UA": '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
                "Sec-CH-UA-Mobile": "?0",
                "Sec-CH-UA-Platform": '"Windows"',
            })
        
        return headers
    
    def manage_cookies(self, cookies: Dict[str, str]) -> Dict[str, str]:
        """
        Manage cookies for privacy protection.
        
        Args:
            cookies (Dict[str, str]): Original cookies
            
        Returns:
            Dict[str, str]: Managed cookies
        """
        if not self.config.cookie_management:
            return cookies
        
        managed_cookies = {}
        
        # Filter out tracking cookies
        tracking_patterns = [
            '_ga', '_gid', '_fbp', '_fbc', 'utm_', 'gclid', 'fbclid',
            'mc_cid', 'mc_eid', 'ref', 'source', 'campaign'
        ]
        
        for name, value in cookies.items():
            # Check if cookie name matches tracking patterns
            is_tracking = any(pattern in name.lower() for pattern in tracking_patterns)
            
            if not is_tracking:
                managed_cookies[name] = value
            else:
                self.logger.debug("Filtered tracking cookie", cookie_name=name)
        
        return managed_cookies
    
    def get_privacy_score(self, request_data: Dict[str, Any]) -> float:
        """
        Calculate privacy score for a request.
        
        Args:
            request_data (Dict[str, Any]): Request data
            
        Returns:
            float: Privacy score (0.0 to 1.0)
        """
        score = 1.0
        
        # Check for privacy headers
        headers = request_data.get('headers', {})
        if 'DNT' in headers:
            score += 0.1
        if 'Sec-Fetch-Dest' in headers:
            score += 0.1
        
        # Check for tracking cookies
        cookies = request_data.get('cookies', {})
        tracking_cookies = sum(1 for name in cookies.keys() 
                             if any(pattern in name.lower() 
                                   for pattern in ['_ga', '_fbp', 'utm_']))
        score -= tracking_cookies * 0.1
        
        # Check for user agent randomization
        if request_data.get('user_agent_randomized', False):
            score += 0.2
        
        # Check for fingerprint randomization
        if request_data.get('fingerprint_randomized', False):
            score += 0.2
        
        return max(0.0, min(1.0, score))
    
    def log_privacy_event(self, event_type: str, data: Dict[str, Any]):
        """
        Log privacy-related events.
        
        Args:
            event_type (str): Type of privacy event
            data (Dict[str, Any]): Event data
        """
        self.logger.info(
            "Privacy event",
            event_type=event_type,
            privacy_score=self.get_privacy_score(data),
            **{k: v for k, v in data.items() if k not in ['headers', 'cookies']}
        ) 