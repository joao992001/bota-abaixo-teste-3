"""Controles e ícones de botão em PAPEL E GIZ, fiéis ao formato dos originais (pedido 2026-11-28).
Sem logotipos (regra do projeto): o botão central de cada marca é um botão liso.
Modelos: ps5 (DualSense), ps4 (DualShock 4), xbox (Xbox Series), switch (Switch Pro), gen (genérico).
ctrl(x, y, modelo, s, lit) desenha o controle de frente; glifo(...) desenha o ícone de um botão na cor/forma da marca.
"""
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(HERE, ".."))
from papel import hatch, rough  # noqa: E402
from svg import shade  # noqa: E402

AM = "#f2c84b"
_n = [0]

# cores de cada marca
COR = {
    "ps5": {"corpo": "#eef0f3", "centro": "#26282f", "touch": "#e3e6ea", "luz": "#5aa8ff", "botao": "#2f3238", "ombro": "#e3e6ea", "stick": "#4b4e57"},
    "ps4": {"corpo": "#2e323c", "centro": "#2e323c", "touch": "#23262d", "luz": "#5aa8ff", "botao": "#474c57", "ombro": "#262930", "stick": "#41454f"},
    "xbox": {"corpo": "#3a3d45", "centro": "#3a3d45", "botao": "#24262b", "ombro": "#2c2e34", "stick": "#4d5058", "guia": "#d9dde2"},
    "switch": {"corpo": "#2b2b31", "centro": "#2b2b31", "grip": "#56565f", "botao": "#1d1d22", "ombro": "#232328", "stick": "#46464e"},
    "gen": {"corpo": "#8d939d", "centro": "#8d939d", "botao": "#4b5059", "ombro": "#6f747e", "stick": "#41454c"},
}
SIMB = {  # cor dos símbolos (DualShock 4 colorido; DualSense cinza claro, como no original)
    "ps4": {"cima": "#3fc7a0", "dir": "#ff6b6b", "baixo": "#86aaff", "esq": "#ec8fdc"},
    "ps5": {"cima": "#cfd3da", "dir": "#cfd3da", "baixo": "#cfd3da", "esq": "#cfd3da"},
}
XBOX_LET = {"baixo": ("A", "#62c04e"), "dir": ("B", "#ea4a3f"), "esq": ("X", "#3f93e2"), "cima": ("Y", "#f2c230")}
SW_LET = {"baixo": "B", "dir": "A", "esq": "Y", "cima": "X"}
GEN_LET = {"baixo": "1", "dir": "2", "esq": "3", "cima": "4"}
OMBRO = {"ps5": ("L1", "R1", "L2", "R2"), "ps4": ("L1", "R1", "L2", "R2"), "xbox": ("LB", "RB", "LT", "RT"),
         "switch": ("L", "R", "ZL", "ZR"), "gen": ("L1", "R1", "L2", "R2")}
NOME = {"ps5": "DUALSENSE", "ps4": "DUALSHOCK 4", "xbox": "XBOX SERIES", "switch": "SWITCH PRO", "gen": "GENÉRICO"}


def defs():
    """Filtro de borda de papel; incluir uma vez no SVG."""
    return f"<defs>{rough('rgh', 3, 1.6, 0.08)}{rough('rghs', 5, 0.8, 0.12)}</defs>"


def P(d, fill, box, k=1.0, dens=1.0, filt="rgh", vol=0.0):
    """Forma de papel: cor chapada + giz, borda tremida; vol>0 escurece a borda de baixo (volume)."""
    _n[0] += 1
    cid = f"cp{_n[0]}"
    o = f'<clipPath id="{cid}"><path d="{d}"/></clipPath><g filter="url(#{filt})">'
    if vol:
        o += f'<path d="{d}" fill="{shade(fill, -0.28)}"/><g clip-path="url(#{cid})"><path d="{d}" transform="translate(0,{-vol})" fill="{fill}"/></g>'
    else:
        o += f'<path d="{d}" fill="{fill}"/>'
    o += hatch(cid, box, fill, _n[0] * 7 + 3, k, dens) + "</g>"
    return o


def circ_d(cx, cy, r):
    return f"M{cx - r},{cy} a{r},{r} 0 1,0 {2 * r},0 a{r},{r} 0 1,0 {-2 * r},0 Z"


def rr_d(x, y, w, h, r):
    return (f"M{x + r},{y} h{w - 2 * r} a{r},{r} 0 0 1 {r},{r} v{h - 2 * r} a{r},{r} 0 0 1 {-r},{r} h{-(w - 2 * r)} "
            f"a{r},{r} 0 0 1 {-r},{-r} v{-(h - 2 * r)} a{r},{r} 0 0 1 {r},{-r} Z")


def C(cx, cy, r, fill, k=0.9, vol=0.0):
    return P(circ_d(cx, cy, r), fill, (cx - r, cy - r, cx + r, cy + r), k, vol=vol)


def halo(cx, cy, r):
    return f'<g filter="url(#rgh)"><circle cx="{cx}" cy="{cy}" r="{r}" fill="{AM}" opacity="0.92"/></g>'


def Tx(x, y, s, size, col, w=700):
    return (f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="{w}" font-size="{size}" fill="{col}" '
            f'text-anchor="middle">{s}</text>')


# ---------------------------------------------------------------- símbolos
def simbolo_ps(cx, cy, k, botao, col, sw=None):
    sw = sw or max(2.0, k * 0.42)
    a = f'stroke="{col}" stroke-width="{sw:.1f}" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    if botao == "baixo":
        return f'<path d="M{cx - k},{cy - k} L{cx + k},{cy + k} M{cx + k},{cy - k} L{cx - k},{cy + k}" {a}/>'
    if botao == "dir":
        return f'<circle cx="{cx}" cy="{cy}" r="{k * 1.05:.1f}" {a}/>'
    if botao == "esq":
        return f'<rect x="{cx - k * 0.95:.1f}" y="{cy - k * 0.95:.1f}" width="{k * 1.9:.1f}" height="{k * 1.9:.1f}" {a}/>'
    return f'<path d="M{cx},{cy - k * 1.15:.1f} L{cx + k * 1.1:.1f},{cy + k * 0.8:.1f} L{cx - k * 1.1:.1f},{cy + k * 0.8:.1f} Z" {a}/>'


def face(cx, cy, modelo, botao, r, lit=False):
    """Um botão de ação (frente) do controle."""
    c = COR[modelo]
    o = halo(cx, cy, r + 7) if lit else ""
    o += C(cx, cy, r, c["botao"], 0.7, vol=r * 0.18)
    if modelo in ("ps5", "ps4"):
        o += simbolo_ps(cx, cy - 1, r * 0.48, botao, SIMB[modelo][botao])
    elif modelo == "xbox":
        lt, col = XBOX_LET[botao]
        o += Tx(cx, cy + r * 0.4, lt, r * 1.15, col)
    elif modelo == "switch":
        o += Tx(cx, cy + r * 0.4, SW_LET[botao], r * 1.15, "#f1f1f4")
    else:
        o += Tx(cx, cy + r * 0.4, GEN_LET[botao], r * 1.1, "#f1f1f4")
    return o


def stick(cx, cy, r, modelo, lit=False):
    c = COR[modelo]
    o = halo(cx, cy, r + 8) if lit else ""
    o += C(cx, cy, r, shade(c["stick"], -0.25), 0.8)
    o += C(cx, cy - 2, r * 0.78, c["stick"], 0.8, vol=r * 0.12)
    o += f'<g filter="url(#rghs)"><circle cx="{cx}" cy="{cy - 2}" r="{r * 0.5:.1f}" fill="none" stroke="{shade(c["stick"], 0.22)}" stroke-width="{max(1.5, r * 0.08):.1f}" opacity="0.8"/></g>'
    return o


def dpad_ps(cx, cy, s, modelo, lit=""):
    """Direcional PlayStation: quatro setas separadas apontando para o centro."""
    c = COR[modelo]
    o = ""
    for ang, nm in ((0, "cima"), (90, "dir"), (180, "baixo"), (270, "esq")):
        d = f"M{-s * 0.55},{-s * 1.85} h{s * 1.1} v{s * 0.85} l{-s * 0.55},{s * 0.5} l{-s * 0.55},{-s * 0.5} Z"
        g = P(d, AM if lit == nm else c["botao"], (-s, -s * 2, s, 0), 0.6, vol=s * 0.12)
        o += f'<g transform="translate({cx},{cy}) rotate({ang})">{g}</g>'
    return o


def dpad_cruz(cx, cy, s, modelo, lit="", disco=False):
    """Direcional em cruz (Switch/genérico); disco=True põe o prato do Xbox Series embaixo."""
    c = COR[modelo]
    o = C(cx, cy, s * 1.55, shade(c["corpo"], -0.22), 0.8) if disco else ""
    a, b = s * 0.42, s * 1.25
    d = (f"M{cx - a},{cy - b} h{2 * a} v{b - a} h{b - a} v{2 * a} h{-(b - a)} v{b - a} h{-2 * a} v{-(b - a)} "
         f"h{-(b - a)} v{-2 * a} h{b - a} Z")
    o += P(d, c["botao"], (cx - b, cy - b, cx + b, cy + b), 0.6, vol=s * 0.12)
    if lit:
        dx, dy = {"cima": (0, -1), "baixo": (0, 1), "esq": (-1, 0), "dir": (1, 0)}[lit]
        o += C(cx + dx * s * 0.85, cy + dy * s * 0.85, s * 0.36, AM, 0.5)
    return o


def ombro(cx, cy, w, h, fill, lit=False):
    o = P(rr_d(cx - w / 2, cy - h / 2, w, h, h / 2), AM if lit else fill, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), 0.8, vol=h * 0.2)
    return o


def pilula(cx, cy, w, h, fill):
    return P(rr_d(cx - w / 2, cy - h / 2, w, h, h / 2), fill, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), 0.5)


# ---------------------------------------------------------------- controles (caixa ~ -210..210 × -130..150)
def _ps(modelo, lit):
    c = COR[modelo]
    longo = modelo == "ps5"
    gy = 128 if longo else 110  # DualSense tem as pegadas mais compridas
    corpo = (f"M-150,-96 C-178,-96 -198,-70 -203,-28 C-210,32 -206,{gy - 30} -188,{gy} C-170,{gy + 28} -128,{gy + 26} -110,{gy - 6} "
             f"L-82,66 C-60,52 60,52 82,66 L110,{gy - 6} C128,{gy + 26} 170,{gy + 28} 188,{gy} C206,{gy - 30} 210,32 203,-28 "
             f"C198,-70 178,-96 150,-96 Z")
    o = ombro(-150, -102, 86, 20, c["ombro"], lit == "lb") + ombro(150, -102, 86, 20, c["ombro"], lit == "rb")
    o += P(corpo, c["corpo"], (-210, -100, 210, gy + 30), 1.1, vol=9)
    if longo:  # miolo preto do DualSense
        mio = "M-112,-74 L112,-74 C118,-22 108,36 84,68 C62,54 -62,54 -84,68 C-108,36 -118,-22 -112,-74 Z"
        o += P(mio, c["centro"], (-120, -80, 120, 70), 1.0)
        tp = "M-80,-99 L80,-99 L72,-30 C40,-20 -40,-20 -72,-30 Z"
        o += P(tp, c["touch"], (-82, -100, 82, -18), 1.0, vol=4)
        for sx in (-1, 1):
            o += f'<g filter="url(#rghs)"><path d="M{sx * 82},-97 L{sx * 73},-32" stroke="{c["luz"]}" stroke-width="6" stroke-linecap="round"/></g>'
        o += C(0, 42, 9, "#1b1c20", 0.5) + pilula(0, 58, 22, 7, "#3b3e46")  # botão central + mudo
        o += pilula(-96, -82, 9, 22, "#cfd3d9") + pilula(96, -82, 9, 22, "#cfd3d9")  # criar / options
    else:
        tp = "M-64,-94 L64,-94 L60,-38 C30,-30 -30,-30 -60,-38 Z"
        o += P(tp, c["touch"], (-66, -96, 66, -28), 1.0, vol=3)
        o += f'<g filter="url(#rghs)"><path d="M-58,-97 L58,-97" stroke="{c["luz"]}" stroke-width="6" stroke-linecap="round"/></g>'
        o += C(0, 40, 9, "#17181c", 0.5)
        o += pilula(-82, -78, 9, 20, "#4a4f5a") + pilula(82, -78, 9, 20, "#4a4f5a")  # share / options
    o += dpad_ps(-140, -22, 15, modelo, lit[2:] if lit.startswith("d-") else "")
    for nm, (dx, dy) in {"cima": (0, -31), "baixo": (0, 31), "esq": (-31, 0), "dir": (31, 0)}.items():
        o += face(140 + dx, -22 + dy, modelo, nm, 15, lit == nm)
    o += stick(-56, 34, 27, modelo, lit == "ls") + stick(56, 34, 27, modelo, lit == "rs")
    return o


def _assim(modelo, lit):
    """Xbox Series / Switch Pro / genérico: analógico esquerdo em cima, direcional embaixo."""
    c = COR[modelo]
    corpo = ("M-142,-90 C-182,-90 -202,-50 -207,0 C-212,62 -197,116 -166,130 C-140,140 -118,122 -100,96 C-80,70 -60,62 0,62 "
             "C60,62 80,70 100,96 C118,122 140,140 166,130 C197,116 212,62 207,0 C202,-50 182,-90 142,-90 C102,-96 60,-82 0,-82 "
             "C-60,-82 -102,-96 -142,-90 Z")
    o = ""
    for sx, nm in ((-1, "lb"), (1, "rb")):
        d = f"M{sx * 92},-92 C{sx * 120},-108 {sx * 170},-108 {sx * 192},-82 L{sx * 178},-74 C{sx * 160},-94 {sx * 122},-94 {sx * 100},-80 Z"
        o += P(d, AM if lit == nm else c["ombro"], (-200, -110, 200, -70), 0.8)
    o += P(corpo, c["corpo"], (-212, -98, 212, 140), 1.1, vol=9)
    if modelo == "switch":  # pegadas cinza-fumê do Pro
        for sx in (-1, 1):
            g = f"M{sx * 150},30 C{sx * 200},40 {sx * 205},110 {sx * 166},130 C{sx * 140},140 {sx * 118},122 {sx * 100},96 C{sx * 112},70 {sx * 130},40 {sx * 150},30 Z"
            o += P(g, c["grip"], (-210, 28, 210, 140), 1.0)
    o += stick(-128, -22, 27, modelo, lit == "ls") + stick(62, 40, 27, modelo, lit == "rs")
    o += dpad_cruz(-62, 40, 20, modelo, lit[2:] if lit.startswith("d-") else "", disco=modelo == "xbox")
    for nm, (dx, dy) in {"cima": (0, -29), "baixo": (0, 29), "esq": (-29, 0), "dir": (29, 0)}.items():
        o += face(128 + dx, -22 + dy, modelo, nm, 14, lit == nm)
    if modelo == "xbox":
        o += C(0, -52, 17, c["guia"], 0.7, vol=2) + C(0, -52, 11, "#eef1f4", 0.5)  # botão-guia liso (sem logo)
        o += C(-40, -14, 9, c["botao"], 0.5) + C(40, -14, 9, c["botao"], 0.5) + pilula(0, 10, 16, 8, c["botao"])
        o += '<g stroke="#d9dde2" stroke-width="1.6" fill="none"><rect x="-45" y="-19" width="6" height="5"/><rect x="-41" y="-15" width="6" height="5"/>'
        o += '<path d="M35,-17 h10 M35,-14 h10 M35,-11 h10"/></g>'
    elif modelo == "switch":
        o += pilula(-40, -52, 14, 5, "#d6d6dc") + pilula(40, -52, 14, 5, "#d6d6dc") + pilula(40, -52, 5, 14, "#d6d6dc")
        o += P(rr_d(-31, -22, 14, 14, 3), "#3a3a42", (-31, -22, -17, -8), 0.5) + C(-24, -15, 3.5, "#1d1d22", 0.3)
        o += C(26, -15, 9, "#3a3a42", 0.5) + '<path d="M21,-14 l5,-5 l5,5 v5 h-10 Z" fill="#d6d6dc"/>'
    else:
        o += pilula(-30, -40, 22, 8, c["botao"]) + pilula(30, -40, 22, 8, c["botao"])
    return o


def ctrl(x, y, modelo, s=1.0, lit=None):
    lit = lit or ""
    corpo = _ps(modelo, lit) if modelo in ("ps5", "ps4") else _assim(modelo, lit)
    return f'<g transform="translate({x},{y}) scale({s})">{corpo}</g>'


# ---------------------------------------------------------------- ícones (glifos) de botão
def glifo(x, y, modelo, botao, r=22):
    """Ícone do botão como aparece nas dicas/mapeamento: botão de papel na forma da marca.
    botao: cima/baixo/esq/dir (ação), lb/rb/lt/rt, start/select, ls/rs (analógico), d-cima/d-baixo/d-esq/d-dir, l-cima.. (analógico numa direção)."""
    c = COR[modelo]
    if botao in ("cima", "baixo", "esq", "dir"):
        return face(x, y, modelo, botao, r)
    if botao in ("lb", "rb", "lt", "rt"):
        lab = OMBRO[modelo][("lb", "rb", "lt", "rt").index(botao)]
        w, h = r * 2.6, r * 1.55
        if botao in ("lb", "rb"):
            d = rr_d(x - w / 2, y - h / 2, w, h, h * 0.45)
        else:  # gatilho: mais alto em cima
            d = (f"M{x - w / 2},{y + h / 2} v{-h * 0.55} C{x - w / 2},{y - h * 0.75} {x + w / 2},{y - h * 0.75} {x + w / 2},{y - h * 0.05} "
                 f"v{h * 0.55} Z")
        return P(d, c["botao"], (x - w / 2, y - h, x + w / 2, y + h / 2), 0.6, vol=r * 0.12) + Tx(x, y + r * 0.36, lab, r * 0.92, "#f1f1f4")
    if botao in ("start", "select"):
        rot = {"ps5": ("OPTIONS", "CREATE"), "ps4": ("OPTIONS", "SHARE"), "xbox": ("☰", "⧉"), "switch": ("+", "−"), "gen": ("START", "SELECT")}[modelo]
        lab = rot[0 if botao == "start" else 1]
        w = r * (3.4 if len(lab) > 2 else 1.9)
        return pilula(x, y, w, r * 1.3, c["botao"]) + Tx(x, y + r * 0.3, lab, r * (0.62 if len(lab) > 2 else 1.0), "#f1f1f4")
    if botao in ("ls", "rs") or botao.startswith("l-") or botao.startswith("r-"):
        o = stick(x, y, r, modelo)
        lab = "L" if botao[0] == "l" else "R"
        if "-" in botao:
            ang = {"cima": -90, "baixo": 90, "esq": 180, "dir": 0}[botao.split("-")[1]]
            o += (f'<g transform="translate({x},{y - 1}) rotate({ang})" filter="url(#rghs)"><path d="M{r * 1.08},-{r * 0.5} L{r * 1.6},0 '
                  f'L{r * 1.08},{r * 0.5} Z" fill="{AM}" stroke="#2a1a2e" stroke-width="{r * 0.1:.1f}" stroke-linejoin="round"/></g>')
            o += Tx(x, y + r * 0.2, lab, r * 0.75, "#f1f1f4")
        else:
            o += Tx(x, y + r * 0.2, lab, r * 0.75, "#f1f1f4")
        return o
    if botao.startswith("d-"):
        dirn = botao[2:]
        if modelo in ("ps5", "ps4"):
            return dpad_ps(x, y, r * 0.55, modelo, dirn)
        return dpad_cruz(x, y, r * 0.8, modelo, dirn)
    return C(x, y, r, c["botao"])


def tecla(x, y, txt, w=None, r=22, lit=False):
    """Tecla do teclado em papel (para as dicas quando o jogador usa teclado)."""
    w = w or r * 2
    h = r * 2
    fill = AM if lit else "#eef0f2"
    o = P(rr_d(x - w / 2, y - h / 2, w, h, r * 0.35), fill, (x - w / 2, y - h / 2, x + w / 2, y + h / 2), 0.6, vol=r * 0.22)
    return o + Tx(x, y + r * 0.3, txt, r * (0.85 if len(txt) <= 2 else 0.55), "#2a1a2e")
