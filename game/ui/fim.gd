extends RefCounted
## FIM DA PARTIDA do Derruba v2 (pranchas aprovadas 2026-11-26: art/out/recompensas/r1–r3). Três telas em sequência:
## 1 GANGORRA (tela própria animada) → 2 PROJETOS DE DEMOLIÇÃO (tela própria animada) → 3 RESULTADOS (estatísticas +
## cronômetro). Luta que não vale (curta ou sem vencedor): uma tela só "NÃO CONTOU" (A24) e depois os resultados.
## Quem decide a fase e o tempo é main (res_fase, res_t, res_crono); aqui só desenho e durações.
const Kit := preload("res://ui/kit.gd")
const Obra := preload("res://ui/obra.gd")
const RobotVis := preload("res://player/robot_visual.gd")
const INK := Color("#2a1a2e")
const ZC := ["#2e9e4f", "#8fd46a", "#f2d04b", "#f39a3a", "#ec6448", "#a8233a"]
const COLS := [["DERRUBOU", "derrubadas"], ["CAIU SOZINHO", "quedas"], ["CAIXOTES", "caixotes"], ["ENGENHOCAS", "engenhocas"], ["GOLPES", "golpes"]]
const CAT_NOME := {"skin": "SKIN", "spell": "ENGENHOCA", "evento": "EVENTO"}   # A20: spell = ENGENHOCA para o jogador
const TITULOS := {"derrubadas": "MARRETEIRO", "caixotes": "DEMOLIDOR", "engenhocas": "INVENTOR", "golpes": "BRIGÃO"}

var main: Node

func setup(m: Node) -> void:
	main = m

# ---------------------------------------------------------------- tempos
const G_MOSTRA := 0.8     # mostrador da luta
const G_PESO := 1.5       # peso cai na ponta
const G_BALANCA := 3.6    # gangorra puxa para lá e para cá e assenta
const G_PREMIO := 1.2     # caixa abre (só se chegar a ±100)
const P_INICIO := 0.6
const P_LINHA := 0.7
const P_ANDAR := 0.35

## Duração da animação de cada tela (depois disso PULAR segue; sozinha segue após mais alguns segundos).
func duracao(fase: String) -> float:
	var ri: Dictionary = main.res_info
	match fase:
		"gangorra":
			if ri.is_empty() or not ri["valida"]:
				return 1.0
			return G_BALANCA + (G_PREMIO if String(ri["premio"]) != "" else 0.0)
		"projetos":
			return P_INICIO + _linhas().size() * P_LINHA + int(ri.get("pontos", 0)) * P_ANDAR + 0.6
	return 0.0

func _linhas() -> Array:
	var ri: Dictionary = main.res_info
	var out := []
	if ri.is_empty() or not ri["valida"]:
		return out
	var pc: Dictionary = MapaReg.modo_cfg("derruba").get("progressao", {})
	out.append({"icone": "✔", "txt": "Partida válida", "sub": "1 min ou mais, com vencedor", "pts": int(pc.get("pontos_partida", 1))})
	for id in ri["novas"]:
		var nm := String(MapaReg.cena_id(main.game_mode, String(main.level.id), String(id)).get("nome", id)).to_upper()
		out.append({"icone": "★", "txt": "Cena nova: " + nm, "sub": "1ª vez neste mapa", "pts": int(pc.get("pontos_cena_nova", 2))})
	return out

static func _ease_back(x: float) -> float:
	return 1.0 + 2.70158 * pow(x - 1.0, 3) + 1.70158 * pow(x - 1.0, 2)

static func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func draw(ci: CanvasItem) -> void:
	match main.res_fase:
		"gangorra": _gangorra(ci, main.res_t)
		"projetos": _projetos(ci, main.res_t)
		_: _resultados(ci)

func _fundo(ci: CanvasItem, t: float, escurece := 0.0) -> void:
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, 880, 1920, 200), Color("#b9ab8f"))
	ci.draw_rect(Rect2(0, 880, 1920, 60), Color("#d8ccb6"))
	ci.draw_rect(Rect2(0, 880, 1920, 10), Color("#eee5d2"))
	if escurece > 0.0:
		ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(INK, escurece))

func _titulo(ci: CanvasItem, txt: String, w: float) -> void:
	ci.draw_line(Vector2(960, -4), Vector2(960, 40), Color("#4a4f5c"), 5.0)
	Obra.corrente(ci, 960 - w / 2.0 + 60, 26, 46)
	Obra.corrente(ci, 960 + w / 2.0 - 60, 26, 46)
	Obra.placa(ci, Vector2(960, 44), w, 96, txt, true, 0.0, 48)

# ---------------------------------------------------------------- 1 GANGORRA
## Valor mostrado (−100..100) no instante k: antes → peso cai → oscila amortecido até o novo valor.
func valor_gangorra(k: float) -> float:
	var ri: Dictionary = main.res_info
	if ri.is_empty() or not ri["valida"]:
		return float(main.perfil.dados["gangorra"]["valor"]) if not ri.is_empty() else 0.0
	var a := float(ri["antes"])
	var d := float(ri["depois"])
	if k < G_PESO:
		return a
	var u := clampf((k - G_PESO) / (G_BALANCA - G_PESO), 0.0, 1.0)
	return clampf(d + (a - d) * exp(-4.0 * u) * cos(u * PI * 5.0), -100.0, 100.0)

func _caixa(ci: CanvasItem, c: Vector2, cat: String, aberta: bool, t: float) -> void:
	for k in 12:   # raios
		var a := k * PI / 6.0 + t * 0.4
		ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a) * 135.0, c + Vector2.from_angle(a + 0.22) * 135.0]), Color(1.0, 0.96, 0.78, 0.7))
	var w := 126.0
	if aberta:
		ci.draw_style_box(Obra._sb(Obra.MADEIRA_D, 10, 6), Rect2(c + Vector2(-w / 2.0, -w / 2.0 + 18), Vector2(w, w - 18)))
		ci.draw_set_transform(c + Vector2(-w / 2.0, -w / 2.0), -0.45)
		ci.draw_style_box(Obra._sb(Obra.MADEIRA, 8, 6), Rect2(-10, -34, w + 20, 30))
		ci.draw_set_transform(Vector2.ZERO)
	else:
		ci.draw_style_box(Obra._sb(Obra.YEL, 12, 7), Rect2(c - Vector2(w, w) / 2.0, Vector2(w, w)))
		ci.draw_line(c + Vector2(-w / 2.0, -w / 2.0 + 28), c + Vector2(w / 2.0, -w / 2.0 + 28), INK, 5.0)
		ci.draw_line(c + Vector2(-w / 2.0, w / 2.0 - 28), c + Vector2(w / 2.0, w / 2.0 - 28), INK, 5.0)
		Kit.text(ci, c + Vector2(-60, 32), "?", 92, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120, 14)
	var ty := c.y - w / 2.0 - 64.0   # etiqueta da categoria em cima da caixa
	ci.draw_style_box(Obra._sb(Obra.CREAM, 10, 4), Rect2(c.x - 74, ty, 148, 44))
	Kit.text(ci, Vector2(c.x - 74, ty + 32), cat, 24 if cat.length() < 8 else 20, INK, HORIZONTAL_ALIGNMENT_CENTER, 148)

func _gangorra(ci: CanvasItem, k: float) -> void:
	var t: float = main.hud.t
	var ri: Dictionary = main.res_info
	_fundo(ci, t, 0.12)
	var valida: bool = not ri.is_empty() and bool(ri["valida"])
	var v := valor_gangorra(k)
	var px := 960.0
	var py := 690.0
	var ang := deg_to_rad(v / 100.0 * 15.7)
	# régua em arco atrás (verde à esquerda, vermelho à direita) e a agulha presa no pivô
	for i in 6:
		ci.draw_arc(Vector2(px, py), 330.0, PI + i * PI / 6.0, PI + (i + 1) * PI / 6.0, 12, Color(ZC[i]), 60.0, true)
	ci.draw_arc(Vector2(px, py), 360.0, PI, TAU, 48, INK, 5.0, true)
	ci.draw_arc(Vector2(px, py), 300.0, PI, TAU, 48, INK, 5.0, true)
	for i in 7:
		var a := PI + i * PI / 6.0
		ci.draw_line(Vector2(px, py) + Vector2.from_angle(a) * 300.0, Vector2(px, py) + Vector2.from_angle(a) * 360.0, INK, 5.0)
	Kit.text(ci, Vector2(px - 40, py - 372), "0", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 80, 6)
	var na := -PI / 2.0 + deg_to_rad(v * 0.9)
	var tip := Vector2(px, py) + Vector2.from_angle(na) * 340.0
	var nb := Vector2.from_angle(na + PI / 2.0) * 14.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(px, py) + nb, tip, Vector2(px, py) - nb]), INK)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(px, py) + nb * 0.5, Vector2(px, py) + Vector2.from_angle(na) * 318.0, Vector2(px, py) - nb * 0.5]), Color("#d42035"))
	# cavalete de concreto
	ci.draw_rect(Rect2(px - 120, 860, 240, 26), Color("#bdb3a0"))
	var cav := PackedVector2Array([Vector2(px - 110, 868), Vector2(px, py + 10), Vector2(px + 110, 868)])
	ci.draw_colored_polygon(cav, Color("#cfc6b4"))
	cav.append(cav[0])
	ci.draw_polyline(cav, INK, 7.0, true)
	# alvos no chão (ponta encostou = prêmio)
	for sx in [-1.0, 1.0]:
		ci.draw_set_transform(Vector2(px + sx * 690.0, 886), 0.0, Vector2(1.0, 0.18))
		ci.draw_circle(Vector2.ZERO, 90.0, Obra.YEL)
		ci.draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 32, INK, 18.0)
		ci.draw_set_transform(Vector2.ZERO)
	# tábua nas 6 cores + prêmios nas pontas + peso
	var g: Dictionary = main.perfil.dados["gangorra"]
	var cat_v := String(g["extremo_verde"])
	var cat_r := String(g["extremo_vermelho"])
	var premio_nome := ""
	var premio := String(ri.get("premio", "")) if valida else ""
	if premio != "":   # o perfil já sorteou extremos novos: a ponta premiada mostra a categoria ganha
		if float(ri["depois"]) < 0.0:
			cat_v = premio
		else:
			cat_r = premio
	cat_v = String(CAT_NOME.get(cat_v, cat_v.to_upper()))
	cat_r = String(CAT_NOME.get(cat_r, cat_r.to_upper()))
	premio_nome = String(CAT_NOME.get(premio, premio.to_upper()))
	_titulo(ci, "GANGORRA DE RECOMPENSAS", 820)
	# cartões: mostrador da luta (esq.) e legenda (dir.)
	ci.draw_style_box(Obra._sb(Obra.CREAM, 18, 5), Rect2(30, 170, 470, 200))
	var et = main.demo.etapas
	var prog: float = et.progresso if et != null and is_instance_valid(et) else 0.5
	main.hud.draw_gauge(Vector2(130, 262), 76, prog * clampf(k / G_MOSTRA, 0.0, 1.0) if valida else prog)
	var zona_nome: String = ["VERDE ESCURO", "VERDE", "AMARELO", "LARANJA", "VERMELHO", "VERMELHO ESCURO"][int(ri.get("zona", 0))] if not ri.is_empty() else ""
	Kit.text(ci, Vector2(230, 238), "a luta terminou", 28, INK, HORIZONTAL_ALIGNMENT_CENTER, 260)
	Kit.text(ci, Vector2(230, 274), "em %d%%:" % int(round(prog * 100.0)), 28, INK, HORIZONTAL_ALIGNMENT_CENTER, 260)
	Kit.text(ci, Vector2(230, 314), zona_nome, 28 if zona_nome.length() < 10 else 22, INK, HORIZONTAL_ALIGNMENT_CENTER, 260)
	ci.draw_style_box(Obra._sb(Obra.CREAM, 18, 5), Rect2(1420, 170, 470, 200))
	Kit.text(ci, Vector2(1420, 228), "VERDE puxa para: %s" % cat_v, 26, Color("#2e9e4f"), HORIZONTAL_ALIGNMENT_CENTER, 470)
	Kit.text(ci, Vector2(1420, 282), "VERMELHO puxa para: %s" % cat_r, 26, Color("#a8233a"), HORIZONTAL_ALIGNMENT_CENTER, 470)
	Kit.text(ci, Vector2(1420, 338), "ponta no chão = prêmio", 24, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, 470)
	var abre: bool = premio != "" and k >= G_BALANCA
	var L := 720.0
	var xf := Transform2D(ang, Vector2(px, py))
	ci.draw_set_transform_matrix(xf)
	for i in 6:
		ci.draw_rect(Rect2(-L + i * 2.0 * L / 6.0, -46, 2.0 * L / 6.0, 40), Color(ZC[i]))
	ci.draw_style_box(Obra._sb(Color(0, 0, 0, 0), 8, 7), Rect2(-L, -46, 2.0 * L, 40))
	ci.draw_circle(Vector2(0, -26), 16.0, Color("#8d98a4"))
	ci.draw_arc(Vector2(0, -26), 16.0, 0.0, TAU, 20, INK, 5.0)
	ci.draw_set_transform(Vector2.ZERO)
	for sx in [-1.0, 1.0]:
		var cc: Vector2 = xf * Vector2(sx * (L - 90.0), -120.0)
		var ganhou: bool = abre and (sx < 0) == (float(ri["depois"]) < 0.0)
		if ganhou:
			Kit.burst(ci, cc, 110.0 * (0.6 + 0.4 * clampf((k - G_BALANCA) / 0.4, 0.0, 1.0)), t, 5.0)
		_caixa(ci, cc, cat_v if sx < 0 else cat_r, ganhou, t)
	if valida and k >= G_MOSTRA:
		var delta := int(ri["delta"])
		var side := 1.0 if delta > 0 else -1.0
		var u := _smooth((k - G_MOSTRA) / (G_PESO - G_MOSTRA))
		var alvo: Vector2 = xf * Vector2(side * 380.0, -100.0)
		var c := Vector2(alvo.x, lerpf(-120.0, alvo.y, u * u))
		ci.draw_set_transform(c, ang if u >= 1.0 else 0.0)
		ci.draw_style_box(Obra._sb(Color(ZC[int(ri["zona"])]), 10, 7), Rect2(-70, -50, 140, 100))
		Kit.text(ci, Vector2(-70, 18), "%+d" % delta, 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 140, 10)
		ci.draw_set_transform(Vector2.ZERO)
	if abre:   # faixa no meio: o que foi ganho
		var u2 := _ease_back(clampf((k - G_BALANCA) / 0.4, 0.0, 1.0))
		ci.draw_set_transform(Vector2(960, 470), -0.04, Vector2.ONE * u2)
		ci.draw_style_box(Obra._sb(Obra.YEL, 14, 7), Rect2(-330, -60, 660, 110))
		Kit.text(ci, Vector2(-330, 22), "PRÊMIO: %s!" % premio_nome, 54, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 660, 12)
		ci.draw_set_transform(Vector2.ZERO)
	if valida:
		Kit.text(ci, Vector2(760, 992), "%+d" % int(round(v)), 60, Obra.YEL if v >= 0.0 else Color("#8fd46a"), HORIZONTAL_ALIGNMENT_CENTER, 400, 12)
		Obra.dica(ci, "PULAR  pula a animação  ·  segue para os Projetos")
	else:
		_carimbo(ci, Vector2(960, 560), "NÃO CONTOU")
		var mot := "luta curta (menos de 1 min)" if not ri.is_empty() and main.winner >= 0 else "sem vencedor"
		ci.draw_style_box(Obra._sb(Color("#fbe3dc"), 12, 5), Rect2(460, 930, 1000, 64))
		Kit.text(ci, Vector2(460, 972), mot + ": não vale para a gangorra nem para os Projetos", 26, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, 1000)
		Obra.dica(ci, "PULAR  segue para os resultados")

func _carimbo(ci: CanvasItem, c: Vector2, txt: String) -> void:
	ci.draw_set_transform(c, -0.12)
	ci.draw_style_box(Obra._sb(Color(1, 1, 1, 0.85), 14, 0), Rect2(-330, -80, 660, 160))
	var sb := Obra._sb(Color(0, 0, 0, 0), 14, 0)
	sb.border_color = Color("#d42035")
	sb.set_border_width_all(12)
	ci.draw_style_box(sb, Rect2(-330, -80, 660, 160))
	Kit.text(ci, Vector2(-330, 36), txt, 96, Color("#d42035"), HORIZONTAL_ALIGNMENT_CENTER, 660)
	ci.draw_set_transform(Vector2.ZERO)

# ---------------------------------------------------------------- 2 PROJETOS DE DEMOLIÇÃO
func _projetos(ci: CanvasItem, k: float) -> void:
	var t: float = main.hud.t
	var ri: Dictionary = main.res_info
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, 930, 1920, 150), Color("#b9ab8f"))
	ci.draw_rect(Rect2(0, 930, 1920, 60), Color("#d8ccb6"))
	for i in 9:   # tapume
		var x := -40.0 + i * 230.0
		ci.draw_rect(Rect2(x, 170, 236, 760), Color("#7fae86") if i % 2 == 0 else Color("#86b48c"))
		ci.draw_rect(Rect2(x, 170, 236, 760), Color("#4d7a56"), false, 3.0)
	Obra.zebra(ci, Rect2(0, 150, 1920, 26))
	Obra.zebra(ci, Rect2(0, 920, 1920, 18))
	_titulo(ci, "PROJETOS DE DEMOLIÇÃO", 860)
	# prancheta: cada ganho numa linha
	var folha := Obra.prancheta(ci, Rect2(70, 230, 760, 640), "NESTA PARTIDA", Color("#3f7fb5"))
	var linhas := _linhas()
	var y := folha.position.y + 90.0
	var mostrados := 0   # pontos já entregues (andares que caem)
	var tl := P_INICIO
	for ln in linhas:
		var on := k >= tl
		var pts: int = ln["pts"]
		if on:
			var aceso := k < tl + P_LINHA + pts * P_ANDAR
			if aceso:
				ci.draw_style_box(Obra._sb(Color("#fff0b8"), 10, 5), Rect2(100, y - 46, 700, 96))
			Kit.text(ci, Vector2(116, y + 12), ln["icone"], 40, Color("#3f9e55") if ln["icone"] == "✔" else Color("#e0a21e"))
			Kit.text(ci, Vector2(170, y + 4), ln["txt"], 32, INK)
			Kit.text(ci, Vector2(170, y + 34), ln["sub"], 20, Kit.SOFT)
			for b in pts:
				var tb := tl + P_LINHA * 0.5 + b * P_ANDAR
				if k >= tb:
					ci.draw_style_box(Obra._sb(Color("#d42035"), 3, 3), Rect2(610 + b * 42, y - 20, 34, 20))
					mostrados += 1
			Kit.text(ci, Vector2(700, y + 10), "+%d" % pts, 38, INK, HORIZONTAL_ALIGNMENT_RIGHT, 90)
		y += 110.0
		tl += P_LINHA + pts * P_ANDAR
	var fim_linhas := k >= tl
	var ganho := int(ri.get("pontos", 0))
	if fim_linhas:
		for xx in range(110, 790, 20):
			ci.draw_line(Vector2(xx, y - 40), Vector2(xx + 12, y - 40), INK, 4.0)
		Kit.text(ci, Vector2(130, y + 14), "TOTAL", 36, INK)
		Kit.text(ci, Vector2(640, y + 20), "+%d" % ganho, 52, Obra.YEL, HORIZONTAL_ALIGNMENT_RIGHT, 150, 12)
	Kit.text(ci, Vector2(folha.position.x, folha.end.y - 20), "cena nova só conta 1 vez por mapa · luta curta não conta", 20, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, folha.size.x)
	# planta azul: prédio de N andares; cada ponto derruba um andar
	var pm := int(ri.get("por_mapa", 6))
	var total := int(ri.get("total", 0))
	var antes := maxi(total - ganho, 0)
	var caidos := mini(antes + mostrados, pm)
	var bx := 900.0
	var by := 220.0
	var bw := 940.0
	var bh := 650.0
	ci.draw_rect(Rect2(bx + 8, by + 12, bw, bh), Color(INK, 0.35))
	ci.draw_style_box(Obra._sb(Color("#2f6fb0"), 8, 6), Rect2(bx, by, bw, bh))
	for gx in range(int(bx) + 40, int(bx + bw), 40):
		ci.draw_line(Vector2(gx, by + 6), Vector2(gx, by + bh - 6), Color(1, 1, 1, 0.16), 1.0)
	for gy in range(int(by) + 40, int(by + bh), 40):
		ci.draw_line(Vector2(bx + 6, gy), Vector2(bx + bw - 6, gy), Color(1, 1, 1, 0.16), 1.0)
	Kit.text(ci, Vector2(bx + 30, by + 58), "PROJETO · PRÓXIMO MAPA", 30, Color.WHITE)
	var fx := bx + 120.0
	var fw := 400.0
	var fh := minf(74.0, 450.0 / pm)
	var base := by + bh - 70.0
	for i in pm:
		var y0 := base - (i + 1) * fh
		var r := Rect2(fx, y0, fw, fh)
		if i < caidos:
			for xx in range(int(fx), int(fx + fw), 18):   # contorno tracejado (andar que já caiu)
				ci.draw_line(Vector2(xx, y0), Vector2(xx + 10, y0), Color(1, 1, 1, 0.5), 3.0)
			var novo := i >= antes
			ci.draw_set_transform(r.get_center(), -0.1)
			var sb := Obra._sb(Color(0, 0, 0, 0), 6, 0)
			sb.border_color = Color("#ff5a5a") if novo else Color(1, 0.55, 0.55, 0.55)
			sb.set_border_width_all(5)
			ci.draw_style_box(sb, Rect2(-110, -fh * 0.32, 220, fh * 0.64))
			Kit.text(ci, Vector2(-110, fh * 0.14), "DEMOLIDO", int(fh * 0.38), sb.border_color, HORIZONTAL_ALIGNMENT_CENTER, 220)
			ci.draw_set_transform(Vector2.ZERO)
			Kit.text(ci, Vector2(fx - 60, y0 + fh * 0.65), "%d" % (i + 1), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 40)
		else:
			ci.draw_rect(r, Color.WHITE, false, 4.0)
			for wx in 4:
				ci.draw_rect(Rect2(fx + 40 + wx * 90, y0 + fh * 0.27, 44, fh * 0.46), Color.WHITE, false, 3.0)
			Kit.text(ci, Vector2(fx - 60, y0 + fh * 0.65), "%d" % (i + 1), 30, Obra.YEL if i == caidos else Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 40)
	ci.draw_line(Vector2(fx - 40, base), Vector2(fx + fw + 40, base), Color.WHITE, 6.0)
	# bola de demolição: balança e bate no próximo andar
	var gx := fx + fw + 170.0
	var alvo_y := base - (mini(caidos, pm - 1) + 0.5) * fh
	var bate := absf(sin(k * 4.0))
	var bola := Vector2(gx - 10.0 - 90.0 * bate, alvo_y)
	ci.draw_line(Vector2(gx + 120, by + 80), bola, Color.WHITE, 5.0)
	ci.draw_circle(bola, 52.0, Color("#4a4f5c"))
	ci.draw_arc(bola, 52.0, 0.0, TAU, 32, INK, 6.0)
	if caidos < pm and bate > 0.92:
		Kit.burst(ci, Vector2(fx + fw + 20, alvo_y), 46.0, t, 4.0)
	ci.draw_style_box(Obra._sb(Obra.CREAM, 14, 5), Rect2(gx - 130, base - 230, 330, 200))
	Kit.text(ci, Vector2(gx - 130, base - 180), "ANTES  %d" % mini(antes, pm), 30, INK, HORIZONTAL_ALIGNMENT_CENTER, 330)
	Kit.text(ci, Vector2(gx - 130, base - 135), "+%d AGORA" % mostrados, 30, Color("#d42035"), HORIZONTAL_ALIGNMENT_CENTER, 330)
	Kit.text(ci, Vector2(gx - 130, base - 62), "%d / %d" % [caidos, pm], 52, Obra.YEL, HORIZONTAL_ALIGNMENT_CENTER, 330, 12)
	var falta := pm - mini(total, pm)
	var msg := ("PROJETO COMPLETO → MAPA NOVO!" if falta <= 0 else "falta %d %s → MAPA NOVO (você escolhe qual)" % [falta, "andar" if falta == 1 else "andares"])
	ci.draw_style_box(Obra._sb(Obra.YEL, 12, 5), Rect2(bx + 40, by + bh + 20, bw - 80, 56))
	Kit.text(ci, Vector2(bx + 40, by + bh + 58), msg, 28, INK, HORIZONTAL_ALIGNMENT_CENTER, bw - 80)
	Obra.dica(ci, "PULAR  pula a animação  ·  segue para os resultados")

# ---------------------------------------------------------------- 3 RESULTADOS
## Melhor valor de cada coluna (CAIU SOZINHO: o menor). Só destaca se alguém fez algo.
func _melhores() -> Dictionary:
	var out := {}
	for c in COLS:
		var key: String = c[1]
		var vals: Array = main.players.map(func(p): return int(p["stats"].get(key, 0)))
		if vals.is_empty():
			continue
		var best: int = vals.min() if key == "quedas" else vals.max()
		if key != "quedas" and best <= 0:
			continue
		out[key] = best
	return out

## Título de cada jogador: a 1ª coluna em que ele é o melhor sozinho.
func titulo_de(i: int) -> String:
	for key in ["derrubadas", "caixotes", "engenhocas", "golpes"]:
		var v := int(main.players[i]["stats"].get(key, 0))
		if v <= 0:
			continue
		var unico := true
		for j in main.players.size():
			if j != i and int(main.players[j]["stats"].get(key, 0)) >= v:
				unico = false
		if unico:
			return TITULOS[key]
	return ""

func _resultados(ci: CanvasItem) -> void:
	var t: float = main.hud.t
	_fundo(ci, t, 0.08)
	for k in 50:   # confete
		var x := fposmod(k * 137.0 + t * (40 + k % 7 * 15), 1920.0)
		var y := fposmod(k * 71.0 + t * (120 + k % 5 * 30), 1080.0)
		ci.draw_set_transform(Vector2(x, y), t * (2.0 + k % 3) + k)
		ci.draw_rect(Rect2(-9, -12, 18, 24), INK)
		ci.draw_rect(Rect2(-7, -10, 14, 20), Data.COLORS[k % 4])
	ci.draw_set_transform(Vector2.ZERO)
	var w: int = main.winner
	_titulo(ci, ("P%d  VENCEU!" % (w + 1)) if w >= 0 else "EMPATE!", 640)
	# vencedor em cima do palete de caixotes (sem o círculo com estrela)
	for k in 3:
		ci.draw_texture_rect(Data.tex("cenario/caixote_%d" % k), Rect2(90 + k * 110, 770, 110, 110), false)
	if w >= 0:
		var pw: Dictionary = main.players[w]
		RobotVis.draw_robot(ci, {"color": pw["color"], "model": pw["model"], "skin": String(pw.get("skin", ""))}, RobotVis.victory_pose(t, int(Data.model_meta(pw["model"])["danca"])), Transform2D(0.0, Vector2(3.0, 3.0), 0.0, Vector2(255, 770)))
		ci.draw_set_transform(Vector2.ZERO)
		var sc := int(pw["score"])
		ci.draw_style_box(Obra._sb(Obra.CREAM, 14, 5), Rect2(90, 200, 330, 72))
		for s in mini(sc, 5):
			Kit.star(ci, Vector2(130 + s * 44, 236), 38, true)
		Kit.text(ci, Vector2(130 + mini(sc, 5) * 44 - 10, 248), ("×%d " % sc if sc > 5 else "") + "sessão", 26, Color("#e0a21e"))
	# quadro de estatísticas
	var q := Rect2(470, 190, 960, 680)
	Obra.quadro(ci, q)
	ci.draw_style_box(Obra._sb(Obra.CREAM, 6, 4), q.grow(-22))
	var cx0 := q.position.x + 330.0
	for j in COLS.size():
		Kit.text(ci, Vector2(cx0 + j * 120 - 60, q.position.y + 74), COLS[j][0], 17, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, 120)
	var best := _melhores()
	var rk: Array = main.demo.ranking()
	var rowh := minf(120.0, 540.0 / maxf(rk.size(), 1.0) - 16.0)
	for k in rk.size():
		var i: int = rk[k]
		var p: Dictionary = main.players[i]
		var y := q.position.y + 100 + k * (rowh + 16.0)
		var row := Rect2(q.position.x + 34, y, q.size.x - 68, rowh)
		ci.draw_style_box(Obra._sb(Color("#dff3d6") if k == 0 and w >= 0 else Color("#f6eedb"), 12, 4), row)
		Kit.text(ci, Vector2(row.position.x + 14, y + rowh * 0.64), "%dº" % (k + 1), 40, INK)
		RobotVis.draw_robot(ci, {"color": p["color"], "model": p["model"], "skin": String(p.get("skin", ""))}, RobotVis.idle_pose(t + i), Transform2D(0.0, Vector2(1.05, 1.05), 0.0, Vector2(row.position.x + 140, y + rowh - 8)))
		ci.draw_set_transform(Vector2.ZERO)
		Kit.text(ci, Vector2(row.position.x + 180, y + rowh * 0.5), "P%d" % (i + 1), 34, Data.COLORS[p["color"]], HORIZONTAL_ALIGNMENT_CENTER, 72, 7)
		var tit := titulo_de(i)
		if tit != "":
			Kit.text(ci, Vector2(row.position.x + 156, y + rowh * 0.82), tit, 16, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, 120)
		for j in COLS.size():
			var key: String = COLS[j][1]
			var v := int(p["stats"].get(key, 0))
			var c := Vector2(cx0 + j * 120, y + rowh * 0.5)
			if best.has(key) and v == int(best[key]):
				ci.draw_circle(c, 34.0, Obra.YEL)
				ci.draw_arc(c, 34.0, 0.0, TAU, 32, INK, 4.0)
			Kit.text(ci, c + Vector2(-60, 14), str(v), 38, INK, HORIZONTAL_ALIGNMENT_CENTER, 120)
	# cronômetro + opções
	var tot := cronometro_s()
	var seg := int(ceil(maxf(main.res_crono, 0.0)))
	var c0 := Vector2(1660, 300)
	ci.draw_circle(c0 + Vector2(0, 8), 92.0, INK)
	ci.draw_circle(c0, 92.0, Obra.CREAM)
	var frac := clampf(main.res_crono / tot, 0.0, 1.0)
	if frac > 0.0:
		var pts := PackedVector2Array([c0])
		for s in 33:
			pts.append(c0 + Vector2.from_angle(-PI / 2.0 + TAU * frac * s / 32.0) * 75.0)
		ci.draw_colored_polygon(pts, Obra.YEL)
		ci.draw_polyline(pts, INK, 3.0, true)
	ci.draw_arc(c0, 92.0, 0.0, TAU, 40, INK, 7.0, true)
	ci.draw_style_box(Obra._sb(Color("#8d98a4"), 5, 4), Rect2(c0.x - 18, c0.y - 114, 36, 20))
	Kit.text(ci, Vector2(c0.x - 90, c0.y + 24), str(seg), 66, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 180, 12)
	Kit.text(ci, Vector2(c0.x - 200, c0.y + 130), "escolhe sozinho em %d s" % seg, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 400, 6)
	for k in main.RES_OPCOES.size():
		var on: bool = k == main.res_sel
		Obra.placa(ci, Vector2(1660, 460 + k * 104), 430.0 if on else 400.0, 84, main.RES_OPCOES[k], on, (sin(t * 3.0) * 0.02) if on else 0.0, 40 if on else 34)
	Obra.dica(ci, "▲▼ escolher  ·  PULAR confirmar  ·  quando o relógio zera, vale a opção marcada")

func cronometro_s() -> float:
	return float(MapaReg.modo_cfg("derruba").get("progressao", {}).get("resultados_cronometro_s", 15))
