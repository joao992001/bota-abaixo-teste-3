"""PRANCHAS para aprovar — fim de partida e pausa no estilo "Canteiro vivo" (avaliação do usuário de 2026-11-26, itens 5–7):
r1 Gangorra (tela própria), r1b storyboard da agulha, r2 Projetos de Demolição (tela própria), r3 Resultados com
estatísticas e cronômetro, r4 Pausa nova. Conceito para aprovar antes do código.
Rodar: python3 art/src/ui/recompensas.py → art/out/recompensas/*.png
"""
import math
import os
import sys

from PIL import Image, ImageEnhance

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import menus_v2 as mv  # noqa: E402
from menus_v2 import ec, fp, INK, YEL, CREAM, W, H, rough  # noqa: E402

OUT = os.path.join(ec.ROOT, "art/out/recompensas")
ZC = [z[2] for z in ec.ZONAS]   # 6 cores do manômetro (verde → vermelho)
PCOL = ec.PCOL
ROBOS = ["marretao", "picareta", "chave", "britadeira"]


def titulo(txt, w=760):
    return (f'<path d="M960,0 V40" stroke="#4a4f5c" stroke-width="5"/>' + mv.corrente(960 - w / 2 + 60, 30, 46)
            + mv.corrente(960 + w / 2 - 60, 30, 46) + mv.placa(960, 44, w, 96, txt, True))


def caixa_premio(cx, cy, cat, s=1.0, aberta=False):
    """Caixa de prêmio "?" com raios atrás e etiqueta da categoria."""
    b = []
    for k in range(12):
        a = k * math.pi / 6
        b.append(f'<path d="M{cx},{cy} L{cx + math.cos(a) * 150 * s:.0f},{cy + math.sin(a) * 150 * s:.0f} '
                 f'L{cx + math.cos(a + 0.22) * 150 * s:.0f},{cy + math.sin(a + 0.22) * 150 * s:.0f}Z" fill="#fff4c8" opacity="0.75"/>')
    w = 140 * s
    if aberta:
        b.append(f'<rect x="{cx - w / 2}" y="{cy - w / 2 + 20 * s}" width="{w}" height="{w - 20 * s}" rx="10" fill="#b57a3e" stroke="{INK}" stroke-width="6"/>')
        b.append(f'<rect x="{cx - w / 2 - 10}" y="{cy - w / 2 - 40 * s}" width="{w + 20}" height="{34 * s}" rx="8" fill="#c98c4a" stroke="{INK}" stroke-width="6" transform="rotate(-24 {cx - w / 2} {cy - w / 2})"/>')
        b.append(fp.robot("chave", "parado", "#f06aa8", cx, cy - 10 * s, 0.9 * s))
    else:
        b.append(f'<rect x="{cx - w / 2}" y="{cy - w / 2}" width="{w}" height="{w}" rx="12" fill="{YEL}" stroke="{INK}" stroke-width="7"/>')
        b.append(f'<path d="M{cx - w / 2},{cy - w / 2 + 30 * s} H{cx + w / 2} M{cx - w / 2},{cy + w / 2 - 30 * s} H{cx + w / 2}" stroke="{INK}" stroke-width="5"/>')
        b.append(ec.title(cx, cy + 34 * s, "?", int(96 * s), "#ffffff"))
    ty = cy - w / 2 - 70 * s   # etiqueta da categoria em cima da caixa
    b.append(ec.chunk(cx - 80 * s, ty, 160 * s, 46 * s, CREAM, 10, 4, 6) + ec.T(cx, ty + 33 * s, cat, int(26 * s)))
    return "".join(b)


def gangorra(val, ui=True, peso=None, premio=False, oscila=False):
    """Gangorra grande: tábua pintada nas 6 cores do manômetro sobre um cavalete de concreto; a agulha (mastro) sai do
    pivô e aponta numa régua em arco -100…+100. Prêmio em cada ponta; ponta que toca o chão = prêmio liberado."""
    b = [mv.fundo(0.18), mv.chao(880)]
    px, py = 960, 690
    ang = max(-15.7, min(15.7, val / 100 * 15.7))
    # régua em arco atrás (verde à esquerda, vermelho à direita)
    R1, R2 = 300, 360
    for i, col in enumerate(ZC):
        a0 = math.radians(180 + i * 30)
        a1 = math.radians(180 + (i + 1) * 30)
        p = [(px + math.cos(a0) * R2, py + math.sin(a0) * R2), (px + math.cos(a1) * R2, py + math.sin(a1) * R2),
             (px + math.cos(a1) * R1, py + math.sin(a1) * R1), (px + math.cos(a0) * R1, py + math.sin(a0) * R1)]
        b.append(f'<path d="M{p[0][0]:.0f},{p[0][1]:.0f} A{R2},{R2} 0 0 1 {p[1][0]:.0f},{p[1][1]:.0f} L{p[2][0]:.0f},{p[2][1]:.0f} '
                 f'A{R1},{R1} 0 0 0 {p[3][0]:.0f},{p[3][1]:.0f}Z" fill="{col}" stroke="{INK}" stroke-width="5"/>')
    for v, lab in ((-100, "-100"), (0, "0"), (100, "+100")):
        a = math.radians(270 + v * 0.8)
        b.append(ec.T(px + math.cos(a) * (R2 + 34), py + math.sin(a) * (R2 + 34) + 10, lab, 26, "#ffffff",
                      extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))
    # agulha = mastro preso no pivô (gira com a tábua)
    if oscila:
        for g in (-34, 22):   # rastros da agulha indo e voltando
            b.append(f'<g transform="rotate({g} {px} {py})" opacity="0.28"><path d="M{px - 10},{py} L{px},{py - 330} L{px + 10},{py}Z" fill="{INK}"/></g>')
    b.append(f'<g transform="rotate({ang * 5.7:.1f} {px} {py})"><path d="M{px - 14},{py} L{px},{py - 340} L{px + 14},{py}Z" fill="{INK}"/>'
             f'<path d="M{px - 7},{py - 10} L{px},{py - 320} L{px + 7},{py - 10}Z" fill="#d42035"/></g>')
    # cavalete de concreto
    b.append(fp.R(px - 120, 860, 240, 26, "#bdb3a0", 4, 1.6))
    b.append(f'<path d="M{px - 110},{868} L{px},{py + 10} L{px + 110},{868}Z" fill="#cfc6b4" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>')
    # tábua (6 cores) e prêmios nas pontas
    L = 720
    t = [f'<g transform="rotate({ang:.2f} {px} {py})">']
    for i, col in enumerate(ZC):
        t.append(f'<rect x="{px - L + i * (2 * L / 6):.0f}" y="{py - 46}" width="{2 * L / 6:.0f}" height="40" fill="{col}"/>')
    t.append(f'<rect x="{px - L}" y="{py - 46}" width="{2 * L}" height="40" rx="8" fill="none" stroke="{INK}" stroke-width="7"/>')
    for k in range(1, 6):
        x = px - L + k * 2 * L / 6
        t.append(f'<line x1="{x:.0f}" y1="{py - 46}" x2="{x:.0f}" y2="{py - 6}" stroke="{INK}" stroke-width="3" opacity="0.5"/>')
    t.append(f'<circle cx="{px}" cy="{py - 26}" r="16" fill="#8d98a4" stroke="{INK}" stroke-width="5"/>')
    t.append(caixa_premio(px - L + 90, py - 130, "SKIN", 0.9))
    t.append(caixa_premio(px + L - 90, py - 130, "EVENTO", 0.9, aberta=premio))
    if peso is not None:   # o peso da cor final cai na ponta
        side = 1 if peso > 0 else -1
        zx = px + side * 380
        t.append(f'<rect x="{zx - 70}" y="{py - 150}" width="140" height="100" rx="10" fill="{ZC[4] if side > 0 else ZC[1]}" stroke="{INK}" stroke-width="7"/>'
                 + ec.title(zx, py - 82, f"{peso:+d}", 46))
        t.append(f'<path d="M{zx},{py - 270} V{py - 170}" stroke="{INK}" stroke-width="6" stroke-dasharray="14 10"/>'
                 f'<path d="M{zx - 18},{py - 186} L{zx},{py - 160} L{zx + 18},{py - 186}" stroke="{INK}" stroke-width="6" fill="none"/>')
    t.append('</g>')
    b.append("".join(t))
    # alvo no chão sob cada ponta (tocou = prêmio)
    for sx in (-1, 1):
        b.append(f'<ellipse cx="{px + sx * 690}" cy="886" rx="90" ry="16" fill="{YEL}" stroke="{INK}" stroke-width="5"/>')
    if premio:
        b.append(mv.pow_(px + L - 60, 800, 1.1))
    if ui:
        b.append(titulo("GANGORRA DE RECOMPENSAS", 820))
        b.append(ec.chunk(30, 170, 470, 200, CREAM, 18, 5, 8) + ec.gauge(130, 262, 76, 68, label=False)
                 + ec.lines(330, 240, "a luta terminou\nem 68%:\nLARANJA", 28))
        b.append(ec.chunk(1420, 170, 470, 200, CREAM, 18, 5, 8)
                 + ec.T(1655, 226, "VERDE puxa para a SKIN", 28, "#2e9e4f") + ec.T(1655, 280, "VERMELHO puxa para o EVENTO", 26, "#a8233a")
                 + ec.T(1655, 336, "ponta no chão = prêmio", 24, "#6b5a70"))
        b.append(ec.title(px, 990, f"{val:+d}", 60, YEL if val >= 0 else "#8fd46a"))
        b.append(mv.plaquinha_dica("PULAR  pula a animação  ·  segue para os Projetos"))
    return "".join(b)


def tela_gangorra():
    n = ec.notes("GANGORRA — tela própria depois da luta (proposta)", [
        ("PROPOSTA", "Gangorra GRANDE: tábua nas 6 cores do manômetro sobre cavalete de concreto."),
        ("PROPOSTA", "Prêmios nas pontas (caixa “?” com raios); a categoria aparece em cima."),
        ("PROPOSTA", "A cor em que a luta terminou vira PESO e cai na ponta do lado dela."),
        ("PROPOSTA", "Agulha presa no pivô aponta a régua −100…+100; puxa para lá e para cá e para."),
        ("PROPOSTA", "Ponta toca o alvo no chão (±100) = caixa abre com POW e mostra o prêmio."),
        ("DECIDIR", "Luta curta (não vale): pular as 2 telas (recomendo) ou mostrar “não contou”?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{gangorra(35, peso=35)}</g>', n, rough(seed=21, scale=0.6, freq=0.05))


def tela_gangorra_story():
    b = [f'<rect width="{W}" height="{H}" fill="#f4ecd8"/>']
    frames = [(0, dict(peso=None), "1  Mostrador: a luta terminou no LARANJA (68%)"),
              (0, dict(peso=35), "2  O peso +35 cai na ponta vermelha"),
              (55, dict(oscila=True), "3  A gangorra puxa para lá e para cá (agulha balança)"),
              (100, dict(premio=True), "4  Se a ponta toca o chão: a caixa abre — PRÊMIO!")]
    for i, (v, kw, cap) in enumerate(frames):
        x, y = 40 + (i % 2) * 940, 30 + (i // 2) * 520
        pw, ph = 900, 506
        b.append(f'<svg x="{x}" y="{y}" width="{pw}" height="{ph}" viewBox="0 0 {W} {H}">{gangorra(v, ui=(i == 0), **kw)}</svg>')
        b.append(f'<rect x="{x}" y="{y}" width="{pw}" height="{ph}" rx="8" fill="none" stroke="{INK}" stroke-width="5"/>')
        b.append(ec.chunk(x + 20, y + ph - 70, pw - 40, 52, CREAM, 10, 4, 0) + ec.T(x + pw / 2, y + ph - 34, cap, 24))
    n = ec.notes("GANGORRA — animação (≈ 4 s, qualquer botão pula)", [
        ("PROPOSTA", "Quadro 1: a tela abre com o mostrador da luta; a agulha dele para na cor final."),
        ("PROPOSTA", "Quadro 2: a cor vira um bloco com o número (+35) e cai na ponta do lado dela."),
        ("PROPOSTA", "Quadro 3: a tábua oscila 2–3 vezes (som de mola/rangido) e assenta no novo valor."),
        ("PROPOSTA", "Quadro 4 (só se chegar a ±100): a caixa abre, prêmio aparece; a gangorra volta ao 0."),
        ("PROPOSTA", "Valor acumula entre partidas (fica salvo no perfil), como hoje."),
        ("PROVISÓRIO", "Pesos por cor: −75 −35 −15 +15 +35 +75 (P3, calibrar no playtest)."),
    ])
    return ec.page("".join(b), n)


def tapume():
    b = [mv.fundo(), mv.chao(930)]
    for k in range(9):
        x = -40 + k * 230
        b.append(fp.R(x, 170, 236, 760, "#7fae86" if k % 2 == 0 else "#86b48c", 2, 2.4, dark="#5f8f68"))
        b.append(f'<rect x="{x}" y="170" width="236" height="760" fill="none" stroke="#4d7a56" stroke-width="3"/>')
    b.append(fp.cd.zebra(-20, 150, W + 40, 26))
    b.append(fp.cd.zebra(-20, 920, W + 40, 18))
    return "".join(b)


def tijolo(x, y, s=1.0, col="#d42035"):
    return f'<rect x="{x}" y="{y}" width="{34 * s}" height="{20 * s}" rx="3" fill="{col}" stroke="{INK}" stroke-width="3"/>'


def tela_projetos():
    b = [tapume(), titulo("PROJETOS DE DEMOLIÇÃO", 860)]
    # prancheta: o que esta partida rendeu, linha por linha
    b.append(mv.prancheta(70, 230, 760, 640, "NESTA PARTIDA", "#3f7fb5"))
    linhas = [("✔", "Partida válida", "1 min ou mais, com vencedor", 1, False),
              ("★", "Cena nova: TÉRREO", "1ª vez neste mapa", 2, False),
              ("★", "Cena nova: FACHADA", "1ª vez neste mapa", 2, True)]
    y = 380
    for ic, txt, sub, pts, acendendo in linhas:
        if acendendo:
            b.append(f'<rect x="100" y="{y - 46}" width="700" height="96" rx="10" fill="#fff0b8" stroke="{YEL}" stroke-width="5"/>')
        b.append(ec.T(130, y + 4, ic, 40, "#3f9e55" if ic == "✔" else "#e0a21e"))
        b.append(ec.T(170, y - 2, txt, 32, INK, "start") + ec.T(170, y + 30, sub, 20, "#6b5a70", "start", w=600))
        for k in range(pts):
            b.append(tijolo(610 + k * 42, y - 20))
        b.append(ec.T(780, y + 6, f"+{pts}", 38, INK, "end"))
        y += 110
    b.append(f'<line x1="110" y1="{y - 40}" x2="790" y2="{y - 40}" stroke="{INK}" stroke-width="4" stroke-dasharray="12 8"/>')
    b.append(ec.T(130, y + 14, "TOTAL", 36, INK, "start") + ec.title(770, y + 18, "+5", 52, YEL))
    b.append(ec.lines(450, y + 80, "cena nova só conta 1 vez por mapa · luta curta não conta", 20, "#6b5a70"))
    # planta azul do próximo mapa: um prédio de 6 andares; cada ponto derruba um andar
    bx, by, bw, bh = 900, 220, 940, 650
    b.append(f'<rect x="{bx + 8}" y="{by + 12}" width="{bw}" height="{bh}" rx="8" fill="{INK}" opacity="0.35"/>')
    b.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="8" fill="#2f6fb0" stroke="{INK}" stroke-width="6"/>')
    for gx in range(bx + 40, bx + bw, 40):
        b.append(f'<line x1="{gx}" y1="{by + 6}" x2="{gx}" y2="{by + bh - 6}" stroke="#ffffff" stroke-width="1" opacity="0.18"/>')
    for gy in range(by + 40, by + bh, 40):
        b.append(f'<line x1="{bx + 6}" y1="{gy}" x2="{bx + bw - 6}" y2="{gy}" stroke="#ffffff" stroke-width="1" opacity="0.18"/>')
    for tx, rot in ((bx - 20, -30), (bx + bw - 70, 30)):
        b.append(f'<rect x="{tx}" y="{by - 12}" width="90" height="30" fill="#e8d9a8" opacity="0.9" transform="rotate({rot} {tx + 45} {by + 3})"/>')
    b.append(ec.T(bx + 30, by + 58, "PROJETO Nº 1 · PRÓXIMO MAPA", 30, "#ffffff", "start"))
    # prédio: 6 andares (base em baixo). antes = 0; agora +5 (5 derrubados); falta 1
    fx, fw, fh, base = bx + 120, 400, 74, by + bh - 70
    for k in range(6):
        y0 = base - (k + 1) * fh
        if k < 1:   # andar que ainda está de pé (em cima): desenho branco
            pass
        b.append(f'<rect x="{fx}" y="{y0}" width="{fw}" height="{fh}" fill="none" stroke="#ffffff" stroke-width="4" '
                 f'{"stroke-dasharray=\"10 8\" opacity=\"0.55\"" if k < 5 else ""}/>')
        if k < 5:   # derrubado nesta partida: carimbo vermelho
            b.append(f'<g transform="rotate(-6 {fx + fw / 2} {y0 + fh / 2})"><rect x="{fx + 90}" y="{y0 + 14}" width="220" height="46" rx="6" fill="none" stroke="#ff5a5a" stroke-width="5"/>'
                     + ec.T(fx + 200, y0 + 48, "DEMOLIDO", 28, "#ff5a5a") + '</g>')
            b.append(ec.T(fx - 20, y0 + 48, f"{k + 1}", 30, "#ffffff", "end"))
        else:
            for wx in range(4):
                b.append(f'<rect x="{fx + 40 + wx * 90}" y="{y0 + 20}" width="44" height="34" fill="none" stroke="#ffffff" stroke-width="3"/>')
            b.append(ec.T(fx - 20, y0 + 48, "6", 30, YEL, "end"))
    b.append(f'<line x1="{fx - 40}" y1="{base}" x2="{fx + fw + 40}" y2="{base}" stroke="#ffffff" stroke-width="6"/>')
    # bola de demolição batendo no último andar
    gx = fx + fw + 170
    b.append(f'<path d="M{gx + 120},{by + 80} L{gx + 30},{base - 6 * fh + 10}" stroke="#ffffff" stroke-width="5"/>')
    b.append(f'<circle cx="{gx + 10}" cy="{base - 6 * fh + 50}" r="52" fill="#4a4f5c" stroke="{INK}" stroke-width="6"/>')
    b.append(mv.pow_(fx + fw + 30, base - 6 * fh + 30, 0.7))
    b.append(ec.chunk(gx - 130, base - 230, 330, 200, CREAM, 14, 5, 8) + ec.T(gx + 35, base - 180, "ANTES  0", 30)
             + ec.T(gx + 35, base - 135, "+5 AGORA", 30, "#d42035") + ec.title(gx + 35, base - 66, "5 / 6", 52, YEL))
    b.append(ec.chunk(bx + 40, by + bh + 20, bw - 80, 56, YEL, 12, 5, 6) + ec.T(bx + bw / 2, by + bh + 58, "falta 1 andar → MAPA NOVO (você escolhe qual)", 28))
    b.append(mv.plaquinha_dica("PULAR  pula a animação  ·  segue para os resultados"))
    n = ec.notes("PROJETOS DE DEMOLIÇÃO — tela própria (proposta; corrige o “+2” confuso)", [
        ("PROPOSTA", "Prancheta lista CADA ganho numa linha: partida +1, cada cena nova +2 (com nome)."),
        ("PROPOSTA", "Planta azul do próximo mapa = prédio de 6 andares; 1 ponto = 1 andar derrubado."),
        ("PROPOSTA", "Animação: a linha acende, os tijolos voam e a bola de demolição derruba o andar."),
        ("PROPOSTA", "Placar ANTES + AGORA = TOTAL deixa claro o acumulado entre partidas."),
        ("PROPOSTA", "Prédio todo no chão = MAPA NOVO liberado; pontos que sobram vão para o próximo projeto."),
        ("PROVISÓRIO", "6 pontos por mapa, +1 partida, +2 cena nova (P4/P6, calibrar no playtest)."),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=22, scale=0.6, freq=0.05))


def cronometro(cx, cy, r, seg, frac):
    """Relógio de obra: mostrador creme, fatia restante em amarelo, número grande."""
    a1 = -90 + 360 * frac
    x1, y1 = cx + math.cos(math.radians(a1)) * r * 0.82, cy + math.sin(math.radians(a1)) * r * 0.82
    big = 1 if frac > 0.5 else 0
    return (f'<circle cx="{cx}" cy="{cy + 8}" r="{r}" fill="{INK}"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff6e4" stroke="{INK}" stroke-width="7"/>'
            f'<path d="M{cx},{cy} L{cx},{cy - r * 0.82} A{r * 0.82},{r * 0.82} 0 {big} 1 {x1:.1f},{y1:.1f}Z" fill="{YEL}" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="{cx - 18}" y="{cy - r - 22}" width="36" height="20" rx="5" fill="#8d98a4" stroke="{INK}" stroke-width="4"/>'
            + ec.title(cx, cy + r * 0.24, f"{seg}", int(r * 0.7)))


def tela_resultados():
    b = [mv.fundo(0.1), mv.chao(880)]
    # confete
    for k in range(60):
        x, y = (k * 137) % W, (k * 71) % 860
        b.append(f'<rect x="{x}" y="{y}" width="16" height="22" fill="{PCOL[k % 4]}" stroke="{INK}" stroke-width="2" transform="rotate({k * 37} {x + 8} {y + 11})"/>')
    b.append(titulo("P1 VENCEU!", 640))
    # vencedor no palete de caixotes (sem o círculo com estrela)
    for k in range(3):
        b.append(fp.R(90 + k * 110, 790, 110, 90, "#c98c4a", 6, 1.8, dark="#9a6a35") + f'<rect x="{90 + k * 110}" y="790" width="110" height="90" fill="none" stroke="{INK}" stroke-width="5"/>')
    b.append(fp.robot("picareta", "pesado_golpe", PCOL[1], 255, 790, 2.4))
    b.append(ec.chunk(110, 210, 300, 70, CREAM, 14, 5, 6) + ec.T(260, 258, "★ ★ ☆  sessão", 32, "#e0a21e"))
    # quadro de estatísticas (compensado)
    qx, qy, qw, qh = 470, 190, 960, 680
    b.append(f'<rect x="{qx + 8}" y="{qy + 12}" width="{qw}" height="{qh}" rx="14" fill="{INK}" opacity="0.4"/>')
    b.append(fp.R(qx, qy, qw, qh, "#b57a3e", 14, 2.0, dark="#8a5a2b") + f'<rect x="{qx}" y="{qy}" width="{qw}" height="{qh}" rx="14" fill="none" stroke="{INK}" stroke-width="6"/>')
    b.append(fp.R(qx + 20, qy + 20, qw - 40, qh - 40, CREAM, 6, 1.4, dark="#e9dcc0"))
    cols = ["DERRUBOU", "CAIU SOZINHO", "CAIXOTES", "ENGENHOCAS", "GOLPES"]
    cx0 = qx + 330
    for j, c in enumerate(cols):
        b.append(ec.T(cx0 + j * 120, qy + 74, c, 17, "#6b5a70"))
    dados = [(1, 1, "P1", [5, 0, 12, 3, 41], "MARRETEIRO"), (2, 0, "P2", [3, 1, 20, 2, 33], "DEMOLIDOR"),
             (3, 2, "P3", [1, 3, 6, 5, 18], "INVENTOR"), (4, 3, "P4", [0, 2, 9, 1, 12], "")]
    best = [max(d[3][j] for d in dados) if j != 1 else min(d[3][j] for d in dados) for j in range(5)]
    for i, (pos, ci, nm, vals, tit) in enumerate(dados):
        y = qy + 110 + i * 136
        b.append(f'<rect x="{qx + 34}" y="{y}" width="{qw - 68}" height="120" rx="12" fill="{"#dff3d6" if pos == 1 else "#f6eedb"}" stroke="{INK}" stroke-width="4"/>')
        b.append(ec.T(qx + 80, y + 76, f"{pos}º", 40))
        b.append(f'<svg x="{qx + 112}" y="{y + 6}" width="110" height="110" viewBox="-60 -150 120 120">{fp.robot(ROBOS[ci], "parado", PCOL[ci], 0, -30, 0.95)}</svg>')
        b.append(ec.T(qx + 250, y + 58, nm, 34, PCOL[ci], extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))
        if tit:
            b.append(ec.T(qx + 250, y + 96, tit, 16, "#6b5a70"))
        for j, v in enumerate(vals):
            on = v == best[j]
            if on:
                b.append(f'<circle cx="{cx0 + j * 120}" cy="{y + 60}" r="34" fill="{YEL}" stroke="{INK}" stroke-width="4"/>')
            b.append(ec.T(cx0 + j * 120, y + 74, str(v), 38))
    # opções + cronômetro
    b.append(cronometro(1660, 300, 92, 9, 0.6))
    b.append(ec.T(1660, 428, "escolhe sozinho em 9 s", 22, "#ffffff", extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"'))
    for i, (t, sel) in enumerate([("JOGAR DE NOVO", True), ("CONFIGURAR MAPA", False), ("SELECIONAR MAPA", False), ("MENU PRINCIPAL", False)]):
        b.append(mv.placa(1660, 460 + i * 104, 400 if not sel else 430, 84, t, sel))
    b.append(mv.plaquinha_dica("▲▼ escolher  ·  PULAR confirmar  ·  quando o relógio zera, vale a opção marcada"))
    n = ec.notes("RESULTADOS — vencedor, estatísticas por jogador e cronômetro (proposta)", [
        ("PROPOSTA", "Sem o círculo com estrela: o vencedor comemora em cima de um palete de caixotes."),
        ("PROPOSTA", "Quadro de obra com 1 linha por jogador: derrubou, caiu sozinho, caixotes, engenhocas, golpes."),
        ("PROPOSTA", "Melhor de cada coluna ganha bolinha amarela; título do jogador embaixo do nome."),
        ("PROPOSTA", "Relógio de obra conta 15 s; ao zerar vale a opção marcada (padrão JOGAR DE NOVO)."),
        ("PROPOSTA", "Estrelas da sessão ao lado do vencedor (somam até o Menu principal)."),
        ("DECIDIR", "Tempo do relógio: 15 s (recomendo) ou 10 s? Mexer na seleção reinicia o relógio?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=23, scale=0.6, freq=0.05))


def tela_pausa():
    fundo = os.path.join(ec.ROOT, "art/out/recompensas/base_partida.png")
    im = Image.open(fundo).convert("RGB").resize((W, H))
    im = ImageEnhance.Brightness(im).enhance(0.45)
    b = [f'<image href="{ec.uri_img(im)}" x="0" y="0" width="{W}" height="{H}"/><rect width="{W}" height="{H}" fill="#1a3a44" opacity="0.5"/>']
    b.append(f'<path d="M700,0 V120" stroke="#4a4f5c" stroke-width="5"/>' + mv.viga(420, 980, 120))
    b.append(mv.corrente(520, 172, 200) + mv.corrente(880, 172, 200) + mv.placa(700, 196, 520, 110, "PAUSA", True))
    y = 340
    for i, (t, sel) in enumerate([("CONTINUAR", True), ("REINICIAR PARTIDA", False), ("CONFIGURAR MAPA", False), ("SELECIONAR MAPA", False), ("MENU PRINCIPAL", False)]):
        w = 500 if sel else 440
        h = 96 if sel else 80
        b.append(mv.corrente(700 - w / 2 + 40, y - 30, y) + mv.corrente(700 + w / 2 - 40, y - 30, y))
        b.append(mv.placa(700, y, w, h, t, sel, rot=(-2 if sel else 0)))
        y += h + 30
    # prancheta com a partida em andamento
    b.append(mv.prancheta(1120, 220, 640, 620, "PARTIDA", "#e0841e"))
    rows = [("Mapa", "Canteiro de Obras"), ("Cena", "Térreo"), ("Tempo de luta", "1:24"), ("Engenhocas", "8 ligadas"), ("Eventos", "11 · normal")]
    for i, (k, v) in enumerate(rows):
        yy = 370 + i * 62
        b.append(ec.T(1160, yy, k, 26, "#6b5a70", "start") + ec.T(1720, yy, v, 28, INK, "end"))
    for i in range(4):   # vidas de cada jogador
        x = 1170 + i * 145
        b.append(ec.chip_p(x, 690, i + 1))
        for k in range(4):
            on = k < [3, 2, 4, 1][i]
            b.append(f'<circle cx="{x + 10 + k * 26}" cy="{760}" r="10" fill="{"#e5484d" if on else "#d9d2c4"}" stroke="{INK}" stroke-width="3"/>')
    b.append(ec.chunk(1140, 870, 600, 70, "#fbe3dc", 12, 4, 6) + ec.lines(1440, 900, "Configurar / Selecionar / Menu: abandona a luta\n(sem gangorra e sem Projetos) — pede confirmação", 19, "#a01528"))
    b.append(mv.plaquinha_dica("▲▼ escolher  ·  PULAR confirmar  ·  START volta à luta"))
    n = ec.notes("PAUSA — visual novo e mais opções (A23)", [
        ("APROVADO", "Pausa ganha CONFIGURAR MAPA e SELECIONAR MAPA (A23, 2026-11-26)."),
        ("PROPOSTA", "Mesma linguagem do menu: placas penduradas na viga da grua, luta escurecida atrás."),
        ("PROPOSTA", "Prancheta com a partida: mapa, cena, tempo, engenhocas, eventos e vidas de cada um."),
        ("PROPOSTA", "Sair da luta (reiniciar, configurar, selecionar, menu) pede “tem certeza?”."),
        ("PROPOSTA", "Sair no meio não conta para gangorra nem Projetos."),
        ("DECIDIR", "Pedir confirmação ao sair: sim (recomendo) ou não?"),
    ])
    return ec.page(f'<g filter="url(#rough)">{"".join(b)}</g>', n, rough(seed=24, scale=0.6, freq=0.05))


def main():
    os.makedirs(OUT, exist_ok=True)
    boards = [("r1_gangorra", tela_gangorra()), ("r1b_gangorra_animacao", tela_gangorra_story()), ("r2_projetos", tela_projetos()),
              ("r3_resultados", tela_resultados()), ("r4_pausa", tela_pausa())]
    import json, subprocess, tempfile
    tmp = tempfile.mkdtemp(prefix="recompensas_")
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
