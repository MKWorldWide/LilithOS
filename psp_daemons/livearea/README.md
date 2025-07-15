# 🐾 LilithDaemon LiveArea UI

**Divine-Black Theme with Lilybear Mascot**

## 📋 Overview

The LilithDaemon LiveArea UI provides a beautiful, themed interface for the PSP core daemon with:
- 🎨 Divine-black gradient theme
- 🐻 Lilybear mascot character
- 📱 Custom icon and background
- 🔊 Boot sound integration
- 🚀 Seamless VPK integration

## 🏗️ Architecture

```
livearea/
├── livearea.xml          # LiveArea configuration
├── generate_assets.py    # Asset generator script
├── assets/              # Generated assets
│   ├── icon.png         # App icon (128x128)
│   ├── bg.png           # Background (960x544)
│   ├── lilybear.png     # Mascot (64x64)
│   └── boot.wav         # Startup sound
└── README.md            # This file
```

## 🎨 Theme Design

### Color Palette
- **Primary**: `#0a0a0a` (Divine black)
- **Secondary**: `#1a1a1a` (Dark gray)
- **Accent**: `#4a90e2` (Blue accent)
- **Text**: `#ffffff` (White)
- **Highlight**: `#ff6b6b` (Red highlight)
- **Lilybear**: `#8b4513` (Brown)

### Visual Elements
- **Gradient Backgrounds**: Smooth transitions from divine black
- **Geometric Patterns**: Hexagonal and circular motifs
- **Lilybear Mascot**: Friendly bear character in bottom-right
- **Subtle Overlays**: Accent dots for texture

## 🚀 Quick Start

### 1. Generate Assets
```bash
cd psp_daemons/livearea
python3 generate_assets.py
```

### 2. Build LiveArea VPK
```bash
cd psp_daemons/build
./build_livearea.sh
```

### 3. Install on Vita
```bash
# Copy VPK to Vita
cp vpk/LilithDaemon.vpk /path/to/vita/
```

## 🛠️ Customization

### Modify Theme Colors
Edit `generate_assets.py`:
```python
self.theme = {
    'primary': '#0a0a0a',      # Change primary color
    'accent': '#4a90e2',       # Change accent color
    # ... other colors
}
```

### Add Custom Assets
1. Place custom images in `livearea/assets/`
2. Update `livearea.xml` to reference new assets
3. Rebuild with `./build_livearea.sh`

### Custom Boot Sound
1. Add `boot.wav` to `livearea/assets/`
2. Format: WAV, 44.1kHz, 16-bit
3. Duration: 1-2 seconds recommended

## 📱 LiveArea Features

### XML Configuration
```xml
<livearea>
  <title>LilithDaemon</title>
  <description>PSP Core • Signal Watchdog • OTA Sync</description>
  <image src="bg.png"/>
  <icon src="icon.png"/>
  <startup sound="boot.wav"/>
  <actions>
    <launch>EBOOT.PBP</launch>
  </actions>
</livearea>
```

### Asset Specifications
- **Icon**: 128x128 PNG, transparent background
- **Background**: 960x544 PNG, Vita screen resolution
- **Mascot**: 64x64 PNG, positioned bottom-right
- **Boot Sound**: WAV format, 44.1kHz, 16-bit

## 🔧 Development

### Asset Generator
The `generate_assets.py` script creates:
- Gradient backgrounds with divine-black theme
- Geometric icon patterns
- Lilybear mascot character
- Asset placeholders

### Build Integration
The LiveArea system integrates with:
- VPK build system
- PSP daemon compilation
- Asset management
- Deployment automation

## 🐛 Troubleshooting

### Common Issues

**Assets not generating**
```bash
# Check Python dependencies
pip3 install Pillow

# Verify script permissions
chmod +x generate_assets.py
```

**VPK build fails**
```bash
# Check VPK structure
ls -la vpk/livearea/

# Verify asset paths
cat vpk/livearea/livearea.xml
```

**Boot sound not playing**
- Ensure `boot.wav` is in correct format
- Check file permissions
- Verify XML references

### Debug Mode
```bash
# Enable verbose output
python3 generate_assets.py --debug

# Check asset generation
ls -la assets/
file assets/*.png
```

## 🔮 Future Enhancements

### Planned Features
- 🎭 Animated LiveArea backgrounds
- 🎵 Custom music integration
- 🌙 Dynamic theme switching
- 🎮 Interactive mascot animations
- 📊 Real-time status overlays

### Memory Scanner Integration
```c
// Future signal: add runtime memory scanner
// Example stub for dynamic module loading
// load_module("ms0:/LILIDAEMON/MODULES/memory_sniff.prx");
```

## 📚 References

- [PS Vita LiveArea Documentation](https://docs.vitasdk.org/)
- [VPK Format Specification](https://vita.cfw.guide/)
- [PIL/Pillow Image Processing](https://pillow.readthedocs.io/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add LiveArea enhancements
4. Test with VPK build
5. Submit pull request

---

**🐾 Built with love for the LilithOS community** 