"""EXPORTA a arte da GANGORRA A (balança da grua) e das CAIXAS de prêmio (pranchas g1/g2/g3 aprovadas em 2026-11-27).
Cada caixa em 3 texturas de MESMA moldura e origem (centro da caixa): corpo, tampa (com o enfeite) e conteúdo (o que
salta ao abrir). Gangorra: viga (origem = pivô), cesto (origem = ponto de pendurar) e gancho (origem = olhal).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/premio_export.py → art/out/game/premio/*.png (copiar p/ game/assets/premio)
"""
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import recompensas_v2 as rv  # noqa: E402
from menus_v2 import ec, fp, INK, YEL  # noqa: E402

OUT = os.path.join(ec.ROOT, "art/out/game/premio")
PX = 2.5   # px da textura por unidade do desenho (o jogo escala para baixo)
CX = (-180, -350, 360, 470)   # moldura das caixas (x, y, w, h), unidades; origem = centro da caixa


def svg(vb, body):
    x, y, w, h = vb
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * PX:.0f}" height="{h * PX:.0f}" viewBox="{x} {y} {w} {h}">'
            f'{body}</svg>'), round(w * PX), round(h * PX)


def caixa_partes(cat):
    """Corpo (fechado, sem tampa), tampa+enfeite (fechada) e conteúdo (como fica com a tampa toda aberta)."""
    return (rv.caixa(cat, 0, 0, 1.0, parte="corpo"), rv.caixa(cat, 0, 0, 1.0, parte="tampa"),
            rv.caixa(cat, 0, 0, 1.0, tampa=1.0, parte="conteudo"))


def main():
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="premio_")
    jobs, meta = [], {"px": PX, "caixa": list(CX)}
    for cat in ("skin", "spell", "evento"):
        for nome, body in zip(("corpo", "tampa", "conteudo"), caixa_partes(cat)):
            sv, w, h = svg(CX, body)
            p = os.path.join(tmp, f"{cat}_{nome}.svg")
            open(p, "w").write(sv)
            jobs.append({"svg": p, "png": os.path.join(OUT, f"caixa_{cat}_{nome}.png"), "w": w, "h": h, "scale": 1})
    # gangorra A em peças: viga (pivô em 0,0), cesto (pendurado em 0,0) e gancho (olhal em 0,0)
    viga = (f'<path d="M-6,-14 L-380,4 M6,-14 L380,4" stroke="#4a4f5c" stroke-width="5"/>'
            + "".join(f'<rect x="{-420 + k * 140}" y="-2" width="140" height="34" fill="{rv.ZC[k]}" stroke="{INK}" stroke-width="5"/>' for k in range(6))
            + f'<rect x="-420" y="-2" width="840" height="34" rx="6" fill="none" stroke="{INK}" stroke-width="7"/>'
            + f'<circle cx="0" cy="0" r="16" fill="#8d98a4" stroke="{INK}" stroke-width="6"/>')
    cesto = (f'<path d="M-50,0 L-60,158 M50,0 L60,158" stroke="#4a4f5c" stroke-width="5"/>'
             f'<path d="M-80,158 h160 l-16,60 h-128 z" fill="#8d98a4" stroke="{INK}" stroke-width="6"/>'
             f'<path d="M-62,178 h124 M-58,198 h116" stroke="#6b7684" stroke-width="4"/>'
             f'<circle cx="0" cy="0" r="7" fill="#4a4f5c"/>')
    gancho = (f'<rect x="-34" y="-100" width="68" height="56" rx="10" fill="{YEL}" stroke="{INK}" stroke-width="7"/>' + fp.cd.zebra(-34, -66, 68, 14)
              + f'<path d="M0,-44 v22 a16,16 0 1 1 -18,14" stroke="#8d98a4" stroke-width="10" fill="none" stroke-linecap="round"/>')
    for nome, vb, body in (("viga", (-430, -40, 860, 84), viga), ("cesto", (-90, -12, 180, 240), cesto), ("gancho", (-44, -110, 88, 136), gancho)):
        sv, w, h = svg(vb, body)
        p = os.path.join(tmp, f"{nome}.svg")
        open(p, "w").write(sv)
        jobs.append({"svg": p, "png": os.path.join(OUT, f"gangorra_{nome}.png"), "w": w, "h": h, "scale": 1})
        meta[nome] = list(vb)
    jp = os.path.join(tmp, "jobs.json")
    json.dump(jobs, open(jp, "w"))
    subprocess.run(["node", os.path.join(ec.ROOT, "tools/render_svg.js"), jp], check=True)
    json.dump(meta, open(os.path.join(OUT, "premio.json"), "w"), indent=1)
    print(len(jobs), "texturas →", OUT)


if __name__ == "__main__":
    main()
