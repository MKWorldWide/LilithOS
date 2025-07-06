"""
🚀 TrafficFlou API Handler Lambda Function

Main API handler for serverless TrafficFlou deployment with LilithOS integration.
Handles all API requests and routes them to appropriate Lambda functions.

Author: TrafficFlou Team
Version: 2.0.0
"""

import json
import os
import sys
from typing import Dict, Any, Optional
import logging
from mangum import Mangum
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))

from src.core.config import TrafficFlouConfig
from src.lilithos.process_manager import LilithOSProcessManager
from src.serverless.traffic_generator import ServerlessTrafficGenerator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="TrafficFlou Serverless API",
    description="AI-Powered traffic generation with LilithOS integration",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Global instances
process_manager: Optional[LilithOSProcessManager] = None
traffic_generator: Optional[ServerlessTrafficGenerator] = None

class TrafficRequest(BaseModel):
    """Request model for traffic generation"""
    target_url: str
    session_duration: int = 300
    traffic_intensity: float = 0.7
    user_profile: Optional[Dict[str, Any]] = None
    lilithos_features: Optional[Dict[str, Any]] = None

class SessionRequest(BaseModel):
    """Request model for session management"""
    session_id: str
    action: str  # start, stop, pause, resume

@app.on_event("startup")
async def startup_event():
    """Initialize LilithOS and TrafficFlou components"""
    global process_manager, traffic_generator
    
    try:
        logger.info("🚀 Initializing TrafficFlou Serverless API with LilithOS...")
        
        # Initialize LilithOS Process Manager
        process_manager = LilithOSProcessManager()
        await process_manager.initialize()
        
        # Initialize Serverless Traffic Generator
        config = TrafficFlouConfig()
        traffic_generator = ServerlessTrafficGenerator(config, process_manager)
        await traffic_generator.initialize()
        
        logger.info("✅ TrafficFlou Serverless API initialized successfully")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize TrafficFlou: {e}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup resources on shutdown"""
    global process_manager, traffic_generator
    
    try:
        if traffic_generator:
            await traffic_generator.cleanup()
        if process_manager:
            await process_manager.cleanup()
        logger.info("✅ TrafficFlou cleanup completed")
    except Exception as e:
        logger.error(f"❌ Error during cleanup: {e}")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "TrafficFlou Serverless API",
        "version": "2.0.0",
        "lilithos": "enabled",
        "features": [
            "AI-powered traffic generation",
            "LilithOS process management",
            "Serverless architecture",
            "Real-time analytics"
        ]
    }

@app.get("/health")
async def health_check():
    """Detailed health check with LilithOS status"""
    try:
        lilithos_status = await process_manager.get_status() if process_manager else "not_initialized"
        
        return {
            "status": "healthy",
            "timestamp": "2025-01-27T00:00:00Z",
            "lilithos": {
                "status": lilithos_status,
                "processes": await process_manager.get_process_count() if process_manager else 0,
                "memory_usage": await process_manager.get_memory_usage() if process_manager else 0,
                "cpu_usage": await process_manager.get_cpu_usage() if process_manager else 0
            },
            "traffic_generator": {
                "status": "active" if traffic_generator else "not_initialized",
                "active_sessions": await traffic_generator.get_active_sessions() if traffic_generator else 0
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@app.post("/api/generate-traffic")
async def generate_traffic(request: TrafficRequest):
    """Generate traffic with LilithOS optimization"""
    try:
        if not traffic_generator:
            raise HTTPException(status_code=503, detail="Traffic generator not initialized")
        
        # Start LilithOS process monitoring
        await process_manager.start_monitoring()
        
        # Generate traffic with LilithOS optimization
        result = await traffic_generator.generate_traffic(
            target_url=request.target_url,
            session_duration=request.session_duration,
            traffic_intensity=request.traffic_intensity,
            user_profile=request.user_profile,
            lilithos_features=request.lilithos_features
        )
        
        return {
            "status": "success",
            "session_id": result.get("session_id"),
            "traffic_generated": result.get("traffic_count", 0),
            "lilithos_optimization": result.get("lilithos_metrics", {}),
            "performance_metrics": result.get("performance_metrics", {})
        }
        
    except Exception as e:
        logger.error(f"Traffic generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Traffic generation failed: {str(e)}")

@app.post("/api/session")
async def manage_session(request: SessionRequest):
    """Manage traffic generation sessions"""
    try:
        if not traffic_generator:
            raise HTTPException(status_code=503, detail="Traffic generator not initialized")
        
        if request.action == "start":
            result = await traffic_generator.start_session(request.session_id)
        elif request.action == "stop":
            result = await traffic_generator.stop_session(request.session_id)
        elif request.action == "pause":
            result = await traffic_generator.pause_session(request.session_id)
        elif request.action == "resume":
            result = await traffic_generator.resume_session(request.session_id)
        else:
            raise HTTPException(status_code=400, detail=f"Invalid action: {request.action}")
        
        return {
            "status": "success",
            "session_id": request.session_id,
            "action": request.action,
            "result": result
        }
        
    except Exception as e:
        logger.error(f"Session management failed: {e}")
        raise HTTPException(status_code=500, detail=f"Session management failed: {str(e)}")

@app.get("/api/analytics")
async def get_analytics():
    """Get real-time analytics with LilithOS metrics"""
    try:
        if not traffic_generator:
            raise HTTPException(status_code=503, detail="Traffic generator not initialized")
        
        analytics = await traffic_generator.get_analytics()
        lilithos_metrics = await process_manager.get_metrics() if process_manager else {}
        
        return {
            "traffic_analytics": analytics,
            "lilithos_metrics": lilithos_metrics,
            "system_health": {
                "memory_usage": await process_manager.get_memory_usage() if process_manager else 0,
                "cpu_usage": await process_manager.get_cpu_usage() if process_manager else 0,
                "active_processes": await process_manager.get_process_count() if process_manager else 0
            }
        }
        
    except Exception as e:
        logger.error(f"Analytics retrieval failed: {e}")
        raise HTTPException(status_code=500, detail=f"Analytics retrieval failed: {str(e)}")

@app.get("/api/lilithos/status")
async def get_lilithos_status():
    """Get detailed LilithOS status and metrics"""
    try:
        if not process_manager:
            raise HTTPException(status_code=503, detail="LilithOS not initialized")
        
        return {
            "status": await process_manager.get_status(),
            "metrics": await process_manager.get_metrics(),
            "processes": await process_manager.get_process_info(),
            "optimization": await process_manager.get_optimization_status()
        }
        
    except Exception as e:
        logger.error(f"LilithOS status retrieval failed: {e}")
        raise HTTPException(status_code=500, detail=f"LilithOS status retrieval failed: {str(e)}")

# Error handlers
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc),
            "timestamp": "2025-01-27T00:00:00Z"
        }
    )

# AWS Lambda handler
def lambda_handler(event, context):
    """AWS Lambda handler function"""
    try:
        # Create Mangum adapter for FastAPI
        asgi_handler = Mangum(app, lifespan="off")
        
        # Handle the event
        response = asgi_handler(event, context)
        
        return response
        
    except Exception as e:
        logger.error(f"Lambda handler error: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error",
                "detail": str(e)
            })
        } 