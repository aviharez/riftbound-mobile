"""Recolour pixel art without touching its pixel grid: scale saturation and value, optionally shift hue.

Usage: python3 tools/art/recolor.py IN.png OUT.png --sat 0.35 --val 0.85 [--hue-to 222]
Used for the arena floor (art-spec §4: the arena stays low saturation, mid-dark value).
"""
import argparse, colorsys
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("dst")
ap.add_argument("--sat", type=float, default=1.0)
ap.add_argument("--val", type=float, default=1.0)
ap.add_argument("--hue-to", type=float, default=None, help="set every hue to this angle (degrees)")
a = ap.parse_args()
im = Image.open(a.src).convert("RGBA")
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, al = px[x, y]
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if a.hue_to is not None:
            h = (a.hue_to % 360) / 360
        s = min(1.0, s * a.sat); v = min(1.0, v * a.val)
        r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
        px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), al)
im.save(a.dst)
print("wrote", a.dst, im.size)
