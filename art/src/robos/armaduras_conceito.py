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


def mecha(col, casco, arma, extra_costas="", extra_peito="", cab=(30, 26), H=58, tw=1.0, th=1.0, gorila=False, ombro=1.0, perna=1.0):
    """Mecha humanoide com CORPO PRÓPRIO: H = altura do quadril, tw/th = largura/altura do tronco, gorila = braço de trás
    apoiado no chão (punho), ombro = tamanho das ombreiras. A arma é desenhada no quadro padrão e levada até o ombro."""
    def T(x, y):   # quadro padrão do tronco (quadril em -58) → corpo deste mecha
        return x * tw, -H + (y + 58) * th
    sx, sy = T(34, -106)
    dx, dy = sx - 34, sy + 106
    tr = f"translate(0,{-H}) scale({tw},{th}) translate(0,58)"
    o = f'<g transform="translate({dx:.1f},{dy:.1f})">{extra_costas}</g>' if extra_costas else ""
    o += perna_mecha(-14 * tw, -H, -22 * perna, shade(casco, -0.15), 0.6)                               # perna de trás
    bx, by = T(-30, -104)
    if gorila:   # braço de trás enorme, nó dos dedos no chão
        o += f'<path d="M{bx},{by} L{bx - 22},{by + (-by) * 0.45} L{bx - 18},-20" stroke="{DARK}" stroke-width="18" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + punho(bx - 18, -12, shade(casco, -0.15), 1.4)
    else:
        o += f'<path d="M{bx},{by} L{bx - 14},{by + 26} L{bx - 10},{by + 52}" stroke="{DARK}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + punho(bx - 10, by + 58, shade(casco, -0.15), 0.9)
    o += f'<g transform="{tr}">'
    o += R(-22, -66, 40, 14, 5, DARK, k=0.4)
    o += S("M-34,-62 L-40,-112 L-14,-126 L30,-122 L40,-96 L26,-60 Z", casco, (-41, -127, 41, -59), k=0.7)
    o += P_([(-30, -112), (-14, -122), (28, -118), (20, -110), (-22, -106)], shade(casco, 0.18), k=0.2)
    o += cb.faixa(-30, -72, 54, 7, n=7) + faixa_jogador(-36, -86, 74, col) + "</g>"
    cx, cy = T(4, -102)
    o += cabine_peito(cx, cy, cab[0], cab[1], col)
    o += f'<g transform="{tr}">{extra_peito}</g>'
    o += perna_mecha(12 * tw, -H, 18 * perna, casco, 1.0)                                                # perna da frente
    hx, hy = T(10, -136)
    o += cabeca_mecha(hx, hy, casco)
    ox, oy = T(-24, -118)
    o += ombreira(ox, oy, shade(casco, -0.1), ombro)
    o += f'<g transform="translate({dx:.1f},{dy:.1f})">{arma}</g>'
    ox, oy = T(30, -116)
    o += ombreira(ox, oy, casco, 1.15 * ombro)
    return o


# ---------------------------------------------------------------- T01 FORNALHA: mecha-caldeira, fornalha em brasa na barriga, lança-chamas
def fornalha(col):
    casco = "#4a505c"
    costas = "".join(R(-50 + i * 12, -168 + i * 4, 9, 46, 3, DARK, k=0.3) for i in range(2)) + "".join(E(-44 + i * 12, -176 - i * 6, 7 + i * 3, 6 + i * 2, "#6a6a70", k=0.2) for i in range(2))
    peito = R(-22, -74, 40, 10, 3, "#2a1a14", k=0.3) + "".join(R(-19 + i * 8, -73, 5, 8, 1.5, "#ff7a1f", k=0.2) for i in range(5)) + '<ellipse cx="-2" cy="-66" rx="30" ry="9" fill="#ff8a2a" opacity="0.4"/>'
    arma = f'<path d="M34,-106 L56,-90 L66,-92" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(56, -102, 34, 20, 6, casco, k=0.4) + R(88, -98, 10, 12, 3, DARK, k=0.3)
    arma += P_([(98, -100), (140, -110), (128, -92), (146, -80), (98, -82)], "#ff6a1a", k=0.4) + P_([(98, -96), (122, -100), (114, -92), (126, -86), (98, -86)], "#ffe27a", k=0.3)
    return mecha(col, casco, arma, costas, peito, cab=(36, 26), H=40, tw=1.35, th=0.85, ombro=1.2, perna=1.3)   # BAIXA e LARGA


# ---------------------------------------------------------------- T02 EMPILHADEIRA: mecha de carga, mastro hidráulico nas costas, braço-GARFO de 2 lâminas
def empilhadeira(col):
    casco = "#e0b02a"
    costas = R(-54, -190, 10, 130, 3, DARK, k=0.4) + R(-48, -186, 6, 120, 2, STEEL, k=0.2) + E(-49, -196, 6, 5, "#ffb22e", k=0.2)
    arma = f'<path d="M34,-106 L52,-84 L66,-86" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(60, -104, 14, 40, 4, DARK, k=0.4)
    for y in (-100, -74):
        arma += S(f"M72,{y} L132,{y + 2} L140,{y + 8} L72,{y + 8} Z", STEEL, (71, y - 1, 141, y + 9), k=0.4, dark=STEEL_D, light=STEEL_L)
    return mecha(col, casco, arma, costas, H=66, tw=1.1, th=1.15, ombro=0.9)   # ALTA e QUADRADA, ereta


# ---------------------------------------------------------------- T03 BOLA: mecha de demolição, punho = BOLA de aço na corrente (e se enrola numa bola para rolar)
def bola(col):
    casco = "#7a828f"
    arma = f'<path d="M34,-106 L50,-86 L60,-80" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + punho(62, -78, casco, 1.0)
    arma += "".join(f'<ellipse cx="{72 + i * 7}" cy="{-66 + i * 3}" rx="3.4" ry="2.4" fill="none" stroke="{STEEL_D}" stroke-width="2"/>' for i in range(6))
    arma += E(128, -40, 24, 24, STEEL_D, k=0.6) + E(124, -44, 20, 20, STEEL, k=0.3, light=STEEL_L)
    arma += "".join(P_([(128 + math.cos(a) * 22, -40 + math.sin(a) * 22), (128 + math.cos(a + 0.18) * 34, -40 + math.sin(a + 0.18) * 34), (128 + math.cos(a + 0.36) * 22, -40 + math.sin(a + 0.36) * 22)], STEEL_L, k=0.1) for a in (-1.2, 0.2, 1.6, 3.0, 4.4))
    return mecha(col, casco, arma, H=40, tw=1.25, th=1.05, gorila=True, ombro=1.45, perna=0.8)   # GORILA: punho no chão


# ---------------------------------------------------------------- T05 BROCA: mecha perfurador laranja, braço = broca enorme girando
def broca(col):
    casco = "#e07a2e"
    arma = f'<path d="M34,-106 L52,-92 L64,-94" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(58, -108, 22, 28, 6, DARK, k=0.4)
    arma += S("M80,-112 L150,-94 L80,-76 Z", STEEL, (79, -113, 151, -75), k=0.5, dark=STEEL_D, light=STEEL_L)
    arma += "".join(f'<path d="M{88 + i * 14},{-110 + i * 3.6} L{96 + i * 14},{-78 - i * 3.6}" stroke="{STEEL_D}" stroke-width="3"/>' for i in range(4))
    arma += "".join(f'<path d="M154,{-94 + d} l12,{d * 0.6}" stroke="#c8a27a" stroke-width="3.4" stroke-linecap="round"/>' for d in (-10, 0, 10))
    return mecha(col, casco, arma, cab=(26, 24), H=78, tw=0.75, th=0.95, ombro=0.8, perna=0.8)   # ALTA e MAGRA, pernas compridas


# ---------------------------------------------------------------- T06 SOLDADOR: mecha de solda, tanques nas costas, visor verde sobre o cockpit, maçarico
def soldador(col):
    casco = "#3e444f"
    costas = R(-62, -150, 16, 64, 7, "#d9482b", k=0.5) + R(-50, -146, 14, 60, 7, "#e8a33a", k=0.5) + f'<path d="M-44,-148 C-40,-170 -10,-168 -4,-130" stroke="{DARK}" stroke-width="3" fill="none"/>'
    peito = R(-12, -120, 32, 8, 3, "#6fe08a", k=0.2) + '<rect x="-14" y="-122" width="36" height="12" rx="4" fill="#6fe08a" opacity="0.25"/>'
    arma = f'<path d="M34,-106 L52,-90 L64,-92" stroke="{DARK}" stroke-width="15" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    arma += R(60, -100, 30, 14, 5, STEEL_D, k=0.3) + R(88, -104, 9, 22, 2, STEEL, k=0.3)
    arma += P_([(97, -98), (128, -93), (97, -88)], "#7fd3ff", k=0.2) + E(130, -93, 8, 8, "#ffffff", k=0.2)
    arma += "".join(f'<path d="M130,-93 l{dx},{dy}" stroke="#ffd36b" stroke-width="2.4" stroke-linecap="round"/>' for dx, dy in ((14, -10), (16, 2), (10, 14), (2, 16), (-6, 14)))
    return mecha(col, casco, arma, costas, peito, H=50, tw=1.0, th=1.0)   # CORCUNDA de tanques


ARMAS = [("T01 · FORNALHA (baixa e larga)", fornalha, "#4f86d9"), ("T02 · EMPILHADEIRA (alta, ereta)", empilhadeira, "#5cc45c"), ("T03 · BOLA (gorila)", bola, "#f06aa8"),
         ("T05 · BROCA (alta e magra)", broca, "#f2c84b"), ("T06 · SOLDADOR (corcunda)", soldador, "#4f86d9")]

REGRAS = ["1  TODA armadura é um MECHA humanoide (2 pernas, 2 braços), nunca o veículo: o robô PILOTA de dentro, cabeça visível no COCKPIT do peito.",
          "2  FAIXA NA COR DO JOGADOR sempre no mesmo lugar do casco: quem é quem em 1 segundo.",
          "3  AMEAÇA: ~2× o robô, ombreiras com espetos, cabecinha com FENDA DE OLHO VERMELHA, pés com garras — e SILHUETA PRÓPRIA (baixo/largo, alto/magro, gorila…).",
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
        b.append(label(cx, 344, nome, 19, INK))
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


# ================================================================ T03: o gorila SE FECHA numa BOLA (pedido 2026-11-27)
def bola_fechada(col, rot=0.0, aberto=0.0):
    """Bola blindada: as placas do casco (ombreiras/costas) viram gomos; janela do piloto e faixa na cor do jogador."""
    casco = "#7a828f"
    r = 46
    o = f'<g transform="translate(0,{-r}) rotate({rot:.0f})">'
    o += E(0, 0, r, r, DARK, k=0.6)
    for a in range(0, 360, 60):                                                    # gomos de placa
        a0, a1 = math.radians(a + 4 + aberto * 10), math.radians(a + 56 - aberto * 10)
        p = [(math.cos(a0) * 12, math.sin(a0) * 12), (math.cos(a0) * (r - 3), math.sin(a0) * (r - 3)),
             (math.cos((a0 + a1) / 2) * (r + 2), math.sin((a0 + a1) / 2) * (r + 2)), (math.cos(a1) * (r - 3), math.sin(a1) * (r - 3)), (math.cos(a1) * 12, math.sin(a1) * 12)]
        o += P_(p, casco if a % 120 else shade(casco, 0.15), k=0.4)
        sx, sy = math.cos(math.radians(a + 30)), math.sin(math.radians(a + 30))
        o += P_([(sx * r - sy * 5, sy * r + sx * 5), (sx * (r + 14), sy * (r + 14)), (sx * r + sy * 5, sy * r - sx * 5)], STEEL_L, k=0.1)   # espetos
    o += R(-r, -6, 2 * r, 12, 5, col, k=0.4)                                       # cinturão na cor do jogador
    o += f'<g transform="rotate({-rot:.0f})">{janela_redonda(0, 0, 17, col)}</g>'
    o += P_([(-10, -24), (10, -24), (8, -19), (-8, -19)], EYE, k=0.1)
    return o + "</g>"


def bola_virando(col):
    """4 quadros: gorila → agacha e encolhe → placas fecham → rola."""
    q = []
    q.append(("1 · gorila", bola(col)))
    ag = f'<g transform="translate(0,0) scale(1.05,0.72)">{bola(col)}</g>'
    q.append(("2 · agacha e abraça o corpo", ag))
    meio = f'<g opacity="0.35" transform="scale(0.9,0.6)">{bola(col)}</g>' + f'<g transform="scale(0.9)">{bola_fechada(col, 0, 1.0)}</g>'
    q.append(("3 · as placas fecham", meio))
    rola = bola_fechada(col, 140) + "".join(f'<path d="M{-80 - i * 18},{-30 + i * 14} h26" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.7"/>' for i in range(3))
    rola += ab.fx_dust(-30, 0, 0.5, 1.0)
    q.append(("4 · BOLA: rola e esmaga", rola))
    return q


def prancha_bola():
    W, H = 1920, 620
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 54, "T03 · BOLA DE DEMOLIÇÃO — o mecha gorila SE FECHA numa bola blindada", 32)]
    for i, (nome, svg) in enumerate(bola_virando("#f06aa8")):
        x = 20 + i * 475
        b.append(f'<rect x="{x}" y="86" width="460" height="510" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(x + 230, 130, nome, 24, INK))
        b.append(f'<rect x="{x + 20}" y="500" width="420" height="8" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({x + 210},500) scale(2.0)">{svg}</g>')
    b.append(label(W / 2, 560, "Fechada: piloto na vigia, cinturão na cor do jogador, espetos e olho vermelho — o resto (rolar, quicar, esmagar) segue as regras de hoje.", 17, "#2a4a58", "middle", 600))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


if __name__ == "__main__" and "--bola" in sys.argv:
    svg, w, h = prancha_bola()
    queue(svg, os.path.join(HERE, "svg/armaduras_bola.svg"), os.path.join(ab.OUT, "armaduras_bola.png"), w, h, 1)
    print("bola:", render_all())
