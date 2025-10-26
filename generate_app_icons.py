#!/usr/bin/env python3
"""
Generate macOS app icons from a high-quality logo.png
"""

from PIL import Image
import os
import json

# Define the required icon sizes for macOS
ICON_SIZES = [
    ("16x16", 1, 16),
    ("16x16", 2, 32),
    ("32x32", 1, 32),
    ("32x32", 2, 64),
    ("128x128", 1, 128),
    ("128x128", 2, 256),
    ("256x256", 1, 256),
    ("256x256", 2, 512),
    ("512x512", 1, 512),
    ("512x512", 2, 1024),
]

def generate_icons(source_image_path, output_dir):
    """Generate all required icon sizes from source image"""
    from PIL import ImageFilter, ImageEnhance

    # Open the source image
    print(f"Opening source image: {source_image_path}")
    img = Image.open(source_image_path)

    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    print(f"Source image size: {img.size}")
    print(f"Source image mode: {img.mode}")

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Generate each icon size
    generated_files = []
    for size_name, scale, pixel_size in ICON_SIZES:
        filename = f"icon_{size_name}@{scale}x.png"
        filepath = os.path.join(output_dir, filename)

        # Resize image with high-quality resampling
        resized = img.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)

        # Apply sharpening for smaller sizes to improve clarity
        if pixel_size <= 64:
            # More sharpening for very small icons
            resized = resized.filter(ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3))
        elif pixel_size <= 256:
            # Moderate sharpening for medium icons
            resized = resized.filter(ImageFilter.UnsharpMask(radius=0.5, percent=100, threshold=2))

        # Slightly enhance contrast for better visibility
        if pixel_size <= 128:
            enhancer = ImageEnhance.Contrast(resized)
            resized = enhancer.enhance(1.1)

        # Save the resized image with maximum quality
        resized.save(filepath, 'PNG', optimize=True, compress_level=9)
        print(f"Generated: {filename} ({pixel_size}x{pixel_size})")

        generated_files.append({
            "size": size_name,
            "scale": f"{scale}x",
            "filename": filename
        })

    return generated_files

def update_contents_json(output_dir, generated_files):
    """Update Contents.json with the generated icon filenames"""

    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    for file_info in generated_files:
        contents["images"].append({
            "filename": file_info["filename"],
            "idiom": "mac",
            "scale": file_info["scale"],
            "size": file_info["size"]
        })

    # Write Contents.json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\nUpdated: {contents_path}")

def main():
    # Paths
    source_logo = "/Users/projects/Documents/zetanotes-dev/logo.png"
    output_dir = "/Users/projects/Documents/zetanotes-dev/ZetaNotes/Assets.xcassets/AppIcon.appiconset"

    # Check if source file exists
    if not os.path.exists(source_logo):
        print(f"Error: Source logo not found at {source_logo}")
        return 1

    print("=" * 60)
    print("Generating macOS App Icons")
    print("=" * 60)

    # Generate icons
    generated_files = generate_icons(source_logo, output_dir)

    # Update Contents.json
    update_contents_json(output_dir, generated_files)

    print("\n" + "=" * 60)
    print("✓ App icons generated successfully!")
    print("=" * 60)
    print(f"\nGenerated {len(generated_files)} icon files in:")
    print(f"  {output_dir}")

    return 0

if __name__ == "__main__":
    exit(main())
