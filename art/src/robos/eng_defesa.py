"""PRANCHA — classe nova DEFESA (2026-11-27, docs/revisoes/auditoria_engenhocas.md). Lote D1: D01 ÂNCORA DE CONTRAPESO e
D02 AIRBAG DE OBRA + identidade da classe (cor verde, placa em cúpula, ícone capacete de obra). Sem escudo na mão (S28).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/eng_defesa.py → art/out/robos_v2/eng_defesa_l1.png
"""
import math
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "efeitos"))
import eng_ataques as ea  # noqa: E402
from eng_ataques import laje, rival, marretao, painel, nota, poeira, linhas_vel, estrela, pedra, anel, TILE, EYE  # noqa: E402
from armaduras_conceito import R, E, P_, DARK, STEEL, STEEL_D, ab, label, INK, queue, render_all, shade  # noqa: E402
import spells as sp_art  # noqa: E402

VERDE_D = "#4fae5b"
PARADO = dict(hip=(0, -24), lean=4, head=2, feet=[(-9, 0), (9, 0)], tool=(9, -34, -150), bk=(-12, -24), face="foco")


# ---------------------------------------------------------------- arte
def contrapeso(x, y, s=1.0, afunda=0.0):
    """Contrapeso de guindaste: bloco de ferro com '1T', argola em cima; cravado no chão (afunda = quanto entrou)."""
    o = f'<g transform="translate({x},{y + 12 * afunda}) scale({s})">'
    o += R(-14, -26, 28, 26, 4, "#4a505c", k=0.5) + R(-14, -26, 28, 6, 3, "#6a7280", k=0.2)
    o += ab.cb.faixa(-14, -10, 28, 5, n=4)
    o += f'<text x="0" y="-13" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="9" fill="#e3e8ee">1T</text>'
    o += f'<circle cx="0" cy="-30" r="5" fill="none" stroke="{STEEL_D}" stroke-width="3"/>'
    return o + "</g>"


def corrente(a, b, tensa=True):
    n = max(3, int(math.dist(a, b) / 6))
    o = ""
    for i in range(n + 1):
        u = i / n
        x = a[0] + (b[0] - a[0]) * u
        y = a[1] + (b[1] - a[1]) * u + (0 if tensa else math.sin(u * math.pi) * 8)
        o += f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="3.2" ry="2.2" fill="none" stroke="{STEEL_D}" stroke-width="1.8" transform="rotate({(i % 2) * 90} {x:.1f} {y:.1f})"/>'
    return o


def airbag_mochila(x, y, s=1.6):
    """Airbag dobrado nas costas: pacote amarelo com faixa e válvula."""
    return (f'<g transform="translate({x},{y}) scale({s})">' + R(-9, -12, 14, 22, 4, "#f2c84b", k=0.4) + ab.cb.faixa(-9, 2, 14, 4, n=3)
            + E(-2, -13, 3, 2.5, STEEL_D, k=0.1) + "</g>")


def airbag_balao(cx, cy, r, murcho=0.0):
    """Balão do airbag em volta do robô: amarelo com gomos, faixa de perigo no meio e brilho."""
    rx, ry = r * (1 - 0.35 * murcho), r * (1 - 0.55 * murcho)
    o = f'<ellipse cx="{cx}" cy="{cy}" rx="{rx + 3}" ry="{ry + 3}" fill="#8a6a1a" opacity="0.5"/>'
    o += f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#f2c84b" opacity="0.88"/>'
    for k in (-0.5, 0.0, 0.5):
        o += f'<path d="M{cx + rx * k},{cy - ry * math.sqrt(1 - k * k)} Q{cx + rx * k * 1.3},{cy} {cx + rx * k},{cy + ry * math.sqrt(1 - k * k)}" stroke="#c99a2a" stroke-width="2" fill="none" opacity="0.7"/>'
    o += f'<path d="M{cx - rx * 0.55},{cy - ry * 0.55} Q{cx - rx * 0.2},{cy - ry * 0.85} {cx + rx * 0.15},{cy - ry * 0.75}" stroke="#ffffff" stroke-width="4" fill="none" opacity="0.7" stroke-linecap="round"/>'
    return o


def caixa_e_icone(x, y):
    """Identidade da classe: caixa (mesmo gerador das outras) + ícone + cabeçalho do card."""
    o = f'<g transform="translate({x},{y}) scale(1.4)">{sp_art.caixa_body("defesa")}</g>'
    o += f'<g transform="translate({x + 150},{y + 16}) scale(1.4)"><rect x="0" y="0" width="64" height="64" rx="10" fill="{VERDE_D}"/>{sp_art.icon("capacete", "#ffffff")}</g>'
    o += f'<rect x="{x + 270}" y="{y + 8}" width="150" height="110" rx="10" fill="#fff7ee" stroke="{INK}" stroke-width="3"/>'
    o += f'<rect x="{x + 270}" y="{y + 8}" width="150" height="24" rx="10" fill="{VERDE_D}"/><rect x="{x + 270}" y="{y + 22}" width="150" height="10" fill="{VERDE_D}"/>'
    o += f'<g transform="translate({x + 276},{y + 10}) scale(0.3)">{sp_art.icon("capacete", "#ffffff")}</g>'
    o += f'<text x="{x + 345}" y="{y + 108}" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="13" fill="{INK}">ÂNCORA</text>'
    o += contrapeso(x + 345, y + 84, 1.4)
    return o


# ---------------------------------------------------------------- quadros
def d01():
    ps = []
    crava = dict(PARADO, hip=(0, -18), lean=-10, head=6, feet=[(-14, 0), (10, 0)], face="raiva", sq=(1.05, 0.9))
    c = laje(-110, 260) + rival(150, 0) + marretao(crava)
    c += contrapeso(-34, 0, 1.0, 0.3) + corrente((-30, -26), (-6, -26)) + poeira(-34, 0, 6, 6, 26)
    c += anel(-34, 0, 30, 6, 3) + ea.barra_energia(0, -96, 1.0).replace("#9b6bff", VERDE_D)
    c += nota(-205, "crava o contrapeso atrás de si", "corrente presa na cintura · 4 s")
    ps.append(("1 · CRAVA — contrapeso no chão", c))
    c = laje(-110, 260) + contrapeso(-34, 0, 1.0, 0.3) + corrente((-30, -26), (-6, -26))
    c += marretao(dict(PARADO, face="raiva", lean=-4)) + rival(70, 0, flip=True)
    c += estrela(18, -40, 20) + linhas_vel(60, -60, 3, 30, 1, 0.5)
    c += f'<text x="0" y="-104" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="16" fill="{INK}">NEM SE MEXE</text>'
    c += nota(-205, "golpe, vento, ímã e onda NÃO empurram", "o dano % continua contando")
    ps.append(("2 · AGUENTA — ninguém te tira do lugar", c))
    anda = dict(PARADO, hip=(4, -22), lean=14, head=-4, feet=[(-12, 0), (16, 0)], face="raiva")
    c = laje(-110, 260) + contrapeso(-40, 0, 1.0, 0.1) + corrente((-36, -26), (6, -26), tensa=True) + marretao(anda, x=10)
    c += "".join(f'<path d="M{-70 - i * 18},{-2} l12,0" stroke="#8a7a5e" stroke-width="3"/>' for i in range(3))
    c += nota(-205, "dá para andar e bater, mas DEVAGAR", "arrasta o contrapeso (sulcos no chão)")
    ps.append(("3 · ANDA DEVAGAR — arrastando o peso", c))
    c = laje(-110, 260) + contrapeso(-34, 0, 1.0, 1.4) + poeira(-34, 0, 8, 7, 40, 0.6) + marretao(PARADO)
    c += corrente((-30, -10), (-6, -26), tensa=False)
    c += nota(-205, "fim dos 4 s: a corrente solta", "e o contrapeso afunda em poeira")
    ps.append(("4 · FIM — solta e afunda", c))
    return ps


def d02():
    ps = []
    c = laje(-110, 260) + rival(150, 0) + airbag_mochila(-14, -34) + marretao(PARADO)
    c += nota(-205, "fica DOBRADO nas costas (passivo)", "nada a apertar: dispara sozinho")
    ps.append(("1 · EQUIPADO — mochila amarela", c))
    voa = dict(PARADO, face="susto", feet=[(-14, -10), (-2, -18)], hip=(0, -28))
    c = laje(-110, 260) + marretao(voa, x=70, y=-90, rot=-60) + linhas_vel(40, -150, 4, 40, 1)
    c += rival(-60, 0) + estrela(-20, -40, 22)
    c += nota(-205, "levou um golpe forte e foi arremessado", "(voando rápido / caindo no vazio)")
    ps.append(("2 · ARREMESSADO — voo forte", c))
    c = laje(-110, 260) + airbag_balao(80, -120, 56) + marretao(dict(voa, face="susto"), x=80, y=-84, rot=-20)
    c += "".join(f'<path d="M{80 + math.cos(a) * 66:.0f},{-120 + math.sin(a) * 66:.0f} l{math.cos(a) * 12:.0f},{math.sin(a) * 12:.0f}" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/>' for a in [i * math.pi / 4 for i in range(8)])
    c += f'<text x="170" y="-150" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="18" fill="{INK}">FUMP!</text>'
    c += nota(-205, "infla na hora: CORTA O VOO (para no ar)", "1 vez · salva da queda pra fora")
    ps.append(("3 · INFLA — corta o voo", c))
    c = laje(-110, 260) + airbag_balao(80, -40, 40, murcho=0.6) + marretao(PARADO, x=80)
    c += "".join(f'<path d="M{110 + i * 10},{-60 - i * 6} q6,-4 10,0" stroke="#ffffff" stroke-width="2" fill="none" opacity="0.7"/>' for i in range(3))
    c += f'<text x="140" y="-80" font-family="Fredoka, Arial" font-weight="700" font-size="14" fill="{INK}">pffff</text>'
    c += nota(-205, "desce devagar até o chão mais perto", "pousa e o balão murcha (gasto)")
    ps.append(("4 · POUSA — murcha e acabou", c))
    return ps


def prancha():
    W, H = 1920, 1420
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "CLASSE NOVA · DEFESA — lote D1: ÂNCORA DE CONTRAPESO e AIRBAG DE OBRA (proposta)", 30)]
    b.append(f'<text x="40" y="104" font-family="Fredoka, Arial" font-weight="700" font-size="24" fill="{INK}">IDENTIDADE DA CLASSE</text>')
    b.append(f'<text x="40" y="132" font-family="Arial" font-size="16" fill="{INK}">verde · placa em CÚPULA · ícone CAPACETE DE OBRA (cor + forma + ícone, como as outras)</text>')
    b.append(caixa_e_icone(900, 70))
    pw, ph = 452, 470
    for r, (nome, sub, ps) in enumerate([
            ("D01 ÂNCORA DE CONTRAPESO", "aperta: crava o contrapeso · 4 s sem ser empurrado (golpe, vento, ímã, onda) · anda devagar · dano % conta", d01()),
            ("D02 AIRBAG DE OBRA", "passivo: dispara sozinho no 1º arremesso forte (ou caindo no vazio) · corta o voo · desce devagar · 1 uso", d02())]):
        y0 = 230 + r * (ph + 110)
        b.append(f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{nome}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        for j, (tit, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 80, pw, ph, tit, c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/eng_defesa_l1.png")
    queue(svg, os.path.join(HERE, "svg/eng_defesa_l1.svg"), out, W, H, 1)
    print(render_all(), out)


# ================================================================ LOTE D2: D03 PARA-CHOQUE DE MOLA · D04 REMENDO RÁPIDO
def molas_em_volta(cx, cy, k=1.0, comp=0.0, n=7):
    """D03: molas que brotam do corpo em leque com batente de borracha na ponta (k = quanto saíram; comp = comprimidas)."""
    o = ""
    for i in range(n):
        a = math.radians(-200 + i * (220 / (n - 1)))
        L = (18 + 34 * k) * (1 - 0.55 * comp)
        x0, y0 = cx + math.cos(a) * 18, cy + math.sin(a) * 22
        x1, y1 = cx + math.cos(a) * (18 + L), cy + math.sin(a) * (22 + L)
        voltas = 5
        pts = []
        for j in range(voltas * 2 + 1):
            u = j / (voltas * 2)
            px, py = x0 + (x1 - x0) * u, y0 + (y1 - y0) * u
            off = (3.2 if j % 2 else -3.2)
            pts.append(f"{px - math.sin(a) * off:.1f},{py + math.cos(a) * off:.1f}")
        o += f'<polyline points="{" ".join(pts)}" fill="none" stroke="{STEEL_D}" stroke-width="2.4"/>'
        o += f'<g transform="translate({x1:.1f},{y1:.1f}) rotate({math.degrees(a) + 90:.0f})">' + R(-7, -4, 14, 7, 3, "#2b2b33", k=0.2) + R(-7, -4, 14, 3, 2, "#f2c84b", k=0.1) + "</g>"
    return o


def macarico(x, y, ang=0.0, chama=True):
    """D04: maçarico de solda (cabo azul, bico de cobre) com chama azul-branca."""
    o = f'<g transform="translate({x},{y}) rotate({ang})">' + R(-4, -3, 14, 6, 2, "#3f6fb0", k=0.2) + R(10, -2, 8, 4, 1, "#c98a3a", k=0.1)
    if chama:
        o += f'<path d="M18,0 Q26,-5 32,0 Q26,5 18,0 Z" fill="#7fd7ff"/><path d="M18,0 Q23,-2 27,0 Q23,2 18,0 Z" fill="#ffffff"/>'
    return o + "</g>"


def chapa(x, y, s=1.0, rot=0, brilho=0.0):
    o = f'<g transform="translate({x},{y}) rotate({rot}) scale({s})">' + R(-9, -7, 18, 14, 2, "#9aa4ae", k=0.3) + R(-9, -7, 18, 4, 1.5, "#c9d1d8", k=0.1)
    o += "".join(f'<circle cx="{cx}" cy="{cy}" r="1.4" fill="#5d6672"/>' for cx, cy in ((-6, -4), (6, -4), (-6, 4), (6, 4)))
    if brilho:
        o += f'<rect x="-9" y="-7" width="18" height="14" rx="2" fill="#ffffff" opacity="{brilho}"/>'
    return o + "</g>"


def faiscas(x, y, n=8, r=14):
    return "".join(f'<path d="M{x},{y} l{math.cos(a) * r:.1f},{math.sin(a) * r:.1f}" stroke="#ffd27a" stroke-width="2" stroke-linecap="round"/>'
                   for a in [i * 2 * math.pi / n + 0.3 for i in range(n)])


def d03():
    ps = []
    c = laje(-110, 260) + rival(150, 0) + molas_em_volta(0, -40, 0.6) + marretao(PARADO)
    c += f'<circle cx="0" cy="-40" r="46" fill="#f2c84b" opacity="0.18"/>' + nota(-205, "aperta: molas com batente brotam do corpo", "1,5 s armado (pisca amarelo)")
    ps.append(("1 · ARMA — molas brotam", c))
    golpe = dict(hip=(3, -16), lean=30, head=-10, feet=[(-16, 0), (18, 0)], face="raiva")
    c = laje(-110, 260) + molas_em_volta(0, -40, 1.0, comp=0.7) + marretao(PARADO) + rival(46, 0, flip=True)
    c += estrela(22, -44, 18) + nota(-205, "o rival bate: as molas COMPRIMEM", "(o golpe não passa)")
    ps.append(("2 · GOLPEADO — comprime", c))
    c = laje(-110, 260) + molas_em_volta(0, -40, 1.2) + marretao(PARADO) + rival(160, -60, rot=50) + linhas_vel(120, -80, 4, 40, -1)
    c += f'<text x="70" y="-110" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="20" fill="{INK}">BOING!</text>'
    c += ea.rebite(90, -60, 180) + ea.rastro([(60, -60), (90, -60)]) + nota(-205, "REBATE: quem bateu voa de volta", "tiros (rebite, gelo, mola) voltam")
    ps.append(("3 · REBATE — BOING!", c))
    c = laje(-110, 260) + molas_em_volta(0, -40, 0.2) + marretao(PARADO) + nota(-205, "fim dos 1,5 s: as molas recolhem", "(1 uso)")
    ps.append(("4 · FIM — recolhe", c))
    return ps


def nuvem(cx, cy, r, op=0.85, n=11):
    """Nuvem de pó de cimento: bolhas cinza-claras com sombra embaixo (cor do concreto, não branca pura)."""
    o = ""
    for i in range(n):
        a = i * 2 * math.pi / n
        rr = r * (0.42 + 0.12 * ((i * 7) % 3))
        x, y = cx + math.cos(a) * r * 0.62, cy + math.sin(a) * r * 0.5
        o += f'<circle cx="{x:.1f}" cy="{y + 3:.1f}" r="{rr:.1f}" fill="#a8987a" opacity="{op * 0.5:.2f}"/>'
        o += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rr:.1f}" fill="#e3dccd" opacity="{op:.2f}"/>'
    o += f'<circle cx="{cx}" cy="{cy}" r="{r * 0.55:.1f}" fill="#efe9dc" opacity="{op:.2f}"/>'
    return o


def saco_cimento(x, y, rasgado=False):
    o = R(x - 10, y - 13, 20, 26, 4, "#d8cbb0", k=0.4) + R(x - 10, y - 4, 20, 6, 1, "#c0392b", k=0.1)
    o += f'<text x="{x}" y="{y + 1}" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="5" fill="#fff">CIMENTO</text>'
    if rasgado:
        o += f'<path d="M{x - 10},{y - 13} l5,-4 l4,4 l5,-5 l6,5" fill="none" stroke="#8a7a5e" stroke-width="2"/>'
    return o


def d04():
    ps = []
    joga = dict(PARADO, hip=(0, -20), lean=-8, head=6, feet=[(-12, 0), (10, 0)], bk=(-6, -60), fr=(8, -62), face="raiva")
    c = laje(-110, 260) + rival(150, 0) + marretao(joga) + saco_cimento(4, -92, True)
    c += "".join(f'<circle cx="{4 + math.cos(i) * 12:.0f}" cy="{-110 - i * 5}" r="{3 + i}" fill="#e3dccd"/>' for i in range(4))
    c += nota(-205, "aperta: rasga um saco de cimento", "por cima da cabeça")
    ps.append(("1 · RASGA O SACO", c))
    c = laje(-110, 260) + marretao(PARADO) + nuvem(0, -40, 70, 0.5) + rival(150, 0)
    c += f'<text x="0" y="-130" text-anchor="middle" font-family="Fredoka, Arial" font-weight="700" font-size="20" fill="{INK}">PUF!</text>'
    c += nota(-205, "nuvem de pó em volta (2 s)", "o robô fica meio sumido dentro")
    ps.append(("2 · PUF — nuvem de pó", c))
    c = laje(-110, 260) + marretao(PARADO) + nuvem(0, -40, 72, 0.45) + rival(60, 0, flip=True)
    c += ea.rebite(-40, -40, 180) + ea.rastro([(40, -40), (-40, -40)]) + estrela(26, -40, 10, "#ffffff")
    c += nota(-205, "golpe e tiro PASSAM DIRETO (sem dano)", "mas dentro dela você não ataca")
    ps.append(("3 · INTOCÁVEL — passa direto", c))
    c = laje(-110, 260) + marretao(PARADO) + nuvem(0, -30, 60, 0.25) + nuvem(-40, -10, 30, 0.2, 7) + nuvem(46, -14, 26, 0.2, 7)
    c += nota(-205, "a poeira assenta e se espalha", "(1 uso)")
    ps.append(("4 · ASSENTA — acabou", c))
    return ps


def prancha2():
    W, H = 1920, 1260
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', label(W / 2, 50, "DEFESA · lote D2 — D03 PARA-CHOQUE DE MOLA (aprovado) e D04 CORTINA DE POEIRA (proposta)", 30)]
    pw, ph = 452, 470
    for r, (nome, sub, ps) in enumerate([
            ("D03 PARA-CHOQUE DE MOLA", "aperta: 1,5 s de molas em volta · quem bate (golpe ou tiro) é REBATIDO de volta · sem escudo na mão", d03()),
            ("D04 CORTINA DE POEIRA", "aperta: nuvem de pó de cimento por 2 s · golpe e tiro passam direto (sem dano) · dentro dela não ataca", d04())]):
        y0 = 80 + r * (ph + 110)
        b.append(f'<text x="40" y="{y0 + 30}" font-family="Fredoka, Arial" font-weight="700" font-size="26" fill="{INK}">{nome}</text>')
        b.append(f'<text x="40" y="{y0 + 58}" font-family="Arial" font-size="17" fill="{INK}">{sub}</text>')
        for j, (tit, c) in enumerate(ps):
            b.append(painel(20 + j * (pw + 14), y0 + 80, pw, ph, tit, c))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'
    out = os.path.join(ab.ROOT, "art/out/robos_v2/eng_defesa_l2.png")
    queue(svg, os.path.join(HERE, "svg/eng_defesa_l2.svg"), out, W, H, 1)
    print(render_all(), out)


def exportar_jogo():
    """Texturas do jogo: spells/d01_contrapeso (64x80, base em 32,72) e spells/d02_airbag (48x64, centro 24,32)."""
    out = os.path.join(ab.ROOT, "art/out/game/spells")
    os.makedirs(out, exist_ok=True)
    itens = [("d01_contrapeso", contrapeso(16, 37, 0.9), 32, 40, 4),
             ("d02_airbag", f'<g transform="translate(12,16) scale(1.0)">' + R(-9, -12, 18, 26, 5, "#f2c84b", k=0.4) + ab.cb.faixa(-9, 3, 18, 5, n=3)
              + E(-1, -13, 3.5, 3, STEEL_D, k=0.1) + R(-9, -12, 18, 5, 3, "#ffe27a", k=0.1) + "</g>", 24, 32, 4)]
    mola = "".join(f'<polyline points="{" ".join(f"{6 + j * 2.2:.1f},{(4 if j % 2 else -4) + 8 + k * 9}" for j in range(9))}" fill="none" stroke="{STEEL_D}" stroke-width="2"/>' for k in range(3))
    mola += "".join(R(24, 3 + k * 9, 6, 10, 2, "#2b2b33", k=0.1) + R(24, 3 + k * 9, 6, 4, 1, "#f2c84b", k=0.1) for k in range(3))
    itens.append(("d03_molas", R(2, 1, 6, 28, 2, "#4a505c", k=0.2) + mola, 32, 32, 4))
    itens.append(("d04_saco", saco_cimento(13, 17), 26, 32, 4))
    for nome, g, w, h, sc in itens:
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{g}</svg>'
        queue(svg, os.path.join(HERE, f"svg/eng_{nome}.svg"), os.path.join(out, f"{nome}.png"), w, h, sc)
    print("defesa:", render_all())


if __name__ == "__main__":
    if "--jogo" in sys.argv:
        exportar_jogo()
    elif "--l2" in sys.argv:
        prancha2()
    else:
        prancha()
