"""PRANCHA — COMBATE (etapa 2 da avaliação de gameplay, itens 7, 8 e 10; refeita com o elenco A27, 2026-11-27).
Pedido do usuário: golpe pesado não é fluido e falta vontade de usar; golpe leve sem prazer; a destruição tem de vir da
LUTA (arremesso, crítico, pouso forte) e o jogador deve poder "se segurar" e destruir menos.
Referências de JOGO (só a mecânica): Smash (carregar o golpe forte, congelamento maior quanto mais forte) e Brawlhalla
(pesados direcionais que mandam longe).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/combate_r3.py → art/out/robos_v2/combate_r3.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
from eng_ataques import (marretao, rival, laje, pedra, poeira, linhas_vel, anel, estrela, painel, nota, R, ab, label,  # noqa: E402
                         INK, TILE, CONC, CONC_D, queue, render_all)

AMAR = "#ffd23a"


def arco(cx, cy, r, a0, a1, w=14, op=0.6, cor="#ffffff"):
    x0, y0 = cx + math.cos(math.radians(a0)) * r, cy + math.sin(math.radians(a0)) * r
    x1, y1 = cx + math.cos(math.radians(a1)) * r, cy + math.sin(math.radians(a1)) * r
    large = 1 if abs(a1 - a0) > 180 else 0
    return f'<path d="M{x0:.1f},{y0:.1f} A{r},{r} 0 {large} 1 {x1:.1f},{y1:.1f}" stroke="{cor}" stroke-width="{w}" fill="none" opacity="{op}" stroke-linecap="round"/>'


def seta(x0, y0, x1, y1, cor="#d42035", w=4):
    a = math.atan2(y1 - y0, x1 - x0)
    h = [(x1, y1), (x1 - math.cos(a - 0.5) * 12, y1 - math.sin(a - 0.5) * 12), (x1 - math.cos(a + 0.5) * 12, y1 - math.sin(a + 0.5) * 12)]
    return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{cor}" stroke-width="{w}" stroke-linecap="round"/>'
            + f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in h)}" fill="{cor}"/>')


def barra(x, y, k, cor="#ff9a3a"):
    return R(x - 20, y, 40, 8, 3, "#2e323b", k=0.1) + R(x - 18, y + 1.5, 36 * k, 5, 2, cor, k=0.1)


def parede(x, y0=0, n=4, rach=False):
    o = ""
    for j in range(n):
        o += R(x, y0 - TILE * 0.55 * (j + 1), TILE, TILE * 0.55, 3, CONC if j % 2 else CONC_D, k=0.5)
    if rach:
        o += f'<path d="M{x + 4},{y0 - 70} l12,10 l-8,12 l14,10 l-6,14" stroke="#4a3a2e" stroke-width="3" fill="none"/>'
    return o


# ---------------------------------------------------------------- poses (Marretão)
P_BASE = dict(hip=(0, -24), lean=4, head=2, feet=[(-9, 0), (9, 0)], tool=(9, -34, -150), face="foco")


def pz(**k):
    d = dict(P_BASE)
    d.update(k)
    return d


def leve():
    ps = []
    c = laje(-110, 250) + rival(118, 0)
    c += marretao(pz(lean=14, feet=[(-12, 0), (14, 0)], tool=(20, -30, 10), face="raiva"), x=10)
    c += arco(30, -40, 70, -80, 40) + seta(-20, 6, 30, 6, "#4f86d9", 3)
    c += nota(-205, "aperto: AVANÇO curto até o rival", "arco maior · aperta antes e o golpe sai")
    ps.append(("1 · ALCANÇA — avança e arqueia", c))
    c = laje(-110, 250) + rival(110, 0, sq=(1.08, 0.92))
    c += marretao(pz(lean=18, feet=[(-14, 0), (16, 0)], tool=(22, -26, 20), face="raiva"), x=14)
    c += estrela(94, -38, 18) + anel(94, -38, 24, 24, 3) + linhas_vel(140, -40, 3, 22, 1)
    c += nota(-205, "acertou: tranco curto (congela 0,04 s)", "faísca + rival EMPURRADO de leve")
    ps.append(("2 · ACERTA — tranco e empurra", c))
    c = laje(-110, 250) + rival(150, -20, rot=-40, sq=(1, 0.9)) + linhas_vel(180, -30, 4, 30, 1)
    c += marretao(pz(lean=26, head=-6, feet=[(-16, 0), (18, 0)], tool=(26, -20, 40), face="raiva"), x=40)
    c += label(60, -150, "1 · 2 · 3!", 20, INK) + arco(70, -36, 60, -100, 60, 18, 0.7, AMAR)
    c += nota(-205, "3 golpes seguidos: o 3º é uma MARRETADA", "que LANÇA (o leve vira combo)")
    ps.append(("3 · COMBO — o 3º lança", c))
    c = laje(-110, 250) + rival(140, 0)
    c += f'<g opacity="0.35">{marretao(pz(lean=16, tool=(20, -28, 10)), x=0)}</g>'
    c += marretao(pz(lean=-6, feet=[(-12, -26), (10, -30)], tool=(8, -40, -120), face="foco"), x=-20, y=-40)
    c += seta(0, -20, -20, -60, "#4f86d9", 3)
    c += nota(-205, "recupera rápido e CANCELA em pulo/esquiva", "bate e segue se mexendo (nada fica parado)")
    ps.append(("4 · SEGUE — cancela no pulo", c))
    return ps


def pesado():
    ps = []
    c = laje(-110, 250) + rival(140, 0)
    c += marretao(pz(lean=-22, head=12, feet=[(-14, 0), (10, 0)], tool=(-4, -50, -120), face="raiva", sq=(1.06, 0.88)), marreta_giga=1.2)
    c += f'<circle cx="-30" cy="-90" r="26" fill="#ffb24a" opacity="0.45"/>' + barra(0, -130, 0.7)
    c += "".join(f'<path d="M{-40 + i * 16},-4 l-4,-8" stroke="#ffffff" stroke-width="2.4"/>' for i in range(4))
    c += nota(-205, "SEGURA = carrega (até 1 s): treme, brilha", "não é interrompido pelo golpe leve (armadura)")
    ps.append(("1 · CARREGA — segura", c))
    c = laje(-110, 250)
    c += marretao(pz(lean=10, tool=(14, -40, -60), face="raiva"), x=-20)
    for (x1, y1, t) in ((150, -40, "◄►  lança longe"), (40, -170, "▲  joga para cima"), (60, 10, "▼ no ar: crava")):
        c += seta(10, -50, x1, y1, AMAR, 6) + label(x1 + (0 if x1 < 100 else -10), y1 - 10, t, 13, INK)
    c += nota(-205, "4 DIREÇÕES (◄ ► ▲ ▼)", "cada uma com seu golpe")
    ps.append(("2 · DIREÇÃO — escolhe para onde", c))
    c = laje(-110, 250)
    c += marretao(pz(lean=30, head=-8, feet=[(-16, 0), (18, 0)], tool=(26, -24, 30), face="raiva"), x=-10, marreta_giga=1.2)
    c += arco(20, -40, 90, -110, 50, 26, 0.6, AMAR) + estrela(110, -40, 40, "#fff3b0") + anel(110, -40, 50, 50, 6)
    c += rival(170, -100, rot=-70, sq=(1, 0.9)) + linhas_vel(196, -90, 4, 30, 1)
    c += label(110, -100, "CRÍTICO!", 18, "#d42035")
    c += nota(-205, "acertou com a PONTA da marreta = CRÍTICO", "congela mais, voa muito longe")
    ps.append(("3 · PONTA — crítico", c))
    c = laje(-110, 250) + rival(120, 0)
    c += f'<g opacity="0.4">{marretao(pz(lean=30, tool=(26, -24, 30), face="raiva"), x=-10)}</g>'
    c += marretao(pz(lean=-8, head=6, feet=[(-16, 0), (6, 0)], tool=(12, -40, -110), face="susto"), x=-34)
    c += label(-20, -140, "errou: fica exposto", 14, "#d42035")
    c += nota(-205, "risco: se errar, recupera DEVAGAR", "acertou: recupera rápido e segue")
    ps.append(("4 · RISCO — errou, fica exposto", c))
    return ps


def destruicao():
    ps = []
    c = laje(-110, 250) + parede(170, rach=True)
    c += rival(160, -50, rot=60, sq=(0.85, 1.05)) + estrela(170, -50, 26)
    for i in range(6):
        c += pedra(176 - i * 6, -80 + i * 14, 1.1, i * 50)
    c += marretao(pz(lean=20, tool=(22, -26, 20), face="raiva"), x=-30)
    c += nota(-205, "ARREMESSADO contra parede/bloco: RACHA", "quanto mais forte o voo, mais quebra")
    ps.append(("1 · ARREMESSO — racha a parede", c))
    c = laje(-110, 250, buraco=(80, 150))
    for i in range(10):
        c += pedra(90 + (i * 13) % 56, -20 - (i * 23) % 80, 1.1, i * 40)
    c += marretao(pz(lean=30, head=-8, feet=[(-16, 0), (18, 0)], tool=(26, -14, 60), face="raiva"), x=10, marreta_giga=1.2)
    c += label(115, -110, "CRÍTICO!", 18, "#d42035")
    c += nota(-205, "pesado CRÍTICO / carregado: quebra a peça", "que ele acerta (laje, tábua, bloco)")
    ps.append(("2 · CRÍTICO — quebra a peça", c))
    c = laje(-110, 250, rachar=(40, 120)) if "rachar" in laje.__code__.co_varnames else laje(-110, 250)
    c += f'<path d="M60,2 l10,10 l-6,8 l12,8" stroke="#4a3a2e" stroke-width="3" fill="none"/>'
    c += rival(80, 0, sq=(1.2, 0.8)) + poeira(80, 0, 8, 7, 40) + anel(80, 0, 60, 12, 5)
    c += seta(80, -170, 80, -70, AMAR, 5) + marretao(P_BASE, x=-40)
    c += nota(-205, "POUSO forte (caiu de alto/arremessado)", "racha o chão onde cai")
    ps.append(("3 · POUSO — racha o chão", c))
    c = laje(-110, 250) + rival(110, 0, sq=(1.06, 0.94)) + estrela(94, -38, 14)
    c += marretao(pz(lean=14, feet=[(-12, 0), (14, 0)], tool=(20, -30, 10), face="foco"), x=14)
    c += label(70, -130, "leve: NÃO quebra", 15, "#2a7a3a")
    c += nota(-205, "quem quer destruir MENOS luta no leve", "(controla para onde a obra vai)")
    ps.append(("4 · CONTROLE — o leve não quebra", c))
    return ps


def prancha():
    W, H = 1920, 1820
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>',
         label(W / 2, 50, "COMBATE — golpe leve, golpe pesado e a obra quebrando com a LUTA (proposta)", 32)]
    pw, ph = 452, 430
    linhas = [("GOLPE LEVE — acertar é fácil e dá prazer", "alcança, acerta com tranco, combo de 3 que lança, cancela no pulo/esquiva", leve()),
              ("GOLPE PESADO — vontade de usar", "segurar carrega (até 1 s, armadura contra o leve), 4 direções, ponta = crítico; errou = exposto", pesado()),
              ("DESTRUIÇÃO PELA LUTA", "arremesso racha parede, crítico quebra a peça, pouso forte racha o chão; o leve não quebra (controle)", destruicao())]
    for r, (tit, sub, ps) in enumerate(linhas):
        y0 = 80 + r * (ph + 100)
        b.append(f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{tit}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        for j, (t, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 74, pw, ph, t, c, s=1.5))
    yd = 80 + 3 * (ph + 100) + 10
    b.append(f'<rect x="20" y="{yd}" width="{W - 40}" height="120" rx="18" fill="#fff3c4"/>')
    b.append(label(40, yd + 34, "DECIDIR:", 22, "#d42035", "start"))
    b.append(label(40, yd + 68, "1) Golpe pesado com 4 DIREÇÕES (◄► ▲ ▼, como no painel 2)  ou  1 direção só, mais forte e carregável?", 19, INK, "start", 600))
    b.append(label(40, yd + 100, "2) Golpe LEVE não quebra nada (dá o controle de destruir menos) — sim ou não?", 19, INK, "start", 600))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/combate_r3.png")
    queue(svg, os.path.join(HERE, "svg/combate_r3.svg"), out, W, H, 1)
    print(render_all(), out)


if __name__ == "__main__":
    prancha()
