"""PRANCHA — o que o robô carrega ANTES de ativar o mecha (pedido 2026-11-27) + ÍCONES novos da seleção de engenhocas.
Proposta: CARTUCHO DE MECHA — uma cápsula pesada no tema da máquina, com a fenda de olho vermelha do mecha e um núcleo
que pulsa; segurada na mão da frente, projeta um HOLOGRAMA girando da silhueta do mecha. Ativar = o robô crava o
cartucho no peito e as peças explodem para fora (a transformação que já existe).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/mecha_cartucho.py → art/out/robos_v2/mecha_cartucho.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import armaduras_conceito as ac  # noqa: E402
import armaduras_habilidades as ah  # noqa: E402
from armaduras_conceito import R, E, S, P_, DARK, STEEL, STEEL_D, STEEL_L, YEL, YEL_D, ab, eu, label, INK, queue, render_all, shade  # noqa: E402

EYE = "#ff3b2f"
TEMAS = {   # id: (nome, cor do casco, cor do núcleo, função do mecha, detalhe)
    "T01": ("FORNALHA", "#4a505c", "#ff8a2a", ac.fornalha, "brasa"),
    "T02": ("EMPILHADEIRA", "#e0b02a", "#ffe27a", ac.empilhadeira, "garfo"),
    "T03": ("BOLA", "#7a828f", "#d8e0ea", ac.bola, "espinhos"),
    "T04": ("JATO", "#d8dde4", "#5fb8ff", ac.jato, "aletas"),
    "T05": ("BROCA", "#e07a2e", "#ffd36b", ac.broca, "ponta"),
    "T06": ("PARA-RAIOS", "#2f3f5a", "#7fe7ff", ah.para_raios, "bobina"),
}


def cartucho(tid, s=1.0, brilho=1.0):
    """Cápsula em pé (centro em 0,0; ~52 de altura): casco no tema, cinta de perigo, janela do núcleo, fenda de olho."""
    nome, casco, nucleo, _, det = TEMAS[tid]
    o = ""
    # detalhe do tema atrás
    if det == "brasa":
        o += R(-16, -36, 6, 12, 2, DARK, k=0.2) + R(-8, -38, 6, 14, 2, DARK, k=0.2)
    if det == "garfo":
        o += R(14, -20, 16, 4, 1.5, STEEL, k=0.2) + R(14, -8, 16, 4, 1.5, STEEL, k=0.2)
    if det == "espinhos":
        for a in range(0, 360, 45):
            c, sn = math.cos(math.radians(a)), math.sin(math.radians(a))
            o += P_([(c * 20 - sn * 4, sn * 24 + c * 4), (c * 30, sn * 34), (c * 20 + sn * 4, sn * 24 - c * 4)], STEEL_L, k=0.1)
    if det == "aletas":
        o += P_([(-18, 10), (-28, 26), (-14, 22)], STEEL_D, k=0.2) + P_([(18, 10), (28, 26), (14, 22)], STEEL_D, k=0.2)
        o += R(-6, 24, 12, 8, 2, DARK, k=0.2) + P_([(-5, 32), (5, 32), (0, 32 + 14 * brilho)], "#ff9a1f", k=0.2)
    if det == "ponta":
        o += S("M-10,-24 L10,-24 L0,-44 Z", STEEL, (-11, -45, 11, -23), k=0.4, dark=STEEL_D, light=STEEL_L)
    if det == "bobina":
        o += R(-3, -40, 6, 16, 2, DARK, k=0.2) + "".join(E(0, -28 - i * 4, 7 - i, 2.2, "#c98a3a", k=0.1) for i in range(3))
        o += f'<path d="M0,-42 l5,-6 l-3,-3 l6,-7" stroke="#e8fbff" stroke-width="1.6" fill="none"/>'
    # corpo da cápsula
    o += R(-18, -26, 36, 52, 12, casco, k=0.6)
    o += R(-18, -26, 36, 9, 6, shade(casco, 0.2), k=0.2)
    o += ac.cb.faixa(-18, 12, 36, 6, n=5)
    o += R(-12, -14, 24, 22, 7, DARK, k=0.3)
    o += f'<rect x="-9" y="-11" width="18" height="16" rx="5" fill="{nucleo}" opacity="{0.55 + 0.45 * brilho:.2f}"/>'
    o += f'<circle cx="0" cy="-3" r="{14 + 10 * brilho:.1f}" fill="{nucleo}" opacity="{0.18 * brilho:.2f}"/>'
    o += P_([(-8, -20), (8, -18), (8, -16), (-8, -17)], EYE, k=0.1)   # fenda de olho do mecha
    o += R(-20, -4, 4, 10, 1.5, STEEL_D, k=0.1) + R(16, -4, 4, 10, 1.5, STEEL_D, k=0.1)   # travas
    return f'<g transform="scale({s})">{o}</g>'


COLAR = []   # (tipo, tid, x, y, escala, rot) — o PIL cola o mecha (imagens do jogo) por cima do SVG


def holograma(tid, x, y, s=0.28, rot=0.0, base=(0, 0, 1.0)):
    """Silhueta do mecha em luz, girando (achatada no eixo x para parecer 3D) sobre o cartucho (colada depois)."""
    _, _, nucleo, fn, _ = TEMAS[tid]
    bx, by, bs = base
    COLAR.append(("holo", tid, bx + x * bs, by + y * bs, s * bs, rot))
    hh, ww = 260.0 * s, 95.0 * s   # cone de luz do núcleo até o holograma, na escala do holograma
    return (f'<path d="M{x - 3 * s / 0.16},{y + 18 * s / 0.16} L{x - ww},{y - hh} L{x + ww},{y - hh} L{x + 3 * s / 0.16},{y + 18 * s / 0.16} Z" fill="{nucleo}" opacity="0.22"/>'
            + f'<ellipse cx="{x}" cy="{y}" rx="{ww * 0.9:.1f}" ry="{ww * 0.25:.1f}" fill="{nucleo}" opacity="0.3"/>')


def defs():
    return ('<defs><filter id="holo"><feColorMatrix type="matrix" values="0 0 0 0 0.55  0 0 0 0 0.92  0 0 0 0 1  0 0 0 0.85 0"/></filter>'
            '<filter id="sil"><feColorMatrix type="matrix" values="0 0 0 0 0.16  0 0 0 0 0.1  0 0 0 0 0.18  0 0 0 1 0"/></filter></defs>')


def icone(tid, x, y, tam=150):
    """Ícone da seleção = o próprio CARTUCHO que o robô segura (pedido 2026-11-27), num distintivo na cor do tema."""
    nome, casco, nucleo, fn, _ = TEMAS[tid]
    o = R(x, y, tam, tam, 26, shade(casco, -0.35), k=0.4) + R(x + 6, y + 6, tam - 12, tam - 12, 22, shade(nucleo, -0.55), k=0.3)
    o += f'<circle cx="{x + tam / 2}" cy="{y + tam * 0.45}" r="{tam * 0.36}" fill="{nucleo}" opacity="0.35"/>'
    o += f'<circle cx="{x + tam / 2}" cy="{y + tam * 0.45}" r="{tam * 0.22}" fill="{nucleo}" opacity="0.35"/>'
    o += f'<g transform="translate({x + tam / 2},{y + tam * 0.46}) rotate(-8)">{cartucho(tid, tam / 115.0, 1.0)}</g>'
    o += R(x + 10, y + tam - 30, tam - 20, 22, 9, "#ffffff", k=0.1) + label(x + tam / 2, y + tam - 13, nome, 13, INK)
    return o


def robo_com(tid, x, y, s=2.4):
    """Robô do elenco (Marretão) segurando o cartucho na mão da frente, com o holograma em cima."""
    corpo = eu.desenha(0, "#f06aa8", "parado")
    o = f'<g transform="translate({x},{y}) scale({s})">{corpo}'
    o += f'<g transform="translate(20,-38) rotate(-8)">{cartucho(tid, 0.55)}</g>'
    o += holograma(tid, 21, -54, 0.13, 35, (x, y, s)) + "</g>"
    return o


def prancha():
    W, H = 1920, 1340
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', defs(),
         label(W / 2, 54, "CARTUCHO DE MECHA (o que o robô carrega antes de ativar) + ÍCONES NOVOS", 34)]
    b.append(f'<rect x="20" y="84" width="{W - 40}" height="70" rx="18" fill="#ffffff" opacity="0.6"/>')
    b.append(label(W / 2, 112, "Pegou a caixa: o robô segura o CARTUCHO na mão da frente; o núcleo pulsa e projeta o HOLOGRAMA do mecha girando.", 19, INK, "middle", 600))
    b.append(label(W / 2, 140, "Ativou: crava o cartucho no peito → clarão → as peças explodem para fora e montam o mecha (transformação atual).", 19, INK, "middle", 600))
    for i, tid in enumerate(TEMAS):
        x = 30 + i * 312
        b.append(f'<rect x="{x - 10}" y="170" width="300" height="600" rx="22" fill="#ffffff" opacity="0.5"/>')
        b.append(label(x + 140, 206, TEMAS[tid][0], 24, INK))
        b.append(holograma(tid, x + 140, 345, 0.5, 40))
        b.append(f'<g transform="translate({x + 140},420) scale(2.3)">{cartucho(tid)}</g>')
        b.append(label(x + 140, 498, "na mão:", 15, "#2a4a58", "middle", 600))
        b.append(f'<rect x="{x + 20}" y="720" width="240" height="6" rx="3" fill="#c9b99a"/>')
        b.append(robo_com(tid, x + 120, 720, 2.6))
    # storyboard da ativação
    b.append(f'<rect x="20" y="790" width="{W - 40}" height="250" rx="22" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 826, "ATIVAÇÃO (Fornalha de exemplo)", 22, INK, "start"))
    passos = ["1 · segura (holograma gira)", "2 · ergue o cartucho", "3 · crava no peito: CLARÃO", "4 · peças explodem para fora", "5 · mecha montado"]
    for k, txt in enumerate(passos):
        x = 120 + k * 370
        b.append(f'<rect x="{x - 90}" y="1010" width="200" height="5" fill="#c9b99a"/>')
        if k == 0:
            b.append(robo_com("T01", x, 1010, 1.5))
        elif k == 1:
            b.append(f'<g transform="translate({x},1010) scale(1.5)">{eu.desenha(0, "#f06aa8", "parado")}<g transform="translate(10,-80)">{cartucho("T01", 0.55, 1.0)}</g></g>')
        elif k == 2:
            b.append(f'<g transform="translate({x},1010) scale(1.5)">{eu.desenha(0, "#f06aa8", "parado")}<g transform="translate(4,-44)">{cartucho("T01", 0.5, 1.0)}</g>'
                     + '<circle cx="4" cy="-44" r="40" fill="#ffffff" opacity="0.8"/></g>' + ah.ah_estrela(x + 6, 944, 60) if hasattr(ah, "ah_estrela") else
                     f'<g transform="translate({x},1010) scale(1.5)">{eu.desenha(0, "#f06aa8", "parado")}<g transform="translate(4,-44)">{cartucho("T01", 0.5, 1.0)}</g><circle cx="4" cy="-44" r="44" fill="#ffffff" opacity="0.75"/><circle cx="4" cy="-44" r="70" fill="#fff3b0" opacity="0.35"/></g>')
        elif k == 3:
            COLAR.append(("explode", "T01", x, 1010, 0.62, 0))
        else:
            COLAR.append(("mecha", "T01", x, 1010, 0.62, 0))
        b.append(label(x + 10, 1032, txt, 15, "#2a4a58", "middle", 600))
    # ícones
    b.append(f'<rect x="20" y="1060" width="{W - 40}" height="265" rx="22" fill="#ffffff" opacity="0.5"/>')
    b.append(label(60, 1094, "ÍCONES NOVOS DA SELEÇÃO (família MECHAS)", 22, INK, "start"))
    for i, tid in enumerate(TEMAS):
        b.append(icone(tid, 90 + i * 300, 1112, 196))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>', W, H


MDIR = os.path.join(ab.ROOT, "art/out/game/mecha")
X0, Y0, PXU = -150, -280, 0.84 * 2


def mecha_png(tid, explode=False):
    import json
    from PIL import Image
    m = json.load(open(os.path.join(MDIR, "mechas.json")))
    im = None
    for p in m["pecas"]:
        if p not in m["mechas"][tid]["tem"]:
            continue
        pi = Image.open(os.path.join(MDIR, f"{tid}_{p}{'_p1' if p == 'tronco' else ''}.png")).convert("RGBA")
        if im is None:
            im = Image.new("RGBA", pi.size, (0, 0, 0, 0))
        if explode:
            off = {"coxa": (-50, 30), "canela": (-30, 50), "pe": (-10, 60), "tronco": (0, -50), "cabeca": (20, -110), "arma": (90, -30),
                   "ombro_b": (-80, -80), "ombro_f": (80, -90), "costas": (-70, -110), "braco": (-90, 10), "cabine": (0, -30), "peito": (0, -40)}
            k = next((v for kk, v in off.items() if p.startswith(kk)), (0, 0))
            sgn = 1 if p.endswith("_f") else 1
            lay = Image.new("RGBA", pi.size, (0, 0, 0, 0))
            lay.alpha_composite(pi.rotate(-k[0] * 0.3, center=(252, 300)), (int(k[0] * sgn), int(k[1])))
            im.alpha_composite(lay)
        else:
            im.alpha_composite(pi)
    return im


def colar(base_img):
    from PIL import Image, ImageOps
    cache = {}
    for kind, tid, x, y, s, rot in COLAR:
        key = (tid, kind == "explode")
        if key not in cache:
            cache[key] = mecha_png(tid, kind == "explode")
        im = cache[key]
        sc = s / PXU
        kx = abs(math.cos(math.radians(rot))) if kind == "holo" else 1.0
        w, h = max(1, int(im.width * sc * kx)), max(1, int(im.height * sc))
        r = im.resize((w, h))
        if kind == "holo":
            a = r.getchannel("A").point(lambda v: int(v * 0.8))
            r = Image.merge("RGBA", (Image.new("L", r.size, 150), Image.new("L", r.size, 235), Image.new("L", r.size, 255), a))
        ox = int(x - (0 - X0) * PXU * sc * kx)
        oy = int(y - (0 - Y0) * PXU * sc)
        base_img.alpha_composite(r, (ox, oy))
    return base_img


def em_partes():
    from PIL import Image
    COLAR.clear()
    svg, w, h = prancha()
    tmp = os.path.join(ab.OUT, "_mc.png")
    queue(svg, os.path.join(HERE, "svg/mecha_cartucho.svg"), tmp, w, h, 1)
    print("svg:", render_all())
    im = colar(Image.open(tmp).convert("RGBA"))
    im.convert("RGB").save(os.path.join(ab.OUT, "mecha_cartucho.png"))
    os.remove(tmp)


if __name__ == "__main__":
    em_partes()
