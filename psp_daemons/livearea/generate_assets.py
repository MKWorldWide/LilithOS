#!/usr/bin/env python3
"""
🐾 LilithDaemon LiveArea Asset Generator
Divine-Black Theme with Lilybear Mascot
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont
import math
import colorsys

class LiveAreaAssetGenerator:
    def __init__(self):
        self.theme = {
            'primary': '#0a0a0a',      # Divine black
            'secondary': '#1a1a1a',    # Dark gray
            'accent': '#4a90e2',       # Blue accent
            'text': '#ffffff',         # White text
            'highlight': '#ff6b6b',    # Red highlight
            'lilybear': '#8b4513'      # Brown for Lilybear
        }
        
        self.sizes = {
            'icon': (128, 128),
            'bg': (960, 544),          # Vita screen resolution
            'lilybear': (64, 64)
        }
        
    def create_gradient_background(self, size, start_color, end_color):
        """Create divine-black gradient background"""
        img = Image.new('RGBA', size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        for y in range(size[1]):
            ratio = y / size[1]
            r = int(int(start_color[1:3], 16) * (1 - ratio) + int(end_color[1:3], 16) * ratio)
            g = int(int(start_color[3:5], 16) * (1 - ratio) + int(end_color[3:5], 16) * ratio)
            b = int(int(start_color[5:7], 16) * (1 - ratio) + int(end_color[5:7], 16) * ratio)
            draw.line([(0, y), (size[0], y)], fill=(r, g, b, 255))
            
        return img
    
    def create_lilybear_mascot(self, size):
        """Create Lilybear mascot character"""
        img = Image.new('RGBA', size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 🐻 Lilybear design (simplified geometric)
        center_x, center_y = size[0] // 2, size[1] // 2
        
        # Body (circle)
        body_radius = min(size) // 3
        draw.ellipse([
            center_x - body_radius, center_y - body_radius,
            center_x + body_radius, center_y + body_radius
        ], fill=self.theme['lilybear'])
        
        # Head (smaller circle)
        head_radius = body_radius // 2
        draw.ellipse([
            center_x - head_radius, center_y - head_radius - body_radius//2,
            center_x + head_radius, center_y + head_radius - body_radius//2
        ], fill=self.theme['lilybear'])
        
        # Eyes (white dots)
        eye_radius = head_radius // 4
        draw.ellipse([
            center_x - head_radius//2 - eye_radius, center_y - body_radius//2 - eye_radius,
            center_x - head_radius//2 + eye_radius, center_y - body_radius//2 + eye_radius
        ], fill='white')
        draw.ellipse([
            center_x + head_radius//2 - eye_radius, center_y - body_radius//2 - eye_radius,
            center_x + head_radius//2 + eye_radius, center_y - body_radius//2 + eye_radius
        ], fill='white')
        
        # Nose (black dot)
        nose_radius = eye_radius // 2
        draw.ellipse([
            center_x - nose_radius, center_y - body_radius//2 - nose_radius,
            center_x + nose_radius, center_y - body_radius//2 + nose_radius
        ], fill='black')
        
        return img
    
    def create_icon(self):
        """Create LilithDaemon icon with divine-black theme"""
        img = self.create_gradient_background(self.sizes['icon'], self.theme['primary'], self.theme['secondary'])
        draw = ImageDraw.Draw(img)
        
        # Add geometric pattern
        center_x, center_y = self.sizes['icon'][0] // 2, self.sizes['icon'][1] // 2
        
        # Outer ring
        outer_radius = min(self.sizes['icon']) // 2 - 10
        draw.ellipse([
            center_x - outer_radius, center_y - outer_radius,
            center_x + outer_radius, center_y + outer_radius
        ], outline=self.theme['accent'], width=3)
        
        # Inner pattern (hexagon)
        points = []
        for i in range(6):
            angle = i * math.pi / 3
            x = center_x + int(outer_radius * 0.6 * math.cos(angle))
            y = center_y + int(outer_radius * 0.6 * math.sin(angle))
            points.append((x, y))
        
        draw.polygon(points, outline=self.theme['highlight'], width=2)
        
        # Center dot
        center_radius = outer_radius // 4
        draw.ellipse([
            center_x - center_radius, center_y - center_radius,
            center_x + center_radius, center_y + center_radius
        ], fill=self.theme['accent'])
        
        return img
    
    def create_background(self):
        """Create LiveArea background with Lilybear mascot"""
        img = self.create_gradient_background(self.sizes['bg'], self.theme['primary'], self.theme['secondary'])
        
        # Add subtle pattern overlay
        draw = ImageDraw.Draw(img)
        for i in range(0, self.sizes['bg'][0], 50):
            for j in range(0, self.sizes['bg'][1], 50):
                draw.ellipse([i, j, i+2, j+2], fill=self.theme['accent'])
        
        # Add Lilybear mascot in bottom-right
        lilybear = self.create_lilybear_mascot(self.sizes['lilybear'])
        img.paste(lilybear, (self.sizes['bg'][0] - self.sizes['lilybear'][0] - 20, 
                            self.sizes['bg'][1] - self.sizes['lilybear'][1] - 20), lilybear)
        
        return img
    
    def create_boot_sound_placeholder(self):
        """Create placeholder for boot sound file"""
        # This would normally generate an audio file
        # For now, create a text file indicating the sound should be added
        with open('boot.wav.placeholder', 'w') as f:
            f.write("Boot sound file should be placed here\n")
            f.write("Format: WAV, 44.1kHz, 16-bit\n")
            f.write("Duration: 1-2 seconds\n")
    
    def generate_all_assets(self):
        """Generate all LiveArea assets"""
        print("🐾 Generating LilithDaemon LiveArea assets...")
        
        # Create assets directory
        os.makedirs('assets', exist_ok=True)
        
        # Generate icon
        print("  📱 Creating icon...")
        icon = self.create_icon()
        icon.save('assets/icon.png')
        
        # Generate background
        print("  🎨 Creating background...")
        bg = self.create_background()
        bg.save('assets/bg.png')
        
        # Generate Lilybear mascot
        print("  🐻 Creating Lilybear mascot...")
        lilybear = self.create_lilybear_mascot(self.sizes['lilybear'])
        lilybear.save('assets/lilybear.png')
        
        # Create boot sound placeholder
        print("  🔊 Creating boot sound placeholder...")
        self.create_boot_sound_placeholder()
        
        print("✅ LiveArea assets generated successfully!")
        print("📁 Assets saved to: assets/")
        print("🔊 Add boot.wav file to assets/ for startup sound")

def main():
    generator = LiveAreaAssetGenerator()
    generator.generate_all_assets()

if __name__ == "__main__":
    main() 