import math
from PIL import Image, ImageDraw

SIZE = 1024
center = SIZE // 2

# 1. Helper to get gradient color
def get_gradient_color(p):
    # p is from 0.0 to 1.0
    if p < 0.48:
        # Interpolate between Sunrise Gold (#FFCB6B) and Coral (#FF8F8F)
        t = p / 0.48
        r = int(255)
        g = int(203 + (143 - 203) * t)
        b = int(107 + (143 - 107) * t)
    else:
        # Interpolate between Coral (#FF8F8F) and Sunset Pink (#FF6FA6)
        t = (p - 0.48) / 0.52
        r = int(255)
        g = int(143 + (111 - 143) * t)
        b = int(143 + (166 - 143) * t)
    return (r, g, b, 255)

# 2. Draw the diagonal gradient background
# Create a 1D gradient of size 2048x1 and rotate it by 30 degrees (to approximate 150/160deg)
grad_1d = Image.new('RGBA', (2048, 1))
for x in range(2048):
    color = get_gradient_color(x / 2047.0)
    grad_1d.putpixel((x, 0), color)

grad_2d = grad_1d.resize((2048, 2048))
grad_rotated = grad_2d.rotate(30, resample=Image.Resampling.BICUBIC)
bg_gradient = grad_rotated.crop((512, 512, 1536, 1536))

# 3. Draw the cloud logo shapes
# Coords scaled from 100x100 viewBox to 548x548 size centered inside 1024x1024
# Scale: 5.48, Offset: 238
def draw_logo(draw, offset_x=238, offset_y=238, scale=5.48, fill_color=(255, 255, 255, 255)):
    # Circle 1: cx=38, cy=50, r=19
    cx1, cy1, r1 = offset_x + 38 * scale, offset_y + 50 * scale, 19 * scale
    draw.ellipse([cx1 - r1, cy1 - r1, cx1 + r1, cy1 + r1], fill=fill_color)
    
    # Circle 2: cx=60, cy=45, r=23
    cx2, cy2, r2 = offset_x + 60 * scale, offset_y + 45 * scale, 23 * scale
    draw.ellipse([cx2 - r2, cy2 - r2, cx2 + r2, cy2 + r2], fill=fill_color)
    
    # Circle 3: cx=27, cy=59, r=13
    cx3, cy3, r3 = offset_x + 27 * scale, offset_y + 59 * scale, 13 * scale
    draw.ellipse([cx3 - r3, cy3 - r3, cx3 + r3, cy3 + r3], fill=fill_color)
    
    # Circle 4: cx=74, cy=59, r=14
    cx4, cy4, r4 = offset_x + 74 * scale, offset_y + 59 * scale, 14 * scale
    draw.ellipse([cx4 - r4, cy4 - r4, cx4 + r4, cy4 + r4], fill=fill_color)
    
    # Rectangle: x=25, y=55, w=54, h=20, rx=10 (bounds [25, 55, 79, 75])
    rx = 10 * scale
    x1, y1 = offset_x + 25 * scale, offset_y + 55 * scale
    x2, y2 = offset_x + 79 * scale, offset_y + 75 * scale
    draw.rounded_rectangle([x1, y1, x2, y2], radius=rx, fill=fill_color)
    
    # Triangle (polygon): points = (45, 71), (37, 90), (56, 73)
    p1 = (offset_x + 45 * scale, offset_y + 71 * scale)
    p2 = (offset_x + 37 * scale, offset_y + 90 * scale)
    p3 = (offset_x + 56 * scale, offset_y + 73 * scale)
    draw.polygon([p1, p2, p3], fill=fill_color)

# Generate square icon with logo
square_icon = bg_gradient.copy()
draw_square = ImageDraw.Draw(square_icon)
draw_logo(draw_square)
square_icon.save('app_icon_v10_square.png')
print("Saved app_icon_v10_square.png")

# Generate rounded icon
# Start with transparent canvas
rounded_icon = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw_mask = ImageDraw.Draw(rounded_icon)
# Draw rounded rectangle mask
draw_mask.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=(255, 255, 255, 255))
# Composite rounded rectangle mask with background gradient
rounded_icon = Image.composite(bg_gradient, rounded_icon, rounded_icon.split()[3])
# Draw logo
draw_rounded = ImageDraw.Draw(rounded_icon)
draw_logo(draw_rounded)
rounded_icon.save('app_icon_v10.png')
print("Saved app_icon_v10.png")

# Generate Android adaptive foreground
# Just the logo in white, on a transparent background, padded (size 512x512 in center)
# Center size 512 means offset_x = (1024 - 512) / 2 = 256, offset_y = 256. scale = 5.12
foreground_icon = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw_fg = ImageDraw.Draw(foreground_icon)
draw_logo(draw_fg, offset_x=256, offset_y=256, scale=5.12)
foreground_icon.save('app_icon_v10_foreground.png')
print("Saved app_icon_v10_foreground.png")
