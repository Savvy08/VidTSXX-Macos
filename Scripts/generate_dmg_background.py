import os
from PIL import Image, ImageDraw

def create_dmg_background():
    # 2x Retina разрешение для окна 660x440
    w = 1320
    h = 880
    
    # Чистый белый фон
    bg_color = (255, 255, 255, 255)
    img = Image.new('RGBA', (w, h), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Четкая контрастная стрелка темно-графитового цвета
    arrow_color = (45, 48, 58, 255) # Темный графит
    line_width = 8
    
    start_x = 540
    end_x = 780
    center_y = 430
    
    # 1. Горизонтальная линия стрелки
    draw.line([(start_x, center_y), (end_x, center_y)], fill=arrow_color, width=line_width)
    
    # 2. Наконечник стрелки (шеврон)
    head_len = 40
    head_width = 34
    
    draw.line([(end_x - head_len, center_y - head_width), (end_x, center_y)], fill=arrow_color, width=line_width)
    draw.line([(end_x - head_len, center_y + head_width), (end_x, center_y)], fill=arrow_color, width=line_width)
    
    # Скругление кончиков
    r = line_width // 2
    for pt in [
        (start_x, center_y),
        (end_x, center_y),
        (end_x - head_len, center_y - head_width),
        (end_x - head_len, center_y + head_width)
    ]:
        draw.ellipse([pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r], fill=arrow_color)
    
    out_path = 'Resources/dmg_background.png'
    os.makedirs('Resources', exist_ok=True)
    img.save(out_path, 'PNG')
    print(f'Белый фон DMG со стрелкой сохранен в {out_path}')

if __name__ == '__main__':
    create_dmg_background()
