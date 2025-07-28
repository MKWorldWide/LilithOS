""
LilithOS Command Line Interface

This module provides the command-line interface for interacting with LilithOS.
"""

__all__ = ['main']

def main():
    """Entry point for the lilithctl command-line tool."""
    from .cli import main as _main
    return _main()
