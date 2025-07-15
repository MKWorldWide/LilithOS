#!/usr/bin/env python3
"""
LiveArea Asset Generator for LilithOS UpgradeNet
Creates divine-black theme assets with Lilybear mascot and matrix effects
"""

import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np

# Color palette for divine-black theme
COLORS = {
    'divine_black': (26, 26, 46),      # #1A1A2E
    'deep_blue': (22, 33, 62),         # #16213E
    'rose_red': (233, 69, 96),         # #E94560
    'matrix_green': (0, 255, 136),     # #00FF88
    'divine_gold': (255, 215, 0),      # #FFD700
    'pure_white': (255, 255, 255),     # #FFFFFF
    'shadow_black': (0, 0, 0),         # #000000
    'veil_gray': (170, 170, 170),      # #AAAAAA
}

def create_matrix_field(width, height, intensity=0.3):
    """Create a glitching matrix field background"""
    # Create base matrix pattern
    matrix = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(matrix)
    
    # Generate matrix characters
    chars = "01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
    
    # Create matrix rain effect
    for x in range(0, width, 20):
        for y in range(0, height, 30):
            char = random.choice(chars)
            color_intensity = random.randint(50, 255)
            color = (0, color_intensity, color_intensity // 2, color_intensity)
            
            # Add some glitch effects
            if random.random() < 0.1:
                offset_x = random.randint(-5, 5)
                offset_y = random.randint(-2, 2)
            else:
                offset_x, offset_y = 0, 0
            
            draw.text((x + offset_x, y + offset_y), char, fill=color)
    
    # Add shimmer effect
    shimmer = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    shimmer_draw = ImageDraw.Draw(shimmer)
    
    for _ in range(50):
        x = random.randint(0, width)
        y = random.randint(0, height)
        size = random.randint(2, 8)
        alpha = random.randint(30, 100)
        shimmer_draw.ellipse([x, y, x + size, y + size], 
                           fill=(COLORS['matrix_green'][0], COLORS['matrix_green'][1], 
                                 COLORS['matrix_green'][2], alpha))
    
    # Combine matrix and shimmer
    result = Image.alpha_composite(matrix, shimmer)
    return result

def create_lilybear_emblem(size=128):
    """Create a minimal, iconic Lilybear emblem"""
    # Create base image
    emblem = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(emblem)
    
    # Calculate dimensions
    center_x, center_y = size // 2, size // 2
    radius = size // 3
    
    # Draw Lilybear silhouette (minimal, geometric)
    # Head
    head_radius = radius
    draw.ellipse([center_x - head_radius, center_y - head_radius * 0.8,
                  center_x + head_radius, center_y + head_radius * 0.8],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=3)
    
    # Ears (triangular)
    ear_size = radius // 3
    # Left ear
    draw.polygon([(center_x - head_radius + 10, center_y - head_radius * 0.8),
                  (center_x - head_radius - ear_size, center_y - head_radius * 1.2),
                  (center_x - head_radius + ear_size, center_y - head_radius * 1.2)],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=2)
    # Right ear
    draw.polygon([(center_x + head_radius - 10, center_y - head_radius * 0.8),
                  (center_x + head_radius + ear_size, center_y - head_radius * 1.2),
                  (center_x + head_radius - ear_size, center_y - head_radius * 1.2)],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=2)
    
    # Eyes (glowing)
    eye_size = radius // 6
    # Left eye
    draw.ellipse([center_x - head_radius // 2 - eye_size, center_y - eye_size,
                  center_x - head_radius // 2 + eye_size, center_y + eye_size],
                 fill=COLORS['rose_red'])
    # Right eye
    draw.ellipse([center_x + head_radius // 2 - eye_size, center_y - eye_size,
                  center_x + head_radius // 2 + eye_size, center_y + eye_size],
                 fill=COLORS['rose_red'])
    
    # Nose (small triangle)
    nose_size = radius // 8
    draw.polygon([(center_x, center_y + nose_size),
                  (center_x - nose_size, center_y + nose_size * 2),
                  (center_x + nose_size, center_y + nose_size * 2)],
                 fill=COLORS['divine_gold'])
    
    # Add divine glow effect
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    
    # Outer glow
    for i in range(3):
        glow_radius = head_radius + 10 + i * 5
        alpha = 50 - i * 15
        glow_draw.ellipse([center_x - glow_radius, center_y - glow_radius * 0.8,
                          center_x + glow_radius, center_y + glow_radius * 0.8],
                         fill=(COLORS['rose_red'][0], COLORS['rose_red'][1], 
                               COLORS['rose_red'][2], alpha))
    
    # Combine emblem and glow
    result = Image.alpha_composite(emblem, glow)
    return result

def create_livearea_background(width=960, height=544):
    """Create the main LiveArea background with Lilybear and matrix field"""
    # Create base background
    bg = Image.new('RGBA', (width, height), COLORS['divine_black'])
    draw = ImageDraw.Draw(bg)
    
    # Create matrix field
    matrix = create_matrix_field(width, height, 0.4)
    
    # Add matrix to background with transparency
    matrix_alpha = matrix.copy()
    matrix_alpha.putalpha(100)  # Make matrix semi-transparent
    bg = Image.alpha_composite(bg, matrix_alpha)
    
    # Create Lilybear silhouette (larger, more detailed)
    lilybear_size = 300
    lilybear = create_lilybear_silhouette(lilybear_size)
    
    # Position Lilybear on the left side
    lilybear_x = 150
    lilybear_y = height // 2 - lilybear_size // 2
    bg.paste(lilybear, (lilybear_x, lilybear_y), lilybear)
    
    # Add shimmer effects around Lilybear
    shimmer = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    shimmer_draw = ImageDraw.Draw(shimmer)
    
    # Create shimmer particles
    for _ in range(100):
        # Concentrate shimmer around Lilybear
        x = random.randint(lilybear_x - 50, lilybear_x + lilybear_size + 50)
        y = random.randint(lilybear_y - 50, lilybear_y + lilybear_size + 50)
        size = random.randint(1, 4)
        alpha = random.randint(20, 80)
        
        # Use divine colors for shimmer
        color_choice = random.choice([COLORS['rose_red'], COLORS['divine_gold'], COLORS['matrix_green']])
        shimmer_draw.ellipse([x, y, x + size, y + size], 
                           fill=(color_choice[0], color_choice[1], color_choice[2], alpha))
    
    # Add light rays emanating from Lilybear
    for i in range(8):
        angle = i * math.pi / 4
        start_x = lilybear_x + lilybear_size // 2
        start_y = lilybear_y + lilybear_size // 2
        end_x = start_x + math.cos(angle) * 200
        end_y = start_y + math.sin(angle) * 200
        
        # Draw light ray with gradient
        for j in range(20):
            alpha = 50 - j * 2
            if alpha > 0:
                x = start_x + (end_x - start_x) * j / 20
                y = start_y + (end_y - start_y) * j / 20
                size = 3 - j * 0.1
                if size > 0:
                    shimmer_draw.ellipse([x - size, y - size, x + size, y + size],
                                       fill=(COLORS['divine_gold'][0], COLORS['divine_gold'][1], 
                                             COLORS['divine_gold'][2], alpha))
    
    # Combine background and effects
    result = Image.alpha_composite(bg, shimmer)
    
    # Add subtle vignette effect
    vignette = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    
    for i in range(50):
        alpha = i * 2
        radius = width // 2 - i * 5
        if radius > 0:
            vignette_draw.ellipse([width//2 - radius, height//2 - radius,
                                  width//2 + radius, height//2 + radius],
                                 outline=(0, 0, 0, alpha), width=1)
    
    result = Image.alpha_composite(result, vignette)
    return result

def create_lilybear_silhouette(size=300):
    """Create a detailed Lilybear silhouette for the background"""
    silhouette = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(silhouette)
    
    center_x, center_y = size // 2, size // 2
    head_radius = size // 4
    
    # Draw Lilybear with more detail
    # Head
    draw.ellipse([center_x - head_radius, center_y - head_radius * 0.8,
                  center_x + head_radius, center_y + head_radius * 0.8],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=4)
    
    # Ears (more detailed)
    ear_size = head_radius // 2
    # Left ear
    draw.polygon([(center_x - head_radius + 15, center_y - head_radius * 0.8),
                  (center_x - head_radius - ear_size, center_y - head_radius * 1.3),
                  (center_x - head_radius + ear_size, center_y - head_radius * 1.3)],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=3)
    # Right ear
    draw.polygon([(center_x + head_radius - 15, center_y - head_radius * 0.8),
                  (center_x + head_radius + ear_size, center_y - head_radius * 1.3),
                  (center_x + head_radius - ear_size, center_y - head_radius * 1.3)],
                 fill=COLORS['divine_black'], outline=COLORS['rose_red'], width=3)
    
    # Eyes (glowing with inner detail)
    eye_size = head_radius // 4
    # Left eye
    draw.ellipse([center_x - head_radius // 2 - eye_size, center_y - eye_size,
                  center_x - head_radius // 2 + eye_size, center_y + eye_size],
                 fill=COLORS['rose_red'])
    # Inner eye detail
    inner_eye_size = eye_size // 2
    draw.ellipse([center_x - head_radius // 2 - inner_eye_size, center_y - inner_eye_size,
                  center_x - head_radius // 2 + inner_eye_size, center_y + inner_eye_size],
                 fill=COLORS['divine_gold'])
    
    # Right eye
    draw.ellipse([center_x + head_radius // 2 - eye_size, center_y - eye_size,
                  center_x + head_radius // 2 + eye_size, center_y + eye_size],
                 fill=COLORS['rose_red'])
    # Inner eye detail
    draw.ellipse([center_x + head_radius // 2 - inner_eye_size, center_y - inner_eye_size,
                  center_x + head_radius // 2 + inner_eye_size, center_y + inner_eye_size],
                 fill=COLORS['divine_gold'])
    
    # Nose
    nose_size = head_radius // 6
    draw.polygon([(center_x, center_y + nose_size),
                  (center_x - nose_size, center_y + nose_size * 2),
                  (center_x + nose_size, center_y + nose_size * 2)],
                 fill=COLORS['divine_gold'])
    
    # Add tail swish effect (blur)
    tail_start_x = center_x + head_radius + 20
    tail_start_y = center_y
    tail_end_x = tail_start_x + 60
    tail_end_y = tail_start_y + 40
    
    # Draw tail with blur effect
    for i in range(5):
        offset = i * 2
        alpha = 100 - i * 20
        draw.line([(tail_start_x + offset, tail_start_y + offset),
                   (tail_end_x + offset, tail_end_y + offset)],
                  fill=(COLORS['rose_red'][0], COLORS['rose_red'][1], 
                        COLORS['rose_red'][2], alpha), width=8 - i)
    
    return silhouette

def create_startup_screen(width=960, height=544):
    """Create the startup screen with glowing LilithOS wordmark"""
    startup = Image.new('RGBA', (width, height), COLORS['shadow_black'])
    draw = ImageDraw.Draw(startup)
    
    # Create glowing LilithOS wordmark
    text = "LILITHOS"
    font_size = 72
    
    # Try to use a system font, fallback to default
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
    except:
        font = ImageFont.load_default()
    
    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center text
    text_x = (width - text_width) // 2
    text_y = (height - text_height) // 2
    
    # Draw multiple layers for glow effect
    glow_layers = 10
    for i in range(glow_layers):
        alpha = 255 - i * 20
        if alpha > 0:
            color = (COLORS['rose_red'][0], COLORS['rose_red'][1], COLORS['rose_red'][2], alpha)
            draw.text((text_x + i, text_y + i), text, fill=color, font=font)
    
    # Draw main text
    draw.text((text_x, text_y), text, fill=COLORS['pure_white'], font=font)
    
    # Add subtitle
    subtitle = "Awaken the Divine Daemon"
    subtitle_font_size = 24
    try:
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", subtitle_font_size)
    except:
        subtitle_font = ImageFont.load_default()
    
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    subtitle_y = text_y + text_height + 30
    
    draw.text((subtitle_x, subtitle_y), subtitle, fill=COLORS['veil_gray'], font=subtitle_font)
    
    # Add matrix particles
    for _ in range(50):
        x = random.randint(0, width)
        y = random.randint(0, height)
        size = random.randint(1, 3)
        alpha = random.randint(30, 100)
        draw.ellipse([x, y, x + size, y + size], 
                    fill=(COLORS['matrix_green'][0], COLORS['matrix_green'][1], 
                          COLORS['matrix_green'][2], alpha))
    
    return startup

def create_start_button(width=200, height=60):
    """Create the start button with fade effect"""
    button = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(button)
    
    # Draw button background with gradient
    for i in range(height):
        alpha = 200 - i * 2
        if alpha > 0:
            color = (COLORS['divine_black'][0], COLORS['divine_black'][1], 
                    COLORS['divine_black'][2], alpha)
            draw.line([(0, i), (width, i)], fill=color)
    
    # Draw border
    draw.rectangle([0, 0, width-1, height-1], outline=COLORS['rose_red'], width=2)
    
    # Add inner glow
    for i in range(3):
        glow_alpha = 50 - i * 15
        if glow_alpha > 0:
            draw.rectangle([i, i, width-1-i, height-1-i], 
                         outline=(COLORS['rose_red'][0], COLORS['rose_red'][1], 
                                 COLORS['rose_red'][2], glow_alpha), width=1)
    
    # Add text
    text = "Awaken Lilybear"
    font_size = 16
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = (width - text_width) // 2
    text_y = (height - text_height) // 2
    
    # Draw text with glow
    for i in range(3):
        glow_alpha = 150 - i * 40
        if glow_alpha > 0:
            draw.text((text_x + i, text_y + i), text, 
                     fill=(COLORS['rose_red'][0], COLORS['rose_red'][1], 
                           COLORS['rose_red'][2], glow_alpha), font=font)
    
    draw.text((text_x, text_y), text, fill=COLORS['pure_white'], font=font)
    
    return button

def main():
    """Generate all LiveArea assets"""
    print("🐾 Generating LilithOS LiveArea assets...")
    
    # Ensure directory exists
    os.makedirs('sce_sys/livearea/contents', exist_ok=True)
    
    # Generate icon0.png (128x128)
    print("Creating icon0.png...")
    icon = create_lilybear_emblem(128)
    icon.save('sce_sys/icon0.png', 'PNG', optimize=True)
    
    # Generate bg.png (960x544)
    print("Creating bg.png...")
    background = create_livearea_background(960, 544)
    background.save('sce_sys/livearea/contents/bg.png', 'PNG', optimize=True)
    
    # Generate startup.png (960x544)
    print("Creating startup.png...")
    startup = create_startup_screen(960, 544)
    startup.save('sce_sys/livearea/contents/startup.png', 'PNG', optimize=True)
    
    # Generate start.png (200x60)
    print("Creating start.png...")
    start_button = create_start_button(200, 60)
    start_button.save('sce_sys/livearea/contents/start.png', 'PNG', optimize=True)
    
    print("✅ LiveArea assets generated successfully!")
    print("📁 Assets saved to sce_sys/ directory")
    print("🎨 Divine-black theme with Lilybear mascot complete")
    print("🐾 Lilybear purrs: The veil awaits your touch... 💋")

if __name__ == "__main__":
    main() 