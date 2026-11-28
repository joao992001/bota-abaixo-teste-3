"""PLATAFORMAS NO TEMA DO MAR — Cena 1 (Cargueiro no Alto-Mar), mesma composição, contexto visual de NAVIO.
Pedido do usuário (2026-11-28): "a composição até tá boa, mas o contexto visual não tá se encaixando com o tema".
Troca o vocabulário de OBRA (andaime laranja, tábua com braçadeira, pilar de concreto com pneus, viga içada) pelo de NAVIO:
  andaime  → MASTRO DE CARGA (coluna de aço branca, faixa vermelha, rebites, escada de marinheiro, boia salva-vidas)
  tábua    → PASSARELA DE AÇO (chapa xadrez cinza-azulada, borda amarela de segurança, longarina com rebites, cantoneiras)
  pilar    → BOIA-TORRE de sinalização (listras vermelho/branco, convés de aço com cabeços e defensas de corda)
  escoras  → montantes de aço com rebites; mão-francesa → console de aço
  viga     → BOTE SALVA-VIDAS pendurado nos cabos (topo plano = plataforma)
As funções desenham em coordenadas da CENA (px), nos mesmos lugares das peças/tiles de hoje.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_plataformas.py → art/out/fase2/plataformas_cena1.png
"""
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
from f2_prancha import R, E, PL, T, W, H, INK, YEL, CONT, zebra, conteiner, robot, sign  # noqa: E402
import elenco as el  # noqa: E402
from papel import rough  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
MAR1 = fp.MAR1

ACO, ACO_D, ACO_L = "#6d7d91", "#4b5869", "#97a6b8"      # aço do navio (cinza-azulado)
BRANCO, BRANCO_D = "#ece6da", "#c9c1b1"                  # tinta branca de navio
VERM, VERM_D = "#c8413a", "#962c27"
LARANJA, LARANJA_D = "#f08a3d", "#c0662a"
CORDA, CORDA_D = "#d9b77a", "#a8854a"


def rebites(x0, y, x1, passo=22, r=2.4, cor=None):
    cor = cor or ACO_D
    return "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{cor}"/>' for x in range(int(x0), int(x1), passo))


def ferrugem(x, y, n, alt, seed, larg=6):
    rnd = random.Random(seed)
    o = ""
    for _ in range(n):
        xx = x + rnd.uniform(-larg, larg)
        o += f'<path d="M{xx:.1f},{y} q2,{alt * 0.4:.0f} -1,{alt * rnd.uniform(0.5, 1.0):.0f}" stroke="#a5523d" stroke-width="{rnd.uniform(2, 4):.1f}" fill="none" opacity="0.55"/>'
    return o


def mastro(x, y_top, y_bot, niveis=(6 * T, 9 * T), seed=1):
    """MASTRO DE CARGA (fixo, no lugar do andaime de 64 px): coluna de aço branca, capitel vermelho, cruzetas onde as
    passarelas encostam, escada de marinheiro do lado, rebites, ferrugem escorrendo e uma boia salva-vidas."""
    cx = x + 32
    o = R(cx - 20, y_top, 40, y_bot - y_top, BRANCO, 3, 1.4, dark=BRANCO_D)
    o += f'<rect x="{cx - 20}" y="{y_top}" width="9" height="{y_bot - y_top}" fill="{BRANCO_D}" opacity="0.7"/>'
    o += R(cx - 24, y_top - 6, 48, 30, VERM, 3, 1.0, dark=VERM_D)                      # capitel vermelho
    o += R(cx - 28, y_top - 14, 56, 10, ACO_D, 2, 0.8)
    for yy in range(int(y_top) + 40, int(y_bot) - 10, 64):                            # costuras com rebites
        o += f'<path d="M{cx - 20},{yy} h40" stroke="{BRANCO_D}" stroke-width="3"/>' + rebites(cx - 14, yy + 6, cx + 16, 10, 1.8, "#a59c8a")
    for yv in niveis:                                                                  # cruzetas de apoio
        if y_top < yv < y_bot:
            o += R(cx - 34, yv + 24, 68, 12, ACO, 2, 0.8, dark=ACO_D) + rebites(cx - 28, yv + 30, cx + 32, 12, 1.8)
    lx = cx + 24                                                                       # escada de marinheiro
    o += f'<path d="M{lx},{y_top + 30} V{y_bot} M{lx + 16},{y_top + 30} V{y_bot}" stroke="{YEL}" stroke-width="4"/>'
    for yy in range(int(y_top) + 44, int(y_bot), 22):
        o += f'<path d="M{lx},{yy} h16" stroke="#c49a2a" stroke-width="3"/>'
    o += ferrugem(cx - 6, y_top + 60, 4, 120, seed) + ferrugem(cx + 4, (y_top + y_bot) / 2, 3, 90, seed + 7)
    by = (y_top + y_bot) / 2 + 40
    o += f'<path d="M{cx - 4},{by - 40} L{cx - 4},{by - 26}" stroke="{INK}" stroke-width="3"/>' + boia(cx - 4, by, 24)
    return o


def boia(cx, cy, r=24):
    import math
    o = E(cx, cy, r, r, LARANJA, 1.0, dark=LARANJA_D)
    for a0 in (45, 135, 225, 315):
        a = math.radians(a0)
        o += f'<path d="M{cx + math.cos(a) * r * 0.55:.1f},{cy + math.sin(a) * r * 0.55:.1f} L{cx + math.cos(a) * r * 1.02:.1f},{cy + math.sin(a) * r * 1.02:.1f}" stroke="{BRANCO}" stroke-width="12"/>'
    o += E(cx, cy, r * 0.48, r * 0.48, "#9a4a38", 0.5)
    o += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.76:.1f}" fill="none" stroke="{CORDA_D}" stroke-width="2.5" stroke-dasharray="7 5"/>'
    return o


def passarela(x, y, w, seed=1):
    """PASSARELA DE AÇO (QUEBRA; mesmo retângulo da tábua: 28 px): chapa xadrez, borda amarela, longarina com rebites e
    cantoneiras parafusadas nas pontas."""
    o = R(x, y, w, 12, ACO, 2, 1.2, dark=ACO_D)                                        # chapa de piso
    o += f'<rect x="{x}" y="{y}" width="{w}" height="4" fill="{YEL}"/>'                # borda de segurança
    for i in range(int(w / 14)):                                                       # chapa xadrez (losangos)
        xx = x + 7 + i * 14
        o += f'<path d="M{xx},{y + 6 + (i % 2) * 2} l5,-2" stroke="{ACO_L}" stroke-width="2"/>'
    o += R(x + 6, y + 12, w - 12, 16, ACO_D, 2, 1.0, dark="#38424f")                  # longarina
    o += rebites(x + 16, y + 20, x + w - 10, 26, 2.4, "#2f3843")
    rnd = random.Random(seed)
    for _ in range(max(1, int(w / 180))):                                              # marcas de ferrugem
        xx = rnd.uniform(x + 30, x + w - 30)
        o += f'<path d="M{xx},{y + 28} q1,10 -2,{rnd.uniform(10, 22):.0f}" stroke="#a5523d" stroke-width="3" fill="none" opacity="0.6"/>'
    for xx, s in ((x - 2, 1), (x + w - 16, -1)):                                       # cantoneiras
        o += R(xx, y - 4, 18, 36, ACO_L, 2, 0.8, dark=ACO) + f'<circle cx="{xx + 9}" cy="{y + 8}" r="3" fill="{ACO_D}"/><circle cx="{xx + 9}" cy="{y + 22}" r="3" fill="{ACO_D}"/>'
    return o


def montante(x, y0, y1):
    """Escora de aço com rebites (no lugar da escora laranja)."""
    return R(x, y0, 14, y1 - y0, ACO, 2, 0.8, dark=ACO_D) + rebites(x + 7, y0 + 12, x + 8, 1, 2.0) + "".join(
        f'<circle cx="{x + 7}" cy="{yy}" r="2" fill="{ACO_D}"/>' for yy in range(int(y0) + 12, int(y1), 18))


def console(x0, y0, x1, y1):
    """Mão-francesa de aço (triângulo vazado) presa no mastro."""
    return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{ACO_D}" stroke-width="12" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{ACO}" stroke-width="6" stroke-linecap="round"/>')


def boia_torre(x0, x1, topo):
    """BOIA-TORRE de sinalização (fixa, no lugar do pilar de concreto): coluna listrada, convés de aço com borda amarela,
    defensas de corda, lanterna verde no braço e o casco boiando (anel escuro na linha d'água)."""
    cx = (x0 + x1) / 2
    cw = 2 * T
    o = ""
    o += E(cx, MAR1 + 6, cw * 0.75, 18, "#2f3a48", 1.0)                                 # flutuador (sai da água)
    faixa = 46
    y = topo + 28
    i = 0
    while y < MAR1:
        hh = min(faixa, MAR1 - y)
        o += R(cx - cw / 2, y, cw, hh, VERM if i % 2 == 0 else BRANCO, 0, 1.0, dark=VERM_D if i % 2 == 0 else BRANCO_D)
        y += faixa
        i += 1
    o += f'<rect x="{cx - cw / 2}" y="{topo + 28}" width="16" height="{MAR1 - topo - 28}" fill="#000" opacity="0.12"/>'
    o += ferrugem(cx + 20, topo + 40, 4, 110, 21, 30)
    o += R(x0, topo, x1 - x0, 28, ACO, 3, 1.4, dark=ACO_D) + zebra(x0, topo - 8, x1 - x0, 8)   # convés da boia
    o += rebites(x0 + 14, topo + 20, x1 - 8, 24, 2.4, "#2f3843")
    for k in range(3):                                                                  # defensas de corda
        fx = x0 + 34 + k * ((x1 - x0 - 68) / 2)
        o += E(fx, topo + 44, 14, 18, CORDA, 0.8, dark=CORDA_D) + f'<path d="M{fx - 10},{topo + 36} h20 M{fx - 10},{topo + 46} h20 M{fx - 10},{topo + 56} h20" stroke="{CORDA_D}" stroke-width="2"/>'
    ax = x1 - 6                                                                         # braço com lanterna
    o += f'<path d="M{cx + cw / 2},{topo + 90} L{ax + 26},{topo + 90} V{topo + 60}" stroke="{ACO_D}" stroke-width="6" fill="none"/>'
    o += R(ax + 16, topo + 38, 20, 24, "#3fbf6a", 3, 0.6) + f'<circle cx="{ax + 26}" cy="{topo + 50}" r="20" fill="#bff7cf" opacity="0.35"/>'
    o += R(ax + 14, topo + 32, 24, 7, ACO_D, 2, 0.4)
    return o


def bote(x0, x1, y_topo, y_cabo):
    """BOTE SALVA-VIDAS pendurado (QUEBRA; no lugar da viga): casco laranja, faixa branca, cobertura plana (é onde se
    pisa), alças de corda e dois cabos com moitão até a lança."""
    w = x1 - x0
    o = (f'<path d="M{x0 + 20},{y_cabo} V{y_topo} M{x1 - 20},{y_cabo} V{y_topo}" stroke="{INK}" stroke-width="3"/>'
         + R(x0 + 12, y_topo - 26, 16, 20, "#8a909c", 3, 0.6) + R(x1 - 28, y_topo - 26, 16, 20, "#8a909c", 3, 0.6))
    o += R(x0 + 6, y_topo, w - 12, 12, BRANCO, 4, 1.0, dark=BRANCO_D)                    # cobertura (topo plano)
    casco = f"M{x0},{y_topo + 10} L{x1},{y_topo + 10} C{x1 - 10},{y_topo + 44} {x1 - 40},{y_topo + 54} {x1 - 80},{y_topo + 54} L{x0 + 80},{y_topo + 54} C{x0 + 40},{y_topo + 54} {x0 + 10},{y_topo + 44} {x0},{y_topo + 10} Z"
    o += fp.S(casco, LARANJA, (x0, y_topo + 8, x1, y_topo + 56), k=1.4, dark=LARANJA_D)
    o += f'<rect x="{x0 + 6}" y="{y_topo + 14}" width="{w - 12}" height="6" fill="{BRANCO}"/>'
    for k in range(int((w - 60) / 46)):                                                 # alças de corda
        ax = x0 + 40 + k * 46
        o += f'<path d="M{ax},{y_topo + 24} q23,14 46,0" stroke="{CORDA_D}" stroke-width="3" fill="none"/>'
    o += f'<text x="{(x0 + x1) / 2}" y="{y_topo + 44}" font-family="Fredoka" font-weight="700" font-size="15" fill="{BRANCO}" text-anchor="middle">E. DO SUL · 2</text>'
    return o


# ---------------------------------------------------------------- palco e peças da cena 1 (mesma composição de hoje)
def e1_palco_mar():
    o = fp.balsa(70, 6 * T) + fp.balsa(22 * T, 7 * T)
    o += boia_torre(13 * T - 10, 17 * T + 10, 11 * T)
    o += mastro(7 * T, 4 * T, 13 * T, seed=3) + mastro(21 * T, 4 * T, 13 * T, seed=5)
    o += R(28 * T, 1 * T, 26, 12 * T, "#e0a83a", 3, 1.6, dark="#b07a1e")              # torre da grua da balsa (já é do navio)
    for k in range(11):
        y = T + 20 + k * 64
        o += f'<path d="M{28 * T},{y} l26,40 M{28 * T + 26},{y} l-26,40" stroke="#b07a1e" stroke-width="3"/>'
    o += R(9 * T, 1 * T - 14, 20 * T, 20, "#e0a83a", 3, 1.4) + R(28 * T - 30, 1 * T - 60, 80, 46, "#cfd3da", 3, 1.2)
    o += sign(23 * T, 13 * T - 60, "BOTA-ABAIXO", 170)
    o += montante(13 * T, 9 * T + 24, 11 * T - 8) + montante(17 * T - 14, 9 * T + 24, 11 * T - 8)
    o += console(7 * T + 12, 6 * T + 130, 5 * T + 24, 6 * T + 26)
    return o


def pecas_mar():
    return {
        "p1_andaime_0": passarela(8 * T - 6, 9 * T - 4, 5 * T + 12, 1),
        "p1_andaime_1": passarela(17 * T - 6, 9 * T - 4, 4 * T + 12, 2),
        "p1_andaime_2": passarela(5 * T - 6, 6 * T - 4, 3 * T + 12, 3),
        "p1_andaime_3": passarela(22 * T - 6, 6 * T - 4, 6 * T + 12, 4),
        "p1_viga_0": bote(20 * T - 10, 25 * T + 10, 3 * T, 1 * T + 6),
    }


def conteineres():
    o = ""
    cores = [0, 1, 2, 3, 4, 5, 6]
    for i, (cx, cy, cw, chh) in enumerate([[1, 11, 3, 1], [1, 12, 3, 1], [4, 12, 3, 1], [13, 10, 3, 1], [22, 12, 3, 1], [25, 11, 3, 1], [25, 12, 3, 1]]):
        o += conteiner(cx * T, cy * T, cw * T, chh * T, CONT[cores[i] % 7])
    return o


def cena_depois():
    defs = fp.fonte() + rough(seed=31, scale=0.8, freq=0.05) + fp.grad("c1ceu", [(0, "#f7b27a"), (0.45, "#e8988a"), (1, "#6f6aa0")])
    body = fp.c1_ceu() + fp.c1_longe() + fp.c1_navio_fundo() + e1_palco_mar() + "".join(pecas_mar().values()) + conteineres()
    body += robot("marretao", "parado", el.COLORS[0], 2 * T + 40, 11 * T, s=0.62)
    body += robot("picareta", "parado", el.COLORS[1], 10 * T + 20, 9 * T - 4, s=0.62, flip=True)
    body += robot("chave", "parado", el.COLORS[2], 23 * T, 6 * T - 4, s=0.62)
    body += robot("britadeira", "parado", el.COLORS[3], 22 * T + 30, 3 * T, s=0.62, flip=True)
    body += fp.ondas_frente(MAR1, "#2f6f9f", "#9fd0ec", 16, 2)
    return doc(W, H, f'<g filter="url(#rough)">{body}</g>', defs)


def main():
    os.makedirs(OUT, exist_ok=True)
    png = os.path.join(OUT, "plataformas_cena1_depois.png")
    queue(cena_depois(), os.path.join(HERE, "svg/fase2/plataformas_cena1_depois.svg"), png, W, H, 1)
    print(render_all(), png)


if __name__ == "__main__":
    main()


def prancha():
    """Antes (captura do jogo) × depois (mesma composição no tema) + detalhes ampliados lado a lado."""
    from PIL import Image, ImageDraw, ImageFont
    fb = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    f_t, f_s = ImageFont.truetype(fb, 40), ImageFont.truetype(fb, 24)
    antes = Image.open(os.path.join(OUT, "uso/cena1_jogo_antes.png")).convert("RGB")
    depois = Image.open(os.path.join(OUT, "plataformas_cena1_depois.png")).convert("RGB")
    PW = 1920
    pw, ph = 940, 529
    det = [("ANDAIME laranja → MASTRO DE CARGA", (400, 230, 600, 860)),
           ("TÁBUA → PASSARELA DE AÇO", (300, 360, 860, 640)),
           ("PILAR de concreto → BOIA-TORRE", (780, 620, 1160, 970)),
           ("VIGA içada → BOTE SALVA-VIDAS", (1240, 40, 1660, 280))]
    dh = 360
    img = Image.new("RGB", (PW, 110 + ph + 70 + len(det) * (dh + 60) + 20), "#2a1a2e")
    d = ImageDraw.Draw(img)
    d.text((PW / 2, 50), "PLATAFORMAS NO TEMA DO MAR · Cena 1 Alto-Mar (mesma composição)", font=f_t, fill="white", anchor="mm")
    for i, (im, tit) in enumerate([(antes, "ANTES (no jogo hoje): vocabulário de OBRA"), (depois, "DEPOIS: vocabulário de NAVIO")]):
        x = 13 + i * (pw + 14)
        img.paste(im.resize((pw, ph)), (x, 100))
        d.text((x + pw / 2, 100 + ph + 30), tit, font=f_s, fill="white", anchor="mm")
    y = 100 + ph + 70
    for tit, (x0, y0, x1, y1) in det:
        d.text((PW / 2, y + 18), tit, font=f_s, fill="#f2c84b", anchor="mm")
        for i, im in enumerate((antes, depois)):
            c = im.crop((x0, y0, x1, y1))
            s = min((pw) / c.width, dh / c.height)
            c = c.resize((int(c.width * s), int(c.height * s)))
            x = 13 + i * (pw + 14) + (pw - c.width) // 2
            img.paste(c, (x, y + 40))
        y += dh + 60
    png = os.path.join(OUT, "plataformas_cena1.png")
    img.save(png)
    print(png)


if __name__ == "__main__" and "--prancha" in sys.argv:
    prancha()
