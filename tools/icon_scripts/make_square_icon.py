from PIL import Image

# Load the rounded icon
img = Image.open('app_icon_v3.png').convert('RGBA')
size = img.width

# Create square background with bottom gradient color (fallback fill)
bg = Image.new('RGBA', (size, size), (30, 80, 230, 255))

# Composite: background first, then icon
result = Image.alpha_composite(bg, img)

# Remove alpha by pasting onto opaque background
result_no_alpha = Image.new('RGBA', (size, size), (30, 80, 230, 255))
result_no_alpha.paste(result, (0, 0), result)

result_no_alpha.save('app_icon_square.png')
print("Saved app_icon_square.png ({}x{})".format(size, size))
