import sys
import os
import asyncio
import logging

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("test_connection")

# Try to import the DivineBus
try:
    from core.divine_bus import DivineBus, start_divine_bus, stop_divine_bus
    logger.info("Successfully imported DivineBus")
except ImportError as e:
    logger.error(f"Failed to import DivineBus: {e}")
    logger.error(f"Python path: {sys.path}")
    sys.exit(1)

async def test_connection():
    """Test the DivineBus connection."""
    try:
        logger.info("Starting DivineBus...")
        await start_divine_bus()
        
        # Keep the server running for a while
        logger.info("DivineBus started. Press Ctrl+C to stop.")
        while True:
            await asyncio.sleep(1)
            
    except asyncio.CancelledError:
        logger.info("Shutting down DivineBus...")
        await stop_divine_bus()
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
    finally:
        await stop_divine_bus()

if __name__ == "__main__":
    try:
        asyncio.run(test_connection())
    except KeyboardInterrupt:
        logger.info("Test interrupted by user")
    except Exception as e:
        logger.error(f"Test failed: {e}", exc_info=True)
