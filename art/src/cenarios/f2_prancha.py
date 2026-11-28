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
    o += f'<path d="M140,290 q0,-50 30,-64 M340,290 q0,-50 -30,-64" stroke="#8a8f9a" stroke-width="10" fill="none" stroke-linecap="round"/>'
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
    # nível 9: tábua da torre esquerda até o pilar e do pilar até a torre direita — escoras laranja sobre o topo do pilar
    o += R(13 * T, 9 * T + 18, 12, 11 * T - 9 * T - 18, "#f08a3d", 2, 1.0, dark="#c06a2a") + R(17 * T - 12, 9 * T + 18, 12, 11 * T - 9 * T - 18, "#f08a3d", 2, 1.0, dark="#c06a2a")
    o += tabua(8 * T, 9 * T, 5 * T + 12) + tabua(17 * T - 12, 9 * T, 4 * T + 12)
    # nível 6: à esquerda, tábua em consola presa na torre (mão-francesa); à direita, da torre até a torre da grua
    o += f'<path d="M{7 * T},{6 * T + 130} L{5 * T + 20},{6 * T + 18}" stroke="#c06a2a" stroke-width="10" stroke-linecap="round"/>'
    o += tabua(5 * T, 6 * T, 2 * T + 64) + tabua(22 * T, 6 * T, 6 * T)
    o += R(28 * T - 30, 6 * T + 18, 30, 14, "#b07a1e", 2, 0.8)   # suporte na torre da grua
    # contêiner no gancho da grua (balança, nível 6)
    o += icado(15 * T, 1 * T + 6, 4 * T + 10, 13 * T + 40, 16 * T + 20, 5 * T + 10) + conteiner(13 * T + 40, 5 * T + 10, 3 * T - 20, T - 8, CONT[4], 0, True)
    o += f'<path d="M{13 * T + 20},{6 * T + 10} q-18,0 -26,12 M{16 * T + 40},{6 * T + 10} q18,0 26,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    # viga içada lá no alto (nível 3), pendurada por dois cabos da lança
    o += pendurada(19 * T + 40, 25 * T + 16, 3 * T, 1 * T + 6, 1 * T + 6) + R(19 * T + 40, 3 * T, 5 * T + 40, 22, "#7a808c", 2, 1.4, dark="#5a606c")
    # bote salva-vidas pendurado nos turcos do navio (nível 5)
    o += f'<path d="M170,226 v30 M310,226 v30" stroke="{INK}" stroke-width="3"/>'
    o += PL([(140, 4 * T), (340, 4 * T), (316, 4 * T + 50), (164, 4 * T + 50)], "#f08a3d", 1.4)
    o += R(150, 4 * T - 8, 180, 10, "#d9dce4", 2, 0.8)
    return o


def c1_atores():
    o = robot("marretao", "pesado_prep", el.COLORS[0], 2 * T + 40, 13 * T - 3 * T)
    o += robot("picareta", "rapido", el.COLORS[1], 10 * T + 20, 9 * T, flip=True)
    o += robot("chave", "parado", el.COLORS[2], 14 * T + 10, 5 * T + 10)
    o += robot("britadeira", "pesado_golpe", el.COLORS[3], 23 * T + 40, 13 * T - 2 * T, flip=True)

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


def casco_fundo(pts_alto, pts_baixo, box, seed):
    """Casco de navio de verdade: obras mortas azul-escuras, faixa branca, obras vivas vermelhas (antiferrugem)."""
    o = PL(pts_alto, "#34506a", 2.4, dark="#243a50") + PL(pts_baixo, "#b5482f", 2.2, dark="#8a3524")
    rnd = random.Random(seed)
    x0, y0, x1, y1 = box
    for k in range(int((x1 - x0) / 120)):   # chapas
        x = x0 + 60 + k * 120
        o += f'<path d="M{x},{y0 + 20} V{y1 - 10}" stroke="#2a4258" stroke-width="3" opacity="0.8"/>'
    for _ in range(int((x1 - x0) / 60)):   # ferrugem escorrendo
        x = rnd.uniform(x0 + 20, x1 - 20)
        y = rnd.uniform(y0 + 30, y0 + 120)
        o += f'<path d="M{x},{y} q5,30 -2,{rnd.uniform(40, 110)}" stroke="#a5523d" stroke-width="{rnd.uniform(3, 6):.1f}" fill="none" opacity="0.6"/>'
    return o


def c2_navio_fundo():
    """Moldura (não se pisa), 3 camadas: banco de areia · proa tombada (corte com os andares) · popa emborcada. Pintura de
    navio de verdade, luz da manhã nas bordas de cima, sombra embaixo e reflexo na água."""
    o = PL([(220, 640), (640, 584), (1240, 594), (1360, 640)], "#ead8a6", 1.6) + PL([(300, 640), (700, 604), (1200, 612), (1300, 640)], "#d9c38c", 1.2)
    # ---- proa tombada (esquerda/centro)
    o += '<g transform="rotate(-11 760 430)">'
    o += casco_fundo([(250, 300), (1120, 300), (1120, 470), (285, 470)], [(285, 470), (1120, 470), (1120, 640), (320, 640)], (250, 300, 1120, 640), 41)
    o += f'<rect x="270" y="462" width="850" height="14" fill="#f2efe6"/>'   # faixa branca da linha d'água
    o += R(250, 288, 870, 16, "#8a909c", 2, 1.2) + f'<rect x="250" y="286" width="870" height="5" fill="#fff2c0" opacity="0.9"/>'   # luz no convés
    for x in range(260, 1110, 44):
        o += f'<path d="M{x},288 v-30" stroke="#f2efe6" stroke-width="3"/>'
    o += f'<path d="M250,262 H1110" stroke="#f2efe6" stroke-width="3"/>'
    for k in range(7):
        o += E(330 + k * 110, 360, 13, 13, "#1e2c3a", 0.8) + f'<circle cx="{326 + k * 110}" cy="356" r="4" fill="#cfe6f4"/>'
    o += f'<text x="640" y="430" font-family="Fredoka" font-weight="700" font-size="44" fill="#f2efe6" text-anchor="middle" opacity="0.85">ESTRELA DO SUL</text>'
    o += E(330, 410, 34, 24, "#1e2c3a", 1.0) + f'<path d="M330,434 v90 M300,500 h60 M305,524 q25,22 50,0" stroke="#5a5f6a" stroke-width="8" fill="none"/>'   # âncora
    for k, x in enumerate((520, 880)):   # boias penduradas
        o += f'<circle cx="{x}" cy="320" r="18" fill="none" stroke="#f08a3d" stroke-width="9"/><path d="M{x},302 v-14" stroke="#f2efe6" stroke-width="3"/>'
    rnd = random.Random(9)
    for _ in range(28):   # cracas e algas na linha d'água
        x = rnd.uniform(300, 1100)
        o += E(x, rnd.uniform(560, 630), 6, 4, "#e8e0cc", 0.5)
    for k in range(9):
        x = 340 + k * 90
        o += f'<path d="M{x},600 q-8,24 4,44" stroke="#3f8a4f" stroke-width="7" fill="none" stroke-linecap="round"/>'
    # corte aberto na quebra: andares por dentro, canos e cabos pendurados, luz entrando
    o += R(1000, 306, 120, 330, "#2a1f26", 2, 1.2)
    for k in range(3):
        o += R(1000, 360 + k * 90, 120, 12, "#8a8f9a", 2, 0.8)
        o += f'<path d="M1010,{372 + k * 90} q30,40 60,10" stroke="#c9a46a" stroke-width="3" fill="none"/>'
        o += R(1020 + k * 20, 320 + k * 90, 14, 40, "#5a6f8f", 2, 0.6)
    o += f'<path d="M1000,306 L1120,306 L1060,640 Z" fill="#fff2c0" opacity="0.08"/>'
    o += f'<path d="M1120,296 l18,26 l-14,18 l20,24 l-16,22 l22,24 l-18,26 l20,22 l-14,20 l18,24" stroke="{INK}" stroke-width="4" fill="none"/>'
    for k, (x, c) in enumerate([(700, 0), (860, 3)]):
        o += f'<g transform="rotate({8 - k * 6} {x} 260)">' + R(x, 216, 130, 44, shade(CONT[c], -0.05), 2, 1.0) + "</g>"
    o += gaivota(620, 262, 1.0, True) + gaivota(980, 262, 1.0, True)
    o += f'<rect x="250" y="560" width="870" height="80" fill="#1a2f3a" opacity="0.18"/>'   # sombra embaixo
    o += "</g>"
    # ---- popa emborcada à direita (ponte de lado, chaminé listrada, hélice)
    o += '<g transform="rotate(14 1560 430)">'
    o += casco_fundo([(1260, 320), (1960, 320), (1975, 470), (1272, 470)], [(1272, 470), (1975, 470), (2000, 640), (1290, 640)], (1260, 320, 1960, 640), 43)
    o += f'<rect x="1270" y="462" width="710" height="14" fill="#f2efe6"/>'
    o += R(1500, 170, 240, 150, "#eef0f4", 4, 1.4, dark="#cfd3da") + f'<rect x="1500" y="168" width="240" height="6" fill="#fff2c0"/>'
    for c in range(3):
        o += R(1516 + c * 76, 196, 56, 32, "#5a6f8f", 3, 1.0) + R(1516 + c * 76, 248, 56, 32, "#5a6f8f", 3, 1.0)
    o += R(1770, 140, 76, 180, "#2f3f5a", 3, 1.2) + R(1770, 176, 76, 34, "#e0a83a", 2, 1.0) + R(1770, 220, 76, 12, "#d14b4b", 2, 0.8)
    o += R(1610, 110, 10, 60, "#8a8f9a", 2, 0.8) + R(1580, 120, 70, 8, "#8a8f9a", 2, 0.6) + gaivota(1560, 168, 1.0, True)
    o += E(1880, 560, 34, 60, "#d9b46a", 1.2) + E(1880, 560, 10, 10, "#8a6b4f", 0.6)
    o += f'<rect x="1270" y="560" width="720" height="80" fill="#1a2f3a" opacity="0.18"/>'
    o += "</g>"
    # reflexos na água calma entre o banco de areia e o palco
    for k in range(10):
        x = 300 + k * 160
        o += f'<path d="M{x},{650 + (k % 3) * 18} h{60 + (k % 4) * 20}" stroke="#ffffff" stroke-width="4" opacity="0.5"/>'
    o += f'<rect x="0" y="0" width="{W}" height="{MAR2}" fill="#fff4dc" opacity="0.33"/>'   # névoa leve da manhã
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


def gancho(x, y):
    """Gancho de içamento (fim do cabo principal)."""
    return (f'<circle cx="{x}" cy="{y - 6}" r="7" fill="#5a5f6a"/>'
            f'<path d="M{x},{y} q0,16 12,16 q10,0 10,-10" stroke="#5a5f6a" stroke-width="5" fill="none" stroke-linecap="round"/>')


def icado(x_cabo, y_lanca, y_gancho, x0, x1, y_topo):
    """Peça içada do jeito certo: cabo principal da lança até o gancho; duas lingas do gancho até as QUINAS da peça."""
    o = f'<path d="M{x_cabo},{y_lanca} V{y_gancho}" stroke="{INK}" stroke-width="4"/>' + gancho(x_cabo, y_gancho)
    o += f'<path d="M{x_cabo},{y_gancho + 14} L{x0 + 8},{y_topo} M{x_cabo},{y_gancho + 14} L{x1 - 8},{y_topo}" stroke="{INK}" stroke-width="3"/>'
    o += f'<circle cx="{x0 + 8}" cy="{y_topo}" r="4" fill="#5a5f6a"/><circle cx="{x1 - 8}" cy="{y_topo}" r="4" fill="#5a5f6a"/>'
    return o


def pendurada(x0, x1, y_peca, y_esq, y_dir, inset=14):
    """Peça pendurada por DOIS cabos verticais que descem até as pontas dela (com manilhas)."""
    a, b = x0 + inset, x1 - inset
    return (f'<path d="M{a},{y_esq} V{y_peca} M{b},{y_dir} V{y_peca}" stroke="{INK}" stroke-width="3"/>'
            f'<circle cx="{a}" cy="{y_peca}" r="4" fill="#5a5f6a"/><circle cx="{b}" cy="{y_peca}" r="4" fill="#5a5f6a"/>')


def caranguejo(x, y):
    """Caranguejo de pé sobre a superfície y."""
    return (E(x, y - 7, 12, 8, "#e06a4a", 0.8) + f'<path d="M{x - 12},{y - 8} l-8,-8 M{x + 12},{y - 8} l8,-8 M{x - 8},{y - 2} l-4,4 M{x + 8},{y - 2} l4,4" stroke="#e06a4a" stroke-width="3"/>'
            + f'<circle cx="{x - 4}" cy="{y - 15}" r="2.5" fill="{INK}"/><circle cx="{x + 4}" cy="{y - 15}" r="2.5" fill="{INK}"/>')


def pneu_deitado(x, y):
    """Pneu deitado sobre a superfície y (visto de lado = elipse achatada)."""
    return E(x, y - 12, 34, 12, "#2a2a30", 0.8) + E(x, y - 14, 16, 5, "#55555f", 0.5)


# ---- medidas do palco da cena 2a (grid de 64)
R2_ESQ = (1 * T, 6 * T, 12 * T)          # rocha da esquerda: x0, x1 do topo plano, y do topo
R2_MEIO = (12 * T + 40, 17 * T, 11 * T)   # rocha-arco
BALSA2 = (23 * T, 6 * T + 20)             # x, largura (convés no nível 13)
LANCA2 = 1 * T                            # altura da lança da grua


def c2_palco():
    o = ""
    rx0, rx1, ry = R2_ESQ
    mx0, mx1, my = R2_MEIO
    bx, bw = BALSA2
    # ---- FIXO: rochas com topo plano medido (o que se pisa é o topo)
    o += rocha2([(rx0 - 40, H), (rx0 - 20, ry + 50), (rx0 + 10, ry), (rx1 - 10, ry), (rx1 + 30, ry + 60), (rx1 + 10, H)], rx0 + 10, rx1 - 10, ry, 3)
    o += rocha2([(mx0 - 30, H), (mx0 - 10, my + 50), (mx0 + 20, my), (mx1 - 20, my), (mx1 + 20, my + 60), (mx1 + 10, H)], mx0 + 20, mx1 - 20, my, 7)
    o += f'<path d="M{mx0 + 60},{H} q{(mx1 - mx0 - 120) / 2},-150 {mx1 - mx0 - 120},0" fill="#174a5a"/>'   # vão do arco
    o += balsa(bx, bw)
    tx = bx + bw - 34                     # torre da grua presa na ponta direita da balsa
    o += R(tx, LANCA2, 26, 13 * T - LANCA2, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(11):
        y = LANCA2 + 20 + k * 64
        o += f'<path d="M{tx},{y} l26,40 M{tx + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(3 * T, LANCA2 - 14, tx - 3 * T + 40, 20, "#e0a83a", 3, 1.4) + R(tx - 30, LANCA2 - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += f'<path d="M{tx + 13},{LANCA2 - 60} L{3 * T + 20},{LANCA2 - 14}" stroke="#b07a1e" stroke-width="3"/>'   # tirante da lança
    o += sign(bx + 30, 13 * T - 60, "BOTA-ABAIXO", 170)
    # coqueiro enraizado no topo da rocha da esquerda (quina esquerda)
    o += f'<path d="M{rx0 + 24},{ry} q-26,-120 40,-230" stroke="#8a6b4f" stroke-width="16" fill="none"/>'
    for a in range(5):
        ang = -2.7 + a * 0.5
        o += f'<path d="M{rx0 + 64},{ry - 230} q{math.cos(ang) * 50},{math.sin(ang) * 26 - 26} {math.cos(ang) * 110},{math.sin(ang) * 56 + 20}" stroke="#4f9a52" stroke-width="14" fill="none" stroke-linecap="round"/>'
    # ---- QUEBRA: pilha de 2 contêineres na rocha da esquerda; carga derramada (pneus e caixa) NO TOPO da rocha, ao lado
    c_x = rx0 + 50
    o += conteiner(c_x, ry - T, 3 * T, T, CONT[2], 0, True)
    o += conteiner(c_x + 16, ry - 2 * T, 3 * T - 16, T, CONT[0], 1)
    o += f'<rect x="{c_x + 3 * T - 34}" y="{ry - T + 8}" width="28" height="{T - 16}" fill="#1e1e24"/>'   # portas abertas (vão escuro)
    o += pneu_deitado(c_x + 3 * T + 30, ry) + pneu_deitado(c_x + 3 * T + 30, ry - 24)
    # ---- QUEBRA: bote virado e jangada boiando no vão entre as rochas
    o += PL([(6 * T + 50, MAR2 - 44), (9 * T + 10, MAR2 - 44), (8 * T + 50, MAR2 + 6), (7 * T, MAR2 + 6)], "#f08a3d", 1.4)
    o += R(6 * T + 50, MAR2 - 50, 2 * T + 24, 10, "#d9dce4", 2, 0.8)
    for k in range(3):
        o += R(9 * T + 50 + k * 34, MAR2 - 28, 30, 30, "#c98a4b", 2, 0.8)
    o += R(9 * T + 40, MAR2 - 34, 110, 10, "#b07a3e", 2, 0.8)
    # ---- QUEBRA: pedaço do convés (nível 8) sobre DUAS escoras que pisam no topo da rocha-arco
    dk0, dk1, dky = 11 * T + 20, 18 * T + 20, 8 * T
    o += R(mx0 + 60, dky + 56, 20, my - dky - 56, "#4a2620", 2, 1.0) + R(mx1 - 80, dky + 56, 20, my - dky - 56, "#4a2620", 2, 1.0)
    o += R(dk0, dky, dk1 - dk0, 26, "#6b6f7a", 2, 1.6, dark="#4a4f5a") + R(dk0, dky + 26, dk1 - dk0, 30, "#9a4a38", 2, 1.4, dark="#7a3424")
    o += zebra(dk0, dky - 6, dk1 - dk0, 8)
    for x in range(int(dk0 + 10), int(dk1), 44):
        o += f'<path d="M{x},{dky - 6} v-30" stroke="#e9e2d2" stroke-width="4"/>'
    o += f'<path d="M{dk0},{dky - 30} H{dk1}" stroke="#e9e2d2" stroke-width="4"/>'
    o += E(16 * T + 30, dky - 14, 18, 14, "#5a5f6a", 0.8)   # cabrestante
    # ---- QUEBRA: mastro-ponte com as DUAS pontas apoiadas: topo do contêiner de cima → convés
    ax, ay = c_x + 3 * T - 30, ry - 2 * T
    bx2, by2 = dk0 + 30, dky
    ang = math.degrees(math.atan2(by2 - ay, bx2 - ax))
    comp = math.hypot(bx2 - ax, by2 - ay)
    o += f'<g transform="translate({ax},{ay}) rotate({ang:.2f})">' + R(0, -18, comp, 18, "#9a9aa8", 3, 1.4, dark="#6b6b7a") + "</g>"
    # ---- QUEBRA: içados na lança (contêiner à esquerda, rede de carga no centro)
    cx0, cx1, cy = 4 * T, 7 * T, 5 * T
    o += icado((cx0 + cx1) / 2, LANCA2 + 6, cy - 70, cx0, cx1, cy) + conteiner(cx0, cy, cx1 - cx0, T - 8, CONT[5], 0, True)
    nx0, nx1, ny = 12 * T, 15 * T, 4 * T + 40
    o += f'<path d="M{(nx0 + nx1) / 2},{LANCA2 + 6} V{ny - 50}" stroke="{INK}" stroke-width="4"/>' + gancho((nx0 + nx1) / 2, ny - 50)
    for k in range(3):
        o += R(nx0 + 10 + k * 62, ny, 58, 50, "#c98a4b" if k != 1 else "#b07a3e", 3, 1.0)
    o += f'<path d="M{nx0},{ny - 6} Q{(nx0 + nx1) / 2},{ny + 110} {nx1},{ny - 6}" stroke="#5a4a3a" stroke-width="4" fill="none"/>'
    o += f'<path d="M{(nx0 + nx1) / 2},{ny - 36} L{nx0},{ny - 6} M{(nx0 + nx1) / 2},{ny - 36} L{nx1},{ny - 6}" stroke="#5a4a3a" stroke-width="3"/>'
    for k in range(6):
        o += f'<path d="M{nx0 + 8 + k * 32},{ny - 4} l18,56" stroke="#5a4a3a" stroke-width="3"/>'
    # ---- QUEBRA: tábuas penduradas por dois cabos nas PONTAS — nível 9 (arco → balsa) e nível 5 (alto à direita)
    t1x0, t1x1 = 18 * T + 20, 23 * T - 10
    o += pendurada(t1x0, t1x1, 9 * T, LANCA2 + 6, LANCA2 + 6) + tabua(t1x0, 9 * T, t1x1 - t1x0)
    t2x0, t2x1 = 21 * T, tx - 10
    o += pendurada(t2x0, t2x1, 5 * T, LANCA2 + 6, LANCA2 + 6) + tabua(t2x0, 5 * T, t2x1 - t2x0)
    # ---- QUEBRA: contêineres sobre o convés da balsa (2 embaixo, 1 em cima), sem invadir a torre
    o += conteiner(bx + 20, 12 * T, 3 * T, T, CONT[1], 0, True) + conteiner(bx + 20 + 3 * T + 6, 12 * T, tx - (bx + 20 + 3 * T + 6) - 8, T, CONT[3], 1)
    o += conteiner(bx + 40, 11 * T, 3 * T - 10, T, CONT[6], 2)
    # ---- vida: caranguejos e gaivota pousados em superfícies
    o += caranguejo(mx0 + 120, my) + caranguejo(17 * T - 40, 8 * T - 6)
    o += gaivota(bx + 40 + 3 * T - 30, 11 * T, 1.2, True)
    return o


def c2_atores():
    rx0, rx1, ry = R2_ESQ
    o = robot("pa", "pesado_prep", el.COLORS[4], rx0 + 50 + 70, ry - 2 * T)                 # em cima do contêiner de cima
    o += robot("marretao", "rapido", el.COLORS[0], 14 * T + 20, 8 * T - 6)                  # no convés (por cima da fita)
    o += robot("chave", "esquiva", el.COLORS[2], 13 * T + 40, 4 * T + 40, flip=True)        # nas caixas da rede
    o += robot("britadeira", "pesado_golpe", el.COLORS[3], 7 * T + 70, MAR2 - 50)           # na quilha do bote virado
    o += f'<path d="M{13 * T - 30},{4 * T + 10} h-50 M{13 * T - 24},{4 * T + 24} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.85"/>'
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
    o += tag(3 * T + 20, 13 * T + 40, "ROCHA (FIXA)") + tag(15 * T, 12 * T + 40, "ROCHA-ARCO (FIXA)") + tag(26 * T, 14 * T + 10, "BALSA (FIXA)")
    o += tag(5 * T + 10, 12 * T + 34, "CARGA DERRAMADA") + tag(9 * T + 30, 9 * T + 40, "MASTRO-PONTE") + tag(14 * T + 40, 9 * T + 20, "PEDAÇO DO CONVÉS")
    o += tag(8 * T, MAR2 - 90, "BOTE VIRADO") + tag(10 * T + 30, MAR2 + 50, "JANGADA") + tag(13 * T + 32, 6 * T + 30, "REDE DE CARGA")
    o += tag(5 * T + 32, 6 * T + 20, "CONTÊINER IÇADO") + tag(20 * T + 40, 9 * T + 50, "TÁBUA") + tag(24 * T + 20, 5 * T + 50, "TÁBUA ALTA")
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
    # laje-ponte (nível 9): coluna no pilar esquerdo + coluna curta na quina do pilar central (as duas pontas apoiadas)
    o += coluna2(6 * T - 40, 9 * T + 34, 12 * T - 14) + coluna2(12 * T + 4, 9 * T + 34, 11 * T - 14, larg=40)
    o += laje2(5 * T + 10, 9 * T, 12 * T + 54 - (5 * T + 10)) + alga(7 * T, 9 * T + 34, 2, 110)
    # ---- QUEBRA (esquerda alta): coluna no pilar segura uma laje no nível 6
    o += coluna2(1 * T + 30, 6 * T + 34, 12 * T - 14 - 104) + laje2(0 * T + 30, 6 * T, 5 * T) + alga(2 * T, 6 * T + 34, 2, 90)
    # ---- QUEBRA (centro alto): colunas curtas sobre a laje do centro seguram uma laje no nível 4
    o += coluna2(13 * T + 10, 4 * T + 34, 7 * T) + coluna2(16 * T + 20, 4 * T + 34, 7 * T) + laje2(12 * T + 30, 4 * T, 5 * T)
    # ---- QUEBRA (direita, meio): bloco de mármore pendurado na corrente da proa (nível 9) e prancha do navio presa no alto (nível 3)
    # bloco de mármore pendurado pela corrente que sai da PONTA da proa (1451,136) — sem girar
    px, py = 1451, 136
    o += f'<path d="M{px},{py} V{9 * T}" stroke="#5a5f6a" stroke-width="6" stroke-dasharray="12 6"/>' + gancho(px, 9 * T - 6)
    o += f'<path d="M{px},{9 * T + 8} L{px - 80},{9 * T + 20} M{px},{9 * T + 8} L{px + 80},{9 * T + 20}" stroke="#5a5f6a" stroke-width="4"/>'
    o += R(px - 96, 9 * T + 20, 192, 40, MARM, 4, 1.6, dark=MARM_D) + R(px - 96, 9 * T + 50, 192, 10, OURO, 2, 0.6)
    # prancha do navio pendurada por duas correntes presas na ARMAÇÃO DOURADA da cúpula (pontos medidos no arco)
    o += pendurada(1146, 1414, 3 * T, 51, 144, inset=14) + tabua(1146, 3 * T, 268)
    # ---- QUEBRA (centro): duas colunas seguram a laje (nível 7); concha-trampolim no pilar
    o += coluna2(12 * T + 70, 7 * T + 34, 11 * T - 14, rachada=True) + coluna2(17 * T - 90, 7 * T + 34, 11 * T - 14)
    o += laje2(11 * T + 20, 7 * T, 7 * T) + alga(16 * T, 7 * T + 34, 3, 120)
    o += E(15 * T, 11 * T - 30, 48, 18, "#f2a7c3", 1.2) + f'<path d="M{15 * T - 48},{11 * T - 34} a48,40 0 0 1 96,-28" fill="#f7c6d8" stroke="#d1708f" stroke-width="4"/>'
    o += E(15 * T, 11 * T - 36, 10, 8, "#ffffff", 0.6)
    # ---- QUEBRA: lustre dourado pendurado na cúpula por corrente (nível 4), balança
    o += f'<path d="M660,79 L{10 * T + 20},{3 * T + 30}" stroke="{OURO_D}" stroke-width="5" stroke-dasharray="10 6"/>' + f'<circle cx="660" cy="79" r="8" fill="{OURO}"/>'
    o += f'<path d="M{10 * T + 20},{3 * T + 30} L{8 * T + 60},{4 * T} M{10 * T + 20},{3 * T + 30} L{11 * T + 40},{4 * T}" stroke="{OURO_D}" stroke-width="4"/>'
    o += f'<g transform="rotate(0 {10 * T + 20} {4 * T})">'
    o += R(8 * T + 40, 4 * T, 3 * T + 20, 18, OURO, 3, 1.2, dark=OURO_D)
    o += f'<path d="M{8 * T + 50},{4 * T + 18} Q{10 * T + 20},{5 * T + 40} {11 * T + 50},{4 * T + 18}" stroke="{OURO}" stroke-width="8" fill="none"/>'
    for k in range(5):
        o += f'<circle cx="{8 * T + 60 + k * 40}" cy="{4 * T - 10}" r="8" fill="#fff6c8"/><circle cx="{8 * T + 60 + k * 40}" cy="{4 * T - 10}" r="20" fill="#fff6c8" opacity="0.25"/>'
    o += "</g>"
    o += f'<path d="M{8 * T + 20},{4 * T + 30} q-16,0 -24,12 M{11 * T + 80},{4 * T + 10} q16,0 24,12" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.9"/>'
    # ---- QUEBRA (direita, alagada): contêiner do navio derramando moedas + baú; coluna alta com laje (nível 6)
    # pilar da direita: coluna E e coluna D seguram a laje alta (nível 6); entre elas, o contêiner com o baú em cima e moedas
    o += coluna2(24 * T + 14, 6 * T + 34, 12 * T - 14) + coluna2(28 * T + 14, 6 * T + 34, 12 * T - 14)
    o += laje2(23 * T, 6 * T, 29 * T + 40 - 23 * T) + alga(25 * T + 20, 6 * T + 34, 3, 130)
    o += conteiner(25 * T, 12 * T - 14 - T, 2 * T + 40, T, CONT[3], 2, True)
    o += R(25 * T + 30, 12 * T - 14 - T - 46, 70, 46, "#8a5a3a", 4, 1.0) + R(25 * T + 30, 12 * T - 14 - T - 46, 70, 12, OURO, 2, 0.6)
    for k in range(9):   # moedas caídas no topo do pilar
        o += E(27 * T + 50 + k * 10, 12 * T - 18 - (k % 3) * 6, 8, 4, OURO, 0.5)
    # ---- águas-vivas brilhando (nadam: não precisam de apoio)
    for x, y, c in [(3 * T, 4 * T, "#ff9ad8"), (20 * T, 3 * T, "#9ad8ff"), (7 * T, 6 * T + 20, "#c8a0ff")]:
        o += f'<circle cx="{x}" cy="{y}" r="40" fill="{c}" opacity="0.18"/>' + f'<path d="M{x - 22},{y} a22,18 0 0 1 44,0 Z" fill="{c}" opacity="0.85"/>'
        for j in range(4):
            o += f'<path d="M{x - 15 + j * 10},{y} q-4,20 4,40" stroke="{c}" stroke-width="3" fill="none" opacity="0.8"/>'
    return o


def c3_grua():
    """Grua submarina da equipe (identidade da obra) presa no pilar da esquerda, com holofote."""
    x = 5 * T + 20
    o = R(x, 1 * T + 40, 22, (12 * T - 14) - (1 * T + 40), "#e0a83a", 3, 1.4, dark="#b07a1e")
    for k in range(9):
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
    o += tag(10 * T + 20, 5 * T + 50, "LUSTRE DOURADO") + tag(2 * T + 40, 5 * T + 30, "LAJE ALTA") + tag(15 * T, 3 * T + 30, "LAJE DO TOPO")
    o += tag(1451, 10 * T + 20, "BLOCO NA CORRENTE") + tag(1280, 2 * T + 30, "PRANCHA DO NAVIO") + tag(2 * T, 10 * T + 10, "TAMBORES") + tag(4 * T + 40, 12 * T + 40, "CABEÇA DE ESTÁTUA")
    o += tag(15 * T, 12 * T - 100, "CONCHA") + tag(26 * T + 20, 12 * T + 50, "BAÚ E MOEDAS") + tag(25 * T + 40, 2 * T + 60, "PROA FUROU A CÚPULA")
    o += tag(25 * T + 20, 9 * T + 50, "ALAGANDO") + tag(9 * T, H - 34, "FENDA = KO") + tag(21 * T, H - 34, "FENDA = KO")
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
