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
    run([A_correr, A_pulo, A_leve, A_pesado], "solda_lote1", loops=[A_correr])


if __name__ == "__main__":
    main()
