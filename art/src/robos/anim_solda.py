"""ANIMAÇÕES do SOLDA (elenco aprovado 2026-11-27): ranzinza corcunda, máscara de solda, tanques de gás nas costas, chave
inglesa gigante. Jeito próprio: anda gingando de lado a lado, tudo é pesado e resmungão, solta faísca e fumaça do
maçarico; golpe pesado = esquenta a chave até ficar vermelha. Rodar: python3 art/src/robos/anim_solda.py [--resto]
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import anim_blindado as ab  # noqa: E402
import elenco_uch as eu  # noqa: E402

P = ab.P
COL = "#f2c84b"


def desenha(pose, col=COL):
    if pose.get("oculto"):
        return ""
    pz = dict(hip=pose["hip"], lean=pose["lean"], head=pose.get("head", 0), feet=pose["feet"], grip=pose["tool"][:2], ang=pose["tool"][2],
              bk=pose.get("bk"), face=pose.get("face", "foco"), quente=pose.get("sirene", 0), fx_fixo=False)   # 'sirene' do motor = calor da chave
    body = eu.corpo_generico(eu.SOLDA, col, pz)
    sqx, sqy = pose["sq"]
    body = f'<g transform="skewX({pose.get("skew", 0):.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -26)">{body}</g>'
    return body


BASE = P(hip=(0, -22), lean=16, head=6, feet=[(-11, 0), (11, 0)], tool=(14, -20, -50), face="foco")


def fumaca(x, y, t, n=3):
    o = ""
    for i in range(n):
        u = ((t * 1.6 + i / n) % 1)
        o += f'<circle cx="{x - 6 * u + math.sin(u * 7 + i) * 3:.1f}" cy="{y - 22 * u:.1f}" r="{3 + 5 * u:.1f}" fill="#bfb8ae" opacity="{0.6 * (1 - u):.2f}"/>'
    return o


def faiscas(x, y, t, n=4, k=1.0):
    o = ""
    for i in range(n):
        a = -2.6 + i * 0.5 + math.sin(t * 30 + i) * 0.3
        L = (6 + 6 * ((t * 7 + i * 0.37) % 1)) * k
        o += f'<path d="M{x:.1f},{y:.1f} l{math.cos(a) * L:.1f},{math.sin(a) * L:.1f}" stroke="#ffd36b" stroke-width="2" stroke-linecap="round"/>'
    return o


def bico(p):
    """Bico do tanque (atrás da cabeça) no espaço do robô, para fumaça/faísca."""
    return (p["ox"] - 20 + p["lean"] * -0.2, p["oy"] - 40)


def A_correr():
    b = dict(head=4, tool=(16, -18, -40), face="foco")
    k = [(0.0, P(hip=(-2, -20), lean=12, feet=[(-14, -2), (12, 0)], sq=(1.04, 0.94), **b)),
         (0.13, P(hip=(2, -24), lean=22, feet=[(-4, -10), (4, -2)], sq=(0.97, 1.04), **b)),
         (0.26, P(hip=(-2, -20), lean=12, feet=[(12, 0), (-14, -2)], sq=(1.04, 0.94), **b)),
         (0.39, P(hip=(2, -24), lean=22, feet=[(4, -2), (-4, -10)], sq=(0.97, 1.04), **b)),
         (0.52, P(hip=(-2, -20), lean=12, feet=[(-14, -2), (12, 0)], sq=(1.04, 0.94), **b))]

    def fx(t, p):
        off = (t / 0.52 * 140) % 70
        x, y = bico(p)
        return ("".join(f'<path d="M{x_ - off:.0f},2 h16" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x_ in range(-140, 180, 70))
                + fumaca(x, y, t))
    return "SOLDA · CORRER (corcunda, gingando)", 0.52, k, fx, None


def A_pulo():
    k = [(0.0, BASE), (0.16, P(**{**BASE, "hip": (0, -16), "sq": (1.06, 0.82), "lean": 26, "head": 10})),
         (0.24, P(**{**BASE, "oy": -12, "sq": (0.96, 1.1), "feet": [(-5, -2), (5, 0)], "face": "raiva"})),
         (0.45, P(**{**BASE, "oy": -40, "lean": 10, "feet": [(-11, -8), (10, -6)], "tool": (16, -24, -70)})),
         (0.68, P(**{**BASE, "oy": 0, "sq": (1, 1.04)})), (0.74, P(**{**BASE, "hip": (0, -15), "sq": (1.1, 0.78), "lean": 28, "head": 12})), (1.05, BASE)]

    def fx(t, p):
        o = ""
        x, y = bico(p)
        if 0.18 < t < 0.5:   # sopro do maçarico ajuda a subir
            u = (t - 0.18) / 0.32
            o += f'<path d="M{x},{y} l-6,{14 + 10 * u:.0f} l6,-4 l6,4 Z" fill="#ff8a2a" opacity="{1 - u:.2f}"/>' + fumaca(x, y + 10, t, 4)
        if 0.74 < t < 0.98:
            o += ab.fx_dust(0, 0, (t - 0.74) / 0.24, 1.3)
        return o
    return "SOLDA · PULAR (pesado, sopro do maçarico)", 1.05, k, fx, None


def A_leve():
    prep = P(**{**BASE, "lean": 8, "head": 10, "tool": (8, -26, -110), "face": "raiva"})
    hit = P(**{**BASE, "lean": 28, "head": -4, "hip": (2, -21), "tool": (16, -24, 5), "feet": [(-13, 0), (15, 0)], "face": "raiva", "sq": (1.05, 0.95)})
    k = [(0.0, BASE), (0.08, prep), (0.15, hit), (0.38, P(**{**hit, "tool": (16, -22, 15)})), (0.75, BASE)]

    def fx(t, p):
        o = ""
        if 0.1 < t < 0.2:
            o += ab.smear(p["tool"][:2], -110, 5, 18, 44)
        if 0.15 < t < 0.45:
            o += faiscas(58, -24, t, 6, 1.4) + ab.fx_estrela(58, -24, (t - 0.15) / 0.3, 11)
        return o
    return "SOLDA · GOLPE LEVE (pancada com faísca)", 0.75, k, fx, None


def A_pesado():
    esquenta = P(**{**BASE, "lean": 4, "head": 14, "tool": (-6, -32, -150), "face": "raiva", "sq": (1.04, 0.94)})
    k = [(0.0, BASE), (0.2, esquenta), (1.0, P(**{**esquenta, "sirene": 1.0, "lean": 2})),
         (1.08, P(**{**BASE, "lean": -6, "hip": (0, -20), "head": 6, "tool": (2, -44, -120), "face": "raiva", "sirene": 1.0, "sq": (1, 1.06)})),
         (1.18, P(**{**BASE, "lean": 32, "hip": (3, -18), "head": -6, "tool": (16, -20, 60), "feet": [(-15, 0), (16, 0)], "face": "raiva", "sirene": 1.0, "sq": (1.06, 0.88)})),
         (1.6, P(**{**BASE, "lean": 30, "hip": (3, -18), "tool": (16, -16, 70), "feet": [(-15, 0), (16, 0)], "sirene": 0.4})), (2.1, BASE)]

    def fx(t, p):
        o = ""
        x, y = bico(p)
        if 0.2 < t < 1.04:   # chama do maçarico na cabeça da chave
            kk = min((t - 0.2) / 0.8, 1)
            g, a = p["tool"][:2], math.radians(p["tool"][2])
            hx, hy = g[0] + math.cos(a) * 30, g[1] + math.sin(a) * 30
            fl = 6 + 4 * math.sin(t * 40)
            o += f'<path d="M{hx + 10:.1f},{hy + 2:.1f} l{-fl:.1f},-4 l{-fl * 0.6:.1f},4 l{fl * 0.6:.1f},4 Z" fill="#7fd3ff" opacity="0.9"/>'
            o += faiscas(hx, hy, t, int(3 + 5 * kk), 1.2) + fumaca(hx, hy - 4, t, 3)
        if 1.1 < t < 1.22:
            o += ab.smear(p["tool"][:2], -120, 60, 18, 46)
        if 1.16 < t < 1.7:
            kk = (t - 1.16) / 0.54
            o += ab.fx_onda(52, 0, kk, 1.4) + ((ab.fx_estrela(52, -6, kk, 20) + ab.impacto(52, 0) + faiscas(52, -6, t, 8, 2.0)) if kk < 0.35 else fumaca(52, -4, t, 3))
        return o
    return "SOLDA · GOLPE PESADO (esquenta a chave e desce)", 2.1, k, fx, None


def A_duplo():
    air = dict(feet=[(-11, -8), (10, -6)], tool=(16, -24, -70))
    tuck = dict(feet=[(-4, -14), (4, -12)], tool=(10, -22, -100), hip=(0, -24))
    k = [(0.0, P(**{**BASE, "oy": -14, **air})), (0.08, P(**{**BASE, "oy": -18, "sq": (1, 1.08), "feet": [(-3, -1), (4, 1)], "tool": (16, -24, -70)})),
         (0.38, P(**{**BASE, "oy": -30, "rot": 360, "face": "raiva", **tuck})), (0.52, P(**{**BASE, "oy": -30, "rot": 360, **air})),
         (0.9, P(**{**BASE, "oy": 0, "rot": 360})), (0.96, P(**{**BASE, "rot": 360, "hip": (0, -15), "sq": (1.1, 0.78)})), (1.25, P(**{**BASE, "rot": 360}))]

    def fx(t, p):
        x, y = bico(p)
        if 0.06 < t < 0.3:   # o maçarico dispara para o 2º pulo
            u = (t - 0.06) / 0.24
            return f'<path d="M{x},{y} l-7,{16 + 12 * u:.0f} l7,-5 l7,5 Z" fill="#ff8a2a" opacity="{1 - u:.2f}"/>' + fumaca(x, y + 12, t, 4)
        return ab.fx_dust(0, 0, (t - 0.96) / 0.25, 1.2) if 0.96 < t < 1.21 else ""
    return "SOLDA · PULO DUPLO (jato do maçarico)", 1.25, k, fx, None


def A_parede():
    wall = dict(lean=-2, head=10, feet=[(-12, -6), (-2, -1)], tool=(16, -22, -60), face="foco")
    k = [(0.0, P(**{**BASE, "ox": -26, "oy": -40, **wall})), (0.9, P(**{**BASE, "ox": -26, "oy": -12, **wall})),
         (1.0, P(**{**BASE, "ox": -24, "oy": -14, "hip": (0, -16), "sq": (1.1, 0.78), "lean": -8, "feet": [(-11, -2), (-6, 0)], "tool": (16, -22, -60)})),
         (1.4, P(**{**BASE, "ox": 46, "oy": -46, "lean": 18, "feet": [(-11, -8), (10, -6)], "tool": (16, -24, -70), "face": "raiva"}))]

    def fx(t, p):
        o = '<rect x="-78" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-50" y="-200" width="6" height="210" fill="#b57a3e"/>'
        if t < 0.9:   # as botas raspam a parede soltando faísca
            o += faiscas(-44, p["oy"] - 2, t, 3, 0.9)
        return o
    return "SOLDA · PAREDE (raspa faiscando · salta)", 1.4, k, fx, None


def A_borda():
    hang = dict(hip=(0, -22), lean=0, head=-8, feet=[(-3, -4), (4, -1)], tool=(18, -44, -20), bk=(-2, -46), face="susto")
    k = [(0.0, P(**{**BASE, "oy": 4, **hang})), (0.5, P(**{**BASE, "oy": 4, **{**hang, "feet": [(-8, -1), (8, -6)]}})), (0.9, P(**{**BASE, "oy": 4, **hang})),
         (1.2, P(**{**BASE, "ox": 10, "oy": -36, "lean": 24, "feet": [(-4, -10), (10, -2)], "tool": (16, -22, -50), "face": "raiva", "sq": (1.04, 0.9)})),
         (1.6, P(**{**BASE, "ox": 34, "oy": -40}))]

    def fx(t, p):
        return '<rect x="22" y="-40" width="210" height="44" fill="#cfc6b4"/><rect x="22" y="-40" width="210" height="8" fill="#e8e0d0"/>'
    return "SOLDA · BORDA (engancha a chave · sobe)", 1.6, k, fx, None


def A_esquiva():
    low = P(**{**BASE, "hip": (0, -15), "lean": -12, "head": 12, "sq": (1.1, 0.82), "tool": (12, -20, -80), "face": "susto"})
    k = [(0.0, BASE), (0.05, low), (0.2, P(**{**low, "ox": -48})), (0.42, P(**{**BASE, "ox": -48})), (0.8, P(**{**BASE, "ox": 0}))]
    return "SOLDA · ESQUIVA", 0.8, k, None, "fantasma"


def A_cima():
    k = [(0.0, BASE), (0.08, P(**{**BASE, "hip": (0, -17), "sq": (1.06, 0.86), "tool": (14, -14, 40)})),
         (0.16, P(**{**BASE, "lean": -6, "head": -12, "hip": (0, -24), "tool": (12, -40, -95), "face": "raiva", "sq": (1, 1.08)})),
         (0.45, P(**{**BASE, "lean": -4, "head": -10, "tool": (12, -38, -100)})), (0.8, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.24:
            return ab.smear(p["tool"][:2], 40, -95, 18, 44)
        return faiscas(14, -84, t, 5, 1.2) + ab.fx_estrela(14, -84, (t - 0.16) / 0.28, 10) if 0.16 < t < 0.44 else ""
    return "SOLDA · GOLPE LEVE PARA CIMA", 0.8, k, fx, None


def A_baixo():
    air = dict(oy=-44, feet=[(-10, -9), (9, -6)])
    k = [(0.0, P(**{**BASE, **air, "tool": (10, -34, -110), "face": "raiva"})), (0.1, P(**{**BASE, **air, "tool": (14, -14, 88), "face": "raiva", "lean": 26})),
         (0.42, P(**{**BASE, "oy": 0, "tool": (14, -14, 88), "lean": 26, "hip": (0, -16), "sq": (1.1, 0.8), "face": "raiva"})), (0.9, BASE)]

    def fx(t, p):
        return (ab.fx_onda(18, 0, (t - 0.42) / 0.35) + faiscas(18, -4, t, 6, 1.4)) if 0.42 < t < 0.77 else ""
    return "SOLDA · GOLPE LEVE PARA BAIXO (no ar)", 0.9, k, fx, None


def A_leva():
    hit = P(**{**BASE, "lean": -10, "head": 22, "sq": (1, 1.08), "ox": -12, "feet": [(-14, -2), (8, 0)], "tool": (6, -18, -160), "face": "dor"})
    k = [(0.0, BASE), (0.06, hit), (0.35, P(**{**hit, "ox": -20})), (0.9, P(**{**BASE, "ox": 0}))]

    def fx(t, p):
        x, y = bico(p)
        return (ab.fx_estrela(10, -46, (t - 0.04) / 0.25, 11) + fumaca(x, y, t, 4)) if 0.04 < t < 0.5 else ""
    return "SOLDA · LEVA GOLPE (o tanque solta fumaça)", 0.9, k, fx, None


def A_arremessado():
    fly = dict(feet=[(-12, -8), (-2, -14)], tool=(4, -30, -150), face="susto")
    k = [(0.0, BASE), (0.05, P(**{**BASE, "oy": -6, **fly})), (0.5, P(**{**BASE, "ox": -54, "oy": -40, "rot": -340, **fly})),
         (0.92, P(**{**BASE, "ox": -84, "oy": -12, "rot": -660, **fly})), (1.02, P(**{**BASE, "ox": -87, "oy": -8, "rot": -720, "feet": [(-11, -4), (10, -2)]})),
         (1.12, P(**{**BASE, "ox": -90, "oy": 0, "rot": -720, "hip": (0, -15), "sq": (1.12, 0.76)})), (1.6, P(**{**BASE, "ox": -92, "rot": -720}))]

    def fx(t, p):
        if t < 0.9:   # rastro de fumaça dos tanques enquanto voa
            return f'<g transform="translate({p["ox"] + 26:.0f},{p["oy"] - 34:.0f})">{ab.fx_lines(0, 0, 3, 24, 1)}</g>' + fumaca(p["ox"] + 10, p["oy"] - 30, t, 5)
        return ab.fx_dust(p["ox"], 0, (t - 1.12) / 0.25, 1.2) if 1.12 < t < 1.37 else ""
    return "SOLDA · ARREMESSADO (rastro de fumaça)", 1.6, k, fx, "desloca"


def A_engenhoca():
    k = [(0.0, BASE), (0.12, P(**{**BASE, "bk": (16, -36), "lean": 12, "face": "raiva"})), (0.6, P(**{**BASE, "bk": (17, -35), "lean": 12, "face": "raiva"})), (1.0, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="14" y="-46" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="19" cy="-49" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(19, -54, kk, 12) + f'<circle cx="19" cy="-40" r="{8 + kk * 46:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return "SOLDA · USAR ENGENHOCA", 1.0, k, fx, None


def A_vitoria():
    up = P(**{**BASE, "lean": 0, "head": -6, "tool": (18, -40, -70), "face": "vitoria"})
    k = [(0.0, up), (0.45, P(**{**up, "lean": 6, "sirene": 1.0})), (0.9, P(**{**up, "lean": -2, "sirene": 0.3})), (1.35, P(**{**up, "lean": 6, "sirene": 1.0})), (1.8, up)]

    def fx(t, p):
        g, a = p["tool"][:2], math.radians(p["tool"][2])
        hx, hy = g[0] + math.cos(a) * 34, g[1] + math.sin(a) * 34
        return faiscas(hx, hy, t, 6, 1.3) + fumaca(hx, hy - 4, t, 2)
    return "SOLDA · VITÓRIA (chave em brasa, faiscando)", 1.8, k, fx, None


def A_eliminado():
    k = [(0.0, P(**{**BASE, "face": "susto"})), (0.14, P(**{**BASE, "face": "eliminado", "sq": (1.1, 0.86)})),
         (0.2, P(**{**BASE, "oculto": True})), (1.4, P(**{**BASE, "oculto": True}))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:
            r = 20 + 60 * u
            o += f'<circle cx="0" cy="-30" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-30" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, eu.solda_head(COL, {"face": "eliminado"})), (50, -120, -500, eu.solda_torso(COL, {})),
                 (-30, -140, 600, eu.R(-8, -14, 8, 22, 4, "#d9482b", k=0.5)), (70, -80, -800, eu.chave((0, 0), 0, {})[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -30 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.9)">{svg}</g>'
        return o + fumaca(0, -10, t, 5)
    return "SOLDA · ELIMINADO (desmonta e fumega)", 1.4, k, fx, None


def run(anims, saida, loops=()):
    ab.desenha = desenha
    ab.SC = 2.6
    ab.COL = COL
    ab.frame_svg.__defaults__ = (COL, None)
    ab.ANIMS = anims
    ab.LOOPS = set(loops)
    ab.main()
    for a, b in (("anim_blindado.mp4", saida + ".mp4"), ("anim_blindado_lento.mp4", saida + "_lento.mp4"), ("anim_blindado_folha.png", saida + "_folha.png")):
        if os.path.exists(os.path.join(ab.OUT, a)):
            os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))


def main():
    if "--resto" in sys.argv:
        run([A_duplo, A_parede, A_borda, A_esquiva, A_cima, A_baixo, A_leva, A_arremessado, A_engenhoca, A_vitoria, A_eliminado], "solda_resto", loops=[A_vitoria])
        return
    run([A_correr, A_pulo, A_leve, A_pesado], "solda_lote1", loops=[A_correr])


if __name__ == "__main__":
    main()
