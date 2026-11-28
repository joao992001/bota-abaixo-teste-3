"""VÍDEOS DAS ARMADURAS-MECHA (A29/A30, pedido 2026-11-27: "o mais animado possível"): para cada armadura, a
TRANSFORMAÇÃO estilo Transformers (peças voam e encaixam em volta do robô, o piloto entra no cockpit, o olho acende,
onda de choque) e depois a HABILIDADE com muito efeito (partículas de fogo, rastro e destroços no dash, rolamento com
faíscas, arco elétrico em cadeia, agarrão e arremesso).
Rodar: NODE_PATH=$(npm root -g) python3 art/src/robos/armaduras_video.py [fornalha broca bola empilhadeira raio]
→ art/out/robos_v2/armadura_<nome>.mp4 e armaduras_todas.mp4
"""
import math
import os
import random
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import armaduras_conceito as ac  # noqa: E402
import armaduras_habilidades as ah  # noqa: E402
from armaduras_conceito import R, E, P_, DARK, STEEL, STEEL_D, STEEL_L, ab, eu, label, INK, queue, render_all  # noqa: E402

W, H = 1280, 720
GROUND = 610
SC = 1.6
FPS = 30
T_TRANS = 1.6
COL = "#4f86d9"


# ================================================================ utilidades de tempo e partículas
def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def seg(t, t0, t1):
    return clamp((t - t0) / max(t1 - t0, 1e-6))


def ease_out(u):
    return 1 - (1 - u) ** 3


def ease_back(u, s=2.2):
    u -= 1
    return u * u * ((s + 1) * u + s) + 1


def lerp(a, b, u):
    return a + (b - a) * u


def mix(c1, c2, u):
    a = [int(c1[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(c2[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{int(lerp(x, y, clamp(u))):02x}" for x, y in zip(a, b))


def grad_fogo(u):
    """Cor da partícula de fogo pela idade: branco-amarelo → laranja → vermelho → fumaça."""
    pal = [(0.0, "#fffbe0"), (0.15, "#ffe35a"), (0.38, "#ff9a1f"), (0.62, "#e8401a"), (0.8, "#6b4a44"), (1.0, "#8a8a90")]
    for (u0, c0), (u1, c1) in zip(pal, pal[1:]):
        if u <= u1:
            return mix(c0, c1, (u - u0) / (u1 - u0))
    return pal[-1][1]


def particulas(t, t0, t1, taxa, vida, emissor, seed=1):
    """Gera (idade_u, x, y, rnd) de partículas nascidas entre t0 e t1 (taxa por s) e vivas em t. emissor(tb, rnd) → (x, y, vx, vy, g)."""
    out = []
    n = int((t1 - t0) * taxa)
    for i in range(n):
        tb = t0 + i / taxa
        if tb > t:
            break
        age = t - tb
        rnd = random.Random(seed * 100003 + i)
        lv = vida * rnd.uniform(0.75, 1.2)
        if age > lv:
            continue
        x, y, vx, vy, g = emissor(tb, rnd)
        out.append((age / lv, x + vx * age, y + vy * age + 0.5 * g * age * age, rnd))
    return out


def tremor(t, t0, dur, amp):
    u = seg(t, t0, t0 + dur)
    if u <= 0 or u >= 1:
        return 0.0, 0.0
    a = amp * (1 - u)
    return math.sin(t * 97) * a, math.cos(t * 71) * a * 0.7


def estrela(x, y, r, op=1.0, col="#fff6c2"):
    pts = []
    for k in range(16):
        rr = r if k % 2 == 0 else r * 0.42
        a = k * math.pi / 8
        pts.append(f"{x + math.cos(a) * rr:.1f},{y + math.sin(a) * rr:.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{col}" opacity="{op:.2f}"/>'


def anel(x, y, r, w, col, op):
    return f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="none" stroke="{col}" stroke-width="{w:.1f}" opacity="{clamp(op):.2f}"/>'


def raios_luz(x, y, r, n, op, col="#fff6c2", rot=0):
    o = ""
    for k in range(n):
        a = math.radians(rot + k * 360 / n)
        a2 = a + math.radians(360 / n * 0.35)
        o += f'<polygon points="{x},{y} {x + math.cos(a) * r:.1f},{y + math.sin(a) * r:.1f} {x + math.cos(a2) * r:.1f},{y + math.sin(a2) * r:.1f}" fill="{col}" opacity="{op:.2f}"/>'
    return o


def poeira(t, t0, x, y, n=10, dur=0.7, s=1.0, seed=5, cor="#d8c8a8"):
    u = seg(t, t0, t0 + dur)
    if u <= 0 or u >= 1:
        return ""
    o = ""
    for i in range(n):
        rnd = random.Random(seed * 31 + i)
        d = rnd.choice((-1, 1)) * rnd.uniform(0.3, 1.0)
        px = x + d * 90 * s * ease_out(u)
        py = y - rnd.uniform(4, 26) * s * ease_out(u)
        r = (8 + rnd.uniform(4, 14) * u) * s
        o += f'<circle cx="{px:.1f}" cy="{py:.1f}" r="{r:.1f}" fill="{cor}" opacity="{0.75 * (1 - u):.2f}"/>'
    return o


def destrocos(t, t0, x, y, n=14, seed=9, cores=("#d9a35f", "#b57a3e", "#8a6a4a"), forca=1.0):
    o = ""
    age = t - t0
    if age <= 0 or age > 1.4:
        return ""
    for i in range(n):
        rnd = random.Random(seed * 53 + i)
        vx = rnd.uniform(-60, 260) * forca
        vy = -rnd.uniform(120, 340) * forca
        px, py = x + vx * age, y + vy * age + 0.5 * 900 * age * age
        if py > 0:
            py = 0
        s = rnd.uniform(4, 10)
        ang = rnd.uniform(0, 360) + age * rnd.uniform(-600, 600)
        op = clamp(1.4 - age)
        o += f'<g transform="translate({px:.1f},{py:.1f}) rotate({ang:.0f})" opacity="{op:.2f}"><rect x="{-s}" y="{-s * 0.7}" width="{2 * s}" height="{1.4 * s}" rx="1.5" fill="{rnd.choice(cores)}"/></g>'
    return o


def linhas_vel(t, x0, x1, y0, y1, n=10, seed=3, op=0.7, comp=90):
    o = ""
    for i in range(n):
        rnd = random.Random(seed * 17 + i)
        y = rnd.uniform(y0, y1)
        x = x0 + ((rnd.uniform(0, 1) + t * rnd.uniform(2, 4)) % 1.0) * (x1 - x0)
        o += f'<path d="M{x:.0f},{y:.0f} h{-comp * rnd.uniform(0.5, 1.2):.0f}" stroke="#ffffff" stroke-width="{rnd.uniform(2, 5):.1f}" stroke-linecap="round" opacity="{op * rnd.uniform(0.4, 1):.2f}"/>'
    return o


# ================================================================ alvos (robôs do jogo)
def robo(x, y=0, col="#5cc45c", rot=0, s=1.0, face=None, tint=None, tint_op=0.0):
    body = eu.desenha(0, col, "parado")
    o = f'<g transform="translate({x:.1f},{y:.1f}) rotate({rot:.0f} 0 -40) scale({s})">{body}'
    if tint and tint_op > 0:
        o += f'<ellipse cx="0" cy="-42" rx="34" ry="46" fill="{tint}" opacity="{tint_op:.2f}"/>'
    return o + "</g>"


# ================================================================ TRANSFORMAÇÃO (comum a todas)
CHEGADA = [  # peça, início, fim, de onde vem (dx, dy, giro)
    ("perna_b", 0.40, 0.62, (-160, 120, -90)), ("perna_f", 0.44, 0.66, (160, 120, 90)),
    ("tronco", 0.52, 0.76, (0, -260, 25)), ("cabine", 0.58, 0.82, (0, -60, 0)),
    ("peito", 0.62, 0.84, (0, -200, -20)), ("braco_b", 0.70, 0.9, (-220, -40, -140)),
    ("ombro_b", 0.74, 0.94, (-200, -160, -120)), ("arma", 0.80, 1.0, (260, -30, 160)),
    ("ombro_f", 0.84, 1.04, (220, -170, 140)), ("costas", 0.88, 1.08, (-120, -240, -60)),
    ("cabeca", 0.98, 1.16, (0, -300, 200)),
]


def partes_transf(t):
    P = {}
    for nome, t0, t1, (dx, dy, rr) in CHEGADA:
        u = seg(t, t0, t1)
        if u <= 0:
            P[nome] = dict(op=0)
            continue
        k = 1 - ease_back(u, 1.9)
        P[nome] = dict(dx=dx * k, dy=dy * k, rot=rr * k, s=lerp(0.6, 1.0, ease_out(u)), op=clamp(u * 4))
    return P


def fx_transf_atras(t, cx, cy):
    """Atrás do mecha: raios de luz giratórios e brilho enquanto monta."""
    o = ""
    u = seg(t, 0.25, 1.2)
    if 0 < u < 1:
        op = 0.55 * math.sin(u * math.pi)
        o += raios_luz(cx, cy, 260, 14, op * 0.6, "#fff3b0", rot=t * 90)
        o += f'<circle cx="{cx}" cy="{cy}" r="{90 + 60 * u:.0f}" fill="#fff6d8" opacity="{op:.2f}"/>'
    return o


def fx_transf_frente(t, cx, cy, olho, nome):
    o = ""
    # 1) pega a caixa: ícone brilhando sobe e explode em luz
    u = seg(t, 0.0, 0.3)
    if 0 <= t < 0.32:
        y = -150 - 40 * ease_out(u)
        o += f'<g transform="translate(0,{y:.0f}) rotate({t * 400:.0f})">' + R(-16, -16, 32, 32, 6, "#ffb22e", k=0.3) + R(-10, -10, 20, 20, 4, "#fff3b0", k=0.2) + "</g>"
        o += f'<circle cx="0" cy="{y:.0f}" r="{30 + 30 * u:.0f}" fill="#fff6c2" opacity="{0.5:.2f}"/>'
    u = seg(t, 0.28, 0.5)
    if 0 < u < 1:
        o += f'<circle cx="0" cy="-120" r="{60 + 260 * ease_out(u):.0f}" fill="#ffffff" opacity="{0.9 * (1 - u):.2f}"/>' + anel(0, -120, 40 + 300 * u, 10 * (1 - u) + 1, "#ffe27a", 1 - u)
    # 2) o robô sobe brilhando e encolhe para dentro do cockpit
    if t < 0.82:
        uj = seg(t, 0.25, 0.5)
        uc = seg(t, 0.55, 0.8)
        y = -60 * math.sin(uj * math.pi / 2) - lerp(0, cy + 60, ease_out(uc)) * 0 + lerp(0, cy, ease_out(uc))
        y = lerp(-60 * math.sin(uj * math.pi / 2), cy + 30, ease_out(uc))
        x = lerp(0, cx, ease_out(uc))
        s = lerp(1.0, 0.35, ease_out(uc))
        glow = seg(t, 0.25, 0.4)
        o += robo(x, y, COL, s=s, rot=uc * 360 if uc > 0 else 0, tint="#ffffff", tint_op=0.75 * glow)
    # 3) faíscas de encaixe quando cada peça chega
    for i, (nome_p, t0, t1, _) in enumerate(CHEGADA):
        a = t - t1
        if 0 <= a < 0.22:
            k = a / 0.22
            px, py = random.Random(i).uniform(-40, 40), random.Random(i + 50).uniform(-150, -40)
            o += estrela(px, py, 26 * (1 - k) + 6, 1 - k, "#ffffff")
            for j in range(6):
                ang = j * 1.05 + i
                o += f'<path d="M{px + math.cos(ang) * 10 * (1 + 4 * k):.1f},{py + math.sin(ang) * 10 * (1 + 4 * k):.1f} l{math.cos(ang) * 10:.1f},{math.sin(ang) * 10:.1f}" stroke="#ffd36b" stroke-width="3" stroke-linecap="round" opacity="{1 - k:.2f}"/>'
    # 4) o olho acende: risco vermelho e brilho
    u = seg(t, 1.16, 1.34)
    if 0 < u < 1 or 1.16 < t < 1.6:
        k = clamp(u)
        ox_, oy_ = olho
        o += f'<ellipse cx="{ox_:.1f}" cy="{oy_:.1f}" rx="{20 + 140 * k * (1 - k) * 4:.0f}" ry="{6 + 8 * (1 - k):.0f}" fill="#ff3b2f" opacity="{0.8 * (1 - seg(t, 1.3, 1.6)):.2f}"/>'
        o += estrela(ox_ + 6, oy_, 30 * (1 - seg(t, 1.2, 1.5)) + 2, 0.9 * (1 - seg(t, 1.2, 1.5)), "#ffd0c8")
    # 5) aterrissa: onda de choque, poeira, pedras e o NOME estoura na tela (desenhado fora do mundo)
    u = seg(t, 1.18, 1.75)
    if 0 < u < 1:
        o += f'<ellipse cx="0" cy="0" rx="{40 + 300 * ease_out(u):.0f}" ry="{8 + 40 * ease_out(u):.0f}" fill="none" stroke="#ffffff" stroke-width="{10 * (1 - u) + 1:.1f}" opacity="{1 - u:.2f}"/>'
        o += poeira(t, 1.18, 0, 0, n=16, dur=0.9, s=1.4, seed=7)
        o += destrocos(t, 1.18, -20, 0, n=10, seed=3, cores=("#a89878", "#8a7a60", "#c9b99a"))
        o += destrocos(t, 1.18, 20, 0, n=10, seed=4, cores=("#a89878", "#8a7a60", "#c9b99a"), forca=-1.0)
    return o


def titulo_pop(t, nome, t0=1.2, x=W / 2, y=150, cor="#ffd23a"):
    u = seg(t, t0, t0 + 0.25)
    if t < t0 or t > t0 + 1.3:
        return ""
    s = ease_back(u, 3.0) if u < 1 else 1.0
    op = 1 - seg(t, t0 + 1.0, t0 + 1.3)
    txt = nome + "!"
    return (f'<g opacity="{op:.2f}" transform="translate({x},{y}) rotate(-4) scale({s:.3f})">'
            f'<text x="0" y="0" text-anchor="middle" font-family="Fredoka, Arial Black, Arial" font-weight="900" font-size="86" fill="#2a1a2e" stroke="#2a1a2e" stroke-width="16" stroke-linejoin="round">{txt}</text>'
            f'<text x="0" y="0" text-anchor="middle" font-family="Fredoka, Arial Black, Arial" font-weight="900" font-size="86" fill="{cor}">{txt}</text></g>')


# ================================================================ cenário
def cenario(t, extra=""):
    b = [f'<defs><linearGradient id="ceu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fd8ea"/><stop offset="1" stop-color="#d8f1f0"/></linearGradient></defs>',
         f'<rect width="{W}" height="{H}" fill="url(#ceu)"/>']
    for i, (x, w, h) in enumerate(((60, 120, 260), (210, 90, 190), (980, 140, 300), (1150, 100, 220), (640, 110, 160))):
        b.append(f'<rect x="{x}" y="{GROUND - h}" width="{w}" height="{h}" fill="#b6dbe2"/>')
        for r in range(int(h / 34)):
            b.append(f'<rect x="{x + 14}" y="{GROUND - h + 16 + r * 34}" width="{w - 28}" height="12" fill="#a6cfd8"/>')
    b.append(f'<path d="M820,{GROUND - 330} h300 M840,{GROUND - 330} v330" stroke="#e8b84a" stroke-width="8" opacity="0.55"/>')
    b.append(f'<rect x="0" y="{GROUND}" width="{W}" height="{H - GROUND}" fill="#cbbd9f"/><rect x="0" y="{GROUND}" width="{W}" height="6" fill="#e8dcc2"/>')
    return "".join(b) + extra


def quadro(t, mundo_atras, mecha_svg, mundo_frente, hud, shake=(0, 0), cx=W / 2, ox=0.0, oy=0.0, flash=0.0, flash_cor="#ffffff"):
    sx, sy = shake
    b = [cenario(t)]
    b.append(f'<g transform="translate({cx + sx:.1f},{GROUND + sy:.1f}) scale({SC})">')
    b.append(mundo_atras)
    b.append(f'<ellipse cx="{ox:.1f}" cy="2" rx="58" ry="9" fill="#2a1a2e" opacity="0.2"/>')
    b.append(f'<g transform="translate({ox:.1f},{oy:.1f})">{mecha_svg}</g>')
    b.append(mundo_frente)
    b.append("</g>")
    if flash > 0:
        b.append(f'<rect width="{W}" height="{H}" fill="{flash_cor}" opacity="{clamp(flash):.2f}"/>')
    b.append(hud)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(b)}</svg>'


def faixa_nome(nome, sub):
    return (f'<rect x="20" y="18" width="{W - 40}" height="52" rx="14" fill="#ffffff" opacity="0.82"/>'
            + label(40, 54, nome, 28, INK, "start") + label(W - 40, 54, sub, 18, "#2a4a58", "end", 600))


def barra(x, y, w, u, cor="#ff9a3a", txt="combustível"):
    return (R(x, y, w, 22, 9, "#2e323b", k=0.2) + f'<rect x="{x + 4}" y="{y + 4}" width="{max(0, (w - 8) * clamp(u)):.0f}" height="14" rx="6" fill="{cor}"/>'
            + label(x + w / 2, y - 8, txt, 16, "#2a4a58", "middle", 700))


# ================================================================ helpers da arma (posição da ponta no mundo do mecha)
def ponta_arma(off, mira):
    sx, sy = ac.OMBRO[0]
    a = math.radians(mira)
    return sx + off[0] * math.cos(a) - off[1] * math.sin(a), sy + off[0] * math.sin(a) + off[1] * math.cos(a)


def desenha_mecha(fn, col, partes, mira=0.0):
    ac.PARTES.clear()
    ac.PARTES.update(partes)
    ac.MIRA[0] = mira
    ac.ESTATICO[0] = False
    out = fn(col)
    ac.PARTES.clear()
    ac.MIRA[0] = 0.0
    return out


def olho_de(fn):
    """Posição do olho (cabecinha) no mundo do mecha: mesma conta de mecha()."""
    cfg = {"fornalha": (40, 1.35, 0.85), "broca": (78, 0.75, 0.95), "bola": (40, 1.25, 1.05), "empilhadeira": (66, 1.1, 1.15), "para_raios": (50, 1.0, 1.0)}[fn.__name__]
    Hh, tw, th = cfg
    return 10 * tw + 8, -Hh + (-136 + 58) * th - 1


def cockpit_de(fn):
    cfg = {"fornalha": (40, 1.35, 0.85), "broca": (78, 0.75, 0.95), "bola": (40, 1.25, 1.05), "empilhadeira": (66, 1.1, 1.15), "para_raios": (50, 1.0, 1.0)}[fn.__name__]
    Hh, tw, th = cfg
    return 4 * tw, -Hh + (-102 + 58) * th


def transf(t, fn, col, nome):
    """Quadro do trecho de transformação (0..T_TRANS)."""
    partes = partes_transf(t)
    cx, cy = cockpit_de(fn)
    atras = fx_transf_atras(t, cx, cy - 20)
    frente = fx_transf_frente(t, cx, cy, olho_de(fn), nome)
    sh = tremor(t, 1.18, 0.4, 9)
    flash = 0.55 * (1 - seg(t, 0.3, 0.5)) if 0.3 <= t < 0.5 else (0.35 * (1 - seg(t, 1.18, 1.32)) if 1.18 <= t < 1.32 else 0)
    m = desenha_mecha(fn, col, partes)
    return atras, m, frente, sh, flash


# ================================================================ T01 FORNALHA — lança-chamas com partículas
FOGO_OFF = (64, 15)


def mira_fornalha(t):
    keys = [(0.0, 0), (1.0, 0), (1.3, -40), (1.7, -40), (2.0, -90), (2.4, -90), (2.7, -15), (3.4, -15)]
    for (a, va), (b, vb) in zip(keys, keys[1:]):
        if t <= b:
            u = seg(t, a, b)
            return lerp(va, vb, u * u * (3 - 2 * u))
    return keys[-1][1]


def fx_fornalha(t, tl):
    """tl = tempo da habilidade. Jato de partículas da boca, brasas, calor, fumaça da chaminé, alvo queimando."""
    atras, frente = "", ""
    mira = mira_fornalha(tl)
    tip = ponta_arma(FOGO_OFF, mira)
    hist = {}

    def emi(tb, rnd):
        tb_l = tb - T_TRANS
        m = math.radians(mira_fornalha(tb_l) + rnd.uniform(-9, 9))
        p = ponta_arma(FOGO_OFF, mira_fornalha(tb_l))
        v = rnd.uniform(380, 560)
        return p[0], p[1], math.cos(m) * v, math.sin(m) * v, -180
    ligado = 0.15 < tl < 3.3
    if tl > 0.15:
        ps = particulas(t, T_TRANS + 0.15, T_TRANS + 3.3, 120, 0.42, emi, seed=11)
        ps.sort(key=lambda p: -p[0])
        for u, x, y, rnd in ps:
            r = (5 + 22 * u ** 0.8) * rnd.uniform(0.8, 1.2)
            c = grad_fogo(u)
            op = (1 - u) ** 0.7 * (0.95 if u < 0.75 else 0.5)
            frente += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{c}" opacity="{op:.2f}"/>'
            if u < 0.4:
                frente += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 0.45:.1f}" fill="#fffbe0" opacity="{0.7 * (1 - u / 0.4):.2f}"/>'

        def emb(tb, rnd):
            tb_l = tb - T_TRANS
            m = math.radians(mira_fornalha(tb_l) + rnd.uniform(-25, 25))
            p = ponta_arma(FOGO_OFF, mira_fornalha(tb_l))
            v = rnd.uniform(200, 420)
            return p[0], p[1], math.cos(m) * v, math.sin(m) * v - 60, 380
        for u, x, y, rnd in particulas(t, T_TRANS + 0.15, T_TRANS + 3.3, 40, 0.8, emb, seed=12):
            frente += f'<circle cx="{x:.1f}" cy="{min(y, -2):.1f}" r="{2.2 * (1 - u) + 0.8:.1f}" fill="#ffcf5a" opacity="{1 - u:.2f}"/>'
    if ligado:
        fl = 0.8 + 0.2 * math.sin(t * 60)
        frente += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="{22 * fl:.1f}" fill="#fff3b0" opacity="0.85"/><circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="{46 * fl:.1f}" fill="#ffb03a" opacity="0.35"/>'
        atras += f'<ellipse cx="{tip[0] + 80:.0f}" cy="0" rx="180" ry="18" fill="#ffb03a" opacity="0.25"/>'
    # brasa do peito pulsando e fumaça das chaminés
    atras += f'<ellipse cx="0" cy="-30" rx="70" ry="30" fill="#ff8a2a" opacity="{0.15 + 0.12 * math.sin(t * 14):.2f}"/>'

    def fum(tb, rnd):
        return -54 + rnd.uniform(-4, 4), -150, rnd.uniform(-20, 10), -rnd.uniform(50, 90), 0
    for u, x, y, rnd in particulas(t, 0.0, 6.0, 9, 1.6, fum, seed=13):
        atras += f'<circle cx="{x - 30 * u:.1f}" cy="{y:.1f}" r="{8 + 22 * u:.1f}" fill="#7a7a80" opacity="{0.55 * (1 - u):.2f}"/>'
    # alvo: pega fogo quando a chama passa por ele (tl 0.2..1.0) e é empurrado
    ax = 300 + 60 * ease_out(seg(tl, 0.3, 1.2))
    queima = clamp(seg(tl, 0.25, 0.4) - seg(tl, 1.1, 1.6))
    frente += robo(ax, 0, "#5cc45c", rot=10 * queima, tint="#ff6a1a", tint_op=0.45 * queima)
    if queima > 0:
        def chama_alvo(tb, rnd):
            return ax + rnd.uniform(-20, 20), -rnd.uniform(10, 70), rnd.uniform(-10, 10), -rnd.uniform(60, 120), 0
        for u, x, y, rnd in particulas(t, T_TRANS + 0.25, T_TRANS + 1.6, 50, 0.45, chama_alvo, seed=14):
            frente += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{(9 * (1 - u) + 3):.1f}" fill="{grad_fogo(0.2 + u * 0.7)}" opacity="{(1 - u) * queima:.2f}"/>'
    return atras, frente, mira


def instante(fx, alvo, t0, t1):
    """Primeiro t em [t0,t1] com fx(t) >= alvo (passo fino)."""
    t = t0
    while t <= t1:
        if fx(t) >= alvo:
            return t
        t += 0.005
    return t1 + 9


# ================================================================ T05 BROCA — dash furando
BROCA_OFF = (80, 12)


def broca_x(tl):
    if tl < 0.5:
        return lerp(-260, -290, ease_out(seg(tl, 0.0, 0.5)))
    return lerp(-290, 230, seg(tl, 0.5, 1.7) ** 0.85) + (20 * ease_out(seg(tl, 1.7, 2.1)) if tl > 1.7 else 0)


def fx_broca(t, tl, partes):
    atras, frente = "", ""
    # posição do mecha: carrega (0..0.5) recuando, dispara (0.5..1.7), derrapa (1.7..2.1)
    carga = seg(tl, 0.0, 0.5)
    dash = seg(tl, 0.5, 1.7)
    ox = broca_x(tl)
    vel = 1.0 if 0.5 < tl < 1.7 else 0.0
    lean = -8 * carga if tl < 0.5 else (14 if tl < 1.7 else lerp(14, 0, seg(tl, 1.7, 2.2)))
    for n in ("tronco", "cabine", "peito", "cabeca", "ombro_b", "ombro_f", "arma", "costas", "braco_b"):
        partes[n] = dict(rot=lean, dx=0, dy=0)
    tip_l = ponta_arma(BROCA_OFF, lean)
    tip = (tip_l[0] + ox, tip_l[1])
    # broca girando: listras que correm + faíscas na ponta durante a carga
    gir = (t * 26) % 1.0
    frente += f'<g transform="translate({ox:.1f},0) rotate({lean:.1f} {ac.OMBRO[0][0]:.1f} {ac.OMBRO[0][1]:.1f})">'
    for i in range(5):
        x = ac.OMBRO[0][0] + 46 + ((i + gir) / 5) * 64
        hgt = 18 * (1 - ((i + gir) / 5))
        frente += f'<path d="M{x:.1f},{ac.OMBRO[0][1] + 12 - hgt:.1f} L{x + 6:.1f},{ac.OMBRO[0][1] + 12 + hgt:.1f}" stroke="#ffffff" stroke-width="2.6" opacity="0.8"/>'
    frente += "</g>"
    if tl < 0.55:
        def fa(tb, rnd):
            a = rnd.uniform(-1.2, 1.2)
            v = rnd.uniform(150, 330)
            return tip[0], tip[1], math.cos(a) * v, math.sin(a) * v - 40, 600
        for u, x, y, rnd in particulas(t, T_TRANS, T_TRANS + 0.55, 90, 0.3, fa, seed=21):
            frente += f'<path d="M{x:.1f},{y:.1f} l{-6 * (1 - u):.1f},{3 * (1 - u):.1f}" stroke="#ffd36b" stroke-width="2.4" stroke-linecap="round" opacity="{1 - u:.2f}"/>'
        frente += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="{12 + 14 * carga:.0f}" fill="#fff3b0" opacity="{0.4 + 0.4 * carga:.2f}"/>'
    # rastro: fantasmas azulados + linhas de velocidade + poeira contínua
    fantasmas = ""
    if vel > 0:
        for k, dt in enumerate((0.12, 0.08, 0.04)):
            tt = tl - dt
            if tt > 0.5:
                gx = broca_x(tt)
                fantasmas += f'<g opacity="{0.14 + k * 0.08:.2f}" transform="translate({gx:.1f},0)"><ellipse cx="0" cy="-70" rx="50" ry="70" fill="#bfe7ff"/></g>'
        atras += fantasmas + linhas_vel(t, ox - 420, ox - 40, -170, -10, n=14, seed=4, op=0.8, comp=120)
        atras += "".join(f'<circle cx="{ox - 40 - i * 34 - (t * 300) % 34:.0f}" cy="{-6 - (i % 3) * 5}" r="{14 + i * 3}" fill="#d8c8a8" opacity="{0.6 - i * 0.07:.2f}"/>' for i in range(7))
    # parede de blocos que é furada
    bx = -40
    hit_t = instante(broca_x, bx - 125, 0.5, 2.0)
    quebrou = tl > hit_t
    if not quebrou:
        for yy in range(4):
            for xx in range(2):
                frente += ah.bloco(bx + xx * 32, -32 * (yy + 1), 32, 32, quebrado=tl > hit_t - 0.25)
    else:
        for yy in range(4):
            frente += destrocos(t, T_TRANS + hit_t, bx + 32, -32 * yy - 16, n=8, seed=60 + yy, forca=1.3)
        frente += poeira(t, T_TRANS + hit_t, bx + 32, 0, n=14, dur=1.0, s=1.6, seed=61)
        u = seg(tl, hit_t, hit_t + 0.25)
        if u < 1:
            frente += estrela(bx + 32, -70, 70 * (1 - u) + 10, 1 - u)
    # alvo: atropelado e voa longe girando
    ax0 = 110
    hit2 = instante(broca_x, ax0 - 120, 0.5, 2.0)
    if tl < hit2:
        frente += robo(ax0, 0, "#f06aa8")
    else:
        a = tl - hit2
        frente += robo(ax0 + 300 * a, -320 * a + 600 * a * a if a < 0.9 else -320 * 0.9 + 600 * 0.81, "#f06aa8", rot=a * 900)
        u = seg(tl, hit2, hit2 + 0.25)
        if u < 1:
            frente += estrela(ax0, -60, 60 * (1 - u) + 8, 1 - u)
    # derrapagem: faíscas sob os pés
    if 1.7 < tl < 2.2:
        def fs(tb, rnd):
            return ox + rnd.uniform(-20, 20), -2, -rnd.uniform(80, 260), -rnd.uniform(40, 160), 700
        for u, x, y, rnd in particulas(t, T_TRANS + 1.7, T_TRANS + 2.2, 120, 0.3, fs, seed=22):
            frente += f'<path d="M{x:.1f},{min(y, -1):.1f} l5,-2" stroke="#ffd36b" stroke-width="2.4" stroke-linecap="round" opacity="{1 - u:.2f}"/>'
    shake = tremor(tl, hit_t, 0.35, 12) if tl > hit_t else (tremor(tl, hit2, 0.3, 9) if tl > hit2 else (math.sin(t * 80) * 2 * carga, 0))
    comb = 1.0 if tl < 0.5 else 1 - dash
    return atras, frente, ox, shake, comb


# ================================================================ T03 BOLA — fecha e rola
def fx_bola(t, tl, fn, col):
    """Devolve (atras, frente, mecha_svg_ou_bola, ox, oy, shake)."""
    atras, frente = "", ""
    fecha = seg(tl, 0.0, 0.45)
    if tl < 0.45:   # gorila agacha e as placas fecham
        s = lerp(1.0, 0.55, ease_out(fecha))
        partes = {n: dict(s=s, dy=60 * fecha, rot=0) for n in ("tronco", "cabine", "peito", "cabeca", "ombro_b", "ombro_f", "arma", "costas", "braco_b", "perna_b", "perna_f")}
        corpo = f'<g opacity="{1 - fecha:.2f}">{desenha_mecha(fn, col, partes)}</g>'
        corpo += f'<g opacity="{fecha:.2f}" transform="scale({lerp(0.6, 1.0, fecha):.2f})">{ac.bola_fechada(col, 0, 1 - fecha)}</g>'
        frente += anel(0, -46, 50 + 30 * fecha, 6, "#ffffff", fecha)
        return atras, frente, corpo, -300, 0, (0, 0)
    # rola: x(t), pula por cima do bloco, quica
    u = seg(tl, 0.45, 2.9)
    ox = lerp(-300, 340, u)
    jump = seg(tl, 1.25, 1.85)
    oy = -190 * math.sin(jump * math.pi) if 0 < jump < 1 else 0
    q = seg(tl, 1.85, 2.1)
    if 0 < q < 1:
        oy = -50 * math.sin(q * math.pi)
    rot = (ox + 260) * 1.6
    sq = 1.0
    if 1.85 <= tl < 1.95 or 2.1 <= tl < 2.18:
        sq = 0.78
    corpo = f'<g transform="scale({1 / sq ** 0.5:.2f},{sq:.2f})">{ac.bola_fechada(col, rot)}</g>'
    # rastro de bolas fantasmas + arco de giro + faíscas no chão
    for k, dt in enumerate((0.09, 0.06, 0.03)):
        tt = tl - dt
        gx = lerp(-300, 340, seg(tt, 0.45, 2.9))
        gj = seg(tt, 1.25, 1.85)
        gy = -190 * math.sin(gj * math.pi) if 0 < gj < 1 else 0
        atras += f'<circle cx="{gx - ox:.1f}" cy="{gy - oy - 46:.1f}" r="46" fill="#bfe7ff" opacity="{0.12 + 0.08 * k:.2f}"/>'
    atras += f'<path d="M-30,-96 A52,52 0 0 0 -60,-20" stroke="#ffffff" stroke-width="7" fill="none" opacity="0.6" stroke-linecap="round"/>'
    atras += linhas_vel(t, -330, -60, -110, -10, n=10, seed=8, op=0.7, comp=110)
    if oy > -4:
        def fs(tb, rnd):
            return 0, -2, -rnd.uniform(120, 300), -rnd.uniform(60, 200), 800
        for uu, x, y, rnd in particulas(t, t - 0.3, t, 80, 0.28, fs, seed=int(t * 7)):
            atras += f'<path d="M{x:.1f},{min(y, -1):.1f} l6,-2" stroke="#ffd36b" stroke-width="2.4" stroke-linecap="round" opacity="{1 - uu:.2f}"/>'
        atras += "".join(f'<circle cx="{-50 - i * 26:.0f}" cy="{-8 - i * 2}" r="{10 + i * 3}" fill="#d8c8a8" opacity="{0.5 - i * 0.08:.2f}"/>' for i in range(5))
    # obstáculo (bloco) e alvo que é atropelado; impactos de pouso
    mundo = ah.bloco(-20, -64, 64, 64)
    mundo += poeira(t, T_TRANS + 1.85, lerp(-300, 340, seg(1.85, 0.45, 2.9)), 0, n=14, dur=0.8, s=1.4, seed=31)
    if 1.85 < tl < 2.3:
        uu = seg(tl, 1.85, 2.3)
        lx = lerp(-300, 340, seg(1.85, 0.45, 2.9))
        mundo += f'<ellipse cx="{lx:.0f}" cy="0" rx="{40 + 200 * uu:.0f}" ry="{8 + 24 * uu:.0f}" fill="none" stroke="#ffffff" stroke-width="{8 * (1 - uu) + 1:.1f}" opacity="{1 - uu:.2f}"/>'
    ax = 250
    hit = instante(lambda q: lerp(-300, 340, seg(q, 0.45, 2.9)), ax - 60, 0.45, 2.9)
    if tl < hit:
        mundo += robo(ax, 0, "#f2c84b")
    else:
        a = tl - hit
        mundo += robo(ax + 420 * a, min(0, -420 * a + 700 * a * a), "#f2c84b", rot=-a * 800)
        uu = seg(tl, hit, hit + 0.25)
        if uu < 1:
            mundo += estrela(ax, -50, 70 * (1 - uu) + 8, 1 - uu)
    sh = tremor(tl, 1.85, 0.3, 10) if tl > 1.85 else (0, 0)
    if tl > hit:
        s2 = tremor(tl, hit, 0.3, 8)
        sh = (sh[0] + s2[0], sh[1] + s2[1])
    return f'<g transform="translate({ox:.1f},{oy:.1f})">{atras}</g>' + mundo, frente, corpo, ox, oy, sh


# ================================================================ T02 EMPILHADEIRA — agarra e arremessa
GARFO_OFF = (80, 6)


def fx_empilhadeira(t, tl, partes):
    atras, frente = "", ""
    inv = seg(tl, 0.0, 0.45)
    ox = lerp(-260, -120, ease_out(inv))
    # mira do garfo: baixo na investida, sobe ao levantar, gira para trás e arremessa
    keys = [(0.0, 10), (0.45, 10), (0.9, -35), (1.15, -55), (1.3, -110), (1.5, -95), (2.5, 0)]
    mira = 0
    for (a, va), (b, vb) in zip(keys, keys[1:]):
        if tl <= b:
            uu = seg(tl, a, b)
            mira = lerp(va, vb, uu * uu * (3 - 2 * uu))
            break
    else:
        mira = 0
    if tl < 0.45:
        atras += linhas_vel(t, ox - 300, ox - 20, -150, -10, n=10, seed=5, op=0.7)
        atras += "".join(f'<circle cx="{-60 - i * 28:.0f}" cy="{-6 - (i % 2) * 4}" r="{12 + i * 3}" fill="#d8c8a8" opacity="{0.55 - i * 0.08:.2f}"/>' for i in range(6))
    lean = 10 if tl < 0.45 else (-12 * seg(tl, 0.9, 1.3) + 22 * seg(tl, 1.3, 1.45) if tl < 1.8 else 0)
    for n in ("tronco", "cabine", "peito", "cabeca", "ombro_b", "ombro_f", "costas", "braco_b"):
        partes[n] = dict(rot=lean)
    tip = ponta_arma(GARFO_OFF, mira)
    tipw = (tip[0] + ox, tip[1])
    # alvo: parado → preso no garfo → arremessado em arco girando → impacto
    if tl < 0.45:
        frente += robo(80, 0, "#f06aa8")
    elif tl < 1.4:
        frente += robo(tipw[0] + 10, tipw[1] + 10, "#f06aa8", rot=mira * 0.5, s=0.95)
        if tl < 0.65:
            uu = seg(tl, 0.45, 0.65)
            frente += estrela(tipw[0], tipw[1] - 20, 60 * (1 - uu) + 8, 1 - uu) + anel(tipw[0], tipw[1] - 20, 20 + 80 * uu, 6 * (1 - uu) + 1, "#ffffff", 1 - uu)
    else:
        a = seg(tl, 1.4, 2.4)
        x0, y0 = ox + ponta_arma(GARFO_OFF, -95)[0], ponta_arma(GARFO_OFF, -95)[1]
        x = lerp(x0, 300, a)
        y = lerp(y0, 0, a) - 190 * math.sin(a * math.pi)
        # rastro do arremesso
        pts = []
        for k in range(14):
            aa = max(0.0, a - k * 0.025)
            pts.append(f"{lerp(x0, 300, aa):.0f},{lerp(y0, 0, aa) - 190 * math.sin(aa * math.pi) - 40:.0f}")
        frente += f'<polyline points="{" ".join(pts)}" stroke="#ffffff" stroke-width="12" fill="none" opacity="0.5" stroke-linecap="round" stroke-linejoin="round"/>'
        frente += robo(x, y, "#f06aa8", rot=a * 1080)
        if tl > 2.4:
            frente += destrocos(t, T_TRANS + 2.4, 300, 0, n=14, seed=41, cores=("#a89878", "#8a7a60", "#c9b99a"), forca=1.2)
            frente += poeira(t, T_TRANS + 2.4, 300, 0, n=14, dur=0.9, s=1.6, seed=42)
            uu = seg(tl, 2.4, 2.8)
            frente += f'<ellipse cx="300" cy="0" rx="{40 + 200 * uu:.0f}" ry="{8 + 26 * uu:.0f}" fill="none" stroke="#ffffff" stroke-width="{8 * (1 - uu) + 1:.1f}" opacity="{1 - uu:.2f}"/>'
            frente += estrela(300, -40, 80 * (1 - uu) + 8, 1 - uu)
    # brilho hidráulico no mastro ao levantar
    if 0.45 < tl < 1.4:
        atras += f'<rect x="-82" y="-260" width="16" height="200" rx="6" fill="#ffe27a" opacity="{0.25 + 0.2 * math.sin(t * 30):.2f}"/>'
    sh = tremor(tl, 2.4, 0.4, 13) if tl > 2.4 else (tremor(tl, 0.45, 0.2, 7) if tl > 0.45 else (0, 0))
    return atras, frente, ox, mira, sh


# ================================================================ T06 PARA-RAIOS — arco elétrico em cadeia
RAIO_OFF = (84, 13)
ELEC = "#7fe7ff"


def raio_vivo(a, b, w, t, seed, amp=12, n=9, galhos=2):
    """Raio que muda de forma a cada quadro (seed + quadro), com halo e galhos."""
    fr = int(t * FPS)
    o = ah.raio(a, b, w, seed=seed * 1000 + fr // 1, n=n, amp=amp)
    o += f'<path d="M{a[0]:.1f},{a[1]:.1f} L{b[0]:.1f},{b[1]:.1f}" stroke="{ELEC}" stroke-width="{w * 7:.1f}" opacity="0.12" stroke-linecap="round"/>'
    rnd = random.Random(seed * 77 + fr)
    for g in range(galhos):
        u = rnd.uniform(0.2, 0.8)
        px, py = lerp(a[0], b[0], u), lerp(a[1], b[1], u)
        ang = rnd.uniform(0, 2 * math.pi)
        L = rnd.uniform(20, 45)
        o += ah.raio((px, py), (px + math.cos(ang) * L, py + math.sin(ang) * L), w * 0.45, seed=seed * 31 + fr * 7 + g, n=4, amp=6)
    return o


def fx_raio(t, tl):
    atras, frente = "", ""
    tip = ponta_arma(RAIO_OFF, 0)
    coil = (-53 * 1.0 + 0, -186 + 0)   # ponto da bobina no quadro padrão (costas transladadas para o ombro: mesma conta de mecha)
    sx, sy = ac.OMBRO[0]
    coil = (coil[0] + sx - 34, coil[1] + sy + 106)
    carga = seg(tl, 0.0, 0.7)
    # carga: arcos estalando na bobina, partículas elétricas convergindo, brilho crescente
    if tl < 2.9:
        atras += f'<circle cx="{coil[0]:.1f}" cy="{coil[1]:.1f}" r="{18 + 30 * carga + 4 * math.sin(t * 50):.1f}" fill="{ELEC}" opacity="{0.25 + 0.35 * carga:.2f}"/>'
        for k in range(2 + int(carga * 4)):
            ang = (t * 7 + k * 1.7) % (2 * math.pi)
            frente += ah.raio(coil, (coil[0] + math.cos(ang) * (26 + 20 * carga), coil[1] + math.sin(ang) * (26 + 20 * carga)), 1.6, seed=int(t * FPS) * 13 + k, n=4, amp=5)

        def conv(tb, rnd):
            a = rnd.uniform(0, 2 * math.pi)
            r = rnd.uniform(70, 120)
            return coil[0] + math.cos(a) * r, coil[1] + math.sin(a) * r, -math.cos(a) * r / 0.4, -math.sin(a) * r / 0.4, 0
        if tl < 0.75:
            for uu, x, y, rnd in particulas(t, T_TRANS, T_TRANS + 0.75, 60, 0.4, conv, seed=51):
                frente += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{2.6 * (1 - uu) + 1:.1f}" fill="#ffffff" opacity="{0.4 + 0.6 * uu:.2f}"/>'
    # disparo em cadeia: alvo 1 (0.7), alvo 2 (0.85), alvo 3 (1.0), viga (0.95); dura até 2.6
    alvos = [(150, "#4f86d9", 0.7, 5.0), (300, "#5cc45c", 0.86, 3.4), (440, "#f06aa8", 1.02, 2.2)]
    flash = 0.0
    src = tip
    for i, (x, col, t0, w) in enumerate(alvos):
        ativo = t0 < tl < 2.6
        jit = (math.sin(t * 90 + i) * 4, math.cos(t * 70 + i) * 3) if ativo else (0, 0)
        choque = 1.0 if ativo else 0.0
        frente += robo(x + jit[0], jit[1], col, tint="#e8fbff", tint_op=0.55 * choque * (0.6 + 0.4 * math.sin(t * 60)))
        alvo_p = (x, -48)
        if ativo:
            frente += raio_vivo(src, alvo_p, w, t, seed=i + 1, amp=12 - i * 2, galhos=3 - i)
            frente += f'<circle cx="{x}" cy="-48" r="{40 - i * 8 + 6 * math.sin(t * 40):.1f}" fill="{ELEC}" opacity="0.35"/>'
            frente += estrela(x, -48, 26 - i * 5, 0.8)
            frente += label(x, -150, f"{['100', '60', '35'][i]}%", 22, "#0f5a78")
            u0 = seg(tl, t0, t0 + 0.15)
            if u0 < 1:
                frente += anel(x, -48, 20 + 90 * u0, 8 * (1 - u0) + 1, "#ffffff", 1 - u0)
                flash = max(flash, 0.35 * (1 - u0) * (1 if i == 0 else 0.5))
        src = alvo_p
    # viga de metal: o raio conduz e ela solta faíscas e trinca
    viga_y = -240
    atras += ah.viga(220, viga_y, 300) + R(510, viga_y, 12, -viga_y, 2, "#8a94a3", k=0.3)
    if 0.95 < tl < 2.6:
        frente += raio_vivo((300, -60), (360, viga_y + 6), 2.6, t, seed=9, amp=10, galhos=1)
        frente += raio_vivo((360, viga_y + 6), (512, viga_y + 6), 2.0, t, seed=10, amp=6, galhos=1)
        frente += raio_vivo((516, viga_y + 10), (516, -4), 1.8, t, seed=11, amp=5, galhos=1)

        def fv(tb, rnd):
            return rnd.uniform(240, 500), viga_y + 12, rnd.uniform(-40, 40), rnd.uniform(0, 60), 600
        for uu, x, y, rnd in particulas(t, T_TRANS + 0.95, T_TRANS + 2.6, 60, 0.6, fv, seed=55):
            frente += f'<path d="M{x:.1f},{min(y, -2):.1f} l2,6" stroke="#ffe27a" stroke-width="2.2" stroke-linecap="round" opacity="{1 - uu:.2f}"/>'
        frente += f'<path d="M380,{viga_y + 2} l10,8 l-6,4 l12,6" stroke="#2a2f38" stroke-width="2" fill="none"/>'
    # robô longe: não é atingido
    frente += robo(620, 0, "#8a8a8a") + (label(620, -150, "longe", 18, "#6b5a70") if tl > 1.0 else "")
    if 0.7 < tl < 2.6:
        frente += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="{18 + 5 * math.sin(t * 60):.1f}" fill="#ffffff" opacity="0.9"/><circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="40" fill="{ELEC}" opacity="0.4"/>'
    sh = (math.sin(t * 120) * 3, math.cos(t * 90) * 2) if 0.7 < tl < 2.6 else (0, 0)
    return atras, frente, flash, sh


# ================================================================ montagem dos vídeos
ARMS = {
    "fornalha": (ac.fornalha, "#4f86d9", "FORNALHA", "T01 · lança-chamas em 8 direções", 5.2),
    "broca": (ac.broca, "#f2c84b", "BROCA", "T05 · dash furando (segura até acabar o combustível)", 4.6),
    "bola": (ac.bola, "#f06aa8", "BOLA", "T03 · fecha numa bola blindada e rola", 5.0),
    "empilhadeira": (ac.empilhadeira, "#5cc45c", "EMPILHADEIRA", "T02 · agarra e arremessa", 4.9),
    "raio": (ah.para_raios, "#f2c84b", "PARA-RAIOS", "T06 · raio em cadeia (3 alvos) e conduz no metal", 4.9),
}


CX = {"raio": W / 2 - 290 * SC}


def frame(nome, t):
    fn, col, titulo, sub, dur = ARMS[nome]
    hud = faixa_nome(titulo, sub)
    ox0 = {"broca": -260, "bola": -300, "empilhadeira": -260, "fornalha": -220, "raio": 0}[nome]
    if t < T_TRANS:
        atras, m, frente, sh, flash = transf(t, fn, col, titulo)
        rel = lambda x: f'<g transform="translate({ox0},0)">{x}</g>'  # noqa: E731
        return quadro(t, rel(atras), m, rel(frente), hud + titulo_pop(t, titulo), shake=sh, ox=ox0, flash=flash, cx=CX.get(nome, W / 2))
    tl = t - T_TRANS
    hud += titulo_pop(t, titulo)
    if nome == "fornalha":
        ac.OMBRO[0] = ac.OMBRO[0]
        desenha_mecha(fn, col, {})   # atualiza OMBRO
        atras, frente, mira = fx_fornalha(t - 0 + 0, tl)
        recuo = (-3 * math.sin(t * 40), 0) if 0.15 < tl < 3.3 else (0, 0)
        m = desenha_mecha(fn, col, {"tronco": dict(dx=recuo[0])}, mira=mira)
        rel = lambda x: f'<g transform="translate({ox0},0)">{x}</g>'  # noqa: E731
        return quadro(t, rel(atras), m, rel(frente), hud, shake=recuo, ox=ox0)
    if nome == "broca":
        partes = {}
        desenha_mecha(fn, col, {})
        atras, frente, ox, sh, comb = fx_broca(t, tl, partes)
        lean = partes.get("arma", {}).get("rot", 0)
        partes.pop("arma", None)
        m = desenha_mecha(fn, col, partes, mira=lean)
        return quadro(t, atras, m, frente, hud + barra(W - 300, 100, 260, comb), shake=sh, ox=ox)
    if nome == "bola":
        atras, frente, corpo, ox, oy, sh = fx_bola(t, tl, fn, col)
        rel = lambda x: f'<g transform="translate({ox:.1f},{oy:.1f})">{x}</g>'  # noqa: E731
        return quadro(t, atras, corpo, rel(frente), hud, shake=sh, ox=ox, oy=oy)
    if nome == "empilhadeira":
        partes = {}
        desenha_mecha(fn, col, {})
        atras, frente, ox, mira, sh = fx_empilhadeira(t, tl, partes)
        m = desenha_mecha(fn, col, partes, mira=mira)
        rel = lambda x: f'<g transform="translate({ox:.1f},0)">{x}</g>'  # noqa: E731
        return quadro(t, atras, m, rel(frente) if False else frente, hud, shake=sh, ox=ox)
    if nome == "raio":
        desenha_mecha(fn, col, {})
        atras, frente, flash, sh = fx_raio(t, tl)
        m = desenha_mecha(fn, col, {})
        return quadro(t, atras, m, frente, hud, shake=sh, ox=0, cx=CX["raio"], flash=flash, flash_cor="#dff8ff")
    raise ValueError(nome)


def render(nomes):
    out_dir = ab.OUT
    os.makedirs(out_dir, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="armvid_")
    meta = {}
    for nome in nomes:
        dur = ARMS[nome][4]
        n = int(dur * FPS)
        for f in range(n):
            svg = frame(nome, f / FPS)
            queue(svg, f"{tmp}/svg/{nome}_{f:04d}.svg", f"{tmp}/png/{nome}_{f:04d}.png", W, H, 1)
        meta[nome] = n
    print("quadros:", render_all())
    lista = []
    for nome in nomes:
        out = os.path.join(out_dir, f"armadura_{nome}.mp4")
        subprocess.run(["ffmpeg", "-v", "quiet", "-y", "-framerate", str(FPS), "-i", f"{tmp}/png/{nome}_%04d.png", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", out], check=True)
        lista.append(out)
        from PIL import Image
        n = meta[nome]
        idx = [int(n * k) for k in (0.1, 0.22, 0.3, 0.45, 0.6, 0.75, 0.88, 0.97)]
        folha = Image.new("RGB", (4 * 640, 2 * 360))
        for k, i in enumerate(idx):
            folha.paste(Image.open(f"{tmp}/png/{nome}_{i:04d}.png").convert("RGB").resize((640, 360)), ((k % 4) * 640, (k // 4) * 360))
        folha.save(os.path.join(out_dir, f"armadura_{nome}_folha.png"))
        print(out)
    if len(lista) > 1:
        lst = os.path.join(tmp, "l.txt")
        with open(lst, "w") as fh:
            fh.write("".join(f"file '{p}'\n" for p in lista))
        subprocess.run(["ffmpeg", "-v", "quiet", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", os.path.join(out_dir, "armaduras_todas.mp4")], check=True)
    shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    nomes = [a for a in sys.argv[1:] if a in ARMS] or list(ARMS)
    render(nomes)
