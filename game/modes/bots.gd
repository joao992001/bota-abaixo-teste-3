extends Node
## Bots do Modo Festa (Demolição). Cada bot é um jogador com dispositivo virtual "botN": o cérebro
## escreve os botões em PlayerInput.virtual, então o robô do bot usa exatamente o mesmo controle dos humanos.
## Prioridades: fugir de dinamite > sair de caixote rachando > atacar de perto > arremessar dinamite >
## pegar item > ir até o rival (pulando buracos com segurança). Dificuldade em data/modos.json ("bots").

const LEVELS := ["facil", "medio", "dificil"]
const LEVEL_NAMES := ["fácil", "médio", "difícil"]
var main: Node
var cfg: Dictionary
var state := {}      # dev -> {think, cmd, jump_hold, pulse_hammer, pulse_item, last_pos, stuck}

func setup(m: Node) -> void:
	main = m
	cfg = Data.read_json("data/modos.json")["bots"]

func reset() -> void:
	state.clear()

func update(dt: float) -> void:
	for p in main.players:
		if not p.get("bot", false):
			continue
		var dev: String = p["dev"]
		var r = _robot_of(dev)
		if r == null or not r.alive or not r.active or main.state != main.S.RUN:
			PlayerInput.virtual[dev] = {}
			continue
		var st: Dictionary = state.get(dev, {"think": 0.0, "cmd": {}, "jump_hold": 0, "pulse_hammer": false, "pulse_item": false,
			"last_pos": r.position, "stuck": 0.0})
		state[dev] = st
		var lv: Dictionary = cfg[LEVELS[p.get("level", 1)]]
		st["think"] -= dt
		st["hammer_cd"] = st.get("hammer_cd", 0.0) - dt
		if st["think"] <= 0.0 and r.is_on_floor() and r.stun_t <= 0.0 and main.rng.randf() < float(lv.get("pausa", 0.0)) and not main.danger_near(r):
			# respira: fica parado um pouco (ritmo humano; bots acelerados demais — avaliação 2026-11-26)
			var ps: Array = lv.get("pausa_s", [0.4, 0.9])
			st["think"] = main.rng.randf_range(float(ps[0]), float(ps[1]))
			st["cmd"] = {}
			st["pulse_hammer"] = false
			st["pulse_heavy"] = false
			st["pulse_dodge"] = false
			st["pulse_item"] = false
		elif st["think"] <= 0.0:
			st["think"] = float(lv["react_s"]) * main.rng.randf_range(0.8, 1.4)
			st["cmd"] = _decide(r, lv, st)
			if st["cmd"].get("jump", false) and st["jump_hold"] <= 0 and r.is_on_floor():
				st["jump_hold"] = st["cmd"].get("jump_frames", 14)
			st["pulse_hammer"] = st["cmd"].get("hammer", false)
			st["pulse_heavy"] = st["cmd"].get("heavy", false)
			st["pulse_dodge"] = st["cmd"].get("dodge", false)
			st["pulse_item"] = st["cmd"].get("item", false)
		var cmd: Dictionary = st["cmd"]
		if r.is_on_floor() and not cmd.get("distracted", false) and r.fall_reason == "distraído":
			r.fall_reason = ""
		# segurança a cada quadro (a decisão pode ter sido tomada no ar)
		if r.is_on_floor() and cmd.get("dir", 0) != 0 and not cmd.get("distracted", false):
			var chk := _safe(r, {"dir": cmd["dir"]}, lv, false)
			if chk.get("dir", 0) == 0:
				cmd = cmd.duplicate()
				cmd["dir"] = 0
			elif chk.get("jump", false) and (st["jump_hold"] <= 0 or PlayerInput.virtual.get(dev, {}).get("jump", false)):
				# ainda segurando o pulo anterior: solta 1 quadro para o novo pulo valer
				st["release"] = PlayerInput.virtual.get(dev, {}).get("jump", false)
				st["jump_hold"] = chk.get("jump_frames", 16)
				cmd = cmd.duplicate()
				cmd["jump_frames"] = st["jump_hold"]
				cmd["land"] = chk.get("land", Vector2i(-9, -9))
		# preso: querendo andar (depois da checagem de segurança) sem sair do lugar, ex.: degrau
		if r.position.distance_to(st["last_pos"]) < 1.0 and cmd.get("dir", 0) != 0:
			st["stuck"] += dt
		else:
			st["stuck"] = 0.0
		st["last_pos"] = r.position
		if st["stuck"] > 0.6 and r.is_on_floor():
			st["jump_hold"] = 14
			st["stuck"] = 0.0
		if OS.has_environment("BOT_DEBUG"):
			var was: bool = st.get("was_floor", true)
			if r.is_on_floor():
				st["floor_y"] = r.position.y
			if was and not r.is_on_floor():
				var rowd := int((float(st.get("floor_y", r.position.y)) + 2.0) / 64.0)
				var cl := ""
				for dc in range(-3, 4):
					cl += "#" if main.level.is_solid(Vector2i(int(r.position.x / 64.0) + dc, rowd)) else "."
				cl += " linha=%d" % rowd
				r.set_meta("takeoff", "x=%.0f col=%d vx=%.0f vy=%.0f chão[-3..3]=%s cmd=%s" % [r.position.x, int(r.position.x / 64.0), r.velocity.x, r.velocity.y, cl, str(cmd)])
			if was and not r.is_on_floor() and r.velocity.y >= 0.0 and r.last_hit > 2.0:
				var row := int((r.position.y + 2.0) / 64.0)
				var cells := ""
				for dc in range(-2, 3):
					cells += "#" if main.level.is_solid(Vector2i(int(r.position.x / 64.0) + dc, row)) else "."
				print("    SAIU DO CHÃO P%d x=%.0f vx=%.0f cmd=%s chão[-2..2]=%s stun=%.2f" % [r.pid + 1, r.position.x, r.velocity.x, str(cmd), cells, r.stun_t])
			st["was_floor"] = r.is_on_floor()
		var inp := {}
		var dir: int = cmd.get("dir", 0)
		if dir < 0:
			inp["left"] = true
		elif dir > 0:
			inp["right"] = true
		if cmd.get("down", false):
			inp["down"] = true
		if cmd.get("up", false):
			inp["up"] = true
		var prev: Dictionary = PlayerInput.virtual.get(dev, {})
		if st.get("release", false):
			st["release"] = false   # solta agora; aperta no próximo quadro
		elif st["jump_hold"] > 0:
			inp["jump"] = not (prev.get("jump", false) and st["jump_hold"] == cmd.get("jump_frames", 14))
			st["jump_hold"] -= 1
		# marreta e item: um quadro apertado (borda), depois solta
		if st["pulse_hammer"] and not prev.get("hammer", false):
			inp["hammer"] = true
			st["pulse_hammer"] = false
		if st.get("pulse_heavy", false) and not prev.get("heavy", false):
			inp["heavy"] = true
			st["pulse_heavy"] = false
		if st.get("pulse_dodge", false) and not prev.get("dodge", false):
			inp["dodge"] = true
			st["pulse_dodge"] = false
		if st["pulse_item"] and not prev.get("item", false):
			inp["item"] = true
			st["pulse_item"] = false
		_recover(r, st, inp, prev, dt)
		PlayerInput.virtual[dev] = inp

func demo_canteiro():
	var c = main.demo.canteiro if main.demo != null else null
	return c if c != null and is_instance_valid(c) else null

func _robot_of(dev: String):
	var i: int = PlayerInput.slots.find(dev)
	if i < 0 or i >= main.robots.size():
		return null
	return main.robots[i]

func _decide(r, lv: Dictionary, st: Dictionary) -> Dictionary:
	if r.drop_t > 0.0 and not r.is_on_floor():
		return {"dir": 0}   # descendo pendurado no guindaste (renascimento): espera pousar
	var L = main.level
	var demo = main.demo
	var pos: Vector2 = r.position
	var center: Vector2 = r.rect().get_center()
	var row := int((pos.y + 2.0) / 64.0)
	var col := int(pos.x / 64.0)
	var cmd := {"dir": 0}
	var sp = demo.spells
	var mine: String = sp.slot[r.pid]["id"] if sp != null and sp.slot.has(r.pid) else ""
	if mine in ["E01", "C04"] and not r.is_on_floor() and r.velocity.y > 250.0 and pos.y > 64.0 * (L.rows - 5):
		cmd["item"] = true   # caindo no buraco: andaime embaixo dos pés / teleporte para cima
		cmd["up"] = mine == "C04"
		return cmd
	# 1b) máquinas da arena (chama, pistão, serra, barril): sair de perto ou pular por cima
	var fx0 = demo.fx
	if fx0 != null and is_instance_valid(fx0):
		var hz: Vector2 = fx0.hazard_near(center, 110.0)
		if hz != Vector2.INF:
			cmd["dir"] = 1 if center.x >= hz.x else -1
			if hz.y > center.y - 10.0 and absf(hz.x - center.x) < 90.0:
				cmd["jump"] = true
			return _safe(r, cmd, lv)
		# alavanca ao alcance e rival em cima do alçapão: marreta a alavanca
		for lvr in fx0.levers:
			var lc: Vector2 = Vector2(lvr["cell"] * 64) + Vector2(32, 32)
			if absf(lc.x - pos.x) < 90.0 and absf(lc.y - center.y) < 60.0 and fx0.traps_open_t <= 0.0 and fx0.someone_on_traps(r):
				var want := 1 if lc.x > pos.x else -1
				if want != r.facing:
					cmd["dir"] = want
				elif st.get("hammer_cd", 0.0) <= 0.0:
					cmd["hammer"] = true
					st["hammer_cd"] = float(lv["hammer_cooldown_s"])
				return cmd
	# 1b) Canteiro: o trecho/andaime embaixo está marcado para cair (aviso do ciclo ou crítico): correr para o núcleo
	var ct = demo.canteiro
	if ct != null and is_instance_valid(ct):
		var under_c := Vector2i(int(pos.x / 64.0), int((pos.y + 6.0) / 64.0))
		if ct.owner_of.has(under_c):
			var part: Dictionary = ct.owner_of[under_c]
			if part["warn_t"] > 0.0 or part["crit_t"] > 0.0 or (part["state"] == 2 and part["kind"] != "laje"):
				cmd["dir"] = 1 if pos.x < 20.0 * 64.0 else -1
				if part["kind"] != "laje":
					cmd["jump"] = true
				return _safe(r, cmd, lv)
	# 2) caixote embaixo rachando / tremendo: sair dele
	var under := Vector2i(col, row)
	if r.is_on_floor() and L.blocks.has(under):
		var b: Dictionary = L.blocks[under]
		# foge 2 s antes de quebrar (com os valores padrão = 80% do tempo de rachar; sem quebra, não foge à toa)
		if b["warn"] > 0.0 or b["load"] > float(demo.cfg["crumble_break_s"]) - 2.0:
			for dc in [1, -1, 2, -2, 3, -3]:
				var c2 := Vector2i(col + dc, row)
				if L.is_solid(c2) and not (L.blocks.has(c2) and L.blocks[c2]["warn"] > 0.0):
					cmd["dir"] = signi(dc)
					return _safe(r, cmd, lv)
	# 2b) maré de lama chegando: subir para o caixote mais alto alcançável
	var fx = demo.fx
	var climb: bool = fx != null and is_instance_valid(fx) and fx.goo_on and fx.goo_y - pos.y < 330.0
	if fx != null and is_instance_valid(fx) and fx.scroll_on and fx.scroll_dir == "cima" and pos.y > fx.scroll_center.y + 120.0:
		climb = true   # Torre: a câmera sobe, não pode ficar para trás
	if fx != null and is_instance_valid(fx) and fx.scroll_on and fx.scroll_dir != "cima" and pos.x < fx.scroll_center.x - 380.0:
		cmd["dir"] = 1   # Ponte: a câmera avança, segue em frente
		return _safe(r, cmd, lv)
	if climb and r.is_on_floor():
		var best := Vector2i(-1, -1)
		for dr in range(1, 5):
			for dc in range(-7, 8):
				var cc := Vector2i(col + dc, row - dr)
				if L.is_solid(cc) and not L.is_solid(cc + Vector2i.UP) and not L.is_solid(cc + Vector2i(0, -2)):
					if best.x < 0 or absi(dc) < absi(best.x - col):
						best = cc
			if best.x >= 0:
				break
		if best.x >= 0:
			var gx := best.x * 64 + 32 - pos.x
			cmd["dir"] = signi(int(gx)) if absf(gx) > 20.0 else 0
			if absf(gx) < 150.0:
				cmd["jump"] = true
				cmd["jump_frames"] = 16
			return _safe(r, cmd, lv)
	# 2) Batata-Dinamite: sem a bomba, foge de quem está com ela; com ela, persegue o mais perto (encostar passa)
	var bomb_on: bool = demo.rule() == "batata" and demo.bomb_holder >= 0 and demo.bomb_holder < main.robots.size()
	var holder = main.robots[demo.bomb_holder] if bomb_on else null
	if holder != null and holder != r and holder.alive and holder.position.distance_to(pos) < 380.0:
		cmd["dir"] = 1 if pos.x >= holder.position.x else -1
		if absf(holder.position.x - pos.x) < 170.0 and r.is_on_floor():
			cmd["jump"] = true
			cmd["jump_frames"] = 16
		return _safe(r, cmd, lv)
	# 2b) Rei da Obra: o rei foge de quem chega perto; os outros vão atrás do rei ou do capacete solto
	if demo.rule() == "rei":
		if demo.king == r.pid:
			var near = null
			var nd := 1e9
			for o in main.robots:
				if o != r and o.alive and o.position.distance_to(pos) < nd:
					nd = o.position.distance_to(pos)
					near = o
			if near != null and nd < 300.0:
				cmd["dir"] = 1 if pos.x >= near.position.x else -1
				if absf(near.position.x - pos.x) < 150.0 and r.is_on_floor():
					cmd["jump"] = true
					cmd["jump_frames"] = 16
				return _safe(r, cmd, lv)
			return cmd
		if demo.king < 0:
			return _climb(r, demo.crown_pos, lv)
		var kr = main.robots[demo.king]
		if kr.position.y < pos.y - 110.0:
			return _climb(r, kr.position, lv)   # o rei está lá em cima: sobe degrau por degrau
	# 2c) Fuga: corre para o elevador; só briga com quem estiver colado
	if demo.rule() == "fuga" and L.elevator_cell != Vector2i(-1, -1):
		var g: Rect2 = L.goal_rect
		var run := _climb(r, Vector2(g.get_center().x, g.end.y), lv)
		for o in main.robots:
			if o != r and o.alive and absf(o.position.x - pos.x) < 78.0 and absf(o.position.y - pos.y) < 50.0 \
					and signi(int(o.position.x - pos.x)) == r.facing and st.get("hammer_cd", 0.0) <= 0.0 \
					and main.rng.randf() < float(lv["hammer_acc"]) * 0.5:
				run["hammer"] = true   # marretada de passagem, sem parar de correr
				st["hammer_cd"] = float(lv["hammer_cooldown_s"]) * 1.5
		return run
	# alvo: rival mais perto (na Batata, ninguém vai atrás de quem está com a bomba; no Rei, todos vão no rei)
	var target = null
	var td := 1e9
	for o in main.robots:
		if o != r and o.alive and not o.finished and not (holder != null and o == holder and r != holder) \
				and (demo.rule() != "rei" or demo.king < 0 or o.pid == demo.king):
			var dd: float = o.position.distance_to(pos)
			if dd < td:
				td = dd
				target = o
	if target == null:
		return cmd
	var dx: float = target.position.x - pos.x
	var dy: float = target.position.y - pos.y
	var dc6 = demo.spells.decoy_of(target.pid) if demo.spells != null else null
	if dc6 != null:   # D06: o boneco de teste é a isca — o bot vai nele
		dx = dc6.x - pos.x
		dy = dc6.y - pos.y
	# 3a) rival preparando a marretada pesada virado para mim: esquiva para longe (bots melhores fazem mais)
	if absf(dx) < 130.0 and absf(dy) < 60.0 and target.atk == "pesado" and not target.atk_hit \
			and signi(int(-dx)) == target.facing and r.dodge_cd <= 0.0 and main.rng.randf() < float(lv["hammer_acc"]) * 0.7:
		cmd["dodge"] = true
		cmd["dir"] = -signi(int(dx)) if dx != 0.0 else -r.facing
		return _safe(r, cmd, lv)
	# 3) atacar de perto: golpe rápido na maioria; marretada pesada quando o rival já está amassado
	if absf(dx) < 78.0 and absf(dy) < 50.0:
		if signi(int(dx)) != r.facing and absf(dx) > 4.0:
			cmd["dir"] = signi(int(dx))   # vira para o rival
		# acertou o golpe rápido: continua a sequência (até o 3º, que arremessa) sem esperar a recarga
		if (r.atk == "rapido" and r.atk_landed and r.combo_i < 2) or (r.atk == "" and r.combo_t > 0.0 and r.combo_i < 2):
			if float(lv["hammer_acc"]) >= 0.5:   # bots médio/difícil continuam a sequência (sem sorteio: comportamento previsível)
				cmd["hammer"] = true
				return _safe(r, cmd, lv)
		if main.rng.randf() < float(lv["hammer_acc"]) and st.get("hammer_cd", 0.0) <= 0.0:
			# rival bem amassado + marreta pronta: bots bons finalizam com a pesada
			var heavy: bool = r.heavy_cd <= 0.0 and ((target.dmg > 60.0 and main.rng.randf() < 0.35 + 0.6 * float(lv["hammer_acc"])) or main.rng.randf() < 0.12)
			cmd["heavy" if heavy else "hammer"] = true
			st["hammer_cd"] = float(lv["hammer_cooldown_s"]) * (1.6 if heavy else 1.0)
		return _safe(r, cmd, lv)
	# 4) spells: cada uma tem sua hora
	var it_ok := false
	match mine:
		"A01": it_ok = absf(dy) < 50.0 and absf(dx) > 70.0 and absf(dx) < 240.0
		"A03": it_ok = absf(dy) < 40.0 and absf(dx) > 90.0 and absf(dx) < 900.0
		"C01": it_ok = absf(dy) < 90.0 and absf(dx) > 120.0 and absf(dx) < 300.0
		"T01": it_ok = absf(dy) < 60.0 and absf(dx) < 150.0
		"A02": it_ok = absf(dy) < 30.0 and absf(dx) > 120.0 and absf(dx) < 800.0
		"A04": it_ok = r.is_on_floor() and target.is_on_floor() and absf(dy) < 8.0 and absf(dx) < 280.0
		"A05": it_ok = absf(dy) < 40.0 and absf(dx) > 80.0 and absf(dx) < 600.0
		"A06": it_ok = absf(absf(dx) - 166.0) < 40.0 and absf(dy) < 90.0
		"A07": it_ok = absf(dy) < 70.0 and absf(dx) > 90.0 and absf(dx) < 300.0
		"A08": it_ok = absf(dy) < 60.0 and absf(dx) > 100.0 and absf(dx) < 420.0
		"C02": it_ok = absf(dy) < 60.0 and absf(dx) < 320.0
		"T02": it_ok = absf(dy) < 40.0 and absf(dx) < 140.0
		"T03": it_ok = sp.slot[r.pid]["t"] < 0.0 and absf(dx) < 500.0
		"T04": it_ok = not r.is_on_floor() and r.velocity.y > 200.0
		"T05": it_ok = sp.slot[r.pid]["t"] < 0.0 and absf(dy) < 40.0 and absf(dx) < 220.0
		"T06": it_ok = absf(dy) < 40.0 and absf(dx) < 120.0
		"T07":   # A36: vira o mecha Corredor; já montado, ARRANCADA quando o rival está na frente, na mesma altura
			it_ok = (sp.slot[r.pid]["t"] < 0.0 and absf(dx) < 420.0) or (sp.slot[r.pid]["t"] > 0.0 and absf(dy) < 40.0 and absf(dx) < 460.0 and signf(dx) == float(r.facing))
		"C03": it_ok = absf(dy) < 40.0 and absf(dx) > 120.0 and absf(dx) < 480.0
		"D01": it_ok = r.is_on_floor() and sp.slot[r.pid]["t"] < 0.0 and absf(dy) < 60.0 and absf(dx) < 170.0   # Defesa: ancora quando o rival chega perto
		"D02": it_ok = false   # passivo
		"D03": it_ok = sp.slot[r.pid]["t"] < 0.0 and absf(dy) < 60.0 and absf(dx) < 130.0 and target.atk != ""   # rival atacando perto
		"D04": it_ok = sp.slot[r.pid]["t"] < 0.0 and absf(dx) < 160.0 and r.dmg > 60.0   # machucado e cercado
		"D05": it_ok = sp.slot[r.pid]["t"] < 0.0 and absf(dx) < 220.0
		"D06": it_ok = absf(dx) < 140.0 and absf(dy) < 60.0
		"C05": it_ok = absf(dy) < 50.0 and absf(dx) > 100.0 and absf(dx) < 400.0
		"E03":
			var tg = sp.remote_target(r)
			it_ok = tg != null and target.position.x > tg["rect"].position.x and target.position.x < tg["rect"].end.x and target.position.y > tg["rect"].position.y
		"E02":
			var mine_c = null
			for ch in sp.charges_placed:
				if ch["owner"] == r.pid:
					mine_c = ch
			if mine_c == null:
				it_ok = absf(dx) < 100.0 and absf(dy) < 40.0
			else:
				it_ok = mine_c["armed"] and target.rect().get_center().distance_to(mine_c["pos"]) < 130.0 and r.position.distance_to(mine_c["pos"]) > 150.0
	if it_ok and main.rng.randf() < float(lv["use_items"]):
		if signi(int(dx)) != r.facing:
			cmd["dir"] = signi(int(dx))
		else:
			cmd["item"] = true
		return cmd
	# 5) slot vazio: vai pegar a caixa se estiver mais perto que o rival
	var goal: Vector2 = target.position
	if sp != null and mine == "":
		for b in sp.boxes:
			if b["vy"] == 0.0 and not b["block"].has(r.pid) and b["pos"].distance_to(pos) < td * 1.2 and main.rng.randf() < float(lv["use_items"]):
				goal = b["pos"] + Vector2(0, 26)
				break
	st["alvo_abaixo"] = goal.y > pos.y + 90.0
	# 6) rival em outro andar: segue o caminho de degraus, subindo ou descendo
	#    (andar em linha reta parava na beirada e o bot ficava travado)
	if absf(goal.y - pos.y) > 90.0:
		return _climb(r, goal, lv)
	var gx := goal.x - pos.x
	if absf(gx) > 20.0:
		cmd["dir"] = signi(int(gx))
	if goal.y < pos.y - 90.0 and r.is_on_floor() and absf(gx) < 260.0:
		cmd["jump"] = true
		cmd["jump_frames"] = 16
	return _safe(r, cmd, lv)

## Caminho até o objetivo: distância (em pulos) de cada degrau até o degrau do objetivo, calculada de trás
## para a frente e guardada enquanto o objetivo não muda de célula. Devolve o próximo degrau (ou -1).
var _nav := {"lv": null, "goal": Vector2i(-99, -99), "dist": {}, "t": 0.0}

func _standable(L, c: Vector2i) -> bool:
	var ch: String = L.ch_at(c)
	return (L.is_solid(c) or ch == "=") and ch != "I" and not L.is_solid(c + Vector2i.UP) and not L.is_solid(c + Vector2i(0, -2))

func _reach(L, a: Vector2i, b: Vector2i) -> bool:
	var dx := absi(b.x - a.x)
	var up := a.y - b.y
	var hmax := 6 if L.ch_at(a) == "J" else 3
	if up > hmax or dx > (3 if up > 0 else 5):
		return false
	var sx := signi(b.x - a.x)
	if up > 0:   # sobe na coluna de saída e depois atravessa na altura de chegada
		for y in range(b.y - 2, a.y):
			if L.is_solid(Vector2i(a.x, y)):
				return false
		for x in range(a.x, b.x + sx, sx if sx != 0 else 1):
			if L.is_solid(Vector2i(x, b.y - 1)) or L.is_solid(Vector2i(x, b.y - 2)):
				return false
		return true
	for x in range(a.x, b.x + sx, sx if sx != 0 else 1):   # atravessa na altura de saída e depois cai
		if L.is_solid(Vector2i(x, a.y - 1)):
			return false
	for y in range(a.y - 1, b.y):
		if L.is_solid(Vector2i(b.x, y)):
			return false
	return true

## Sair andando para a coluna c é seguro? Chão na mesma altura (e sem parede) ou um vão cujo primeiro piso embaixo dá para
## ficar em pé (nunca espinho, água ou o fundo do mapa).
func _queda_segura(L, c: int, row: int) -> bool:
	if L.is_solid(Vector2i(c, row)):
		return not L.is_solid(Vector2i(c, row - 1))
	for y in range(row + 1, L.rows):
		var cc := Vector2i(c, y)
		if L.is_solid(cc) or L.ch_at(cc) == "=":
			return _standable(L, cc) and not L.ch_at(cc) in ["^", "w"] and y < L.rows - 1
	return false

func _goal_cell(L, goal: Vector2) -> Vector2i:
	var gx := int(goal.x / 64.0)
	var gy := int((goal.y + 2.0) / 64.0)
	for k in 4:
		if _standable(L, Vector2i(gx, gy + k)):
			return Vector2i(gx, gy + k)
	return Vector2i(-1, -1)

func _nav_step(from: Vector2i, goal: Vector2) -> Vector2i:
	var L = main.level
	var g := _goal_cell(L, goal)
	if g.x < 0 or not _standable(L, from):
		return Vector2i(-1, -1)
	var now := Time.get_ticks_msec() / 1000.0
	if _nav["lv"] != L or (_nav["goal"] != g and now - float(_nav["t"]) > 0.5):
		var ok := {}
		for y in range(1, L.rows):
			for x in range(1, L.cols - 1):
				if _standable(L, Vector2i(x, y)):
					ok[Vector2i(x, y)] = true
		var dist := {g: 0}
		var queue: Array = [g]
		var qi := 0
		while qi < queue.size():
			var b: Vector2i = queue[qi]
			qi += 1
			for y in range(b.y - 8, b.y + 7):   # quem chega em b: até 6 abaixo (trampolim) ou caindo de até 8 acima
				for x in range(b.x - 5, b.x + 6):
					var a := Vector2i(x, y)
					if ok.has(a) and not dist.has(a) and _reach(L, a, b):
						dist[a] = int(dist[b]) + 1
						queue.append(a)
		_nav = {"lv": L, "goal": g, "dist": dist, "t": now}
	var d: Dictionary = _nav["dist"]
	if not d.has(from) or int(d[from]) == 0:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var bk := 1e9
	for y in range(from.y - 6, from.y + 9):
		for x in range(from.x - 5, from.x + 6):
			var c := Vector2i(x, y)
			if c != from and d.has(c) and _reach(L, from, c):
				var k := float(d[c]) * 100.0 + absi(x - from.x)
				if k < bk:
					bk = k
					best = c
	return best

## Subir até um objetivo no alto: escolhe um degrau (chão com espaço em cima, 1–3 linhas acima e perto)
## que aproxime do objetivo; tábuas dão para atravessar por baixo, blocos sólidos ele pega pela lateral.
func _climb(r, goal: Vector2, lv: Dictionary) -> Dictionary:
	var L = main.level
	var pos: Vector2 = r.position
	var cmd := {"dir": 0}
	var row := int((pos.y + 2.0) / 64.0)
	var col := int(pos.x / 64.0)
	var tx := goal.x
	var nav := _nav_step(Vector2i(col, row), goal)
	if nav.x >= 0 and nav.y >= row:
		# o caminho segue pelo mesmo andar ou desce: anda até lá (cai da beirada se preciso)
		var ndx := nav.x * 64 + 32 - pos.x
		cmd["dir"] = signi(int(ndx)) if absf(ndx) > 12.0 else 0
		if nav.y > row and cmd["dir"] != 0 and r.is_on_floor() and _queda_segura(L, col + int(cmd["dir"]), row):
			return cmd   # o caminho DESCE: sai da beirada e cai no degrau de baixo (a segurança pulava o vão e o bot ficava preso em cima)
		var rs := _safe(r, cmd, lv)
		if cmd["dir"] != 0 and rs.get("dir", 0) == 0:
			rs["dir"] = cmd["dir"]   # o próximo degrau do caminho é chão: segue (e cai, se for para baixo)
			if nav.y == row and not _standable(L, Vector2i(col + int(cmd["dir"]), row)) and r.is_on_floor():
				rs["jump"] = true    # vão no mesmo andar: pula
				rs["jump_frames"] = 16
		return rs
	if goal.y < pos.y - 90.0 or nav.x >= 0:
		var best := nav
		var bs := 1e9
		for dy in range(1, 4 if nav.x < 0 else 1):
			var y := row - dy
			for x in range(col - 5, col + 6):
				var c := Vector2i(x, y)
				var standable: bool = (L.is_solid(c) or L.ch_at(c) == "=") and L.ch_at(c) != "I" \
					and not L.is_solid(c + Vector2i.UP) and not L.is_solid(c + Vector2i(0, -2))
				if not standable:
					continue
				var sc := Vector2(x * 64 + 32, y * 64).distance_to(goal) + absf(x - col) * 24.0
				if sc < bs:
					bs = sc
					best = c
		if best.x >= 0:
			tx = best.x * 64 + 32
			var dx := tx - pos.x
			var solid_step: bool = L.is_solid(best)
			if solid_step and absf(dx) < 50.0:
				cmd["dir"] = -1 if dx >= 0.0 else 1   # embaixo de um bloco: sai para o lado antes de pular
				return _safe(r, cmd, lv)
			cmd["dir"] = signi(int(dx)) if absf(dx) > 12.0 else 0
			if r.is_on_floor() and absf(dx) < (140.0 if solid_step else 110.0):
				cmd["jump"] = true
				cmd["jump_frames"] = 18
			var want: int = cmd["dir"]
			var res := _safe(r, cmd, lv)
			if want != 0 and res.get("dir", 0) == 0 and r.is_on_floor() and absf(dx) < 300.0:
				# a segurança parou na beirada, mas o degrau está em cima e perto: pula para ele
				res["dir"] = want
				res["jump"] = true
				res["jump_frames"] = 18
			return res
	var gx := tx - pos.x
	if absf(gx) > 16.0:
		cmd["dir"] = signi(int(gx))
	if goal.y < pos.y - 70.0 and r.is_on_floor() and absf(gx) < 120.0:
		cmd["jump"] = true
		cmd["jump_frames"] = 16
	return _safe(r, cmd, lv)

## Segurança: olha à frente o quanto o robô anda até a próxima decisão; não entra em buraco sem chão
## alcançável do outro lado (pula vãos, inclusive de 1 caixote, e paredes).
func _safe(r, cmd: Dictionary, lv: Dictionary, may_distract := true) -> Dictionary:
	var L = main.level
	var dir: int = cmd.get("dir", 0)
	if dir == 0 or not r.is_on_floor():
		return cmd
	var row := int((r.position.y + 2.0) / 64.0)
	var look := 30.0 + float(Data.ctrl["max_run"]) * float(lv["react_s"]) * 1.4
	var k := 6.0
	while k <= look:
		var cx := int(floor((r.position.x + dir * (24.0 + k)) / 64.0))
		if L.is_solid(Vector2i(cx, row - 1)):
			cmd["jump"] = true
			return cmd
		var ok: bool = L.is_solid(Vector2i(cx, row)) and not (L.blocks.has(Vector2i(cx, row)) and L.blocks[Vector2i(cx, row)]["warn"] > 0.0)
		if not ok:
			if absf(r.velocity.x) > 120.0 and signf(r.velocity.x) != float(dir):
				# ainda deslizando para o outro lado: espera virar antes de pular
				cmd.erase("jump")
				return cmd
			if k > 40.0:
				# vão ainda longe: continua andando; para só se não houver onde pousar e já estiver perto de frear
				var land_far := _landing(cx - dir, row, dir)
				if land_far == Vector2i(-1, -1) and k < 90.0:
					cmd["dir"] = 0
					cmd.erase("jump")
				return cmd
			if may_distract and absf(r.velocity.x) > 300.0 and signf(r.velocity.x) == float(dir) and main.rng.randf() > float(lv["safety"]):
				cmd["distracted"] = true
				r.fall_reason = "distraído"
				return cmd   # bot fácil às vezes se distrai
			var land := _landing(cx - dir, row, dir)
			if land == Vector2i(-1, -1):
				cmd["dir"] = 0
				cmd.erase("jump")
			else:
				cmd["jump"] = true
				cmd["jump_frames"] = 16
				cmd["land"] = land
			return cmd
		k += 14.0
	return cmd

## Primeiro chão onde dá para aterrissar à frente (até 4 colunas, de 2 acima a 5 abaixo).
func _landing(col: int, row: int, dir: int) -> Vector2i:
	var L = main.level
	for dc in range(1, 5):
		var c := col + dir * dc
		for r2 in range(maxi(row - 2, 1), mini(row + 6, L.rows - 1)):   # só dentro do mapa (fora conta como sólido)
			if L.is_solid(Vector2i(c, r2)) and not L.is_solid(Vector2i(c, r2 - 1)) and not L.is_solid(Vector2i(c, r2 - 2)):
				if not (L.blocks.has(Vector2i(c, r2)) and L.blocks[Vector2i(c, r2)]["warn"] > 0.0):
					return Vector2i(c, r2)
	return Vector2i(-1, -1)

## Recuperação: pendurado na borda → sobe; caindo sobre o vazio → vai para o chão mais próximo e usa o pulo duplo.
func _recover(r, st: Dictionary, inp: Dictionary, prev: Dictionary, dt: float) -> void:
	if r.hanging:
		st["hang_t"] = st.get("hang_t", 0.0) + dt
		inp.erase("left")
		inp.erase("right")
		if st.get("alvo_abaixo", false) and r.stun_t <= 0.0 \
				and _queda_segura(main.level, int(r.position.x / 64.0), int((r.position.y + 2.0) / 64.0)):
			inp["down"] = true   # o alvo está embaixo e há chão logo abaixo: solta a borda e cai (subir de volta o deixava preso em cima)
			inp.erase("jump")
			return
		inp["right" if r.hang_dir > 0 else "left"] = true
		if st["hang_t"] > 0.25:
			inp["jump"] = not prev.get("jump", false)
		return
	st["hang_t"] = 0.0
	if r.is_on_floor() or r.velocity.y < 60.0 or r.stun_t > 0.0:
		return
	var L = main.level
	var col := int(r.position.x / 64.0)
	var row := int((r.position.y + 2.0) / 64.0)
	for k in range(0, 7):
		if L.is_solid(Vector2i(col, row + k)) and L.ch_at(Vector2i(col, row + k)) != "I":
			return   # tem chão embaixo
	var best := Vector2i(-1, -1)
	var bd := 1e9
	for dc in range(-7, 8):
		for dr in range(-3, 5):
			var c := Vector2i(col + dc, row + dr)
			if L.is_solid(c) and L.ch_at(c) != "I" and not L.is_solid(c + Vector2i.UP):
				var d := absf(dc) * 1.0 + maxf(dr, 0) * 0.3
				if d < bd:
					bd = d
					best = c
	if best.x < 0:
		return
	var gx: float = best.x * 64 + 32 - r.position.x
	inp.erase("left")
	inp.erase("right")
	if absf(gx) > 12.0:
		inp["right" if gx > 0 else "left"] = true
	if r.air_jumps > 0 and best.y <= row + 1:
		inp["jump"] = not prev.get("jump", false)
