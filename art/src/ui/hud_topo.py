"""PRANCHA — HUD de cima mais animado (pedido 2026-11-27): cartão do jogador com RETRATO VIVO (o robô de verdade, mexendo,
reagindo) e a MALETA da engenhoca em evidência (com ela / usando). Cartão no tamanho real ×2.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/hud_topo.py → art/out/ui/hud_topo.png
"""
import base64
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "../robos"))
sys.path.insert(0, os.path.join(HERE, ".."))
import elenco_uch as eu  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, INK, CREAM  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/ui")
CORES = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]
FAM = {"ataque": "#f08a3d", "controle": "#8a63d2", "transformacao": "#3fc1c9", "defesa": "#4fae5b"}
# centro e raio da cabeça de cada robô do elenco (unidades do desenho, pés em 0,0)
CAB = {0: (9, -62, 25), 1: (2, -52, 27), 2: (3, -56, 21), 3: (13, -51, 21), 4: (4, -56, 21)}   # medido na grade
_n = [0]


def png(path):
    with open(os.path.join(ROOT, path), "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def retrato(cx, cy, r, model, col, face="parado", dy=0.0, rot=0.0, cinza=False, susto=False):
    """Retrato redondo: a CABEÇA do robô de verdade recortada num círculo (dy/rot = o robô se mexendo dentro)."""
    _n[0] += 1
    hx, hy, hr = CAB[model]
    s = r / hr * 0.95
    body = eu.desenha(model, "#b8b0b4" if cinza else col, face)
    o = f'<clipPath id="cp{_n[0]}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>'
    o += f'<circle cx="{cx}" cy="{cy}" r="{r + 5}" fill="{INK}"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="{CREAM if not susto else "#ffd9cf"}"/>'
    o += (f'<g clip-path="url(#cp{_n[0]})"><g transform="translate({cx},{cy + r * 0.08 + dy}) rotate({rot}) scale({s}) '
          f'translate({-hx},{-hy})">{body}</g></g>')
    return o


def coracao(x, y, s, cheio=True, pisca=False):
    pts = []
    for k in range(32):
        a = k * 2 * math.pi / 32
        pts.append(f"{x + 16 * math.sin(a) ** 3 * s / 16:.1f},{y - (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)) * s / 16:.1f}")
    fill = "#ffffff" if pisca else ("#e5484d" if cheio else "#c9c2b8")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{INK}" stroke-width="{s * 0.4:.1f}" stroke-linejoin="round"/>'


def maleta(x, y, fam, icone, cargas=1, usando=0.0, nome="", rot_ic=0):
    """MALETA pendurada embaixo do cartão: alça + caixa grande na cor da família com o ÍCONE DA engenhoca + cargas.
    usando (0..1) = a maleta abre: mostra o nome e a barra de uso esvaziando, com brilho em volta."""
    col = FAM[fam]
    w, h = (290 if usando else 124), 86
    o = ""
    if usando:
        for k in range(10):
            a = k * math.pi / 5
            o += f'<path d="M{x + w / 2 + math.cos(a) * (w / 2 + 6):.0f},{y + h / 2 + math.sin(a) * (h / 2 + 4):.0f} l{math.cos(a) * 18:.0f},{math.sin(a) * 14:.0f}" stroke="{col}" stroke-width="6" stroke-linecap="round"/>'
        o += f'<rect x="{x - 12}" y="{y - 10}" width="{w + 24}" height="{h + 20}" rx="28" fill="{col}" opacity="0.4"/>'
    else:
        o += f'<rect x="{x - 8}" y="{y - 8}" width="{w + 16}" height="{h + 16}" rx="24" fill="{col}" opacity="0.3"/>'
    o += f'<path d="M{x + 40},{y + 4} v-18 h44 v18" fill="none" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/>'
    o += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{col}" stroke="{INK}" stroke-width="6"/>'
    o += f'<rect x="{x + 6}" y="{y + 6}" width="{w - 12}" height="16" rx="8" fill="#ffffff" opacity="0.3"/>'
    o += f'<rect x="{x}" y="{y + h * 0.55}" width="{w}" height="7" fill="{INK}" opacity="0.25"/>'
    o += f'<circle cx="{x + 62}" cy="{y + h / 2}" r="36" fill="#fff6e4" stroke="{INK}" stroke-width="4"/>'
    o += f'<image href="{icone}" x="{x + 28}" y="{y + h / 2 - 34}" width="68" height="68" preserveAspectRatio="xMidYMid meet" transform="rotate({rot_ic} {x + 62} {y + h / 2})"/>'
    for k in range(cargas):
        o += f'<circle cx="{x + 22 + k * 22}" cy="{y + h + 14}" r="9" fill="{col}" stroke="{INK}" stroke-width="4"/>'
    if usando:
        o += T(x + 196, y + 36, nome, 20, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
        o += f'<rect x="{x + 110}" y="{y + 50}" width="166" height="18" rx="9" fill="{INK}"/>'
        o += f'<rect x="{x + 114}" y="{y + 54}" width="{158 * usando}" height="10" rx="5" fill="#ffffff"/>'
    return o


def cartao(x, y, i, model, estado, dano, vidas=4, max_vidas=4, extra=""):
    col = CORES[i]
    cinza = estado == "fora"
    fill = "#b8aeb4" if cinza else col
    o = ""
    if estado == "usando":
        o += f'<rect x="{x - 12}" y="{y - 12}" width="604" height="148" rx="44" fill="{FAM["ataque"]}" opacity="0.45"/>'
    if estado == "dano":
        o += f'<rect x="{x - 8}" y="{y - 8}" width="596" height="140" rx="42" fill="#ff5a3a" opacity="0.45"/>'
    o += f'<rect x="{x}" y="{y + 10}" width="580" height="124" rx="36" fill="{INK}"/>'
    o += f'<rect x="{x}" y="{y}" width="580" height="124" rx="36" fill="{fill}" stroke="{INK}" stroke-width="8"/>'
    o += f'<rect x="{x + 10}" y="{y + 8}" width="560" height="26" rx="13" fill="#ffffff" opacity="0.22"/>'
    if estado == "perigo":
        o += f'<path d="M{x + 420},{y + 6} l14,30 l-12,18 l16,26 M{x + 520},{y + 120} l-10,-24 l14,-12" stroke="{INK}" stroke-width="4" fill="none" opacity="0.6"/>'
    face = {"normal": "parado", "maleta": "parado", "usando": "golpe", "dano": "parado", "perigo": "parado", "fora": "parado"}[estado]
    o += retrato(x + 66, y + 58, 62, model, col, face, dy={"usando": -4, "dano": 6}.get(estado, 0), rot={"dano": -14, "usando": 6}.get(estado, 0),
                 cinza=cinza, susto=estado == "dano")
    o += T(x + 150, y + 50, f"P{i + 1}", 40, "#ffffff", "start", extra=f'stroke="{INK}" stroke-width="8" paint-order="stroke"')
    for k in range(max_vidas):
        o += coracao(x + 162 + k * 32, y + 92, 13, k < vidas, pisca=(estado == "perigo" and k == vidas - 1))
    dc = {"normal": "#ffffff", "maleta": "#ffffff", "usando": "#ffffff", "dano": "#ffb03a", "perigo": "#ff4a3a", "fora": "#ffffff"}[estado]
    sz = {"dano": 84, "perigo": 74}.get(estado, 64)
    if estado != "fora":
        tr = f'transform="rotate(-6 {x + 560} {y + 80})"' if estado == "dano" else ""
        o += f'<g {tr}>' + T(x + 562, y + 88 + (sz - 64) * 0.3, f"{dano}%", sz, dc, "end", extra=f'stroke="{INK}" stroke-width="12" paint-order="stroke"') + "</g>"
    return o + extra


def nota(x, y, linhas):
    return "".join(T(x, y + k * 30, ln, 22, INK, "start", 600) for k, ln in enumerate(linhas))


def prancha():
    W, H = 1920, 1620
    ic_marreta = png("game/assets/spells/a04_marreta.png")
    ic_mecha = png("game/assets/spells/icone_mecha_T05.png")
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', title(W / 2, 74, "HUD DE CIMA — PROPOSTA", 60)]
    linhas = [
        ("1 · NORMAL", cartao(60, 150, 0, 0, "normal", 0),
         ["RETRATO VIVO: a cabeça do robô de verdade, respirando,", "piscando e olhando para os lados (não é foto parada)."]),
        ("2 · COM A MALETA", cartao(60, 150, 1, 2, "maleta", 34, extra=maleta(160, 296, "transformacao", ic_mecha)) +
         T(300, 290, "!", 46, "#ffd34d", extra=f'stroke="{INK}" stroke-width="7" paint-order="stroke"'),
         ["Pegou engenhoca: a MALETA cai do cartão com o ÍCONE DELA", "(não só o da família), quica, e pulsa na cor da família.",
          "Pontinhos = cargas. O robô olha para a maleta."]),
        ("3 · USANDO", cartao(60, 150, 0, 0, "usando", 52, extra=maleta(160, 296, "ataque", ic_marreta, 1, 0.65, "MARRETA SÍSMICA", rot_ic=45)),
         ["Usando: o cartão brilha na cor da família, a maleta abre", "mostrando o NOME e a barra de uso esvaziando; o robô", "faz cara de esforço e se mexe."]),
        ("4 · LEVOU GOLPE", cartao(60, 150, 2, 3, "dano", 87) + T(560, 140, "+12%", 34, "#ffb03a", extra=f'stroke="{INK}" stroke-width="7" paint-order="stroke"'),
         ["O número dá um PULO (cresce, gira e treme) e muda de cor;", "o cartão pisca vermelho e o robô leva o susto no retrato", "(balança para trás)."]),
        ("5 · EM PERIGO (+120%)", cartao(60, 150, 3, 1, "perigo", 134, vidas=1),
         ["Muito amassado: % vermelho pulsando, rachaduras no cartão,", "o último coração pisca e o robô sua no retrato."]),
        ("6 · FORA", cartao(60, 150, 1, 4, "fora", 0, vidas=0) +
         f'<g transform="rotate(-8 330 212)">' + T(330, 232, "FORA", 64, "#ff5a5a", extra=f'stroke="{INK}" stroke-width="12" paint-order="stroke"') + "</g>",
         ["Eliminado: cartão cinza, robô desmaiado no retrato,", "carimbo FORA."]),
    ]
    for k, (tit, card, txt) in enumerate(linhas):
        col, row = k % 2, k // 2
        ox, oy = 40 + col * 940, 130 + row * 490
        b.append(f'<rect x="{ox}" y="{oy}" width="900" height="470" rx="30" fill="#ffffff" opacity="0.45"/>')
        b.append(T(ox + 30, oy + 46, tit, 30, INK, "start"))
        b.append(f'<g transform="translate({ox},{oy - 60})">{card}</g>')
        b.append(f'<g transform="translate({ox},{oy})">{nota(30, 370, txt)}</g>')
    b.append(T(W / 2, H - 24, "Cartão desenhado ×2. No jogo: mesmo lugar (topo), 2 à esquerda e 2 à direita; manômetro no meio.", 22, INK))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    style = "<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}</style>"
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{style}{"".join(b)}</svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/hud_topo.svg"), os.path.join(OUT, "hud_topo.png"), W, H, 1)
    print(render_all(), os.path.join(OUT, "hud_topo.png"))


if __name__ == "__main__":
    prancha()
