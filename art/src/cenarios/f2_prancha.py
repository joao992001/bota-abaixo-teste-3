"""FOTOGRAFIAS CONCEITUAIS — FASE 2 do Derruba: CARGUEIRO PERDIDO (biblioteca docs/fases/derruba/f2_cargueiro/).
As 3 cenas como TELA DE JOGO (1920×1080, grid 64 px, arena 30 colunas), papel e giz, com o elenco em ação e os
mecanismos no lugar (etiquetas). Camadas: C0 céu/água · C1 fundo distante · C2 fundo próximo · C3 palco · C4 frente.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_prancha.py → art/out/fase2/cena1_conves.png, cena2a_destrocos.png, cena2b_atlantida.png
"""
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../robos"))
import elenco as el  # noqa: E402
import base64  # noqa: E402
from papel import ellipse_d, rect_d, rough, shape  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
SRC = os.path.join(HERE, "svg/fase2")
OUT = os.path.join(ROOT, "art/out/fase2")
T = 64
W, H = 1920, 1080
INK = "#2a1a2e"
YEL, YEL_D = "#f2c84b", "#c49a2a"
FERR, FERR_D = "#b5482f", "#8a3524"
CONT = ["#d14b4b", "#3f7fd0", "#4fae5b", "#f2a33a", "#8a63d2", "#e0c34a", "#3fb6b0"]
_id = [0]


def S(d, fill, box, k=2.0, **kw):
    _id[0] += 1
    return shape(f"f2s{_id[0]}", d, fill, 1700 + _id[0], box, k=k, **kw)


def R(x, y, w, h, fill, r=4, k=2.0, **kw):
    return S(rect_d(x, y, w, h, r), fill, (x - 2, y - 2, x + w + 2, y + h + 2), k=k, **kw)


def E(cx, cy, rx, ry, fill, k=2.0, **kw):
    return S(ellipse_d(cx, cy, rx, ry), fill, (cx - rx - 2, cy - ry - 2, cx + rx + 2, cy + ry + 2), k=k, **kw)


def PL(pts, fill, k=2.0, **kw):
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return S(d, fill, (min(xs) - 2, min(ys) - 2, max(xs) + 2, max(ys) + 2), k=k, **kw)


def robot(cid, pose, col, x, y, s=0.8, flip=False, rot=0):
    sx = -s if flip else s
    return f'<g transform="translate({x},{y}) rotate({rot}) scale({sx},{s})">{el.draw(cid, el.POSES[cid][pose], col)}</g>'


def tag(x, y, txt):
    w = len(txt) * 10 + 24
    return (f'<rect x="{x - w / 2}" y="{y - 16}" width="{w}" height="30" rx="10" fill="#ffffff" stroke="{INK}" stroke-width="3"/>'
            f'<text x="{x}" y="{y + 6}" font-family="Fredoka" font-weight="700" font-size="17" fill="{INK}" text-anchor="middle">{txt}</text>')


def sign(x, y, txt, w=None, bg=YEL):
    w = w or len(txt) * 11 + 30
    return (R(x, y, w, 40, bg, 6, 1.2) + f'<rect x="{x + 4}" y="{y + 32}" width="{w - 8}" height="5" fill="{INK}" opacity="0.6"/>'
            f'<text x="{x + w / 2}" y="{y + 26}" font-family="Fredoka" font-weight="700" font-size="18" fill="{INK}" text-anchor="middle">{txt}</text>')


def zebra(x, y, w, h=12):
    o = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{YEL}"/>'
    for k in range(int(w / 20) + 1):
        o += f'<path d="M{x + k * 20},{y + h} l10,-{h} h8 l-10,{h} Z" fill="{INK}" opacity="0.85"/>'
    return o


def fonte():
    a = os.path.join(ROOT, "game/assets/fonts/fredoka-700.woff2")
    f7 = base64.b64encode(open(a, "rb").read()).decode()
    return "<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}</style>"


def rot_pt(x, y, cx, cy, ang):
    a = math.radians(ang)
    dx, dy = x - cx, y - cy
    return cx + dx * math.cos(a) - dy * math.sin(a), cy + dx * math.sin(a) + dy * math.cos(a)


def grad(gid, stops, x2="0", y2="1"):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def conteiner(x, y, w, h, cor, dano=0, porta=False):
    o = R(x, y, w, h, cor, 3, 1.6, dark=shade(cor, -0.3))
    for j in range(int(w / 16)):
        o += f'<path d="M{x + 8 + j * 16},{y + 6} v{h - 12}" stroke="{shade(cor, -0.22)}" stroke-width="3"/>'
    o += f'<rect x="{x}" y="{y}" width="{w}" height="6" fill="{shade(cor, 0.18)}"/><rect x="{x}" y="{y + h - 6}" width="{w}" height="6" fill="{shade(cor, -0.35)}"/>'
    if porta:
        o += f'<path d="M{x + w - 30},{y + 8} v{h - 16} M{x + w - 16},{y + 8} v{h - 16}" stroke="{shade(cor, -0.4)}" stroke-width="3"/>'
    if dano >= 1:
        o += f'<path d="M{x + w * 0.3},{y + 4} l10,18 l-12,10 l14,16" stroke="{INK}" stroke-width="3" fill="none"/>'
    if dano >= 2:
        o += f'<path d="M{x + w * 0.7},{y + h - 4} l-8,-14 l12,-8" stroke="{INK}" stroke-width="3" fill="none"/>'
        o += E(x + w * 0.55, y + h * 0.5, 12, 8, shade(cor, -0.45), 1.0)
    return o


def ondas_frente(y, cor, cor2, amp=18, seed=1, fase=0):
    rnd = random.Random(seed)
    d = f"M-20,{H} L-20,{y}"
    x = -20
    while x < W + 40:
        a = amp * rnd.uniform(0.6, 1.2)
        d += f" q30,{-a} 60,0 t60,0"
        x += 120
    d += f" L{W + 40},{H} Z"
    o = S(d, cor, (-20, y - amp, W + 40, H), k=2.2, dark=shade(cor, -0.25))
    for k in range(10):
        xx = rnd.uniform(0, W)
        o += f'<path d="M{xx},{y + 30 + rnd.uniform(0, 50)} q16,-6 32,0" stroke="{cor2}" stroke-width="4" fill="none" opacity="0.8"/>'
    return o


# =========================================================================================== CENA 1 — CARGUEIRO NO ALTO-MAR
DECK = 13 * T          # convés (chão do palco)


def c1_ceu():
    o = f'<rect width="{W}" height="{H}" fill="url(#c1ceu)"/>'
    o += f'<circle cx="300" cy="300" r="110" fill="#fde2a0" opacity="0.85"/><circle cx="300" cy="300" r="160" fill="#fde2a0" opacity="0.2"/>'
    rnd = random.Random(3)
    for cx, cy, s, col in [(1350, 150, 1.4, "#8a7aa0"), (1650, 110, 1.8, "#6f6290"), (1850, 210, 1.3, "#7a6c98"), (620, 120, 0.9, "#f4c9b0")]:
        for dx, dy, r in [(0, 0, 60), (70, -24, 70), (150, 0, 60), (60, 26, 56)]:
            o += E(cx + dx * s, cy + dy * s, r * s, r * 0.7 * s, col, 1.4)
    for k in range(40):   # chuva chegando pela direita
        x = rnd.uniform(1300, W)
        y = rnd.uniform(200, 560)
        o += f'<path d="M{x},{y} l-12,34" stroke="#c9c2e0" stroke-width="2" opacity="0.6"/>'
    for k in range(5):    # gaivotas
        x, y = 500 + k * 90 + rnd.uniform(-20, 20), 180 + rnd.uniform(-40, 40)
        o += f'<path d="M{x},{y} q10,-10 20,0 q10,-10 20,0" stroke="{INK}" stroke-width="3" fill="none"/>'
    return o


def c1_longe():
    o = f'<rect x="0" y="600" width="{W}" height="{H - 600}" fill="#3a6f9a"/>'
    o += f'<rect x="0" y="600" width="{W}" height="14" fill="#f6c89a" opacity="0.5"/>'
    # navio distante + balsa-guindaste da equipe (identidade da obra)
    o += PL([(160, 600), (360, 600), (340, 624), (175, 624)], "#5a4f6a", 1.2) + R(300, 572, 30, 28, "#5a4f6a", 2, 1.0)
    o += R(760, 576, 170, 26, "#4a5468", 3, 1.2) + R(830, 470, 12, 106, YEL_D, 2, 1.0) + R(760, 462, 150, 10, YEL_D, 2, 1.0)
    o += f'<path d="M768,472 v40" stroke="{INK}" stroke-width="2"/>'
    rnd = random.Random(8)
    for k in range(30):
        o += f'<path d="M{rnd.uniform(0, W)},{rnd.uniform(620, 760)} h{rnd.uniform(20, 60)}" stroke="#7fb0d6" stroke-width="3" opacity="0.6"/>'
    return o


def c1_navio():
    o = ""
    # casco (vai além das bordas: o palco é o navio inteiro)
    o += PL([(-40, DECK), (1720, DECK), (1720, 11 * T), (1960, 11 * T), (1960, H), (-40, H)], FERR, 2.4, dark=FERR_D)
    o += f'<rect x="-40" y="{DECK + 150}" width="{W + 80}" height="22" fill="#e9e2d2" opacity="0.9"/>'   # linha d'água pintada
    for k in range(14):
        o += E(80 + k * 130, DECK + 80, 14, 14, "#3a3f4a", 1.0) + f'<circle cx="{80 + k * 130 - 4}" cy="{DECK + 76}" r="4" fill="#9fc0dc"/>'
    o += f'<text x="980" y="{DECK + 128}" font-family="Fredoka" font-weight="700" font-size="40" fill="#e9e2d2" text-anchor="middle" opacity="0.85">ESTRELA DO SUL · PORTO LIVRE</text>'
    # convés
    o += R(-40, DECK - 10, 1760, 20, "#6b6f7a", 2, 1.4) + R(1720, 11 * T - 10, 240, 20, "#6b6f7a", 2, 1.4)
    for x in range(-40, 1720, 48):   # guarda-corpo
        o += f'<path d="M{x},{DECK - 10} v-40" stroke="#e9e2d2" stroke-width="4"/>'
    o += f'<path d="M-40,{DECK - 50} H1720 M-40,{DECK - 30} H1720" stroke="#e9e2d2" stroke-width="4"/>'
    return o


def c1_ponte():
    """Ponte de comando (BASE FIXA): 3 andares com terraços jogáveis nas linhas 10, 7 e 4."""
    o = ""
    x0, w = T, 6 * T
    for k, (y, h) in enumerate([(10 * T, 3 * T), (7 * T, 3 * T), (4 * T, 3 * T)]):
        ww = w - k * 30
        xx = x0 + k * 15
        o += R(xx, y, ww, h, "#eef0f4", 4, 2.0, dark="#c9ccd6")
        o += R(xx - 16, y - 12, ww + 32, 18, "#cfd3da", 3, 1.2)
        for j in range(4 - k):
            o += R(xx + 30 + j * 86, y + 46, 60, 40, "#5a6f8f", 4, 1.0) + f'<rect x="{xx + 34 + j * 86}" y="{y + 50}" width="20" height="10" fill="#9fc0dc"/>'
    o += R(x0 + 140, 2 * T, 14, 2 * T, "#8a8f9a", 2, 1.0) + R(x0 + 100, 2 * T + 10, 94, 10, "#8a8f9a", 2, 1.0)
    o += E(x0 + 147, 2 * T - 6, 18, 8, "#cfd3da", 1.0) + f'<circle cx="{x0 + 147}" cy="{2 * T - 18}" r="6" fill="#ff6b6b"/>'
    o += sign(x0 + 40, 10 * T + 8, "BOTA-ABAIXO · DESMONTE", 270)
    # bote salva-vidas pendurado (mecanismo: plataforma que balança; o cabo quebra)
    o += f'<path d="M{x0 + w + 20},{7 * T} v70 M{x0 + w + 130},{7 * T} v70" stroke="{INK}" stroke-width="3"/>'
    o += PL([(x0 + w + 4, 8 * T + 6), (x0 + w + 150, 8 * T + 6), (x0 + w + 130, 8 * T + 50), (x0 + w + 24, 8 * T + 50)], "#f08a3d", 1.4)
    o += R(x0 + w - 4, 7 * T - 10, 160, 12, "#8a8f9a", 2, 1.0)
    return o


def c1_carga():
    """Contêineres empilhados sobre as tampas dos porões (QUEBRA). Contêiner = 3×1 tiles."""
    o = ""
    pilhas = [(8, 3, 0), (11, 2, 1), (17, 4, 0), (20, 2, 2), (24, 3, 1)]
    for k, (col, n, dano) in enumerate(pilhas):
        x = col * T
        o += R(x - 10, DECK - 22, 3 * T + 20, 18, "#7a7f8a", 2, 1.2)   # tampa do porão
        o += zebra(x - 10, DECK - 26, 3 * T + 20, 6)
        for j in range(n):
            o += conteiner(x, DECK - 22 - (j + 1) * T, 3 * T, T, CONT[(k * 3 + j) % len(CONT)], dano if j == n - 1 else 0, porta=j % 2 == 0)
    # tampa do porão RACHADA (lugar de abrir o navio)
    o += R(14 * T - 10, DECK - 22, 3 * T + 20, 18, "#7a7f8a", 2, 1.2)
    o += f'<path d="M{14 * T + 40},{DECK - 22} l14,10 l-10,8 M{15 * T + 60},{DECK - 20} l-12,14" stroke="{INK}" stroke-width="4" fill="none"/>'
    o += f'<rect x="{14 * T + 30}" y="{DECK - 6}" width="100" height="8" fill="#1d1d26"/>'
    return o


def c1_guindaste():
    """Guindaste do navio entre as pilhas (QUEBRA) + gancho com contêiner balançando (mecanismo)."""
    x = 15 * T + 20
    o = R(x - 30, DECK - 60, 84, 40, "#d9a53a", 4, 1.4)
    o += R(x, 4 * T, 24, DECK - 60 - 4 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(9):
        y = 4 * T + 20 + k * 52
        o += f'<path d="M{x},{y} l24,30 M{x + 24},{y} l-24,30" stroke="#b07a1e" stroke-width="3"/>'
    o += f'<g transform="rotate(-18 {x + 12} {4 * T})">' + R(x + 12, 4 * T - 10, 420, 20, "#e0a83a", 3, 1.4) + "</g>"
    hx, hy = x + 400, 4 * T - 140
    o += f'<path d="M{hx},{hy + 6} L{hx + 30},{6 * T + 20}" stroke="{INK}" stroke-width="4"/>'
    o += f'<g transform="rotate(8 {hx + 30} {6 * T + 40})">' + conteiner(hx - 60, 6 * T + 26, 3 * T, T - 8, CONT[4]) + "</g>"
    o += f'<path d="M{hx - 70},{6 * T + 60} q-18,0 -26,12 M{hx + 140},{6 * T + 40} q18,0 26,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.8"/>'
    return o


def c1_proa():
    o = R(27 * T, 11 * T - 40, 3 * T + 40, 40, "#cfd3da", 3, 1.2)
    o += E(28 * T, 11 * T - 60, 30, 22, "#5a5f6a", 1.2) + f'<path d="M{28 * T},{11 * T - 60} h60" stroke="#8a8f9a" stroke-width="10"/>'
    o += R(29 * T + 20, 6 * T, 12, 5 * T - 40, "#8a8f9a", 2, 1.0) + f'<circle cx="{29 * T + 26}" cy="{6 * T - 8}" r="10" fill="#fff4c8"/>'
    # onda batendo por cima da proa
    o += S(f"M{W},{11 * T + 20} C{W - 120},{11 * T - 160} {W - 300},{11 * T - 120} {W - 260},{11 * T - 20} C{W - 230},{11 * T + 30} {W - 120},{11 * T + 40} {W},{11 * T + 60} Z",
           "#d6eef8", (W - 310, 11 * T - 170, W, 11 * T + 60), k=1.6, dark="#9fcfe6")
    rnd = random.Random(4)
    for k in range(14):
        o += f'<circle cx="{W - rnd.uniform(60, 360)}" cy="{11 * T - rnd.uniform(0, 200)}" r="{rnd.uniform(4, 12)}" fill="#ffffff" opacity="0.8"/>'
    o += f'<path d="M{W - 300},{DECK - 30} h-140 M{W - 300},{DECK - 50} h-90" stroke="#ffffff" stroke-width="6" stroke-linecap="round" opacity="0.85"/>'
    return o


def c1_atores():
    o = robot("marretao", "pesado_prep", el.COLORS[0], 9 * T + 40, DECK - 22 - 3 * T)
    o += robot("picareta", "rapido", el.COLORS[1], 12 * T + 70, DECK - 22 - 2 * T, flip=True)
    o += robot("chave", "esquiva", el.COLORS[2], 18 * T + 60, DECK - 22 - 4 * T)
    o += robot("britadeira", "pesado_golpe", el.COLORS[3], 22 * T, DECK - 22, flip=True)
    o += f'<path d="M{18 * T},{DECK - 22 - 4 * T - 30} h-50 M{18 * T + 6},{DECK - 22 - 4 * T - 16} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>'
    return o


def c1_frente():
    o = ondas_frente(H - 70, "#2f6f9f", "#9fd0ec", 16, 2)
    rnd = random.Random(9)
    for _ in range(30):
        x = rnd.uniform(1400, W)
        o += f'<path d="M{x},{rnd.uniform(0, H)} l-14,40" stroke="#e6e2f6" stroke-width="2.5" opacity="0.5"/>'
    o += tag(9 * T + 96, DECK - 22 - 3 * T - 130, "CONTÊINERES")
    o += tag(14 * T + 96, DECK + 20, "TAMPA DO PORÃO")
    o += tag(21 * T + 40, 3 * T + 30, "GANCHO")
    o += tag(W - 200, 11 * T - 200, "ONDA")
    o += tag(7 * T + 80, 8 * T - 40, "BOTE")
    o += tag(3 * T + 70, 3 * T + 30, "PONTE (FIXA)")
    return o


def cena1():
    defs = fonte() + rough(seed=31, scale=0.8, freq=0.05) + grad("c1ceu", [(0, "#f7b27a"), (0.45, "#e8988a"), (1, "#6f6aa0")])
    body = c1_ceu() + c1_longe() + c1_navio() + c1_ponte() + c1_guindaste() + c1_carga() + c1_proa() + c1_atores() + c1_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


# =========================================================================================== CENA 2a — DESTROÇOS DO CARGUEIRO
MAR2 = 14 * T + 10      # nível do mar (maré baixa); maré alta sobe até a linha 12


def c2_ceu():
    o = f'<rect width="{W}" height="{H}" fill="url(#c2ceu)"/>'
    for cx, cy, s in [(300, 140, 1.0), (980, 90, 1.3), (1600, 160, 1.1)]:
        for dx, dy, r in [(0, 0, 50), (60, -20, 60), (130, 0, 50)]:
            o += E(cx + dx * s, cy + dy * s, r * s, r * 0.65 * s, "#ffffff", 1.2)
    o += f'<circle cx="1700" cy="230" r="70" fill="#fff6c8" opacity="0.9"/>'
    o += PL([(1300, 640), (1420, 560), (1520, 590), (1640, 640)], "#7aa79a", 1.2) + PL([(1440, 560), (1460, 470), (1480, 560)], "#5f8a6a", 1.0)
    o += f'<rect x="0" y="640" width="{W}" height="{H}" fill="#5fc4c0"/><rect x="0" y="640" width="{W}" height="10" fill="#ffffff" opacity="0.4"/>'
    # a outra metade do navio afundando no horizonte
    o += PL([(560, 640), (720, 600), (740, 640)], "#7a5a52", 1.2) + R(690, 560, 16, 44, "#7a5a52", 2, 1.0)
    rnd = random.Random(12)
    for k in range(5):
        x, y = 700 + k * 120 + rnd.uniform(-30, 30), 260 + rnd.uniform(-60, 60)
        o += f'<path d="M{x},{y} q10,-10 20,0 q10,-10 20,0" stroke="{INK}" stroke-width="3" fill="none"/>'
    return o


def c2_balsa():
    """Balsa-guindaste da equipe Bota-Abaixo (identidade da obra) ancorada ao fundo; o gancho segura um contêiner
    que balança sobre a quebra do casco (plataforma alta, mecanismo)."""
    bx = 1380
    o = R(bx, MAR2 - 40, 360, 50, "#4a5468", 3, 1.6, dark="#353d4e") + zebra(bx, MAR2 - 46, 360, 8)
    o += R(bx + 250, 2 * T, 26, MAR2 - 40 - 2 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(13):
        y = 2 * T + 20 + k * 52
        o += f'<path d="M{bx + 250},{y} l26,30 M{bx + 276},{y} l-26,30" stroke="#b07a1e" stroke-width="3"/>'
    o += R(bx - 380, 2 * T - 14, 680, 20, "#e0a83a", 3, 1.4) + R(bx + 230, 2 * T - 60, 70, 46, "#cfd3da", 3, 1.2)
    o += f'<path d="M{bx - 330},{2 * T + 6} L{bx - 320},{5 * T - 10}" stroke="{INK}" stroke-width="4"/>'
    o += f'<g transform="rotate(-6 {bx - 320} {5 * T})">' + conteiner(bx - 420, 5 * T - 10, 3 * T, T - 6, CONT[6], 0, True) + "</g>"
    o += f'<path d="M{bx - 440},{5 * T + 20} q-16,0 -24,12 M{bx - 210},{5 * T} q16,0 24,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    o += sign(bx + 180, 5 * T + 20, "BOTA-ABAIXO", 170)
    return o


def c2_ilheu():
    """Rochas do ilhéu (BASE FIXA) à esquerda e pilar de rocha à direita."""
    o = PL([(-40, H), (-40, 12 * T), (90, 11 * T + 20), (3 * T, 9 * T), (5 * T, 9 * T - 20), (7 * T, 10 * T + 10), (9 * T, 12 * T), (10 * T, H)],
           "#8a8f99", 2.6, dark="#6b7079")
    o += PL([(3 * T - 10, 9 * T), (5 * T + 20, 9 * T - 20), (5 * T + 10, 9 * T + 20), (3 * T, 9 * T + 24)], "#a2a7b0", 1.4)   # topo plano jogável
    o += PL([(25 * T, H), (25 * T + 20, 11 * T), (26 * T + 40, 10 * T), (28 * T, 10 * T + 10), (28 * T + 30, H)], "#8a8f99", 2.4, dark="#6b7079")
    # coqueiro torto + farolete no ilhéu
    o += f'<path d="M{2 * T},{11 * T + 30} q-30,-140 40,-260" stroke="#8a6b4f" stroke-width="18" fill="none"/>'
    for a in range(5):
        ang = -2.6 + a * 0.45
        o += f'<path d="M{2 * T + 40},{6 * T + 20} q{math.cos(ang) * 60},{math.sin(ang) * 30 - 30} {math.cos(ang) * 120},{math.sin(ang) * 60 + 20}" stroke="#4f9a52" stroke-width="16" fill="none" stroke-linecap="round"/>'
    o += R(4 * T + 30, 7 * T + 10, 30, 2 * T - 30, "#eef0f4", 3, 1.2) + R(4 * T + 24, 7 * T - 20, 42, 30, "#d14b4b", 3, 1.0) + f'<circle cx="{4 * T + 45}" cy="{7 * T - 30}" r="10" fill="#fff4c8"/>'
    o += sign(80, 11 * T + 30, "ÁREA DE DESMONTE", 210)
    return o


def c2_casco():
    """Metade da proa tombada sobre as rochas: convés vira RAMPA (linha 12 → 8); interior aberto com andares."""
    o = ""
    ang = -14
    cx, cy = 13 * T, 11 * T
    o += f'<g transform="rotate({ang} {cx} {cy})">'
    o += PL([(8 * T, 10 * T), (19 * T, 10 * T), (19 * T + 30, 10 * T + 60), (18 * T + 40, 10 * T + 110), (19 * T + 20, 10 * T + 160),
             (18 * T + 60, 13 * T + 40), (9 * T, 13 * T + 40)], FERR, 2.4, dark=FERR_D)
    o += R(8 * T - 10, 10 * T - 14, 11 * T + 20, 18, "#6b6f7a", 2, 1.4)
    for x in range(8 * T, 19 * T, 48):
        o += f'<path d="M{x},{10 * T - 14} v-36" stroke="#e9e2d2" stroke-width="4"/>'
    o += f'<path d="M{8 * T},{10 * T - 50} H{19 * T}" stroke="#e9e2d2" stroke-width="4"/>'
    for k in range(6):
        o += E(9 * T + 30 + k * 130, 11 * T + 30, 13, 13, "#3a3f4a", 1.0)
    # interior aberto na quebra: dois andares de corredor (plataformas dentro do casco)
    o += R(17 * T, 10 * T + 30, 2 * T - 10, 3 * T, "#3a2f33", 2, 1.2)
    o += R(17 * T, 11 * T + 20, 2 * T, 12, "#8a8f9a", 2, 1.0) + R(17 * T, 12 * T + 30, 2 * T, 12, "#8a8f9a", 2, 1.0)
    o += f'<path d="M{19 * T},{10 * T + 10} l18,20 l-14,16 l20,22 l-16,18 l22,20" stroke="{INK}" stroke-width="4" fill="none"/>'
    o += zebra(17 * T, 10 * T - 30, 2 * T, 10)
    # mastro do navio de pé no casco, com o cesto da gávea (plataforma alta, QUEBRA)
    o += R(14 * T, 4 * T, 18, 6 * T - 14, "#9a9aa8", 3, 1.4, dark="#6b6b7a")
    o += R(13 * T, 5 * T, 2 * T + 20, 16, "#9a9aa8", 3, 1.2)
    o += PL([(13 * T - 10, 4 * T), (15 * T + 30, 4 * T), (15 * T + 10, 4 * T + 40), (13 * T + 10, 4 * T + 40)], "#8a6b4f", 1.4)
    o += f'<path d="M{14 * T + 9},{4 * T} L{9 * T},{10 * T - 14} M{14 * T + 9},{4 * T} L{18 * T},{10 * T - 14}" stroke="#c9a46a" stroke-width="3"/>'
    o += "</g>"
    return o


def c2_resto():
    o = ""
    # mastro caído como ponte: da quebra do casco até o pilar de rocha
    o += f'<g transform="rotate(4 {19 * T} {8 * T})">' + R(19 * T, 8 * T, 7 * T + 30, 18, "#9a9aa8", 3, 1.4, dark="#6b6b7a") + "</g>"
    for k in range(3):
        o += f'<path d="M{20 * T + k * 120},{8 * T + 26 + k * 6} q10,40 -4,70" stroke="#c9a46a" stroke-width="4" fill="none"/>'
    # contêineres boiando (plataformas que balançam com a maré) e encalhado
    o += f'<g transform="rotate(6 {21 * T} {MAR2})">' + conteiner(20 * T, MAR2 - T + 10, 3 * T, T, CONT[1], 1) + "</g>"
    o += f'<g transform="rotate(-8 {23 * T} {MAR2})">' + conteiner(22 * T + 40, MAR2 - T + 20, 2 * T + 20, T, CONT[3], 0, True) + "</g>"
    o += f'<g transform="rotate(12 {27 * T} {10 * T})">' + conteiner(26 * T - 20, 10 * T - T + 6, 3 * T, T, CONT[0], 2) + "</g>"
    o += conteiner(10, 11 * T + 24 - T, 3 * T, T, CONT[2], 0, True)
    # popa saindo d'água ao fundo direito (hélice)
    o += PL([(28 * T + 10, MAR2), (28 * T + 30, 9 * T), (W + 20, 8 * T + 30), (W + 20, MAR2)], FERR_D, 1.8)
    o += E(29 * T + 40, 11 * T, 26, 46, "#c9a46a", 1.2) + E(29 * T + 40, 11 * T, 8, 8, "#8a6b4f", 0.8)
    # destroços boiando
    for x, cor in [(860, "#c98a4b"), (1500, "#f08a3d"), (1180, "#c98a4b")]:
        o += R(x, MAR2 + 20, 70, 14, cor, 3, 1.0)
    o += E(1580, MAR2 + 40, 26, 12, "#ffffff", 1.0) + E(1580, MAR2 + 40, 14, 6, "#d14b4b", 0.8)
    # caranguejos (vida)
    for x in (3 * T + 20, 26 * T + 20):
        y = 9 * T - 10 if x < 600 else 10 * T - 6
        o += E(x, y, 12, 8, "#e06a4a", 0.8) + f'<path d="M{x - 12},{y} l-8,-8 M{x + 12},{y} l8,-8" stroke="#e06a4a" stroke-width="3"/>'
    return o


def c2_atores():
    o = robot("pa", "pesado_prep", el.COLORS[4], 3 * T + 20, 9 * T - 6, s=0.8)
    mx, my = rot_pt(12 * T, 10 * T - 14, 13 * T, 11 * T, -14)
    o += robot("marretao", "rapido", el.COLORS[0], mx, my, s=0.8, rot=-14)
    o += robot("chave", "esquiva", el.COLORS[2], 22 * T + 20, 8 * T + 22, s=0.8, flip=True)
    o += robot("britadeira", "parado", el.COLORS[3], 21 * T + 40, MAR2 - T + 6, s=0.8)
    return o


def c2_frente():
    o = f'<rect x="0" y="{MAR2}" width="{W}" height="{H - MAR2}" fill="#3fa7a0" opacity="0.88"/>'
    o += f'<path d="M0,{12 * T} H{W}" stroke="#ffffff" stroke-width="3" stroke-dasharray="16 12" opacity="0.8"/>'
    o += f'<text x="{W - 30}" y="{12 * T - 10}" font-family="Fredoka" font-weight="700" font-size="18" fill="#ffffff" text-anchor="end">maré alta</text>'
    rnd = random.Random(6)
    for k in range(16):
        x = rnd.uniform(0, W)
        o += f'<path d="M{x},{MAR2 + 30 + rnd.uniform(0, 120)} q16,-6 32,0" stroke="#bff0ea" stroke-width="4" fill="none" opacity="0.8"/>'
    o += f'<path d="M0,{MAR2} ' + "".join("q30,-10 60,0 " for _ in range(33)) + '" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.9"/>'
    o += tag(4 * T, 6 * T + 10, "ROCHAS (FIXAS)") + tag(13 * T, 7 * T + 30, "CASCO TOMBADO")
    o += tag(23 * T, 7 * T + 20, "MASTRO-PONTE") + tag(12 * T + 20, 3 * T + 30, "GÁVEA") + tag(1060, 4 * T - 20, "CONTÊINER NO GANCHO") + tag(21 * T + 60, MAR2 + 70, "CONTÊINER BOIANDO") + tag(W - 160, 12 * T + 40, "MARÉ")
    return o


def cena2a():
    defs = fonte() + rough(seed=33, scale=0.8, freq=0.05) + grad("c2ceu", [(0, "#9fdaf0"), (1, "#f4ecd2")])
    body = c2_ceu() + c2_balsa() + c2_ilheu() + c2_casco() + c2_resto() + c2_atores() + c2_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


# =========================================================================================== CENA 2b — ATLÂNTIDA
CHAO3 = 14 * T
MARM, MARM_D, OURO = "#ece3cf", "#c9bda2", "#e6b84a"


def c3_agua():
    o = f'<rect width="{W}" height="{H}" fill="url(#c3agua)"/>'
    for k in range(7):
        x = 120 + k * 270
        o += f'<path d="M{x},0 L{x + 90},0 L{x + 260},{H} L{x + 60},{H} Z" fill="#ffffff" opacity="0.06"/>'
    # cidade distante (silhuetas de torres e arcos)
    for x, w, h in [(40, 120, 300), (200, 90, 220), (1640, 110, 280), (1790, 120, 200)]:
        o += R(x, CHAO3 - h, w, h, "#2f7f95", 4, 1.2) + E(x + w / 2, CHAO3 - h, w / 2, 40, "#2f7f95", 1.0)
    rnd = random.Random(21)
    for k in range(3):   # cardumes
        cx, cy = rnd.uniform(200, 1700), rnd.uniform(80, 300)
        for j in range(9):
            fx, fy = cx + j * 22 + rnd.uniform(-8, 8), cy + rnd.uniform(-20, 20)
            o += f'<path d="M{fx},{fy} q10,-6 20,0 q-10,6 -20,0 Z M{fx + 20},{fy} l8,-5 v10 Z" fill="#9fe0e8" opacity="0.8"/>'
    return o


def c3_templo():
    o = ""
    # ESCADARIAS (BASE FIXA): plataforma de mármore em degraus
    o += R(-20, CHAO3, W + 40, H - CHAO3, "#d9c48f", 0, 2.4, dark="#b9a46f")
    o += R(2 * T, CHAO3 - 30, 26 * T, 30, MARM_D, 2, 1.6) + R(3 * T, CHAO3 - 56, 24 * T, 28, MARM, 2, 1.6)
    # muralhas laterais (FIXAS) com arcos
    for x in (2 * T, 25 * T):
        o += R(x, 7 * T, 3 * T, CHAO3 - 56 - 7 * T, MARM_D, 4, 2.0, dark="#a89c82")
        o += f'<path d="M{x + 40},{CHAO3 - 56} v-120 a56,56 0 0 1 112,0 v120 Z" fill="#1f5f78" opacity="0.8"/>'
        o += R(x - 10, 7 * T - 18, 3 * T + 20, 22, MARM, 3, 1.2)
    # COLUNAS (QUEBRA) + FRONTÃO (QUEBRA, plataforma) do templo central
    for k in range(6):
        cx = 8 * T + k * 2 * T + 30
        o += R(cx, 7 * T + 20, 40, CHAO3 - 56 - 7 * T - 20, MARM, 3, 1.8, dark=MARM_D)
        for j in range(4):
            o += f'<path d="M{cx + 8 + j * 8},{7 * T + 30} V{CHAO3 - 66}" stroke="{MARM_D}" stroke-width="2"/>'
        o += R(cx - 10, 7 * T + 4, 60, 18, MARM_D, 2, 1.0) + R(cx - 10, CHAO3 - 74, 60, 18, MARM_D, 2, 1.0)
    o += R(7 * T, 6 * T + 20, 16 * T, 40, MARM_D, 3, 1.8)
    o += PL([(7 * T - 20, 6 * T + 20), (15 * T, 3 * T + 30), (23 * T + 20, 6 * T + 20)], MARM, 2.0, dark=MARM_D)
    o += E(15 * T, 5 * T + 10, 34, 34, OURO, 1.2) + f'<path d="M{15 * T - 18},{5 * T + 10} h36 M{15 * T},{5 * T - 8} v36" stroke="#a87a2a" stroke-width="5"/>'
    # coluna rachada (já sendo quebrada)
    o += f'<path d="M{12 * T + 40},{9 * T} l18,20 l-14,16 l16,22" stroke="{INK}" stroke-width="4" fill="none"/>'
    # PASSARELAS de mármore (QUEBRA) nas laterais, linha 10
    o += R(5 * T, 10 * T, 3 * T, 18, MARM, 2, 1.4) + R(22 * T, 10 * T, 3 * T, 18, MARM, 2, 1.4)
    # estátuas de tritão sobre pedestais (QUEBRA)
    for x in (5 * T + 40, 23 * T + 40):
        o += R(x - 30, CHAO3 - 56 - 60, 60, 60, MARM_D, 3, 1.2)
        o += E(x, CHAO3 - 56 - 110, 22, 44, "#9fb8a8", 1.2) + E(x, CHAO3 - 56 - 168, 16, 16, "#9fb8a8", 1.0)
        o += f'<path d="M{x + 18},{CHAO3 - 56 - 190} v-50 M{x + 8},{CHAO3 - 56 - 236} h20" stroke="{OURO}" stroke-width="5"/>'
    # concha-trampolim (mecanismo) no chão à esquerda
    o += E(4 * T, CHAO3 - 70, 50, 20, "#f2a7c3", 1.2) + f'<path d="M{4 * T - 50},{CHAO3 - 74} a50,40 0 0 1 100,-30" fill="#f7c6d8" stroke="#d1708f" stroke-width="4"/>'
    o += E(4 * T, CHAO3 - 74, 10, 8, "#ffffff", 0.8)
    return o


def c3_navio_caido():
    o = ""
    # mastro do navio atravessado: do canto de cima até o frontão (rampa/viga, QUEBRA)
    o += f'<g transform="rotate(28 {2 * T} {1 * T})">' + R(2 * T, T, 12 * T, 24, "#9a9aa8", 3, 1.6, dark="#6b6b7a") + "</g>"
    # contêiner caído sobre o frontão + pedaço de casco no alto direito
    o += f'<g transform="rotate(-12 {18 * T} {3 * T})">' + conteiner(16 * T + 30, 3 * T - 20, 3 * T, T, CONT[3], 2) + "</g>"
    o += PL([(24 * T, 0), (W + 20, 0), (W + 20, 3 * T), (26 * T, 2 * T + 20)], FERR_D, 1.8)
    o += f'<path d="M{26 * T},{2 * T + 20} l20,20 l-10,16 l18,14" stroke="{INK}" stroke-width="4" fill="none"/>'
    return o


def c3_cupula():
    """Cúpula de AR sobre o templo; o lado direito rachou e está ALAGANDO até a linha 11."""
    cx, base, rx, ry = 15 * T, CHAO3 - 56, 13 * T + 20, 12 * T + 30
    o = f'<path d="M{cx - rx},{base} A{rx},{ry} 0 0 1 {cx + rx},{base} Z" fill="#dff7fb" opacity="0.18"/>'
    o += f'<path d="M{cx - rx},{base} A{rx},{ry} 0 0 1 {cx + rx},{base}" fill="none" stroke="#ffffff" stroke-width="6" opacity="0.85"/>'
    for k in range(1, 6):
        a = math.pi * k / 6
        o += f'<path d="M{cx - math.cos(a) * rx},{base - math.sin(a) * ry} L{cx - math.cos(a) * rx * 0.98},{base}" stroke="#ffffff" stroke-width="2" opacity="0.35"/>'
    # rachadura e vazamento no lado direito
    px, py = cx + math.cos(0.75) * rx, base - math.sin(0.75) * ry
    o += f'<path d="M{px},{py} l-20,26 l16,14 l-24,30 M{px},{py} l26,10" stroke="#ffffff" stroke-width="5" fill="none"/>'
    o += f'<path d="M{px - 10},{py + 20} C{px - 40},{py + 120} {px - 20},{py + 220} {px - 60},{11 * T}" stroke="#7fd6e6" stroke-width="22" fill="none" opacity="0.7"/>'
    o += f'<rect x="{18 * T}" y="{11 * T}" width="{9 * T}" height="{base - 11 * T}" fill="#3fc6dc" opacity="0.45"/>'
    o += f'<path d="M{18 * T},{11 * T} q20,-8 40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0" stroke="#ffffff" stroke-width="4" fill="none"/>'
    rnd = random.Random(17)
    for _ in range(18):
        o += f'<circle cx="{rnd.uniform(18 * T, 27 * T)}" cy="{rnd.uniform(11 * T, base)}" r="{rnd.uniform(3, 9)}" fill="none" stroke="#ffffff" stroke-width="2.5" opacity="0.8"/>'
    return o


def c3_grua():
    """Grua submarina da equipe (identidade da obra), presa no chão do mar à direita."""
    x = 28 * T + 20
    o = R(x - 20, CHAO3 - 30, 70, 30, "#6b5a3a", 3, 1.2)
    o += R(x, 3 * T, 22, CHAO3 - 30 - 3 * T, "#e0a83a", 3, 1.4, dark="#b07a1e")
    for k in range(12):
        y = 3 * T + 20 + k * 52
        o += f'<path d="M{x},{y} l22,30 M{x + 22},{y} l-22,30" stroke="#b07a1e" stroke-width="3"/>'
    o += R(x - 200, 3 * T - 14, 260, 18, "#e0a83a", 3, 1.2) + f'<circle cx="{x + 10}" cy="{3 * T - 30}" r="12" fill="#fff4c8"/>'
    o += f'<path d="M{x + 10},{3 * T - 30} L{x - 120},{3 * T + 200} L{x + 80},{3 * T + 200} Z" fill="#fff4c8" opacity="0.12"/>'
    o += f'<rect x="{x - 300}" y="{CHAO3 - 50}" width="180" height="40" rx="6" fill="{YEL}"/><text x="{x - 210}" y="{CHAO3 - 23}" font-family="Fredoka" font-weight="700" font-size="17" fill="{INK}" text-anchor="middle">OBRA SUBMARINA</text>'
    return o


def c3_atores():
    o = robot("marretao", "pesado_golpe", el.COLORS[0], 12 * T + 10, CHAO3 - 56)
    o += robot("picareta", "parado", el.COLORS[1], 10 * T, 6 * T + 20)
    o += robot("chave", "esquiva", el.COLORS[2], 22 * T + 60, 10 * T, flip=True)
    o += robot("pa", "rapido", el.COLORS[4], 20 * T, CHAO3 - 56 - 20, s=0.8, flip=True, rot=-10)   # na parte alagada: flutuando
    o += f'<path d="M{20 * T - 30},{CHAO3 - 60} q-10,-30 6,-60" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.8"/>'
    return o


def c3_frente():
    o = ""
    o += f'<path d="M640,{H - 60} v-90 M600,{H - 120} h80 M610,{H - 60} q30,30 60,0" stroke="#5a5f6a" stroke-width="10" fill="none" stroke-linecap="round"/>'   # âncora do navio
    for x, cor in [(320, "#e06a8a"), (1300, "#f2a33a"), (1500, "#e06a8a")]:
        for j in range(3):
            o += f'<path d="M{x + j * 14},{H - 40} q-6,-40 {6 - j * 4},-70" stroke="{cor}" stroke-width="10" fill="none" stroke-linecap="round"/>'
    for x in (460, 1100, 1700):
        o += E(x, H - 50, 40, 18, "#b9a46f", 1.2)
    o += conteiner(1150, H - 110, 3 * T, T, CONT[1], 1)
    rnd = random.Random(23)
    for x in (40, 160, 1760, 1860):   # algas no primeiro plano
        o += f'<path d="M{x},{H} q-30,-120 10,-240 q30,-90 -10,-180" stroke="#2f8a5a" stroke-width="22" fill="none" stroke-linecap="round" opacity="0.9"/>'
    for _ in range(26):
        o += f'<circle cx="{rnd.uniform(0, W)}" cy="{rnd.uniform(0, H)}" r="{rnd.uniform(3, 10)}" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.6"/>'
    o += tag(15 * T, 3 * T, "FRONTÃO") + tag(9 * T + 20, 12 * T + 10, "COLUNAS")
    o += tag(17 * T + 60, 2 * T - 30, "PEDAÇO DO NAVIO") + tag(6 * T, 2 * T + 60, "MASTRO CAÍDO")
    o += tag(22 * T + 50, 12 * T + 40, "ALAGANDO") + tag(4 * T, CHAO3 - 130, "CONCHA") + tag(15 * T, CHAO3 + 60, "ESCADARIAS (FIXAS)")
    o += tag(23 * T, 0 * T + 40, "CÚPULA RACHOU")
    return o


def cena2b():
    defs = fonte() + rough(seed=35, scale=0.8, freq=0.05) + grad("c3agua", [(0, "#4fc0d0"), (0.6, "#1f7f9a"), (1, "#0f4f6f")])
    body = c3_agua() + c3_templo() + c3_grua() + c3_cupula() + c3_navio_caido() + c3_atores() + c3_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


def main():
    os.makedirs(SRC, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    queue(cena1(), f"{SRC}/cena1.svg", os.path.join(OUT, "cena1_conves.png"), W, H, 1)
    queue(cena2a(), f"{SRC}/cena2a.svg", os.path.join(OUT, "cena2a_destrocos.png"), W, H, 1)
    queue(cena2b(), f"{SRC}/cena2b.svg", os.path.join(OUT, "cena2b_atlantida.png"), W, H, 1)
    print("fotografias fase 2:", render_all())


if __name__ == "__main__":
    main()
