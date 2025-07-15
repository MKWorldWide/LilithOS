#!/usr/bin/env python3
"""
LilithOS Voice Daemon: lilith_voice
===================================
Quantum-detailed Python daemon for TTS, signal-to-speech mapping, and audio output.

📋 Feature Context:
    - Text-to-Speech (TTS) synthesis with multiple voice options
    - Signal-to-speech mapping for system events and notifications
    - Event whisperer integration for real-time audio feedback
    - Audio output management with volume and quality control
    - Phrase scripting for customizable voice responses

🧩 Dependency Listings:
    - Requires pyttsx3 or gTTS for TTS synthesis
    - Integrates with event whisperer system
    - Uses pyaudio for audio output
    - Requires threading for concurrent operations

💡 Usage Example:
    - Run as system daemon: python3 lilith_voice_daemon.py
    - Automatically processes events and generates speech

⚡ Performance Considerations:
    - Non-blocking TTS synthesis
    - Efficient audio buffer management
    - Minimal latency for real-time responses

🔒 Security Implications:
    - Validates audio input/output paths
    - Sanitizes text input for TTS
    - Secure phrase scripting execution

📜 Changelog Entries:
    - v1.0.0: Initial quantum-detailed scaffold
"""

import threading
import time
import json
import logging
import queue
import re
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('lilith_voice.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('LilithVoice')

class VoiceEvent(Enum):
    """Voice event types for signal-to-speech mapping."""
    SYSTEM_STARTUP = "system_startup"
    SYSTEM_SHUTDOWN = "system_shutdown"
    ERROR_OCCURRED = "error_occurred"
    SUCCESS_COMPLETED = "success_completed"
    WARNING_ALERT = "warning_alert"
    USER_INTERACTION = "user_interaction"
    NETWORK_EVENT = "network_event"
    SECURITY_ALERT = "security_alert"

@dataclass
class PhraseScript:
    """Phrase scripting configuration."""
    trigger: str
    response: str
    voice_id: str
    volume: float
    priority: int
    conditions: Dict[str, any]

class LilithVoiceDaemon:
    def __init__(self):
        self.running = True
        self.audio_queue = queue.Queue()
        self.phrase_scripts: List[PhraseScript] = []
        self.voice_config = {
            'default_voice': 'en-US',
            'volume': 0.8,
            'rate': 150,
            'pitch': 1.0
        }
        self.event_whisperer_integration = None
        
    def initialize_tts(self):
        """Initialize TTS engine with configuration."""
        logger.info("[LilithVoice] Initializing TTS engine")
        try:
            # TODO: Initialize pyttsx3 or gTTS
            # import pyttsx3
            # self.tts_engine = pyttsx3.init()
            # self.tts_engine.setProperty('rate', self.voice_config['rate'])
            # self.tts_engine.setProperty('volume', self.voice_config['volume'])
            logger.info("[LilithVoice] TTS engine initialized")
        except Exception as e:
            logger.error(f"[LilithVoice] TTS initialization failed: {e}")
    
    def signal_to_speech_map(self, event: VoiceEvent, data: Dict = None):
        """Map system signals to speech responses."""
        logger.info(f"[LilithVoice] Processing signal: {event.value}")
        
        speech_mapping = {
            VoiceEvent.SYSTEM_STARTUP: "LilithOS system initialized and ready",
            VoiceEvent.SYSTEM_SHUTDOWN: "System shutdown sequence initiated",
            VoiceEvent.ERROR_OCCURRED: f"Error detected: {data.get('message', 'Unknown error')}",
            VoiceEvent.SUCCESS_COMPLETED: "Operation completed successfully",
            VoiceEvent.WARNING_ALERT: f"Warning: {data.get('message', 'System warning')}",
            VoiceEvent.USER_INTERACTION: "User interaction detected",
            VoiceEvent.NETWORK_EVENT: f"Network event: {data.get('type', 'Unknown')}",
            VoiceEvent.SECURITY_ALERT: "Security alert - immediate attention required"
        }
        
        response = speech_mapping.get(event, "Unknown event occurred")
        self.speak_text(response, priority=event.value)
    
    def speak_text(self, text: str, voice_id: str = None, volume: float = None, priority: int = 1):
        """Convert text to speech and queue for output."""
        logger.info(f"[LilithVoice] Speaking: {text[:50]}...")
        
        # Sanitize text input
        sanitized_text = self.sanitize_text(text)
        
        # Add to audio queue
        audio_request = {
            'text': sanitized_text,
            'voice_id': voice_id or self.voice_config['default_voice'],
            'volume': volume or self.voice_config['volume'],
            'priority': priority,
            'timestamp': time.time()
        }
        
        self.audio_queue.put(audio_request)
    
    def sanitize_text(self, text: str) -> str:
        """Sanitize text input for TTS synthesis."""
        # Remove potentially dangerous characters
        sanitized = re.sub(r'[<>"\']', '', text)
        # Limit length
        if len(sanitized) > 500:
            sanitized = sanitized[:500] + "..."
        return sanitized
    
    def load_phrase_scripts(self, script_file: str = "phrase_scripts.json"):
        """Load phrase scripting configuration."""
        logger.info("[LilithVoice] Loading phrase scripts")
        try:
            with open(script_file, 'r') as f:
                scripts_data = json.load(f)
                
            for script_data in scripts_data:
                script = PhraseScript(
                    trigger=script_data['trigger'],
                    response=script_data['response'],
                    voice_id=script_data.get('voice_id', 'en-US'),
                    volume=script_data.get('volume', 0.8),
                    priority=script_data.get('priority', 1),
                    conditions=script_data.get('conditions', {})
                )
                self.phrase_scripts.append(script)
                
            logger.info(f"[LilithVoice] Loaded {len(self.phrase_scripts)} phrase scripts")
        except FileNotFoundError:
            logger.warning("[LilithVoice] Phrase scripts file not found, using defaults")
            self.create_default_scripts()
        except Exception as e:
            logger.error(f"[LilithVoice] Failed to load phrase scripts: {e}")
    
    def create_default_scripts(self):
        """Create default phrase scripts."""
        default_scripts = [
            PhraseScript("hello", "Hello, I am Lilith Voice", "en-US", 0.8, 1, {}),
            PhraseScript("status", "System status is operational", "en-US", 0.8, 1, {}),
            PhraseScript("error", "An error has occurred", "en-US", 0.9, 2, {}),
            PhraseScript("success", "Operation completed successfully", "en-US", 0.8, 1, {})
        ]
        self.phrase_scripts.extend(default_scripts)
    
    def process_phrase_script(self, trigger: str, context: Dict = None):
        """Process phrase script based on trigger."""
        logger.info(f"[LilithVoice] Processing phrase script: {trigger}")
        
        for script in self.phrase_scripts:
            if script.trigger.lower() == trigger.lower():
                # Check conditions
                if self.evaluate_conditions(script.conditions, context):
                    self.speak_text(
                        script.response,
                        voice_id=script.voice_id,
                        volume=script.volume,
                        priority=script.priority
                    )
                    return True
        
        return False
    
    def evaluate_conditions(self, conditions: Dict, context: Dict) -> bool:
        """Evaluate script conditions against context."""
        if not conditions:
            return True
            
        for key, value in conditions.items():
            if context and key in context:
                if context[key] != value:
                    return False
            else:
                return False
        return True
    
    def audio_output_worker(self):
        """Worker thread for audio output processing."""
        logger.info("[LilithVoice] Audio output worker started")
        
        while self.running:
            try:
                # Get audio request from queue
                audio_request = self.audio_queue.get(timeout=1)
                
                # Process TTS synthesis
                self.synthesize_and_play(audio_request)
                
                self.audio_queue.task_done()
                
            except queue.Empty:
                continue
            except Exception as e:
                logger.error(f"[LilithVoice] Audio output error: {e}")
        
        logger.info("[LilithVoice] Audio output worker stopped")
    
    def synthesize_and_play(self, audio_request: Dict):
        """Synthesize text to speech and play audio."""
        logger.info(f"[LilithVoice] Synthesizing: {audio_request['text'][:30]}...")
        
        try:
            # TODO: Implement actual TTS synthesis
            # self.tts_engine.say(audio_request['text'])
            # self.tts_engine.runAndWait()
            
            # Simulate synthesis delay
            time.sleep(0.1)
            
            logger.info(f"[LilithVoice] Audio played: {audio_request['text'][:30]}...")
            
        except Exception as e:
            logger.error(f"[LilithVoice] TTS synthesis failed: {e}")
    
    def integrate_with_whisperer(self, whisperer_callback: Callable):
        """Integrate with event whisperer system."""
        logger.info("[LilithVoice] Integrating with event whisperer")
        self.event_whisperer_integration = whisperer_callback
        
        # Register voice events with whisperer
        if whisperer_callback:
            whisperer_callback('voice_ready', {'status': 'initialized'})
    
    def handle_whisperer_event(self, event_type: str, data: Dict):
        """Handle events from whisperer system."""
        logger.info(f"[LilithVoice] Whisperer event: {event_type}")
        
        # Map whisperer events to voice responses
        if event_type == 'system_startup':
            self.signal_to_speech_map(VoiceEvent.SYSTEM_STARTUP, data)
        elif event_type == 'error_detected':
            self.signal_to_speech_map(VoiceEvent.ERROR_OCCURRED, data)
        elif event_type == 'success_completed':
            self.signal_to_speech_map(VoiceEvent.SUCCESS_COMPLETED, data)
        elif event_type == 'security_alert':
            self.signal_to_speech_map(VoiceEvent.SECURITY_ALERT, data)
        else:
            # Try phrase script processing
            self.process_phrase_script(event_type, data)
    
    def run_daemon(self):
        """Main daemon loop."""
        logger.info("[LilithVoice] Daemon started")
        
        # Initialize TTS
        self.initialize_tts()
        
        # Load phrase scripts
        self.load_phrase_scripts()
        
        # Start audio output worker
        audio_thread = threading.Thread(target=self.audio_output_worker)
        audio_thread.daemon = True
        audio_thread.start()
        
        try:
            while self.running:
                # Main daemon loop
                time.sleep(1)
                
                # Process any pending events
                # This would typically come from event whisperer
                
        except KeyboardInterrupt:
            logger.info("[LilithVoice] Daemon stopping...")
            self.running = False
        
        logger.info("[LilithVoice] Daemon stopped")

def main():
    """Main entry point for Lilith Voice daemon."""
    daemon = LilithVoiceDaemon()
    daemon.run_daemon()

if __name__ == "__main__":
    main() 