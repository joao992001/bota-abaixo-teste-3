"""SKINS v2 (2026-11-27): skins no estilo ATUAL do elenco (robo_uch / elenco_uch). Skin = FANTASIA COMPLETA, não troca de
cor: figurino novo no tronco, acessórios grandes na cabeça, luvas/botas/joelheiras próprias e a FERRAMENTA com acabamento
temático. A cor do jogador fica no CAPACETE (o maior volume) e nos braços e pernas (regra aprovada em 2026-11-25).
Mesma silhueta e hitbox; nenhum efeito de jogo. Origem: mapa Canteiro de Obras.
Amostra para crítica do usuário: K1 · Marretão · MESTRE DE OBRAS.
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/skins_v2.py → art/out/skins_v2/k1_mestre_de_obras.png
"""
import json
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
import robo_uch as ru  # noqa: E402
from elenco import COLORS  # noqa: E402
from svg import shade  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/skins_v2")

# ---------------------------------------------------------------- K1 · MARRETÃO · MESTRE DE OBRAS
VEST, VEST_D = "#f2741f", "#c4531a"          # colete laranja de alta visibilidade
REFL, REFL_D = "#e9eef2", "#aab4bd"          # faixa refletiva
CASCO, CASCO_D = "#eee2c6", "#c9b894"        # casco creme da cabeça (pintura de fábrica)
COURO, COURO_D = "#b0753d", "#7a4a22"        # luvas e cinto de couro
BOTA, BOTA_D = "#6e4526", "#4a2d18"          # botina de couro com biqueira de aço
ABAF = "#3f4552"                             # abafador de ouvido (grafite: não some na marreta vermelha)
LAPIS = "#f2c84b"


def k1_cabeca(col, pose):
    return k1_cabeca_L(col, pose.get("face", "foco"), "all", pose)


def k1_cabeca_L(col, e, L="all", pose=None):
    """Casco creme com tela e BIGODE; abafador grafite com lápis atrás da orelha; capacete de aba total na cor do
    jogador com faixa refletiva e lanterna de testa."""
    pose = pose or {}
    face = {"normal": "foco", "esforco": "raiva", "ataque": "raiva", "forca": "raiva", "grito": "raiva", "esquiva": "susto"}.get(e, e or "foco")
    o = ""
    if L in ("all", "base"):
        o += cb.R(-20, -21, 42, 38, 12, CASCO, k=0.7) + cb.R(-20, 8, 42, 9, 6, CASCO_D, k=0.3)           # casco + sombra de baixo
        o += cb.R(-6, -12, 27, 22, 7, ru.SCREEN, k=0.35)                                                  # tela
        # bigodão de mestre de obras (pintado na tela, abaixo dos olhos)
        o += cb.S("M0,8 C2,4 7,4 9.5,6.5 C12,4 17,4 19,8 C16,11 12,10 9.5,8.5 C7,10 3,11 0,8 Z", "#d9d2c4", (-1, 3, 20, 12), k=0.3)
        # abafador de ouvido (concha vermelha) com a haste por cima
        o += cb.R(-25, -8, 10, 18, 5, ABAF, k=0.4) + cb.R(-25, -8, 10, 5, 3, shade(ABAF, 0.25), k=0.25)
        o += f'<path d="M-20,-8 C-21,-16 -19,-20 -16,-22" stroke="#3a3f4a" stroke-width="3" fill="none" stroke-linecap="round"/>'
        # lápis atrás da orelha
        o += f'<g transform="translate(-24,-12) rotate(-75)">' + cb.R(-6, -1.6, 12, 3.2, 1.2, LAPIS, k=0.25) + \
             cb.P([(6, -1.6), (9.5, 0), (6, 1.6)], "#e8c9a0", k=0.15) + "</g>"
        # capacete de ABA TOTAL (cor do jogador), maior que o padrão
        o += cb.S("M-20,-19 C-21,-41 23,-41 23,-19 Z", col, (-22, -42, 24, -18), k=0.5, dark=shade(col, -0.3))
        o += cb.R(-27, -22, 56, 6, 3, shade(col, -0.22), k=0.3)                                           # aba larga
        o += cb.S("M-19,-27 C-18,-31 22,-31 22,-27 L22,-23 L-19,-23 Z", REFL, (-20, -32, 23, -22), k=0.3)  # faixa refletiva
        o += f'<path d="M-15,-25.5 h34" stroke="{REFL_D}" stroke-width="0.8" stroke-dasharray="3 2"/>'
        o += f'<path d="M1,-39 v10" stroke="{shade(col, -0.3)}" stroke-width="3"/>'                         # nervura
        # lanterna de testa
        o += cb.R(14, -36, 10, 9, 3, "#3a3f4a", k=0.3) + cb.E(23, -31.5, 2.6, 3.6, "#fff6c8", k=0.2)
    if L in ("all", "face"):
        if face == "piscar":
            o += '<path d="M-3,-2 h8 M8,-2 h8" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round"/>'
        else:
            o += ru.olhos(face, 0)
    if L in ("all", "acc"):   # facho da lanterna (no lugar do giroflex)
        o += '<path d="M25,-31.5 L52,-42 L52,-20 Z" fill="#fff3b0" opacity="0.35"/>'
    return o


def k1_tronco(col, pose):
    """Colete laranja refletivo cobrindo o tronco todo, bolso com lápis e rádio, cinto de couro com trena e bolsinha."""
    t = cb.S("M-11,0 C-14,-6 -12,-18 0,-19 C12,-18 14,-6 11,0 Z", VEST, (-15, -20, 15, 1), k=0.6, dark=VEST_D)
    t += f'<path d="M1,-18 L1,-3" stroke="{VEST_D}" stroke-width="1.2"/>'                                # zíper
    for y in (-13.5, -8.5):                                                                          # faixas refletivas
        t += cb.R(-12.5, y, 25, 3, 1, REFL, k=0.25) + f'<path d="M-11,{y + 1.5} h22" stroke="{REFL_D}" stroke-width="0.6" stroke-dasharray="2 1.5"/>'
    t += cb.R(3, -17, 7, 6, 1.5, VEST_D, k=0.25)                                                       # bolso
    t += cb.R(4.5, -21, 1.6, 6, 0.6, LAPIS, k=0.2)                                                     # lápis no bolso
    t += cb.R(-9, -19, 5, 7, 1.5, "#3a3f4a", k=0.25) + f'<path d="M-8,-19 v-6" stroke="#3a3f4a" stroke-width="1.2"/>'  # rádio
    t += f'<circle cx="-8" cy="-25.3" r="1" fill="#e84a3a"/>'
    t += cb.R(-12, -4, 24, 4.5, 1.5, COURO_D, k=0.3) + cb.R(-1.5, -4.3, 5, 5, 1, "#c9d1d8", k=0.2)      # cinto + fivela
    t += cb.E(-9.5, -0.5, 4, 4, LAPIS, k=0.25) + f'<circle cx="-9.5" cy="-0.5" r="1.4" fill="#3a3f4a"/>'  # trena
    t += cb.R(6, -2, 6, 6, 1.5, COURO, k=0.25)                                                         # bolsinha
    return t


def k1_marreta(g, ang, s=0.72):
    """Marreta do mestre: cabeça vermelha descascada com faces de aço, cabo de madeira com fita isolante amarela/preta
    e um nível de bolha preso com abraçadeira."""
    import math
    cabo = cb.R(-24, -3, 62, 6, 2.5, cb.WOOD, k=0.5, dark=cb.WOOD_D)
    cabo += cb.R(-24, -4, 18, 8, 3, "#2f2f36", k=0.4)                                                 # fita isolante
    cabo += "".join(f'<path d="M{-22 + i * 4},-4 l2,8" stroke="{LAPIS}" stroke-width="1.6"/>' for i in range(5))
    cabo += cb.R(8, -6, 20, 5, 1.5, "#4ac0a8", k=0.3) + cb.E(18, -3.5, 3, 1.4, "#d8fff4", k=0.15)        # nível de bolha
    cabo += cb.R(11, -6.5, 2, 9, 0.8, "#c9d1d8", k=0.15) + cb.R(23, -6.5, 2, 9, 0.8, "#c9d1d8", k=0.15)
    cab = cb.R(40, -17, 30, 34, 3, "#c8402f", k=0.6, dark="#8e2a20")                                   # cabeça vermelha
    cab += cb.R(40, -17, 30, 6, 2, "#e0634e", k=0.35)
    cab += cb.R(67, -19, 7, 38, 2.5, cb.STEEL, k=0.45, dark=cb.STEEL_D) + cb.R(36, -18, 6, 36, 2, cb.STEEL_D, k=0.4)
    cab += f'<path d="M46,-9 l5,2 l-2,4 Z M58,6 l6,1 l-3,5 Z M52,12 l3,-1 l1,3 Z" fill="#9aa4ae" opacity="0.85"/>'  # tinta descascada
    body = cabo + cab
    g2 = (g[0] - math.cos(math.radians(ang)) * 11, g[1] - math.sin(math.radians(ang)) * 11)
    return f'<g transform="translate({g[0]:.1f},{g[1]:.1f}) rotate({ang:.1f}) scale({s})">{body}</g>', g, g2


_tubo0 = ab.tubo


def _tubo_k1(p, k, q, w0, w1, fill):
    out = _tubo0(p, k, q, w0, w1, fill)
    if w0 >= 6.4:   # perna: joelheira de obra
        out += cb.R(k[0] - 3.5, k[1] - 4, 8, 8, 2.5, "#3a3f4a", k=0.25) + cb.R(k[0] - 2.5, k[1] - 3, 6, 2.2, 1, "#5d6470", k=0.15)
    return out


class Skin:
    """Troca as peças do robo_uch pelas da skin enquanto desenha (o resto do esqueleto é o mesmo)."""
    def __init__(self, cab, tro, mar, glove, glove_d, boot, sola, tubo):
        self.p = dict(cabeca=cab, tronco=tro, marreta=mar, GLOVE=glove, GLOVE_D=glove_d, BOOT=boot, SOLA=sola)
        self.tubo = tubo

    def __enter__(self):
        self.old = {k: getattr(ru, k) for k in self.p}
        for k, v in self.p.items():
            setattr(ru, k, v)
        ab.tubo = self.tubo
        return self

    def __exit__(self, *a):
        for k, v in self.old.items():
            setattr(ru, k, v)
        ab.tubo = _tubo0


def k1():
    return Skin(k1_cabeca, k1_tronco, k1_marreta, COURO, COURO_D, BOTA, BOTA_D, _tubo_k1)


# ---------------------------------------------------------------- prancha
def robo(pose, col, x, y, s, skin=None):
    if skin:
        with skin:
            body = ru.desenha(pose, col)
    else:
        body = ru.desenha(pose, col)
    sh = f'<ellipse cx="0" cy="2" rx="26" ry="5" fill="#2a1a2e" opacity="0.18"/>'
    return f'<g transform="translate({x},{y}) scale({s})">{sh}{body}</g>'


def prancha():
    import etapa_c as ec
    W, H = ec.W, ec.H
    INK, CREAM = ec.INK, "#fbf4e4"
    parado = ru.PARADO
    correr = ru.A_correr()[2][1][1]
    pesado = ru.A_pesado()[2][3][1]
    pulo = ru.A_pulo()[2][3][1]
    b = [f'<rect width="{W}" height="{H}" fill="#bfe9ef"/>', f'<rect y="1000" width="{W}" height="80" fill="#cbbd9f"/>',
         f'<rect y="1000" width="{W}" height="8" fill="#e8dcc2"/>']
    b.append(ec.chunk(560, 24, 800, 92, "#f2c84b", 16, 6, 8) + ec.T(960, 88, "SKIN · MESTRE DE OBRAS", 50))
    # padrão × skin, grandes e lado a lado (mesma pose, mesma cor)
    for i, (nome, sk) in enumerate((("PADRÃO", None), ("SKIN K1", k1()))):
        x = 60 + i * 560
        b.append(ec.chunk(x, 140, 520, 640, CREAM, 22, 5, 8))
        b.append(ec.T(x + 30, 190, nome, 34, INK if sk is None else "#c4531a", "start"))
        b.append(robo(parado, COLORS[0], x + 270, 750, 5.4, sk))
    # o que muda (chamadas)
    b.append(ec.chunk(1200, 140, 680, 640, CREAM, 22, 5, 8))
    b.append(ec.T(1540, 190, "O QUE MUDA (não é só cor)", 32))
    itens = [("CAPACETE de aba total", "cor do jogador, faixa refletiva, lanterna de testa"),
             ("CABEÇA creme com BIGODÃO", "abafador de ouvido e lápis atrás da orelha"),
             ("COLETE laranja refletivo", "cobre o tronco: bolso, lápis, rádio no peito"),
             ("CINTO de couro", "trena e bolsinha de ferramentas"),
             ("LUVAS e BOTINAS de couro", "joelheiras de obra; sola de borracha"),
             ("MARRETA do mestre", "cabeça vermelha descascada, fita isolante, nível de bolha")]
    for k, (t1, t2) in enumerate(itens):
        y = 250 + k * 90
        b.append(f'<circle cx="1250" cy="{y}" r="24" fill="#c4531a"/>' + ec.T(1250, y + 10, str(k + 1), 28, "#ffffff"))
        b.append(ec.T(1290, y + 2, t1, 27, INK, "start") + ec.T(1290, y + 34, t2, 21, "#5a4a5e", "start", w=600))
    # faixa de baixo: 4 cores e 3 poses (tamanho maior que o de jogo, para ler)
    for k in range(4):
        b.append(robo(parado, COLORS[k], 130 + k * 160, 1000, 2.2, k1()))
    for k, (pz, nm) in enumerate(((correr, "correr"), (pesado, "golpe pesado"), (pulo, "pulo"))):
        x = 1020 + k * 300
        b.append(robo(pz, COLORS[0], x, 1000 if nm != "pulo" else 960, 2.2, k1()))
        b.append(ec.T(x, 1056, nm, 22, INK))
    b.append(ec.T(370, 1056, "as 4 cores de jogador", 22, INK))
    n = ec.notes("SKIN K1 · Marretão · MESTRE DE OBRAS — amostra para crítica (origem: Canteiro de Obras)", [
        ("PROPOSTA", "Fantasia completa: cabeça, tronco, luvas, botas e marreta mudam de forma e material."),
        ("PROPOSTA", "Cor do jogador no capacete grande + braços e pernas; legível nas 4 cores."),
        ("PROPOSTA", "Mesma silhueta e hitbox; zero efeito de jogo; usa as mesmas animações."),
        ("DECIDIR", "Se a direção agradar: 3 skins por robô (15), cada uma com um tema próprio."),
    ])
    return ec.page(f'<g>{"".join(b)}</g>', n)


def main():
    import etapa_c as ec
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="skins_v2_")
    p = os.path.join(tmp, "k1.svg")
    open(p, "w").write(prancha())
    png = os.path.join(OUT, "k1_mestre_de_obras.png")
    jp = os.path.join(tmp, "jobs.json")
    json.dump([{"svg": p, "png": png, "w": ec.W, "h": ec.H + ec.NOTES_H, "scale": 1}], open(jp, "w"))
    subprocess.run(["node", os.path.join(ROOT, "tools/render_svg.js"), jp], check=True)
    print(png)


if __name__ == "__main__":
    main()
