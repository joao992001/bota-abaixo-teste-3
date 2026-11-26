extends RefCounted
## TELAS DE SELEÇÃO do Derruba v2 (aprovadas: A9, A14, A15, A18, A19; pranchas art/out/etapa_c/c2_spells.png e
## c3_eventos.png). Fluxo: MAPAS → SPELLS → EVENTOS → AJUSTES (vidas) → ENTRADA. "Configurar mapa" (resultados) → SPELLS.
## SPELLS: mosaico com as spells autorizadas pelo mapa; PULAR acende/apaga; ALEATÓRIO acende 8 (2 por família);
##   ATACAR acende/apaga todas; START segue (mínimo 4 acesas). A seleção é o conjunto que pode sair nas caixas.
## EVENTOS: só os eventos DO MAPA (valem em todas as cenas, A14); NENHUM apaga todos; ALEATÓRIO sorteia; START segue.
##   Perigos da cena (antigos V#) não aparecem aqui: estão sempre ligados.
const Kit := preload("res://ui/kit.gd")
const COLS := 8
const CW := 182.0
const GAP := 26.0
const EV_COR := Color("#6aa6c8")

var main: Node
var sel := 0
var aviso_t := 0.0

func setup(m: Node) -> void:
	main = m

## O mapa escolhido tem manifesto do Derruba (é aqui que as telas existem; sorteio/ferramentas seguem direto aos ajustes).
func ativo_para(map_id: String) -> bool:
	return main.game_mode == "derruba" and not MapaReg.manifesto("derruba", map_id).is_empty()

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
		for id in spells_do_mapa():
			main.spells_on[id] = true
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
		var f: String = main.demo.spells.sc(id)["familia"]
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

func _mover(m: Node, n: int) -> void:
	sel = clampi(sel + m.move_h(), 0, n - 1)
	var v: int = m.move_v()
	if v != 0:
		sel = clampi(sel + v * COLS, 0, n - 1)

func update_spells(m: Node) -> void:
	aviso_t = maxf(aviso_t - 1.0 / 60.0, 0.0)
	var lista := spells_do_mapa()
	var n := lista.size() + 1
	_mover(m, n)
	if m.pressed("jump"):
		if sel < lista.size():
			main.spells_on[lista[sel]] = not main.spells_on.get(lista[sel], false)
		else:
			aleatorio_spells()
	elif m.pressed("hammer"):
		var todas := n_on() == lista.size()
		for id in lista:
			main.spells_on[id] = not todas
	elif m.pressed("start"):
		if n_on() >= min_spells():
			sel = 0
			main.state = main.S.SELEVENTOS
		else:
			aviso_t = 1.6
			Audio.play("menu_voltar")
	elif m.pressed("back"):
		main.state = main.S.ARENAS

func update_eventos(m: Node) -> void:
	var lista := eventos_do_mapa()
	var n := lista.size() + 2
	_mover(m, n)
	var en: Dictionary = main.events.enabled
	if m.pressed("jump"):
		if sel == 0:
			for id in lista:
				en[id] = false
		elif sel <= lista.size():
			var id: String = lista[sel - 1]
			en[id] = not en.get(id, true)
		else:
			var algum := false
			for id in lista:
				en[id] = main.rng.randf() < 0.5
				algum = algum or en[id]
			if not algum and not lista.is_empty():
				en[lista[main.rng.randi_range(0, lista.size() - 1)]] = true
	elif m.pressed("start"):
		m.adj_sel = 0
		main.state = main.S.AJUSTES
	elif m.pressed("back"):
		sel = 0
		main.state = main.S.SELSPELLS

# ---------------------------------------------------------------- desenho
func _x0() -> float:
	return (1920.0 - (COLS * CW + (COLS - 1) * GAP)) / 2.0

func _check(ci: CanvasItem, c: Vector2, on: bool) -> void:
	ci.draw_circle(c, 23.0, Kit.INK)
	ci.draw_circle(c, 18.0, Color("#5fc95f") if on else Color("#d9d2c4"))
	if on:
		ci.draw_polyline(PackedVector2Array([c + Vector2(-9, 1), c + Vector2(-2, 8), c + Vector2(10, -7)]), Color.WHITE, 5.0, true)

func _icone(ci: CanvasItem, nome: String, r: Rect2, on: bool) -> void:
	var tx: Texture2D = Data.tex("spells/" + nome) if nome != "" else null
	if tx == null:
		return
	var k := minf(r.size.x / tx.get_width(), r.size.y / tx.get_height())
	var sz := Vector2(tx.get_width(), tx.get_height()) * k
	ci.draw_texture_rect(tx, Rect2(r.get_center() - sz / 2.0, sz), false, Color.WHITE if on else Color(0.55, 0.55, 0.6, 0.5))

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

func _carta(ci: CanvasItem, r: Rect2, cor: Color, nome: String, on: bool, cursor: bool, rotulo := "") -> void:
	if cursor:
		Kit.chunk(ci, r.grow(14), Kit.YEL, 34, 6, 0.0)
	Kit.chunk(ci, r, Kit.CREAM if on else Color("#e7e0d2"), 26, 6, 10.0)
	ci.draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(r.size.x - 12, 34)), Color(cor, 1.0 if on else 0.4))
	ci.draw_line(r.position + Vector2(3, 42), r.position + Vector2(r.size.x - 3, 42), Kit.INK, 5.0)
	if rotulo != "":
		Kit.text(ci, r.position + Vector2(16, 33), rotulo, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	var quebra := nome.replace("-", "- ") if not " " in nome else nome   # MARRETA-BUMERANGUE quebra no hífen
	Kit.text_box(ci, Vector2(r.position.x + 6, r.end.y - 46), r.size.x - 12, quebra, 18, Kit.INK if on else Kit.SOFT, 2)
	_check(ci, r.position + Vector2(r.size.x - 12, 12), on)

func _rodape(ci: CanvasItem, txt: String, legenda: Callable) -> void:
	var rr := Rect2(120, 905, 1680, 108)
	Kit.chunk(ci, rr, Kit.CREAM, 22, 6, 9.0)
	Kit.text(ci, Vector2(170, 972), txt, 36, Kit.INK)
	legenda.call(rr)

func _chip_p1(ci: CanvasItem, p: Vector2) -> void:
	Kit.chunk(ci, Rect2(p, Vector2(64, 40)), Data.COLORS[0], 12, 5, 0.0)
	Kit.text(ci, p + Vector2(0, 30), "P1", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 64, 5)

func _titulo(ci: CanvasItem, txt: String) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(460, 30, 1000, 128), txt, 58)
	var nm := String(MapaReg.manifesto("derruba", main.arena_choice).get("nome", main.arena_choice)).to_upper()
	Kit.chunk(ci, Rect2(70, 50, 340, 64), Kit.CREAM, 18, 5, 7.0)
	Kit.text(ci, Vector2(70, 93), nm, 26, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, 340)

func draw_spells(ci: CanvasItem) -> void:
	_titulo(ci, "ESCOLHA AS SPELLS")
	var lista := spells_do_mapa()
	var ch := 214.0
	for i in lista.size() + 1:
		var r := Rect2(_x0() + (i % COLS) * (CW + GAP), 190 + (i / COLS) * (ch + 34), CW, ch)
		if i == lista.size():
			if i == sel:
				Kit.chunk(ci, r.grow(14), Color.WHITE, 34, 6, 0.0)
			Kit.chunk(ci, r, Kit.YEL, 26, 6, 10.0)
			Kit.title(ci, Vector2(r.position.x, r.position.y + 130), "?", 110, Color.WHITE, r.size.x)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 22), "ALEATÓRIO", 22, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			var id: String = lista[i]
			var s: Dictionary = main.demo.spells.sc(id)
			var on: bool = main.spells_on.get(id, false)
			var cor: Color = main.demo.spells.FAM_COR[s["familia"]]
			_carta(ci, r, cor, String(main.demo.spells.NOMES.get(id, id)), on, i == sel)
			_icone(ci, "icone_" + String(s["familia"]), Rect2(r.position + Vector2(16, 10), Vector2(26, 26)), on)
			_icone(ci, String(s.get("icone", "")), Rect2(r.position + Vector2(22, 52), Vector2(r.size.x - 44, ch - 112)), on)
		if i == sel:
			_chip_p1(ci, r.position - Vector2(30, 30))
	var leg := func(rr: Rect2) -> void:
		var lx := 560.0
		for f in ["ataque", "controle", "engenharia", "transformacao"]:
			Kit.chunk(ci, Rect2(lx, 944, 34, 34), main.demo.spells.FAM_COR[f], 8, 4, 0.0)
			var nm: String = {"ataque": "ATAQUE", "controle": "CONTROLE", "engenharia": "ENGENHARIA", "transformacao": "TRANSFORMAÇÃO"}[f]
			Kit.text(ci, Vector2(lx + 46, 972), nm, 24, Kit.INK)
			lx += 66.0 + nm.length() * 15.0
	_rodape(ci, "%d de %d ligadas" % [n_on(), lista.size()], leg)
	if aviso_t > 0.0:
		Kit.chunk(ci, Rect2(660, 820, 600, 64), Kit.YEL, 18, 5, 6.0)
		Kit.text(ci, Vector2(660, 863), "Ligue pelo menos %d spells" % min_spells(), 30, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, 600)
	Kit.text(ci, Vector2(0, 1056), "◄►▲▼ escolher  ·  PULAR acende/apaga  ·  ATACAR tudo/nada  ·  START continuar  ·  ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

func draw_eventos(ci: CanvasItem) -> void:
	_titulo(ci, "ESCOLHA OS EVENTOS")
	var lista := eventos_do_mapa()
	var ch := 250.0
	var en: Dictionary = main.events.enabled
	var nomes := {}
	var icones := {}
	for e in main.events.cfg["lista"]:
		nomes[e["id"]] = String(e.get("nome", e["id"])).to_upper()
		icones[e["id"]] = String(e.get("icone", ""))
	for i in lista.size() + 2:
		var r := Rect2(_x0() + (i % COLS) * (CW + GAP), 200 + (i / COLS) * (ch + 56), CW, ch)
		if i == 0:
			if i == sel:
				Kit.chunk(ci, r.grow(14), Kit.YEL, 34, 6, 0.0)
			Kit.chunk(ci, r, Color("#e7e0d2"), 26, 6, 10.0)
			var c := r.position + Vector2(r.size.x / 2.0, 106)
			ci.draw_arc(c, 56.0, 0.0, TAU, 40, Kit.INK, 12.0, true)
			ci.draw_line(c + Vector2(-40, 40), c + Vector2(40, -40), Kit.INK, 12.0, true)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 30), "NENHUM", 24, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		elif i == lista.size() + 1:
			if i == sel:
				Kit.chunk(ci, r.grow(14), Color.WHITE, 34, 6, 0.0)
			Kit.chunk(ci, r, Kit.YEL, 26, 6, 10.0)
			Kit.title(ci, Vector2(r.position.x, r.position.y + 150), "?", 120, Color.WHITE, r.size.x)
			Kit.text(ci, Vector2(r.position.x, r.end.y - 30), "ALEATÓRIO", 22, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			var id: String = lista[i - 1]
			var on: bool = en.get(id, true)
			_carta(ci, r, EV_COR, nomes.get(id, id), on, i == sel, id)
			var area := Rect2(r.position + Vector2(22, 52), Vector2(r.size.x - 44, ch - 118))
			if icones.get(id, "") != "":
				_icone(ci, icones[id], area, on)
			else:
				_glifo(ci, id, area.get_center(), on)
		if i == sel:
			_chip_p1(ci, r.position - Vector2(30, 30))
	var ligados := 0
	for id in lista:
		if en.get(id, true):
			ligados += 1
	var leg := func(rr: Rect2) -> void:
		Kit.text(ci, Vector2(560, 972), "todo evento vale em todas as cenas do mapa", 26, Kit.INK)
		Kit.text(ci, Vector2(rr.position.x, 972), "perigos da cena seguem sempre", 22, Kit.SOFT, HORIZONTAL_ALIGNMENT_RIGHT, rr.size.x - 40)
	_rodape(ci, "%d de %d ligados" % [ligados, lista.size()], leg)
	Kit.text(ci, Vector2(0, 1056), "◄►▲▼ escolher  ·  PULAR acende/apaga  ·  START continuar  ·  ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)
