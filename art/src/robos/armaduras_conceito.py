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


# ---------------------------------------------------------------- T01 FORNALHA
def fornalha(col):
    o = perna_pistao(-14, -34, -8) + perna_pistao(14, -34, -8) + pe_maquina(-14, 0) + pe_maquina(14, 0)
    o += R(26, -120, 12, 34, 3, STEEL_D, k=0.3) + "".join(E(32 + i * 3, -128 - i * 10, 6 + i * 2, 5 + i * 2, "#9a9aa0", k=0.2) for i in range(3))   # chaminé
    o += E(0, -70, 40, 42, "#4a505c", k=0.7) + E(0, -70, 34, 36, shade("#4a505c", 0.12), k=0.3)
    o += R(-22, -44, 44, 14, 4, "#2a1a14", k=0.3) + "".join(R(-18 + i * 9, -42, 5, 10, 1.5, "#ff7a1f", k=0.2) for i in range(5))   # grelha em brasa
    o += f'<ellipse cx="0" cy="-37" rx="30" ry="10" fill="#ff9a3a" opacity="0.35"/>'
    o += faixa_jogador(-36, -64, 10, col) + janela_redonda(2, -82, 20, col)
    o += R(34, -64, 30, 14, 5, STEEL_D, k=0.3) + E(66, -57, 9, 9, "#2a2230", k=0.3)                   # bocal de fogo (braço)
    o += P_([(72, -64), (100, -70), (92, -57), (104, -46), (72, -50)], "#ff8a2a", k=0.4) + P_([(74, -60), (90, -62), (84, -56), (92, -50), (74, -53)], "#ffe27a", k=0.3)
    return o


# ---------------------------------------------------------------- T02 EMPILHADEIRA
def empilhadeira(col):
    o = E(-20, -12, 13, 13, "#2a2f38", k=0.4) + E(-20, -12, 5, 5, STEEL, k=0.2) + E(20, -12, 13, 13, "#2a2f38", k=0.4) + E(20, -12, 5, 5, STEEL, k=0.2)
    o += R(-34, -50, 66, 34, 8, YEL, k=0.6, dark=YEL_D) + cb.faixa(-34, -24, 66, 6, n=8)
    o += f'<path d="M-26,-50 V-118 H18 V-50" stroke="#3a3f4a" stroke-width="6" fill="none" stroke-linejoin="round"/>'   # santo-antônio
    o += R(-22, -110, 36, 56, 10, GLASS, k=0.3)
    o += f'<clipPath id="emp"><rect x="-22" y="-110" width="36" height="56" rx="10"/></clipPath><g clip-path="url(#emp)">{piloto(-4, -70, col, 0.75)}</g>'
    o += f'<path d="M-16,-104 l10,0" stroke="#ffffff" stroke-width="3" opacity="0.8"/>'
    o += faixa_jogador(-34, -46, 66, col)
    o += R(34, -120, 9, 104, 3, STEEL_D, k=0.4) + R(43, -64, 44, 7, 2, STEEL, k=0.4, dark=STEEL_D) + R(43, -36, 44, 7, 2, STEEL, k=0.4, dark=STEEL_D)   # mastro e garfo
    o += E(-2, -122, 5, 4, "#ffb22e", k=0.2)
    return o


# ---------------------------------------------------------------- T03 BOLA DE DEMOLIÇÃO
def bola(col):
    o = E(0, -46, 46, 46, STEEL_D, k=0.7) + E(-6, -54, 40, 38, STEEL, k=0.3, light=STEEL_L)
    o += R(-46, -52, 92, 12, 5, col, k=0.4)                                                            # faixa do jogador (cinturão)
    for x, y in ((-30, -78), (28, -80), (-36, -20), (34, -18), (0, -92)):
        o += E(x, y, 3, 3, STEEL_L, k=0.1)
    o += janela_redonda(4, -50, 19, col)
    o += f'<path d="M-50,-46 a50,50 0 0 1 12,-32 M-46,-20 a50,50 0 0 1 -6,-14" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.45" stroke-linecap="round"/>'
    o += "".join(f'<path d="M{-70 - i * 14},{-30 + i * 10} h20" stroke="#ffffff" stroke-width="4" stroke-linecap="round" opacity="0.7"/>' for i in range(3))
    return o


# ---------------------------------------------------------------- T05 BROCA
def broca(col):
    o = perna_pistao(-14, -36, -8, 10) + perna_pistao(14, -36, -8, 10) + pe_maquina(-14, 0, 28) + pe_maquina(14, 0, 28)
    o += R(-34, -108, 64, 74, 14, "#f08a3d", k=0.7) + R(-34, -108, 64, 14, 8, shade("#f08a3d", 0.2), k=0.3) + cb.faixa(-34, -46, 64, 6, n=8)
    o += faixa_jogador(-34, -36, 64, col) + janela_redonda(-2, -76, 19, col)
    o += R(30, -74, 18, 20, 5, STEEL_D, k=0.3)
    o += S("M48,-78 L100,-64 L48,-50 Z", STEEL, (47, -79, 101, -49), k=0.5, dark=STEEL_D, light=STEEL_L)       # broca girando
    o += "".join(f'<path d="M{54 + i * 10},{-76 + i * 2.6} L{60 + i * 10},{-52 - i * 2.6}" stroke="{STEEL_D}" stroke-width="2.4"/>' for i in range(4))
    o += "".join(f'<path d="M{104},{-64 + d} l10,{d * 0.6}" stroke="#c8a27a" stroke-width="3" stroke-linecap="round"/>' for d in (-8, 0, 8))
    return o


# ---------------------------------------------------------------- T06 SOLDADOR
def soldador(col):
    o = perna_pistao(-13, -34, -8) + perna_pistao(13, -34, -8) + pe_maquina(-13, 0) + pe_maquina(13, 0)
    o += R(-38, -100, 14, 58, 6, "#d9482b", k=0.5) + R(-30, -96, 12, 54, 6, "#e8a33a", k=0.5)            # tanques
    o += R(-26, -96, 58, 64, 14, "#4a505c", k=0.7) + faixa_jogador(-26, -44, 58, col)
    o += S("M-20,-104 C-20,-136 30,-136 30,-104 L30,-70 L-20,-70 Z", "#2a3a2a", (-21, -137, 31, -69), k=0.5)   # cúpula-visor
    o += S("M-15,-102 C-15,-128 25,-128 25,-102 L25,-76 L-15,-76 Z", "#6fe08a", (-16, -129, 26, -75), k=0.3)
    o += f'<clipPath id="sol"><path d="M-15,-102 C-15,-128 25,-128 25,-102 L25,-76 L-15,-76 Z"/></clipPath><g clip-path="url(#sol)" opacity="0.85">{piloto(5, -88, col, 0.62)}</g>'
    o += f'<path d="M-15,-102 C-15,-128 25,-128 25,-102 L25,-76 L-15,-76 Z" fill="#6fe08a" opacity="0.28"/>'
    o += R(30, -66, 30, 10, 4, STEEL_D, k=0.3) + R(58, -70, 8, 18, 2, STEEL, k=0.3)                  # maçarico-braço
    o += P_([(66, -64), (86, -60), (66, -56)], "#7fd3ff", k=0.2) + E(88, -60, 6, 6, "#ffffff", k=0.2)
    o += "".join(f'<path d="M88,-60 l{dx},{dy}" stroke="#ffd36b" stroke-width="2" stroke-linecap="round"/>' for dx, dy in ((10, -8), (12, 2), (8, 10), (2, 12)))
    return o


ARMAS = [("T01 · FORNALHA", fornalha, "#4f86d9"), ("T02 · EMPILHADEIRA", empilhadeira, "#5cc45c"), ("T03 · BOLA DE DEMOLIÇÃO", bola, "#f06aa8"),
         ("T05 · BROCA", broca, "#f2c84b"), ("T06 · SOLDADOR", soldador, "#4f86d9")]

REGRAS = ["1  O robô ENTRA na máquina: a cabeça do piloto aparece inteira numa JANELA grande (vigia, cabine ou cúpula).",
          "2  FAIXA NA COR DO JOGADOR sempre no mesmo lugar do casco: quem é quem em 1 segundo.",
          "3  Máquina ≈ 1,5× o robô; casco arredondado e grosso, papel e giz, sem contorno.",
          "4  A FERRAMENTA vira um braço grande à frente (bocal, garfo, broca, maçarico) — mostra para onde ataca.",
          "5  Pés de máquina (pistões com sapata, rodas, esteira); fumaça, brasa ou faísca dizem que está LIGADA."]


def prancha():
    W, H = 1920, 1300
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 56, "ARMADURAS — NOVO CONCEITO: MÁQUINA PILOTADA (vale para todas, atuais e futuras)", 34)]
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
        b.append(f'<g transform="translate({cx - 30},{gy}) scale(2.6)">{fn(col)}</g>')
        b.append(label(cx, gy + 40, "na cor de outro jogador:", 15, "#2a4a58", "middle", 600))
        gy2 = 1060
        b.append(f'<rect x="{x + 16}" y="{gy2}" width="{cw - 32}" height="6" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 30},{gy2}) scale(1.3)">{fn(["#5cc45c", "#f06aa8", "#f2c84b", "#4f86d9", "#f06aa8"][i])}</g>')
        gy3 = 1240
        b.append(label(cx, gy3 - 110, "tamanho de jogo, ao lado do robô:", 15, "#2a4a58", "middle", 600))
        b.append(f'<rect x="{x + 60}" y="{gy3}" width="{cw - 120}" height="5" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 60},{gy3})">{eu.desenha(0, "#f06aa8", "parado")}</g>')
        b.append(f'<g transform="translate({cx + 30},{gy3}) scale(0.8)">{fn(col)}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


if __name__ == "__main__":
    svg, w, h = prancha()
    queue(svg, os.path.join(HERE, "svg/armaduras_conceito.svg"), os.path.join(ab.OUT, "armaduras_conceito.png"), w, h, 1)
    print("prancha:", render_all())
