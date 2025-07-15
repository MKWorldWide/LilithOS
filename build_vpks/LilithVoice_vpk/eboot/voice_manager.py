#!/usr/bin/env python3
"""
LilithOS Voice Manager: voice_manager.py
========================================
High-level voice management interface for TTS operations and audio control.

📋 Feature Context:
    - Centralized voice management for all LilithOS components
    - TTS engine abstraction with multiple backend support
    - Audio output management and device control
    - Integration with event whisperer and other daemons
    - Voice profile management and customization

🧩 Dependency Listings:
    - Integrates with lilith_voice_daemon.py
    - Uses voice_config.yaml for configuration
    - Connects to event whisperer system
    - Manages audio output devices

💡 Usage Example:
    - Import and use: from voice_manager import VoiceManager
    - Initialize: vm = VoiceManager()
    - Speak: vm.speak("Hello, LilithOS")

⚡ Performance Considerations:
    - Efficient TTS engine management
    - Audio buffer optimization
    - Non-blocking operations

🔒 Security Implications:
    - Input validation and sanitization
    - Secure audio device access
    - Protected voice profile management

📜 Changelog Entries:
    - v1.0.0: Initial quantum-detailed scaffold
"""

import yaml
import logging
import threading
import time
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger('VoiceManager')

class TTSBackend(Enum):
    """TTS backend types."""
    PYTTSX3 = "pyttsx3"
    GTTS = "gTTS"
    ESPEAK = "espeak"
    AZURE = "azure"
    GOOGLE = "google"

@dataclass
class VoiceProfile:
    """Voice profile configuration."""
    name: str
    voice_id: str
    rate: int
    volume: float
    pitch: float
    backend: TTSBackend

class VoiceManager:
    def __init__(self, config_file: str = "voice_config.yaml"):
        """Initialize voice manager with configuration."""
        self.config = self.load_config(config_file)
        self.tts_engine = None
        self.voice_profiles: Dict[str, VoiceProfile] = {}
        self.current_profile = "default"
        self.audio_devices = []
        self.is_initialized = False
        
        # Initialize components
        self.initialize_voice_profiles()
        self.initialize_tts_engine()
        self.scan_audio_devices()
        
    def load_config(self, config_file: str) -> Dict:
        """Load configuration from YAML file."""
        try:
            with open(config_file, 'r') as f:
                config = yaml.safe_load(f)
            logger.info(f"[VoiceManager] Configuration loaded from {config_file}")
            return config
        except FileNotFoundError:
            logger.warning(f"[VoiceManager] Config file {config_file} not found, using defaults")
            return self.get_default_config()
        except Exception as e:
            logger.error(f"[VoiceManager] Failed to load config: {e}")
            return self.get_default_config()
    
    def get_default_config(self) -> Dict:
        """Get default configuration."""
        return {
            'tts_engine': {
                'type': 'pyttsx3',
                'default_voice': 'en-US',
                'rate': 150,
                'volume': 0.8,
                'pitch': 1.0
            },
            'voice_customization': {
                'profiles': {
                    'default': {
                        'voice_id': 'en-US',
                        'rate': 150,
                        'volume': 0.8,
                        'pitch': 1.0
                    }
                }
            }
        }
    
    def initialize_voice_profiles(self):
        """Initialize voice profiles from configuration."""
        logger.info("[VoiceManager] Initializing voice profiles")
        
        profiles_config = self.config.get('voice_customization', {}).get('profiles', {})
        
        for profile_name, profile_config in profiles_config.items():
            profile = VoiceProfile(
                name=profile_name,
                voice_id=profile_config.get('voice_id', 'en-US'),
                rate=profile_config.get('rate', 150),
                volume=profile_config.get('volume', 0.8),
                pitch=profile_config.get('pitch', 1.0),
                backend=TTSBackend.PYTTSX3  # Default backend
            )
            self.voice_profiles[profile_name] = profile
        
        logger.info(f"[VoiceManager] Initialized {len(self.voice_profiles)} voice profiles")
    
    def initialize_tts_engine(self):
        """Initialize TTS engine based on configuration."""
        logger.info("[VoiceManager] Initializing TTS engine")
        
        tts_config = self.config.get('tts_engine', {})
        engine_type = tts_config.get('type', 'pyttsx3')
        
        try:
            if engine_type == 'pyttsx3':
                self.initialize_pyttsx3(tts_config)
            elif engine_type == 'gTTS':
                self.initialize_gtts(tts_config)
            elif engine_type == 'espeak':
                self.initialize_espeak(tts_config)
            else:
                logger.warning(f"[VoiceManager] Unknown TTS engine type: {engine_type}")
                self.initialize_pyttsx3(tts_config)
                
            self.is_initialized = True
            logger.info(f"[VoiceManager] TTS engine initialized: {engine_type}")
            
        except Exception as e:
            logger.error(f"[VoiceManager] TTS engine initialization failed: {e}")
            self.is_initialized = False
    
    def initialize_pyttsx3(self, config: Dict):
        """Initialize pyttsx3 TTS engine."""
        try:
            import pyttsx3
            self.tts_engine = pyttsx3.init()
            
            # Configure engine properties
            self.tts_engine.setProperty('rate', config.get('rate', 150))
            self.tts_engine.setProperty('volume', config.get('volume', 0.8))
            
            # Set voice
            voices = self.tts_engine.getProperty('voices')
            for voice in voices:
                if config.get('default_voice', 'en-US') in voice.id:
                    self.tts_engine.setProperty('voice', voice.id)
                    break
                    
        except ImportError:
            logger.error("[VoiceManager] pyttsx3 not installed")
            raise
    
    def initialize_gtts(self, config: Dict):
        """Initialize gTTS TTS engine."""
        try:
            from gtts import gTTS
            self.gtts_engine = gTTS
            self.gtts_config = config
        except ImportError:
            logger.error("[VoiceManager] gTTS not installed")
            raise
    
    def initialize_espeak(self, config: Dict):
        """Initialize espeak TTS engine."""
        try:
            import subprocess
            self.espeak_config = config
            self.espeak_available = subprocess.run(['which', 'espeak'], 
                                                 capture_output=True).returncode == 0
            if not self.espeak_available:
                logger.error("[VoiceManager] espeak not found in system")
                raise RuntimeError("espeak not available")
        except Exception as e:
            logger.error(f"[VoiceManager] espeak initialization failed: {e}")
            raise
    
    def scan_audio_devices(self):
        """Scan available audio output devices."""
        logger.info("[VoiceManager] Scanning audio devices")
        
        try:
            import pyaudio
            p = pyaudio.PyAudio()
            
            for i in range(p.get_device_count()):
                device_info = p.get_device_info_by_index(i)
                if device_info['maxOutputChannels'] > 0:
                    self.audio_devices.append({
                        'index': i,
                        'name': device_info['name'],
                        'channels': device_info['maxOutputChannels'],
                        'sample_rate': device_info['defaultSampleRate']
                    })
            
            p.terminate()
            logger.info(f"[VoiceManager] Found {len(self.audio_devices)} audio devices")
            
        except ImportError:
            logger.warning("[VoiceManager] pyaudio not available, skipping device scan")
        except Exception as e:
            logger.error(f"[VoiceManager] Audio device scan failed: {e}")
    
    def speak(self, text: str, profile: str = None, blocking: bool = True) -> bool:
        """Speak text using specified voice profile."""
        if not self.is_initialized:
            logger.error("[VoiceManager] TTS engine not initialized")
            return False
        
        # Sanitize input
        sanitized_text = self.sanitize_text(text)
        if not sanitized_text:
            return False
        
        # Get voice profile
        profile_name = profile or self.current_profile
        voice_profile = self.voice_profiles.get(profile_name)
        
        if not voice_profile:
            logger.error(f"[VoiceManager] Voice profile not found: {profile_name}")
            return False
        
        try:
            if self.tts_engine and hasattr(self.tts_engine, 'say'):
                # Use pyttsx3
                self.tts_engine.setProperty('rate', voice_profile.rate)
                self.tts_engine.setProperty('volume', voice_profile.volume)
                self.tts_engine.say(sanitized_text)
                
                if blocking:
                    self.tts_engine.runAndWait()
                else:
                    # Run in separate thread
                    thread = threading.Thread(target=self.tts_engine.runAndWait)
                    thread.daemon = True
                    thread.start()
                
                logger.info(f"[VoiceManager] Spoke text using profile {profile_name}")
                return True
                
            elif hasattr(self, 'gtts_engine'):
                # Use gTTS
                return self.speak_gtts(sanitized_text, voice_profile, blocking)
                
            elif hasattr(self, 'espeak_config'):
                # Use espeak
                return self.speak_espeak(sanitized_text, voice_profile, blocking)
                
        except Exception as e:
            logger.error(f"[VoiceManager] Speech synthesis failed: {e}")
            return False
        
        return False
    
    def speak_gtts(self, text: str, profile: VoiceProfile, blocking: bool) -> bool:
        """Speak text using gTTS."""
        try:
            import tempfile
            import os
            import subprocess
            
            # Create temporary file for audio
            with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as temp_file:
                temp_filename = temp_file.name
            
            # Generate speech
            tts = self.gtts_engine(text=text, lang=profile.voice_id)
            tts.save(temp_filename)
            
            # Play audio
            if blocking:
                subprocess.run(['mpg123', temp_filename], check=True)
            else:
                subprocess.Popen(['mpg123', temp_filename])
            
            # Clean up
            os.unlink(temp_filename)
            return True
            
        except Exception as e:
            logger.error(f"[VoiceManager] gTTS speech failed: {e}")
            return False
    
    def speak_espeak(self, text: str, profile: VoiceProfile, blocking: bool) -> bool:
        """Speak text using espeak."""
        try:
            import subprocess
            
            cmd = [
                'espeak',
                '-s', str(profile.rate),
                '-v', profile.voice_id,
                '-a', str(int(profile.volume * 200)),
                text
            ]
            
            if blocking:
                subprocess.run(cmd, check=True)
            else:
                subprocess.Popen(cmd)
            
            return True
            
        except Exception as e:
            logger.error(f"[VoiceManager] espeak speech failed: {e}")
            return False
    
    def sanitize_text(self, text: str) -> str:
        """Sanitize text input for TTS."""
        if not text or not isinstance(text, str):
            return ""
        
        # Remove potentially dangerous characters
        import re
        sanitized = re.sub(r'[<>"\']', '', text)
        
        # Limit length
        max_length = self.config.get('performance', {}).get('max_text_length', 500)
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length] + "..."
        
        return sanitized.strip()
    
    def set_voice_profile(self, profile_name: str) -> bool:
        """Set active voice profile."""
        if profile_name in self.voice_profiles:
            self.current_profile = profile_name
            logger.info(f"[VoiceManager] Voice profile set to: {profile_name}")
            return True
        else:
            logger.error(f"[VoiceManager] Voice profile not found: {profile_name}")
            return False
    
    def get_voice_profiles(self) -> List[str]:
        """Get list of available voice profiles."""
        return list(self.voice_profiles.keys())
    
    def get_audio_devices(self) -> List[Dict]:
        """Get list of available audio devices."""
        return self.audio_devices.copy()
    
    def test_voice(self, text: str = "Hello, this is a test of the LilithOS voice system") -> bool:
        """Test voice synthesis with sample text."""
        logger.info("[VoiceManager] Testing voice synthesis")
        return self.speak(text, blocking=True)
    
    def shutdown(self):
        """Shutdown voice manager and cleanup resources."""
        logger.info("[VoiceManager] Shutting down voice manager")
        
        if self.tts_engine and hasattr(self.tts_engine, 'stop'):
            self.tts_engine.stop()
        
        self.is_initialized = False
        logger.info("[VoiceManager] Voice manager shutdown complete")

# Convenience functions for easy integration
def create_voice_manager(config_file: str = "voice_config.yaml") -> VoiceManager:
    """Create and initialize voice manager."""
    return VoiceManager(config_file)

def speak_text(text: str, profile: str = None) -> bool:
    """Quick function to speak text using default voice manager."""
    vm = create_voice_manager()
    result = vm.speak(text, profile)
    vm.shutdown()
    return result 