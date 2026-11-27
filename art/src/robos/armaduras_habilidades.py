"""PRANCHA — HABILIDADE ESPECIAL de cada armadura-mecha (pedido 2026-11-27, decisões 1B 2A 3A 4B):
Bola = movimento · Broca = dash furando (segura até acabar o combustível) · Fornalha = lança-chamas em 8 direções ·
Empilhadeira = agarra e arremessa · PARA-RAIOS (ex-Soldador) = raio em cadeia: até 3 alvos, mais fraco a cada pulo,
também pula em estrutura de METAL (vigas/andaimes) e danifica.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/armaduras_habilidades.py → art/out/robos_v2/armaduras_habilidades.png
"""
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import armaduras_conceito as ac  # noqa: E402
from armaduras_conceito import R, E, S, P_, DARK, STEEL, STEEL_D, STEEL_L, YEL, YEL_D, ab, eu, label, INK, queue, render_all, shade  # noqa: E402

ELEC = "#7fe7ff"


# ---------------------------------------------------------------- PARA-RAIOS (substitui o Soldador): bobina de Tesla nas costas, braço-eletrodo
def para_raios(col):
    casco = "#2f3f5a"
    costas = R(-60, -176, 14, 70, 4, DARK, k=0.3)
    for i in range(5):
        costas += E(-53, -112 - i * 13, 13 - i, 4.5, "#c98a3a", k=0.2)                        # bobina de cobre
    costas += E(-53, -186, 10, 10, STEEL_L, k=0.3) + f'<circle cx="-53" cy="-186" r="16" fill="{ELEC}" opacity="0.3"/>'
    costas += raio((-53, -186), (-30, -214), 2.2, seed=3) + raio((-53, -186), (-80, -206), 2.2, seed=4)
    peito = R(-14, -122, 36, 10, 4, ELEC, k=0.2) + f'<rect x="-16" y="-124" width="40" height="14" rx="5" fill="{ELEC}" opacity="0.3"/>'
    arma = f'<path d="M34,-106 L52,-90 L64,-92" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(60, -102, 24, 18, 5, casco, k=0.4) + R(84, -98, 18, 10, 3, STEEL_D, k=0.3)
    arma += P_([(100, -104), (114, -93), (100, -82)], "#c98a3a", k=0.2) + E(116, -93, 7, 7, ELEC, k=0.2) + f'<circle cx="116" cy="-93" r="14" fill="{ELEC}" opacity="0.35"/>'
    return ac.mecha(col, casco, arma, costas, peito, H=50, tw=1.0, th=1.0)


def raio(a, b, w=4.0, seed=1, n=7, amp=9):
    rnd = random.Random(seed)
    pts = [a]
    for i in range(1, n):
        u = i / n
        x, y = a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u
        nx, ny = -(b[1] - a[1]), b[0] - a[0]
        L = math.hypot(nx, ny) or 1
        o = rnd.uniform(-amp, amp)
        pts.append((x + nx / L * o, y + ny / L * o))
    pts.append(b)
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return (f'<path d="{d}" stroke="{ELEC}" stroke-width="{w * 2.6:.1f}" fill="none" opacity="0.35" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="#ffffff" stroke-width="{w:.1f}" fill="none" stroke-linejoin="round" stroke-linecap="round"/>')


def robo(x, y, col, face="dor", s=1.0, rot=0):
    pz = dict(eu.ru.PARADO) if hasattr(eu, "ru") else {}
    body = eu.desenha(0, col, "parado")
    return f'<g transform="translate({x},{y}) rotate({rot}) scale({s})">{body}</g>'


def chao(x0, x1, y):
    return f'<rect x="{x0}" y="{y}" width="{x1 - x0}" height="8" rx="3" fill="#c9b99a"/>'


def bloco(x, y, w=32, h=32, quebrado=False):
    o = R(x, y, w, h, 3, "#d9a35f", k=0.4) + f'<path d="M{x + 3},{y + 3} L{x + w - 3},{y + h - 3} M{x + w - 3},{y + 3} L{x + 3},{y + h - 3}" stroke="#b57a3e" stroke-width="2.4"/>'
    if quebrado:
        o += f'<path d="M{x + 6},{y + 4} l6,10 l-4,8 l8,6" stroke="#5a3a1e" stroke-width="2" fill="none"/>'
    return o


def viga(x, y, w):
    o = R(x, y, w, 12, 2, "#8a94a3", k=0.4) + "".join(f'<path d="M{x + i},{y + 2} l8,8 l8,-8" stroke="#5e6775" stroke-width="1.6" fill="none"/>' for i in range(4, int(w) - 16, 16))
    return o


def seta(x0, y0, x1, y1, col="#d42035", w=4):
    a = math.atan2(y1 - y0, x1 - x0)
    h = [(x1, y1), (x1 - math.cos(a - 0.45) * 14, y1 - math.sin(a - 0.45) * 14), (x1 - math.cos(a + 0.45) * 14, y1 - math.sin(a + 0.45) * 14)]
    return f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{col}" stroke-width="{w}" stroke-linecap="round" stroke-dasharray="10 7"/>' + P_(h, col, k=0.1)


# ---------------------------------------------------------------- painéis (cada um em coordenadas locais 0..900 x 0..420, chão em 360)
def painel_bola():
    o = chao(0, 900, 360) + bloco(560, 296, 64, 64)
    path = "M60,330 C200,330 300,330 420,330 C470,330 520,200 600,200 C680,200 700,330 820,330"
    o += f'<path d="{path}" stroke="#ffffff" stroke-width="6" fill="none" stroke-dasharray="14 10" opacity="0.8"/>'
    for x, op in ((120, 0.25), (220, 0.45)):
        o += f'<g opacity="{op}" transform="translate({x},360) scale(0.9)">{ac.bola_fechada("#f06aa8", x)}</g>'
    o += f'<g transform="translate(330,360) scale(0.9)">{ac.bola_fechada("#f06aa8", 200)}</g>'
    o += robo(820, 360, "#5cc45c", s=1.1, rot=-30) + ab.fx_estrela(820, 320, 0.4, 16)
    o += label(600, 170, "pula sobre o obstáculo", 18, "#2a4a58")
    return o, "T03 · BOLA — MOVIMENTO", "Fecha-se na bola: rola rápido, freia firme, PULA e QUICA no ar. Quem é atropelado leva dano e é jogado."


def painel_broca():
    o = chao(0, 900, 360)
    for y in (232, 264, 296, 328):
        for x in (520, 552):
            o += bloco(x, y, 32, 32, quebrado=True)
    o += "".join(P_([(530 + random.Random(i).uniform(-30, 60), 250 + random.Random(i + 9).uniform(-30, 80)), (540 + random.Random(i).uniform(-30, 60), 240 + random.Random(i + 9).uniform(-30, 80)), (548 + random.Random(i).uniform(-30, 60), 256 + random.Random(i + 9).uniform(-30, 80))], "#b57a3e", k=0.1) for i in range(12))
    o += "".join(f'<path d="M{80 + i * 40},{280 + (i % 3) * 14} h{60 + i * 8}" stroke="#ffffff" stroke-width="6" stroke-linecap="round" opacity="{0.25 + i * 0.1:.2f}"/>' for i in range(6))
    o += f'<g transform="translate(380,360) scale(0.95)">{ac.broca("#f2c84b")}</g>'
    o += robo(760, 330, "#4f86d9", s=1.1, rot=40) + ab.fx_estrela(740, 300, 0.4, 16)
    o += R(40, 40, 260, 26, 10, "#3a3f4a", k=0.3) + R(44, 44, 150, 18, 8, "#ff9a3a", k=0.2) + label(170, 90, "combustível: SEGURE até acabar", 16, "#2a4a58")
    return o, "T05 · BROCA — DASH FURANDO", "SEGURE o golpe: dispara para a frente girando a broca, FURA blocos e empurra quem estiver no caminho, até acabar o combustível."


def painel_fornalha():
    o = chao(0, 900, 360)
    cx, cy = 450, 260
    for k in range(8):
        a = math.radians(k * 45)
        x1, y1 = cx + math.cos(a) * 150, cy + math.sin(a) * 110
        if y1 > 360:
            continue
        o += seta(cx + math.cos(a) * 70, cy + math.sin(a) * 50, x1, y1, "#ff7a1f", 3)
    o += f'<g transform="translate(410,360) scale(0.9)">{ac.fornalha("#4f86d9")}</g>'
    o += P_([(560, 270), (720, 230), (690, 270), (740, 300), (560, 290)], "#ff6a1a", k=0.3) + P_([(560, 274), (660, 258), (640, 276), (668, 290), (560, 286)], "#ffe27a", k=0.2)
    o += robo(760, 360, "#5cc45c", s=1.0) + '<circle cx="760" cy="320" r="30" fill="#ff7a1f" opacity="0.35"/>'
    o += label(450, 60, "8 direções: mire com o direcional", 18, "#2a4a58")
    return o, "T01 · FORNALHA — LANÇA-CHAMAS", "Solta fogo contínuo para a direção que você mirar (8 direções), enquanto tiver combustível; queima quem fica na chama."


def painel_empilhadeira():
    o = chao(0, 900, 360)
    o += f'<g transform="translate(230,360) scale(0.85)">{ac.empilhadeira("#5cc45c")}</g>'
    o += robo(370, 286, "#f06aa8", s=0.9, rot=-10)
    o += f'<path d="M380,250 C470,60 640,60 760,250" stroke="#ffffff" stroke-width="6" fill="none" stroke-dasharray="14 10"/>' + seta(700, 160, 760, 250, "#ffffff", 0)
    o += robo(780, 330, "#f06aa8", s=0.9, rot=120) + ab.fx_estrela(790, 320, 0.5, 18) + ab.fx_onda(790, 360, 0.5, 1.0)
    o += label(370, 220, "1 · agarra no garfo", 18, "#2a4a58") + label(600, 70, "2 · arremessa", 18, "#2a4a58")
    return o, "T02 · EMPILHADEIRA — AGARRA E ARREMESSA", "Investe com o garfo, AGARRA o adversário e o ARREMESSA longe (a direção segue o direcional)."


def painel_para_raios():
    o = chao(0, 900, 360) + viga(560, 150, 260) + R(800, 150, 12, 210, 2, "#8a94a3", k=0.3)
    o += f'<g transform="translate(140,360) scale(0.85)">{para_raios("#f2c84b")}</g>'
    alvos = [(330, 330, "#4f86d9"), (480, 330, "#5cc45c"), (620, 330, "#f06aa8")]
    src = (240, 280)
    largs = [5.0, 3.4, 2.2]
    for i, (x, y, col) in enumerate(alvos):
        o += robo(x, 360, col)
        o += raio(src, (x, y - 30), largs[i], seed=10 + i)
        o += f'<circle cx="{x}" cy="{y - 30}" r="{26 - i * 6}" fill="{ELEC}" opacity="0.35"/>'
        o += label(x, y - 96, f"{['100', '60', '35'][i]}%", 18, "#1a6a8a")
        src = (x, y - 30)
    o += raio((330, 300), (600, 156), 2.6, seed=31) + f'<circle cx="600" cy="156" r="16" fill="{ELEC}" opacity="0.4"/>'
    o += label(690, 130, "pula também na VIGA de metal (danifica)", 16, "#1a6a8a")
    o += robo(820, 360, "#8a8a8a") + label(820, 260, "longe: não pula", 15, "#6b5a70")
    return o, "T06 · PARA-RAIOS — RAIO EM CADEIA (ex-Soldador)", "O raio acerta o alvo e PULA para o próximo que estiver perto: até 3 robôs, mais fraco a cada pulo; também conduz por vigas/andaimes de METAL e os danifica."


PAINEIS = [painel_bola, painel_broca, painel_fornalha, painel_empilhadeira, painel_para_raios]


def prancha():
    W, ph = 1920, 470
    H = 110 + ph * 3 + 20
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 56, "HABILIDADE ESPECIAL DE CADA MECHA (mesmas regras de duração/cargas de hoje)", 34)]
    for i, fn in enumerate(PAINEIS):
        svg, titulo, desc = fn()
        col, row = i % 2, i // 2
        x = 20 + col * 950 if i < 4 else 20 + 475
        y = 100 + row * ph
        b.append(f'<rect x="{x}" y="{y}" width="930" height="{ph - 14}" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(x + 465, y + 40, titulo, 24, INK))
        b.append(label(x + 465, y + 68, desc, 14, "#2a4a58", "middle", 600))
        b.append(f'<g transform="translate({x + 15},{y + 50}) scale(1.0)">{svg}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


if __name__ == "__main__":
    svg, w, h = prancha()
    queue(svg, os.path.join(HERE, "svg/armaduras_habilidades.svg"), os.path.join(ab.OUT, "armaduras_habilidades.png"), w, h, 1)
    print("habilidades:", render_all())
