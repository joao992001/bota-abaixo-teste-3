extends Node
## Telas fora da partida: MENU principal, seleção de MODOS, COMO JOGAR, OPÇÕES e a PAUSA.
## Qualquer teclado ou controle navega (bots não). Desenho em draw(ci), chamado pelo HUD.

const Kit := preload("res://ui/kit.gd")
const Obra := preload("res://ui/obra.gd")
const RobotVis := preload("res://player/robot_visual.gd")

const MENU_ITEMS := ["JOGAR", "LABORATÓRIO", "COMO JOGAR", "OPÇÕES", "SAIR"]
const PAUSE_ITEMS := ["CONTINUAR", "REINICIAR PARTIDA", "CONFIGURAR MAPA", "SELECIONAR MAPA", "MENU PRINCIPAL"]   # A23
var pause_conf := -1   # opção da pausa esperando "tem certeza?" (A26); -1 = nenhuma
var pause_sim := false
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
const INTRO_END := 5.4
var shake_card := 0.0
var pag_x := 0.0          # página mostrada na grade de mapas (desliza até a da seleção)
var paginas_min := 1      # só testes/capturas: força páginas para ver o deslize
const POR_PAG := 9        # mapas em grade 3 × 3 (prancha m1, 2026-11-27)
const GRADE_COLS := 3
var arena_sel := 0
var adj_sel := 0
const EVENT_LEVELS := ["DESLIGADOS", "BAIXA", "NORMAL", "ALTA"]

func setup(m: Node) -> void:
	main = m

## O CONTROLE PRINCIPAL (ou o teclado) apertou a ação? Os outros controles não mexem nos menus (PlayerInput.principal).
## dono: aparelho que assumiu agora (MAPEAR/TESTAR um controle: só ele, até voltar) · pausa: quem pausou também manda.
var dono := ""
var dono_pausa := ""

func _manda(dev: String) -> bool:
	if dono == "" and dono_pausa != "" and main.paused and dev == dono_pausa:
		return true
	return PlayerInput.manda_no_menu(dev, dono)

func pressed(a: String) -> bool:
	for dev in PlayerInput.all_devices():
		if _manda(dev) and PlayerInput.dev_pressed(dev, a):
			return true
	return false

func confirm() -> bool:
	return pressed("jump") or pressed("start")

## Menus andam por nav_* (a direção mapeada OU o analógico/direcional/teclas de fábrica: ninguém fica preso).
## SEGURAR repete (2026-11-28: grades grandes como a das engenhocas ficavam lentas de um em um): espera REP_ATRASO e
## depois anda a cada REP_PASSO, acelerando até REP_RAPIDO.
const REP_ATRASO := 0.3
const REP_PASSO := 0.11
const REP_RAPIDO := 0.06
var _rep_t := {"nav_left": 0.0, "nav_right": 0.0, "nav_up": 0.0, "nav_down": 0.0}
var _rep_fire := {}

func _held_any(a: String) -> bool:
	for dev in PlayerInput.all_devices():
		if _manda(dev) and PlayerInput.dev_held(dev, a):
			return true
	return false

## Chamado 1× por quadro de física (main._physics_process, antes de qualquer menu/pausa/laboratório): marca quais direções "repetiram" neste quadro.
func _repeat_tick(dt: float) -> void:
	_rep_fire.clear()
	for a in _rep_t:
		if not _held_any(a):
			_rep_t[a] = 0.0
			continue
		var t0: float = _rep_t[a]
		var t1 := t0 + dt
		_rep_t[a] = t1
		if t1 >= REP_ATRASO:
			var passo := REP_RAPIDO if t1 > REP_ATRASO + 1.0 else REP_PASSO
			if t0 < REP_ATRASO or floori((t1 - REP_ATRASO) / passo) != floori((t0 - REP_ATRASO) / passo):
				_rep_fire[a] = true

func _nav(a: String) -> bool:
	return pressed(a) or _rep_fire.has(a)

func move_v() -> int:
	return int(_nav("nav_down")) - int(_nav("nav_up"))

func move_h() -> int:
	return int(_nav("nav_right")) - int(_nav("nav_left"))

func update(dt: float) -> void:
	t += dt
	# MAPEAR/TESTAR um aparelho: ele assume os menus até voltar/salvar; depois o principal volta (pedido 2026-11-28)
	dono = map_dev if main.state == main.S.CONFIGPAD else (test_dev if main.state == main.S.TESTPAD else "")
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
					0: abrir_mapas()   # A22: só existe o Derruba → JOGAR vai direto aos mapas
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
					pag_x = 0.0
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
		S.AJUSTES when main.selecao.ativo_para(main.arena_choice):
			main.selecao.update_vidas(self)   # Derruba com mapa: etapa 3 (VIDAS), A21
		S.DETONAR:
			main.selecao.update_detonar(self)
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
			_update_hub()
		S.CONFIGPAD:
			_update_mapear(dt)
		S.TESTPAD:
			_update_teste()
		S.ARENAS:
			_mover_grade(move_h(), move_v())
			pag_x = lerpf(pag_x, float(arena_sel / POR_PAG), minf(1.0, dt * 10.0))   # a página desliza
			if confirm() and arena_sel >= arena_list().size():
				shake_card = 0.35   # cartaz bloqueado (lona e cadeado)
				Audio.play("menu_negado")
			elif confirm():
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
				main.state = S.MENU
		S.OPTIONS:
			opt_sel = posmod(opt_sel + move_v(), 8)
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
				abrir_controles()
			elif opt_sel == 7 and c:
				main.state = S.MENU
			if h != 0 or c:
				main.save_options()
			if pressed("back"):
				main.state = S.MENU

## JOGAR (A22, 2026-11-26): a tela de MODOS é pulada enquanto só o Derruba existir; volta quando houver outro modo.
func abrir_mapas() -> void:
	var m: Dictionary = main.demo.find_mode("derruba")
	main.game_mode = "derruba"
	main.demo.items_on = bool(m.get("itens", true))
	arena_sel = 0
	pag_x = 0.0
	adj_sel = 0
	main.state = main.S.ARENAS

## Pausa (dentro da partida): Start/Enter abre; navega com ▲▼. Sair da luta (reiniciar, configurar, selecionar, menu)
## pede confirmação (A26) e não conta para gangorra nem Projetos.
func update_pause() -> void:
	if pause_conf >= 0:
		if move_h() != 0 or move_v() != 0:
			pause_sim = not pause_sim
			Audio.play("menu_mover")
		if pressed("back") or (confirm() and not pause_sim):
			pause_conf = -1
			Audio.play("menu_voltar")
		elif confirm():
			var k := pause_conf
			pause_conf = -1
			_pausa_executa(k)
		return
	var v := move_v()
	if v != 0:
		Audio.play("menu_mover")
	pause_sel = posmod(pause_sel + v, PAUSE_ITEMS.size())
	if pressed("back"):
		main.paused = false
	elif confirm():
		Audio.play("menu_ok")
		if pause_sel == 0:
			main.paused = false
		else:
			pause_conf = pause_sel
			pause_sim = false

func _pausa_executa(k: int) -> void:
	main.paused = false
	Audio.play("menu_ok")
	match k:
		1: main.start_match()
		2: main.resultado_escolhe(1)   # configurar mapa
		3: main.resultado_escolhe(2)   # selecionar mapa
		4: main.go_menu()

# ---------------------------------------------------------------- desenho
func draw(ci: CanvasItem) -> void:
	var S = main.S
	if main.state != S.INTRO and main.state != S.ARENAS and main.state in main.MENU_STATES:
		_draw_scene(ci, [1.0, 1.0, 1.0, 1.0])
	match main.state:
		S.MENU: _draw_menu(ci)
		S.MODES: _draw_modes(ci)
		S.HOWTO: _draw_howto(ci)
		S.OPTIONS: _draw_options(ci)
		S.ARENAS: _draw_arenas(ci)
		S.AJUSTES:
			if main.selecao.ativo_para(main.arena_choice):
				main.selecao.draw_vidas(ci)
			else:
				_draw_adjust(ci)
		S.DETONAR: main.selecao.draw_detonar(ci)
		S.EVENTOS: main.events.menu_draw(ci, self)
		S.SELSPELLS: main.selecao.draw_spells(ci)
		S.SELEVENTOS: main.selecao.draw_eventos(ci)
		S.CONTROLES: _draw_hub(ci)
		S.INTRO: _draw_intro(ci)
		S.CONFIGPAD: _draw_mapear(ci)
		S.TESTPAD: _draw_teste(ci)
	if main.paused:
		if main.sandbox and main.tester().open:
			main.tester().draw(ci)
		else:
			_draw_pause(ci)

## Qual dispositivo confirmou agora (vira o P1 do Laboratório).
func _who_confirmed() -> String:
	for dev in PlayerInput.all_devices():
		if _manda(dev) and (PlayerInput.dev_pressed(dev, "jump") or PlayerInput.dev_pressed(dev, "start")):
			return dev
	return "kb_a"

func _logo(ci: CanvasItem, y: float, w: float, cx := 960.0) -> void:
	var h := w * 340.0 / 1700.0
	var bob := sin(t * 1.6) * 6.0 * menu_in
	ci.draw_texture_rect(Data.tex("ui/logo"), Rect2(cx - w / 2, y + bob, w, h), false)

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

## Menu "Canteiro vivo" (A21), igual à prancha aprovada `art/out/menus_v2/v2_1_menu.png`: logo no alto à esquerda,
## LIVRE (nenhum cabo passa por ele); placas de obra EM COLUNA penduradas por correntes numa viga da grua no centro-direita;
## a escolhida é amarela e balança. O elenco brinca na laje dos dois lados da coluna (_draw_scene).
const MENU_VX := 1180.0
func _draw_menu(ci: CanvasItem) -> void:
	_logo(ci, 56, 720, 440)
	menu_in = minf(menu_in + get_process_delta_time() / 0.45, 1.0)
	var vx := MENU_VX
	ci.draw_line(Vector2(vx, -10), Vector2(vx, 150), Color("#4a4f5c"), 5.0)   # cabo da grua
	var vg := Rect2(vx - 280, 150, 560, 50)   # viga
	ci.draw_rect(vg, Color("#3a3f4a"))
	ci.draw_rect(Rect2(vg.position + Vector2(0, 14), Vector2(vg.size.x, 20)), Color("#4a5060"))
	for k in 8:
		ci.draw_circle(vg.position + Vector2(30 + k * 71, 25), 5.0, Color("#6b7380"))
	var y := vg.end.y + 34.0   # topo da placa (Obra.placa desenha a partir do topo)
	var prev_fundo := vg.end.y - 6.0
	for i in MENU_ITEMS.size():
		var u := _ease_out_back(clampf(menu_in * 1.6 - i * 0.12, 0.0, 1.0))
		var on := sel == i
		var w := 520.0 if on else 440.0
		var h := 122.0 if on else 90.0
		var cx := vx + 1100.0 * (1.0 - u)
		Obra.corrente(ci, cx - w / 2.0 + 40, prev_fundo, y + 8)
		Obra.corrente(ci, cx + w / 2.0 - 40, prev_fundo, y + 8)
		var rot := (sin(t * 3.0) * 0.035) if on else (0.012 if i % 2 else -0.01)
		Obra.placa(ci, Vector2(cx, y), w, h, MENU_ITEMS[i], on, rot, 46 if on else 38)
		prev_fundo = y + h - 10.0
		y += h + 28.0
	Obra.dica(ci, "▲▼ escolher  ·  PULAR confirmar  ·  ESC voltar")

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
	Obra.titulo(ci, "ESCOLHA O MODO")
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
	Obra.dica(ci, "◄► modo  ·  PULAR confirmar  ·  ESC voltar")

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
	var out: Array = [{"id": "sorteio", "nome": "SORTEIO", "dica": "a grua escolhe por você" if main.game_mode == "derruba" else "Cada rodada numa arena do modo"}]
	out.append_array(main.demo.mode_arenas(main.game_mode))
	return out

## Cartazes "EM BREVE" (lona + cadeado) completam a última página da grade 3 × 3 (prancha m1).
func mapas_bloqueados() -> int:
	var n := arena_list().size()
	return maxi(int(ceil(n / float(POR_PAG))), paginas_min) * POR_PAG - n

func n_paginas() -> int:
	return maxi(1, (arena_list().size() + mapas_bloqueados()) / POR_PAG)

## ◄► anda na linha; na borda da grade desliza para a página ao lado (mesma linha). ▲▼ troca de linha.
func _mover_grade(h: int, v: int) -> void:
	var pg := arena_sel / POR_PAG
	var k := arena_sel % POR_PAG
	var col := k % GRADE_COLS
	var row := k / GRADE_COLS
	var np := n_paginas()
	if h != 0:
		col += h
		if col < 0 or col >= GRADE_COLS:
			if np > 1:
				pg = posmod(pg + h, np)
			col = posmod(col, GRADE_COLS)
	if v != 0:
		row = clampi(row + v, 0, POR_PAG / GRADE_COLS - 1)
	arena_sel = pg * POR_PAG + row * GRADE_COLS + col

## Retângulo do cartaz i dentro da página (grade 3 × 3).
func _cartaz_rect(k: int) -> Rect2:
	var cw := 470.0
	var ch := 218.0
	var x0 := (1920.0 - (GRADE_COLS * cw + (GRADE_COLS - 1) * 30.0)) / 2.0
	return Rect2(x0 + (k % GRADE_COLS) * (cw + 30.0), 200.0 + (k / GRADE_COLS) * (ch + 20.0), cw, ch)

## Mapas (A21/A23 → grade m1, 2026-11-27): tapume de obra com cartazes presos por fita crepe, título pendurado no cabo
## da grua, 9 cartazes por página (Sorteio "?", o mapa com foto + capacetes das cenas, EM BREVE com lona e cadeado),
## setas grandes e bolinhas de página, régua dos Projetos de Demolição.
func _draw_arenas(ci: CanvasItem) -> void:
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, 990, 1920, 90), Color("#b9ab8f"))   # laje
	ci.draw_rect(Rect2(0, 990, 1920, 40), Color("#d8ccb6"))
	ci.draw_rect(Rect2(0, 990, 1920, 8), Color("#eee5d2"))
	for k in 9:   # tapume: painéis de compensado pintados
		var x := -40.0 + k * 230.0
		ci.draw_rect(Rect2(x, 150, 236, 840), Color("#7fae86") if k % 2 == 0 else Color("#86b48c"))
		ci.draw_rect(Rect2(x, 150, 236, 840), Color("#4d7a56"), false, 3.0)
	Obra.zebra(ci, Rect2(0, 132, 1920, 26))
	ci.draw_line(Vector2(960, -4), Vector2(960, 40), Color("#4a4f5c"), 5.0)   # título no cabo da grua
	Obra.corrente(ci, 820, 30, 60)
	Obra.corrente(ci, 1100, 30, 60)
	Obra.placa(ci, Vector2(960, 54), 560, 92, "ESCOLHA O MAPA" if main.game_mode == "derruba" else "ESCOLHA A ARENA", true, 0.0, 50)
	var list := arena_list()
	var total := list.size() + mapas_bloqueados()
	var np := n_paginas()
	for pg in np:
		var dx := (pg - pag_x) * 1920.0
		if absf(dx) >= 1900.0:
			continue
		for k in POR_PAG:
			var i := pg * POR_PAG + k
			if i >= total:
				break
			var r := _cartaz_rect(k)
			r.position.x += dx
			var on := i == arena_sel
			var rot := 0.0
			if on and shake_card > 0.0:
				rot = sin(shake_card * 60.0) * 0.03
			var xf := Transform2D(rot, Vector2.ONE * (1.03 if on else 1.0), 0.0, r.get_center())
			ci.draw_set_transform_matrix(xf)
			var rr := Rect2(-r.size / 2.0, r.size)
			if on:
				ci.draw_style_box(Obra._sb(Obra.YEL, 14, 6), rr.grow(12))
			if i < list.size():
				_cartaz_mapa(ci, rr, list[i], xf)
			else:
				_cartaz_bloqueado(ci, rr, xf)
			if on:   # moldura por cima (a lona do EM BREVE cobriria a de baixo)
				var sb := Obra._sb(Color(0, 0, 0, 0), 16, 0)
				sb.border_color = Obra.YEL
				sb.set_border_width_all(10)
				ci.draw_style_box(sb, rr.grow(12))
				Obra.chip(ci, rr.position + Vector2(rr.size.x - 84, -30), 1)
			ci.draw_set_transform(Vector2.ZERO)
	var pg_at := arena_sel / POR_PAG
	for sx in [-1.0, 1.0]:   # setas grandes: há página para lá?
		var tem: bool = np > 1
		var c := Vector2(960 + sx * 890.0, 548)
		ci.draw_circle(c + Vector2(0, 5), 50.0, Color(Kit.INK, 0.3))
		ci.draw_circle(c, 50.0, Kit.INK)
		ci.draw_circle(c, 43.0, Obra.YEL if tem else Color("#c9c2b2"))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * 20, 0), c + Vector2(-sx * 14, -20), c + Vector2(-sx * 14, 20)]), Kit.INK)
	var y_pe := 200.0 + 3 * 218.0 + 2 * 20.0 + 40.0
	var x_pe := _cartaz_rect(0).position.x
	for pg in np:   # bolinhas de página
		ci.draw_circle(Vector2(x_pe + 20 + pg * 40, y_pe), 13.0, Kit.INK)
		ci.draw_circle(Vector2(x_pe + 20 + pg * 40, y_pe), 9.0, Kit.INK if pg == pg_at else Color.WHITE)
	Kit.text(ci, Vector2(x_pe + 20 + np * 40 + 10, y_pe + 9), "página %d/%d" % [pg_at + 1, np], 22, Color("#2a4a58"))
	if main.game_mode == "derruba":
		var xr := _cartaz_rect(GRADE_COLS - 1).end.x
		_draw_projetos(ci, Rect2(xr - 620, y_pe - 34, 620, 74))
	Obra.dica(ci, "◄►▲▼ escolher  ·  na borda: desliza a página  ·  PULAR confirmar  ·  ESC voltar")

## Cartaz de papel com fita crepe nos cantos (comum a todos os cartazes do tapume).
func _papel_cartaz(ci: CanvasItem, rr: Rect2, xf: Transform2D) -> void:
	ci.draw_style_box(Obra._sb(Color(Kit.INK, 0.3), 6), Rect2(rr.position + Vector2(6, 10), rr.size))
	ci.draw_style_box(Obra._sb(Color("#f6eedb"), 6, 5), rr)
	ci.draw_set_transform_matrix(xf * Transform2D(-0.52, Vector2(rr.position.x + 25.0, rr.position.y + 5.0)))   # fita crepe no canto
	ci.draw_rect(Rect2(-45, -15, 90, 30), Color(0.91, 0.85, 0.66, 0.9))
	ci.draw_set_transform_matrix(xf)

func _cartaz_mapa(ci: CanvasItem, rr: Rect2, a: Dictionary, xf: Transform2D) -> void:
	_papel_cartaz(ci, rr, xf)
	var tr := Rect2(rr.position + Vector2(16, 16), Vector2(236, rr.size.y - 32))   # foto à esquerda
	var tx0 := tr.end.x + 10.0
	var tw := rr.end.x - tx0 - 10.0
	if a["id"] == "sorteio":
		ci.draw_style_box(Obra._sb(Color("#9fe3ee"), 6, 4), tr)
		Kit.sticker(ci, Vector2(tr.position.x, tr.get_center().y + 60), "?", 160, Obra.YEL, HORIZONTAL_ALIGNMENT_CENTER, tr.size.x)
		Kit.text(ci, Vector2(tx0, rr.position.y + 100), "SORTEIO", 32, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, tw)
		Kit.text_box(ci, Vector2(tx0, rr.position.y + 140), tw, String(a.get("dica", "")), 19, Kit.SOFT, 2)
		return
	var thumb := Data.tex("ui/arena_" + String(a["id"]))
	if thumb != null:   # foto cortada no meio (slice), sem esticar
		var ts := thumb.get_size()
		var esc := maxf(tr.size.x / ts.x, tr.size.y / ts.y)
		var src := Rect2((ts - tr.size / esc) / 2.0, tr.size / esc)
		ci.draw_texture_rect_region(thumb, tr, src)
	else:
		ci.draw_rect(tr, Color("#9fe3ee"))
	ci.draw_rect(tr, Kit.INK, false, 4.0)
	var nome := String(a["nome"]).to_upper()
	var mf: Dictionary = MapaReg.manifesto(main.game_mode, String(a["id"])) if main.game_mode == "derruba" else {}
	Kit.text_box(ci, Vector2(tx0, rr.position.y + 66), tw, nome, 28 if nome.length() < 16 else 24, Kit.INK, 2)
	if mf.is_empty():
		Kit.text_box(ci, Vector2(tx0, rr.position.y + 150), tw, String(a.get("dica", "")), 17, Kit.SOFT, 2)
		return
	# capacetes = cenas descobertas (amarelo) / não descobertas (cinza)
	var vis: Array = main.perfil.dados.get("cenas_visitadas", {}).get(a["id"], [])
	var cenas: Array = MapaReg.cenas(main.game_mode, String(a["id"]))
	var passo := minf(64.0, (tw - 10.0) / maxf(cenas.size(), 1))
	for k in cenas.size():
		var ok: bool = String(cenas[k].get("id", "")) in vis
		var cx := tx0 + tw / 2.0 - passo * (cenas.size() - 1) / 2.0 + k * passo
		ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(0.72, 0.72), 0.0, Vector2(cx, rr.end.y - 44)))
		_capacete(ci, Vector2.ZERO, ok)
		ci.draw_set_transform_matrix(xf)

func _capacete(ci: CanvasItem, c: Vector2, aceso: bool) -> void:
	var col := Obra.YEL if aceso else Color("#c9c2b2")
	var pts := PackedVector2Array()
	for k in 17:
		var a := PI + k * PI / 16.0
		pts.append(c + Vector2(cos(a) * 32.0, sin(a) * 30.0))
	ci.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	ci.draw_polyline(pts, Kit.INK, 4.0, true)
	ci.draw_style_box(Obra._sb(col, 4, 4), Rect2(c + Vector2(-40, -4), Vector2(80, 12)))

## Mapa que ainda vem: lona azul presa por fita, corrente tracejada atravessada, cadeado e EM BREVE.
func _cartaz_bloqueado(ci: CanvasItem, rr: Rect2, xf := Transform2D.IDENTITY) -> void:
	var x := rr.position.x
	var y := rr.position.y
	var w := rr.size.x
	var h := rr.size.y
	ci.draw_style_box(Obra._sb(Color(Kit.INK, 0.3), 6), Rect2(rr.position + Vector2(6, 10), rr.size))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 4), Vector2(x + w, y - 4), Vector2(x + w + 2, y + h + 4), Vector2(x - 2, y + h - 2)]), Color("#3f7fb5"))
	ci.draw_polyline(PackedVector2Array([Vector2(x, y + 4), Vector2(x + w, y - 4), Vector2(x + w + 2, y + h + 4), Vector2(x - 2, y + h - 2), Vector2(x, y + 4)]), Color("#2f6595"), 4.0, true)
	for k in 4:   # dobras da lona
		var x0 := x + 40 + k * w / 4.0
		ci.draw_polyline(PackedVector2Array([Vector2(x0, y + 6), Vector2(x0 + 10, y + h * 0.5), Vector2(x0 - 6, y + h - 4)]), Color("#3873a6"), 4.0, true)
	var c0 := Vector2(x, y + h * 0.46)
	var c1 := Vector2(x + w, y + h * 0.52)
	for k in 22:   # corrente tracejada
		var u0 := k / 22.0
		ci.draw_line(c0.lerp(c1, u0), c0.lerp(c1, u0 + 0.6 / 22.0), Color("#8d98a4"), 7.0)
	var lc := Vector2(x + w / 2.0, y + h * 0.5)
	ci.draw_arc(lc + Vector2(0, -22), 19.0, PI, TAU, 16, Kit.INK, 8.0, true)
	ci.draw_line(lc + Vector2(-19, -22), lc + Vector2(-19, -6), Kit.INK, 8.0)
	ci.draw_line(lc + Vector2(19, -22), lc + Vector2(19, -6), Kit.INK, 8.0)
	ci.draw_style_box(Obra._sb(Obra.YEL, 8, 4), Rect2(lc + Vector2(-30, -22), Vector2(60, 50)))
	Kit.text(ci, Vector2(x, y + h - 26), "EM BREVE", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w, 6)
	ci.draw_set_transform_matrix(xf * Transform2D(-0.52, Vector2(x + 25.0, y + 5.0)))   # fita crepe no canto
	ci.draw_rect(Rect2(-45, -15, 90, 30), Color(0.91, 0.85, 0.66, 0.9))
	ci.draw_set_transform_matrix(xf)

## Projetos de Demolição (perfil, D4): pontos para liberar o próximo mapa. Só na seleção de mapas e nos resultados.
func _draw_projetos(ci: CanvasItem, rr: Rect2) -> void:
	var pm := int(MapaReg.modo_cfg("derruba").get("progressao", {}).get("pontos_por_mapa", 6))
	var tot := int(main.perfil.dados.get("pontos_exploracao", 0))
	ci.draw_style_box(Obra._sb(Color("#f6eedb"), 6, 4), rr)   # régua de obra pintada no tapume (prancha)
	Kit.text(ci, Vector2(rr.position.x + 20, rr.position.y + 32), "PROJETOS DE", 20, Kit.INK)
	Kit.text(ci, Vector2(rr.position.x + 20, rr.position.y + 58), "DEMOLIÇÃO", 20, Kit.INK)
	var cw := minf(62.0, (rr.size.x - 260.0) / pm)
	for k in pm:
		var cel := Rect2(rr.position.x + 180 + k * cw, rr.position.y + 16, cw, rr.size.y - 32)
		ci.draw_rect(cel, (Color("#d42035") if k % 2 == 0 else Color.WHITE) if k < mini(tot, pm) else Color("#e2d9c6"))
		ci.draw_rect(cel, Kit.INK, false, 3.0)
	Kit.text(ci, Vector2(rr.position.x + 180 + pm * cw, rr.position.y + 48), "%d/%d" % [mini(tot, pm), pm], 24, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, rr.end.x - (rr.position.x + 180 + pm * cw))

func _draw_howto(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 30, 800, 128), "COMO JOGAR", 60)
	var r := Rect2(160, 180, 1600, 780)
	Kit.paper(ci, r)
	var tips := [
		["robo", "Derrube os outros no poço de espinhos. O último em pé ganha uma ★."],
		["marreta", "GOLPE RÁPIDO (X/□): empurra e interrompe. MARRETADA PESADA (Y/△): demora,\nmas arremessa longe e quebra caixotes (▼ + pesada quebra o chão). Errou? Fica exposto."],
		["pisao", "ESQUIVA (RB/R1): escapa de golpes por um instante, no chão ou 1 vez no ar.\nArremessado? Segure a direção para corrigir e use a esquiva para se salvar."],
		["itens", "Caixas de ENGENHOCA: a cor mostra a família (ataque, controle, mecha).\nEncoste para pegar · ESPECIAL usa · segure ESPECIAL em cima de outra caixa para trocar."],
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
				var names := ["ataque", "controle", "transformacao", "defesa"]
				for k in 4:
					ci.draw_texture_rect(Data.tex("spells/caixa_" + names[k]), Rect2(c + Vector2(-70 + (k % 2) * 60, -40 + (k / 2) * 52), Vector2(54, 54)), false)
			"parado":
				ci.draw_texture_rect(Data.tex("cenario/caixote_0"), Rect2(c - Vector2(40, 30), Vector2(80, 80)), false)
		ci.draw_set_transform(Vector2.ZERO)
		var lines: PackedStringArray = String(tips[i][1]).split("\n")
		for k in lines.size():
			Kit.text(ci, Vector2(r.position.x + 260, y + 44 - (lines.size() - 1) * 18 + k * 40), lines[k], 32, Color("#2a1a2e"))
	Kit.text(ci, Vector2(0, 1050), "Teclado A: WASD · G pula · H golpe · J pesada · Y esquiva · U especial     Teclado B: setas · numérico 1 pula · 2 golpe · 3 pesada · 4 esquiva · 5 especial (notebook: K L Ç O P)", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)

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
		"CONTROLES  ▸",
		"VOLTAR",
	]
	for i in items.size():
		_button(ci, Rect2(560, 190 + i * 92, 800, 76), items[i], opt_sel == i)
	Kit.text(ci, Vector2(0, 1056), "▲▼ escolher  ·  ◄► ou PULAR muda", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

func _bar(v: int) -> String:
	return "■".repeat(v) + "□".repeat(10 - v)

## Pausa nova (prancha art/out/recompensas/r4_pausa.png): placas na viga da grua + prancheta com a partida em andamento.
func _draw_pause(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.1, 0.22, 0.27, 0.62))
	ci.draw_line(Vector2(700, -4), Vector2(700, 120), Color("#4a4f5c"), 5.0)
	var vg := Rect2(420, 120, 560, 50)
	ci.draw_rect(vg, Color("#3a3f4a"))
	ci.draw_rect(Rect2(vg.position + Vector2(0, 14), Vector2(vg.size.x, 20)), Color("#4a5060"))
	for k in 8:
		ci.draw_circle(vg.position + Vector2(30 + k * 71, 25), 5.0, Color("#6b7380"))
	Obra.corrente(ci, 520, vg.end.y - 4, 196)
	Obra.corrente(ci, 880, vg.end.y - 4, 196)
	Obra.placa(ci, Vector2(700, 190), 520, 110, "PAUSA", true, 0.0, 54)
	var y := 340.0
	var prev := 290.0
	for i in PAUSE_ITEMS.size():
		var on := pause_sel == i
		var w := 500.0 if on else 440.0
		var h := 96.0 if on else 80.0
		Obra.corrente(ci, 700 - w / 2.0 + 40, prev, y + 8)
		Obra.corrente(ci, 700 + w / 2.0 - 40, prev, y + 8)
		Obra.placa(ci, Vector2(700, y), w, h, PAUSE_ITEMS[i], on, (sin(t * 3.0) * 0.03) if on else 0.0, 40 if on else 34)
		prev = y + h - 10.0
		y += h + 30.0
	# prancheta: a partida em andamento
	var folha := Obra.prancheta(ci, Rect2(1120, 220, 640, 620), "PARTIDA", Color("#e0841e"))
	var et = main.demo.etapas if main.demo != null else null
	var lid := String(main.level.id)
	var mf: Dictionary = MapaReg.manifesto(main.game_mode, lid)
	var cena := "—"
	if et != null and is_instance_valid(et):
		cena = String(MapaReg.cena(main.game_mode, lid, et.etapa).get("nome", "—"))
	var lt := int(main.demo.luta_t) if main.demo != null else 0
	var n_eng: int = main.spells_on.values().filter(func(x): return x).size() if main.spells_mapa == main.arena_choice else 0
	var evs: Array = main.selecao.eventos_do_mapa() if not mf.is_empty() else []
	var n_ev: int = evs.filter(func(id): return main.events.enabled.get(id, true)).size()
	var rows := [["Mapa", String(mf.get("nome", lid))], ["Cena", cena], ["Tempo de luta", "%d:%02d" % [lt / 60, lt % 60]],
		["Engenhocas", ("%d ligadas" % n_eng) if n_eng > 0 else "todas"], ["Eventos", "%d · %s" % [n_ev, EVENT_LEVELS[main.event_level].to_lower()]]]
	for i in rows.size():
		var yy := folha.position.y + 52 + i * 62
		Kit.text(ci, Vector2(folha.position.x + 22, yy), rows[i][0], 26, Kit.SOFT)
		Kit.text(ci, Vector2(folha.position.x, yy), rows[i][1], 28, Kit.INK, HORIZONTAL_ALIGNMENT_RIGHT, folha.size.x - 22)
	var vmax: int = maxi(main.demo.lives_setting, 1) if main.demo != null else 4
	for i in main.players.size():
		var x: float = folha.position.x + 30 + i * 145
		Obra.chip(ci, Vector2(x, folha.position.y + 380), i + 1)
		var vivas := int(main.demo.lives.get(i, 0)) if main.demo != null else 0
		for k in mini(vmax, 6):
			var c := Vector2(x + 10 + k * 22, folha.position.y + 450)
			ci.draw_circle(c, 9.0, Color("#e5484d") if k < vivas else Color("#d9d2c4"))
			ci.draw_arc(c, 9.0, 0.0, TAU, 16, Kit.INK, 3.0)
	ci.draw_style_box(Obra._sb(Color("#fbe3dc"), 12, 4), Rect2(1140, 870, 600, 70))
	Kit.text(ci, Vector2(1140, 898), "Reiniciar / Configurar / Selecionar / Menu: abandona a luta", 19, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, 600)
	Kit.text(ci, Vector2(1140, 924), "(sem gangorra e sem Projetos) — pede confirmação", 19, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, 600)
	if not main.lost_pads.is_empty():
		var r := Rect2(460, 10, 1000, 100)
		ci.draw_style_box(Obra._sb(Color(1, 0.86, 0.82), 12, 5), r)
		var who := ", ".join(main.lost_pads.map(func(i): return "P%d" % (i + 1)))
		Kit.text(ci, Vector2(r.position.x, r.position.y + 46), "CONTROLE DESCONECTADO: %s" % who, 34, Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 82), "Reconecte (USB ou Bluetooth) ou aperte START em outro controle", 22, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Obra.dica(ci, "▲▼ escolher  ·  PULAR confirmar  ·  START volta à luta")
	if pause_conf >= 0:   # "tem certeza?" (A26)
		ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(Kit.INK, 0.45))
		var r2 := Rect2(560, 360, 800, 330)
		Obra.quadro(ci, r2)
		ci.draw_style_box(Obra._sb(Obra.CREAM, 8, 4), r2.grow(-22))
		Kit.text(ci, Vector2(r2.position.x, r2.position.y + 92), PAUSE_ITEMS[pause_conf] + "?", 44, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		Kit.text(ci, Vector2(r2.position.x, r2.position.y + 140), "A luta atual é abandonada (não conta para", 24, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		Kit.text(ci, Vector2(r2.position.x, r2.position.y + 172), "a gangorra nem para os Projetos).", 24, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)
		Obra.placa(ci, Vector2(r2.position.x + 230, r2.position.y + 210), 260.0 if not pause_sim else 220.0, 80, "NÃO", not pause_sim, 0.0, 38)
		Obra.placa(ci, Vector2(r2.position.x + 570, r2.position.y + 210), 260.0 if pause_sim else 220.0, 80, "SIM, SAIR", pause_sim, 0.0, 34)

# ---------------------------------------------------------------- testar controles
var pad_prev := {}   # joy -> {botão: bool} (bordas para vibrar e sair)

func _pad_edge(j: int, b: int) -> bool:
	var now := Input.is_joy_button_pressed(j, b)
	var key := "%d:%d" % [j, b]
	var was: bool = pad_prev.get(key, false)
	pad_prev[key] = now
	return now and not was

# ---------------------------------------------------------------- intro animada (abre o jogo)
## O logo cai e quica, bate levantando poeira, os robôs entram correndo e acenam, e o logo desliza até o menu.
## ABERTURA "Canteiro vivo" (A21, storyboard art/out/menus_v2/v2_4_abertura.png): a grua desce o letreiro coberto
## por lona → a lona cai → um robô SORTEADO entra e marreta o pilar → as letras caem e quicam no lugar → o elenco entra.
## ~5,5 s; qualquer botão pula para o fim (o menu, no mesmo cenário).
const IN_DESCE := 1.1      # grua descendo o letreiro tapado
const IN_LONA := 1.5       # lona cai
const IN_CORRE := 2.5      # robô sorteado chega e marreta
const IN_BATE := 2.75      # impacto: letras se soltam
const IN_ASSENTA := 3.6    # letras assentadas
var intro_robo := 0

func _update_intro(dt: float) -> void:
	intro_frames += 1
	if intro_frames < 4:
		return   # primeiros quadros (carregando a tela): o relógio da animação só anda depois
	if intro_frames == 4:
		intro_robo = main.rng.randi_range(0, 4)   # quem marreta muda a cada abertura (A21)
	intro_t += minf(dt, 1.0 / 30.0)   # sem pulos se um quadro demorar
	if not intro_hit and intro_t >= IN_BATE:
		intro_hit = true
		Audio.play("marreta_pesada_metal", 0.8)
		Audio.play("caixote_pancada", 0.8)
		main.shake(12.0)
	if not intro_hi and intro_t >= IN_ASSENTA:
		intro_hi = true
		Audio.play("pisao", 0.7)
		Audio.voice("voz_oi", intro_robo)
	if confirm() or pressed("start") or pressed("back"):
		intro_t = INTRO_END   # qualquer botão pula direto para o menu
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
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 1080 - SCENE_GROUND), Color("#b9ab8f"))
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 60), Color("#d8ccb6"))
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 10), Color("#eee5d2"))
	var tex := Data.tex("ui/logo")
	var lw := 1300.0
	var lh := lw * 340.0 / 1700.0
	var alvo := Vector2(960, 360)
	# 1) a grua desce o letreiro preso por cabos (balança um pouco)
	var desce := _smooth(k / IN_DESCE)
	var pend := Vector2(960 + sin(k * 3.0) * 14.0 * (1.0 - _smooth((k - IN_BATE) / 0.4)), lerpf(-lh, alvo.y - 40.0, desce))
	var preso := k < IN_BATE
	if preso:
		for dx in [-lw * 0.32, lw * 0.32]:
			ci.draw_line(Vector2(960 + dx * 0.4, -10), pend + Vector2(dx, -lh / 2.0 + 10), Color("#4a4f5c"), 4.0, true)
		ci.draw_rect(Rect2(pend + Vector2(-lw * 0.42, -lh / 2.0 - 10), Vector2(lw * 0.84, 18)), Color("#3a3f4a"))
	# letras: penduradas → soltam no impacto, caem e quicam até o lugar
	var lc := pend
	var rot := sin(k * 2.0) * 0.02
	var sq := Vector2.ONE
	if k >= IN_BATE:
		var u := clampf((k - IN_BATE) / (IN_ASSENTA - IN_BATE), 0.0, 1.0)
		var queda := 1.0 - absf(cos(u * PI * 2.5)) * (1.0 - u)   # quiques que vão diminuindo
		lc = pend.lerp(alvo, queda)
		lc.y = lerpf(pend.y, alvo.y + 40.0, queda) - 40.0 * u
		rot = (0.08 * (1.0 - u)) * sin(u * 20.0)
		var s2 := sin(u * PI * 5.0) * (1.0 - u) * 0.12
		sq = Vector2(1.0 + s2, 1.0 - s2)
	if tex != null:
		ci.draw_set_transform(lc, rot, sq)
		ci.draw_texture_rect(tex, Rect2(Vector2(-lw / 2.0, -lh / 2.0), Vector2(lw, lh)), false)
		ci.draw_set_transform(Vector2.ZERO)
	# lona azul tapando o letreiro até cair
	if k < IN_LONA + 0.5:
		var cai := _smooth((k - IN_LONA) / 0.5)
		var lr := Rect2(pend + Vector2(-lw * 0.46, -lh / 2.0 + 8 + cai * 700.0), Vector2(lw * 0.92, lh - 10))
		ci.draw_set_transform(lr.get_center(), cai * 0.6, Vector2.ONE)
		var lr0 := Rect2(-lr.size / 2.0, lr.size)
		ci.draw_rect(lr0, Color("#3f7fb5", 1.0 - cai * 0.6))
		for j in 6:
			var x := lr0.position.x + 40 + j * lr0.size.x / 6.0
			ci.draw_line(Vector2(x, lr0.position.y + 6), Vector2(x - 10, lr0.end.y - 6), Color("#2f6595", 1.0 - cai), 5.0)
		Kit.text(ci, Vector2(lr0.position.x, 30), "?", 90, Color(1, 1, 1, 1.0 - cai), HORIZONTAL_ALIGNMENT_CENTER, lr0.size.x, 12)
		ci.draw_set_transform(Vector2.ZERO)
	# pilar de concreto que segura o letreiro (à direita) — o alvo da marretada
	var px := 1180.0   # pilar embaixo do letreiro (sustenta a ponta direita)
	if k < IN_BATE + 0.1:
		ci.draw_rect(Rect2(px - 26, alvo.y + lh * 0.2, 52, SCENE_GROUND - alvo.y - lh * 0.2), Color("#cfc6b4"))
		ci.draw_rect(Rect2(px - 26, alvo.y + lh * 0.2, 52, SCENE_GROUND - alvo.y - lh * 0.2), Kit.INK, false, 4.0)
	else:   # pedaços do pilar voando
		var u := (k - IN_BATE) / 1.2
		for j in 5:
			var p := Vector2(px + (j - 2) * 30.0 + u * (j - 2) * 260.0, SCENE_GROUND - 260.0 + j * 40.0 - 600.0 * u + 900.0 * u * u)
			if p.y < SCENE_GROUND:
				ci.draw_set_transform(p, u * (j + 1) * 3.0)
				ci.draw_rect(Rect2(-22, -16, 44, 32), Color("#cfc6b4"))
				ci.draw_set_transform(Vector2.ZERO)
	# robô sorteado: entra correndo da direita e marreta o pilar
	if k >= IN_LONA:
		var ent := _smooth((k - IN_LONA) / (IN_CORRE - IN_LONA))
		var base := Vector2(lerpf(2150.0, px + 110.0, ent), SCENE_GROUND)
		var pose: Dictionary = RobotVis.idle_pose(k)
		var ph := k * 22.0
		if ent < 1.0:
			pose["feet"] = [Vector2(cos(ph) * 9.0, -maxf(sin(ph), 0.0) * 8.0), Vector2(cos(ph + PI) * 9.0, -maxf(sin(ph + PI), 0.0) * 8.0)]
			pose["lean"] = 0.15
		elif k < IN_BATE:
			pose["hammer_ang"] = lerpf(0.3, -1.4, _smooth((k - IN_CORRE) / (IN_BATE - IN_CORRE)))
			pose["expr"] = "esforco"
		else:
			pose["hammer_ang"] = lerpf(2.4, 0.3, _smooth((k - IN_BATE) / 0.6))
			pose["expr"] = "vitoria" if k > IN_BATE + 0.4 else "esforco"
		RobotVis.draw_robot(ci, {"color": intro_robo % 4, "model": intro_robo, "hammer": true, "fx": {}}, pose, Transform2D(0.0, Vector2(-SCENE_SCALE, SCENE_SCALE), 0.0, base))
		ci.draw_set_transform(Vector2.ZERO)
	# impacto: POW + poeira quando as letras batem
	if k >= IN_BATE and k < IN_BATE + 0.5:
		var u := (k - IN_BATE) / 0.5
		var pc := Vector2(px + 40, SCENE_GROUND - 260)
		Kit.burst(ci, pc, 70.0 * (0.7 + u * 0.5), u * 2.0, 5.0)
		Kit.text(ci, Vector2(pc.x - 120, pc.y + 16), "POW!", 46, Color(1, 1, 1, 1.0 - u), HORIZONTAL_ALIGNMENT_CENTER, 240, 10)
	if k >= IN_ASSENTA - 0.4 and k < IN_ASSENTA + 1.0:
		var u := (k - IN_ASSENTA + 0.4) / 1.4
		for i in 12:
			var side := -1.0 if i % 2 == 0 else 1.0
			var dx := side * (120.0 + (i / 2) * 110.0 + u * 160.0)
			ci.draw_circle(Vector2(960 + dx, alvo.y + lh * 0.48 - u * 30.0), (24.0 + (i % 3) * 8.0) * (1.0 - u * 0.6), Color(0.97, 0.94, 0.86, 0.85 * (1.0 - u)))
	# 5) o elenco entra correndo; a plaquinha "aperte qualquer botão"
	var ent2 := []
	for i in 4:
		ent2.append(_smooth((k - IN_ASSENTA - i * 0.12) / 0.6))
	if k >= IN_ASSENTA:
		_draw_scene_robos(ci, ent2, intro_robo)
	if k > 0.6 and k < INTRO_END - 0.3:
		var a := clampf((k - 0.6) / 0.3, 0.0, 1.0)
		var r := Rect2(760, 1004, 400, 52)
		Kit.chunk(ci, r, Color(0.91, 0.89, 0.82, a), 8, 4, 0.0)
		Kit.text(ci, Vector2(r.position.x, r.position.y + 36), "aperte qualquer botão", 26, Color(Kit.INK, a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

# ---------------------------------------------------------------- CONTROLES (prancha controles_v2, 2026-11-28)
## Central: um cartão por aparelho (teclado A, teclado B, cada controle) com o MODELO reconhecido, MAPEAR e TESTAR.
## MAPEAR vale só para aquele aparelho (dois DualSense iguais têm mapeamentos separados), com PRINCIPAL e ALTERNATIVO.
const Glifos := preload("res://ui/glifos.gd")
const MAP_NAMES := {"left": "ANDAR  ◄", "right": "ANDAR  ►", "up": "CIMA  ▲   (subir / mirar)", "down": "BAIXO  ▼   (descer / pisão)",
	"jump": "PULAR", "hammer": "GOLPE RÁPIDO", "heavy": "MARRETADA PESADA", "dodge": "ESQUIVA", "item": "ESPECIAL (ENGENHOCA)", "start": "PAUSA"}
const MAP_ROWS := 12          # 10 ações + RESTAURAR PADRÃO + SALVAR
const LISTEN_S := 5.0
## Teclas que não podem virar ação: voltar/cancelar dos menus e Shift/Ctrl (o Windows manda "fantasmas" deles).
const KEYS_PROIBIDAS := [KEY_ESCAPE, KEY_BACKSPACE, KEY_DELETE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]
var hub_sel := 0
var hub_btn := 0              # 0 = MAPEAR · 1 = TESTAR
var dev_act := {}             # aparelho -> instante do último botão (o cartão dele pisca: "é este")
var map_dev := ""
var map_m := {}               # mapeamento em edição (só vai para o disco no SALVAR)
var map_sel := 0
var map_col := 0
var map_listen := -1.0        # > 0: esperando o novo botão (segundos restantes)
var map_base := {}            # botões/eixos já apertados quando começou a escuta (só valem depois de soltos)
var map_msg := ""
var map_msg_t := 0.0
var map_msg_row := -1
var map_hold := 0.0
var test_dev := ""

func _hub_devs() -> Array:
	var l: Array = ["kb_a", "kb_b"]
	for j in PlayerInput._joys():
		l.append("joy%d" % j)
	return l

func abrir_controles() -> void:
	main.state = main.S.CONTROLES
	hub_sel = 0
	hub_btn = 0

func _dev_model(dev: String) -> String:
	return PlayerInput.pad_model(dev) if dev.begins_with("joy") else ""

func _dev_title(dev: String) -> String:
	match dev:
		"kb_a": return "TECLADO A"
		"kb_b": return "TECLADO B"
	return PlayerInput.model_title(dev).to_upper()

func _dev_sub(dev: String) -> String:
	match dev:
		"kb_a": return "lado esquerdo · WASD"
		"kb_b": return "lado direito · setas + numérico"
	var fam: String = PlayerInput.MODEL_FAMILY.get(_dev_model(dev), "")
	var con: String = PlayerInput.pad_conexao(dev)
	return "controle %d · %s%s" % [int(dev.substr(3)) + 1, fam, (" · " + con) if con != "" else ""]

func _update_hub() -> void:
	var devs := _hub_devs()
	for d in devs:
		for a in ["jump", "hammer", "heavy", "dodge", "item", "start", "nav_left", "nav_right", "nav_up", "nav_down"]:
			if PlayerInput.dev_pressed(d, a):
				dev_act[d] = t
	hub_sel = clampi(hub_sel, 0, devs.size() - 1)
	if pressed("back"):
		main.state = main.S.OPTIONS
		return
	var h := move_h()
	var v := move_v()
	if h != 0:
		var k := posmod(hub_sel * 2 + hub_btn + h, devs.size() * 2)
		hub_sel = k / 2
		hub_btn = k % 2
	if v != 0:
		var cols := 4 if devs.size() <= 4 else 3
		hub_sel = clampi(hub_sel + v * cols, 0, devs.size() - 1)
	if confirm():
		if hub_btn == 0:
			_abrir_mapear(devs[hub_sel])
		else:
			_abrir_teste(devs[hub_sel])

func _hub_rect(k: int, n: int) -> Rect2:
	var cols := 4 if n <= 4 else 3
	var cw := 420.0 if cols == 4 else 520.0
	var ch := 470.0 if n <= 4 else 380.0
	var x0 := 960.0 - (cols * cw + (cols - 1) * 26.0) / 2.0
	var y0 := 250.0 if n <= 4 else 168.0
	return Rect2(x0 + (k % cols) * (cw + 26.0), y0 + (k / cols) * (ch + 26.0), cw, ch)

func _draw_hub(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.5))
	Kit.ribbon(ci, Rect2(610, 20, 700, 128), "CONTROLES", 58)
	var devs := _hub_devs()
	var dark := Color("#2a1a2e")
	for k in devs.size():
		var dev: String = devs[k]
		var r := _hub_rect(k, devs.size())
		var sel := k == hub_sel
		var flash := clampf(1.0 - (t - float(dev_act.get(dev, -9.0))) / 0.6, 0.0, 1.0)
		if sel:
			Kit.chunk(ci, r.grow(10), Color("#f2c84b"), 34, 0, 0.0)
		Kit.chunk(ci, r, Color("#f4ecdc").lerp(Color("#fff3b0"), flash), 26, 5, 8.0)
		var used: int = PlayerInput.slots.find(dev)
		if used >= 0 and used < main.players.size():
			var pc: Color = Data.TEXT_COLORS[main.players[used]["color"]]
			Kit.chunk(ci, Rect2(r.position + Vector2(14, 14), Vector2(62, 38)), pc, 10, 4, 0.0)
			Kit.text(ci, r.position + Vector2(14, 43), "P%d" % (used + 1), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 62, 5)
		var big := devs.size() <= 4
		var ac := Vector2(r.get_center().x, r.position.y + (150.0 if big else 104.0))
		if dev.begins_with("joy"):
			Glifos.controller(ci, ac, _dev_model(dev), 0.5 if big else 0.36)
		else:
			_kb_art(ci, ac, dev, 0.9 if big else 0.72)
		var ty := r.position.y + (300.0 if big else 214.0)
		Kit.text(ci, Vector2(r.position.x, ty), _dev_title(dev), 32, dark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Kit.text(ci, Vector2(r.position.x + 10, ty + 30), _dev_sub(dev), 19, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 20)
		var mine := PlayerInput.has_custom(dev)
		Kit.text(ci, Vector2(r.position.x, ty + 56), "SUA configuração" if mine else "padrão", 20, Color("#3c9a46") if mine else Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if flash > 0.0:
			Kit.text(ci, Vector2(r.end.x - 150, r.position.y + 44), "é este!", 22, Color("#c0392b"), HORIZONTAL_ALIGNMENT_CENTER, 130)
		elif dev == PlayerInput.principal():
			Kit.chunk(ci, Rect2(r.end.x - 168, r.position.y + 14, 154, 38), Color("#f2c84b"), 10, 4, 0.0)
			Kit.text(ci, Vector2(r.end.x - 168, r.position.y + 42), "PRINCIPAL", 22, dark, HORIZONTAL_ALIGNMENT_CENTER, 154)
		for b in 2:
			var bw := (r.size.x - 70.0) / 2.0
			var br := Rect2(r.position.x + 25 + b * (bw + 20), r.end.y - (76.0 if big else 70.0), bw, 54.0 if big else 50.0)
			Kit.chunk(ci, br, Color("#f2c84b") if (sel and hub_btn == b) else Color("#e9e2d2"), 16, 4, 5.0)
			Kit.text(ci, Vector2(br.position.x, br.position.y + br.size.y * 0.7), ["MAPEAR", "TESTAR"][b], 25, dark, HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
	if devs.size() == 2:
		Kit.sticker(ci, Vector2(0, 820), "nenhum controle detectado: ligue o cabo ou pareie no Bluetooth (PlayStation: CREATE/SHARE + PS · Xbox: botão de parear)", 22, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920)
	Kit.text(ci, Vector2(0, 1010), "Aperte qualquer botão num controle: o cartão dele pisca  ·  só o PRINCIPAL navega; em MAPEAR/TESTAR o controle escolhido assume", 24, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	Kit.text(ci, Vector2(0, 1056), "◄►▲▼ escolhe  ·  PULAR abre  ·  VOLTAR sai", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

## Desenho do teclado no cartão: as teclas de andar e pular daquele lado.
func _kb_art(ci: CanvasItem, c: Vector2, dev: String, s: float) -> void:
	var m := PlayerInput.current_map(dev)
	var r := 30.0 * s
	var g := 70.0 * s
	Glifos.key(ci, c + Vector2(-g * 1.4, -g * 0.55), m["up"][0], r)
	Glifos.key(ci, c + Vector2(-g * 2.4, g * 0.45), m["left"][0], r)
	Glifos.key(ci, c + Vector2(-g * 1.4, g * 0.45), m["down"][0], r)
	Glifos.key(ci, c + Vector2(-g * 0.4, g * 0.45), m["right"][0], r)
	Glifos.key(ci, c + Vector2(g * 1.3, -g * 0.55), m["jump"][0], r)
	Glifos.key(ci, c + Vector2(g * 2.3, -g * 0.55), m["hammer"][0], r)
	Glifos.key(ci, c + Vector2(g * 1.3, g * 0.45), m["heavy"][0], r)
	Glifos.key(ci, c + Vector2(g * 2.3, g * 0.45), m["dodge"][0], r)

# ---- MAPEAR (só este aparelho)
func _abrir_mapear(dev: String) -> void:
	map_dev = dev
	map_m = PlayerInput.current_map(dev)
	map_sel = 0
	map_col = 0
	map_listen = -1.0
	map_msg = ""
	map_msg_row = -1
	map_hold = 0.25
	main.state = main.S.CONFIGPAD

func _map_msg(txt: String, row := -1) -> void:
	map_msg = txt
	map_msg_row = row
	map_msg_t = 2.6

func _update_mapear(dt: float) -> void:
	map_msg_t = maxf(map_msg_t - dt, 0.0)
	if not map_dev in _hub_devs():
		main.state = main.S.CONTROLES   # controle desconectou
		return
	if map_listen > 0.0:
		_listen(dt)
		return
	if map_hold > 0.0:
		map_hold -= dt
		return
	if pressed("back"):
		main.state = main.S.CONTROLES   # sai sem salvar
		return
	map_sel = posmod(map_sel + move_v(), MAP_ROWS)
	var h := move_h()
	if h != 0:
		if map_sel < 10:
			map_col = clampi(map_col + h, 0, 1)
		else:
			map_sel = 10 if h < 0 else 11
	if pressed("heavy") and map_sel < 10 and map_col == 1:
		map_m[PlayerInput.MAP_ACTIONS[map_sel]][1] = null
		_map_msg("alternativo apagado", map_sel)
	elif confirm():
		if map_sel < 10:
			map_listen = LISTEN_S
			map_base = _raw_state()
			PlayerInput.key_hits.clear()
		elif map_sel == 10:
			map_m = PlayerInput.default_map(map_dev)
			_map_msg("padrão de fábrica de volta — SALVAR para manter")
		else:
			_salvar_map()

func _raw_state() -> Dictionary:
	var st := {}
	if map_dev.begins_with("joy"):
		var j := int(map_dev.substr(3))
		for b in 32:
			st["b%d" % b] = PlayerInput.jbtn(j, b)
		for a in 6:
			st["a%d" % a] = absf(PlayerInput.jaxis(j, a)) > 0.4
	return st

func _listen(dt: float) -> void:
	map_listen -= dt
	if PlayerInput.key_hits.has(KEY_ESCAPE) or map_listen <= 0.0:
		_map_msg("nada apertado" if map_listen <= 0.0 else "cancelado", map_sel)
		map_listen = -1.0
		map_hold = 0.2
		PlayerInput.key_hits.clear()
		return
	if not map_dev.begins_with("joy"):
		for k in PlayerInput.key_hits:
			if k in KEYS_PROIBIDAS:
				_map_msg("essa tecla não pode (Esc, ⌫, Del, Shift, Ctrl, Alt)", map_sel)
				continue
			_assign(k)
			break
		PlayerInput.key_hits.clear()
		return
	var j := int(map_dev.substr(3))
	for key in map_base.keys():   # o que já estava apertado só conta depois de solto
		if map_base[key]:
			var solto: bool = (not PlayerInput.jbtn(j, int(key.substr(1)))) if key[0] == "b" else absf(PlayerInput.jaxis(j, int(key.substr(1)))) < 0.3
			if solto:
				map_base[key] = false
	for b in 32:
		if PlayerInput.jbtn(j, b) and not map_base.get("b%d" % b, false):
			if b in [JOY_BUTTON_BACK, JOY_BUTTON_GUIDE]:
				_map_msg("esse botão é do sistema / VOLTAR", map_sel)
				map_base["b%d" % b] = true
				return
			_assign(["b", b])
			return
	for a in 6:
		var v := PlayerInput.jaxis(j, a)
		if absf(v) > 0.7 and not map_base.get("a%d" % a, false):
			if a >= JOY_AXIS_TRIGGER_LEFT and v < 0.0:
				continue
			_assign(["a", a, 1 if v > 0.0 else -1])
			return

## Põe o sinal na célula escolhida; se ele já estava em outra ação deste aparelho, as duas trocam de lugar.
func _assign(b) -> void:
	var a: String = PlayerInput.MAP_ACTIONS[map_sel]
	var old = map_m[a][map_col]
	var troca := ""
	for a2 in PlayerInput.MAP_ACTIONS:
		for c2 in 2:
			if (a2 != a or c2 != map_col) and map_m[a2][c2] != null and map_m[a2][c2] == b:
				map_m[a2][c2] = old
				troca = a2
	map_m[a][map_col] = b
	for a2 in PlayerInput.MAP_ACTIONS:   # principal vazio: o alternativo sobe
		if map_m[a2][0] == null and map_m[a2][1] != null:
			map_m[a2] = [map_m[a2][1], null]
	map_listen = -1.0
	map_hold = 0.3
	Audio.play("item")
	if troca != "":
		_map_msg("trocou com %s" % MAP_NAMES[troca].split("  ")[0], map_sel)
	else:
		_map_msg("", -1)

func _salvar_map() -> void:
	for a in PlayerInput.MAP_ACTIONS:
		if map_m[a][0] == null:
			_map_msg("%s ficou sem botão" % MAP_NAMES[a].split("  ")[0], PlayerInput.MAP_ACTIONS.find(a))
			Audio.play("menu_negado")
			return
	var key := PlayerInput.dev_key(map_dev)
	var legado := map_dev.begins_with("joy") and PlayerInput.custom.has(PlayerInput.joy_guid(int(map_dev.substr(3))))
	if map_m == PlayerInput.default_map(map_dev) and not legado:
		PlayerInput.save_custom(key, {})
	else:
		PlayerInput.save_custom(key, map_m.duplicate(true))
	Audio.play("rodada_vence")
	PlayerInput.toasts.append({"text": "Salvo: %s" % _dev_title(map_dev).capitalize(), "t": 0.0, "ok": true, "dev": map_dev})
	main.state = main.S.CONTROLES

func _draw_mapear(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.55))
	var dark := Color("#2a1a2e")
	var joy := map_dev.begins_with("joy")
	var model := _dev_model(map_dev)
	Kit.ribbon(ci, Rect2(460, 14, 1000, 116), "MAPEAR — " + _dev_title(map_dev), 50)
	var quem := _dev_sub(map_dev)
	var used: int = PlayerInput.slots.find(map_dev)
	if used >= 0:
		quem += "  ·  P%d" % (used + 1)
	Kit.text(ci, Vector2(0, 160), quem, 24, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	# desenho com o botão da ação escolhida aceso
	var pr := Rect2(50, 200, 640, 600)
	Kit.chunk(ci, pr, Color("#f4ecdc"), 26, 5, 8.0)
	var cur = map_m[PlayerInput.MAP_ACTIONS[map_sel]][map_col] if map_sel < 10 else null
	var pulse := 1.0 + 0.08 * sin(t * 7.0)
	if joy:
		var lit: Array = []
		if cur != null and Glifos.spec_glyph(cur) != "":
			lit.append(Glifos.spec_glyph(cur))
		Glifos.controller(ci, pr.get_center() + Vector2(0, -40), model, 0.92, lit, pulse)
		Kit.text(ci, Vector2(pr.position.x, pr.end.y - 70), "o botão da ação escolhida", 22, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
		Kit.text(ci, Vector2(pr.position.x, pr.end.y - 40), "acende no desenho", 22, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	else:
		Glifos.key(ci, pr.get_center() + Vector2(0, -60), cur, 90.0 * pulse, cur != null)
		Kit.text(ci, Vector2(pr.position.x, pr.end.y - 70), "tecla da ação escolhida", 22, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
		Kit.text(ci, Vector2(pr.position.x, pr.end.y - 40), "(posição da tecla: vale para qualquer layout)", 20, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	# lista: ação · PRINCIPAL · ALTERNATIVO
	var lx := 730.0
	var cx1 := lx + 560.0
	var cx2 := lx + 690.0
	Kit.text(ci, Vector2(cx1 - 70, 214), "PRINCIPAL", 19, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 140, 5)
	Kit.text(ci, Vector2(cx2 - 80, 214), "ALTERNATIVO", 19, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 160, 5)
	for k in 10:
		var a: String = PlayerInput.MAP_ACTIONS[k]
		var y := 230.0 + k * 62.0 + (10.0 if k >= 4 else 0.0)
		var rr := Rect2(lx, y, 780, 54)
		var ouvindo := map_listen > 0.0 and k == map_sel
		if k == map_sel and not ouvindo:
			Kit.chunk(ci, rr.grow(5), Color("#f2c84b"), 18, 0, 0.0)
		Kit.chunk(ci, rr, Color("#f2c84b") if ouvindo else Color.WHITE, 14, 4, 4.0)
		Kit.text(ci, Vector2(lx + 22, y + 37), MAP_NAMES[a], 23, dark)
		if ouvindo:
			var txt := ("aperte o novo botão…  %d" if joy else "aperte a nova tecla…  %d") % ceili(map_listen)
			Kit.text(ci, Vector2(lx + 330, y + 37), txt, 22, Color("#a01528"), HORIZONTAL_ALIGNMENT_RIGHT, 430)
			continue
		for c in 2:
			var cc := Vector2(cx1 if c == 0 else cx2, y + 27)
			if k == map_sel and c == map_col:
				ci.draw_arc(cc, 31, 0, TAU, 32, dark, 5.0, true)
			Glifos.bind(ci, cc, map_dev, model, map_m[a][c], 19.0)
		if map_msg_row == k and map_msg_t > 0.0 and map_msg != "":
			Kit.text(ci, Vector2(lx + 200, y + 36), map_msg, 18, Color("#8a5a10"), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	# botões e avisos
	var bx := 1560.0
	for b in 2:
		var br := Rect2(bx, 220 + b * 92, 310, 68)
		if map_sel == 10 + b:
			Kit.chunk(ci, br.grow(6), Color("#f2c84b"), 22, 0, 0.0)
		Kit.chunk(ci, br, Color("#e9e2d2") if b == 0 else Color("#5cc45c"), 18, 5, 6.0)
		Kit.text(ci, Vector2(br.position.x, br.position.y + 44), ["RESTAURAR PADRÃO", "SALVAR"][b], 25, dark, HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
	var vale: Array = ["vale SÓ para este", "controle — os outros", "%s não mudam" % PlayerInput.MODEL_NAMES.get(model, "")] if joy else ["vale SÓ para o", _dev_title(map_dev), ""]
	for k in vale.size():
		Kit.text(ci, Vector2(bx - 20, 450 + k * 30), vale[k], 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 350, 6)
	var dicas: Array = ["botão repetido? troca", "de lugar sozinho", "", "direções aceitam", "analógico, direcional", "ou qualquer botão"] if joy else ["tecla repetida? troca", "de lugar sozinha", "", "Esc cancela a escuta"]
	for k in dicas.size():
		Kit.text(ci, Vector2(bx - 20, 570 + k * 28), dicas[k], 20, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 350, 5)
	if map_msg_row == -1 and map_msg_t > 0.0 and map_msg != "":
		Kit.sticker(ci, Vector2(0, 900), map_msg, 26, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920)
	var apaga := "TRIÂNGULO / Y apaga o alternativo" if joy else "a tecla de MARRETADA apaga o alternativo"
	Kit.text(ci, Vector2(0, 1010), "▲▼ escolhe a ação  ·  ◄► PRINCIPAL / ALTERNATIVO  ·  PULAR muda (5 s)  ·  " + apaga, 22, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	Kit.text(ci, Vector2(0, 1050), "VOLTAR sai sem salvar  ·  os menus continuam andando pelo analógico/direcional (ninguém fica preso)", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)

# ---- TESTAR (ao vivo: o que chega do aparelho e o que o jogo entende)
func _abrir_teste(dev: String) -> void:
	test_dev = dev
	pad_prev.clear()
	main.state = main.S.TESTPAD

func _update_teste() -> void:
	if PlayerInput.dev_pressed("kb_a", "back") or PlayerInput.dev_pressed("kb_b", "back"):
		main.state = main.S.CONTROLES
		Audio.play("menu_voltar")
		return
	if not test_dev in _hub_devs():
		main.state = main.S.CONTROLES
		return
	if test_dev.begins_with("joy"):
		var j := int(test_dev.substr(3))
		if _pad_edge(j, JOY_BUTTON_BACK):
			main.state = main.S.CONTROLES
			Audio.play("menu_voltar")
			return
	for d in ([test_dev] if test_dev.begins_with("joy") else ["kb_a", "kb_b"]):
		if PlayerInput.dev_pressed(d, "jump"):
			Audio.play("pulo")
			if d.begins_with("joy"):
				Input.start_joy_vibration(int(d.substr(3)), 0.6, 0.6, 0.2)   # PULAR vibra: testa o motor
		if PlayerInput.dev_pressed(d, "hammer"):
			Audio.play("marreta_vento")
		if PlayerInput.dev_pressed(d, "item") or PlayerInput.dev_pressed(d, "heavy"):
			Audio.play("item")

const RAW_IDS := {"baixo": JOY_BUTTON_A, "dir": JOY_BUTTON_B, "esq": JOY_BUTTON_X, "cima": JOY_BUTTON_Y, "lb": JOY_BUTTON_LEFT_SHOULDER,
	"rb": JOY_BUTTON_RIGHT_SHOULDER, "start": JOY_BUTTON_START, "select": JOY_BUTTON_BACK, "ls": JOY_BUTTON_LEFT_STICK, "rs": JOY_BUTTON_RIGHT_STICK,
	"d-cima": JOY_BUTTON_DPAD_UP, "d-baixo": JOY_BUTTON_DPAD_DOWN, "d-esq": JOY_BUTTON_DPAD_LEFT, "d-dir": JOY_BUTTON_DPAD_RIGHT}

func _draw_acoes(ci: CanvasItem, x: float, y0: float, dev: String, titulo: String) -> void:
	var dark := Color("#2a1a2e")
	var m := PlayerInput.current_map(dev)
	var model := _dev_model(dev)
	Kit.text(ci, Vector2(x, y0), titulo, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 560, 6)
	for k in 10:
		var a: String = PlayerInput.MAP_ACTIONS[k]
		var y := y0 + 22 + k * 58
		var on := PlayerInput.dev_held(dev, a)
		Kit.chunk(ci, Rect2(x, y, 560, 50), Color("#f2c84b") if on else Color.WHITE, 14, 4, 4.0)
		Kit.text(ci, Vector2(x + 18, y + 34), MAP_NAMES[a].split("   ")[0], 21, dark)
		Glifos.bind(ci, Vector2(x + 430, y + 25), dev, model, m[a][0], 17.0)
		Glifos.bind(ci, Vector2(x + 510, y + 25), dev, model, m[a][1], 17.0)

func _draw_teste(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.55))
	var dark := Color("#2a1a2e")
	if not test_dev.begins_with("joy"):
		# teclado: os dois lados ao mesmo tempo (teste de "fantasma")
		Kit.ribbon(ci, Rect2(560, 14, 800, 116), "TESTAR TECLADO", 50)
		_draw_acoes(ci, 300, 190, "kb_a", "TECLADO A")
		_draw_acoes(ci, 1060, 190, "kb_b", "TECLADO B")
		var n := 0
		for k in PlayerInput._keys:
			if PlayerInput._keys[k]:
				n += 1
		Kit.text(ci, Vector2(0, 850), "teclas apertadas agora: %d" % n, 26, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
		Kit.text(ci, Vector2(0, 900), "TESTE DE FANTASMA: os dois apertem andar + pular + golpe juntos. Se alguma linha não acender,", 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
		Kit.text(ci, Vector2(0, 934), "este teclado não aguenta essa combinação: troque uma das teclas em MAPEAR (grupos mais afastados funcionam melhor).", 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
		Kit.text(ci, Vector2(0, 1050), "Aperte as teclas para ver acender  ·  ESC volta", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)
		return
	var j := int(test_dev.substr(3))
	var model := _dev_model(test_dev)
	Kit.ribbon(ci, Rect2(460, 14, 1000, 116), "TESTAR — " + _dev_title(test_dev), 50)
	Kit.text(ci, Vector2(0, 160), _dev_sub(test_dev), 24, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)
	var pr := Rect2(60, 200, 760, 560)
	Kit.chunk(ci, pr, Color("#f4ecdc"), 26, 5, 8.0)
	var lit: Array = []
	for id in RAW_IDS:
		if PlayerInput.jbtn(j, RAW_IDS[id]):
			lit.append(id)
	if PlayerInput.jaxis(j, JOY_AXIS_TRIGGER_LEFT) > 0.4:
		lit.append("lt")
	if PlayerInput.jaxis(j, JOY_AXIS_TRIGGER_RIGHT) > 0.4:
		lit.append("rt")
	if Vector2(PlayerInput.jaxis(j, JOY_AXIS_LEFT_X), PlayerInput.jaxis(j, JOY_AXIS_LEFT_Y)).length() > 0.4:
		lit.append("ls")
	if Vector2(PlayerInput.jaxis(j, JOY_AXIS_RIGHT_X), PlayerInput.jaxis(j, JOY_AXIS_RIGHT_Y)).length() > 0.4:
		lit.append("rs")
	Glifos.controller(ci, pr.get_center() + Vector2(0, -30), model, 1.05, lit)
	var ids: Array = PlayerInput.joy_ids(j)
	var info := "fabricante %04X · produto %04X" % [ids[0], ids[1]] if ids[0] != 0 else "fabricante não informado"
	Kit.text(ci, Vector2(pr.position.x, pr.end.y - 46), info + "  ·  " + PlayerInput.joy_name(j).substr(0, 28), 18, Color("#6b5a70"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	var known := Input.get_connected_joypads().has(j) and Input.is_joy_known(j)
	Kit.text(ci, Vector2(pr.position.x, pr.end.y - 18), "mapeamento reconhecido" if known else "mapeamento DESCONHECIDO: use MAPEAR para acertar os botões", 18,
		Color("#3c9a46") if known else Color("#a01528"), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	_draw_acoes(ci, 1000, 190, test_dev, "O QUE O JOGO ENTENDE")
	Kit.text(ci, Vector2(60, 800), "sinais crus: " + PlayerInput.raw_now(j), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	Kit.text(ci, Vector2(60, 832), "último sinal: %s" % String(PlayerInput.last_raw.get(j, "—")), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	if PlayerInput.aliases.has(test_dev):
		Kit.text(ci, Vector2(60, 864), "cópia do mesmo controle (o Windows mostrou 2x): usado junto com o original", 20, Color("#ffd27a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	Kit.text(ci, Vector2(0, 990), "Steam aberta pode esconder ou duplicar controles (Steam Input) · relatório: " + ProjectSettings.globalize_path("user://controles.txt"), 19, Color("#fff4c8"), HORIZONTAL_ALIGNMENT_CENTER, 1920, 5)
	Kit.text(ci, Vector2(0, 1050), "Aperte os botões para ver acender  ·  PULAR vibra  ·  SELECT ou ESC volta", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)

# ---------------------------------------------------------------- cenário do menu (não depende da fase)
const SCENE_GROUND := 880.0
const SCENE_X := [270.0, 410.0, 1580.0, 1760.0]   # dos dois lados da coluna de placas do menu
const SCENE_FACE := [1.0, -1.0, -1.0, -1.0]
const SCENE_SCALE := 2.4

## Chão de caixotes e os quatro robôs em ação: azul marreta o verde (que voa e volta), rosa quica de botas
## de mola, amarelo corre desesperado com o TNT aceso. enter[i] = 0..1 (entrando correndo pela lateral).
func _draw_scene(ci: CanvasItem, enter: Array) -> void:
	# "Canteiro vivo" (A21): a obra ao fundo e a laje de concreto do térreo como palco
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 1080 - SCENE_GROUND), Color("#b9ab8f"))
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 60), Color("#d8ccb6"))
	ci.draw_rect(Rect2(0, SCENE_GROUND, 1920, 10), Color("#eee5d2"))
	for k in 24:
		ci.draw_circle(Vector2(30 + k * 82, SCENE_GROUND + 110 + (k % 3) * 22), 4.0, Color("#958a72"))
	_draw_scene_robos(ci, enter)

func _draw_scene_robos(ci: CanvasItem, enter: Array, sem_modelo := -1) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	ci.draw_texture_rect(Data.tex("cenario/tnt"), Rect2(1830, SCENE_GROUND - 64, 64, 64), false)
	ci.draw_texture_rect(Data.tex("cenario/caixote_1"), Rect2(1830, SCENE_GROUND - 128, 64, 64), false)
	var cyc := fmod(now, 1.6) / 1.6   # ciclo da marretada
	for i in 4:
		var e: float = enter[i]
		if e <= 0.0 or i == sem_modelo:   # abertura: quem marretou já está em cena
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
