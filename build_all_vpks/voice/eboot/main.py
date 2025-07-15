#!/usr/bin/env python3
"""
LilithOS Voice Daemon - VPK Entry Point
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lilith_voice_daemon import LilithVoiceDaemon

def main():
    print("🎤 Starting LilithOS Voice Daemon...")
    daemon = LilithVoiceDaemon()
    daemon.run_daemon()

if __name__ == "__main__":
    main()
