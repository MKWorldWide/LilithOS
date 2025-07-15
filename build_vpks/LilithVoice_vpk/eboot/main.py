#!/usr/bin/env python3
"""
LilithOS Voice Daemon - VPK Entry Point
"""

import sys
import os
import logging

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('lilith_voice.log'),
        logging.StreamHandler()
    ]
)

def main():
    """Main entry point for VPK."""
    try:
        from lilith_voice_daemon import LilithVoiceDaemon
        
        print("🎤 Starting LilithOS Voice Daemon...")
        print("📱 Running on PlayStation Vita")
        
        daemon = LilithVoiceDaemon()
        daemon.run_daemon()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
