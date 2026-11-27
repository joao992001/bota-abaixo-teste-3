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


def marca_alcance(x, nome):
    return (f'<path d="M{x},-110 V4" stroke="#d42035" stroke-width="2" stroke-dasharray="6 5" opacity="0.7"/>'
            f'<text x="{x - 46}" y="-100" font-family="Fredoka, Arial" font-weight="700" font-size="9" fill="#d42035">{nome}</text>')


def A_leve():
    prep = P(**{**BASE, "lean": -4, "head": 6, "tool": (6, -50, -150), "face": "raiva"})
    hit = P(**{**BASE, "lean": 14, "head": -6, "tool": (12, -60, -8), "feet": [(-14, 0), (14, 0)], "face": "raiva"})
    k = [(0.0, BASE), (0.12, prep), (0.2, hit), (0.42, P(**{**hit, "tool": (12, -56, 10)})), (0.8, BASE)]

    def fx(t, p):
        if 0.16 < t < 0.34:
            L = p.get("chain_L", 70)
            g, a = p["tool"][:2], math.radians(p["tool"][2])
            hx, hy = g[0] + math.cos(a) * L, g[1] + math.sin(a) * L
            return marca_alcance(56, "alcance") + f'<path d="M{g[0] - 4:.0f},{g[1] - 18:.0f} Q{(g[0] + hx) / 2:.0f},{g[1] - 30:.0f} {hx:.0f},{hy:.0f}" stroke="#ffffff" stroke-width="9" fill="none" opacity="0.5" stroke-linecap="round"/>' + ab.fx_estrela(hx + 4, hy, (t - 0.18) / 0.16, 12)
        return marca_alcance(56, "alcance")
    return anim("GUINDASTE · GOLPE LEVE (chicotada de longe)", 0.8, k, fx, None, [(0, 30, 10), (0.12, 26, -8), (0.18, 34, 0), (0.32, 35, -2), (0.48, 32, 8), (0.8, 30, 10)])


def A_pesado():
    gira = P(**{**BASE, "lean": -2, "head": -10, "tool": (4, -70, -90), "bk": (-6, -66), "face": "raiva", "feet": [(-12, 0), (12, 0)]})
    lanca = P(**{**BASE, "lean": 18, "head": -8, "tool": (14, -56, 34), "feet": [(-18, 0), (18, 0)], "face": "raiva"})
    k = [(0.0, BASE), (0.18, gira), (1.0, P(**{**gira, "lean": -4})), (1.1, lanca), (1.45, P(**{**lanca, "tool": (14, -50, 38)})), (2.0, BASE)]

    def fx(t, p):
        o = marca_alcance(70, "alcance")
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
    return anim("GUINDASTE · GOLPE PESADO (gira o gancho e lança)", 2.0, k, fx, None, [(0, 30, 10), (0.18, 2, 0), (1.04, 2, 0), (1.1, 52, 0), (1.45, 50, 4), (2.0, 30, 10)])


def A_duplo():
    air = dict(feet=[(-12, -10), (10, -14)], tool=(14, -34, 150))
    tuck = dict(feet=[(-6, -18), (6, -16)], tool=(10, -36, 120), hip=(0, -32))
    k = [(0.0, P(**{**BASE, "oy": -18, **air})), (0.1, P(**{**BASE, "oy": -22, "sq": (1, 1.06), "feet": [(-4, -2), (4, 0)], "tool": (14, -34, 150)})),
         (0.5, P(**{**BASE, "oy": -32, "rot": 360, "face": "raiva", **tuck})), (0.75, P(**{**BASE, "oy": -32, "rot": 360, **air})),
         (1.2, P(**{**BASE, "oy": 0, "rot": 360, "feet": [(-10, 0), (10, 0)]})), (1.28, P(**{**BASE, "rot": 360, "hip": (0, -31), "sq": (1, 0.9)})), (1.5, P(**{**BASE, "rot": 360}))]

    def fx(t, p):
        return f'<circle cx="0" cy="-30" r="{6 + 30 * (t - 0.06):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.06) * 4:.2f}"/>' if 0.06 < t < 0.22 else ""
    return anim("GUINDASTE · PULO DUPLO (giro lento)", 1.5, k, fx, None, [(0, 30, 14), (0.5, 20, 0), (0.9, 30, 16), (1.5, 30, 10)])


def A_parede():
    wall = dict(lean=-4, head=10, feet=[(-14, -8), (-2, -2)], tool=(14, -40, 120), face="foco")
    k = [(0.0, P(**{**BASE, "ox": -24, "oy": -34, **wall})), (0.9, P(**{**BASE, "ox": -24, "oy": -10, **wall})),
         (1.0, P(**{**BASE, "ox": -22, "oy": -12, "hip": (0, -30), "sq": (1, 0.9), "lean": -10, "feet": [(-12, -2), (-6, 0)], "tool": (14, -40, 120)})),
         (1.5, P(**{**BASE, "ox": 50, "oy": -40, "lean": 16, "feet": [(-12, -10), (10, -14)], "tool": (14, -34, 160), "face": "raiva"}))]

    def fx(t, p):
        return '<rect x="-74" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-46" y="-200" width="6" height="210" fill="#b57a3e"/>'
    return anim("GUINDASTE · PAREDE (desliza · salta)", 1.5, k, fx, None, [(0, 30, 6), (0.9, 30, 14), (1.5, 30, 6)])


def A_borda():
    hang = dict(hip=(0, -36), lean=0, head=-10, feet=[(-3, -6), (4, -2)], tool=(14, -64, -40), bk=(-4, -60), face="susto")
    k = [(0.0, P(**{**BASE, "oy": 22, **hang})), (0.5, P(**{**BASE, "oy": 22, **{**hang, "feet": [(-8, -2), (8, -8)]}})), (0.9, P(**{**BASE, "oy": 22, **hang})),
         (1.25, P(**{**BASE, "ox": 10, "oy": -30, "lean": 20, "feet": [(-4, -10), (12, -2)], "tool": (12, -34, 100), "face": "raiva", "sq": (1, 0.92)})),
         (1.7, P(**{**BASE, "ox": 40, "oy": -40}))]

    def fx(t, p):
        return '<rect x="24" y="-40" width="210" height="44" fill="#cfc6b4"/><rect x="24" y="-40" width="210" height="8" fill="#e8e0d0"/>'
    return anim("GUINDASTE · BORDA (pendura no gancho · sobe)", 1.7, k, fx, None, [(0, 12, 0), (0.9, 12, 0), (1.2, 30, 12), (1.7, 30, 10)])


def A_esquiva():
    low = P(**{**BASE, "hip": (0, -30), "lean": -20, "head": 14, "sq": (1.04, 0.92), "tool": (10, -30, 130), "face": "susto", "feet": [(-18, 0), (8, 0)]})
    k = [(0.0, BASE), (0.05, low), (0.22, P(**{**low, "ox": -56})), (0.45, P(**{**BASE, "ox": -56})), (0.85, P(**{**BASE, "ox": 0}))]
    return anim("GUINDASTE · ESQUIVA", 0.85, k, None, "fantasma", [(0, 30, 10), (0.22, 30, 18), (0.85, 30, 10)])


def A_cima():
    k = [(0.0, BASE), (0.1, P(**{**BASE, "lean": 6, "tool": (12, -40, 40), "face": "raiva"})),
         (0.2, P(**{**BASE, "lean": -6, "head": -14, "tool": (8, -60, -88), "face": "raiva"})), (0.45, P(**{**BASE, "lean": -4, "head": -10, "tool": (8, -58, -96)})), (0.85, BASE)]

    def fx(t, p):
        return ab.fx_estrela(8, -104, (t - 0.18) / 0.25, 11) if 0.18 < t < 0.43 else ""
    return anim("GUINDASTE · GOLPE LEVE PARA CIMA", 0.85, k, fx, None, [(0, 30, 10), (0.1, 26, -6), (0.2, 42, 0), (0.45, 40, 2), (0.85, 30, 10)])


def A_baixo():
    air = dict(oy=-40, feet=[(-10, -12), (10, -10)])
    k = [(0.0, P(**{**BASE, **air, "tool": (12, -50, -100), "face": "raiva"})), (0.12, P(**{**BASE, **air, "tool": (12, -40, 80), "face": "raiva"})),
         (0.45, P(**{**BASE, "oy": 0, "tool": (12, -34, 85), "feet": [(-10, 0), (10, 0)], "hip": (0, -31), "sq": (1, 0.9), "face": "raiva"})), (0.9, BASE)]

    def fx(t, p):
        return ab.fx_onda(16, 0, (t - 0.45) / 0.35, 0.9) if 0.45 < t < 0.8 else ""
    return anim("GUINDASTE · GOLPE LEVE PARA BAIXO (no ar)", 0.9, k, fx, None, [(0, 20, 0), (0.12, 40, 0), (0.45, 34, 0), (0.9, 30, 10)])


def A_leva():
    hit = P(**{**BASE, "lean": -22, "head": 24, "sq": (1, 1.04), "ox": -12, "feet": [(-16, -2), (8, 0)], "tool": (10, -34, 140), "face": "dor"})
    k = [(0.0, BASE), (0.06, hit), (0.4, P(**{**hit, "ox": -20})), (0.95, P(**{**BASE, "ox": 0}))]

    def fx(t, p):
        return ab.fx_estrela(10, -66, (t - 0.04) / 0.25, 11) if 0.04 < t < 0.29 else ""
    return anim("GUINDASTE · LEVA GOLPE (o pescoço chicoteia)", 0.95, k, fx, None, [(0, 30, 10), (0.06, 30, 22), (0.95, 30, 10)])


def A_arremessado():
    fly = dict(feet=[(-14, -12), (-2, -20)], tool=(-6, -40, 170), face="susto")
    k = [(0.0, BASE), (0.05, P(**{**BASE, "oy": -6, **fly})), (0.55, P(**{**BASE, "ox": -80, "oy": -46, "rot": -300, **fly})),
         (1.0, P(**{**BASE, "ox": -124, "oy": -16, "rot": -660, **fly})), (1.1, P(**{**BASE, "ox": -128, "oy": -10, "rot": -720, "feet": [(-12, -6), (12, -4)]})),
         (1.2, P(**{**BASE, "ox": -130, "oy": 0, "rot": -720, "hip": (0, -30), "sq": (1, 0.88)})), (1.7, P(**{**BASE, "ox": -132, "rot": -720}))]

    def fx(t, p):
        if t < 0.95:
            return f'<g transform="translate({p["ox"] + 30:.0f},{p["oy"] - 50:.0f})">{ab.fx_lines(0, 0, 4, 26, 1)}</g>'
        return ""
    return anim("GUINDASTE · ARREMESSADO (gira devagar)", 1.7, k, fx, "desloca", [(0, 30, 10), (0.5, 30, 20), (1.2, 30, 14), (1.7, 30, 10)])


def A_engenhoca():
    k = [(0.0, BASE), (0.12, P(**{**BASE, "bk": (14, -50), "lean": 10, "face": "raiva"})), (0.6, P(**{**BASE, "bk": (15, -49), "lean": 10, "face": "raiva"})), (1.0, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="12" y="-60" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="17" cy="-63" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(17, -68, kk, 12) + f'<circle cx="17" cy="-54" r="{8 + kk * 46:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return anim("GUINDASTE · USAR ENGENHOCA", 1.0, k, fx, None, [(0, 30, 10), (1.0, 30, 10)])


def A_vitoria():
    up = P(**{**BASE, "tool": (8, -76, -80), "bk": (-14, -40), "face": "vitoria", "lean": -2})
    k = [(0.0, up), (0.5, P(**{**up, "lean": 8, "head": 10, "oy": -6})), (1.0, P(**{**up, "lean": -8, "head": -10})), (1.5, P(**{**up, "lean": 8, "head": 10, "oy": -6})), (2.0, up)]

    def fx(t, p):
        a = t * 8
        return f'<ellipse cx="8" cy="-110" rx="28" ry="9" fill="none" stroke="#ffffff" stroke-width="4" opacity="0.5"/><rect x="{8 + math.cos(a) * 28 - 6:.1f}" y="{-110 + math.sin(a) * 9 - 4:.1f}" width="12" height="8" rx="2" fill="#f2c84b"/>'
    return anim("GUINDASTE · VITÓRIA (gira o gancho, gingando)", 2.0, k, fx, None, [(0, 2, 0), (2.0, 2, 0)])


def A_eliminado():
    k = [(0.0, P(**{**BASE, "face": "susto"})), (0.14, P(**{**BASE, "face": "eliminado", "sq": (1, 0.9)})),
         (0.2, P(**{**BASE, "oculto": True})), (1.4, P(**{**BASE, "oculto": True}))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:
            r = 20 + 60 * u
            o += f'<circle cx="0" cy="-50" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-50" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, eu.guinda_head(COL, {"face": "eliminado"})), (50, -120, -500, eu.guinda_torso(COL, {})),
                 (70, -80, -800, eu.gancho((0, 0), 90, {"chain_L": 20, "chain_sag": 4})[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -50 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.9)">{svg}</g>'
        return o
    return anim("GUINDASTE · ELIMINADO (desmonta)", 1.4, k, fx, None, [(0, 30, 10)])


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
    if "--resto" in sys.argv:
        run([A_leve, A_pesado, A_duplo, A_parede, A_borda, A_esquiva, A_cima, A_baixo, A_leva, A_arremessado, A_engenhoca, A_vitoria, A_eliminado], "guinda_resto")
        return
    run([A_correr, A_pulo, A_leve, A_pesado], "guinda_lote1")


if __name__ == "__main__":
    main()
