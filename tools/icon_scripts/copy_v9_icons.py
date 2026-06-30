from PIL import Image
import os

# iOS/AppStore square icon (with solid sky-blue background)
square = Image.open('app_icon_v9_square.png').convert('RGBA')
square.save('app_icon_v9_square.png')
print("Confirmed app_icon_v9_square.png")

# Android adaptive foreground (full icon with rounded bg)
foreground = Image.open('app_icon_v9.png').convert('RGBA')
foreground.save('app_icon_v9_foreground.png')
print("Saved app_icon_v9_foreground.png")

# Resize Android adaptive foreground for each dpi
sizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
}

base_path = '../../android/app/src/main/res'
for folder, size in sizes.items():
    resized = foreground.resize((size, size), Image.Resampling.LANCZOS)
    path = os.path.join(base_path, folder, 'ic_launcher_foreground.png')
    resized.save(path)
    print(f"Saved {path} ({size}x{size})")
