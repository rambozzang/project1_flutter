from PIL import Image, ImageDraw

SIZE = 1024
center = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
draw = ImageDraw.Draw(img)

# 1. Solid sky-blue background
bg_color = (74, 144, 226, 255)  # Sky blue
draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=bg_color)

# 2. White camera body with rounded corners
body_w, body_h = 420, 300
body_left = center - body_w // 2
body_top = center - body_h // 2 + 20
body_right = body_left + body_w
body_bottom = body_top + body_h
body_radius = 45

draw.rounded_rectangle([body_left, body_top, body_right, body_bottom],
                       radius=body_radius, fill=(255, 255, 255, 245))

# 3. Lens (dark blue circle with white ring)
lens_r = 90
lens_x, lens_y = center, center + 20
draw.ellipse([lens_x - lens_r, lens_y - lens_r, lens_x + lens_r, lens_y + lens_r],
             fill=(10, 36, 99, 255), outline=(200, 220, 255, 200), width=8)

# Inner lens highlight
inner_r = 45
draw.ellipse([lens_x - inner_r, lens_y - inner_r, lens_x + inner_r, lens_y + inner_r],
             fill=(30, 70, 150, 255))

# Lens glossy dot
draw.ellipse([lens_x - 25, lens_y - 35, lens_x - 5, lens_y - 15], fill=(255, 255, 255, 180))

# 4. Flash dot (top right of camera body)
draw.ellipse([body_right - 70, body_top + 35, body_right - 40, body_top + 65], fill=(255, 200, 80, 230))

# 5. Viewfinder bump (top of camera)
bump_w, bump_h = 120, 30
bump_left = center - bump_w // 2
bump_top = body_top - bump_h + 10
draw.rounded_rectangle([bump_left, bump_top, bump_left + bump_w, bump_top + bump_h],
                       radius=15, fill=(255, 255, 255, 245))

# 6. Small brand dot (bottom right outside camera)
draw.ellipse([center + 220, center + 240, center + 250, center + 270], fill=(255, 255, 255, 200))

# Save rounded version
img.save('app_icon_v9.png')
print("Saved app_icon_v9.png ({}x{})".format(SIZE, SIZE))

# Save square version for iOS/App Store
square = Image.new('RGBA', (SIZE, SIZE), bg_color)
square.paste(img, (0, 0), img)
square.save('app_icon_v9_square.png')
print("Saved app_icon_v9_square.png ({}x{})".format(SIZE, SIZE))
