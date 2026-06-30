from PIL import Image, ImageDraw

# Load the rounded icon
img = Image.open('app_icon_v3.png').convert('RGBA')
size = img.width
center = size // 2
lens_outer = 340  # Must match generate_icon_v3.py

# Create mask: circle for lens area, transparent outside
mask = Image.new('L', (size, size), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.ellipse([center - lens_outer, center - lens_outer,
                   center + lens_outer, center + lens_outer], fill=255)

# Apply mask
result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
result.paste(img, (0, 0), mask)

result.save('app_icon_adaptive_fore.png')
print("Saved app_icon_adaptive_fore.png ({}x{})".format(size, size))
