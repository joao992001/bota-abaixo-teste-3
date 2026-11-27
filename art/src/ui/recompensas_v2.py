"""PRANCHAS para aprovar (avaliação do usuário de 2026-11-27):
g1 — GANGORRA: 3 formatos novos (o atual "está estranho").
g2 — ABRIR O PRESENTE: a gangorra SAI de cena, o presente vem para o CENTRO, abre e mostra o prêmio com destaque.
m1 — MAPAS em grade 3 × 3 (mais aberto); com mais mapas, desliza para o lado (páginas).
Rodar: python3 art/src/ui/recompensas_v2.py → art/out/recompensas/g1_gangorra_formatos.png, g2_presente.png, m1_mapas_grade.png
"""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import menus_v2 as mv  # noqa: E402
from menus_v2 import ec, fp, INK, YEL, CREAM, W, H, rough  # noqa: E402

OUT = os.path.join(ec.ROOT, "art/out/recompensas")
ZC = [z[2] for z in ec.ZONAS]


def presente(cx, cy, s=1.0, cat="SKIN", tampa=0.0, brilho=0.0):
    """Caixa de presente de obra: caixote amarelo com fita zebrada em cruz e laço; tampa sobe com 'tampa' (0..1)."""
    w = 150 * s
    b = []
    if brilho > 0:
        for k in range(14):
            a = k * math.pi / 7
            b.append(f'<path d="M{cx},{cy} L{cx + math.cos(a) * 320 * s * brilho:.0f},{cy + math.sin(a) * 320 * s * brilho:.0f} '
                     f'L{cx + math.cos(a + 0.2) * 320 * s * brilho:.0f},{cy + math.sin(a + 0.2) * 320 * s * brilho:.0f}Z" fill="#fff4c8" opacity="0.8"/>')
    b.append(f'<rect x="{cx - w / 2}" y="{cy - w / 2 + 16 * s}" width="{w}" height="{w - 16 * s}" rx="12" fill="{YEL}" stroke="{INK}" stroke-width="{7 * s:.1f}"/>')
    b.append(f'<rect x="{cx - 14 * s}" y="{cy - w / 2 + 16 * s}" width="{28 * s}" height="{w - 16 * s}" fill="#d42035" stroke="{INK}" stroke-width="{4 * s:.1f}"/>')
    ty = cy - w / 2 + 16 * s - 240 * s * tampa
    rot = -35 * tampa
    b.append(f'<g transform="rotate({rot} {cx} {ty})"><rect x="{cx - w / 2 - 12 * s}" y="{ty - 34 * s}" width="{w + 24 * s}" height="{36 * s}" rx="10" fill="#f5d870" stroke="{INK}" stroke-width="{7 * s:.1f}"/>'
             f'<rect x="{cx - 14 * s}" y="{ty - 34 * s}" width="{28 * s}" height="{36 * s}" fill="#d42035" stroke="{INK}" stroke-width="{4 * s:.1f}"/>'
             f'<path d="M{cx},{ty - 34 * s} c-40,-50 -80,-10 -30,0 M{cx},{ty - 34 * s} c40,-50 80,-10 30,0" stroke="#d42035" stroke-width="{12 * s:.1f}" fill="none" stroke-linecap="round"/></g>')
    if cat and tampa < 0.05:
        b.append(ec.chunk(cx - 80 * s, cy - w / 2 - 70 * s, 160 * s, 46 * s, CREAM, 10, 4, 6) + ec.T(cx, cy - w / 2 - 37 * s, cat, int(26 * s)))
    return "".join(b)


def regua_cores(cx, cy, R1, R2):
    b = []
    for i, col in enumerate(ZC):
        a0, a1 = math.radians(180 + i * 30), math.radians(180 + (i + 1) * 30)
        p = [(cx + math.cos(a0) * R2, cy + math.sin(a0) * R2), (cx + math.cos(a1) * R2, cy + math.sin(a1) * R2),
             (cx + math.cos(a1) * R1, cy + math.sin(a1) * R1), (cx + math.cos(a0) * R1, cy + math.sin(a0) * R1)]
        b.append(f'<polygon points="{" ".join(f"{x:.0f},{y:.0f}" for x, y in p)}" fill="{col}" stroke="{INK}" stroke-width="4"/>')
    return "".join(b)


def formato_a(ox, oy, s, ang):
    """A · BALANÇA DA GRUA: o gancho da grua segura uma VIGA pelo meio; a viga é pintada nas 6 cores do manômetro; nas
    pontas, cestos de carga com os presentes. A viga inclina; o cesto que desce até o chão libera o prêmio."""
    b = [f'<g transform="translate({ox},{oy}) scale({s})">']
    b.append(f'<path d="M0,-1100 V-300" stroke="#4a4f5c" stroke-width="8"/>')
    b.append(f'<rect x="-34" y="-330" width="68" height="56" rx="10" fill="{YEL}" stroke="{INK}" stroke-width="7"/>' + fp.cd.zebra(-34, -296, 68, 14))
    b.append(f'<path d="M0,-274 v22 a16,16 0 1 1 -18,14" stroke="#8d98a4" stroke-width="10" fill="none" stroke-linecap="round"/>')
    b.append(f'<g transform="rotate({ang} 0 -230)">')
    b.append(f'<path d="M-6,-244 L-380,-226 M6,-244 L380,-226" stroke="#4a4f5c" stroke-width="5"/>')
    for k in range(6):
        b.append(f'<rect x="{-420 + k * 140}" y="-232" width="140" height="34" fill="{ZC[k]}" stroke="{INK}" stroke-width="5"/>')
    b.append(f'<rect x="-420" y="-232" width="840" height="34" rx="6" fill="none" stroke="{INK}" stroke-width="7"/>')
    for sx in (-1, 1):
        x = sx * 370
        b.append(f'<path d="M{x - 50},-198 L{x - 60},-40 M{x + 50},-198 L{x + 60},-40" stroke="#4a4f5c" stroke-width="5"/>')
        b.append(f'<path d="M{x - 80},-40 h160 l-16,60 h-128 z" fill="#8d98a4" stroke="{INK}" stroke-width="6"/>')
        b.append(presente(x, -84, 0.62, "SKIN" if sx < 0 else "ENGENHOCA"))
    b.append("</g>")
    b.append(f'<circle cx="0" cy="-230" r="16" fill="#8d98a4" stroke="{INK}" stroke-width="6"/></g>')
    return "".join(b)


def formato_b(ox, oy, s, ang):
    """B · VIGA NO MACACO HIDRÁULICO: viga I de aço apoiada num macaco hidráulico amarelo no centro; presentes nas
    pontas; o manômetro é o próprio mostrador do macaco."""
    b = [f'<g transform="translate({ox},{oy}) scale({s})">']
    b.append(f'<rect x="-70" y="-150" width="140" height="150" rx="14" fill="{YEL}" stroke="{INK}" stroke-width="7"/>' + fp.cd.zebra(-70, -40, 140, 20))
    b.append(f'<rect x="-30" y="-210" width="60" height="70" fill="#8d98a4" stroke="{INK}" stroke-width="6"/>')
    b.append(f'<circle cx="0" cy="-100" r="42" fill="#f3ead8" stroke="{INK}" stroke-width="6"/>')
    for i, col in enumerate(ZC):
        a0, a1 = math.radians(200 + i * 23.3), math.radians(200 + (i + 1) * 23.3)
        b.append(f'<path d="M{math.cos(a0) * 34:.0f},{-100 + math.sin(a0) * 34:.0f} A34,34 0 0 1 {math.cos(a1) * 34:.0f},{-100 + math.sin(a1) * 34:.0f}" stroke="{col}" stroke-width="10" fill="none"/>')
    b.append(f'<path d="M0,-100 l{math.cos(math.radians(270 + ang * 3)) * 30:.0f},{math.sin(math.radians(270 + ang * 3)) * 30:.0f}" stroke="#d42035" stroke-width="6" stroke-linecap="round"/>')
    b.append(f'<g transform="rotate({ang} 0 -226)">')
    b.append(f'<rect x="-430" y="-250" width="860" height="14" fill="#5a6372" stroke="{INK}" stroke-width="5"/><rect x="-430" y="-222" width="860" height="14" fill="#5a6372" stroke="{INK}" stroke-width="5"/>')
    b.append(f'<rect x="-430" y="-238" width="860" height="18" fill="#7a828f" stroke="{INK}" stroke-width="4"/>')
    for i in range(6):
        b.append(f'<rect x="{-430 + i * 143}" y="-238" width="143" height="18" fill="{ZC[i]}" opacity="0.85"/>')
    for sx in (-1, 1):
        b.append(presente(sx * 360, -330, 0.7, "SKIN" if sx < 0 else "ENGENHOCA"))
    b.append("</g></g>")
    return "".join(b)


def formato_c(ox, oy, s, ang):
    """C · CARRINHO DE MÃO NA TÁBUA: tábua grossa de andaime num cavalete; em cada ponta um carrinho de mão com o
    presente; o peso (saco de cimento com o número da luta) cai e escorrega para o lado que ganhou."""
    b = [f'<g transform="translate({ox},{oy}) scale({s})">']
    b.append(f'<path d="M-90,0 L0,-150 L90,0 Z" fill="#c9b99a" stroke="{INK}" stroke-width="7"/>' + f'<path d="M-60,-40 h120" stroke="{INK}" stroke-width="5"/>')
    b.append(f'<g transform="rotate({ang} 0 -160)">')
    b.append(f'<rect x="-440" y="-186" width="880" height="40" rx="8" fill="#c98a4b" stroke="{INK}" stroke-width="7"/>')
    b.append("".join(f'<path d="M{-420 + k * 70},-180 v28" stroke="#9a6a3a" stroke-width="3"/>' for k in range(13)))
    for sx in (-1, 1):
        x = sx * 350
        b.append(f'<path d="M{x - 80},-190 L{x + 70},-190 L{x + 40},-250 L{x - 60},-250 Z" fill="#d94a3a" stroke="{INK}" stroke-width="6"/>')
        b.append(presente(x - 10, -300, 0.55, "SKIN" if sx < 0 else "ENGENHOCA"))
    b.append(f'<rect x="120" y="-250" width="80" height="62" rx="12" fill="#e8dcc2" stroke="{INK}" stroke-width="6"/>' + ec.T(160, -208, "+25", 28))
    b.append("</g></g>")
    return "".join(b)


def tela_formatos():
    b = [mv.fundo(0.15), mv.chao(930), mv.placa(960, 44, 900, 96, "GANGORRA — 3 FORMATOS", True)]
    for i, (fn, nome, sub) in enumerate([(formato_a, "A · BALANÇA DA GRUA", "a grua segura a viga; cestos de carga"),
                                         (formato_b, "B · VIGA NO MACACO", "viga de aço sobre macaco hidráulico"),
                                         (formato_c, "C · TÁBUA E CARRINHOS", "tábua de andaime; carrinhos de mão")]):
        x = 30 + i * 630
        b.append(ec.chunk(x, 160, 600, 740, CREAM, 22, 5, 8))
        b.append(ec.T(x + 300, 214, nome, 34) + ec.T(x + 300, 252, sub, 22, "#6b5a70", w=600))
        b.append(fn(x + 300, 840, 0.62, -10))
    n = ec.notes("GANGORRA — escolher o formato (a lógica não muda: cor da luta puxa para um lado; ponta no chão = prêmio)", [
        ("DECIDIR", "A · Balança da grua: tudo pendurado, a viga balança como gangorra."),
        ("DECIDIR", "B · Viga de aço num macaco hidráulico com o mostrador no meio."),
        ("DECIDIR", "C · Tábua de andaime com carrinhos de mão e saco de cimento de peso."),
        ("PROPOSTA", "Recomendo A: grande, legível e ligado à grua do menu (mesma linguagem)."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=21, scale=0.6, freq=0.05))


def tela_presente():
    b = [mv.fundo(0.15), mv.placa(960, 44, 900, 96, "ABRIR O PRESENTE — 5 tempos", True)]
    pw, ph = 364, 470
    passos = ["1 · DECIDE", "2 · SAI DE CENA", "3 · VEM AO CENTRO", "4 · ABRE", "5 · O PRÊMIO"]
    subs = ["a ponta ganhadora bate no chão", "o presente sobe; gangorra desce", "o presente voa girando e cresce",
            "treme, tampa estoura, confete", "prêmio GRANDE, com o nome"]
    for i in range(5):
        x = 20 + i * (pw + 12)
        y = 180
        b.append(ec.chunk(x, y, pw, ph, "#cfeef3", 18, 5, 6))
        b.append(f'<clipPath id="cp{i}"><rect x="{x}" y="{y}" width="{pw}" height="{ph}" rx="18"/></clipPath><g clip-path="url(#cp{i})">')
        cx, cy = x + pw / 2, y + ph / 2 + 40
        if i == 0:
            b.append(formato_a(cx, y + ph - 20, 0.36, -12))
            b.append(f'<circle cx="{cx - 134}" cy="{y + ph - 24}" r="40" fill="#fff3b0" opacity="0.7"/>')
        elif i == 1:
            b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="#1a1a2a" opacity="0.35"/>')
            b.append(f'<g opacity="0.8">{formato_a(cx, y + ph + 90, 0.36, -12)}</g>')
            b.append(f'<path d="M{cx - 120},{y + ph - 110} Q{cx - 140},{y + 300} {cx - 60},{y + 210}" stroke="#ffffff" stroke-width="5" fill="none" stroke-dasharray="12 8"/>')
            b.append(presente(cx - 40, y + 190, 0.7, "SKIN"))
            for dx in (90, 140):
                b.append(f'<path d="M{cx + dx},{y + ph - 170} v60" stroke="#ffffff" stroke-width="6"/>' + f'<path d="M{cx + dx - 14},{y + ph - 124} l14,20 l14,-20" stroke="#ffffff" stroke-width="6" fill="none"/>')
        elif i == 2:
            b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="#1a1a2a" opacity="0.5"/>')
            b.append(f'<path d="M{x + 40},{y + 330} Q{cx - 60},{y + 120} {cx},{cy - 10}" stroke="#ffffff" stroke-width="5" fill="none" stroke-dasharray="12 8"/>')
            b.append(f'<g transform="rotate(-12 {cx} {cy})">{presente(cx, cy, 1.1, "SKIN")}</g>')
        elif i == 3:
            b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="#1a1a2a" opacity="0.5"/>')
            b.append(presente(cx, cy + 40, 1.1, "", tampa=0.6, brilho=1.0))
            for k in range(18):
                a = k * 0.35
                b.append(f'<rect x="{cx + math.cos(a) * (60 + k * 6):.0f}" y="{cy - 60 + math.sin(a) * (40 + k * 5):.0f}" width="10" height="16" fill="{["#d42035", "#5cc45c", "#4f86d9", YEL][k % 4]}" transform="rotate({k * 37} {cx} {cy})"/>')
        else:
            b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" fill="#1a1a2a" opacity="0.55"/>')
            for k in range(14):
                a = k * math.pi / 7
                b.append(f'<path d="M{cx},{cy - 30} L{cx + math.cos(a) * 300:.0f},{cy - 30 + math.sin(a) * 300:.0f} L{cx + math.cos(a + 0.2) * 300:.0f},{cy - 30 + math.sin(a + 0.2) * 300:.0f}Z" fill="#fff4c8" opacity="0.55"/>')
            b.append(f'<ellipse cx="{cx}" cy="{cy + 120}" rx="110" ry="22" fill="#8d98a4" stroke="{INK}" stroke-width="5"/>')
            b.append(fp.robot("marretao", "parado", "#4f86d9", cx, cy + 118, 2.4))
            b.append(f'<path d="M{cx - 40},{cy - 150} C{cx - 40},{cy - 190} {cx + 40},{cy - 190} {cx + 40},{cy - 150} Z" fill="#e8b84a" stroke="{INK}" stroke-width="5"/>')
            b.append(ec.chunk(cx - 150, y + 30, 300, 70, YEL, 12, 5, 6) + ec.T(cx, y + 78, "SKIN NOVA!", 34))
            b.append(ec.T(cx, y + ph - 30, "MESTRE DE OBRAS", 28, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"'))
            b.append(f'<rect x="{cx + 70}" y="{cy - 100}" width="78" height="34" rx="8" fill="#d42035" stroke="{INK}" stroke-width="4" transform="rotate(14 {cx + 100} {cy - 80})"/>'
                     + ec.T(cx + 109, cy - 75, "NOVO", 20, "#ffffff"))
        b.append("</g>")
        b.append(ec.T(x + pw / 2, y + ph + 50, passos[i], 30) + ec.T(x + pw / 2, y + ph + 86, subs[i], 20, "#2a4a58", w=600))
    b.append(ec.chunk(220, 780, 1480, 120, CREAM, 18, 5, 6))
    b.append(ec.T(960, 830, "O prêmio aparece do jeito que ele é: SKIN = o robô do jogador vestindo, girando num pedestal; ENGENHOCA = o cartucho/arma", 22, INK, w=600))
    b.append(ec.T(960, 866, "flutuando com brilho; EVENTO = o ícone do evento. Nome grande + selo NOVO. PULAR segue para os Projetos.", 22, INK, w=600))
    n = ec.notes("ABRIR O PRESENTE — a gangorra decide, sai de cena e o presente vira o centro da tela (proposta)", [
        ("PROPOSTA", "1 decide (ponta bate no chão) · 2 o presente sobe, a gangorra desce e a tela escurece."),
        ("PROPOSTA", "3 voa ao centro girando e cresce · 4 treme 3×, tampa estoura, raios + confete."),
        ("PROPOSTA", "5 o prêmio GRANDE no pedestal (skin no robô do jogador / arma / ícone) + nome + NOVO."),
        ("PROPOSTA", "~4 s; PULAR adianta; sem prêmio a gangorra só mostra NÃO CONTOU."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=22, scale=0.6, freq=0.05))


def tela_mapas_grade():
    b = [mv.fundo(), mv.chao(1000)]
    for k in range(9):
        x = -40 + k * 230
        b.append(fp.R(x, 150, 236, 860, "#7fae86" if k % 2 == 0 else "#86b48c", 2, 2.4, dark="#5f8f68"))
    b.append(fp.cd.zebra(-20, 132, W + 40, 22))
    b.append(f'<path d="M960,0 V40" stroke="#4a4f5c" stroke-width="5"/>' + mv.corrente(820, 40, 56) + mv.corrente(1100, 40, 56))
    b.append(mv.placa(960, 50, 560, 84, "ESCOLHA O MAPA", True))
    thumb = Image.open(os.path.join(ec.ROOT, "game/assets/ui/arena_canteiro_obras.png")).convert("RGB")
    cw, ch, gx, gy = 470, 218, 30, 20
    x0 = (W - (3 * cw + 2 * gx)) / 2
    y0 = 200
    nomes = [("SORTEIO", "sorteio"), ("CANTEIRO DE OBRAS", "canteiro")] + [("? ? ?", "bloq")] * 7
    for i, (nm, kind) in enumerate(nomes):
        c, r = i % 3, i // 3
        x, y = x0 + c * (cw + gx), y0 + r * (ch + gy)
        sel = i == 1
        if sel:
            b.append(f'<rect x="{x - 12}" y="{y - 12}" width="{cw + 24}" height="{ch + 24}" rx="14" fill="{YEL}" stroke="{INK}" stroke-width="6"/>')
        b.append(fp.R(x, y, cw, ch, "#f6eedb", 6, 1.4, dark="#d9c7a3") + f'<rect x="{x}" y="{y}" width="{cw}" height="{ch}" rx="6" fill="none" stroke="{INK}" stroke-width="5"/>')
        b.append(f'<rect x="{x - 14}" y="{y - 8}" width="70" height="24" fill="#e8d9a8" opacity="0.9" transform="rotate(-28 {x + 20} {y + 4})"/>')
        if kind == "sorteio":
            b.append(f'<rect x="{x + 16}" y="{y + 16}" width="{cw * 0.5}" height="{ch - 32}" rx="6" fill="#9fe3ee" stroke="{INK}" stroke-width="4"/>' + ec.title(x + 16 + cw * 0.25, y + ch / 2 + 44, "?", 130, YEL))
            b.append(ec.T(x + cw * 0.77, y + ch / 2 - 4, "SORTEIO", 30) + ec.T(x + cw * 0.77, y + ch / 2 + 30, "a grua escolhe", 18, "#6b5a70", w=600))
        elif kind == "canteiro":
            b.append(f'<clipPath id="cmt"><rect x="{x + 16}" y="{y + 16}" width="{cw * 0.5}" height="{ch - 32}" rx="6"/></clipPath>')
            b.append(f'<image clip-path="url(#cmt)" href="{ec.uri_img(thumb)}" x="{x + 16}" y="{y + 16}" width="{cw * 0.5}" height="{ch - 32}" preserveAspectRatio="xMidYMid slice"/>')
            b.append(f'<rect x="{x + 16}" y="{y + 16}" width="{cw * 0.5}" height="{ch - 32}" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
            b.append(ec.T(x + cw * 0.77, y + 60, "CANTEIRO", 30) + ec.T(x + cw * 0.77, y + 92, "DE OBRAS", 30))
            for k, ok in enumerate((True, True, False)):
                hx, hy = x + cw * 0.77 - 60 + k * 60, y + ch - 50
                col = "#f2c84b" if ok else "#c9c2b2"
                b.append(f'<path d="M{hx - 22},{hy} C{hx - 22},{hy - 28} {hx + 22},{hy - 28} {hx + 22},{hy} Z" fill="{col}" stroke="{INK}" stroke-width="4"/><rect x="{hx - 28}" y="{hy - 3}" width="56" height="8" rx="3" fill="{col}" stroke="{INK}" stroke-width="3"/>')
            b.append(mv.chip(x + cw - 60, y - 30))
        else:
            b.append(f'<path d="M{x - 6},{y + 14} L{x + cw + 6},{y - 4} L{x + cw + 4},{y + ch + 6} L{x - 4},{y + ch - 4}Z" fill="#3f7fb5" opacity="0.92"/>')
            b.append(f'<path d="M{x - 6},{y + ch * 0.46} L{x + cw + 6},{y + ch * 0.54}" stroke="#8d98a4" stroke-width="8" stroke-dasharray="12 5"/>')
            b.append(fp.R(x + cw / 2 - 28, y + ch / 2 - 22, 56, 46, YEL, 8, 1.2) + f'<path d="M{x + cw / 2 - 16},{y + ch / 2 - 22} v-16 a16,16 0 0 1 32,0 v16" stroke="{INK}" stroke-width="7" fill="none"/>')
            b.append(ec.T(x + cw / 2, y + ch - 24, "EM BREVE", 22, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))
    for sx, d in ((70, "◄"), (W - 70, "►")):   # setas: desliza para o lado
        b.append(f'<circle cx="{sx}" cy="{y0 + 1.5 * ch + gy}" r="46" fill="{YEL}" stroke="{INK}" stroke-width="6"/>' + ec.T(sx, y0 + 1.5 * ch + gy + 18, d, 44))
    for k in range(2):   # páginas
        b.append(f'<circle cx="{x0 + 20 + k * 40}" cy="{y0 + 3 * ch + 2 * gy + 40}" r="12" fill="{INK if k == 0 else "#ffffff"}" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(x0 + 110, y0 + 3 * ch + 2 * gy + 48, "página 1/2", 20, "#2a4a58", "start", w=600))
    px0 = x0 + 3 * cw + 2 * gx - 620
    py0 = y0 + 3 * ch + 2 * gy + 12
    b.append(fp.R(px0, py0, 620, 60, "#f6eedb", 6, 1.4) + f'<rect x="{px0}" y="{py0}" width="620" height="60" rx="6" fill="none" stroke="{INK}" stroke-width="4"/>')
    b.append(ec.T(px0 + 20, py0 + 28, "PROJETOS DE", 18, INK, "start") + ec.T(px0 + 20, py0 + 50, "DEMOLIÇÃO", 18, INK, "start"))
    for k in range(6):
        b.append(f'<rect x="{px0 + 180 + k * 62}" y="{py0 + 10}" width="62" height="40" fill="{("#d42035" if k % 2 == 0 else "#ffffff") if k < 4 else "#e2d9c6"}" stroke="{INK}" stroke-width="3"/>')
    b.append(mv.plaquinha_dica("◄►▲▼ escolher  ·  na borda: desliza a página  ·  PULAR confirmar  ·  ESC voltar"))
    n = ec.notes("MAPAS em grade 3 × 3 (proposta)", [
        ("PROPOSTA", "9 cartazes por página (3 × 3), mais aberto; o escolhido ganha moldura amarela."),
        ("PROPOSTA", "◄► na borda da grade desliza para a próxima página; bolinhas = páginas."),
        ("PROPOSTA", "Cartaz = foto + nome + capacetes das cenas; bloqueado = lona azul, cadeado, EM BREVE."),
        ("PROPOSTA", "Hoje: Sorteio + Canteiro + 7 'em breve'; a 2ª página vem com os mapas novos."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=23, scale=0.6, freq=0.05))


def main():
    os.makedirs(OUT, exist_ok=True)
    boards = [("g1_gangorra_formatos", tela_formatos()), ("g2_presente", tela_presente()), ("m1_mapas_grade", tela_mapas_grade())]
    import json, subprocess, tempfile
    tmp = tempfile.mkdtemp(prefix="recompensas2_")
    jobs = []
    for name, svg in boards:
        p = os.path.join(tmp, name + ".svg")
        open(p, "w").write(svg)
        jobs.append({"svg": p, "png": os.path.join(OUT, name + ".png"), "w": W, "h": H + ec.NOTES_H, "scale": 1})
    jp = os.path.join(tmp, "jobs.json")
    json.dump(jobs, open(jp, "w"))
    subprocess.run(["node", os.path.join(ec.ROOT, "tools/render_svg.js"), jp], check=True)
    for j in jobs:
        Image.open(j["png"]).convert("RGB").save(j["png"], optimize=True)
        print(j["png"])


if __name__ == "__main__":
    main()
