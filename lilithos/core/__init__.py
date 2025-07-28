""
LilithOS Core Package

This package contains the core functionality of LilithOS, including the DivineBus
implementation for secure communication with AthenaCore.
"""

from .divine_bus import DivineBus, start_divine_bus, stop_divine_bus

__all__ = ['DivineBus', 'start_divine_bus', 'stop_divine_bus']
