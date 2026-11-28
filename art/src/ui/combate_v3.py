"""PRANCHA para aprovar — refinamento do COMBATE (etapa 2 da avaliação de gameplay, 2026-11-26).
Pedido: acertar é difícil; "bate e tudo fica parado"; golpe pesado fraco ("nerfado"); a destruição tem de vir da LUTA
(arremesso, crítico) e não de ficar parado marretando; dar para "se segurar" e destruir menos.
Referências pesquisadas: Smash (smash attack carregado até 1,4×, congelamento maior quanto mais forte o golpe, dano
aumenta o arremesso) e Brawlhalla (pesados direcionais ◄► ▲ ▼ como finalizadores que mandam longe).
Rodar: python3 art/src/ui/combate_v3.py → art/out/robos_v2/r2_combate.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "../robos"))
import etapa_c as ec  # noqa: E402
import articulado as ar  # noqa: E402
from etapa_c import INK, W, H  # noqa: E402

OUT = os.path.join(ec.ROOT, "art/out/robos_v2")
CREAM = "#fff6e4"
BLUE, GREEN, PINK = "#4f86d9", "#5cc45c", "#f06aa8"


def robo(cid, pose, col, x, y, s=1.6, flip=False):
    sx = -s if flip else s
    return f'<g transform="translate({x},{y}) scale({sx},{s})">{ar.draw2(cid, pose, col)}</g>'


def painel(x, y, w, h, num, titulo):
    return (ec.chunk(x, y, w, h, CREAM, 22, 5, 8) + f'<circle cx="{x + 34}" cy="{y + 36}" r="22" fill="#e08a1e" stroke="{INK}" stroke-width="4"/>'
            + ec.T(x + 34, y + 45, str(num), 26, "#ffffff") + ec.T(x + 66, y + 46, titulo, 28, INK, "start"))


def linha(x, y, hoje, nova, txt):
    return (ec.T(x, y, txt, 18, INK, "start", w=600) + ec.T(x + 330, y, hoje, 18, "#a01528", "start")
            + ec.T(x + 410, y, "→", 18, INK, "start") + ec.T(x + 435, y, nova, 18, "#2e7d32", "start"))


def chao(x, y, w):
    return f'<rect x="{x}" y="{y}" width="{w}" height="10" rx="3" fill="#c9b99a"/>'


def tela():
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', ec.title(W / 2, 62, "COMBATE — REFINAMENTO (proposta)", 50)]
    pw, ph = 925, 470
    # 1 ACERTAR FICA FÁCIL
    x, y = 25, 100
    b.append(painel(x, y, pw, ph, 1, "ACERTAR FICA FÁCIL"))
    b.append(chao(x + 30, y + 300, 420))
    k_hit = ar.KEYS["marretao"][3][1]
    b.append(robo("marretao", k_hit, BLUE, x + 150, y + 300, 1.7))
    b.append(f'<path d="M{x + 175},{y + 170} A120,120 0 0 1 {x + 300},{y + 300} L{x + 175},{y + 300} Z" fill="#ffe27a" opacity="0.35" stroke="#e0a21e" stroke-width="3" stroke-dasharray="8 6"/>')
    b.append(f'<rect x="{x + 175}" y="{y + 215}" width="92" height="70" fill="none" stroke="#a01528" stroke-width="3" stroke-dasharray="5 5"/>')
    b.append(ec.T(x + 290, y + 232, "hoje", 16, "#a01528") + ec.T(x + 300, y + 175, "proposta (arco)", 16, "#9a6a00"))
    b.append(robo("picareta", ar.KEYS["picareta"][7][1], GREEN, x + 360, y + 300, 1.5, flip=True))
    b.append(f'<path d="M{x + 210},{y + 330} h60" stroke="{INK}" stroke-width="4" marker-end="url(#seta)"/>' + ec.T(x + 240, y + 356, "avanço curto até o rival", 15, INK))
    lx = x + 470
    for i, (t, a, n) in enumerate([("alcance do golpe leve", "54 px", "80 px"), ("área", "caixa", "arco frente+cima"), ("tempo ativo", "0,06 s", "0,10 s"),
                                   ("ímã: rival perto", "—", "avança 40 px"), ("aperto antecipado", "—", "0,15 s vale")]):
        b.append(ec.T(lx, y + 120 + i * 62, t, 19, INK, "start", w=600))
        b.append(ec.T(lx, y + 146 + i * 62, a, 19, "#a01528", "start") + ec.T(lx + 110, y + 146 + i * 62, "→ " + n, 19, "#2e7d32", "start"))
    # 2 FLUXO: BATE E SEGUE
    x = 970
    b.append(painel(x, y, pw, ph, 2, "BATE E SEGUE (sem travar)"))
    b.append(chao(x + 30, y + 300, 860))
    for i, (px, lab) in enumerate([(130, "1 leve"), (330, "2 leve"), (560, "3 FINAL")]):
        kk = ar.KEYS["marretao"][3][1] if i < 2 else ar.KEYS["marretao"][5][1]
        b.append(robo("marretao", kk, BLUE, x + px, y + 300, 1.25))
        b.append(ec.T(x + px + 20, y + 335, lab, 18, INK))
    b.append(robo("picareta", ar.KEYS["picareta"][8][1], GREEN, x + 780, y + 250, 1.25, flip=True))
    b.append(f'<path d="M{x + 640},{y + 240} Q{x + 700},{y + 170} {x + 760},{y + 200}" stroke="{INK}" stroke-width="4" fill="none" stroke-dasharray="10 7"/>')
    for i, (t, a, n) in enumerate([("empurrão do leve (0%)", "190", "300"), ("recuperação do leve", "0,13 s", "0,08 s"),
                                   ("acertou: cancela em pulo/esquiva", "não", "sim"), ("3º golpe do combo", "igual", "arremessa")]):
        b.append(ec.T(x + 40, y + 372 + i * 24, t, 17, INK, "start", w=600) + ec.T(x + 420, y + 372 + i * 24, a, 17, "#a01528", "start")
                 + ec.T(x + 520, y + 372 + i * 24, "→ " + n, 17, "#2e7d32", "start"))
    # 3 GOLPE PESADO REPENSADO
    x, y = 25, 590
    b.append(painel(x, y, pw, ph, 3, "GOLPE PESADO REPENSADO"))
    b.append(chao(x + 30, y + 290, 520))
    b.append(robo("marretao", ar.KEYS["marretao"][4][1], BLUE, x + 120, y + 290, 1.45))
    b.append(f'<rect x="{x + 70}" y="{y + 316}" width="120" height="16" rx="8" fill="#ffffff" stroke="{INK}" stroke-width="3"/><rect x="{x + 72}" y="{y + 318}" width="80" height="12" rx="6" fill="#e0841e"/>')
    b.append(ec.T(x + 130, y + 355, "SEGURE = carrega", 16, INK))
    b.append(robo("marretao", ar.KEYS["marretao"][5][1], BLUE, x + 330, y + 290, 1.45))
    b.append(ec.T(x + 390, y + 355, "SOLTE = golpe", 16, INK))
    b.append(f'<circle cx="{x + 420}" cy="{y + 282}" r="22" fill="none" stroke="#d42035" stroke-width="4"/>' + ec.T(x + 500, y + 210, "PONTA = CRÍTICO", 16, "#d42035"))
    for i, (t, a, n) in enumerate([("preparo (toque)", "0,40 s", "0,24 s"), ("carga (segurar)", "—", "até 1 s: ×1,6"),
                                   ("leve interrompe?", "sim", "não (armadura)"), ("recarga", "0,9 s", "0,6 s"),
                                   ("direções ◄► ▲ ▼", "1 golpe", "4 golpes"), ("ponta da ferramenta", "—", "crítico +50%")]):
        b.append(ec.T(x + 560, y + 100 + i * 52, t, 18, INK, "start", w=600))
        b.append(ec.T(x + 560, y + 124 + i * 52, a, 18, "#a01528", "start") + ec.T(x + 670, y + 124 + i * 52, "→ " + n, 18, "#2e7d32", "start"))
    b.append(ec.T(x + 300, y + 410, "◄► arremessa longe · ▲ antiaéreo · ▼ bate no chão (racha o piso)", 16, "#6b5a70"))
    # 4 DESTRUIÇÃO PELA LUTA
    x = 970
    b.append(painel(x, y, pw, ph, 4, "A OBRA QUEBRA COM A LUTA"))
    b.append(chao(x + 30, y + 300, 860))
    b.append(f'<rect x="{x + 620}" y="{y + 120}" width="40" height="180" fill="#d9a35f" stroke="{INK}" stroke-width="3"/>' + f'<path d="M{x + 628},{y + 150} l14,24 l-10,18 l16,28" stroke="{INK}" stroke-width="3" fill="none"/>')
    b.append(robo("picareta", ar.KEYS["picareta"][8][1], GREEN, x + 560, y + 230, 1.3))
    b.append(f'<path d="M{x + 330},{y + 240} Q{x + 450},{y + 180} {x + 560},{y + 200}" stroke="{INK}" stroke-width="4" fill="none" stroke-dasharray="10 7"/>')
    b.append(robo("marretao", ar.KEYS["marretao"][5][1], BLUE, x + 210, y + 300, 1.3))
    b.append(ec.T(x + 640, y + 105, "BATEU FORTE = QUEBRA", 16, "#d42035"))
    for i, t in enumerate(["Arremessado forte contra parede/andaime/laje: a peça leva dano (e ele quica).",
                           "Crítico e pesado carregado danificam o chão e as peças na área do golpe.",
                           "Cair de alto com força racha o chão onde pousa.",
                           "Golpe LEVE não quebra nada: lutar só no leve = destruir pouco (se segurar)."]):
        b.append(ec.T(x + 40, y + 345 + i * 28, "• " + t, 17, INK, "start", w=600))
    b.append('<defs><marker id="seta" markerWidth="10" markerHeight="10" refX="6" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 Z" fill="#2a1a2e"/></marker></defs>')
    n = ec.notes("COMBATE — refinamento (proposta; números PROVISÓRIOS para calibrar jogando)", [
        ("PROPOSTA", "Acertar: arco maior, ativo 0,10 s, avanço curto até o rival e aperto antecipado."),
        ("PROPOSTA", "Bate e segue: leve empurra mais, recupera rápido e cancela em pulo/esquiva."),
        ("PROPOSTA", "Pesado: segurar carrega (até 1 s), armadura contra o leve, 4 direções, ponta = crítico."),
        ("PROPOSTA", "A obra quebra com a luta (arremesso na parede, crítico, pouso forte); o leve não quebra."),
        ("DECIDIR", "Pesado com 4 direções (como Brawlhalla) ou 1 só, mais forte e carregável?"),
        ("DECIDIR", "Golpe leve não quebrar nada (para dar o controle de destruir menos): sim?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, ec.rough(seed=31, scale=0.5, freq=0.05) if hasattr(ec, "rough") else "")


def main():
    os.makedirs(OUT, exist_ok=True)
    import json, subprocess, tempfile
    from PIL import Image
    tmp = tempfile.mkdtemp(prefix="combate_")
    p = os.path.join(tmp, "r2.svg")
    open(p, "w").write(tela())
    png = os.path.join(OUT, "r2_combate.png")
    jp = os.path.join(tmp, "jobs.json")
    json.dump([{"svg": p, "png": png, "w": W, "h": H + ec.NOTES_H, "scale": 1}], open(jp, "w"))
    subprocess.run(["node", os.path.join(ec.ROOT, "tools/render_svg.js"), jp], check=True)
    Image.open(png).convert("RGB").save(png, optimize=True)
    print(png)


if __name__ == "__main__":
    main()
