"""
📊 Analytics Dashboard

This module provides the analytics dashboard for real-time monitoring
and visualization of TrafficFlou system metrics.

Author: TrafficFlou Team
Version: 1.0.0
"""

import time
import json
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta

import structlog


@dataclass
class DashboardData:
    """Dashboard data structure."""
    
    # System overview
    total_sessions: int
    active_sessions: int
    total_requests: int
    requests_per_second: float
    success_rate: float
    average_response_time: float
    
    # Performance metrics
    cpu_usage: float
    memory_usage: float
    network_usage: float
    
    # AI model usage
    ai_model_usage: Dict[str, int]
    ai_model_costs: Dict[str, float]
    
    # Traffic patterns
    traffic_by_hour: List[Dict[str, Any]]
    top_urls: List[Dict[str, Any]]
    top_errors: List[Dict[str, Any]]
    
    # Session data
    recent_sessions: List[Dict[str, Any]]
    session_duration_distribution: List[Dict[str, Any]]
    
    # Timestamp
    timestamp: float = field(default_factory=time.time)


class AnalyticsDashboard:
    """
    📊 Analytics Dashboard
    
    Provides real-time dashboard data for monitoring TrafficFlou system
    performance, traffic patterns, and analytics.
    
    Attributes:
        config (TrafficFlouConfig): System configuration
        logger (structlog.BoundLogger): Structured logging instance
        metrics_collector: Metrics collection system
        dashboard_data (DashboardData): Current dashboard data
    """
    
    def __init__(self, config, metrics_collector=None):
        """
        Initialize the analytics dashboard.
        
        Args:
            config: System configuration
            metrics_collector: Metrics collection system
        """
        self.config = config
        self.logger = structlog.get_logger(__name__)
        self.metrics_collector = metrics_collector
        
        # Initialize dashboard data
        self.dashboard_data = self._create_empty_dashboard_data()
        
        self.logger.info("Analytics dashboard initialized")
    
    def _create_empty_dashboard_data(self) -> DashboardData:
        """Create empty dashboard data structure."""
        return DashboardData(
            total_sessions=0,
            active_sessions=0,
            total_requests=0,
            requests_per_second=0.0,
            success_rate=0.0,
            average_response_time=0.0,
            cpu_usage=0.0,
            memory_usage=0.0,
            network_usage=0.0,
            ai_model_usage={},
            ai_model_costs={},
            traffic_by_hour=[],
            top_urls=[],
            top_errors=[],
            recent_sessions=[],
            session_duration_distribution=[]
        )
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """
        Get current dashboard data.
        
        Returns:
            Dict[str, Any]: Dashboard data
        """
        try:
            # Update dashboard data
            self._update_dashboard_data()
            
            # Convert to dictionary for JSON serialization
            return {
                "system_overview": {
                    "total_sessions": self.dashboard_data.total_sessions,
                    "active_sessions": self.dashboard_data.active_sessions,
                    "total_requests": self.dashboard_data.total_requests,
                    "requests_per_second": self.dashboard_data.requests_per_second,
                    "success_rate": self.dashboard_data.success_rate,
                    "average_response_time": self.dashboard_data.average_response_time,
                    "timestamp": self.dashboard_data.timestamp
                },
                "performance_metrics": {
                    "cpu_usage": self.dashboard_data.cpu_usage,
                    "memory_usage": self.dashboard_data.memory_usage,
                    "network_usage": self.dashboard_data.network_usage
                },
                "ai_model_usage": {
                    "usage": self.dashboard_data.ai_model_usage,
                    "costs": self.dashboard_data.ai_model_costs
                },
                "traffic_patterns": {
                    "traffic_by_hour": self.dashboard_data.traffic_by_hour,
                    "top_urls": self.dashboard_data.top_urls,
                    "top_errors": self.dashboard_data.top_errors
                },
                "session_data": {
                    "recent_sessions": self.dashboard_data.recent_sessions,
                    "session_duration_distribution": self.dashboard_data.session_duration_distribution
                }
            }
            
        except Exception as e:
            self.logger.error("Failed to get dashboard data", error=str(e))
            return self._get_error_dashboard_data()
    
    def _update_dashboard_data(self):
        """Update dashboard data from metrics collector."""
        if not self.metrics_collector:
            return
        
        try:
            # Get system metrics
            system_metrics = self.metrics_collector.get_all_metrics()
            
            # Update system overview
            self.dashboard_data.total_sessions = system_metrics.get('total_sessions', 0)
            self.dashboard_data.active_sessions = system_metrics.get('active_sessions', 0)
            self.dashboard_data.total_requests = system_metrics.get('total_requests', 0)
            self.dashboard_data.requests_per_second = system_metrics.get('requests_per_second', 0.0)
            self.dashboard_data.success_rate = system_metrics.get('success_rate', 0.0)
            self.dashboard_data.average_response_time = system_metrics.get('average_response_time', 0.0)
            
            # Update AI model usage
            self.dashboard_data.ai_model_usage = system_metrics.get('ai_model_usage', {})
            
            # Update traffic patterns
            self.dashboard_data.top_urls = system_metrics.get('top_urls', [])
            self.dashboard_data.top_errors = system_metrics.get('top_errors', [])
            
            # Update timestamp
            self.dashboard_data.timestamp = time.time()
            
        except Exception as e:
            self.logger.error("Failed to update dashboard data", error=str(e))
    
    def _get_error_dashboard_data(self) -> Dict[str, Any]:
        """Get error dashboard data when metrics collection fails."""
        return {
            "error": "Failed to load dashboard data",
            "system_overview": {
                "total_sessions": 0,
                "active_sessions": 0,
                "total_requests": 0,
                "requests_per_second": 0.0,
                "success_rate": 0.0,
                "average_response_time": 0.0,
                "timestamp": time.time()
            },
            "performance_metrics": {
                "cpu_usage": 0.0,
                "memory_usage": 0.0,
                "network_usage": 0.0
            },
            "ai_model_usage": {
                "usage": {},
                "costs": {}
            },
            "traffic_patterns": {
                "traffic_by_hour": [],
                "top_urls": [],
                "top_errors": []
            },
            "session_data": {
                "recent_sessions": [],
                "session_duration_distribution": []
            }
        }
    
    def get_session_dashboard_data(self, session_id: str) -> Dict[str, Any]:
        """
        Get dashboard data for a specific session.
        
        Args:
            session_id (str): Session ID
            
        Returns:
            Dict[str, Any]: Session-specific dashboard data
        """
        if not self.metrics_collector:
            return {"error": "Metrics collector not available"}
        
        try:
            session_metrics = self.metrics_collector.get_session_metrics(session_id)
            
            if not session_metrics:
                return {"error": f"Session {session_id} not found"}
            
            return {
                "session_id": session_id,
                "total_requests": session_metrics.get('total_requests', 0),
                "successful_requests": session_metrics.get('successful_requests', 0),
                "failed_requests": session_metrics.get('failed_requests', 0),
                "success_rate": session_metrics.get('success_rate', 0.0),
                "average_response_time": session_metrics.get('average_response_time', 0.0),
                "ai_model_usage": session_metrics.get('ai_model_usage', {}),
                "behavior_types": session_metrics.get('behavior_types', {}),
                "error_distribution": session_metrics.get('error_distribution', {}),
                "status_code_distribution": session_metrics.get('status_code_distribution', {}),
                "timestamp": time.time()
            }
            
        except Exception as e:
            self.logger.error("Failed to get session dashboard data", 
                            session_id=session_id, error=str(e))
            return {"error": f"Failed to load session data: {e}"}
    
    def get_performance_dashboard_data(self) -> Dict[str, Any]:
        """
        Get performance-focused dashboard data.
        
        Returns:
            Dict[str, Any]: Performance dashboard data
        """
        try:
            # Get system metrics
            system_metrics = self.metrics_collector.get_all_metrics() if self.metrics_collector else {}
            
            # Calculate performance metrics
            performance_data = {
                "requests_per_second": system_metrics.get('requests_per_second', 0.0),
                "average_response_time": system_metrics.get('average_response_time', 0.0),
                "success_rate": system_metrics.get('success_rate', 0.0),
                "error_rate": 1.0 - system_metrics.get('success_rate', 0.0),
                "total_requests": system_metrics.get('total_requests', 0),
                "active_sessions": system_metrics.get('active_sessions', 0),
                "ai_model_performance": self._get_ai_model_performance(),
                "traffic_trends": self._get_traffic_trends(),
                "timestamp": time.time()
            }
            
            return performance_data
            
        except Exception as e:
            self.logger.error("Failed to get performance dashboard data", error=str(e))
            return {"error": f"Failed to load performance data: {e}"}
    
    def _get_ai_model_performance(self) -> Dict[str, Any]:
        """Get AI model performance metrics."""
        if not self.metrics_collector:
            return {}
        
        try:
            # This would typically come from the metrics collector
            # For now, return mock data
            return {
                "total_requests": 0,
                "average_response_time": 0.0,
                "success_rate": 0.0,
                "cost_per_request": 0.0,
                "models": {}
            }
        except Exception as e:
            self.logger.error("Failed to get AI model performance", error=str(e))
            return {}
    
    def _get_traffic_trends(self) -> List[Dict[str, Any]]:
        """Get traffic trends data."""
        try:
            # Generate mock traffic trends for the last 24 hours
            trends = []
            now = datetime.now()
            
            for i in range(24):
                hour = now - timedelta(hours=i)
                trends.append({
                    "hour": hour.strftime("%H:00"),
                    "requests": random.randint(10, 100),
                    "success_rate": random.uniform(0.8, 1.0),
                    "average_response_time": random.uniform(0.1, 2.0)
                })
            
            return list(reversed(trends))
            
        except Exception as e:
            self.logger.error("Failed to get traffic trends", error=str(e))
            return []
    
    def get_realtime_metrics(self) -> Dict[str, Any]:
        """
        Get real-time metrics for live monitoring.
        
        Returns:
            Dict[str, Any]: Real-time metrics
        """
        try:
            if not self.metrics_collector:
                return {"error": "Metrics collector not available"}
            
            system_metrics = self.metrics_collector.get_all_metrics()
            
            return {
                "requests_per_second": system_metrics.get('requests_per_second', 0.0),
                "active_sessions": system_metrics.get('active_sessions', 0),
                "success_rate": system_metrics.get('success_rate', 0.0),
                "average_response_time": system_metrics.get('average_response_time', 0.0),
                "total_requests": system_metrics.get('total_requests', 0),
                "timestamp": time.time()
            }
            
        except Exception as e:
            self.logger.error("Failed to get real-time metrics", error=str(e))
            return {"error": f"Failed to load real-time metrics: {e}"}
    
    def export_dashboard_data(self, format_type: str = "json") -> str:
        """
        Export dashboard data in specified format.
        
        Args:
            format_type (str): Export format (json, csv)
            
        Returns:
            str: Exported data
        """
        try:
            dashboard_data = self.get_dashboard_data()
            
            if format_type.lower() == "json":
                return json.dumps(dashboard_data, indent=2)
            elif format_type.lower() == "csv":
                return self._convert_to_csv(dashboard_data)
            else:
                raise ValueError(f"Unsupported format: {format_type}")
                
        except Exception as e:
            self.logger.error("Failed to export dashboard data", 
                            format=format_type, error=str(e))
            return f"Error: {e}"
    
    def _convert_to_csv(self, data: Dict[str, Any]) -> str:
        """Convert dashboard data to CSV format."""
        try:
            import csv
            import io
            
            output = io.StringIO()
            writer = csv.writer(output)
            
            # Write headers
            writer.writerow(["Metric", "Value"])
            
            # Write system overview
            system_overview = data.get("system_overview", {})
            for key, value in system_overview.items():
                if key != "timestamp":
                    writer.writerow([f"system_{key}", value])
            
            # Write performance metrics
            performance_metrics = data.get("performance_metrics", {})
            for key, value in performance_metrics.items():
                writer.writerow([f"performance_{key}", value])
            
            return output.getvalue()
            
        except Exception as e:
            self.logger.error("Failed to convert to CSV", error=str(e))
            return f"Error converting to CSV: {e}"
    
    def get_dashboard_config(self) -> Dict[str, Any]:
        """
        Get dashboard configuration.
        
        Returns:
            Dict[str, Any]: Dashboard configuration
        """
        return {
            "refresh_interval": 5,  # seconds
            "max_data_points": 1000,
            "enabled_features": [
                "system_overview",
                "performance_metrics",
                "ai_model_usage",
                "traffic_patterns",
                "session_data"
            ],
            "chart_types": {
                "traffic_trends": "line",
                "success_rate": "gauge",
                "ai_model_usage": "pie",
                "top_urls": "bar"
            }
        } 