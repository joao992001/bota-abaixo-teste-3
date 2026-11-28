extends Node2D
## MECANISMOS DA FASE (cartilha do mapa, Z7): armadilhas/máquinas próprias de cada fase, com aviso visível, ciclo legível
## e interação do jogador (marretar alavanca/botão/registro/trava). Cada TIPO é uma receita reaproveitável; a fase só lista
## quais usa, onde e em que etapa: data/modos.json → demolicao.mecanismos.<cena> (ex.: "fase1").
## Golpe da máquina = do ambiente (by -1), a não ser que um jogador a acione.
## Tipos: betoneira (concreto fresco), elevador (plataforma de cremalheira), esteira (leva para fora; botão inverte),
## tubos (marretar solta tubos rolando), serra (sobe da bancada em ciclo), bate_estaca (martela uma faixa),
## agua (alagamento; registro drena), vagonete (passa varrendo o piso), gerador (faísca; com água dá choque).

const T := 64.0
const Kit := preload("res://ui/kit.gd")
const INK := Color("#2a1a2e")
const OndaFx := preload("res://modes/mec_onda.gd")
const ConteinerFx := preload("res://modes/mec_conteiner.gd")
var main: Node
var frente: Node2D            # desenho por cima do palco (onda M3)
var list: Array = []          # instâncias {tipo, etapa, d (dados do data), s (estado)}
var tex := {}
var t := 0.0

func setup(m: Node) -> void:
	main = m
	var key := String(m.level.prop("cena", ""))   # pasta da arte da cena (game/assets/<cena>)
	for d in MapaReg.mecanismos(m.game_mode, m.level.id):   # instâncias por cena, do manifesto do mapa
		var inst := {"tipo": d["tipo"], "etapa": int(d.get("etapa", 1)), "d": d, "s": {}}
		list.append(inst)
		_prepara(inst)
	frente = Node2D.new()   # camada da frente (por cima do palco e das peças): a onda do M3
	frente.z_index = 2
	frente.draw.connect(_draw_frente)
	add_child(frente)
	for n in ["m_betoneira", "m_esteira", "m_tubo", "m_serra", "m_bancada", "m_martelo", "m_vagonete", "m_gerador", "m_bate_torre"]:
		tex[n] = Data.tex("%s/%s" % [key, n])

func _etapa() -> int:
	var et = main.demo.etapas
	return et.etapa if et != null and is_instance_valid(et) else 1

func _on(inst: Dictionary) -> bool:
	return inst["etapa"] == _etapa() and not inst["s"].get("gone", false)

func _v(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func _body(r: Rect2, layer := 1, oneway := false, animated := false) -> StaticBody2D:
	var b: StaticBody2D = AnimatableBody2D.new() if animated else StaticBody2D.new()
	if animated:
		b.sync_to_physics = false
	b.collision_layer = layer
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	cs.one_way_collision = oneway
	b.add_child(cs)
	add_child(b)
	return b

func _prepara(inst: Dictionary) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	s["t"] = float(d.get("fase_s", 0.0))
	match String(inst["tipo"]):
		"elevador":
			var base := _v(d["base"])
			s["y"] = base.y
			s["body"] = _body(Rect2(base.x, base.y, float(d["largura"]), 18), 2, true, true)
		"serra":
			var p := _v(d["pos"])
			if d.has("passarela"):
				s["plat"] = _body(Rect2(float(d["passarela"][0]), p.y, float(d["passarela"][1]) - float(d["passarela"][0]), 14), 2, true)
			s["k"] = 0.0
		"tubos":
			s["pile"] = 6
			s["rolling"] = []
			s["reload"] = 0.0
		"agua":
			s["h"] = 0.0
		"vagonete":
			s["x"] = -1.0

## Virada: os mecanismos da etapa que desabou somem (corpos fora; caem como entulho).
func desaba(etapa: int) -> void:
	for inst in list:
		if inst["etapa"] != etapa:
			continue
		var s: Dictionary = inst["s"]
		for k in ["body", "plat"]:
			if s.has(k) and is_instance_valid(s[k]):
				s[k].queue_free()
		s["gone"] = true
		var p = inst["d"].get("pos", inst["d"].get("base", null))
		if p != null:
			main.dust(_v(p), 1.4)

## Robôs vivos que estão nesta etapa.
## Zonas de perigo dos mecanismos ligados (renascimento seguro: ninguém volta em cima de serra, bate-estaca, trilho do
## vagonete, gerador, pilha de tubos ou plataforma que se move).
func zonas_perigo() -> Array:
	var out := []
	for inst in list:
		if not _on(inst):
			continue
		var d: Dictionary = inst["d"]
		match String(inst["tipo"]):
			"serra", "tubos":
				var p := _v(d["pos"])
				out.append(Rect2(p.x - 160.0, p.y - 200.0, 320.0, 220.0))
			"bate_estaca":
				out.append(Rect2(float(d["x"]) - 130.0, float(d["topo"]) - 40.0, 260.0, float(d["chao"]) - float(d["topo"]) + 60.0))
			"vagonete":
				out.append(Rect2(float(d["x"][0]) - 80.0, float(d["chao"]) - 200.0, float(d["x"][1]) - float(d["x"][0]) + 160.0, 220.0))
			"conteiner_boia":
				out.append(_boia_rect(inst).grow(64.0))
			"tubarao":   # a plataforma-alvo no aviso/salto
				if inst["s"].has("alvo_r"):
					out.append((inst["s"]["alvo_r"] as Rect2).grow(96.0))
			"onda_balsa":   # a balsa da vez durante o aviso e a onda
				var s3: Dictionary = inst["s"]
				if String(s3.get("fase", "")) != "" and s3.has("fx"):
					out.append(s3["fx"].area(main.level.etapa_rect(inst["etapa"]).position))
			"gancho_balanca":   # todo o arco que o contêiner varre
				var g: Dictionary = _gancho_geo(inst)
				var pv: Vector2 = g["pivo"]
				var rr: float = g["L"] + 70.0
				out.append(Rect2(pv.x - rr, pv.y, 2.0 * rr, rr + 40.0))
			"conteiner_cai":   # sombra no aviso/queda e o contêiner parado (plataforma nova)
				var s2: Dictionary = inst["s"]
				if s2.has("alvo"):
					out.append((s2["alvo"] as Rect2).grow(48.0))
			"gerador":
				var a: Array = d["alvo"]
				out.append(Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3])).grow(80.0))
			"elevador":
				var w := float(d.get("largura", 130.0))
				out.append(Rect2(float(d["base"][0]) - w / 2.0 - 40.0, float(d["topo"]) - 200.0, w + 80.0, float(d["base"][1]) - float(d["topo"]) + 220.0))
	return out

func _robots() -> Array:
	return main.robots.filter(func(r): return r.alive)

func update(dt: float) -> void:
	t += dt
	if main.state != main.S.RUN or main.countdown > 0.0:
		queue_redraw()
		return
	var paused := false
	for inst in list:
		if not _on(inst):
			continue
		var s: Dictionary = inst["s"]
		if paused:
			continue
		s["t"] += dt
		match String(inst["tipo"]):
			"betoneira": _betoneira(inst, dt)
			"elevador": _elevador(inst, dt)
			"esteira": _esteira(inst, dt)
			"tubos": _tubos(inst, dt)
			"serra": _serra(inst, dt)
			"bate_estaca": _bate_estaca(inst, dt)
			"cede": _cede(inst, dt)
			"agua": _agua(inst, dt)
			"vagonete": _vagonete(inst, dt)
			"gerador": _gerador(inst, dt)
			"conteiner_cai": _conteiner_cai(inst, dt)
			"gancho_balanca": _gancho(inst, dt)
			"onda_balsa": _onda_balsa(inst, dt)
			"mare": _mare(inst, dt)
			"conteiner_boia": _boia(inst, dt)
			"rede_rasga": _rede(inst, dt)
			"tubarao": _tubarao(inst, dt)
			"cupula_racha": _cupula(inst, dt)
			"geiser": _geiser(inst, dt)
			"lustre_cai": _lustre(inst, dt)
			"concha": _concha(inst, dt)
	queue_redraw()
	if frente != null:
		frente.queue_redraw()

# ---------------------------------------------------------------- tipos
func _betoneira(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var cyc := float(d["ciclo_s"])
	if float(s.get("force", 0.0)) > 0.0:   # alavanca marretada: despeja já
		s["t"] = cyc - float(d["aviso_s"])
		s["force"] = 0.0
	var k: float = s["t"]
	if k >= cyc:
		s["t"] = 0.0
		s["fresh"] = float(d["fresco_s"])
		Audio.play("lama", 0.8, -2.0)
		if not s.get("told", false):
			s["told"] = true
			main.float_text(Vector2(float(d["faixa"][0] + d["faixa"][1]) / 2.0, float(d["chao"]) - 90), "CONCRETO FRESCO: GRUDA!", Color("#f2c84b"))
		main.dust(Vector2(float(d["faixa"][0] + d["faixa"][1]) / 2.0, float(d["chao"])), 1.0)
	s["fresh"] = maxf(float(s.get("fresh", 0.0)) - dt, 0.0)
	if float(s["fresh"]) > 0.0:
		var x0 := float(d["faixa"][0])
		var x1 := float(d["faixa"][1])
		for r in _robots():
			if r.is_on_floor() and r.position.x > x0 and r.position.x < x1 and absf(r.position.y - float(d["chao"])) < 12.0:
				r.env_slow = minf(r.env_slow, float(d["lentidao"]))
	if k > cyc - float(d["aviso_s"]) and fmod(k, 0.4) < dt:
		Audio.play("pistao_aviso", 1.3, -8.0)

func _elevador(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var y0 := float(d["base"][1])
	var y1 := float(d["topo"])
	var w := float(d["espera_s"])
	var m := float(d["move_s"])
	var cyc := 2.0 * (w + m)
	var k := fmod(float(s["t"]), cyc)
	var y: float
	if k < w:
		y = y0
	elif k < w + m:
		y = lerpf(y0, y1, smoothstep(0.0, 1.0, (k - w) / m))
	elif k < 2.0 * w + m:
		y = y1
	else:
		y = lerpf(y1, y0, smoothstep(0.0, 1.0, (k - 2.0 * w - m) / m))
	s["y"] = y
	s["moving"] = absf(y - y0) > 0.5 and absf(y - y1) > 0.5
	s["warn"] = (k > w - 0.8 and k < w) or (k > 2.0 * w + m - 0.8 and k < 2.0 * w + m)
	var b = s["body"]
	if is_instance_valid(b):
		b.position = Vector2(0, y - y0)

func _esteira(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var inv := float(d["inverte_s"])
	if float(s["t"]) >= inv:
		s["t"] = 0.0
		s["dir"] = -int(s.get("dir", int(d["dir"])))
		Audio.play("alavanca", 1.4, -6.0)
	var dir := int(s.get("dir", int(d["dir"])))
	s["blink"] = float(s["t"]) > inv - 1.2
	var x0 := float(d["x"][0])
	var x1 := float(d["x"][1])
	for r in _robots():
		if r.is_on_floor() and r.position.x > x0 and r.position.x < x1 and absf(r.position.y - float(d["chao"])) < 12.0:
			r.push_vx += dir * float(d["vel"])

func _tubos(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var ch := float(d["chao"])
	if int(s["pile"]) == 0:
		s["reload"] = float(s["reload"]) - dt
		if float(s["reload"]) <= 0.0:
			s["pile"] = 6
			main.dust(_v(d["pos"]), 1.0)
	for tb in (s["rolling"] as Array).duplicate():
		tb["vx"] = move_toward(tb["vx"], 0.0, 40.0 * dt)
		tb["x"] += tb["vx"] * dt
		tb["rot"] += tb["vx"] * dt / 38.0
		var on_ground: bool = main.level.is_solid(Vector2i(int(tb["x"] / T), int((tb["y"] + 2.0) / T)))
		var ct = main.demo.canteiro
		if ct != null and is_instance_valid(ct):
			for p in ct.parts:
				if not p["fallen"] and p["rect"].has_point(Vector2(tb["x"], tb["y"] + 4.0)):
					on_ground = true
		if not on_ground:
			tb["vy"] += 2000.0 * dt
			tb["y"] += tb["vy"] * dt
		var hr := Rect2(tb["x"] - 36.0, tb["y"] - 72.0, 72.0, 72.0)
		for r in _robots():
			if r.rect().intersects(hr) and not tb["hit"].has(r.pid) and absf(tb["vx"]) > 80.0:
				tb["hit"][r.pid] = true
				r.take_hit(1 if tb["vx"] > 0.0 else -1, "mec_tubo", int(tb["by"]))
		if tb["y"] > main.level.area.end.y + 300.0 or absf(tb["vx"]) < 10.0 and on_ground:
			(s["rolling"] as Array).erase(tb)
			main.dust(Vector2(tb["x"], tb["y"]), 0.8)

func _serra(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	if s.get("broken", false):
		return
	var on_top := 0   # D6: 2 robôs pulando em cima partem a passarela (só a serra de passarela)
	for r in (_robots() if d.has("passarela") else []):
		if r.is_on_floor() and r.position.x > float(d["passarela"][0]) and r.position.x < float(d["passarela"][1]) and absf(r.position.y - float(d["pos"][1])) < 10.0:
			on_top += 1
	if on_top >= 2:
		_break_walkway(inst)
		return
	var on := float(d["ligada_s"])
	var off := float(d["desligada_s"])
	var k := fmod(float(s["t"]), on + off)
	var up := k < on
	s["k"] = move_toward(float(s["k"]), 1.0 if up else 0.0, dt * 5.0)
	s["warn"] = k > on + off - 0.8
	if float(s["k"]) > 0.6:
		var p := _v(d["pos"])
		var hr := Rect2(p.x - 34.0, p.y - (110.0 if not d.has("passarela") else 70.0), 68.0, 70.0)
		s["cd"] = s.get("cd", {})
		for r in _robots():
			if r.rect().intersects(hr) and float(s["cd"].get(r.pid, 0.0)) <= t:
				s["cd"][r.pid] = t + 0.8
				r.take_hit(1 if r.position.x >= p.x else -1, "mec_serra", -1)
				main.spark(p + Vector2(0, -30), 8)
		if fmod(t, 0.25) < dt:
			Audio.play("serra", 1.2, -10.0)

## D6: a passarela parte no meio e a serra cai junto (fica quebrada até o fim da rodada).
func _break_walkway(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	s["broken"] = true
	s["fall"] = 0.0
	if is_instance_valid(s["plat"]):
		s["plat"].queue_free()
	var d: Dictionary = inst["d"]
	main.dust(_v(d["pos"]), 1.4)
	main.shake(6.0)
	Audio.play("caixote_quebra", 0.9, 0.0)
	main.float_text(_v(d["pos"]) + Vector2(0, -80), "PASSARELA PARTIU!", Color("#f2c84b"))

func _bate_estaca(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var cyc := float(d["ciclo_s"])
	var k := fmod(float(s["t"]), cyc)
	var aviso := float(d["aviso_s"])
	var top := float(d["topo"])
	var floor_y := float(d["chao"])
	var hy: float = top
	var phase := "sobe"
	if k < cyc - aviso - 0.15:
		hy = lerpf(floor_y - 90.0, top, clampf(k / 1.0, 0.0, 1.0))
	elif k < cyc - 0.15:
		hy = top + sin(t * 60.0) * 3.0
		phase = "aviso"
	else:
		hy = lerpf(top, floor_y - 90.0, (k - (cyc - 0.15)) / 0.15)
		phase = "bate"
	if phase == "bate" and s.get("last", "") != "bate":
		s["hit"] = {}
	if phase != "bate" and s.get("last", "") == "bate":
		main.shake(6.0)
		Audio.play("pistao", 0.6, 0.0)
		main.dust(Vector2(float(d["x"]), floor_y), 1.6)
		var ct = main.demo.canteiro   # cada batida trinca a grelha do poço embaixo (abre sozinha depois de algumas)
		if ct != null and is_instance_valid(ct):
			for p in ct.parts:
				if p["kind"] == "grelha" and not p["fallen"] and p["rect"].has_point(Vector2(float(d["x"]), p["rect"].get_center().y)):
					ct.damage(p, 1, Vector2(float(d["x"]), floor_y))
	s["last"] = phase
	s["y"] = hy
	s["phase"] = phase
	if phase == "bate":
		var hr := Rect2(float(d["x"]) - 60.0, hy, 120.0, floor_y - hy)
		for r in _robots():
			if r.rect().intersects(hr) and not s["hit"].has(r.pid):
				s["hit"][r.pid] = true
				r.take_hit(1 if r.position.x >= float(d["x"]) else -1, "mec_estaca", -1)

## M13 Andaime Cede (Fachada, aprovado 2026-11-26): de tempos em tempos uma prancha da cena ganha fita zebrada e, no fim
## do aviso, cede inteira (passa pelo aviso final normal do canteiro: treme, range e cai).
func _cede(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var ct = main.demo.canteiro
	if ct == null or not is_instance_valid(ct):
		return
	var p = s.get("alvo")
	if p != null:
		if p["fallen"]:
			s["alvo"] = null
			return
		p["warn_t"] = maxf(float(p["warn_t"]) - dt, 0.0)
		if fmod(float(s["t"]), 0.9) < dt:
			Audio.play("pistao_aviso", 0.8, -6.0)
		if p["warn_t"] <= 0.0:
			ct.damage(p, 99, p["rect"].get_center())
			s["alvo"] = null
		return
	if float(s["t"]) < float(d["ciclo_s"]):
		return
	s["t"] = 0.0
	var cands: Array = ct.parts.filter(func(q): return q["kind"] == "prancha" and int(q["etapa"]) == int(inst["etapa"]) and not q["fallen"] and q["warn_t"] <= 0.0 and q.get("evt", "") == "" and q["crit_t"] <= 0.0)
	if cands.is_empty():
		return
	var q: Dictionary = cands[main.rng.randi_range(0, cands.size() - 1)]
	q["warn_t"] = float(d["aviso_s"])
	s["alvo"] = q
	main.float_text(q["rect"].get_center() + Vector2(0, -70), "O ANDAIME VAI CEDER!", Color("#f2c84b"))

func _agua(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var cyc := float(d["ciclo_s"])
	if float(s.get("enchente", 0.0)) > 0.0:   # V3 Enchente: a bomba falha e a água sobe bem alto
		s["enchente"] = float(s["enchente"]) - dt
		s["h"] = move_toward(float(s["h"]), float(d["altura"]) * float(s.get("enchente_mult", 2.4)), float(d["altura"]) * dt)
		s["pour"] = true
		var top0 := float(d["chao"]) - float(s["h"])
		for r in _robots():
			if r.position.x > float(d["x"][0]) and r.position.x < float(d["x"][1]) and r.position.y > top0:
				r.env_slow = minf(r.env_slow, float(d["lentidao"]))
		return
	if float(s.get("dreno", 0.0)) > 0.0:
		s["pour"] = false
		s["dreno"] = float(s["dreno"]) - dt
		s["h"] = move_toward(float(s["h"]), 0.0, float(d["altura"]) / 1.0 * dt)
		return
	var k := fmod(float(s["t"]), cyc)
	var sobe := float(d["sobe_s"])
	var fica := float(d["fica_s"])
	var target := 0.0
	if k < sobe:
		target = float(d["altura"]) * k / sobe
	elif k < sobe + fica:
		target = float(d["altura"])
	elif k < 2.0 * sobe + fica:
		target = float(d["altura"]) * (1.0 - (k - sobe - fica) / sobe)
	s["h"] = target
	s["pour"] = k < sobe + fica * 0.6   # despeja do teto enquanto sobe (e um pouco cheia)
	var top := float(d["chao"]) - float(s["h"])
	if float(s["h"]) > 8.0:
		for r in _robots():
			if r.position.x > float(d["x"][0]) and r.position.x < float(d["x"][1]) and r.position.y > top:
				r.env_slow = minf(r.env_slow, float(d["lentidao"]))

func _vagonete(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var cyc := float(d["ciclo_s"])
	var k := fmod(float(s["t"]), cyc)
	var x0 := float(d["x"][0])
	var x1 := float(d["x"][1])
	var dur := (x1 - x0) / float(d["vel"])
	var start := cyc - dur
	s["warn"] = k > start - float(d["aviso_s"]) and k < start
	if k >= start:
		var u := (k - start) / dur
		var dir := 1 if int(floor(float(s["t"]) / cyc)) % 2 == 0 else -1
		s["dir"] = dir
		s["x"] = lerpf(x0, x1, u) if dir > 0 else lerpf(x1, x0, u)
		if fmod(t, 0.3) < dt:
			Audio.play("barril", 0.7, -8.0)
		var hr := Rect2(float(s["x"]) - 80.0, float(d["chao"]) - 100.0, 160.0, 100.0)
		s["hit"] = s.get("hit", {})
		for r in _robots():
			if r.rect().intersects(hr) and float(s["hit"].get(r.pid, 0.0)) <= t:
				s["hit"][r.pid] = t + 1.0
				r.take_hit(dir, "mec_vagonete", -1)
	else:
		s["x"] = -1.0
		if s["warn"] and fmod(t, 0.5) < dt:
			Audio.play("alarme", 1.6, -8.0)

func _gerador(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	if float(s.get("off", 0.0)) > 0.0:
		s["off"] = float(s["off"]) - dt
		s["spark"] = false
		return
	var cyc := float(d["ciclo_s"])
	var k := fmod(float(s["t"]), cyc)
	s["spark"] = k > cyc - float(d["faisca_s"])
	if s["spark"]:
		if fmod(t, 0.15) < dt:
			main.spark(_v(d["cabo"]), 3)
		var agua = _find("agua")
		if agua != null and float(agua["s"]["h"]) > 20.0:   # água alta + faísca = choque em quem está na água
			var ad: Dictionary = agua["d"]
			var top := float(ad["chao"]) - float(agua["s"]["h"])
			s["hit"] = s.get("hit", {})
			for r in _robots():
				if r.position.y > top and r.position.x > float(ad["x"][0]) and r.position.x < float(ad["x"][1]) and float(s["hit"].get(r.pid, 0.0)) <= t:
					s["hit"][r.pid] = t + 1.2
					r.take_hit(0, "mec_choque", -1)
					main.spark(r.position + Vector2(0, -30), 6)

## M1 Contêiner despenca (Fase 2, Alto-Mar; ideia do usuário): a cada ciclo uma coluna é sorteada; amarras estalam e a
## SOMBRA VERMELHA mostra onde cai (aviso_s); o contêiner despenca, acerta quem está embaixo (mec_conteiner), racha a peça
## do palco em que bate e FICA como plataforma nova (fica_s, ou até o próximo); se cair no mar, afunda.
func _conteiner_cai(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var w := float(d.get("largura_t", 2)) * T
	var h := float(d.get("altura_t", 1)) * T
	if not s.has("fx"):
		var fx0 = ConteinerFx.new()
		fx0.setup(self, d)
		s["fx"] = fx0
	var fx = s["fx"]
	var ev: String = fx.update(dt)   # animação em mec_conteiner.gd (5 batidas); aqui só a regra de jogo
	var fase := String(s.get("fase", "espera"))
	match fase:
		"espera":
			if s.has("parado"):
				s["parado"] = float(s["parado"]) - dt
				if float(s["parado"]) <= 0.0:
					_conteiner_some(s)
			if float(s["t"]) >= float(d["ciclo_s"]):
				s["t"] = 0.0
				_conteiner_some(s)
				var cols: Array = d["colunas"]
				var x := o.x + float(cols[main.rng.randi() % cols.size()]) * T
				var chao := _chao_em(Rect2(x, o.y, w, 1.0), main.level.etapa_rect(inst["etapa"]).end.y + 200.0)
				s["alvo"] = Rect2(x, chao - h, w, h)
				s["mar"] = chao > main.level.etapa_rect(inst["etapa"]).end.y
				s["aviso"] = float(d["aviso_s"])
				s["fase"] = "aviso"
				s["cor"] = main.rng.randi() % 7
				s["hit"] = {}
				fx.comecar(s["alvo"], s["mar"], int(s["cor"]))
		"aviso", "salta":   # treme e solta da pilha do navio; o alvo zebrado cresce no chão
			s["aviso"] = maxf(float(s["aviso"]) - dt, 0.0)
			if fx.fase == "cai":
				s["fase"] = "cai"
			elif ev == "solta":
				s["fase"] = "salta"
		"cai":
			var alvo: Rect2 = s["alvo"]
			var cr: Rect2 = fx.caixa()
			s["y"] = cr.position.y
			for r in _robots():
				if r.rect().intersects(cr) and not s["hit"].has(r.pid):
					s["hit"][r.pid] = true
					var dir := 1 if r.position.x >= cr.get_center().x else -1
					if r.take_hit(dir, "mec_conteiner", -1):
						r.hitstop = 0.09
						r.vis.hurt(0.8, dir)
			if ev == "impacto":
				s["fase"] = "espera"
				for r in _robots():   # quem ficou embaixo é cuspido para o lado (não fica entalado nem sobe no contêiner)
					var rr0: Rect2 = r.rect()
					if rr0.intersects(alvo.grow(-4.0)):
						var dir0 := 1 if r.position.x >= alvo.get_center().x else -1
						r.position.x = (alvo.end.x + rr0.size.x * 0.5 + 6.0) if dir0 > 0 else (alvo.position.x - rr0.size.x * 0.5 - 6.0)
						r.position.y = maxf(r.position.y, alvo.end.y)
						r.velocity = Vector2(dir0 * 520.0, -420.0)
						r.own_vx = 0.0
						s["hit"][r.pid] = true
				var chao_r := Rect2(alvo.position.x - 56.0, alvo.end.y - 76.0, w + 112.0, 76.0)
				for r in _robots():   # a pancada arremessa quem está do lado (não embaixo)
					if not s["hit"].has(r.pid) and r.rect().intersects(chao_r) and not r.rect().intersects(alvo):
						var dir2 := 1 if r.position.x >= alvo.get_center().x else -1
						r.knock(dir2, 340.0, 380.0, 0.2)
						r.vis.hurt(0.4, dir2)
				var ct = main.demo.canteiro   # racha a peça do palco em que bateu
				if ct != null and is_instance_valid(ct):
					for p in ct.parts:
						if not p["fallen"] and (p["rect"] as Rect2).intersects(Rect2(alvo.position.x, alvo.end.y - 4.0, w, 12.0)):
							ct.damage(p, int(d.get("dano_peca", 2)), Vector2(alvo.get_center().x, alvo.end.y))
				s["plat"] = _body(alvo)   # fica como plataforma nova
				s["parado"] = float(d.get("fica_s", 14.0))
			elif ev == "afundou":
				s["fase"] = "espera"   # afundou no mar
				s.erase("alvo")

func _conteiner_some(s: Dictionary) -> void:
	if s.has("plat") and is_instance_valid(s["plat"]):
		main.dust((s["alvo"] as Rect2).get_center(), 1.0)
		s["plat"].queue_free()
	s.erase("plat")
	s.erase("parado")
	if String(s.get("fase", "espera")) == "espera":
		s.erase("alvo")

## M2 Gancho balança (Fase 2, Alto-Mar): contêiner pendurado no gancho da grua = plataforma. A cada ciclo a grua range e
## um ARCO TRACEJADO mostra o caminho (aviso_s); ele balança (balanco_s, amplitude amortecendo) e empurra quem está no
## caminho (mec_gancho); quem está em cima vai junto. Marretada nele: parado → balança já para o outro lado; balançando → inverte.
func _gancho_geo(inst: Dictionary) -> Dictionary:
	var d: Dictionary = inst["d"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	return {"pivo": o + _v(d["pivo"]) * T, "L": float(d["comprimento_t"]) * T, "w": float(d["largura_t"]) * T, "h": T - 8.0}

func _gancho_rect(inst: Dictionary) -> Rect2:
	var g := _gancho_geo(inst)
	var th := float(inst["s"].get("ang", 0.0))
	var topo: Vector2 = g["pivo"] + Vector2(sin(th), cos(th)) * float(g["L"])
	return Rect2(topo.x - float(g["w"]) / 2.0, topo.y, g["w"], g["h"])

func _gancho(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	if not s.has("plat"):
		s["ang"] = 0.0
		s["fase"] = "parado"
		s["dir"] = 1.0
		s["r0"] = _gancho_rect(inst)
		s["plat"] = _body(s["r0"], 2, true, true)   # plataforma de passagem (pisa por cima)
	var fase := String(s["fase"])
	if fase == "parado" and float(s["t"]) >= float(d["ciclo_s"]) - float(d["aviso_s"]):
		s["fase"] = "aviso"
		s["aviso"] = float(d["aviso_s"])
		Audio.play("gancho", 0.5, -2.0)   # a grua range
	elif fase == "aviso":
		s["aviso"] = float(s["aviso"]) - dt
		s["ang"] = sin(t * 30.0) * 0.015
		if float(s["aviso"]) <= 0.0:
			_gancho_solta(inst)
	elif fase == "balanca":
		s["bt"] = float(s["bt"]) + dt
		var bt := float(s["bt"])
		var dur := float(d["balanco_s"])
		var w := TAU / float(d["periodo_s"])
		var amp := float(d["amplitude"]) * (1.0 - bt / dur)
		var ang := float(s["dir"]) * amp * sin(w * bt + float(s.get("fi", 0.0)))
		var vel := ang - float(s["ang"])
		if signf(vel) != signf(float(s.get("vel", 0.0))):
			s["hit"] = {}   # nova passada: pode acertar de novo
		s["vel"] = vel
		s["ang"] = ang
		var r := _gancho_rect(inst)
		for rb in _robots():
			if s["hit"].has(rb.pid):
				continue
			var rr: Rect2 = rb.rect()
			var em_cima: bool = rr.end.y <= r.position.y + 10.0
			if rr.intersects(r.grow(4.0)) and not em_cima and absf(vel) > 0.004:
				s["hit"][rb.pid] = true
				rb.take_hit(1 if vel > 0.0 else -1, "mec_gancho", -1)
		if bt >= dur:
			s["fase"] = "parado"
			s["ang"] = 0.0
			s["t"] = 0.0
	var b = s["plat"]
	if is_instance_valid(b):
		b.position = _gancho_rect(inst).position - (s["r0"] as Rect2).position

func _gancho_solta(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	s["fase"] = "balanca"
	s["bt"] = 0.0
	s["fi"] = 0.0
	s["hit"] = {}
	s["vel"] = 0.0
	Audio.play("gancho", 0.8, 0.0)

## M3 Onda estoura na balsa (Fase 2, Alto-Mar): alterna entre as balsas; a água INCHA na borda de fora (aviso_s) → a onda
## varre o convés (onda_s): empurra para dentro e deixa MOLHADO (agua.molhar: lento por uns segundos). Sem dano.
func _onda_area(inst: Dictionary, qual: int) -> Rect2:
	var b: Array = inst["d"]["balsas"][qual]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var alt := float(inst["d"]["altura_t"]) * T
	return Rect2(o.x + float(b[0]) * T, o.y + float(b[2]) * T - alt, (float(b[1]) - float(b[0])) * T, alt)

func _onda_balsa(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	if not s.has("fx"):
		var fx0 = OndaFx.new()
		fx0.setup(self, d)
		s["fx"] = fx0
	var fx = s["fx"]
	if String(s.get("fase", "")) == "" and float(s["t"]) >= float(d["ciclo_s"]):
		s["t"] = 0.0
		s["qual"] = (int(s.get("qual", 1)) + 1) % (d["balsas"] as Array).size()
		fx.comecar(int(s["qual"]), main.level.etapa_rect(inst["etapa"]).position)
		Audio.play("soprador", 0.6, -6.0)   # o mar puxando
	fx.update(dt)
	s["fase"] = fx.fase

func _draw_frente() -> void:
	for inst in list:
		if _on(inst) and String(inst["tipo"]) == "onda_balsa":
			_draw_onda(inst, frente)
		elif _on(inst) and String(inst["tipo"]) == "tubarao":
			_draw_tub_frente(inst, frente)

## Onda: desenho procedural em mec_onda.gd (parede que sai do mar, lâmina, cascatas, gotas).
func _draw_onda(inst: Dictionary, ci: CanvasItem) -> void:
	var fx = inst["s"].get("fx")
	if fx != null and fx.ativa():
		fx.draw(ci)

## M4 Maré (Fase 2, Destroços): baixa → SETA + som (aviso_s) → sobe (sobe_s) até a linha da maré alta e fica (alta_s) →
## desce. Mexe no `topo` da zona de água da cena (agua.gd: quem fica abaixo dela está ALAGADO); bote e jangada (peças
## `boiam`, índices das pranchas da cena) sobem junto.
func _mare_zona(inst: Dictionary) -> Variant:
	var ag = main.demo.agua
	if ag == null or not is_instance_valid(ag):
		return null
	var n := 0
	for z in ag.zonas:
		if int(z["cena"]) == int(inst["etapa"]):
			if n == int(inst["d"].get("zona", 0)):
				return z
			n += 1
	return null

func _mare(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var baixa := o.y + float(d["baixa_px"])
	var alta := o.y + float(d["alta_px"])
	var cyc := float(d["ciclo_s"])
	var av := float(d["aviso_s"])
	var sob := float(d["sobe_s"])
	var al := float(d["alta_s"])
	var k := fmod(float(s["t"]), cyc)
	var t_aviso := cyc - av - sob - al - sob
	var nivel := baixa
	var fase := "baixa"
	if k >= t_aviso and k < t_aviso + av:
		fase = "aviso"
	elif k >= t_aviso + av and k < t_aviso + av + sob:
		fase = "sobe"
		nivel = lerpf(baixa, alta, smoothstep(0.0, 1.0, (k - t_aviso - av) / sob))
	elif k >= t_aviso + av + sob and k < t_aviso + av + sob + al:
		fase = "alta"
		nivel = alta
	elif k >= t_aviso + av + sob + al:
		fase = "desce"
		nivel = lerpf(alta, baixa, smoothstep(0.0, 1.0, (k - t_aviso - av - sob - al) / sob))
	if fase == "aviso" and s.get("fase", "") != "aviso":
		Audio.play("alarme", 0.7, -4.0)
	s["fase"] = fase
	s["nivel"] = nivel
	var z = _mare_zona(inst)
	if z != null:
		z["topo"] = nivel
	var ct = main.demo.canteiro   # o que boia sobe com a maré
	if ct != null and is_instance_valid(ct):
		var sobe := maxf(float(d["baixa_px"]) - (nivel - o.y), 0.0)   # boiam: sobem o mesmo que a água
		for p in ct.parts:
			if p["kind"] == "prancha" and int(p["etapa"]) == int(inst["etapa"]) and float(p["idx"]) in d.get("boiam", []):   # JSON dá 7.0
				ct.move_part(p, float(p["y0"]) - sobe)

## M7 (Atlântida): a racha da cúpula pinga e mantém o lado direito alagado até a linha base; cada MARRETADA no vidro
## (alvo) faz a racha crescer e a água subir um degrau (até max_degraus); sem novas marretadas a água desce um degrau a
## cada volta_s. O evento "Bolhão de Ar" pode zerar `s.degraus`.
func _cupula(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var deg := int(s.get("degraus", 0))
	if deg > 0:
		s["volta"] = float(s.get("volta", 0.0)) + dt
		if float(s["volta"]) >= float(d["volta_s"]):
			s["volta"] = 0.0
			s["degraus"] = deg - 1
	var alvo_topo := o.y + float(d["base_px"]) - float(d["degrau_px"]) * int(s.get("degraus", 0))
	var atual := float(s.get("nivel", alvo_topo))
	s["nivel"] = move_toward(atual, alvo_topo, float(d["vel_px"]) * dt)
	var z = _mare_zona(inst)
	if z != null:
		z["topo"] = float(s["nivel"])

func cupula_racha(inst: Dictionary) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	s["degraus"] = mini(int(s.get("degraus", 0)) + 1, int(d["max_degraus"]))
	s["volta"] = 0.0
	s["pulso"] = 1.0
	Audio.play("caixote_quebra", 1.4, -2.0)

## M11 Gêiser (Atlântida, ideia do usuário): a cada ciclo uma das fendas (alterna) BORBULHA (aviso) e depois JORRA: quem
## está na coluna do jato é empurrado para cima (elevador até as lajes altas); quem cai na fenda é jogado de volta (sem dano).
func _geiser_fase(inst: Dictionary) -> Array:
	var d: Dictionary = inst["d"]
	var cyc := float(d["ciclo_s"])
	var k := fmod(float(inst["s"]["t"]), cyc)
	var idx := int(float(inst["s"]["t"]) / cyc) % (d["fendas"] as Array).size()
	var fase := "calmo"
	if k >= cyc - float(d["aviso_s"]) - float(d["jorra_s"]) and k < cyc - float(d["jorra_s"]):
		fase = "aviso"
	elif k >= cyc - float(d["jorra_s"]):
		fase = "jorra"
	return [fase, idx]

func _geiser_rect(inst: Dictionary, idx: int) -> Rect2:
	var d: Dictionary = inst["d"]
	var er: Rect2 = main.level.etapa_rect(inst["etapa"])
	var f: Array = d["fendas"][idx]
	var x0 := er.position.x + float(f[0]) * T
	var x1 := er.position.x + float(f[1]) * T
	var topo := er.position.y + float(d["topo_px"])
	return Rect2(x0, topo, x1 - x0, er.end.y + 400.0 - topo)

func _geiser(inst: Dictionary, _dt: float) -> void:
	var s: Dictionary = inst["s"]
	var fi: Array = _geiser_fase(inst)
	if fi[0] == "jorra" and s.get("fase", "") != "jorra":
		Audio.play("explosao", 1.6, -8.0)
	s["fase"] = fi[0]
	s["idx"] = fi[1]
	if fi[0] != "jorra":
		return
	var jr := _geiser_rect(inst, int(fi[1]))
	var vel := float(inst["d"]["jato_vel"])
	for r in _robots():
		if jr.has_point(r.position):
			r.velocity.y = minf(r.velocity.y, -vel)   # sobe com o jato (não é golpe: sem dano)

func _draw_geiser(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	var fase := String(s.get("fase", "calmo"))
	if fase == "calmo":
		return
	var jr := _geiser_rect(inst, int(s.get("idx", 0)))
	var fundo := minf(jr.end.y, main.level.etapa_rect(inst["etapa"]).end.y)
	if fase == "aviso":
		for k in 10:   # o fundo da fenda borbulha e brilha
			var x := jr.position.x + fmod(k * 53.0 + t * 40.0, jr.size.x)
			var y := fundo - fmod(t * 160.0 + k * 37.0, 220.0)
			draw_arc(Vector2(x, y), 6.0 + float(k % 3) * 4.0, 0, TAU, 12, Color(1, 1, 1, 0.8), 3.0, true)
		draw_rect(Rect2(jr.position.x, fundo - 40.0, jr.size.x, 40.0), Color(0.75, 0.95, 1.0, 0.25 + 0.2 * sin(t * 14.0)))
		return
	var a := 0.5 + 0.1 * sin(t * 20.0)
	draw_rect(Rect2(jr.position.x + 20.0, jr.position.y, jr.size.x - 40.0, fundo - jr.position.y), Color(0.78, 0.96, 1.0, a))
	for side in [jr.position.x + 20.0, jr.end.x - 20.0]:
		draw_line(Vector2(side, jr.position.y), Vector2(side, fundo), Color(1, 1, 1, 0.9), 5.0, true)
	for k in 8:   # espuma no topo do jato
		draw_circle(Vector2(jr.position.x + 30.0 + k * (jr.size.x - 60.0) / 7.0, jr.position.y + sin(t * 9.0 + k) * 10.0), 18.0, Color(1, 1, 1, 0.85))

## M8 Lustre (Atlântida): MARRETADA na corrente (acima da peça) → ESTALA (treme + sombra vermelha no chão, aviso_s) → CAI
## acelerando: acerta quem estiver embaixo e, ao bater, racha a plataforma onde cai; depois o lustre se desfaz (não volta).
func _lustre_peca(inst: Dictionary) -> Variant:
	return _rede_peca(inst)

func _lustre_corrente(inst: Dictionary) -> Rect2:
	var p = _lustre_peca(inst)
	if p == null:
		return Rect2()
	var r: Rect2 = p["rect"]
	var alt := float(inst["d"]["corrente_px"])
	return Rect2(r.get_center().x - 40.0, r.position.y - alt, 80.0, alt + 10.0)

func _lustre(inst: Dictionary, dt: float) -> void:
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	var p = _lustre_peca(inst)
	var fase := String(s.get("fase", "preso"))
	if p == null or (p["fallen"] and fase != "caiu"):
		s["fase"] = "caiu"
		return
	var r: Rect2 = p["rect"]
	if fase == "estala":
		s["k"] = float(s["k"]) + dt
		p["shake"] = 0.2
		if float(s["k"]) >= float(d["aviso_s"]):
			s["fase"] = "cai"
			s["vy"] = 0.0
			s["hit"] = {}
			Audio.play("terremoto", 1.6, -6.0)
	elif fase == "cai":
		s["vy"] = float(s["vy"]) + float(d["gravidade"]) * dt
		var ny := r.position.y + float(s["vy"]) * dt
		var chao := float(s["chao"])
		for rb in _robots():
			if not (s["hit"] as Dictionary).has(rb.pid) and rb.rect().intersects(Rect2(r.position.x, ny, r.size.x, r.size.y + 30.0)):
				s["hit"][rb.pid] = true
				rb.take_hit(1 if rb.position.x >= r.get_center().x else -1, "mec_lustre", -1)
		if ny + r.size.y >= chao:
			ny = chao - r.size.y
			s["fase"] = "caiu"
			var ct = main.demo.canteiro
			var baixo := Rect2(r.position.x, chao, r.size.x, 8.0)
			for q in ct.parts:   # racha a plataforma onde cai
				if q != p and not q["fallen"] and (q["rect"] as Rect2).intersects(baixo):
					ct.damage(q, int(d["dano_plataforma"]), Vector2(r.get_center().x, chao))
			main.shake(10.0)
			main.dust(Vector2(r.get_center().x, chao), 1.6)
			Audio.play("explosao", 1.2, -4.0)
			ct.move_part(p, ny)
			ct.damage(p, 99, Vector2(r.get_center().x, chao))   # o lustre se desfaz
			return
		main.demo.canteiro.move_part(p, ny)

func lustre_solta(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	if String(s.get("fase", "preso")) != "preso":
		return
	var p = _lustre_peca(inst)
	var r: Rect2 = p["rect"]
	s["fase"] = "estala"
	s["k"] = 0.0
	var abaixo := (floorf(r.position.y / T) + 1.0) * T   # a partir da linha de baixo (a própria peça ocupa a linha dela)
	s["chao"] = _chao_em(Rect2(r.position.x + 10.0, abaixo, r.size.x - 20.0, 1.0), main.level.etapa_rect(inst["etapa"]).end.y + 200.0)
	Audio.play("chave", 0.6, 0.0)

func _draw_lustre(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	var fase := String(s.get("fase", "preso"))
	var p = _lustre_peca(inst)
	if p == null or fase == "caiu":
		return
	var cr := _lustre_corrente(inst)
	var top := cr.position.y
	if fase == "preso":   # corrente inteira; brilha quando alguém chega perto (dá para soltar)
		for rb in _robots():
			if rb.position.distance_to(cr.get_center()) < 160.0:
				draw_arc(Vector2(cr.get_center().x, top + 30.0), 26.0 + 3.0 * sin(t * 8.0), 0, TAU, 20, Color(1, 0.9, 0.4, 0.8), 4.0, true)
				break
		return
	var r: Rect2 = p["rect"]
	if fase == "estala":   # elo partindo + SOMBRA VERMELHA onde vai cair
		var a := 0.55 + 0.35 * sin(t * 20.0)
		var chao := float(s["chao"])
		draw_rect(Rect2(r.position.x, chao - 8.0, r.size.x, 10.0), Color(0.83, 0.13, 0.21, a))
		for x in range(int(r.position.x), int(r.end.x), 22):
			draw_line(Vector2(x, chao - 3.0), Vector2(x + 12, chao - 3.0), Color(1, 1, 1, a), 3.0)
		draw_circle(Vector2(r.get_center().x, chao - 46.0), 16.0, Color(0.83, 0.13, 0.21, 0.9))
		draw_string(ThemeDB.fallback_font, Vector2(r.get_center().x - 5.0, chao - 38.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		draw_line(Vector2(cr.get_center().x - 10.0, top + 20.0), Vector2(cr.get_center().x + 10.0, top + 36.0), Color(1, 1, 1, 0.9), 4.0, true)

## M9 Concha-trampolim (Atlântida): quem pisa na concha ABERTA é lançado MUITO alto (lanca_tiles); ela FECHA por fecha_s e
## prende quem estiver em cima (parado, sem controle); marretada na concha fechada abre na hora.
func _concha_rect(inst: Dictionary) -> Rect2:
	var d: Dictionary = inst["d"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	return Rect2(o + Vector2(float(d["x_px"]) - 56.0, float(d["chao_px"]) - 30.0), Vector2(112.0, 34.0))

func _concha(inst: Dictionary, dt: float) -> void:
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	var cr := _concha_rect(inst)
	if String(s.get("fase", "aberta")) == "fechada":
		s["k"] = float(s["k"]) + dt
		for r in _robots():   # preso dentro: parado, sem controle
			if cr.has_point(r.position):
				r.velocity = Vector2.ZERO
				r.stun_t = maxf(r.stun_t, 0.1)
				r.position.x = clampf(r.position.x, cr.position.x + 10.0, cr.end.x - 10.0)
		if float(s["k"]) >= float(d["fecha_s"]):
			s["fase"] = "aberta"
		return
	s["fase"] = "aberta"
	for r in _robots():
		if cr.has_point(r.position) and r.velocity.y >= 0.0:
			r.launch(float(d["lanca_tiles"]))
			s["fase"] = "fechada"
			s["k"] = 0.0
			main.dust(Vector2(cr.get_center().x, cr.end.y), 0.8)
			return

func _draw_concha(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	var cr := _concha_rect(inst)
	var tx: Texture2D = Data.tex("cargueiro/concha_fechada" if String(s.get("fase", "aberta")) == "fechada" else "cargueiro/concha_aberta")
	if tx != null:
		var base := Vector2(cr.get_center().x, cr.end.y + 4.0)   # sprite 140×110, base em y=100
		draw_texture_rect(tx, Rect2(base - Vector2(70, 100), Vector2(140, 110)), false)

## Alvo do vidro em px do mundo (o manifesto dá em px relativos à cena).
func _cup_alvo(inst: Dictionary) -> Rect2:
	var a: Array = inst["d"]["alvo_rel"]
	return Rect2(main.level.etapa_rect(inst["etapa"]).position + Vector2(float(a[0]), float(a[1])), Vector2(float(a[2]), float(a[3])))

func _draw_cupula(inst: Dictionary) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var c := _cup_alvo(inst).get_center()
	var deg := int(s.get("degraus", 0))
	s["pulso"] = maxf(float(s.get("pulso", 0.0)) - 0.03, 0.0)
	var brilho := 0.5 + 0.5 * sin(t * 6.0)
	draw_circle(c, 26.0 + 8.0 * deg + 14.0 * float(s["pulso"]), Color(0.75, 0.95, 1.0, 0.18 + 0.15 * brilho))
	var rr := 18.0 + 10.0 * deg
	for k in 4 + deg * 2:   # racha: raios brancos saindo do ponto de impacto
		var ang := float(k) * TAU / float(4 + deg * 2) + 0.4
		draw_line(c, c + Vector2.from_angle(ang) * rr * (0.7 + 0.3 * float(k % 2)), Color(1, 1, 1, 0.9), 3.0, true)
	var fio := 6.0 + 5.0 * deg   # jato que engrossa
	var nivel := float(s.get("nivel", c.y + 200.0))
	draw_line(c + Vector2(0, 10), Vector2(c.x - 10.0, nivel), Color(0.75, 0.94, 1.0, 0.7), fio, true)
	var gy := fmod(t * 300.0, maxf(nivel - c.y, 1.0))   # gotas caindo
	draw_circle(Vector2(c.x - 4.0, c.y + gy), 5.0, Color(0.85, 0.97, 1.0, 0.9))

func _draw_mare(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	if s.get("fase", "") != "aviso" and s.get("fase", "") != "sobe":
		return
	var d: Dictionary = inst["d"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var alta := o.y + float(d["alta_px"])
	var a := 0.6 + 0.4 * sin(t * 12.0)
	# linha da maré alta (tracejada) e setas subindo nas pontas: "a água vai chegar até aqui"
	var x := o.x
	while x < o.x + 30.0 * T:
		draw_line(Vector2(x, alta), Vector2(x + 26.0, alta), Color(1, 1, 1, a), 5.0)
		x += 44.0
	for cx in [o.x + 2.5 * T, o.x + 15.0 * T, o.x + 27.5 * T]:
		var b := Vector2(cx, alta + 150.0 - fmod(t * 120.0, 60.0))
		draw_colored_polygon(PackedVector2Array([b + Vector2(0, -60), b + Vector2(-30, -20), b + Vector2(-12, -20), b + Vector2(-12, 20), b + Vector2(12, 20), b + Vector2(12, -20), b + Vector2(30, -20)]), Color(0.2, 0.75, 0.95, a))
	Kit.text(self, Vector2(o.x + 15.0 * T - 90.0, alta - 20.0), "MARÉ ALTA!", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 180, 6)

## M5 Contêiner boiando vira (Fase 2, Destroços): plataforma que boia (balança de leve e sobe com a maré). Com min_robos
## ou mais em cima por pesa_s, RANGE e afunda o lado mais pesado (range_s, inclinando) → VIRA: some a plataforma e todos
## caem na água; volta à tona em virado_s.
func _boia_rect(inst: Dictionary) -> Rect2:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var o: Vector2 = main.level.etapa_rect(inst["etapa"]).position
	var topo := o.y + float(d["topo_px"])
	var mar := o.y + 960.0
	var z = _mare_zona(inst) if main.demo.agua != null else null
	if z != null and float(z["topo"]) < mar:   # maré alta: boia mais alto
		topo -= mar - float(z["topo"])
	topo += sin(t * 1.6) * 4.0 + float(s.get("afunda", 0.0))
	return Rect2(o.x + float(d["x_t"]) * T, topo, float(d["largura_t"]) * T, T)

func _boia(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	if not s.has("plat"):
		s["fase"] = "boia"
		s["pesa"] = 0.0
		s["ang"] = 0.0
		s["r0"] = _boia_rect(inst)
		s["plat"] = _body(s["r0"], 2, true, true)
	var r := _boia_rect(inst)
	var fase := String(s["fase"])
	match fase:
		"boia":
			var em_cima := []
			for rb in _robots():
				var rr: Rect2 = rb.rect()
				if rb.is_on_floor() and absf(rr.end.y - r.position.y) < 12.0 and rr.end.x > r.position.x and rr.position.x < r.end.x:
					em_cima.append(rb)
			s["pesa"] = float(s["pesa"]) + dt if em_cima.size() >= int(d["min_robos"]) else 0.0
			if float(s["pesa"]) >= float(d["pesa_s"]):
				var mx := 0.0
				for rb in em_cima:
					mx += rb.position.x
				s["lado"] = 1.0 if mx / em_cima.size() >= r.get_center().x else -1.0
				s["fase"] = "range"
				s["k"] = 0.0
				Audio.play("gancho", 0.45, 0.0)   # o contêiner range
		"range":
			s["k"] = float(s["k"]) + dt / float(d["range_s"])
			s["ang"] = float(s["lado"]) * 0.35 * float(s["k"]) + sin(t * 40.0) * 0.02
			s["afunda"] = 18.0 * float(s["k"])
			if float(s["k"]) >= 1.0:
				s["fase"] = "virado"
				s["k"] = 0.0
				Audio.play("explosao", 1.5, -8.0)   # tchibum
				main.dust(r.get_center(), 1.2)
				var ag = main.demo.agua
				for rb in _robots():   # quem estava em cima vai para a água (empurrado para o lado que afundou)
					var rr: Rect2 = rb.rect()
					if absf(rr.end.y - r.position.y) < 40.0 and rr.end.x > r.position.x - 10.0 and rr.position.x < r.end.x + 10.0:
						rb.velocity.y = 120.0
						rb.own_vx = float(s["lado"]) * 160.0
						if ag != null and is_instance_valid(ag):
							ag.molhar(rb)
		"virado":
			s["k"] = float(s["k"]) + dt
			s["ang"] = float(s["lado"]) * PI * 0.5
			s["afunda"] = 70.0
			if float(s["k"]) >= float(d["virado_s"]):
				s["fase"] = "boia"
				s["ang"] = 0.0
				s["afunda"] = 0.0
				s["pesa"] = 0.0
				main.dust(r.get_center(), 1.0)
	var b = s["plat"]
	if is_instance_valid(b):   # virado: sem plataforma (todos caem na água)
		b.position = r.position - (s["r0"] as Rect2).position + (Vector2(0, 4000) if String(s["fase"]) == "virado" else Vector2.ZERO)

func _draw_boia(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	if not s.has("plat"):
		return
	var r := _boia_rect(inst)
	var tx: Texture2D = Data.tex("cargueiro/cont_%d" % int(inst["d"].get("cor", 1)))
	var piv := r.get_center()
	draw_set_transform(piv, float(s.get("ang", 0.0)), Vector2.ONE)
	var a := 0.55 if String(s.get("fase", "")) == "virado" else 1.0
	if tx != null:
		draw_texture_rect(tx, Rect2(-r.size / 2.0, r.size), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	if String(s.get("fase", "")) == "range":   # rangendo: bolhas e respingos no lado que afunda
		var lx := piv.x + float(s["lado"]) * r.size.x * 0.45
		for k in 4:
			draw_arc(Vector2(lx + sin(t * 9.0 + k) * 12.0, r.end.y + 10.0 - fmod(t * 80.0 + k * 20.0, 60.0)), 5.0, 0, TAU, 8, Color(1, 1, 1, 0.8), 2.0)
	elif String(s.get("fase", "")) == "boia":   # linha d'água batendo no casco
		draw_line(Vector2(r.position.x - 6.0, r.end.y - 14.0), Vector2(r.end.x + 6.0, r.end.y - 14.0), Color(1, 1, 1, 0.7), 3.0)

## M6 Rede de carga rasga (Fase 2, Destroços): a rede é uma peça do canteiro (prancha `peca` da cena). Marretada PESADA
## rasga na hora; quebrou de qualquer jeito → as caixas caem em quem está embaixo (mec_caixas) e se espatifam no chão.
func _rede_peca(inst: Dictionary) -> Variant:
	var ct = main.demo.canteiro
	if ct == null or not is_instance_valid(ct):
		return null
	for p in ct.parts:
		if p["kind"] == "prancha" and int(p["etapa"]) == int(inst["etapa"]) and float(p["idx"]) == float(inst["d"]["peca"]):
			return p
	return null

func _rede(inst: Dictionary, dt: float) -> void:
	var s: Dictionary = inst["s"]
	var p = _rede_peca(inst)
	if p != null and p["fallen"] and not s.get("rasgou", false):
		s["rasgou"] = true
		var r: Rect2 = p["rect"]
		s["caixas"] = []
		for k in int(inst["d"]["caixas"]):
			(s["caixas"] as Array).append({"p": Vector2(r.position.x + (k + 0.5) * r.size.x / float(inst["d"]["caixas"]), r.position.y + 30.0), "vy": -80.0 - k * 40.0, "rot": 0.0, "hit": {}})
		Audio.play("caixote_quebra", 0.8, 0.0)
	var vivas := []
	for cx in s.get("caixas", []):
		cx["vy"] = float(cx["vy"]) + 2600.0 * dt
		cx["p"] += Vector2(0, float(cx["vy"]) * dt)
		cx["rot"] = float(cx["rot"]) + dt * 3.0
		var br := Rect2(cx["p"] - Vector2(27, 25), Vector2(54, 50))
		for rb in _robots():
			if not cx["hit"].has(rb.pid) and rb.rect().intersects(br):
				cx["hit"][rb.pid] = true
				rb.take_hit(1 if rb.position.x >= br.get_center().x else -1, "mec_caixas", -1)
		var chao := _chao_em(Rect2(br.position.x, br.position.y, br.size.x, 1.0), main.level.etapa_rect(inst["etapa"]).end.y + 200.0)
		if br.end.y >= chao:
			main.dust(Vector2(br.get_center().x, chao), 0.9)
			Audio.play("caixote_quebra", 1.1, -4.0)
		elif br.position.y < main.level.etapa_rect(inst["etapa"]).end.y + 100.0:
			vivas.append(cx)
	s["caixas"] = vivas

func _draw_rede(inst: Dictionary) -> void:
	for cx in inst["s"].get("caixas", []):
		draw_set_transform(cx["p"], float(cx["rot"]), Vector2.ONE)
		draw_rect(Rect2(-27, -25, 54, 50), Color("#c98a4b"))
		draw_rect(Rect2(-27, 17, 54, 8), Color("#9a6a3a"))
		draw_line(Vector2(-27, -25), Vector2(27, 25), Color("#9a6a3a"), 4.0)
		draw_set_transform(Vector2.ZERO)

## M10 Tubarão (Fase 2, Destroços; ideia do usuário): a BARBATANA ronda o mar; alguém numa plataforma BAIXA (peças `alvos`
## da cena ou o contêiner boiando) → acelera até lá + ANEL VERMELHO + som (aviso_s) → SALTA em arco e morde (mec_tubarao:
## joga para cima/lado; o contêiner boiando vira). Marretada no focinho no salto: TONTO e foge (foge_s).
func _mar_y(inst: Dictionary) -> float:
	var y: float = main.level.etapa_rect(inst["etapa"]).position.y + 960.0
	var z = _mare_zona(inst)
	return minf(y, float(z["topo"])) if z != null else y

func _tub_alvos(inst: Dictionary) -> Array:
	var out := []   # [rect, "peca"|"boia", ref]
	var ct = main.demo.canteiro
	if ct != null and is_instance_valid(ct):
		for p in ct.parts:
			if p["kind"] == "prancha" and not p["fallen"] and int(p["etapa"]) == int(inst["etapa"]) and float(p["idx"]) in inst["d"]["alvos"]:
				out.append([p["rect"], "peca", p])
	for i in list:
		if String(i["tipo"]) == "conteiner_boia" and int(i["etapa"]) == int(inst["etapa"]) and String(i["s"].get("fase", "")) == "boia":
			out.append([_boia_rect(i), "boia", i])
	return out

func _tub_rect(inst: Dictionary) -> Rect2:
	var p: Vector2 = inst["s"].get("pos", Vector2.ZERO)
	return Rect2(p - Vector2(110, 40), Vector2(220, 80))

func _tubarao(inst: Dictionary, dt: float) -> void:
	var d: Dictionary = inst["d"]
	var s: Dictionary = inst["s"]
	var a: Rect2 = main.level.etapa_rect(inst["etapa"])
	var mar := _mar_y(inst)
	if not s.has("fase"):
		s["fase"] = "ronda"
		s["x"] = a.position.x + a.size.x * 0.5
		s["vx"] = float(d["vel"])
		s["ronda"] = main.rng.randf_range(float(d["ronda_s"][0]), float(d["ronda_s"][1]))
	var fase := String(s["fase"])
	match fase:
		"ronda":
			s["x"] = float(s["x"]) + float(s["vx"]) * dt
			if float(s["x"]) < a.position.x + 200.0 or float(s["x"]) > a.end.x - 200.0:
				s["vx"] = -float(s["vx"])
			s["ronda"] = float(s["ronda"]) - dt
			if float(s["ronda"]) <= 0.0:
				s["ronda"] = 1.0   # tenta de novo daqui a 1 s se ninguém estiver numa plataforma baixa
				for al in _tub_alvos(inst):
					var ar: Rect2 = al[0]
					for rb in _robots():
						var rr: Rect2 = rb.rect()
						if absf(rr.end.y - ar.position.y) < 14.0 and rr.end.x > ar.position.x and rr.position.x < ar.end.x:
							s["fase"] = "aviso"
							s["k"] = 0.0
							s["alvo"] = al
							s["alvo_r"] = ar
							s["lado"] = 1.0 if float(s["x"]) < ar.get_center().x else -1.0
							Audio.play("pistao_aviso", 0.5, 0.0)   # tã-dã... tã-dã...
							break
					if fase != String(s["fase"]):
						break
		"aviso":
			s["k"] = float(s["k"]) + dt / float(d["aviso_s"])
			var ar: Rect2 = s["alvo_r"]
			var px := ar.get_center().x - float(s["lado"]) * 260.0   # acelera até o ponto de salto
			s["x"] = move_toward(float(s["x"]), px, float(d["vel"]) * 3.5 * dt)
			if fmod(float(s["k"]) * float(d["aviso_s"]), 0.6) < dt:
				Audio.play("pistao_aviso", 0.5, -2.0)
			if float(s["k"]) >= 1.0:
				s["fase"] = "salta"
				s["k"] = 0.0
				s["x0"] = float(s["x"])
				s["hit"] = {}
				s["pos"] = Vector2(float(s["x"]), mar + 40.0)
				Audio.play("explosao", 1.6, -8.0)
		"salta":
			s["k"] = float(s["k"]) + dt / float(d["salto_s"])
			var ar: Rect2 = s["alvo_r"]
			var u := clampf(float(s["k"]), 0.0, 1.0)
			var x0 := float(s["x0"])
			var x1 := ar.get_center().x + float(s["lado"]) * 260.0
			var h := mar + 40.0 - (ar.position.y - 110.0)
			var p := Vector2(lerpf(x0, x1, u), mar + 40.0 - 4.0 * h * u * (1.0 - u))
			var prev: Vector2 = s.get("pos", p)
			s["pos"] = p
			s["ang"] = (p - prev).angle() if p.distance_to(prev) > 0.5 else float(s.get("ang", 0.0))
			var tr := _tub_rect(inst)
			for rb in _robots():
				if not s["hit"].has(rb.pid) and rb.rect().intersects(tr):
					s["hit"][rb.pid] = true
					rb.take_hit(int(s["lado"]), "mec_tubarao", -1)
			var al: Array = s["alvo"]
			if u > 0.45 and String(al[1]) == "boia" and String(al[2]["s"].get("fase", "")) == "boia":
				al[2]["s"]["fase"] = "range"   # mordeu o contêiner boiando: ele vira
				al[2]["s"]["k"] = 0.6
				al[2]["s"]["lado"] = float(s["lado"])
			if u >= 1.0:
				_tub_volta(inst)
		"tonto":
			s["k"] = float(s["k"]) + dt
			var p: Vector2 = s["pos"]
			s["pos"] = p + Vector2(0, 600.0 * dt)
			s["ang"] = float(s.get("ang", 0.0)) + 6.0 * dt
			if float(s["k"]) >= 0.8:
				_tub_volta(inst)
				s["ronda"] = float(d["foge_s"])   # fugiu: some por um tempo
				s["foge"] = float(d["foge_s"])
	if s.has("foge"):
		s["foge"] = float(s["foge"]) - dt
		if float(s["foge"]) <= 0.0:
			s.erase("foge")

func _tub_volta(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	s["fase"] = "ronda"
	s["x"] = (s["pos"] as Vector2).x if s.has("pos") else float(s["x"])
	s.erase("pos")
	s.erase("alvo")
	s.erase("alvo_r")
	s["ronda"] = main.rng.randf_range(float(inst["d"]["ronda_s"][0]), float(inst["d"]["ronda_s"][1]))
	main.dust(Vector2(float(s["x"]), _mar_y(inst)), 1.0)

## Barbatana e anel vermelho na camada da frente (por cima da água alagada): leitura do perigo em 1 s.
func _draw_tub_frente(inst: Dictionary, ci: CanvasItem) -> void:
	var s: Dictionary = inst["s"]
	if not s.has("fase"):
		return
	var mar := _mar_y(inst)
	var fase := String(s["fase"])
	if (fase == "ronda" and not s.has("foge")) or fase == "aviso":   # barbatana cortando a água
		var bt: Texture2D = Data.tex("cargueiro/barbatana")
		var x := float(s["x"])
		var dirx := signf(float(s.get("vx", 1.0))) if fase == "ronda" else float(s["lado"])
		if bt != null:
			ci.draw_texture_rect(bt, Rect2(x - 60.0 * dirx, mar - 62.0, 120.0 * dirx, 70.0), false)
	if fase == "aviso":   # ANEL VERMELHO tracejado embaixo da plataforma-alvo
		var ar: Rect2 = s["alvo_r"]
		var c := Vector2(ar.get_center().x, mar + 4.0)
		var rx := ar.size.x * 0.6 + 30.0
		var a := 0.6 + 0.4 * sin(t * 16.0)
		for k in 16:
			if k % 2 == 1:
				continue
			var a0 := TAU * k / 16.0
			var a1 := TAU * (k + 1) / 16.0
			ci.draw_line(c + Vector2(cos(a0) * rx, sin(a0) * 18.0), c + Vector2(cos(a1) * rx, sin(a1) * 18.0), Color(0.83, 0.13, 0.21, a), 6.0)

func _draw_tubarao(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	if not s.has("fase"):
		return
	var mar := _mar_y(inst)
	var fase := String(s["fase"])
	if (fase == "salta" or fase == "tonto") and s.has("pos"):
		var tx: Texture2D = Data.tex("cargueiro/tubarao_boca" if fase == "salta" else "cargueiro/tubarao")
		var p: Vector2 = s["pos"]
		var ang := float(s.get("ang", 0.0))
		var flip := float(s["lado"]) < 0.0
		draw_set_transform(p, ang if not flip else ang + PI, Vector2(1, -1) if flip else Vector2.ONE)
		if tx != null:
			draw_texture_rect(tx, Rect2(Vector2(-170, -90), Vector2(300, 160)), false)
		draw_set_transform(Vector2.ZERO)
		if fase == "tonto":
			for k in 3:
				var q := p + Vector2(cos(t * 6.0 + k * 2.1) * 50.0, -70.0 + sin(t * 6.0 + k * 2.1) * 12.0)
				draw_circle(q, 7.0, Color("#f2c84b"))

## Primeiro chão (tile sólido ou peça do canteiro de pé) embaixo da faixa r, descendo até limite.
func _chao_em(r: Rect2, limite: float) -> float:
	var y := r.position.y
	var best := limite
	var ct = main.demo.canteiro
	if ct != null and is_instance_valid(ct):
		for p in ct.parts:
			var pr: Rect2 = p["rect"]
			if not p["fallen"] and pr.position.x < r.end.x and pr.end.x > r.position.x and pr.position.y > y:
				best = minf(best, pr.position.y)
	var c0 := int(r.position.x / T)
	var c1 := int((r.end.x - 1.0) / T)
	var row := int(y / T)
	while row * T < best:
		for c in range(c0, c1 + 1):
			if main.level.is_solid(Vector2i(c, row)):
				return minf(best, row * T)
		row += 1
	return best

func _draw_gancho(inst: Dictionary) -> void:
	var s: Dictionary = inst["s"]
	var d: Dictionary = inst["d"]
	if not s.has("plat"):
		return
	var g := _gancho_geo(inst)
	var pv: Vector2 = g["pivo"]
	var L: float = g["L"]
	if String(s["fase"]) == "aviso":   # ARCO TRACEJADO: por onde o contêiner vai varrer
		var amp := float(d["amplitude"])
		var n := 18
		for k in n:
			if k % 2 == 1:
				continue
			var a0 := -amp + 2.0 * amp * k / n
			var a1 := -amp + 2.0 * amp * (k + 1) / n
			var rr := L + float(g["h"]) * 0.5
			draw_circle(pv + Vector2(sin(a0), cos(a0)) * rr, 7.0, Color(0.83, 0.13, 0.21, 0.5 + 0.5 * float(k % 4 == 0)))
	var r := _gancho_rect(inst)
	var th := float(s.get("ang", 0.0))
	var mt := Vector2(r.get_center().x, r.position.y) - Vector2(sin(th), cos(th)) * 96.0   # topo do moitão (lapidado)
	_cabo_aco(pv, mt)
	var mx: Texture2D = Data.tex("cargueiro/moitao")
	if mx != null:   # moitão amarelo/preto + gancho (sprite 100×110, topo em (56,4)), gira com o cabo
		draw_set_transform(mt, -th, Vector2(0.8, 0.8))
		draw_texture_rect(mx, Rect2(Vector2(-56, -4), Vector2(100, 110)), false)
		draw_set_transform(Vector2.ZERO)
	var olho := mt + Vector2(sin(th), cos(th)) * 72.0
	draw_line(olho, r.position + Vector2(8, 0), INK, 4.0)   # lingas do gancho às quinas
	draw_line(olho, Vector2(r.end.x - 8.0, r.position.y), INK, 4.0)
	if String(s["fase"]) == "aviso":   # a roldana range: estalos vermelhos no pivô
		for k in 3:
			var a := -0.6 + k * 0.6
			draw_line(pv + Vector2.from_angle(a - PI / 2.0) * 14.0, pv + Vector2.from_angle(a - PI / 2.0) * 28.0, Color("#d42035"), 4.0, true)
	var ctx: Texture2D = Data.tex("cargueiro/cont_%d" % int(d.get("cor", 4)))
	if ctx != null:
		draw_texture_rect(ctx, r, false)
	if String(s["fase"]) == "balanca":   # rastro do movimento
		var v := float(s.get("vel", 0.0))
		for k in 3:
			var x := r.position.x - signf(v) * (20.0 + k * 16.0) if v > 0.0 else r.end.x - signf(v) * (20.0 + k * 16.0)
			draw_line(Vector2(x, r.position.y + 12.0 + k * 14.0), Vector2(x - signf(v) * 26.0, r.position.y + 12.0 + k * 14.0), Color(1, 1, 1, 0.7), 4.0)

const CONT_CORES := [Color("#d14b4b"), Color("#3f7fd0"), Color("#4fae5b"), Color("#f2a33a"), Color("#8a63d2")]

## Cabo de aço (lapidado): contorno escuro + aço + brilho tracejado.
func _cabo_aco(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, INK, 8.0, true)
	draw_line(a, b, Color("#8a909c"), 4.0, true)
	draw_dashed_line(a, b, Color("#d9dce4"), 1.5, 8.0)

## Contêiner lapidado (prancha `lapida_cena1.png`): no aviso aparece preso por cintas (quadro 0) e uma cinta ESTALA (1) +
## ALVO zebrado com seta que cresce no chão; cai com traços de velocidade (2); no impacto, poeira e lascas (3, ~0,45 s).
func _draw_conteiner(s: Dictionary, d: Dictionary) -> void:
	var fase := String(s.get("fase", "espera"))
	if s.has("alvo") and fase in ["aviso", "salta", "cai"] and not s.get("mar", false):   # ALVO zebrado no chão (cresce e pisca no fim do aviso)
		var alvo: Rect2 = s["alvo"]
		var sc := alvo.size.x / 192.0
		var k := 1.0 - clampf(float(s.get("aviso", 0.0)) / float(d["aviso_s"]), 0.0, 1.0)
		var az: Texture2D = Data.tex("cargueiro/alvo_zebra")
		if az != null:
			var ww := 240.0 * sc * (0.55 + 0.45 * k)
			var pisca := 1.0 if k < 0.7 else 0.6 + 0.4 * sin(t * 30.0)
			draw_texture_rect(az, Rect2(alvo.get_center().x - ww / 2.0, alvo.end.y - 100.0 * sc, ww, 110.0 * sc), false, Color(1, 1, 1, pisca))
	var ctx: Texture2D = Data.tex("cargueiro/cont_%d" % (int(s.get("cor", 0)) % 7))   # mesma arte dos contêineres do palco
	var fx = s.get("fx")
	if fx != null and fx.ativa():
		fx.draw(self, ctx)
		if fx.fase != "":
			return
	if not s.has("alvo") or fase != "espera" or not s.has("plat"):
		return
	var r: Rect2 = s["alvo"]
	if ctx != null:
		draw_texture_rect(ctx, r, false)
	else:
		draw_rect(r, CONT_CORES[int(s.get("cor", 0)) % CONT_CORES.size()])

func _find(tipo: String):
	for inst in list:
		if inst["tipo"] == tipo and _on(inst):
			return inst
	return null

## Marretada nos controles: alavanca da betoneira (despeja), botão da esteira (inverte), pilha de tubos (solta),
## registro (drena a água), gerador (desliga), trava do bate-estaca (segura uma batida).
func hammer_hit(hit: Rect2, heavy: bool, by := -1) -> bool:
	for inst in list:
		if not _on(inst):
			continue
		var d: Dictionary = inst["d"]
		var s: Dictionary = inst["s"]
		if String(inst["tipo"]) == "tubarao" and String(s.get("fase", "")) == "salta" and _tub_rect(inst).intersects(hit):
			s["fase"] = "tonto"   # M10: marretada no focinho: fica tonto e foge
			s["k"] = 0.0
			main.float_text(hit.get_center() + Vector2(0, -60), "TONTO!", Color("#f2c84b"))
			main.spark(hit.get_center(), 8)
			Audio.play("bonk", 0.8, 0.0)
			return true
		if String(inst["tipo"]) == "concha":   # M9: marretada na concha fechada abre na hora
			if String(s.get("fase", "aberta")) == "fechada" and _concha_rect(inst).grow(20).intersects(hit):
				s["fase"] = "aberta"
				s["k"] = 0.0
				main.spark(hit.get_center(), 5)
				main.float_text(hit.get_center() + Vector2(0, -60), "ABRIU!", Color("#f7c6d8"))
				return true
			continue
		if String(inst["tipo"]) == "lustre_cai":   # M8: marretada na corrente solta o lustre
			if String(s.get("fase", "preso")) == "preso" and _lustre_corrente(inst).intersects(hit):
				lustre_solta(inst)
				main.spark(hit.get_center(), 6)
				main.float_text(hit.get_center() + Vector2(0, -60), "ESTALOU!", Color("#f2c84b"))
				return true
			continue
		if String(inst["tipo"]) == "cupula_racha":   # M7: marretada no vidro: a racha cresce e a água sobe um degrau
			if _cup_alvo(inst).intersects(hit):
				cupula_racha(inst)
				main.spark(hit.get_center(), 6)
				main.float_text(hit.get_center() + Vector2(0, -60), "RACHOU!", Color("#9fe8ff"))
				return true
			continue
		if String(inst["tipo"]) == "rede_rasga" and heavy:   # M6: marretada pesada rasga a rede
			var rp = _rede_peca(inst)
			if rp != null and not rp["fallen"] and (rp["rect"] as Rect2).grow_individual(0, 0, 0, 60).intersects(hit):
				main.demo.canteiro.damage(rp, 99, hit.get_center())
				main.float_text(hit.get_center() + Vector2(0, -60), "RASGOU!", Color("#f2c84b"))
				return true
		if String(inst["tipo"]) == "gancho_balanca" and s.has("plat") and _gancho_rect(inst).intersects(hit):
			var lado := 1.0 if hit.get_center().x < _gancho_rect(inst).get_center().x else -1.0   # empurra para longe de quem bateu
			if String(s["fase"]) == "balanca":
				s["dir"] = -float(s["dir"])   # inverte o sentido (mesmo ângulo, velocidade ao contrário)
				s["fi"] = -2.0 * (TAU / float(d["periodo_s"])) * float(s["bt"]) - float(s.get("fi", 0.0))
			else:
				_gancho_solta(inst)
				s["dir"] = lado
			main.spark(hit.get_center(), 5)
			Audio.play("chave", 0.9, -2.0)
			return true
		if not d.has("alvo"):
			continue
		var a: Array = d["alvo"]
		var ar := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		if not ar.intersects(hit):
			continue
		main.spark(ar.get_center(), 5)
		Audio.play("chave", 0.9, -2.0)
		match String(inst["tipo"]):
			"betoneira":
				s["force"] = 1.0
			"esteira":
				s["t"] = float(d["inverte_s"])
			"tubos":
				if not heavy or int(s["pile"]) == 0:
					return true
				var dir := 1 if by < 0 or main.robots[by].position.x < ar.get_center().x else -1
				for k in 3:
					(s["rolling"] as Array).append({"x": ar.get_center().x + dir * k * 40.0, "y": float(d["chao"]), "vx": dir * (520.0 - k * 60.0), "vy": 0.0,
						"rot": 0.0, "hit": {}, "by": by})
				s["pile"] = 0
				s["reload"] = float(d["recarga_s"])
				Audio.play("barril", 0.8, 0.0)
				main.shake(5.0)
			"agua":
				s["dreno"] = float(d["dreno_s"])
			"gerador":
				s["off"] = float(d["desliga_s"])
				main.float_text(ar.get_center() + Vector2(0, -60), "DESLIGOU", Color("#9ff7c8"))
			"bate_estaca":
				s["t"] = float(s["t"]) - 2.0
		return true
	for inst in list:   # D6: marretada pesada na passarela
		if inst["tipo"] == "serra" and _on(inst) and heavy and inst["d"].has("passarela") and not inst["s"].get("broken", false):
			var d2: Dictionary = inst["d"]
			var pr := Rect2(float(d2["passarela"][0]), float(d2["pos"][1]) - 10.0, float(d2["passarela"][1]) - float(d2["passarela"][0]), 34.0)
			if pr.intersects(hit):
				_break_walkway(inst)
				return true
	return false

# ---------------------------------------------------------------- desenho
func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_mecanismos", _pf)

func _draw_perf() -> void:
	var v: Rect2 = main.view_rect().grow(300)
	for inst in list:
		if not _on(inst):
			continue
		var d: Dictionary = inst["d"]
		var s: Dictionary = inst["s"]
		match String(inst["tipo"]):
			"conteiner_cai":
				_draw_conteiner(s, d)
			"gancho_balanca":
				_draw_gancho(inst)
			"mare":
				_draw_mare(inst)
			"conteiner_boia":
				_draw_boia(inst)
			"rede_rasga":
				_draw_rede(inst)
			"tubarao":
				_draw_tubarao(inst)
			"cupula_racha":
				_draw_cupula(inst)
			"geiser":
				_draw_geiser(inst)
			"lustre_cai":
				_draw_lustre(inst)
			"concha":
				_draw_concha(inst)
			"onda_balsa":
				pass   # desenhada na frente do palco (frente): a onda passa POR CIMA dos contêineres
			"betoneira":
				var p := _v(d["pos"])
				var aviso: bool = float(s["t"]) > float(d["ciclo_s"]) - float(d["aviso_s"])
				var spin := t * (6.0 if aviso else 2.0)
				draw_texture_rect(tex["m_betoneira"], Rect2(p + Vector2(-70, -160), Vector2(330, 170)), false)
				# alavanca brilha quando alguém chega perto (dá para acionar a armadilha)
				var lv := Rect2(float(d["alvo"][0]), float(d["alvo"][1]), float(d["alvo"][2]), float(d["alvo"][3]))
				for r in _robots():
					if r.position.distance_to(lv.get_center()) < 140.0:
						draw_arc(lv.get_center(), 30.0 + 3.0 * sin(t * 8.0), 0, TAU, 20, Color(1, 0.9, 0.4, 0.8), 4.0, true)
						break
				var pour := float(s.get("fresh", 0.0)) > float(d["fresco_s"]) - 0.9
				if pour:   # jato de concreto saindo da bica
					var bx := p + Vector2(140, -66)
					var fx := Vector2(float(d["faixa"][0] + d["faixa"][1]) / 2.0, float(d["chao"]) - 10)
					draw_line(bx, fx, Color("#b9b2a6"), 18.0, true)
					draw_line(bx, fx, Color("#d6d0c4"), 8.0, true)
				for k in 3:   # listras do tambor correndo (tambor girando)
					var u := fposmod(spin * 0.15 + k / 3.0, 1.0)
					draw_line(p + Vector2(-40 + u * 90, -140 + u * 30), p + Vector2(-50 + u * 90, -60), Color(1, 0.82, 0.54, 0.8), 6.0, true)
				var f := float(s.get("fresh", 0.0))
				var x0 := float(d["faixa"][0])
				var x1 := float(d["faixa"][1])
				var ch := float(d["chao"])
				if f > 0.0:
					var al := minf(f, 1.0)
					draw_rect(Rect2(x0, ch - 12, x1 - x0, 14), Color(0.72, 0.7, 0.66, al))
					draw_line(Vector2(x0 + 10, ch - 9), Vector2(x1 - 10, ch - 9), Color(1, 1, 1, 0.5 * al), 3.0)
					for k in 4:   # bolhas do concreto fresco
						var bxx := x0 + 20.0 + fmod(k * 37.0 + t * 9.0, x1 - x0 - 40.0)
						draw_circle(Vector2(bxx, ch - 12 - fmod(t * 6.0 + k, 1.0) * 4.0), 3.0, Color(0.9, 0.88, 0.84, al))
				if float(s["t"]) > float(d["ciclo_s"]) - float(d["aviso_s"]) and fmod(t, 0.3) < 0.15:
					draw_rect(Rect2(x0, ch - 4, x1 - x0, 6), Color("#f2c84b"))
			"elevador":
				var x := float(d["base"][0])
				var w := float(d["largura"])
				var y: float = s["y"]
				var mast := float(d["mastro"])
				if String(d.get("estilo", "")) == "balancim":   # M10: plataforma suspensa por cabos (Fachada)
					var cy := float(d.get("cabo_y", y - 400.0))
					for cx in [x + 20.0, x + w - 20.0]:
						draw_line(Vector2(cx, cy), Vector2(cx, y), Color("#4a4f5c"), 4.0, true)
						draw_rect(Rect2(cx - 14, y - 86, 28, 34), Color("#6b7783"))
						draw_circle(Vector2(cx, y - 69), 7.0, Color("#f2c84b"))
					draw_rect(Rect2(x, y, w, 18), Color("#f2c84b"))
					draw_rect(Rect2(x, y + 18, w, 8), INK)
					draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x, y - 54), Vector2(x + w, y - 54), Vector2(x + w, y)]), Color("#8d98a4"), 5.0)
					for k in range(1, 4):
						draw_line(Vector2(x + k * w / 4.0, y - 52), Vector2(x + k * w / 4.0, y), Color("#8d98a4"), 2.5)
					continue
				draw_rect(Rect2(mast - 10, float(d["topo"]) - 60, 20, float(d["base"][1]) - float(d["topo"]) + 60), Color("#8d98a4"))
				for yy in range(int(float(d["topo"]) - 50), int(float(d["base"][1])), 24):
					draw_line(Vector2(mast - 10, yy), Vector2(mast + 10, yy + 12), Color("#6b7783"), 3.0)
				draw_rect(Rect2(x, y, w, 18), Color("#f2c84b"))
				draw_rect(Rect2(x, y + 18, w, 6), INK)
				draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x, y - 70), Vector2(x + w, y - 70), Vector2(x + w, y)]), Color("#6b7783"), 5.0)
				for k in 4:
					draw_line(Vector2(x + 10 + k * w / 4.0, y - 66), Vector2(x + 10 + k * w / 4.0, y), Color("#6b7783"), 2.0)
				var on: bool = s.get("warn", false) or s.get("moving", false)
				draw_circle(Vector2(x + w / 2.0, y - 82), 9.0, Color("#f08a3d") if on and fmod(t, 0.4) < 0.25 else Color("#8a4a2a"))
			"esteira":
				var x0 := float(d["x"][0])
				var x1 := float(d["x"][1])
				var ch := float(d["chao"])
				var dir := int(s.get("dir", int(d["dir"])))
				# a esteira fica PARADA no lugar (antes ela era espelhada a cada inversão e parecia pular); só as setas andam
				draw_texture_rect(tex["m_esteira"], Rect2(x0 - 8, ch - 66, 300, 70), false)
				var blink: bool = s.get("blink", false) and fmod(t, 0.3) < 0.15
				var sc := fposmod(t * float(d["vel"]) * 0.25 * dir, 40.0)
				var x := x0 + sc
				while x < x0 + 230.0:
					var ax := x
					var tip := Vector2(ax + dir * 8.0, ch - 17)
					draw_colored_polygon(PackedVector2Array([tip, Vector2(ax - dir * 8.0, ch - 24), Vector2(ax - dir * 8.0, ch - 10)]), Color("#ffffff") if blink else Color("#f2c84b"))
					x += 40.0
			"tubos":
				var p := _v(d["pos"])
				var spots := [Vector2(0, 0), Vector2(78, 0), Vector2(156, 0), Vector2(39, -66), Vector2(117, -66), Vector2(78, -132)]
				for k in int(s["pile"]):
					draw_texture_rect(tex["m_tubo"], Rect2(p + spots[k] - Vector2(42, 80), Vector2(84, 84)), false)
				for tb in s["rolling"]:
					draw_set_transform(Vector2(tb["x"], tb["y"] - 38.0), tb["rot"], Vector2.ONE)
					draw_texture_rect(tex["m_tubo"], Rect2(-42, -42, 84, 84), false)
					draw_set_transform(Vector2.ZERO)
			"serra":
				var p := _v(d["pos"])
				if not d.has("passarela"):   # serra de BANCADA no chão: pés, tampo e a lâmina subindo pela fenda
					var kb := float(s["k"])
					draw_set_transform(p + Vector2(0, -44 - 30 * kb), t * 30.0 * kb, Vector2.ONE)
					draw_texture_rect(tex["m_serra"], Rect2(-38, -38, 76, 76), false)
					draw_set_transform(Vector2.ZERO)
					draw_rect(Rect2(p.x - 70, p.y - 44, 140, 18), Color("#4a5566"))
					draw_rect(Rect2(p.x - 70, p.y - 44, 140, 5), Color("#71829a"))
					for lx in [p.x - 60, p.x + 50]:
						draw_rect(Rect2(lx, p.y - 26, 10, 26), Color("#3a3f4a"))
					draw_rect(Rect2(p.x - 6, p.y - 47, 12, 6), Color("#2a1a2e"))
					draw_circle(p + Vector2(58, -52), 6.0, Color("#d94a3a") if s.get("warn", false) and fmod(t, 0.2) < 0.1 else Color("#7a2a20"))
					continue
				var x0 := float(d["passarela"][0])
				var x1 := float(d["passarela"][1])
				if s.get("broken", false):   # metades penduradas + serra caída lá embaixo
					s["fall"] = minf(float(s.get("fall", 0.0)) + 0.016, 1.0)
					var mid := (x0 + x1) / 2.0
					draw_set_transform(Vector2(x0, p.y), 0.9, Vector2.ONE)
					draw_rect(Rect2(0, 0, mid - x0, 14), Color("#d9a05e"))
					draw_set_transform(Vector2(x1, p.y), PI - 0.9, Vector2.ONE)
					draw_rect(Rect2(0, -14, x1 - mid, 14), Color("#d9a05e"))
					draw_set_transform(Vector2.ZERO)
					continue
				for x in range(int(x0), int(x1), 40):
					draw_rect(Rect2(x, p.y, 38, 14), Color("#d9a05e"))
				draw_line(Vector2(x0, p.y - 30), Vector2(x1, p.y - 30), Color("#f2c84b"), 4.0)
				var k := float(s["k"])
				draw_set_transform(p + Vector2(0, -12 - 34 * k), t * 30.0 * k, Vector2.ONE)
				draw_texture_rect(tex["m_serra"], Rect2(-38, -38, 76, 76), false)
				draw_set_transform(Vector2.ZERO)
				draw_texture_rect(tex["m_bancada"], Rect2(p + Vector2(-55, -34), Vector2(110, 40)), false)
				if s.get("warn", false) and fmod(t, 0.2) < 0.1:
					draw_circle(p + Vector2(48, -30), 6.0, Color("#d94a3a"))
			"bate_estaca" when String(d.get("estilo", "")) == "guincho":   # M11: guincho na prancha de cima, palete balançando
				var x := float(d["x"])
				var ch := float(d["chao"])
				var hy: float = s.get("y", float(d["topo"]))
				var px := float(d["poste"])
				var arm_y := float(d["alvo"][1]) + 10.0
				draw_rect(Rect2(px - 10, arm_y, 20, float(d["alvo"][1]) + float(d["alvo"][3]) - arm_y), Color("#6b7783"))
				draw_line(Vector2(px, arm_y), Vector2(x + 20, arm_y), Color("#6b7783"), 14.0)
				draw_circle(Vector2(px + 6, arm_y + 80), 24.0, Color("#8d98a4"))
				draw_circle(Vector2(px + 6, arm_y + 80), 9.0, INK)
				var sw := sin(t * 2.2) * 6.0 if s.get("phase", "") != "bate" else 0.0
				draw_line(Vector2(x + 10, arm_y), Vector2(x + sw, hy), Color("#4a4f5c"), 4.0, true)
				draw_rect(Rect2(x - 70 + sw, hy + 70, 140, 16), Color("#8a5a2b"))
				for rr in 3:
					for cc in 4:
						draw_rect(Rect2(x - 66 + sw + cc * 33, hy + 50 - rr * 20, 31, 18), Color("#c8643c"))
						draw_rect(Rect2(x - 66 + sw + cc * 33, hy + 50 - rr * 20, 31, 18), Color("#9a4a2a"), false, 2.0)
				var warn: bool = s.get("phase", "") == "aviso"
				draw_rect(Rect2(x - 70, ch - 6, 140, 8), Color(0.85, 0.29, 0.23, 0.9 if warn and fmod(t, 0.2) < 0.1 else 0.5))
			"bate_estaca":
				# máquina inteira apoiada no piso (esteira + cabine + mastro até a roldana); o martelo sobe e desce
				# pendurado no cabo, na frente do mastro
				var x := float(d["x"])
				var ch := float(d["chao"])
				var hy: float = s.get("y", float(d["topo"]))
				if tex.has("m_bate_torre"):
					draw_texture_rect(tex["m_bate_torre"], Rect2(x - 120, ch - 852, 260, 860), false)
				var crown := Vector2(x, ch - 812)
				draw_line(crown + Vector2(-6, 0), Vector2(x - 6, hy + 8), INK, 3.0, true)
				draw_line(crown + Vector2(6, 0), Vector2(x + 6, hy + 8), INK, 3.0, true)
				draw_texture_rect(tex["m_martelo"], Rect2(x - 70, hy, 140, 110), false)
				var warn: bool = s.get("phase", "") == "aviso"
				draw_rect(Rect2(x - 70, ch - 6, 140, 8), Color(0.85, 0.29, 0.23, 0.9 if warn and fmod(t, 0.2) < 0.1 else 0.5))
			"agua":
				_draw_agua(d, s)
			"vagonete":
				var x0 := float(d["x"][0])
				var x1 := float(d["x"][1])
				var ch := float(d["chao"])
				draw_line(Vector2(x0, ch - 4), Vector2(x1, ch - 4), Color("#3a3a46"), 5.0)
				if float(s["x"]) >= 0.0:
					draw_set_transform(Vector2(s["x"], ch - 110), 0.0, Vector2(int(s.get("dir", 1)), 1))
					draw_texture_rect(tex["m_vagonete"], Rect2(-85, 0, 170, 110), false)
					draw_colored_polygon(PackedVector2Array([Vector2(80, 36), Vector2(260, 0), Vector2(260, 80)]), Color(1, 0.96, 0.78, 0.2))
					draw_set_transform(Vector2.ZERO)
				elif s.get("warn", false):
					var side := x0 if int(floor(float(s["t"]) / float(d["ciclo_s"]))) % 2 == 0 else x1
					draw_circle(Vector2(side, ch - 60), 12.0 + 4.0 * sin(t * 20.0), Color(1, 0.85, 0.3, 0.8))
			"gerador":
				var p := _v(d["pos"])
				draw_texture_rect(tex["m_gerador"], Rect2(p - Vector2(85, 130), Vector2(170, 130)), false, Color(0.6, 0.6, 0.6) if float(s.get("off", 0.0)) > 0.0 else Color.WHITE)
				var cb := _v(d["cabo"])
				draw_polyline(PackedVector2Array([p + Vector2(80, -70), p.lerp(cb, 0.5) + Vector2(0, 60), cb]), INK, 6.0, true)
				if s.get("spark", false):
					for k in 4:
						var a := randf() * TAU
						draw_line(cb, cb + Vector2.from_angle(a) * randf_range(10, 26), Color("#ffd36b"), 3.0, true)

## Água da Fundação (M7): o piso alaga por cima das lajes e TRANSBORDA pelas bordas em cachoeiras que somem no
## vazio; enquanto sobe, ela despeja das bordas quebradas do teto (de onde vem a água).
func _draw_agua(d: Dictionary, s: Dictionary) -> void:
	var h: float = s["h"]
	var x0 := float(d["x"][0])
	var x1 := float(d["x"][1])
	var ch := float(d["chao"])
	var wcol := Color(0.33, 0.58, 0.72, 0.55)
	var foam := Color(0.85, 0.95, 0.98, 0.85)
	if s.get("pour", false):   # despejando das bordas quebradas do teto; cai na primeira coisa embaixo (plataforma ou piso)
		var hb := String(main.level.prop("buraco1", "10,30")).split(",")
		var top: float = main.level.etapa_rect(int(d.get("etapa", 2))).position.y + 128.0
		var ct = main.demo.canteiro
		for xe in [float(hb[0]) * T + 16.0, float(hb[1]) * T - 16.0]:
			var bot := ch - h
			if ct != null and is_instance_valid(ct):
				for p in ct.parts:
					var pr: Rect2 = p["rect"]
					if p["kind"] == "estaca" and not p["fallen"] and xe > pr.position.x and xe < pr.end.x and pr.position.y > top:
						bot = minf(bot, pr.position.y)
			_jorro(xe, top, bot, foam)
	if h < 3.0:
		return
	# trechos de piso sólido dentro da faixa (as 3 lajes): lâmina d'água em cada um, cachoeira em cada borda
	var row := int((ch + 8.0) / T)
	var runs: Array = []
	var cx := int(x0 / T)
	while cx < int(ceil(x1 / T)):
		if main.level.is_solid(Vector2i(cx, row)):
			var c0 := cx
			while cx < int(ceil(x1 / T)) and main.level.is_solid(Vector2i(cx, row)):
				cx += 1
			runs.append(Vector2(c0 * T, cx * T))
		else:
			cx += 1
	for rn in runs:
		var a: float = rn.x
		var b: float = rn.y
		draw_rect(Rect2(a, ch - h, b - a, h), wcol)
		var wave := PackedVector2Array()
		var xx := a
		while xx <= b:
			wave.append(Vector2(xx, ch - h + sin(t * 3.0 + xx * 0.03) * 2.5))
			xx += 16.0
		draw_polyline(wave, foam, 3.0, true)
		for e in [[a, -1.0], [b, 1.0]]:
			if main.level.is_solid(Vector2i(int(floor((e[0] + e[1] * 8.0) / T)), row)):
				continue
			_cachoeira(float(e[0]), float(e[1]), ch, h, wcol, foam)

func _cachoeira(ex: float, sg: float, ch: float, h: float, wcol: Color, foam: Color) -> void:
	var wv := clampf(6.0 + h * 0.3, 8.0, 34.0)   # mais água = cachoeira mais grossa
	var L := 420.0
	var n := 7
	for k in n:   # desce pela borda da laje e some no escuro
		var y0 := ch - h + k * L / n
		var y1 := ch - h + (k + 1) * L / n
		var o0 := sg * (2.0 + 10.0 * sqrt(float(k) / n))
		var o1 := sg * (2.0 + 10.0 * sqrt(float(k + 1) / n))
		var al := wcol.a * (1.0 - float(k) / n)
		var wb0 := sin(t * 7.0 + y0 * 0.04) * 2.0
		var wb1 := sin(t * 7.0 + y1 * 0.04) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(ex + o0, y0), Vector2(ex + o0 + sg * (wv + wb0), y0), Vector2(ex + o1 + sg * (wv + wb1), y1), Vector2(ex + o1, y1)]),
			Color(wcol.r + 0.1, wcol.g + 0.1, wcol.b + 0.08, al))
	for i in 6:   # fios de espuma correndo para baixo
		var u := fmod(t * 1.6 + i * 0.17, 1.0)
		var y := ch - h + u * L
		var ox := sg * (2.0 + 10.0 * sqrt(u) + wv * (0.2 + 0.6 * fmod(i * 0.43, 1.0)))
		draw_line(Vector2(ex + ox, y), Vector2(ex + ox, y + 22.0), Color(foam.r, foam.g, foam.b, foam.a * (1.0 - u)), 2.5, true)
	draw_arc(Vector2(ex, ch - h + 6.0), 6.0, -PI / 2.0 if sg > 0 else PI, 0.0 if sg > 0 else PI * 1.5, 6, foam, 3.0, true)   # lábio da borda

## Jorro de água caindo de cima (borda do teto) até `bot`: coluna que ondula, miolo claro, espuma descendo e respingo.
func _jorro(xe: float, top: float, bot: float, foam: Color) -> void:
	var L := bot - top
	if L < 10.0:
		return
	var n := int(L / 24.0) + 1
	var lft := PackedVector2Array()
	var rgt := PackedVector2Array()
	for k in n + 1:
		var y := top + L * k / n
		var w := 9.0 + 7.0 * float(k) / n + sin(t * 9.0 + y * 0.05) * 1.6   # alarga um pouco ao cair
		lft.append(Vector2(xe - w + sin(t * 6.0 + y * 0.03) * 1.5, y))
		rgt.append(Vector2(xe + w + sin(t * 6.0 + y * 0.03) * 1.5, y))
	var poly := lft.duplicate()
	rgt.reverse()
	poly.append_array(rgt)
	draw_colored_polygon(poly, Color(0.5, 0.76, 0.88, 0.55))
	draw_line(Vector2(xe, top), Vector2(xe, bot), Color(0.82, 0.94, 0.98, 0.45), 6.0, true)
	for i in 10:
		var u := fmod(t * 2.2 + i * 0.1, 1.0)
		var x := xe + (float(i % 3) - 1.0) * 6.0
		draw_line(Vector2(x, top + u * L), Vector2(x, minf(top + u * L + 26.0, bot)), foam, 2.0, true)
	for i in 7:   # respingo e névoa onde bate
		var u := fmod(t * 2.6 + i * 0.143, 1.0)
		var a := -PI * (0.12 + 0.76 * fmod(i * 0.37, 1.0))
		draw_circle(Vector2(xe, bot) + Vector2.from_angle(a) * (6.0 + 26.0 * u), 4.0 * (1.0 - u) + 1.0, Color(foam.r, foam.g, foam.b, 0.9 * (1.0 - u)))
	draw_circle(Vector2(xe, bot - 2.0), 16.0, Color(0.9, 0.97, 1.0, 0.35))

