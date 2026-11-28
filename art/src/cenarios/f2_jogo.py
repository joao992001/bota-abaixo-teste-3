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
    return fp.pilar_ouro(1 * T, 6 * T, 12 * T) + fp.pilar_ouro(12 * T, 18 * T, 11 * T) + fp.pilar_ouro(24 * T, 29 * T, 12 * T) + fp.c3_grua()


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
    print("fase 2 (jogo):", render_all())


if __name__ == "__main__":
    main()
