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
    if pose.get("oculto"):
        return ""
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


def A_duplo():
    air = dict(feet=[(-10, -8), (9, -6)], tool=(18, -20, -30))
    tuck = dict(feet=[(-4, -12), (4, -10)], tool=(10, -20, -70), hip=(0, -18))
    k = [(0.0, P(**{**BASE, "oy": -24, **air})), (0.08, P(**{**BASE, "oy": -30, "sq": (1, 1.12), "feet": [(-3, -1), (4, 1)], "tool": (18, -20, -30)})),
         (0.38, P(**{**BASE, "oy": -50, "rot": 360, "face": "raiva", **tuck})), (0.5, P(**{**BASE, "oy": -50, "rot": 360, **air})),
         (0.85, P(**{**BASE, "oy": 0, "rot": 360, "sq": (1, 1.1)})), (0.92, P(**{**BASE, "rot": 360, "hip": (0, -9), "sq": (1, 0.68)})),
         (1.02, P(**{**BASE, "rot": 360, "oy": -12, "sq": (1, 1.1)})), (1.12, P(**{**BASE, "rot": 360, "sq": (1, 0.86)})), (1.3, P(**{**BASE, "rot": 360}))]

    def fx(t, p):
        if 0.05 < t < 0.2:
            return f'<circle cx="0" cy="-24" r="{6 + 30 * (t - 0.05):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.05) * 4:.2f}"/>'
        return ab.fx_dust(0, 0, (t - 0.92) / 0.2, 1.0) if 0.92 < t < 1.12 else ""
    return "BRITA · PULO DUPLO (cambalhota + quica)", 1.3, k, fx, None


def A_parede():
    wall = dict(lean=-4, head=8, feet=[(-12, -4), (0, -1)], tool=(14, -20, -40), face="foco")
    k = [(0.0, P(**{**BASE, "ox": -26, "oy": -46, **wall}))]
    k += vibra(0.05, 0.85, dict(BASE, ox=-26, **wall, **{"oy": -30}), amp=1.4, campo="ox")
    k += [(0.9, P(**{**BASE, "ox": -26, "oy": -14, **wall})),
          (1.0, P(**{**BASE, "ox": -24, "oy": -16, "hip": (0, -10), "sq": (1, 0.72), "lean": -10, "feet": [(-10, -1), (-6, 0)], "tool": (14, -20, -40)})),
          (1.4, P(**{**BASE, "ox": 50, "oy": -54, "lean": 22, "rot": 20, "feet": [(-10, -8), (9, -6)], "tool": (18, -20, -30), "face": "raiva", "sq": (1, 1.12)}))]

    def fx(t, p):
        o = '<rect x="-78" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-50" y="-200" width="6" height="210" fill="#b57a3e"/>'
        if t < 0.9:   # a britadeira raspando a parede solta faísca
            o += "".join(f'<path d="M-44,{p["oy"] - 12 + d} l{4 + abs(d) * 0.4:.0f},{d * 0.6:.0f}" stroke="#ffd36b" stroke-width="2" stroke-linecap="round"/>' for d in (-5, 0, 5))
        return o
    return "BRITA · PAREDE (raspa com faísca · salta)", 1.4, k, fx, None


def A_borda():
    hang = dict(hip=(0, -16), lean=0, head=-8, feet=[(-3, -3), (4, -1)], tool=(-2, -38, -95), bk=(-8, -36), face="susto")
    k = [(0.0, P(**{**BASE, "oy": -14, **hang}))]
    k += vibra(0.05, 0.85, dict(BASE, oy=-14, **{**hang, "feet": [(-6, -2), (6, -4)]}), amp=1.2, campo="ox")
    k += [(0.9, P(**{**BASE, "oy": -14, **hang})),
          (1.15, P(**{**BASE, "ox": 8, "oy": -54, "lean": 22, "feet": [(-4, -8), (10, -2)], "tool": (18, -20, -30), "face": "raiva", "sq": (1, 0.9)})),
          (1.3, P(**{**BASE, "ox": 20, "oy": -40, "sq": (1, 0.7), "hip": (0, -9)})), (1.6, P(**{**BASE, "ox": 26, "oy": -40}))]

    def fx(t, p):
        return '<rect x="8" y="-40" width="210" height="44" fill="#cfc6b4"/><rect x="8" y="-40" width="210" height="8" fill="#e8e0d0"/>'
    return "BRITA · BORDA (pendura pela britadeira · sobe)", 1.6, k, fx, None


def A_esquiva():
    low = P(**{**BASE, "hip": (0, -10), "lean": -16, "head": 10, "sq": (1.08, 0.82), "tool": (14, -18, -40), "face": "susto"})
    k = [(0.0, BASE), (0.04, low), (0.18, P(**{**low, "ox": -50})), (0.4, P(**{**BASE, "ox": -50})), (0.75, P(**{**BASE, "ox": 0}))]
    return "BRITA · ESQUIVA", 0.75, k, None, "fantasma"


def A_cima():
    k = [(0.0, BASE), (0.07, P(**{**BASE, "hip": (0, -10), "sq": (1, 0.8), "tool": (14, -16, -10)})),
         (0.15, P(**{**BASE, "oy": -8, "sq": (1, 1.15), "lean": -6, "head": -12, "tool": (22, -30, -78), "face": "raiva"}))]
    k += vibra(0.17, 0.5, dict(BASE, oy=-8, lean=-6, head=-12, tool=(22, -30, -78), face="raiva"), amp=1.3, campo="ox")
    k += [(0.8, BASE)]

    def fx(t, p):
        if 0.15 < t < 0.5:
            return "".join(f'<path d="M{30 + d},-78 l{d * 0.5},-8" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>' for d in (-6, 0, 6)) + ab.fx_estrela(30, -80, ((t - 0.15) % 0.12) / 0.12, 8)
        return ""
    return "BRITA · GOLPE LEVE PARA CIMA (fura o teto)", 0.8, k, fx, None


def A_baixo():
    air = dict(oy=-50, feet=[(-8, -10), (8, -10)], hip=(0, -16))
    k = [(0.0, P(**{**BASE, **air, "tool": (14, -20, -30)})), (0.1, P(**{**BASE, **air, "tool": (0, -16, 90), "face": "raiva", "sq": (1, 1.1)})),
         (0.4, P(**{**BASE, "oy": 0, "tool": (0, -16, 90), "feet": [(-8, -12), (8, -12)], "hip": (0, -16), "face": "raiva", "sq": (1, 0.8)}))]
    k += vibra(0.42, 0.7, dict(BASE, oy=0, tool=(0, -16, 90), feet=[(-8, -12), (8, -12)], hip=(0, -16), face="raiva"), amp=1.4)
    k += [(0.95, BASE)]

    def fx(t, p):
        return ab.fx_onda(0, 0, ((t - 0.4) % 0.2) / 0.2, 0.9) + ab.fx_dust(0, 0, (t * 4) % 1, 0.8) if 0.4 < t < 0.72 else ""
    return "BRITA · GOLPE LEVE PARA BAIXO (cai furando)", 0.95, k, fx, None


def A_leva():
    hit = P(**{**BASE, "lean": -24, "head": 18, "sq": (1, 1.12), "ox": -12, "feet": [(-14, -2), (8, 0)], "tool": (14, -20, -60), "face": "dor"})
    k = [(0.0, BASE), (0.06, hit), (0.3, P(**{**hit, "ox": -20, "sq": (1, 0.85)})), (0.42, P(**{**hit, "ox": -22, "sq": (1, 1.05)})), (0.85, P(**{**BASE, "ox": 0}))]

    def fx(t, p):
        return ab.fx_estrela(10, -40, (t - 0.04) / 0.25, 11) if 0.04 < t < 0.29 else ""
    return "BRITA · LEVA GOLPE", 0.85, k, fx, None


def A_arremessado():
    fly = dict(feet=[(-10, -8), (-2, -12)], tool=(10, -24, -120), face="susto")
    k = [(0.0, BASE), (0.05, P(**{**BASE, "oy": -6, **fly})), (0.45, P(**{**BASE, "ox": -70, "oy": -56, "rot": -360, **fly})),
         (0.8, P(**{**BASE, "ox": -110, "oy": 0, "rot": -680, **fly})), (0.86, P(**{**BASE, "ox": -114, "oy": 0, "rot": -720, "sq": (1, 0.66), "hip": (0, -9)})),
         (1.0, P(**{**BASE, "ox": -124, "oy": -26, "rot": -720, "sq": (1, 1.1)})), (1.14, P(**{**BASE, "ox": -132, "oy": 0, "rot": -720, "sq": (1, 0.8)})),
         (1.5, P(**{**BASE, "ox": -136, "rot": -720}))]

    def fx(t, p):
        if t < 0.78:
            return f'<g transform="translate({p["ox"] + 26:.0f},{p["oy"] - 30:.0f})">{ab.fx_lines(0, 0, 4, 24, 1)}</g>'
        return ab.fx_dust(p["ox"], 0, (t - 0.86) / 0.2, 1.0) if 0.86 < t < 1.06 else ""
    return "BRITA · ARREMESSADO (rola · quica)", 1.5, k, fx, "desloca"


def A_engenhoca():
    k = [(0.0, BASE), (0.12, P(**{**BASE, "bk": (14, -32), "lean": 12, "face": "raiva", "sq": (1, 1.06)})),
         (0.6, P(**{**BASE, "bk": (15, -31), "lean": 12, "face": "raiva"})), (1.0, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="12" y="-42" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="17" cy="-45" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(17, -50, kk, 12) + f'<circle cx="17" cy="-36" r="{8 + kk * 46:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return "BRITA · USAR ENGENHOCA", 1.0, k, fx, None


def A_vitoria():
    up = P(**{**BASE, "tool": (22, -30, -75), "face": "vitoria", "lean": -4})
    k = [(0.0, up)]
    for i in range(4):   # pulinhos elétricos
        k.append((0.1 + i * 0.35, P(**{**up, "oy": -18, "sq": (1, 1.12), "feet": [(-8, -4), (8, -4)]})))
        k.append((0.28 + i * 0.35, P(**{**up, "oy": 0, "sq": (1, 0.84)})))
    k.append((1.5, up))

    def fx(t, p):
        return "".join(f'<path d="M{32 + d},-80 l{d * 0.5},-8" stroke="#ffe27a" stroke-width="2" stroke-linecap="round"/>' for d in (-6, 0, 6)) if (t * 6) % 1 < 0.5 else ""
    return "BRITA · VITÓRIA (pulinhos elétricos)", 1.5, k, fx, None


def A_eliminado():
    k = [(0.0, P(**{**BASE, "face": "susto"}))]
    k += vibra(0.02, 0.16, dict(BASE, face="eliminado"), amp=2.2, campo="ox")
    k += [(0.2, P(**{**BASE, "face": "eliminado", "oculto": True})), (1.4, P(**{**BASE, "oculto": True}))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:
            r = 20 + 60 * u
            o += f'<circle cx="0" cy="-26" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-26" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, eu.brita_head(COL, {"face": "eliminado"})), (50, -120, -500, eu.brita_torso(COL, {})),
                 (70, -80, -800, eu.britadeira((0, 0), 0, {})[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -26 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.9)">{svg}</g>'
        return o
    return "BRITA · ELIMINADO (desmonta)", 1.4, k, fx, None


def main():
    if "--resto" in sys.argv:
        ab.desenha = desenha
        ab.SC = 2.3
        ab.COL = COL
        ab.frame_svg.__defaults__ = (COL, None)
        ab.ANIMS = [A_duplo, A_parede, A_borda, A_esquiva, A_cima, A_baixo, A_leva, A_arremessado, A_engenhoca, A_vitoria, A_eliminado]
        ab.LOOPS = set()
        ab.main()
        for a, b in (("anim_blindado.mp4", "brita_resto.mp4"), ("anim_blindado_lento.mp4", "brita_resto_lento.mp4"), ("anim_blindado_folha.png", "brita_resto_folha.png")):
            if os.path.exists(os.path.join(ab.OUT, a)):
                os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))
        return
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
