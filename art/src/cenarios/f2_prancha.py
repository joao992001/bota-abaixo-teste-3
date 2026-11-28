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


# =========================================================================================== CENA 2a — DESTROÇOS DO CARGUEIRO (v3)
# Manhã dourada depois da tempestade. O navio partido é MOLDURA (não se pisa). A luta é sobre o MAR FUNDO (KO), em rochas
# e na balsa (FIXAS) e em plataformas que quebram: contêineres tortos/derramando, bote virado, jangada de paletes, pedaço do
# convés, rede de carga no gancho, tábuas da balsa.
MAR2 = 15 * T


def gaivota(x, y, s=1.0, pousada=False):
    if pousada:
        return (E(x, y - 8 * s, 10 * s, 7 * s, "#ffffff", 0.6) + E(x + 8 * s, y - 14 * s, 5 * s, 5 * s, "#ffffff", 0.5)
                + f'<path d="M{x + 12 * s},{y - 14 * s} l6,1" stroke="#f2a33a" stroke-width="2"/><path d="M{x - 8 * s},{y - 8 * s} l-8,-2" stroke="#8a8f9a" stroke-width="3"/>')
    return f'<path d="M{x},{y} q{10 * s},{-10 * s} {20 * s},0 q{10 * s},{-10 * s} {20 * s},0" stroke="{INK}" stroke-width="3" fill="none"/>'


def c2_ceu():
    o = f'<rect width="{W}" height="{H}" fill="url(#c2ceu)"/>'
    o += f'<circle cx="260" cy="210" r="90" fill="#fff2c0"/><circle cx="260" cy="210" r="150" fill="#fff2c0" opacity="0.25"/>'
    for k in range(8):
        a = -0.2 + k * 0.32
        o += f'<path d="M260,210 L{260 + math.cos(a) * 1400},{210 + math.sin(a) * 900}" stroke="#fff6d8" stroke-width="40" opacity="0.08"/>'
    for cx, cy, s in [(760, 90, 1.2), (1340, 60, 1.0), (1700, 120, 0.9)]:
        for dx, dy, r in [(0, 0, 50), (60, -20, 60), (130, 0, 50)]:
            o += E(cx + dx * s, cy + dy * s, r * s, r * 0.6 * s, "#fff8ec", 1.2)
    o += f'<rect x="0" y="560" width="{W}" height="{H}" fill="#8fd8cf"/>'
    o += f'<rect x="0" y="556" width="{W}" height="8" fill="#fff2c0" opacity="0.6"/>'
    # ilha distante com coqueiros e farolzinho
    o += PL([(1380, 560), (1500, 510), (1650, 505), (1780, 560)], "#9cc49a", 1.2)
    for x in (1520, 1600):
        o += f'<path d="M{x},540 q-6,-40 10,-70" stroke="#8a6b4f" stroke-width="5" fill="none"/>' + f'<path d="M{x + 10},470 q-20,-6 -34,8 M{x + 10},470 q20,-6 34,8 M{x + 10},470 q-4,-20 -20,-24" stroke="#4f9a52" stroke-width="5" fill="none"/>'
    o += R(1700, 470, 12, 40, "#eef0f4", 2, 0.8) + R(1698, 462, 16, 10, "#d14b4b", 2, 0.6)
    for k in range(6):
        o += gaivota(820 + k * 70, 230 + (k % 3) * 24, 0.9)
    return o


def c2_navio_fundo():
    """Moldura: a proa tombada à esquerda (com o corte mostrando os andares) e a popa emborcada à direita."""
    o = PL([(260, 640), (700, 590), (1200, 600), (1320, 640)], "#e6d6a8", 1.6)   # banco de areia onde encalhou
    o += f'<g transform="rotate(-11 760 430)">'
    o += PL([(250, 300), (1120, 300), (1120, 640), (300, 640)], "#b4664f", 2.4, dark="#8a4a38")
    o += R(250, 288, 870, 16, "#7a7f8a", 2, 1.2)
    for x in range(260, 1110, 44):
        o += f'<path d="M{x},288 v-30" stroke="#e9e2d2" stroke-width="3"/>'
    o += f'<path d="M250,262 H1110" stroke="#e9e2d2" stroke-width="3"/>'
    for k in range(7):
        o += E(330 + k * 110, 370, 12, 12, "#4a3f44", 0.8)
    rnd = random.Random(41)
    for k in range(14):
        x = rnd.uniform(270, 1080)
        o += f'<path d="M{x},{rnd.uniform(320, 420)} q4,30 -2,{rnd.uniform(40, 90)}" stroke="#7a3424" stroke-width="4" fill="none" opacity="0.5"/>'
    # corte aberto na quebra: andares por dentro, canos e cabos pendurados
    o += R(1000, 310, 120, 320, "#3a2a2e", 2, 1.2)
    for k in range(3):
        o += R(1000, 360 + k * 90, 120, 12, "#8a8f9a", 2, 0.8)
        o += f'<path d="M1010,{372 + k * 90} q30,40 60,10" stroke="#c9a46a" stroke-width="3" fill="none"/>'
    o += f'<path d="M1120,300 l18,26 l-14,18 l20,24 l-16,22 l22,24 l-18,26 l20,22" stroke="{INK}" stroke-width="4" fill="none"/>'
    # contêineres escorregando pelo convés inclinado
    for k, (x, c) in enumerate([(420, 0), (560, 3), (760, 1)]):
        o += f'<g transform="rotate({8 - k * 6} {x} 260)">' + R(x, 216, 130, 44, shade(CONT[c], -0.1), 2, 1.0) + "</g>"
    o += gaivota(620, 210, 1.0, True) + gaivota(880, 212, 1.0, True)
    o += "</g>"
    # popa emborcada à direita: ponte de comando de lado, chaminé listrada
    o += f'<g transform="rotate(14 1560 430)">'
    o += PL([(1260, 320), (1960, 320), (2000, 640), (1290, 640)], "#b4664f", 2.4, dark="#8a4a38")
    o += R(1500, 170, 240, 150, "#e6e8ee", 4, 1.4) + R(1520, 196, 60, 34, "#6a7a96", 3, 1.0) + R(1620, 196, 60, 34, "#6a7a96", 3, 1.0)
    o += R(1770, 150, 70, 170, "#2f3f5a", 3, 1.2) + R(1770, 190, 70, 30, "#e0a83a", 2, 1.0)
    o += R(1610, 120, 10, 50, "#8a8f9a", 2, 0.8) + gaivota(1560, 168, 1.0, True)
    o += "</g>"
    o += f'<rect x="0" y="0" width="{W}" height="{MAR2}" fill="#fff4dc" opacity="0.38"/>'   # névoa dourada da manhã
    return o


def rocha2(pts, topo_x0, topo_x1, topo_y, seed=1):
    """Rocha (FIXA) com cracas, alga e poça no topo plano jogável."""
    o = PL(pts, "#7f8794", 2.6, dark="#5f6672")
    o += R(topo_x0, topo_y - 6, topo_x1 - topo_x0, 14, "#9aa1ac", 3, 1.0)
    rnd = random.Random(seed)
    xs = [p[0] for p in pts]
    for _ in range(14):   # cracas
        x = rnd.uniform(min(xs) + 30, max(xs) - 30)
        y = rnd.uniform(topo_y + 40, MAR2 - 10)
        o += E(x, y, 6, 4, "#d9d2c0", 0.5)
    for _ in range(3):   # alga escorrendo
        x = rnd.uniform(min(xs) + 40, max(xs) - 40)
        o += f'<path d="M{x},{MAR2 - 60} q-10,30 4,60" stroke="#3f8a4f" stroke-width="8" fill="none" stroke-linecap="round"/>'
    o += E((topo_x0 + topo_x1) / 2, topo_y + 2, (topo_x1 - topo_x0) * 0.22, 5, "#7fd0e0", 0.6)   # poça
    return o


def c2_palco():
    o = ""
    # ---- FIXO: rocha da esquerda (alta), rocha-arco do meio, balsa-guindaste à direita
    o += rocha2([(40, H), (60, 12 * T + 40), (120, 12 * T), (5 * T + 10, 12 * T - 6), (5 * T + 60, 12 * T + 50), (5 * T + 40, H)], 140, 5 * T, 12 * T, 3)
    o += rocha2([(12 * T, H), (12 * T + 30, 11 * T + 40), (12 * T + 80, 11 * T), (17 * T + 10, 11 * T - 10), (17 * T + 60, 11 * T + 60), (17 * T + 40, H)], 12 * T + 90, 17 * T, 11 * T, 7)
    o += f'<path d="M{13 * T + 40},{H} q{1.5 * T},-140 {3 * T},0" fill="#174a5a"/>'   # vão do arco (mar passa por baixo)
    o += balsa(23 * T, 6 * T + 20)
    o += R(28 * T, 1 * T, 26, 12 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(11):
        y = T + 20 + k * 64
        o += f'<path d="M{28 * T},{y} l26,40 M{28 * T + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(11 * T, 1 * T - 14, 18 * T, 20, "#e0a83a", 3, 1.4) + R(28 * T - 30, 1 * T - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += sign(23 * T + 30, 13 * T - 60, "BOTA-ABAIXO", 170)
    # coqueiro torto e boia de sinalização na rocha da esquerda
    o += f'<path d="M{1 * T + 40},{12 * T} q-20,-120 50,-230" stroke="#8a6b4f" stroke-width="16" fill="none"/>'
    for a in range(5):
        ang = -2.7 + a * 0.5
        o += f'<path d="M{1 * T + 90},{8 * T + 26} q{math.cos(ang) * 50},{math.sin(ang) * 26 - 26} {math.cos(ang) * 110},{math.sin(ang) * 56 + 20}" stroke="#4f9a52" stroke-width="14" fill="none" stroke-linecap="round"/>'
    # ---- QUEBRA: contêineres tortos na rocha da esquerda (um aberto derramando pneus e caixas)
    o += f'<g transform="rotate(-3 {3 * T} {12 * T})">' + conteiner(2 * T, 11 * T, 3 * T, T, CONT[2], 0, True) + "</g>"
    o += f'<g transform="rotate(6 {3 * T} {10 * T})">' + conteiner(2 * T + 20, 10 * T - 4, 3 * T - 10, T, CONT[0], 1) + "</g>"
    o += R(5 * T - 30, 11 * T - 6, 40, 70, "#2a2a30", 3, 0.8)   # porta aberta
    for k, (dx, dy) in enumerate([(5 * T + 30, 12 * T - 30), (5 * T + 70, 12 * T - 10), (5 * T + 10, 12 * T - 8)]):
        o += E(dx, dy, 18, 18, "#2a2a30", 0.8) + E(dx, dy, 8, 8, "#5a5a64", 0.5) if k < 2 else R(dx, dy - 30, 40, 30, "#c98a4b", 3, 0.8)
    # ---- QUEBRA: bote virado boiando + jangada de paletes (balançam com a maré)
    o += f'<g transform="rotate(4 {8 * T} {MAR2})">' + PL([(6 * T + 40, MAR2 - 44), (9 * T + 20, MAR2 - 44), (9 * T, MAR2 + 6), (7 * T, MAR2 + 6)], "#f08a3d", 1.4)
    o += R(6 * T + 40, MAR2 - 50, 2 * T + 44, 10, "#d9dce4", 2, 0.8) + "</g>"
    o += f'<g transform="rotate(-5 {10 * T} {MAR2})">'
    for k in range(3):
        o += R(9 * T + 50 + k * 34, MAR2 - 28, 30, 30, "#c98a4b", 2, 0.8)
    o += R(9 * T + 40, MAR2 - 34, 110, 10, "#b07a3e", 2, 0.8) + "</g>"
    # ---- QUEBRA: pedaço do convés (com guarda-corpo) apoiado no arco — nível 8; escoras dobradas
    o += f'<g transform="rotate(-5 {15 * T} {8 * T})">'
    o += R(11 * T + 30, 8 * T, 7 * T, 26, "#6b6f7a", 2, 1.6, dark="#4a4f5a") + R(11 * T + 30, 8 * T + 26, 7 * T, 30, "#9a4a38", 2, 1.4, dark="#7a3424")
    for x in range(11 * T + 40, 18 * T + 30, 44):
        o += f'<path d="M{x},{8 * T} v-34" stroke="#e9e2d2" stroke-width="4"/>'
    o += f'<path d="M{11 * T + 30},{8 * T - 30} H{18 * T + 30}" stroke="#e9e2d2" stroke-width="4"/>'
    o += E(16 * T, 8 * T - 18, 18, 14, "#5a5f6a", 0.8)   # cabrestante
    o += "</g>"
    o += f'<path d="M{13 * T},{8 * T + 60} L{13 * T + 30},{11 * T} M{16 * T + 40},{8 * T + 50} L{16 * T + 10},{11 * T - 6}" stroke="#4a2620" stroke-width="14"/>'
    # ---- QUEBRA: mastro-ponte (dos contêineres da esquerda até o pedaço do convés)
    o += f'<g transform="rotate(-10 {5 * T} {10 * T})">' + R(5 * T, 10 * T - 40, 7 * T, 18, "#9a9aa8", 3, 1.4, dark="#6b6b7a") + "</g>"
    # ---- QUEBRA: rede de carga no gancho (nível 5): caixas dentro, balança
    o += f'<path d="M{17 * T},{1 * T + 6} L{17 * T + 10},{4 * T}" stroke="{INK}" stroke-width="4"/>'
    o += f'<g transform="rotate(6 {17 * T} {5 * T})">'
    for k in range(3):
        o += R(15 * T + 50 + k * 66, 4 * T + 34, 60, 50, "#c98a4b" if k != 1 else "#b07a3e", 3, 1.0)
    o += f'<path d="M{15 * T + 40},{4 * T + 20} Q{17 * T},{5 * T + 70} {18 * T + 50},{4 * T + 20}" stroke="#5a4a3a" stroke-width="4" fill="none"/>'
    for k in range(6):
        o += f'<path d="M{15 * T + 50 + k * 34},{4 * T + 24} l20,56" stroke="#5a4a3a" stroke-width="3"/>'
    o += "</g>"
    o += f'<path d="M{15 * T + 20},{5 * T + 10} q-16,0 -24,12 M{18 * T + 70},{5 * T} q16,0 24,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    # ---- QUEBRA: contêineres na balsa + tábuas da torre (nível 6)
    o += conteiner(23 * T + 30, 12 * T, 3 * T, T, CONT[1], 0, True) + conteiner(26 * T + 20, 12 * T, 2 * T + 20, T, CONT[3], 1)
    o += conteiner(23 * T + 50, 11 * T, 3 * T - 10, T, CONT[6], 2)
    o += tabua(21 * T, 6 * T, 7 * T - 10)
    o += f'<path d="M{21 * T + 20},{1 * T + 6} V{6 * T}" stroke="{INK}" stroke-width="3"/>'
    # vida: caranguejos e gaivota pousada
    for x, y in [(3 * T + 40, 10 * T - 4), (14 * T + 20, 11 * T - 10)]:
        o += E(x, y, 12, 8, "#e06a4a", 0.8) + f'<path d="M{x - 12},{y} l-8,-8 M{x + 12},{y} l8,-8" stroke="#e06a4a" stroke-width="3"/>'
    o += gaivota(26 * T, 11 * T, 1.2, True)
    return o


def c2_atores():
    o = robot("pa", "pesado_prep", el.COLORS[4], 3 * T, 10 * T - 4)
    o += robot("marretao", "rapido", el.COLORS[0], 14 * T + 20, 8 * T + 4)
    o += robot("chave", "esquiva", el.COLORS[2], 17 * T, 4 * T + 30, flip=True)
    o += robot("britadeira", "pesado_golpe", el.COLORS[3], 7 * T + 60, MAR2 - 46)
    o += f'<path d="M{16 * T + 20},{4 * T} h-50 M{16 * T + 26},{4 * T + 14} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>'
    return o


def c2_frente():
    o = f'<rect x="0" y="{MAR2}" width="{W}" height="{H - MAR2}" fill="url(#c2fundo)"/>'
    rnd = random.Random(6)
    for k in range(18):
        x = rnd.uniform(0, W)
        o += f'<path d="M{x},{MAR2 + 26 + rnd.uniform(0, 80)} q16,-6 32,0" stroke="#9fe0e0" stroke-width="4" fill="none" opacity="0.7"/>'
    o += f'<path d="M0,{MAR2} ' + "".join("q30,-10 60,0 " for _ in range(33)) + '" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.95"/>'
    o += f'<path d="M0,{13 * T} H{W}" stroke="#ffffff" stroke-width="3" stroke-dasharray="16 12" opacity="0.85"/>'
    o += f'<text x="{W - 30}" y="{13 * T - 10}" font-family="Fredoka" font-weight="700" font-size="18" fill="#ffffff" text-anchor="end">maré alta</text>'
    o += tag(3 * T, 13 * T + 50, "ROCHA (FIXA)") + tag(15 * T, 12 * T + 40, "ROCHA-ARCO (FIXA)") + tag(26 * T, 13 * T + 50, "BALSA (FIXA)")
    o += tag(6 * T, 9 * T - 30, "CONTÊINER ABERTO") + tag(9 * T, 9 * T + 70, "MASTRO-PONTE") + tag(14 * T + 40, 9 * T + 30, "PEDAÇO DO CONVÉS")
    o += tag(8 * T, MAR2 - 80, "BOTE VIRADO") + tag(10 * T + 60, MAR2 + 50, "JANGADA") + tag(19 * T + 60, 5 * T + 50, "REDE NO GANCHO") + tag(24 * T + 40, 5 * T + 40, "TÁBUAS")
    o += tag(5 * T, H - 34, "MAR FUNDO = KO") + tag(20 * T, H - 34, "MAR FUNDO = KO") + tag(940, 186, "NAVIO PARTIDO = FUNDO")
    return o


def cena2a():
    defs = (fonte() + rough(seed=33, scale=0.8, freq=0.05) + grad("c2ceu", [(0, "#ffe2b0"), (0.5, "#cfe9f0"), (1, "#a8e0e8")])
            + grad("c2fundo", [(0, "#2f8f9a"), (0.35, "#1f5f78"), (1, "#0b2f45")]))
    body = c2_ceu() + c2_navio_fundo() + c2_palco() + c2_atores() + c2_frente()
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


# =========================================================================================== CENA 2b — ATLÂNTIDA (v3)
# Atlântida dourada. A cidade, o guardião e a cúpula são MOLDURA. A proa do navio furou a cúpula e a água jorra (alaga a direita).
# A luta é sobre a FENDA ABISSAL (KO), em pilares (FIXOS) e plataformas que quebram: tambores, cabeça de estátua, lajes
# entalhadas, lustre dourado pendurado, baú e contêiner de moedas, concha-trampolim.
TOPO3 = 12 * T
MARM, MARM_D, OURO, OURO_D = "#f0e6d0", "#cbbd9e", "#e8bc4a", "#b58a2a"


def c3_agua():
    o = f'<rect width="{W}" height="{H}" fill="url(#c3agua)"/>'
    for k in range(8):
        x = 60 + k * 250
        o += f'<path d="M{x},0 L{x + 80},0 L{x + 280},{H} L{x + 60},{H} Z" fill="#fff6c8" opacity="0.07"/>'
    return o


def c3_cidade_fundo():
    """Moldura: cidade de Atlântida com cúpulas douradas, aqueduto e o GUARDIÃO gigante (genérico, com tridente)."""
    o = ""
    for x, w, h, cup in [(20, 160, 380, True), (200, 120, 300, False), (1600, 150, 360, True), (1780, 140, 280, False), (360, 110, 240, True), (1460, 120, 250, False)]:
        o += R(x, 9 * T - h + 160, w, h, "#5aa6b6", 4, 1.4)
        if cup:
            o += E(x + w / 2, 9 * T - h + 160, w / 2, w * 0.4, "#c9b46a", 1.2)
        for k in range(3):
            o += R(x + 20 + k * (w - 40) / 3, 9 * T - h + 220, 20, 34, "#3f8a9a", 3, 0.8)
    for k in range(7):   # aqueduto
        o += f'<path d="M{480 + k * 140},{9 * T + 60} v-120 a50,50 0 0 1 100,0 v120" fill="none" stroke="#6fb6c4" stroke-width="22"/>'
    o += R(470, 9 * T - 110, 1000, 30, "#6fb6c4", 3, 1.2)
    # guardião gigante ao centro (sem rosto definido: silhueta de pedra)
    gx = 15 * T
    o += PL([(gx - 150, 9 * T + 60), (gx - 110, 3 * T), (gx + 110, 3 * T), (gx + 150, 9 * T + 60)], "#6aaebc", 1.8)
    o += E(gx, 2 * T + 10, 70, 80, "#6aaebc", 1.6) + PL([(gx - 80, 1 * T), (gx - 40, 0), (gx, 1 * T - 30), (gx + 40, 0), (gx + 80, 1 * T)], "#c9b46a", 1.2)
    o += R(gx + 150, 0, 16, 7 * T, "#c9b46a", 2, 1.0) + PL([(gx + 128, 30), (gx + 158, -20), (gx + 188, 30), (gx + 166, 40), (gx + 158, 10), (gx + 150, 40)], "#c9b46a", 1.0)
    o += f'<rect x="0" y="0" width="{W}" height="{H}" fill="#2f8fa8" opacity="0.4"/>'
    return o


def c3_cupula():
    """Cúpula de ar com armação dourada; a PROA do navio furou o alto à direita e a água jorra, alagando a direita até a linha 10."""
    cx, base, rx, ry = 15 * T, H + 60, 15 * T + 60, H + 30
    o = f'<path d="M{cx - rx},{base} A{rx},{ry} 0 0 1 {cx + rx},{base}" fill="#e6fbff" opacity="0.07"/>'
    o += f'<path d="M{cx - rx},{base} A{rx},{ry} 0 0 1 {cx + rx},{base}" fill="none" stroke="{OURO}" stroke-width="10" opacity="0.8"/>'
    for k in range(1, 8):
        a = math.pi * k / 8
        o += f'<path d="M{cx - math.cos(a) * rx},{base - math.sin(a) * ry} L{cx - math.cos(a) * rx * 0.96},{base}" stroke="{OURO}" stroke-width="4" opacity="0.35"/>'
    # proa furando a cúpula
    o += f'<g transform="rotate(32 {24 * T} 0)">' + PL([(22 * T, -200), (26 * T, -200), (26 * T, 40), (24 * T, 160), (22 * T, 40)], "#a5523d", 2.0, dark="#7e3a2b")
    o += R(22 * T, -40, 4 * T, 14, "#e9e2d2", 2, 0.8) + E(24 * T, 20, 14, 14, "#4a3f44", 0.8) + "</g>"
    o += f'<path d="M{23 * T + 40},{1 * T + 40} l-30,30 l20,14 l-30,34 M{25 * T + 10},{1 * T + 30} l30,24" stroke="#ffffff" stroke-width="5" fill="none"/>'
    o += f'<path d="M{23 * T + 20},{2 * T} C{23 * T},{4 * T} {24 * T},{7 * T} {23 * T + 30},{10 * T}" stroke="#bff0fa" stroke-width="34" fill="none" opacity="0.65"/>'
    o += f'<rect x="{20 * T}" y="{10 * T}" width="{10 * T}" height="{H - 10 * T}" fill="#3fc6dc" opacity="0.32"/>'
    o += f'<path d="M{20 * T},{10 * T} ' + "".join("q20,-8 40,0 " for _ in range(16)) + '" stroke="#ffffff" stroke-width="4" fill="none"/>'
    rnd = random.Random(17)
    for _ in range(22):
        o += f'<circle cx="{rnd.uniform(20 * T, 30 * T)}" cy="{rnd.uniform(9 * T, H)}" r="{rnd.uniform(3, 9)}" fill="none" stroke="#ffffff" stroke-width="2.5" opacity="0.8"/>'
    return o


def pilar_ouro(x0, x1, topo):
    """Topo de pilar (FIXO): plinto de mármore com anel de ouro, corais, sobre um pico de rocha que desce para a fenda."""
    o = PL([(x0 + 20, topo + 40), (x1 - 20, topo + 40), (x1 - 70, H + 10), (x0 + 70, H + 10)], "#3f5566", 2.4, dark="#2c3c4a")
    o += R(x0, topo, x1 - x0, 46, MARM_D, 3, 1.8, dark="#a89c82") + R(x0, topo + 30, x1 - x0, 10, OURO, 2, 0.8)
    o += R(x0 + 10, topo - 14, x1 - x0 - 20, 18, MARM, 3, 1.2)
    for k, (x, cor) in enumerate([(x0 + 6, "#ff7aa8"), (x1 - 30, "#f2a33a")]):   # corais crescendo nas quinas do plinto
        for j in range(3):
            o += f'<path d="M{x + j * 9},{topo - 10} q-6,-16 {4 - j * 3},-34" stroke="{cor}" stroke-width="7" fill="none" stroke-linecap="round"/>'
    for k in range(3):   # cracas/conchinhas na lateral
        o += E(x0 + 40 + k * (x1 - x0 - 80) / 2, topo + 24, 7, 5, "#fff2d0", 0.5)
    return o


def coluna2(x, y_top, y_bot, rachada=False, larg=44):
    o = R(x, y_top, larg, y_bot - y_top, MARM, 3, 1.6, dark=MARM_D)
    for j in range(4):
        o += f'<path d="M{x + 8 + j * 9},{y_top + 10} V{y_bot - 10}" stroke="{MARM_D}" stroke-width="2"/>'
    o += R(x - 10, y_top - 16, larg + 20, 18, MARM_D, 2, 1.0) + R(x - 6, y_top - 4, larg + 12, 6, OURO, 2, 0.6)
    if rachada:
        o += f'<path d="M{x + 12},{(y_top + y_bot) / 2} l16,18 l-12,14 l14,18" stroke="{INK}" stroke-width="4" fill="none"/>'
    return o


def laje2(x, y, w):
    """Laje de mármore entalhada (QUEBRA): friso grego dourado."""
    o = R(x, y, w, 34, MARM, 3, 1.6, dark=MARM_D) + R(x, y + 26, w, 8, MARM_D, 2, 0.8)
    d = ""
    for k in range(int(w / 32)):
        xx = x + 8 + k * 32
        d += f"M{xx},{y + 22} v-12 h16 v8 h-8 "
    o += f'<path d="{d}" stroke="{OURO_D}" stroke-width="3" fill="none"/>'
    return o


def alga(x, y, n=2, comp=90):
    o = ""
    for j in range(n):
        o += f'<path d="M{x + j * 18},{y} q-14,{comp * 0.4} 4,{comp * 0.7} q14,{comp * 0.2} -6,{comp}" stroke="#3f9a5a" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.9"/>'
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


def c3_palco():
    o = ""
    # ---- FIXO: três pilares
    o += pilar_ouro(1 * T, 6 * T, 12 * T) + pilar_ouro(12 * T, 18 * T, 11 * T) + pilar_ouro(24 * T, 29 * T, 12 * T)
    # ---- QUEBRA (esquerda): tambores empilhados + cabeça de estátua caída; laje-ponte (nível 9) até o centro
    o += tambores(1 * T + 20, 12 * T - 14, 2)
    o += E(4 * T + 10, 12 * T - 60, 54, 46, "#cfc6b0", 1.6, dark="#a89c82") + E(4 * T + 30, 12 * T - 70, 10, 6, "#8a826e", 0.6)
    o += PL([(3 * T + 30, 12 * T - 96), (3 * T + 60, 12 * T - 130), (4 * T + 20, 12 * T - 106), (4 * T + 60, 12 * T - 138), (4 * T + 80, 12 * T - 96)], OURO, 1.0)   # coroa
    o += coluna2(6 * T - 40, 9 * T + 34, 12 * T - 14) + laje2(5 * T + 10, 9 * T, 6 * T + 30) + alga(7 * T, 9 * T + 34, 2, 110)
    # ---- QUEBRA (centro): duas colunas seguram a laje (nível 7); concha-trampolim no pilar
    o += coluna2(12 * T + 40, 7 * T + 34, 11 * T - 14, rachada=True) + coluna2(17 * T - 90, 7 * T + 34, 11 * T - 14)
    o += laje2(11 * T + 20, 7 * T, 7 * T) + alga(16 * T, 7 * T + 34, 3, 120)
    o += E(15 * T, 11 * T - 30, 48, 18, "#f2a7c3", 1.2) + f'<path d="M{15 * T - 48},{11 * T - 34} a48,40 0 0 1 96,-28" fill="#f7c6d8" stroke="#d1708f" stroke-width="4"/>'
    o += E(15 * T, 11 * T - 36, 10, 8, "#ffffff", 0.6)
    # ---- QUEBRA: lustre dourado pendurado na cúpula por corrente (nível 4), balança
    o += f'<path d="M{10 * T},0 L{10 * T + 20},{3 * T + 30}" stroke="{OURO_D}" stroke-width="5" stroke-dasharray="10 6"/>'
    o += f'<g transform="rotate(6 {10 * T + 20} {4 * T})">'
    o += R(8 * T + 40, 4 * T, 3 * T + 20, 18, OURO, 3, 1.2, dark=OURO_D)
    o += f'<path d="M{8 * T + 50},{4 * T + 18} Q{10 * T + 20},{5 * T + 40} {11 * T + 50},{4 * T + 18}" stroke="{OURO}" stroke-width="8" fill="none"/>'
    for k in range(5):
        o += f'<circle cx="{8 * T + 60 + k * 40}" cy="{4 * T - 10}" r="8" fill="#fff6c8"/><circle cx="{8 * T + 60 + k * 40}" cy="{4 * T - 10}" r="20" fill="#fff6c8" opacity="0.25"/>'
    o += "</g>"
    o += f'<path d="M{8 * T + 20},{4 * T + 30} q-16,0 -24,12 M{11 * T + 80},{4 * T + 10} q16,0 24,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    # ---- QUEBRA (direita, alagada): contêiner do navio derramando moedas + baú; coluna alta com laje (nível 6)
    o += f'<g transform="rotate(-6 {26 * T} {12 * T})">' + conteiner(24 * T + 30, 12 * T - 14 - T, 3 * T, T, CONT[3], 2, True) + "</g>"
    for k in range(14):
        o += E(24 * T + 20 + k * 12, 12 * T - 18 - (k % 3) * 8, 8, 4, OURO, 0.5)
    o += R(27 * T + 20, 12 * T - 60, 70, 46, "#8a5a3a", 4, 1.0) + R(27 * T + 20, 12 * T - 60, 70, 12, OURO, 2, 0.6)
    o += coluna2(28 * T - 10, 6 * T + 34, 12 * T - 60) + laje2(22 * T + 20, 6 * T, 7 * T) + alga(24 * T, 6 * T + 34, 3, 130)
    # ---- QUEBRA: corrente do navio pendurada da proa (decoração) e águas-vivas brilhando
    o += f'<path d="M{23 * T},{3 * T} q-20,120 10,220" stroke="#5a5f6a" stroke-width="6" fill="none" stroke-dasharray="12 6"/>'
    for x, y, c in [(3 * T, 4 * T, "#ff9ad8"), (20 * T, 3 * T, "#9ad8ff"), (7 * T, 6 * T + 20, "#c8a0ff")]:
        o += f'<circle cx="{x}" cy="{y}" r="40" fill="{c}" opacity="0.18"/>' + f'<path d="M{x - 22},{y} a22,18 0 0 1 44,0 Z" fill="{c}" opacity="0.85"/>'
        for j in range(4):
            o += f'<path d="M{x - 15 + j * 10},{y} q-4,20 4,40" stroke="{c}" stroke-width="3" fill="none" opacity="0.8"/>'
    return o


def c3_grua():
    """Grua submarina da equipe (identidade da obra) presa no pilar da esquerda, com holofote."""
    x = 5 * T + 20
    o = R(x, 1 * T + 40, 22, 12 * T - 14 - 1 * T - 40 - 104, "#e0a83a", 3, 1.4, dark="#b07a1e")
    for k in range(6):
        y = 1 * T + 60 + k * 52
        o += f'<path d="M{x},{y} l22,30 M{x + 22},{y} l-22,30" stroke="#b07a1e" stroke-width="3"/>'
    o += R(x - 220, 1 * T + 26, 260, 18, "#e0a83a", 3, 1.2) + f'<circle cx="{x - 200}" cy="{1 * T + 50}" r="12" fill="#fff4c8"/>'
    o += f'<path d="M{x - 200},{1 * T + 50} L{x - 320},{5 * T} L{x - 80},{5 * T} Z" fill="#fff4c8" opacity="0.12"/>'
    o += f'<rect x="{12 * T + 40}" y="{11 * T + 56}" width="180" height="36" rx="6" fill="{YEL}"/><text x="{12 * T + 130}" y="{11 * T + 81}" font-family="Fredoka" font-weight="700" font-size="17" fill="{INK}" text-anchor="middle">OBRA SUBMARINA</text>'
    return o


def c3_atores():
    o = robot("marretao", "pesado_golpe", el.COLORS[0], 14 * T, 7 * T)
    o += robot("picareta", "rapido", el.COLORS[1], 7 * T + 20, 9 * T)
    o += robot("chave", "esquiva", el.COLORS[2], 10 * T + 10, 4 * T - 6)
    o += robot("pa", "parado", el.COLORS[4], 25 * T, 8 * T + 30, flip=True, rot=-14)   # flutuando na parte alagada
    o += f'<path d="M{25 * T - 30},{8 * T + 30} q-10,-30 6,-60" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.8"/>'
    return o


def c3_frente():
    o = f'<rect x="0" y="{11 * T + 110}" width="{W}" height="{H - 11 * T - 110}" fill="url(#c3fenda)" opacity="0.85"/>'
    rnd = random.Random(23)
    for _ in range(5):   # luzes de peixe-pescador na fenda
        x, y = rnd.uniform(100, W - 100), rnd.uniform(H - 110, H - 30)
        o += f'<circle cx="{x}" cy="{y}" r="16" fill="#fff6a0" opacity="0.2"/><circle cx="{x}" cy="{y}" r="5" fill="#fff6a0"/>'
    for _ in range(22):
        o += f'<circle cx="{rnd.uniform(0, W)}" cy="{rnd.uniform(0, H)}" r="{rnd.uniform(3, 10)}" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.6"/>'
    o += tag(3 * T + 30, 13 * T + 20, "PILAR (FIXO)") + tag(15 * T, 12 * T + 50, "PILAR (FIXO)") + tag(26 * T + 30, 13 * T + 20, "PILAR (FIXO)")
    o += tag(17 * T + 60, 7 * T + 70, "LAJE ENTALHADA") + tag(9 * T, 10 * T + 10, "LAJE-PONTE") + tag(23 * T + 40, 5 * T + 40, "LAJE ALTA")
    o += tag(10 * T + 20, 5 * T + 50, "LUSTRE DOURADO") + tag(2 * T, 10 * T + 10, "TAMBORES") + tag(4 * T + 40, 12 * T + 40, "CABEÇA DE ESTÁTUA")
    o += tag(15 * T, 12 * T - 100, "CONCHA") + tag(26 * T + 20, 11 * T + 10, "MOEDAS E BAÚ") + tag(22 * T + 60, 2 * T + 40, "PROA FUROU A CÚPULA")
    o += tag(21 * T + 40, 9 * T + 40, "ALAGANDO") + tag(9 * T, H - 34, "FENDA = KO") + tag(21 * T, H - 34, "FENDA = KO")
    return o


def cena2b():
    defs = (fonte() + rough(seed=35, scale=0.8, freq=0.05) + grad("c3agua", [(0, "#5fd0d8"), (0.55, "#2a8fa8"), (1, "#14506e")])
            + grad("c3fenda", [(0, "#14506e"), (0.5, "#0a2a40"), (1, "#02080f")]))
    body = c3_agua() + c3_cidade_fundo() + c3_cupula() + c3_grua() + c3_palco() + c3_atores() + c3_frente()
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
