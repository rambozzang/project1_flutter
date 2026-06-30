from PIL import Image, ImageDraw
import math

SIZE = 1024
center = SIZE // 2

def draw_pin(draw, cx, cy, size, body_color, play_color):
    head_r = size // 2
    head_y = cy - size // 3
    tip_y = cy + size // 1.2

    # Pin body (triangle from head to tip)
    pin_points = [
        (cx - head_r * 0.7, head_y),
        (cx + head_r * 0.7, head_y),
        (cx, tip_y),
    ]
    draw.polygon(pin_points, fill=body_color)

    # Pin head circle
    draw.ellipse([cx - head_r, head_y - head_r, cx + head_r, head_y + head_r],
                 fill=body_color)

    # Inner circle (lighter)
    inner_r = head_r * 0.55
    draw.ellipse([cx - inner_r, head_y - inner_r, cx + inner_r, head_y + inner_r],
                 fill=(255, 255, 255, 230))

    # Play triangle inside pin head
    play_size = inner_r * 0.6
    draw.polygon([
        (cx - play_size * 0.4, head_y - play_size * 0.5),
        (cx - play_size * 0.4, head_y + play_size * 0.5),
        (cx + play_size * 0.6, head_y),
    ], fill=play_color)

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Rounded square background: Instagram/TikTok vibe gradient
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        # Top: warm coral, Middle: magenta-purple, Bottom: deep blue
        if ratio < 0.35:
            r = int(255)
            g = int(120 + (80 - 120) * (ratio / 0.35))
            b = int(100 + (160 - 100) * (ratio / 0.35))
        elif ratio < 0.7:
            r = int(255 - (255 - 150) * ((ratio - 0.35) / 0.35))
            g = int(80 - (80 - 50) * ((ratio - 0.35) / 0.35))
            b = int(160 + (220 - 160) * ((ratio - 0.35) / 0.35))
        else:
            r = int(150 - (150 - 30) * ((ratio - 0.7) / 0.3))
            g = int(50 - (50 - 30) * ((ratio - 0.7) / 0.3))
            b = int(220 + (200 - 220) * ((ratio - 0.7) / 0.3))
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# 2. Soft circular glow behind pin
glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
for r in range(300, 0, -10):
    alpha = int(30 * (1 - r / 300))
    glow_draw.ellipse([center - r, center - r, center + r, center + r],
                      fill=(255, 255, 255, alpha))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# 3. Draw pin
draw_pin(draw, center, center, 260, (255, 255, 255, 250), (255, 90, 130, 255))

# 4. Bottom location ring (subtle)
ring_y = center + 230
ring_w, ring_h = 160, 50
draw.ellipse([center - ring_w, ring_y - ring_h, center + ring_w, ring_y + ring_h],
             fill=(0, 0, 0, 40), outline=(255, 255, 255, 30), width=3)

# 5. Top gloss
gloss = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(gloss)
hl_draw.ellipse([center - 200, center - 280, center + 80, center - 120], fill=(255, 255, 255, 12))
img = Image.alpha_composite(img, gloss)

# Save rounded version
img.save('app_icon_v6.png')
print("Saved app_icon_v6.png ({}x{})".format(SIZE, SIZE))

# Save square version for iOS
bg = Image.new('RGBA', (SIZE, SIZE), (30, 30, 200, 255))
square = Image.alpha_composite(bg, img)
square.save('app_icon_v6_square.png')
print("Saved app_icon_v6_square.png ({}x{})".format(SIZE, SIZE))
