"""ANIMAÇÕES do robô blindado (conceito aprovado em 2026-11-26) — todas as movimentações básicas e habilidades, para o
usuário aprovar ANTES de ir para o jogo. Poses-chave interpoladas (com suavização) + efeitos (rastro, impacto, poeira,
carga, fantasmas, linhas de velocidade). Tempos seguem o controle do jogo (golpe leve rápido; pesado carrega e solta).
Rodar: python3 art/src/robos/anim_blindado.py → art/out/robos_v2/anim_blindado.mp4 (+ _lento.mp4)
"""
import math
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import conceito3_blindado as cb  # noqa: E402
from elenco import label, INK, ik  # noqa: E402
from conceitos2 import smear, impacto, rot  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = cb.ROOT
OUT = os.path.join(ROOT, "art/out/robos_v2")
FPS = 30
CW, CH = 480, 360
SC = 1.45
GROUND = 330
COL = "#4f86d9"


# ---------------------------------------------------------------- poses base
def P(**k):
    base = dict(hip=(0, -38), lean=12, head=4, feet=[(-18, 0), (18, 0)], tool=(16, -50, -58), face="foco",
                ox=0, oy=0, rot=0, sq=(1, 1), bk=None, fr=None, sirene=0)
    base.update(k)
    return base


GUARDA = P()
HEROI = P(hip=(0, -42), lean=4, head=-4, feet=[(-16, 0), (15, 0)], tool=(9, -44, -142), bk=(-12, -22))


def ease(x):
    return x * x * (3 - 2 * x)


def lerp(a, b, t):
    return a + (b - a) * t


def lerp_p(a, b, t):
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t))


def _bk_point(p):
    if p.get("bk") is not None:
        return p["bk"]
    g, ang = p["tool"][:2], p["tool"][2]
    return (g[0] - math.cos(math.radians(ang)) * 16, g[1] - math.sin(math.radians(ang)) * 16)


def mix(a, b, t):
    """Interpola duas poses (t já suavizado)."""
    o = dict(b if t >= 0.5 else a)
    for k in ("lean", "head", "ox", "oy", "rot", "sirene"):
        o[k] = lerp(a[k], b[k], t)
    o["hip"] = lerp_p(a["hip"], b["hip"], t)
    o["feet"] = [lerp_p(a["feet"][i], b["feet"][i], t) for i in range(2)]
    o["tool"] = (lerp(a["tool"][0], b["tool"][0], t), lerp(a["tool"][1], b["tool"][1], t), lerp(a["tool"][2], b["tool"][2], t))
    o["sq"] = (lerp(a["sq"][0], b["sq"][0], t), lerp(a["sq"][1], b["sq"][1], t))
    o["bk"] = lerp_p(_bk_point(a), _bk_point(b), t)
    if a.get("fr") is not None or b.get("fr") is not None:
        fa = a.get("fr") or a["tool"][:2]
        fb = b.get("fr") or b["tool"][:2]
        o["fr"] = lerp_p(fa, fb, t) if (b.get("fr") is not None or t < 0.5) else None
    return o


def pose_at(keys, t):
    if t <= keys[0][0]:
        return dict(keys[0][1])
    for (t0, p0), (t1, p1) in zip(keys, keys[1:]):
        if t <= t1:
            return mix(p0, p1, ease((t - t0) / max(t1 - t0, 1e-6)))
    return dict(keys[-1][1])


# ---------------------------------------------------------------- desenho de uma pose (com mão da frente livre e corpo girando)
def desenha(pose, col=COL):
    hip, lean = pose["hip"], pose["lean"]
    st = cb.ST
    sx, sy = st["shl"]
    sh_f = rot((hip[0] + sx, hip[1] + sy), lean, hip)
    sh_b = rot((hip[0] + sx - st["sh_gap"], hip[1] + sy + 1), lean, hip)
    fr = pose.get("fr")
    if fr is not None:   # mão da frente livre (borda): a marreta fica na mão de trás
        bkp = pose["bk"]
        tool, g1, g2 = cb.marreta(bkp, pose["tool"][2])
    else:
        tool, g1, g2 = cb.marreta(pose["tool"][:2], pose["tool"][2])
    el, end = ik(sh_b, pose["bk"] if pose.get("bk") is not None else g2, st["uarm"], st["farm"], lambda q: q[1])
    back_arm = cb.braco(col, sh_b, el, end, True)
    legs = []
    for i in range(2):
        hp = (hip[0] + (-st["hip_w"] if i == 0 else st["hip_w"]), hip[1] + 2)
        ft = pose["feet"][i]
        kn, en = ik(hp, (ft[0], ft[1] - st["foot_h"]), st["thigh"], st["shin"], lambda q: q[0])
        legs.append(cb.perna(col, hp, kn, en, i == 0))
    el, end = ik(sh_f, fr if fr is not None else g1, st["uarm"], st["farm"], lambda q: q[1])
    front_arm = cb.braco(col, sh_f, el, end, False)
    corpo = cb.corpo(col, hip, lean, pose)
    behind = pose["tool"][2] < -110 and fr is None   # marreta nas costas (no ombro / erguida atrás)
    parts = ([tool] if behind else []) + [cb.ombreira(col, sh_b, True), back_arm, legs[0], corpo, legs[1]] + ([] if behind else [tool]) + [front_arm, cb.ombreira(col, sh_f, False)]
    body = "".join(parts)
    sqx, sqy = pose["sq"]
    if sqx != 1 or sqy != 1:
        body = f'<g transform="scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -44)">{body}</g>'
    return body


def head_pos(pose):
    g, a = pose["tool"][:2], pose["tool"][2]
    return (g[0] + math.cos(math.radians(a)) * 56, g[1] + math.sin(math.radians(a)) * 56)


# ---------------------------------------------------------------- efeitos
def fx_dust(x, y, k, s=1.0):
    out = ""
    for i, (dx, r) in enumerate(((-14, 6), (-4, 8), (8, 6), (18, 4.5))):
        out += f'<circle cx="{x + dx * (1 + k) * s:.1f}" cy="{y - 4 - k * 6:.1f}" r="{r * s * (1 - k * 0.5):.1f}" fill="#e8e0d0" opacity="{0.9 * (1 - k):.2f}"/>'
    return out


def fx_lines(x, y, n=4, ln=24, dx=1):
    return "".join(f'<path d="M{x + (i % 2) * 8},{y + i * 9} h{dx * ln}" stroke="#ffffff" stroke-width="3" stroke-opacity="0.85" stroke-linecap="round"/>' for i in range(n))


def fx_carga(p, k, t):
    hx, hy = head_pos(p)
    r = 14 + 10 * k
    out = f'<circle cx="{hx:.1f}" cy="{hy:.1f}" r="{r:.1f}" fill="#ffd27a" opacity="{0.25 + 0.35 * k:.2f}"/>'
    for i in range(int(3 + 6 * k)):
        a = t * 9 + i * 1.3
        out += f'<path d="M{hx + math.cos(a) * r:.1f},{hy + math.sin(a) * r:.1f} l{math.cos(a) * 6:.1f},{math.sin(a) * 6:.1f}" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>'
    return out


def fx_onda(x, y, k, big=1.0):
    return (f'<ellipse cx="{x}" cy="{y}" rx="{(20 + 50 * k) * big:.1f}" ry="{(4 + 9 * k) * big:.1f}" fill="none" stroke="#ffffff" stroke-width="{3 * (1 - k) + 1:.1f}" opacity="{1 - k:.2f}"/>'
            + "".join(f'<rect x="{x + d * (8 + 40 * k):.1f}" y="{y - 6 - 30 * k + 40 * k * k:.1f}" width="6" height="5" fill="#b9ab8f" transform="rotate({k * 300 * d} {x + d * (8 + 40 * k):.1f} {y - 6 - 30 * k:.1f})"/>' for d in (-1.4, -0.7, 0.6, 1.3)))


def fx_estrela(x, y, k, r=14):
    pts = []
    rr0 = r * (0.6 + 0.6 * k)
    for i in range(16):
        rr = rr0 if i % 2 == 0 else rr0 * 0.45
        a = math.radians(i * 22.5)
        pts.append(f"{x + math.cos(a) * rr:.1f},{y + math.sin(a) * rr:.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="#ffe27a" opacity="{1 - k * 0.7:.2f}"/>'


# ---------------------------------------------------------------- as animações: (nome, duração, poses-chave, efeitos(t, pose) -> svg, cenário)
def A_parado():
    k = [(0, HEROI), (0.8, P(**{**HEROI, "hip": (0, -40.6), "head": -1, "tool": (9, -43, -139)})), (1.6, HEROI)]
    return "PARADO (respira)", 1.6, k, None, None


def A_correr():
    base = dict(lean=16, head=-6, tool=(4, -46, -150), face="foco")
    k = [(0.0, P(hip=(0, -40), feet=[(-22, -3), (20, 0)], bk=(-20, -30), **base)),
         (0.125, P(hip=(0, -36), feet=[(-6, -12), (6, 0)], bk=(-12, -27), **base)),
         (0.25, P(hip=(0, -40), feet=[(20, 0), (-22, -3)], bk=(-4, -24), **base)),
         (0.375, P(hip=(0, -36), feet=[(6, 0), (-6, -12)], bk=(-12, -27), **base)),
         (0.5, P(hip=(0, -40), feet=[(-22, -3), (20, 0)], bk=(-20, -30), **base))]

    def fx(t, p):
        off = (t / 0.5 * 120) % 60
        return "".join(f'<path d="M{x - off:.0f},2 h18" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-120, 160, 60)) + (fx_dust(-26, 0, (t % 0.25) / 0.25, 0.7))
    return "CORRER", 0.5, k, fx, None


def A_pulo():
    air = dict(feet=[(-12, -16), (10, -10)], tool=(6, -50, -150), bk=(-16, -40))
    k = [(0.0, GUARDA), (0.10, P(hip=(0, -30), sq=(1.12, 0.88), lean=16)),
         (0.17, P(hip=(0, -44), sq=(0.9, 1.12), oy=-14, lean=6, face="raiva", **air)),
         (0.45, P(hip=(0, -42), oy=-66, lean=2, head=-6, **air)),
         (0.75, P(hip=(0, -44), oy=-20, lean=10, feet=[(-14, -4), (14, -2)], tool=(8, -54, -120), bk=(-18, -46))),
         (0.82, P(hip=(0, -30), sq=(1.14, 0.86), lean=18)), (1.0, GUARDA), (1.3, GUARDA)]

    def fx(t, p):
        o = ""
        if 0.1 < t < 0.3:
            o += fx_dust(0, 0, (t - 0.1) / 0.2)
        if 0.82 < t < 1.05:
            o += fx_dust(0, 0, (t - 0.82) / 0.23, 1.2)
        return o
    return "PULO (prepara · sobe · cai · pousa)", 1.3, k, fx, None


def A_pulo_duplo():
    tuck = dict(feet=[(-6, -24), (6, -22)], tool=(10, -48, -100), bk=(-4, -40), hip=(0, -48))
    k = [(0.0, P(oy=-50, feet=[(-12, -10), (10, -6)], tool=(6, -50, -150), bk=(-16, -40))),
         (0.08, P(oy=-60, feet=[(-4, -2), (6, 2)], tool=(6, -50, -150), bk=(-16, -40), sq=(0.92, 1.1))),
         (0.40, P(oy=-70, rot=360, **tuck, face="raiva")),
         (0.55, P(oy=-70, rot=360, feet=[(-14, -12), (12, -8)], tool=(8, -54, -120), bk=(-18, -46))),
         (1.0, P(oy=0, rot=360)), (1.2, P(rot=360))]

    def fx(t, p):
        if 0.05 < t < 0.2:
            return f'<g transform="translate(0,{-50 - 10 * (t - 0.05) / 0.15:.0f})"><circle cx="0" cy="6" r="{8 + 30 * (t - 0.05):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.05) * 4:.2f}"/></g>'
        return ""
    return "PULO DUPLO (cambalhota)", 1.2, k, fx, None


def A_parede():
    wall = dict(lean=6, head=8, feet=[(4, -8), (-8, -2)], tool=(6, -52, -150), bk=(-14, -60), face="foco")
    k = [(0.0, P(ox=-34, oy=-90, **wall)), (0.9, P(ox=-34, oy=-34, **wall)),
         (1.0, P(ox=-30, oy=-38, lean=-6, feet=[(-12, -4), (-18, 0)], tool=(6, -52, -150), bk=(-14, -50), sq=(1.1, 0.9))),
         (1.4, P(ox=60, oy=-100, lean=20, feet=[(-14, -16), (8, -10)], tool=(4, -50, -150), bk=(-16, -40), face="raiva"))]

    def fx(t, p):
        o = '<rect x="-98" y="-230" width="40" height="240" fill="#d9a35f"/><rect x="-64" y="-230" width="6" height="240" fill="#b57a3e"/>'
        if t < 0.9:
            o += fx_dust(-56, p["oy"] + 4, (t * 4) % 1, 0.5)
        return o
    return "PAREDE (desliza · pulo de parede)", 1.4, k, fx, None


def A_borda():
    hang = dict(hip=(0, -40), lean=0, head=-12, tool=(0, 0, 125), fr=(26, -108), face="susto")
    k = [(0.0, P(ox=0, oy=-12, feet=[(-4, -6), (6, -2)], bk=(-6, -26), **hang)),
         (0.5, P(ox=0, oy=-12, feet=[(-10, -2), (10, -8)], bk=(-6, -24), **hang)),
         (0.9, P(ox=0, oy=-12, feet=[(-4, -6), (6, -2)], bk=(-6, -26), **hang)),
         (1.25, P(ox=14, oy=-92, hip=(0, -34), lean=24, head=0, feet=[(-6, -14), (16, -2)], tool=(10, -40, -150), bk=(-12, -30), face="raiva")),
         (1.6, P(ox=50, oy=-120))]

    def fx(t, p):
        return '<rect x="30" y="-120" width="200" height="125" fill="#cfc6b4"/><rect x="30" y="-120" width="200" height="9" fill="#e8e0d0"/>'
    return "BORDA (pendurado · sobe)", 1.6, k, fx, None


def A_combo():
    k = [(0.00, GUARDA),
         (0.05, P(lean=6, tool=(8, -56, -80), face="raiva")),
         (0.10, P(lean=22, hip=(2, -36), tool=(30, -40, -5), face="raiva", feet=[(-18, 0), (22, 0)])),
         (0.30, P(lean=16, tool=(26, -38, 10))),
         (0.36, P(lean=4, tool=(20, -30, 40), face="raiva")),
         (0.42, P(lean=20, head=-6, tool=(26, -56, -60), face="raiva", feet=[(-18, 0), (22, 0)])),
         (0.60, P(lean=-10, hip=(0, -36), head=8, tool=(-6, -70, -140), face="raiva", sq=(1.04, 0.96))),
         (0.72, P(lean=30, hip=(4, -30), head=-6, tool=(32, -34, 64), feet=[(-24, 0), (25, 0)], face="raiva")),
         (0.95, P(lean=28, hip=(4, -30), tool=(32, -30, 70), feet=[(-24, 0), (25, 0)])),
         (1.3, GUARDA)]

    def fx(t, p):
        o = ""
        g = p["tool"][:2]
        if 0.06 < t < 0.16:
            o += smear(g, -80, -5, 34, 70) + fx_lines(70, -62, 3, 18, -1)
        if 0.37 < t < 0.48:
            o += smear(g, 40, -60, 34, 70)
        if 0.62 < t < 0.8:
            o += smear(g, -140, 64, 34, 70)
        if 0.72 < t < 1.0:
            kk = (t - 0.72) / 0.28
            o += fx_onda(72, 0, kk) + fx_estrela(72, -6, kk, 16)
        return o
    return "GOLPE LEVE: COMBO 1 · 2 · 3", 1.3, k, fx, None


def A_cima():
    k = [(0.0, GUARDA), (0.07, P(hip=(0, -32), lean=10, tool=(22, -26, 50), face="raiva", sq=(1.06, 0.94))),
         (0.15, P(hip=(0, -44), lean=-6, head=-14, oy=-6, tool=(8, -70, -100), face="raiva", feet=[(-16, 0), (16, -2)])),
         (0.45, P(hip=(0, -42), lean=-4, head=-10, tool=(6, -66, -110))), (0.8, GUARDA)]

    def fx(t, p):
        return smear(p["tool"][:2], 50, -100, 34, 70) + fx_estrela(14, -120, (t - 0.15) / 0.3, 12) if 0.08 < t < 0.45 else ""
    return "GOLPE LEVE PARA CIMA (antiaéreo)", 0.8, k, fx, None


def A_baixo():
    air = dict(oy=-70, feet=[(-12, -14), (10, -10)])
    k = [(0.0, P(tool=(0, -78, -120), bk=None, face="raiva", lean=-4, **air)),
         (0.08, P(tool=(0, -80, -130), lean=-8, face="raiva", **air)),
         (0.16, P(tool=(18, -22, 92), lean=24, head=-10, face="raiva", **air)),
         (0.55, P(oy=0, tool=(18, -22, 92), lean=24, feet=[(-16, 0), (16, 0)], sq=(1.1, 0.9))), (0.9, GUARDA)]

    def fx(t, p):
        o = ""
        if 0.1 < t < 0.3:
            o += f'<g transform="translate(0,-70)">{smear((18, -22), -130, 92, 34, 70)}</g>'
        if 0.55 < t < 0.85:
            o += fx_onda(26, 0, (t - 0.55) / 0.3)
        return o
    return "GOLPE LEVE PARA BAIXO (no ar)", 0.9, k, fx, None


def A_pesado():
    car = P(hip=(0, -32), lean=-22, head=10, feet=[(-20, 0), (14, 0)], tool=(-14, -70, -135), face="raiva", sq=(1.06, 0.94))
    sol = P(hip=(4, -30), lean=34, head=-10, feet=[(-24, 0), (26, 0)], tool=(34, -26, 76), face="raiva")
    k = [(0.0, GUARDA), (0.18, car), (1.0, P(**{**car, "lean": -24, "hip": (0, -31)})), (1.10, sol), (1.5, P(**{**sol, "tool": (32, -16, 92)})), (2.2, GUARDA)]

    def fx(t, p):
        o = ""
        if 0.18 < t < 1.04:
            kk = min((t - 0.18) / 0.8, 1)
            o += fx_carga(p, kk, t)
        if 1.0 < t < 1.18:
            o += smear(p["tool"][:2], -135, 76, 34, 72)
        if 1.08 < t < 1.6:
            kk = (t - 1.08) / 0.52
            o += (fx_onda(84, 0, kk, 1.6) + fx_estrela(84, -8, kk, 24) + impacto(84, 0)) if kk < 0.35 else fx_onda(84, 0, kk, 1.6)
        return o
    return "GOLPE PESADO (segura = carrega · solta)", 2.2, k, fx, "treme"


def A_esq_chao():
    low = P(hip=(0, -30), lean=-16, head=8, feet=[(-24, 0), (12, 0)], tool=(10, -44, -150), bk=(-18, -30), face="susto")
    k = [(0.0, GUARDA), (0.04, P(**{**low, "ox": 0})), (0.2, P(**{**low, "ox": -60})), (0.45, P(**{**GUARDA, "ox": -60})), (0.9, P(**{**GUARDA, "ox": 0}))]
    return "ESQUIVA NO CHÃO", 0.9, k, None, "fantasma"


def A_esq_ar():
    tuck = dict(feet=[(-6, -24), (6, -22)], tool=(10, -48, -100), bk=(-4, -40), hip=(0, -48), face="susto")
    k = [(0.0, P(oy=-60, feet=[(-12, -10), (10, -6)], tool=(6, -50, -150), bk=(-16, -40))),
         (0.3, P(oy=-56, ox=-40, rot=-360, **tuck)), (0.55, P(oy=-60, ox=-40, rot=-360, feet=[(-12, -10), (10, -6)], tool=(6, -50, -150), bk=(-16, -40))),
         (1.0, P(oy=-60, ox=0, rot=-360, feet=[(-12, -10), (10, -6)], tool=(6, -50, -150), bk=(-16, -40)))]
    return "ESQUIVA NO AR (giro)", 1.0, k, None, "fantasma"


def A_leva():
    hit = P(lean=-24, head=18, sq=(0.88, 1.08), ox=-14, hip=(-2, -36), feet=[(-22, -2), (12, 0)], tool=(4, -40, -160), bk=(-16, -18), face="dor")
    k = [(0.0, GUARDA), (0.06, hit), (0.35, P(**{**hit, "ox": -22, "sq": (1, 1)})), (0.9, P(**{**GUARDA, "ox": 0}))]

    def fx(t, p):
        return fx_estrela(18, -60, (t - 0.04) / 0.25, 14) if 0.04 < t < 0.29 else ""
    return "LEVA GOLPE", 0.9, k, fx, None


def A_arremessado():
    fly = dict(feet=[(-20, -14), (-4, -26)], tool=(-14, -66, -170), bk=(-26, -50), face="susto", hip=(0, -42))
    k = [(0.0, GUARDA), (0.05, P(ox=0, oy=-10, rot=0, **fly)), (0.5, P(ox=-90, oy=-70, rot=-300, **fly)),
         (0.95, P(ox=-140, oy=-30, rot=-600, **fly)), (1.05, P(ox=-148, oy=-24, rot=-720, feet=[(-14, -6), (12, -4)], tool=(6, -50, -150), bk=(-16, -40))),
         (1.2, P(ox=-152, oy=0, rot=-720, sq=(1.12, 0.88), hip=(0, -30))), (1.6, P(ox=-152, rot=-720))]

    def fx(t, p):
        if t < 0.9:
            return f'<g transform="translate({p["ox"] * 1 + 40:.0f},{p["oy"] - 50:.0f})">{fx_lines(0, 0, 4, 34, 1)}</g>'
        if 1.0 < t < 1.15:
            return f'<circle cx="{p["ox"]:.0f}" cy="{p["oy"] - 44:.0f}" r="{(t - 1.0) * 300:.0f}" fill="none" stroke="#ffffff" stroke-width="4" opacity="{1 - (t - 1) / 0.15:.2f}"/>'
        return ""
    return "ARREMESSADO (gira · recupera)", 1.6, k, fx, "desloca"


def A_engenhoca():
    k = [(0.0, HEROI), (0.12, P(**{**HEROI, "bk": (24, -62), "lean": 10, "face": "raiva"})), (0.6, P(**{**HEROI, "bk": (26, -60), "lean": 12, "face": "raiva"})), (1.0, HEROI)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="26" y="-70" width="12" height="16" rx="3" fill="#3a3f4a"/><circle cx="32" cy="-74" r="3" fill="#d42035"/>'
                    + fx_estrela(32, -80, kk, 16) + f'<circle cx="32" cy="-62" r="{10 + kk * 60:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return "USAR ENGENHOCA", 1.0, k, fx, None


def A_vitoria():
    up = P(hip=(0, -44), lean=-4, head=-10, feet=[(-16, 0), (16, 0)], tool=(4, -92, -96), bk=(0, -86), face="vitoria")
    k = [(0.0, up), (0.4, P(**{**up, "oy": -16, "sirene": 1, "feet": [(-12, -6), (12, -6)]})), (0.8, up), (1.2, P(**{**up, "oy": -16, "sirene": 1, "feet": [(-12, -6), (12, -6)]})), (1.6, up)]
    return "VITÓRIA", 1.6, k, None, None


ANIMS = [A_parado, A_correr, A_pulo, A_pulo_duplo, A_parede, A_borda, A_combo, A_cima, A_baixo, A_pesado, A_esq_chao, A_esq_ar, A_leva, A_arremessado, A_engenhoca, A_vitoria]


def frame_svg(nome, dur, keys, fx, modo, t, col=COL):
    p = pose_at(keys, t)
    ox, oy = p["ox"], p["oy"]
    jit = ""
    if modo == "treme" and 0.18 < t < 1.0:
        j = math.sin(t * 90) * (0.6 + 1.6 * (t - 0.18))
        jit = f" translate({j:.2f},0)"
    flip = -1 if modo == "flip" else 1
    cx = CW / 2 + (95 if modo == "desloca" else 0)
    b = [f'<rect width="{CW}" height="{CH}" fill="#bfe9ef"/>', f'<rect x="0" y="{GROUND}" width="{CW}" height="{CH - GROUND}" fill="#cbbd9f"/>',
         f'<rect x="0" y="{GROUND}" width="{CW}" height="5" fill="#e8dcc2"/>']
    world = ""
    if fx:
        world += fx(t, p)
    sombra_k = max(0.3, 1 + oy / 120)
    world_robo = ""
    if modo == "fantasma":   # rastros da esquiva
        for i, dt in enumerate((0.09, 0.06, 0.03)):
            if t - dt > 0:
                pg = pose_at(keys, t - dt)
                world_robo += f'<g opacity="{0.15 + i * 0.08:.2f}" transform="translate({pg["ox"]:.1f},{pg["oy"]:.1f})">{desenha(pg, "#bfe7ff")}</g>'
    world_robo += f'<g transform="translate({ox:.1f},{oy:.1f}){jit}">{desenha(p, col)}</g>'
    sh = f'<ellipse cx="{ox:.1f}" cy="2" rx="{26 * sombra_k:.1f}" ry="{5 * sombra_k:.1f}" fill="#2a1a2e" opacity="0.18"/>'
    b.append(f'<g transform="translate({cx:.1f},{GROUND}) scale({SC * flip},{SC})">{sh}{world}{world_robo}</g>')
    b.append(f'<rect x="8" y="8" width="{CW - 16}" height="34" rx="10" fill="#ffffff" opacity="0.8"/>' + label(18, 32, nome, 18, INK, "start"))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{CW}" height="{CH}" viewBox="0 0 {CW} {CH}">{"".join(b)}</svg>'


def main():
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="anim_blind_")
    meta = []
    for ai, fn in enumerate(ANIMS):
        nome, dur, keys, fx, modo = fn()
        n = max(1, int(round(dur * FPS)))
        for f in range(n):
            svg = frame_svg(nome, dur, keys, fx, modo, f / FPS)
            queue(svg, f"{tmp}/svg/a{ai:02d}_{f:03d}.svg", f"{tmp}/png/a{ai:02d}_{f:03d}.png", CW, CH, 1)
        meta.append(n)
    print("quadros:", render_all())
    from PIL import Image
    cols, rows = 4, (len(ANIMS) + 3) // 4
    for nome_saida, lento in (("anim_blindado", 1), ("anim_blindado_lento", 2)):
        fr = os.path.join(tmp, "grid_" + nome_saida)
        os.makedirs(fr, exist_ok=True)
        total = 6 * FPS * lento
        for f in range(total):
            W = Image.new("RGB", (cols * CW, rows * CH), "#9fe2ec")
            for ai, n in enumerate(meta):
                im = Image.open(f"{tmp}/png/a{ai:02d}_{(f // lento) % n:03d}.png").convert("RGB")
                W.paste(im, ((ai % cols) * CW, (ai // cols) * CH))
            W.save(f"{fr}/g_{f:04d}.png")
        out = os.path.join(OUT, nome_saida + ".mp4")
        subprocess.run(["ffmpeg", "-v", "quiet", "-y", "-framerate", str(FPS), "-i", f"{fr}/g_%04d.png", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", out], check=True)
        print(out)
    # folha de conferência: 1 quadro "chave" de cada
    W = Image.new("RGB", (cols * CW, rows * CH), "#9fe2ec")
    for ai, n in enumerate(meta):
        im = Image.open(f"{tmp}/png/a{ai:02d}_{min(n - 1, int(n * 0.45)):03d}.png").convert("RGB")
        W.paste(im, ((ai % cols) * CW, (ai // cols) * CH))
    W.save(os.path.join(OUT, "anim_blindado_folha.png"))
    shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
