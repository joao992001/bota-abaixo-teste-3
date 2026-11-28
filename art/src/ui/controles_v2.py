"""PRANCHA — CONTROLES no padrão dos grandes jogos (pedido 2026-11-28), arte em PAPEL E GIZ fiel ao formato dos
controles originais (sem logotipos). Reconhecer o MODELO, mapear UM controle por vez (com direcionais, principal e
alternativo) e o melhor mapeamento de teclado para 2 jogadores.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/controles_v2.py → art/out/ui/controles_v2.png
"""
import base64
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import controles_arte as ca  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/ui")
AZ, VD, RS, AM = "#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"
CINZA = "#6b5a70"
PAPEL = "#f4ecdc"


def st(w=6):
    return f'stroke="{INK}" stroke-width="{w}" paint-order="stroke"'


def tecla(x, y, txt, cor="#ffffff", w=40, h=40, fs=18):
    return (f'<rect x="{x}" y="{y + 4}" width="{w}" height="{h}" rx="7" fill="{INK}"/><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="{cor}" stroke="{INK}" stroke-width="3"/>'
            + T(x + w / 2, y + h / 2 + fs * 0.36, txt, fs, INK))


def mini_teclado(x, y, s):
    o = f'<g transform="translate({x},{y}) scale({s})">'
    o += ca.P(ca.rr_d(-150, -62, 300, 124, 16), "#cfd5db", (-150, -62, 150, 62), 1.0, vol=8)
    for r in range(4):
        for c in range(12 if r < 3 else 9):
            w = 20 if r < 3 else (20 if c not in (3,) else 92)
            xx = -136 + c * 23.5 + (r * 5 if r < 3 else 0) + (72 if (r == 3 and c > 3) else 0)
            if r == 3 and c > 6:
                break
            o += ca.P(ca.rr_d(xx, -50 + r * 26, w, 20, 4), "#f1f3f5", (xx, -50 + r * 26, xx + w, -30 + r * 26), 0.5)
    return o + "</g>"


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
        o += chunk(cx, y0 + 120, 410, 400, PAPEL, 24, 5, 8)
        o += mini_teclado(cx + 205, y0 + 240, 0.95) if mod == "teclado" else ca.ctrl(cx + 205, y0 + 228, mod, 0.62)
        o += T(cx + 205, y0 + 355, nome, 32, INK)
        o += T(cx + 205, y0 + 386, sub, 20, CINZA, w=600)
        if p != "—":
            o += f'<rect x="{cx + 14}" y="{y0 + 134}" width="56" height="34" rx="10" fill="{cor}" stroke="{INK}" stroke-width="4"/>' + T(cx + 42, y0 + 158, p, 22, "#ffffff", extra=st(4))
        o += T(cx + 205, y0 + 416, cfg, 20, "#3c9a46" if cfg.startswith("SUA") else CINZA, w=600)
        for j, lb in enumerate(["MAPEAR", "TESTAR"]):
            bx = cx + 30 + j * 180
            o += chunk(bx, y0 + 440, 170, 54, AM if (sel and j == 0) else "#e9e2d2", 16, 4, 5) + T(bx + 85, y0 + 476, lb, 24, INK)
    o += T(x0 + 920, y0 + 545, "O jogo reconhece o MODELO (código do fabricante/produto e, na falta, o nome) e desenha o controle certo · conexão e jogador aparecem no cartão", 20, CINZA, w=600)
    return o


# ---------------------------------------------------------------- painel 2: ícones de cada marca
def painel_icones(x0, y0):
    mods = ["ps5", "ps4", "xbox", "switch", "gen"]
    o = chunk(x0, y0, 1840, 150 + len(mods) * 150, CREAM, 30, 6, 10)
    o += title(x0 + 920, y0 + 70, "2 · ÍCONES — papel e giz, no formato e nas cores de cada controle", 40)
    cols = ["baixo", "dir", "esq", "cima", "lb", "rb", "lt", "rt", "start", "select", "d-cima", "l-esq", "rs"]
    nomes = ["", "", "", "", "", "", "", "", "", "", "direcional", "analógico", ""]
    for r, m in enumerate(mods):
        y = y0 + 190 + r * 150
        o += ca.ctrl(x0 + 150, y - 8, m, 0.4)
        o += T(x0 + 150, y + 68, ca.NOME[m], 22, INK)
        for c, b in enumerate(cols):
            o += ca.glifo(x0 + 360 + c * 112, y, m, b, 26)
            if r == len(mods) - 1 and nomes[c]:
                o += T(x0 + 360 + c * 112, y + 62, nomes[c], 18, CINZA, w=600)
    o += T(x0 + 920, y0 + 130 + len(mods) * 150, "Sem logotipos das marcas (botão central liso) · as dicas do jogo usam estes ícones conforme o controle de cada jogador", 20, CINZA, w=600)
    return o


# ---------------------------------------------------------------- painel 3: mapear UM controle
def painel_mapear(x0, y0):
    H = 900
    o = chunk(x0, y0, 1840, H, CREAM, 30, 6, 10)
    o += title(x0 + 920, y0 + 70, "3 · MAPEAR — só ESTE controle (DualSense do P2)", 40)
    o += chunk(x0 + 30, y0 + 120, 600, 560, PAPEL, 24, 5, 8)
    o += ca.ctrl(x0 + 330, y0 + 360, "ps5", 1.3, lit="esq")
    o += T(x0 + 330, y0 + 600, "o botão da ação escolhida", 22, CINZA, w=600) + T(x0 + 330, y0 + 628, "acende no desenho", 22, CINZA, w=600)
    acoes = [("ANDAR ◄", "l-esq", "d-esq", None), ("ANDAR ►", "l-dir", "d-dir", None), ("CIMA ▲ (subir / mirar)", "l-cima", "d-cima", None),
             ("BAIXO ▼ (descer / pisão)", "l-baixo", "d-baixo", None),
             ("PULAR", "baixo", None, None), ("GOLPE RÁPIDO", "esq", None, "ouvindo"), ("MARRETADA PESADA", "cima", None, None),
             ("ESQUIVA", "rb", "rt", "troca"), ("ESPECIAL (ENGENHOCA)", "lb", "lt", None), ("PAUSA", "start", None, None)]
    lx = x0 + 670
    o += T(lx + 560, y0 + 140, "PRINCIPAL", 20, CINZA) + T(lx + 690, y0 + 140, "ALTERNATIVO", 20, CINZA)
    for k, (nm, b1, b2, est) in enumerate(acoes):
        y = y0 + 156 + k * 64
        cor = AM if est == "ouvindo" else "#ffffff"
        o += chunk(lx, y, 780, 54, cor, 14, 4, 4)
        o += T(lx + 22, y + 36, nm, 23, INK, "start")
        if est == "ouvindo":
            o += T(lx + 625, y + 36, "aperte o novo botão…  4", 21, "#a01528")
        else:
            o += ca.glifo(lx + 560, y + 27, "ps5", b1, 19)
            o += ca.glifo(lx + 690, y + 27, "ps5", b2, 19) if b2 else T(lx + 690, y + 37, "—", 24, CINZA)
        if est == "troca":
            o += T(lx + 360, y + 36, "trocou com GOLPE RÁPIDO", 17, "#8a5a10")
        if k == 3:
            o += f'<path d="M{lx},{y + 61} h780" stroke="{CINZA}" stroke-width="3" stroke-dasharray="8 8"/>'
    bx = lx + 830
    for j, (lb, cor) in enumerate([("RESTAURAR PADRÃO", "#e9e2d2"), ("SALVAR", VD)]):
        o += chunk(bx, y0 + 160 + j * 90, 250, 66, cor, 18, 5, 6) + T(bx + 125, y0 + 202 + j * 90, lb, 24, INK)
    for k, ln in enumerate(["vale SÓ para este", "controle — os outros", "DualSense não mudam"]):
        o += T(bx + 125, y0 + 380 + k * 28, ln, 22, INK)
    for k, ln in enumerate(["botão repetido? troca", "de lugar sozinho", "", "direções aceitam", "analógico, direcional", "ou qualquer botão"]):
        o += T(bx + 125, y0 + 490 + k * 26, ln, 20, CINZA, w=600)
    o += T(x0 + 920, y0 + H - 50, "▲▼ escolhe a ação · ◄► escolhe PRINCIPAL/ALTERNATIVO · PULAR muda · aperte o novo botão em 5 s (nada = cancela) · TRIÂNGULO apaga o alternativo", 20, CINZA, w=600)
    o += T(x0 + 920, y0 + H - 22, "o menu continua andando pelo analógico/direcional mesmo se você remapear as direções (para nunca ficar preso)", 20, CINZA, w=600)
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
    o += title(x0 + 920, y0 + 70, "4 · TECLADO PARA 2 — as duas mãos de cada um, sem se trombar", 40)
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
    W, H = 1920, 3340
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', ca.defs(), title(W / 2, 70, "CONTROLES — PROPOSTA v2", 60)]
    b.append(painel_hub(40, 120))
    b.append(painel_icones(40, 720))
    b.append(painel_mapear(40, 1650))
    b.append(painel_teclado(40, 2600))
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
