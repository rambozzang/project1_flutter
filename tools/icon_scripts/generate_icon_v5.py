from PIL import Image, ImageDraw
import math

SIZE = 1024
center = SIZE // 2

def round_rect(draw, xy, radius, fill, outline=None, width=1):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

def draw_rounded_line(draw, p1, p2, thickness, fill):
    x1, y1 = p1
    x2, y2 = p2
    dx, dy = x2 - x1, y2 - y1
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    nx, ny = -uy, ux
    half = thickness / 2
    points = [
        (x1 + nx * half, y1 + ny * half),
        (x2 + nx * half, y2 + ny * half),
        (x2 - nx * half, y2 - ny * half),
        (x1 - nx * half, y1 - ny * half),
    ]
    draw.polygon(points, fill=fill)
    draw.ellipse([x1 - half, y1 - half, x1 + half, y1 + half], fill=fill)
    draw.ellipse([x2 - half, y2 - half, x2 + half, y2 + half], fill=fill)

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Rounded square background: deep purple -> electric blue
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        r = int(40 + (15 - 40) * ratio)
        g = int(30 + (80 - 30) * ratio)
        b = int(100 + (220 - 100) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# 2. Subtle inner glow ring
draw.ellipse([center - 360, center - 360, center + 360, center + 360],
             outline=(255, 255, 255, 25), width=2)

# 3. S monogram - modern, thick rounded bars
# S tilted slightly for dynamic feel
tilt = 0  # Keep straight for simplicity and readability
bar_thickness = 75

# Top bar: left to right
top_y = center - 140
top_left = (center - 150, top_y)
top_right = (center + 150, top_y)
draw_rounded_line(draw, top_left, top_right, bar_thickness, (255, 255, 255, 255))

# Diagonal bar: top-right to bottom-left
mid_top = (center + 150, top_y)
mid_bottom = (center - 150, center + 140)
draw_rounded_line(draw, mid_top, mid_bottom, bar_thickness, (255, 255, 255, 255))

# Bottom bar: left to right
bottom_y = center + 140
bottom_left = (center - 150, bottom_y)
bottom_right = (center + 150, bottom_y)
draw_rounded_line(draw, bottom_left, bottom_right, bar_thickness, (255, 255, 255, 255))

# 4. Small accent dot (snap/camera indicator)
draw.ellipse([center + 220, center + 240, center + 250, center + 270], fill=(255, 200, 80, 230))

# 5. Top-left soft gloss
gloss = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(gloss)
hl_draw.ellipse([center - 240, center - 280, center + 80, center - 100], fill=(255, 255, 255, 15))
img = Image.alpha_composite(img, gloss)

# Save rounded version
img.save('app_icon_v5.png')
print("Saved app_icon_v5.png ({}x{})".format(SIZE, SIZE))

# Save square version for iOS
bg = Image.new('RGBA', (SIZE, SIZE), (15, 80, 220, 255))
square = Image.alpha_composite(bg, img)
square.save('app_icon_v5_square.png')
print("Saved app_icon_v5_square.png ({}x{})".format(SIZE, SIZE))
