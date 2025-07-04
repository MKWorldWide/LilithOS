"""
LilithOS Events Manager
======================

Handles event-driven architecture:
- Event publishing and subscription
- Event routing and filtering
- Event persistence and replay
- Event monitoring and analytics
- Event-driven workflows
"""

import os
import asyncio
import logging
import threading
import time
import json
import uuid
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable, Union
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict
import weakref

class EventPriority(Enum):
    """Event priority levels"""
    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3

class EventType(Enum):
    """Event type enumeration"""
    SYSTEM = "system"
    MODULE = "module"
    SECURITY = "security"
    PERFORMANCE = "performance"
    NETWORK = "network"
    STORAGE = "storage"
    USER = "user"
    CUSTOM = "custom"

@dataclass
class Event:
    """Event container"""
    id: str
    type: EventType
    name: str
    data: Dict[str, Any]
    priority: EventPriority = EventPriority.NORMAL
    timestamp: float = field(default_factory=time.time)
    source: str = ""
    target: Optional[str] = None
    correlation_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class EventHandler:
    """Event handler information"""
    id: str
    callback: Callable
    event_types: List[EventType]
    event_names: List[str]
    priority: EventPriority
    async_handler: bool
    created_at: float = field(default_factory=time.time)

@dataclass
class EventStats:
    """Event statistics"""
    total_events: int = 0
    events_by_type: Dict[str, int] = field(default_factory=dict)
    events_by_priority: Dict[str, int] = field(default_factory=dict)
    active_handlers: int = 0
    events_per_second: float = 0.0
    average_processing_time: float = 0.0

class EventBus:
    """Core event bus for event routing"""
    
    def __init__(self, events_manager: 'EventsManager'):
        self.events_manager = events_manager
        self.handlers: Dict[str, EventHandler] = {}
        self.event_queue: asyncio.Queue = asyncio.Queue()
        self.processing_task = None
        self.running = False
        self.lock = threading.RLock()
        
        # Event type and name filters
        self.type_handlers: Dict[EventType, List[str]] = defaultdict(list)
        self.name_handlers: Dict[str, List[str]] = defaultdict(list)
    
    async def start(self):
        """Start the event bus"""
        try:
            self.running = True
            self.processing_task = asyncio.create_task(self._process_events())
            self.events_manager.logger.info("Event bus started successfully")
            
        except Exception as e:
            self.events_manager.logger.error(f"Failed to start event bus: {e}")
    
    async def stop(self):
        """Stop the event bus"""
        try:
            self.running = False
            if self.processing_task:
                self.processing_task.cancel()
                try:
                    await self.processing_task
                except asyncio.CancelledError:
                    pass
            
            self.events_manager.logger.info("Event bus stopped successfully")
            
        except Exception as e:
            self.events_manager.logger.error(f"Failed to stop event bus: {e}")
    
    async def _process_events(self):
        """Process events from the queue"""
        while self.running:
            try:
                # Get event from queue with timeout
                try:
                    event = await asyncio.wait_for(self.event_queue.get(), timeout=1.0)
                except asyncio.TimeoutError:
                    continue
                
                # Process event
                await self._handle_event(event)
                
                # Mark task as done
                self.event_queue.task_done()
                
            except Exception as e:
                self.events_manager.logger.error(f"Event processing error: {e}")
                await asyncio.sleep(0.1)
    
    async def _handle_event(self, event: Event):
        """Handle a single event"""
        try:
            start_time = time.time()
            
            # Find handlers for this event
            handlers = self._get_handlers_for_event(event)
            
            # Execute handlers
            tasks = []
            for handler in handlers:
                if handler.async_handler:
                    task = asyncio.create_task(self._execute_handler(handler, event))
                    tasks.append(task)
                else:
                    # Run sync handler in thread pool
                    loop = asyncio.get_event_loop()
                    task = loop.run_in_executor(None, self._execute_handler_sync, handler, event)
                    tasks.append(task)
            
            # Wait for all handlers to complete
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
            
            # Update statistics
            processing_time = time.time() - start_time
            self.events_manager._update_processing_stats(processing_time)
            
        except Exception as e:
            self.events_manager.logger.error(f"Event handling error: {e}")
    
    def _get_handlers_for_event(self, event: Event) -> List[EventHandler]:
        """Get handlers that should process this event"""
        handlers = []
        
        # Get handlers by event type
        type_handlers = self.type_handlers.get(event.type, [])
        for handler_id in type_handlers:
            if handler_id in self.handlers:
                handler = self.handlers[handler_id]
                if event.name in handler.event_names or not handler.event_names:
                    handlers.append(handler)
        
        # Get handlers by event name
        name_handlers = self.name_handlers.get(event.name, [])
        for handler_id in name_handlers:
            if handler_id in self.handlers:
                handler = self.handlers[handler_id]
                if event.type in handler.event_types or not handler.event_types:
                    handlers.append(handler)
        
        # Sort by priority
        handlers.sort(key=lambda h: h.priority.value, reverse=True)
        
        return handlers
    
    async def _execute_handler(self, handler: EventHandler, event: Event):
        """Execute an async event handler"""
        try:
            await handler.callback(event)
        except Exception as e:
            self.events_manager.logger.error(f"Handler {handler.id} error: {e}")
    
    def _execute_handler_sync(self, handler: EventHandler, event: Event):
        """Execute a sync event handler"""
        try:
            handler.callback(event)
        except Exception as e:
            self.events_manager.logger.error(f"Handler {handler.id} error: {e}")
    
    async def publish(self, event: Event):
        """Publish an event to the bus"""
        try:
            await self.event_queue.put(event)
            self.events_manager._update_event_stats(event)
            
        except Exception as e:
            self.events_manager.logger.error(f"Failed to publish event: {e}")
    
    def register_handler(self, handler: EventHandler):
        """Register an event handler"""
        try:
            with self.lock:
                self.handlers[handler.id] = handler
                
                # Register by event type
                for event_type in handler.event_types:
                    self.type_handlers[event_type].append(handler.id)
                
                # Register by event name
                for event_name in handler.event_names:
                    self.name_handlers[event_name].append(handler.id)
                
                self.events_manager.logger.info(f"Registered event handler: {handler.id}")
                
        except Exception as e:
            self.events_manager.logger.error(f"Failed to register handler: {e}")
    
    def unregister_handler(self, handler_id: str):
        """Unregister an event handler"""
        try:
            with self.lock:
                if handler_id in self.handlers:
                    handler = self.handlers[handler_id]
                    
                    # Remove from type handlers
                    for event_type in handler.event_types:
                        if handler_id in self.type_handlers[event_type]:
                            self.type_handlers[event_type].remove(handler_id)
                    
                    # Remove from name handlers
                    for event_name in handler.event_names:
                        if handler_id in self.name_handlers[event_name]:
                            self.name_handlers[event_name].remove(handler_id)
                    
                    # Remove handler
                    del self.handlers[handler_id]
                    
                    self.events_manager.logger.info(f"Unregistered event handler: {handler_id}")
                    
        except Exception as e:
            self.events_manager.logger.error(f"Failed to unregister handler: {e}")

class EventPersister:
    """Handles event persistence and replay"""
    
    def __init__(self, events_manager: 'EventsManager'):
        self.events_manager = events_manager
        self.persistence_path = Path("data/events")
        self.persistence_path.mkdir(parents=True, exist_ok=True)
        self.max_events = 10000
        self.events_file = self.persistence_path / "events.jsonl"
    
    async def persist_event(self, event: Event):
        """Persist an event to storage"""
        try:
            event_data = {
                "id": event.id,
                "type": event.type.value,
                "name": event.name,
                "data": event.data,
                "priority": event.priority.value,
                "timestamp": event.timestamp,
                "source": event.source,
                "target": event.target,
                "correlation_id": event.correlation_id,
                "metadata": event.metadata
            }
            
            with open(self.events_file, 'a', encoding='utf-8') as f:
                f.write(json.dumps(event_data) + '\n')
            
            # Cleanup old events if needed
            await self._cleanup_old_events()
            
        except Exception as e:
            self.events_manager.logger.error(f"Failed to persist event: {e}")
    
    async def load_events(self, start_time: Optional[float] = None, end_time: Optional[float] = None) -> List[Event]:
        """Load events from storage"""
        try:
            events = []
            
            if not self.events_file.exists():
                return events
            
            with open(self.events_file, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        event_data = json.loads(line.strip())
                        
                        # Apply time filters
                        if start_time and event_data["timestamp"] < start_time:
                            continue
                        if end_time and event_data["timestamp"] > end_time:
                            continue
                        
                        event = Event(
                            id=event_data["id"],
                            type=EventType(event_data["type"]),
                            name=event_data["name"],
                            data=event_data["data"],
                            priority=EventPriority(event_data["priority"]),
                            timestamp=event_data["timestamp"],
                            source=event_data["source"],
                            target=event_data.get("target"),
                            correlation_id=event_data.get("correlation_id"),
                            metadata=event_data.get("metadata", {})
                        )
                        events.append(event)
                        
                    except json.JSONDecodeError:
                        continue
            
            return events
            
        except Exception as e:
            self.events_manager.logger.error(f"Failed to load events: {e}")
            return []
    
    async def _cleanup_old_events(self):
        """Remove old events to maintain storage limits"""
        try:
            if not self.events_file.exists():
                return
            
            # Read all events
            events = []
            with open(self.events_file, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        events.append(json.loads(line.strip()))
                    except json.JSONDecodeError:
                        continue
            
            # Keep only recent events
            if len(events) > self.max_events:
                events = events[-self.max_events:]
                
                # Rewrite file
                with open(self.events_file, 'w', encoding='utf-8') as f:
                    for event_data in events:
                        f.write(json.dumps(event_data) + '\n')
                
                self.events_manager.logger.info(f"Cleaned up {len(events)} events")
                
        except Exception as e:
            self.events_manager.logger.error(f"Failed to cleanup events: {e}")

class EventsManager:
    """
    LilithOS Events Manager
    
    Manages event-driven architecture:
    - Event publishing and subscription
    - Event routing and filtering
    - Event persistence and replay
    - Event monitoring and analytics
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("EventsManager")
        self.event_bus = EventBus(self)
        self.persister = EventPersister(self)
        self.stats = EventStats()
        self.processing_times: List[float] = []
        self.event_count = 0
        self.last_event_time = time.time()
        
        # Event rate calculation
        self.event_times: List[float] = []
        self.rate_window = 60  # 1 minute
    
    async def start(self) -> bool:
        """Start the events manager"""
        try:
            self.logger.info("Starting Events Manager...")
            
            # Start event bus
            await self.event_bus.start()
            
            # Start statistics update task
            asyncio.create_task(self._update_stats_loop())
            
            self.logger.info("Events Manager started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start Events Manager: {e}")
            return False
    
    async def stop(self) -> bool:
        """Stop the events manager"""
        try:
            self.logger.info("Stopping Events Manager...")
            
            # Stop event bus
            await self.event_bus.stop()
            
            self.logger.info("Events Manager stopped successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to stop Events Manager: {e}")
            return False
    
    async def publish_event(self, event_type: EventType, name: str, data: Dict[str, Any], 
                          priority: EventPriority = EventPriority.NORMAL, source: str = "",
                          target: Optional[str] = None, correlation_id: Optional[str] = None,
                          metadata: Dict[str, Any] = None) -> str:
        """Publish an event"""
        try:
            event = Event(
                id=str(uuid.uuid4()),
                type=event_type,
                name=name,
                data=data,
                priority=priority,
                timestamp=time.time(),
                source=source,
                target=target,
                correlation_id=correlation_id,
                metadata=metadata or {}
            )
            
            # Publish to event bus
            await self.event_bus.publish(event)
            
            # Persist event
            await self.persister.persist_event(event)
            
            self.logger.debug(f"Published event: {event.name} ({event.id})")
            return event.id
            
        except Exception as e:
            self.logger.error(f"Failed to publish event: {e}")
            return ""
    
    def subscribe(self, callback: Callable, event_types: Optional[List[EventType]] = None,
                 event_names: Optional[List[str]] = None, priority: EventPriority = EventPriority.NORMAL) -> str:
        """Subscribe to events"""
        try:
            handler_id = str(uuid.uuid4())
            
            # Determine if callback is async
            async_handler = asyncio.iscoroutinefunction(callback)
            
            handler = EventHandler(
                id=handler_id,
                callback=callback,
                event_types=event_types or [],
                event_names=event_names or [],
                priority=priority,
                async_handler=async_handler
            )
            
            # Register handler
            self.event_bus.register_handler(handler)
            
            return handler_id
            
        except Exception as e:
            self.logger.error(f"Failed to subscribe to events: {e}")
            return ""
    
    def unsubscribe(self, handler_id: str) -> bool:
        """Unsubscribe from events"""
        try:
            self.event_bus.unregister_handler(handler_id)
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to unsubscribe: {e}")
            return False
    
    async def replay_events(self, start_time: Optional[float] = None, end_time: Optional[float] = None):
        """Replay events from storage"""
        try:
            events = await self.persister.load_events(start_time, end_time)
            
            for event in events:
                await self.event_bus.publish(event)
            
            self.logger.info(f"Replayed {len(events)} events")
            
        except Exception as e:
            self.logger.error(f"Failed to replay events: {e}")
    
    def _update_event_stats(self, event: Event):
        """Update event statistics"""
        try:
            self.event_count += 1
            self.last_event_time = time.time()
            
            # Update type statistics
            event_type_str = event.type.value
            self.stats.events_by_type[event_type_str] = self.stats.events_by_type.get(event_type_str, 0) + 1
            
            # Update priority statistics
            priority_str = event.priority.value
            self.stats.events_by_priority[priority_str] = self.stats.events_by_priority.get(priority_str, 0) + 1
            
            # Update event times for rate calculation
            self.event_times.append(time.time())
            
            # Remove old event times
            cutoff_time = time.time() - self.rate_window
            self.event_times = [t for t in self.event_times if t > cutoff_time]
            
        except Exception as e:
            self.logger.error(f"Failed to update event stats: {e}")
    
    def _update_processing_stats(self, processing_time: float):
        """Update processing statistics"""
        try:
            self.processing_times.append(processing_time)
            
            # Keep only recent processing times
            if len(self.processing_times) > 1000:
                self.processing_times = self.processing_times[-1000:]
            
        except Exception as e:
            self.logger.error(f"Failed to update processing stats: {e}")
    
    async def _update_stats_loop(self):
        """Update statistics periodically"""
        while True:
            try:
                # Calculate events per second
                if self.event_times:
                    self.stats.events_per_second = len(self.event_times) / self.rate_window
                
                # Calculate average processing time
                if self.processing_times:
                    self.stats.average_processing_time = sum(self.processing_times) / len(self.processing_times)
                
                # Update total events
                self.stats.total_events = self.event_count
                
                # Update active handlers
                self.stats.active_handlers = len(self.event_bus.handlers)
                
                await asyncio.sleep(10)  # Update every 10 seconds
                
            except Exception as e:
                self.logger.error(f"Stats update error: {e}")
                await asyncio.sleep(30)
    
    def get_event_stats(self) -> Dict[str, Any]:
        """Get event statistics"""
        return {
            "total_events": self.stats.total_events,
            "events_by_type": self.stats.events_by_type,
            "events_by_priority": self.stats.events_by_priority,
            "active_handlers": self.stats.active_handlers,
            "events_per_second": self.stats.events_per_second,
            "average_processing_time": self.stats.average_processing_time,
            "last_event_time": self.last_event_time
        }
    
    def get_active_handlers(self) -> List[Dict[str, Any]]:
        """Get information about active event handlers"""
        handlers = []
        for handler in self.event_bus.handlers.values():
            handlers.append({
                "id": handler.id,
                "event_types": [t.value for t in handler.event_types],
                "event_names": handler.event_names,
                "priority": handler.priority.value,
                "async": handler.async_handler,
                "created_at": handler.created_at
            })
        return handlers 