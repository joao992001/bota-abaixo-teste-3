"""ESQUEMA — FASE 2 do Derruba: CARGUEIRO PERDIDO (biblioteca docs/fases/derruba/f2_cargueiro/, 2026-11-28).
3 cenas descendo o mar: Cargueiro no Alto-Mar → Destroços do Cargueiro (40% no tempo) / Atlântida (bateu 65%).
Etiquetas: verde = BASE FIXA · vermelho = QUEBRA · azul = ÁGUA (regra-assinatura). Rodar:
NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_catalogo.py → art/out/fase2/esquema.png
"""
import base64
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import mapas_detalhe as md  # noqa: E402
from mapas_detalhe import R, C, poly, grad, robo, zebra, placa, bolhas, quadro, listas, COR, SOFT  # noqa: E402
import controles_arte as ca  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
FERR, FERR2 = "#b5482f", "#8a3524"
CONT = ["#d14b4b", "#4f86d9", "#5cc45c", "#f2a33a", "#8a63d2", "#e0c34a"]
TAGC = {"FIXO": "#3c9a46", "QUEBRA": "#d42035", "ÁGUA": "#2f7fc0"}


def tag(x, y, px, py, kind, txt):
    cor = TAGC[kind]
    w = len(txt) * 9.2 + 24
    o = f'<path d="M{x + w / 2},{y + 16} L{px},{py}" stroke="{INK}" stroke-width="5"/><path d="M{x + w / 2},{y + 16} L{px},{py}" stroke="{cor}" stroke-width="2.5"/>'
    o += f'<circle cx="{px}" cy="{py}" r="6" fill="{cor}" stroke="{INK}" stroke-width="3"/>'
    o += f'<rect x="{x}" y="{y}" width="{w}" height="32" rx="10" fill="{cor}" stroke="{INK}" stroke-width="4"/>'
    return o + T(x + w / 2, y + 22, txt, 16, "#ffffff")


def conteiner(x, y, w, h, cor, k=1.0):
    o = R(x, y, w, h, cor, 1.0, vol=4 * k)
    for j in range(int(w / 14)):
        o += f'<path d="M{x + 7 + j * 14},{y + 5} v{h - 10}" stroke="{shade(cor, -0.25)}" stroke-width="2"/>'
    return o


def ondas(w, y, amp=8, cor="#2a6fa8", cor2="#3f8fc8", seed=1):
    o = f'<rect x="0" y="{y}" width="{w}" height="400" fill="{cor}"/>'
    for k in range(3):
        yy = y + 6 + k * 22
        d = f"M0,{yy}" + "".join(f" q{20},{-amp} {40},0 t{40},0" for _ in range(int(w / 80) + 1))
        o += f'<path d="{d}" stroke="{cor2}" stroke-width="4" fill="none" opacity="0.8"/>'
    return o


# ---------------------------------------------------------------- cena 1: cargueiro no alto-mar
def cena1(w=900, h=440):
    o = grad(w, h, "#f6b27a", "#7a6fa8")
    for cx, cy, r in [(120, 70, 40), (170, 60, 50), (700, 90, 44), (760, 80, 36)]:
        o += C(cx, cy, r, "#c9b8d8", 0.9)
    o += ondas(w, 330, seed=2)
    # casco
    o += poly([(30, 300), (840, 300), (880, 250), (870, 300), (820, 380), (70, 380)], FERR, vol=6)
    o += R(30, 296, 830, 10, "#5a5a68", 1.0)
    # ponte de comando (fixa)
    o += R(60, 120, 130, 180, "#eef0f4", vol=5) + R(50, 110, 150, 18, "#cfd3da", 1.0)
    for k in range(3):
        o += R(74 + k * 38, 140, 28, 22, "#5a6f8f", 0.8)
    o += R(120, 70, 12, 40, "#8a8a9a", 0.8) + C(126, 66, 7, "#f2c84b", 0.6)
    # tampas dos porões (lajes) + contêineres empilhados
    for k, (x, n) in enumerate([(230, 3), (360, 2), (600, 3), (730, 2)]):
        o += R(x - 6, 286, 112, 12, "#7a7f8a", 1.0, vol=2)
        for j in range(n):
            o += conteiner(x, 246 - j * 40, 100, 40, CONT[(k * 2 + j) % len(CONT)])
    # guindaste do navio
    o += R(500, 120, 16, 176, "#e0a83a", 1.0) + R(500, 112, 160, 12, "#e0a83a", 1.0)
    o += f'<path d="M640,124 v60" stroke="{INK}" stroke-width="3"/>' + conteiner(605, 184, 70, 30, CONT[4])
    # onda batendo
    o += f'<path d="M800,300 q30,-60 70,-40 q-20,10 -10,40" fill="#cfe9f7" stroke="#ffffff" stroke-width="3"/>' + bolhas(780, 230, 880, 300, 8, 3)
    o += placa(720, 20, "CARGUEIRO PERDIDO", 15)
    o += robo(280, 166, 0, COR[0], 0.62) + robo(400, 206, 2, COR[2], 0.62, flip=True) + robo(650, 166, 1, COR[1], 0.62) + robo(460, 286, 3, COR[3], 0.62)
    o += tag(20, 330, 125, 220, "FIXO", "ponte de comando") + tag(330, 395, 450, 312, "FIXO", "casco / convés (chão)")
    o += tag(250, 34, 280, 150, "QUEBRA", "contêineres") + tag(520, 60, 508, 140, "QUEBRA", "guindaste")
    o += tag(560, 330, 650, 292, "QUEBRA", "tampas dos porões") + tag(730, 160, 830, 270, "ÁGUA", "ondas no convés")
    return o


# ---------------------------------------------------------------- cena 2a: destroços do cargueiro
def cena2a(w=880, h=420):
    o = grad(w, h, "#bfe6f0", "#f3e3b6")
    o += ondas(w, 300, 6, "#3fa7a0", "#7fd0c8", 4)
    # ilhéu de rochas (fixo)
    o += poly([(0, 300), (40, 230), (120, 210), (220, 240), (260, 300), (260, 420), (0, 420)], "#8a8f99", vol=6)
    o += poly([(560, 300), (600, 270), (680, 280), (700, 300)], "#8a8f99", vol=4)
    # metade do casco tombada sobre as rochas
    o += f'<g transform="rotate(-16 330 250)">' + poly([(170, 200), (470, 200), (450, 300), (190, 300)], FERR, vol=6)
    o += poly([(470, 200), (490, 225), (460, 245), (485, 270), (450, 300)], FERR2, 1.0) + R(170, 196, 300, 10, "#5a5a68", 1.0) + "</g>"
    # contêineres espalhados e boiando
    o += f'<g transform="rotate(8 600 250)">' + conteiner(560, 230, 100, 40, CONT[1]) + "</g>"
    o += conteiner(720, 286, 100, 40, CONT[0]) + f'<g transform="rotate(-6 80 190)">' + conteiner(40, 170, 90, 40, CONT[2]) + "</g>"
    # mastro caído como ponte
    o += f'<g transform="rotate(-8 600 220)">' + R(470, 214, 260, 12, "#8a8a9a", 1.0) + "</g>"
    o += f'<path d="M0,330 h{w}" stroke="#ffffff" stroke-width="3" stroke-dasharray="14 10" opacity="0.9"/>'
    o += robo(300, 205, 0, COR[0], 0.6) + robo(610, 226, 2, COR[2], 0.6) + robo(770, 286, 4, COR[1], 0.6, flip=True)
    o += tag(20, 360, 120, 260, "FIXO", "rochas do ilhéu") + tag(280, 30, 330, 230, "QUEBRA", "casco tombado")
    o += tag(640, 150, 610, 240, "QUEBRA", "contêineres") + tag(430, 96, 560, 214, "QUEBRA", "mastro caído")
    o += tag(620, 370, 700, 332, "ÁGUA", "maré sobe e desce")
    return o


# ---------------------------------------------------------------- cena 2b: atlântida
def cena2b(w=880, h=420):
    o = md.at_templo(w, h, agua=0.45, s=0.6)
    o += f'<g transform="rotate(14 330 200)">' + R(200, 196, 300, 12, "#8a8a9a", 1.0) + "</g>"
    o += f'<g transform="rotate(-10 470 140)">' + conteiner(420, 120, 100, 40, CONT[3]) + "</g>"
    o += robo(330, 360, 0, COR[0], 0.6) + robo(520, 360, 2, COR[2], 0.6, flip=True) + robo(640, 280, 1, COR[1], 0.6, rot=-15)
    o += tag(20, 380, 180, 360, "FIXO", "escadarias e muralhas") + tag(80, 60, 300, 250, "QUEBRA", "colunas e frontão")
    o += tag(470, 40, 470, 138, "QUEBRA", "pedaços do navio") + tag(640, 120, 640, 200, "ÁGUA", "cúpula: quebrou, alaga")
    return o


def prancha():
    PW, PH = 1920, 1760
    b = [f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>', ca.defs(), title(PW / 2, 70, "CARGUEIRO PERDIDO — ESQUEMA DAS 3 CENAS", 54)]
    b.append(T(PW / 2, 116, "a viagem desce o mar: superfície → destroços → Atlântida · REGRA-ASSINATURA: a ÁGUA (alagado = anda devagar, pulo flutua, golpe joga longe)", 22, "#fff4c8"))
    leg = [("FIXO", "base fixa: não quebra"), ("QUEBRA", "conta na destruição"), ("ÁGUA", "regra-assinatura")]
    for k, (kd, tx) in enumerate(leg):
        x = 560 + k * 290
        b.append(f'<rect x="{x}" y="134" width="30" height="24" rx="6" fill="{TAGC[kd]}" stroke="#ffffff" stroke-width="2"/>' + T(x + 40, 153, f"{kd}: {tx}", 18, "#ffffff", "start"))
    b.append(quadro(510, 180, 900, 440, cena1(), 6))
    b.append(T(960, 655, "1 · CARGUEIRO NO ALTO-MAR (início, na superfície)", 26, "#ffffff"))
    b.append(f'<path d="M760,668 C700,700 520,700 480,730" stroke="#8fd46a" stroke-width="10" fill="none"/>' + T(330, 722, "40% no tempo: o navio encalha", 20, "#8fd46a"))
    b.append(f'<path d="M1160,668 C1220,700 1400,700 1440,730" stroke="#ec6448" stroke-width="10" fill="none"/>' + T(1640, 722, "bateu 65%: o navio parte e afunda", 20, "#ec6448"))
    b.append(quadro(40, 740, 880, 420, cena2a(), 6))
    b.append(quadro(1000, 740, 880, 420, cena2b(), 6))
    b.append(T(480, 1196, "2a · DESTROÇOS DO CARGUEIRO (encalhado no ilhéu)", 24, "#ffffff"))
    b.append(T(1440, 1196, "2b · ATLÂNTIDA (o navio caiu sobre a cidade) — os últimos momentos", 24, "#ffffff"))
    blocos = [
        ("PERIGOS / MECANISMOS", [("Ondas no convés", "empurram de tempos em tempos (1)"), ("Gancho do guindaste", "balança e derruba contêiner (1)"),
                                  ("Maré", "alaga a parte baixa (2a)"), ("Cúpula de vidro", "quebrou = alaga (2b)")]),
        ("EVENTOS DO MAPA", [("Onda Gigante", "atravessa e arrasta"), ("Tempestade", "raios racham a estrutura"),
                             ("Cardume", "peixes empurram"), ("Polvo da Grua", "agarra e joga")]),
        ("ENGENHOCAS", [("Todas as atuais", "revisar as que não cabem na água"), ("Escafandro (Defesa, nova)", "sem lentidão na água por 10 s"),
                        ("Torpedo (Ataque, novo)", "corre pela água e explode")]),
        ("SKINS DO MAPA", [("Marinheiro", "boné e colete salva-vidas"), ("Mergulhador", "escafandro de cobre"),
                           ("Pirata Afogado", "chapéu e casco"), ("Coral / Água-viva", "corais · transparente")]),
    ]
    b.append(listas(40, 1240, blocos, "#1f6f8a"))
    b.append(T(PW / 2, 1610, "Tudo marcado como PROPOSTO na biblioteca (docs/fases/derruba/f2_cargueiro/) — o que você aprovar vira APROVADO; depois vêm as fotografias de cada cena", 20, "#fff4c8"))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH - 120}" viewBox="0 0 {PW} {PH - 120}">{style}{"".join(b)}</svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/f2_esquema.svg"), os.path.join(OUT, "esquema.png"), PW, PH - 120, 1)
    print(render_all(), os.path.join(OUT, "esquema.png"))


if __name__ == "__main__":
    prancha()
