#!/usr/bin/env python3

import os
import sys
import plistlib
import subprocess
from pathlib import Path
import logging
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import imageio
import math

# Configure logging
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BootAnimationCustomizer:
    def __init__(self, resources_dir):
        self.resources_dir = Path(resources_dir)
        self.work_dir = Path("work")
        self.frames_dir = self.work_dir / "frames"
        self.output_dir = Path("build")
        self.width = 640
        self.height = 1136
        self.fps = 30
        self.duration = 5  # seconds

    def setup_directories(self):
        """Create necessary directories."""
        self.frames_dir.mkdir(parents=True, exist_ok=True)
        self.output_dir.mkdir(exist_ok=True)

    def create_boot_animation(self):
        """Create the custom boot animation."""
        logger.info("Creating boot animation...")
        
        # Create frames
        self._create_frames()
        
        # Combine frames into animation
        self._combine_frames()
        
        # Create plist configuration
        self._create_plist()

    def _draw_crest(self, draw, center_x, center_y, size, progress):
        """Draw the Khandokar family crest."""
        # Crest colors
        primary_color = (139, 69, 19)  # Saddle Brown
        accent_color = (218, 165, 32)  # Golden Rod
        highlight_color = (255, 215, 0)  # Gold
        
        # Calculate animation parameters
        scale = 0.5 + 0.5 * math.sin(progress * math.pi)
        rotation = progress * 360
        
        # Draw the main shield shape
        shield_points = [
            (center_x, center_y - size * 0.8),  # Top
            (center_x + size * 0.6, center_y - size * 0.4),  # Top right
            (center_x + size * 0.6, center_y + size * 0.4),  # Bottom right
            (center_x, center_y + size * 0.8),  # Bottom
            (center_x - size * 0.6, center_y + size * 0.4),  # Bottom left
            (center_x - size * 0.6, center_y - size * 0.4),  # Top left
        ]
        
        # Draw shield with gradient
        for i in range(len(shield_points)):
            p1 = shield_points[i]
            p2 = shield_points[(i + 1) % len(shield_points)]
            draw.line([p1, p2], fill=primary_color, width=3)
        
        # Draw inner decorative elements
        inner_size = size * 0.6
        for i in range(8):
            angle = i * (360 / 8) + rotation
            rad = math.radians(angle)
            x1 = center_x + math.cos(rad) * inner_size * 0.3
            y1 = center_y + math.sin(rad) * inner_size * 0.3
            x2 = center_x + math.cos(rad) * inner_size * 0.6
            y2 = center_y + math.sin(rad) * inner_size * 0.6
            draw.line([(x1, y1), (x2, y2)], fill=accent_color, width=2)
        
        # Draw central emblem
        emblem_size = size * 0.3
        draw.ellipse([
            center_x - emblem_size,
            center_y - emblem_size,
            center_x + emblem_size,
            center_y + emblem_size
        ], outline=highlight_color, width=2)
        
        # Add glow effect
        for i in range(3):
            glow_size = emblem_size + i * 2
            draw.ellipse([
                center_x - glow_size,
                center_y - glow_size,
                center_x + glow_size,
                center_y + glow_size
            ], outline=(255, 215, 0, 128 - i * 40), width=1)

    def _create_frames(self):
        """Create individual animation frames."""
        logger.info("Creating animation frames...")
        
        total_frames = self.fps * self.duration
        
        for i in range(total_frames):
            # Create base image with gradient background
            frame = Image.new('RGB', (self.width, self.height), color='black')
            draw = ImageDraw.Draw(frame)
            
            # Calculate animation progress (0 to 1)
            progress = i / total_frames
            
            # Create gradient background
            for y in range(self.height):
                # Calculate color based on position and progress
                r = int(20 + 10 * math.sin(progress * math.pi + y / self.height * math.pi))
                g = int(20 + 10 * math.sin(progress * math.pi * 2 + y / self.height * math.pi))
                b = int(20 + 10 * math.sin(progress * math.pi * 3 + y / self.height * math.pi))
                draw.line([(0, y), (self.width, y)], fill=(r, g, b))
            
            # Draw the Khandokar family crest
            self._draw_crest(draw, self.width // 2, self.height // 2 - 100, 200, progress)
            
            # Add LilithOS text
            try:
                # Try to use Arial font, fall back to default if not available
                font_path = os.path.join(os.environ['WINDIR'], 'Fonts', 'arial.ttf')
                if os.path.exists(font_path):
                    font = ImageFont.truetype(font_path, 48)
                else:
                    font = ImageFont.load_default()
            except:
                font = ImageFont.load_default()
            
            # Calculate text position
            text = "LilithOS"
            text_width = draw.textlength(text, font=font)
            text_position = ((self.width - text_width) // 2, self.height // 2 + 100)
            
            # Draw text with glow effect
            for offset in range(3):
                draw.text((text_position[0] + offset, text_position[1]), text, font=font, fill=(139, 69, 19))
                draw.text((text_position[0] - offset, text_position[1]), text, font=font, fill=(139, 69, 19))
                draw.text((text_position[0], text_position[1] + offset), text, font=font, fill=(139, 69, 19))
                draw.text((text_position[0], text_position[1] - offset), text, font=font, fill=(139, 69, 19))
            
            # Draw main text
            draw.text(text_position, text, font=font, fill=(218, 165, 32))
            
            # Add version text
            version_text = "9.3.6"
            version_font = ImageFont.truetype(font_path, 24) if os.path.exists(font_path) else ImageFont.load_default()
            version_width = draw.textlength(version_text, font=version_font)
            version_position = ((self.width - version_width) // 2, self.height // 2 + 160)
            draw.text(version_position, version_text, font=version_font, fill=(139, 69, 19))
            
            # Save frame
            frame.save(self.frames_dir / f"frame_{i:03d}.png")

    def _combine_frames(self):
        """Combine frames into a single animation file."""
        logger.info("Combining frames...")
        
        # Get all frame files
        frames = sorted(self.frames_dir.glob("frame_*.png"))
        
        # Create animation
        with imageio.get_writer(self.output_dir / "boot_animation.gif",
                              mode='I',
                              duration=1.0/self.fps) as writer:
            for frame in frames:
                image = imageio.imread(frame)
                writer.append_data(image)

    def _create_plist(self):
        """Create the boot animation configuration plist."""
        logger.info("Creating boot animation configuration...")
        
        config = {
            'CFBundleIdentifier': 'com.lilithos.bootanimation',
            'CFBundleVersion': '1.0',
            'Duration': self.duration,
            'FramesPerSecond': self.fps,
            'LoopCount': 1,
            'AnimationType': 'GIF',
            'AnimationFile': 'boot_animation.gif'
        }
        
        with open(self.output_dir / "BootAnimation.plist", 'wb') as f:
            plistlib.dump(config, f)

    def cleanup(self):
        """Clean up temporary files."""
        logger.info("Cleaning up...")
        if self.work_dir.exists():
            for file in self.work_dir.glob("**/*"):
                if file.is_file():
                    file.unlink()
            self.work_dir.rmdir()

def main():
    if len(sys.argv) != 2:
        print("Usage: boot_animation.py <resources_directory>")
        sys.exit(1)
    
    try:
        customizer = BootAnimationCustomizer(sys.argv[1])
        customizer.setup_directories()
        customizer.create_boot_animation()
        customizer.cleanup()
        logger.info("Boot animation creation completed successfully!")
    except Exception as e:
        logger.error(f"Error creating boot animation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 