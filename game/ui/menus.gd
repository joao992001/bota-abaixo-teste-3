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
			_update_pads()
		S.CONFIGPAD:
			_update_config(dt)
		S.ARENAS:
			var n := arena_list().size() + mapas_bloqueados()
			arena_sel = posmod(arena_sel + move_h(), n)
			var v := move_v()
			if v != 0:
				arena_sel = clampi(arena_sel + v * 4, 0, n - 1)
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

## JOGAR (A22, 2026-11-26): a tela de MODOS é pulada enquanto só o Derruba existir; volta quando houver outro modo.
func abrir_mapas() -> void:
	var m: Dictionary = main.demo.find_mode("derruba")
	main.game_mode = "derruba"
	main.demo.items_on = bool(m.get("itens", true))
	arena_sel = 0
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

## Cartazes bloqueados de exemplo (lona + cadeado) até existirem outros mapas: o tapume sempre mostra 4 cartazes (A23).
func mapas_bloqueados() -> int:
	return maxi(0, 4 - arena_list().size())

## Retângulos dos cartazes no tapume. 4 cartazes = posições da prancha aprovada (6_referencia_mapas_preferida.png).
func _cartazes_rects(n: int) -> Array:
	if n == 4:
		return [Rect2(70, 300, 380, 500), Rect2(520, 260, 560, 560), Rect2(1150, 300, 330, 500), Rect2(1540, 300, 330, 500)]
	var out := []
	var w := minf(400.0, 1780.0 / n - 30.0)
	for i in n:
		out.append(Rect2(70 + i * (1780.0 / n) + (1780.0 / n - w) / 2.0, 300, w, 500))
	return out

## Mapas (A21/A23) = IGUAL à prancha aprovada: tapume de obra com cartazes presos por fita crepe, título pendurado no cabo
## da grua, Sorteio "?", o mapa com foto e capacetes das cenas, cartazes bloqueados com lona/corrente/cadeado, régua dos
## Projetos de Demolição e dois robôs na laje.
func _draw_arenas(ci: CanvasItem) -> void:
	Obra.fundo(ci, t)
	ci.draw_rect(Rect2(0, 930, 1920, 150), Color("#b9ab8f"))   # laje
	ci.draw_rect(Rect2(0, 930, 1920, 60), Color("#d8ccb6"))
	ci.draw_rect(Rect2(0, 930, 1920, 10), Color("#eee5d2"))
	for k in 24:
		ci.draw_circle(Vector2(30 + k * 82, 1040 + (k % 3) * 12), 4.0, Color("#958a72"))
	for k in 9:   # tapume: painéis de compensado pintados
		var x := -40.0 + k * 230.0
		ci.draw_rect(Rect2(x, 170, 236, 760), Color("#7fae86") if k % 2 == 0 else Color("#86b48c"))
		ci.draw_rect(Rect2(x, 170, 236, 760), Color("#4d7a56"), false, 3.0)
	Obra.zebra(ci, Rect2(0, 150, 1920, 26))
	Obra.zebra(ci, Rect2(0, 920, 1920, 18))
	ci.draw_line(Vector2(960, -4), Vector2(960, 58), Color("#4a4f5c"), 5.0)   # título no cabo da grua
	Obra.corrente(ci, 820, 50, 74)
	Obra.corrente(ci, 1100, 50, 74)
	Obra.placa(ci, Vector2(960, 70), 560, 96, "ESCOLHA O MAPA" if main.game_mode == "derruba" else "ESCOLHA A ARENA", true, 0.0, 50)
	var list := arena_list()
	var nb := mapas_bloqueados()
	var rects := _cartazes_rects(list.size() + nb)
	for i in list.size() + nb:
		var r: Rect2 = rects[i]
		var on := i == arena_sel
		var c := r.get_center()
		var rot := 0.0
		if on and shake_card > 0.0:
			rot = sin(shake_card * 60.0) * 0.04
		var xf := Transform2D(rot, Vector2.ONE * (1.03 if on else 1.0), 0.0, c)
		ci.draw_set_transform_matrix(xf)
		var rr := Rect2(-r.size / 2.0, r.size)
		if on:
			ci.draw_style_box(Obra._sb(Obra.YEL, 14, 6), rr.grow(16))
		if i < list.size():
			_cartaz_mapa(ci, rr, list[i], xf)
		else:
			_cartaz_bloqueado(ci, rr)
		if on:
			Obra.chip(ci, rr.position + Vector2(-20, -40), 1)
		ci.draw_set_transform(Vector2.ZERO)
	if main.game_mode == "derruba":
		_draw_projetos(ci, Rect2(1150, 830, 620, 74))
	# elenco na laje (prancha): Picareta verde à esquerda, Marretão azul à direita
	var now := Time.get_ticks_msec() / 1000.0
	var po: Dictionary = RobotVis.idle_pose(now)
	var ph := now * 14.0
	po["feet"] = [Vector2(cos(ph) * 8.0, -maxf(sin(ph), 0.0) * 7.0), Vector2(cos(ph + PI) * 8.0, -maxf(sin(ph + PI), 0.0) * 7.0)]
	po["lean"] = 0.12
	RobotVis.draw_robot(ci, {"color": 1, "model": 1, "hammer": true, "fx": {}}, po, Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(66, 930)))
	RobotVis.draw_robot(ci, {"color": 0, "model": 0, "hammer": true, "fx": {}}, RobotVis.idle_pose(now + 1.0), Transform2D(0.0, Vector2(-1.5, 1.5), 0.0, Vector2(1858, 930)))
	ci.draw_set_transform(Vector2.ZERO)
	Obra.dica(ci, "◄► escolher  ·  PULAR confirmar  ·  ESC voltar")

## Cartaz de papel com fita crepe nos cantos (comum a todos os cartazes do tapume).
func _papel_cartaz(ci: CanvasItem, rr: Rect2, xf: Transform2D) -> void:
	ci.draw_style_box(Obra._sb(Color(Kit.INK, 0.3), 6), Rect2(rr.position + Vector2(6, 10), rr.size))
	ci.draw_style_box(Obra._sb(Color("#f6eedb"), 6, 5), rr)
	for fx in [-1.0, 1.0]:   # fita crepe nos cantos
		ci.draw_set_transform_matrix(xf * Transform2D(0.52 * fx, Vector2(rr.get_center().x + fx * (rr.size.x / 2.0 - 25.0), rr.position.y + 5.0)))
		ci.draw_rect(Rect2(-45, -15, 90, 30), Color(0.91, 0.85, 0.66, 0.9))
		ci.draw_set_transform_matrix(xf)

func _cartaz_mapa(ci: CanvasItem, rr: Rect2, a: Dictionary, xf: Transform2D) -> void:
	_papel_cartaz(ci, rr, xf)
	var x := rr.position.x
	var w := rr.size.x
	if a["id"] == "sorteio":
		var tr := Rect2(x + 22, rr.position.y + 22, w - 44, 290)
		ci.draw_style_box(Obra._sb(Color("#9fe3ee"), 6, 4), tr)
		Kit.sticker(ci, Vector2(tr.position.x, tr.get_center().y + 72), "?", 200, Obra.YEL, HORIZONTAL_ALIGNMENT_CENTER, tr.size.x)
		Kit.text(ci, Vector2(x, rr.position.y + 372), "SORTEIO", 36, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, w)
		Kit.text(ci, Vector2(x, rr.end.y - 40), String(a.get("dica", "")), 22, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, w)
		return
	var th := rr.size.y * 0.58
	var tr2 := Rect2(x + 22, rr.position.y + 22, w - 44, th)
	var thumb := Data.tex("ui/arena_" + String(a["id"]))
	if thumb != null:   # foto cortada no meio (slice), sem esticar
		var ts := thumb.get_size()
		var esc := maxf(tr2.size.x / ts.x, tr2.size.y / ts.y)
		var src := Rect2((ts - tr2.size / esc) / 2.0, tr2.size / esc)
		ci.draw_texture_rect_region(thumb, tr2, src)
	else:
		ci.draw_rect(tr2, Color("#9fe3ee"))
	ci.draw_rect(tr2, Kit.INK, false, 4.0)
	var nome := String(a["nome"]).to_upper()
	Kit.text(ci, Vector2(x, rr.position.y + th + 80), nome, 36 if nome.length() < 20 else 30, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, w)
	var mf: Dictionary = MapaReg.manifesto(main.game_mode, String(a["id"])) if main.game_mode == "derruba" else {}
	if mf.is_empty():
		Kit.text_box(ci, Vector2(x + 14, rr.position.y + th + 110), w - 28, String(a.get("dica", "")), 21, Kit.SOFT, 2)
		return
	# capacetes = cenas descobertas (amarelo + nome) / não descobertas (cinza + "?")
	var vis: Array = main.perfil.dados.get("cenas_visitadas", {}).get(a["id"], [])
	var cenas: Array = MapaReg.cenas(main.game_mode, String(a["id"]))
	for k in cenas.size():
		var cn: Dictionary = cenas[k]
		var ok: bool = String(cn.get("id", "")) in vis
		var cx := x + w / 2.0 - 110.0 * (cenas.size() - 1) / 2.0 + k * 110.0
		_capacete(ci, Vector2(cx, rr.end.y - 60), ok)
		Kit.text(ci, Vector2(cx - 60, rr.end.y - 26), String(cn.get("nome", "")).to_upper() if ok else "?", 17, Kit.INK if ok else Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, 120)

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

## Mapa ainda bloqueado: lona azul por cima, corrente atravessada e cadeado; "???" e BLOQUEADO.
func _cartaz_bloqueado(ci: CanvasItem, rr: Rect2) -> void:
	ci.draw_style_box(Obra._sb(Color("#f6eedb"), 6, 5), rr)
	var x := rr.position.x
	var y := rr.position.y
	var w := rr.size.x
	var h := rr.size.y
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 10, y + 20), Vector2(x + w + 10, y - 6), Vector2(x + w + 6, y + h + 10), Vector2(x - 6, y + h - 6)]), Color("#3f7fb5", 0.95))
	for k in 5:   # dobras da lona
		var x0 := x + 20 + k * w / 5.0
		ci.draw_polyline(PackedVector2Array([Vector2(x0, y + 10), Vector2(x0 + 12, y + h * 0.5), Vector2(x0 - 6, y + h - 4)]), Color("#2f6595"), 5.0, true)
	var c0 := Vector2(x - 10, y + h * 0.45)
	var c1 := Vector2(x + w + 10, y + h * 0.55)
	for k in 18:   # corrente tracejada
		var u0 := k / 18.0
		ci.draw_line(c0.lerp(c1, u0), c0.lerp(c1, u0 + 0.7 / 18.0), Color("#8d98a4"), 10.0)
	var lc := Vector2(x + w / 2.0, y + h * 0.5)
	ci.draw_arc(lc + Vector2(0, -30), 24.0, PI, TAU, 16, Kit.INK, 10.0, true)
	ci.draw_line(lc + Vector2(-24, -30), lc + Vector2(-24, -8), Kit.INK, 10.0)
	ci.draw_line(lc + Vector2(24, -30), lc + Vector2(24, -8), Kit.INK, 10.0)
	ci.draw_style_box(Obra._sb(Obra.YEL, 10, 0), Rect2(lc + Vector2(-40, -30), Vector2(80, 66)))
	Kit.text(ci, Vector2(x, y + h - 100), "? ? ?", 34, Color("#2f6595"), HORIZONTAL_ALIGNMENT_CENTER, w)
	Kit.text(ci, Vector2(x, y + h - 40), "BLOQUEADO", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w, 6)

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
				var names := ["ataque", "controle", "transformacao"]
				for k in 3:
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
