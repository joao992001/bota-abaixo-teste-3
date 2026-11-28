"""PRANCHA — CONTROLES no padrão dos grandes jogos (pedido 2026-11-28): reconhecer o MODELO do controle (DualSense,
DualShock 4, Xbox, Switch Pro, genérico), mapear UM controle por vez (não todos do mesmo modelo) e o melhor mapeamento
de teclado para 2 jogadores (com e sem teclado numérico).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/controles_v2.py → art/out/ui/controles_v2.png
"""
import base64
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/ui")
AZ, VD, RS, AM = "#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"
CINZA = "#6b5a70"
PS_COR = {"x": "#7fb0ff", "o": "#ff7b7b", "q": "#ff8fd8", "t": "#5fe0b0"}


def st(w=6):
    return f'stroke="{INK}" stroke-width="{w}" paint-order="stroke"'


# ---------------------------------------------------------------- desenhos dos controles (silhuetas por marca)
def ctrl(x, y, modelo, s=1.0, lit=None):
    """Silhueta do controle de cada marca (cartoon, contorno grosso). lit = botão aceso ("baixo", "esq", "dir", "cima", "rb", "lb", "rt", "lt")."""
    lit = lit or ""
    o = f'<g transform="translate({x},{y}) scale({s})">'
    if modelo == "teclado":
        o += f'<rect x="-120" y="-50" width="240" height="100" rx="14" fill="#d5dbe1" stroke="{INK}" stroke-width="6"/>'
        for r in range(4):
            for c in range(12):
                o += f'<rect x="{-108 + c * 18}" y="{-40 + r * 20}" width="14" height="14" rx="3" fill="#ffffff" stroke="{INK}" stroke-width="2"/>'
        return o + "</g>"
    corpo = {"ps5": "#f3f4f7", "ps4": "#2c3140", "xbox": "#3a3f48", "switch": "#2c2c34", "gen": "#7a828f"}[modelo]
    o += (f'<path d="M-110,-40 C-130,-40 -150,10 -140,60 C-132,96 -96,98 -80,70 L-50,30 L50,30 L80,70 C96,98 132,96 140,60 '
          f'C150,10 130,-40 110,-40 Z" fill="{corpo}" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>')
    if modelo == "ps5":
        o += f'<path d="M-60,-40 L60,-40 L50,10 L-50,10 Z" fill="#1d2230" stroke="{INK}" stroke-width="4"/>'
        o += f'<path d="M-60,-40 L-50,10 M60,-40 L50,10" stroke="#5aa8ff" stroke-width="5"/>'
    if modelo == "ps4":
        o += f'<rect x="-50" y="-40" width="100" height="44" rx="8" fill="#1d2230" stroke="{INK}" stroke-width="4"/><rect x="-46" y="-46" width="92" height="6" rx="3" fill="#5aa8ff"/>'
    if modelo == "xbox":
        o += f'<circle cx="0" cy="-22" r="13" fill="#9aa4ae" stroke="{INK}" stroke-width="4"/><path d="M-7,-29 L7,-15 M7,-29 L-7,-15" stroke="#5cc45c" stroke-width="4"/>'
    # analógicos (PlayStation simétricos; Xbox/Switch esquerdo em cima)
    sim = modelo in ("ps5", "ps4")
    ls = (-44, 34) if sim else (-92, -6)
    dp = (-92, -6) if sim else (-44, 34)
    for (sx, sy) in (ls, (44, 34)):
        o += f'<circle cx="{sx}" cy="{sy}" r="20" fill="#1d2230" stroke="{INK}" stroke-width="4"/><circle cx="{sx}" cy="{sy}" r="12" fill="#4a505c"/>'
    o += f'<path d="M{dp[0] - 8},{dp[1] - 22} h16 v14 h14 v16 h-14 v14 h-16 v-14 h-14 v-16 h14 Z" fill="#4a505c" stroke="{INK}" stroke-width="3"/>'
    # botões de ação
    bx, by = 92, -6
    pos = {"cima": (0, -20), "baixo": (0, 20), "esq": (-20, 0), "dir": (20, 0)}
    for k, (dx, dy) in pos.items():
        cx, cy = bx + dx, by + dy
        cor = "#f2c84b" if lit == k else "#1d2230"
        o += f'<circle cx="{cx}" cy="{cy}" r="11" fill="{cor}" stroke="{INK}" stroke-width="3"/>'
        if modelo in ("ps5", "ps4"):
            sym = {"baixo": ("x", f'<path d="M{cx - 5},{cy - 5} l10,10 M{cx + 5},{cy - 5} l-10,10" stroke="{PS_COR["x"]}" stroke-width="2.5"/>'),
                   "dir": ("o", f'<circle cx="{cx}" cy="{cy}" r="5" fill="none" stroke="{PS_COR["o"]}" stroke-width="2.5"/>'),
                   "esq": ("q", f'<rect x="{cx - 5}" y="{cy - 5}" width="10" height="10" fill="none" stroke="{PS_COR["q"]}" stroke-width="2.5"/>'),
                   "cima": ("t", f'<path d="M{cx},{cy - 6} l6,10 h-12 Z" fill="none" stroke="{PS_COR["t"]}" stroke-width="2.5"/>')}[k][1]
            o += sym
        else:
            lab = {"xbox": {"baixo": "A", "dir": "B", "esq": "X", "cima": "Y"}, "switch": {"baixo": "B", "dir": "A", "esq": "Y", "cima": "X"},
                   "gen": {"baixo": "1", "dir": "2", "esq": "3", "cima": "4"}}[modelo][k]
            col = {"A": "#5cc45c", "B": "#ff6b6b", "X": "#5aa8ff", "Y": "#f2c84b"}.get(lab, "#ffffff") if modelo == "xbox" else "#ffffff"
            o += T(cx, cy + 5, lab, 14, col)
    for side, nm in ((-1, "lb"), (1, "rb")):
        cor = "#f2c84b" if lit == nm else "#4a505c"
        o += f'<rect x="{side * 100 - 30}" y="-58" width="60" height="16" rx="8" fill="{cor}" stroke="{INK}" stroke-width="4"/>'
    return o + "</g>"


def glifo(x, y, modelo, botao, r=22):
    """Glifo do botão no padrão da marca (como aparece no jogo)."""
    o = f'<circle cx="{x}" cy="{y + 3}" r="{r + 4}" fill="{INK}"/><circle cx="{x}" cy="{y}" r="{r}" fill="#2f3640"/>'
    if botao in ("rb", "lb", "rt", "lt", "start"):
        lab = {"ps5": {"rb": "R1", "lb": "L1", "rt": "R2", "lt": "L2", "start": "OPT"}, "ps4": {"rb": "R1", "lb": "L1", "rt": "R2", "lt": "L2", "start": "OPT"},
               "xbox": {"rb": "RB", "lb": "LB", "rt": "RT", "lt": "LT", "start": "☰"}, "switch": {"rb": "R", "lb": "L", "rt": "ZR", "lt": "ZL", "start": "+"}}[modelo][botao]
        return (f'<rect x="{x - r * 1.3}" y="{y - r * 0.8 + 3}" width="{r * 2.6}" height="{r * 1.6}" rx="{r * 0.5}" fill="{INK}"/>'
                f'<rect x="{x - r * 1.3}" y="{y - r * 0.8}" width="{r * 2.6}" height="{r * 1.6}" rx="{r * 0.5}" fill="#2f3640"/>' + T(x, y + r * 0.35, lab, int(r * 0.9), "#ffffff"))
    if modelo in ("ps5", "ps4"):
        k = r * 0.45
        o += {"baixo": f'<path d="M{x - k},{y - k} l{2 * k},{2 * k} M{x + k},{y - k} l{-2 * k},{2 * k}" stroke="{PS_COR["x"]}" stroke-width="4"/>',
              "dir": f'<circle cx="{x}" cy="{y}" r="{k}" fill="none" stroke="{PS_COR["o"]}" stroke-width="4"/>',
              "esq": f'<rect x="{x - k}" y="{y - k}" width="{2 * k}" height="{2 * k}" fill="none" stroke="{PS_COR["q"]}" stroke-width="4"/>',
              "cima": f'<path d="M{x},{y - k * 1.1} l{k},{k * 1.8} h{-2 * k} Z" fill="none" stroke="{PS_COR["t"]}" stroke-width="4"/>'}[botao]
        return o
    lab = {"xbox": {"baixo": "A", "dir": "B", "esq": "X", "cima": "Y"}, "switch": {"baixo": "B", "dir": "A", "esq": "Y", "cima": "X"}}[modelo][botao]
    col = {"A": "#5cc45c", "B": "#ff6b6b", "X": "#5aa8ff", "Y": "#f2c84b"}[lab] if modelo == "xbox" else "#ffffff"
    return o + T(x, y + r * 0.38, lab, int(r * 1.05), col)


def tecla(x, y, txt, cor="#ffffff", w=40, h=40, fs=18):
    return (f'<rect x="{x}" y="{y + 4}" width="{w}" height="{h}" rx="7" fill="{INK}"/><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="{cor}" stroke="{INK}" stroke-width="3"/>'
            + T(x + w / 2, y + h / 2 + fs * 0.36, txt, fs, INK))


# ---------------------------------------------------------------- painel 1: central de controles
def painel_hub(x0, y0):
    o = chunk(x0, y0, 1840, 560, CREAM, 30, 6, 10)
    o += title(x0 + 920, y0 + 70, "1 · CONTROLES — cada aparelho num cartão", 40)
    cards = [("teclado", "TECLADO A", "lado esquerdo", "P1", AZ, "padrão"),
             ("ps5", "DUALSENSE", "PlayStation 5 · Bluetooth", "P2", VD, "SUA configuração"),
             ("xbox", "XBOX SERIES", "Xbox · USB", "P3", RS, "padrão"),
             ("ps4", "DUALSHOCK 4", "PlayStation 4 · USB", "—", "#9aa4ae", "padrão")]
    for k, (mod, nome, sub, p, cor, cfg) in enumerate(cards):
        cx = x0 + 40 + k * 450
        sel = k == 1
        if sel:
            o += f'<rect x="{cx - 10}" y="{y0 + 110}" width="430" height="420" rx="30" fill="{AM}" opacity="0.7"/>'
        o += chunk(cx, y0 + 120, 410, 400, "#ffffff", 24, 5, 8)
        o += ctrl(cx + 205, y0 + 230, mod, 0.9)
        o += T(cx + 205, y0 + 345, nome, 32, INK)
        o += T(cx + 205, y0 + 378, sub, 20, CINZA, w=600)
        if p != "—":
            o += f'<rect x="{cx + 14}" y="{y0 + 134}" width="56" height="34" rx="10" fill="{cor}" stroke="{INK}" stroke-width="4"/>' + T(cx + 42, y0 + 158, p, 22, "#ffffff", extra=st(4))
        o += T(cx + 205, y0 + 410, cfg, 20, "#3c9a46" if cfg.startswith("SUA") else CINZA, w=600)
        for j, lb in enumerate(["MAPEAR", "TESTAR"]):
            bx = cx + 30 + j * 180
            o += chunk(bx, y0 + 440, 170, 54, AM if (sel and j == 0) else "#e9e2d2", 16, 4, 5) + T(bx + 85, y0 + 476, lb, 24, INK)
    o += T(x0 + 920, y0 + 545, "O jogo reconhece o MODELO (pelo fabricante/produto e pelo nome) e mostra os botões no desenho dele · a conexão e o jogador que está usando aparecem no cartão", 20, CINZA, w=600)
    return o


# ---------------------------------------------------------------- painel 2: mapear UM controle
def painel_mapear(x0, y0):
    o = chunk(x0, y0, 1840, 640, CREAM, 30, 6, 10)
    o += title(x0 + 920, y0 + 70, "2 · MAPEAR — só ESTE controle (DualSense do P2)", 40)
    o += ctrl(x0 + 330, y0 + 330, "ps5", 1.9, lit="esq")
    o += T(x0 + 330, y0 + 540, "o botão escolhido acende no desenho", 22, CINZA, w=600)
    acoes = [("PULAR", "baixo", None), ("GOLPE RÁPIDO", "esq", "ouvindo"), ("MARRETADA PESADA", "cima", None), ("ESQUIVA", "rb", "troca"),
             ("ESPECIAL (ENGENHOCA)", "lb", None), ("PAUSA", "start", None)]
    lx = x0 + 700
    for k, (nm, bt, est) in enumerate(acoes):
        y = y0 + 120 + k * 72
        cor = AM if est == "ouvindo" else "#ffffff"
        o += chunk(lx, y, 760, 60, cor, 16, 4, 5)
        o += T(lx + 24, y + 40, nm, 26, INK, "start")
        if est == "ouvindo":
            o += T(lx + 620, y + 40, "aperte o novo botão…  4", 22, "#a01528")
        else:
            o += glifo(lx + 690, y + 30, "ps5", bt, 20)
        if est == "troca":
            o += T(lx + 420, y + 40, "trocou com GOLPE RÁPIDO", 18, "#8a5a10")
    o += T(lx + 24, y0 + 568, "MOVER: analógico esquerdo e direcional (fixos, não precisa mapear)", 20, CINZA, "start", 600)
    for j, (lb, cor) in enumerate([("RESTAURAR PADRÃO", "#e9e2d2"), ("SALVAR", VD)]):
        o += chunk(lx + 830, y0 + 140 + j * 90, 250, 66, cor, 18, 5, 6) + T(lx + 955, y0 + 182 + j * 90, lb, 24, INK)
    o += T(lx + 955, y0 + 360, "vale SÓ para este", 22, INK) + T(lx + 955, y0 + 388, "controle — os outros", 22, INK) + T(lx + 955, y0 + 416, "DualSense não mudam", 22, INK)
    o += T(lx + 955, y0 + 470, "botão repetido? troca", 20, CINZA, w=600) + T(lx + 955, y0 + 496, "de lugar sozinho", 20, CINZA, w=600)
    o += T(x0 + 920, y0 + 620, "▲▼ escolhe a ação · PULAR muda · aperte o novo botão em 5 s (nada = cancela) · os botões das dicas do jogo seguem o mapeamento", 20, CINZA, w=600)
    return o


# ---------------------------------------------------------------- painel 3: teclado para 2
def teclado(x0, y0, p1, p2, numpad=True):
    """Teclado ABNT2 simplificado; p1/p2 = {tecla: rótulo da ação}."""
    o = ""
    rows = [["ESC", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], ["TAB", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["CAPS", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Ç"], ["SHIFT", "Z", "X", "C", "V", "B", "N", "M", ",", ".", ";"]]
    for r, row in enumerate(rows):
        for c, k in enumerate(row):
            w = 62 if c == 0 else 44
            x = x0 + (0 if c == 0 else 62 + 4 + (c - 1) * 48) + r * 10
            y = y0 + r * 50
            cor = AZ if k in p1 else ("#ffffff" if k not in p2 else VD)
            o += tecla(x, y, k, cor, w, 44, 15 if len(k) > 1 else 18)
    o += tecla(x0 + 160, y0 + 200, "ESPAÇO", AZ if "ESPAÇO" in p1 else "#ffffff", 300, 44, 16)
    ax, ay = x0 + 620, y0 + 150
    for k, dx, dy in (("▲", 48, 0), ("◄", 0, 50), ("▼", 48, 50), ("►", 96, 50)):
        o += tecla(ax + dx, ay + dy, k, VD if k in p2 else "#ffffff", 44, 44, 18)
    if numpad:
        nx, ny = x0 + 780, y0 + 0
        grid = [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], ["0", "", ","]]
        for r, row in enumerate(grid):
            for c, k in enumerate(row):
                if k:
                    kk = "N" + k
                    o += tecla(nx + c * 48, ny + r * 50, k, VD if kk in p2 else "#ffffff", 44, 44, 18)
        o += tecla(nx + 144, ny + 100, "↵", VD if "N↵" in p2 else "#ffffff", 44, 94, 18)
    return o


def legenda(x, y, cor, titulo, linhas):
    o = f'<rect x="{x}" y="{y - 26}" width="34" height="34" rx="8" fill="{cor}" stroke="{INK}" stroke-width="4"/>' + T(x + 48, y, titulo, 26, INK, "start")
    for k, ln in enumerate(linhas):
        o += T(x + 48, y + 34 + k * 28, ln, 20, INK, "start", 600)
    return o


def painel_teclado(x0, y0):
    o = chunk(x0, y0, 1840, 700, CREAM, 30, 6, 10)
    o += title(x0 + 920, y0 + 70, "3 · TECLADO PARA 2 — as duas mãos de cada um, sem se trombar", 40)
    p1 = {"W": "", "A": "", "S": "", "D": "", "G": "pular", "H": "golpe", "J": "marretada", "Y": "esquiva", "U": "especial", "ESC": "pausa"}
    p2 = {"▲": "", "◄": "", "▼": "", "►": "", "N1": "pular", "N2": "golpe", "N3": "marretada", "N4": "esquiva", "N5": "especial", "N↵": "pausa"}
    o += T(x0 + 40, y0 + 130, "TECLADO COMPLETO (com numérico)", 26, INK, "start")
    o += teclado(x0 + 40, y0 + 150, p1, p2)
    o += legenda(x0 + 1060, y0 + 170, AZ, "P1 · esquerda", ["mão esquerda: W A S D (andar)", "mão direita: G pular · H golpe · J marretada", "Y esquiva · U especial · ESC pausa"])
    o += legenda(x0 + 1060, y0 + 330, VD, "P2 · direita", ["mão esquerda: setas (andar)", "mão direita, numérico: 1 pular · 2 golpe", "3 marretada · 4 esquiva · 5 especial · ↵ pausa"])
    o += T(x0 + 40, y0 + 450, "NOTEBOOK (sem numérico): P1 igual · P2 = setas + K pular · L golpe · Ç marretada · O esquiva · P especial", 22, INK, "start", 600)
    o += T(x0 + 40, y0 + 490, "Por quê: andar e PULAR ficam em mãos diferentes (como no controle) · nada de SHIFT/CTRL (o Windows mistura) ·", 20, CINZA, "start", 600)
    o += T(x0 + 40, y0 + 518, "os grupos de teclas são separados para o teclado não \"engolir\" teclas apertadas juntas (fantasma).", 20, CINZA, "start", 600)
    o += chunk(x0 + 40, y0 + 560, 1760, 110, "#ffffff", 20, 4, 6)
    o += T(x0 + 70, y0 + 600, "TECLADO TAMBÉM MAPEIA: cada lado (A e B) tem a sua tela de MAPEAR, igual à do controle.", 24, INK, "start")
    o += T(x0 + 70, y0 + 638, "TESTE DE FANTASMA: aperte andar + pular + golpe juntos dos dois lados; se alguma tecla não acender, o jogo avisa e sugere outra.", 20, CINZA, "start", 600)
    return o


def prancha():
    W, H = 1920, 2140
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', title(W / 2, 70, "CONTROLES — PROPOSTA", 60)]
    b.append(painel_hub(40, 120))
    b.append(painel_mapear(40, 720))
    b.append(painel_teclado(40, 1400))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{style}{"".join(b)}</svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/controles_v2.svg"), os.path.join(OUT, "controles_v2.png"), W, H, 1)
    print(render_all(), os.path.join(OUT, "controles_v2.png"))


if __name__ == "__main__":
    prancha()
