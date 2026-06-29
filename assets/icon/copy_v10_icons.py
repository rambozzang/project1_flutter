from PIL import Image
import os

# Confirm and save App Store square icon
square = Image.open('app_icon_v10_square.png').convert('RGBA')
square.save('app_icon_v10_square.png')
print("Confirmed app_icon_v10_square.png")

# Android adaptive foreground (white logo on transparent bg)
foreground = Image.open('app_icon_v10_foreground.png').convert('RGBA')
foreground.save('app_icon_v10_foreground.png')
print("Confirmed app_icon_v10_foreground.png")

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
    os.makedirs(os.path.dirname(path), exist_ok=True)
    resized.save(path)
    print(f"Saved {path} ({size}x{size})")
