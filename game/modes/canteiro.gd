extends Node2D
## CANTEIRO DE OBRAS (Derruba): estrutura destrutível montada por código (não por tiles). Relatório 02.
## - Laje central em 6 trechos de 4x2 tiles (cols 8..31, topo na linha 13). Os 2 do meio (núcleo, sobre pilares) NUNCA caem;
##   os 4 de fora (sobre escoras) caem DE VEZ. Andaimes (topo 3 tiles acima da laje) e viga pendurada (5 acima) também.
## - Estados: íntegro → rachado → crítico (fita zebrada, treme, solta pedrinha) → desaba (pedaços com física).
##   A colisão some no MESMO quadro em que o trecho começa a cair (nunca antes, nunca depois).
## - Dano: só golpes fortes (marretada pesada) e robô arremessado batendo forte; e o CICLO DA OBRA (calma → sirene e fita
##   zebrada marcando o trecho → ele cede). Números: data/modos.json → demolicao.canteiro.

const T := 64
## Estruturas das fases vêm do MANIFESTO do mapa (data/mapas/<modo>/<mapa>.json → cenas[].estruturas: lajes, andaimes,
## vigas, pilares, terreos [base fixa], estacas, grelhas, piso, entulhos). Aqui só o layout da fase do Laboratório
## (ferramenta), escolhido no .lvl com "canteiro: lab".
const LAYOUTS := {
	"lab": {"seg_x": [3, 7, 11, 15, 19, 23], "nucleo": [2, 3], "laje_y": 12, "andaimes": [[5, 9, 4], [20, 9, 4]],
		"vigas": [[11, 6, 6], [24, 4, 4]], "pilares": [12, 17]},
}
var SEG_X: Array = []
var NUCLEO: Array = []
var LAJE_Y := 13
var ANDAIMES: Array = []
## vigas penduradas por cabos [col, linha do topo, largura]: a grande no meio, 2 baixas (2 tiles acima da laje, dá para
## passar por baixo) e 2 no alto (alcançáveis com pulo duplo a partir dos andaimes). Todas caem de vez.
var VIGAS: Array = []
var PILARES: Array = []
var ETAPA_LAJE := 1            # cena (ordem) que tem a laje com andaimes, vigas e térreo

var main: Node
var cfg: Dictionary
var parts: Array = []          # {kind, rect, hp, max, nucleo, body, state, crit_t, warn_t, fallen, shake, idx}
var owner_of := {}             # Vector2i -> part (para bots e para agarrar a borda)
var laje_vira_rampa := false   # rota moderada: a laje sai sem entulho (vira a rampa da transição)
var debris: Array = []         # pedaços caindo {tex, rect, pos, vel, rot, spin, t}
var crumbs: Array = []         # pedrinhas {pos, vel, t}
var prev_speed := {}
var t := 0.0
var cycle_state := "calma"
var target = null
var tex := {}
var extras: Array = []        # cenas seguintes do manifesto (estacas, grelhas, piso, entulhos)
var quiet := false             # virada da fase: desaba tudo sem um texto por peça
var pillars_down := false
var mute_hit := false          # marretada do robô: o som é o clang aprovado (demolicao.gd), não a pancada da peça      # virada: os pilares do núcleo também caem

func setup(m: Node, lv) -> void:
	main = m
	cfg = m.demo.cfg["canteiro"]
	for k in ["laje_0", "laje_1", "laje_2", "andaime", "viga", "viga4", "pilar", "escora", "laje_pedaco_0", "laje_pedaco_2"]:
		tex[k] = Data.tex("canteiro/" + k)
	for k in ["plataforma", "estaca", "grelha"]:
		tex[k] = Data.tex("fase1/" + k)
	var lay: Dictionary = LAYOUTS.get(String(lv.prop("canteiro", "lab")), LAYOUTS["lab"])
	var cs: Array = MapaReg.cenas(m.game_mode, lv.id)
	if not cs.is_empty():
		lay = _layout_do_mapa(cs)
	SEG_X = lay["seg_x"]
	NUCLEO = lay["nucleo"]
	LAJE_Y = int(lay["laje_y"])
	ANDAIMES = lay["andaimes"]
	VIGAS = lay["vigas"]
	PILARES = lay["pilares"]
	ETAPA_LAJE = int(lay.get("etapa_laje", 1))
	for i in SEG_X.size():
		_add("laje", Rect2(SEG_X[i] * T, LAJE_Y * T, 4 * T, 2 * T), int(cfg["laje_hp"]), i in NUCLEO, false, i, ETAPA_LAJE)
	for i in ANDAIMES.size():
		var a: Array = ANDAIMES[i]
		_add("andaime", Rect2(a[0] * T - 6, a[1] * T, a[2] * T + 12, 20), int(cfg["andaime_hp"]), false, true, i, ETAPA_LAJE)
	for i in VIGAS.size():
		var v: Array = VIGAS[i]
		_add("viga", Rect2(v[0] * T, v[1] * T, v[2] * T, 26), int(cfg["viga_hp"]), false, true, i, ETAPA_LAJE)
	var ters: Array = lay.get("terreos", [])
	for i in ters.size():   # chão do térreo (dos lados): firme; só some na virada da fase (collapse_all)
		var g: Array = ters[i]
		_add("terreo", Rect2(g[0] * T, g[1] * T, g[2] * T, g[3] * T), 999, true, false, i, ETAPA_LAJE)
	extras = lay.get("cenas_extra", [])
	for c in extras:   # cenas seguintes: plataformas sobre estaca e grelhas de poço
		var n: int = c["ordem"]
		for i in c.get("estacas", []).size():
			var e: Array = c["estacas"][i]
			_add("estaca", Rect2(e[0] * T, e[1] * T, e[2] * T, 22), int(cfg["estaca_hp"]), false, true, i, n)
		for i in c.get("pranchas", []).size():   # Fachada: pranchas de andaime (racham com quem fica parado; G12 move)
			var pr: Array = c["pranchas"][i]
			_add("prancha", Rect2(pr[0] * T + 10, pr[1] * T, pr[2] * T - 20, 22), int(cfg["prancha_hp"]), false, true, i, n)
		for i in c.get("grelhas", []).size():   # poços de drenagem (abrem KO)
			var gr: Array = c["grelhas"][i]
			_add("grelha", Rect2(gr[0] * T, gr[1] * T, gr[2] * T, 40), int(cfg["grelha_hp"]), false, false, i, n)
	lv.extra_solid = func(c: Vector2i) -> bool: return owner_of.has(c)
	lv.grab_solid = func(c: Vector2i) -> bool: return owner_of.has(c) and owner_of[c]["kind"] == "laje"

func _add(kind: String, r: Rect2, hp: int, nucleo: bool, oneway: bool, idx: int, etapa := 1) -> void:
	var body: StaticBody2D = AnimatableBody2D.new() if kind in ["andaime", "estaca", "prancha"] else StaticBody2D.new()   # G12 move o deque (andaime no Térreo, plataforma sobre estaca na Fundação)
	if body is AnimatableBody2D:
		body.sync_to_physics = false
	body.collision_layer = 2 if oneway else 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = r.size
	cs.shape = shp
	cs.position = r.get_center()
	cs.one_way_collision = oneway
	body.add_child(cs)
	add_child(body)
	var p := {"kind": kind, "rect": r, "hp": hp, "max": hp, "nucleo": nucleo, "body": body, "state": 0, "crit_t": 0.0,
		"warn_t": 0.0, "fallen": false, "shake": 0.0, "idx": idx, "evt": "", "y0": r.position.y, "oneway": oneway, "etapa": etapa,
		"escora_hp": int(cfg["escora_hp"]) if kind == "laje" and not nucleo else 0}
	body.set_meta("canteiro", p)
	parts.append(p)
	_claim(p)

func _claim(p: Dictionary) -> void:
	var r: Rect2 = p["rect"]
	for x in range(int(r.position.x / T), int(ceil(r.end.x / T))):
		for y in range(int(r.position.y / T), int(ceil(r.end.y / T))):
			owner_of[Vector2i(x, y)] = p

func _unclaim(p: Dictionary) -> void:
	for c in owner_of.keys():
		if owner_of[c] == p:
			owner_of.erase(c)

## Eventos: G12 sobe/desce o deque do andaime (o corpo anda junto, quem está em cima vai junto).
func move_part(p: Dictionary, y: float) -> void:
	if p["fallen"] or not is_instance_valid(p["body"]):
		return
	p["body"].position.y = y - p["y0"]
	if absf(p["rect"].position.y - y) < 0.01:
		return
	var old_row := int(p["rect"].position.y / T)
	p["rect"].position.y = y
	if int(y / T) != old_row:
		_unclaim(p)
		_claim(p)

## G13 na Fundação (A14): o guindaste desce uma viga pelo poço e a deixa pendurada sobre a cena (peça GERADA: não
## conta na destruição). Devolve a peça.
func viga_pelo_poco(r: Rect2, n: int) -> Dictionary:
	_add("viga", r, int(cfg["viga_hp"]), false, true, 90 + parts.size(), n)
	var p: Dictionary = parts[-1]
	p["gerada"] = true
	return p

## G13: o cabo rompe — a viga perde a colisão (o evento cuida da queda e do desenho).
func drop_body(p: Dictionary) -> void:
	if is_instance_valid(p["body"]):
		p["body"].queue_free()
	_unclaim(p)
	if p == target:
		target = null

## G13 fim: o guindaste pendura a viga de volta no lugar.
func restore_body(p: Dictionary, r: Rect2) -> void:
	if is_instance_valid(p["body"]):
		p["body"].queue_free()
	p["rect"] = r
	var body := StaticBody2D.new()
	body.collision_layer = 2 if p["oneway"] else 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = r.size
	cs.shape = shp
	cs.position = r.get_center()
	cs.one_way_collision = p["oneway"]
	body.add_child(cs)
	add_child(body)
	body.set_meta("canteiro", p)
	p["body"] = body
	p["y0"] = r.position.y
	_claim(p)

# ---------------------------------------------------------------- dano
## Aplica dano estrutural. O núcleo só treme e solta poeira.
func damage(p: Dictionary, amount: int, at: Vector2) -> void:
	var _pf := Perf.t0()
	damage_perf(p, amount, at)
	Perf.add("sub_canteiro_dano", _pf)

func damage_perf(p: Dictionary, amount: int, at: Vector2) -> void:
	if p["fallen"] or p["crit_t"] > 0.0 or p["evt"] != "" or p["kind"] == "terreo":
		return
	p["shake"] = 0.3
	main.dust(at, 0.9)
	if p["nucleo"]:
		if not mute_hit:
			Audio.play("caixote_pancada", 0.6, -4.0)
		return
	p["hp"] = maxi(int(p["hp"]) - amount, 0)
	var frac := float(p["hp"]) / float(p["max"])
	p["state"] = 0 if frac > 0.67 else (1 if frac > 0.34 else 2)
	if not mute_hit:
		Audio.play("caixote_pancada", 0.55 + 0.1 * p["state"], -1.0)
	main.spark(at, 3 + 2 * p["state"])
	for k in 4 + 4 * p["state"]:
		_crumb(p)
	if p["hp"] <= 0:
		p["state"] = 2
		p["crit_t"] = float(cfg["aviso_queda_s"])   # aviso final: range, treme forte, pedrinhas caindo
		Audio.play("terremoto", 1.5, -4.0)

## Layout a partir das cenas do manifesto. Limitação atual (documentada no manual): laje + andaimes + vigas + térreo numa
## cena só; estacas/grelhas/entulhos em qualquer cena. Tipo novo de estrutura = código novo aqui.
func _layout_do_mapa(cs: Array) -> Dictionary:
	var lay := {"seg_x": [], "nucleo": [], "laje_y": 13, "andaimes": [], "vigas": [], "pilares": [], "terreos": [], "cenas_extra": []}
	for c in cs:
		var es: Dictionary = c.get("estruturas", {})
		if es.has("lajes"):
			lay["seg_x"] = es["lajes"]["seg_x"].map(func(v): return int(v))
			lay["nucleo"] = es["lajes"].get("nucleo", []).map(func(v): return int(v))   # JSON dá 2.0: "2 in [2.0]" é falso
			lay["laje_y"] = int(es["lajes"]["linha"])
			lay["etapa_laje"] = int(c["ordem"])
			for k in ["andaimes", "vigas", "terreos"]:
				lay[k] = es.get(k, []).map(func(a): return a.map(func(v): return int(v)))
			lay["pilares"] = es.get("pilares", []).map(func(v): return int(v))
		if es.has("estacas") or es.has("grelhas") or es.has("entulhos") or es.has("pranchas"):
			var ex: Dictionary = es.duplicate()
			ex["ordem"] = int(c["ordem"])
			lay["cenas_extra"].append(ex)
	return lay

## Etapa em que o jogo está (fase em etapas); peças da outra etapa ficam fora de eventos, caixas e ciclo.
func etapa_now() -> int:
	var et = main.demo.etapas
	return et.etapa if et != null and is_instance_valid(et) else 1

## Onde a marretada pega a peça (a estaca inclui o pilar embaixo da plataforma).
func hit_rect(p: Dictionary) -> Rect2:
	var r: Rect2 = p["rect"]
	if p["kind"] == "estaca":
		return r.merge(Rect2(r.get_center().x - 22.0, r.end.y, 44.0, _piso(int(p["etapa"])) - r.end.y))
	return r

## Marretada pesada: acerta o trecho à frente (no chão onde a marreta bate) ou, com ▼, o trecho embaixo dos pés.
func hammer(r, hit: Rect2, down: bool, critico := false) -> bool:
	if down and r.is_on_floor():
		var c := Vector2i(int(r.position.x / T), int((r.position.y + 6.0) / T))
		if owner_of.has(c):
			damage(owner_of[c], int(cfg["dano_pesada"]), r.position)
			return true
	var reach := hit.grow_individual(0, 0, 0, 16)
	for p in parts:   # escoras (D4): 2 pesadas quebram e o trecho de cima entra em queda
		if p["kind"] == "laje" and not p["fallen"] and int(p["escora_hp"]) > 0 and p["crit_t"] <= 0.0:
			var er := Rect2(p["rect"].position.x + 24.0, p["rect"].end.y, p["rect"].size.x - 48.0, 3.5 * T)
			if reach.intersects(er):
				p["escora_hp"] = int(p["escora_hp"]) - 1
				main.spark(reach.get_center(), 5)
				Audio.play("caixote_pancada", 0.8, -1.0)
				if int(p["escora_hp"]) <= 0:
					debris.append({"tex": tex["escora"], "size": Vector2(276, 532), "pos": Vector2(p["rect"].get_center().x, p["rect"].end.y + 250),
						"vel": Vector2(randf_range(-80, 80), 0), "rot": 0.0, "spin": randf_range(-0.8, 0.8), "t": 0.0})
					main.float_text(p["rect"].get_center() + Vector2(0, 60), "ESCORA QUEBROU!", Color("#f2c84b"))
					p["hp"] = 1
					damage(p, 1, reach.get_center())
				return true
	for p in parts:
		if not p["fallen"] and reach.intersects(hit_rect(p)):
			var at := Vector2(clampf(reach.get_center().x, p["rect"].position.x, p["rect"].end.x), p["rect"].position.y)
			if critico and not p["nucleo"] and not hit_rect(p).grow(2).has_point(r.position + Vector2(0, 8)):   # A47: CRÍTICO quebra a peça
				damage(p, 9999, at)
				if p["crit_t"] > 0.0:
					p["crit_t"] = 0.0
					_collapse(p)
				return true
			damage(p, int(cfg["dano_pesada"]), at)
			return true
	return false

func _collapse(p: Dictionary) -> void:
	var _pf := Perf.t0()
	_collapse_perf(p)
	Perf.add("sub_canteiro_desaba", _pf)

## A53b (2026-11-28): REAÇÃO EM CADEIA — a peça que desaba racha as que estavam logo acima dela (perdem o apoio); as
## que já estavam fracas caem também (com o aviso de queda normal, então a cadeia é legível). Sem isso as vigas altas e
## os andaimes das pontas quase nunca eram quebrados e a destruição empacava em ~60%.
func _cascata(p: Dictionary) -> void:
	var dano := int(cfg.get("cascata_dano", 0))
	if dano <= 0 or p["nucleo"]:
		return
	var r: Rect2 = p["rect"]
	var alcance := float(cfg.get("cascata_alcance_tiles", 6)) * T
	for q in parts:
		if q == p or q["fallen"] or q["nucleo"] or q["kind"] in ["terreo", "entulho"] or int(q["etapa"]) != int(p["etapa"]):
			continue
		var qr: Rect2 = q["rect"]
		var acima := qr.end.y <= r.position.y + 8.0 and r.position.y - qr.end.y <= alcance
		var cobre := minf(qr.end.x, r.end.x) - maxf(qr.position.x, r.position.x) >= T * 0.5
		if acima and cobre:
			damage(q, dano, Vector2(clampf(r.get_center().x, qr.position.x, qr.end.x), qr.end.y))

func _collapse_perf(p: Dictionary) -> void:
	p["fallen"] = true
	_cascata(p)
	if is_instance_valid(p["body"]):
		p["body"].queue_free()   # a colisão some agora, junto com o começo da queda
	for c in owner_of.keys():
		if owner_of[c] == p:
			owner_of.erase(c)
	if p == target:
		target = null
	var r: Rect2 = p["rect"]
	main.shake(12.0 if p["kind"] == "laje" else 8.0)
	Audio.play("caixote_quebra", 0.6, 3.0)
	Audio.play("explosao", 0.7, -6.0)
	for x in range(int(r.position.x), int(r.end.x), 48):
		main.dust(Vector2(x + 24, r.position.y + 10), 1.4)
	var mid: float = r.get_center().x
	var out := -1.0 if mid < 20 * T else 1.0
	match p["kind"]:
		"prancha":
			for k in 3:   # a prancha parte em pedaços de madeira
				debris.append({"tex": null, "size": Vector2(r.size.x / 3.0, 22), "pos": Vector2(r.position.x + (k + 0.5) * r.size.x / 3.0, r.get_center().y),
					"vel": Vector2(randf_range(-120, 120), randf_range(-160, 20)), "rot": 0.0, "spin": randf_range(-2.4, 2.4), "t": 0.0, "cor": Color("#c98a4b")})
		"estaca", "grelha", "entulho":
			var tx: Texture2D = tex["plataforma"] if p["kind"] == "estaca" else (tex["grelha"] if p["kind"] == "grelha" else tex["laje_pedaco_2"])
			debris.append({"tex": tx, "size": r.size + Vector2(0, 18), "pos": r.get_center(), "vel": Vector2(randf_range(-60, 60), 40),
				"rot": 0.0, "spin": randf_range(-1.6, 1.6), "t": 0.0})
			if p["kind"] == "estaca":
				debris.append({"tex": tex["estaca"], "size": Vector2(44, 300), "pos": Vector2(r.get_center().x, r.end.y + 150), "vel": Vector2(randf_range(-80, 80), 0),
					"rot": 0.0, "spin": randf_range(-1.2, 1.2), "t": 0.0})
			if p["kind"] == "grelha" and not quiet:
				main.float_text(r.get_center() + Vector2(0, -60), "O POÇO ABRIU!", Color("#f2c84b"))
		"laje" when laje_vira_rampa:
			pass
		"laje":
			for k in 8:
				var px := r.position.x + 20 + (k % 4) * 64 + randf_range(-8, 8)
				var py := r.position.y + 24 + (k / 4) * 56
				debris.append({"tex": Data.tex("canteiro/laje_pedaco_%d" % (k % 6)), "size": Vector2(96, 80) * randf_range(0.9, 1.3),
					"pos": Vector2(px, py), "vel": Vector2(out * randf_range(20, 160) + (px - mid) * 0.6, randf_range(-260, -60)),
					"rot": randf_range(-0.3, 0.3), "spin": randf_range(-5, 5), "t": 0.0})
			if not p["nucleo"]:   # as escoras vão junto, tombando
				debris.append({"tex": tex["escora"], "size": Vector2(276, 532), "pos": Vector2(mid, r.end.y + 250),
					"vel": Vector2(out * 90, 40), "rot": 0.0, "spin": out * 1.4, "t": 0.0})
			if not quiet:
				main.float_text(r.get_center() + Vector2(0, -80), "DESABOU!", Color("#f2c84b"))
		"andaime":
			# a torre tomba para fora e cai
			debris.append({"tex": tex["andaime"], "size": Vector2(340, 788), "pos": Vector2(mid, r.position.y + 384),
				"vel": Vector2(out * 140, -40), "rot": 0.0, "spin": out * 1.1, "t": 0.0})
		"viga":
			debris.append({"tex": tex["viga"] if r.size.x > 300.0 else tex["viga4"], "size": Vector2(r.size.x + 20.0, 46), "pos": r.get_center(), "vel": Vector2(0, 60),
				"rot": 0.0, "spin": 2.2, "t": 0.0})
			if not quiet:
				main.float_text(r.get_center() + Vector2(0, -60), "CABO ROMPEU!", Color.WHITE)

func _crumb(p: Dictionary) -> void:
	var r: Rect2 = p["rect"]
	crumbs.append({"pos": Vector2(randf_range(r.position.x + 8, r.end.x - 8), r.end.y - 4), "vel": Vector2(randf_range(-30, 30), randf_range(20, 120)), "t": 0.0})

# ---------------------------------------------------------------- quadro a quadro
func _physics_process(dt: float) -> void:
	var _pf := Perf.t0()
	_physics_process_perf(dt)
	Perf.add("canteiro", _pf)

func _physics_process_perf(dt: float) -> void:
	if main == null or main.paused:
		return
	t += dt
	# robô arremessado batendo forte na estrutura
	for r in main.robots:
		if not r.alive:
			continue
		var spd: float = prev_speed.get(r, 0.0)
		var launched: bool = r.stun_t > 0.0 or r.recover_t > 0.0
		if launched and spd >= float(cfg["impacto_vel"]):
			for i in r.get_slide_collision_count():
				var col: Object = r.get_slide_collision(i).get_collider()
				if col != null and col.has_meta("canteiro"):
					var strong := spd >= float(cfg["impacto_forte_vel"])
					damage(col.get_meta("canteiro"), int(cfg["dano_impacto_forte"] if strong else cfg["dano_impacto"]), r.position)
					main.impact_fx(r.position + Vector2(0, -10), 0, 0.6 if strong else 0.4)
					spd = 0.0
					break
		prev_speed[r] = r.velocity.length() if spd > 0.0 or launched else 0.0
	for p in parts:
		p["shake"] = maxf(p["shake"] - dt, 0.0)
		if p["crit_t"] > 0.0 and not p["fallen"]:
			p["crit_t"] -= dt
			if randf() < 0.5:
				_crumb(p)
			if p["crit_t"] <= 0.0:
				_collapse(p)
		elif p["state"] == 2 and not p["fallen"] and randf() < 0.06:
			_crumb(p)
	_update_cycle(dt)
	for d in debris:
		d["t"] += dt
		d["vel"].y += 1500.0 * dt
		d["pos"] += d["vel"] * dt
		d["rot"] += d["spin"] * dt
	debris = debris.filter(func(d): return d["t"] < 2.5)
	for c in crumbs:
		c["t"] += dt
		c["vel"].y += 900.0 * dt
		c["pos"] += c["vel"] * dt
	crumbs = crumbs.filter(func(c): return c["t"] < 1.4)
	queue_redraw()

## Ciclo da obra = evento G01 (Sirene de Demolição, modes/eventos.gd): calma → aviso (sirene, luzes, fita zebrada
## no alvo) → o alvo cede. Só trechos que podem cair, nunca o núcleo, nunca embaixo de quem acabou de voltar.
func _alert_pool() -> Array:
	var pool := []
	for p in parts:
		if p["fallen"] or p["nucleo"] or p["crit_t"] > 0.0 or p["warn_t"] > 0.0 or p["evt"] != "" or p["kind"] == "terreo" or int(p["etapa"]) != etapa_now():
			continue
		var fresh := false
		for r in main.robots:
			if r.alive and r.invuln > 0.0 and p["rect"].grow(48).has_point(r.position):
				fresh = true
		if not fresh:
			for k in (3 if p["kind"] == "laje" else 1):
				pool.append(p)
	return pool

func can_alert() -> bool:
	return cycle_state == "calma" and not _alert_pool().is_empty()

func start_alert(warn_s: float) -> void:
	var pool := _alert_pool()
	if pool.is_empty():
		return
	target = pool[main.rng.randi() % pool.size()]
	target["warn_t"] = warn_s
	cycle_state = "aviso"

func _update_cycle(dt: float) -> void:
	if cycle_state == "calma":
		return
	else:
		if target == null or target["fallen"]:
			cycle_state = "calma"
			return
		target["warn_t"] -= dt
		if fmod(t, 0.9) < dt:
			Audio.play("pistao_aviso", 0.8, -6.0)   # sirene da obra
		if target["warn_t"] <= 0.0:
			target["warn_t"] = 0.0
			damage(target, int(cfg["ciclo_dano"]), target["rect"].get_center())
			cycle_state = "calma"

# ---------------------------------------------------------------- desenho
func _shake_off(p: Dictionary) -> Vector2:
	var k: float = p["shake"] / 0.3
	if p["crit_t"] > 0.0:
		k = 1.6
	elif p["warn_t"] > 0.0:
		k = maxf(k, 0.35)
	return Vector2(sin(t * 71.0 + p["idx"]), cos(t * 53.0 + p["idx"] * 2.0)) * 3.0 * k

func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_canteiro", _pf)

func _draw_perf() -> void:
	var ly := LAJE_Y * T
	# escoras (atrás) e pilares do núcleo
	for p in parts:
		if p["kind"] == "laje" and not p["nucleo"] and not p["fallen"] and int(p["escora_hp"]) > 0:
			draw_texture_rect(tex["escora"], Rect2(Vector2(p["rect"].position.x - 10, ly + 2 * T - 16) + _shake_off(p) * 0.5, Vector2(276, 532)), false)
	for col in PILARES:
		if not pillars_down:
			draw_texture_rect(tex["pilar"], Rect2(col * T + 8 - 10, ly + 2 * T - 14, 132, 532), false)
	# andaimes e viga
	for p in parts:
		if p["fallen"] or p["evt"] == "G13":
			continue
		var o := _shake_off(p)
		if p["kind"] == "andaime":
			draw_texture_rect(tex["andaime"], Rect2(p["rect"].position + Vector2(-4, -10) + o, Vector2(340, 788)), false)
		elif p["kind"] == "viga":
			var r: Rect2 = p["rect"]
			for cx in [r.position.x + 40, r.end.x - 40]:
				draw_line(Vector2(cx, -500), Vector2(cx, r.position.y) + o, Color("#5a4a3a"), 4.0, true)
			draw_texture_rect(tex["viga"] if r.size.x > 300.0 else tex["viga4"], Rect2(r.position + Vector2(-10, -10) + o, Vector2(r.size.x + 20.0, 46)), false)
	# Fundação: plataformas sobre estaca (inclinam no aviso), grelha do poço e pedaços da laje
	for p in parts:
		if p["fallen"] or int(p["etapa"]) != 2:
			continue
		var r: Rect2 = p["rect"]
		var o := _shake_off(p)
		match p["kind"]:
			"estaca":
				var floor_y := _piso(int(p["etapa"]))
				draw_texture_rect(tex["estaca"], Rect2(Vector2(r.get_center().x - 22.0, r.end.y) + o * 0.5, Vector2(44, floor_y - r.end.y)), false)
				var tilt := 0.0
				if p["crit_t"] > 0.0:
					tilt = 0.12 * (1.0 - p["crit_t"] / maxf(float(cfg["aviso_queda_s"]), 0.01))
				elif int(p["state"]) == 2:
					tilt = 0.03
				draw_set_transform(r.get_center() + o, tilt, Vector2.ONE)
				draw_texture_rect(tex["plataforma"], Rect2(-r.size.x / 2.0, -11, r.size.x, 34), false)
				draw_set_transform(Vector2.ZERO)
				if int(p["state"]) >= 1:   # rachaduras no pilar
					var cx := r.get_center().x
					draw_polyline(PackedVector2Array([Vector2(cx - 6, r.end.y + 60), Vector2(cx + 4, r.end.y + 90), Vector2(cx - 4, r.end.y + 130)]), Color("#4a3f3a"), 3.0)
			"grelha":
				draw_texture_rect(tex["grelha"], Rect2(r.position + o, r.size), false)
				if int(p["state"]) >= 1:
					draw_line(r.position + Vector2(40, 4) + o, r.position + Vector2(90, 36) + o, Color("#2a1a2e"), 3.0)
			"entulho":
				draw_texture_rect(tex["laje_pedaco_0" if p["idx"] % 2 == 0 else "laje_pedaco_2"], Rect2(r.position + Vector2(-8, -16) + o, r.size + Vector2(16, 20)), false)
	# Fachada: pranchas de andaime (madeira com rodapé; racham e inclinam antes de cair)
	for p in parts:
		if p["kind"] != "prancha" or p["fallen"]:
			continue
		var r: Rect2 = p["rect"]
		var tilt := 0.0
		if p["crit_t"] > 0.0:
			tilt = 0.1 * (1.0 - p["crit_t"] / maxf(float(cfg["aviso_queda_s"]), 0.01))
		draw_set_transform(r.get_center() + _shake_off(p), tilt, Vector2.ONE)
		var lr := Rect2(-r.size.x / 2.0, -r.size.y / 2.0, r.size.x, r.size.y)
		draw_rect(lr, Color("#c98a4b"))
		draw_rect(Rect2(lr.position.x, lr.end.y - 6.0, lr.size.x, 10.0), Color("#8a5a2b"))
		for k in range(1, int(lr.size.x / 92.0) + 1):
			draw_line(Vector2(lr.position.x + k * 92.0, lr.position.y + 3), Vector2(lr.position.x + k * 92.0, lr.end.y - 4), Color("#a46a35"), 3.0)
		if int(p["state"]) >= 1:
			draw_polyline(PackedVector2Array([Vector2(-20, lr.position.y + 2), Vector2(-4, 2), Vector2(-14, 8), Vector2(10, lr.end.y)]), Color("#2a1a2e"), 3.0)
		draw_set_transform(Vector2.ZERO)
	# chão do térreo (lados): terra batida com faixa clara no topo
	for p in parts:
		if p["kind"] == "terreo" and not p["fallen"]:
			var r: Rect2 = p["rect"]
			draw_rect(r, Color("#b9ab8f"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), Color("#d9ccb0"))
			for k in int(r.size.x / 70.0):
				draw_circle(r.position + Vector2(30 + k * 70, 40 + (k % 3) * 18), 4.0, Color("#958a72"))
	# laje
	for p in parts:
		if p["kind"] != "laje" or p["fallen"]:
			continue
		var sag := Vector2(0, 3.0 * (1.0 - p["crit_t"] / maxf(float(cfg["aviso_queda_s"]), 0.01))) if p["crit_t"] > 0.0 else Vector2.ZERO
		draw_texture_rect(tex["laje_%d" % int(p["state"])], Rect2(p["rect"].position + Vector2(-12, -12) + _shake_off(p) + sag, Vector2(280, 160)), false)
	# aviso do ciclo: fita zebrada correndo no topo do alvo + contorno piscando + luzes
	for p in parts:
		if p["warn_t"] > 0.0 and not p["fallen"]:
			_draw_warning(p)
	if cycle_state == "aviso":
		_draw_sirens()
	# pedaços e pedrinhas
	for d in debris:
		var a := clampf(2.5 - d["t"], 0.0, 1.0)
		draw_set_transform(d["pos"], d["rot"])
		if d["tex"] == null:   # lascas desenhadas (prancha de madeira)
			var cc: Color = d.get("cor", Color("#c98a4b"))
			draw_rect(Rect2(-d["size"] / 2.0, d["size"]), Color(cc, a))
			draw_rect(Rect2(Vector2(-d["size"].x / 2.0, d["size"].y / 2.0 - 6.0), Vector2(d["size"].x, 6.0)), Color(cc.darkened(0.35), a))
		else:
			draw_texture_rect(d["tex"], Rect2(-d["size"] / 2.0, d["size"]), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	for c in crumbs:
		draw_circle(c["pos"], 3.5, Color("#a1988a"))

func _draw_warning(p: Dictionary) -> void:
	var r: Rect2 = p["rect"]
	var o := _shake_off(p)
	var blink := 0.5 + 0.5 * sin(t * 12.0)
	draw_rect(Rect2(r.position + o - Vector2(4, 4), r.size + Vector2(8, 8)), Color(0.95, 0.78, 0.29, 0.35 + 0.4 * blink), false, 5.0)
	var tape := Rect2(r.position.x + 4, r.position.y - 12, r.size.x - 8, 10)
	draw_rect(tape, Color("#f2c84b"))
	var s := fmod(t * 60.0, 22.0)
	var x := tape.position.x - 22.0 + s
	while x < tape.end.x:
		var x0 := maxf(x, tape.position.x)
		var x1 := minf(x + 10.0, tape.end.x)
		if x1 > x0:
			draw_rect(Rect2(x0, tape.position.y, x1 - x0, tape.size.y), Color("#2a1a2e"))
		x += 22.0
	if p["warn_t"] < 1.5 and randf() < 0.3:
		_crumb(p)

func _draw_sirens() -> void:
	var on := fmod(t, 0.5) < 0.25
	var spots := [Vector2(PILARES[0] * T + 64, LAJE_Y * T + 2 * T + 20), Vector2(PILARES[1] * T + 64, LAJE_Y * T + 2 * T + 20)]
	for p in parts:
		if p["kind"] == "andaime" and not p["fallen"]:
			spots.append(p["rect"].position + Vector2(12, -6))
			spots.append(Vector2(p["rect"].end.x - 12, p["rect"].position.y - 6))
	for sp in spots:
		draw_circle(sp, 9.0, Color("#f08a3d") if on else Color("#8a4a2a"))
		if on:
			draw_circle(sp, 26.0, Color(1.0, 0.6, 0.2, 0.25))
			var ang := t * 8.0
			draw_colored_polygon(PackedVector2Array([sp, sp + Vector2.from_angle(ang - 0.25) * 120.0, sp + Vector2.from_angle(ang + 0.25) * 120.0]), Color(1.0, 0.75, 0.3, 0.18))

## VIRADA da fase (modes/etapas.gd): TUDO desaba de uma vez (inclusive núcleo e térreo), em pedaços com física.
func collapse_all(n := 1) -> void:
	quiet = true
	for p in parts:
		if int(p["etapa"]) != n:
			continue
		p["warn_t"] = 0.0
		p["evt"] = ""
		if not p["fallen"]:
			_collapse(p)
	quiet = false
	# D12: pedaços da cena que caiu viram obstáculos quebráveis no piso da cena seguinte (entulhos da cena n+1)
	for c in extras:
		if int(c["ordem"]) != n + 1:
			continue
		var piso := float(c.get("piso", 41)) * T
		for i in c.get("entulhos", []).size():
			var e: Array = c["entulhos"][i]
			_add("entulho", Rect2(e[0] * T, piso - 44.0, e[1] * T, 44.0), int(cfg["entulho_hp"]), false, false, i, n + 1)
	pillars_down = n == ETAPA_LAJE
	for col in PILARES:   # os pilares tombam em pedaços
		var x: float = col * T + 64.0
		for k in 4:
			debris.append({"tex": tex["pilar"], "size": Vector2(132, 133), "pos": Vector2(x, LAJE_Y * T + 2 * T + 70 + k * 133),
				"vel": Vector2(randf_range(-160, 160), randf_range(-200, 40)), "rot": 0.0, "spin": randf_range(-2.5, 2.5), "t": 0.0})
	cycle_state = "calma"
	target = null

## Aviso da virada: todas as peças tremem com a fita zebrada.
func warn_all(s: float, n := 1) -> void:
	for p in parts:
		if not p["fallen"] and p["kind"] != "terreo" and int(p["etapa"]) == n:
			p["warn_t"] = s

## Linha do piso (px) da cena n (estacas descem até ele).
func _piso(n: int) -> float:
	for c in extras:
		if int(c["ordem"]) == n:
			return float(c.get("piso", 41)) * T
	return 41.0 * T

## DESTRUIÇÃO ELEGÍVEL da cena n (0..1) — gatilho da transição (modos[derruba].destruicao.limiar). Conta só peças
## destrutíveis da cena: fora a base fixa (núcleo, térreo), os pedaços gerados na queda (entulho) e as outras cenas.
## Calculado do ESTADO das peças (não somando golpes): nenhuma origem de dano fica de fora e nada conta duas vezes.
## Peso = largura em tiles (laje x2, tem 2 tiles de altura); fração = HP perdido (laje inclui as escoras); caída = 1.
func progresso(n: int) -> float:
	var tot := 0.0
	var feito := 0.0
	for p in parts:
		if int(p["etapa"]) != n or p["nucleo"] or p["kind"] in ["terreo", "entulho"] or p.get("gerada", false):
			continue
		var w: float = maxf(1.0, round(p["rect"].size.x / T)) * (2.0 if p["kind"] == "laje" else 1.0)
		var f := 1.0
		if not p["fallen"]:
			var mx := float(p["max"]) + (float(cfg["escora_hp"]) if p["kind"] == "laje" else 0.0)
			f = clampf(1.0 - (float(p["hp"]) + float(p.get("escora_hp", 0))) / maxf(mx, 1.0), 0.0, 1.0)
		tot += w
		feito += w * f
	return feito / tot if tot > 0.0 else 1.0

## Quantos trechos/peças ainda de pé (testes e bots).
func standing(kind := "") -> int:
	var n := 0
	for p in parts:
		if not p["fallen"] and (kind == "" or p["kind"] == kind):
			n += 1
	return n
