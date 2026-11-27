"""ANIMAÇÕES do BRITA (elenco aprovado 2026-11-27): baixinho elétrico com cabeça de betoneira e britadeira.
Jeito próprio: passinhos rápidos, tudo vibra, quica ao pousar, golpe pesado = pula em cima da britadeira e crava.
Usa o motor de anim_blindado (curva contínua + molas). Rodar: python3 art/src/robos/anim_brita.py [--resto]
→ art/out/robos_v2/brita_lote1.mp4 (+ _lento)
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import anim_blindado as ab  # noqa: E402
import elenco_uch as eu  # noqa: E402

P = ab.P
COL = "#5cc45c"


def desenha(pose, col=COL):
    """Converte a pose do motor para o Brita (corpo_generico) + achata/estica, verga e gira."""
    pz = dict(hip=pose["hip"], lean=pose["lean"], head=pose.get("head", 0), feet=pose["feet"], grip=pose["tool"][:2], ang=pose["tool"][2],
              bk=pose.get("bk"), face=pose.get("face", "foco"), rajada=False)
    body = eu.corpo_generico(eu.BRITA, col, pz)
    sqx, sqy = pose["sq"]
    body = f'<g transform="skewX({pose.get("skew", 0):.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -24)">{body}</g>'
    return body


BASE = P(hip=(0, -15), lean=6, head=0, feet=[(-12, 0), (12, 0)], tool=(16, -18, -8), face="foco")


def vibra(t0, t1, base, amp=1.6, campo="oy", passo=1 / 30):
    """Quadros alternados (tremidinha da britadeira) entre t0 e t1."""
    out = []
    t = t0
    s = 1
    while t < t1:
        p = dict(base)
        if campo == "oy":
            p["oy"] = base.get("oy", 0) + amp * s
        else:
            p["ox"] = base.get("ox", 0) + amp * s
        out.append((round(t, 4), P(**p)))
        t += passo
        s = -s
    return out


def A_correr():
    b = dict(lean=16, head=-6, tool=(18, -15, 20), face="foco")
    k = [(0.0, P(hip=(0, -13), feet=[(-9, -2), (9, 0)], sq=(1, 0.9), bk=None, **b)),
         (0.07, P(hip=(0, -18), feet=[(-2, -8), (3, -2)], sq=(1, 1.08), **b)),
         (0.14, P(hip=(0, -13), feet=[(9, 0), (-9, -2)], sq=(1, 0.9), **b)),
         (0.21, P(hip=(0, -18), feet=[(3, -2), (-2, -8)], sq=(1, 1.08), **b)),
         (0.28, P(hip=(0, -13), feet=[(-9, -2), (9, 0)], sq=(1, 0.9), **b))]

    def fx(t, p):
        off = (t / 0.28 * 140) % 70
        return ("".join(f'<path d="M{x - off:.0f},2 h14" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-140, 180, 70))
                + ab.fx_dust(-16, 0, (t % 0.14) / 0.14, 0.5)
                + "".join(f'<path d="M{50 + i * 3},{-10 + i * 5} l6,0" stroke="#ffffff" stroke-width="2" stroke-linecap="round"/>' for i in range(2)))
    return "BRITA · CORRER (passinhos)", 0.28, k, fx, None


def A_pulo():
    k = [(0.0, BASE), (0.1, P(**{**BASE, "hip": (0, -10), "sq": (1, 0.7), "lean": 18, "head": 10})),
         (0.16, P(**{**BASE, "hip": (0, -18), "sq": (1, 1.25), "oy": -14, "feet": [(-5, -2), (5, 0)], "face": "raiva"})),
         (0.38, P(**{**BASE, "oy": -52, "rot": -20, "feet": [(-10, -8), (9, -6)], "tool": (18, -20, -30)})),
         (0.6, P(**{**BASE, "oy": 0, "rot": 0, "sq": (1, 1.1)})),
         (0.66, P(**{**BASE, "hip": (0, -9), "sq": (1, 0.68), "lean": 20, "head": 12})),
         (0.76, P(**{**BASE, "oy": -14, "sq": (1, 1.12)})),            # quica de novo
         (0.86, P(**{**BASE, "oy": 0, "sq": (1, 0.84)})), (1.1, BASE)]

    def fx(t, p):
        o = ""
        for t0 in (0.1, 0.66, 0.86):
            if t0 < t < t0 + 0.22:
                o += ab.fx_dust(0, 0, (t - t0) / 0.22, 1.0 if t0 != 0.86 else 0.6)
        return o
    return "BRITA · PULAR (quica)", 1.1, k, fx, None


def A_leve():
    k = [(0.0, BASE)]
    t = 0.04
    for i in range(3):   # rajada: 3 estocadas rápidas e tremidas
        k.append((round(t, 3), P(**{**BASE, "lean": 4, "tool": (12, -16, 0), "face": "raiva"})))
        k.append((round(t + 0.06, 3), P(**{**BASE, "lean": 20, "hip": (2, -15), "tool": (26, -17, 0), "face": "raiva", "sq": (1.06, 0.95)})))
        t += 0.16
    k += [(0.62, P(**{**BASE, "lean": 18, "tool": (24, -17, 0)})), (0.95, BASE)]

    def fx(t, p):
        if 0.04 < t < 0.56:
            hx = p["tool"][0] + 48
            ph = ((t - 0.04) % 0.16) / 0.16
            o = "".join(f'<path d="M{hx + 4},{-18 + d} l7,{d * 0.6}" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>' for d in (-6, 0, 6))
            o += "".join(f'<path d="M{hx - 30 + i * 4},{-26 + i * 6} l9,0" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>' for i in range(3))
            if ph < 0.4:
                o += ab.fx_estrela(hx + 4, -18, ph / 0.4, 9)
            return o
        return ""
    return "BRITA · GOLPE LEVE (rajada)", 0.95, k, fx, None


def A_pesado():
    agacha = P(**{**BASE, "hip": (0, -10), "lean": -6, "head": 8, "sq": (1.08, 0.86), "tool": (8, -14, 90), "face": "raiva"})
    em_cima = dict(hip=(0, -16), lean=0, head=-4, feet=[(-7, -14), (7, -14)], tool=(0, -16, 90), face="raiva")
    k = [(0.0, BASE), (0.18, agacha),
         (0.32, P(oy=-54, sq=(1, 1.15), **em_cima)),                    # pula em cima da britadeira
         (0.5, P(oy=-58, **em_cima)),
         (0.58, P(oy=-30, sq=(1, 0.86), **em_cima))]                    # crava: a ponta bate no chão
    k += vibra(0.6, 1.2, dict(oy=-30, sq=(1, 0.95), **em_cima), amp=1.8)   # perfura tremendo
    k += [(1.28, P(oy=-44, ox=-6, feet=[(-10, -6), (8, -4)], tool=(10, -16, 60), face="foco", hip=(0, -16))),
          (1.45, P(**{**BASE, "sq": (1, 0.8), "hip": (0, -11)})), (1.8, BASE)]

    def fx(t, p):
        o = ""
        if 0.58 < t < 1.25:
            kk = min((t - 0.58) / 0.5, 1)
            o += ab.fx_onda(0, 0, (t - 0.58) % 0.25 / 0.25, 1.1)
            o += "".join(f'<path d="M{d},0 l{d * 0.5},{-4 - kk * 10:.0f}" stroke="#7a6a50" stroke-width="2.5" stroke-linecap="round"/>' for d in (-22, -12, 12, 22))
            o += ab.fx_dust(0, 0, (t * 5) % 1, 1.2)
        if 0.58 < t < 0.75:
            o += ab.fx_estrela(0, -4, (t - 0.58) / 0.17, 20) + ab.impacto(0, 0)
        return o
    return "BRITA · GOLPE PESADO (pula na britadeira e crava)", 1.8, k, fx, None


def main():
    ab.desenha = desenha
    ab.SC = 2.3
    ab.COL = COL
    ab.frame_svg.__defaults__ = (COL, None)
    ab.ANIMS = [A_correr, A_pulo, A_leve, A_pesado]
    ab.LOOPS = {A_correr}
    ab.main()
    for a, b in (("anim_blindado.mp4", "brita_lote1.mp4"), ("anim_blindado_lento.mp4", "brita_lote1_lento.mp4"), ("anim_blindado_folha.png", "brita_lote1_folha.png")):
        if os.path.exists(os.path.join(ab.OUT, a)):
            os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))


if __name__ == "__main__":
    main()
