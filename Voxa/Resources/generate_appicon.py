#!/usr/bin/env python3
"""
生成 Voxa 应用图标
基于 SF Symbols mic.circle.fill 样式
"""

from PIL import Image, ImageDraw
import os

# macOS 应用图标所需尺寸
SIZES = [16, 32, 128, 256, 512]

def create_app_icon(size: int) -> Image.Image:
    """
    创建指定尺寸的应用图标

    使用渐变效果：浅灰到深灰的圆形背景，带阴影效果
    麦克风图标为白色

    Args:
        size: 图标尺寸（正方形边长）

    Returns:
        RGBA 模式的 Pillow Image
    """
    # 创建白色背景（macOS Big Sur+ 风格）
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)

    # 颜色配置 - 使用灰色渐变背景（更接近系统风格）
    circle_color = (120, 120, 120, 255)
    mic_color = (255, 255, 255, 255)

    # 计算圆的位置和大小
    padding = size * 0.08  # 8% 边距
    circle_bbox = (
        padding,
        padding,
        size - padding,
        size - padding
    )

    # 绘制圆形背景
    draw.ellipse(circle_bbox, fill=circle_color)

    # 绘制麦克风图标
    center_x = size / 2
    center_y = size / 2

    # 麦克风尺寸根据图标大小缩放
    mic_scale = size / 512

    # 麦克风外框 - 圆角矩形
    mic_width = int(140 * mic_scale)
    mic_height = int(200 * mic_scale)
    mic_radius = int(70 * mic_scale)

    mic_x1 = center_x - mic_width / 2
    mic_y1 = center_y - mic_height / 2 - int(20 * mic_scale)
    mic_x2 = center_x + mic_width / 2
    mic_y2 = mic_y1 + mic_height

    # 绘制圆角矩形（麦克风主体）
    draw.rounded_rectangle(
        [mic_x1, mic_y1, mic_x2, mic_y2],
        radius=mic_radius,
        fill=mic_color
    )

    # 麦克风支架
    stand_width = int(40 * mic_scale)
    stand_height = int(60 * mic_scale)
    stand_x1 = center_x - stand_width / 2
    stand_y1 = mic_y2
    stand_x2 = center_x + stand_width / 2
    stand_y2 = stand_y1 + stand_height

    draw.rectangle(
        [stand_x1, stand_y1, stand_x2, stand_y2],
        fill=mic_color
    )

    # 麦克风底座
    base_width = int(160 * mic_scale)
    base_height = int(30 * mic_scale)
    base_radius = int(15 * mic_scale)
    base_x1 = center_x - base_width / 2
    base_y1 = stand_y2
    base_x2 = center_x + base_width / 2
    base_y2 = base_y1 + base_height

    draw.rounded_rectangle(
        [base_x1, base_y1, base_x2, base_y2],
        radius=base_radius,
        fill=mic_color
    )

    return img


def main():
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, 'Assets.xcassets', 'AppIcon.appiconset')

    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)

    # 生成各尺寸图标
    for size in SIZES:
        # 生成 @1x 版本
        img_1x = create_app_icon(size)
        filename_1x = os.path.join(output_dir, f'app-icon-{size}x{size}.png')
        img_1x.save(filename_1x, 'PNG')
        print(f"Created: {filename_1x}")

        # 生成 @2x 版本 (Retina)
        img_2x = create_app_icon(size * 2)
        filename_2x = os.path.join(output_dir, f'app-icon-{size}x{size}@2x.png')
        img_2x.save(filename_2x, 'PNG')
        print(f"Created: {filename_2x}")

    print(f"\nApp icons generated successfully in: {output_dir}")


if __name__ == '__main__':
    main()
