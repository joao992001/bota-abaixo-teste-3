"""LAPIDAÇÃO — perigos da Cena 1 (Cargueiro no Alto-Mar), quadro a quadro, em papel e giz.
As funções `onda()`, `conteiner_cai()`, `gancho()`, `poeira()`, `tabua_boa()` devolvem SVG em coordenadas LOCAIS do sprite
(mesmas que o jogo vai usar); a prancha só compõe sobre um pedaço da cena.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_lapida1.py → art/out/fase2/lapida_cena1.png
"""
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
from f2_prancha import R, E, PL, S, conteiner, robot, CONT, INK, YEL, zebra  # noqa: E402
import elenco as el  # noqa: E402
from papel import rough  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
AGUA, AGUA_D, AGUA_L, ESPUMA = "#3f86b8", "#2a5f8c", "#7fc0e0", "#f4fbff"
VERM = "#d42035"


def Tt(x, y, s, size=18, col=INK, anchor="middle"):
    return f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="700" font-size="{size}" fill="{col}" text-anchor="{anchor}">{s}</text>'


# ================================================================ M3 ONDA (vem do mar pela DIREITA e varre a balsa)
def _gotas(cx, cy, n, raio, seed, cor=ESPUMA, tam=(4, 10)):
    rnd = random.Random(seed)
    o = ""
    for _ in range(n):
        a = rnd.uniform(-math.pi, 0)
        d = rnd.uniform(raio * 0.4, raio)
        r = rnd.uniform(*tam)
        o += f'<circle cx="{cx + math.cos(a) * d:.1f}" cy="{cy + math.sin(a) * d * 0.8:.1f}" r="{r:.1f}" fill="{cor}"/>'
    return o


def _espuma(pts, seed, r0=12, r1=22):
    """Fileira de bolotas de espuma ao longo de pontos (crista)."""
    rnd = random.Random(seed)
    return "".join(E(x, y, rnd.uniform(r0, r1), rnd.uniform(r0, r1) * 0.8, ESPUMA, 0.8) for x, y in pts)


def onda(k, w=448, h=300):
    """Quadro k (0 incha · 1 cresce · 2 quebra · 3 varre · 4 recua) da onda; base (nível do mar) em y=h; vem da direita."""
    o = ""
    if k == 0:   # a água INCHA na borda da balsa: lombada + bolhas subindo + respingos
        o += S(f"M{w * 0.45},{h} C{w * 0.62},{h - 70} {w * 0.86},{h - 80} {w},{h - 40} L{w},{h} Z", AGUA, (w * 0.45, h - 80, w, h), k=1.4, dark=AGUA_D)
        o += f'<path d="M{w * 0.55},{h - 30} C{w * 0.68},{h - 64} {w * 0.84},{h - 70} {w * 0.98},{h - 44}" stroke="{AGUA_L}" stroke-width="6" fill="none" stroke-linecap="round"/>'
        o += _espuma([(w * 0.62 + i * 34, h - 62 - (i % 2) * 8) for i in range(5)], 1, 8, 14)
        rnd = random.Random(2)
        for _ in range(8):
            x = rnd.uniform(w * 0.55, w * 0.98)
            o += f'<circle cx="{x}" cy="{rnd.uniform(h - 140, h - 80)}" r="{rnd.uniform(4, 8)}" fill="none" stroke="{ESPUMA}" stroke-width="3"/>'
    elif k == 1:   # a crista CRESCE e se inclina para a balsa
        body = f"M{w * 0.30},{h} C{w * 0.42},{h - 120} {w * 0.60},{h - 210} {w * 0.80},{h - 200} C{w * 0.95},{h - 190} {w},{h - 120} {w},{h - 60} L{w},{h} Z"
        o += S(body, AGUA, (w * 0.3, h - 215, w, h), k=1.6, dark=AGUA_D)
        o += S(f"M{w * 0.45},{h} C{w * 0.52},{h - 90} {w * 0.64},{h - 160} {w * 0.78},{h - 168} C{w * 0.70},{h - 120} {w * 0.66},{h - 60} {w * 0.7},{h} Z", AGUA_D, (w * 0.45, h - 170, w * 0.78, h), k=1.2)
        for i in range(3):
            o += f'<path d="M{w * (0.48 + i * 0.12)},{h - 20} C{w * (0.52 + i * 0.12)},{h - 90} {w * (0.6 + i * 0.1)},{h - 150} {w * (0.7 + i * 0.08)},{h - 170}" stroke="{AGUA_L}" stroke-width="5" fill="none" opacity="0.7"/>'
        o += _espuma([(w * 0.62 + i * 26, h - 198 + abs(i - 3) * 6) for i in range(8)], 3, 12, 20)
        o += _gotas(w * 0.7, h - 210, 10, 70, 4)
    elif k == 2:   # QUEBRA: o lábio enrola por cima da balsa, espuma grossa e spray
        body = (f"M{w * 0.15},{h} C{w * 0.25},{h - 150} {w * 0.42},{h - 250} {w * 0.62},{h - 262} C{w * 0.84},{h - 270} {w},{h - 190} {w},{h - 80} L{w},{h} Z")
        o += S(body, AGUA, (w * 0.15, h - 275, w, h), k=1.8, dark=AGUA_D)
        lip = f"M{w * 0.62},{h - 262} C{w * 0.38},{h - 262} {w * 0.16},{h - 200} {w * 0.10},{h - 120} C{w * 0.22},{h - 170} {w * 0.36},{h - 200} {w * 0.46},{h - 190} Z"
        o += S(lip, AGUA_L, (w * 0.1, h - 265, w * 0.62, h - 120), k=1.2)
        o += S(f"M{w * 0.46},{h - 190} C{w * 0.40},{h - 140} {w * 0.42},{h - 80} {w * 0.5},{h} L{w * 0.7},{h} C{w * 0.64},{h - 80} {w * 0.6},{h - 160} {w * 0.62},{h - 230} Z", AGUA_D, (w * 0.4, h - 232, w * 0.7, h), k=1.2)
        o += _espuma([(w * (0.1 + i * 0.065), h - 120 - math.sin(i / 9 * math.pi) * 150) for i in range(10)], 5, 14, 24)
        o += _gotas(w * 0.2, h - 140, 18, 120, 6, tam=(5, 12)) + _gotas(w * 0.5, h - 280, 10, 80, 7)
    elif k == 3:   # VARRE o convés: lençol de água com frente de espuma indo para a esquerda
        o += S(f"M0,{h - 26} C{w * 0.08},{h - 58} {w * 0.2},{h - 62} {w * 0.32},{h - 46} C{w * 0.6},{h - 30} {w * 0.86},{h - 34} {w},{h - 44} L{w},{h} L0,{h} Z", AGUA, (0, h - 62, w, h), k=1.2, dark=AGUA_D)
        o += f'<path d="M{w * 0.36},{h - 40} C{w * 0.6},{h - 26} {w * 0.84},{h - 30} {w * 0.98},{h - 38}" stroke="{AGUA_L}" stroke-width="5" fill="none"/>'
        o += _espuma([(14 + i * 20, h - 44 - math.sin(i / 6 * math.pi) * 18) for i in range(8)], 8, 10, 18)
        o += _gotas(30, h - 60, 12, 70, 9, tam=(4, 9))
        for i in range(4):
            o += f'<path d="M{w * 0.45 + i * 46},{h - 22} h-56" stroke="{ESPUMA}" stroke-width="4" stroke-linecap="round" opacity="0.85"/>'
    else:   # RECUA: poça de espuma escorrendo pelas bordas
        o += S(f"M0,{h - 14} C{w * 0.3},{h - 30} {w * 0.7},{h - 26} {w},{h - 12} L{w},{h} L0,{h} Z", AGUA_L, (0, h - 30, w, h), k=1.0)
        o += _espuma([(30 + i * 52, h - 20 - (i % 2) * 6) for i in range(8)], 10, 6, 11)
        for x in (12, w - 14):
            o += f'<path d="M{x},{h - 10} q-4,30 2,60" stroke="{AGUA_L}" stroke-width="7" fill="none" stroke-linecap="round"/>'
    return o


# ================================================================ M1 CONTÊINER DESPENCA DO NAVIO
def amarra(x0, y0, x1, y1, partida=False):
    """Cinta de amarração amarela (com catraca); partida = ponta solta chicoteando + estalo."""
    if not partida:
        return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{INK}" stroke-width="9"/><path d="M{x0},{y0} L{x1},{y1}" stroke="#f2c84b" stroke-width="6"/>'
                + R((x0 + x1) / 2 - 8, (y0 + y1) / 2 - 8, 16, 16, "#5a5f6a", 2, 0.6))
    mx, my = x0 + (x1 - x0) * 0.4, y0 + (y1 - y0) * 0.4
    return (f'<path d="M{x0},{y0} L{mx},{my} q12,-20 30,-14" stroke="{INK}" stroke-width="9" fill="none"/><path d="M{x0},{y0} L{mx},{my} q12,-20 30,-14" stroke="#f2c84b" stroke-width="6" fill="none"/>'
            + f'<path d="M{mx + 34},{my - 18} l14,-8 M{mx + 36},{my - 8} l16,2 M{mx + 30},{my - 28} l6,-14" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>')


def sombra_alvo(cx, y, w, k):
    """Alvo no chão: faixa zebrada vermelha que cresce (k 0..1) + seta e !"""
    ww = w * (0.5 + 0.5 * k)
    o = f'<rect x="{cx - ww / 2}" y="{y - 12}" width="{ww}" height="14" rx="5" fill="{VERM}" opacity="0.9"/>'
    for i in range(int(ww / 22)):
        o += f'<path d="M{cx - ww / 2 + 6 + i * 22},{y + 2} l10,-14 h7 l-10,14 Z" fill="#ffffff" opacity="0.9"/>'
    o += f'<path d="M{cx},{y - 30} l-14,-22 h9 v-26 h10 v26 h9 Z" fill="{VERM}" stroke="#ffffff" stroke-width="3"/>'
    return o


def poeira(cx, y, k, w=260):
    """Nuvem de poeira/estilhaços do impacto (k 0 = estouro, 1 = assentando)."""
    rnd = random.Random(31)
    o = ""
    for i in range(11):
        a = math.pi * (0.05 + 0.9 * i / 10)
        d = (40 + 90 * k) * (0.7 + 0.3 * rnd.random())
        r = (34 + 20 * k) * (0.6 + 0.5 * rnd.random())
        o += E(cx - math.cos(a) * d * (w / 260), y - math.sin(a) * d * 0.5 - 10, r, r * 0.8, "#efe4d2" if i % 2 else "#e2d4bd", 1.0)
    if k < 0.5:
        for i in range(7):   # lascas de tinta e madeira voando
            a = math.pi * (0.1 + 0.8 * i / 6)
            x, yy = cx - math.cos(a) * (130 + 40 * k), y - math.sin(a) * (90 + 30 * k)
            o += f'<g transform="rotate({i * 40} {x} {yy})">' + R(x - 10, yy - 6, 20, 12, ["#c98a4b", CONT[1], "#7a7f8a"][i % 3], 2, 0.6) + "</g>"
    return o


def conteiner_cai(k, w=192, h=64):
    """Quadro k (0 preso tremendo · 1 cinta estala · 2 caindo · 3 impacto) — só o contêiner + efeitos locais."""
    o = ""
    if k <= 1:
        sh = 4 if k == 0 else 8
        o += f'<g transform="translate({sh if k else 0},0) rotate({-3 if k else 2} {w / 2} {h / 2})">' + conteiner(0, 0, w, h, CONT[1], 0, True) + "</g>"
        o += amarra(-26, h + 2, 30, 4, partida=(k == 1)) + amarra(w + 26, h + 2, w - 30, 4)
        for i in range(3):
            o += f'<path d="M{w + 14 + i * 6},{-6 + i * 14} l12,-4" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
    elif k == 2:
        o += f'<g transform="rotate(8 {w / 2} {h / 2})">' + conteiner(0, 0, w, h, CONT[1], 0, True) + "</g>"
        for i in range(5):
            o += f'<path d="M{16 + i * 40},{-20} v-{40 + (i % 2) * 30}" stroke="#ffffff" stroke-width="6" stroke-linecap="round" opacity="0.85"/>'
    else:
        o += conteiner(0, 8, w, h - 8, CONT[1], 2, True) + f'<path d="M{w * 0.2},{h} l-14,10 M{w * 0.8},{h} l14,10" stroke="{INK}" stroke-width="4"/>'
        o += poeira(w / 2, h + 6, 0.2, w + 80)
    return o


# ================================================================ M2 GANCHO (cabo de aço + gancho de guindaste)
def cabo(x0, y0, x1, y1):
    return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{INK}" stroke-width="8" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#8a909c" stroke-width="4" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#d9dce4" stroke-width="1.5" stroke-dasharray="6 8"/>')


def gancho(x, y, s=1.0):
    """Moitão amarelo com faixas pretas + gancho de aço (topo do moitão em x,y)."""
    o = f'<g transform="translate({x},{y}) scale({s})">'
    o += R(-26, 0, 52, 56, "#e0a83a", 6, 1.2, dark="#b07a1e")
    for i in range(3):
        o += f'<path d="M-26,{12 + i * 16} l52,-10 v8 l-52,10 Z" fill="{INK}" opacity="0.85"/>'
    o += E(0, 8, 9, 9, "#5a5f6a", 0.6)
    o += f'<path d="M0,56 V74 q0,26 -22,26 q-16,0 -18,-16" stroke="{INK}" stroke-width="12" fill="none" stroke-linecap="round"/>'
    o += f'<path d="M0,56 V74 q0,26 -22,26 q-16,0 -18,-16" stroke="#9aa0ac" stroke-width="7" fill="none" stroke-linecap="round"/>'
    o += f'<path d="M-4,92 l10,-6" stroke="#e0a83a" stroke-width="5" stroke-linecap="round"/>'   # trava de segurança
    return o + "</g>"


def balanco(cx, top, comp, ang, cor_idx=4):
    """Contêiner pendurado: cabo da lança → moitão → lingas nas quinas; ang em graus (positivo = para a direita)."""
    a = math.radians(ang)
    hx, hy = cx + math.sin(a) * comp, top + math.cos(a) * comp
    o = cabo(cx, top, hx, hy) + f'<g transform="rotate({-ang} {hx} {hy})">' + gancho(hx, hy, 0.8)
    w, h = 176, 56
    o += f'<path d="M{hx},{hy + 78} L{hx - w / 2 + 8},{hy + 130} M{hx},{hy + 78} L{hx + w / 2 - 8},{hy + 130}" stroke="{INK}" stroke-width="5"/>'
    o += conteiner(hx - w / 2, hy + 130, w, h, CONT[cor_idx], 0, True) + "</g>"
    return o


def arco_aviso(cx, top, comp, a0, a1):
    o = ""
    for i in range(9):
        a = math.radians(a0 + (a1 - a0) * i / 8)
        x, y = cx + math.sin(a) * (comp + 160), top + math.cos(a) * (comp + 160)
        o += f'<circle cx="{x}" cy="{y}" r="7" fill="{VERM}" opacity="{0.4 + 0.6 * (i % 2)}"/>'
    for sgn in (-1, 1):
        a = math.radians(a1 if sgn > 0 else a0)
        x, y = cx + math.sin(a) * (comp + 160), top + math.cos(a) * (comp + 160)
        o += f'<path d="M{x},{y} l{sgn * 16},-10 l{-sgn * 2},20 Z" fill="{VERM}"/>'
    return o


# ================================================================ TÁBUA de andaime (bem acabada)
def tabua_boa(x, y, w):
    """Tábua de andaime: 2 pranchas lado a lado (28 px), veio, nós, pregos, ponta desgastada e braçadeiras."""
    o = R(x, y, w, 14, "#d0955a", 3, 1.6, dark="#a8743f") + R(x, y + 14, w, 14, "#c08548", 3, 1.6, dark="#9a6a3a")
    o += f'<rect x="{x}" y="{y}" width="{w}" height="3" fill="#ecc28c"/><rect x="{x}" y="{y + 25}" width="{w}" height="3" fill="#7a5030"/>'
    rnd = random.Random(int(x + w))
    for _ in range(int(w / 70)):
        xx = rnd.uniform(x + 20, x + w - 40)
        o += f'<path d="M{xx},{y + 6} q20,-3 40,1" stroke="#a8743f" stroke-width="2" fill="none"/>'
    for _ in range(max(1, int(w / 260))):
        xx = rnd.uniform(x + 40, x + w - 40)
        o += E(xx, y + 20, 6, 3, "#8a5a30", 0.4)
    for i in range(int(w / 96) + 1):
        xx = x + 26 + i * 96
        if xx < x + w - 20:
            o += f'<circle cx="{xx}" cy="{y + 7}" r="2.6" fill="#4a3428"/><circle cx="{xx}" cy="{y + 21}" r="2.6" fill="#4a3428"/>'
    for xx in (x - 4, x + w - 14):   # braçadeiras de metal nas pontas
        o += R(xx, y - 6, 18, 40, "#8a909c", 3, 0.8, dark="#5a606c") + f'<circle cx="{xx + 9}" cy="{y + 14}" r="4" fill="#5a606c"/>'
    return o


# ================================================================ PRANCHA
def fundo_cena(w, h):
    """Pedaço da cena 1: céu do fim de tarde, costado do navio ao fundo, balsa e mar."""
    o = f'<rect width="{w}" height="{h}" fill="#f2b892"/>'
    o += R(-20, 40, w + 40, h - 120, "#a5523d", 0, 1.8, dark="#7e3a2b") + f'<rect x="0" y="0" width="{w}" height="{h}" fill="#f2b892" opacity="0.35"/>'
    return o


def balsa_local(x, y, w):
    return R(x, y, w, 26, "#4a5468", 3, 1.4, dark="#353d4e") + zebra(x, y - 8, w, 8) + R(x + 20, y + 26, w - 40, 60, "#353d4e", 3, 1.2)


def mar_local(w, y, h):
    o = f'<rect x="0" y="{y}" width="{w}" height="{h - y}" fill="{AGUA}"/>'
    o += f'<path d="M0,{y} ' + "".join("q15,-7 30,0 " for _ in range(int(w / 30) + 1)) + f'" stroke="{AGUA_L}" stroke-width="4" fill="none"/>'
    return o


def quadro(x, y, w, h, corpo, titulo):
    cid = f"c{x}_{y}"
    return (f'<g transform="translate({x},{y})"><clipPath id="{cid}"><rect width="{w}" height="{h}" rx="12"/></clipPath>'
            f'<g clip-path="url(#{cid})">{corpo}</g><rect width="{w}" height="{h}" rx="12" fill="none" stroke="{INK}" stroke-width="5"/></g>'
            + Tt(x + w / 2, y + h + 30, titulo, 20, "#ffffff"))


def linha_onda(y0):
    o = Tt(960, y0 - 18, "M3 · ONDA ESTOURA NA BALSA — vem do mar, cresce, quebra por cima e varre o convés", 28, "#ffffff")
    W1, H1 = 360, 300
    tit = ["0 · a água INCHA (aviso)", "1 · a crista CRESCE", "2 · QUEBRA por cima", "3 · VARRE o convés", "4 · recua (poça)"]
    o2 = ""
    for k in range(5):
        corpo = fundo_cena(W1, H1) + balsa_local(20, 200, 300) + mar_local(W1, 236, H1)
        if k == 3 or k == 4:
            corpo += f'<g transform="translate(20,{200 - 300 * 0.8}) scale({300 / 448},0.8)">{onda(k)}</g>'
        else:
            corpo += f'<g transform="translate(0,{236 - 300 * 0.78}) scale({W1 / 448},0.78)">{onda(k)}</g>'
        if k in (0, 1):
            corpo += robot("marretao", "parado", el.COLORS[0], 150, 200, s=0.55)
        elif k == 2:
            corpo += robot("marretao", "esquiva", el.COLORS[0], 110, 190, s=0.55, rot=-15)
        elif k == 3:
            corpo += robot("marretao", "parado", el.COLORS[0], 60, 196, s=0.55, rot=-25)
        else:
            corpo += robot("marretao", "parado", el.COLORS[0], 60, 200, s=0.55) + _gotas(60, 150, 6, 30, 12, cor=AGUA_L, tam=(3, 6))
        o2 += quadro(30 + k * 378, y0, W1, H1, corpo, tit[k])
    return o + o2


def linha_conteiner(y0):
    o = Tt(960, y0 - 18, "M1 · CONTÊINER DESPENCA DO NAVIO — cintas estalam, alvo no chão, cai e estoura em poeira", 28, "#ffffff")
    W1, H1 = 450, 330
    tit = ["0 · treme lá em cima + ALVO aparece", "1 · a cinta ESTALA (alvo cresce)", "2 · CAI (traços de velocidade)", "3 · IMPACTO: poeira, lascas, racha"]
    for k in range(4):
        corpo = fundo_cena(W1, H1) + R(0, 120, W1, 16, "#8a909c", 0, 1.0) + tabua_boa(60, 266, 330)
        for xx in range(0, W1, 40):
            corpo += f'<path d="M{xx},120 v-34" stroke="#e9e2d2" stroke-width="4"/>'
        corpo += f'<path d="M0,90 H{W1}" stroke="#e9e2d2" stroke-width="4"/>'
        if k < 2:
            corpo += f'<g transform="translate(130,{120 - 64})">{conteiner_cai(k)}</g>' + sombra_alvo(226, 266, 200, 0.4 + 0.6 * k)
        elif k == 2:
            corpo += f'<g transform="translate(130,160)">{conteiner_cai(2)}</g>' + sombra_alvo(226, 266, 200, 1.0)
        else:
            corpo += f'<g transform="translate(130,202)">{conteiner_cai(3)}</g>'
            corpo += f'<path d="M110,270 l14,8 l-10,6 l14,6 M340,270 l-12,10 l10,6" stroke="{INK}" stroke-width="4" fill="none"/>'
            corpo += f'<rect x="60" y="282" width="330" height="10" fill="#9a6a3a" opacity="0.5"/>'
        if k < 3:
            corpo += robot("picareta", "parado" if k == 0 else "esquiva", el.COLORS[1], 230 if k < 2 else 370, 270, s=0.55)
        else:
            corpo += robot("picareta", "parado", el.COLORS[1], 400, 250, s=0.55, rot=30)
        o += quadro(30 + k * 470, y0, W1, H1, corpo, tit[k])
    return o


def linha_gancho(y0):
    o = Tt(960, y0 - 18, "M2 · GANCHO BALANÇA — moitão e cabo de aço de verdade, arco de aviso, varrida com rastro", 28, "#ffffff")
    W1, H1 = 600, 360
    tit = ["0 · parado (plataforma)", "1 · AVISO: range + arco", "2 · VARRE (rastro) e empurra"]
    for k in range(3):
        corpo = fundo_cena(W1, H1) + R(0, 20, W1, 16, "#e0a83a", 0, 1.0)
        corpo += tabua_boa(30, 316, 160) + tabua_boa(410, 316, 160)
        if k == 0:
            corpo += balanco(300, 36, 60, 0)
            corpo += robot("chave", "parado", el.COLORS[2], 360, 226, s=0.55)
        elif k == 1:
            corpo += arco_aviso(300, 36, 60, -38, 38) + balanco(300, 36, 60, -8)
            corpo += f'<path d="M286,30 l-10,-14 M300,26 v-16 M314,30 l10,-14" stroke="{VERM}" stroke-width="4" stroke-linecap="round"/>'
            corpo += robot("chave", "parado", el.COLORS[2], 500, 320, s=0.55)
        else:
            for i, a in enumerate((-30, -20, -10)):
                corpo += f'<g opacity="{0.15 + 0.15 * i}">{balanco(300, 36, 60, a)}</g>'
            corpo += balanco(300, 36, 60, 2)
            corpo += robot("chave", "esquiva", el.COLORS[2], 520, 250, s=0.55, rot=35)
            corpo += f'<path d="M430,250 l20,-6 M432,262 l24,0 M430,274 l20,6" stroke="{INK}" stroke-width="4"/>'
        o += quadro(30 + k * 630, y0, W1, H1, corpo, tit[k])
    return o


def linha_tabuas(y0):
    o = Tt(960, y0 - 18, "TÁBUAS DE ANDAIME — grossas, com veio, pregos e braçadeiras nas pontas (antes: palitos)", 28, "#ffffff")
    W1, H1 = 900, 170
    antes = fundo_cena(W1, H1) + f'<g transform="translate(-200,-80) scale(1.6)">' + fp.tabua(170, 110, 400) + "</g>" + Tt(450, 40, "ANTES", 24, "#ffffff")
    depois = fundo_cena(W1, H1) + f'<g transform="translate(-200,-80) scale(1.6)">' + tabua_boa(170, 108, 400) + "</g>" + Tt(450, 40, "DEPOIS", 24, "#ffffff")
    return o + quadro(30, y0, W1, H1, antes, "") + quadro(990, y0, W1, H1, depois, "")


def prancha():
    PW, PH = 1920, 1720
    corpo = (linha_onda(110) + linha_conteiner(510) + linha_gancho(940) + linha_tabuas(1420))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH}" viewBox="0 0 {PW} {PH}"><defs>{fp.fonte()}{rough(seed=51, scale=0.7, freq=0.05)}</defs>'
           f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>' + Tt(PW / 2, 62, "LAPIDAÇÃO · CENA 1 — CARGUEIRO NO ALTO-MAR (quadro a quadro)", 40, "#ffffff")
           + f'<g filter="url(#rough)">{corpo}</g></svg>')
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/fase2/lapida_cena1.svg"), os.path.join(OUT, "lapida_cena1.png"), PW, PH, 1)
    print(render_all(), os.path.join(OUT, "lapida_cena1.png"))


if __name__ == "__main__":
    prancha()
