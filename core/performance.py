"""
LilithOS Performance Monitor
===========================

Handles system performance monitoring and optimization:
- CPU and memory usage tracking
- Disk I/O monitoring
- Network performance metrics
- Application performance profiling
- Automatic optimization recommendations
"""

import os
import time
import asyncio
import logging
import threading
import psutil
import platform
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json
import yaml
from collections import deque
import statistics

class MetricType(Enum):
    """Performance metric types"""
    CPU_USAGE = "cpu_usage"
    MEMORY_USAGE = "memory_usage"
    DISK_USAGE = "disk_usage"
    NETWORK_IO = "network_io"
    DISK_IO = "disk_io"
    PROCESS_COUNT = "process_count"
    THREAD_COUNT = "thread_count"
    RESPONSE_TIME = "response_time"
    THROUGHPUT = "throughput"
    ERROR_RATE = "error_rate"

@dataclass
class PerformanceMetric:
    """Performance metric container"""
    timestamp: float
    metric_type: MetricType
    value: float
    unit: str = ""
    tags: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class PerformanceAlert:
    """Performance alert container"""
    timestamp: float
    alert_type: str
    severity: str
    message: str
    metric_value: float
    threshold: float
    component: str = ""
    resolved: bool = False

@dataclass
class SystemResources:
    """System resources information"""
    cpu_count: int = 0
    cpu_usage_percent: float = 0.0
    memory_total: int = 0
    memory_available: int = 0
    memory_used: int = 0
    memory_percent: float = 0.0
    disk_total: int = 0
    disk_used: int = 0
    disk_free: int = 0
    disk_percent: float = 0.0
    network_bytes_sent: int = 0
    network_bytes_recv: int = 0
    process_count: int = 0
    thread_count: int = 0

class MetricCollector:
    """Collects performance metrics from various sources"""
    
    def __init__(self, performance_monitor: 'PerformanceMonitor'):
        self.performance_monitor = performance_monitor
        self.collection_interval = 5.0  # 5 seconds
        self.metrics_buffer: deque = deque(maxlen=1000)
        self.last_network_stats = None
        self.last_disk_stats = None
    
    async def start_collection(self):
        """Start metric collection"""
        while True:
            try:
                await self._collect_metrics()
                await asyncio.sleep(self.collection_interval)
            except Exception as e:
                self.performance_monitor.logger.error(f"Metric collection error: {e}")
                await asyncio.sleep(1)
    
    async def _collect_metrics(self):
        """Collect all performance metrics"""
        timestamp = time.time()
        
        # CPU metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        self._add_metric(timestamp, MetricType.CPU_USAGE, cpu_percent, "%")
        
        # Memory metrics
        memory = psutil.virtual_memory()
        self._add_metric(timestamp, MetricType.MEMORY_USAGE, memory.percent, "%")
        
        # Disk metrics
        disk = psutil.disk_usage('/')
        disk_percent = (disk.used / disk.total) * 100
        self._add_metric(timestamp, MetricType.DISK_USAGE, disk_percent, "%")
        
        # Network metrics
        await self._collect_network_metrics(timestamp)
        
        # Disk I/O metrics
        await self._collect_disk_io_metrics(timestamp)
        
        # Process metrics
        process_count = len(psutil.pids())
        self._add_metric(timestamp, MetricType.PROCESS_COUNT, process_count, "processes")
        
        # Thread metrics
        thread_count = psutil.cpu_count() * 2  # Approximate
        self._add_metric(timestamp, MetricType.THREAD_COUNT, thread_count, "threads")
    
    async def _collect_network_metrics(self, timestamp: float):
        """Collect network I/O metrics"""
        try:
            network_stats = psutil.net_io_counters()
            
            if self.last_network_stats:
                bytes_sent = network_stats.bytes_sent - self.last_network_stats.bytes_sent
                bytes_recv = network_stats.bytes_recv - self.last_network_stats.bytes_recv
                
                # Convert to MB/s
                bytes_sent_mbps = (bytes_sent / 1024 / 1024) / self.collection_interval
                bytes_recv_mbps = (bytes_recv / 1024 / 1024) / self.collection_interval
                
                self._add_metric(timestamp, MetricType.NETWORK_IO, bytes_sent_mbps, "MB/s", {"direction": "sent"})
                self._add_metric(timestamp, MetricType.NETWORK_IO, bytes_recv_mbps, "MB/s", {"direction": "received"})
            
            self.last_network_stats = network_stats
            
        except Exception as e:
            self.performance_monitor.logger.error(f"Network metrics collection failed: {e}")
    
    async def _collect_disk_io_metrics(self, timestamp: float):
        """Collect disk I/O metrics"""
        try:
            disk_io = psutil.disk_io_counters()
            
            if self.last_disk_stats:
                read_bytes = disk_io.read_bytes - self.last_disk_stats.read_bytes
                write_bytes = disk_io.write_bytes - self.last_disk_stats.write_bytes
                
                # Convert to MB/s
                read_mbps = (read_bytes / 1024 / 1024) / self.collection_interval
                write_mbps = (write_bytes / 1024 / 1024) / self.collection_interval
                
                self._add_metric(timestamp, MetricType.DISK_IO, read_mbps, "MB/s", {"direction": "read"})
                self._add_metric(timestamp, MetricType.DISK_IO, write_mbps, "MB/s", {"direction": "write"})
            
            self.last_disk_stats = disk_io
            
        except Exception as e:
            self.performance_monitor.logger.error(f"Disk I/O metrics collection failed: {e}")
    
    def _add_metric(self, timestamp: float, metric_type: MetricType, value: float, unit: str = "", tags: Dict[str, str] = None):
        """Add a metric to the buffer"""
        metric = PerformanceMetric(
            timestamp=timestamp,
            metric_type=metric_type,
            value=value,
            unit=unit,
            tags=tags or {}
        )
        self.metrics_buffer.append(metric)
    
    def get_recent_metrics(self, metric_type: Optional[MetricType] = None, minutes: int = 5) -> List[PerformanceMetric]:
        """Get recent metrics, optionally filtered by type"""
        cutoff_time = time.time() - (minutes * 60)
        metrics = [m for m in self.metrics_buffer if m.timestamp >= cutoff_time]
        
        if metric_type:
            metrics = [m for m in metrics if m.metric_type == metric_type]
        
        return metrics

class AlertManager:
    """Manages performance alerts and thresholds"""
    
    def __init__(self, performance_monitor: 'PerformanceMonitor'):
        self.performance_monitor = performance_monitor
        self.alerts: List[PerformanceAlert] = []
        self.thresholds: Dict[str, Dict[str, float]] = {
            "cpu_usage": {"warning": 70.0, "critical": 90.0},
            "memory_usage": {"warning": 80.0, "critical": 95.0},
            "disk_usage": {"warning": 85.0, "critical": 95.0},
            "network_io": {"warning": 100.0, "critical": 200.0},  # MB/s
            "disk_io": {"warning": 50.0, "critical": 100.0},  # MB/s
            "response_time": {"warning": 1000.0, "critical": 5000.0},  # ms
            "error_rate": {"warning": 5.0, "critical": 10.0}  # %
        }
    
    def check_thresholds(self, metrics: List[PerformanceMetric]):
        """Check metrics against thresholds and generate alerts"""
        current_time = time.time()
        
        for metric in metrics:
            threshold_key = metric.metric_type.value
            
            if threshold_key in self.thresholds:
                thresholds = self.thresholds[threshold_key]
                
                # Check critical threshold
                if metric.value >= thresholds.get("critical", float('inf')):
                    self._create_alert(
                        timestamp=current_time,
                        alert_type="critical_threshold_exceeded",
                        severity="critical",
                        message=f"{metric.metric_type.value} exceeded critical threshold: {metric.value}{metric.unit}",
                        metric_value=metric.value,
                        threshold=thresholds["critical"],
                        component=metric.metric_type.value
                    )
                
                # Check warning threshold
                elif metric.value >= thresholds.get("warning", float('inf')):
                    self._create_alert(
                        timestamp=current_time,
                        alert_type="warning_threshold_exceeded",
                        severity="warning",
                        message=f"{metric.metric_type.value} exceeded warning threshold: {metric.value}{metric.unit}",
                        metric_value=metric.value,
                        threshold=thresholds["warning"],
                        component=metric.metric_type.value
                    )
    
    def _create_alert(self, timestamp: float, alert_type: str, severity: str, message: str, metric_value: float, threshold: float, component: str = ""):
        """Create a new performance alert"""
        alert = PerformanceAlert(
            timestamp=timestamp,
            alert_type=alert_type,
            severity=severity,
            message=message,
            metric_value=metric_value,
            threshold=threshold,
            component=component
        )
        
        self.alerts.append(alert)
        
        # Log the alert
        log_level = logging.ERROR if severity == "critical" else logging.WARNING
        self.performance_monitor.logger.log(log_level, f"Performance Alert: {message}")
    
    def get_active_alerts(self, severity: Optional[str] = None) -> List[PerformanceAlert]:
        """Get active (unresolved) alerts"""
        alerts = [a for a in self.alerts if not a.resolved]
        if severity:
            alerts = [a for a in alerts if a.severity == severity]
        return alerts
    
    def resolve_alert(self, alert_index: int) -> bool:
        """Mark an alert as resolved"""
        try:
            if 0 <= alert_index < len(self.alerts):
                self.alerts[alert_index].resolved = True
                return True
            return False
        except Exception as e:
            self.performance_monitor.logger.error(f"Failed to resolve alert: {e}")
            return False

class OptimizationEngine:
    """Provides performance optimization recommendations"""
    
    def __init__(self, performance_monitor: 'PerformanceMonitor'):
        self.performance_monitor = performance_monitor
        self.recommendations: List[Dict[str, Any]] = []
    
    def analyze_performance(self, metrics: List[PerformanceMetric]) -> List[Dict[str, Any]]:
        """Analyze performance metrics and generate recommendations"""
        recommendations = []
        
        # Analyze CPU usage
        cpu_metrics = [m for m in metrics if m.metric_type == MetricType.CPU_USAGE]
        if cpu_metrics:
            avg_cpu = statistics.mean([m.value for m in cpu_metrics])
            if avg_cpu > 80:
                recommendations.append({
                    "type": "cpu_optimization",
                    "priority": "high",
                    "title": "High CPU Usage Detected",
                    "description": f"Average CPU usage is {avg_cpu:.1f}%. Consider optimizing CPU-intensive operations.",
                    "suggestions": [
                        "Review and optimize CPU-intensive modules",
                        "Consider implementing caching strategies",
                        "Check for unnecessary background processes"
                    ]
                })
        
        # Analyze memory usage
        memory_metrics = [m for m in metrics if m.metric_type == MetricType.MEMORY_USAGE]
        if memory_metrics:
            avg_memory = statistics.mean([m.value for m in memory_metrics])
            if avg_memory > 85:
                recommendations.append({
                    "type": "memory_optimization",
                    "priority": "high",
                    "title": "High Memory Usage Detected",
                    "description": f"Average memory usage is {avg_memory:.1f}%. Consider memory optimization.",
                    "suggestions": [
                        "Review memory usage by modules",
                        "Implement memory pooling",
                        "Check for memory leaks"
                    ]
                })
        
        # Analyze disk usage
        disk_metrics = [m for m in metrics if m.metric_type == MetricType.DISK_USAGE]
        if disk_metrics:
            avg_disk = statistics.mean([m.value for m in disk_metrics])
            if avg_disk > 90:
                recommendations.append({
                    "type": "disk_optimization",
                    "priority": "critical",
                    "title": "Critical Disk Usage",
                    "description": f"Average disk usage is {avg_disk:.1f}%. Immediate action required.",
                    "suggestions": [
                        "Clean up unnecessary files",
                        "Implement log rotation",
                        "Consider disk expansion"
                    ]
                })
        
        # Analyze network performance
        network_metrics = [m for m in metrics if m.metric_type == MetricType.NETWORK_IO]
        if network_metrics:
            avg_network = statistics.mean([m.value for m in network_metrics])
            if avg_network > 100:
                recommendations.append({
                    "type": "network_optimization",
                    "priority": "medium",
                    "title": "High Network Usage",
                    "description": f"Average network I/O is {avg_network:.1f} MB/s. Consider network optimization.",
                    "suggestions": [
                        "Implement data compression",
                        "Review network-intensive operations",
                        "Consider caching frequently accessed data"
                    ]
                })
        
        self.recommendations = recommendations
        return recommendations
    
    def get_recommendations(self) -> List[Dict[str, Any]]:
        """Get current optimization recommendations"""
        return self.recommendations.copy()

class PerformanceMonitor:
    """
    LilithOS Performance Monitor
    
    Monitors and optimizes system performance:
    - Real-time metric collection
    - Performance alerting
    - Optimization recommendations
    - Resource usage tracking
    - Performance reporting
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("PerformanceMonitor")
        self.collector = MetricCollector(self)
        self.alert_manager = AlertManager(self)
        self.optimization_engine = OptimizationEngine(self)
        self.monitoring_enabled = True
        self.optimization_enabled = True
        self.collection_task = None
        self.system_resources = SystemResources()
        
        # Performance history
        self.performance_history: Dict[str, List[float]] = {}
        self.history_retention_hours = 24
    
    async def start(self) -> bool:
        """Start performance monitoring"""
        try:
            self.logger.info("Starting Performance Monitor...")
            
            # Initialize system resources
            self._update_system_resources()
            
            # Start metric collection
            self.collection_task = asyncio.create_task(self.collector.start_collection())
            
            # Start performance analysis
            asyncio.create_task(self._performance_analysis_loop())
            
            self.logger.info("Performance Monitor started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start Performance Monitor: {e}")
            return False
    
    async def stop(self) -> bool:
        """Stop performance monitoring"""
        try:
            self.logger.info("Stopping Performance Monitor...")
            
            if self.collection_task:
                self.collection_task.cancel()
                try:
                    await self.collection_task
                except asyncio.CancelledError:
                    pass
            
            self.logger.info("Performance Monitor stopped successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to stop Performance Monitor: {e}")
            return False
    
    def _update_system_resources(self):
        """Update system resources information"""
        try:
            # CPU information
            self.system_resources.cpu_count = psutil.cpu_count()
            self.system_resources.cpu_usage_percent = psutil.cpu_percent()
            
            # Memory information
            memory = psutil.virtual_memory()
            self.system_resources.memory_total = memory.total
            self.system_resources.memory_available = memory.available
            self.system_resources.memory_used = memory.used
            self.system_resources.memory_percent = memory.percent
            
            # Disk information
            disk = psutil.disk_usage('/')
            self.system_resources.disk_total = disk.total
            self.system_resources.disk_used = disk.used
            self.system_resources.disk_free = disk.free
            self.system_resources.disk_percent = (disk.used / disk.total) * 100
            
            # Network information
            network = psutil.net_io_counters()
            self.system_resources.network_bytes_sent = network.bytes_sent
            self.system_resources.network_bytes_recv = network.bytes_recv
            
            # Process information
            self.system_resources.process_count = len(psutil.pids())
            self.system_resources.thread_count = self.system_resources.cpu_count * 2
            
        except Exception as e:
            self.logger.error(f"Failed to update system resources: {e}")
    
    async def _performance_analysis_loop(self):
        """Performance analysis loop"""
        while self.monitoring_enabled:
            try:
                # Get recent metrics
                recent_metrics = self.collector.get_recent_metrics(minutes=5)
                
                # Check thresholds and generate alerts
                self.alert_manager.check_thresholds(recent_metrics)
                
                # Generate optimization recommendations
                if self.optimization_enabled:
                    self.optimization_engine.analyze_performance(recent_metrics)
                
                # Update performance history
                self._update_performance_history(recent_metrics)
                
                # Update system resources
                self._update_system_resources()
                
                await asyncio.sleep(60)  # Run every minute
                
            except Exception as e:
                self.logger.error(f"Performance analysis error: {e}")
                await asyncio.sleep(30)
    
    def _update_performance_history(self, metrics: List[PerformanceMetric]):
        """Update performance history"""
        current_time = time.time()
        cutoff_time = current_time - (self.history_retention_hours * 3600)
        
        for metric in metrics:
            metric_key = metric.metric_type.value
            
            if metric_key not in self.performance_history:
                self.performance_history[metric_key] = []
            
            self.performance_history[metric_key].append(metric.value)
            
            # Remove old data
            self.performance_history[metric_key] = [
                v for v in self.performance_history[metric_key]
                if v >= cutoff_time
            ]
    
    def get_current_metrics(self) -> Dict[str, Any]:
        """Get current performance metrics"""
        recent_metrics = self.collector.get_recent_metrics(minutes=1)
        
        metrics_dict = {}
        for metric in recent_metrics:
            metric_key = metric.metric_type.value
            if metric_key not in metrics_dict:
                metrics_dict[metric_key] = []
            metrics_dict[metric_key].append({
                "value": metric.value,
                "unit": metric.unit,
                "timestamp": metric.timestamp,
                "tags": metric.tags
            })
        
        return metrics_dict
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Get performance statistics"""
        stats = {
            "system_resources": self.system_resources.__dict__,
            "active_alerts": len(self.alert_manager.get_active_alerts()),
            "critical_alerts": len(self.alert_manager.get_active_alerts("critical")),
            "warning_alerts": len(self.alert_manager.get_active_alerts("warning")),
            "optimization_recommendations": len(self.optimization_engine.get_recommendations()),
            "metrics_collected": len(self.collector.metrics_buffer)
        }
        
        # Add average metrics
        for metric_type in MetricType:
            metrics = self.collector.get_recent_metrics(metric_type, minutes=5)
            if metrics:
                avg_value = statistics.mean([m.value for m in metrics])
                stats[f"avg_{metric_type.value}"] = avg_value
        
        return stats
    
    def get_alerts(self, severity: Optional[str] = None, resolved: bool = False) -> List[PerformanceAlert]:
        """Get performance alerts"""
        alerts = [a for a in self.alert_manager.alerts if a.resolved == resolved]
        if severity:
            alerts = [a for a in alerts if a.severity == severity]
        return alerts
    
    def get_recommendations(self) -> List[Dict[str, Any]]:
        """Get optimization recommendations"""
        return self.optimization_engine.get_recommendations()
    
    def add_custom_metric(self, metric_type: MetricType, value: float, unit: str = "", tags: Dict[str, str] = None):
        """Add a custom performance metric"""
        self.collector._add_metric(time.time(), metric_type, value, unit, tags)
    
    async def run_maintenance(self) -> bool:
        """Run performance maintenance tasks"""
        try:
            # Clean up old metrics
            cutoff_time = time.time() - (self.history_retention_hours * 3600)
            
            for metric_key in list(self.performance_history.keys()):
                self.performance_history[metric_key] = [
                    v for v in self.performance_history[metric_key]
                    if v >= cutoff_time
                ]
            
            # Resolve old alerts
            current_time = time.time()
            for alert in self.alert_manager.alerts:
                if not alert.resolved and (current_time - alert.timestamp) > 3600:  # 1 hour
                    alert.resolved = True
            
            self.logger.info("Performance maintenance completed")
            return True
            
        except Exception as e:
            self.logger.error(f"Performance maintenance failed: {e}")
            return False 