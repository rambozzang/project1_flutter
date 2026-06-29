from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Vibrant rounded square background: sky blue -> electric blue
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        r = int(50 + (20 - 50) * ratio)
        g = int(160 + (80 - 160) * ratio)
        b = int(255 + (230 - 255) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# 2. Camera lens ring (metallic dark blue)
ring_outer = 340
ring_inner = 310
draw.ellipse([center - ring_outer, center - ring_outer, center + ring_outer, center + ring_outer],
             fill=(15, 35, 75, 230))
draw.ellipse([center - ring_inner, center - ring_inner, center + ring_inner, center + ring_inner],
             fill=(25, 55, 110, 255), outline=(255, 255, 255, 40), width=4)

# 3. Lens glass - bright sky scene
lens_r = 290
lens = Image.new('RGBA', (lens_r * 2, lens_r * 2), (0, 0, 0, 0))
lens_draw = ImageDraw.Draw(lens)

# Sky gradient inside lens
for y in range(lens_r * 2):
    ratio = y / (lens_r * 2)
    r = int(120 + (60 - 120) * ratio)
    g = int(210 + (140 - 210) * ratio)
    b = int(255 + (210 - 255) * ratio)
    lens_draw.line([(0, y), (lens_r * 2, y)], fill=(r, g, b, 255))

# Sun - vivid yellow-orange, top right
sun_x, sun_y = lens_r + 90, lens_r - 110
sun_r = 95
for rad in range(sun_r, 0, -2):
    ratio = rad / sun_r
    red = 255
    green = int(240 - 110 * ratio)
    blue = int(100 - 60 * ratio)
    alpha = int(255 * (1 - ratio * 0.4))
    lens_draw.ellipse([sun_x - rad, sun_y - rad, sun_x + rad, sun_y + rad],
                      fill=(red, green, blue, alpha))

# Cloud - white with soft blue shadow
cx, cy = lens_r, lens_r + 50
puffs = [
    (cx - 110, cy - 30, 80),
    (cx - 40, cy - 80, 95),
    (cx + 50, cy - 60, 90),
    (cx + 120, cy - 10, 75),
    (cx - 70, cy + 30, 90),
    (cx + 30, cy + 40, 100),
    (cx + 110, cy + 45, 80),
]

# Soft shadow
for x, y, r in puffs:
    lens_draw.ellipse([x - r + 8, y - r + 16, x + r + 8, y + r + 16], fill=(40, 90, 150, 45))

# Cloud body
for x, y, r in puffs:
    lens_draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 250))

# Lens circular mask
lens_mask = Image.new('L', (lens_r * 2, lens_r * 2), 0)
lens_mask_draw = ImageDraw.Draw(lens_mask)
lens_mask_draw.ellipse([0, 0, lens_r * 2, lens_r * 2], fill=255)
lens.putalpha(lens_mask)

img.paste(lens, (center - lens_r, center - lens_r), lens)

# 4. Glass highlight (top-left subtle arc)
hl = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(hl)
hl_draw.arc([center - 230, center - 230, center + 50, center + 50], start=140, end=230,
            fill=(255, 255, 255, 35), width=20)
img = Image.alpha_composite(img, hl)

# 5. Camera indicator dot (bottom right)
draw.ellipse([center + 245, center + 255, center + 275, center + 285],
             fill=(255, 255, 255, 220))

# 6. Bottom app name hint - tiny "S" mark using circle arc
s_mark = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(s_mark)
# Stylized S as two arcs
s_draw.arc([center - 20, center + 240, center + 20, center + 280], start=200, end=340,
           fill=(255, 255, 255, 0), width=6)
s_draw.arc([center - 20, center + 250, center + 20, center + 290], start=20, end=160,
           fill=(255, 255, 255, 0), width=6)
# Skip S mark, play button is enough

# Save
img.save('app_icon_v3.png')
print("Saved app_icon_v3.png ({}x{})".format(SIZE, SIZE))
