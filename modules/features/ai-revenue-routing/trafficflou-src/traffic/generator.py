"""
🌐 Traffic Generation Engine

This module provides the core traffic generation functionality for the TrafficFlou
system, including HTTP request handling, user agent rotation, and realistic
traffic pattern simulation.

Author: TrafficFlou Team
Version: 1.0.0
"""

import asyncio
import time
import random
import hashlib
from typing import Dict, List, Optional, Any, Union
from urllib.parse import urlparse, urljoin
from dataclasses import dataclass, field

import aiohttp
import httpx
from fake_useragent import UserAgent
import structlog

from ..core.config import TrafficFlouConfig
from ..core.exceptions import TrafficGenerationError, NetworkError
from .behavior import BehaviorPattern, BehaviorType


@dataclass
class RequestMetrics:
    """Metrics for a single HTTP request."""
    
    request_id: str
    url: str
    method: str
    status_code: Optional[int] = None
    response_time: float = 0.0
    success: bool = False
    error_message: Optional[str] = None
    user_agent: str = ""
    proxy_used: Optional[str] = None
    timestamp: float = field(default_factory=time.time)


class TrafficGenerator:
    """
    🌐 Traffic Generation Engine
    
    Handles the generation of realistic HTTP traffic to target websites,
    including user agent rotation, proxy support, and behavior simulation.
    
    Attributes:
        config (TrafficFlouConfig): System configuration
        logger (structlog.BoundLogger): Structured logging instance
        user_agent_generator (UserAgent): User agent generator
        session_metrics (List[RequestMetrics]): Metrics for all requests
        active_sessions (Dict[str, aiohttp.ClientSession]): Active HTTP sessions
    """
    
    def __init__(self, config: TrafficFlouConfig):
        """
        Initialize the traffic generator.
        
        Args:
            config (TrafficFlouConfig): System configuration
        """
        self.config = config
        self.logger = structlog.get_logger(__name__)
        
        # Initialize user agent generator
        try:
            self.user_agent_generator = UserAgent()
        except Exception as e:
            self.logger.warning("Failed to initialize UserAgent, using fallback", error=str(e))
            self.user_agent_generator = None
        
        # Metrics tracking
        self.session_metrics: List[RequestMetrics] = []
        self.active_sessions: Dict[str, aiohttp.ClientSession] = {}
        
        # Request counters
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        
        self.logger.info("Traffic generator initialized", 
                        target_url=config.target_url,
                        user_agent_rotation=config.traffic.user_agent_rotation)
    
    async def generate_request(
        self,
        target_url: str,
        behavior_patterns: Union[Dict[str, Any], List[BehaviorPattern]],
        proxy: Optional[str] = None,
        session_id: Optional[str] = None
    ) -> RequestMetrics:
        """
        Generate a single HTTP request based on behavior patterns.
        
        Args:
            target_url (str): Target URL for the request
            behavior_patterns: Behavior patterns to simulate
            proxy (str): Optional proxy to use
            session_id (str): Optional session ID for tracking
            
        Returns:
            RequestMetrics: Metrics for the generated request
        """
        request_id = self._generate_request_id()
        
        try:
            # Parse behavior patterns
            if isinstance(behavior_patterns, dict):
                parsed_patterns = self._parse_behavior_dict(behavior_patterns)
            else:
                parsed_patterns = behavior_patterns
            
            # Generate request parameters
            request_params = await self._generate_request_params(
                target_url, parsed_patterns, proxy
            )
            
            # Execute the request
            metrics = await self._execute_request(request_params, request_id)
            
            # Update session metrics
            self.session_metrics.append(metrics)
            self.total_requests += 1
            
            if metrics.success:
                self.successful_requests += 1
            else:
                self.failed_requests += 1
            
            return metrics
            
        except Exception as e:
            self.logger.error("Request generation failed", 
                            request_id=request_id,
                            error=str(e))
            
            # Create error metrics
            error_metrics = RequestMetrics(
                request_id=request_id,
                url=target_url,
                method="GET",
                success=False,
                error_message=str(e),
                timestamp=time.time()
            )
            
            self.session_metrics.append(error_metrics)
            self.total_requests += 1
            self.failed_requests += 1
            
            return error_metrics
    
    def _parse_behavior_dict(self, behavior_dict: Dict[str, Any]) -> List[BehaviorPattern]:
        """Parse behavior dictionary into BehaviorPattern objects."""
        patterns = []
        
        # Extract behavior information from dictionary
        behavior_type = behavior_dict.get('type', 'browsing')
        target_element = behavior_dict.get('target_element')
        action = behavior_dict.get('action', '')
        parameters = behavior_dict.get('parameters', {})
        
        # Create behavior pattern
        pattern = BehaviorPattern(
            behavior_type=BehaviorType(behavior_type),
            target_element=target_element,
            action=action,
            parameters=parameters,
            timestamp=time.time()
        )
        
        patterns.append(pattern)
        return patterns
    
    async def _generate_request_params(
        self,
        target_url: str,
        behavior_patterns: List[BehaviorPattern],
        proxy: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate request parameters based on behavior patterns.
        
        Args:
            target_url (str): Target URL
            behavior_patterns (List[BehaviorPattern]): Behavior patterns
            proxy (str): Optional proxy
            
        Returns:
            Dict[str, Any]: Request parameters
        """
        # Base request parameters
        params = {
            'url': target_url,
            'method': 'GET',
            'headers': {},
            'timeout': self.config.traffic.timeout,
            'proxy': proxy
        }
        
        # Generate user agent
        if self.config.traffic.user_agent_rotation and self.user_agent_generator:
            params['headers']['User-Agent'] = self.user_agent_generator.random
        else:
            params['headers']['User-Agent'] = self._get_default_user_agent()
        
        # Add realistic headers
        params['headers'].update(self._generate_realistic_headers())
        
        # Process behavior patterns
        for pattern in behavior_patterns:
            params = self._apply_behavior_pattern(params, pattern)
        
        return params
    
    def _generate_realistic_headers(self) -> Dict[str, str]:
        """Generate realistic HTTP headers."""
        headers = {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
        
        # Add referer if available
        if hasattr(self, '_last_url') and self._last_url:
            headers['Referer'] = self._last_url
        
        # Add cache control
        if random.random() < 0.3:  # 30% chance of cache control
            headers['Cache-Control'] = 'no-cache'
        
        return headers
    
    def _get_default_user_agent(self) -> str:
        """Get a default user agent string."""
        default_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
        ]
        return random.choice(default_agents)
    
    def _apply_behavior_pattern(
        self,
        params: Dict[str, Any],
        pattern: BehaviorPattern
    ) -> Dict[str, Any]:
        """
        Apply a behavior pattern to request parameters.
        
        Args:
            params (Dict[str, Any]): Current request parameters
            pattern (BehaviorPattern): Behavior pattern to apply
            
        Returns:
            Dict[str, Any]: Updated request parameters
        """
        if pattern.behavior_type == BehaviorType.NAVIGATION:
            # Handle navigation behavior
            if pattern.target_element:
                params['url'] = self._build_navigation_url(params['url'], pattern.target_element)
        
        elif pattern.behavior_type == BehaviorType.SEARCH:
            # Handle search behavior
            if pattern.parameters.get('query'):
                params['url'] = self._build_search_url(params['url'], pattern.parameters['query'])
        
        elif pattern.behavior_type == BehaviorType.CLICKING:
            # Handle clicking behavior - might change method to POST
            if pattern.parameters.get('form_data'):
                params['method'] = 'POST'
                params['data'] = pattern.parameters['form_data']
        
        elif pattern.behavior_type == BehaviorType.FORM_FILLING:
            # Handle form filling behavior
            if pattern.parameters.get('form_data'):
                params['method'] = 'POST'
                params['data'] = pattern.parameters['form_data']
                params['headers']['Content-Type'] = 'application/x-www-form-urlencoded'
        
        return params
    
    def _build_navigation_url(self, base_url: str, target_element: str) -> str:
        """Build navigation URL based on target element."""
        try:
            # Simple URL building logic
            if target_element.startswith('http'):
                return target_element
            elif target_element.startswith('/'):
                return urljoin(base_url, target_element)
            else:
                return urljoin(base_url, f'/{target_element}')
        except Exception:
            return base_url
    
    def _build_search_url(self, base_url: str, query: str) -> str:
        """Build search URL with query parameters."""
        try:
            parsed = urlparse(base_url)
            if 'search' in parsed.path or 'q=' in parsed.query:
                # URL already has search parameters
                return base_url
            else:
                # Add search parameters
                separator = '&' if '?' in base_url else '?'
                return f"{base_url}{separator}q={query}"
        except Exception:
            return base_url
    
    async def _execute_request(
        self,
        params: Dict[str, Any],
        request_id: str
    ) -> RequestMetrics:
        """
        Execute an HTTP request with the given parameters.
        
        Args:
            params (Dict[str, Any]): Request parameters
            request_id (str): Unique request ID
            
        Returns:
            RequestMetrics: Request execution metrics
        """
        start_time = time.time()
        
        try:
            # Create session if needed
            session_key = f"session_{hash(params.get('proxy', 'default'))}"
            if session_key not in self.active_sessions:
                self.active_sessions[session_key] = aiohttp.ClientSession()
            
            session = self.active_sessions[session_key]
            
            # Prepare request parameters
            request_kwargs = {
                'method': params['method'],
                'headers': params['headers'],
                'timeout': aiohttp.ClientTimeout(total=params['timeout']),
            }
            
            # Add proxy if specified
            if params.get('proxy'):
                request_kwargs['proxy'] = params['proxy']
            
            # Add data for POST requests
            if params['method'] == 'POST' and params.get('data'):
                request_kwargs['data'] = params['data']
            
            # Execute request
            async with session.request(params['url'], **request_kwargs) as response:
                response_time = time.time() - start_time
                
                # Read response content
                content = await response.read()
                
                # Create metrics
                metrics = RequestMetrics(
                    request_id=request_id,
                    url=params['url'],
                    method=params['method'],
                    status_code=response.status,
                    response_time=response_time,
                    success=200 <= response.status < 400,
                    user_agent=params['headers'].get('User-Agent', ''),
                    proxy_used=params.get('proxy'),
                    timestamp=start_time
                )
                
                # Update last URL for referer
                self._last_url = params['url']
                
                self.logger.debug("Request completed", 
                                request_id=request_id,
                                status_code=response.status,
                                response_time=response_time,
                                success=metrics.success)
                
                return metrics
                
        except asyncio.TimeoutError:
            response_time = time.time() - start_time
            return RequestMetrics(
                request_id=request_id,
                url=params['url'],
                method=params['method'],
                response_time=response_time,
                success=False,
                error_message="Request timeout",
                user_agent=params['headers'].get('User-Agent', ''),
                proxy_used=params.get('proxy'),
                timestamp=start_time
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return RequestMetrics(
                request_id=request_id,
                url=params['url'],
                method=params['method'],
                response_time=response_time,
                success=False,
                error_message=str(e),
                user_agent=params['headers'].get('User-Agent', ''),
                proxy_used=params.get('proxy'),
                timestamp=start_time
            )
    
    def _generate_request_id(self) -> str:
        """Generate a unique request ID."""
        timestamp = int(time.time() * 1000)
        random_part = random.randint(1000, 9999)
        return f"req_{timestamp}_{random_part}"
    
    async def generate_batch_requests(
        self,
        target_url: str,
        count: int,
        behavior_patterns: List[BehaviorPattern],
        proxies: Optional[List[str]] = None
    ) -> List[RequestMetrics]:
        """
        Generate a batch of requests.
        
        Args:
            target_url (str): Target URL
            count (int): Number of requests to generate
            behavior_patterns (List[BehaviorPattern]): Behavior patterns
            proxies (List[str]): Optional list of proxies
            
        Returns:
            List[RequestMetrics]: Metrics for all requests
        """
        tasks = []
        
        for i in range(count):
            # Select proxy if available
            proxy = None
            if proxies:
                proxy = proxies[i % len(proxies)]
            
            # Create request task
            task = asyncio.create_task(
                self.generate_request(target_url, behavior_patterns, proxy)
            )
            tasks.append(task)
            
            # Add delay between requests
            if i > 0 and i % 10 == 0:
                await asyncio.sleep(random.uniform(0.1, 0.5))
        
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        metrics = []
        for result in results:
            if isinstance(result, Exception):
                self.logger.error("Batch request failed", error=str(result))
            else:
                metrics.append(result)
        
        return metrics
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get comprehensive metrics for all requests."""
        if not self.session_metrics:
            return {
                'total_requests': 0,
                'successful_requests': 0,
                'failed_requests': 0,
                'success_rate': 0.0,
                'average_response_time': 0.0,
                'total_response_time': 0.0
            }
        
        successful_metrics = [m for m in self.session_metrics if m.success]
        failed_metrics = [m for m in self.session_metrics if not m.success]
        
        total_response_time = sum(m.response_time for m in self.session_metrics)
        average_response_time = total_response_time / len(self.session_metrics)
        
        return {
            'total_requests': len(self.session_metrics),
            'successful_requests': len(successful_metrics),
            'failed_requests': len(failed_metrics),
            'success_rate': len(successful_metrics) / len(self.session_metrics),
            'average_response_time': average_response_time,
            'total_response_time': total_response_time,
            'user_agents_used': len(set(m.user_agent for m in self.session_metrics)),
            'proxies_used': len(set(m.proxy_used for m in self.session_metrics if m.proxy_used))
        }
    
    async def close(self):
        """Close all active sessions and clean up resources."""
        self.logger.info("Closing traffic generator")
        
        # Close all active sessions
        for session in self.active_sessions.values():
            await session.close()
        
        self.active_sessions.clear() 