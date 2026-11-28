"""PRANCHA — PROJETOS DE DEMOLIÇÃO v2 (pedido 2026-11-28: a tela antiga não agradou).
Uma cena só, em papel e giz: o prédio do PROJETO (próximo mapa) de pé no canteiro; cada ponto ganho = a bola da grua
derruba um andar. Tickets dos ganhos à esquerda. Projeto completo = o prédio vem abaixo e o cartaz do mapa novo é revelado.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/projetos_v2.py
"""
import base64
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import controles_arte as ca  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/ui")
YEL, RED, SOFT = "#f2c84b", "#d42035", "#6b5a70"
TIJ, CONC, JAN = "#d98b5f", "#c9c0b0", "#5a6f8f"


def P(d, fill, box, k=2.0, vol=0.0):
    return ca.P(d, fill, box, k, vol=vol)


def rect(x, y, w, h, fill, k=2.0, vol=0.0):
    return P(ca.rr_d(x, y, w, h, 2), fill, (x, y, x + w, y + h), k, vol)


def placa(cx, y, txt, w=860, fs=56):
    o = f'<path d="M{cx - w / 2 + 60},{y - 40} L{cx - w / 2 + 60},{y} M{cx + w / 2 - 60},{y - 40} L{cx + w / 2 - 60},{y}" stroke="{INK}" stroke-width="5"/>'
    o += chunk(cx - w / 2, y, w, 104, YEL, 14, 6, 8)
    for k in range(int(w / 28)):
        x = cx - w / 2 + 10 + k * 28
        o += f'<path d="M{x},{y + 96} l14,-14 h12 l-14,14 Z" fill="{INK}"/>'
    return o + T(cx, y + 66, txt, fs, INK)


def fundo():
    o = '<defs><linearGradient id="ceu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fd3e6"/><stop offset="1" stop-color="#d9f0f2"/></linearGradient></defs>'
    o += '<rect width="1920" height="1080" fill="url(#ceu)"/>'
    o += f'<circle cx="300" cy="170" r="90" fill="#fde9a6" opacity="0.8"/>'
    for i, (x, h) in enumerate([(60, 420), (230, 520), (1500, 470), (1700, 560)]):
        o += P(ca.rr_d(x, 900 - h, 150, h, 4), "#b9cfd6", (x, 900 - h, x + 150, 900), 2.2)
    o += rect(0, 880, 1920, 200, "#c7b394", 2.4) + rect(0, 870, 1920, 26, "#a99673", 2.0)
    return o


def ticket(x, y, w, txt, sub, pts, cor, aceso=False, rot=0.0):
    o = f'<g transform="rotate({rot} {x + w / 2} {y + 50})">'
    if aceso:
        o += f'<rect x="{x - 10}" y="{y - 10}" width="{w + 20}" height="120" rx="18" fill="{YEL}" opacity="0.8"/>'
    o += chunk(x, y, w, 100, CREAM, 12, 5, 6)
    o += f'<path d="M{x + w - 120},{y + 8} v84" stroke="{INK}" stroke-width="3" stroke-dasharray="8 7"/>'
    o += f'<circle cx="{x + 30}" cy="{y + 50}" r="14" fill="#9fc9d3" stroke="{INK}" stroke-width="4"/>'
    o += T(x + 58, y + 46, txt, 30, INK, "start") + T(x + 58, y + 78, sub, 19, SOFT, "start", 600)
    o += T(x + w - 60, y + 66, f"+{pts}", 50, cor, extra=f'stroke="{INK}" stroke-width="8" paint-order="stroke"')
    return o + "</g>"


def tickets(estado):
    o = ticket(70, 250, 640, "PARTIDA VÁLIDA", "1 min ou mais, com vencedor", 1, YEL, aceso=estado == 0, rot=-1.2)
    o += ticket(70, 380, 640, "CENA NOVA: TELHADO", "1ª vez neste mapa", 2, YEL, aceso=estado == 1, rot=0.8)
    o += f'<path d="M90,520 h600" stroke="{INK}" stroke-width="5" stroke-dasharray="16 12"/>'
    o += T(100, 590, "NESTA PARTIDA", 34, INK, "start") + T(690, 600, "+3", 72, YEL, "end", extra=f'stroke="{INK}" stroke-width="12" paint-order="stroke"')
    o += T(390, 660, "como ganhar: +1 partida válida · +2 cada cena que ninguém viu ainda", 20, SOFT, w=600)
    return o


def predio(x0, base, andares, de_pe, batendo=False, ruina=0):
    """Prédio de papel e giz: andares de baixo para cima; de_pe = quantos ainda estão de pé."""
    o = ""
    w, h = 460, 84
    for i in range(de_pe):
        y = base - (i + 1) * h
        cor = TIJ if i % 2 == 0 else shade(TIJ, -0.06)
        o += rect(x0, y, w, h - 4, cor, 2.0, vol=6)
        o += rect(x0 - 10, y + h - 14, w + 20, 12, CONC, 1.4)
        for j in range(4):
            o += rect(x0 + 34 + j * 108, y + 18, 64, 42, JAN, 1.2)
            o += f'<path d="M{x0 + 66 + j * 108},{y + 18} v42" stroke="{shade(JAN, 0.35)}" stroke-width="3"/>'
        o += T(x0 - 34, y + 54, str(i + 1), 30, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
    # andares que já caíram: contorno tracejado de giz (o projeto)
    for i in range(de_pe, andares):
        y = base - (i + 1) * h
        o += f'<rect x="{x0}" y="{y}" width="{w}" height="{h - 4}" fill="none" stroke="#ffffff" stroke-width="4" stroke-dasharray="14 10" opacity="0.85"/>'
        o += T(x0 - 34, y + 54, str(i + 1), 30, YEL, extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
    if batendo and de_pe > 0:
        y = base - de_pe * h
        rnd = random.Random(3)
        o += f'<path d="M{x0 + w - 10},{y + 10} l-40,22 l18,14 l-46,26" stroke="{INK}" stroke-width="5" fill="none" stroke-linejoin="round"/>'
        for k in range(9):
            a = rnd.uniform(-1.2, 1.2)
            o += f'<circle cx="{x0 + w + 20 + math.cos(a) * rnd.uniform(20, 90)}" cy="{y + 40 + math.sin(a) * rnd.uniform(10, 60)}" r="{rnd.uniform(16, 34)}" fill="#e9dfcf" opacity="0.92"/>'
        for k in range(6):
            o += rect(x0 + w + 10 + k * 26, y + 70 + (k % 3) * 22, 18, 14, TIJ, 1.0)
    if ruina:
        rnd = random.Random(9)
        for k in range(ruina):
            bx = x0 - 40 + rnd.uniform(0, w + 80)
            o += P(f"M{bx},{base} l{rnd.uniform(20, 40)},{-rnd.uniform(20, 50)} l{rnd.uniform(20, 40)},{rnd.uniform(20, 50)} Z", TIJ if k % 2 else CONC,
                   (bx, base - 60, bx + 80, base), 1.4)
    return o


def grua(x, alvo_y, puxada=0.0):
    o = rect(x, 160, 34, 720, "#e0a83a", 1.6)
    for k in range(14):
        o += f'<path d="M{x},{180 + k * 50} l34,40 M{x + 34},{180 + k * 50} l-34,40" stroke="#b07a1e" stroke-width="4"/>'
    o += rect(x - 420, 150, 560, 30, "#e0a83a", 1.6)
    bx = x - 330 + puxada
    o += f'<path d="M{x - 330},{180} L{bx},{alvo_y - 40}" stroke="{INK}" stroke-width="5"/>'
    o += P(ca.circ_d(bx, alvo_y, 56), "#4b505c", (bx - 56, alvo_y - 56, bx + 56, alvo_y + 56), 1.6, vol=8)
    o += f'<circle cx="{bx - 16}" cy="{alvo_y - 18}" r="12" fill="#7d8494" opacity="0.7"/>'
    return o


def contador(x, y, feitos, total, falta_txt, cor_txt=INK):
    o = chunk(x, y, 560, 210, CREAM, 18, 6, 8)
    o += T(x + 280, y + 52, "PROJETO 2 · PRÓXIMO MAPA", 26, SOFT)
    cw = 480 / total
    for k in range(total):
        cx = x + 40 + k * cw
        on = k < feitos
        o += f'<rect x="{cx + 4}" y="{y + 76}" width="{cw - 8}" height="54" rx="10" fill="{RED if on else "#e2d9c6"}" stroke="{INK}" stroke-width="4"/>'
        if on:
            o += f'<path d="M{cx + 14},{y + 96} l{cw - 28},20 M{cx + 14},{y + 116} l{cw - 28},-20" stroke="#ffffff" stroke-width="4" opacity="0.6"/>'
    o += T(x + 280, y + 182, falta_txt, 30, cor_txt)
    return o


def cartaz_novo(cx, cy, s=1.0):
    o = f'<g transform="translate({cx},{cy}) rotate(-3) scale({s})">'
    o += chunk(-260, -200, 520, 380, "#f4ecdc", 18, 6, 10)
    o += rect(-230, -170, 460, 260, "#9fd0dc", 2.0)
    o += P("M-230,90 L-130,-30 L-60,40 L40,-90 L230,90 Z", "#7b8f6a", (-230, -90, 230, 90), 1.8)
    o += rect(-40, -60, 90, 150, "#d98b5f", 1.4) + rect(70, -10, 70, 100, "#c9c0b0", 1.4)
    o += T(0, 140, "MAPA NOVO", 44, INK)
    o += f'<g transform="rotate(-12)"><rect x="-200" y="-60" width="400" height="96" rx="12" fill="none" stroke="{RED}" stroke-width="10"/>'
    o += T(0, 8, "LIBERADO!", 70, RED) + "</g>"
    return o + "</g>"


def quadro(estado):
    """estado 0: contando (ticket aceso, bola bate) · 1: andar caindo · 2: projeto completo · 3: sem mapa novo ainda."""
    o = fundo()
    o += placa(960, 30, "PROJETOS DE DEMOLIÇÃO")
    if estado < 2:
        o += tickets(estado)
        de_pe = 4 if estado == 0 else 3
        o += predio(1000, 880, 6, de_pe, batendo=True, ruina=4 if estado == 0 else 7)
        o += grua(1780, 880 - de_pe * 84 + 40, puxada=-60)
        o += contador(70, 690, 6 - de_pe, 6, "faltam %d → MAPA NOVO" % de_pe)
        o += chunk(560, 1000, 800, 56, "#f4ecdc", 14, 4, 0) + T(960, 1038, "PULAR  pula a animação", 26, INK)
    elif estado == 2:
        o += predio(1000, 880, 6, 0, ruina=18)
        rnd = random.Random(4)
        for k in range(26):
            o += f'<circle cx="{1000 + rnd.uniform(-80, 540)}" cy="{880 - rnd.uniform(0, 260)}" r="{rnd.uniform(30, 70)}" fill="#efe6d6" opacity="0.85"/>'
        o += cartaz_novo(1230, 470, 0.95)
        for k in range(40):
            o += f'<rect x="{rnd.uniform(800, 1700)}" y="{rnd.uniform(140, 700)}" width="14" height="22" fill="{rnd.choice([YEL, RED, "#4f86d9", "#5cc45c"])}" transform="rotate({rnd.uniform(0, 90)} 0 0)" opacity="0.9"/>'
        o += tickets(9)
        o += contador(70, 690, 6, 6, "PROJETO COMPLETO!", RED)
        o += chunk(460, 1000, 1000, 56, YEL, 14, 4, 0) + T(960, 1038, "PULAR  escolher o mapa novo  ·  sobra +1 → já conta no PROJETO 3", 26, INK)
    else:
        o += tickets(9)
        o += predio(1000, 880, 6, 0, ruina=18)
        o += f'<g transform="translate(1230,470) rotate(-3)">' + chunk(-260, -200, 520, 380, "#3f7fb5", 18, 6, 10)
        o += T(0, -60, "PRÓXIMO MAPA", 44, "#ffffff") + T(0, 10, "EM BREVE", 70, YEL, extra=f'stroke="{INK}" stroke-width="12" paint-order="stroke"')
        o += T(0, 90, "seus pontos ficam guardados:", 26, "#ffffff") + T(0, 130, "ele já chega liberado", 26, "#ffffff") + "</g>"
        o += contador(70, 690, 6, 6, "+3 GUARDADOS (total 9)", "#3c9a46")
        o += chunk(560, 1000, 800, 56, "#f4ecdc", 14, 4, 0) + T(960, 1038, "PULAR  segue para os resultados", 26, INK)
    return o


def prancha():
    W, H = 1920, 1400
    s = 0.47
    b = [f'<rect width="{W}" height="{H}" fill="#2a1a2e"/>', ca.defs(), title(W / 2, 70, "PROJETOS DE DEMOLIÇÃO — PROPOSTA v2", 54)]
    rot = ["1 · CONTA: o ticket acende e a bola derruba um andar", "2 · cada ponto = um andar no chão (poeira e tijolos)",
           "3 · PROJETO COMPLETO: o prédio vem abaixo e o mapa novo é revelado", "4 · sem mapa novo ainda: os pontos ficam guardados"]
    for k in range(4):
        x = 40 + (k % 2) * 940
        y = 120 + (k // 2) * 610
        b.append(f'<g transform="translate({x},{y}) scale({s})"><clipPath id="q{k}"><rect width="1920" height="1080"/></clipPath><g clip-path="url(#q{k})">{quadro(k)}</g></g>')
        b.append(f'<rect x="{x}" y="{y}" width="{1920 * s}" height="{1080 * s}" fill="none" stroke="#ffffff" stroke-width="4"/>')
        b.append(T(x + 1920 * s / 2, y + 1080 * s + 40, rot[k], 26, "#ffffff"))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{style}{"".join(b)}</svg>'
    queue(svg, os.path.join(HERE, "svg/projetos_v2.svg"), os.path.join(OUT, "projetos_v2.png"), W, H, 1)
    print(render_all(), os.path.join(OUT, "projetos_v2.png"))


if __name__ == "__main__":
    prancha()
