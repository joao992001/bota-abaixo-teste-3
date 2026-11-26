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
            b.append(pow_(cx + w / 2 + 20, y + 40, 0.9))
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
    b.append(cartaz(130, 260, 560, 560, "CANTEIRO DE OBRAS", thumb, [("TÉRREO", True), ("FUNDAÇÃO", True), ("FACHADA", False)], sel=True))
    b.append(chip(110, 220))
    b.append(cartaz(800, 300, 430, 500, "? ? ?", bloqueado=True))
    b.append(cartaz(1330, 300, 430, 500, "? ? ?", bloqueado=True))
    # régua de obra pintada no tapume = Projetos de Demolição
    b.append(fp.R(800, 830, 960, 74, "#f6eedb", 6, 1.4) + f'<rect x="800" y="830" width="960" height="74" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(830, 878, "PROJETOS DE DEMOLIÇÃO", 26, INK, "start"))
    for k in range(6):
        col = "#d42035" if k % 2 == 0 else "#ffffff"
        b.append(f'<rect x="{1220 + k * 80}" y="846" width="80" height="42" fill="{col if k < 4 else "#e2d9c6"}" stroke="{INK}" stroke-width="3"/>')
    b.append(ec.T(1700, 878, "4/6", 26, INK))
    b.append(elenco(930, [("picareta", "rapido", 1, False), ("marretao", "parado", 0, True)], [60, 1860], 1.4))
    b.append(plaquinha_dica("◄► escolher  ·  PULAR confirmar  ·  ESC voltar"))
    n = ec.notes("MAPAS — cartazes presos num tapume de obra (proposta)", [
        ("PROPOSTA", "Cada mapa é um cartaz com foto, preso com fita crepe; o escolhido ganha moldura amarela."),
        ("PROPOSTA", "Cenas descobertas = capacetes amarelos; não descobertas = capacete cinza com “?”."),
        ("PROPOSTA", "Mapa bloqueado = coberto por lona azul, corrente e cadeado."),
        ("PROPOSTA", "Projetos de Demolição = régua de obra (vermelho/branco) pintada no tapume."),
        ("PROPOSTA", "Título = placa pendurada no cabo da grua (mesma linguagem do menu)."),
        ("PROPOSTA", "O SORTEIO vira um cartaz “?” coberto por lona que a grua puxa ao escolher."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=12, scale=0.6, freq=0.05))


def tela_ajustes():
    b = [fundo(0.15), chao(930)]
    # quadro de avisos de compensado em dois cavaletes
    b.append(f'<path d="M520,930 L600,760 M1400,930 L1320,760" stroke="#8a5a2b" stroke-width="18"/>')
    b.append(fp.R(380, 150, 1160, 680, "#c98a4b", 10, 2.6, dark="#a46a35"))
    b.append(f'<rect x="380" y="150" width="1160" height="680" rx="10" fill="none" stroke="{INK}" stroke-width="7"/>')
    for k in range(5):
        b.append(f'<path d="M{400 + k * 230},170 l40,640" stroke="#b57a3e" stroke-width="3" opacity="0.6"/>')
    b.append(placa(960, 60, 640, 96, "AJUSTES DA PARTIDA", True))
    b.append(corrente(700, 30, 60) + corrente(1220, 30, 60))
    # fichas presas no quadro
    def ficha(x, y, w, h, titulo, sel=False):
        s = ""
        if sel:
            s += f'<rect x="{x - 12}" y="{y - 12}" width="{w + 24}" height="{h + 24}" rx="12" fill="{YEL}" stroke="{INK}" stroke-width="5"/>'
        s += fp.R(x, y, w, h, CREAM, 6, 1.4) + f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>'
        s += f'<circle cx="{x + w / 2}" cy="{y + 4}" r="10" fill="#d42035" stroke="{INK}" stroke-width="3"/>'   # tachinha
        s += ec.T(x + 24, y + 48, titulo, 28, INK, "start")
        return s
    b.append(ficha(440, 210, 500, 250, "VIDAS", True))
    for k in range(6):   # capacetes = vidas
        cx = 500 + k * 72
        cy = 380
        col = "#f2c84b" if k < 4 else "#c9c2b2"
        b.append(f'<path d="M{cx - 28},{cy} C{cx - 28},{cy - 36} {cx + 28},{cy - 36} {cx + 28},{cy} Z" fill="{col}" stroke="{INK}" stroke-width="4"/>'
                 f'<rect x="{cx - 34}" y="{cy - 4}" width="68" height="9" rx="4" fill="{col}" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(690, 440, "◄  4 vidas  ►", 26, "#6b5a70", w=600))
    b.append(chip(410, 175))
    b.append(ficha(980, 210, 500, 250, "EVENTOS"))
    cx, cy = 1230, 360   # sirene com mostrador de intensidade
    for k, lab in enumerate(["DESL.", "BAIXA", "NORMAL", "ALTA"]):
        a = math.radians(200 + k * 46.6)
        b.append(ec.T(cx + math.cos(a) * 130, cy + math.sin(a) * 90 + 10, lab, 17, INK if lab != "NORMAL" else "#d42035"))
    b.append(f'<path d="M{cx - 40},{cy + 30} v-30 a40,40 0 0 1 80,0 v30z" fill="#e8483f" stroke="{INK}" stroke-width="4"/><rect x="{cx - 52}" y="{cy + 28}" width="104" height="18" fill="#4a4f5c"/>')
    b.append(ficha(440, 500, 500, 280, "SPELLS NAS CAIXAS"))
    b.append(f'<rect x="590" y="600" width="200" height="120" rx="16" fill="#4a4f5c" stroke="{INK}" stroke-width="5"/><rect x="610" y="620" width="70" height="80" rx="10" fill="#5fc95f" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(735, 672, "LIGA", 26, "#ffffff"))
    b.append(ficha(980, 500, 500, 280, ""))
    b.append(f'<ellipse cx="1230" cy="700" rx="140" ry="40" fill="#3a3f4a"/><ellipse cx="1230" cy="670" rx="120" ry="60" fill="#d42035" stroke="{INK}" stroke-width="6"/>')
    b.append(ec.T(1230, 600, "INICIAR DEMOLIÇÃO", 30, INK))
    b.append(elenco(930, [("chave", "parado", 2, False), ("britadeira", "rapido", 3, True)], [180, 1720], 1.5))
    b.append(plaquinha_dica("▲▼◄► escolher  ·  PULAR muda  ·  START inicia  ·  ESC voltar"))
    n = ec.notes("AJUSTES — quadro de avisos de compensado nos cavaletes (proposta)", [
        ("PROPOSTA", "Cada ajuste é uma ficha presa com tachinha; a escolhida ganha moldura amarela."),
        ("PROPOSTA", "Vidas = capacetes acesos (3 a 6); Eventos = sirene com mostrador de intensidade."),
        ("PROPOSTA", "Spells nas caixas = chave industrial LIGA/DESLIGA."),
        ("PROPOSTA", "Começar = botão vermelho “INICIAR DEMOLIÇÃO” (aperta com som e tremor)."),
        ("PROPOSTA", "Spells e Eventos (mosaicos) ganham o mesmo fundo de obra e a placa de título."),
        ("PROPOSTA", "Entrada de jogadores e resultados seguem a mesma linguagem (próximas pranchas)."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=13, scale=0.6, freq=0.05))


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
    boards = [("v2_1_menu", tela_menu()), ("v2_2_mapas", tela_mapas()), ("v2_3_ajustes", tela_ajustes()), ("v2_4_abertura", tela_abertura())]
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
