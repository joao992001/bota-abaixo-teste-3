"""STORYBOARD DAS 2 TRANSIÇÕES — FASE 2 (Cargueiro Perdido), exigido pelo método (docs/manuais/derruba/mapa.md §0/§2):
a cena 1 é intermediária e tem DUAS saídas, cada uma com cinematografia própria.
  Moderada (≥ 40% na verificação por tempo) → 2a Destroços: o navio é arrastado e ENCALHA; todos deslizam para a direita.
  Total (65% a qualquer momento) → 2b Atlântida: o navio PARTE AO MEIO e AFUNDA; queda lenta pelo porão até a cidade.
Usa as fotografias aprovadas/propostas (art/out/fase2/cena*.png) como base de cada quadro + sobreposições.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_transicoes.py → art/out/fase2/transicoes.png
"""
import base64
import json
import math
import os
import random
import subprocess
import sys
import tempfile

HERE = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../robos"))
sys.path.insert(0, os.path.join(HERE, "../ui"))
import elenco as el  # noqa: E402
import etapa_c as ec  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
INK = "#2a1a2e"
YEL = "#f2c84b"
PW, PH = 440, 248          # quadro 16:9
X0, GAP = 34, 26


def img64(nome):
    return "data:image/png;base64," + base64.b64encode(open(os.path.join(OUT, nome), "rb").read()).decode()


def foto(nome, x=0, y=0, s=1.0, rot=0.0, extra=""):
    """A fotografia 1920×1080 dentro de um quadro de PW×PH (escala base), deslocada/girada em volta do centro."""
    k = PW / 1920.0 * s
    return (f'<g transform="translate({PW / 2 + x},{PH / 2 + y}) rotate({rot}) scale({k}) translate(-960,-540)" {extra}>'
            f'<image href="{IMG[nome]}" width="1920" height="1080"/></g>')


def robo(cid, pose, col, x, y, s=0.42, rot=0, flip=False):
    sx = -s if flip else s
    return f'<g transform="translate({x},{y}) rotate({rot}) scale({sx},{s})">{el.draw(cid, el.POSES[cid][pose], col)}</g>'


def faixa(txt, y=26, cor="#d42035"):
    w = len(txt) * 11 + 40
    return (f'<rect x="{PW / 2 - w / 2}" y="{y - 20}" width="{w}" height="30" rx="8" fill="{cor}" stroke="{INK}" stroke-width="3"/>'
            f'<text x="{PW / 2}" y="{y + 2}" font-family="Fredoka" font-weight="700" font-size="17" fill="#ffffff" text-anchor="middle">{txt}</text>')


def arco(x0, y0, x1, y1, alto, cor="#ffffff"):
    mx, my = (x0 + x1) / 2, min(y0, y1) - alto
    return f'<path d="M{x0},{y0} Q{mx},{my} {x1},{y1}" stroke="{cor}" stroke-width="3.2" fill="none" stroke-dasharray="9 7" stroke-linecap="round"/>'


def seta(x0, y0, x1, y1, cor="#ffffff", w=6):
    a = math.atan2(y1 - y0, x1 - x0)
    p1 = (x1 - math.cos(a - 0.5) * 16, y1 - math.sin(a - 0.5) * 16)
    p2 = (x1 - math.cos(a + 0.5) * 16, y1 - math.sin(a + 0.5) * 16)
    return (f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{INK}" stroke-width="{w + 4}" stroke-linecap="round"/>'
            f'<path d="M{x0},{y0} L{x1},{y1}" stroke="{cor}" stroke-width="{w}" stroke-linecap="round"/>'
            f'<path d="M{x1},{y1} L{p1[0]:.1f},{p1[1]:.1f} L{p2[0]:.1f},{p2[1]:.1f} Z" fill="{cor}" stroke="{INK}" stroke-width="2.5"/>')


def bolhas(n, seed, x0=0, x1=PW, y0=0, y1=PH):
    rnd = random.Random(seed)
    return "".join(f'<circle cx="{rnd.uniform(x0, x1):.0f}" cy="{rnd.uniform(y0, y1):.0f}" r="{rnd.uniform(2, 6):.1f}" fill="none" stroke="#dff6ff" stroke-width="1.6" opacity="0.8"/>' for _ in range(n))


def sirene(x, y):
    return (f'<rect x="{x - 10}" y="{y}" width="20" height="8" fill="#3a3f4a"/><path d="M{x - 9},{y} a9,9 0 0 1 18,0 Z" fill="#ff5a3c" stroke="{INK}" stroke-width="2"/>'
            f'<path d="M{x - 16},{y - 6} l-8,-6 M{x + 16},{y - 6} l8,-6 M{x},{y - 14} v-9" stroke="#ff5a3c" stroke-width="3" stroke-linecap="round"/>')


# ---------------------------------------------------------------- quadros
def m1():   # aviso
    return (foto("cena1_conves.png") + f'<rect width="{PW}" height="{PH}" fill="#2a1a2e" opacity="0.12"/>'
            + faixa("O NAVIO VAI ENCALHAR!") + sirene(60, 60) + sirene(PW - 60, 60)
            + seta(70, 200, 190, 200, "#bfe7ff") + seta(250, 212, 370, 212, "#bfe7ff")
            + f'<text x="{PW / 2}" y="{PH - 12}" font-family="Fredoka" font-weight="700" font-size="14" fill="#ffffff" text-anchor="middle" stroke="{INK}" stroke-width="3" paint-order="stroke">a corrente puxa o navio</text>')


def m2():   # arrastado: rochas surgem
    rocha = (f'<path d="M{PW - 70},{PH} L{PW - 60},{PH - 70} L{PW - 30},{PH - 96} L{PW + 10},{PH - 80} L{PW + 10},{PH} Z" fill="#8f98a4" stroke="{INK}" stroke-width="3"/>'
             f'<path d="M{PW - 40},{PH - 60} l14,10" stroke="#6b7480" stroke-width="3"/>')
    linhas = "".join(f'<path d="M{20 + i * 70},{60 + (i % 3) * 50} h-46" stroke="#ffffff" stroke-width="3" stroke-linecap="round" opacity="0.8"/>' for i in range(6))
    return foto("cena1_conves.png", x=-40, rot=-2) + linhas + rocha + faixa("ARRASTADO PARA AS ROCHAS", cor="#c96a1f")


def m3():   # tranco: todos voam para a direita
    estrela = (f'<path d="M{PW - 70},{PH - 80} l10,-26 l8,24 l26,-6 l-18,18 l18,18 l-26,-4 l-8,24 l-10,-26 l-24,6 Z" fill="{YEL}" stroke="{INK}" stroke-width="3"/>')
    voos = (arco(120, 170, 380, 150, 90) + arco(170, 150, 400, 120, 110) + arco(240, 160, 420, 170, 80)
            + robo("marretao", "esquiva", "#4f86d9", 270, 95, rot=20) + robo("picareta", "esquiva", "#5cc45c", 330, 70, rot=35)
            + robo("chave", "esquiva", "#f06aa8", 360, 120, rot=15))
    return foto("cena1_conves.png", x=-90, rot=4) + estrela + voos + faixa("TRANCO! TODOS DESLIZAM →", cor="#c96a1f")


def m4():   # chegada nos destroços
    pouso = (arco(-30, 60, 140, 175, 40) + arco(-30, 40, 220, 120, 60)
             + robo("marretao", "parado", "#4f86d9", 140, 182) + robo("picareta", "parado", "#5cc45c", 222, 128))
    return foto("cena2a_destrocos.png") + pouso + faixa("DESTROÇOS DO CARGUEIRO!", cor="#3f9e55")


def t1():   # aviso: racha o casco
    racha = (f'<path d="M218,90 l-8,22 l12,10 l-10,24 l14,14 l-8,26 l10,18 l-6,30" stroke="{INK}" stroke-width="5" fill="none"/>'
             f'<path d="M218,90 l-8,22 l12,10 l-10,24 l14,14 l-8,26 l10,18 l-6,30" stroke="#ffd36b" stroke-width="2" fill="none"/>')
    return foto("cena1_conves.png") + racha + faixa("O NAVIO VAI AFUNDAR!") + sirene(60, 60) + sirene(PW - 60, 60)


def t2():   # parte ao meio, água sobe, caem pelo porão
    esq = f'<clipPath id="ce"><rect x="0" y="0" width="{PW / 2}" height="{PH}"/></clipPath><g clip-path="url(#ce)">{foto("cena1_conves.png", x=-14, y=20, rot=-9)}</g>'
    dir_ = f'<clipPath id="cd"><rect x="{PW / 2}" y="0" width="{PW / 2}" height="{PH}"/></clipPath><g clip-path="url(#cd)">{foto("cena1_conves.png", x=14, y=24, rot=9)}</g>'
    vao = f'<path d="M{PW / 2 - 14},0 L{PW / 2 + 14},0 L{PW / 2 + 30},{PH} L{PW / 2 - 30},{PH} Z" fill="#0f3550"/>'
    agua = f'<rect x="0" y="{PH - 70}" width="{PW}" height="70" fill="#1f6f9a" opacity="0.75"/><path d="M0,{PH - 70} q30,-10 60,0 t60,0 t60,0 t60,0 t60,0 t60,0 t60,0 t60,0" stroke="#bfe7ff" stroke-width="3" fill="none"/>'
    cai = (seta(PW / 2, 60, PW / 2, 190, "#ffffff") + robo("britadeira", "esquiva", "#f2c84b", PW / 2 - 40, 130, rot=-20)
           + robo("pa", "esquiva", "#4f86d9", PW / 2 + 44, 110, rot=25))
    return esq + dir_ + vao + agua + cai + faixa("PARTIU! CAI-SE PELO PORÃO")


def t3():   # descida pelo mar
    fundo = (f'<defs><linearGradient id="dg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2f8fb8"/><stop offset="1" stop-color="#0c2a40"/></linearGradient></defs>'
             f'<rect width="{PW}" height="{PH}" fill="url(#dg)"/>')
    raios = "".join(f'<path d="M{60 + i * 90},0 L{30 + i * 90},{PH} L{70 + i * 90},{PH} Z" fill="#bfe7ff" opacity="0.10"/>' for i in range(5))
    peixe = lambda x, y, s=1.0: (f'<g transform="translate({x},{y}) scale({s})"><ellipse cx="0" cy="0" rx="14" ry="7" fill="#f2a33a" stroke="{INK}" stroke-width="2"/>'  # noqa: E731
                                f'<path d="M12,0 l10,-7 v14 Z" fill="#f2a33a" stroke="{INK}" stroke-width="2"/><circle cx="-7" cy="-2" r="1.8" fill="{INK}"/></g>')
    cont = (f'<g transform="translate(330,150) rotate(18)"><rect x="-38" y="-16" width="76" height="32" fill="#3f7fd0" stroke="{INK}" stroke-width="3"/>'
            + "".join(f'<path d="M{-30 + i * 12},-16 v32" stroke="#2f5fa0" stroke-width="2"/>' for i in range(6)) + "</g>")
    robos = (robo("marretao", "esquiva", "#4f86d9", 150, 110, rot=-10) + robo("picareta", "esquiva", "#5cc45c", 230, 160, rot=15)
             + robo("chave", "esquiva", "#f06aa8", 110, 190, rot=-25))
    camera = (f'<rect x="{PW - 62}" y="40" width="40" height="28" rx="5" fill="#ffffff" stroke="{INK}" stroke-width="3"/>'
              f'<circle cx="{PW - 42}" cy="54" r="8" fill="#3a3f4a"/>' + seta(PW - 42, 78, PW - 42, 160, YEL, 5))
    return (fundo + raios + bolhas(40, 5) + peixe(60, 70) + peixe(380, 210, 0.8) + cont + robos + camera
            + faixa("QUEDA LENTA PELO MAR", cor="#1f6f9a")
            + f'<text x="{PW / 2}" y="{PH - 12}" font-family="Fredoka" font-weight="700" font-size="14" fill="#ffffff" text-anchor="middle">a câmera desce junto · ninguém é eliminado</text>')


def t4():   # chegada em Atlântida
    pouso = (seta(150, 0, 150, 70, "#ffffff", 4) + seta(290, 0, 290, 50, "#ffffff", 4)
             + robo("marretao", "parado", "#4f86d9", 210, 138) + robo("picareta", "parado", "#5cc45c", 300, 116)
             + f'<g transform="translate(120,150) rotate(-10)"><rect x="-26" y="-11" width="52" height="22" fill="#3f7fd0" stroke="{INK}" stroke-width="3"/></g>')
    return foto("cena2b_atlantida.png") + bolhas(14, 9) + pouso + faixa("ATLÂNTIDA!", cor="#3f9e55")


def quadro(x, y, corpo, n, titulo, sub):
    cid = f"q{x}_{y}"
    return (f'<g transform="translate({x},{y})"><clipPath id="{cid}"><rect width="{PW}" height="{PH}" rx="12"/></clipPath>'
            f'<g clip-path="url(#{cid})"><rect width="{PW}" height="{PH}" fill="#bfe9ef"/>{corpo}</g>'
            f'<rect width="{PW}" height="{PH}" rx="12" fill="none" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="0" cy="0" r="22" fill="{YEL}" stroke="{INK}" stroke-width="4"/>'
            f'<text x="0" y="8" font-family="Fredoka" font-weight="700" font-size="22" fill="{INK}" text-anchor="middle">{n}</text>'
            f'<text x="{PW / 2}" y="{PH + 34}" font-family="Fredoka" font-weight="700" font-size="22" fill="{INK}" text-anchor="middle">{titulo}</text>'
            f'<text x="{PW / 2}" y="{PH + 60}" font-family="Fredoka" font-weight="600" font-size="17" fill="#5a4a5e" text-anchor="middle">{sub}</text></g>')


def prancha():
    W, H = ec.W, ec.H
    b = [f'<rect width="{W}" height="{H}" fill="#f6eedb"/>']
    b.append(ec.chunk(460, 16, 1000, 84, YEL, 16, 6, 8) + ec.T(960, 74, "CARGUEIRO PERDIDO · AS 2 TRANSIÇÕES DA CENA 1", 40))
    linhas = [("ROTA MODERADA · ≥ 40% NA VERIFICAÇÃO POR TEMPO → 2a DESTROÇOS", "#c96a1f", [
        (m1(), "AVISO", "sirene + faixa; a corrente puxa"), (m2(), "ARRASTADO", "o navio anda; as rochas aparecem"),
        (m3(), "TRANCO", "bate nas rochas: todos voam →"), (m4(), "CHEGADA", "pousam nos destroços (sem dano)")]),
        ("ROTA TOTAL · 65% A QUALQUER MOMENTO → 2b ATLÂNTIDA", "#1f6f9a", [
        (t1(), "AVISO", "o casco racha; sirene + faixa"), (t2(), "PARTE AO MEIO", "a água entra; cai-se pelo porão"),
        (t3(), "DESCIDA", "queda lenta pelo mar, câmera junto"), (t4(), "CHEGADA", "pousam no templo; contêineres viram peças")])]
    y = 128
    for titulo, cor, qs in linhas:
        b.append(f'<rect x="{X0}" y="{y}" width="{W - 2 * X0}" height="40" rx="10" fill="{cor}" stroke="{INK}" stroke-width="4"/>'
                 + ec.T(960, y + 29, titulo, 23, "#ffffff"))
        for i, (corpo, tt, sub) in enumerate(qs):
            x = X0 + 6 + i * (PW + GAP + 4)
            b.append(quadro(x, y + 66, corpo, i + 1, tt, sub))
            if i < 3:
                b.append(seta(x + PW + 4, y + 66 + PH / 2, x + PW + GAP + 2, y + 66 + PH / 2, YEL, 5))
        y += 66 + PH + 96
    n = ec.notes("Transições da cena 1 (o motor já existe: deslize da Fachada e queda da Fundação)", [
        ("PROPOSTA", "Moderada: encalha → todos deslizam para a direita (igual à Fachada)."),
        ("PROPOSTA", "Total: parte e afunda → queda lenta pelo mar (igual à Fundação)."),
        ("APROVADO", "Gatilhos: 40% no tempo → Destroços · 65% → Atlântida."),
        ("DECIDIR", "Aprovar as duas cinematografias (ou pedir ajuste por quadro: M1–M4, T1–T4)."),
    ])
    return ec.page(f'<g>{"".join(b)}</g>', n)


IMG = {}


def main():
    for nome in ("cena1_conves.png", "cena2a_destrocos.png", "cena2b_atlantida.png"):
        IMG[nome] = img64(nome)
    tmp = tempfile.mkdtemp(prefix="f2_trans_")
    p = os.path.join(tmp, "transicoes.svg")
    open(p, "w").write(prancha())
    png = os.path.join(OUT, "transicoes.png")
    jp = os.path.join(tmp, "jobs.json")
    json.dump([{"svg": p, "png": png, "w": ec.W, "h": ec.H + ec.NOTES_H, "scale": 1}], open(jp, "w"))
    subprocess.run(["node", os.path.join(ROOT, "tools/render_svg.js"), jp], check=True)
    print(png)


if __name__ == "__main__":
    main()
