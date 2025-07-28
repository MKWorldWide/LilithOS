"""
Direct test of the DivineBus module.
This script tests the DivineBus functionality directly without relying on imports.
"""

import asyncio
import json
import logging
import os
import sys
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("divinebus_test")

# Add the current directory to Python path
current_dir = Path(__file__).parent.absolute()
sys.path.insert(0, str(current_dir))

# Import the module directly
module_path = current_dir / "core" / "divine_bus.py"
if not module_path.exists():
    logger.error(f"Could not find module at {module_path}")
    sys.exit(1)

# Load the module directly
import importlib.util
spec = importlib.util.spec_from_file_location("divine_bus", module_path)
divine_bus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(divine_bus)

# Now we can use the module
DivineBus = divine_bus.DivineBus

async def test_divine_bus():
    """Test the DivineBus functionality."""
    logger.info("Starting DivineBus test...")
    
    # Initialize the bus
    bus = DivineBus(config_path=str(current_dir / "config" / "athena.json"))
    
    # Start the server
    server_task = asyncio.create_task(bus.start())
    
    try:
        # Wait for the server to start
        await asyncio.sleep(1)
        
        # Test the ping functionality
        logger.info("Testing ping...")
        try:
            from core.divine_bus import divine_bus as db
            response = await db.divine_bus._handle_ping({})
            logger.info(f"Ping response: {response}")
        except Exception as e:
            logger.error(f"Ping test failed: {e}", exc_info=True)
        
        # Keep the server running for a while
        logger.info("Press Ctrl+C to stop the server...")
        while True:
            await asyncio.sleep(1)
            
    except asyncio.CancelledError:
        logger.info("Shutting down...")
    except Exception as e:
        logger.error(f"Test error: {e}", exc_info=True)
    finally:
        # Clean up
        if 'server_task' in locals():
            server_task.cancel()
            try:
                await server_task
            except asyncio.CancelledError:
                pass
        
        await bus.stop()
        logger.info("Test completed")

if __name__ == "__main__":
    try:
        asyncio.run(test_divine_bus())
    except KeyboardInterrupt:
        logger.info("Test interrupted by user")
    except Exception as e:
        logger.error(f"Test failed: {e}", exc_info=True)
