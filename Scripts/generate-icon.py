#!/usr/bin/env python3
"""Generate a macOS app icon for DDC Monitor."""

import math
import os
import subprocess
import shutil
from PIL import Image, ImageDraw

SIZE = 1024
CENTER = SIZE / 2
PADDING = SIZE * 0.08


def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: rounded square with deep blue-to-teal gradient
    r = size * 0.185
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [PADDING, PADDING, size - PADDING, size - PADDING],
        radius=r,
        fill=255,
    )

    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / size
        red = int(30 + t * 10)
        green = int(40 + t * 140)
        blue = int(120 + t * 80)
        bg_draw.line([(0, y), (size, y)], fill=(red, green, blue, 255))

    img.paste(bg, mask=mask)
    draw = ImageDraw.Draw(img)

    # Sun center
    sun_cx = CENTER
    sun_cy = CENTER * 0.92
    sun_r = size * 0.14

    # Glow effect
    for i in range(8, 0, -1):
        glow_r = sun_r + i * size * 0.02
        alpha = int(25 - i * 2.5)
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse(
            [sun_cx - glow_r, sun_cy - glow_r, sun_cx + glow_r, sun_cy + glow_r],
            fill=(255, 220, 80, alpha),
        )
        img = Image.alpha_composite(img, glow)

    draw = ImageDraw.Draw(img)

    # Sun body
    draw.ellipse(
        [sun_cx - sun_r, sun_cy - sun_r, sun_cx + sun_r, sun_cy + sun_r],
        fill=(255, 210, 60, 255),
    )

    # Inner sun highlight
    highlight_r = sun_r * 0.65
    highlight_cx = sun_cx - sun_r * 0.1
    highlight_cy = sun_cy - sun_r * 0.15
    draw.ellipse(
        [
            highlight_cx - highlight_r,
            highlight_cy - highlight_r,
            highlight_cx + highlight_r,
            highlight_cy + highlight_r,
        ],
        fill=(255, 235, 130, 255),
    )

    # Sun rays
    num_rays = 8
    ray_inner = sun_r + size * 0.04
    ray_outer = sun_r + size * 0.10
    ray_width = size * 0.028

    for i in range(num_rays):
        angle = (2 * math.pi * i / num_rays) - math.pi / 2
        ix = sun_cx + math.cos(angle) * ray_inner
        iy = sun_cy + math.sin(angle) * ray_inner
        ox = sun_cx + math.cos(angle) * ray_outer
        oy = sun_cy + math.sin(angle) * ray_outer
        draw.line([(ix, iy), (ox, oy)], fill=(255, 210, 60, 230), width=int(ray_width))
        cap_r = ray_width / 2
        draw.ellipse([ox - cap_r, oy - cap_r, ox + cap_r, oy + cap_r], fill=(255, 210, 60, 230))
        draw.ellipse([ix - cap_r, iy - cap_r, ix + cap_r, iy + cap_r], fill=(255, 210, 60, 230))

    # Monitor body
    mon_w = size * 0.52
    mon_h = size * 0.28
    mon_x = CENTER - mon_w / 2
    mon_y = CENTER * 1.12
    mon_r = size * 0.03

    # Monitor shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [mon_x + 4, mon_y + 6, mon_x + mon_w + 4, mon_y + mon_h + 6],
        radius=mon_r,
        fill=(0, 0, 0, 40),
    )
    img = Image.alpha_composite(img, shadow)
    draw = ImageDraw.Draw(img)

    # Monitor frame
    draw.rounded_rectangle(
        [mon_x, mon_y, mon_x + mon_w, mon_y + mon_h],
        radius=mon_r,
        fill=(220, 225, 235, 255),
    )

    # Monitor screen
    scr_pad = size * 0.018
    draw.rounded_rectangle(
        [
            mon_x + scr_pad,
            mon_y + scr_pad,
            mon_x + mon_w - scr_pad,
            mon_y + mon_h - scr_pad * 1.8,
        ],
        radius=mon_r * 0.6,
        fill=(20, 25, 50, 255),
    )

    # Screen glow
    screen_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sg_draw = ImageDraw.Draw(screen_glow)
    sg_draw.rounded_rectangle(
        [
            mon_x + scr_pad,
            mon_y + scr_pad,
            mon_x + mon_w - scr_pad,
            mon_y + mon_h - scr_pad * 1.8,
        ],
        radius=mon_r * 0.6,
        fill=(80, 140, 200, 40),
    )
    img = Image.alpha_composite(img, screen_glow)

    # Monitor stand
    draw = ImageDraw.Draw(img)
    stand_w = size * 0.07
    stand_h = size * 0.05
    stand_x = CENTER - stand_w / 2
    stand_y = mon_y + mon_h
    draw.rectangle(
        [stand_x, stand_y, stand_x + stand_w, stand_y + stand_h],
        fill=(195, 200, 210, 255),
    )

    # Stand base
    base_w = size * 0.16
    base_h = size * 0.018
    base_x = CENTER - base_w / 2
    base_y = stand_y + stand_h
    draw.rounded_rectangle(
        [base_x, base_y, base_x + base_w, base_y + base_h],
        radius=base_h / 2,
        fill=(195, 200, 210, 255),
    )

    return img


def main():
    icon = draw_icon(SIZE)

    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    iconset_dir = os.path.join(project_dir, "Resources", "AppIcon.iconset")

    if os.path.exists(iconset_dir):
        shutil.rmtree(iconset_dir)
    os.makedirs(iconset_dir)

    # Standard macOS iconset naming (required by iconutil)
    entries = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for filename, px in entries:
        resized = icon.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename))

    # Convert to .icns
    icns_path = os.path.join(project_dir, "Resources", "AppIcon.icns")
    subprocess.run(
        ["iconutil", "-c", "icns", iconset_dir, "-o", icns_path],
        check=True,
    )
    print(f"Icon created: {icns_path}")

    # Cleanup iconset
    shutil.rmtree(iconset_dir)

    # Preview
    preview_path = os.path.join(project_dir, "Resources", "AppIcon-preview.png")
    icon.resize((512, 512), Image.LANCZOS).save(preview_path)
    print(f"Preview: {preview_path}")


if __name__ == "__main__":
    main()
