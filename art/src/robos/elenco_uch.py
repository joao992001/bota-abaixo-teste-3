"""CONCEITOS do ELENCO no modelo aprovado (A27, estilo Ultimate Chicken Horse + papel e giz): 5 robôs com SILHUETA, vibe,
arma e jeito de mover muito diferentes — reconhecíveis só pelo contorno no meio da confusão. Mesmas regras de jogo.
Rodar: python3 art/src/robos/elenco_uch.py → art/out/robos_v2/elenco_uch.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import anim_blindado as ab  # noqa: E402
import conceito3_blindado as cb  # noqa: E402
import robo_uch as ru  # noqa: E402
from elenco import ik, label, INK  # noqa: E402
from conceitos2 import rot  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

R, E, S, P_ = cb.R, cb.E, cb.S, cb.P
tubo = ab.tubo
STEEL, STEEL_D, STEEL_L = cb.STEEL, cb.STEEL_D, cb.STEEL_L
YEL, YEL_D = "#f2c84b", "#c49a2a"
SCREEN = "#1f2a36"
GLOVE, GLOVE_D = "#f4f1ea", "#cfc8bc"


def olhos_tela(face, x0, y0, r=4.4, gap=10):
    o = ""
    if face == "vitoria":
        return f'<path d="M{x0 - r},{y0 + 1} Q{x0},{y0 - r * 1.4} {x0 + r},{y0 + 1} M{x0 + gap - r},{y0 + 1} Q{x0 + gap},{y0 - r * 1.4} {x0 + gap + r},{y0 + 1}" stroke="#ffffff" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
    if face == "dor":
        return f'<path d="M{x0 - r},{y0 - r} L{x0 + r * 0.6},{y0} L{x0 - r},{y0 + r} M{x0 + gap + r},{y0 - r} L{x0 + gap - r * 0.6},{y0} L{x0 + gap + r},{y0 + r}" stroke="#ffffff" stroke-width="2" fill="none" stroke-linecap="round"/>'
    if face == "eliminado":
        return f'<path d="M{x0 - r},{y0 - r} l{2 * r},{2 * r} m0,{-2 * r} l{-2 * r},{2 * r} M{x0 + gap - r},{y0 - r} l{2 * r},{2 * r} m0,{-2 * r} l{-2 * r},{2 * r}" stroke="#ff6b6b" stroke-width="2" stroke-linecap="round"/>'
    if face == "piscar":
        return f'<path d="M{x0 - r},{y0} h{2 * r} M{x0 + gap - r},{y0} h{2 * r}" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round"/>'
    if face == "susto":
        r *= 1.15
    for i in range(2):
        ex = x0 + i * gap
        ry = r * (1.45 if face != "raiva" else 1.0)
        o += E(ex, y0, r, ry, "#ffffff", k=0.3) + f'<circle cx="{ex + r * 0.3:.1f}" cy="{y0 + 0.5:.1f}" r="{r * 0.5:.1f}" fill="#1a1a22"/>'
    if face == "raiva":
        o += f'<path d="M{x0 - r},{y0 - r * 1.8} L{x0 + r},{y0 - r * 0.9} M{x0 + gap - r},{y0 - r * 0.9} L{x0 + gap + r},{y0 - r * 1.8}" stroke="#1a1a22" stroke-width="2.2" stroke-linecap="round"/>'
    return o


def corpo_generico(spec, col, pose):
    """Monta qualquer robô do elenco: pernas e braços em curva por IK, tronco, cabeça e arma de cada um."""
    hip, lean = pose["hip"], pose.get("lean", 0)

    def T(p):
        q = rot(p, lean * 0.6, (0, 0))
        return (q[0] + hip[0], q[1] + hip[1])
    out_b, out_f = [], []
    th, sh, lw0, lw1 = spec["leg"]
    for i in range(2):
        hp = T((-spec["hip_w"] if i == 0 else spec["hip_w"], -1))
        ft = pose["feet"][i]
        kn, en = ik(hp, (ft[0], ft[1] - spec["foot_h"]), th, sh, lambda q: q[0] * spec.get("knee", 1))
        c = shade(col, -0.5 if i == 0 else -0.3)
        lg = tubo(hp, kn, en, lw0, lw1, c) + spec["boot"](en, i == 0)
        (out_b if i == 0 else out_f).append(lg)
    ua, fa, aw = spec["arm"]
    shb, shf = T(spec["sh_b"]), T(spec["sh_f"])
    g = pose["grip"]
    weapon, g1, g2 = spec["weapon"](g, pose["ang"], pose)
    bk = pose.get("bk") or g2
    el, end = ik(shb, bk, ua, fa, lambda q: q[1])
    back = tubo(shb, el, end, aw, aw * 0.9, shade(col, -0.5)) + spec["hand"](end, True)
    el, end = ik(shf, g1, ua, fa, lambda q: q[1])
    front = tubo(shf, el, end, aw * 1.1, aw, shade(col, -0.25)) + spec["hand"](end, False)
    torso = f'<g transform="translate({hip[0]:.1f},{hip[1]:.1f}) rotate({lean * 0.6:.1f})">{spec["torso"](col, pose)}</g>'
    hp = T(spec["neck"])
    head = f'<g transform="translate({hp[0]:.1f},{hp[1]:.1f}) rotate({lean * 0.7 + pose.get("head", 0):.1f})">{spec["head"](col, pose)}</g>'
    behind = spec.get("behind", lambda p: False)(pose)
    parts = spec.get("pre", lambda c, p: "")(col, pose)
    parts += (weapon if behind else "") + back + out_b[0] + torso + spec.get("neck_draw", lambda c, a, b: "")(col, T((0, -spec["torso_h"])), hp) + out_f[0] + head + ("" if behind else weapon) + front
    sq = pose.get("sq", (1, 1))
    return spec.get("fx_b", lambda p: "")(pose) + f'<g transform="scale({sq[0]},{sq[1]})">{parts}</g>' + spec.get("fx", lambda p: "")(pose)


def mao(end, back):
    return E(end[0], end[1], 5, 5, GLOVE_D if back else GLOVE, k=0.3)


def botina(en, back, w=1.0):
    bx, by = en[0], en[1] + 4
    return (S(f"M{bx - 6 * w},{by} C{bx - 7 * w},{by - 7} {bx + 4 * w},{by - 8} {bx + 9 * w},{by - 3} L{bx + 10 * w},{by} Z", shade("#3d434e", -0.2 if back else 0), (bx - 9 * w, by - 9, bx + 11 * w, by + 1), k=0.4)
            + R(bx - 7 * w, by - 1.5, 18 * w, 3, 1.5, shade("#f08a2b", -0.25 if back else 0), k=0.3))


# ---------------------------------------------------------------- 1 MARRETÃO (o aprovado)
def marretao(col, pose):
    p = ab.P(**pose)
    p.setdefault("bend", 0)
    return ru.desenha(p, col)


# ---------------------------------------------------------------- 2 BRITA: baixinho largo, cabeça de BETONEIRA, britadeira
def _Lb(pose):
    return pose.get("L", "all") in ("all", "base")


def _Lf(pose):
    return pose.get("L", "all") in ("all", "face")


def _La(pose):
    return pose.get("L", "all") in ("all", "acc")


def olho_unico(cx, cy, r, face, pupil="#123"):
    """Rosto de 1 lente (Guindaste/Escavadeira/Solda) com as expressões do jogo."""
    if face == "eliminado":
        return f'<path d="M{cx - r},{cy - r} l{2 * r},{2 * r} m0,{-2 * r} l{-2 * r},{2 * r}" stroke="#ff6b6b" stroke-width="2.2" stroke-linecap="round"/>'
    if face == "vitoria":
        return f'<path d="M{cx - r},{cy + 1} Q{cx},{cy - r * 1.4} {cx + r},{cy + 1}" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
    if face == "piscar":
        return f'<path d="M{cx - r},{cy} h{2 * r}" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round"/>'
    pr = r * (0.35 if face == "susto" else 0.5)
    o = f'<circle cx="{cx + (1.5 if face == "raiva" else 0)}" cy="{cy}" r="{pr:.1f}" fill="{pupil}"/><circle cx="{cx - r * 0.3:.1f}" cy="{cy - r * 0.35:.1f}" r="{r * 0.22:.1f}" fill="#fff"/>'
    if face == "raiva":
        o += f'<path d="M{cx - r * 1.6},{cy - r * 1.7} L{cx + r * 1.4},{cy - r * 1.1}" stroke="#1a1a22" stroke-width="2.4" stroke-linecap="round"/>'
    return o


def brita_head(col, pose):
    if not _Lb(pose):
        h = ""
        if _Lf(pose):
            h += olhos_tela(pose.get("face", "foco"), 4, -9, 3.6, 9)
        if _La(pose):
            h += f'<path d="M14,-34 l3,-7" stroke="{cb.MEC_D}" stroke-width="2"/><circle cx="17.5" cy="-42" r="2.6" fill="#ffb22e"/>'
        return h
    h = f'<g transform="rotate(-14)">' + E(0, -18, 25, 17, col, k=0.7)                      # tambor
    for i in range(4):
        x = -18 + i * 11
        h += f'<path d="M{x},-33 Q{x + 7},-18 {x},-3" stroke="{shade(col, -0.3)}" stroke-width="4.5" fill="none"/>'
    h += E(-24, -22, 5, 9, shade(col, -0.45), k=0.3) + E(-25, -22, 2.6, 5, "#2a2230", k=0.2) + "</g>"   # boca do tambor
    h += R(-2, -16, 22, 15, 6, SCREEN, k=0.35)
    if pose.get("L", "all") == "all":
        h += brita_head(col, dict(pose, L="face")) + brita_head(col, dict(pose, L="acc"))
    return h


def brita_torso(col, pose):
    return R(-15, -15, 30, 16, 7, col, k=0.6) + cb.faixa(-15, -5, 30, 4, n=5)


def britadeira(g, ang, pose):
    """Britadeira: alça em T na pegada; corpo e ponteira descem no ângulo."""
    body = R(-11, -2.5, 22, 5, 2.5, "#3a3f4a", k=0.4)                                         # alça (pegada)
    body += R(-6, 2, 12, 26, 3, YEL, k=0.5, dark=YEL_D) + R(-6, 8, 12, 4, 1, "#2a1a2e", k=0.2) + R(-6, 15, 12, 4, 1, "#2a1a2e", k=0.2)
    body += R(-3.5, 28, 7, 7, 1.5, STEEL_D, k=0.3) + P_([(-2.5, 35), (2.5, 35), (0, 46)], STEEL, k=0.3)
    a = ang - 90
    g2 = (g[0] - math.cos(math.radians(ang + 90)) * 8, g[1] - math.sin(math.radians(ang + 90)) * 8)
    g1 = (g[0] + math.cos(math.radians(ang + 90)) * 8, g[1] + math.sin(math.radians(ang + 90)) * 8)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({a:.1f})">{body}</g>', g1, g2


BRITA = dict(nome="BRITA", vibe="baixinho elétrico: vibra, quica, passinhos rápidos", arma="britadeira (pula em cima dela)",
             hip_w=8, leg=(7, 8, 7.5, 7), foot_h=4, arm=(9, 9, 6), sh_b=(-11, -10), sh_f=(11, -10), torso_h=15, neck=(2, -13),
             torso=brita_torso, head=brita_head, weapon=britadeira, hand=mao, boot=lambda en, b: botina(en, b, 1.15))
BRITA_P = {"parado": dict(hip=(0, -15), lean=4, feet=[(-12, 0), (12, 0)], grip=(16, -18), ang=0, bk=None),
           "golpe": dict(hip=(0, -15), lean=14, feet=[(-14, 0), (14, 0)], grip=(22, -18), ang=-90, face="raiva", sq=(1.05, 0.95))}


def brita_fx(pose):
    if pose.get("face") == "raiva" and pose.get("rajada", True):
        return "".join(f'<path d="M{56 + i * 4},{-24 + i * 6} l8,0" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>' for i in range(3)) + \
            "".join(f'<path d="M{48},{-18 + d} l6,{d * 0.5}" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>' for d in (-6, 0, 6))
    return ""


BRITA["fx"] = brita_fx


# ---------------------------------------------------------------- 3 GUINDASTE (refeito 2026-11-27, opção G2 "LANÇA"): olhão-lente gigante,
# corpinho de pera, empunha a LANÇA treliçada do guindaste com o gancho pendurado na ponta (o gancho balança com mola).
GLASS = "#7fd3ff"


def guinda_head(col, pose):
    f = pose.get("face", "foco")
    h = ""
    if _Lb(pose):
        h += E(0, -10, 20, 18, col, k=0.7) + E(-2, -20, 14, 6, shade(col, 0.2), k=0.3)
        h += E(4, -9, 13, 13, "#2a2f38", k=0.3) + E(4, -9, 10, 10, GLASS, k=0.2)
        h += R(-22, -14, 5, 10, 2, YEL, k=0.3)
    if _Lf(pose):
        h += olho_unico(4, -9, 8.5, f)
    if _La(pose):
        h += f'<path d="M-12,-25 v-3" stroke="{cb.MEC_D}" stroke-width="1.6"/>' + E(-12, -29, 3, 3, "#ffb22e", k=0.2)
    return h


def guinda_torso(col, pose):
    return S("M-11,0 C-14,-8 -11,-22 0,-23 C11,-22 14,-8 11,0 Z", col, (-15, -24, 15, 1), k=0.6) + R(-11, -6, 22, 4, 2, YEL, k=0.3)


def gancho_ponta(x, y, drop, swing=0.0):
    """Cabo + gancho pendurados em (x, y); swing = deslocamento lateral do gancho (mola)."""
    ex, ey = x + swing, y + drop
    return (f'<path d="M{x:.1f},{y:.1f} L{ex:.1f},{ey:.1f}" stroke="{STEEL_D}" stroke-width="1.8" stroke-dasharray="3 1.5"/>'
            + R(ex - 4, ey - 1, 8, 6, 2, YEL, k=0.3, dark=YEL_D)
            + f'<path d="M{ex:.1f},{ey + 5:.1f} v4 a6,6 0 1 1 -9,5" stroke="{STEEL}" stroke-width="4.5" fill="none" stroke-linecap="round"/>')


LANCA_L = 44


def lanca(g, ang, pose):
    """Lança treliçada amarela: pegada em g, aponta no ângulo ang; gancho pendurado na ponta (chain_L = cabo, chain_sag = balanço)."""
    L = LANCA_L
    body = R(-6, -4, L + 6, 8, 2, YEL, k=0.5, dark=YEL_D)
    body += "".join(f'<path d="M{x},-3 L{x + 5},3 L{x + 10},-3" stroke="{YEL_D}" stroke-width="1.6" fill="none"/>' for x in range(-4, L - 4, 10))
    body += R(-10, -5, 8, 10, 2, "#3a3f4a", k=0.3) + E(L, 0, 3.2, 3.2, STEEL_D, k=0.2)
    o = f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>'
    if not pose.get("sem_gancho"):
        tip = (g[0] + math.cos(math.radians(ang)) * L, g[1] + math.sin(math.radians(ang)) * L)
        o += gancho_ponta(tip[0], tip[1], pose.get("chain_L", 14), pose.get("chain_sag", 0))
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return o, g, g2


GUINDA = dict(nome="GUINDASTE", vibe="o alto do olhão: calmo, ginga, cutuca de longe", arma="lança do guindaste com gancho na ponta",
              hip_w=6, leg=(12, 13, 7, 6.5), foot_h=4, arm=(11, 11, 6), sh_b=(-7, -18), sh_f=(7, -18), torso_h=22, neck=(1, -22),
              torso=guinda_torso, head=guinda_head, weapon=lanca, hand=mao, boot=lambda en, b: botina(en, b, 1.1))
GUINDA_P = {"parado": dict(hip=(0, -24), lean=3, feet=[(-10, 0), (10, 0)], grip=(10, -22), ang=-60),
            "golpe": dict(hip=(0, -22), lean=18, head=-4, feet=[(-15, 0), (17, 0)], grip=(16, -26), ang=-4, face="raiva")}


# ---------------------------------------------------------------- 4 SOLDA: corcunda, máscara de solda, tanques nas costas, chave inglesa
def solda_head(col, pose):
    h = ""
    glow = "#ff8a2a"
    f = pose.get("face", "foco")
    if _Lb(pose):
        h += R(-15, -16, 30, 30, 7, "#4a505c", k=0.6) + R(-13, -14, 26, 26, 6, shade("#4a505c", 0.12), k=0.3)   # máscara
        h += R(-3, -6, 17, 9, 3, "#1f1a1a", k=0.2)                                                              # visor
        h += R(-15, -20, 30, 6, 3, col, k=0.4) + E(-15, -1, 3.5, 3.5, cb.MEC_L, k=0.2)   # faixa na cor + dobradiça
    if _Lf(pose):
        if f == "eliminado":
            h += '<path d="M0,-4 l5,5 m0,-5 l-5,5 M7,-4 l5,5 m0,-5 l-5,5" stroke="#ff6b6b" stroke-width="1.8" stroke-linecap="round"/>'
        elif f == "vitoria":
            h += f'<path d="M-1,0 Q6,-7 13,0" stroke="{glow}" stroke-width="3" fill="none" stroke-linecap="round"/>'
        elif f == "piscar":
            h += f'<path d="M-1,-1.5 h14" stroke="{glow}" stroke-width="1.6" stroke-linecap="round"/>'
        elif f == "raiva":
            h += P_([(-2, -4), (12, -1), (12, 3), (-2, 0)], glow, k=0.2)
        elif f == "susto":
            h += R(-1, -5, 15, 7, 3, glow, k=0.2)
        else:
            h += R(-2, -4, 15, 5, 2.5, glow, k=0.2)
        if f not in ("eliminado", "piscar"):
            h += f'<rect x="-2" y="-5" width="15" height="7" rx="3" fill="{glow}" opacity="0.25"/>'
    return h


def solda_torso(col, pose):
    return S("M-12,0 C-15,-10 -10,-22 2,-22 C13,-21 14,-9 11,0 Z", col, (-16, -23, 15, 1), k=0.6) + R(-12, -6, 23, 4, 2, "#5a3d2b", k=0.3)


def solda_tanques(col, pose):
    hip, lean = pose["hip"], pose.get("lean", 0)
    q = rot((-14, -14), lean * 0.6, (0, 0))
    x, y = q[0] + hip[0], q[1] + hip[1]
    return (f'<g transform="translate({x:.1f},{y:.1f}) rotate({lean * 0.6:.1f})">' + R(-8, -14, 8, 22, 4, "#d9482b", k=0.5) + R(-1, -12, 8, 20, 4, "#e8a33a", k=0.5)
            + R(-6, -17, 4, 4, 1, STEEL_D, k=0.2) + f'<path d="M3,-12 C10,-24 18,-22 20,-14" stroke="#2a2a30" stroke-width="2" fill="none"/></g>')


def chave(g, ang, pose):
    body = R(-14, -3.5, 46, 7, 3, STEEL, k=0.5, dark=STEEL_D, light=STEEL_L)
    body += S("M30,-12 L44,-12 L46,-4 L38,-4 L38,4 L46,4 L44,12 L30,12 Z", STEEL, (29, -13, 47, 13), k=0.5, dark=STEEL_D, light=STEEL_L)
    body += E(32, 0, 2.5, 2.5, STEEL_D, k=0.2) + R(-14, -4, 12, 8, 3, "#c0392b", k=0.3)
    q = pose.get("quente", 0.0)
    if q > 0.01:   # chave aquecida no maçarico: brilha laranja/vermelho na cabeça
        body += f'<path d="M12,-3.5 L46,-12 L46,12 L12,3.5 Z" fill="#ff5a1f" opacity="{0.55 * q:.2f}"/><circle cx="38" cy="0" r="{12 + 8 * q:.1f}" fill="#ffb347" opacity="{0.3 * q:.2f}"/>'
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def solda_fx(pose):
    if pose.get("face") == "raiva" and pose.get("fx_fixo", True):
        return "".join(f'<path d="M58,-30 l{math.cos(a) * 12:.1f},{math.sin(a) * 12:.1f}" stroke="#ffd36b" stroke-width="2" stroke-linecap="round"/>' for a in (-2.6, -2.0, -1.4, -0.8, -0.2))
    return ""


SOLDA = dict(nome="SOLDA", vibe="ranzinza corcunda: anda gingando, faísca o tempo todo", arma="chave inglesa gigante + maçarico",
             hip_w=6, leg=(11, 12, 6, 5.5), foot_h=4, arm=(11, 12, 5.5), sh_b=(-6, -17), sh_f=(7, -17), torso_h=20, neck=(8, -26),
             torso=solda_torso, head=solda_head, weapon=chave, hand=lambda e, b: E(e[0], e[1], 5.5, 5.5, "#7a4a2a" if not b else "#5e3a22", k=0.3),
             boot=lambda en, b: botina(en, b, 1.05), pre=solda_tanques, fx=solda_fx, knee=1)
SOLDA_P = {"parado": dict(hip=(0, -22), lean=16, head=6, feet=[(-11, 0), (11, 0)], grip=(14, -20), ang=-50),
           "golpe": dict(hip=(0, -21), lean=26, head=-4, feet=[(-14, 0), (16, 0)], grip=(26, -28), ang=-10, face="raiva")}


# ---------------------------------------------------------------- 5 ESCAVADEIRA (refeita 2026-11-27, opção E2 "TRATOR"): cabeça com
# LÂMINA de trator na frente (olhos de tela espiando), escapamento, esteira na cintura, braço-caçamba.
def escava_head(col, pose):
    h = ""
    if _Lb(pose):
        h += R(-16, -26, 34, 30, 8, col, k=0.7) + R(-16, -26, 34, 7, 4, shade(col, 0.2), k=0.3)
        h += R(-6, -20, 24, 12, 6, SCREEN, k=0.35)
        h += S("M10,-6 C20,-8 26,-2 26,6 C26,12 20,14 10,12 Z", YEL, (9, -9, 27, 15), k=0.5, dark=YEL_D)                # lâmina
        h += f'<path d="M12,-3 C20,-4 23,1 23,6" stroke="{shade(YEL, 0.3)}" stroke-width="2" fill="none"/>'
    if _Lf(pose):
        h += olhos_tela(pose.get("face", "foco"), 1.5, -14, 3.6, 9)
    if _La(pose):
        h += R(-8, -34, 8, 8, 2, cb.MEC_D, k=0.2) + f'<circle cx="-4" cy="-38" r="3" fill="#8a8a8a" opacity="0.6"/>'      # escapamento
    return h


def escava_torso(col, pose):
    t = R(-17, -26, 34, 22, 7, col, k=0.6)
    t += R(-19, -8, 38, 9, 4.5, "#3a3f4a", k=0.4) + "".join(E(x, -3.5, 2.6, 2.6, STEEL, k=0.15) for x in (-13, -6, 1, 8, 15))
    return t


def cacamba(g, ang, pose):
    body = R(-8, -5, 14, 10, 3, "#4a505c", k=0.4) + R(2, -4, 10, 8, 2, STEEL, k=0.3)            # pistão hidráulico
    body += S("M8,-18 L34,-16 C39,-6 39,8 32,15 L8,13 Z", YEL, (7, -19, 40, 16), k=0.6, dark=YEL_D)
    for i in range(4):
        y = -12 + i * 7.5
        body += P_([(32, y), (41, y + 2.5), (32, y + 5)], STEEL, k=0.2)
    body += R(10, -16, 4, 28, 1.5, YEL_D, k=0.2)
    g2 = (g[0] - math.cos(math.radians(ang)) * 6, g[1] - math.sin(math.radians(ang)) * 6)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


ESCAVA = dict(nome="ESCAVADEIRA", vibe="o trator: pisa forte, empurra com a lâmina", arma="braço-caçamba (pega e arremessa)",
              hip_w=9, leg=(9, 9, 9, 8.5), foot_h=5, arm=(12, 12, 8), sh_b=(-12, -20), sh_f=(12, -20), torso_h=26, neck=(1, -26),
              torso=escava_torso, head=escava_head, weapon=cacamba, hand=lambda e, b: E(e[0], e[1], 5.5, 5.5, GLOVE_D if b else GLOVE, k=0.3),
              boot=lambda en, b: botina(en, b, 1.4))
ESCAVA_P = {"parado": dict(hip=(0, -18), lean=4, feet=[(-13, 0), (13, 0)], grip=(22, -14), ang=10, bk=(-20, -10)),
            "golpe": dict(hip=(0, -18), lean=-6, head=-6, feet=[(-15, 0), (15, 0)], grip=(20, -46), ang=-80, face="raiva", bk=(-22, -16))}


ELENCO = [("MARRETÃO", "o equilibrado: capacete-tela, quica e verga", "marreta de demolição", None, None),
          (BRITA["nome"], BRITA["vibe"], BRITA["arma"], BRITA, BRITA_P),
          (GUINDA["nome"], GUINDA["vibe"], GUINDA["arma"], GUINDA, GUINDA_P),
          (SOLDA["nome"], SOLDA["vibe"], SOLDA["arma"], SOLDA, SOLDA_P),
          (ESCAVA["nome"], ESCAVA["vibe"], ESCAVA["arma"], ESCAVA, ESCAVA_P)]
COLS = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b", "#4f86d9"]


def desenha(i, col, pose_k):
    nome, _, _, spec, poses = ELENCO[i]
    if spec is None:
        pz = dict(ru.PARADO) if pose_k == "parado" else dict(hip=(3, -18), lean=30, head=-8, feet=[(-15, 0), (16, 0)], tool=(22, -24, 70), face="raiva", sq=(1, 0.9))
        out = marretao(col, {k: v for k, v in pz.items()})
        if pose_k == "golpe":
            out += ab.fx_onda(38, 0, 0.3) + ab.fx_estrela(38, -6, 0.3, 14)
        return out
    return corpo_generico(spec, col, poses[pose_k])


def silhueta(svg):
    return f'<g filter="url(#sil)">{svg}</g>'


def prancha():
    W, H = 1920, 1250
    defs = '<filter id="sil"><feColorMatrix type="matrix" values="0 0 0 0 0.16  0 0 0 0 0.1  0 0 0 0 0.18  0 0 0 1 0"/></filter>'
    b = [f'<defs>{defs}</defs><rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 58, "ELENCO — 5 ROBÔS, 5 SILHUETAS (estilo aprovado)", 40)]
    cw = 376
    for i, (nome, vibe, arma, spec, poses) in enumerate(ELENCO):
        x = 12 + i * (cw + 4)
        cx = x + cw / 2
        col = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b", "#f08a3d"][i]
        b.append(f'<rect x="{x}" y="90" width="{cw}" height="860" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(cx, 136, nome, 30, INK))
        b.append(label(cx, 166, vibe.split(":")[0], 17, "#2a4a58"))
        b.append(label(cx, 188, vibe.split(":")[1].strip() if ":" in vibe else "", 15, "#2a4a58", "middle", 600))
        b.append(label(cx, 212, "arma: " + arma, 15, "#6b5a70", "middle", 600))
        gy = 500
        b.append(f'<rect x="{x + 20}" y="{gy}" width="{cw - 40}" height="8" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 20},{gy}) scale(2.7)">{desenha(i, col, "parado")}</g>' + label(cx, gy + 30, "parado", 16, "#2a4a58"))
        gy2 = 780
        b.append(f'<rect x="{x + 20}" y="{gy2}" width="{cw - 40}" height="8" rx="3" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({cx - 50},{gy2}) scale(2.3)">{desenha(i, col, "golpe")}</g>' + label(cx, gy2 + 30, "golpe característico", 16, "#2a4a58"))
        b.append(label(cx, 856, "silhueta", 15, "#2a4a58"))
        b.append(f'<g transform="translate({cx - 70},{940}) scale(0.85)">{silhueta(desenha(i, col, "parado"))}</g>')
        b.append(f'<g transform="translate({cx + 40},{940}) scale(0.85)">{silhueta(desenha(i, col, "golpe"))}</g>')
    # no caos: os 5 juntos, misturados, em tamanho de jogo
    b.append(f'<rect x="12" y="965" width="{W - 24}" height="270" rx="22" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 1005, "NO CAOS (tamanho de jogo, 4 cores misturadas) — dá para saber quem é quem?", 22, INK, "start"))
    b.append(f'<rect x="40" y="1200" width="{W - 80}" height="8" fill="#c9b99a"/>')
    cores = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]
    xs = [200, 420, 640, 860, 1080, 1300, 1520, 1740]
    for k, x in enumerate(xs):
        i = k % 5
        b.append(f'<g transform="translate({x},1200) scale(1.25)">{desenha(i, cores[(k * 3) % 4], "golpe" if k % 2 else "parado")}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


def main():
    os.makedirs(ab.OUT, exist_ok=True)
    svg, w, h = prancha()
    queue(svg, os.path.join(ROOT_SRC, "elenco_uch.svg"), os.path.join(ab.OUT, "elenco_uch.png"), w, h, 1)
    print("elenco:", render_all())


ROOT_SRC = os.path.join(ab.ROOT, "art/src/robos/svg")

if __name__ == "__main__":
    main()
