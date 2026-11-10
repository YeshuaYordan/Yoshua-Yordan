"""Cut a 4x4 character sheet (rows: walk, stand, eat-sitting, drink-sitting; a label column on the left)
into equal frames with a transparent background.

Usage: python3 tools/slice_sprites.py SOURCE.png OUT_FULL.png
The game uses a 72% size, 128-colour version of OUT_FULL (assets/characters/girl-sheet.png).
"""
import sys
from collections import deque
from PIL import Image
SRC = sys.argv[1] if len(sys.argv) > 1 else 'sprites/source.png'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'sprites/sheet_full.png'
im = Image.open(SRC).convert('RGBA'); W, H = im.size; px = im.load()
rows = [(0, 273), (278, 523), (528, 768), (773, 1023)]
def isbg(c):  # white paper / near white
    r, g, b, a = c
    return r > 236 and g > 236 and b > 236 and max(r, g, b) - min(r, g, b) < 14
def islav(c):  # lavender separator lines / label boxes
    r, g, b, a = c
    return b - g > 18 and r - g > 5 and g > 150
# find sprite columns in x>=290 per row via content projection
def cols_for(y0, y1):
    occ = []
    for x in range(290, W):
        n = 0
        for y in range(y0, y1, 2):
            c = px[x, y]
            if not isbg(c) and not islav(c): n += 1
        occ.append(n > 1)
    spans, inside = [], False
    for i, o in enumerate(occ):
        x = i + 290
        if o and not inside: s = x; inside = True
        if not o and inside:
            if x - s > 40: spans.append([s, x])
            inside = False
    if inside: spans.append([s, W])
    # merge small effects (sparkles) into nearest sprite
    merged = []
    for sp in spans:
        if merged and sp[0] - merged[-1][1] < 30: merged[-1][1] = sp[1]
        else: merged.append(sp)
    return merged
frames = []
for ri, (y0, y1) in enumerate(rows):
    cs = cols_for(y0, y1)
    print('row', ri, cs, file=sys.stderr)
    for (x0, x1) in cs:
        cell = im.crop((x0 - 6, y0, min(W, x1 + 6), y1 + 1))
        cw, ch = cell.size; cp = cell.load()
        # flood fill background from the cell border
        seen = [[False] * ch for _ in range(cw)]
        q = deque()
        for x in range(cw):
            for y in (0, ch - 1): q.append((x, y))
        for y in range(ch):
            for x in (0, cw - 1): q.append((x, y))
        while q:
            x, y = q.popleft()
            if x < 0 or y < 0 or x >= cw or y >= ch or seen[x][y]: continue
            c = cp[x, y]
            if not (isbg(c) or islav(c)): continue
            seen[x][y] = True
            cp[x, y] = (0, 0, 0, 0)
            q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
        # enclosed white pockets (gaps between legs, arm and body): remove if big enough
        vis = [[False] * ch for _ in range(cw)]
        for x in range(cw):
            for y in range(ch):
                if vis[x][y] or cp[x, y][3] == 0 or not isbg(cp[x, y]): continue
                comp = []; q = deque([(x, y)]); vis[x][y] = True
                while q:
                    a, b = q.popleft(); comp.append((a, b))
                    for na, nb in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                        if 0 <= na < cw and 0 <= nb < ch and not vis[na][nb] and cp[na, nb][3] and isbg(cp[na, nb]):
                            vis[na][nb] = True; q.append((na, nb))
                # keep pockets in the head band (hair clip, eye shine); remove the rest (gaps by legs, arms, hair tuft)
                xs = [p[0] for p in comp]; ys = [p[1] for p in comp]
                cyr = (sum(ys) / len(ys)) / ch
                # remove: the loop of the hair tuft at the top, and real gaps lower down (between legs, arm and body).
                # keep: hair clip, eye shine, shirt highlights (small pockets).
                keep = not (cyr < .2 or (cyr > .55 and len(comp) > 120))
                if not keep:
                    for a, b in comp: cp[a, b] = (0, 0, 0, 0)
        # soften the light fringe left by anti-aliasing against white
        fringe = []
        for x in range(cw):
            for y in range(ch):
                r, g, b, a = cp[x, y]
                if a and r > 225 and g > 225 and b > 225:
                    nb = sum(1 for na, nb2 in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)) if 0<=na<cw and 0<=nb2<ch and cp[na,nb2][3]==0)
                    if nb >= 2: fringe.append((x, y))
        for x, y in fringe:
            r, g, b, a = cp[x, y]; cp[x, y] = (r, g, b, 0)
        bb = cell.getbbox()
        col = len([f for f in frames if f[0] == ri])
        # position inside the source grid: column origins are evenly spaced (~288px)
        gx = (x0 - 6 + bb[0]) - (300 + col * 287.7)
        gy = (y0 + bb[3]) - y1
        frames.append((ri, cell.crop(bb), (gx, gy)))
# layout into a uniform grid: every frame in a cell of the same size, bottom aligned, centered on the row's body center
minx = min(f[2][0] for f in frames); maxx = max(f[2][0] + f[1].size[0] for f in frames)
FW = int(maxx - minx) + 4
FH = max(f[1].size[1] - min(0, f[2][1]) for f in frames) + 4
print('frame', FW, FH, file=sys.stderr)
sheet = Image.new('RGBA', (FW * 4, FH * 4), (0, 0, 0, 0))
for i, (ri, fr, (gx, gy)) in enumerate(frames):
    col = i % 4
    w, h = fr.size
    # same feet line for every frame in a row; horizontal position kept from the source grid
    sheet.paste(fr, (int(col * FW + 2 + gx - minx), int(ri * FH + FH - 2 - h)), fr)
sheet.save(OUT)
print(len(frames), sheet.size)
