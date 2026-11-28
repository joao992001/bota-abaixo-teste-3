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
from f2_prancha import E, INK, W, H, fonte, grad, gaivota  # noqa: E402
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
}


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    for i, (name, fn) in enumerate([("e1_longe", e1_longe), ("e2_longe", e2_longe), ("e3_longe", e3_longe)]):
        queue(wrap(W, H, fn(), 41 + i, DEFS[name]), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", W, H, 1)
    for i, (name, (w, h, fn)) in enumerate(SPRITES.items()):
        queue(wrap(w, h, fn(), 61 + i), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", w, h, 2)
    print("fase 2 (jogo):", render_all())


if __name__ == "__main__":
    main()
