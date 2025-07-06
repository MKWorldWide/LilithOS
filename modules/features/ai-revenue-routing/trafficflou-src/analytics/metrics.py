"""
📊 Metrics Collection System

This module provides comprehensive metrics collection and analytics for the
TrafficFlou system, including real-time monitoring, performance tracking,
and data aggregation.

Author: TrafficFlou Team
Version: 1.0.0
"""

import time
import json
import asyncio
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, field
from collections import defaultdict, deque
from datetime import datetime, timedelta
import threading

import structlog
from prometheus_client import Counter, Histogram, Gauge, Summary

from ..core.config import TrafficFlouConfig
from ..core.exceptions import AnalyticsError


@dataclass
class RequestMetrics:
    """Detailed metrics for a single request."""
    
    request_id: str
    session_id: str
    url: str
    method: str
    status_code: Optional[int]
    response_time: float
    success: bool
    error_message: Optional[str]
    user_agent: str
    proxy_used: Optional[str]
    ai_model_used: Optional[str]
    behavior_type: Optional[str]
    timestamp: float
    size_bytes: Optional[int] = None


@dataclass
class SessionMetrics:
    """Aggregated metrics for a session."""
    
    session_id: str
    start_time: float
    end_time: Optional[float]
    total_requests: int
    successful_requests: int
    failed_requests: int
    total_response_time: float
    average_response_time: float
    success_rate: float
    unique_urls: int
    user_agents_used: int
    proxies_used: int
    ai_models_used: Dict[str, int]
    behavior_types: Dict[str, int]
    error_distribution: Dict[str, int]
    status_code_distribution: Dict[int, int]


@dataclass
class SystemMetrics:
    """System-wide metrics."""
    
    total_sessions: int
    active_sessions: int
    total_requests: int
    requests_per_second: float
    average_response_time: float
    success_rate: float
    error_rate: float
    ai_model_usage: Dict[str, int]
    proxy_usage: Dict[str, int]
    top_urls: List[Dict[str, Any]]
    top_errors: List[Dict[str, Any]]


class MetricsCollector:
    """
    📊 Metrics Collection System
    
    Comprehensive metrics collection and analytics for the TrafficFlou system.
    Provides real-time monitoring, performance tracking, and data aggregation
    with support for multiple storage backends.
    
    Attributes:
        config (TrafficFlouConfig): System configuration
        logger (structlog.BoundLogger): Structured logging instance
        active_sessions (Dict[str, SessionMetrics]): Active session metrics
        request_history (deque): Recent request history
        prometheus_metrics (Dict): Prometheus metrics objects
        storage_backend: Metrics storage backend
    """
    
    def __init__(self, config: TrafficFlouConfig):
        """
        Initialize the metrics collector.
        
        Args:
            config (TrafficFlouConfig): System configuration
        """
        self.config = config
        self.logger = structlog.get_logger(__name__)
        
        # Session and request tracking
        self.active_sessions: Dict[str, SessionMetrics] = {}
        self.completed_sessions: Dict[str, SessionMetrics] = {}
        self.request_history = deque(maxlen=10000)  # Keep last 10k requests
        
        # Initialize Prometheus metrics
        self.prometheus_metrics = self._initialize_prometheus_metrics()
        
        # Storage backend
        self.storage_backend = self._initialize_storage_backend()
        
        # Background tasks
        self._metrics_aggregation_task = None
        self._cleanup_task = None
        self._running = False
        
        self.logger.info("Metrics collector initialized", 
                        storage_backend=config.analytics.storage_backend)
    
    def _initialize_prometheus_metrics(self) -> Dict[str, Any]:
        """Initialize Prometheus metrics."""
        return {
            'requests_total': Counter(
                'trafficflou_requests_total',
                'Total number of requests',
                ['method', 'status_code', 'success']
            ),
            'request_duration': Histogram(
                'trafficflou_request_duration_seconds',
                'Request duration in seconds',
                ['method', 'status_code']
            ),
            'active_sessions': Gauge(
                'trafficflou_active_sessions',
                'Number of active sessions'
            ),
            'requests_per_second': Gauge(
                'trafficflou_requests_per_second',
                'Requests per second'
            ),
            'success_rate': Gauge(
                'trafficflou_success_rate',
                'Request success rate'
            ),
            'ai_model_requests': Counter(
                'trafficflou_ai_model_requests_total',
                'Total AI model requests',
                ['model_name', 'success']
            ),
            'proxy_requests': Counter(
                'trafficflou_proxy_requests_total',
                'Total proxy requests',
                ['proxy', 'success']
            )
        }
    
    def _initialize_storage_backend(self):
        """Initialize the metrics storage backend."""
        backend_type = self.config.analytics.storage_backend.lower()
        
        if backend_type == 'redis':
            return self._initialize_redis_backend()
        elif backend_type == 'influxdb':
            return self._initialize_influxdb_backend()
        elif backend_type == 'elasticsearch':
            return self._initialize_elasticsearch_backend()
        else:
            # Default to in-memory storage
            return self._initialize_memory_backend()
    
    def _initialize_redis_backend(self):
        """Initialize Redis storage backend."""
        try:
            import redis
            redis_client = redis.Redis.from_url(self.config.analytics.redis_url)
            redis_client.ping()  # Test connection
            self.logger.info("Redis storage backend initialized")
            return redis_client
        except Exception as e:
            self.logger.warning("Failed to initialize Redis backend, using memory", error=str(e))
            return None
    
    def _initialize_influxdb_backend(self):
        """Initialize InfluxDB storage backend."""
        try:
            from influxdb_client import InfluxDBClient
            client = InfluxDBClient.from_url(self.config.analytics.influxdb_url)
            self.logger.info("InfluxDB storage backend initialized")
            return client
        except Exception as e:
            self.logger.warning("Failed to initialize InfluxDB backend, using memory", error=str(e))
            return None
    
    def _initialize_elasticsearch_backend(self):
        """Initialize Elasticsearch storage backend."""
        try:
            from elasticsearch import Elasticsearch
            es_client = Elasticsearch([self.config.analytics.elasticsearch_url])
            if es_client.ping():
                self.logger.info("Elasticsearch storage backend initialized")
                return es_client
            else:
                raise Exception("Elasticsearch connection failed")
        except Exception as e:
            self.logger.warning("Failed to initialize Elasticsearch backend, using memory", error=str(e))
            return None
    
    def _initialize_memory_backend(self):
        """Initialize in-memory storage backend."""
        self.logger.info("Using in-memory storage backend")
        return None
    
    async def start_session(self, session_id: str) -> bool:
        """
        Start metrics collection for a new session.
        
        Args:
            session_id (str): Session ID
            
        Returns:
            bool: True if session started successfully
        """
        try:
            session_metrics = SessionMetrics(
                session_id=session_id,
                start_time=time.time(),
                end_time=None,
                total_requests=0,
                successful_requests=0,
                failed_requests=0,
                total_response_time=0.0,
                average_response_time=0.0,
                success_rate=0.0,
                unique_urls=0,
                user_agents_used=0,
                proxies_used=0,
                ai_models_used={},
                behavior_types={},
                error_distribution={},
                status_code_distribution={}
            )
            
            self.active_sessions[session_id] = session_metrics
            
            # Update Prometheus metrics
            self.prometheus_metrics['active_sessions'].inc()
            
            self.logger.info("Started metrics collection for session", session_id=session_id)
            return True
            
        except Exception as e:
            self.logger.error("Failed to start session metrics", 
                            session_id=session_id, error=str(e))
            return False
    
    async def stop_session(self, session_id: str) -> bool:
        """
        Stop metrics collection for a session.
        
        Args:
            session_id (str): Session ID
            
        Returns:
            bool: True if session stopped successfully
        """
        try:
            if session_id in self.active_sessions:
                session_metrics = self.active_sessions[session_id]
                session_metrics.end_time = time.time()
                
                # Move to completed sessions
                self.completed_sessions[session_id] = session_metrics
                del self.active_sessions[session_id]
                
                # Update Prometheus metrics
                self.prometheus_metrics['active_sessions'].dec()
                
                # Store in backend
                await self._store_session_metrics(session_metrics)
                
                self.logger.info("Stopped metrics collection for session", 
                               session_id=session_id,
                               total_requests=session_metrics.total_requests,
                               success_rate=session_metrics.success_rate)
                return True
            else:
                self.logger.warning("Session not found for metrics stop", session_id=session_id)
                return False
                
        except Exception as e:
            self.logger.error("Failed to stop session metrics", 
                            session_id=session_id, error=str(e))
            return False
    
    async def record_request(self, request_metrics: RequestMetrics) -> bool:
        """
        Record metrics for a single request.
        
        Args:
            request_metrics (RequestMetrics): Request metrics
            
        Returns:
            bool: True if metrics recorded successfully
        """
        try:
            # Add to request history
            self.request_history.append(request_metrics)
            
            # Update session metrics
            if request_metrics.session_id in self.active_sessions:
                session_metrics = self.active_sessions[request_metrics.session_id]
                self._update_session_metrics(session_metrics, request_metrics)
            
            # Update Prometheus metrics
            self._update_prometheus_metrics(request_metrics)
            
            # Store in backend
            await self._store_request_metrics(request_metrics)
            
            return True
            
        except Exception as e:
            self.logger.error("Failed to record request metrics", 
                            request_id=request_metrics.request_id, error=str(e))
            return False
    
    def _update_session_metrics(self, session_metrics: SessionMetrics, request_metrics: RequestMetrics):
        """Update session metrics with new request data."""
        
        # Basic counters
        session_metrics.total_requests += 1
        session_metrics.total_response_time += request_metrics.response_time
        
        if request_metrics.success:
            session_metrics.successful_requests += 1
        else:
            session_metrics.failed_requests += 1
        
        # Calculate averages
        session_metrics.average_response_time = (
            session_metrics.total_response_time / session_metrics.total_requests
        )
        session_metrics.success_rate = (
            session_metrics.successful_requests / session_metrics.total_requests
        )
        
        # Track unique values
        if not hasattr(session_metrics, '_unique_urls'):
            session_metrics._unique_urls = set()
        if not hasattr(session_metrics, '_user_agents'):
            session_metrics._user_agents = set()
        if not hasattr(session_metrics, '_proxies'):
            session_metrics._proxies = set()
        
        session_metrics._unique_urls.add(request_metrics.url)
        session_metrics._user_agents.add(request_metrics.user_agent)
        if request_metrics.proxy_used:
            session_metrics._proxies.add(request_metrics.proxy_used)
        
        session_metrics.unique_urls = len(session_metrics._unique_urls)
        session_metrics.user_agents_used = len(session_metrics._user_agents)
        session_metrics.proxies_used = len(session_metrics._proxies)
        
        # Track AI model usage
        if request_metrics.ai_model_used:
            session_metrics.ai_models_used[request_metrics.ai_model_used] = \
                session_metrics.ai_models_used.get(request_metrics.ai_model_used, 0) + 1
        
        # Track behavior types
        if request_metrics.behavior_type:
            session_metrics.behavior_types[request_metrics.behavior_type] = \
                session_metrics.behavior_types.get(request_metrics.behavior_type, 0) + 1
        
        # Track error distribution
        if not request_metrics.success and request_metrics.error_message:
            session_metrics.error_distribution[request_metrics.error_message] = \
                session_metrics.error_distribution.get(request_metrics.error_message, 0) + 1
        
        # Track status code distribution
        if request_metrics.status_code:
            session_metrics.status_code_distribution[request_metrics.status_code] = \
                session_metrics.status_code_distribution.get(request_metrics.status_code, 0) + 1
    
    def _update_prometheus_metrics(self, request_metrics: RequestMetrics):
        """Update Prometheus metrics."""
        
        # Request counter
        self.prometheus_metrics['requests_total'].labels(
            method=request_metrics.method,
            status_code=request_metrics.status_code or 0,
            success=request_metrics.success
        ).inc()
        
        # Request duration
        self.prometheus_metrics['request_duration'].labels(
            method=request_metrics.method,
            status_code=request_metrics.status_code or 0
        ).observe(request_metrics.response_time)
        
        # AI model requests
        if request_metrics.ai_model_used:
            self.prometheus_metrics['ai_model_requests'].labels(
                model_name=request_metrics.ai_model_used,
                success=request_metrics.success
            ).inc()
        
        # Proxy requests
        if request_metrics.proxy_used:
            self.prometheus_metrics['proxy_requests'].labels(
                proxy=request_metrics.proxy_used,
                success=request_metrics.success
            ).inc()
    
    async def _store_request_metrics(self, request_metrics: RequestMetrics):
        """Store request metrics in the backend."""
        if not self.storage_backend:
            return
        
        try:
            if hasattr(self.storage_backend, 'set'):  # Redis
                key = f"request:{request_metrics.request_id}"
                data = {
                    'session_id': request_metrics.session_id,
                    'url': request_metrics.url,
                    'method': request_metrics.method,
                    'status_code': request_metrics.status_code,
                    'response_time': request_metrics.response_time,
                    'success': request_metrics.success,
                    'timestamp': request_metrics.timestamp
                }
                self.storage_backend.setex(key, 3600, json.dumps(data))  # Expire in 1 hour
                
            elif hasattr(self.storage_backend, 'write_api'):  # InfluxDB
                from influxdb_client import Point
                point = Point("request_metrics") \
                    .tag("session_id", request_metrics.session_id) \
                    .tag("method", request_metrics.method) \
                    .tag("success", str(request_metrics.success)) \
                    .field("response_time", request_metrics.response_time) \
                    .field("status_code", request_metrics.status_code or 0) \
                    .time(request_metrics.timestamp * 1000000000)  # Convert to nanoseconds
                
                write_api = self.storage_backend.write_api()
                write_api.write(bucket="trafficflou", record=point)
                
            elif hasattr(self.storage_backend, 'index'):  # Elasticsearch
                doc = {
                    'session_id': request_metrics.session_id,
                    'url': request_metrics.url,
                    'method': request_metrics.method,
                    'status_code': request_metrics.status_code,
                    'response_time': request_metrics.response_time,
                    'success': request_metrics.success,
                    'timestamp': datetime.fromtimestamp(request_metrics.timestamp)
                }
                self.storage_backend.index(index='trafficflou-requests', document=doc)
                
        except Exception as e:
            self.logger.warning("Failed to store request metrics in backend", error=str(e))
    
    async def _store_session_metrics(self, session_metrics: SessionMetrics):
        """Store session metrics in the backend."""
        if not self.storage_backend:
            return
        
        try:
            if hasattr(self.storage_backend, 'set'):  # Redis
                key = f"session:{session_metrics.session_id}"
                data = {
                    'total_requests': session_metrics.total_requests,
                    'successful_requests': session_metrics.successful_requests,
                    'failed_requests': session_metrics.failed_requests,
                    'success_rate': session_metrics.success_rate,
                    'average_response_time': session_metrics.average_response_time,
                    'start_time': session_metrics.start_time,
                    'end_time': session_metrics.end_time
                }
                self.storage_backend.setex(key, 86400, json.dumps(data))  # Expire in 24 hours
                
            elif hasattr(self.storage_backend, 'write_api'):  # InfluxDB
                from influxdb_client import Point
                point = Point("session_metrics") \
                    .tag("session_id", session_metrics.session_id) \
                    .field("total_requests", session_metrics.total_requests) \
                    .field("successful_requests", session_metrics.successful_requests) \
                    .field("success_rate", session_metrics.success_rate) \
                    .field("average_response_time", session_metrics.average_response_time) \
                    .time(session_metrics.end_time * 1000000000)
                
                write_api = self.storage_backend.write_api()
                write_api.write(bucket="trafficflou", record=point)
                
            elif hasattr(self.storage_backend, 'index'):  # Elasticsearch
                doc = {
                    'session_id': session_metrics.session_id,
                    'total_requests': session_metrics.total_requests,
                    'successful_requests': session_metrics.successful_requests,
                    'success_rate': session_metrics.success_rate,
                    'average_response_time': session_metrics.average_response_time,
                    'start_time': datetime.fromtimestamp(session_metrics.start_time),
                    'end_time': datetime.fromtimestamp(session_metrics.end_time)
                }
                self.storage_backend.index(index='trafficflou-sessions', document=doc)
                
        except Exception as e:
            self.logger.warning("Failed to store session metrics in backend", error=str(e))
    
    def get_session_metrics(self, session_id: str) -> Optional[SessionMetrics]:
        """Get metrics for a specific session."""
        if session_id in self.active_sessions:
            return self.active_sessions[session_id]
        elif session_id in self.completed_sessions:
            return self.completed_sessions[session_id]
        else:
            return None
    
    def get_all_metrics(self) -> SystemMetrics:
        """Get system-wide metrics."""
        
        # Calculate totals
        total_sessions = len(self.active_sessions) + len(self.completed_sessions)
        active_sessions = len(self.active_sessions)
        total_requests = sum(s.total_requests for s in self.active_sessions.values()) + \
                        sum(s.total_requests for s in self.completed_sessions.values())
        
        # Calculate averages
        all_sessions = list(self.active_sessions.values()) + list(self.completed_sessions.values())
        if all_sessions:
            average_response_time = sum(s.average_response_time for s in all_sessions) / len(all_sessions)
            success_rate = sum(s.success_rate for s in all_sessions) / len(all_sessions)
        else:
            average_response_time = 0.0
            success_rate = 0.0
        
        # Calculate requests per second (last minute)
        now = time.time()
        recent_requests = [r for r in self.request_history if now - r.timestamp < 60]
        requests_per_second = len(recent_requests) / 60.0 if recent_requests else 0.0
        
        # Aggregate AI model usage
        ai_model_usage = defaultdict(int)
        for session in all_sessions:
            for model, count in session.ai_models_used.items():
                ai_model_usage[model] += count
        
        # Aggregate proxy usage
        proxy_usage = defaultdict(int)
        for session in all_sessions:
            proxy_usage[f"proxy_{session.proxies_used}"] += 1
        
        # Get top URLs and errors
        url_counts = defaultdict(int)
        error_counts = defaultdict(int)
        
        for request in self.request_history:
            url_counts[request.url] += 1
            if not request.success and request.error_message:
                error_counts[request.error_message] += 1
        
        top_urls = [{'url': url, 'count': count} for url, count in 
                   sorted(url_counts.items(), key=lambda x: x[1], reverse=True)[:10]]
        top_errors = [{'error': error, 'count': count} for error, count in 
                     sorted(error_counts.items(), key=lambda x: x[1], reverse=True)[:10]]
        
        return SystemMetrics(
            total_sessions=total_sessions,
            active_sessions=active_sessions,
            total_requests=total_requests,
            requests_per_second=requests_per_second,
            average_response_time=average_response_time,
            success_rate=success_rate,
            error_rate=1.0 - success_rate,
            ai_model_usage=dict(ai_model_usage),
            proxy_usage=dict(proxy_usage),
            top_urls=top_urls,
            top_errors=top_errors
        )
    
    async def start_background_tasks(self):
        """Start background tasks for metrics aggregation and cleanup."""
        if self._running:
            return
        
        self._running = True
        self._metrics_aggregation_task = asyncio.create_task(self._metrics_aggregation_loop())
        self._cleanup_task = asyncio.create_task(self._cleanup_loop())
        
        self.logger.info("Started background metrics tasks")
    
    async def stop_background_tasks(self):
        """Stop background tasks."""
        self._running = False
        
        if self._metrics_aggregation_task:
            self._metrics_aggregation_task.cancel()
        if self._cleanup_task:
            self._cleanup_task.cancel()
        
        self.logger.info("Stopped background metrics tasks")
    
    async def _metrics_aggregation_loop(self):
        """Background loop for metrics aggregation."""
        while self._running:
            try:
                # Update system-wide Prometheus metrics
                system_metrics = self.get_all_metrics()
                
                self.prometheus_metrics['requests_per_second'].set(system_metrics.requests_per_second)
                self.prometheus_metrics['success_rate'].set(system_metrics.success_rate)
                
                await asyncio.sleep(self.config.analytics.metrics_interval)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error("Error in metrics aggregation loop", error=str(e))
                await asyncio.sleep(5)
    
    async def _cleanup_loop(self):
        """Background loop for cleanup tasks."""
        while self._running:
            try:
                # Clean up old completed sessions (older than 24 hours)
                now = time.time()
                old_sessions = [
                    session_id for session_id, session in self.completed_sessions.items()
                    if session.end_time and now - session.end_time > 86400
                ]
                
                for session_id in old_sessions:
                    del self.completed_sessions[session_id]
                
                if old_sessions:
                    self.logger.info("Cleaned up old sessions", count=len(old_sessions))
                
                await asyncio.sleep(3600)  # Run every hour
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error("Error in cleanup loop", error=str(e))
                await asyncio.sleep(300)
    
    async def close(self):
        """Close the metrics collector and clean up resources."""
        await self.stop_background_tasks()
        
        if self.storage_backend:
            if hasattr(self.storage_backend, 'close'):
                self.storage_backend.close()
        
        self.logger.info("Metrics collector closed") 