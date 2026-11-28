"""CONCEITOS de repaginação dos robôs (pedido do usuário, 2026-11-26): "mudar o conceito de design, mais clean; o formato
de hoje está estranho". Só conceitos (1 robô de exemplo por direção), antes de qualquer prancha de elenco.
Mantém o tema: papel e giz (formas chapadas com textura de giz, sem contorno), cores de jogador, ferramenta de demolição.
Rodar: python3 art/src/robos/conceitos.py → art/out/robos_v2/c1_conceitos.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
from elenco import S, label, INK  # noqa: E402
from papel import ellipse_d, rect_d  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/robos_v2")
SRC = os.path.join(ROOT, "art/src/robos/svg")
COLS = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]
GLOVE, GLOVE_D = "#f4f1ea", "#c9c2b4"
STEEL, STEEL_D, STEEL_L = "#9aa4ae", "#6b7783", "#c9d1d8"
WOOD, WOOD_D = "#c98a4b", "#8a5a2b"
YEL = "#f2c84b"


def R(x, y, w, h, r, fill, k=0.6, **kw):
    return S(rect_d(x, y, w, h, r), fill, (x - 1, y - 1, x + w + 1, y + h + 1), k=k, **kw)


def E(cx, cy, rx, ry, fill, k=0.6, **kw):
    return S(ellipse_d(cx, cy, rx, ry), fill, (cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1), k=k, **kw)


def hose(p, q, bend, w, col):
    """Membro "mangueira" (curva única, dobra sozinha): de p a q, barriga para o lado de bend."""
    mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
    dx, dy = q[0] - p[0], q[1] - p[1]
    L = math.hypot(dx, dy) or 1
    cx, cy = mx - dy / L * bend, my + dx / L * bend
    return f'<path d="M{p[0]:.1f},{p[1]:.1f} Q{cx:.1f},{cy:.1f} {q[0]:.1f},{q[1]:.1f}" stroke="{col}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'


def seg(p, q, w, col):
    return f'<path d="M{p[0]:.1f},{p[1]:.1f} L{q[0]:.1f},{q[1]:.1f}" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>'


def marreta(g, ang, s=1.0):
    """Marreta simples: pegada da frente em g, ângulo ang (0 = frente, -90 = cima)."""
    body = (R(-14 * s, -2.2 * s, 46 * s, 4.4 * s, 2, WOOD, dark=WOOD_D) + R(30 * s, -10 * s, 15 * s, 20 * s, 3, STEEL, dark=STEEL_D, light=STEEL_L)
            + f'<rect x="{34 * s}" y="{-10 * s}" width="{3.5 * s}" height="{20 * s}" fill="{YEL}"/>')
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang})">{body}</g>', (g[0] + math.cos(math.radians(ang)) * -10 * s, g[1] + math.sin(math.radians(ang)) * -10 * s)


def olhos(x, y, r, expr, gap, col_pupila=INK, branco="#ffffff"):
    out = ""
    for i in range(2):
        ex = x + i * gap
        if expr == "raiva":
            out += f'<ellipse cx="{ex}" cy="{y}" rx="{r}" ry="{r * 0.62}" fill="{branco}"/><circle cx="{ex + r * 0.3}" cy="{y + 0.5}" r="{r * 0.45}" fill="{col_pupila}"/>'
            out += f'<path d="M{ex - r * 1.1},{y - r * (1.25 if i == 0 else 0.7)} L{ex + r * 1.1},{y - r * (0.7 if i == 0 else 1.25)}" stroke="{INK}" stroke-width="{r * 0.45}" stroke-linecap="round"/>'
        elif expr == "susto":
            out += f'<ellipse cx="{ex}" cy="{y}" rx="{r * 1.1}" ry="{r * 1.2}" fill="{branco}"/><circle cx="{ex + r * 0.2}" cy="{y}" r="{r * 0.28}" fill="{col_pupila}"/>'
        else:
            out += f'<ellipse cx="{ex}" cy="{y}" rx="{r * 0.9}" ry="{r}" fill="{branco}"/><circle cx="{ex + r * 0.3}" cy="{y + 0.3}" r="{r * 0.45}" fill="{col_pupila}"/>'
    return out


def boca(x, y, w, expr):
    if expr == "raiva":
        return f'<path d="M{x - w / 2},{y} h{w}" stroke="{INK}" stroke-width="{w * 0.22}" stroke-linecap="round"/>'
    if expr == "susto":
        return f'<ellipse cx="{x}" cy="{y}" rx="{w * 0.22}" ry="{w * 0.3}" fill="#7a2232"/>'
    return f'<path d="M{x - w / 2},{y - w * 0.1} Q{x},{y + w * 0.4} {x + w / 2},{y - w * 0.1}" stroke="{INK}" stroke-width="{w * 0.18}" fill="none" stroke-linecap="round"/>'


# ---------------------------------------------------------------- poses comuns (pés, mãos, ferramenta, inclinação)
POSES = {
    "parado": dict(lean=0, bob=0, feet=[(-9, 0), (9, 0)], tool=(16, -30, 60), expr="normal"),
    "corre": dict(lean=10, bob=-3, feet=[(-16, -6), (14, 0)], tool=(-4, -52, -150), expr="normal"),
    "golpe": dict(lean=20, bob=6, feet=[(-16, 0), (18, 0)], tool=(26, -26, 70), expr="raiva", impacto=True),
}


def _fx(pose, x=50, y=0):
    if not pose.get("impacto"):
        return ""
    pts = []
    for i in range(16):
        rr = 14 if i % 2 == 0 else 6
        a = math.radians(i * 22.5)
        pts.append(f"{x + math.cos(a) * rr:.1f},{y - 6 + math.sin(a) * rr:.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="#ffe27a"/><ellipse cx="{x}" cy="{y}" rx="26" ry="5" fill="none" stroke="#ffffff" stroke-width="3"/>'


# ---------------------------------------------------------------- A · CÁPSULA: feijão inteiriço + membros-mangueira
def robo_capsula(col, pose):
    lc = shade(col, -0.45)
    lean, bob = pose["lean"], pose["bob"]
    cx, cy = 0, -46 + bob
    out = []
    t, hand = marreta((pose["tool"][0], pose["tool"][1] + bob * 0.5), pose["tool"][2])
    for i, side in enumerate((-1, 1)):   # pernas
        hip = (side * 7, cy + 22)
        ft = pose["feet"][i]
        out.append(hose(hip, (ft[0], ft[1] - 4), -4 * side, 6, shade(col, -0.6 if side < 0 else -0.45)))
        out.append(E(ft[0] + 3, ft[1] - 3, 7.5, 4.5, shade(col, -0.55 if side < 0 else -0.4)))
    out.append(hose((cx - 6, cy - 2), (hand[0] - 6, hand[1]), 5, 5, shade(col, -0.6)))   # braço de trás
    body = E(0, 0, 20, 29, col, k=0.7) + R(-2, -20, 20, 15, 7, INK, k=0.4)
    body += olhos(4, -13, 3.6, pose["expr"], 8.5, col_pupila=INK, branco="#bff7e0") if False else olhos(4, -13, 3.6, pose["expr"], 8.5)
    body += f'<path d="M-4,-29 C-6,-36 -2,-39 2,-39" stroke="{shade(col, -0.5)}" stroke-width="1.8" fill="none"/><circle cx="2" cy="-39.5" r="2.6" fill="{YEL}"/>'
    body += f'<path d="M-17,6 Q0,12 17,6" stroke="{shade(col, -0.25)}" stroke-width="3" fill="none"/>'
    out.append(f'<g transform="translate({cx},{cy}) rotate({lean})">{body}</g>')
    out.append(t)
    out.append(hose((cx + 8, cy - 4), hand, -6, 5.5, lc) + E(hand[0], hand[1], 5.2, 5, GLOVE, k=0.4))
    return _fx(pose) + "".join(out)


# ---------------------------------------------------------------- B · BLOCO: caixas arredondadas + cabeça-tela
def robo_bloco(col, pose):
    lc, lb = shade(col, -0.45), shade(col, -0.6)
    lean, bob = pose["lean"], pose["bob"]
    hip = (0, -28 + bob)
    out = []
    t, hand = marreta((pose["tool"][0], pose["tool"][1] + bob * 0.5), pose["tool"][2])
    for i, side in enumerate((-1, 1)):
        hp = (hip[0] + side * 6, hip[1])
        ft = pose["feet"][i]
        knee = ((hp[0] + ft[0]) / 2 + 4, (hp[1] + ft[1]) / 2)
        c = lb if side < 0 else lc
        out.append(seg(hp, knee, 7, c) + seg(knee, (ft[0], ft[1] - 4), 7, c) + f'<circle cx="{knee[0]:.1f}" cy="{knee[1]:.1f}" r="4.6" fill="{shade(col, 0.15)}"/>')
        out.append(R(ft[0] - 6, ft[1] - 7, 15, 7, 2.5, shade(col, -0.5)))
    sh = (hip[0] + 2, hip[1] - 22)
    out.append(seg(sh, (hand[0] - 6, hand[1]), 6, lb))
    body = R(-13, -26, 26, 26, 6, col, k=0.7) + R(-13, -8, 26, 5, 2, shade(col, -0.3), k=0.3)
    body += R(-3, -31, 7, 6, 2, shade(col, -0.4))
    head = R(-15, -55, 30, 25, 6, col, k=0.6) + R(-10, -51, 22, 17, 4, "#1d2a3a", k=0.3)
    ex = pose["expr"]
    gl = "#7ef0b0"
    if ex == "raiva":
        head += f'<path d="M-6,-45 l5,2 M5,-45 l5,-2" stroke="{gl}" stroke-width="2.6" stroke-linecap="round"/><path d="M-3,-38 h8" stroke="{gl}" stroke-width="2"/>'
    elif ex == "susto":
        head += f'<circle cx="-2" cy="-44" r="3.4" fill="none" stroke="{gl}" stroke-width="2"/><circle cx="7" cy="-44" r="3.4" fill="none" stroke="{gl}" stroke-width="2"/><circle cx="2.5" cy="-38" r="1.6" fill="{gl}"/>'
    else:
        head += f'<circle cx="-2" cy="-44" r="2.6" fill="{gl}"/><circle cx="7" cy="-44" r="2.6" fill="{gl}"/><path d="M-2,-39 Q2.5,-36 7,-39" stroke="{gl}" stroke-width="1.8" fill="none"/>'
    head += f'<path d="M-9,-55 l-4,-8 M9,-55 l4,-8" stroke="{shade(col, -0.5)}" stroke-width="1.8"/><circle cx="-13" cy="-63" r="2.2" fill="#d14d35"/><circle cx="13" cy="-63" r="2.2" fill="{YEL}"/>'
    out.append(f'<g transform="translate({hip[0]},{hip[1]}) rotate({lean})">{body}{head}</g>')
    out.append(t)
    sh2 = (hip[0] + 6, hip[1] - 22)
    el = ((sh2[0] + hand[0]) / 2, (sh2[1] + hand[1]) / 2 + 6)
    out.append(seg(sh2, el, 6, lc) + seg(el, hand, 6, lc) + f'<circle cx="{el[0]:.1f}" cy="{el[1]:.1f}" r="4" fill="{shade(col, 0.15)}"/>' + R(hand[0] - 5, hand[1] - 5, 10, 10, 3, GLOVE, k=0.4))
    return _fx(pose) + "".join(out)


# ---------------------------------------------------------------- C · LATA: cilindro alto, rosto pintado, braços finos
def robo_lata(col, pose):
    lc = shade(col, -0.45)
    lean, bob = pose["lean"], pose["bob"]
    base = (0, -20 + bob)
    out = []
    t, hand = marreta((pose["tool"][0], pose["tool"][1] + bob * 0.5), pose["tool"][2])
    for i, side in enumerate((-1, 1)):
        hp = (base[0] + side * 6, base[1])
        ft = pose["feet"][i]
        out.append(hose(hp, (ft[0], ft[1] - 4), 3 * side, 4, shade(col, -0.6 if side < 0 else -0.45)))
        out.append(E(ft[0] + 4, ft[1] - 3.5, 9, 4.5, INK, k=0.4))
    out.append(hose((base[0] - 4, base[1] - 34), (hand[0] - 6, hand[1]), 6, 3.6, shade(col, -0.6)))
    body = R(-14, -58, 28, 58, 5, col, k=0.7) + E(0, -58, 14, 4, shade(col, 0.25), k=0.4)
    body += R(-14, -22, 28, 6, 1, YEL, k=0.3) + f'<path d="M-14,-19 h28" stroke="{INK}" stroke-width="1.5" stroke-dasharray="4 3"/>'
    body += olhos(1, -44, 3.4, pose["expr"], 8) + boca(5, -33, 9, pose["expr"])
    body += f'<path d="M-4,-62 C-5,-70 0,-72 3,-72" stroke="{shade(col, -0.5)}" stroke-width="1.6" fill="none"/><circle cx="3" cy="-72.5" r="2.5" fill="{YEL}"/>'
    out.append(f'<g transform="translate({base[0]},{base[1]}) rotate({lean * 0.7})">{body}</g>')
    out.append(t)
    out.append(hose((base[0] + 6, base[1] - 36), hand, -6, 3.8, lc) + E(hand[0], hand[1], 5.8, 5.6, GLOVE, k=0.4))
    return _fx(pose) + "".join(out)


# ---------------------------------------------------------------- D · MASCOTE: cabeção redondo com capacete, corpo pequeno
def robo_mascote(col, pose):
    lc = shade(col, -0.45)
    lean, bob = pose["lean"], pose["bob"]
    hip = (0, -18 + bob)
    out = []
    t, hand = marreta((pose["tool"][0], pose["tool"][1] + bob * 0.5), pose["tool"][2])
    for i, side in enumerate((-1, 1)):
        hp = (hip[0] + side * 6, hip[1])
        ft = pose["feet"][i]
        out.append(hose(hp, (ft[0], ft[1] - 4), 2 * side, 7.5, shade(col, -0.6 if side < 0 else -0.45)))
        out.append(E(ft[0] + 3, ft[1] - 4, 8.5, 5.5, shade(col, -0.5)))
    out.append(hose((hip[0] - 5, hip[1] - 16), (hand[0] - 6, hand[1]), 4, 6.5, shade(col, -0.6)))
    body = E(0, -11, 12, 13, col, k=0.6) + R(-12, -5, 24, 4, 2, shade(col, -0.3), k=0.3)
    head = E(2, -44, 22, 20, col, k=0.7)
    head += S("M-21,-46 C-21,-66 25,-66 25,-46 Z", YEL, (-22, -66, 26, -45), k=0.5, dark="#c49a2a") + R(-24, -48, 52, 4.5, 2, "#c49a2a", k=0.3)
    head += olhos(6, -38, 4.2, pose["expr"], 10) + boca(12, -28, 8, pose["expr"])
    out.append(f'<g transform="translate({hip[0]},{hip[1]}) rotate({lean * 0.6})">{body}{head}</g>')
    out.append(t)
    out.append(hose((hip[0] + 5, hip[1] - 17), hand, -5, 6.5, lc) + E(hand[0], hand[1], 6.5, 6.2, GLOVE, k=0.4))
    return _fx(pose) + "".join(out)


CONCEITOS = [
    ("A · CÁPSULA", robo_capsula, "Corpo e cabeça numa peça só (feijão), visor escuro com olhos; braços e pernas de mangueira:", "dobram sozinhos em curva = animação muito orgânica. O mais clean e fofo."),
    ("B · BLOCO", robo_bloco, "Caixas arredondadas (tronco e cabeça-tela), juntas redondas visíveis, rosto em pixels na tela:", "robótico e legível; expressões trocam como ícones. Estilo brinquedo."),
    ("C · LATA", robo_lata, "Cilindro alto (lata de tinta), rosto pintado no corpo, braços e pernas finos, luvas e botas grandes:", "silhueta vertical muito clara; parente direto da sua ref. 'Lata'."),
    ("D · MASCOTE", robo_mascote, "Cabeção redondo com capacete de obra, corpinho pequeno, membros grossos de mangueira:", "proporção de mascote (cabeça ~50%); carisma e expressão em primeiro lugar."),
]


def painel(x, y, w, h, nome, fn, l1, l2):
    b = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="#ffffff" opacity="0.5"/>', label(x + 30, y + 52, nome, 38, INK, "start")]
    b.append(label(x + 30, y + 86, l1, 17, "#2a4a58", "start", 600) + label(x + 30, y + 110, l2, 17, "#2a4a58", "start", 600))
    gy = y + h - 70
    b.append(f'<rect x="{x + 20}" y="{gy}" width="{w - 40}" height="12" rx="4" fill="#c9b99a"/>')
    ci = [0, 1, 2, 0][[c[1] for c in CONCEITOS].index(fn)]   # cor do exemplo (o Mascote não em amarelo: some com o capacete)
    for i, (pk, px) in enumerate((("parado", 110), ("corre", 300), ("golpe", 500))):
        b.append(f'<g transform="translate({x + px},{gy}) scale(2.6)">{fn(COLS[ci], POSES[pk])}</g>')
    # rostos (raiva, susto) grandes: no golpe já aparece a raiva; aqui o susto
    sp = dict(POSES["parado"])
    sp["expr"] = "susto"
    b.append(f'<g transform="translate({x + 700},{gy}) scale(2.6)">{fn(COLS[(ci + 2) % 4], sp)}</g>')
    # tamanho de jogo 1x, 4 cores
    b.append(label(x + w - 120, y + 150, "tamanho de jogo (1x)", 15, "#2a4a58"))
    for k in range(4):
        b.append(f'<g transform="translate({x + w - 195 + k * 50},{y + 250})">{fn(COLS[k], POSES["parado" if k % 2 == 0 else "golpe"])}</g>')
    b.append(f'<rect x="{x + w - 215}" y="{y + 250}" width="200" height="5" fill="#c9b99a"/>')
    return "".join(b)


def prancha():
    W, H = 1920, 1300
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 62, "REPAGINAÇÃO DOS ROBÔS — 4 CONCEITOS (escolha 1, ou misture)", 40)]
    pw, ph = 925, 560
    for i, (nome, fn, l1, l2) in enumerate(CONCEITOS):
        b.append(painel(25 + (i % 2) * 945, 100 + (i // 2) * 590, pw, ph, nome, fn, l1, l2))
    b.append(label(W / 2, H - 14, "Mesmo papel e giz e cores de jogador; parado · correndo · golpe · susto. Só o conceito — o elenco de 5 vem depois da escolha.", 20, "#2a4a58"))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


def main():
    os.makedirs(OUT, exist_ok=True)
    svg, w, h = prancha()
    queue(svg, f"{SRC}/c1_conceitos.svg", os.path.join(OUT, "c1_conceitos.png"), w, h, 1)
    print("conceitos:", render_all())


if __name__ == "__main__":
    main()
