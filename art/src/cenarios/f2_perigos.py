"""PRANCHA — PERIGOS E MECANISMOS do Cargueiro Perdido (biblioteca docs/fases/derruba/f2_cargueiro/perigos_mecanismos.md).
Cada perigo em 3 quadros (AVISO → AÇÃO → RESULTADO) + ficha (aviso, efeito, dano, marretada, frequência).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_perigos.py → art/out/fase2/perigos.png
"""
import base64
import math
import os
import random
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import f2_prancha as fp  # noqa: E402
from f2_prancha import R, E, PL, S, conteiner, tabua, zebra, robot, gancho, CONT, YEL, INK  # noqa: E402
import elenco as el  # noqa: E402
from papel import rough  # noqa: E402
from svg import doc, queue, render_all, shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/fase2")
FW, FH = 176, 120          # um quadro
VERM = "#d42035"
SOFT = "#6b5a70"
CREAM = "#fff6e4"


def Tt(x, y, s, size=16, col=INK, anchor="start", w=700):
    return f'<text x="{x}" y="{y}" font-family="Fredoka" font-weight="{w}" font-size="{size}" fill="{col}" text-anchor="{anchor}">{s}</text>'


def bot(x, y, cid="marretao", pose="parado", cor=0, s=0.36, rot=0, flip=False):
    return robot(cid, pose, el.COLORS[cor], x, y, s=s, flip=flip, rot=rot)


def alvo(x0, x1, y):
    """Sombra de aviso no chão: faixa vermelha tracejada + ! (onde vai cair)."""
    return (f'<rect x="{x0}" y="{y - 6}" width="{x1 - x0}" height="8" fill="{VERM}" opacity="0.85"/>'
            f'<path d="M{x0},{y - 2} H{x1}" stroke="#ffffff" stroke-width="3" stroke-dasharray="8 6"/>'
            f'<circle cx="{(x0 + x1) / 2}" cy="{y - 30}" r="12" fill="{VERM}"/>' + Tt((x0 + x1) / 2, y - 24, "!", 18, "#ffffff", "middle"))


def mar(y, cor="#2f6f9f"):
    return f'<rect x="0" y="{y}" width="{FW}" height="{FH - y}" fill="{cor}"/><path d="M0,{y} q11,-5 22,0 t22,0 t22,0 t22,0 t22,0 t22,0 t22,0 t22,0" stroke="#bfe6f4" stroke-width="2" fill="none"/>'


def quadro(x, y, corpo, rot, fundo):
    return (f'<g transform="translate({x},{y})"><clipPath id="q{x}_{y}"><rect width="{FW}" height="{FH}" rx="8"/></clipPath>'
            f'<g clip-path="url(#q{x}_{y})"><rect width="{FW}" height="{FH}" fill="{fundo}"/>{corpo}</g>'
            f'<rect width="{FW}" height="{FH}" rx="8" fill="none" stroke="{INK}" stroke-width="3"/></g>'
            + Tt(x + FW / 2, y + FH + 18, rot, 13, SOFT, "middle"))


# ---------------------------------------------------------------- CENA 1
def p_conteiner(k):
    o = R(0, 0, FW, 52, "#a5523d", 0, 1.0) + R(0, 50, FW, 4, "#7a7f8a", 0, 0.6)   # costado do navio ao fundo
    o += mar(100) + R(20, 86, 140, 14, "#4a5468", 2, 0.8)
    if k == 0:
        o += f'<g transform="rotate(-8 100 36)">' + conteiner(70, 14, 70, 26, CONT[1]) + "</g>"
        o += f'<path d="M70,12 l-8,-8 M140,12 l8,-8" stroke="{VERM}" stroke-width="3"/>' + alvo(64, 146, 86) + bot(40, 86)
        o += Tt(150, 30, "!", 22, VERM, "middle")
    elif k == 1:
        o += conteiner(70, 46, 70, 26, CONT[1]) + f'<path d="M80,30 v12 M100,26 v14 M120,30 v12" stroke="#ffffff" stroke-width="3"/>' + bot(30, 86, pose="esquiva", flip=True)
    else:
        o += conteiner(66, 60, 74, 26, CONT[1], 1) + f'<path d="M66,86 l-8,6 M140,86 l8,6" stroke="{INK}" stroke-width="3"/>' + bot(30, 86, rot=-30)
        o += Tt(100, 52, "+1 PLATAFORMA", 12, INK, "middle")
    return o


def p_gancho(k):
    o = mar(104) + R(0, 4, FW, 8, "#e0a83a", 0, 0.8) + R(10, 80, 60, 12, "#c98a4b", 2, 0.6) + R(110, 80, 60, 12, "#c98a4b", 2, 0.6)
    ang = [0, -26, 26][k]
    o += f'<g transform="rotate({ang} 88 12)"><path d="M88,12 V50" stroke="{INK}" stroke-width="3"/>' + conteiner(60, 54, 56, 20, CONT[4]) + "</g>"
    if k == 0:
        o += f'<path d="M50,30 q38,-20 76,0" stroke="{VERM}" stroke-width="3" fill="none" stroke-dasharray="6 5"/>' + Tt(88, 26, "range!", 12, VERM, "middle") + bot(140, 80)
    elif k == 1:
        o += bot(140, 80, pose="pesado_prep") + f'<path d="M34,60 q-14,0 -20,10" stroke="#ffffff" stroke-width="3" fill="none"/>'
    else:
        o += bot(160, 60, rot=40) + f'<path d="M128,60 l14,-8 M130,70 l16,0" stroke="{INK}" stroke-width="3"/>'
    return o


def p_onda(k):
    o = mar(96) + R(20, 84, 120, 14, "#4a5468", 2, 0.8) + zebra(20, 80, 120, 4)
    if k == 0:
        o += S("M176,96 q-30,-30 -50,-10 q20,0 26,14 Z", "#d6eef8", (120, 60, 176, 100), k=1.0) + Tt(140, 54, "a água incha", 11, VERM, "middle") + bot(70, 80)
    elif k == 1:
        o += S("M176,96 C150,20 90,30 70,80 C100,50 140,60 176,80 Z", "#d6eef8", (60, 20, 176, 100), k=1.0) + bot(60, 80, pose="esquiva", rot=-15)
    else:
        o += bot(20, 80, rot=-20) + f'<path d="M60,70 h-30 M60,78 h-24" stroke="#ffffff" stroke-width="3"/>' + Tt(90, 40, "empurra + molhado", 11, INK, "middle")
        o += f'<circle cx="80" cy="84" r="5" fill="#9fd0ec"/><circle cx="96" cy="86" r="4" fill="#9fd0ec"/>'
    return o


# ---------------------------------------------------------------- CENA 2a
def p_mare(k):
    nivel = [100, 84, 70][k]
    o = PL([(10, FH), (24, 70), (70, 66), (84, FH)], "#8a8f99", 1.0) + R(100, 92 - (100 - nivel), 60, 12, "#f08a3d", 2, 0.6)
    o += f'<path d="M0,70 H{FW}" stroke="#ffffff" stroke-width="2" stroke-dasharray="6 5"/>'
    o += f'<rect x="0" y="{nivel}" width="{FW}" height="{FH - nivel}" fill="#3fa7a0" opacity="0.8"/>'
    if k == 0:
        o += bot(46, 66) + Tt(130, 30, "maré subindo", 12, VERM, "middle") + f'<path d="M150,60 v-14 m-5,5 l5,-5 l5,5" stroke="{VERM}" stroke-width="3" fill="none"/>'
    elif k == 1:
        o += bot(46, 66) + bot(128, 92 - 16, cid="britadeira", cor=3)
    else:
        o += bot(46, 66, pose="esquiva") + bot(128, 78, cid="britadeira", cor=3, rot=-10) + Tt(110, 40, "alagado: lento", 12, INK, "middle")
    return o


def p_boia(k):
    o = mar(92, "#2f8f9a")
    ang = [0, 8, 32][k]
    o += f'<g transform="rotate({ang} 88 92)">' + conteiner(44, 68, 88, 26, CONT[6]) + "</g>"
    if k == 0:
        o += bot(70, 68) + Tt(88, 30, "1 robô: firme", 12, INK, "middle")
    elif k == 1:
        o += bot(60, 70) + bot(112, 74, cid="chave", cor=2) + Tt(88, 30, "range e afunda!", 12, VERM, "middle")
    else:
        o += bot(140, 50, cid="chave", cor=2, rot=40) + bot(36, 96, rot=-50) + f'<circle cx="60" cy="100" r="8" fill="none" stroke="#ffffff" stroke-width="2"/>'
    return o


def p_rede(k):
    o = mar(108, "#2f8f9a") + R(0, 4, FW, 8, "#e0a83a", 0, 0.8) + f'<path d="M88,12 V34" stroke="{INK}" stroke-width="3"/>' + gancho(88, 34)
    o += R(20, 100, 50, 10, "#6b6f7a", 2, 0.6)
    if k == 0:
        o += R(62, 50, 26, 22, "#c98a4b", 2, 0.6) + R(90, 50, 26, 22, "#c98a4b", 2, 0.6) + f'<path d="M58,46 Q88,96 120,46" stroke="#5a4a3a" stroke-width="3" fill="none"/>'
        o += bot(76, 50, pose="pesado_prep") + Tt(88, 96, "marretada!", 12, VERM, "middle")
    elif k == 1:
        o += f'<path d="M58,46 Q70,70 76,72 M120,46 Q106,70 100,72" stroke="#5a4a3a" stroke-width="3" fill="none"/>' + R(60, 76, 26, 22, "#c98a4b", 2, 0.6) + R(92, 82, 26, 22, "#c98a4b", 2, 0.6)
        o += bot(36, 100, cid="pa", cor=4)
    else:
        o += R(30, 80, 26, 22, "#c98a4b", 2, 0.6) + bot(16, 100, cid="pa", cor=4, rot=-30) + Tt(110, 70, "caixas caem", 12, INK, "middle")
    return o


# ---------------------------------------------------------------- CENA 2b
def p_alaga(k):
    nivel = [100, 80, 58][k]
    o = f'<path d="M-40,{FH} A140,130 0 0 1 216,{FH}" fill="none" stroke="#e8bc4a" stroke-width="4"/>'
    o += R(20, 70, 50, 12, "#f0e6d0", 2, 0.6) + R(110, 86, 50, 12, "#f0e6d0", 2, 0.6)
    o += f'<path d="M150,16 l-8,10 l6,6 l-8,10" stroke="#ffffff" stroke-width="3" fill="none"/>'
    o += f'<path d="M146,40 C140,60 150,80 144,{nivel}" stroke="#bff0fa" stroke-width="{6 + k * 5}" fill="none" opacity="0.8"/>'
    o += f'<rect x="90" y="{nivel}" width="{FW}" height="{FH}" fill="#3fc6dc" opacity="0.45"/>'
    if k == 0:
        o += bot(44, 70) + Tt(60, 30, "racha pinga", 12, VERM, "middle")
    elif k == 1:
        o += bot(44, 70, pose="pesado_golpe") + Tt(60, 30, "marretou o vidro", 11, VERM, "middle")
    else:
        o += bot(134, 70, cid="pa", cor=4, rot=-14) + Tt(60, 30, "a água sobe mais", 11, INK, "middle")
    return o


def p_lustre(k):
    o = f'<path d="M88,0 V30" stroke="#b58a2a" stroke-width="3" stroke-dasharray="6 4"/>' + R(20, 100, 136, 12, "#f0e6d0", 2, 0.6)
    y = [34, 34, 76][k]
    if k < 2:
        o += f'<path d="M88,30 L60,{y} M88,30 L116,{y}" stroke="#b58a2a" stroke-width="2"/>'
    o += R(54, y, 68, 8, "#e8bc4a", 2, 0.6) + f'<path d="M58,{y + 8} Q88,{y + 30} 118,{y + 8}" stroke="#e8bc4a" stroke-width="4" fill="none"/>'
    if k == 0:
        o += bot(130, 100, pose="pesado_prep", flip=True) + f'<path d="M108,20 l-14,8" stroke="{VERM}" stroke-width="3"/>' + Tt(40, 20, "na corrente", 11, VERM, "middle")
    elif k == 1:
        o += alvo(50, 126, 100) + bot(80, 100, cid="chave", cor=2)
    else:
        o += bot(60, 100, cid="chave", cor=2, rot=-60) + f'<path d="M50,100 l-10,-8 M130,100 l10,-8" stroke="{INK}" stroke-width="3"/>' + Tt(130, 60, "esmaga e racha", 11, INK, "middle")
    return o


def p_concha(k):
    o = R(10, 100, 156, 14, "#f0e6d0", 2, 0.6)
    aberta = k != 2
    o += E(88, 96, 34, 10, "#f2a7c3", 0.8)
    if aberta:
        o += f'<path d="M54,94 a34,28 0 0 1 68,-20" fill="#f7c6d8" stroke="#d1708f" stroke-width="3"/>' + E(88, 92, 7, 5, "#ffffff", 0.5)
    else:
        o += f'<path d="M54,96 a34,14 0 0 1 68,0" fill="#f7c6d8" stroke="#d1708f" stroke-width="3"/>'
    if k == 0:
        o += bot(88, 92) + Tt(88, 30, "pisou na concha", 12, INK, "middle")
    elif k == 1:
        o += bot(88, 40, pose="esquiva") + f'<path d="M88,86 v-30 m-6,6 l6,-6 l6,6" stroke="#ffffff" stroke-width="3" fill="none"/>' + Tt(140, 30, "lança alto", 12, INK, "middle")
    else:
        o += Tt(88, 40, "fecha 2 s", 12, VERM, "middle") + bot(150, 100, cid="pa", cor=4)
    return o


CENAS = [
    ("CENA 1 · CARGUEIRO NO ALTO-MAR", "#3a6f9a", [
        ("M1 · CONTÊINER DESPENCA DO NAVIO", p_conteiner, "#f7c8a0",
         ["AVISO: amarras estalam, o contêiner balança lá em cima e", "a SOMBRA VERMELHA marca onde vai cair (1,5 s)", "EFEITO: golpe forte em quem está embaixo + racha a plataforma",
          "DEPOIS: fica como plataforma nova (ou afunda se cair no mar)", "FREQUÊNCIA: a cada ~20 s, num lugar sorteado"]),
        ("M2 · GANCHO BALANÇA", p_gancho, "#f7c8a0",
         ["AVISO: a grua range e aparece o arco tracejado", "EFEITO: o contêiner varre o arco e empurra quem estiver nele",
          "MARRETADA no contêiner: ele balança para o outro lado", "FREQUÊNCIA: a cada ~12 s"]),
        ("M3 · ONDA ESTOURA NA BALSA", p_onda, "#f7c8a0",
         ["AVISO: a água incha na borda da balsa (1 s)", "EFEITO: empurra para dentro e deixa MOLHADO (lento) 2 s",
          "Só pega as plataformas baixas (balsas)", "FREQUÊNCIA: a cada ~15 s, alterna os lados"]),
    ]),
    ("CENA 2a · DESTROÇOS DO CARGUEIRO", "#2f8f8a", [
        ("M4 · MARÉ SOBE E DESCE", p_mare, "#cfeae6",
         ["AVISO: seta e som de maré; a água começa a subir", "EFEITO: até a linha da maré alta tudo fica ALAGADO (lento,", "pulo flutua); o que boia sobe junto",
          "Desce sozinha depois de ~8 s", "FREQUÊNCIA: a cada ~25 s"]),
        ("M5 · CONTÊINER BOIANDO VIRA", p_boia, "#cfeae6",
         ["AVISO: com 2+ robôs em cima ele RANGE e afunda um lado", "EFEITO: depois de 1 s vira e joga todo mundo na água",
          "Volta a boiar de pé em ~4 s", "Com 1 robô: firme (lugar seguro... por enquanto)"]),
        ("M6 · REDE DE CARGA RASGA", p_rede, "#cfeae6",
         ["AVISO: marretada pesada na rede faz ela rasgar (racha visível)", "EFEITO: as caixas caem em quem está embaixo",
          "A rede vira um saco vazio (não dá mais para pisar)", "Acionado SÓ pelos jogadores"]),
    ]),
    ("CENA 2b · ATLÂNTIDA", "#1f7f9a", [
        ("M7 · A RACHA DA CÚPULA ALAGA", p_alaga, "#bfe9f0",
         ["AVISO: a racha pinga e brilha; o jato engrossa", "EFEITO: o lado direito alaga (lento, pulo flutua, golpe longe)",
          "MARRETADA no vidro: a racha cresce e a água sobe mais", "O 'Bolhão de Ar' (evento) faz a água baixar"]),
        ("M8 · LUSTRE DESPENCA", p_lustre, "#bfe9f0",
         ["AVISO: marretada na corrente; ela estala e a SOMBRA", "VERMELHA aparece embaixo (1 s)", "EFEITO: esmaga quem estiver embaixo e racha a plataforma",
          "Some depois de cair (não volta na partida)"]),
        ("M9 · CONCHA-TRAMPOLIM", p_concha, "#bfe9f0",
         ["Pisou na concha aberta: LANÇA MUITO ALTO (atalho para cima)", "Depois de lançar ela FECHA por 2 s: quem estiver dentro",
          "fica preso (marretada abre)", "Mecanismo: ajuda a subir e prende quem abusa"]),
    ]),
]


def prancha():
    PW = 1920
    blocos = []
    y = 120
    b = [f'<rect width="{PW}" height="2000" fill="#2a1a2e"/>', fp.fonte().replace("<style>", "<style>"), rough(seed=41, scale=0.6, freq=0.05)]
    b.append(Tt(PW / 2, 70, "CARGUEIRO PERDIDO — PERIGOS E MECANISMOS (proposta)", 44, "#ffffff", "middle"))
    b.append(Tt(PW / 2, 104, "cada um: AVISO legível em 1 s → AÇÃO → RESULTADO · apoiado na arquitetura · protege nascimentos e rotas", 20, "#fff4c8", "middle"))
    for titulo, cor, perigos in CENAS:
        b.append(f'<rect x="30" y="{y}" width="{PW - 60}" height="56" rx="16" fill="{cor}" stroke="#ffffff" stroke-width="3"/>' + Tt(PW / 2, y + 38, titulo, 28, "#ffffff", "middle"))
        y += 72
        for k, (nome, fn, fundo, ficha) in enumerate(perigos):
            x = 30 + k * 630
            b.append(f'<rect x="{x}" y="{y}" width="610" height="380" rx="18" fill="{CREAM}" stroke="{INK}" stroke-width="5"/>')
            b.append(Tt(x + 305, y + 34, nome, 21, INK, "middle"))
            for q in range(3):
                b.append(quadro(x + 22 + q * 192, y + 52, fn(q), ["1 · AVISO", "2 · AÇÃO", "3 · RESULTADO"][q], fundo))
            for j, ln in enumerate(ficha):
                b.append(Tt(x + 24, y + 222 + j * 30, ln, 16, INK if j % 2 == 0 or ln.startswith(("EFEITO", "MARRETADA", "DEPOIS", "FREQ")) else SOFT, "start", 600))
        y += 400
    H = y + 20
    b[0] = f'<rect width="{PW}" height="{H}" fill="#2a1a2e"/>'
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{PW}" height="{H}" viewBox="0 0 {PW} {H}"><defs>{b[1]}{b[2]}</defs>{b[0]}<g filter="url(#rough)">{"".join(b[3:])}</g></svg>'
    os.makedirs(OUT, exist_ok=True)
    queue(svg, os.path.join(HERE, "svg/fase2/perigos.svg"), os.path.join(OUT, "perigos.png"), PW, H, 1)
    print(render_all(), os.path.join(OUT, "perigos.png"))


if __name__ == "__main__":
    prancha()
