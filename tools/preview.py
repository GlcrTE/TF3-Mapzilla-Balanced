"""Render _metadata/0.png (1920x1080): four layouts coloured by terrain band."""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(__file__)
MOD = os.path.join(HERE, "..", "mod", "glcrte_mapzilla_balanced_1")
TEX = os.path.join(MOD, "content", "mapzilla_balanced", "tex", "layouts.tga")
OUT = os.path.join(MOD, "_metadata", "0.png")

# tile index -> remap knots from LAYOUTS in nodes.script.lua
SHOWN = {0: (0.220, 0.643, 0.902), 2: (0.114, 0.529, 0.937), 3: (0.200, 0.682, 0.973),
         6: (0.086, 0.490, 0.827)}
COLOURS = [(118, 150, 80), (140, 178, 92), (170, 205, 115), (60, 120, 190)]
NAMES = ["Hills", "Rolling", "Flat", "Sea"]


def main():
    tex = Image.open(TEX)
    w, h = 1920, 1080
    img = Image.new("RGB", (w, h), (24, 28, 32))
    d = ImageDraw.Draw(img)
    lo, size, tw = 21, 214, 420
    gap = (w - len(SHOWN) * tw) // (len(SHOWN) + 1)
    for j, (t, k) in enumerate(SHOWN.items()):
        tile = tex.crop((t * 256 + lo, lo, t * 256 + lo + size, lo + size)).resize((tw, tw))
        bands = tile.point(lambda v: sum(v / 255 >= b for b in k[:2]) + (v / 255 > k[2]))
        rgb = Image.new("RGB", (tw, tw))
        bp, rp = bands.load(), rgb.load()
        for y in range(tw):
            for x in range(tw):
                rp[x, y] = COLOURS[bp[x, y]]
        img.paste(rgb, (gap + j * (tw + gap), 300))
    try:
        big, small = ImageFont.truetype("arialbd.ttf", 96), ImageFont.truetype("arial.ttf", 44)
    except OSError:
        big = small = ImageFont.load_default()
    d.text((w // 2, 150), "Mapzilla Balanced", font=big, fill=(240, 240, 240), anchor="mm")
    d.text((w // 2, 860), "No dead mountain strip - room for towns and industry", font=small,
           fill=(220, 220, 220), anchor="mm")
    widths = [55 + d.textlength(name, font=small) for name in NAMES]
    spacing = 70
    x = (w - sum(widths) - spacing * (len(NAMES) - 1)) // 2
    for name, c, width in zip(NAMES, COLOURS, widths):
        d.rectangle([x, 950, x + 40, 990], fill=c)
        d.text((x + 55, 970), name, font=small, fill=(220, 220, 220), anchor="lm")
        x += width + spacing
    img.save(OUT)


if __name__ == "__main__":
    main()
