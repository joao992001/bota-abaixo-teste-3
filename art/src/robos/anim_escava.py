"""ANIMAÇÕES da ESCAVADEIRA (refeita 2026-11-27, opção E2 "TRATOR": lâmina no rosto, esteira na cintura, braço-caçamba).
óculos. Jeito próprio: passos pesados que tremem o chão, tomba para o lado do braço, pousos com estrondo; golpe pesado =
ergue a caçamba e esmaga. Rodar: python3 art/src/robos/anim_escava.py [--resto]
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import anim_blindado as ab  # noqa: E402
import elenco_uch as eu  # noqa: E402

P = ab.P
COL = "#f08a3d"


def desenha(pose, col=COL):
    if pose.get("oculto"):
        return ""
    pz = dict(hip=pose["hip"], lean=pose["lean"], head=pose.get("head", 0), feet=pose["feet"], grip=pose["tool"][:2], ang=pose["tool"][2],
              bk=pose.get("bk"), face=pose.get("face", "foco"))
    body = eu.corpo_generico(eu.ESCAVA, col, pz)
    sqx, sqy = pose["sq"]
    body = f'<g transform="skewX({pose.get("skew", 0):.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -24)">{body}</g>'
    return body


BASE = P(hip=(0, -18), lean=4, head=0, feet=[(-13, 0), (13, 0)], tool=(22, -14, 10), bk=(-20, -10), face="foco")


def pedras(x, y, k, n=5, s=1.0):
    o = ""
    for i in range(n):
        d = (i - (n - 1) / 2) * 0.6
        px = x + d * 40 * k * s
        py = y - 34 * k * s + 60 * k * k * s
        o += f'<rect x="{px - 3:.1f}" y="{py - 3:.1f}" width="{6 + i % 2 * 2}" height="{5 + i % 3}" fill="#9a8a6a" transform="rotate({k * 300 * d:.0f} {px:.1f} {py:.1f})"/>'
    return o


def A_correr():
    b = dict(head=-2, tool=(24, -18, 30), face="foco")
    k = [(0.0, P(hip=(0, -17), lean=12, feet=[(-16, 0), (14, 0)], bk=(-24, -12), sq=(1.08, 0.9), **b)),
         (0.18, P(hip=(0, -23), lean=4, feet=[(-6, -8), (6, -1)], bk=(-20, -16), sq=(0.98, 1.04), **b)),
         (0.36, P(hip=(0, -17), lean=12, feet=[(14, 0), (-16, 0)], bk=(-16, -12), sq=(1.08, 0.9), **b)),
         (0.54, P(hip=(0, -23), lean=4, feet=[(6, -1), (-6, -8)], bk=(-20, -16), sq=(0.98, 1.04), **b)),
         (0.72, P(hip=(0, -17), lean=12, feet=[(-16, 0), (14, 0)], bk=(-24, -12), sq=(1.08, 0.9), **b))]

    def fx(t, p):
        off = (t / 0.72 * 140) % 70
        o = "".join(f'<path d="M{x - off:.0f},2 h16" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-140, 180, 70))
        ph = (t % 0.36) / 0.36   # cada passo: estrondo
        if ph < 0.35:
            o += ab.fx_dust(0, 0, ph / 0.35, 1.2) + ab.fx_onda(0, 0, ph / 0.35, 0.7)
        return o
    return "ESCAVADEIRA · CORRER (pisa forte)", 0.72, k, fx, "treme_passo"


def A_pulo():
    k = [(0.0, BASE), (0.2, P(**{**BASE, "hip": (0, -13), "sq": (1.12, 0.78), "lean": 14, "head": 8})),
         (0.3, P(**{**BASE, "oy": -10, "sq": (0.94, 1.1), "feet": [(-7, -2), (7, 0)], "face": "raiva", "tool": (22, -26, -40)})),
         (0.5, P(**{**BASE, "oy": -30, "feet": [(-12, -8), (11, -6)], "tool": (22, -30, -60)})),
         (0.7, P(**{**BASE, "oy": 0, "sq": (1, 1.06), "tool": (24, -30, 60)})),
         (0.76, P(**{**BASE, "hip": (0, -12), "sq": (1.16, 0.72), "lean": 16, "head": 10, "tool": (24, -28, 70)})), (1.15, BASE)]

    def fx(t, p):
        o = ""
        if 0.2 < t < 0.4:
            o += ab.fx_dust(0, 0, (t - 0.2) / 0.2, 1.0)
        if 0.76 < t < 1.1:
            kk = (t - 0.76) / 0.34
            o += ab.fx_onda(0, 0, kk, 1.8) + ab.fx_dust(0, 0, kk, 1.6) + pedras(0, 0, kk)
        return o
    return "ESCAVADEIRA · PULAR (curto · pousa com estrondo)", 1.15, k, fx, "treme_pouso"


def A_leve():
    prep = P(**{**BASE, "lean": -4, "head": 6, "tool": (16, -28, -40), "face": "raiva"})
    hit = P(**{**BASE, "lean": 18, "head": -6, "tool": (24, -32, 50), "feet": [(-15, 0), (15, 0)], "face": "raiva", "sq": (1.06, 0.94)})
    k = [(0.0, BASE), (0.1, prep), (0.2, hit), (0.42, P(**{**hit, "tool": (24, -30, 56)})), (0.85, BASE)]

    def fx(t, p):
        o = ""
        if 0.12 < t < 0.24:
            o += ab.smear(p["tool"][:2], -40, 50, 12, 40)
        if 0.2 < t < 0.5:
            kk = (t - 0.2) / 0.3
            o += ab.fx_estrela(54, -8, kk, 12) + pedras(54, 0, kk, 4, 0.7)
        return o
    return "ESCAVADEIRA · GOLPE LEVE (raspa com a caçamba)", 0.85, k, fx, None


def A_pesado():
    ergue = P(**{**BASE, "lean": -14, "head": 10, "hip": (0, -18), "tool": (4, -56, -115), "bk": (-24, -20), "face": "raiva", "sq": (1.05, 0.96)})
    esmaga = P(**{**BASE, "lean": 26, "head": -8, "hip": (3, -14), "tool": (30, -36, 85), "feet": [(-16, 0), (17, 0)], "face": "raiva", "sq": (1.1, 0.84)})
    k = [(0.0, BASE), (0.25, ergue), (1.0, P(**{**ergue, "lean": -18, "tool": (2, -58, -120)})), (1.12, esmaga),
         (1.55, P(**{**esmaga, "sq": (1, 1)})), (2.1, BASE)]

    def fx(t, p):
        o = ""
        if 0.25 < t < 1.04:   # a caçamba balança pesada lá no alto (carregando)
            kk = min((t - 0.25) / 0.75, 1)
            o += f'<circle cx="-4" cy="-96" r="{12 + 10 * kk:.0f}" fill="#ffd27a" opacity="{0.15 + 0.3 * kk:.2f}"/>'
        if 1.04 < t < 1.16:
            o += ab.smear(p["tool"][:2], -115, 85, 12, 42)
        if 1.12 < t < 1.75:
            kk = (t - 1.12) / 0.63
            o += ab.fx_onda(36, 0, kk, 2.2) + pedras(36, 0, kk, 7, 1.3) + ab.fx_dust(36, 0, kk, 1.8)
            if kk < 0.3:
                o += ab.fx_estrela(36, -6, kk / 0.3, 24) + ab.impacto(36, 0)
            o += "".join(f'<path d="M{36 + d},0 l{d * 0.3:.0f},{-6 - kk * 4:.0f}" stroke="#5a4a36" stroke-width="2.5" stroke-linecap="round"/>' for d in (-26, -14, 12, 24))   # racha
        return o
    return "ESCAVADEIRA · GOLPE PESADO (ergue e esmaga)", 2.1, k, fx, "treme_pesado"


def A_duplo():
    air = dict(feet=[(-12, -8), (11, -6)], tool=(22, -30, -60))
    tuck = dict(feet=[(-6, -12), (6, -10)], tool=(16, -30, -90), hip=(0, -22))
    k = [(0.0, P(**{**BASE, "oy": -14, **air})), (0.1, P(**{**BASE, "oy": -18, "sq": (1, 1.08), "feet": [(-5, -1), (6, 1)], "tool": (22, -30, -60)})),
         (0.45, P(**{**BASE, "oy": -30, "rot": 360, "face": "raiva", **tuck})), (0.6, P(**{**BASE, "oy": -30, "rot": 360, **air})),
         (0.95, P(**{**BASE, "oy": 0, "rot": 360, "tool": (24, -30, 60)})), (1.01, P(**{**BASE, "rot": 360, "hip": (0, -12), "sq": (1.16, 0.72), "tool": (24, -28, 70)})), (1.35, P(**{**BASE, "rot": 360}))]

    def fx(t, p):
        if 0.06 < t < 0.22:   # a caçamba empurra o chão para o 2º pulo
            return f'<circle cx="24" cy="-14" r="{6 + 30 * (t - 0.06):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.06) * 4:.2f}"/>'
        if 1.01 < t < 1.33:
            kk = (t - 1.01) / 0.32
            return ab.fx_onda(0, 0, kk, 1.8) + pedras(0, 0, kk)
        return ""
    return "ESCAVADEIRA · PULO DUPLO (cambalhota pesada)", 1.35, k, fx, None


def A_parede():
    wall = dict(lean=-2, head=8, feet=[(-14, -4), (-2, -1)], tool=(22, -24, -20), face="foco")
    k = [(0.0, P(**{**BASE, "ox": -24, "oy": -34, **wall})), (0.9, P(**{**BASE, "ox": -24, "oy": -10, **wall})),
         (1.0, P(**{**BASE, "ox": -22, "oy": -12, "hip": (0, -13), "sq": (1.12, 0.76), "lean": -8, "feet": [(-12, -2), (-6, 0)], "tool": (22, -24, -20)})),
         (1.4, P(**{**BASE, "ox": 40, "oy": -36, "lean": 16, "feet": [(-12, -8), (11, -6)], "tool": (22, -30, -60), "face": "raiva"}))]

    def fx(t, p):
        o = '<rect x="-82" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-54" y="-200" width="6" height="210" fill="#b57a3e"/>'
        if t < 0.9:   # crava as pontas da caçamba na parede: farelo
            o += "".join(f'<rect x="{-48 + (i % 2) * 4}" y="{p["oy"] - 40 + ((t * 3 + i * 0.3) % 1) * 30:.0f}" width="4" height="4" fill="#b57a3e"/>' for i in range(3))
        return o
    return "ESCAVADEIRA · PAREDE (desce freando · salta)", 1.4, k, fx, None


def A_borda():
    hang = dict(hip=(0, -20), lean=0, head=-8, feet=[(-3, -4), (4, -1)], tool=(22, -46, -30), bk=(-14, -40), face="susto")
    k = [(0.0, P(**{**BASE, "oy": 8, **hang})), (0.5, P(**{**BASE, "oy": 8, **{**hang, "feet": [(-8, -1), (8, -6)]}})), (0.9, P(**{**BASE, "oy": 8, **hang})),
         (1.25, P(**{**BASE, "ox": 10, "oy": -34, "lean": 22, "feet": [(-4, -10), (10, -2)], "tool": (24, -30, 20), "face": "raiva", "sq": (1.06, 0.9)})),
         (1.7, P(**{**BASE, "ox": 32, "oy": -40}))]

    def fx(t, p):
        return '<rect x="22" y="-40" width="210" height="44" fill="#cfc6b4"/><rect x="22" y="-40" width="210" height="8" fill="#e8e0d0"/>'
    return "ESCAVADEIRA · BORDA (crava a caçamba · sobe)", 1.7, k, fx, None


def A_esquiva():
    low = P(**{**BASE, "hip": (0, -13), "lean": -12, "head": 10, "sq": (1.12, 0.8), "tool": (18, -26, -40), "face": "susto"})
    k = [(0.0, BASE), (0.06, low), (0.24, P(**{**low, "ox": -44})), (0.48, P(**{**BASE, "ox": -44})), (0.9, P(**{**BASE, "ox": 0}))]
    return "ESCAVADEIRA · ESQUIVA (rola pesada)", 0.9, k, None, "fantasma"


def A_cima():
    k = [(0.0, BASE), (0.1, P(**{**BASE, "hip": (0, -15), "sq": (1.08, 0.86), "tool": (24, -22, 40)})),
         (0.2, P(**{**BASE, "lean": -6, "head": -10, "hip": (0, -22), "tool": (26, -50, -65), "face": "raiva", "sq": (1, 1.08)})),
         (0.5, P(**{**BASE, "lean": -4, "head": -8, "tool": (26, -48, -70)})), (0.9, BASE)]

    def fx(t, p):
        if 0.14 < t < 0.26:
            return ab.smear(p["tool"][:2], 40, -65, 12, 40)
        return ab.fx_estrela(40, -92, (t - 0.2) / 0.3, 12) if 0.2 < t < 0.5 else ""
    return "ESCAVADEIRA · LEVE PARA CIMA", 0.9, k, fx, None


def A_baixo():
    air = dict(oy=-34, feet=[(-11, -9), (10, -6)])
    k = [(0.0, P(**{**BASE, **air, "tool": (16, -40, -90), "face": "raiva"})), (0.12, P(**{**BASE, **air, "tool": (26, -36, 85), "face": "raiva", "lean": 22})),
         (0.42, P(**{**BASE, "oy": 0, "tool": (26, -36, 85), "lean": 22, "hip": (0, -13), "sq": (1.14, 0.76), "face": "raiva"})), (0.95, BASE)]

    def fx(t, p):
        if 0.42 < t < 0.85:
            kk = (t - 0.42) / 0.43
            return ab.fx_onda(30, 0, kk, 1.6) + pedras(30, 0, kk, 6)
        return ""
    return "ESCAVADEIRA · LEVE PARA BAIXO (esmaga)", 0.95, k, fx, "treme_baixo"


def A_leva():
    hit = P(**{**BASE, "lean": -10, "head": 16, "sq": (1.02, 1.04), "ox": -6, "feet": [(-14, -2), (10, 0)], "tool": (22, -26, -30), "face": "dor"})
    k = [(0.0, BASE), (0.07, hit), (0.35, P(**{**hit, "ox": -10})), (0.9, P(**{**BASE, "ox": 0}))]

    def fx(t, p):
        return ab.fx_estrela(10, -44, (t - 0.05) / 0.25, 12) if 0.05 < t < 0.3 else ""
    return "ESCAVADEIRA · LEVA GOLPE (quase não se mexe)", 0.9, k, fx, None


def A_arremessado():
    fly = dict(feet=[(-12, -8), (-2, -14)], tool=(16, -32, -120), face="susto")
    k = [(0.0, BASE), (0.05, P(**{**BASE, "oy": -6, **fly})), (0.45, P(**{**BASE, "ox": -50, "oy": -34, "rot": -300, **fly})),
         (0.8, P(**{**BASE, "ox": -76, "oy": -6, "rot": -640, **fly})), (0.88, P(**{**BASE, "ox": -80, "oy": 0, "rot": -720, "hip": (0, -12), "sq": (1.18, 0.7)})),
         (1.0, P(**{**BASE, "ox": -84, "oy": 0, "rot": -720, "sq": (1.06, 0.92)})), (1.5, P(**{**BASE, "ox": -86, "rot": -720}))]

    def fx(t, p):
        if t < 0.78:
            return f'<g transform="translate({p["ox"] + 28:.0f},{p["oy"] - 30:.0f})">{ab.fx_lines(0, 0, 4, 22, 1)}</g>'
        if 0.88 < t < 1.2:
            kk = (t - 0.88) / 0.32
            return ab.fx_onda(p["ox"], 0, kk, 1.8) + pedras(p["ox"], 0, kk)
        return ""
    return "ESCAVADEIRA · ARREMESSADO (cai como pedra)", 1.5, k, fx, "treme_arr"


def A_engenhoca():
    k = [(0.0, BASE), (0.12, P(**{**BASE, "bk": (6, -36), "lean": 12, "face": "raiva"})), (0.6, P(**{**BASE, "bk": (7, -35), "lean": 12, "face": "raiva"})), (1.0, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="4" y="-46" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="9" cy="-49" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(9, -54, kk, 12) + f'<circle cx="9" cy="-40" r="{8 + kk * 46:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return "ESCAVADEIRA · USAR ENGENHOCA", 1.0, k, fx, None


def A_vitoria():
    up = P(**{**BASE, "lean": -4, "head": -6, "tool": (28, -50, -60), "face": "vitoria"})
    bate = P(**{**BASE, "lean": 10, "head": 4, "tool": (8, -30, -40), "face": "vitoria", "sq": (1.06, 0.94)})
    k = [(0.0, up), (0.35, bate), (0.7, up), (1.05, bate), (1.4, up)]

    def fx(t, p):
        return ab.fx_estrela(4, -46, ((t - 0.3) % 0.7) / 0.2, 10) if ((t - 0.3) % 0.7) < 0.2 else ""
    return "ESCAVADEIRA · VITÓRIA (bate a caçamba no peito)", 1.4, k, fx, None


def A_eliminado():
    k = [(0.0, P(**{**BASE, "face": "susto"})), (0.14, P(**{**BASE, "face": "eliminado", "sq": (1.12, 0.84)})),
         (0.2, P(**{**BASE, "oculto": True})), (1.4, P(**{**BASE, "oculto": True}))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:
            r = 22 + 64 * u
            o += f'<circle cx="0" cy="-26" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-26" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, eu.escava_head(COL, {"face": "eliminado"})), (40, -110, -400, eu.escava_torso(COL, {})),
                 (70, -90, -700, eu.cacamba((0, 0), 0, {})[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -26 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.85)">{svg}</g>'
        return o
    return "ESCAVADEIRA · ELIMINADO (desmonta)", 1.4, k, fx, None


def run(anims, saida, loops=()):
    ab.desenha = desenha
    ab.SC = 2.3
    ab.COL = COL
    ab.frame_svg.__defaults__ = (COL, None)
    orig = ab.frame_svg

    def frame(nome, dur, keys, fx, modo, t, col=COL, p=None):
        svg = orig(nome, dur, keys, fx, None if (modo or "").startswith("treme_") else modo, t, col, p)
        sh = 0.0
        if modo == "treme_passo":
            ph = (t % 0.36) / 0.36
            sh = 3.0 * (1 - ph / 0.3) if ph < 0.3 else 0
        elif modo == "treme_pouso" and 0.76 < t < 1.0:
            sh = 6.0 * (1 - (t - 0.76) / 0.24)
        elif modo == "treme_pesado" and 1.12 < t < 1.45:
            sh = 9.0 * (1 - (t - 1.12) / 0.33)
        elif modo == "treme_baixo" and 0.42 < t < 0.66:
            sh = 6.0 * (1 - (t - 0.42) / 0.24)
        elif modo == "treme_arr" and 0.88 < t < 1.1:
            sh = 6.0 * (1 - (t - 0.88) / 0.22)
        if sh > 0:   # tremor de câmera (tudo menos a etiqueta)
            dy = math.sin(t * 90) * sh
            svg = svg.replace('<rect x="8" y="8"', f'</g><rect x="8" y="8"', 1) if False else svg.replace(f'<g transform="translate(', f'<g transform="translate(0,{dy:.1f}) translate(', 1)
        return svg
    ab.frame_svg = frame
    ab.ANIMS = anims
    ab.LOOPS = set(loops)
    ab.main()
    ab.frame_svg = orig
    for a, b in (("anim_blindado.mp4", saida + ".mp4"), ("anim_blindado_lento.mp4", saida + "_lento.mp4"), ("anim_blindado_folha.png", saida + "_folha.png")):
        if os.path.exists(os.path.join(ab.OUT, a)):
            os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))


def main():
    if "--resto" in sys.argv:
        run([A_duplo, A_parede, A_borda, A_esquiva, A_cima, A_baixo, A_leva, A_arremessado, A_engenhoca, A_vitoria, A_eliminado], "escava_resto", loops=[A_vitoria])
        return
    run([A_correr, A_pulo, A_leve, A_pesado], "escava_lote1", loops=[A_correr])


if __name__ == "__main__":
    main()
