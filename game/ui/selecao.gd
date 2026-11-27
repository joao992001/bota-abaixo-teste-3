extends RefCounted
## AJUSTES DA PARTIDA em ETAPAS OBRIGATÓRIAS (A21, interface "Canteiro vivo", pranchas art/out/menus_v2/):
## 1 ENGENHOCAS → 2 EVENTOS → 3 VIDAS → 4 JOGADORES (tela de entrada, hud.gd) → 5 DETONAR. START avança, ESC volta uma.
## "Configurar mapa" (resultados) → etapa 1 já preenchida. (Engenhoca = "spell" no código, A20.)
## SPELLS: mosaico com as spells autorizadas pelo mapa; PULAR acende/apaga; ALEATÓRIO acende 8 (2 por família);
##   ATACAR acende/apaga todas; START segue (mínimo 4 acesas). A seleção é o conjunto que pode sair nas caixas.
## EVENTOS: só os eventos DO MAPA (valem em todas as cenas, A14); NENHUM apaga todos; ALEATÓRIO sorteia; START segue.
##   Perigos da cena (antigos V#) não aparecem aqui: estão sempre ligados.
const Kit := preload("res://ui/kit.gd")
const SpellsScr := preload("res://modes/spells.gd")   # NOMES e FAM_COR (constantes): a tela abre ANTES de existir partida
const Obra := preload("res://ui/obra.gd")
const GRADE_AREA := Rect2(110, 250, 1700, 736)   # mosaico de engenhocas: cabe sempre dentro do quadro (cartas encolhem)
const CARTA := Vector2(170, 226)                 # tamanho máximo da carta (proporção fixa)
const COLS_EV := 7       # mosaico de eventos (nenhum + 11 + aleatório + intensidade)
const EV_NIVEIS := ["DESLIGADOS", "BAIXA", "NORMAL", "ALTA"]
const EV_COR := Color("#6aa6c8")

var main: Node
var sel := 0
var aviso_t := 0.0
var t := 0.0
var detona_t := -1.0   # etapa 5: alavanca descendo (s); -1 = parada

func setup(m: Node) -> void:
	main = m

## O mapa escolhido tem manifesto do Derruba (é aqui que as telas existem; sorteio/ferramentas seguem direto aos ajustes).
func ativo_para(map_id: String) -> bool:
	return main.game_mode == "derruba" and not MapaReg.manifesto("derruba", map_id).is_empty()

## Dados da spell direto do modos.json (o nó de spells da partida ainda não existe quando se vem do menu: usar
## main.demo.spells aqui derrubava o jogo exportado ao escolher o mapa).
var _spells_cfg := {}

func _sc(id: String) -> Dictionary:
	if _spells_cfg.is_empty():
		_spells_cfg = Data.read_json("data/modos.json")["demolicao"]["spells"]
	return _spells_cfg.get(id, {"familia": "ataque"})

func spells_do_mapa() -> Array:
	return MapaReg.spells("derruba", main.arena_choice, [])

func eventos_do_mapa() -> Array:
	var out := []
	for id in MapaReg.manifesto("derruba", main.arena_choice).get("eventos_permitidos", []):
		if not String(id).begins_with("V"):
			out.append(id)
	return out

## Entra na tela de spells: mapa novo → tudo aceso (padrão "tudo liberado", A9).
func abrir_spells() -> void:
	if main.spells_mapa != main.arena_choice:
		main.spells_mapa = main.arena_choice
		main.spells_on.clear()
		var uc: Dictionary = main.perfil.dados.get("ultima_config", {})
		var volta: bool = String(uc.get("mapa", "")) == main.arena_choice   # perfil (D4): volta a última configuração deste mapa
		# engenhoca que NÃO existia quando a configuração foi guardada entra acesa (a Defesa sumia: configs antigas)
		var salvas: Array = uc.get("spells", [])
		var conhecidas = uc.get("conhecidas", null)
		var fams := {}
		for id in salvas:
			fams[String(_sc(id).get("familia", ""))] = true
		for id in spells_do_mapa():
			var nova: bool = (not id in conhecidas) if conhecidas is Array else not fams.has(String(_sc(id).get("familia", "")))
			main.spells_on[id] = (id in salvas or nova) if volta else true
		if volta:
			for id in eventos_do_mapa():
				main.events.enabled[id] = id in uc.get("eventos", [])
			main.demo.lives_setting = int(uc.get("vidas", main.demo.lives_setting))
	sel = 0
	aviso_t = 0.0
	main.state = main.S.SELSPELLS

func n_on() -> int:
	var n := 0
	for id in spells_do_mapa():
		if main.spells_on.get(id, false):
			n += 1
	return n

func min_spells() -> int:
	return int(MapaReg.modo_cfg("derruba").get("selecao", {}).get("spells_min", 4))

## ALEATÓRIO (A19): 8 spells, 2 de cada família.
func aleatorio_spells() -> void:
	var por := {}
	for id in spells_do_mapa():
		var f: String = _sc(id)["familia"]
		if not por.has(f):
			por[f] = []
		por[f].append(id)
	for id in spells_do_mapa():
		main.spells_on[id] = false
	var k := int(MapaReg.modo_cfg("derruba").get("selecao", {}).get("aleatorio_por_familia", 2))
	for f in por:
		var l: Array = por[f].duplicate()
		for j in mini(k, l.size()):
			var i: int = main.rng.randi_range(0, l.size() - 1)
			main.spells_on[l[i]] = true
			l.remove_at(i)

## Grade do mosaico de engenhocas para n cartas: escolhe linhas × colunas que deixam a carta MAIOR sem sair da tela.
func grade_spells(n: int) -> Dictionary:
	var gap := 14.0
	var best := {}
	for rows in range(1, 8):
		var cols := int(ceil(n / float(rows)))
		var cw := (GRADE_AREA.size.x - (cols - 1) * gap) / cols
		var ch := (GRADE_AREA.size.y - (rows - 1) * gap) / rows
		var k := minf(minf(cw / CARTA.x, ch / CARTA.y), 1.0)
		if best.is_empty() or k > float(best["k"]) + 0.001:
			best = {"k": k, "cols": cols, "rows": rows}
	var sz: Vector2 = CARTA * float(best["k"])
	var cols: int = best["cols"]
	var rows: int = best["rows"]
	var x0 := GRADE_AREA.get_center().x - (cols * sz.x + (cols - 1) * gap) / 2.0
	var y0 := GRADE_AREA.get_center().y - (rows * sz.y + (rows - 1) * gap) / 2.0
	return {"cols": cols, "rows": rows, "size": sz, "gap": gap, "origem": Vector2(x0, y0)}

func _mover(m: Node, n: int, cols: int) -> void:
	sel = clampi(sel + m.move_h(), 0, n - 1)
	var v: int = m.move_v()
	if v != 0:
		sel = clampi(sel + v * cols, 0, n - 1)

## Etapa 1: ENGENHOCAS (mosaico) + chave "engenhocas nas caixas" (última carta).
func update_spells(m: Node) -> void:
	aviso_t = maxf(aviso_t - 1.0 / 60.0, 0.0)
	var lista := spells_do_mapa()
	var n := lista.size() + 2
	_mover(m, n, int(grade_spells(n)["cols"]))
	if m.pressed("jump"):
		if sel < lista.size():
			main.spells_on[lista[sel]] = not main.spells_on.get(lista[sel], false)
		elif sel == lista.size():
			aleatorio_spells()
		else:
			main.demo.items_on = not main.demo.items_on
	elif m.pressed("hammer"):
		var todas := n_on() == lista.size()
		for id in lista:
			main.spells_on[id] = not todas
	elif m.pressed("start"):
		if n_on() >= min_spells() or not main.demo.items_on:
			sel = 0
			main.state = main.S.SELEVENTOS
		else:
			aviso_t = 1.6
			Audio.play("menu_voltar")
	elif m.pressed("back"):
		main.state = main.S.ARENAS

## Etapa 2: EVENTOS (mosaico) + sirene de intensidade (última carta).
func update_eventos(m: Node) -> void:
	var lista := eventos_do_mapa()
	var n := lista.size() + 3
	_mover(m, n, COLS_EV)
	var en: Dictionary = main.events.enabled
	if m.pressed("jump"):
		if sel == 0:
			for id in lista:
				en[id] = false
		elif sel <= lista.size():
			var id: String = lista[sel - 1]
			en[id] = not en.get(id, true)
		elif sel == lista.size() + 1:
			var algum := false
			for id in lista:
				en[id] = main.rng.randf() < 0.5
				algum = algum or en[id]
			if not algum and not lista.is_empty():
				en[lista[main.rng.randi_range(0, lista.size() - 1)]] = true
		else:
			main.event_level = posmod(main.event_level + 1, 4)
	elif m.pressed("start"):
		sel = 0
		main.state = main.S.AJUSTES
	elif m.pressed("back"):
		sel = 0
		main.state = main.S.SELSPELLS

## Etapa 3: VIDAS (3 a 6).
func update_vidas(m: Node) -> void:
	var vc: Dictionary = MapaReg.modo_cfg("derruba").get("vidas", {"min": 3, "max": 6})
	main.demo.lives_setting = clampi(main.demo.lives_setting, int(vc["min"]), int(vc["max"]))   # nunca fora de 3–6
	var h: int = m.move_h()
	if h != 0:
		main.demo.lives_setting = clampi(main.demo.lives_setting + h, int(vc["min"]), int(vc["max"]))
	if m.pressed("start") or m.pressed("jump"):
		main.go_join()
	elif m.pressed("back"):
		main.state = main.S.SELEVENTOS

## Etapa 5: DETONAR — confere a ordem de serviço; START desce a alavanca e a luta começa.
func update_detonar(m: Node) -> void:
	if detona_t >= 0.0:
		detona_t += 1.0 / 60.0
		if detona_t >= 0.45:
			detona_t = -1.0
			main.shake(10.0)
			main.start_match()
		return
	if m.pressed("start") or m.pressed("jump"):
		detona_t = 0.0
		Audio.play("explosao", 0.9, -4.0)
	elif m.pressed("back"):
		main.join_volta_f = Engine.get_physics_frames()
		main.state = main.S.JOIN

# ---------------------------------------------------------------- desenho (Canteiro vivo)
func _sub() -> String:
	return String(MapaReg.manifesto("derruba", main.arena_choice).get("nome", main.arena_choice)).to_upper()

func _tela(ci: CanvasItem, titulo: String, etapa: int) -> void:
	t = main.menus.t
	Obra.fundo(ci, t, 0.12)
	Obra.titulo(ci, titulo, "%s  ·  ETAPA %d DE 5" % [_sub(), etapa + 1])
	Obra.trilha(ci, etapa)

func _check(ci: CanvasItem, c: Vector2, on: bool) -> void:
	ci.draw_circle(c, 20.0, Obra.INK)
	ci.draw_circle(c, 16.0, Obra.VERDE if on else Obra.CINZA)
	if on:
		ci.draw_polyline(PackedVector2Array([c + Vector2(-8, 1), c + Vector2(-2, 7), c + Vector2(9, -6)]), Color.WHITE, 5.0, true)

func _icone(ci: CanvasItem, nome: String, r: Rect2, on: bool) -> void:
	var tx: Texture2D = Data.tex("spells/" + nome) if nome != "" else null
	if tx == null:
		return
	var k := minf(r.size.x / tx.get_width(), r.size.y / tx.get_height())
	var sz := Vector2(tx.get_width(), tx.get_height()) * k
	ci.draw_texture_rect(tx, Rect2(r.get_center() - sz / 2.0, sz), false, Color.WHITE if on else Color(0.55, 0.55, 0.6, 0.45))

## Desenho simples para eventos sem peça própria.
func _glifo(ci: CanvasItem, id: String, c: Vector2, on: bool) -> void:
	var a := 1.0 if on else 0.45
	match id:
		"G01":   # sirene
			ci.draw_rect(Rect2(c + Vector2(-40, 18), Vector2(80, 18)), Color("#4a4f5c", a))
			ci.draw_circle(c + Vector2(0, 14), 32.0, Color("#e8483f", a))
			ci.draw_rect(Rect2(c + Vector2(-34, 14), Vector2(68, 6)), Color("#4a4f5c", a))
			for k in 3:
				var an := PI * (1.15 + k * 0.35)
				ci.draw_line(c + Vector2.from_angle(an) * 46.0, c + Vector2.from_angle(an) * 62.0, Color("#ffd34d", a), 6.0)
		"G03":   # gravidade: caixas flutuando
			for k in 3:
				var p := c + Vector2(-28 + k * 26, 20 - k * 22)
				ci.draw_rect(Rect2(p - Vector2(14, 14), Vector2(28, 28)), Color("#c98a4b", a))
			ci.draw_line(c + Vector2(44, 40), c + Vector2(44, -24), Color(1, 1, 1, a), 6.0)
		"G13":   # cabo rompido: viga caindo
			ci.draw_set_transform(c, -0.25)
			ci.draw_rect(Rect2(-60, -12, 120, 24), Color("#6f7a8c", a))
			ci.draw_rect(Rect2(-60, -12, 120, 7), Color("#ffd34d", a))
			ci.draw_set_transform(Vector2.ZERO)
			ci.draw_rect(Rect2(c + Vector2(-60, 44), Vector2(120, 10)), Color("#d42035", a * 0.85))

## Ficha do mosaico: compensado creme (cinza se apagada), faixa da família, ícone, nome e carimbo.
func _ficha(ci: CanvasItem, r: Rect2, cor: Color, nome: String, on: bool, cursor: bool, rotulo := "") -> Rect2:
	if cursor:
		Kit.chunk(ci, r.grow(12), Obra.YEL, 20, 6, 0.0)
	Kit.chunk(ci, r, Obra.CREAM if on else Color("#dcd4c4"), 12, 5, 8.0)
	ci.draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 34)), Color(cor, 1.0 if on else 0.4))
	if rotulo != "":
		Kit.text(ci, r.position + Vector2(14, 31), rotulo, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	var quebra := nome.replace("-", "- ") if not " " in nome else nome   # MARRETA-BUMERANGUE quebra no hífen
	var fs := _fonte_nome(quebra, r.size.x - 14.0)   # nome comprido não corta (TURBOVENTILADOR, PARA-CHOQUE DE MOLA)
	Kit.text_box(ci, Vector2(r.position.x + 6, r.end.y - 46), r.size.x - 12, quebra, fs, Kit.INK if on else Kit.SOFT, 2)
	_check(ci, r.position + Vector2(r.size.x - 12, 12), on)
	return Rect2(r.position + Vector2(20, 46), Vector2(r.size.x - 40, r.size.y - 100))

## Maior fonte (17 → 12) em que o nome cabe em 2 linhas quebrando nas palavras (largura estimada por letra).
static func _fonte_nome(nome: String, w: float) -> int:
	for fs in range(17, 11, -1):
		var cw := fs * 0.68
		var linhas := 1
		var atual := 0
		var ok := true
		for p in nome.split(" "):
			if p.length() * cw > w:
				ok = false
				break
			var n := p.length() if atual == 0 else atual + 1 + p.length()
			if n * cw > w:
				linhas += 1
				atual = p.length()
			else:
				atual = n
		if ok and linhas <= 2:
			return fs
	return 12

func _cursor_chip(ci: CanvasItem, r: Rect2) -> void:
	Obra.chip(ci, r.position - Vector2(28, 30))

func draw_spells(ci: CanvasItem) -> void:
	_tela(ci, "ESCOLHA AS ENGENHOCAS", 0)
	Obra.quadro(ci, Rect2(90, 232, 1740, 762))
	var lista := spells_do_mapa()
	var gd := grade_spells(lista.size() + 2)
	var cols: int = gd["cols"]
	var csz: Vector2 = gd["size"]
	var gap: float = gd["gap"]
	var o: Vector2 = gd["origem"]
	for i in lista.size() + 2:
		var r := Rect2(o + Vector2((i % cols) * (csz.x + gap), (i / cols) * (csz.y + gap)), csz)
		if i < lista.size():
			var id: String = lista[i]
			var s: Dictionary = _sc(id)
			var on: bool = main.spells_on.get(id, false) and main.demo.items_on
			var area := _ficha(ci, r, SpellsScr.FAM_COR[s["familia"]], String(SpellsScr.NOMES.get(id, id)), on, i == sel)
			_icone(ci, "icone_" + String(s["familia"]), Rect2(r.position + Vector2(10, 7), Vector2(26, 26)), on)
			_icone(ci, String(s.get("icone", "")), area, on)
		elif i == lista.size():   # ALEATÓRIO
			if i == sel:
				Kit.chunk(ci, r.grow(12), Color.WHITE, 20, 6, 0.0)
			Kit.chunk(ci, r, Obra.YEL, 12, 5, 8.0)
			Kit.title(ci, Vector2(r.position.x, r.position.y + 140), "?", 100, Color.WHITE, r.size.x)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 20), "ALEATÓRIO", 20, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:   # chave "nas caixas"
			if i == sel:
				Kit.chunk(ci, r.grow(12), Obra.YEL, 20, 6, 0.0)
			Kit.chunk(ci, r, Color("#4a5060"), 12, 5, 8.0)
			var lig: bool = main.demo.items_on
			var sx := r.get_center().x
			ci.draw_rect(Rect2(sx - 12, r.position.y + 40, 24, 110), Color("#2a2f3a"))
			var ky := r.position.y + (52.0 if lig else 140.0)
			ci.draw_line(Vector2(sx, r.position.y + 96), Vector2(sx, ky), Color("#c9d1d8"), 14.0)
			ci.draw_circle(Vector2(sx, ky), 18.0, Obra.VERDE if lig else Color("#d42035"))
			Kit.text(ci, Vector2(r.position.x, r.end.y - 46), "LIGADAS" if lig else "DESLIGADAS", 20, Obra.VERDE if lig else Color("#ff8a8a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 20), "nas caixas", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if i == sel:
			_cursor_chip(ci, r)
	if aviso_t > 0.0:
		Obra.placa(ci, Vector2(960, 470), 640, 90, "Ligue pelo menos %d engenhocas" % min_spells(), true, -0.02, 30)
	Obra.dica(ci, "%d de %d ligadas  ·  PULAR acende/apaga  ·  ATACAR tudo/nada  ·  START próxima etapa  ·  ESC voltar" % [n_on(), lista.size()])

func draw_eventos(ci: CanvasItem) -> void:
	_tela(ci, "ESCOLHA OS EVENTOS", 1)
	Obra.quadro(ci, Rect2(90, 232, 1740, 762))
	var lista := eventos_do_mapa()
	var cw := 210.0
	var ch := 336.0
	var gap := 22.0
	var x0 := 960.0 - (COLS_EV * cw + (COLS_EV - 1) * gap) / 2.0
	var en: Dictionary = main.events.enabled
	var nomes := {}
	var icones := {}
	for e in main.events.cfg["lista"]:
		nomes[e["id"]] = String(e.get("nome", e["id"])).to_upper()
		icones[e["id"]] = String(e.get("icone", ""))
	for i in lista.size() + 3:
		var r := Rect2(x0 + (i % COLS_EV) * (cw + gap), 262 + (i / COLS_EV) * (ch + 32), cw, ch)
		if i == 0:   # NENHUM
			if i == sel:
				Kit.chunk(ci, r.grow(12), Obra.YEL, 20, 6, 0.0)
			Kit.chunk(ci, r, Color("#dcd4c4"), 12, 5, 8.0)
			var c := r.position + Vector2(r.size.x / 2.0, 140)
			ci.draw_arc(c, 54.0, 0.0, TAU, 40, Kit.INK, 11.0, true)
			ci.draw_line(c + Vector2(-38, 38), c + Vector2(38, -38), Kit.INK, 11.0, true)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 28), "NENHUM", 24, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		elif i <= lista.size():
			var id: String = lista[i - 1]
			var on: bool = en.get(id, true)
			var area := _ficha(ci, r, Color("#6aa6c8"), nomes.get(id, id), on, i == sel, id)
			if icones.get(id, "") != "":
				_icone(ci, icones[id], area, on)
			else:
				_glifo(ci, id, area.get_center(), on)
		elif i == lista.size() + 1:   # ALEATÓRIO
			if i == sel:
				Kit.chunk(ci, r.grow(12), Color.WHITE, 20, 6, 0.0)
			Kit.chunk(ci, r, Obra.YEL, 12, 5, 8.0)
			Kit.title(ci, Vector2(r.position.x, r.position.y + 190), "?", 120, Color.WHITE, r.size.x)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 24), "ALEATÓRIO", 20, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:   # INTENSIDADE: sirene + mostrador
			if i == sel:
				Kit.chunk(ci, r.grow(12), Obra.YEL, 20, 6, 0.0)
			Kit.chunk(ci, r, Obra.CREAM, 12, 5, 8.0)
			ci.draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 34)), Color("#d42035"))
			Kit.text(ci, r.position + Vector2(0, 31), "INTENSIDADE", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			var sc := r.position + Vector2(r.size.x / 2.0, 120)
			var gira: float = t * (2.0 + main.event_level * 2.0)
			if main.event_level > 0:
				for k in 2:
					var a: float = gira + k * PI
					ci.draw_colored_polygon(PackedVector2Array([sc + Vector2(0, -16), sc + Vector2.from_angle(a - 0.25) * 90.0, sc + Vector2.from_angle(a + 0.25) * 90.0]), Color(1.0, 0.83, 0.3, 0.45))
			ci.draw_rect(Rect2(sc + Vector2(-44, 0), Vector2(88, 20)), Color("#4a4f5c"))
			ci.draw_circle(sc, 34.0, Color("#e8483f") if main.event_level > 0 else Color("#9a8f86"))
			ci.draw_rect(Rect2(sc + Vector2(-34, 0), Vector2(68, 8)), Color("#4a4f5c"))
			var gc := r.position + Vector2(r.size.x / 2.0, 262)
			var cols := [Color("#8d98a4"), Color("#8fd46a"), Color("#f2d04b"), Color("#ec6448")]
			for k in 4:
				ci.draw_arc(gc, 64.0, PI + k * PI / 4.0, PI + (k + 1) * PI / 4.0, 8, cols[k], 22.0)
			var an: float = PI + (main.event_level + 0.5) * PI / 4.0
			ci.draw_line(gc, gc + Vector2.from_angle(an) * 62.0, Kit.INK, 7.0, true)
			ci.draw_circle(gc, 9.0, Obra.YEL)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 20), EV_NIVEIS[main.event_level], 22, Color("#b0331f"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if i == sel:
			_cursor_chip(ci, r)
	var ligados := 0
	for id in lista:
		if en.get(id, true):
			ligados += 1
	Obra.dica(ci, "%d de %d ligados  ·  vale em todas as cenas  ·  PULAR acende/apaga  ·  START próxima etapa  ·  ESC etapa anterior" % [ligados, lista.size()])

func draw_vidas(ci: CanvasItem) -> void:
	_tela(ci, "QUANTAS VIDAS?", 2)
	Obra.quadro(ci, Rect2(360, 250, 1200, 720))
	var area := Obra.prancheta(ci, Rect2(520, 300, 880, 600), "VIDAS DE CADA ROBÔ", Color("#2f8ff0"), true)
	Obra.chip(ci, Vector2(490, 262))
	var n: int = main.demo.lives_setting
	var c := area.get_center()
	Obra.seta(ci, c + Vector2(-260, -60), -1)
	Obra.seta(ci, c + Vector2(260, -60), 1)
	Kit.text(ci, Vector2(area.position.x, c.y + 10), str(n), 190, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
	ci.draw_rect(Rect2(c.x - 300, c.y + 120, 600, 16), Color("#8a5a2b"))
	for k in 6:
		Obra.capacete(ci, Vector2(c.x - 250 + k * 100, c.y + 118), 0.8, k < n)
	Kit.text(ci, Vector2(area.position.x, area.end.y - 18), "de 3 a 6  ·  mais vidas = luta mais longa", 22, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
	Obra.dica(ci, "◄► muda  ·  START próxima etapa  ·  ESC etapa anterior")

func _jogadores_txt() -> String:
	var nb: int = main.players.filter(func(p): return p.get("bot", false)).size()
	return "%d" % main.players.size() + ("" if nb == 0 else (" (%d bot%s)" % [nb, "" if nb == 1 else "s"]))

func draw_detonar(ci: CanvasItem) -> void:
	_tela(ci, "TUDO PRONTO?", 4)
	Obra.quadro(ci, Rect2(150, 250, 1620, 720))
	var area := Obra.prancheta(ci, Rect2(210, 300, 820, 620), "ORDEM DE SERVIÇO", Color("#2a1a2e"))
	var lista := eventos_do_mapa()
	var ligados := 0
	for id in lista:
		if main.events.enabled.get(id, true):
			ligados += 1
	var linhas := [["MAPA", _sub()],
		["ENGENHOCAS", ("%d acesas" % n_on()) if main.demo.items_on else "desligadas"],
		["EVENTOS", ("%d · %s" % [ligados, EV_NIVEIS[main.event_level]]) if main.event_level > 0 else "desligados"],
		["VIDAS", str(main.demo.lives_setting)],
		["JOGADORES", _jogadores_txt()]]
	for k in linhas.size():
		var y := area.position.y + 70 + k * 92
		ci.draw_line(Vector2(area.position.x + 24, y + 20), Vector2(area.end.x - 24, y + 20), Color("#d9c7a3"), 3.0)
		Kit.text(ci, Vector2(area.position.x + 30, y), linhas[k][0], 24, Kit.SOFT)
		Kit.text(ci, Vector2(area.position.x + 270, y), linhas[k][1], 30, Kit.INK)
		var c := Vector2(area.end.x - 60, y - 10)
		ci.draw_arc(c, 24.0, 0, TAU, 24, Color("#2e7d32"), 4.0, true)
		Kit.text(ci, c + Vector2(-24, 7), "OK", 18, Color("#2e7d32"), HORIZONTAL_ALIGNMENT_CENTER, 48)
	var k2 := clampf(detona_t / 0.25, 0.0, 1.0) if detona_t >= 0.0 else 0.0
	Obra.detonador(ci, Vector2(1380, 640), 1.0, k2)
	Obra.chip(ci, Vector2(1345, 380))
	Kit.text(ci, Vector2(1080, 880), "START = DETONAR!", 40, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, 600)
	Obra.dica(ci, "START detona e a luta começa  ·  ESC volta para corrigir")
