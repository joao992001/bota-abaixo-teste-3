"""PRANCHAS para aprovar — interface nova "CANTEIRO VIVO" (direção A, escolhida pelo usuário em 2026-11-26):
o menu acontece DENTRO da obra. Fundo = camadas reais do Canteiro; botões = placas de obra penduradas (escolher = a placa
balança e leva uma marretada); ajustes = quadro de avisos de compensado; mapas = cartazes num tapume.
Não é arte final: é conceito para aprovar antes do código. Rodar: python3 art/src/ui/menus_v2.py → art/out/menus_v2/*.png
"""
import base64
import io
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../cenarios"))
import etapa_c as ec  # noqa: E402  (page, notes, T, title, chunk, uri_img)
import fase1_prancha as fp  # noqa: E402
import ui  # noqa: E402
from papel import rough  # noqa: E402

ROOT = ec.ROOT
OUT = os.path.join(ROOT, "art/out/menus_v2")
W, H = 1920, 1080
INK, YEL, CREAM = "#2a1a2e", "#f2c84b", "#fff6e4"
el = fp.el


def fundo(escurece=0.0):
    a = Image.open(os.path.join(ROOT, "game/assets/fase1/e1_longe.png")).convert("RGBA")
    b = Image.open(os.path.join(ROOT, "game/assets/fase1/e1_perto.png")).convert("RGBA")
    a.alpha_composite(b)
    im = a.convert("RGB").resize((W, 1056))
    s = f'<image href="{ec.uri_img(im)}" x="0" y="0" width="{W}" height="1056"/><rect x="0" y="1050" width="{W}" height="40" fill="#b9ab8f"/>'
    if escurece:
        s += f'<rect width="{W}" height="{H}" fill="#2a1a2e" opacity="{escurece}"/>'
    return s


def chao(y=880):
    """Laje de concreto do térreo (palco onde o elenco fica)."""
    b = [fp.R(-20, y, W + 40, 60, "#d8ccb6", 0, 2.6, dark="#b8ab92"), f'<rect x="-20" y="{y}" width="{W + 40}" height="10" fill="#eee5d2"/>']
    b.append(fp.R(-20, y + 60, W + 40, H - y, "#b9ab8f", 0, 3, dark="#958a72"))
    for k in range(24):
        b.append(f'<circle cx="{30 + k * 82}" cy="{y + 110 + (k % 3) * 22}" r="4" fill="#958a72"/>')
    return "".join(b)


def logo(x, y, w):
    svg = ui.logo()
    h = w * 340 / 1700
    return svg.replace("<svg ", f'<svg x="{x}" y="{y}" width="{w}" height="{h}" ', 1)


def corrente(x, y0, y1):
    b = []
    yy = y0
    while yy < y1:
        b.append(f'<ellipse cx="{x}" cy="{yy + 7}" rx="5" ry="8" fill="none" stroke="#6b7783" stroke-width="3"/>')
        yy += 13
    return "".join(b)


def viga(x0, x1, y):
    return (f'<rect x="{x0}" y="{y}" width="{x1 - x0}" height="16" fill="#3a3f4a"/><rect x="{x0}" y="{y + 16}" width="{x1 - x0}" height="20" fill="#4a5060"/>'
            f'<rect x="{x0}" y="{y + 36}" width="{x1 - x0}" height="16" fill="#3a3f4a"/>' +
            "".join(f'<circle cx="{x0 + 30 + k * 60}" cy="{y + 26}" r="5" fill="#6b7380"/>' for k in range(int((x1 - x0 - 30) // 60))))


def placa(cx, y, w, h, txt, sel=False, rot=0.0, sub=""):
    """Placa de obra pendurada: chapa amarela (escolhida) ou cinza-creme, borda escura, parafusos; a escolhida tem fita
    zebrada embaixo, balança e leva uma marretada (estrela de impacto)."""
    fill = YEL if sel else "#e9e2d0"
    b = [f'<g transform="rotate({rot} {cx} {y})">']
    b.append(f'<rect x="{cx - w / 2 + 6}" y="{y + 10}" width="{w}" height="{h}" rx="10" fill="{INK}" opacity="0.35"/>')
    b.append(f'<rect x="{cx - w / 2}" y="{y}" width="{w}" height="{h}" rx="10" fill="{fill}" stroke="{INK}" stroke-width="7"/>')
    for bx in (cx - w / 2 + 18, cx + w / 2 - 18):
        b.append(f'<circle cx="{bx}" cy="{y + 18}" r="6" fill="#8d98a4" stroke="{INK}" stroke-width="2"/>')
    if sel:
        b.append(fp.cd.zebra(cx - w / 2 + 10, y + h - 22, w - 20, 12))
    b.append(ec.T(cx, y + h / 2 + 16 - (10 if sub else 0), txt, 46 if sel else 38, INK))
    if sub:
        b.append(ec.T(cx, y + h - 26, sub, 20, "#6b5a70", w=600))
    b.append('</g>')
    return "".join(b)


def pow_(cx, cy, s=1.0):
    pts = []
    for k in range(16):
        r = (70 if k % 2 == 0 else 34) * s
        a = k * math.pi / 8
        pts.append(f"{cx + math.cos(a) * r:.1f},{cy + math.sin(a) * r:.1f}")
    return (f'<polygon points="{" ".join(pts)}" fill="#fff4c8" stroke="{INK}" stroke-width="5"/>'
            + ec.T(cx, cy + 12, "POW!", int(30 * s), INK))


def chip(x, y, n=1):
    return (f'<rect x="{x}" y="{y}" width="70" height="44" rx="12" fill="{ec.PCOL[n - 1]}" stroke="{INK}" stroke-width="5"/>'
            + ec.T(x + 35, y + 32, f"P{n}", 26, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))


def elenco(y, poses, xs, s=1.6):
    out = []
    for (cid, pose, ci, flip), x in zip(poses, xs):
        out.append(fp.robot(cid, pose, el.COLORS[ci], x, y, s, flip))
    return "".join(out)


def plaquinha_dica(txt):
    return (fp.R(560, 1000, 800, 56, "#e9e2d0", 8, 1.6) + f'<rect x="560" y="1000" width="800" height="56" rx="8" fill="none" stroke="{INK}" stroke-width="4"/>'
            + ec.T(960, 1037, txt, 24, INK))


# ---------------------------------------------------------------- telas
def tela_menu():
    b = [fundo(), chao()]
    b.append(f'<path d="M1180,0 V150" stroke="#4a4f5c" stroke-width="5"/>')     # cabo da grua
    b.append(viga(900, 1460, 150))
    itens = [("JOGAR", True), ("LABORATÓRIO", False), ("COMO JOGAR", False), ("OPÇÕES", False), ("SAIR", False)]
    y = 230
    for i, (t, sel) in enumerate(itens):
        h = 112 if sel else 84
        w = 520 if sel else 440
        cx = 1180
        b.append(corrente(cx - w / 2 + 40, y - 30 if i else 202, y))
        b.append(corrente(cx + w / 2 - 40, y - 30 if i else 202, y))
        b.append(placa(cx, y, w, h, t, sel, rot=(-3.5 if sel else (1.2 if i % 2 else -1.0))))
        if sel:
            b.append(pow_(cx + w / 2 + 70, y + 64, 0.8))
        y += h + 30
    b.append(logo(60, 40, 760))
    b.append(elenco(880, [("marretao", "pesado_prep", 0, False), ("picareta", "parado", 1, False), ("chave", "rapido", 2, True),
                          ("britadeira", "esquiva", 3, False), ("pa", "parado", 4, True)], [1500, 240, 420, 760, 1760], 1.7))
    b.append(chip(1500 - 35, 640))
    b.append(plaquinha_dica("▲▼ escolher  ·  PULAR marreta a placa  ·  ESC voltar"))
    n = ec.notes("MENU PRINCIPAL — direção A “Canteiro vivo” (proposta para aprovar)", [
        ("PROPOSTA", "Fundo = o próprio Canteiro (grua, prédio, cidade), animado como na fase."),
        ("PROPOSTA", "Botões = placas de obra penduradas na viga da grua, por correntes."),
        ("PROPOSTA", "Escolher = a placa balança; confirmar = o robô marreta a placa (POW!)."),
        ("PROPOSTA", "Logo = o letreiro atual, preso por cabo; o elenco fica na laje, vivo."),
        ("PROPOSTA", "Sem caixa branca: tudo é objeto da obra (papel e giz)."),
        ("DECIDIR", "Placas em coluna (como aqui) ou espalhadas pela obra?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=11, scale=0.6, freq=0.05))


def cartaz(x, y, w, h, nome, thumb=None, cenas=None, bloqueado=False, sel=False):
    b = []
    if sel:
        b.append(f'<rect x="{x - 16}" y="{y - 16}" width="{w + 32}" height="{h + 32}" rx="14" fill="{YEL}" stroke="{INK}" stroke-width="6"/>')
    b.append(fp.R(x, y, w, h, "#f6eedb", 6, 1.6, dark="#d9c7a3"))
    b.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="none" stroke="{INK}" stroke-width="5"/>')
    for tx, ty, rot in ((x - 20, y - 10, -30), (x + w - 70, y - 10, 30)):   # fita crepe nos cantos
        b.append(f'<rect x="{tx}" y="{ty}" width="90" height="30" fill="#e8d9a8" opacity="0.9" transform="rotate({rot} {tx + 45} {ty + 15})"/>')
    if thumb is not None:
        b.append(f'<clipPath id="ct{x}"><rect x="{x + 22}" y="{y + 22}" width="{w - 44}" height="{h * 0.58}" rx="6"/></clipPath>')
        b.append(f'<image clip-path="url(#ct{x})" href="{ec.uri_img(thumb)}" x="{x + 22}" y="{y + 22}" width="{w - 44}" height="{h * 0.58}" preserveAspectRatio="xMidYMid slice"/>')
        b.append(f'<rect x="{x + 22}" y="{y + 22}" width="{w - 44}" height="{h * 0.58}" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(x + w / 2, y + h * 0.58 + 80, nome, 36))
    if cenas:
        for k, (nm, ok) in enumerate(cenas):   # capacetes = cenas descobertas
            cx = x + w / 2 - 110 + k * 110
            cy = y + h - 60
            col = "#f2c84b" if ok else "#c9c2b2"
            b.append(f'<path d="M{cx - 32},{cy} C{cx - 32},{cy - 40} {cx + 32},{cy - 40} {cx + 32},{cy} Z" fill="{col}" stroke="{INK}" stroke-width="4"/>'
                     f'<rect x="{cx - 40}" y="{cy - 4}" width="80" height="10" rx="4" fill="{col}" stroke="{INK}" stroke-width="4"/>')
            b.append(ec.T(cx, cy + 34, nm if ok else "?", 17, INK if ok else "#6b5a70", w=600))
    if bloqueado:   # lona por cima + corrente e cadeado
        b.append(f'<path d="M{x - 10},{y + 20} L{x + w + 10},{y - 6} L{x + w + 6},{y + h + 10} L{x - 6},{y + h - 6}Z" fill="#3f7fb5" opacity="0.92"/>')
        for k in range(5):
            b.append(f'<path d="M{x + 20 + k * w / 5},{y + 10} q20,{h / 2} -6,{h - 10}" stroke="#2f6595" stroke-width="5" fill="none"/>')
        b.append(f'<path d="M{x - 10},{y + h * 0.45} L{x + w + 10},{y + h * 0.55}" stroke="#8d98a4" stroke-width="10" stroke-dasharray="14 6"/>')
        b.append(fp.R(x + w / 2 - 40, y + h * 0.5 - 30, 80, 66, YEL, 10, 1.4) + f'<path d="M{x + w / 2 - 24},{y + h * 0.5 - 30} v-22 a24,24 0 0 1 48,0 v22" stroke="{INK}" stroke-width="10" fill="none"/>')
        b.append(ec.T(x + w / 2, y + h - 40, "BLOQUEADO", 28, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))
    return "".join(b)


def tela_mapas():
    b = [fundo(), chao(930)]
    # tapume (painéis de compensado pintados) atravessando a tela
    for k in range(9):
        x = -40 + k * 230
        b.append(fp.R(x, 170, 236, 760, "#7fae86" if k % 2 == 0 else "#86b48c", 2, 2.4, dark="#5f8f68"))
        b.append(f'<rect x="{x}" y="170" width="236" height="760" fill="none" stroke="#4d7a56" stroke-width="3"/>')
    b.append(fp.cd.zebra(-20, 150, W + 40, 26))
    b.append(fp.cd.zebra(-20, 920, W + 40, 18))
    b.append(f'<path d="M960,0 V58" stroke="#4a4f5c" stroke-width="5"/>' + corrente(820, 58, 74) + corrente(1100, 58, 74))
    b.append(placa(960, 70, 560, 96, "ESCOLHA O MAPA", True))
    thumb = Image.open(os.path.join(ROOT, "game/assets/ui/arena_canteiro_obras.png")).convert("RGB")
    b.append(cartaz(70, 300, 380, 500, "SORTEIO"))
    b.append(f'<rect x="92" y="322" width="336" height="290" rx="6" fill="#9fe3ee" stroke="{INK}" stroke-width="4"/>' + ec.title(260, 520, "?", 200, YEL))
    b.append(ec.T(260, 760, "a grua escolhe por você", 22, "#6b5a70", w=600))
    b.append(cartaz(520, 260, 560, 560, "CANTEIRO DE OBRAS", thumb, [("TÉRREO", True), ("FUNDAÇÃO", True), ("FACHADA", False)], sel=True))
    b.append(chip(500, 220))
    b.append(cartaz(1150, 300, 330, 500, "? ? ?", bloqueado=True))
    b.append(cartaz(1540, 300, 330, 500, "? ? ?", bloqueado=True))
    # régua de obra pintada no tapume = Projetos de Demolição
    b.append(fp.R(1150, 830, 620, 74, "#f6eedb", 6, 1.4) + f'<rect x="1150" y="830" width="620" height="74" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(1170, 864, "PROJETOS DE", 20, INK, "start") + ec.T(1170, 890, "DEMOLIÇÃO", 20, INK, "start"))
    for k in range(6):
        col = "#d42035" if k % 2 == 0 else "#ffffff"
        b.append(f'<rect x="{1330 + k * 62}" y="846" width="62" height="42" fill="{col if k < 4 else "#e2d9c6"}" stroke="{INK}" stroke-width="3"/>')
    b.append(ec.T(1728, 878, "4/6", 24, INK))
    b.append(elenco(930, [("picareta", "rapido", 1, False), ("marretao", "parado", 0, True)], [60, 1860], 1.4))
    b.append(plaquinha_dica("◄► escolher  ·  PULAR confirmar  ·  ESC voltar"))
    n = ec.notes("MAPAS — cartazes presos num tapume de obra (proposta)", [
        ("PROPOSTA", "Cada mapa é um cartaz com foto, preso com fita crepe; o escolhido ganha moldura amarela."),
        ("PROPOSTA", "Cenas descobertas = capacetes amarelos; não descobertas = capacete cinza com “?”."),
        ("PROPOSTA", "Mapa bloqueado = coberto por lona azul, corrente e cadeado."),
        ("PROPOSTA", "Projetos de Demolição = régua de obra (vermelho/branco) pintada no tapume."),
        ("PROPOSTA", "Título = placa pendurada no cabo da grua (mesma linguagem do menu)."),
        ("PROPOSTA", "SORTEIO = cartaz “?”: a grua escolhe o mapa e segue para a configuração dele."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=12, scale=0.6, freq=0.05))


def estencil(x, y, txt, size, col=INK, anchor="middle"):
    """Letra de estêncil de obra (pintada com molde): cor chapada + falhas do molde."""
    return (f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="700" font-size="{size}" fill="{col}" text-anchor="{anchor}" '
            f'letter-spacing="{size * 0.04:.1f}">{txt}</text>')


def prancheta(x, y, w, h, titulo, cor, sel=False):
    """Prancheta de obra: base de compensado, folha creme, prendedor de metal e faixa colorida do título."""
    b = []
    if sel:
        b.append(f'<rect x="{x - 16}" y="{y - 16}" width="{w + 32}" height="{h + 32}" rx="22" fill="{YEL}" stroke="{INK}" stroke-width="6"/>')
    b.append(f'<rect x="{x + 8}" y="{y + 12}" width="{w}" height="{h}" rx="16" fill="{INK}" opacity="0.4"/>')
    b.append(fp.R(x, y, w, h, "#b57a3e", 14, 2.0, dark="#8a5a2b"))
    b.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="none" stroke="{INK}" stroke-width="6"/>')
    b.append(fp.R(x + 18, y + 30, w - 36, h - 48, CREAM, 6, 1.4, dark="#e9dcc0"))
    b.append(f'<rect x="{x + 18}" y="{y + 30}" width="{w - 36}" height="62" fill="{cor}"/>')
    b.append(f'<rect x="{x + 18}" y="{y + 30}" width="{w - 36}" height="{h - 48}" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
    b.append(estencil(x + w / 2, y + 76, titulo, 34, "#ffffff"))
    cx = x + w / 2   # prendedor
    b.append(f'<rect x="{cx - 70}" y="{y - 10}" width="140" height="40" rx="10" fill="#9aa3ad" stroke="{INK}" stroke-width="5"/>'
             f'<rect x="{cx - 40}" y="{y - 24}" width="80" height="22" rx="8" fill="#c9d1d8" stroke="{INK}" stroke-width="4"/>')
    return "".join(b)


def seta_aba(x, y, d):
    """Botão de metal redondo com seta (◄ ►) para mudar o valor."""
    pts = f"{x - 9 * d},{y - 15} {x + 13 * d},{y} {x - 9 * d},{y + 15}"
    return (f'<circle cx="{x}" cy="{y}" r="27" fill="#4a5060" stroke="{INK}" stroke-width="4"/>'
            f'<polygon points="{pts}" fill="{YEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')


def capacete(cx, cy, s, aceso):
    col = YEL if aceso else "#cfc8b8"
    sh = "#c49a2a" if aceso else "#a9a293"
    return (f'<path d="M{cx - 40 * s},{cy} C{cx - 40 * s},{cy - 56 * s} {cx + 40 * s},{cy - 56 * s} {cx + 40 * s},{cy} Z" fill="{col}" stroke="{INK}" stroke-width="5"/>'
            f'<path d="M{cx - 6 * s},{cy - 40 * s} h12 v40 h-12z" fill="{sh}"/>'
            f'<rect x="{cx - 52 * s}" y="{cy - 6}" width="{104 * s}" height="14" rx="7" fill="{col}" stroke="{INK}" stroke-width="5"/>')


def tela_ajustes():
    b = [fundo(0.1), chao(930)]
    # cavaletes de obra (A) segurando o quadro
    for x in (470, 1450):
        b.append(f'<path d="M{x - 70},930 L{x},760 L{x + 70},930" stroke="#8a5a2b" stroke-width="22" fill="none" stroke-linejoin="round"/>'
                 f'<path d="M{x - 45},850 h90" stroke="#8a5a2b" stroke-width="14"/>')
    # quadro de compensado
    b.append(f'<rect x="268" y="168" width="1400" height="760" rx="18" fill="{INK}" opacity="0.35"/>')
    b.append(fp.R(260, 150, 1400, 760, "#d9a35f", 16, 2.6, dark="#b57a3e"))
    for k in range(9):
        b.append(f'<path d="M{300 + k * 160},160 q30,350 -10,700" stroke="#c28a4a" stroke-width="4" fill="none" opacity="0.55"/>')
    b.append(f'<rect x="260" y="150" width="1400" height="760" rx="16" fill="none" stroke="{INK}" stroke-width="8"/>')
    for sx, sy in ((290, 180), (1630, 180), (290, 880), (1630, 880)):   # parafusos
        b.append(f'<circle cx="{sx}" cy="{sy}" r="10" fill="#8d98a4" stroke="{INK}" stroke-width="3"/><path d="M{sx - 6},{sy} h12" stroke="{INK}" stroke-width="3"/>')
    b.append(fp.cd.zebra(330, 878, 1260, 16))
    # título: placa pendurada
    b.append(corrente(690, 26, 64) + corrente(1230, 26, 64))
    b.append(placa(960, 60, 660, 100, "AJUSTES DA PARTIDA", True))
    b.append(estencil(960, 214, "CANTEIRO DE OBRAS · 3 CENAS", 26, "#6b3f17"))

    # 1) VIDAS — capacetes na prateleira + número grande
    x, y, w, h = 320, 236, 620, 300
    b.append(prancheta(x, y, w, h, "VIDAS", "#2f8ff0", sel=True))
    b.append(chip(x - 30, y - 40))
    b.append(seta_aba(x + 62, y + 190, -1) + seta_aba(x + 218, y + 190, 1))
    b.append(estencil(x + 140, y + 232, "4", 118, INK))
    b.append(f'<rect x="{x + 262}" y="{y + 222}" width="330" height="14" fill="#8a5a2b" stroke="{INK}" stroke-width="3"/>')   # prateleira
    for k in range(6):
        b.append(capacete(x + 290 + k * 54, y + 220, 0.52, k < 4))
    b.append(estencil(x + 427, y + 140, "de 3 a 6", 24, "#6b5a70"))

    # 2) EVENTOS — sirene girando + mostrador
    x, y = 980, 236
    b.append(prancheta(x, y, w, h, "EVENTOS", "#d42035"))
    cx, cy = x + 150, y + 210
    for k in range(3):   # facho girando
        a = math.radians(-60 + k * 50)
        b.append(f'<path d="M{cx},{cy - 30} L{cx + math.cos(a) * 160:.0f},{cy - 30 + math.sin(a) * 90:.0f} L{cx + math.cos(a + 0.35) * 160:.0f},{cy - 30 + math.sin(a + 0.35) * 90:.0f}Z" fill="#ffd34d" opacity="0.35"/>')
    b.append(f'<rect x="{cx - 56}" y="{cy + 2}" width="112" height="26" rx="6" fill="#4a4f5c" stroke="{INK}" stroke-width="4"/>'
             f'<path d="M{cx - 44},{cy + 4} v-38 a44,44 0 0 1 88,0 v38z" fill="#e8483f" stroke="{INK}" stroke-width="5"/>'
             f'<path d="M{cx - 20},{cy - 30} a20,20 0 0 1 18,-20" stroke="#ffd0c8" stroke-width="7" fill="none" stroke-linecap="round"/>')
    gx, gy, gr = x + 430, y + 222, 88   # mostrador
    labs = ["DESL.", "BAIXA", "NORMAL", "ALTA"]
    cols = ["#8d98a4", "#8fd46a", "#f2d04b", "#ec6448"]
    for k in range(4):
        a0 = math.radians(180 + k * 45)
        a1 = math.radians(180 + (k + 1) * 45)
        b.append(f'<path d="M{gx},{gy} L{gx + math.cos(a0) * gr:.1f},{gy + math.sin(a0) * gr:.1f} A{gr},{gr} 0 0 1 {gx + math.cos(a1) * gr:.1f},{gy + math.sin(a1) * gr:.1f}Z" fill="{cols[k]}" stroke="{INK}" stroke-width="4"/>')
        am = math.radians(180 + (k + 0.5) * 45)
        b.append(ec.T(gx + math.cos(am) * (gr + 34), gy + math.sin(am) * (gr + 26) + 6, labs[k], 17, INK))
    an = math.radians(180 + 2.5 * 45)
    b.append(f'<path d="M{gx},{gy} L{gx + math.cos(an) * (gr - 10):.1f},{gy + math.sin(an) * (gr - 10):.1f}" stroke="{INK}" stroke-width="9" stroke-linecap="round"/><circle cx="{gx}" cy="{gy}" r="12" fill="{YEL}" stroke="{INK}" stroke-width="4"/>')
    b.append(estencil(gx, gy + 46, "NORMAL", 28, "#b0331f"))

    # 3) SPELLS NAS CAIXAS — as caixas de verdade + alavanca
    x, y = 320, 566
    b.append(prancheta(x, y, w, h, "SPELLS NAS CAIXAS", "#8a5ad8"))
    for k, fam in enumerate(("ataque", "controle", "engenharia", "transformacao")):
        im = Image.open(os.path.join(ROOT, f"game/assets/spells/caixa_{fam}.png")).convert("RGBA")
        b.append(ec.img(im.crop(im.getbbox()), x + 90 + k * 86, y + 170, 78, 78))
    b.append(estencil(x + 220, y + 252, "23 acesas no mosaico", 22, "#5a3fa0"))
    sx, sy = x + 500, y + 168   # alavanca industrial
    b.append(f'<rect x="{sx - 60}" y="{sy - 70}" width="120" height="150" rx="14" fill="#4a5060" stroke="{INK}" stroke-width="5"/>'
             f'<rect x="{sx - 12}" y="{sy - 50}" width="24" height="110" rx="12" fill="#2a2f3a"/>'
             f'<path d="M{sx},{sy + 30} L{sx + 4},{sy - 42}" stroke="#c9d1d8" stroke-width="14" stroke-linecap="round"/>'
             f'<circle cx="{sx + 4}" cy="{sy - 48}" r="18" fill="#5fc95f" stroke="{INK}" stroke-width="5"/>')
    b.append(estencil(sx, sy + 106, "LIGADAS", 20, "#2e7d32"))

    # 4) INICIAR DEMOLIÇÃO — detonador de TNT
    x, y = 980, 566
    b.append(prancheta(x, y, w, h, "INICIAR DEMOLIÇÃO", "#2a1a2e"))
    dx, dy = x + 190, y + 186
    b.append(f'<path d="M{dx},{dy - 66} V{dy - 10}" stroke="#c9d1d8" stroke-width="14"/>'
             f'<rect x="{dx - 70}" y="{dy - 80}" width="140" height="22" rx="10" fill="#c9d1d8" stroke="{INK}" stroke-width="5"/>')
    b.append(f'<rect x="{dx - 110}" y="{dy - 14}" width="220" height="86" rx="12" fill="#d42035" stroke="{INK}" stroke-width="6"/>')
    b.append(fp.cd.zebra(dx - 100, dy + 46, 200, 18))
    b.append(estencil(dx, dy + 34, "TNT", 40, "#ffffff"))
    b.append(f'<path d="M{dx + 110},{dy + 40} C{dx + 200},{dy + 40} {dx + 180},{dy - 60} {dx + 300},{dy - 40}" stroke="#2a2f3a" stroke-width="7" fill="none"/>')
    for k in range(3):   # bananas de dinamite
        b.append(f'<rect x="{dx + 296 + k * 28}" y="{dy - 80}" width="24" height="96" rx="8" fill="#e8483f" stroke="{INK}" stroke-width="4"/>')
    b.append(estencil(dx + 310, dy + 66, "aperte START", 24, "#6b5a70"))

    b.append(elenco(930, [("chave", "parado", 2, False), ("marretao", "pesado_prep", 0, True)], [150, 1780], 1.5))
    b.append(plaquinha_dica("▲▼◄► escolher  ·  ◄► muda o valor  ·  START detona  ·  ESC voltar"))
    n = ec.notes("AJUSTES v2 — pranchetas de obra num quadro de compensado (proposta lapidada)", [
        ("PROPOSTA", "Cada ajuste = prancheta com prendedor e faixa colorida; o valor aparece GRANDE."),
        ("PROPOSTA", "Vidas: número em estêncil + capacetes acesos na prateleira (3 a 6)."),
        ("PROPOSTA", "Eventos: sirene girando + mostrador DESL./BAIXA/NORMAL/ALTA com ponteiro."),
        ("PROPOSTA", "Spells: as 4 caixas de spell de verdade + alavanca LIGA/DESLIGA."),
        ("PROPOSTA", "Começar: detonador de TNT (START) — a alavanca desce, BUM, e a luta começa."),
        ("PROPOSTA", "Escolhida = moldura amarela + chip P1; ◄► mudam pelas abas de metal."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=13, scale=0.5, freq=0.05))


def trilha(atual):
    """Trilha de etapas obrigatórias (ordem de serviço): feitas = OK verde; atual = amarela; próximas = cinza + cadeado."""
    nomes = ["SPELLS", "EVENTOS", "VIDAS", "DETONAR"]
    b = [f'<rect x="330" y="214" width="1260" height="12" fill="#8d98a4" stroke="{INK}" stroke-width="3"/>']
    for k, nm in enumerate(nomes):
        cx = 420 + k * 360
        if k < atual:
            fill, txt = "#5fc95f", "#ffffff"
        elif k == atual:
            fill, txt = YEL, INK
        else:
            fill, txt = "#cfc8b8", "#6b5a70"
        w = 250 if k == atual else 220
        b.append(f'<rect x="{cx - w / 2 + 6}" y="{186 + 8}" width="{w}" height="64" rx="14" fill="{INK}" opacity="0.35"/>')
        b.append(f'<rect x="{cx - w / 2}" y="186" width="{w}" height="64" rx="14" fill="{fill}" stroke="{INK}" stroke-width="5"/>')
        b.append(estencil(cx + 12, 230, f"{k + 1} · {nm}", 26, txt))
        if k < atual:   # carimbo OK
            b.append(f'<g transform="rotate(-14 {cx + w / 2 - 14} 190)"><circle cx="{cx + w / 2 - 14}" cy="190" r="26" fill="#ffffff" stroke="#2e7d32" stroke-width="5"/>'
                     + estencil(cx + w / 2 - 14, 199, "OK", 22, "#2e7d32") + '</g>')
        if k > atual:   # cadeado
            lx = cx - w / 2 + 26
            b.append(f'<path d="M{lx - 9},208 v-8 a9,9 0 0 1 18,0 v8" stroke="{INK}" stroke-width="4" fill="none"/><rect x="{lx - 13}" y="206" width="26" height="22" rx="4" fill="#8d98a4" stroke="{INK}" stroke-width="3"/>')
    return "".join(b)


def quadro(y0=280, h=560):
    b = []
    for x in (470, 1450):
        b.append(f'<path d="M{x - 70},930 L{x},{y0 + h - 60} L{x + 70},930" stroke="#8a5a2b" stroke-width="22" fill="none" stroke-linejoin="round"/>')
    b.append(f'<rect x="368" y="{y0 + 14}" width="1200" height="{h}" rx="18" fill="{INK}" opacity="0.35"/>')
    b.append(fp.R(360, y0, 1200, h, "#d9a35f", 16, 2.6, dark="#b57a3e"))
    for k in range(8):
        b.append(f'<path d="M{400 + k * 150},{y0 + 10} q30,{h / 2} -10,{h - 20}" stroke="#c28a4a" stroke-width="4" fill="none" opacity="0.55"/>')
    b.append(f'<rect x="360" y="{y0}" width="1200" height="{h}" rx="16" fill="none" stroke="{INK}" stroke-width="8"/>')
    for sx, sy in ((390, y0 + 30), (1530, y0 + 30), (390, y0 + h - 30), (1530, y0 + h - 30)):
        b.append(f'<circle cx="{sx}" cy="{sy}" r="10" fill="#8d98a4" stroke="{INK}" stroke-width="3"/><path d="M{sx - 6},{sy} h12" stroke="{INK}" stroke-width="3"/>')
    return "".join(b)


def cabecalho(sub):
    return (corrente(690, 0, 40) + corrente(1230, 0, 40) + placa(960, 36, 660, 96, "AJUSTES DA PARTIDA", True)
            + estencil(960, 168, sub, 24, "#ffffff") .replace('fill="#ffffff"', f'fill="#ffffff" stroke="{INK}" stroke-width="5" paint-order="stroke"'))


def tela_etapa_vidas():
    b = [fundo(0.12), chao(930), cabecalho("CANTEIRO DE OBRAS · ETAPA 3 DE 4"), trilha(2), quadro()]
    x, y, w, h = 560, 320, 800, 440
    b.append(prancheta(x, y, w, h, "QUANTAS VIDAS CADA ROBÔ TEM?", "#2f8ff0", sel=True))
    b.append(chip(x - 30, y - 40))
    b.append(seta_aba(x + 150, y + 250, -1) + seta_aba(x + 650, y + 250, 1))
    b.append(estencil(x + 400, y + 300, "4", 190, INK))
    b.append(f'<rect x="{x + 110}" y="{y + 352}" width="580" height="16" fill="#8a5a2b" stroke="{INK}" stroke-width="3"/>')
    for k in range(6):
        b.append(capacete(x + 160 + k * 96, y + 350, 0.8, k < 4))
    b.append(estencil(x + 400, y + 410, "de 3 a 6  ·  mais vidas = luta mais longa", 22, "#6b5a70"))
    b.append(elenco(930, [("chave", "parado", 2, False), ("marretao", "parado", 0, True)], [150, 1780], 1.5))
    b.append(plaquinha_dica("◄► muda  ·  START próxima etapa  ·  ESC etapa anterior"))
    n = ec.notes("AJUSTES em ETAPAS OBRIGATÓRIAS (ordem de serviço) — etapa 3: VIDAS", [
        ("PROPOSTA", "Trilha no topo de TODAS as etapas: 1 SPELLS → 2 EVENTOS → 3 VIDAS → 4 DETONAR."),
        ("PROPOSTA", "Feita = carimbo OK verde; atual = amarela; próximas = cinza com cadeado (não pula)."),
        ("PROPOSTA", "START avança; ESC volta UMA etapa; só a etapa atual aparece no quadro."),
        ("PROPOSTA", "Etapa 1 (mosaico de spells) inclui a chave “spells nas caixas”."),
        ("PROPOSTA", "Etapa 2 (mosaico de eventos) inclui a sirene de intensidade."),
        ("PROPOSTA", "Etapa 3: só VIDAS, grande — número em estêncil e capacetes."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=15, scale=0.5, freq=0.05))


def tela_etapa_detonar():
    b = [fundo(0.12), chao(930), cabecalho("CANTEIRO DE OBRAS · ETAPA 4 DE 4"), trilha(3), quadro()]
    # ficha-resumo (ordem de serviço) à esquerda
    x, y, w, h = 420, 320, 600, 480
    b.append(prancheta(x, y, w, h, "ORDEM DE SERVIÇO", "#2a1a2e"))
    linhas = [("MAPA", "Canteiro de Obras"), ("SPELLS", "8 acesas"), ("EVENTOS", "10 · NORMAL"), ("VIDAS", "4")]
    for k, (a_, v) in enumerate(linhas):
        yy = y + 150 + k * 78
        b.append(f'<path d="M{x + 40},{yy + 16} H{x + w - 40}" stroke="#d9c7a3" stroke-width="3"/>')
        b.append(estencil(x + 48, yy, a_, 26, "#6b5a70", "start") + estencil(x + 220, yy, v, 27, INK, "start"))
        b.append(f'<g transform="rotate(-12 {x + w - 70} {yy - 10})"><circle cx="{x + w - 70}" cy="{yy - 10}" r="24" fill="none" stroke="#2e7d32" stroke-width="5"/>'
                 + estencil(x + w - 70, yy - 2, "OK", 20, "#2e7d32") + '</g>')
    # detonador grande à direita
    dx, dy = 1270, 620
    b.append(f'<path d="M{dx},{dy - 130} V{dy - 20}" stroke="#c9d1d8" stroke-width="20"/>'
             f'<rect x="{dx - 110}" y="{dy - 150}" width="220" height="34" rx="14" fill="#c9d1d8" stroke="{INK}" stroke-width="6"/>')
    b.append(f'<rect x="{dx - 170}" y="{dy - 24}" width="340" height="150" rx="16" fill="#d42035" stroke="{INK}" stroke-width="7"/>')
    b.append(fp.cd.zebra(dx - 155, dy + 86, 310, 26))
    b.append(estencil(dx, dy + 60, "TNT", 70, "#ffffff"))
    b.append(f'<path d="M{dx + 170},{dy + 60} C{dx + 250},{dy + 60} {dx + 230},{dy - 120} {dx + 250},{dy - 160}" stroke="#2a2f3a" stroke-width="8" fill="none"/>')
    b.append(chip(dx - 35, dy - 210))
    b.append(estencil(dx, dy + 180, "START = DETONAR!", 34, INK))
    b.append(elenco(930, [("britadeira", "parado", 3, False), ("marretao", "pesado_prep", 0, True)], [150, 1780], 1.5))
    b.append(plaquinha_dica("START detona e a luta começa  ·  ESC volta para corrigir"))
    n = ec.notes("AJUSTES em ETAPAS OBRIGATÓRIAS — etapa 4: CONFERIR E DETONAR", [
        ("PROPOSTA", "Ficha-resumo (ordem de serviço) com tudo o que foi escolhido, cada linha carimbada OK."),
        ("PROPOSTA", "Detonador de TNT grande: START desce a alavanca, BUM, a luta começa."),
        ("PROPOSTA", "ESC volta à etapa 3 (e assim por diante) para corrigir algo."),
        ("PROPOSTA", "“Jogar de novo” pula as etapas; “Configurar mapa” começa na etapa 1 já preenchida."),
        ("PROPOSTA", "Entrada de jogadores (quem joga, robô e skin) vem DEPOIS da etapa 4, como hoje."),
        ("DECIDIR", "A entrada de jogadores vira a etapa 5 da trilha, ou fica separada?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=16, scale=0.5, freq=0.05))


def tela_abertura():
    """Storyboard da ABERTURA: 5 quadros (5–6 s, pula com qualquer botão)."""
    b = [f'<rect width="{W}" height="{H}" fill="#9fc9d3"/>', ec.title(W / 2, 80, "ABERTURA (5–6 s)")]
    pw, ph = 580, 326
    pos = [(60, 140), (670, 140), (1280, 140), (365, 560), (975, 560)]
    caps = ["1 · manhã no Canteiro: a grua\ndesce o letreiro tapado por lona",
            "2 · a lona cai: BOTA-ABAIXO\nem letras de concreto penduradas",
            "3 · o MARRETÃO entra correndo\ne marreta o pilar — POW!",
            "4 · as letras caem, quicam e\nencaixam no lugar (poeira)",
            "5 · o elenco entra; plaquinha:\n“aperte qualquer botão”"]
    bg = Image.open(os.path.join(ROOT, "game/assets/fase1/e1_longe.png")).convert("RGBA")
    bg.alpha_composite(Image.open(os.path.join(ROOT, "game/assets/fase1/e1_perto.png")).convert("RGBA"))
    bgu = ec.uri_img(bg.convert("RGB").resize((pw * 2, int(pw * 2 * 1408 / 2560))))
    for i, ((x, y), cap) in enumerate(zip(pos, caps)):
        q = [f'<image href="{bgu}" x="0" y="0" width="{pw}" height="{pw * 1408 / 2560}"/>', f'<rect x="0" y="260" width="{pw}" height="70" fill="#d8ccb6"/>']
        q.append(f'<path d="M290,0 V{[150, 120, 120, 0, 0][i]}" stroke="#4a4f5c" stroke-width="3"/>' if i < 3 else "")
        if i == 0:
            q.append(f'<rect x="150" y="150" width="280" height="80" fill="#3f7fb5" stroke="{INK}" stroke-width="3"/>' + ec.T(290, 200, "?", 40, "#ffffff"))
        if i in (1, 2):
            q.append(logo(120, 120, 340))
        if i == 2:
            q.append(fp.robot("marretao", "pesado_golpe", el.COLORS[0], 480, 262, 0.8, True) + pow_(430, 210, 0.5))
            q.append(f'<rect x="400" y="160" width="30" height="100" fill="#cfc6b4" stroke="{INK}" stroke-width="2"/>')
        if i == 3:
            q.append(f'<g transform="rotate(6 290 150)">{logo(110, 150, 360)}</g>')
            for k in range(8):
                q.append(f'<ellipse cx="{120 + k * 50}" cy="{245 + (k % 2) * 8}" rx="30" ry="12" fill="#f4efe6" opacity="0.85"/>')
        if i == 4:
            q.append(logo(110, 40, 360))
            q.append(elenco(262, [("marretao", "parado", 0, False), ("picareta", "rapido", 1, False), ("chave", "parado", 2, True),
                                  ("britadeira", "esquiva", 3, False), ("pa", "parado", 4, True)], [110, 200, 300, 400, 490], 0.7))
            q.append(fp.R(190, 190, 200, 36, "#e9e2d0", 6, 1.2) + ec.T(290, 214, "aperte qualquer botão", 16, INK))
        b.append(f'<svg x="{x}" y="{y}" width="{pw}" height="{ph}" viewBox="0 0 {pw} {ph}">{"".join(q)}</svg>')
        b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" rx="8" fill="none" stroke="{INK}" stroke-width="5"/>')
        b.append(ec.lines(x + pw / 2, y + ph + 34, cap, 22))
    n = ec.notes("ABERTURA nova — demolição desde o primeiro segundo (proposta)", [
        ("PROPOSTA", "5–6 s, no próprio Canteiro; qualquer botão pula direto para o menu."),
        ("PROPOSTA", "A grua traz o letreiro; o Marretão derruba e as letras caem no lugar."),
        ("PROPOSTA", "Som: guincho da grua → marretada → letras batendo → tema começa."),
        ("PROPOSTA", "Termina já no MENU (mesmo cenário): sem corte, as placas descem."),
        ("PROPOSTA", "Letras = o logo atual (papel recortado), agora com peso e quique."),
        ("DECIDIR", "Quem marreta: sempre o Marretão, ou um robô sorteado a cada abertura?"),
    ])
    return ec.page("".join(b), n, rough(seed=14, scale=0.6, freq=0.05))


def main():
    os.makedirs(OUT, exist_ok=True)
    boards = [("v2_1_menu", tela_menu()), ("v2_2_mapas", tela_mapas()), ("v2_3_etapa_vidas", tela_etapa_vidas()), ("v2_3b_etapa_detonar", tela_etapa_detonar()), ("v2_4_abertura", tela_abertura())]
    import json, subprocess, tempfile
    tmp = tempfile.mkdtemp(prefix="menus_v2_")
    jobs = []
    for name, svg in boards:
        p = os.path.join(tmp, name + ".svg")
        open(p, "w").write(svg)
        jobs.append({"svg": p, "png": os.path.join(OUT, name + ".png"), "w": W, "h": H + ec.NOTES_H, "scale": 1})
    jp = os.path.join(tmp, "jobs.json")
    json.dump(jobs, open(jp, "w"))
    subprocess.run(["node", os.path.join(ROOT, "tools/render_svg.js"), jp], check=True)
    for j in jobs:
        Image.open(j["png"]).convert("RGB").save(j["png"], optimize=True)
        print(j["png"])


if __name__ == "__main__":
    main()
