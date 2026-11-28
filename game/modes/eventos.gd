extends Node2D
## EVENTOS GLOBAIS (Relatório 04): cada evento tem AVISO (com o lugar marcado) → ATIVO → FIM (restauração).
## Até `max_simultaneos` eventos COMPATÍVEIS ao mesmo tempo (matriz `conflitos`). Intensidade nos AJUSTES:
## 0 desligados, 1 baixa, 2 normal, 3 alta (muda o ritmo, a força e a quantidade). Cada evento pode ser desligado
## na tela ESCOLHER EVENTOS. Números em data/modos.json → demolicao.eventos.
## Estrutura (Canteiro): G01 Sirene, G05 Guindaste, G12 Troca de Andaimes, G13 Cabo Rompido.
## Universais: G06 Entulho, G11 Interdição, G02 Ventania, G03 Gravidade, G04 Sobrecarga, G14 Rebites, G10 Carga Especial.
## Eventos nunca fingem ser ataque de jogador: golpes do ambiente usam by = -1.

const Kit := preload("res://ui/kit.gd")
const T := 64
const INK := Color("#2a1a2e")
const YEL := Color("#f2c84b")
const RED := Color("#d94a3a")
const GREEN := Color("#3c9a46")
var main: Node
var cfg: Dictionary
var enabled := {}            # id -> bool
var timer := 0.0
var active: Array = []       # {e, id, phase, t, len, age, d}
var manual := false          # Laboratório: só dispara pelo painel
var libera_tudo := false     # testes da biblioteca: ignora a lista do mapa/cena
var menu_sel := 0
var fired: Array = []        # ids disparados (testes)
var t := 0.0
var gravity_mult := 1.0
var wind := 0.0
var crates: Array = []       # G06 {pos(pés), vy, floor, kind, state, life, hp, body, flash}
var rivets: Array = []       # G14 {pos, vy, state, t, hits(dict), ev}
var bits: Array = []         # partículas {pos, vel, t, life, kind, rot, spin, size}
var front: Node2D            # camada da frente (vento, rebites, drone, medidor)
var tex := {}

## Compatibilidade (testes antigos): fase do evento mais recente e os 2 holofotes do G10.
var phase: String:
	get:
		return "" if active.is_empty() else String(active[-1]["phase"])
var spots: Array:
	get:
		for a in active:
			if a["id"] == "G10":
				return a["d"].get("spots", [])
		return []

func setup(m: Node) -> void:
	main = m
	cfg = Data.read_json("data/modos.json")["demolicao"]["eventos"]
	for e in cfg["lista"]:
		enabled[e["id"]] = true
	for k in ["g02_exaustor", "g02_helice", "g02_grade", "g04_bobina", "g05_carga", "g05_moitao", "g06_caixa", "g06_sucata",
			"g11_tapume", "g14_rebite"]:
		tex[k] = Data.tex("spells/" + k)
	tex["pedaco"] = Data.tex("canteiro/laje_pedaco_1")
	front = Node2D.new()
	front.z_index = 2
	front.draw.connect(_draw_front)
	add_child(front)

func reset_round() -> void:
	for a in active.duplicate():
		_cleanup(a)
	active.clear()
	for c in crates:
		if c["body"] != null and is_instance_valid(c["body"]):
			c["body"].queue_free()
	crates.clear()
	rivets.clear()
	bits.clear()
	_fila.clear()
	_fila_viva = false
	gravity_mult = 1.0
	wind = 0.0
	var lvl: int = main.event_level
	timer = float(cfg["primeiro_s"][lvl]) * main.rng.randf_range(0.85, 1.15)

## Virada da fase: encerra tudo o que está ativo (restaura) sem mexer no ritmo.
func stop_all() -> void:
	for a in active.duplicate():
		_cleanup(a)
	active.clear()
	for c in crates.duplicate():
		_break_crate(c)
	rivets.clear()

func ev(id: String) -> Dictionary:
	for e in cfg["lista"]:
		if e["id"] == id:
			return e
	return {}

func is_active(id: String) -> bool:
	return active.any(func(a): return a["id"] == id)

func inst(id: String) -> Variant:
	for a in active:
		if a["id"] == id:
			return a
	return null

## Intensidade: multiplicador de força/quantidade (baixa < normal < alta).
func K() -> float:
	return float(cfg["intensidade"][clampi(main.event_level, 0, 3)])

func max_sim() -> int:
	return int(cfg["max_simultaneos"][clampi(main.event_level, 0, 3)])

func _canteiro():
	if main.demo == null:
		return null
	var ct = main.demo.canteiro
	return ct if ct != null and is_instance_valid(ct) else null

func _pr() -> Rect2:
	return main.demo.play_rect()

## O que a câmera mostra agora (dentro da arena): exaustores, medidor, drone e faixas de rebite ficam à vista.
func _vr() -> Rect2:
	var v: Rect2 = main.view_rect()
	var pr := _pr()
	return v.intersection(pr) if v.intersects(pr) else pr

func _etapa() -> int:
	var et = main.demo.etapas if main.demo != null else null
	return et.etapa if et != null and is_instance_valid(et) else 1

## Mecanismo de água ativo nesta etapa (V3 Enchente).
func _agua():
	var mc = main.demo.mecs if main.demo != null else null
	if mc == null or not is_instance_valid(mc):
		return null
	return mc._find("agua")

## Chão embaixo do buraco do teto (V2 Desmoronamento).
func _hole_spots() -> Array:
	var et = main.demo.etapas
	if et == null or not is_instance_valid(et):
		return []
	return _ground_spots(2).filter(func(p): return p.x > et.hole.x + 40.0 and p.x < et.hole.y - 40.0)

func _solid_px(p: Vector2) -> bool:
	return main.level.is_solid(Vector2i(int(floor(p.x / T)), int(floor(p.y / T))))

## Dois eventos podem rodar juntos? (mesmo id nunca; pares da matriz `conflitos` nunca)
func compatible(id: String) -> bool:
	for a in active:
		if a["id"] == id or conflict(a["id"], id):
			return false
	return true

func conflict(x: String, y: String) -> bool:
	for pair in cfg["conflitos"]:
		if (pair[0] == x and pair[1] == y) or (pair[1] == x and pair[0] == y):
			return true
	return false

## Evento pode rodar nesta arena agora?
func eligible(e: Dictionary) -> bool:
	if main.demo == null or (not enabled.get(e["id"], true) and not String(e["id"]).begins_with("V")):
		return false   # V# = perigo da cena (A14): não depende da seleção de eventos
	# eventos são DO MAPA E DA CENA: o manifesto lista quais valem em cada cena; mapa-ferramenta = biblioteca inteira
	# (exceto V#, específicos de mapa); mapa sem manifesto = nenhum. libera_tudo: testes da biblioteca.
	if not libera_tudo:
		var lst = MapaReg.eventos(main.game_mode, main.level.id, _etapa())
		if lst == null:
			if String(e["id"]).begins_with("V"):
				return false
		elif not (e["id"] in lst):
			return false
	var ct = _canteiro()
	match e["id"]:
		"V1":
			return ct != null and _ground_spots(2).size() >= 2
		"V2":
			return _etapa() == 2 and not _hole_spots().is_empty()
		"V3":
			return _agua() != null
		"G01":
			return ct != null and ct.can_alert()
		"G10":
			return main.demo.spells != null and (main.demo.items_on or manual) and main.demo.spells.spawn_points().size() >= 2
		"G02", "G03", "G14":
			return true
		"G04":
			return _coil_spot() != null
		"G05":
			return ct != null and _crane_spot() != null
		"G06":
			return _ground_spots(2).size() >= 4
		"G11":
			return not _wall_spots().is_empty()
		"G12":
			return ct != null and not _scaffold_moves(ct).is_empty()
		"G13":
			return ct != null and (_beam_pick(ct) != null or _poco_viga_rect() != Rect2())
	return false

func update(dt: float) -> void:
	t += dt
	queue_redraw()
	front.queue_redraw()
	for r in main.robots:
		r.env_slow = 1.0   # lentidão do ambiente: eventos e mecanismos somam neste quadro
	var _pb := Perf.t0()
	_update_bits(dt)
	Perf.add("sub_ev_particulas", _pb)
	_pb = Perf.t0()
	_update_crates(dt)
	_update_rivets(dt)
	Perf.add("sub_ev_caixas_rebites", _pb)
	wind = 0.0
	gravity_mult = 1.0
	if main.event_level <= 0 or main.state != main.S.RUN or main.countdown > 0.0:
		return
	var et = main.demo.etapas if main.demo != null else null
	var virando: bool = et != null and is_instance_valid(et) and et.state != "etapa"
	if not manual and not virando and active.size() < max_sim():
		timer -= dt
		if timer <= 0.0:
			_sorteia_aos_poucos()
	for a in active.duplicate():
		var _pe := Perf.t0()
		_step(a, dt)
		Perf.add("ev_%s_%s" % [String(a.get("id", "?")), String(a.get("phase", ""))] if Perf.on else "", _pe)
	wind = clampf(wind, -float(cfg["vento_max"]), float(cfg["vento_max"]))

## Sorteio do próximo evento ESPALHADO EM QUADROS (desempenho, 2026-11-28): testar se cada evento cabe na cena (lugares
## livres, guindaste, andaimes...) custava 8–19 ms quando os 14 eram testados de uma vez. Agora a fila sai embaralhada e
## no máximo SORTEIO_POR_QUADRO são testados por quadro; o primeiro que couber é o sorteado (mesma chance para todos os
## que cabem). O último disparado vai para o fim da fila (só repete se nenhum outro couber).
const SORTEIO_POR_QUADRO := 2
var _fila: Array = []
var _fila_viva := false

func _sorteia_aos_poucos() -> void:
	if not _fila_viva:
		var ultimo = null
		_fila = []
		for e in cfg["lista"]:
			if not fired.is_empty() and e["id"] == fired[-1]:
				ultimo = e
			else:
				_fila.append(e)
		for i in range(_fila.size() - 1, 0, -1):   # embaralha com o rng da partida (repetível)
			var j: int = main.rng.randi_range(0, i)
			var tmp = _fila[i]
			_fila[i] = _fila[j]
			_fila[j] = tmp
		if ultimo != null:
			_fila.append(ultimo)
		_fila_viva = true
	var n := 0
	while not _fila.is_empty() and n < SORTEIO_POR_QUADRO:
		var e: Dictionary = _fila.pop_front()
		n += 1
		if compatible(e["id"]) and eligible(e):
			var _pa := Perf.t0()
			_announce(e, -1.0)
			Perf.add("ev_anuncio", _pa)
			timer = float(cfg["intervalo_s"][main.event_level]) * main.rng.randf_range(0.8, 1.2)
			_fila_viva = false
			return
	if _fila.is_empty():   # nenhum cabe agora: tenta de novo daqui a pouco
		_fila_viva = false
		timer = 3.0

func _step(a: Dictionary, dt: float) -> void:
	a["age"] += dt
	a["t"] -= dt
	var pa: float = a["len"] - a["t"]   # tempo dentro da fase
	match a["phase"]:
		"aviso":
			_tick_aviso(a, dt, pa)
			if a["t"] <= 0.0:
				a["phase"] = "ativo"
				a["t"] = float(a["d"].get("dur", a["e"]["dur"]))
				a["len"] = a["t"]
				_on_ativo(a)
		"ativo":
			_tick_ativo(a, dt, pa)
			if a["t"] <= 0.0:
				a["phase"] = "fim"
				a["t"] = float(a["e"].get("fim_s", 0.0))
				a["len"] = maxf(a["t"], 0.001)
				_on_fim(a)
		"fim":
			_tick_fim(a, dt, pa)
			if a["t"] <= 0.0:
				_cleanup(a)
				active.erase(a)
				Audio.play("evento_fim", 1.0, -4.0)

## Anúncio: faixa + som + o LUGAR marcado. aviso < 0 = o do data.
func _announce(e: Dictionary, aviso: float) -> bool:
	var a := {"e": e, "id": e["id"], "phase": "aviso", "t": aviso if aviso >= 0.0 else float(e["aviso_s"]), "age": 0.0, "d": {}}
	a["len"] = a["t"]
	if not _on_aviso(a):
		return false
	active.append(a)
	fired.append(e["id"])
	main.demo.banner = String(e.get("curto", e["nome"])).to_upper() + "!"
	main.demo.banner_t = 2.0
	Audio.play("evento", 1.0)
	return true

## Dispara um evento agora (painel do Laboratório): aviso curto; tira da frente o que conflita.
func trigger(e: Dictionary) -> void:
	for a in active.duplicate():
		if a["id"] == e["id"] or conflict(a["id"], e["id"]):
			_cleanup(a)
			active.erase(a)
	while active.size() >= 2:
		_cleanup(active[0])
		active.remove_at(0)
	if not eligible(e) or not _announce(e, minf(float(e["aviso_s"]), 1.2)):
		Audio.play("menu_negado")

func active_name() -> String:
	for a in active:
		if a["phase"] == "ativo":
			return String(a["e"]["nome"])
	return ""

# ================================================================ fases por evento
func _on_aviso(a: Dictionary) -> bool:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	var ct = _canteiro()
	match a["id"]:
		"G01":
			ct.start_alert(a["t"] + float(e["dur"]) * 0.5)   # sirene + fita já no aviso; cede no fim do aviso do Canteiro
		"G10":
			d["spots"] = _pick_spots()
		"G02":
			d["dir"] = 1 if main.rng.randf() < 0.5 else -1
			d["spin"] = 0.0
			d["ang"] = 0.0
			Audio.play("ventilador", 0.7, -2.0)
		"G03":
			Audio.play("vortice", 0.7, -4.0)
		"G04":
			var p = _coil_spot()
			if p == null:
				return false
			d["pos"] = p
			d["pulse_t"] = 0.0
			d["pulse"] = 0.0
			Audio.play("laser_carga", 0.6, -2.0)
		"G05":
			var r = _crane_spot()
			if r == null:
				return false
			d["rect"] = r
			d["y"] = _pr().position.y - 260.0
			Audio.play("alarme", 1.3, -6.0)
		"V1":
			var pts := _ground_spots(2)
			pts.shuffle()
			var strips := []
			for p in pts:
				if strips.size() >= 2:
					break
				if strips.all(func(r): return absf(r.get_center().x - p.x) > 360.0):
					strips.append(Rect2(p.x - 90.0, p.y - 12.0, 180.0, 12.0))
			if strips.size() < 2:
				return false
			d["strips"] = strips
			Audio.play("alarme", 1.1, -6.0)
		"V2":
			var pts2 := _hole_spots()
			pts2.shuffle()
			var pick2 := []
			for p in pts2:
				if pick2.size() >= maxi(int(round(float(e["pedacos"]) * K())), 2):
					break
				if pick2.all(func(q): return absf(q.x - p.x) > 170.0):
					pick2.append(p)
			if pick2.size() < 2:
				return false
			d["spots"] = pick2
			d["dur"] = pick2.size() * 0.35 + 1.2
			Audio.play("terremoto", 1.4, -6.0)
		"V3":
			if _agua() == null:
				return false
			Audio.play("alarme", 0.7, -2.0)
		"G06":
			var n := maxi(int(round(float(e["caixas"]) * K())), 2)
			var pts := _ground_spots(2)
			pts.shuffle()
			var pick := []
			for p in pts:
				if pick.size() >= n:
					break
				if pick.all(func(q): return absf(q.x - p.x) > 150.0 or absf(q.y - p.y) > 100.0):
					pick.append(p)
			if pick.size() < 2:
				return false
			d["spots"] = pick
			d["dur"] = pick.size() * 0.28 + 1.0
			Audio.play("alarme", 0.9, -6.0)
		"G11":
			var ws := _wall_spots()
			if ws.is_empty():
				return false
			ws.shuffle()
			var n := 2 if K() > 1.1 else 1
			var walls := []
			for p in ws:
				if walls.size() >= n:
					break
				if walls.all(func(w): return absf(w["x"] - p.x) > 360.0):
					walls.append({"x": p.x, "y": p.y, "w": 2.0 * T, "h": float(e["altura_px"]), "body": null, "k": 0.0})
			d["walls"] = walls
			Audio.play("pistao_aviso", 1.0, -4.0)
		"G12":
			var mv := _scaffold_moves(ct)
			if mv.is_empty():
				return false
			for m in mv:
				m["p"]["evt"] = "G12"
			d["moves"] = mv
			Audio.play("gancho", 0.6, -4.0)
		"G13":
			var p = _beam_pick(ct)
			if p == null and _poco_viga_rect() != Rect2():
				p = ct.viga_pelo_poco(_poco_viga_rect(), _etapa())   # Fundação: a viga desce pelo poço (A14)
			if p == null:
				return false
			p["evt"] = "G13"
			d["p"] = p
			d["base"] = p["rect"]
			d["floor"] = _floor_under_rect(p["rect"], p)
			d["y"] = p["rect"].position.y
			d["vy"] = 0.0
			d["state"] = "pendurada"
			d["body"] = null
			Audio.play("serra", 0.5, -8.0)
		"G14":
			d["waves"] = maxi(int(round(float(e["ondas"]) * K())), 1)
			d["wave"] = -1
			d["hits"] = {}
			_new_wave(a)
			Audio.play("alarme", 1.5, -6.0)
	return true

func _on_ativo(a: Dictionary) -> void:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	var ct = _canteiro()
	match a["id"]:
		"G10":   # CARGA ESPECIAL = chuva de ARMADURAS (as transformações, as spells mais fortes)
			for p in d["spots"]:
				main.demo.spells.spawn_box(p, true, String(e.get("classe", "transformacao")))
			Audio.play("elevador", 1.2, -4.0)
		"G02":
			Audio.play("soprador", 0.8, -2.0)
		"G03":
			Audio.play("vortice", 1.2, -2.0)
		"G04":
			Audio.play("ima", 0.7, -2.0)
		"G05":
			var r: Rect2 = d["rect"]
			var body := AnimatableBody2D.new()
			body.sync_to_physics = false
			body.collision_layer = 2
			body.collision_mask = 0
			var cs := CollisionShape2D.new()
			var shp := RectangleShape2D.new()
			shp.size = Vector2(r.size.x, 26)
			cs.shape = shp
			cs.position = r.position + Vector2(r.size.x / 2.0, 13)
			cs.one_way_collision = true
			body.add_child(cs)
			body.position = Vector2(0, d["y"] - r.position.y)
			add_child(body)
			d["body"] = body
			Audio.play("elevador", 0.8, -2.0)
		"G11":
			for w in d["walls"]:
				var r := Rect2(w["x"], w["y"] - w["h"], w["w"], w["h"])
				for rb in main.robots:   # nunca ergue dentro de alguém: empurra para o lado mais perto
					if rb.alive and rb.rect().intersects(r.grow_individual(4, 30, 4, 0)):
						var left: bool = rb.position.x < r.get_center().x
						rb.position.x = r.position.x - 30.0 if left else r.end.x + 30.0
						rb.push_vx = -160.0 if left else 160.0
				var body := StaticBody2D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var cs := CollisionShape2D.new()
				var shp := RectangleShape2D.new()
				shp.size = r.size
				cs.shape = shp
				cs.position = r.get_center()
				body.add_child(cs)
				add_child(body)
				w["body"] = body
			Audio.play("pistao", 1.0, -2.0)
			main.shake(3.0)
		"G13":
			var p: Dictionary = d["p"]
			if not p["fallen"]:
				ct.drop_body(p)
				d["state"] = "cai"
				Audio.play("caixote_quebra", 0.5, -2.0)
				main.float_text(p["rect"].get_center() + Vector2(0, -60), "CABO ROMPEU!", Color.WHITE)
				for k in 8:
					_spark_bit(Vector2(p["rect"].position.x + 40.0, p["rect"].position.y - 30.0))
			else:
				d["state"] = "sumiu"
		"G14":
			pass
		"V1":
			d["fresh"] = float(e["fresco_s"])
			Audio.play("lama", 0.7, 0.0)
			for st in d["strips"]:
				main.dust(st.get_center(), 1.2)
		"V3":
			var ag = _agua()
			if ag != null:
				ag["s"]["enchente"] = float(e["dur"])
				ag["s"]["enchente_mult"] = float(e["altura_mult"])

func _on_fim(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	match a["id"]:
		"G05":
			if d.get("body") != null and is_instance_valid(d["body"]):
				d["body"].queue_free()   # solta a trava: quem está em cima cai antes de a carga subir
			d["body"] = null
			Audio.play("elevador", 1.3, -4.0)
		"G11":
			for w in d["walls"]:
				if w["body"] != null and is_instance_valid(w["body"]):
					w["body"].queue_free()
				w["body"] = null
			Audio.play("pistao", 0.8, -4.0)
		"G13":
			if d.get("body") != null and is_instance_valid(d["body"]):
				d["body"].queue_free()
			d["body"] = null
			d["from_y"] = d["y"]
			if d["state"] == "chao" or d["state"] == "cai":
				Audio.play("gancho", 0.8, -4.0)

## Fim de verdade (também ao trocar de rodada): tudo volta ao normal, nada fica preso.
func _cleanup(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var ct = _canteiro()
	match a["id"]:
		"G01":
			if ct != null and ct.cycle_state == "aviso" and ct.target != null:
				ct.target["warn_t"] = 0.0
				ct.cycle_state = "calma"
		"G05", "G11":
			if d.get("body") != null and is_instance_valid(d["body"]):
				d["body"].queue_free()
			for w in d.get("walls", []):
				if w["body"] != null and is_instance_valid(w["body"]):
					w["body"].queue_free()
		"G12":
			if ct != null:
				for m in d["moves"]:
					if not m["p"]["fallen"]:
						ct.move_part(m["p"], m["base"])
					m["p"]["evt"] = ""
		"G13":
			if d.get("body") != null and is_instance_valid(d["body"]):
				d["body"].queue_free()
			if ct != null:
				var p: Dictionary = d["p"]
				p["evt"] = ""
				if not p["fallen"]:
					ct.restore_body(p, d["base"])

# ---------------------------------------------------------------- ticks
func _tick_aviso(a: Dictionary, dt: float, pa: float) -> void:
	var d: Dictionary = a["d"]
	var k: float = clampf(pa / maxf(a["len"], 0.01), 0.0, 1.0)
	match a["id"]:
		"G02":
			d["spin"] = k * 0.5
			d["ang"] += d["spin"] * 18.0 * dt
		"G03":
			if randf() < 6.0 * dt:
				_nut_bit(0.5)
		"G12":
			for m in d["moves"]:
				m["p"]["shake"] = 0.12   # correntes tensionam
		"G13":
			d["p"]["shake"] = 0.3
			if randf() < 10.0 * dt:
				var r: Rect2 = d["p"]["rect"]
				_spark_bit(Vector2(r.position.x + 40.0, r.position.y - 20.0 - randf() * 120.0))
			if fmod(a["age"], 0.5) < dt:
				Audio.play("serra", 0.4 + 0.3 * k, -10.0)
		"G14":
			_tick_rivets(a, dt, a["age"])

func _tick_ativo(a: Dictionary, dt: float, pa: float) -> void:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	var ct = _canteiro()
	match a["id"]:
		"G01":
			if ct == null or ct.cycle_state == "calma":
				a["t"] = 0.0   # a laje cedeu (ou a arena sumiu): termina já
		"G02":
			var ramp := clampf(pa / 0.6, 0.0, 1.0)
			var gust := 0.72 + 0.28 * sin(pa * 2.4)
			wind += float(d["dir"]) * float(e["forca"]) * K() * ramp * gust
			d["spin"] = 0.6 + 0.4 * gust
			d["ang"] += d["spin"] * 18.0 * dt
			if randf() < 26.0 * dt:
				_streak_bit(d["dir"])
		"G03":
			var target := clampf(1.0 - (1.0 - float(e["gravidade"])) * K(), 0.3, 0.92)
			gravity_mult = minf(gravity_mult, lerpf(1.0, target, clampf(pa / 0.5, 0.0, 1.0)))
			if randf() < 14.0 * dt:
				_nut_bit(1.0)
		"G04":
			d["pulse_t"] -= dt
			if d["pulse_t"] <= 0.0:
				d["pulse_t"] = float(e["pulso_s"])
				d["pulse"] = 0.45
				Audio.play("ima", 1.1, -4.0)
				main.shake(2.0)
			if d["pulse"] > 0.0:
				d["pulse"] -= dt
				_magnet_pull(a, dt)
		"G05":
			_crane_step(a, dt, pa)
		"G06", "V2":
			var spots_: Array = d["spots"]
			var gap := 0.28 if a["id"] == "G06" else 0.35
			var i := int(d.get("next", 0))
			if i < spots_.size() and pa >= i * gap:
				var p: Vector2 = spots_[i]
				_drop_crate(p, "pedaco" if a["id"] == "V2" else "")
				d["next"] = i + 1
		"V1":
			d["fresh"] = maxf(float(d["fresh"]) - dt, 0.0)
			for r in main.robots:
				if r.alive and r.is_on_floor():
					for st in d["strips"]:
						if r.position.x > st.position.x and r.position.x < st.end.x and absf(r.position.y - st.end.y) < 14.0:
							r.env_slow = minf(r.env_slow, float(e["lentidao"]))
		"G11":
			for w in d["walls"]:
				w["k"] = clampf(pa / 0.35, 0.0, 1.0)
				if w["body"] != null and not _solid_px(Vector2(w["x"] + 32.0, w["y"] + 8.0)) and not _solid_px(Vector2(w["x"] + 96.0, w["y"] + 8.0)):
					w["body"].queue_free()   # o chão sumiu (laje caiu): o tapume vai junto
					w["body"] = null
					w["gone"] = true
		"G12":
			var mk := clampf(pa / float(e["mover_s"]), 0.0, 1.0)
			var s := mk * mk * (3.0 - 2.0 * mk)
			for m in d["moves"]:
				if not m["p"]["fallen"]:
					ct.move_part(m["p"], m["base"] + m["dy"] * s)
			if mk >= 1.0 and not d.get("locked", false):
				d["locked"] = true
				Audio.play("chave", 1.0, 0.0)
				for m in d["moves"]:
					main.spark(m["p"]["rect"].position + Vector2(10, 4), 4)
					main.spark(Vector2(m["p"]["rect"].end.x - 10, m["p"]["rect"].position.y + 4), 4)
		"G13":
			_beam_step(a, dt)
		"G14":
			_tick_rivets(a, dt, a["age"])

func _tick_fim(a: Dictionary, dt: float, _pa: float) -> void:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	var k: float = clampf(a["t"] / a["len"], 0.0, 1.0)   # 1 → 0
	var ct = _canteiro()
	match a["id"]:
		"G02":
			wind += float(d["dir"]) * float(e["forca"]) * K() * 0.7 * k
			d["spin"] = 0.6 * k
			d["ang"] += d["spin"] * 18.0 * dt
		"G03":
			var target := clampf(1.0 - (1.0 - float(e["gravidade"])) * K(), 0.3, 0.92)
			gravity_mult = minf(gravity_mult, lerpf(1.0, target, k))
		"G05":
			if d.get("state", "") != "caiu":
				var top := _pr().position.y - 260.0
				d["y"] = lerpf(top, d["rect"].position.y, k * k)
		"G11":
			for w in d["walls"]:
				w["k"] = k
		"G12":
			var s := k * k * (3.0 - 2.0 * k)
			for m in d["moves"]:
				if not m["p"]["fallen"]:
					ct.move_part(m["p"], m["base"] + m["dy"] * s)
		"G13":
			if d["state"] != "sumiu":
				d["y"] = lerpf(d["base"].position.y, d["from_y"], k * k)

# ---------------------------------------------------------------- G04 ímã
func _magnet_pull(a: Dictionary, dt: float) -> void:
	var e: Dictionary = a["e"]
	var c: Vector2 = a["d"]["pos"] + Vector2(0, -90)
	var rad := float(e["raio_px"])
	var cap := float(e["teto_px_s"])
	for r in main.robots:
		if not r.alive:
			continue
		var v: Vector2 = c - r.rect().get_center()
		var dist := v.length()
		if dist > rad or dist < 30.0:
			continue
		var fall := 1.0 - dist / rad
		var f := float(e["forca"]) * K() * (0.35 + 0.65 * fall)
		r.push_vx = clampf(r.push_vx + v.normalized().x * f, -cap, cap)
		r.velocity.y += v.normalized().y * f * 3.0 * dt
	if main.demo.spells != null:
		for b in main.demo.spells.boxes:   # caixas de spell escorregam um pouco
			var v2: Vector2 = c - b["pos"]
			if v2.length() < rad and v2.length() > 40.0:
				b["pos"].x += signf(v2.x) * 60.0 * dt

# ---------------------------------------------------------------- G06 entulho
func _drop_crate(p: Vector2, kind := "") -> void:
	var e := ev("G06")
	while crates.filter(func(c): return c["state"] != "quebrou").size() >= int(e["max_objetos"]):
		_break_crate(crates[0])
	if kind == "":
		kind = "g06_caixa" if randf() < 0.55 else "g06_sucata"
	crates.append({"pos": Vector2(p.x, _pr().position.y - 90.0), "vy": 0.0, "floor": p.y, "kind": kind,
		"state": "cai", "life": float(e["vida_s"]), "hp": 2, "body": null, "flash": 0.0, "rot": randf_range(-0.3, 0.3)})
	Audio.play("arremesso", 0.7, -6.0)

func crate_rect(c: Dictionary) -> Rect2:
	return Rect2(c["pos"].x - 28.0, c["pos"].y - 52.0, 56.0, 52.0)

func _update_crates(dt: float) -> void:
	for c in crates.duplicate():
		c["flash"] = maxf(c["flash"] - dt, 0.0)
		if c["state"] == "cai":
			c["vy"] = minf(c["vy"] + 2600.0 * dt, 1500.0)
			c["pos"].y += c["vy"] * dt
			c["rot"] *= 0.96
			if c["pos"].y >= c["floor"]:
				c["pos"].y = c["floor"]
				var r := crate_rect(c)
				var hit := false
				for rb in main.robots:
					if rb.alive and rb.rect().intersects(r.grow(2)):
						rb.take_hit(1 if rb.position.x >= c["pos"].x else -1, "evento_entulho", -1)
						hit = true
				main.dust(Vector2(c["pos"].x, c["floor"]), 1.0)
				main.shake(3.0)
				if hit or not _solid_px(Vector2(c["pos"].x, c["floor"] + 8.0)):
					_break_crate(c)
					continue
				c["state"] = "chao"
				c["rot"] = 0.0
				Audio.play("caixote_pancada", 0.7, 0.0)
				var body := StaticBody2D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var cs := CollisionShape2D.new()
				var shp := RectangleShape2D.new()
				shp.size = r.size
				cs.shape = shp
				cs.position = r.get_center()
				body.add_child(cs)
				add_child(body)
				c["body"] = body
		elif c["state"] == "chao":
			c["life"] -= dt
			if c["life"] <= 0.0 or not _solid_px(Vector2(c["pos"].x, c["floor"] + 8.0)):
				_break_crate(c)

func _break_crate(c: Dictionary) -> void:
	if c["body"] != null and is_instance_valid(c["body"]):
		c["body"].queue_free()
	c["body"] = null
	crates.erase(c)
	var mid: Vector2 = crate_rect(c).get_center()
	main.dust(mid, 1.0)
	Audio.play("caixote_quebra", 1.0, -3.0)
	for k in 7:
		bits.append({"pos": mid + Vector2(randf_range(-20, 20), randf_range(-16, 16)), "vel": Vector2(randf_range(-260, 260), randf_range(-520, -200)),
			"t": 0.0, "life": 0.9, "kind": "lasca", "rot": randf() * TAU, "spin": randf_range(-10, 10), "size": randf_range(6, 12),
			"col": Color("#c98a4b") if c["kind"] == "g06_caixa" else Color("#3c9a46")})

## Marretada acerta entulho? (golpe forte quebra; 2 fracos quebram)
func hammer_hit(r: Rect2, heavy: bool, by := -1) -> bool:
	var g = inst("G05")
	if g != null and g["phase"] == "ativo" and String(g["d"].get("state", "")) == "parada" and float(g["d"].get("crack", 0.0)) <= 0.0 and hook_rect(g).intersects(r):
		g["d"]["hook_hp"] = int(g["d"].get("hook_hp", 2)) - (2 if heavy else 1)
		main.spark(hook_rect(g).get_center(), 6)
		Audio.play("chave", 0.7, 0.0)
		main.shake(3.0)
		if int(g["d"]["hook_hp"]) <= 0:
			g["d"]["crack"] = 0.3   # range um instante (quem está embaixo vê) e solta
			g["d"]["by"] = by
			Audio.play("serra", 0.6, -4.0)
		return true
	for c in crates.duplicate():
		if c["state"] == "chao" and crate_rect(c).intersects(r):
			c["hp"] -= 2 if heavy else 1
			c["flash"] = 0.15
			Audio.play("caixote_pancada", 1.0, -2.0)
			if c["hp"] <= 0:
				_break_crate(c)
			return true
	return false

## Sólido que para tiros (entulho e tapumes): cobertura de verdade.
func hard_at(p: Vector2) -> bool:
	for c in crates:
		if c["state"] == "chao" and crate_rect(c).has_point(p):
			return true
	var a = inst("G11")
	if a != null:
		for w in a["d"]["walls"]:
			if w["body"] != null and Rect2(w["x"], w["y"] - w["h"], w["w"], w["h"]).has_point(p):
				return true
	return false

## Onde gancho/carga podem grudar (carga do guindaste e viga caída também).
func grab_at(p: Vector2) -> bool:
	if hard_at(p):
		return true
	var a = inst("G05")
	if a != null and a["d"].get("body") != null:
		var r: Rect2 = a["d"]["rect"]
		if Rect2(r.position.x, a["d"]["y"], r.size.x, 26).grow(4).has_point(p):
			return true
	var b = inst("G13")
	if b != null and b["d"].get("body") != null:
		var br: Rect2 = b["d"]["base"]
		if Rect2(br.position.x, b["d"]["y"], br.size.x, 26).grow(4).has_point(p):
			return true
	return false

# ---------------------------------------------------------------- G05 guindaste
## Desce e trava; ao travar, uma caixa especial de spell desce de paraquedas EM CIMA da carga (motivo para subir).
## Quem sobe pode MARRETAR O GANCHO (pesada quebra; 2 rápidas também): ele range e a carga despenca na faixa da sombra,
## acertando quem estiver embaixo (crédito para quem marretou).
func _crane_step(a: Dictionary, dt: float, pa: float) -> void:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	var r: Rect2 = d["rect"]
	match String(d.get("state", "")):
		"", "parada":
			var top := _pr().position.y - 260.0
			var kd := clampf(pa / float(e["desce_s"]), 0.0, 1.0)
			d["y"] = lerpf(top, r.position.y, 1.0 - pow(1.0 - kd, 3.0))
			if d["body"] != null and is_instance_valid(d["body"]):
				d["body"].position = Vector2(0, d["y"] - r.position.y)
			if kd >= 1.0 and not d.get("locked", false):
				d["locked"] = true
				d["state"] = "parada"
				Audio.play("chave", 0.8, 0.0)
				main.dust(r.get_center() + Vector2(0, 10), 0.6)
				if main.demo.spells != null:
					main.demo.spells.spawn_box(Vector2(r.get_center().x, r.position.y), true)
			if float(d.get("crack", 0.0)) > 0.0:
				d["crack"] = float(d["crack"]) - dt
				if randf() < 0.6:
					_spark_bit(hook_rect(a).get_center() + Vector2(randf_range(-12, 12), 20))
				if float(d["crack"]) <= 0.0:
					if d["body"] != null and is_instance_valid(d["body"]):
						d["body"].queue_free()
					d["body"] = null
					d["state"] = "cai"
					d["vy"] = 0.0
					d["floor"] = _floor_under_rect(r, null)
					Audio.play("caixote_quebra", 0.5, 0.0)
					main.float_text(r.get_center() + Vector2(0, -150), "SOLTOU!", Color.WHITE)
		"cai":
			d["vy"] = minf(float(d["vy"]) + 2600.0 * dt, 1600.0)
			d["y"] = float(d["y"]) + float(d["vy"]) * dt
			var fl: float = d["floor"]
			if fl > 0.0 and float(d["y"]) + 26.0 >= fl:
				d["y"] = fl - 26.0
				var hr := Rect2(r.position.x, fl - 40.0, r.size.x, 40.0)
				for rb in main.robots:
					if rb.alive and rb.rect().intersects(hr):
						rb.take_hit(1 if rb.position.x >= r.get_center().x else -1, "evento_carga", int(d.get("by", -1)))
				main.shake(12.0)
				Audio.play("terremoto", 1.6, -4.0)
				for x in range(int(r.position.x), int(r.end.x), 48):
					main.dust(Vector2(x + 24, fl), 1.2)
				d["state"] = "caiu"
				a["t"] = minf(a["t"], 0.01)   # vai para o fim: some numa nuvem de poeira
			elif float(d["y"]) > _pr().end.y + 300.0:
				d["state"] = "caiu"
				a["t"] = minf(a["t"], 0.01)

## Moitão (gancho) do guindaste: alvo da marretada.
func hook_rect(a: Dictionary) -> Rect2:
	var r: Rect2 = a["d"]["rect"]
	return Rect2(r.get_center().x - 30.0, float(a["d"]["y"]) - 176.0, 60.0, 136.0)

## Onde a caixa de spell para em cima de algo do evento (carga do guindaste, entulho, viga caída). -1 = nada.
func top_at(x: float, y: float) -> float:
	var g = inst("G05")
	if g != null and g["d"].get("body") != null:
		var r: Rect2 = g["d"]["rect"]
		var ty := float(g["d"]["y"])
		if x >= r.position.x and x <= r.end.x and y >= ty - 2.0 and y <= ty + 30.0:
			return ty
	for c in crates:
		if c["state"] == "chao" and absf(c["pos"].x - x) < 30.0:
			var ty2: float = crate_rect(c).position.y
			if y >= ty2 - 2.0 and y <= ty2 + 26.0:
				return ty2
	return -1.0

# ---------------------------------------------------------------- G13 viga
func _beam_step(a: Dictionary, dt: float) -> void:
	var d: Dictionary = a["d"]
	var ct = _canteiro()
	var base: Rect2 = d["base"]
	match d["state"]:
		"cai":
			d["vy"] = minf(d["vy"] + 2600.0 * dt, 1600.0)
			d["y"] += d["vy"] * dt
			var fl: float = d["floor"]
			if fl > 0.0 and d["y"] + 26.0 >= fl:
				d["y"] = fl - 26.0
				var r := Rect2(base.position.x, d["y"], base.size.x, 26.0)
				for rb in main.robots:
					if rb.alive and rb.rect().intersects(r.grow_individual(4, 0, 4, 10)):
						rb.take_hit(1 if rb.position.x >= r.get_center().x else -1, "evento_viga", -1)
				d["body"] = _oneway_body(r)
				d["state"] = "chao"
				main.shake(10.0)
				Audio.play("caixote_quebra", 0.6, 0.0)
				Audio.play("terremoto", 2.0, -6.0)
				for x in range(int(r.position.x), int(r.end.x), 48):
					main.dust(Vector2(x + 24, fl), 1.0)
			elif d["y"] > _pr().end.y + 300.0:
				d["state"] = "sumiu"
		"chao":
			var cx := base.get_center().x
			if not _solid_px(Vector2(cx, d["y"] + 26.0 + 8.0)) and not _solid_px(Vector2(base.position.x + 24.0, d["y"] + 34.0)) and not _solid_px(Vector2(base.end.x - 24.0, d["y"] + 34.0)):
				if d["body"] != null and is_instance_valid(d["body"]):
					d["body"].queue_free()
				d["body"] = null
				d["floor"] = _floor_under_rect(Rect2(base.position.x, d["y"] + 30.0, base.size.x, 26.0), d["p"])
				d["state"] = "cai"

func _oneway_body(r: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = r.size
	cs.shape = shp
	cs.position = r.get_center()
	cs.one_way_collision = true
	body.add_child(cs)
	add_child(body)
	return body

func _floor_under_rect(r: Rect2, ignore) -> float:
	var ct = _canteiro()
	var best := -1.0
	for x in [r.get_center().x, r.position.x + 30.0, r.end.x - 30.0]:
		var cy := int(floor(r.end.y / T)) + 1
		for k in 14:
			var c := Vector2i(int(floor(x / T)), cy + k)
			if ct != null and ct.owner_of.has(c) and ct.owner_of[c] == ignore:
				continue
			if main.level.is_solid(c):
				var y := float(c.y * T)
				if best < 0.0 or y < best:
					best = y
				break
	return best

## Fundação (cena sem vigas penduradas): lugar para a viga que desce pelo poço — em cima de uma plataforma sobre estaca
## que está embaixo da boca do poço, 4 tiles acima dela. Rect2() = não há.
func _poco_viga_rect() -> Rect2:
	var ct = _canteiro()
	var et = main.demo.etapas if main.demo != null else null
	if ct == null or et == null or not is_instance_valid(et) or _etapa() < 2:
		return Rect2()
	var lv = main.level
	var h := String(lv.prop("buraco%d" % (_etapa() - 1), "")).split(",")
	var x0 := float(h[0]) * T if h.size() >= 2 else 0.0
	var x1 := float(h[1]) * T if h.size() >= 2 else -1.0
	for p in ct.parts:
		if p["kind"] == "estaca" and int(p["etapa"]) == _etapa() and not p["fallen"] and p["rect"].position.x >= x0 and p["rect"].end.x <= x1:
			var r: Rect2 = p["rect"]
			return Rect2(r.position.x, r.position.y - 4 * T, r.size.x, 26)
	# Fachada: a grua pendura a viga sobre uma prancha com espaço livre acima (nada entre a viga e a prancha)
	for p in ct.parts:
		if p["kind"] == "prancha" and int(p["etapa"]) == _etapa() and not p["fallen"]:
			var r: Rect2 = p["rect"]
			var vr := Rect2(r.position.x, r.position.y - 3 * T, r.size.x, 26)
			var livre: bool = vr.position.y > main.level.area.position.y + T
			for q in ct.parts:
				if q != p and not q["fallen"] and q["rect"].intersects(Rect2(vr.position.x, vr.position.y - T, vr.size.x, r.position.y - vr.position.y + T - 2)):
					livre = false
			if livre:
				return vr
	return Rect2()

func _beam_pick(ct) -> Variant:
	var cands := []
	for p in ct.parts:
		if p["kind"] == "viga" and int(p["etapa"]) == _etapa() and not p["fallen"] and p.get("evt", "") == "" and p["crit_t"] <= 0.0 and p["warn_t"] <= 0.0:
			if _floor_under_rect(p["rect"], p) > 0.0:
				cands.append(p)
	if cands.is_empty():
		return null
	return cands[main.rng.randi() % cands.size()]

# ---------------------------------------------------------------- G12 andaimes
func _scaffold_moves(ct) -> Array:
	var ands: Array = ct.parts.filter(func(p): return p["kind"] in ["andaime", "estaca", "prancha"] and int(p["etapa"]) == _etapa() and not p["fallen"] and p.get("evt", "") == "" and p["crit_t"] <= 0.0)
	if ands.is_empty():
		return []
	ands.shuffle()
	var e := ev("G12")
	var out := []
	var plan := [-float(e["subir_tiles"]) - (1.0 if K() > 1.1 else 0.0), float(e["descer_tiles"])]
	for i in ands.size():
		var p: Dictionary = ands[i]
		var dy: float = plan[i % 2] * T
		if not _deck_clear(ct, p, dy):
			dy = -dy if _deck_clear(ct, p, -dy) else 0.0
		if dy != 0.0:
			out.append({"p": p, "base": p["rect"].position.y, "dy": dy})
	return out

## O deque pode ir para base+dy sem prender ninguém? (cabe um robô em cima e embaixo)
func _deck_clear(ct, p: Dictionary, dy: float) -> bool:
	var r: Rect2 = p["rect"]
	var nr := Rect2(r.position.x, r.position.y + dy, r.size.x, r.size.y)
	var zone := nr.grow_individual(0, 96, 0, 84)
	for q in ct.parts:
		if q != p and not q["fallen"] and zone.intersects(q["rect"]):
			return false
	for x in range(int(zone.position.x) + 8, int(zone.end.x), 32):
		for y in range(int(zone.position.y), int(zone.end.y), 32):
			var c := Vector2i(int(floor(x / float(T))), int(floor(y / float(T))))
			if ct.owner_of.has(c) and ct.owner_of[c] == p:
				continue
			if main.level.is_solid(c):
				return false
	return _pr().grow(-40).has_point(nr.position)

# ---------------------------------------------------------------- G14 rebites
func _new_wave(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var pr := _vr()
	var w := 192.0
	var cols := int(pr.size.x / w)
	var m := clampi(int(round(float(a["e"]["faixas"]) * K())), 1, maxi(int(cols * 0.45), 1))
	var idx := range(cols)
	idx.shuffle()
	var bands := []
	for i in m:
		bands.append(Rect2(pr.position.x + idx[i] * w + (pr.size.x - cols * w) / 2.0, pr.position.y, w, pr.size.y))
	d["bands"] = bands
	d["wave"] += 1
	d["wave_t"] = 0.0
	d["spawn"] = 0.0
	d["hits"] = {}
	Audio.play("pistao_aviso", 1.4, -6.0)

func _tick_rivets(a: Dictionary, dt: float, _age: float) -> void:
	var e: Dictionary = a["e"]
	var d: Dictionary = a["d"]
	if d["wave"] >= d["waves"]:
		return
	var marca := float(e["marca_s"])
	if a["phase"] == "aviso":
		d["wave_t"] = minf(d["wave_t"] + dt, marca)   # a 1ª onda fica marcada durante todo o aviso
		return
	d["wave_t"] += dt
	var chuva := float(e["chuva_s"])
	if a["phase"] == "ativo" and d["wave_t"] >= marca and d["wave_t"] < marca + chuva:
		d["spawn"] += dt * float(e["rebites_s"]) * clampf(K(), 0.8, 1.3)
		while d["spawn"] >= 1.0 and rivets.size() < 70:
			d["spawn"] -= 1.0
			var b: Rect2 = d["bands"][randi() % d["bands"].size()]
			rivets.append({"pos": Vector2(randf_range(b.position.x + 10, b.end.x - 10), b.position.y - 40.0), "vy": randf_range(1300, 1650),
				"state": "cai", "t": 0.0, "hits": d["hits"]})
	if a["phase"] == "ativo" and d["wave_t"] >= marca + chuva + float(e["pausa_s"]):
		if d["wave"] + 1 < d["waves"]:
			_new_wave(a)
		else:
			d["wave"] = d["waves"]
	if a["phase"] == "ativo" and d["wave"] >= d["waves"]:
		a["t"] = minf(a["t"], 0.6)

func _update_rivets(dt: float) -> void:
	var sp = main.demo.spells if main.demo != null else null
	for rv in rivets:
		rv["t"] += dt
		if rv["state"] != "cai":
			continue
		var prev: Vector2 = rv["pos"]
		rv["pos"].y += rv["vy"] * dt
		var p: Vector2 = rv["pos"]
		var stop := false
		for r in main.robots:
			if r.alive and r.rect().grow(6).has_point(p):
				if not rv["hits"].has(r.pid):
					rv["hits"][r.pid] = true
					r.take_hit(1 if randf() < 0.5 else -1, "evento_rebite", -1)
				main.spark(p, 3)
				stop = true
				break
		if not stop and prev.y > _pr().position.y and (_solid_px(p) or (sp != null and sp._grab_at(p))):
			rv["pos"].y = floor(p.y / 4.0) * 4.0
			rv["state"] = "cravado"
			rv["t"] = 0.0
			if randf() < 0.35:
				main.spark(p, 2)
			if randf() < 0.25:
				Audio.play("chave", randf_range(1.6, 2.2), -12.0)
			continue
		if stop:
			rv["state"] = "sumiu"
		if p.y > _pr().end.y + 100.0:
			rv["state"] = "sumiu"
	rivets = rivets.filter(func(rv): return rv["state"] == "cai" or (rv["state"] == "cravado" and rv["t"] < 1.2))

# ---------------------------------------------------------------- lugares
## Chão firme livre (pés em p): não é borda que vai cair, nem perto de nascimento, nem em entulho/tapume.
## Pontos de chão livre da cena atual. Varre só a área da cena (não o mapa inteiro) e guarda o resultado por 0,25 s:
## era chamada várias vezes por quadro (elegibilidade dos eventos + porcas da G03, 14×/s) e travava o jogo (avaliação 2026-11-26).
var _gs_cache := {}
func _ground_spots(free_tiles := 3) -> Array:
	var ck: Dictionary = _gs_cache.get(free_tiles, {})
	if not ck.is_empty() and t - float(ck["t"]) < 0.25 and ck["area"] == main.level.area:
		return (ck["out"] as Array).duplicate()   # cópia: quem chama embaralha/ordena
	var out := _ground_spots_scan(free_tiles)
	_gs_cache[free_tiles] = {"t": t, "out": out, "area": main.level.area}
	return out.duplicate()

func _ground_spots_scan(free_tiles: int) -> Array:
	var out := []
	var lv = main.level
	var ct = _canteiro()
	var pr := _pr().grow(-96)
	for y in range(maxi(2, int(pr.position.y / T) - 1), mini(lv.rows, int(pr.end.y / T) + 2)):
		for x in range(maxi(0, int(pr.position.x / T) - 1), mini(lv.cols, int(pr.end.x / T) + 2)):
			var c := Vector2i(x, y)
			if not lv.is_solid(c) or lv.is_solid(c + Vector2i.UP) or lv.is_solid(c + Vector2i(0, -2)) or (free_tiles >= 3 and lv.is_solid(c + Vector2i(0, -3))):
				continue
			if lv.ch_at(c) in ["^", "I"]:
				continue
			if ct != null and ct.owner_of.has(c):
				var p: Dictionary = ct.owner_of[c]
				if not (p["kind"] in ["laje", "terreo"]) or p["fallen"] or p["crit_t"] > 0.0 or p["warn_t"] > 0.0:
					continue
			var pos := Vector2(x * T + 32, y * T)
			if not pr.has_point(pos):
				continue
			var near := false
			for s in lv.spawns.values():
				if absf(s.x - pos.x) < 128.0 and absf(s.y - pos.y) < 100.0:
					near = true
			for cr in crates:
				if absf(cr["pos"].x - pos.x) < 80.0 and absf(cr["floor"] - pos.y) < 40.0:
					near = true
			if not near:
				out.append(pos)
	return out

func _wall_spots() -> Array:
	var g := _ground_spots()
	var seen := {}
	for p in g:
		seen[Vector2i(int(p.x), int(p.y))] = true
	var out := []
	for p in g:
		if seen.has(Vector2i(int(p.x) + T, int(p.y))):
			out.append(Vector2(p.x - 32.0, p.y))   # x = canto esquerdo da faixa de 2 tiles
	return out

func _coil_spot() -> Variant:
	var g := _ground_spots()
	if g.is_empty():
		return null
	var cx := _pr().get_center().x
	g.sort_custom(func(a, b): return absf(a.x - cx) < absf(b.x - cx))
	return g[main.rng.randi() % mini(6, g.size())]

## G05: onde a carga do guindaste estaciona (no ar, com espaço para subir nela e passar embaixo, sem nada acima).
func _crane_spot() -> Variant:
	var ct = _canteiro()
	if ct == null:
		return null
	var pr := _pr()
	var cands := []
	var chao_y: int = ct.LAJE_Y
	var topo := pr.position.y - 200.0   # Térreo: céu aberto acima
	if chao_y * T < pr.position.y or chao_y * T > pr.end.y:   # Fundação/Fachada: o chão da cena atual (não a laje do Térreo)
		topo = INF   # cena coberta (Fundação): basta folga de 3 blocos acima da carga (não o céu livre)
		var gs := _ground_spots(2)
		if gs.is_empty():
			return null
		var ys: Array = gs.map(func(p): return int(p.y / T))
		ys.sort()
		chao_y = ys[ys.size() / 2]
	for row in [chao_y - 4, chao_y - 3, chao_y - 5]:
		if row * T < pr.position.y + 2 * T or row * T > pr.end.y:
			continue   # linha fora da cena atual: Rect2 negativo a cada quadro
		for xi in range(int(pr.position.x / T) + 2, int(pr.end.x / T) - 6):
			var r := Rect2(xi * T, row * T, 4 * T, 26)
			var ok := true
			var zone := r.grow_individual(48, 110, 48, 100)
			var top_y: float = topo if topo != INF else r.position.y - 3.0 * T
			var above := Rect2(r.position.x - 16, top_y, r.size.x + 32, r.position.y - top_y)
			for p in ct.parts:
				if not p["fallen"] and (zone.intersects(p["rect"]) or above.intersects(p["rect"])):
					ok = false
					break
			if ok:
				for x in range(int(zone.position.x), int(zone.end.x), 32):
					for y in range(int(maxf(above.position.y, pr.position.y)), int(zone.end.y), 32):
						if main.level.is_solid(Vector2i(int(floor(x / float(T))), int(floor(y / float(T))))):
							ok = false
			if ok:
				cands.append(r)
	if cands.is_empty():
		return null
	var cx := pr.get_center().x
	cands.sort_custom(func(a, b): return absf(a.get_center().x - cx) < absf(b.get_center().x - cx))
	return cands[main.rng.randi() % mini(4, cands.size())]

func _pick_spots() -> Array:
	var pts: Array = main.demo.spells.spawn_points()
	pts.shuffle()
	var a: Vector2 = pts[0]["pos"]
	var b: Vector2 = pts[1]["pos"]
	for q in pts:   # o segundo o mais longe possível do primeiro (disputa dos dois lados)
		if q["pos"].distance_to(a) > b.distance_to(a):
			b = q["pos"]
	var out := [a, b]
	var n: int = main.rng.randi_range(int(cfg_ev("G10").get("caixas", [1, 3])[0]), int(cfg_ev("G10").get("caixas", [1, 3])[1]))
	for q in pts:   # a 3ª (se sair) longe das outras duas
		if out.size() >= 3:
			break
		if q["pos"].distance_to(a) > 300.0 and q["pos"].distance_to(b) > 300.0:
			out.append(q["pos"])
	return out.slice(0, maxi(n, 1))

func cfg_ev(id: String) -> Dictionary:
	for e in cfg["lista"]:
		if e["id"] == id:
			return e
	return {}

# ---------------------------------------------------------------- partículas
func _update_bits(dt: float) -> void:
	for b in bits:
		b["t"] += dt
		b["pos"] += b["vel"] * dt
		b["rot"] += b.get("spin", 0.0) * dt
		match b["kind"]:
			"lasca", "faisca":
				b["vel"].y += 1400.0 * dt
			"porca":
				b["vel"].x += sin(t * 2.0 + b["size"]) * 20.0 * dt
	bits = bits.filter(func(b): return b["t"] < b["life"])

func _streak_bit(dir: int) -> void:
	var pr := _vr()
	var x := pr.position.x - 80.0 if dir > 0 else pr.end.x + 80.0
	bits.append({"pos": Vector2(x, randf_range(pr.position.y + 40, pr.end.y - 20)), "vel": Vector2(dir * randf_range(1300, 1900), randf_range(-20, 20)),
		"t": 0.0, "life": 1.6, "kind": "vento", "rot": 0.0, "size": randf_range(60, 160)})

const PORCAS_MAX := 24        # G03: teto de porcas no ar (eram ~45, cada uma 4 comandos de desenho → +1,3 ms e +210 chamadas)
const PORCA_PX := 32
const PORCA_QUADROS := 6       # sextavada: 0–60° bastam; 6 giros pré-desenhados num atlas (1 textura = desenho em lote)
static var _porca_tex: ImageTexture

## Atlas das porcas (desenhado 1×, por código): corpo cinza, aro escuro, furo.
static func porca_tex() -> ImageTexture:
	if _porca_tex != null:
		return _porca_tex
	var img := Image.create(PORCA_PX * PORCA_QUADROS, PORCA_PX, false, Image.FORMAT_RGBA8)
	var c := PORCA_PX / 2.0
	var ap := (c - 1.5) * cos(PI / 6.0)
	for f in PORCA_QUADROS:
		var rot := f * (PI / 3.0) / PORCA_QUADROS
		for y in PORCA_PX:
			for x in PORCA_PX:
				var v := Vector2(x + 0.5 - c, y + 0.5 - c)
				var m := 0.0
				for k in 3:
					m = maxf(m, absf(v.dot(Vector2.from_angle(rot + PI / 6.0 + k * PI / 3.0))))
				var cor := Color(0.79, 0.82, 0.85)
				if m > ap - 2.2:
					cor = Color(0.42, 0.47, 0.51)
				if v.length() < c * 0.42:
					cor = Color(0.16, 0.1, 0.18)
				cor.a = clampf(ap + 0.5 - m, 0.0, 1.0)
				img.set_pixel(f * PORCA_PX + x, y, cor)
	_porca_tex = ImageTexture.create_from_image(img)
	return _porca_tex

func _nut_bit(speed: float) -> void:
	var n := 0
	for b in bits:
		if b["kind"] == "porca":
			n += 1
	if n >= PORCAS_MAX:
		return
	var g := _ground_spots()
	var pr := _pr()
	var p: Vector2 = g[randi() % g.size()] if not g.is_empty() else Vector2(randf_range(pr.position.x, pr.end.x), pr.end.y - 64)
	bits.append({"pos": p + Vector2(randf_range(-30, 30), -6), "vel": Vector2(randf_range(-20, 20), -randf_range(50, 110) * speed),
		"t": 0.0, "life": 3.2, "kind": "porca", "rot": randf() * TAU, "spin": randf_range(-2, 2), "size": randf_range(9, 15)})

func _spark_bit(p: Vector2) -> void:
	bits.append({"pos": p, "vel": Vector2(randf_range(-240, 240), randf_range(-320, -60)), "t": 0.0, "life": 0.5, "kind": "faisca", "rot": 0.0, "size": randf_range(3, 5)})

# ================================================================ desenho (atrás dos robôs)
func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_eventos", _pf)

func _draw_perf() -> void:
	for c in crates:
		_draw_crate(c)
	for a in active:
		match a["id"]:
			"G10":
				if a["phase"] == "aviso":
					_draw_spotlights(a)
			"G02":
				_draw_fans(a)
			"G04":
				_draw_coil(a)
			"G05":
				_draw_crane(a)
			"G06", "V2":
				_draw_crate_shadows(a)
			"V1":
				_draw_concrete(a)
			"V3":
				if a["phase"] == "aviso":
					var ag = _agua()
					if ag != null and fmod(t, 0.3) < 0.18:
						var ad: Dictionary = ag["d"]
						var top := float(ad["chao"]) - float(ad["altura"]) * float(a["e"]["altura_mult"])
						draw_rect(Rect2(float(ad["x"][0]), top, float(ad["x"][1]) - float(ad["x"][0]), 8), Color(0.31, 0.53, 0.66, 0.8))
			"G11":
				_draw_walls(a)
			"G12":
				_draw_scaffold_move(a)
			"G13":
				_draw_beam(a)
			"G14":
				_draw_bands(a)

## Faixa zebrada (listras diagonais correndo); só desenha listras inteiras dentro da faixa.
func _hatch(r: Rect2, c1: Color, c2: Color, step := 22.0, scroll := 0.0) -> void:
	draw_rect(r, c1)
	var h := r.size.y
	var x := r.position.x + fmod(scroll, step * 2.0) - step * 2.0
	while x < r.end.x:
		if x >= r.position.x and x + step + h <= r.end.x:
			draw_colored_polygon(PackedVector2Array([Vector2(x, r.end.y), Vector2(x + step, r.end.y), Vector2(x + step + h, r.position.y), Vector2(x + h, r.position.y)]), c2)
		x += step * 2.0

func _beacon(p: Vector2, col: Color, on: bool, size := 9.0) -> void:
	draw_circle(p, size + 3.0, INK)
	draw_circle(p, size, col if on else col.darkened(0.55))
	if on:
		draw_circle(p, size * 3.0, Color(col.r, col.g, col.b, 0.22))

func _draw_spotlights(a: Dictionary) -> void:
	var k := 1.0 - clampf(a["t"] / a["len"], 0.0, 1.0)
	var sp: Array = a["d"]["spots"]
	for i in sp.size():
		var p: Vector2 = sp[i]
		var top := Vector2(p.x + (1.0 - k) * (240.0 if i == 0 else -240.0) * sin(t * 2.0), p.y - 900.0)
		var w := 70.0
		draw_colored_polygon(PackedVector2Array([top + Vector2(-14, 0), top + Vector2(14, 0), p + Vector2(w, 0), p + Vector2(-w, 0)]), Color(1.0, 0.95, 0.7, 0.16 + 0.08 * sin(t * 10.0)))
		draw_set_transform(p + Vector2(0, -4), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, w, Color(1.0, 0.95, 0.7, 0.35))
		draw_set_transform(Vector2.ZERO)
		var ay := p.y - 120.0 - absf(sin(t * 6.0)) * 18.0
		var tri := PackedVector2Array([Vector2(p.x - 22, ay - 26), Vector2(p.x + 22, ay - 26), Vector2(p.x, ay)])
		draw_colored_polygon(tri, YEL)
		draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), INK, 4.0, true)

## G02: 3 exaustores na borda de onde vem o vento (entram deslizando no aviso, saem no fim).
func _draw_fans(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var pr := _vr()
	var dir: int = d["dir"]
	var slide := 1.0
	if a["phase"] == "aviso":
		slide = clampf((a["len"] - a["t"]) / 0.5, 0.0, 1.0)
	elif a["phase"] == "fim":
		slide = clampf(a["t"] / a["len"] * 1.5, 0.0, 1.0)
	var x := pr.position.x + lerpf(-120.0, 70.0, slide) if dir > 0 else pr.end.x - lerpf(-120.0, 70.0, slide)
	for i in 3:
		var y := pr.position.y + pr.size.y * (0.22 + 0.27 * i)
		var c := Vector2(x, y)
		draw_texture_rect(tex["g02_exaustor"], Rect2(c - Vector2(80, 80), Vector2(160, 160)), false)
		draw_set_transform(c, d["ang"] * (1.0 + 0.1 * i) * dir, Vector2.ONE)
		draw_texture_rect(tex["g02_helice"], Rect2(-64, -64, 128, 128), false, Color(1, 1, 1, 1.0 - 0.45 * clampf(d["spin"], 0.0, 1.0)))
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(tex["g02_grade"], Rect2(c - Vector2(80, 80), Vector2(160, 160)), false)
		# setas: para onde o vento empurra (piscam no aviso)
		if a["phase"] != "fim":
			var on: bool = a["phase"] == "ativo" or fmod(t, 0.4) < 0.25
			for k in 3:
				var ax := c.x + dir * (110.0 + k * 46.0 + fmod(t * 120.0, 46.0) * (1.0 if a["phase"] == "ativo" else 0.0))
				var col := Color(1, 1, 1, (0.85 - k * 0.22) * (1.0 if on else 0.3))
				var tri := PackedVector2Array([Vector2(ax - dir * 16, y - 22), Vector2(ax + dir * 14, y), Vector2(ax - dir * 16, y + 22)])
				draw_polyline(tri, INK, 13.0, true)
				draw_polyline(tri, col, 7.0, true)

## G04: bobina sobe do chão; campo tracejado; pulsos = anéis que encolhem até a bobina.
func _draw_coil(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var p: Vector2 = d["pos"]
	var e: Dictionary = a["e"]
	var rad := float(e["raio_px"])
	var rise := 1.0
	if a["phase"] == "aviso":
		rise = clampf((a["len"] - a["t"]) / 0.5, 0.0, 1.0)
	elif a["phase"] == "fim":
		rise = clampf(a["t"] / a["len"], 0.0, 1.0)
	var c := p + Vector2(0, -90)
	# área: círculo tracejado roxo + chão marcado
	var alpha := 0.35 + 0.25 * sin(t * (14.0 if a["phase"] == "aviso" else 5.0))
	var n := 48
	for i in n:
		if i % 2 == 0:
			var a0 := TAU * i / n + t * 0.4
			draw_arc(c, rad, a0, a0 + TAU / n, 4, Color(0.54, 0.39, 0.82, alpha * rise), 6.0, true)
	draw_circle(c, rad, Color(0.54, 0.39, 0.82, 0.06 * rise))
	if a["phase"] == "ativo":
		var pk := 1.0 - clampf(d["pulse"] / 0.45, 0.0, 1.0)
		if d["pulse"] > 0.0:
			for k in 3:
				var rr := rad * (1.0 - fmod(pk + k * 0.33, 1.0))
				draw_arc(c, rr, 0, TAU, 64, Color(0.75, 0.6, 1.0, 0.7 * (rr / rad)), 8.0, true)
		# linhas magnéticas em espiral
		for k in 6:
			var pts := PackedVector2Array()
			for s in 12:
				var f := s / 11.0
				var ang := TAU * k / 6.0 + t * 1.6 + f * 2.2
				pts.append(c + Vector2.from_angle(ang) * lerpf(rad * 0.85, 40.0, f))
			draw_polyline(pts, Color(0.75, 0.6, 1.0, 0.35), 3.0, true)
	# a bobina
	var h := 160.0 * rise
	if h > 2.0:
		draw_texture_rect_region(tex["g04_bobina"], Rect2(p.x - 56, p.y - h, 112, h), Rect2(0, 0, 224, 320.0 * rise))
		var glow: float = 0.5 + 0.5 * sin(t * 20.0) if a["phase"] != "fim" else 0.0
		if rise >= 1.0:
			draw_circle(p + Vector2(0, -146), 18.0 + 8.0 * glow, Color(0.75, 0.6, 1.0, 0.35))
			if a["phase"] == "ativo" and randf() < 0.5:
				var q := p + Vector2(0, -146)
				var pts2 := PackedVector2Array([q])
				var dirv := Vector2.from_angle(randf() * TAU)
				for s in 4:
					q += dirv * 22.0 + Vector2(randf_range(-10, 10), randf_range(-10, 10))
					pts2.append(q)
				draw_polyline(pts2, Color("#d9c8ff"), 3.0, true)
	draw_set_transform(p + Vector2(0, -2), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO)

## G05: guindaste. Aviso: fantasma do lugar + cabo tracejado + sombra listrada no chão. Ativo: a carga desce balançando.
func _draw_crane(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var r: Rect2 = d["rect"]
	var pr := _pr()
	var cx := r.get_center().x
	# sombra no chão embaixo da parada
	var fl := _floor_under_rect(r, null)
	if fl > 0.0 and a["phase"] != "fim":
		var sk: float = 0.5 + 0.5 * clampf((d["y"] - (pr.position.y - 260.0)) / maxf(r.position.y - pr.position.y + 260.0, 1.0), 0.0, 1.0)
		_hatch(Rect2(r.position.x + 10, fl - 10, r.size.x - 20, 10), Color(0, 0, 0, 0.18 * sk), Color(0.95, 0.78, 0.29, 0.5 * sk), 14.0, t * 40.0)
	if a["phase"] == "aviso":
		var blink := fmod(t, 0.4) < 0.25
		draw_rect(r.grow(3), Color(1, 1, 1, 0.12 if blink else 0.05))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 26)), Color(0.95, 0.78, 0.29, 0.85 if blink else 0.4), false, 4.0)
		var y := pr.position.y
		while y < r.position.y - 40.0:
			draw_line(Vector2(cx, y), Vector2(cx, minf(y + 18.0, r.position.y - 40.0)), Color(1, 1, 1, 0.55), 3.0)
			y += 34.0
		var ay := r.position.y - 60.0 - absf(sin(t * 6.0)) * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 18, ay - 22), Vector2(cx + 18, ay - 22), Vector2(cx, ay)]), YEL)
		return
	var st := String(d.get("state", ""))
	if st == "caiu" or st == "cai":   # despencou: carga solta (some em poeira no fim), cabo partido lá em cima
		var al: float = 1.0 if a["phase"] != "fim" else clampf(a["t"] / a["len"], 0.0, 1.0)
		draw_set_transform(Vector2(cx, float(d["y"]) + 20.0), 0.06 if st == "caiu" else 0.0, Vector2.ONE)
		draw_texture_rect(tex["g05_carga"], Rect2(-r.size.x / 2.0, -26, r.size.x, 56), false, Color(1, 1, 1, al))
		draw_set_transform(Vector2.ZERO)
		draw_line(Vector2(cx, pr.position.y - 300.0), Vector2(cx + sin(t * 9.0) * 20.0, r.position.y - 220.0), Color("#3a3a46"), 5.0, true)
		return
	# carga + moitão + correntes, com balanço que amortece
	var sway := sin(a["age"] * 2.6) * 0.06 * exp(-maxf(a["age"] - float(a["e"]["aviso_s"]), 0.0) * 0.5)
	if float(d.get("crack", 0.0)) > 0.0:
		sway += sin(t * 70.0) * 0.12
	elif int(d.get("hook_hp", 2)) < 2:
		sway += sin(t * 40.0) * 0.04
	var lt := Vector2(cx, d["y"])
	var hook := lt + Vector2(0, -120)
	draw_line(Vector2(cx, pr.position.y - 300.0), hook + Vector2(0, -40), Color("#3a3a46"), 5.0, true)
	draw_set_transform(hook, sway, Vector2.ONE)
	draw_texture_rect(tex["g05_moitao"], Rect2(-40, -52, 80, 112), false)
	_beacon(Vector2(0, -50), Color("#f08a3d"), fmod(t, 0.5) < 0.25, 7.0)
	draw_set_transform(Vector2.ZERO)
	var blink_end: bool = a["phase"] == "ativo" and a["t"] < 1.2 and fmod(t, 0.2) < 0.1
	var hk: Vector2 = hook + Vector2(0, 52).rotated(sway)
	for ex in [r.position.x + 52 + 8, r.end.x - 68 + 8]:
		var end := Vector2(ex, d["y"] + 2)
		var steps := 9
		for s in steps:
			var p := hk.lerp(end, (s + 0.5) / steps)
			draw_set_transform(p, (end - hk).angle(), Vector2.ONE)
			draw_rect(Rect2(-7, -4 if s % 2 == 0 else -2, 14, 8 if s % 2 == 0 else 4), Color("#5a5a66"))
			draw_set_transform(Vector2.ZERO)
	draw_texture_rect(tex["g05_carga"], Rect2(r.position.x, d["y"] - 6, r.size.x, 56), false, Color(1, 0.6, 0.6) if blink_end else Color.WHITE)

## V1 Concretagem: faixas marcadas no aviso; depois concreto fresco brilhando (endurece no fim).
func _draw_concrete(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	for st in d["strips"]:
		var r: Rect2 = st
		if a["phase"] == "aviso":
			var on := fmod(t, 0.4) < 0.25
			_hatch(Rect2(r.position.x, r.end.y - 8, r.size.x, 8), YEL, INK, 12.0, t * 60.0)
			draw_circle(r.get_center() + Vector2(0, -2), 50.0 * (1.0 - a["t"] / a["len"]) + 10.0, Color(0, 0, 0, 0.18 if on else 0.1))
		else:
			var k := clampf(float(d.get("fresh", 0.0)) / 1.5, 0.0, 1.0)
			draw_rect(Rect2(r.position.x, r.end.y - 14, r.size.x, 14), Color(0.72, 0.7, 0.66, 0.4 + 0.6 * k))
			draw_line(Vector2(r.position.x + 12, r.end.y - 10), Vector2(r.end.x - 12, r.end.y - 10), Color(1, 1, 1, 0.5 * k), 3.0)

func _draw_crate(c: Dictionary) -> void:
	var r := crate_rect(c)
	var a := 1.0
	if c["state"] == "chao" and c["life"] < 1.0:
		a = 0.5 + 0.5 * float(fmod(t, 0.2) < 0.1)
	var sc := 1.0
	draw_set_transform(r.get_center(), c["rot"], Vector2(sc, sc))
	draw_texture_rect(tex[c["kind"]], Rect2(-32, -30, 64, 56) if c["kind"] != "pedaco" else Rect2(-40, -34, 80, 66), false, Color(1, 1, 1, a) if c["flash"] <= 0.0 else Color(2, 2, 2, 1))
	draw_set_transform(Vector2.ZERO)

## G06: sombras listradas que crescem antes de cada queda (e durante a queda, até tocar o chão).
func _draw_crate_shadows(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	var spots_: Array = d["spots"]
	var nxt := int(d.get("next", 0))
	for i in spots_.size():
		var p: Vector2 = spots_[i]
		var falling := false
		for c in crates:
			if c["state"] == "cai" and absf(c["pos"].x - p.x) < 2.0:
				falling = true
		if i < nxt and not falling:
			continue
		var k := clampf(a["age"] / maxf(float(a["e"]["aviso_s"]) + i * 0.28, 0.1), 0.2, 1.0)
		var w := 34.0 * k + 4.0 * sin(t * 12.0)
		draw_set_transform(p + Vector2(0, -3), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, w + 6.0, Color(0, 0, 0, 0.25))
		draw_arc(Vector2.ZERO, w + 6.0, 0, TAU, 32, Color(0.95, 0.78, 0.29, 0.9), 6.0, true)
		draw_set_transform(Vector2.ZERO)
		draw_line(p + Vector2(-w * 0.6, -4), p + Vector2(w * 0.6, -4), RED, 4.0, true)
		if not falling:   # "!" sobre o lugar
			var ay := p.y - 60.0 - absf(sin(t * 7.0 + i)) * 10.0
			draw_circle(Vector2(p.x, ay), 16.0, INK)
			draw_circle(Vector2(p.x, ay), 12.0, YEL)
			draw_rect(Rect2(p.x - 2.5, ay - 8, 5, 10), INK)
			draw_rect(Rect2(p.x - 2.5, ay + 4, 5, 4), INK)

## G11: faixa zebrada no chão + luzes; os tapumes sobem (recortados pelo chão) e descem no fim.
func _draw_walls(a: Dictionary) -> void:
	for w in a["d"]["walls"]:
		if w.get("gone", false):
			continue
		var x: float = w["x"]
		var y: float = w["y"]
		var W: float = w["w"]
		var H: float = w["h"]
		var on := fmod(t, 0.5) < 0.25
		if a["phase"] == "aviso":
			_hatch(Rect2(x, y - 12, W, 12), YEL, INK, 12.0, t * 60.0)
			draw_rect(Rect2(x, y - H, W, H), Color(0.95, 0.78, 0.29, 0.12 if on else 0.05))
			draw_rect(Rect2(x, y - H, W, H), Color(0.95, 0.78, 0.29, 0.7 if on else 0.3), false, 3.0)
		var k: float = w["k"] if a["phase"] != "aviso" else 0.0
		var h := H * k
		if h > 1.0:
			for i in 2:
				var px := x + i * 64.0
				draw_texture_rect_region(tex["g11_tapume"], Rect2(px, y - h, 64, h), Rect2(0, 0, 128, 320.0 * k))
		_beacon(Vector2(x - 6, y - 8 - h), Color("#f08a3d"), on, 7.0)
		_beacon(Vector2(x + W + 6, y - 8 - h), Color("#f08a3d"), not on, 7.0)

## G12: correntes tensas até lá em cima, deque fantasma no destino, setas.
func _draw_scaffold_move(a: Dictionary) -> void:
	var pr := _pr()
	for m in a["d"]["moves"]:
		var p: Dictionary = m["p"]
		if p["fallen"]:
			continue
		var r: Rect2 = p["rect"]
		var shake := Vector2(sin(t * 60.0), 0) * (2.0 if a["phase"] == "aviso" else 0.0)
		for ex in [r.position.x + 16.0, r.end.x - 16.0]:
			var top := Vector2(ex, pr.position.y - 20.0)
			var bot := Vector2(ex, r.position.y) + shake
			var n := int((bot.y - top.y) / 16.0)
			for s in n:
				var q := top.lerp(bot, (s + 0.5) / n)
				draw_rect(Rect2(q.x - (5.0 if s % 2 == 0 else 2.0), q.y - 7, 10.0 if s % 2 == 0 else 4.0, 14), Color("#5a5a66"))
			draw_circle(Vector2(ex, pr.position.y + 6.0), 16.0, INK)
			draw_circle(Vector2(ex, pr.position.y + 6.0), 12.0, Color("#9aa4ae"))
			var ga := t * (6.0 if a["phase"] != "aviso" else 1.0)
			for g in 4:
				draw_line(Vector2(ex, pr.position.y + 6.0), Vector2(ex, pr.position.y + 6.0) + Vector2.from_angle(ga + g * PI / 2.0) * 12.0, INK, 3.0)
		if a["phase"] == "aviso":
			var dest := Rect2(r.position.x, m["base"] + m["dy"], r.size.x, r.size.y)
			var blink := fmod(t, 0.4) < 0.25
			draw_rect(dest, Color(1, 1, 1, 0.25 if blink else 0.1))
			draw_rect(dest, Color(0.95, 0.78, 0.29, 0.9 if blink else 0.45), false, 4.0)
			var ax := r.get_center().x
			var y0 := r.position.y + (-30.0 if m["dy"] < 0.0 else r.size.y + 30.0)
			var dirs := signf(m["dy"])
			for k in 2:
				var yy := y0 + dirs * (k * 26.0 + fmod(t * 50.0, 26.0))
				var tri := PackedVector2Array([Vector2(ax - 18, yy - dirs * 10), Vector2(ax, yy + dirs * 10), Vector2(ax + 18, yy - dirs * 10)])
				draw_polyline(tri, INK, 11.0, true)
				draw_polyline(tri, YEL, 6.0, true)

## G13: a viga (o Canteiro não a desenha enquanto o evento cuida dela).
func _draw_beam(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	if d["state"] == "sumiu" and a["phase"] != "fim":
		return
	var base: Rect2 = d["base"]
	var pr := _pr()
	var y: float = d["y"]
	var o := Vector2.ZERO
	if d["state"] == "pendurada":
		o = Vector2(sin(t * 71.0), cos(t * 53.0)) * 3.0
	var cxs := [base.position.x + 40.0, base.end.x - 40.0]
	# sombra / faixa de perigo no chão
	if d["floor"] > 0.0 and (d["state"] == "pendurada" or d["state"] == "cai"):
		var fl: float = d["floor"]
		_hatch(Rect2(base.position.x, fl - 12, base.size.x, 12), Color(0.85, 0.29, 0.23, 0.8), INK, 12.0, t * 60.0)
		draw_rect(Rect2(base.position.x, y + 26, base.size.x, fl - y - 26), Color(0.85, 0.29, 0.23, 0.1 + 0.06 * sin(t * 14.0)))
	# cabos
	match d["state"]:
		"pendurada":
			for i in 2:
				var cx: float = cxs[i]
				var col := Color("#5a4a3a")
				if i == 0:   # o cabo que vai romper: fiapos e faíscas
					var top := Vector2(cx, -500)
					var bot := Vector2(cx, y) + o
					var mid := top.lerp(bot, 0.86)
					draw_line(top, mid + Vector2(-2, 0), col, 4.0, true)
					draw_line(mid + Vector2(2, 4), bot, col, 4.0, true)
					for f in 3:
						draw_line(mid + Vector2(-2, 0), mid + Vector2(-6 + f * 6, 10) + Vector2(sin(t * 30.0 + f), 0) * 2.0, col, 1.5)
					draw_circle(mid + Vector2(0, 2), 5.0 + 2.0 * sin(t * 40.0), Color(1.0, 0.8, 0.3, 0.8))
				else:
					draw_line(Vector2(cx, -500), Vector2(cx, y) + o, col, 4.0, true)
		"cai", "chao":
			if a["phase"] != "fim":
				for cx in cxs:   # pontas do cabo chicoteando lá em cima
					var w := sin(a["age"] * 9.0 + cx) * 30.0 * exp(-a["age"] * 0.3)
					draw_line(Vector2(cx, -500), Vector2(cx + w, base.position.y - 60.0), Color("#5a4a3a"), 4.0, true)
	if a["phase"] == "fim":
		for cx in cxs:
			draw_line(Vector2(cx, pr.position.y - 300.0), Vector2(cx, y), Color("#5a4a3a"), 4.0, true)
			draw_circle(Vector2(cx, y - 4), 6.0, Color("#9aa4ae"))
	var tilt := 0.0
	if d["state"] == "cai":
		tilt = clampf(d["vy"] / 1600.0, 0.0, 1.0) * 0.12
	var ct = _canteiro()
	var tx: Texture2D = ct.tex["viga"] if base.size.x > 300.0 else ct.tex["viga4"]
	draw_set_transform(Vector2(base.get_center().x, y + 13.0) + o, tilt, Vector2.ONE)
	draw_texture_rect(tx, Rect2(-base.size.x / 2.0 - 10.0, -23.0, base.size.x + 20.0, 46), false)
	draw_set_transform(Vector2.ZERO)

## G14: faixas de risco vermelhas (a onda atual) com X no chão; some na chuva.
func _draw_bands(a: Dictionary) -> void:
	var d: Dictionary = a["d"]
	if d["wave"] >= d["waves"] or not d.has("bands"):
		return
	var marca := float(a["e"]["marca_s"])
	var chuva := float(a["e"]["chuva_s"])
	var wt: float = d["wave_t"] if a["phase"] == "ativo" else 0.0
	if wt > marca + chuva:
		return
	var warn := wt < marca
	var blink := fmod(t, 0.24) < 0.14
	for b in d["bands"]:
		var br: Rect2 = b
		draw_rect(br, Color(0.85, 0.29, 0.23, (0.16 if blink else 0.08) if warn else 0.12))
		draw_line(br.position, Vector2(br.position.x, br.end.y), Color(0.85, 0.29, 0.23, 0.6), 4.0)
		draw_line(Vector2(br.end.x, br.position.y), br.end, Color(0.85, 0.29, 0.23, 0.6), 4.0)
		_hatch(Rect2(br.position.x, br.position.y, br.size.x, 14), RED, INK, 12.0, t * 80.0)
		# X vermelhos onde os rebites vão cravar
		for x in range(int(br.position.x) + 24, int(br.end.x), 48):
			var fy := -1.0
			for row in range(int(br.position.y / T) + 1, main.level.rows):
				var c := Vector2i(int(floor(x / float(T))), row)
				if main.level.is_solid(c) and not main.level.is_solid(c + Vector2i.UP):
					fy = row * T
					break
			if fy > 0.0:
				var q := Vector2(x, fy - 8)
				draw_line(q + Vector2(-8, -6), q + Vector2(8, 6), RED, 5.0, true)
				draw_line(q + Vector2(-8, 6), q + Vector2(8, -6), RED, 5.0, true)

# ================================================================ desenho (frente dos robôs)
func _draw_front() -> void:
	var _pf := Perf.t0()
	_draw_front_perf()
	Perf.add("draw_eventos_frente", _pf)

func _draw_front_perf() -> void:
	var fr := front
	for b in bits:
		var k: float = 1.0 - b["t"] / b["life"]
		match b["kind"]:
			"vento":
				var p: Vector2 = b["pos"]
				var dx := signf(b["vel"].x)
				fr.draw_line(p, p - Vector2(dx * b["size"], 0), Color(1, 1, 1, 0.35 * minf(k * 3.0, 1.0)), 4.0, true)
				fr.draw_line(p - Vector2(dx * b["size"] * 0.3, 10), p - Vector2(dx * b["size"] * 0.8, 10), Color(1, 1, 1, 0.2 * minf(k * 3.0, 1.0)), 3.0, true)
			"porca":   # 1 retângulo do atlas por porca (mesma textura: a placa desenha todas juntas)
				var p: Vector2 = b["pos"]
				var sz: float = b["size"]
				var f := int(fposmod(b["rot"], PI / 3.0) / (PI / 3.0) * PORCA_QUADROS) % PORCA_QUADROS
				fr.draw_texture_rect_region(porca_tex(), Rect2(p.x - sz, p.y - sz, sz * 2.0, sz * 2.0), Rect2(f * PORCA_PX, 0, PORCA_PX, PORCA_PX), Color(1, 1, 1, minf(k * 3.0, 1.0)))
			"faisca":
				fr.draw_circle(b["pos"], b["size"] * k + 1.0, Color(1.0, 0.85, 0.4, k))
			"lasca":
				fr.draw_set_transform(b["pos"], b["rot"], Vector2.ONE)
				fr.draw_rect(Rect2(-b["size"] / 2.0, -b["size"] / 3.0, b["size"], b["size"] / 1.5), Color(b["col"].r, b["col"].g, b["col"].b, minf(k * 2.0, 1.0)))
				fr.draw_set_transform(Vector2.ZERO)
	for rv in rivets:
		var p: Vector2 = rv["pos"]
		if rv["state"] == "cai":
			fr.draw_line(p + Vector2(0, -90), p + Vector2(0, -14), Color(1.0, 0.7, 0.4, 0.35), 5.0, true)
			fr.draw_line(p + Vector2(0, -50), p + Vector2(0, -14), Color(1.0, 0.95, 0.8, 0.6), 2.5, true)
			fr.draw_texture_rect(tex["g14_rebite"], Rect2(p.x - 8, p.y - 30, 16, 32), false)
		else:
			var a := clampf(1.2 - rv["t"], 0.0, 1.0)
			fr.draw_texture_rect_region(tex["g14_rebite"], Rect2(p.x - 8, p.y - 16, 16, 16), Rect2(0, 0, 32, 32), Color(1, 1, 1, a))
	for a in active:
		match a["id"]:
			"G03":
				_draw_gauge(fr, a)
		if a["id"] == "G03" and a["phase"] == "ativo":
			for r in main.robots:   # anéis de anti-gravidade embaixo de quem está no ar
				if r.alive and not r.is_on_floor():
					var p: Vector2 = r.position + Vector2(0, 10)
					var ph := fmod(t * 2.0, 1.0)
					fr.draw_set_transform(p, 0.0, Vector2(1.0, 0.3))
					fr.draw_arc(Vector2.ZERO, 20.0 + ph * 18.0, 0, TAU, 24, Color(0.62, 0.89, 0.96, 0.6 * (1.0 - ph)), 4.0, true)
					fr.draw_set_transform(Vector2.ZERO)

## G03: medidor de gravidade no alto (o ponteiro cai no aviso e volta devagar no fim).
func _draw_gauge(fr: Node2D, a: Dictionary) -> void:
	var pr := _vr()
	var c := Vector2(pr.get_center().x, pr.position.y + 170.0)
	var g := gravity_mult
	if a["phase"] == "aviso":
		g = 1.0 - 0.15 * sin(t * 18.0) * clampf((a["len"] - a["t"]) / a["len"], 0.0, 1.0)
	fr.draw_circle(c, 56.0, INK)
	fr.draw_circle(c, 49.0, Color("#eef7f6"))
	fr.draw_arc(c, 40.0, PI * 0.85, PI * 1.5, 16, Color("#9fe3f5"), 9.0)
	fr.draw_arc(c, 40.0, PI * 1.5, PI * 2.15, 16, Color("#5cc45c"), 9.0)
	var ang := lerpf(PI * 0.85, PI * 2.15, clampf((g - 0.3) / 0.9, 0.0, 1.0)) + sin(t * 30.0) * 0.03
	fr.draw_line(c, c + Vector2.from_angle(ang) * 38.0, RED, 5.0, true)
	fr.draw_circle(c, 7.0, INK)
	Kit.text(fr, c + Vector2(-60, 46), "G", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120, 5, INK)

func _beacon_on(fr: Node2D, p: Vector2, col: Color, on: bool) -> void:
	fr.draw_circle(p, 13.0, INK)
	fr.draw_circle(p, 10.0, col if on else col.darkened(0.55))
	if on:
		fr.draw_circle(p, 30.0, Color(col.r, col.g, col.b, 0.22))

# ---------------------------------------------------------------- tela ESCOLHER EVENTOS
func menu_update(m: Node) -> void:
	var n: int = cfg["lista"].size() + 1
	menu_sel = posmod(menu_sel + m.move_v(), n)
	if m.confirm() or m.move_h() != 0:
		if menu_sel < n - 1:
			var id: String = cfg["lista"][menu_sel]["id"]
			enabled[id] = not enabled.get(id, true)
		elif m.confirm():
			main.state = main.S.AJUSTES
	if m.pressed("back"):
		main.state = main.S.AJUSTES

func menu_draw(ci: CanvasItem, m: Node) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.16, 0.1, 0.18, 0.45))
	Kit.ribbon(ci, Rect2(560, 20, 800, 128), "ESCOLHER EVENTOS", 54)
	var list: Array = cfg["lista"]
	var r := Rect2(300, 160, 1320, 870)
	Kit.paper(ci, r)
	var step := 64.0
	for i in list.size() + 1:
		var y := r.position.y + 46 + i * step
		var on := i == menu_sel
		if on:
			ci.draw_rect(Rect2(r.position.x + 30, y - 36, r.size.x - 60, 60), Color(0.95, 0.78, 0.29, 0.5))
		if i < list.size():
			var e: Dictionary = list[i]
			var en: bool = enabled.get(e["id"], true)
			ci.draw_rect(Rect2(r.position.x + 60, y - 26, 36, 36), Color("#2a1a2e"), false, 4.0)
			if en:
				ci.draw_polyline(PackedVector2Array([Vector2(r.position.x + 66, y - 8), Vector2(r.position.x + 77, y + 4), Vector2(r.position.x + 94, y - 22)]), Color("#3c9a46"), 6.0, true)
			Kit.text(ci, Vector2(r.position.x + 120, y), String(e["nome"]).to_upper(), 30, Color("#2a1a2e") if en else Color("#9aa4ae"))
			Kit.text(ci, Vector2(r.position.x + 640, y), e["dica"], 22, Color("#6b5a70") if en else Color("#b0b8bf"))
		else:
			Kit.text(ci, Vector2(r.position.x, y), "VOLTAR  ▸", 34, Color("#2a1a2e"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Kit.text(ci, Vector2(0, 1056), "▲▼ escolher  ·  PULAR liga/desliga  ·  BACKSPACE/ESC voltar", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 7)
