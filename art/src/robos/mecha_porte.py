"""PRANCHA — como o robô CARREGA a engenhoca de mecha antes de ativar (pedido 2026-11-27: "na mão fica bugado").
A MOCHILA-NÚCLEO (cápsula nas costas, alças no peito) · B CAPACETE DO MECHA (viseira com a fenda vermelha + detalhe do tema)
· C PEITORAL + OMBREIRA (um pedaço do mecha já vestido). Cada proposta em 3 robôs do elenco × 3 mechas, e no tamanho do jogo.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/mecha_porte.py → art/out/robos_v2/mecha_porte.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import mecha_cartucho as mc  # noqa: E402
from armaduras_conceito import R, E, P_, DARK, STEEL, STEEL_D, ab, eu, label, INK, queue, render_all, shade  # noqa: E402

EYE = "#ff3b2f"
# âncoras por robô do elenco (unidades do desenho, pés em y=0, olhando para a direita): costas, peito, ombro da frente, cabeça
ANC = {   # medidas na grade (scratchpad/grade.png)
    0: {"costas": (-15, -31), "peito": (4, -31), "ombro": (-2, -38), "olhos": (0, 28, -60), "topo": (6, -88)},
    1: {"costas": (-17, -23), "peito": (8, -20), "ombro": (11, -24), "olhos": (2, 25, -38), "topo": (-2, -68)},
    2: {"costas": (-17, -29), "peito": (3, -24), "ombro": (8, -30), "olhos": (-9, 19, -48), "topo": (4, -74)},
}
CORES = {0: "#4f86d9", 1: "#5cc45c", 2: "#f2c84b"}


def tema(tid):
    nome, casco, nucleo, _, det = mc.TEMAS[tid]
    return nome, casco, nucleo, det


def detalhe_topo(tid, x, y, s):
    """Detalhe do tema (o mesmo do cartucho) para pôr em cima da mochila ou do capacete."""
    _, casco, nucleo, det = tema(tid)
    g = f'<g transform="translate({x},{y}) scale({s})">'
    if det == "brasa":
        g += R(-9, -14, 6, 14, 2, DARK, k=0.2) + R(-1, -17, 6, 17, 2, DARK, k=0.2) + E(2, -20, 3, 3, "#ff8a2a", k=0.1)
    elif det == "garfo":
        g += R(-9, -16, 4, 16, 1.2, STEEL, k=0.2) + R(5, -16, 4, 16, 1.2, STEEL, k=0.2) + R(-10, -3, 20, 4, 1.5, STEEL_D, k=0.1)
    elif det == "espinhos":
        g += "".join(P_([(x - 4, 0), (x + 4, 0), (x, -10)], STEEL_D, k=0.2) for x in (-9, 0, 9))
    elif det == "aletas":
        g += P_([(-14, 0), (-22, 10), (-10, 6)], STEEL_D, k=0.2) + P_([(14, 0), (22, 10), (10, 6)], STEEL_D, k=0.2)
    elif det == "aerofolio":
        g += R(-2, -9, 4, 9, 1.5, DARK, k=0.1) + P_([(-14, -13), (14, -13), (11, -8), (-11, -8)], DARK, k=0.2)
    elif det == "ponta":
        g += P_([(-7, 0), (7, 0), (0, -16)], STEEL, k=0.3)
    elif det == "bobina":
        g += R(-2, -12, 4, 12, 1, DARK, k=0.1) + "".join(E(0, -6 - i * 3, 5 - i, 1.6, "#c98a3a", k=0.1) for i in range(3))
    return g + "</g>"


def mochila(tid, a, atras):
    """A: cápsula grande presa nas costas; 'atras' = parte que vai ATRÁS do corpo, senão as alças por cima do peito."""
    _, casco, nucleo, det = tema(tid)
    cx, cy = a["costas"]
    if atras:
        o = f'<g transform="translate({cx - 4},{cy}) rotate(-6)">'
        o += R(-11, -16, 22, 32, 7, casco, k=0.5) + R(-11, -16, 22, 6, 4, shade(casco, 0.2), k=0.2)
        o += R(-7, -8, 14, 13, 4, DARK, k=0.2) + f'<rect x="-5" y="-6" width="10" height="9" rx="3" fill="{nucleo}"/>'
        o += f'<circle cx="0" cy="-2" r="13" fill="{nucleo}" opacity="0.22"/>'
        o += mc.ac.cb.faixa(-11, 8, 22, 4, n=4)
        o += f'<path d="M-6,-12 h7" stroke="{EYE}" stroke-width="2" stroke-linecap="round"/>'
        o += detalhe_topo(tid, 0, -16, 0.75) + "</g>"
        return o
    px, py = a["peito"]
    return (f'<path d="M{cx + 2},{cy - 10} Q{px - 2},{cy - 6} {px + 3},{py + 4}" stroke="{DARK}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            + R(px - 1, py - 1, 6, 6, 1.5, STEEL_D, k=0.1))


def capacete(tid, a):
    """B: VISEIRA DO MECHA levantada na testa (os olhos continuam à mostra): casco no tema, fenda vermelha acesa,
    detalhe do tema no alto da cabeça. Ao ativar, ela desce sobre os olhos e as peças explodem para fora."""
    _, casco, nucleo, det = tema(tid)
    x0, x1, y = a["olhos"]
    y -= 13
    w = x1 - x0 + 6
    o = R(x0 - 3, y - 6, w, 11, 4, casco, k=0.3) + R(x0 - 3, y - 6, w, 3.5, 2, shade(casco, 0.25), k=0.1)
    o += R(x0 + 2, y - 2, w - 10, 5, 2, DARK, k=0.1) + f'<path d="M{x0 + w * 0.35},{y + 0.5} h{w * 0.42}" stroke="{EYE}" stroke-width="2.2" stroke-linecap="round"/>'
    o += f'<circle cx="{x0 + w * 0.55}" cy="{y}" r="6" fill="{EYE}" opacity="0.22"/>'
    o += E(x0 - 3, y, 3, 3, STEEL_D, k=0.1) + E(x1 + 3, y, 3, 3, STEEL_D, k=0.1)
    tx, ty = a["topo"]
    o += detalhe_topo(tid, tx, ty + 4, 0.7)
    return o


def peitoral(tid, a):
    """C: peitoral com o núcleo pulsando + ombreira grande na cor do mecha (um pedaço dele já vestido)."""
    _, casco, nucleo, det = tema(tid)
    px, py = a["peito"]
    sx, sy = a["ombro"]
    o = R(px - 9, py - 8, 17, 16, 5, casco, k=0.4) + R(px - 5, py - 4, 9, 8, 3, DARK, k=0.1)
    o += f'<rect x="{px - 3.5}" y="{py - 2.5}" width="6" height="5" rx="2" fill="{nucleo}"/><circle cx="{px - 0.5}" cy="{py}" r="9" fill="{nucleo}" opacity="0.25"/>'
    o += f'<g transform="translate({sx},{sy}) rotate(10)">' + f'<path d="M-9,4 C-10,-8 10,-10 12,3 Z" fill="{casco}"/>'
    o += mc.ac.cb.faixa(-9, 1, 21, 3.5, n=3) + f'<path d="M-2,-4 h7" stroke="{EYE}" stroke-width="1.8" stroke-linecap="round"/>'
    o += detalhe_topo(tid, 1, -6, 0.5) + "</g>"
    return o


def robo(i, tid, prop, x, y, s):
    a = ANC[i]
    corpo = eu.desenha(i, CORES[i], "parado")
    o = f'<g transform="translate({x},{y}) scale({s})">'
    if prop == "A":
        o += mochila(tid, a, True) + corpo + mochila(tid, a, False)
    elif prop == "B":
        o += corpo + capacete(tid, a)
    else:
        o += corpo + peitoral(tid, a)
    return o + "</g>"


def prancha():
    W, H = 1920, 1300
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', mc.defs(),
         label(W / 2, 54, "COMO O ROBÔ CARREGA O MECHA ANTES DE ATIVAR — 3 PROPOSTAS (sem nada na mão)", 34)]
    props = [("A", "MOCHILA-NÚCLEO", "cápsula nas costas, alças no peito; mãos livres p/ a arma"),
             ("B", "VISEIRA DO MECHA", "viseira na testa + detalhe no alto; desce sobre os olhos ao ativar"),
             ("C", "PEITORAL + OMBREIRA", "um pedaço do mecha já vestido; núcleo pulsando no peito")]
    combos = [(0, "T01"), (1, "T04"), (2, "T07")]
    rh = 390
    for r, (k, nome, sub) in enumerate(props):
        y0 = 90 + r * (rh + 10)
        b.append(f'<rect x="20" y="{y0}" width="{W - 40}" height="{rh}" rx="24" fill="#ffffff" opacity="0.55"/>')
        b.append(label(130, y0 + 60, k, 64, INK) + label(130, y0 + 110, nome, 20, INK))
        b.append(label(150, y0 + 130, "", 16, INK))
        for j, (i, tid) in enumerate(combos):
            cx = 470 + j * 340
            b.append(robo(i, tid, k, cx, y0 + 345, 3.0))
            b.append(label(cx, y0 + 372, f"{eu.ELENCO[i][0]} + {mc.TEMAS[tid][0]}", 18, INK))
        # tamanho do jogo (~80 px de altura)
        gx = 1500
        b.append(f'<rect x="{gx - 40}" y="{y0 + 20}" width="440" height="{rh - 40}" rx="16" fill="#cfeef3"/>')
        b.append(label(gx + 180, y0 + 56, "tamanho do jogo", 20, INK))
        for j, (i, tid) in enumerate(combos):
            b.append(robo(i, tid, k, gx + 40 + j * 140, y0 + 250, 1.15))
        b.append(label(gx + 180, y0 + 320, sub, 15, INK))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/mecha_porte.png")
    queue(svg, os.path.join(HERE, "svg/mecha_porte.svg"), out, W, H, 1)
    print(render_all(), out)


def exportar_jogo():
    """A aprovada (2026-11-27): textura spells/mochila_T0x (só a cápsula das costas; a alça é desenhada no jogo).
    Centro da cápsula em (0,0) da caixa -24..24 × -44..20 (unidades), 8 px por unidade."""
    out = os.path.join(ab.ROOT, "art/out/game/spells")
    os.makedirs(out, exist_ok=True)
    so = [a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--so=")]
    for tid in mc.TEMAS:
        if so and tid not in so[0]:
            continue
        mc._fn(tid)
        g = mochila(tid, {"costas": (4, 0)}, True)   # mochila() desloca -4 em x: centro fica em 0
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="48" height="64" viewBox="-24 -44 48 64">{g}</svg>'
        queue(svg, os.path.join(HERE, f"svg/mochila_{tid}.svg"), os.path.join(out, f"mochila_{tid}.png"), 48, 64, 8)
    print("mochilas:", render_all())


if __name__ == "__main__":
    if "--jogo" in sys.argv:
        exportar_jogo()
    else:
        prancha()
