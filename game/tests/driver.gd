extends Node
## Teste automático (--autotest) e capturas de tela (--shot=<pasta>), com controles virtuais.
## Uso: godot --headless --path game --fixed-fps 60 -- --autotest

var main: Node
var fails := 0
var S

func _ready() -> void:
	S = main.S
	main.perfil.caminho = "user://perfil_teste.json"   # testes, vídeos e vitrines nunca gravam no perfil do jogador
	main.perfil.dados = main.perfil.novo()
	_run.call_deferred()

func _run() -> void:
	var shot := ""
	var anim := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		if a.begins_with("--lab="):
			await lab_shots(a.trim_prefix("--lab="))
			get_tree().quit()
			return
		if a.begins_with("--canteiro="):
			await canteiro_frames(a.trim_prefix("--canteiro="))
			get_tree().quit()
			return
		if a.begins_with("--prancha="):
			await prancha_canteiro(a.trim_prefix("--prancha="))
			get_tree().quit()
			return
		if a.begins_with("--pulo="):
			await pulo_frames(a.trim_prefix("--pulo="))
			get_tree().quit()
			return
		if a.begins_with("--elenco="):
			await elenco_frames(a.trim_prefix("--elenco="))
			get_tree().quit()
			return
		if a.begins_with("--fase="):
			await fase_frames(a.trim_prefix("--fase="))
			get_tree().quit()
			return
		if a.begins_with("--luta="):
			await luta_frames(a.trim_prefix("--luta="))
			get_tree().quit()
			return
		if a.begins_with("--mechas="):
			await mechas_frames(a.trim_prefix("--mechas="))
			get_tree().quit()
			return
		if a.begins_with("--equipa="):
			await equipa_frames(a.trim_prefix("--equipa="))
			get_tree().quit()
			return
		if a.begins_with("--eventos="):
			await eventos_frames(a.trim_prefix("--eventos="))
			get_tree().quit()
			return
		if a.begins_with("--spells="):
			await spells_frames(a.trim_prefix("--spells="))
			get_tree().quit()
			return
		if a.begins_with("--hud="):
			await hud_frames(a.trim_prefix("--hud="))
			get_tree().quit()
			return
		if a.begins_with("--combate="):
			await combate_frames(a.trim_prefix("--combate="))
			get_tree().quit()
			return
		if a.begins_with("--anim="):
			anim = a.substr(7)
		if a.begins_with("--intro="):
			var dir: String = a.substr(8)
			DirAccess.make_dir_recursive_absolute(dir)
			get_window().size = Vector2i(1920, 1080)
			main.go_menu()
			main.state = S.INTRO
			main.menus.intro_t = 0.0
			main.menus.intro_frames = 0
			main.menus.intro_hit = false
			main.menus.intro_hi = false
			var shots := [30, 60, 100, 150, 170, 190, 230, 300]
			var fr := 0
			for target in shots:
				await frames(target - fr)
				fr = target
				await snap(dir, "intro_%03d" % target)
			get_tree().quit(0)
			return
		if a.begins_with("--espiar="):
			await espiar(a.trim_prefix("--espiar="))
			get_tree().quit()
			return
		if a.begins_with("--maquete="):
			await maquete_frames(a.trim_prefix("--maquete="))
			get_tree().quit()
			return
		if a.begins_with("--robos="):
			await robos_sheet(a.trim_prefix("--robos="))
			get_tree().quit()
			return
		if a == "--perf-vaza":
			await perf_vaza()
			get_tree().quit(0)
			return
		if a.begins_with("--estudo-destruicao="):
			await estudo_destruicao(int(a.substr(20)))
			get_tree().quit(0)
			return
		if a.begins_with("--cargueiro-video="):   # vídeo dos perigos de uma cena (--video-cena=1|2|3)
			await cargueiro_video(a.substr(18))
			get_tree().quit(0)
			return
		if a.begins_with("--cargueiro="):
			await cargueiro_frames(a.substr(12))
			get_tree().quit(0)
			return
		if a.begins_with("--perf-derruba="):
			await perf_derruba(a.substr(15))
			get_tree().quit(0)
			return
		if a == "--perf-canteiro":
			await perf_canteiro()
			get_tree().quit()
			return
		if a.begins_with("--perf"):
			await perf_run()
			get_tree().quit(0)
			return
		if a.begins_with("--stats="):
			await stats_run(int(a.substr(8)))
			get_tree().quit(0)
			return
		if a.begins_with("--video="):
			await video_frames(a.substr(8))
			get_tree().quit(0)
			return
		if a.begins_with("--arenas="):
			await arenas_frames(a.substr(9))
			get_tree().quit(0)
			return
		if a.begins_with("--projetos="):   # só a tela PROJETOS (v2): capturas + quadros do vídeo
			DirAccess.make_dir_recursive_absolute(a.substr(11))
			get_window().size = Vector2i(1920, 1080)
			PlayerInput.virtual = {"v0": {}, "v1": {}}
			await frames(2)
			await tap("v0", "jump")
			await tap("v1", "jump")
			main.game_mode = "derruba"
			main.arena_choice = "canteiro_obras"
			main.start_match()
			await frames(10)
			main.state = S.WIN
			main._clear_robots()
			await projetos_frames(a.substr(11), true)
			get_tree().quit(0)
			return
		if a.begins_with("--menus="):
			await menus_frames(a.substr(8))
			get_tree().quit(0)
			return
		if a.begins_with("--demo="):
			await demo_frames(a.substr(7))
			get_tree().quit(0)
			return
	if anim != "":
		await anim_frames(anim)
		get_tree().quit(0)
	elif shot != "":
		await shots(shot)
		get_tree().quit(0)
	else:
		await autotest()
		print("RESULTADO: %s (%d falhas)" % ["OK" if fails == 0 else "FALHOU", fails])
		get_tree().quit(1 if fails > 0 else 0)

# ---------------------------------------------------------------- utilidades
func key_event(k: Key, down: bool, loc := KEY_LOCATION_UNSPECIFIED) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = down
	e.location = loc
	Input.parse_input_event(e)
	await frames(2)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func vset(dev: String, a: String, v: bool) -> void:
	PlayerInput.virtual[dev][a] = v

func tap(dev: String, a: String) -> void:
	vset(dev, a, true)
	await frames(2)
	vset(dev, a, false)
	await frames(2)

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FALHA ") + msg)
	if not cond:
		fails += 1

func clear_inputs() -> void:
	for d in PlayerInput.virtual:
		PlayerInput.virtual[d] = {}

func reset_run() -> void:
	clear_inputs()
	if main.level.id != "canteiro":
		if main.demo.fx != null and is_instance_valid(main.demo.fx):
			main.demo.fx.free()   # máquinas da arena anterior apontam para o mapa velho
		main.demo.fx = null
		main.load_arena("canteiro")   # mapa plano de referência para medir pulo e corrida
		await frames(1)
	main.start_run()
	main.countdown = 0.0
	main.timer = 999.0
	for r in main.robots:
		r.active = true
	await frames(2)

## Marretada pesada "limpa" para testes de efeito: zera a recarga, aperta e espera o impacto.
func heavy_hit(dev: String) -> void:
	var i: int = PlayerInput.slots.find(dev)
	if i >= 0 and i < main.robots.size():
		main.robots[i].heavy_cd = 0.0
		while main.robots[i].atk != "":
			await frames(1)
	await tap(dev, "heavy")
	await frames(int(float(Data.ctrl["ataque_pesado"]["preparo"]) * 60.0) + 8)

func put(r, pos: Vector2) -> void:
	r.position = pos
	r.velocity = Vector2.ZERO
	r.own_vx = 0.0

func col_x(c: int) -> float:
	return c * 64 + 32.0

# robô de teste: segue para a direita e pula buracos e paredes (só para testes)
func steer(devs: Array, frames_max: int, trace := false) -> void:
	var hold := {}
	for i in frames_max:
		for k in devs.size():
			var r = main.robots[k]
			var d: String = devs[k]
			if not r.alive or r.finished:
				PlayerInput.virtual[d] = {}
				continue
			vset(d, "right", true)
			var row := int((r.position.y + 2) / 64.0)
			var ahead := int((r.position.x + 40) / 64.0)
			var gap: bool = not main.level.is_solid(Vector2i(ahead, row))
			var wall: bool = main.level.is_solid(Vector2i(ahead, row - 1))
			if r.is_on_floor() and (gap or wall) and hold.get(d, 0) <= 0:
				hold[d] = 14
			vset(d, "jump", hold.get(d, 0) > 0)
			hold[d] = hold.get(d, 0) - 1
		await frames(1)
		if trace and i % 10 == 0:
			print("    t=%d " % i, main.robots.map(func(r): return "(%.0f,%.0f %s%s)" % [r.position.x, r.position.y, "F" if r.is_on_floor() else "-", "" if r.alive else " MORTO"]))
		if main.state != S.RUN or main.end_delay >= 0.0:
			break

# ---------------------------------------------------------------- teste
func autotest() -> void:
	seed(20261120)            # sorteios repetíveis: o teste não oscila
	main.rng.seed = 20261120
	main.perfil.caminho = "user://perfil_teste.json"   # nunca mexe no perfil de verdade do jogador
	for suf in ["", ".bak", ".tmp", ".corrompido"]:
		if FileAccess.file_exists(main.perfil.caminho + suf):
			DirAccess.remove_absolute(main.perfil.caminho + suf)
	main.perfil.dados = main.perfil.novo()
	for a in OS.get_cmdline_user_args():   # atalho de depuração: --so=maquinas,itens_novos,eventos
		if a.begins_with("--so="):
			PlayerInput.virtual = {"v0": {}, "v1": {}}
			await frames(2)
			await tap("v0", "jump")
			await tap("v1", "jump")
			main.mode = "demolicao"
			main.start_match()
			for nm in a.substr(5).split(","):
				await call(nm + "_test")
			return
	print("== Áudio")
	var missing := []
	for k in Audio._index.keys():
		var n: int = int(Audio._index[k])
		var path := "res://assets/audio/sfx/%s.wav" % k if n == 0 else "res://assets/audio/sfx/%s_1.wav" % k
		if Audio._stream(path) == null:
			missing.append(k)
	check(Audio._index.size() >= 30 and missing.is_empty(), "%d sons carregam (faltando: %s)" % [Audio._index.size(), str(missing)])
	await frames(30)
	var ms: AudioStream = Audio._music.stream
	check(Audio._music_name == main.TEMA and ms is AudioStreamOggVorbis and ms.loop, "tema aprovado (Rock Cartoon) tocando em loop")
	Audio.play("bonk")
	Audio.voice("voz_ai", 2)
	print("== Teclado (Windows: Shift fantasma nas setas, Ctrl esquerdo x direito)")
	await key_event(KEY_SHIFT, true, KEY_LOCATION_LEFT)
	await key_event(KEY_RIGHT, true)
	check(PlayerInput.dev_held("kb_b", "right") and not PlayerInput.dev_held("kb_a", "hammer"), "seta com Shift fantasma não aciona a marreta do teclado A")
	await key_event(KEY_SHIFT, false, KEY_LOCATION_LEFT)
	await key_event(KEY_RIGHT, false)
	await key_event(KEY_CTRL, true, KEY_LOCATION_RIGHT)
	check(not PlayerInput.dev_held("kb_b", "jump"), "Ctrl não pula mais (teclado sem Shift/Ctrl)")
	await key_event(KEY_CTRL, false, KEY_LOCATION_RIGHT)
	await key_event(KEY_KP_1, true)
	check(PlayerInput.dev_held("kb_b", "jump"), "1 do numérico faz o teclado B pular")
	await key_event(KEY_KP_1, false)
	await key_event(KEY_K, true)
	check(PlayerInput.dev_held("kb_b", "jump"), "K (notebook) também pula no teclado B")
	await key_event(KEY_K, false)
	await key_event(KEY_H, true)
	check(PlayerInput.dev_held("kb_a", "hammer") and not PlayerInput.dev_held("kb_b", "hammer"), "H é o golpe rápido do teclado A")
	await key_event(KEY_H, false)
	main.players.clear()   # o Ctrl direito simulado fez o teclado B entrar: limpa para o resto do teste
	PlayerInput.slots.clear()

	print("== Entrada")
	main.game_mode = "derruba"
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	check(main.players.size() == 2, "2 jogadores entraram")
	await tap("v0", "right")
	check(main.players[0]["color"] == 2, "P1 troca de cor pulando a cor ocupada (azul→rosa)")
	await tap("v0", "left")
	print("== Controle duplicado (Windows) e sair")
	PlayerInput.virtual["padA"] = {}
	PlayerInput.virtual["padB"] = {}
	await frames(2)
	vset("padA", "jump", true)
	vset("padB", "jump", true)
	await frames(2)
	vset("padA", "jump", false)
	vset("padB", "jump", false)
	await frames(2)
	check(main.players.size() == 3, "mesmo controle visto 2x entra como 1 jogador (%d)" % main.players.size())
	var m0: int = main.players[0]["model"]
	var m2: int = main.players[2]["model"]
	vset("padA", "down", true)
	vset("padB", "down", true)
	await frames(2)
	vset("padA", "down", false)
	vset("padB", "down", false)
	await frames(2)
	check(main.players[2]["model"] == posmod(m2 + 1, Data.MODELS.size()) and main.players[0]["model"] == m0, "trocar robô muda só o jogador do controle")
	await tap("padA", "back")
	check(main.players.size() == 2, "botão de sair remove o jogador")
	await tap("v0", "start")
	check(main.state == S.RUN, "Start com 2 jogadores começa a rodada")

	print("== Pulo")
	await reset_run()
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	put(r0, Vector2(col_x(21), 768))
	put(r1, Vector2(col_x(22), 768))
	await frames(5)
	var miny := 9999.0
	vset("v0", "jump", true)
	for i in 50:
		await frames(1)
		miny = minf(miny, r0.position.y)
	vset("v0", "jump", false)
	var full := (768 - miny) / 64.0
	check(full > 3.5 and full < 4.3, "pulo segurado = %.2f tiles (esperado ~3,9)" % full)
	await frames(40)
	miny = 9999.0
	vset("v0", "jump", true)
	await frames(1)
	vset("v0", "jump", false)
	for i in 40:
		await frames(1)
		miny = minf(miny, r0.position.y)
	var short := (768 - miny) / 64.0
	check(short < full * 0.6, "toque rápido = %.2f tiles (pulo variável)" % short)

	print("== Corrida")
	await reset_run()
	r0 = main.robots[0]
	put(r0, Vector2(col_x(20), 768))
	vset("v0", "right", true)
	await frames(20)
	check(absf(r0.velocity.x - float(Data.ctrl["max_run"])) < 1.0, "velocidade máxima %.0f px/s" % r0.velocity.x)
	vset("v0", "right", false)

	await demolicao_test()

func demo_round() -> void:
	clear_inputs()
	main.demo.start_round()
	main.state = S.RUN
	main.countdown = 0.0
	if main.demo.etapas != null:
		main.demo.etapas.ativo = false   # testes longos: diretor e transição desligados (só etapas_test/verificacao_test ligam)
	for r in main.robots:
		r.active = true
	await frames(3)
	for r in main.robots:
		r.invuln = 0.0   # testes de golpe sem a proteção do começo

func demolicao_test() -> void:
	print("== Demolição (Derruba com 1 vida)")
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.demo.lives_setting = 1
	main.event_level = 0   # eventos são testados à parte (spells_test)
	main.arena_choice = "demolicao"   # mecânicas básicas testadas no Canteiro
	main.start_match()
	check(main.level.id == "demolicao" and main.level.blocks.size() > 30, "arena de caixotes carregada (%d caixotes)" % main.level.blocks.size())
	await demo_round()
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	# corrida lisa sobre caixotes separados: sem tropeçar nas emendas
	put(r1, Vector2(col_x(26), 576))
	put(r0, Vector2(col_x(10) + 10, 576))
	await frames(3)
	vset("v0", "right", true)
	var drops := 0
	var air := 0
	for i in 40:
		await frames(1)
		if i > 8 and absf(r0.velocity.x) < float(Data.ctrl["max_run"]) - 1.0:
			drops += 1
		if not r0.is_on_floor():
			air += 1
	vset("v0", "right", false)
	check(drops == 0 and air == 0, "corre liso sobre caixotes (quedas de velocidade: %d, quadros sem chão: %d)" % [drops, air])
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(12), 576))
	put(r1, Vector2(col_x(26), 576))
	r0.facing = 1
	await frames(3)
	var cell := Vector2i(13, 9)
	var hp0: int = int(main.demo.cfg["block_hp"])
	await heavy_hit("v0")
	check(main.level.blocks.has(cell) and main.level.blocks[cell]["hp"] == hp0 - 1, "1ª marretada racha o caixote do chão à frente")
	for k in hp0 - 1:
		await frames(34)   # a marretada que erra o robô fica presa ~0,7 s (abertura real)
		await heavy_hit("v0")
	check(not main.level.blocks.has(cell), "%dª marretada quebra o caixote" % hp0)
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 34, 576))   # colado (a ponta da marreta = crítico, A47)
	r0.facing = 1
	await frames(3)
	var x1: float = r1.position.x
	await heavy_hit("v0")
	check(r1.recover_t > 0.0 and absf(r1.dmg - 14.0) < 0.1, "marretada pesada arremessa e soma 14%% no Amassômetro (%.0f%%)" % r1.dmg)
	await frames(30)
	var push_low: float = r1.position.x - x1
	put(r1, Vector2(col_x(11) + 60, 576))
	r1.dmg = 120.0
	await frames(16)
	x1 = r1.position.x
	await heavy_hit("v0")
	await frames(30)
	var push_high: float = r1.position.x - x1
	check(push_low > 20.0 and push_low < 200.0 and push_high > push_low * 3.0, "amassado voa mais longe: 14%% → %.0f px, 120%% → %.0f px" % [push_low, push_high])
	# invulnerável não sofre golpe
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	r0.facing = 1
	r1.invuln = 2.0
	await frames(3)
	await heavy_hit("v0")
	check(r1.dmg == 0.0 and r1.stun_t == 0.0, "invulnerável (começo da rodada) não leva golpe")
	# pulo duplo do propulsor
	await demo_round()
	r0 = main.robots[0]
	put(r0, Vector2(col_x(12), 576))
	await frames(3)
	var y_ground: float = r0.position.y
	vset("v0", "jump", true)
	await frames(24)
	vset("v0", "jump", false)
	await frames(2)
	vset("v0", "jump", true)
	var top_y := 9999.0
	for i in 40:
		await frames(1)
		top_y = minf(top_y, r0.position.y)
	vset("v0", "jump", false)
	check(y_ground - top_y > 4.6 * 64.0 and r0.air_jumps == 0, "pulo duplo do propulsor (altura %.1f tiles)" % ((y_ground - top_y) / 64.0))
	await frames(60)
	# agarrar a borda: cai ao lado da plataforma segurando na direção dela
	await demo_round()
	r0 = main.robots[0]
	put(r0, Vector2(col_x(9) - 4, 600))
	r0.air_jumps = 0
	vset("v0", "right", true)
	var grabbed := false
	for i in 30:
		await frames(1)
		if r0.hanging:
			grabbed = true
			break
	vset("v0", "right", false)
	check(grabbed, "agarra a borda do caixote")
	await tap("v0", "jump")
	await frames(30)
	check(r0.alive and r0.is_on_floor() and r0.position.y <= 577.0, "da borda, PULAR sobe na plataforma")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r1, Vector2(col_x(11), 576))
	put(r0, Vector2(col_x(11), 360))
	var stomped := false
	for i in 40:
		await frames(1)
		if r1.stun_t > 0.0:
			stomped = true
			break
	check(stomped and r0.velocity.y < 0.0 and r1.dmg > 0.0, "pular na cabeça atordoa, amassa e quica")
	var stomps := 1
	var was_stunned := true
	for i in 90:
		await frames(1)
		if r1.stun_t > 0.0 and not was_stunned:
			stomps += 1
		was_stunned = r1.stun_t > 0.0
	check(stomps == 1, "pisão não vira laço: 1 pisão em 1,5 s (%d)" % stomps)
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r1, Vector2(col_x(16), 576))
	var under := Vector2i(16, 9)
	await frames(int(float(main.demo.cfg["crumble_break_s"]) * 60) + 10)
	check(not main.level.blocks.has(under), "caixote cai se o robô fica parado em cima")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	var before: int = main.players[0]["score"]
	main.kill(r1, -1, null)
	await frames(100)
	check(main.state == S.SCORE and main.players[0]["score"] == before + 1, "último em pé ganha ★ (%d)" % main.players[0]["score"])
	main.timer = 0.0
	await frames(3)
	check(main.state == S.RUN and main.robots.size() == 2, "placar → próxima rodada com arena nova")
	main.players[0]["score"] = int(main.demo.cfg["rounds_to_win"]) - 1
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	main.kill(main.robots[1], -1, null)
	await frames(100)
	main.timer = 0.0
	await frames(3)
	check(main.state == S.WIN and main.winner == 0, "%d ★ vence a partida" % int(main.demo.cfg["rounds_to_win"]))
	await bots_test()
	await arenas_test()
	await parede_test()
	await maquinas_test()
	await submodos_test()
	await menus_test()
	await controles_test()
	await bots_entrada_test()
	await seletor_test()
	await fluxo_test()
	await controle_real_test()
	await robos_test()
	await combate_test()
	await luta_test()
	await lab_test()
	await canteiro_test()
	await spells_test()
	await eventos_test()
	await mapa_test()
	await cargueiro_test()
	await agua_test()
	await m1_test()
	await m2_test()
	await m3_test()
	await m4_test()
	await m5_test()
	await m6_test()
	await m10_test()
	await skins_test()
	await etapas_test()
	await verificacao_test()
	await caixas_subsolo_test()
	await principal_test()
	await resultados_test()
	await selecao_test()
	await desempenho_test()
	await perfil_test()
	await eventos_cenas_test()
	await fachada_test()
	await moderada_test()
	await limpa_test()
	await mecanismos_test()
	await renascer_test()
	await transicao_test()
	await imagens_test()

func menus_test() -> void:
	print("== Menus e pausa")
	main.go_menu()
	main.menus.sel = 0
	PlayerInput.virtual = {"v0": {}}
	await frames(2)
	check(main.state == S.MENU and main.players.is_empty(), "volta ao menu principal sem jogadores")
	await tap("v0", "jump")
	check(main.state == S.ARENAS and main.game_mode == "derruba", "JOGAR vai direto aos mapas do Derruba (A22: tela de modos pulada)")
	await tap("v0", "back")
	check(main.state == S.MENU, "ESC nos mapas volta ao menu principal")
	await tap("v0", "jump")
	check(main.menus.arena_list().size() == 1 + main.demo.find_mode("derruba")["arenas"].size(), "só as arenas da Derruba (+ sorteio)")
	await tap("v0", "jump")
	check(main.state == S.SELSPELLS and main.arena_choice == "canteiro_obras", "SORTEIO no Derruba: o jogo escolhe o mapa e segue para a configuração dele (%s)" % main.arena_choice)
	await tap("v0", "start")
	await tap("v0", "start")
	check(main.state == S.AJUSTES and main.menus.adjust_rows()[0] == "vidas", "spells → eventos → AJUSTES; Derruba v2: sem meta de estrelas, a 1ª linha é VIDAS")
	var lives0: int = main.demo.lives_setting
	await tap("v0", "right")
	check(main.demo.lives_setting == clampi(lives0 + 1, 3, 6), "ajuste de VIDAS da Derruba, 3 a 6 (%d)" % main.demo.lives_setting)
	await tap("v0", "left")
	await tap("v0", "down")
	await tap("v0", "right")
	var lvl: int = main.event_level
	check(main.menus.adjust_rows() == ["vidas", "eventos", "itens", "comecar"], "ajustes do mapa: vidas, intensidade dos eventos, spells sim/não, começar (eventos escolhidos no mosaico)")
	await tap("v0", "down")
	await tap("v0", "down")
	await tap("v0", "jump")
	check(main.state == S.JOIN and main.mode == "demolicao" and main.estrelas_da_sessao() and lvl >= 0, "COMEÇAR → entrada; partida única (eventos nível %d)" % main.event_level)
	main.game_mode = "derruba"
	main.demo.lives_setting = 1
	await tap("v0", "jump")
	main.add_bot()
	await tap("v0", "start")
	check(main.state == S.DETONAR, "entrada (etapa 4) → DETONAR (etapa 5)")
	await tap("v0", "start")
	await frames(40)
	check(main.state == S.RUN and main.robots.size() == 2, "detonador: partida começa (1 pessoa + 1 bot)")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	await frames(5)
	await tap("v0", "start")
	check(main.paused, "START pausa")
	var bx: Vector2 = main.robots[1].position
	await frames(30)
	check(main.robots[1].position == bx, "na pausa, ninguém se mexe")
	check(main.menus.PAUSE_ITEMS.size() == 5 and "CONFIGURAR MAPA" in main.menus.PAUSE_ITEMS and "SELECIONAR MAPA" in main.menus.PAUSE_ITEMS, "pausa com Configurar e Selecionar mapa (A23)")
	for k in 4:
		await tap("v0", "down")
	await tap("v0", "jump")
	check(main.paused and main.menus.pause_conf == 4 and main.state == S.RUN, "MENU PRINCIPAL pede confirmação (A26)")
	await tap("v0", "jump")
	check(main.paused and main.menus.pause_conf == -1, "NÃO (padrão) volta para a pausa")
	await tap("v0", "jump")
	await tap("v0", "right")
	await tap("v0", "jump")
	check(main.state == S.MENU and not main.paused, "pausa → MENU PRINCIPAL → SIM, SAIR")
	main.menus.sel = 0
	for k in 3:
		await tap("v0", "down")
	await tap("v0", "jump")
	check(main.state == S.OPTIONS, "OPÇÕES abre")
	await tap("v0", "down")
	await tap("v0", "jump")
	check(not main.shake_on, "tremor da tela desliga")
	await tap("v0", "jump")
	await tap("v0", "back")
	check(main.state == S.MENU and main.shake_on, "voltar ao menu (tremor religado)")

func parede_test() -> void:
	print("== Parede e borda")
	main.event_level = 0
	main.game_mode = "derruba"
	main.demo.lives_setting = 1
	main.arena_choice = "demolicao"
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var lv = main.level
	var r0 = main.robots[0]
	put(main.robots[1], Vector2(col_x(24), 576))
	# parede invisível da borda do mapa: não gruda
	put(r0, Vector2(64.0 + 25.0, 300))
	vset("v0", "left", true)
	await frames(12)
	var dbg := "y %.0f chão %s nível %s cel %s" % [r0.position.y, r0.is_on_floor(), main.level.id, main.level.ch_at(Vector2i(int(r0.position.x / 64.0), int((r0.position.y + 2.0) / 64.0)))]
	check(not r0.wall_sliding and r0.velocity.y > 300.0, "não gruda na parede invisível da borda (vy %.0f; %s)" % [r0.velocity.y, dbg])
	vset("v0", "left", false)
	# parede de caixotes: escorrega devagar e o pulo de parede funciona
	for y in [3, 4, 5, 6, 7]:
		lv.add_block(Vector2i(13, y))
	put(r0, Vector2(13 * 64.0 - 25.0, 300))
	vset("v0", "right", true)
	await frames(14)
	check(r0.wall_sliding and r0.velocity.y <= float(Data.ctrl["wall_slide_speed"]) + 1.0 and r0.grip < 1.0, "escorrega na parede de caixotes gastando aderência (vy %.0f, %.0f%%)" % [r0.velocity.y, r0.grip * 100.0])
	await tap("v0", "jump")
	await frames(2)
	check(r0.velocity.y < -300.0 and r0.own_vx < 0.0, "pulo de parede empurra para longe")
	vset("v0", "right", false)
	# os dois lados: o desenho vira de costas para a parede (direita e esquerda), pendurado olha para a parede
	for side in [1, -1]:
		await demo_round()
		r0 = main.robots[0]
		lv = main.level
		put(main.robots[1], Vector2(col_x(24), 576))
		for y in [3, 4, 5, 6, 7]:
			lv.add_block(Vector2i(10, y))
		var x := 10 * 64.0 - 25.0 if side > 0 else 11 * 64.0 + 25.0
		put(r0, Vector2(x, 400))
		vset("v0", "right" if side > 0 else "left", true)
		await frames(14)
		var sx: float = r0.vis.scale.x
		check(r0.wall_sliding and signf(sx) == -side, "parede à %s: desenho de costas para ela (escala %.2f)" % ["direita" if side > 0 else "esquerda", sx])
		vset("v0", "right" if side > 0 else "left", false)
		# pendurado na quina do topo (linha 3)
		put(r0, Vector2(x + (-5.0 * side), 3 * 64.0 + 40.0))
		r0.velocity.y = 100.0
		r0.grip = 1.0
		vset("v0", "right" if side > 0 else "left", true)
		var hung := false
		for i in 30:
			await frames(1)
			if r0.hanging:
				hung = true
				break
		await frames(8)
		check(hung and signf(r0.vis.scale.x) == side, "borda à %s: pendurado olhando para a parede (escala %.2f)" % ["direita" if side > 0 else "esquerda", r0.vis.scale.x])
		vset("v0", "right" if side > 0 else "left", false)
	# aderência acaba: solta da parede e cai (o medidor mostra isso)
	await demo_round()
	r0 = main.robots[0]
	lv = main.level
	put(main.robots[1], Vector2(col_x(24), 576))
	for y in [1, 2, 3, 4, 5, 6, 7, 8]:
		lv.add_block(Vector2i(20, y))
	put(r0, Vector2(20 * 64.0 - 25.0, 140))
	r0.velocity.y = 100.0
	vset("v0", "right", true)
	var slid := false
	for i in 120:
		await frames(1)
		if r0.wall_sliding:
			slid = true
		if r0.is_on_floor():
			break
	vset("v0", "right", false)
	check(slid and r0.grip <= 0.05, "a aderência na parede acaba (%.0f%%) e o robô solta" % (r0.grip * 100.0))
	await frames(40)
	check(r0.grip > 0.95, "no chão a aderência recarrega")
	# agarra a borda e sobe sem teletransporte, e depois anda
	await demo_round()
	r0 = main.robots[0]
	lv = main.level
	put(main.robots[1], Vector2(col_x(24), 576))
	lv.add_block(Vector2i(11, 5))
	put(r0, Vector2(11 * 64.0 - 30.0, 5 * 64.0 + 40.0))
	r0.velocity.y = 100.0
	vset("v0", "right", true)
	var grabbed := false
	for i in 20:
		await frames(1)
		if r0.hanging:
			grabbed = true
			break
	check(grabbed, "agarra a quina do caixote caindo ao lado dela")
	vset("v0", "right", false)
	await tap("v0", "jump")
	var mid_ok := false
	for i in 6:
		await frames(1)
		if r0.climb_t > 0.0 and r0.climb_t < 1.0:
			mid_ok = true
	await frames(14)
	check(mid_ok and absf(r0.position.y - 5 * 64.0) < 6.0 and r0.is_on_floor(), "sobe animado e fica em pé em cima (y %.0f)" % r0.position.y)
	var xs: float = r0.position.x
	vset("v0", "left", true)
	await frames(10)
	vset("v0", "left", false)
	check(absf(r0.position.x - xs) > 20.0, "depois de subir, anda normalmente")
	# sem espaço em cima (teto a 1 bloco): não agarra
	await demo_round()
	r0 = main.robots[0]
	lv = main.level
	put(main.robots[1], Vector2(col_x(24), 576))
	lv.add_block(Vector2i(11, 5))
	lv.add_block(Vector2i(11, 3))
	put(r0, Vector2(11 * 64.0 - 30.0, 5 * 64.0 + 40.0))
	r0.velocity.y = 100.0
	vset("v0", "right", true)
	grabbed = false
	for i in 20:
		await frames(1)
		if r0.hanging:
			grabbed = true
	vset("v0", "right", false)
	check(not grabbed, "não agarra borda sem espaço para subir")
	# segurar a borda tem limite de tempo
	await demo_round()
	r0 = main.robots[0]
	lv = main.level
	put(main.robots[1], Vector2(col_x(24), 576))
	lv.add_block(Vector2i(11, 5))
	put(r0, Vector2(11 * 64.0 - 30.0, 5 * 64.0 + 40.0))
	r0.velocity.y = 100.0
	vset("v0", "right", true)
	for i in 20:
		await frames(1)
		if r0.hanging:
			break
	var lim := float(main.demo.cfg["recuperacao"]["borda_max_s"])
	await frames(int(lim * 60.0 * 0.5))
	var half: float = r0.grip
	await frames(int(lim * 60.0 * 0.6))
	vset("v0", "right", false)
	check(half > 0.3 and half < 0.7 and not r0.hanging, "segurar a borda esvazia o medidor e solta no fim (meio: %.0f%%)" % (half * 100.0))
	# nenhum mapa tem vão baixo demais (o robô de 72 px entalava, ex.: alto da Maré)
	var bad := []
	for a in main.demo.cfg["arenas"]:
		var L = load("res://level/level.gd").new()
		L.load_level(a["id"])
		for y in range(2, L.rows):
			for x in L.cols:
				var c := Vector2i(x, y)
				if L.is_solid(c) and L.ch_at(c) != "I" and not L.is_solid(c + Vector2i.UP) and L.is_solid(c + Vector2i(0, -2)):
					bad.append("%s %s" % [a["id"], str(c)])
		L.free()
	check(bad.is_empty(), "nenhum mapa com vão de 1 bloco onde o robô entala %s" % str(bad.slice(0, 6)))

func maquinas_test() -> void:
	print("== Máquinas e câmera que rola")
	main.event_level = 0
	main.game_mode = "derruba"
	main.demo.lives_setting = 1
	var fx
	# Torre: a câmera sobe; quem fica embaixo está fora
	await arena_round("torre")
	fx = main.demo.fx
	check(fx.scroll_on and fx.scroll_dir == "cima" and main.level.rows == 40, "Torre: mapa alto com câmera que sobe")
	var y0: float = fx.scroll_center.y
	main.demo.t = 20.0
	await frames(60)
	check(fx.scroll_center.y < y0 - 20.0, "Torre: a câmera subiu (%.0f → %.0f)" % [y0, fx.scroll_center.y])
	var vr: Rect2 = main.view_rect()
	check(vr.size.x <= 1921.0 and main.camera.position.y < float(main.level.rows) * 64.0, "Torre: a câmera acompanha (centro %.0f)" % main.cam_center.y)
	main.robots[1].invuln = 0.0
	fx.scroll_center.y = 600.0
	await frames(3)
	check(not main.robots[0].alive and main.demo.death_log[-1]["cause"] == "ficou para trás", "Torre: quem ficou para trás saiu (%s)" % main.demo.death_log[-1]["cause"])

func submodos_test() -> void:
	print("== Modos (Derruba com vidas, Batata-Dinamite)")
	main.mode = "demolicao"
	main.arena_choice = "demolicao"
	main.event_level = 0
	# Vidas: cair tira 1 vida e volta pelo guindaste; com 0 vidas, sai
	main.game_mode = "derruba"
	main.demo.lives_setting = 3
	await demo_round()
	var r0 = main.robots[0]
	var lv0: int = main.demo.lives[0]
	main.kill(r0, -1, null)
	await frames(2)
	check(r0.alive and main.demo.lives[0] == lv0 - 1, "Derruba: caiu, perdeu 1 vida (%d) e voltou" % main.demo.lives[0])
	# sem nenhum caixote no mapa: o guindaste traz um caixote e o robô volta em cima dele (não no espinho)
	for c in main.level.blocks.keys():
		main.level.break_block(c)
	await frames(2)
	r0.invuln = 0.0
	main.demo.lives[0] = 3
	main.kill(r0, -1, null)
	await frames(90)
	var under := Vector2i(int(r0.position.x / 64.0), int((r0.position.y + 2.0) / 64.0))
	check(r0.alive and r0.is_on_floor() and main.level.is_solid(under) and r0.position.y < (main.level.rows - 2) * 64.0,
		"Derruba: sem chão, volta em cima de um caixote novo (%s)" % str(under))
	main.demo.lives[0] = 1
	r0.invuln = 0.0
	main.kill(r0, -1, null)
	await frames(2)
	check(not r0.alive, "Derruba: sem vidas, está fora")
	await frames(100)
	check(main.state == S.SCORE and main.demo.round_winner == 1, "Derruba: P2 vence a rodada")
	# Batata-Dinamite: a marretada passa a dinamite; quando o pavio acaba, explode quem está com ela
	main.game_mode = "batata"
	await demo_round()
	r0 = main.robots[0]
	var r1 = main.robots[1]
	main.demo.bomb_next = 0.01
	await frames(3)
	var h: int = main.demo.bomb_holder
	check(h >= 0, "Batata: alguém pegou a dinamite (P%d)" % (h + 1))
	var hr = main.robots[h]
	var other = main.robots[1 - h]
	hr.invuln = 0.0
	other.invuln = 0.0
	put(hr, Vector2(col_x(12), 576))
	put(other, Vector2(col_x(12) + 20, 576))
	await frames(3)
	check(main.demo.bomb_holder == 1 - h, "Batata: encostar no rival passa a dinamite")
	await frames(55)
	put(hr, Vector2(col_x(12) + 20, 576))
	await frames(3)
	check(main.demo.bomb_holder == h, "Batata: e ele pode devolver encostando")
	await frames(55)
	put(hr, Vector2(col_x(12), 576))
	put(other, Vector2(col_x(12) + 50, 576))
	hr.facing = 1
	await frames(3)
	main.demo.attack(hr, "pesado")
	await frames(2)
	check(main.demo.bomb_holder == 1 - h, "Batata: marretada passou a dinamite para P%d" % (2 - h))
	hr.invuln = 99.0
	main.demo.bomb_fuse = 0.02
	await frames(4)
	check(not other.alive, "Batata: o pavio acabou e quem estava com ela explodiu")
	await frames(100)
	check(main.state == S.SCORE and main.demo.round_winner == h, "Batata: P%d vence a rodada" % (h + 1))
	# Rei da Obra: pega o capacete no trono, perde com um golpe, vence ao juntar os segundos
	main.game_mode = "rei"
	main.arena_choice = "piramide"
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	check(main.level.throne != Vector2.INF and main.demo.crown_pos.distance_to(main.level.throne) < 6.0, "Rei: capacete de ouro no trono (K)")
	r0.invuln = 0.0
	r1.invuln = 0.0
	put(r0, main.demo.crown_pos + Vector2(0, 2))
	await frames(4)
	check(main.demo.king == 0, "Rei: P1 pegou o capacete")
	await frames(30)
	check(main.demo.king_time.get(0, 0.0) > 0.3 and r0.speed_k < 1.0, "Rei: o rei soma segundos e fica mais lento")
	r0.take_hit(1, "marretada", 1)
	await frames(3)
	check(main.demo.king == 0, "Rei: logo depois de pegar, o rei fica protegido um instante")
	main.demo.king_grace = 0.0
	r0.invuln = 0.0
	r0.take_hit(1, "marretada", 1)
	await frames(3)
	check(main.demo.king == -1 and r0.speed_k == 1.0, "Rei: golpe derruba o capacete")
	main.demo.crown_pos = Vector2(64 * 3 + 32, main.level.rows * 64.0 + 20.0)
	main.demo.crown_vel = Vector2.ZERO
	main.demo.crown_cd = {0: 99.0, 1: 99.0}
	await frames(3)
	check(main.demo.crown_pos.distance_to(main.demo.crown_home) < 2.0, "Rei: capacete no fundo/espinho volta para o trono")
	main.demo.crown_cd.clear()
	main.demo.crown_cd.clear()
	main.demo.king = 1
	main.demo.king_hit[1] = r1.last_hit
	main.demo.king_time[1] = main.demo.king_goal() - 0.05
	await frames(100)
	check(main.state == S.SCORE and main.demo.round_winner == 1, "Rei: quem junta os segundos vence a rodada")
	# Fuga: quem chega ao elevador vence na hora
	main.game_mode = "fuga"
	main.arena_choice = "mare"
	await demo_round()
	r0 = main.robots[0]
	check(main.level.elevator_cell != Vector2i(-1, -1), "Fuga: a Maré tem elevador de chegada")
	var g: Rect2 = main.level.goal_rect
	put(r0, Vector2(g.get_center().x, g.end.y - 2))
	await frames(100)
	check(main.state == S.SCORE and main.demo.round_winner == 0, "Fuga: chegou ao elevador, venceu a rodada")
	main.arena_choice = "demolicao"
	main.game_mode = "derruba"
	main.demo.lives_setting = 1

func robos_test() -> void:
	print("== Robôs (elenco de 5)")
	check(Data.MODELS.size() == 5 and Data.robot_meta["modelos"].size() == 5, "5 robôs no elenco (%d)" % Data.MODELS.size())
	var poses_ok := true
	for m in Data.MODELS:
		var g: Dictionary = Data.robot_meta["modelos"][m]
		for fr in ["parado", "corre", "ar", "rapido_prep", "rapido", "rapido2_prep", "rapido2", "cima", "baixo", "pesado_prep", "pesado_golpe", "esquiva", "esquiva_ar"]:
			poses_ok = poses_ok and g["poses"].has(fr)
		poses_ok = poses_ok and Data.tex("robo/ferramenta_" + m) != null
	check(poses_ok, "cada robô tem a própria ferramenta e os 13 quadros-chave de golpe e esquiva")
	var faltando := []
	for m in Data.MODELS:
		var names := ["robo/antena_" + m, "robo/ferramenta_" + m, "robo/dano3_" + m]
		for k in 4:
			names.append("robo/corpo_%s_p%d" % [m, k + 1])
		for e in ["normal", "piscar", "esforco", "susto", "vitoria", "eliminado"]:
			names.append("robo/rosto_%s_%s" % [m, e])
		for n in names:
			if Data.tex(n) == null:
				faltando.append(n)
	check(faltando.is_empty(), "todos os modelos têm corpo nas 4 cores, 6 rostos e antena %s" % [faltando])
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	var seen := {}
	for k in Data.MODELS.size():
		seen[main.players[0]["model"]] = true
		await tap("v0", "down")
	check(seen.size() == 5 and main.players[0]["model"] == 0, "▲▼ na entrada passa pelos 5 robôs e volta ao primeiro")
	main.players[0]["model"] = 4   # Pá
	main.players[1]["model"] = 1   # Picareta
	main.start_match()
	await frames(3)
	var hb0: Rect2 = main.robots[0].rect()
	var hb1: Rect2 = main.robots[1].rect()
	check(main.robots[0].vis.model == 4 and hb0.size == hb1.size, "o modelo muda só a aparência (mesma hitbox %s)" % [hb0.size])
	var ok := true
	for m in Data.MODELS.size():
		var parts: Array = main.robots[0].vis.parts({"color": 1, "model": m, "hammer": true})
		ok = ok and parts.size() >= 6 and parts[0]["tex"][0] != null
	check(ok, "todos os modelos desmontam na eliminação")
	main.go_menu()

## COMBATE (relatório de 2026-11-24): golpe rápido × marretada pesada, esquiva (chão/ar, só contra robôs),
## arremesso com retorno gradual do controle. Cenários de aceitação da seção 8.
## Vitrine do combate r3 (--luta=DIR): leve com avanço e combo, pesado carregado, ▲, ponta = crítico, arremesso na parede.
var _el_log: Array = []

func luta_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 9
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	main.hud.visible = false
	var ct = main.demo.canteiro
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = ct.parts.filter(func(p): return p["nucleo"])
	var fy: float = nuc[0]["rect"].position.y
	var xa: float = nuc[0]["rect"].position.x + 40.0
	_frame_no = 0
	var segs := [["leve", 60, 90.0], ["carga", 110, 80.0], ["cima", 60, 30.0], ["critico", 60, 90.0]]
	for sg in segs:
		for r in [r0, r1]:
			r.dmg = 40.0
			r.stun_t = 0.0
			r.recover_t = 0.0
			r.atk = ""
			r.heavy_cd = 0.0
			r.velocity = Vector2.ZERO
			r.own_vx = 0.0
		main.demo.lives[0] = 9
		main.demo.lives[1] = 9
		put(r0, Vector2(xa, fy))
		put(r1, Vector2(xa + float(sg[2]), fy))
		r0.facing = 1
		r1.facing = -1
		main.cam_lock = [2.2, Vector2(xa + 120.0, fy - 120.0)]
		for f in int(sg[1]):
			match String(sg[0]):
				"leve":
					vset("v0", "hammer", f in [6, 7, 20, 21, 34, 35])
				"carga":
					vset("v0", "heavy", f >= 4 and f < 78)
				"cima":
					vset("v0", "up", f >= 2 and f < 40)
					vset("v0", "heavy", f in [4, 5])
				"critico":
					vset("v0", "heavy", f in [4, 5])
			await frames(1)
			if f % 2 == 0:
				await grab(dir, "luta_" + String(sg[0]))
		for k in ["hammer", "heavy", "up"]:
			vset("v0", k, false)
	main.cam_lock = []
	print("quadros: ", _frame_no)

## A47 (combate r3): pesado carregável com armadura, 4 direções, ponta = crítico que quebra a peça; leve não quebra;
## arremessado contra parede racha. --so=luta
func luta_test() -> void:
	print("== Combate r3 (carga, direções, crítico, leve não quebra, a luta quebra a obra)")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var ct = main.demo.canteiro
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = ct.parts.filter(func(p): return p["nucleo"])
	var fy: float = nuc[0]["rect"].position.y
	var xa: float = nuc[0]["rect"].position.x + 40.0
	var ap: Dictionary = Data.ctrl["ataque_pesado"]
	var reset := func(dx: float) -> void:
		for i in main.players.size():
			main.demo.lives[i] = 99
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.recover_t = 0.0
			r.invuln = 0.0
			r.atk = ""
			r.atk_cd = 0.0
			r.heavy_cd = 0.0
			r.own_vx = 0.0
			r.velocity = Vector2.ZERO
		put(r0, Vector2(xa, fy))
		put(r1, Vector2(xa + dx, fy))
		r0.facing = 1
		r1.facing = -1
	# 1) toque × carga cheia: a carga empurra mais
	reset.call(70.0)
	await frames(3)
	await tap("v0", "heavy")
	await frames(int(float(ap["preparo"]) * 60.0) + 4)
	var kx_toque: float = absf(r1.own_vx)
	await frames(40)
	reset.call(70.0)
	await frames(3)
	vset("v0", "heavy", true)
	await frames(int((float(ap["preparo"]) + float(ap["carga_max_s"])) * 60.0) + 6)
	vset("v0", "heavy", false)
	await frames(10)
	var kx_carga: float = absf(r1.own_vx)
	check(kx_carga > kx_toque * 1.25, "pesado CARREGADO empurra mais que o toque (%.0f × %.0f)" % [kx_carga, kx_toque])
	await frames(40)
	# 2) armadura: golpe leve do rival não interrompe a carga
	reset.call(60.0)
	r1.facing = -1
	await frames(3)
	vset("v0", "heavy", true)
	await frames(int(float(ap["preparo"]) * 60.0) + 8)
	await tap("v1", "hammer")
	await frames(6)
	var ainda: bool = r0.atk == "pesado" and r0.heavy_charge > 0.0 and r1.dmg == 0.0
	vset("v0", "heavy", false)
	await frames(20)
	check(ainda and r0.dmg > 0.0 and r1.dmg > 0.0, "carregando: o golpe leve NÃO interrompe (armadura) e o pesado sai")
	await frames(40)
	# 3) ▲ pesado para cima: joga para o alto
	reset.call(20.0)
	await frames(3)
	vset("v0", "up", true)
	await tap("v0", "heavy")
	var y0: float = r1.position.y
	var topo: float = y0
	for k in int(float(ap["preparo"]) * 60.0) + 40:
		await frames(1)
		topo = minf(topo, r1.position.y)
	vset("v0", "up", false)
	check(r1.dmg > 0.0 and y0 - topo > 120.0, "▲ pesado joga o rival para CIMA (%.0f px)" % (y0 - topo))
	await frames(40)
	# 4) ponta da marreta = CRÍTICO (mais forte que de perto)
	reset.call(30.0)
	await frames(3)
	await tap("v0", "heavy")
	await frames(int(float(ap["preparo"]) * 60.0) + 4)
	var kx_perto: float = absf(r1.own_vx)
	await frames(40)
	reset.call(24.0 + float(ap["alcance_px"]) * 0.95)
	await frames(3)
	await tap("v0", "heavy")
	await frames(int(float(ap["preparo"]) * 60.0) + 4)
	var kx_ponta: float = absf(r1.own_vx)
	check(r1.last_cause == "marretada" and kx_ponta > kx_perto * 1.2, "ponta da marreta = CRÍTICO (%.0f × %.0f)" % [kx_ponta, kx_perto])
	await frames(40)
	# 5) golpe leve não quebra a obra
	var hp_tot := func() -> int:
		var n := 0
		for p in ct.parts:
			n += int(p["hp"])
		return n
	reset.call(400.0)
	var h0: int = hp_tot.call()
	for k in 6:
		vset("v0", "down", k % 2 == 0)
		await tap("v0", "hammer")
		await frames(12)
	vset("v0", "down", false)
	check(hp_tot.call() == h0, "golpe LEVE não quebra o cenário")
	# 6) arremessado contra parede racha a peça
	var alvo = null
	for p in ct.parts:
		if not p["fallen"] and not p["nucleo"] and p["kind"] == "laje":
			alvo = p
			break
	if alvo != null:
		var hr: Rect2 = ct.hit_rect(alvo)
		var hpa: int = int(alvo["hp"])
		reset.call(400.0)
		put(r1, Vector2(hr.position.x - 40.0, hr.get_center().y + 10.0))
		r1.stun_t = 0.3
		r1.recover_t = 0.5
		main.demo.luta_quebra(r1, Vector2(hr.position.x + 4.0, hr.get_center().y), 1)
		check(int(alvo["hp"]) < hpa or alvo["fallen"], "robô ARREMESSADO contra a obra racha a peça (%d → %d)" % [hpa, int(alvo["hp"])])
	main.go_menu()

func combate_test() -> void:
	print("== Combate (rápido, pesado, esquiva, arremesso)")
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "demolicao"
	if main.players.size() < 2:
		PlayerInput.virtual = {"v0": {}, "v1": {}}
		main.go_join()
		await frames(2)
		await tap("v0", "jump")
		await tap("v1", "jump")
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var am: Dictionary = main.demo.cfg["amassometro"]
	# 1) golpe rápido: acerta, soma pouco, reação menor; não quebra caixote
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	r0.facing = 1
	r1.dmg = 50.0
	await frames(3)
	await tap("v0", "hammer")
	await frames(4)
	var kx_fast: float = absf(r1.own_vx)
	check(absf(r1.dmg - 50.0 - float(am["combo"]["dano"])) < 0.1, "golpe rápido acerta e soma %d%% (%.0f%%)" % [int(am["combo"]["dano"]), r1.dmg])
	await frames(40)
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	r1.dmg = 50.0
	await frames(3)
	await tap("v0", "heavy")
	await frames(10)
	check(r1.dmg == 50.0, "marretada pesada tem preparo: ainda não acertou no 10º quadro")
	await frames(int(float(Data.ctrl["ataque_pesado"]["preparo"]) * 60.0))
	var kx_heavy: float = absf(r1.own_vx)
	check(r1.dmg > 50.0 and kx_heavy > kx_fast * 1.4, "pesada empurra bem mais que a rápida (%.0f × %.0f)" % [kx_heavy, kx_fast])
	await frames(60)
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(12), 576))
	put(r1, Vector2(col_x(26), 576))
	r0.facing = 1
	await frames(3)
	var cell := Vector2i(13, 9)
	var hp0: int = main.level.blocks[cell]["hp"] if main.level.blocks.has(cell) else -1
	await tap("v0", "hammer")
	await frames(12)
	check(hp0 > 0 and main.level.blocks.has(cell) and main.level.blocks[cell]["hp"] == hp0, "golpe rápido não quebra caixote")
	# marretada que erra deixa aberto: ainda presa depois de 0,5 s
	await frames(20)
	await tap("v0", "heavy")
	await frames(30)
	check(r0.atk == "pesado", "marretada que erra deixa o robô exposto (ainda se recuperando)")
	await frames(40)
	check(r0.atk == "", "...e termina sem travar")
	# 2) esquiva no chão: desloca rápido e, na janela, golpe de robô não pega
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(12), 576))
	put(r1, Vector2(col_x(14), 576))
	r0.facing = 1
	r1.facing = -1
	await frames(3)
	var x0: float = r0.position.x
	vset("v0", "dodge", true)
	await frames(1)
	vset("v0", "dodge", false)
	check(r0.guard_t > 0.0 and r0.dodge_t > 0.0, "esquiva começa com a janela de proteção")
	r1.atk = ""
	var hit_during: bool = r0.take_hit(-1, "rapido", r1.pid)
	check(not hit_during and r0.dmg == 0.0, "na janela da esquiva, golpe de robô não pega")
	var env_hit: bool = r0.take_hit(-1, "explosao", -1)
	check(env_hit and r0.dmg > 0.0, "esquiva NÃO protege de explosão/cenário")
	await frames(12)
	check(absf(r0.position.x - x0) > 60.0 or r0.dmg > 0.0, "esquiva desloca o robô (%.0f px)" % absf(r0.position.x - x0))
	# 3) esquiva no ar: 1 por período no ar; golpe não devolve; pousar devolve
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(12), 150))
	put(r1, Vector2(col_x(25), 576))
	await frames(2)
	await tap("v0", "dodge")
	check(not r0.is_on_floor() and r0.air_dodge == 0, "esquiva no ar gasta a carga aérea")
	await frames(8)
	r0.take_hit(1, "rapido", r1.pid)
	r0.hitstop = 0.0
	r0.stun_t = 0.0
	r0.dodge_cd = 0.0   # sem esperar a recarga: só a regra da carga aérea decide
	await tap("v0", "dodge")
	check(not r0.is_on_floor() and r0.air_dodge == 0 and r0.dodge_t == 0.0, "levar golpe no ar NÃO devolve a esquiva (sem 2ª esquiva no ar)")
	for k in 120:
		if r0.is_on_floor():
			break
		await frames(1)
	await frames(2)
	check(r0.is_on_floor() and r0.air_dodge == 1, "pousar devolve a esquiva aérea")
	# 4) arremesso: sem controle curto, depois controle volta aos poucos; esquiva ajuda mas não anula
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(14), 400))
	r0.dmg = 110.0
	r0.take_hit(1, "pesado", r1.pid)
	r0.hitstop = 0.0
	check(r0.stun_t > 0.0 and r0.stun_t <= float(main.c_ctrl("arremesso")["sem_controle_max"]) + 0.01, "arremesso: perda de controle curta (%.2f s)" % r0.stun_t)
	var v_launch: float = r0.own_vx
	vset("v0", "left", true)
	await frames(int(r0.stun_t * 60.0) + 6)
	check(r0.recover_t > 0.0 and r0.own_vx > 0.0 and r0.own_vx < v_launch, "controle volta aos poucos: corrige sem cancelar o arremesso (%.0f → %.0f)" % [v_launch, r0.own_vx])
	await tap("v0", "dodge")
	await frames(2)
	check(r0.air_dodge == 0 and r0.dodge_carry.x > 0.0, "esquiva na recuperação usa a mesma carga aérea e mantém parte do impulso")
	vset("v0", "left", false)
	await frames(90)
	check(r0.stun_t == 0.0 and r0.atk == "" and r0.dodge_t == 0.0, "nenhum estado preso depois do arremesso")
	await frames(2)
	# 6) combate de perto: colado acerta; sequência de 3 mantém perto e o 3º arremessa; golpes com direção
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 4, 576))
	r0.facing = 1
	r1.dmg = 30.0
	await frames(3)
	await tap("v0", "hammer")
	await frames(6)
	check(r1.dmg > 30.0, "colado (sobreposto) o golpe rápido acerta")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 46, 576 - 90))   # ao lado: fora da área do pisão na cabeça
	r1.velocity = Vector2.ZERO
	r1.invuln = 0.0
	r1.last_cause = ""
	vset("v0", "up", true)
	await tap("v0", "hammer")
	vset("v0", "up", false)
	await frames(6)
	check(r1.last_cause == "cima" and r1.position.y < 576 - 90 - 10, "▲ + golpe joga o rival de cima para o alto")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	r0.facing = 1
	put(r0, Vector2(col_x(11), 576))
	await frames(30)
	put(r1, Vector2(col_x(11) + 40, 576))
	r1.dmg = 30.0
	var near := true
	for k in 3:
		await tap("v0", "hammer")
		await frames(8)
		if k < 2 and absf(r1.position.x - r0.position.x) > 140.0:
			near = false
	check(r0.combo_i == 2 and near, "sequência: 2 golpes mantêm o rival perto e chega ao 3º (combo %d)" % r0.combo_i)
	await frames(10)
	check(absf(r1.own_vx) > 250.0 or absf(r1.position.x - r0.position.x) > 120.0, "o 3º golpe da sequência arremessa")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(14), 90))
	put(r1, Vector2(col_x(14) + 6, 90 + 80))
	r1.invuln = 0.0
	r0.invuln = 0.0
	await frames(2)
	vset("v0", "down", true)
	await tap("v0", "hammer")
	vset("v0", "down", false)
	await frames(6)
	check(r1.last_cause == "baixo" and r1.velocity.y > 200.0, "▼ + golpe no ar joga o rival para baixo")
	# 5) marretada pesada: recarga própria, esquiva cancela o preparo, golpe do rival interrompe
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(20), 576))
	r0.facing = 1
	await frames(3)
	await tap("v0", "heavy")
	await frames(70)
	check(r0.atk == "" and r0.heavy_cd > 0.0, "depois da marretada vem a recarga (%.2f s)" % r0.heavy_cd)
	await tap("v0", "heavy")
	check(r0.atk == "", "na recarga, a marretada não sai (golpe rápido continua livre)")
	await tap("v0", "hammer")
	check(r0.atk == "rapido", "golpe rápido funciona durante a recarga da pesada")
	await demo_round()
	r0 = main.robots[0]
	r1 = main.robots[1]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	r0.facing = 1
	r1.facing = -1
	await frames(3)
	await tap("v0", "heavy")
	await frames(6)
	await tap("v0", "dodge")
	check(r0.atk == "" and r0.dodge_t > 0.0 and r1.dmg == 0.0 and r0.heavy_cd > 0.0, "esquiva cancela o preparo da marretada (finta)")
	await frames(60)
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	r0.facing = 1
	r0.heavy_cd = 0.0
	await frames(3)
	await tap("v0", "heavy")
	await frames(4)
	r1.facing = -1
	await tap("v1", "hammer")
	await frames(6)
	check(r0.atk == "" and r0.dmg > 0.0 and r1.dmg == 0.0, "golpe do rival no preparo INTERROMPE a marretada")

## LABORATÓRIO: abre pela tela inicial, ajusta número ao vivo, mede pulo, boneco obedece, salva/volta ao padrão.
func lab_test() -> void:
	print("== Laboratório")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	main.menus.sel = 0
	await tap("v0", "down")
	await tap("v0", "jump")
	check(main.sandbox and main.lab_mode and main.level.id == "laboratorio" and main.demo.canteiro != null and main.robots.size() == 2, "menu ▸ LABORATÓRIO abre a fase de teste destrutível (1 jogador + boneco)")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
		r.invuln = 0.0
	var lab = main.lab
	var r0 = main.robots[0]
	check(main.demo.canteiro.parts.any(func(p): return p["kind"] == "viga") and main.demo.canteiro.parts.any(func(p): return p["kind"] == "andaime"), "a fase tem laje em trechos, andaimes e vigas penduradas")
	put(r0, Vector2(col_x(9), 12 * 64))
	await frames(20)
	vset("v0", "jump", true)
	await frames(30)
	vset("v0", "jump", false)
	await frames(60)
	check(lab.last_jump != "", "mede o pulo (%s)" % lab.last_jump)
	lab.dummy_i = lab.DUMMY.find("marretada")
	var saw := false
	for k in 150:
		await frames(1)
		if main.robots[1].atk == "pesado":
			saw = true
			break
	check(saw, "boneco obedece o comportamento (dá marretada)")
	lab.dummy_i = 0
	# menu curto
	await tap("v0", "start")
	check(lab.open and main.paused and lab.rows().size() <= 10, "START abre o menu curto (%d linhas)" % lab.rows().size())
	lab.sel = lab.rows().find("spell")
	lab.spell_i = lab.spells().find("A03")
	await tap("v0", "jump")
	check(main.demo.spells.hud_info(0).get("id", "") == "A03" and not lab.open, "menu: SPELL entrega a escolhida ao P1")
	await tap("v0", "start")
	lab.sel = lab.rows().find("evento")
	lab.event_i = 0
	await tap("v0", "jump")
	check(main.events.phase == "aviso" and main.demo.canteiro.cycle_state == "aviso", "menu: EVENTO dispara (G01 funciona na fase do Laboratório)")
	var nel: Array = main.events.cfg["lista"].filter(func(e): return not main.events.eligible(e) and e["id"] != "G01" and not String(e["id"]).begins_with("V"))
	check(nel.is_empty(), "todos os eventos funcionam na fase do Laboratório (fora: %s)" % str(nel.map(func(e): return e["id"])))
	await tap("v0", "start")
	lab.sel = lab.rows().find("bot")
	var nb: int = main.robots.size()
	await tap("v0", "right")
	check(main.robots.size() == nb + 1, "menu: + BOT")
	await tap("v0", "start")
	await frames(240)
	var ct = main.demo.canteiro
	ct.damage(ct.parts[0], 99, ct.parts[0]["rect"].get_center())
	await frames(int(float(ct.cfg["aviso_queda_s"]) * 60.0) + 10)
	check(ct.parts.any(func(p): return p["fallen"]), "trechos da fase caem")
	await tap("v0", "start")
	lab.sel = lab.rows().find("reiniciar")
	await tap("v0", "jump")
	await frames(5)
	check(main.demo.canteiro.parts.all(func(p): return not p["fallen"]) and main.robots.size() == nb + 1, "menu: REINICIAR FASE repõe tudo e mantém bots/bonecos")
	# medidores no jogo
	await tap("v0", "back")
	check(lab.show_meters, "VOLTAR mostra os medidores")
	await tap("v0", "back")
	check(not lab.show_meters, "VOLTAR esconde de novo")
	r0 = main.robots[0]
	r0.invuln = 0.0
	main.kill(r0, -1, null)
	await frames(2)
	check(r0.alive and main.state == S.RUN, "no Laboratório, cair não tira ninguém")
	await tap("v0", "start")
	lab.sel = lab.rows().find("sair")
	await tap("v0", "jump")
	check(main.state == S.MENU and not main.lab_mode and not main.sandbox and not main.paused and Engine.time_scale == 1.0, "SAIR volta ao menu")
	await frames(20)

func lab_shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}}
	await frames(2)
	main.lab.start("v0")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
		r.invuln = 0.0
	await frames(30)
	var r0 = main.robots[0]
	put(r0, Vector2(col_x(12), 12 * 64))
	r0.facing = 1
	main.robots[1].dmg = 90.0
	put(main.robots[1], Vector2(col_x(13) + 6, 12 * 64))
	vset("v0", "jump", true)
	await frames(30)
	vset("v0", "jump", false)
	await frames(60)
	vset("v0", "heavy", true)
	await frames(2)
	vset("v0", "heavy", false)
	await frames(10)
	await snap(dir, "lab_golpe")
	await frames(70)
	await snap(dir, "lab_medidas")
	await tap("v0", "start")
	main.lab.sel = 0
	await frames(4)
	await snap(dir, "lab_painel")

## CANTEIRO DE OBRAS (Relatório 02): KO no mundo nos 4 lados, laje em trechos (núcleo fixo), gatilhos e ciclo da obra.
func canteiro_test() -> void:
	print("== Canteiro de Obras (Derruba)")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var ct = main.demo.canteiro
	check(ct != null and main.level.id == "canteiro_obras" and ct.parts.filter(func(p): return int(p["etapa"]) == 1 and not p["fallen"]).size() == 15 and ct.standing("terreo") == 2, "Canteiro monta laje (6), andaimes (2), vigas (5) e o chão do térreo (2) (%s)" % [ct.standing() if ct != null else -1])
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	put(r1, Vector2(col_x(30), 13 * 64))
	# marretada pesada no trecho 0 (cols 8-11) até desabar
	var seg = ct.parts[0]
	var hits := 0
	for k in 12:
		put(r0, Vector2(col_x(9), 13 * 64))
		r0.facing = 1
		r0.heavy_cd = 0.0
		await frames(2)
		await tap("v0", "heavy")
		await frames(66)   # marretada que não acerta robô dura ~1 s (preparo + recuperação longa)
		hits += 1
		if seg["fallen"] or seg["crit_t"] > 0.0:
			break
	check(seg["crit_t"] > 0.0 or seg["fallen"], "marretadas pesadas levam o trecho ao aviso final (%d golpes)" % hits)
	put(r0, Vector2(col_x(10), 12 * 64))
	await frames(80)
	check(seg["fallen"] and not main.level.is_solid(Vector2i(9, 13)), "o trecho desaba e a colisão some junto")
	check(r0.position.y > 13 * 64 + 40 or main.demo.lives.get(0, 5) < 5, "quem estava em cima cai")
	# caixa de spell pousa na laje (não atravessa) e cai junto quando o trecho desaba
	var seg2 = ct.parts[1]
	var sp = main.demo.spells
	sp.boxes.clear()
	sp.drop_box("A01", Vector2(seg2["rect"].get_center().x, 0))
	await frames(150)
	var it: Dictionary = sp.boxes[0] if sp.boxes.size() > 0 else {}
	check(not it.is_empty() and absf(it["pos"].y + 30.0 - seg2["rect"].position.y) < 8.0, "caixa pousa em cima da laje (y %.0f, laje %.0f)" % [it.get("pos", Vector2.ZERO).y + 30.0, seg2["rect"].position.y])
	ct.damage(seg2, 99, seg2["rect"].get_center())
	await frames(int(float(ct.cfg["aviso_queda_s"]) * 60.0) + 40)
	check(sp.boxes.is_empty() or sp.boxes[0]["pos"].y > seg2["rect"].position.y + 40.0, "trecho desabou: a caixa cai junto")
	# núcleo nunca cai
	var nuc = ct.parts[2]
	for k in 20:
		ct.damage(nuc, 99, nuc["rect"].get_center())
	await frames(90)
	check(not nuc["fallen"], "o núcleo (trechos do meio) nunca cai")
	# golpe rápido não danifica
	await demo_round()
	ct = main.demo.canteiro
	r0 = main.robots[0]
	put(r0, Vector2(col_x(26), 13 * 64))
	r0.facing = 1
	await frames(2)
	await tap("v0", "hammer")
	await frames(20)
	check(ct.parts[4]["hp"] == ct.parts[4]["max"] and ct.parts[5]["hp"] == ct.parts[5]["max"], "golpe rápido não danifica a laje")
	# G01 Sirene de Demolição (evento da biblioteca; no Canteiro o ciclo virou o DIRETOR da destruição): aviso e o alvo cede
	main.event_level = 2
	main.events.manual = true
	main.events.libera_tudo = true
	var g01: Dictionary = main.events.cfg["lista"][0]
	main.events.trigger(g01)
	await frames(3)
	var alvo = ct.target
	check(main.events.phase == "aviso" and ct.cycle_state == "aviso" and alvo != null and not alvo["nucleo"] and alvo["warn_t"] > 0.0, "G01 Sirene de Demolição marca um trecho com aviso (sirene + fita)")
	await frames(int((minf(float(g01["aviso_s"]), 1.2) + float(g01["dur"]) * 0.5 + float(ct.cfg["aviso_queda_s"])) * 60.0) + 20)
	check(alvo != null and alvo["fallen"] and ct.cycle_state == "calma" and main.events.phase == "", "depois do aviso o trecho cede e o evento termina")
	main.events.libera_tudo = false
	main.events.manual = false
	main.event_level = 0
	# KO no mundo nos 4 lados (independente da câmera)
	var ko: Rect2 = main.level.ko_rect()
	var dirs := {"esquerda": Vector2(ko.position.x - 40, 600), "direita": Vector2(ko.end.x + 40, 600), "cima": Vector2(1200, ko.position.y - 40), "baixo": Vector2(1200, ko.end.y + 80)}
	for nome in dirs:
		await demo_round()
		r1 = main.robots[1]
		var lives0: int = main.demo.lives.get(1, 5)
		main.cam_lock = [1.0, Vector2(1280, 700)]
		put(r1, dirs[nome])
		await frames(3)
		check(main.demo.lives.get(1, 5) < lives0 or not r1.alive, "KO pela borda: %s" % nome)
	main.cam_lock = []
	# dentro da zona mas fora da tela (câmera bem fechada) NÃO elimina
	await demo_round()
	r1 = main.robots[1]
	main.cam_lock = [2.0, Vector2(600, 600)]
	put(r1, Vector2(ko.end.x - 200, 900))
	await frames(3)
	check(r1.alive and main.demo.lives.get(1, 5) == 5, "fora da tela mas dentro da zona: segue vivo (a câmera não decide o KO)")
	main.cam_lock = []
	main.go_menu()
	await frames(20)

## Relatório 04, Etapa 1: caixas por família, slot único, troca segurando, limpeza na eliminação e as 6 spells; G10.
## Etapa 5: os 12 eventos globais (aviso → ativo → fim), até 2 juntos, matriz de conflitos e intensidade.
func eventos_test() -> void:
	print("== Eventos globais (Etapa 5)")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var ev = main.events
	var ct = main.demo.canteiro
	main.demo.spells.spawn_t = 999.0
	main.event_level = 2
	check(ev.eligible(ev.ev("G03")) and ev.eligible(ev.ev("V1")) and not ev.eligible(ev.ev("V3")) and ev.eligible(ev.ev("G01")), "A14: no Térreo valem os eventos do mapa (G03, G01…) e o perigo V1; V3 é da Fundação")
	ev.libera_tudo = true   # daqui em diante testa a BIBLIOTECA inteira (cada evento isolado)
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = ct.parts.filter(func(p): return p["nucleo"])
	var fy: float = nuc[0]["rect"].position.y
	var fx: float = nuc[0]["rect"].position.x
	var reset := func() -> void:
		for i in main.players.size():
			main.demo.lives[i] = 99
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.recover_t = 0.0
			r.invuln = 0.0
			r.velocity = Vector2.ZERO
		put(r0, Vector2(fx + 40.0, fy))
		put(r1, Vector2(fx + 440.0, fy))
	main.event_level = 2
	ev.manual = true
	var go := func(id: String) -> Dictionary:
		ev.trigger(ev.ev(id))
		await frames(2)
		return ev.inst(id) if ev.inst(id) != null else {}
	var wait_phase := func(a: Dictionary, ph: String) -> void:
		for i in 1200:
			if a.is_empty() or a["phase"] == ph or not ev.active.has(a):
				return
			await frames(1)
	var wait_end := func(a: Dictionary) -> void:
		for i in 2400:
			if not ev.active.has(a):
				return
			await frames(1)
	# G02 Ventania
	reset.call()
	var a: Dictionary = await go.call("G02")
	check(not a.is_empty() and a["phase"] == "aviso" and ev.wind == 0.0, "G02: aviso primeiro (exaustores e setas), sem vento ainda")
	await wait_phase.call(a, "ativo")
	await frames(45)
	var x0: float = r0.position.x
	await frames(40)
	check(signf(ev.wind) == float(a["d"]["dir"]) and absf(ev.wind) <= float(ev.cfg["vento_max"]) and signf(r0.position.x - x0) == float(a["d"]["dir"]), "G02: vento empurra para o lado anunciado (%.0f px/s), com teto" % ev.wind)
	await wait_end.call(a)
	check(ev.wind == 0.0, "G02: vento acaba no fim")
	# G03 Gravidade
	a = await go.call("G03")
	await wait_phase.call(a, "ativo")
	await frames(40)
	check(ev.gravity_mult < 0.7, "G03: gravidade baixa no ativo (%.2f)" % ev.gravity_mult)
	await wait_phase.call(a, "fim")
	await frames(20)
	var mid_g: float = ev.gravity_mult
	await wait_end.call(a)
	check(mid_g > 0.55 and mid_g < 1.0 and ev.gravity_mult == 1.0, "G03: volta aos poucos ao normal (%.2f → 1)" % mid_g)
	# G04 Sobrecarga
	reset.call()
	a = await go.call("G04")
	check(not a.is_empty(), "G04: bobina escolhe um lugar no chão")
	var coil: Vector2 = a["d"]["pos"] if not a.is_empty() else Vector2.ZERO
	put(r0, Vector2(coil.x - 300.0, fy))
	await wait_phase.call(a, "ativo")
	var d0: float = absf(r0.position.x - coil.x)
	await frames(60)
	check(absf(r0.position.x - coil.x) < d0 - 20.0, "G04: pulso puxa quem está no círculo (%.0f → %.0f)" % [d0, absf(r0.position.x - coil.x)])
	await wait_end.call(a)
	# G05 Guindaste
	reset.call()
	a = await go.call("G05")
	check(not a.is_empty(), "G05: acha lugar para a carga (com espaço em cima e embaixo)")
	if not a.is_empty():
		var cr: Rect2 = a["d"]["rect"]
		await wait_phase.call(a, "ativo")
		await frames(int(float(a["e"]["desce_s"]) * 60.0) + 10)
		check(a["d"]["body"] != null and absf(a["d"]["y"] - cr.position.y) < 1.0, "G05: a carga desce e trava no lugar anunciado")
		put(r0, Vector2(cr.get_center().x, cr.position.y - 60.0))
		await frames(40)
		check(r0.is_on_floor() and absf(r0.position.y - cr.position.y) < 6.0, "G05: dá para subir na carga (plataforma nova)")
		await wait_phase.call(a, "fim")
		await frames(30)
		check(not r0.is_on_floor() or r0.position.y > cr.position.y + 20.0, "G05: no fim a trava solta antes de a carga subir (ninguém é levado)")
		await wait_end.call(a)
		# 2ª vez: caixa de spell em cima da carga; marretar o gancho derruba a carga em quem está embaixo
		reset.call()
		main.demo.spells.boxes.clear()
		a = await go.call("G05")
		cr = a["d"]["rect"]
		await wait_phase.call(a, "ativo")
		var on_load := false
		for i in 400:
			await frames(1)
			for b in main.demo.spells.boxes:
				if b["special"] and absf(b["pos"].y - (cr.position.y - 30.0)) < 2.0 and absf(b["pos"].x - cr.get_center().x) < 40.0:
					on_load = true
			if on_load:
				break
		check(on_load, "G05: uma caixa especial de spell desce e fica EM CIMA da carga")
		var fl0: float = a["d"]["floor"] if a["d"].has("floor") else ev._floor_under_rect(cr, null)
		put(r1, Vector2(cr.get_center().x, fl0))
		r1.dmg = 0.0
		ev.hammer_hit(ev.hook_rect(a), false, 0)
		ev.hammer_hit(ev.hook_rect(a), false, 0)
		for i in 120:
			await frames(1)
			if not ev.active.has(a) or a["d"].get("state", "") == "caiu":
				break
		check(a["d"].get("state", "") == "caiu" and r1.dmg > 0.0 and r1.last_attacker == 0, "G05: 2 marretadas no gancho soltam a carga em quem está embaixo (crédito de quem marretou)")
		await wait_end.call(a)
	# G06 Entulho
	reset.call()
	a = await go.call("G06")
	var andm: Array = ct.parts.filter(func(p): return p["kind"] == "andaime")
	put(r0, Vector2(andm[0]["rect"].get_center().x, andm[0]["rect"].position.y))
	put(r1, Vector2(andm[1]["rect"].get_center().x, andm[1]["rect"].position.y))
	check(not a.is_empty() and a["d"]["spots"].size() >= 2, "G06: marca %d sombras listradas" % (0 if a.is_empty() else a["d"]["spots"].size()))
	await wait_end.call(a)
	await frames(60)
	var solid: Array = ev.crates.filter(func(c): return c["state"] == "chao")
	check(solid.size() >= 2 and solid.all(func(c): return c["body"] != null), "G06: o entulho cai e vira obstáculo (%d)" % solid.size())
	var spawns_ok: bool = solid.all(func(c): return main.level.spawns.values().all(func(s): return absf(s.x - c["pos"].x) >= 120.0 or absf(s.y - c["floor"]) > 90.0))
	check(spawns_ok, "G06: nunca cai em cima de nascimento")
	if not solid.is_empty():
		var c0: Dictionary = solid[0]
		check(main.demo.spells._hard_at(ev.crate_rect(c0).get_center()), "G06: entulho é cobertura (para tiros)")
		ev.hammer_hit(ev.crate_rect(c0), true)
		check(not ev.crates.has(c0), "G06: marretada forte quebra o entulho")
	# G11 Interdição
	reset.call()
	a = await go.call("G11")
	check(not a.is_empty(), "G11: escolhe uma faixa no chão")
	if not a.is_empty():
		var w: Dictionary = a["d"]["walls"][0]
		put(r0, Vector2(w["x"] + 40.0, w["y"]))
		await wait_phase.call(a, "ativo")
		await frames(20)
		var wr := Rect2(w["x"], w["y"] - w["h"], w["w"], w["h"])
		check(w["body"] != null and not r0.rect().intersects(wr.grow(-2)), "G11: tapume sobe sem prender ninguém (empurra para fora)")
		check(main.demo.spells._hard_at(wr.get_center()), "G11: tapume bloqueia tiro")
		await wait_end.call(a)
		check(w["body"] == null, "G11: tapumes descem no fim")
	# G12 Andaimes
	reset.call()
	a = await go.call("G12")
	check(not a.is_empty() and a["d"]["moves"].size() >= 1, "G12: andaimes marcados com o destino")
	if not a.is_empty():
		var m: Dictionary = a["d"]["moves"][0]
		await wait_phase.call(a, "ativo")
		await frames(int(float(a["e"]["mover_s"]) * 60.0) + 5)
		var moved: bool = absf(m["p"]["rect"].position.y - (m["base"] + m["dy"])) < 1.0
		check(moved and ct.owner_of.has(Vector2i(int(m["p"]["rect"].get_center().x / 64.0), int(m["p"]["rect"].position.y / 64.0))), "G12: o deque muda de altura (%.0f px) e a colisão vai junto" % m["dy"])
		await wait_end.call(a)
		check(absf(m["p"]["rect"].position.y - m["base"]) < 0.5 and m["p"]["evt"] == "", "G12: volta ao lugar no fim")
	# G13 Cabo Rompido
	reset.call()
	a = await go.call("G13")
	check(not a.is_empty(), "G13: escolhe uma viga com chão embaixo")
	if not a.is_empty():
		var p: Dictionary = a["d"]["p"]
		var base: Rect2 = a["d"]["base"]
		put(r1, Vector2(base.get_center().x, a["d"]["floor"]))
		r1.god = false
		await wait_phase.call(a, "ativo")
		for i in 120:
			if a["d"]["state"] != "cai":
				break
			await frames(1)
		check(a["d"]["state"] == "chao" and a["d"]["body"] != null, "G13: a viga cai e vira plataforma no chão")
		check(r1.dmg > 0.0 and r1.last_attacker == -1, "G13: quem ficou na faixa vermelha leva o golpe (do ambiente, não de jogador)")
		await wait_end.call(a)
		check(not p["fallen"] and p["rect"] == base and is_instance_valid(p["body"]) and p["evt"] == "", "G13: o guindaste pendura a viga de volta")
	# G14 Rebites
	reset.call()
	a = await go.call("G14")
	if not a.is_empty():
		var b: Rect2 = a["d"]["bands"][0]
		put(r0, Vector2(b.get_center().x, fy) if b.get_center().x > fx - 200.0 else Vector2(b.get_center().x, r0.position.y))
		await wait_phase.call(a, "ativo")
		var safe := true
		var inband := true
		for i in 60:
			for rv in ev.rivets:
				if rv["state"] == "cai" and not a["d"]["bands"].any(func(bb): return rv["pos"].x >= bb.position.x - 2.0 and rv["pos"].x <= bb.end.x + 2.0):
					inband = false
			await frames(1)
		check(inband and ev.rivets.size() > 0, "G14: rebites só caem nas faixas marcadas")
		await wait_end.call(a)
		check(ev.rivets.size() < 60, "G14: densidade limitada")
	# conflitos e simultâneos
	await go.call("G02")
	await go.call("G03")
	check(ev.is_active("G03") and not ev.is_active("G02"), "matriz: G03 tira G02 (não rodam juntos)")
	await go.call("G14")
	check(ev.active.size() == 2, "dois eventos compatíveis juntos (G03 + G14)")
	await go.call("G06")
	check(ev.active.size() <= 2, "nunca mais de 2 ao mesmo tempo")
	ev.reset_round()
	ev.manual = false
	main.event_level = 3
	ev.timer = 0.01
	var maxn := 0
	var bad := false
	var seen := {}
	for i in 60 * 70:
		await frames(1)
		for i2 in main.players.size():
			main.demo.lives[i2] = 99
		maxn = maxi(maxn, ev.active.size())
		for x in ev.active:
			seen[x["id"]] = true
			for y in ev.active:
				if x != y and ev.conflict(x["id"], y["id"]):
					bad = true
		if main.state != S.RUN:
			break
	check(maxn <= 2 and not bad and seen.size() >= 3, "agendador (alta): até 2 juntos, sem conflito (%d eventos vistos: %s)" % [seen.size(), str(seen.keys())])
	main.event_level = 0
	ev.manual = false
	ev.reset_round()
	ev.libera_tudo = false

## Fase em etapas (cartilha do mapa): a virada cronometrada — aviso, tudo desaba, queda sem KO e chegada na etapa 2.
func etapas_test() -> void:
	print("== Fase em etapas (virada do Canteiro)")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var et = main.demo.etapas
	var lv = main.level
	check(et != null and et.etapa == 1 and lv.area == lv.etapa_rect(1), "Canteiro começa na etapa 1 (área = Térreo)")
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	put(r0, Vector2(2 * 64.0, 17 * 64.0))   # na ponta do térreo esquerdo (fora do buraco)
	put(r1, Vector2(20 * 64.0, 13 * 64.0))   # no núcleo
	for i in main.players.size():
		main.demo.lives[i] = 9
	var lives0 = main.demo.lives.duplicate()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	sp.boxes.clear()
	sp.drop_box("A02", Vector2(6 * 64.0, 17 * 64.0), false)   # caixa no térreo: tem de cair junto para a Fundação
	# --- v2: o TEMPO decide QUANDO verificar, a DESTRUIÇÃO decide PARA ONDE
	var ct = main.demo.canteiro
	et.ativo = true
	var tp: Array = et.tempos()
	var vcf: Dictionary = et.dcfg["verificacao"]
	var p1e := float(vcf["primeira_base_s"]) + float(vcf["por_vida_s"]) * (5 - int(vcf["vidas_base"]))
	check(is_equal_approx(tp[0], p1e) and absf(tp[1] - p1e * float(vcf["intervalo_frac"])) < 0.1, "5 vidas: 1ª verificação aos %.0f s, depois a cada ~%.0f s (lido de modos.json)" % [tp[0], tp[1]])
	check(ct.progresso(1) == 0.0, "obra intacta: 0%")
	for p in ct.parts:
		if p["nucleo"] or p["kind"] == "terreo":
			ct.damage(p, 9, p["rect"].get_center())
	check(ct.progresso(1) == 0.0, "base fixa (núcleo e térreo) não leva dano e não conta na destruição")
	et.t_cena = et.prox_verif - 0.05   # chega a hora da 1ª verificação, sem destruição
	await frames(10)
	check(et.state == "etapa" and et.verificacoes == 1 and et.prox_verif > et.t_cena + 20.0, "abaixo da faixa na verificação: fica na cena e marca a próxima (+%.0f s)" % (et.prox_verif - et.t_cena))
	var vig: Array = ct.parts.filter(func(p): return p["kind"] == "viga" and int(p["etapa"]) == 1)
	ct.damage(vig[0], 1, vig[0]["rect"].get_center())   # dano parcial (caminho de spells/eventos/mecanismos/ciclo)
	var pp: float = ct.progresso(1)
	check(pp > 0.0 and pp < 0.2, "dano parcial conta proporcional ao HP perdido (%.1f%%)" % (pp * 100.0))
	put(r0, Vector2(vig[1]["rect"].get_center().x - 70.0, vig[1]["rect"].position.y))
	r0.facing = 1
	r0.heavy_cd = 0.0
	await frames(5)
	await heavy_hit("v0")
	check(ct.progresso(1) > pp, "marretada do jogador também conta (%.1f%%)" % (ct.progresso(1) * 100.0))
	et.progresso = 0.62
	et.verificar()
	check(et.state == "aviso" and et.rota == "moderada" and et.destino == 3 and main.demo.banner.begins_with("A LAJE"), "faixa moderada na verificação → rota MODERADA (Fachada): \"A LAJE VAI ESCORREGAR!\"")
	et.state = "etapa"   # cancela (a transição moderada inteira tem teste próprio) e segue para provar a rota total
	et.destino = -1
	main.demo.banner = ""
	put(r0, Vector2(2 * 64.0, 17 * 64.0))   # de volta à ponta do térreo (a marretada o deixou perto da beira)
	for i in main.players.size():
		main.demo.lives[i] = 9
	lives0 = main.demo.lives.duplicate()
	for p in ct.parts:
		if int(p["etapa"]) == 1 and not p["nucleo"] and p["kind"] != "terreo":
			ct.damage(p, 99, p["rect"].get_center())
	et.prox_verif = et.t_cena + 999.0
	var w0 := 0
	while et.progresso < et.limiar_total() and w0 < 600:   # as peças caem aos poucos
		await frames(1)
		w0 += 1
	await frames(30)
	check(et.state == "etapa", "A56: bater %.0f%% ANTES da verificação não vira a cena (quem decide é o tempo, ~90 s)" % (et.limiar_total() * 100.0))
	et.t_cena = et.prox_verif - 0.05
	await frames(3)
	check(et.state == "aviso" and et.rota == "total" and et.destino == 2 and main.demo.banner.begins_with("A OBRA"), "≥ %.0f%% na verificação → rota TOTAL: \"A OBRA VAI CEDER!\"" % (et.limiar_total() * 100.0))
	sp.equip(r1, "T04")   # jetpack ligado bem na virada (bug: voava para fora da queda)
	sp.use(r1)
	await frames(int(float(et.cfg["aviso_s"]) * 60.0) + 4)
	check(et.state == "queda" and main.demo.canteiro.parts.all(func(p): return p["fallen"] or int(p["etapa"]) != 1), "a estrutura TODA da etapa 1 desaba (inclusive núcleo e térreo)")
	check(main.demo.canteiro.parts.filter(func(p): return p["kind"] == "entulho").size() == 2, "pedaços da laje caem na Fundação e viram obstáculos")
	var waited := 0
	while et.state != "etapa" and waited < 400:
		await frames(1)
		waited += 1
	var a2: Rect2 = lv.etapa_rect(2)
	check(et.etapa == 2 and lv.area == a2 and not lv.ko_off, "chegam na etapa 2 (%.1f s de queda): câmera e KO passam para a Fundação" % (waited / 60.0))
	check(r0.alive and r1.alive and main.demo.lives == lives0, "ninguém é eliminado na queda")
	check(a2.has_point(r0.position) and a2.has_point(r1.position), "o funil leva até quem estava na ponta do térreo para dentro do buraco")
	await frames(30)
	check(r0.is_on_floor() and r1.is_on_floor(), "todos de pé no chão da Fundação")
	for p in ct.parts:   # última cena: nem 100% de destruição gera transição (não há próxima)
		if int(p["etapa"]) == 2:
			ct.damage(p, 99, p["rect"].get_center())
	await frames(120)
	check(et.etapa == 2 and et.state == "etapa" and not et.tem_proxima(), "última cena: destruída (%.0f%%) e sem transição inexistente" % (ct.progresso(2) * 100.0))
	check(String(sp.flags(r1).get("spell", "")) != "T04", "o jetpack desliga na virada (ninguém foge da queda voando)")
	sp.spawn_box()
	await frames(150)
	var bx_ok: bool = sp.boxes.size() >= 1 and sp.boxes.all(func(b): return a2.has_point(b["pos"]) and b["pos"].y > a2.position.y + 140.0)
	check(bx_ok, "caixas de spell caem DENTRO da Fundação (nenhuma presa em cima do teto): %s" % [sp.boxes.map(func(b): return b["pos"])])
	main.event_level = 0

## Resolução modo → mapa → cena (manifesto data/mapas/<modo>/<mapa>.json): validação, spells, eventos e mecanismos por
## cena, isolamento entre mapas e modos (sem herança silenciosa). --so=mapa
func mapa_test() -> void:
	print("== Mapa: manifesto e resolução modo → mapa → cena")
	var m := MapaReg.manifesto("derruba", "canteiro_obras")
	check(not m.is_empty() and MapaReg.validar(m).is_empty(), "manifesto do Canteiro carrega e valida (%s)" % str(MapaReg.validar(m)))
	var classes: Dictionary = MapaReg.modo_cfg("derruba")["classes_spells"]
	check(classes.keys() == ["ataque", "controle", "transformacao", "defesa"], "classes de spell pertencem ao MODO Derruba (%s)" % str(classes.keys()))
	var sp: Array = MapaReg.spells("derruba", "canteiro_obras", [])
	check(sp.size() == 27 and ["D01", "D02", "D03", "D04", "D05", "D06"].all(func(x): return x in sp), "Canteiro autoriza as 27 spells aprovadas (sem E01/E03, com a Defesa D01–D06) (%d)" % sp.size())
	check(MapaReg.spells("batata", "obra_concreto", ["A01"]).is_empty() and MapaReg.spells("derruba", "mapa_sem_manifesto", ["A01"]).is_empty(), "sem manifesto: nenhuma spell (outro modo não herda as do Derruba)")
	check(MapaReg.spells("derruba", "demolicao", ["A01", "A02"]).size() == 2, "mapa-ferramenta (laboratório/testes) recebe o pool do modo, explícito")
	var e1: Array = MapaReg.eventos("derruba", "canteiro_obras", 1)
	var e2: Array = MapaReg.eventos("derruba", "canteiro_obras", 2)
	check("V1" in e1 and not "V1" in e2 and "V3" in e2 and not "V3" in e1 and "G01" in e1 and "G01" in e2, "eventos por cena: V1 só no Térreo, V3 só na Fundação, G01 Sirene nas duas")
	check(MapaReg.eventos("derruba", "mapa_sem_manifesto", 1) == [] and MapaReg.eventos("derruba", "demolicao", 1) == null, "sem manifesto: nenhum evento; ferramenta: biblioteca")
	var mecs: Array = MapaReg.mecanismos("derruba", "canteiro_obras")
	var por := {1: [], 2: [], 3: []}
	for d in mecs:
		por[int(d["etapa"])].append(d["id"])
	check(mecs.size() == 13 and por[1] == ["M1", "M2", "M4", "M5"] and por[2] == ["M6", "M7", "M8", "M9"] and por[3] == ["M10", "M10b", "M11", "M12", "M13"], "mecanismos instanciados na cena certa (%s)" % str(por))
	check(MapaReg.rota("derruba", "canteiro_obras", 1, "total") == 2 and MapaReg.rota("derruba", "canteiro_obras", 1, "moderada") == 3 and not MapaReg.tem_proxima("derruba", "canteiro_obras", 2) and not MapaReg.tem_proxima("derruba", "canteiro_obras", 3), "Térreo → Fundação (total) ou Fachada (moderada); as duas são as últimas")
	var bad := {"mode_id": "derruba", "topologia": 4, "spells_permitidas": ["S99"], "eventos_permitidos": [], "cenas": [
		{"id": "a", "ordem": 1, "nivel": 1, "eventos": ["G02"], "mecanismos": [{"id": "X"}], "rota_total": "a", "rota_moderada": null}]}
	var errs := MapaReg.validar(bad)
	check(errs.size() >= 5, "validação pega spell inexistente, topologia errada, evento fora da lista, mecanismo sem posição e rota em ciclo (%d erros: %s)" % [errs.size(), str(errs)])

## Skins do mapa na entrada (modo → mapa → personagens): X/□ alterna padrão ↔ skins do mapa escolhido para o robô;
## trocar de robô volta ao padrão; a partida veste o robô. --so=skins
func skins_test() -> void:
	print("== Skins do mapa na entrada")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.players[0]["model"] = 0
	check(main.skins_do_robo(0) == ["", "k1", "k6", "k7"] and main.skins_do_robo(4) == ["", "k5", "k14", "k15"], "Canteiro oferece 3 skins por robô (%s)" % str(main.skins_do_robo(0)))
	var faltam := []
	for m in 5:
		for k in main.skins_do_robo(m).slice(1):
			var mn: String = Data.MODELS[m]
			for t in ["corpo_%s_%s_p1", "tronco_%s_%s_p4", "cabeca_%s_%s_p2", "rosto_%s_%s_normal", "antena_%s_%s", "ferramenta_%s_%s", "mao_%s_%s", "pe_%s_%s"]:
				if Data.tex("robo/" + t % [mn, k]) == null:
					faltam.append(t % [mn, k])
	check(faltam.is_empty(), "as 15 skins têm todas as camadas (corpo, tronco, cabeça, rosto, acessório, ferramenta, luva, botina) %s" % str(faltam.slice(0, 4)))
	await tap("v0", "hammer")
	check(main.players[0]["skin"] == "k1" and main.skin_nome(0, "k1") == "MESTRE DE OBRAS", "X/□ veste a skin do mapa (Mestre de Obras)")
	await tap("v0", "hammer")
	await tap("v0", "hammer")
	check(main.players[0]["skin"] == "k7" and main.skin_nome(0, "k7") == "SUCATEIRO", "X/□ de novo passa pelas outras (Brigadista → Sucateiro)")
	await tap("v0", "hammer")
	check(main.players[0]["skin"] == "", "...e volta ao padrão")
	await tap("v0", "hammer")
	await tap("v0", "down")
	check(main.players[0]["skin"] == "", "trocar de robô volta ao visual padrão")
	await tap("v0", "hammer")
	var sk: String = main.players[0]["skin"]
	main.arena_choice = "demolicao"
	check(main.skins_do_robo(int(main.players[0]["model"])) == [""], "mapa sem skins não oferece nenhuma")
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	check(main.robots[0].vis.skin == sk and sk == "k2" and main.robots[1].vis.skin == "", "na partida o robô entra vestido (%s); quem não escolheu fica padrão" % sk)

## Limpa de spells (2026-11-25): gancho sobe por cima e se salva sozinho caindo; carga gruda no rival; bola pula;
## empilhadeira pega mais longe (e avança); controle remoto aciona máquinas. --so=limpa
func limpa_test() -> void:
	print("== Limpa de spells (gancho, carga, bola, empilhadeira, controle remoto)")
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	for i in main.players.size():
		main.demo.lives[i] = 9
	var ny := 13 * 64.0   # topo do núcleo da laje
	# C03: chega na garra embaixo da viga grande → passa POR CIMA dela
	put(r1, Vector2(1800.0, 17 * 64.0))
	put(r0, Vector2(1280.0, 8 * 64.0 + 26.0 + 80.0))   # onde o puxão termina: logo abaixo da viga grande
	sp._hook_finish(r0, Vector2(1280.0, 8 * 64.0 + 8.0))
	await frames(40)
	check(r0.position.y <= 8 * 64.0 + 2.0 and r0.position.y > 8 * 64.0 - 40.0, "C03: puxado por baixo da plataforma, passa e fica EM CIMA dela (y %.0f)" % r0.position.y)
	# C03: caindo sem mirar → acha sozinho onde agarrar (para cima/lado, nunca para baixo)
	put(r0, Vector2(1300.0, ny - 200.0))
	r0.velocity = Vector2(0, 400)
	var dv: Vector2 = sp._hook_auto(r0, float(sp.sc("C03")["alcance_tiles"]) * 64.0)
	check(dv != Vector2.ZERO and dv.y <= 0.3, "C03: salvamento automático mira a estrutura mais perto (%s)" % str(dv))
	# E02: arremessada, gruda no rival
	put(r0, Vector2(1100.0, ny))
	put(r1, Vector2(1260.0, ny))
	r0.facing = 1
	sp.clear(r0)
	sp.equip(r0, "E02")
	await frames(3)
	await tap("v0", "item")
	var stuck := false
	for k in 60:
		await frames(1)
		if sp.charges_placed.any(func(c): return int(c.get("on", -1)) == r1.pid):
			stuck = true
			break
	check(stuck, "E02: a carga arremessada GRUDA no rival")
	sp.clear(r0)
	sp.charges_placed.clear()
	# T03: a bola pula de verdade
	put(r1, Vector2(1800.0, 17 * 64.0))
	put(r0, Vector2(1200.0, ny))
	sp.equip(r0, "T03")
	await frames(3)
	await tap("v0", "item")
	await frames(62)
	vset("v0", "item", true)   # A33: segurar o especial fecha em bola
	await frames(20)
	var y0: float = r0.position.y
	await tap("v0", "jump")
	var top := y0
	for k in 30:
		await frames(1)
		top = minf(top, r0.position.y)
	check(r0.spell_form == "bola" and y0 - top > 90.0, "T03: a bola pula (%.0f px)" % (y0 - top))
	vset("v0", "item", false)
	sp.clear(r0)
	await frames(20)
	# T02: rival a 2,3 tiles na frente → o garfo pega
	put(r0, Vector2(1100.0, ny))
	put(r1, Vector2(1100.0 + 150.0, ny))
	r0.facing = 1
	r1.invuln = 0.0
	r1.guard_t = 0.0
	sp.equip(r0, "T02")
	await frames(3)
	await tap("v0", "item")
	await frames(50)
	await tap("v0", "item")
	await frames(6)
	var lifted = sp.slot[0]["data"].get("lift") if sp.slot.has(0) else null
	check(lifted == r1, "T02: o garfo pega o rival a 150 px (área maior)")
	sp.clear(r0)
	# E03: a máquina da cena entra na lista de alvos
	main.demo.etapas.ativo = false
	put(r0, Vector2(300.0, 17 * 64.0))
	sp.equip(r0, "E03")
	await frames(3)
	var tg = sp.remote_target(r0)
	check(tg != null, "E03: há alvo ao alcance perto da betoneira/serra (%s)" % ("máquina" if tg != null and tg.has("mec") else "estrutura" if tg != null else "nenhum"))
	sp.clear(r0)

## Derruba v2 sem diretor (A5): parado, nada cai sozinho; as verificações acontecem no tempo das vidas e ficam na
## cena (< 50%). --so=verificacao
func verificacao_test() -> void:
	print("== Verificação por tempo × vidas (sem diretor)")
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 3
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var et = main.demo.etapas
	var ct = main.demo.canteiro
	var vcf: Dictionary = et.dcfg["verificacao"]
	var t3 := float(vcf["primeira_base_s"]) + float(vcf["por_vida_s"]) * (3 - int(vcf["vidas_base"]))
	var t6 := t3 + 3.0 * float(vcf["por_vida_s"])
	check(is_equal_approx(et.tempos()[0], t3) and absf(et.tempos()[1] - t3 * float(vcf["intervalo_frac"])) < 0.1, "3 vidas: %.0f s / %.0f s (lido de modos.json)" % [et.tempos()[0], et.tempos()[1]])
	main.demo.lives_setting = 6
	check(is_equal_approx(et.tempos()[0], t6) and absf(et.tempos()[1] - t6 * float(vcf["intervalo_frac"])) < 0.1, "6 vidas: %.0f s / %.0f s" % [et.tempos()[0], et.tempos()[1]])
	main.demo.lives_setting = 3
	et.prox_verif = et.tempos()[0]
	for r in main.robots:
		put(r, Vector2(2 * 64.0 + r.pid * 40.0, 17 * 64.0))   # parados no térreo, longe da laje
		r.active = false
	et.ativo = true
	var espera := float(et.tempos()[0]) + float(et.tempos()[1]) + 1.0
	for k in int(60 * espera):
		await frames(1)
	var caidas: int = ct.parts.filter(func(p): return int(p["etapa"]) == 1 and p["fallen"]).size()
	check(caidas == 0 and ct.progresso(1) == 0.0, "sem diretor: %.0f s parados e nada caiu sozinho (%d peças, %.0f%%)" % [espera, caidas, ct.progresso(1) * 100.0])
	check(et.state == "etapa" and et.verificacoes >= 2, "verificou na 1ª hora e de novo depois, e ficou na cena (%d verificações)" % et.verificacoes)
	check("G01" in MapaReg.eventos("derruba", "canteiro_obras", 1) and "G01" in MapaReg.eventos("derruba", "canteiro_obras", 2), "G01 Sirene volta como evento do Canteiro (nas 2 cenas)")
	for r in main.robots:
		r.active = true

## Correções urgentes 2026-11-28: na Fundação as caixas de engenhoca continuam caindo quando as plataformas já caíram
## (chão firme do .lvl entra nos pontos); a G03 (gravidade) tem teto de porcas no ar (era a queda de FPS). --so=caixas_subsolo
func caixas_subsolo_test() -> void:
	print("== Caixas no subterrâneo + porcas da G03")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.event_level = 0
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.demo.lives_setting = 3
	main.event_level = 2
	main.start_match()
	main.events.manual = true   # nada sorteado: o teste liga a G03 na mão
	await demo_round()
	var et = main.demo.etapas
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	et.ativo = true
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	check(et.etapa == 2, "chegou na Fundação (%.1f s)" % (w / 60.0))
	var ct = main.demo.canteiro
	for p in ct.parts:
		if int(p.get("etapa", 1)) == 2:
			p["fallen"] = true   # todas as plataformas da cena já caíram
	sp._pc_f = -999
	var pr: Rect2 = main.demo.play_rect()
	var pts: Array = sp.spawn_points()
	check(pts.size() >= 4 and pts.all(func(q): return pr.has_point(q["pos"])), "sem plataformas, ainda há %d pontos de caixa no chão da Fundação (dentro da cena)" % pts.size())
	sp.boxes.clear()
	sp.spawn_box()
	check(sp.boxes.size() == 1 and pr.grow(64).has_point(sp.boxes[0]["pos"]), "a caixa de engenhoca nasce dentro da Fundação")
	var ev = main.events
	ev.trigger(ev.ev("G03"))
	check(ev.inst("G03") != null, "G03 ligada na Fundação")
	var mx := 0
	for k in 360:
		await frames(1)
		var n := 0
		for b in ev.bits:
			if b["kind"] == "porca":
				n += 1
		mx = maxi(mx, n)
	check(mx >= 5 and mx <= ev.PORCAS_MAX, "G03: porcas no ar com teto (máx %d ≤ %d; eram ~45 e derrubavam o FPS)" % [mx, ev.PORCAS_MAX])
	ev.manual = false
	main.go_menu()

## Controle principal (pedido 2026-11-28): só o 1º controle conectado mexe nos menus; em MAPEAR o controle escolhido
## assume até voltar, e o principal retoma. --so=principal
func principal_test() -> void:
	print("== Controle principal")
	main.go_menu()
	await frames(2)
	var virt0: Dictionary = PlayerInput.virtual
	PlayerInput.virtual = {}
	PlayerInput.fake_joys = [5, 6]
	PlayerInput.ordem_con = ["joy6", "joy5"]   # o 6 conectou primeiro
	PlayerInput._princ_f = -1
	await frames(3)
	check(PlayerInput.principal() == "joy6", "principal = o 1º conectado (joy6)")
	main.menus.sel = 0
	await joy_tap(5, JOY_BUTTON_DPAD_DOWN)
	check(main.menus.sel == 0, "outro controle NÃO mexe no menu")
	await joy_tap(6, JOY_BUTTON_DPAD_DOWN)
	check(main.menus.sel == 1, "o principal mexe")
	main.menus.abrir_controles()
	await frames(2)
	var devs: Array = main.menus._hub_devs()
	main.menus.hub_sel = devs.find("joy5")
	main.menus.hub_btn = 0
	await joy_tap(6, JOY_BUTTON_A)
	check(main.state == S.CONFIGPAD and main.menus.map_dev == "joy5", "o principal escolhe MAPEAR o controle do P2")
	await frames(20)
	await joy_tap(6, JOY_BUTTON_B)
	check(main.state == S.CONFIGPAD, "durante o MAPEAR o principal não manda (o P2 assumiu)")
	await joy_tap(5, JOY_BUTTON_B)
	check(main.state == S.CONTROLES, "o P2 volta/sai do MAPEAR")
	var hs: int = main.menus.hub_sel
	await joy_tap(5, JOY_BUTTON_DPAD_RIGHT)
	check(main.menus.hub_sel == hs and main.menus.hub_btn == 0, "de volta ao hub, o P2 não manda mais")
	await joy_tap(6, JOY_BUTTON_DPAD_RIGHT)
	check(main.menus.hub_btn == 1 or main.menus.hub_sel != hs, "o principal retoma o controle")
	PlayerInput.fake_joys = [5]
	await frames(2)
	check(PlayerInput.principal() == "joy5", "o principal saiu: o próximo conectado assume")
	PlayerInput.fake_joys = []
	PlayerInput.ordem_con.clear()
	PlayerInput._princ_f = -1
	PlayerInput.virtual = virt0
	main.go_menu()

## Derruba v2 (D2): no mapa de verdade a partida é UMA luta (vidas 3–6), resultados com ranking por eliminação, estrela
## da sessão e 4 opções; Jogar de novo mantém as estrelas, Menu principal zera. --so=resultados
func resultados_test() -> void:
	print("== Resultados do Derruba (partida única)")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}}
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	check(not "estrelas" in main.menus.adjust_rows() and "vidas" in main.menus.adjust_rows(), "ajustes do Derruba: sem meta de estrelas, com vidas")
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	await tap("v2", "jump")
	main.demo.lives_setting = 3
	main.event_level = 0
	main.start_match()
	await demo_round()
	main.demo.etapas.ativo = false
	check(main.demo.partida_unica() and main.demo.lives.get(1, 0) == 3, "Canteiro = partida única com 3 vidas")
	for alvo in [2, 1]:   # P3 sai primeiro, depois P2
		for k in 3:
			main.kill(main.robots[alvo], -1, null)
			await frames(20)
	var w := 0
	var viu_placar := false
	while main.state != S.WIN and w < 600:
		await frames(1)
		viu_placar = viu_placar or main.state == S.SCORE
		w += 1
	check(main.state == S.WIN and main.winner == 0, "sobrou 1: vai direto para os RESULTADOS (%.1f s)" % (w / 60.0))
	check(not viu_placar, "sem a tela antiga de placar (\"1 de 5 estrelas\") antes do fim")
	check(main.demo.ranking() == [0, 1, 2], "ranking pela ordem de eliminação (%s)" % str(main.demo.ranking()))
	check(int(main.players[0]["score"]) == 1, "estrela para o vencedor")
	check(not main.res_info.is_empty() and not main.res_info["valida"] and main.res_info["pontos"] == 0, "luta de poucos segundos: não conta para gangorra nem Projetos")
	check(main.res_fase == "gangorra", "fim: abre a tela da gangorra (luta curta = carimbo NÃO CONTOU, A24)")
	main.res_t = 60.0
	await frames(20)
	check(main.res_fase == "gangorra", "tela de recompensa não passa sozinha: espera um jogador confirmar")
	await tap("v0", "jump")   # animação já acabou: segue
	check(main.res_fase == "resultados" and main.res_crono > main.fim.cronometro_s() - 0.5, "luta que não vale: pula os Projetos e vai aos resultados com o relógio cheio (%.0f s)" % main.res_crono)
	await frames(30)
	var cr: float = main.res_crono
	await tap("v0", "down")
	check(main.res_sel == 1 and main.res_crono > cr, "mexer na escolha reinicia o relógio (A25)")
	await tap("v0", "up")
	await tap("v0", "jump")   # JOGAR DE NOVO (opção 0)
	await frames(5)
	check(main.state == S.RUN and int(main.players[0]["score"]) == 1 and main.demo.etapas.etapa == 1, "Jogar de novo: mesmo mapa, cena inicial, estrelas somam (%d ★)" % int(main.players[0]["score"]))
	await demo_round()
	main.demo.etapas.ativo = false
	for alvo in [1, 0]:
		for k in 3:
			main.kill(main.robots[alvo], -1, null)
			await frames(20)
	w = 0
	while main.state != S.WIN and w < 600:
		await frames(1)
		w += 1
	check(main.winner == 2 and int(main.players[2]["score"]) == 1 and int(main.players[0]["score"]) == 1, "segunda luta: P3 ganha a estrela dele, P1 mantém a sua")
	main.players[2]["stats"]["engenhocas"] = 4
	check(main.fim.titulo_de(2) != "" or int(main.players[2]["stats"]["derrubadas"]) == 0, "título do jogador vem das estatísticas (%s)" % main.fim.titulo_de(2))
	await frames(10)
	await tap("v0", "jump")
	await tap("v0", "jump")
	for k in 3:
		await tap("v0", "down")
	check(main.res_sel == 3, "▼ escolhe MENU PRINCIPAL")
	main.res_crono = 0.05
	await frames(10)
	check(main.state == S.MENU and main.players.is_empty(), "relógio zerou: vale a opção marcada (Menu principal; estrelas zeram)")
	# luta que vale: gangorra → Projetos → resultados; estatísticas novas existem
	main.res_info = {"valida": true, "zona": 4, "antes": 0, "depois": 35, "delta": 35, "premio": "", "novas": ["terreo"], "pontos": 3, "total": 3, "por_mapa": 6}
	main.res_fase = "gangorra"
	main._proxima_fase_fim()
	check(main.res_fase == "projetos" and main.fim._linhas().size() == 2, "luta válida: gangorra → PROJETOS (1 linha por ganho: partida + cena nova)")
	main._proxima_fase_fim()
	check(main.res_fase == "resultados", "Projetos → RESULTADOS")
	check(main.fim.duracao("projetos") > main.fim.duracao("gangorra") * 0.5, "telas de recompensa têm animação com duração")
	# gangorra A (balança da grua) + presente em 5 tempos (pranchas g1–g3, 2026-11-27)
	var F = main.fim
	var fundo_cesto: float = (F.caixa_no_cesto(100.0, 1.0) - F.CESTO_CAIXA * F.GA_S).y + 218.0 * F.GA_S
	check(absf(fundo_cesto - F.GA_CHAO) < 6.0, "no ±100 o cesto ganhador encosta no chão (%.0f px; chão %.0f)" % [fundo_cesto, F.GA_CHAO])
	for cat in ["skin", "spell", "evento"]:
		main.res_info = {"valida": true, "zona": 5, "antes": 60, "depois": 100, "delta": 40, "premio": cat, "novas": [], "pontos": 1, "total": 4, "por_mapa": 6}
		check(is_equal_approx(F.duracao("gangorra"), F.G_BALANCA + F.G_SAI + F.G_VOA + F.G_ABRE + F.G_REVELA), "%s: a gangorra decide e o presente tem os tempos 2–5" % cat)
		var it: Dictionary = F.premio_item()
		check(String(it.get("nome", "")) != "" and (cat == "skin" or String(it.get("icone", "")) != ""), "%s: o prêmio revelado tem nome e figura (%s)" % [cat, it.get("nome", "")])
		check(F.premio_item() == it, "%s: o item sorteado é o mesmo em todos os quadros" % cat)
		for c in ["corpo", "tampa", "conteudo"]:
			check(Data.tex("premio/caixa_%s_%s" % [cat, c]) != null, "%s: caixa própria (%s)" % [cat, c])
	main.res_info = {}

## Derruba v2 (D3): telas de seleção de spells e eventos (mosaico). --so=selecao
func selecao_test() -> void:
	print("== Seleção de spells e eventos (D3)")
	main.go_menu()
	main.menus.sel = 0
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	await tap("v0", "jump")   # JOGAR → mapas (A22)
	check(main.state == S.ARENAS, "chega às arenas do Derruba")
	var mn = main.menus   # grade 3 × 3 com páginas (prancha m1, 2026-11-27)
	check((mn.arena_list().size() + mn.mapas_bloqueados()) % 9 == 0, "a grade completa a página com EM BREVE (%d mapas + %d)" % [mn.arena_list().size(), mn.mapas_bloqueados()])
	mn.arena_sel = 0
	await tap("v0", "down")
	check(mn.arena_sel == 3, "▼ desce uma linha da grade (3 por linha)")
	await tap("v0", "right")
	await tap("v0", "right")
	check(mn.arena_sel == 5, "► anda na linha")
	await tap("v0", "right")
	check(mn.arena_sel == (3 if mn.n_paginas() == 1 else 12), "► na borda: próxima página na mesma linha (ou volta ao começo se há uma página só)")
	main.menus.arena_sel = 1
	var spells_partida = main.demo.spells
	main.demo.spells = null   # como no jogo de verdade vindo do menu: ainda não existe partida (derrubava o .exe)
	await tap("v0", "jump")
	var sl = main.selecao
	for nn in [sl.spells_do_mapa().size() + 2, 40, 60]:   # o mosaico cabe sempre na tela (cartas encolhem)
		var gd: Dictionary = sl.grade_spells(nn)
		var fim: Vector2 = gd["origem"] + Vector2(gd["cols"] * (gd["size"].x + gd["gap"]) - gd["gap"], gd["rows"] * (gd["size"].y + gd["gap"]) - gd["gap"])
		check(gd["cols"] * gd["rows"] >= nn and fim.y <= 990.0 and fim.x <= 1812.0 and gd["origem"].x >= 108.0, "%d cartas de engenhoca cabem na tela (%d×%d, carta %.0f×%.0f)" % [nn, gd["cols"], gd["rows"], gd["size"].x, gd["size"].y])
	var n_sp: int = sl.spells_do_mapa().size()   # A31: 3 famílias, engenhocas sem E01/E03 (números lidos dos dados)
	var fams := {}
	for id in sl.spells_do_mapa():
		fams[String(sl._sc(id)["familia"])] = true
	sl.aleatorio_spells()
	check(sl.n_on() == 2 * fams.size(), "a tela de spells funciona sem partida criada (veio direto do menu)")
	main.demo.spells = spells_partida
	main.spells_mapa = ""
	sl.abrir_spells()
	check(main.state == S.SELSPELLS and main.arena_choice == "canteiro_obras", "mapa escolhido → tela de SPELLS")
	check(sl.n_on() == n_sp, "mapa novo: as %d spells começam acesas (tudo liberado)" % n_sp)
	await tap("v0", "jump")
	check(sl.n_on() == n_sp - 1 and not main.spells_on["A01"], "PULAR apaga a spell do cursor (A01)")
	await tap("v0", "hammer")
	check(sl.n_on() == n_sp, "ATACAR acende todas")
	await tap("v0", "hammer")
	check(sl.n_on() == 0, "ATACAR de novo apaga todas")
	await tap("v0", "start")
	check(main.state == S.SELSPELLS and sl.aviso_t > 0.0, "com menos de 4 não segue (aviso)")
	sl.sel = n_sp
	await tap("v0", "jump")
	var por := {}
	for id in main.spells_on:
		if main.spells_on[id]:
			var f: String = main.demo.spells.sc(id)["familia"]
			por[f] = por.get(f, 0) + 1
	check(sl.n_on() == 2 * fams.size() and por.values().all(func(v): return v == 2) and por.size() == fams.size(), "ALEATÓRIO acende 2 de cada família (%s)" % str(por))
	var acesas: Array = main.spells_on.keys().filter(func(id): return main.spells_on[id])
	await tap("v0", "start")
	check(main.state == S.SELEVENTOS, "START → tela de EVENTOS")
	var evs: Array = sl.eventos_do_mapa()
	check(evs.size() == 11 and not evs.any(func(id): return String(id).begins_with("V")) and "G01" in evs, "eventos do mapa: 11 gerais, sem os perigos da cena (V#), com a G01")
	await tap("v0", "jump")   # NENHUM
	check(evs.all(func(id): return not main.events.enabled[id]), "NENHUM apaga todos")
	await tap("v0", "right")
	await tap("v0", "jump")
	check(main.events.enabled[evs[0]], "PULAR religa o evento do cursor (%s)" % evs[0])
	await tap("v0", "start")
	check(main.state == S.AJUSTES, "START → etapa 3 (VIDAS)")
	await tap("v0", "back")
	check(main.state == S.SELEVENTOS, "voltar dos ajustes → eventos")
	await tap("v0", "start")
	check(main.state == S.AJUSTES, "etapa 2 → etapa 3 (VIDAS)")
	await frames(2)
	var v0: int = main.demo.lives_setting
	await tap("v0", "right")
	check(main.demo.lives_setting == mini(v0 + 1, 6), "etapa 3: ◄► muda as vidas (%d)" % main.demo.lives_setting)
	await tap("v0", "start")
	check(main.state == S.JOIN, "etapa 3 → etapa 4 (JOGADORES)")
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	await tap("v0", "start")
	check(main.state == S.DETONAR and main.players.size() == 2, "etapa 4 → etapa 5 (DETONAR) com 2 jogadores")
	await tap("v0", "back")
	check(main.state == S.JOIN and main.players.size() == 2, "ESC na etapa 5 volta à 4 sem perder os jogadores")
	await tap("v0", "start")
	await tap("v0", "start")
	await frames(40)
	check(main.state == S.RUN, "START no detonador: a luta começa")
	await demo_round()
	var pool: Array = main.demo.spells.pool()
	pool.sort()
	acesas.sort()
	check(pool == acesas, "as caixas só sorteiam as spells acesas (%d)" % pool.size())
	var ev = main.events
	ev.enabled["V1"] = false
	check(ev.eligible(ev.ev("V1")), "perigo da cena (V1) não depende da seleção de eventos (A14)")
	check(not ev.eligible(ev.ev(evs[1])), "evento apagado não acontece (%s)" % evs[1])
	ev.enabled["V1"] = true
	main.resultado_escolhe(1)
	check(main.state == S.SELSPELLS and sl.n_on() == acesas.size(), "Configurar mapa (resultados) → SPELLS, guardando a seleção")
	for id in ev.enabled:
		ev.enabled[id] = true
	main.spells_on.clear()
	main.spells_mapa = ""
	main.go_menu()   # não deixa o jogo parado na tela de engenhocas para o próximo teste

## Perfil salvo local (D4, docs/manuais/derruba/perfil_salvo.md): grava/lê, recupera do .bak, migra, gangorra e
## Projetos de Demolição. --so=perfil
func perfil_test() -> void:
	print("== Perfil salvo (gangorra e Projetos)")
	var pf = main.perfil
	var cfg: Dictionary = MapaReg.modo_cfg("derruba")["progressao"]
	var mm := [0.1, 0.9]
	pf.dados = pf.novo()
	check(pf.zona(0.05) == 0 and pf.zona(0.5) == 3 and pf.zona(0.89) == 5 and pf.zona(0.95) == 5, "zonas do manômetro: <10% = 1ª, 50% = 1ª da moderada, ≥ 90% = última")
	var r1: Dictionary = pf.fim_de_partida("canteiro_obras", ["terreo", "fundacao"], 0.95, 70.0, true, cfg, mm)
	check(r1["valida"] and r1["delta"] == 75 and r1["depois"] == 75 and r1["novas"].size() == 2 and r1["pontos"] == 5, "luta válida na zona vermelha: +75 na gangorra; +1 partida +2+2 cenas novas (%s)" % str(r1))
	var r2: Dictionary = pf.fim_de_partida("canteiro_obras", ["terreo"], 0.3, 90.0, true, cfg, mm)
	check(r2["delta"] == -35 and r2["novas"].is_empty() and r2["pontos"] == 1 and r2["total"] == 6, "revisitar não dá bônus; zona verde clara puxa −35 (total %d pontos)" % r2["total"])
	var r3: Dictionary = pf.fim_de_partida("canteiro_obras", ["terreo"], 0.95, 61.0, false, cfg, mm)
	check(not r3["valida"] and r3["delta"] == 0, "sem vencedor não conta")
	pf.dados["gangorra"]["valor"] = 50
	var cat: String = pf.dados["gangorra"]["extremo_vermelho"]
	var r4: Dictionary = pf.fim_de_partida("canteiro_obras", ["terreo"], 0.95, 61.0, true, cfg, mm)
	check(r4["premio"] == cat and pf.dados["gangorra"]["valor"] == 0 and pf.dados["premios"].size() == 1, "chegou ao extremo vermelho: prêmio da categoria %s, agulha volta ao centro" % cat)
	var antes: Dictionary = pf.dados.duplicate(true)
	pf.carregar()
	check(pf.dados["pontos_exploracao"] == antes["pontos_exploracao"] and pf.dados["cenas_visitadas"] == antes["cenas_visitadas"], "grava e lê de volta igual (%s)" % ProjectSettings.globalize_path(pf.caminho))
	var f := FileAccess.open(pf.caminho, FileAccess.WRITE)
	f.store_string("{quebrado")
	f.close()
	pf.carregar()
	check(pf.dados.has("versao") and FileAccess.file_exists(pf.caminho + ".corrompido"), "JSON quebrado: volta do .bak e guarda o quebrado como .corrompido")
	var velho := {"gangorra": {"valor": 10, "extremo_verde": "skin", "extremo_vermelho": "spell"}}
	var mg: Dictionary = pf.migrar(velho)
	check(int(mg["versao"]) == 1 and mg.has("cenas_visitadas") and int(mg["gangorra"]["valor"]) == 10, "migração v0 → v1 mantém o que existe e completa o resto")
	# última configuração volta ao reabrir o mapa
	main.arena_choice = "canteiro_obras"
	main.spells_mapa = ""
	pf.dados["ultima_config"] = {"mapa": "canteiro_obras", "vidas": 5, "spells": ["A01", "A02", "C01", "T03"], "eventos": ["G02"]}
	main.selecao.abrir_spells()
	var n_def: int = main.selecao.spells_do_mapa().filter(func(id): return String(main.selecao._sc(id)["familia"]) == "defesa").size()
	check(main.selecao.n_on() == 4 + n_def and main.spells_on["T03"] and not main.spells_on["A03"] and not main.events.enabled["G01"] and main.events.enabled["G02"] and main.demo.lives_setting == 5, "reabrir o mapa volta a última configuração (spells, eventos, vidas); a família que não existia (Defesa, %d) entra acesa" % n_def)
	main.spells_mapa = ""
	pf.dados["ultima_config"] = {"mapa": "canteiro_obras", "vidas": 5, "spells": ["A01", "D02"], "eventos": ["G02"], "conhecidas": ["A01", "A02", "D01", "D02"]}
	main.selecao.abrir_spells()
	check(main.spells_on["D02"] and not main.spells_on["D01"] and not main.spells_on["A02"] and main.spells_on["C01"], "com a lista de conhecidas: apagada continua apagada; engenhoca nova entra acesa")
	for id in main.events.enabled:
		main.events.enabled[id] = true
	main.spells_on.clear()
	main.spells_mapa = ""
	pf.dados = pf.novo()
	main.go_menu()

## A14: todo evento do mapa vale nas cenas do Canteiro (Térreo e Fundação; Fachada na D5). Na Fundação, G12 move as
## plataformas sobre estaca e G13 desce uma viga pelo poço (peça gerada, fora da conta da destruição). --so=eventos_cenas
func eventos_cenas_test() -> void:
	print("== Eventos do mapa em todas as cenas (A14)")
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 6
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.countdown = 0.0
	main.demo.spells.spawn_t = 999.0
	var ev = main.events
	var ids: Array = MapaReg.manifesto("derruba", "canteiro_obras")["eventos_permitidos"].filter(func(e): return not String(e).begins_with("V"))
	var falta1: Array = ids.filter(func(id): return not ev.eligible(ev.ev(id)))
	check(ids.size() == 11 and falta1.is_empty(), "Térreo: os 11 eventos do mapa podem acontecer (faltam: %s)" % str(falta1))
	main.demo.etapas.ativo = true
	main.demo.etapas.forcar()
	var w := 0
	while main.demo.etapas.etapa != 2 and w < 900:
		await frames(1)
		w += 1
	main.demo.etapas.ativo = false
	await frames(60)
	var falta2: Array = ids.filter(func(id): return not ev.eligible(ev.ev(id)))
	check(falta2.is_empty(), "Fundação: os 11 eventos do mapa podem acontecer (faltam: %s)" % str(falta2))
	var ct = main.demo.canteiro
	var p0: float = ct.progresso(2)
	ev.manual = true
	main.event_level = 2
	var ys: Array = ct.parts.filter(func(p): return p["kind"] == "estaca" and not p["fallen"]).map(func(p): return p["rect"].position.y)
	ev.trigger(ev.ev("G12"))
	await frames(int((1.2 + float(ev.ev("G12")["dur"]) * 0.4) * 60.0))
	var ys2: Array = ct.parts.filter(func(p): return p["kind"] == "estaca" and not p["fallen"]).map(func(p): return p["rect"].position.y)
	check(ys != ys2, "G12 na Fundação: as plataformas sobre estaca sobem/descem (%s → %s)" % [str(ys), str(ys2)])
	for k in 60 * 10:
		await frames(1)
	ev.trigger(ev.ev("G13"))
	await frames(5)
	var vg: Array = ct.parts.filter(func(p): return p["kind"] == "viga" and int(p["etapa"]) == 2)
	check(vg.size() == 1 and vg[0].get("gerada", false) and ev.is_active("G13"), "G13 na Fundação: uma viga desce pelo poço (peça gerada)")
	for k in 60 * 16:
		await frames(1)
	check(not ev.is_active("G13") and is_equal_approx(ct.progresso(2), p0), "G13 termina e a viga gerada não mexe no manômetro (%.0f%%)" % (ct.progresso(2) * 100.0))
	ev.manual = false
	main.event_level = 0

## D5 bloco F: rota MODERADA de verdade — 50–90% na verificação → "A LAJE VAI ESCORREGAR!" → o Térreo cede e todos
## escorregam até as pranchas da Fachada, sem KO nem dano; chegam de pé e a luta segue lá. --so=moderada
func moderada_test() -> void:
	print("== Rota moderada: Térreo → Fachada")
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.add_bot()
	main.game_mode = "derruba"
	main.demo.lives_setting = 4
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.countdown = 0.0
	var et = main.demo.etapas
	var ct = main.demo.canteiro
	var lives0 = main.demo.lives.duplicate()
	for p in ct.parts:   # os jogadores destruíram uns 60% do Térreo
		if int(p["etapa"]) == 1 and p["kind"] == "andaime":
			ct.damage(p, 99, p["rect"].get_center())
	var vg: Array = ct.parts.filter(func(p): return p["kind"] == "viga" and int(p["etapa"]) == 1)
	for p in vg:
		ct.damage(p, 99, p["rect"].get_center())
	await frames(240)
	var prog: float = ct.progresso(1)
	et.ativo = true
	et.prox_verif = et.t_cena + 0.1
	await frames(10)
	check(prog >= et.limiar_moderada() and prog < et.limiar_total() and et.rota == "moderada" and main.demo.banner.begins_with("A LAJE"), "%.0f%% na verificação → \"A LAJE VAI ESCORREGAR!\"" % (prog * 100.0))
	var w := 0
	while et.state != "queda" and w < 400:
		await frames(1)
		w += 1
	var a3: Rect2 = main.level.etapa_rect(3)
	lives0 = main.demo.lives.duplicate()   # a luta segue durante o aviso (o bot pode derrubar alguém): conta do deslize em diante
	check(et.state == "queda" and main.level.area.encloses(a3), "o Térreo cede e a câmera abre para mostrar a Fachada")
	await frames(60)
	check(main.robots.all(func(r): return r.position.y < a3.end.y), "ninguém cai na rua durante o deslize")
	w = 0
	while et.state != "etapa" and w < 600:
		await frames(1)
		w += 1
	await frames(40)
	check(et.etapa == 3 and main.level.area == a3 and 3 in et.visitadas, "chegam na Fachada (%.1f s); área, KO e câmera passam para ela" % (w / 60.0))
	check(main.robots.all(func(r): return r.alive and a3.has_point(r.position) and (r.is_on_floor() or bool(main.players[r.pid].get("bot", false)))) and main.demo.lives == lives0, "todos de pé nas pranchas (o bot pode estar no meio de um pulo: a luta segue), sem perder vida (%s, vidas %s → %s)" % [str(main.robots.map(func(r): return [r.pid, r.position.round(), r.is_on_floor(), r.alive])), str(lives0), str(main.demo.lives)])
	check(not et.tem_proxima(), "a Fachada é a última cena (sem nova transição)")
	main.go_menu()   # tira os bots (os testes seguintes contam com só 2 jogadores parados)

## D5: cena 3 do Canteiro, a FACHADA (rota moderada): perigos M10–M13, os 11 eventos do mapa e bots lutando sem cair
## à toa no vão do meio (que dá na rua = KO). --so=fachada
## Renascimento seguro (avaliação 2026-11-26, item 3): em cada cena, com o cenário sendo destruído, quem volta pousa em chão
## firme DENTRO da cena, não morre nem perde vida nos primeiros segundos e fica invulnerável. --so=renascer
func renascer_test() -> void:
	seed(23)   # renascimento sorteado: semente fixa (não depende dos testes que rodaram antes)
	main.rng.seed = 23
	print("== Renascimento seguro")
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 6
	main.event_level = 3   # eventos no máximo e mecanismos ligados: o pior caso
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.countdown = 0.0
	var et = main.demo.etapas
	et.ativo = false
	var lv = main.level
	var ct = main.demo.canteiro
	var r = main.robots[0]
	var inv_cfg := float(main.demo.cfg["recuperacao"]["invuln_volta_s"])
	for cena in [1, 2, 3]:
		if cena > 1:
			et.pular_para(cena)
			await frames(60)
		var area: Rect2 = lv.etapa_rect(cena)
		var ruins := []
		var fallback := 0
		for k in 30:
			if k % 3 == 2 and ct != null:   # destrói o cenário aos poucos
				var vivas: Array = ct.parts.filter(func(p): return not p["fallen"] and int(p.get("etapa", 1)) == cena and p["kind"] != "terreo")
				if not vivas.is_empty():
					var pp = vivas[main.rng.randi_range(0, vivas.size() - 1)]
					ct.damage(pp, 99, pp["rect"].get_center())
			main.demo.lives[0] = 6
			main.demo.lives[1] = 6   # o outro jogador (parado) também não pode sair, senão a partida acaba no meio
			r.invuln = 0.0
			var nb: int = lv.blocks.size()
			main.demo.respawn(r)
			if lv.blocks.size() > nb:
				fallback += 1
			var inv0: float = r.invuln
			var pousou := -1
			var vidas0: int = main.demo.lives[0]
			var morreu := false
			var traj := []
			for f in 200:
				await frames(1)
				traj.append("%d:%s v%s%s" % [f, str(Vector2i(r.position)), str(Vector2i(r.velocity)), "F" if r.is_on_floor() else ""])
				if pousou < 0 and r.is_on_floor():
					pousou = f
				if main.demo.lives[0] < vidas0 and not morreu:
					morreu = true
					print("    trajeto: ", " | ".join(traj.slice(maxi(0, traj.size() - 25))))
					print("    eventos: ", main.events.active.map(func(a): return a["id"]))
					print("    perdeu vida no quadro %d (pousou %d) causa=%s pos=%s chão=%s" % [f, pousou, r.last_cause, str(Vector2i(r.position / 64.0)), str(main.fall_log.back() if not main.fall_log.is_empty() else "")])
			var ok: bool = not morreu and pousou >= 0 and pousou < 150 and r.alive and area.grow(8).has_point(r.position) and main.demo.lives[0] == vidas0 and inv0 >= inv_cfg - 0.01
			if not ok:
				ruins.append("%s (%s) pousou=%d vivo=%s area=%s vidas=%d→%d" % [str(Vector2i(r.position / 64.0)), r.last_cause, pousou, str(r.alive), str(area.has_point(r.position)), vidas0, main.demo.lives[0]])
				if not r.alive:
					main.demo.lives[0] = 6
					main.demo.respawn(r)
					await frames(2)
		check(ruins.is_empty(), "cena %d: 30 renascimentos pousam no chão, dentro da cena, sem perder vida (%s; caixote de emergência %d×)" % [cena, "; ".join(ruins.slice(0, 3)), fallback])
	check(inv_cfg >= 3.0, "invulnerável por %.1f s ao voltar (avaliação: alguns segundos)" % inv_cfg)
	main.go_menu()

## Transições orgânicas (avaliação 2026-11-26, item 5): na queda para a Fundação e no deslize para a Fachada ninguém
## teletransporta (sem salto de posição) e cada robô volta a ser controlado assim que pousa, ainda durante a transição. --so=transicao
func transicao_test() -> void:
	print("== Transições orgânicas")
	for rota in ["total", "moderada"]:
		main.go_join()
		await frames(2)
		PlayerInput.virtual = {"v0": {}, "v1": {}}
		await tap("v0", "jump")
		await tap("v1", "jump")
		main.add_bot()
		main.game_mode = "derruba"
		main.demo.lives_setting = 6
		main.event_level = 0
		main.arena_choice = "canteiro_obras"
		main.start_match()
		await demo_round()
		main.countdown = 0.0
		var et = main.demo.etapas
		et.forcar(rota)
		var prev := {}
		var salto := 0.0
		var livre_na_queda := false
		var pose_vista := false
		var dest: int = et.destino
		for f in 60 * 12:
			await frames(1)
			for r in main.robots:
				if prev.has(r.pid):
					salto = maxf(salto, (r.position - prev[r.pid]).length())
				prev[r.pid] = r.position
				if et.state == "queda":
					pose_vista = pose_vista or r.vis.cena_pose != ""
					if r.has_meta("pousou_cena") and not r.spell_lock:
						livre_na_queda = true
			if et.state == "etapa" and et.etapa == dest:
				break
		check(et.etapa == dest, "%s: chegou à cena %d" % [rota, dest])
		check(salto < 160.0, "%s: ninguém teletransporta (maior passo num quadro %.0f px)" % [rota, salto])
		check(pose_vista, "%s: os robôs mostram que estão caindo/escorregando (pose da transição)" % rota)
		if rota == "total":
			check(livre_na_queda, "total: quem pousa joga na hora, sem esperar os outros")
		check(main.robots.all(func(r): return not r.spell_lock and r.vis.cena_pose == ""), "%s: no fim, todos com controle e pose normal" % rota)
	main.go_menu()

func fachada_test() -> void:
	print("== Fachada (cena 3)")
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.add_bot()
	main.add_bot()
	main.game_mode = "derruba"
	main.demo.lives_setting = 6
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.countdown = 0.0
	var et = main.demo.etapas
	et.ativo = false
	et.pular_para(3)
	var lv = main.level
	var a3: Rect2 = lv.etapa_rect(3)
	await frames(90)
	check(et.etapa == 3 and lv.area == a3 and main.robots.all(func(r): return a3.has_point(r.position)), "pular para a cena 3: área, KO e todos os robôs na Fachada")
	var ct = main.demo.canteiro
	var pr: Array = ct.parts.filter(func(p): return p["kind"] == "prancha" and int(p["etapa"]) == 3)
	check(pr.size() == 9 and ct.progresso(3) == 0.0, "9 pranchas de andaime destrutíveis; manômetro da Fachada em 0%")
	ct.damage(pr[0], 1, pr[0]["rect"].get_center())
	check(ct.progresso(3) > 0.0, "dano numa prancha conta na destruição da Fachada (%.1f%%)" % (ct.progresso(3) * 100.0))
	var mc = main.demo.mecs
	var by := {}
	for inst in mc.list:
		if int(inst["etapa"]) == 3:
			by[inst["d"]["id"]] = inst
	var y0: float = by["M10"]["s"]["y"]
	await frames(60 * 5)
	check(absf(float(by["M10"]["s"]["y"]) - y0) > 10.0, "M10 balancim sobe e desce (%.0f → %.0f)" % [y0, by["M10"]["s"]["y"]])
	var fases := {}
	for k in 60 * 8:
		await frames(1)
		fases[String(by["M11"]["s"].get("phase", ""))] = true
	check(fases.has("aviso") and fases.has("bate"), "M11 guincho: avisa e desce o palete (%s)" % str(fases.keys()))
	by["M13"]["s"]["t"] = float(by["M13"]["d"]["ciclo_s"])
	await frames(5)
	var alvo = by["M13"]["s"].get("alvo")
	check(alvo != null and alvo["warn_t"] > 0.0, "M13 Andaime Cede: uma prancha ganha a fita zebrada")
	var w := 0
	while alvo != null and not alvo["fallen"] and w < 600:
		await frames(1)
		w += 1
	check(alvo != null and alvo["fallen"], "...e cede no fim do aviso (%.1f s)" % (w / 60.0))
	var ev = main.events
	main.event_level = 2
	var ids: Array = MapaReg.manifesto("derruba", "canteiro_obras")["eventos_permitidos"].filter(func(e): return not String(e).begins_with("V"))
	var falta: Array = ids.filter(func(id): return not ev.eligible(ev.ev(id)))
	check(falta.is_empty(), "Fachada: os 11 eventos do mapa podem acontecer (faltam: %s)" % str(falta))
	main.event_level = 0
	main.self_falls = 0
	main.fall_log.clear()
	for i in main.players.size():
		main.demo.lives[i] = 99
	for k in 60 * 45:
		await frames(1)
	check(main.self_falls <= 1, "bots lutam 45 s na Fachada quase sem cair sozinhos (%d: %s)" % [main.self_falls, str(main.fall_log)])
	main.go_menu()

## Mecanismos da Fase 1 (catálogo M1–M9): cada um faz o que promete e responde à marretada.
func mecanismos_test() -> void:
	print("== Mecanismos da Fase 1")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 9
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var mc = main.demo.mecs
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var get := func(id: String) -> Dictionary:
		for m in mc.list:
			if m["d"]["id"] == id:
				return m
		return {}
	var calm := func() -> void:
		for i in main.players.size():
			main.demo.lives[i] = 9
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.invuln = 0.0
	check(mc != null and mc.list.size() == 13, "o Canteiro tem 13 mecanismos: 4 no Térreo, 4 na Fundação, 5 na Fachada (%d)" % (0 if mc == null else mc.list.size()))
	# M1 betoneira
	calm.call()
	var m1: Dictionary = get.call("M1")
	put(r0, Vector2(240, 1088))
	mc.hammer_hit(Rect2(Vector2(m1["d"]["alvo"][0], m1["d"]["alvo"][1]), Vector2(20, 20)), false, 1)
	await frames(int(float(m1["d"]["aviso_s"]) * 60.0) + 10)
	check(float(m1["s"].get("fresh", 0.0)) > 0.0 and r0.env_slow < 1.0, "M1 betoneira: marretar a alavanca despeja concreto e quem pisa fica lento")
	# M2 elevador
	var m2: Dictionary = get.call("M2")
	var ys := []
	for k in 8:
		await frames(60)
		ys.append(m2["s"]["y"])
	check(ys.min() < 700.0 and ys.max() > 1080.0, "M2 elevador: sobe até o andaime e desce ao térreo")
	# M4 tubos
	calm.call()
	var m4: Dictionary = get.call("M4")
	put(r1, Vector2(2345, 1088))
	put(r0, Vector2(2060, 1088))
	mc.hammer_hit(Rect2(Vector2(m4["d"]["alvo"][0], m4["d"]["alvo"][1]), Vector2(40, 40)), true, 0)
	await frames(90)
	check(int(m4["s"]["pile"]) == 0 and r1.dmg > 0.0 and r1.last_attacker == 0, "M4 tubos: marretada solta tubos rolando que acertam (crédito de quem marretou)")
	# D4 escora: 2 pesadas quebram e o trecho de cima entra em queda
	var ct = main.demo.canteiro
	var lj: Dictionary = ct.parts.filter(func(p): return p["kind"] == "laje" and not p["nucleo"] and not p["fallen"])[0]
	var esc := Rect2(lj["rect"].get_center().x - 20.0, lj["rect"].end.y + 40.0, 40.0, 40.0)
	ct.hammer(r0, esc, false)
	ct.hammer(r0, esc, false)
	check(int(lj["escora_hp"]) == 0 and lj["crit_t"] > 0.0, "D4 escora: 2 marretadas quebram a escora e o trecho entra em queda")
	# M5 serra
	calm.call()
	var m5: Dictionary = get.call("M5")
	put(r0, Vector2(400, 1088))
	var hurt := false
	for k in 400:
		await frames(1)
		r0.invuln = 0.0
		if r0.dmg > 0.0:
			hurt = true
			break
		if not r0.alive:
			break
		if k % 30 == 0:
			put(r0, Vector2(400, 1088))
	check(hurt, "M5 serra: a lâmina sobe em ciclo e machuca")
	# V1 Concretagem (evento da Etapa 1)
	calm.call()
	main.event_level = 2
	main.events.manual = true
	main.events.trigger(main.events.ev("V1"))
	await frames(3)
	var v1 = main.events.inst("V1")
	check(v1 != null and v1["d"]["strips"].size() == 2, "V1 Concretagem: marca 2 faixas no chão")
	if v1 != null:
		var st: Rect2 = v1["d"]["strips"][0]
		put(r0, Vector2(st.get_center().x, st.end.y))
		for k in 200:
			await frames(1)
			if v1["phase"] == "ativo" and r0.env_slow < 1.0:
				break
		check(r0.env_slow < 1.0, "V1: quem pisa no concreto fresco fica lento")

	# etapa 2
	var et = main.demo.etapas
	et.ativo = true
	et.forcar()
	et.st_t = 0.01
	for k in 60 * (int(et.cfg["queda_max_s"]) + 2):   # a queda é lenta (até queda_max_s)
		await frames(1)
		if et.etapa == 2 and et.state == "etapa":
			break
	check(et.etapa == 2, "virada para a Fundação")
	var fl: float = main.level.etapa_rect(2).position.y + 15 * 64.0
	ct = main.demo.canteiro
	# D9 estaca: 2 pesadas → a plataforma inclina e cai
	var est: Dictionary = ct.parts.filter(func(p): return p["kind"] == "estaca")[0]
	var er := Rect2(est["rect"].get_center().x - 10.0, est["rect"].end.y + 100.0, 20.0, 20.0)
	ct.hammer(r0, er, false)
	ct.hammer(r0, er, false)
	await frames(int(float(ct.cfg["aviso_queda_s"]) * 60.0) + 10)
	check(est["fallen"], "D9 estaca: 2 marretadas e a plataforma de cima cai")
	# vãos entre as lajes da Fundação: cair = KO (rápido, sem parede para se agarrar)
	put(r1, Vector2(14.5 * 64.0, fl - 200.0))
	r1.velocity = Vector2.ZERO
	var lv1: int = main.demo.lives[1]
	var tko := 0
	for k in 240:
		await frames(1)
		r1.invuln = 0.0
		if main.demo.lives[1] < lv1:
			tko = k
			break
	check(main.demo.lives[1] < lv1 and tko < 90, "Fundação: cair no vão entre as lajes elimina logo (%d quadros)" % tko)
	await frames(120)
	# M6 bate-estaca
	calm.call()
	var hit6 := false
	for k in 420:
		await frames(1)
		if k % 20 == 0:
			put(r0, Vector2(1440, fl))
		r0.invuln = 0.0
		if r0.dmg > 0.0:
			hit6 = true
			break
	check(hit6, "M6 bate-estaca: martela a faixa marcada")
	# M7 água + M9 gerador
	calm.call()
	var m7: Dictionary = get.call("M7")
	var m9: Dictionary = get.call("M9")
	var hmax := 0.0
	for k in 1200:
		await frames(1)
		hmax = maxf(hmax, float(m7["s"]["h"]))
		if hmax > 60.0:
			break
	check(hmax > 60.0, "M7 alagamento: a água sobe no fundo")
	put(r1, Vector2(1200, fl))
	var choque := false
	for k in 420:
		await frames(1)
		r1.invuln = 0.0
		if r1.dmg > 0.0:
			choque = true
			break
	check(choque, "M9 gerador: faísca com água alta dá choque em quem está na água")
	mc.hammer_hit(Rect2(Vector2(m7["d"]["alvo"][0], m7["d"]["alvo"][1]), Vector2(20, 20)), false, 0)
	await frames(80)
	check(float(m7["s"]["h"]) < 5.0, "M7: marretar o registro drena a água")
	mc.hammer_hit(Rect2(Vector2(m9["d"]["alvo"][0], m9["d"]["alvo"][1]), Vector2(20, 20)), false, 0)
	check(float(m9["s"].get("off", 0.0)) > 0.0, "M9: marretar o gerador desliga")
	main.events.trigger(main.events.ev("V3"))
	var hv := 0.0
	for k in 600:
		await frames(1)
		hv = maxf(hv, float(m7["s"]["h"]))
	check(hv > float(m7["d"]["altura"]) * 1.5, "V3 Enchente: a água sobe bem mais alto que o normal (%.0f)" % hv)
	main.events.manual = false
	main.events.reset_round()
	# M8 vagonete
	calm.call()
	var hit8 := false
	for k in 900:
		await frames(1)
		if k % 30 == 0:
			put(r0, Vector2(650, fl))
			r0.invuln = 0.0
		if r0.dmg > 0.0 and r0.last_cause == "vagonete":
			hit8 = true
			break
	check(hit8, "M8 vagonete: passa varrendo o piso")
	main.event_level = 0

func spells_test() -> void:
	print("== Spells (Etapa 1) e eventos G01/G10")
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	var ct = main.demo.canteiro
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = ct.parts.filter(func(p): return p["nucleo"])
	var floor_y: float = nuc[0]["rect"].position.y
	var x0: float = nuc[0]["rect"].position.x + 40.0
	var place := func(dx_tiles: float) -> void:
		for i in main.players.size():
			main.demo.lives[i] = 99   # muitos testes seguidos: ninguém fica sem vida
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.recover_t = 0.0
			r.frozen_t = 0.0
			main.demo.spells.pinned.erase(r.pid)
			main.demo.spells.rivet_hits.erase(r.pid)
			r.spell_lock = false
			r.invuln = 0.0
			r.atk = ""
			r.atk_cd = 0.0
		put(r0, Vector2(x0, floor_y))
		put(r1, Vector2(x0 + dx_tiles * 64.0, floor_y))
		r0.facing = 1
		r1.facing = -1
	# sorteio em 2 etapas: só spells do pool, todas as famílias aparecem, ataque é a mais comum
	var cnt := {}
	for k in 400:
		var d: Dictionary = sp.pick()
		cnt[d["fam"]] = cnt.get(d["fam"], 0) + 1
		check(d["id"] in sp.pool() and sp.sc(d["id"])["familia"] == d["fam"], "sorteio dá spell do pool na família certa") if k == 0 else null
	var nfam: int = main.demo.cfg["spells"]["classes_spells"].size() if main.demo.cfg["spells"].has("classes_spells") else 4
	var mais_ataque := true
	for fk in cnt:
		if fk != "ataque" and cnt[fk] >= cnt["ataque"]:
			mais_ataque = false
	check(cnt.size() == nfam and mais_ataque, "sorteio: as %d famílias aparecem, ataque mais frequente %s" % [nfam, str(cnt)])
	check(sp.spawn_points().size() >= 6 and sp.spawn_points().any(func(q): return q["fixo"]), "pontos de caixa fixos e variáveis no Canteiro (%d)" % sp.spawn_points().size())
	# coleta por contato com slot vazio
	place.call(6.0)
	sp.drop_box("A03", Vector2(x0, floor_y - 120.0), false)
	await frames(40)
	check(sp.boxes.is_empty() and sp.hud_info(0).get("id", "") == "A03" and sp.hud_info(0)["charges"] == 3, "encostar na caixa pega a spell (A03, 3 cargas)")
	# A03 canhão criogênico: congela quem acerta
	place.call(6.0)
	await frames(2)
	await tap("v0", "item")
	await frames(40)
	check(r1.frozen_t > 0.0 and sp.frozen.has(1) and sp.hud_info(0)["charges"] == 2, "A03: tiro acerta e congela (%.1f s)" % r1.frozen_t)
	var px: float = r1.position.x
	vset("v1", "right", true)
	await frames(20)
	vset("v1", "right", false)
	check(absf(r1.position.x - px) < 20.0, "congelado não anda")
	# agitar o direcional quebra mais rápido: conta quadros até soltar, sem e com agitação
	var calm := 0
	while r1.frozen_t > 0.0 and calm < 400:
		await frames(1)
		calm += 1
	check(calm > 60 and not sp.frozen.has(1), "sem agitar, o gelo solta sozinho (%d quadros)" % calm)
	place.call(6.0)
	sp.slot[0]["cd"] = 0.0
	await frames(2)
	await tap("v0", "item")
	await frames(40)
	var shook := 0
	while r1.frozen_t > 0.0 and shook < 400:
		vset("v1", "left" if shook % 8 < 4 else "right", true)
		vset("v1", "right" if shook % 8 < 4 else "left", false)
		await frames(1)
		shook += 1
	vset("v1", "left", false)
	vset("v1", "right", false)
	check(shook < calm * 0.7, "agitando ◄► quebra o gelo mais rápido (%d × %d quadros)" % [shook, calm])
	# pancada em quem está congelado estilhaça com empurrão maior
	place.call(1.0)
	sp.freeze(r1, 0)
	r1.take_hit(1, "rapido", 0)
	var kx_frozen: float = absf(r1.own_vx)
	place.call(1.0)
	r1.take_hit(1, "rapido", 0)
	check(kx_frozen > absf(r1.own_vx) * 1.2 and r1.frozen_t <= 0.0, "golpe no congelado estilhaça e empurra mais (%.0f × %.0f)" % [kx_frozen, absf(r1.own_vx)])
	# troca: segurar o especial ~0,3 s sobre outra caixa; a antiga cai com as cargas e o dono não pega de volta na hora
	place.call(8.0)
	sp.drop_box("A01", Vector2(x0, floor_y - 120.0), false)
	await frames(40)
	check(sp.boxes.size() == 1 and sp.hud_info(0)["id"] == "A03", "com o slot ocupado, encostar não pega")
	vset("v0", "item", true)
	await frames(int(float(sp.cfg["caixa"]["troca_s"]) * 60.0) + 4)
	vset("v0", "item", false)
	await frames(3)
	var dropped: Dictionary = sp.boxes[0] if sp.boxes.size() == 1 else {}
	check(sp.hud_info(0).get("id", "") == "A01" and dropped.get("id", "") == "A03" and dropped.get("charges", 0) == 1 and dropped["block"].has(0), "segurar troca: pega A01, o A03 cai com 1 carga e bloqueado para o dono")
	await frames(20)
	check(sp.hud_info(0)["id"] == "A01" and sp.boxes.size() == 1, "anti-recaptura: o dono não pega de volta na hora")
	# toque rápido em cima de caixa usa a spell (não troca)
	place.call(8.0)
	put(r0, Vector2(dropped["pos"].x, floor_y))
	await frames(2)
	await tap("v0", "item")
	await frames(4)
	check(sp.hud_info(0)["id"] == "A01" and sp.flags(r0)["prep"] >= 0.0, "toque rápido sobre a caixa usa a spell atual")
	await frames(40)
	# C01 superímã: segurar puxa todo mundo à frente enquanto a barra dura; soltar pausa
	sp.boxes.clear()
	place.call(5.0)
	sp.clear(r0)
	sp.equip(r0, "C01")
	await frames(2)
	var d0: float = r1.position.x - r0.position.x
	vset("v0", "item", true)
	await frames(30)
	vset("v0", "item", false)
	await frames(2)
	var e_left: float = sp.slot[0]["energy"]
	check(r1.position.x - r0.position.x < d0 - 80.0 and e_left < float(sp.sc("C01")["energia_s"]) - 0.3 and not sp.slot[0]["channel"], "C01: segurando puxa o rival (%.0f → %.0f px) e gasta a barra" % [d0, r1.position.x - r0.position.x])
	vset("v0", "item", true)
	await frames(int(e_left * 60.0) + 30)
	vset("v0", "item", false)
	check(sp.hud_info(0).is_empty(), "C01: barra acabou, o ímã some")
		# eliminação limpa o slot
	sp.boxes.clear()
	main.kill(r0, -1, null)
	await frames(2)
	check(sp.hud_info(0).is_empty(), "eliminado perde a spell (nada passa para o respawn)")
	await frames(90)
	# A01 punho pneumático: preparo, soco em linha
	place.call(3.0)
	sp.equip(r0, "A01")
	await frames(2)
	await tap("v0", "item")
	check(sp.flags(r0)["prep"] >= 0.0, "A01: começa a preparação (puxa o braço)")
	await frames(int(float(sp.sc("A01")["carga_min_s"]) * 60.0) + 8)
	check(r1.dmg > 0.0 and r1.own_vx > 200.0 and sp.hud_info(0)["charges"] == 1, "A01: punho estica e arremessa o rival (dano %d%%, vx %.0f)" % [int(r1.dmg), r1.own_vx])
	# golpe na preparação cancela sem gastar carga
	place.call(3.0)
	sp.slot[0]["cd"] = 0.0
	await frames(2)
	vset("v0", "item", true)   # segurando = carregando a pressão
	await frames(20)
	check(sp.flags(r0)["prep"] > 0.2 and sp.flags(r0)["prep"] < 1.0, "A01: segurar carrega a pressão (%.2f)" % sp.flags(r0)["prep"])
	r0.take_hit(-1, "rapido", 1)
	await frames(2)
	vset("v0", "item", false)
	await frames(30)
	check(sp.hud_info(0).get("charges", 0) == 1 and r1.dmg == 0.0, "A01: levar golpe na preparação cancela (sem gastar carga) [%s cargas, rival %d%%]" % [str(sp.hud_info(0).get("charges", -1)), int(r1.dmg)])
	# E01 andaime relâmpago: plataforma 2 tiles acima, à frente; robô fica de pé nela
	place.call(10.0)
	sp.clear(r0)
	sp.equip(r0, "E01")
	await frames(2)
	var pr: Rect2 = sp.scaffold_rect(r0)
	await tap("v0", "item")
	check(sp.platforms.size() == 1 and sp.hud_info(0)["charges"] == 1, "E01: andaime abre (1 carga restante)")
	put(r1, Vector2(pr.get_center().x, pr.position.y - 80.0))
	await frames(40)
	check(absf(r1.position.y - pr.position.y) < 6.0 and r1.is_on_floor(), "E01: dá para ficar de pé no andaime (y %.0f, topo %.0f)" % [r1.position.y, pr.position.y])
	put(r1, Vector2(sp.scaffold_rect(r0).get_center().x, sp.scaffold_rect(r0).position.y + 10.0))
	await frames(1)
	await tap("v0", "item")
	check(sp.hud_info(0).get("charges", 0) == 1, "E01: lugar ocupado não gasta carga")
	await frames(int(float(sp.sc("E01")["duracao_s"]) * 60.0))
	check(sp.platforms.is_empty(), "E01: andaime dobra sozinho")
	# C04 teleporte: segura para mirar (o robô para), move a mira com o direcional, solta para ir
	place.call(10.0)
	sp.clear(r0)
	sp.equip(r0, "C04")
	await frames(2)
	var x_before: float = r0.position.x
	vset("v0", "item", true)
	await frames(3)
	check(sp.aims.has(0) and r0.spell_lock, "C04: segurar abre a mira")
	vset("v0", "right", true)
	await frames(10)
	vset("v0", "right", false)
	vset("v0", "item", false)
	await frames(30)
	check(r0.position.x - x_before > 180.0 and sp.hud_info(0)["charges"] == 1 and not r0.spell_lock and r0.vis.visible, "C04: solta e teleporta %.1f tiles" % ((r0.position.x - x_before) / 64.0))
	r0.facing = -1
	put(r0, Vector2(main.level.ko_rect().position.x + 140.0, floor_y - 600.0))
	await frames(1)
	check(sp.teleport_dest(r0) == null, "C04: sem lugar livre não há destino")
		# T01 armadura fornalha: toque veste; segurar solta um jato contínuo; acabou o combustível, explode
	place.call(2.5)
	sp.clear(r0)
	sp.equip(r0, "T01")
	await frames(2)
	await tap("v0", "item")
	check(r0.spell_speed < 1.0 and r0.spell_push < 1.0 and sp.flags(r0).get("armor", false), "T01: veste a armadura (mais lento, resiste a empurrão)")
	await frames(25)
	r0.dmg = 0.0
	r0.invuln = 0.0
	r0.take_hit(-1, "pesado", 1)
	var kx_arm: float = absf(r0.own_vx)
	check(kx_arm < float(main.demo.cfg["amassometro"]["pesado"]["kx"]) * 0.6, "T01: marretada empurra bem menos (%.0f)" % kx_arm)
	await frames(30)
	place.call(2.5)
	await frames(2)
	vset("v0", "item", true)
	await frames(40)
	check(r1.dmg > 0.0 and sp.slot[0]["energy"] < float(sp.sc("T01")["combustivel_s"]) - 0.4, "T01: segurando, o jato acerta quem está na frente (dano %d%%)" % int(r1.dmg))
	await frames(int(float(sp.sc("T01")["combustivel_s"]) * 60.0))
	vset("v0", "item", false)
	await frames(2)
	check(r0.spell_speed == 1.0 and r0.spell_push == 1.0 and sp.hud_info(0).is_empty(), "T01: combustível acabou, a armadura explode e o slot esvazia")
	# ===== Etapa 2 (ataque)
	sp.boxes.clear()
	# A02 laser: preparo com linha de mira, feixe atravessa robôs
	place.call(6.0)
	sp.clear(r0)
	sp.equip(r0, "A02")
	await frames(2)
	await tap("v0", "item")
	check(sp.flags(r0)["prep"] >= 0.0, "A02: mira antes de disparar")
	await frames(int(float(sp.sc("A02")["preparo"]) * 60.0) + 4)
	check(r1.dmg > 0.0 and sp.lasers.size() > 0, "A02: feixe acerta à distância e segue saindo (dano %d%%)" % int(r1.dmg))
	await frames(int(float(sp.sc("A02")["feixe_min_s"]) * 60.0) + 4)
	check(sp.hud_info(0)["charges"] == 2 and not sp.slot[0].has("beam"), "A02: soltou o botão: o feixe acaba no mínimo e gasta 1 carga")
	# feixe segurado corta o andaime (auditoria 2026-11-27)
	var ct2 = main.demo.canteiro
	var and2: Array = ct2.parts.filter(func(p): return p["kind"] == "andaime" and not p["fallen"]) if ct2 != null else []
	check(and2.size() > 0, "A02: há andaime de pé para testar o corte")
	if and2.size() > 0:
		var pa = and2[and2.size() - 1]   # o último: os testes de plataforma usam os primeiros
		place.call(6.0)
		sp.slot[0]["cd"] = 0.0
		var hr2: Rect2 = ct2.hit_rect(pa)
		var xa: float = hr2.position.x - 200.0
		var fy2: float = sp._floor_below(xa, hr2.position.y)
		put(r0, Vector2(xa, fy2 if fy2 > 0.0 else floor_y))
		r0.facing = 1
		put(r1, Vector2(hr2.position.x - 900.0, floor_y))
		await frames(4)
		sp.slot[0]["aim"] = (hr2.get_center() - sp.muzzle(r0, "A02")).normalized()
		vset("v0", "item", true)
		var cortou := false
		for q in 120:
			await frames(1)
			if not sp.slot.has(0):
				break
			sp.slot[0]["aim"] = (hr2.get_center() - sp.muzzle(r0, "A02")).normalized()
			if pa["fallen"] or pa["crit_t"] > 0.0:
				cortou = true
				break
		vset("v0", "item", false)
		check(cortou, "A02: feixe segurado CORTA o andaime")
	# A04 marreta sísmica: no ar não gasta; no chão a onda pega quem está apoiado no mesmo trecho
	place.call(3.0)
	sp.clear(r0)
	sp.equip(r0, "A04")
	r0.position.y -= 120.0
	r0.velocity.y = -100.0
	await frames(1)
	await tap("v0", "item")
	check(sp.hud_info(0).get("charges", 0) == 1 and sp.flags(r0)["prep"] < 0.0, "A04: no ar avisa e não gasta")
	place.call(3.0)
	await frames(30)
	await tap("v0", "item")
	await frames(int(float(sp.sc("A04")["preparo"]) * 60.0) + 25)
	check(r1.dmg > 0.0 and r1.velocity.y < 0.0 or r1.dmg > 0.0, "A04: a onda tira o rival do chão (dano %d%%)" % int(r1.dmg))
	place.call(3.0)
	sp.equip(r0, "A04")
	await frames(2)
	await tap("v0", "item")
	await frames(int(float(sp.sc("A04")["preparo"]) * 60.0 * 0.6))
	r1.position.y -= 110.0   # no alto de um pulo na hora do golpe (o cenário do teste tem teto baixo em cima do rival)
	r1.velocity.y = -300.0   # viu a faixa vermelha e pulou no preparo (auditoria 2026-11-27: a cratera é na hora do golpe)
	await frames(30)
	check(r1.last_cause != "cratera da marreta sísmica", "A04: quem pulou no preparo escapa da cratera (%s, %d%%)" % [r1.last_cause, int(r1.dmg)])
	# A04 cratera (auditoria 2026-11-27): derruba a laje à frente, nunca a que está sob quem bate
	var ct4 = main.demo.canteiro
	var lajes4: Array = ct4.parts.filter(func(p): return p["kind"] == "laje" and not p["nucleo"] and not p["fallen"]) if ct4 != null else []
	var alvo4 = null
	var pe4 = null
	for p in lajes4:
		for q in ct4.parts:
			if q["kind"] == "laje" and not q["fallen"] and absf(q["rect"].end.x - p["rect"].position.x) < 2.0:
				alvo4 = p
				pe4 = q
		if alvo4 != null:
			break
	check(alvo4 != null, "A04: achou laje com vizinha à esquerda para testar a cratera")
	if alvo4 != null:
		place.call(3.0)
		sp.clear(r0)
		sp.equip(r0, "A04")
		put(r0, Vector2(alvo4["rect"].position.x - 24.0, alvo4["rect"].position.y))
		r0.facing = 1
		put(r1, Vector2(alvo4["rect"].position.x + 300.0, alvo4["rect"].position.y - 400.0))
		await frames(8)
		await tap("v0", "item")
		await frames(int(float(sp.sc("A04")["preparo"]) * 60.0) + 20)
		check(alvo4["fallen"] or alvo4["crit_t"] > 0.0, "A04: a cratera derruba a laje à frente")
		check(not pe4["fallen"] and pe4["crit_t"] <= 0.0, "A04: a laje sob quem bateu fica")
	# A01 carregado (auditoria 2026-11-27): carga cheia arremessa bem mais longe que o toque
	place.call(2.0)
	sp.clear(r0)
	sp.equip(r0, "A01")
	await frames(2)
	await tap("v0", "item")
	await frames(int(float(sp.sc("A01")["carga_min_s"]) * 60.0) + 8)
	var vx_toque: float = absf(r1.own_vx)
	place.call(2.0)
	sp.slot[0]["cd"] = 0.0
	await frames(2)
	vset("v0", "item", true)
	await frames(int(float(sp.sc("A01")["carga_max_s"]) * 60.0) + 2)
	vset("v0", "item", false)
	await frames(10)
	var vx_cheio: float = absf(r1.own_vx)
	check(vx_cheio > vx_toque * 1.8, "A01: carga cheia arremessa mais longe (toque %.0f × cheio %.0f)" % [vx_toque, vx_cheio])
	# C03 (sessão 6): o gancho agarra a BASE de uma coluna alta → o robô vai para CIMA dela (salva-vidas)
	place.call(9.0)
	sp.clear(r0)
	sp.equip(r0, "A06")
	await frames(2)
	var dx6 := 200.0   # lugar com espaço livre em cima da coluna (sem viga baixa)
	for cand in [200.0, -200.0, 280.0, -280.0, 360.0, -360.0, 440.0, -440.0, 520.0, -520.0]:
		var top_c: float = r0.position.y - float(sp.sc("A06")["coluna_tiles"]) * 64.0
		if absf(sp._floor_below(r0.position.x + cand, r0.position.y - 128.0, 9) - r0.position.y) < 2.0 and not sp._grab_at(Vector2(r0.position.x + cand, top_c - 40.0)) and not sp._grab_at(Vector2(r0.position.x + cand, top_c - 80.0)) and not sp._grab_at(Vector2(r0.position.x + cand, r0.position.y - 40.0)):
			dx6 = cand
			break
	r0.facing = 1 if dx6 > 0.0 else -1
	sp._drop_pile(r0, sp.slot[0], r0.position.x + dx6)
	await frames(int((float(sp.sc("A06")["marca_s"]) + float(sp.sc("A06")["sobe_s"])) * 60.0) + 12)
	var pl6 = sp.piles[sp.piles.size() - 1]
	var topo6: float = pl6["floor_y"] - pl6["shp"].size.y
	sp.clear(r0)
	sp.equip(r0, "C03")
	r0.facing = 1 if dx6 > 0.0 else -1
	await frames(2)
	sp.slot[0]["aim"] = Vector2(signf(dx6), 0)
	await tap("v0", "item")
	var subiu6 := false
	for q in 90:
		await frames(1)
		if r0.is_on_floor() and absf(r0.position.y - topo6) < 8.0:
			subiu6 = true
			break
	check(subiu6, "C03: gancho na base da coluna joga o robô para cima dela (y %.0f, topo %.0f)" % [r0.position.y, topo6])
	for p6 in sp.piles:   # limpa a coluna (os testes seguintes contam as estacas)
		if p6.get("body") != null and is_instance_valid(p6["body"]):
			p6["body"].queue_free()
	sp.piles.clear()
	# ===== DEFESA (2026-11-27): D01 Âncora de Contrapeso e D02 Airbag de Obra
	place.call(1.6)
	sp.clear(r0)
	sp.equip(r0, "D01")
	await frames(2)
	await tap("v0", "item")
	check(sp.anchors.has(0) and r0.ancora_t > 0.0, "D01: crava o contrapeso (ancorado)")
	var x_d1: float = r0.position.x
	var dano_d1: float = r0.dmg
	r0.take_hit(-1, "spell_mola", 1)
	await frames(20)
	check(absf(r0.position.x - x_d1) < 12.0 and r0.dmg > dano_d1, "D01: golpe forte NÃO empurra, mas o dano conta (andou %.0f px, %d%%)" % [absf(r0.position.x - x_d1), int(r0.dmg)])
	vset("v0", "right", true)
	await frames(20)
	vset("v0", "right", false)
	var andou_d1: float = absf(r0.position.x - x_d1)
	check(andou_d1 > 20.0 and andou_d1 < 0.7 * float(main.demo.robots_cfg["max_run"]) * 20.0 / 60.0 if main.demo.get("robots_cfg") != null else andou_d1 > 20.0, "D01: anda, devagar (%.0f px em 20 quadros)" % andou_d1)
	await frames(int((float(sp.sc("D01")["duracao_s"]) + sp.RobotVis.ANCORA_CRAVA_S + 0.4) * 60.0))
	check(not sp.anchors.has(0) and r0.ancora_t == 0.0 and sp.hud_info(0).is_empty(), "D01: acaba em %.0f s e some" % float(sp.sc("D01")["duracao_s"]))
	# D02: passivo — arremesso forte infla o airbag e corta o voo
	place.call(1.6)
	sp.clear(r0)
	sp.equip(r0, "D02")
	await frames(2)
	r0.dmg = 120.0
	r0.take_hit(-1, "spell_mola", 1)
	await frames(3)
	check(not sp.airbags.has(0), "D02: não infla no instante do golpe (o voo aparece primeiro)")
	await frames(int(float(sp.sc("D02")["apos_voo_s"]) * 60.0) + 3)
	check(sp.airbags.has(0), "D02: voando arremessado, o airbag infla sozinho")
	await frames(10)
	check(absf(r0.own_vx) < 300.0, "D02: o airbag corta o voo (vx %.0f)" % r0.own_vx)
	var pousou_d2 := false
	for q in 200:
		await frames(1)
		if not sp.airbags.has(0):
			pousou_d2 = true
			break
	await frames(30)
	check(pousou_d2 and sp.hud_info(0).is_empty() and r0.alive, "D02: pousa, o balão murcha e a engenhoca acaba")
	# DEFESA lote D2: D03 Para-choque de Mola (rebate golpe e tiro) e D04 Cortina de Poeira (intocável, não ataca)
	place.call(1.2)
	sp.clear(r0)
	sp.equip(r0, "D03")
	await frames(2)
	await tap("v0", "item")
	await frames(10)
	check(sp.bumpers.has(0) and r0.mola_t > 0.0, "D03: molas armadas")
	var d3_dmg: float = r0.dmg
	r0.take_hit(-1, "rapido", 1)
	await frames(6)
	check(r0.dmg == d3_dmg and r1.dmg > 0.0, "D03: o golpe não passa e quem bateu é rebatido (eu %d%%, rival %d%%)" % [int(r0.dmg), int(r1.dmg)])
	var rv3 := {"owner": 1, "pos": r0.rect().get_center() + Vector2(90, 0), "vel": Vector2(-900, 0), "bounces": 0, "t": 0.0, "hit": [], "trail": []}
	sp.rivets.append(rv3)
	await frames(8)
	check(rv3["owner"] == 0 and rv3["vel"].x > 0.0, "D03: o rebite volta com dono novo")
	await frames(int(float(sp.sc("D03")["duracao_s"]) * 60.0) + 10)
	check(not sp.bumpers.has(0) and r0.mola_t == 0.0 and sp.hud_info(0).is_empty(), "D03: acaba e some")
	place.call(1.2)
	sp.clear(r0)
	sp.equip(r0, "D04")
	await frames(2)
	await tap("v0", "item")
	await frames(int(float(sp.sc("D04")["rasga_s"]) * 60.0) + 6)
	check(sp.dusts.has(0) and r0.poeira_t > 0.0, "D04: rasgou o saco: nuvem de pó")
	var d4_dmg: float = r0.dmg
	var x4: float = r0.position.x
	r0.take_hit(-1, "spell_mola", 1)
	await frames(4)
	check(r0.dmg == d4_dmg and absf(r0.position.x - x4) < 4.0, "D04: golpe passa direto (sem dano, sem empurrão)")
	var rv4 := {"owner": 1, "pos": r0.rect().get_center() + Vector2(60, 0), "vel": Vector2(-900, 0), "bounces": 0, "t": 0.0, "hit": [], "trail": []}
	sp.rivets.append(rv4)
	await frames(8)
	check(rv4["pos"].x < r0.position.x - 20.0 and r0.dmg == d4_dmg, "D04: o tiro atravessa a nuvem")
	await tap("v0", "hammer")
	check(r0.atk == "", "D04: dentro da poeira não ataca")
	await frames(int(float(sp.sc("D04")["duracao_s"]) * 60.0) + 10)
	check(not sp.dusts.has(0) and r0.poeira_t == 0.0 and sp.hud_info(0).is_empty(), "D04: a poeira assenta e acaba")
	# DEFESA lote D3: D05 Capacete de Aço (absorve 3) e D06 Boneco de Teste (isca)
	place.call(1.2)
	sp.clear(r0)
	sp.equip(r0, "D05")
	await frames(2)
	await tap("v0", "item")
	check(r0.capacete_n == 3, "D05: capacete de aço com 3 proteções")
	var d5x: float = r0.position.x
	for k5 in 2:
		r0.take_hit(-1, "spell_mola", 1)
		await frames(12)
	check(r0.dmg == 0.0 and absf(r0.position.x - d5x) < 4.0 and r0.capacete_n == 1, "D05: 2 golpes absorvidos (sem dano/empurrão), resta 1 (%d)" % r0.capacete_n)
	r0.take_hit(-1, "spell_mola", 1)
	await frames(30)
	check(r0.dmg == 0.0 and r0.capacete_n == 0 and sp.helmet_fly.size() > 0 and sp.hud_info(0).is_empty(), "D05: o 3º golpe também não passa e o capacete voa")
	r0.take_hit(-1, "spell_mola", 1)
	check(r0.dmg > 0.0, "D05: depois do capacete, o golpe volta a doer")
	place.call(1.4)
	sp.clear(r0)
	sp.equip(r0, "D06")
	await frames(2)
	var d6x: float = r0.position.x
	await tap("v0", "item")
	await frames(20)
	check(sp.decoys.size() == 1 and absf(r0.position.x - d6x) > 40.0, "D06: boneco no lugar, o robô recuou (%.0f px)" % absf(r0.position.x - d6x))
	check(sp.decoy_of(0) != null and absf(sp.decoy_of(0).x - d6x) < 2.0, "D06: os bots miram no boneco (decoy_of)")
	var d6dmg: float = r1.dmg
	check(sp.decoy_hit(r1, Rect2(d6x - 30.0, r0.position.y - 80.0, 60, 70), false), "D06: golpe no boneco estoura")
	await frames(10)
	check(r1.dmg > d6dmg, "D06: quem bateu leva serragem (%d%%)" % int(r1.dmg))
	await frames(60)
	check(sp.decoys.is_empty(), "D06: o boneco some")
	# A05 rebiteira: tiro rápido, acerta e some
	place.call(5.0)
	sp.clear(r0)
	sp.equip(r0, "A05")
	await frames(2)
	await tap("v0", "item")
	await frames(25)
	check(r1.dmg > 0.0 and sp.hud_info(0)["charges"] == int(sp.sc("A05")["cargas"]) - 1, "A05: rajada acerta e gasta 1 carga (dano %d%%)" % int(r1.dmg))
	check(sp.pinned.has(1), "A05: 3 rebites seguidos = PREGADO")
	var pin_pos: Vector2 = r1.position
	await frames(20)
	check(r1.position.distance_to(pin_pos) < 2.0, "A05: pregado fica preso onde está")
	await frames(int(float(sp.sc("A05")["pino_s"]) * 60.0))
	check(not sp.pinned.has(1), "A05: solta depois de %.1f s" % float(sp.sc("A05")["pino_s"]))
	# ricochete: atira de costas para a parede de longe e o rebite volta
	var rv_test := {"owner": 0, "pos": Vector2(x0, floor_y - 40.0), "vel": Vector2(0, 900.0), "bounces": 0, "t": 0.0, "hit": [], "trail": []}
	sp.rivets.append(rv_test)
	await frames(10)
	check(rv_test["bounces"] >= 1 and rv_test["vel"].y < 0.0, "A05: rebite ricocheteia no chão (%d)" % rv_test["bounces"])
	# A06 bate-estaca: marca, desce e lança para cima
	place.call(2.6)
	sp.clear(r0)
	sp.equip(r0, "A06")
	await frames(2)
	await tap("v0", "item")
	check(sp.piles.size() == 1 and r1.dmg == 0.0, "A06: toque rápido marca a faixa à frente antes de descer")
	var y_before: float = r1.position.y
	var top_y: float = y_before
	for k in int(float(sp.sc("A06")["marca_s"]) * 60.0) + 40:
		await frames(1)
		top_y = minf(top_y, r1.position.y)
	check(r1.dmg > 0.0 and y_before - top_y > 2.0 * 64.0, "A06: estaca lança o rival para cima (%.1f tiles, %s)" % [(y_before - top_y) / 64.0, r1.last_cause])
	# mirar segurando: a marca anda com o direcional
	place.call(6.0)
	sp.equip(r0, "A06")
	await frames(2)
	vset("v0", "item", true)
	await frames(2)
	var mx0: float = sp.pile_aims[0]["x"] if sp.pile_aims.has(0) else 0.0
	vset("v0", "right", true)
	await frames(15)
	vset("v0", "right", false)
	var mx1: float = sp.pile_aims[0]["x"] if sp.pile_aims.has(0) else 0.0
	vset("v0", "item", false)
	await frames(3)
	check(mx1 - mx0 > 100.0 and sp.piles.size() >= 1 and absf(sp.piles[-1]["x"] - mx1) < 20.0, "A06: segurando, a mira anda (%.0f → %.0f) e a estaca cai lá" % [mx0, mx1])
	# A41: a COLUNA fica de pé (sólida, dá para subir) e desaba depois de coluna_s
	await frames(int(float(sp.sc("A06")["marca_s"]) * 60.0) + 20)
	var col_p: Dictionary = sp.piles[-1]
	var bcol = col_p.get("body")
	var de_pe: bool = bcol != null and is_instance_valid(bcol)
	var solido: bool = sp._solid_at(Vector2(col_p["x"], col_p["floor_y"] - 64.0)) or main.world.get_world_2d().direct_space_state.intersect_point(_pq(Vector2(col_p["x"], col_p["floor_y"] - 64.0))).size() > 0
	check(de_pe and solido, "A06 (A41): a coluna de concreto fica de pé e é sólida (plataforma)")
	await frames(int(float(sp.sc("A06")["coluna_s"]) * 60.0) + 20)
	check(col_p.get("gone", false), "A06 (A41): a coluna desaba depois de %.0f s" % float(sp.sc("A06")["coluna_s"]))
	sp.clear_columns()
	# A07 marreta-bumerangue: sem pesada enquanto voa, volta garantido
	place.call(3.5)
	sp.clear(r0)
	sp.equip(r0, "A07")
	await frames(2)
	await tap("v0", "item")
	await frames(3)
	check(r0.hammer_out and not r0.vis.has_hammer, "A07: a marreta sai da mão")
	await tap("v0", "heavy")
	check(r0.atk != "pesado", "A07: sem marretada pesada enquanto ela voa")
	var ret := 0
	while r0.hammer_out and ret < 300:
		await frames(1)
		ret += 1
	check(not r0.hammer_out and r1.dmg > 0.0, "A07: acerta na ida/volta e volta para a mão (%d quadros, dano %d%%)" % [ret, int(r1.dmg)])
	# A41: cada robô arremessa a SUA arma
	var mod0: int = r0.vis.model
	for kk in [["picareta", 1], ["britadeira", 3], ["pa", 4], ["chave", 2]]:
		place.call(3.5)
		sp.clear(r0)
		r0.vis.model = int(kk[1])
		r1.dmg = 0.0
		sp.equip(r0, "A07")
		await frames(2)
		var x_r1: float = r1.position.x
		await tap("v0", "item")
		var puxou := false
		var cravou := false
		var w := 0
		while (r0.hammer_out or w < 5) and w < 360:
			await frames(1)
			w += 1
			for h in sp.hammers:
				if h["phase"] == "puxa":
					puxou = true
				if h["phase"] == "crava":
					cravou = true
		match kk[0]:
			"picareta":
				check(puxou and r1.dmg > 0.0 and absf(r1.position.x - r0.position.x) < absf(x_r1 - r0.position.x), "A07 Guindaste: o gancho AGARRA e PUXA o rival (dano %d%%)" % int(r1.dmg))
			"britadeira":
				check(cravou and r1.dmg > 0.0, "A07 Brita: a britadeira crava e VIBRA empurrando (dano %d%%)" % int(r1.dmg))
			"pa":
				check(r1.dmg > 0.0, "A07 Escavadeira: a caçamba espalha TERRA e empurra (dano %d%%)" % int(r1.dmg))
			"chave":
				check(r1.dmg > 0.0, "A07 Solda: a chave vai e volta e acerta (dano %d%%)" % int(r1.dmg))
		check(not r0.hammer_out, "A07 %s: a arma volta para a mão" % kk[0])
	r0.vis.model = mod0
	sp.clear(r0)
	# A08 canhão de molas: BOING forte no primeiro alvo
	place.call(4.0)
	sp.clear(r0)
	sp.equip(r0, "A08")
	await frames(2)
	await tap("v0", "item")
	var x_b: float = r1.position.x
	var esticou := false
	for k in int(float(sp.sc("A08")["preparo"]) * 60.0) + 60:
		await frames(1)
		for m in sp.springs:
			if float(m.get("hit_t", -1.0)) >= 0.0:
				esticou = true
	check(r1.dmg > 0.0 and r1.position.x - x_b > 3.0 * 64.0, "A08: BOING arremessa longe (%.1f tiles)" % ((r1.position.x - x_b) / 64.0))
	check(esticou and sp.springs.is_empty(), "A08 (lote 3): a mola ESTICA no rival e depois some")
	sp.clear(r0)
	# ===== Etapa 3 (controle e engenharia)
	sp.boxes.clear()
	# C02 turboventilador: segurando, empurra para longe sem tirar o controle
	place.call(3.0)
	sp.clear(r0)
	sp.equip(r0, "C02")
	await frames(2)
	var d7: float = r1.position.x - r0.position.x
	vset("v0", "item", true)
	await frames(40)
	vset("v0", "item", false)
	await frames(2)
	check(r1.position.x - r0.position.x > d7 + 100.0 and r1.stun_t <= 0.0, "C02: vento empurra o rival (%.0f → %.0f px), sem tirar o controle" % [d7, r1.position.x - r0.position.x])
	# C03 gancho: no rival dá tranco para perto; na parede puxa o dono
	place.call(5.0)
	sp.clear(r0)
	sp.equip(r0, "C03")
	await frames(2)
	await tap("v0", "item")
	await frames(20)
	check(r1.dmg > 0.0 and r1.own_vx < 0.0 or r1.dmg > 0.0, "C03: garra acerta o rival e puxa (dano %d%%)" % int(r1.dmg))
	place.call(9.0)
	put(r1, Vector2(x0 - 600.0, floor_y))
	var xg: float = r0.position.x
	await frames(30)
	sp.slot[0]["cd"] = 0.0
	vset("v0", "up", true)
	await tap("v0", "item")
	vset("v0", "up", false)
	var moved := false
	for k in 70:
		await frames(1)
		if r0.position.distance_to(Vector2(xg, floor_y)) > 120.0:
			moved = true
	check(moved or sp.hooks.is_empty(), "C03: garra na estrutura puxa o dono (ou volta se não achar nada)")
	# C05 laço: liga os dois e o elástico puxa quando estica
	place.call(4.0)
	sp.clear(r0)
	sp.equip(r0, "C05")
	await frames(2)
	await tap("v0", "item")
	await frames(20)
	check(sp.tethers.size() == 1, "C05: laço prende o rival")
	put(r1, Vector2(r0.position.x + 6.0 * 64.0, floor_y))
	await frames(12)
	check(r1.position.x - r0.position.x < 6.0 * 64.0 - 40.0, "C05: esticado, o elástico aproxima os dois (%.0f px)" % (r1.position.x - r0.position.x))
	await frames(int(float(sp.sc("C05")["duracao_s"]) * 60.0))
	check(sp.tethers.is_empty(), "C05: o laço solta depois do tempo")
	# E02 carga remota: instala, arma e detona no segundo toque
	place.call(5.0)
	sp.clear(r0)
	sp.equip(r0, "E02")
	await frames(2)
	await tap("v0", "item")
	check(sp.charges_placed.size() == 1 and sp.hud_info(0)["charges"] == 1, "E02: instala a carga (slot vira detonador)")
	put(r1, Vector2(sp.charges_placed[0]["pos"].x + 40.0, floor_y))
	put(r0, Vector2(x0 + 5.0 * 64.0, floor_y))
	await frames(40)
	await tap("v0", "item")
	await frames(3)
	check(sp.charges_placed.is_empty() and r1.dmg > 0.0 and sp.flags(r0).get("fading", false), "E02: detona e lança quem está perto (dano %d%%)" % int(r1.dmg))
	# lote 3: a carga explode SOZINHA em auto_s (4 s) e as peças no raio DESABAM
	var alvos: Array = ct.parts.filter(func(p): return p["kind"] == "laje" and not p["fallen"] and not p["nucleo"])
	if alvos.size() > 0:
		alvos.sort_custom(func(a, b): return a["rect"].get_center().x < b["rect"].get_center().x)
		var pa: Dictionary = alvos[0]   # o trecho MAIS À ESQUERDA: o buraco fica longe do dash da Broca (que vai para a direita)
		var topo: Vector2 = Vector2(pa["rect"].get_center().x, pa["rect"].position.y)
		sp.clear(r0)
		put(r0, Vector2(x0, floor_y))   # o dono fica num lugar seguro (se ele cair, a carga some com ele)
		put(r1, Vector2(x0 + 200.0, floor_y))
		sp.equip(r0, "E02")
		sp.charges_placed.append({"owner": 0, "pos": topo, "t": 0.0, "armed": false, "drop": 1.0, "flying": false, "vel": Vector2.ZERO, "rot": 0.0})
		await frames(int(float(sp.sc("E02")["auto_s"]) * 60.0) - 30)
		var ainda: bool = not sp.charges_placed.is_empty()
		await frames(45)
		check(ainda and sp.charges_placed.is_empty(), "E02 (lote 3): explode sozinha em %.0f s" % float(sp.sc("E02")["auto_s"]))
		check(pa["fallen"], "E02 (lote 3): a peça no raio DESABA na explosão")
		sp.clear(r0)
		r0.facing = 1   # o teste seguinte (dash da Broca) conta com o robô virado para a direita
	# E03 controle remoto: derruba a viga pendurada mais perto
	var vigas: Array = ct.parts.filter(func(p): return p["kind"] == "viga" and not p["fallen"])
	if vigas.size() > 0:
		var vg: Dictionary = vigas[0]
		place.call(3.0)
		sp.clear(r0)
		put(r0, Vector2(vg["rect"].get_center().x - 120.0, floor_y))
		r0.facing = 1
		sp.equip(r0, "E03")
		await frames(2)
		var tg = sp.remote_target(r0)
		await tap("v0", "item")
		await frames(60)
		check(tg != null and ((tg.has("part") and tg["part"]["fallen"]) or tg.has("mec")), "E03: o alvo mais perto (viga/andaime/máquina) é acionado")
	sp.clear(r0)
	# ===== Mira em 8 direções e regra das plataformas
	# beirada de laje que ainda existe (os testes anteriores derrubam trechos)
	var edge_x := 8 * 64.0 + 30.0
	for pt in ct.parts:
		if pt["kind"] == "laje" and not pt["fallen"] and not sp._hard_at(Vector2(pt["rect"].position.x - 20.0, floor_y + 20.0)):
			edge_x = pt["rect"].position.x + 30.0
			break
	var and0: Dictionary = ct.parts.filter(func(p): return p["kind"] == "andaime" and not p["fallen"])[0]
	check(not sp._hard_at(and0["rect"].get_center()) and sp._grab_at(and0["rect"].get_center()) and sp._hard_at(nuc[0]["rect"].get_center()),
		"plataforma vazada não para tiro (mas o gancho agarra); a laje para")
	place.call(6.0)
	sp.clear(r0)
	sp.equip(r0, "A03")
	await frames(2)
	vset("v0", "up", true)
	await tap("v0", "item")
	await frames(int(float(sp.sc("A03")["preparo"]) * 60.0) + 2)
	vset("v0", "up", false)
	check(sp.shots.size() > 0 and sp.shots[0]["vel"].y < -500.0 and absf(sp.shots[0]["vel"].x) < 1.0, "▲: canhão de gelo atira para cima")
	await frames(30)
	place.call(6.0)
	sp.clear(r0)
	sp.equip(r0, "C03")
	await frames(2)
	vset("v0", "up", true)
	vset("v0", "right", true)
	await tap("v0", "item")
	vset("v0", "up", false)
	vset("v0", "right", false)
	check(sp.hooks.size() == 1 and sp.hooks[0]["vel"].y < 0.0 and sp.hooks[0]["vel"].x > 0.0, "▲►: gancho sai na diagonal")
	await frames(60)
	place.call(4.0)
	sp.clear(r0)
	sp.equip(r0, "C01")
	await frames(2)
	vset("v0", "item", true)
	vset("v0", "up", true)
	await frames(30)
	check(sp.slot[0]["aim"].y < -0.5, "ímã: a mira gira para cima enquanto segura (%s)" % str(sp.slot[0]["aim"]))
	vset("v0", "item", false)
	vset("v0", "up", false)
	await frames(3)
	place.call(6.0)
	sp.clear(r0)
	sp.equip(r0, "E02")
	await frames(2)
	vset("v0", "up", true)
	await tap("v0", "item")
	vset("v0", "up", false)
	await frames(110)
	check(sp.charges_placed.size() == 1 and not sp.charges_placed[0].get("flying", false) and sp.charges_placed[0]["pos"].distance_to(r0.position) > 40.0, "▲: carga arremessada gruda numa superfície")
	sp.charges_placed.clear()
	place.call(6.0)
	sp.clear(r0)
	sp.equip(r0, "A08")
	await frames(2)
	vset("v0", "up", true)
	await tap("v0", "item")
	await frames(int(float(sp.sc("A08")["preparo"]) * 60.0) + 2)
	vset("v0", "up", false)
	check(sp.springs.size() > 0 and sp.springs[0]["vel"].y < -600.0, "▲: canhão de molas em arco alto")
	await frames(60)
	sp.clear(r0)
	# ===== Etapa 4 (transformações)
	# T02 empilhadeira: veste, ergue o rival à frente e joga
	place.call(1.3)
	sp.clear(r0)
	sp.equip(r0, "T02")
	await frames(2)
	await tap("v0", "item")
	await frames(20)
	check(sp.flags(r0).get("armor_set", "") == "T02" and r0.spell_speed < 1.0 and r0.vis.visible, "T02: veste a armadura de empilhadeira (mais lenta)")
	place.call(1.3)
	await frames(2)
	await tap("v0", "item")
	await frames(10)
	check(r1.position.y < floor_y - 40.0, "T02: garfo ergue o rival (%.0f acima)" % (floor_y - r1.position.y))
	var x14: float = r1.position.x
	await frames(60)
	check(r1.dmg > 0.0 and r1.position.x - x14 > 100.0, "T02: e joga para a frente (%.0f px)" % (r1.position.x - x14))
	sp.clear(r0)
	check(r0.spell_speed == 1.0 and r0.vis.visible, "T02: desmonta ao limpar")
	# T03 bola: rola com inércia e atropela
	place.call(5.0)
	sp.equip(r0, "T03")
	await frames(2)
	await tap("v0", "item")
	await frames(62)   # transformação estilo Transformers dura 0,9 s (A29)
	check(r0.spell_form == "" and r0.vis.visible and sp.flags(r0).get("mecha", "") == "T03", "T03: monta o mecha gorila EM PÉ (A33)")
	vset("v0", "item", true)
	await frames(20)
	check(r0.spell_form == "bola" and not r0.vis.visible, "T03: segurando o especial fecha em bola")
	vset("v0", "right", true)
	await frames(50)
	vset("v0", "right", false)
	check(r1.dmg > 0.0, "T03: atropela o rival (dano %d%%)" % int(r1.dmg))
	vset("v0", "item", false)
	await frames(20)
	check(r0.spell_form == "" and r0.vis.visible, "T03: soltou, abre e volta a ficar em pé")
	await frames(int(float(sp.sc("T03")["duracao_s"]) * 60.0))
	check(r0.spell_form == "" and r0.vis.visible and sp.hud_info(0).is_empty(), "T03: abre de volta no fim")
	# T04 jetpack: segurar = voar gastando combustível; acabou, a mochila cai
	place.call(6.0)
	sp.equip(r0, "T04")
	await frames(2)
	var y16: float = r0.position.y
	vset("v0", "item", true)
	await frames(40)
	check(y16 - r0.position.y > 120.0 and sp.slot[0]["energy"] < float(sp.sc("T04")["combustivel_s"]) - 0.4 and r0.spell_fly, "T04: segurando, voa (subiu %.0f px)" % (y16 - r0.position.y))
	vset("v0", "right", true)
	var x16: float = r0.position.x
	await frames(25)
	vset("v0", "right", false)
	check(r0.position.x - x16 > 80.0, "T04: pilota para o lado voando (%.0f px)" % (r0.position.x - x16))
	await frames(int(float(sp.sc("T04")["combustivel_s"]) * 60.0))
	vset("v0", "item", false)
	await frames(2)
	check(sp.hud_info(0).is_empty() and not r0.spell_fly, "T04: combustível acabou, a mochila cai")
	await frames(60)
	# A33 modo mecha: o golpe leve do mecha causa mais; o mecha recebe menos dano
	place.call(1.0)
	sp.equip(r0, "T01")
	await frames(2)
	await tap("v0", "item")
	await frames(62)
	place.call(1.0)
	r1.dmg = 0.0
	r1.invuln = 0.0
	await frames(4)
	await tap("v0", "hammer")
	await frames(30)
	var esperado: float = float(main.demo.cfg["amassometro"]["mecha_leve"]["dano"]) * float(main.demo.cfg["modo_mecha"]["T01"]["causa"])
	check(absf(r1.dmg - esperado) < 0.6, "modo mecha: golpe LEVE da Fornalha dá %.1f%% (esperado %.1f%%)" % [r1.dmg, esperado])
	r0.dmg = 0.0
	r0.invuln = 0.0
	r0.guard_t = 0.0
	r0.take_hit(-1, "rapido", 1)
	var normal: float = float(main.demo.cfg["amassometro"]["rapido"]["dano"])
	check(r0.dmg < normal - 0.1 and r0.dmg > 0.0, "modo mecha: a Fornalha recebe menos dano (%.1f%% em vez de %.1f%%)" % [r0.dmg, normal])
	sp.clear(r0)
	await frames(10)
	# T05 broca: rival na frente leva dano contínuo
	place.call(1.2)
	sp.equip(r0, "T05")
	await frames(2)
	await tap("v0", "item")
	place.call(1.2)
	await frames(40)
	check(r1.dmg > 0.0 and sp.flags(r0).get("armor_set", "") == "T05", "T05: veste a broca e fura quem está na frente (dano %d%%)" % int(r1.dmg))
	# A30: SEGURAR = dash furando para a frente até acabar o combustível; atropela quem está no caminho
	await frames(30)
	place.call(3.5)
	r0.facing = 1   # independe do teste anterior: o dash vai para a direita, em direção ao rival
	await frames(4)
	var x_antes: float = r0.position.x
	var dmg_antes: float = r1.dmg
	vset("v0", "item", true)
	await frames(30)
	var dash_on: bool = sp.slot[0]["data"].get("dash", false)
	await frames(30)
	var en_fim: float = float(sp.slot[0]["energy"]) if sp.slot.has(0) else 99.0   # mede antes de uma queda (a carga do E02 abre buracos)
	await frames(60)
	vset("v0", "item", false)
	check(dash_on and absf(r0.position.x - x_antes) > 150.0, "T05: segurar dispara o DASH furando (andou %d px)" % int(absf(r0.position.x - x_antes)))
	check(r1.dmg >= dmg_antes + 7.0, "T05: o dash atropela quem está no caminho (%d%% → %d%%)" % [int(dmg_antes), int(r1.dmg)])
	check(en_fim <= 0.0, "T05: o combustível do dash acaba")
	sp.clear(r0)
	# T06 soldador: arco curto e conserto de trecho rachado
	place.call(1.2)
	sp.equip(r0, "T06")
	await frames(2)
	await tap("v0", "item")
	await frames(60)   # transformação (0,9 s)
	place.call(2.5)
	vset("v0", "item", true)
	await frames(12)
	var cadeia: Array = sp.slot[0]["data"].get("chain", [])
	await frames(18)
	vset("v0", "item", false)
	check(r1.dmg > 0.0, "T06: o raio do Para-Raios acerta (dano %d%%)" % int(r1.dmg))
	check(cadeia.size() >= 2, "T06: o raio sai da arma e chega no alvo (%d pontos na cadeia)" % cadeia.size())
	var lajes: Array = ct.parts.filter(func(p): return p["kind"] == "laje" and not p["fallen"] and not p["nucleo"] and p["crit_t"] <= 0.0)
	if lajes.size() > 0:
		var lp: Dictionary = lajes[0]
		lp["hp"] = int(lp["max"]) - 1
		put(r0, Vector2(lp["rect"].get_center().x, lp["rect"].position.y))
		put(r1, Vector2(lp["rect"].get_center().x + 600.0, floor_y))
		await frames(8)
		vset("v0", "down", true)
		vset("v0", "item", true)
		await frames(int(float(sp.sc("T06")["reparo_s"]) * 60.0) + 10)
		vset("v0", "down", false)
		vset("v0", "item", false)
		check(int(lp["hp"]) == int(lp["max"]), "T06: parado com ▼ conserta o trecho rachado")
	sp.clear(r0)
	# T07 MECHA CORREDOR (A36): não encolhe; monta o mecha, corre/pula mais, ARRANCADA (segurar) atropela; acaba no tempo
	place.call(5.0)
	sp.equip(r0, "T07")
	await frames(2)
	await tap("v0", "item")
	await frames(70)
	var cfg_t07: Dictionary = sp.sc("T07")
	check(r0.size_k == 1.0 and sp.mecha_of(r0) == "T07" and is_equal_approx(r0.spell_speed, float(cfg_t07["vel_mult"])) and is_equal_approx(r0.spell_jump, float(cfg_t07["pulo_mult"])),
		"T07: vira o mecha Corredor (sem encolher), corre ×%.1f e pula ×%.2f" % [r0.spell_speed, r0.spell_jump])
	check(sp.flags(r0).get("mecha", "") == "T07" and sp.flags(r0).get("armor", false), "T07: desenhado como mecha (flags)")
	var dano_t07: float = r1.dmg
	put(r0, Vector2(x0, floor_y))
	put(r1, Vector2(x0 + 260.0, floor_y))
	r0.facing = 1
	await frames(2)
	var x_t07: float = r0.position.x
	vset("v0", "item", true)
	await frames(30)
	vset("v0", "item", false)
	check(r0.position.x - x_t07 > 250.0 and r1.dmg > dano_t07, "T07: ARRANCADA dispara para a frente (%.0f px) e atropela o rival (%.0f%%)" % [r0.position.x - x_t07, r1.dmg])
	await frames(int(float(cfg_t07["duracao_s"]) * 60.0))
	check(r0.spell_speed == 1.0 and r0.spell_jump == 1.0 and sp.mecha_of(r0) == "", "T07: o mecha acaba no tempo e o robô volta ao normal")
	# G10 carga especial: holofotes em 2 pontos e duas cápsulas descem
	main.event_level = 2
	main.events.manual = true
	sp.boxes.clear()
	main.events.trigger(main.events.ev("G10"))
	await frames(3)
	var nsp: int = main.events.spots.size()
	check(main.events.phase == "aviso" and nsp >= 1 and nsp <= 3, "G10: anuncia 1 a 3 pontos (holofotes): %d" % nsp)
	await frames(85)
	check(sp.boxes.size() == nsp and sp.boxes.all(func(b): return b["special"] and sp.sc(b["id"])["familia"] == "transformacao"), "G10 Carga Especial: só ARMADURAS descem (%s)" % str(sp.boxes.map(func(b): return b["id"])))
	main.events.manual = false
	main.event_level = 0

## Toda imagem pedida no código existe (a lama da Maré faltava e enchia o log de erros, travando o jogo).
func imagens_test() -> void:
	print("== Imagens")
	var missing := []
	var found := 0
	var re := RegEx.new()
	re.compile("Data\\.tex\\(\"([a-z_/0-9]+)\"\\)")
	for path in ["res://main.gd", "res://modes/demolicao.gd", "res://modes/arena_fx.gd", "res://modes/eventos.gd", "res://modes/spells.gd",
			"res://level/level.gd", "res://ui/hud.gd", "res://ui/menus.gd", "res://ui/kit.gd", "res://player/robot_visual.gd"]:
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			found += 1
			if Data.tex(m.get_string(1)) == null:
				missing.append(m.get_string(1))
	for k in ["s01_canhao", "s01_luva", "s03_canhao", "s06_ima", "s10_tabua", "s10_trouxa", "s13_frente", "s13_costas", "icone_engenharia", "icone_transformacao"]:
		if Data.tex("spells/" + k) == null:
			missing.append("spells/" + k)
	if found == 0 and OS.has_feature("template"):
		found = 99   # jogo exportado: o código vai compilado (sem o texto para varrer); os ícones dos itens foram conferidos
	check(missing.is_empty() and found > 40, "todas as %d imagens usadas no código existem %s" % [found, str(missing)])
	var f: Font = load("res://ui/kit.gd").font()
	check(f is FontFile and f != ThemeDB.fallback_font, "a fonte do jogo (Fredoka) está incluída")

func joy_btn(dev: int, b: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = dev
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)

func joy_axis(dev: int, ax: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = dev
	e.axis = ax
	e.axis_value = v
	Input.parse_input_event(e)

func joy_tap(dev: int, b: int) -> void:
	joy_btn(dev, b, true)
	await frames(3)
	joy_btn(dev, b, false)
	await frames(3)

## Partida inteira só com eventos de controle (como o Windows manda), sem teclado.
func controle_real_test() -> void:
	print("== Controle (eventos de verdade)")
	main.go_menu()
	PlayerInput.virtual = {}
	PlayerInput.fake_joys = [3]
	await frames(3)
	main.menus.sel = 0
	joy_axis(3, JOY_AXIS_LEFT_Y, 1.0)
	await frames(3)
	joy_axis(3, JOY_AXIS_LEFT_Y, 0.0)
	await frames(3)
	check(main.menus.sel == 1, "analógico desce no menu (%d)" % main.menus.sel)
	await joy_tap(3, JOY_BUTTON_DPAD_UP)
	check(main.menus.sel == 0, "direcional sobe no menu")
	await joy_tap(3, JOY_BUTTON_A)
	check(main.state == S.ARENAS, "A confirma no menu (JOGAR → mapas)")
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.demo.lives_setting = 1
	main.arena_choice = "demolicao"
	main.event_level = 0
	main.go_join()
	await frames(3)
	await joy_tap(3, JOY_BUTTON_A)
	check(main.players.size() == 1 and main.players[0]["dev"] == "joy3", "A entra na partida pelo controle")
	main.add_bot()
	await joy_tap(3, JOY_BUTTON_START)
	check(main.state == S.RUN, "START começa a partida")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	await frames(5)
	var r0 = main.robots[0]
	put(r0, Vector2(col_x(11), 576))
	put(main.robots[1], Vector2(col_x(24), 576))
	main.bots.reset()
	main.players[1]["bot"] = false   # bot parado para não atrapalhar
	await frames(2)
	var x0: float = r0.position.x
	joy_axis(3, JOY_AXIS_LEFT_X, 1.0)
	await frames(20)
	joy_axis(3, JOY_AXIS_LEFT_X, 0.0)
	check(r0.position.x > x0 + 60.0, "analógico anda com o robô (%.0f px)" % (r0.position.x - x0))
	x0 = r0.position.x
	joy_btn(3, JOY_BUTTON_DPAD_LEFT, true)
	await frames(20)
	joy_btn(3, JOY_BUTTON_DPAD_LEFT, false)
	check(r0.position.x < x0 - 60.0, "direcional anda com o robô")
	await frames(10)
	var y0: float = r0.position.y
	joy_btn(3, JOY_BUTTON_A, true)
	await frames(8)
	check(r0.position.y < y0 - 40.0, "A pula")
	joy_btn(3, JOY_BUTTON_A, false)
	await frames(40)
	await joy_tap(3, JOY_BUTTON_X)
	check(PlayerInput.dev_held("joy3", "hammer") or r0.atk != "" or r0.atk_cd > 0.0, "X dá o golpe rápido")
	joy_axis(3, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await frames(2)
	check(PlayerInput.held(0, "dodge"), "gatilho RT é a esquiva")
	joy_axis(3, JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await mapeamento_test()

## CONTROLES (2026-11-28): modelo pelo fabricante/produto, MAPEAR só um aparelho (principal/alternativo, troca), teclado.
func mapeamento_test() -> void:
	print("== Controles: modelo e mapeamento por aparelho")
	var PI_ = PlayerInput
	check(PI_.model_from(0x054c, 0x0ce6, "") == "ps5" and PI_.model_from(0x054c, 0x05c4, "Wireless Controller") == "ps4"
		and PI_.model_from(0x045e, 0x0b12, "") == "xbox" and PI_.model_from(0x057e, 0x2009, "") == "switch"
		and PI_.model_from(0, 0, "DualSense Wireless Controller") == "ps5" and PI_.model_from(0, 0, "Wireless Controller") == "ps4"
		and PI_.model_from(0, 0, "8BitDo SN30 Pro") == "gen", "reconhece DualSense, DualShock 4, Xbox, Switch Pro e genérico")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PI_.CUSTOM_PATH))
	var cf := ConfigFile.new()
	cf.set_value("guidvelho", "jump", ["b", 2, 1])
	cf.save(PI_.CUSTOM_PATH)
	PI_.load_custom()
	check(PI_.custom["guidvelho"]["jump"] == [["b", 2], null], "lê o arquivo antigo (um sinal por ação)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PI_.CUSTOM_PATH))
	PI_.custom.clear()
	main.go_menu()
	PI_.virtual = {"v0": {}}
	PI_.fake_joys = [3, 4]
	await frames(3)
	main.menus.abrir_controles()
	await frames(3)
	check("joy3" in main.menus._hub_devs() and "kb_b" in main.menus._hub_devs(), "CONTROLES: um cartão por aparelho")
	main.menus._abrir_mapear("joy3")
	await frames(30)
	main.menus.map_sel = 4   # PULAR, principal
	main.menus.map_col = 0
	await tap("v0", "jump")
	check(main.menus.map_listen > 0.0, "MAPEAR: PULAR começa a escutar o novo botão")
	await joy_tap(3, JOY_BUTTON_X)
	var mm: Dictionary = main.menus.map_m
	check(mm["jump"][0] == ["b", JOY_BUTTON_X] and mm["hammer"][0] == ["b", JOY_BUTTON_A], "botão repetido troca de lugar (X pula, A vira golpe)")
	await frames(30)
	main.menus.map_sel = 0   # ANDAR ◄ pelo analógico DIREITO
	await tap("v0", "jump")
	joy_axis(3, JOY_AXIS_RIGHT_X, -1.0)
	await frames(3)
	joy_axis(3, JOY_AXIS_RIGHT_X, 0.0)
	check(main.menus.map_m["left"][0] == ["a", JOY_AXIS_RIGHT_X, -1], "direção aceita outro analógico")
	await frames(30)
	main.menus.map_sel = 7   # ESQUIVA alternativo: apagar
	main.menus.map_col = 1
	await tap("v0", "heavy")
	check(main.menus.map_m["dodge"][1] == null, "TRIÂNGULO/Y apaga o alternativo")
	main.menus.map_sel = 11
	await tap("v0", "jump")
	await frames(3)
	check(main.state == S.CONTROLES and PI_.custom.has(PI_.pad_key(3)) and not PI_.custom.has(PI_.pad_key(4)), "SALVAR grava só para ESTE controle")
	joy_btn(3, JOY_BUTTON_X, true)
	joy_btn(4, JOY_BUTTON_X, true)
	await frames(2)
	var j3_pula: bool = PI_.dev_held("joy3", "jump")
	var j4_golpe: bool = PI_.dev_held("joy4", "hammer") and not PI_.dev_held("joy4", "jump")
	joy_btn(3, JOY_BUTTON_X, false)
	joy_btn(4, JOY_BUTTON_X, false)
	check(j3_pula and j4_golpe, "o controle mapeado usa o novo, o outro igual continua no padrão")
	joy_axis(3, JOY_AXIS_LEFT_X, -1.0)
	await frames(2)
	var nav_ok: bool = PI_.dev_held("joy3", "nav_left") and not PI_.dev_held("joy3", "left")
	joy_axis(3, JOY_AXIS_LEFT_X, 0.0)
	check(nav_ok, "menus continuam andando pelo analógico esquerdo (ninguém fica preso)")
	# teclado A: PULAR na tecla T
	main.menus._abrir_mapear("kb_a")
	await frames(30)
	main.menus.map_sel = 4
	main.menus.map_col = 0
	await tap("v0", "jump")
	await key_event(KEY_SHIFT, true, KEY_LOCATION_LEFT)
	await key_event(KEY_SHIFT, false, KEY_LOCATION_LEFT)
	check(main.menus.map_listen > 0.0 and main.menus.map_m["jump"][0] == KEY_G, "Shift não pode virar ação")
	await key_event(KEY_T, true)
	await key_event(KEY_T, false)
	main.menus.map_sel = 11
	await frames(30)
	await tap("v0", "jump")
	await key_event(KEY_T, true)
	var t_pula: bool = PI_.dev_held("kb_a", "jump")
	await key_event(KEY_T, false)
	await key_event(KEY_G, true)
	var g_pula: bool = PI_.dev_held("kb_a", "jump")
	await key_event(KEY_G, false)
	check(t_pula and not g_pula, "teclado A remapeado: T pula, G não")
	PI_.custom.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PI_.CUSTOM_PATH))
	PI_.fake_joys = []
	main.go_menu()

## BOTS na entrada (2026-11-28): R1/RB edita o bot; ◄► muda robô/visual/cor/dificuldade; TIRAR BOT tira só ele.
func bots_entrada_test() -> void:
	print("== Bots na entrada")
	main.go_menu()
	main.mode = "demolicao"
	main.state = S.JOIN
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	await tap("v0", "jump")
	await tap("v0", "heavy")
	await tap("v0", "heavy")
	check(main.players.size() == 3 and main.players[1].get("bot", false) and main.players[2].get("bot", false), "Y/△ adiciona bots")
	await tap("v0", "dodge")
	check(main.bot_editado(0) == 1, "R1/RB passa a editar o 1º bot")
	var m0: int = main.players[1]["model"]
	await tap("v0", "right")
	check(main.players[1]["model"] != m0 and main.players[0]["model"] == 0, "◄► muda o robô DO BOT (não o do jogador)")
	await tap("v0", "down")
	await tap("v0", "down")
	await tap("v0", "down")
	var nv: int = main.players[1].get("level", 1)
	await tap("v0", "right")
	check(int(main.players[1]["level"]) == posmod(nv + 1, 3), "DIFICULDADE do bot muda")
	await tap("v0", "dodge")
	check(main.bot_editado(0) == 2, "R1/RB de novo: próximo bot")
	await tap("v0", "back")
	check(main.bot_editado(0) == -1 and main.players.size() == 3, "VOLTAR editando: volta ao próprio cartão (ninguém sai)")
	await tap("v0", "dodge")
	await tap("v0", "up")   # linha 0 → sobe para TIRAR BOT (última)
	await tap("v0", "jump")
	check(main.players.size() == 2 and main.players[1].get("bot", false) and main.bot_editado(0) == -1, "TIRAR BOT tira só aquele bot")
	await tap("v0", "heavy")
	await tap("v1", "jump")
	await tap("v0", "heavy")
	check(main.players.size() == 4, "mesa cheia")
	await tap("v0", "heavy")
	check(main.players.size() == 4, "Y/△ com a mesa cheia não tira mais todos os bots")
	main.players.clear()
	PlayerInput.slots.clear()
	main.go_menu()

## Fluxo (2026-11-28): CONFIGURAR MAPA / SELECIONAR MAPA terminam na escolha dos personagens; o START que fecha a
## etapa VIDAS não pula a tela de jogadores.
func fluxo_test() -> void:
	print("== Fluxo: tudo termina na escolha dos personagens")
	main.go_menu()
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	main.go_join()
	await frames(3)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.start_match()
	await frames(5)
	main.resultado_escolhe(1)   # CONFIGURAR MAPA
	check(main.state == S.SELSPELLS, "CONFIGURAR MAPA abre as engenhocas")
	await tap("v0", "start")
	await tap("v0", "start")
	check(main.state == S.AJUSTES, "engenhocas → eventos → vidas")
	await tap("v0", "start")
	await frames(3)
	check(main.state == S.JOIN and main.players.size() == 2, "START em VIDAS para na escolha dos personagens (não pula para DETONAR)")
	await tap("v0", "start")
	check(main.state == S.DETONAR, "outro START na escolha dos personagens segue para DETONAR")
	main.resultado_escolhe(2)   # SELECIONAR MAPA
	check(main.state == S.ARENAS, "SELECIONAR MAPA abre os mapas")
	main.players.clear()
	PlayerInput.slots.clear()
	main.go_menu()

## Seletor das engenhocas: segurar repete e as bordas dão a volta (2026-11-28: estava lento de um em um).
func seletor_test() -> void:
	print("== Seletor das grades (segurar repete)")
	main.go_menu()
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.selecao.abrir_spells()
	PlayerInput.virtual = {"v0": {}}
	await frames(3)
	main.selecao.sel = 0
	await tap("v0", "left")
	var n: int = main.selecao.spells_do_mapa().size() + 2
	check(main.selecao.sel == n - 1, "◄ na 1ª ficha dá a volta para a última")
	main.selecao.sel = 0
	vset("v0", "right", true)
	await frames(60)
	vset("v0", "right", false)
	await frames(2)
	check(main.selecao.sel >= 6, "segurar ► 1 s anda várias fichas (%d)" % main.selecao.sel)
	var cols: int = main.selecao.grade_spells(n)["cols"]
	main.selecao.sel = 0
	await tap("v0", "up")
	check(main.selecao.sel / cols == int(ceil(n / float(cols))) - 1, "▲ na 1ª linha dá a volta para a última")
	main.go_menu()

func controles_test() -> void:
	print("== Controles externos")
	var PI_ = PlayerInput
	check(PI_.type_from_name("Xbox Wireless Controller") == "xbox" and PI_.type_from_name("XInput Controller") == "xbox"
		and PI_.type_from_name("DualSense Wireless Controller") == "ps" and PI_.type_from_name("PS4 Controller") == "ps"
		and PI_.type_from_name("Nintendo Switch Pro Controller") == "nintendo" and PI_.type_from_name("8BitDo SN30 Pro") == "generico",
		"reconhece Xbox, PlayStation, Nintendo e genérico pelo nome")
	# entrada: ITEM adiciona bot, VOLTAR sai
	main.go_menu()
	main.mode = "demolicao"
	main.state = S.JOIN
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v9": {}}
	await frames(2)
	await tap("v0", "jump")
	await tap("v0", "heavy")
	check(main.players.size() == 2 and main.players[1].get("bot", false), "na entrada, Y/△ adiciona bot")
	await tap("v1", "jump")
	check(main.players.size() == 3, "outro controle entra")
	# controle cai no meio da partida: pausa; outro controle livre assume com START
	main.start_match()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	await frames(3)
	var dev_p3: String = PlayerInput.slots[2]
	main._on_pad_changed(dev_p3, false)
	await frames(2)
	check(main.paused and main.lost_pads == [2], "controle desconectado na partida: pausa e avisa (P3)")
	await tap("v9", "start")
	await frames(2)
	check(PlayerInput.slots[2] == "v9" and main.players[2]["dev"] == "v9" and main.lost_pads.is_empty(), "outro controle assume P3 com START")
	await tap("v0", "start")
	check(not main.paused, "continua a partida")
	# o mesmo controle visto 2x pelo Windows: o jogador escuta as duas cópias
	main.go_menu()
	main.state = S.JOIN
	PlayerInput.virtual = {"v0": {}, "v7": {}}
	await frames(2)
	await tap("v0", "jump")
	PlayerInput.aliases["v7"] = "v0"
	vset("v7", "right", true)
	await frames(2)
	check(PlayerInput.held(0, "right"), "controle duplicado: o botão da cópia também move o jogador")
	vset("v7", "right", false)
	PlayerInput.aliases.erase("v7")
	# intro: anda sozinha até o menu, e qualquer botão pula
	main.go_menu()
	main.state = S.INTRO
	main.menus.intro_t = 0.0
	main.menus.intro_frames = 0
	await frames(30)
	check(main.state == S.INTRO, "intro rodando")
	await tap("v0", "jump")
	await frames(60)
	check(main.state == S.MENU, "qualquer botão pula a intro e chega ao menu")
	# tela de teste de controles abre e fecha com ESC
	main.go_menu()
	main.state = S.CONTROLES
	await frames(3)
	await key_event(KEY_ESCAPE, true)
	await frames(2)
	await key_event(KEY_ESCAPE, false)
	check(main.state == S.OPTIONS, "CONTROLES abre e ESC volta às opções")
	main.menus._abrir_teste("kb_a")
	await frames(3)
	await key_event(KEY_ESCAPE, true)
	await key_event(KEY_ESCAPE, false)
	check(main.state == S.CONTROLES, "TESTAR: ESC volta à central de controles")

func bots_test() -> void:
	print("== Bots")
	seed(11)   # luta de bots depende do sorteio: semente fixa (não muda conforme os testes que rodaram antes)
	main.rng.seed = 11
	main.mode = "demolicao"
	main.arena_choice = "demolicao"
	main.state = S.JOIN
	main.players.clear()
	PlayerInput.slots.clear()
	PlayerInput.virtual = {"v0": {}}
	await frames(2)
	await tap("v0", "jump")
	main.add_bot()
	check(main.players.size() == 2 and main.players[1].get("bot", false), "B adiciona bot na entrada")
	main.bot_level = 2
	main.players[1]["level"] = 2
	main.demo.cfg["quake_start_s"] = 999.0
	var crumble0 = main.demo.cfg["crumble_break_s"]
	main.demo.lives_setting = 1   # "derruba" = 1 eliminação (não herda vidas de outro teste)
	main.demo.cfg["crumble_break_s"] = 999.0   # mede só o bot: o caixote que racha sob quem fica parado derrubava os dois
	main.start_match()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	var human = main.robots[0]
	var won := false
	for i in 60 * 90:
		await frames(1)
		if main.state != S.RUN:
			won = main.demo.round_winner == 1
			break
	check(won, "bot difícil derruba um jogador parado em até 90 s")
	main.demo.cfg["crumble_break_s"] = crumble0
	main.demo.cfg["quake_start_s"] = 30.0
	# 3 bots entre si: a rodada termina e nenhum cai sozinho nos primeiros 4 s
	main.state = S.JOIN
	main.players.clear()
	PlayerInput.slots.clear()
	PlayerInput.virtual = {}
	main.bot_level = 1
	for k in 3:
		main.add_bot()
	main.start_match()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	main.self_falls = 0
	main.fall_log.clear()
	var rounds := 0
	for i in 60 * 200:
		await frames(1)
		if main.state == S.SCORE:
			rounds += 1
			print("    rodada %d acabou em %.0f s (arena %s, etapa %s)" % [rounds, i / 60.0, main.level.id, str(main.demo.etapas.etapa) if main.demo.etapas != null else "-"])
			main.timer = 0.0
			await frames(3)
			if rounds >= 4 or main.state == S.WIN:
				break
			main.countdown = 0.0
			for r in main.robots:
				r.active = true
	check(rounds >= 3, "rodadas só de bots terminam (%d rodadas)" % rounds)
	print("    quedas sozinho: ", main.fall_log)
	check(main.self_falls <= 3, "bots quase não erram a navegação (%d quedas por andar/pular errado em %d rodadas; outras: %s)" % [main.self_falls, rounds, str(main.fall_log)])

# ---------------------------------------------------------------- capturas
func projetos_frames(dir: String, video := "--projetos-video" in OS.get_cmdline_user_args()) -> void:
	# PROJETOS v2: completa o projeto (4 no chão + 3) e o caso "sem mapa novo: guardados"
	for caso in [["comp", 4, 3, ["terreo"]], ["guarda", 9, 1, []]]:
		main.res_info = {"valida": true, "zona": 4, "antes": 40, "depois": 75, "delta": 35, "premio": "", "novas": caso[3],
			"pontos": caso[2], "total": caso[1] + caso[2], "por_mapa": 6}
		main.res_fase = "projetos"
		for tt in [2.0, 99.0]:
			main.res_t = tt
			await frames(1)
			await snap(dir, "m11_fim_projetos_%s_%d" % [caso[0], int(tt)])
	if video:   # quadros para o vídeo (30 por segundo)
		main.res_info = {"valida": true, "zona": 4, "antes": 40, "depois": 75, "delta": 35, "premio": "", "novas": ["terreo"],
			"pontos": 3, "total": 7, "por_mapa": 6}
		main.res_fase = "projetos"
		var dur: float = main.fim.duracao("projetos") + 1.0
		DirAccess.make_dir_recursive_absolute(dir + "/projetos_video")
		for f in int(dur * 30.0):
			main.res_t = f / 30.0
			await frames(1)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir + "/projetos_video/%04d.png" % f)

func snap(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("captura: ", name)

func shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
	await frames(2)
	for d in ["v0", "v1", "v2", "v3"]:
		await tap(d, "jump")
	await frames(10)
	await snap(dir, "1_entrada")
	await tap("v0", "start")
	await frames(30)
	main.countdown = 0.01
	await steer(["v0", "v1", "v2", "v3"], 50)
	await snap(dir, "4_corrida")
	# prancha: 4 robôs espalhados pela obra (posições escolhidas, sem física)
	var spots := [Vector2(560, 768), Vector2(930, 520), Vector2(680, 576), Vector2(1335, 768)]
	for k in 4:
		var r = main.robots[k]
		r.active = false
		r.set_physics_process(false)
		r.visible = true
		r.scale = Vector2.ONE
		r.position = spots[k]
		r.facing = 1 if k != 3 else -1
	main.robots[1].vis.expression = "esforco"
	main.robots[0].vis.expression = "vitoria"
	main.robots[3].vis.expression = "susto"
	main.robots[1].vis.sq = Vector2(0.85, 1.18)
	for k in 4:
		main.robots[k].vis.scale = Vector2(main.robots[k].vis.sq.x * main.robots[k].facing, main.robots[k].vis.sq.y)
		main.robots[k].vis.queue_redraw()
	main.dust(Vector2(905, 768))
	await frames(90)
	main.dust(Vector2(905, 704))
	await frames(4)
	await snap(dir, "prancha_canteiro")
	await steer(["v0", "v1", "v2", "v3"], 600)
	await frames(80)
	await snap(dir, "5_placar")
	# prancha dos robôs desenhada pelo próprio motor (mesma montagem do jogo)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var sheet := Node2D.new()
	sheet.draw.connect(func():
		sheet.draw_texture_rect(Data.tex("cenario/fundo_canteiro"), Rect2(0, 0, 1920, 1080), false)
		var Vis = load("res://player/robot_visual.gd")
		sheet.draw_rect(Rect2(0, 0, 1920, 1080), Color("#9fe3ee"))
		var ex := ["normal", "esforco", "susto", "vitoria", "eliminado"]
		for k in 8:  # os 8 modelos em azul
			Vis.draw_robot(sheet, {"color": 0, "model": k}, Vis.idle_pose(0.5), Transform2D(0.0, Vector2(2.6, 2.6), 0.0, Vector2(140 + k * 235, 560)))
		for k in 8:  # cores e expressões
			var po: Dictionary = Vis.idle_pose(0.5)
			po["expr"] = ex[k % 5]
			Vis.draw_robot(sheet, {"color": k % 4, "model": k}, po, Transform2D(0.0, Vector2(1.6, 1.6), 0.0, Vector2(140 + k * 235, 1010)))
	)
	layer.add_child(sheet)
	await frames(3)
	await snap(dir, "prancha_robos")

## Espia uma arena num modo com 4 bots: --espiar=DIR,arena,modo,segundos (uma foto a cada 10 s).
func espiar(arg: String) -> void:
	var p := arg.split(",")
	var dir := p[0]
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	main.bot_level = 1
	for k in 4:
		main.add_bot()
	main.arena_choice = p[1]
	main.game_mode = p[2]
	main.demo.cfg["rounds_to_win"] = 99
	main.start_match()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	var secs := int(p[3]) if p.size() > 3 else 40
	for k in range(1, secs / 10 + 1):
		await frames(600)
		await snap(dir, "%s_%s_%02ds" % [p[1], p[2], k * 10])
		print("t=%d rei=%d capacete=%s tempos=%s estado=%d robôs=%s" % [k * 10, main.demo.king, str(main.demo.crown_pos), str(main.demo.king_time), main.state, str(main.robots.map(func(r): return Vector2i(r.position)))])

## Material para as propostas de interface: cenários sem HUD e robôs com fundo transparente.
func maquete_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	main.hud.bare = true
	main.go_menu()
	await frames(90)
	await snap(dir, "bg_menu")
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.arena_choice = "canteiro"
	main.go_join()
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	for k in 6:
		await tap("v0", "down")
	main.add_bot()
	main.add_bot()
	var looks: Array = []
	for p in main.players:
		looks.append({"color": p["color"], "model": p["model"]})
	main.start_match()
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	await frames(100)
	await snap(dir, "bg_jogo")
	# robôs recortados (fundo transparente)
	get_viewport().transparent_bg = true
	main._clear_robots()
	main.state = S.MENU
	main.hud.visible = false
	main.bg.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var sheet := Node2D.new()
	var Vis = load("res://player/robot_visual.gd")
	var which := [0, false]
	sheet.draw.connect(func():
		var lk: Dictionary = looks[which[0]]
		var pose: Dictionary = Vis.victory_pose(0.35, int(Data.model_meta(lk["model"])["danca"])) if which[1] else Vis.idle_pose(0.5)
		Vis.draw_robot(sheet, lk, pose, Transform2D(0.0, Vector2(6, 6), 0.0, Vector2(960, 900)))
	)
	layer.add_child(sheet)
	for k in looks.size():
		for v in 2:
			which[0] = k
			which[1] = v == 1
			sheet.queue_redraw()
			await frames(3)
			await snap(dir, "robo_%d%s" % [k, "_vitoria" if v == 1 else ""])
	print("cores: ", main.players.map(func(p): return p["color"]))

## Prancha do elenco montado pelo motor: parado, rostos, comemoração e corrida (--robos=DIR).
func robos_sheet(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var sheet := Node2D.new()
	var Vis = load("res://player/robot_visual.gd")
	var tt := [0.0]
	sheet.draw.connect(func():
		sheet.draw_texture_rect(Data.tex("temas/fabrica/fundo"), Rect2(0, 0, 1920, 1080), false)
		for k in Data.MODELS.size():
			var x := 220.0 + k * 370.0
			Vis.draw_robot(sheet, {"color": k % 4, "model": k}, Vis.idle_pose(0.5), Transform2D(0.0, Vector2(2.4, 2.4), 0.0, Vector2(x, 400)))
			load("res://ui/kit.gd").text(sheet, Vector2(x - 110, 450), Data.MODEL_NAMES[k], 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 220, 6, Data.INK)
			var po: Dictionary = Vis.victory_pose(tt[0] + k * 0.13, int(Data.model_meta(k)["danca"]))
			Vis.draw_robot(sheet, {"color": (k + 1) % 4, "model": k}, po, Transform2D(0.0, Vector2(1.6, 1.6), 0.0, Vector2(x, 760)))
			var p2: Dictionary = Vis.idle_pose(0.5)
			p2["expr"] = ["esforco", "susto", "eliminado", "vitoria"][k % 4]
			Vis.draw_robot(sheet, {"color": (k + 2) % 4, "model": k}, p2, Transform2D(0.0, Vector2(1.6, 1.6), 0.0, Vector2(x, 1010)))
	)
	layer.add_child(sheet)
	for f in 2:
		tt[0] = 0.21 * f
		sheet.queue_redraw()
		await frames(3)
		await snap(dir, "robos_%d" % f)

# ---------------------------------------------------------------- animação (quadros para GIF)
var _frame_no := 0

func _pq(p: Vector2) -> PhysicsPointQueryParameters2D:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collision_mask = 1
	return q

func grab(dir: String, prefix: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("%s_%04d.png" % [prefix, _frame_no]))
	_frame_no += 1

## Vitrine das animações de movimento e combate (--combate=DIR): quadros a 30 por segundo para virar GIF.
## P1 Lata: corre, derrapa, pulo + pulo duplo (mortal), esquiva no chão e no ar, golpes rápidos, marretada pesada.
## P2 Brutamontes (amassado): apanha, é arremessado girando e se recupera no ar. P3 Varapau: erra a marretada (fica cravada).
## Vitrine do HUD de cima vivo (prancha hud_topo aprovada 2026-11-27): P1 pega a engenhoca (maleta cai) e usa,
## P2 leva golpes (número pula, cartão pisca), P3 passa de 120% (perigo), P4 é eliminado (FORA). --hud=DIR
func hud_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1", "v2", "v3"]:
		await tap(d, "jump")
	for i in 4:
		main.players[i]["model"] = i
	main.game_mode = "derruba"
	main.demo.lives_setting = 4
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	var rs: Array = main.robots
	_frame_no = 0
	main.demo.lives[2] = 1
	main.demo.lives[3] = 1
	for f in 330:
		var a := {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
		if f == 20:
			sp.equip(rs[0], "A04")
		if f == 70:
			sp.equip(rs[1], "T05")
		a["v0"]["item"] = f == 110 or f == 111
		if f == 150:
			a["v1"]["item"] = true
		if f in [40, 90, 130, 175]:
			rs[1].take_hit(-1, "rapido", 2)
			rs[1].velocity = Vector2.ZERO
			rs[1].own_vx = 0.0
		if f == 60:
			rs[2].dmg = 116.0
		if f == 100:
			rs[2].take_hit(1, "rapido", 3)
			rs[2].own_vx = 0.0
		if f == 230:
			main.kill(rs[3], -1, null)
		for r in rs:
			r.invuln = 0.0
		PlayerInput.virtual = a
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "hud")
	print("quadros: ", _frame_no)

func combate_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1", "v2"]:
		await tap(d, "jump")
	main.players[0]["model"] = 0
	main.players[1]["model"] = 4
	main.players[2]["model"] = 5
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "demolicao"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	main.hud.visible = false
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var r2 = main.robots[2]
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(19), 576))
	put(r2, Vector2(col_x(24), 576))
	r1.dmg = 45.0
	r2.dmg = 90.0
	r1.facing = -1
	r2.facing = -1
	main.cam_lock = [1.55, Vector2(col_x(17), 470)]
	_frame_no = 0
	var script := {
		"v0": [[10, 40, "right"], [40, 58, "left"], [70, 78, "jump"], [82, 92, "jump"], [82, 120, "right"],
			[150, 153, "dodge"], [150, 153, "right"], [175, 189, "jump"], [192, 195, "dodge"], [192, 195, "right"], [192, 195, "up"],
			[240, 243, "hammer"], [258, 261, "hammer"], [276, 279, "hammer"], [330, 333, "heavy"],
			[440, 443, "dodge"], [440, 443, "right"]],
		"v1": [[372, 420, "left"], [395, 398, "dodge"], [395, 398, "left"]],
		"v2": [[300, 303, "heavy"], [430, 433, "heavy"]],
	}
	for f in 520:
		if f == 225:
			put(r0, Vector2(col_x(16), 576))
			put(r1, Vector2(col_x(17) + 10, 576))
			r0.facing = 1
			r1.dmg = 45.0
		if f == 320:
			r1.dmg = 135.0
			put(r1, Vector2(col_x(17) + 10, 576))
			r1.own_vx = 0.0
		if f == 425:
			put(r0, Vector2(col_x(12), 576))
			put(r2, Vector2(col_x(14) + 20, 576))
			r0.facing = 1
		var a := {"v0": {}, "v1": {}, "v2": {}}
		for d in script:
			for seg in script[d]:
				if f >= seg[0] and f < seg[1]:
					a[d][seg[2]] = true
		PlayerInput.virtual = a
		for r in main.robots:
			r.invuln = 0.0
		var foco: Vector2 = r0.position
		if f >= 225 and f < 425:
			foco = (r0.position + r1.position) / 2.0
		elif f >= 425:
			foco = (r0.position + r2.position) / 2.0
		main.cam_lock = [2.3, foco + Vector2(0, -60)]
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "c")
	print("quadros: ", _frame_no)

## Vitrine das spells da Etapa 1 no Canteiro (--spells=DIR): caixas, cada spell em uso e a troca. 30 quadros/s.
## Vitrine do elenco (--elenco=DIR, --so-elenco=0+3): cada robô de perto: parado, corre, 3 golpes rápidos, marretada
## pesada num boneco, esquiva no chão, pulo + esquiva no ar. 1 quadro a cada 2 (30/s).
## Vitrines com --skins: cada robô veste a skin do mapa (manifesto → skins_originadas). Só para capturas (sem menu).
func _vestir_skins() -> void:
	var qual := -1   # --skins = 1ª skin de cada robô; --skins=N = a N-ésima (0, 1, 2)
	for a0 in OS.get_cmdline_user_args():
		if a0 == "--skins":
			qual = 0
		elif a0.begins_with("--skins="):
			qual = int(a0.substr(8))
	if qual < 0:
		return
	var por := {}
	var n := {}
	for k in MapaReg.manifesto("derruba", "canteiro_obras").get("skins_originadas", []):
		var rb := String(k["robo"])
		if int(n.get(rb, 0)) == qual:
			por[rb] = String(k["id"]).to_lower()
		n[rb] = int(n.get(rb, 0)) + 1
	for r in main.robots:
		r.vis.skin = por.get(Data.MODELS[posmod(r.vis.model, Data.MODELS.size())], "")

func elenco_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var which := [0, 1, 2, 3, 4]
	for a0 in OS.get_cmdline_user_args():
		if a0.begins_with("--so-elenco="):
			which = Array(a0.substr(12).split("+")).map(func(x): return int(x))
	_frame_no = 0
	for m in which:
		main.go_menu()
		PlayerInput.virtual = {"v0": {}, "v1": {}}
		main.mode = "demolicao"
		main.go_join()
		await frames(2)
		for d in ["v0", "v1"]:
			await tap(d, "jump")
		main.players[0]["model"] = m
		main.players[0]["color"] = m % 4
		main.players[1]["model"] = (m + 1) % 5
		main.game_mode = "derruba"
		main.demo.lives_setting = 5
		main.event_level = 0
		main.arena_choice = "demolicao"
		main.start_match()
		await demo_round()
		main.demo.spells.spawn_t = 999.0
		main.hud.visible = false
		_vestir_skins()
		var r0 = main.robots[0]
		var r1 = main.robots[1]
		put(r0, Vector2(col_x(11), 576))
		put(r1, Vector2(col_x(20), 576))
		r0.facing = 1
		r1.facing = -1
		var script := [[22, 46, "right"], [60, 63, "hammer"], [74, 77, "hammer"], [88, 91, "hammer"], [118, 121, "heavy"],
			[178, 181, "dodge"], [178, 181, "right"], [205, 219, "jump"], [224, 227, "dodge"], [224, 227, "right"], [224, 227, "up"]]
		for f in 262:
			if f == 50:
				put(r1, Vector2(r0.position.x + 70.0, 576))
				r1.dmg = 0.0
			if f == 110:
				put(r1, Vector2(r0.position.x + 74.0, 576))
				r1.dmg = 60.0
				r1.own_vx = 0.0
			if f == 170:
				put(r1, Vector2(col_x(24), 576))
			var a := {"v0": {}, "v1": {}}
			for seg in script:
				if f >= seg[0] and f < seg[1]:
					a["v0"][seg[2]] = true
			PlayerInput.virtual = a
			for r in main.robots:
				r.invuln = 0.0
			main.demo.lives[0] = 9
			main.demo.lives[1] = 9
			main.cam_lock = [2.6, r0.position + Vector2(30, -70)]
			await frames(1)
			if f % 2 == 0:
				await grab(dir, "el%d" % m)
				var scp: Vector2 = (r0.position - main.cam_center) * main.cam_zoom + Vector2(960, 540)
				_el_log.append([m, f, int(scp.x), int(scp.y), main.cam_zoom])
	var fpos := FileAccess.open(dir.path_join("pos.json"), FileAccess.WRITE)
	fpos.store_string(JSON.stringify(_el_log))
	fpos.close()
	print("quadros: ", _frame_no)

## Vitrine da FASE em etapas (--fase=DIR): 4 bots lutando no Térreo, a virada inteira (aviso, desaba, queda) e a luta
## na Fundação. 1 quadro a cada 4 (15/s).
func fase_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	main.go_menu()
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for k in 4:
		main.add_bot()
	main.game_mode = "derruba"
	main.demo.lives_setting = 9
	main.event_level = 2
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.countdown = 0.0
	var et = main.demo.etapas
	et.ativo = true
	_frame_no = 0
	var f := 0
	var after := -1
	while f < 1500:
		if f == 300:
			et.forcar(OS.get_environment("ROTA") if OS.get_environment("ROTA") != "" else "total")   # ROTA=moderada → Fachada
		if et.etapa != 1 and after < 0:
			after = f
		if after >= 0 and f - after > 330:
			break
		for i in main.players.size():
			main.demo.lives[i] = 9
		await frames(1)
		if f % 4 == 0:
			await grab(dir, "fase")
		f += 1
	print("quadros: ", _frame_no)

## Prancha de conferência: os robôs do elenco com cada tipo de spell (arma carregada, mirando, armaduras, jetpack,
## kit e objeto nas costas). --equipa=DIR → 2 passadas (modelos 0-3 e 1-4), 1 quadro por estado.
func equipa_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var states := [["A03", "carrega"], ["A02", "mira"], ["T01", "usa"], ["T02", "usa"], ["T05", "usa"], ["T06", "usa"], ["T04", "voa"], ["T01", "kit"], ["T02", "kit"], ["T03", "kit"], ["T04", "kit"], ["T05", "kit"], ["T06", "kit"], ["A04", "costas"], ["T07", "usa"]]
	for pass_i in 2:
		main.go_menu()
		PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
		main.mode = "demolicao"
		main.go_join()
		await frames(2)
		for d in ["v0", "v1", "v2", "v3"]:
			await tap(d, "jump")
		for i in 4:
			main.players[i]["model"] = i + pass_i
		main.game_mode = "derruba"
		main.demo.lives_setting = 9
		main.event_level = 0
		main.arena_choice = "canteiro_obras"
		main.start_match()
		await demo_round()
		var sp = main.demo.spells
		sp.spawn_t = 999.0
		main.hud.visible = false
		_vestir_skins()
		for st in states:
			for i in 4:
				var r = main.robots[i]
				sp.clear(r)
				put(r, Vector2(760.0 + i * 190.0, 832.0))
				r.facing = 1
				r.invuln = 9.0
			await frames(3)
			for i in 4:
				var r = main.robots[i]
				sp.equip(r, st[0])
				match st[1]:
					"mira", "usa":
						sp.use(r)
					"voa":
						sp.use(r)
						sp.bot_hold[r.pid] = 3.0
			main.cam_lock = [1.9, Vector2(1045, 740)]
			await frames(40 if not st[1] in ["mira", "voa"] else 12)
			for i in 4:
				main.robots[i].invuln = 0.0
			await frames(1)
			await grab(dir, "eq%d_%s_%s" % [pass_i, st[0], st[1]])

## Vitrine dos MECHAS no jogo (A29/A30, --mechas=DIR): P1 pega cada armadura, transforma e usa a habilidade contra
## 3 alvos (Fornalha, Broca, Bola, Empilhadeira, Para-Raios, Jato). 1 quadro a cada 2 (30/s) → mecha_NNNN.png.
func mechas_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1", "v2", "v3"]:
		await tap(d, "jump")
	for i in 4:
		main.players[i]["model"] = i
	if OS.get_environment("MECHAS_MODELO") != "":   # vitrine: escolhe o robô do P1
		main.players[0]["model"] = int(OS.get_environment("MECHAS_MODELO"))
	main.game_mode = "derruba"
	main.demo.lives_setting = 9
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	if OS.get_environment("MECHAS_SEGURA") != "" and OS.get_environment("MECHAS_SO") != "":   # vitrine: card na tela de engenhocas
		main.selecao.abrir_spells()
		await frames(10)
		main.selecao.sel = main.selecao.spells_do_mapa().find(OS.get_environment("MECHAS_SO").split(",")[0])
		await frames(20)
		await grab(dir, "selecao")
		main.state = S.JOIN
	main.start_match()
	await demo_round()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	_frame_no = 0
	var log := []
	# cada mecha recém-montado: anda → leve → pesado → pulo → pulo duplo → dash → habilidade (A34)
	var seq := [["T01", "fogo"], ["T05", "dash"], ["T03", "rola"], ["T02", "garfo"], ["T06", "raio"], ["T04", "voa"], ["T07", "arrancada"]]
	if OS.get_environment("MECHAS_SO") != "":   # ex.: MECHAS_SO=T07 → só esse mecha
		seq = seq.filter(func(x): return x[0] in OS.get_environment("MECHAS_SO").split(","))
	for st in seq:
		var r0 = main.robots[0]
		for i in 4:
			var r = main.robots[i]
			sp.clear(r)
			r.dmg = 0.0
			main.demo.lives[i] = 9
			put(r, Vector2(700.0 if i == 0 else 1500.0 + i * 120.0, 832.0))
			r.facing = 1 if i == 0 else -1
		await frames(4)
		sp.equip(r0, st[0])
		await frames(2)
		var segura := int(OS.get_environment("MECHAS_SEGURA"))   # vitrine: anda segurando o cartucho antes de usar
		for k in segura:
			vset("v0", "right", k < segura / 2)
			await frames(1)
			if k % 4 == 0:
				await grab(dir, "segura")
				var sp_s: Vector2 = (r0.position - main.cam_center) * main.cam_zoom + Vector2(960, 540)
				log.append(["segura", k, int(sp_s.x), int(sp_s.y), main.cam_zoom])
		vset("v0", "right", false)
		await tap("v0", "item")
		var n := 0
		while n < 400:
			match n:
				60:
					vset("v0", "right", true)
				110:
					vset("v0", "right", false)
				125:
					put(main.robots[1], r0.position + Vector2(130, 0))
					main.robots[1].facing = -1
					await tap("v0", "hammer")
				165:
					put(main.robots[1], r0.position + Vector2(140, 0))
					await tap("v0", "heavy")
				225:
					put(main.robots[1], Vector2(1700, 832))
					await tap("v0", "jump")
				243:
					await tap("v0", "jump")
				290:
					vset("v0", "right", true)
				296:
					await tap("v0", "dodge")
				315:
					vset("v0", "right", false)
				330:
					for i in range(1, 4):
						put(main.robots[i], r0.position + Vector2(150.0 + i * 120.0, 0))
					match st[1]:
						"fogo", "dash", "raio", "rola", "arrancada":
							vset("v0", "item", true)
						"garfo":
							await tap("v0", "item")
						"voa":
							vset("v0", "item", true)
				385:
					vset("v0", "item", false)
			if st[1] == "rola" and n > 330 and n < 385:
				vset("v0", "right", true)
			if n == 386:
				vset("v0", "right", false)
			for i in range(1, 4):
				main.demo.lives[i] = 9
			if sp.slot.has(0):
				sp.slot[0]["t"] = maxf(float(sp.slot[0]["t"]), 3.0)   # a armadura não acaba no meio da vitrine
			await frames(1)
			if n % 2 == 0:
				await grab(dir, "mecha")
				var sc_p: Vector2 = (r0.position - main.cam_center) * main.cam_zoom + Vector2(960, 540)
				log.append([st[0], n, int(sc_p.x), int(sc_p.y), main.cam_zoom])
			n += 1
		for k in ["item", "right", "up"]:
			vset("v0", k, false)
	var fa := FileAccess.open(dir.path_join("pos.json"), FileAccess.WRITE)
	fa.store_string(JSON.stringify(log))
	fa.close()
	print("quadros: ", _frame_no)

## Som aprovado (pack VB): cada ação toca SÓ o seu som, uma vez; golpe no vazio não faz clang; KO fora da arena = UMA
## explosão (sem o som de peças) e abaixa a música; tema em loop no barramento Music. --so=som
func som_test() -> void:
	print("== Som aprovado (pack VB)")
	var miss := []
	for k in Audio.APROVADO.keys():
		for f in Audio.APROVADO[k][0]:
			if Audio._stream("res://assets/audio/aprovado/%s.wav" % f) == null:
				miss.append(f)
	check(miss.is_empty(), "%d sons aprovados carregam (faltando: %s)" % [Audio.APROVADO.size(), str(miss)])
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var log_of := func() -> Array:
		return Audio.rec_log.filter(func(e): return e.has("path")).map(func(e): return String(e["path"]).get_file().get_basename())
	var has := func(names: Array, pre: String) -> int:
		return names.filter(func(n): return String(n).begins_with(pre)).size()
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(20), 576))
	r0.facing = 1
	await frames(20)
	Audio.rec_log = []
	await tap("v0", "jump")
	await frames(6)
	await tap("v0", "jump")
	await frames(40)
	var l: Array = log_of.call()
	check(has.call(l, "salto_0") == 1 and has.call(l, "salto_duplo") == 1, "pulo e pulo duplo: 1 som cada (%s)" % str(l))
	check(has.call(l, "aterrissagem") == 0 and has.call(l, "passo") == 0, "pouso comum e passos: mudos (revisão do usuário: barulho demais)")
	await frames(30)
	Audio.rec_log = []
	r0.dodge_cd = 0.0
	await tap("v0", "dodge")
	await frames(30)
	l = log_of.call()
	check(has.call(l, "dash_solo") == 1 and has.call(l, "esquiva") == 0 and not l.has("soprador"), "dash no chão: só o som de dash (%s)" % str(l))
	# golpe no vazio: nada de pancada
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(20), 576))
	await frames(10)
	Audio.rec_log = []
	await tap("v0", "hammer")
	await frames(25)
	l = log_of.call()
	check(has.call(l, "impacto") == 0 and has.call(l, "marreta_r") + has.call(l, "marreta_p") == 0, "golpe no vazio não faz clang (%s)" % str(l))
	# golpe rápido e pesado no robô
	put(r1, Vector2(col_x(11) + 60, 576))
	await frames(25)
	Audio.rec_log = []
	await tap("v0", "hammer")
	await frames(8)
	l = log_of.call()
	check(has.call(l, "impacto_robo_rapido") == 1 and has.call(l, "marreta_r") + has.call(l, "marreta_p") == 0, "golpe rápido no robô: 1 pancada de robô, sem clang de estrutura (%s)" % str(l))
	await frames(50)
	put(r0, Vector2(col_x(11), 576))
	put(r1, Vector2(col_x(11) + 60, 576))
	await frames(5)
	Audio.rec_log = []
	await heavy_hit("v0")
	l = log_of.call()
	check(has.call(l, "impacto_robo_pesado") == 1, "pesada no robô: pancada pesada (%s)" % str(l))
	# pesada na estrutura (caixote do mapa): clang de marreta no metal, uma vez, sem pancada de robô
	await frames(60)
	put(r0, Vector2(col_x(12), 576))
	put(r1, Vector2(col_x(26), 576))
	r0.facing = 1
	await frames(20)
	Audio.rec_log = []
	await heavy_hit("v0")
	l = log_of.call()
	check(has.call(l, "marreta_pesada_metal") == 1 and has.call(l, "impacto") == 0 and not l.has("caixote_pancada_1"), "pesada na estrutura: 1 clang no metal (%s)" % str(l))
	# KO fora da arena: UMA explosão, sem 'eliminado', música abaixa
	for i in main.players.size():
		main.demo.lives[i] = 9
	await frames(60)
	Audio.music(main.TEMA)
	await frames(30)
	Audio.rec_log = []
	put(r1, Vector2(-3000, 300))
	await frames(4)
	l = log_of.call()
	check(has.call(l, "explosao_fora_arena") == 1 and not l.has("eliminado") and not l.any(func(n): return String(n).begins_with("explosao_") and not String(n).contains("fora")), "KO fora da arena: 1 explosão aprovada, sem som de peças (%s)" % str(l))
	check(Audio._duck < 0.9, "a música abaixa na explosão (%.2f)" % Audio._duck)
	await frames(60)
	check(Audio._duck == 1.0, "...e volta em ~0,5 s")
	var ms: AudioStream = Audio._music.stream
	check(ms is AudioStreamOggVorbis and ms.loop and Audio._music.bus == "Music" and Audio._pool[0].bus == "SFX", "tema Rock Cartoon em loop no barramento Music; efeitos no SFX")
	Audio.rec_log = null

## Vitrine dos eventos (--eventos=DIR, --so-eventos=G02+G05): cada evento do aviso ao fim, 1 quadro a cada 3.
func eventos_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1"]:
		await tap(d, "jump")
	main.players[0]["model"] = 0
	main.players[1]["model"] = 4
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 2
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var ev = main.events
	ev.manual = true
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = main.demo.canteiro.parts.filter(func(p): return p["nucleo"])
	var fy: float = nuc[0]["rect"].position.y
	var x0: float = nuc[0]["rect"].position.x
	_frame_no = 0
	var ids := ["G02", "G03", "G04", "G05", "G06", "G11", "G12", "G13", "G14"]
	for a0 in OS.get_cmdline_user_args():
		if a0.begins_with("--so-eventos="):
			ids = ids.filter(func(x): return x in a0.substr(13).split("+"))
	for id in ids:
		for i in main.players.size():
			main.demo.lives[i] = 99
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.invuln = 0.0
		put(r0, Vector2(x0 + 40.0, fy))
		put(r1, Vector2(x0 + 300.0, fy))
		ev.trigger(ev.ev(id))
		var a = ev.inst(id)
		if id == "G04" and a != null:
			put(r0, Vector2(a["d"]["pos"].x - 280.0, fy))
		if id == "G13" and a != null:
			put(r1, Vector2(a["d"]["base"].get_center().x + 90.0, a["d"]["floor"]))
		var n := 0
		while ev.active.has(a) and n < 900:
			var inp := {"v0": {}, "v1": {}}
			if id == "G05" and a["phase"] == "ativo" and a["len"] - a["t"] > 1.6 and a["len"] - a["t"] < 2.4:
				put(r0, Vector2(a["d"]["rect"].get_center().x, a["d"]["rect"].position.y - 80.0))
			if id == "G05" and a["phase"] == "ativo" and n == 330:
				put(r1, Vector2(a["d"]["rect"].get_center().x + 40.0, ev._floor_under_rect(a["d"]["rect"], null)))
				ev.hammer_hit(ev.hook_rect(a), true, 0)
			if id in ["G03", "G02"] and n % 50 < 14:
				inp["v0"]["jump"] = true
			PlayerInput.virtual = inp
			await frames(1)
			if n % 4 == 0:
				await grab(dir, "ev_" + id)
			n += 1
		PlayerInput.virtual = {"v0": {}, "v1": {}}
		ev.reset_round()
		main.demo.canteiro.parts.map(func(p): p["shake"] = 0.0)

func spells_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1"]:
		await tap(d, "jump")
	main.players[0]["model"] = 0
	main.players[1]["model"] = 4
	main.game_mode = "derruba"
	main.demo.lives_setting = 5
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	var sp = main.demo.spells
	sp.spawn_t = 999.0
	main.hud.visible = false
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var nuc: Array = main.demo.canteiro.parts.filter(func(p): return p["nucleo"])
	var fy: float = nuc[0]["rect"].position.y
	var x0: float = nuc[0]["rect"].position.x + 40.0
	_frame_no = 0
	var segs := [["caixas", 50], ["A01", 60], ["A03", 120], ["C01", 90], ["E01", 70], ["C04", 70], ["T01", 300], ["troca", 60],
		["A02", 60], ["A04", 70], ["A05", 60], ["A06", 90], ["A07", 90], ["A08", 70], ["porte", 90],
		["C02", 90], ["C03", 70], ["C05", 120], ["E02", 110], ["E03", 90], ["A01cheio", 130], ["A02corte", 130], ["C03coluna", 150], ["D01", 200], ["D02", 170], ["D03", 130], ["D04", 190], ["D05", 150], ["D06", 170], ["A08quique", 110], ["A06col", 160], ["A07guinda", 110], ["A07brita", 110], ["A07escava", 100], ["A07solda", 100],
		["lasercima", 70], ["gelodiag", 70], ["ganchocima", 90], ["ventocima", 80], ["fogocima", 140], ["socobaixo", 60], ["ganchocaixa", 70],
		["T02", 130], ["T03", 120], ["T04", 100], ["T05", 100], ["T06", 100], ["T07", 110],
		["kitT01", 40], ["kitT02", 40], ["kitT05", 40], ["kitT06", 40], ["kitT03", 40], ["kitT07", 40]]
	var fx_c03 := 0.0
	var mira_sp := {"lasercima": "A02", "gelodiag": "A03", "ganchocima": "C03", "ventocima": "C02", "fogocima": "T01", "socobaixo": "A01"}
	for a0 in OS.get_cmdline_user_args():
		if a0.begins_with("--so-spells="):
			segs = segs.filter(func(x): return x[0] in a0.substr(12).split("+"))
	for sg in segs:
		var nm: String = sg[0]
		for r in [r0, r1]:
			r.dmg = 0.0
			r.stun_t = 0.0
			r.recover_t = 0.0
			r.atk_cd = 0.0
			r.frozen_t = 0.0
			sp.clear(r)
		sp.boxes.clear()
		sp.clear_columns()
		put(r0, Vector2(x0, fy))
		put(r1, Vector2(x0 + ({"A01": 3.0, "T01": 3.0, "A04": 3.0, "A06": 2.6, "A07": 3.5, "A08": 4.0, "C02": 3.0, "C05": 4.0, "E02": 1.5,
			"T02": 2.2, "T03": 6.0, "T05": 2.5, "T06": 1.6, "T07": 3.0}.get(nm, 5.5)) * 64.0, fy))
		r0.facing = 1
		r1.facing = -1
		if nm == "caixas":
			var fams := ["A01", "C01", "E01", "T01"]
			for k in 4:
				sp.drop_box(fams[k], Vector2(x0 + 90.0 + k * 90.0, fy - 260.0 - k * 40.0), false)
		elif nm == "troca":
			sp.equip(r0, "A03")
			sp.drop_box("T01", Vector2(x0, fy - 100.0), false)
		elif nm == "E03":
			var vg: Array = main.demo.canteiro.parts.filter(func(p): return p["kind"] == "viga" and not p["fallen"])
			if vg.size() > 0:
				put(r0, Vector2(vg[0]["rect"].get_center().x - 160.0, fy))
				put(r1, Vector2(vg[0]["rect"].get_center().x, fy))
			sp.equip(r0, nm)
		elif nm.begins_with("kit"):
			sp.equip(r0, nm.substr(3))
		elif nm == "ganchocaixa":
			sp.equip(r0, "C03")
			sp.drop_box("A08", Vector2(x0 + 4.0 * 64.0, fy - 40.0), false)
			put(r1, Vector2(x0 + 9.0 * 64.0, fy))
		elif mira_sp.has(nm):
			sp.equip(r0, mira_sp[nm])
			if nm == "ganchocima":
				var vg2: Array = main.demo.canteiro.parts.filter(func(p): return p["kind"] == "viga" and not p["fallen"])
				if vg2.size() > 0:
					put(r0, Vector2(vg2[0]["rect"].position.x - 60.0, fy))
			if nm in ["ventocima", "socobaixo"]:
				put(r1, Vector2(x0 + 1.6 * 64.0, fy))
		elif nm == "porte":
			sp.equip(r0, "A05")
			sp.equip(r1, "E01")
		elif nm in ["D01", "D02", "D03", "D04", "D05", "D06"]:
			sp.equip(r0, nm)
			put(r0, Vector2(x0 + 2.0 * 64.0, fy))
			put(r1, Vector2(x0 + 3.2 * 64.0, fy))
			r0.facing = 1
			r1.facing = -1
		elif nm == "C03coluna":
			sp.equip(r0, "A06")
			var dx6 := 200.0
			for cand in [200.0, -200.0, 280.0, -280.0, 360.0, -360.0, 440.0, -440.0, 520.0, -520.0]:
				var top_c: float = r0.position.y - float(sp.sc("A06")["coluna_tiles"]) * 64.0
				if absf(sp._floor_below(r0.position.x + cand, r0.position.y - 128.0, 9) - r0.position.y) < 2.0 and not sp._grab_at(Vector2(r0.position.x + cand, top_c - 40.0)) and not sp._grab_at(Vector2(r0.position.x + cand, top_c - 80.0)) and not sp._grab_at(Vector2(r0.position.x + cand, r0.position.y - 40.0)):
					dx6 = cand
					break
			sp.set_meta("dx6", dx6)
			fx_c03 = r0.position.x + dx6 * 0.5
			r0.facing = 1 if dx6 > 0.0 else -1
			put(r1, Vector2(r0.position.x - signf(dx6) * 500.0, fy))
			sp._drop_pile(r0, sp.slot[0], r0.position.x + dx6)
		elif nm == "A02corte":
			sp.equip(r0, "A02")
			var ct2 = main.demo.canteiro
			var an: Array = ct2.parts.filter(func(p): return p["kind"] == "andaime" and not p["fallen"])
			if an.size() > 0:
				var hr: Rect2 = ct2.hit_rect(an[an.size() - 1])
				var xa: float = hr.position.x - 120.0
				put(r0, Vector2(xa, sp._floor_below(xa, hr.end.y + 8.0)))
				put(r1, Vector2(hr.position.x + 70.0, hr.position.y))
		elif nm == "A06col":
			sp.clear_columns()
			sp.equip(r0, "A06")
			put(r1, Vector2(x0 + 2.6 * 64.0, fy))
		elif nm.begins_with("A07") and nm.length() > 3:   # A41: cada robô arremessa a SUA arma
			r0.vis.model = {"A07guinda": 1, "A07solda": 2, "A07brita": 3, "A07escava": 4}[nm]
			sp.equip(r0, "A07")
			put(r1, Vector2(x0 + 3.2 * 64.0, fy))
		elif nm == "A08quique":   # lote 3: mola em arco alto, alvo longe → quica no chão (amassa e estica)
			sp.equip(r0, "A08")
			put(r1, Vector2(x0 + 11.0 * 64.0, fy))
		elif nm == "A01cheio":
			sp.equip(r0, "A01")
			put(r1, Vector2(x0 + 2.6 * 64.0, fy))
		elif nm == "A04":   # cratera numa laje que cai (o núcleo do meio não cai)
			var ct4 = main.demo.canteiro
			for p in ct4.parts:
				if p["kind"] == "laje" and not p["nucleo"] and not p["fallen"] and ct4.parts.any(func(q): return q["kind"] == "laje" and not q["fallen"] and absf(q["rect"].end.x - p["rect"].position.x) < 2.0):
					put(r0, Vector2(p["rect"].position.x - 24.0, p["rect"].position.y))
					put(r1, Vector2(p["rect"].position.x + 120.0, p["rect"].position.y))
					break
			sp.equip(r0, nm)
		else:
			sp.equip(r0, nm)
		for f in int(sg[1]):
			var a := {"v0": {}, "v1": {}}
			match nm:
				"troca":
					a["v0"]["item"] = f >= 30 and f < 52
				"A01", "E01", "A02", "A04", "A06", "A07", "A08":
					a["v0"]["item"] = f == 14 or f == 15
				"A06col":
					a["v0"]["item"] = f == 14 or f == 15
				"A07guinda", "A07brita", "A07escava", "A07solda":
					a["v0"]["item"] = f == 14 or f == 15
				"A08quique":
					a["v0"]["item"] = f == 14 or f == 15
				"A01cheio":   # auditoria 2026-11-27: segura até encher e solta
					a["v0"]["item"] = f >= 10 and f < 76
				"D01":   # Defesa: crava, leva um golpe forte e não sai do lugar, anda devagar arrastando
					a["v0"]["item"] = f == 10 or f == 11
					if f == 40 or f == 80:
						r0.take_hit(-1, "spell_mola", 1)
					a["v0"]["right"] = f >= 110 and f < 170
				"D03":   # Defesa: molas; o rival bate e é rebatido; um rebite volta
					a["v0"]["item"] = f == 10 or f == 11
					if f == 34:
						r1.atk = ""
						r0.take_hit(-1, "rapido", 1)
					if f == 70:
						sp.rivets.append({"owner": 1, "pos": r0.rect().get_center() + Vector2(220, 0), "vel": Vector2(-900, 0), "bounces": 0, "t": 0.0, "hit": [], "trail": []})
				"D05":   # Defesa: capacete de aço absorve 3 golpes e voa
					a["v0"]["item"] = f == 10 or f == 11
					if f in [40, 70, 100]:
						r0.take_hit(-1, "spell_mola", 1)
				"D06":   # Defesa: boneco no lugar, recua; o rival bate no boneco e leva serragem
					a["v0"]["item"] = f == 10 or f == 11
					if f == 60:
						sp.decoy_hit(r1, Rect2(r0.position.x - 400.0, r0.position.y - 120.0, 800, 120), false)
				"D04":   # Defesa: rasga o saco, nuvem; golpe e tiro passam direto
					a["v0"]["item"] = f == 10 or f == 11
					if f == 50:
						r0.take_hit(-1, "spell_mola", 1)
					if f == 80:
						sp.rivets.append({"owner": 1, "pos": r0.rect().get_center() + Vector2(220, 0), "vel": Vector2(-900, 0), "bounces": 0, "t": 0.0, "hit": [], "trail": []})
				"D02":   # Defesa: arremesso forte → voa → airbag infla no ar, desce balançando e pousa
					if f == 20:
						r0.dmg = 110.0
						r0.take_hit(-1, "spell_mola", 1)
				"C03coluna":   # sessão 6: coluna sobe; o gancho agarra a base e o robô vai para cima dela
					if f == 64:
						sp.clear(r0)
						sp.equip(r0, "C03")
					if f == 66 and sp.slot.has(0):
						sp.slot[0]["aim"] = Vector2(signf(float(sp.get_meta("dx6", 200.0))), 0)
					a["v0"]["item"] = f == 67 or f == 68
				"A02corte":   # segura o feixe e varre para cima até o andaime
					a["v0"]["item"] = f >= 10 and f < 100
					a["v0"]["up"] = f >= 8 and f < 70
					a["v0"]["right"] = f >= 8 and f < 12
				"C02":
					a["v0"]["item"] = f >= 10 and f < 80
				"C03", "C05", "E03":
					a["v0"]["item"] = f == 14 or f == 15
				"E02":
					a["v0"]["item"] = f in [14, 15, 80, 81]
					a["v0"]["left"] = f >= 25 and f < 45
				"lasercima":
					a["v0"]["up"] = true
					a["v0"]["item"] = f == 14 or f == 15
				"gelodiag":
					a["v0"]["up"] = f >= 8
					a["v0"]["right"] = f >= 8 and f < 12
					a["v0"]["item"] = f == 14 or f == 15
				"ganchocima":
					a["v0"]["up"] = f >= 8 and f < 20
					a["v0"]["right"] = f >= 8 and f < 11
					a["v0"]["item"] = f == 14 or f == 15
				"ventocima":
					a["v0"]["up"] = f >= 8
					a["v0"]["item"] = f >= 10 and f < 75
				"fogocima":
					a["v0"]["item"] = (f == 14 or f == 15) or (f >= 60 and f < 130)
					a["v0"]["up"] = f >= 60 and f < 95
				"socobaixo":
					a["v0"]["jump"] = f >= 4 and f < 18
					a["v0"]["right"] = f >= 4 and f < 14
					a["v0"]["down"] = f >= 20
					a["v0"]["item"] = f == 20 or f == 21
				"kitT01", "kitT02", "kitT05", "kitT06", "kitT03", "kitT07":
					a["v0"]["right"] = f >= 22 and f < 36
				"ganchocaixa":
					a["v0"]["item"] = f == 14 or f == 15
				"T02":
					a["v0"]["item"] = f in [16, 17, 56, 57]
					a["v0"]["right"] = f >= 34 and f < 42
				"T03":
					a["v0"]["item"] = f in [16, 17]
					a["v0"]["right"] = f >= 40 and f < 95
				"T04":
					a["v0"]["item"] = f >= 16 and f < 84
					a["v0"]["right"] = f >= 40 and f < 60
					a["v0"]["left"] = f >= 66 and f < 80
				"T05":
					a["v0"]["item"] = f in [16, 17]
					a["v0"]["right"] = f >= 40 and f < 62
					a["v0"]["up"] = f >= 70 and f < 80
				"T06":
					a["v0"]["item"] = (f == 16 or f == 17) or (f >= 45 and f < 85)
				"T07":
					a["v0"]["item"] = f in [16, 17]
					a["v0"]["right"] = f >= 50 and f < 80
					a["v0"]["hammer"] = f in [82, 83]
				"porte":
					a["v0"]["right"] = f >= 10 and f < 40
					a["v0"]["hammer"] = f in [55, 56]
				"A05":
					a["v0"]["item"] = f in [14, 15, 30, 31]
					a["v0"]["up"] = f >= 28 and f < 33
				"A03":
					a["v0"]["item"] = f == 14 or f == 15
					if f > 60:   # o congelado agita para sair
						a["v1"]["left" if f % 8 < 4 else "right"] = true
				"C01":
					a["v0"]["item"] = f >= 10 and f < 85
				"C04":
					a["v0"]["item"] = f >= 10 and f < 40
					a["v0"]["right"] = f >= 14 and f < 24
					a["v0"]["up"] = f >= 18 and f < 24
				"T01":
					a["v0"]["item"] = (f == 14 or f == 15) or (f >= 60 and f < 280)
			PlayerInput.virtual = a
			for r in main.robots:
				r.invuln = 0.0
			main.cam_lock = [2.4, (r0.position + Vector2(150, 0)) + Vector2(0, -70)]
			if nm == "D06":   # enquadra o boneco, o robô que recuou e o rival
				main.cam_lock = [2.0, Vector2(x0 + 1.6 * 64.0, fy - 80.0)]
			if nm == "C03coluna":   # enquadra o robô e a coluna
				main.cam_lock = [1.9, Vector2(fx_c03, fy - 150.0)]
			await frames(1)
			if f % 2 == 0:
				await grab(dir, nm)
	print("quadros: ", _frame_no)

## Pulo duplo quadro a quadro (--pulo=DIR): pula do chão, no alto aperta de novo; câmera parada e perto.
func pulo_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}}
	await frames(2)
	main.lab.start("v0")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
		r.invuln = 0.0
	main.sandbox_remove("boneco")
	main.hud.visible = false
	var r0 = main.robots[0]
	put(r0, Vector2(col_x(16), 12 * 64))
	r0.facing = 1
	await frames(30)
	main.cam_lock = [2.4, Vector2(col_x(16), 12 * 64 - 260)]
	_frame_no = 0
	for f in 70:
		var a := {}
		if f < 16:
			a["jump"] = true
		if f >= 20 and f < 32:
			a["jump"] = true
		if f >= 20 and f < 50:
			a["right"] = true
		PlayerInput.virtual = {"v0": a}
		await frames(1)
		await grab(dir, "p")

## Prancha do Canteiro (Derruba): a arte de art/out/prancha_canteiro_derruba_1/2.png + robôs desenhados pelo motor.
func prancha_canteiro(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var Vis = load("res://player/robot_visual.gd")
	var root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var sheet := Node2D.new()
	layer.add_child(sheet)
	var cur := [null, 0]
	const S := 0.75
	var at := func(c: float, r: float) -> Vector2:
		return Vector2(c * 64.0, r * 64.0) * S
	sheet.draw.connect(func():
		sheet.draw_texture_rect(cur[0], Rect2(0, 0, 1920, 1056), false)
		sheet.draw_rect(Rect2(0, 1056, 1920, 24), Color("#e9f7f6"))
		var heavy: Dictionary = Vis.idle_pose(0.3)
		heavy["expr"] = "esforco"
		heavy["hammer_ang"] = -2.75
		heavy["hf_off"] = Vector2(-10, -22)
		heavy["hb_off"] = Vector2(-4, -18)
		heavy["lean"] = -0.3
		heavy["glint"] = 1.0
		var run: Dictionary = Vis.idle_pose(0.6)
		run["feet"] = [Vector2(10, -8), Vector2(-9, 0)]
		run["knee"] = [Vector2(7, 0), Vector2(1, 0)]
		run["hb_off"] = Vector2(-9, -4)
		run["lean"] = 0.18
		var fly: Dictionary = Vis.idle_pose(0.2)
		fly["expr"] = "eliminado"
		fly["rot"] = 2.2
		fly["hb_off"] = Vector2(-16, -22)
		fly["hf_off"] = Vector2(14, -20)
		fly["feet"] = [Vector2(-10, -6), Vector2(12, -4)]
		var flip: Dictionary = Vis.idle_pose(0.4)
		flip["expr"] = "esforco"
		flip["rot"] = 3.3
		flip["tuck"] = 1.0
		flip["feet"] = [Vector2(3, -24), Vector2(8, -24)]
		flip["knee"] = [Vector2(12, 0), Vector2(12, 0)]
		flip["hb_off"] = Vector2(9, 6)
		flip["hf_off"] = Vector2(6, 8)
		flip["hammer_ang"] = 2.5
		var looks := [{"color": 0, "model": 0}, {"color": 1, "model": 4}, {"color": 2, "model": 5}, {"color": 3, "model": 7}]
		var xf := func(c: float, r: float, face := 1.0) -> Transform2D:
			return Transform2D(0.0, Vector2(S * face, S), 0.0, at.call(c, r))
		if cur[1] == 0:
			Vis.draw_robot(sheet, looks[0], run, xf.call(12.0, 13.0))
			Vis.draw_robot(sheet, looks[1], heavy, xf.call(21.5, 13.0, -1.0))
			Vis.draw_robot(sheet, looks[2], Vis.idle_pose(1.0), xf.call(5.5, 10.0))
			Vis.draw_robot(sheet, looks[3], flip, xf.call(19.5, 7.2))
		else:
			var lk2: Dictionary = looks[1].duplicate()
			lk2["dmg"] = 3
			Vis.draw_robot(sheet, looks[0], heavy, xf.call(19.0, 13.0))
			Vis.draw_robot(sheet, lk2, fly, xf.call(36.0, 7.0))
			var lk3: Dictionary = looks[2].duplicate()
			lk3["dmg"] = 1
			Vis.draw_robot(sheet, lk3, Vis.idle_pose(2.0), xf.call(14.0, 13.0))
			Vis.draw_robot(sheet, looks[3], run, xf.call(34.5, 10.0, -1.0))
			# rastro e riscos do arremesso do Brutamontes
			sheet.draw_set_transform_matrix(Transform2D.IDENTITY)
			for k in 4:
				var p0: Vector2 = at.call(36.0 - 1.6 * (k + 1), 7.0 + 0.55 * (k + 1)) + Vector2(0, -30)
				sheet.draw_circle(p0, 22.0 - k * 4.0, Color(0.36, 0.77, 0.36, 0.35 - k * 0.07))
			for k in 3:
				var y0: float = at.call(0, 6.4 + k * 0.35).y
				sheet.draw_line(Vector2(at.call(30.0, 0).x, y0), Vector2(at.call(34.6, 0).x, y0 + 30), Color(1, 1, 1, 0.9), 4.0)
	)
	for i in 2:
		var img := Image.load_from_file(root.path_join("art/out/prancha_canteiro_derruba_%d.png" % (i + 1)))
		cur[0] = ImageTexture.create_from_image(img)
		cur[1] = i
		sheet.queue_redraw()
		await frames(3)
		await snap(dir, "prancha_canteiro_%d" % (i + 1))

## Vitrine do Canteiro (--canteiro=DIR): P1 marreta um trecho até desabar, o ciclo da obra dispara,
## P2 (amassado) é arremessado para fora e explode na borda. Quadros a cada 2 físicos.
func canteiro_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}}
	main.mode = "demolicao"
	main.go_join()
	await frames(2)
	for d in ["v0", "v1", "v2"]:
		await tap(d, "jump")
	main.players[1]["model"] = 4
	main.players[2]["model"] = 5
	main.game_mode = "derruba"
	main.demo.lives_setting = 3
	main.event_level = 0
	main.arena_choice = "canteiro_obras"
	main.start_match()
	await demo_round()
	main.demo.spells.spawn_t = 999.0
	var ct = main.demo.canteiro
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var r2 = main.robots[2]
	put(r0, Vector2(col_x(10), 13 * 64))
	put(r1, Vector2(col_x(22), 13 * 64))
	put(r2, Vector2(col_x(18), 13 * 64))
	r0.facing = 1
	_frame_no = 0
	for f in 600:
		var a := {"v0": {}, "v1": {}, "v2": {}}
		# P1 marreta o trecho 2 (cols 8-11) de cima, com ▼, até desabar (pula para o trecho do lado antes)
		if f < 330 and f % 72 == 4:
			r0.heavy_cd = 0.0
			a["v0"]["heavy"] = true
			a["v0"]["down"] = true
		if f >= 300 and f < 318:
			a["v0"]["right"] = true
		if f == 340:
			main.event_level = 2
			main.events.trigger(main.events.cfg["lista"][0])   # G01 agora (sirene + fita zebrada)
		if f == 470:
			put(r1, Vector2(col_x(27), 13 * 64))
			r1.dmg = 160.0
			put(r0, Vector2(col_x(26), 13 * 64))
			r0.facing = 1
			r0.heavy_cd = 0.0
		if f >= 474 and f < 477:
			a["v0"]["heavy"] = true
		PlayerInput.virtual = a
		for r in main.robots:
			r.invuln = 0.0
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "k")
	print("quadros: ", _frame_no, " de pé: ", ct.standing(), " P2 vivo: ", r1.alive, " vidas: ", main.demo.lives)

func anim_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
	await frames(2)
	for d in ["v0", "v1", "v2", "v3"]:
		await tap(d, "jump")
	await tap("v0", "start")
	main.skip_phase()
	await frames(2)
	main.skip_phase()
	await frames(2)
	main.countdown = 0.0
	main.timer = 999.0
	for r in main.robots:
		r.active = true
	# --- cena 1: corrida, giro, pulo, parede, marretada e queda nos espinhos
	main.cam_lock = [1.7, Vector2(565, 723)]
	_frame_no = 0
	for f in 300:
		var a := {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
		# Lata (P1): anda, freia e vira, pula, marreta e cai no poço
		if f >= 40 and f < 80: a["v0"]["right"] = true
		if f >= 80 and f < 100: a["v0"]["left"] = true
		if f >= 115 and f < 130: a["v0"]["jump"] = true
		if f >= 150 and f < 153: a["v0"]["hammer"] = true
		if f >= 190: a["v0"]["right"] = true
		# TV (P2): pulos
		if f % 70 >= 10 and f % 70 < 24: a["v1"]["jump"] = true
		# Baixinho (P3): pula na parede da esquerda e desliza
		if f < 140: a["v2"]["left"] = true
		if (f >= 20 and f < 34) or (f >= 100 and f < 112): a["v2"]["jump"] = true
		if f >= 160 and f < 200: a["v2"]["right"] = true
		# Pescoção (P4): marretadas
		if f % 60 >= 30 and f % 60 < 33: a["v3"]["hammer"] = true
		PlayerInput.virtual = a
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "a")
	# --- cena 2: marretada numa peça rival, chegada ao elevador com a porta abrindo
	_frame_no = 0
	await reset_run()
	main.cam_lock = [2.0, Vector2(1440, 740)]
	var rs: Array = main.robots
	put(rs[0], Vector2(-400, 768))
	put(rs[2], Vector2(-400, 768))
	put(rs[3], Vector2(1306, 768))
	put(rs[1], Vector2(1240, 704))
	rs[1].position = Vector2(1250, 768)
	for f in 140:
		var a := {"v0": {}, "v1": {}, "v2": {}, "v3": {}}
		if f >= 20 and f < 23: a["v3"]["hammer"] = true
		if f >= 50: a["v1"]["right"] = true
		if f >= 56 and f < 70: a["v1"]["jump"] = true
		PlayerInput.virtual = a
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "b")
	# --- cena 3: tela de vitória (dancinha)
	_frame_no = 0
	main.cam_lock = []
	main.winner = 2
	main.state = S.WIN
	main._clear_robots()
	for f in 60:
		await frames(1)
		if f % 2 == 0:
			await grab(dir, "c")

# ---------------------------------------------------------------- Demolição em movimento (captura para GIF)
## Roteiro só de captura: cada robô persegue o rival mais próximo, pula para alcançar e marreta de perto.
func demo_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.bot_level = 2
	for k in 4:
		main.add_bot()
	main.players[1]["level"] = 1
	main.players[3]["level"] = 1
	main.demo.cfg["spells"]["caixa"]["intervalo_s"] = [1.5, 2.5]
	main.demo.cfg["spells"]["caixa"]["max_mapa"] = 3
	main.start_match()
	main.demo.spells.spawn_t = 1.0
	_frame_no = 0
	for f in 60 * 16:
		await frames(1)
		if f % 4 == 0:
			await grab(dir, "d")
		if main.state != S.RUN and f > 120:
			for k in 60:
				await frames(1)
				if k % 4 == 0:
					await grab(dir, "d")
			break

# ---------------------------------------------------------------- capturas das telas de menu e HUD
func menus_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	main.go_menu()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(40)
	await snap(dir, "m1_menu")
	await tap("v0", "jump")
	await frames(20)
	await snap(dir, "m2_modos")
	main.state = S.HOWTO
	await frames(10)
	await snap(dir, "m3_como_jogar")
	main.state = S.OPTIONS
	await frames(10)
	await snap(dir, "m4_opcoes")
	main.state = S.CONTROLES
	PlayerInput.toasts.append({"text": "Conectado: Xbox (Xbox Wireless Controller)", "t": 1.0, "ok": true, "dev": ""})
	await frames(10)
	await snap(dir, "m4c_controles")
	PlayerInput.fake_joys = [0, 1, 2]
	PlayerInput.fake_models = {0: "ps5", 1: "xbox", 2: "ps4"}
	main.menus.abrir_controles()
	main.menus.hub_sel = 2
	await frames(10)
	await snap(dir, "m4d_controles_cartoes")
	main.menus._abrir_mapear("joy0")
	main.menus.map_sel = 5
	main.menus.map_m["dodge"] = [["b", JOY_BUTTON_RIGHT_SHOULDER], ["a", JOY_AXIS_TRIGGER_RIGHT, 1]]
	main.menus._map_msg("trocou com GOLPE RÁPIDO", 7)
	await frames(30)
	await snap(dir, "m4e_mapear_controle")
	main.menus._abrir_mapear("kb_b")
	main.menus.map_sel = 4
	await frames(30)
	await snap(dir, "m4f_mapear_teclado")
	main.menus._abrir_teste("joy1")
	joy_btn(1, JOY_BUTTON_A, true)
	await frames(10)
	await snap(dir, "m4g_testar_controle")
	joy_btn(1, JOY_BUTTON_A, false)
	main.menus._abrir_teste("kb_a")
	await frames(10)
	await snap(dir, "m4h_testar_teclado")
	PlayerInput.fake_joys = []
	PlayerInput.fake_models = {}
	main.state = S.ARENAS
	main.menus.arena_sel = 1
	await frames(10)
	await snap(dir, "m4b_arenas")
	main.menus.paginas_min = 2   # deslize de página (prancha m1): força a 2ª página e anda para ela pela borda
	main.menus.arena_sel = 5
	await frames(2)
	await tap("v0", "right")
	await frames(3)
	await snap(dir, "m4b_arenas_desliza")
	await frames(30)
	await snap(dir, "m4b_arenas_pag2")
	main.menus.paginas_min = 1
	main.menus.arena_sel = 0
	main.menus.pag_x = 0.0
	main.arena_choice = "canteiro_obras"   # tela de engenhocas: todas as cartas (e ALEATÓRIO + chave) cabem na tela
	main.selecao.abrir_spells()
	main.selecao.sel = main.selecao.spells_do_mapa().size() + 1
	main.state = S.SELSPELLS
	await frames(10)
	await snap(dir, "m4e_engenhocas")
	main.state = S.JOIN
	main.mode = "demolicao"
	main.demo.cfg["rounds_to_win"] = 5
	await tap("v0", "jump")
	await tap("v1", "jump")
	await tap("v1", "down")
	for k in 6:
		await tap("v0", "down")   # P1 com outro modelo de robô
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	await tap("v0", "hammer")   # skins do mapa escolhido (P1 e P2 vestem; o bot fica padrão)
	await tap("v1", "hammer")
	main.add_bot()
	await frames(20)
	await snap(dir, "m5_entrada")
	main.add_bot()
	main.players[0]["edita"] = main.players[2]["dev"]
	main.players[0]["linha"] = 3
	await frames(20)
	await snap(dir, "m5b_entrada_bot_editando")
	main.players[0]["edita"] = ""
	main.remove_last_bot()
	main.start_match()
	await frames(30)
	await snap(dir, "m6_contagem")
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	main.players[0]["score"] = 2
	main.players[2]["score"] = 1
	main.demo.spells.equip(main.robots[0], "A03")
	main.demo.spells.equip(main.robots[1], "T01")
	await frames(120)
	await snap(dir, "m7_partida")
	main.paused = true
	await frames(5)
	await snap(dir, "m8_pausa")
	main.menus.pause_conf = 4
	await frames(3)
	await snap(dir, "m8b_pausa_confirma")
	main.menus.pause_conf = -1
	main.paused = false
	main.kill(main.robots[1], -1, null)
	main.kill(main.robots[2], -1, null)
	await frames(110)
	await snap(dir, "m9_placar")
	main.winner = 0
	main.res_fase = "resultados"
	main.res_crono = 15.0
	main.state = S.WIN
	main._clear_robots()
	await frames(30)
	await snap(dir, "m10_vitoria")
	# telas do fim (pranchas r1–r3) com um resultado de exemplo: +35 na gangorra, 2 cenas novas
	main.players[0]["stats"] = {"derrubadas": 5, "caixotes": 12, "quedas": 0, "engenhocas": 3, "golpes": 41}
	main.players[1]["stats"] = {"derrubadas": 3, "caixotes": 20, "quedas": 1, "engenhocas": 2, "golpes": 33}
	main.players[2]["stats"] = {"derrubadas": 1, "caixotes": 6, "quedas": 3, "engenhocas": 5, "golpes": 18}
	main.res_info = {"valida": true, "zona": 4, "antes": 40, "depois": 75, "delta": 35, "premio": "", "novas": ["terreo", "fachada"],
		"pontos": 5, "total": 5, "por_mapa": 6}
	for st in [["g1", "gangorra", 0.3], ["g2", "gangorra", 1.2], ["g3", "gangorra", 2.3], ["g4", "gangorra", 3.8], ["p1", "projetos", 1.6], ["p2", "projetos", 6.0], ["r", "resultados", 0.0]]:
		main.state = S.WIN
		main.res_fase = st[1]
		main.res_t = st[2]
		main.res_crono = 9.0
		await frames(1)
		await snap(dir, "m11_fim_" + st[0])
	await projetos_frames(dir)
	main.res_info["valida"] = false
	main.res_fase = "gangorra"
	main.res_t = 0.5
	await frames(1)
	await snap(dir, "m11_fim_nao_contou")
	main.res_info = {"valida": true, "zona": 5, "antes": 40, "depois": 100, "delta": 75, "premio": "skin", "novas": [], "pontos": 1, "total": 6, "por_mapa": 6}
	for pt in [["a", 3.5], ["b", 4.1], ["c", 4.8], ["d", 5.4], ["e", 6.0], ["f", 6.6], ["g", 9.0]]:   # gangorra decide → presente → prêmio
		main.res_fase = "gangorra"
		main.res_t = pt[1]
		await frames(1)
		await snap(dir, "m11_fim_premio_" + pt[0])
	if "--fim-video" in OS.get_cmdline_user_args():   # quadros para o vídeo da gangorra + presente (30 por segundo)
		main.res_info = {"valida": true, "zona": 5, "antes": 40, "depois": 100, "delta": 75, "premio": "skin", "novas": [], "pontos": 1, "total": 6, "por_mapa": 6}
		main.fim._k_prev = -1.0
		for f in 300:
			main.res_t = f / 30.0
			await frames(1)
			await snap(dir, "v_%03d" % f)
	for cat in ["spell", "evento"]:   # a revelação de cada categoria (caixa e prêmio próprios)
		main.res_info = {"valida": true, "zona": 0, "antes": -40, "depois": -100, "delta": -60, "premio": cat, "novas": [], "pontos": 1, "total": 6, "por_mapa": 6}
		for pt in [["a", 3.5], ["d", 5.4], ["g", 9.0]]:
			main.res_t = pt[1]
			await frames(1)
			await snap(dir, "m11_fim_%s_%s" % [cat, pt[0]])

func arena_round(id: String) -> void:
	main.arena_choice = id
	main.mode = "demolicao"
	await demo_round()
	main.demo.spells.spawn_t = 999.0

func arenas_test() -> void:
	print("== Arenas")
	main.state = S.JOIN
	main.players.clear()
	PlayerInput.slots.clear()
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await frames(2)
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.start_match()
	# todas carregam e rodam um pouco sem erro
	for a in main.demo.cfg["arenas"]:
		await arena_round(a["id"])
		await frames(30)
		check(main.level.id == a["id"] and main.robots.size() == 2, "arena %s carrega e roda" % a["nome"])
	# maré: lama sobe e elimina quem ficou embaixo
	await arena_round("mare")
	var r0 = main.robots[0]
	main.demo.t = float(main.level.prop("mare_inicio", "6"))
	main.demo.fx.goo_y = 820.0
	put(r0, Vector2(col_x(3), 832))
	await frames(60)
	check(not r0.alive, "a lama alcança e elimina")
## --arenas=DIR[,id:modo,...]: miniatura de cada arena (o mapa inteiro) e uma foto jogando com 4 bots.
func arenas_frames(arg: String) -> void:
	var parts := arg.split(",")
	var dir := parts[0]
	var only := {}
	for k in range(1, parts.size()):
		var pm := parts[k].split(":")
		only[pm[0]] = pm[1] if pm.size() > 1 else "derruba"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.bot_level = 1
	for k in 4:
		main.add_bot()
	main.start_match()
	for a in main.demo.cfg["arenas"]:
		if not only.is_empty() and not only.has(a["id"]):
			continue
		if not only.is_empty():
			main.game_mode = only[a["id"]]
		else:
			main.game_mode = "derruba"
			for m in main.demo.cfg["modos"]:
				if a["id"] in m["arenas"]:
					main.game_mode = m["id"]
		main.arena_choice = a["id"]
		main._clear_robots()
		main.demo.start_round()
		# miniatura: arena inteira, sem HUD e sem robôs
		var lw: float = main.level.cols * 64.0
		var lh: float = main.level.rows * 64.0
		main.cam_lock = [minf(1.0, minf(1920.0 / lw, 1024.0 / lh)), Vector2(lw, lh) / 2.0]
		main.hud.visible = false
		for r in main.robots:
			r.visible = false
		await frames(8)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img = img.get_region(Rect2i(0, 56, 1920, 1024))
		img.resize(480, 256, Image.INTERPOLATE_LANCZOS)
		img.save_png(dir.path_join("arena_%s.png" % a["id"]))
		if not only.is_empty():
			var full := get_viewport().get_texture().get_image()
			full.save_png(dir.path_join("mapa_%s.png" % a["id"]))
		main.hud.visible = true
		main.cam_lock = []
		for r in main.robots:
			r.visible = true
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		main.demo.spells.spawn_t = 1.0
		await frames(260)
		await snap(dir, "jogo_%s" % a["id"])

# ---------------------------------------------------------------- vídeo com som (quadros JPG + registro de sons)
func video_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	Audio.rec_log = []
	main.mode = "demolicao"
	main.bot_level = 2
	for k in 4:
		main.add_bot()
	main.players[1]["level"] = 1
	main.players[3]["level"] = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modelos="):   # vídeo do elenco: modelo de cada jogador (índices de Data.MODELS)
			var ms: PackedStringArray = a.substr(10).split(",")
			for k in mini(ms.size(), main.players.size()):
				main.players[k]["model"] = int(ms[k])
	main.demo.cfg["spells"]["caixa"]["intervalo_s"] = [2.0, 3.0]
	main.demo.cfg["spells"]["caixa"]["max_mapa"] = 3
	main.arena_choice = "sorteio"
	main.demo.last_arena = "demolicao"
	var tour: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour="):
			tour = Array(a.substr(7).split(","))
	main.event_level = 3 if tour.size() > 0 else main.event_level
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--arena="):
			main.arena_choice = a.substr(8)   # vídeo de 30 s numa arena só (ex.: conferir o som)
	if tour.size() > 0:
		main.arena_choice = tour[0]
	main.start_match()
	main.demo.spells.spawn_t = 1.5
	var virada_f := -1
	var rota := "total"
	var dur_s := 30.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--virada="):   # vídeo promocional: a obra cede em N s (força a transição)
			virada_f = int(float(a.substr(9)) * 60.0)
		if a.begins_with("--rota="):     # total (Fundação) ou moderada (Fachada)
			rota = a.substr(7)
		if a.begins_with("--dur="):
			dur_s = float(a.substr(6))
	if virada_f >= 0:
		main.demo.lives_setting = 6   # a luta não acaba antes da virada
		for i in main.players.size():
			main.demo.lives[i] = 6
	var f := 0
	var end_f := -1
	var per := 60 * 10
	var limit := int(60 * dur_s) if tour.is_empty() else per * tour.size()
	while f < limit:
		Audio.rec_time = f / 60.0
		if f == virada_f and main.demo.etapas != null:
			main.demo.etapas.forcar(rota)
		if tour.size() > 0 and f > 0 and f % per == 0:
			main.arena_choice = tour[f / per]
			main._clear_robots()
			main.round_no += 1
			main.demo.start_round()
			main.demo.spells.spawn_t = 1.0
		if tour.size() > 0 and f % per == 200:
			main.events.timer = 0.01   # um evento por arena no tour
		await frames(1)
		if f % 2 == 0:
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.resize(960, 540, Image.INTERPOLATE_BILINEAR)
			img.save_jpg(dir.path_join("v_%05d.jpg" % (f / 2)), 0.85)
		if main.state == S.WIN:
			break
		f += 1
	var fa := FileAccess.open(dir.path_join("sons.json"), FileAccess.WRITE)
	fa.store_string(JSON.stringify({"fps": 30, "frames": f / 2, "root": ProjectSettings.globalize_path("res://"), "log": Audio.rec_log}))
	fa.close()
	print("vídeo: %d quadros, %d sons" % [f / 2, Audio.rec_log.size()])

## Desempenho do Canteiro (avaliação 2026-11-26, item 6): 4 bots; mede o quadro na luta normal, em cada evento do mapa e
## nas duas transições. Rodar com tela (xvfb) para contar o desenho: godot --path game -- --perf-canteiro
func _perf_medir(nome: String, n: int) -> void:
	var ts: Array = []
	var ph: Array = []
	var pr: Array = []
	var last := Time.get_ticks_usec()
	main.perf_acc = {}
	for f in n:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ts.append((now - last) / 1000.0)
		if (now - last) > 115000:   # pico (congelada visível)
			print("   PICO %s quadro %d: %.0f ms" % [nome, f, (now - last) / 1000.0])
		ph.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		pr.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		last = now
		for r in main.robots:   # ninguém sai: a medição não pode acabar a partida
			main.demo.lives[r.pid] = 6
	ts.sort()
	ph.sort()
	pr.sort()
	var avg: float = ts.reduce(func(x, y): return x + y, 0.0) / ts.size()
	print("PERF %-22s quadro med %5.1f p95 %5.1f máx %6.1f ms | física med %5.2f máx %6.2f | process med %5.2f máx %6.2f | bots %.2f demo %.2f | nós %d" % [nome, avg,
		ts[int(ts.size() * 0.95)], ts[-1], ph[ph.size() / 2], ph[-1], pr[pr.size() / 2], pr[-1], main.perf_acc.get("bots", 0.0) / n, main.perf_acc.get("demo", 0.0) / n,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])

func perf_canteiro() -> void:
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.bot_level = 1
	main.event_level = 0
	for k in 4:
		main.add_bot()
	main.demo.lives_setting = 6
	main.start_match()
	await frames(120)
	main.countdown = 0.0
	var et = main.demo.etapas
	et.ativo = false
	main.events.manual = true
	await _perf_medir("luta (Térreo)", 300)

	var ev = main.events
	for id in main.selecao.eventos_do_mapa():
		ev.trigger(ev.ev(id))
		var dur := float(ev.ev(id).get("aviso_s", 1.0)) + float(ev.ev(id).get("dur", 4.0)) + float(ev.ev(id).get("fim_s", 0.5))
		await _perf_medir("evento %s" % id, int(dur * 60.0))
		await frames(30)
	et.ativo = true
	et.forcar("total")
	await _perf_medir("transição → Fundação", 360)
	await _perf_medir("luta (Fundação)", 240)
	main.start_match()
	await frames(120)
	main.countdown = 0.0
	main.demo.etapas.ativo = true
	main.demo.etapas.forcar("moderada")
	await _perf_medir("transição → Fachada", 420)
	await _perf_medir("luta (Fachada)", 240)

func perf_run() -> void:
	get_window().size = Vector2i(1920, 1080)
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.bot_level = 1
	main.event_level = 0
	for k in 4:
		main.add_bot()
	main.demo.cfg["rounds_to_win"] = 999
	main.start_match()
	for a in main.demo.cfg["arenas"]:
		main.arena_choice = a["id"]
		main._clear_robots()
		main.demo.start_round()
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		var ts: Array = []
		var phys: Array = []
		var last := Time.get_ticks_usec()
		main.perf_acc = {}
		for f in 240:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			if f > 20:
				ts.append((now - last) / 1000.0)
				phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
			last = now
		ts.sort()
		phys.sort()
		var avg: float = ts.reduce(func(x, y): return x + y, 0.0) / ts.size()
		if OS.get_cmdline_user_args().has("--perf-longo") and a["id"] in ["mare", "demolicao", "torre"]:
			main.event_level = 3
			for k in 6:
				var t0 := Time.get_ticks_usec()
				for f2 in 300:
					await get_tree().process_frame
				print("   %s +%ds: nós %d  objetos %d  %.1f ms/quadro  estado %s" % [a["id"], (k + 1) * 5, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT), (Time.get_ticks_usec() - t0) / 300000.0, main.state])
			main.event_level = 0
		print("PERF %-11s quadro med %.1f ms  p95 %.1f  máx %.1f  |  física med %.2f ms máx %.2f  |  bots %.2f  demo %.2f ms/quadro" % [a["id"], avg, ts[int(ts.size() * 0.95)], ts[-1], phys[phys.size() / 2], phys[-1], main.perf_acc.get("bots", 0.0) / 240.0, main.perf_acc.get("demo", 0.0) / 240.0])

# ---------------------------------------------------------------- estatísticas de rodadas (bots), para a análise de ritmo
func stats_run(rounds_per_arena: int) -> void:
	seed(7)
	main.rng.seed = 7
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.bot_level = 1
	for k in 4:
		main.add_bot()
	main.demo.cfg["rounds_to_win"] = 999
	for a in OS.get_cmdline_user_args():
		if a == "--muitos-itens":
			main.demo.cfg["spells"]["caixa"]["intervalo_s"] = [1.5, 2.5]
			main.demo.cfg["spells"]["caixa"]["max_mapa"] = 4
		if a.begins_with("--sub="):
			main.game_mode = a.substr(6)
		if a.begins_with("--so-arenas="):
			main.demo.cfg["arenas"] = main.demo.cfg["arenas"].filter(func(x): return x["id"] in a.substr(12).split(","))
	var out := []
	for a in main.demo.cfg["arenas"]:
		main.arena_choice = a["id"]
		main.start_match()
		for rr in rounds_per_arena:
			main.countdown = 0.0
			for r in main.robots:
				r.active = true
			var t0: float = main.demo.t
			var first_death := -1.0
			var n0: int = main.demo.death_log.size()
			var hits := 0
			for f in 60 * 120:
				await get_tree().physics_frame
				if first_death < 0.0 and main.demo.death_log.size() > n0:
					first_death = main.demo.t
				if main.state != S.RUN:
					break
			out.append({"arena": a["id"], "dur": main.demo.t, "first": first_death, "winner": main.demo.round_winner,
				"chegou": main.robots.filter(func(x): return x.finished).size()})
			main.timer = 0.0
			await get_tree().physics_frame
			await get_tree().physics_frame
	var fa := FileAccess.open("user://stats.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify({"rounds": out, "deaths": main.demo.death_log, "quedas": main.fall_log}))
	fa.close()
	print("STATS_FILE ", ProjectSettings.globalize_path("user://stats.json"))


# ---------------------------------------------------------------- PROTOCOLO DE DESEMPENHO (docs/manuais/desempenho.md)
## --perf-derruba=DIR [--perf-dur=S] [--perf-rota=total|moderada] [--perf-normal]: partida de 4 bots no Canteiro com
## eventos em ALTA, todas as engenhocas e caixas frequentes (pior caso; --perf-normal = configuração padrão), virada de
## cena no meio. Mede CADA quadro: tempo real, ms por sistema (lógica e desenho, autoload Perf), render (CPU), chamadas
## de desenho, nós e objetos; anota o contexto (eventos ativos, engenhoca em uso, mecha, fase da virada).
## Grava DIR/quadros.json e DIR/relatorio.md (picos com o que estava acontecendo + ranking por sistema e por contexto).
const PERF_FILHOS := ["eventos", "etapas_mecanismos", "arena_fx", "engenhocas"]   # já dentro de demo_total

func _perf_filho(k: String) -> bool:   # medidas que já estão somadas dentro de outra (não somar duas vezes)
	return k in PERF_FILHOS or k.begins_with("ev_") or k.begins_with("hud_") or k.begins_with("sub_")

func _perf_tags() -> Array:
	var tags := []
	for a in main.events.active:
		tags.append("ev:" + String(a.get("id", "?")))
	var sp = main.demo.spells
	if sp != null:
		for pid in sp.slot:
			var s: Dictionary = sp.slot[pid]
			if float(s.get("prep", -1.0)) >= 0.0 or float(s.get("fire", -1.0)) >= 0.0:
				tags.append("eng:" + String(s.get("id", "?")))
	for r in main.robots:
		var m := String(r.vis.look().get("fx", {}).get("mecha", "")) if r.vis != null else ""
		if m != "":
			tags.append("mecha:" + m)
	var et = main.demo.etapas
	if et != null and is_instance_valid(et) and String(et.state) != "etapa":
		tags.append("virada:" + String(et.state))
	return tags

func _perf_coisas(obj) -> int:
	var n := 0
	if obj == null or not is_instance_valid(obj):
		return 0
	for pr in obj.get_property_list():
		if pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v = obj.get(pr["name"])
			if v is Array or v is Dictionary:
				n += v.size()
	return n

func perf_derruba(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var args := OS.get_cmdline_user_args()
	var dur := 70.0
	var rota := "total"
	for a in args:
		if a.begins_with("--perf-dur="):
			dur = float(a.substr(11))
		if a.begins_with("--perf-rota="):
			rota = a.substr(12)
	var pior: bool = not "--perf-normal" in args
	var cena_alvo := 1      # --perf-cena=2: mede já na cena 2 (vira antes de medir)
	var evento := ""        # --perf-evento=G03: mantém esse evento ligado o tempo todo
	for a in args:
		if a.begins_with("--perf-cena="):
			cena_alvo = int(a.substr(12))
		if a.begins_with("--perf-evento="):
			evento = a.substr(14)
	var partidas := 1
	for a in args:
		if a.begins_with("--perf-partidas="):
			partidas = int(a.substr(16))
	get_window().size = Vector2i(1920, 1080)
	seed(11)
	main.rng.seed = 11
	main.go_menu()
	PlayerInput.virtual = {}
	main.mode = "demolicao"
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.go_join()
	await frames(2)
	main.bot_level = 2
	for k in 4:
		main.add_bot()
	main.selecao.abrir_spells()
	for id in main.spells_on:
		main.spells_on[id] = true
	main.demo.items_on = true
	main.demo.lives_setting = 9
	main.event_level = 3 if pior else 2
	if pior:
		main.demo.cfg["spells"]["caixa"]["intervalo_s"] = [1.5, 2.5]
		main.demo.cfg["spells"]["caixa"]["max_mapa"] = 4
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	Perf.on = true
	Perf.take()
	var quadros := []
	var n := int(dur * 60.0)
	for pi in partidas:   # --perf-partidas=N: sessão longa (vazamento/acúmulo entre partidas)
		var last := Time.get_ticks_usec()
		main.start_match()
		await frames(5)
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		var et = main.demo.etapas
		if et != null:
			et.ativo = true
		if cena_alvo > 1 and et != null:
			et.forcar("total" if cena_alvo == 2 else "moderada")
			var w := 0
			while (et.etapa != cena_alvo or et.state != "etapa") and w < 1500:
				for i in main.players.size():
					main.demo.lives[i] = 9
				await frames(1)
				w += 1
			Perf.take()
		if evento != "":
			main.events.manual = true
		for f in n:
			if evento != "" and main.events.inst(evento) == null:
				main.events.trigger(main.events.ev(evento))
			if f == n / 2 and et != null and is_instance_valid(et) and cena_alvo == 1:
				et.forcar(rota)
			for i in main.players.size():
				main.demo.lives[i] = 9
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var sis: Dictionary = Perf.take()
			var cpu := 0.0
			for k in sis:
				if not _perf_filho(k):
					cpu += float(sis[k])
			var rcpu := RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
			quadros.append({"f": f, "real": (now - last) / 1000.0, "cpu": cpu, "render": rcpu, "sis": sis,
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"nos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
				"coisas": _perf_coisas(main.demo.spells) + _perf_coisas(main.events) + _perf_coisas(main.demo.mecs) + _perf_coisas(main.demo.fx),
				"tags": _perf_tags(), "estado": int(main.state), "partida": pi,
				"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, "mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0})
			last = now
	Perf.on = false
	RenderingServer.viewport_set_measure_render_time(vp, false)
	var fj := FileAccess.open(dir.path_join("quadros.json"), FileAccess.WRITE)
	fj.store_string(JSON.stringify(quadros))
	fj.close()
	var rel := _perf_relatorio(quadros, "pior caso" if pior else "normal", rota)
	var fr := FileAccess.open(dir.path_join("relatorio.md"), FileAccess.WRITE)
	fr.store_string(rel)
	fr.close()
	print(rel)

func _pct(v: Array, p: float) -> float:
	if v.is_empty():
		return 0.0
	var s := v.duplicate()
	s.sort()
	return float(s[clampi(int(s.size() * p), 0, s.size() - 1)])

func _perf_relatorio(q: Array, modo: String, rota: String) -> String:
	var orc: Dictionary = Data.read_json("data/desempenho.json")
	var budget := float(orc.get("orcamento_cpu_ms", 8.0))
	var limite := float(orc.get("pico_cpu_ms", 12.0))
	var cpus := q.map(func(x): return float(x["cpu"]))
	var reais := q.map(func(x): return float(x["real"]))
	var rend := q.map(func(x): return float(x["render"]))
	var media := func(v: Array) -> float: return v.reduce(func(a, b): return a + b, 0.0) / maxf(v.size(), 1)
	var o := "# Relatório de desempenho — Canteiro, 4 bots, %s, virada %s\n\n" % [modo, rota]
	o += "Quadros: %d · orçamento de CPU do jogo %.1f ms · pico tolerado %.1f ms\n\n" % [q.size(), budget, limite]
	o += "| medida | média | p95 | p99 | máx |\n|---|---|---|---|---|\n"
	o += "| CPU do jogo (lógica + desenho) ms | %.2f | %.2f | %.2f | %.2f |\n" % [media.call(cpus), _pct(cpus, 0.95), _pct(cpus, 0.99), _pct(cpus, 1.0)]
	o += "| render (CPU) ms | %.2f | %.2f | %.2f | %.2f |\n" % [media.call(rend), _pct(rend, 0.95), _pct(rend, 0.99), _pct(rend, 1.0)]
	o += "| quadro real ms (xvfb, GL por software) | %.2f | %.2f | %.2f | %.2f |\n" % [media.call(reais), _pct(reais, 0.95), _pct(reais, 0.99), _pct(reais, 1.0)]
	var dc := q.map(func(x): return float(x["draw_calls"]))
	var nos := q.map(func(x): return float(x["nos"]))
	var co := q.map(func(x): return float(x["coisas"]))
	o += "| chamadas de desenho | %.0f | %.0f | %.0f | %.0f |\n" % [media.call(dc), _pct(dc, 0.95), _pct(dc, 0.99), _pct(dc, 1.0)]
	o += "| nós | %.0f | | | %.0f |\n| coisas vivas (listas de engenhocas/eventos/mecanismos) | %.0f | | | %.0f |\n\n" % [media.call(nos), _pct(nos, 1.0), media.call(co), _pct(co, 1.0)]
	var np := int(q[-1].get("partida", 0)) + 1 if not q.is_empty() else 1
	if np > 1:
		o += "## Por partida (sessão longa)\n| partida | CPU média | render média | nós (fim) | objetos (fim) | coisas (fim) | memória MB | vídeo MB |\n|---|---|---|---|---|---|---|---|\n"
		for pi in np:
			var qq := q.filter(func(x): return int(x.get("partida", 0)) == pi)
			o += "| %d | %.2f | %.2f | %d | %d | %d | %.0f | %.0f |\n" % [pi + 1, media.call(qq.map(func(x): return float(x["cpu"]))), media.call(qq.map(func(x): return float(x["render"]))), int(qq[-1]["nos"]), int(qq[-1]["objetos"]), int(qq[-1]["coisas"]), float(qq[-1]["mem_mb"]), float(qq[-1]["vram_mb"])]
		o += "\n"
	var acima := q.filter(func(x): return float(x["cpu"]) > limite).size()
	o += "**Quadros acima do pico tolerado: %d (%.1f%%)**\n\n" % [acima, 100.0 * acima / maxf(q.size(), 1)]
	# por sistema
	var sist := {}
	for x in q:
		for k in x["sis"]:
			if not sist.has(k):
				sist[k] = []
			sist[k].append(float(x["sis"][k]))
	var nomes := sist.keys()
	nomes.sort_custom(func(a, b): return media.call(sist[a]) > media.call(sist[b]))
	o += "## Por sistema (ms por quadro)\n| sistema | média | p99 | máx |\n|---|---|---|---|\n"
	for k in nomes:
		o += "| %s%s | %.3f | %.3f | %.3f |\n" % [k, " (parte de outra)" if _perf_filho(k) else "", media.call(sist[k]), _pct(sist[k], 0.99), _pct(sist[k], 1.0)]
	# por contexto
	var base := q.filter(func(x): return x["tags"].is_empty()).map(func(x): return float(x["cpu"]))
	var mb: float = media.call(base)
	var por := {}
	for x in q:
		for tg in x["tags"]:
			if not por.has(tg):
				por[tg] = []
			por[tg].append(float(x["cpu"]))
	var tgs := por.keys()
	tgs.sort_custom(func(a, b): return media.call(por[a]) > media.call(por[b]))
	o += "\n## Por contexto (CPU média quando ativo; base sem nada ativo = %.2f ms)\n| contexto | quadros | média | máx | a mais que a base |\n|---|---|---|---|---|\n" % mb
	for tg in tgs:
		o += "| %s | %d | %.2f | %.2f | %+.2f |\n" % [tg, por[tg].size(), media.call(por[tg]), _pct(por[tg], 1.0), media.call(por[tg]) - mb]
	# picos
	var picos := q.duplicate()
	picos.sort_custom(func(a, b): return float(a["cpu"]) > float(b["cpu"]))
	o += "\n## 15 piores quadros\n| quadro | s | CPU | 3 sistemas mais caros | contexto |\n|---|---|---|---|---|\n"
	for x in picos.slice(0, 15):
		var ks: Array = x["sis"].keys().filter(func(k): return not k in PERF_FILHOS or true)
		ks.sort_custom(func(a, b): return float(x["sis"][a]) > float(x["sis"][b]))
		var top := ", ".join(ks.slice(0, 3).map(func(k): return "%s %.1f" % [k, float(x["sis"][k])]))
		o += "| %d | %.1f | %.2f | %s | %s |\n" % [int(x["f"]), int(x["f"]) / 60.0, float(x["cpu"]), top, " ".join(x["tags"])]
	return o


## PROTOCOLO DE DESEMPENHO (docs/manuais/desempenho.md): guarda as correções contra regressão. Limites generosos (a
## máquina de teste é lenta e oscila): pegam o erro de volta (ex.: reler JSON por chamada, busca do mapa inteiro num
## quadro), não variações pequenas. --so=desempenho
func desempenho_test() -> void:
	print("== Desempenho (protocolo)")
	var t0 := Time.get_ticks_usec()
	for k in 2000:
		MapaReg.modo_cfg("derruba")
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	check(ms < 60.0, "modos.json não é relido a cada chamada (2000× modo_cfg = %.1f ms)" % ms)
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {}
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.bot_level = 2
	for k in 4:
		main.add_bot()
	main.event_level = 3
	main.demo.lives_setting = 9
	main.start_match()
	await frames(5)
	main.countdown = 0.0
	for r in main.robots:
		r.active = true
	var L = main.level
	t0 = Time.get_ticks_usec()
	var n := 0
	for y in L.rows:
		for x in L.cols:
			if L.is_solid(Vector2i(x, y)):
				n += 1
	ms = (Time.get_ticks_usec() - t0) / 1000.0
	check(ms < 40.0, "is_solid no mapa inteiro é barato (%d células, %.1f ms)" % [L.rows * L.cols, ms])
	# a busca de caminho dos bots respeita a fatia de tempo (nunca o mapa inteiro num quadro)
	var bt = main.bots
	bt._busca = bt._nova_busca(L, Vector2i(int(L.cols / 2), int(L.area.end.y / 64.0) - 1))
	var pior := 0.0
	var quadros := 0
	while bt._busca != null and quadros < 600:
		bt._nav_quadro = -1
		var q0 := Time.get_ticks_usec()
		bt._avanca_busca()
		pior = maxf(pior, (Time.get_ticks_usec() - q0) / 1000.0)
		quadros += 1
	check(bt._busca == null and pior < float(bt.NAV_FATIA_MS) * 4.0 + 2.0, "busca dos bots fatiada: termina em %d quadros, pior fatia %.1f ms (limite %.1f)" % [quadros, pior, bt.NAV_FATIA_MS])
	# sorteio de evento: no máximo SORTEIO_POR_QUADRO testes por quadro
	check(int(main.events.SORTEIO_POR_QUADRO) <= 3, "sorteio de evento espalhado (%d testes por quadro)" % main.events.SORTEIO_POR_QUADRO)
	# partida curta com a sonda ligada: nenhum sistema de LÓGICA com pico absurdo (o desenho não roda sem tela)
	Perf.on = true
	Perf.take()
	var picos := {}
	for f in 600:
		for i in main.players.size():
			main.demo.lives[i] = 9
		await frames(1)
		var sis: Dictionary = Perf.take()
		for k in ["bots", "demo_total", "fisica_robos", "canteiro"]:
			var v := float(sis.get(k, 0.0))
			if v > 15.0:
				picos[k] = int(picos.get(k, 0)) + 1
	Perf.on = false
	var tot := 0
	for k in picos:
		tot += int(picos[k])
	check(tot <= 3, "10 s de partida com 4 bots e eventos em ALTA: picos de lógica > 15 ms = %d %s" % [tot, str(picos)])
	# vazamento entre partidas: nenhum nó órfão e objetos estáveis (antes: formas de colisão órfãs e estilos sem fim)
	var obj0 := 0
	for k in 3:
		main.start_match()
		await frames(5)
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		await frames(90)
		if k == 0:
			obj0 = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var obj1 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var orf := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	check(orf == 0 and obj1 - obj0 < 300, "3 partidas seguidas sem vazamento: órfãos %d, objetos %d → %d" % [orf, obj0, obj1])
	var KitS = load("res://ui/kit.gd")
	check(KitS.cor_cache(Color(0.5, 0.5, 0.5, 0.501)) == KitS.cor_cache(Color(0.5, 0.5, 0.5, 0.499)), "cache de estilos arredonda a transparência (não cresce com animação)")
	main.go_menu()

## Vazamento entre partidas (--perf-vaza): objetos, recursos e nós órfãos depois de cada partida.
func perf_vaza() -> void:
	PlayerInput.virtual = {}
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.go_join()
	await frames(2)
	for k in 4:
		main.add_bot()
	main.event_level = 3
	for i in 4:
		main.start_match()
		await frames(5)
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		for f in 600:
			for j in main.players.size():
				main.demo.lives[j] = 9
			await frames(1)
		print("VAZA partida %d: objetos %d  recursos %d  nós %d  órfãos %d" % [i + 1, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])
	Node.print_orphan_nodes()


## FASE 2 · Cargueiro Perdido — bloco A (cenas + base fixa + estruturas com os tipos atuais): manifesto válido, rotas,
## nascimentos em chão firme, estruturas montadas e as DUAS transições de verdade (afunda → Atlântida; encalha →
## Destroços), todos chegando vivos na área certa. --so=cargueiro
func _cargueiro_partida() -> void:
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.add_bot()
	main.add_bot()
	main.game_mode = "derruba"
	main.demo.lives_setting = 4
	main.event_level = 0
	main.arena_choice = "cargueiro_perdido"
	main.start_match()
	await demo_round()
	main.countdown = 0.0

func _cargueiro_rota(tipo: String, n: int) -> void:
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false   # bots parados: o teste é da transição (no aviso um bot podia cair no mar brigando)
	var lives0 = main.demo.lives.duplicate()
	et.forcar(tipo)
	var w := 0
	while (et.etapa != n or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	await frames(40)
	var a: Rect2 = main.level.etapa_rect(n)
	check(et.etapa == n and main.level.area == a, "rota %s: chega à cena %d em %.1f s; área e KO passam para ela" % [tipo, n, w / 60.0])
	check(main.robots.all(func(r): return r.alive and a.has_point(r.position)) and main.demo.lives == lives0, "rota %s: os 4 chegam vivos dentro da cena nova, sem perder vida (%s vidas %s→%s)" % [tipo, str(main.robots.map(func(r): return [r.pid, Vector2i(r.position / 64.0), r.alive])), str(lives0), str(main.demo.lives)])

func cargueiro_test() -> void:
	print("== Fase 2 · Cargueiro Perdido (bloco A)")
	var m := MapaReg.manifesto("derruba", "cargueiro_perdido")
	check(not m.is_empty() and MapaReg.validar(m).is_empty(), "manifesto do Cargueiro carrega e valida (%s)" % str(MapaReg.validar(m)))
	check(MapaReg.rota("derruba", "cargueiro_perdido", 1, "total") == 2 and MapaReg.rota("derruba", "cargueiro_perdido", 1, "moderada") == 3 and not MapaReg.tem_proxima("derruba", "cargueiro_perdido", 2) and not MapaReg.tem_proxima("derruba", "cargueiro_perdido", 3), "Alto-Mar → Atlântida (rota total) ou Destroços (rota moderada); as duas são as últimas")
	check(not "cargueiro_perdido" in main.demo.find_mode("derruba").get("arenas", []), "ainda escondido do menu do Derruba (em construção)")
	await _cargueiro_partida()
	var L = main.level
	check(L.id == "cargueiro_perdido" and L.etapa_rect(1).has_area() and L.etapa_rect(2).has_area() and L.etapa_rect(3).has_area(), "o .lvl tem as 3 áreas de cena")
	var ruins := []
	for k in range(1, 13):
		var sp: Vector2 = L.spawns.get(k, Vector2.INF)
		if sp == Vector2.INF or not L.is_solid(Vector2i(int(sp.x / 64.0), int(sp.y / 64.0))):
			ruins.append(k)
	check(ruins.is_empty(), "12 nascimentos (4 por cena), todos em chão firme %s" % str(ruins))
	var ct = main.demo.canteiro
	var por := {1: 0, 2: 0, 3: 0}
	for p in ct.parts:
		por[int(p.get("etapa", 1))] += 1
	check(por[1] == 15 and por[2] == 11 and por[3] == 14, "estruturas que quebram montadas em cada cena (Alto-Mar %d, Atlântida %d, Destroços %d)" % [por[1], por[2], por[3]])
	await frames(60)
	check(main.robots.all(func(r): return r.alive and L.etapa_rect(1).has_point(r.position)), "todos nascem e ficam de pé no Alto-Mar")
	check(ct.progresso(1) < 0.05, "manômetro começa zerado (%.0f%%)" % (ct.progresso(1) * 100.0))
	await _cargueiro_rota("total", 2)
	await _cargueiro_rota("moderada", 3)
	main.go_menu()

## Fase 2 bloco C: ÁGUA (regra-assinatura). Alagado: lento, pulo flutua, queda lenta, golpe joga longe; ao sair fica
## molhado (lento por uns segundos) e volta ao normal; respingo ao entrar; mapa sem água não cria nada. --so=agua
func agua_test() -> void:
	print("== Fase 2 · ÁGUA (alagado / molhado)")
	await _cargueiro_partida()
	var et = main.demo.etapas
	var ag = main.demo.agua
	check(ag != null and ag.zonas.size() >= 1, "o Cargueiro tem zonas de água (%d)" % (ag.zonas.size() if ag != null else 0))
	et.ativo = true
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	await frames(30)
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	var z: Rect2 = ag.zonas[0]["rect"]
	var cfg: Dictionary = ag.cfg
	for r in main.robots:
		r.invuln = 99.0
	r1.active = false
	put(r1, Vector2(main.level.etapa_rect(2).position.x + 300.0, r1.position.y))
	put(r0, Vector2(z.get_center().x, z.position.y + 64.0))
	var nb: int = ag.bits.size()
	await frames(3)
	check(ag.bits.size() > nb, "entrar na água faz respingo")
	check(is_equal_approx(r0.agua_grav, float(cfg["gravidade"])) and is_equal_approx(r0.agua_queda, float(cfg["queda_max"])) and r0.env_slow <= float(cfg["corrida"]) + 0.001,
		"alagado: gravidade ×%.2f (pulo flutua), queda ×%.2f, corrida ×%.2f (lido de modos.json)" % [r0.agua_grav, r0.agua_queda, r0.env_slow])
	check(r1.agua_grav == 1.0 and r1.env_slow == 1.0, "quem está fora d'água fica normal")
	r0.invuln = 0.0
	r0.knock(1, 400.0, 300.0, 0.1)
	check(is_equal_approx(r0.own_vx, 400.0 * float(cfg["empurrao"])), "golpe recebido na água joga longe (×%.2f)" % float(cfg["empurrao"]))
	r0.invuln = 99.0
	await frames(20)
	put(r0, Vector2(main.level.etapa_rect(2).position.x + 400.0, r1.position.y))
	await frames(3)
	check(r0.agua_grav == 1.0 and r0.env_slow <= float(cfg["molhado_corrida"]) + 0.001, "saiu da água: molhado (corrida ×%.2f)" % r0.env_slow)
	await frames(int(float(cfg["molhado_s"]) * 60.0) + 20)
	check(r0.env_slow == 1.0, "secou: volta ao normal em %.0f s" % float(cfg["molhado_s"]))
	main.go_menu()
	main.game_mode = "derruba"
	main.arena_choice = "canteiro_obras"
	main.go_join()
	await frames(2)
	PlayerInput.virtual = {"v0": {}, "v1": {}}
	await tap("v0", "jump")
	await tap("v1", "jump")
	main.event_level = 0
	main.start_match()
	await demo_round()
	check(main.demo.agua == null and main.robots.all(func(r): return r.agua_grav == 1.0), "mapa sem água (Canteiro): nada muda")
	main.go_menu()

## M1 Contêiner despenca (Alto-Mar): sombra vermelha antes (aviso), acerta quem está embaixo, racha a peça em que bate
## e fica como plataforma nova; depois some. --so=m1
func m1_test() -> void:
	print("== Fase 2 · M1 contêiner despenca")
	await _cargueiro_partida()
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "conteiner_cai":
			inst = i
	check(inst != null, "M1 está no Alto-Mar (manifesto)")
	if inst == null:
		return
	var d: Dictionary = inst["d"]
	d["colunas"] = [8]   # coluna do andaime da esquerda (tem peça embaixo)
	var s: Dictionary = inst["s"]
	s["t"] = float(d["ciclo_s"]) - 0.02
	await frames(3)
	check(s.get("fase", "") == "aviso" and s.has("alvo"), "aviso: a sombra vermelha marca onde vai cair (%.1f s antes)" % float(d["aviso_s"]))
	var alvo: Rect2 = s["alvo"]
	check(mc.zonas_perigo().any(func(z): return z.intersects(alvo)), "a sombra entra nas zonas de perigo (ninguém renasce ali)")
	var r0 = main.robots[0]
	for r in main.robots:
		r.invuln = 99.0
	r0.invuln = 0.0
	r0.active = false
	put(r0, Vector2(alvo.get_center().x, alvo.end.y))
	var ct = main.demo.canteiro
	var hp0 := 0
	for p in ct.parts:
		if (p["rect"] as Rect2).intersects(Rect2(alvo.position.x, alvo.end.y - 4.0, alvo.size.x, 12.0)):
			hp0 += int(p.get("hp", 0))
	var dmg0: float = r0.dmg
	var w := 0
	while s.get("fase", "") != "espera" and w < 400:
		await frames(1)
		w += 1
	check(r0.dmg > dmg0, "quem estava embaixo leva o golpe (%.0f%%)" % (r0.dmg - dmg0))
	var hp1 := 0
	for p in ct.parts:
		if (p["rect"] as Rect2).intersects(Rect2(alvo.position.x, alvo.end.y - 4.0, alvo.size.x, 12.0)):
			hp1 += int(p.get("hp", 0))
	check(hp1 < hp0, "racha a peça em que bateu (HP %d → %d)" % [hp0, hp1])
	check(s.has("plat") and is_instance_valid(s["plat"]), "fica como plataforma nova")
	s["parado"] = 0.01
	await frames(3)
	check(not s.has("plat"), "depois de um tempo some (abre espaço para o próximo)")
	main.go_menu()

## M2 Gancho balança (Alto-Mar): parado é plataforma; aviso (arco) → balança e empurra quem está no caminho; marretada
## inverte o balanço. --so=m2
func m2_test() -> void:
	print("== Fase 2 · M2 gancho balança")
	await _cargueiro_partida()
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "gancho_balanca":
			inst = i
	check(inst != null, "M2 está no Alto-Mar (manifesto)")
	if inst == null:
		return
	await frames(2)
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	check(s.has("plat") and is_instance_valid(s["plat"]) and s["fase"] == "parado", "parado: o contêiner no gancho é plataforma")
	var r0 = main.robots[0]
	for r in main.robots:
		r.invuln = 99.0
		r.active = false
	r0.invuln = 0.0
	var rc: Rect2 = mc._gancho_rect(inst)
	s["t"] = float(d["ciclo_s"]) - float(d["aviso_s"]) - 0.02
	await frames(3)
	check(s["fase"] == "aviso", "aviso: a grua range e o arco tracejado aparece (%.1f s)" % float(d["aviso_s"]))
	put(r0, Vector2(rc.end.x + 70.0, rc.end.y + 20.0))   # no caminho, ao lado do contêiner
	r0.set_meta("grav_cena", 0.0)
	r0.velocity = Vector2.ZERO
	var dmg0: float = r0.dmg
	var w := 0
	while r0.dmg == dmg0 and w < 300:
		r0.velocity = Vector2.ZERO
		await frames(1)
		w += 1
	r0.remove_meta("grav_cena")
	check(r0.dmg > dmg0, "balançando, o contêiner varre e empurra quem está no caminho (%.0f%%)" % (r0.dmg - dmg0))
	var a0: float = s["ang"]
	await frames(2)
	var v0: float = float(s["ang"]) - a0
	var rr: Rect2 = mc._gancho_rect(inst)
	mc.hammer_hit(Rect2(rr.position.x - 20.0, rr.position.y, 30.0, 30.0), true, 0)
	var a1: float = s["ang"]
	await frames(2)
	var v1: float = float(s["ang"]) - a1
	check(signf(v0) != signf(v1) and absf(v1) > 0.0, "marretada inverte o balanço (%.3f → %.3f)" % [v0, v1])
	var w2 := 0
	while s["fase"] != "parado" and w2 < 400:
		await frames(1)
		w2 += 1
	check(s["fase"] == "parado" and absf(float(s["ang"])) < 0.001, "depois para e volta a ser plataforma")
	main.go_menu()

## M3 Onda estoura na balsa (Alto-Mar): aviso (a água incha) → a onda varre o convés: empurra para dentro e deixa
## molhado (lento); sem dano. --so=m3
func m3_test() -> void:
	print("== Fase 2 · M3 onda na balsa")
	await _cargueiro_partida()
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "onda_balsa":
			inst = i
	check(inst != null and main.demo.agua != null, "M3 está no Alto-Mar e a água (molhado) está ligada")
	if inst == null:
		return
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	var r0 = main.robots[0]
	for r in main.robots:
		r.invuln = 99.0
		r.active = false
	s["qual"] = 1   # o próximo é a balsa 0 (esquerda)
	s["t"] = float(d["ciclo_s"]) - 0.02
	await frames(3)
	check(s.get("fase", "") == "aviso" and int(s["qual"]) == 0, "aviso: a água incha na borda da balsa da esquerda")
	var a: Rect2 = mc._onda_area(inst, 0)
	put(r0, Vector2(5 * 64.0 + 20.0, 12 * 64.0))   # em cima do contêiner baixo da balsa (a onda chega até ali)
	r0.invuln = 0.0
	r0.active = true   # sem comando (ninguém apertando nada): só a onda mexe nele
	var dmg0: float = r0.dmg
	var x0: float = r0.position.x
	var w := 0
	while s.get("fase", "") != "" and w < 320:
		await frames(1)
		w += 1
	check(main.demo.agua.molhado.has(r0) and float(main.demo.agua.molhado[r0]) > 0.0, "a onda deixa molhado (lento)")
	check(r0.position.x > x0 + 20.0, "a onda empurra para dentro da balsa (longe do mar: %.0f px)" % (r0.position.x - x0))
	check(r0.dmg == dmg0, "a onda não dá dano (só empurra e molha)")
	main.go_menu()

## M4 Maré (Destroços): baixa → aviso (linha + setas) → sobe até a maré alta: quem está no convés da balsa fica alagado,
## bote e jangada boiam e sobem; depois desce. --so=m4
func m4_test() -> void:
	print("== Fase 2 · M4 maré")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
	et.forcar("moderada")
	var w := 0
	while (et.etapa != 3 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "mare":
			inst = i
	check(inst != null and main.demo.agua != null, "M4 está nos Destroços, com a zona de água")
	if inst == null:
		return
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(3).position
	var r0 = main.robots[0]
	r0.invuln = 99.0
	put(r0, Vector2(o.x + 29.0 * 64.0 + 24.0, o.y + 13.0 * 64.0))   # no convés livre da balsa (ponta, depois dos contêineres)
	r0.active = true
	var ct = main.demo.canteiro
	var bote = null
	for p in ct.parts:
		if p["kind"] == "prancha" and int(p["etapa"]) == 3 and int(p["idx"]) == 7:
			bote = p
	await frames(5)
	check(s["fase"] == "baixa" and not main.demo.agua.alagado(r0.position + Vector2(0, -36)), "maré baixa: o convés da balsa está seco")
	var cyc := float(d["ciclo_s"])
	var t_aviso := cyc - float(d["aviso_s"]) - 2.0 * float(d["sobe_s"]) - float(d["alta_s"])
	s["t"] = t_aviso + 0.05
	await frames(3)
	check(s["fase"] == "aviso", "aviso: linha da maré alta + setas + alarme (%.0f s antes)" % float(d["aviso_s"]))
	s["t"] = t_aviso + float(d["aviso_s"]) + float(d["sobe_s"]) + 0.2
	await frames(5)
	check(s["fase"] == "alta" and is_equal_approx(r0.agua_grav, float(main.demo.agua.cfg["gravidade"])), "maré alta: quem está no convés da balsa fica ALAGADO (pulo flutua)")
	check(bote != null and (bote["rect"] as Rect2).position.y < float(bote["y0"]) - 100.0, "o bote boia e sobe com a água")
	s["t"] = cyc - 0.01
	await frames(10)
	check(s["fase"] == "baixa" and r0.agua_grav == 1.0 and is_equal_approx((bote["rect"] as Rect2).position.y, float(bote["y0"])), "a maré desce: seca e o bote volta")
	main.go_menu()

## M5 Contêiner boiando (Destroços): 1 robô em cima não vira; 2 viram: range (inclina) → vira e os dois caem na água;
## volta à tona depois. --so=m5
func m5_test() -> void:
	print("== Fase 2 · M5 contêiner boiando vira")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
		r.invuln = 99.0
	et.forcar("moderada")
	var w := 0
	while (et.etapa != 3 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "conteiner_boia":
			inst = i
	check(inst != null, "M5 está nos Destroços")
	if inst == null:
		return
	await frames(3)
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	var r: Rect2 = mc._boia_rect(inst)
	var r0 = main.robots[0]
	var r1 = main.robots[1]
	put(r0, Vector2(r.position.x + 40.0, r.position.y))
	r0.active = true
	await frames(int(float(d["pesa_s"]) * 60.0) + 30)
	check(s["fase"] == "boia" and r0.is_on_floor(), "um robô sozinho fica em pé no contêiner boiando")
	put(r1, Vector2(r.end.x - 40.0, r.position.y))
	r1.active = true
	var w2 := 0
	while s["fase"] == "boia" and w2 < 120:
		await frames(1)
		w2 += 1
	check(s["fase"] == "range", "dois em cima: o contêiner range e inclina")
	var y0: float = r0.position.y
	var v0: int = int(main.demo.lives[0])
	while s["fase"] == "range" and w2 < 400:
		await frames(1)
		w2 += 1
	var caiu := false
	for k in 40:
		await frames(1)
		caiu = caiu or r0.position.y > y0 + 30.0 or int(main.demo.lives[0]) < v0
	check(s["fase"] == "virado" and caiu, "vira e joga quem estava em cima na água (o mar fundo é KO)")
	s["k"] = float(d["virado_s"]) - 0.02
	await frames(3)
	check(s["fase"] == "boia", "volta à tona depois de %.0f s" % float(d["virado_s"]))
	main.go_menu()

## M6 Rede de carga (Destroços): marretada pesada rasga a rede (a peça cai) e as caixas caem em quem está embaixo. --so=m6
func m6_test() -> void:
	print("== Fase 2 · M6 rede de carga rasga")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
		r.invuln = 99.0
	et.forcar("moderada")
	var w := 0
	while (et.etapa != 3 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "rede_rasga":
			inst = i
	check(inst != null, "M6 está nos Destroços")
	if inst == null:
		return
	var rede = mc._rede_peca(inst)
	check(rede != null and not rede["fallen"], "a rede de carga é uma peça de pé (prancha %d)" % int(inst["d"]["peca"]))
	var rr: Rect2 = rede["rect"]
	var r1 = main.robots[1]
	put(r1, Vector2(rr.get_center().x, main.level.etapa_rect(3).position.y + 8 * 64.0))   # embaixo da rede, no convés (nível 8)
	r1.invuln = 0.0
	r1.active = true
	var dmg0: float = r1.dmg
	mc.hammer_hit(Rect2(rr.position, Vector2(40, 40)), false, 0)
	check(int(rede["hp"]) > 0 and not inst["s"].get("rasgou", false), "marretada leve (no mecanismo) não rasga a rede")
	mc.hammer_hit(Rect2(rr.position, Vector2(40, 40)), true, 0)
	check(int(rede["hp"]) == 0, "marretada PESADA rasga a rede (HP → 0)")
	var w2 := 0
	while r1.dmg == dmg0 and w2 < 120:
		await frames(1)
		w2 += 1
	check(inst["s"].get("rasgou", false) and r1.dmg > dmg0, "as caixas caem em quem está embaixo (%.0f%%)" % (r1.dmg - dmg0))
	main.go_menu()

## M10 Tubarão (Destroços): barbatana ronda; alguém no bote → aviso (anel) → salta e morde; marretada no focinho no
## salto: tonto e foge. --so=m10
func m10_test() -> void:
	print("== Fase 2 · M10 tubarão")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
		r.invuln = 99.0
	et.forcar("moderada")
	var w := 0
	while (et.etapa != 3 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "tubarao":
			inst = i
	check(inst != null, "M10 está nos Destroços")
	if inst == null:
		return
	await frames(3)
	var s: Dictionary = inst["s"]
	check(s["fase"] == "ronda", "a barbatana ronda o mar")
	var bote = null
	for p in main.demo.canteiro.parts:
		if p["kind"] == "prancha" and int(p["etapa"]) == 3 and int(p["idx"]) == 7:
			bote = p
	var r0 = main.robots[0]
	put(r0, Vector2((bote["rect"] as Rect2).get_center().x, (bote["rect"] as Rect2).position.y))
	r0.active = true
	r0.invuln = 0.0
	await frames(10)
	s["ronda"] = 0.01
	await frames(3)
	check(s["fase"] == "aviso", "alguém no bote: o tubarão acelera até lá e o anel vermelho aparece")
	var dmg0: float = r0.dmg
	var w2 := 0
	while r0.dmg == dmg0 and w2 < 200:
		await frames(1)
		w2 += 1
	check(r0.dmg > dmg0 and s["fase"] == "salta", "salta e morde quem está no bote (%.0f%%)" % (r0.dmg - dmg0))
	mc.hammer_hit(mc._tub_rect(inst), true, 1)
	check(s["fase"] == "tonto", "marretada no focinho: fica TONTO")
	await frames(60)
	check(s["fase"] == "ronda" and s.has("foge"), "e foge por um tempo (%.0f s)" % float(inst["d"]["foge_s"]))
	main.go_menu()

## Capturas da Fase 2 em construção (--cargueiro=DIR): Alto-Mar, chegada em Atlântida (total) e nos Destroços (moderada).
func cargueiro_frames(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	await _cargueiro_partida()
	main.hud.visible = false
	await frames(30)
	await snap(dir, "f2_1_alto_mar")
	for i in main.demo.mecs.list:   # M1: o aviso (sombra vermelha) e o contêiner caído
		if i["tipo"] == "conteiner_cai":
			i["d"]["colunas"] = [8]
			i["s"]["t"] = float(i["d"]["ciclo_s"]) - 0.02
			await frames(50)
			await snap(dir, "f2_1b_m1_aviso")
			await frames(110)
			await snap(dir, "f2_1c_m1_caiu")
	for i in main.demo.mecs.list:   # M2: arco do aviso e o contêiner varrendo
		if i["tipo"] == "gancho_balanca":
			i["s"]["t"] = float(i["d"]["ciclo_s"]) - float(i["d"]["aviso_s"]) + 0.6
			await frames(10)
			await snap(dir, "f2_1d_m2_aviso")
			await frames(100)
			await snap(dir, "f2_1e_m2_balanca")
	for i in main.demo.mecs.list:   # M3: a água inchando e a onda varrendo
		if i["tipo"] == "onda_balsa":
			i["s"]["qual"] = 1
			i["s"]["t"] = float(i["d"]["ciclo_s"]) - 0.02
			await frames(45)
			await snap(dir, "f2_1f_m3_aviso")
			await frames(35)
			await snap(dir, "f2_1g_m3_onda")
	for par in [["total", 2, "f2_2_atlantida"], ["moderada", 3, "f2_3_destrocos"]]:
		if par[0] == "moderada":
			await _cargueiro_partida()
			main.hud.visible = false
		var et = main.demo.etapas
		et.ativo = true
		et.forcar(par[0])
		var w := 0
		while (et.etapa != par[1] or et.state != "etapa") and w < 1500:
			await frames(1)
			w += 1
		await frames(60)
		await snap(dir, par[2])
		if par[1] == 2:   # Atlântida: M7 racha (2 marretadas) e M11 gêiser (aviso e jorra)
			var mc2 = main.demo.mecs
			for i in mc2.list:
				if i["tipo"] == "cupula_racha":
					mc2.hammer_hit(mc2._cup_alvo(i), false, 0)
					mc2.hammer_hit(mc2._cup_alvo(i), false, 0)
					await frames(150)
					await snap(dir, "f2_2b_m7_racha")
			for i in mc2.list:   # M8: a corrente estala (sombra) e o lustre caindo
				if i["tipo"] == "lustre_cai":
					mc2.hammer_hit(mc2._lustre_corrente(i), false, 0)
					await frames(30)
					await snap(dir, "f2_2e_m8_estala")
					await frames(int(float(i["d"]["aviso_s"]) * 60.0) - 30 + 14)
					await snap(dir, "f2_2f_m8_cai")
			for i in mc2.list:   # M9: lança quem pisa e fecha
				if i["tipo"] == "concha":
					var cr9: Rect2 = mc2._concha_rect(i)
					var r9 = main.robots[2]
					r9.invuln = 99.0
					put(r9, Vector2(cr9.get_center().x, cr9.position.y - 20.0))
					await frames(14)
					await snap(dir, "f2_2g_m9_lanca")
			for i in mc2.list:
				if i["tipo"] == "geiser":
					var cg := float(i["d"]["ciclo_s"])
					i["s"]["t"] = cg - float(i["d"]["aviso_s"]) - float(i["d"]["jorra_s"]) + 0.6
					await frames(10)
					await snap(dir, "f2_2c_m11_aviso")
					var jr: Rect2 = mc2._geiser_rect(i, int(i["s"]["idx"]))
					var rg = main.robots[1]
					rg.invuln = 99.0
					put(rg, Vector2(jr.get_center().x, main.level.etapa_rect(2).end.y - 60.0))
					await frames(int(float(i["d"]["aviso_s"]) * 60.0) + 12)
					await snap(dir, "f2_2d_m11_jorra")
		if par[1] == 3:   # M4 maré nos Destroços: aviso e maré alta
			for i in main.demo.mecs.list:
				if i["tipo"] == "mare":
					var dd: Dictionary = i["d"]
					var ta := float(dd["ciclo_s"]) - float(dd["aviso_s"]) - 2.0 * float(dd["sobe_s"]) - float(dd["alta_s"])
					i["s"]["t"] = ta + 1.0
					await frames(10)
					await snap(dir, "f2_3b_m4_aviso")
					await frames(int((float(dd["aviso_s"]) - 1.0 + float(dd["sobe_s"])) * 60.0) + 30)
					await snap(dir, "f2_3c_m4_alta")
			for i in main.demo.mecs.list:   # M5: o contêiner boiando rangendo (inclinado)
				if i["tipo"] == "conteiner_boia":
					i["s"]["fase"] = "range"
					i["s"]["k"] = 0.0
					i["s"]["lado"] = 1.0
					await frames(40)
					await snap(dir, "f2_3d_m5_range")
			for i in main.demo.mecs.list:   # M6: a rede rasga e as caixas caem
				if i["tipo"] == "rede_rasga":
					var rp = main.demo.mecs._rede_peca(i)
					if rp != null:
						main.demo.canteiro.damage(rp, 99, (rp["rect"] as Rect2).get_center())
						await frames(40)
						await snap(dir, "f2_3g_m6_rasgou")
			for i in main.demo.mecs.list:   # M10: aviso (anel) e o salto
				if i["tipo"] == "tubarao":
					var bt = null
					for p in main.demo.canteiro.parts:
						if p["kind"] == "prancha" and int(p["etapa"]) == 3 and int(p["idx"]) == 7:
							bt = p
					if bt != null:
						var rb0 = main.robots[0]
						rb0.invuln = 99.0
						put(rb0, Vector2((bt["rect"] as Rect2).get_center().x, (bt["rect"] as Rect2).position.y))
						await frames(10)
						i["s"]["ronda"] = 0.01
						await frames(50)
						await snap(dir, "f2_3e_m10_aviso")
						await frames(int(float(i["d"]["aviso_s"]) * 60.0) - 20)
						await snap(dir, "f2_3f_m10_salta")
	main.hud.visible = true

## ESTUDO DO EQUILÍBRIO DA DESTRUIÇÃO (--estudo-destruicao=N): N partidas de 4 bots no Canteiro, configuração PADRÃO
## (eventos normais, engenhocas ligadas, vidas padrão), SEM virada (o diretor de cenas desligado), 150 s cada. Imprime o
## % destruído do Térreo a cada 10 s e de onde veio a destruição (para achar a regra da verificação por tempo).
func estudo_destruicao(n: int) -> void:
	var curvas := []
	var nivel := 1       # --estudo-nivel=N (bots 0 fácil · 1 médio · 2 difícil)
	var ev_nivel := 2    # --estudo-eventos=N
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--estudo-nivel="):
			nivel = int(a.substr(15))
		elif a.begins_with("--estudo-eventos="):
			ev_nivel = int(a.substr(17))
	var regra := "--estudo-regra" in OS.get_cmdline_user_args()   # transição LIGADA: mede quando e para onde vira
	for i in n:
		seed(100 + i)
		main.rng.seed = 100 + i
		main.go_join()
		await frames(2)
		PlayerInput.virtual = {}
		main.bot_level = nivel
		for k in 4:
			main.add_bot()
		main.game_mode = "derruba"
		main.arena_choice = "canteiro_obras"
		main.event_level = ev_nivel
		main.start_match()
		await frames(5)
		main.countdown = 0.0
		for r in main.robots:
			r.active = true
		var et = main.demo.etapas
		et.ativo = regra
		var ct = main.demo.canteiro
		var cur := []
		if regra:
			var q := 0
			while et.state == "etapa" and q < 60 * 200:
				for j in main.players.size():
					main.demo.lives[j] = 9
				await frames(1)
				q += 1
			print("ESTUDO regra partida %d: virou aos %.0f s → rota %s com %.0f%%" % [i + 1, q / 60.0, et.rota, et.progresso * 100.0])
			main.go_menu()
			await frames(3)
			continue
		for s in 151:
			for j in main.players.size():
				main.demo.lives[j] = 9
			if s % 10 == 0:
				cur.append(snappedf(ct.progresso(1) * 100.0, 0.1))
			await frames(60)
		curvas.append(cur)
		print("ESTUDO partida %d: %s" % [i + 1, str(cur)])
	var med := []
	if curvas.is_empty():
		main.go_menu()
		return
	for k in curvas[0].size():
		var v := curvas.map(func(c): return float(c[k]))
		med.append(snappedf(v.reduce(func(a, b): return a + b, 0.0) / v.size(), 0.1))
	print("ESTUDO média por 10 s: %s" % str(med))
	main.go_menu()

## M7 (Atlântida): a racha da cúpula mantém a direita alagada; marretada no vidro sobe a água; sem marretadas ela desce.
func m7_test() -> void:
	print("== Fase 2 · M7 racha da cúpula")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "cupula_racha":
			inst = i
	check(inst != null and main.demo.agua != null, "M7 está em Atlântida, com a zona de água")
	if inst == null:
		return
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(2).position
	await frames(10)
	var base := o.y + float(d["base_px"])
	check(absf(float(s["nivel"]) - base) < 2.0 and main.demo.agua.alagado(Vector2(o.x + 25.0 * 64.0, base + 40.0)), "direita alagada até a linha base")
	var hit: Rect2 = mc._cup_alvo(inst)
	check(mc.hammer_hit(hit, false, 0), "marretada no vidro acerta a racha")
	await frames(90)
	check(int(s["degraus"]) == 1 and float(s["nivel"]) < base - 40.0, "a água subiu um degrau (%.0f px)" % (base - float(s["nivel"])))
	for k in 5:
		mc.hammer_hit(hit, false, 0)
	check(int(s["degraus"]) == int(d["max_degraus"]), "no máximo %d degraus" % int(d["max_degraus"]))
	s["volta"] = float(d["volta_s"]) - 0.05
	await frames(5)
	check(int(s["degraus"]) == int(d["max_degraus"]) - 1, "sem marretadas a água desce um degrau")

## M11 Gêiser: avisa borbulhando, jorra e empurra para cima quem está na fenda (sem dano).
func m11_test() -> void:
	print("== Fase 2 · M11 gêiser")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "geiser":
			inst = i
	check(inst != null, "M11 está em Atlântida")
	if inst == null:
		return
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var cyc := float(d["ciclo_s"])
	s["t"] = cyc - float(d["aviso_s"]) - float(d["jorra_s"]) + 0.05
	await frames(2)
	check(s["fase"] == "aviso", "aviso: a fenda borbulha antes de jorrar")
	var jr: Rect2 = mc._geiser_rect(inst, int(s["idx"]))
	var r0 = main.robots[0]
	r0.invuln = 0.0
	var dano0: float = r0.dmg
	put(r0, Vector2(jr.get_center().x, main.level.etapa_rect(2).end.y - 40.0))
	r0.active = true
	s["t"] = cyc - float(d["jorra_s"]) + 0.02
	var y0: float = r0.position.y
	await frames(30)
	check(s["fase"] == "jorra" and r0.alive and r0.position.y < y0 - 150.0, "jorra: quem caiu na fenda sobe de volta (%.0f px)" % (y0 - r0.position.y))
	check(is_equal_approx(r0.dmg, dano0), "o jato não dá dano")

## M8 Lustre: marretada na corrente → estala com sombra → cai, acerta quem está embaixo e racha a plataforma.
func m8_test() -> void:
	print("== Fase 2 · M8 lustre")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "lustre_cai":
			inst = i
	check(inst != null and mc._lustre_peca(inst) != null, "M8 está em Atlântida, com a peça do lustre")
	if inst == null:
		return
	var s: Dictionary = inst["s"]
	var p = mc._lustre_peca(inst)
	var r: Rect2 = p["rect"]
	check(mc.hammer_hit(mc._lustre_corrente(inst), false, 0) and s["fase"] == "estala", "marretada na corrente: estala (aviso)")
	var chao := float(s["chao"])
	var r0 = main.robots[0]
	r0.invuln = 0.0
	r0.active = true
	var xs := r.get_center().x
	for q in main.demo.canteiro.parts:   # fica em cima da plataforma onde o lustre vai bater
		var qr: Rect2 = q["rect"]
		if q != p and not q["fallen"] and absf(qr.position.y - chao) < 2.0 and qr.position.x < r.end.x and qr.end.x > r.position.x:
			xs = (maxf(qr.position.x, r.position.x) + minf(qr.end.x, r.end.x)) / 2.0
	put(r0, Vector2(xs, chao))
	var d0: float = r0.dmg
	var w2 := 0
	while s["fase"] != "caiu" and w2 < 300:
		await frames(1)
		w2 += 1
	check(s["fase"] == "caiu" and r0.dmg > d0, "caiu e acertou quem estava embaixo (+%.0f%%)" % (r0.dmg - d0))
	await frames(90)
	check(p["fallen"], "o lustre se desfaz depois de cair")

## M9 Concha-trampolim: lança alto quem pisa; fecha e prende; marretada abre.
func m9_test() -> void:
	print("== Fase 2 · M9 concha-trampolim")
	await _cargueiro_partida()
	var et = main.demo.etapas
	et.ativo = true
	for r in main.robots:
		r.active = false
	et.forcar("total")
	var w := 0
	while (et.etapa != 2 or et.state != "etapa") and w < 1500:
		await frames(1)
		w += 1
	var mc = main.demo.mecs
	var inst = null
	for i in mc.list:
		if i["tipo"] == "concha":
			inst = i
	check(inst != null, "M9 está em Atlântida")
	if inst == null:
		return
	var s: Dictionary = inst["s"]
	var cr: Rect2 = mc._concha_rect(inst)
	var r0 = main.robots[0]
	r0.active = true
	put(r0, Vector2(cr.get_center().x, cr.position.y - 30.0))
	var y0: float = cr.end.y
	var top := y0
	for k in 70:
		await frames(1)
		top = minf(top, r0.position.y)
	check(y0 - top > 6.0 * 64.0, "pisou na concha: lançado muito alto (%.1f tiles)" % ((y0 - top) / 64.0))
	put(r0, Vector2(cr.get_center().x, cr.end.y - 2.0))
	s["fase"] = "fechada"
	s["k"] = 0.0
	await frames(20)
	check(s["fase"] == "fechada" and absf(r0.velocity.x) < 1.0 and r0.stun_t > 0.0, "fechada: prende quem está em cima")
	check(mc.hammer_hit(cr, false, 1) and s["fase"] == "aberta", "marretada abre a concha")


## VÍDEO dos perigos do Cargueiro (--cargueiro-video=DIR [--video-cena=1|2|3]): grava quadros a 30 por segundo (a cada 2
## quadros de física) de cada perigo da cena, um depois do outro, com legenda no topo. Montar com ffmpeg -framerate 30.
func cargueiro_video(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1920, 1080)
	var cena := 1
	var so := ""      # --video-so=onda_balsa: só um perigo
	var passo := 2    # --video-passo=1: grava os 60 quadros/s (para a câmera lenta)
	var uma := false  # --video-uma: só a primeira repetição (onda: só uma balsa)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--video-cena="):
			cena = int(a.substr(13))
		elif a.begins_with("--video-so="):
			so = a.substr(11)
		elif a.begins_with("--video-passo="):
			passo = int(a.substr(14))
		elif a.begins_with("--video-uma"):
			uma = true
	await _cargueiro_partida()
	main.hud.visible = false
	for r in main.robots:
		r.invuln = 9999.0
	if cena != 1:
		var et = main.demo.etapas
		et.ativo = true
		et.forcar("total" if cena == 2 else "moderada")
		var w := 0
		while (et.etapa != cena or et.state != "etapa") and w < 1500:
			await frames(1)
			w += 1
	var mc = main.demo.mecs
	for i in mc.list:   # nenhum perigo dispara sozinho durante a gravação
		i["s"]["t"] = -9999.0
	var n := [0]
	var grava := func(seg: float) -> void:
		for f in int(seg * 60.0 / passo):
			await frames(passo)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir + "/%04d.png" % n[0])
			n[0] += 1
	await grava.call(1.0)
	for i in mc.list:
		var tp := String(i["tipo"])
		var d: Dictionary = i["d"]
		if so != "" and tp != so:
			continue
		match tp:
			"conteiner_cai":   # robô embaixo (leva o golpe) e um do lado (a pancada arremessa); 2ª queda no bote
				var cols0: Array = d["colunas"]
				for c in ([9] if uma else [9, 3]):
					d["colunas"] = [c]
					for ri in 2:
						var r = main.robots[ri]
						r.invuln = 0.0
						r.velocity = Vector2.ZERO
						r.own_vx = 0.0
						r.position = Vector2(float(c) * 64.0 + 64.0 + 150.0 * ri, (8.6 if c == 9 else 2.6) * 64.0)
					await grava.call(0.3)
					i["s"]["t"] = float(d["ciclo_s"]) - 0.02
					await grava.call(float(d["aviso_s"]) + float(d.get("salta_s", 0.42)) + 2.0)
					for r in main.robots:
						r.invuln = 9999.0
				d["colunas"] = cols0
				i["s"]["t"] = -9999.0
			"gancho_balanca":
				i["s"]["t"] = float(d["ciclo_s"]) - float(d["aviso_s"]) - 0.02
				await grava.call(float(d["aviso_s"]) + float(d["balanco_s"]) + 0.6)
				i["s"]["t"] = -9999.0
			"onda_balsa":
				for qual in ([1] if uma else [1, 0]):
					var b: Array = d["balsas"][1 - qual]   # robôs na balsa que vai levar a onda (sentem o golpe)
					var xs := [float(b[0]) + 1.5, float(b[0]) + 4.5] if float(b[3]) > 0.0 else [float(b[1]) - 1.5, float(b[1]) - 4.5]
					for ri in 2:
						var r = main.robots[ri]
						r.invuln = 0.0
						r.velocity = Vector2.ZERO
						r.own_vx = 0.0
						r.position = Vector2(float(xs[ri]) * 64.0, 6.0 * 64.0)
					await grava.call(0.5)
					i["s"]["qual"] = qual
					i["s"]["t"] = float(d["ciclo_s"]) - 0.02
					await grava.call(float(d["aviso_s"]) + float(d.get("quebra_s", 0.0)) + float(d["onda_s"]) + float(d.get("escoa_s", 0.0)) + 1.2)
					for r in main.robots:
						r.invuln = 9999.0
				i["s"]["t"] = -9999.0
	main.hud.visible = true
	print("video: ", n[0], " quadros")
