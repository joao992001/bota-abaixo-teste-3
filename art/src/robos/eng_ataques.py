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


def canhao_jogo():
    """A01 no jogo: canhão pneumático no espaço de design 128x64 (pega 30,34 · bico 100,33), sem a luva."""
    o = f'<path d="M24,44 C10,54 4,44 2,36" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(18, 20, 80, 28, 10, "#d06a2a", k=0.5) + R(18, 20, 80, 8, 6, "#e8894a", k=0.2)
    o += "".join(R(34 + i * 18, 20, 5, 28, 1.5, "#a5501f", k=0.1) for i in range(3))
    o += R(94, 22, 12, 24, 3, STEEL, k=0.3) + R(100, 25, 6, 18, 2, STEEL_D, k=0.2)
    o += R(46, 6, 6, 16, 2, STEEL_D, k=0.1) + E(49, 8, 9, 9, "#f3ead8", k=0.1)
    o += f'<circle cx="49" cy="8" r="9" fill="none" stroke="{DARK}" stroke-width="2.4"/><path d="M49,8 l5,-5" stroke="{EYE}" stroke-width="2.4" stroke-linecap="round"/>'
    o += f'<path d="M42,13 a9,9 0 0 1 14,0" stroke="{EYE}" stroke-width="2" fill="none" opacity="0.7"/>'
    return o


def luva_jogo():
    """A01 luva no espaço 62x50 (desenhada em Rect2(-8,-26,62,50): punho na esquerda)."""
    o = R(0, 13, 14, 24, 3, STEEL, k=0.3) + R(4, 15, 4, 20, 1.5, STEEL_D, k=0.1)
    o += S("M12,6 C34,0 58,8 58,25 C58,42 34,50 12,44 Z", "#e54b3c", (12, 0, 58, 50), k=0.5)
    o += S("M14,30 C24,28 30,34 28,42 C22,46 16,45 14,42 Z", "#c73a2d", (14, 28, 30, 46), k=0.3)
    o += f'<path d="M24,10 C38,6 48,12 52,18" stroke="#ffffff" stroke-width="4" opacity="0.65" fill="none" stroke-linecap="round"/>'
    return o


def exportar_jogo():
    out = os.path.join(ab.ROOT, "art/out/game/spells")
    os.makedirs(out, exist_ok=True)
    itens = [("a04_marreta", f'<g transform="translate(56,40)">{marreta_sismica()}</g>', 112, 140, 4),
             ("s01_canhao", canhao_jogo(), 128, 64, 2), ("s01_luva", luva_jogo(), 62, 50, 2.0645),
             ("s02_laser", laser_jogo(), 128, 64, 2), ("s05_rebiteira", rebiteira_jogo(), 128, 64, 2),
             ("s20_canhao", molas_c(), 128, 64, 2)]
    for nome, g, w, h, sc in itens:
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{g}</svg>'
        queue(svg, os.path.join(HERE, f"svg/eng_{nome}.svg"), os.path.join(out, f"{nome}.png"), w, h, sc)
    # E02 (lote 3): dinamite com detonador de antena (viewBox -22 -46 44 64) e o detonador da mão (-10 -30 20 42)
    for nome, g, vb, w, h in (("s12_carga", dinamite(1.0, 0.0), "-22 -46 44 64", 44, 64), ("s12_detonador", detonador(1.0), "-10 -30 20 42", 20, 42)):
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}">{g}</svg>'
        queue(svg, os.path.join(HERE, f"svg/eng_{nome}.svg"), os.path.join(out, f"{nome}.png"), w, h, 4)
    print("armas:", render_all())


# ================================================================ LOTE 2: A02 LASER DE CORTE · A05 REBITEIRA RICOCHETE
def laser_jogo():
    """A02 no espaço de design 128x64 (pega 19,50 · bico 122,31): cortadora industrial com cilindro de gás e lente."""
    o = f'<path d="M14,52 C4,58 2,46 6,40" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(12, 40, 14, 20, 4, "#2b2b33", k=0.3)
    o += R(10, 20, 92, 24, 8, "#3f4654", k=0.5) + R(10, 20, 92, 7, 5, "#5a6372", k=0.2)
    o += ab.cb.faixa(30, 34, 40, 6, n=5)
    o += "".join(R(76 + i * 7, 16, 4, 32, 1.5, STEEL, k=0.1) for i in range(3))
    o += R(26, 4, 44, 14, 7, "#e0702a", k=0.4) + R(26, 4, 44, 4, 3, "#f0904a", k=0.1) + R(68, 8, 6, 6, 1.5, STEEL_D, k=0.1)
    o += R(100, 22, 14, 20, 3, STEEL, k=0.3)
    o += E(118, 31, 9, 9, "#2b2b33", k=0.1) + E(118, 31, 6.5, 6.5, "#ff7a2a", k=0.1) + E(117, 30, 3, 3, "#fff3d0", k=0.1)
    return o


def rebiteira_jogo():
    """A05 no espaço 128x64 (pega 40,52 · bico 127,25): rebiteira com tambor de rebites em brasa e cano de boca larga."""
    o = f'<path d="M30,50 C14,60 10,44 16,38" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(34, 36, 14, 24, 4, "#2b2b33", k=0.3)
    o += R(24, 14, 76, 24, 8, "#8e98a4", k=0.5) + R(24, 14, 76, 7, 5, "#b9c3cc", k=0.2) + R(30, 28, 50, 5, 2, "#e0702a", k=0.1)
    o += E(52, 12, 15, 15, "#3f4654", k=0.3) + E(52, 12, 10, 10, "#2b2b33", k=0.1)
    for i in range(6):
        a = math.radians(i * 60)
        o += E(52 + math.cos(a) * 6.5, 12 + math.sin(a) * 6.5, 2.6, 2.6, "#ffb24a", k=0.05)
    o += R(98, 18, 20, 14, 3, STEEL, k=0.3) + P_([(116, 15), (128, 12), (128, 38), (116, 35)], STEEL_D, k=0.2)
    return o


def andaime(x0, x1, y, partido=None, cai=0.0):
    """Tábua de andaime sobre tubos; partido=x do corte (as duas metades caem girando com 'cai')."""
    o = ""
    pecas = [(x0, x1)] if partido is None else [(x0, partido - 2), (partido + 2, x1)]
    for j, (a, b) in enumerate(pecas):
        rot = 0 if partido is None else (cai * (18 if j else -14))
        dy = 0 if partido is None else cai * (30 + 20 * j)
        piv = b if j == 0 else a
        o += f'<g transform="translate(0,{dy}) rotate({rot} {piv} {y})">' + R(a, y, b - a, 9, 2, "#c08a4a", k=0.5) + R(a, y, b - a, 3, 1, "#d9a868", k=0.1)
        o += "".join(f'<path d="M{a + 8 + i * 22},{y + 2} v5" stroke="#8a5a2a" stroke-width="1.4"/>' for i in range(int((b - a - 10) / 22)))
        o += "</g>"
    if partido is None or cai < 0.5:
        for xx in (x0 + 6, x1 - 6):
            o += R(xx - 2, y + 9, 4, -y - 9, 1, "#7a828f", k=0.2)
    if partido is not None:
        hot = max(0.0, 1.0 - cai)
        o += f'<circle cx="{partido}" cy="{y + 4}" r="{6 + 6 * hot}" fill="#ff8a2a" opacity="{0.4 + 0.5 * hot:.2f}"/>'
    return o


def feixe(x0, y0, x1, y1, w=8.0):
    return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#2b1a2e" stroke-width="{w + 5}" stroke-linecap="round" opacity="0.85"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#e8302a" stroke-width="{w + 2}" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#ff8a3a" stroke-width="{w * 0.7}" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="#fff6dc" stroke-width="{w * 0.3}" stroke-linecap="round"/>')


def arma_mao(fn, hand, ang=0.0, s=0.42):
    """Arma de design 128x64 com a pega na mão (pega em gx,gy do design)."""
    g = {"laser": (19, 50), "rebite": (40, 52)}[fn]
    art = laser_jogo() if fn == "laser" else rebiteira_jogo()
    return f'<g transform="translate({hand[0]},{hand[1]}) rotate({ang}) scale({s}) translate({-g[0]},{-g[1]})">{art}</g>'


def rebite(x, y, ang, s=1.0):
    return (f'<g transform="translate({x},{y}) rotate({ang}) scale({s})">' + R(-9, -2, 10, 4, 1, STEEL, k=0.1)
            + E(2, 0, 4.5, 5.5, "#ffb24a", k=0.1) + E(2.5, -1, 2, 2.2, "#fff0c0", k=0.05) + "</g>")


def rastro(pts, cor="#ffd27a"):
    d = "M" + " L".join(f"{x},{y}" for x, y in pts)
    return f'<path d="{d}" stroke="{cor}" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.8"/>'


def faisca(x, y, r=8):
    return "".join(f'<path d="M{x},{y} l{math.cos(math.radians(a)) * r:.1f},{math.sin(math.radians(a)) * r:.1f}" stroke="#ffd27a" stroke-width="2.4" stroke-linecap="round"/>' for a in range(0, 360, 45))


def a02():
    mira = dict(hip=(0, -22), lean=-4, head=2, feet=[(-14, 0), (12, 0)], tool=(9, -34, -150), bk=(10, -32), fr=(16, -36), face="foco")
    ps = []
    c = laje(-110, 260) + andaime(60, 190, -96) + rival(130, -105) + rival(170, 0)
    c += marretao(mira, sem_ferramenta=True) + arma_mao("laser", (16, -36))
    c += f'<path d="M50,-38 L200,-38" stroke="{EYE}" stroke-width="1.6" stroke-dasharray="7 5"/>' + f'<circle cx="38" cy="-38" r="7" fill="#ff7a2a" opacity="0.6"/>'
    c += nota(-205, "segura: mira vermelha + lente acendendo", "▲▼ inclina a mira antes de soltar")
    ps.append(("1 · MIRA — segura (0,5 s)", c))
    c = laje(-110, 260) + andaime(60, 190, -96) + rival(130, -105) + rival(178, 0, sq=(1.05, 0.95))
    c += marretao(mira, sem_ferramenta=True) + arma_mao("laser", (16, -36), -10) + feixe(40, -42, 210, -72)
    c += f'<path d="M210,-40 A50,50 0 0 0 214,-110" stroke="#ffffff" stroke-width="3" fill="none" stroke-dasharray="5 4"/><path d="M214,-110 l-6,6 M214,-110 l7,5" stroke="#fff" stroke-width="3"/>'
    c += linhas_vel(200, -10, 3, 26, 1) + nota(-205, "feixe grosso (branco/laranja)", "segurando: VARRE para cima/baixo; arrasta quem toca")
    ps.append(("2 · FEIXE — varre enquanto segura", c))
    c = laje(-110, 260) + andaime(60, 190, -96, partido=124, cai=0.35) + rival(132, -78, rot=-25)
    c += marretao(mira, sem_ferramenta=True) + arma_mao("laser", (16, -36), -28) + feixe(40, -50, 124, -92) + faisca(124, -92, 12)
    c += nota(-205, "CORTA andaime, viga e plataforma:", "a peça parte e cai com quem está em cima")
    ps.append(("3 · CORTA — o andaime parte", c))
    c = laje(-110, 260) + andaime(60, 190, -96, partido=124, cai=1.0) + rival(150, 0, rot=80)
    c += marretao(dict(mira, face="foco"), sem_ferramenta=True) + arma_mao("laser", (16, -36))
    c += f'<path d="M118,-58 L130,-50" stroke="#ff8a2a" stroke-width="4"/><path d="M114,-40 L138,-36" stroke="#5a3a2a" stroke-width="4"/>'
    c += "".join(f'<path d="M{120 + i * 6},{-60 - i * 4} q4,-8 0,-16" stroke="#ffffff" stroke-width="2" fill="none" opacity="0.6"/>' for i in range(3))
    c += nota(-205, "borda cortada em brasa que esfria", "(laranja → escuro), fumaça")
    ps.append(("4 · RESULTADO — caiu tudo", c))
    return ps


def a05():
    tiro = dict(hip=(0, -22), lean=-6, head=2, feet=[(-14, 0), (12, 0)], tool=(9, -34, -150), bk=(10, -30), fr=(16, -36), face="raiva")
    ps = []
    c = laje(-110, 260) + rival(170, 0)
    c += marretao(tiro, x=-4, sem_ferramenta=True) + arma_mao("rebite", (12, -36))
    for i, (x, y) in enumerate(((70, -40), (100, -46), (130, -36))):
        c += rastro([(x - 30, y + 2), (x - 8, y)]) + rebite(x, y, -4 + i * 4)
    c += "".join(pedra(-6 - i * 8, -60 - i * 9, 0.6, i * 50, "#d9a868") for i in range(3))
    c += nota(-205, "rajada de 3 rebites em brasa", "coice a cada tiro, tambor girando")
    ps.append(("1 · RAJADA — 3 rebites em brasa", c))
    c = laje(-110, 260)
    for j in range(4):
        c += R(196, -TILE * 0.55 * (j + 1), TILE, TILE * 0.55, 3, CONC, k=0.5)
    c += marretao(tiro, x=-4, sem_ferramenta=True) + arma_mao("rebite", (12, -36), 22)
    c += rastro([(40, -24), (110, 0), (196, -60), (150, -110)]) + faisca(110, 0) + faisca(196, -60) + rebite(150, -110, -130)
    c += rival(120, -120, rot=10) + nota(-205, "quica até 3× em chão e parede", "faísca a cada ricochete: acerta atrás da cobertura")
    ps.append(("2 · RICOCHETE — chão e parede", c))
    c = laje(-110, 260) + rival(150, 0, sq=(1.08, 0.92))
    c += marretao(tiro, x=-4, sem_ferramenta=True) + arma_mao("rebite", (12, -36))
    c += rebite(140, -50, 0) + rebite(146, -30, 6) + estrela(150, -40, 18)
    c += label(124, -84, "1", 18, INK) + label(150, -92, "2", 18, INK) + label(176, -84, "3", 18, EYE)
    c += nota(-205, "cada acerto empurra um pouco", "contador 1 · 2 · 3 sobre o rival")
    ps.append(("3 · ACERTOS — cada um empurra", c))
    c = laje(-110, 260)
    for j in range(3):
        c += R(196, -TILE * 0.55 * (j + 1), TILE, TILE * 0.55, 3, CONC, k=0.5)
    c += rival(176, 0, rot=0)
    c += rebite(160, -60, 0, 1.3) + rebite(160, -30, 0, 1.3) + rebite(156, -4, 0, 1.3)
    c += f'<circle cx="176" cy="-90" r="16" fill="none" stroke="#ffe27a" stroke-width="2"/>' + "".join(estrela(176 + math.cos(a) * 16, -90 + math.sin(a) * 6, 5) for a in (0, 2.1, 4.2))
    c += marretao(dict(tiro, face="foco"), x=-4, sem_ferramenta=True) + arma_mao("rebite", (12, -36))
    c += nota(-205, "3 acertos = PREGADO ~1 s", "preso onde estiver, indefeso (rebites cravados)")
    ps.append(("4 · PREGADO — 3 acertos", c))
    return ps


def prancha2():
    W, H = 1920, 1260
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "ATAQUES · LOTE 2 — A02 LASER DE CORTE e A05 REBITEIRA RICOCHETE (proposta)", 32)]
    pw, ph = 452, 470
    for r, (nome, sub, ps, arma) in enumerate([
            ("A02 LASER DE CORTE", "segura = mira · solta = feixe que varre enquanto segura · CORTA andaime/viga/plataforma · arrasta o rival", a02(), laser_jogo()),
            ("A05 REBITEIRA RICOCHETE", "rajada de 3 rebites em brasa · quicam até 3× · cada acerto empurra · 3 acertos = PREGADO ~1 s", a05(), rebiteira_jogo())]):
        y0 = 80 + r * (ph + 110)
        b.append(f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{nome}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        b.append(f'<g transform="translate({W - 300},{y0 - 4}) scale(1.6)">{arma}</g>')
        b.append(f'<text x="{W - 200}" y="{y0 + 106}" text-anchor="middle" font-family="Arial" font-size="13" fill="{INK}">arte nova</text>')
        for j, (tit, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 80, pw, ph, tit, c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/eng_ataques_l2.png")
    queue(svg, os.path.join(HERE, "svg/eng_ataques_l2.svg"), out, W, H, 1)
    print(render_all(), out)


# ================================================================ LOTE 3: A08 CANHÃO DE MOLAS · E02 CARGA REMOTA
def canhao_molas_jogo():
    """A08 no espaço 128x64 (pega 24,54 · bico 124,32): canhão amarelo de boca larga, mola visível pelas fendas,
    manivela de carga em cima e anel de perigo na boca."""
    o = f'<path d="M18,52 C6,60 2,48 8,42" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(18, 38, 14, 22, 4, "#2b2b33", k=0.3)
    o += R(14, 16, 84, 30, 10, "#f2c84b", k=0.5, dark="#c49a2a") + R(14, 16, 84, 8, 6, "#f8dc7a", k=0.2)
    for i in range(4):   # fendas com a mola aparecendo
        o += R(30 + i * 15, 24, 10, 16, 3, "#2b2b33", k=0.1)
        o += f'<path d="M{31 + i * 15},{27} q4,4 8,0 M{31 + i * 15},{33} q4,4 8,0" stroke="{STEEL_L}" stroke-width="2.2" fill="none"/>'
    o += P_([(96, 12), (122, 6), (122, 58), (96, 50)], STEEL, k=0.4) + P_([(116, 8), (122, 6), (122, 58), (116, 56)], STEEL_D, k=0.2)
    o += ab.cb.faixa(98, 22, 10, 20, n=3)
    o += R(40, 4, 6, 14, 2, STEEL_D, k=0.1) + R(36, 0, 24, 6, 3, "#e0702a", k=0.2)   # manivela
    o += E(76, 12, 7, 7, "#f3ead8", k=0.1) + f'<path d="M76,12 l4,-4" stroke="{EYE}" stroke-width="2" stroke-linecap="round"/>'
    return o


def helice(x0, x1, ry, voltas, w=3.4):
    """Mola de verdade: UM fio em espiral (hélice vista de lado), desenhado por meias-voltas contínuas: as de trás
    escuras e finas, as da frente com contorno escuro e brilho de aço."""
    n = max(60, int(voltas * 36))
    pts = [(x0 + (x1 - x0) * i / n, ry * math.sin(i / n * voltas * 2 * math.pi), math.cos(i / n * voltas * 2 * math.pi)) for i in range(n + 1)]
    runs, cur, front = [], [pts[0]], pts[0][2] >= 0
    for p_ in pts[1:]:
        f = p_[2] >= 0
        cur.append(p_)
        if f != front:
            runs.append((front, cur))
            cur, front = [p_], f
    runs.append((front, cur))
    tras, frente = "", ""
    for f, run in runs:
        d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y, _ in run)
        if f:
            frente += f'<path d="{d}" stroke="#2b2f38" stroke-width="{w + 2.2:.1f}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            frente += f'<path d="{d}" stroke="#c9d1d8" stroke-width="{w * 0.6:.1f}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
        else:
            tras += f'<path d="{d}" stroke="#5a616c" stroke-width="{w:.1f}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    return tras, frente


def mola(x, y, ang=0.0, compr=1.0, s=1.0):
    """Projétil do A08 (combina com a arma C): mola de aço em espiral; atrás uma ARRUELA redonda; na frente um BATENTE de
    borracha vermelho em cúpula com anel de perigo. compr: 1 = comprimida (no voo), >1 = esticada (BOING), <1 = amassada."""
    L = 26.0 * compr
    voltas = 4.5
    tras, frente = helice(-L / 2, L / 2, 10, voltas)
    o = tras
    o += E(-L / 2 - 2, 0, 3.5, 11.5, "#8e98a4", k=0.15) + E(-L / 2 - 2.5, 0, 1.6, 4, "#5a6372", k=0.05)    # arruela de trás
    o += frente
    # batente: arruela + cúpula de borracha vermelha grande, com uma faixa amarela fina e brilho
    o += E(L / 2 + 1, 0, 3, 12, "#8e98a4", k=0.15)
    o += S(f"M{L / 2 + 3},-14 C{L / 2 + 24},-14 {L / 2 + 24},14 {L / 2 + 3},14 Z", "#e54b3c", (L / 2 + 2, -15, L / 2 + 25, 15), k=0.4)
    o += f'<path d="M{L / 2 + 9},-13 C{L / 2 + 11},-4 {L / 2 + 11},4 {L / 2 + 9},13" stroke="#f2c84b" stroke-width="3" fill="none"/>'
    o += f'<path d="M{L / 2 + 13},-9 C{L / 2 + 19},-7 {L / 2 + 20},-2 {L / 2 + 19},2" stroke="#ff9a8a" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
    return f'<g transform="translate({x},{y}) rotate({ang}) scale({s})">{o}</g>'


def projetil_a08():
    W, H = 1920, 420
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "A08 · arma C (Pistão-mola) + PROJÉTIL", 32)]
    b.append(f'<rect x="30" y="80" width="560" height="310" rx="22" fill="#ffffff" opacity="0.5"/>' + label(310, 116, "arma C", 22, INK))
    b.append(f'<g transform="translate(60,150) scale(3.8)">{molas_c()}</g>')
    estados = [("na boca (pronto)", 1.0, 0, ""), ("voando: gira comprimida", 1.0, -35, "rastro"), ("bate no chão: AMASSA", 0.4, -90, "poeira"),
               ("BOING: estica e quica", 2.0, -70, "boing"), ("acerta: estica TODA", 2.8, 0, "estrela")]
    for i, (txt, cp, ang, fx) in enumerate(estados):
        x = 640 + i * 254
        b.append(f'<rect x="{x}" y="80" width="240" height="310" rx="22" fill="#ffffff" opacity="0.5"/>' + label(x + 120, 116, txt, 15, INK, "middle", 700))
        g = f'<g transform="translate({x + 120},270) scale({2.6 if cp < 1.5 else 1.9})">'
        if fx == "rastro":
            g += linhas_vel(-14, 0, 3, 26, 1)
        if fx == "poeira":
            g += poeira(0, 22, 6, 5, 20)
        g += mola(0, 0, ang, cp)
        if fx == "boing":
            g += boing(0, -36, 13)
        if fx == "estrela":
            g += estrela(40, 0, 12) + boing(0, -34, 13)
        b.append(g + "</g>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/a08_projetil.png")
    queue(svg, os.path.join(HERE, "svg/a08_projetil.svg"), out, W, H, 1)
    print(render_all(), out)


def dinamite(s=1.0, luz=1.0, num=""):
    """E02: 3 bananas de dinamite amarradas com fita zebrada + caixinha detonadora com ANTENA e luz vermelha."""
    o = ""
    for i in range(3):
        o += R(-15 + i * 10, -14, 9, 30, 4, "#d8402e", k=0.4) + R(-15 + i * 10, -14, 9, 5, 3, "#f06a52", k=0.1)
    o += ab.cb.faixa(-16, -2, 32, 6, n=4)
    o += R(-9, -24, 18, 11, 3, "#2b2b33", k=0.3) + R(-6, -21, 8, 5, 1.5, "#9ff7c8", k=0.1)
    if num:
        o += label(-2, -17, num, 6, "#1a3a2a")
    o += f'<path d="M6,-24 L10,-42" stroke="#2b2b33" stroke-width="2"/>' + E(10, -43, 2.6, 2.6, "#2b2b33", k=0.1)
    o += f'<circle cx="5" cy="-18" r="{3 + 5 * luz:.1f}" fill="#ff3b2f" opacity="{0.25 * luz:.2f}"/>' + E(5, -18, 2.4, 2.4, "#ff3b2f" if luz > 0.3 else "#7a2a2a", k=0.05)
    return f'<g transform="scale({s})">{o}</g>'


def detonador(s=1.0, apertou=False):
    """Controle do detonador na mão: caixinha com antena e botão vermelho."""
    o = R(-7, -10, 14, 20, 4, "#3f4654", k=0.3) + E(0, -3 + (2 if apertou else 0), 4.2, 3 if apertou else 4.2, "#e54b3c", k=0.1)
    o += f'<path d="M4,-10 L8,-26" stroke="#2b2b33" stroke-width="1.8"/>' + E(8, -27, 2, 2, "#ff3b2f" if apertou else "#2b2b33", k=0.05)
    if apertou:
        o += "".join(f'<path d="M8,-27 l{math.cos(math.radians(a)) * 9:.1f},{math.sin(math.radians(a)) * 9:.1f}" stroke="#ffe27a" stroke-width="1.8" stroke-linecap="round"/>' for a in (-150, -90, -30))
    return f'<g transform="scale({s})">{o}</g>'


def arma_mao3(hand, ang=0.0, s=0.42):
    return f'<g transform="translate({hand[0]},{hand[1]}) rotate({ang}) scale({s}) translate(-24,-54)">{canhao_molas_jogo()}</g>'


def boing(x, y, sz=22, rot=-8):
    return (f'<g transform="translate({x},{y}) rotate({rot})"><text x="0" y="0" text-anchor="middle" font-family="Fredoka, Arial Black, Arial" font-weight="900" '
            f'font-size="{sz}" fill="#2a1a2e" stroke="#2a1a2e" stroke-width="6" stroke-linejoin="round">BOING!</text>'
            f'<text x="0" y="0" text-anchor="middle" font-family="Fredoka, Arial Black, Arial" font-weight="900" font-size="{sz}" fill="#ffd23a">BOING!</text></g>')


def a08():
    mira = dict(hip=(0, -22), lean=-8, head=4, feet=[(-14, 0), (12, 0)], tool=(9, -34, -150), bk=(8, -30), fr=(14, -36), face="foco")
    coice = dict(hip=(-4, -21), lean=-16, head=8, feet=[(-18, 0), (8, 0)], tool=(9, -34, -150), bk=(4, -30), fr=(8, -40), face="raiva")
    ps = []
    c = laje(-110, 260) + rival(190, 0)
    c += marretao(mira, sem_ferramenta=True) + arma_mao3((14, -36), -14)
    c += mola(30, -45, -14, 0.55, 0.6)
    c += f'<path d="M60,-58 Q130,-140 200,-40" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-dasharray="7 5"/>'
    c += nota(-205, "0,3 s: a mola COMPRIME dentro (clec-clec)", "▲▼ ajusta o arco · manivela gira")
    ps.append(("1 · PREPARO — comprime a mola", c))
    c = laje(-110, 260) + rival(190, 0)
    c += marretao(coice, x=-8, sem_ferramenta=True) + arma_mao3((6, -40), -20)
    c += anel(48, -60, 14, 14, 4, 0.8) + poeira(48, -60, 5, 4, 16, 0.6)
    c += mola(96, -96, -30, 0.7) + linhas_vel(70, -80, 3, 30, 1, 0.8)
    c += nota(-205, "dispara a mola GROSSA girando", "coice joga o robô para trás")
    ps.append(("2 · DISPARO — mola girando, coice", c))
    c = laje(-110, 260) + rival(200, 0)
    c += marretao(mira, sem_ferramenta=True) + arma_mao3((14, -36), -14)
    c += mola(120, -10, -90, 0.35) + poeira(120, 0, 6, 5, 22)
    c += mola(150, -60, -60, 1.6) + boing(130, -100, 18)
    c += f'<path d="M120,-8 Q150,-120 190,-40" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-dasharray="7 5"/>'
    c += nota(-205, "bate no chão: AMASSA e estica (BOING)", "quica até sumir (1,8 s)")
    ps.append(("3 · QUIQUE — amassa e estica", c))
    c = laje(-110, 260)
    c += marretao(dict(mira, face="raiva"), sem_ferramenta=True) + arma_mao3((14, -36), -14)
    c += mola(118, -40, 0, 2.4) + estrela(146, -40, 22) + boing(110, -110, 24)
    c += rival(185, -70, rot=-50, sq=(1, 0.9)) + linhas_vel(200, -60, 4, 30, 1)
    c += nota(-205, "acerta: a mola ESTICA toda e", "ARREMESSA o rival (mesmo efeito de hoje)")
    ps.append(("4 · IMPACTO — estica e arremessa", c))
    return ps


def e02():
    joga = dict(hip=(0, -22), lean=12, head=-4, feet=[(-16, 0), (14, 0)], tool=(9, -34, -150), bk=(-12, -30), fr=(22, -52), face="raiva")
    pose = dict(hip=(0, -22), lean=-2, head=2, feet=[(-12, 0), (10, 0)], tool=(9, -34, -150), bk=(-10, -28), fr=(16, -40), face="foco")
    ps = []
    c = laje(-110, 260) + rival(170, 0)
    c += marretao(joga, sem_ferramenta=True)
    c += f'<g transform="translate(70,-92) rotate(30)">{dinamite(0.9, 1.0)}</g>'
    c += f'<path d="M24,-56 Q70,-130 160,-50" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-dasharray="7 5"/>'
    c += f'<g transform="translate(-14,-30)">{detonador(0.8)}</g>'
    c += nota(-205, "arremessa a dinamite em arco (▲▼ muda o arco)", "e fica com o DETONADOR de antena na mão")
    ps.append(("1 · ARREMESSO — dinamite em arco", c))
    c = laje(-110, 260) + rival(140, 0, sq=(1.03, 0.97))
    c += f'<g transform="translate(130,-44) rotate(-10)">{dinamite(0.8, 1.0, "3")}</g>'
    c += f'<circle cx="130" cy="-44" r="34" fill="none" stroke="#ff3b2f" stroke-width="3" stroke-dasharray="40 200"/>'
    c += label(110, -112, "bip · bip · bip·bip·bip", 13, "#c0302a")
    c += marretao(pose, sem_ferramenta=True) + f'<g transform="translate(16,-40)">{detonador(0.8)}</g>'
    c += nota(-205, "GRUDA no rival (ou no chão/parede)", "bipe ACELERA · explode sozinha em 4 s")
    ps.append(("2 · GRUDA — bipe acelerando", c))
    c = laje(-110, 260, buraco=(80, 180))
    c += marretao(dict(pose, face="raiva"), sem_ferramenta=True) + f'<g transform="translate(16,-40)">{detonador(0.8, True)}</g>'
    c += f'<circle cx="130" cy="-40" r="70" fill="#ffd27a" opacity="0.55"/><circle cx="130" cy="-40" r="40" fill="#ffffff" opacity="0.8"/>'
    c += estrela(130, -40, 46, "#fff3b0") + anel(130, 0, 100, 20, 6)
    for i in range(14):
        c += pedra(84 + (i * 29) % 100, -30 - (i * 31) % 120, 1.1 + (i % 3) * 0.4, i * 40)
    c += nota(-205, "2º toque = BOOM (ou o tempo acaba)", "as peças no raio DESABAM")
    ps.append(("3 · DETONA — explosão", c))
    c = laje(-110, 260, buraco=(80, 180))
    for i in range(6):
        c += pedra(88 + i * 16, 50 + (i % 3) * 20, 1.3, i * 50, CONC_D)
    c += rival(185, -140, rot=-120, sq=(1, 0.9)) + linhas_vel(185, -110, 3, 30, 1)
    c += poeira(130, -10, 9, 9, 60, 0.5) + marretao(pose, sem_ferramenta=True)
    c += nota(-205, "buraco no raio · rival LANÇADO longe", "fumaça assenta")
    ps.append(("4 · RESULTADO — buraco e voo", c))
    return ps


def prancha3():
    W, H = 1920, 1260
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "ATAQUES · LOTE 3 — A08 CANHÃO DE MOLAS e E02 CARGA REMOTA (proposta)", 32)]
    pw, ph = 452, 470
    arma_e02 = f'<g transform="translate(40,40) scale(1.6)">{dinamite(1.0, 1.0, "4")}</g><g transform="translate(110,46) scale(1.6)">{detonador()}</g>'
    for r, (nome, sub, ps, arma) in enumerate([
            ("A08 CANHÃO DE MOLAS", "mesmo efeito de hoje · projétil NOVO: mola grossa comprimida com tampão e faixa de perigo · estica no impacto (BOING)", a08(), canhao_molas_jogo()),
            ("E02 CARGA REMOTA", "dinamite com detonador de antena (sem fio azul) · gruda · bipe acelerando · explosão DESTRÓI as peças no raio e lança longe · sozinha em 4 s", e02(), arma_e02)]):
        y0 = 80 + r * (ph + 110)
        b.append(f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{nome}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        b.append(f'<g transform="translate({W - 300},{y0 - 4}) scale(1.6)">{arma}</g>' if r == 0 else f'<g transform="translate({W - 260},{y0 - 10})">{arma}</g>')
        b.append(f'<text x="{W - 200}" y="{y0 + 106}" text-anchor="middle" font-family="Arial" font-size="13" fill="{INK}">arte nova</text>')
        for j, (tit, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 80, pw, ph, tit, c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/eng_ataques_l3.png")
    queue(svg, os.path.join(HERE, "svg/eng_ataques_l3.svg"), out, W, H, 1)
    print(render_all(), out)


# ---- A08: 3 opções de arma (o usuário não gostou do canhão amarelo da prancha do lote 3)
def _espiras(x0, x1, cy, ry, n, w=4.2):
    o = ""
    for i in range(n):
        xx = x0 + (i + 0.5) * (x1 - x0) / n
        rx = max(1.4, (x1 - x0) / n * 0.55)
        o += f'<ellipse cx="{xx:.1f}" cy="{cy}" rx="{rx:.1f}" ry="{ry}" fill="none" stroke="#3f4654" stroke-width="{w + 2}"/>'
        o += f'<ellipse cx="{xx:.1f}" cy="{cy}" rx="{rx:.1f}" ry="{ry}" fill="none" stroke="{STEEL_L}" stroke-width="{w * 0.5}"/>'
    return o


def molas_a():
    """A · LANÇA-MOLA ABERTO: a mola fica À MOSTRA num trilho (tipo besta), puxada por uma catraca; tampão na frente."""
    o = f'<path d="M18,52 C6,60 2,48 8,42" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(18, 38, 14, 22, 4, "#2b2b33", k=0.3)
    o += R(10, 34, 112, 8, 3, "#3f4654", k=0.4) + R(10, 34, 112, 3, 2, "#5a6372", k=0.1)        # trilho
    o += R(8, 18, 16, 22, 4, "#e0702a", k=0.4) + E(16, 29, 5, 5, STEEL_D, k=0.1)                 # catraca
    o += "".join(f'<path d="M{9 + i * 4},18 l2,-4 l2,4" stroke="{STEEL_D}" stroke-width="1.4" fill="none"/>' for i in range(4))
    o += _espiras(26, 88, 26, 10, 7)                                                           # mola exposta
    o += R(88, 12, 18, 28, 5, "#e54b3c", k=0.4) + ab.cb.faixa(92, 20, 10, 12, n=3)              # tampão pronto
    o += R(108, 22, 16, 12, 3, STEEL, k=0.3) + R(118, 14, 6, 28, 2, STEEL_D, k=0.2)            # boca-guia
    return o


def molas_b():
    """B · BACAMARTE DE OBRA: boca de trombeta feita de cone de trânsito; a mola gigante sai pelas COSTAS (vê-se comprimir)."""
    o = f'<path d="M30,52 C18,60 14,48 20,42" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(30, 38, 14, 22, 4, "#2b2b33", k=0.3)
    o += _espiras(2, 34, 30, 13, 5, 5.0) + R(0, 18, 6, 24, 2, STEEL_D, k=0.2)                   # mola atrás
    o += R(30, 20, 46, 22, 7, "#5a6372", k=0.5) + R(30, 20, 46, 6, 4, "#7a828f", k=0.1)
    o += R(40, 14, 8, 8, 2, "#e0702a", k=0.2)
    o += P_([(74, 22), (124, 4), (124, 58), (74, 40)], "#f07a2a", k=0.5)                        # cone de trânsito
    o += P_([(88, 17), (100, 13), (100, 49), (88, 45)], "#ffffff", k=0.1) + P_([(108, 10), (116, 7), (116, 55), (108, 52)], "#ffffff", k=0.1)
    o += R(120, 2, 6, 60, 2, "#c25a1a", k=0.2)
    return o


def molas_c():
    """C · PISTÃO-MOLA COMPACTO: caixa industrial vermelha e preta; a mola é um cilindro de molas EMPILHADAS na frente,
    com o tampão já encaixado na boca e manômetro de pressão."""
    o = f'<path d="M18,52 C6,60 2,48 8,42" stroke="#2b2b33" stroke-width="5" fill="none" stroke-linecap="round"/>'
    o += R(18, 38, 14, 22, 4, "#2b2b33", k=0.3)
    o += R(10, 14, 54, 34, 8, "#c0392b", k=0.5) + R(10, 14, 54, 9, 6, "#e0574a", k=0.2) + ab.cb.faixa(14, 38, 46, 6, n=6)
    o += E(30, 26, 8, 8, "#f3ead8", k=0.1) + f'<circle cx="30" cy="26" r="8" fill="none" stroke="{DARK}" stroke-width="2.2"/><path d="M30,26 l5,-4" stroke="{EYE}" stroke-width="2" stroke-linecap="round"/>'
    o += R(62, 22, 46, 18, 4, "#2b2b33", k=0.4)
    tr_, fr_ = helice(64, 104, 11, 4.5, 3.0)
    o += f'<g transform="translate(0,31)">{tr_}{fr_}</g>'
    o += E(105, 31, 3, 13, "#8e98a4", k=0.15)   # o projétil pronto na boca: batente de borracha
    o += S("M107,17 C127,17 127,45 107,45 Z", "#e54b3c", (106, 16, 127, 46), k=0.4)
    o += f'<path d="M112,18 C114,26 114,36 112,44" stroke="#f2c84b" stroke-width="3" fill="none"/>'
    o += f'<path d="M116,22 C121,24 122,29 121,33" stroke="#ff9a8a" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
    return o


def opcoes_mola():
    W, H = 1920, 820
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "A08 CANHÃO DE MOLAS — 3 opções de arma (o efeito aprovado não muda)", 32)]
    tiro = dict(hip=(0, -22), lean=-8, head=4, feet=[(-14, 0), (12, 0)], tool=(9, -34, -150), bk=(8, -30), fr=(14, -36), face="foco")
    for i, (nome, txt, fn) in enumerate([("A · LANÇA-MOLA ABERTO", "mola à mostra num trilho, catraca puxa; tampão na frente", molas_a),
                                          ("B · BACAMARTE DE OBRA", "boca de cone de trânsito; molona sai pelas costas", molas_b),
                                          ("C · PISTÃO-MOLA COMPACTO", "caixa vermelha industrial; molas empilhadas na boca", molas_c)]):
        x = 30 + i * 630
        b.append(f'<rect x="{x}" y="90" width="610" height="700" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(x + 305, 132, nome, 26, INK) + label(x + 305, 162, txt, 16, "#2a4a58", "middle", 600))
        b.append(f'<g transform="translate({x + 50},200) scale(4)">{fn()}</g>')
        chao = f'<rect x="{x + 40}" y="740" width="530" height="8" rx="3" fill="#c9b99a"/>'
        robo = marretao(tiro, sem_ferramenta=True) + f'<g transform="translate(14,-36) rotate(-14) scale(0.42) translate(-24,-54)">{fn()}</g>'
        b.append(chao + f'<g transform="translate({x + 200},740) scale(2.6)">{robo}</g>')
        b.append(label(x + 470, 600, "na mão", 15, "#2a4a58", "middle", 600))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/a08_opcoes.png")
    queue(svg, os.path.join(HERE, "svg/a08_opcoes.svg"), out, W, H, 1)
    print(render_all(), out)


if __name__ == "__main__":
    if "--jogo" in sys.argv:
        exportar_jogo()
    elif "--l2" in sys.argv:
        prancha2()
    elif "--l3" in sys.argv:
        prancha3()
    elif "--a08" in sys.argv:
        opcoes_mola()
    elif "--a08p" in sys.argv:
        projetil_a08()
    else:
        prancha()
