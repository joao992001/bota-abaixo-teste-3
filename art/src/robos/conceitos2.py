"""CONCEITOS (rodada 2, 2026-11-26): o usuário achou os robôs "mal desenhados, pouco combativos, pouco articulados" e
pediu um conceito de cada direção: A industrial, B atleta, C minimalista. Mesmo papel e giz. 1 robô por direção em
3 poses de luta (guarda · golpe · pesado no ar) + tamanho de jogo. Corpo com anatomia: braço/antebraço e coxa/canela
afinando, ombro/cotovelo/joelho, postura de luta (base larga, joelhos dobrados), golpe com o corpo todo.
Rodar: python3 art/src/robos/conceitos2.py → art/out/robos_v2/c2_conceitos.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
from elenco import S, label, INK, ik  # noqa: E402
from papel import ellipse_d, rect_d  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/robos_v2")
SRC = os.path.join(ROOT, "art/src/robos/svg")
STEEL, STEEL_D, STEEL_L = "#9aa4ae", "#5f6b77", "#c9d1d8"
DARK = "#3a3f4a"
WOOD, WOOD_D = "#c98a4b", "#8a5a2b"
YEL, YEL_D = "#f2c84b", "#c49a2a"
GLOW = "#ffb347"


def P(pts, fill, k=0.6, **kw):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    d = "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts) + " Z"
    return S(d, fill, (min(xs) - 1, min(ys) - 1, max(xs) + 1, max(ys) + 1), k=k, **kw)


def E(cx, cy, rx, ry, fill, k=0.5, **kw):
    return S(ellipse_d(cx, cy, rx, ry), fill, (cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1), k=k, **kw)


def R(x, y, w, h, r, fill, k=0.5, **kw):
    return S(rect_d(x, y, w, h, r), fill, (x - 1, y - 1, x + w + 1, y + h + 1), k=k, **kw)


def taper(p, q, w1, w2, fill, k=0.55):
    """Segmento que afina (braço/antebraço, coxa/canela) com pontas arredondadas."""
    a = math.atan2(q[1] - p[1], q[0] - p[0])
    nx, ny = -math.sin(a), math.cos(a)
    pts = [(p[0] + nx * w1 / 2, p[1] + ny * w1 / 2), (q[0] + nx * w2 / 2, q[1] + ny * w2 / 2),
           (q[0] - nx * w2 / 2, q[1] - ny * w2 / 2), (p[0] - nx * w1 / 2, p[1] - ny * w1 / 2)]
    return P(pts, fill, k) + E(p[0], p[1], w1 / 2, w1 / 2, fill, k=0.4) + E(q[0], q[1], w2 / 2, w2 / 2, fill, k=0.4)


def rot(p, a, c=(0, 0)):
    s, co = math.sin(math.radians(a)), math.cos(math.radians(a))
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * co - y * s, c[1] + x * s + y * co)


def marreta(g, ang, big=1.0):
    """Marreta de obra: pegada da frente em g; segunda pegada 12 px atrás no cabo."""
    s = big
    body = (R(-18 * s, -2.4 * s, 54 * s, 4.8 * s, 2, WOOD, dark=WOOD_D) + R(34 * s, -12 * s, 18 * s, 24 * s, 3, STEEL, dark=STEEL_D, light=STEEL_L)
            + f'<rect x="{39 * s}" y="{-12 * s}" width="{4 * s}" height="{24 * s}" fill="{YEL}"/><rect x="{-18 * s}" y="{-3 * s}" width="{9 * s}" height="{6 * s}" rx="2" fill="{DARK}"/>')
    g2 = (g[0] - math.cos(math.radians(ang)) * 13, g[1] - math.sin(math.radians(ang)) * 13)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def smear(g, a0, a1, r0=30, r1=56):
    """Rastro do golpe: faixa curva clara entre os ângulos a0→a1 em torno da pegada."""
    pts = []
    n = 10
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((g[0] + math.cos(a) * r1, g[1] + math.sin(a) * r1))
    for i in range(n, -1, -1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((g[0] + math.cos(a) * r0, g[1] + math.sin(a) * r0))
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    return f'<path d="{d}" fill="#ffffff" opacity="0.55"/>'


def impacto(x, y):
    pts = []
    for i in range(16):
        rr = 16 if i % 2 == 0 else 7
        a = math.radians(i * 22.5)
        pts.append(f"{x + math.cos(a) * rr:.1f},{y - 6 + math.sin(a) * rr:.1f}")
    return (f'<polygon points="{" ".join(pts)}" fill="#ffe27a"/><ellipse cx="{x}" cy="{y}" rx="30" ry="6" fill="none" stroke="#ffffff" stroke-width="3"/>'
            + "".join(f'<path d="M{x + dx},{y - 4} l{dx * 0.4},-9" stroke="#b9ab8f" stroke-width="3" stroke-linecap="round"/>' for dx in (-22, -10, 12, 24)))


# Poses de luta (unidades = px de jogo, pés em y=0, virado para a direita).
POSES = {
    "guarda": dict(hip=(0, -36), lean=12, head=6, feet=[(-16, 0), (17, 0)], tool=(16, -50, -55), face="foco", sw=None),
    "golpe": dict(hip=(4, -30), lean=32, head=-4, feet=[(-22, 0), (24, 0)], tool=(32, -36, 62), face="raiva", sw=(-120, 62), hit=(60, 0)),
    "ar": dict(hip=(0, -62), lean=-10, head=-8, feet=[(-14, -36), (12, -28)], tool=(-10, -94, -122), face="raiva", sw=None, ar=True),
}


def montar(st, col, pose):
    """Monta o robô do estilo st: braços e pernas por IK nas pegadas/pés; tronco e cabeça desenhados pelo estilo."""
    hip = pose["hip"]
    lean = pose["lean"]
    chest = rot((hip[0], hip[1] - st["spine"]), lean, hip)
    sx, sy = st["shl"]   # ombro no espaço do tronco (gira com a inclinação)
    sh_f = rot((hip[0] + sx, hip[1] + sy), lean, hip)
    sh_b = rot((hip[0] + sx - st["sh_gap"], hip[1] + sy + 1), lean, hip)
    tool_svg, g1, g2 = marreta(pose["tool"][:2], pose["tool"][2])
    out = {"back_leg": "", "back_arm": "", "body": "", "front_leg": "", "tool": tool_svg, "front_arm": "", "fx_b": "", "fx": ""}
    if pose.get("sw"):
        out["fx_b"] = smear(g1, pose["sw"][0], pose["sw"][1])
    if pose.get("hit"):
        out["fx"] = impacto(*pose["hit"])
    # pernas
    for i, key in ((0, "back_leg"), (1, "front_leg")):
        hp = (hip[0] + (-st["hip_w"] if i == 0 else st["hip_w"]), hip[1] + 2)
        ft = pose["feet"][i]
        knee, end = ik(hp, (ft[0], ft[1] - st["foot_h"]), st["thigh"], st["shin"], lambda q: q[0])
        out[key] = st["leg"](col, hp, knee, end, i == 0)
    # braços (atrás pega a 2ª pegada; frente a 1ª)
    for i, key, sh, gp in ((0, "back_arm", sh_b, g2), (1, "front_arm", sh_f, g1)):
        el, end = ik(sh, gp, st["uarm"], st["farm"], lambda q: q[1])
        out[key] = st["arm"](col, sh, el, end, i == 0)
    out["body"] = st["body"](col, hip, chest, lean, pose)
    order = ["fx_b", "back_arm", "back_leg", "body", "front_leg", "tool", "front_arm", "fx"]
    return "".join(out[k] for k in order)


def olhos_foco(x, y, w, h, face, cor):
    """Olhos de luta: fendas na viseira; raiva = inclinadas."""
    if face == "raiva":
        return P([(x, y), (x + w, y + h * 0.6), (x + w, y + h * 1.1), (x, y + h * 0.7)], cor, k=0.3)
    return R(x, y, w, h, h / 2, cor, k=0.3)


# ---------------------------------------------------------------- A · INDUSTRIAL
def a_body(col, hip, chest, lean, pose):
    tf = f'translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lean:.1f})'
    b = R(-12, -8, 24, 10, 3, DARK)                                             # quadril
    b += P([(-17, -44), (19, -44), (15, -10), (-12, -10)], col, k=0.7)          # chassi
    b += P([(-17, -44), (19, -44), (18, -38), (-16, -38)], shade(col, 0.2), k=0.4)
    b += R(-15, -24, 31, 6, 1, YEL) + "".join(f'<path d="M{-13 + i * 6},-18 l4,-6 l3,0 l-4,6 Z" fill="{INK}"/>' for i in range(5))
    b += "".join(f'<circle cx="{x}" cy="{y}" r="1.6" fill="{shade(col, -0.4)}"/>' for x, y in ((-13, -40), (15, -40), (-10, -13), (12, -13)))
    b += R(-6, -50, 10, 7, 2, DARK)                                             # pescoço
    hx, hy = 2, -59
    hd = f'<g transform="translate({hx},{hy}) rotate({pose["head"]})">'
    hd += R(-11, -10, 24, 21, 5, STEEL, dark=STEEL_D, light=STEEL_L)            # capacete-máscara de solda
    hd += R(-2, -4, 17, 7, 2, "#1d2128", k=0.3) + olhos_foco(1, -3, 11, 4, pose["face"], GLOW)
    hd += f'<rect x="-11" y="-12" width="24" height="3.5" rx="1.5" fill="{col}"/><circle cx="-6" cy="-14" r="2.2" fill="#ff7b2e"/></g>'
    return f'<g transform="{tf}">{b}{hd}</g>'


def a_arm(col, sh, el, end, back):
    c = shade(STEEL_D, -0.2) if back else STEEL_D
    out = taper(sh, el, 9, 7, c) + taper(el, end, 9.5, 8, shade(col, -0.25) if not back else shade(col, -0.45))
    out += f'<path d="M{el[0]:.1f},{el[1]:.1f} L{(el[0] + end[0]) / 2:.1f},{(el[1] + end[1]) / 2:.1f}" stroke="{STEEL_L}" stroke-width="1.6"/>'   # pistão
    out += E(sh[0], sh[1], 7.5, 7.5, shade(col, -0.15) if not back else shade(col, -0.4), k=0.4)   # ombreira
    out += R(end[0] - 6, end[1] - 5.5, 12, 11, 3, DARK if back else "#4a505c", k=0.4)           # mão-garra
    return out


def a_leg(col, hp, knee, end, back):
    c = shade(col, -0.5) if back else shade(col, -0.3)
    out = taper(hp, knee, 11, 9, c) + taper(knee, end, 9, 8, STEEL_D if not back else shade(STEEL_D, -0.2))
    out += E(knee[0], knee[1], 5.5, 5.5, DARK, k=0.3)
    out += P([(end[0] - 8, end[1] - 4), (end[0] + 12, end[1] - 4), (end[0] + 14, end[1] + 6), (end[0] - 9, end[1] + 6)], DARK if back else "#4a505c", k=0.4)
    return out


# ---------------------------------------------------------------- B · ATLETA
def b_body(col, hip, chest, lean, pose):
    tf = f'translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lean:.1f})'
    b = P([(-8, 0), (9, 0), (7, -12), (-7, -12)], shade(col, -0.35), k=0.5)        # quadril
    b += R(-6, -14, 13, 4, 2, DARK)                                               # cintura fina
    b += P([(-15, -42), (17, -42), (9, -15), (-7, -15)], col, k=0.7)              # tronco em V
    b += P([(-6, -40), (12, -40), (7, -24), (-2, -24)], shade(col, 0.22), k=0.4)    # peitoral
    b += R(-3, -48, 8, 7, 3, shade(col, -0.4))
    hx, hy = 3, -60
    hd = f'<g transform="translate({hx},{hy}) rotate({pose["head"]})">'
    hd += E(0, 0, 10, 11, col, k=0.6) + R(-2, -5, 14, 7, 3.5, "#1d2a3a", k=0.3) + olhos_foco(2, -3.5, 9, 3.6, pose["face"], "#7ef0d0")
    hd += P([(-10, -2), (-16, -8), (-9, -8)], shade(col, -0.3), k=0.3) + "</g>"   # aleta (crista)
    return f'<g transform="{tf}">{b}{hd}</g>'


def b_arm(col, sh, el, end, back):
    c1 = shade(col, -0.45) if back else shade(col, -0.2)
    c2 = shade(col, -0.55) if back else shade(col, -0.32)
    out = taper(sh, el, 8, 6, c1) + taper(el, end, 8.5, 6, c2)
    out += E(sh[0], sh[1], 6.5, 6, shade(col, 0.15) if not back else shade(col, -0.35), k=0.4)
    out += E(end[0], end[1], 5, 5, "#f4f1ea" if not back else "#c9c2b4", k=0.4)
    return out


def b_leg(col, hp, knee, end, back):
    c1 = shade(col, -0.5) if back else shade(col, -0.25)
    out = taper(hp, knee, 10, 7, c1) + taper(knee, end, 8, 5.5, shade(col, -0.6) if back else shade(col, -0.42))
    out += E(knee[0], knee[1], 4, 4, DARK, k=0.3)
    out += P([(end[0] - 6, end[1] - 3), (end[0] + 12, end[1] - 1), (end[0] + 12, end[1] + 6), (end[0] - 7, end[1] + 6)], "#f4f1ea" if not back else "#c9c2b4", k=0.4)
    out += f'<rect x="{end[0] - 7:.1f}" y="{end[1] + 4:.1f}" width="19" height="2.5" fill="{col}"/>'
    return out


# ---------------------------------------------------------------- C · MINIMALISTA
def c_body(col, hip, chest, lean, pose):
    tf = f'translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lean:.1f})'
    b = R(-10, -9, 20, 11, 5, shade(col, -0.3))
    b += R(-14, -42, 28, 30, 9, col, k=0.7)
    b += R(-14, -42, 28, 7, 3, shade(col, 0.18), k=0.3)
    b += R(-3, -48, 8, 8, 3, shade(col, -0.4))   # pescoço
    hx, hy = 2, -56
    hd = f'<g transform="translate({hx},{hy}) rotate({pose["head"]})">'
    hd += R(-12, -11, 25, 21, 9, "#f4f1ea", k=0.6) + R(-7, -6, 19, 11, 5, "#1d2a3a", k=0.3)
    if pose["face"] == "raiva":
        hd += f'<path d="M-3,-3 L3,-1 M6,-1 L12,-3" stroke="{col}" stroke-width="2.4" stroke-linecap="round"/><path d="M0,2 h9" stroke="{col}" stroke-width="1.8" stroke-linecap="round"/>'
    else:
        hd += f'<path d="M-3,-1.5 h5 M6,-1.5 h5" stroke="{col}" stroke-width="2.4" stroke-linecap="round"/>'
    hd += "</g>"
    return f'<g transform="{tf}">{b}{hd}</g>'


def c_arm(col, sh, el, end, back):
    c = shade(col, -0.45) if back else shade(col, -0.15)
    out = taper(sh, el, 7.5, 7.5, c) + taper(el, end, 7.5, 7.5, c)
    out += f'<circle cx="{el[0]:.1f}" cy="{el[1]:.1f}" r="2" fill="{shade(col, -0.6)}"/>'
    out += E(end[0], end[1], 5.5, 5.5, "#f4f1ea" if not back else "#cfc8bc", k=0.4)
    return out


def c_leg(col, hp, knee, end, back):
    c = shade(col, -0.5) if back else shade(col, -0.22)
    out = taper(hp, knee, 9, 9, c) + taper(knee, end, 9, 9, c)
    out += f'<circle cx="{knee[0]:.1f}" cy="{knee[1]:.1f}" r="2.2" fill="{shade(col, -0.65)}"/>'
    out += R(end[0] - 7, end[1] - 3, 19, 9, 4.5, "#f4f1ea" if not back else "#cfc8bc", k=0.4)
    return out


ESTILOS = [
    ("A · INDUSTRIAL", "#4f86d9", "Equipamento de obra que anda: chassi com faixa de perigo, máscara de solda com fenda acesa,", "braços de pistão e mãos-garra, botas de aço. Pesado, sério, mecânico.",
     dict(spine=32, shl=(5, -38), sh_gap=13, hip_w=6, thigh=18, shin=18, uarm=15, farm=16, foot_h=5, body=a_body, arm=a_arm, leg=a_leg)),
    ("B · ATLETA", "#f06aa8", "Lutador: tronco em V e cintura fina, cabeça pequena com viseira, membros longos que afinam,", "tênis de obra. Proporção 'adulta', rápido e combativo.",
     dict(spine=30, shl=(6, -37), sh_gap=12, hip_w=5, thigh=20, shin=20, uarm=16, farm=16, foot_h=4, body=b_body, arm=b_arm, leg=b_leg)),
    ("C · MINIMALISTA", "#5cc45c", "Poucas formas lisas: tronco e membros arredondados de mesma largura, cabeça-tela branca com", "olhos de traço. Limpo como produto de design; a pose faz o trabalho.",
     dict(spine=30, shl=(4, -36), sh_gap=12, hip_w=6, thigh=19, shin=19, uarm=15, farm=15, foot_h=5, body=c_body, arm=c_arm, leg=c_leg)),
]


def prancha():
    W, H = 1920, 1700
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 60, "ROBÔS — 3 CONCEITOS DE LUTA (A industrial · B atleta · C minimalista)", 38)]
    for i, (nome, col, l1, l2, st) in enumerate(ESTILOS):
        y = 90 + i * 530
        b.append(f'<rect x="25" y="{y}" width="{W - 50}" height="510" rx="24" fill="#ffffff" opacity="0.5"/>')
        b.append(label(55, y + 52, nome, 38, INK, "start"))
        b.append(label(55, y + 86, l1, 17, "#2a4a58", "start", 600) + label(55, y + 110, l2, 17, "#2a4a58", "start", 600))
        gy = y + 462
        b.append(f'<rect x="45" y="{gy}" width="1440" height="12" rx="4" fill="#c9b99a"/>')
        for j, (pk, px, nm) in enumerate((("guarda", 380, "GUARDA"), ("golpe", 780, "GOLPE"), ("ar", 1220, "PESADO NO AR"))):
            b.append(f'<g transform="translate({px},{gy}) scale(2.55)">{montar(st, col, POSES[pk])}</g>')
            b.append(label(px, gy + 36, nm, 18, "#2a4a58"))
        # 1x nas 4 cores
        b.append(label(1700, y + 150, "tamanho de jogo (1x)", 16, "#2a4a58"))
        b.append(f'<rect x="1530" y="{y + 300}" width="340" height="6" fill="#c9b99a"/>')
        for k, c in enumerate(["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]):
            b.append(f'<g transform="translate({1570 + k * 80},{y + 300})">{montar(st, c, POSES["guarda" if k % 2 == 0 else "golpe"])}</g>')
        b.append(label(1700, y + 400, "2x", 16, "#2a4a58"))
        b.append(f'<g transform="translate({1700},{y + 470}) scale(1.6)">{montar(st, col, POSES["golpe"])}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


def main():
    os.makedirs(OUT, exist_ok=True)
    svg, w, h = prancha()
    queue(svg, f"{SRC}/c2_conceitos.svg", os.path.join(OUT, "c2_conceitos.png"), w, h, 1)
    print("conceitos2:", render_all())


if __name__ == "__main__":
    main()
