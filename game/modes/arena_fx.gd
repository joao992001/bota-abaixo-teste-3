extends Node2D
## Mecânicas especiais de cada arena da Demolição, lidas do cabeçalho do .lvl:
##   plataformas: x,y,largura,dx,dy,periodo ; ...   (tiles; plataformas de aço que vão e voltam)
##   mare_inicio / mare_vel / mare_topo             (lama sobe a partir de mare_inicio s, mare_vel tiles/s)
##   bola: pivo_x,pivo_y,comprimento,amplitude_graus,periodo  (bola de demolição em pêndulo)
##   esteira_inverte: segundos                       (esteiras do mapa invertem; aviso 1,2 s antes)
##   rolagem: cima|direita, vel_tiles_s, inicio_s     (câmera que rola; quem fica para trás está fora)
##   gangorras: x,y,largura ; ...                    (tábua que inclina com o peso; x,y = topo do apoio)
##   serras: x1,y,x2,periodo ; ...                    (serra circular num trilho, embutida no chão da linha y)
##   ventilador_ciclo: ligado,desligado · ventilador_alcance: tiles     (F)
##   chama_ciclo: apagada,aviso,acesa                (f)
##   pistao_ciclo: segundos                          (P, no teto: desce e prensa)
##   barril_cada: segundos · barril_vel: tiles/s      (B: calha que solta barris rolando)
##   alcapao_s: segundos aberto                      (L alavanca: marretada abre os alçapões 'a' e abre/fecha as portas 'D')
##   trampolim: velocidade (px/s, padrão 2150 ≈ 6 tiles)       (J: pisou, voa)
##   rolagem baixo                                   (câmera desce; quem fica para cima está fora)
## Tubos de teletransporte: 'Y' e 'Z' (dois de cada letra): entrou num, sai no outro.
## As plataformas são AnimatableBody2D: a física da Godot carrega quem está em cima.

const T := 64
var main: Node
var level: Node
var t := 0.0
var plats: Array = []      # {body, start, delta, period, w, pos}
var goo_y := 99999.0       # altura da lama (y do topo; mundo)
var goo_on := false
var ball := {}             # {pivot, len, amp, period, pos, vel}
var flip_every := 0.0
var flip_t := 0.0
var bubble_t := 0.5
# câmera que rola
var scroll_on := false
var scroll_dir := ""
var scroll_vel := 0.0
var scroll_start := 0.0
var scroll_center := Vector2.ZERO
var scroll_zoom := 1.0
# máquinas
var fans: Array = []       # {cell, rect}
var flames: Array = []     # {cell, rect, off}
var pistons: Array = []    # {cell, max, off, ext, state}
var saws: Array = []       # {x1, x2, y, period, pos, vx}
var chutes: Array = []     # {cell, dir, t}
var barrels: Array = []    # {pos, vx, vy, by, bounces, rot}
var seesaws: Array = []    # {body, pivot, w, ang}
var levers: Array = []     # {cell, ang}
var traps_open_t := 0.0
var pad_t := {}            # trampolim: célula -> tempo da última mola (anima)
var portal_cd := {}        # robô -> espera para usar um tubo de novo
var trap_by := -1
var fan_on := true
var fan_t := 0.0

func setup(m: Node, lv: Node) -> void:
	main = m
	level = lv
	main.bg.modulate = main.bg_tint()
	# plataformas
	var spec: String = lv.prop("plataformas", "")
	for part in spec.split(";", false):
		var v := part.split(",")
		if v.size() < 6:
			continue
		var w := int(v[2])
		var body := AnimatableBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.sync_to_physics = true
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(w * T, 24)
		cs.shape = rs
		cs.position = Vector2(w * T / 2.0, 12)
		body.add_child(cs)
		var start := Vector2(float(v[0]) * T, float(v[1]) * T)
		body.position = start
		add_child(body)
		plats.append({"body": body, "start": start, "delta": Vector2(float(v[3]), float(v[4])) * T, "period": float(v[5]), "w": w})
	_setup_machines(lv)
	if plats.size() > 0 or seesaws.size() > 0:
		lv.extra_solid = Callable(self, "_extra_solid")
	# maré de lama
	if lv.prop("mare_inicio", "") != "":
		goo_on = true
		goo_y = lv.rows * T + 40.0
	# bola de demolição
	var bs: String = lv.prop("bola", "")
	if bs != "":
		var b := bs.split(",")
		ball = {"pivot": Vector2(float(b[0]) * T + T / 2.0, float(b[1]) * T), "len": float(b[2]) * T,
			"amp": deg_to_rad(float(b[3])), "period": float(b[4]), "pos": Vector2.ZERO, "vel": Vector2.ZERO}
		_ball_step(0.0)
	flip_every = float(lv.prop("esteira_inverte", "0"))
	flip_t = flip_every

func _extra_solid(c: Vector2i) -> bool:
	return _cell_on_platform(c) or _cell_on_seesaw(c)

func _setup_machines(lv: Node) -> void:
	# câmera que rola
	var rs: String = lv.prop("rolagem", "")
	if rs != "":
		var v := rs.split(",")
		scroll_dir = v[0].strip_edges()
		scroll_vel = float(v[1]) * T
		scroll_start = float(v[2])
		scroll_on = true
		var lw: float = lv.cols * T
		var lh: float = lv.rows * T
		scroll_center = Vector2(lw / 2.0, lh - 512.0) if scroll_dir == "cima" else (Vector2(lw / 2.0, 512.0) if scroll_dir == "baixo" else Vector2(960.0, lh / 2.0))
	# gangorras
	for part in String(lv.prop("gangorras", "")).split(";", false):
		var g := part.split(",")
		if g.size() < 3:
			continue
		var w := int(g[2])
		var body := AnimatableBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.sync_to_physics = true
		var cs := CollisionShape2D.new()
		var rsh := RectangleShape2D.new()
		rsh.size = Vector2(w * T, 24)
		cs.shape = rsh
		cs.position = Vector2(0, -12)
		body.add_child(cs)
		var pv := Vector2(float(g[0]) * T + T / 2.0, float(g[1]) * T)
		body.position = pv
		add_child(body)
		seesaws.append({"body": body, "pivot": pv, "w": w, "ang": 0.0})
	# serras
	for part in String(lv.prop("serras", "")).split(";", false):
		var sv := part.split(",")
		if sv.size() < 4:
			continue
		saws.append({"x1": float(sv[0]) * T + T / 2.0, "x2": float(sv[2]) * T + T / 2.0, "y": float(sv[1]) * T,
			"period": float(sv[3]), "pos": Vector2.ZERO, "vx": 0.0})
	# máquinas no mapa
	var reach := int(lv.prop("ventilador_alcance", "7"))
	var k := 0
	for y in lv.rows:
		for x in lv.cols:
			var c := Vector2i(x, y)
			match lv.ch_at(c):
				"F":
					var top: int = y
					while top > 0 and y - top < reach and not lv.is_solid(Vector2i(x, top - 1)):
						top -= 1
					fans.append({"cell": c, "rect": Rect2(x * T - 6, top * T, T + 12, (y - top) * T)})
				"f":
					flames.append({"cell": c, "rect": Rect2(x * T + 10, y * T - 2.6 * T, T - 20, 2.6 * T), "off": 0.0 if x % 2 == 0 else 0.5})
				"P":
					var n := 0
					while y + n + 1 < lv.rows - 1 and not (lv.ch_at(Vector2i(x, y + n + 1)) in ["#", "o", "I", "F", "f", "P", "B", "<", ">", "a", "^", "w", "d", "T", "="]):
						n += 1
					pistons.append({"cell": c, "max": n * T, "off": k * 1.4, "ext": 0.0, "state": "", "t": 0.0})
					k += 1
				"B":
					chutes.append({"cell": c, "dir": 1 if x < lv.cols / 2 else -1, "t": 1.5 + chutes.size() * 2.3})
				"L":
					levers.append({"cell": c, "ang": -0.6})

func _cell_on_seesaw(c: Vector2i) -> bool:
	var cc := Vector2(c * T) + Vector2(T / 2.0, T / 2.0)
	for g in seesaws:
		var lp: Vector2 = (cc - g["pivot"]).rotated(-float(g["ang"]))
		if absf(lp.x) <= g["w"] * T / 2.0 and lp.y > -40.0 and lp.y < 20.0:
			return true
	return false

func _cell_on_platform(c: Vector2i) -> bool:
	var cr := Rect2(Vector2(c * T), Vector2(T, T))
	for p in plats:
		var pr := Rect2(p["body"].position, Vector2(p["w"] * T, 24))
		if pr.intersects(cr):
			return true
	return false

## Plataforma embaixo deste ponto (para itens pousarem e andarem junto).
func platform_at(pt: Vector2):
	for p in plats:
		var pr := Rect2(p["body"].position + Vector2(0, -4), Vector2(p["w"] * T, 30))
		if pr.has_point(pt):
			return p
	return null

func update(dt: float, running: bool) -> void:
	t += dt
	for p in plats:
		var k := 0.5 - 0.5 * cos(TAU * t / float(p["period"]))
		p["body"].position = p["start"] + p["delta"] * k
	_update_seesaws(dt)
	if not running:
		queue_redraw()
		return
	_update_scroll(dt)
	_update_machines(dt)
	_update_pads_portals(dt)
	# esteiras invertem
	if flip_every > 0.0:
		flip_t -= dt
		if flip_t < 1.2 and not level.belt_warn:
			Audio.play("alarme")
		level.belt_warn = flip_t < 1.2
		if flip_t <= 0.0:
			flip_t = flip_every
			level.belt_warn = false
			level.flip_belts()
			main.shake(3.0)
	# lama sobe
	if goo_on and main.demo.t >= float(level.prop("mare_inicio", "6")):
		var top := float(level.prop("mare_topo", "2")) * T
		goo_y = maxf(goo_y - float(level.prop("mare_vel", "0.25")) * T * dt, top)
		bubble_t -= dt
		if bubble_t <= 0.0:
			bubble_t = randf_range(0.35, 0.9)
			Audio.play("lama", 1.0, -6.0)
		for r in main.robots:
			if r.alive and r.position.y - 20.0 > goo_y:
				r.last_hit = 0.0
				r.last_cause = "lama"
				r.caught = true
				main.kill(r, -1, null)
		for cell in level.blocks.keys():
			if cell.y * T > goo_y + T:
				main.demo.break_reason = "lama"
				level.break_block(cell)
				main.demo.break_reason = ""
	# bola de demolição
	if not ball.is_empty():
		var before_x: float = ball["pos"].x - ball["pivot"].x
		_ball_step(dt)
		if signf(before_x) != signf(ball["pos"].x - ball["pivot"].x):
			Audio.play("bola_vento")
		var bp: Vector2 = ball["pos"]
		for r in main.robots:
			if r.alive and r.rect().grow(4).intersects(Rect2(bp - Vector2(46, 46), Vector2(92, 92))) and r.stun_t <= 0.2:
				var dir := 1 if ball["vel"].x >= 0.0 else -1
				r.take_hit(dir, "bola", -1)
				main.spark(r.rect().get_center(), 8)
				main.shake(9.0)
		for cell in level.blocks.keys():
			if (Vector2(cell * T) + Vector2(32, 32)).distance_to(bp) < 70.0:
				main.demo.break_reason = "bola"
				level.break_block(cell)
				main.demo.break_reason = ""
	queue_redraw()

## Câmera que rola: anda depois de scroll_start; quem sai pelo lado de trás está fora; o chão de trás desaba.
func _update_scroll(dt: float) -> void:
	if not scroll_on:
		return
	var lw: float = level.cols * T
	var lh: float = level.rows * T
	if main.demo.t >= scroll_start:
		if scroll_dir == "cima":
			scroll_center.y = maxf(scroll_center.y - scroll_vel * dt, 512.0)
		elif scroll_dir == "baixo":
			scroll_center.y = minf(scroll_center.y + scroll_vel * dt, lh - 512.0)
		else:
			scroll_center.x = minf(scroll_center.x + scroll_vel * dt, lw - 960.0)
	var view := Rect2(scroll_center - Vector2(960, 512), Vector2(1920, 1024))
	for r in main.robots:
		if not r.alive:
			continue
		var behind := false
		if scroll_dir == "cima":
			behind = r.position.y - 80.0 > view.end.y
		elif scroll_dir == "baixo":
			behind = r.position.y + 10.0 < view.position.y   # ficou lá em cima
			if r.position.y > view.end.y - 10.0 and r.velocity.y > 0.0:   # não passa da frente (de baixo) da tela
				r.position.y = view.end.y - 10.0
				r.velocity.y = 0.0
		else:
			behind = r.position.x + 30.0 < view.position.x
			if r.position.x > view.end.x - 28.0:   # não passa da frente da tela
				r.position.x = view.end.x - 28.0
				r.own_vx = minf(r.own_vx, 0.0)
		if behind:
			r.caught = true
			if r.last_hit > 2.5:
				r.last_cause = "ficou para trás"
				r.last_hit = 0.0
				r.last_attacker = -1
			Audio.play("ficou_para_tras", 1.0, -4.0)
			main.kill(r, -1, null)
	# o que ficou para trás desaba
	for cell in level.blocks.keys():
		var cp := Vector2(cell * T)
		if (scroll_dir == "cima" and cp.y > view.end.y + 64.0) or (scroll_dir == "baixo" and cp.y + T < view.position.y - 64.0) \
				or (scroll_dir == "direita" and cp.x + T < view.position.x - 64.0):
			if level.blocks[cell]["warn"] <= 0.0:
				level.blocks[cell]["warn"] = 0.4

func _update_seesaws(dt: float) -> void:
	for g in seesaws:
		var torque := 0.0
		var on := []
		var half: float = g["w"] * T / 2.0
		for r in main.robots:
			if not r.alive:
				continue
			var lp: Vector2 = (r.position - g["pivot"]).rotated(-float(g["ang"]))
			if absf(lp.x) <= half + 8.0 and lp.y > -40.0 and lp.y < 8.0 and r.velocity.y >= -10.0:
				torque += lp.x
				on.append(r)
		var target := clampf(torque / half * 0.35, -0.3, 0.3)
		var spd := 1.3 if on.size() > 0 else 0.9
		g["ang"] = lerpf(g["ang"], target, 1.0 - exp(-dt * spd))
		g["body"].rotation = g["ang"]
		for r in on:
			if r.stun_t > 0.0 or absf(r.own_vx) < 60.0:
				r.push_vx += sin(g["ang"]) * 420.0   # parado ou tonto: escorrega para o lado mais baixo

func _update_machines(dt: float) -> void:
	# ventiladores (ligam e desligam)
	if fans.size() > 0:
		var cyc := String(level.prop("ventilador_ciclo", "5,2.5")).split(",")
		fan_t += dt
		var period := float(cyc[0]) + float(cyc[1])
		var was := fan_on
		fan_on = fmod(fan_t, period) < float(cyc[0])
		if fan_on and not was:
			Audio.play("ventilador", 1.0, -4.0)
		if fan_on:
			for f in fans:
				for r in main.robots:
					if r.alive and r.rect().intersects(f["rect"]):
						r.velocity.y = maxf(r.velocity.y - 7600.0 * dt, -720.0)
						r.var_jump = 0.0
						r.air_jumps = 1
	# chamas
	if flames.size() > 0:
		var cc := String(level.prop("chama_ciclo", "2.4,0.8,1.3")).split(",")
		var per := float(cc[0]) + float(cc[1]) + float(cc[2])
		for f in flames:
			var u := fposmod(t + f["off"] * per, per)
			var st := "" if u < float(cc[0]) else ("aviso" if u < float(cc[0]) + float(cc[1]) else "acesa")
			if st == "acesa" and f.get("st", "") != "acesa":
				Audio.play("chama", 1.0, -6.0)
			f["st"] = st
			if st == "acesa":
				var cx: float = f["rect"].get_center().x
				for r in main.robots:
					if r.alive and r.stun_t <= 0.1 and r.rect().intersects(f["rect"]):
						r.take_hit(1 if r.position.x >= cx else -1, "chama", -1)
						main.spark(r.rect().get_center(), 6)
	# pistões
	var pc := float(level.prop("pistao_ciclo", "4.5"))
	for p in pistons:
		var u := fposmod(t + float(p["off"]), pc)
		var wait := pc - 2.0
		var prev: String = p["state"]
		if u < wait:
			p["state"] = ""
			p["ext"] = 0.0
		elif u < wait + 0.8:
			p["state"] = "aviso"
			p["ext"] = sin(u * 60.0) * 3.0
		elif u < wait + 0.95:
			p["state"] = "desce"
			p["ext"] = float(p["max"]) * (u - wait - 0.8) / 0.15
		elif u < wait + 1.4:
			p["state"] = "embaixo"
			p["ext"] = float(p["max"])
		else:
			p["state"] = "sobe"
			p["ext"] = float(p["max"]) * (1.0 - (u - wait - 1.4) / 0.6)
		if p["state"] == "aviso" and prev == "":
			Audio.play("pistao_aviso", 1.0, -8.0)
		if p["state"] == "embaixo" and prev == "desce":
			Audio.play("pistao")
			main.shake(5.0)
			main.dust(Vector2(p["cell"].x * T + 32, (p["cell"].y + 1) * T + float(p["ext"])), 1.0)
		if p["state"] in ["desce", "embaixo"]:
			var head := _piston_head(p)
			for r in main.robots:
				if r.alive and r.stun_t <= 0.15 and r.rect().intersects(head):
					var cx := head.get_center().x
					var d := 1 if r.position.x >= cx else -1
					if absf(r.position.x - cx) < 4.0:
						d = 1 if main.rng.randf() < 0.5 else -1
					r.take_hit(d, "prensa", -1)
					main.spark(r.rect().get_center(), 8)
			for cell in level.blocks.keys():
				if Rect2(Vector2(cell * T), Vector2(T, T)).grow(-4).intersects(head):
					main.demo.break_reason = "prensa"
					level.break_block(cell)
					main.demo.break_reason = ""
	# serras no trilho
	for sw in saws:
		var k := 0.5 - 0.5 * cos(TAU * t / float(sw["period"]))
		var nx: float = lerpf(sw["x1"], sw["x2"], k)
		var nvx: float = (nx - sw["pos"].x) / maxf(dt, 0.001)
		if signf(nvx) != signf(sw["vx"]) and absf(sw["vx"]) > 1.0:
			Audio.play("serra", 0.9, -10.0)
		sw["vx"] = nvx
		sw["pos"] = Vector2(nx, sw["y"])
		var sp: Vector2 = sw["pos"]
		for r in main.robots:
			if r.alive and r.stun_t <= 0.15 and _circle_rect(sp, 40.0, r.rect()):
				r.take_hit(1 if r.position.x >= sp.x else -1, "serra", -1)
				main.spark(r.rect().get_center(), 10)
				Audio.play("serra", 1.0, -2.0)
				Audio.play("bonk", 1.4)
		for cell in level.blocks.keys():
			if _circle_rect(sp, 38.0, Rect2(Vector2(cell * T), Vector2(T, T))) and cell.y * T < sp.y - 8.0:
				main.demo.break_reason = "serra"
				level.break_block(cell)
				main.demo.break_reason = ""
	# barris
	var every := float(level.prop("barril_cada", "5.5"))
	for ch in chutes:
		ch["t"] -= dt
		if ch["t"] <= 0.0:
			ch["t"] = every
			var c0: Vector2i = ch["cell"]
			barrels.append({"pos": Vector2(c0.x * T + 32 + ch["dir"] * 44, c0.y * T + 34), "vx": ch["dir"] * float(level.prop("barril_vel", "4.5")) * T,
				"vy": 0.0, "by": -1, "bounces": 0, "rot": 0.0})
			Audio.play("barril", 0.8)
	for b in barrels:
		_barrel_step(b, dt)
	barrels = barrels.filter(func(b): return not b.get("dead", false) and b["pos"].y < level.rows * T + 100)
	# alçapões fecham sozinhos depois de um tempo (só onde não tem ninguém dentro)
	if traps_open_t > 0.0:
		traps_open_t -= dt
		if traps_open_t <= 0.0:
			for c in level.traps.keys():
				var cr := Rect2(Vector2(c * T), Vector2(T, 24))
				var busy := false
				for r in main.robots:
					if r.alive and r.rect().intersects(cr):
						busy = true
				if busy:
					traps_open_t = 0.1
				elif level.ch_at(c) == "A":
					level.set_trap(c, false)
	for lv in levers:
		lv["ang"] = lerpf(lv["ang"], 0.6 if traps_open_t > 0.0 else -0.6, 1.0 - exp(-dt * 12.0))

## Para os bots: centro do perigo ativo (ou prestes a ligar) mais perto deste ponto, ou Vector2.INF.
func hazard_near(p: Vector2, margin: float) -> Vector2:
	var best := Vector2.INF
	var bd := margin
	var hz: Array = []
	for f in flames:
		if f.get("st", "") != "":
			hz.append(f["rect"])
	for pi in pistons:
		if pi["state"] in ["aviso", "desce", "embaixo"]:
			var c: Vector2i = pi["cell"]
			hz.append(Rect2(c.x * T, (c.y + 1) * T, T, float(pi["max"])))
	for sw in saws:
		hz.append(Rect2(sw["pos"] - Vector2(46, 46), Vector2(92, 92)))
	for b in barrels:
		hz.append(Rect2(b["pos"] - Vector2(28, 28), Vector2(56, 56)))
	for r in hz:
		var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
		var d := q.distance_to(p)
		if d < bd:
			bd = d
			best = r.get_center()
	return best

## Para os bots: alguém em cima dos alçapões fechados?
func someone_on_traps(except) -> bool:
	for c in level.traps.keys():
		if level.ch_at(c) != "a":
			continue
		for r in main.robots:
			if r != except and r.alive and absf(r.position.x - (c.x * T + 32)) < 36.0 and absf(r.position.y - c.y * T) < 8.0:
				return true
	return false

func _piston_head(p: Dictionary) -> Rect2:
	var c: Vector2i = p["cell"]
	return Rect2(c.x * T + 2, (c.y + 1) * T + float(p["ext"]) - 46.0, T - 4, 46.0)

func _circle_rect(c: Vector2, rad: float, r: Rect2) -> bool:
	var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
	return q.distance_to(c) < rad

func _barrel_step(b: Dictionary, dt: float) -> void:
	b["vy"] = minf(b["vy"] + 1800.0 * dt, 1000.0)
	var p: Vector2 = b["pos"]
	var nx: float = p.x + b["vx"] * dt
	var ahead := Vector2i(int((nx + signf(b["vx"]) * 27.0) / T), int(p.y / T))
	if level.is_solid(ahead):
		b["bounces"] += 1
		b["vx"] = -b["vx"] * 0.8
		Audio.play("barril", 1.2, -4.0)
		if b["bounces"] > 2:
			_barrel_break(b)
			return
	else:
		p.x = nx
	var ny: float = p.y + b["vy"] * dt
	var below := Vector2i(int(p.x / T), int((ny + 27.0) / T))
	if b["vy"] > 0.0 and level.is_solid(below) and p.y + 27.0 <= below.y * T + 6.0:
		ny = below.y * T - 27.0
		if b["vy"] > 500.0:
			Audio.play("barril", 1.0, -8.0)
		b["vy"] = 0.0
	p.y = ny
	b["pos"] = p
	b["rot"] += b["vx"] * dt / 27.0
	for r in main.robots:
		if r.alive and r.stun_t <= 0.15 and r.pid != b["by"] and _circle_rect(p, 27.0, r.rect()):
			r.take_hit(1 if b["vx"] >= 0.0 else -1, "barril", int(b["by"]))
			main.spark(p, 6)
			_barrel_break(b)
			return

func _barrel_break(b: Dictionary) -> void:
	b["dead"] = true
	main.dust(b["pos"], 1.0)
	main.break_crate(b["pos"])
	Audio.play("caixote_quebra", 0.8)

## Marretada perto de uma alavanca ou de um barril. true = acertou algo daqui.
## heavy = marretada pesada (chuta barril); o golpe rápido só puxa alavanca.
func hammer_hit(r, reach: Rect2, heavy := true) -> bool:
	var hit := false
	for b in barrels:
		if not heavy:
			break
		if reach.grow(10).has_point(b["pos"]):
			b["vx"] = r.facing * 560.0
			b["vy"] = -260.0
			b["by"] = r.pid
			b["bounces"] = 0
			main.spark(b["pos"], 5)
			hit = true
	for lv in levers:
		var lr := Rect2(Vector2(lv["cell"] * T), Vector2(T, T))
		if reach.intersects(lr) and traps_open_t <= 0.0:
			pull_lever(r.pid)
			hit = true
	return hit

func pull_lever(by: int) -> void:
	traps_open_t = float(level.prop("alcapao_s", "3.5"))
	# portas: alavanca inverte (abertas fecham, fechadas abrem); não fecha em cima de ninguém
	for c in level.doors.keys():
		var opening: bool = level.ch_at(c) == "D"
		var busy := false
		if not opening:
			var dr := Rect2(Vector2(c * T), Vector2(T, T))
			for r in main.robots:
				if r.alive and r.rect().intersects(dr):
					busy = true
		if not busy:
			level.set_door(c, opening)
	if not level.doors.is_empty():
		Audio.play("alcapao", 1.3, -3.0)
	trap_by = by
	Audio.play("alavanca")
	Audio.play("alcapao", 1.0, -2.0)
	main.shake(3.0)
	for c in level.traps.keys():
		for r in main.robots:
			if r.alive and absf(r.position.x - (c.x * T + 32)) < 40.0 and absf(r.position.y - c.y * T) < 8.0:
				r.last_hit = 0.0
				r.last_cause = "alçapão"
				r.last_attacker = by
		level.set_trap(c, true)

## Trampolins (J) e tubos de teletransporte (Y/Z).
func _update_pads_portals(dt: float) -> void:
	for k in portal_cd.keys():
		portal_cd[k] = maxf(portal_cd[k] - dt, 0.0)
	var launch := float(level.prop("trampolim", "2150"))   # ~6 tiles: pula dois andares
	for r in main.robots:
		if not r.alive:
			continue
		if r.is_on_floor() and r.velocity.y >= -10.0:
			var below := Vector2i(int(r.position.x / T), int((r.position.y + 2.0) / T))
			if level.ch_at(below) == "J":
				r.velocity.y = -launch
				r.var_jump = 0.0
				r.vis.stretch()
				pad_t[below] = t
				Audio.play("pulo_mola", 0.9)
		if portal_cd.get(r.pid, 0.0) > 0.0:
			continue
		var cc := Vector2i(int(r.position.x / T), int((r.position.y - 30.0) / T))
		var ch: String = level.ch_at(cc)
		if (ch == "Y" or ch == "Z") and level.portals.has(ch) and level.portals[ch].size() == 2:
			var pair: Array = level.portals[ch]
			var dest: Vector2i = pair[1] if pair[0] == cc else pair[0]
			main.spark(r.rect().get_center(), 6)
			r.position = Vector2(dest.x * T + T / 2.0, dest.y * T + T - 2.0)
			r.reset_physics_interpolation()
			portal_cd[r.pid] = 1.2
			main.spark(r.rect().get_center(), 6)
			Audio.play("teleporte", 1.1, -2.0)

func _ball_step(_dt: float) -> void:
	var ang: float = ball["amp"] * sin(TAU * t / float(ball["period"]))
	var w: float = ball["amp"] * cos(TAU * t / float(ball["period"])) * TAU / float(ball["period"])
	var dirv := Vector2(sin(ang), cos(ang))
	ball["pos"] = ball["pivot"] + dirv * float(ball["len"])
	ball["vel"] = Vector2(cos(ang), -sin(ang)) * w * float(ball["len"])

func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_arena_fx", _pf)

func _draw_perf() -> void:
	if level == null or not is_instance_valid(level):
		return
	_draw_machines()
	# redemoinho dos tubos de teletransporte
	for ch in level.portals:
		var pc := Color("#d9c8ff") if ch == "Y" else Color("#c8f6f8")
		for c in level.portals[ch]:
			var cen := Vector2(c * T) + Vector2(T / 2.0, T / 2.0)
			for k in 3:
				var a0 := t * 4.0 + k * TAU / 3.0
				draw_arc(cen, 8.0 + k * 5.0, a0, a0 + 2.2, 12, pc, 3.0, true)
	# mola do trampolim encolhe e estica quando alguém pula
	for c in pad_t:
		var age: float = t - pad_t[c]
		if age < 0.3:
			var pos := Vector2(c * T)
			draw_rect(Rect2(pos + Vector2(4, -10.0 * (1.0 - age / 0.3)), Vector2(T - 8, 8)), Color("#ff8a8a"))
	# cabos e plataformas
	var tex := Data.tex("cenario/plataforma_aco")
	for p in plats:
		var pos: Vector2 = p["body"].position
		var w: float = p["w"] * T
		for cx in [pos.x + 16, pos.x + w - 16]:
			draw_line(Vector2(cx, -200), Vector2(cx, pos.y + 6), Color("#5a6370"), 3.0, true)
		draw_texture_rect(tex, Rect2(pos + Vector2(0, -6), Vector2(w, 40)), false)
	# bola + corrente
	if not ball.is_empty():
		var a: Vector2 = ball["pivot"]
		var b: Vector2 = ball["pos"]
		var n := 14
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			draw_circle(p, 6.5, Color("#5a6370"))
			draw_circle(p, 3.5, Color("#8e98a8"))
		draw_set_transform(b, -atan2(b.x - a.x, b.y - a.y))
		draw_texture_rect(Data.tex("cenario/bola_demolicao"), Rect2(-60, -60, 120, 120), false)
		draw_set_transform(Vector2.ZERO)
		draw_circle(a, 12, Color("#3e4752"))
	# lama subindo
	if goo_on and goo_y < level.rows * T + 30:
		var lama := Data.tex("cenario/lama")
		var y := goo_y - 24.0
		var x := -fposmod(t * 20.0, 64.0)
		while x < level.cols * T and lama != null:
			draw_texture_rect(lama, Rect2(x, y, 64, 64), false)
			x += 64.0
		draw_rect(Rect2(0, y + 60, level.cols * T, level.rows * T + 200 - y), Color("#7a5fb3"))

func _draw_machines() -> void:
	var now := t
	# ventiladores: hélice girando e correntes de ar subindo
	for f in fans:
		var c: Vector2i = f["cell"]
		var center := Vector2(c.x * T + 32, c.y * T + 34)
		draw_set_transform(center, now * (22.0 if fan_on else 2.0))
		draw_texture_rect(Data.tex("cenario/helice"), Rect2(-24, -24, 48, 48), false)
		draw_set_transform(Vector2.ZERO)
		if fan_on:
			var r: Rect2 = f["rect"]
			for k in 5:
				var x := r.position.x + 10 + k * 13
				var y := r.end.y - fposmod(now * 520.0 + k * 97.0, r.size.y)
				draw_line(Vector2(x, y), Vector2(x, y + 34), Color(1, 1, 1, 0.6), 3.0, true)
	# chamas
	for f in flames:
		var r: Rect2 = f["rect"]
		var st: String = f.get("st", "")
		if st == "":
			continue
		var c: Vector2i = f["cell"]
		var base := Vector2(c.x * T, c.y * T + 6)
		var h := 0.25 + 0.08 * sin(now * 40.0) if st == "aviso" else 1.0 + 0.06 * sin(now * 30.0 + c.x)
		var wob := sin(now * 25.0 + c.x) * 0.04
		draw_set_transform(base + Vector2(32, 0), wob, Vector2(1.0 + 0.05 * sin(now * 33.0), h))
		draw_texture_rect(Data.tex("cenario/chama"), Rect2(-32, -160, 64, 160), false)
		draw_set_transform(Vector2.ZERO)
	# pistões: aviso vermelho na coluna, haste e prensa
	for p in pistons:
		var c: Vector2i = p["cell"]
		if p["state"] == "aviso":
			var a := 0.18 + 0.12 * sin(now * 30.0)
			draw_rect(Rect2(c.x * T, (c.y + 1) * T, T, float(p["max"])), Color(0.83, 0.13, 0.21, a))
		var head := _piston_head(p)
		var rod_top := float((c.y + 1) * T) - 20.0
		var y := rod_top
		while y < head.position.y:
			var hh := minf(64.0, head.position.y - y + 2.0)
			draw_texture_rect_region(Data.tex("cenario/pistao_haste"), Rect2(c.x * T + 16, y, 32, hh), Rect2(0, 0, 96, hh * 3.0))
			y += 64.0
		draw_texture_rect(Data.tex("cenario/pistao_prensa"), Rect2(c.x * T, head.position.y - 2, T, 48), false)
	# serras: trilho e lâmina girando
	for sw in saws:
		var x := float(sw["x1"]) - 64.0
		while x < float(sw["x2"]) + 64.0:
			draw_texture_rect(Data.tex("cenario/trilho"), Rect2(x, float(sw["y"]) - 12.0, 64, 16), false)
			x += 64.0
		draw_set_transform(sw["pos"], now * 14.0 * (1.0 if sw["vx"] >= 0.0 else -1.0))
		draw_texture_rect(Data.tex("cenario/serra"), Rect2(-46, -46, 92, 92), false)
		draw_set_transform(Vector2.ZERO)
	# barris rolando
	for b in barrels:
		draw_set_transform(b["pos"], b["rot"])
		draw_texture_rect(Data.tex("cenario/barril"), Rect2(-28, -28, 56, 56), false)
		draw_set_transform(Vector2.ZERO)
	# alavancas
	for lv in levers:
		var c: Vector2i = lv["cell"]
		var piv := Vector2(c.x * T + 32, c.y * T + 50)
		draw_set_transform(piv, lv["ang"])
		draw_texture_rect(Data.tex("cenario/alavanca_haste"), Rect2(-8, -50, 16, 56), false)
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(Data.tex("cenario/alavanca_base"), Rect2(c.x * T, c.y * T + 32, 64, 32), false)
	# gangorras
	for g in seesaws:
		var pv: Vector2 = g["pivot"]
		draw_texture_rect(Data.tex("cenario/gangorra_apoio"), Rect2(pv + Vector2(-32, -12), Vector2(64, 64)), false)
		var w: int = g["w"]
		draw_set_transform(pv, g["ang"])
		for k in w:
			draw_texture_rect(Data.tex("cenario/gangorra_tabua"), Rect2(-w * T / 2.0 + k * T, -26, T, 28), false)
		draw_set_transform(Vector2.ZERO)
