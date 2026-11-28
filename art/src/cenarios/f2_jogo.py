"""Camadas de JOGO da Fase 2 (Cargueiro Perdido) para modes/cena_cargueiro.gd — saem das fotografias APROVADAS
(f2_prancha.py, A55): o que é PARADO vira camada (PNG 1920x1080, a tela da cena); o que MEXE vira peça solta (sprite) que
o jogo anima. O palco (balsas, rochas, pilares, contêineres) NÃO entra aqui: são tiles/peças do canteiro (blocos C/D).
Cenas no .lvl: etapa1 = Alto-Mar (c1_*), etapa2 = Atlântida (c3_*, rota total), etapa3 = Destroços (c2_*, rota moderada).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_jogo.py → art/out/game/cargueiro/*.png
(copiar para game/assets/cargueiro/ e rodar godot --headless --path game --import)
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
import f2_tubarao as ft  # noqa: E402
import math  # noqa: E402
from f2_prancha import E, INK, W, H, T, R, PL, CONT, fonte, grad, gaivota, sign, conteiner  # noqa: E402
from papel import rough  # noqa: E402
from svg import doc, queue, render_all  # noqa: E402

OUT = os.path.join(fp.ROOT, "art/out/game/cargueiro")
SRC = os.path.join(HERE, "svg/f2_jogo")


def wrap(w, h, body, seed, defs=""):
    return doc(w, h, f'<g filter="url(#rough)">{body}</g>', fonte() + rough(seed=seed, scale=0.8, freq=0.05) + defs)


# ---------------------------------------------------------------- camadas paradas (uma por cena: menos texturas grandes)
def e1_longe():
    """Alto-Mar: céu do fim de tarde com a tempestade chegando + mar + navio distante + o costado do cargueiro (moldura)."""
    return fp.c1_ceu() + fp.c1_longe() + fp.c1_navio_fundo()


def e2_longe():
    """Atlântida: água dourada, cidade e guardião ao fundo, cúpula furada pela proa (a água jorrando à direita)."""
    return fp.c3_agua() + fp.c3_cidade_fundo() + fp.c3_cupula()


def e3_longe():
    """Destroços: manhã depois da tempestade, ilha distante, o navio partido ao fundo (moldura)."""
    return fp.c2_ceu() + fp.c2_navio_fundo()


# ---------------------------------------------------------------- palco FIXO (o que é tile no .lvl; mundo, sem paralaxe)
# Só a base que não quebra, nos mesmos lugares das fotografias (que já casam com os tiles do levels/cargueiro_perdido.lvl).
# O que quebra (contêineres, tábuas, lajes) é peça do canteiro, desenhada pelo jogo.
def e1_palco():
    o = fp.balsa(70, 6 * T) + fp.balsa(22 * T, 7 * T)
    o += R(14 * T, 11 * T + 20, 2 * T, fp.MAR1 - 11 * T, "#9a9488", 4, 2.0, dark="#7a7468")       # pilar de concreto
    o += R(13 * T - 10, 11 * T, 4 * T + 20, 28, "#b9b2a4", 3, 1.6) + fp.zebra(13 * T - 10, 11 * T - 8, 4 * T + 20, 8)
    for k in range(3):
        o += E(13 * T + 20 + k * 100, 11 * T + 40, 16, 10, "#3a3a44", 0.8)   # pneus de atracação
    o += fp.andaime(7 * T, 4 * T, 13 * T) + fp.andaime(21 * T, 4 * T, 13 * T)
    o += R(28 * T, 1 * T, 26, 12 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")                          # torre da grua da balsa
    for k in range(11):
        y = T + 20 + k * 64
        o += f'<path d="M{28 * T},{y} l26,40 M{28 * T + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(9 * T, 1 * T - 14, 20 * T, 20, "#e0a83a", 3, 1.4) + R(28 * T - 30, 1 * T - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += sign(23 * T, 13 * T - 60, "BOTA-ABAIXO", 170)
    # escoras laranja das tábuas do nível 9 (sobre o pilar) e mão-francesa da tábua do nível 6
    o += R(13 * T, 9 * T + 18, 12, 2 * T - 18, "#f08a3d", 2, 1.0, dark="#c06a2a") + R(17 * T - 12, 9 * T + 18, 12, 2 * T - 18, "#f08a3d", 2, 1.0, dark="#c06a2a")
    o += f'<path d="M{7 * T},{6 * T + 130} L{5 * T + 20},{6 * T + 18}" stroke="#c06a2a" stroke-width="10" stroke-linecap="round"/>'
    o += R(28 * T - 30, 6 * T + 18, 30, 14, "#b07a1e", 2, 0.8)
    return o


def e3_palco():
    """Destroços: rochas (topo plano), convés quebrado encravado na rocha-arco, balsa e grua."""
    o = ""
    rx0, rx1, ry = fp.R2_ESQ
    mx0, mx1, my = fp.R2_MEIO
    bx, bw = fp.BALSA2
    H2 = fp.MAR2
    o += fp.rocha2([(rx0 - 40, H), (rx0 - 20, ry + 50), (rx0 + 10, ry), (rx1 - 10, ry), (rx1 + 30, ry + 60), (rx1 + 10, H)], rx0 + 10, rx1 - 10, ry, 3)
    o += fp.rocha2([(mx0 - 30, H), (mx0 - 10, my + 50), (mx0 + 20, my), (mx1 - 20, my), (mx1 + 20, my + 60), (mx1 + 10, H)], mx0 + 20, mx1 - 20, my, 7)
    o += f'<path d="M{mx0 + 60},{H} q{(mx1 - mx0 - 120) / 2},-150 {mx1 - mx0 - 120},0" fill="#174a5a"/>'
    o += fp.balsa(bx, bw)
    tx = bx + bw - 34
    o += R(tx, fp.LANCA2, 26, 13 * T - fp.LANCA2, "#e0a83a", 3, 1.6, dark="#b07a1e")
    for k in range(11):
        y = fp.LANCA2 + 20 + k * 64
        o += f'<path d="M{tx},{y} l26,40 M{tx + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(3 * T, fp.LANCA2 - 14, tx - 3 * T + 40, 20, "#e0a83a", 3, 1.4) + R(tx - 30, fp.LANCA2 - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += f'<path d="M{tx + 13},{fp.LANCA2 - 60} L{3 * T + 20},{fp.LANCA2 - 14}" stroke="#b07a1e" stroke-width="3"/>'
    o += f'<path d="M{rx0 + 24},{ry} q-26,-120 40,-230" stroke="#8a6b4f" stroke-width="16" fill="none"/>'   # coqueiro
    for a in range(5):
        ang = -2.7 + a * 0.5
        o += f'<path d="M{rx0 + 64},{ry - 230} q{math.cos(ang) * 50},{math.sin(ang) * 26 - 26} {math.cos(ang) * 110},{math.sin(ang) * 56 + 20}" stroke="#4f9a52" stroke-width="14" fill="none" stroke-linecap="round"/>'
    o += fp.caranguejo(mx0 + 120, my)
    return o


def e2_palco():
    """Atlântida: os três pilares dourados (topo plano) e a grua submarina da equipe."""
    o = fp.pilar_ouro(1 * T, 6 * T, 12 * T) + fp.pilar_ouro(12 * T, 18 * T, 11 * T) + fp.pilar_ouro(24 * T, 29 * T, 12 * T) + fp.c3_grua()
    # concha-trampolim no pilar do centro (M9 vira mecanismo no bloco C; por enquanto é cenário)
    o += E(15 * T, 11 * T - 30, 48, 18, "#f2a7c3", 1.2) + f'<path d="M{15 * T - 48},{11 * T - 34} a48,40 0 0 1 96,-28" fill="#f7c6d8" stroke="#d1708f" stroke-width="4"/>'
    o += E(15 * T, 11 * T - 36, 10, 8, "#ffffff", 0.6)
    for k in range(9):   # moedas caídas no topo do pilar da direita
        o += E(28 * T + 10 + k * 10, 12 * T - 4 - (k % 3) * 6, 8, 4, fp.OURO, 0.5)
    return o


# ---------------------------------------------------------------- PEÇAS QUE QUEBRAM, cada uma do desenho da fotografia
# (com os suportes: colunas, correntes, escoras, cabos). Nome = p<etapa>_<tipo>_<índice no canteiro>; o jogo lê o recorte
# e a posição (em px da cena) de art/out/game/cargueiro/pecas.json. Coordenadas em px da cena (origem = canto da cena).
TT = T


def _pecas_e1():
    """Alto-Mar: tábuas dos níveis 9 e 6 (andaimes do manifesto) e a viga içada (viga)."""
    return {
        "p1_andaime_0": fp.tabua(8 * TT - 6, 9 * TT, 5 * TT + 12),
        "p1_andaime_1": fp.tabua(17 * TT - 6, 9 * TT, 4 * TT + 12),
        "p1_andaime_2": fp.tabua(5 * TT - 6, 6 * TT, 3 * TT + 12),
        "p1_andaime_3": fp.tabua(22 * TT - 6, 6 * TT, 6 * TT + 12),
        "p1_viga_0": fp.pendurada(20 * TT, 25 * TT, 3 * TT, 1 * TT + 6, 1 * TT + 6) + R(20 * TT - 10, 3 * TT, 5 * TT + 20, 26, "#7a808c", 2, 1.4, dark="#5a606c"),
    }


def _conves_quebrado(lado, x0, x1):
    y = 12 * TT
    o = R(x0, y, x1 - x0, 22, "#6b6f7a", 2, 1.4, dark="#4a4f5a") + R(x0, y + 22, x1 - x0, 22, "#9a4a38", 2, 1.2, dark="#7a3424")
    o += fp.zebra(x0, y - 6, x1 - x0, 7)
    ex = x0 if lado < 0 else x1
    o += f'<path d="M{ex},{y - 6} l{lado * 14},10 l{-lado * 10},8 l{lado * 16},10 l{-lado * 12},10 l{lado * 8},10" stroke="{INK}" stroke-width="4" fill="none"/>'
    for k in range(3):
        o += f'<path d="M{ex - lado * (30 + k * 46)},{y - 6} v-26" stroke="#e9e2d2" stroke-width="4"/>'
    o += f'<path d="M{ex - lado * 30},{y - 32} L{ex - lado * 122},{y - 32}" stroke="#e9e2d2" stroke-width="4"/>'
    sx = (x1 - 40) if lado < 0 else (x0 + 40)
    o += f'<path d="M{sx},{y + 44} Q{sx - lado * 20},{y + 100} {sx + lado * 30},{y + 150}" stroke="#4a2620" stroke-width="14" fill="none" stroke-linecap="round"/>'
    return o


def _pecas_e3():
    """Destroços (ordem das pranchas no manifesto)."""
    dk0, dk1, dky = 11 * TT + 10, 19 * TT - 10, 8 * TT
    deck = R(dk0 + 50, dky + 56, 20, 3 * TT - 56, "#4a2620", 2, 1.0) + R(dk1 - 70, dky + 56, 20, 3 * TT - 56, "#4a2620", 2, 1.0)
    deck += R(dk0, dky, dk1 - dk0, 26, "#6b6f7a", 2, 1.6, dark="#4a4f5a") + R(dk0, dky + 26, dk1 - dk0, 30, "#9a4a38", 2, 1.4, dark="#7a3424")
    deck += fp.zebra(dk0, dky - 6, dk1 - dk0, 8)
    for x in range(int(dk0 + 10), int(dk1), 44):
        deck += f'<path d="M{x},{dky - 6} v-30" stroke="#e9e2d2" stroke-width="4"/>'
    deck += f'<path d="M{dk0},{dky - 30} H{dk1}" stroke="#e9e2d2" stroke-width="4"/>' + E(16 * TT + 30, dky - 14, 18, 14, "#5a5f6a", 0.8)
    t1 = fp.pendurada(18 * TT + 10, 23 * TT - 10, 9 * TT, fp.LANCA2 + 6, fp.LANCA2 + 6) + fp.tabua(18 * TT + 10, 9 * TT, 5 * TT - 20)
    t2 = fp.pendurada(21 * TT + 10, 29 * TT - 10, 5 * TT, fp.LANCA2 + 6, fp.LANCA2 + 6) + fp.tabua(21 * TT + 10, 5 * TT, 8 * TT - 20)
    ci = fp.icado(5.5 * TT, fp.LANCA2 + 6, 5 * TT - 70, 4 * TT + 10, 7 * TT - 10, 5 * TT) + conteiner(4 * TT + 10, 5 * TT, 3 * TT - 20, TT - 8, CONT[5], 0, True)
    nx0, nx1, ny = 12 * TT + 10, 15 * TT - 10, 4 * TT
    rede = f'<path d="M{(nx0 + nx1) / 2},{fp.LANCA2 + 6} V{ny - 50}" stroke="{INK}" stroke-width="4"/>' + fp.gancho((nx0 + nx1) / 2, ny - 50)
    for k in range(3):
        rede += R(nx0 + 6 + k * 58, ny, 54, 50, "#c98a4b" if k != 1 else "#b07a3e", 3, 1.0)
    rede += f'<path d="M{nx0},{ny - 6} Q{(nx0 + nx1) / 2},{ny + 110} {nx1},{ny - 6}" stroke="#5a4a3a" stroke-width="4" fill="none"/>'
    rede += f'<path d="M{(nx0 + nx1) / 2},{ny - 36} L{nx0},{ny - 6} M{(nx0 + nx1) / 2},{ny - 36} L{nx1},{ny - 6}" stroke="#5a4a3a" stroke-width="3"/>'
    for k in range(5):
        rede += f'<path d="M{nx0 + 8 + k * 32},{ny - 4} l18,56" stroke="#5a4a3a" stroke-width="3"/>'
    y14 = 14 * TT
    bote = PL([(7 * TT, y14), (9 * TT, y14), (8 * TT + 40, y14 + 50), (7 * TT + 24, y14 + 50)], "#f08a3d", 1.4) + R(7 * TT, y14 - 6, 2 * TT, 10, "#d9dce4", 2, 0.8)
    jang = "".join(R(9 * TT + 14 + k * 54, y14 + 8, 48, 34, "#c98a4b", 2, 0.8) for k in range(3)) + R(9 * TT + 6, y14, 3 * TT - 12, 12, "#b07a3e", 2, 0.8)
    return {
        "p3_prancha_0": _conves_quebrado(-1, 9 * TT + 10, 12 * TT + 40),
        "p3_prancha_1": _conves_quebrado(1, 17 * TT + 40, 21 * TT - 10),
        "p3_prancha_2": deck,
        "p3_prancha_3": t1,
        "p3_prancha_4": t2,
        "p3_prancha_5": ci,
        "p3_prancha_6": rede,
        "p3_prancha_7": bote,
        "p3_prancha_8": jang,
    }


def _pecas_e2():
    """Atlântida (ordem das pranchas e contêineres no manifesto)."""
    c2, l2, al = fp.coluna2, fp.laje2, fp.alga
    px = 22 * TT + 43   # ponta da proa
    return {
        "p2_prancha_0": c2(6 * TT - 30, 9 * TT + 34, 12 * TT - 14) + c2(12 * TT, 9 * TT + 34, 11 * TT - 14, larg=40) + l2(5 * TT + 10, 9 * TT, 8 * TT - 20) + al(7 * TT, 9 * TT + 34, 2, 110),
        "p2_prancha_1": c2(1 * TT + 20, 6 * TT + 34, 10 * TT) + l2(10, 6 * TT, 6 * TT - 20) + al(2 * TT, 6 * TT + 34, 2, 90),
        "p2_prancha_2": c2(13 * TT, 4 * TT + 34, 7 * TT) + c2(16 * TT + 30, 4 * TT + 34, 7 * TT) + l2(12 * TT + 10, 4 * TT, 6 * TT - 20),
        "p2_prancha_3": c2(12 * TT + 40, 7 * TT + 34, 11 * TT - 14, rachada=True) + c2(17 * TT, 7 * TT + 34, 11 * TT - 14) + l2(11 * TT + 10, 7 * TT, 8 * TT - 20) + al(16 * TT + 20, 7 * TT + 34, 3, 120),
        "p2_prancha_4": c2(24 * TT + 14, 6 * TT + 34, 12 * TT - 14) + c2(28 * TT + 14, 6 * TT + 34, 12 * TT - 14) + l2(23 * TT + 10, 6 * TT, 7 * TT - 20) + al(25 * TT + 20, 6 * TT + 34, 3, 130),
        "p2_prancha_5": fp.pendurada(18 * TT + 10, 22 * TT - 10, 3 * TT, 51, 144) + fp.tabua(18 * TT + 10, 3 * TT, 4 * TT - 20),
        "p2_prancha_6": f'<path d="M{px},136 V{9 * TT - 20}" stroke="#5a5f6a" stroke-width="6" stroke-dasharray="12 6"/>' + fp.gancho(px, 9 * TT - 26)
            + f'<path d="M{px},{9 * TT - 12} L{21 * TT + 20},{9 * TT} M{px},{9 * TT - 12} L{24 * TT - 20},{9 * TT}" stroke="#5a5f6a" stroke-width="4"/>'
            + R(21 * TT + 10, 9 * TT, 3 * TT - 20, 40, fp.MARM, 4, 1.6, dark=fp.MARM_D) + R(21 * TT + 10, 9 * TT + 30, 3 * TT - 20, 10, fp.OURO, 2, 0.6),
        "p2_prancha_7": f'<path d="M660,79 L{10 * TT},{3 * TT + 30}" stroke="{fp.OURO_D}" stroke-width="5" stroke-dasharray="10 6"/>' + f'<circle cx="660" cy="79" r="8" fill="{fp.OURO}"/>'
            + f'<path d="M{10 * TT},{3 * TT + 30} L{8 * TT + 20},{4 * TT} M{10 * TT},{3 * TT + 30} L{12 * TT - 20},{4 * TT}" stroke="{fp.OURO_D}" stroke-width="4"/>'
            + R(8 * TT + 10, 4 * TT, 4 * TT - 20, 18, fp.OURO, 3, 1.2, dark=fp.OURO_D)
            + f'<path d="M{8 * TT + 20},{4 * TT + 18} Q{10 * TT},{5 * TT + 40} {12 * TT - 20},{4 * TT + 18}" stroke="{fp.OURO}" stroke-width="8" fill="none"/>'
            + "".join(f'<circle cx="{8 * TT + 34 + k * 46}" cy="{4 * TT - 10}" r="8" fill="#fff6c8"/><circle cx="{8 * TT + 34 + k * 46}" cy="{4 * TT - 10}" r="20" fill="#fff6c8" opacity="0.25"/>' for k in range(5)),
        "p2_conteiner_7": fp.tambores(1 * TT + 16, 12 * TT, 2) + f'<rect x="{TT}" y="{12 * TT - 6}" width="2" height="2" fill="none"/>',
        "p2_conteiner_8": E(4 * TT, 12 * TT - 50, 58, 50, "#cfc6b0", 1.6, dark="#a89c82") + E(4 * TT + 20, 12 * TT - 60, 10, 6, "#8a826e", 0.6)
            + PL([(3 * TT + 20, 12 * TT - 86), (3 * TT + 50, 12 * TT - 124), (4 * TT + 10, 12 * TT - 96), (4 * TT + 50, 12 * TT - 128), (4 * TT + 70, 12 * TT - 86)], fp.OURO, 1.0),
        "p2_conteiner_9": conteiner(25 * TT + 4, 11 * TT, 3 * TT - 8, TT, CONT[3], 0, True)
            + R(26 * TT, 11 * TT - 40, 70, 40, "#8a5a3a", 4, 1.0) + R(26 * TT, 11 * TT - 40, 70, 12, fp.OURO, 2, 0.6),
    }


PECAS = {1: _pecas_e1, 2: _pecas_e2, 3: _pecas_e3}


def cont(cor):
    def f():
        return conteiner(4, 4, 3 * T - 8, T - 8, cor, 0, True)
    return f


DEFS = {
    "e1_longe": grad("c1ceu", [(0, "#f7b27a"), (0.45, "#e8988a"), (1, "#6f6aa0")]) + grad("c1poro", [(0, "#3a3a48"), (1, "#14141c")]),
    "e2_longe": grad("c3agua", [(0, "#5fd0d8"), (0.55, "#2a8fa8"), (1, "#14506e")]) + grad("c3fenda", [(0, "#14506e"), (0.5, "#0a2a40"), (1, "#02080f")]),
    "e3_longe": grad("c2ceu", [(0, "#ffe2b0"), (0.5, "#cfe9f0"), (1, "#a8e0e8")]) + grad("c2fundo", [(0, "#2f8f9a"), (0.35, "#1f5f78"), (1, "#0b2f45")]),
}


# ---------------------------------------------------------------- peças que mexem (o jogo anima)
def gaivota_voa():
    return gaivota(8, 30, 1.6)


def gaivota_pousada():
    return gaivota(30, 40, 1.6, pousada=True)


def onda(cor, cor2):
    """Faixa de onda da frente (repete na horizontal; o jogo desliza e balança)."""
    def f():
        d = "M0,140 L0,40"
        x = 0
        while x < 960:
            d += " q30,-22 60,0 t60,0"
            x += 120
        d += " L960,140 Z"
        o = fp.S(d, cor, (0, 18, 960, 140), k=2.2, dark=fp.shade(cor, -0.25))
        for k in range(6):
            xx = 60 + k * 150
            o += f'<path d="M{xx},{80 + (k % 3) * 14} q16,-6 32,0" stroke="{cor2}" stroke-width="4" fill="none" opacity="0.8"/>'
        return o
    return f


def agua_viva():
    o = E(40, 34, 30, 22, "#f4a6d8", 1.2) + E(40, 40, 22, 10, "#e07ab8", 0.8)
    for k in range(5):
        x = 18 + k * 11
        o += f'<path d="M{x},50 q6,14 0,28 q-6,14 0,26" stroke="#f4a6d8" stroke-width="3.5" fill="none" opacity="0.85"/>'
    return o


def peixe(cor):
    def f():
        return (E(36, 20, 24, 12, cor, 1.0) + fp.PL([(12, 20), (0, 8), (0, 32)], cor, 0.8)
                + E(50, 17, 3.5, 3.5, INK, 0.3))
    return f


SPRITES = {
    "gaivota": (64, 48, gaivota_voa),
    "gaivota_pousada": (72, 56, gaivota_pousada),
    "onda_tarde": (960, 140, onda("#4a7fae", "#cfe3f2")),
    "onda_manha": (960, 140, onda("#58b8c4", "#ffffff")),
    "agua_viva": (80, 110, agua_viva),
    "peixe_a": (64, 40, peixe("#f2a33a")),
    "peixe_b": (64, 40, peixe("#e8bc4a")),
    **{f"cont_{i}": (3 * T, T, cont(c)) for i, c in enumerate(CONT)},
    "tubarao": (300, 160, lambda: ft.tubarao(170, 90, 0, 0.0)),
    "tubarao_boca": (300, 160, lambda: ft.tubarao(170, 90, 0, 1.0)),
    "barbatana": (120, 70, lambda: ft.barbatana(60, 60, 1.0)),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    for i, (name, fn) in enumerate([("e1_longe", e1_longe), ("e2_longe", e2_longe), ("e3_longe", e3_longe)]):
        queue(wrap(W, H, fn(), 41 + i, DEFS[name]), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", W, H, 1)
    for i, (name, fn) in enumerate([("e1_palco", e1_palco), ("e2_palco", e2_palco), ("e3_palco", e3_palco)]):
        queue(wrap(W, H, fn(), 51 + i), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", W, H, 1)
    for i, (name, (w, h, fn)) in enumerate(SPRITES.items()):
        queue(wrap(w, h, fn(), 61 + i), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", w, h, 2)
    tmp = os.path.join(OUT, "_pecas")
    nomes = []
    for et, fn in PECAS.items():
        for i, (name, body) in enumerate(fn().items()):
            queue(wrap(W, H, body, 71 + i + et * 10), f"{SRC}/{name}.svg", f"{tmp}/{name}.png", W, H, 1)
            nomes.append(name)
    print("fase 2 (jogo):", render_all())
    _recorta(tmp, nomes)


def _recorta(tmp, nomes):
    """Recorta cada peça (desenhada na tela inteira da cena) no menor retângulo e guarda a posição em pecas.json."""
    import json
    from PIL import Image
    pos = {}
    for n in nomes:
        im = Image.open(f"{tmp}/{n}.png")
        bb = im.getbbox()
        if bb is None:
            continue
        bb = (max(bb[0] - 2, 0), max(bb[1] - 2, 0), min(bb[2] + 2, im.width), min(bb[3] + 2, im.height))
        im.crop(bb).save(f"{OUT}/{n}.png")
        pos[n] = [bb[0], bb[1], bb[2] - bb[0], bb[3] - bb[1]]
    with open(f"{OUT}/pecas.json", "w") as f:
        json.dump(pos, f, indent=1)


if __name__ == "__main__":
    main()
