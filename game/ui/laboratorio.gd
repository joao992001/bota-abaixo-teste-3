extends Node
## LABORATÓRIO: fase de teste pequena e destrutível (levels/laboratorio.lvl, montada pelo Canteiro no layout "lab")
## para testar golpes, spells e eventos. Menu curto (START / Tab): spell, evento, bots, bonecos, reiniciar a fase,
## invencível, câmera lenta, medidores e sair. VOLTAR (B/○, Backspace) ou H mostra/esconde os medidores no jogo.

const Kit := preload("res://ui/kit.gd")
const SLOWS := [1.0, 0.5, 0.25]
const DUMMY := ["parado", "anda", "pula", "golpe rápido", "marretada", "esquiva"]
const DUMMY_DMG := [0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 200.0]
const ROWS := ["spell", "evento", "bot", "boneco", "boneco_faz", "reiniciar", "invencivel", "lento", "medidores", "sair"]

var main: Node
var open := false
var sel := 0
var slow_i := 0
var god := false
var dummy_i := 0
var dummy_dmg_i := 0
var show_meters := false       # medidores do P1 (VOLTAR/H mostra)
var spell_i := 0
var event_i := 0
var _h_was := false
var t := 0.0
var frame := 0
var msg := ""
var msg_t := 0.0
# medições
var jump := {"on": false, "y0": 0.0, "x0": 0.0, "top": 0.0}
var last_jump := ""
var dodge := {"on": false, "p0": Vector2.ZERO}
var last_dodge := ""
var flights := {}             # robô -> {p0, top, dmg}
var last_flight := ""
var last_atk := {}            # último golpe do P1 (para a linha do tempo continuar na tela)

func setup(m: Node) -> void:
	main = m

func rows() -> Array:
	return ROWS

# ---------------------------------------------------------------- entrar / sair
func start(dev: String) -> void:
	main.players.clear()
	PlayerInput.slots.clear()
	main.mode = "demolicao"
	main.sandbox = true
	main.lab_mode = true
	main.add_player(dev)
	main.arena_choice = "laboratorio"
	main.game_mode = "derruba"
	for id in main.events.enabled:   # ferramenta de testes: todos os eventos disponíveis (a seleção da partida não vale aqui)
		main.events.enabled[id] = true
	main.event_level = 2
	main.events.manual = true
	main.demo.items_on = false
	main.demo.cfg["rounds_to_win"] = 999
	open = false
	god = false
	slow_i = 0
	sel = 0
	main.start_match()
	main.sandbox_add("boneco")
	if main.robots.size() > 1:
		main.robots[1].position = Vector2(16 * 64 + 32, 12 * 64)
	main.demo.banner = "LABORATÓRIO"
	main.demo.banner_t = 2.0

func stop() -> void:
	open = false
	god = false
	slow_i = 0
	Engine.time_scale = 1.0
	main.debug = false
	main.events.manual = false
	main.lab_mode = false

func toggle() -> void:
	open = not open
	main.paused = open
	Audio.play("menu_ok" if open else "menu_voltar")

func _say(s: String) -> void:
	msg = s
	msg_t = 2.0

## Recomeça a fase (laje, andaimes e vigas inteiros de novo) mantendo todos os jogadores, bots e bonecos.
func _restart() -> void:
	main.arena_choice = "laboratorio"
	main._demo_next_round()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	_say("FASE REINICIADA")

# ---------------------------------------------------------------- menu
func update() -> void:
	var m = main.menus
	sel = posmod(sel + m.move_v(), ROWS.size())
	var h: int = m.move_h()
	var ok: bool = m.confirm()
	if m.pressed("back") or _pressed_start():
		toggle()
		return
	match ROWS[sel]:
		"spell":
			spell_i = posmod(spell_i + h, spells().size())
			if ok and main.robots.size() > 0:
				main.demo.spells.clear(main.robots[0])
				main.demo.spells.equip(main.robots[0], spells()[spell_i])
				toggle()
		"evento":
			event_i = posmod(event_i + h, events().size())
			if ok:
				main.events.trigger(events()[event_i])
				toggle()
		"bot":
			if h > 0 or ok:
				main.sandbox_add("bot")
			elif h < 0:
				main.sandbox_remove("bot")
		"boneco":
			if h > 0 or ok:
				main.sandbox_add("boneco")
			elif h < 0:
				main.sandbox_remove("boneco")
		"boneco_faz":
			dummy_i = posmod(dummy_i + h + (1 if ok else 0), DUMMY.size())
		"reiniciar":
			if ok:
				_restart()
				toggle()
		"invencivel":
			if h != 0 or ok:
				god = not god
		"lento":
			if h != 0 or ok:
				slow_i = posmod(slow_i + (h if h != 0 else 1), SLOWS.size())
				Engine.time_scale = SLOWS[slow_i]
		"medidores":
			if h != 0 or ok:
				show_meters = not show_meters
		"sair":
			if ok:
				main.go_menu()

func _label(row: String) -> String:
	match row:
		"spell": return "ENGENHOCA:  ◄ %s ►" % _spell_name(spells()[spell_i])
		"evento": return "EVENTO:  ◄ %s ►" % String(events()[event_i]["nome"]).to_upper()
		"bot": return "BOTS:  ◄ − / + ►   %d" % _count("bot")
		"boneco": return "BONECOS:  ◄ − / + ►   %d" % _count("boneco")
		"boneco_faz": return "BONECO FAZ:  ◄ %s ►" % String(DUMMY[dummy_i]).to_upper()
		"reiniciar": return "REINICIAR FASE"
		"invencivel": return "INVENCÍVEL:  %s" % ("SIM" if god else "NÃO")
		"lento": return "CÂMERA LENTA:  %s" % ["NÃO", "½×", "¼×"][slow_i]
		"medidores": return "MEDIDORES:  %s" % ("MOSTRAR" if show_meters else "ESCONDER")
		"sair": return "SAIR DO LABORATÓRIO"
	return row

const HINTS := {"spell": "PULAR: dar ao P1", "evento": "PULAR: disparar agora", "reiniciar": "laje, andaimes e vigas voltam"}

func draw(ci: CanvasItem) -> void:
	if open:
		_draw_panel(ci)
		return
	if show_meters:
		_draw_meters(ci)
	else:
		Kit.sticker(ci, Vector2(20, 118), "LABORATÓRIO  ·  START: menu  ·  VOLTAR / H: medidores", 22, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_LEFT)
	if msg_t > 0.0:
		Kit.sticker(ci, Vector2(960, 1000), msg, 30, Color("#3c9a46"))

func _draw_panel(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.1, 0.25, 0.3, 0.35))
	var r := Rect2(560, 150, 800, 800)
	Kit.paper(ci, r)
	Kit.ribbon(ci, Rect2(640, 70, 640, 110), "LABORATÓRIO", 54)
	for i in ROWS.size():
		var y := r.position.y + 90 + i * 70
		var on := i == sel
		if on:
			ci.draw_rect(Rect2(r.position.x + 30, y - 46, r.size.x - 60, 62), Color(0.95, 0.78, 0.29, 0.55))
			if HINTS.has(ROWS[i]):
				Kit.text(ci, Vector2(r.position.x + 60, y + 4), HINTS[ROWS[i]], 17, Color("#8a5a2a"))
		Kit.text(ci, Vector2(r.position.x + 60, y - 10), _label(ROWS[i]), 30, Color("#2a1a2e") if on else Color("#3e5a62"))
		if ROWS[i] == "spell":
			var fam: String = main.demo.cfg["spells"][spells()[spell_i]]["familia"]
			ci.draw_texture_rect(Data.tex("spells/caixa_" + fam), Rect2(r.end.x - 100, y - 48, 54, 54), false)
		if ROWS[i] == "evento" and not main.events.eligible(events()[event_i]):
			Kit.text(ci, Vector2(r.end.x - 300, y - 10), "(indisponível aqui)", 18, Color("#b04030"))
	Kit.text(ci, Vector2(0, 1066), "▲▼ escolher  ·  ◄► mudar  ·  PULAR confirmar  ·  START / TAB / ESC fecha", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

## (régua antiga do Laboratório removida: a fase agora é destrutível)
func draw_world(_ci: CanvasItem) -> void:
	pass


func _pressed_start() -> bool:
	for i in main.players.size():
		if not main.players[i].get("bot", false) and not main.players[i].get("boneco", false) and PlayerInput.pressed(i, "start"):
			return true
	return false

# ---------------------------------------------------------------- a cada quadro (jogo rodando)

# ---------------------------------------------------------------- a cada quadro (jogo rodando)
func tick() -> void:
	t += 1.0 / 60.0
	frame += 1
	msg_t = maxf(msg_t - 1.0 / 60.0, 0.0)
	var hk := Input.is_key_pressed(KEY_H)
	if (hk and not _h_was) or (main.players.size() > 0 and PlayerInput.pressed(0, "back")):
		show_meters = not show_meters
		Audio.play("menu_mover")
	_h_was = hk
	var human = null
	for i in main.robots.size():
		var r = main.robots[i]
		var is_dummy: bool = i < main.players.size() and main.players[i].get("boneco", false)
		r.god = god and not is_dummy and not main.players[i].get("bot", false)
		if is_dummy:
			_drive_dummy(i, r)
		elif human == null:
			human = r
		_measure_flight(r)
	if human != null:
		_measure_player(human)


func _drive_dummy(i: int, r) -> void:
	var dev: String = main.players[i]["dev"]
	var inp := {}
	var target = main.robots[0] if main.robots.size() > 0 else null
	var cyc := frame % 120
	match DUMMY[dummy_i]:
		"anda":
			inp["right" if (frame / 90) % 2 == 0 else "left"] = true
		"pula":
			if frame % 75 < 14:
				inp["jump"] = true
		"golpe rápido":
			if cyc % 55 == 0:
				inp["hammer"] = true
		"marretada":
			if cyc == 0:
				inp["heavy"] = true
		"esquiva":
			if frame % 70 == 0:
				inp["dodge"] = true
				inp["right" if (frame / 70) % 2 == 0 else "left"] = true
	if DUMMY[dummy_i] in ["golpe rápido", "marretada"] and target != null and r.atk == "" and r.is_on_floor():
		r.facing = 1 if target.position.x >= r.position.x else -1   # vira para o P1
	PlayerInput.virtual[dev] = inp
	# dano fixo: volta ao valor escolhido depois de pousar quieto
	if r.is_on_floor() and r.stun_t <= 0.0 and r.recover_t <= 0.0 and r.last_hit > 1.0:
		r.dmg = DUMMY_DMG[dummy_dmg_i]


func _measure_player(r) -> void:
	var on_floor: bool = r.is_on_floor()
	if not on_floor and not jump["on"] and r.velocity.y < -100.0 and r.dodge_t <= 0.0:
		jump = {"on": true, "y0": r.position.y, "x0": r.position.x, "top": r.position.y}
	if jump["on"]:
		jump["top"] = minf(jump["top"], r.position.y)
		if on_floor or r.hanging:
			jump["on"] = false
			last_jump = "%.2f tiles de altura · %.1f tiles de distância" % [(jump["y0"] - jump["top"]) / 64.0, absf(r.position.x - jump["x0"]) / 64.0]
	if r.dodge_t > 0.0 and not dodge["on"]:
		dodge = {"on": true, "p0": r.position}
	elif r.dodge_t <= 0.0 and dodge["on"]:
		dodge["on"] = false
		last_dodge = "%.0f px (%.1f tiles)" % [r.position.distance_to(dodge["p0"]), r.position.distance_to(dodge["p0"]) / 64.0]
	if r.atk != "":
		last_atk = {"kind": r.atk, "t": r.atk_t, "landed": r.atk_landed, "hit": r.atk_hit}


func _measure_flight(r) -> void:
	if r.stun_t > 0.0 and not flights.has(r):
		flights[r] = {"p0": r.position, "top": r.position.y, "dmg": r.dmg}
	if flights.has(r):
		var fl: Dictionary = flights[r]
		fl["top"] = minf(fl["top"], r.position.y)
		if r.stun_t <= 0.0 and (r.is_on_floor() or r.hanging or not r.alive):
			var d: float = absf(r.position.x - fl["p0"].x) / 64.0
			var hgt: float = (fl["p0"].y - fl["top"]) / 64.0
			last_flight = "P%d com %d%%: %.1f tiles de distância · %.1f de altura" % [r.pid + 1, int(fl["dmg"]), d, hgt]
			flights.erase(r)

# ---------------------------------------------------------------- desenho

func spells() -> Array:   # todas as spells liberadas (data/modos.json → demolicao.spells.pools)
	var out := []
	for pool in main.demo.cfg["spells"]["pools"].values():
		if not pool is Array:
			continue   # "nota"
		for k in pool:
			if k not in out:
				out.append(k)
	return out


func events() -> Array:
	return main.events.cfg["lista"]

## Troca/recarrega a arena mantendo todos (robôs, bonecos e bots).

func _spell_name(id: String) -> String:
	return id + " " + String(main.demo.spells.NOMES.get(id, id))


func _count(kind: String) -> int:
	var n := 0
	for p in main.players:
		if p.get(kind, false):
			n += 1
	return n


## Medidores do P1 (cartão compacto no canto esquerdo) e resultados das medições (embaixo).
func _draw_meters(ci: CanvasItem) -> void:
	if main.robots.is_empty():
		return
	var r = main.robots[0]
	var c: Dictionary = Data.ctrl
	var box := Rect2(16, 104, 470, 368)
	ci.draw_rect(Rect2(box.position + Vector2(5, 6), box.size), Color(0.16, 0.1, 0.18, 0.35))   # sombra dura
	ci.draw_rect(box, Color(1, 0.99, 0.96, 0.9))
	ci.draw_rect(box, Color("#2a1a2e"), false, 3.0)
	ci.draw_rect(Rect2(box.position, Vector2(box.size.x, 34)), Color("#2a1a2e"))
	var x := box.position.x + 14
	Kit.text(ci, Vector2(x, box.position.y + 25), "P1  ·  START painel  ·  VOLTAR/H esconde", 19, Color("#fff4c8"))
	var y := box.position.y + 66
	Kit.text(ci, Vector2(x, y), _state(r), 24, Color("#3c4a8a"))
	y += 12
	# linha do tempo do golpe: preparo (amarelo) · ativo (vermelho) · recuperação (cinza)
	var a: Dictionary = last_atk
	if not a.is_empty():
		var ac: Dictionary = c["ataque_rapido"] if a["kind"] == "rapido" else c["ataque_pesado"]
		var rec := float(ac["recupera"]) if a["kind"] == "rapido" else (float(ac["recupera_acerto"]) if a["landed"] else float(ac["recupera_erro"]))
		var segs := [[float(ac["preparo"]), Color("#f2c84b")], [float(ac["ativo"]), Color("#d42035")], [rec, Color("#9aa4ae")]]
		var total := 0.0
		for sg in segs:
			total += sg[0]
		var bw := 300.0
		var bx := x + 130.0
		Kit.text(ci, Vector2(x, y + 20), "RÁPIDO" if a["kind"] == "rapido" else "PESADA", 18, Color("#2a1a2e"))
		var px := bx
		for sg in segs:
			var w: float = bw * sg[0] / maxf(total, 0.001)
			ci.draw_rect(Rect2(px, y + 4, w, 18), sg[1])
			px += w
		var cur: float = float(r.atk_t) if r.atk != "" else total
		ci.draw_rect(Rect2(bx + bw * clampf(cur / maxf(total, 0.001), 0.0, 1.0) - 2, y, 4, 26), Color("#2a1a2e"))
		Kit.text(ci, Vector2(bx, y + 42), "%d + %d + %d quadros%s" % [roundi(segs[0][0] * 60), roundi(segs[1][0] * 60), roundi(rec * 60), ("  · acertou" if a["landed"] else "  · errou")], 16, Color("#3e5a62"))
	y += 56
	_bar(ci, Vector2(x, y), "Sem controle", r.stun_t / maxf(float(c["arremesso"]["sem_controle_max"]), 0.01), Color("#d42035"))
	_bar(ci, Vector2(x, y + 28), "Recuperando", r.recover_t / maxf(r.recover_len, 0.01), Color("#f2a23a"))
	_bar(ci, Vector2(x, y + 56), "Proteção", r.guard_t / maxf(float(c["esquiva"]["protecao"]), 0.01), Color("#5cc45c"))
	_bar(ci, Vector2(x, y + 84), "Recarga esquiva", r.dodge_cd / maxf(float(c["esquiva"]["recarga"]), 0.01), Color("#4f86d9"))
	_bar(ci, Vector2(x, y + 112), "Recarga pesada", r.heavy_cd / maxf(float(c["ataque_pesado"]["recarga"]), 0.01), Color("#8a63d2"))
	# spell do P1: nome, cargas e preparo/duração
	var sp = main.demo.spells
	var info: Dictionary = sp.hud_info(0) if sp != null else {}
	var fl: Dictionary = sp.flags(r) if sp != null else {}
	var prep: float = fl.get("prep", -1.0)
	var k := prep if prep >= 0.0 else (1.0 - float(info.get("frac", 1.0)) if info.get("frac", 1.0) < 1.0 else 0.0)
	_bar(ci, Vector2(x, y + 140), "Engenhoca " + (String(info["id"]) + " ×%d" % int(info["charges"]) if not info.is_empty() else "—"), k, sp.FAM_COR.get(info.get("fam", ""), Color("#9aa4ae")) if sp != null else Color.GRAY)
	y += 186
	Kit.text(ci, Vector2(x, y), "Esquiva no ar %s   Pulo duplo %s   Dano %d%%" % ["●" if r.air_dodge > 0 else "○", "●" if r.air_jumps > 0 else "○", int(r.dmg)], 19, Color("#2a1a2e"))
	# entradas apertadas
	var keys := [["◄", "left"], ["►", "right"], ["▲", "up"], ["▼", "down"], ["PULO", "jump"], ["GOLPE", "hammer"], ["PESADA", "heavy"], ["ESQUIVA", "dodge"], ["ESPECIAL", "item"]]
	var kx := 16.0
	for kk in keys:
		var on: bool = PlayerInput.held(0, kk[1])
		var w: float = 26.0 + 11.0 * String(kk[0]).length()
		var kr := Rect2(kx, 484, w, 34)
		ci.draw_rect(kr, Color("#f2c84b") if on else Color(1, 1, 1, 0.7))
		ci.draw_rect(kr, Color("#2a1a2e"), false, 2.0)
		Kit.text(ci, Vector2(kr.position.x, kr.position.y + 25), kk[0], 17, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, w)
		kx += w + 5.0
	# resultados
	var lines := []
	if last_jump != "":
		lines.append("Último pulo: " + last_jump)
	if last_dodge != "":
		lines.append("Última esquiva: " + last_dodge)
	if last_flight != "":
		lines.append("Último arremesso: " + last_flight)
	lines.append("Boneco: %s   ·   velocidade %s" % [DUMMY[dummy_i], ["1×", "½×", "¼×"][slow_i]])
	for i in lines.size():
		Kit.sticker(ci, Vector2(16, 566 + i * 40), lines[i], 21, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_LEFT)


func _bar(ci: CanvasItem, p: Vector2, label: String, k: float, col: Color) -> void:
	Kit.text(ci, p + Vector2(0, 18), label, 18, Color("#2a1a2e"))
	var r := Rect2(p.x + 170, p.y + 3, 270, 17)
	ci.draw_rect(r, Color(0, 0, 0, 0.08))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0.0, 1.0), r.size.y)), col)
	ci.draw_rect(r, Color("#2a1a2e"), false, 2.0)


func _state(r) -> String:
	if r.hitstop > 0.0:
		return "IMPACTO (hitstop)"
	if r.stun_t > 0.0:
		return "ARREMESSADO (sem controle)"
	if r.dodge_t > 0.0:
		return "ESQUIVA%s" % (" · PROTEGIDO" if r.guard_t > 0.0 else "")
	if r.atk != "":
		var ac: Dictionary = Data.ctrl["ataque_rapido"] if r.atk == "rapido" else Data.ctrl["ataque_pesado"]
		var ph := "PREPARO" if not r.atk_hit else ("ATIVO" if r.atk_t < float(ac["preparo"]) + float(ac["ativo"]) else "RECUPERAÇÃO")
		return "%s · %s" % ["GOLPE RÁPIDO" if r.atk == "rapido" else "MARRETADA PESADA", ph]
	if r.recover_t > 0.0 and not r.is_on_floor():
		return "RECUPERANDO O CONTROLE"
	if r.hanging:
		return "NA BORDA"
	if r.wall_sliding:
		return "NA PAREDE"
	if not r.is_on_floor():
		return "NO AR (subindo)" if r.velocity.y < 0.0 else "NO AR (caindo)"
	if absf(r.velocity.x) > 40.0:
		return "CORRENDO"
	return "PARADO"

## Régua no mundo: marcas a cada tile no chão e alturas de 1 a 7 tiles na parede da esquerda.
