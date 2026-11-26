"""CONCEITO 3 (2026-11-26): direção da referência do usuário (docs/referencias/ref7_usuario_robo_blindado.jpg) traduzida
para o papel e giz do jogo: robô BLINDADO de demolição — placas de armadura na cor do jogador sobre juntas mecânicas
cinza, ombreiras grandes com número, joelheiras creme, punhos e botas grandes (sola laranja), faixa de perigo no peito,
capacete com viseira escura e olhos laranja acesos, giroflex, marreta enorme com faixas de perigo.
Um robô só (o conceito), em 3 poses + tamanho de jogo. Copia o ESTILO, não a imagem.
Rodar: python3 art/src/robos/conceito3_blindado.py → art/out/robos_v2/c3_blindado.png
"""
import base64
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
from elenco import S, label, INK, ik  # noqa: E402
from conceitos2 import P, E, R, taper, smear, impacto, rot  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/robos_v2")
SRC = os.path.join(ROOT, "art/src/robos/svg")
MEC, MEC_D, MEC_L = "#6b7380", "#474d58", "#8f98a4"     # juntas e mecânica
CREME, CREME_D = "#e8dcc2", "#bfae8c"                     # joelheiras / cotoveleiras
HAZ, HAZ_D = "#f2a33b", "#2a1a2e"                        # faixa de perigo
GLOW, SOLA = "#ffa23a", "#f08a2b"
STEEL, STEEL_D, STEEL_L = "#a2abb5", "#6b7783", "#cdd4da"
WOOD, WOOD_D = "#a8683a", "#6e3f20"


def faixa(x, y, w, h, n=4, ang=1.0):
    """Placa com listras de perigo (laranja/escuro)."""
    out = R(x, y, w, h, 2, HAZ, k=0.4)
    step = w / n
    for i in range(n + 1):
        x0 = x + i * step - h * 0.5
        out += f'<path d="M{max(x0, x):.1f},{y + h:.1f} L{min(x0 + h * ang, x + w):.1f},{y:.1f} L{min(x0 + h * ang + step * 0.45, x + w):.1f},{y:.1f} L{min(max(x0 + step * 0.45, x), x + w):.1f},{y + h:.1f} Z" fill="{HAZ_D}" opacity="0.85"/>'
    return out


def marreta(g, ang):
    """Marreta de demolição grande: bloco de aço com faixa de perigo; pegada da frente em g; 2ª pegada 16 px atrás."""
    body = R(-24, -2.8, 66, 5.6, 2.5, WOOD, dark=WOOD_D)
    body += R(40, -15, 26, 30, 4, STEEL, dark=STEEL_D, light=STEEL_L)
    body += faixa(44, -15, 9, 30, n=2) + R(60, -15, 6, 30, 2, STEEL_D, k=0.3)
    body += R(-24, -3.6, 10, 7.2, 2.5, MEC_D)
    g2 = (g[0] - math.cos(math.radians(ang)) * 16, g[1] - math.sin(math.radians(ang)) * 16)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def braco(col, sh, el, end, back, punho_aberto=False):
    """Braço blindado: umero cinza com placa, cotovelo creme, antebraço-manopla larga no punho, punho grande."""
    k = -0.38 if back else 0.0
    out = taper(sh, el, 8, 7, shade(MEC, k * 0.5))
    mid = ((sh[0] + el[0]) / 2, (sh[1] + el[1]) / 2)
    out += taper(((sh[0] + mid[0]) / 2, (sh[1] + mid[1]) / 2), mid, 11, 10, shade(col, -0.15 + k))            # placa do braço
    wr = (el[0] + (end[0] - el[0]) * 0.78, el[1] + (end[1] - el[1]) * 0.78)
    out += taper(el, wr, 10, 14, shade(col, k))                                                              # manopla
    out += taper(((el[0] + wr[0]) / 2, (el[1] + wr[1]) / 2), wr, 13.5, 14.5, shade(col, 0.15 + k))
    out += E(el[0], el[1], 5.2, 5.2, shade(CREME, k), k=0.3)                                                  # cotoveleira
    a = math.degrees(math.atan2(end[1] - el[1], end[0] - el[0]))
    fist = R(-7, -7.5, 15, 15, 4.5, shade(MEC_D, k), k=0.45) + f'<path d="M3,-6 v12 M7,-6 v12" stroke="{shade(MEC, k)}" stroke-width="1.4"/>'
    out += f'<g transform="translate({end[0]:.1f},{end[1]:.1f}) rotate({a:.1f})">{fist}</g>'
    return out


def ombreira(col, sh, back, num=True):
    k = -0.38 if back else 0.0
    out = E(sh[0], sh[1] - 1, 10.5, 9.5, shade(col, k), k=0.6) + E(sh[0], sh[1] - 4.5, 9, 4.5, shade(col, 0.22 + k), k=0.3)
    out += R(sh[0] - 10, sh[1] + 4.5, 20, 3, 1.5, shade(MEC_D, k), k=0.3)
    if num and not back:
        out += f'<text x="{sh[0] - 6:.1f}" y="{sh[1] + 3:.1f}" font-family="Fredoka, Arial" font-weight="700" font-size="8" fill="#f4f1ea">01</text>'
    return out


def perna(col, hp, knee, end, back):
    k = -0.38 if back else 0.0
    out = taper(hp, knee, 12, 10, shade(MEC, k * 0.5))
    out += taper(hp, ((hp[0] + knee[0]) / 2 + 1, (hp[1] + knee[1]) / 2), 14, 12, shade(col, -0.1 + k))      # coxa blindada
    ank = (end[0], end[1] - 2)
    out += taper(knee, ank, 11, 14, shade(col, k))                                                            # caneleira (larga embaixo)
    out += taper(((knee[0] + ank[0]) / 2, (knee[1] + ank[1]) / 2), ank, 14, 15, shade(col, 0.14 + k))
    out += R(knee[0] - 6, knee[1] - 6, 12, 11, 3.5, shade(CREME, k), k=0.35) + R(knee[0] - 4, knee[1] + 1, 8, 2, 1, shade(CREME_D, k), k=0.2)   # joelheira
    bx, by = end[0], end[1] + 5
    out += P([(bx - 9, by - 9), (bx + 9, by - 9), (bx + 15, by - 3), (bx + 15, by), (bx - 10, by)], shade(MEC_D, k), k=0.45)   # bota
    out += R(bx - 11, by - 1, 27, 4.5, 2, shade(SOLA, k), k=0.35) + R(bx + 9, by - 8, 6, 6, 2, shade(SOLA, k), k=0.3)          # sola + biqueira
    return out


def corpo(col, hip, lean, pose):
    """Quadril com cinto e bolsa, abdômen mecânico, peitoral blindado com faixa de perigo, capacete."""
    b = R(-13, -9, 26, 10, 3, MEC, k=0.45) + R(-14, -11, 28, 4.5, 1.5, "#5a3d2b", k=0.3) + R(-3, -12, 7, 6, 1.5, "#c9b07a", k=0.3)   # cinto + fivela
    b += R(-15, -9, 9, 9, 2.5, "#8a5a33", k=0.35)                                               # bolsa de ferramentas
    b += R(-9, -21, 18, 11, 3, MEC_D, k=0.4) + f'<path d="M-8,-17 h16 M-8,-13.5 h16" stroke="{MEC}" stroke-width="1.6"/>'   # abdômen
    b += P([(-15, -46), (17, -46), (19, -34), (13, -20), (-11, -20), (-16, -32)], col, k=0.75)  # peitoral
    b += P([(-13, -45), (15, -45), (16, -39), (-14, -39)], shade(col, 0.22), k=0.35)
    b += faixa(-2, -36, 17, 9, n=3)                                                            # placa de perigo
    b += f'<circle cx="-11" cy="-26" r="1.5" fill="{shade(col, -0.45)}"/><circle cx="14" cy="-24" r="1.5" fill="{shade(col, -0.45)}"/>'
    b += R(-5, -51, 11, 7, 2.5, MEC_D, k=0.35)                                                  # pescoço
    hx, hy = 3, -60
    face = pose.get("face", "foco")
    h = E(0, 0, 13, 12.5, col, k=0.6) + E(-1, -5, 12, 6.5, shade(col, 0.2), k=0.3)              # capacete
    h += R(-2, -4, 16, 10, 4, "#1d2128", k=0.3)                                                  # viseira
    if face == "raiva":
        h += f'<path d="M0,-1 L6,1.5 L6,4 L0,2 Z" fill="{GLOW}"/><path d="M8,1.5 L13,-1 L13,1.5 L8,4 Z" fill="{GLOW}"/>'
    else:
        h += f'<rect x="0" y="-0.5" width="5.5" height="3.2" rx="1.6" fill="{GLOW}"/><rect x="7.5" y="-0.5" width="5.5" height="3.2" rx="1.6" fill="{GLOW}"/>'
    h += f'<circle cx="2.5" cy="1" r="5" fill="{GLOW}" opacity="0.18"/>'
    h += E(-8, 2, 4.5, 4.5, MEC, k=0.3) + E(-8, 2, 2, 2, MEC_L, k=0.2)                           # disco da orelha
    h += R(-3, -16, 6, 4, 1.5, MEC_D, k=0.3) + E(0, -18.5, 3.6, 3.4, "#ffb22e", k=0.3)            # giroflex
    h += f'<circle cx="0" cy="-18.5" r="7" fill="#ffd27a" opacity="0.25"/>'
    hd = f'<g transform="translate({hx},{hy}) rotate({pose.get("head", 0)})">{h}</g>'
    return f'<g transform="translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lean:.1f})">{b}{hd}</g>'


ST = dict(hip_w=6, thigh=19, shin=19, uarm=14, farm=15, foot_h=6, shl=(13, -41), sh_gap=22)

POSES = {
    "heroi": dict(hip=(0, -42), lean=4, head=-4, feet=[(-18, 0), (16, 0)], tool=(9, -44, -142), back_free=(-14, -22), face="foco"),
    "guarda": dict(hip=(0, -38), lean=12, head=4, feet=[(-18, 0), (18, 0)], tool=(16, -50, -58), face="foco"),
    "golpe": dict(hip=(4, -32), lean=30, head=-6, feet=[(-24, 0), (25, 0)], tool=(32, -36, 64), face="raiva", sw=(-120, 64), hit=(70, 0)),
}


def robo(col, pose):
    hip, lean = pose["hip"], pose["lean"]
    sx, sy = ST["shl"]
    sh_f = rot((hip[0] + sx, hip[1] + sy), lean, hip)
    sh_b = rot((hip[0] + sx - ST["sh_gap"], hip[1] + sy + 1), lean, hip)
    tool, g1, g2 = marreta(pose["tool"][:2], pose["tool"][2])
    out = []
    if pose.get("sw"):
        out.append(smear(g1, pose["sw"][0], pose["sw"][1], 34, 70))
    if pose.get("hit"):
        out.append(impacto(*pose["hit"]))
    bt = pose.get("back_free", g2)
    el, end = ik(sh_b, bt, ST["uarm"], ST["farm"], lambda q: q[1])
    back_arm = braco(col, sh_b, el, end, True)
    legs = []
    for i in range(2):
        hp = (hip[0] + (-ST["hip_w"] if i == 0 else ST["hip_w"]), hip[1] + 2)
        ft = pose["feet"][i]
        kn, en = ik(hp, (ft[0], ft[1] - ST["foot_h"]), ST["thigh"], ST["shin"], lambda q: q[0])
        legs.append(perna(col, hp, kn, en, i == 0))
    el, end = ik(sh_f, g1, ST["uarm"], ST["farm"], lambda q: q[1])
    front_arm = braco(col, sh_f, el, end, False)
    if pose.get("back_free"):   # herói: marreta no ombro atrás do corpo
        out += [tool, ombreira(col, sh_b, True), back_arm, legs[0], corpo(col, hip, lean, pose), legs[1], front_arm, ombreira(col, sh_f, False)]
    else:
        out += [ombreira(col, sh_b, True), back_arm, legs[0], corpo(col, hip, lean, pose), legs[1], tool, front_arm, ombreira(col, sh_f, False)]
    return "".join(out)


def prancha():
    W, H = 1920, 1180
    ref = base64.b64encode(open(os.path.join(ROOT, "docs/referencias/ref7_usuario_robo_blindado.jpg"), "rb").read()).decode()
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 60, "CONCEITO — ROBÔ BLINDADO DE DEMOLIÇÃO (sua referência → papel e giz do jogo)", 36)]
    b.append(f'<rect x="25" y="95" width="330" height="640" rx="20" fill="#ffffff" opacity="0.5"/>' + label(190, 130, "SUA REFERÊNCIA", 22, "#2a4a58"))
    b.append(f'<image href="data:image/jpeg;base64,{ref}" x="45" y="145" width="290" height="530" preserveAspectRatio="xMidYMid meet"/>')
    b.append(label(190, 715, "(só o estilo — não copiamos a imagem)", 15, "#6b5a70"))
    b.append(f'<rect x="375" y="95" width="1520" height="660" rx="20" fill="#ffffff" opacity="0.5"/>')
    gy = 660
    b.append(f'<rect x="395" y="{gy}" width="1480" height="12" rx="4" fill="#c9b99a"/>')
    for pk, px, nm in (("heroi", 620, "HERÓI (marreta no ombro)"), ("guarda", 1060, "GUARDA"), ("golpe", 1420, "GOLPE")):
        b.append(f'<g transform="translate({px},{gy}) scale(3.6)">{robo("#4f86d9", POSES[pk])}</g>')
        b.append(label(px, gy + 44, nm, 20, "#2a4a58"))
    # tamanhos de jogo
    b.append(f'<rect x="25" y="755" width="1870" height="400" rx="20" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 800, "NO JOGO, nas 4 cores", 26, INK, "start"))
    for t, (esc, x0, nm) in enumerate(((1.0, 120, "1x (tamanho de hoje, ~100 px)"), (1.35, 900, "1,35x (proposta: ~130 px, cabe o detalhe)"))):
        gy2 = 1060
        b.append(f'<rect x="{x0 - 60}" y="{gy2}" width="{700}" height="8" fill="#c9b99a"/>' + label(x0 + 290, 1110, nm, 18, "#2a4a58"))
        for k, c in enumerate(["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]):
            pz = ["guarda", "golpe", "heroi", "guarda"][k]
            b.append(f'<g transform="translate({x0 + k * 160 * esc},{gy2}) scale({esc})">{robo(c, POSES[pz])}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


def main():
    os.makedirs(OUT, exist_ok=True)
    svg, w, h = prancha()
    queue(svg, f"{SRC}/c3_blindado.svg", os.path.join(OUT, "c3_blindado.png"), w, h, 1)
    print("blindado:", render_all())


if __name__ == "__main__":
    main()
