from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Rounded square background - brighter sky gradient
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        # Top: light sky cyan-blue, Bottom: vivid blue
        r = int(100 + (45 - 100) * ratio)
        g = int(200 + (120 - 200) * ratio)
        b = int(255 + (220 - 255) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

# Rounded corners mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# 2. Soft sun (top-right) with warm gradient
sun_x, sun_y = center + 130, center - 140
sun_r = 130
sun = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sun_draw = ImageDraw.Draw(sun)
for r in range(sun_r, 0, -2):
    ratio = r / sun_r
    red = 255
    green = int(230 - 110 * ratio)
    blue = int(120 - 80 * ratio)
    alpha = int(220 * (1 - ratio * 0.5))
    sun_draw.ellipse([sun_x - r, sun_y - r, sun_x + r, sun_y + r],
                     fill=(red, green, blue, alpha))
img = Image.alpha_composite(img, sun)

# 3. Modern cloud (white, soft shadow)
draw = ImageDraw.Draw(img)
cloud_color = (255, 255, 255, 245)
cloud_shadow = (60, 90, 140, 35)

cx, cy = center, center + 40
puffs = [
    (cx - 130, cy - 20, 90),
    (cx - 50, cy - 80, 110),
    (cx + 60, cy - 60, 100),
    (cx + 140, cy - 10, 85),
    (cx - 90, cy + 30, 100),
    (cx + 30, cy + 40, 110),
    (cx + 120, cy + 50, 90),
]

# Shadow
for x, y, r in puffs:
    draw.ellipse([x - r + 10, y - r + 20, x + r + 10, y + r + 20], fill=cloud_shadow)

# Cloud body
for x, y, r in puffs:
    draw.ellipse([x - r, y - r, x + r, y + r], fill=cloud_color)

# 4. Camera/video indicator - small play button shape at bottom center
play_y = center + 220
play_size = 28
# Draw tiny circle background
draw.ellipse([center - play_size - 4, play_y - play_size - 4,
              center + play_size + 4, play_y + play_size + 4],
             fill=(255, 255, 255, 200), outline=(255, 255, 255, 230), width=3)
# Draw play triangle
draw.polygon([
    (center - 8, play_y - 10),
    (center - 8, play_y + 10),
    (center + 12, play_y),
], fill=(70, 140, 230, 255))

# 5. Subtle top highlight (glassmorphism feel)
highlight = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(highlight)
hl_draw.ellipse([center - 250, center - 300, center + 100, center - 80], fill=(255, 255, 255, 20))
img = Image.alpha_composite(img, highlight)

# 6. Soft outer glow (slightly darker edges for depth)
glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
for i in range(40):
    alpha = int(30 * (1 - i / 40))
    glow_draw.rounded_rectangle([i, i, SIZE - i, SIZE - i], radius=220 - i, outline=(0, 30, 80, alpha), width=1)
img = Image.alpha_composite(img, glow)

# Save
img.save('app_icon_v2.png')
print("Saved app_icon_v2.png ({}x{})".format(SIZE, SIZE))
