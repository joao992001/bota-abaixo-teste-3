"""PRANCHA — T07 vira MECHA "CORREDOR" (pedido do usuário 2026-11-27): o Minirrobô Veloz deixa de encolher e vira um mecha
no padrão A29 (humanoide pilotado, faixa na cor do jogador, ombreiras com espetos, fenda de olho vermelha, ~2× o robô,
SILHUETA PRÓPRIA) cujo atributo é CORRER MUITO RÁPIDO. Duas variantes de silhueta para escolher + habilidade, golpes,
atributos e cartucho (A35). Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/mecha_corredor.py → art/out/robos_v2/mecha_corredor.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import armaduras_conceito as ac  # noqa: E402
import mecha_cartucho as mc  # noqa: E402
from armaduras_conceito import R, E, S, P_, DARK, STEEL, STEEL_D, STEEL_L, ab, eu, label, INK, queue, render_all, shade  # noqa: E402

PERNA_ORIG = ac.perna_partes
CASCO = "#d9483b"      # vermelho de corrida (nenhum outro mecha usa)
NUCLEO = "#ffe14a"


# ---------------------------------------------------------------- pernas próprias (troca perna_partes do construtor)
def pernas_lamina(hx, hy, fx, casco, k=1.0):
    """VELOCISTA: perna digitígrada longa (coxa, canela para trás) terminando numa LÂMINA de corrida curva (mola de aço)."""
    kx, ky = (hx + fx) / 2 + 12 * k, hy + (0 - hy) * 0.42
    ax, ay = fx - 6, -22                                                   # tornozelo alto (digitígrado)
    coxa = f'<path d="M{hx},{hy} L{kx},{ky}" stroke="{DARK}" stroke-width="13" fill="none" stroke-linecap="round"/>'
    coxa += S(f"M{hx - 10},{hy - 5} L{hx + 10},{hy - 5} L{kx + 7},{ky} L{kx - 8},{ky + 2} Z", casco, (hx - 11, hy - 6, kx + 8, ky + 3), k=0.5)
    can = f'<path d="M{kx},{ky} L{ax},{ay}" stroke="{DARK}" stroke-width="11" fill="none" stroke-linecap="round"/>'
    can += S(f"M{kx - 7},{ky + 2} L{kx + 7},{ky + 2} L{ax + 6},{ay} L{ax - 6},{ay} Z", casco, (kx - 8, ky + 1, ax + 7, ay + 1), k=0.5)
    can += P_([(kx - 7, ky - 6), (kx + 9, ky - 3), (kx + 5, ky + 8), (kx - 6, ky + 5)], shade(casco, -0.25), k=0.3)
    pe = (f'<path d="M{ax},{ay} C{ax + 18},{ay + 2} {ax + 22},{-4} {ax + 6},0 L{ax - 10},0" stroke="{STEEL_D}" stroke-width="7" fill="none" stroke-linecap="round"/>'
          f'<path d="M{ax + 1},{ay + 1} C{ax + 16},{ay + 3} {ax + 19},{-4} {ax + 5},-1" stroke="{STEEL_L}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
          + R(ax - 12, -3, 16, 3, 1.5, "#2a2a30", k=0.1))                   # sola de borracha
    return coxa, can, pe, {"quadril": [hx, hy], "joelho": [kx, ky], "tornozelo": [ax, ay]}


def pernas_rodas(hx, hy, fx, casco, k=1.0):
    """PATINADOR: perna normal curta terminando num PATIM de 2 rodas grandes (desliza em vez de passada)."""
    co, ca, _, j = PERNA_ORIG(hx, hy, fx, casco, k)
    pe = R(fx - 18, -16, 40, 8, 4, DARK, k=0.4) + R(fx - 18, -16, 40, 3, 1.5, casco, k=0.2)
    for wx in (fx - 10, fx + 14):
        pe += E(wx, -7, 7, 7, "#2a2a30", k=0.3) + E(wx, -7, 3, 3, STEEL_L, k=0.1)
    return co, ca, pe, j


def _com_pernas(fn_pernas, desenho):
    orig = ac.perna_partes
    ac.perna_partes = fn_pernas
    try:
        return desenho()
    finally:
        ac.perna_partes = orig


def velocista(col):
    """A · VELOCISTA: inclinado para a frente, pernas-lâmina, aerofólio e 2 escapamentos nas costas, braço = aríete curto."""
    costas = R(-58, -150, 30, 6, 2, DARK, k=0.3) + P_([(-62, -158), (-26, -156), (-28, -150), (-60, -150)], CASCO, k=0.3)   # aerofólio
    costas += R(-52, -150, 4, 14, 1, DARK, k=0.2) + R(-36, -150, 4, 14, 1, DARK, k=0.2)
    for x in (-58, -46):   # escapamentos inclinados com chama
        costas += f'<g transform="rotate(-35 {x + 5} -110)">' + R(x, -126, 10, 30, 4, STEEL_D, k=0.3) + R(x - 1, -128, 12, 5, 2, DARK, k=0.2)
        if ac.ESTATICO[0]:
            costas += P_([(x + 1, -128), (x + 9, -128), (x + 5, -150)], "#ff8a2a", k=0.2) + P_([(x + 3, -128), (x + 7, -128), (x + 5, -140)], "#fff1b8", k=0.1)
        costas += "</g>"
    arma = f'<path d="M34,-106 L52,-96 L62,-98" stroke="{DARK}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += S("M58,-110 L84,-106 L92,-98 L84,-90 L58,-86 Z", STEEL, (57, -111, 93, -85), k=0.5, dark=STEEL_D, light=STEEL_L)   # aríete/para-choque
    arma += R(56, -112, 8, 28, 3, CASCO, k=0.3)
    peito = R(-8, -84, 24, 5, 2.5, NUCLEO, k=0.2)
    corpo = _com_pernas(pernas_lamina, lambda: ac.mecha(col, CASCO, arma, costas, peito, cab=(26, 22), H=70, tw=0.82, th=0.9, ombro=0.75, perna=1.15))
    return f'<g transform="skewX(-14)">{corpo}</g>'   # inclinado para a frente (os pés ficam no chão)


def patinador(col):
    """B · PATINADOR: corpo compacto e baixo, patins de rodas, para-choque frontal; desliza como um kart."""
    costas = R(-52, -128, 14, 34, 5, STEEL_D, k=0.3) + R(-54, -130, 18, 6, 2, DARK, k=0.2)
    if ac.ESTATICO[0]:
        costas += P_([(-50, -94), (-40, -94), (-45, -70)], "#ff8a2a", k=0.2)
    arma = f'<path d="M34,-106 L50,-92 L60,-94" stroke="{DARK}" stroke-width="14" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(56, -112, 14, 40, 5, CASCO, k=0.4) + "".join(R(68, -110 + i * 9, 10, 5, 2, DARK, k=0.2) for i in range(4))   # para-choque de grade
    corpo = _com_pernas(pernas_rodas, lambda: ac.mecha(col, CASCO, arma, costas, H=46, tw=1.05, th=0.9, ombro=0.9, perna=0.9))
    return f'<g transform="skewX(-8)">{corpo}</g>'


def rastro(x, y, n=5, w=60):
    return "".join(f'<path d="M{x - i * 14},{y + i * 9} h{-w + i * 6}" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="{0.85 - i * 0.12:.2f}"/>' for i in range(n))


def fogo(x, y, L=70):
    return (P_([(x, y - 9), (x - L, y - 4), (x - L * 0.7, y), (x - L, y + 5), (x, y + 9)], "#ff6a1a", k=0.3)
            + P_([(x, y - 5), (x - L * 0.55, y - 2), (x - L * 0.4, y), (x - L * 0.55, y + 3), (x, y + 5)], "#ffe27a", k=0.2))


def cartucho_corredor(s=1.0):
    """Cartucho do T07 no padrão A35: cápsula vermelha, núcleo amarelo, aerofólio e escapamento atrás."""
    o = P_([(-24, -30), (24, -30), (20, -24), (-20, -24)], DARK, k=0.2) + R(-16, 24, 8, 8, 2, STEEL_D, k=0.1) + R(8, 24, 8, 8, 2, STEEL_D, k=0.1)
    o += R(-18, -26, 36, 52, 12, CASCO, k=0.6) + R(-18, -26, 36, 9, 6, shade(CASCO, 0.2), k=0.2)
    o += ac.cb.faixa(-18, 12, 36, 6, n=5) + R(-12, -14, 24, 22, 7, DARK, k=0.3)
    o += f'<rect x="-9" y="-11" width="18" height="16" rx="5" fill="{NUCLEO}"/>' + f'<circle cx="0" cy="-3" r="22" fill="{NUCLEO}" opacity="0.18"/>'
    o += P_([(-8, -20), (8, -18), (8, -16), (-8, -17)], "#ff3b2f", k=0.1)
    o += "".join(f'<path d="M{-30 - i * 6},{-6 + i * 8} h-12" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.8"/>' for i in range(3))   # linhas de velocidade
    return f'<g transform="scale({s})">{o}</g>'


def card(x, y, w, h, titulo, sub=""):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="22" fill="#ffffff" opacity="0.5"/>' + label(x + w / 2, y + 40, titulo, 24, INK)
            + (label(x + w / 2, y + 68, sub, 16, "#2a4a58", "middle", 600) if sub else ""))


def prancha():
    W, H = 1920, 1480
    col = "#4f86d9"
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>',
         label(W / 2, 54, "T07 · MINIRROBÔ VELOZ vira MECHA \"CORREDOR\" (proposta) — não encolhe mais; vira mecha e CORRE MUITO", 30)]
    # variantes
    for i, (nome, fn, sub) in enumerate((("A · VELOCISTA", velocista, "inclinado, pernas-lâmina de corrida, aerofólio + escapamentos"),
                                          ("B · PATINADOR", patinador, "compacto e baixo, patins de rodas, para-choque — desliza como kart"))):
        x = 20 + i * 950
        b.append(card(x, 86, 930, 600, nome, sub))
        gy = 600
        b.append(f'<rect x="{x + 20}" y="{gy}" width="890" height="8" rx="3" fill="#c9b99a"/>')
        b.append(rastro(x + 230, gy - 160, 5, 90))
        b.append(f'<g transform="translate({x + 380},{gy}) scale(2.3)">{fn(col)}</g>')
        # 1x + ao lado do robô + outra cor
        b.append(label(x + 760, 200, "tamanho de jogo, ao lado do robô:", 15, "#2a4a58", "middle", 600))
        b.append(f'<rect x="{x + 640}" y="330" width="250" height="5" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({x + 680},330)">{eu.desenha(0, "#f06aa8", "parado")}</g>')
        b.append(f'<g transform="translate({x + 790},330) scale(0.62)">{fn("#f06aa8")}</g>')
        b.append(label(x + 760, 400, "na cor de outro jogador:", 15, "#2a4a58", "middle", 600))
        b.append(f'<g transform="translate({x + 760},560) scale(0.9)">{fn("#5cc45c")}</g>')
    # silhueta junto dos outros mechas (escolhe o que mais se diferencia)
    b.append(card(20, 700, 1880, 270, "SILHUETAS LADO A LADO (tem que ser reconhecível no meio da luta)"))
    xs = [140, 400, 640, 880, 1120, 1360, 1590, 1790]
    tipos = [("Fornalha", ac.fornalha), ("Empilhadeira", ac.empilhadeira), ("Bola", ac.bola), ("Jato", ac.jato), ("Broca", ac.broca),
             ("Para-Raios", mc.TEMAS["T06"][3]), ("A Velocista", velocista), ("B Patinador", patinador)]
    for (nm, fn), x in zip(tipos, xs):
        b.append(f'<g transform="translate({x},935) scale(0.95)" filter="url(#sil)">{fn("#4f86d9")}</g>')
        b.append(label(x, 960, nm, 15, "#d42035" if nm[:2] in ("A ", "B ") else "#2a4a58"))
    # habilidade, golpes, atributos, cartucho
    y0 = 990
    b.append(card(20, y0, 620, 470, "HABILIDADE: ARRANCADA", "segure ESPECIAL"))
    b.append(f'<rect x="40" y="{y0 + 380}" width="580" height="8" rx="3" fill="#c9b99a"/>')
    b.append(fogo(300, y0 + 300, 110) + rastro(250, y0 + 250, 4, 120))
    b.append(f'<g transform="translate(380,{y0 + 380}) scale(1.25)">{velocista(col)}</g>')
    b.append(f'<g transform="translate(560,{y0 + 380}) rotate(-60) scale(0.9)">{eu.desenha(1, "#5cc45c", "parado")}</g>' + ac.ab.fx_estrela(540, y0 + 320, 0.3, 22))
    b.append(label(330, y0 + 420, "dispara em linha reta, escapamentos cospem fogo;", 16, INK, "middle", 600))
    b.append(label(330, y0 + 444, "atropela quem estiver no caminho e sobe parede correndo", 16, INK, "middle", 600))
    b.append(card(650, y0, 620, 470, "GOLPES DO MECHA"))
    b.append(f'<rect x="670" y="{y0 + 300}" width="580" height="8" rx="3" fill="#c9b99a"/>')
    b.append(f'<g transform="translate(800,{y0 + 300}) scale(1.05)">{velocista(col)}</g>' + rastro(830, y0 + 160, 3, 40) + ac.ab.fx_estrela(905, y0 + 196, 0.3, 14))
    b.append(f'<g transform="translate(1120,{y0 + 300}) rotate(-12) scale(1.05)">{velocista(col)}</g>' + ac.ab.fx_onda(1210, y0 + 300, 0.3, 1.5) + rastro(1060, y0 + 270, 4, 70))
    b.append(label(800, y0 + 340, "LEVE: joelhada-relâmpago", 17, INK) + label(1120, y0 + 340, "PESADO: voadora deslizante", 17, INK))
    b.append(label(960, y0 + 380, "leve sai muito rápido (empurra pouco);", 16, "#2a4a58", "middle", 600))
    b.append(label(960, y0 + 404, "pesado = desliza no chão e derruba quem estiver na frente", 16, "#2a4a58", "middle", 600))
    b.append(card(1280, y0, 620, 470, "ATRIBUTOS (PROVISÓRIOS) + CARTUCHO"))
    linhas = [("velocidade", "×1,7"), ("pulo", "×1,15"), ("recebe dano", "90%"), ("empurrão", "85%"), ("causa dano", "110%"), ("duração", "10 s")]
    for i, (a, v) in enumerate(linhas):
        b.append(label(1320, y0 + 110 + i * 40, a, 20, "#2a4a58", "start", 600) + label(1600, y0 + 110 + i * 40, v, 22, "#2e7d32" if i < 2 else INK, "end"))
    b.append(label(1460, y0 + 360, "o mecha mais FRÁGIL e o mais RÁPIDO:", 15, "#6b5a70", "middle", 600))
    b.append(label(1460, y0 + 382, "ganha por mobilidade, não por força", 15, "#6b5a70", "middle", 600))
    b.append(f'<g transform="translate(1770,{y0 + 230}) rotate(-8)">{cartucho_corredor(2.2)}</g>' + label(1770, y0 + 400, "cartucho / ícone", 15, "#2a4a58"))
    defs = '<defs><filter id="sil"><feColorMatrix type="matrix" values="0 0 0 0 0.16  0 0 0 0 0.1  0 0 0 0 0.18  0 0 0 1 0"/></filter></defs>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{defs}{"".join(b)}</svg>', W, H


if __name__ == "__main__":
    svg, w, h = prancha()
    queue(svg, os.path.join(HERE, "svg/mecha_corredor.svg"), os.path.join(ab.OUT, "mecha_corredor.png"), w, h, 1)
    print("corredor:", render_all())
