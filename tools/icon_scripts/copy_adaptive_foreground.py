from PIL import Image
import os

src = Image.open('app_icon_adaptive_fore.png').convert('RGBA')

# Android adaptive icon foreground sizes
sizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
}

base_path = '../../android/app/src/main/res'

for folder, size in sizes.items():
    resized = src.resize((size, size), Image.Resampling.LANCZOS)
    path = os.path.join(base_path, folder, 'ic_launcher_foreground.png')
    resized.save(path)
    print(f"Saved {path} ({size}x{size})")
