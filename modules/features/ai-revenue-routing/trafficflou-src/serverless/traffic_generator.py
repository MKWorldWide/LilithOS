"""
🚀 Serverless Traffic Generator

Serverless-optimized traffic generation system for AWS Lambda deployment.
Integrates with LilithOS for advanced process management and optimization.

Author: TrafficFlou Team
Version: 2.0.0
"""

import asyncio
import aiohttp
import logging
import uuid
import time
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import json
import random

from ..core.config import TrafficFlouConfig
from ..lilithos.process_manager import LilithOSProcessManager
from ..ai_models.factory import AIModelFactory
from ..traffic.behavior import BehaviorSimulator
from ..analytics.metrics import MetricsCollector

logger = logging.getLogger(__name__)

@dataclass
class SessionData:
    """Session data structure"""
    session_id: str
    target_url: str
    start_time: datetime
    end_time: Optional[datetime] = None
    status: str = "active"
    traffic_count: int = 0
    user_profile: Optional[Dict[str, Any]] = None
    lilithos_features: Optional[Dict[str, Any]] = None
    performance_metrics: Dict[str, Any] = field(default_factory=dict)

class ServerlessTrafficGenerator:
    """
    🚀 Serverless Traffic Generator
    
    Optimized for AWS Lambda deployment with:
    - LilithOS process management integration
    - AI-powered behavior generation
    - Real-time analytics
    - Adaptive performance optimization
    - Session management
    """
    
    def __init__(self, config: TrafficFlouConfig, process_manager: LilithOSProcessManager):
        """Initialize Serverless Traffic Generator"""
        self.config = config
        self.process_manager = process_manager
        self.sessions: Dict[str, SessionData] = {}
        self.ai_models = AIModelFactory()
        self.behavior_simulator = BehaviorSimulator(config)
        self.metrics_collector = MetricsCollector()
        
        # Performance settings
        self.max_concurrent_sessions = 50
        self.session_timeout = 900  # 15 minutes
        self.request_timeout = 30
        self.retry_attempts = 3
        
        # LilithOS integration
        self.lilithos_optimization = True
        self.adaptive_scaling = True
        
        logger.info("🚀 Serverless Traffic Generator initialized")
    
    async def initialize(self):
        """Initialize the traffic generator"""
        try:
            logger.info("🚀 Initializing Serverless Traffic Generator...")
            
            # Initialize AI models
            await self.ai_models.initialize()
            
            # Initialize behavior simulator
            await self.behavior_simulator.initialize()
            
            # Initialize metrics collector
            await self.metrics_collector.initialize()
            
            # Register with LilithOS
            await self.process_manager.register_process(
                "traffic_generator",
                process_type="traffic_generation",
                priority="high"
            )
            
            logger.info("✅ Serverless Traffic Generator initialized successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize Serverless Traffic Generator: {e}")
            raise
    
    async def cleanup(self):
        """Cleanup resources"""
        try:
            logger.info("🧹 Cleaning up Serverless Traffic Generator...")
            
            # Stop all active sessions
            for session_id in list(self.sessions.keys()):
                await self.stop_session(session_id)
            
            # Cleanup AI models
            await self.ai_models.cleanup()
            
            # Cleanup behavior simulator
            await self.behavior_simulator.cleanup()
            
            # Cleanup metrics collector
            await self.metrics_collector.cleanup()
            
            # Unregister from LilithOS
            await self.process_manager.unregister_process("traffic_generator")
            
            logger.info("✅ Serverless Traffic Generator cleanup completed")
            
        except Exception as e:
            logger.error(f"❌ Error during cleanup: {e}")
    
    async def generate_traffic(
        self,
        target_url: str,
        session_duration: int = 300,
        traffic_intensity: float = 0.7,
        user_profile: Optional[Dict[str, Any]] = None,
        lilithos_features: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Generate traffic with LilithOS optimization"""
        try:
            # Check session limits
            if len(self.sessions) >= self.max_concurrent_sessions:
                raise Exception("Maximum concurrent sessions reached")
            
            # Create session
            session_id = str(uuid.uuid4())
            session_data = SessionData(
                session_id=session_id,
                target_url=target_url,
                start_time=datetime.now(),
                user_profile=user_profile or self._get_default_user_profile(),
                lilithos_features=lilithos_features or {}
            )
            
            self.sessions[session_id] = session_data
            
            # Register session with LilithOS
            await self.process_manager.register_process(
                f"session_{session_id}",
                process_type="traffic_session",
                priority="medium",
                target_url=target_url,
                intensity=traffic_intensity
            )
            
            # Start traffic generation
            traffic_task = asyncio.create_task(
                self._generate_session_traffic(session_id, session_duration, traffic_intensity)
            )
            
            # Schedule session cleanup
            asyncio.create_task(self._schedule_session_cleanup(session_id, session_duration))
            
            logger.info(f"🚀 Traffic generation started for session {session_id}")
            
            return {
                "session_id": session_id,
                "status": "started",
                "target_url": target_url,
                "duration": session_duration,
                "intensity": traffic_intensity
            }
            
        except Exception as e:
            logger.error(f"Failed to start traffic generation: {e}")
            raise
    
    async def _generate_session_traffic(
        self,
        session_id: str,
        duration: int,
        intensity: float
    ):
        """Generate traffic for a specific session"""
        try:
            session_data = self.sessions[session_id]
            start_time = time.time()
            end_time = start_time + duration
            
            # Calculate traffic parameters based on intensity
            base_requests_per_minute = 10
            requests_per_minute = int(base_requests_per_minute * intensity)
            delay_between_requests = 60.0 / requests_per_minute
            
            traffic_count = 0
            
            while time.time() < end_time and session_data.status == "active":
                try:
                    # Generate behavior pattern
                    behavior_pattern = await self.behavior_simulator.generate_behavior(
                        target_url=session_data.target_url,
                        user_profile=session_data.user_profile
                    )
                    
                    # Execute traffic request
                    success = await self._execute_traffic_request(
                        session_id, session_data.target_url, behavior_pattern
                    )
                    
                    if success:
                        traffic_count += 1
                        session_data.traffic_count = traffic_count
                        
                        # Update LilithOS metrics
                        await self.process_manager.update_process_metrics(
                            f"session_{session_id}",
                            traffic_count=traffic_count,
                            success_rate=traffic_count / (traffic_count + 1)
                        )
                    
                    # Adaptive delay based on LilithOS optimization
                    if self.lilithos_optimization:
                        optimized_delay = await self._get_optimized_delay(session_id, delay_between_requests)
                        await asyncio.sleep(optimized_delay)
                    else:
                        await asyncio.sleep(delay_between_requests)
                    
                except asyncio.CancelledError:
                    break
                except Exception as e:
                    logger.error(f"Error in session {session_id}: {e}")
                    await asyncio.sleep(5)  # Wait before retry
            
            # Session completed
            session_data.end_time = datetime.now()
            session_data.status = "completed"
            
            logger.info(f"✅ Session {session_id} completed with {traffic_count} requests")
            
        except Exception as e:
            logger.error(f"Session {session_id} failed: {e}")
            session_data.status = "error"
    
    async def _execute_traffic_request(
        self,
        session_id: str,
        target_url: str,
        behavior_pattern: Dict[str, Any]
    ) -> bool:
        """Execute a single traffic request"""
        try:
            # Create HTTP session with realistic headers
            headers = self._generate_realistic_headers(session_id)
            
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.request_timeout),
                headers=headers
            ) as session:
                
                # Execute request based on behavior pattern
                if behavior_pattern.get("type") == "page_view":
                    async with session.get(target_url) as response:
                        success = response.status == 200
                        
                        # Collect metrics
                        await self.metrics_collector.record_request(
                            session_id=session_id,
                            url=target_url,
                            status_code=response.status,
                            response_time=response.headers.get("X-Response-Time", 0),
                            behavior_type=behavior_pattern.get("type")
                        )
                        
                        return success
                
                elif behavior_pattern.get("type") == "api_call":
                    # Simulate API calls
                    api_url = f"{target_url}/api/{behavior_pattern.get('endpoint', 'status')}"
                    async with session.get(api_url) as response:
                        success = response.status in [200, 201, 204]
                        
                        await self.metrics_collector.record_request(
                            session_id=session_id,
                            url=api_url,
                            status_code=response.status,
                            response_time=response.headers.get("X-Response-Time", 0),
                            behavior_type="api_call"
                        )
                        
                        return success
                
                else:
                    # Default page view
                    async with session.get(target_url) as response:
                        success = response.status == 200
                        
                        await self.metrics_collector.record_request(
                            session_id=session_id,
                            url=target_url,
                            status_code=response.status,
                            response_time=response.headers.get("X-Response-Time", 0),
                            behavior_type="page_view"
                        )
                        
                        return success
                        
        except Exception as e:
            logger.error(f"Request execution failed for session {session_id}: {e}")
            return False
    
    def _generate_realistic_headers(self, session_id: str) -> Dict[str, str]:
        """Generate realistic HTTP headers"""
        user_agent = self._get_user_agent(session_id)
        
        return {
            "User-Agent": user_agent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Cache-Control": "max-age=0",
            "X-Forwarded-For": self._generate_ip_address(),
            "X-Real-IP": self._generate_ip_address()
        }
    
    def _get_user_agent(self, session_id: str) -> str:
        """Get user agent for session"""
        user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0"
        ]
        
        # Use session_id to consistently select user agent
        index = hash(session_id) % len(user_agents)
        return user_agents[index]
    
    def _generate_ip_address(self) -> str:
        """Generate realistic IP address"""
        return f"{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}"
    
    def _get_default_user_profile(self) -> Dict[str, Any]:
        """Get default user profile"""
        profiles = [
            {
                "age_group": "25-34",
                "interests": ["technology", "gaming"],
                "behavior_type": "focused",
                "session_duration": 300
            },
            {
                "age_group": "18-24",
                "interests": ["social_media", "entertainment"],
                "behavior_type": "casual",
                "session_duration": 180
            },
            {
                "age_group": "35-44",
                "interests": ["business", "professional"],
                "behavior_type": "efficient",
                "session_duration": 240
            }
        ]
        
        return random.choice(profiles)
    
    async def _get_optimized_delay(self, session_id: str, base_delay: float) -> float:
        """Get optimized delay based on LilithOS metrics"""
        try:
            # Get system metrics
            metrics = await self.process_manager.get_metrics()
            
            # Adjust delay based on system load
            cpu_usage = metrics.get("cpu_usage", 50.0)
            memory_usage = metrics.get("memory_usage", 50.0)
            
            # Increase delay under high load
            if cpu_usage > 80 or memory_usage > 80:
                return base_delay * 1.5
            elif cpu_usage > 60 or memory_usage > 60:
                return base_delay * 1.2
            else:
                return base_delay * 0.8  # Reduce delay under low load
                
        except Exception as e:
            logger.error(f"Error getting optimized delay: {e}")
            return base_delay
    
    async def _schedule_session_cleanup(self, session_id: str, duration: int):
        """Schedule session cleanup after duration"""
        await asyncio.sleep(duration)
        await self.stop_session(session_id)
    
    # Session management methods
    
    async def start_session(self, session_id: str) -> Dict[str, Any]:
        """Start a session"""
        if session_id in self.sessions:
            session_data = self.sessions[session_id]
            session_data.status = "active"
            
            await self.process_manager.update_process_metrics(
                f"session_{session_id}",
                status="active"
            )
            
            return {"status": "started", "session_id": session_id}
        else:
            raise Exception(f"Session {session_id} not found")
    
    async def stop_session(self, session_id: str) -> Dict[str, Any]:
        """Stop a session"""
        if session_id in self.sessions:
            session_data = self.sessions[session_id]
            session_data.status = "stopped"
            session_data.end_time = datetime.now()
            
            # Unregister from LilithOS
            await self.process_manager.unregister_process(f"session_{session_id}")
            
            return {
                "status": "stopped",
                "session_id": session_id,
                "traffic_count": session_data.traffic_count,
                "duration": (session_data.end_time - session_data.start_time).total_seconds()
            }
        else:
            raise Exception(f"Session {session_id} not found")
    
    async def pause_session(self, session_id: str) -> Dict[str, Any]:
        """Pause a session"""
        if session_id in self.sessions:
            session_data = self.sessions[session_id]
            session_data.status = "paused"
            
            await self.process_manager.update_process_metrics(
                f"session_{session_id}",
                status="paused"
            )
            
            return {"status": "paused", "session_id": session_id}
        else:
            raise Exception(f"Session {session_id} not found")
    
    async def resume_session(self, session_id: str) -> Dict[str, Any]:
        """Resume a session"""
        if session_id in self.sessions:
            session_data = self.sessions[session_id]
            session_data.status = "active"
            
            await self.process_manager.update_process_metrics(
                f"session_{session_id}",
                status="active"
            )
            
            return {"status": "resumed", "session_id": session_id}
        else:
            raise Exception(f"Session {session_id} not found")
    
    # Analytics methods
    
    async def get_analytics(self) -> Dict[str, Any]:
        """Get real-time analytics"""
        try:
            # Get basic session metrics
            active_sessions = len([s for s in self.sessions.values() if s.status == "active"])
            total_traffic = sum(s.traffic_count for s in self.sessions.values())
            
            # Get metrics from collector
            metrics = await self.metrics_collector.get_metrics()
            
            # Get LilithOS metrics
            lilithos_metrics = await self.process_manager.get_metrics()
            
            return {
                "sessions": {
                    "active": active_sessions,
                    "total": len(self.sessions),
                    "completed": len([s for s in self.sessions.values() if s.status == "completed"])
                },
                "traffic": {
                    "total_requests": total_traffic,
                    "success_rate": metrics.get("success_rate", 0.0),
                    "average_response_time": metrics.get("average_response_time", 0.0)
                },
                "lilithos": {
                    "cpu_usage": lilithos_metrics.get("cpu_usage", 0.0),
                    "memory_usage": lilithos_metrics.get("memory_usage", 0.0),
                    "optimization_status": lilithos_metrics.get("optimization_status", "unknown")
                },
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting analytics: {e}")
            return {"error": str(e)}
    
    async def get_active_sessions(self) -> int:
        """Get number of active sessions"""
        return len([s for s in self.sessions.values() if s.status == "active"])
    
    async def get_session_details(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed session information"""
        if session_id in self.sessions:
            session_data = self.sessions[session_id]
            return {
                "session_id": session_data.session_id,
                "target_url": session_data.target_url,
                "status": session_data.status,
                "start_time": session_data.start_time.isoformat(),
                "end_time": session_data.end_time.isoformat() if session_data.end_time else None,
                "traffic_count": session_data.traffic_count,
                "user_profile": session_data.user_profile,
                "lilithos_features": session_data.lilithos_features,
                "performance_metrics": session_data.performance_metrics
            }
        return None 