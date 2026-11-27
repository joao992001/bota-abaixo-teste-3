"""Elenco novo (2026-11-24, pedido do usuário): 5 robôs de demolição com silhueta, ferramenta e golpes próprios.
Mesmo estilo papel e giz (formas chapadas, textura de giz, sem contorno), mas DE PERFIL (olham para onde andam) e
batendo com as DUAS mãos / o corpo todo. As regras do golpe são iguais para todos; só o visual muda.

Esqueleto de recorte: quadril → tronco (inclinação) → ombros/cabeça; pernas e braços de 2 segmentos resolvidos por IK
(pés e pegadas da ferramenta são alvos). Este mesmo esqueleto e estas poses vão para a Godot depois da aprovação.
Unidades = px de jogo, pés na origem, virado para a direita (+x), y para baixo.
Rodar: python3 art/src/robos/elenco.py  → art/out/prancha_elenco5.png
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from papel import ellipse_d, rect_d, rough, shape  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
SRC = os.path.join(ROOT, "art/src/robos/svg")
INK = "#2a1a2e"
COLORS = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b", "#f08a3d"]
STEEL, STEEL_D, STEEL_L = "#9aa4ae", "#6b7783", "#c9d1d8"
WOOD, WOOD_D = "#c98a4b", "#8a5a2b"
GLOVE, GLOVE_D = "#f4f1ea", "#c9c2b4"
YEL, YEL_D = "#f2c84b", "#c49a2a"
_n = [0]


def sid():
    _n[0] += 1
    return f"e{_n[0]}"


def S(d, fill, box, k=0.9, **kw):
    """Forma de giz (k pequeno: a peça é desenhada em px de jogo e a prancha amplia)."""
    return shape(sid(), d, fill, _n[0] * 7 + 3, box, k=k, **kw)


# ---------------------------------------------------------------- geometria
def rot(p, a):
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c)


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def ik(root, target, a, b, prefer):
    """Junta do meio de 2 segmentos (a, b) indo de root a target. prefer(cand) -> pontuação (maior vence)."""
    dx, dy = target[0] - root[0], target[1] - root[1]
    d = max(min(math.hypot(dx, dy), a + b - 0.01), abs(a - b) + 0.01)
    th = math.atan2(dy, dx)
    al = math.acos(max(-1.0, min(1.0, (a * a + d * d - b * b) / (2 * a * d))))
    c1 = (root[0] + math.cos(th + al) * a, root[1] + math.sin(th + al) * a)
    c2 = (root[0] + math.cos(th - al) * a, root[1] + math.sin(th - al) * a)
    end = (root[0] + math.cos(th) * d, root[1] + math.sin(th) * d)
    return (c1 if prefer(c1) >= prefer(c2) else c2), end


def capsule_d(p, q, w):
    ang = math.atan2(q[1] - p[1], q[0] - p[0])
    nx, ny = -math.sin(ang) * w / 2, math.cos(ang) * w / 2
    r = w / 2
    return (f"M{p[0] + nx:.2f},{p[1] + ny:.2f} L{q[0] + nx:.2f},{q[1] + ny:.2f} "
            f"A{r:.2f},{r:.2f} 0 0 0 {q[0] - nx:.2f},{q[1] - ny:.2f} L{p[0] - nx:.2f},{p[1] - ny:.2f} "
            f"A{r:.2f},{r:.2f} 0 0 0 {p[0] + nx:.2f},{p[1] + ny:.2f} Z")


def limb(p, q, w, col):
    box = (min(p[0], q[0]) - w, min(p[1], q[1]) - w, max(p[0], q[0]) + w, max(p[1], q[1]) + w)
    return S(capsule_d(p, q, w), col, box, k=0.6)


def poly_d(pts):
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts) + " Z"


def glove(p, r, back=False):
    col = GLOVE_D if back else GLOVE
    return (S(ellipse_d(p[0], p[1], r, r * 0.92), col, (p[0] - r - 1, p[1] - r - 1, p[0] + r + 1, p[1] + r + 1), k=0.5)
            + f'<path d="M{p[0] - r * 0.5:.1f},{p[1] - r * 0.3:.1f} h{r:.1f}" stroke="{GLOVE_D}" stroke-width="{r * 0.25:.2f}" stroke-linecap="round"/>')


def boot(p, w, h, col, forward=1.0):
    x, y = p
    d = (f"M{x - w * 0.35:.1f},{y - h:.1f} C{x - w * 0.5:.1f},{y - h:.1f} {x - w * 0.5:.1f},{y:.1f} {x - w * 0.3:.1f},{y:.1f} "
         f"L{x + w * 0.65 * forward:.1f},{y:.1f} C{x + w * 0.75 * forward:.1f},{y:.1f} {x + w * 0.75 * forward:.1f},{y - h * 0.9:.1f} {x + w * 0.3 * forward:.1f},{y - h:.1f} Z")
    return S(d, col, (x - w, y - h - 1, x + w, y + 1), k=0.6)


# ---------------------------------------------------------------- personagens
# Cada um: hip_h (altura do quadril), torso(c, expr) desenhado no espaço do tronco (origem no quadril, -y para cima),
# ombros/quadris no tronco, braço (a, b, w), perna (a, b, w, dobra), mão, ferramenta (desenho no espaço da pegada
# da frente, +x para a cabeça da ferramenta) e pegadas.

# Expressões: as da prancha (ataque, forca, grito, esquiva) e as do jogo (normal, piscar, esforco, susto, vitoria, eliminado).
ANGRY = ("ataque", "forca", "grito", "esforco")


def face_eye(x, y, r, expr, lens=False):
    out = []
    if lens:
        out.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}"/>')
        if expr == "eliminado":
            out.append(f'<path d="M{x - r * 0.6:.1f},{y - r * 0.6:.1f} L{x + r * 0.6:.1f},{y + r * 0.6:.1f} M{x + r * 0.6:.1f},{y - r * 0.6:.1f} L{x - r * 0.6:.1f},{y + r * 0.6:.1f}" stroke="#9ff7c8" stroke-width="{r * 0.35:.2f}" stroke-linecap="round"/>')
        elif expr == "piscar":
            out.append(f'<path d="M{x - r * 0.8:.1f},{y:.1f} h{r * 1.6:.1f}" stroke="#9ff7c8" stroke-width="{r * 0.3:.2f}" stroke-linecap="round"/>')
        elif expr == "vitoria":
            out.append(f'<path d="M{x - r * 0.6:.1f},{y + r * 0.2:.1f} Q{x:.1f},{y - r * 0.8:.1f} {x + r * 0.6:.1f},{y + r * 0.2:.1f}" stroke="#9ff7c8" stroke-width="{r * 0.35:.2f}" fill="none" stroke-linecap="round"/>')
        else:
            pr = r * (0.3 if expr == "susto" else 0.55)
            out.append(f'<circle cx="{x + r * 0.25}" cy="{y}" r="{pr:.2f}" fill="#9ff7c8"/><circle cx="{x}" cy="{y - r * 0.35}" r="{r * 0.25}" fill="#ffffff"/>')
    elif expr == "piscar":
        out.append(f'<path d="M{x - r * 0.9:.1f},{y:.1f} h{r * 1.8:.1f}" stroke="{INK}" stroke-width="{r * 0.4:.2f}" stroke-linecap="round"/>')
    elif expr == "vitoria":
        out.append(f'<path d="M{x - r * 0.8:.1f},{y + r * 0.3:.1f} Q{x:.1f},{y - r:.1f} {x + r * 0.8:.1f},{y + r * 0.3:.1f}" stroke="{INK}" stroke-width="{r * 0.42:.2f}" fill="none" stroke-linecap="round"/>')
    elif expr == "eliminado":
        out.append(f'<path d="M{x - r * 0.7:.1f},{y - r * 0.7:.1f} L{x + r * 0.7:.1f},{y + r * 0.7:.1f} M{x + r * 0.7:.1f},{y - r * 0.7:.1f} L{x - r * 0.7:.1f},{y + r * 0.7:.1f}" stroke="{INK}" stroke-width="{r * 0.42:.2f}" stroke-linecap="round"/>')
    else:
        big = expr == "susto"
        ry = r * (0.45 if expr in ("esquiva", "forca", "esforco") else (1.15 if big else 1.0))
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r * (1.05 if big else 0.9):.2f}" ry="{ry:.2f}" fill="#ffffff"/>')
        pr = 0.3 if big else 0.45
        out.append(f'<ellipse cx="{x + r * 0.35:.2f}" cy="{y + 0.2:.2f}" rx="{r * pr:.2f}" ry="{min(ry, r * (pr + 0.1)):.2f}" fill="{INK}"/>')
    if expr in ANGRY:
        out.append(f'<path d="M{x - r * 1.1:.1f},{y - r * 1.5:.1f} L{x + r * 1.1:.1f},{y - r * 0.9:.1f}" stroke="{INK}" stroke-width="{r * 0.45:.2f}" stroke-linecap="round"/>')
    return "".join(out)


def mouth(x, y, w, expr):
    if expr in ("grito", "vitoria"):
        return f'<path d="M{x - w * 0.5:.1f},{y - w * 0.2:.1f} Q{x:.1f},{y - w * 0.35:.1f} {x + w * 0.5:.1f},{y - w * 0.25:.1f} Q{x + w * 0.3:.1f},{y + w * 0.7:.1f} {x - w * 0.4:.1f},{y + w * 0.4:.1f} Z" fill="#7a2232"/>'
    if expr in ("ataque", "forca", "esforco"):
        return f'<path d="M{x - w * 0.45:.1f},{y:.1f} h{w * 0.9:.1f}" stroke="{INK}" stroke-width="{w * 0.18:.2f}" stroke-linecap="round"/>' + \
            f'<path d="M{x - w * 0.3:.1f},{y - w * 0.12:.1f} v{w * 0.24:.1f} M{x:.1f},{y - w * 0.12:.1f} v{w * 0.24:.1f} M{x + w * 0.3:.1f},{y - w * 0.12:.1f} v{w * 0.24:.1f}" stroke="{INK}" stroke-width="{w * 0.06:.2f}"/>'
    if expr in ("esquiva", "susto"):
        return f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{w * 0.18:.1f}" ry="{w * 0.24:.1f}" fill="#7a2232"/>'
    if expr == "eliminado":
        return f'<path d="M{x - w * 0.45:.1f},{y:.1f} q{w * 0.15:.1f},{-w * 0.2:.1f} {w * 0.3:.1f},0 q{w * 0.15:.1f},{w * 0.2:.1f} {w * 0.3:.1f},0 q{w * 0.15:.1f},{-w * 0.2:.1f} {w * 0.3:.1f},0" stroke="{INK}" stroke-width="{w * 0.13:.2f}" fill="none" stroke-linecap="round"/>'
    return f'<path d="M{x - w * 0.4:.1f},{y - w * 0.1:.1f} Q{x:.1f},{y + w * 0.35:.1f} {x + w * 0.45:.1f},{y - w * 0.15:.1f}" stroke="{INK}" stroke-width="{w * 0.15:.2f}" fill="none" stroke-linecap="round"/>'


# Cabeças em 3 camadas: L = "base" (forma), "face" (rosto, troca com a expressão), "acc" (antena/giroflex que balança), "all".
def _L(L, *want):
    return L == "all" or L in want


# 1 MARRETÃO — brutamontes: tronco em trapézio largo, cabeça pequena de capacete com viseira, braços de pistão, botas.
def t_marretao(c, e):
    """Marretão no estilo aprovado A27 (Ultimate Chicken Horse): corpinho de pera com cinto de perigo (robo_uch.py)."""
    import robo_uch as ru
    return ru.tronco(c, {})


def h_marretao(c, e, L="all"):
    import robo_uch as ru
    return ru.cabeca_L(c, e, L)


def tool_marreta():
    import conceito3_blindado as cb3
    return cb3.marreta_cabo() + cb3.marreta_cabeca()


# 2 PICARETA — magrelo de pernas de pássaro (joelho para trás), pescoço longo, cabeça oval com 1 lente.
def t_picareta(c, e):
    out = S("M-9,-2 C-12,-12 -10,-30 0,-32 C10,-32 12,-14 8,-2 C4,2 -6,2 -9,-2 Z", c, (-13, -34, 13, 3), k=0.6)
    out += f'<rect x="-2" y="-24" width="9" height="5" rx="1.5" fill="{YEL}"/><circle cx="4.5" cy="-21.5" r="1.2" fill="#d14d35"/>'
    return out


def h_picareta(c, e, L="all"):
    out = ""
    if _L(L, "acc"):
        out += f'<path d="M-2,-29 C-4,-34 -1,-37 2,-37" stroke="{STEEL_D}" stroke-width="1.4" fill="none"/><circle cx="2" cy="-37.5" r="2" fill="{YEL}"/>'
    if _L(L, "base"):
        out += f'<path d="M0,0 C1,-6 -1,-10 1,-15" stroke="{shade(c, -0.5)}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
        out += S("M-9,-16 C-10,-26 0,-30 7,-28 C14,-26 16,-18 12,-13 C8,-9 -6,-9 -9,-16 Z", c, (-11, -31, 16, -8), k=0.5)
        out += f'<circle cx="7" cy="-19.5" r="5.2" fill="{STEEL_D}"/>'
    if _L(L, "face"):
        out += face_eye(7, -19.5, 3.6, e, lens=True)
        if e in ANGRY:
            out += f'<path d="M2,-25 L12,-23" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>'
        if e in ("grito", "susto", "vitoria", "eliminado"):
            out += mouth(9, -12, 5, e)
    return out


def tool_picareta():
    out = S(rect_d(-16, -1.8, 50, 3.6, 1.8), WOOD, (-17, -3, 35, 3), k=0.5, dark=WOOD_D)
    out += S("M33,-3 C40,-6 48,-13 52,-22 C50,-12 44,-4 37,1 L37,4 C44,8 50,16 52,26 C46,17 40,10 33,6 Z", STEEL, (32, -23, 53, 27), k=0.6, dark=STEEL_D, light=STEEL_L)
    out += f'<rect x="31" y="-4" width="7" height="8" rx="2" fill="{STEEL_D}"/>'
    return out


# 3 CHAVE — mecânico: tronco de caixa de ferramentas com macacão, cabeça de porca sextavada com boné virado.
def t_chave(c, e):
    out = S(rect_d(-15, -30, 30, 30, 5), c, (-16, -31, 16, 1), k=0.7)
    out += S(rect_d(-15, -12, 30, 12, 4), "#3e5a8a", (-16, -13, 16, 1), k=0.5)
    out += f'<path d="M-10,-12 L-8,-30 M10,-12 L8,-30" stroke="#3e5a8a" stroke-width="3"/>'
    out += f'<rect x="-11" y="-14" width="5" height="4" rx="1" fill="{YEL}"/><rect x="6" y="-14" width="5" height="4" rx="1" fill="{YEL}"/>'
    out += f'<rect x="0" y="-24" width="9" height="7" rx="1.5" fill="{GLOVE}"/><path d="M2,-21 h5" stroke="{INK}" stroke-width="1"/>'
    return out


def h_chave(c, e, L="all"):
    out = ""
    if _L(L, "acc"):
        out += f'<circle cx="-2" cy="-26.5" r="2.2" fill="#a33a26"/>'
    if _L(L, "base"):
        pts = [(math.cos(math.radians(a)) * 12, -12 + math.sin(math.radians(a)) * 12) for a in range(0, 360, 60)]
        out += S(poly_d(pts), c, (-13, -25, 13, 1), k=0.5)
        out += f'<circle cx="-4" cy="-12" r="4.5" fill="{shade(c, -0.25)}"/>'
        out += S("M-11,-20 C-9,-27 5,-28 9,-21 L-13,-19 Z", "#d14d35", (-14, -28, 10, -18), k=0.4)
        out += S("M-11,-21 L-20,-19 L-12,-18 Z", "#a33a26", (-21, -22, -10, -17), k=0.3)
    if _L(L, "face"):
        out += face_eye(3, -12, 2.6, e) + face_eye(9.5, -12.3, 2.3, e)
        if e in ("grito", "susto", "vitoria", "eliminado"):
            out += mouth(7, -5, 5, e)
        elif e in ANGRY:
            out += f'<path d="M3,-5.5 C6,-7 9,-7 11,-5.5" stroke="{INK}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
        else:
            out += f'<path d="M3,-6 C6,-4.5 9,-4.5 11,-6.5" stroke="{INK}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
    return out


def tool_chave():
    out = S(rect_d(-14, -3, 46, 6, 3), STEEL, (-15, -4, 33, 4), k=0.5, dark=STEEL_D, light=STEEL_L)
    out += S("M30,-8 C36,-14 46,-13 49,-6 L42,-4 L42,4 L49,6 C46,13 36,14 30,8 Z", STEEL, (29, -15, 50, 15), k=0.6, dark=STEEL_D, light=STEEL_L)
    out += f'<path d="M-6,-1 h26" stroke="{STEEL_D}" stroke-width="1.4"/><rect x="-14" y="-4" width="9" height="8" rx="2" fill="#d14d35"/>'
    return out


# 4 BRITADEIRA — baixinho de barril, cabeção de capacete com óculos de proteção, pernas curtas.
def t_brit(c, e):
    out = S(ellipse_d(0, -14, 17, 15), c, (-18, -30, 18, 2), k=0.6)
    out += f'<path d="M-16,-10 C-6,-6 6,-6 16,-10" stroke="{shade(c, -0.3)}" stroke-width="2.4" fill="none"/>'
    out += f'<path d="M-16,-19 C-6,-15 6,-15 16,-19" stroke="{shade(c, -0.3)}" stroke-width="2.4" fill="none"/>'
    return out


def h_brit(c, e, L="all"):
    out = ""
    if _L(L, "acc"):
        out += f'<rect x="0" y="-31" width="5" height="4" rx="1" fill="{STEEL_D}"/><circle cx="2.5" cy="-31" r="2.4" fill="#fff1b8"/>'
    if _L(L, "base"):
        out += S(ellipse_d(2, -13, 15, 14), c, (-14, -28, 18, 2), k=0.5)
        out += S("M-14,-15 C-14,-30 18,-30 18,-15 Z", YEL, (-15, -30, 19, -14), k=0.5, dark=YEL_D)
        out += f'<rect x="-16" y="-16.5" width="36" height="3" rx="1.5" fill="{YEL_D}"/>'
        out += f'<rect x="-6" y="-13" width="26" height="4" rx="2" fill="{INK}"/>'
        for x in (6, 15):
            out += f'<circle cx="{x}" cy="-9" r="5" fill="{STEEL_D}"/><circle cx="{x}" cy="-9" r="3.6" fill="#cdeff7"/>'
    if _L(L, "face"):
        for x in (6, 15):
            if e == "piscar":
                out += f'<path d="M{x - 2.4},-9 h4.8" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>'
            elif e == "vitoria":
                out += f'<path d="M{x - 2},-8.4 Q{x},-11.4 {x + 2},-8.4" stroke="{INK}" stroke-width="1.3" fill="none"/>'
            elif e == "eliminado":
                out += f'<path d="M{x - 1.8},-10.8 L{x + 1.8},-7.2 M{x + 1.8},-10.8 L{x - 1.8},-7.2" stroke="{INK}" stroke-width="1.2"/>'
            else:
                sq = 0.5 if e in ("forca", "esquiva", "esforco") else 1.0
                r = 1.1 if e == "susto" else 1.6
                out += f'<ellipse cx="{x + 1}" cy="-9" rx="{r}" ry="{1.8 * sq * r / 1.6:.1f}" fill="{INK}"/>'
        if e in ANGRY:
            out += f'<path d="M2,-15 L19,-13" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>'
        out += mouth(10, -1, 7, e)
    return out


def tool_brit():
    # britadeira: barra em T na pegada (perpendicular), corpo, ponteiro. +x = ponteiro
    out = S(rect_d(-2, -11, 5, 22, 2.5), INK, (-3, -12, 4, 12), k=0.4)
    out += S(rect_d(2, -6, 24, 12, 4), YEL, (1, -7, 27, 7), k=0.6, dark=YEL_D)
    out += f'<rect x="8" y="-6" width="3" height="12" fill="{INK}"/><rect x="15" y="-6" width="3" height="12" fill="{INK}"/>'
    out += S(rect_d(26, -4, 6, 8, 1.5), STEEL_D, (25, -5, 33, 5), k=0.4)
    out += S("M32,-2 L42,-1.2 L45,0 L42,1.2 L32,2 Z", STEEL, (31, -3, 46, 3), k=0.4, light=STEEL_L)
    return out


# 5 PÁ — operário de máquina pesada: cabeça de cabine (rosto na janelinha, giroflex), escapamento nas costas,
# pistões hidráulicos nas pernas, pá enorme (finca no chão para saltar).
def t_pa(c, e):
    out = S(rect_d(-7, -44, 5, 20, 2), STEEL_D, (-8, -45, -1, -23), k=0.3)
    out += f'<circle cx="-4.5" cy="-46" r="2.6" fill="#8a8a8a" opacity="0.7"/>'
    out += S("M-12,-2 C-15,-14 -15,-30 -11,-36 L11,-36 C15,-30 15,-14 12,-2 C6,1 -6,1 -12,-2 Z", c, (-16, -37, 16, 2), k=0.7)
    out += f'<rect x="-13" y="-13" width="26" height="5" fill="{YEL}"/>'
    for i in range(4):
        out += f'<path d="M{-11 + i * 7},-8 l4,-5 l3,0 l-4,5 Z" fill="{INK}"/>'
    out += f'<circle cx="6" cy="-26" r="3.2" fill="{shade(c, -0.35)}"/><circle cx="6" cy="-26" r="1.3" fill="{STEEL_L}"/>'
    return out


def h_pa(c, e, L="all"):
    out = ""
    if _L(L, "acc"):
        on = "#ff8a3a" if e in ("forca", "grito") else "#f08a3d"
        out += f'<rect x="-2" y="-27" width="7" height="5" rx="2" fill="{on}"/><rect x="-3" y="-23" width="9" height="1.6" fill="{STEEL_D}"/>'
    if _L(L, "base"):
        out += S(rect_d(-10, -22, 22, 20, 5), c, (-11, -23, 13, -1), k=0.5)
        out += S(rect_d(-2, -19, 13, 12, 3), "#cdeff7", (-3, -20, 12, -6), k=0.4)
        out += f'<path d="M0,-17 L4,-17 L1,-9 L-1,-9 Z" fill="#ffffff" opacity="0.6"/>'
        out += f'<rect x="-10" y="-6" width="22" height="3.4" rx="1.5" fill="{STEEL_D}"/>'
    if _L(L, "face"):
        out += face_eye(4, -13, 2.0, e) + face_eye(8.6, -13.2, 1.8, e)
        if e in ("grito", "esquiva", "susto", "vitoria", "eliminado"):
            out += mouth(6.5, -8.6, 3.6, e)
    return out


def tool_pa():
    out = f'<path d="M-16,-6 C-23,-6 -23,6 -16,6" stroke="{INK}" stroke-width="2.6" fill="none"/><path d="M-21,-5 L-21,5" stroke="{INK}" stroke-width="2.6"/>'
    out += S(rect_d(-17, -2.1, 49, 4.2, 2), WOOD, (-18, -3, 33, 3), k=0.5, dark=WOOD_D)
    out += S(rect_d(29, -3.6, 7, 7.2, 1.5), STEEL_D, (28, -5, 37, 5), k=0.4)
    out += S("M35,-10 C40,-12 50,-11 55,-8 C59,-4 59,4 55,8 C50,11 40,12 35,10 Z", STEEL, (34, -13, 60, 13), k=0.6, dark=STEEL_D, light=STEEL_L)
    out += f'<path d="M38,-6 C44,-3 44,3 38,6" stroke="{STEEL_L}" stroke-width="1.6" fill="none"/>'
    return out


CHARS = {
    "marretao": dict(nome="MARRETÃO", desc="o equilibrado: capacete-tela, quica e verga", hip_h=24, torso=t_marretao, head=h_marretao,
                     head_at=(2, -34), sh_b=(-5, -13), sh_f=(5, -13), hip_b=(-4, -1), hip_f=(4, -1), arm=(10, 11, 5.5),
                     leg=(13, 13, 6.5), knee=1, boot=(14, 7), hand=5.5, tool=tool_marreta, grips=[(0, 0), (-16, 0)]),
    "picareta": dict(nome="PICARETA", desc="o ágil: pernas de pássaro, alcance longo", hip_h=40, torso=t_picareta, head=h_picareta,
                     head_at=(3, -30), sh_b=(-4, -24), sh_f=(4, -24), hip_b=(-3, -1), hip_f=(3, -1), arm=(16, 16, 4.2),
                     leg=(20, 22, 5), knee=-1, boot=(12, 5), hand=3.8, tool=tool_picareta, grips=[(0, 0), (-12, 0)]),
    "chave": dict(nome="CHAVE", desc="o mecânico: caixa de ferramentas, chave inglesa gigante", hip_h=26, torso=t_chave, head=h_chave,
                  head_at=(1, -29), sh_b=(-11, -24), sh_f=(11, -24), hip_b=(-6, -2), hip_f=(6, -2), arm=(14, 14, 6),
                  leg=(13, 13, 7), knee=1, boot=(14, 7), hand=4.6, tool=tool_chave, grips=[(0, 0), (-10, 0)]),
    "britadeira": dict(nome="BRITADEIRA", desc="o baixinho: pula na britadeira", hip_h=14, torso=t_brit, head=h_brit,
                       head_at=(2, -24), sh_b=(-10, -18), sh_f=(10, -18), hip_b=(-6, -3), hip_f=(6, -3), arm=(11, 11, 5.6),
                       leg=(8, 8, 7), knee=1, boot=(13, 7), hand=4.4, tool=tool_brit, grips=[(0, 8), (0, -8)]),
    "pa": dict(nome="PÁ", desc="o operário: cabeça de cabine, pá que vira apoio", hip_h=28, torso=t_pa, head=h_pa,
               head_at=(1, -36), sh_b=(-9, -31), sh_f=(9, -31), hip_b=(-6, -2), hip_f=(6, -2), arm=(14, 14, 6.4),
               leg=(14, 13, 7.6), knee=1, boot=(15, 8), hand=4.8, tool=tool_pa, grips=[(0, 0), (-13, 0)]),
}


def draw(cid, pose, col):
    ch = CHARS[cid]
    limbc = shade(col, -0.45)
    limbb = shade(col, -0.6)
    lean = pose.get("lean", 0)
    hip = (pose.get("dx", 0), -ch["hip_h"] + pose.get("dy", 0))
    T = lambda p: add(rot(p, lean), hip)  # noqa: E731
    e = pose.get("face", "")
    G = pose["tool"][:2]
    A = pose["tool"][2]
    grips = [add(G, rot(g, A)) for g in ch["grips"]]
    parts = {"back_leg": "", "back_arm": "", "torso": "", "front_leg": "", "tool": "", "back_hand": "", "front_arm": "", "fx_back": "", "fx": ""}
    # pernas
    if ch["leg"]:
        a, b, w = ch["leg"]
        for side, key in (("b", "back_leg"), ("f", "front_leg")):
            hp = T(ch["hip_" + side])
            ft = pose["feet"][0 if side == "b" else 1]
            ft = (ft[0], ft[1] - 3)
            knee, end = ik(hp, ft, a, b, (lambda q: q[0]) if ch["knee"] > 0 else (lambda q: -q[0]))
            lc = limbb if side == "b" else limbc
            parts[key] = limb(hp, knee, w, lc) + limb(knee, end, w * 0.9, lc) + boot((end[0], end[1] + 3), ch["boot"][0], ch["boot"][1], shade(col, -0.55) if side == "b" else shade(col, -0.4))
    # tronco + cabeça
    torso = f'<g transform="translate({hip[0]:.2f},{hip[1]:.2f}) rotate({lean:.2f})">{ch["torso"](col, e)}'
    ha = ch["head_at"]
    torso += f'<g transform="translate({ha[0]},{ha[1]}) rotate({pose.get("head", 0)})">{ch["head"](col, e, "all")}</g></g>'
    parts["torso"] = torso
    # braços
    a, b, w = ch["arm"]
    shf = T(ch["sh_f"])
    elbow_pref = lambda q: q[1]  # noqa: E731  (cotovelo para baixo)
    if ch["sh_b"]:
        shb = T(ch["sh_b"])
        el, end = ik(shb, grips[1], a, b, elbow_pref)
        parts["back_arm"] = limb(shb, el, w, limbb) + limb(el, end, w * 0.9, limbb)
        parts["back_hand"] = glove(end, ch["hand"], back=True)
    if False:
        pass
    else:
        el, end = ik(shf, grips[0], a, b, elbow_pref)
        parts["front_arm"] = limb(shf, el, w, limbc) + limb(el, end, w * 0.9, limbc) + glove(end, ch["hand"] * 1.05)
    parts["tool"] = f'<g transform="translate({G[0]:.2f},{G[1]:.2f}) rotate({A:.2f})">{ch["tool"]()}</g>'
    order = ["fx_back", "back_arm", "back_leg", "torso", "front_leg", "tool", "back_hand", "front_arm"]
    body = "".join(parts[k] for k in order)
    if pose.get("spin"):
        cx, cy = pose.get("spin_c", (0, -30))
        body = f'<g transform="rotate({pose["spin"]} {cx} {cy})">{body}</g>'
    return fx_draw(pose.get("fx_b", []), True) + body + fx_draw(pose.get("fx", []), False)


# ---------------------------------------------------------------- efeitos (movimento, poeira, impacto)
def fx_draw(items, back):
    out = []
    for it in items:
        k = it[0]
        if k == "arco":   # rastro do golpe: arco grosso branco translúcido
            _, cx, cy, r, a0, a1, w = it
            p0 = (cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0)))
            p1 = (cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1)))
            large = 1 if abs(a1 - a0) > 180 else 0
            sweep = 1 if a1 > a0 else 0
            out.append(f'<path d="M{p0[0]:.1f},{p0[1]:.1f} A{r},{r} 0 {large} {sweep} {p1[0]:.1f},{p1[1]:.1f}" stroke="#ffffff" stroke-opacity="0.75" stroke-width="{w}" fill="none" stroke-linecap="round"/>')
            out.append(f'<path d="M{p0[0]:.1f},{p0[1]:.1f} A{r},{r} 0 {large} {sweep} {p1[0]:.1f},{p1[1]:.1f}" stroke="#ffffff" stroke-width="{w * 0.35}" fill="none" stroke-linecap="round"/>')
        elif k == "linhas":   # linhas de velocidade
            _, x, y, n, ln, dx = it
            for i in range(n):
                yy = y + i * 7
                out.append(f'<path d="M{x + (i % 2) * 6},{yy} h{dx * ln}" stroke="#ffffff" stroke-width="2.4" stroke-opacity="0.8" stroke-linecap="round"/>')
        elif k == "poeira":
            _, x, y, s = it
            for i, (ox, oy, r) in enumerate(((-8, -3, 5), (0, -6, 7), (9, -3, 5), (-15, -1, 3.5), (16, -1, 3.5))):
                out.append(f'<circle cx="{x + ox * s:.1f}" cy="{y + oy * s:.1f}" r="{r * s:.1f}" fill="#e8e0d0" opacity="0.9"/>')
        elif k == "onda":   # onda de choque no chão
            _, x, y, r = it
            out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * 0.22}" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.85"/>')
            out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r * 0.6}" ry="{r * 0.13}" stroke="#ffe27a" stroke-width="2.4" fill="none"/>')
        elif k == "estrela":   # impacto cartoon
            _, x, y, r = it
            pts = []
            for i in range(16):
                rr = r if i % 2 == 0 else r * 0.45
                a = math.radians(i * 22.5 - 90)
                pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
            out.append(f'<path d="{poly_d(pts)}" fill="#ffe27a"/>')
            out.append(f'<circle cx="{x}" cy="{y}" r="{r * 0.3}" fill="#ffffff"/>')
        elif k == "faiscas":
            _, x, y = it
            for a in (-150, -120, -90, -60, -30):
                ra = math.radians(a)
                out.append(f'<path d="M{x + math.cos(ra) * 4:.1f},{y + math.sin(ra) * 4:.1f} L{x + math.cos(ra) * 11:.1f},{y + math.sin(ra) * 11:.1f}" stroke="#ffd36b" stroke-width="2" stroke-linecap="round"/>')
        elif k == "vibra":   # tremor da britadeira
            _, x, y = it
            for i in range(3):
                out.append(f'<path d="M{x + i * 5},{y - 9} q2,3 0,6 q-2,3 0,6" stroke="#ffffff" stroke-width="1.8" fill="none"/>')
        elif k == "pedras":
            _, x, y = it
            for (ox, oy, r) in ((-10, -12, 3), (6, -16, 2.5), (14, -8, 2), (-4, -20, 2)):
                out.append(f'<rect x="{x + ox}" y="{y + oy}" width="{r * 2}" height="{r * 1.6}" rx="0.8" fill="#a1988a" transform="rotate(20 {x + ox} {y + oy})"/>')
    return "".join(out)


# ---------------------------------------------------------------- poses
# tool = (x, y, ângulo) da pegada da frente; feet = [trás, frente]
POSES = {
    "marretao": {   # poses de jogo do Marretão A27 (tiradas das animações aprovadas, art/src/robos/robo_uch.py)
        "parado": dict(lean=10, feet=[(-11, 0), (11, 0)], tool=(12, -34, -60)),
        "rapido": dict(lean=24, dy=2, feet=[(-12, 0), (14, 0)], tool=(20, -30, 10), face="ataque"),
        "pesado_prep": dict(lean=-20, dy=7, feet=[(-13, 0), (10, 0)], tool=(-6, -44, -140), face="forca", head=12),
        "pesado_golpe": dict(lean=34, dy=7, feet=[(-16, 0), (18, 0)], tool=(24, -22, 75), face="grito"),
        "esquiva": dict(lean=-18, dy=7, feet=[(-16, 0), (8, 0)], tool=(8, -30, -160), face="esquiva"),
    },
    "picareta": {
        "parado": dict(lean=6, feet=[(-8, 0), (10, 0)], tool=(14, -52, -72), head=4),
        "rapido": dict(lean=24, dy=7, feet=[(-24, 0), (26, 0)], tool=(40, -48, -4), face="ataque",
                       fx=[("linhas", 70, -58, 3, 16, -1)]),
        "pesado_prep": dict(lean=-14, dy=-7, feet=[(-5, 0), (7, 0)], tool=(-6, -100, -104), face="forca", head=-10),
        "pesado_golpe": dict(lean=42, dy=12, feet=[(-20, 0), (28, 0)], tool=(46, -32, 78), face="grito",
                             fx=[("estrela", 52, 2, 12), ("pedras", 54, 0)], fx_b=[("arco", 4, -50, 62, -110, 75, 10)]),
        "esquiva": dict(lean=0, dy=-26, feet=[(-12, -18), (4, -14)], tool=(-2, -70, -90), face="esquiva", spin=-160, spin_c=(0, -46),
                        fx_b=[("arco", 0, -46, 40, -40, 200, 5)]),
    },
    "chave": {
        "parado": dict(lean=2, feet=[(-10, 0), (10, 0)], tool=(12, -42, -128)),
        "rapido": dict(lean=12, dy=2, feet=[(-12, 0), (17, 0)], tool=(32, -40, 0), face="ataque",
                       fx=[("arco", 82, -40, 12, -80, 80, 4), ("faiscas", 80, -40)]),
        "pesado_prep": dict(lean=-8, dy=5, feet=[(-15, 0), (12, 0)], tool=(-22, -42, 176), face="forca", head=-4),
        "pesado_golpe": dict(lean=6, dy=4, feet=[(-18, 0), (18, 0)], tool=(30, -40, 8), face="grito",
                             fx_b=[("arco", 0, -40, 50, -175, 160, 9)], fx=[("estrela", 76, -40, 12)]),
        "esquiva": dict(lean=-22, dy=12, feet=[(-18, -2), (24, -4)], tool=(-10, -52, -130), face="esquiva",
                        fx=[("faiscas", -10, 0), ("faiscas", 4, 0)], fx_b=[("linhas", -50, -34, 4, 16, 1)]),
    },
    "britadeira": {
        "parado": dict(lean=0, feet=[(-8, 0), (7, 0)], tool=(17, -38, 90)),
        "rapido": dict(lean=12, dy=2, feet=[(-12, 0), (12, 0)], tool=(20, -24, 0), face="ataque",
                       fx=[("vibra", 64, -24), ("linhas", 66, -36, 2, 8, 1)]),
        "pesado_prep": dict(lean=-4, dy=-34, feet=[(0, -28), (14, -28)], tool=(10, -54, 90), face="forca"),
        "pesado_golpe": dict(lean=10, dy=-8, feet=[(2, -8), (16, -8)], tool=(12, -34, 90), face="grito",
                             fx=[("onda", 12, 0, 34), ("estrela", 12, 0, 14), ("pedras", 12, 0)]),
        "esquiva": dict(lean=-10, dy=-18, feet=[(-8, -14), (8, -12)], tool=(16, -38, 62), face="esquiva",
                        fx_b=[("poeira", -20, 0, 0.9), ("linhas", -48, -36, 3, 14, 1)]),
    },
    "pa": {
        "parado": dict(lean=4, feet=[(-10, 0), (10, 0)], tool=(14, -40, 45)),
        "rapido": dict(lean=14, dy=3, feet=[(-14, 0), (17, 0)], tool=(32, -42, 0), face="ataque",
                       fx=[("linhas", 92, -54, 3, 12, -1), ("estrela", 92, -42, 9)]),
        "pesado_prep": dict(lean=-16, dy=4, feet=[(-14, 0), (12, 0)], tool=(-6, -74, -112), face="forca", head=-6),
        "pesado_golpe": dict(lean=30, dy=10, feet=[(-17, 0), (18, 0)], tool=(32, -30, 64), face="grito",
                             fx=[("onda", 56, 0, 30), ("estrela", 56, -4, 13), ("pedras", 56, 0)], fx_b=[("arco", 4, -44, 54, -140, 55, 11)]),
        "esquiva": dict(lean=-24, dy=-34, dx=-10, feet=[(-22, -30), (-10, -38)], tool=(6, -56, 86), face="esquiva",
                        fx_b=[("poeira", 12, 0, 0.9), ("linhas", -60, -70, 3, 16, 1)]),

    },
}
POSE_NAMES = [("parado", "PARADO"), ("rapido", "GOLPE RÁPIDO"), ("pesado_prep", "PESADO: PREPARO"), ("pesado_golpe", "PESADO: IMPACTO"), ("esquiva", "ESQUIVA")]


def label(x, y, t, size=26, col=INK, anchor="middle", weight=700):
    return f'<text x="{x}" y="{y}" font-family="Fredoka, Arial" font-weight="{weight}" font-size="{size}" fill="{col}" text-anchor="{anchor}">{t}</text>'


def prancha():
    W, H = 1920, 2200
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 64, "ELENCO NOVO — 5 ROBÔS (para aprovar antes de animar no jogo)", 42)]
    x0, cw, ch_, top = 300, 324, 370, 110
    for j, (_, nm) in enumerate(POSE_NAMES):
        b.append(label(x0 + cw * j + cw / 2, top + 20, nm, 24, "#2a4a58"))
    s = 2.15
    for i, cid in enumerate(CHARS):
        y = top + 40 + i * ch_
        col = COLORS[i]
        b.append(f'<rect x="20" y="{y + 6}" width="{W - 40}" height="{ch_ - 14}" rx="22" fill="#ffffff" opacity="0.35"/>')
        b.append(label(40, y + 90, CHARS[cid]["nome"], 38, INK, "start"))

        words = CHARS[cid]["desc"].split(":")
        b.append(label(40, y + 130, words[0] + ":", 22, "#2a4a58", "start", 600))
        b.append(label(40, y + 158, words[1].strip(), 20, "#2a4a58", "start", 500))
        gy = y + ch_ - 40
        for j, (pk, _) in enumerate(POSE_NAMES):
            cx = x0 + cw * j + cw / 2
            b.append(f'<path d="M{cx - 140},{gy} H{cx + 140}" stroke="#7fb8c4" stroke-width="5" stroke-linecap="round"/>')
            b.append(f'<g transform="translate({cx - 20},{gy}) scale({s})">{draw(cid, POSES[cid][pk], col)}</g>')
    # tamanho real no jogo (1x e 1,5x)
    y = top + 40 + 5 * ch_ + 20
    b.append(label(W / 2, y + 30, "TAMANHO DE JOGO (1x) — nas 4 cores de jogador", 26, "#2a4a58"))
    gy = y + 140
    b.append(f'<rect x="60" y="{gy}" width="{W - 120}" height="40" fill="#d8cdb8"/>')
    k = 0
    for i, cid in enumerate(CHARS):
        for ci in range(4):
            cx = 120 + k * 88
            pose = POSES[cid]["parado"]
            b.append(f'<g transform="translate({cx},{gy}) scale(1)">{draw(cid, pose, COLORS[ci])}</g>')
            k += 1
    return doc(W, H, f'<g filter="url(#rough)">{"".join(b)}</g>', rough(seed=8, scale=0.8, freq=0.08))


# ================================================================ exportação para o jogo
# Escala de cada um no jogo (o robô fica com ~80-95 px; a Britadeira é baixinha) e da ferramenta.
GAME = {
    "marretao": dict(k=0.84, tk=0.72, voz=0.7, danca=1, hand_r=5.5, foot=(16, 8), acc=(0.5, -36), eyes_at=(5, -2), top_at=(0, -44),
                     torso_d="M-10,0 C-13,-6 -11,-17 0,-18 C11,-17 13,-6 10,0 Z",
                     especial={"pesado": "", "esquiva": ""}),
    "picareta": dict(k=0.84, tk=0.9, voz=0.9, danca=3, hand_r=3.8, foot=(12, 5), acc=(-2, -29),
                     torso_d="M-9,-2 C-12,-12 -10,-30 0,-32 C10,-32 12,-14 8,-2 C4,2 -6,2 -9,-2 Z",
                     especial={"pesado": "", "esquiva": "mortal"}),
    "chave": dict(k=1.0, tk=0.88, voz=1.08, danca=2, hand_r=4.6, foot=(14, 7), acc=(-2, -24),
                  torso_d=rect_d(-15, -30, 30, 30, 5), especial={"pesado": "giro", "esquiva": "carrinho"}),
    "britadeira": dict(k=1.0, tk=0.9, voz=1.4, danca=2, hand_r=4.4, foot=(13, 7), acc=(2.5, -28),
                       torso_d=ellipse_d(0, -14, 17, 15), especial={"pesado": "monta", "esquiva": "pulinho"}),
    "pa": dict(k=0.92, tk=0.88, voz=1.0, danca=0, hand_r=4.8, foot=(15, 8), acc=(1.5, -22),
               torso_d="M-12,-2 C-15,-14 -15,-30 -11,-36 L11,-36 C15,-30 15,-14 12,-2 C6,1 -6,1 -12,-2 Z",
               especial={"pesado": "", "esquiva": "salto"}),
}
TOOL_BOX = {"marretao": (-30, -20, 75, 20), "picareta": (-17, -23, 53, 27), "chave": (-15, -15, 50, 15),
            "britadeira": (-3, -12, 46, 12), "pa": (-23, -13, 60, 13)}
# Quadros que só o jogo usa (a prancha mostra os principais). tool = (x, y, ângulo) da pegada da frente.
EXTRA = {
    "marretao": {"corre": dict(lean=22, tool=(6, -32, -160)), "ar": dict(tool=(6, -34, -150)),
                 "rapido_prep": dict(lean=0, tool=(6, -40, -110)), "rapido2_prep": dict(lean=6, tool=(18, -24, 50)),
                 "rapido2": dict(lean=18, tool=(16, -42, -70)), "cima": dict(lean=-8, tool=(6, -48, -100)),
                 "baixo": dict(lean=24, tool=(12, -14, 92)), "esquiva_ar": dict(tool=(8, -32, -100))},
    "picareta": {"corre": dict(lean=10, tool=(10, -56, -120)), "ar": dict(tool=(12, -62, -100)),
                 "rapido_prep": dict(lean=-8, tool=(-2, -52, -12)), "rapido2_prep": dict(tool=(6, -82, -80)),
                 "rapido2": dict(lean=14, feet=[(-16, 0), (20, 0)], tool=(34, -46, 40)), "cima": dict(tool=(14, -88, -75)),
                 "baixo": dict(tool=(18, -36, 100)), "esquiva_ar": dict(feet=[(-6, -20), (6, -18)], tool=(4, -66, -90))},
    "chave": {"corre": dict(lean=8, tool=(12, -44, -128)), "ar": dict(tool=(14, -50, -100)),
              "rapido_prep": dict(lean=-6, tool=(6, -44, -24)), "rapido2_prep": dict(tool=(18, -60, -120)),
              "rapido2": dict(lean=10, feet=[(-12, 0), (16, 0)], tool=(32, -34, 30)), "cima": dict(tool=(16, -66, -80)),
              "baixo": dict(tool=(16, -28, 95)), "esquiva_ar": dict(feet=[(-4, -12), (8, -10)], tool=(8, -44, -130))},
    "britadeira": {"corre": dict(lean=8, tool=(16, -30, 60)), "ar": dict(tool=(14, -34, 110)),
                   "rapido_prep": dict(lean=-6, tool=(6, -26, 4)), "rapido2_prep": dict(tool=(14, -44, -60)),
                   "rapido2": dict(lean=8, feet=[(-10, 0), (12, 0)], tool=(24, -30, 30)), "cima": dict(tool=(14, -48, -90)),
                   "baixo": dict(tool=(12, -26, 90)), "esquiva_ar": dict(feet=[(-6, -12), (6, -10)], tool=(14, -36, 60))},
    "pa": {"corre": dict(lean=8, tool=(12, -50, -130)), "ar": dict(tool=(14, -56, -105)),
           "rapido_prep": dict(lean=-8, tool=(2, -46, -8)), "rapido2_prep": dict(tool=(10, -70, -100)),
           "rapido2": dict(lean=12, feet=[(-14, 0), (16, 0)], tool=(30, -28, 20)), "cima": dict(tool=(14, -76, -80)),
           "baixo": dict(tool=(14, -34, 100)), "esquiva_ar": dict(feet=[(-4, -14), (8, -12)], tool=(10, -50, -120))},
}
GAME_EXPR = ("normal", "piscar", "esforco", "susto", "vitoria", "eliminado")
O = (64.0, 120.0)
K4 = 4


def _gwrap(body, seed, w=128, h=128):
    return doc(w, h, f'<g filter="url(#rough)">{body}</g>', rough(seed=seed, scale=0.9, freq=0.12))


def _xf(cid):
    g, ch = GAME[cid], CHARS[cid]
    return f'translate({O[0]},{O[1]}) scale({g["k"]}) translate(0,{-ch["hip_h"]})'


def _head_xf(cid):
    ha = CHARS[cid]["head_at"]
    return _xf(cid) + f' translate({ha[0]},{ha[1]})'


def _damage(cid, lvl):
    import random as _r
    g = GAME[cid]
    rnd = _r.Random(len(cid) * 13 + 5)
    d = g["torso_d"]
    xs = [float(v) for v in __import__("re").findall(r"-?\d+\.?\d*", d)]
    x0, x1 = min(xs[0::2]), max(xs[0::2])
    y0, y1 = min(xs[1::2]), max(xs[1::2])
    w, h = x1 - x0, y1 - y0
    pts = lambda: (rnd.uniform(x0 + w * 0.15, x1 - w * 0.15), rnd.uniform(y0 + h * 0.15, y1 - h * 0.15))  # noqa: E731
    spots = [pts() for _ in range(9)]
    b = [f'<clipPath id="dc"><path d="{d}"/></clipPath><g clip-path="url(#dc)">']
    for (x, y) in spots[:3 + (2 if lvl >= 3 else 0)]:
        rx, ry = rnd.uniform(3.5, 5.5), rnd.uniform(2.4, 3.6)
        b.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{INK}" opacity="0.22"/>')
        b.append(f'<path d="M{x - rx:.1f},{y + 0.4:.1f} Q{x:.1f},{y + ry * 1.3:.1f} {x + rx:.1f},{y + 0.4:.1f}" stroke="#ffffff" stroke-width="0.8" fill="none" opacity="0.55"/>')
    for _ in range(4):
        x, y = pts()
        b.append(f'<path d="M{x:.1f},{y:.1f} l{rnd.uniform(3, 6):.1f},{rnd.uniform(-1.5, 1.5):.1f}" stroke="#ffffff" stroke-width="0.6" opacity="0.6"/>')
    if lvl >= 2:
        for (x, y) in spots[5:7]:
            dd = f"M{x:.1f},{y:.1f}"
            cx, cy = x, y
            for _ in range(4):
                cx += rnd.uniform(1.5, 3.5) * rnd.choice([-1, 1])
                cy += rnd.uniform(1.0, 3.0)
                dd += f" L{cx:.1f},{cy:.1f}"
            b.append(f'<path d="{dd}" stroke="{INK}" stroke-width="1.1" fill="none" opacity="0.8"/>')
        tx, ty = spots[7]
        for ang in (35, -35):
            b.append(f'<rect x="{tx - 6:.1f}" y="{ty - 1.6:.1f}" width="12" height="3.2" fill="#d9d4c4" transform="rotate({ang} {tx:.1f} {ty:.1f})"/>')
    if lvl >= 3:
        hx, hy = spots[8]
        b.append(f'<ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="8" ry="6.3" fill="{INK}" opacity="0.25"/>')
        b.append(f'<path d="M{hx - 4:.1f},{hy:.1f} L{hx - 1.6:.1f},{hy - 3.8:.1f} L{hx + 2:.1f},{hy - 3:.1f} L{hx + 4.2:.1f},{hy:.1f} L{hx + 1.2:.1f},{hy + 3.8:.1f} L{hx - 2.5:.1f},{hy + 3:.1f} Z" fill="#1c1626"/>')
        for kk, col in enumerate(("#f2c84b", "#d14d35", "#5cc45c")):
            b.append(f'<path d="M{hx - 1 + kk:.1f},{hy:.1f} q{2 + kk},{3 + kk} {4 + kk},{1}" stroke="{col}" stroke-width="0.9" fill="none"/>')
    b.append("</g>")
    return f'<g transform="{_xf(cid)}">{"".join(b)}</g>'


def _tool_export(cid):
    """Ferramenta em pé (cabeça para cima), pegada da frente em tool_grip; grip2 = da frente até a de trás."""
    g, ch = GAME[cid], CHARS[cid]
    x0, y0, x1, y1 = TOOL_BOX[cid]
    s = g["k"] * g["tk"]
    pad = 2.0
    w = (y1 - y0) * s + pad * 2
    h = (x1 - x0) * s + pad * 2
    gf = ch["grips"][0]
    gb = ch["grips"][1] if len(ch["grips"]) > 1 else ch["grips"][0]
    # ponto (x,y) da ferramenta → (y, -x) em pé
    up = lambda p: ((p[1] - y0) * s + pad, (x1 - p[0]) * s + pad)  # noqa: E731
    grip = up(gf)
    back = up(gb)
    head = up(((x1 + max(x1 - 14, 0)) / 2.0, 0))
    body = f'<g transform="translate({pad - y0 * s},{pad + x1 * s}) scale({s}) rotate(-90) ">{ch["tool"]()}</g>'
    return body, (math.ceil(w), math.ceil(h)), grip, (back[0] - grip[0], back[1] - grip[1]), math.hypot(head[0] - grip[0], head[1] - grip[1])


def _pose_export(cid, pz):
    g, ch = GAME[cid], CHARS[cid]
    k = g["k"]
    G = pz["tool"]
    out = {"hf": [round(G[0] * k, 2), round(G[1] * k, 2)], "a": round(math.radians(G[2] + 90.0), 4),
           "lean": round(math.radians(pz.get("lean", 0)), 4), "dy": round(pz.get("dy", 0) * k, 2), "dx": round(pz.get("dx", 0) * k, 2)}
    if "feet" in pz:
        out["feet"] = [[round(f[0] * k, 2), round(f[1] * k, 2)] for f in pz["feet"]]
    return out


def export_game():
    out_dir = os.path.join(ROOT, "art/out/game/robo")
    src = os.path.join(ROOT, "art/src/robos/svg/elenco")
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(src, exist_ok=True)
    meta = {"cores": COLORS[:4], "membros": [shade(c, -0.45) for c in COLORS[:4]], "ordem": list(CHARS), "modelos": {}}
    for mi, cid in enumerate(CHARS):
        g, ch = GAME[cid], CHARS[cid]
        k = g["k"]
        seed = 40 + mi * 3
        for ci in range(4):
            col = COLORS[ci]
            body = f'<g transform="{_xf(cid)}">{ch["torso"](col, "")}</g><g transform="{_head_xf(cid)}">{ch["head"](col, "", "base")}</g>'
            queue(_gwrap(body, seed), f"{src}/corpo_{cid}_p{ci + 1}.svg", f"{out_dir}/corpo_{cid}_p{ci + 1}.png", 128, 128, K4)
        for e in GAME_EXPR:
            face = f'<g transform="{_head_xf(cid)}">{ch["head"](COLORS[0], e, "face")}</g>'
            queue(_gwrap(face, seed + 1), f"{src}/rosto_{cid}_{e}.svg", f"{out_dir}/rosto_{cid}_{e}.png", 128, 128, K4)
        acc = f'<g transform="{_head_xf(cid)}">{ch["head"](COLORS[0], "", "acc")}</g>'
        queue(_gwrap(acc, seed + 2), f"{src}/antena_{cid}.svg", f"{out_dir}/antena_{cid}.png", 128, 128, K4)
        for lvl in (1, 2, 3):
            queue(_gwrap(_damage(cid, lvl), seed + 3 + lvl), f"{src}/dano{lvl}_{cid}.svg", f"{out_dir}/dano{lvl}_{cid}.png", 128, 128, K4)
        tbody, tsize, tgrip, grip2, reach = _tool_export(cid)
        queue(_gwrap(tbody, seed + 7, tsize[0], tsize[1]), f"{src}/ferramenta_{cid}.svg", f"{out_dir}/ferramenta_{cid}.png", tsize[0], tsize[1], K4)
        # geometria em coordenadas da tela 128x128 (pés em 64,120)
        hip = (0, -ch["hip_h"])
        cv = lambda p: [round(O[0] + k * p[0], 2), round(O[1] + k * p[1], 2)]  # noqa: E731
        hb = ch["hip_b"] or (-6, -2)
        hf = ch["hip_f"] or (6, -2)
        shb = ch["sh_b"] or (-8, ch["sh_f"][1])
        poses = dict(POSES[cid])
        poses.update(EXTRA[cid])
        ha = ch["head_at"]
        eyes_c = add(add(hip, ha), g.get("eyes_at", (7, -12)))
        acc_p = add(add(hip, ha), g["acc"])
        top = add(add(hip, ha), g.get("top_at", (0, -26 if cid in ("chave", "pa") else (-38 if cid == "picareta" else -32))))
        meta["modelos"][cid] = {
            "nome": ch["nome"].capitalize() if cid != "pa" else "Pá", "hat": [64, 40, 0.5],
            "hips": [cv(add(hip, hb)), cv(add(hip, hf))], "shoulders": [cv(add(hip, shb)), cv(add(hip, ch["sh_f"]))],
            "hand_back": cv(POSES[cid]["parado"]["tool"][:2]), "hand_front": cv(POSES[cid]["parado"]["tool"][:2]),
            "antenna": cv(acc_p), "eyes": [cv(eyes_c), cv(eyes_c)], "top": round(O[1] + k * top[1], 1),
            "limb_w": round(ch["arm"][2] * k, 2), "leg_w": round(ch["leg"][2] * k, 2), "knee": ch["knee"],
            "hand_s": round(g["hand_r"] * k / 6.2, 3), "foot_s": round(g["foot"][0] * k / 17.0, 3),
            "voz": g["voz"], "danca": g["danca"],
            "tool": list(tsize), "tool_grip": [round(tgrip[0], 2), round(tgrip[1], 2)], "grip2": [round(grip2[0], 2), round(grip2[1], 2)],
            "reach": round(reach, 1), "especial": g["especial"],
            "poses": {name: _pose_export(cid, pz) for name, pz in poses.items()},
        }
    import json
    with open(f"{out_dir}/modelos.json", "w") as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)


def main():
    os.makedirs(SRC, exist_ok=True)
    export_game()
    queue(prancha(), f"{SRC}/prancha_elenco5.svg", os.path.join(ROOT, "art/out/prancha_elenco5.png"), 1920, 2200, 1)
    print("elenco:", render_all())


if __name__ == "__main__":
    main()
