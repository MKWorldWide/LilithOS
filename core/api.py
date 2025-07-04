"""
LilithOS API Manager
===================

Handles REST API endpoints and request routing:
- API endpoint management
- Request/response handling
- Authentication and authorization
- API documentation generation
- Rate limiting and throttling
"""

import os
import asyncio
import logging
import threading
import time
import json
import inspect
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable, Union
from dataclasses import dataclass, field
from enum import Enum
from functools import wraps
import aiohttp
from aiohttp import web, ClientSession
from aiohttp_cors import setup as cors_setup, ResourceOptions

class HTTPMethod(Enum):
    """HTTP method enumeration"""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"
    OPTIONS = "OPTIONS"

class APIVersion(Enum):
    """API version enumeration"""
    V1 = "v1"
    V2 = "v2"

@dataclass
class APIEndpoint:
    """API endpoint information"""
    path: str
    method: HTTPMethod
    handler: Callable
    version: APIVersion = APIVersion.V1
    auth_required: bool = False
    rate_limit: Optional[int] = None
    description: str = ""
    parameters: Dict[str, Any] = field(default_factory=dict)
    responses: Dict[str, Any] = field(default_factory=dict)

@dataclass
class APIRequest:
    """API request information"""
    method: str
    path: str
    headers: Dict[str, str]
    query_params: Dict[str, str]
    body: Optional[Any] = None
    client_ip: str = ""
    user_agent: str = ""
    timestamp: float = field(default_factory=time.time)

@dataclass
class APIResponse:
    """API response information"""
    status: int
    data: Any
    headers: Dict[str, str] = field(default_factory=dict)
    timestamp: float = field(default_factory=time.time)

class RateLimiter:
    """Handles API rate limiting"""
    
    def __init__(self, api_manager: 'APIManager'):
        self.api_manager = api_manager
        self.requests: Dict[str, List[float]] = {}
        self.lock = threading.RLock()
    
    def is_allowed(self, client_id: str, limit: int, window: int = 60) -> bool:
        """Check if a request is allowed based on rate limit"""
        try:
            current_time = time.time()
            
            with self.lock:
                if client_id not in self.requests:
                    self.requests[client_id] = []
                
                # Remove old requests outside the window
                self.requests[client_id] = [
                    req_time for req_time in self.requests[client_id]
                    if current_time - req_time < window
                ]
                
                # Check if limit exceeded
                if len(self.requests[client_id]) >= limit:
                    return False
                
                # Add current request
                self.requests[client_id].append(current_time)
                return True
                
        except Exception as e:
            self.api_manager.logger.error(f"Rate limiting error: {e}")
            return True  # Allow request on error
    
    def get_remaining_requests(self, client_id: str, limit: int, window: int = 60) -> int:
        """Get remaining requests for a client"""
        try:
            current_time = time.time()
            
            with self.lock:
                if client_id not in self.requests:
                    return limit
                
                # Remove old requests
                self.requests[client_id] = [
                    req_time for req_time in self.requests[client_id]
                    if current_time - req_time < window
                ]
                
                return max(0, limit - len(self.requests[client_id]))
                
        except Exception as e:
            self.api_manager.logger.error(f"Rate limiting error: {e}")
            return 0

class APIAuthenticator:
    """Handles API authentication"""
    
    def __init__(self, api_manager: 'APIManager'):
        self.api_manager = api_manager
    
    async def authenticate_request(self, request: web.Request) -> Optional[str]:
        """Authenticate an API request"""
        try:
            # Check for API key in headers
            api_key = request.headers.get('X-API-Key')
            if api_key:
                # Validate API key
                if await self._validate_api_key(api_key):
                    return api_key
            
            # Check for session token
            session_token = request.headers.get('X-Session-Token')
            if session_token:
                # Validate session
                session = self.api_manager.core.security.auth.validate_session(session_token)
                if session:
                    return session["username"]
            
            # Check for Bearer token
            auth_header = request.headers.get('Authorization')
            if auth_header and auth_header.startswith('Bearer '):
                token = auth_header[7:]  # Remove 'Bearer ' prefix
                session = self.api_manager.core.security.auth.validate_session(token)
                if session:
                    return session["username"]
            
            return None
            
        except Exception as e:
            self.api_manager.logger.error(f"Authentication error: {e}")
            return None
    
    async def _validate_api_key(self, api_key: str) -> bool:
        """Validate an API key"""
        # TODO: Implement API key validation
        # For now, accept any non-empty key
        return bool(api_key and len(api_key) > 0)

class APIHandler:
    """Handles API request processing"""
    
    def __init__(self, api_manager: 'APIManager'):
        self.api_manager = api_manager
        self.authenticator = APIAuthenticator(api_manager)
        self.rate_limiter = RateLimiter(api_manager)
    
    async def handle_request(self, request: web.Request, endpoint: APIEndpoint) -> web.Response:
        """Handle an API request"""
        try:
            # Create API request object
            api_request = await self._create_api_request(request)
            
            # Rate limiting
            if endpoint.rate_limit:
                client_id = api_request.client_ip
                if not self.rate_limiter.is_allowed(client_id, endpoint.rate_limit):
                    return web.json_response(
                        {"error": "Rate limit exceeded"},
                        status=429
                    )
            
            # Authentication
            if endpoint.auth_required:
                user = await self.authenticator.authenticate_request(request)
                if not user:
                    return web.json_response(
                        {"error": "Authentication required"},
                        status=401
                    )
                api_request.headers['X-User'] = user
            
            # Process request
            try:
                if asyncio.iscoroutinefunction(endpoint.handler):
                    result = await endpoint.handler(request, api_request)
                else:
                    result = endpoint.handler(request, api_request)
                
                # Create response
                if isinstance(result, web.Response):
                    return result
                elif isinstance(result, dict):
                    return web.json_response(result)
                else:
                    return web.json_response({"data": result})
                    
            except Exception as e:
                self.api_manager.logger.error(f"Request handler error: {e}")
                return web.json_response(
                    {"error": "Internal server error"},
                    status=500
                )
                
        except Exception as e:
            self.api_manager.logger.error(f"Request processing error: {e}")
            return web.json_response(
                {"error": "Internal server error"},
                status=500
            )
    
    async def _create_api_request(self, request: web.Request) -> APIRequest:
        """Create an API request object from aiohttp request"""
        try:
            # Get client IP
            client_ip = request.headers.get('X-Forwarded-For', request.remote)
            if ',' in client_ip:
                client_ip = client_ip.split(',')[0].strip()
            
            # Get query parameters
            query_params = dict(request.query)
            
            # Get request body
            body = None
            if request.content_type == 'application/json':
                try:
                    body = await request.json()
                except:
                    body = await request.text()
            elif request.content_type == 'application/x-www-form-urlencoded':
                body = await request.post()
            else:
                body = await request.text()
            
            return APIRequest(
                method=request.method,
                path=str(request.path),
                headers=dict(request.headers),
                query_params=query_params,
                body=body,
                client_ip=client_ip,
                user_agent=request.headers.get('User-Agent', ''),
                timestamp=time.time()
            )
            
        except Exception as e:
            self.api_manager.logger.error(f"Failed to create API request: {e}")
            return APIRequest(
                method=request.method,
                path=str(request.path),
                headers={},
                query_params={},
                body=None
            )

class APIManager:
    """
    LilithOS API Manager
    
    Manages REST API endpoints and request routing:
    - Endpoint registration and management
    - Request/response handling
    - Authentication and authorization
    - Rate limiting and throttling
    - API documentation generation
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("APIManager")
        self.app = web.Application()
        self.handler = APIHandler(self)
        self.endpoints: Dict[str, APIEndpoint] = {}
        self.server = None
        self.port = 8080
        self.host = "localhost"
        
        # Setup CORS
        cors = cors_setup(self.app, defaults={
            "*": ResourceOptions(
                allow_credentials=True,
                expose_headers="*",
                allow_headers="*",
                allow_methods="*"
            )
        })
        
        # Register default endpoints
        self._register_default_endpoints()
    
    def _register_default_endpoints(self):
        """Register default API endpoints"""
        # Health check
        self.register_endpoint(
            path="/health",
            method=HTTPMethod.GET,
            handler=self._health_check,
            description="Health check endpoint"
        )
        
        # API documentation
        self.register_endpoint(
            path="/docs",
            method=HTTPMethod.GET,
            handler=self._get_documentation,
            description="API documentation"
        )
        
        # System status
        self.register_endpoint(
            path="/status",
            method=HTTPMethod.GET,
            handler=self._get_system_status,
            description="System status information"
        )
        
        # Module management
        self.register_endpoint(
            path="/modules",
            method=HTTPMethod.GET,
            handler=self._list_modules,
            description="List all modules"
        )
        
        self.register_endpoint(
            path="/modules/{module_name}",
            method=HTTPMethod.GET,
            handler=self._get_module_info,
            description="Get module information"
        )
        
        # Performance metrics
        self.register_endpoint(
            path="/metrics",
            method=HTTPMethod.GET,
            handler=self._get_metrics,
            description="Get performance metrics"
        )
        
        # Storage information
        self.register_endpoint(
            path="/storage",
            method=HTTPMethod.GET,
            handler=self._get_storage_info,
            description="Get storage information"
        )
    
    def register_endpoint(self, path: str, method: HTTPMethod, handler: Callable, 
                         version: APIVersion = APIVersion.V1, auth_required: bool = False,
                         rate_limit: Optional[int] = None, description: str = "",
                         parameters: Dict[str, Any] = None, responses: Dict[str, Any] = None):
        """Register a new API endpoint"""
        try:
            endpoint = APIEndpoint(
                path=f"/api/{version.value}{path}",
                method=method,
                handler=handler,
                version=version,
                auth_required=auth_required,
                rate_limit=rate_limit,
                description=description,
                parameters=parameters or {},
                responses=responses or {}
            )
            
            endpoint_key = f"{method.value}:{endpoint.path}"
            self.endpoints[endpoint_key] = endpoint
            
            # Register with aiohttp
            self.app.router.add_route(
                method.value,
                endpoint.path,
                lambda req, ep=endpoint: self.handler.handle_request(req, ep)
            )
            
            self.logger.info(f"Registered API endpoint: {method.value} {endpoint.path}")
            
        except Exception as e:
            self.logger.error(f"Failed to register endpoint {path}: {e}")
    
    async def start(self) -> bool:
        """Start the API server"""
        try:
            self.logger.info(f"Starting API server on {self.host}:{self.port}")
            
            # Create server
            runner = web.AppRunner(self.app)
            await runner.setup()
            
            self.server = web.TCPSite(runner, self.host, self.port)
            await self.server.start()
            
            self.logger.info("API server started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start API server: {e}")
            return False
    
    async def stop(self) -> bool:
        """Stop the API server"""
        try:
            if self.server:
                await self.server.stop()
                self.logger.info("API server stopped successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to stop API server: {e}")
            return False
    
    # Default endpoint handlers
    async def _health_check(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Health check endpoint"""
        return {
            "status": "healthy",
            "timestamp": time.time(),
            "version": "2.0.0"
        }
    
    async def _get_documentation(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Get API documentation"""
        docs = {
            "title": "LilithOS API Documentation",
            "version": "2.0.0",
            "endpoints": []
        }
        
        for endpoint in self.endpoints.values():
            docs["endpoints"].append({
                "path": endpoint.path,
                "method": endpoint.method.value,
                "description": endpoint.description,
                "auth_required": endpoint.auth_required,
                "rate_limit": endpoint.rate_limit,
                "parameters": endpoint.parameters,
                "responses": endpoint.responses
            })
        
        return docs
    
    async def _get_system_status(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Get system status"""
        return self.core.get_system_stats()
    
    async def _list_modules(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """List all modules"""
        modules = self.core.module_manager.list_modules()
        return {
            "modules": [
                {
                    "name": module.name,
                    "version": module.version,
                    "description": module.description,
                    "category": module.category,
                    "enabled": module.enabled,
                    "loaded": module.loaded,
                    "error_count": module.error_count
                }
                for module in modules
            ]
        }
    
    async def _get_module_info(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Get module information"""
        module_name = request.match_info.get('module_name')
        if not module_name:
            raise web.HTTPBadRequest(text="Module name required")
        
        module_info = self.core.module_manager.get_module_info(module_name)
        if not module_info:
            raise web.HTTPNotFound(text=f"Module {module_name} not found")
        
        return {
            "name": module_info.name,
            "version": module_info.version,
            "description": module_info.description,
            "author": module_info.author,
            "dependencies": module_info.dependencies,
            "conflicts": module_info.conflicts,
            "category": module_info.category,
            "priority": module_info.priority,
            "enabled": module_info.enabled,
            "loaded": module_info.loaded,
            "error_count": module_info.error_count,
            "last_error": module_info.last_error,
            "load_time": module_info.load_time
        }
    
    async def _get_metrics(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Get performance metrics"""
        return {
            "performance": self.core.performance.get_performance_stats(),
            "storage": self.core.storage.get_storage_stats(),
            "network": self.core.network.get_network_info(),
            "security": self.core.security.get_system_stats()
        }
    
    async def _get_storage_info(self, request: web.Request, api_request: APIRequest) -> Dict[str, Any]:
        """Get storage information"""
        return self.core.storage.get_storage_stats()
    
    def get_endpoint(self, path: str, method: HTTPMethod) -> Optional[APIEndpoint]:
        """Get an endpoint by path and method"""
        endpoint_key = f"{method.value}:{path}"
        return self.endpoints.get(endpoint_key)
    
    def list_endpoints(self, version: Optional[APIVersion] = None) -> List[APIEndpoint]:
        """List all endpoints, optionally filtered by version"""
        endpoints = list(self.endpoints.values())
        if version:
            endpoints = [ep for ep in endpoints if ep.version == version]
        return endpoints
    
    def get_api_stats(self) -> Dict[str, Any]:
        """Get API statistics"""
        return {
            "total_endpoints": len(self.endpoints),
            "versions": [version.value for version in APIVersion],
            "endpoints_by_version": {
                version.value: len([ep for ep in self.endpoints.values() if ep.version == version])
                for version in APIVersion
            },
            "endpoints_by_method": {
                method.value: len([ep for ep in self.endpoints.values() if ep.method == method])
                for method in HTTPMethod
            }
        } 