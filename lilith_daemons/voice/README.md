# 🎤 LilithOS Voice Daemon

**Quantum-detailed voice synthesis and audio management system for LilithOS**

## 📋 Overview

The Lilith Voice daemon provides comprehensive Text-to-Speech (TTS) capabilities, signal-to-speech mapping, event whisperer integration, audio output management, and phrase scripting for the LilithOS ecosystem.

### 🎯 Core Features

- **Text-to-Speech Synthesis**: Multiple TTS backends (pyttsx3, gTTS, espeak)
- **Signal-to-Speech Mapping**: Automatic voice responses for system events
- **Event Whisperer Integration**: Real-time event processing and voice feedback
- **Audio Output Management**: Device control, volume management, and quality optimization
- **Phrase Scripting**: Customizable voice responses with conditional triggers
- **Voice Profile Management**: Multiple voice profiles with different characteristics

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Event Input   │───▶│  Voice Daemon    │───▶│  Audio Output   │
│   (Whisperer)   │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  TTS Engine      │
                       │  (pyttsx3/gTTS)  │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  Phrase Scripts  │
                       │  (JSON Config)   │
                       └──────────────────┘
```

## 🚀 Installation

### Prerequisites

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install python3 python3-pip espeak-ng portaudio19-dev

# On macOS
brew install espeak portaudio
```

### Python Dependencies

```bash
# Install Python packages
pip3 install -r requirements.txt

# Or install individually
pip3 install pyttsx3 gTTS pyaudio pyyaml click colorama
```

## 📖 Usage

### Basic Usage

```python
# Import and initialize
from lilith_voice_daemon import LilithVoiceDaemon

# Create daemon instance
daemon = LilithVoiceDaemon()

# Start daemon
daemon.run_daemon()
```

### Voice Manager Usage

```python
# Import voice manager
from voice_manager import VoiceManager

# Create manager
vm = VoiceManager("voice_config.yaml")

# Speak text
vm.speak("Hello, LilithOS!")

# Use specific profile
vm.speak("System alert!", profile="alert")

# Test voice
vm.test_voice()
```

### Whisperer Integration

```python
# Import whisperer integration
from whisperer_integration import WhispererIntegration

# Create integration
wi = WhispererIntegration(voice_daemon, config)

# Start integration
await wi.start()

# Send events
await wi.send_event('system_startup', {'status': 'ready'})
```

## ⚙️ Configuration

### Voice Configuration (voice_config.yaml)

```yaml
# TTS Engine Configuration
tts_engine:
  type: "pyttsx3"  # Options: pyttsx3, gTTS, espeak
  default_voice: "en-US"
  rate: 150        # Words per minute
  volume: 0.8      # Volume level (0.0 to 1.0)
  pitch: 1.0       # Pitch multiplier

# Audio Output Configuration
audio_output:
  device: "default"     # Audio output device
  sample_rate: 44100    # Sample rate in Hz
  channels: 2          # Number of audio channels
  buffer_size: 1024    # Audio buffer size
  format: "int16"      # Audio format

# Voice Event Mapping
voice_events:
  system_startup:
    enabled: true
    response: "LilithOS voice system initialized and ready for commands"
    volume: 0.8
    priority: 1
```

### Phrase Scripts (phrase_scripts.json)

```json
[
  {
    "trigger": "system_startup",
    "response": "LilithOS voice system initialized and ready for commands",
    "voice_id": "en-US",
    "volume": 0.8,
    "priority": 1,
    "conditions": {}
  },
  {
    "trigger": "security_alert",
    "response": "Security alert detected. Immediate attention required.",
    "voice_id": "en-US",
    "volume": 1.0,
    "priority": 3,
    "conditions": {}
  }
]
```

## 🔧 Integration

### Event Whisperer Integration

The voice daemon integrates with the LilithOS event whisperer system to provide real-time voice feedback for system events:

```python
# Event types supported
- system_startup
- system_shutdown
- error_detected
- success_completed
- security_alert
- network_connected
- memory_scan_complete
- ota_update
- user_interaction
```

### Memory Scanner Integration

```python
# Memory scanner events
- memory_scan_start
- memory_scan_complete
- memory_anomaly
```

### Bootloader Integration

```python
# Bootloader events
- bootloader_mode
- psp_mode
- vita_mode
```

### LiveArea Integration

```python
# LiveArea events
- theme_change
- animation_trigger
- user_interaction
```

## 🎨 Voice Profiles

### Default Profiles

- **default**: Standard voice for general use
- **alert**: Higher rate and volume for alerts
- **calm**: Lower rate and volume for calm situations
- **lilybear**: Special profile for Lilybear mascot interactions

### Custom Profiles

```yaml
voice_customization:
  profiles:
    custom_profile:
      voice_id: "en-GB"
      rate: 140
      volume: 0.9
      pitch: 1.1
```

## 🔒 Security Features

### Input Validation

- Text sanitization to prevent injection attacks
- Input length limits (configurable)
- Voice ID validation against allowed list
- Volume level validation

### Audio Security

- Secure audio device access
- Protected voice profile management
- Encrypted communication channels
- Audit logging for all voice operations

## 📊 Performance Optimization

### Memory Management

- Efficient audio buffer management
- Configurable queue sizes
- Memory limits for text and audio
- Automatic cleanup of temporary files

### CPU Optimization

- Non-blocking TTS synthesis
- Worker thread management
- Timeout controls for operations
- Background processing for non-critical events

### Battery Optimization

- Minimal CPU usage for idle state
- Efficient audio playback
- Smart event filtering
- Power-aware voice profiles

## 🐛 Troubleshooting

### Common Issues

1. **TTS Engine Not Found**
   ```bash
   # Install missing TTS engine
   pip3 install pyttsx3
   # or
   sudo apt-get install espeak-ng
   ```

2. **Audio Device Issues**
   ```bash
   # Check audio devices
   python3 -c "import pyaudio; p = pyaudio.PyAudio(); [print(p.get_device_info_by_index(i)) for i in range(p.get_device_count())]"
   ```

3. **Permission Errors**
   ```bash
   # Fix audio permissions
   sudo usermod -a -G audio $USER
   # Reboot required
   ```

4. **Whisperer Connection Issues**
   ```bash
   # Check whisperer service
   curl http://localhost:8080/health
   # Check network connectivity
   ping localhost
   ```

### Debug Mode

```python
# Enable debug logging
import logging
logging.getLogger('LilithVoice').setLevel(logging.DEBUG)
```

## 📈 Monitoring

### Log Files

- `lilith_voice.log`: Main daemon log
- `voice_manager.log`: Voice manager operations
- `whisperer_integration.log`: Event integration log

### Metrics

- TTS synthesis time
- Audio playback duration
- Event processing latency
- Error rates and types
- Voice profile usage statistics

## 🔄 Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/lilithos/voice-daemon.git
cd voice-daemon

# Install dependencies
pip3 install -r requirements.txt

# Run tests
python3 -m pytest tests/

# Run daemon
python3 lilith_voice_daemon.py
```

### Testing

```bash
# Run unit tests
python3 -m pytest tests/unit/

# Run integration tests
python3 -m pytest tests/integration/

# Run performance tests
python3 -m pytest tests/performance/
```

## 📝 API Reference

### LilithVoiceDaemon

```python
class LilithVoiceDaemon:
    def __init__(self)
    def initialize_tts(self)
    def signal_to_speech_map(self, event: VoiceEvent, data: Dict = None)
    def speak_text(self, text: str, voice_id: str = None, volume: float = None, priority: int = 1)
    def load_phrase_scripts(self, script_file: str = "phrase_scripts.json")
    def process_phrase_script(self, trigger: str, context: Dict = None)
    def integrate_with_whisperer(self, whisperer_callback: Callable)
    def handle_whisperer_event(self, event_type: str, data: Dict)
    def run_daemon(self)
```

### VoiceManager

```python
class VoiceManager:
    def __init__(self, config_file: str = "voice_config.yaml")
    def speak(self, text: str, profile: str = None, blocking: bool = True) -> bool
    def set_voice_profile(self, profile_name: str) -> bool
    def get_voice_profiles(self) -> List[str]
    def get_audio_devices(self) -> List[Dict]
    def test_voice(self, text: str = "Hello, this is a test") -> bool
    def shutdown(self)
```

### WhispererIntegration

```python
class WhispererIntegration:
    def __init__(self, voice_daemon, config: Dict = None)
    def register_event_handler(self, event_type: str, handler: Callable)
    async def connect_to_whisperer(self)
    async def listen_for_events(self)
    async def send_event(self, event_type: str, data: Dict = None, priority: EventPriority = EventPriority.NORMAL)
    async def start(self)
    async def stop(self)
```

## 🤝 Contributing

### Development Guidelines

1. Follow quantum-detailed documentation standards
2. Include comprehensive inline comments
3. Add unit tests for new features
4. Update configuration examples
5. Maintain backward compatibility

### Code Style

- Use type hints for all functions
- Follow PEP 8 style guidelines
- Include docstrings for all classes and methods
- Use meaningful variable and function names

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **pyttsx3**: Cross-platform TTS library
- **gTTS**: Google Text-to-Speech integration
- **espeak**: Open-source speech synthesizer
- **pyaudio**: Audio I/O library
- **LilithOS Community**: For feedback and contributions

---

**🎤 Voice daemon ready to bring LilithOS to life with intelligent speech synthesis!** 