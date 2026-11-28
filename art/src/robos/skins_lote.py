"""SKINS v2 — LOTE COMPLETO (2026-11-27, depois da amostra K1 aprovada): 3 skins por robô (15), todas nascidas no mapa
Canteiro de Obras (profissões e máquinas de obra). Mesma regra da K1: fantasia completa (forma e material mudam), cor do
jogador no capacete/cabine grande e nos braços e pernas; mesma silhueta, hitbox e animações; zero efeito de jogo.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/skins_lote.py [--so=marretao,...] → art/out/skins_v2/lote_<robo>.png
"""
import json
import math
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../ui"))
import anim_blindado as ab  # noqa: E402
import conceito3_blindado as cb  # noqa: E402
import elenco_uch as eu  # noqa: E402
import robo_uch as ru  # noqa: E402
import skins_v2 as k1m  # noqa: E402
from elenco import COLORS  # noqa: E402
from svg import shade  # noqa: E402

R, E, S, P_ = cb.R, cb.E, cb.S, cb.P
ROOT = k1m.ROOT
OUT = k1m.OUT
INK = "#2a1a2e"
STEEL, STEEL_D, STEEL_L = cb.STEEL, cb.STEEL_D, cb.STEEL_L
YEL, YEL_D = "#f2c84b", "#c49a2a"
SCREEN = "#1f2a36"
GRAFITE = "#3f4552"
REFL, REFL_D = "#e9eef2", "#aab4bd"


def faixa_refl(x, y, w, h=3):
    return R(x, y, w, h, 1, REFL, k=0.25) + f'<path d="M{x + 1},{y + h / 2} h{w - 2}" stroke="{REFL_D}" stroke-width="0.6" stroke-dasharray="2 1.5"/>'


def bota(cor, sola, w=1.0, faixa=None):
    def f(en, back):
        bx, by = en[0], en[1] + 4
        o = S(f"M{bx - 6 * w},{by} C{bx - 7 * w},{by - 8} {bx + 4 * w},{by - 9} {bx + 9 * w},{by - 3} L{bx + 10 * w},{by} Z", shade(cor, -0.2 if back else 0),
              (bx - 9 * w, by - 10, bx + 11 * w, by + 1), k=0.4)
        if faixa:
            o += R(bx - 5 * w, by - 5, 12 * w, 2, 1, shade(faixa, -0.2 if back else 0), k=0.2)
        return o + R(bx - 7 * w, by - 1.5, 18 * w, 3, 1.5, shade(sola, -0.25 if back else 0), k=0.3)
    return f


def mao(cor, r=5.5):
    return lambda e, b: E(e[0], e[1], r, r, shade(cor, -0.25) if b else cor, k=0.3)


class Troca:
    """Troca atributos de módulos enquanto desenha (cabeça/tronco/arma/mãos/botas do robo_uch; tubo dos membros)."""
    def __init__(self, mod, **kv):
        self.mod, self.kv = mod, kv

    def __enter__(self):
        self.old = {k: getattr(self.mod, k) for k in self.kv}
        for k, v in self.kv.items():
            setattr(self.mod, k, v)

    def __exit__(self, *a):
        for k, v in self.old.items():
            setattr(self.mod, k, v)


def joelheira(cor, cor2):
    t0 = ab.tubo

    def t(p, k, q, w0, w1, fill):
        out = t0(p, k, q, w0, w1, fill)
        if w0 >= 6.4 or (w0 >= 5.4 and w1 < w0 and w0 - w1 < 0.8 and fill and False):
            out += R(k[0] - 3.5, k[1] - 4, 8, 8, 2.5, cor, k=0.25) + R(k[0] - 2.5, k[1] - 3, 6, 2.2, 1, cor2, k=0.15)
        return out
    return t


# ================================================================ MARRETÃO (K1 aprovado + K6 Brigadista + K7 Sucateiro)
def _marr_face(e):
    return {"normal": "foco", "esforco": "raiva", "ataque": "raiva", "forca": "raiva", "grito": "raiva", "esquiva": "susto"}.get(e, e or "foco")


def k6_cabeca_L(col, e, L="all"):
    """BRIGADISTA: cabeça vermelha de bombeiro, capacete de bombeiro (aba comprida atrás) na cor do jogador com escudo
    creme na frente, tela com fuligem, lanterna em L no ombro do capacete."""
    o = ""
    if L in ("all", "base"):
        o += R(-20, -21, 42, 38, 12, "#c8402f", k=0.7) + R(-20, 8, 42, 9, 6, "#8e2a20", k=0.3)
        o += R(-6, -12, 27, 22, 7, SCREEN, k=0.35) + E(18, 7, 4, 2.5, "#4a4f5c", k=0.2)                  # fuligem no canto
        o += f'<path d="M-20,-4 h-4 M-20,2 h-4" stroke="#f2c84b" stroke-width="2.4"/>'                        # faixas no "pescoço"
        # capacete de bombeiro: domo + aba que desce comprida atrás
        o += S("M-30,-14 C-30,-20 -26,-22 -20,-22 C-20,-42 24,-42 24,-22 L28,-21 C29,-19 27,-17 24,-18 L-18,-18 C-22,-14 -26,-10 -30,-14 Z",
               col, (-31, -43, 29, -9), k=0.5, dark=shade(col, -0.3))
        o += "".join(f'<path d="M{x},-39 C{x - 1},-32 {x - 1},-26 {x},-21" stroke="{shade(col, -0.25)}" stroke-width="1.6" fill="none"/>' for x in (-8, 2, 12))
        o += S("M15,-40 L26,-38 L27,-27 L21,-22 L15,-27 Z", "#efe3c8", (14, -41, 28, -21), k=0.3)             # escudo da frente
        o += P_([(21, -36), (23, -31), (21, -26), (19, -31)], "#c8402f", k=0.15)
    if L in ("all", "face"):
        o += '<path d="M-3,-2 h8 M8,-2 h8" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round"/>' if _marr_face(e) == "piscar" else ru.olhos(_marr_face(e), 0)
    if L in ("all", "acc"):   # lanterna em L de bombeiro
        o += R(-16, -48, 7, 9, 2, "#f08a2b", k=0.2) + R(-15, -51, 5, 3, 1, "#3a3f4a", k=0.15) + E(-12.5, -44, 2, 2, "#fff6c8", k=0.1)
    return o


def k6_tronco(col, pose):
    """Japona de bombeiro (areia) com faixas amarelo-prata, gola alta, mosquetão e extintorzinho na cintura."""
    t = S("M-12,0 C-15,-6 -13,-19 0,-20 C13,-19 15,-6 12,0 Z", "#d9b45a", (-16, -21, 16, 1), k=0.6, dark="#a8873a")
    t += R(-6, -21, 13, 4, 2, "#a8873a", k=0.2)                                                         # gola
    for y in (-13, -6):
        t += R(-13, y, 26, 4, 1.2, "#f2e04b", k=0.25) + R(-13, y + 1.2, 26, 1.6, 0.6, REFL, k=0.15)
    t += f'<path d="M1,-19 L1,-2" stroke="#8a6a2a" stroke-width="1.2"/>'
    t += R(-11, -2, 22, 3.5, 1.2, "#2f2f36", k=0.25) + E(5, 0, 2.2, 2.6, "#c9d1d8", k=0.15)              # cinto + mosquetão
    t += R(-13, -4, 5, 9, 2, "#c8402f", k=0.25) + R(-12, -6, 3, 2, 0.6, "#2f2f36", k=0.1)                 # extintorzinho
    return t


def k6_marreta(g, ang, s=0.72):
    """Machado-marreta de bombeiro: cabeça vermelha com lâmina de machado atrás, cabo de fibra amarelo."""
    cabo = R(-24, -3, 62, 6, 2.5, YEL, k=0.5, dark=YEL_D) + R(-24, -4, 18, 8, 3, "#2f2f36", k=0.4)
    cabo += "".join(f'<path d="M{-22 + i * 4},-4 l2,8" stroke="#55555f" stroke-width="1.3"/>' for i in range(5))
    cab = R(44, -15, 26, 30, 3, "#c8402f", k=0.6, dark="#8e2a20") + R(44, -15, 26, 5, 2, "#e0634e", k=0.3)
    cab += R(67, -17, 7, 34, 2.5, STEEL, k=0.45, dark=STEEL_D)
    cab += S("M44,-12 C34,-20 24,-14 22,-4 C30,-8 36,-6 44,-2 Z", STEEL, (21, -21, 45, -1), k=0.4, dark=STEEL_D, light=STEEL_L)   # lâmina
    cab += S("M44,12 C34,20 24,14 22,4 C30,8 36,6 44,2 Z", STEEL, (21, 1, 45, 21), k=0.4, dark=STEEL_D, light=STEEL_L)
    g2 = (g[0] - math.cos(math.radians(ang)) * 11, g[1] - math.sin(math.radians(ang)) * 11)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f}) scale({s})">{cabo + cab}</g>', g, g2


FERRUGEM, FERRUGEM_D = "#b06a35", "#7a4420"


def k7_cabeca_L(col, e, L="all"):
    """SUCATEIRO: casco enferrujado com chapas rebitadas e fita, BALDE amassado de capacete (cor do jogador) com alça
    de arame, tela trincada."""
    o = ""
    if L in ("all", "base"):
        o += R(-20, -21, 42, 38, 12, FERRUGEM, k=0.7) + R(-20, 8, 42, 9, 6, FERRUGEM_D, k=0.3)
        o += R(-21, -6, 14, 14, 2, "#8f98a4", k=0.3) + "".join(f'<circle cx="{x}" cy="{y}" r="1" fill="{STEEL_D}"/>' for x, y in ((-19, -4), (-9, -4), (-19, 6), (-9, 6)))
        o += R(-6, -12, 27, 22, 7, SCREEN, k=0.35)
        o += f'<path d="M14,-12 L11,-5 L15,-1 L12,5" stroke="#9fb3c4" stroke-width="0.9" fill="none"/>'      # trinca
        o += f'<path d="M-15,10 l9,-6 M-15,4 l9,6" stroke="#d8d0b8" stroke-width="3.4" stroke-linecap="round"/>'   # fita em X
        # balde amassado de capacete
        o += S("M-17,-20 L-13,-41 L19,-41 L23,-20 Z", col, (-18, -42, 24, -19), k=0.5, dark=shade(col, -0.32))
        o += R(-20, -23, 46, 5, 2, shade(col, -0.25), k=0.3)
        o += f'<path d="M-6,-40 l3,6 l4,-3" stroke="{shade(col, -0.4)}" stroke-width="1.6" fill="none"/>'      # amassado
        o += f'<path d="M-15,-30 C-28,-22 -26,-6 -21,-2" stroke="#8f98a4" stroke-width="1.6" fill="none"/>'    # alça de arame
        o += R(-11, -36, 3, 9, 1, shade(col, 0.25), k=0.15)
    if L in ("all", "face"):
        o += '<path d="M-3,-2 h8 M8,-2 h8" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round"/>' if _marr_face(e) == "piscar" else ru.olhos(_marr_face(e), 0)
    if L in ("all", "acc"):   # antena de cabide torto
        o += f'<path d="M14,-41 C16,-48 12,-52 18,-56" stroke="#8f98a4" stroke-width="1.6" fill="none"/><circle cx="18" cy="-56" r="2" fill="#e84a3a"/>'
    return o


def k7_tronco(col, pose):
    """Tronco de TAMBOR de óleo (azul descascado, frisos) com um PNEU velho de cinto."""
    t = S("M-11,0 C-13,-6 -12,-18 0,-19 C12,-18 13,-6 11,0 Z", "#3f6f9a", (-14, -20, 14, 1), k=0.6, dark="#2b4e70")
    t += "".join(f'<path d="M-12,{y} C-4,{y + 1.5} 4,{y + 1.5} 12,{y}" stroke="#2b4e70" stroke-width="1.4" fill="none"/>' for y in (-15, -10))
    t += E(-5, -12, 3, 2, FERRUGEM, k=0.15) + E(7, -16, 2, 1.5, FERRUGEM, k=0.15)
    t += R(-14, -6, 28, 7, 3.5, "#2a2a30", k=0.4) + "".join(f'<path d="M{x},-6 l2,7" stroke="#4a4a54" stroke-width="1.4"/>' for x in range(-12, 13, 4))
    return t


def k7_marreta(g, ang, s=0.72):
    """Marreta de ferro-velho: cano de cabo com fita, cabeça = BLOCO DE CONCRETO com vergalhões, amarrado com arame."""
    cabo = R(-24, -3, 62, 6, 2.5, "#8f98a4", k=0.5, dark=STEEL_D) + R(-6, -4, 10, 8, 2, "#d8d0b8", k=0.3)
    cabo += R(-24, -4, 14, 8, 3, "#e84a3a", k=0.4)
    cab = R(38, -18, 34, 36, 2, "#b9b2a6", k=0.6, dark="#8f887c") + R(44, -12, 8, 8, 1, "#8f887c", k=0.2) + R(58, 2, 8, 8, 1, "#8f887c", k=0.2)
    cab += f'<path d="M50,-18 l-3,-8 M62,18 l4,7 M70,-10 l7,-3" stroke="#8a5a3a" stroke-width="2" stroke-linecap="round"/>'
    cab += f'<path d="M36,-14 L40,14 M36,14 L40,-14" stroke="#c9d1d8" stroke-width="1.6"/>'
    g2 = (g[0] - math.cos(math.radians(ang)) * 11, g[1] - math.sin(math.radians(ang)) * 11)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f}) scale({s})">{cabo + cab}</g>', g, g2


def _marr_skin(cabL, tronco, marreta, glove, glove_d, boot, sola, tubo=None):
    def draw(col, pose):
        with Troca(ru, cabeca=lambda c, p: cabL(c, p.get("face", "foco"), "all"), tronco=tronco, marreta=marreta,
                   GLOVE=glove, GLOVE_D=glove_d, BOOT=boot, SOLA=sola):
            with Troca(ab, tubo=tubo or ab.tubo):
                return ru.desenha(pose, col)
    return draw


def _marr_padrao(col, pose):
    return ru.desenha(pose, col)


MARR_POSES = {"parado": ru.PARADO, "golpe": ru.A_pesado()[2][3][1]}
MARRETAO = dict(nome="MARRETÃO", escala=4.0, dx=10, poses=MARR_POSES, padrao=_marr_padrao, skins=[
    ("K1", "MESTRE DE OBRAS", ["capacete de aba total com lanterna,", "bigodão, colete refletivo (APROVADO)"],
     _marr_skin(k1m.k1_cabeca_L, k1m.k1_tronco, k1m.k1_marreta, k1m.COURO, k1m.COURO_D, k1m.BOTA, k1m.BOTA_D, k1m._tubo_k1)),
    ("K6", "BRIGADISTA", ["capacete de bombeiro, japona areia com", "faixas, machado-marreta vermelho"],
     _marr_skin(k6_cabeca_L, k6_tronco, k6_marreta, "#2f2f36", "#1f1f24", "#2b2b31", YEL, joelheira("#2f2f36", "#f2e04b"))),
    ("K7", "SUCATEIRO", ["balde amassado de capacete, tambor de", "óleo, pneu de cinto, marreta de entulho"],
     _marr_skin(k7_cabeca_L, k7_tronco, k7_marreta, "#f2c84b", "#3f6f9a", "#5a4a3a", "#2a2a30", joelheira("#c9d1d8", "#8f98a4"))),
])


# ================================================================ GUINDASTE (K2 Topógrafo · K8 Grua Clássica · K9 Pintor)
def _g_eye(pose, cx=4, cy=-9, r=8.5):
    return eu.olho_unico(cx, cy, r, pose.get("face", "foco"))


def k2_head(col, pose):
    """TOPÓGRAFO: cabeça creme, o olhão vira LENTE DE TEODOLITO (aro de latão e mira), chapéu de aba larga na cor do
    jogador com protetor de nuca, teodolito pequeno no alto."""
    h = ""
    if eu._Lb(pose):
        h += E(0, -10, 20, 18, "#efe3c8", k=0.7) + E(0, 2, 18, 6, "#c9b894", k=0.3)
        h += E(4, -9, 14, 14, "#b8872a", k=0.3) + E(4, -9, 11, 11, "#2a2f38", k=0.25) + E(4, -9, 9, 9, eu.GLASS, k=0.2)
        h += f'<path d="M4,-19 v4 M4,-3 v4 M-6,-9 h4 M12,-9 h4" stroke="#1f2a36" stroke-width="1" opacity="0.6"/>'    # mira
        h += S("M-24,-22 C-24,-26 24,-26 26,-22 C26,-19 -24,-18 -24,-22 Z", shade(col, -0.2), (-25, -27, 27, -17), k=0.4)   # aba larga
        h += S("M-16,-23 C-16,-38 16,-38 16,-23 Z", col, (-17, -39, 17, -22), k=0.5, dark=shade(col, -0.3))
        h += R(-16, -27, 32, 3.5, 1, shade(col, -0.35), k=0.2)
        h += S("M-24,-21 C-30,-12 -26,-4 -20,-4 L-18,-18 Z", shade(col, 0.15), (-31, -22, -17, -3), k=0.3)                # protetor de nuca
    if eu._Lf(pose):
        h += _g_eye(pose)
    if eu._La(pose):   # teodolito no alto do chapéu
        h += f'<path d="M-4,-36 l-4,-8 M2,-36 l0,-9 M8,-36 l4,-8" stroke="#8a6a3a" stroke-width="1.4"/>' + R(-5, -50, 12, 6, 2, YEL, k=0.2) + E(9, -47, 3, 2.5, "#2a2f38", k=0.15)
    return h


def k2_torso(col, pose):
    t = S("M-11,0 C-14,-8 -11,-22 0,-23 C11,-22 14,-8 11,0 Z", "#c6e84a", (-15, -24, 15, 1), k=0.6, dark="#93b02a")
    t += faixa_refl(-12, -16, 24) + faixa_refl(-12, -10, 24)
    t += f'<path d="M-9,-22 L10,-3" stroke="#6b4a2a" stroke-width="2.2"/>' + R(6, -6, 9, 7, 1.5, "#8a5a2b", k=0.25)        # alça + bolsa
    t += R(-11, -5, 22, 4, 2, "#3a3f4a", k=0.3)
    return t


def k2_lanca(g, ang, pose):
    """BALIZA de topografia listrada vermelho/branco, prisma na ponta e o gancho pendurado."""
    L = eu.LANCA_L
    body = R(-6, -3, L + 6, 6, 2, "#f4f1ea", k=0.5)
    body += "".join(R(x, -3, 6, 6, 0.5, "#d42035", k=0.2) for x in range(-4, L - 2, 12))
    body += R(-10, -4, 8, 8, 2, "#3a3f4a", k=0.3) + E(L + 2, 0, 4.5, 4.5, "#ffb84a", k=0.2) + E(L + 2, 0, 2.2, 2.2, "#fff3c8", k=0.1)
    o = f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>'
    tip = (g[0] + math.cos(math.radians(ang)) * L, g[1] + math.sin(math.radians(ang)) * L)
    o += eu.gancho_ponta(tip[0], tip[1], pose.get("chain_L", 14), pose.get("chain_sag", 0))
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return o, g, g2


def k8_head(col, pose):
    """GRUA CLÁSSICA: a cabeça vira a CABINE da grua (cor do jogador) com janelão (o olho), teto com corrimão,
    contrapeso de concreto atrás e luz de topo vermelha."""
    h = ""
    if eu._Lb(pose):
        h += R(-22, -14, 12, 20, 2, "#9aa0a6", k=0.4) + R(-22, -6, 12, 2, 0.5, "#7a8088", k=0.1) + R(-22, 0, 12, 2, 0.5, "#7a8088", k=0.1)   # contrapeso
        h += R(-14, -28, 32, 34, 4, col, k=0.6, dark=shade(col, -0.3)) + R(-14, -28, 32, 6, 3, shade(col, 0.2), k=0.25)
        h += R(-6, -22, 22, 24, 3, "#2a2f38", k=0.3) + R(-4, -20, 18, 20, 2, eu.GLASS, k=0.2)
        h += f'<path d="M-4,-14 L14,-14 M5,-20 L5,0" stroke="#2a2f38" stroke-width="1.2" opacity="0.5"/>'
        h += f'<path d="M-14,-32 h32 M-12,-32 v4 M0,-32 v4 M12,-32 v4" stroke="#3a3f4a" stroke-width="1.6"/>'          # corrimão
        h += R(-14, 4, 32, 4, 1, "#d42035", k=0.2) + "".join(R(x, 4, 4, 4, 0, "#f4f1ea", k=0.1) for x in (-10, -2, 6, 14))
    if eu._Lf(pose):
        h += _g_eye(pose, 5, -10, 8)
    if eu._La(pose):
        h += f'<path d="M14,-32 v-6" stroke="{cb.MEC_D}" stroke-width="1.6"/>' + E(14, -40, 3, 3, "#ff4a3a", k=0.2) + '<circle cx="14" cy="-40" r="6" fill="#ff8a7a" opacity="0.3"/>'
    return h


def k8_torso(col, pose):
    t = S("M-11,0 C-14,-8 -11,-22 0,-23 C11,-22 14,-8 11,0 Z", "#f4f1ea", (-15, -24, 15, 1), k=0.6, dark="#c9c2b4")
    t += "".join(f'<path d="M{x},-21 L{x + 6},-3 M{x + 6},-21 L{x},-3" stroke="#d42035" stroke-width="2"/>' for x in (-9, -1, 7))
    t += R(-11, -6, 22, 4, 2, "#d42035", k=0.3)
    return t


def k8_lanca(g, ang, pose):
    L = eu.LANCA_L
    body = R(-6, -5, L + 6, 10, 1.5, "#f4f1ea", k=0.5)
    body += "".join(f'<path d="M{x},-4 L{x + 5},4 L{x + 10},-4" stroke="#d42035" stroke-width="2" fill="none"/>' for x in range(-4, L - 4, 10))
    body += R(-6, -6, L + 6, 2, 0.5, "#d42035", k=0.1) + R(-6, 4, L + 6, 2, 0.5, "#d42035", k=0.1)
    body += R(-12, -6, 9, 12, 2, "#3a3f4a", k=0.3) + E(L, 0, 3.6, 3.6, STEEL_D, k=0.2)
    o = f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>'
    tip = (g[0] + math.cos(math.radians(ang)) * L, g[1] + math.sin(math.radians(ang)) * L)
    drop = pose.get("chain_L", 14)
    ex, ey = tip[0] + pose.get("chain_sag", 0), tip[1] + drop
    o += f'<path d="M{tip[0]:.1f},{tip[1]:.1f} L{ex:.1f},{ey:.1f}" stroke="{STEEL_D}" stroke-width="1.8" stroke-dasharray="3 1.5"/>'
    o += R(ex - 6, ey - 1, 12, 8, 2, "#d42035", k=0.3) + R(ex - 6, ey + 2, 12, 2.5, 0.5, "#f4f1ea", k=0.1)              # moitão listrado
    o += f'<path d="M{ex:.1f},{ey + 7:.1f} v4 a6,6 0 1 1 -9,5" stroke="{STEEL}" stroke-width="4.5" fill="none" stroke-linecap="round"/>'
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return o, g, g2


TINTAS = ["#e84a3a", "#4f86d9", "#5cc45c", "#f2c84b"]


def _respingos(pts):
    return "".join(E(x, y, r, r * 0.8, TINTAS[i % 4], k=0.15) for i, (x, y, r) in enumerate(pts))


def k9_head(col, pose):
    """PINTOR: cabeça branca respingada de tinta, CHAPÉU DE JORNAL dobrado (cor do jogador), lápis-pincel atrás."""
    h = ""
    if eu._Lb(pose):
        h += E(0, -10, 20, 18, "#f4f1ea", k=0.7) + E(0, 2, 18, 6, "#d6d0c4", k=0.3)
        h += _respingos([(-14, -2, 2.2), (-8, 4, 1.4), (15, 1, 1.8), (-16, -14, 1.2)])
        h += E(4, -9, 13, 13, "#2a2f38", k=0.3) + E(4, -9, 10, 10, eu.GLASS, k=0.2)
        h += S("M8,1 C9,4 8,7 9,9 C10,7 10,4 9,1 Z", "#4f86d9", (7, 0, 11, 10), k=0.1)                             # pingo
        h += P_([(-20, -22), (2, -44), (22, -22)], col, k=0.4, dark=shade(col, -0.3))                                # chapéu de jornal
        h += P_([(-22, -24), (22, -24), (22, -19), (-22, -19)], shade(col, -0.2), k=0.25)
        h += f'<path d="M-6,-30 h10 M-3,-34 h8 M-9,-26 h16" stroke="{shade(col, -0.45)}" stroke-width="0.9" opacity="0.6"/>'   # "letrinhas"
    if eu._Lf(pose):
        h += _g_eye(pose)
    if eu._La(pose):   # pincel atrás da orelha
        h += f'<g transform="rotate(-60 -18 -16)">' + R(-26, -18, 10, 3, 1, "#c98a4b", k=0.15) + R(-17, -19, 5, 5, 1, "#e84a3a", k=0.15) + "</g>"
    return h


def k9_torso(col, pose):
    t = S("M-11,0 C-14,-8 -11,-22 0,-23 C11,-22 14,-8 11,0 Z", "#f4f1ea", (-15, -24, 15, 1), k=0.6, dark="#d6d0c4")
    t += R(-9, -18, 18, 14, 3, "#e6e0d2", k=0.25) + f'<path d="M-9,-18 L-6,-24 M9,-18 L6,-24" stroke="#d6d0c4" stroke-width="2.4"/>'   # jardineira
    t += R(-3, -15, 6, 5, 1, "#d6d0c4", k=0.15) + R(-1.5, -20, 2.5, 7, 0.8, "#c98a4b", k=0.1)                   # bolso + pincel
    t += _respingos([(-7, -8, 1.6), (6, -12, 1.4), (8, -4, 2), (-4, -20, 1.2), (2, -6, 1.1)])
    return t


def k9_lanca(g, ang, pose):
    """Cabo extensor com ROLO DE PINTURA na ponta; no lugar do gancho, uma LATA DE TINTA pendurada."""
    L = eu.LANCA_L
    body = R(-6, -2.5, L - 2, 5, 2, "#c9d1d8", k=0.5) + R(-10, -4, 9, 8, 2, "#3a3f4a", k=0.3)
    body += R(L - 8, -1.5, 8, 3, 1, STEEL_D, k=0.2) + R(L - 2, -9, 9, 18, 4, "#f4f1ea", k=0.4) + R(L - 2, -9, 9, 18, 4, "#4f86d9", k=0.2)
    o = f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>'
    tip = (g[0] + math.cos(math.radians(ang)) * (L - 6), g[1] + math.sin(math.radians(ang)) * (L - 6))
    ex, ey = tip[0] + pose.get("chain_sag", 0), tip[1] + pose.get("chain_L", 14)
    o += f'<path d="M{tip[0]:.1f},{tip[1]:.1f} L{ex:.1f},{ey:.1f}" stroke="{STEEL_D}" stroke-width="1.4"/>'
    o += R(ex - 7, ey, 14, 14, 2, "#c9d1d8", k=0.3, dark=STEEL_D) + R(ex - 7, ey, 14, 4, 1.5, "#4f86d9", k=0.15)
    o += S(f"M{ex - 7},{ey + 4} C{ex - 8},{ey + 9} {ex - 5},{ey + 10} {ex - 4},{ey + 6} Z", "#4f86d9", (ex - 9, ey + 3, ex - 3, ey + 11), k=0.1)
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return o, g, g2


def _gen_skin(base, **kv):
    spec = dict(base, **kv)
    tubo = kv.pop("tubo", None) if "tubo" in kv else None

    def draw(col, pose):
        with Troca(eu, tubo=spec.get("tubo") or eu.tubo):
            return eu.corpo_generico(spec, col, dict(pose))
    return draw


def _gen_padrao(base):
    return lambda col, pose: eu.corpo_generico(base, col, dict(pose))


GUINDASTE = dict(nome="GUINDASTE", escala=4.8, poses=eu.GUINDA_P, padrao=_gen_padrao(eu.GUINDA), skins=[
    ("K2", "TOPÓGRAFO", ["chapéu de aba com nuca, olho de teodolito,", "colete limão, baliza listrada"],
     _gen_skin(eu.GUINDA, head=k2_head, torso=k2_torso, weapon=k2_lanca, hand=mao("#f4f1ea"), boot=bota("#7a4a28", "#3a2a20", 1.1))),
    ("K8", "GRUA CLÁSSICA", ["a cabeça vira a cabine da grua com", "contrapeso; treliça vermelha e branca"],
     _gen_skin(eu.GUINDA, head=k8_head, torso=k8_torso, weapon=k8_lanca, hand=mao("#8f98a4"), boot=bota("#3d434e", "#d42035", 1.1))),
    ("K9", "PINTOR", ["chapéu de jornal, jardineira respingada,", "rolo de pintura com lata pendurada"],
     _gen_skin(eu.GUINDA, head=k9_head, torso=k9_torso, weapon=k9_lanca, hand=mao("#f4f1ea"), boot=bota("#f4f1ea", "#4f86d9", 1.1))),
])


# ================================================================ SOLDA (K3 Soldador Caprichado · K10 Eletricista · K11 Mergulhador)
GLOW = "#ff8a2a"


def _solda_face(pose, glow=GLOW):
    p = dict(pose, L="face")
    o = eu.solda_head("#000", p)
    return o.replace(GLOW, glow) if glow != GLOW else o


def k3_head(col, pose):
    """SOLDADOR CAPRICHADO: máscara de solda grande NA COR DO JOGADOR com chamas pintadas, visor verde, presilha cromada."""
    h = ""
    if eu._Lb(pose):
        h += R(-17, -18, 34, 34, 8, col, k=0.6, dark=shade(col, -0.3)) + R(-15, -16, 30, 9, 6, shade(col, 0.2), k=0.25)
        h += S("M-17,16 C-14,6 -12,10 -9,2 C-7,9 -4,6 -2,-2 C1,7 4,4 6,0 C8,7 11,6 13,2 C14,8 16,10 17,16 Z", "#f08a2b", (-18, -3, 18, 17), k=0.3)
        h += S("M-14,16 C-12,10 -10,12 -8,8 C-6,12 -3,10 -1,6 C1,12 5,9 7,7 C9,12 12,11 14,16 Z", "#f2e04b", (-15, 5, 15, 17), k=0.2)
        h += R(-4, -7, 19, 10, 3, "#1c3a2a", k=0.2) + R(-4, -7, 19, 3, 1.5, "#3f6a50", k=0.1)
        h += R(-17, -22, 34, 5, 2.5, "#c9d1d8", k=0.3) + E(-17, -1, 3.8, 3.8, "#c9d1d8", k=0.2)
    if eu._Lf(pose):
        h += _solda_face(pose, "#8affc1")
    return h


def k3_torso(col, pose):
    t = S("M-12,0 C-15,-10 -10,-22 2,-22 C13,-21 14,-9 11,0 Z", "#3a3f4a", (-16, -23, 15, 1), k=0.6)
    t += S("M-9,0 C-11,-8 -8,-18 2,-18 C10,-18 11,-8 9,0 Z", "#8a5a2b", (-12, -19, 12, 1), k=0.5, dark="#5e3b1a")   # avental de couro
    t += "".join(f'<circle cx="{x}" cy="{y}" r="1.2" fill="#e8eef2"/>' for x, y in ((-6, -15), (0, -16), (6, -15), (-7, -9), (7, -9), (-6, -3), (6, -3)))
    t += R(-12, -6, 23, 4, 2, "#2a2a30", k=0.3)
    return t


def k3_tanques(col, pose):
    hip, lean = pose["hip"], pose.get("lean", 0)
    q = eu.rot((-14, -14), lean * 0.6, (0, 0))
    x, y = q[0] + hip[0], q[1] + hip[1]
    return (f'<g transform="translate({x:.1f},{y:.1f}) rotate({lean * 0.6:.1f})">' + R(-8, -14, 8, 22, 4, "#c9d1d8", k=0.5, dark=STEEL_D) + R(-1, -12, 8, 20, 4, "#e8eef2", k=0.5, dark=STEEL)
            + R(-8, -6, 8, 2.5, 0.5, "#f08a2b", k=0.1) + R(-1, -4, 8, 2.5, 0.5, "#f08a2b", k=0.1)
            + R(-6, -17, 4, 4, 1, STEEL_D, k=0.2) + f'<path d="M3,-12 C10,-24 18,-22 20,-14" stroke="#2a2a30" stroke-width="2" fill="none"/></g>')


COBRE, COBRE_D, COBRE_L = "#c87533", "#8e4f1f", "#e8a06a"


def k3_chave(g, ang, pose):
    body = R(-14, -3.5, 46, 7, 3, COBRE, k=0.5, dark=COBRE_D, light=COBRE_L)
    body += S("M30,-12 L44,-12 L46,-4 L38,-4 L38,4 L46,4 L44,12 L30,12 Z", COBRE, (29, -13, 47, 13), k=0.5, dark=COBRE_D, light=COBRE_L)
    body += E(32, 0, 2.5, 2.5, COBRE_D, k=0.2) + R(-14, -4, 12, 8, 3, "#2a2a30", k=0.3)
    body += S("M14,-3.5 C18,-8 22,-3 26,-7 C26,-2 22,1 18,0 Z", "#f08a2b", (13, -9, 27, 1), k=0.15)
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def k10_head(col, pose):
    """ELETRICISTA: capacete classe B na cor do jogador com raio, PROTETOR FACIAL transparente sobre a cara grafite,
    olhos acesos atrás do protetor."""
    h = ""
    if eu._Lb(pose):
        h += R(-15, -14, 30, 28, 9, GRAFITE, k=0.6) + R(-3, -6, 17, 9, 3, "#1f1a1a", k=0.2)
        h += S("M-17,-22 C-17,-36 19,-36 19,-22 Z", col, (-18, -37, 20, -21), k=0.5, dark=shade(col, -0.3))
        h += R(-21, -24, 42, 5, 2.5, shade(col, -0.25), k=0.3)
        h += P_([(2, -34), (-3, -27), (1, -27), (-2, -22), (5, -29), (1, -29)], "#f2e04b", k=0.15)                 # raio
        h += S("M-12,-19 L18,-19 C22,-8 21,6 14,12 L-10,12 Z", "#bfe7ff", (-13, -20, 22, 13), k=0.3)                 # protetor facial
        h += f'<path d="M-12,-19 L18,-19 C22,-8 21,6 14,12 L-10,12 Z" fill="#bfe7ff" opacity="0.0"/>'
    if eu._Lf(pose):
        h += _solda_face(pose, "#ffe14a")
    if eu._Lb(pose):   # brilho do protetor por cima do rosto
        h += f'<path d="M14,-15 C17,-8 17,0 14,6" stroke="#ffffff" stroke-width="2" fill="none" opacity="0.7"/>'
    return h


def k10_torso(col, pose):
    t = S("M-12,0 C-15,-10 -10,-22 2,-22 C13,-21 14,-9 11,0 Z", "#2f4a7a", (-16, -23, 15, 1), k=0.6, dark="#22365a")
    t += R(-12, -6, 23, 4.5, 2, "#8a5a2b", k=0.3) + R(-8, -10, 4, 6, 1, "#f2e04b", k=0.2)                          # cinto + testador
    t += E(6, -3, 4, 3, "#f08a2b", k=0.2) + E(6, -3, 2, 1.5, "#2f4a7a", k=0.1)                                     # rolo de fio
    t += f'<path d="M-10,-16 C-4,-12 2,-20 9,-14" stroke="#f08a2b" stroke-width="1.6" fill="none"/>'
    return t


def k10_bobina(col, pose):
    hip, lean = pose["hip"], pose.get("lean", 0)
    q = eu.rot((-15, -14), lean * 0.6, (0, 0))
    x, y = q[0] + hip[0], q[1] + hip[1]
    return (f'<g transform="translate({x:.1f},{y:.1f}) rotate({lean * 0.6:.1f})">' + E(-3, -3, 11, 13, "#a8683a", k=0.5, dark="#6e3f20")
            + E(-3, -3, 7, 9, "#f08a2b", k=0.3) + "".join(f'<path d="M-9,{yy} C-5,{yy - 2} -1,{yy - 2} 3,{yy}" stroke="#b85a1e" stroke-width="1.2" fill="none"/>' for yy in (-8, -4, 0, 4))
            + E(-3, -3, 2.5, 2.5, "#6e3f20", k=0.15) + "</g>")


def k10_alicate(g, ang, pose):
    """ALICATE gigante: cabos com isolamento vermelho/amarelo, mordente de aço."""
    body = R(-14, -5, 26, 4.5, 2, "#d42035", k=0.4) + R(-14, 0.5, 26, 4.5, 2, YEL, k=0.4, dark=YEL_D)
    body += E(15, 0, 5, 5, STEEL, k=0.3, dark=STEEL_D) + E(15, 0, 1.8, 1.8, STEEL_D, k=0.1)
    body += S("M18,-5 L40,-9 L44,-4 L20,1 Z", STEEL, (17, -10, 45, 2), k=0.4, dark=STEEL_D, light=STEEL_L)
    body += S("M18,5 L40,9 L44,4 L20,-1 Z", STEEL, (17, -2, 45, 10), k=0.4, dark=STEEL_D, light=STEEL_L)
    body += "".join(f'<path d="M{x},-5 l2,2 M{x},5 l2,-2" stroke="{STEEL_D}" stroke-width="0.8"/>' for x in range(24, 40, 4))
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


LATAO, LATAO_D = "#d0a046", "#8f6a22"


def k11_head(col, pose):
    """MERGULHADOR DE POÇO (fundações alagadas): capacete de escafandro NA COR DO JOGADOR, aros e parafusos de latão,
    janela da frente redonda (olhos acesos), janelinhas laterais, gola de latão."""
    h = ""
    if eu._Lb(pose):
        h += R(-18, 6, 36, 9, 3, LATAO, k=0.4, dark=LATAO_D) + "".join(E(x, 10.5, 1.4, 1.4, LATAO_D, k=0.1) for x in (-13, -6, 1, 8, 15))
        h += E(0, -6, 18, 18, col, k=0.6, dark=shade(col, -0.3)) + E(-4, -16, 9, 5, shade(col, 0.25), k=0.25)
        h += E(5, -5, 10, 10, LATAO, k=0.3, dark=LATAO_D) + E(5, -5, 7.5, 7.5, "#1c2a38", k=0.2)
        h += f'<path d="M5,-12.5 v15 M-2.5,-5 h15" stroke="{LATAO_D}" stroke-width="1"/>'
        h += E(-12, -6, 4.5, 4.5, LATAO, k=0.2) + E(-12, -6, 2.8, 2.8, "#1c2a38", k=0.1)
        h += E(0, -24, 4, 2.5, LATAO, k=0.2)
    if eu._Lf(pose):
        h += _solda_face(dict(pose), "#7fe8ff").replace('y="-4"', 'y="-6"')
    return h


def k11_torso(col, pose):
    t = S("M-12,0 C-15,-10 -10,-22 2,-22 C13,-21 14,-9 11,0 Z", "#9b8a6e", (-16, -23, 15, 1), k=0.6, dark="#6e5f48")
    t += R(-10, -22, 22, 6, 2, LATAO, k=0.3, dark=LATAO_D) + "".join(E(x, -19, 1.1, 1.1, LATAO_D, k=0.1) for x in (-6, 0, 6))
    t += R(-12, -6, 23, 4, 2, "#5a4a3a", k=0.3) + R(-4, -6.5, 6, 5, 1, "#8f98a4", k=0.15)                          # cinto de lastro
    return t


def k11_tanque(col, pose):
    hip, lean = pose["hip"], pose.get("lean", 0)
    q = eu.rot((-14, -14), lean * 0.6, (0, 0))
    x, y = q[0] + hip[0], q[1] + hip[1]
    return (f'<g transform="translate({x:.1f},{y:.1f}) rotate({lean * 0.6:.1f})">' + R(-9, -16, 13, 26, 6, "#f2c84b", k=0.5, dark=YEL_D)
            + R(-6, -19, 6, 4, 1, STEEL_D, k=0.2) + f'<path d="M-3,-19 C2,-30 14,-26 16,-14" stroke="#2a2a30" stroke-width="2.4" fill="none"/></g>')


def k11_chave(g, ang, pose):
    body = R(-14, -3.5, 46, 7, 3, LATAO, k=0.5, dark=LATAO_D)
    body += S("M30,-12 L44,-12 L46,-4 L38,-4 L38,4 L46,4 L44,12 L30,12 Z", LATAO, (29, -13, 47, 13), k=0.5, dark=LATAO_D)
    body += E(32, 0, 2.5, 2.5, LATAO_D, k=0.2) + R(-14, -4, 12, 8, 3, "#3a3f4a", k=0.3)
    body += S("M6,3.5 C4,9 8,12 6,16 C10,12 9,8 11,3.5 Z", "#5cc45c", (3, 2, 12, 17), k=0.15)                     # alga
    g2 = (g[0] - math.cos(math.radians(ang)) * 10, g[1] - math.sin(math.radians(ang)) * 10)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


SOLDA = dict(nome="SOLDA", escala=5.0, poses=eu.SOLDA_P, padrao=_gen_padrao(eu.SOLDA), skins=[
    ("K3", "SOLDADOR CAPRICHADO", ["máscara na cor com chamas pintadas,", "avental de couro tachado, chave de cobre"],
     _gen_skin(eu.SOLDA, head=k3_head, torso=k3_torso, pre=k3_tanques, weapon=k3_chave, hand=mao("#8a5a2b", 6.2), boot=bota("#4a2d18", "#2a2a30", 1.05))),
    ("K10", "ELETRICISTA", ["capacete com raio, protetor facial,", "bobina de fio nas costas, alicate gigante"],
     _gen_skin(eu.SOLDA, head=k10_head, torso=k10_torso, pre=k10_bobina, weapon=k10_alicate, hand=mao("#f08a2b", 6.2), boot=bota("#2b2b31", "#f2c84b", 1.05))),
    ("K11", "MERGULHADOR DE POÇO", ["escafandro na cor com latão, tanque", "de ar amarelo, chave de bronze com alga"],
     _gen_skin(eu.SOLDA, head=k11_head, torso=k11_torso, pre=k11_tanque, weapon=k11_chave, hand=mao("#6e5f48", 6.2), boot=bota("#4a4f5c", "#2a2a30", 1.3))),
])


# ================================================================ BRITA (K4 Concreteiro · K12 Asfaltador · K13 Mineiro)
CIMENTO, CIMENTO_D = "#b9b2a6", "#8f887c"


def _brita_tambor(col, extra=""):
    h = f'<g transform="rotate(-14)">' + E(0, -18, 25, 17, col, k=0.7)
    for i in range(4):
        x = -18 + i * 11
        h += f'<path d="M{x},-33 Q{x + 7},-18 {x},-3" stroke="{shade(col, -0.3)}" stroke-width="4.5" fill="none"/>'
    h += E(-24, -22, 5, 9, shade(col, -0.45), k=0.3) + E(-25, -22, 2.6, 5, "#2a2230", k=0.2) + extra + "</g>"
    return h


def _brita_face(pose, dx=0):
    return eu.olhos_tela(pose.get("face", "foco"), 4 + dx, -9, 3.6, 9)


def k4_head(col, pose):
    """CONCRETEIRO: tambor coberto de CIMENTO escorrendo (a cor aparece por baixo), máscara de pó, capacete respingado."""
    h = ""
    if eu._Lb(pose):
        h += _brita_tambor(col, S("M-22,-28 C-14,-36 8,-37 20,-30 L18,-24 C14,-20 12,-26 8,-22 C4,-18 2,-25 -4,-21 C-8,-18 -12,-24 -16,-20 C-19,-18 -21,-23 -22,-28 Z",
                                    CIMENTO, (-23, -38, 21, -17), k=0.35) + E(10, -8, 4, 3, CIMENTO, k=0.15) + E(-12, -6, 3, 2, CIMENTO, k=0.15))
        h += R(-2, -16, 22, 15, 6, SCREEN, k=0.35)
        h += S("M2,-4 C4,4 16,4 18,-4 Z", "#f4f1ea", (1, -5, 19, 4), k=0.25) + E(10, 0, 2.4, 1.6, "#d6d0c4", k=0.1)     # máscara de pó
        h += f'<path d="M2,-4 L-6,-10 M18,-4 L22,-12" stroke="#f4f1ea" stroke-width="1"/>'
        h += S("M-6,-38 C-6,-50 18,-50 18,-38 Z", col, (-7, -51, 19, -37), k=0.4, dark=shade(col, -0.3)) + R(-10, -40, 32, 4, 2, shade(col, -0.25), k=0.2)
        h += E(2, -45, 2.4, 1.8, CIMENTO, k=0.1) + E(12, -42, 1.8, 1.4, CIMENTO, k=0.1)
    if eu._Lf(pose):
        h += _brita_face(pose)
    return h


def k4_torso(col, pose):
    t = R(-15, -15, 30, 16, 7, CIMENTO, k=0.6, dark=CIMENTO_D)
    t += R(-15, -5, 30, 4, 1.5, "#8a5a2b", k=0.25)
    t += f'<g transform="translate(9,-6) rotate(30)">' + P_([(0, 0), (8, -4), (8, 4)], STEEL, k=0.15) + R(-6, -1, 7, 2, 1, "#8a5a2b", k=0.1) + "</g>"   # colher de pedreiro
    t += E(-6, -10, 3, 2, "#a8a196", k=0.1) + E(4, -12, 2, 1.5, "#a8a196", k=0.1)
    return t


def k4_britadeira(g, ang, pose):
    o, g1, g2 = eu.britadeira(g, ang, pose)
    a = ang - 90
    suja = (S("M-6,4 C-2,8 2,2 6,6 L6,14 C3,12 0,16 -3,12 C-5,14 -6,10 -6,8 Z", CIMENTO, (-7, 1, 7, 17), k=0.2)
            + S("M-3.5,28 L3.5,28 L3,34 C1,33 -1,36 -3,33 Z", CIMENTO, (-4, 27, 4, 37), k=0.15))
    return o + f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({a:.1f})">{suja}</g>', g1, g2


def k12_head(col, pose):
    """ASFALTADOR: tambor na cor com ASFALTO preto escorrendo de cima, chaminé fumegante, viseira solar."""
    h = ""
    if eu._Lb(pose):
        h += _brita_tambor(col, S("M-24,-24 C-16,-36 10,-37 22,-28 L20,-22 C16,-18 14,-24 10,-19 C6,-14 4,-23 -2,-18 C-6,-13 -10,-22 -14,-17 C-18,-14 -22,-20 -24,-24 Z",
                                    "#2a2a30", (-25, -38, 23, -13), k=0.35))
        h += R(-2, -16, 22, 15, 6, SCREEN, k=0.35)
        h += R(-4, -18, 26, 4, 2, "#f08a2b", k=0.2)                                                                       # viseira
        h += R(14, -40, 6, 10, 1.5, "#3a3f4a", k=0.2) + R(13, -42, 8, 3, 1, "#2a2a30", k=0.15)                            # chaminé
    if eu._Lf(pose):
        h += _brita_face(pose)
    if eu._La(pose):
        h += E(17, -48, 4, 3, "#8a8a8a", k=0.15) + E(21, -54, 5, 3.5, "#a6a6a6", k=0.15) + '<circle cx="17" cy="-48" r="7" fill="#bbbbbb" opacity="0.3"/>'
    return h


def k12_torso(col, pose):
    t = R(-15, -15, 30, 16, 7, "#f27a1f", k=0.6, dark="#c4531a")
    t += faixa_refl(-15, -11, 30) + faixa_refl(-15, -6, 30)
    t += R(-15, -2, 30, 3, 1.2, "#2a2a30", k=0.2)
    return t


def k12_sapo(g, ang, pose):
    """COMPACTADOR "sapo": alça em T, corpo laranja com motor, sapata larga embaixo."""
    body = R(-11, -2.5, 22, 5, 2.5, "#3a3f4a", k=0.4)
    body += R(-7, 2, 14, 20, 3, "#f27a1f", k=0.5, dark="#c4531a") + R(-9, 8, 6, 9, 2, "#3a3f4a", k=0.2) + E(-6, 12.5, 1.6, 1.6, STEEL_L, k=0.1)
    body += R(-3, 22, 6, 9, 1, STEEL_D, k=0.3) + R(-12, 30, 24, 6, 1.5, "#2a2a30", k=0.3) + R(-12, 30, 24, 2, 0.5, "#4a4a54", k=0.1)
    a = ang - 90
    g2 = (g[0] - math.cos(math.radians(ang + 90)) * 8, g[1] - math.sin(math.radians(ang + 90)) * 8)
    g1 = (g[0] + math.cos(math.radians(ang + 90)) * 8, g[1] + math.sin(math.radians(ang + 90)) * 8)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({a:.1f})">{body}</g>', g1, g2


def k13_head(col, pose):
    """MINEIRO: tambor vira BARRIL de madeira com aros, CAPACETE DE MINEIRO na cor do jogador com farol, carvão na tela."""
    h = ""
    if eu._Lb(pose):
        h += f'<g transform="rotate(-14)">' + E(0, -18, 25, 17, "#b07a45", k=0.7, dark="#7a4a22")
        h += "".join(f'<path d="M{x},-34 Q{x + 3},-18 {x},-2" stroke="#8a5a2b" stroke-width="1.2" fill="none"/>' for x in (-14, -6, 2, 10))
        h += "".join(f'<path d="M{x},-33 Q{x + 6},-18 {x},-3" stroke="#5a606c" stroke-width="3" fill="none"/>' for x in (-19, 15))
        h += E(-24, -22, 5, 9, "#7a4a22", k=0.3) + E(-25, -22, 2.6, 5, "#2a2230", k=0.2) + "</g>"
        h += R(-2, -16, 22, 15, 6, SCREEN, k=0.35) + E(-1, -4, 3, 2, "#4a4f5c", k=0.1) + E(17, -14, 2, 1.5, "#4a4f5c", k=0.1)
        h += S("M-8,-36 C-8,-50 18,-50 18,-36 Z", col, (-9, -51, 19, -35), k=0.4, dark=shade(col, -0.3)) + R(-12, -38, 34, 4, 2, shade(col, -0.25), k=0.2)
        h += R(14, -46, 8, 7, 2, "#3a3f4a", k=0.2) + E(22, -42.5, 2.4, 3, "#fff6c8", k=0.1)                              # farol
    if eu._Lf(pose):
        h += _brita_face(pose)
    if eu._La(pose):
        h += '<path d="M24,-42.5 L48,-50 L48,-34 Z" fill="#fff3b0" opacity="0.35"/>'
    return h


def k13_torso(col, pose):
    t = R(-15, -15, 30, 16, 7, "#a83a2f", k=0.6, dark="#7a2a20")
    t += "".join(f'<path d="M{x},-15 v16" stroke="#7a2a20" stroke-width="1.4"/>' for x in (-9, -3, 3, 9))                # xadrez
    t += "".join(f'<path d="M-15,{y} h30" stroke="#7a2a20" stroke-width="1.4"/>' for y in (-10, -5))
    t += f'<path d="M-8,-15 L-8,1 M8,-15 L8,1" stroke="#5a3d2b" stroke-width="2.6"/>'                                    # suspensório
    t += R(-15, -2, 30, 3, 1.2, "#5a3d2b", k=0.2)
    return t


def k13_perfuratriz(g, ang, pose):
    """PERFURATRIZ de rocha: alça em T, corpo amarelo com mangueira, broca helicoidal comprida."""
    body = R(-11, -2.5, 22, 5, 2.5, "#3a3f4a", k=0.4)
    body += R(-6, 2, 12, 18, 3, YEL, k=0.5, dark=YEL_D) + R(-6, 7, 12, 3, 1, "#2a1a2e", k=0.2)
    body += f'<path d="M6,6 C14,8 14,16 10,20" stroke="#2a2a30" stroke-width="2" fill="none"/>'
    body += R(-2, 20, 4, 26, 1, STEEL, k=0.3, dark=STEEL_D) + "".join(f'<path d="M-2,{y} l4,3" stroke="{STEEL_D}" stroke-width="1.2"/>' for y in range(22, 44, 4))
    a = ang - 90
    g2 = (g[0] - math.cos(math.radians(ang + 90)) * 8, g[1] - math.sin(math.radians(ang + 90)) * 8)
    g1 = (g[0] + math.cos(math.radians(ang + 90)) * 8, g[1] + math.sin(math.radians(ang + 90)) * 8)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({a:.1f})">{body}</g>', g1, g2


BRITA = dict(nome="BRITA", escala=4.3, dx=-45, poses=eu.BRITA_P, padrao=_gen_padrao(eu.BRITA), skins=[
    ("K4", "CONCRETEIRO", ["cimento escorrendo no tambor, máscara de", "pó, capacete respingado, britadeira suja"],
     _gen_skin(eu.BRITA, head=k4_head, torso=k4_torso, weapon=k4_britadeira, hand=mao("#8f887c", 5.5), boot=bota("#f4f1ea", "#b9b2a6", 1.15))),
    ("K12", "ASFALTADOR", ["asfalto escorrendo, chaminé fumegante,", "colete laranja, compactador 'sapo'"],
     _gen_skin(eu.BRITA, head=k12_head, torso=k12_torso, weapon=k12_sapo, hand=mao("#2a2a30", 5.5), boot=bota("#2a2a30", "#f27a1f", 1.2))),
    ("K13", "MINEIRO", ["barril de madeira, capacete de mineiro", "com farol, camisa xadrez, perfuratriz"],
     _gen_skin(eu.BRITA, head=k13_head, torso=k13_torso, weapon=k13_perfuratriz, hand=mao("#8a5a2b", 5.5), boot=bota("#2b2b31", "#5a3d2b", 1.15))),
])


# ================================================================ ESCAVADEIRA (K5 Operador nº01 · K14 Velho de Guerra · K15 Demolidora)
def _zebra_rect(x, y, w, h):
    return cb.faixa(x, y, w, h, n=5)


def k5_head(col, pose):
    """OPERADOR Nº 01: cabine na cor com SANTO-ANTÔNIO (arco de proteção), lâmina zebrada, placa "01"."""
    h = ""
    if eu._Lb(pose):
        h += R(-16, -26, 34, 30, 8, col, k=0.7) + R(-16, -26, 34, 7, 4, shade(col, 0.2), k=0.3)
        h += R(-6, -20, 24, 12, 6, SCREEN, k=0.35)
        h += f'<path d="M-14,-24 L-14,-34 Q1,-40 16,-34 L16,-24" stroke="#3a3f4a" stroke-width="3.2" fill="none" stroke-linejoin="round"/>'
        h += S("M10,-6 C20,-8 26,-2 26,6 C26,12 20,14 10,12 Z", YEL, (9, -9, 27, 15), k=0.5, dark=YEL_D)
        h += f'<clipPath id="k5l"><path d="M10,-6 C20,-8 26,-2 26,6 C26,12 20,14 10,12 Z"/></clipPath><g clip-path="url(#k5l)">'
        h += "".join(f'<path d="M{x},16 L{x + 10},-10 L{x + 14},-10 L{x + 4},16 Z" fill="#2a1a2e"/>' for x in range(4, 30, 8)) + "</g>"
        h += R(-14, -6, 12, 9, 2, "#f4f1ea", k=0.2) + f'<text x="-8" y="0.5" font-family="Fredoka" font-weight="700" font-size="7" fill="#2a1a2e" text-anchor="middle">01</text>'
    if eu._Lf(pose):
        h += eu.olhos_tela(pose.get("face", "foco"), 1.5, -14, 3.6, 9)
    if eu._La(pose):
        h += R(-2, -41, 6, 4, 1, "#3a3f4a", k=0.15) + E(1, -43, 3.4, 3, "#ffb22e", k=0.15) + '<circle cx="1" cy="-43" r="7" fill="#ffd27a" opacity="0.3"/>'
    return h


def k5_torso(col, pose):
    t = R(-17, -26, 34, 22, 7, col, k=0.6)
    t += _zebra_rect(-17, -14, 34, 5)
    t += R(-19, -8, 38, 9, 4.5, "#3a3f4a", k=0.4) + "".join(E(x, -3.5, 2.6, 2.6, STEEL, k=0.15) for x in (-13, -6, 1, 8, 15))
    return t


def k5_cacamba(g, ang, pose):
    body = R(-8, -5, 14, 10, 3, "#4a505c", k=0.4) + R(2, -4, 10, 8, 2, STEEL, k=0.3)
    body += S("M8,-18 L34,-16 C39,-6 39,8 32,15 L8,13 Z", YEL, (7, -19, 40, 16), k=0.6, dark=YEL_D)
    body += f'<clipPath id="k5c"><path d="M8,-18 L34,-16 C39,-6 39,8 32,15 L8,13 Z"/></clipPath><g clip-path="url(#k5c)">'
    body += "".join(f'<path d="M{x},16 L{x + 12},-20 L{x + 16},-20 L{x + 4},16 Z" fill="#2a1a2e" opacity="0.85"/>' for x in range(0, 44, 10)) + "</g>"
    for i in range(4):
        y = -13 + i * 8
        body += P_([(32, y), (44, y + 3), (32, y + 6)], STEEL, k=0.2, dark=STEEL_D)
    g2 = (g[0] - math.cos(math.radians(ang)) * 6, g[1] - math.sin(math.radians(ang)) * 6)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def _ferrugem(pts):
    return "".join(E(x, y, rx, ry, FERRUGEM, k=0.2) for x, y, rx, ry in pts)


def k14_head(col, pose):
    """VELHO DE GUERRA: cabine na cor desbotada com FERRUGEM, remendo de chapa rebitada, lâmina amassada e
    escapamento amarrado com arame soltando fumaça preta."""
    h = ""
    if eu._Lb(pose):
        h += R(-16, -26, 34, 30, 8, col, k=0.7) + R(-16, -26, 34, 7, 4, shade(col, 0.15), k=0.3)
        h += _ferrugem([(-10, -2, 5, 3), (12, -22, 4, 2.5), (-14, -16, 2, 4)])
        h += R(-17, -14, 10, 12, 1, "#8f98a4", k=0.25) + "".join(f'<circle cx="{x}" cy="{y}" r="0.9" fill="{STEEL_D}"/>' for x, y in ((-15, -12), (-9, -12), (-15, -4), (-9, -4)))
        h += R(-6, -20, 24, 12, 6, SCREEN, k=0.35)
        h += S("M10,-6 C18,-9 25,-1 26,5 C24,7 23,9 26,11 C20,15 14,13 10,12 Z", FERRUGEM, (9, -10, 27, 15), k=0.5, dark=FERRUGEM_D)
        h += f'<path d="M18,0 l3,3 M14,8 l4,-2" stroke="{FERRUGEM_D}" stroke-width="1.2"/>'
    if eu._Lf(pose):
        h += eu.olhos_tela(pose.get("face", "foco"), 1.5, -14, 3.6, 9)
    if eu._La(pose):
        h += R(-8, -36, 8, 10, 2, cb.MEC_D, k=0.2) + f'<path d="M-9,-31 h10" stroke="#c9d1d8" stroke-width="1.2"/>'
        h += E(-5, -41, 4, 3, "#3a3a40", k=0.15) + E(-1, -47, 5, 3.5, "#4a4a50", k=0.15) + E(4, -53, 6, 4, "#5a5a60", k=0.15)
    return h


def k14_torso(col, pose):
    t = R(-17, -26, 34, 22, 7, col, k=0.6) + _ferrugem([(-10, -20, 4, 3), (9, -12, 5, 3)])
    t += R(-2, -24, 12, 10, 1, "#8f98a4", k=0.2) + f'<path d="M-2,-24 l12,10" stroke="{STEEL_D}" stroke-width="0.8"/>'
    t += R(-19, -8, 38, 9, 4.5, "#3a3f4a", k=0.4) + "".join(E(x, -3.5, 2.6, 2.6, STEEL if x != 1 else FERRUGEM, k=0.15) for x in (-13, -6, 1, 8, 15))
    return t


def k14_cacamba(g, ang, pose):
    body = R(-8, -5, 14, 10, 3, "#4a505c", k=0.4) + R(2, -4, 10, 8, 2, STEEL, k=0.3)
    body += S("M8,-18 L34,-16 C39,-6 37,0 39,3 C37,8 36,12 32,15 L8,13 Z", FERRUGEM, (7, -19, 40, 16), k=0.6, dark=FERRUGEM_D)
    body += R(14, -8, 12, 10, 1, "#8f98a4", k=0.2) + f'<path d="M14,-8 h12 M14,2 h12" stroke="#ffb84a" stroke-width="0.8" stroke-dasharray="1 1"/>'
    for i, y in enumerate((-12, -4, 4)):
        body += P_([(32, y), (40 - i * 2, y + 2.5), (32, y + 5)], STEEL, k=0.2)
    g2 = (g[0] - math.cos(math.radians(ang)) * 6, g[1] - math.sin(math.radians(ang)) * 6)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


def k15_head(col, pose):
    """DEMOLIDORA: cabine na cor com GRADE DE PROTEÇÃO de aço sobre a tela, para-choque com faixa vermelha/preta."""
    h = ""
    if eu._Lb(pose):
        h += R(-16, -26, 34, 30, 8, col, k=0.7, dark=shade(col, -0.3)) + R(-16, -26, 34, 7, 4, shade(col, 0.2), k=0.3)
        h += R(-6, -20, 24, 12, 6, SCREEN, k=0.35)
    if eu._Lf(pose):
        h += eu.olhos_tela(pose.get("face", "foco"), 1.5, -14, 3.6, 9)
    if eu._Lb(pose):   # grade por cima da tela
        h += f'<rect x="-8" y="-22" width="28" height="16" rx="3" fill="none" stroke="#3a3f4a" stroke-width="2.4"/>'
        h += "".join(f'<path d="M{x},-22 v16" stroke="#3a3f4a" stroke-width="1.6"/>' for x in (-1, 6, 13))
        h += f'<path d="M-8,-14 h28" stroke="#3a3f4a" stroke-width="1.6"/>'
        h += R(8, -4, 18, 14, 3, "#2a2a30", k=0.4)
        h += "".join(f'<path d="M{x},10 L{x + 6},-4 L{x + 9},-4 L{x + 3},10 Z" fill="#d42035"/>' for x in (6, 13, 20))
    if eu._La(pose):
        h += R(-8, -34, 8, 8, 2, cb.MEC_D, k=0.2) + E(-4, -38, 3, 3, "#d42035", k=0.15)
    return h


def k15_torso(col, pose):
    t = R(-17, -26, 34, 22, 7, col, k=0.6, dark=shade(col, -0.3))
    t += R(-17, -22, 10, 14, 2, "#2a2a30", k=0.3) + R(7, -22, 10, 14, 2, "#2a2a30", k=0.3)                             # placas
    t += "".join(f'<circle cx="{x}" cy="{y}" r="1" fill="#8f98a4"/>' for x, y in ((-15, -20), (-9, -20), (-15, -10), (-9, -10), (9, -20), (15, -20), (9, -10), (15, -10)))
    t += R(-19, -8, 38, 9, 4.5, "#3a3f4a", k=0.4) + "".join(E(x, -3.5, 2.6, 2.6, "#d42035", k=0.15) for x in (-13, -6, 1, 8, 15))
    return t


def k15_pinca(g, ang, pose):
    """PINÇA de demolição (tesoura hidráulica): duas mandíbulas com dentes, vermelho e preto."""
    body = R(-8, -5, 14, 10, 3, "#4a505c", k=0.4) + R(2, -4, 10, 8, 2, STEEL, k=0.3)
    body += S("M8,-6 C20,-22 34,-22 42,-12 L36,-8 C30,-14 20,-12 14,-2 Z", "#d42035", (7, -23, 43, -1), k=0.5, dark="#8e1a28")
    body += S("M8,6 C20,22 34,22 42,12 L36,8 C30,14 20,12 14,2 Z", "#2a2a30", (7, 1, 43, 23), k=0.5)
    body += "".join(P_([(x, -10 + abs(x - 26) * 0.15), (x + 3, -5), (x + 6, -10 + abs(x - 26) * 0.15)], STEEL_L, k=0.1) for x in (18, 25, 32))
    body += "".join(P_([(x, 10 - abs(x - 26) * 0.15), (x + 3, 5), (x + 6, 10 - abs(x - 26) * 0.15)], STEEL_L, k=0.1) for x in (18, 25, 32))
    body += E(10, 0, 4, 4, STEEL_D, k=0.2)
    g2 = (g[0] - math.cos(math.radians(ang)) * 6, g[1] - math.sin(math.radians(ang)) * 6)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f})">{body}</g>', g, g2


ESCAVADEIRA = dict(nome="ESCAVADEIRA", escala=3.9, dx=-50, poses=eu.ESCAVA_P, padrao=_gen_padrao(eu.ESCAVA), skins=[
    ("K5", "OPERADOR Nº 01", ["santo-antônio com giroflex, lâmina e", "caçamba zebradas, placa 01"],
     _gen_skin(eu.ESCAVA, head=k5_head, torso=k5_torso, weapon=k5_cacamba, hand=mao("#f2c84b", 5.5), boot=bota("#3d434e", "#f2c84b", 1.4))),
    ("K14", "VELHO DE GUERRA", ["ferrugem, remendos rebitados, lâmina", "amassada, escapamento com fumaça preta"],
     _gen_skin(eu.ESCAVA, head=k14_head, torso=k14_torso, weapon=k14_cacamba, hand=mao("#8a5a2b", 5.5), boot=bota("#5a4a3a", FERRUGEM, 1.4))),
    ("K15", "DEMOLIDORA", ["grade de aço na tela, placas blindadas,", "pinça hidráulica de demolição"],
     _gen_skin(eu.ESCAVA, head=k15_head, torso=k15_torso, weapon=k15_pinca, hand=mao("#3a3f4a", 5.5), boot=bota("#2a2a30", "#d42035", 1.4))),
])

ROBOS = {"marretao": MARRETAO, "guindaste": GUINDASTE, "solda": SOLDA, "brita": BRITA, "escavadeira": ESCAVADEIRA}


# ---------------------------------------------------------------- prancha (uma por robô)
def _robo(fn, pose, col, x, y, s):
    return f'<g transform="translate({x},{y}) scale({s})"><ellipse cx="0" cy="2" rx="24" ry="5" fill="#2a1a2e" opacity="0.18"/>{fn(col, pose)}</g>'


def prancha(rid):
    import etapa_c as ec
    W, H = ec.W, ec.H
    rb = ROBOS[rid]
    sc = rb["escala"]
    b = [f'<rect width="{W}" height="{H}" fill="#bfe9ef"/>', f'<rect y="1000" width="{W}" height="80" fill="#cbbd9f"/>',
         f'<rect y="1000" width="{W}" height="8" fill="#e8dcc2"/>']
    b.append(ec.chunk(510, 20, 900, 92, "#f2c84b", 16, 6, 8) + ec.T(960, 84, f"{rb['nome']} · 3 SKINS", 50))
    cards = [("PADRÃO", "", ["o visual de hoje", ""], rb["padrao"])] + list(rb["skins"])
    for i, (sid, nome, desc, fn) in enumerate(cards):
        x = 28 + i * 472
        b.append(ec.chunk(x, 135, 448, 640, "#fbf4e4", 22, 5, 8))
        cor = INK if i == 0 else "#c4531a"
        b.append(ec.T(x + 24, 180, sid if i else "PADRÃO", 30, cor, "start"))
        if i:
            b.append(ec.T(x + 424, 180, nome, 26 if len(nome) < 16 else 22, INK, "end"))
        b.append(_robo(fn, rb["poses"]["parado"], COLORS[0], x + 214 + rb.get("dx", 0), 655, sc))
        b.append(ec.T(x + 224, 712, desc[0], 20, "#5a4a5e", w=600) + ec.T(x + 224, 740, desc[1], 20, "#5a4a5e", w=600))
        # embaixo: golpe em outra cor de jogador
        b.append(_robo(fn, rb["poses"]["golpe"], COLORS[i % 4], x + 150 + rb.get("dx", 0) * 0.4, 985, sc * 0.45))
        b.append(_robo(fn, rb["poses"]["parado"], COLORS[(i + 2) % 4], x + 320 + rb.get("dx", 0) * 0.4, 985, sc * 0.45))
    b.append(ec.T(960, 1052, "embaixo: golpe e parado em outras cores de jogador (tamanho perto do de jogo, ampliado 2×)", 22, INK))
    n = ec.notes(f"{rb['nome']} — 3 skins do Canteiro de Obras (proposta; mesma regra da K1 aprovada)", [
        ("APROVADO" if rid == "marretao" else "PROPOSTA", "K1 Mestre de Obras aprovado (2026-11-27)." if rid == "marretao" else "Fantasia completa: cabeça, tronco, mãos, botas e arma mudam de forma e material."),
        ("PROPOSTA", "Cor do jogador no capacete/cabine grande e nos braços e pernas (4 cores)."),
        ("PROPOSTA", "Mesma silhueta, hitbox e animações; zero efeito de jogo."),
        ("DECIDIR", "Aprovar, trocar alguma ou pedir ajuste por skin (diga o id: K6, K7...)."),
    ])
    return ec.page(f'<g>{"".join(b)}</g>', n)


def main():
    import etapa_c as ec
    os.makedirs(OUT, exist_ok=True)
    so = [a.split("=", 1)[1].split(",") for a in sys.argv if a.startswith("--so=")]
    ids = so[0] if so else list(ROBOS)
    tmp = tempfile.mkdtemp(prefix="skins_lote_")
    jobs = []
    for rid in ids:
        p = os.path.join(tmp, f"{rid}.svg")
        open(p, "w").write(prancha(rid))
        jobs.append({"svg": p, "png": os.path.join(OUT, f"lote_{rid}.png"), "w": ec.W, "h": ec.H + ec.NOTES_H, "scale": 1})
    jp = os.path.join(tmp, "jobs.json")
    json.dump(jobs, open(jp, "w"))
    subprocess.run(["node", os.path.join(ROOT, "tools/render_svg.js"), jp], check=True)
    for j in jobs:
        print(j["png"])


if __name__ == "__main__" and "--jogo" not in sys.argv:
    main()


# ---------------------------------------------------------------- exportação para o jogo (mesmo esqueleto do elenco.py)
# Cada skin troca, no CHARS do elenco.py, o desenho do tronco, da cabeça (base/rosto/acessório) e da ferramenta; o jogo
# carrega tronco_/cabeca_/corpo_<robô>_<k#>_p<cor>, rosto_<robô>_<k#>_<expressão>, antena_<robô>_<k#>,
# ferramenta_<robô>_<k#>, mao_<robô>_<k#> (luva) e pe_<robô>_<k#> (botina, sem tingir).
def _marr_ferr(fn):
    return lambda: fn((0, 0), 0, 1.0)[0]


def _gen_parts(spec, weapon_kw):
    def torso(c, e):
        out = spec["torso"](c, {})
        if spec.get("pre") is not None and spec is not None and spec.get("nome") == "SOLDA":
            out = spec["pre"](c, {"hip": (0, 0), "lean": 0}) + out
        return out

    def head(c, e, L="all"):
        import elenco as EL
        return spec["head"](c, {"L": L, "face": EL._UCH_FACE.get(e, e or "foco")})

    def tool():
        return spec["weapon"]((0, 0), 0, dict(weapon_kw))[0]
    return torso, head, tool


def _glove_svg(cor):
    return E(34, 32, 22, 21, cor, k=1.4, dark=shade(cor, -0.3))


def _boot_svg(cor, sola, faixa=None):
    o = S("M10,44 C8,18 30,10 52,12 C70,13 86,24 88,44 Z", cor, (6, 9, 90, 46), k=1.6, dark=shade(cor, -0.3))
    if faixa:
        o += R(22, 26, 52, 7, 3, faixa, k=0.8)
    return o + R(6, 40, 84, 10, 4, sola, k=1.0)


# (id, robô no jogo, fonte da skin, cor da luva, (botina, sola, faixa))
EXPORT = [
    ("k1", "marretao", ("marr", k1m.k1_tronco, k1m.k1_cabeca_L, k1m.k1_marreta), k1m.COURO, (k1m.BOTA, k1m.BOTA_D, None)),
    ("k6", "marretao", ("marr", k6_tronco, k6_cabeca_L, k6_marreta), "#2f2f36", ("#2b2b31", YEL, "#f2e04b")),
    ("k7", "marretao", ("marr", k7_tronco, k7_cabeca_L, k7_marreta), "#f2c84b", ("#5a4a3a", "#2a2a30", None)),
    ("k2", "picareta", ("gen", dict(eu.GUINDA, head=k2_head, torso=k2_torso, weapon=k2_lanca), {"chain_L": 14}), "#f4f1ea", ("#7a4a28", "#3a2a20", None)),
    ("k8", "picareta", ("gen", dict(eu.GUINDA, head=k8_head, torso=k8_torso, weapon=k8_lanca), {"chain_L": 14}), "#8f98a4", ("#3d434e", "#d42035", None)),
    ("k9", "picareta", ("gen", dict(eu.GUINDA, head=k9_head, torso=k9_torso, weapon=k9_lanca), {"chain_L": 14}), "#f4f1ea", ("#f4f1ea", "#4f86d9", None)),
    ("k3", "chave", ("gen", dict(eu.SOLDA, head=k3_head, torso=k3_torso, pre=k3_tanques, weapon=k3_chave), {}), "#8a5a2b", ("#4a2d18", "#2a2a30", None)),
    ("k10", "chave", ("gen", dict(eu.SOLDA, head=k10_head, torso=k10_torso, pre=k10_bobina, weapon=k10_alicate), {}), "#f08a2b", ("#2b2b31", "#f2c84b", None)),
    ("k11", "chave", ("gen", dict(eu.SOLDA, head=k11_head, torso=k11_torso, pre=k11_tanque, weapon=k11_chave), {}), "#6e5f48", ("#4a4f5c", "#2a2a30", None)),
    ("k4", "britadeira", ("gen", dict(eu.BRITA, head=k4_head, torso=k4_torso, weapon=k4_britadeira), {}), "#8f887c", ("#f4f1ea", "#b9b2a6", None)),
    ("k12", "britadeira", ("gen", dict(eu.BRITA, head=k12_head, torso=k12_torso, weapon=k12_sapo), {}), "#2a2a30", ("#2a2a30", "#f27a1f", None)),
    ("k13", "britadeira", ("gen", dict(eu.BRITA, head=k13_head, torso=k13_torso, weapon=k13_perfuratriz), {}), "#8a5a2b", ("#2b2b31", "#5a3d2b", None)),
    ("k5", "pa", ("gen", dict(eu.ESCAVA, head=k5_head, torso=k5_torso, weapon=k5_cacamba), {}), "#f2c84b", ("#3d434e", "#f2c84b", None)),
    ("k14", "pa", ("gen", dict(eu.ESCAVA, head=k14_head, torso=k14_torso, weapon=k14_cacamba), {}), "#8a5a2b", ("#5a4a3a", FERRUGEM, None)),
    ("k15", "pa", ("gen", dict(eu.ESCAVA, head=k15_head, torso=k15_torso, weapon=k15_pinca), {}), "#3a3f4a", ("#2a2a30", "#d42035", None)),
]
EXPORT_NOMES = {"k1": "Mestre de Obras", "k6": "Brigadista", "k7": "Sucateiro", "k2": "Topógrafo", "k8": "Grua Clássica", "k9": "Pintor",
                "k3": "Soldador Caprichado", "k10": "Eletricista", "k11": "Mergulhador de Poço", "k4": "Concreteiro", "k12": "Asfaltador",
                "k13": "Mineiro", "k5": "Operador nº 01", "k14": "Velho de Guerra", "k15": "Demolidora"}


def exportar_jogo(so=None):
    import elenco as EL
    from svg import queue, render_all
    out_dir = os.path.join(ROOT, "art/out/game/robo")
    src = os.path.join(ROOT, "art/src/robos/svg/skins")
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(src, exist_ok=True)
    for kid, cid, fonte, luva, (bota_c, sola, faixa) in EXPORT:
        if so and kid not in so:
            continue
        ch = EL.CHARS[cid]
        velho = {k: ch[k] for k in ("torso", "head", "tool")}
        if fonte[0] == "marr":
            _, tro, cab, mar = fonte
            ch["torso"] = lambda c, e, tro=tro: tro(c, {})
            ch["head"] = lambda c, e, L="all", cab=cab: cab(c, e, L)
            ch["tool"] = _marr_ferr(mar)
        else:
            spec = dict(fonte[1])
            ch["torso"], ch["head"], ch["tool"] = _gen_parts(spec, fonte[2])
        seed = 40 + list(EL.CHARS).index(cid) * 3
        nm = f"{cid}_{kid}"
        for ci in range(4):
            col = EL.COLORS[ci]
            tor = f'<g transform="{EL._xf(cid)}">{ch["torso"](col, "")}</g>'
            cab = f'<g transform="{EL._head_xf(cid)}">{ch["head"](col, "", "base")}</g>'
            queue(EL._gwrap(tor + cab, seed), f"{src}/corpo_{nm}_p{ci + 1}.svg", f"{out_dir}/corpo_{nm}_p{ci + 1}.png", 128, 128, EL.K4)
            queue(EL._gwrap(tor, seed), f"{src}/tronco_{nm}_p{ci + 1}.svg", f"{out_dir}/tronco_{nm}_p{ci + 1}.png", 128, 128, EL.K4)
            queue(EL._gwrap(cab, seed), f"{src}/cabeca_{nm}_p{ci + 1}.svg", f"{out_dir}/cabeca_{nm}_p{ci + 1}.png", 128, 128, EL.K4)
        for e in EL.GAME_EXPR:
            face = f'<g transform="{EL._head_xf(cid)}">{ch["head"](EL.COLORS[0], e, "face")}</g>'
            queue(EL._gwrap(face, seed + 1), f"{src}/rosto_{nm}_{e}.svg", f"{out_dir}/rosto_{nm}_{e}.png", 128, 128, EL.K4)
        acc = f'<g transform="{EL._head_xf(cid)}">{ch["head"](EL.COLORS[0], "", "acc")}</g>'
        queue(EL._gwrap(acc, seed + 2), f"{src}/antena_{nm}.svg", f"{out_dir}/antena_{nm}.png", 128, 128, EL.K4)
        tbody, tsize, _, _, _ = EL._tool_export(cid)
        queue(EL._gwrap(tbody, seed + 7, tsize[0], tsize[1]), f"{src}/ferramenta_{nm}.svg", f"{out_dir}/ferramenta_{nm}.png", tsize[0], tsize[1], EL.K4)
        queue(EL._gwrap(_glove_svg(luva), seed + 9, 64, 64), f"{src}/mao_{nm}.svg", f"{out_dir}/mao_{nm}.png", 64, 64, 1)
        queue(EL._gwrap(_boot_svg(bota_c, sola, faixa), seed + 10, 96, 56), f"{src}/pe_{nm}.svg", f"{out_dir}/pe_{nm}.png", 96, 56, 1)
        ch.update(velho)
    print("skins:", render_all())


if __name__ == "__main__" and "--jogo" in sys.argv:
    exportar_jogo([a.split("=", 1)[1] for a in sys.argv if a.startswith("--skins=")][0].split(",") if any(a.startswith("--skins=") for a in sys.argv) else None)
