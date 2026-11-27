"""ANIMAÇÕES do GUINDASTE refeito (2026-11-27, opção G2 "LANÇA"): olhão-lente gigante, corpinho de pera, empunha a lança
treliçada do guindaste com o gancho pendurado na ponta. Jeito próprio: calmo e gingado, cutuca de longe (estocada), o gancho
balança atrasado (mola) e o golpe pesado é a lança caindo como um guindaste tombando. Rodar: python3 art/src/robos/anim_guinda.py [--resto]
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
              bk=pose.get("bk"), face=pose.get("face", "foco"), chain_L=pose.get("chain_L", 14), chain_sag=pose.get("chain_sag", 0))
    body = eu.corpo_generico(eu.GUINDA, col, pz)
    sqx, sqy = pose["sq"]
    body = f'<g transform="skewX({pose.get("skew", 0):.2f}) scale({sqx:.3f},{sqy:.3f})">{body}</g>'
    if abs(pose["rot"]) > 0.01:
        body = f'<g transform="rotate({pose["rot"]:.1f} 0 -30)">{body}</g>'
    return body


BASE = P(hip=(0, -24), lean=3, head=0, feet=[(-10, 0), (10, 0)], tool=(10, -22, -60), face="foco")


def anim(nome, dur, keys, fx=None, modo=None, chain=None):
    """chain = [(t, cabo, balanço), …]: comprimento do cabo do gancho e balanço lateral (com mola)."""
    return nome, dur, keys, fx, modo, chain


def chain_at(chain, t):
    if not chain:
        return 14, 0
    if t <= chain[0][0]:
        return chain[0][1], chain[0][2]
    for (t0, l0, s0), (t1, l1, s1) in zip(chain, chain[1:]):
        if t <= t1:
            u = (t - t0) / max(t1 - t0, 1e-6)
            u = u * u * (3 - 2 * u)
            return l0 + (l1 - l0) * u, s0 + (s1 - s0) * u
    return chain[-1][1], chain[-1][2]


def Q(**k):
    return P(**{**BASE, **k})


def ponta(p):
    g, a = p["tool"][:2], math.radians(p["tool"][2])
    return g[0] + math.cos(a) * eu.LANCA_L + p.get("ox", 0), g[1] + math.sin(a) * eu.LANCA_L + p.get("oy", 0)


def A_correr():
    b = dict(lean=12, tool=(12, -24, -30))
    k = [(0.0, Q(hip=(0, -22), head=-4, feet=[(-16, -2), (14, 0)], sq=(1, 0.97), **b)),
         (0.12, Q(hip=(0, -27), head=4, feet=[(-3, -9), (4, -1)], sq=(1, 1.03), **b)),
         (0.24, Q(hip=(0, -22), head=-4, feet=[(14, 0), (-16, -2)], sq=(1, 0.97), **b)),
         (0.36, Q(hip=(0, -27), head=4, feet=[(4, -1), (-3, -9)], sq=(1, 1.03), **b)),
         (0.48, Q(hip=(0, -22), head=-4, feet=[(-16, -2), (14, 0)], sq=(1, 0.97), **b))]

    def fx(t, p):
        off = (t / 0.48 * 140) % 70
        return "".join(f'<path d="M{x - off:.0f},2 h18" stroke="#9ab" stroke-width="3" stroke-linecap="round"/>' for x in range(-140, 180, 70))
    return anim("GUINDASTE · CORRER (ginga, o gancho balança)", 0.48, k, fx, None, [(0, 14, -6), (0.12, 12, -2), (0.24, 14, -6), (0.36, 12, -2), (0.48, 14, -6)])


def A_pulo():
    k = [(0.0, BASE), (0.12, Q(hip=(0, -19), sq=(1, 0.86), lean=10, head=8)),
         (0.2, Q(oy=-18, sq=(1, 1.1), feet=[(-4, -2), (4, 0)])),
         (0.5, Q(oy=-48, head=-8, feet=[(-10, -10), (9, -12)], tool=(10, -26, -40))),
         (0.85, Q(oy=-40, head=-4, feet=[(-9, -10), (10, -7)], tool=(10, -24, -50))),
         (1.15, Q(oy=0)), (1.22, Q(hip=(0, -20), sq=(1, 0.9))), (1.45, BASE)]

    def fx(t, p):
        o = ""
        if 0.12 < t < 0.32:
            o += ab.fx_dust(0, 0, (t - 0.12) / 0.2, 0.7)
        if 1.22 < t < 1.42:
            o += ab.fx_dust(0, 0, (t - 1.22) / 0.2, 0.7)
        return o
    return anim("GUINDASTE · PULAR (flutua · desce devagar)", 1.45, k, fx, None, [(0, 14, 0), (0.2, 8, 0), (0.5, 18, 6), (1.15, 16, -4), (1.45, 14, 0)])


def marca_alcance(x, nome):
    return (f'<path d="M{x},-110 V4" stroke="#d42035" stroke-width="2" stroke-dasharray="6 5" opacity="0.7"/>'
            f'<text x="{x - 46}" y="-100" font-family="Fredoka, Arial" font-weight="700" font-size="9" fill="#d42035">{nome}</text>')


def A_leve():
    prep = Q(lean=-6, head=6, tool=(-2, -24, -8), face="raiva", feet=[(-12, 0), (10, 0)])
    hit = Q(lean=20, head=-4, tool=(20, -26, -4), feet=[(-15, 0), (17, 0)], face="raiva")
    k = [(0.0, BASE), (0.1, prep), (0.17, hit), (0.36, Q(**{**hit, "tool": (18, -26, -6)})), (0.7, BASE)]

    def fx(t, p):
        o = marca_alcance(66, "alcance")
        if 0.15 < t < 0.33:
            x, y = ponta(p)
            o += f'<path d="M{x - 40:.0f},{y:.0f} h34" stroke="#ffffff" stroke-width="8" opacity="0.5" stroke-linecap="round"/>' + ab.fx_estrela(x + 4, y, (t - 0.15) / 0.18, 12)
        return o
    return anim("GUINDASTE · GOLPE LEVE (estocada de longe)", 0.7, k, fx, None, [(0, 14, 0), (0.1, 14, 6), (0.17, 12, -10), (0.36, 13, -4), (0.7, 14, 0)])


def A_pesado():
    sobe = Q(lean=-10, head=-10, tool=(4, -40, -100), face="raiva", feet=[(-12, 0), (11, 0)], hip=(0, -25))
    cai = Q(lean=22, head=-6, tool=(18, -24, 30), feet=[(-17, 0), (19, 0)], face="raiva", hip=(0, -20), sq=(1.04, 0.94))
    k = [(0.0, BASE), (0.2, sobe), (0.9, Q(**{**sobe, "lean": -12, "tool": (2, -42, -104)})), (1.02, cai), (1.4, Q(**{**cai, "sq": (1, 1)})), (1.9, BASE)]

    def fx(t, p):
        o = marca_alcance(66, "alcance")
        if 0.2 < t < 0.96:   # carregando: a lança treme e brilha
            kk = min((t - 0.2) / 0.7, 1)
            x, y = ponta(p)
            o += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{6 + 10 * kk:.0f}" fill="#ffe27a" opacity="{0.25 + 0.4 * kk:.2f}"/>'
        if 0.98 < t < 1.5:
            kk = (t - 0.98) / 0.52
            x, y = ponta(p)
            o += f'<path d="M4,-70 Q{x - 10:.0f},{-80:.0f} {x:.0f},{y:.0f}" stroke="#ffffff" stroke-width="{10 * (1 - kk):.1f}" fill="none" opacity="0.5" stroke-linecap="round"/>' if kk < 0.4 else ""
            o += ab.fx_estrela(x, y, kk, 20) if kk < 0.45 else ""
            o += f'<g transform="translate({x:.0f},0)">{ab.fx_onda(0, 0, kk, 1.0)}</g>'
        return o
    return anim("GUINDASTE · GOLPE PESADO (a lança tomba como guindaste)", 1.9, k, fx, None, [(0, 14, 0), (0.2, 10, 8), (0.9, 10, -8), (1.02, 24, 0), (1.4, 18, 6), (1.9, 14, 0)])


def A_duplo():
    air = dict(feet=[(-10, -10), (9, -12)], tool=(10, -26, -40))
    tuck = dict(feet=[(-5, -16), (5, -14)], tool=(8, -26, -80), hip=(0, -22))
    k = [(0.0, Q(oy=-18, **air)), (0.1, Q(oy=-22, sq=(1, 1.06), feet=[(-4, -2), (4, 0)], tool=(10, -26, -40))),
         (0.45, Q(oy=-34, rot=360, face="raiva", **tuck)), (0.7, Q(oy=-34, rot=360, **air)),
         (1.1, Q(oy=0, rot=360)), (1.17, Q(rot=360, hip=(0, -20), sq=(1, 0.9))), (1.4, Q(rot=360))]

    def fx(t, p):
        return f'<circle cx="0" cy="-30" r="{6 + 30 * (t - 0.06):.0f}" fill="#fff6e4" opacity="{0.7 - (t - 0.06) * 4:.2f}"/>' if 0.06 < t < 0.22 else ""
    return anim("GUINDASTE · PULO DUPLO (giro com a lança)", 1.4, k, fx, None, [(0, 16, 4), (0.45, 6, 0), (0.8, 16, 8), (1.4, 14, 0)])


def A_parede():
    wall = dict(lean=-4, head=10, feet=[(-12, -8), (-2, -2)], tool=(10, -26, -70))
    k = [(0.0, Q(ox=-22, oy=-34, **wall)), (0.9, Q(ox=-22, oy=-10, **wall)),
         (1.0, Q(ox=-20, oy=-12, hip=(0, -20), sq=(1, 0.9), lean=-10, feet=[(-10, -2), (-5, 0)], tool=(10, -26, -70))),
         (1.5, Q(ox=50, oy=-40, lean=16, feet=[(-10, -10), (9, -12)], tool=(12, -26, -30), face="raiva"))]

    def fx(t, p):
        return '<rect x="-70" y="-200" width="34" height="210" fill="#d9a35f"/><rect x="-42" y="-200" width="6" height="210" fill="#b57a3e"/>'
    return anim("GUINDASTE · PAREDE (desliza · salta)", 1.5, k, fx, None, [(0, 14, -4), (0.9, 14, 4), (1.5, 14, -6)])


def A_borda():
    hang = dict(hip=(0, -24), lean=0, head=-8, feet=[(-3, -4), (4, -2)], tool=(8, -36, -88), face="susto", sem_gancho=True)
    k = [(0.0, Q(oy=30, **hang)), (0.5, Q(oy=30, **{**hang, "feet": [(-7, -2), (7, -6)]})), (0.9, Q(oy=30, **hang)),
         (1.2, Q(ox=10, oy=-26, lean=20, feet=[(-4, -10), (12, -2)], tool=(12, -24, -40), face="raiva", sq=(1, 0.92))),
         (1.6, Q(ox=40, oy=-36))]

    def fx(t, p):
        o = '<rect x="24" y="-40" width="210" height="44" fill="#cfc6b4"/><rect x="24" y="-40" width="210" height="8" fill="#e8e0d0"/>'
        if t < 1.0:   # o gancho preso na quina da borda
            x, y = ponta(p)
            o += eu.gancho_ponta(x, y, max(-40 - y, 2), 0)
        return o
    return anim("GUINDASTE · BORDA (engancha a lança · sobe)", 1.6, k, fx, None, [(0, 14, 0), (1.6, 14, 0)])


def A_esquiva():
    low = Q(hip=(0, -19), lean=-20, head=14, sq=(1.04, 0.92), tool=(6, -20, -110), face="susto", feet=[(-16, 0), (7, 0)])
    k = [(0.0, BASE), (0.05, low), (0.22, P(**{**low, "ox": -56})), (0.45, Q(ox=-56)), (0.85, Q(ox=0))]
    return anim("GUINDASTE · ESQUIVA", 0.85, k, None, "fantasma", [(0, 14, 0), (0.22, 14, 12), (0.85, 14, 0)])


def A_cima():
    k = [(0.0, BASE), (0.1, Q(lean=4, tool=(10, -18, -40), face="raiva")),
         (0.18, Q(lean=-6, head=-14, tool=(6, -34, -90), face="raiva")), (0.42, Q(lean=-4, head=-10, tool=(6, -32, -92))), (0.8, BASE)]

    def fx(t, p):
        x, y = ponta(p)
        return ab.fx_estrela(x, y - 6, (t - 0.16) / 0.25, 11) if 0.16 < t < 0.41 else ""
    return anim("GUINDASTE · GOLPE LEVE PARA CIMA (estocada no alto)", 0.8, k, fx, None, [(0, 14, 0), (0.18, 6, 0), (0.42, 8, 0), (0.8, 14, 0)])


def A_baixo():
    air = dict(oy=-44, feet=[(-9, -10), (9, -8)])
    k = [(0.0, Q(tool=(10, -30, -80), face="raiva", **air)), (0.12, Q(tool=(10, -18, 85), face="raiva", **air)),
         (0.42, Q(oy=0, tool=(10, -18, 88), hip=(0, -20), sq=(1, 0.9), face="raiva")), (0.85, BASE)]

    def fx(t, p):
        return ab.fx_onda(12, 0, (t - 0.42) / 0.35, 0.9) if 0.42 < t < 0.77 else ""
    return anim("GUINDASTE · GOLPE LEVE PARA BAIXO (no ar, espeta o chão)", 0.85, k, fx, None, [(0, 14, 0), (0.12, 4, 0), (0.42, 4, 0), (0.85, 14, 0)])


def A_leva():
    hit = Q(lean=-22, head=24, sq=(1, 1.04), ox=-12, feet=[(-14, -2), (7, 0)], tool=(6, -24, -110), face="dor")
    k = [(0.0, BASE), (0.06, hit), (0.4, P(**{**hit, "ox": -20})), (0.95, Q(ox=0))]

    def fx(t, p):
        return ab.fx_estrela(10, -50, (t - 0.04) / 0.25, 11) if 0.04 < t < 0.29 else ""
    return anim("GUINDASTE · LEVA GOLPE (o olhão arregala)", 0.95, k, fx, None, [(0, 14, 0), (0.06, 14, 16), (0.95, 14, 0)])


def A_arremessado():
    fly = dict(feet=[(-12, -10), (-2, -16)], tool=(-4, -28, -150), face="susto")
    k = [(0.0, BASE), (0.05, Q(oy=-6, **fly)), (0.55, Q(ox=-80, oy=-46, rot=-300, **fly)),
         (1.0, Q(ox=-124, oy=-16, rot=-660, **fly)), (1.1, Q(ox=-128, oy=-10, rot=-720, feet=[(-10, -6), (10, -4)])),
         (1.2, Q(ox=-130, oy=0, rot=-720, hip=(0, -19), sq=(1, 0.88))), (1.7, Q(ox=-132, rot=-720))]

    def fx(t, p):
        if t < 0.95:
            return f'<g transform="translate({p["ox"] + 30:.0f},{p["oy"] - 50:.0f})">{ab.fx_lines(0, 0, 4, 26, 1)}</g>'
        return ""
    return anim("GUINDASTE · ARREMESSADO (gira)", 1.7, k, fx, "desloca", [(0, 14, 0), (0.5, 14, 14), (1.2, 14, -8), (1.7, 14, 0)])


def A_engenhoca():
    k = [(0.0, BASE), (0.12, Q(bk=(14, -40), lean=10, face="raiva")), (0.6, Q(bk=(15, -39), lean=10, face="raiva")), (1.0, BASE)]

    def fx(t, p):
        if 0.12 < t < 0.6:
            kk = (t - 0.12) / 0.48
            return (f'<rect x="12" y="-50" width="10" height="13" rx="3" fill="#3a3f4a"/><circle cx="17" cy="-53" r="2.6" fill="#d42035"/>'
                    + ab.fx_estrela(17, -58, kk, 12) + f'<circle cx="17" cy="-44" r="{8 + kk * 46:.0f}" fill="none" stroke="#ffe27a" stroke-width="3" opacity="{1 - kk:.2f}"/>')
        return ""
    return anim("GUINDASTE · USAR ENGENHOCA", 1.0, k, fx, None, [(0, 14, 0), (1.0, 14, 0)])


def A_vitoria():
    up = Q(tool=(6, -36, -88), bk=(-12, -30), face="vitoria", lean=-2)
    k = [(0.0, up), (0.5, P(**{**up, "lean": 8, "head": 10, "oy": -6})), (1.0, P(**{**up, "lean": -8, "head": -10})), (1.5, P(**{**up, "lean": 8, "head": 10, "oy": -6})), (2.0, up)]
    return anim("GUINDASTE · VITÓRIA (ergue a lança, o gancho balança)", 2.0, k, None, None, [(0, 14, -10), (0.5, 14, 10), (1.0, 14, -10), (1.5, 14, 10), (2.0, 14, -10)])


def A_eliminado():
    k = [(0.0, Q(face="susto")), (0.14, Q(face="eliminado", sq=(1, 0.9))), (0.2, Q(oculto=True)), (1.4, Q(oculto=True))]

    def fx(t, p):
        if t < 0.2:
            return ""
        u = (t - 0.2) / 1.2
        o = ""
        if u < 0.35:
            r = 20 + 60 * u
            o += f'<circle cx="0" cy="-40" r="{r:.0f}" fill="#ffd27a" opacity="{1 - u / 0.35:.2f}"/><circle cx="0" cy="-40" r="{r * 0.6:.0f}" fill="#ffffff" opacity="{1 - u / 0.35:.2f}"/>'
        pecas = [(-60, -160, 400, eu.guinda_head(COL, {"face": "eliminado"})), (50, -120, -500, eu.guinda_torso(COL, {})),
                 (70, -80, -800, eu.lanca((0, 0), 0, {"chain_L": 10})[0])]
        for vx, vy, spin, svg in pecas:
            x = vx * u * 1.6
            y = -40 + vy * u * 1.6 + 260 * u * u
            o += f'<g transform="translate({x:.1f},{y:.1f}) rotate({spin * u:.0f}) scale(0.9)">{svg}</g>'
        return o
    return anim("GUINDASTE · ELIMINADO (desmonta)", 1.4, k, fx, None, [(0, 14, 0)])


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
        m = ab.Mola(0, 4.0, 0.35)
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
