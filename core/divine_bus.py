"""
DivineBus - Secure RPC communication channel for LilithOS <-> AthenaCore

This module implements an encrypted, authenticated socket-based RPC system that allows
bidirectional communication between LilithOS and AthenaCore. All communications are
encrypted using AES-256-GCM for confidentiality and authenticity.
"""

import asyncio
import json
import logging
import os
import struct
from typing import Any, Callable, Dict, Optional, Tuple

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes, hmac
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.exceptions import InvalidTag

# Configure logging
logger = logging.getLogger("lilith.divine_bus")

class DivineBus:
    """Secure RPC communication bus for LilithOS <-> AthenaCore communication."""
    
    def __init__(self, config_path: str = "config/athena.json"):
        """Initialize the DivineBus with configuration.
        
        Args:
            config_path: Path to Athena configuration file
        """
        self.config_path = config_path
        self.config = self._load_config()
        self.aes_key = self._derive_key(self.config["shared_secret"].encode())
        self.running = False
        self.server = None
        self._handlers = {}
        self._default_handler = None
        self._connection_id = 0
        
        # Register default handlers
        self.register_handler("ping", self._handle_ping)
        self.register_handler("restart_module", self._handle_restart_module)
        self.register_handler("get_metrics", self._handle_get_metrics)
        self.register_handler("sync_heartbeat", self._handle_sync_heartbeat)
        self.register_handler("send_alert", self._handle_send_alert)
    
    def _load_config(self) -> Dict[str, Any]:
        """Load Athena configuration."""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning(f"Configuration file {self.config_path} not found. Using defaults.")
            return {
                "host": "0.0.0.0",
                "port": 9001,
                "shared_secret": os.urandom(32).hex(),  # Generate a random secret if none exists
                "auth_timeout": 5.0,
                "max_message_size": 1048576,  # 1MB
            }
    
    def _derive_key(self, secret: bytes, salt: bytes = b'lilith-divine-bus') -> bytes:
        """Derive a secure encryption key from the shared secret."""
        hkdf = HKDF(
            algorithm=hashes.SHA256(),
            length=32,  # 256 bits for AES-256
            salt=salt,
            info=b'divine-bus-key',
        )
        return hkdf.derive(secret)
    
    async def start(self):
        """Start the DivineBus server."""
        if self.running:
            logger.warning("DivineBus is already running")
            return
            
        self.running = True
        try:
            self.server = await asyncio.start_server(
                self._handle_connection,
                host=self.config["host"],
                port=self.config["port"]
            )
            logger.info(f"DivineBus listening on {self.config['host']}:{self.config['port']}")
            
            # Keep the server running
            async with self.server:
                await self.server.serve_forever()
                
        except Exception as e:
            logger.error(f"DivineBus server error: {e}")
            raise
        finally:
            self.running = False
    
    async def stop(self):
        """Stop the DivineBus server."""
        if not self.running or not self.server:
            return
            
        self.running = False
        self.server.close()
        await self.server.wait_closed()
        logger.info("DivineBus server stopped")
    
    def register_handler(self, method: str, handler: Callable):
        """Register an RPC handler for a specific method.
        
        Args:
            method: The RPC method name
            handler: Async function that takes (params: Dict) and returns a serializable result
        """
        self._handlers[method] = handler
    
    def set_default_handler(self, handler: Callable):
        """Set the default handler for unregistered methods."""
        self._default_handler = handler
    
    async def _handle_connection(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        """Handle a new client connection."""
        conn_id = self._connection_id
        self._connection_id += 1
        
        client_addr = writer.get_extra_info('peername')
        logger.info(f"New DivineBus connection from {client_addr} [conn-{conn_id}]")
        
        try:
            while self.running:
                # Read message length (4 bytes, big-endian)
                try:
                    msg_len_bytes = await asyncio.wait_for(
                        reader.readexactly(4),
                        timeout=30.0
                    )
                except (asyncio.IncompleteReadError, asyncio.TimeoutError):
                    logger.debug(f"Connection {conn_id} timed out or closed")
                    break
                    
                msg_len = struct.unpack('>I', msg_len_bytes)[0]
                
                # Validate message length
                if msg_len > self.config["max_message_size"]:
                    logger.warning(f"Message too large: {msg_len} bytes")
                    await self._send_error(writer, "message_too_large", "Message exceeds maximum size")
                    break
                
                # Read encrypted message
                try:
                    encrypted_msg = await asyncio.wait_for(
                        reader.readexactly(msg_len),
                        timeout=5.0
                    )
                except (asyncio.IncompleteReadError, asyncio.TimeoutError):
                    logger.warning(f"Failed to read message from {client_addr}")
                    break
                
                # Decrypt and process message
                try:
                    decrypted_msg = self._decrypt(encrypted_msg)
                    result = await self._handle_rpc(decrypted_msg)
                    response = self._create_response(result=result)
                except Exception as e:
                    logger.error(f"Error processing RPC: {e}", exc_info=True)
                    response = self._create_response(error={"code": "internal_error", "message": str(e)})
                
                # Send response
                await self._send_encrypted(writer, response)
                
        except Exception as e:
            logger.error(f"Connection {conn_id} error: {e}", exc_info=True)
        finally:
            writer.close()
            try:
                await writer.wait_closed()
            except Exception:
                pass
            logger.info(f"Connection {conn_id} closed")
    
    async def _handle_rpc(self, message: Dict) -> Any:
        """Handle an incoming RPC message."""
        method = message.get("method")
        params = message.get("params", {})
        
        if not method:
            raise ValueError("No method specified")
        
        handler = self._handlers.get(method)
        if not handler:
            if self._default_handler:
                return await self._default_handler(method, params)
            raise ValueError(f"Unknown method: {method}")
        
        return await handler(params)
    
    async def _handle_ping(self, params: Dict) -> Dict:
        """Handle ping request."""
        return {"status": "alive", "timestamp": asyncio.get_event_loop().time()}
    
    async def _handle_restart_module(self, params: Dict) -> Dict:
        """Handle module restart request."""
        module = params.get("module")
        if not module:
            raise ValueError("No module specified")
            
        # TODO: Implement actual module restart logic
        logger.info(f"Restarting module: {module}")
        return {"status": "restarting", "module": module}
    
    async def _handle_get_metrics(self, params: Dict) -> Dict:
        """Handle metrics collection request."""
        # TODO: Implement actual metrics collection
        from .performance import collect_metrics
        return await collect_metrics()
    
    async def _handle_sync_heartbeat(self, params: Dict) -> Dict:
        """Handle heartbeat synchronization."""
        # TODO: Implement heartbeat sync logic
        return {"status": "synced", "timestamp": asyncio.get_event_loop().time()}
    
    async def _handle_send_alert(self, params: Dict) -> Dict:
        """Handle alert notification."""
        message = params.get("message")
        level = params.get("level", "info")
        
        if not message:
            raise ValueError("No message provided")
            
        # TODO: Implement actual alert handling
        logger.log(
            getattr(logging, level.upper(), logging.INFO),
            f"ALERT ({level}): {message}"
        )
        
        return {"status": "alert_sent", "message": message, "level": level}
    
    def _encrypt(self, data: bytes) -> bytes:
        """Encrypt data using AES-GCM."""
        aesgcm = AESGCM(self.aes_key)
        nonce = os.urandom(12)  # 96-bit nonce for GCM
        ct = aesgcm.encrypt(nonce, data, None)
        return nonce + ct  # Return nonce || ciphertext || tag
    
    def _decrypt(self, data: bytes) -> bytes:
        """Decrypt data using AES-GCM."""
        if len(data) < 28:  # 12-byte nonce + 16-byte tag
            raise ValueError("Invalid encrypted data")
            
        nonce = data[:12]
        ct = data[12:]
        
        aesgcm = AESGCM(self.aes_key)
        try:
            return aesgcm.decrypt(nonce, ct, None)
        except InvalidTag:
            raise ValueError("Invalid authentication tag")
    
    def _create_response(self, result: Any = None, error: Dict = None) -> Dict:
        """Create an RPC response."""
        if result is not None and error is not None:
            raise ValueError("Cannot specify both result and error")
            
        response = {"jsonrpc": "2.0"}
        
        if error is not None:
            response["error"] = error
        else:
            response["result"] = result
            
        return response
    
    async def _send_encrypted(self, writer: asyncio.StreamWriter, data: Dict):
        """Send encrypted JSON-RPC response."""
        try:
            json_data = json.dumps(data).encode('utf-8')
            encrypted = self._encrypt(json_data)
            
            # Send message length (4 bytes, big-endian)
            writer.write(struct.pack('>I', len(encrypted)))
            
            # Send encrypted message
            writer.write(encrypted)
            await writer.drain()
            
        except Exception as e:
            logger.error(f"Failed to send response: {e}", exc_info=True)
            raise
    
    async def _send_error(self, writer: asyncio.StreamWriter, code: str, message: str):
        """Send an error response and close the connection."""
        error = {"code": code, "message": message}
        response = self._create_response(error=error)
        await self._send_encrypted(writer, response)
        writer.close()
        await writer.wait_closed()


# Singleton instance
divine_bus = DivineBus()

async def start_divine_bus():
    """Start the DivineBus server."""
    await divine_bus.start()

async def stop_divine_bus():
    """Stop the DivineBus server."""
    await divine_bus.stop()

# Example usage
if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    
    async def main():
        bus = DivineBus()
        try:
            await bus.start()
        except KeyboardInterrupt:
            await bus.stop()
    
    asyncio.run(main())
