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


MAR1 = 15 * T          # superfície do mar: abaixo disto é KO em toda a largura


def c1_navio_fundo():
    """O CARGUEIRO É MOLDURA (não se pisa): costado grande e apagado atrás do palco, com a ponte e a carga lá em cima."""
    o = ""
    # carga no convés lá atrás (silhuetas)
    rnd = random.Random(14)
    x = 420
    while x < W:
        n = rnd.randint(2, 4)
        for j in range(n):
            o += R(x, 290 - (j + 1) * 42, 150, 42, shade(CONT[rnd.randint(0, len(CONT) - 1)], -0.15), 2, 1.2)
        x += 156
    # ponte de comando lá atrás (esquerda)
    o += R(60, 40, 300, 250, "#d9dce4", 4, 1.6, dark="#b9bcc6")
    for r in range(3):
        for c in range(3):
            o += R(90 + c * 92, 62 + r * 74, 60, 36, "#6a7a96", 3, 1.0)
    o += R(190, 0, 12, 40, "#8a8f9a", 2, 1.0)
    # costado
    o += R(-40, 290, W + 80, MAR1 - 290 + 30, "#a5523d", 0, 2.4, dark="#7e3a2b")
    o += R(-40, 282, W + 80, 16, "#7a7f8a", 0, 1.2)
    for k in range(9):   # chapas do casco e ferrugem escorrendo
        o += f'<path d="M{-40 + k * 240},{300} V{MAR1}" stroke="#8e4533" stroke-width="3" opacity="0.7"/>'
    for k in range(3):
        o += f'<path d="M-40,{420 + k * 150} H{W + 40}" stroke="#8e4533" stroke-width="3" opacity="0.6"/>'
    rnd2 = random.Random(31)
    for k in range(18):
        x = rnd2.uniform(0, W)
        y = rnd2.uniform(320, 700)
        o += f'<path d="M{x},{y} q4,40 -2,{rnd2.uniform(50, 120)}" stroke="#7a3424" stroke-width="{rnd2.uniform(3, 7):.1f}" fill="none" opacity="0.55"/>'
    for k in range(15):
        o += E(70 + k * 130, 360, 14, 14, "#4a3f44", 1.0)
    o += E(1700, 400, 46, 30, "#5a3a32", 1.2) + f'<path d="M1700,430 v120 M1670,520 h60 M1675,550 q25,25 50,0" stroke="#5a5f6a" stroke-width="9" fill="none"/>'   # escovém + âncora
    o += f'<rect x="-40" y="{MAR1 - 70}" width="{W + 80}" height="22" fill="#e9e2d2" opacity="0.7"/>'
    o += f'<text x="{W / 2}" y="600" font-family="Fredoka" font-weight="700" font-size="64" fill="#e9e2d2" text-anchor="middle" opacity="0.55">ESTRELA DO SUL</text>'
    # turcos (braços) do bote presos no costado
    o += f'<path d="M150,290 q0,-40 90,-60 M330,290 q0,-40 -60,-60" stroke="#8a8f9a" stroke-width="10" fill="none"/>'
    # névoa: empurra o navio para trás
    o += f'<rect x="0" y="0" width="{W}" height="{MAR1}" fill="#f2b892" opacity="0.28"/>'
    return o


def andaime(x, y_top, y_bot):
    """Torre de andaime laranja (FIXA): dois montantes + travessas."""
    o = ""
    for dx in (0, 52):
        o += R(x + dx, y_top, 12, y_bot - y_top, "#f08a3d", 2, 1.2, dark="#c06a2a")
    yy = y_top
    while yy < y_bot - 40:
        o += f'<path d="M{x + 6},{yy} L{x + 58},{yy + 64} M{x + 58},{yy} L{x + 6},{yy + 64}" stroke="#c06a2a" stroke-width="4"/>'
        o += R(x, yy, 64, 8, "#f08a3d", 2, 0.8)
        yy += 64
    return o


def tabua(x, y, w):
    """Tábua de andaime (QUEBRA)."""
    o = R(x, y, w, 18, "#c98a4b", 2, 1.4, dark="#9a6a3a")
    for k in range(int(w / 64)):
        o += f'<path d="M{x + 32 + k * 64},{y + 3} v12" stroke="#9a6a3a" stroke-width="3"/>'
    return o


def balsa(x, w):
    """Balsa da equipe (FIXA) boiando: convés de aço no nível 13, flutuadores na água."""
    o = R(x, 13 * T, w, 26, "#4a5468", 3, 1.6, dark="#353d4e") + zebra(x, 13 * T - 8, w, 8)
    o += R(x + 20, 13 * T + 26, w - 40, MAR1 - 13 * T, "#353d4e", 3, 1.4)
    for k in range(int(w / 90)):
        o += E(x + 50 + k * 90, MAR1 + 6, 30, 14, "#f2c84b", 1.0)
    return o


def c1_palco():
    o = ""
    # --- FIXO: balsas nas pontas, pilar de atracação no meio, torres de andaime, torre da grua
    o += balsa(70, 6 * T) + balsa(22 * T, 7 * T)
    o += R(14 * T, 11 * T + 20, 2 * T, MAR1 - 11 * T, "#9a9488", 4, 2.0, dark="#7a7468")       # pilar de concreto
    o += R(13 * T - 10, 11 * T, 4 * T + 20, 28, "#b9b2a4", 3, 1.6) + zebra(13 * T - 10, 11 * T - 8, 4 * T + 20, 8)
    for k in range(3):
        o += E(13 * T + 20 + k * 100, 11 * T + 40, 16, 10, "#3a3a44", 0.8)   # pneus de atracação
    o += andaime(7 * T, 4 * T, 13 * T) + andaime(21 * T, 4 * T, 13 * T)
    o += R(28 * T, 1 * T, 26, 12 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")                          # torre da grua da balsa
    for k in range(11):
        y = T + 20 + k * 64
        o += f'<path d="M{28 * T},{y} l26,40 M{28 * T + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(9 * T, 1 * T - 14, 20 * T, 20, "#e0a83a", 3, 1.4) + R(28 * T - 30, 1 * T - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += sign(23 * T, 13 * T - 60, "BOTA-ABAIXO", 170)
    # --- QUEBRA: contêineres separados sobre as balsas e o pilar
    pil = [(70, 3, 0), (3 * T + 70, 2, 1), (22 * T + 30, 2, 0), (25 * T + 40, 3, 2)]
    for k, (x, n, dano) in enumerate(pil):
        for j in range(n):
            o += conteiner(x + 10, 13 * T - (j + 1) * T, 3 * T - 10, T, CONT[(k * 3 + j) % len(CONT)], dano if j == n - 1 else 0, porta=j % 2 == 0)
    o += conteiner(13 * T + 20, 11 * T - T, 3 * T, T, CONT[5], 1)
    # tábuas entre as torres e os contêineres (nível 9) e no alto (nível 6)
    o += tabua(7 * T + 64, 9 * T, 5 * T) + tabua(16 * T + 30, 9 * T, 5 * T - 30)
    o += tabua(3 * T, 6 * T, 4 * T + 64) + tabua(21 * T + 64, 6 * T, 4 * T)
    # contêiner no gancho da grua (balança, nível 6)
    o += f'<path d="M{15 * T},{1 * T + 6} L{15 * T + 20},{5 * T}" stroke="{INK}" stroke-width="4"/>'
    o += f'<g transform="rotate(5 {15 * T + 20} {6 * T})">' + conteiner(13 * T + 40, 5 * T + 10, 3 * T - 20, T - 8, CONT[4], 0, True) + "</g>"
    o += f'<path d="M{13 * T + 20},{6 * T + 10} q-18,0 -26,12 M{16 * T + 50},{6 * T} q18,0 26,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    # viga içada lá no alto (nível 3), pendurada por dois cabos da lança
    o += f'<path d="M{20 * T},{1 * T + 6} L{20 * T + 10},{3 * T} M{25 * T},{1 * T + 6} L{24 * T + 50},{3 * T}" stroke="{INK}" stroke-width="3"/>'
    o += R(19 * T + 40, 3 * T, 5 * T + 40, 22, "#7a808c", 2, 1.4, dark="#5a606c")
    # bote salva-vidas pendurado nos turcos do navio (nível 5)
    o += f'<path d="M240,230 v26 M270,230 v26" stroke="{INK}" stroke-width="3"/>'
    o += PL([(140, 4 * T), (340, 4 * T), (316, 4 * T + 50), (164, 4 * T + 50)], "#f08a3d", 1.4)
    o += R(150, 4 * T - 8, 180, 10, "#d9dce4", 2, 0.8)
    return o


def c1_atores():
    o = robot("marretao", "pesado_prep", el.COLORS[0], 2 * T + 40, 13 * T - 3 * T)
    o += robot("picareta", "rapido", el.COLORS[1], 10 * T + 20, 9 * T, flip=True)
    o += robot("chave", "esquiva", el.COLORS[2], 15 * T + 10, 5 * T - 10)
    o += robot("britadeira", "pesado_golpe", el.COLORS[3], 23 * T + 40, 13 * T - 2 * T, flip=True)
    o += f'<path d="M{15 * T - 60},{5 * T - 40} h-50 M{15 * T - 54},{5 * T - 26} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>'
    return o


def c1_frente():
    o = ondas_frente(MAR1, "#2f6f9f", "#9fd0ec", 16, 2)
    # borrifo de onda subindo no meio (mecanismo: a onda molha e empurra quem está baixo)
    o += S(f"M{11 * T},{MAR1 + 10} C{11 * T + 20},{12 * T} {12 * T + 60},{11 * T + 40} {12 * T + 40},{MAR1}", "#d6eef8", (11 * T, 11 * T + 30, 13 * T, MAR1 + 10), k=1.4)
    rnd = random.Random(9)
    for _ in range(30):
        x = rnd.uniform(1400, W)
        o += f'<path d="M{x},{rnd.uniform(0, H)} l-14,40" stroke="#e6e2f6" stroke-width="2.5" opacity="0.5"/>'
    o += tag(3 * T, 13 * T + 50, "BALSA (FIXA)") + tag(26 * T, 13 * T + 50, "BALSA (FIXA)") + tag(15 * T, 12 * T + 40, "PILAR (FIXO)")
    o += tag(7 * T + 32, 3 * T + 40, "ANDAIME (FIXO)") + tag(4 * T + 40, 9 * T - 30, "CONTÊINERES") + tag(10 * T + 40, 9 * T + 50, "TÁBUAS")
    o += tag(15 * T + 10, 7 * T + 30, "CONTÊINER NO GANCHO") + tag(22 * T + 20, 2 * T + 30, "VIGA IÇADA") + tag(240, 5 * T + 20, "BOTE")
    o += tag(9 * T, MAR1 + 70, "MAR = KO") + tag(21 * T, MAR1 + 70, "MAR = KO") + tag(W / 2, 7 * T - 20 - 2 * T, "") if False else ""
    o += tag(9 * T, MAR1 + 70, "MAR = KO") + tag(21 * T, MAR1 + 70, "MAR = KO") + tag(40, 12 * T, "KO") + tag(W - 34, 12 * T, "KO") + tag(1150, 250, "NAVIO = FUNDO (não se pisa)")
    return o


def cena1():
    defs = fonte() + rough(seed=31, scale=0.8, freq=0.05) + grad("c1ceu", [(0, "#f7b27a"), (0.45, "#e8988a"), (1, "#6f6aa0")]) + grad("c1poro", [(0, "#3a3a48"), (1, "#14141c")])
    body = c1_ceu() + c1_longe() + c1_navio_fundo() + c1_palco() + c1_atores() + c1_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


# =========================================================================================== CENA 2a — DESTROÇOS DO CARGUEIRO
# O navio partido e encalhado é MOLDURA (não se pisa). A luta é sobre o MAR FUNDO (KO em toda a largura), em pontas de
# rocha (FIXAS) e plataformas que quebram: contêineres empilhados/boiando, chapas do casco, mastro-ponte, contêiner no gancho.
MAR2 = 15 * T           # superfície do mar (maré baixa); a maré alta sobe até a linha 13 e molha as plataformas baixas


def c2_ceu():
    o = f'<rect width="{W}" height="{H}" fill="url(#c2ceu)"/>'
    for cx, cy, s in [(300, 110, 1.0), (980, 70, 1.3), (1600, 130, 1.1)]:
        for dx, dy, r in [(0, 0, 50), (60, -20, 60), (130, 0, 50)]:
            o += E(cx + dx * s, cy + dy * s, r * s, r * 0.65 * s, "#ffffff", 1.2)
    o += f'<circle cx="1760" cy="200" r="60" fill="#fff6c8" opacity="0.9"/>'
    o += f'<rect x="0" y="560" width="{W}" height="{H}" fill="#7fd0c8"/>'
    o += PL([(60, 560), (260, 470), (420, 500), (560, 560)], "#8fb59f", 1.2) + R(250, 380, 26, 100, "#eef0f4", 3, 1.0) + R(244, 360, 38, 24, "#d14b4b", 3, 1.0)
    return o


def c2_navio_fundo():
    """Moldura: as duas metades do navio encalhadas no ilhéu, grandes e apagadas (névoa)."""
    o = PL([(380, 640), (980, 600), (1100, 640)], "#9aa0a8", 1.6)   # ilhéu atrás
    # metade da proa tombada (fundo, esquerda/centro)
    o += f'<g transform="rotate(-12 700 420)">' + PL([(300, 300), (1080, 300), (1110, 360), (1060, 420), (1100, 480), (1040, 640), (340, 640)], "#a5523d", 2.4, dark="#7e3a2b")
    o += R(300, 290, 780, 16, "#7a7f8a", 2, 1.2)
    for k in range(6):
        o += E(380 + k * 120, 380, 13, 13, "#4a3f44", 1.0)
    o += f'<path d="M1080,300 l20,30 l-16,20 l22,26 l-18,24 l24,26" stroke="{INK}" stroke-width="4" fill="none"/>' + "</g>"
    # metade da popa com a ponte, emborcada à direita
    o += f'<g transform="rotate(10 1500 420)">' + PL([(1180, 300), (1900, 300), (1960, 640), (1220, 640)], "#a5523d", 2.4, dark="#7e3a2b")
    o += R(1600, 160, 220, 140, "#d9dce4", 4, 1.4) + R(1620, 186, 60, 34, "#6a7a96", 3, 1.0) + R(1720, 186, 60, 34, "#6a7a96", 3, 1.0)
    o += E(1880, 520, 40, 70, "#c9a46a", 1.2) + "</g>"
    o += f'<rect x="0" y="0" width="{W}" height="{MAR2}" fill="#dff1ee" opacity="0.55"/>'   # névoa da manhã (empurra o navio para trás)
    return o


def rocha(x0, x1, topo):
    """Ponta de rocha (FIXA) saindo do mar fundo, com topo plano jogável."""
    pts = [(x0 - 20, H), (x0, topo + 30), (x0 + 30, topo), (x1 - 30, topo), (x1, topo + 30), (x1 + 20, H)]
    o = PL(pts, "#8a8f99", 2.6, dark="#6b7079")
    o += R(x0 + 24, topo - 6, x1 - x0 - 48, 14, "#a2a7b0", 3, 1.0)
    o += f'<path d="M{x0 + 10},{topo + 120} q30,-10 60,6 M{x1 - 80},{topo + 200} q30,-8 50,4" stroke="#6b7079" stroke-width="5" fill="none"/>'
    return o


def c2_palco():
    o = ""
    # FIXO: três pontas de rocha + torre da balsa-guindaste ancorada à direita
    o += rocha(1 * T, 5 * T + 20, 12 * T) + rocha(13 * T, 17 * T, 11 * T) + rocha(24 * T, 28 * T + 20, 12 * T)
    o += R(28 * T - 6, 1 * T, 26, 11 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(10):
        y = T + 20 + k * 64
        o += f'<path d="M{28 * T - 6},{y} l26,40 M{28 * T + 20},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(8 * T, 1 * T - 14, 21 * T, 20, "#e0a83a", 3, 1.4) + R(28 * T - 40, 1 * T - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += sign(24 * T + 30, 12 * T - 60, "BOTA-ABAIXO", 170)
    # QUEBRA: contêineres empilhados nas rochas
    o += conteiner(1 * T + 30, 11 * T, 3 * T, T, CONT[2], 0, True) + conteiner(1 * T + 50, 10 * T, 3 * T - 20, T, CONT[0], 1)
    o += f'<g transform="rotate(-4 {26 * T} {11 * T})">' + conteiner(24 * T + 40, 11 * T, 3 * T, T, CONT[1], 0, True) + "</g>"
    o += conteiner(25 * T, 10 * T, 3 * T - 10, T, CONT[3], 2)
    # QUEBRA: contêineres boiando entre as rochas (balançam com a maré)
    o += f'<g transform="rotate(5 {8 * T} {MAR2})">' + conteiner(6 * T + 30, MAR2 - T + 14, 3 * T, T, CONT[4], 0) + "</g>"
    o += f'<g transform="rotate(-6 {20 * T} {MAR2})">' + conteiner(18 * T + 50, MAR2 - T + 14, 3 * T, T, CONT[6], 1, True) + "</g>"
    # QUEBRA: chapa do casco encravada na rocha do meio (plataforma no nível 8) e outra à direita (nível 7)
    o += f'<g transform="rotate(-6 {15 * T} {8 * T})">' + R(12 * T + 20, 8 * T, 6 * T, 24, "#6b3a30", 2, 1.6, dark="#4a2620") + zebra(12 * T + 20, 8 * T - 6, 6 * T, 7)
    o += f'<path d="M{12 * T + 20},{8 * T + 22} l14,40 M{18 * T + 20},{8 * T + 22} l-10,30" stroke="#7e3a2b" stroke-width="10"/>' + "</g>"
    o += R(14 * T + 10, 8 * T + 30, 18, 3 * T - 30, "#4a2620", 2, 1.0)   # escora retorcida apoiando a chapa na rocha
    o += f'<g transform="rotate(8 {22 * T} {7 * T})">' + R(20 * T + 20, 7 * T, 4 * T + 20, 22, "#6b3a30", 2, 1.4, dark="#4a2620") + zebra(20 * T + 20, 7 * T - 6, 4 * T + 20, 7) + "</g>"
    o += R(23 * T + 30, 7 * T + 30, 16, 3 * T, "#4a2620", 2, 1.0)
    # QUEBRA: mastro caído como ponte (do topo dos contêineres da esquerda até a chapa do meio)
    o += f'<g transform="rotate(-8 {5 * T} {10 * T})">' + R(4 * T + 30, 10 * T - 30, 8 * T, 18, "#9a9aa8", 3, 1.4, dark="#6b6b7a") + "</g>"
    # QUEBRA: contêiner no gancho (nível 5) + tábuas presas no alto da torre (nível 4)
    o += f'<path d="M{10 * T},{1 * T + 6} L{10 * T + 16},{4 * T + 10}" stroke="{INK}" stroke-width="4"/>'
    o += f'<g transform="rotate(-5 {10 * T} {5 * T})">' + conteiner(8 * T + 30, 4 * T + 16, 3 * T, T - 8, CONT[5], 0, True) + "</g>"
    o += f'<path d="M{8 * T + 10},{5 * T + 20} q-16,0 -24,12 M{11 * T + 60},{5 * T} q16,0 24,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    o += tabua(23 * T, 4 * T, 5 * T - 6)
    o += f'<path d="M{23 * T + 20},{1 * T + 6} V{4 * T} M{27 * T + 30},{1 * T + 6} V{4 * T}" stroke="{INK}" stroke-width="3"/>'
    # vida e destroços
    for x in (3 * T, 26 * T + 10):
        y = 10 * T - 4
        o += E(x, y, 12, 8, "#e06a4a", 0.8) + f'<path d="M{x - 12},{y} l-8,-8 M{x + 12},{y} l8,-8" stroke="#e06a4a" stroke-width="3"/>'
    for x, cor in [(11 * T, "#c98a4b"), (22 * T, "#f08a3d")]:
        o += R(x, MAR2 + 18, 70, 14, cor, 3, 1.0)
    return o


def c2_atores():
    o = robot("pa", "pesado_prep", el.COLORS[4], 2 * T + 40, 10 * T)
    o += robot("marretao", "rapido", el.COLORS[0], 14 * T + 20, 8 * T + 6)
    o += robot("chave", "esquiva", el.COLORS[2], 9 * T + 60, 4 * T + 10, flip=True)
    o += robot("britadeira", "parado", el.COLORS[3], 19 * T + 70, MAR2 - T + 10)
    o += f'<path d="M{9 * T},{4 * T - 30} h-50 M{9 * T + 6},{4 * T - 16} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>'
    return o


def c2_frente():
    o = f'<rect x="0" y="{MAR2}" width="{W}" height="{H - MAR2}" fill="#2f8f8a"/>'
    o += f'<rect x="0" y="{MAR2}" width="{W}" height="{H - MAR2}" fill="url(#c2fundo)" opacity="0.7"/>'
    rnd = random.Random(6)
    for k in range(16):
        x = rnd.uniform(0, W)
        o += f'<path d="M{x},{MAR2 + 30 + rnd.uniform(0, 70)} q16,-6 32,0" stroke="#bff0ea" stroke-width="4" fill="none" opacity="0.8"/>'
    o += f'<path d="M0,{MAR2} ' + "".join("q30,-10 60,0 " for _ in range(33)) + '" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.9"/>'
    o += f'<path d="M0,{13 * T} H{W}" stroke="#ffffff" stroke-width="3" stroke-dasharray="16 12" opacity="0.85"/>'
    o += f'<text x="{W - 30}" y="{13 * T - 10}" font-family="Fredoka" font-weight="700" font-size="18" fill="#ffffff" text-anchor="end">maré alta</text>'
    o += tag(3 * T + 10, 13 * T + 20, "ROCHA (FIXA)") + tag(15 * T, 12 * T + 30, "ROCHA (FIXA)") + tag(26 * T + 10, 13 * T + 20, "ROCHA (FIXA)")
    o += tag(3 * T + 20, 11 * T + 30, "CONTÊINERES") + tag(8 * T + 20, 10 * T + 10, "MASTRO-PONTE") + tag(16 * T + 40, 9 * T + 10, "CHAPA DO CASCO")
    o += tag(8 * T + 20, MAR2 - 90, "BOIANDO") + tag(12 * T + 60, 4 * T + 40, "CONTÊINER NO GANCHO") + tag(25 * T + 20, 3 * T + 30, "TÁBUAS")
    o += tag(9 * T, MAR2 + 70, "MAR FUNDO = KO") + tag(21 * T, MAR2 + 70, "MAR FUNDO = KO") + tag(1000, 230, "NAVIO PARTIDO = FUNDO")
    return o


def cena2a():
    defs = fonte() + rough(seed=33, scale=0.8, freq=0.05) + grad("c2ceu", [(0, "#9fdaf0"), (1, "#f4ecd2")]) + grad("c2fundo", [(0, "#2f8f8a"), (1, "#0f3f4f")])
    body = c2_ceu() + c2_navio_fundo() + c2_palco() + c2_atores() + c2_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


# =========================================================================================== CENA 2b — ATLÂNTIDA
# O templo e a cúpula são MOLDURA (não se pisam). A luta é sobre a FENDA ABISSAL (KO embaixo), em topos de pilares (FIXOS)
# e plataformas que quebram: tambores de coluna, lajes de mármore entre colunas, frontão caído e pedaços do navio.
TOPO3 = 12 * T
MARM, MARM_D, OURO = "#ece3cf", "#c9bda2", "#e6b84a"


def c3_agua():
    o = f'<rect width="{W}" height="{H}" fill="url(#c3agua)"/>'
    for k in range(7):
        x = 120 + k * 270
        o += f'<path d="M{x},0 L{x + 90},0 L{x + 260},{H} L{x + 60},{H} Z" fill="#ffffff" opacity="0.06"/>'
    rnd = random.Random(21)
    for k in range(3):
        cx, cy = rnd.uniform(200, 1700), rnd.uniform(60, 260)
        for j in range(9):
            fx, fy = cx + j * 22 + rnd.uniform(-8, 8), cy + rnd.uniform(-20, 20)
            o += f'<path d="M{fx},{fy} q10,-6 20,0 q-10,6 -20,0 Z M{fx + 20},{fy} l8,-5 v10 Z" fill="#9fe0e8" opacity="0.8"/>'
    return o


def c3_templo_fundo():
    """Moldura: a fachada do templo inteira lá atrás, apagada pela água (não se pisa)."""
    o = R(2 * T, 9 * T, 26 * T, 40, "#7fb8c4", 3, 1.6)
    for k in range(10):
        o += R(3 * T + k * 2 * T + 40, 3 * T + 40, 50, 6 * T - 40, "#8ec4cf", 3, 1.6)
    o += R(2 * T, 3 * T, 26 * T, 50, "#7fb8c4", 3, 1.6)
    o += PL([(2 * T - 20, 3 * T), (15 * T, 0), (28 * T + 20, 3 * T)], "#8ec4cf", 1.8)
    o += E(15 * T, 1 * T + 30, 40, 40, "#c9b46a", 1.2)
    for x, w, h in [(0, 110, 400), (1800, 120, 360)]:
        o += R(x, 9 * T - h + 200, w, h, "#3f8fa5", 4, 1.2)
    o += f'<rect x="0" y="0" width="{W}" height="{H}" fill="#2f8fa8" opacity="0.35"/>'
    return o


def pilar_fixo(x0, x1):
    """Topo de pilar (FIXO): plinto de mármore sobre um pico de rocha que desce para a fenda."""
    o = PL([(x0 + 20, TOPO3 + 40), (x1 - 20, TOPO3 + 40), (x1 - 60, H + 10), (x0 + 60, H + 10)], "#4a5a6a", 2.4, dark="#34404c")
    o += R(x0, TOPO3, x1 - x0, 44, MARM_D, 3, 1.8, dark="#a89c82") + R(x0 + 10, TOPO3 - 14, x1 - x0 - 20, 18, MARM, 3, 1.2)
    return o


def coluna(x, y_top, y_bot, rachada=False):
    o = R(x, y_top, 40, y_bot - y_top, MARM, 3, 1.6, dark=MARM_D)
    for j in range(4):
        o += f'<path d="M{x + 8 + j * 8},{y_top + 10} V{y_bot - 10}" stroke="{MARM_D}" stroke-width="2"/>'
    o += R(x - 10, y_top - 14, 60, 16, MARM_D, 2, 1.0)
    if rachada:
        o += f'<path d="M{x + 10},{(y_top + y_bot) / 2} l16,18 l-12,14 l14,18" stroke="{INK}" stroke-width="4" fill="none"/>'
    return o


def tambores(x, y_base, n):
    """Tambores de coluna empilhados (QUEBRA)."""
    o = ""
    for j in range(n):
        y = y_base - (j + 1) * 52
        o += R(x, y, 96, 50, MARM if j % 2 == 0 else "#e4dac4", 6, 1.4, dark=MARM_D)
        for k in range(5):
            o += f'<path d="M{x + 14 + k * 17},{y + 6} v38" stroke="{MARM_D}" stroke-width="2"/>'
    return o


def laje(x, y, w):
    """Laje de mármore (QUEBRA) apoiada em colunas."""
    return R(x, y, w, 30, MARM, 3, 1.6, dark=MARM_D) + f'<rect x="{x}" y="{y + 24}" width="{w}" height="6" fill="{MARM_D}"/>'


def c3_palco():
    o = ""
    # FIXO: três topos de pilar sobre a fenda
    o += pilar_fixo(1 * T, 6 * T) + pilar_fixo(12 * T, 18 * T) + pilar_fixo(24 * T, 29 * T)
    # QUEBRA: pilar central — duas colunas seguram uma laje (nível 8); sobre ela, colunas curtas e o FRONTÃO caído (nível 5)
    o += coluna(12 * T + 40, 8 * T + 30, TOPO3 - 14, rachada=True) + coluna(17 * T - 80, 8 * T + 30, TOPO3 - 14)
    o += laje(11 * T, 8 * T, 8 * T)
    o += coluna(13 * T + 20, 5 * T + 40, 8 * T) + coluna(16 * T + 20, 5 * T + 40, 8 * T)
    o += f'<g transform="rotate(-4 {15 * T} {5 * T})">' + PL([(12 * T, 5 * T + 40), (15 * T, 3 * T + 40), (18 * T + 20, 5 * T + 40)], MARM, 1.8, dark=MARM_D)
    o += R(12 * T, 5 * T + 40, 6 * T + 20, 18, MARM_D, 2, 1.0) + E(15 * T, 4 * T + 50, 24, 24, OURO, 1.0) + "</g>"
    # QUEBRA: esquerda — tambores empilhados + estátua de tritão; laje-ponte para o centro (nível 9)
    o += tambores(1 * T + 30, TOPO3 - 14, 2) + tambores(3 * T + 40, TOPO3 - 14, 3)
    o += coluna(5 * T + 10, 9 * T + 30, TOPO3 - 14) + laje(4 * T + 40, 9 * T, 6 * T + 40)
    o += R(2 * T, TOPO3 - 14 - 104 - 60, 60, 60, MARM_D, 3, 1.2)
    o += E(2 * T + 30, TOPO3 - 14 - 104 - 110, 22, 44, "#9fb8a8", 1.2) + E(2 * T + 30, TOPO3 - 14 - 104 - 168, 16, 16, "#9fb8a8", 1.0)
    # QUEBRA: direita — pedaço do navio (contêiner) no pilar + coluna alta segurando uma laje (nível 6) + concha-trampolim
    o += f'<g transform="rotate(-6 {26 * T} {TOPO3})">' + conteiner(24 * T + 30, TOPO3 - 14 - T, 3 * T, T, CONT[3], 2) + "</g>"
    o += coluna(27 * T + 40, 6 * T + 30, TOPO3 - 14) + laje(21 * T + 40, 6 * T, 7 * T)
    o += E(28 * T + 10, TOPO3 - 30, 40, 16, "#f2a7c3", 1.2) + f'<path d="M{28 * T - 30},{TOPO3 - 34} a40,32 0 0 1 80,-24" fill="#f7c6d8" stroke="#d1708f" stroke-width="4"/>'
    # QUEBRA: mastro do navio atravessado como rampa (do alto esquerdo até a laje do centro) + contêiner preso no alto
    o += f'<g transform="rotate(22 {1 * T} {3 * T})">' + R(1 * T, 3 * T, 11 * T, 22, "#9a9aa8", 3, 1.6, dark="#6b6b7a") + "</g>"
    o += f'<g transform="rotate(10 {21 * T} {3 * T})">' + conteiner(19 * T + 40, 2 * T + 30, 3 * T, T, CONT[1], 1) + "</g>"
    o += f'<path d="M{20 * T},{2 * T + 30} L{19 * T + 30},0 M{22 * T + 40},{2 * T + 40} L{23 * T},0" stroke="#5a5f6a" stroke-width="4"/>'   # correntes do navio
    return o


def c3_cupula():
    """A cúpula de ar cobre a arena; rachou à DIREITA: a água entra e alaga até a linha 10 daquele lado."""
    cx, base, rx, ry = 15 * T, H + 40, 15 * T + 40, H + 20
    o = f'<path d="M{cx - rx},{base} A{rx},{ry} 0 0 1 {cx + rx},{base}" fill="none" stroke="#ffffff" stroke-width="6" opacity="0.7"/>'
    px, py = 24 * T, 1 * T + 10
    o += f'<path d="M{px},{py} l-20,26 l16,14 l-24,30 M{px},{py} l26,10" stroke="#ffffff" stroke-width="5" fill="none"/>'
    o += f'<path d="M{px - 10},{py + 20} C{px - 40},{py + 140} {px + 10},{py + 280} {px - 20},{10 * T}" stroke="#7fd6e6" stroke-width="22" fill="none" opacity="0.7"/>'
    o += f'<rect x="{20 * T}" y="{10 * T}" width="{10 * T}" height="{H - 10 * T}" fill="#3fc6dc" opacity="0.35"/>'
    o += f'<path d="M{20 * T},{10 * T} ' + "".join("q20,-8 40,0 " for _ in range(16)) + '" stroke="#ffffff" stroke-width="4" fill="none"/>'
    rnd = random.Random(17)
    for _ in range(18):
        o += f'<circle cx="{rnd.uniform(20 * T, 30 * T)}" cy="{rnd.uniform(10 * T, H)}" r="{rnd.uniform(3, 9)}" fill="none" stroke="#ffffff" stroke-width="2.5" opacity="0.8"/>'
    return o


def c3_grua():
    """Grua submarina da equipe (identidade da obra) presa no pilar da esquerda, com holofote."""
    x = 1 * T + 10
    o = R(x, 3 * T, 22, TOPO3 - 14 - 104 - 3 * T, "#e0a83a", 3, 1.4, dark="#b07a1e")
    for k in range(5):
        y = 3 * T + 20 + k * 52
        o += f'<path d="M{x},{y} l22,30 M{x + 22},{y} l-22,30" stroke="#b07a1e" stroke-width="3"/>'
    o += R(x - 20, 3 * T - 14, 200, 18, "#e0a83a", 3, 1.2) + f'<circle cx="{x + 170}" cy="{3 * T + 10}" r="12" fill="#fff4c8"/>'
    o += f'<path d="M{x + 170},{3 * T + 10} L{x + 60},{6 * T} L{x + 300},{6 * T} Z" fill="#fff4c8" opacity="0.12"/>'
    o += f'<rect x="{12 * T + 30}" y="{TOPO3 + 50}" width="180" height="36" rx="6" fill="{YEL}"/><text x="{12 * T + 120}" y="{TOPO3 + 75}" font-family="Fredoka" font-weight="700" font-size="17" fill="{INK}" text-anchor="middle">OBRA SUBMARINA</text>'
    return o


def c3_atores():
    o = robot("marretao", "pesado_golpe", el.COLORS[0], 14 * T + 40, 8 * T)
    o += robot("picareta", "parado", el.COLORS[1], 7 * T, 9 * T)
    o += robot("chave", "esquiva", el.COLORS[2], 15 * T, 3 * T + 40)
    o += robot("pa", "rapido", el.COLORS[4], 23 * T + 20, 8 * T + 40, flip=True, rot=-12)   # flutuando na parte alagada
    o += f'<path d="M{23 * T - 20},{8 * T + 40} q-10,-30 6,-60" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.8"/>'
    return o


def c3_frente():
    o = f'<rect x="0" y="{TOPO3 + 120}" width="{W}" height="{H - TOPO3 - 120}" fill="url(#c3fenda)" opacity="0.85"/>'
    rnd = random.Random(23)
    for _ in range(22):
        o += f'<circle cx="{rnd.uniform(0, W)}" cy="{rnd.uniform(0, H)}" r="{rnd.uniform(3, 10)}" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.6"/>'
    o += tag(3 * T + 30, TOPO3 + 70, "PILAR (FIXO)") + tag(15 * T, TOPO3 + 120, "PILAR (FIXO)") + tag(26 * T + 30, TOPO3 + 70, "PILAR (FIXO)")
    o += tag(17 * T + 60, 7 * T + 50, "LAJE") + tag(8 * T, 10 * T + 10, "LAJE-PONTE") + tag(24 * T, 5 * T + 40, "LAJE ALTA")
    o += tag(15 * T, 2 * T + 60, "FRONTÃO CAÍDO") + tag(3 * T + 40, 10 * T - 30, "TAMBORES") + tag(5 * T, 3 * T + 30, "MASTRO-RAMPA")
    o += tag(21 * T + 40, 1 * T + 60, "CONTÊINER PRESO") + tag(25 * T + 20, 11 * T + 10, "ALAGANDO") + tag(28 * T, TOPO3 - 90, "CONCHA")
    o += tag(9 * T, H - 40, "FENDA = KO") + tag(21 * T, H - 40, "FENDA = KO") + tag(W / 2, 40, "TEMPLO E CÚPULA = FUNDO")
    return o


def cena2b():
    defs = (fonte() + rough(seed=35, scale=0.8, freq=0.05) + grad("c3agua", [(0, "#4fc0d0"), (0.6, "#1f7f9a"), (1, "#0f4f6f")])
            + grad("c3fenda", [(0, "#0f4f6f"), (0.5, "#08283c"), (1, "#02080f")]))
    body = c3_agua() + c3_templo_fundo() + c3_grua() + c3_palco() + c3_cupula() + c3_atores() + c3_frente()
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
