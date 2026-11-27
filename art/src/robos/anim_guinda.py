"""ANIMAÇÕES do GUINDASTE (elenco aprovado 2026-11-27): alto, magro e calmo; pescoço longo que ginga; olhão de lente;
gancho na corrente de alcance longo. Jeito próprio: passos longos e lentos, sobe flutuando e desce devagar, a corrente
balança atrasada (mola) e chicoteia no golpe. Rodar: python3 art/src/robos/anim_guinda.py [--resto]
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import anim_blindado as ab  # noqa: E402
import elenco_uch as eu  # noqa: E402

P = ab.P
COL = "#f06aa8"


def desenha(pose, col=COL):
    if pose.get("oculto"):
        return ""
    pz = dict(hip=pose["hip"], lean=pose["lean"], head=pose.get("head", 0), feet=pose["feet"], grip=pose["tool"][:2], ang=pose["tool"][2],
              bk=pose.get("bk"), face=pose.get("face", "foco"), chain_L=pose.get("chain_L", 30), chain_sag=pose.get("chain_sag", 10), rastro=False)
    body = eu.corpo_generico(eu.GUINDA, col, pz)
    sqx, sqy = pose["sq"]
    body = f'<g transform="skewX({pose.get("skew", 0):.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -40)">{body}</g>'
    return body


def C(L, sag, **k):
    """Pose com corrente (comprimento e barriga interpolados pelo motor através de 'sirene' livre? não: campos próprios)."""
    p = P(**k)
    p["chain_L"], p["chain_sag"] = L, sag
    return p


BASE = C(30, 10, hip=(0, -36), lean=2, head=0, feet=[(-9, 0), (9, 0)], tool=(12, -34, 80), bk=(-10, -26), face="foco")

# o motor interpola só os campos conhecidos: a corrente vai junto pelo "bk"? Não — interpolamos aqui por tempo.


def anim(nome, dur, keys, fx=None, modo=None, chain=None):
    """chain = [(t, L, sag), …]: comprimento/barriga da corrente ao longo do tempo (interpolado aqui, com balanço)."""
    return nome, dur, keys, fx, modo, chain


def chain_at(chain, t):
    if not chain:
        return 30, 10
    if t <= chain[0][0]:
        return chain[0][1], chain[0][2]
    for (t0, l0, s0), (t1, l1, s1) in zip(chain, chain[1:]):
        if t <= t1:
            u = (t - t0) / max(t1 - t0, 1e-6)
            u = u * u * (3 - 2 * u)
            return l0 + (l1 - l0) * u, s0 + (s1 - s0) * u
    return chain[-1][1], chain[-1][2]


def A_correr():
    b = dict(lean=10, tool=(14, -34, 100), bk=(-14, -24), face="foco")
    k = [(0.0, P(hip=(0, -34), head=-6, feet=[(-20, -2), (18, 0)], sq=(1, 0.97), **b)),
         (0.15, P(hip=(0, -40), head=4, feet=[(-4, -12), (4, -2)], sq=(1, 1.03), **b)),
         (0.3, P(hip=(0, -34), head=-6, feet=[(18, 0), (-20, -2)], sq=(1, 0.97), **b)),
         (0.45, P(hip=(0, -40), head=4, feet=[(4, -2), (-4, -12)], sq=(1, 1.03), **b)),
         (0.6, P(hip=(0, -34), head=-6, feet=[(-20, -2), (18, 0)], sq=(1, 0.97), **b))]

    def fx(t, p):
        off = (t / 0.6 * 140) % 70
        return "".join(f'<path d="M{x - off:.0f},2 h18" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-140, 180, 70))
    return anim("GUINDASTE · CORRER (passos longos, ginga)", 0.6, k, fx, None, [(0, 30, 10), (0.15, 28, 4), (0.3, 30, 12), (0.45, 28, 4), (0.6, 30, 10)])


def A_pulo():
    k = [(0.0, BASE), (0.14, P(**{**BASE, "hip": (0, -30), "sq": (1, 0.86), "lean": 12, "head": 8})),
         (0.22, P(**{**BASE, "oy": -18, "sq": (1, 1.1), "feet": [(-4, -2), (4, 0)]})),
         (0.55, P(**{**BASE, "oy": -44, "head": -8, "feet": [(-12, -10), (10, -14)], "tool": (14, -34, 150)})),   # flutua (o gancho fica para trás, atrasado)
         (0.95, P(**{**BASE, "oy": -40, "head": -4, "feet": [(-10, -12), (12, -8)], "tool": (14, -34, 130)})),
         (1.3, P(**{**BASE, "oy": 0, "feet": [(-10, 0), (10, 0)]})), (1.38, P(**{**BASE, "hip": (0, -31), "sq": (1, 0.9)})), (1.6, BASE)]

    def fx(t, p):
        o = ""
        if 0.14 < t < 0.34:
            o += ab.fx_dust(0, 0, (t - 0.14) / 0.2, 0.7)
        if 1.38 < t < 1.58:
            o += ab.fx_dust(0, 0, (t - 1.38) / 0.2, 0.7)
        return o
    return anim("GUINDASTE · PULAR (flutua · desce devagar)", 1.6, k, fx, None, [(0, 30, 10), (0.22, 24, -6), (0.55, 30, 14), (1.0, 32, 4), (1.3, 30, 16), (1.6, 30, 10)])


def A_leve():
    prep = P(**{**BASE, "lean": -4, "head": 6, "tool": (6, -50, -150), "face": "raiva"})
    hit = P(**{**BASE, "lean": 14, "head": -6, "tool": (12, -60, -8), "feet": [(-14, 0), (14, 0)], "face": "raiva"})
    k = [(0.0, BASE), (0.12, prep), (0.2, hit), (0.42, P(**{**hit, "tool": (12, -56, 10)})), (0.8, BASE)]

    def fx(t, p):
        if 0.16 < t < 0.34:
            L = p.get("chain_L", 70)
            g, a = p["tool"][:2], math.radians(p["tool"][2])
            hx, hy = g[0] + math.cos(a) * L, g[1] + math.sin(a) * L
            return f'<path d="M{g[0] - 4:.0f},{g[1] - 18:.0f} Q{(g[0] + hx) / 2:.0f},{g[1] - 30:.0f} {hx:.0f},{hy:.0f}" stroke="#ffffff" stroke-width="9" fill="none" opacity="0.5" stroke-linecap="round"/>' + ab.fx_estrela(hx + 4, hy, (t - 0.18) / 0.16, 12)
        return ""
    return anim("GUINDASTE · GOLPE LEVE (chicotada de longe)", 0.8, k, fx, None, [(0, 30, 10), (0.12, 26, -8), (0.18, 66, 0), (0.32, 68, -2), (0.48, 54, 8), (0.8, 30, 10)])


def A_pesado():
    gira = P(**{**BASE, "lean": -2, "head": -10, "tool": (4, -70, -90), "bk": (-6, -66), "face": "raiva", "feet": [(-12, 0), (12, 0)]})
    lanca = P(**{**BASE, "lean": 18, "head": -8, "tool": (14, -56, 34), "feet": [(-18, 0), (18, 0)], "face": "raiva"})
    k = [(0.0, BASE), (0.18, gira), (1.0, P(**{**gira, "lean": -4})), (1.1, lanca), (1.45, P(**{**lanca, "tool": (14, -50, 38)})), (2.0, BASE)]

    def fx(t, p):
        o = ""
        if 0.18 < t < 1.04:   # gancho girando acima da cabeça (laço)
            kk = min((t - 0.18) / 0.8, 1)
            a = t * (14 + 12 * kk)
            cx, cy = 4, -104
            R = 30 + 6 * kk
            hx, hy = cx + math.cos(a) * R, cy + math.sin(a) * R * 0.35
            o += f'<ellipse cx="{cx}" cy="{cy}" rx="{R:.0f}" ry="{R * 0.35:.0f}" fill="none" stroke="#ffffff" stroke-width="{3 + 4 * kk:.1f}" opacity="{0.3 + 0.4 * kk:.2f}"/>'
            o += f'<line x1="4" y1="-70" x2="{hx:.1f}" y2="{hy:.1f}" stroke="#6b7783" stroke-width="2.5" stroke-dasharray="4 2"/>'
            o += f'<rect x="{hx - 6:.1f}" y="{hy - 4:.1f}" width="12" height="8" rx="2" fill="#f2c84b"/>'
        if 1.06 < t < 1.6:
            kk = (t - 1.06) / 0.54
            L = p.get("chain_L", 90)
            g, a = p["tool"][:2], math.radians(p["tool"][2])
            hx, hy = g[0] + math.cos(a) * L, g[1] + math.sin(a) * L
            o += f'<path d="M{g[0]:.0f},{g[1]:.0f} L{hx:.0f},{hy:.0f}" stroke="#ffffff" stroke-width="{8 * (1 - kk):.1f}" opacity="0.5" stroke-linecap="round"/>' if kk < 0.4 else ""
            o += ab.fx_estrela(hx, hy, kk, 20) if kk < 0.4 else ""
            o += f'<g transform="translate({hx:.0f},{min(hy, 0):.0f})">{ab.fx_onda(0, 0, kk, 1.0)}</g>' if hy > -10 else ""
        return o
    return anim("GUINDASTE · GOLPE PESADO (gira o gancho e lança)", 2.0, k, fx, None, [(0, 30, 10), (0.18, 2, 0), (1.04, 2, 0), (1.1, 92, 0), (1.45, 86, 4), (2.0, 30, 10)])


def run(anims, saida):
    ab.desenha = desenha
    ab.SC = 2.0
    ab.COL = COL
    ab.frame_svg.__defaults__ = (COL, None)
    orig_sim = ab.simular
    chains = {}

    def wrap(fn):
        def f():
            nome, dur, keys, fx, modo, chain = fn()
            chains[nome] = chain
            return nome, dur, keys, fx, modo
        f.__name__ = fn.__name__
        return f
    wrapped = [wrap(fn) for fn in anims]

    def sim(keys, dur, loop):
        nome = sim.atual
        poses = orig_sim(keys, dur, loop)
        ch = chains.get(nome)
        m = ab.Mola(30, 4.0, 0.35)
        for i, p in enumerate(poses):
            L, sag = chain_at(ch, i / ab.FPS)
            p["chain_L"] = L
            p["chain_sag"] = m.step(sag, 1 / ab.FPS) if ch else sag   # a barriga da corrente balança atrasada
        return poses
    orig_main_anims = wrapped
    ab.ANIMS = wrapped
    ab.LOOPS = {w for w, fn in zip(wrapped, anims) if fn.__name__ == "A_correr"}

    real = ab.simular
    calls = iter([fn()[0] for fn in wrapped])

    def sim2(keys, dur, loop):
        sim.atual = next(calls)
        return sim(keys, dur, loop)
    ab.simular = sim2
    ab.main()
    ab.simular = real
    for a, b in (("anim_blindado.mp4", saida + ".mp4"), ("anim_blindado_lento.mp4", saida + "_lento.mp4"), ("anim_blindado_folha.png", saida + "_folha.png")):
        if os.path.exists(os.path.join(ab.OUT, a)):
            os.replace(os.path.join(ab.OUT, a), os.path.join(ab.OUT, b))


def main():
    run([A_correr, A_pulo, A_leve, A_pesado], "guinda_lote1")


if __name__ == "__main__":
    main()
