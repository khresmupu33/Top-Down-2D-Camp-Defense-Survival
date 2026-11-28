#!/usr/bin/env python3
"""Membuat gambar PENGGANTI (ilustrasi, bukan foto asli) untuk 18 slot di assets/photos/.

Tujuannya hanya untuk mengetes jalur foto (PhotoKit) di Godot. Ganti file hasilnya dengan foto asli
bernama sama kapan saja. Jalankan dari folder proyek:

    pip install pillow
    python3 tools/make_placeholder_photos.py            # tulis ke assets/photos/
    python3 tools/make_placeholder_photos.py --force    # timpa file yang sudah ada

Tanpa --force, file yang sudah ada TIDAK ditimpa (foto asli kamu aman).
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets" / "photos"
SS = 2  # supersampling agar tepi halus


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def rr(d, box, r, fill, outline=None, width=0):
    d.rounded_rectangle([v * SS for v in box], r * SS, fill=fill, outline=outline, width=width * SS)


def ell(d, box, fill, outline=None, width=0):
    d.ellipse([v * SS for v in box], fill=fill, outline=outline, width=width * SS)


def poly(d, pts, fill):
    d.polygon([(x * SS, y * SS) for x, y in pts], fill=fill)


def glow(img, color, radius):
    """Cahaya lembut di belakang gambar."""
    a = img.split()[3].filter(ImageFilter.GaussianBlur(radius * SS))
    g = Image.new("RGBA", img.size, color)
    g.putalpha(a.point(lambda v: int(v * 0.6)))
    return Image.alpha_composite(g, img)


# ── entitas (256 px, kecuali dicatat) ────────────────────────────────

def player():
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    rr(d, (10, 10, 246, 246), 40, (20, 83, 45, 255))
    rr(d, (22, 22, 234, 234), 32, (34, 197, 94, 255))
    rr(d, (34, 34, 100, 100), 18, (134, 239, 172, 230))
    for ex in (58, 142):
        rr(d, (ex, 104, ex + 58, 176), 22, (240, 253, 244, 255))
        rr(d, (ex + 16, 126, ex + 42, 164), 12, (5, 46, 22, 255))
    rr(d, (92, 200, 164, 214), 7, (5, 46, 22, 200))
    return finish(glow(im, (34, 197, 94, 255), 8), n, n)


def target():
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    rr(d, (14, 14, 242, 242), 30, (209, 213, 219, 255))
    rr(d, (28, 28, 228, 228), 18, (255, 255, 255, 255))
    ell(d, (78, 78, 178, 178), None, (156, 163, 175, 255), 14)
    ell(d, (108, 108, 148, 148), (239, 68, 68, 255))
    return finish(glow(im, (255, 255, 255, 255), 6), n, n)


def orb(base, light, dark, glyph):
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    ell(d, (10, 10, 246, 246), base)
    for i in range(9):  # bayangan bola: lingkaran mengecil ke sorotan
        k = i / 9
        r = 112 * (1 - k)
        cx = 128 - 30 * k; cy = 128 - 38 * k
        t = k
        col = tuple(int(dark[j] + (light[j] - dark[j]) * t) for j in range(3)) + (255,)
        ell(d, (cx - r, cy - r, cx + r, cy + r), col)
    glyph(d)
    return finish(glow(im, base, 8), n, n)


def health():
    def g(d):
        rr(d, (108, 48, 148, 208), 10, (255, 255, 255, 255))
        rr(d, (48, 108, 208, 148), 10, (255, 255, 255, 255))
    return orb((187, 247, 208, 255), (134, 239, 172), (21, 128, 61), g)


def power():
    def g(d):
        poly(d, [(150, 36), (86, 138), (124, 138), (100, 220), (176, 112), (136, 112)], (74, 44, 0, 255))
    return orb((255, 247, 174, 255), (253, 230, 138), (202, 138, 4), g)


def timestop():
    def g(d):
        poly(d, [(84, 60), (172, 60), (136, 128), (172, 196), (84, 196), (120, 128)], (224, 242, 254, 255))
        poly(d, [(112, 170), (144, 170), (128, 192)], (251, 191, 36, 255))
        rr(d, (78, 50, 178, 62), 4, (186, 230, 253, 255))
        rr(d, (78, 194, 178, 206), 4, (186, 230, 253, 255))
    return orb((147, 197, 253, 255), (96, 165, 250), (30, 58, 138), g)


def gadfly(frozen=False):
    w, h = 256, 192  # 4:3, kepala menghadap atas
    im = canvas(w, h); d = ImageDraw.Draw(im)
    wing = (186, 230, 253, 190) if not frozen else (203, 213, 225, 170)
    body = (239, 68, 68, 255) if not frozen else (100, 116, 139, 255)
    dark = (185, 28, 28, 255) if not frozen else (71, 85, 105, 255)
    rr(d, (12, 36, 68, 156), 28, wing, (255, 255, 255, 140), 5)
    rr(d, (188, 36, 244, 156), 28, wing, (255, 255, 255, 140), 5)
    for x0, x1 in ((86, 80), (170, 176)):
        d.line([(x0 * SS, 40 * SS), (x1 * SS - (6 if x0 < 128 else -6) * SS, 2 * SS)], fill=(127, 29, 29, 255), width=12 * SS)
    rr(d, (48, 16, 208, 176), 24, body)
    rr(d, (58, 26, 198, 166), 18, dark)
    rr(d, (62, 30, 194, 150), 14, body)
    for ex in (80, 144):
        rr(d, (ex, 56, ex + 32, 88), 6, (17, 24, 39, 255))
        rr(d, (ex + 8, 64, ex + 16, 72), 2, (248, 250, 252, 255))
    rr(d, (88, 120, 168, 144), 6, (17, 24, 39, 255))
    poly(d, [(100, 120), (116, 120), (108, 136)], (248, 250, 252, 255))
    poly(d, [(140, 120), (156, 120), (148, 136)], (248, 250, 252, 255))
    col = (148, 163, 184, 255) if frozen else (239, 68, 68, 255)
    return finish(glow(im, col, 6), w, h)


def killer():
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    rr(d, (24, 34, 232, 230), 14, (33, 3, 7, 255))
    rr(d, (40, 48, 216, 216), 8, (92, 8, 20, 255))
    rr(d, (56, 58, 200, 150), 6, (60, 4, 12, 255))
    for ex in (66, 146):
        rr(d, (ex, 100, ex + 44, 128), 4, (255, 20, 20, 255))
        rr(d, (ex + 14, 100, ex + 30, 128), 2, (5, 0, 0, 255))
    poly(d, [(64, 160), (192, 160), (176, 206), (80, 206)], (2, 0, 0, 255))
    for i in range(4):
        x = 76 + i * 28
        poly(d, [(x, 160), (x + 20, 160), (x + 10, 182)], (248, 250, 252, 255))
    d.line([(80 * SS, 70 * SS), (110 * SS, 120 * SS)], fill=(220, 38, 38, 255), width=7 * SS)
    d.line([(176 * SS, 70 * SS), (150 * SS, 118 * SS)], fill=(220, 38, 38, 255), width=7 * SS)
    rr(d, (50, 192, 68, 224), 6, (220, 38, 38, 255))
    return finish(glow(im, (127, 0, 0, 255), 8), n, n)


def archer():  # menghadap kanan
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    ell(d, (32, 32, 224, 224), (126, 34, 206, 255), (253, 186, 116, 255), 16)
    ell(d, (84, 84, 172, 172), (167, 100, 240, 255))
    d.arc([(112 * SS), (72 * SS), (232 * SS), (184 * SS)], -69, 69, fill=(126, 34, 206, 255), width=16 * SS)
    rr(d, (150, 104, 190, 152), 10, (254, 226, 226, 255))
    return finish(glow(im, (249, 115, 22, 255), 8), n, n)


def arrow(lord=False):  # ujung ke kanan, 2:1
    w, h = 256, 128
    im = canvas(w, h); d = ImageDraw.Draw(im)
    main = (167, 139, 250, 255) if lord else (126, 34, 206, 255)
    poly(d, [(8, 20), (56, 20), (80, 64), (56, 108), (8, 108), (32, 64)], main[:3] + (220,))
    rr(d, (50, 54, 190, 74), 10, (126, 34, 206, 255))
    poly(d, [(186, 18), (248, 64), (186, 110)], main)
    return finish(glow(im, main, 5) if lord else im, w, h)


def vindex():
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    ell(d, (8, 8, 248, 248), (59, 7, 100, 255))
    for i in range(9):
        k = i / 9; r = 118 * (1 - k)
        cx = 128 - 36 * k; cy = 128 - 44 * k
        a, b = (126, 34, 206), (30, 3, 56)
        col = tuple(int(b[j] + (a[j] - b[j]) * k) for j in range(3)) + (255,)
        ell(d, (cx - r, cy - r, cx + r, cy + r), col)
    ell(d, (14, 14, 242, 242), None, (192, 132, 252, 110), 8)
    eye = (192, 132, 252, 255)
    poly(d, [(58, 82), (112, 98), (112, 124), (58, 112)], eye)
    poly(d, [(198, 82), (144, 98), (144, 124), (198, 112)], eye)
    rr(d, (76, 94, 94, 112), 2, (17, 24, 39, 255))
    rr(d, (162, 94, 180, 112), 2, (17, 24, 39, 255))
    rr(d, (70, 164, 186, 190), 6, (254, 243, 199, 255))
    for i in range(5):
        rr(d, (88 + i * 20, 164, 90 + i * 20, 190), 0, (216, 201, 142, 255))
    return finish(glow(im, (168, 85, 247, 255), 10), n, n)


def meteor(hard=False, big=False):
    n = 256
    im = canvas(n, n); d = ImageDraw.Draw(im)
    if hard:
        a, b = (126, 34, 206), (46, 16, 101)
    else:
        a, b = (180, 120, 80), (70, 40, 30)
    rnd = random.Random(7 if not big else 11)
    pts = []
    for i in range(18):
        ang = i / 18 * math.tau
        r = 116 * (0.86 + 0.14 * rnd.random())
        pts.append((128 + r * math.cos(ang), 128 + r * math.sin(ang)))
    poly(d, pts, b + (255,))
    for i in range(9):
        k = i / 9
        sc = 1 - k * 0.9
        poly(d, [(128 + (x - 128) * sc - 20 * k, 128 + (y - 128) * sc - 24 * k) for x, y in pts],
             tuple(int(b[j] + (a[j] - b[j]) * k) for j in range(3)) + (255,))
    if big:
        crater = (107, 63, 43, 255) if not hard else (60, 20, 110, 255)
        for cx, cy, r in ((82, 84, 28), (168, 104, 22), (112, 168, 32)):
            ell(d, (cx - r, cy - r, cx + r, cy + r), crater)
        glowc = (192, 132, 252, 255) if hard else (249, 115, 22, 255)
        d.line([(60 * SS, 150 * SS), (110 * SS, 126 * SS), (150 * SS, 176 * SS), (200 * SS, 150 * SS)], fill=glowc, width=6 * SS)
    else:
        ell(d, (112, 118, 140, 146), (254, 243, 199, 230))
    return finish(im, n, n)


# ── peta (1600x1200) ─────────────────────────────────────────────────

def map_arena():
    w, h = 1600, 1200
    rnd = random.Random(3)
    im = Image.new("RGB", (w, h), (30, 34, 30))
    d = ImageDraw.Draw(im)
    cell = 80
    for cy in range(0, h, cell):
        for cx in range(0, w, cell):
            v = 36 + ((cx // cell + cy // cell) % 2) * 8 + rnd.randint(-3, 3)
            d.rectangle([cx, cy, cx + cell, cy + cell], fill=(v, v + 6, v))
    for _ in range(9000):  # butiran seperti tanah/beton
        x, y = rnd.randrange(w), rnd.randrange(h)
        v = rnd.randint(18, 62)
        d.point((x, y), fill=(v, v + 4, v))
    for x in range(0, w + 1, cell):
        d.line([(x, 0), (x, h)], fill=(20, 24, 20), width=3)
    for y in range(0, h + 1, cell):
        d.line([(0, y), (w, y)], fill=(20, 24, 20), width=3)
    return im.filter(ImageFilter.GaussianBlur(0.8))


def radial(w, h, inner, outer, cx=0.5, cy=0.47):
    im = Image.new("RGB", (w, h))
    px = im.load()
    far = math.hypot(w, h) * 0.6
    for y in range(h):
        for x in range(w):
            t = min(1.0, math.hypot(x - w * cx, y - h * cy) / far)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return im


def stars(im, n, seed):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(im)
    for _ in range(n):
        x, y = rnd.randrange(im.width), rnd.randrange(im.height)
        v = rnd.randint(90, 200)
        d.ellipse([x, y, x + 2, y + 2], fill=(v, v - 20, 255))
    return im


# ── tabel berkas (sama dengan Config.PHOTOS.files) ────────────────────

def build():
    return {
        "map/arena.png": lambda: map_arena(),
        "map/hard-intro.png": lambda: stars(radial(800, 600, (88, 28, 135), (5, 3, 10)).resize((1600, 1200)), 220, 5),
        "map/ending.png": lambda: stars(radial(800, 600, (24, 24, 40), (3, 3, 5)).resize((1600, 1200)), 120, 9),
        "entities/player.png": player,
        "entities/target.png": target,
        "entities/health.png": health,
        "entities/power.png": power,
        "entities/timestop.png": timestop,
        "entities/gadfly.png": lambda: gadfly(False),
        "entities/gadfly-frozen.png": lambda: gadfly(True),
        "entities/killer.png": killer,
        "entities/archer.png": archer,
        "entities/arrow.png": lambda: arrow(False),
        "entities/arrow-lord.png": lambda: arrow(True),
        "entities/vindex.png": vindex,
        "entities/meteor-small.png": lambda: meteor(False, False),
        "entities/meteor-small-hard.png": lambda: meteor(True, False),
        "entities/meteor-big.png": lambda: meteor(False, True),
    }


def main():
    force = "--force" in sys.argv
    made = skipped = 0
    for rel, fn in build().items():
        path = OUT / rel
        if path.exists() and not force:
            skipped += 1
            print("lewati (sudah ada):", rel)
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        fn().save(path)
        made += 1
        print("dibuat:", rel)
    print(f"selesai: {made} dibuat, {skipped} dilewati -> {OUT}")


if __name__ == "__main__":
    main()
