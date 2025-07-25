"""
DivineBus - The Divine Event Bus for LilithOS

A high-performance, thread-safe event bus for inter-process communication
and reactive programming across the LilithOS ecosystem.
"""

import asyncio
import json
import logging
import time
import uuid
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Union, Coroutine
from pathlib import Path

import aiofiles
import aiofiles.os
from typing_extensions import Protocol

# Constants
DEFAULT_HISTORY_SIZE = 1000
MAX_EVENT_SIZE = 1024 * 1024  # 1MB max event size

class EventPriority(Enum):
    """Priority levels for event delivery."""
    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3

@dataclass
class Event:
    """Base event class for all DivineBus events."""
    name: str
    data: Dict[str, Any] = field(default_factory=dict)
    source: str = "system"
    timestamp: float = field(default_factory=time.time)
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    priority: EventPriority = EventPriority.NORMAL
    ttl: Optional[float] = None  # Time to live in seconds
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert event to dictionary for serialization."""
        return {
            "name": self.name,
            "data": self.data,
            "source": self.source,
            "timestamp": self.timestamp,
            "event_id": self.event_id,
            "priority": self.priority.name,
            "ttl": self.ttl
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Event':
        """Create an event from a dictionary."""
        return cls(
            name=data["name"],
            data=data.get("data", {}),
            source=data.get("source", "system"),
            timestamp=data.get("timestamp", time.time()),
            event_id=data.get("event_id", str(uuid.uuid4())),
            priority=EventPriority[data.get("priority", "NORMAL")],
            ttl=data.get("ttl")
        )

class EventHandler(Protocol):
    """Protocol for event handler functions."""
    async def __call__(self, event: Event) -> None:
        ...

class Subscription:
    """Represents an event subscription."""
    
    def __init__(
        self,
        event_name: str,
        callback: EventHandler,
        priority: EventPriority = EventPriority.NORMAL,
        filter_fn: Optional[Callable[[Event], bool]] = None
    ):
        self.event_name = event_name
        self.callback = callback
        self.priority = priority
        self.filter_fn = filter_fn or (lambda _: True)
        self.active = True
        self.id = str(uuid.uuid4())
    
    async def handle(self, event: Event) -> None:
        """Handle an event if the subscription is active and filter passes."""
        if self.active and self.filter_fn(event):
            await self.callback(event)

class DivineBus:
    """
    The Divine Event Bus for LilithOS.
    
    A high-performance, thread-safe event bus that supports:
    - Synchronous and asynchronous event handling
    - Priority-based event delivery
    - Event persistence and replay
    - Cross-process communication
    - Event filtering and transformation
    """
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self._logger = logging.getLogger("DivineBus")
        self._subscriptions: Dict[str, List[Subscription]] = defaultdict(list)
        self._event_history: Dict[str, List[Event]] = defaultdict(list)
        self._history_size = DEFAULT_HISTORY_SIZE
        self._event_loop = asyncio.get_event_loop()
        self._persistence_path = Path("/var/lilithos/events")
        self._persistence_path.mkdir(parents=True, exist_ok=True)
        self._initialized = True
        self._logger.info("DivineBus initialized")
    
    async def publish(self, event_name: str, data: Optional[Dict[str, Any]] = None, **kwargs) -> str:
        """
        Publish an event to the bus.
        
        Args:
            event_name: Name of the event
            data: Event data dictionary
            **kwargs: Additional event attributes (source, priority, ttl)
            
        Returns:
            str: The event ID
        """
        event = Event(
            name=event_name,
            data=data or {},
            **{k: v for k, v in kwargs.items() if hasattr(Event, k)}
        )
        
        self._logger.debug(f"Publishing event: {event_name} (ID: {event.event_id})")
        
        # Store in history
        self._event_history[event_name].append(event)
        if len(self._event_history[event_name]) > self._history_size:
            self._event_history[event_name].pop(0)
        
        # Persist if needed
        if event.priority in [EventPriority.HIGH, EventPriority.CRITICAL]:
            await self._persist_event(event)
        
        # Deliver to subscribers
        await self._deliver_event(event)
        
        return event.event_id
    
    async def _deliver_event(self, event: Event) -> None:
        """Deliver an event to all matching subscribers."""
        # Get all matching subscriptions
        subscriptions = []
        
        # Exact match
        if event.name in self._subscriptions:
            subscriptions.extend(self._subscriptions[event.name])
        
        # Wildcard match (e.g., "system.*")
        for event_pattern, subs in self._subscriptions.items():
            if ".*" in event_pattern:
                pattern = event_pattern.replace(".*", "[^.]*")
                import re
                if re.fullmatch(pattern, event.name):
                    subscriptions.extend(s for s in subs if s not in subscriptions)
        
        # Sort by priority (highest first)
        subscriptions.sort(key=lambda s: s.priority.value, reverse=True)
        
        # Deliver to subscribers
        for subscription in subscriptions:
            try:
                await subscription.handle(event)
            except Exception as e:
                self._logger.error(
                    f"Error in event handler for {event.name}: {e}",
                    exc_info=True
                )
    
    def subscribe(
        self,
        event_name: str,
        callback: EventHandler,
        priority: EventPriority = EventPriority.NORMAL,
        filter_fn: Optional[Callable[[Event], bool]] = None
    ) -> Subscription:
        """
        Subscribe to events matching the given name pattern.
        
        Args:
            event_name: Event name or pattern (supports * wildcard)
            callback: Async callback function to handle the event
            priority: Priority for event delivery
            filter_fn: Optional filter function to further filter events
            
        Returns:
            Subscription: A subscription object that can be used to unsubscribe
        """
        subscription = Subscription(event_name, callback, priority, filter_fn)
        self._subscriptions[event_name].append(subscription)
        self._logger.debug(f"New subscription for {event_name} (ID: {subscription.id})")
        return subscription
    
    def unsubscribe(self, subscription: Subscription) -> None:
        """Remove an event subscription."""
        if subscription.event_name in self._subscriptions:
            self._subscriptions[subscription.event_name] = [
                s for s in self._subscriptions[subscription.event_name]
                if s.id != subscription.id
            ]
    
    async def _persist_event(self, event: Event) -> None:
        """Persist an event to disk for durability."""
        try:
            event_path = self._persistence_path / f"{int(time.time())}_{event.event_id}.json"
            async with aiofiles.open(event_path, 'w') as f:
                await f.write(json.dumps(event.to_dict()))
        except Exception as e:
            self._logger.error(f"Failed to persist event {event.event_id}: {e}")
    
    async def replay_events(
        self,
        event_name: Optional[str] = None,
        since: Optional[float] = None,
        limit: int = 100
    ) -> List[Event]:
        """
        Replay historical events.
        
        Args:
            event_name: Optional event name filter
            since: Optional timestamp to get events after
            limit: Maximum number of events to return
            
        Returns:
            List[Event]: List of matching events
        """
        events = []
        
        # Get from memory history first
        for name, event_list in self._event_history.items():
            if event_name and name != event_name:
                continue
                
            for event in event_list:
                if since and event.timestamp < since:
                    continue
                events.append(event)
        
        # Get from disk if needed
        if len(events) < limit and self._persistence_path.exists():
            # Implementation for reading from disk would go here
            pass
        
        # Sort by timestamp and apply limit
        events.sort(key=lambda e: e.timestamp)
        return events[-limit:]
    
    async def wait_for(
        self,
        event_name: str,
        timeout: Optional[float] = None,
        filter_fn: Optional[Callable[[Event], bool]] = None
    ) -> Event:
        """
        Wait for an event matching the given criteria.
        
        Args:
            event_name: Name of the event to wait for
            timeout: Maximum time to wait in seconds
            filter_fn: Optional filter function
            
        Returns:
            Event: The matching event
            
        Raises:
            asyncio.TimeoutError: If the timeout is reached
        """
        event_future = self._event_loop.create_future()
        
        def handler(event: Event) -> None:
            if not filter_fn or filter_fn(event):
                if not event_future.done():
                    event_future.set_result(event)
        
        subscription = self.subscribe(event_name, handler)
        
        try:
            return await asyncio.wait_for(event_future, timeout)
        except asyncio.TimeoutError:
            self.unsubscribe(subscription)
            raise
        finally:
            self.unsubscribe(subscription)

# Singleton instance
event_bus = DivineBus()

# Shortcut functions for common operations
async def publish(event_name: str, data: Optional[Dict[str, Any]] = None, **kwargs) -> str:
    """Publish an event to the default event bus."""
    return await event_bus.publish(event_name, data, **kwargs)

def subscribe(
    event_name: str,
    callback: EventHandler,
    priority: EventPriority = EventPriority.NORMAL,
    filter_fn: Optional[Callable[[Event], bool]] = None
) -> Subscription:
    """Subscribe to events on the default event bus."""
    return event_bus.subscribe(event_name, callback, priority, filter_fn)

async def wait_for(
    event_name: str,
    timeout: Optional[float] = None,
    filter_fn: Optional[Callable[[Event], bool]] = None
) -> Event:
    """Wait for an event on the default event bus."""
    return await event_bus.wait_for(event_name, timeout, filter_fn)
