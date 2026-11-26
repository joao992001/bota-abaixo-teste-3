extends Node
## Telas fora da partida: MENU principal, seleção de MODOS, COMO JOGAR, OPÇÕES e a PAUSA.
## Qualquer teclado ou controle navega (bots não). Desenho em draw(ci), chamado pelo HUD.

const Kit := preload("res://ui/kit.gd")
const RobotVis := preload("res://player/robot_visual.gd")

const MENU_ITEMS := ["JOGAR", "LABORATÓRIO", "COMO JOGAR", "OPÇÕES", "SAIR"]
const PAUSE_ITEMS := ["CONTINUAR", "REINICIAR PARTIDA", "MENU PRINCIPAL"]
const STAR_GOALS := [3, 5, 7]

var main: Node
var sel := 0
var mode_sel := 0
var goal_sel := 1
var opt_sel := 0
var pause_sel := 0
var t := 0.0
var intro_t := 0.0
var menu_in := 1.0   # 0→1: botões do menu entram deslizando depois da intro
var intro_frames := 0
var intro_hit := false
var intro_hi := false
const INTRO_END := 2.6
var shake_card := 0.0
var arena_sel := 0
var adj_sel := 0
const EVENT_LEVELS := ["DESLIGADOS", "BAIXA", "NORMAL", "ALTA"]

func setup(m: Node) -> void:
	main = m

## Algum teclado/controle (não bot) apertou a ação?
func pressed(a: String) -> bool:
	for dev in PlayerInput.all_devices():
		if not dev.begins_with("bot") and PlayerInput.dev_pressed(dev, a):
			return true
	return false

func confirm() -> bool:
	return pressed("jump") or pressed("start")

func move_v() -> int:
	return int(pressed("down")) - int(pressed("up"))

func move_h() -> int:
	return int(pressed("right")) - int(pressed("left"))

func update(dt: float) -> void:
	t += dt
	if main.state == main.S.INTRO:
		_update_intro(dt)
		return
	if move_v() != 0 or move_h() != 0:
		Audio.play("menu_mover")
	if pressed("back"):
		Audio.play("menu_voltar")
	elif confirm():
		Audio.play("menu_ok")
	shake_card = maxf(shake_card - dt, 0.0)
	var S = main.S
	match main.state:
		S.MENU:
			sel = posmod(sel + move_v(), MENU_ITEMS.size())
			if confirm():
				match sel:
					0: main.state = S.MODES
					1: main.lab.start(_who_confirmed())
					2: main.state = S.HOWTO
					3: main.state = S.OPTIONS
					4: main.get_tree().quit()
		S.MODES:
			var modes: Array = main.demo.cfg["modos"]
			mode_sel = posmod(mode_sel + move_h(), modes.size())
			if confirm():
				var m: Dictionary = modes[mode_sel]
				if m["ok"]:
					main.game_mode = m["id"]
					main.demo.items_on = bool(m.get("itens", true))
					arena_sel = 0
					adj_sel = 0
					main.state = S.ARENAS
				else:
					shake_card = 0.35
					Audio.play("menu_negado")
			elif pressed("back"):
				main.state = S.MENU
		S.HOWTO:
			if confirm() or pressed("back"):
				main.state = S.MENU
		S.AJUSTES:
			var rows := adjust_rows()
			adj_sel = posmod(adj_sel + move_v(), rows.size())
			var h2 := move_h()
			var c2 := confirm()
			match rows[adj_sel]:
				"estrelas":
					if h2 != 0:
						goal_sel = clampi(goal_sel + h2, 0, STAR_GOALS.size() - 1)
				"vidas":
					if h2 != 0 or c2:
						var vc: Dictionary = MapaReg.modo_cfg("derruba").get("vidas", {"min": 1, "max": 5})
						var lo := int(vc["min"])
						var hi := int(vc["max"])
						main.demo.lives_setting = clampi(main.demo.lives_setting + h2, lo, hi) if h2 != 0 else lo + posmod(main.demo.lives_setting + 1 - lo, hi - lo + 1)
				"rei":
					if h2 != 0 or c2:
						main.demo.king_setting = posmod(main.demo.king_setting + (h2 if h2 != 0 else 1), 3)
				"pavio":
					if h2 != 0 or c2:
						main.demo.fuse_setting = posmod(main.demo.fuse_setting + (h2 if h2 != 0 else 1), 3)
				"eventos":
					if h2 != 0 or c2:
						main.event_level = posmod(main.event_level + (h2 if h2 != 0 else 1), 4)
				"escolher":
					if c2:
						main.state = S.EVENTOS
				"itens":
					if h2 != 0 or c2:
						main.demo.items_on = not main.demo.items_on
				"comecar":
					if c2:
						main.demo.cfg["rounds_to_win"] = STAR_GOALS[goal_sel]
						main.go_join()
			if pressed("back"):
				if main.selecao.ativo_para(main.arena_choice):
					main.state = S.SELEVENTOS
				else:
					main.state = S.ARENAS
		S.SELSPELLS:
			main.selecao.update_spells(self)
		S.SELEVENTOS:
			main.selecao.update_eventos(self)
		S.EVENTOS:
			main.events.menu_update(self)
		S.CONTROLES:
			_update_pads()
		S.CONFIGPAD:
			_update_config(dt)
		S.ARENAS:
			var n := arena_list().size()
			arena_sel = posmod(arena_sel + move_h(), n)
			var v := move_v()
			if v != 0:
				arena_sel = clampi(arena_sel + v * 4, 0, n - 1)
			if confirm():
				main.arena_choice = arena_list()[arena_sel]["id"]
				if main.arena_choice == "sorteio" and main.game_mode == "derruba":
					# Derruba: "?" = o jogo escolhe o mapa agora; depois a configuração é a mesma de quem escolheu o mapa
					var reais: Array = main.demo.mode_arenas("derruba").filter(func(a): return main.selecao.ativo_para(String(a["id"])))
					if not reais.is_empty():
						main.arena_choice = String(reais[main.rng.randi_range(0, reais.size() - 1)]["id"])
						main.float_text(Vector2(960, 540), "SORTEADO: " + String(MapaReg.manifesto("derruba", main.arena_choice).get("nome", main.arena_choice)).to_upper(), Color("#f2c84b"))
				if main.selecao.ativo_para(main.arena_choice):
					main.selecao.abrir_spells()   # Derruba v2: MAPA → SPELLS → EVENTOS → AJUSTES
				else:
					main.state = S.AJUSTES
			elif pressed("back"):
				main.state = S.MODES
		S.OPTIONS:
			opt_sel = posmod(opt_sel + move_v(), 9)
			var h := move_h()
			var c := confirm()
			if opt_sel == 0 and (h != 0 or c):
				main.toggle_fullscreen()
			elif opt_sel == 1 and (h != 0 or c):
				main.shake_on = not main.shake_on
			elif opt_sel == 2 and (h != 0 or c):
				main.bot_level = posmod(main.bot_level + (h if h != 0 else 1), 3)
			elif opt_sel == 3 and h != 0:
				Audio.set_volumes(Audio.music_vol + h, Audio.sfx_vol)
			elif opt_sel == 4 and h != 0:
				Audio.set_volumes(Audio.music_vol, Audio.sfx_vol + h)
				Audio.play("caixote_pancada")
			elif opt_sel == 5 and (h != 0 or c):
				PlayerInput.vibration = not PlayerInput.vibration
				if PlayerInput.vibration:
					for j in Input.get_connected_joypads():
						Input.start_joy_vibration(j, 0.5, 0.5, 0.25)
			elif opt_sel == 6 and c:
				main.state = S.CONTROLES
				pad_prev.clear()
			elif opt_sel == 7 and c:
				start_config()
			elif opt_sel == 8 and c:
				main.state = S.MENU
			if h != 0 or c:
				main.save_options()
			if pressed("back"):
				main.state = S.MENU

## Pausa (dentro da partida): Start/Enter abre; navega com ▲▼.
func update_pause() -> void:
	pause_sel = posmod(pause_sel + move_v(), PAUSE_ITEMS.size())
	if pressed("back"):
		main.paused = false
	elif confirm():
		match pause_sel:
			0: main.paused = false
			1:
				main.paused = false
				main.start_match()
			2:
				main.paused = false
				main.go_menu()

# ---------------------------------------------------------------- desenho
func draw(ci: CanvasItem) -> void:
	var S = main.S
	if main.state != S.INTRO and main.state in main.MENU_STATES:
		_draw_scene(ci, [1.0, 1.0, 1.0, 1.0])
	match main.state:
		S.MENU: _draw_menu(ci)
		S.MODES: _draw_modes(ci)
		S.HOWTO: _draw_howto(ci)
		S.OPTIONS: _draw_options(ci)
		S.ARENAS: _draw_arenas(ci)
		S.AJUSTES: _draw_adjust(ci)
		S.EVENTOS: main.events.menu_draw(ci, self)
		S.SELSPELLS: main.selecao.draw_spells(ci)
		S.SELEVENTOS: main.selecao.draw_eventos(ci)
		S.CONTROLES: _draw_pads(ci)
		S.INTRO: _draw_intro(ci)
		S.CONFIGPAD: _draw_config(ci)
	if main.paused:
		if main.sandbox and main.tester().open:
			main.tester().draw(ci)
		else:
			_draw_pause(ci)

## Qual dispositivo confirmou agora (vira o P1 do Laboratório).
func _who_confirmed() -> String:
	for dev in PlayerInput.all_devices():
		if PlayerInput.dev_pressed(dev, "jump") or PlayerInput.dev_pressed(dev, "start"):
			return dev
	return "kb_a"

func _logo(ci: CanvasItem, y: float, w: float) -> void:
	var h := w * 340.0 / 1700.0
	var bob := sin(t * 1.6) * 6.0 * menu_in
	ci.draw_texture_rect(Data.tex("ui/logo"), Rect2(960 - w / 2, y + bob, w, h), false)

## Botão cartoon: creme com contorno; o selecionado fica amarelo, maior, inclinado e com letras brancas contornadas.
func _button(ci: CanvasItem, r: Rect2, label: String, on: bool, rot := 0.0) -> void:
	var c := r.get_center()
	ci.draw_set_transform(c, (rot * 1.5 + sin(t * 5.0) * 0.012) if on else 0.0, Vector2.ONE * (1.08 if on else 1.0))
	var rr := Rect2(-r.size / 2.0, r.size)
	Kit.chunk(ci, rr, Kit.YEL if on else Kit.CREAM, int(minf(28.0, rr.size.y * 0.32)))
	var fs := int(clampf(rr.size.y * 0.5, 22.0, 48.0))
	var f := Kit.font()
	while fs > 18 and f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rr.size.x - 40:
		fs -= 2
	if on:
		Kit.text(ci, Vector2(rr.position.x, fs * 0.36), label, fs, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, int(fs * 0.22))
	else:
		Kit.text(ci, Vector2(rr.position.x, fs * 0.36), label, fs, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
	ci.draw_set_transform(Vector2.ZERO)

func _draw_menu(ci: CanvasItem) -> void:
	_logo(ci, 30, 1000)
	menu_in = minf(menu_in + get_process_delta_time() / 0.45, 1.0)
	for i in MENU_ITEMS.size():
		var u := _ease_out_back(clampf(menu_in * 1.6 - i * 0.12, 0.0, 1.0))
		_button(ci, Rect2(960 - 240 - 1400.0 * (1.0 - u), 262 + i * 112, 480, 86), MENU_ITEMS[i], sel == i, (-0.025 if i % 2 == 0 else 0.025))
	Kit.pad_hint(ci, 960, 1044, ["▲▼ escolher   ", ["baixo"], " confirmar   ", ["direita"], " voltar"], 28, Color.WHITE, PlayerInput.main_pad_type(), 7)

## Ilustração do cartão; xf = transformação do cartão (girado), para não perdê-la ao desenhar peças giradas.
func _mode_art(ci: CanvasItem, id: String, c: Vector2, xf: Transform2D) -> void:
	match id:
		"derruba":
			for k in 3:
				ci.draw_texture_rect(Data.tex("cenario/caixote_%d" % k), Rect2(c + Vector2(-96 + k * 64, 20), Vector2(64, 64)), false)
			RobotVis.draw_robot(ci, {"color": 0, "model": 0}, RobotVis.victory_pose(t), xf * Transform2D(0.0, Vector2(1.2, 1.2), 0.0, c + Vector2(-30, 20)))
			RobotVis.draw_robot(ci, {"color": 2, "model": 2}, RobotVis.idle_pose(t), xf * Transform2D(-0.6 + sin(t * 3.0) * 0.2, Vector2(1.0, 1.0), 0.0, c + Vector2(90, -40)))
			ci.draw_set_transform_matrix(xf)
			for k in 3:
				_heart(ci, c + Vector2(-50 + k * 50, -120), 14.0)
		"batata":
			ci.draw_set_transform_matrix(xf * Transform2D(sin(t * 8.0) * 0.15, c))
			ci.draw_texture_rect(Data.tex("itens/dinamite"), Rect2(-70, -80, 140, 140), false)
			if fmod(t, 0.3) < 0.15:
				ci.draw_circle(Vector2(40, -78), 9, Color("#fff4c8"))
		"rei":
			ci.draw_texture_rect(Data.tex("cenario/caixote_0"), Rect2(c + Vector2(-48, 20), Vector2(96, 64)), false)
			ci.draw_texture_rect(Data.tex("itens/capacete"), Rect2(c + Vector2(-56, -84), Vector2(112, 112)), false, Color(1.0, 0.85, 0.3))
		"fuga":
			for k in 4:
				ci.draw_set_transform_matrix(xf * Transform2D(sin(k * 2.1) * 0.12, c + Vector2(sin(k * 1.3) * 10.0, 60 - k * 46)))
				ci.draw_texture_rect(Data.tex("cenario/caixote_%d" % (k % 3)), Rect2(-30, -24, 60, 48), false)
	ci.draw_set_transform_matrix(xf)

func _heart(ci: CanvasItem, c: Vector2, sz: float) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		var a := k * TAU / 32.0
		pts.append(c + Vector2(16.0 * pow(sin(a), 3), -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))) * sz / 16.0)
	ci.draw_colored_polygon(pts, Color("#e5484d"))
	ci.draw_polyline(pts, Kit.INK, 3.0, true)

func _draw_modes(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 40, 800, 128), "ESCOLHA O MODO", 60)
	var modes: Array = main.demo.cfg["modos"]
	var n := modes.size()
	for i in n:
		var m: Dictionary = modes[i]
		var on := i == mode_sel
		var cx := 960 + (i - mode_sel) * 380.0
		var sz := Vector2(340, 470) * (1.08 if on else 0.92)
		var cy := 560.0 + (0.0 if on else 20.0)
		var rot := sin(i * 1.7) * 0.03
		if on and shake_card > 0.0:
			rot += sin(shake_card * 60.0) * 0.05
		var xf := Transform2D(rot, Vector2(cx, cy))
		ci.draw_set_transform_matrix(xf)
		var r := Rect2(-sz / 2.0, sz)
		if on:
			Kit.paper(ci, r.grow(12), Color("#f2c84b"))
		Kit.paper(ci, r, Color.WHITE if m["ok"] else Color(0.85, 0.85, 0.85))
		_mode_art(ci, m["id"], Vector2(0, -90), xf)
		Kit.text(ci, Vector2(r.position.x, 70), m["nome"], 38 if String(m["nome"]).length() < 12 else 30, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var lines: PackedStringArray = String(m["dica"]).split("\n")
		for k in lines.size():
			Kit.text(ci, Vector2(r.position.x, 118 + k * 32), lines[k], 23, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if not m["ok"]:
			ci.draw_texture_rect(Data.tex("ui/em_breve"), Rect2(-130, -150, 260, 95), false)
		ci.draw_set_transform(Vector2.ZERO)
	Kit.text(ci, Vector2(0, 1056), "◄► modo  ·  PULAR confirmar  ·  BACKSPACE/ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

func _draw_adjust(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 30, 800, 128), "AJUSTES DA PARTIDA", 54)
	var sname: String = main.demo.find_mode(main.game_mode)["nome"]
	var aname := "Sorteio"
	for a in main.demo.cfg["arenas"]:
		if a["id"] == main.arena_choice:
			aname = a["nome"]
	Kit.sticker(ci, Vector2(0, 205), "%s  ·  %s" % [sname, aname], 34, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, 1920)
	var labels := {
		"estrelas": "★ PARA VENCER:  ◄ %d ►" % STAR_GOALS[goal_sel],
		"vidas": "VIDAS:  ◄ %d ►" % main.demo.lives_setting,
		"pavio": "PAVIO:  ◄ %s ►" % ["CURTO", "NORMAL", "LONGO"][main.demo.fuse_setting],
		"rei": "SEGUNDOS PARA VENCER:  ◄ %d ►" % main.demo.KING_GOALS[main.demo.king_setting],
		"eventos": "EVENTOS (INTENSIDADE):  ◄ %s ►" % EVENT_LEVELS[main.event_level],
		"escolher": "ESCOLHER EVENTOS  ▸",
		"itens": "ENGENHOCAS:  ◄ %s ►" % ("SIM" if main.demo.items_on else "NÃO"),
		"comecar": "COMEÇAR  ▸",
	}
	var rows := adjust_rows()
	var step := minf(112.0, 800.0 / rows.size())
	for i in rows.size():
		_button(ci, Rect2(510, 260 + i * step, 900, step - 20), labels[rows[i]], adj_sel == i)
	Kit.text(ci, Vector2(0, 1056), "▲▼ escolher  ·  ◄► muda  ·  PULAR confirmar  ·  BACKSPACE/ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

## Linhas da tela de AJUSTES (mudam conforme o modo).
func adjust_rows() -> Array:
	var rows := [] if main.estrelas_da_sessao() else ["estrelas"]   # Derruba v2: uma luta só (sem meta de estrelas)
	match main.game_mode:
		"derruba": rows.append("vidas")
		"batata": rows.append("pavio")
		"rei": rows.append("rei")
	if main.selecao.ativo_para(main.arena_choice):
		rows.append_array(["eventos", "itens", "comecar"])   # eventos escolhidos no mosaico (D3); aqui só a frequência
	else:
		rows.append_array(["eventos", "escolher", "itens", "comecar"])
	return rows

## SORTEIO + arenas do modo escolhido (data/modos.json → modos[].arenas).
func arena_list() -> Array:
	var out: Array = [{"id": "sorteio", "nome": "SORTEIO", "dica": "Cada rodada numa arena do modo"}]
	out.append_array(main.demo.mode_arenas(main.game_mode))
	return out

func _draw_arenas(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 30, 800, 128), "ESCOLHA O MAPA" if main.game_mode == "derruba" else "ESCOLHA A ARENA", 58)
	var list := arena_list()
	var nrows: int = int(ceil(list.size() / 4.0))
	var sc := minf(1.0, 860.0 / (nrows * 400.0 - 70.0))   # mais arenas: cartões menores
	for i in list.size():
		var a: Dictionary = list[i]
		var on := i == arena_sel
		var col := i % 4
		var row := i / 4
		var c := Vector2(255 + col * 470, 175 + 165 * sc + row * 400 * sc)
		var xf := Transform2D(sin(i * 1.9) * 0.025, Vector2(sc, sc) * (1.06 if on else 1.0), 0.0, c)
		ci.draw_set_transform_matrix(xf)
		var r := Rect2(-205, -165, 410, 330)
		if on:
			Kit.paper(ci, r.grow(12), Color("#f2c84b"))
		Kit.paper(ci, r)
		var thumb := Data.tex("ui/arena_" + a["id"])
		var tr := Rect2(-180, -142, 360, 192)
		if a["id"] == "sorteio":
			ci.draw_rect(tr, Color("#9fe3ee"))
			Kit.sticker(ci, Vector2(-180, 0), "?", 150, Color("#f2c84b"), HORIZONTAL_ALIGNMENT_CENTER, 360)
		elif thumb != null:
			ci.draw_texture_rect(thumb, tr, false)
		else:
			ci.draw_rect(tr, Color("#9fe3ee"))
		Kit.text(ci, Vector2(r.position.x, 100), String(a["nome"]).to_upper(), 34 if String(a["nome"]).length() < 15 else 28, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text_box(ci, Vector2(r.position.x + 14, 116), r.size.x - 28, String(a["dica"]), 21, Color("#6b5a70"), 2)
		var mf: Dictionary = MapaReg.manifesto(main.game_mode, String(a["id"])) if main.game_mode == "derruba" else {}
		if not mf.is_empty():   # perfil (D4): cenas descobertas deste mapa
			var vis: int = main.perfil.dados.get("cenas_visitadas", {}).get(a["id"], []).size()
			Kit.chunk(ci, Rect2(40, -156, 150, 40), Color("#5fc95f") if vis > 0 else Kit.CREAM, 12, 4, 4.0)
			Kit.text(ci, Vector2(40, -127), "%d de %d cenas" % [vis, int(mf.get("topologia", 0))], 20, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, 150)
	ci.draw_set_transform(Vector2.ZERO)
	if main.game_mode == "derruba":
		_draw_projetos(ci, Rect2(560, 900, 800, 110))
	Kit.text(ci, Vector2(0, 1056), "◄►▲▼ escolher  ·  PULAR confirmar  ·  BACKSPACE/ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

## Projetos de Demolição (perfil, D4): pontos para liberar o próximo mapa. Só na seleção de mapas e nos resultados.
func _draw_projetos(ci: CanvasItem, rr: Rect2) -> void:
	var pm := int(MapaReg.modo_cfg("derruba").get("progressao", {}).get("pontos_por_mapa", 6))
	var tot := int(main.perfil.dados.get("pontos_exploracao", 0))
	Kit.chunk(ci, rr, Kit.CREAM, 22, 6, 9.0)
	Kit.text(ci, Vector2(rr.position.x + 30, rr.position.y + 48), "PROJETOS DE DEMOLIÇÃO", 26, Kit.INK)
	for k in pm:
		Kit.chunk(ci, Rect2(rr.position.x + 30 + k * 52, rr.position.y + 62, 44, 34), Color("#5fc95f") if k < mini(tot, pm) else Color("#e2d9c6"), 8, 4, 0.0)
	Kit.text(ci, Vector2(rr.position.x + 360, rr.position.y + 88), "%d de %d → você escolhe o próximo mapa" % [mini(tot, pm), pm], 22, Kit.SOFT)

func _draw_howto(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 30, 800, 128), "COMO JOGAR", 60)
	var r := Rect2(160, 180, 1600, 780)
	Kit.paper(ci, r)
	var tips := [
		["robo", "Derrube os outros no poço de espinhos. O último em pé ganha uma ★."],
		["marreta", "GOLPE RÁPIDO (X/□): empurra e interrompe. MARRETADA PESADA (Y/△): demora,\nmas arremessa longe e quebra caixotes (▼ + pesada quebra o chão). Errou? Fica exposto."],
		["pisao", "ESQUIVA (RB/R1): escapa de golpes por um instante, no chão ou 1 vez no ar.\nArremessado? Segure a direção para corrigir e use a esquiva para se salvar."],
		["itens", "Caixas de ENGENHOCA: a cor mostra a família (ataque, controle, engenharia, transformação).\nEncoste para pegar · ESPECIAL usa · segure ESPECIAL em cima de outra caixa para trocar."],
		["parado", "Caixote racha se você fica parado em cima. No fim da rodada, TERREMOTO!"],
	]
	for i in tips.size():
		var y := r.position.y + 80 + i * 140
		var ic: String = tips[i][0]
		var c := Vector2(r.position.x + 120, y + 30)
		match ic:
			"robo": RobotVis.draw_robot(ci, {"color": 0, "model": 0}, RobotVis.victory_pose(t), Transform2D(0.0, Vector2(1.1, 1.1), 0.0, c + Vector2(0, 50)))
			"marreta":
				ci.draw_set_transform(c, 0.6 + sin(t * 5.0) * 0.5, Vector2(0.45, 0.45))
				ci.draw_texture(Data.tex("robo/marreta"), Vector2(-128, -224))
			"pisao":
				var po: Dictionary = RobotVis.idle_pose(t)
				po["expr"] = "susto"
				RobotVis.draw_robot(ci, {"color": 2, "model": 2}, po, Transform2D(0.0, Vector2(0.9, 0.9), 0.0, c + Vector2(0, 60)))
			"itens":
				var names := ["ataque", "controle", "engenharia", "transformacao"]
				for k in 4:
					ci.draw_texture_rect(Data.tex("spells/caixa_" + names[k]), Rect2(c + Vector2(-70 + (k % 2) * 60, -40 + (k / 2) * 52), Vector2(54, 54)), false)
			"parado":
				ci.draw_texture_rect(Data.tex("cenario/caixote_0"), Rect2(c - Vector2(40, 30), Vector2(80, 80)), false)
		ci.draw_set_transform(Vector2.ZERO)
		var lines: PackedStringArray = String(tips[i][1]).split("\n")
		for k in lines.size():
			Kit.text(ci, Vector2(r.position.x + 260, y + 44 - (lines.size() - 1) * 18 + k * 40), lines[k], 32, Color("#2a1a2e"))
	Kit.text(ci, Vector2(0, 1050), "Teclado A: WASD · Espaço pula · F golpe · R pesada · Shift esq. esquiva · G especial     Teclado B: setas · Ctrl dir. pula · ponto golpe · / pesada · 0 num. esquiva · vírgula especial", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)

func _draw_options(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 60, 800, 128), "OPÇÕES", 60)
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	var items := [
		"TELA CHEIA:  %s" % ("SIM" if full else "NÃO"),
		"TREMOR DA TELA:  %s" % ("SIM" if main.shake_on else "NÃO"),
		"BOTS:  %s" % main.bots.LEVEL_NAMES[main.bot_level].to_upper(),
		"MÚSICA:  ◄ %s ►" % _bar(Audio.music_vol),
		"EFEITOS:  ◄ %s ►" % _bar(Audio.sfx_vol),
		"VIBRAÇÃO:  %s" % ("SIM" if PlayerInput.vibration else "NÃO"),
		"TESTAR CONTROLES  ▸",
		"CONFIGURAR CONTROLE  ▸",
		"VOLTAR",
	]
	for i in items.size():
		_button(ci, Rect2(560, 190 + i * 92, 800, 76), items[i], opt_sel == i)
	Kit.text(ci, Vector2(0, 1056), "▲▼ escolher  ·  ◄► ou PULAR muda", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

func _bar(v: int) -> String:
	return "■".repeat(v) + "□".repeat(10 - v)

func _draw_pause(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.1, 0.25, 0.3, 0.55))
	Kit.ribbon(ci, Rect2(610, 180, 700, 128), "PAUSA", 64)
	if not main.lost_pads.is_empty():
		var r := Rect2(460, 40, 1000, 120)
		Kit.paper(ci, r, Color(1, 0.86, 0.82))
		var who := ", ".join(main.lost_pads.map(func(i): return "P%d" % (i + 1)))
		Kit.text(ci, Vector2(r.position.x, r.position.y + 52), "CONTROLE DESCONECTADO: %s" % who, 38, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 94), "Reconecte (USB ou Bluetooth) ou aperte START em outro controle", 24, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i in PAUSE_ITEMS.size():
		_button(ci, Rect2(610, 380 + i * 140, 700, 100), PAUSE_ITEMS[i], pause_sel == i)

# ---------------------------------------------------------------- testar controles
var pad_prev := {}   # joy -> {botão: bool} (bordas para vibrar e sair)

func _pad_edge(j: int, b: int) -> bool:
	var now := Input.is_joy_button_pressed(j, b)
	var key := "%d:%d" % [j, b]
	var was: bool = pad_prev.get(key, false)
	pad_prev[key] = now
	return now and not was

func _update_pads() -> void:
	# sai com Esc/Backspace ou SELECT (B não sai: aqui ele é testado)
	if PlayerInput.dev_pressed("kb_a", "back") or PlayerInput.dev_pressed("kb_b", "back"):
		main.state = main.S.OPTIONS
		Audio.play("menu_voltar")
		return
	for j in Input.get_connected_joypads():
		if _pad_edge(j, JOY_BUTTON_BACK):
			main.state = main.S.OPTIONS
			Audio.play("menu_voltar")
			return
		if _pad_edge(j, JOY_BUTTON_A):
			Input.start_joy_vibration(j, 0.6, 0.6, 0.2)   # PULAR vibra: testa o motor
			Audio.play("pulo")
		if _pad_edge(j, JOY_BUTTON_X):
			Audio.play("marreta_vento")
		if _pad_edge(j, JOY_BUTTON_Y) or _pad_edge(j, JOY_BUTTON_B):
			Audio.play("item")

func _draw_pads(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.5))
	Kit.ribbon(ci, Rect2(560, 20, 800, 128), "TESTAR CONTROLES", 54)
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		var r := Rect2(260, 190, 1400, 760)
		Kit.paper(ci, r)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 90), "NENHUM CONTROLE DETECTADO", 50, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var tips := [
			"USB: ligue o cabo — aparece aqui na hora.",
			"Xbox (Bluetooth): Windows ▸ Bluetooth ▸ Adicionar dispositivo; segure o botão de parear do controle.",
			"PlayStation (DualSense/DualShock 4): segure CREATE/SHARE + PS até a luz piscar e pareie no Bluetooth.",
			"Switch Pro / 8BitDo: modo X-input (Xbox) funciona melhor; pareie pelo Bluetooth do Windows.",
			"Steam aberta pode esconder ou duplicar o controle (Steam Input): feche a Steam se algo estranho acontecer.",
			"Rodando dentro do editor: clique na janela do jogo para ela ter o foco.",
		]
		for i in tips.size():
			Kit.text(ci, Vector2(r.position.x + 70, r.position.y + 190 + i * 88), "•  " + tips[i], 27, Color("#3b2b40"))
	else:
		var n: int = mini(pads.size(), 4)
		var cw := 430.0
		var x0 := 960.0 - (n * cw + (n - 1) * 20.0) / 2.0
		for k in n:
			_draw_pad_card(ci, pads[k], Rect2(x0 + k * (cw + 20.0), 180, cw, 780), k)
	Kit.text(ci, Vector2(0, 990), "Botões trocados ou o robô não responde?  OPÇÕES ▸ CONFIGURAR CONTROLE", 24, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	Kit.text(ci, Vector2(0, 1022), "relatório dos controles: " + ProjectSettings.globalize_path("user://controles.txt"), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	Kit.text(ci, Vector2(0, 1056), "Aperte os botões para ver acender  ·  PULAR vibra  ·  SELECT ou ESC volta", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

func _draw_pad_card(ci: CanvasItem, j: int, r: Rect2, k: int) -> void:
	Kit.paper(ci, r)
	var dev := "joy%d" % j
	var st: String = PlayerInput.pad_type(dev)
	var dark := Color("#2a1a2e")
	Kit.text(ci, Vector2(r.position.x, r.position.y + 60), "CONTROLE %d" % (j + 1), 40, dark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var nm := Input.get_joy_name(j)
	Kit.text(ci, Vector2(r.position.x + 20, r.position.y + 96), nm.substr(0, 30), 22, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 40)
	var tname := {"xbox": "tipo Xbox", "ps": "tipo PlayStation", "nintendo": "tipo Nintendo", "generico": "genérico (botões como Xbox)"}
	Kit.text(ci, Vector2(r.position.x, r.position.y + 128), tname.get(st, ""), 22, Color("#3c9a46"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var used: int = PlayerInput.slots.find(dev)
	if used >= 0:
		Kit.text(ci, Vector2(r.position.x, r.position.y + 158), "jogando como P%d" % (used + 1), 22, Data.TEXT_COLORS[main.players[used]["color"]] if used < main.players.size() else dark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	elif PlayerInput.aliases.has(dev):
		Kit.text(ci, Vector2(r.position.x, r.position.y + 158), "cópia do mesmo controle (usado junto)", 20, Color("#8a5a10"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# diagnóstico: mapeamento reconhecido e último sinal cru recebido
	var known := Input.is_joy_known(j)
	Kit.text(ci, Vector2(r.position.x, r.end.y - 40), ("mapeamento reconhecido" if known else "mapeamento DESCONHECIDO (botões podem vir trocados)"), 19,
		Color("#3c9a46") if known else Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(ci, Vector2(r.position.x, r.end.y - 14), "último sinal: %s" % String(PlayerInput.last_raw.get(j, "—")), 19, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(ci, Vector2(r.position.x + 10, r.end.y - 66), PlayerInput.raw_now(j), 18, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 20)
	if PlayerInput.custom.has(Input.get_joy_guid(j)):
		Kit.text(ci, Vector2(r.position.x, r.end.y - 92), "usando a SUA configuração", 19, Color("#3c9a46"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# corpo do controle
	var c := Vector2(r.get_center().x, r.position.y + 360)
	var body := Rect2(c - Vector2(180, 95), Vector2(360, 190))
	ci.draw_rect(body, Color("#d5dbe1"))
	ci.draw_circle(body.position + Vector2(40, 150), 70, Color("#d5dbe1"))
	ci.draw_circle(body.end - Vector2(40, 40), 70, Color("#d5dbe1"))
	# gatilhos e ombros
	var lt := Input.get_joy_axis(j, JOY_AXIS_TRIGGER_LEFT)
	var rt := Input.get_joy_axis(j, JOY_AXIS_TRIGGER_RIGHT)
	for side in [-1, 1]:
		var tr := Rect2(c + Vector2(side * 125 - 40, -165), Vector2(80, 26))
		ci.draw_rect(tr, Color("#9aa4ae"))
		var v: float = rt if side > 0 else lt
		ci.draw_rect(Rect2(tr.position, Vector2(tr.size.x * clampf(v, 0.0, 1.0), tr.size.y)), Color("#f2c84b"))
		Kit.text(ci, Vector2(tr.position.x, tr.position.y - 6), ("RT" if side > 0 else "LT") if st != "ps" else ("R2" if side > 0 else "L2"), 18, dark, HORIZONTAL_ALIGNMENT_CENTER, tr.size.x)
		Kit.pad_btn(ci, c + Vector2(side * 125, -112), 18, "rb" if side > 0 else "lb", st, Input.is_joy_button_pressed(j, JOY_BUTTON_RIGHT_SHOULDER if side > 0 else JOY_BUTTON_LEFT_SHOULDER))
	# analógicos
	for stick in [[JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, Vector2(-120, -20), JOY_BUTTON_LEFT_STICK], [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, Vector2(60, 50), JOY_BUTTON_RIGHT_STICK]]:
		var sc: Vector2 = c + stick[2]
		ci.draw_circle(sc, 36, Color("#5a6370"))
		var ax := Vector2(Input.get_joy_axis(j, stick[0]), Input.get_joy_axis(j, stick[1]))
		ci.draw_circle(sc + ax * 22.0, 22, Color("#f2c84b") if Input.is_joy_button_pressed(j, stick[3]) else Color("#2f3640"))
	# direcional
	var dc := c + Vector2(-60, 50)
	for d in [[JOY_BUTTON_DPAD_UP, Vector2(0, -22)], [JOY_BUTTON_DPAD_DOWN, Vector2(0, 22)], [JOY_BUTTON_DPAD_LEFT, Vector2(-22, 0)], [JOY_BUTTON_DPAD_RIGHT, Vector2(22, 0)]]:
		ci.draw_rect(Rect2(dc + d[1] - Vector2(12, 12), Vector2(24, 24)), Color("#f2c84b") if Input.is_joy_button_pressed(j, d[0]) else Color("#2f3640"))
	ci.draw_rect(Rect2(dc - Vector2(12, 12), Vector2(24, 24)), Color("#2f3640"))
	# botões de ação
	var fc := c + Vector2(120, -20)
	for b in [["baixo", Vector2(0, 30), JOY_BUTTON_A], ["direita", Vector2(30, 0), JOY_BUTTON_B], ["esquerda", Vector2(-30, 0), JOY_BUTTON_X], ["cima", Vector2(0, -30), JOY_BUTTON_Y]]:
		Kit.pad_btn(ci, fc + b[1], 16, b[0], st, Input.is_joy_button_pressed(j, b[2]))
	Kit.pad_btn(ci, c + Vector2(-34, -40), 12, "select", st, Input.is_joy_button_pressed(j, JOY_BUTTON_BACK))
	Kit.pad_btn(ci, c + Vector2(34, -40), 12, "start", st, Input.is_joy_button_pressed(j, JOY_BUTTON_START))
	# o que faz cada botão no jogo
	var y := r.position.y + 500
	for line in [[["baixo"], " pula"], [["esquerda"], " golpe rápido"], [["cima"], " marretada pesada"], [["rb"], " esquiva"], [["lb"], " especial (engenhoca)"], [["start"], " pausa / começa"], [["direita"], " volta nos menus"]]:
		var parts: Array = []
		for e in line:
			parts.append(e)
		Kit.pad_hint(ci, r.get_center().x, y, parts, 24, dark, st)
		y += 38

# ---------------------------------------------------------------- intro animada (abre o jogo)
## O logo cai e quica, bate levantando poeira, os robôs entram correndo e acenam, e o logo desliza até o menu.
func _update_intro(dt: float) -> void:
	intro_frames += 1
	if intro_frames < 4:
		return   # primeiros quadros (carregando a tela): o relógio da animação só anda depois
	intro_t += minf(dt, 1.0 / 30.0)   # sem pulos se um quadro demorar
	if not intro_hit and intro_t >= 0.55:
		intro_hit = true
		Audio.play("caixote_pancada", 0.8)
		Audio.play("pisao", 0.7)
		main.shake(10.0)
	if not intro_hi and intro_t >= 1.25:
		intro_hi = true
		Audio.voice("voz_oi", 0)
	if intro_t < 1.8 and (confirm() or pressed("start") or pressed("back")):
		intro_t = 1.8   # qualquer botão pula para o final da intro
	if intro_t >= INTRO_END:
		main.state = main.S.MENU
		sel = 0
		menu_in = 0.0

static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3) + c1 * pow(x - 1.0, 2)

static func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _draw_intro(ci: CanvasItem) -> void:
	var k := intro_t
	# fundo: céu cheio no começo, some no fim revelando o menu
	var fade := 1.0 - _smooth((k - 1.8) / 0.7)
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.498, 0.827, 0.875, fade))
	# raios girando atrás do logo
	if fade > 0.0:
		for i in 12:
			var a := i * TAU / 12.0 + k * 0.4
			var p0 := Vector2(960, 420)
			ci.draw_colored_polygon(PackedVector2Array([p0, p0 + Vector2.from_angle(a - 0.12) * 1400.0, p0 + Vector2.from_angle(a + 0.12) * 1400.0]), Color(1, 1, 1, 0.10 * fade * _smooth(k / 0.6)))
	# o cenário do menu (chão e robôs) já está lá: os robôs entram correndo até os lugares deles
	var ent := []
	for i in 4:
		ent.append(_smooth((k - 0.7 - i * 0.1) / 0.6))
	_draw_scene(ci, ent)
	# logo: cai com quique, amassa no impacto, respira, e desliza para o lugar do menu
	var tex := Data.tex("ui/logo")
	var w0 := 1500.0
	var c0 := Vector2(960, 400)
	var w1 := 1180.0
	var c1 := Vector2(960, 40 + w1 * 340.0 / 1700.0 / 2.0)
	var drop := clampf(k / 0.55, 0.0, 1.0)
	var c := Vector2(960, lerpf(-320.0, c0.y, _ease_out_back(drop) if drop < 1.0 else 1.0))
	var sq := Vector2.ONE
	if k >= 0.55 and k < 0.95:
		var u := (k - 0.55) / 0.4
		var s := sin(u * PI * 2.0) * (1.0 - u) * 0.14
		sq = Vector2(1.0 + s, 1.0 - s)
	var move := _smooth((k - 1.8) / 0.7)
	var w := lerpf(w0, w1, move)
	c = c.lerp(c1, move)
	c.y += sin(k * 2.2) * 6.0 * (1.0 - move) * float(k > 0.95)
	var h := w * 340.0 / 1700.0
	if tex != null:
		ci.draw_set_transform(c, sin(k * 1.7) * 0.015 * (1.0 - move), sq)
		ci.draw_texture_rect(tex, Rect2(Vector2(-w / 2.0, -h / 2.0), Vector2(w, h)), false)
		ci.draw_set_transform(Vector2.ZERO)
	# poeira e estrelinhas no impacto
	if k >= 0.55 and k < 1.4:
		var u := (k - 0.55) / 0.85
		for i in 10:
			var side := -1.0 if i % 2 == 0 else 1.0
			var px := 960.0 + side * (200.0 + (i / 2) * 120.0 + u * 160.0)
			var py := c0.y + h * 0.42 - u * 40.0 * (1.0 + (i % 3) * 0.4)
			ci.draw_circle(Vector2(px, py), (22.0 + (i % 3) * 8.0) * (1.0 - u * 0.6), Color(0.97, 0.94, 0.86, 0.85 * (1.0 - u)))
		for i in 8:
			var a := i * TAU / 8.0
			var sp := c0 + Vector2.from_angle(a) * (300.0 + u * 420.0) * Vector2(1.6, 0.6)
			var sz := 14.0 * (1.0 - u)
			Kit.star(ci, sp, sz * 2.0, true)
	if k > 1.0 and k < 1.8:
		var a := clampf((k - 1.0) / 0.3, 0.0, 1.0) * (0.6 + 0.4 * sin(k * 6.0))
		Kit.text(ci, Vector2(0, 1030), "aperte qualquer botão", 30, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6, Color(0.12, 0.3, 0.33, a))

# ---------------------------------------------------------------- configurar controle (aprende os sinais do controle)
const LEARN_NAMES := {"jump": "PULAR", "hammer": "GOLPE RÁPIDO", "heavy": "MARRETADA PESADA", "dodge": "ESQUIVA", "item": "ESPECIAL (ENGENHOCA)", "start": "START (começar / pausar)", "back": "VOLTAR (nos menus)",
	"left": "ESQUERDA (analógico ou direcional)", "right": "DIREITA", "up": "CIMA", "down": "BAIXO"}
var cfg_step := -1          # -1 = esperando escolher o controle; 0..8 = ação; 9 = pronto
var cfg_joy := -1
var cfg_map := {}
var cfg_base := {}          # estado cru no início do passo (ignora botão/eixo que já estava "preso")
var cfg_wait := 0.0         # pausa entre passos (e espera soltar)
var cfg_msg := ""

func start_config() -> void:
	main.state = main.S.CONFIGPAD
	cfg_step = -1
	cfg_joy = -1
	cfg_map = {}
	cfg_wait = 0.3
	cfg_msg = ""
	_cfg_snapshot()

func _cfg_joys() -> Array:
	var js: Array = Input.get_connected_joypads().duplicate()
	for j in PlayerInput.fake_joys:
		if not j in js:
			js.append(j)
	return js

func _cfg_snapshot() -> void:
	cfg_base = {}
	for j in _cfg_joys():
		var st := {}
		for b in 32:
			st["b%d" % b] = PlayerInput.jbtn(j, b)
		for a in 10:
			st["a%d" % a] = PlayerInput.jaxis(j, a)
		cfg_base[j] = st

## Primeiro sinal novo (botão apertado ou eixo empurrado) desde o começo do passo: [joy, spec] ou [].
func _cfg_detect() -> Array:
	for j in _cfg_joys():
		if cfg_joy >= 0 and j != cfg_joy:
			continue
		var base: Dictionary = cfg_base.get(j, {})
		for b in 32:
			if PlayerInput.jbtn(j, b) and not base.get("b%d" % b, false):
				return [j, ["b", b, 1]]
		for a in 10:
			var v := PlayerInput.jaxis(j, a)
			if absf(v) > 0.7 and absf(float(base.get("a%d" % a, 0.0))) < 0.4:
				return [j, ["a", a, signf(v)]]
	return []

func _cfg_idle(j: int) -> bool:
	var base: Dictionary = cfg_base.get(j, {})
	for b in 32:
		if PlayerInput.jbtn(j, b) and not base.get("b%d" % b, false):
			return false
	for a in 10:
		if absf(PlayerInput.jaxis(j, a)) > 0.4 and absf(float(base.get("a%d" % a, 0.0))) < 0.4:
			return false
	return true

func _update_config(dt: float) -> void:
	if PlayerInput.dev_pressed("kb_a", "back") or PlayerInput.dev_pressed("kb_b", "back"):
		main.state = main.S.OPTIONS   # Esc / Backspace cancela
		Audio.play("menu_voltar")
		return
	if cfg_step >= PlayerInput.LEARN_ACTIONS.size():
		return
	if cfg_wait > 0.0:
		cfg_wait -= dt
		if cfg_wait <= 0.0 and cfg_joy >= 0 and not _cfg_idle(cfg_joy):
			cfg_wait = 0.05   # espera soltar antes do próximo passo
		if cfg_wait <= 0.0:
			_cfg_snapshot()
		return
	if Input.is_key_pressed(KEY_TAB) and cfg_step >= 0:
		cfg_step += 1   # Tab pula esta ação (fica a padrão)
		cfg_wait = 0.3
		_cfg_finish_if_done()
		return
	var hit := _cfg_detect()
	if hit.is_empty():
		return
	if cfg_step < 0:
		cfg_joy = hit[0]   # este é o controle que vai ser configurado
		cfg_step = 0
		cfg_msg = "Configurando: %s" % Input.get_joy_name(cfg_joy)
		Audio.play("menu_ok")
		cfg_wait = 0.4
		return
	var spec: Array = hit[1]
	cfg_map[PlayerInput.LEARN_ACTIONS[cfg_step]] = spec
	Audio.play("item", 1.0 + cfg_step * 0.06)
	cfg_step += 1
	cfg_wait = 0.35
	_cfg_finish_if_done()

func _cfg_finish_if_done() -> void:
	if cfg_step >= PlayerInput.LEARN_ACTIONS.size():
		if cfg_joy >= 0 and not cfg_map.is_empty():
			PlayerInput.save_custom(Input.get_joy_guid(cfg_joy), cfg_map)
		Audio.play("rodada_vence")
		await get_tree().create_timer(1.2).timeout
		if main.state == main.S.CONFIGPAD:
			main.state = main.S.CONTROLES
			pad_prev.clear()

func _draw_config(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.5))
	Kit.ribbon(ci, Rect2(510, 20, 900, 128), "CONFIGURAR CONTROLE", 54)
	var r := Rect2(260, 180, 1400, 800)
	Kit.paper(ci, r)
	var dark := Color("#2a1a2e")
	var acts: Array = PlayerInput.LEARN_ACTIONS
	if cfg_step < 0:
		Kit.text(ci, Vector2(r.position.x, r.position.y + 200), "Aperte QUALQUER botão no controle", 54, dark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 260), "que você quer configurar", 40, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.end.y - 90), "Se NADA acontecer ao apertar: feche a Steam (ou desligue o Steam Input),", 24, Color("#8a5a10"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.end.y - 56), "desconecte e conecte o controle de novo, e abra esta tela outra vez.", 24, Color("#8a5a10"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.end.y - 20), "ESC cancela", 22, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if _cfg_joys().is_empty():
			Kit.text(ci, Vector2(r.position.x, r.position.y + 380), "Nenhum controle detectado pelo Windows.", 34, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			var y := r.position.y + 380
			for j in _cfg_joys():
				Kit.text(ci, Vector2(r.position.x, y), "controle %d: %s" % [j + 1, Input.get_joy_name(j)], 26, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
				y += 40
	elif cfg_step < acts.size():
		Kit.text(ci, Vector2(r.position.x, r.position.y + 70), cfg_msg, 26, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var a: String = acts[cfg_step]
		var verb := "Mova para" if a in ["left", "right", "up", "down"] else "Aperte o botão de"
		Kit.text(ci, Vector2(r.position.x, r.position.y + 230), verb, 40, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var pulse := 1.0 + 0.05 * sin(t * 6.0)
		ci.draw_set_transform(Vector2(960, r.position.y + 320), 0.0, Vector2(pulse, pulse))
		Kit.text(ci, Vector2(-700, 0), LEARN_NAMES[a], 64, Color("#d42035") if cfg_wait <= 0.0 else Color("#3c9a46"), HORIZONTAL_ALIGNMENT_CENTER, 1400)
		ci.draw_set_transform(Vector2.ZERO)
		# progresso
		for i in acts.size():
			var c := Vector2(960 - (acts.size() - 1) * 40 + i * 80, r.position.y + 470)
			ci.draw_circle(c, 20, Color("#5cc45c") if i < cfg_step else (Color("#f2c84b") if i == cfg_step else Color(0.8, 0.78, 0.72)))
		if cfg_joy >= 0:
			Kit.text(ci, Vector2(r.position.x, r.position.y + 580), "sinais agora: " + PlayerInput.raw_now(cfg_joy), 24, dark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.end.y - 40), "TAB (teclado) pula esta ação  ·  ESC cancela", 24, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		Kit.text(ci, Vector2(r.position.x, r.position.y + 330), "PRONTO! Controle configurado.", 56, Color("#3c9a46"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 400), "Agora teste na tela de TESTAR CONTROLES.", 32, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

# ---------------------------------------------------------------- cenário do menu (não depende da fase)
const SCENE_GROUND := 880.0
const SCENE_X := [1010.0, 1150.0, 1440.0, 1680.0]
const SCENE_FACE := [1.0, -1.0, -1.0, -1.0]
const SCENE_SCALE := 2.4

## Chão de caixotes e os quatro robôs em ação: azul marreta o verde (que voa e volta), rosa quica de botas
## de mola, amarelo corre desesperado com o TNT aceso. enter[i] = 0..1 (entrando correndo pela lateral).
func _draw_scene(ci: CanvasItem, enter: Array) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	# chão de caixotes (três fileiras até o fim da tela) e um TNT de enfeite
	for row in 4:
		var x := -16.0
		var y := SCENE_GROUND + row * 64.0
		var i := 0
		while x < 1920.0:
			ci.draw_texture_rect(Data.tex("cenario/caixote_%d" % ((i * 7 + row * 3) % 3)), Rect2(x, y, 64, 64), false)
			x += 64.0
			i += 1
	ci.draw_texture_rect(Data.tex("cenario/tnt"), Rect2(1830, SCENE_GROUND - 64, 64, 64), false)
	ci.draw_texture_rect(Data.tex("cenario/caixote_1"), Rect2(1830, SCENE_GROUND - 128, 64, 64), false)
	var cyc := fmod(now, 1.6) / 1.6   # ciclo da marretada
	for i in 4:
		var e: float = enter[i]
		if e <= 0.0:
			continue
		var side := -1.0 if i < 2 else 1.0
		var base := Vector2(lerpf(SCENE_X[i] + side * 1200.0 * (-1.0 if i < 2 else 1.0) * -1.0, SCENE_X[i], e), SCENE_GROUND)
		if i < 2:
			base.x = lerpf(SCENE_X[i] - 1300.0, SCENE_X[i], e)
		else:
			base.x = lerpf(SCENE_X[i] + 900.0, SCENE_X[i], e)
		var face: float = SCENE_FACE[i]
		var look := {"color": i, "model": i, "hammer": true, "fx": {}}
		var pose: Dictionary = RobotVis.idle_pose(now + i)
		var off := Vector2.ZERO
		if e < 1.0:
			# entrando correndo
			var ph := now * 22.0 + i
			pose["feet"] = [Vector2(cos(ph) * 9.0, -maxf(sin(ph), 0.0) * 8.0), Vector2(cos(ph + PI) * 9.0, -maxf(sin(ph + PI), 0.0) * 8.0)]
			pose["lean"] = 0.15
			face = 1.0 if i < 2 else -1.0
		else:
			match i:
				0:   # marreta: prepara, bate, volta
					var k := clampf(cyc / 0.4, 0.0, 1.0)
					if k < 0.4:
						pose["hammer_ang"] = lerpf(0.35, -1.3, k / 0.4)
						pose["lean"] = -0.1
					elif k < 0.6:
						pose["hammer_ang"] = lerpf(-1.3, 2.4, pow((k - 0.4) / 0.2, 2.0))
						pose["lean"] = 0.25
					else:
						pose["hammer_ang"] = lerpf(2.4, 0.35, (k - 0.6) / 0.4)
					pose["expr"] = "esforco" if k < 0.7 else "normal"
				1:   # levou a marretada: voa para trás e volta
					if cyc > 0.22:
						var u := (cyc - 0.22) / 0.78
						off = Vector2(150.0 * sin(u * PI) * 1.0, -80.0 * sin(u * PI))
						pose["expr"] = "susto" if u < 0.7 else "normal"
						pose["hb_off"] = Vector2(-6, -22) * sin(u * PI)
						pose["hf_off"] = Vector2(4, -20) * sin(u * PI)
						pose["lean"] = -0.35 * sin(u * PI)
				2:   # armadura fornalha: quica blindado
					look["fx"] = {"spell": "T01", "armor": true, "assemble": 1.0}
					var b := absf(sin(now * 3.2))
					off.y = -110.0 * b
					pose["spring_k"] = 0.7 + 0.8 * b
					pose["expr"] = "vitoria" if b > 0.5 else "normal"
				3:   # TNT aceso na mão: corre no lugar, desesperado
					look["fx"] = {"spell": "A03"}
					var ph := now * 18.0
					pose["feet"] = [Vector2(cos(ph) * 8.0, -maxf(sin(ph), 0.0) * 9.0), Vector2(cos(ph + PI) * 8.0, -maxf(sin(ph + PI), 0.0) * 9.0)]
					pose["expr"] = "susto"
					pose["hf_off"] = Vector2(sin(now * 20.0) * 4.0, -24.0)
					off.y = -absf(sin(ph)) * 4.0
		# sombra no chão
		var hgt := clampf(-off.y / 120.0, 0.0, 1.0)
		ci.draw_set_transform(Vector2(base.x + off.x, SCENE_GROUND + 4), 0.0, Vector2(1.0 - 0.4 * hgt, 0.35))
		ci.draw_circle(Vector2.ZERO, 46.0, Color(0.1, 0.2, 0.22, 0.25 * (1.0 - 0.5 * hgt)))
		ci.draw_set_transform(Vector2.ZERO)
		RobotVis.draw_robot(ci, look, pose, Transform2D(0.0, Vector2(SCENE_SCALE * face, SCENE_SCALE), 0.0, base + off))
		ci.draw_set_transform(Vector2.ZERO)
	# impacto da marretada no verde: estrela "POW!" e estrelinhas girando
	if enter[0] >= 1.0 and enter[1] >= 1.0:
		if cyc > 0.2 and cyc < 0.42:
			var u := (cyc - 0.2) / 0.22
			var c := Vector2(SCENE_X[1] - 20.0, SCENE_GROUND - 150.0)
			var burst := PackedVector2Array()
			for k in 16:
				burst.append(c + Vector2.from_angle(k * TAU / 16.0) * (70.0 if k % 2 == 0 else 34.0) * (0.6 + 0.6 * u))
			ci.draw_colored_polygon(burst, Color(1.0, 0.94, 0.55, 1.0 - u * 0.6))
			Kit.sticker(ci, c + Vector2(-120, 18), "POW!", 52, Color("#d42035"), HORIZONTAL_ALIGNMENT_CENTER, 240)
		if cyc > 0.3 and cyc < 0.95:
			var u := (cyc - 0.22) / 0.78
			var head := Vector2(SCENE_X[1] + 150.0 * sin(u * PI), SCENE_GROUND - 80.0 * sin(u * PI) - 200.0)
			for k in 3:
				Kit.star(ci, head + Vector2.from_angle(now * 8.0 + k * TAU / 3.0) * Vector2(40, 14), 22.0, true)
