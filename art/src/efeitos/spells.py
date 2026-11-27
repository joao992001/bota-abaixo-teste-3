"""Spells e eventos (Relatório 04) — Etapa 1: caixas das 4 famílias, S01, S03, S06, S10, S11, S13, G10 e HUD.
Estilo papel e giz (formas chapadas, textura de giz, borda tremida). Cada família tem COR + FORMA + ÍCONE (nunca só cor).
Gera art/out/game/spells/*.png (peças que o jogo anima) e a prancha art/out/prancha_spells_etapa1.png.
Rodar: python3 art/src/efeitos/spells.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from papel import ellipse_d, rect_d, rough, shape  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
SRC = os.path.join(ROOT, "art/src/efeitos/svg/spells")
OUT = os.path.join(ROOT, "art/out/game/spells")
INK = "#2a1a2e"
METAL, METAL_D, METAL_L = "#9aa4ae", "#6b7783", "#c9d1d8"
FAM = {  # cor, forma da caixa, ícone
    "ataque": ("#f08a3d", "espinhos", "punho"),
    "controle": ("#8a63d2", "capsula", "ima"),
    "engenharia": ("#f2c84b", "hexagono", "chave"),
    "transformacao": ("#3fc1c9", "losango", "engrenagem"),
    "defesa": ("#4fae5b", "cupula", "capacete"),   # 2026-11-27: classe nova DEFESA (capacete de obra, placa em cúpula)
}
ICE, ICE_D, FIRE, FIRE_L = "#9fe3f5", "#5fb6d6", "#f08a3d", "#ffd36b"


def wrap(w, h, body, seed, scale=0.8):
    return doc(w, h, f'<g filter="url(#rough)">{body}</g>', rough(seed=seed, scale=scale, freq=0.08))


def star_pts(cx, cy, n, r0, r1, rot=0.0):
    pts = []
    for i in range(n * 2):
        a = rot + i * math.pi / n
        r = r0 if i % 2 == 0 else r1
        pts.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return " ".join(pts)


# ---------------------------------------------------------------- ícones (64x64, centro 32,32)
def icon(name, col="#ffffff"):
    if name == "punho":
        return (f'<path d="M18,30 C18,22 24,18 32,18 L42,18 C48,18 50,22 50,27 L50,40 C50,46 46,48 40,48 L26,48 C21,48 18,45 18,40 Z" fill="{col}"/>'
                f'<path d="M26,18 V30 M34,18 V30 M42,19 V30" stroke="{INK}" stroke-width="2.4" opacity="0.5"/>'
                f'<path d="M8,26 h8 M6,34 h10 M8,42 h8" stroke="{col}" stroke-width="3.4" stroke-linecap="round"/>')
    if name == "ima":
        return (f'<path d="M16,14 V34 C16,44 23,50 32,50 C41,50 48,44 48,34 V14 H38 V34 C38,38 35,40 32,40 C29,40 26,38 26,34 V14 Z" fill="{col}"/>'
                f'<path d="M16,14 H26 V20 H16 Z M38,14 H48 V20 H38 Z" fill="{INK}" opacity="0.45"/>')
    if name == "chave":
        return (f'<path d="M20,48 L36,32" stroke="{col}" stroke-width="8" stroke-linecap="round"/>'
                f'<path d="M36,32 C32,24 38,14 48,16 L42,22 L44,28 L50,30 L56,24 C58,34 48,40 40,36 Z" fill="{col}"/>')
    if name == "capacete":   # capacete de obra: cúpula com friso, aba e luz
        return (f'<path d="M12,42 C12,24 22,14 32,14 C42,14 52,24 52,42 Z" fill="{col}"/>'
                f'<rect x="6" y="40" width="52" height="8" rx="4" fill="{col}"/>'
                f'<path d="M32,14 V40" stroke="{INK}" stroke-width="3" opacity="0.4"/>'
                f'<path d="M22,20 C18,26 17,32 17,40 M42,20 C46,26 47,32 47,40" stroke="{INK}" stroke-width="2" opacity="0.3" fill="none"/>')
    if name == "engrenagem":
        teeth = []
        for k in range(8):
            a = k * math.pi / 4
            teeth.append(f'<rect x="-4" y="-22" width="8" height="10" rx="2" fill="{col}" transform="translate(32,32) rotate({math.degrees(a):.0f})"/>')
        return "".join(teeth) + f'<circle cx="32" cy="32" r="15" fill="{col}"/><circle cx="32" cy="32" r="6" fill="{INK}" opacity="0.45"/>'
    return ""


# ---------------------------------------------------------------- caixas (96x96)
def caixa_body(fam):
    """Caixa de spell: engradado com moldura metálica, cantos aparafusados, alça, placa da família (forma + ícone) e '?'."""
    col, form, ic = FAM[fam]
    dark, light = shade(col, -0.32), shade(col, 0.35)
    b = []
    # corpo do engradado (madeira pintada na cor da família) + ripas
    b.append(shape(f"cb{fam}", rect_d(10, 20, 76, 66, 8), col, 300 + len(fam), (8, 18, 88, 88), k=2.0, dark=dark, light=light))
    for x in (28, 48, 68):
        b.append(f'<rect x="{x - 2}" y="22" width="4" height="62" fill="{dark}" opacity="0.45"/>')
    # moldura metálica e cantos com parafuso
    b.append(f'<rect x="10" y="20" width="76" height="66" rx="8" fill="none" stroke="{METAL}" stroke-width="5"/>')
    for (x, y) in ((14, 24), (82, 24), (14, 82), (82, 82)):
        b.append(f'<rect x="{x - 7}" y="{y - 7}" width="14" height="14" rx="3" fill="{METAL_L}"/><circle cx="{x}" cy="{y}" r="2.4" fill="{METAL_D}"/>')
    # alça no topo
    b.append(f'<path d="M36,20 V10 H60 V20" stroke="{METAL_D}" stroke-width="5" fill="none" stroke-linejoin="round"/>')
    # placa da família (a FORMA muda por família) com o ícone
    if form == "espinhos":
        plate = "M48,30 L56,38 L66,36 L62,46 L68,54 L58,56 L54,66 L48,60 L42,66 L38,56 L28,54 L34,46 L30,36 L40,38 Z"
    elif form == "capsula":
        plate = rect_d(28, 34, 40, 30, 15)
    elif form == "cupula":
        plate = "M28,64 V48 C28,36 37,28 48,28 C59,28 68,36 68,48 V64 Z"
    elif form == "hexagono":
        plate = "M38,30 H58 L68,48 L58,66 H38 L28,48 Z"
    else:
        plate = "M48,28 L68,48 L48,68 L28,48 Z"
    b.append(f'<path d="{plate}" fill="#fff7ee"/>')
    b.append(f'<g transform="translate(33,33) scale(0.47)">{icon(ic, dark)}</g>')
    # "?" estampado no canto (a spell só aparece ao pegar)
    b.append(f'<text x="74" y="80" font-family="Fredoka, Arial" font-weight="700" font-size="20" fill="#fff7ee" text-anchor="middle">?</text>')
    return "".join(b)


# ---------------------------------------------------------------- spells (peças que o jogo anima)
def s01_canhao():
    """Punho Pneumático: tubo do pistão (preso na mão) — 128x64; a luva (s01_luva) é desenhada à parte e estica."""
    b = [shape("s1b", rect_d(8, 18, 78, 30, 8), "#d9622b", 11, (6, 16, 88, 50), k=2.0, dark="#9e3f17")]
    b.append(shape("s1c", rect_d(80, 14, 18, 38, 4), METAL, 12, (78, 12, 100, 54), k=2.0, dark=METAL_D))
    for x in (22, 38, 54):
        b.append(f'<rect x="{x}" y="18" width="6" height="30" fill="#9e3f17" opacity="0.55"/>')
    b.append(f'<circle cx="24" cy="54" r="8" fill="{METAL_D}"/><circle cx="24" cy="54" r="3" fill="{METAL_L}"/>')
    return b


def s01_luva():
    """Luva de boxe da ponta do braço de tesoura (aponta para a direita) — 64x50: punho de metal, luva, polegar e brilho."""
    b = [shape("s1k", rect_d(1, 14, 14, 22, 3), METAL, 13, (0, 12, 16, 38), k=1.6, dark=METAL_D)]
    body = "M14,12 C14,4 22,1 34,1 C52,1 63,10 63,25 C63,40 52,49 34,49 C22,49 14,46 14,38 Z"
    b.append(shape("s1l", body, "#e8503a", 14, (12, 0, 64, 50), k=2.0, dark="#a8301f", light="#ff8a6a"))
    b.append('<path d="M22,30 C22,24 30,22 38,25 C44,27 44,34 38,36 C32,38 24,37 22,30 Z" fill="#c93a2a"/>')
    b.append('<path d="M30,7 C40,5 52,9 57,17" stroke="#ffffff" stroke-width="3.4" fill="none" stroke-linecap="round" opacity="0.75"/>')
    b.append('<path d="M14,16 H18 M14,34 H18" stroke="#a8301f" stroke-width="3"/>')
    b.append(f'<circle cx="7" cy="25" r="3" fill="{METAL_L}"/>')
    return b


def s03_canhao():
    """Canhão Criogênico: tanque de gás + bico com gelo — 128x64."""
    b = [shape("s3t", rect_d(6, 10, 40, 44, 14), "#dfe9f2", 21, (4, 8, 48, 56), k=2.0, dark="#9fb3c4")]
    b.append(f'<rect x="14" y="20" width="24" height="7" rx="2" fill="{ICE_D}"/>')
    b.append(shape("s3c", rect_d(40, 20, 62, 22, 6), "#5f87b8", 22, (38, 18, 104, 44), k=2.0, dark="#3c5e8a"))
    b.append(shape("s3g", "M98,14 L120,20 L124,31 L120,42 L98,48 Z", ICE, 23, (96, 12, 126, 50), k=2.0, dark=ICE_D, light="#ffffff"))
    for (x, y) in ((104, 12), (114, 50), (122, 16)):
        b.append(f'<polygon points="{star_pts(x, y, 4, 5, 2)}" fill="#ffffff"/>')
    return b


def s03_projetil():
    b = [f'<polygon points="{star_pts(32, 32, 6, 26, 12, 0.3)}" fill="{ICE_D}"/>',
         f'<polygon points="{star_pts(32, 32, 6, 18, 8, 0.8)}" fill="{ICE}"/>',
         '<circle cx="32" cy="32" r="7" fill="#ffffff"/>']
    return b


def s03_gelo():
    """Faixa de gelo no chão (128x24): translúcida, borda clara e brilhos — o jogo estica na largura."""
    b = [shape("s3f", rect_d(2, 6, 124, 14, 6), ICE, 24, (0, 4, 128, 22), k=1.6, dark=ICE_D, light="#ffffff")]
    b.append('<path d="M10,9 H60 M74,9 H110" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>')
    return b


def s06_ima():
    """Superímã: ferradura com bobinas — 112x80 (polos à direita)."""
    d = "M20,8 H70 C92,8 104,22 104,40 C104,58 92,72 70,72 H20 V54 H70 C80,54 86,48 86,40 C86,32 80,26 70,26 H20 Z"
    b = [shape("s6", d, "#d94a5a", 31, (18, 6, 106, 74), k=2.0, dark="#9e2a3a", light="#ff8a96")]
    b.append(f'<rect x="8" y="8" width="16" height="18" rx="3" fill="{METAL_L}"/><rect x="8" y="54" width="16" height="18" rx="3" fill="{METAL_L}"/>')
    for x in (34, 44, 54):
        b.append(f'<path d="M{x},6 V28 M{x},52 V74" stroke="#f2c84b" stroke-width="4" stroke-linecap="round"/>')
    return b


def s10_tabua():
    """Andaime Relâmpago: deque (192x24) em 3 pedaços (o jogo desliza as abas): tábuas de madeira, ponteiras de
    metal, rodapé zebrado e parafusos. Cortado em terços pelo jogo."""
    b = [shape("s10a", rect_d(1, 1, 190, 16, 3), "#d9a05e", 41, (0, 0, 192, 18), k=1.6, dark="#8f5a2c", light="#f0c487")]
    for x in (64, 128):
        b.append(f'<rect x="{x - 1}" y="1" width="2" height="16" fill="#8f5a2c"/>')
    for x0 in (8, 72, 136):
        b.append(f'<path d="M{x0},6 C{x0 + 14},4 {x0 + 30},8 {x0 + 48},5 M{x0 + 4},12 C{x0 + 20},10 {x0 + 34},13 {x0 + 50},11" stroke="#b47a3e" stroke-width="1.4" fill="none"/>')
    b.append('<rect x="1" y="17" width="190" height="6" fill="#f2c84b"/>')
    for x in range(4, 190, 12):
        b.append(f'<path d="M{x},23 L{x + 6},17 L{x + 10},17 L{x + 4},23 Z" fill="{INK}"/>')
    for x0 in (0, 184):
        b.append(f'<rect x="{x0}" y="0" width="8" height="24" rx="2" fill="#71829a"/>')
    for x in (32, 96, 160):
        b.append(f'<circle cx="{x}" cy="9" r="2.2" fill="{METAL_L}"/>')
    return b


def s10_trouxa():
    """Andaime dobrado (a 'trouxa' que o robô arremessa) — 48x32: tábuas empilhadas, tubos e cinta amarela."""
    b = [shape("s10t", rect_d(4, 8, 40, 18, 3), "#d9a05e", 44, (2, 6, 46, 28), k=1.6, dark="#8f5a2c")]
    b.append('<path d="M2,10 L46,6 M2,26 L46,22" stroke="#71829a" stroke-width="4" stroke-linecap="round"/>')
    b.append('<rect x="20" y="4" width="8" height="26" rx="2" fill="#f2c84b"/>')
    b.append(f'<path d="M21,8 H27 M21,14 H27 M21,20 H27" stroke="{INK}" stroke-width="2"/>')
    return b


def s11_portal():
    """Teleporte de Manutenção: escotilha de bolso (anel zebrado + miolo azul em espiral) — 80x80."""
    b = []
    b.append(f'<circle cx="40" cy="40" r="36" fill="{INK}"/>')
    for k in range(12):
        a0, a1 = k * 30, k * 30 + 15
        r0, r1 = 36, 27
        p = []
        for a_, r_ in ((a0, r0), (a1, r0), (a1, r1), (a0, r1)):
            p.append(f"{40 + r_ * math.cos(math.radians(a_)):.1f},{40 + r_ * math.sin(math.radians(a_)):.1f}")
        b.append(f'<polygon points="{" ".join(p)}" fill="#f2c84b"/>')
    b.append('<circle cx="40" cy="40" r="26" fill="#3fc1c9"/>')
    for k in range(3):
        b.append(f'<path d="M40,40 m0,-{20 - k * 6} a{20 - k * 6},{20 - k * 6} 0 1,1 -{(20 - k * 6) * 0.8:.1f},{(20 - k * 6) * 0.6:.1f}" stroke="#bff6ff" stroke-width="3" fill="none" stroke-linecap="round"/>')
    b.append('<circle cx="40" cy="40" r="5" fill="#ffffff"/>')
    for (x, y) in ((40, 6), (74, 40), (40, 74), (6, 40)):
        b.append(f'<circle cx="{x}" cy="{y}" r="3.2" fill="{METAL_L}"/>')
    return b


def s13_frente():
    """Armadura Fornalha (frente): tronco de fornalha com VIGIA de vidro (o rosto do robô aparece nela), ombreiras,
    grelha de fogo e rebites — 150x130 (o jogo põe sobre o corpo do robô; pés em y≈130)."""
    b = []
    body = "M22,34 C22,22 32,14 46,14 H104 C118,14 128,22 128,34 V104 C128,116 120,124 108,124 H42 C30,124 22,116 22,104 Z"
    b.append(shape("a13f", body, "#7c5a4a", 61, (20, 12, 130, 126), k=2.4, dark="#4e372d", light="#a9806a"))
    # ombreiras
    for x0 in (4, 112):
        b.append(shape(f"a13o{x0}", rect_d(x0, 18, 34, 26, 10), "#5f4438", 62 + x0, (x0 - 2, 16, x0 + 36, 46), k=2.0, dark="#3d2b23"))
        b.append(f'<rect x="{x0 + 4}" y="22" width="26" height="6" rx="2" fill="#f2c84b"/>')
    # vigia (aro de latão + vidro escuro; o jogo desenha o rosto do robô dentro)
    b.append('<circle cx="75" cy="50" r="27" fill="#c9a03a"/><circle cx="75" cy="50" r="21" fill="#2b3d4f"/>')
    b.append('<path d="M60,40 C64,33 70,31 76,31" stroke="#ffffff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.7"/>')
    for k in range(8):
        a_ = k * math.pi / 4
        b.append(f'<circle cx="{75 + 24 * math.cos(a_):.1f}" cy="{50 + 24 * math.sin(a_):.1f}" r="2" fill="#7a5a1a"/>')
    # grelha de fogo
    b.append(shape("a13g", rect_d(44, 84, 62, 28, 6), INK, 63, (42, 82, 108, 114), k=1.8))
    b.append(f'<path d="M50,110 C52,96 60,100 62,90 C68,100 76,96 78,86 C84,98 92,96 100,110 Z" fill="{FIRE}"/>')
    b.append(f'<path d="M60,110 C62,102 68,104 70,96 C74,104 82,102 88,110 Z" fill="{FIRE_L}"/>')
    for x in range(50, 104, 10):
        b.append(f'<rect x="{x}" y="84" width="3" height="28" fill="#3d2b23"/>')
    for (x, y) in ((30, 26), (120, 26), (30, 116), (120, 116)):
        b.append(f'<circle cx="{x}" cy="{y}" r="3.4" fill="{METAL_L}"/>')
    return b


def s13_costas():
    """Armadura Fornalha (costas): tanque de carvão e chaminé soltando fumaça — 150x130."""
    b = [shape("a13c", rect_d(30, 20, 90, 96, 18), "#5f4438", 64, (28, 18, 122, 118), k=2.2, dark="#3d2b23")]
    b.append(shape("a13ch", rect_d(92, 0, 20, 30, 3), METAL_D, 65, (90, -2, 114, 32), k=1.8))
    b.append('<ellipse cx="102" cy="2" rx="12" ry="4" fill="#3d3340"/>')
    return b


def g10_capsula():
    """Carga Especial: cápsula com paraquedas listrado — 128x160 (cápsula embaixo)."""
    b = ['<path d="M8,60 C8,20 40,4 64,4 C88,4 120,20 120,60 Z" fill="#ffffff"/>']
    for k in range(4):
        x0 = 8 + k * 28
        b.append(f'<path d="M{x0 + 14},60 C{x0 + 14},30 {x0 + 20},10 {64},4 C{x0 + 6},14 {x0},34 {x0},60 Z" fill="#f08a3d" opacity="0.9"/>')
    b.append('<path d="M12,60 L52,112 M116,60 L76,112 M64,60 V112" stroke="#5a4a3a" stroke-width="2.5"/>')
    b.append(shape("g10", rect_d(40, 108, 48, 48, 12), "#f2c84b", 71, (38, 106, 90, 158), k=2.0, dark="#c49a2a"))
    b.append(f'<text x="64" y="143" font-family="Fredoka, Arial" font-weight="700" font-size="30" fill="{INK}" text-anchor="middle">★</text>')
    return b


# ---------------------------------------------------------------- Etapa 2 (ataque)
def s02_laser():
    """Laser de Corte: corpo de maçarico com aletas, lente incandescente na ponta — 128x64."""
    b = [shape("s2c", rect_d(8, 16, 76, 30, 8), "#4a5566", 81, (6, 14, 86, 48), k=2.0, dark="#2e3642", light="#71829a")]
    for x in (20, 30, 40, 50):
        b.append(f'<rect x="{x}" y="10" width="5" height="42" rx="2" fill="#71829a"/>')
    b.append(shape("s2b", rect_d(80, 22, 28, 18, 4), METAL, 82, (78, 20, 110, 42), k=1.6, dark=METAL_D))
    b.append('<circle cx="112" cy="31" r="12" fill="#c9a03a"/><circle cx="112" cy="31" r="8" fill="#ff5a3a"/>')
    b.append('<circle cx="109" cy="28" r="3" fill="#ffe2b0"/>')
    b.append(f'<rect x="12" y="44" width="14" height="16" rx="3" fill="{INK}"/>')
    b.append('<path d="M60,20 H74" stroke="#f2c84b" stroke-width="4" stroke-linecap="round"/>')
    return b


def s05_rebiteira():
    """Rebiteira Ricochete: pistola pneumática gorda — cilindro de aço, cabo de pistola, pente de rebites em cima,
    bico com mola e mangueira de ar — 128x64 (cabo em x≈40, bico em x≈124)."""
    b = []
    b.append('<path d="M14,34 C0,40 2,58 18,60 C26,61 30,56 34,54" stroke="#2e3642" stroke-width="6" fill="none" stroke-linecap="round"/>')
    b.append(shape("s5g", "M30,34 L50,34 L46,60 C46,62 44,63 42,63 L30,63 C28,63 27,61 27,59 Z", "#3e4752", 83, (26, 32, 52, 64), k=1.6, dark="#252b33"))
    b.append(shape("s5c", "M12,20 C12,12 18,9 26,9 H92 C100,9 104,14 104,22 V30 C104,38 100,40 92,40 H26 C18,40 12,36 12,30 Z",
               METAL, 84, (10, 7, 106, 42), k=2.0, dark=METAL_D, light=METAL_L))
    b.append('<rect x="20" y="16" width="70" height="7" rx="3" fill="#f08a3d"/>')
    b.append(shape("s5m", rect_d(46, 0, 34, 12, 3), "#3e4752", 85, (44, -2, 82, 14), k=1.4))
    for x in (53, 63, 73):
        b.append(f'<path d="M{x - 4},10 A4,4 0 0 1 {x + 4},10 Z" fill="#f2c84b"/>')
    b.append(shape("s5n", rect_d(102, 15, 14, 20, 3), "#f08a3d", 86, (100, 13, 118, 37), k=1.4, dark="#b05a20"))
    b.append(shape("s5t", rect_d(114, 19, 12, 12, 2), METAL_D, 87, (112, 17, 128, 33), k=1.2))
    b.append(f'<circle cx="122" cy="25" r="3" fill="{INK}"/>')
    for x in (30, 40):
        b.append(f'<circle cx="{x}" cy="30" r="2.4" fill="{METAL_D}"/>')
    return b


def s04_marreta():
    """Marreta Sísmica: cabeça de aço enorme com faixa zebrada, amortecedor de pistão e núcleo laranja aceso;
    cabo longo com fita — 64x128 (cabeça em cima, pega em (32,120))."""
    b = []
    b.append(shape("s4c", rect_d(27, 34, 10, 92, 4), "#8f5a2c", 91, (25, 32, 39, 128), k=1.6, dark="#5e3a1a"))
    for y in (98, 106, 114):
        b.append(f'<rect x="26" y="{y}" width="12" height="4" fill="#2a1a2e"/>')
    b.append(shape("s4p", rect_d(24, 26, 16, 14, 3), METAL_D, 92, (22, 24, 42, 42), k=1.4))
    b.append(shape("s4h", rect_d(2, 2, 60, 30, 7), "#4a5566", 93, (0, 0, 64, 34), k=2.2, dark="#2e3642", light="#71829a"))
    b.append('<rect x="2" y="12" width="60" height="9" fill="#f2c84b"/>')
    for x in range(4, 60, 10):
        b.append(f'<path d="M{x},21 L{x + 5},12 L{x + 9},12 L{x + 4},21 Z" fill="{INK}"/>')
    b.append('<rect x="0" y="4" width="6" height="26" rx="2" fill="#9aa4ae"/><rect x="58" y="4" width="6" height="26" rx="2" fill="#9aa4ae"/>')
    b.append('<circle cx="32" cy="7" r="4" fill="#ff8a3a"/><circle cx="32" cy="7" r="2" fill="#ffe2b0"/>')
    return b


def s18_disco():
    """Disco de Corte: serra circular com dentes, furo central e reflexo — 64x64."""
    pts = []
    for k in range(24):
        a = k * math.pi * 2 / 24
        r = 31 if k % 2 == 0 else 26
        pts.append(f"{32 + r * math.cos(a):.1f},{32 + r * math.sin(a):.1f}")
    b = [f'<polygon points="{" ".join(pts)}" fill="{METAL_D}"/>']
    b.append(shape("s18", ellipse_d(32, 32, 24, 24), METAL_L, 85, (6, 6, 58, 58), k=1.6, dark=METAL))
    b.append('<circle cx="32" cy="32" r="9" fill="#d9622b"/><circle cx="32" cy="32" r="4" fill="#2a1a2e"/>')
    b.append('<path d="M18,22 C22,15 30,12 38,13" stroke="#ffffff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>')
    return b


def s20_canhao():
    """Canhão de Molas: cano largo vermelho com boca de bumbo e janela mostrando a mola — 128x64."""
    b = [shape("s20", rect_d(6, 12, 92, 40, 10), "#d94a3a", 86, (4, 10, 100, 54), k=2.0, dark="#9e2a20", light="#ff8a6a")]
    b.append(shape("s20b", rect_d(94, 6, 28, 52, 8), "#f2c84b", 87, (92, 4, 124, 60), k=1.6, dark="#c49a2a"))
    b.append(f'<rect x="28" y="22" width="52" height="20" rx="4" fill="{INK}"/>')
    b.append('<path d="M32,32 L36,24 L40,40 L44,24 L48,40 L52,24 L56,40 L60,24 L64,40 L68,24 L72,40 L76,32" stroke="#c9d1d8" stroke-width="3" fill="none"/>')
    b.append(f'<rect x="16" y="50" width="16" height="12" rx="3" fill="{INK}"/>')
    return b


def s17_estaca():
    """Bate-Estaca: caixa do pistão (em cima) + estaca de aço com ponta zebrada — 64x192 (a estaca é esticada pelo jogo)."""
    b = [shape("s17h", rect_d(4, 2, 56, 46, 8), "#f2c84b", 88, (2, 0, 62, 50), k=2.0, dark="#c49a2a")]
    for x in range(6, 58, 12):
        b.append(f'<path d="M{x},40 L{x + 6},48 L{x + 12},48 L{x + 6},40 Z" fill="{INK}"/>')
    b.append('<circle cx="16" cy="14" r="4" fill="#d94a3a"/><circle cx="48" cy="14" r="4" fill="#d94a3a"/>')
    b.append(shape("s17p", rect_d(18, 46, 28, 120, 3), METAL, 89, (16, 44, 48, 168), k=1.8, dark=METAL_D, light=METAL_L))
    b.append(f'<rect x="22" y="60" width="4" height="96" fill="{METAL_L}"/>')
    b.append(shape("s17t", "M12,164 H52 L48,190 H16 Z", "#4a5566", 90, (10, 162, 54, 192), k=1.6, dark="#2e3642"))
    return b


# ---------------------------------------------------------------- Etapa 3 (controle e engenharia)
def s07_ventilador():
    """Turboventilador: motor com tanque, grade redonda na frente com hélice — 128x64 (cabo x≈30, bico x≈124)."""
    b = [shape("s7t", rect_d(6, 18, 40, 28, 8), "#3fa7c9", 101, (4, 16, 48, 48), k=1.8, dark="#2a7a96", light="#7fd3ea")]
    b.append(f'<rect x="22" y="44" width="14" height="18" rx="3" fill="{INK}"/>')
    b.append(shape("s7m", rect_d(42, 22, 30, 20, 4), METAL_D, 102, (40, 20, 74, 44), k=1.6))
    b.append(shape("s7g", ellipse_d(98, 32, 26, 30), METAL, 103, (70, 0, 126, 64), k=1.8, dark=METAL_D, light=METAL_L))
    b.append('<ellipse cx="100" cy="32" rx="20" ry="24" fill="#2e3642"/>')
    for k in range(3):
        a = k * 2.094
        b.append(f'<path d="M100,32 L{100 + 18 * math.cos(a):.1f},{32 + 22 * math.sin(a):.1f} L{100 + 18 * math.cos(a + 0.7):.1f},{32 + 22 * math.sin(a + 0.7):.1f} Z" fill="#c9d1d8"/>')
    b.append('<circle cx="100" cy="32" r="5" fill="#f2c84b"/>')
    for x in (82, 92, 108, 118):
        b.append(f'<path d="M{x},6 V58" stroke="{METAL_L}" stroke-width="2" opacity="0.7"/>')
    return b


def s08_gancho():
    """Gancho de Arrasto: lançador com carretel de corrente e garra de 3 dentes na ponta — 128x64."""
    b = [shape("s8b", rect_d(10, 18, 70, 24, 6), "#8a63d2", 104, (8, 16, 82, 44), k=1.8, dark="#5e3fa0", light="#b59cff")]
    b.append(f'<rect x="26" y="40" width="14" height="20" rx="3" fill="{INK}"/>')
    b.append(shape("s8c", ellipse_d(38, 22, 13, 13), METAL_D, 105, (24, 8, 52, 36), k=1.4))
    b.append('<circle cx="38" cy="22" r="5" fill="#c9d1d8"/>')
    b.append(shape("s8p", rect_d(78, 24, 20, 12, 2), METAL, 106, (76, 22, 100, 38), k=1.4, dark=METAL_D))
    b.append(f'<path d="M98,30 L116,30 M108,30 L124,16 M108,30 L124,44 M110,30 L126,30" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>')
    b.append(f'<path d="M98,30 L116,30 M108,30 L124,16 M108,30 L124,44 M110,30 L126,30" stroke="{METAL_L}" stroke-width="3.5" stroke-linecap="round"/>')
    return b


def s21_laco():
    """Laço de Energia: emissor roxo com 3 bobinas de cobre e cristal ciano aceso na ponta — 128x64."""
    b = [shape("s21h", rect_d(8, 20, 70, 24, 7), "#5e3fa0", 107, (6, 18, 80, 46), k=1.8, dark="#3d2870", light="#8a63d2")]
    b.append(f'<rect x="22" y="42" width="14" height="20" rx="3" fill="{INK}"/>')
    for x in (44, 56, 68):
        b.append(f'<rect x="{x}" y="14" width="8" height="36" rx="3" fill="#c9853a"/><rect x="{x + 2}" y="14" width="2" height="36" fill="#f0b46a"/>')
    b.append(shape("s21p", rect_d(76, 24, 22, 16, 3), METAL, 108, (74, 22, 100, 42), k=1.4, dark=METAL_D))
    b.append('<polygon points="98,32 110,20 124,32 110,44" fill="#3fc1c9"/><polygon points="102,32 110,24 118,32 110,40" fill="#bff6ff"/>')
    b.append('<circle cx="110" cy="32" r="3" fill="#ffffff"/>')
    b.append('<path d="M14,26 H40" stroke="#bff6ff" stroke-width="3" stroke-linecap="round" opacity="0.8"/>')
    return b


def s12_carga():
    """Carga de Demolição: maleta de dinamite com ímã embaixo, luz e antena — 64x48."""
    b = [shape("s12", rect_d(4, 12, 56, 30, 5), "#4a5566", 109, (2, 10, 62, 44), k=1.8, dark="#2e3642", light="#71829a")]
    for i, x in enumerate((10, 22, 34)):
        b.append(shape(f"s12d{i}", rect_d(x, 16, 10, 22, 3), "#d14d35", 110 + i, (x - 2, 14, x + 12, 40), k=1.2))
    b.append('<rect x="8" y="24" width="38" height="6" fill="#2a1a2e"/>')
    b.append('<rect x="48" y="16" width="8" height="10" rx="2" fill="#2a1a2e"/><circle cx="52" cy="21" r="3" fill="#ff5a3a"/>')
    b.append(f'<path d="M52,16 L56,2" stroke="{INK}" stroke-width="2.5"/><circle cx="56" cy="2" r="2.4" fill="#f2c84b"/>')
    b.append(f'<rect x="10" y="40" width="44" height="6" rx="2" fill="{METAL_D}"/>')
    return b


def s27_controle():
    """Controle Remoto Industrial: caixa amarela, 2 botões grandes, antena com bolinha — 48x64."""
    b = [shape("s27", rect_d(6, 18, 36, 44, 6), "#f2c84b", 112, (4, 16, 44, 64), k=1.8, dark="#c49a2a")]
    b.append('<rect x="12" y="24" width="24" height="12" rx="2" fill="#2e3d4f"/><path d="M15,30 L33,30" stroke="#5cc45c" stroke-width="2"/>')
    b.append('<circle cx="17" cy="46" r="5" fill="#d94a3a"/><circle cx="31" cy="46" r="5" fill="#3c9a46"/>')
    b.append(f'<path d="M34,18 L40,2" stroke="{INK}" stroke-width="3"/><circle cx="40" cy="2" r="3" fill="#d94a3a"/>')
    for x in (12, 24, 36):
        b.append(f'<rect x="{x - 2}" y="54" width="4" height="4" fill="{INK}"/>')
    return b


def s28_placa():
    """(antiga, mantida para a prancha) chapa simples — 48x96."""
    return [shape("s28", rect_d(2, 2, 44, 92, 4), METAL, 113, (0, 0, 48, 96), k=2.0, dark=METAL_D, light=METAL_L)]


def s28_painel():
    """Escudo de Solda: painel de aço (3 empilhados formam o muro) — 64x40: moldura grossa, chapa com X de reforço,
    parafusos nos cantos e um amassado; o jogo desenha o cordão de solda entre os painéis."""
    b = [shape("s28f", rect_d(1, 1, 62, 38, 4), "#4a5566", 117, (0, 0, 64, 40), k=1.8, dark="#2e3642", light="#71829a")]
    b.append(shape("s28c", rect_d(7, 6, 50, 28, 2), METAL, 118, (6, 5, 58, 35), k=1.8, dark=METAL_D, light=METAL_L))
    b.append(f'<path d="M9,8 L55,32 M55,8 L9,32" stroke="{METAL_D}" stroke-width="5" stroke-linecap="round"/>')
    b.append(f'<path d="M9,8 L55,32 M55,8 L9,32" stroke="{METAL_L}" stroke-width="1.6" stroke-linecap="round"/>')
    for (x, y) in ((5, 5), (59, 5), (5, 35), (59, 35)):
        b.append(f'<circle cx="{x}" cy="{y}" r="2.8" fill="#f2c84b"/><circle cx="{x}" cy="{y}" r="1.1" fill="{INK}"/>')
    b.append('<path d="M40,12 C44,14 46,18 44,22" stroke="#6b7783" stroke-width="2" fill="none"/>')
    return b


def s28_topo():
    """Topo do muro (64x16): faixa zebrada de aviso com cantoneiras."""
    b = [shape("s28t", rect_d(1, 2, 62, 12, 2), "#f2c84b", 119, (0, 0, 64, 16), k=1.6, dark="#c49a2a")]
    for x in range(2, 62, 10):
        b.append(f'<path d="M{x},14 L{x + 6},2 L{x + 10},2 L{x + 4},14 Z" fill="{INK}"/>')
    b.append(f'<rect x="0" y="0" width="6" height="16" rx="1" fill="#4a5566"/><rect x="58" y="0" width="6" height="16" rx="1" fill="#4a5566"/>')
    return b


def s28_macarico():
    """Maçarico de solda (o robô segura antes de usar) — 64x32."""
    b = [shape("s28m", rect_d(4, 10, 34, 12, 4), "#3e4752", 114, (2, 8, 40, 24), k=1.4)]
    b.append(shape("s28b", rect_d(36, 12, 18, 8, 2), METAL, 115, (34, 10, 56, 22), k=1.2, dark=METAL_D))
    b.append('<path d="M54,16 L62,16" stroke="#3fc1c9" stroke-width="4" stroke-linecap="round"/>')
    b.append('<path d="M8,22 C4,30 14,32 18,28" stroke="#d94a3a" stroke-width="3" fill="none"/>')
    return b


def s25_tabua():
    """Ponte Dobrável: segmento de ponte (64x20) com guarda-corpo zebrado e dobradiça."""
    b = [shape("s25", rect_d(1, 6, 62, 12, 2), "#71829a", 116, (0, 4, 64, 20), k=1.6, dark="#4a5566", light="#9aa4ae")]
    for x in range(4, 62, 8):
        b.append(f'<rect x="{x}" y="9" width="4" height="6" fill="#4a5566"/>')
    b.append('<rect x="0" y="0" width="64" height="5" fill="#f2c84b"/>')
    for x in range(2, 62, 10):
        b.append(f'<path d="M{x},5 L{x + 5},0 L{x + 8},0 L{x + 3},5 Z" fill="{INK}"/>')
    b.append(f'<circle cx="2" cy="12" r="3" fill="{METAL_L}"/><circle cx="62" cy="12" r="3" fill="{METAL_L}"/>')
    return b


# ---------------------------------------------------------------- Etapa 4 (transformações)
def s14_chassi():
    """Mecha Empilhadeira: carroceria amarela (o robô vai na cabine), contrapeso atrás, 2 rodas — 128x80
    (frente para a direita; rodas no chão em y≈80)."""
    b = [shape("s14c", "M10,30 C10,24 14,20 20,20 H70 L86,40 H110 C116,40 120,44 120,50 V62 H10 Z", "#f2c84b", 121, (8, 18, 122, 64), k=2.0, dark="#c49a2a", light="#ffe08a")]
    b.append(shape("s14p", rect_d(2, 26, 22, 34, 6), "#4a5566", 122, (0, 24, 26, 62), k=1.8, dark="#2e3642"))
    for x in range(26, 70, 10):
        b.append(f'<path d="M{x},62 L{x + 5},52 L{x + 9},52 L{x + 4},62 Z" fill="{INK}"/>')
    b.append(f'<path d="M24,20 V4 H62 V20" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>')
    b.append(f'<path d="M24,20 V4 H62 V20" stroke="#3e4752" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
    for (cx, r) in ((30, 15), (98, 13)):
        b.append(f'<circle cx="{cx}" cy="{64}" r="{r}" fill="{INK}"/><circle cx="{cx}" cy="64" r="{r - 5}" fill="#71829a"/><circle cx="{cx}" cy="64" r="3" fill="#f2c84b"/>')
    b.append('<rect x="104" y="44" width="10" height="6" rx="2" fill="#ffffff" opacity="0.8"/>')
    return b


def s14_garfo():
    """Mastro + garfos da empilhadeira — 48x96 (garfo embaixo apontando para a direita)."""
    b = [shape("s14m", rect_d(4, 2, 14, 90, 3), "#4a5566", 123, (2, 0, 20, 94), k=1.6, dark="#2e3642")]
    b.append(shape("s14k", rect_d(14, 70, 32, 10, 2), METAL, 124, (12, 68, 48, 82), k=1.4, dark=METAL_D, light=METAL_L))
    b.append(shape("s14k2", rect_d(14, 84, 32, 8, 2), METAL, 125, (12, 82, 48, 94), k=1.4, dark=METAL_D))
    for y in (14, 30, 46):
        b.append(f'<rect x="6" y="{y}" width="10" height="4" fill="#f2c84b"/>')
    return b


def s15_bola():
    """Bola de Demolição: esfera de aço em gomos, faixa zebrada e rebites — 96x96 (o jogo gira)."""
    b = [shape("s15", ellipse_d(48, 48, 44, 44), "#71829a", 126, (2, 2, 94, 94), k=2.2, dark="#4a5566", light="#9aa4ae")]
    b.append('<path d="M48,4 C30,24 30,72 48,92 M48,4 C66,24 66,72 48,92 M6,48 H90" stroke="#4a5566" stroke-width="3" fill="none"/>')
    b.append('<path d="M8,40 H88 V56 H8 Z" fill="#f2c84b"/>')
    for x in range(8, 88, 12):
        b.append(f'<path d="M{x},56 L{x + 7},40 L{x + 11},40 L{x + 4},56 Z" fill="{INK}"/>')
    for (x, y) in ((48, 14), (48, 82), (22, 26), (74, 26), (22, 70), (74, 70)):
        b.append(f'<circle cx="{x}" cy="{y}" r="3.2" fill="{METAL_L}"/>')
    b.append('<path d="M24,18 C30,12 38,9 46,9" stroke="#ffffff" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.6"/>')
    return b


def s16_mochila():
    """Propulsor Gambiarra: barril remendado com fita prateada, 2 bicos de escape e mangueira — 64x72."""
    b = [shape("s16", rect_d(10, 6, 40, 50, 10), "#d94a3a", 127, (8, 4, 52, 58), k=2.0, dark="#9e2a20", light="#ff8a6a")]
    b.append('<path d="M10,20 L50,26 M14,40 L48,34" stroke="#c9d1d8" stroke-width="7" opacity="0.95"/>')
    b.append(f'<path d="M10,20 L50,26 M14,40 L48,34" stroke="{METAL_D}" stroke-width="1.2" stroke-dasharray="3 3"/>')
    for x in (16, 36):
        b.append(shape(f"s16n{x}", f"M{x},54 H{x + 12} L{x + 14},68 H{x - 2} Z", "#4a5566", 128 + x, (x - 3, 52, x + 16, 70), k=1.4, dark="#2e3642"))
    b.append('<path d="M50,14 C60,14 62,28 56,34" stroke="#3e4752" stroke-width="4" fill="none"/>')
    b.append('<rect x="24" y="0" width="12" height="8" rx="2" fill="#f2c84b"/>')
    return b


def s31_broca():
    """Modo Broca: cone de perfuração com sulcos em espiral e colar laranja — 96x64 (ponta à direita)."""
    b = [shape("s31b", rect_d(2, 10, 22, 44, 4), "#f08a3d", 129, (0, 8, 26, 56), k=1.6, dark="#b05a20")]
    b.append(shape("s31c", "M22,8 L94,32 L22,56 Z", METAL, 130, (20, 6, 96, 58), k=2.0, dark=METAL_D, light=METAL_L))
    for k in range(5):
        x0 = 28 + k * 13
        b.append(f'<path d="M{x0},{12 + k * 4} L{x0 + 12},{52 - k * 4}" stroke="{METAL_D}" stroke-width="3"/>')
    return b


def s31_esteira():
    """Esteira (lagarta) da broca — 112x28."""
    b = [shape("s31e", rect_d(2, 4, 108, 22, 11), "#3e4752", 131, (0, 2, 112, 28), k=1.6, dark="#252b33")]
    for x in (16, 40, 64, 88):
        b.append(f'<circle cx="{x}" cy="15" r="7" fill="#71829a"/><circle cx="{x}" cy="15" r="2.5" fill="#f2c84b"/>')
    return b


def s33_mascara():
    """Modo Soldador: máscara de solda com visor escuro e dobradiça — 56x48."""
    b = [shape("s33", "M6,10 C6,4 12,2 28,2 C44,2 50,4 50,10 V38 C50,44 44,46 28,46 C12,46 6,44 6,38 Z", "#3e4752", 132, (4, 0, 52, 48), k=1.8, dark="#252b33", light="#5a6370")]
    b.append('<rect x="12" y="14" width="32" height="14" rx="3" fill="#1a2a1a"/><rect x="14" y="16" width="28" height="4" fill="#3c9a46" opacity="0.6"/>')
    b.append('<circle cx="6" cy="22" r="4" fill="#f2c84b"/><circle cx="50" cy="22" r="4" fill="#f2c84b"/>')
    return b


# ---------------------------------------------------------------- Etapa 4 refeita: ARMADURAS (o robô veste a máquina)
# Mesmo molde da Fornalha (150x130, janela do rosto centrada em (75,50)); o jogo põe sobre o corpo e desenha o rosto.
def _ombreiras(cor, dark, seed, faixa="#f2c84b"):
    b = []
    for x0 in (4, 112):
        b.append(shape(f"om{seed}{x0}", rect_d(x0, 18, 34, 26, 10), cor, seed + x0, (x0 - 2, 16, x0 + 36, 46), k=2.0, dark=dark))
        b.append(f'<rect x="{x0 + 4}" y="22" width="26" height="6" rx="2" fill="{faixa}"/>')
    return b


def a14_frente():
    """Mecha Empilhadeira (frente): cabine amarela com SANTO-ANTÔNIO (barras) e janela retangular para o rosto,
    luzes de alerta, faixa zebrada embaixo — 150x130."""
    b = []
    body = "M20,30 C20,20 28,14 40,14 H110 C122,14 130,20 130,30 V108 C130,118 122,124 112,124 H38 C28,124 20,118 20,108 Z"
    b.append(shape("a14f", body, "#f2c84b", 141, (18, 12, 132, 126), k=2.4, dark="#c49a2a", light="#ffe08a"))
    b += _ombreiras("#4a5566", "#2e3642", 142, "#f2c84b")
    b.append(f'<rect x="47" y="32" width="56" height="36" rx="5" fill="{INK}"/><rect x="51" y="36" width="48" height="28" rx="3" fill="#2b3d4f"/>')
    b.append('<path d="M56,40 L66,34" stroke="#ffffff" stroke-width="3" opacity="0.6" stroke-linecap="round"/>')
    b.append(f'<path d="M40,72 V10 H110 V72" stroke="{INK}" stroke-width="8" fill="none" stroke-linejoin="round"/>')
    b.append('<path d="M40,72 V10 H110 V72" stroke="#3e4752" stroke-width="4" fill="none" stroke-linejoin="round"/>')
    b.append('<circle cx="75" cy="6" r="6" fill="#ff8a3a"/><circle cx="75" cy="6" r="3" fill="#fff1b8"/>')
    b.append('<rect x="24" y="96" width="102" height="14" fill="#f2c84b"/>')
    for x in range(24, 124, 12):
        b.append(f'<path d="M{x},110 L{x + 7},96 L{x + 11},96 L{x + 4},110 Z" fill="{INK}"/>')
    for (x, y) in ((30, 82), (120, 82)):
        b.append(f'<circle cx="{x}" cy="{y}" r="3.4" fill="{METAL_L}"/>')
    return b


def a14_costas():
    """Mecha Empilhadeira (costas): contrapeso de aço com escape — 150x130."""
    b = [shape("a14c", rect_d(26, 22, 98, 96, 16), "#4a5566", 143, (24, 20, 126, 120), k=2.2, dark="#2e3642")]
    b.append('<rect x="34" y="70" width="82" height="12" fill="#f2c84b"/>')
    b.append(shape("a14e", rect_d(100, 0, 14, 28, 3), METAL_D, 144, (98, -2, 116, 30), k=1.6))
    return b


def a14_mastro():
    """Mastro da empilhadeira com trilhos e correntes — 40x120 (o garfo é desenhado pelo jogo e sobe nele)."""
    b = [shape("a14m", rect_d(4, 2, 32, 116, 4), "#4a5566", 145, (2, 0, 38, 120), k=1.8, dark="#2e3642", light="#71829a")]
    b.append(f'<rect x="12" y="6" width="16" height="108" fill="{INK}"/>')
    b.append('<path d="M16,8 V112 M24,8 V112" stroke="#9aa4ae" stroke-width="2" stroke-dasharray="4 3"/>')
    for y in (20, 60, 100):
        b.append(f'<rect x="4" y="{y}" width="32" height="5" fill="#f2c84b"/>')
    return b


def a31_frente():
    """Modo Broca (frente): placas laranja pesadas, vigia redonda com aro de aço, grade de ventilação — 150x130."""
    b = []
    body = "M22,34 C22,22 32,14 46,14 H104 C118,14 128,22 128,34 V104 C128,116 120,124 108,124 H42 C30,124 22,116 22,104 Z"
    b.append(shape("a31f", body, "#f08a3d", 146, (20, 12, 130, 126), k=2.4, dark="#b05a20", light="#ffb27a"))
    b += _ombreiras("#71829a", "#4a5566", 147)
    b.append('<circle cx="75" cy="50" r="27" fill="#9aa4ae"/><circle cx="75" cy="50" r="21" fill="#2b3d4f"/>')
    for k in range(6):
        a_ = k * math.pi / 3
        b.append(f'<circle cx="{75 + 24 * math.cos(a_):.1f}" cy="{50 + 24 * math.sin(a_):.1f}" r="2.2" fill="#4a5566"/>')
    for y in (88, 98, 108):
        b.append(f'<rect x="46" y="{y}" width="58" height="5" rx="2" fill="#7a3a10"/>')
    return b


def a31_costas():
    """Modo Broca (costas): motor com 2 pistões e cano de escape soltando fumaça — 150x130."""
    b = [shape("a31c", rect_d(30, 22, 90, 90, 14), "#4a5566", 148, (28, 20, 122, 114), k=2.2, dark="#2e3642")]
    for x in (48, 84):
        b.append(shape(f"a31p{x}", rect_d(x, 4, 18, 26, 4), METAL, 149 + x, (x - 2, 2, x + 20, 32), k=1.4, dark=METAL_D))
    b.append(shape("a31e", rect_d(108, 0, 12, 34, 3), METAL_D, 150, (106, -2, 122, 36), k=1.4))
    return b


def a31_braco():
    """Broca que vira o braço: colar laranja + cone com sulcos — 112x56 (pega à esquerda, ponta à direita)."""
    b = [shape("a31k", rect_d(2, 10, 28, 36, 6), "#f08a3d", 151, (0, 8, 32, 48), k=1.6, dark="#b05a20")]
    b.append(f'<rect x="26" y="14" width="8" height="28" fill="{INK}"/>')
    b.append(shape("a31b", "M32,6 L110,28 L32,50 Z", METAL, 152, (30, 4, 112, 52), k=2.0, dark=METAL_D, light=METAL_L))
    return b


def a33_frente():
    """Modo Soldador (frente): peito de aço azulado, capacete com VISOR de solda verde (o rosto aparece escurecido),
    protetor de couro marrom no peito — 150x130."""
    b = []
    body = "M22,34 C22,20 34,10 50,10 H100 C116,10 128,20 128,34 V104 C128,116 120,124 108,124 H42 C30,124 22,116 22,104 Z"
    b.append(shape("a33f", body, "#4f6a8a", 153, (20, 8, 130, 126), k=2.4, dark="#334a66", light="#7894b4"))
    b += _ombreiras("#3e4752", "#252b33", 154, "#f08a3d")
    b.append(f'<rect x="44" y="30" width="62" height="40" rx="8" fill="{INK}"/><rect x="49" y="35" width="52" height="30" rx="5" fill="#1d3a22"/>')
    b.append(shape("a33a", rect_d(40, 78, 70, 40, 8), "#8f5a2c", 155, (38, 76, 112, 120), k=1.8, dark="#5e3a1a"))
    b.append('<path d="M46,84 H104" stroke="#5e3a1a" stroke-width="2" stroke-dasharray="4 3"/>')
    b.append('<circle cx="40" cy="50" r="5" fill="#f2c84b"/><circle cx="110" cy="50" r="5" fill="#f2c84b"/>')
    return b


def a33_costas():
    """Modo Soldador (costas): 2 cilindros de gás (oxigênio verde e acetileno vermelho) com válvulas — 150x130."""
    b = []
    for x, cor, dk in ((40, "#3c9a46", "#256a2e"), (80, "#d94a3a", "#9e2a20")):
        b.append(shape(f"a33c{x}", rect_d(x, 16, 32, 100, 14), cor, 156 + x, (x - 2, 14, x + 34, 118), k=2.0, dark=dk))
        b.append(f'<rect x="{x + 10}" y="6" width="12" height="12" rx="2" fill="{METAL}"/>')
    return b


def a33_tocha():
    """Maçarico grande que vira o braço do soldador — 96x40 (pega à esquerda, bico à direita)."""
    b = [shape("a33t", rect_d(2, 12, 44, 16, 6), "#3e4752", 157, (0, 10, 48, 30), k=1.6)]
    b.append(shape("a33b", rect_d(44, 14, 32, 12, 3), METAL, 158, (42, 12, 78, 28), k=1.4, dark=METAL_D, light=METAL_L))
    b.append(shape("a33n", "M76,15 L94,18 L94,22 L76,25 Z", "#c9a03a", 159, (74, 13, 96, 27), k=1.2))
    b.append('<path d="M10,28 C6,36 18,38 24,32" stroke="#d94a3a" stroke-width="3" fill="none"/>')
    return b


def a34_raio():
    """Minirrobô: raio encolhedor (prato parabólico + bobina + gatilho) — 72x48."""
    b = [shape("a34", rect_d(4, 16, 36, 18, 5), "#8a63d2", 160, (2, 14, 42, 36), k=1.6, dark="#5e3fa0")]
    b.append(f'<rect x="12" y="32" width="10" height="14" rx="2" fill="{INK}"/>')
    b.append(shape("a34d", "M40,25 C48,8 64,6 70,4 V46 C64,44 48,42 40,25 Z", METAL_L, 161, (38, 2, 72, 48), k=1.4, dark=METAL))
    b.append('<circle cx="52" cy="25" r="4" fill="#3fc1c9"/><path d="M52,25 L68,25" stroke="#3fc1c9" stroke-width="2"/>')
    return b


def a16_jato():
    """Jetpack: 2 tanques de foguete presos por cintas, bicos embaixo, aletas e manômetro — 72x84."""
    b = []
    for x in (8, 38):
        b.append(shape(f"a16t{x}", rect_d(x, 10, 26, 54, 12), "#d94a3a", 162 + x, (x - 2, 8, x + 28, 66), k=2.0, dark="#9e2a20", light="#ff8a6a"))
        b.append(f'<path d="M{x + 2},70 H{x + 24} L{x + 20},82 H{x + 6} Z" fill="#3e4752"/>')
        b.append(f'<rect x="{x + 4}" y="16" width="6" height="40" rx="3" fill="#ffffff" opacity="0.35"/>')
    b.append(f'<rect x="4" y="30" width="64" height="8" fill="{METAL_D}"/><rect x="30" y="0" width="12" height="12" rx="6" fill="#f2c84b"/>')
    b.append(f'<path d="M36,6 L39,3" stroke="{INK}" stroke-width="2"/>')
    for x in (4, 64):
        b.append(f'<path d="M{x},50 L{x - 4 if x < 30 else x + 4},64 L{x},64 Z" fill="#3e4752"/>')
    return b


# ---------------------------------------------------------------- Etapa 5 (eventos globais)
def _parafusos(pts, r=3.2, col=None):
    col = col or METAL_D
    return "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{col}"/><circle cx="{x - 0.8}" cy="{y - 0.8}" r="{r * 0.4}" fill="{METAL_L}"/>' for x, y in pts)


def g02_exaustor():
    """Ventania: carcaça de exaustor industrial (quadrada, aro zebrado, grade redonda) — 160x160; a hélice gira à parte."""
    b = [shape("g2a", rect_d(6, 6, 148, 148, 18), "#4a5566", 201, (4, 4, 156, 156), k=2.2, dark="#2e3642", light="#71829a")]
    b.append(f'<circle cx="80" cy="80" r="66" fill="#f2c84b"/>')
    for k in range(16):
        a = k * math.tau / 16
        b.append(f'<path d="M{80 + 58 * math.cos(a):.1f},{80 + 58 * math.sin(a):.1f} L{80 + 66 * math.cos(a + 0.22):.1f},{80 + 66 * math.sin(a + 0.22):.1f} '
                 f'L{80 + 66 * math.cos(a + 0.42):.1f},{80 + 66 * math.sin(a + 0.42):.1f} L{80 + 58 * math.cos(a + 0.2):.1f},{80 + 58 * math.sin(a + 0.2):.1f} Z" fill="{INK}"/>')
    b.append(f'<circle cx="80" cy="80" r="57" fill="#232a33"/>')
    b.append(_parafusos([(20, 20), (140, 20), (20, 140), (140, 140)], 5))
    return b


def g02_grade():
    """Grade da frente do exaustor (desenhada por cima da hélice) — 160x160."""
    b = []
    for r in (18, 34, 50):
        b.append(f'<circle cx="80" cy="80" r="{r}" fill="none" stroke="{METAL}" stroke-width="3.2"/>')
    b.append(f'<path d="M80,24 V136 M24,80 H136" stroke="{METAL}" stroke-width="3.2"/>')
    b.append(f'<circle cx="80" cy="80" r="11" fill="{METAL_D}"/><circle cx="77" cy="77" r="4" fill="{METAL_L}"/>')
    return b


def g02_helice():
    """Hélice do exaustor: 5 pás gordinhas — 128x128 (o jogo gira)."""
    b = []
    for k in range(5):
        a = k * 72
        b.append(f'<g transform="rotate({a} 64 64)">' + shape(f"g2h{k}", "M64,64 C58,40 60,14 76,8 C96,4 98,30 84,48 C78,56 70,60 64,64 Z",
                 "#c9d1d8", 210 + k, (54, 2, 100, 66), k=1.6, dark="#8d98a4") + '</g>')
    b.append(f'<circle cx="64" cy="64" r="12" fill="{METAL_D}"/>')
    return b


def g04_bobina():
    """Sobrecarga Magnética: bobina de Tesla de obra — base de aço zebrada, núcleo de cobre enrolado, cúpula
    com esfera — 112x160 (pés embaixo)."""
    b = [shape("g4b", rect_d(8, 128, 96, 30, 6), "#4a5566", 220, (6, 126, 106, 160), k=1.8, dark="#2e3642", light="#71829a")]
    for k in range(6):
        b.append(f'<path d="M{14 + k * 16},{132} l8,0 l-8,22 l-8,0 Z" fill="#f2c84b" opacity="0.95"/>')
    b.append(shape("g4c", rect_d(26, 48, 60, 84, 10), "#c9733a", 221, (24, 46, 88, 134), k=1.8, dark="#8e4a22", light="#f0a066"))
    for y in range(54, 128, 9):
        b.append(f'<path d="M26,{y} C40,{y + 5} 72,{y + 5} 86,{y}" stroke="#7a3a18" stroke-width="2.6" fill="none"/>')
        b.append(f'<path d="M30,{y + 3} C44,{y + 6} 66,{y + 6} 80,{y + 3}" stroke="#ffc08a" stroke-width="1.2" fill="none" opacity="0.7"/>')
    b.append(shape("g4t", "M14,52 C14,36 34,30 56,30 C78,30 98,36 98,52 C98,58 80,60 56,60 C32,60 14,58 14,52 Z", METAL, 222, (12, 28, 100, 62), k=1.8, dark=METAL_D, light=METAL_L))
    b.append(f'<rect x="52" y="12" width="8" height="22" fill="{METAL_D}"/>')
    b.append(f'<circle cx="56" cy="14" r="12" fill="#8a63d2"/><circle cx="52" cy="10" r="4" fill="#d9c8ff"/>')
    b.append(f'<path d="M40,96 l12,-14 l-2,10 l10,-2 l-12,16 l2,-10 Z" fill="#f2c84b" stroke="{INK}" stroke-width="1.5"/>')
    return b


def g05_carga():
    """Operação Guindaste: fardo de 3 vigas I pintadas, amarradas com 2 cintas amarelas — 256x56 (topo = piso)."""
    b = []
    for i, (y, h) in enumerate(((2, 18), (20, 16), (36, 16))):
        x0 = 4 + (i % 2) * 6
        b.append(shape(f"g5v{i}", rect_d(x0, y, 248 - (i % 2) * 12, h, 3), "#d9643a", 230 + i, (x0 - 2, y - 2, 254, y + h + 2), k=1.8, dark="#9e3f17", light="#f08a5d"))
        b.append(f'<rect x="{x0 + 4}" y="{y + h / 2 - 2:.0f}" width="{236 - (i % 2) * 12}" height="4" fill="#9e3f17" opacity="0.6"/>')
    for x in (52, 188):
        b.append(shape(f"g5c{x}", rect_d(x, 0, 16, 56, 3), "#f2c84b", 235 + x, (x - 2, -2, x + 18, 58), k=1.4, dark="#c49a2a"))
        b.append(f'<rect x="{x + 3}" y="24" width="10" height="8" rx="2" fill="{METAL_D}"/>')
    return b


def g05_moitao():
    """Moitão do guindaste: caixa amarela com roldana, giroflex laranja em cima e gancho embaixo — 80x112."""
    b = [f'<rect x="34" y="0" width="12" height="18" fill="{METAL_D}"/>']
    b.append(shape("g5m", rect_d(10, 14, 60, 56, 10), "#f2c84b", 240, (8, 12, 72, 72), k=1.8, dark="#c49a2a", light="#ffe28a"))
    b.append(f'<circle cx="40" cy="40" r="17" fill="{METAL_D}"/><circle cx="40" cy="40" r="11" fill="{METAL}"/><circle cx="40" cy="40" r="4" fill="{INK}"/>')
    b.append(_parafusos([(18, 22), (62, 22), (18, 62), (62, 62)], 3))
    for k in range(4):
        b.append(f'<path d="M{12 + k * 16},66 l8,0 l-6,6 l-8,0 Z" fill="{INK}"/>')
    b.append(f'<rect x="35" y="70" width="10" height="12" fill="{METAL_D}"/>')
    b.append(shape("g5g", "M40,80 C54,80 58,92 56,100 C54,110 40,112 32,106 L38,100 C42,104 48,102 48,96 C48,90 44,88 40,88 Z", METAL, 241, (30, 78, 60, 112), k=1.4, dark=METAL_D, light=METAL_L))
    return b


def g06_caixa():
    """Entrega de Entulho: engradado de madeira cheio de tijolos — 64x56."""
    b = []
    for i, x in enumerate((8, 22, 36)):
        b.append(shape(f"g6t{i}", rect_d(x, 2 + (i % 2) * 4, 18, 12, 2), "#c4573a", 250 + i, (x - 2, 0, x + 20, 20), k=1.2, dark="#8e3420"))
    b.append(shape("g6c", rect_d(2, 12, 60, 42, 4), "#c98a4b", 253, (0, 10, 64, 56), k=1.6, dark="#8a5a2b", light="#e8b27a"))
    for y in (22, 34, 46):
        b.append(f'<path d="M4,{y} H60" stroke="#8a5a2b" stroke-width="2"/>')
    b.append(f'<path d="M6,16 L58,52 M58,16 L6,52" stroke="#a8703a" stroke-width="5" stroke-linecap="round"/>')
    for (x, y) in ((2, 12), (52, 12), (2, 44), (52, 44)):
        b.append(f'<rect x="{x}" y="{y}" width="10" height="10" rx="2" fill="{METAL_D}"/>')
    return b


def g06_sucata():
    """Entrega de Entulho: tambor amassado com canos e chapa torta — 64x56."""
    b = [shape("g6s", "M10,14 C10,8 20,6 32,6 C44,6 54,8 54,14 L52,48 C52,54 42,56 32,56 C22,56 12,54 12,48 Z", "#3c9a46", 255, (8, 4, 56, 58), k=1.6, dark="#25682d", light="#6cc476")]
    b.append(f'<path d="M12,24 C24,28 40,28 53,24 M12,38 C24,42 40,42 52,38" stroke="#25682d" stroke-width="3" fill="none"/>')
    b.append(f'<path d="M30,20 l6,6 l-8,4 Z" fill="#25682d"/>')
    b.append(shape("g6p", rect_d(40, 0, 22, 9, 3), METAL, 256, (38, -2, 64, 11), k=1.2, dark=METAL_D))
    b.append(shape("g6q", rect_d(0, 30, 16, 8, 3), METAL, 257, (-2, 28, 18, 40), k=1.2, dark=METAL_D))
    b.append(f'<path d="M22,12 C26,10 30,10 34,12" stroke="#ffffff" stroke-width="2" opacity="0.6" fill="none"/>')
    return b


def g11_tapume():
    """Interdição de Área: tapume metálico ondulado com listras laranja/branco, moldura e pé — 64x160 (pé embaixo)."""
    b = [shape("g11m", rect_d(2, 8, 60, 140, 4), "#ffffff", 260, (0, 6, 64, 150), k=1.8, dark="#c9c9c9")]
    for k in range(-3, 6):
        y = 8 + k * 32
        b.append(f'<path d="M2,{y + 32} L62,{y} L62,{y + 16} L2,{y + 48} Z" fill="#f08a3d" clip-path="url(#g11m)"/>')
    for x in (12, 24, 36, 48):
        b.append(f'<path d="M{x},10 V146" stroke="#000000" stroke-width="2" opacity="0.12"/>')
    b.append(f'<rect x="0" y="4" width="64" height="8" rx="2" fill="{METAL_D}"/><rect x="0" y="144" width="64" height="8" rx="2" fill="{METAL_D}"/>')
    b.append(f'<rect x="6" y="150" width="20" height="10" rx="2" fill="{INK}"/><rect x="38" y="150" width="20" height="10" rx="2" fill="{INK}"/>')
    b.append(_parafusos([(6, 8), (58, 8), (6, 148), (58, 148)], 2.4))
    return b


def g14_rebite():
    """Chuva de Rebites: rebite caindo (cabeça em cima, ponta em brasa) — 16x32."""
    return [shape("g14", "M2,8 C2,2 14,2 14,8 L14,10 L11,10 L11,26 C11,30 5,30 5,26 L5,10 L2,10 Z", METAL, 270, (0, 0, 16, 32), k=1.0, dark=METAL_D, light=METAL_L),
            '<path d="M5,22 L11,22 L11,26 C11,30 5,30 5,26 Z" fill="#f08a3d"/><path d="M4,4 C6,3 8,3 9,4" stroke="#ffffff" stroke-width="1.4" fill="none"/>']


def g09_drone():
    """Inspeção de Segurança: drone vistoriador (corpo verde, capacete branco, olho, prancheta) — 112x88."""
    b = []
    for x in (6, 76):
        b.append(f'<rect x="{x + 12}" y="10" width="6" height="14" fill="{METAL_D}"/>')
        b.append(shape(f"g9h{x}", ellipse_d(x + 15, 8, 16, 4), METAL_L, 280 + x, (x - 2, 2, x + 32, 14), k=1.0))
    b.append(f'<path d="M18,24 H94" stroke="{METAL_D}" stroke-width="5" stroke-linecap="round"/>')
    b.append(shape("g9c", ellipse_d(56, 48, 30, 24), "#3c9a46", 283, (24, 22, 88, 74), k=1.6, dark="#25682d", light="#6cc476"))
    b.append(shape("g9k", "M30,38 C30,20 82,20 82,38 Z", "#ffffff", 284, (28, 18, 84, 40), k=1.4, dark="#c9c9c9"))
    b.append(f'<rect x="26" y="36" width="60" height="5" rx="2" fill="#f2c84b"/>')
    b.append(f'<circle cx="56" cy="54" r="11" fill="{INK}"/><circle cx="56" cy="54" r="6" fill="#9ff7c8"/><circle cx="53" cy="51" r="2.4" fill="#ffffff"/>')
    b.append(f'<path d="M82,58 L96,66" stroke="{METAL_D}" stroke-width="4" stroke-linecap="round"/>')
    b.append(shape("g9p", rect_d(88, 56, 22, 30, 3), "#c98a4b", 285, (86, 54, 112, 88), k=1.2, dark="#8a5a2b"))
    b.append(f'<rect x="91" y="62" width="16" height="21" fill="#ffffff"/><path d="M94,68 h10 M94,73 h10 M94,78 h6" stroke="#9aa4ae" stroke-width="1.6"/>')
    b.append(f'<rect x="95" y="53" width="8" height="5" rx="1" fill="{METAL_D}"/>')
    return b


PIECES = {  # nome: (largura, altura, função)
    "s01_canhao": (128, 64, s01_canhao), "s01_luva": (64, 50, s01_luva),
    "s03_canhao": (128, 64, s03_canhao),
    "s06_ima": (112, 80, s06_ima), "s10_tabua": (192, 24, s10_tabua), "s10_trouxa": (48, 32, s10_trouxa),
    "s13_frente": (150, 130, s13_frente), "s13_costas": (150, 130, s13_costas),
    "g10_capsula": (128, 160, g10_capsula),
    "s02_laser": (128, 64, s02_laser), "s05_rebiteira": (128, 64, s05_rebiteira), "s18_disco": (64, 64, s18_disco),
    "s20_canhao": (128, 64, s20_canhao), "s17_estaca": (64, 192, s17_estaca), "s04_marreta": (64, 128, s04_marreta),
    "s07_ventilador": (128, 64, s07_ventilador), "s08_gancho": (128, 64, s08_gancho), "s21_laco": (128, 64, s21_laco),
    "s12_carga": (64, 48, s12_carga), "s27_controle": (48, 64, s27_controle), "s28_placa": (48, 96, s28_placa), "s28_painel": (64, 40, s28_painel), "s28_topo": (64, 16, s28_topo),
    "s14_chassi": (128, 80, s14_chassi), "s14_garfo": (48, 96, s14_garfo), "s15_bola": (96, 96, s15_bola),
    "s16_mochila": (64, 72, s16_mochila), "s31_broca": (96, 64, s31_broca), "s31_esteira": (112, 28, s31_esteira),
    "s33_mascara": (56, 48, s33_mascara),
    "a14_frente": (150, 130, a14_frente), "a14_costas": (150, 130, a14_costas), "a14_mastro": (40, 120, a14_mastro),
    "a31_frente": (150, 130, a31_frente), "a31_costas": (150, 130, a31_costas), "a31_braco": (112, 56, a31_braco),
    "a33_frente": (150, 130, a33_frente), "a33_costas": (150, 130, a33_costas), "a33_tocha": (96, 40, a33_tocha),
    "a34_raio": (72, 48, a34_raio), "a16_jato": (72, 84, a16_jato),
    "s28_macarico": (64, 32, s28_macarico), "s25_tabua": (64, 20, s25_tabua),
    "g02_exaustor": (160, 160, g02_exaustor), "g02_grade": (160, 160, g02_grade), "g02_helice": (128, 128, g02_helice),
    "g04_bobina": (112, 160, g04_bobina), "g05_carga": (256, 56, g05_carga), "g05_moitao": (80, 112, g05_moitao),
    "g06_caixa": (64, 56, g06_caixa), "g06_sucata": (64, 56, g06_sucata), "g11_tapume": (64, 160, g11_tapume),
    "g14_rebite": (16, 32, g14_rebite), "g09_drone": (112, 88, g09_drone),
}


# ---------------------------------------------------------------- prancha
def label(x, y, t, size=26, col=INK, anchor="middle"):
    return f'<text x="{x}" y="{y}" font-family="Fredoka, Arial" font-weight="700" font-size="{size}" fill="{col}" text-anchor="{anchor}">{t}</text>'


def place(fn, x, y, s=1.0):
    return f'<g transform="translate({x},{y}) scale({s})">{"".join(fn())}</g>'


def prancha():
    b = ['<rect width="1920" height="1080" fill="#eef7f6"/>', label(960, 56, "SPELLS — ETAPA 1 (para aprovar a arte)", 40)]
    # caixas
    b.append(label(250, 110, "CAIXAS (família visível, spell escondida)", 24))
    names = {"ataque": "ATAQUE", "controle": "CONTROLE", "engenharia": "ENGENHARIA", "transformacao": "TRANSFORM."}
    for i, fam in enumerate(FAM):
        x = 40 + i * 120
        b.append(f'<g transform="translate({x},130)">{caixa_body(fam)}</g>')
        b.append(label(x + 48, 250, names[fam], 15))
    # spells
    cards = [
        ("S01 PUNHO PNEUMÁTICO", 40, 300, lambda: (place(s01_canhao, 10, 40, 1.3) + place(s01_luva, 180, 44, 1.3)
                                                    + '<path d="M140,80 H180" stroke="#9e3f17" stroke-width="10"/>'
                                                    + "".join(f'<path d="M{150 + k * 8},{66 + k * 10} h-40" stroke="#ffffff" stroke-width="4" stroke-linecap="round"/>' for k in range(3)))),
        ("S03 CANHÃO CRIOGÊNICO", 520, 300, lambda: (place(s03_canhao, 0, 40, 1.3) + place(s03_projetil, 190, 40, 1.0)
                                                      + place(s03_gelo, 20, 160, 2.2))),
        ("S06 SUPERÍMÃ", 1000, 300, lambda: (place(s06_ima, 0, 40, 1.4)
                                             + "".join(f'<path d="M{170 + k * 40},{40 + k * 6} C{230 + k * 40},{60} {230 + k * 40},{140} {170 + k * 40},{160 - k * 6}" stroke="#d94a5a" stroke-width="3" fill="none" stroke-dasharray="8 6" opacity="{0.8 - k * 0.2}"/>' for k in range(3)))),
        ("S10 ANDAIME RELÂMPAGO", 1440, 300, lambda: (place(s10_trouxa, 20, 40, 2.4) + place(s10_tabua, 20, 150, 1.8))),
        ("S11 TELEPORTE", 40, 640, lambda: (place(s11_portal, 20, 60, 1.4) + place(s11_portal, 300, 60, 1.4)
                                            + '<path d="M150,120 h170" stroke="#9ff7c8" stroke-width="4" stroke-dasharray="10 8"/>'
                                            + '<rect x="320" y="40" width="70" height="120" rx="20" fill="#9ff7c8" fill-opacity="0.35" stroke="#3fc1c9" stroke-width="3" stroke-dasharray="8 5"/>'
                                            + "".join(f'<circle cx="{150 + k * 22}" cy="{100 + (k % 3) * 18}" r="5" fill="{METAL}"/>' for k in range(6)))),
        ("S13 ARMADURA FORNALHA", 520, 640, lambda: (place(s13_costas, 20, 30, 1.4) + place(s13_frente, 20, 30, 1.4)
                                                     + f'<path d="M230,120 C290,90 330,130 380,104 C350,140 300,150 230,136 Z" fill="{FIRE}"/>'
                                                     + f'<path d="M232,124 C280,108 310,128 340,118 C320,136 280,140 232,132 Z" fill="{FIRE_L}"/>')),
        ("G10 CARGA ESPECIAL", 1000, 640, lambda: (place(g10_capsula, 10, 10, 1.1) + place(g10_capsula, 220, 40, 0.9)
                                                   + '<path d="M330,0 L300,250 M370,0 L340,250" stroke="#fff4c8" stroke-width="40" opacity="0.35"/>')),
    ]
    for (t, x, y, fn) in cards:
        b.append(f'<rect x="{x}" y="{y}" width="440" height="310" rx="18" fill="#ffffff" opacity="0.7"/>')
        b.append(label(x + 220, y + 34, t, 24))
        b.append(f'<g transform="translate({x + 20},{y + 40})">{fn()}</g>')
    # HUD
    hx, hy = 1440, 640
    b.append(f'<rect x="{hx}" y="{hy}" width="440" height="310" rx="18" fill="#ffffff" opacity="0.7"/>')
    b.append(label(hx + 220, hy + 34, "HUD + TROCA (segurar 0,3 s)", 24))
    b.append(f'<circle cx="{hx + 110}" cy="{hy + 160}" r="62" fill="{FAM["ataque"][0]}"/>')
    b.append(f'<g transform="translate({hx + 78},{hy + 128})">{icon("punho")}</g>')
    for k in range(2):
        b.append(f'<circle cx="{hx + 86 + k * 24}" cy="{hy + 246}" r="9" fill="{INK}"/>')
    b.append(label(hx + 110, hy + 285, "PUNHO · 1 carga", 18))
    b.append(f'<circle cx="{hx + 330}" cy="{hy + 160}" r="62" fill="none" stroke="#d9dde2" stroke-width="12"/>')
    b.append(f'<path d="M{hx + 330},{hy + 98} A62,62 0 1,1 {hx + 272},{hy + 182}" fill="none" stroke="#5cc45c" stroke-width="12" stroke-linecap="round"/>')
    b.append(f'<g transform="translate({hx + 282},{hy + 112})">{caixa_body("controle")}</g>')
    b.append(label(hx + 330, hy + 285, "trocando…", 18))
    return doc(1920, 1080, f'<g filter="url(#rough)">{"".join(b)}</g>', rough(seed=5, scale=0.9, freq=0.06))


def main():
    os.makedirs(OUT, exist_ok=True)
    for fam in FAM:
        queue(wrap(96, 96, caixa_body(fam), 10), f"{SRC}/caixa_{fam}.svg", f"{OUT}/caixa_{fam}.png", 96, 96, 2)
        queue(wrap(64, 64, icon(FAM[fam][2]), 11), f"{SRC}/icone_{fam}.svg", f"{OUT}/icone_{fam}.png", 64, 64, 2)
    for name, (w, h, fn) in PIECES.items():
        queue(wrap(w, h, "".join(fn()), 20), f"{SRC}/{name}.svg", f"{OUT}/{name}.png", w, h, 2)
    queue(prancha(), f"{SRC}/prancha.svg", os.path.join(ROOT, "art/out/prancha_spells_etapa1.png"), 1920, 1080, 1)
    print("spells renderizados:", render_all())


if __name__ == "__main__":
    main()
