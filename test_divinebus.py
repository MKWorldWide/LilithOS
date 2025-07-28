import asyncio
import logging
from core.divine_bus import divine_bus

# Configure logging
logging.basicConfig(level=logging.INFO)

async def main():
    try:
        print("Starting LilithKit DivineBus...")
        await divine_bus.start()
    except asyncio.CancelledError:
        print("Shutting down LilithKit...")
        await divine_bus.stop()

if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        print("\nShutdown requested...")
        loop.run_until_complete(divine_bus.stop())
    finally:
        loop.close()
