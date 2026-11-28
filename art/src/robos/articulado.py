"""PRANCHA para aprovar — robôs ARTICULADOS e expressivos (etapa 2 da avaliação de gameplay, 2026-11-26).
Pedido do usuário: animações "pouco articuladas, sem gosto de usar os golpes". No tamanho do jogo (~80 px) articulação
lê por SILHUETA e POSE, não por juntas pequenas. Proposta, mantendo o papel e giz aprovado:
  · tronco em 2 peças (peito + quadril/cinto) com dobra na cintura; pescoço com atraso da cabeça;
  · juntas visíveis (ombro, cotovelo, quadril, joelho = parafusos), membros ~35% mais grossos, mãos e botas maiores;
  · sobrancelha em todo rosto (expressão lê a 1x); corpo que achata/estica (squash/stretch);
  · poses-chave com LINHA DE AÇÃO forte e rastro (smear) da ferramenta.
Rodar: python3 art/src/robos/articulado.py → art/out/robos_v2/r1_articulado.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import elenco as el  # noqa: E402
from elenco import CHARS, POSES, COLORS, INK, add, rot, ik, limb, glove, boot, fx_draw, label, S, face_eye  # noqa: E402
from papel import ellipse_d  # noqa: E402
from svg import queue, render_all, shade  # noqa: E402

ROOT = el.ROOT
OUT = os.path.join(ROOT, "art/out/robos_v2")
SRC = os.path.join(ROOT, "art/src/robos/svg")

# Proporções novas (multiplicadores sobre o CHARS aprovado): legibilidade a 1x.
V2 = dict(limb_w=1.35, hand=1.3, boot=1.2, head=1.18)


def junta(p, r, col):
    """Parafuso da junta: disco na cor do membro um pouco mais escura + brilho."""
    return (f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="{r:.2f}" fill="{shade(col, 0.18)}"/>'
            + f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="{r * 0.45:.2f}" fill="{shade(col, -0.35)}"/>')


def sobrancelha(cid, e):
    """Sobrancelha por cima do rosto (no espaço da cabeça): brava, susto (alta), triste/eliminado, normal leve."""
    eye = {"marretao": (10, 3.0), "picareta": (7, -25.5)}.get(cid, (6, -16))
    x, y = eye
    if e in ("ataque", "forca", "grito", "esforco"):
        return f'<path d="M{x - 6},{y - 1.5} L{x + 5},{y + 1.8}" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>'
    if e in ("susto", "esquiva"):
        return f'<path d="M{x - 5},{y - 2.5} Q{x},{y - 6} {x + 5},{y - 3}" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
    if e in ("dor", "eliminado"):
        return f'<path d="M{x - 5},{y + 1.5} L{x + 5},{y - 2}" stroke="{INK}" stroke-width="1.8" stroke-linecap="round"/>'
    if e == "vitoria":
        return f'<path d="M{x - 5},{y - 3} Q{x},{y - 5.5} {x + 5},{y - 3}" stroke="{INK}" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
    return f'<path d="M{x - 4.5},{y - 1.5} L{x + 4.5},{y - 2}" stroke="{INK}" stroke-width="1.5" stroke-linecap="round"/>'


def draw2(cid, pose, col):
    """Desenho articulado. pose: lean (quadril), bend (peito além do quadril), head (atraso da cabeça), dx, dy,
    feet=[(x,y,ang)…], tool=(x,y,a), face, sq=(sx,sy) achata/estica, smear=[ângulos antigos da ferramenta]."""
    ch = CHARS[cid]
    limbc = shade(col, -0.45)
    limbb = shade(col, -0.6)
    lean = pose.get("lean", 0)
    bend = pose.get("bend", 0)
    hip = (pose.get("dx", 0), -ch["hip_h"] + pose.get("dy", 0))
    waist = (0, -ch["hip_h"] * 0.45 if cid != "picareta" else -14)
    T_hip = lambda p: add(rot(p, lean), hip)  # noqa: E731
    w_world = T_hip(waist)
    T_chest = lambda p: add(rot((p[0] - waist[0], p[1] - waist[1]), lean + bend), w_world)  # noqa: E731
    e = pose.get("face", "")
    G = pose["tool"][:2]
    A = pose["tool"][2]
    grips = [add(G, rot(g, A)) for g in ch["grips"]]
    P = {k: "" for k in ("fx_back", "smear", "back_arm", "back_leg", "torso", "front_leg", "tool", "back_hand", "front_arm")}
    # pernas (mais grossas, joelho com parafuso, bota maior inclinável)
    a, b, w = ch["leg"]
    w *= V2["limb_w"]
    for side, key in (("b", "back_leg"), ("f", "front_leg")):
        hp = T_hip(ch["hip_" + side])
        ft = pose["feet"][0 if side == "b" else 1]
        fang = ft[2] if len(ft) > 2 else 0
        tgt = (ft[0], ft[1] - 3)
        knee, end = ik(hp, tgt, a, b, (lambda q: q[0]) if ch["knee"] > 0 else (lambda q: -q[0]))
        lc = limbb if side == "b" else limbc
        bw, bh = ch["boot"][0] * V2["boot"], ch["boot"][1] * V2["boot"]
        bt = boot((0, 0), bw, bh, shade(col, -0.55) if side == "b" else shade(col, -0.4))
        P[key] = (limb(hp, knee, w, lc) + limb(knee, end, w * 0.9, lc) + junta(knee, w * 0.42, lc)
                  + f'<g transform="translate({end[0]:.1f},{end[1] + 3:.1f}) rotate({fang})">{bt}</g>')
    # quadril (cinto) + peito dobrando na cintura + cabeça no pescoço (com atraso)
    sx, sy = pose.get("sq", (1.0, 1.0))
    hc = shade(col, -0.25)
    pelvis = (f'<g transform="translate({hip[0]:.2f},{hip[1]:.2f}) rotate({lean:.2f})">'
              + S(f"M{-ch['hip_h'] * 0.42 - 4},-2 L{ch['hip_h'] * 0.42 + 4},-2 L{ch['hip_h'] * 0.38 + 3},{waist[1] + 3} L{-ch['hip_h'] * 0.38 - 3},{waist[1] + 3} Z", hc,
                  (-30, waist[1], 30, 2), k=0.5)
              + f'<rect x="{-ch["hip_h"] * 0.42 - 4}" y="{waist[1] + 1}" width="{ch["hip_h"] * 0.84 + 8}" height="3.5" rx="1.5" fill="{INK}" opacity="0.55"/></g>')
    chest_tf = f'translate({w_world[0]:.2f},{w_world[1]:.2f}) rotate({lean + bend:.2f}) translate({-waist[0]},{-waist[1]})'
    ha = ch["head_at"]
    hs = V2["head"]
    head = (f'<g transform="translate({ha[0]},{ha[1]}) rotate({pose.get("head", 0)}) scale({hs})">{ch["head"](col, e, "all")}'
            f'{sobrancelha(cid, e)}</g>')
    neck = f'<path d="M{ha[0] - 1},{ha[1] + 4} L{ha[0]},{ha[1] - 2}" stroke="{limbc}" stroke-width="5" stroke-linecap="round"/>' if cid != "picareta" else ""
    P["torso"] = pelvis + f'<g transform="{chest_tf} translate(0,0) scale({sx},{sy})">{ch["torso"](col, e)}{neck}{head}</g>'
    # braços (mais grossos, ombro e cotovelo com parafuso, luvas maiores)
    a, b, w = ch["arm"]
    w *= V2["limb_w"]
    hand = ch["hand"] * V2["hand"]
    elbow_pref = lambda q: q[1]  # noqa: E731
    shb = T_chest(ch["sh_b"])
    el_, end = ik(shb, grips[1], a, b, elbow_pref)
    P["back_arm"] = limb(shb, el_, w, limbb) + limb(el_, end, w * 0.9, limbb) + junta(el_, w * 0.4, limbb)
    P["back_hand"] = glove(end, hand, back=True)
    shf = T_chest(ch["sh_f"])
    el_, end = ik(shf, grips[0], a, b, elbow_pref)
    P["front_arm"] = (junta(shf, w * 0.6, limbc) + limb(shf, el_, w, limbc) + limb(el_, end, w * 0.9, limbc)
                      + junta(el_, w * 0.4, limbc) + glove(end, hand * 1.05))
    # rastro (smear): cópias da ferramenta nos ângulos anteriores, cada vez mais apagadas
    for i, sa in enumerate(pose.get("smear", [])):
        op = 0.38 - i * 0.1
        P["smear"] += f'<g opacity="{max(op, 0.08):.2f}" transform="translate({G[0]:.2f},{G[1]:.2f}) rotate({sa:.2f})">{_tool_silhueta(cid)}</g>'
    P["tool"] = f'<g transform="translate({G[0]:.2f},{G[1]:.2f}) rotate({A:.2f})">{ch["tool"]()}</g>'
    order = ["fx_back", "smear", "back_arm", "back_leg", "torso", "front_leg", "tool", "back_hand", "front_arm"]
    body = "".join(P[k] for k in order)
    if pose.get("spin"):
        cx, cy = pose.get("spin_c", (0, -30))
        body = f'<g transform="rotate({pose["spin"]} {cx} {cy})">{body}</g>'
    if pose.get("stretch"):   # corpo inteiro esticado no sentido do movimento (arremesso/impacto)
        k = pose["stretch"]
        body = f'<g transform="translate(0,-36) scale({1 + k},{1 - k * 0.6}) translate(0,36)">{body}</g>'
    return fx_draw(pose.get("fx_b", []), True) + body + fx_draw(pose.get("fx", []), False)


def _tool_silhueta(cid):
    """Silhueta branca da ferramenta para o rastro."""
    return {"marretao": '<rect x="-16" y="-2.5" width="52" height="5" fill="#ffffff"/><rect x="34" y="-12" width="17" height="24" rx="3" fill="#ffffff"/>',
            "picareta": '<rect x="-16" y="-2" width="50" height="4" fill="#ffffff"/><path d="M33,-3 C40,-6 48,-13 52,-22 C50,-12 44,-4 37,1 L37,4 C44,8 50,16 52,26 C46,17 40,10 33,6 Z" fill="#ffffff"/>'}.get(cid, "")


# Poses-chave novas (o golpe inteiro, não só 2 quadros). Unidades = px de jogo.
KEYS = {
    "marretao": [
        ("PARADO (respira)", dict(lean=4, bend=2, feet=[(-12, 0), (12, 0)], tool=(18, -34, 52))),
        ("CORRE (contato)", dict(lean=14, bend=6, dy=-2, head=-4, feet=[(-20, -6, -20), (18, 0, 10)], tool=(-2, -58, -150), face="esforco")),
        ("LEVE: ANTECIPA", dict(lean=-6, bend=-10, dy=3, head=6, feet=[(-14, 0), (13, 0)], tool=(2, -60, -110), face="ataque")),
        ("LEVE: IMPACTO", dict(lean=18, bend=14, dy=3, head=-6, feet=[(-16, 0), (20, 0, 8)], tool=(32, -40, 10), face="ataque",
                               smear=[-40, -75], fx=[("linhas", 60, -58, 3, 14, -1)])),
        ("PESADO: CARREGA", dict(lean=-22, bend=-16, dy=9, head=10, sq=(1.08, 0.92), feet=[(-19, 0, -6), (14, 0)], tool=(-14, -70, -135), face="forca",
                                 fx_b=[("poeira", -8, 0, 0.7)])),
        ("PESADO: SOLTA", dict(lean=34, bend=18, dy=12, head=-10, feet=[(-20, 0, -14), (22, 0, 6)], tool=(34, -26, 76), face="grito",
                               smear=[30, -20, -70, -115], fx=[("onda", 54, 0, 34), ("estrela", 54, -4, 15), ("pedras", 54, 0)])),
        ("PESADO: CONTINUA", dict(lean=26, bend=8, dy=10, head=4, feet=[(-18, 0), (20, 0)], tool=(30, -12, 96), face="esforco")),
        ("LEVA GOLPE", dict(lean=-24, bend=-14, dy=2, dx=-6, head=18, sq=(0.86, 1.1), feet=[(-14, -4, -18), (6, 0)], tool=(4, -40, -160), face="dor",
                            fx=[("estrela", 22, -46, 10)])),
        ("ARREMESSADO", dict(lean=-10, bend=-8, dy=-20, head=20, stretch=0.22, spin=-38, spin_c=(0, -40), feet=[(-22, -14), (-6, -24)], tool=(-14, -66, -170),
                             face="susto", fx_b=[("linhas", -70, -64, 4, 20, 1)])),
    ],
    "picareta": [
        ("PARADO (respira)", dict(lean=6, bend=2, feet=[(-8, 0), (10, 0)], tool=(14, -52, -72), head=4)),
        ("CORRE (contato)", dict(lean=22, bend=8, dy=-2, head=-6, feet=[(-26, -4, -25), (22, 0, 8)], tool=(-6, -56, -160), face="esforco")),
        ("LEVE: ANTECIPA", dict(lean=-6, bend=-8, dy=4, head=8, feet=[(-12, 0), (14, 0)], tool=(-4, -48, -10), face="ataque")),
        ("LEVE: IMPACTO", dict(lean=30, bend=14, dy=8, head=-8, feet=[(-26, 0, -10), (30, 0, 6)], tool=(44, -46, -4), face="ataque",
                               smear=[-6, -8], fx=[("linhas", 80, -58, 3, 18, -1)])),
        ("PESADO: CARREGA", dict(lean=-18, bend=-14, dy=-4, head=-14, sq=(0.94, 1.08), feet=[(-6, 0, -10), (8, 0)], tool=(-8, -104, -108), face="forca")),
        ("PESADO: SOLTA", dict(lean=46, bend=16, dy=14, head=-10, feet=[(-22, 0, -16), (30, 0, 8)], tool=(48, -30, 80), face="grito",
                               smear=[30, -20, -70, -100], fx=[("estrela", 56, 2, 14), ("pedras", 56, 0)])),
        ("PESADO: CONTINUA", dict(lean=40, bend=10, dy=14, head=2, feet=[(-20, 0), (28, 0)], tool=(44, -16, 96), face="esforco")),
        ("LEVA GOLPE", dict(lean=-24, bend=-14, dx=-8, head=22, sq=(0.86, 1.1), feet=[(-14, -6, -18), (4, 0)], tool=(0, -58, -150), face="dor",
                            fx=[("estrela", 18, -60, 10)])),
        ("ARREMESSADO", dict(lean=-8, dy=-26, head=22, stretch=0.22, spin=-36, spin_c=(0, -46), feet=[(-24, -16), (-8, -28)], tool=(-10, -80, -170),
                             face="susto", fx_b=[("linhas", -70, -74, 4, 20, 1)])),
    ],
}
HOJE = [("PARADO", "parado"), ("GOLPE RÁPIDO", "rapido"), ("PESADO: PREPARO", "pesado_prep"), ("PESADO: IMPACTO", "pesado_golpe")]


def notes(y0, W, items):
    b = [f'<rect x="0" y="{y0}" width="{W}" height="260" fill="#f4ecd8"/><rect x="0" y="{y0}" width="{W}" height="8" fill="{INK}"/>']
    b.append(label(40, y0 + 52, "ROBÔS ARTICULADOS — proposta da etapa 2 (arte antes do código)", 30, INK, "start"))
    colr = {"PROPOSTA": "#e08a1e", "DECIDIR": "#c23a5a"}
    for i, (tag, txt) in enumerate(items):
        x, y = 30 + (i % 2) * 950, y0 + 100 + (i // 2) * 46
        b.append(f'<rect x="{x}" y="{y - 26}" width="128" height="36" rx="10" fill="{colr[tag]}"/>' + label(x + 64, y - 1, tag, 18, "#ffffff"))
        b.append(label(x + 140, y, txt, 19, INK, "start", 600))
    return "".join(b)


def prancha():
    W = 1920
    rows = []
    b = [f'<rect width="{W}" height="2000" fill="#9fe2ec"/>',
         label(W / 2, 60, "ROBÔS ARTICULADOS — HOJE × PROPOSTA (mesmo papel e giz)", 40)]
    y = 100
    for i, cid in enumerate(["marretao", "picareta"]):
        col = COLORS[i]
        nm = CHARS[cid]["nome"]
        # HOJE (4 quadros, escala menor) — referência
        b.append(f'<rect x="20" y="{y}" width="{W - 40}" height="250" rx="22" fill="#ffffff" opacity="0.28"/>')
        b.append(label(40, y + 44, f"{nm} · HOJE", 28, "#6b5a70", "start"))
        for j, (lab, pk) in enumerate(HOJE):
            cx = 420 + j * 300
            gy = y + 220
            b.append(f'<path d="M{cx - 110},{gy} H{cx + 110}" stroke="#7fb8c4" stroke-width="4"/>')
            b.append(f'<g transform="translate({cx - 10},{gy}) scale(1.75)">{el.draw(cid, POSES[cid][pk], col)}</g>')
            b.append(label(cx, y + 244, lab, 16, "#2a4a58"))
        # tamanho real HOJE × PROPOSTA (1x)
        gx = 1640
        b.append(label(gx + 110, y + 44, "TAMANHO DE JOGO (1x)", 18, "#2a4a58"))
        b.append(f'<rect x="{gx}" y="{y + 160}" width="240" height="8" fill="#c9b99a"/>')
        b.append(f'<g transform="translate({gx + 60},{y + 160})">{el.draw(cid, POSES[cid]["pesado_golpe"], col)}</g>')
        b.append(f'<g transform="translate({gx + 170},{y + 160})">{draw2(cid, KEYS[cid][5][1], col)}</g>')
        b.append(label(gx + 60, y + 196, "hoje", 16, "#6b5a70") + label(gx + 170, y + 196, "proposta", 16, INK))
        y += 270
        # PROPOSTA (9 poses-chave)
        b.append(f'<rect x="20" y="{y}" width="{W - 40}" height="680" rx="22" fill="#ffffff" opacity="0.45"/>')
        b.append(label(40, y + 44, f"{nm} · PROPOSTA (poses-chave do golpe inteiro)", 30, INK, "start"))
        for j, (lab, pose) in enumerate(KEYS[cid]):
            row, colk = j // 5, j % 5
            cx = 200 + colk * 370 + (185 if row == 1 else 0)
            gy = y + 320 + row * 320
            b.append(f'<path d="M{cx - 140},{gy} H{cx + 140}" stroke="#7fb8c4" stroke-width="5" stroke-linecap="round"/>')
            b.append(f'<g transform="translate({cx - 14},{gy}) scale(2.15)">{draw2(cid, pose, col)}</g>')
            b.append(label(cx, gy + 30, lab, 18, "#2a4a58"))
        y += 700
    H = y + 10
    b[0] = f'<rect width="{W}" height="{H + 260}" fill="#9fe2ec"/>'
    b.append(notes(H, W, [
        ("PROPOSTA", "Tronco em 2 peças (peito + quadril) dobrando na cintura; cabeça no pescoço com atraso."),
        ("PROPOSTA", "Juntas visíveis (parafusos) e membros ~35% mais grossos: lê a 1x."),
        ("PROPOSTA", "Mãos e botas maiores; sobrancelha em todo rosto (raiva, susto, dor)."),
        ("PROPOSTA", "Golpe em 3 tempos: antecipa → solta (rastro da ferramenta) → continua."),
        ("PROPOSTA", "Corpo achata ao carregar e estica no arremesso (squash/stretch)."),
        ("DECIDIR", "Aplicar nos 5 robôs assim? (depois vêm as mecânicas e as animações no jogo)"),
    ]))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H + 260}" viewBox="0 0 {W} {H + 260}">{"".join(b)}</svg>', H + 260


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    svg, h = prancha()
    queue(svg, f"{SRC}/r1_articulado.svg", os.path.join(OUT, "r1_articulado.png"), 1920, h, 1)
    print("articulado:", render_all())


if __name__ == "__main__":
    main()
