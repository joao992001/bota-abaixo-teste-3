"""PRANCHA — M10 TUBARÃO (Cargueiro Perdido, cena 2a Destroços). Barbatana ronda o mar fundo; aviso (anel vermelho +
som) → salta em arco e morde quem está em plataforma BAIXA; marretada no focinho espanta.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_tubarao.py → art/out/fase2/perigo_tubarao.png
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
from f2_prancha import R, E, PL, S, conteiner, robot, CONT, INK  # noqa: E402
import elenco as el  # noqa: E402
from papel import rough  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
FW, FH = 560, 340
VERM = "#d42035"
CINZA, CINZA_D, BARRIGA = "#7f8fa0", "#5a6878", "#e8eef2"


def Tt(x, y, s, size=18, col=INK, anchor="middle"):
    return f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="700" font-size="{size}" fill="{col}" text-anchor="{anchor}">{s}</text>'


def barbatana(x, y, s=1.0):
    return PL([(x - 26 * s, y), (x + 4 * s, y - 52 * s), (x + 24 * s, y)], CINZA_D, 1.2) + f'<path d="M{x - 40 * s},{y + 4} q20,-8 40,0 t40,0" stroke="#ffffff" stroke-width="3" fill="none"/>'


def tubarao(cx, cy, ang, boca=0.0):
    """Tubarão cartoon de perfil (focinho para a direita), girado ang graus."""
    o = f'<g transform="translate({cx},{cy}) rotate({ang})">'
    o += S("M-110,0 C-80,-46 40,-50 96,-12 C110,-4 112,8 96,14 C40,40 -80,40 -110,0 Z", CINZA, (-112, -50, 112, 40), k=1.4, dark=CINZA_D)
    o += S("M-90,8 C-40,30 40,30 92,14 C40,40 -60,40 -90,8 Z", BARRIGA, (-90, 8, 92, 40), k=1.0)
    o += PL([(-110, 0), (-160, -40), (-140, 0), (-160, 40)], CINZA_D, 1.2)          # cauda
    o += PL([(-10, -40), (16, -86), (34, -38)], CINZA_D, 1.2)                         # barbatana
    o += PL([(10, 22), (30, 56), (44, 20)], CINZA_D, 1.0)                             # nadadeira
    o += f'<circle cx="62" cy="-14" r="7" fill="{INK}"/><circle cx="64" cy="-16" r="2" fill="#ffffff"/>'
    for k in range(3):
        o += f'<path d="M{20 - k * 12},-6 q-4,10 0,18" stroke="{CINZA_D}" stroke-width="3" fill="none"/>'
    if boca > 0:
        o += f'<path d="M66,4 L112,{-4 - 18 * boca} L112,{8 + 18 * boca} Z" fill="#7a1a2a"/>'
        for k in range(4):
            o += f'<path d="M{72 + k * 10},{2 - 2 * k * boca} l4,8 l4,-8" fill="#ffffff"/>'
    return o + "</g>"


def cena_base(nivel=250):
    o = f'<rect width="{FW}" height="{FH}" fill="#cfeae6"/>'
    o += PL([(0, FH), (10, 170), (120, 160), (140, FH)], "#8a8f99", 1.6) + PL([(420, FH), (440, 150), (560, 150), (560, FH)], "#8a8f99", 1.6)
    o += f'<rect x="0" y="{nivel}" width="{FW}" height="{FH - nivel}" fill="#1f5f78"/>'
    o += f'<path d="M0,{nivel} ' + "".join("q20,-6 40,0 " for _ in range(15)) + '" stroke="#ffffff" stroke-width="3" fill="none"/>'
    # bote virado (plataforma baixa) no meio
    o += PL([(220, nivel - 34), (340, nivel - 34), (326, nivel + 6), (234, nivel + 6)], "#f08a3d", 1.2) + R(220, nivel - 40, 120, 8, "#d9dce4", 2, 0.6)
    return o


def quadro(x, y, corpo, titulo, txt):
    o = (f'<g transform="translate({x},{y})"><clipPath id="t{x}"><rect width="{FW}" height="{FH}" rx="14"/></clipPath>'
         f'<g clip-path="url(#t{x})">{corpo}</g><rect width="{FW}" height="{FH}" rx="14" fill="none" stroke="{INK}" stroke-width="5"/></g>')
    o += Tt(x + FW / 2, y + FH + 34, titulo, 24, "#ffffff")
    for k, ln in enumerate(txt):
        o += Tt(x + FW / 2, y + FH + 64 + k * 26, ln, 18, "#fff4c8")
    return o


def prancha():
    PW, PH = 1920, 640
    b = []
    # 1 · aviso: barbatana acelera para o bote; anel vermelho na água; tã-dã
    c1 = cena_base() + barbatana(150, 250) + f'<path d="M110,262 h-60 M116,272 h-40" stroke="#ffffff" stroke-width="3"/>'
    c1 += f'<ellipse cx="280" cy="256" rx="90" ry="14" fill="none" stroke="{VERM}" stroke-width="5" stroke-dasharray="14 8"/>'
    c1 += robot("marretao", "parado", el.COLORS[0], 280, 216, s=0.7) + Tt(400, 70, "tã-dã... tã-dã...", 22, VERM) + f'<circle cx="280" cy="150" r="16" fill="{VERM}"/>' + Tt(280, 157, "!", 22, "#ffffff")
    b.append(quadro(40, 110, c1, "1 · AVISO (1,5 s)", ["a barbatana acelera para a plataforma baixa", "anel vermelho na água + som de tubarão"]))
    # 2 · ação: salta em arco e morde
    c2 = cena_base() + tubarao(300, 170, -28, boca=1.0) + robot("marretao", "esquiva", el.COLORS[0], 370, 110, s=0.7, rot=-30)
    c2 += f'<path d="M180,250 q30,-60 60,-90" stroke="#ffffff" stroke-width="4" fill="none" stroke-dasharray="8 8"/>' + f'<circle cx="200" cy="250" r="10" fill="none" stroke="#ffffff" stroke-width="3"/>'
    for k in range(6):
        b_ = f'<circle cx="{220 + k * 18}" cy="{240 - k * 6}" r="{4 + k}" fill="#ffffff" opacity="0.8"/>'
        c2 += b_
    b.append(quadro(680, 110, c2, "2 · SALTA E MORDE", ["joga o robô para cima e para o lado", "só pega plataformas BAIXAS (rentes à água)"]))
    # 3 · revide: marretada no focinho → tonto, foge
    c3 = cena_base() + tubarao(380, 236, 168) + robot("picareta", "pesado_golpe", el.COLORS[1], 250, 216, s=0.7)
    c3 += f'<path d="M296,200 l-14,-12 M290,214 l-20,0" stroke="{INK}" stroke-width="4"/>' + f'<path d="M480,250 h50 M486,262 h36" stroke="#ffffff" stroke-width="3"/>'
    for k in range(3):
        c3 += Tt(300 + k * 26, 180 - (k % 2) * 12, "✦", 22, "#f2c84b")
    b.append(quadro(1320, 110, c3, "3 · REVIDE", ["marretada no focinho enquanto salta:", "fica tonto e foge por um tempo"]))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{PH}" viewBox="0 0 {PW} {PH}"><defs>{fp.fonte()}{rough(seed=43, scale=0.6, freq=0.05)}</defs>'
           f'<rect width="{PW}" height="{PH}" fill="#2a1a2e"/>' + Tt(PW / 2, 66, "M10 · TUBARÃO — Destroços do Cargueiro (mar fundo)", 40, "#ffffff")
           + f'<g filter="url(#rough)">{"".join(b)}</g></svg>')
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/fase2/tubarao.svg"), os.path.join(OUT, "perigo_tubarao.png"), PW, PH, 1)
    print(render_all(), os.path.join(OUT, "perigo_tubarao.png"))


if __name__ == "__main__":
    prancha()
