"""REFORMULAÇÃO do robô (2026-11-27): geometria e proporções do Ultimate Chicken Horse (ref4) com a cara do nosso jogo.
Cabeça GRANDE (capacete-tela com olhos grandes), corpinho de pera, membros finos que dobram em curva, luvas e botinas
pequenas, capacete de obra com giroflex que balança. O que vende é o MOVIMENTO: corpo inteiro que achata/estica e verga,
cabeça e acessórios atrasados (molas), corrida quicante. Papel e giz, sem contorno.
Teste: correr + pular. Rodar: python3 art/src/robos/robo_uch.py → art/out/robos_v2/uch_teste.mp4 (+ _lento)
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import anim_blindado as ab  # noqa: E402  (motor: curva contínua + molas + render)
import conceito3_blindado as cb  # noqa: E402
from elenco import ik  # noqa: E402
from conceitos2 import rot  # noqa: E402
from svg import shade  # noqa: E402

YEL, YEL_D = "#f2c84b", "#c49a2a"
SCREEN = "#1f2a36"
GLOVE, GLOVE_D = "#f4f1ea", "#cfc8bc"
BOOT, SOLA = "#3d434e", "#f08a2b"

TH, SH_ = 13, 13      # coxa, canela
UA, FA = 10, 11       # braço, antebraço


def marreta(g, ang, s=0.72):
    body = cb.marreta_cabo() + cb.marreta_cabeca()
    g2 = (g[0] - math.cos(math.radians(ang)) * 11, g[1] - math.sin(math.radians(ang)) * 11)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f}) scale({s})">{body}</g>', g, g2


def olhos(face, x0=4):
    """Olhos grandes brancos na tela (expressão estilo UCH) + sobrancelha."""
    o = ""
    if face == "dor":
        return (f'<path d="M{x0 - 3},-5 L{x0 + 3},-2 L{x0 - 3},1 M{x0 + 14},-5 L{x0 + 8},-2 L{x0 + 14},1" stroke="#ffffff" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
                f'<path d="M{x0 + 2},6 q3,-2 6,0" stroke="#ffffff" stroke-width="1.6" fill="none"/>')
    if face == "vitoria":
        return (f'<path d="M{x0 - 3},0 Q{x0},-6 {x0 + 3},0 M{x0 + 8},0 Q{x0 + 11},-6 {x0 + 14},0" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                f'<path d="M{x0 + 1},4 Q{x0 + 5.5},9 {x0 + 10},4 Z" fill="#ffffff"/>')
    if face == "eliminado":
        return f'<path d="M{x0 - 3},-5 l6,6 m0,-6 l-6,6 M{x0 + 8},-5 l6,6 m0,-6 l-6,6" stroke="#ff6b6b" stroke-width="2.2" stroke-linecap="round"/>'
    big = face == "susto"
    for i, ex in enumerate((x0, x0 + 11)):
        ry = 6.5 if not big else 7.5
        if face in ("raiva",):
            ry = 4.6
        o += cb.E(ex, -2, 4.6 if not big else 5.2, ry, "#ffffff", k=0.3)
        pr = 2.3 if not big else 1.5
        o += f'<circle cx="{ex + 1.4:.1f}" cy="-1.5" r="{pr}" fill="#1a1a22"/><circle cx="{ex + 0.6:.1f}" cy="-3.2" r="0.9" fill="#ffffff"/>'
    if face == "raiva":
        o += f'<path d="M{x0 - 5},-10 L{x0 + 4},-6.5 M{x0 + 17},-6.5 L{x0 + 25},-10" stroke="#1a1a22" stroke-width="2.4" stroke-linecap="round"/>'
    elif face == "susto":
        o += f'<path d="M{x0 - 4},-12 Q{x0},-14 {x0 + 4},-12.5 M{x0 + 7},-12.5 Q{x0 + 11},-14 {x0 + 15},-12" stroke="#1a1a22" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
    return o


def cabeca(col, pose):
    """Capacete-tela grande: corpo da cabeça na cor do jogador, tela escura com olhos, capacete de obra e giroflex."""
    h = cb.R(-20, -21, 42, 38, 12, col, k=0.7)                                        # cabeça
    h += cb.R(-20, -21, 42, 9, 6, shade(col, 0.2), k=0.3)                              # luz no alto
    h += cb.R(-6, -12, 27, 22, 7, SCREEN, k=0.35)                                      # tela
    h += olhos(pose.get("face", "foco"), 0)
    h += cb.E(-18, 2, 4, 5, shade(col, -0.35), k=0.3) + f'<circle cx="-18" cy="2" r="1.6" fill="{cb.MEC_L}"/>'   # parafuso da orelha
    # capacete de obra (aba + domo) e giroflex que balança
    hat = cb.S("M-19,-20 C-19,-37 21,-37 21,-20 Z", YEL, (-20, -38, 22, -19), k=0.5, dark=YEL_D)
    hat += cb.R(-24, -22, 50, 5, 2.5, YEL_D, k=0.3) + f'<path d="M1,-35 v14" stroke="{YEL_D}" stroke-width="3"/>'
    sir = cb.R(-3, -41, 7, 5, 2, cb.MEC_D, k=0.3) + cb.E(0.5, -44, 4, 3.6, "#ffb22e", k=0.3)
    sir += f'<circle cx="0.5" cy="-44" r="{8 + 6 * pose.get("sirene", 0):.1f}" fill="#ffd27a" opacity="{0.22 + 0.4 * pose.get("sirene", 0):.2f}"/>'
    hat += f'<g transform="rotate({pose.get("sir_ang", 0) * 1.6:.1f} 0.5 -36)">{sir}</g>'
    return h + hat


def cabeca_L(col, e, L="all"):
    """Cabeça em camadas para o jogo (elenco.py → texturas): base / face (expressão) / acc (giroflex)."""
    face = {"normal": "foco", "esforco": "raiva", "ataque": "raiva", "forca": "raiva", "grito": "raiva", "esquiva": "susto"}.get(e, e or "foco")
    o = ""
    if L in ("all", "base"):
        o += cb.R(-20, -21, 42, 38, 12, col, k=0.7) + cb.R(-20, -21, 42, 9, 6, shade(col, 0.2), k=0.3)
        o += cb.R(-6, -12, 27, 22, 7, SCREEN, k=0.35)
        o += cb.E(-18, 2, 4, 5, shade(col, -0.35), k=0.3) + f'<circle cx="-18" cy="2" r="1.6" fill="{cb.MEC_L}"/>'
        o += cb.S("M-19,-20 C-19,-37 21,-37 21,-20 Z", YEL, (-20, -38, 22, -19), k=0.5, dark=YEL_D)
        o += cb.R(-24, -22, 50, 5, 2.5, YEL_D, k=0.3) + f'<path d="M1,-35 v14" stroke="{YEL_D}" stroke-width="3"/>'
    if L in ("all", "face"):
        if face == "piscar":
            o += '<path d="M-3,-2 h8 M8,-2 h8" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round"/>'
        else:
            o += olhos(face, 0)
    if L in ("all", "acc"):
        o += cb.R(-3, -41, 7, 5, 2, cb.MEC_D, k=0.3) + cb.E(0.5, -44, 4, 3.6, "#ffb22e", k=0.3)
        o += '<circle cx="0.5" cy="-44" r="7" fill="#ffd27a" opacity="0.25"/>'
    return o


def tronco(col, pose):
    """Corpinho de pera com placa de barriga e cinto de perigo."""
    t = cb.S("M-10,0 C-13,-6 -11,-17 0,-18 C11,-17 13,-6 10,0 Z", col, (-14, -19, 14, 1), k=0.6)
    t += cb.S("M-5,-2 C-6,-8 -4,-13 2,-13 C7,-13 8,-8 6,-2 Z", shade(col, 0.25), (-7, -14, 9, -1), k=0.3)
    t += cb.faixa(-10, -4, 21, 4, n=4)
    return t


def desenha(pose, col=ab.COL):
    hip, lean = pose["hip"], pose["lean"]
    lp, lc = lean * 0.5, lean * 0.5 + pose.get("bend", 0)
    neck = (2, -17)

    def T(p, extra=0.0):   # tronco → mundo (gira no quadril)
        q = rot(p, lp + lc * 0.3 + extra, (0, 0))
        return (q[0] + hip[0], q[1] + hip[1])
    sh_f, sh_b = T((5, -13)), T((-5, -13))
    if pose.get("oculto"):
        return ""
    fr = pose.get("fr")
    if fr is not None:   # mão da frente livre (borda): a marreta pendurada na mão de trás
        bk = pose["bk"]
        tool, g1, g2 = marreta(bk, pose["tool"][2])
        g1 = fr
    else:
        tool, g1, g2 = marreta(pose["tool"][:2], pose["tool"][2])
        bk = pose["bk"] if pose.get("bk") is not None else g2
    parts = []
    # perna de trás, braço de trás
    legs = []
    for i in range(2):
        hp = T((-4 if i == 0 else 4, -1))
        ft = pose["feet"][i]
        kn, en = ik(hp, (ft[0], ft[1] - 4), TH, SH_, lambda q: q[0])
        c = shade(col, -0.5 if i == 0 else -0.3)
        lg = ab.tubo(hp, kn, en, 6.5, 5.5, c)
        bx, by = en[0], en[1] + 4
        lg += cb.S(f"M{bx - 6},{by} C{bx - 7},{by - 7} {bx + 4},{by - 8} {bx + 9},{by - 3} L{bx + 10},{by} Z", shade(BOOT, -0.2 if i == 0 else 0), (bx - 8, by - 9, bx + 11, by + 1), k=0.4)
        lg += cb.R(bx - 7, by - 1.5, 18, 3, 1.5, shade(SOLA, -0.25 if i == 0 else 0), k=0.3)
        legs.append(lg)
    el, end = ik(sh_b, bk, UA, FA, lambda q: q[1])
    back_arm = ab.tubo(sh_b, el, end, 5, 4.5, shade(col, -0.5)) + cb.E(end[0], end[1], 5, 5, GLOVE_D, k=0.3)
    el, end = ik(sh_f, g1, UA, FA, lambda q: q[1])
    front_arm = ab.tubo(sh_f, el, end, 5.5, 5, shade(col, -0.25)) + cb.E(end[0], end[1], 5.5, 5.5, GLOVE, k=0.3)
    torso = f'<g transform="translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lp + lc * 0.3:.1f})">{tronco(col, pose)}</g>'
    hw = rot((neck[0], neck[1] + pose.get("hdy", 0.0)), lp + lc * 0.3, (0, 0))
    head = (f'<g transform="translate({hip[0] + hw[0]:.1f},{hip[1] + hw[1]:.1f}) rotate({lean * 0.6 + pose.get("head", 0):.1f}) '
            f'translate(0,-17)">{cabeca(col, pose)}</g>')
    behind = pose["tool"][2] < -110 and fr is None
    parts = ([tool] if behind else []) + [back_arm, legs[0], torso, legs[1], head] + ([] if behind else [tool]) + [front_arm]
    body = "".join(parts)
    sqx, sqy = pose["sq"]
    sk = pose.get("skew", 0.0)
    body = f'<g transform="skewX({sk:.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -40)">{body}</g>'
    return body


# ---------------------------------------------------------------- as 2 animações de teste
P = ab.P
PARADO = P(hip=(0, -24), lean=4, head=2, feet=[(-9, 0), (9, 0)], tool=(9, -34, -150), bk=(-12, -24))


def A_correr():
    base = dict(lean=22, head=-10, tool=(6, -32, -160), face="foco")
    k = [(0.0, P(hip=(0, -20), feet=[(-16, -3), (15, 0)], bk=(-18, -24), sq=(1.0, 0.86), **base)),
         (0.09, P(hip=(0, -30), feet=[(-4, -12), (3, -3)], bk=(-8, -30), sq=(1.0, 1.1), **base)),
         (0.18, P(hip=(0, -20), feet=[(15, 0), (-16, -3)], bk=(4, -26), sq=(1.0, 0.86), **base)),
         (0.27, P(hip=(0, -30), feet=[(3, -3), (-4, -12)], bk=(-8, -30), sq=(1.0, 1.1), **base)),
         (0.36, P(hip=(0, -20), feet=[(-16, -3), (15, 0)], bk=(-18, -24), sq=(1.0, 0.86), **base))]

    def fx(t, p):
        off = (t / 0.36 * 140) % 70
        return ("".join(f'<path d="M{x - off:.0f},2 h18" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-140, 180, 70))
                + ab.fx_dust(-22, 0, (t % 0.18) / 0.18, 0.6))
    return "CORRER", 0.36, k, fx, None


def A_pulo():
    air = dict(feet=[(-10, -10), (9, -6)], tool=(6, -34, -150), bk=(-12, -50))
    k = [(0.0, PARADO), (0.12, P(hip=(0, -15), sq=(1.0, 0.72), lean=22, head=12, feet=[(-10, 0), (10, 0)], tool=(9, -26, -150), bk=(-14, -14))),
         (0.18, P(hip=(0, -30), sq=(1.0, 1.16), oy=-16, lean=2, face="raiva", feet=[(-4, -2), (4, 0)], tool=(6, -36, -150), bk=(-6, -56))),
         (0.42, P(hip=(0, -28), oy=-52, lean=-4, head=-10, face="raiva", **air)),
         (0.62, P(hip=(0, -28), oy=-34, lean=6, sq=(1.0, 1.1), feet=[(-10, -4), (10, -2)], tool=(8, -36, -130), bk=(-16, -40), face="susto")),
         (0.72, P(hip=(0, -28), oy=0, lean=8, sq=(1.0, 1.12), feet=[(-10, 0), (10, 0)])),
         (0.78, P(hip=(0, -14), sq=(1.0, 0.7), lean=24, head=14, feet=[(-11, 0), (11, 0)], tool=(9, -24, -150), bk=(-14, -12))),
         (1.0, PARADO), (1.3, PARADO)]

    def fx(t, p):
        o = ""
        if 0.12 < t < 0.32:
            o += ab.fx_dust(0, 0, (t - 0.12) / 0.2)
        if 0.78 < t < 1.05:
            o += ab.fx_dust(0, 0, (t - 0.78) / 0.27, 1.4)
        return o
    return "PULAR", 1.3, k, fx, None


GUARD = P(hip=(0, -23), lean=10, head=4, feet=[(-11, 0), (11, 0)], tool=(12, -34, -60), face="foco")


def cabeca_marreta(p):
    g, a = p["tool"][:2], p["tool"][2]
    return (g[0] + math.cos(math.radians(a)) * 40, g[1] + math.sin(math.radians(a)) * 40)


def A_combo():
    k = [(0.00, GUARD),
         (0.05, P(lean=0, hip=(0, -22), tool=(6, -40, -110), face="raiva", sq=(1, 0.94))),
         (0.10, P(lean=24, hip=(2, -22), tool=(20, -30, 10), feet=[(-12, 0), (14, 0)], face="raiva", sq=(1, 1.06))),
         (0.24, P(lean=20, hip=(2, -22), tool=(20, -28, 18), feet=[(-12, 0), (14, 0)])),
         (0.30, P(lean=6, tool=(18, -24, 50), face="raiva")),
         (0.36, P(lean=18, head=-8, tool=(16, -42, -70), feet=[(-12, 0), (14, 0)], face="raiva", sq=(1, 1.08))),
         (0.52, P(lean=-12, hip=(0, -20), head=10, tool=(-2, -46, -150), face="raiva", sq=(1, 0.9))),
         (0.62, P(lean=30, hip=(3, -18), head=-8, tool=(22, -24, 70), feet=[(-15, 0), (16, 0)], face="raiva", sq=(1, 0.86))),
         (0.85, P(lean=28, hip=(3, -18), tool=(22, -22, 74), feet=[(-15, 0), (16, 0)])),
         (1.1, GUARD)]

    def fx(t, p):
        o = ""
        g = p["tool"][:2]
        if 0.06 < t < 0.16:
            o += ab.smear(g, -110, 10, 22, 48) + ab.fx_lines(46, -48, 3, 14, -1)
        if 0.31 < t < 0.42:
            o += ab.smear(g, 50, -70, 22, 48)
        if 0.54 < t < 0.7:
            o += ab.smear(g, -150, 70, 22, 48)
        if 0.62 < t < 0.92:
            kk = (t - 0.62) / 0.3
            o += ab.fx_onda(38, 0, kk) + ab.fx_estrela(38, -6, kk, 14)
        return o
    return "GOLPE LEVE (combo 1 · 2 · 3)", 1.1, k, fx, None


def A_pesado():
    car = P(hip=(0, -17), lean=-20, head=12, feet=[(-13, 0), (10, 0)], tool=(-6, -44, -140), face="raiva", sq=(1.08, 0.88))
    sol = P(hip=(3, -17), lean=34, head=-10, feet=[(-16, 0), (18, 0)], tool=(24, -22, 75), face="raiva", sq=(1, 0.84))
    k = [(0.0, GUARD), (0.15, car), (0.95, P(**{**car, "lean": -24, "hip": (0, -16), "sq": (1.1, 0.86)})), (1.05, sol),
         (1.4, P(**{**sol, "tool": (24, -16, 88), "sq": (1, 1)})), (2.0, GUARD)]

    def fx(t, p):
        o = ""
        if 0.15 < t < 1.0:
            kk = min((t - 0.15) / 0.8, 1)
            hx, hy = cabeca_marreta(p)
            r = 10 + 9 * kk
            o += f'<circle cx="{hx:.1f}" cy="{hy:.1f}" r="{r:.1f}" fill="#ffd27a" opacity="{0.25 + 0.4 * kk:.2f}"/>'
            for i in range(int(3 + 6 * kk)):
                a = t * 9 + i * 1.3
                o += f'<path d="M{hx + math.cos(a) * r:.1f},{hy + math.sin(a) * r:.1f} l{math.cos(a) * 5:.1f},{math.sin(a) * 5:.1f}" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>'
        if 0.96 < t < 1.12:
            o += ab.smear(p["tool"][:2], -140, 75, 22, 50)
        if 1.04 < t < 1.6:
            kk = (t - 1.04) / 0.56
            o += ab.fx_onda(44, 0, kk, 1.7) + ((ab.fx_estrela(44, -8, kk, 22) + ab.impacto(44, 0)) if kk < 0.35 else "")
        return o
    return "GOLPE PESADO (segura = carrega · solta)", 2.0, k, fx, "treme"


def A_esquiva():
    low = P(hip=(0, -17), lean=-18, head=10, feet=[(-16, 0), (8, 0)], tool=(8, -30, -160), bk=(-14, -22), face="susto", sq=(1.06, 0.9))
    k = [(0.0, GUARD), (0.04, low), (0.2, P(**{**low, "ox": -55})), (0.45, P(**{**GUARD, "ox": -55})), (0.8, P(**{**GUARD, "ox": 0}))]
    return "ESQUIVA", 0.8, k, None, "fantasma"


def A_duplo():
    tuck = dict(feet=[(-4, -14), (4, -12)], tool=(8, -32, -100), bk=(-2, -30), hip=(0, -28))
    air = dict(feet=[(-10, -8), (9, -5)], tool=(6, -34, -150), bk=(-12, -48))
    k = [(0.0, P(oy=-24, **air)), (0.08, P(oy=-30, feet=[(-3, -1), (5, 2)], tool=(6, -34, -150), bk=(-8, -52), sq=(1, 1.12))),
         (0.4, P(oy=-50, rot=360, face="raiva", **tuck)), (0.55, P(oy=-50, rot=360, **air)),
         (0.95, P(oy=0, rot=360, sq=(1, 1.1), feet=[(-10, 0), (10, 0)])), (1.02, P(rot=360, hip=(0, -15), sq=(1, 0.74), lean=22, head=12)), (1.3, P(rot=360, **{k_: v for k_, v in PARADO.items() if k_ != "rot"}))]

    def fx(t, p):
        if 0.05 < t < 0.2:
            return f'<circle cx="0" cy="{-44 + 6:.0f}" r="{6 + 30 * (t - 0.05):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.05) * 4:.2f}"/>'
        if 1.0 < t < 1.25:
            return ab.fx_dust(0, 0, (t - 1.0) / 0.25, 1.2)
        return ""
    return "PULO DUPLO (cambalhota)", 1.3, k, fx, None


def A_parede():
    wall = dict(lean=8, head=10, feet=[(-12, -6), (2, -2)], tool=(6, -34, -150), bk=(-20, -44), face="foco")
    k = [(0.0, P(ox=-32, oy=-52, **wall)), (0.9, P(ox=-32, oy=-16, **wall)),
         (1.0, P(ox=-30, oy=-18, lean=-8, hip=(0, -18), feet=[(-12, -2), (-6, 0)], tool=(6, -34, -150), bk=(-20, -36), sq=(1, 0.82))),
         (1.4, P(ox=50, oy=-56, lean=20, feet=[(-10, -10), (9, -6)], tool=(6, -34, -150), bk=(-12, -48), face="raiva", sq=(1, 1.1)))]

    def fx(t, p):
        o = '<rect x="-88" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-60" y="-200" width="6" height="210" fill="#b57a3e"/>'
        if t < 0.9:
            o += ab.fx_dust(-50, p["oy"] + 2, (t * 4) % 1, 0.45)
        return o
    return "PAREDE (desliza · pulo de parede)", 1.4, k, fx, None


def A_borda():
    hang = dict(hip=(0, -23), lean=0, head=-10, tool=(0, 0, 120), face="susto")
    k = [(0.0, P(oy=-26, feet=[(-3, -4), (4, -1)], bk=(-6, -18), fr=(20, -56), **hang)),
         (0.5, P(oy=-26, feet=[(-8, -1), (8, -6)], bk=(-6, -17), fr=(20, -56), **hang)),
         (0.9, P(oy=-26, feet=[(-3, -4), (4, -1)], bk=(-6, -18), fr=(20, -56), **hang)),
         (1.2, P(ox=12, oy=-66, hip=(0, -20), lean=26, head=0, feet=[(-6, -10), (12, -2)], tool=(8, -32, -150), bk=(-10, -22), face="raiva", sq=(1, 0.9))),
         (1.6, P(ox=34, oy=-82, **{k_: v for k_, v in PARADO.items() if k_ not in ("ox", "oy")}))]

    def fx(t, p):
        return '<rect x="22" y="-82" width="200" height="86" fill="#cfc6b4"/><rect x="22" y="-82" width="200" height="8" fill="#e8e0d0"/>'
    return "BORDA (pendurado · sobe)", 1.6, k, fx, None


def A_cima():
    k = [(0.0, GUARD), (0.07, P(hip=(0, -18), lean=12, tool=(14, -18, 60), face="raiva", sq=(1, 0.88))),
         (0.15, P(hip=(0, -27), lean=-8, head=-14, oy=-4, tool=(6, -48, -100), face="raiva", sq=(1, 1.12), feet=[(-11, 0), (11, -2)])),
         (0.45, P(hip=(0, -26), lean=-4, head=-10, tool=(4, -46, -108))), (0.8, GUARD)]

    def fx(t, p):
        if 0.08 < t < 0.45:
            return ab.smear(p["tool"][:2], 60, -100, 22, 48) + ab.fx_estrela(10, -92, (t - 0.15) / 0.3, 10)
        return ""
    return "GOLPE LEVE PARA CIMA", 0.8, k, fx, None


def A_baixo():
    air = dict(oy=-56, feet=[(-10, -9), (9, -6)])
    k = [(0.0, P(tool=(0, -50, -120), face="raiva", lean=-4, **air)),
         (0.08, P(tool=(0, -52, -130), lean=-8, face="raiva", sq=(1, 1.08), **air)),
         (0.16, P(tool=(12, -14, 92), lean=24, head=-10, face="raiva", **air)),
         (0.5, P(oy=0, tool=(12, -14, 92), lean=24, feet=[(-11, 0), (11, 0)], sq=(1, 0.8), hip=(0, -17))), (0.9, GUARD)]

    def fx(t, p):
        o = ""
        if 0.1 < t < 0.3:
            o += f'<g transform="translate(0,{p["oy"]:.0f})">{ab.smear((12, -14), -130, 92, 22, 48)}</g>'
        if 0.5 < t < 0.85:
            o += ab.fx_onda(16, 0, (t - 0.5) / 0.35)
        return o
    return "GOLPE LEVE PARA BAIXO (no ar)", 0.9, k, fx, None


def A_leva():
    hit = P(lean=-26, head=20, sq=(1, 1.1), ox=-12, hip=(-2, -23), feet=[(-14, -2), (8, 0)], tool=(4, -30, -160), bk=(-14, -14), face="dor")
    k = [(0.0, GUARD), (0.06, hit), (0.35, P(**{**hit, "ox": -20, "sq": (1, 0.92)})), (0.9, P(**{**GUARD, "ox": 0}))]

    def fx(t, p):
        return ab.fx_estrela(14, -46, (t - 0.04) / 0.25, 12) if 0.04 < t < 0.29 else ""
    return "LEVA GOLPE", 0.9, k, fx, None


def A_arremessado():
    fly = dict(feet=[(-14, -10), (-2, -18)], tool=(-10, -44, -170), bk=(-18, -40), face="susto", hip=(0, -28))
    k = [(0.0, GUARD), (0.05, P(ox=0, oy=-8, **fly)), (0.5, P(ox=-80, oy=-60, rot=-300, **fly)),
         (0.95, P(ox=-130, oy=-24, rot=-600, **fly)), (1.05, P(ox=-136, oy=-18, rot=-720, feet=[(-10, -4), (9, -2)], tool=(6, -34, -150), bk=(-12, -40))),
         (1.15, P(ox=-140, oy=0, rot=-720, sq=(1, 0.76), hip=(0, -16))), (1.6, P(ox=-140, rot=-720, **{k_: v for k_, v in PARADO.items() if k_ not in ("ox", "rot")}))]

    def fx(t, p):
        if t < 0.9:
            return f'<g transform="translate({p["ox"] + 30:.0f},{p["oy"] - 40:.0f})">{ab.fx_lines(0, 0, 4, 28, 1)}</g>'
        if 1.0 < t < 1.15:
            return f'<circle cx="{p["ox"]:.0f}" cy="{p["oy"] - 30:.0f}" r="{(t - 1.0) * 260:.0f}" fill="none" stroke="#ffffff" stroke-width="4" opacity="{1 - (t - 1) / 0.15:.2f}"/>'
        return ""
    return "ARREMESSADO (gira · recupera)", 1.6, k, fx, "desloca"


def A_engenhoca():
    k = [(0.0, PARADO), (0.12, P(**{**PARADO, "bk": (18, -40), "lean": 12, "face": "raiva", "sq": (1, 1.05)})),
         (0.6, P(**{**PARADO, "bk": (19, -38), "lean": 12, "face": "raiva"})), (1.0, PARADO)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="16" y="-50" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="21" cy="-53" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(21, -58, kk, 13) + f'<circle cx="21" cy="-44" r="{8 + kk * 50:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return "USAR ENGENHOCA", 1.0, k, fx, None


def A_vitoria():
    up = P(hip=(0, -26), lean=-4, head=-10, feet=[(-10, 0), (10, 0)], tool=(16, -54, -62), bk=(-16, -50), face="vitoria")
    k = [(0.0, up), (0.4, P(**{**up, "oy": -16, "sirene": 1, "feet": [(-8, -4), (8, -4)], "sq": (1, 1.08)})), (0.8, P(**{**up, "sq": (1, 0.9)})),
         (1.2, P(**{**up, "oy": -16, "sirene": 1, "feet": [(-8, -4), (8, -4)], "sq": (1, 1.08)})), (1.6, up)]
    return "VITÓRIA", 1.6, k, None, None


def A_eliminado():
    k = [(0.0, P(**{**GUARD, "face": "susto"})), (0.14, P(**{**GUARD, "face": "eliminado", "sq": (1, 0.8), "hip": (0, -17)})),
         (0.2, P(**{**GUARD, "face": "eliminado", "oculto": True})), (1.4, P(**{**GUARD, "oculto": True}))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:   # explosão cartoon
            r = 20 + 60 * u
            o += f'<circle cx="0" cy="-40" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-40" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, cabeca(ab.COL, {"face": "eliminado"})), (50, -120, -500, tronco(ab.COL, {})),
                 (-30, -90, 700, cb.R(-7, -7, 15, 15, 6, cb.MEC_D, k=0.45)), (70, -70, -800, marreta((0, 0), 0)[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -40 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.9)">{svg}</g>'
        return o
    return "ELIMINADO (desmonta)", 1.4, k, fx, None


def main():
    import sys as _s
    if "--resto" in _s.argv:
        ab.desenha = desenha
        ab.SC = 2.0
        ab.ANIMS = [A_duplo, A_parede, A_borda, A_cima, A_baixo, A_leva, A_arremessado, A_engenhoca, A_vitoria, A_eliminado]
        ab.LOOPS = {A_vitoria}
        ab.main()
        for a, b in (("anim_blindado.mp4", "uch_resto.mp4"), ("anim_blindado_lento.mp4", "uch_resto_lento.mp4"), ("anim_blindado_folha.png", "uch_resto_folha.png")):
            if os.path.exists(os.path.join(ab.OUT, a)):
                os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))
        return
    if "--golpes" in _s.argv:
        ab.desenha = desenha
        ab.SC = 2.0
        ab.ANIMS = [A_combo, A_pesado, A_esquiva]
        ab.LOOPS = set()
        ab.main()
        for a, b in (("anim_blindado.mp4", "uch_golpes.mp4"), ("anim_blindado_lento.mp4", "uch_golpes_lento.mp4"), ("anim_blindado_folha.png", "uch_golpes_folha.png")):
            if os.path.exists(os.path.join(ab.OUT, a)):
                os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))
        return
    ab.desenha = desenha
    ab.SC = 2.0
    ab.ANIMS = [A_correr, A_pulo]
    ab.LOOPS = {A_correr}
    out_prev = os.path.join(ab.OUT, "anim_blindado.mp4")
    ab.main()
    for a, b in (("anim_blindado.mp4", "uch_teste.mp4"), ("anim_blindado_lento.mp4", "uch_teste_lento.mp4"), ("anim_blindado_folha.png", "uch_teste_folha.png")):
        if os.path.exists(os.path.join(ab.OUT, a)):
            os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))


if __name__ == "__main__":
    main()
