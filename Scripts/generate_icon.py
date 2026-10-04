import os
import subprocess
from PIL import Image, ImageDraw, ImageFilter

def make_macos_icon():
    src_path = '/Users/alex/.gemini/antigravity/brain/509f231b-bb3c-4a32-8422-0df66ee889e9/vidtsx_2d_prism_1791100353181.jpg'
    img = Image.open(src_path).convert('RGBA')
    w, h = img.size

    # 1. Точные границы сквиркла (с небольшим отступом внутрь на 2px, чтобы исключить серые пиксели)
    left = 207
    top = 207
    right = 817
    bottom = 817
    
    cropped = img.crop((left, top, right, bottom))
    
    # 2. Целевой размер сквиркла по гайдлайнам macOS Sequoia (836x836 внутри 1024x1024)
    target_size = 836
    canvas_size = 1024
    corner_radius = 188 # ~22.5% от ширины
    
    resized_content = cropped.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    # 3. Создание высокоточечной сглаженной маски сквиркла (через 4x supersampling)
    scale = 4
    mask_large = Image.new('L', (target_size * scale, target_size * scale), 0)
    draw_large = ImageDraw.Draw(mask_large)
    draw_large.rounded_rectangle(
        [0, 0, target_size * scale - 1, target_size * scale - 1],
        radius=corner_radius * scale,
        fill=255
    )
    mask = mask_large.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    # Применяем маску к контенту
    masked_icon = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    masked_icon.paste(resized_content, (0, 0), mask)
    
    # 4. Создаем итоговый холст 1024x1024 с прозрачным фоном
    final_canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    
    # Координаты центрирования
    pos_x = (canvas_size - target_size) // 2
    pos_y = (canvas_size - target_size) // 2 - 8 # Легкое смещение вверх под системную тень
    
    # 5. Мягкая нативная системная тень macOS (2 слоя: контактная + рассеянная)
    # Слой 1: рассеянная тень
    shadow_layer = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_mask_1 = mask.copy()
    shadow_img_1 = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 75))
    shadow_layer.paste(shadow_img_1, (pos_x, pos_y + 16), shadow_mask_1)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=22))
    
    # Слой 2: контактная тень
    contact_shadow = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_img_2 = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 90))
    contact_shadow.paste(shadow_img_2, (pos_x, pos_y + 8), shadow_mask_1)
    contact_shadow = contact_shadow.filter(ImageFilter.GaussianBlur(radius=10))
    
    # Накладываем тени и сам значок
    final_canvas.alpha_composite(shadow_layer)
    final_canvas.alpha_composite(contact_shadow)
    final_canvas.alpha_composite(masked_icon, (pos_x, pos_y))
    
    # Сохраняем мастер-PNG
    master_png = 'Resources/AppIcon_Master.png'
    final_canvas.save(master_png, 'PNG')
    print(f'Мастер-иконка сохранена: {master_png}')
    
    # 6. Генерация всех Retina и non-Retina размеров для iconset
    iconset_dir = 'Resources/AppIcon.iconset'
    os.makedirs(iconset_dir, exist_ok=True)
    
    sizes = [
        (16, 'icon_16x16.png'),
        (32, 'icon_16x16@2x.png'),
        (32, 'icon_32x32.png'),
        (64, 'icon_32x32@2x.png'),
        (128, 'icon_128x128.png'),
        (256, 'icon_128x128@2x.png'),
        (256, 'icon_256x256.png'),
        (512, 'icon_256x256@2x.png'),
        (512, 'icon_512x512.png'),
        (1024, 'icon_512x512@2x.png'),
    ]
    
    for sz, name in sizes:
        resized = final_canvas.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, name), 'PNG')
    
    # 7. Компиляция в .icns через системную утилиту Apple
    icns_path = 'Resources/AppIcon.icns'
    subprocess.run(['iconutil', '-c', 'icns', iconset_dir, '-o', icns_path], check=True)
    subprocess.run(['rm', '-rf', iconset_dir, master_png], check=True)
    print(f'Скомпилирован {icns_path} с идеальным прозрачным альфа-каналом и габаритами macOS')

if __name__ == '__main__':
    make_macos_icon()
