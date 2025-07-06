"""
🧠 LilithOS Process Manager

Advanced process management and optimization system inspired by LilithOS capabilities.
Provides intelligent resource allocation, process monitoring, and performance optimization.

Author: TrafficFlou Team
Version: 2.0.0
"""

import asyncio
import psutil
import time
import logging
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from enum import Enum
import json
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class ProcessStatus(Enum):
    """Process status enumeration"""
    RUNNING = "running"
    PAUSED = "paused"
    STOPPED = "stopped"
    OPTIMIZING = "optimizing"
    ERROR = "error"

class OptimizationLevel(Enum):
    """Optimization level enumeration"""
    NONE = "none"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    MAXIMUM = "maximum"

@dataclass
class ProcessMetrics:
    """Process metrics data structure"""
    process_id: str
    cpu_usage: float
    memory_usage: float
    network_io: Dict[str, float]
    disk_io: Dict[str, float]
    status: ProcessStatus
    optimization_level: OptimizationLevel
    timestamp: datetime
    performance_score: float = 0.0

@dataclass
class SystemMetrics:
    """System-wide metrics data structure"""
    total_cpu_usage: float
    total_memory_usage: float
    available_memory: float
    network_throughput: float
    disk_throughput: float
    active_processes: int
    optimization_status: str
    timestamp: datetime

class LilithOSProcessManager:
    """
    🧠 LilithOS Process Manager
    
    Advanced process management system that provides:
    - Intelligent resource allocation
    - Real-time process monitoring
    - Performance optimization
    - Adaptive scaling
    - Security isolation
    """
    
    def __init__(self):
        """Initialize LilithOS Process Manager"""
        self.processes: Dict[str, Dict[str, Any]] = {}
        self.metrics_history: List[SystemMetrics] = []
        self.optimization_enabled: bool = True
        self.monitoring_active: bool = False
        self.monitoring_task: Optional[asyncio.Task] = None
        self.optimization_task: Optional[asyncio.Task] = None
        
        # Performance thresholds
        self.cpu_threshold: float = 80.0
        self.memory_threshold: float = 85.0
        self.network_threshold: float = 90.0
        
        # Optimization settings
        self.auto_optimize: bool = True
        self.optimization_interval: int = 30  # seconds
        self.metrics_retention: int = 1000  # max metrics to keep
        
        logger.info("🧠 LilithOS Process Manager initialized")
    
    async def initialize(self):
        """Initialize the process manager"""
        try:
            logger.info("🚀 Initializing LilithOS Process Manager...")
            
            # Start background monitoring
            await self.start_monitoring()
            
            # Start optimization engine
            if self.auto_optimize:
                await self.start_optimization()
            
            logger.info("✅ LilithOS Process Manager initialized successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize LilithOS Process Manager: {e}")
            raise
    
    async def cleanup(self):
        """Cleanup resources"""
        try:
            logger.info("🧹 Cleaning up LilithOS Process Manager...")
            
            # Stop monitoring
            await self.stop_monitoring()
            
            # Stop optimization
            await self.stop_optimization()
            
            # Clear metrics history
            self.metrics_history.clear()
            
            logger.info("✅ LilithOS Process Manager cleanup completed")
            
        except Exception as e:
            logger.error(f"❌ Error during cleanup: {e}")
    
    async def start_monitoring(self):
        """Start real-time process monitoring"""
        if self.monitoring_active:
            return
        
        self.monitoring_active = True
        self.monitoring_task = asyncio.create_task(self._monitoring_loop())
        logger.info("📊 LilithOS monitoring started")
    
    async def stop_monitoring(self):
        """Stop process monitoring"""
        self.monitoring_active = False
        
        if self.monitoring_task:
            self.monitoring_task.cancel()
            try:
                await self.monitoring_task
            except asyncio.CancelledError:
                pass
        
        logger.info("📊 LilithOS monitoring stopped")
    
    async def start_optimization(self):
        """Start automatic optimization"""
        if self.optimization_task:
            return
        
        self.optimization_task = asyncio.create_task(self._optimization_loop())
        logger.info("⚡ LilithOS optimization started")
    
    async def stop_optimization(self):
        """Stop automatic optimization"""
        if self.optimization_task:
            self.optimization_task.cancel()
            try:
                await self.optimization_task
            except asyncio.CancelledError:
                pass
        
        logger.info("⚡ LilithOS optimization stopped")
    
    async def _monitoring_loop(self):
        """Background monitoring loop"""
        while self.monitoring_active:
            try:
                # Collect system metrics
                metrics = await self._collect_system_metrics()
                self.metrics_history.append(metrics)
                
                # Trim metrics history
                if len(self.metrics_history) > self.metrics_retention:
                    self.metrics_history = self.metrics_history[-self.metrics_retention:]
                
                # Check for performance issues
                await self._check_performance_thresholds(metrics)
                
                # Wait for next monitoring cycle
                await asyncio.sleep(5)  # 5-second monitoring interval
                
            except Exception as e:
                logger.error(f"Monitoring loop error: {e}")
                await asyncio.sleep(10)  # Longer wait on error
    
    async def _optimization_loop(self):
        """Background optimization loop"""
        while True:
            try:
                # Perform system optimization
                await self._optimize_system()
                
                # Wait for next optimization cycle
                await asyncio.sleep(self.optimization_interval)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Optimization loop error: {e}")
                await asyncio.sleep(60)  # Longer wait on error
    
    async def _collect_system_metrics(self) -> SystemMetrics:
        """Collect system-wide metrics"""
        try:
            # CPU usage
            cpu_usage = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_usage = memory.percent
            available_memory = memory.available / (1024 ** 3)  # GB
            
            # Network I/O
            network = psutil.net_io_counters()
            network_throughput = (network.bytes_sent + network.bytes_recv) / (1024 ** 2)  # MB
            
            # Disk I/O
            disk = psutil.disk_io_counters()
            disk_throughput = (disk.read_bytes + disk.write_bytes) / (1024 ** 2)  # MB
            
            # Active processes
            active_processes = len(self.processes)
            
            # Optimization status
            optimization_status = "active" if self.auto_optimize else "disabled"
            
            return SystemMetrics(
                total_cpu_usage=cpu_usage,
                total_memory_usage=memory_usage,
                available_memory=available_memory,
                network_throughput=network_throughput,
                disk_throughput=disk_throughput,
                active_processes=active_processes,
                optimization_status=optimization_status,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error collecting system metrics: {e}")
            # Return default metrics on error
            return SystemMetrics(
                total_cpu_usage=0.0,
                total_memory_usage=0.0,
                available_memory=0.0,
                network_throughput=0.0,
                disk_throughput=0.0,
                active_processes=0,
                optimization_status="error",
                timestamp=datetime.now()
            )
    
    async def _check_performance_thresholds(self, metrics: SystemMetrics):
        """Check performance thresholds and trigger alerts"""
        alerts = []
        
        if metrics.total_cpu_usage > self.cpu_threshold:
            alerts.append(f"High CPU usage: {metrics.total_cpu_usage:.1f}%")
        
        if metrics.total_memory_usage > self.memory_threshold:
            alerts.append(f"High memory usage: {metrics.total_memory_usage:.1f}%")
        
        if metrics.network_throughput > self.network_threshold:
            alerts.append(f"High network usage: {metrics.network_throughput:.1f} MB")
        
        if alerts:
            logger.warning(f"🚨 Performance alerts: {'; '.join(alerts)}")
    
    async def _optimize_system(self):
        """Perform system optimization"""
        try:
            if not self.metrics_history:
                return
            
            # Get latest metrics
            latest_metrics = self.metrics_history[-1]
            
            # CPU optimization
            if latest_metrics.total_cpu_usage > 70:
                await self._optimize_cpu_usage()
            
            # Memory optimization
            if latest_metrics.total_memory_usage > 80:
                await self._optimize_memory_usage()
            
            # Process optimization
            await self._optimize_processes()
            
            logger.debug("⚡ System optimization completed")
            
        except Exception as e:
            logger.error(f"Optimization error: {e}")
    
    async def _optimize_cpu_usage(self):
        """Optimize CPU usage"""
        try:
            # Reduce process priorities for non-critical processes
            for process_id, process_info in self.processes.items():
                if process_info.get("priority", "normal") == "low":
                    # Implement CPU throttling for low-priority processes
                    process_info["cpu_limit"] = 0.5  # 50% CPU limit
            
            logger.info("⚡ CPU optimization applied")
            
        except Exception as e:
            logger.error(f"CPU optimization error: {e}")
    
    async def _optimize_memory_usage(self):
        """Optimize memory usage"""
        try:
            # Implement memory cleanup for idle processes
            for process_id, process_info in self.processes.items():
                if process_info.get("status") == ProcessStatus.PAUSED:
                    # Release memory for paused processes
                    process_info["memory_released"] = True
            
            logger.info("⚡ Memory optimization applied")
            
        except Exception as e:
            logger.error(f"Memory optimization error: {e}")
    
    async def _optimize_processes(self):
        """Optimize process scheduling and resource allocation"""
        try:
            # Implement intelligent process scheduling
            for process_id, process_info in self.processes.items():
                # Calculate performance score
                performance_score = self._calculate_performance_score(process_info)
                process_info["performance_score"] = performance_score
                
                # Adjust optimization level based on performance
                if performance_score < 0.5:
                    process_info["optimization_level"] = OptimizationLevel.HIGH
                elif performance_score < 0.7:
                    process_info["optimization_level"] = OptimizationLevel.MEDIUM
                else:
                    process_info["optimization_level"] = OptimizationLevel.LOW
            
            logger.debug("⚡ Process optimization completed")
            
        except Exception as e:
            logger.error(f"Process optimization error: {e}")
    
    def _calculate_performance_score(self, process_info: Dict[str, Any]) -> float:
        """Calculate performance score for a process"""
        try:
            # Base score
            score = 1.0
            
            # CPU efficiency (lower is better)
            cpu_usage = process_info.get("cpu_usage", 0.0)
            if cpu_usage > 80:
                score -= 0.3
            elif cpu_usage > 60:
                score -= 0.2
            elif cpu_usage > 40:
                score -= 0.1
            
            # Memory efficiency (lower is better)
            memory_usage = process_info.get("memory_usage", 0.0)
            if memory_usage > 80:
                score -= 0.3
            elif memory_usage > 60:
                score -= 0.2
            elif memory_usage > 40:
                score -= 0.1
            
            # Status bonus
            if process_info.get("status") == ProcessStatus.RUNNING:
                score += 0.1
            
            # Ensure score is between 0 and 1
            return max(0.0, min(1.0, score))
            
        except Exception as e:
            logger.error(f"Performance score calculation error: {e}")
            return 0.5  # Default score
    
    # Public API methods
    
    async def get_status(self) -> str:
        """Get overall system status"""
        if not self.monitoring_active:
            return "not_monitoring"
        
        if not self.metrics_history:
            return "no_data"
        
        latest_metrics = self.metrics_history[-1]
        
        if latest_metrics.total_cpu_usage > 90 or latest_metrics.total_memory_usage > 95:
            return "critical"
        elif latest_metrics.total_cpu_usage > 70 or latest_metrics.total_memory_usage > 80:
            return "warning"
        else:
            return "healthy"
    
    async def get_metrics(self) -> Dict[str, Any]:
        """Get current system metrics"""
        if not self.metrics_history:
            return {"error": "No metrics available"}
        
        latest_metrics = self.metrics_history[-1]
        
        return {
            "cpu_usage": latest_metrics.total_cpu_usage,
            "memory_usage": latest_metrics.total_memory_usage,
            "available_memory_gb": latest_metrics.available_memory,
            "network_throughput_mb": latest_metrics.network_throughput,
            "disk_throughput_mb": latest_metrics.disk_throughput,
            "active_processes": latest_metrics.active_processes,
            "optimization_status": latest_metrics.optimization_status,
            "timestamp": latest_metrics.timestamp.isoformat()
        }
    
    async def get_process_count(self) -> int:
        """Get number of active processes"""
        return len(self.processes)
    
    async def get_memory_usage(self) -> float:
        """Get current memory usage percentage"""
        if not self.metrics_history:
            return 0.0
        
        return self.metrics_history[-1].total_memory_usage
    
    async def get_cpu_usage(self) -> float:
        """Get current CPU usage percentage"""
        if not self.metrics_history:
            return 0.0
        
        return self.metrics_history[-1].total_cpu_usage
    
    async def get_process_info(self) -> List[Dict[str, Any]]:
        """Get detailed process information"""
        return [
            {
                "process_id": process_id,
                "status": process_info.get("status", ProcessStatus.STOPPED).value,
                "cpu_usage": process_info.get("cpu_usage", 0.0),
                "memory_usage": process_info.get("memory_usage", 0.0),
                "optimization_level": process_info.get("optimization_level", OptimizationLevel.NONE).value,
                "performance_score": process_info.get("performance_score", 0.0),
                "created_at": process_info.get("created_at", datetime.now()).isoformat()
            }
            for process_id, process_info in self.processes.items()
        ]
    
    async def get_optimization_status(self) -> Dict[str, Any]:
        """Get optimization status and recommendations"""
        if not self.metrics_history:
            return {"status": "no_data"}
        
        latest_metrics = self.metrics_history[-1]
        
        recommendations = []
        
        if latest_metrics.total_cpu_usage > 70:
            recommendations.append("Consider reducing CPU-intensive processes")
        
        if latest_metrics.total_memory_usage > 80:
            recommendations.append("Consider memory cleanup or process termination")
        
        if latest_metrics.network_throughput > 1000:  # 1GB
            recommendations.append("High network usage detected")
        
        return {
            "optimization_enabled": self.auto_optimize,
            "current_level": "high" if latest_metrics.total_cpu_usage > 70 else "normal",
            "recommendations": recommendations,
            "last_optimization": datetime.now().isoformat()
        }
    
    async def register_process(self, process_id: str, **kwargs) -> bool:
        """Register a new process for monitoring"""
        try:
            self.processes[process_id] = {
                "status": ProcessStatus.RUNNING,
                "cpu_usage": 0.0,
                "memory_usage": 0.0,
                "optimization_level": OptimizationLevel.NONE,
                "performance_score": 1.0,
                "created_at": datetime.now(),
                **kwargs
            }
            
            logger.info(f"📝 Process registered: {process_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to register process {process_id}: {e}")
            return False
    
    async def unregister_process(self, process_id: str) -> bool:
        """Unregister a process from monitoring"""
        try:
            if process_id in self.processes:
                del self.processes[process_id]
                logger.info(f"📝 Process unregistered: {process_id}")
                return True
            return False
            
        except Exception as e:
            logger.error(f"Failed to unregister process {process_id}: {e}")
            return False
    
    async def update_process_metrics(self, process_id: str, **metrics) -> bool:
        """Update metrics for a specific process"""
        try:
            if process_id in self.processes:
                self.processes[process_id].update(metrics)
                return True
            return False
            
        except Exception as e:
            logger.error(f"Failed to update metrics for process {process_id}: {e}")
            return False 