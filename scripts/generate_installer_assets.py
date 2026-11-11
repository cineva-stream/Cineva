"""
Generates high-end visual assets for the Cineva Windows Setup Installer (Inno Setup):
1. marquee_strip.bmp: A seamless horizontally-tileable Cinema Poster Wall Marquee
   featuring angled movie & TV series posters from assets/images/, rounded corners,
   drop shadows, Obsidian vignette gradients (#07070A -> #0E0E14), and Cinema Amber
   (#FF9500) ambient lighting.
2. brand_logo.bmp: Crisp 32x32 Cineva icon pre-composited on #07070A Obsidian background
   for the custom installer top bar.
"""

import math
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


def create_rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def prepare_poster_card(img_path, card_w=104, card_h=152, radius=10):
    img = Image.open(img_path).convert("RGBA")
    # Crop/resize to cover card_w x card_h (2:3 aspect ratio)
    img = img.resize((card_w, card_h), Image.Resampling.LANCZOS)

    # Slightly enhance contrast & color vibrancy for cinema wall look
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Color(img).enhance(1.10)

    # Apply rounded corners
    mask = create_rounded_mask((card_w, card_h), radius)
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    card.paste(img, (0, 0), mask)

    # Draw subtle inner glass border (1px white 22% alpha)
    border_layer = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(border_layer)
    bdraw.rounded_rectangle(
        (0, 0, card_w - 1, card_h - 1),
        radius=radius,
        outline=(255, 255, 255, 58),
        width=1,
    )
    card = Image.alpha_composite(card, border_layer)

    # Add soft drop shadow behind card
    pad = 12
    canvas = Image.new("RGBA", (card_w + pad * 2, card_h + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 180))
    canvas.paste(shadow, (pad + 2, pad + 4), mask)
    canvas = canvas.filter(ImageFilter.GaussianBlur(5))
    canvas.paste(card, (pad, pad), card)
    return canvas


def generate_marquee_strip(poster_paths, out_path, view_w=700, view_h=160):
    """
    Creates a horizontally seamless marquee strip of width (tile_w + view_w) and height view_h.
    When scrolled from x = 0 to x = tile_w - 1, frame(tile_w) == frame(0) seamlessly!
    """
    cards = [prepare_poster_card(p, card_w=96, card_h=142, radius=10) for p in poster_paths]
    num_posters = len(cards)  # 8 posters
    col_step = 112  # horizontal spacing per column
    tile_w = num_posters * col_step  # 8 * 112 = 896 px seamless period
    total_w = tile_w + view_w + 120  # extra buffer for safe copy

    # Create high-res base canvas in Deep Obsidian (#07070A)
    strip = Image.new("RGBA", (total_w, view_h), (7, 7, 10, 255))

    # Pre-rotate cards slightly (-9 degrees) for dynamic modern cinema wall feel
    rotated_cards_top = [
        c.rotate(9, resample=Image.Resampling.BICUBIC, expand=True) for c in cards
    ]
    rotated_cards_bottom = [
        c.rotate(9, resample=Image.Resampling.BICUBIC, expand=True)
        for c in cards[4:] + cards[:4]
    ]

    # Tile enough columns to cover [-col_step .. total_w + col_step] so edges match seamlessly
    total_cols = (total_w // col_step) + 4
    for col_idx in range(-2, total_cols):
        p_idx = col_idx % num_posters
        base_x = col_idx * col_step

        # Stagger vertical offset subtly per column for dynamic rhythm
        stagger_y = -6 if (col_idx % 2 == 0) else 4

        # Row 1 (upper/middle poster)
        c_top = rotated_cards_top[p_idx]
        x1 = base_x - 10
        y1 = -32 + stagger_y
        strip.alpha_composite(c_top, (x1, y1))

        # Row 2 (lower/offset poster)
        c_bot = rotated_cards_bottom[p_idx]
        x2 = base_x + 36
        y2 = 68 + stagger_y
        strip.alpha_composite(c_bot, (x2, y2))

    # Crop to exact (tile_w + view_w, view_h)
    final_w = tile_w + view_w
    strip = strip.crop((0, 0, final_w, view_h))

    # Apply cinematic lighting & Obsidian gradient overlay (100% horizontally invariant!)
    overlay = Image.new("RGBA", (final_w, view_h), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)

    for y in range(view_h):
        t = y / float(view_h - 1)
        # Top edge vignette (connects seamlessly to #07070A top bar)
        if t < 0.22:
            top_factor = 1.0 - (t / 0.22)
            alpha_top = int(235 * (top_factor ** 1.5))
        else:
            alpha_top = 0

        # Bottom gradient fade (connects seamlessly to #0E0E14 page body & makes text legible)
        if t > 0.28:
            bot_factor = (t - 0.28) / 0.72
            alpha_bot = int(120 + 135 * (bot_factor ** 1.3))
        else:
            alpha_bot = 120

        alpha = max(alpha_top, alpha_bot)
        # Base dark tint (#0E0E14)
        odraw.line([(0, y), (final_w, y)], fill=(14, 14, 20, min(255, alpha)))

    strip = Image.alpha_composite(strip, overlay)

    # Subtle bottom divider line with Cinema Amber (#FF9500) accent blended cleanly
    accent_overlay = Image.new("RGBA", (final_w, view_h), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(accent_overlay)
    adraw.line([(0, view_h - 2), (final_w, view_h - 2)], fill=(255, 149, 0, 95))
    adraw.line([(0, view_h - 1), (final_w, view_h - 1)], fill=(38, 38, 56, 255))
    strip = Image.alpha_composite(strip, accent_overlay)

    # Save as 24-bit BMP for fast native GDI BitBlt in Inno Setup
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    strip.convert("RGB").save(out_path, format="BMP")
    print(f"Generated {out_path} ({final_w}x{view_h}, tile_w={tile_w})")
    return tile_w


def generate_brand_logo(icon_path, out_path, size=30, bg_color=(7, 7, 10)):
    icon = Image.open(icon_path).convert("RGBA").resize(
        (size, size), Image.Resampling.LANCZOS
    )
    bg = Image.new("RGBA", (size, size), (*bg_color, 255))
    bg.alpha_composite(icon, (0, 0))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bg.convert("RGB").save(out_path, format="BMP")
    print(f"Generated {out_path} ({size}x{size})")


if __name__ == "__main__":
    posters = [
        "assets/images/spiderman_brand_new_day.webp",
        "assets/images/stranger_things.webp",
        "assets/images/house_of_the_dragon.webp",
        "assets/images/breaking_bad.webp",
        "assets/images/peaky_blinders.webp",
        "assets/images/squid_game.webp",
        "assets/images/game_of_thrones.webp",
        "assets/images/chernobyl.webp",
    ]
    generate_marquee_strip(
        posters,
        "windows/installer/marquee_strip.bmp",
        view_w=700,
        view_h=160,
    )
    generate_brand_logo(
        "assets/images/cineva_icon.png",
        "windows/installer/brand_logo.bmp",
        size=28,
        bg_color=(7, 7, 10),
    )
