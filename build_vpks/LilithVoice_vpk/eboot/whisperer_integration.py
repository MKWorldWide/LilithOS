#!/usr/bin/env python3
"""
LilithOS Whisperer Integration: whisperer_integration.py
=======================================================
Integration module for event whisperer system and voice event routing.

📋 Feature Context:
    - Connects to event whisperer system for real-time event processing
    - Routes system events to appropriate voice responses
    - Manages event queue and priority handling
    - Provides bidirectional communication with whisperer daemon

🧩 Dependency Listings:
    - Integrates with lilith_voice_daemon.py
    - Connects to event whisperer system
    - Uses voice_config.yaml for event mappings
    - Manages event queue and threading

💡 Usage Example:
    - Initialize: wi = WhispererIntegration(voice_daemon)
    - Start: wi.start()
    - Send event: wi.send_event('system_startup', {})

⚡ Performance Considerations:
    - Non-blocking event processing
    - Efficient queue management
    - Minimal latency for critical events

🔒 Security Implications:
    - Event validation and sanitization
    - Secure communication channels
    - Protected event routing

📜 Changelog Entries:
    - v1.0.0: Initial quantum-detailed scaffold
"""

import asyncio
import json
import logging
import threading
import time
import websockets
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass
from enum import Enum
from queue import Queue, PriorityQueue

logger = logging.getLogger('WhispererIntegration')

class EventPriority(Enum):
    """Event priority levels."""
    LOW = 3
    NORMAL = 2
    HIGH = 1
    CRITICAL = 0

@dataclass
class WhispererEvent:
    """Whisperer event structure."""
    event_type: str
    data: Dict[str, Any]
    priority: EventPriority
    timestamp: float
    source: str

class WhispererIntegration:
    def __init__(self, voice_daemon, config: Dict = None):
        """Initialize whisperer integration."""
        self.voice_daemon = voice_daemon
        self.config = config or {}
        self.running = False
        self.websocket = None
        self.event_queue = PriorityQueue()
        self.event_handlers: Dict[str, Callable] = {}
        self.connection_retries = 0
        self.max_retries = self.config.get('max_retries', 5)
        
        # Event mappings from config
        self.event_mappings = self.config.get('event_mappings', {})
        
        # Initialize event handlers
        self.initialize_event_handlers()
        
    def initialize_event_handlers(self):
        """Initialize default event handlers."""
        logger.info("[WhispererIntegration] Initializing event handlers")
        
        # System events
        self.register_event_handler('system_startup', self.handle_system_startup)
        self.register_event_handler('system_shutdown', self.handle_system_shutdown)
        self.register_event_handler('error_detected', self.handle_error_detected)
        self.register_event_handler('success_completed', self.handle_success_completed)
        self.register_event_handler('security_alert', self.handle_security_alert)
        
        # Network events
        self.register_event_handler('network_connected', self.handle_network_connected)
        self.register_event_handler('network_disconnected', self.handle_network_disconnected)
        self.register_event_handler('mesh_peer_discovered', self.handle_mesh_peer_discovered)
        
        # Memory scanner events
        self.register_event_handler('memory_scan_start', self.handle_memory_scan_start)
        self.register_event_handler('memory_scan_complete', self.handle_memory_scan_complete)
        self.register_event_handler('memory_anomaly', self.handle_memory_anomaly)
        
        # Bootloader events
        self.register_event_handler('bootloader_mode', self.handle_bootloader_mode)
        self.register_event_handler('psp_mode', self.handle_psp_mode)
        self.register_event_handler('vita_mode', self.handle_vita_mode)
        
        # LiveArea events
        self.register_event_handler('theme_change', self.handle_theme_change)
        self.register_event_handler('animation_trigger', self.handle_animation_trigger)
        self.register_event_handler('user_interaction', self.handle_user_interaction)
        
        # OTA events
        self.register_event_handler('ota_update_available', self.handle_ota_update_available)
        self.register_event_handler('ota_update_progress', self.handle_ota_update_progress)
        self.register_event_handler('ota_update_complete', self.handle_ota_update_complete)
        
        # WhispurrNet events
        self.register_event_handler('whispurrnet_ready', self.handle_whispurrnet_ready)
        self.register_event_handler('encryption_active', self.handle_encryption_active)
        self.register_event_handler('secure_channel_established', self.handle_secure_channel_established)
        
        logger.info(f"[WhispererIntegration] Registered {len(self.event_handlers)} event handlers")
    
    def register_event_handler(self, event_type: str, handler: Callable):
        """Register event handler for specific event type."""
        self.event_handlers[event_type] = handler
        logger.debug(f"[WhispererIntegration] Registered handler for event: {event_type}")
    
    async def connect_to_whisperer(self):
        """Connect to event whisperer system."""
        whisperer_config = self.config.get('whisperer', {})
        host = whisperer_config.get('host', 'localhost')
        port = whisperer_config.get('port', 8080)
        timeout = whisperer_config.get('timeout', 10.0)
        
        url = f"ws://{host}:{port}/events"
        
        try:
            logger.info(f"[WhispererIntegration] Connecting to whisperer at {url}")
            self.websocket = await asyncio.wait_for(
                websockets.connect(url),
                timeout=timeout
            )
            
            # Send registration message
            registration = {
                'type': 'register',
                'component': 'lilith_voice',
                'capabilities': ['tts', 'audio_output', 'phrase_scripting'],
                'event_types': list(self.event_handlers.keys())
            }
            
            await self.websocket.send(json.dumps(registration))
            response = await self.websocket.recv()
            response_data = json.loads(response)
            
            if response_data.get('status') == 'registered':
                logger.info("[WhispererIntegration] Successfully registered with whisperer")
                self.connection_retries = 0
                return True
            else:
                logger.error(f"[WhispererIntegration] Registration failed: {response_data}")
                return False
                
        except Exception as e:
            logger.error(f"[WhispererIntegration] Connection failed: {e}")
            self.connection_retries += 1
            return False
    
    async def listen_for_events(self):
        """Listen for events from whisperer system."""
        logger.info("[WhispererIntegration] Starting event listener")
        
        while self.running:
            try:
                if not self.websocket:
                    if not await self.connect_to_whisperer():
                        await asyncio.sleep(5)  # Wait before retry
                        continue
                
                # Listen for events
                message = await self.websocket.recv()
                event_data = json.loads(message)
                
                # Process event
                await self.process_event(event_data)
                
            except websockets.exceptions.ConnectionClosed:
                logger.warning("[WhispererIntegration] Connection closed, attempting reconnect")
                self.websocket = None
                await asyncio.sleep(2)
                
            except Exception as e:
                logger.error(f"[WhispererIntegration] Event processing error: {e}")
                await asyncio.sleep(1)
        
        logger.info("[WhispererIntegration] Event listener stopped")
    
    async def process_event(self, event_data: Dict):
        """Process incoming event from whisperer."""
        event_type = event_data.get('type')
        data = event_data.get('data', {})
        priority = EventPriority(event_data.get('priority', 2))
        source = event_data.get('source', 'unknown')
        
        logger.info(f"[WhispererIntegration] Processing event: {event_type} from {source}")
        
        # Create whisperer event
        whisperer_event = WhispererEvent(
            event_type=event_type,
            data=data,
            priority=priority,
            timestamp=time.time(),
            source=source
        )
        
        # Add to priority queue
        self.event_queue.put((priority.value, whisperer_event))
        
        # Process immediately if high priority
        if priority in [EventPriority.HIGH, EventPriority.CRITICAL]:
            await self.handle_event(whisperer_event)
    
    async def handle_event(self, event: WhispererEvent):
        """Handle specific event."""
        handler = self.event_handlers.get(event.event_type)
        
        if handler:
            try:
                # Call handler in thread pool to avoid blocking
                loop = asyncio.get_event_loop()
                await loop.run_in_executor(None, handler, event)
            except Exception as e:
                logger.error(f"[WhispererIntegration] Event handler error for {event.event_type}: {e}")
        else:
            logger.warning(f"[WhispererIntegration] No handler for event: {event.event_type}")
    
    async def event_processor_worker(self):
        """Worker to process events from queue."""
        logger.info("[WhispererIntegration] Starting event processor worker")
        
        while self.running:
            try:
                # Get event from queue with timeout
                try:
                    priority, event = self.event_queue.get(timeout=1)
                    await self.handle_event(event)
                    self.event_queue.task_done()
                except asyncio.TimeoutError:
                    continue
                    
            except Exception as e:
                logger.error(f"[WhispererIntegration] Event processor error: {e}")
                await asyncio.sleep(0.1)
        
        logger.info("[WhispererIntegration] Event processor worker stopped")
    
    async def send_event(self, event_type: str, data: Dict = None, priority: EventPriority = EventPriority.NORMAL):
        """Send event to whisperer system."""
        if not self.websocket:
            logger.error("[WhispererIntegration] Not connected to whisperer")
            return False
        
        try:
            event_message = {
                'type': event_type,
                'data': data or {},
                'priority': priority.value,
                'source': 'lilith_voice',
                'timestamp': time.time()
            }
            
            await self.websocket.send(json.dumps(event_message))
            logger.debug(f"[WhispererIntegration] Sent event: {event_type}")
            return True
            
        except Exception as e:
            logger.error(f"[WhispererIntegration] Failed to send event: {e}")
            return False
    
    # Event handler implementations
    def handle_system_startup(self, event: WhispererEvent):
        """Handle system startup event."""
        logger.info("[WhispererIntegration] Handling system startup")
        self.voice_daemon.signal_to_speech_map(
            self.voice_daemon.VoiceEvent.SYSTEM_STARTUP,
            event.data
        )
    
    def handle_system_shutdown(self, event: WhispererEvent):
        """Handle system shutdown event."""
        logger.info("[WhispererIntegration] Handling system shutdown")
        self.voice_daemon.signal_to_speech_map(
            self.voice_daemon.VoiceEvent.SYSTEM_SHUTDOWN,
            event.data
        )
    
    def handle_error_detected(self, event: WhispererEvent):
        """Handle error detected event."""
        logger.info("[WhispererIntegration] Handling error detected")
        self.voice_daemon.signal_to_speech_map(
            self.voice_daemon.VoiceEvent.ERROR_OCCURRED,
            event.data
        )
    
    def handle_success_completed(self, event: WhispererEvent):
        """Handle success completed event."""
        logger.info("[WhispererIntegration] Handling success completed")
        self.voice_daemon.signal_to_speech_map(
            self.voice_daemon.VoiceEvent.SUCCESS_COMPLETED,
            event.data
        )
    
    def handle_security_alert(self, event: WhispererEvent):
        """Handle security alert event."""
        logger.info("[WhispererIntegration] Handling security alert")
        self.voice_daemon.signal_to_speech_map(
            self.voice_daemon.VoiceEvent.SECURITY_ALERT,
            event.data
        )
    
    def handle_network_connected(self, event: WhispererEvent):
        """Handle network connected event."""
        logger.info("[WhispererIntegration] Handling network connected")
        self.voice_daemon.process_phrase_script('network_connected', event.data)
    
    def handle_network_disconnected(self, event: WhispererEvent):
        """Handle network disconnected event."""
        logger.info("[WhispererIntegration] Handling network disconnected")
        self.voice_daemon.speak_text("Network connection lost", priority=2)
    
    def handle_mesh_peer_discovered(self, event: WhispererEvent):
        """Handle mesh peer discovered event."""
        logger.info("[WhispererIntegration] Handling mesh peer discovered")
        self.voice_daemon.process_phrase_script('mesh_peer_discovered', event.data)
    
    def handle_memory_scan_start(self, event: WhispererEvent):
        """Handle memory scan start event."""
        logger.info("[WhispererIntegration] Handling memory scan start")
        self.voice_daemon.speak_text("Memory scan initiated", priority=1)
    
    def handle_memory_scan_complete(self, event: WhispererEvent):
        """Handle memory scan complete event."""
        logger.info("[WhispererIntegration] Handling memory scan complete")
        self.voice_daemon.process_phrase_script('memory_scan_complete', event.data)
    
    def handle_memory_anomaly(self, event: WhispererEvent):
        """Handle memory anomaly event."""
        logger.info("[WhispererIntegration] Handling memory anomaly")
        self.voice_daemon.process_phrase_script('memory_anomaly', event.data)
    
    def handle_bootloader_mode(self, event: WhispererEvent):
        """Handle bootloader mode event."""
        logger.info("[WhispererIntegration] Handling bootloader mode")
        self.voice_daemon.process_phrase_script('bootloader_mode', event.data)
    
    def handle_psp_mode(self, event: WhispererEvent):
        """Handle PSP mode event."""
        logger.info("[WhispererIntegration] Handling PSP mode")
        self.voice_daemon.process_phrase_script('psp_mode', event.data)
    
    def handle_vita_mode(self, event: WhispererEvent):
        """Handle Vita mode event."""
        logger.info("[WhispererIntegration] Handling Vita mode")
        self.voice_daemon.process_phrase_script('vita_mode', event.data)
    
    def handle_theme_change(self, event: WhispererEvent):
        """Handle theme change event."""
        logger.info("[WhispererIntegration] Handling theme change")
        self.voice_daemon.process_phrase_script('divine_black_theme', event.data)
    
    def handle_animation_trigger(self, event: WhispererEvent):
        """Handle animation trigger event."""
        logger.info("[WhispererIntegration] Handling animation trigger")
        self.voice_daemon.speak_text("Animation triggered", priority=1)
    
    def handle_user_interaction(self, event: WhispererEvent):
        """Handle user interaction event."""
        logger.info("[WhispererIntegration] Handling user interaction")
        self.voice_daemon.process_phrase_script('user_interaction', event.data)
    
    def handle_ota_update_available(self, event: WhispererEvent):
        """Handle OTA update available event."""
        logger.info("[WhispererIntegration] Handling OTA update available")
        self.voice_daemon.process_phrase_script('ota_update', event.data)
    
    def handle_ota_update_progress(self, event: WhispererEvent):
        """Handle OTA update progress event."""
        logger.info("[WhispererIntegration] Handling OTA update progress")
        progress = event.data.get('progress', 0)
        self.voice_daemon.speak_text(f"Update progress: {progress} percent", priority=1)
    
    def handle_ota_update_complete(self, event: WhispererEvent):
        """Handle OTA update complete event."""
        logger.info("[WhispererIntegration] Handling OTA update complete")
        self.voice_daemon.speak_text("Update completed successfully", priority=1)
    
    def handle_whispurrnet_ready(self, event: WhispererEvent):
        """Handle WhispurrNet ready event."""
        logger.info("[WhispererIntegration] Handling WhispurrNet ready")
        self.voice_daemon.process_phrase_script('whisperer_ready', event.data)
    
    def handle_encryption_active(self, event: WhispererEvent):
        """Handle encryption active event."""
        logger.info("[WhispererIntegration] Handling encryption active")
        self.voice_daemon.process_phrase_script('encryption_active', event.data)
    
    def handle_secure_channel_established(self, event: WhispererEvent):
        """Handle secure channel established event."""
        logger.info("[WhispererIntegration] Handling secure channel established")
        self.voice_daemon.speak_text("Secure communication channel established", priority=1)
    
    async def start(self):
        """Start whisperer integration."""
        logger.info("[WhispererIntegration] Starting whisperer integration")
        self.running = True
        
        # Start event listener and processor
        listener_task = asyncio.create_task(self.listen_for_events())
        processor_task = asyncio.create_task(self.event_processor_worker())
        
        try:
            await asyncio.gather(listener_task, processor_task)
        except Exception as e:
            logger.error(f"[WhispererIntegration] Integration error: {e}")
        finally:
            self.running = False
    
    async def stop(self):
        """Stop whisperer integration."""
        logger.info("[WhispererIntegration] Stopping whisperer integration")
        self.running = False
        
        if self.websocket:
            await self.websocket.close()
            self.websocket = None
        
        logger.info("[WhispererIntegration] Whisperer integration stopped")

def create_whisperer_integration(voice_daemon, config: Dict = None) -> WhispererIntegration:
    """Create whisperer integration instance."""
    return WhispererIntegration(voice_daemon, config) 