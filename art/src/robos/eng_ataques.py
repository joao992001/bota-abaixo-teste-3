"""PRANCHA — melhoria dos ATAQUES (auditoria 2026-11-27, docs/revisoes/auditoria_engenhocas.md).
Lote 1: A04 MARRETA SÍSMICA (a mais destrutiva: cratera + onda de choque) e A01 PUNHO PNEUMÁTICO (carrega e arremessa).
Storyboard em 4 tempos (preparo → ação → impacto → resultado) + arte nova das armas.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/eng_ataques.py → art/out/robos_v2/eng_ataques_l1.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import robo_uch as ru  # noqa: E402
from armaduras_conceito import R, E, P_, S, DARK, STEEL, STEEL_D, STEEL_L, YEL, ab, eu, label, INK, queue, render_all, shade  # noqa: E402

P = ab.P
AZUL, VERDE = "#4f86d9", "#5cc45c"
CONC, CONC_D, CONC_L = "#cdbfa3", "#a8987a", "#e3d7bf"
TILE = 56          # 64 px do jogo em unidades do desenho (robô ~70)
EYE = "#ff3b2f"
_MARRETA = ru.marreta


# ---------------------------------------------------------------- cenário
def laje(x0, x1, y=0, buraco=None, rachar=None):
    """Laje de blocos de concreto; buraco=(xa, xb) some com bordas quebradas e vergalhões."""
    o = ""
    x = x0
    while x < x1:
        w = min(TILE, x1 - x)
        if buraco and x + w > buraco[0] and x < buraco[1]:
            x += w
            continue
        o += R(x + 1, y, w - 2, TILE * 0.55, 3, CONC, k=0.5) + R(x + 1, y, w - 2, 5, 2, CONC_L, k=0.2)
        o += f'<path d="M{x + 10},{y + 14} l6,4 M{x + w - 16},{y + 22} l5,-3" stroke="{CONC_D}" stroke-width="1.6"/>'
        x += w
    if buraco:
        for bx, d in ((buraco[0], 1), (buraco[1], -1)):
            o += P_([(bx, y), (bx + d * 9, y + 6), (bx + d * 3, y + 14), (bx + d * 10, y + 22), (bx, y + 31)], CONC_D, k=0.2)
            o += f'<path d="M{bx},{y + 8} l{d * 16},{-6} M{bx},{y + 20} l{d * 13},{4}" stroke="#7a4a2a" stroke-width="2.2" stroke-linecap="round"/>'
    if rachar:
        xa, xb = rachar
        pts = " ".join(f"{xa + (xb - xa) * i / 8:.1f},{y + 2 + (5 if i % 2 else -2)}" for i in range(9))
        o += f'<polyline points="{pts}" fill="none" stroke="#ff9a3a" stroke-width="3"/>'
    return o


def pedra(x, y, s, rot, cor=CONC):
    return f'<g transform="translate({x},{y}) rotate({rot}) scale({s})">' + P_([(-6, -5), (5, -6), (7, 3), (-2, 6), (-7, 1)], cor, k=0.3) + "</g>"


def poeira(x, y, n, r0, sp, op=0.85):
    return "".join(f'<circle cx="{x + math.cos(i * 2.3) * sp * (0.4 + (i % 3) * 0.3):.1f}" cy="{y - abs(math.sin(i * 1.7)) * sp * 0.35:.1f}" '
                   f'r="{r0 * (0.7 + (i % 4) * 0.15):.1f}" fill="#efe6d4" opacity="{op}"/>' for i in range(n))


def linhas_vel(x, y, n, ln, dx=1, op=0.9):
    return "".join(f'<path d="M{x - dx * (i % 2) * 8},{y + i * 7} h{-dx * ln}" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="{op}"/>' for i in range(n))


def anel(x, y, rx, ry, w, op=1.0, cor="#ffffff"):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="none" stroke="{cor}" stroke-width="{w}" opacity="{op}"/>'


def estrela(x, y, r, cor="#ffe27a"):
    pts = " ".join(f"{x + math.cos(math.radians(i * 22.5)) * (r if i % 2 == 0 else r * 0.45):.1f},{y + math.sin(math.radians(i * 22.5)) * (r if i % 2 == 0 else r * 0.45):.1f}" for i in range(16))
    return f'<polygon points="{pts}" fill="{cor}"/>'


def area_perigo(xa, xb, y):
    return (f'<rect x="{xa}" y="{y - 3}" width="{xb - xa}" height="6" fill="{EYE}" opacity="0.35"/>'
            f'<rect x="{xa}" y="{y - 3}" width="{xb - xa}" height="6" fill="none" stroke="{EYE}" stroke-width="1.6" stroke-dasharray="6 4"/>'
            + "".join(f'<path d="M{xa + i * 10},{y + 3} l6,-6" stroke="{EYE}" stroke-width="1.5"/>' for i in range(int((xb - xa) / 10))))


# ---------------------------------------------------------------- robôs
def marretao(pose, x=0, y=0, sem_ferramenta=False, marreta_giga=1.0, rot=0, sq=None):
    if sem_ferramenta:
        ru.marreta = lambda g, ang, s=0.72: ("", g, (g[0] - 8, g[1] + 4))
    elif marreta_giga != 1.0:
        ru.marreta = lambda g, ang, s=0.72: _MARRETA(g, ang, s * marreta_giga)
    corpo = ru.desenha(P(**pose), AZUL)
    ru.marreta = _MARRETA
    t = f"translate({x},{y})" + (f" rotate({rot} 0 -36)" if rot else "") + (f" scale({sq[0]},{sq[1]})" if sq else "")
    return f'<g transform="{t}">{corpo}</g>'


def rival(x, y, rot=0, sq=None, flip=True):
    corpo = eu.desenha(2, VERDE, "parado")
    t = f"translate({x},{y})" + (f" rotate({rot} 0 -36)" if rot else "") + (" scale(-1,1)" if flip else "") + (f" scale({sq[0]},{sq[1]})" if sq else "")
    return f'<g transform="{t}">{corpo}</g>'


def cabeca_giga(tool, f):
    """Centro da cabeça da marreta gigante (marreta de ru.marreta em escala 0.72*f)."""
    gx, gy, ang = tool
    a = math.radians(ang)
    L = 40.0 * f
    return gx + math.cos(a) * L, gy + math.sin(a) * L


# ---------------------------------------------------------------- arte nova das armas
def marreta_sismica(s=1.0):
    """A04: marreta gigante de demolição: cabeça de aço com núcleo sísmico laranja, pistões nas pontas, cabo reforçado."""
    o = R(-4, 0, 8, 96, 3, "#7a4a2a", k=0.4) + "".join(R(-5, 60 + i * 10, 10, 4, 1, DARK, k=0.1) for i in range(3))
    o += R(-7, -6, 14, 12, 2, STEEL_D, k=0.2)
    o += R(-40, -34, 80, 30, 6, "#4a505c", k=0.5) + R(-40, -34, 80, 7, 4, "#6a7280", k=0.2)
    o += ab.cb.faixa(-30, -20, 60, 8, n=6)
    o += R(-48, -36, 10, 34, 3, STEEL, k=0.3) + R(38, -36, 10, 34, 3, STEEL, k=0.3)
    o += R(-54, -30, 8, 22, 2, STEEL_D, k=0.2) + R(46, -30, 8, 22, 2, STEEL_D, k=0.2)
    o += E(0, -26, 8, 8, "#2b2b33", k=0.1) + E(0, -26, 5, 5, "#ff8a2a", k=0.1) + f'<circle cx="0" cy="-26" r="11" fill="#ff8a2a" opacity="0.3"/>'
    return f'<g transform="scale({s})">{o}</g>'


def luva_pneu(ext=0.0, s=1.0, pressao=0.0, vapor=0.0):
    """A01: canhão pneumático no antebraço (cilindro + manômetro + mangueira) → braço de TESOURA → luva vermelha.
    ext = comprimento esticado (0 = recolhido). Origem = mão (0,0), apontando para +x."""
    o = R(-14, -8, 30, 16, 5, "#d06a2a", k=0.4) + R(-14, -8, 30, 5, 3, "#e8894a", k=0.2) + R(14, -6, 6, 12, 2, STEEL_D, k=0.2)
    o += f'<path d="M-12,6 C-22,16 -30,8 -34,0" stroke="#2b2b33" stroke-width="3" fill="none"/>'
    o += E(2, -12, 7, 7, "#f3ead8", k=0.1) + f'<circle cx="2" cy="-12" r="7" fill="none" stroke="{DARK}" stroke-width="1.6"/>'
    a = math.radians(200 - 220 * pressao)
    o += f'<path d="M2,-12 l{math.cos(a) * 5.5:.1f},{-math.sin(a) * 5.5:.1f}" stroke="{EYE}" stroke-width="1.8" stroke-linecap="round"/>'
    x = 20.0
    if ext > 4:
        n = max(2, int(ext / 14))
        st = ext / n
        pts1 = " ".join(f"{x + i * st:.1f},{(-6 if i % 2 else 6)}" for i in range(n + 1))
        pts2 = " ".join(f"{x + i * st:.1f},{(6 if i % 2 else -6)}" for i in range(n + 1))
        o += f'<polyline points="{pts1}" fill="none" stroke="{STEEL_D}" stroke-width="3.2"/><polyline points="{pts2}" fill="none" stroke="{STEEL}" stroke-width="3.2"/>'
        x += ext
    o += R(x, -7, 6, 14, 2, STEEL, k=0.2)
    gs = 1.0 + 0.25 * min(ext / 160.0, 1.0)
    o += f'<g transform="translate({x + 6},0) scale({gs},{1 / gs})">' + S("M0,-11 C14,-14 24,-8 24,0 C24,9 14,13 0,11 Z", "#e54b3c", (0, -14, 24, 13), k=0.5)
    o += f'<path d="M6,-8 C14,-10 18,-6 19,-3" stroke="#ffffff" stroke-width="2.4" opacity="0.7" fill="none" stroke-linecap="round"/></g>'
    for i in range(int(vapor * 4)):
        o += f'<circle cx="{-6 - i * 7}" cy="{-14 - i * 6}" r="{4 + i * 1.5}" fill="#ffffff" opacity="{0.8 - i * 0.15:.2f}"/>'
    return f'<g transform="scale({s})">{o}</g>'


def marreta_em(grip, ang, s=0.68, glow=0.0):
    """Marreta sísmica segurada em grip; ang = direção da cabeça (graus, 0 = frente, -90 = cima). Pega a 80 do cabo."""
    gx, gy = grip
    o = f'<g transform="translate({gx},{gy}) rotate({ang + 90}) scale({s}) translate(0,-80)">{marreta_sismica()}</g>'
    if glow:
        a = math.radians(ang)
        hx, hy = gx + math.cos(a) * 106 * s, gy + math.sin(a) * 106 * s
        o = f'<circle cx="{hx:.1f}" cy="{hy:.1f}" r="{34 * glow:.1f}" fill="#ffb24a" opacity="0.4"/>' + o
    return o


def nota(y, *txt):
    return "".join(label(62, y + i * 13, t, 11, INK) for i, t in enumerate(txt))


def barra_energia(x, y, k):
    return R(x - 16, y, 32, 7, 3, DARK, k=0.1) + R(x - 14, y + 1.5, 28 * k, 4, 2, "#9b6bff", k=0.1)


# ---------------------------------------------------------------- quadros
def painel(xp, yp, w, h, titulo, conteudo, s=1.6, chao=None):
    gx, gy = xp + w * 0.28, yp + h - 70
    o = f'<rect x="{xp}" y="{yp}" width="{w}" height="{h}" rx="18" fill="#cfeef3"/>'
    o += f'<clipPath id="c{xp}_{yp}"><rect x="{xp}" y="{yp}" width="{w}" height="{h}" rx="18"/></clipPath>'
    o += f'<g clip-path="url(#c{xp}_{yp})"><g transform="translate({gx},{gy}) scale({s})">{conteudo}</g></g>'
    o += label(xp + w / 2, yp + 30, titulo, 19, INK)
    return o


def a04():
    car = dict(hip=(0, -17), lean=-22, head=12, feet=[(-13, 0), (10, 0)], tool=(-2, -52, -120), face="raiva", sq=(1.08, 0.88))
    gol = dict(hip=(2, -17), lean=18, head=-6, feet=[(-15, 0), (16, 0)], tool=(16, -44, -20), face="raiva", sq=(1, 0.9))
    sol = dict(hip=(3, -16), lean=30, head=-10, feet=[(-16, 0), (18, 0)], tool=(24, -24, 20), face="raiva", sq=(1, 0.84))
    rec = dict(hip=(0, -22), lean=8, head=0, feet=[(-12, 0), (10, 0)], tool=(16, -30, 20), face="foco")
    ps = []
    c = laje(-110, 230) + area_perigo(40, 150, -1) + rival(118, 0)
    c += marreta_em((-2, -52), -125, glow=1.0) + marretao(car, sem_ferramenta=True) + poeira(0, 0, 5, 5, 26)
    c += nota(-205, "segura erguida: brilho carrega", "faixa vermelha = onde vai abrir")
    ps.append(("1 · PREPARO — arqueia e ergue (0,5 s)", c))
    c = laje(-110, 230) + area_perigo(40, 150, -1) + rival(118, 0)
    c += f'<path d="M-70,-120 C0,-170 110,-120 100,-20" stroke="#ffffff" stroke-width="30" fill="none" opacity="0.55" stroke-linecap="round"/>'
    c += marreta_em((16, -44), -20, glow=0.5) + marretao(gol, sem_ferramenta=True)
    ps.append(("2 · GOLPE — arco com rastro", c))
    c = laje(-110, 230, buraco=(40, 150))
    for i in range(14):
        c += pedra(44 + (i * 37) % 106, -20 - (i * 23) % 90, 1.2 + (i % 3) * 0.5, i * 40)
    c += anel(95, 0, 130, 24, 6) + anel(95, 0, 72, 12, 4, 0.8) + estrela(95, -12, 30) + poeira(95, 0, 12, 9, 90)
    c += linhas_vel(150, -120, 4, 40, -1) + rival(178, -100, rot=-60, sq=(1, 0.9))
    c += marreta_em((24, -24), 10) + marretao(sol, sem_ferramenta=True)
    c += f'<path d="M-30,-2 l-40,-3 M-30,5 l-46,2" stroke="#ff9a3a" stroke-width="3"/>'
    c += nota(-205, "laje some na área · pedras voam", "perto: voa longe · no chão: é levantado")
    ps.append(("3 · IMPACTO — cratera + onda de choque", c))
    c = laje(-110, 230, buraco=(40, 150))
    for i in range(6):
        c += pedra(50 + i * 17, 40 + (i % 3) * 22, 1.3, i * 50, CONC_D)
    c += poeira(95, -6, 8, 8, 70, 0.5) + marreta_em((16, -30), 20) + marretao(rec, sem_ferramenta=True)
    c += nota(-205, "buraco de 2 blocos na laje", "quem estava em cima cai")
    ps.append(("4 · RESULTADO — buraco aberto, poeira assenta", c))
    return ps


def a01():
    agacha = dict(hip=(-2, -16), lean=-12, head=8, feet=[(-14, 0), (10, 0)], tool=(9, -34, -150), bk=(-12, -28), fr=(4, -34), face="raiva", sq=(1.06, 0.86))
    solta = dict(hip=(-6, -22), lean=10, head=-2, feet=[(-20, 0), (6, 0)], tool=(9, -34, -150), bk=(-16, -30), fr=(14, -38), face="raiva")
    ps = []
    # 1 carga
    c = laje(-110, 250) + rival(150, 0) + nota(-205, "barra = pressão (até 1 s)", "manômetro sobe, robô treme")
    c += marretao(agacha, sem_ferramenta=True) + f'<g transform="translate(4,-34)">{luva_pneu(0, 1.0, 0.8, 1.0)}</g>'
    c += barra_energia(0, -96, 0.75) + poeira(-6, 0, 4, 4, 18)
    c += f'<path d="M-24,-60 l-4,-6 M30,-62 l5,-6" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>'
    ps.append(("1 · CARREGA — segura: pistão enche, vapor", c))
    # 2 solta
    c = laje(-110, 250) + rival(150, 0, sq=(0.9, 1.08))
    c += marretao(solta, x=-14, sem_ferramenta=True) + f'<g transform="translate(0,-38)">{luva_pneu(104, 1.0, 0.1, 0.0)}</g>'
    c += poeira(-30, 0, 6, 5, 24) + linhas_vel(-40, -50, 3, 26, 1) + estrela(150, -40, 26) + anel(150, -40, 30, 30, 4)
    ps.append(("2 · SOLTA — tesoura estica, coice no robô", c))
    # 3 voo
    c = laje(-110, 250) + marretao(dict(hip=(0, -24), lean=4, head=2, feet=[(-9, 0), (9, 0)], tool=(9, -34, -150), bk=(-12, -24), face="foco"), x=-40)
    c += linhas_vel(140, -64, 5, 70, 1) + rival(190, -26, rot=-90, sq=(0.92, 1))
    c += nota(-205, "carga cheia = voa longe em linha reta", "pouca carga = soco médio")
    ps.append(("3 · ARREMESSO — reto, mais longe quanto mais carga", c))
    # 4 parede
    c = laje(-110, 250)
    for j in range(3):
        c += R(140, -TILE * 0.55 * (j + 1), TILE, TILE * 0.55, 3, CONC if j != 1 else CONC_D, k=0.5)
    c += f'<path d="M142,-52 l14,8 l-6,10 l16,6" stroke="#5a4a3a" stroke-width="2.5" fill="none"/>'
    for i in range(6):
        c += pedra(130 - i * 8, -60 + (i % 3) * 14, 1.1, i * 60)
    c += estrela(134, -46, 22) + rival(104, -20, rot=30) + linhas_vel(80, -40, 2, 20, -1, 0.6)
    c += nota(-205, "bateu na parede/bloco: quica de volta", "e o bloco racha (dano no cenário)")
    ps.append(("4 · PAREDE — quica e racha o bloco", c))
    return ps


def prancha():
    W, H = 1920, 1260
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "ATAQUES · LOTE 1 — A04 MARRETA SÍSMICA e A01 PUNHO PNEUMÁTICO (proposta)", 32)]
    pw, ph = 452, 470
    for r, (nome, sub, ps, arma) in enumerate([
            ("A04 MARRETA SÍSMICA", "só no chão · cratera destrói 2 blocos à frente · onda levanta todos no chão · perto voa longe", a04(), marreta_sismica(0.9)),
            ("A01 PUNHO PNEUMÁTICO", "segurar carrega (até 1 s) · soltar = arremesso reto · bateu em parede quica e racha · coice", a01(), luva_pneu(40, 1.6, 0.7, 0.5))]):
        y0 = 80 + r * (ph + 110)
        b.append(label(40, y0 + 22, nome, 26, INK, anchor="start") if False else f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{nome}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        b.append(f'<g transform="translate({W - 150},{y0 + 40})">{arma}</g>' if r == 0 else f'<g transform="translate({W - 230},{y0 + 40})">{arma}</g>')
        b.append(f'<text x="{W - 150}" y="{y0 + 70}" text-anchor="middle" font-family="Arial" font-size="13" fill="{INK}">arte nova</text>')
        for j, (tit, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 80, pw, ph, tit, c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/eng_ataques_l1.png")
    queue(svg, os.path.join(HERE, "svg/eng_ataques_l1.svg"), out, W, H, 1)
    print(render_all(), out)


if __name__ == "__main__":
    prancha()
