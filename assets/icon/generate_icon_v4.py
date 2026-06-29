from PIL import Image, ImageDraw
import math

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Vibrant rounded square background: sunset/purple-blue gradient
def draw_gradient_bg(draw, size):
    for y in range(size):
        ratio = y / size
        # Top: warm coral/pink, Middle: purple, Bottom: deep blue
        if ratio < 0.5:
            r = int(255 - (255 - 120) * (ratio * 2))
            g = int(120 + (80 - 120) * (ratio * 2))
            b = int(180 + (220 - 180) * (ratio * 2))
        else:
            r = int(120 - (120 - 30) * ((ratio - 0.5) * 2))
            g = int(80 + (60 - 80) * ((ratio - 0.5) * 2))
            b = int(220 + (200 - 220) * ((ratio - 0.5) * 2))
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

draw_gradient_bg(draw, SIZE)

# Rounded corners mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# 2. Phone/video screen frame (vertical, rounded corners)
screen_w, screen_h = 420, 680
screen_left = center - screen_w // 2
screen_top = center - screen_h // 2
screen_right = screen_left + screen_w
screen_bottom = screen_top + screen_h
screen_radius = 50

# Screen outer shadow
draw.rounded_rectangle([screen_left + 15, screen_top + 15, screen_right + 15, screen_bottom + 15],
                       radius=screen_radius, fill=(0, 0, 0, 60))

# Screen bezel
draw.rounded_rectangle([screen_left, screen_top, screen_right, screen_bottom],
                       radius=screen_radius, fill=(20, 25, 45, 230), outline=(255, 255, 255, 80), width=6)

# 3. Screen content - sky gradient inside screen
screen = Image.new('RGBA', (screen_w, screen_h), (0, 0, 0, 0))
screen_draw = ImageDraw.Draw(screen)
for y in range(screen_h):
    ratio = y / screen_h
    r = int(80 + (40 - 80) * ratio)
    g = int(180 + (100 - 180) * ratio)
    b = int(255 + (200 - 255) * ratio)
    screen_draw.line([(0, y), (screen_w, y)], fill=(r, g, b, 255))

# Rounded mask for screen content
screen_mask = Image.new('L', (screen_w, screen_h), 0)
sm_draw = ImageDraw.Draw(screen_mask)
sm_draw.rounded_rectangle([8, 8, screen_w - 8, screen_h - 8], radius=screen_radius - 8, fill=255)
screen.putalpha(screen_mask)

img.paste(screen, (screen_left, screen_top), screen)

# 4. Play button in center of screen
play_y = center
play_size = 55
# Circle background
draw.ellipse([center - play_size - 6, play_y - play_size - 6,
              center + play_size + 6, play_y + play_size + 6],
             fill=(255, 255, 255, 220))
# Play triangle
draw.polygon([
    (center - 18, play_y - 22),
    (center - 18, play_y + 22),
    (center + 24, play_y),
], fill=(255, 100, 120, 255))

# 5. Viewfinder corners around the screen (camera vibe)
corner_len = 45
corner_offset = 25
corner_color = (255, 255, 255, 180)
corner_width = 8

corners = [
    # top-left
    (screen_left - corner_offset, screen_top - corner_offset),
    # top-right
    (screen_right + corner_offset - corner_len, screen_top - corner_offset),
    # bottom-left
    (screen_left - corner_offset, screen_bottom + corner_offset - corner_len),
    # bottom-right
    (screen_right + corner_offset - corner_len, screen_bottom + corner_offset - corner_len),
]

# Draw L-shaped corners
for i, (x, y) in enumerate(corners):
    if i == 0:  # top-left: right + down
        draw.line([(x, y), (x + corner_len, y)], fill=corner_color, width=corner_width)
        draw.line([(x, y), (x, y + corner_len)], fill=corner_color, width=corner_width)
    elif i == 1:  # top-right: left + down
        draw.line([(x + corner_len, y), (x, y)], fill=corner_color, width=corner_width)
        draw.line([(x + corner_len, y), (x + corner_len, y + corner_len)], fill=corner_color, width=corner_width)
    elif i == 2:  # bottom-left: right + up
        draw.line([(x, y + corner_len), (x + corner_len, y + corner_len)], fill=corner_color, width=corner_width)
        draw.line([(x, y + corner_len), (x, y)], fill=corner_color, width=corner_width)
    else:  # bottom-right: left + up
        draw.line([(x + corner_len, y + corner_len), (x, y + corner_len)], fill=corner_color, width=corner_width)
        draw.line([(x + corner_len, y + corner_len), (x + corner_len, y)], fill=corner_color, width=corner_width)

# 6. Progress dots at bottom of screen (video indicator)
dot_y = screen_bottom - 50
dot_count = 5
dot_spacing = 35
start_x = center - ((dot_count - 1) * dot_spacing) // 2
for i in range(dot_count):
    x = start_x + i * dot_spacing
    if i == 2:
        draw.ellipse([x - 6, dot_y - 6, x + 6, dot_y + 6], fill=(255, 255, 255, 230))
    else:
        draw.ellipse([x - 5, dot_y - 5, x + 5, dot_y + 5], fill=(255, 255, 255, 80))

# 7. Top subtle gloss
gloss = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(gloss)
hl_draw.ellipse([center - 250, center - 300, center + 100, center - 80], fill=(255, 255, 255, 20))
img = Image.alpha_composite(img, gloss)

# Save rounded version (for preview)
img.save('app_icon_v4.png')
print("Saved app_icon_v4.png ({}x{})".format(SIZE, SIZE))

# Save square version (for iOS / flutter_launcher_icons)
bg = Image.new('RGBA', (SIZE, SIZE), (30, 60, 200, 255))
square = Image.alpha_composite(bg, img)
square.save('app_icon_v4_square.png')
print("Saved app_icon_v4_square.png ({}x{})".format(SIZE, SIZE))
