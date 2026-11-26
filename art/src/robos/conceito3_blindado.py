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


_fid = [0]


def faixa(x, y, w, h, n=4, ang=1.0):
    """Placa com listras diagonais de perigo (laranja/escuro), recortada no retângulo."""
    _fid[0] += 1
    cid = f"fx{_fid[0]}"
    out = f'<clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2"/></clipPath>' + R(x, y, w, h, 2, HAZ, k=0.4)
    st = max(min(w, h) / 2.2, 3.0)
    out += f'<g clip-path="url(#{cid})">'
    xx = x - h
    while xx < x + w + h:
        out += f'<path d="M{xx:.1f},{y + h:.1f} L{xx + h:.1f},{y:.1f} L{xx + h + st:.1f},{y:.1f} L{xx + st:.1f},{y + h:.1f} Z" fill="{HAZ_D}" opacity="0.88"/>'
        xx += st * 2
    return out + "</g>"


def marreta_cabeca():
    """Cabeça de aço detalhada (espaço da pegada: +x para a cabeça)."""
    o = R(40, -17, 30, 34, 3, STEEL, k=0.6, dark=STEEL_D, light=STEEL_L)               # bloco
    o += R(40, -17, 30, 6, 2, STEEL_L, k=0.35)                                            # chanfro de cima (luz)
    o += R(40, 11, 30, 6, 2, STEEL_D, k=0.35)                                             # chanfro de baixo (sombra)
    o += R(67, -19, 7, 38, 2.5, shade(STEEL, -0.18), k=0.45) + R(67, -19, 7, 5, 1.5, STEEL_L, k=0.3)   # face de batida (frente)
    o += R(36, -18, 6, 36, 2, shade(STEEL, -0.25), k=0.4)                                 # face de trás
    o += faixa(49, -17, 12, 34, n=3)                                                      # faixa de perigo
    for x, y in ((44, -12), (44, 12), (64, -12), (64, 12)):                                # parafusos
        o += f'<circle cx="{x}" cy="{y}" r="1.7" fill="{STEEL_D}"/><circle cx="{x - 0.5}" cy="{y - 0.5}" r="0.7" fill="{STEEL_L}"/>'
    o += f'<path d="M62,-6 l4,3 M45,4 l3,-2 M69,6 l2,5 M68,-12 l3,4" stroke="#eef2f5" stroke-width="0.9" opacity="0.8"/>'  # arranhões
    o += f'<path d="M70,-19 l2,0 l1,3 Z M71,14 l2,1 l-1,3 Z" fill="#eef2f5" opacity="0.7"/>'                                   # lascas
    return o


def marreta_cabo():
    """Cabo detalhado: madeira com veios, colar rebitado, empunhadura emborrachada, ponteira."""
    o = R(-24, -3, 62, 6, 2.5, WOOD, k=0.5, dark=WOOD_D)
    o += f'<path d="M-8,-1 C4,-2 14,0 26,-1.2 M-4,1.4 C8,0.6 18,2 30,1" stroke="{WOOD_D}" stroke-width="0.8" fill="none" opacity="0.7"/>'
    o += R(30, -4.5, 8, 9, 2, MEC, k=0.4) + R(30, -4.5, 8, 2.2, 1, MEC_L, k=0.2)            # colar
    o += f'<circle cx="32.5" cy="0" r="1" fill="{MEC_D}"/><circle cx="35.5" cy="0" r="1" fill="{MEC_D}"/>'
    o += R(-24, -4, 18, 8, 3, "#3a3f4a", k=0.45)                                            # empunhadura
    o += "".join(f'<path d="M{-22 + i * 4},-4 l2,8" stroke="#5a606c" stroke-width="1.3"/>' for i in range(5))
    o += R(-29, -4.5, 6, 9, 2.5, STEEL, k=0.4, dark=STEEL_D) + f'<circle cx="-26" cy="0" r="1.1" fill="{STEEL_D}"/>'   # ponteira
    return o


def marreta(g, ang):
    """Marreta de demolição detalhada; pegada da frente em g; 2ª pegada 16 px atrás."""
    body = marreta_cabo() + marreta_cabeca()
    g2 = (g[0] - math.cos(math.radians(ang)) * 16, g[1] - math.sin(math.radians(ang)) * 16)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def marreta_antiga():
    body = R(-24, -2.8, 66, 5.6, 2.5, WOOD, dark=WOOD_D)
    body += R(40, -15, 26, 30, 4, STEEL, dark=STEEL_D, light=STEEL_L)
    body += faixa(44, -15, 9, 30, n=2) + R(60, -15, 6, 30, 2, STEEL_D, k=0.3)
    body += R(-24, -3.6, 10, 7.2, 2.5, MEC_D)
    return body


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


def prancha_arma():
    W, H = 1920, 1120
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 60, "MARRETA DE DEMOLIÇÃO — mais detalhe (antes × depois)", 38)]
    b.append(f'<rect x="25" y="95" width="900" height="600" rx="20" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 140, "ANTES", 26, "#6b5a70", "start") + f'<g transform="translate(250,250) scale(5)">{marreta_antiga()}</g>')
    b.append(label(60, 400, "DEPOIS", 26, INK, "start") + f'<g transform="translate(250,520) scale(5)">{marreta_cabo()}{marreta_cabeca()}</g>')
    notas = ["aço com chanfro: topo claro, base escura", "faces de batida reforçadas (frente e trás)", "faixa de perigo + 4 parafusos",
             "arranhões e lascas de uso", "colar de metal rebitado no encaixe", "veios na madeira",
             "empunhadura emborrachada + ponteira de aço"]
    for i, t in enumerate(notas):
        b.append(label(60 + (i % 2) * 430, 640 + (i // 2) * 0 if False else 620 + (i // 2) * 0, "", 1))
    for i, t in enumerate(notas):
        b.append(label(960 + 30, 0, "", 1))
    b.append(f'<rect x="945" y="95" width="950" height="600" rx="20" fill="#ffffff" opacity="0.5"/>')
    gy = 640
    b.append(f'<rect x="965" y="{gy}" width="910" height="10" rx="4" fill="#c9b99a"/>')
    for pk, px in (("heroi", 1120), ("guarda", 1400), ("golpe", 1610)):
        b.append(f'<g transform="translate({px},{gy}) scale(2.6)">{robo("#4f86d9", POSES[pk])}</g>')
    b.append(f'<rect x="25" y="715" width="1870" height="380" rx="20" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 760, "O que mudou na marreta", 24, INK, "start"))
    for i, t in enumerate(notas):
        b.append(label(60 + (i % 2) * 520, 805 + (i // 2) * 40, "• " + t, 20, "#2a4a58", "start", 600))
    b.append(label(1380, 760, "no jogo (1,35x)", 20, "#2a4a58"))
    b.append(f'<rect x="1180" y="1000" width="420" height="8" fill="#c9b99a"/>')
    for k, c in enumerate(["#4f86d9", "#f06aa8"]):
        b.append(f'<g transform="translate({1270 + k * 200},1000) scale(1.35)">{robo(c, POSES["guarda" if k == 0 else "heroi"])}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


def main():
    os.makedirs(OUT, exist_ok=True)
    svg, w, h = prancha()
    queue(svg, f"{SRC}/c3_blindado.svg", os.path.join(OUT, "c3_blindado.png"), w, h, 1)
    svg, w, h = prancha_arma()
    queue(svg, f"{SRC}/c4_marreta.svg", os.path.join(OUT, "c4_marreta.png"), w, h, 1)
    print("blindado:", render_all())


if __name__ == "__main__":
    main()
