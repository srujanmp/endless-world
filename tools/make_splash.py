"""Boot splash / web loading picture: assets/ui/splash.png (1280x720).
Run: python tools/make_splash.py

The title over a sunset sea, and the machine-learning ideas the game is built on as five
pixel-art cards: web search -> RAG -> LLM (the riddle pipeline), Q-learning (adaptive
difficulty) and speech (talking to Bolt). The scene is drawn at 320x180 and scaled 4x,
the lettering is set in Jersey 10 on top. Godot shows it while the engine starts
(project.godot: boot_splash); the web page (web/shell.html) shows it behind the loading bar.
"""
import os, random
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, 'assets')
W, H, K = 320, 180, 4
HORIZON = 112
TOP, MID, LOW = (16, 14, 46), (86, 46, 108), (244, 150, 92)       # sky: night -> dusk -> sunset
SEA_TOP, SEA_LOW = (58, 62, 126), (12, 16, 48)
NAVY, EDGE, GOLD, INK = (18, 22, 50), (34, 16, 44), (255, 204, 72), (10, 12, 30)
CARD, GAP, CY = 46, 12, 72                                         # card size, gap, top (low-res px)
CARDS = [('WEB SEARCH', 'finds live pages'), ('RAG', 'retrieves the facts'), ('LLM', 'writes the riddle'),
         ('Q-LEARNING', 'adapts the difficulty'), ('SPEECH', 'hears your voice')]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def card_x(i):
    return (W - (len(CARDS) * CARD + (len(CARDS) - 1) * GAP)) // 2 + i * (CARD + GAP)


# ---------------------------------------------------------------- the five icons (ox, oy = card corner)
def icon_search(d, x, y):
    cx, cy = x + 20, y + 21
    d.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=(52, 150, 226))                    # globe
    d.ellipse((cx - 13, cy - 13, cx + 2, cy + 2), fill=(96, 190, 246))
    d.polygon([(cx - 9, cy - 6), (cx - 2, cy - 9), (cx + 2, cy - 3), (cx - 3, cy + 2), (cx - 8, cy)], fill=(92, 190, 96))
    d.polygon([(cx + 3, cy + 2), (cx + 9, cy), (cx + 10, cy + 6), (cx + 5, cy + 10), (cx + 1, cy + 7)], fill=(92, 190, 96))
    d.arc((cx - 13, cy - 13, cx + 13, cy + 13), 0, 360, fill=INK)
    d.arc((cx - 6, cy - 13, cx + 6, cy + 13), 0, 360, fill=(28, 96, 170))
    d.line((cx - 13, cy, cx + 13, cy), fill=(28, 96, 170))
    d.line((x + 31, y + 31, x + 39, y + 39), fill=INK, width=5); d.line((x + 31, y + 31, x + 38, y + 38), fill=(170, 116, 70), width=3)
    d.ellipse((x + 20, y + 20, x + 34, y + 34), fill=(200, 236, 255)); d.ellipse((x + 20, y + 20, x + 34, y + 34), outline=INK)
    d.ellipse((x + 21, y + 21, x + 33, y + 33), outline=(236, 236, 244)); d.line((x + 24, y + 25, x + 27, y + 23), fill=(255, 255, 255))


def icon_rag(d, x, y):
    for i, (px, py) in enumerate(((7, 13), (10, 10), (13, 7))):                             # stack of pages
        d.rectangle((x + px, y + py, x + px + 15, y + py + 22), fill=(236, 232, 220) if i == 2 else (176, 176, 190), outline=INK)
    for ly in (11, 14, 20, 23, 26):
        d.line((x + 16, y + ly, x + 26, y + ly), fill=(150, 150, 166))
    d.rectangle((x + 15, y + 16, x + 27, y + 18), fill=GOLD)                                # the passage that matters
    d.line((x + 28, y + 17, x + 34, y + 17), fill=GOLD); d.polygon([(x + 34, y + 14), (x + 38, y + 17), (x + 34, y + 20)], fill=GOLD)
    for px, py, c in ((33, 30, (96, 190, 246)), (38, 34, (96, 190, 246)), (30, 36, (96, 190, 246)), (36, 39, (96, 190, 246)), (35, 26, GOLD)):
        d.rectangle((x + px, y + py, x + px + 2, y + py + 2), fill=c)                       # vectors; the nearest one lit
    d.rectangle((x + 33, y + 24, x + 39, y + 30), outline=GOLD)


def icon_llm(d, x, y):
    layers = [[(9, 12), (9, 23), (9, 34)], [(23, 8), (23, 18), (23, 28), (23, 38)], [(37, 16), (37, 30)]]
    for a, b in ((0, 1), (1, 2)):
        for p in layers[a]:
            for q in layers[b]:
                d.line((x + p[0], y + p[1], x + q[0], y + q[1]), fill=(70, 84, 140))
    for p, q in (((9, 23), (23, 18)), ((23, 18), (37, 30)), ((9, 12), (23, 28)), ((23, 28), (37, 16))):   # the lit path
        d.line((x + p[0], y + p[1], x + q[0], y + q[1]), fill=GOLD)
    for li, col in enumerate(((96, 190, 246), (236, 110, 170), (255, 204, 72))):
        for px, py in layers[li]:
            d.ellipse((x + px - 4, y + py - 4, x + px + 4, y + py + 4), fill=INK)
            d.ellipse((x + px - 3, y + py - 3, x + px + 3, y + py + 3), fill=col)
            d.point((x + px - 1, y + py - 1), fill=(255, 255, 255))


def icon_q(d, x, y):
    heat = [(30, 44, 100), (40, 96, 150), (60, 160, 120), (150, 200, 90), (255, 204, 72)]
    vals = [[0, 1, 1, 2], [1, 1, 2, 3], [1, 2, 3, 4], [0, 1, 3, 4]]
    for r in range(4):
        for c in range(4):
            d.rectangle((x + 7 + c * 8, y + 7 + r * 8, x + 14 + c * 8, y + 14 + r * 8), fill=heat[vals[r][c]], outline=INK)
    path = [(10, 34), (18, 34), (18, 26), (26, 26), (26, 18), (34, 18)]                     # the policy it learned
    for a, b in zip(path, path[1:]):
        d.line((x + a[0], y + a[1], x + b[0], y + b[1]), fill=(255, 255, 255), width=1)
    d.polygon([(x + 34, y + 14), (x + 39, y + 18), (x + 34, y + 22)], fill=(255, 255, 255))
    d.ellipse((x + 8, y + 32, x + 12, y + 36), fill=(236, 110, 170), outline=INK)             # the agent


def icon_speech(d, x, y):
    cx = x + 23
    for i, h in enumerate((3, 7, 4, 9, 5)):                                                 # sound, both sides
        for s in (-1, 1):
            bx = cx + s * (11 + i * 2) + (0 if s > 0 else -1)
            if x + 4 <= bx <= x + 41:
                d.line((bx, y + 20 - h, bx, y + 20 + h), fill=(96, 190, 246) if i % 2 else (160, 220, 250))
    d.rounded_rectangle((cx - 6, y + 6, cx + 6, y + 27), radius=6, fill=(196, 200, 214), outline=INK)   # microphone
    d.rounded_rectangle((cx - 4, y + 8, cx - 1, y + 20), radius=2, fill=(240, 242, 250))
    for ly in (12, 16, 20):
        d.line((cx, y + ly, cx + 4, y + ly), fill=(120, 126, 146))
    stand = (150, 156, 178)
    d.arc((cx - 9, y + 16, cx + 9, y + 33), 0, 180, fill=stand, width=2)
    d.line((cx, y + 33, cx, y + 38), fill=stand, width=2); d.line((cx - 6, y + 39, cx + 6, y + 39), fill=stand, width=2)


ICONS = [icon_search, icon_rag, icon_llm, icon_q, icon_speech]


def build():
    random.seed(7)
    im = Image.new('RGBA', (W, H))
    d = ImageDraw.Draw(im)
    for y in range(HORIZON):                                   # sky, in bands (pixel art: no smooth gradient)
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
    for cx, cy, w in ((30, 62, 34), (292, 58, 40)):            # clouds
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

    for i, draw_icon in enumerate(ICONS):                      # the cards
        x = card_x(i)
        d.rectangle((x + 2, CY + 3, x + CARD + 1, CY + CARD + 2), fill=(8, 8, 26, 255))      # drop shadow
        d.rectangle((x - 1, CY - 1, x + CARD, CY + CARD), fill=EDGE)
        d.rectangle((x, CY, x + CARD - 1, CY + CARD - 1), fill=GOLD)
        d.rectangle((x + 1, CY + 1, x + CARD - 2, CY + CARD - 2), fill=NAVY)
        d.line((x + 1, CY + 1, x + CARD - 2, CY + 1), fill=(34, 42, 86))
        draw_icon(d, x, CY)
        if i < 2:                                              # search -> RAG -> LLM is one pipeline
            ax, ay = x + CARD + 3, CY + CARD // 2
            d.polygon([(ax, ay - 4), (ax + 5, ay), (ax, ay + 4)], fill=EDGE)
            d.polygon([(ax + 1, ay - 2), (ax + 4, ay), (ax + 1, ay + 2)], fill=GOLD)

    big = im.resize((W * K, H * K), Image.NEAREST)
    d = ImageDraw.Draw(big)
    font = lambda s: ImageFont.truetype(os.path.join(A, 'fonts', 'Jersey10-Regular.ttf'), s)

    def centred(text, cx, y, size, fill, stroke):
        f = font(size)
        d.text((cx - d.textlength(text, font=f) / 2, y), text, font=f, fill=fill, stroke_width=stroke, stroke_fill=EDGE + (255,))

    title = 'ENDLESS WORLDS'
    f = font(150)
    x, y = (W * K - d.textlength(title, font=f)) / 2, 24
    d.text((x, y + 9), title, font=f, fill=(60, 20, 30, 255), stroke_width=9, stroke_fill=(60, 20, 30, 255))   # drop shadow
    d.text((x, y), title, font=f, fill=GOLD + (255,), stroke_width=9, stroke_fill=EDGE + (255,))
    d.text((x, y - 5), title, font=f, fill=(255, 238, 150, 255))                                             # top-light
    d.text((x, y), title, font=f, fill=GOLD + (255,))
    centred('type any topic · AI turns it into a riddle', W * K / 2, 196, 46, (250, 236, 214, 255), 5)
    for i, (name, what) in enumerate(CARDS):
        cx = (card_x(i) + CARD / 2) * K
        centred(name, cx, (CY + CARD) * K + 12, 44, GOLD + (255,), 5)
        centred(what, cx, (CY + CARD) * K + 56, 28, (250, 236, 214, 255), 4)
    return big.convert('RGB')


if __name__ == '__main__':
    out = os.path.join(A, 'ui', 'splash.png')
    build().save(out)
    print('splash ->', out)
