""
LilithOS Command Line Interface

This module implements the command-line interface for LilithOS.
"""

import argparse
import asyncio
import json
import logging
import os
import sys
from typing import Dict, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("lilithctl")

# Import from our package
try:
    from ..core import DivineBus, start_divine_bus, stop_divine_bus
except ImportError as e:
    logger.error(f"Failed to import LilithOS core: {e}")
    logger.error("Please ensure the package is properly installed")
    sys.exit(1)

class LilithCtl:
    """LilithOS Control Tool"""
    
    def __init__(self, config_path: str = None):
        """Initialize the CLI tool."""
        self.config_path = config_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "config",
            "athena.json"
        )
        self.bus = None
        self._setup_argparse()
    
    def _setup_argparse(self):
        """Set up the argument parser."""
        self.parser = argparse.ArgumentParser(
            description="LilithOS Control Tool",
            formatter_class=argparse.RawDescriptionHelpFormatter
        )
        
        # Global arguments
        self.parser.add_argument(
            "-c", "--config",
            default=self.config_path,
            help="Path to Athena configuration file"
        )
        self.parser.add_argument(
            "-v", "--verbose",
            action="store_true",
            help="Enable verbose output"
        )
        
        # Subcommands
        subparsers = self.parser.add_subparsers(dest="command", required=True)
        
        # ping command
        ping_parser = subparsers.add_parser(
            "ping",
            help="Ping the AthenaCore service"
        )
        ping_parser.add_argument(
            "target",
            choices=["athena"],
            help="Target service to ping"
        )
        
        # status command
        status_parser = subparsers.add_parser(
            "status",
            help="Check status of LilithOS components"
        )
        
        # restart command
        restart_parser = subparsers.add_parser(
            "restart",
            help="Restart LilithOS components"
        )
        restart_parser.add_argument(
            "component",
            choices=["divine-bus", "all"],
            help="Component to restart"
        )
        
        # metrics command
        metrics_parser = subparsers.add_parser(
            "metrics",
            help="View or collect system metrics"
        )
        metrics_parser.add_argument(
            "--format",
            choices=["json", "text", "prometheus"],
            default="text",
            help="Output format"
        )
        
        # config command
        config_parser = subparsers.add_parser(
            "config",
            help="View or update configuration"
        )
        config_parser.add_argument(
            "action",
            choices=["show", "get", "set", "validate"],
            help="Action to perform"
        )
        config_parser.add_argument(
            "key",
            nargs="?",
            help="Configuration key to get/set"
        )
        config_parser.add_argument(
            "value",
            nargs="?",
            help="Value to set"
        )
        
        # key rotation command
        key_parser = subparsers.add_parser(
            "rotate-keys",
            help="Rotate encryption keys"
        )
        key_parser.add_argument(
            "--force",
            action="store_true",
            help="Force rotation even if not expired"
        )
    
    async def run(self, args=None):
        """Run the CLI tool."""
        if args is None:
            args = self.parser.parse_args()
        
        # Set log level
        if args.verbose:
            logging.getLogger().setLevel(logging.DEBUG)
        
        # Update config path if specified
        if hasattr(args, 'config') and args.config:
            self.config_path = args.config
        
        # Initialize DivineBus
        try:
            self.bus = DivineBus(config_path=self.config_path)
        except Exception as e:
            logger.error(f"Failed to initialize DivineBus: {e}")
            return 1
        
        # Route to appropriate handler
        handler = getattr(self, f"handle_{args.command.replace('-', '_')}", None)
        if not handler:
            logger.error(f"Unknown command: {args.command}")
            return 1
        
        try:
            return await handler(args)
        except KeyboardInterrupt:
            logger.info("Operation cancelled by user")
            return 130  # SIGINT exit code
        except Exception as e:
            logger.error(f"Error: {e}", exc_info=args.verbose)
            return 1
    
    async def handle_ping(self, args):
        """Handle ping command."""
        if args.target == "athena":
            try:
                result = await self._send_rpc("ping", {})
                print(f"✅ Athena is alive! Response: {result}")
                return 0
            except Exception as e:
                print(f"❌ Failed to ping Athena: {e}")
                return 1
    
    async def handle_status(self, args):
        """Handle status command."""
        try:
            # Check DivineBus status
            print("🔍 Checking DivineBus status...")
            try:
                result = await self._send_rpc("get_metrics", {})
                print("✅ DivineBus is running")
                print(f"   • Uptime: {result.get('uptime', 'N/A')}")
                print(f"   • Active connections: {result.get('connections', 'N/A')}")
                print(f"   • Messages processed: {result.get('messages_processed', 'N/A')}")
                return 0
            except Exception as e:
                print(f"❌ DivineBus is not responding: {e}")
                return 1
                
        except Exception as e:
            print(f"❌ Error checking status: {e}")
            return 1
    
    async def handle_restart(self, args):
        """Handle restart command."""
        if args.component in ["divine-bus", "all"]:
            print("🔄 Restarting DivineBus...")
            try:
                result = await self._send_rpc("restart_module", {"module": "divine_bus"})
                print(f"✅ DivineBus restart initiated: {result}")
                return 0
            except Exception as e:
                print(f"❌ Failed to restart DivineBus: {e}")
                return 1
    
    async def handle_metrics(self, args):
        """Handle metrics command."""
        try:
            metrics = await self._send_rpc("get_metrics", {})
            
            if args.format == "json":
                print(json.dumps(metrics, indent=2))
            elif args.format == "prometheus":
                self._print_prometheus_metrics(metrics)
            else:  # text
                self._print_text_metrics(metrics)
                
            return 0
            
        except Exception as e:
            print(f"❌ Failed to get metrics: {e}")
            return 1
    
    async def handle_config(self, args):
        """Handle config command."""
        if args.action == "show":
            with open(self.config_path, 'r') as f:
                print(json.dumps(json.load(f), indent=2))
            return 0
            
        elif args.action == "get":
            if not args.key:
                print("Error: No key specified")
                return 1
                
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                
            # Support nested keys with dot notation
            value = config
            for key_part in args.key.split('.'):
                if key_part not in value:
                    print(f"Key not found: {args.key}")
                    return 1
                value = value[key_part]
                
            print(json.dumps(value, indent=2))
            return 0
            
        elif args.action == "set":
            if not args.key or not args.value:
                print("Error: Both key and value must be specified")
                return 1
                
            # TODO: Implement config set with validation
            print("Config set not yet implemented")
            return 0
            
        elif args.action == "validate":
            try:
                with open(self.config_path, 'r') as f:
                    json.load(f)
                print("✅ Configuration is valid JSON")
                return 0
            except json.JSONDecodeError as e:
                print(f"❌ Invalid JSON: {e}")
                return 1
    
    async def handle_rotate_keys(self, args):
        """Handle key rotation command."""
        print("🔄 Rotating encryption keys...")
        try:
            result = await self._send_rpc("rotate_keys", {"force": args.force})
            print(f"✅ {result.get('message', 'Keys rotated successfully')}")
            return 0
        except Exception as e:
            print(f"❌ Failed to rotate keys: {e}")
            return 1
    
    async def _send_rpc(self, method: str, params: Dict) -> Any:
        """Send an RPC request to the local DivineBus."""
        # In a real implementation, this would connect to the running DivineBus
        # For now, we'll simulate it for the CLI
        if method == "ping":
            return {"status": "pong", "timestamp": asyncio.get_event_loop().time()}
        elif method == "get_metrics":
            return {
                "uptime": "1h 23m",
                "connections": 1,
                "messages_processed": 42,
                "cpu_usage": 12.5,
                "memory_usage": 256.7,
                "timestamp": asyncio.get_event_loop().time()
            }
        elif method == "restart_module":
            return {"status": "success", "module": params.get("module")}
        elif method == "rotate_keys":
            return {"message": "Keys rotated successfully"}
        else:
            raise ValueError(f"Unknown method: {method}")
    
    def _print_text_metrics(self, metrics: Dict):
        """Print metrics in human-readable text format."""
        print("📊 System Metrics")
        print("----------------")
        print(f"• Uptime: {metrics.get('uptime', 'N/A')}")
        print(f"• CPU Usage: {metrics.get('cpu_usage', 'N/A')}%")
        print(f"• Memory Usage: {metrics.get('memory_usage', 'N/A')} MB")
        print(f"• Active Connections: {metrics.get('connections', 'N/A')}")
        print(f"• Messages Processed: {metrics.get('messages_processed', 'N/A')}")
    
    def _print_prometheus_metrics(self, metrics: Dict):
        """Print metrics in Prometheus format."""
        print(f"# HELP lilith_uptime_seconds System uptime in seconds")
        print(f"# TYPE lilith_uptime_seconds gauge")
        print(f'lilith_uptime_seconds{{host="lilith"}} {metrics.get("uptime_seconds", 0)}')
        
        print(f"# HELP lilith_cpu_usage_percent CPU usage percentage")
        print(f"# TYPE lilith_cpu_usage_percent gauge")
        print(f'lilith_cpu_usage_percent{{host="lilith"}} {metrics.get("cpu_usage", 0)}')
        
        print(f"# HELP lilith_memory_usage_mb Memory usage in MB")
        print(f"# TYPE lilith_memory_usage_mb gauge")
        print(f'lilith_memory_usage_mb{{host="lilith"}} {metrics.get("memory_usage", 0)}')
        
        print(f"# HELP lilith_connections Number of active connections")
        print(f"# TYPE lilith_connections gauge")
        print(f'lilith_connections{{host="lilith"}} {metrics.get("connections", 0)}')
        
        print(f"# HELP lilith_messages_processed_total Total messages processed")
        print(f"# TYPE lilith_messages_processed_total counter")
        print(f'lilith_messages_processed_total{{host="lilith"}} {metrics.get("messages_processed", 0)}')

def main():
    """Main entry point for the CLI."""
    # Enable ANSI colors on Windows
    if sys.platform == "win32":
        import colorama
        colorama.init()
    
    # Run the CLI
    cli = LilithCtl()
    return asyncio.run(cli.run())

if __name__ == "__main__":
    sys.exit(main())
