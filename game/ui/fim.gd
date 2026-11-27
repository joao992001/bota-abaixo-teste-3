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
const G_SAI := 0.7       # 2 · a gangorra sai de cena, o presente sobe
const G_VOA := 0.8       # 3 · o presente voa ao centro
const G_ABRE := 1.0      # 4 · treme e abre
const G_REVELA := 1.6    # 5 · o prêmio
const G_PREMIO := G_SAI + G_VOA + G_ABRE + G_REVELA   # só se chegar a ±100
const P_INICIO := 0.6
const P_LINHA := 0.7
const P_ANDAR := 0.35

## Duração da animação de cada tela (1º PULAR pula a animação; depois disso PULAR segue — nunca sozinha).
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

# ---- arte da gangorra A e das caixas (art/src/ui/premio_export.py; pranchas g1–g3 aprovadas em 2026-11-27)
const CX_VB := Rect2(-180, -350, 360, 470)      # moldura comum das 3 camadas da caixa (unidades; origem = centro)
const VIGA_VB := Rect2(-430, -40, 860, 84)      # origem = pivô
const CESTO_VB := Rect2(-90, -12, 180, 240)     # origem = onde pendura
const GANCHO_VB := Rect2(-44, -110, 88, 136)    # origem = pivô da viga
const GA_S := 1.35                              # unidades do desenho → px na tela
const GA_PIVO := Vector2(960, 410)
const GA_CHAO := 884.0
const GA_PONTA := 370.0                         # onde os cestos penduram (unidades a partir do pivô)
const CESTO_CAIXA := Vector2(0, 114)            # centro da caixa dentro do cesto (unidades)
const CESTO_K := 0.62                           # tamanho da caixa no cesto
const CAIXA_CENTRO := Vector2(960, 600)
const CAIXA_GRANDE := 1.9
const BANNER := {"skin": "SKIN NOVA!", "spell": "ENGENHOCA NOVA!", "evento": "EVENTO NOVO!"}
var _k_prev := -1.0

func _peca(ci: CanvasItem, nome: String, vb: Rect2, xf: Transform2D, mod := Color.WHITE) -> void:
	var tx: Texture2D = Data.tex("premio/" + nome)
	if tx == null:
		return
	ci.draw_set_transform_matrix(xf)
	ci.draw_texture_rect(tx, vb, false, mod)
	ci.draw_set_transform(Vector2.ZERO)

## Caixa de prêmio que diz a categoria pela forma (figurino / maleta de aço / caixote com sirene).
## xf = posição+giro+escala (unidades do desenho); tampa 0..1 (voa para o lado); sobe 0..1 = conteúdo saindo.
func caixa(ci: CanvasItem, cat: String, xf: Transform2D, tampa := 0.0, sobe := 0.0, alpha := 1.0) -> void:
	if not cat in BANNER:
		cat = "skin"
	var m := Color(1, 1, 1, alpha)
	if tampa > 0.0:
		_peca(ci, "caixa_%s_conteudo" % cat, CX_VB, xf * Transform2D(0.0, Vector2(0, 90.0 + (1.0 - sobe) * 150.0)), Color(1, 1, 1, alpha * clampf(sobe * 3.0, 0.0, 1.0)))
	_peca(ci, "caixa_%s_corpo" % cat, CX_VB, xf, m)
	var tl := xf * Transform2D(0.0, Vector2(190.0 * tampa, -200.0 * tampa)) * Transform2D(0.0, Vector2(0, -75)) \
		* Transform2D(deg_to_rad(40.0 * tampa), Vector2.ZERO) * Transform2D(0.0, Vector2(0, 75))
	_peca(ci, "caixa_%s_tampa" % cat, CX_VB, tl, Color(1, 1, 1, alpha * clampf(2.0 - tampa * 1.6, 0.0, 1.0)))

static func _esc(s: float, pos: Vector2, rot := 0.0) -> Transform2D:
	return Transform2D(rot, Vector2(s, s), 0.0, pos)

## Ângulo máximo da viga: a ponta ganhadora leva o cesto até o chão.
static func ga_amax() -> float:
	return asin(clampf((GA_CHAO - 218.0 * GA_S - GA_PIVO.y - 32.0 * GA_S) / (GA_PONTA * GA_S), 0.0, 1.0))

## Onde fica a caixa do cesto (lado sx = −1 verde / +1 vermelho) com a gangorra no valor v (−100..100).
func caixa_no_cesto(v: float, sx: float, dy := 0.0, balanco := 0.0) -> Vector2:
	var ang := v / 100.0 * ga_amax()
	var pend: Vector2 = Transform2D(ang, GA_PIVO + Vector2(0, dy)) * (Vector2(sx * GA_PONTA, 32.0) * GA_S)
	return pend + (CESTO_CAIXA * GA_S).rotated(balanco)

## Item ganho (sorteado uma vez e guardado em res_info): skin do mapa (de preferência do robô do vencedor),
## uma engenhoca ou um evento com ícone. Hoje tudo já está liberado (A9): é a revelação do que saiu.
func premio_item() -> Dictionary:
	var ri: Dictionary = main.res_info
	if ri.has("premio_item"):
		return ri["premio_item"]
	var cat := String(ri.get("premio", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d" % [cat, main.perfil.dados.get("premios", []).size()])
	var it := {"cat": cat, "nome": String(CAT_NOME.get(cat, cat.to_upper())), "id": ""}
	match cat:
		"skin":
			var w := clampi(main.winner, 0, maxi(main.players.size() - 1, 0))
			var p: Dictionary = main.players[w] if w < main.players.size() else {"color": 0, "model": 0}
			it["color"] = p.get("color", 0)
			it["model"] = int(p.get("model", 0))
			var nome_robo: String = Data.MODELS[posmod(int(it["model"]), Data.MODELS.size())]
			var ks: Array = MapaReg.manifesto(main.game_mode, String(main.level.id) if main.level != null else "").get("skins_originadas", [])
			var esc = null
			for k in ks:
				if k is Dictionary and String(k.get("robo", "")) == nome_robo:
					esc = k
			if esc == null and not ks.is_empty():
				esc = ks[rng.randi() % ks.size()]
				it["model"] = maxi(Data.MODELS.find(String(esc.get("robo", ""))), 0)
			if esc != null:
				it["id"] = String(esc["id"]).to_lower()
				it["nome"] = String(esc.get("nome", esc["id"])).to_upper()
		"spell":
			var todas := []
			for pool in main.demo.cfg["spells"]["pools"].values():
				if pool is Array:
					for k in pool:
						if not k in todas:
							todas.append(k)
			if not todas.is_empty():
				var id: String = todas[rng.randi() % todas.size()]
				it["id"] = id
				it["icone"] = String(main.demo.cfg["spells"].get(id, {}).get("icone", ""))
				it["nome"] = String(preload("res://modes/spells.gd").NOMES.get(id, id)).to_upper()
		"evento":
			var com_icone := []
			for e in main.events.cfg["lista"]:
				if String(e.get("icone", "")) != "":
					com_icone.append(e)
			if not com_icone.is_empty():
				var e: Dictionary = com_icone[rng.randi() % com_icone.size()]
				it["id"] = String(e["id"])
				it["icone"] = String(e["icone"])
				it["nome"] = String(e.get("nome", e["id"])).to_upper()
	ri["premio_item"] = it
	return it

func _som(k: float, t0: float, nome: String) -> void:
	if _k_prev < t0 and k >= t0 and k - _k_prev < 0.5:
		Audio.play(nome)

func _gangorra(ci: CanvasItem, k: float) -> void:
	var t: float = main.hud.t
	var ri: Dictionary = main.res_info
	var valida: bool = not ri.is_empty() and bool(ri["valida"])
	var premio := String(ri.get("premio", "")) if valida else ""
	var q := k - G_BALANCA   # tempos do presente (só com prêmio)
	var sai := _smooth(q / G_SAI) if premio != "" and q > 0.0 else 0.0
	_fundo(ci, t, 0.12 + 0.5 * sai)
	var v := valor_gangorra(k)
	var amax := ga_amax()
	var ang := v / 100.0 * amax
	var dy := sai * sai * 900.0   # 2 · SAI DE CENA: a gangorra desce e some
	var pivo := GA_PIVO + Vector2(0, dy)
	var g: Dictionary = main.perfil.dados["gangorra"]
	var cat_v := String(g["extremo_verde"])
	var cat_r := String(g["extremo_vermelho"])
	var lado_ganho := 0.0
	if premio != "":   # o perfil já sorteou extremos novos: a ponta premiada mostra a categoria ganha
		lado_ganho = -1.0 if float(ri["depois"]) < 0.0 else 1.0
		if lado_ganho < 0.0:
			cat_v = premio
		else:
			cat_r = premio
	if q < G_SAI * 0.8:   # no presente a tela é dele: o título sai
		_titulo(ci, "GANGORRA DE RECOMPENSAS", 820)
	# cabo da grua → gancho → viga nas 6 cores → cestos pendurados (sempre na vertical, balançando um pouco)
	ci.draw_line(Vector2(960, 140), pivo + Vector2(0, -100.0 * GA_S), Color("#4a4f5c"), 6.0)
	for sx in [-1.0, 1.0]:   # alvos no chão (cesto encostou = prêmio)
		ci.draw_set_transform(Vector2(GA_PIVO.x + sx * GA_PONTA * GA_S, GA_CHAO + 4 + dy), 0.0, Vector2(1.0, 0.18))
		ci.draw_circle(Vector2.ZERO, 110.0, Obra.YEL)
		ci.draw_arc(Vector2.ZERO, 110.0, 0.0, TAU, 32, INK, 18.0)
		ci.draw_set_transform(Vector2.ZERO)
	_peca(ci, "gangorra_gancho", GANCHO_VB, _esc(GA_S, pivo))
	var xf := Transform2D(ang, pivo)
	_peca(ci, "gangorra_viga", VIGA_VB, xf * Transform2D(0.0, Vector2(GA_S, GA_S), 0.0, Vector2.ZERO))
	var dv := valor_gangorra(k) - valor_gangorra(maxf(k - 0.06, 0.0))
	var balanco := clampf(-dv * 0.012, -0.3, 0.3)
	for sx in [-1.0, 1.0]:
		var pend: Vector2 = xf * (Vector2(sx * GA_PONTA, 32.0) * GA_S)
		var ganhou: bool = premio != "" and sx == lado_ganho
		if not (ganhou and q > 0.0):   # a caixa ganhadora sai do cesto (desenhada à parte)
			var cc := pend + (CESTO_CAIXA * GA_S).rotated(balanco)
			if ganhou and k > G_BALANCA - 0.5:
				Kit.burst(ci, cc, 90.0, t, 5.0)
			caixa(ci, cat_v if sx < 0 else cat_r, _esc(GA_S * CESTO_K, cc, balanco))
		_peca(ci, "gangorra_cesto", CESTO_VB, _esc(GA_S, pend, balanco))
	if valida and k >= G_MOSTRA:   # o peso da luta cai na viga
		var delta := int(ri["delta"])
		var side := 1.0 if delta > 0 else -1.0
		var u := _smooth((k - G_MOSTRA) / (G_PESO - G_MOSTRA))
		var alvo: Vector2 = xf * Vector2(side * 230.0 * GA_S, -2.0 * GA_S - 50.0)
		var c := Vector2(alvo.x, lerpf(-120.0, alvo.y, u * u))
		ci.draw_set_transform(c, ang if u >= 1.0 else 0.0)
		ci.draw_style_box(Obra._sb(Color(ZC[int(ri["zona"])]), 10, 7), Rect2(-70, -50, 140, 100))
		Kit.text(ci, Vector2(-70, 18), "%+d" % delta, 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 140, 10)
		ci.draw_set_transform(Vector2.ZERO)
	# cartões: mostrador da luta (esq.) e para onde cada cor puxa (dir.) — descem junto com a gangorra
	var cy := 170.0 + dy
	ci.draw_style_box(Obra._sb(Obra.CREAM, 18, 5), Rect2(30, cy, 430, 170))
	var et = main.demo.etapas
	var prog: float = et.progresso if et != null and is_instance_valid(et) else 0.5
	main.hud.draw_gauge(Vector2(122, cy + 86), 68, prog * clampf(k / G_MOSTRA, 0.0, 1.0) if valida else prog)
	var zona_nome: String = ["VERDE ESCURO", "VERDE", "AMARELO", "LARANJA", "VERMELHO", "VERMELHO ESCURO"][int(ri.get("zona", 0))] if not ri.is_empty() else ""
	Kit.text(ci, Vector2(205, cy + 58), "a luta terminou", 28, INK, HORIZONTAL_ALIGNMENT_CENTER, 250)
	Kit.text(ci, Vector2(205, cy + 94), "em %d%%:" % int(round(prog * 100.0)), 28, INK, HORIZONTAL_ALIGNMENT_CENTER, 250)
	Kit.text(ci, Vector2(205, cy + 134), zona_nome, 28 if zona_nome.length() < 10 else 22, INK, HORIZONTAL_ALIGNMENT_CENTER, 250)
	ci.draw_style_box(Obra._sb(Obra.CREAM, 18, 5), Rect2(1460, cy, 430, 170))
	Kit.text(ci, Vector2(1460, cy + 52), "VERDE puxa para: %s" % CAT_NOME.get(cat_v, cat_v.to_upper()), 22, Color("#2e9e4f"), HORIZONTAL_ALIGNMENT_CENTER, 430)
	Kit.text(ci, Vector2(1460, cy + 100), "VERMELHO puxa para: %s" % CAT_NOME.get(cat_r, cat_r.to_upper()), 22, Color("#a8233a"), HORIZONTAL_ALIGNMENT_CENTER, 430)
	Kit.text(ci, Vector2(1460, cy + 146), "cesto no chão = prêmio", 24, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, 430)
	if premio != "" and q > 0.0:
		_presente(ci, q, premio, lado_ganho, t)
	if premio != "":
		_som(k, G_BALANCA - 0.4, "capacete")
		_som(k, G_BALANCA + G_SAI + G_VOA, "bonk_1")
		_som(k, G_BALANCA + G_SAI + G_VOA + G_ABRE * 0.55, "item")
		_som(k, G_BALANCA + G_SAI + G_VOA + G_ABRE, "rodada_vence")
	_k_prev = k
	if valida:
		if sai <= 0.0:
			Kit.text(ci, Vector2(760, 1000), "%+d" % int(round(v)), 60, Obra.YEL if v >= 0.0 else Color("#8fd46a"), HORIZONTAL_ALIGNMENT_CENTER, 400, 12)
		Obra.dica(ci, ("PULAR  segue para os Projetos" if k >= duracao("gangorra") else "PULAR  pula a animação"))
	else:
		_carimbo(ci, Vector2(960, 560), "NÃO CONTOU")
		var mot := "luta curta (menos de 1 min)" if not ri.is_empty() and main.winner >= 0 else "sem vencedor"
		ci.draw_style_box(Obra._sb(Color("#fbe3dc"), 12, 5), Rect2(460, 930, 1000, 64))
		Kit.text(ci, Vector2(460, 972), mot + ": não vale para a gangorra nem para os Projetos", 26, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, 1000)
		Obra.dica(ci, "PULAR  segue para os resultados")

## Tempos 2–5 do presente (q = segundos depois que a gangorra decidiu): sobe do cesto → voa girando ao centro e
## cresce → treme 3× e a tampa estoura (raios + confete) → o prêmio GRANDE no pedestal, com nome e selo NOVO.
func _presente(ci: CanvasItem, q: float, cat: String, lado: float, t: float) -> void:
	var p0 := caixa_no_cesto(lado * 100.0, lado)
	var s0 := GA_S * CESTO_K
	var p1 := p0 + Vector2(0, -230)
	var pos := p0
	var s := s0
	var rot := 0.0
	var tampa := 0.0
	var sobe := 0.0
	var alpha := 1.0
	var brilho := 0.0
	var q2 := q - G_SAI
	var q3 := q2 - G_VOA
	var q4 := q3 - G_ABRE
	if q2 < 0.0:   # 2 · sobe do cesto enquanto a gangorra desce
		var u := _ease_back(clampf(q / G_SAI, 0.0, 1.0))
		pos = p0.lerp(p1, u)
		s = s0 * (1.0 + 0.15 * u)
	elif q3 < 0.0:   # 3 · voa ao centro girando e crescendo
		var u := _smooth(q2 / G_VOA)
		var ctrl := Vector2((p1.x + CAIXA_CENTRO.x) / 2.0, minf(p1.y, CAIXA_CENTRO.y) - 260.0)
		pos = p1.lerp(ctrl, u).lerp(ctrl.lerp(CAIXA_CENTRO, u), u)
		s = lerpf(s0 * 1.15, CAIXA_GRANDE, u)
		rot = -lado * u * TAU
	else:
		pos = CAIXA_CENTRO
		s = CAIXA_GRANDE
		var u3 := clampf(q3 / G_ABRE, 0.0, 1.0)
		if u3 < 0.55:   # 4 · treme 3×
			var f := u3 / 0.55 * 3.0
			var amp := absf(sin(f * PI)) * (0.5 + 0.5 * f / 3.0)
			pos += Vector2(sin(q3 * 70.0) * 14.0 * amp, -absf(sin(f * PI)) * 18.0)
			rot = sin(q3 * 55.0) * 0.08 * amp
			s *= 1.0 + 0.05 * amp
		else:
			tampa = clampf((u3 - 0.55) / 0.22, 0.0, 1.0)
			sobe = _ease_back(clampf((u3 - 0.55) / 0.4, 0.0, 1.0))
			brilho = clampf((u3 - 0.55) / 0.3, 0.0, 1.0)
	if q4 >= 0.0:   # 5 · o prêmio
		tampa = 1.0
		sobe = 1.0
		brilho = 1.0
		alpha = clampf(1.0 - q4 / 0.3, 0.0, 1.0)
		pos = CAIXA_CENTRO + Vector2(0, 260.0 * _smooth(q4 / 0.3))
	if brilho > 0.0:   # raios girando atrás
		var rc := CAIXA_CENTRO + Vector2(0, -60)
		for i in 16:
			var a := i * TAU / 16.0 + t * 0.35
			ci.draw_colored_polygon(PackedVector2Array([rc, rc + Vector2.from_angle(a) * 1300.0 * brilho, rc + Vector2.from_angle(a + 0.18) * 1300.0 * brilho]), Color(1.0, 0.95, 0.75, 0.32))
	if alpha > 0.0:
		caixa(ci, cat, _esc(s, pos, rot), tampa, sobe, alpha)
	if brilho > 0.0:   # confete
		var qc := maxf(q3 - G_ABRE * 0.55, 0.0)
		var cols := [Color("#d42035"), Color("#5cc45c"), Color("#4f86d9"), Obra.YEL, Color("#d9539b")]
		for i in 46:
			var a := -PI / 2.0 + (fposmod(i * 0.618, 1.0) - 0.5) * 2.6
			var vv := 700.0 + fposmod(i * 0.377, 1.0) * 700.0
			var pc := CAIXA_CENTRO + Vector2(0, -120) + Vector2.from_angle(a) * vv * qc + Vector2(0, 900.0 * qc * qc)
			if pc.y > 1100.0:
				continue
			ci.draw_set_transform(pc, qc * 9.0 + i)
			ci.draw_rect(Rect2(-7, -11, 14, 22), cols[i % cols.size()])
			ci.draw_set_transform(Vector2.ZERO)
	if q4 >= 0.0:
		_revela(ci, q4, cat, t)

func _revela(ci: CanvasItem, q: float, cat: String, t: float) -> void:
	var it := premio_item()
	var u := _ease_back(clampf(q / 0.45, 0.0, 1.0))
	var c := Vector2(960, 560)
	# pedestal
	ci.draw_set_transform(c + Vector2(0, 250), 0.0, Vector2(u, u * 0.22))
	ci.draw_circle(Vector2.ZERO, 230.0, Color("#8d98a4"))
	ci.draw_arc(Vector2.ZERO, 230.0, 0.0, TAU, 48, INK, 24.0)
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_rect(Rect2(c.x - 228 * u, c.y + 250, 456 * u, 60), Color("#6b7684"))
	ci.draw_rect(Rect2(c.x - 228 * u, c.y + 304, 456 * u, 8), INK)
	match cat:
		"skin":   # o robô vestindo a skin, girando no pedestal (escala x = cosseno: mesa giratória)
			var gira := cos(t * 1.6)
			var sx := (absf(gira) * 0.8 + 0.2) * signf(gira if absf(gira) > 0.001 else 1.0)
			RobotVis.draw_robot(ci, {"color": it.get("color", 0), "model": it.get("model", 0), "skin": String(it.get("id", ""))},
				RobotVis.idle_pose(t), Transform2D(0.0, Vector2(5.0 * sx, 5.0) * u, 0.0, c + Vector2(0, 252)))
		_:   # engenhoca / evento: o ícone grande flutuando com brilho
			var tx: Texture2D = Data.tex("spells/" + String(it.get("icone", "")))   # ícones de engenhoca e de evento moram em spells/
			var y := c.y - 20 + sin(t * 2.2) * 14.0
			ci.draw_circle(Vector2(c.x, y), 190.0 * u, Color(1.0, 0.97, 0.8, 0.55))
			if tx != null:
				var k := 360.0 / maxf(tx.get_width(), tx.get_height()) * u
				var sz := Vector2(tx.get_width(), tx.get_height()) * k
				ci.draw_texture_rect(tx, Rect2(Vector2(c.x, y) - sz / 2.0, sz), false)
	# faixa da categoria (cai de cima) e nome grande
	var ub := _ease_back(clampf((q - 0.15) / 0.4, 0.0, 1.0))
	var by := lerpf(-120.0, 110.0, ub)
	ci.draw_set_transform(Vector2(960, by), -0.03)
	Kit.chunk(ci, Rect2(-300, -58, 600, 116), Obra.YEL, 16, 7, 10.0)
	Kit.text(ci, Vector2(-300, 22), BANNER.get(cat, "PRÊMIO!"), 60, INK, HORIZONTAL_ALIGNMENT_CENTER, 600)
	ci.draw_set_transform(Vector2.ZERO)
	if q > 0.35:
		var un := _ease_back(clampf((q - 0.35) / 0.35, 0.0, 1.0))
		ci.draw_set_transform(Vector2(960, 930), 0.0, Vector2(un, un))
		Kit.text(ci, Vector2(-700, 30), String(it.get("nome", "")), 80, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1400, 16)
		ci.draw_set_transform(Vector2(1160, 400), 0.25, Vector2(un, un))
		ci.draw_style_box(Obra._sb(Color("#d42035"), 10, 6), Rect2(-80, -32, 160, 64))
		Kit.text(ci, Vector2(-80, 16), "NOVO", 40, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 160)
		ci.draw_set_transform(Vector2.ZERO)

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
	Obra.dica(ci, ("PULAR  segue para os resultados" if k >= duracao("projetos") else "PULAR  pula a animação"))

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
