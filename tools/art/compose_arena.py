"""Assemble the battle arena backdrop with exact gameplay geometry (art-spec "Arena").

Sources (PixelLab, see assets/art/CREDITS.md) live in assets/art/arena/src/. Geometry comes from CombatBalance:
walls at x 30 / 240, ceiling y 38, rune line / stage top y 455. The canvas covers world x -120..390, y -260..564:
enough for every phone and 4:3 tablet at the integer scale GameState picks (the screen is always filled).
Boundaries are straight stone curbs drawn here, so the art never suggests a different bounce line.

Usage: python3 tools/art/compose_arena.py  ->  assets/art/arena/rift_arena.png (+ prints torch points)
"""
import colorsys
import numpy as np
from PIL import Image

ROOT = "assets/art/arena/"
WALL_L, WALL_R, CEIL, RUNE = 30, 240, 38, 455
OX, OY = -120, -260           # canvas origin in world units
W, H = 510, 824               # world x -120..390, y -260..564

def load(p):
    return np.asarray(Image.open(ROOT + "src/" + p).convert("RGBA")).astype(np.float64)

def to_canvas(x, y):
    return x - OX, y - OY

def paste(dst, src, x, y):
    cx, cy = to_canvas(x, y)
    h, w = src.shape[:2]
    a = src[..., 3:4] / 255.0
    region = dst[cy:cy + h, cx:cx + w]
    region[..., :3] = region[..., :3] * (1 - a) + src[..., :3] * a
    region[..., 3] = np.maximum(region[..., 3], src[..., 3])

def recolor_greys(img, hue_deg, sat=0.2, val=1.0, max_s=0.3):
    """Shift only low-saturation pixels (stone) to a hue; torches, ivy, crystals keep their colours."""
    out = img.copy()
    for y in range(img.shape[0]):
        for x in range(img.shape[1]):
            r, g, b, a = img[y, x]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s <= max_s:
                r2, g2, b2 = colorsys.hsv_to_rgb(hue_deg / 360, max(s, sat), min(1.0, v * val))
                out[y, x, :3] = (r2 * 255, g2 * 255, b2 * 255)
    return out

def shade(dst, x0, y0, x1, y1, k):
    cx0, cy0 = to_canvas(x0, y0)
    cx1, cy1 = to_canvas(x1, y1)
    dst[cy0:cy1, cx0:cx1, :3] *= k

def rect(dst, x0, y0, x1, y1, rgb):
    cx0, cy0 = to_canvas(x0, y0)
    cx1, cy1 = to_canvas(x1, y1)
    dst[cy0:cy1, cx0:cx1, :3] = rgb
    dst[cy0:cy1, cx0:cx1, 3] = 255

canvas = np.zeros((H, W, 4))
canvas[..., :3] = (14, 14, 24)
canvas[..., 3] = 255

# ---------------------------------------------------------------- walls
strip = load("wall_strip.png")                       # 48 x 512, pillar side faces right
strip[120:200, 18:30] = strip[30:110, 18:30]         # remove the half-visible banner
strip = recolor_greys(strip, 222, sat=0.16, val=0.85)
# extend to 680 rows: repeat the plain-brick upper band (seam-matched)
best = min(range(0, 240 - 168), key=lambda r: np.abs(strip[r:r + 3, :, :3] - strip[r + 168:r + 171, :, :3]).mean())
tall = np.concatenate([strip[:best + 168], strip[best:best + 168], strip[best + 168:]], axis=0)
left = np.concatenate([tall[:, ::-1][:, :27], tall], axis=1)[:, -75:]     # 75 wide: world -45..30
right = np.roll(left[:, ::-1], -250, axis=0)                              # mirrored; torches land mid-arena
# Taller screens: more of the seam-matched brick band above y -116.
extra = OY - (-116)
band = strip[best:best + 168]
top = np.concatenate([band] * (1 + (-extra) // 168), axis=0)[extra:]
top = np.concatenate([top[:, ::-1][:, :27], top], axis=1)[:, -75:]
left = np.concatenate([top, left], axis=0)
right = np.concatenate([top[:, ::-1], right], axis=0)
# Wider screens: plain brick (no torches or banners to repeat) outside the wall bands, darker so it recedes.
plain = np.concatenate([band] * (H // 168 + 1), axis=0)[:H]
plain = np.concatenate([plain[:, ::-1][:, :27], plain], axis=1)[:, -75:]
outer_l = plain.copy(); outer_l[..., :3] *= 0.55
outer_r = plain[:, ::-1].copy(); outer_r[..., :3] *= 0.55
paste(canvas, outer_l, -120, OY)
paste(canvas, outer_r, 315, OY)
paste(canvas, left, -45, OY)
paste(canvas, right, 240, OY)
# top wall behind the HUD: plain bricks tiled across
brick = strip[10:10 + 48, :48]
for x in range(30, 240, 48):
    for y in range(CEIL - 48 * ((CEIL - OY) // 48 + 1), CEIL, 48):
        part = brick[max(0, OY - y): min(48, CEIL - y), : min(48, 240 - x)]
        paste(canvas, part, x, max(y, OY))

# ---------------------------------------------------------------- floor
# The source has a compass decal mid-floor (owner: no magic circles). Rebuild it from its own stone rows:
# rows run between full-width mortar lines, so whole rows can be dropped and reordered without seams.
# The three rows holding the decal are replaced by other rows, mirrored so repeats don't read as copies.
src = load("floor.png")
MORTAR = [30, 64, 97, 131, 164, 199, 236, 271, 307, 341, 376, 410, 445, 480]
def row(i, flip=False):
    r = src[MORTAR[i]:MORTAR[i + 1]]
    return r[:, ::-1] if flip else r
rows = [row(0), row(1), row(2), row(3), row(4), row(10, True), row(2, True), row(4, True),
        row(8), row(9), row(10), row(11), row(12)]
floor = np.concatenate(rows, axis=0)
assert floor.shape[0] >= RUNE - CEIL, floor.shape
src_w0 = (src.shape[1] - (WALL_R - WALL_L)) // 2
floor = floor[: RUNE - CEIL, src_w0: src_w0 + (WALL_R - WALL_L)].copy()
floor[..., :3] *= 0.8          # mid-dark, so bright projectiles carry the colour (art-spec §4)
paste(canvas, floor, WALL_L, CEIL)

# ---------------------------------------------------------------- stage (fills the move zone)
# Dark slate flagstones (a built dais, unlike the cobbled floor), mirror-tiled so every edge matches.
slate = recolor_greys(load("stage_slate.png"), 225, sat=0.12, val=0.78, max_s=1.0)
dais = np.tile(slate, (1, 2, 1))[: 564 - RUNE, : WALL_R - WALL_L].copy()
# Raised edge without drawn lines: the platform's top rows catch the light, the floor in front darkens.
for i, k in enumerate((1.45, 1.3, 1.15, 1.06)):
    dais[i, :, :3] *= k
paste(canvas, dais, WALL_L, RUNE)
for i, k in enumerate((0.55, 0.7, 0.82, 0.92)):
    shade(canvas, WALL_L, RUNE - 1 - i, WALL_R, RUNE - i, k)
# ---------------------------------------------------------------- curbs and shadows (exact boundaries)
curb_hi, curb, curb_dk = (120, 130, 156), (70, 76, 98), (24, 24, 36)
for x, cols in ((WALL_L - 3, (curb_dk, curb, curb_hi)), (WALL_R, (curb_hi, curb, curb_dk))):
    for i, c in enumerate(cols):
        rect(canvas, x + i, CEIL - 3, x + i + 1, 564, c)
for i, c in enumerate((curb_dk, curb, curb_hi)):
    rect(canvas, WALL_L - 3, CEIL - 3 + i, WALL_R + 3, CEIL - 2 + i, c)
for i, k in enumerate((0.55, 0.7, 0.82, 0.92)):
    shade(canvas, WALL_L + i, CEIL, WALL_L + i + 1, RUNE - 1, k)
    shade(canvas, WALL_R - 1 - i, CEIL, WALL_R - i, RUNE - 1, k)
    shade(canvas, WALL_L, CEIL + i, WALL_R, CEIL + i + 1, k)

out = np.clip(canvas, 0, 255).astype(np.uint8)
Image.fromarray(out).save(ROOT + "rift_arena.png")
print("arena", out.shape)

# torches: warm bright clusters on the walls (world coordinates)
warm = (out[..., 0] > 200) & (out[..., 1] > 100) & (out[..., 2] < 110) & (out[..., 0] > out[..., 2] + 90)
ys, xs = np.nonzero(warm)
clusters = []
for x, y in zip(xs, ys):
    for c in clusters:
        if abs(c[0] / c[2] - x) < 6 and abs(c[1] / c[2] - y) < 6:
            c[0] += x; c[1] += y; c[2] += 1; break
    else:
        clusters.append([x, y, 1])
for c in clusters:
    wx, wy = round(c[0] / c[2]) + OX, round(c[1] / c[2]) + OY
    if c[2] >= 14 and (wx < WALL_L or wx > WALL_R):
        print("torch", wx, wy, c[2])
