"""Regenerate the pixel logo and README banner with Python 3 and Pillow.

Run from any directory: python3 path/to/assets/generate.py
All geometry uses integer coordinates; lettering is an original 5 x 7 grid.
"""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
BACKGROUND = "#101820"
MINT = "#A0F0CC"
AMBER = "#FFC879"
MUTED = "#92A3AA"

GLYPHS = {
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "10001", "11110", "10001", "10001", "11110"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "H": ("10001", "10001", "10001", "11111", "10001", "10001", "10001"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "10101", "01010"),
    " ": ("00000",) * 7,
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
}


def logo():
    """A 32 x 32 transparent master: app window + package-download arrow."""
    image = Image.new("RGBA", (32, 32))
    draw = ImageDraw.Draw(image)
    # Stepped window, balanced within an eight-pixel safe area.
    draw.rectangle((9, 8, 22, 9), fill=MINT)
    draw.rectangle((7, 10, 8, 22), fill=MINT)
    draw.rectangle((23, 10, 24, 22), fill=MINT)
    draw.rectangle((9, 23, 22, 24), fill=MINT)
    draw.rectangle((9, 13, 22, 13), fill=MINT)
    draw.point((10, 11), fill=MINT)
    draw.point((12, 11), fill=MINT)
    # The shaft and stepped head share one visual center.
    draw.rectangle((15, 15, 16, 19), fill=AMBER)
    draw.rectangle((12, 18, 13, 18), fill=AMBER)
    draw.rectangle((18, 18, 19, 18), fill=AMBER)
    draw.rectangle((13, 19, 18, 19), fill=AMBER)
    draw.rectangle((14, 20, 17, 20), fill=AMBER)
    draw.rectangle((15, 21, 16, 21), fill=AMBER)
    return image


def text(draw, value, center_x, y, scale, color):
    width = (len(value) * 6 - 1) * scale
    x = center_x - width // 2
    for char in value:
        for row, pixels in enumerate(GLYPHS[char]):
            for col, pixel in enumerate(pixels):
                if pixel == "1":
                    left = x + col * scale
                    top = y + row * scale
                    draw.rectangle(
                        (left, top, left + scale - 1, top + scale - 1),
                        fill=color,
                    )
        x += 6 * scale


def main():
    mark = logo()
    mark.resize((512, 512), Image.Resampling.NEAREST).save(ROOT / "logo.png")

    banner = Image.new("RGB", (1280, 480), BACKGROUND)
    icon = mark.resize((256, 256), Image.Resampling.NEAREST)
    banner.paste(icon, (512, 8), icon)
    draw = ImageDraw.Draw(banner)
    text(draw, "HOMEBREW-APPS", 640, 294, 8, MINT)
    text(draw, "A HOMEBREW TAP", 640, 388, 3, MUTED)
    banner.save(ROOT / "banner.png", optimize=True)


if __name__ == "__main__":
    main()
