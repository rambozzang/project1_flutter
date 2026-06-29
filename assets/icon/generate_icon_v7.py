from PIL import Image, ImageDraw
import math

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Flat light gray background
bg_color = (248, 249, 250, 255)
draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=bg_color)

# 2. Short-form feed symbol: two vertical rectangles, front one with play button
symbol_color = (255, 107, 74, 255)  # Coral/orange flat color
shadow_color = (230, 230, 230, 180)

# Back card (smaller, offset)
back_w, back_h = 260, 420
back_x = center - 60
back_y = center - back_h // 2 + 10
draw.rounded_rectangle([back_x + 12, back_y + 12, back_x + back_w + 12, back_y + back_h + 12],
                       radius=32, fill=shadow_color)
draw.rounded_rectangle([back_x, back_y, back_x + back_w, back_y + back_h],
                       radius=32, fill=(255, 255, 255, 255), outline=symbol_color, width=4)

# Front card (larger)
front_w, front_h = 300, 480
front_x = center - front_w // 2
front_y = center - front_h // 2
draw.rounded_rectangle([front_x + 14, front_y + 14, front_x + front_w + 14, front_y + front_h + 14],
                       radius=36, fill=shadow_color)
draw.rounded_rectangle([front_x, front_y, front_x + front_w, front_y + front_h],
                       radius=36, fill=symbol_color)

# Play button in center of front card
play_y = center
play_r = 55
draw.ellipse([center - play_r, play_y - play_r, center + play_r, play_y + play_r],
             fill=(255, 255, 255, 240))
# Coral play triangle
draw.polygon([
    (center - 18, play_y - 22),
    (center - 18, play_y + 22),
    (center + 24, play_y),
], fill=symbol_color)

# 3. Small brand dot accent (bottom right)
draw.ellipse([center + 220, center + 240, center + 248, center + 268], fill=(10, 36, 99, 255))

# Save rounded version (for preview)
img.save('app_icon_v7.png')
print("Saved app_icon_v7.png ({}x{})".format(SIZE, SIZE))

# Save square version for iOS/App Store (no transparency)
square = Image.new('RGBA', (SIZE, SIZE), bg_color)
square.paste(img, (0, 0), img)
square.save('app_icon_v7_square.png')
print("Saved app_icon_v7_square.png ({}x{})".format(SIZE, SIZE))
