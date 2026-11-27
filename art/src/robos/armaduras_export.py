"""EXPORTA as armaduras-mecha (A29/A31) para o jogo: cada PEÇA numa textura do mesmo tamanho e mesma origem (o jogo
empilha e anima a transformação peça por peça), o tronco nas 4 cores de jogador (faixa), a bola fechada (T03) nas 4
cores e um JSON com pivôs, ombro, ponta da arma, cockpit e olho.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/armaduras_export.py → art/out/game/mecha/*  (copiar p/ game/assets/mecha)
"""
import json
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import armaduras_conceito as ac  # noqa: E402
import armaduras_habilidades as ah  # noqa: E402
from armaduras_conceito import ab  # noqa: E402
from elenco import COLORS  # noqa: E402
from svg import queue, render_all  # noqa: E402

X0, Y0, CWU, CHU = -150, -280, 340, 300      # caixa comum de todas as peças, em unidades do desenho (pés em 0,0)
PX = 0.84                                     # px de jogo por unidade (mesma escala dos robôs: k=0.84)
SS = 2                                        # supersample
OUT = os.path.join(ab.ROOT, "art/out/game/mecha")
SRC = os.path.join(HERE, "svg/mecha")
PECAS = ["costas", "perna_b", "braco_b", "tronco", "cabine", "peito", "perna_f", "cabeca", "ombro_b", "arma", "ombro_f"]
MECHAS = {"T01": ac.fornalha, "T02": ac.empilhadeira, "T03": ac.bola, "T04": ac.jato, "T05": ac.broca, "T06": ah.para_raios}
# ponta da arma (a partir do ombro, sem giro) — de onde saem fogo, raio, broca, garfo, jato de ar
PONTA = {"T01": (64, 15), "T02": (80, 6), "T03": (30, 70), "T04": (60, 14), "T05": (80, 12), "T06": (84, 13)}


def doc(body):
    w, h = CWU * PX, CHU * PX
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" viewBox="{X0} {Y0} {CWU} {CHU}">'
            f'{body}</svg>'), round(w), round(h)


def so(nome, fn, col):
    """Desenha o mecha mostrando só a peça `nome` (as outras com opacidade 0) e captura os pivôs."""
    ac.PARTES.clear()
    for p in PECAS:
        if p != nome:
            ac.PARTES[p] = dict(op=0)
    out = fn(col)
    ac.PARTES.clear()
    return out


def pivos(fn, col):
    piv = {}
    orig = ac._g

    def spy(nome, svg, p=(0, 0)):
        piv[nome] = [round(p[0], 2), round(p[1], 2)]
        return orig(nome, svg, p)
    ac._g = spy
    fn(col)
    ac._g = orig
    return piv


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    ac.ESTATICO[0] = False
    ac.PILOTO[0] = False
    meta = {"px": PX, "caixa": [X0, Y0, CWU, CHU], "pecas": PECAS, "mechas": {}}
    for tid, fn in MECHAS.items():
        cfg = {}
        for p in PECAS:
            cores = COLORS[:4] if p == "tronco" else [COLORS[0]]
            for ci, col in enumerate(cores):
                svg, w, h = doc(so(p, fn, col))
                nm = f"{tid}_{p}" + (f"_p{ci + 1}" if p == "tronco" else "")
                queue(svg, f"{SRC}/{nm}.svg", f"{OUT}/{nm}.png", w, h, SS)
        pv = pivos(fn, COLORS[0])
        fn(COLORS[0])
        sh = ac.OMBRO[0]
        n = fn.__name__
        cfg = {"pivos": pv, "ombro": [round(sh[0], 2), round(sh[1], 2)], "ponta": list(PONTA[tid]), "tem": [p for p in PECAS if p in pv]}
        meta["mechas"][tid] = cfg
    for ci, col in enumerate(COLORS[:4]):   # T03 fechada (bola blindada) para rolar
        svg, w, h = doc(f'<g transform="translate(0,0)">{ac.bola_fechada(col, 0)}</g>')
        queue(svg, f"{SRC}/T03_bola_p{ci + 1}.svg", f"{OUT}/T03_bola_p{ci + 1}.png", w, h, SS)
    # cockpit / olho: mesma conta do mecha() (quadro padrão do tronco → corpo de cada um)
    corpo = {"T01": (40, 1.35, 0.85, (36, 26)), "T02": (66, 1.1, 1.15, (30, 26)), "T03": (40, 1.25, 1.05, (30, 26)),
             "T04": (62, 0.95, 1.0, (30, 26)), "T05": (78, 0.75, 0.95, (26, 24)), "T06": (50, 1.0, 1.0, (30, 26))}
    for tid, (Hh, tw, th, cab) in corpo.items():
        meta["mechas"][tid]["cockpit"] = [round(4 * tw, 2), round(-Hh + (-102 + 58) * th, 2), cab[0], cab[1]]
        meta["mechas"][tid]["olho"] = [round(10 * tw + 8, 2), round(-Hh + (-136 + 58) * th - 1, 2)]
    print("mecha:", render_all())
    with open(f"{OUT}/mechas.json", "w") as f:
        json.dump(meta, f, indent=1)
    ac.ESTATICO[0] = True
    ac.PILOTO[0] = True


if __name__ == "__main__":
    main()
