#!/usr/bin/env python3
"""
Generate watchOS app icons from source images.
This script creates all required watchOS icon sizes from the main app icon.
"""

import os
from PIL import Image
import json

# Source directory (main app icons)
source_dir = "Coacher/Assets.xcassets/AppIcon.appiconset"
# Target directory (watch app icons)
target_dir = "WatchApp Watch App/Assets.xcassets/AppIcon.appiconset"

# Required watchOS icon sizes and roles
watch_icon_specs = [
    {"size": "24x24", "role": "notificationCenter", "filename": "AppIcon-24.png"},
    {"size": "27.5x27.5", "role": "notificationCenter", "filename": "AppIcon-27.5.png"},
    {"size": "29x29", "role": "companionSettings", "filename": "AppIcon-29.png"},
    {"size": "33x33", "role": "notificationCenter", "filename": "AppIcon-33.png"},
    {"size": "40x40", "role": "appLauncher", "filename": "AppIcon-40.png"},
    {"size": "44x44", "role": "appLauncher", "filename": "AppIcon-44.png"},
    {"size": "46x46", "role": "appLauncher", "filename": "AppIcon-46.png"},
    {"size": "50x50", "role": "appLauncher", "filename": "AppIcon-50.png"},
    {"size": "51x51", "role": "appLauncher", "filename": "AppIcon-51.png"},
    {"size": "54x54", "role": "appLauncher", "filename": "AppIcon-54.png"},
    {"size": "58x58", "role": "appLauncher", "filename": "AppIcon-58.png"},
    {"size": "60x60", "role": "appLauncher", "filename": "AppIcon-60.png"},
    {"size": "66x66", "role": "appLauncher", "filename": "AppIcon-66.png"},
    {"size": "80x80", "role": "appLauncher", "filename": "AppIcon-80.png"},
    {"size": "87x87", "role": "appLauncher", "filename": "AppIcon-87.png"},
    {"size": "88x88", "role": "appLauncher", "filename": "AppIcon-88.png"},
    {"size": "100x100", "role": "appLauncher", "filename": "AppIcon-100.png"},
    {"size": "102x102", "role": "appLauncher", "filename": "AppIcon-102.png"},
    {"size": "108x108", "role": "appLauncher", "filename": "AppIcon-108.png"},
]

def generate_watch_icons():
    """Generate all required watchOS icon sizes."""
    
    # Find the best source image (prefer the main icon)
    source_files = [
        "Lighter App just icon (2).png",
        "Lighter App just icon dark2 (1).png", 
        "Lighter App icon Tinted.png"
    ]
    
    source_image = None
    for filename in source_files:
        source_path = os.path.join(source_dir, filename)
        if os.path.exists(source_path):
            source_image = Image.open(source_path)
            print(f"Using source image: {filename}")
            break
    
    if not source_image:
        print("Error: No source image found!")
        return False
    
    # Ensure target directory exists
    os.makedirs(target_dir, exist_ok=True)
    
    # Generate all required sizes
    generated_files = []
    
    for spec in watch_icon_specs:
        size_parts = spec["size"].split("x")
        width = int(float(size_parts[0]))
        height = int(float(size_parts[1]))
        
        # Resize the image
        resized = source_image.resize((width, height), Image.Resampling.LANCZOS)
        
        # Save the resized image
        output_path = os.path.join(target_dir, spec["filename"])
        resized.save(output_path, "PNG")
        
        generated_files.append({
            "filename": spec["filename"],
            "idiom": "watch",
            "role": spec["role"],
            "size": spec["size"]
        })
        
        print(f"Generated: {spec['filename']} ({spec['size']})")
    
    # Create the Contents.json file
    contents = {
        "images": generated_files,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = os.path.join(target_dir, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    
    print(f"\nGenerated {len(generated_files)} watchOS icons")
    print(f"Updated Contents.json at: {contents_path}")
    
    return True

if __name__ == "__main__":
    print("Generating watchOS app icons...")
    success = generate_watch_icons()
    if success:
        print("✅ WatchOS icons generated successfully!")
    else:
        print("❌ Failed to generate watchOS icons")
