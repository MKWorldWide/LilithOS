"""
LilithOS Network Manager
=======================

Handles network connectivity and communication:
- Network interface management
- Connection pooling and optimization
- Protocol handling (HTTP, WebSocket, TCP/UDP)
- Network monitoring and diagnostics
- Load balancing and failover
"""

import os
import asyncio
import aiohttp
import websockets
import socket
import ssl
import logging
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple, Callable
from dataclasses import dataclass, field
from enum import Enum
import json
import yaml
from urllib.parse import urlparse
import ipaddress

class ConnectionType(Enum):
    """Network connection types"""
    HTTP = "http"
    HTTPS = "https"
    WEBSOCKET = "websocket"
    TCP = "tcp"
    UDP = "udp"
    FTP = "ftp"
    SSH = "ssh"

class ConnectionStatus(Enum):
    """Connection status enumeration"""
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    ERROR = "error"
    TIMEOUT = "timeout"

@dataclass
class NetworkInterface:
    """Network interface information"""
    name: str
    address: str
    netmask: str
    broadcast: str
    mtu: int
    is_up: bool
    is_loopback: bool
    speed: Optional[int] = None

@dataclass
class Connection:
    """Network connection information"""
    id: str
    connection_type: ConnectionType
    host: str
    port: int
    status: ConnectionStatus
    created_at: float
    last_used: float
    timeout: float
    retry_count: int = 0
    max_retries: int = 3
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class NetworkStats:
    """Network statistics"""
    bytes_sent: int = 0
    bytes_received: int = 0
    packets_sent: int = 0
    packets_received: int = 0
    errors: int = 0
    dropped: int = 0
    active_connections: int = 0
    connection_attempts: int = 0
    successful_connections: int = 0
    failed_connections: int = 0

class ConnectionPool:
    """Manages a pool of network connections"""
    
    def __init__(self, network_manager: 'NetworkManager', max_connections: int = 10):
        self.network_manager = network_manager
        self.max_connections = max_connections
        self.connections: Dict[str, Connection] = {}
        self.available_connections: List[str] = []
        self.in_use_connections: List[str] = []
        self.lock = threading.RLock()
        self.session = None
    
    async def initialize(self):
        """Initialize the connection pool"""
        try:
            # Create aiohttp session for HTTP connections
            connector = aiohttp.TCPConnector(
                limit=self.max_connections,
                limit_per_host=5,
                ttl_dns_cache=300,
                use_dns_cache=True
            )
            
            timeout = aiohttp.ClientTimeout(total=30, connect=10)
            self.session = aiohttp.ClientSession(
                connector=connector,
                timeout=timeout
            )
            
            self.network_manager.logger.info("Connection pool initialized successfully")
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to initialize connection pool: {e}")
    
    async def cleanup(self):
        """Cleanup connection pool resources"""
        try:
            if self.session:
                await self.session.close()
            
            # Close all connections
            for conn_id in list(self.connections.keys()):
                await self._close_connection(conn_id)
            
            self.network_manager.logger.info("Connection pool cleaned up successfully")
            
        except Exception as e:
            self.network_manager.logger.error(f"Connection pool cleanup failed: {e}")
    
    async def get_connection(self, connection_type: ConnectionType, host: str, port: int, timeout: float = 30.0) -> Optional[Connection]:
        """Get a connection from the pool or create a new one"""
        try:
            conn_id = f"{connection_type.value}_{host}_{port}"
            
            with self.lock:
                # Check if connection already exists and is available
                if conn_id in self.connections:
                    conn = self.connections[conn_id]
                    if conn.status == ConnectionStatus.CONNECTED and conn_id in self.available_connections:
                        self.available_connections.remove(conn_id)
                        self.in_use_connections.append(conn_id)
                        conn.last_used = time.time()
                        return conn
                
                # Create new connection if pool not full
                if len(self.connections) < self.max_connections:
                    conn = await self._create_connection(connection_type, host, port, timeout)
                    if conn:
                        self.connections[conn_id] = conn
                        self.in_use_connections.append(conn_id)
                        return conn
                
                # Wait for available connection
                return await self._wait_for_connection(conn_id)
                
        except Exception as e:
            self.network_manager.logger.error(f"Failed to get connection: {e}")
            return None
    
    async def release_connection(self, conn_id: str):
        """Release a connection back to the pool"""
        try:
            with self.lock:
                if conn_id in self.in_use_connections:
                    self.in_use_connections.remove(conn_id)
                    self.available_connections.append(conn_id)
                    
                    if conn_id in self.connections:
                        self.connections[conn_id].last_used = time.time()
                
        except Exception as e:
            self.network_manager.logger.error(f"Failed to release connection: {e}")
    
    async def _create_connection(self, connection_type: ConnectionType, host: str, port: int, timeout: float) -> Optional[Connection]:
        """Create a new network connection"""
        try:
            conn_id = f"{connection_type.value}_{host}_{port}"
            
            # Test connection
            if connection_type in [ConnectionType.HTTP, ConnectionType.HTTPS]:
                success = await self._test_http_connection(host, port, connection_type == ConnectionType.HTTPS)
            elif connection_type == ConnectionType.WEBSOCKET:
                success = await self._test_websocket_connection(host, port)
            else:
                success = await self._test_tcp_connection(host, port)
            
            if success:
                connection = Connection(
                    id=conn_id,
                    connection_type=connection_type,
                    host=host,
                    port=port,
                    status=ConnectionStatus.CONNECTED,
                    created_at=time.time(),
                    last_used=time.time(),
                    timeout=timeout
                )
                
                self.network_manager.logger.info(f"Created connection {conn_id}")
                return connection
            else:
                self.network_manager.logger.error(f"Failed to create connection {conn_id}")
                return None
                
        except Exception as e:
            self.network_manager.logger.error(f"Connection creation failed: {e}")
            return None
    
    async def _test_http_connection(self, host: str, port: int, use_ssl: bool) -> bool:
        """Test HTTP/HTTPS connection"""
        try:
            protocol = "https" if use_ssl else "http"
            url = f"{protocol}://{host}:{port}"
            
            async with self.session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
                return response.status < 500
                
        except Exception:
            return False
    
    async def _test_websocket_connection(self, host: str, port: int) -> bool:
        """Test WebSocket connection"""
        try:
            uri = f"ws://{host}:{port}"
            async with websockets.connect(uri, timeout=10) as websocket:
                return True
        except Exception:
            return False
    
    async def _test_tcp_connection(self, host: str, port: int) -> bool:
        """Test TCP connection"""
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port),
                timeout=10
            )
            writer.close()
            await writer.wait_closed()
            return True
        except Exception:
            return False
    
    async def _wait_for_connection(self, conn_id: str) -> Optional[Connection]:
        """Wait for an available connection"""
        max_wait = 30  # 30 seconds
        start_time = time.time()
        
        while time.time() - start_time < max_wait:
            with self.lock:
                if conn_id in self.available_connections:
                    self.available_connections.remove(conn_id)
                    self.in_use_connections.append(conn_id)
                    return self.connections[conn_id]
            
            await asyncio.sleep(1)
        
        return None
    
    async def _close_connection(self, conn_id: str):
        """Close a connection"""
        try:
            if conn_id in self.connections:
                conn = self.connections[conn_id]
                conn.status = ConnectionStatus.DISCONNECTED
                del self.connections[conn_id]
                
                if conn_id in self.available_connections:
                    self.available_connections.remove(conn_id)
                if conn_id in self.in_use_connections:
                    self.in_use_connections.remove(conn_id)
                
        except Exception as e:
            self.network_manager.logger.error(f"Failed to close connection {conn_id}: {e}")

class NetworkMonitor:
    """Monitors network interfaces and connections"""
    
    def __init__(self, network_manager: 'NetworkManager'):
        self.network_manager = network_manager
        self.interfaces: Dict[str, NetworkInterface] = {}
        self.stats = NetworkStats()
        self.monitoring_enabled = True
    
    async def start_monitoring(self):
        """Start network monitoring"""
        try:
            self.network_manager.logger.info("Starting network monitoring...")
            
            # Discover network interfaces
            await self._discover_interfaces()
            
            # Start monitoring loop
            asyncio.create_task(self._monitoring_loop())
            
            self.network_manager.logger.info("Network monitoring started successfully")
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to start network monitoring: {e}")
    
    async def _discover_interfaces(self):
        """Discover network interfaces"""
        try:
            import psutil
            
            for interface_name, interface_info in psutil.net_if_addrs().items():
                for addr_info in interface_info:
                    if addr_info.family == socket.AF_INET:  # IPv4
                        interface = NetworkInterface(
                            name=interface_name,
                            address=addr_info.address,
                            netmask=addr_info.netmask,
                            broadcast=addr_info.broadcast or "",
                            mtu=psutil.net_if_stats().get(interface_name, {}).get('mtu', 1500),
                            is_up=psutil.net_if_stats().get(interface_name, {}).get('isup', False),
                            is_loopback=interface_name.startswith('lo')
                        )
                        self.interfaces[interface_name] = interface
                        break
            
            self.network_manager.logger.info(f"Discovered {len(self.interfaces)} network interfaces")
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to discover network interfaces: {e}")
    
    async def _monitoring_loop(self):
        """Network monitoring loop"""
        while self.monitoring_enabled:
            try:
                # Update network statistics
                await self._update_network_stats()
                
                # Check interface status
                await self._check_interface_status()
                
                # Update connection statistics
                await self._update_connection_stats()
                
                await asyncio.sleep(30)  # Run every 30 seconds
                
            except Exception as e:
                self.network_manager.logger.error(f"Network monitoring error: {e}")
                await asyncio.sleep(60)
    
    async def _update_network_stats(self):
        """Update network statistics"""
        try:
            import psutil
            
            net_io = psutil.net_io_counters()
            self.stats.bytes_sent = net_io.bytes_sent
            self.stats.bytes_received = net_io.bytes_recv
            self.stats.packets_sent = net_io.packets_sent
            self.stats.packets_received = net_io.packets_recv
            self.stats.errors = net_io.errin + net_io.errout
            self.stats.dropped = net_io.dropin + net_io.dropout
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to update network stats: {e}")
    
    async def _check_interface_status(self):
        """Check network interface status"""
        try:
            import psutil
            
            for interface_name in list(self.interfaces.keys()):
                if interface_name in psutil.net_if_stats():
                    stats = psutil.net_if_stats()[interface_name]
                    self.interfaces[interface_name].is_up = stats.isup
                    self.interfaces[interface_name].mtu = stats.mtu
                else:
                    # Interface no longer exists
                    del self.interfaces[interface_name]
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to check interface status: {e}")
    
    async def _update_connection_stats(self):
        """Update connection statistics"""
        try:
            pool = self.network_manager.connection_pool
            self.stats.active_connections = len(pool.connections)
            
        except Exception as e:
            self.network_manager.logger.error(f"Failed to update connection stats: {e}")
    
    def get_interface_info(self, interface_name: str) -> Optional[NetworkInterface]:
        """Get information about a network interface"""
        return self.interfaces.get(interface_name)
    
    def list_interfaces(self) -> List[NetworkInterface]:
        """List all network interfaces"""
        return list(self.interfaces.values())
    
    def get_network_stats(self) -> NetworkStats:
        """Get current network statistics"""
        return self.stats

class NetworkManager:
    """
    LilithOS Network Manager
    
    Manages network connectivity and communication:
    - Connection pooling and optimization
    - Network interface monitoring
    - Protocol handling
    - Network diagnostics and troubleshooting
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("NetworkManager")
        self.connection_pool = ConnectionPool(self)
        self.monitor = NetworkMonitor(self)
        self.initialized = False
        
        # Network configuration
        self.default_timeout = 30.0
        self.max_retries = 3
        self.retry_delay = 1.0
    
    async def initialize(self) -> bool:
        """Initialize the network manager"""
        try:
            self.logger.info("Initializing Network Manager...")
            
            # Initialize connection pool
            await self.connection_pool.initialize()
            
            # Start network monitoring
            await self.monitor.start_monitoring()
            
            self.initialized = True
            self.logger.info("Network Manager initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Network Manager: {e}")
            return False
    
    async def cleanup(self):
        """Cleanup network manager resources"""
        try:
            self.logger.info("Cleaning up Network Manager...")
            
            # Stop monitoring
            self.monitor.monitoring_enabled = False
            
            # Cleanup connection pool
            await self.connection_pool.cleanup()
            
            self.logger.info("Network Manager cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Network Manager cleanup failed: {e}")
    
    async def make_request(self, method: str, url: str, **kwargs) -> Optional[aiohttp.ClientResponse]:
        """Make an HTTP request"""
        try:
            if not self.initialized:
                self.logger.error("Network Manager not initialized")
                return None
            
            parsed_url = urlparse(url)
            connection_type = ConnectionType.HTTPS if parsed_url.scheme == 'https' else ConnectionType.HTTP
            
            # Get connection from pool
            conn = await self.connection_pool.get_connection(
                connection_type,
                parsed_url.hostname,
                parsed_url.port or (443 if connection_type == ConnectionType.HTTPS else 80)
            )
            
            if not conn:
                self.logger.error(f"Failed to get connection for {url}")
                return None
            
            try:
                # Make request
                async with self.connection_pool.session.request(method, url, **kwargs) as response:
                    return response
            finally:
                # Release connection back to pool
                await self.connection_pool.release_connection(conn.id)
                
        except Exception as e:
            self.logger.error(f"Request failed: {e}")
            return None
    
    async def get(self, url: str, **kwargs) -> Optional[aiohttp.ClientResponse]:
        """Make a GET request"""
        return await self.make_request('GET', url, **kwargs)
    
    async def post(self, url: str, **kwargs) -> Optional[aiohttp.ClientResponse]:
        """Make a POST request"""
        return await self.make_request('POST', url, **kwargs)
    
    async def websocket_connect(self, url: str) -> Optional[websockets.WebSocketServerProtocol]:
        """Connect to a WebSocket server"""
        try:
            parsed_url = urlparse(url)
            conn = await self.connection_pool.get_connection(
                ConnectionType.WEBSOCKET,
                parsed_url.hostname,
                parsed_url.port or 80
            )
            
            if not conn:
                return None
            
            websocket = await websockets.connect(url)
            return websocket
            
        except Exception as e:
            self.logger.error(f"WebSocket connection failed: {e}")
            return None
    
    async def tcp_connect(self, host: str, port: int) -> Optional[Tuple[asyncio.StreamReader, asyncio.StreamWriter]]:
        """Connect to a TCP server"""
        try:
            conn = await self.connection_pool.get_connection(ConnectionType.TCP, host, port)
            
            if not conn:
                return None
            
            reader, writer = await asyncio.open_connection(host, port)
            return reader, writer
            
        except Exception as e:
            self.logger.error(f"TCP connection failed: {e}")
            return None
    
    def get_network_info(self) -> Dict[str, Any]:
        """Get network information"""
        return {
            "interfaces": [interface.__dict__ for interface in self.monitor.list_interfaces()],
            "stats": self.monitor.get_network_stats().__dict__,
            "connection_pool": {
                "total_connections": len(self.connection_pool.connections),
                "available_connections": len(self.connection_pool.available_connections),
                "in_use_connections": len(self.connection_pool.in_use_connections),
                "max_connections": self.connection_pool.max_connections
            }
        }
    
    async def test_connectivity(self, host: str, port: int = 80) -> bool:
        """Test network connectivity to a host"""
        try:
            conn = await self.connection_pool.get_connection(ConnectionType.TCP, host, port)
            if conn:
                await self.connection_pool.release_connection(conn.id)
                return True
            return False
        except Exception:
            return False
    
    async def run_maintenance(self) -> bool:
        """Run network maintenance tasks"""
        try:
            # Clean up old connections
            current_time = time.time()
            old_connections = []
            
            for conn_id, conn in self.connection_pool.connections.items():
                if current_time - conn.last_used > 300:  # 5 minutes
                    old_connections.append(conn_id)
            
            for conn_id in old_connections:
                await self.connection_pool._close_connection(conn_id)
            
            if old_connections:
                self.logger.info(f"Cleaned up {len(old_connections)} old connections")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Network maintenance failed: {e}")
            return False 