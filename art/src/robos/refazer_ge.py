"""PRANCHA — Guindaste e Escavadeira REFEITOS do zero (pedido 2026-11-27: "refazer completamente arte e animação").
3 opções de cada, no estilo A27 (cabeça grande legível, membros grossos como o Marretão), papel e giz.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/refazer_ge.py → art/out/robos_v2/refazer_ge.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import anim_blindado as ab  # noqa: E402
import conceito3_blindado as cb  # noqa: E402
import elenco_uch as eu  # noqa: E402
from elenco import label, INK  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

R, E, S, P_ = cb.R, cb.E, cb.S, cb.P
YEL, YEL_D = eu.YEL, eu.YEL_D
STEEL, STEEL_D, STEEL_L = cb.STEEL, cb.STEEL_D, cb.STEEL_L
SCREEN = eu.SCREEN
GLASS = "#7fd3ff"


def tela(x, y, w, h, face, r=4.2, gap=10):
    return R(x, y, w, h, 6, SCREEN, k=0.35) + eu.olhos_tela(face, x + w / 2 - gap / 2 + 1, y + h / 2, r, gap)


def boot(w):
    return lambda en, b: eu.botina(en, b, w)


# ================================================================ GUINDASTE
# G1 MASTRO — corpo de torre treliçada, cabeça-cabine com vidro, gancho na corrente
def g1_head(col, pose):
    h = R(-18, -26, 38, 32, 8, col, k=0.7) + R(-18, -26, 38, 8, 5, shade(col, 0.2), k=0.3)
    h += tela(-6, -18, 26, 20, pose.get("face", "foco"))
    h += R(-12, -36, 30, 7, 3, YEL, k=0.4, dark=YEL_D)                       # lança curtinha no teto
    h += f'<path d="M-10,-33 l6,-3 l6,3 l6,-3 l6,3 l6,-3" stroke="{YEL_D}" stroke-width="1.6" fill="none"/>'
    h += E(18, -40, 3.4, 3.4, "#ffb22e", k=0.2)
    return h


def g1_torso(col, pose):
    t = R(-10, -26, 20, 27, 4, col, k=0.6)
    for y in (-24, -15, -6):
        t += f'<path d="M-8,{y} L8,{y + 8} M8,{y} L-8,{y + 8}" stroke="{shade(col, -0.35)}" stroke-width="2"/>'
    return t + cb.faixa(-10, -3, 20, 4, n=4)


G1 = dict(nome="G1 · MASTRO", ideia="torre treliçada + cabine de vidro; gancho na corrente",
          hip_w=6, leg=(12, 12, 7, 6.5), foot_h=4, arm=(11, 11, 6), sh_b=(-8, -22), sh_f=(8, -22), torso_h=26, neck=(1, -26),
          torso=g1_torso, head=g1_head, weapon=eu.gancho, hand=eu.mao, boot=boot(1.1))
G1_P = {"parado": dict(hip=(0, -24), lean=3, feet=[(-10, 0), (10, 0)], grip=(13, -26), ang=60, chain_L=16, chain_sag=3, bk=(-12, -18)),
        "golpe": dict(hip=(0, -23), lean=12, head=-5, feet=[(-15, 0), (16, 0)], grip=(14, -46), ang=-10, face="raiva", bk=(-14, -22))}


# G2 LANÇA — cabeça de olhão-lente GRANDE com moldura de cabine; segura a lança treliçada com o gancho na ponta
def g2_head(col, pose):
    f = pose.get("face", "foco")
    h = E(0, -10, 20, 18, col, k=0.7) + E(-2, -20, 14, 6, shade(col, 0.2), k=0.3)
    h += E(4, -9, 13, 13, "#2a2f38", k=0.3) + E(4, -9, 10, 10, GLASS, k=0.2)
    h += eu.olho_unico(4, -9, 8.5, f)
    h += R(-22, -14, 5, 10, 2, YEL, k=0.3) + E(-12, -28, 3, 3, "#ffb22e", k=0.2)
    return h


def g2_torso(col, pose):
    return S("M-11,0 C-14,-8 -11,-22 0,-23 C11,-22 14,-8 11,0 Z", col, (-15, -24, 15, 1), k=0.6) + R(-11, -6, 22, 4, 2, YEL, k=0.3)


def lanca(g, ang, pose):
    L = 44
    body = R(-6, -4, L + 6, 8, 2, YEL, k=0.5, dark=YEL_D)
    body += "".join(f'<path d="M{x},-3 L{x + 5},3 L{x + 10},-3" stroke="{YEL_D}" stroke-width="1.6" fill="none"/>' for x in range(-4, L - 4, 10))
    body += R(-10, -5, 8, 10, 2, "#3a3f4a", k=0.3)
    o = f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>'
    tip = (g[0] + math.cos(math.radians(ang)) * L, g[1] + math.sin(math.radians(ang)) * L)
    drop = 16 if pose.get("face") != "raiva" else 10
    o += f'<path d="M{tip[0]:.1f},{tip[1]:.1f} v{drop}" stroke="{STEEL_D}" stroke-width="1.8" stroke-dasharray="3 1.5"/>'
    o += f'<path d="M{tip[0]:.1f},{tip[1] + drop:.1f} v5 a6,6 0 1 1 -9,5" stroke="{STEEL}" stroke-width="4.5" fill="none" stroke-linecap="round"/>'
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return o, g, g2


G2 = dict(nome="G2 · LANÇA", ideia="olhão-lente gigante; empunha a lança do guindaste com o gancho na ponta",
          hip_w=6, leg=(12, 13, 7, 6.5), foot_h=4, arm=(11, 11, 6), sh_b=(-7, -18), sh_f=(7, -18), torso_h=22, neck=(1, -22),
          torso=g2_torso, head=g2_head, weapon=lanca, hand=eu.mao, boot=boot(1.1))
G2_P = {"parado": dict(hip=(0, -24), lean=3, feet=[(-10, 0), (10, 0)], grip=(10, -22), ang=-60),
        "golpe": dict(hip=(0, -22), lean=18, head=-4, feet=[(-15, 0), (17, 0)], grip=(16, -26), ang=-4, face="raiva")}


# G3 GARRA — baixote de cabine quadrada, braço telescópico com garra de 3 dedos
def g3_head(col, pose):
    h = R(-20, -24, 42, 28, 6, YEL, k=0.6, dark=YEL_D) + R(-14, -20, 32, 20, 4, col, k=0.4)
    h += tela(-6, -18, 22, 16, pose.get("face", "foco"), 3.8, 9)
    h += R(-22, -28, 46, 5, 2, shade(YEL_D, -0.1), k=0.3) + E(-14, -32, 3.2, 3.2, "#ffb22e", k=0.2)
    return h


def g3_torso(col, pose):
    return R(-13, -22, 26, 23, 8, col, k=0.6) + R(-8, -16, 16, 10, 4, shade(col, 0.25), k=0.3) + cb.faixa(-13, -4, 26, 4, n=5)


def garra(g, ang, pose):
    ext = 30 if pose.get("face") != "raiva" else 46
    body = R(-8, -4, 16, 8, 3, "#3a3f4a", k=0.3) + R(4, -3, ext - 6, 6, 2, STEEL, k=0.4, dark=STEEL_D) + R(4, -5, 12, 10, 3, YEL, k=0.3, dark=YEL_D)
    x = ext
    body += E(x, 0, 5, 5, STEEL_D, k=0.2)
    for a in (-35, 0, 35):
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        body += f'<path d="M{x},0 L{x + c * 10:.1f},{s * 10:.1f} L{x + c * 14 + s * 4:.1f},{s * 14 - c * 4 * (1 if a >= 0 else -1):.1f}" stroke="{STEEL_D}" stroke-width="3.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    g2 = (g[0] - math.cos(math.radians(ang)) * 8, g[1] - math.sin(math.radians(ang)) * 8)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


G3 = dict(nome="G3 · GARRA", ideia="cabine quadrada; braço que estica com garra (agarra e puxa)",
          hip_w=7, leg=(10, 10, 8, 7.5), foot_h=4, arm=(10, 10, 6.5), sh_b=(-9, -17), sh_f=(9, -17), torso_h=22, neck=(1, -22),
          torso=g3_torso, head=g3_head, weapon=garra, hand=eu.mao, boot=boot(1.2))
G3_P = {"parado": dict(hip=(0, -20), lean=3, feet=[(-11, 0), (11, 0)], grip=(13, -16), ang=-20),
        "golpe": dict(hip=(0, -19), lean=14, feet=[(-15, 0), (16, 0)], grip=(18, -20), ang=0, face="raiva")}


# ================================================================ ESCAVADEIRA
def cacamba_grande(g, ang, pose, k=1.0):
    body = R(-8, -5, 14, 10, 3, "#4a505c", k=0.4) + R(2, -4, 10, 8, 2, STEEL, k=0.3)            # pistão hidráulico
    body += S(f"M8,{-18 * k} L{34 * k},{-16 * k} C{39 * k},{-6 * k} {39 * k},{8 * k} {32 * k},{15 * k} L8,{13 * k} Z", YEL, (7, -19 * k, 40 * k, 16 * k), k=0.6, dark=YEL_D)
    for i in range(4):
        y = (-12 + i * 7.5) * k
        body += P_([(32 * k, y), (41 * k, y + 2.5 * k), (32 * k, y + 5 * k)], STEEL, k=0.2)
    body += R(10, -16 * k, 4, 28 * k, 1.5, YEL_D, k=0.2)
    g2 = (g[0] - math.cos(math.radians(ang)) * 6, g[1] - math.sin(math.radians(ang)) * 6)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


# E1 CABINE — a cabeça é a cabine da escavadeira (amarela, janela inclinada com olhos), corpo redondo e pesado
def e1_head(col, pose):
    h = S("M-20,6 L-20,-22 C-20,-28 -14,-30 -8,-30 L14,-30 L24,-10 L24,6 Z", YEL, (-21, -31, 25, 7), k=0.7, dark=YEL_D)
    h += S("M-6,-24 L12,-24 L19,-9 L19,0 L-6,0 Z", SCREEN, (-7, -25, 20, 1), k=0.35)
    h += eu.olhos_tela(pose.get("face", "foco"), 2, -11, 4, 10)
    h += R(-22, 2, 48, 6, 2.5, col, k=0.4) + R(-18, -36, 7, 7, 2, cb.MEC_D, k=0.2) + E(-14.5, -38, 3.4, 3, "#ffb22e", k=0.2)
    return h


def e1_torso(col, pose):
    return (S("M-18,0 C-22,-12 -16,-28 0,-28 C16,-28 22,-12 18,0 Z", col, (-23, -29, 23, 1), k=0.7)
            + S("M-10,-5 C-12,-12 -8,-20 0,-20 C8,-20 11,-12 9,-5 Z", shade(col, 0.22), (-13, -21, 12, -4), k=0.3) + cb.faixa(-18, -5, 36, 5, n=6))


E1 = dict(nome="E1 · CABINE", ideia="a cabeça É a cabine amarela; braço hidráulico com caçamba",
          hip_w=9, leg=(9, 9, 9, 8.5), foot_h=5, arm=(12, 12, 8), sh_b=(-12, -22), sh_f=(12, -22), torso_h=28, neck=(2, -30),
          torso=e1_torso, head=e1_head, weapon=cacamba_grande, hand=lambda e, b: (E(e[0], e[1], 5.5, 5.5, eu.GLOVE_D, k=0.3) if b else ""),
          boot=boot(1.4))
E1_P = {"parado": dict(hip=(0, -18), lean=4, feet=[(-13, 0), (13, 0)], grip=(22, -14), ang=10, bk=(-20, -10)),
        "golpe": dict(hip=(0, -18), lean=-6, head=-6, feet=[(-15, 0), (15, 0)], grip=(20, -46), ang=-80, face="raiva", bk=(-22, -16))}


# E2 TRATOR — cabeça com LÂMINA de trator na frente (olhos espiando por cima), esteira na cintura
def e2_head(col, pose):
    h = R(-16, -26, 34, 30, 8, col, k=0.7) + R(-16, -26, 34, 7, 4, shade(col, 0.2), k=0.3)
    h += tela(-6, -20, 24, 12, pose.get("face", "foco"), 3.6, 9)
    h += S("M10,-6 C20,-8 26,-2 26,6 C26,12 20,14 10,12 Z", YEL, (9, -9, 27, 15), k=0.5, dark=YEL_D)                # lâmina
    h += f'<path d="M12,-3 C20,-4 23,1 23,6" stroke="{shade(YEL, 0.3)}" stroke-width="2" fill="none"/>'
    h += R(-8, -34, 8, 8, 2, cb.MEC_D, k=0.2) + f'<circle cx="-4" cy="-38" r="3" fill="#8a8a8a" opacity="0.6"/>'      # escapamento
    return h


def e2_torso(col, pose):
    t = R(-17, -26, 34, 22, 7, col, k=0.6)
    t += R(-19, -8, 38, 9, 4.5, "#3a3f4a", k=0.4) + "".join(E(x, -3.5, 2.6, 2.6, STEEL, k=0.15) for x in (-13, -6, 1, 8, 15))
    return t


E2 = dict(nome="E2 · TRATOR", ideia="lâmina de trator no rosto; esteira na cintura; caçamba",
          hip_w=9, leg=(9, 9, 9, 8.5), foot_h=5, arm=(12, 12, 8), sh_b=(-12, -20), sh_f=(12, -20), torso_h=26, neck=(1, -26),
          torso=e2_torso, head=e2_head, weapon=cacamba_grande, hand=lambda e, b: E(e[0], e[1], 5.5, 5.5, eu.GLOVE_D if b else eu.GLOVE, k=0.3),
          boot=boot(1.4))
E2_P = dict(E1_P)


# E3 TATU — redondão baixinho, cabine-cúpula de vidro com faróis, caçamba enorme nas duas mãos
def e3_head(col, pose):
    h = E(0, -12, 18, 15, YEL, k=0.6, dark=YEL_D) + E(2, -14, 13, 10, GLASS, k=0.3) + E(-2, -18, 6, 3, "#ffffff", k=0.1)
    f = pose.get("face", "foco")
    h += E(-1, -12, 4.5, 4.5, "#fff6c2", k=0.2) + E(9, -12, 4.5, 4.5, "#fff6c2", k=0.2)                    # faróis-olhos
    h += eu.olhos_tela(f, -1, -12, 3.2, 10).replace("#ffffff", "#fff6c2")
    h += R(-19, -2, 38, 5, 2, YEL_D, k=0.3)
    return h


def e3_torso(col, pose):
    return E(0, -16, 22, 18, col, k=0.7) + E(0, -12, 13, 10, shade(col, 0.22), k=0.3) + cb.faixa(-20, -6, 40, 5, n=7)


def cacamba_xl(g, ang, pose):
    return cacamba_grande(g, ang, pose, 1.35)


E3 = dict(nome="E3 · TATU", ideia="redondão baixinho, cúpula de vidro com faróis; caçamba XL",
          hip_w=10, leg=(7, 7, 9.5, 9), foot_h=5, arm=(11, 11, 8), sh_b=(-14, -20), sh_f=(14, -20), torso_h=32, neck=(2, -30),
          torso=e3_torso, head=e3_head, weapon=cacamba_xl, hand=lambda e, b: E(e[0], e[1], 5.5, 5.5, eu.GLOVE_D if b else eu.GLOVE, k=0.3),
          boot=boot(1.5))
E3_P = {"parado": dict(hip=(0, -14), lean=4, feet=[(-13, 0), (13, 0)], grip=(24, -16), ang=10),
        "golpe": dict(hip=(0, -14), lean=-6, head=-6, feet=[(-15, 0), (15, 0)], grip=(20, -40), ang=-75, face="raiva")}

OPCOES = [("GUINDASTE", [(G1, G1_P), (G2, G2_P), (G3, G3_P)]), ("ESCAVADEIRA", [(E1, E1_P), (E2, E2_P), (E3, E3_P)])]


def prancha():
    W, H = 1920, 1500
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 54, "REFAZER DO ZERO — escolha 1 Guindaste e 1 Escavadeira", 38)]
    cols = ["#f06aa8", "#4f86d9", "#5cc45c"]
    for r, (titulo, ops) in enumerate(OPCOES):
        y0 = 90 + r * 700
        b.append(label(40, y0 + 34, titulo, 30, INK, "start"))
        for i, (spec, poses) in enumerate(ops):
            x = 20 + i * 630
            cx = x + 305
            b.append(f'<rect x="{x}" y="{y0 + 50}" width="610" height="630" rx="22" fill="#ffffff" opacity="0.55"/>')
            b.append(label(cx, y0 + 92, spec["nome"], 30, INK))
            b.append(label(cx, y0 + 122, spec["ideia"], 16, "#2a4a58", "middle", 600))
            gy = y0 + 430
            b.append(f'<rect x="{x + 20}" y="{gy}" width="570" height="8" rx="3" fill="#c9b99a"/>')
            b.append(f'<g transform="translate({x + 160},{gy}) scale(3.4)">{eu.corpo_generico(spec, cols[i], poses["parado"])}</g>')
            b.append(f'<g transform="translate({x + 400},{gy}) scale(3.0)">{eu.corpo_generico(spec, cols[(i + 1) % 3], poses["golpe"])}</g>')
            b.append(label(x + 160, gy + 30, "parado", 16, "#2a4a58") + label(x + 430, gy + 30, "golpe", 16, "#2a4a58"))
            # tamanho real de jogo (~80 px) ao lado do Marretão
            sy = y0 + 640
            b.append(label(cx, sy - 90, "tamanho de jogo, ao lado do Marretão", 15, "#2a4a58", "middle", 600))
            b.append(f'<rect x="{x + 150}" y="{sy}" width="310" height="5" fill="#c9b99a"/>')
            b.append(f'<g transform="translate({cx - 60},{sy}) scale(1.0)">{eu.desenha(0, "#4f86d9", "parado")}</g>')
            b.append(f'<g transform="translate({cx + 50},{sy}) scale(1.0)">{eu.corpo_generico(spec, cols[i], poses["parado"])}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


if __name__ == "__main__":
    svg, w, h = prancha()
    queue(svg, os.path.join(HERE, "svg/refazer_ge.svg"), os.path.join(ab.OUT, "refazer_ge.png"), w, h, 1)
    print("prancha:", render_all())
