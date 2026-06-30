from PIL import Image, ImageDraw
import math

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Solid white background
bg_color = (255, 255, 255, 255)
draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=bg_color)

# 2. Deep blue circle badge
badge_r = 260
badge_color = (10, 36, 99, 255)
draw.ellipse([center - badge_r, center - badge_r, center + badge_r, center + badge_r],
             fill=badge_color)

# 3. White play button in center
play_r = 85
draw.ellipse([center - play_r, center - play_r, center + play_r, center + play_r],
             fill=(255, 255, 255, 245))

# Play triangle
draw.polygon([
    (center - 28, center - 34),
    (center - 28, center + 34),
    (center + 38, center),
], fill=badge_color)

# 4. Small accent ring (subtle, hand-finished feel)
ring_r = badge_r + 14
draw.ellipse([center - ring_r, center - ring_r, center + ring_r, center + ring_r],
             outline=(10, 36, 99, 40), width=6)

# Save rounded version
img.save('app_icon_v8.png')
print("Saved app_icon_v8.png ({}x{})".format(SIZE, SIZE))

# Save square version for iOS/App Store
square = Image.new('RGBA', (SIZE, SIZE), bg_color)
square.paste(img, (0, 0), img)
square.save('app_icon_v8_square.png')
print("Saved app_icon_v8_square.png ({}x{})".format(SIZE, SIZE))
