"""Exporta para o jogo a arte de CONTROLES (aprovada na prancha controles_v2, 2026-11-28):
- controle_<modelo>.png  (desenho do controle, 660×450, centro do desenho em ORIG)
- glifos_<modelo>.png    (ícones dos botões, grade 5×5 de células CEL px, ordem em GLIFOS)
- tecla.png / tecla_larga.png (tecla de papel vazia; o jogo escreve o nome da tecla)
- layout.json            (posição de cada botão no desenho do controle, para acender)
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/controles_export.py ; depois cp -r art/out/game/ui/controles game/assets/ui/
"""
import base64
import json
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import controles_arte as ca  # noqa: E402
import etapa_c as ec  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/game/ui/controles")
SRC = os.path.join(HERE, "svg/controles")
MODELOS = ["ps5", "ps4", "xbox", "switch", "gen"]
GLIFOS = ["baixo", "dir", "esq", "cima", "lb", "rb", "lt", "rt", "start", "select", "ls", "rs", "d",
          "d-cima", "d-baixo", "d-esq", "d-dir", "l-cima", "l-baixo", "l-esq", "l-dir", "r-cima", "r-baixo", "r-esq", "r-dir"]
CEL, R = 128, 34
W, H, ESC = 660, 470, 1.5
ORIG = (330, 215)


def svg(w, h, corpo):
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    style = "<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}</style>"
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{style}{ca.defs()}{corpo}</svg>'


def layout(m):
    """Posição (px no PNG do controle) e raio de cada botão — mesmas contas de controles_arte._ps/_assim."""
    if m in ("ps5", "ps4"):
        L = {"baixo": (140, 9, 15), "cima": (140, -53, 15), "esq": (109, -22, 15), "dir": (171, -22, 15),
             "ls": (-56, 34, 27), "rs": (56, 34, 27), "lb": (-150, -102, 24), "rb": (150, -102, 24),
             "lt": (-150, -112, 26), "rt": (150, -112, 26), "select": (-96, -82, 12), "start": (96, -82, 12),
             "d-cima": (-140, -44, 11), "d-baixo": (-140, 0, 11), "d-esq": (-162, -22, 11), "d-dir": (-118, -22, 11)}
    else:
        dx, dy = -62, 40
        L = {"baixo": (128, 7, 14), "cima": (128, -51, 14), "esq": (99, -22, 14), "dir": (157, -22, 14),
             "ls": (-128, -22, 27), "rs": (62, 40, 27), "lb": (-142, -94, 24), "rb": (142, -94, 24),
             "lt": (-150, -104, 26), "rt": (150, -104, 26),
             "d-cima": (dx, dy - 17, 10), "d-baixo": (dx, dy + 17, 10), "d-esq": (dx - 17, dy, 10), "d-dir": (dx + 17, dy, 10)}
        L.update({"xbox": {"select": (-40, -14, 10), "start": (40, -14, 10)}, "switch": {"select": (-40, -52, 10), "start": (40, -52, 10)},
                  "gen": {"select": (-30, -40, 12), "start": (30, -40, 12)}}[m])
    return {k: [round(ORIG[0] + x * ESC, 1), round(ORIG[1] + y * ESC, 1), round(r * ESC, 1)] for k, (x, y, r) in L.items()}


def main():
    lay = {"glifos": GLIFOS, "cel": CEL, "colunas": 5, "modelos": {}}
    for m in MODELOS:
        queue(svg(W, H, ca.ctrl(ORIG[0], ORIG[1], m, ESC)), f"{SRC}/controle_{m}.svg", f"{OUT}/controle_{m}.png", W, H, 1)
        cel = []
        for i, g in enumerate(GLIFOS):
            cx, cy = (i % 5) * CEL + CEL / 2, (i // 5) * CEL + CEL / 2
            cel.append(ca.glifo(cx, cy, m, g, R))
        queue(svg(5 * CEL, 5 * CEL, "".join(cel)), f"{SRC}/glifos_{m}.svg", f"{OUT}/glifos_{m}.png", 5 * CEL, 5 * CEL, 1)
        lay["modelos"][m] = layout(m)
    queue(svg(CEL, CEL, ca.tecla(CEL / 2, CEL / 2, "", r=R)), f"{SRC}/tecla.svg", f"{OUT}/tecla.png", CEL, CEL, 1)
    queue(svg(CEL * 2, CEL, ca.tecla(CEL, CEL / 2, "", w=R * 5, r=R)), f"{SRC}/tecla_larga.svg", f"{OUT}/tecla_larga.png", CEL * 2, CEL, 1)
    os.makedirs(OUT, exist_ok=True)
    json.dump(lay, open(f"{OUT}/layout.json", "w"), indent=1)
    print(render_all(), OUT)


if __name__ == "__main__":
    main()
