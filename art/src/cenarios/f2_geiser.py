"""PRANCHA — M11 GÊISER (Cargueiro Perdido, cena 2b Atlântida; ideia do usuário 2026-11-28). Nas fendas entre os pilares
(onde se cai = KO), de tempos em tempos o fundo BORBULHA (aviso) e JORRA um jato: quem cai ali é jogado de volta para cima
(não cai); quem está no jato sobe (elevador para as lajes altas). Sem dano.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_geiser.py → art/out/fase2/perigo_geiser.png
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
from f2_prancha import R, E, PL, robot, INK  # noqa: E402
import f2_tubarao as ft  # noqa: E402
import elenco as el  # noqa: E402
from papel import rough  # noqa: E402
from svg import queue, render_all  # noqa: E402

OUT = ft.OUT
FW, FH = ft.FW, ft.FH
Tt, quadro = ft.Tt, ft.quadro
MARM, MARM_D, OURO = fp.MARM, fp.MARM_D, fp.OURO
FENDA_X0, FENDA_X1 = 170, 390     # a fenda entre dois pilares
TOPO = 200                        # topo dos pilares


def cena_base():
    o = f'<rect width="{FW}" height="{FH}" fill="#2a8fa8"/>'
    o += f'<rect x="0" y="0" width="{FW}" height="{FH}" fill="#5fd0d8" opacity="0.35"/>'
    for x0, x1 in ((0, FENDA_X0), (FENDA_X1, FW)):   # dois pilares dourados (topo plano) e a fenda escura no meio
        o += PL([(x0 + 10, TOPO + 30), (x1 - 10, TOPO + 30), (x1 - 40, FH + 10), (x0 + 40, FH + 10)], "#3f5566", 1.6, dark="#2c3c4a")
        o += R(x0, TOPO, x1 - x0, 34, MARM_D, 3, 1.2) + R(x0, TOPO + 22, x1 - x0, 8, OURO, 2, 0.6) + R(x0 + 8, TOPO - 10, x1 - x0 - 16, 12, MARM, 3, 0.8)
    o += f'<rect x="{FENDA_X0 + 30}" y="{TOPO + 40}" width="{FENDA_X1 - FENDA_X0 - 60}" height="{FH}" fill="#0a2a40"/>'
    o += Tt((FENDA_X0 + FENDA_X1) / 2, FH - 16, "FENDA = KO", 16, "#ffffff")
    return o


def bolhas(cx, y0, y1, n, r0=5, seed=1):
    import random
    rnd = random.Random(seed)
    o = ""
    for _ in range(n):
        x = cx + rnd.uniform(-60, 60)
        y = rnd.uniform(y1, y0)
        r = rnd.uniform(r0, r0 + 6)
        o += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.85"/>'
    return o


def jato(cx, topo, larg=110):
    """Coluna de água subindo da fenda (corpo claro, borda branca, espuma em cima)."""
    o = f'<path d="M{cx - larg / 2},{FH} C{cx - larg / 2 + 10},{topo + 120} {cx - larg / 3},{topo + 40} {cx - 30},{topo} L{cx + 30},{topo} C{cx + larg / 3},{topo + 40} {cx + larg / 2 - 10},{topo + 120} {cx + larg / 2},{FH} Z" fill="#bff0fa" opacity="0.85"/>'
    o += f'<path d="M{cx - 18},{FH} C{cx - 14},{topo + 140} {cx - 8},{topo + 60} {cx},{topo + 10}" stroke="#ffffff" stroke-width="6" fill="none" opacity="0.9"/>'
    for k in range(7):   # espuma no topo do jato
        o += E(cx - 48 + k * 16, topo + (k % 2) * 8, 16, 12, "#ffffff", 0.6)
    for k in range(5):   # gotas caindo dos lados
        o += f'<circle cx="{cx - 70 + k * 35}" cy="{topo + 30 + (k % 3) * 22}" r="6" fill="#ffffff" opacity="0.9"/>'
    return o


def prancha():
    PW, PH = 1920, 640
    b = []
    cx = (FENDA_X0 + FENDA_X1) / 2
    # 1 · aviso: o fundo da fenda borbulha e brilha (1,5 s)
    c1 = cena_base() + f'<ellipse cx="{cx}" cy="{FH - 10}" rx="90" ry="40" fill="#bff0fa" opacity="0.35"/>' + bolhas(cx, FH, TOPO + 40, 18, seed=3)
    c1 += f'<path d="M{cx - 50},{TOPO + 20} l0,-30 l-14,14 M{cx - 50},{TOPO - 10} l14,14 M{cx + 50},{TOPO + 20} l0,-30 l-14,14 M{cx + 50},{TOPO - 10} l14,14" stroke="#ffffff" stroke-width="5" fill="none"/>'
    c1 += robot("chave", "parado", el.COLORS[2], 470, TOPO - 2, s=0.62) + Tt(cx, 70, "blub... blub...", 22, "#ffffff")
    b.append(quadro(40, 110, c1, "1 · BORBULHA (1,5 s)", ["o fundo da fenda borbulha e brilha:", "o gêiser vai jorrar AQUI"]))
    # 2 · jorro: quem caiu na fenda é jogado para cima (não cai)
    c2 = cena_base() + jato(cx, 40) + robot("marretao", "esquiva", el.COLORS[0], cx, 70, s=0.62, rot=-12)
    c2 += f'<path d="M{cx + 70},150 v-60 l-12,14 M{cx + 70},90 l12,14" stroke="#ffffff" stroke-width="5" fill="none"/>' + Tt(cx + 150, 60, "salvo!", 24, "#f2c84b")
    b.append(quadro(680, 110, c2, "2 · JORRA (~2,5 s)", ["quem estava caindo é jogado de volta", "para cima: NÃO cai (sem dano)"]))
    # 3 · elevador: entrar no jato de propósito leva até a laje alta
    c3 = cena_base() + jato(cx, 20) + R(60, 60, 200, 26, MARM, 3, 1.0) + R(60, 78, 200, 8, OURO, 2, 0.5)
    c3 += robot("picareta", "parado", el.COLORS[1], 140, 58, s=0.62) + robot("britadeira", "esquiva", el.COLORS[3], cx + 10, 130, s=0.62, rot=8)
    c3 += f'<path d="M{cx - 20},170 q-40,-60 -110,-100" stroke="#ffffff" stroke-width="4" fill="none" stroke-dasharray="8 8"/>'
    b.append(quadro(1320, 110, c3, "3 · ELEVADOR", ["pular no jato de propósito leva", "até as lajes altas (rota de fuga)"]))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH}" viewBox="0 0 {PW} {PH}"><defs>{fp.fonte()}{rough(seed=47, scale=0.6, freq=0.05)}</defs>'
           f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>' + Tt(PW / 2, 66, "M11 · GÊISER — Atlântida (Fenda Abissal)", 40, "#ffffff")
           + f'<g filter="url(#rough)">{"".join(b)}</g></svg>')
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/fase2/geiser.svg"), os.path.join(OUT, "perigo_geiser.png"), PW, PH, 1)
    print(render_all(), os.path.join(OUT, "perigo_geiser.png"))


if __name__ == "__main__":
    prancha()
