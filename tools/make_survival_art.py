"""Survival extras: HD mobs, friendly NPCs, airdrop crate, buildable machines, item icons.
Run: python tools/make_survival_art.py [preview.png]

Original pixel art drawn from shapes, auto-outlined, 2-frame strips like tools/make_mobs.py.
  mobs / NPCs  24x24 per frame -> assets/survival/<name>.png  (redrawn old mobs: <name>_hd.png,
               the 16px originals stay because the coding-quest art crops them)
  machines     32x32 (16x16 for wall / spikes) per frame -> assets/survival/build_<id>.png
  items        16x16 single icon -> assets/survival/item_<id>.png
"""
import os, sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'survival')
K = (24, 20, 30, 255)


def outline(im):
    w, h = im.size
    src = im.copy(); px = src.load(); out = im.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 60
                                         for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[x, y] = K
    return im


def strip(fn, size, frames=2):
    s = Image.new('RGBA', (size * frames, size), (0, 0, 0, 0))
    for f in range(frames):
        im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        fn(ImageDraw.Draw(im), f)
        s.alpha_composite(outline(im), (f * size, 0))
    return s


ART = {}       # name -> (fn, size, frames)


def art(name, size=24, frames=2):
    def deco(fn):
        ART[name] = (fn, size, frames); return fn
    return deco


def eye2(d, x, y, c=(255, 255, 255), pupil=K):
    d.point((x, y), fill=c); d.point((x + 1, y), fill=pupil)


# ===================================================================== redrawn mobs (HD)
@art('bat_hd')
def _(d, f):
    body, dark, light = (104, 70, 146), (62, 40, 96), (146, 112, 190)
    if f == 0:
        d.polygon([(10, 11), (5, 3), (2, 4), (0, 10), (2, 9), (4, 12), (6, 11), (8, 14)], fill=dark)
        d.polygon([(13, 11), (18, 3), (21, 4), (23, 10), (21, 9), (19, 12), (17, 11), (15, 14)], fill=dark)
        d.line((10, 11, 5, 3), fill=body); d.line((13, 11, 18, 3), fill=body)
    else:
        d.polygon([(10, 11), (4, 12), (0, 17), (3, 16), (4, 19), (7, 16), (9, 17)], fill=dark)
        d.polygon([(13, 11), (19, 12), (23, 17), (20, 16), (19, 19), (16, 16), (14, 17)], fill=dark)
        d.line((10, 11, 1, 16), fill=body); d.line((13, 11, 22, 16), fill=body)
    d.polygon([(9, 9), (9, 4), (11, 8)], fill=body); d.polygon([(14, 9), (14, 4), (12, 8)], fill=body)
    d.ellipse((8, 7, 15, 17), fill=body)
    d.ellipse((9, 8, 11, 10), fill=light)
    d.ellipse((10, 13, 13, 16), fill=(132, 96, 168))
    d.point([(10, 11), (13, 11)], fill=(255, 70, 80)); d.point([(10, 10), (13, 10)], fill=(255, 180, 180))
    d.point([(11, 14), (12, 14)], fill=(250, 250, 250))
    d.point([(10, 18), (13, 18)], fill=dark)


@art('spider_hd')
def _(d, f):
    body, dark, light = (64, 48, 70), (40, 30, 46), (104, 84, 112)
    for i in range(4):
        o = (i + f) % 2
        ky = 8 + i * 3 - o
        d.line((9, 13 + i // 2, 4, ky), fill=dark); d.line((4, ky, 1, ky + 5 + o), fill=dark)
        d.line((14, 13 + i // 2, 19, ky), fill=dark); d.line((19, ky, 22, ky + 5 + o), fill=dark)
    d.ellipse((6, 10, 17, 20), fill=body)                       # abdomen
    d.ellipse((7, 11, 11, 14), fill=light)
    d.polygon([(11, 14), (13, 14), (12, 16)], fill=(220, 50, 60)); d.polygon([(11, 18), (13, 18), (12, 16)], fill=(220, 50, 60))
    d.ellipse((8, 5, 15, 11), fill=(82, 64, 90))                 # head
    d.point([(9, 8), (14, 8), (10, 7), (13, 7)], fill=(255, 60, 60)); d.point([(11, 8), (12, 8)], fill=(255, 140, 120))
    d.line((10, 11, 9, 13), fill=(200, 190, 180)); d.line((13, 11, 14, 13), fill=(200, 190, 180))   # fangs


@art('ghost_hd')
def _(d, f):
    sheet, shade, glow = (234, 240, 252, 230), (176, 190, 226, 230), (255, 255, 255, 245)
    d.ellipse((4, 1, 19, 16), fill=sheet); d.rectangle((4, 9, 19, 19), fill=sheet)
    d.rectangle((14, 6, 19, 19), fill=shade); d.ellipse((14, 1, 19, 12), fill=shade)
    for i, x in enumerate(range(4, 20, 4)):
        up = (i + f) % 2
        d.polygon([(x, 19), (x + 2, 22 - up * 2), (x + 4, 19)], fill=sheet if x < 14 else shade)
    d.ellipse((6, 3, 9, 6), fill=glow)
    d.ellipse((7, 7, 10, 11), fill=(28, 26, 50)); d.ellipse((13, 7, 16, 11), fill=(28, 26, 50))
    d.point([(8, 8), (14, 8)], fill=(120, 200, 255))
    d.ellipse((10, 12 + f, 13, 15), fill=(52, 48, 80))
    d.line((2, 12 + f, 4, 10), fill=sheet); d.line((21, 12 - f, 19, 10), fill=shade)   # little arms


@art('bomber_hd')
def _(d, f):
    b, dark, light = (52, 56, 80), (32, 34, 52), (110, 116, 150)
    lx = f
    d.rectangle((7 + lx, 19, 9 + lx, 22), fill=(230, 130, 40)); d.rectangle((14 - lx, 19, 16 - lx, 22), fill=(230, 130, 40))
    d.ellipse((3, 5, 20, 21), fill=b)
    d.ellipse((5, 7, 11, 12), fill=light); d.ellipse((6, 8, 8, 9), fill=(190, 196, 220))
    d.chord((3, 5, 20, 21), 20, 160, fill=dark)
    d.rectangle((10, 3, 13, 5), fill=(120, 124, 150))              # cap
    d.line((12, 3, 14, 1), fill=(150, 100, 50)); d.line((14, 1, 16, 1), fill=(150, 100, 50))
    sp = [(17, 0), (16, 0), (17, 1)] if f == 0 else [(17, 1), (18, 0), (16, 2), (18, 2)]
    d.point(sp, fill=(255, 220, 70)); d.point((17, 1 - f), fill=(255, 255, 220))
    d.line((7, 11, 10, 12), fill=(250, 250, 250)); d.line((16, 11, 13, 12), fill=(250, 250, 250))   # angry brows
    d.point([(9, 13), (14, 13)], fill=(255, 80, 60))
    d.line((9, 16, 14, 16), fill=(20, 16, 26))


@art('mage_hd')
def _(d, f):
    robe, dark, light, trim = (108, 64, 184), (72, 40, 132), (146, 104, 220), (234, 196, 80)
    sway = f
    d.polygon([(11, 9), (17 + sway, 22), (5 - sway, 22)], fill=robe)
    d.polygon([(11, 9), (17 + sway, 22), (13, 22)], fill=dark)
    d.line((5 - sway, 22, 17 + sway, 22), fill=trim)
    d.line((11, 12, 11, 21), fill=trim)
    d.rectangle((8, 7, 14, 11), fill=(236, 190, 156)); d.rectangle((8, 10, 14, 11), fill=(210, 160, 130))
    d.point([(9, 9), (13, 9)], fill=(60, 220, 255))
    d.polygon([(11, 0), (16, 7), (6, 7)], fill=dark); d.line((5, 7, 17, 7), fill=robe)
    d.point((11, 3), fill=trim); d.point([(10, 4), (12, 4)], fill=(255, 230, 140))
    d.polygon([(8, 11), (14, 11), (11, 15)], fill=(220, 220, 230))  # beard
    d.line((19, 6, 19, 22), fill=(140, 92, 50)); d.line((20, 7, 20, 22), fill=(100, 64, 34))
    g = 2 + f
    d.ellipse((19 - g, 4 - g, 20 + g, 5 + g), fill=(110, 230, 250, 150))
    d.ellipse((18, 3, 21, 6), fill=(140, 240, 255)); d.point((19, 4), fill=(255, 255, 255))
    d.line((15, 13, 18, 12), fill=robe)                              # arm to staff


@art('golem_hd')
def _(d, f):
    rock, dark, light, moss = (140, 140, 152), (98, 98, 112), (184, 184, 194), (92, 150, 70)
    a = f
    d.rectangle((6, 18, 10, 22), fill=dark); d.rectangle((13, 18, 17, 22), fill=dark)
    d.rectangle((5, 7, 18, 19), fill=rock); d.rectangle((5, 7, 18, 9), fill=light)
    d.rectangle((15, 9, 18, 19), fill=dark)
    d.rectangle((8, 1, 15, 7), fill=rock); d.line((8, 1, 15, 1), fill=light)
    d.rectangle((9, 3, 10, 4), fill=(255, 220, 80)); d.rectangle((13, 3, 14, 4), fill=(255, 220, 80))
    d.rectangle((1, 8 + a, 4, 17 + a), fill=rock); d.rectangle((0, 15 + a, 4, 19 + a), fill=dark)   # fists
    d.rectangle((19, 8 - a, 22, 17 - a), fill=rock); d.rectangle((19, 15 - a, 23, 19 - a), fill=dark)
    d.line((8, 10, 11, 14), fill=(255, 200, 70)); d.line((11, 14, 10, 17), fill=(255, 170, 50))   # glowing crack
    d.point([(6, 7), (7, 7), (16, 7), (9, 1), (10, 1)], fill=moss); d.point([(5, 8), (17, 8)], fill=moss)


@art('wolf_hd')
def _(d, f):
    fur, dark, light, belly = (132, 134, 146), (86, 88, 100), (176, 178, 188), (196, 196, 204)
    d.ellipse((3, 9, 16, 17), fill=fur); d.chord((3, 9, 16, 17), 0, 180, fill=dark)
    d.ellipse((5, 13, 14, 17), fill=belly)
    d.polygon([(4, 11), (0, 7 + f), (1, 10 + f), (3, 13)], fill=fur)                       # tail
    leg = [(5, 6), (8, 9), (12, 13), (14, 15)]
    for i, (x0, x1) in enumerate(leg):
        o = 1 if (i + f) % 2 else -1
        d.line((x0, 16, x0 + o, 21), fill=dark); d.point((x0 + o + 1, 21), fill=dark)
    d.ellipse((13, 5, 21, 12), fill=fur); d.rectangle((19, 8, 23, 11), fill=fur)            # head + snout
    d.line((19, 11, 23, 11), fill=light); d.point((23, 8), fill=K)
    d.polygon([(14, 6), (15, 1), (17, 5)], fill=dark); d.polygon([(17, 5), (18, 1), (19, 6)], fill=fur)
    d.point((18, 7), fill=(255, 210, 60)); d.point((19, 7), fill=K)
    d.point([(20, 12), (22, 12)], fill=(240, 240, 240))
    d.line((14, 9, 13, 12), fill=light)


# ===================================================================== new mobs
@art('raider')
def _(d, f):
    skin, skin_d = (226, 170, 124), (186, 130, 92)
    vest, vest_d, band = (128, 82, 50), (92, 56, 34), (200, 50, 50)
    lx = f
    d.rectangle((8 + lx, 17, 10 + lx, 22), fill=(70, 62, 80)); d.rectangle((13 - lx, 17, 15 - lx, 22), fill=(70, 62, 80))
    d.rectangle((7 + lx, 21, 10 + lx, 22), fill=(60, 40, 30)); d.rectangle((13 - lx, 21, 16 - lx, 22), fill=(60, 40, 30))
    d.rectangle((7, 9, 16, 17), fill=skin); d.rectangle((7, 9, 11, 17), fill=vest); d.rectangle((14, 9, 16, 17), fill=vest_d)
    d.rectangle((7, 15, 16, 16), fill=(70, 50, 36)); d.point((12, 15), fill=(230, 200, 90))       # belt
    d.rectangle((8, 2, 15, 9), fill=skin); d.rectangle((8, 8, 15, 9), fill=skin_d)
    d.rectangle((8, 2, 15, 3), fill=band); d.point([(7, 3), (6, 4), (7, 5)], fill=band)           # bandana tails
    d.point([(11, 5), (14, 5)], fill=K); d.line((10, 4, 11, 4), fill=(90, 50, 30)); d.line((13, 4, 14, 4), fill=(90, 50, 30))
    d.line((10, 7, 14, 7), fill=(120, 60, 40)); d.rectangle((9, 8, 14, 9), fill=(110, 70, 40))     # beard
    d.rectangle((4, 10, 6, 15), fill=skin)                                                         # back arm
    if f == 0:   # axe raised
        d.rectangle((16, 8, 18, 11), fill=skin); d.line((18, 9, 21, 2), fill=(120, 80, 44))
        d.polygon([(19, 1), (23, 0), (23, 5), (21, 4)], fill=(200, 206, 216)); d.line((23, 0, 23, 5), fill=(250, 250, 255))
    else:        # axe swung down
        d.rectangle((16, 11, 19, 13), fill=skin); d.line((19, 12, 23, 17), fill=(120, 80, 44))
        d.polygon([(21, 17), (23, 14), (23, 21), (20, 20)], fill=(200, 206, 216)); d.line((23, 15, 23, 21), fill=(250, 250, 255))


@art('goblin')
def _(d, f):
    g, gd, gl = (110, 186, 80), (74, 136, 52), (156, 216, 120)
    lx = f
    d.ellipse((1, 8, 10, 18), fill=(150, 118, 74)); d.ellipse((2, 9, 6, 12), fill=(180, 148, 100))   # loot sack
    d.line((3, 8, 6, 6), fill=(110, 80, 50)); d.point([(4, 14), (7, 15), (5, 16)], fill=(255, 210, 60))
    d.rectangle((10 + lx, 18, 11 + lx, 22), fill=gd); d.rectangle((14 - lx, 18, 15 - lx, 22), fill=gd)
    d.rectangle((9, 12, 16, 18), fill=(120, 76, 50)); d.rectangle((9, 17, 16, 18), fill=(90, 56, 36))
    d.ellipse((8, 4, 18, 13), fill=g); d.chord((8, 4, 18, 13), 20, 160, fill=gd)
    d.polygon([(8, 7), (3, 4), (8, 10)], fill=g); d.polygon([(18, 7), (23, 4), (18, 10)], fill=g)   # big ears
    d.point([(5, 5), (21, 5)], fill=gl)
    d.rectangle((11, 7, 12, 8), fill=(255, 240, 120)); d.rectangle((15, 7, 16, 8), fill=(255, 240, 120))
    d.point([(12, 8), (16, 8)], fill=K)
    d.line((11, 11, 16, 11), fill=(60, 30, 30)); d.point([(12, 11), (15, 11)], fill=(250, 250, 240))   # grin
    d.point((14, 9), fill=gd)
    d.line((16, 14, 19, 13 - f), fill=g); d.ellipse((18, 11 - f, 21, 14 - f), fill=(255, 206, 50))   # coin in hand


@art('coin_golem')
def _(d, f):
    gold, dark, light, gem = (226, 176, 56), (166, 116, 30), (255, 230, 130), (80, 220, 200)
    a = f
    d.rectangle((6, 18, 10, 22), fill=dark); d.rectangle((13, 18, 17, 22), fill=dark)
    d.ellipse((4, 6, 19, 20), fill=gold); d.chord((4, 6, 19, 20), 300, 120, fill=dark)
    d.ellipse((6, 8, 10, 11), fill=light)
    for (x, y) in ((8, 14), (13, 10), (15, 15), (10, 17)):
        d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=light); d.point((x, y), fill=dark)
    d.rectangle((10, 12, 13, 13), fill=K)                              # coin slot
    d.rectangle((8, 0, 15, 6), fill=gold); d.line((8, 0, 15, 0), fill=light)
    d.rectangle((9, 2, 10, 3), fill=gem); d.rectangle((13, 2, 14, 3), fill=gem)
    d.rectangle((0, 8 + a, 3, 16 + a), fill=gold); d.ellipse((0, 14 + a, 4, 19 + a), fill=dark)
    d.rectangle((20, 8 - a, 23, 16 - a), fill=gold); d.ellipse((19, 14 - a, 23, 19 - a), fill=dark)
    if f:
        d.point([(2, 4), (21, 3), (19, 21)], fill=(255, 255, 220))   # sparkle


@art('brute')
def _(d, f):
    skin, dark, light = (128, 146, 176), (92, 106, 138), (166, 182, 206)
    lx = f
    d.rectangle((6 + lx, 18, 10 + lx, 22), fill=dark); d.rectangle((13 - lx, 18, 17 - lx, 22), fill=dark)
    d.ellipse((3, 6, 20, 21), fill=skin); d.ellipse((5, 12, 17, 21), fill=light)            # belly
    d.rectangle((4, 16, 19, 18), fill=(120, 80, 46)); d.rectangle((10, 16, 13, 18), fill=(200, 170, 80))
    d.ellipse((7, 0, 16, 9), fill=skin); d.chord((7, 0, 16, 9), 0, 180, fill=dark)
    d.point([(10, 4), (14, 4)], fill=(255, 90, 60)); d.line((9, 3, 11, 3), fill=dark); d.line((13, 3, 15, 3), fill=dark)
    d.point([(10, 7), (14, 7)], fill=(240, 236, 220)); d.point([(10, 6), (14, 6)], fill=(240, 236, 220))   # tusks
    d.rectangle((0, 8, 3, 16), fill=skin)
    if f == 0:
        d.line((20, 9, 22, 1), fill=(120, 80, 44), width=2); d.ellipse((19, 0, 23, 5), fill=(140, 96, 54))
        d.point([(20, 1), (22, 3)], fill=(90, 90, 100))
    else:
        d.line((20, 12, 23, 18), fill=(120, 80, 44), width=2); d.ellipse((19, 16, 23, 22), fill=(140, 96, 54))
    d.rectangle((18, 9, 21, 13), fill=skin)


@art('sapper')
def _(d, f):
    suit, dark, skin = (226, 126, 50), (176, 88, 30), (236, 196, 150)
    lx = f
    d.rectangle((9 + lx, 18, 11 + lx, 22), fill=(70, 60, 70)); d.rectangle((13 - lx, 18, 15 - lx, 22), fill=(70, 60, 70))
    d.rectangle((8, 11, 16, 18), fill=suit); d.rectangle((13, 11, 16, 18), fill=dark)
    d.line((8, 14, 16, 14), fill=(250, 220, 80))                       # hi-vis stripe
    d.rectangle((9, 5, 15, 11), fill=skin); d.point([(11, 8), (14, 8)], fill=K); d.line((11, 10, 14, 10), fill=(150, 80, 60))
    d.chord((8, 1, 16, 9), 180, 360, fill=(250, 200, 50)); d.line((8, 5, 16, 5), fill=(200, 150, 30))   # helmet
    d.ellipse((11, 2, 13, 4), fill=(255, 255, 200))                    # lamp
    # dynamite bundle carried over the head
    d.rectangle((5, 0 + f, 7, 6 + f), fill=(210, 50, 50)); d.rectangle((17, 0 + f, 19, 6 + f), fill=(210, 50, 50))
    d.line((5, 1 + f, 5, 6 + f), fill=(240, 100, 100)); d.line((17, 1 + f, 17, 6 + f), fill=(240, 100, 100))
    d.line((7, 6, 9, 12), fill=suit); d.line((17, 6, 15, 12), fill=dark)
    d.line((19, 0 + f, 21, 0), fill=(150, 100, 50)); d.point((22, 0 + f), fill=(255, 220, 60))


@art('shaman')
def _(d, f):
    robe, dark, light, gem = (60, 140, 110), (38, 96, 76), (100, 186, 150), (120, 255, 160)
    b = f
    d.polygon([(11, 6), (18, 19 + b), (4, 19 + b)], fill=robe)
    d.polygon([(11, 6), (18, 19 + b), (13, 19 + b)], fill=dark)
    for x in range(5, 18, 3):
        d.point((x, 20 + b), fill=robe)
    d.ellipse((7, 2, 15, 10), fill=dark)                               # hood
    d.rectangle((9, 5, 13, 9), fill=(230, 214, 170))                   # bone mask
    d.point([(10, 6), (12, 6)], fill=gem); d.line((10, 8, 12, 8), fill=(120, 100, 80))
    d.polygon([(11, 0), (13, 3), (9, 3)], fill=(220, 60, 60))          # feather
    d.line((18, 4, 18, 18), fill=(120, 84, 50))
    g = 1 + f
    d.ellipse((18 - g - 1, 1 - g, 19 + g, 4 + g), fill=(120, 255, 160, 130))
    d.polygon([(18, 0), (20, 2), (18, 5), (16, 2)], fill=gem); d.point((18, 2), fill=(240, 255, 240))
    d.line((14, 10, 17, 9), fill=robe)
    d.point([(3, 8 - f), (6, 4 + f), (20, 12 - f)], fill=gem)         # floating sparks


@art('boar')
def _(d, f):
    hide, dark, light = (126, 86, 64), (88, 58, 42), (164, 122, 92)
    cloak = (70, 120, 70)
    for i, x in enumerate((5, 8, 14, 17)):
        o = 1 if (i + f) % 2 else -1
        d.line((x, 17, x + o, 22), fill=dark)
    d.ellipse((2, 9, 19, 19), fill=hide); d.chord((2, 9, 19, 19), 0, 180, fill=dark)
    for x in range(4, 16, 2):
        d.point((x, 9), fill=(60, 40, 30))                             # bristles
    d.ellipse((15, 9, 23, 17), fill=hide); d.rectangle((20, 12, 23, 15), fill=light)
    d.point((22, 13), fill=K); d.point((18, 11), fill=(255, 80, 40))
    d.line((20, 15, 22, 12), fill=(250, 246, 230)); d.point((21, 16), fill=(250, 246, 230))   # tusk
    d.polygon([(16, 10), (17, 7), (18, 10)], fill=dark)
    d.line((2, 12, 0, 10 + f), fill=dark)
    # rider
    d.rectangle((7, 3, 12, 10), fill=cloak); d.rectangle((10, 3, 12, 10), fill=(50, 90, 52))
    d.rectangle((8, 0, 11, 4), fill=(226, 180, 140)); d.point((10, 2), fill=K)
    d.chord((7, -2, 12, 4), 180, 360, fill=(90, 70, 60))
    d.line((12, 5, 15, 1 + f), fill=(120, 80, 44)); d.rectangle((14, 0 + f, 17, 2 + f), fill=(170, 176, 190))   # hammer


@art('knight')
def _(d, f):
    steel, dark, light, plume = (150, 164, 186), (100, 112, 136), (210, 220, 236), (210, 50, 60)
    lx = f
    d.rectangle((8 + lx, 17, 10 + lx, 22), fill=dark); d.rectangle((12 - lx, 17, 14 - lx, 22), fill=dark)
    d.rectangle((7, 9, 15, 17), fill=steel); d.rectangle((7, 9, 9, 17), fill=light); d.rectangle((13, 9, 15, 17), fill=dark)
    d.line((7, 15, 15, 15), fill=(120, 80, 44))
    d.rectangle((8, 2, 14, 9), fill=steel); d.line((8, 2, 14, 2), fill=light)
    d.line((9, 5, 14, 5), fill=K); d.point((13, 5), fill=(255, 220, 100))                # visor slit
    d.polygon([(10, 2), (7, -1), (6, 1), (9, 3)], fill=plume)
    d.rectangle((4, 9, 6, 15), fill=steel)
    d.line((5, 12, 1, 6 + f), fill=(130, 90, 50)); d.polygon([(1, 6 + f), (0, 2 + f), (2, 3 + f)], fill=light)   # spear
    # tower shield in front (right)
    d.rectangle((15, 7, 21, 19), fill=(60, 90, 170)); d.rectangle((15, 7, 21, 8), fill=(220, 190, 80))
    d.line((15, 19, 21, 19), fill=(220, 190, 80)); d.line((18, 9, 18, 17), fill=(220, 190, 80)); d.line((16, 12, 20, 12), fill=(220, 190, 80))
    d.line((21, 8, 21, 18), fill=(40, 60, 120))


@art('drake')
def _(d, f):
    sc, dark, light, belly = (210, 70, 56), (150, 40, 40), (250, 120, 90), (250, 200, 120)
    if f == 0:
        d.polygon([(9, 10), (4, 1), (13, 6)], fill=dark); d.polygon([(10, 9), (17, 0), (16, 8)], fill=dark)
        d.line((9, 10, 4, 1), fill=sc); d.line((10, 9, 17, 0), fill=sc)
    else:
        d.polygon([(9, 11), (2, 16), (12, 14)], fill=dark); d.polygon([(10, 11), (16, 18), (15, 12)], fill=dark)
    d.polygon([(6, 13), (0, 15 + f), (1, 12 + f), (5, 11)], fill=sc)             # tail
    d.point((0, 15 + f), fill=(250, 200, 80))
    d.ellipse((5, 9, 16, 17), fill=sc); d.ellipse((7, 13, 15, 17), fill=belly)
    d.ellipse((14, 5, 21, 11), fill=sc); d.rectangle((19, 8, 23, 10), fill=sc)   # head + snout
    d.point((22, 8), fill=K); d.point((17, 7), fill=(255, 230, 80))
    d.polygon([(15, 6), (14, 2), (17, 5)], fill=(250, 220, 170))               # horn
    d.line((8, 9, 13, 8), fill=light)
    d.line((9, 17, 9, 20), fill=dark); d.line((13, 17, 13, 20), fill=dark)
    if f:
        d.point([(23, 11), (22, 12)], fill=(255, 180, 40))                    # ember breath


# ===================================================================== friendly
@art('trooper')
def _(d, f):
    camo, dark, light, skin = (96, 120, 70), (66, 86, 48), (132, 156, 98), (228, 180, 138)
    lx = f
    d.rectangle((8 + lx, 17, 10 + lx, 22), fill=dark); d.rectangle((13 - lx, 17, 15 - lx, 22), fill=dark)
    d.rectangle((7 + lx, 21, 10 + lx, 22), fill=(50, 40, 34)); d.rectangle((13 - lx, 21, 16 - lx, 22), fill=(50, 40, 34))
    d.rectangle((4, 9, 7, 16), fill=(110, 90, 60))                         # backpack
    d.rectangle((7, 9, 16, 17), fill=camo); d.point([(9, 11), (14, 14), (11, 15)], fill=dark); d.point([(13, 10), (8, 14)], fill=light)
    d.rectangle((7, 15, 16, 15), fill=(60, 50, 40))
    d.rectangle((9, 3, 15, 9), fill=skin); d.point([(12, 6), (14, 6)], fill=K)
    d.chord((8, 0, 16, 8), 180, 360, fill=camo); d.line((7, 4, 16, 4), fill=dark)   # helmet
    d.point([(10, 2), (13, 1)], fill=light)
    d.rectangle((13, 11, 22, 12), fill=(60, 60, 66)); d.rectangle((14, 13, 16, 14), fill=(90, 70, 50))   # rifle
    d.point((22, 11), fill=(140, 140, 150))
    if f:
        d.point([(23, 11), (23, 12)], fill=(255, 230, 120))


@art('trader')
def _(d, f):
    coat, dark, light, skin = (40, 140, 150), (26, 96, 106), (80, 186, 190), (236, 190, 150)
    b = f
    d.rectangle((2, 5 + b, 9, 17 + b), fill=(150, 104, 60)); d.rectangle((2, 5 + b, 9, 7 + b), fill=(120, 80, 44))   # big pack
    d.point([(4, 10 + b), (6, 12 + b)], fill=(255, 210, 60)); d.rectangle((3, 14 + b, 8, 15 + b), fill=(200, 60, 60))
    d.line((5, 3 + b, 5, 5 + b), fill=(120, 80, 44)); d.ellipse((3, 1 + b, 7, 4 + b), fill=(220, 60, 60))   # pot on top
    d.polygon([(9, 10), (17, 10), (19, 22), (8, 22)], fill=coat); d.polygon([(14, 10), (17, 10), (19, 22), (15, 22)], fill=dark)
    d.line((13, 11, 13, 21), fill=(230, 190, 80)); d.rectangle((9, 16, 18, 17), fill=(110, 70, 40))
    d.rectangle((10, 4, 16, 10), fill=skin); d.point([(12, 6), (15, 6)], fill=K)
    d.line((11, 8, 16, 8), fill=(120, 70, 40)); d.point([(10, 9), (17, 9)], fill=(120, 70, 40))   # mustache
    d.rectangle((7, 2, 19, 3), fill=(120, 60, 120)); d.rectangle((9, 0, 17, 2), fill=(150, 80, 150))   # wide hat
    d.line((9, 1, 17, 1), fill=(230, 190, 80))
    d.line((18, 12, 21, 14 - b), fill=coat); d.ellipse((19, 12 - b, 22, 15 - b), fill=(255, 210, 60))   # shows a coin


@art('medic')
def _(d, f):
    coat, shade, red, skin = (240, 242, 248), (196, 204, 220), (220, 50, 60), (232, 186, 150)
    lx = f
    d.rectangle((8 + lx, 17, 10 + lx, 22), fill=(80, 100, 150)); d.rectangle((13 - lx, 17, 15 - lx, 22), fill=(80, 100, 150))
    d.rectangle((7, 9, 16, 18), fill=coat); d.rectangle((13, 9, 16, 18), fill=shade)
    d.rectangle((10, 11, 11, 15), fill=red); d.rectangle((8, 12, 13, 13), fill=red)          # cross
    d.rectangle((9, 3, 15, 9), fill=skin); d.point([(11, 6), (14, 6)], fill=K); d.point([(12, 8), (13, 8)], fill=(200, 110, 110))
    d.rectangle((8, 1, 16, 3), fill=(90, 150, 220)); d.rectangle((8, 0, 15, 1), fill=(120, 180, 240))
    d.point((7, 4), fill=(90, 60, 40)); d.rectangle((6, 3, 8, 8), fill=(110, 70, 46))        # hair
    d.rectangle((16, 13 - f, 21, 17 - f), fill=(200, 60, 60)); d.rectangle((18, 14 - f, 19, 16 - f), fill=(255, 255, 255))   # med bag
    d.line((17, 12 - f, 20, 12 - f), fill=(120, 30, 30))


@art('crate', 20)
def _(d, f):
    wood, dark, light, band = (176, 120, 66), (128, 84, 44), (214, 160, 100), (110, 120, 136)
    d.rectangle((1, 4, 18, 19), fill=wood)
    d.rectangle((1, 4, 18, 7), fill=light)
    d.line((1, 4, 18, 4), fill=(236, 190, 130))
    for y in (10, 14):
        d.line((2, y, 17, y), fill=dark)
    d.rectangle((1, 4, 3, 19), fill=band); d.rectangle((16, 4, 18, 19), fill=band)
    d.point([(2, 6), (17, 6), (2, 17), (17, 17)], fill=(200, 210, 220))
    d.rectangle((7, 11, 12, 16), fill=(60, 170, 90) if f == 0 else (110, 230, 140))       # stencil
    d.rectangle((9, 11, 10, 16), fill=(240, 240, 240)); d.rectangle((7, 13, 12, 14), fill=(240, 240, 240))
    d.rectangle((8, 1, 11, 4), fill=(200, 60, 60)); d.point((9, 0), fill=(255, 220, 90) if f else (255, 140, 80))   # beacon


# ===================================================================== machines (build_*)
def stone_base(d, s, y0):
    d.ellipse((2, y0, s - 3, s - 2), fill=(96, 96, 110)); d.ellipse((2, y0, s - 3, s - 5), fill=(132, 132, 146))
    d.ellipse((5, y0 + 2, s - 6, s - 7), fill=(156, 156, 170))


@art('build_turret', 32)
def _(d, f):
    stone_base(d, 32, 16)
    d.rectangle((10, 12, 21, 24), fill=(84, 92, 120)); d.rectangle((10, 12, 12, 24), fill=(118, 128, 160))
    d.rectangle((19, 12, 21, 24), fill=(60, 66, 90))
    d.line((10, 12, 21, 12), fill=(150, 160, 190))
    for x in (12, 15, 18):
        d.point((x, 22), fill=(255, 210, 80) if f else (180, 140, 60))
    d.ellipse((12, 6, 19, 13), fill=(70, 200, 240) if f else (50, 150, 200)); d.point((14, 8), fill=(220, 250, 255))


@art('build_cannon', 32)
def _(d, f):
    stone_base(d, 32, 17)
    d.rectangle((7, 16, 24, 24), fill=(130, 88, 50)); d.rectangle((7, 16, 24, 17), fill=(170, 120, 70))
    d.line((7, 20, 24, 20), fill=(96, 62, 34))
    d.ellipse((8, 6, 23, 20), fill=(58, 62, 76)); d.ellipse((10, 7, 15, 12), fill=(96, 100, 120))
    d.ellipse((11, 4, 20, 9), fill=(30, 30, 40)); d.ellipse((13, 5, 18, 8), fill=(255, 140, 40) if f else (14, 14, 20))
    d.line((8, 14, 23, 14), fill=(200, 170, 80))


@art('build_tesla', 32)
def _(d, f):
    stone_base(d, 32, 18)
    d.polygon([(11, 26), (13, 8), (18, 8), (20, 26)], fill=(176, 110, 60))
    for y in range(10, 25, 3):
        d.line((12, y, 19, y), fill=(226, 156, 80)); d.line((12, y + 1, 19, y + 1), fill=(120, 72, 40))
    d.ellipse((10, 1, 21, 11), fill=(90, 150, 255) if f else (70, 110, 220))
    d.ellipse((12, 3, 16, 6), fill=(220, 240, 255))
    if f:
        d.line((9, 4, 6, 1), fill=(200, 230, 255)); d.line((22, 5, 25, 2), fill=(200, 230, 255)); d.line((21, 9, 25, 11), fill=(200, 230, 255))


@art('build_frost', 32)
def _(d, f):
    stone_base(d, 32, 18)
    ice, idk, ilt = (150, 220, 250), (90, 160, 220), (230, 250, 255)
    d.polygon([(15, 1), (20, 12), (18, 25), (13, 25), (11, 12)], fill=ice)
    d.polygon([(15, 1), (20, 12), (18, 25), (16, 25)], fill=idk)
    d.polygon([(9, 12), (11, 9), (13, 22), (10, 24)], fill=ice); d.polygon([(22, 13), (20, 10), (18, 22), (21, 24)], fill=idk)
    d.line((14, 4, 13, 18), fill=ilt)
    if f:
        d.point([(6, 6), (25, 5), (24, 15), (7, 16)], fill=ilt)


@art('build_minter', 32)
def _(d, f):
    stone_base(d, 32, 19)
    gold, dark, light = (220, 170, 60), (160, 110, 30), (255, 226, 130)
    d.rectangle((7, 9, 24, 26), fill=gold); d.rectangle((7, 9, 24, 11), fill=light); d.rectangle((21, 11, 24, 26), fill=dark)
    d.rectangle((20, 2, 23, 9), fill=(110, 110, 124)); d.rectangle((19, 1, 24, 2), fill=(140, 140, 154))   # chimney
    d.ellipse((10, 13, 18, 21), fill=dark); d.ellipse((11, 14, 17, 20), fill=(120, 80, 30))              # gear window
    a = f
    for (x, y) in ((14, 14 + a), (14, 20 - a), (11 + a, 17), (17 - a, 17)):
        d.point((x, y), fill=light)
    d.rectangle((9, 23, 22, 24), fill=K)                                                                 # coin tray
    d.ellipse((12, 21 - f * 3, 16, 25 - f * 3), fill=(255, 220, 70))
    if f:
        d.point([(21, 0), (23, 0)], fill=(220, 220, 230))


@art('build_totem', 32)
def _(d, f):
    stone_base(d, 32, 20)
    wood, dark, light = (150, 100, 60), (110, 70, 40), (190, 140, 90)
    d.rectangle((11, 4, 20, 26), fill=wood); d.rectangle((18, 4, 20, 26), fill=dark); d.line((11, 4, 11, 26), fill=light)
    d.rectangle((12, 6, 14, 8), fill=K); d.rectangle((17, 6, 18, 8), fill=K); d.line((13, 11, 18, 11), fill=K)   # face
    d.polygon([(11, 14), (5, 12), (6, 16)], fill=(70, 160, 90)); d.polygon([(20, 14), (26, 12), (25, 16)], fill=(70, 160, 90))   # wings
    g = (120, 255, 150) if f else (80, 210, 110)
    d.ellipse((12, 16, 19, 23), fill=g); d.point((14, 18), fill=(240, 255, 240))
    d.polygon([(15, 0), (17, 4), (13, 4)], fill=(220, 60, 60))


@art('build_wall', 16)
def _(d, f):
    st, dk, lt = (150, 140, 128), (108, 100, 92), (186, 178, 164)
    d.rectangle((0, 3, 15, 15), fill=st); d.rectangle((0, 3, 15, 5), fill=lt)
    d.line((0, 9, 15, 9), fill=dk); d.line((0, 15, 15, 15), fill=dk)
    d.line((7, 5, 7, 9), fill=dk); d.line((3, 9, 3, 15), fill=dk); d.line((11, 9, 11, 15), fill=dk)
    d.point([(2, 7), (12, 12)], fill=lt)
    if f:   # damaged look
        d.line((5, 4, 8, 8), fill=K); d.line((8, 8, 7, 12), fill=K); d.point([(13, 4), (1, 13)], fill=(0, 0, 0, 0))


@art('build_spikes', 16)
def _(d, f):
    d.rectangle((1, 10, 14, 14), fill=(96, 88, 84)); d.line((1, 10, 14, 10), fill=(130, 120, 112))
    h = 7 if f else 3
    for x in (2, 6, 10):
        d.polygon([(x, 10), (x + 2, 10 - h), (x + 4, 10)], fill=(200, 206, 216))
        d.line((x + 2, 10 - h, x + 2, 9), fill=(240, 244, 250))


# ===================================================================== item icons (item_*)
def flask(d, liquid, shine=(255, 255, 255), big=False):
    glass = (210, 226, 240)
    if big:
        d.ellipse((1, 4, 14, 15), fill=glass); d.ellipse((2, 7, 13, 15), fill=liquid)
        d.rectangle((5, 1, 10, 4), fill=glass); d.rectangle((5, 0, 10, 1), fill=(140, 90, 50))
    else:
        d.ellipse((3, 6, 12, 15), fill=glass); d.ellipse((4, 8, 11, 15), fill=liquid)
        d.rectangle((6, 2, 9, 6), fill=glass); d.rectangle((5, 1, 10, 2), fill=(140, 90, 50))
    d.point([(5, 9), (5, 10)], fill=shine)


@art('item_potion_heal', 16, 1)
def _(d, f):
    flask(d, (226, 40, 60)); d.point([(7, 11), (8, 11), (7, 12)], fill=(255, 160, 170))


@art('item_potion_big', 16, 1)
def _(d, f):
    flask(d, (255, 190, 50), big=True)
    d.rectangle((7, 9, 8, 13), fill=(255, 255, 220)); d.rectangle((5, 10, 10, 11), fill=(255, 255, 220))


@art('item_potion_speed', 16, 1)
def _(d, f):
    flask(d, (90, 220, 230)); d.polygon([(12, 7), (15, 5), (14, 9)], fill=(250, 250, 255)); d.polygon([(3, 7), (0, 5), (1, 9)], fill=(250, 250, 255))


@art('item_potion_power', 16, 1)
def _(d, f):
    flask(d, (240, 110, 30)); d.polygon([(7, 9), (9, 9), (8, 11), (10, 11), (6, 14), (7, 12), (5, 12)], fill=(255, 240, 120))


@art('item_potion_shield', 16, 1)
def _(d, f):
    flask(d, (70, 120, 240)); d.polygon([(5, 9), (10, 9), (10, 12), (7, 14), (5, 12)], fill=(190, 220, 255))


@art('item_grenade', 16, 1)
def _(d, f):
    d.ellipse((2, 4, 13, 15), fill=(84, 120, 60)); d.ellipse((3, 5, 7, 9), fill=(130, 170, 100))
    for y in (8, 11):
        d.line((3, y, 12, y), fill=(56, 84, 40))
    d.rectangle((6, 1, 9, 4), fill=(150, 150, 160)); d.line((10, 2, 13, 0), fill=(200, 200, 210)); d.point((13, 1), fill=(200, 200, 210))


@art('item_frost', 16, 1)
def _(d, f):
    d.ellipse((2, 3, 13, 14), fill=(120, 200, 250)); d.ellipse((3, 4, 7, 8), fill=(230, 250, 255))
    d.line((8, 5, 8, 12), fill=(255, 255, 255)); d.line((5, 8, 11, 8), fill=(255, 255, 255))
    d.line((6, 6, 10, 10), fill=(200, 240, 255)); d.line((10, 6, 6, 10), fill=(200, 240, 255))


@art('item_flare', 16, 1)
def _(d, f):
    d.rectangle((6, 6, 9, 15), fill=(210, 50, 50)); d.rectangle((6, 6, 7, 15), fill=(240, 100, 100))
    d.rectangle((6, 11, 9, 12), fill=(240, 240, 240))
    d.ellipse((4, 0, 11, 7), fill=(255, 140, 60)); d.ellipse((6, 2, 9, 5), fill=(255, 240, 160))


@art('item_repair', 16, 1)
def _(d, f):
    d.line((2, 13, 11, 4), fill=(150, 156, 170), width=2); d.ellipse((9, 1, 14, 6), fill=(150, 156, 170)); d.ellipse((11, 2, 13, 4), fill=(0, 0, 0, 0))
    d.line((3, 3, 12, 12), fill=(150, 100, 60), width=2); d.rectangle((1, 1, 5, 5), fill=(110, 116, 130))


def build():
    out = {}
    for name, (fn, size, frames) in ART.items():
        out[name] = strip(fn, size, frames)
    return out


if __name__ == '__main__':
    imgs = build()
    for name, im in imgs.items():
        im.save(os.path.join(OUT, f'{name}.png'))
    print(len(imgs), 'images ->', OUT)
    if len(sys.argv) > 1:   # contact sheet, 4x, on grass
        cols = 8
        cell = 70
        rows = (len(imgs) + cols - 1) // cols
        P = Image.new('RGBA', (cols * cell * 2, rows * cell), (74, 118, 64, 255))
        for i, (n, im) in enumerate(imgs.items()):
            big = im.resize((im.width * 3, im.height * 3), Image.NEAREST)
            P.alpha_composite(big, ((i % cols) * cell * 2 + 4, (i // cols) * cell + 4))
        P.save(sys.argv[1])
