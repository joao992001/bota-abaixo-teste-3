extends Node
## Modo Festa · DEMOLIÇÃO: todos numa obra de caixotes sobre espinhos. A marreta quebra caixotes
## (inclusive o chão de quem está ao lado) e empurra robôs; pular na cabeça atordoa; caixote racha
## se alguém fica parado em cima; depois de um tempo, terremoto derruba blocos. Último em pé leva ⭐.
## Itens caem do céu em bolhas: dinamite (arremessa), martelão, capacete de aço (escudo), botas de mola.
## Números em data/modos.json ("demolicao").

var main: Node
var cfg: Dictionary
var t := 0.0                 # tempo da rodada (depois do VAI!)
var quake_t := 0.0
var quaking := false
var round_winner := -1
var banner := ""
var banner_t := 0.0
var booms: Array = []        # explosões desenhadas {pos, t}
var canvas: Node2D           # desenha itens, dinamites e explosões no mundo
var crumbling := false       # quebra por ter ficado parado em cima (culpa de quem estava em cima)
const ArenaFx := preload("res://modes/arena_fx.gd")
const Canteiro := preload("res://modes/canteiro.gd")
const Etapas := preload("res://modes/etapas.gd")
const Cena := preload("res://modes/cena.gd")
const CenaCargueiro := preload("res://modes/cena_cargueiro.gd")
const Agua := preload("res://modes/agua.gd")   # regra-assinatura ÁGUA (Fase 2)   # Fase 2 (cena: cargueiro)
const Mecanismos := preload("res://modes/mecanismos.gd")
const Spells := preload("res://modes/spells.gd")
const Kit := preload("res://ui/kit.gd")
var fx: Node2D = null        # mecânicas da arena (plataformas, lama, bola, esteiras)
var spells: Node2D = null     # caixas de spell, slots e efeitos (modes/spells.gd)
var canteiro: Node2D = null  # estrutura destrutível do Canteiro de Obras (Derruba), quando a arena tem "canteiro: 1"
var etapas: Node2D = null   # cenas do mapa (modes/etapas.gd): transição por destruição (90%) e queda para a próxima cena
var agua: Node2D = null     # zonas de água da fase (modes/agua.gd), se o manifesto tiver
var cena: Node2D = null     # cena viva da fase (modes/cena.gd): fundo em camadas animado
var mecs: Node2D = null     # mecanismos da fase (modes/mecanismos.gd)
var arena := {}              # {id, nome, dica} da rodada atual
var last_arena := ""
var last_choice := ""         # rodízio: escolha da rodada anterior
var tnt_queue: Array = []
var go_played := false
var break_reason := ""       # por que o caixote que está quebrando agora quebrou (para a causa da queda)
var break_by := -1
var death_log: Array = []
var feed: Array = []         # avisos na tela: "P3 derrubou P1"
var net_hp := {}             # rede: Vector2i -> quedas que ainda aguenta
# ---- submodos (Último em Pé, Vidas, Placar de Demolição, Batata-Dinamite)
var sub := {}                # modo atual (data/modos.json → demolicao.modos): derruba, batata, rei, fuga
var lives := {}              # Derruba: pid -> vidas restantes
var lives_setting := 4       # AJUSTES (Derruba): vidas (v2: 3 a 6, padrão 4)
var ordem_elim: Array = []   # Derruba v2: pids na ordem em que foram eliminados (ranking dos resultados)
var luta_t := 0.0            # duração da luta (s, sem a contagem): partida válida = ≥ 1 min (A17)
var fuse_setting := 1        # AJUSTES (Batata): 0 curto, 1 normal, 2 longo
const FUSES := [[10, 14], [14, 20], [20, 28]]   # pavio curto/normal/longo (s): mais tempo para correr
# Rei da Obra
var king := -1               # quem está com o capacete de ouro (-1: no chão)
var crown_pos := Vector2.ZERO
var crown_vel := Vector2.ZERO
var crown_home := Vector2.ZERO
var king_time := {}          # pid -> segundos com o capacete
var crown_cd := {}           # pid -> espera para pegar de novo depois de perder
var king_hit := {}           # pid -> last_hit do quadro anterior (para perceber o golpe)
var king_setting := 0        # AJUSTES: 0 = 20 s, 1 = 30 s, 2 = 45 s
var king_grace := 0.0        # o rei acabou de pegar: protegido por um instante (a coroa não fica pulando de mão)
const KING_GOALS := [20, 30, 45]
var bomb_holder := -1        # Batata: quem está com a dinamite
var bomb_fuse := 0.0
var bomb_next := 0.0
var bomb_pass_cd := 0.0
var bomb_beep := 0.0
var items_on := true         # AJUSTES: spells ligadas

## Modo de jogo da partida (derruba, batata, rei, fuga).
func rule() -> String:
	return String(sub.get("id", "derruba"))

## Derruba v2 (A4): num mapa de verdade a partida é UMA luta (sem rodadas internas). Mapas-ferramenta seguem em rodadas.
func partida_unica() -> bool:
	return rule() == "derruba" and bool(sub.get("partida_unica", false)) and main.level != null \
		and not MapaReg.eh_ferramenta(String(main.level.id)) and not main.sandbox

## Ranking da luta: vencedor, depois quem saiu por último … quem saiu primeiro.
func ranking() -> Array:
	var out := []
	for i in main.players.size():
		if not i in ordem_elim:
			out.append(i)
	for k in range(ordem_elim.size() - 1, -1, -1):
		if not ordem_elim[k] in out:
			out.append(ordem_elim[k])
	return out

func find_mode(id: String) -> Dictionary:
	for m in cfg["modos"]:
		if m["id"] == id:
			return m
	return cfg["modos"][0]

## Arenas do modo (na ordem do data/modos.json).
func mode_arenas(id: String) -> Array:
	var ids: Array = find_mode(id).get("arenas", [])
	var out := []
	for a in cfg["arenas"]:
		if a["id"] in ids:
			out.append(a)
	return out    # {arena, t, victim, cause, by, round}    # TNT quebrado explode logo depois: {pos, t}

func setup(m: Node) -> void:
	main = m
	cfg = Data.read_json("data/modos.json")["demolicao"]

func c(key: String) -> float:
	return float(cfg[key])


## Arena da rodada: a escolhida ou, no sorteio, uma diferente da anterior.
func pick_arena() -> Dictionary:
	var list: Array = mode_arenas(main.game_mode)
	if list.is_empty():
		list = cfg["arenas"]
	var choice: String = main.arena_choice
	if choice == "laboratorio":
		return {"id": "laboratorio", "nome": "Laboratório", "dica": "Meça e ajuste: START abre o painel", "musica": "fabrica"}
	if choice != "sorteio" and choice == last_choice and main.round_no > 1:
		# rodízio (como em Gang Beasts): a 1ª rodada na escolhida, depois a próxima fase do modo
		var ids: Array = list.map(func(a): return a["id"])
		var k := ids.find(last_arena)
		if k >= 0:
			return list[(k + 1) % list.size()]
	last_choice = choice
	if choice != "sorteio":
		for a in cfg["arenas"]:   # arena escolhida (de qualquer modo: Laboratório e testes podem pedir qualquer uma)
			if a["id"] == choice:
				return a
	var opts := list.filter(func(a): return a["id"] != last_arena)
	if opts.is_empty():
		opts = list
	return opts[main.rng.randi() % opts.size()]

## Nova rodada: arena nova, robôs nos spawns de acordo com o número de jogadores.
func start_round() -> void:
	ordem_elim.clear()
	luta_t = 0.0
	arena = pick_arena()
	last_arena = arena["id"]
	main.load_arena(arena["id"])
	if fx != null and is_instance_valid(fx):
		fx.queue_free()
	fx = ArenaFx.new()
	main.world.add_child(fx)
	main.world.move_child(fx, 1)
	fx.setup(main, main.level)
	if canteiro != null and is_instance_valid(canteiro):
		canteiro.queue_free()
	canteiro = null
	if String(main.level.prop("canteiro", "")) != "":
		canteiro = Canteiro.new()
		main.world.add_child(canteiro)
		main.world.move_child(canteiro, 2)
		canteiro.setup(main, main.level)
	if etapas != null and is_instance_valid(etapas):
		etapas.queue_free()
	etapas = null
	if String(main.level.prop("etapa2", "")) != "":
		etapas = Etapas.new()
		main.world.add_child(etapas)
		etapas.setup(main)
	if cena != null and is_instance_valid(cena):
		cena.queue_free()
	cena = null
	if String(main.level.prop("cena", "")) != "":
		cena = CenaCargueiro.new() if String(main.level.prop("cena", "")) == "cargueiro" else Cena.new()
		main.world.add_child(cena)
		main.world.move_child(cena, 0)   # atrás de tudo (mapa, estrutura, robôs)
		cena.setup(main)
	main.bg.visible = cena == null
	if mecs != null and is_instance_valid(mecs):
		mecs.queue_free()
	mecs = null
	if not MapaReg.mecanismos(main.game_mode, main.level.id).is_empty():
		mecs = Mecanismos.new()
		main.world.add_child(mecs)
		main.world.move_child(mecs, 3)   # no palco, atrás dos robôs
		mecs.setup(main)
	if agua != null and is_instance_valid(agua):
		agua.queue_free()
	agua = null
	for r in main.robots:
		r.agua_grav = 1.0
		r.agua_queda = 1.0
		r.agua_empurra = 1.0
	if Agua.tem_agua(main):
		agua = Agua.new()
		main.world.add_child(agua)
		agua.setup(main)
	if spells != null and is_instance_valid(spells):
		spells.queue_free()
	spells = Spells.new()
	main.world.add_child(spells)
	spells.setup(main, self)
	tnt_queue.clear()
	main.level.block_hp = int(c("block_hp"))
	for b in main.level.blocks.values():
		b["hp"] = main.level.block_hp
	main.level.block_broken.connect(_on_block_broken)
	if canvas == null or not is_instance_valid(canvas):
		canvas = Node2D.new()
		canvas.draw.connect(_draw_canvas)
		main.world.add_child(canvas)
	t = 0.0
	quake_t = 0.0
	quaking = false
	round_winner = -1
	sub = find_mode(main.game_mode)
	_reset_crown()
	lives.clear()
	for i in main.players.size():
		lives[i] = lives_setting if rule() == "derruba" else 1
	bomb_holder = -1
	bomb_next = 4.0
	bomb_pass_cd = 0.0
	auto_lever_t = float(sub.get("alavanca_auto_s", 12.0))
	booms.clear()
	banner = String(arena["nome"]).to_upper()
	banner_t = 2.2
	go_played = false
	Audio.play("contagem")
	var n: int = main.players.size()
	var spots: Array = cfg["spawns_by_players"].get(str(n), [1, 2, 3, 4])
	main.start_run_at(spots)
	main.events.reset_round()
	for r in main.robots:
		r.hammer_left = 999
		r.facing = 1 if r.position.x < 960 else -1

func update(dt: float) -> void:
	banner_t = maxf(banner_t - dt, 0.0)
	if main.countdown <= 0.0:
		luta_t += dt
	_update_fx(dt)
	var _pf := Perf.t0()
	main.events.update(dt)
	Perf.add("eventos", _pf)
	_pf = Perf.t0()
	if etapas != null and is_instance_valid(etapas):
		etapas.update(dt)   # depois dos eventos: a queda mexe na gravidade do quadro
	if mecs != null and is_instance_valid(mecs):
		mecs.update(dt)
	if agua != null and is_instance_valid(agua):
		agua.update(dt)   # depois de eventos/mecanismos: soma na lentidão do quadro
	Perf.add("etapas_mecanismos", _pf)
	_pf = Perf.t0()
	if fx != null and is_instance_valid(fx):
		fx.update(dt, main.countdown <= 0.0)
	Perf.add("arena_fx", _pf)
	if not go_played and main.countdown <= 0.6:
		go_played = true
		Audio.play("vai")
		for r in main.robots:
			r.invuln = float(cfg["recuperacao"]["invuln_inicio_s"])
	if main.countdown > 0.0:
		return
	for q in tnt_queue:
		q["t"] -= dt
		if q["t"] <= 0.0:
			explode(q["pos"], 150.0)
	tnt_queue = tnt_queue.filter(func(q): return q["t"] > 0.0)
	t += dt
	var lv = main.level
	var alive: Array = main.robots.filter(func(r): return r.alive)
	_pf = Perf.t0()
	spells.update(dt, alive)
	Perf.add("engenhocas", _pf)
	# pisão na cabeça (o capacete bloqueia)
	for r in alive:
		r.stomp_immune = maxf(r.stomp_immune - dt, 0.0)
	for a in alive:
		if a.velocity.y <= 120.0 or a.stun_t > 0.0:
			continue
		for b in alive:
			if a == b or b.stomp_immune > 0.0 or b.invuln > 0.0 or b.god or b.guard_t > 0.0:
				continue
			var head: float = b.rect().position.y
			if absf(a.position.y - head) < 16.0 and absf(a.position.x - b.position.x) < 38.0:
				a.velocity.y = -c("stomp_bounce")
				a.var_jump = 0.0
				Audio.play("pisao")
				var side := signf(a.position.x - b.position.x)
				if side == 0.0:
					side = float(a.facing)
				a.own_vx = side * c("stomp_side_push")   # sai de cima, não cai de novo na mesma cabeça
				a.vis.stretch()
				b.stomp_immune = c("stomp_immune_s")
				b.last_hit = 0.0
				b.last_cause = "pisão"
				b.last_attacker = a.pid
				b.hanging = false
				b.dmg += float(cfg["amassometro"]["pisao"]["dano"])
				b.stun_t = c("stun_stomp_s")
				b.recover_len = float(b.c["arremesso"]["retorno_s"]) * 0.5
				b.recover_t = b.recover_len
				b.atk = ""
				b.vis.hurt(0.5, 0)
				PlayerInput.vibrate(b.pid, 0.6, 0.3, 0.18)
				PlayerInput.vibrate(a.pid, 0.25, 0.0, 0.06)
				Audio.voice("voz_ai", b.vis.model)
				Audio.play("tonto", 1.0, -4.0)
				b.vis.sq = Vector2(1.5, 0.55)
				main.float_text(b.position + Vector2(0, -110), "PISÃO!", main.player_color(a.pid))
				main.spark(b.position + Vector2(0, -70), 6)
				main.dust(b.position + Vector2(0, -60), 0.7)
				main.shake(4.0)
				break
	# caixote racha e cai se alguém fica parado em cima
	var stood := {}
	for r in alive:
		if r.is_on_floor() and rule() != "rei":   # no Rei da Obra o chão não racha por ficar parado (rodada longa)
			var cell := Vector2i(int(r.position.x / 64.0), int((r.position.y + 2.0) / 64.0))
			if lv.blocks.has(cell):
				stood[cell] = true
	for cell in lv.blocks.keys():
		var b: Dictionary = lv.blocks[cell]
		if stood.has(cell):
			b["load"] += dt
			if b["load"] >= c("crumble_break_s"):
				crumbling = true
				lv.break_block(cell)
				crumbling = false
				continue
			if b["load"] >= c("crumble_crack_s") and b["hp"] == lv.block_hp:
				b["hp"] = lv.block_hp - 1
				lv.queue_redraw()
		if b["warn"] > 0.0:
			b["warn"] -= dt
			if b["warn"] <= 0.0:
				break_reason = "terremoto"
				lv.break_block(cell)
				break_reason = ""
	# terremoto depois de um tempo: garante que a rodada acaba
	var quake_at := float(main.level.prop("terremoto", str(c("quake_start_s"))))
	if rule() in ["batata", "rei", "fuga"] or main.sandbox:
		quake_at = 0.0   # a dinamite / o relógio do rei já garantem o fim da rodada
	if quake_at > 0.0 and t >= quake_at:
		if not quaking:
			quaking = true
			banner = "TERREMOTO!"
			banner_t = 1.6
			Audio.play("terremoto")
			main.shake(10.0)
		quake_t -= dt
		if quake_t <= 0.0 and lv.blocks.size() > 0:
			quake_t = c("quake_every_s")
			var keys: Array = lv.blocks.keys().filter(func(k): return lv.blocks[k]["warn"] <= 0.0)
			if keys.size() > 0:
				var k: Vector2i = keys[main.rng.randi() % keys.size()]
				lv.blocks[k]["warn"] = c("quake_warn_s")
				main.shake(2.0)
	_update_water_and_nets(dt, alive)
	for f in feed:
		f["t"] += dt
	feed = feed.filter(func(f): return f["t"] < 4.5)
	_update_bomb(dt, alive)
	_update_auto_lever(dt)
	var king_won := _update_king(dt, alive)
	# fim da rodada: sobrou 1 (ou ninguém)
	var over: bool = alive.size() <= 1 and main.robots.size() >= 2 and not main.sandbox
	if rule() == "rei":
		over = king_won >= 0 and not main.sandbox
		if over:
			alive = [main.robots[king_won]]
	if rule() == "fuga":
		for rf in main.robots:
			if rf.finished:   # chegou ao elevador: vence na hora
				over = true
				alive = [rf]
				break
	if main.end_delay < 0.0 and over:
		round_winner = alive[0].pid if alive.size() == 1 else -1
		main.end_delay = 1.4
		if round_winner >= 0:
			alive[0].vis.expression = "vitoria"
			Audio.play("rodada_vence")
			Audio.voice("voz_eba", alive[0].vis.model)
			banner = "P%d  VENCEU A RODADA!" % (round_winner + 1)
		else:
			Audio.play("menu_negado")
			banner = "EMPATE!"
		banner_t = 3.0

# ---------------------------------------------------------------- itens
## Parte do mapa em jogo: a tela, nos mapas com câmera que rola; senão, o mapa inteiro.
func play_rect() -> Rect2:
	if fx != null and is_instance_valid(fx) and fx.scroll_on:
		return Rect2(fx.scroll_center - Vector2(960, 512), Vector2(1920, 1024))
	return main.level.area   # fase em etapas: a área da etapa atual

## Explosão: destrói caixotes no raio e lança os robôs para longe (TNT tem raio maior).
func explode(pos: Vector2, rad := -1.0, by := -1) -> void:
	var dc: Dictionary = cfg["explosao"]
	if rad < 0.0:
		rad = float(dc["radius_px"])
	var lv = main.level
	for cell in lv.blocks.keys():
		if (Vector2(cell * 64) + Vector2(32, 32)).distance_to(pos) < rad:
			break_reason = "explosão"
			lv.damage(cell, int(dc["block_damage"]))
			break_reason = ""
	for r in main.robots:
		if r.alive and r.rect().get_center().distance_to(pos) < rad + 30.0:
			var dir := 1 if r.rect().get_center().x >= pos.x else -1
			r.take_hit(dir, "explosao", by if by != r.pid else -1)
	booms.append({"pos": pos, "t": 0.0})
	Audio.play("explosao")
	main.spark(pos, 10)
	main.dust(pos, 1.6)
	main.shake(12.0)

func _update_fx(dt: float) -> void:
	for b in booms:
		b["t"] += dt
	booms = booms.filter(func(b): return b["t"] < 0.6)
	if canvas != null and is_instance_valid(canvas):
		canvas.queue_redraw()

func _draw_canvas() -> void:
	var _pf := Perf.t0()
	_draw_canvas_perf()
	Perf.add("draw_demo", _pf)

func _draw_canvas_perf() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if rule() == "rei":
		var cp := crown_pos
		var glow := 0.5 + 0.5 * sin(now * 6.0)
		canvas.draw_circle(cp, 40.0 + glow * 8.0, Color(1.0, 0.85, 0.3, 0.18 + glow * 0.12))
		if king < 0:
			cp.y += sin(now * 3.0) * 4.0 - 26.0
			canvas.draw_line(cp + Vector2(0, 30), Vector2(cp.x, crown_pos.y), Color(1, 0.9, 0.5, 0.4), 3.0)
		canvas.draw_texture_rect(Data.tex("itens/capacete"), Rect2(cp - Vector2(30, 30), Vector2(60, 60)), false, Color(1.0, 0.82, 0.25))
		for k in 3:
			var a2 := now * 2.0 + k * TAU / 3.0
			var sp := cp + Vector2(cos(a2) * 36.0, sin(a2) * 14.0 - 18.0)
			canvas.draw_circle(sp, 3.0, Color(1, 1, 0.8, 0.9))
	# explosão cartoon: bolas amarelas/laranja e fumaça escura em camadas (ref. de explosões)
	for b in booms:
		var k: float = b["t"] / 0.6
		var p: Vector2 = b["pos"]
		var r := 40.0 + 110.0 * sqrt(k)
		var a := 1.0 - k
		for i in 7:
			var ang := i * TAU / 7.0 + 0.4
			canvas.draw_circle(p + Vector2.from_angle(ang) * r * 0.55, r * 0.5, Color(0.25, 0.22, 0.27, 0.55 * a))
		for i in 6:
			var ang := i * TAU / 6.0
			canvas.draw_circle(p + Vector2.from_angle(ang) * r * 0.35, r * 0.42, Color(1.0, 0.55, 0.15, a))
		canvas.draw_circle(p, r * 0.45, Color(1.0, 0.85, 0.25, a))
	# Batata-Dinamite: a dinamite acesa em cima da cabeça de quem está com ela + pavio
	if rule() == "batata" and bomb_holder >= 0 and bomb_holder < main.robots.size():
		var h = main.robots[bomb_holder]
		if h.alive:
			var hp: Vector2 = h.position + Vector2(0, -122 + sin(now * 10.0) * 3.0)
			var shake := Vector2(sin(now * 60.0), cos(now * 53.0)) * clampf(3.0 - bomb_fuse, 0.0, 3.0)
			canvas.draw_set_transform(hp + shake, sin(now * 6.0) * 0.25, Vector2(1.5, 1.5))
			canvas.draw_texture_rect(Data.tex("itens/dinamite"), Rect2(-16, -16, 32, 32), false)
			canvas.draw_set_transform(Vector2.ZERO)
			if fmod(now, 0.2) < 0.1:
				canvas.draw_circle(hp + shake + Vector2(14, -24), 7, Color("#fff4c8"))
			var col := Color("#d42035") if bomb_fuse < 3.0 else Color("#2a1a2e")
			var hidden := false
			Kit.text(canvas, hp + Vector2(-60, -34), "?" if hidden else "%d" % ceili(bomb_fuse), 34, col, HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color("#fff7ee"))

# ---------------------------------------------------------------- marreta
## Marretada: empurra o robô à frente e quebra o caixote à frente (no corpo ou no chão).
## Segurando ▼, quebra o caixote embaixo de você mesmo. Martelão: 1 golpe quebra, empurra mais.
## Golpe rápido ("rapido"): só combate (robôs, passa a TNT, derruba o capacete) e alavancas.
## Marretada pesada ("pesado"): golpe mais forte + destruição (caixotes, chão com ▼, barris) e alavancas.
## O Martelão (item) fortalece só a pesada. Retorna true se acertou um robô.
## A47: a obra quebra com a LUTA — robô arremessado contra parede/bloco ou pouso forte racha a peça no ponto.
func luta_quebra(r, pt: Vector2, forca: int) -> void:
	if canteiro == null or not is_instance_valid(canteiro):
		return
	for p in canteiro.parts:
		if p["fallen"] or p["nucleo"]:
			continue
		if canteiro.hit_rect(p).grow(10).has_point(pt):
			canteiro.damage(p, forca * int(canteiro.cfg.get("luta_mult", 1)), pt)   # A53b: a luta conta o dobro
			main.spark(pt, 6)
			main.dust(pt, 1.0)
			main.shake(4.0 + 3.0 * forca)
			Audio.play("caixote_pancada", 0.9, -2.0)
			return

func attack(r, kind: String) -> bool:
	var heavy := kind == "pesado"
	var big := false
	var ac: Dictionary = r.c["ataque_pesado"] if heavy else r.c["ataque_rapido"]
	var reach := float(ac["alcance_px"]) * (1.3 if big else 1.0)
	var mult := 1.0
	var rr: Rect2 = r.rect()
	# a área começa DENTRO do corpo (meio): quem está colado/sobreposto também leva
	var cx: float = rr.get_center().x
	var w := reach + rr.size.x / 2.0
	var hit := Rect2(cx if r.facing > 0 else cx - w, rr.position.y - (10.0 if heavy else 0.0), w, rr.size.y + (10.0 if heavy else 0.0))
	var hk := ("martelao" if big else "pesado") if heavy else "rapido"
	var hdir: int = r.facing
	var critico := false
	var ap: Dictionary = r.c["ataque_pesado"]
	if heavy:   # A47: carga, direção e crítico na ponta
		r.hit_mult = 1.0 + float(ap["carga_mult"]) * clampf(r.heavy_charge / float(ap["carga_max_s"]), 0.0, 1.0)
		match r.atk_dir:
			"cima":
				hit = Rect2(cx - 60, rr.position.y - float(ap["alcance_cima_px"]), 120, float(ap["alcance_cima_px"]) + 40)
				hk = "pesado_cima"
			"baixo":
				hit = Rect2(cx - 56, rr.end.y - 30, 112, float(ap["alcance_baixo_px"]) + 30)
				hk = "pesado_baixo"
			_:
				for o in main.robots:   # o rival está na PONTA da marreta? → crítico
					if o != r and o.alive and hit.intersects(o.rect()):
						var dd: float = (o.rect().get_center().x - cx) * r.facing
						if dd >= rr.size.x / 2.0 + reach * float(ap["critico_frac"]) - 12.0:
							critico = true
				if critico or r.heavy_charge >= float(ap["carga_max_s"]) * 0.95:
					critico = true
					hk = "martelao"
					r.hit_mult *= float(ap["critico_mult"])
	if not heavy:
		var cc: Dictionary = r.c["combo"]
		match r.atk_dir:
			"cima":
				hit = Rect2(cx - 56, rr.position.y - float(cc["alcance_cima_px"]), 112, float(cc["alcance_cima_px"]) + 30)
				hk = "cima"
			"baixo":
				hit = Rect2(cx - 50, rr.end.y - 30, 100, float(cc["alcance_baixo_px"]) + 30)
				hk = "baixo"
			"corrida":
				hit = Rect2(cx if r.facing > 0 else cx - w - 20, rr.position.y, w + 20, rr.size.y)
				hk = "corrida"
			_:
				hk = "combo_final" if r.combo_i == 2 else "combo"
	if spells != null and spells.mecha_of(r) != "" and r.spell_form != "bola":   # golpes do modo mecha (A33)
		var ms: Array = spells.mecha_strike(r, kind)
		hit = ms[0]
		hk = ms[1]
	var hit_robot := false
	var hs: Dictionary = r.c["hitstop"]
	for o in main.robots:
		if o != r and o.alive and hit.intersects(o.rect()):
			var odir := hdir if absf(o.position.x - r.position.x) < 6.0 else signi(int(o.position.x - r.position.x))
			if not o.take_hit(odir if not heavy else r.facing, hk, r.pid):
				continue
			var stop := minf(float(hs["pesado" if heavy else "rapido"]) + o.dmg * float(hs["por_dano"]), float(hs["max"]))
			o.hitstop = stop
			r.hitstop = stop
			PlayerInput.vibrate(r.pid, 0.45 if heavy else 0.25, 0.0, 0.08 if heavy else 0.05)   # quem acertou sente o golpe
			pass_bomb(r.pid, o.pid)
			Audio.play("ba_impacto_pesado" if heavy else "ba_impacto_rapido")   # pancada metálica no robô (impacto confirmado)
			main.spark(o.rect().get_center(), 9 if heavy else 4)
			main.shake((7.0 if heavy else 2.5) * mult)
			main.impact_fx(o.rect().get_center() + Vector2(-r.facing * 10, 0), r.facing, 1.0 if heavy else 0.3)
			main.add_stat(r.pid, "golpes")
			if critico:
				main.float_text(o.position + Vector2(0, -150), "CRÍTICO!", Color("#d42035"))
				o.hitstop = float(hs["max"]) + 0.04
				r.hitstop = o.hitstop
				main.shake(12.0)
				main.ring_fx(o.rect().get_center(), 1.2)
			hit_robot = true
	if spells != null and spells.decoy_hit(r, hit, heavy):   # D06: bateu no boneco de teste
		hit_robot = true
	var struct_hit := false
	if fx != null and is_instance_valid(fx) and fx.hammer_hit(r, hit.grow(8), heavy):
		struct_hit = true
		if not hit_robot:
			r.hitstop = float(hs["rapido"])
	if mecs != null and is_instance_valid(mecs) and mecs.hammer_hit(hit.grow(8), heavy, r.pid):
		struct_hit = true
		if not hit_robot:
			r.hitstop = float(hs["rapido"])   # controle de mecanismo da fase
	if main.events.hammer_hit(hit.grow(8), heavy, r.pid):
		struct_hit = true
		if not hit_robot:
			r.hitstop = float(hs["rapido"])   # entulho do evento G06
	if heavy and canteiro != null and is_instance_valid(canteiro):
		canteiro.mute_hit = true   # o clang aprovado substitui a pancada genérica da peça
		if canteiro.hammer(r, hit, PlayerInput.held(r.pid, "down"), critico):
			struct_hit = true
			if not hit_robot:
				r.hitstop = float(hs["rapido"])
				main.shake(6.0)
		canteiro.mute_hit = false
	if not hit_robot and struct_hit:   # acertou estrutura/máquina: clang da marreta no metal (nunca junto do impacto no robô)
		Audio.play("ba_marreta_pesada" if heavy else "ba_marreta_rapida")
	r.hit_mult = 1.0
	if hit_robot or not heavy:
		return hit_robot
	var lv = main.level
	var feet_row := int((r.position.y + 2.0) / 64.0)
	var targets: Array = []
	if PlayerInput.held(r.pid, "down"):
		targets.append(Vector2i(int(r.position.x / 64.0), feet_row))
	else:
		var fx: float = (rr.end.x + 20.0) if r.facing > 0 else (rr.position.x - 20.0)
		var col := int(floor(fx / 64.0))
		targets.append(Vector2i(col, feet_row - 1))
		targets.append(Vector2i(col, feet_row))
	for cell in targets:
		if lv.blocks.has(cell):
			var center := Vector2(cell * 64) + Vector2(32, 32)
			main.spark(center, 4)
			main.dust(center, 0.8)
			Audio.play("ba_marreta_pesada")
			break_reason = "chão marretado"
			break_by = r.pid
			lv.damage(cell, main.level.block_hp if rule() == "batata" else 1)   # Batata: 1 golpe quebra
			break_reason = ""
			break_by = -1
			r.hitstop = float(hs["rapido"])
			main.shake(4.0)
			return false
	return false

## Água: não mata; volta do alto com dano extra. Rede: quica e rasga depois de algumas quedas.
func _update_water_and_nets(dt: float, alive: Array) -> void:
	var lv = main.level
	for r in alive:
		for w in lv.water_rects:
			if w.has_point(r.position + Vector2(0, -10)):
				r.dmg += float(cfg["amassometro"]["agua"]["dano"])
				Audio.play("lama", 0.6)
				main.dust(r.position, 1.4)
				main.float_text(r.position + Vector2(0, -80), "TCHIBUM! +%d%%" % int(cfg["amassometro"]["agua"]["dano"]), Color("#4f86d9"))
				respawn(r)
				break
		if r.velocity.y > 150.0:
			var cell := Vector2i(int(r.position.x / 64.0), int((r.position.y - 4.0) / 64.0))
			if lv.ch_at(cell) == "n" and r.position.y >= cell.y * 64.0 + 8.0 and r.position.y - r.velocity.y * dt <= cell.y * 64.0 + 14.0:
				r.velocity.y = -minf(r.velocity.y * 0.85 + 300.0, float(cfg["rede"]["quica"]))
				r.air_jumps = 1
				Audio.play("pulo_mola", 0.8)
				var hp: int = net_hp.get(cell, int(cfg["rede"]["aguenta"])) - 1
				net_hp[cell] = hp
				if hp <= 0:
					for dx in range(-1, 2):
						var nc := cell + Vector2i(dx, 0)
						if lv.ch_at(nc) == "n":
							lv.set_cell_char(nc, ".")
					main.dust(r.position, 1.2)
					main.float_text(r.position + Vector2(0, -80), "RASGOU!", Color.WHITE)

## Volta pendurado no guindaste num lugar livre longe dos outros, invulnerável por um tempo.
func respawn(r, ahead := false) -> void:
	var lv = main.level
	var best := Vector2i(-1, -1)
	var best_d := -1.0
	var pr := play_rect().grow_individual(-128, -192, -192, -64)
	var zonas_mec: Array = mecs.zonas_perigo() if mecs != null and is_instance_valid(mecs) else []
	# só as células dentro da área de jogo (o resto era varrido e descartado: o Canteiro empilha cenas → 6–8 ms por volta)
	for y in range(maxi(3, int(pr.position.y / 64.0) - 1), mini(lv.rows - 1, int(pr.end.y / 64.0) + 2)):
		for x in range(maxi(1, int(pr.position.x / 64.0) - 1), mini(lv.cols - 1, int(pr.end.x / 64.0) + 2)):
			var c := Vector2i(x, y)
			if lv.is_solid(c) and lv.ch_at(c) != "I" and not lv.is_solid(c + Vector2i.UP) and not lv.is_solid(c + Vector2i(0, -2)) \
					and not lv.is_solid(c + Vector2i(0, -3)) and not lv.is_solid(c + Vector2i(0, -4)):   # desce de 220 px: caminho livre
				var p := Vector2(x * 64 + 32, y * 64)
				if not pr.has_point(p) or not _firm(lv, c) or not (_firm(lv, c + Vector2i.LEFT) or _firm(lv, c + Vector2i.RIGHT)):
					continue   # só volta em bloco firme, com chão ao lado (nada de caixote solto rachando)
				var danger := false
				for h in lv.hazard_rects:
					if h.grow(96).has_point(p):
						danger = true
				for h in zonas_mec:
					if h.has_point(p):
						danger = true
				if danger:
					continue
				if fx != null and is_instance_valid(fx) and fx.goo_on and p.y > fx.goo_y - 96.0:
					continue
				var dmin := 1e9
				for o in main.robots:
					if o != r and o.alive:
						dmin = minf(dmin, o.position.distance_to(p))
				dmin += main.rng.randf_range(0, 200)
				if not (_firm(lv, c + Vector2i.LEFT) and _firm(lv, c + Vector2i.RIGHT)):
					dmin -= 500.0   # beira de buraco: só se não houver lugar melhor (bots caíam no vão logo ao voltar)
				elif not (_firm(lv, c + Vector2i(-2, 0)) and _firm(lv, c + Vector2i(2, 0))):
					dmin -= 300.0   # perto da beira: prefere chão com folga dos dois lados (vento/empurrão não derruba)
				if rule() == "fuga" and ahead and fx != null and is_instance_valid(fx):
					dmin = -p.distance_to(fx.scroll_center)   # bolha: volta no meio da tela
				elif rule() == "fuga":
					# Fuga: volta no ponto mais atrasado da tela (perde terreno, mas não sai)
					dmin = (-p.x if lv.cols > lv.rows * 2 else p.y) + main.rng.randf_range(0, 40)
				if dmin > best_d:
					best_d = dmin
					best = c
	if best.x < 0:
		# não sobrou chão firme: o guindaste traz um caixote novo e o robô volta em cima dele
		var spot: Vector2 = crown_home if rule() == "rei" else lv.spawns.get((etapas.spawn_index(r.pid % 4 + 1) if etapas != null and is_instance_valid(etapas) else r.pid % 4 + 1), Vector2(lv.cols * 32.0, 256.0))
		var cell := Vector2i(int(spot.x / 64.0), int(spot.y / 64.0))
		if not lv.is_solid(cell):
			lv.add_block(cell)
			if lv.blocks.has(cell):
				lv.blocks[cell]["hp"] = lv.block_hp
			main.dust(Vector2(cell * 64) + Vector2(32, 32), 1.0)
		r.position = Vector2(cell.x * 64 + 32, cell.y * 64 - 220)
		r.reset_physics_interpolation()
		r.velocity = Vector2.ZERO
		r.own_vx = 0.0
		r.stun_t = 0.0
		r.hanging = false
		r.invuln = float(cfg["recuperacao"]["invuln_volta_s"])
		r.drop_t = 1.0
		return
	r.position = Vector2(best.x * 64 + 32, best.y * 64 - 220)
	r.reset_physics_interpolation()
	r.velocity = Vector2.ZERO
	r.own_vx = 0.0
	r.stun_t = 0.0
	r.hanging = false
	r.invuln = float(cfg["recuperacao"]["invuln_volta_s"])
	r.drop_t = 1.0

## Chão firme para voltar: sólido fixo, ou caixote inteiro, sem aviso de queda e sem estar rachando.
func _firm(lv, c: Vector2i) -> bool:
	if not lv.is_solid(c) or lv.ch_at(c) in ["I", "T"]:
		return false
	if canteiro != null and is_instance_valid(canteiro) and canteiro.owner_of.has(c):
		# estrutura do Canteiro: só laje/chão firme da etapa atual (nunca trecho avisado, rachado, plataforma solta ou grelha)
		var p: Dictionary = canteiro.owner_of[c]
		return p["kind"] in ["laje", "terreo"] and not p["fallen"] and p["warn_t"] <= 0.0 and p["crit_t"] <= 0.0 \
			and int(p["state"]) < 2 and p["evt"] == "" and int(p.get("etapa", 1)) == canteiro.etapa_now()
	if lv.blocks.has(c):
		var b: Dictionary = lv.blocks[c]
		return b["warn"] <= 0.0 and b["hp"] >= lv.block_hp and b["load"] < 0.5
	return true

func _on_block_broken(cell: Vector2i, kind: String) -> void:
	var center := Vector2(cell * 64) + Vector2(32, 32)
	if break_by >= 0 and break_by < main.players.size():
		main.players[break_by]["stats"]["caixotes"] += 1
	Audio.play("caixote_quebra")
	if kind == "tnt":
		tnt_queue.append({"pos": center, "t": 0.18})   # explode logo depois (dá para ver a reação em cadeia)
	# quem estava em cima caiu por golpe/explosão/terremoto (não "sozinho"), a não ser que tenha ficado parado
	for r in main.robots:
		if r.alive and absf(r.position.x - center.x) < 56.0 and absf(r.position.y - cell.y * 64.0) < 6.0:
			if crumbling:
				r.fall_reason = "ficou parado"
				r.last_cause = "ficou parado"
			else:
				r.last_hit = 0.0
				r.last_cause = break_reason if break_reason != "" else "chão quebrado"
				r.last_attacker = break_by
	main.dust(center)
	main.break_crate(center)

## Alguém caiu (by = quem derrubou, -1 se ninguém).
func on_knockout(by: int, victim: int) -> void:
	if victim == bomb_holder:
		bomb_holder = -1
		bomb_next = 1.5

## Antes de eliminar: na Derruba, quem ainda tem vida volta pelo guindaste. true = não elimina.
func intercept_kill(r) -> bool:
	if main.sandbox:
		Audio.play("eliminado", 1.2, -4.0)
		main.dust(r.position + Vector2(0, -30), 1.2)
		r.dmg = 0.0
		respawn(r)
		return true   # no Laboratório ninguém sai
	if rule() == "fuga":
		if r.caught:
			return false   # a tela (ou a lama) pegou: está fora
		main.float_text(r.position + Vector2(0, -90), "VOLTOU LÁ ATRÁS!", main.player_color(r.pid))
	elif rule() == "rei":
		if r.pid == king:
			_drop_crown(Vector2.ZERO, true)   # caiu com o capacete: ele volta para o trono
	elif rule() != "derruba":
		return false
	else:
		lives[r.pid] = lives.get(r.pid, 1) - 1
		if lives[r.pid] <= 0:
			if not r.pid in ordem_elim:
				ordem_elim.append(r.pid)
			return false
		main.float_text(r.position + Vector2(0, -90), "-1 VIDA", main.player_color(r.pid))
	if not r.get_meta("ko_fora", false):   # KO fora da arena: só a explosão (main.ko_blast)
		Audio.play("eliminado", 1.2, -4.0)
	r.remove_meta("ko_fora")
	main.dust(r.position + Vector2(0, -30), 1.2)
	r.dmg = 0.0
	respawn(r)
	return true

## Rei da Obra: capacete de ouro no trono ("K" no mapa; sem K, no alto do centro).
func _reset_crown() -> void:
	king = -1
	king_time.clear()
	crown_cd.clear()
	king_hit.clear()
	var lv = main.level
	crown_home = (lv.throne if lv.throne != Vector2.INF else Vector2(lv.cols * 32.0, 3 * 64.0)) + Vector2(0, -4)
	crown_pos = crown_home
	crown_vel = Vector2.ZERO

func king_goal() -> float:
	return float(KING_GOALS[clampi(king_setting, 0, KING_GOALS.size() - 1)])

## O rei perde o capacete: ele voa (ou volta para o trono, se o rei caiu no poço).
func _drop_crown(vel: Vector2, home := false) -> void:
	if king >= 0 and king < main.robots.size():
		var kr = main.robots[king]
		kr.speed_k = 1.0
		crown_cd[king] = 1.0
		crown_pos = kr.rect().get_center() + Vector2(0, -40)
	king = -1
	crown_vel = vel
	if home:
		crown_pos = crown_home
		crown_vel = Vector2.ZERO
	Audio.play("bonk", 0.8)

## Devolve o vencedor quando alguém junta os segundos; senão -1.
func _update_king(dt: float, alive: Array) -> int:
	if rule() != "rei" or main.countdown > 0.0:
		return -1
	for k in crown_cd.keys():
		crown_cd[k] = maxf(crown_cd[k] - dt, 0.0)
	if king >= 0:
		var kr = main.robots[king]
		if not kr.alive:
			_drop_crown(Vector2.ZERO, true)
			return -1
		king_grace = maxf(king_grace - dt, 0.0)
		# levou golpe (marretada, pisão, explosão): o capacete voa para longe do golpe
		if king_grace <= 0.0 and kr.last_hit < float(king_hit.get(king, 99.0)) and kr.last_hit < 0.1:
			var away: float = -1.0 if kr.velocity.x < 0.0 else 1.0
			_drop_crown(Vector2(away * 260.0, -620.0))
			main.float_text(kr.position + Vector2(0, -110), "PERDEU A COROA!", main.player_color(kr.pid))
			return -1
		king_hit[king] = kr.last_hit
		kr.speed_k = float(sub.get("lento", 0.85))
		var before: float = king_time.get(king, 0.0)
		king_time[king] = before + dt
		if int(before) != int(king_time[king]) and int(king_time[king]) >= int(king_goal()) - 5:
			Audio.play("contagem", 1.2)
		crown_pos = kr.rect().get_center() + Vector2(0, -70)
		if king_time[king] >= king_goal():
			return king
		return -1
	# capacete solto: cai até o chão; quem encostar pega
	var lv = main.level
	crown_vel.y = minf(crown_vel.y + 1800.0 * dt, 900.0)
	crown_vel.x = move_toward(crown_vel.x, 0.0, 200.0 * dt)
	var np := crown_pos + crown_vel * dt
	var below := Vector2i(int(np.x / 64.0), int((np.y + 4.0) / 64.0))
	if crown_vel.y > 0.0 and lv.is_solid(below) and lv.ch_at(below) != "I":
		np.y = below.y * 64.0 - 4.0
		crown_vel = Vector2.ZERO
	if lv.is_solid(Vector2i(int(np.x / 64.0), int((np.y - 10.0) / 64.0))):
		crown_vel.x = -crown_vel.x * 0.5
		np.x = crown_pos.x
	crown_pos = np
	# caiu em espinho, água, lama ou no fundo do mapa: volta para o trono (senão ninguém consegue pegar)
	var here := Vector2i(int(crown_pos.x / 64.0), int((crown_pos.y + 8.0) / 64.0))
	var bad: bool = lv.ch_at(here) in ["^", "w"] or crown_pos.y >= (lv.rows - 1) * 64.0 - 2.0 \
		or crown_pos.x < 0.0 or crown_pos.x > lv.cols * 64.0
	for h in lv.hazard_rects:
		if h.grow(6).has_point(crown_pos):
			bad = true
	if fx != null and is_instance_valid(fx) and fx.goo_on and crown_pos.y > fx.goo_y - 10.0:
		bad = true
	if bad:
		crown_pos = crown_home
		crown_vel = Vector2.ZERO
		main.dust(crown_home, 0.8)
	for r in alive:
		if crown_cd.get(r.pid, 0.0) <= 0.0 and r.rect().grow(10).has_point(crown_pos):
			king = r.pid
			king_hit[king] = r.last_hit
			king_grace = float(sub.get("protecao_s", 1.2))
			banner = "P%d  É O REI DA OBRA!" % (r.pid + 1)
			banner_t = 1.4
			Audio.play("item")
			break
	return -1

## Batata-Dinamite (pavio, passar com a marreta, explosão).
func _update_bomb(dt: float, alive: Array) -> void:
	if rule() != "batata":
		return
	bomb_pass_cd = maxf(bomb_pass_cd - dt, 0.0)
	if bomb_holder < 0:
		bomb_next -= dt
		if bomb_next <= 0.0 and alive.size() > 1:
			var r = alive[main.rng.randi() % alive.size()]
			var pv: Array = FUSES[clampi(fuse_setting, 0, FUSES.size() - 1)]
			bomb_holder = r.pid
			bomb_fuse = main.rng.randf_range(float(pv[0]), float(pv[1]))
			banner = "P%d  ESTÁ COM A DINAMITE!" % (r.pid + 1)
			banner_t = 1.6
			Audio.play("arremesso")
		return
	var holder = main.robots[bomb_holder]
	if not holder.alive:
		bomb_holder = -1
		bomb_next = 1.5
		return
	# encostar no rival também passa a dinamite (com uma folguinha para não voltar na hora)
	if bomb_pass_cd <= 0.0:
		var hr: Rect2 = holder.rect()
		for o in alive:
			if o != holder and o.invuln <= 0.0 and hr.intersects(o.rect()):
				pass_bomb(holder.pid, o.pid)
				break
	bomb_fuse -= dt
	bomb_beep -= dt
	if bomb_beep <= 0.0:
		bomb_beep = clampf(bomb_fuse / 6.0, 0.12, 1.0)
		Audio.play("contagem", 1.0 + clampf(3.0 - bomb_fuse, 0.0, 3.0) * 0.15, -6.0)
	if bomb_fuse <= 0.0:
		var pos: Vector2 = holder.rect().get_center()
		holder.last_cause = "dinamite"
		holder.last_attacker = -1
		holder.last_hit = 0.0
		bomb_holder = -1
		bomb_next = 2.5
		explode(pos, float(sub["raio"]))
		main.kill(holder, -1, null)

## Mapa vivo (Batata/Rei): de tempos em tempos as alavancas se acionam sozinhas, com aviso antes.
var auto_lever_t := 12.0
func _update_auto_lever(dt: float) -> void:
	var every := float(sub.get("alavanca_auto_s", 0.0))
	if every <= 0.0 or fx == null or not is_instance_valid(fx) or fx.levers.is_empty() or main.countdown > 0.0:
		return
	var before := auto_lever_t
	auto_lever_t -= dt
	if before > 1.5 and auto_lever_t <= 1.5:
		for lvr in fx.levers:   # aviso: "!" piscando em cima de cada alavanca
			main.float_text(Vector2(lvr["cell"] * 64) + Vector2(32, -40), "!", Color("#ffcf3a"))
		Audio.play("alarme", 1.2, -6.0)
	if auto_lever_t <= 0.0:
		auto_lever_t = every * main.rng.randf_range(0.8, 1.2)
		fx.pull_lever(-1)
		Audio.play("alavanca")

## Batata: a marretada passa a dinamite para quem levou o golpe.
func pass_bomb(from_pid: int, to_pid: int) -> void:
	if rule() != "batata" or from_pid != bomb_holder or bomb_pass_cd > 0.0:
		return
	bomb_holder = to_pid
	bomb_pass_cd = 0.8
	main.float_text(main.robots[to_pid].position + Vector2(0, -110), "TOMA!", main.player_color(from_pid))
	Audio.play("arremesso", 1.3)

## Fim da rodada: estrela para o vencedor; partida acaba em rounds_to_win.
func end_round() -> bool:
	if round_winner >= 0:
		main.players[round_winner]["score"] += 1
	if partida_unica():
		return true   # uma luta só: vai direto para os resultados
	return round_winner >= 0 and main.players[round_winner]["score"] >= int(c("rounds_to_win"))
