"""PRANCHA — novo CONCEITO VISUAL DAS ARMADURAS (pedido 2026-11-27, opção A "máquina pilotada"): vale para todas as
armaduras atuais (T01 Fornalha, T02 Empilhadeira, T03 Bola, T05 Broca, T06 Soldador) e as futuras.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/armaduras_conceito.py → art/out/robos_v2/armaduras_conceito.png
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import anim_blindado as ab  # noqa: E402
import conceito3_blindado as cb  # noqa: E402
import elenco_uch as eu  # noqa: E402
import robo_uch as ru  # noqa: E402
from elenco import label, INK  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

R, E, S, P_ = cb.R, cb.E, cb.S, cb.P
YEL, YEL_D = eu.YEL, eu.YEL_D
STEEL, STEEL_D, STEEL_L = cb.STEEL, cb.STEEL_D, cb.STEEL_L
GLASS = "#bfe9ff"


def piloto(cx, cy, col, s=0.62, face="raiva"):
    """Cabeça do piloto (Marretão) dentro da janela — o jogador se reconhece pela cor e pelo rosto."""
    return f'<g transform="translate({cx},{cy}) scale({s})">{ru.cabeca(col, {"face": face})}</g>'


def janela_redonda(cx, cy, r, col):
    o = E(cx, cy, r + 5, r + 5, STEEL_D, k=0.4) + E(cx, cy, r, r, GLASS, k=0.3)
    o += f'<clipPath id="j{cx}{cy}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath><g clip-path="url(#j{cx}{cy})">{piloto(cx - 1, cy + 8, col)}</g>'
    o += f'<path d="M{cx - r * 0.6},{cy - r * 0.5} a{r * 0.8},{r * 0.8} 0 0 1 {r * 0.5},{-r * 0.3}" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.8"/>'
    for a in range(0, 360, 60):
        import math
        o += E(cx + math.cos(math.radians(a)) * (r + 2.5), cy + math.sin(math.radians(a)) * (r + 2.5), 1.6, 1.6, STEEL_L, k=0.1)
    return o


def faixa_jogador(x, y, w, col):
    return R(x, y, w, 7, 3, col, k=0.3) + R(x, y, w, 2.5, 1.2, shade(col, 0.3), k=0.1)


def perna_pistao(x, y0, y1, w=9):
    return R(x - w / 2, y0, w, y1 - y0, 3, STEEL_D, k=0.3) + R(x - w / 2 + 2, y0 + 3, w - 4, (y1 - y0) * 0.5, 2, STEEL_L, k=0.2)


def pe_maquina(x, y, w=26):
    return R(x - w / 2, y - 9, w, 9, 4, "#3a3f4a", k=0.4) + R(x - w / 2, y - 3, w, 3, 1.5, "#f08a2b", k=0.2)


import math  # noqa: E402

DARK = "#2e323b"
EYE = "#ff3b2f"


def cabine_peito(cx, cy, w, h, col):
    """Cockpit no peito: vidro com a cabeça do piloto + moldura grossa."""
    o = R(cx - w / 2 - 5, cy - h / 2 - 5, w + 10, h + 10, 9, DARK, k=0.4) + R(cx - w / 2, cy - h / 2, w, h, 7, GLASS, k=0.3)
    cid = f"c{int(cx)}{int(cy)}{int(w)}"
    o += f'<clipPath id="{cid}"><rect x="{cx - w / 2}" y="{cy - h / 2}" width="{w}" height="{h}" rx="7"/></clipPath>'
    o += f'<g clip-path="url(#{cid})">{piloto(cx, cy + h * 0.3, col, h / 52)}</g>'
    o += f'<path d="M{cx - w / 2 + 4},{cy - h / 2 + 6} l{w * 0.35},0" stroke="#ffffff" stroke-width="3" opacity="0.7"/>'
    return o


def perna_mecha(hx, hy, fx, casco, k=1.0):
    """Perna de mecha: coxa grossa, joelho com placa, canela larga e pé com garras."""
    kx, ky = (hx + fx) / 2 + 8 * k, hy + (0 - hy) * 0.5
    o = f'<path d="M{hx},{hy} L{kx},{ky} L{fx},-12" stroke="{DARK}" stroke-width="16" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    o += S(f"M{hx - 12},{hy - 6} L{hx + 12},{hy - 6} L{kx + 8},{ky} L{kx - 10},{ky + 2} Z", casco, (hx - 13, hy - 7, kx + 9, ky + 3), k=0.5)
    o += P_([(kx - 9, ky - 8), (kx + 11, ky - 4), (kx + 6, ky + 10), (kx - 8, ky + 6)], shade(casco, -0.25), k=0.3)   # joelheira
    o += S(f"M{kx - 9},{ky + 4} L{kx + 9},{ky + 4} L{fx + 11},-12 L{fx - 11},-12 Z", casco, (kx - 10, ky + 3, fx + 12, -11), k=0.5)
    o += P_([(fx - 16, 0), (fx - 12, -14), (fx + 12, -14), (fx + 22, 0)], DARK, k=0.4)                   # pé
    o += "".join(P_([(fx + 10 + d, 0), (fx + 16 + d, -6), (fx + 26 + d, 0)], STEEL_L, k=0.1) for d in (0, -8))  # garras
    return o


def ombreira(x, y, casco, s=1.0, spikes=True):
    o = S(f"M{x - 20 * s},{y + 10 * s} C{x - 22 * s},{y - 14 * s} {x - 4 * s},{y - 24 * s} {x + 14 * s},{y - 18 * s} L{x + 22 * s},{y + 6 * s} Z",
          casco, (x - 23 * s, y - 25 * s, x + 23 * s, y + 11 * s), k=0.6)
    o += R(x - 16 * s, y + 2 * s, 34 * s, 5 * s, 2, shade(casco, -0.3), k=0.2)
    if spikes:
        o += "".join(P_([(x + d * s - 4, y - 16 * s), (x + d * s, y - 30 * s), (x + d * s + 5, y - 17 * s)], STEEL_L, k=0.1) for d in (-8, 4))
    return o


def cabeca_mecha(x, y, casco):
    """Cabecinha baixa e enfiada entre os ombros, fenda de olho vermelha acesa: AMEAÇA."""
    o = P_([(x - 14, y + 6), (x - 12, y - 10), (x + 6, y - 14), (x + 18, y - 4), (x + 16, y + 8)], casco, k=0.5)
    o += P_([(x - 4, y - 4), (x + 16, y - 2), (x + 14, y + 2), (x - 4, y + 1)], "#1a1414", k=0.2)
    o += P_([(x - 2, y - 3), (x + 14, y - 1.5), (x + 13, y + 0.8), (x - 2, y)], EYE, k=0.1)
    o += f'<ellipse cx="{x + 8}" cy="{y - 1}" rx="14" ry="5" fill="{EYE}" opacity="0.3"/>'
    o += P_([(x - 12, y - 10), (x - 20, y - 22), (x - 4, y - 13)], shade(casco, -0.2), k=0.2)                  # chifre/antena
    return o


def punho(x, y, casco, s=1.0):
    o = R(x - 12 * s, y - 10 * s, 24 * s, 22 * s, 6, DARK, k=0.4)
    o += "".join(R(x - 11 * s + i * 6 * s, y + 8 * s, 5 * s, 10 * s, 2, STEEL, k=0.2) for i in range(4))
    return o + R(x - 12 * s, y - 10 * s, 24 * s, 6 * s, 3, casco, k=0.2)


def mecha(col, casco, arma, extra_costas="", extra_peito="", cab=(30, 26)):
    """Mecha humanoide padrão: curvado para a frente, ombros enormes, cockpit no peito, braço-arma à frente."""
    o = extra_costas
    o += perna_mecha(-14, -58, -22, shade(casco, -0.15), 0.6)                                           # perna de trás
    o += f'<path d="M-30,-104 L-44,-78 L-40,-52" stroke="{DARK}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + punho(-40, -46, shade(casco, -0.15), 0.9)  # braço de trás
    o += R(-22, -66, 40, 14, 5, DARK, k=0.4)                                                            # quadril
    o += S("M-34,-62 L-40,-112 L-14,-126 L30,-122 L40,-96 L26,-60 Z", casco, (-41, -127, 41, -59), k=0.7)   # tronco em V
    o += P_([(-30, -112), (-14, -122), (28, -118), (20, -110), (-22, -106)], shade(casco, 0.18), k=0.2)
    o += cb.faixa(-30, -72, 54, 7, n=7) + faixa_jogador(-36, -86, 74, col)
    o += cabine_peito(4, -102, cab[0], cab[1], col) + extra_peito
    o += perna_mecha(12, -58, 18, casco, 1.0)                                                           # perna da frente
    o += cabeca_mecha(10, -136, casco)
    o += ombreira(-24, -118, shade(casco, -0.1), 1.0)
    o += arma
    o += ombreira(30, -116, casco, 1.15)
    return o


# ---------------------------------------------------------------- T01 FORNALHA: mecha-caldeira, fornalha em brasa na barriga, lança-chamas
def fornalha(col):
    casco = "#4a505c"
    costas = "".join(R(-50 + i * 12, -168 + i * 4, 9, 46, 3, DARK, k=0.3) for i in range(2)) + "".join(E(-44 + i * 12, -176 - i * 6, 7 + i * 3, 6 + i * 2, "#6a6a70", k=0.2) for i in range(2))
    peito = R(-22, -74, 40, 10, 3, "#2a1a14", k=0.3) + "".join(R(-19 + i * 8, -73, 5, 8, 1.5, "#ff7a1f", k=0.2) for i in range(5)) + '<ellipse cx="-2" cy="-66" rx="30" ry="9" fill="#ff8a2a" opacity="0.4"/>'
    arma = f'<path d="M34,-106 L56,-90 L66,-92" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(56, -102, 34, 20, 6, casco, k=0.4) + R(88, -98, 10, 12, 3, DARK, k=0.3)
    arma += P_([(98, -100), (140, -110), (128, -92), (146, -80), (98, -82)], "#ff6a1a", k=0.4) + P_([(98, -96), (122, -100), (114, -92), (126, -86), (98, -86)], "#ffe27a", k=0.3)
    return mecha(col, casco, arma, costas, peito)


# ---------------------------------------------------------------- T02 EMPILHADEIRA: mecha de carga, mastro hidráulico nas costas, braço-GARFO de 2 lâminas
def empilhadeira(col):
    casco = "#e0b02a"
    costas = R(-54, -190, 10, 130, 3, DARK, k=0.4) + R(-48, -186, 6, 120, 2, STEEL, k=0.2) + E(-49, -196, 6, 5, "#ffb22e", k=0.2)
    arma = f'<path d="M34,-106 L52,-84 L66,-86" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(60, -104, 14, 40, 4, DARK, k=0.4)
    for y in (-100, -74):
        arma += S(f"M72,{y} L132,{y + 2} L140,{y + 8} L72,{y + 8} Z", STEEL, (71, y - 1, 141, y + 9), k=0.4, dark=STEEL_D, light=STEEL_L)
    return mecha(col, casco, arma, costas)


# ---------------------------------------------------------------- T03 BOLA: mecha de demolição, punho = BOLA de aço na corrente (e se enrola numa bola para rolar)
def bola(col):
    casco = "#7a828f"
    arma = f'<path d="M34,-106 L50,-86 L60,-80" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + punho(62, -78, casco, 1.0)
    arma += "".join(f'<ellipse cx="{72 + i * 7}" cy="{-66 + i * 3}" rx="3.4" ry="2.4" fill="none" stroke="{STEEL_D}" stroke-width="2"/>' for i in range(6))
    arma += E(128, -40, 24, 24, STEEL_D, k=0.6) + E(124, -44, 20, 20, STEEL, k=0.3, light=STEEL_L)
    arma += "".join(P_([(128 + math.cos(a) * 22, -40 + math.sin(a) * 22), (128 + math.cos(a + 0.18) * 34, -40 + math.sin(a + 0.18) * 34), (128 + math.cos(a + 0.36) * 22, -40 + math.sin(a + 0.36) * 22)], STEEL_L, k=0.1) for a in (-1.2, 0.2, 1.6, 3.0, 4.4))
    return mecha(col, casco, arma)


# ---------------------------------------------------------------- T05 BROCA: mecha perfurador laranja, braço = broca enorme girando
def broca(col):
    casco = "#e07a2e"
    arma = f'<path d="M34,-106 L52,-92 L64,-94" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(58, -108, 22, 28, 6, DARK, k=0.4)
    arma += S("M80,-112 L150,-94 L80,-76 Z", STEEL, (79, -113, 151, -75), k=0.5, dark=STEEL_D, light=STEEL_L)
    arma += "".join(f'<path d="M{88 + i * 14},{-110 + i * 3.6} L{96 + i * 14},{-78 - i * 3.6}" stroke="{STEEL_D}" stroke-width="3"/>' for i in range(4))
    arma += "".join(f'<path d="M154,{-94 + d} l12,{d * 0.6}" stroke="#c8a27a" stroke-width="3.4" stroke-linecap="round"/>' for d in (-10, 0, 10))
    return mecha(col, casco, arma)


# ---------------------------------------------------------------- T06 SOLDADOR: mecha de solda, tanques nas costas, visor verde sobre o cockpit, maçarico
def soldador(col):
    casco = "#3e444f"
    costas = R(-62, -150, 16, 64, 7, "#d9482b", k=0.5) + R(-50, -146, 14, 60, 7, "#e8a33a", k=0.5) + f'<path d="M-44,-148 C-40,-170 -10,-168 -4,-130" stroke="{DARK}" stroke-width="3" fill="none"/>'
    peito = R(-12, -120, 32, 8, 3, "#6fe08a", k=0.2) + '<rect x="-14" y="-122" width="36" height="12" rx="4" fill="#6fe08a" opacity="0.25"/>'
    arma = f'<path d="M34,-106 L52,-90 L64,-92" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(60, -100, 30, 14, 5, STEEL_D, k=0.3) + R(88, -104, 9, 22, 2, STEEL, k=0.3)
    arma += P_([(97, -98), (128, -93), (97, -88)], "#7fd3ff", k=0.2) + E(130, -93, 8, 8, "#ffffff", k=0.2)
    arma += "".join(f'<path d="M130,-93 l{dx},{dy}" stroke="#ffd36b" stroke-width="2.4" stroke-linecap="round"/>' for dx, dy in ((14, -10), (16, 2), (10, 14), (2, 16), (-6, 14)))
    return mecha(col, casco, arma, costas, peito)


ARMAS = [("T01 · FORNALHA", fornalha, "#4f86d9"), ("T02 · EMPILHADEIRA", empilhadeira, "#5cc45c"), ("T03 · BOLA DE DEMOLIÇÃO", bola, "#f06aa8"),
         ("T05 · BROCA", broca, "#f2c84b"), ("T06 · SOLDADOR", soldador, "#4f86d9")]

REGRAS = ["1  TODA armadura é um MECHA humanoide (2 pernas, 2 braços), nunca o veículo: o robô PILOTA de dentro, cabeça visível no COCKPIT do peito.",
          "2  FAIXA NA COR DO JOGADOR sempre no mesmo lugar do casco: quem é quem em 1 segundo.",
          "3  AMEAÇA: ~2× o robô, curvado para a frente, ombreiras enormes com espetos, cabecinha baixa com FENDA DE OLHO VERMELHA acesa, pés com garras.",
          "4  O tema da máquina vira o BRAÇO-ARMA da frente (lança-chamas, garfo, bola na corrente, broca, maçarico) e um detalhe nas costas/peito.",
          "5  Papel e giz, sem contorno; brasa, fumaça ou faísca dizem que está LIGADO. Mesmas regras de jogo de hoje (só muda o visual)."]


def prancha():
    W, H = 1920, 1300
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 56, "ARMADURAS v2 — MECHAS PILOTADOS, AMEAÇADORES (vale para todas, atuais e futuras)", 34)]
    b.append(f'<rect x="20" y="86" width="{W - 40}" height="196" rx="20" fill="#ffffff" opacity="0.6"/>')
    for i, r in enumerate(REGRAS):
        b.append(label(50, 124 + i * 34, r, 20, INK, "start", 600))
    cw = 372
    for i, (nome, fn, col) in enumerate(ARMAS):
        x = 20 + i * (cw + 5)
        cx = x + cw / 2
        b.append(f'<rect x="{x}" y="300" width="{cw}" height="980" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(cx, 344, nome, 24, INK))
        gy = 820
        b.append(f'<rect x="{x + 16}" y="{gy}" width="{cw - 32}" height="8" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 50},{gy}) scale(2.25)">{fn(col)}</g>')
        b.append(label(cx, gy + 40, "na cor de outro jogador:", 15, "#2a4a58", "middle", 600))
        gy2 = 1060
        b.append(f'<rect x="{x + 16}" y="{gy2}" width="{cw - 32}" height="6" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 40},{gy2}) scale(0.95)">{fn(["#5cc45c", "#f06aa8", "#f2c84b", "#4f86d9", "#f06aa8"][i])}</g>')
        gy3 = 1240
        b.append(label(cx, gy3 - 110, "tamanho de jogo, ao lado do robô:", 15, "#2a4a58", "middle", 600))
        b.append(f'<rect x="{x + 60}" y="{gy3}" width="{cw - 120}" height="5" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 60},{gy3})">{eu.desenha(0, "#f06aa8", "parado")}</g>')
        b.append(f'<g transform="translate({cx + 10},{gy3}) scale(0.62)">{fn(col)}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


if __name__ == "__main__":
    svg, w, h = prancha()
    queue(svg, os.path.join(HERE, "svg/armaduras_conceito.svg"), os.path.join(ab.OUT, "armaduras_conceito.png"), w, h, 1)
    print("prancha:", render_all())
