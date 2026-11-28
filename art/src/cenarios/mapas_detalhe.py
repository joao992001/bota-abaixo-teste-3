"""PRANCHAS DETALHADAS — ATLÂNTIDA × BASE LUNAR (2026-11-28, para o usuário escolher o 2º mapa).
Cada prancha: tela de jogo da cena 1 · regra-assinatura em 3 quadros · árvore das 7 cenas · perigos/eventos/engenhoca/skins.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/mapas_detalhe.py → art/out/mapas/detalhe_atlantida.png, detalhe_lua.png
"""
import base64
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
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
COR = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]
SOFT = "#6b5a70"
_g = [0]


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


def grad(w, h, c1, c2):
    _g[0] += 1
    gid = f"gr{_g[0]}"
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/>'
            f'<stop offset="1" stop-color="{c2}"/></linearGradient></defs><rect width="{w}" height="{h}" fill="url(#{gid})"/>')


def robo(x, y, model, col, s=1.0, flip=False, rot=0):
    sx = -s if flip else s
    return f'<g transform="translate({x},{y}) rotate({rot}) scale({sx},{s})">{eu.desenha(model, col, "parado")}</g>'


def zebra(x, y, w, h=14):
    o = R(x, y, w, h, "#f2c84b", 1.0)
    for k in range(int(w / 18)):
        o += f'<path d="M{x + 4 + k * 18},{y + h} l9,-{h} h7 l-9,{h} Z" fill="{INK}" opacity="0.85"/>'
    return o


def placa(x, y, txt, fs=14):
    w = len(txt) * fs * 0.66 + 22
    return R(x, y, w, fs * 2.2, "#f2c84b", 1.0, vol=3) + T(x + w / 2, y + fs * 1.5, txt, fs, INK)


def bolhas(x0, y0, x1, y1, n, seed=1, cor="#ffffff"):
    rnd = random.Random(seed)
    return "".join(f'<circle cx="{rnd.uniform(x0, x1):.0f}" cy="{rnd.uniform(y0, y1):.0f}" r="{rnd.uniform(3, 10):.1f}" fill="none" '
                   f'stroke="{cor}" stroke-width="2.5" opacity="0.85"/>' for _ in range(n))


def estrelas(w, h, n, seed=3):
    rnd = random.Random(seed)
    return "".join(f'<circle cx="{rnd.uniform(0, w):.0f}" cy="{rnd.uniform(0, h):.0f}" r="{rnd.uniform(0.8, 2.4):.1f}" fill="#ffffff" opacity="0.85"/>' for _ in range(n))


def gauge(cx, cy, r, v):
    o = f'<circle cx="{cx}" cy="{cy + r * 0.12}" r="{r}" fill="{INK}"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="{CREAM}"/>'
    cols = ["#2e9e4f", "#8fd46a", "#f2d04b", "#f39a3a", "#ec6448", "#a8233a"]
    for k in range(6):
        a0 = math.radians(150 + 240 * k / 6)
        a1 = math.radians(150 + 240 * (k + 1) / 6)
        rm = r * 0.72
        o += (f'<path d="M{cx + math.cos(a0) * rm},{cy + math.sin(a0) * rm} A{rm},{rm} 0 0 1 {cx + math.cos(a1) * rm},{cy + math.sin(a1) * rm}" '
              f'stroke="{cols[k]}" stroke-width="{r * 0.25}" fill="none"/>')
    an = math.radians(150 + 240 * v)
    o += f'<path d="M{cx},{cy} L{cx + math.cos(an) * r * 0.7},{cy + math.sin(an) * r * 0.7}" stroke="{INK}" stroke-width="{r * 0.12}" stroke-linecap="round"/>'
    return o + T(cx, cy + r * 0.9, f"{int(v * 100)}%", int(r * 0.42), "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')


# ================================================================== ATLÂNTIDA
AQ, AQ2 = "#3fb6c9", "#0f4f73"
MARM, MARM2 = "#ece3cf", "#d9cdb2"


def at_templo(w, h, agua=0.0, s=1.0):
    """Cena 1: Cúpula do Templo. agua = fração alagada (0..1) do lado direito."""
    o = grad(w, h, AQ, AQ2)
    for k in range(6):
        x = w * (0.05 + k * 0.17)
        o += f'<path d="M{x},0 L{x + 50 * s},0 L{x + 120 * s},{h} L{x + 20 * s},{h} Z" fill="#ffffff" opacity="0.07"/>'
    o += bolhas(0, 0, w, h * 0.5, int(16 * s) + 6, 4)
    g = h * 0.86
    o += poly([(0, g), (w * 0.3, g - 10 * s), (w * 0.7, g - 4 * s), (w, g - 14 * s), (w, h), (0, h)], "#d9c48f")
    # cúpula de ar grande
    cx, cy, rr = w * 0.5, g, w * 0.42
    o += f'<path d="M{cx - rr},{g} A{rr},{rr * 0.9} 0 0 1 {cx + rr},{g} Z" fill="#cff3f8" opacity="0.35" stroke="#ffffff" stroke-width="{4 * s}"/>'
    # templo
    base = g - 6 * s
    o += R(cx - 300 * s, base - 30 * s, 600 * s, 30 * s, MARM2, vol=4)
    for k in range(7):
        x = cx - 270 * s + k * 90 * s
        o += R(x, base - 210 * s, 34 * s, 180 * s, MARM, vol=4)
        o += R(x - 6 * s, base - 222 * s, 46 * s, 14 * s, MARM2, 1.0)
    o += R(cx - 310 * s, base - 252 * s, 620 * s, 32 * s, MARM2, vol=4)
    o += poly([(cx - 320 * s, base - 252 * s), (cx, base - 340 * s), (cx + 320 * s, base - 252 * s)], MARM, vol=5)
    o += C(cx, base - 290 * s, 18 * s, "#f2c84b", 1.0)
    # passarelas de mármore (plataformas)
    o += R(cx - 380 * s, base - 120 * s, 120 * s, 18 * s, MARM2, vol=3) + R(cx + 260 * s, base - 120 * s, 120 * s, 18 * s, MARM2, vol=3)
    if agua > 0:
        ax = cx + rr * 0.15
        top = g - (g - (cy - rr * 0.9)) * agua
        o += f'<rect x="{ax}" y="{top}" width="{w - ax}" height="{g - top}" fill="#3fc6dc" opacity="0.5"/>'
        o += f'<path d="M{ax},{top} q20,-8 40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0 t40,0" stroke="#ffffff" stroke-width="{3 * s}" fill="none"/>'
        o += f'<path d="M{cx + rr * 0.55},{cy - rr * 0.6} l{14 * s},{22 * s} l{-18 * s},{10 * s} l{16 * s},{20 * s}" stroke="#ffffff" stroke-width="{4 * s}" fill="none"/>'
        o += bolhas(ax, top, w, g, 10, 9)
    # grua submarina + placa
    o += R(w - 70 * s, g - 360 * s, 16 * s, 360 * s, "#e0a83a", 1.0)
    o += R(w - 220 * s, g - 372 * s, 190 * s, 14 * s, "#e0a83a", 1.0)
    o += f'<path d="M{w - 210 * s},{g - 358 * s} v{80 * s}" stroke="{INK}" stroke-width="{3 * s}"/>' + C(w - 210 * s, g - 270 * s, 14 * s, "#4b505c", 1.0)
    o += placa(30 * s, g - 60 * s, "OBRA SUBMARINA", 16 * s)
    return o


def at_mini(tipo, w=300, h=170):
    o = ""
    if tipo == "jardins":
        o = grad(w, h, "#54c7b0", "#1d6b6b")
        o += poly([(0, 140), (w, 130), (w, h), (0, h)], "#c9b27a")
        for k in range(6):
            x = 20 + k * 50
            o += f'<path d="M{x},140 q-10,-40 4,-80 q10,-20 -2,-40" stroke="#3f9a52" stroke-width="6" fill="none"/>'
        o += f'<path d="M180,140 a40,22 0 0 1 80,0 Z" fill="#f2a7c3"/><path d="M182,132 a38,30 0 0 1 76,-20" stroke="#d1708f" stroke-width="5" fill="none"/>'
        o += f'<rect x="150" y="70" width="150" height="70" fill="#3fc6dc" opacity="0.45"/>'
        o += robo(90, 140, 0, COR[0], 0.5) + robo(220, 118, 2, COR[2], 0.5, rot=-15)
    elif tipo == "tesouro":
        o = grad(w, h, "#2a6f8a", "#0b2f45")
        o += R(0, 140, w, 30, "#8a7a5a")
        o += C(150, 140, 50, "#f2c84b", 1.2) + C(120, 130, 20, "#ffe08a", 1.0) + C(180, 128, 16, "#ffe08a", 1.0)
        o += f'<g transform="rotate(-18 60 110)">' + R(40, 50, 36, 90, MARM, vol=3) + "</g>" + R(240, 50, 36, 90, MARM, vol=3)
        o += f'<ellipse cx="150" cy="60" rx="70" ry="26" fill="#cff3f8" opacity="0.35"/>'
        o += robo(100, 140, 3, COR[3], 0.5) + robo(260, 140, 1, COR[1], 0.5, flip=True)
    elif tipo == "aqueduto":
        o = grad(w, h, "#3fb6c9", "#14506b")
        for k in range(4):
            o += R(10 + k * 76, 60, 60, 16, MARM2, vol=2) + R(30 + k * 76, 76, 20, 80, MARM, vol=2)
        for k in range(4):
            y = 100 + k * 14
            o += f'<path d="M0,{y} q40,-8 80,0 t80,0 t80,0 t80,0" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.7"/>'
        o += '<path d="M230,110 l30,0 l-10,-8 m10,8 l-10,8" stroke="#ffffff" stroke-width="4" fill="none"/>'
        o += robo(120, 60, 4, COR[0], 0.5) + robo(200, 158, 2, COR[1], 0.5, rot=20)
    elif tipo == "fenda":
        o = grad(w, h, "#0b2238", "#02060d")
        o += poly([(0, 0), (90, 0), (60, h), (0, h)], "#1a2f45") + poly([(w, 0), (210, 0), (240, h), (w, h)], "#1a2f45")
        for cx, cy in [(130, 70), (180, 110)]:
            o += f'<circle cx="{cx}" cy="{cy}" r="34" fill="#f2f0a0" opacity="0.18"/>' + C(cx, cy, 8, "#f2f0a0", 0.8)
        o += robo(150, 160, 0, COR[2], 0.5)
    elif tipo == "biblioteca":
        o = grad(w, h, "#3a7a9a", "#123a52")
        for k in range(3):
            o += R(20 + k * 95, 30, 70, 120, "#7a5a3a", vol=3)
            for j in range(4):
                o += R(26 + k * 95, 36 + j * 28, 58, 20, ["#d14b4b", "#4f86d9", "#5cc45c", "#f2c84b"][(k + j) % 4], 0.8)
        o += f'<g transform="rotate(25 200 60)">' + R(180, 50, 40, 26, "#d14b4b", 1.0) + "</g>" + bolhas(0, 0, w, h, 8, 5)
        o += robo(150, 158, 3, COR[0], 0.5)
    elif tipo == "vulcao":
        o = grad(w, h, "#2f5f6f", "#1a1a2a")
        o += poly([(60, h), (150, 60), (240, h)], "#4a3f3f", vol=4)
        o += f'<path d="M150,60 q-6,-30 4,-50" stroke="#ff8a1f" stroke-width="10" fill="none"/>' + bolhas(110, 0, 190, 70, 10, 8, "#ffd23f")
        o += R(0, 150, w, 20, "#3a2f2f") + f'<rect x="100" y="150" width="100" height="20" fill="#ff8a1f"/>'
        o += robo(70, 150, 1, COR[3], 0.5) + robo(240, 150, 4, COR[1], 0.5, flip=True)
    return o


# ================================================================== BASE LUNAR
def lu_patio(w, h, furo=0.0, s=1.0):
    o = grad(w, h, "#070b1e", "#232c55") + estrelas(w, h * 0.6, int(60 * s) + 20)
    o += C(w * 0.82, h * 0.16, 54 * s, "#4f86d9", 1.0) + C(w * 0.8, h * 0.14, 20 * s, "#5cc45c", 0.8) + C(w * 0.85, h * 0.2, 12 * s, "#5cc45c", 0.8)
    g = h * 0.84
    o += poly([(0, g), (w * 0.4, g - 10 * s), (w, g - 4 * s), (w, h), (0, h)], "#9a9aa8")
    for cx, rx in [(0.15, 60), (0.55, 80), (0.85, 50)]:
        o += f'<ellipse cx="{w * cx}" cy="{g + 30 * s}" rx="{rx * s}" ry="{10 * s}" fill="#7d7d8c"/>'
    # módulos
    o += f'<path d="M{w * 0.12},{g} a{150 * s},{140 * s} 0 0 1 {300 * s},0 Z" fill="#d7dde9"/>'
    o += R(w * 0.12 + 300 * s, g - 70 * s, 160 * s, 70 * s, "#c3cad9", vol=4)
    o += f'<path d="M{w * 0.12 + 460 * s},{g} a{110 * s},{100 * s} 0 0 1 {220 * s},0 Z" fill="#d7dde9"/>'
    for k in range(3):
        o += C(w * 0.12 + 90 * s + k * 60 * s, g - 70 * s, 14 * s, "#7ab8ff", 0.8)
    o += zebra(w * 0.12, g - 14 * s, 680 * s, 14 * s)
    # plataforma do foguete
    fx = w * 0.12 + 760 * s
    o += R(fx, g - 30 * s, 200 * s, 30 * s, "#6b6b7a", vol=3)
    o += R(fx + 70 * s, g - 250 * s, 60 * s, 220 * s, "#eef0f4", vol=4) + poly([(fx + 70 * s, g - 250 * s), (fx + 100 * s, g - 320 * s), (fx + 130 * s, g - 250 * s)], "#d14b4b")
    o += poly([(fx + 50 * s, g - 30 * s), (fx + 70 * s, g - 90 * s), (fx + 70 * s, g - 30 * s)], "#d14b4b") + poly([(fx + 150 * s, g - 30 * s), (fx + 130 * s, g - 90 * s), (fx + 130 * s, g - 30 * s)], "#d14b4b")
    # painéis solares (plataformas)
    for k in range(2):
        px = w * 0.06 + k * 900 * s
        o += R(px, g - 210 * s - k * 30 * s, 150 * s, 14 * s, "#3a5fa0", vol=2) + R(px + 70 * s, g - 196 * s - k * 30 * s, 10 * s, 196 * s + k * 30 * s, "#8a8a9a", 1.0)
    if furo > 0:
        hx, hy = w * 0.12 + 520 * s, g - 60 * s
        o += f'<path d="M{hx},{hy} l{18 * s},{-8 * s} l{6 * s},{16 * s} l{-16 * s},{6 * s} Z" fill="#070b1e"/>'
        for k in range(7):
            a = math.pi + (k - 3) * 0.32
            o += (f'<path d="M{hx + math.cos(a) * 230 * s},{hy + math.sin(a) * 120 * s} L{hx},{hy}" stroke="#ffffff" stroke-width="{3 * s}" '
                  f'stroke-dasharray="{10 * s} {9 * s}" opacity="{0.4 + 0.5 * furo}"/>')
    o += placa(30 * s, 30 * s, "OBRA LUNAR · BASE SELENE", 16 * s)
    return o


def lu_mini(tipo, w=300, h=170):
    o = grad(w, h, "#070b1e", "#232c55") + estrelas(w, h * 0.5, 20, 11)
    if tipo == "estufa":
        o += R(0, 140, w, 30, "#9a9aa8")
        o += f'<path d="M30,140 a120,100 0 0 1 240,0 Z" fill="#bff0d0" opacity="0.4" stroke="#ffffff" stroke-width="3"/>'
        for k in range(5):
            o += R(60 + k * 40, 110, 26, 30, "#7a5a3a", 1.0) + C(73 + k * 40, 100, 14, "#5cc45c", 1.0)
        o += robo(120, 110, 2, COR[2], 0.5) + robo(200, 70, 0, COR[0], 0.5, rot=-20)
    elif tipo == "tuneis":
        o = grad(w, h, "#2a1f2f", "#0b0710")
        o += poly([(0, 0), (w, 0), (w, 40), (200, 60), (90, 40), (0, 60)], "#3f3040") + R(0, 145, w, 25, "#4a3a3f")
        for cx in (60, 230):
            o += poly([(cx - 12, 145), (cx, 105), (cx + 12, 145)], "#9fe8ff") + f'<circle cx="{cx}" cy="125" r="26" fill="#9fe8ff" opacity="0.15"/>'
        o += robo(140, 145, 3, COR[3], 0.5)
    elif tipo == "antena":
        o += R(0, 145, w, 25, "#9a9aa8") + R(140, 40, 18, 105, "#c3cad9", vol=2)
        o += f'<path d="M90,50 a60,30 0 0 0 120,0 Z" fill="#eef0f4" stroke="{INK}" stroke-width="3"/>'
        o += '<path d="M150,40 l0,-24" stroke="#ff6b6b" stroke-width="4"/>' + robo(70, 145, 1, COR[1], 0.5) + robo(230, 145, 4, COR[0], 0.5, flip=True)
    elif tipo == "fabrica":
        o += R(0, 145, w, 25, "#6b6b7a")
        for k in range(2):
            o += R(20, 100 - k * 50, 260, 12, "#4a4f5c", 1.0)
            for j in range(9):
                o += C(30 + j * 30, 106 - k * 50, 4, "#9a9aa8", 0.5)
        o += R(120, 70, 40, 30, "#c3cad9", 1.0) + robo(200, 100, 2, COR[3], 0.5) + robo(80, 50, 0, COR[2], 0.5, rot=10)
    elif tipo == "mina":
        o += R(0, 145, w, 25, "#8a7f8f")
        o += f'<g transform="translate(130,60) rotate(-12)">' + R(0, 0, 60, 34, "#8a6b4f", vol=3) + "</g>"
        o += C(80, 120, 18, "#f2e08a", 1.0) + C(240, 125, 14, "#f2e08a", 1.0) + robo(200, 145, 4, COR[1], 0.5)
    elif tipo == "oculto":
        o = grad(w, h, "#03040a", "#0b0f20") + estrelas(w, h, 40, 17)
        o += poly([(0, 150), (w, 140), (w, h), (0, h)], "#3a3a48")
        for k in range(3):
            x = 60 + k * 90
            o += f'<path d="M{x + 60},{10 + k * 20} L{x},{70 + k * 20}" stroke="#ff8a1f" stroke-width="5"/>' + C(x, 70 + k * 20, 8, "#ffd23f", 0.8)
        o += f'<path d="M150,150 L110,90 L190,90 Z" fill="#fff6c0" opacity="0.15"/>' + robo(150, 150, 3, COR[0], 0.5)
    return o


# ================================================================== layout comum
def quadro(x, y, w, h, corpo, borda=5):
    _g[0] += 1
    cid = f"q{_g[0]}"
    return (f'<g transform="translate({x},{y})"><clipPath id="{cid}"><rect width="{w}" height="{h}" rx="12"/></clipPath>'
            f'<g clip-path="url(#{cid})">{corpo}</g><rect width="{w}" height="{h}" rx="12" fill="none" stroke="{INK}" stroke-width="{borda}"/></g>')


def arvore(x0, y0, cenas, cor):
    """cenas = [(nome, sub, svg_corpo)] na ordem 1, 2a, 2b, 3a, 3b, 3c, 3d."""
    o = chunk(x0, y0, 1840, 840, CREAM, 26, 6, 10)
    o += T(x0 + 920, y0 + 50, "AS 7 CENAS  (destruiu 40%+ no tempo → esquerda · bateu 65% → direita)", 30, INK)
    tw, th = 300, 170
    pos = {0: (x0 + 920 - tw / 2, y0 + 80), 1: (x0 + 470 - tw / 2, y0 + 300), 2: (x0 + 1370 - tw / 2, y0 + 300),
           3: (x0 + 90, y0 + 600), 4: (x0 + 520, y0 + 600), 5: (x0 + 1020, y0 + 600), 6: (x0 + 1450, y0 + 600)}
    linhas = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
    for a, bb in linhas:
        ax, ay = pos[a][0] + tw / 2, pos[a][1] + th + (68 if a > 0 else 0)
        bx, by = pos[bb][0] + tw / 2, pos[bb][1]
        moder = bb in (1, 3, 5)
        o += f'<path d="M{ax},{ay} C{ax},{ay + 40} {bx},{by - 50} {bx},{by}" stroke="{"#8fd46a" if moder else "#ec6448"}" stroke-width="8" fill="none"/>'
        o += T((ax + bx) / 2 + (-36 if moder else 36), (ay + by) / 2 + 6, "40%" if moder else "65%", 18, "#3c9a46" if moder else "#a8233a")
    for k, (nome, sub, corpo) in enumerate(cenas):
        px, py = pos[k]
        o += quadro(px, py, tw, th, corpo, 4)
        rot = ["1", "2a", "2b", "3a", "3b", "3c", "3d"][k]
        o += f'<rect x="{px - 10}" y="{py - 12}" width="46" height="32" rx="8" fill="{cor}" stroke="{INK}" stroke-width="3"/>' + T(px + 13, py + 10, rot, 18, "#ffffff")
        if k == 0:
            o += T(px + tw + 20, py + 60, nome, 26, INK, "start") + T(px + tw + 20, py + 92, sub, 19, SOFT, "start", 600)
        elif k in (1, 2):
            o += T(px + tw / 2, py + th + 30, nome, 24, INK) + T(px + tw / 2, py + th + 56, sub, 17, SOFT, w=600)
        else:
            o += T(px + tw / 2, py + th + 30, nome, 21, INK) + T(px + tw / 2, py + th + 56, sub, 16, SOFT, w=600)
    return o


def listas(x0, y0, blocos, cor):
    o = ""
    bw = (1840 - 3 * 20) / 4
    for k, (tit, itens) in enumerate(blocos):
        bx = x0 + k * (bw + 20)
        o += chunk(bx, y0, bw, 330, CREAM, 20, 5, 8)
        o += f'<rect x="{bx}" y="{y0}" width="{bw}" height="50" rx="20" fill="{cor}" stroke="{INK}" stroke-width="5"/><rect x="{bx + 3}" y="{y0 + 30}" width="{bw - 6}" height="20" fill="{cor}"/>'
        o += T(bx + bw / 2, y0 + 36, tit, 24, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
        for j, (nm, ds) in enumerate([i for i in itens if i[0]]):
            yy = y0 + 86 + j * 58
            o += T(bx + 20, yy, "• " + nm, 19, INK, "start") + T(bx + 36, yy + 24, ds, 15, SOFT, "start", 600)
    return o


def regra(x0, y0, titulo, passos, cor):
    o = chunk(x0, y0, 700, 620, CREAM, 24, 6, 10)
    o += f'<rect x="{x0}" y="{y0}" width="700" height="60" rx="24" fill="{cor}" stroke="{INK}" stroke-width="6"/><rect x="{x0 + 3}" y="{y0 + 36}" width="694" height="24" fill="{cor}"/>'
    o += T(x0 + 350, y0 + 42, "REGRA-ASSINATURA: " + titulo, 26, "#ffffff", extra=f'stroke="{INK}" stroke-width="7" paint-order="stroke"')
    for k, (corpo, txt) in enumerate(passos):
        yy = y0 + 80 + k * 178
        o += quadro(x0 + 24, yy, 280, 158, f'<g transform="scale(0.5)">{corpo}</g>', 4)
        o += f'<circle cx="{x0 + 24}" cy="{yy}" r="18" fill="{cor}" stroke="{INK}" stroke-width="3"/>' + T(x0 + 24, yy + 7, str(k + 1), 20, "#ffffff")
        for j, ln in enumerate(txt):
            o += T(x0 + 324, yy + 40 + j * 30, ln, 20 if j == 0 else 18, INK if j == 0 else SOFT, "start", 700 if j == 0 else 600)
    return o


def prancha(nome_arq, titulo, ordem, paleta, cor, tela, passos, titulo_regra, cenas, blocos):
    PW, PH = 1920, 2310
    b = [f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>', ca.defs(), title(PW / 2, 72, titulo, 58)]
    b.append(T(PW / 2, 120, ordem, 26, "#fff4c8"))
    for k, c in enumerate(paleta):
        b.append(f'<rect x="{PW / 2 - len(paleta) * 22 + k * 44}" y="138" width="36" height="20" rx="5" fill="{c}" stroke="#ffffff" stroke-width="2"/>')
    b.append(quadro(40, 180, 1100, 620, tela, 6))
    b.append(T(590, 836, "tela de jogo da cena 1 (prévia de composição)", 22, "#fff4c8"))
    b.append(regra(1180, 180, titulo_regra, passos, cor))
    b.append(arvore(40, 870, cenas, cor))
    b.append(listas(40, 1740, blocos, cor))
    b.append(T(PW / 2, 2120, "Identidade da obra em todas as cenas: placas, fita zebrada e a grua adaptada ao mundo · as cenas seguem o manual (estrutura fixa × o que quebra)", 22, "#fff4c8"))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH - 140}" viewBox="0 0 {PW} {PH - 140}">{style}{"".join(b)}</svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, f"svg/{nome_arq}.svg"), os.path.join(OUT, f"{nome_arq}.png"), PW, PH - 140, 1)


def atlantida():
    tela = at_templo(1100, 620, agua=0.55, s=0.85)
    tela += robo(330, 533, 0, COR[0], 1.0) + robo(470, 533, 2, COR[2], 1.0, flip=True) + robo(160, 422, 1, COR[1], 1.0) + robo(830, 450, 3, COR[3], 1.0, rot=-12)
    tela += gauge(1030, 70, 46, 0.42)
    passos = [
        (at_templo(560, 316, 0.0, 0.42) + robo(170, 270, 0, COR[0], 0.5), ["Tudo seco dentro da cúpula", "a luta começa normal, com ar"]),
        (at_templo(560, 316, 0.25, 0.42) + robo(330, 260, 2, COR[2], 0.5), ["Marretou o vidro: RACHA e vaza", "a água começa a subir naquele lado"]),
        (at_templo(560, 316, 0.8, 0.42) + robo(400, 180, 1, COR[1], 0.5, rot=-20), ["Área ALAGADA", "anda devagar, pulo flutua alto, golpe joga longe"]),
    ]
    cenas = [
        ("Cúpula do Templo", "templo com ar sob uma cúpula gigante · colunas e passarelas quebram", at_mini("jardins") if False else at_templo(300, 170, 0.0, 0.24) + robo(150, 146, 0, COR[0], 0.4)),
        ("Jardins Submersos", "meio alagado · conchas-trampolim abrem e fecham", at_mini("jardins")),
        ("Salão do Tesouro", "afundou! bolsões de ar · estátuas tombam", at_mini("tesouro")),
        ("Aqueduto das Correntes", "correntes empurram · comportas", at_mini("aqueduto")),
        ("Fenda Abissal", "escuro: peixes-lanterna iluminam", at_mini("fenda")),
        ("Biblioteca Afogada", "estantes e livros boiam e viram plataformas", at_mini("biblioteca")),
        ("Coração do Vulcão", "fontes termais lançam para cima", at_mini("vulcao")),
    ]
    blocos = [
        ("PERIGOS / MECANISMOS", [("Cúpula de vidro", "quebrou = alaga aquele lado"), ("Concha-trampolim", "abre e fecha; lança alto"),
                                  ("Comporta", "alavanca abre: corrente empurra"), ("Enguia elétrica", "choque em quem está na água")]),
        ("EVENTOS DO MAPA", [("Maremoto", "uma onda atravessa a tela e arrasta"), ("Cardume", "peixes passam empurrando"),
                             ("Bolhão de ar", "a água baixa por alguns segundos"), ("Polvo da grua", "tentáculo agarra e joga")]),
        ("ENGENHOCA EXCLUSIVA", [("Escafandro (Defesa)", "não fica lento na água por 10 s"), ("Torpedo (Ataque)", "corre reto pela água e explode"),
                                 ("", ""), ("ganhas na gangorra", "como as outras: caixa = maleta")]),
        ("IDEIAS DE SKIN", [("Mergulhador", "capacete de escafandro de cobre"), ("Coral", "robô coberto de corais"),
                            ("Pirata Afogado", "chapéu e casco de navio"), ("Água-viva", "transparente e brilhante")]),
    ]
    prancha("detalhe_atlantida", "ATLÂNTIDA — OBRA SUBMARINA", "ORDEM DE SERVIÇO: derrubar o Templo de Atlântida sem deixar a cidade toda inundar (ou deixando!)",
            [AQ, AQ2, MARM, "#d9c48f", "#f2c84b", "#f2a7c3"], "#1f7f9a", tela, passos, "ALAGAMENTO", cenas, blocos)


def lua():
    tela = lu_patio(1100, 620, furo=1.0, s=0.85)
    tela += robo(300, 521, 0, COR[0], 1.0) + robo(160, 300, 2, COR[2], 1.0, rot=-10) + robo(640, 380, 1, COR[1], 1.0, rot=35) + robo(840, 521, 3, COR[3], 1.0, flip=True)
    tela += '<path d="M160,330 q0,90 10,190" stroke="#ffffff" stroke-width="3" stroke-dasharray="8 10" fill="none" opacity="0.7"/>'
    tela += gauge(1030, 520, 46, 0.3)
    passos = [
        (lu_patio(560, 316, 0.0, 0.42) + robo(160, 150, 2, COR[2], 0.5) + '<path d="M160,170 q0,40 6,100" stroke="#fff" stroke-width="2" stroke-dasharray="5 6" fill="none"/>',
         ["POUCA GRAVIDADE", "pulo altíssimo, queda lenta e arremessos longos"]),
        (lu_patio(560, 316, 0.6, 0.42) + robo(330, 230, 0, COR[0], 0.5), ["Marretou o módulo: FURO", "o ar escapa e SUGA quem está perto"]),
        (lu_patio(560, 316, 0.0, 0.42) + R(250, 236, 30, 30, "#f2c84b", 1.0) + robo(400, 266, 1, COR[1], 0.5), ["Porta de emergência fecha", "em ~4 s a sucção para (dá para fugir)"]),
    ]
    cenas = [
        ("Pátio de Pouso", "módulos, foguete e painéis solares · tudo quebra menos o chão", lu_patio(300, 170, 0.0, 0.24) + robo(150, 146, 0, COR[0], 0.4)),
        ("Estufa Hidropônica", "cúpula de vidro com plantas · furos sugam", lu_mini("estufa")),
        ("Túneis de Lava", "subterrâneo escuro · cristais iluminam", lu_mini("tuneis")),
        ("Antena Gigante", "estrutura alta que gira", lu_mini("antena")),
        ("Fábrica de Robôs", "esteiras em baixa gravidade", lu_mini("fabrica")),
        ("Mina de Hélio-3", "vagonetas que flutuam", lu_mini("mina")),
        ("Lado Oculto", "escuro total · meteoros caem", lu_mini("oculto")),
    ]
    blocos = [
        ("PERIGOS / MECANISMOS", [("Módulo pressurizado", "furou = suga até a porta fechar"), ("Propulsor", "jato que lança longe"),
                                  ("Rover desgovernado", "atravessa o pátio atropelando"), ("Painel solar", "plataforma que gira devagar")]),
        ("EVENTOS DO MAPA", [("Chuva de meteoros", "crateras na estrutura (ajuda a destruir!)"), ("Gravidade zero", "5 s todos flutuam"),
                             ("Apagão", "só as luzes dos capacetes"), ("Lançamento", "o foguete sobe: chamas embaixo")]),
        ("ENGENHOCA EXCLUSIVA", [("Botas Magnéticas (Defesa)", "gruda no chão: sucção não pega"), ("Canhão de Plasma (Ataque)", "tiro que atravessa a cena"),
                                 ("", ""), ("ganhas na gangorra", "como as outras: caixa = maleta")]),
        ("IDEIAS DE SKIN", [("Astronauta", "traje branco com viseira dourada"), ("Alienígena", "verde com antenas"),
                            ("Rover", "rodinhas e painel nas costas"), ("Satélite", "antena parabólica na cabeça")]),
    ]
    prancha("detalhe_lua", "BASE LUNAR — OBRA NA LUA", "ORDEM DE SERVIÇO: desmontar a Base Selene antes que a próxima nave chegue",
            ["#070b1e", "#232c55", "#9a9aa8", "#d7dde9", "#4f86d9", "#f2c84b"], "#3a4a7a", tela, passos, "POUCA GRAVIDADE + VÁCUO", cenas, blocos)


if __name__ == "__main__":
    atlantida()
    lua()
    print(render_all(), OUT)
