"""PRANCHA — TEMAS PARA OS PRÓXIMOS MAPAS (A54, 2026-11-28): estrutura + mundo + regra-assinatura, com a identidade
da obra (placa, zebra, grua) em todo mapa. 8 cartazes em papel e giz para o usuário escolher 2–3 para a beta.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/mapas_temas.py → art/out/mapas/temas.png
"""
import base64
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../ui"))
sys.path.insert(0, os.path.join(HERE, "../robos"))
import controles_arte as ca  # noqa: E402
import elenco_uch as eu  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/mapas")
W, H = 410, 330          # área da cena dentro do cartaz
COR = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]


def P(d, fill, box, k=1.6, vol=0.0):
    return ca.P(d, fill, box, k, vol=vol)


def R(x, y, w, h, fill, k=1.6, vol=0.0, r=3):
    return P(ca.rr_d(x, y, w, h, r), fill, (x, y, x + w, y + h), k, vol)


def C(cx, cy, r, fill, k=1.4, vol=0.0):
    return P(ca.circ_d(cx, cy, r), fill, (cx - r, cy - r, cx + r, cy + r), k, vol)


def poly(pts, fill, k=1.6, vol=0.0):
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return P(d, fill, (min(xs), min(ys), max(xs), max(ys)), k, vol)


def ceu(c1, c2, gid):
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/>'
            f'<stop offset="1" stop-color="{c2}"/></linearGradient></defs><rect width="{W}" height="{H}" fill="url(#{gid})"/>')


def robo(x, y, model, col, s=0.62, flip=False):
    sx = -s if flip else s
    return f'<g transform="translate({x},{y}) scale({sx},{s})">{eu.desenha(model, col, "parado")}</g>'


def zebra(x, y, w, h=12):
    o = R(x, y, w, h, "#f2c84b", 1.0)
    for k in range(int(w / 16)):
        o += f'<path d="M{x + 4 + k * 16},{y + h} l8,-{h} h6 l-8,{h} Z" fill="{INK}" opacity="0.85"/>'
    return o


def placa(x, y, txt):
    w = len(txt) * 9 + 20
    x = min(x, W - w - 6)
    return R(x, y, w, 30, "#f2c84b", 1.0, vol=3) + T(x + w / 2, y + 21, txt, 13, INK)


def grua(x, y, h, cor="#e0a83a", lanca=120):
    o = R(x, y, 12, h, cor, 1.0)
    for k in range(int(h / 18)):
        o += f'<path d="M{x},{y + k * 18} l12,16 M{x + 12},{y + k * 18} l-12,16" stroke="{shade(cor, -0.3)}" stroke-width="2"/>'
    o += R(x - lanca, y - 8, lanca + 40, 10, cor, 1.0)
    return o


# ---------------------------------------------------------------- as 8 cenas
def atlantida():
    o = ceu("#3fb6c9", "#0f4f73", "ga")
    for k in range(5):   # raios de luz
        x = 40 + k * 80
        o += f'<path d="M{x},0 L{x + 30},0 L{x + 70},{H} L{x + 10},{H} Z" fill="#ffffff" opacity="0.07"/>'
    o += poly([(0, 290), (120, 278), (260, 286), (410, 272), (410, 330), (0, 330)], "#d9c48f")
    o += R(70, 150, 270, 22, "#e6dcc6", vol=4)   # frontão
    o += poly([(60, 150), (205, 98), (350, 150)], "#efe6d2", vol=4)
    for k in range(5):
        o += R(84 + k * 52, 172, 22, 106, "#e9e0cc", vol=3)
    o += f'<ellipse cx="205" cy="178" rx="0" ry="0"/>'
    o += f'<path d="M150,95 a55,48 0 0 1 110,0 Z" fill="#bfeaf2" opacity="0.55" stroke="#ffffff" stroke-width="3"/>'
    o += '<path d="M190,60 l10,18 l-14,8 l12,14" stroke="#ffffff" stroke-width="3" fill="none"/>'
    o += f'<rect x="250" y="210" width="96" height="70" fill="#5fd0e0" opacity="0.55"/><path d="M250,210 q24,-8 48,0 t48,0" stroke="#ffffff" stroke-width="3" fill="none"/>'
    rnd = random.Random(2)
    for k in range(14):
        o += f'<circle cx="{rnd.uniform(240, 360)}" cy="{rnd.uniform(60, 220)}" r="{rnd.uniform(3, 9)}" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.8"/>'
    o += grua(370, 120, 160, "#e0a83a", 60) + placa(14, 248, "OBRA SUBMARINA")
    o += robo(150, 288, 0, COR[0]) + robo(300, 288, 2, COR[2], flip=True)
    return o


def siderurgica():
    o = ceu("#f7a35c", "#7a2d2d", "gs")
    o += R(20, 60, 40, 230, "#5a4848", vol=4) + R(70, 90, 34, 200, "#634f4f", vol=4)
    o += C(40, 52, 22, "#8a8a8a", 1.0) + C(87, 80, 18, "#9a9a9a", 1.0)
    o += R(140, 120, 120, 170, "#4a3c3c", vol=5) + R(150, 150, 100, 60, "#d9532b", 1.2)
    o += R(0, 286, 410, 44, "#3a2f2f")
    o += f'<rect x="200" y="300" width="210" height="30" fill="#ff8a1f"/><rect x="200" y="300" width="210" height="8" fill="#ffd23f"/>'
    o += R(110, 214, 300, 12, "#6b5a5a") + zebra(270, 200, 120)
    o += f'<g transform="rotate(-35 330 150)">' + R(300, 120, 70, 54, "#3f3a3a", vol=4) + "</g>"
    o += '<path d="M352,170 C358,210 345,250 360,300" stroke="#ff8a1f" stroke-width="16" fill="none" stroke-linecap="round"/>'
    o += '<path d="M352,170 C358,210 345,250 360,300" stroke="#ffd23f" stroke-width="6" fill="none" stroke-linecap="round"/>'
    o += placa(14, 246, "ORDEM DE SERVIÇO") + robo(180, 214, 1, COR[1]) + robo(130, 286, 3, COR[3])
    return o


def nuvens():
    o = ceu("#f4b6d2", "#9fd6f0", "gn")
    for cx, cy, r in [(60, 270, 50), (130, 290, 60), (300, 285, 55), (370, 270, 45)]:
        o += C(cx, cy, r, "#ffffff", 0.8)
    o += poly([(80, 200), (230, 200), (200, 250), (110, 250)], "#9c7b5a", vol=4)
    o += R(110, 120, 30, 80, "#d8c7e8", vol=3) + R(170, 100, 36, 100, "#e2d4ef", vol=3)
    o += poly([(105, 120), (125, 88), (145, 120)], "#d14b6b") + poly([(166, 100), (188, 62), (210, 100)], "#d14b6b")
    for bx, by, c in [(70, 70, "#ff6b6b"), (250, 50, "#4f86d9")]:
        o += C(bx, by, 26, c, 1.2, vol=4) + f'<path d="M{bx},{by + 26} L{150},{200}" stroke="{INK}" stroke-width="2"/>'
    o += poly([(270, 170), (380, 160), (360, 205), (285, 210)], "#8a6b4f", vol=4)
    for k in range(4):
        y = 110 + k * 22
        o += f'<path d="M250,{y} q40,-10 80,0" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.9"/>'
    o += '<path d="M330,205 l-4,40 m0,0 l-12,8 m12,-8 l10,10" stroke="#5a5a5a" stroke-width="5" fill="none"/>'
    o += placa(250, 222, "ÂNCORA SOLTA") + robo(150, 200, 4, COR[0]) + robo(320, 162, 2, COR[1], flip=True)
    return o


def lua():
    o = ceu("#0b1026", "#26305a", "gl")
    rnd = random.Random(7)
    for k in range(40):
        o += f'<circle cx="{rnd.uniform(0, W)}" cy="{rnd.uniform(0, 200)}" r="{rnd.uniform(0.8, 2.2)}" fill="#ffffff" opacity="0.8"/>'
    o += C(340, 60, 32, "#4f86d9", 1.0) + C(330, 52, 12, "#5cc45c", 0.8)
    o += poly([(0, 270), (410, 262), (410, 330), (0, 330)], "#9a9aa8")
    o += f'<ellipse cx="90" cy="300" rx="34" ry="8" fill="#7d7d8c"/><ellipse cx="300" cy="310" rx="44" ry="9" fill="#7d7d8c"/>'
    o += f'<path d="M60,270 a70,70 0 0 1 140,0 Z" fill="#cfd6e6"/><path d="M220,270 a50,50 0 0 1 100,0 Z" fill="#cfd6e6"/>'
    o += R(196, 246, 30, 24, "#aab3c7") + zebra(60, 262, 140)
    o += '<path d="M262,230 l14,-6 l4,12 l-12,4 Z" fill="#0b1026"/>'
    for k in range(5):
        a = -0.6 + k * 0.3
        o += f'<path d="M{272 + math.cos(a) * 60},{232 + math.sin(a) * 50} L276,232" stroke="#ffffff" stroke-width="2" stroke-dasharray="5 5" opacity="0.8"/>'
    o += placa(14, 18, "OBRA LUNAR") + robo(120, 200, 1, COR[2]) + robo(340, 268, 0, COR[3], flip=True)
    return o


def selva():
    o = ceu("#bfe3a0", "#3f7a4a", "gv")
    for k in range(6):
        o += C(20 + k * 75, 40 + (k % 2) * 20, 50, "#4f9a52", 1.2)
    for k in range(4):
        y = 270 - k * 48
        w = 300 - k * 66
        o += R(205 - w / 2, y, w, 48, "#c9b27a", vol=5)
    o += R(185, 104, 40, 30, "#3a2f2f")
    o += f'<path d="M0,290 L410,290 L410,330 L0,330 Z" fill="#6b4f2f"/>'
    o += C(340, 250, 34, "#8a7f6f", 1.4, vol=5) + '<path d="M300,250 h-30 M302,262 h-40 M300,238 h-24" stroke="#ffffff" stroke-width="3" opacity="0.8"/>'
    for x in (90, 150):
        o += f'<path d="M{x},0 q10,80 -6,140" stroke="#2f6b35" stroke-width="5" fill="none"/>'
    o += placa(14, 250, "DEMOLIÇÃO") + robo(205, 126, 3, COR[0]) + robo(100, 290, 4, COR[1])
    return o


def parque():
    o = ceu("#2a1f4f", "#6b4a8a", "gp")
    o += C(130, 150, 100, "none", 1.0) if False else ""
    o += f'<circle cx="130" cy="150" r="100" fill="none" stroke="#e6d36a" stroke-width="8"/>'
    for k in range(8):
        a = k * math.pi / 4
        o += f'<path d="M130,150 L{130 + math.cos(a) * 100},{150 + math.sin(a) * 100}" stroke="#e6d36a" stroke-width="4"/>'
        o += R(130 + math.cos(a) * 100 - 12, 150 + math.sin(a) * 100, 24, 18, ["#ff6b6b", "#4f86d9", "#5cc45c", "#f2c84b"][k % 4], 1.0)
    o += poly([(100, 290), (130, 150), (160, 290)], "#8a7a9a")
    o += '<path d="M200,280 C240,120 300,120 330,200 S380,280 410,150" stroke="#d8c0e8" stroke-width="8" fill="none"/>'
    o += '<path d="M200,280 C240,120 300,120 330,200 S380,280 410,150" stroke="#8a6aa0" stroke-width="3" fill="none" stroke-dasharray="6 8"/>'
    o += R(0, 290, 410, 40, "#3a3050")
    o += '<path d="M40,250 q20,-10 40,0" stroke="#ffffff" stroke-width="3" fill="none"/>'
    o += placa(290, 290, "PARQUE FECHADO") + robo(230, 290, 2, COR[3]) + robo(60, 290, 0, COR[2])
    return o


def polar():
    o = ceu("#1d3557", "#9fd0e6", "gpo")
    for k, c in enumerate(["#5cf0b0", "#7ab8ff", "#c08cff"]):
        o += f'<path d="M0,{60 + k * 18} C120,{20 + k * 18} 260,{110 + k * 18} 410,{50 + k * 18}" stroke="{c}" stroke-width="12" fill="none" opacity="0.45"/>'
    o += poly([(0, 260), (410, 250), (410, 330), (0, 330)], "#eef6fb")
    o += R(150, 170, 160, 80, "#d14b4b", vol=5) + R(170, 190, 30, 24, "#9fd0e6") + R(250, 190, 30, 24, "#9fd0e6")
    o += poly([(140, 170), (230, 130), (320, 170)], "#eef6fb")
    o += '<path d="M60,280 l30,8 l-10,14 l40,6" stroke="#7ab8d6" stroke-width="3" fill="none"/>'
    o += f'<ellipse cx="90" cy="300" rx="40" ry="10" fill="#4f86d9" opacity="0.7"/>'
    for k in range(5):
        o += poly([(30 + k * 70, 0), (38 + k * 70, 0), (34 + k * 70, 26)], "#dff2fb", 1.0) if k % 2 else ""
    o += placa(320, 250, "BASE POLAR") + robo(200, 170, 4, COR[1]) + robo(300, 262, 1, COR[0], flip=True)
    return o


def doces():
    o = ceu("#ffd6ec", "#bfe6ff", "gd")
    cores = ["#ff6b6b", "#4f86d9", "#5cc45c", "#f2c84b", "#c08cff"]
    for k in range(5):
        for j in range(2):
            o += R(40 + j * 48, 270 - k * 44, 44, 40, cores[(k + j) % 5], vol=4)
            o += C(62 + j * 48, 266 - k * 44, 6, shade(cores[(k + j) % 5], 0.2), 0.8)
    o += R(200, 200, 160, 90, "#8a5a3a", vol=5) + R(214, 140, 132, 60, "#f2a7c3", vol=4) + R(234, 100, 92, 40, "#fff0f6", vol=3)
    o += '<path d="M200,210 q10,20 20,0 q10,26 22,0 q10,18 20,0 q12,30 26,0 q8,16 18,0 q10,22 24,0 q6,12 18,0" stroke="#5a3520" stroke-width="10" fill="none" stroke-linecap="round"/>'
    o += C(280, 92, 8, "#ff6b6b", 0.8)
    o += R(0, 290, 410, 40, "#e8c6a0")
    o += placa(290, 296, "OBRA DOCE") + robo(150, 290, 3, COR[2]) + robo(380, 290, 0, COR[1], flip=True)
    return o


TEMAS = [
    ("ATLÂNTIDA", "cidade submersa", "templo de colunas e cúpulas de vidro", "quebrou a cúpula: ALAGA (a água sobe e empurra)", atlantida, "#1f7f9a"),
    ("SIDERÚRGICA", "fundição abandonada", "fornos, chaminés, passarelas", "AÇO DERRETIDO embaixo; a panela vira e derrama", siderurgica, "#b5482f"),
    ("ILHAS NAS NUVENS", "castelo no céu", "torres presas por balões e correntes", "quebrou a âncora: a ilha INCLINA · VENTO empurra", nuvens, "#c0608a"),
    ("BASE LUNAR", "obra na Lua", "módulos e cúpulas pressurizadas", "POUCA GRAVIDADE · furo SUGA para o buraco", lua, "#3a4a7a"),
    ("TEMPLO NA SELVA", "ruína perdida", "pirâmide com armadilhas", "PEDRAS ROLAM quando a estrutura quebra · cipós", selva, "#3f7a4a"),
    ("PARQUE ABANDONADO", "diversão à noite", "roda-gigante, montanha-russa", "a roda-gigante solta GIRA E ROLA · carrinhos na trilha", parque, "#5a3f8a"),
    ("ESTAÇÃO POLAR", "base no gelo", "base de pesquisa sobre o gelo", "chão ESCORREGA · gelo quebrado vira ÁGUA GELADA", polar, "#3f7aa0"),
    ("FÁBRICA DE DOCES", "torres de blocos e bolo", "blocos de brinquedo e bolo gigante", "blocos QUICAM · chocolate derretido GRUDA", doces, "#c25a8a"),
]


def cartaz(x, y, k, tema):
    nome, sub, estrutura, regra, fn, cor = tema
    o = f'<g transform="translate({x},{y})">'
    o += chunk(0, 0, 450, 610, CREAM, 22, 6, 10)
    o += f'<rect x="0" y="0" width="450" height="64" rx="22" fill="{cor}" stroke="{INK}" stroke-width="6"/><rect x="3" y="40" width="444" height="24" fill="{cor}"/>'
    o += T(225, 46, f"{k + 1} · {nome}", 32, "#ffffff", extra=f'stroke="{INK}" stroke-width="8" paint-order="stroke"')
    o += f'<g transform="translate(20,78)"><clipPath id="cl{k}"><rect width="{W}" height="{H}" rx="10"/></clipPath><g clip-path="url(#cl{k})">{fn()}</g>'
    o += f'<rect width="{W}" height="{H}" rx="10" fill="none" stroke="{INK}" stroke-width="5"/></g>'
    o += T(225, 446, sub, 22, "#6b5a70")
    o += T(30, 486, "ESTRUTURA", 17, "#6b5a70", "start") + T(30, 512, estrutura, 20, INK, "start")
    o += f'<rect x="20" y="528" width="410" height="66" rx="12" fill="#fff3b0" stroke="{INK}" stroke-width="3"/>'
    o += T(36, 552, "REGRA-ASSINATURA", 16, "#8a5a10", "start")
    o += T(36, 580, regra, 18 if len(regra) < 46 else 16, INK, "start")
    return o + "</g>"


def prancha():
    PW, PH = 1920, 1440
    b = [f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>', ca.defs(),
         title(PW / 2, 70, "PRÓXIMOS MAPAS — 8 TEMAS (estrutura + mundo + regra-assinatura)", 46)]
    for k, tema in enumerate(TEMAS):
        b.append(cartaz(20 + (k % 4) * 475, 120 + (k // 4) * 650, k, tema))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH}" viewBox="0 0 {PW} {PH}">{style}{"".join(b)}</svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/mapas_temas.svg"), os.path.join(OUT, "temas.png"), PW, PH, 1)
    print(render_all(), os.path.join(OUT, "temas.png"))


if __name__ == "__main__":
    prancha()
