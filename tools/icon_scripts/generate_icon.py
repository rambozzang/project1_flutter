from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
PADDING = 80
img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Rounded square background with gradient (sky blue to deep blue-purple)
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        # Top: bright sky blue, Bottom: deep indigo
        r = int(74 + (30 - 74) * ratio)
        g = int(144 + (64 - 144) * ratio)
        b = int(226 + (175 - 226) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

# 2. Soft rounded corners mask for the background
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
corner_radius = 220
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=corner_radius, fill=255)
img.putalpha(mask)

# 3. Camera lens outer ring (dark translucent)
center = SIZE // 2
lens_outer = 360
lens_inner = 300
draw.ellipse([center - lens_outer, center - lens_outer, center + lens_outer, center + lens_outer],
             fill=(20, 30, 60, 200), outline=(255, 255, 255, 60), width=8)

# 4. Lens inner sky gradient
lens_img = Image.new('RGBA', (lens_inner * 2, lens_inner * 2), (0, 0, 0, 0))
lens_draw = ImageDraw.Draw(lens_img)
for y in range(lens_inner * 2):
    ratio = y / (lens_inner * 2)
    r = int(135 + (70 - 135) * ratio)
    g = int(206 + (130 - 206) * ratio)
    b = int(235 + (180 - 235) * ratio)
    lens_draw.line([(0, y), (lens_inner * 2, y)], fill=(r, g, b, 255))

# Circular mask for lens
lens_mask = Image.new('L', (lens_inner * 2, lens_inner * 2), 0)
lens_mask_draw = ImageDraw.Draw(lens_mask)
lens_mask_draw.ellipse([0, 0, lens_inner * 2, lens_inner * 2], fill=255)
lens_img.putalpha(lens_mask)

# Paste lens
img.paste(lens_img, (center - lens_inner, center - lens_inner), lens_img)

# 5. Sun (warm yellow-orange) behind cloud
sun_x = center + 70
sun_y = center - 90
sun_radius = 90
sun_img = Image.new('RGBA', (lens_inner * 2, lens_inner * 2), (0, 0, 0, 0))
sun_draw = ImageDraw.Draw(sun_img)
for r in range(sun_radius, 0, -1):
    ratio = r / sun_radius
    red = int(255)
    green = int(200 + (120 - 200) * ratio)
    blue = int(80 + (40 - 80) * ratio)
    alpha = int(255 * (1 - ratio * 0.7))
    sun_draw.ellipse([sun_x - r - (center - lens_inner), sun_y - r - (center - lens_inner),
                      sun_x + r - (center - lens_inner), sun_y + r - (center - lens_inner)],
                     fill=(red, green, blue, alpha))

sun_mask = Image.new('L', (lens_inner * 2, lens_inner * 2), 0)
sun_mask_draw = ImageDraw.Draw(sun_mask)
sun_mask_draw.ellipse([0, 0, lens_inner * 2, lens_inner * 2], fill=255)
sun_img.putalpha(sun_mask)

img.paste(sun_img, (center - lens_inner, center - lens_inner), sun_img)

# 6. Cloud (modern simple cloud shape)
cloud_color = (255, 255, 255, 240)

# Cloud puffs
cx, cy = center - 20, center + 20
puffs = [
    (cx - 90, cy - 40, 70),
    (cx - 30, cy - 70, 80),
    (cx + 50, cy - 50, 75),
    (cx + 100, cy - 10, 65),
    (cx - 60, cy + 10, 75),
    (cx + 20, cy + 20, 85),
    (cx + 90, cy + 30, 70),
]

# Draw cloud shadow/depth first
for x, y, r in puffs:
    draw.ellipse([x - r + 8, y - r + 12, x + r + 8, y + r + 12], fill=(200, 210, 230, 40))

# Draw cloud
for x, y, r in puffs:
    draw.ellipse([x - r, y - r, x + r, y + r], fill=cloud_color)

# 7. Small camera dot (bottom right of lens ring)
draw.ellipse([center + 220, center + 230, center + 250, center + 260], fill=(255, 255, 255, 180))

# 8. Subtle highlight on lens (top-left gloss)
gloss = Image.new('RGBA', (lens_inner * 2, lens_inner * 2), (0, 0, 0, 0))
gloss_draw = ImageDraw.Draw(gloss)
gloss_draw.ellipse([40, 40, 180, 180], fill=(255, 255, 255, 30))
gloss.putalpha(lens_mask)
img.paste(gloss, (center - lens_inner, center - lens_inner), gloss)

# Save
img.save('app_icon.png')
print("Saved app_icon.png ({}x{})".format(SIZE, SIZE))
