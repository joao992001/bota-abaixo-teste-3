"""Etapa C da reformulação do Derruba — pranchas das telas para APROVAR (não é arte final de jogo).
Cada prancha = tela 1920x1080 no estilo do kit de UI (cartão creme, contorno grosso, sombra dura) + faixa de notas.
Usa ícones e capturas reais (art/out/menus, gerados por `--menus=DIR`).
Rodar: python3 art/src/ui/etapa_c.py  → art/out/etapa_c/*.png   (precisa de Pillow e do Chromium/Playwright)
"""
import base64
import io
import json
import math
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageEnhance, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
A = os.path.join(ROOT, "game/assets")
OUT = os.path.join(ROOT, "art/out/etapa_c")
MENUS = os.path.join(ROOT, "art/out/menus")

INK, CREAM, YEL, SOFT = "#2a1a2e", "#fff6e4", "#ffd34d", "#6b5a70"
PCOL = ["#2f8ff0", "#5fd35f", "#ff6fb5", "#ffd23f"]
FAM = {"ataque": "#f0883a", "controle": "#8a5ad8", "engenharia": "#f2c84b", "transformacao": "#3cb6c4"}
FAM_NOME = {"ataque": "ATAQUE", "controle": "CONTROLE", "engenharia": "ENGENHARIA", "transformacao": "TRANSFORMAÇÃO"}
# manômetro: 6 zonas (verde intenso → vermelho intenso). Limites = PROPOSTA (pendente na revisão).
ZONAS = [(0, 20, "#2e9e4f"), (20, 35, "#8fd46a"), (35, 50, "#f2d04b"), (50, 70, "#f39a3a"), (70, 90, "#ec6448"), (90, 100, "#a8233a")]
W, H, NOTES_H = 1920, 1080, 250

SPELLS = [  # id, nome, família, ícone (peça do equipamento; None = ícone da família)
    ("A01", "PUNHO PNEUMÁTICO", "ataque", "spells/s01_luva"), ("A02", "LASER DE CORTE", "ataque", "spells/s02_laser"),
    ("A03", "CANHÃO CRIOGÊNICO", "ataque", "spells/s03_canhao"), ("A04", "MARRETA SÍSMICA", "ataque", "spells/s04_marreta"),
    ("A05", "REBITEIRA RICOCHETE", "ataque", "spells/s05_rebiteira"), ("A06", "BATE-ESTACA", "ataque", "spells/s17_estaca"),
    ("A07", "MARRETA-BUMERANGUE", "ataque", "spells/s04_marreta@rot"), ("A08", "CANHÃO DE MOLAS", "ataque", "spells/s20_canhao"),
    ("C01", "SUPERÍMÃ", "controle", "spells/s06_ima"), ("C02", "TURBOVENTILADOR", "controle", "spells/s07_ventilador"),
    ("C03", "GANCHO DE ARRASTO", "controle", "spells/s08_gancho"), ("C04", "TELEPORTE", "controle", None),
    ("C05", "LAÇO DE ENERGIA", "controle", "spells/s21_laco"),
    ("E01", "ANDAIME RELÂMPAGO", "engenharia", "spells/s10_tabua"), ("E02", "CARGA REMOTA", "engenharia", "spells/s12_carga"),
    ("E03", "CONTROLE REMOTO", "engenharia", "spells/s27_controle"),
    ("T01", "ARMADURA FORNALHA", "transformacao", "spells/s13_frente"), ("T02", "MECHA EMPILHADEIRA", "transformacao", "spells/s14_chassi"),
    ("T03", "BOLA DE DEMOLIÇÃO", "transformacao", "spells/s15_bola"), ("T04", "PROPULSOR GAMBIARRA", "transformacao", "spells/s16_mochila"),
    ("T05", "MODO BROCA", "transformacao", "spells/s31_broca"), ("T06", "MODO SOLDADOR", "transformacao", "spells/s28_macarico"),
    ("T07", "MINIRROBÔ VELOZ", "transformacao", "spells/s33_mascara"),
]
EVENTOS = [  # id, nome, ícone, cena (None = geral)
    ("G01", "SIRENE DE DEMOLIÇÃO", "@sirene", None), ("G02", "VENTANIA", "spells/g02_helice", None),
    ("G03", "GRAVIDADE EM PANE", "@gravidade", None), ("G04", "SOBRECARGA MAGNÉTICA", "spells/g04_bobina", None),
    ("G05", "OPERAÇÃO GUINDASTE", "spells/g05_moitao", None), ("G06", "ENTREGA DE ENTULHO", "spells/g06_caixa", None),
    ("G10", "CARGA ESPECIAL", "spells/g10_capsula", None), ("G11", "INTERDIÇÃO DE ÁREA", "spells/g11_tapume", None),
    ("G12", "TROCA DE ANDAIMES", "fase1/plataforma", None), ("G13", "CABO ROMPIDO", "@viga", None),
    ("G14", "CHUVA DE REBITES", "spells/g14_rebite", None),
    ("V1", "CONCRETAGEM", "fase1/balde", "TÉRREO"), ("V2", "DESMORONAMENTO", "spells/g06_sucata", "FUNDAÇÃO"),
    ("V3", "ENCHENTE", "@agua", "FUNDAÇÃO"),
]


# ---------------------------------------------------------------- utilidades
def uri_img(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def asset(rel):
    rot = rel.endswith("@rot")
    im = Image.open(os.path.join(A, rel.replace("@rot", "") + ".png")).convert("RGBA")
    if rot:
        im = im.rotate(-55, expand=True, resample=Image.BICUBIC)
    return im.crop(im.getbbox())


def img(im, cx, cy, maxw, maxh, extra=""):
    k = min(maxw / im.width, maxh / im.height)
    w, h = im.width * k, im.height * k
    return f'<image href="{uri_img(im)}" x="{cx - w / 2:.1f}" y="{cy - h / 2:.1f}" width="{w:.1f}" height="{h:.1f}" {extra}/>'


def T(x, y, s, size=28, col=INK, anchor="middle", w=700, extra=""):
    return (f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="{w}" font-size="{size}" fill="{col}" '
            f'text-anchor="{anchor}" {extra}>{s}</text>')


def title(x, y, s, size=76, col="#ffffff"):
    o = max(int(size * 0.17), 4)
    st = f'stroke="{INK}" stroke-width="{o * 2}" stroke-linejoin="round" paint-order="stroke"'
    return T(x, y + size * 0.09, s, size, INK, extra=st) + T(x, y, s, size, col, extra=st)


def chunk(x, y, w, h, fill=CREAM, r=26, border=6, shadow=10, extra=""):
    s = f'<rect x="{x}" y="{y + shadow}" width="{w}" height="{h}" rx="{r}" fill="{INK}"/>' if shadow else ""
    return s + f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{INK}" stroke-width="{border}" {extra}/>'


def lines(x, y, txt, size, col=INK, anchor="middle", lh=1.12, w=700):
    out = ""
    for i, ln in enumerate(txt.split("\n")):
        out += T(x, y + i * size * lh, ln, size, col, anchor, w)
    return out


def wrap2(nome, maxc=12):
    if "-" in nome and " " not in nome:
        a, c = nome.split("-", 1)
        return a + "-\n" + c
    ws, a = nome.split(), ""
    if len(nome) <= maxc:
        return nome
    for i in range(1, len(ws)):
        a = " ".join(ws[:i])
        if len(" ".join(ws[:i + 1])) > maxc:
            return a + "\n" + " ".join(ws[i:])
    return nome


def backdrop(name, blur=14, dark=0.82):
    im = Image.open(os.path.join(MENUS, name)).convert("RGB").resize((W, H))
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    im = ImageEnhance.Brightness(im).enhance(dark)
    return f'<image href="{uri_img(im)}" x="0" y="0" width="{W}" height="{H}"/>'


def hint(txt):
    return T(W / 2, 1052, txt, 26, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')


def notes(head, items):
    y0 = H
    b = f'<rect x="0" y="{y0}" width="{W}" height="{NOTES_H}" fill="#f4ecd8"/><rect x="0" y="{y0}" width="{W}" height="8" fill="{INK}"/>'
    b += T(40, y0 + 52, head, 30, INK, "start")
    for i, (tag, txt) in enumerate(items):
        col, row = i % 2, i // 2
        x, y = 30 + col * 950, y0 + 100 + row * 46
        colr = {"APROVADO": "#3f9e55", "PROPOSTA": "#e08a1e", "DECIDIR": "#c23a5a", "FUTURO": "#6b7a90"}[tag]
        b += f'<rect x="{x}" y="{y - 26}" width="128" height="36" rx="10" fill="{colr}"/>' + T(x + 64, y - 1, tag, 18, "#ffffff")
        b += T(x + 140, y, txt, 19, INK, "start", w=600)
    return b


def page(body, notes_svg, defs=""):
    f7 = base64.b64encode(open(os.path.join(A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    gray = '<filter id="cinza"><feColorMatrix type="saturate" values="0.05"/><feComponentTransfer><feFuncA type="linear" slope="0.45"/></feComponentTransfer></filter>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H + NOTES_H}" viewBox="0 0 {W} {H + NOTES_H}">'
            f'{style}<defs>{gray}{defs}</defs>{body}{notes_svg}</svg>')


# ---------------------------------------------------------------- desenhos simples (ícones que não existem como peça)
def glyph(kind, cx, cy, s=1.0):
    if kind == "@sirene":
        return (f'<rect x="{cx - 46 * s}" y="{cy + 18 * s}" width="{92 * s}" height="{22 * s}" rx="6" fill="#4a4f5c"/>'
                f'<path d="M{cx - 36 * s},{cy + 18 * s} v{-26 * s} a{36 * s},{36 * s} 0 0 1 {72 * s},0 v{26 * s}z" fill="#e8483f"/>'
                f'<path d="M{cx - 18 * s},{cy - 2 * s} a{18 * s},{18 * s} 0 0 1 {16 * s},{-18 * s}" stroke="#ffd0c8" stroke-width="{7 * s}" fill="none" stroke-linecap="round"/>'
                + "".join(f'<line x1="{cx + math.cos(a) * 58 * s}" y1="{cy - 8 * s + math.sin(a) * 58 * s}" x2="{cx + math.cos(a) * 76 * s}" '
                          f'y2="{cy - 8 * s + math.sin(a) * 76 * s}" stroke="#ffd34d" stroke-width="{8 * s}" stroke-linecap="round"/>'
                          for a in (math.pi * 1.1, math.pi * 1.5, math.pi * 1.9)))
    if kind == "@gravidade":
        b = ""
        for i, (dx, dy, r) in enumerate([(-30, 20, 22), (24, -10, 17), (-6, -44, 12)]):
            b += f'<rect x="{cx + dx * s - r * s}" y="{cy + dy * s - r * s}" width="{2 * r * s}" height="{2 * r * s}" rx="{5 * s}" fill="#c98a4b" transform="rotate({i * 17 - 12} {cx + dx * s} {cy + dy * s})"/>'
        return b + f'<path d="M{cx + 50 * s},{cy + 50 * s} v{-70 * s} m{-14 * s},{14 * s} l{14 * s},{-14 * s} l{14 * s},{14 * s}" stroke="#ffffff" stroke-width="{8 * s}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    if kind == "@viga":
        return (f'<line x1="{cx - 10 * s}" y1="{cy - 70 * s}" x2="{cx - 10 * s}" y2="{cy - 28 * s}" stroke="#4a4f5c" stroke-width="{5 * s}"/>'
                f'<line x1="{cx + 10 * s}" y1="{cy - 70 * s}" x2="{cx + 16 * s}" y2="{cy - 40 * s}" stroke="#4a4f5c" stroke-width="{5 * s}"/>'
                f'<g transform="rotate(-14 {cx} {cy})"><rect x="{cx - 70 * s}" y="{cy - 14 * s}" width="{140 * s}" height="{30 * s}" fill="#6f7a8c"/>'
                f'<rect x="{cx - 70 * s}" y="{cy - 14 * s}" width="{140 * s}" height="{8 * s}" fill="#ffd34d"/></g>'
                f'<rect x="{cx - 80 * s}" y="{cy + 50 * s}" width="{160 * s}" height="{14 * s}" fill="#d42035" opacity="0.85"/>')
    if kind == "@agua":
        b = f'<rect x="{cx - 66 * s}" y="{cy - 4 * s}" width="{132 * s}" height="{64 * s}" rx="{10 * s}" fill="#3d9ad6"/>'
        for k in range(3):
            y = cy - 4 * s + k * 20 * s
            b += f'<path d="M{cx - 66 * s},{y} q{16 * s},{-12 * s} {33 * s},0 t{33 * s},0 t{33 * s},0 t{33 * s},0" stroke="#bfe6ff" stroke-width="{5 * s}" fill="none"/>'
        return b + f'<path d="M{cx},{cy - 70 * s} l0,{40 * s} m{-14 * s},{-14 * s} l{14 * s},{-26 * s} l{14 * s},{26 * s}" stroke="#ffffff" stroke-width="{8 * s}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    return ""


def icon(ref, cx, cy, mw, mh, extra=""):
    if ref.startswith("@"):
        g = glyph(ref, cx, cy, min(mw, mh) / 150)
        return f'<g {extra}>{g}</g>'
    return img(asset(ref), cx, cy, mw, mh, extra)


def tag_p(x, y, n):
    """Setinha do jogador (P1–P4 na cor dele) apontando para baixo."""
    c = PCOL[n - 1]
    return (f'<path d="M{x - 30},{y - 54} h60 v34 h-16 l-14,18 l-14,-18 h-16z" fill="{c}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
            + T(x, y - 28, f"P{n}", 24, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))


def chip_p(x, y, n):
    c = PCOL[n - 1]
    return (f'<rect x="{x}" y="{y}" width="64" height="40" rx="12" fill="{c}" stroke="{INK}" stroke-width="5"/>'
            + T(x + 32, y + 30, f"P{n}", 24, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))


def check(x, y, on=True):
    if on:
        return (f'<circle cx="{x}" cy="{y}" r="22" fill="#5fc95f" stroke="{INK}" stroke-width="5"/>'
                f'<path d="M{x - 10},{y + 1} l7,8 l13,-16" stroke="#ffffff" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    return f'<circle cx="{x}" cy="{y}" r="20" fill="#d9d2c4" stroke="{INK}" stroke-width="5"/>'


def lock(cx, cy, s=1.0):
    return (f'<path d="M{cx - 22 * s},{cy} v{-18 * s} a{22 * s},{22 * s} 0 0 1 {44 * s},0 v{18 * s}" stroke="{INK}" stroke-width="{10 * s}" fill="none"/>'
            f'<rect x="{cx - 36 * s}" y="{cy - 4 * s}" width="{72 * s}" height="{56 * s}" rx="{10 * s}" fill="{YEL}" stroke="{INK}" stroke-width="{6 * s}"/>'
            f'<circle cx="{cx}" cy="{cy + 22 * s}" r="{7 * s}" fill="{INK}"/>')


# ---------------------------------------------------------------- telas
def card_sel(x, y, w, h, color, ref, nome, on, cursor=False, badge=None, fam_icon=None):
    b = ""
    if cursor:
        b += f'<rect x="{x - 14}" y="{y - 14}" width="{w + 28}" height="{h + 28}" rx="34" fill="{YEL}" stroke="{INK}" stroke-width="6"/>'
    filt = "" if on else 'filter="url(#cinza)"'
    b += chunk(x, y, w, h, CREAM if on else "#e7e0d2")
    b += f'<g {filt}>'
    b += f'<path d="M{x + 3},{y + 40} v-11 a23,23 0 0 1 23,-23 h{w - 52} a23,23 0 0 1 23,23 v11z" fill="{color}"/>'
    b += f'<line x1="{x}" y1="{y + 42}" x2="{x + w}" y2="{y + 42}" stroke="{INK}" stroke-width="5"/>'
    if fam_icon:
        b += img(asset(fam_icon), x + 30, y + 24, 26, 26)
    b += icon(ref, x + w / 2, y + 42 + (h - 42 - 62) / 2, w - 46, h - 42 - 84)
    b += lines(x + w / 2, y + h - 40, wrap2(nome), 18)
    b += "</g>"
    if badge:
        b += f'<rect x="{x + w / 2 - 62}" y="{y - 18}" width="124" height="32" rx="10" fill="{INK}"/>' + T(x + w / 2, y + 6, badge, 18, YEL)
    b += check(x + w - 12, y + 12, on)
    return b


def tela_spells():
    b = backdrop("m2_modos.png") + title(W / 2, 108, "ESCOLHA AS SPELLS")
    b += chunk(70, 50, 330, 64, CREAM, 18, 5, 7) + T(235, 93, "CANTEIRO DE OBRAS", 26)
    off = {"C04", "T06", "T07", "E01"}
    cw, ch, gap = 182, 214, 26
    x0 = (W - (8 * cw + 7 * gap)) / 2
    order = [s for s in SPELLS]
    cells = order[:8] + order[8:16] + order[16:] + [("RND", "ALEATÓRIO", "", None)]
    for i, (sid, nome, fam, ref) in enumerate(cells):
        x, y = x0 + (i % 8) * (cw + gap), 190 + (i // 8) * (ch + 34)
        if sid == "RND":
            b += chunk(x, y, cw, ch, YEL)
            b += title(x + cw / 2, y + 128, "?", 110, "#ffffff") + lines(x + cw / 2, y + ch - 26, "ALEATÓRIO", 22)
            continue
        b += card_sel(x, y, cw, ch, FAM[fam], ref or f"spells/icone_{fam}", nome, sid not in off,
                      cursor=(sid == "T03"), fam_icon=f"spells/icone_{fam}")
        if sid == "T03":
            b += chip_p(x - 30, y - 30, 1)
    # rodapé: contador + legenda das famílias + estados
    b += chunk(120, 905, 1680, 108, CREAM, 22, 6, 9)
    b += T(170, 972, f"{23 - len(off)} de 23 ligadas", 36, INK, "start")
    lx = 560
    for f in FAM:
        b += f'<rect x="{lx}" y="{944}" width="34" height="34" rx="8" fill="{FAM[f]}" stroke="{INK}" stroke-width="4"/>' + T(lx + 46, 972, FAM_NOME[f], 24, INK, "start")
        lx += 66 + len(FAM_NOME[f]) * 15
    b += check(1470, 958, True) + T(1500, 968, "acesa", 22, INK, "start") + check(1610, 958, False) + T(1640, 968, "apagada", 22, INK, "start")
    b += hint("◄►▲▼ escolher · PULAR acende/apaga · ATACAR tudo/nada · START continuar · ESC voltar")
    n = notes("Tela de SPELLS — define o conjunto que pode sair nas caixas (não equipa ninguém)", [
        ("APROVADO", "Mosaico por controle; PULAR acende/apaga; card ALEATÓRIO; tudo liberado (A9)."),
        ("APROVADO", "Família pela cor da faixa + ícone da caixa (sem abas)."),
        ("PROPOSTA", "ATACAR liga/desliga tudo; START segue para EVENTOS; o cursor é do P1."),
        ("DECIDIR", "Mínimo/máximo de spells ligadas (sugestão: mín. 4, sem máximo)."),
        ("PROPOSTA", "ALEATÓRIO = sorteia 8 spells (2 de cada família) e acende só elas."),
        ("FUTURO", "Spell bloqueada na conta = silhueta + cadeado (progressao.md)."),
    ])
    return page(b, n)


def tela_eventos():
    b = backdrop("m2_modos.png") + title(W / 2, 108, "ESCOLHA OS EVENTOS")
    b += chunk(70, 50, 330, 64, CREAM, 18, 5, 7) + T(235, 93, "CANTEIRO DE OBRAS", 26)
    cw, ch, gap = 182, 250, 26
    x0 = (W - (8 * cw + 7 * gap)) / 2
    off = {"G11", "V3"}
    cells = [("NONE", "NENHUM", None, None)] + EVENTOS + [("RND", "ALEATÓRIO", None, None)]
    for i, (eid, nome, ref, cena) in enumerate(cells):
        x, y = x0 + (i % 8) * (cw + gap), 200 + (i // 8) * (ch + 56)
        if eid == "NONE":
            b += chunk(x, y, cw, ch, "#e7e0d2")
            b += (f'<circle cx="{x + cw / 2}" cy="{y + 106}" r="56" fill="none" stroke="{INK}" stroke-width="12"/>'
                  f'<line x1="{x + cw / 2 - 40}" y1="{y + 146}" x2="{x + cw / 2 + 40}" y2="{y + 66}" stroke="{INK}" stroke-width="12"/>')
            b += lines(x + cw / 2, y + ch - 34, "NENHUM", 24) + check(x + cw - 12, y + 12, False)
            continue
        if eid == "RND":
            b += chunk(x, y, cw, ch, YEL) + title(x + cw / 2, y + 150, "?", 120, "#ffffff") + lines(x + cw / 2, y + ch - 30, "ALEATÓRIO", 22)
            continue
        color = "#6aa6c8" if cena is None else "#c98a4b"
        b += card_sel(x, y, cw, ch, color, ref, nome, eid not in off, cursor=(eid == "G03"),
                      badge=(cena if cena else ("VOLTOU" if eid == "G01" else None)))
        b += T(x + 18, y + 32, eid, 22, "#ffffff", "start", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"')
        if eid == "G03":
            b += chip_p(x - 30, y - 30, 1)
    b += chunk(120, 905, 1680, 108, CREAM, 22, 6, 9)
    b += T(170, 972, "12 de 14 ligados", 36, INK, "start")
    b += f'<rect x="560" y="944" width="34" height="34" rx="8" fill="#6aa6c8" stroke="{INK}" stroke-width="4"/>' + T(606, 972, "GERAL (qualquer cena)", 24, INK, "start")
    b += f'<rect x="900" y="944" width="34" height="34" rx="8" fill="#c98a4b" stroke="{INK}" stroke-width="4"/>' + T(946, 972, "DA CENA (selo com o nome)", 24, INK, "start")
    b += T(1760, 972, "mecanismos da cena seguem sempre", 22, SOFT, "end", w=600)
    b += hint("◄►▲▼ escolher · PULAR acende/apaga · NENHUM apaga todos · START continuar · ESC voltar")
    n = notes("Tela de EVENTOS — mesmo padrão da tela de spells", [
        ("APROVADO", "Mosaico; escolha manual, ALEATÓRIO e NENHUM; G01 Sirene volta como evento (A5)."),
        ("APROVADO", "NENHUM não desliga mecanismos da cena (betoneira, elevador, serra, bate-estaca...)."),
        ("PROPOSTA", "Eventos de uma cena só (V1–V3) mostram o selo com o nome da cena."),
        ("DECIDIR", "V1–V3 (viradas) podem ser apagados, ou ficam sempre ligados como parte da cena?"),
        ("DECIDIR", "Máximo de eventos ligados? (sugestão: sem máximo; o diretor de eventos já limita)."),
        ("FUTURO", "Evento bloqueado na conta = silhueta + cadeado (progressao.md)."),
    ])
    return page(b, n)


def gauge(cx, cy, r, pct, label=True, ticks=True):
    """Manômetro: arco de 240° (de 210° a -30°), 6 zonas, agulha, número embaixo."""
    def ang(p):
        return math.radians(210 - 240 * p / 100)

    def pt(p, rr):
        a = ang(p)
        return cx + math.cos(a) * rr, cy - math.sin(a) * rr
    b = f'<circle cx="{cx}" cy="{cy + r * 0.08}" r="{r}" fill="{INK}"/>'
    b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff6e4" stroke="{INK}" stroke-width="{max(4, r * 0.07)}"/>'
    ro, ri = r * 0.86, r * 0.6
    for a0, a1, col in ZONAS:
        x0, y0 = pt(a0, ro)
        x1, y1 = pt(a1, ro)
        x2, y2 = pt(a1, ri)
        x3, y3 = pt(a0, ri)
        lg = 1 if (a1 - a0) * 2.4 > 180 else 0
        b += (f'<path d="M{x0:.1f},{y0:.1f} A{ro},{ro} 0 {lg} 1 {x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f} A{ri},{ri} 0 {lg} 0 {x3:.1f},{y3:.1f}z" '
              f'fill="{col}" stroke="{INK}" stroke-width="{max(2, r * 0.025)}" stroke-linejoin="round"/>')
    if ticks:
        for p in (50, 90):
            xa, ya = pt(p, ri - r * 0.04)
            xb, yb = pt(p, ro + r * 0.08)
            b += f'<line x1="{xa:.1f}" y1="{ya:.1f}" x2="{xb:.1f}" y2="{yb:.1f}" stroke="{INK}" stroke-width="{max(3, r * 0.05)}" stroke-linecap="round"/>'
    xn, yn = pt(pct, r * 0.74)
    xl, yl = pt(pct + 50, r * 0.12)
    xr, yr = pt(pct - 50, r * 0.12)
    b += f'<path d="M{xl:.1f},{yl:.1f} L{xn:.1f},{yn:.1f} L{xr:.1f},{yr:.1f}z" fill="{INK}" stroke="{INK}" stroke-width="{max(2, r * 0.03)}" stroke-linejoin="round"/>'
    b += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.14}" fill="{YEL}" stroke="{INK}" stroke-width="{max(3, r * 0.045)}"/>'
    if label:
        b += title(cx, cy + r * 0.62, f"{pct}%", int(r * 0.34))
    return b


def tela_manometro():
    im = Image.open(os.path.join(MENUS, "m7_partida.png")).convert("RGB")
    im.paste(im.crop((860, 50, 1060, 96)), (860, 4))   # "RODADA 1" sai do HUD: cobre com o céu de logo abaixo
    b = f'<image href="{uri_img(im)}" x="0" y="0" width="{W}" height="{H}"/>'
    b += gauge(W / 2, 74, 62, 62)
    # quadro de detalhe à direita
    b += chunk(1290, 150, 590, 760, CREAM, 26, 6, 10)
    b += T(1585, 212, "MANÔMETRO DA CENA", 34)
    b += gauge(1585, 420, 170, 62)
    xs = [1385, 1585, 1785]
    for x, p, cap in zip(xs, (8, 47, 93), ("cena nova\n(zerou)", "ainda fica\nna cena", "rota TOTAL\nna verificação")):
        b += gauge(x, 690, 62, p)
        b += lines(x, 800, cap, 20, SOFT)
    b += T(1585, 880, "traços pretos = 50% e 90% (rotas)", 22, SOFT, w=600)
    b += f'<path d="M1080,90 C1180,110 1230,150 1286,250" stroke="{INK}" stroke-width="6" fill="none" stroke-dasharray="14 10"/>'
    n = notes("MANÔMETRO no HUD — único elemento novo durante a luta (A6)", [
        ("APROVADO", "Circular, no topo e no centro; destruição da CENA ATUAL; zera ao trocar de cena."),
        ("APROVADO", "Sem cronômetro, rodada, gangorra ou missão no HUD (o “RODADA 1” sai)."),
        ("PROPOSTA", "Zonas: 0–20 · 20–35 · 35–50 (fica) | 50–70 · 70–90 (moderada) · 90–100 (total)."),
        ("PROPOSTA", "Agulha balança e o número pula quando algo cai; o vermelho daqui é vinho, não o do perigo."),
        ("DECIDIR", "Mostrar os 2 traços (50% e 90%)? Ajudam a ler a rota sem mostrar tempo."),
        ("DECIDIR", "Mostrar o número (62%) embaixo da agulha, ou só a agulha?"),
    ])
    return page(b, n)


def tela_resultados():
    b = backdrop("m10_vitoria.png")
    b += f'<rect x="0" y="0" width="{W}" height="{H}" fill="#2a1a2e" opacity="0.28"/>'
    # vencedor (recorte do círculo real da vitória)
    v = Image.open(os.path.join(MENUS, "m10_vitoria.png")).convert("RGBA")
    b += f'<rect x="0" y="0" width="{W}" height="150" fill="none"/>'
    b += title(W / 2, 112, "P1 VENCEU!", 92)
    # ranking (esquerda)
    b += chunk(60, 190, 440, 520, CREAM, 26, 6, 10) + T(280, 250, "RANKING", 34)
    rank = [("1º", 1, "P1", "★ ★"), ("2º", 3, "P3", "★"), ("3º", 2, "P2", ""), ("4º", 4, "P4", "")]
    for i, (pos, pn, nm, st) in enumerate(rank):
        y = 290 + i * 100
        b += chunk(90, y, 380, 80, PCOL[pn - 1] if i == 0 else "#f3ead6", 18, 5, 6)
        b += T(130, y + 54, pos, 36) + f'<circle cx="215" cy="{y + 40}" r="26" fill="{PCOL[pn - 1]}" stroke="{INK}" stroke-width="5"/>'
        b += T(260, y + 52, nm, 32, INK, "start") + T(450, y + 52, st, 32, "#e0a400" if i else "#ffffff", "end",
                                                       extra=f'stroke="{INK}" stroke-width="4" paint-order="stroke"')
    b += T(280, 690, "ordem de eliminação · ★ somam na revanche", 19, SOFT, w=600)
    # centro: vencedor + gangorra + projetos
    cx = 960
    disc = v.crop((960 - 330, 640 - 330, 960 + 330, 640 + 330))   # círculo real do vencedor na tela de vitória
    b += f'<clipPath id="vc"><circle cx="{cx}" cy="330" r="150"/></clipPath>'
    b += f'<circle cx="{cx}" cy="{340}" r="150" fill="{INK}"/>'
    b += f'<image clip-path="url(#vc)" href="{uri_img(disc)}" x="{cx - 150}" y="180" width="300" height="300"/>'
    b += f'<circle cx="{cx}" cy="330" r="150" fill="none" stroke="{INK}" stroke-width="8"/>'
    b += title(cx, 510, "★", 64, YEL)
    b += chunk(560, 560, 800, 200, CREAM, 26, 6, 10) + T(cx, 610, "GANGORRA DE RECOMPENSAS", 30)
    bx0, bx1, by = 650, 1270, 690
    for k, (a0, a1, col) in enumerate(ZONAS):
        b += f'<rect x="{bx0 + k * (bx1 - bx0) / 6}" y="{by - 14}" width="{(bx1 - bx0) / 6}" height="28" fill="{col}"/>'
    b += f'<rect x="{bx0}" y="{by - 14}" width="{bx1 - bx0}" height="28" rx="6" fill="none" stroke="{INK}" stroke-width="5"/>'
    for gx, cat in ((bx0 - 50, "SKIN"), (bx1 + 50, "SPELL")):
        b += chunk(gx - 34, by - 40, 68, 62, YEL, 12, 5, 5) + T(gx, by + 6, "?", 40) + T(gx, by + 52, cat, 18)
    xa, xb = bx0 + (bx1 - bx0) * 0.45, bx0 + (bx1 - bx0) * 0.62
    b += f'<path d="M{xa},{by - 30} L{xb - 12},{by - 30}" stroke="{INK}" stroke-width="6" stroke-dasharray="10 8"/><path d="M{xb - 16},{by - 40} l18,10 l-18,10z" fill="{INK}"/>'
    b += f'<path d="M{xb - 14},{by + 30} l14,-26 l14,26z" fill="{INK}"/>' + T(xb + 70, by - 24, "+35", 28, "#ec6448", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"')
    b += chunk(560, 800, 800, 200, CREAM, 26, 6, 10) + T(cx, 850, "PROJETOS DE DEMOLIÇÃO", 30)
    b += T(600, 900, "+1 partida", 26, INK, "start") + T(600, 940, "+2 cena nova:", 26, INK, "start")
    b += chunk(790, 912, 170, 40, "#ffd34d", 10, 4, 4) + T(875, 941, "FUNDAÇÃO", 22) + chunk(970, 910, 80, 40, "#ec4f88", 10, 4, 4) + T(1010, 939, "NEW", 22, "#ffffff")
    for k in range(6):
        b += f'<rect x="{1080 + k * 42}" y="888" width="36" height="36" rx="8" fill="{"#5fc95f" if k < 5 else "#e2d9c6"}" stroke="{INK}" stroke-width="4"/>'
    b += T(1205, 960, "5 de 6 → mapa novo", 20, SOFT, w=600)
    # direita: opções
    opts = ["JOGAR DE NOVO", "CONFIGURAR MAPA", "SELECIONAR MAPA", "MENU PRINCIPAL"]
    for i, o in enumerate(opts):
        y = 230 + i * 130
        if i == 0:
            b += f'<rect x="1436" y="{y - 12}" width="448" height="104" rx="30" fill="{YEL}" stroke="{INK}" stroke-width="6"/>'
        b += chunk(1450, y, 420, 80, CREAM if i else "#fff1b8", 22, 6, 8) + T(1660, y + 52, o, 30)
    b += tag_p(1660, 218, 1)
    b += T(1660, 770, "exploração: descobriu 1 cena", 24, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
    b += hint("▲▼ escolher · PULAR confirmar")
    n = notes("RESULTADOS — fim da partida (uma luta só, vidas 3–6)", [
        ("APROVADO", "Ranking por ordem de eliminação + estrela do vencedor; 4 opções (A7)."),
        ("APROVADO", "Gangorra e Projetos só aqui (nunca no HUD); prêmios mostram só a categoria."),
        ("PROPOSTA", "Ordem: vencedor → gangorra (agulha anda) → projetos (+1/+2) → opções."),
        ("DECIDIR", "Faixas % das 6 cores e deltas da gangorra (hoje: exemplo −75…+75)."),
        ("DECIDIR", "O que é partida “válida” para pontos (KO muito cedo conta?)."),
        ("PROPOSTA", "Títulos engraçados (Marreteiro, Demolidor...) seguem, menores, se couber."),
    ])
    return page(b, n)


def tela_mapas():
    b = backdrop("m4b_arenas.png") + title(W / 2, 108, "ESCOLHA O MAPA")
    # Canteiro (desbloqueado)
    x, y, w, h = 160, 190, 820, 640
    b += f'<rect x="{x - 14}" y="{y - 14}" width="{w + 28}" height="{h + 28}" rx="34" fill="{YEL}" stroke="{INK}" stroke-width="6"/>'
    b += chunk(x, y, w, h, CREAM) + tag_p(x + w / 2, y - 20, 1)
    art = asset("ui/arena_canteiro_obras")
    b += f'<clipPath id="ca"><rect x="{x + 26}" y="{y + 26}" width="{w - 52}" height="380" rx="14"/></clipPath>'
    k = max((w - 52) / art.width, 380 / art.height)
    b += f'<image clip-path="url(#ca)" href="{uri_img(art)}" x="{x + 26}" y="{y + 26}" width="{art.width * k}" height="{art.height * k}"/>'
    b += f'<rect x="{x + 26}" y="{y + 26}" width="{w - 52}" height="380" rx="14" fill="none" stroke="{INK}" stroke-width="5"/>'
    b += T(x + w / 2, y + 460, "CANTEIRO DE OBRAS", 44)
    # mini grafo de cenas
    gx, gy = x + 140, y + 560
    nodes = [(gx, gy, "TÉRREO", True), (gx + 300, gy - 40, "MODERADA", False), (gx + 300, gy + 40, "FUNDAÇÃO", True)]
    b += f'<path d="M{gx + 36},{gy} L{gx + 264},{gy - 40} M{gx + 36},{gy} L{gx + 264},{gy + 40}" stroke="{INK}" stroke-width="5"/>'
    for nx, ny, nm, known in nodes:
        b += f'<circle cx="{nx}" cy="{ny}" r="28" fill="{"#5fc95f" if known else "#d9d2c4"}" stroke="{INK}" stroke-width="5"/>'
        b += T(nx, ny + 11, "✓" if known else "?", 30, "#ffffff" if known else INK)
        if nx == gx:
            b += T(nx, ny + 62, nm, 24)
        else:
            b += T(nx + 44, ny + 9, nm, 24, INK if known else SOFT, "start")
    b += T(x + w - 40, gy + 10, "2 de 3 cenas", 28, INK, "end")
    # bloqueados
    for i in range(2):
        bx, by = 1060 + i * 380, 260
        b += chunk(bx, by, 340, 470, "#e7e0d2")
        b += f'<rect x="{bx + 24}" y="{by + 24}" width="292" height="250" rx="14" fill="#9fb4b8" stroke="{INK}" stroke-width="5"/>'
        b += lock(bx + 170, by + 140, 1.3) + T(bx + 170, by + 330, "? ? ?", 40, SOFT) + T(bx + 170, by + 380, "mapa bloqueado", 24, SOFT, w=600)
    # projetos de demolição
    b += chunk(1060, 780, 720, 110, CREAM, 22, 6, 9)
    b += T(1090, 828, "PROJETOS DE DEMOLIÇÃO", 26, INK, "start")
    for k in range(6):
        b += f'<rect x="{1090 + k * 52}" y="842" width="44" height="34" rx="8" fill="{"#5fc95f" if k < 4 else "#e2d9c6"}" stroke="{INK}" stroke-width="4"/>'
    b += T(1420, 868, "4 de 6 → você escolhe o próximo", 22, SOFT, "start", w=600)
    b += hint("◄► escolher · PULAR confirmar · ESC voltar")
    n = notes("Tela de MAPAS — entra depois de MODOS → DERRUBA (A8)", [
        ("APROVADO", "Progresso para liberar mapas aparece aqui e nos resultados, nunca no HUD."),
        ("PROPOSTA", "Cartão do mapa mostra o grafo de cenas: descobertas ✓, não descobertas ?."),
        ("PROPOSTA", "Mapas bloqueados = cartão cinza + cadeado; o próximo é escolhido pelo jogador."),
        ("DECIDIR", "Pontos por mapa (exemplo: 6) e o que acontece se passar de 6."),
        ("FUTURO", "Hoje só existe o Canteiro: os 2 cartões bloqueados são de exemplo."),
        ("PROPOSTA", "Sem “Sorteio” no Derruba v2 (cada mapa é uma experiência própria)."),
    ])
    return page(b, n)


# ---------------------------------------------------------------- render
def render(boards):
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="etapa_c_")
    jobs = []
    for name, svg in boards:
        p = os.path.join(tmp, name + ".svg")
        open(p, "w").write(svg)
        jobs.append({"svg": p, "png": os.path.join(OUT, name + ".png"), "w": W, "h": H + NOTES_H, "scale": 1})
    jp = os.path.join(tmp, "jobs.json")
    json.dump(jobs, open(jp, "w"))
    subprocess.run(["node", os.path.join(ROOT, "tools/render_svg.js"), jp], check=True)
    for j in jobs:  # PNG opaco e menor
        Image.open(j["png"]).convert("RGB").save(j["png"], optimize=True)
    return [j["png"] for j in jobs]


if __name__ == "__main__":
    allb = {"c1_mapas": tela_mapas, "c2_spells": tela_spells, "c3_eventos": tela_eventos,
            "c4_manometro": tela_manometro, "c5_resultados": tela_resultados}
    want = sys.argv[1:] or list(allb)
    print("\n".join(render([(k, allb[k]()) for k in want])))
