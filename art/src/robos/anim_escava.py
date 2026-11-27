"""ANIMAÇÕES da ESCAVADEIRA (elenco aprovado 2026-11-27): pesadona e assimétrica, braço que é uma caçamba, cabecinha de
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


BASE = P(hip=(0, -20), lean=6, head=0, feet=[(-13, 0), (13, 0)], tool=(24, -20, 10), bk=(-22, -14), face="foco")


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
    run([A_correr, A_pulo, A_leve, A_pesado], "escava_lote1", loops=[A_correr])


if __name__ == "__main__":
    main()
