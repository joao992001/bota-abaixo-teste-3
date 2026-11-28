"""Exporta a arte da tela PROJETOS DE DEMOLIÇÃO v2 (prancha art/out/ui/projetos_v2.png, aprovada 2026-11-28):
andar_a/andar_b (um andar do prédio, 480×100: andar 460×80 + laje), grua (torre + lança, 640×760, topo da torre em (520,20)),
bola (130×130), tijolo_a/b e entulho (monte). Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/projetos_export.py
e depois cp art/out/game/ui/projetos/* game/assets/ui/projetos/
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import controles_arte as ca  # noqa: E402
import projetos_v2 as pv  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/game/ui/projetos")
SRC = os.path.join(HERE, "svg/projetos")


def svg(w, h, corpo):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{ca.defs()}{corpo}</svg>'


def andar(cor):
    o = pv.rect(10, 6, 460, 80, cor, 2.0, vol=6) + pv.rect(0, 76, 480, 12, pv.CONC, 1.4)
    for j in range(4):
        o += pv.rect(44 + j * 108, 24, 64, 42, pv.JAN, 1.2)
        o += f'<path d="M{76 + j * 108},24 v42" stroke="{shade(pv.JAN, 0.35)}" stroke-width="3"/>'
    return o


def grua():
    x = 520
    o = pv.rect(x, 20, 34, 740, "#e0a83a", 1.6)
    for k in range(15):
        o += f'<path d="M{x},{40 + k * 48} l34,40 M{x + 34},{40 + k * 48} l-34,40" stroke="#b07a1e" stroke-width="4"/>'
    o += pv.rect(10, 10, 620, 30, "#e0a83a", 1.6)
    for k in range(20):
        o += f'<path d="M{20 + k * 30},{12} l20,26" stroke="#b07a1e" stroke-width="3"/>'
    o += pv.rect(560, 40, 60, 50, "#8a8f9a", 1.2)
    return o


def main():
    jobs = [("andar_a", 480, 100, andar(pv.TIJ)), ("andar_b", 480, 100, andar(shade(pv.TIJ, -0.07))),
            ("grua", 640, 760, grua()),
            ("bola", 130, 130, ca.P(ca.circ_d(65, 65, 56), "#4b505c", (9, 9, 121, 121), 1.6, vol=8) + '<circle cx="49" cy="47" r="12" fill="#7d8494" opacity="0.7"/>'),
            ("tijolo_a", 40, 28, pv.rect(4, 4, 32, 20, pv.TIJ, 1.0, vol=3)),
            ("tijolo_b", 40, 28, pv.rect(4, 4, 32, 20, pv.CONC, 1.0, vol=3)),
            ("entulho", 560, 110, pv.predio(50, 106, 0, 0, ruina=34))]
    for nm, w, h, corpo in jobs:
        queue(svg(w, h, corpo), f"{SRC}/{nm}.svg", f"{OUT}/{nm}.png", w, h, 1)
    print(render_all(), OUT)


if __name__ == "__main__":
    main()
