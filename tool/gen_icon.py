"""Generate gang.roll launcher icons (coral bg + cream camera aperture).

Outputs legacy `ic_launcher.png` and adaptive-icon `ic_launcher_foreground.png`
at every density, plus a 512px Play Store icon. Supersampled 4x for clean AA.
"""
import math
import os
from PIL import Image, ImageDraw

CORAL = (255, 77, 58, 255)      # AppTheme.coral #FF4D3A
CREAM = (248, 246, 243, 255)    # AppTheme.cream #F8F6F3
SS = 4                          # supersample factor

RES = os.path.join(os.path.dirname(__file__), "..", "android", "app",
                   "src", "main", "res")

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324,
              "xxxhdpi": 432}


def draw_aperture(d, cx, cy, R, color, w, spin_deg=24, hex_frac=0.54):
    """Line-art camera aperture: rim circle + hexagon opening + 6 slanted blades."""
    r = R * hex_frac
    # Rim.
    d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=color, width=w)
    # Hexagon opening.
    hexpts = []
    for i in range(6):
        a = math.radians(60 * i + 30)
        hexpts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.line(hexpts + [hexpts[0]], fill=color, width=w, joint="curve")
    # Blades — each hexagon vertex to a rim point offset by the spin angle.
    for i in range(6):
        a = math.radians(60 * i + 30)
        a2 = math.radians(60 * i + 30 + spin_deg)
        v = (cx + r * math.cos(a), cy + r * math.sin(a))
        rp = (cx + R * math.cos(a2), cy + R * math.sin(a2))
        d.line([v, rp], fill=color, width=w)
    # Round the vertices for a polished join.
    for (x, y) in hexpts:
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=color)


def make(size, with_bg):
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if with_bg:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.18),
                            fill=CORAL)
        R, w = s * 0.30, max(2, int(s * 0.05))
    else:
        # Foreground for adaptive icon — keep inside the safe zone.
        R, w = s * 0.24, max(2, int(s * 0.042))
    draw_aperture(d, s / 2, s / 2, R, CREAM, w)
    return img.resize((size, size), Image.LANCZOS)


def save(img, density, name):
    folder = os.path.join(RES, f"mipmap-{density}")
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name))


for density, size in LEGACY.items():
    save(make(size, with_bg=True), density, "ic_launcher.png")
for density, size in FOREGROUND.items():
    save(make(size, with_bg=False), density, "ic_launcher_foreground.png")

# Play Store / source icon.
out = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")
os.makedirs(out, exist_ok=True)
make(512, with_bg=True).save(os.path.join(out, "ic_launcher_512.png"))
print("icons generated")
