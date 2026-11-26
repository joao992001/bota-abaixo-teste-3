"""FOTOGRAFIA CONCEITUAL da cena 3 do Canteiro — FACHADA (Rota Moderada), para aprovar antes do código.
Ficha: docs/fases/derruba/f1_canteiro/cenas/fachada.md. Mesmo estilo e peças da prancha da Fase 1 (fase1_prancha.py).
Luta pendurada nos andaimes da frente do prédio, fim de tarde; cair na rua = KO. Tela de jogo 40×22 tiles.
Rodar: python3 art/src/cenarios/fase1_fachada.py → art/out/fase1_fachada.png
      python3 art/src/cenarios/fase1_fachada.py --jogo → art/out/game/fase1/e3_longe.png, e3_palco.png (camadas da cena 3)
"""
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import fase1_prancha as fp  # noqa: E402
from fase1_prancha import INK, ORANGE, YEL, YEL_D, R, T, W, H, cd, el, lattice, cloud, npc, robot, escada  # noqa: E402
from papel import rough  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = fp.ROOT
TUBO = "#e0883a"
MONT = [4, 10, 16, 22, 28, 34]                 # montantes do andaime (tiles) → 5 vãos
LV = {"L4": 6, "L3": 10, "L2": 14, "L1": 18}  # topo das pranchas (linha em tiles)
# vãos com prancha por andar (índice do vão 0..4)
PRANCHAS = {"L4": [2, 3], "L3": [0, 1, 3, 4], "L2": [1, 2, 3], "L1": [0, 1, 3, 4]}
CEDE = ("L2", 3)                                # M13: trecho com fita zebrada (vai ceder)
STREET = 20 * T + 30


def sky():
    b = ['<defs><linearGradient id="skf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3b07f"/>'
         '<stop offset="0.55" stop-color="#f7cf98"/><stop offset="1" stop-color="#fbe3bd"/></linearGradient>'
         '<radialGradient id="sunf"><stop offset="0" stop-color="#fff1c6"/><stop offset="1" stop-color="#fff1c6" stop-opacity="0"/></radialGradient></defs>',
         f'<rect width="{W}" height="{H}" fill="url(#skf)"/>', f'<circle cx="2330" cy="560" r="320" fill="url(#sunf)"/>',
         '<circle cx="2330" cy="560" r="80" fill="#ffe7b0"/>']
    for (cx, cy, s) in ((300, 160, 1.0), (1250, 90, 0.7), (2050, 200, 0.9)):
        b.append(cloud(cx, cy, s, "#fbe6d2"))
    for (x, y) in ((620, 260), (650, 248), (684, 268)):
        b.append(f'<path d="M{x - 10},{y} q5,-7 10,0 q5,-7 10,0" stroke="#8a6a6a" stroke-width="3" fill="none"/>')
    return "".join(b)


def city():
    rnd = random.Random(7)
    b = []
    for (x0, x1) in ((-20, 3 * T), (35 * T, W + 20)):
        x = x0
        while x < x1:
            bw, bh = rnd.uniform(70, 150), rnd.uniform(380, 760)
            top = STREET - bh
            b.append(f'<rect x="{x:.0f}" y="{top:.0f}" width="{bw:.0f}" height="{bh + 200:.0f}" fill="#c79a9e"/>')
            for wy in range(int(top + 20), int(STREET - 40), 32):
                for wx in range(int(x + 12), int(x + bw - 14), 24):
                    if rnd.random() < 0.55:
                        b.append(f'<rect x="{wx}" y="{wy}" width="10" height="14" fill="{"#ffe2a8" if rnd.random() < 0.35 else "#d8b4b2"}"/>')
            x += bw + rnd.uniform(10, 30)
    return "".join(b)


def grua():
    x = 37 * T
    b = [lattice(x, H, x, 60, 34, YEL, 5), lattice(x + 300, 70, 13 * T, 70, 26, YEL, 5)]
    b.append(f'<rect x="{x - 60}" y="40" width="120" height="70" fill="{YEL_D}"/>')   # cabine
    b.append(f'<rect x="{x - 40}" y="54" width="44" height="30" fill="#bfe0ea"/>')
    b.append(f'<path d="M{18 * T},84 V250" stroke="#4a4f5c" stroke-width="4"/>')
    b.append(f'<path d="M{18 * T - 16},250 h32 l-8,26 h-16z" fill="#6b7783"/><path d="M{18 * T},276 q14,10 0,24" stroke="#6b7783" stroke-width="6" fill="none"/>')
    return "".join(b)


def fachada():
    """Parede do prédio (BASE FIXA): concreto, lajes dos andares, janelas acesas, operários olhando."""
    x0, x1 = 3 * T, 35 * T
    b = [R(x0, 3 * T, x1 - x0, STREET - 3 * T, "#dccfb8", 0, 3, dark="#b9ab8f")]
    b.append(f'<rect x="{x0}" y="{3 * T}" width="{x1 - x0}" height="16" fill="#efe4cf"/>')
    rnd = random.Random(3)
    for fl, ytop in enumerate((3 * T + 30, 7 * T, 11 * T, 15 * T)):
        b.append(f'<rect x="{x0}" y="{ytop + 3 * T - 26}" width="{x1 - x0}" height="20" fill="#c9bba1"/>')   # borda da laje
        for k in range(16):
            wx = x0 + 40 + k * 124
            lit = rnd.random() < 0.3
            b.append(f'<rect x="{wx}" y="{ytop + 40}" width="70" height="{3 * T - 110}" rx="4" fill="{"#ffd98f" if lit else "#7f6f84"}"/>')
            b.append(f'<rect x="{wx + 33}" y="{ytop + 40}" width="4" height="{3 * T - 110}" fill="#5e5066" opacity="0.6"/>')
            if lit and rnd.random() < 0.5:
                b.append(npc(wx + 35, ytop + 3 * T - 70, "#8a7f96", "", 0.7))
    b.append(f'<rect x="{x0 + 220}" y="{4 * T}" width="300" height="70" fill="#5fae6a" opacity="0.35"/>')
    return "".join(b)


def rua():
    """Rua lá embaixo: cair aqui = KO (abismo de vários andares, carros pequenos, cones)."""
    b = [f'<rect x="0" y="{STREET}" width="{W}" height="{H - STREET}" fill="#6b7586"/>',
         f'<rect x="0" y="{STREET}" width="{W}" height="14" fill="#8d97a6"/>']
    for k in range(14):
        b.append(f'<rect x="{k * 190 + 30}" y="{STREET + 60}" width="90" height="8" fill="#e8e2d2"/>')
    for (cx, col) in ((300, "#4f86d9"), (980, "#d9a441"), (1720, "#9bb4c4"), (2300, "#c96a5a")):
        b.append(f'<rect x="{cx}" y="{STREET + 26}" width="80" height="24" rx="8" fill="{col}"/><rect x="{cx + 14}" y="{STREET + 14}" width="44" height="16" rx="6" fill="{shade(col, 0.4)}"/>')
    for cx in (620, 1400, 2100):
        b.append(f'<path d="M{cx - 10},{STREET + 30} L{cx},{STREET + 4} L{cx + 10},{STREET + 30}z" fill="{ORANGE}"/>')
    b.append(f'<rect x="0" y="{STREET - 70}" width="{W}" height="70" fill="#ffffff" opacity="0.18"/>')   # névoa da altura
    return "".join(b)


def andaime():
    b = []
    for m in MONT:   # montantes (BASE FIXA, presos na parede)
        x = m * T
        b.append(f'<rect x="{x - 7}" y="{LV["L4"] * T - 60}" width="14" height="{STREET - LV["L4"] * T + 60}" fill="{TUBO}"/>')
        b.append(f'<rect x="{x - 7}" y="{LV["L4"] * T - 60}" width="5" height="{STREET - LV["L4"] * T + 60}" fill="{shade(TUBO, 0.3)}"/>')
        for lv in LV.values():
            b.append(f'<rect x="{x - 12}" y="{lv * T + 20}" width="24" height="16" rx="3" fill="#8d98a4"/>')   # braçadeira
    for i in range(5):   # contraventos em X por baixo das pranchas
        xa, xb = MONT[i] * T, MONT[i + 1] * T
        for lv_a, lv_b in ((LV["L4"], LV["L3"]), (LV["L2"], LV["L1"])):
            if (i + lv_a) % 2 == 0:
                b.append(f'<path d="M{xa},{lv_a * T + 36} L{xb},{lv_b * T}" stroke="{shade(TUBO, -0.15)}" stroke-width="6"/>')
    for nm, bays in PRANCHAS.items():
        y = LV[nm] * T
        for i in bays:
            xa, xb = MONT[i] * T + 10, MONT[i + 1] * T - 10
            fill = "#c98a4b"
            b.append(R(xa, y, xb - xa, 22, fill, 3, 2.2, dark="#a46a35"))
            for k in range(int((xb - xa) // 96)):
                b.append(f'<path d="M{xa + 48 + k * 96},{y + 3} v16" stroke="#a46a35" stroke-width="3"/>')
            b.append(f'<rect x="{xa}" y="{y + 22}" width="{xb - xa}" height="10" fill="#8a5a2b"/>')   # rodapé
            if (nm, i) == CEDE:   # M13 Andaime Cede: fita zebrada + rachadura + poeira
                b.append(cd.zebra(xa, y - 14, xb - xa, 12))
                b.append(f'<path d="M{xa + 150},{y + 2} l18,14 l-10,8 l22,10" stroke="{INK}" stroke-width="4" fill="none"/>')
                for k in range(5):
                    b.append(f'<circle cx="{xa + 120 + k * 30}" cy="{y + 44 + (k % 2) * 10}" r="{6 + k % 3}" fill="#efe6d6" opacity="0.8"/>')
    # guarda-corpo do andar de cima
    for i in PRANCHAS["L4"]:
        xa, xb = MONT[i] * T, MONT[i + 1] * T
        b.append(f'<path d="M{xa},{LV["L4"] * T - 50} H{xb}" stroke="{TUBO}" stroke-width="8"/>')
    # telas de proteção (destrutíveis), uma rasgada
    for (i, torn) in ((1, False), (4, True)):
        xa, xb = MONT[i] * T + 10, MONT[i + 1] * T - 10
        y0, y1 = LV["L4"] * T + 40, LV["L3"] * T - 10
        b.append(f'<rect x="{xa}" y="{y0}" width="{xb - xa}" height="{y1 - y0}" fill="#5fae6a" opacity="0.42"/>')
        for k in range(0, int(xb - xa), 22):
            b.append(f'<path d="M{xa + k},{y0} V{y1}" stroke="#d8f0d8" stroke-width="1.5" opacity="0.5"/>')
        if torn:
            b.append(f'<path d="M{xa + 120},{y0 + 40} q40,60 10,120 q-30,40 40,80" stroke="#f3b07f" stroke-width="26" fill="none" opacity="0.9"/>')
    b.append(escada(4 * T + 26, LV["L3"] * T + 30, LV["L1"] * T))
    b.append(escada(22 * T - 52, LV["L4"] * T + 30, LV["L3"] * T))
    return "".join(b)


def balancim(x0, x1, y, top=3 * T + 10):
    """M10 — balancim (plataforma suspensa por cabos) que sobe e desce; motor no cabo."""
    b = [f'<path d="M{x0 + 20},{top} V{y} M{x1 - 20},{top} V{y}" stroke="#4a4f5c" stroke-width="4"/>']
    for x in (x0 + 20, x1 - 20):
        b.append(f'<rect x="{x - 14}" y="{y - 86}" width="28" height="34" rx="5" fill="#6b7783"/><circle cx="{x}" cy="{y - 69}" r="7" fill="{YEL}"/>')
    b.append(R(x0, y, x1 - x0, 20, YEL, 4, 2, dark=YEL_D))
    b.append(cd.zebra(x0, y + 20, x1 - x0, 8))
    b.append(f'<path d="M{x0},{y} V{y - 54} H{x1} V{y}" stroke="#8d98a4" stroke-width="5" fill="none"/>')
    for k in range(1, 4):
        b.append(f'<path d="M{x0 + k * (x1 - x0) / 4},{y - 52} V{y}" stroke="#8d98a4" stroke-width="2.5"/>')
    b.append(f'<path d="M{(x0 + x1) / 2 - 20},{y + 40} l20,22 l20,-22" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.8"/>')   # sobe/desce
    return "".join(b)


def guincho():
    """M11 — guincho de material na prancha de cima: braço para fora, corda, palete de tijolos balançando."""
    px, py = 26 * T, LV["L4"] * T
    b = [f'<rect x="{px - 10}" y="{py - 150}" width="20" height="150" fill="#6b7783"/>',
         f'<path d="M{px},{py - 140} L{px + 260},{py - 140}" stroke="#6b7783" stroke-width="14"/>',
         f'<circle cx="{px + 6}" cy="{py - 60}" r="26" fill="#8d98a4"/><circle cx="{px + 6}" cy="{py - 60}" r="10" fill="{INK}"/>',
         f'<path d="M{px + 250},{py - 140} L{px + 280},{12 * T - 20}" stroke="#4a4f5c" stroke-width="4"/>']
    lx, ly = px + 280, 12 * T - 20
    b.append(f'<g transform="rotate(-6 {lx} {ly})"><rect x="{lx - 70}" y="{ly}" width="140" height="16" fill="#8a5a2b"/>')
    for r in range(3):
        for c in range(4):
            b.append(f'<rect x="{lx - 64 + c * 32}" y="{ly - 20 - r * 20}" width="30" height="18" fill="#c8643c" stroke="#9a4a2a" stroke-width="2"/>')
    b.append('</g>')
    b.append(f'<path d="M{lx - 110},{ly - 30} q-20,20 0,40 M{lx + 110},{ly - 30} q20,20 0,40" stroke="#ffffff" stroke-width="5" fill="none" opacity="0.8"/>')
    return "".join(b)


def serra():
    """M12 — serra de bancada na prancha de baixo (mesmo tipo da do Térreo)."""
    x, y = 12 * T + 30, LV["L1"] * T
    b = [f'<rect x="{x}" y="{y - 60}" width="170" height="16" fill="#8d98a4"/>',
         f'<path d="M{x + 14},{y - 44} V{y} M{x + 156},{y - 44} V{y}" stroke="#6b7783" stroke-width="10"/>',
         f'<circle cx="{x + 86}" cy="{y - 64}" r="36" fill="#c9d1d8" stroke="#8d98a4" stroke-width="5"/><circle cx="{x + 86}" cy="{y - 64}" r="8" fill="{INK}"/>']
    b.append(cd.zebra(x, y - 44, 170, 8))
    return "".join(b)


def pilhas():
    b = []
    x, y = MONT[3] * T + 40, LV["L3"] * T   # sacos de cimento
    for r in range(3):
        for c in range(4 - r):
            b.append(R(x + c * 56 + r * 28, y - 30 - r * 28, 52, 28, "#d9d2c0", 10, 1.4, dark="#b8ae98"))
    x, y = MONT[1] * T + 230, LV["L2"] * T   # tijolos
    for r in range(3):
        for c in range(3):
            b.append(f'<rect x="{x + c * 34}" y="{y - 20 - r * 20}" width="32" height="18" fill="#c8643c" stroke="#9a4a2a" stroke-width="2"/>')
    return "".join(b)


def laje_torta():
    """Entrada da cena: a laje do Térreo inclinada, com a ponta de baixo APOIADA na prancha do 3º andar (gerada na transição)."""
    ex, ey = MONT[1] * T - 40, LV["L3"] * T          # ponta de baixo, em cima da prancha
    b = [f'<g transform="translate({ex},{ey}) rotate(32)">']
    b.append(R(-900, -66, 900, 66, "#d8ccb6", 4, 2.6, dark="#b8ab92"))
    for k in range(9):
        b.append(f'<path d="M{-860 + k * 96},0 v{22 + (k % 3) * 10}" stroke="#7a6f62" stroke-width="5"/>')   # ferragem
    b.append(f'<path d="M-420,-62 l24,26 l-12,16 l30,20" stroke="{INK}" stroke-width="5" fill="none"/>')
    b.append('</g>')
    for (x, y, r) in ((ex - 120, ey - 20, 20), (ex - 70, ey - 18, -12), (ex + 20, ey - 22, 40)):
        b.append(f'<rect x="{x}" y="{y}" width="36" height="20" fill="#cbc2b1" transform="rotate({r} {x} {y})"/>')
    return "".join(b)


def atores():
    c = el.COLORS
    b = [robot("marretao", "pesado_golpe", c[0], 13 * T - 20, LV["L3"] * T),
         robot("picareta", "esquiva", c[1], 14 * T + 40, LV["L3"] * T, flip=True),
         robot("chave", "rapido", c[2], 19 * T, 11 * T + 40, flip=True),
         robot("britadeira", "esquiva", c[3], 25 * T, 16 * T - 20)]
    b.append(f'<path d="M{25 * T - 70},{16 * T - 70} h-50 M{25 * T - 66},{16 * T - 50} h-40" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity="0.8"/>')
    return "".join(b)


def tags():
    """Etiquetas de aprovação (não vão para o jogo)."""
    out = []
    for (x, y, t) in ((19 * T, 9 * T + 10, "M10"), (32 * T, 12 * T + 40, "M10"), (27 * T + 20, 4 * T - 10, "M11"),
                      (13 * T + 120, LV["L1"] * T - 140, "M12"), (25 * T, LV["L2"] * T - 60, "M13"), (4 * T, 5 * T + 10, "ENTRADA"),
                      (8 * T, STREET + 10, "RUA = KO")):
        w = 26 + len(t) * 15
        out.append(f'<rect x="{x - w / 2}" y="{y - 22}" width="{w}" height="36" rx="12" fill="#ffffff" stroke="{INK}" stroke-width="4"/>'
                   f'<text x="{x}" y="{y + 6}" font-family="Fredoka, Arial" font-weight="700" font-size="22" fill="{INK}" text-anchor="middle">{t}</text>')
    return "".join(out)


def balancins():
    return balancim(16 * T + 30, 22 * T - 30, 11 * T + 40) + balancim(28 * T + 30, 34 * T - 30, 15 * T + 20)


def cena(com_tags=True):
    body = sky() + city() + grua() + fachada() + rua() + andaime() + pilhas() + serra() + guincho() + balancins() + laje_torta() + atores()
    out = f'<g filter="url(#rough)">{body}</g>' + (tags() if com_tags else "")
    return doc(W, H, out, rough(seed=41, scale=0.8, freq=0.05))


# ---------------------------------------------------------------- camadas de JOGO (D5): o que é parado vira PNG da cena 3
def andaime_jogo():
    """Montantes, contraventos, telas e escadas + a prancha de BAIXO (base fixa, tiles da linha 18). As pranchas de cima
    são peças destrutíveis desenhadas pelo jogo (modes/canteiro.gd)."""
    keep = dict(PRANCHAS)
    PRANCHAS.update({"L4": [], "L3": [], "L2": [], "L1": keep["L1"]})
    try:
        out = andaime()
    finally:
        PRANCHAS.clear()
        PRANCHAS.update(keep)
    return out


def e3_longe():
    return sky() + city() + grua()


def e3_palco():
    # a laje torta NÃO vai na camada: no jogo é a própria laje do Térreo que vira rampa (desenhada por modes/cena.gd)
    return fachada() + rua() + andaime_jogo()


def jogo():
    out = os.path.join(ROOT, "art/out/game/fase1")
    src = os.path.join(ROOT, "art/src/cenarios/svg/fase1_jogo")
    os.makedirs(out, exist_ok=True)
    os.makedirs(src, exist_ok=True)
    h3 = 21 * T
    for i, (name, fn) in enumerate((("e3_longe", e3_longe), ("e3_palco", e3_palco))):
        body = fn()
        queue(doc(W, h3, f'<g filter="url(#rough)">{body}</g>', rough(seed=70 + i, scale=0.8, freq=0.05)),
              f"{src}/{name}.svg", f"{out}/{name}.png", W, h3, 1)
    print("fachada (jogo):", render_all())


def main():
    if "--jogo" in sys.argv:
        jogo()
        return
    src = os.path.join(ROOT, "art/src/cenarios/svg/fase1")
    os.makedirs(src, exist_ok=True)
    queue(cena(), f"{src}/fachada.svg", os.path.join(ROOT, "art/out/fase1_fachada.png"), W, H, 0.75)
    print("fachada:", render_all())


if __name__ == "__main__":
    main()
