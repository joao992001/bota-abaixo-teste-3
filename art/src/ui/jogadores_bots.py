"""PRANCHA — BOTS na tela QUEM VAI JOGAR? (pedido 2026-11-28): editar dificuldade, robô, visual e cor do bot e
tirar UM bot, tudo pelo controle. Rodar: NODE_PATH=$(npm root -g) python3 art/src/ui/jogadores_bots.py
"""
import base64
import os
import sys

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "../robos"))
import controles_arte as ca  # noqa: E402
import elenco_uch as eu  # noqa: E402
import etapa_c as ec  # noqa: E402
from etapa_c import T, title, chunk, INK, CREAM  # noqa: E402
from svg import queue, render_all  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "../../.."))
OUT = os.path.join(ROOT, "art/out/ui")
COR = ["#4f86d9", "#5cc45c", "#f06aa8", "#f2c84b"]
SOFT = "#6b5a70"
NOMES = [e[0].capitalize() for e in eu.ELENCO]


def robo(x, y, model, col, s=2.4):
    return f'<g transform="translate({x},{y}) scale({s})">{eu.desenha(model, col, "parado")}</g>'


def capacetes(x, y, n, total=3, s=1.0):
    o = ""
    for k in range(total):
        cx = x + (k - (total - 1) / 2) * 34 * s
        cor = "#f2c84b" if k < n else "#d8d0c4"
        o += (f'<path d="M{cx - 14 * s},{y} a{14 * s},{13 * s} 0 0 1 {28 * s},0 h{4 * s} v{5 * s} h{-36 * s} v{-5 * s} Z" '
              f'fill="{cor}" stroke="{INK}" stroke-width="{3 * s}" stroke-linejoin="round"/>')
    return o


def cartao(x, y, i, rot, conteudo, fill=CREAM, w=400, h=600, borda=None, tag=None):
    o = f'<g transform="rotate({rot} {x + w / 2} {y + h / 2})">'
    if borda:
        o += f'<rect x="{x - 12}" y="{y - 12}" width="{w + 24}" height="{h + 24}" rx="36" fill="{borda}"/>'
    o += chunk(x, y, w, h, fill, 28, 6, 10) + conteudo
    if tag:
        o += chunk(x + w / 2 - 120, y - 34, 240, 52, tag[1], 18, 5, 5) + T(x + w / 2, y + 2, tag[0], 26, "#ffffff", extra=f'stroke="{INK}" stroke-width="6" paint-order="stroke"')
    return o + "</g>"


def humano(x, y, i, model, rot, edita_bots=False):
    c = T(x + 200, y + 86, f"P{i + 1}", 76, COR[i], extra=f'stroke="{INK}" stroke-width="14" paint-order="stroke"')
    c += T(x + 200, y + 126, "controle 1 · DualSense" if i == 0 else "teclado A", 22, SOFT)
    c += f'<circle cx="{x + 200}" cy="{y + 300}" r="140" fill="#ffe48a"/>' + robo(x + 200, y + 420, model, COR[i])
    c += T(x + 200, y + 500, NOMES[model], 42, INK)
    c += chunk(x + 30, y + 520, 340, 56, COR[i], 20, 5, 0) + T(x + 200, y + 558, "◄ cor ►   ▲▼ robô", 27, INK)
    if edita_bots:
        c += chunk(x + 70, y + 150, 260, 44, "#ffffff", 14, 4, 0) + ca.glifo(x + 104, y + 172, "ps5", "rb", 15) + T(x + 222, y + 181, "editar bots", 22, INK)
    return cartao(x, y, i, rot, c)


def bot_parado(x, y, i, model, rot, nivel):
    c = T(x + 200, y + 86, f"P{i + 1}", 76, COR[i], extra=f'stroke="{INK}" stroke-width="14" paint-order="stroke"')
    c += T(x + 200, y + 126, "BOT", 26, SOFT)
    c += capacetes(x + 200, y + 170, nivel + 1) + T(x + 200, y + 202, ["FÁCIL", "MÉDIO", "DIFÍCIL"][nivel], 22, INK)
    c += f'<circle cx="{x + 200}" cy="{y + 330}" r="120" fill="#e8e2d6"/>' + robo(x + 200, y + 430, model, COR[i], 2.1)
    c += T(x + 200, y + 500, NOMES[model], 40, INK)
    c += chunk(x + 30, y + 520, 340, 56, "#ffffff", 20, 5, 0) + T(x + 200, y + 557, "um jogador aperta R1 / RB", 22, SOFT)
    return cartao(x, y, i, rot, c)


def bot_editando(x, y, i, model, rot, quem, sel=3):
    c = T(x + 200, y + 74, f"P{i + 1} · BOT", 52, COR[i], extra=f'stroke="{INK}" stroke-width="11" paint-order="stroke"')
    c += f'<circle cx="{x + 200}" cy="{y + 190}" r="86" fill="#ffe48a"/>' + robo(x + 200, y + 262, model, COR[i], 1.55)
    linhas = [("ROBÔ", NOMES[model]), ("VISUAL", "✦ Asfalto"), ("COR", None), ("DIFICULDADE", "nivel"), ("TIRAR BOT", "botao")]
    for k, (nm, val) in enumerate(linhas):
        yy = y + 300 + k * 56
        on = k == sel
        if val == "botao":
            c += chunk(x + 40, yy + 4, 320, 48, "#e5484d" if on else "#f3c9c9", 14, 4, 4) + T(x + 200, yy + 38, "✖  TIRAR BOT", 24, "#ffffff" if on else "#a01528",
                                                                                                extra=f'stroke="{INK}" stroke-width="5" paint-order="stroke"' if on else "")
            continue
        if on:
            c += f'<rect x="{x + 24}" y="{yy}" width="352" height="54" rx="14" fill="#f2c84b" stroke="{INK}" stroke-width="4"/>'
        c += T(x + 40, yy + 34, nm, 20, SOFT, "start")
        c += T(x + 232, yy + 35, "◄", 22, INK) + T(x + 360, yy + 35, "►", 22, INK)
        if val == "nivel":
            c += capacetes(x + 296, yy + 26, 2, s=0.5)
            c += T(x + 296, yy + 48, "MÉDIO", 16, INK)
        elif val is None:
            c += f'<circle cx="{x + 296}" cy="{yy + 27}" r="14" fill="{COR[i]}" stroke="{INK}" stroke-width="4"/>'
        else:
            c += T(x + 296, yy + 35, val, 20, INK)
    return cartao(x, y, i, rot, c, borda=COR[quem], tag=(f"P{quem + 1} EDITANDO", COR[quem]))


def vazio(x, y, i, rot):
    c = T(x + 200, y + 280, f"P{i + 1}", 84, "#f2c84b", extra=f'stroke="{INK}" stroke-width="16" paint-order="stroke"')
    c += ca.glifo(x + 120, y + 360, "ps5", "baixo", 22) + T(x + 230, y + 371, "entrar", 34, INK)
    c += ca.glifo(x + 120, y + 430, "ps5", "cima", 20) + T(x + 230, y + 440, "+ bot", 30, INK)
    return cartao(x, y, i, rot, c, fill="#e9e3d6")


def legenda(x, y):
    o = chunk(x, y, 1840, 430, CREAM, 30, 6, 10)
    o += title(x + 920, y + 66, "COMO MEXE NOS BOTS (qualquer jogador de verdade, pelo controle ou teclado)", 36)
    itens = [
        [("cima", "no SEU cartão: + bot (vai para a próxima vaga)")],
        [("rb", "passa a editar o próximo bot · aperte de novo para o seguinte / voltar para você")],
        [(None, "▲▼"), (None, "editando o bot: escolhe a linha  ·  ◄► muda (robô, visual do mapa, cor, dificuldade)")],
        [("baixo", "em TIRAR BOT: o bot sai e a vaga abre  ·  "), ("dir", "volta para o seu cartão")],
    ]
    for k, linha in enumerate(itens):
        yy = y + 130 + k * 66
        xx = x + 60
        for g, txt in linha:
            if g:
                o += ca.glifo(xx + 24, yy, "ps5", g, 22)
                xx += 64
            else:
                o += T(xx + 22, yy + 11, txt if txt == "▲▼" else "", 30, INK)
                if txt == "▲▼":
                    xx += 64
                    continue
            if txt != "▲▼":
                o += T(xx, yy + 10, txt, 26, INK, "start")
                xx += len(txt) * 12.6 + 20
    o += T(x + 920, y + 400, "Sai: “mesa cheia + Y tira TODOS os bots” (confuso) e o B do bot não fazia nada · o bot novo nasce com a dificuldade de OPÇÕES ▸ BOTS", 21, SOFT, w=600)
    return o


def prancha():
    W, H = 1920, 1300
    b = [f'<rect width="{W}" height="{H}" fill="#9fe2ec"/>', ca.defs(), title(W / 2, 80, "QUEM VAI JOGAR? — BOTS QUE VOCÊ CONTROLA", 56)]
    x0 = (W - (4 * 400 + 3 * 36)) / 2
    b.append(humano(x0, 170, 0, 1, -1.5, edita_bots=True))
    b.append(humano(x0 + 436, 170, 1, 3, 1.2))
    b.append(bot_editando(x0 + 872, 170, 2, 2, -1.0, 0))
    b.append(bot_parado(x0 + 1308, 170, 3, 4, 1.5, 2))
    b.append(legenda(40, 830))
    f7 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-700.woff2"), "rb").read()).decode()
    f6 = base64.b64encode(open(os.path.join(ec.A, "fonts/fredoka-600.woff2"), "rb").read()).decode()
    style = ("<style>@font-face{font-family:Fredoka;font-weight:700;src:url(data:font/woff2;base64," + f7 + ")}"
             "@font-face{font-family:Fredoka;font-weight:600;src:url(data:font/woff2;base64," + f6 + ")}</style>")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{style}{"".join(b)}</svg>'
    queue(svg, os.path.join(HERE, "svg/jogadores_bots.svg"), os.path.join(OUT, "jogadores_bots.png"), W, H, 1)
    print(render_all(), os.path.join(OUT, "jogadores_bots.png"))


if __name__ == "__main__":
    prancha()
