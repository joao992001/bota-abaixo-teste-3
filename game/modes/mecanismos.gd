extends Node2D
## MECANISMOS DA FASE (cartilha do mapa, Z7): armadilhas/máquinas próprias de cada fase, com aviso visível, ciclo legível
## e interação do jogador (marretar alavanca/botão/registro/trava). Cada TIPO é uma receita reaproveitável; a fase só lista
## quais usa, onde e em que etapa: data/modos.json → demolicao.mecanismos.<cena> (ex.: "fase1").
## Golpe da máquina = do ambiente (by -1), a não ser que um jogador a acione.
## Tipos: betoneira (concreto fresco), elevador (plataforma de cremalheira), esteira (leva para fora; botão inverte),
## tubos (marretar solta tubos rolando), serra (sobe da bancada em ciclo), bate_estaca (martela uma faixa),
## agua (alagamento; registro drena), vagonete (passa varrendo o piso), gerador (faísca; com água dá choque).

const T := 64.0
const INK := Color("#2a1a2e")
var main: Node
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
	queue_redraw()

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
				s["y"] = o.y - h - 260.0
				s["vy"] = 0.0
				s["aviso"] = float(d["aviso_s"])
				s["fase"] = "aviso"
				s["cor"] = main.rng.randi() % 5
				s["hit"] = {}
				Audio.play("gancho", 0.7, -2.0)   # amarras estalando
		"aviso":
			s["aviso"] = float(s["aviso"]) - dt
			if float(s["aviso"]) <= 0.0:
				s["fase"] = "cai"
				s["y"] = main.view_rect().position.y - (s["alvo"] as Rect2).size.y * 0.55   # cai de onde estava pendurado
				Audio.play("alarme", 1.4, -8.0)
		"cai":
			var alvo: Rect2 = s["alvo"]
			s["vy"] = minf(float(s["vy"]) + 4000.0 * dt, float(d["vel_queda"]))
			s["y"] = minf(float(s["y"]) + float(s["vy"]) * dt, alvo.position.y if not s["mar"] else alvo.position.y + 400.0)
			var cr := Rect2(alvo.position.x, float(s["y"]), w, h)
			for r in _robots():
				if r.rect().intersects(cr) and not s["hit"].has(r.pid):
					s["hit"][r.pid] = true
					r.take_hit(1 if r.position.x >= cr.get_center().x else -1, "mec_conteiner", -1)
			if not s["mar"] and float(s["y"]) >= alvo.position.y:
				s["fase"] = "espera"
				main.shake(8.0)
				Audio.play("caixote_pancada", 0.6, 0.0)
				main.dust(Vector2(alvo.get_center().x, alvo.end.y), 1.8)
				var ct = main.demo.canteiro   # racha a peça do palco em que bateu
				if ct != null and is_instance_valid(ct):
					for p in ct.parts:
						if not p["fallen"] and (p["rect"] as Rect2).intersects(Rect2(alvo.position.x, alvo.end.y - 4.0, w, 12.0)):
							ct.damage(p, int(d.get("dano_peca", 2)), Vector2(alvo.get_center().x, alvo.end.y))
				s["plat"] = _body(alvo)   # fica como plataforma nova
				s["parado"] = float(d.get("fica_s", 14.0))
			elif s["mar"] and float(s["y"]) >= alvo.position.y + 400.0:
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

const CONT_CORES := [Color("#d14b4b"), Color("#3f7fd0"), Color("#4fae5b"), Color("#f2a33a"), Color("#8a63d2")]

func _draw_conteiner(s: Dictionary, d: Dictionary) -> void:
	if not s.has("alvo"):
		return
	var alvo: Rect2 = s["alvo"]
	var fase := String(s.get("fase", "espera"))
	if fase == "aviso" or fase == "cai":   # SOMBRA VERMELHA onde vai cair (cresce e pisca no fim do aviso)
		var k := 1.0 - clampf(float(s.get("aviso", 0.0)) / float(d["aviso_s"]), 0.0, 1.0)
		var a := 0.35 + 0.35 * k + (0.2 * sin(t * 30.0) if k > 0.6 else 0.0)
		var cx := alvo.get_center().x
		draw_set_transform(Vector2(cx, alvo.end.y), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, alvo.size.x * (0.45 + 0.25 * k), Color(0.85, 0.1, 0.1, a))
		draw_set_transform(Vector2.ZERO)
		for k2 in 2:   # faixas de perigo descendo até a sombra
			draw_line(Vector2(alvo.position.x + 10.0 + k2 * (alvo.size.x - 20.0), main.view_rect().position.y), Vector2(alvo.position.x + 10.0 + k2 * (alvo.size.x - 20.0), alvo.end.y), Color(0.85, 0.1, 0.1, 0.25 * a), 4.0)
	var y := float(s.get("y", alvo.position.y)) if fase != "espera" else alvo.position.y
	if fase == "aviso":
		y = main.view_rect().position.y - alvo.size.y * 0.55 + sin(t * 40.0) * 3.0   # aparece balançando no alto (amarras)
	var r := Rect2(alvo.position.x, y, alvo.size.x, alvo.size.y)
	var cor: Color = CONT_CORES[int(s.get("cor", 0)) % CONT_CORES.size()]
	draw_rect(r, cor)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 8.0)), cor.darkened(0.3))
	for k3 in range(1, 6):   # nervuras do contêiner
		var x := r.position.x + k3 * r.size.x / 6.0
		draw_line(Vector2(x, r.position.y + 10.0), Vector2(x, r.end.y - 6.0), cor.darkened(0.22), 4.0)
	draw_rect(r, INK, false, 4.0)

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

