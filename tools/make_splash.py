"""Boot splash / web loading picture: assets/ui/splash.png (1280x720).
Run: python tools/make_splash.py

A sunset over the Survival island, built from the game's own sprites: the scene is drawn
at 320x180 and scaled 4x (pixel art), the title is set in Jersey 10 on top. Godot shows
it while the engine starts (project.godot: boot_splash), the web page (web/shell.html)
shows it behind the loading bar.
"""
import os, random
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, 'assets')
W, H, K = 320, 180, 4
HORIZON = 112
TOP, MID, LOW = (16, 14, 46), (86, 46, 108), (244, 150, 92)       # sky: night -> dusk -> sunset
SEA_TOP, SEA_LOW = (58, 62, 126), (12, 16, 48)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def frame(name, size, n=0):
    return Image.open(os.path.join(A, 'survival', name + '.png')).convert('RGBA').crop((n * size, 0, n * size + size, size))


def build():
    random.seed(7)
    im = Image.new('RGBA', (W, H))
    d = ImageDraw.Draw(im)
    for y in range(HORIZON):                                   # sky, in bands (no smooth gradient: pixel art)
        t = (y // 4 * 4) / HORIZON
        c = lerp(TOP, MID, t / 0.6) if t < 0.6 else lerp(MID, LOW, (t - 0.6) / 0.4)
        d.line((0, y, W, y), fill=c + (255,))
    for _ in range(90):                                        # stars, fading toward the horizon
        x, y = random.randrange(W), random.randrange(70)
        v = 255 - y * 2 - random.randrange(60)
        d.point((x, y), fill=(v, v, min(255, v + 30), 255))
    for x, y in ((40, 18), (250, 30), (296, 12), (120, 8)):    # a few bright ones
        d.point([(x, y), (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)], fill=(255, 250, 220, 255))
    d.ellipse((160 - 26, HORIZON - 26, 160 + 26, HORIZON + 26), fill=(255, 190, 110, 255))   # sun
    d.ellipse((160 - 21, HORIZON - 21, 160 + 21, HORIZON + 21), fill=(255, 226, 150, 255))
    for cx, cy, w in ((60, 70, 34), (236, 60, 44), (286, 84, 26), (20, 92, 22)):             # clouds
        d.rectangle((cx - w // 2, cy, cx + w // 2, cy + 2), fill=(150, 80, 120, 255))
        d.rectangle((cx - w // 3, cy - 2, cx + w // 4, cy), fill=(196, 110, 126, 255))
    for y in range(HORIZON, H):                                # sea
        t = ((y - HORIZON) // 4 * 4) / (H - HORIZON)
        d.line((0, y, W, y), fill=lerp(SEA_TOP, SEA_LOW, t) + (255,))
    for y in range(HORIZON + 1, H, 3):                         # the sun's path on the water
        w = 30 - (y - HORIZON) // 3 + random.randrange(-4, 5)
        if w > 2:
            d.line((160 - w, y, 160 + w, y), fill=(255, 196, 130, 255))
    for _ in range(40):                                        # glints
        x, y = random.randrange(W), random.randrange(HORIZON + 4, H)
        d.line((x, y, x + random.randrange(3, 9), y), fill=(110, 120, 190, 255))

    # the island
    d.ellipse((66, 122, 254, 150), fill=(226, 190, 128, 255))          # sand
    d.ellipse((74, 119, 246, 144), fill=(58, 128, 70, 255))            # grass
    d.ellipse((84, 119, 236, 136), fill=(78, 154, 82, 255))
    d.rectangle((0, 150, W, 151), fill=lerp(SEA_TOP, SEA_LOW, 0.55) + (255,))
    for x in range(70, 250, 9):                                        # foam
        d.line((x, 149 + (x // 9) % 2, x + 5, 149 + (x // 9) % 2), fill=(214, 224, 255, 255))

    def put(sprite, x, y, scale=1.0, flip=False, shadow=True):   # x, y = where its feet stand
        s = sprite
        if scale != 1.0:
            s = s.resize((max(1, int(s.width * scale)), max(1, int(s.height * scale))), Image.NEAREST)
        if flip:
            s = s.transpose(Image.FLIP_LEFT_RIGHT)
        if shadow:
            d.ellipse((x - s.width // 3, y - 2, x + s.width // 3, y + 2), fill=(24, 60, 44, 255))
        im.alpha_composite(s, (x - s.width // 2, y - s.height))

    tree = lambda n: Image.open(os.path.join(A, 'trees', n + '.png')).convert('RGBA')
    put(tree('fir_tree_1'), 92, 130, 0.28)
    put(tree('birch_1'), 228, 131, 0.26)
    put(tree('fir_tree_3'), 212, 127, 0.2)
    put(frame('prop_pillar', 32), 118, 128)
    put(frame('prop_ruin', 32), 196, 136)
    put(frame('prop_tent', 32), 160, 133, 1.25)
    put(frame('prop_bush', 16), 104, 139)
    put(frame('prop_rock1', 16), 222, 141)
    put(frame('prop_crystal', 16), 84, 135)
    put(frame('prop_campfire', 16), 138, 142)
    put(frame('trader', 24), 180, 141)
    put(frame('trooper', 24), 124, 144)
    put(frame('boss_bonelord', 32), 240, 138, 1.0, True)
    put(frame('slime', 24), 204, 145)
    put(frame('bat_hd', 24), 58, 96, shadow=False)
    put(frame('bat_hd', 24, 1), 268, 104, 1.0, True, False)

    big = im.resize((W * K, H * K), Image.NEAREST)
    d = ImageDraw.Draw(big)
    font = lambda s: ImageFont.truetype(os.path.join(A, 'fonts', 'Jersey10-Regular.ttf'), s)
    title = 'ENDLESS WORLDS'
    f = font(168)
    tw = d.textlength(title, font=f)
    x, y = (W * K - tw) / 2, 78
    d.text((x, y + 10), title, font=f, fill=(60, 20, 30, 255), stroke_width=10, stroke_fill=(60, 20, 30, 255))   # drop shadow
    d.text((x, y), title, font=f, fill=(255, 206, 76, 255), stroke_width=10, stroke_fill=(34, 16, 44, 255))
    d.text((x, y - 6), title, font=f, fill=(255, 238, 150, 255))                                              # top-light
    d.text((x, y), title, font=f, fill=(255, 206, 76, 255))
    sub = 'riddles · monsters · one small island'
    f2 = font(52)
    sw = d.textlength(sub, font=f2)
    d.text(((W * K - sw) / 2, y + 168), sub, font=f2, fill=(250, 236, 214, 255), stroke_width=5, stroke_fill=(34, 16, 44, 255))
    return big.convert('RGB')


if __name__ == '__main__':
    out = os.path.join(A, 'ui', 'splash.png')
    build().save(out)
    print('splash ->', out)
