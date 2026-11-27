extends Node2D
## SPELLS (Relatório 04): 1 slot por robô, caixa com a FAMÍLIA visível (a spell só aparece ao pegar), troca voluntária
## (segurar o botão de especial ~0,3 s sobre a caixa: o item antigo cai no chão para outro pegar), limpeza na eliminação,
## sorteio em 2 etapas (família → spell) com raridade e sem ajuda a quem perde. Números: data/modos.json → demolicao.spells.
## PADRÃO (lições aprovadas pelo usuário): ver docs/ESTADO.md → "PADRÃO DAS SPELLS".
## Etapa 1: A01 Punho Pneumático, A03 Canhão Criogênico, C01 Superímã, E01 Andaime Relâmpago, C04 Teleporte, T01 Armadura Fornalha.

const T := 64.0
const Kit := preload("res://ui/kit.gd")
const RobotVis := preload("res://player/robot_visual.gd")
const FAM_COR := {"ataque": Color("#f08a3d"), "controle": Color("#8a63d2"), "engenharia": Color("#f2c84b"), "transformacao": Color("#3fc1c9"), "defesa": Color("#4fae5b")}
const NOMES := {"A01": "PUNHO PNEUMÁTICO", "A03": "CANHÃO CRIOGÊNICO", "C01": "SUPERÍMÃ", "E01": "ANDAIME RELÂMPAGO",
	"C04": "TELEPORTE", "T01": "MECHA FORNALHA", "A02": "LASER DE CORTE", "A04": "MARRETA SÍSMICA", "A05": "REBITEIRA RICOCHETE",
	"A06": "BATE-ESTACA", "A07": "MARRETA-BUMERANGUE", "A08": "CANHÃO DE MOLAS",
	"C02": "TURBOVENTILADOR", "C03": "GANCHO DE ARRASTO", "C05": "LAÇO DE ENERGIA", "E02": "CARGA REMOTA",
	"E03": "CONTROLE REMOTO",
	"T02": "MECHA EMPILHADEIRA", "T03": "MECHA BOLA", "T04": "MECHA JATO", "T05": "MECHA BROCA",
	"T06": "PARA-RAIOS", "T07": "MECHA CORREDOR", "D01": "ÂNCORA DE CONTRAPESO", "D02": "AIRBAG DE OBRA", "D03": "PARA-CHOQUE DE MOLA", "D04": "CORTINA DE POEIRA", "D05": "CAPACETE DE AÇO", "D06": "BONECO DE TESTE"}
const FORMS := ["T02", "T03", "T05", "T06", "T07"]   # transformações com duração (T01 tem código próprio)

var main: Node
var demo: Node
var cfg: Dictionary
var boxes: Array = []        # {fam, id, charges, pos, vy, t, land_t, block: {pid: s}, special}
var slot := {}               # pid -> {id, fam, charges, cd, prep, prep_len, fire, t, data}
var helmets := {}            # D05: pid -> {t, cd, tranco}
var helmet_fly := []         # D05: capacete voando no fim {pos, vel, rot, t}
var decoys := []             # D06: {owner, pos, t, len, wob, morre}
var bumpers := {}            # D03: pid -> {t, len, tranco, cd: {pid: s}}
var dusts := {}              # D04: pid -> {t, len, rasga}
var sinks := []              # D01: contrapeso afundando no fim {pos, t}
var pops := []               # D02: balão murchando {pos, t}
var anchors := {}            # D01: pid -> {t, len, pos (onde o contrapeso cravou), fim}
var airbags := {}            # D02: pid -> {t} balão inflado
var rivet_hits := {}         # A05: pid -> {n, t} acertos seguidos (3 = pregado)
var pinned := {}             # A05: pid -> {t, len, pos} robô pregado
var puffs := []              # A04: poeira na cor do concreto {pos, vel, r, t, life}
var craters := []            # A04: clarão da cratera {rect, t}
var punch_fly := []          # A01: rivais voando do soco carregado {pid, owner, t, dir} (quicam na parede)
var bonks := []              # A01: estrela de pancada na parede {pos, t}
var holds := {}              # pid -> {box, t}
var shots: Array = []        # A03 {pos, vel, owner, t}
var frozen := {}             # A03: pid -> {len, age, shake, last_ax}
var shards: Array = []       # A03: lascas de gelo voando {pos, vel, rot, spin, t, size}
var platforms: Array = []    # E01 {rect, body, t, len, owner, k, from, leg}
var fists: Array = []        # A01 {owner, t, reach, dir, hit, wall}
var aims := {}               # C04: pid -> {pos, t, ok}
var teles: Array = []        # C04 {pid, a, b, t, moved}
var flames := {}             # T01: pid -> {k, hitcd: {oid: s}}
var bot_hold := {}           # bots "seguram" o botão por um tempo
var lasers: Array = []       # A02 {owner, t, a, b}
var scorch: Array = []       # A02 marcas de solda {pos, t}
var waves: Array = []        # A04 {owner, x0, y, l_end, r_end, t, hit}
var rivets: Array = []       # A05 {owner, pos, vel, bounces, t, hit, trail}
var piles: Array = []        # A06 {owner, x, floor_y, t, hit, done}
var hammers: Array = []      # A07 {owner, pos, vel, phase, t, hit, rot}
var springs: Array = []      # A08 {owner, pos, vel, t, sq}
var rocks: Array = []        # A04 pedrinhas voando {pos, vel, t, rot, size}
var tings: Array = []        # A05 brilho de ricochete / boca da rebiteira {pos, t, big}
var pile_aims := {}          # A06: pid -> {x, t} (segura para mirar onde a estaca cai)
var hooks: Array = []        # C03 {owner, pos, vel, phase, t, anchor, dir}
var lassos: Array = []       # C05 tiro {owner, pos, vel, t}
var tethers: Array = []      # C05 {a, b, t}
var snaps: Array = []        # C05 elástico estalando ao soltar {a, b, t}
var charges_placed: Array = []   # E02 {owner, pos, t, armed}
var drops: Array = []        # E03 {part, owner, t, hit}
var smokes: Array = []      # T04 fumaça cômica {pos, vel, t, size}
var jets: Array = []         # T04 jato de um pulso {pid, dir, t, fail}
var ext_v := {}              # empurrão externo suave por robô (vento, elástico): pid -> Vector2, aplicado via push_vx
var feedback: Array = []     # {pos, text, t}
var spawn_t := 0.0
var recent: Array = []
var draw_log: Array = []     # sorteios (testes): {fam, id}
var t := 0.0
var ghost: Node2D = null
var trail_node: Node2D = null   # T07: vultos de velocidade     # C04: silhueta holográfica no destino (desenhada com transparência)

func setup(m: Node, d: Node) -> void:
	main = m
	demo = d
	ghost = Node2D.new()
	ghost.draw.connect(_draw_ghost)
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.72, 0.6, 1.0, 0.6);
void fragment() {
	float scan = 0.55 + 0.45 * step(0.5, fract(FRAGCOORD.y / 5.0));
	COLOR = vec4(tint.rgb, COLOR.a * tint.a * scan);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	ghost.material = mat
	add_child(ghost)
	trail_node = Node2D.new()
	trail_node.draw.connect(_draw_trail_node)
	var mat2 := ShaderMaterial.new()
	mat2.shader = sh
	mat2.set_shader_parameter("tint", Color(1, 1, 1, 0.32))
	trail_node.material = mat2
	add_child(trail_node)
	move_child(trail_node, 0)
	cfg = d.cfg["spells"]
	var c: Dictionary = cfg["caixa"]
	spawn_t = main.rng.randf_range(float(c["primeira_s"][0]), float(c["primeira_s"][1]))

func sc(id: String) -> Dictionary:
	return cfg[id]

## Spells que podem sair nas caixas: as AUTORIZADAS pelo mapa (manifesto). Mapa-ferramenta (laboratório/testes): o pool
## do modo, explícito. Outro mapa/modo sem manifesto: nenhuma (sem herdar as do Derruba).
func pool() -> Array:
	var p: Array = MapaReg.spells(main.game_mode, main.level.id, cfg["pools"].get(main.game_mode, []))
	if main.spells_mapa == String(main.level.id) and not main.spells_on.is_empty():   # Derruba v2: só as acesas (D3)
		p = p.filter(func(id): return main.spells_on.get(id, false))
	return p

## Classes de spell (com peso do sorteio) definidas pelo MODO.
func classes() -> Dictionary:
	return MapaReg.modo_cfg(main.game_mode).get("classes_spells", {})

# ---------------------------------------------------------------- sorteio e caixas
## Sorteio em 2 etapas: família (peso) → spell da família (raridade, menos chance de repetir as últimas). Neutro para todos.
func pick(classe := "") -> Dictionary:
	if pool().is_empty():
		return {}
	var fams := {}
	for id in pool():
		if classe == "" or sc(id)["familia"] == classe:
			fams[sc(id)["familia"]] = true
	if fams.is_empty():
		return {}
	var tot := 0.0
	for f in fams:
		tot += float(classes()[f]["peso"])
	var r: float = main.rng.randf() * tot
	var fam: String = fams.keys()[0]
	for f in fams:
		r -= float(classes()[f]["peso"])
		if r <= 0.0:
			fam = f
			break
	var cand := []
	var wsum := 0.0
	for id in pool():
		if sc(id)["familia"] != fam:
			continue
		var w := float(cfg["raridade"][sc(id)["raridade"]]) * (0.35 if id in recent else 1.0)
		cand.append([id, w])
		wsum += w
	var x: float = main.rng.randf() * wsum
	var pick_id: String = cand[0][0]
	for cw in cand:
		x -= cw[1]
		if x <= 0.0:
			pick_id = cw[0]
			break
	recent.append(pick_id)
	if recent.size() > 3:
		recent.pop_front()
	draw_log.append({"fam": fam, "id": pick_id})
	return {"fam": fam, "id": pick_id}

## Pontos de caixa: parte FIXA (centro do núcleo, andaimes) e parte VARIÁVEL (qualquer trecho firme), só onde não vai cair.
func spawn_points() -> Array:
	var out := []
	var ct = demo.canteiro
	if ct != null and is_instance_valid(ct):
		for p in ct.parts:
			if p["fallen"] or p["warn_t"] > 0.0 or p["crit_t"] > 0.0 or p["state"] == 2 or int(p.get("etapa", 1)) != ct.etapa_now():
				continue
			var r: Rect2 = p["rect"]
			var fixed: bool = p["nucleo"] or p["kind"] == "andaime"
			out.append({"pos": Vector2(r.get_center().x, r.position.y), "fixo": fixed})
			out.append({"pos": Vector2(main.rng.randf_range(r.position.x + 40, r.end.x - 40), r.position.y), "fixo": false})
		return out
	var lv = main.level
	var pr: Rect2 = demo.play_rect().grow(-96)
	for y in range(3, lv.rows - 1):
		for x in range(1, lv.cols - 1):
			var c := Vector2i(x, y)
			if lv.is_solid(c) and not lv.is_solid(c + Vector2i.UP) and not lv.is_solid(c + Vector2i(0, -2)) and not (lv.ch_at(c) in ["^", "I"]):
				var p := Vector2(x * T + 32, y * T)
				if pr.has_point(p):
					out.append({"pos": p, "fixo": false})
	return out

func spawn_box(at = null, special := false, classe := "") -> void:
	var pts := spawn_points()
	if pts.is_empty() and at == null:
		return
	var p: Vector2
	if at != null:
		p = at
	else:
		var fixed := pts.filter(func(q): return q["fixo"])
		var src: Array = fixed if (not fixed.is_empty() and main.rng.randf() < 0.5) else pts
		p = src[main.rng.randi() % src.size()]["pos"]
	var k := pick(classe)
	if k.is_empty():
		return   # mapa sem spells autorizadas (ou sem nenhuma da classe pedida)
	boxes.append({"fam": k["fam"], "id": k["id"], "charges": -1, "pos": Vector2(p.x, sky_y(p)),
		"vy": 0.0, "t": 0.0, "land_t": 9.0, "block": {}, "special": special})
	Audio.play("item", 0.8, -6.0)

## De onde a caixa começa a cair sobre p: do alto da área de jogo, ou logo abaixo de um teto (a Fundação tem teto:
## antes a caixa pousava em cima dele e ficava "lá em cima").
func sky_y(p: Vector2) -> float:
	var top: float = demo.play_rect().position.y - 60.0
	var y := p.y - 70.0
	while y > top:
		if main.level.is_solid(Vector2i(int(floor(p.x / T)), int(floor(y / T)))):
			return y + 70.0
		y -= T
	return top

## Laboratório: caixa de uma spell escolhida caindo do céu em x.
func drop_box(id: String, at: Vector2, from_sky := true) -> void:
	boxes.append({"fam": sc(id)["familia"], "id": id, "charges": -1, "pos": Vector2(at.x, sky_y(at)) if from_sky else at,
		"vy": 0.0, "t": 0.0, "land_t": 9.0, "block": {}, "special": false})

func _update_boxes(dt: float, alive: Array) -> void:
	var c: Dictionary = cfg["caixa"]
	spawn_t -= dt
	if spawn_t <= 0.0:
		spawn_t = main.rng.randf_range(float(c["intervalo_s"][0]), float(c["intervalo_s"][1]))
		if demo.items_on and boxes.size() < int(c["max_mapa"]):
			spawn_box()
	var lv = main.level
	for b in boxes:
		b["t"] += dt
		b["land_t"] += dt
		for pid in b["block"].keys():
			b["block"][pid] -= dt
			if b["block"][pid] <= 0.0:
				b["block"].erase(pid)
		var cell := Vector2i(int(b["pos"].x / T), int(floor((b["pos"].y + 30.0) / T)))
		var ev_top: float = main.events.top_at(b["pos"].x, b["pos"].y + 30.0) if main.events != null and b["vy"] >= 0.0 else -1.0
		if ev_top >= 0.0:   # em cima da carga do guindaste / do entulho (eventos)
			if b["vy"] > 60.0:
				b["land_t"] = 0.0
				Audio.play("caixote_pancada", 1.3, -10.0)
			b["pos"].y = ev_top - 30.0
			b["vy"] = 0.0
		elif lv.is_solid(cell) and b["pos"].y + 30.0 >= cell.y * T and b["vy"] >= 0.0:
			if b["vy"] > 60.0:
				b["land_t"] = 0.0
				main.dust(Vector2(b["pos"].x, cell.y * T), 0.6)
				Audio.play("caixote_pancada", 1.3, -10.0)
			b["pos"].y = cell.y * T - 30.0
			b["vy"] = 0.0
		else:
			var vmax := 220.0 if b["special"] else 900.0   # cápsula especial desce de paraquedas
			b["vy"] = minf(b["vy"] + 1800.0 * dt, vmax)
			b["pos"].y += b["vy"] * dt
	var life := float(c["vida_s"])
	boxes = boxes.filter(func(b): return b["t"] < life and b["pos"].y < lv.rows * T + 200.0)
	# coleta por contato (slot vazio); o mais perto da caixa leva, só um por caixa
	for b in boxes.duplicate():
		var br := Rect2(b["pos"] - Vector2(34, 34), Vector2(68, 64))
		var best = null
		var bd := 1e9
		for r in alive:
			if slot.has(r.pid) or b["block"].has(r.pid) or not br.intersects(r.rect()):
				continue
			var d: float = r.rect().get_center().distance_to(b["pos"])
			if d < bd:
				bd = d
				best = r
		if best != null:
			boxes.erase(b)
			equip(best, b["id"], b["charges"], float(b.get("energy", -1.0)))

# ---------------------------------------------------------------- slot
func equip(r, id: String, charges := -1, energy := -1.0) -> void:
	var s: Dictionary = sc(id)
	slot[r.pid] = {"id": id, "fam": s["familia"], "charges": int(s["cargas"]) if charges < 0 else charges, "cd": 0.0,
		"prep": -1.0, "prep_len": 0.0, "fire": -1.0, "t": -1.0, "channel": false,
		"energy": energy if energy >= 0.0 else float(s.get("energia_s", s.get("combustivel_s", 0.0))), "data": {}}
	main.float_text(r.position + Vector2(0, -130), NOMES.get(id, id) + "!", FAM_COR[s["familia"]])
	Audio.play("item", 1.2)
	r.vis.s_sqy[0] = 1.18   # pulinho de alegria
	r.vis.s_sqx[0] = 0.86

## Remove as colunas do A06 que estão de pé (testes/vitrines).
func clear_columns() -> void:
	for p in piles:
		var b = p.get("body")
		if b != null and is_instance_valid(b):
			b.queue_free()
	piles.clear()

## Elimina/limpa: fim de transformação, sem guardar nada para o respawn.
func clear(r) -> void:
	for h in hammers.duplicate():   # a marreta-bumerangue volta na hora
		if h["owner"] == r.pid:
			hammers.erase(h)
			r.hammer_out = false
	hooks = hooks.filter(func(h): return h["owner"] != r.pid)
	charges_placed = charges_placed.filter(func(c): return c["owner"] != r.pid)
	if slot.has(r.pid) and slot[r.pid]["id"] == "T01" and slot[r.pid]["t"] > 0.0:
		_end_armor(r, false)
	if slot.has(r.pid) and slot[r.pid]["id"] in FORMS and slot[r.pid]["t"] > 0.0:
		_end_form(r, false)
	_stop_channel(r)
	if anchors.has(r.pid):
		_end_anchor(r)
	if bumpers.has(r.pid):
		bumpers.erase(r.pid)
		r.mola_t = 0.0
	if helmets.has(r.pid):
		helmets.erase(r.pid)
		r.capacete_n = 0
	if dusts.has(r.pid):
		dusts.erase(r.pid)
		r.poeira_t = 0.0
	airbags.erase(r.pid)
	slot.erase(r.pid)
	holds.erase(r.pid)
	aims.erase(r.pid)
	pile_aims.erase(r.pid)
	flames.erase(r.pid)
	r.spell_lock = false
	r.spell_fly = false
	if is_instance_valid(r.vis):
		r.vis.visible = true

func has_spell(r) -> bool:
	return slot.has(r.pid)

func _is_bot(pid: int) -> bool:
	return pid < main.players.size() and main.players[pid].get("bot", false)

## Botão de especial está seguro? (bots seguram por um tempo fixo)
func held(r) -> bool:
	return PlayerInput.held(r.pid, "item") or float(bot_hold.get(r.pid, 0.0)) > 0.0

## Botão de especial apertado (borda). Em cima de uma caixa com o slot ocupado: começa a TROCA (segurar);
## soltar antes do tempo usa a spell atual (toque rápido continua valendo).
func press(r) -> void:
	if not slot.has(r.pid):
		return
	var b = _box_under(r)
	if b != null:
		holds[r.pid] = {"box": b, "t": 0.0}
		return
	use(r)

func _box_under(r):
	for b in boxes:
		if not b["block"].has(r.pid) and Rect2(b["pos"] - Vector2(34, 34), Vector2(68, 64)).intersects(r.rect()):
			return b
	return null

func _update_holds(dt: float) -> void:
	for pid in holds.keys():
		var h: Dictionary = holds[pid]
		var r = main.robots[pid] if pid < main.robots.size() else null
		if r == null or not r.alive or not (h["box"] in boxes) or not Rect2(h["box"]["pos"] - Vector2(34, 34), Vector2(68, 64)).intersects(r.rect()):
			holds.erase(pid)
			continue
		if PlayerInput.held(pid, "item"):
			h["t"] += dt
			if h["t"] >= float(cfg["caixa"]["troca_s"]):
				_swap(r, h["box"])
				holds.erase(pid)
		else:
			holds.erase(pid)
			use(r)   # foi um toque: usa a spell

func _swap(r, b: Dictionary) -> void:
	var old: Dictionary = slot[r.pid]
	if old["id"] == "T01" and old["t"] > 0.0:
		_end_armor(r, false)   # troca encerra a transformação
	if old["id"] in FORMS and old["t"] > 0.0:
		_end_form(r, false)
	_stop_channel(r)
	aims.erase(r.pid)
	r.spell_lock = false
	# o antigo cai no chão (com as cargas/energia que sobraram) e o dono não pega de volta na hora
	var drop := {"fam": old["fam"], "id": old["id"], "charges": old["charges"], "energy": old["energy"],
		"pos": r.position + Vector2(-r.facing * 50.0, -40.0), "vy": -260.0, "t": 0.0, "land_t": 9.0,
		"block": {r.pid: float(cfg["caixa"]["anti_recaptura_s"])}, "special": false}
	boxes.erase(b)
	boxes.append(drop)
	slot.erase(r.pid)
	equip(r, b["id"], b["charges"], float(b.get("energy", -1.0)))
	Audio.play("alavanca", 1.2)

func _spend(r, s: Dictionary) -> void:
	s["charges"] -= 1
	if s["charges"] <= 0:
		s["empty_t"] = 0.6 if s["id"] == "A04" else 0.35   # some do slot depois da animação de recolher (a marreta fica cravada)

var _uso := [-1, -1]   # [pid, quadro] do último use(): _fail no mesmo quadro desconta a engenhoca
func _fail(r, text: String) -> void:
	if _uso[0] == r.pid and _uso[1] == Engine.get_physics_frames():
		main.add_stat(r.pid, "engenhocas", -1)
		_uso = [-1, -1]
	feedback.append({"pos": r.position + Vector2(0, -120), "text": text, "t": 0.0})
	Audio.play("menu_negado", 1.0, -6.0)

## Mão da frente no mundo (de onde saem punho, tiro e ímã).
## Bico da arma no mundo (mesma conta do desenho em robot_visual: mão mirando + bico − pega, na escala da arma).
func muzzle(r, id: String) -> Vector2:
	if r.vis != null and r.vis.has_meta("bico"):   # o bico como foi desenhado no último quadro (sincroniza com a arte)
		var bm: Array = r.vis.get_meta("bico")
		if bm[0] == id and Engine.get_process_frames() - int(bm[2]) <= 2:
			return get_global_transform().affine_inverse() * bm[1]   # global (com câmera) → coordenadas do mundo deste nó
	var spec: Array = RobotVis.SPELL_TOOLS[id]
	var tx := Data.tex("spells/" + spec[0])
	var dsz := Vector2(tx.get_width(), tx.get_height()) / 2.0
	var a := aim_local(r)
	var loc: Vector2 = RobotVis.shoulder_of(r.vis.model, bool(flags(r).get("armor", false))) + Vector2.from_angle(a) * RobotVis.ARM + ((spec[3] - spec[2]) * spec[1] / dsz).rotated(a)
	return r.position + Vector2(r.facing * loc.x, loc.y)

# ---------------------------------------------------------------- mira em 8 direções (padrão de todas as armas)
## Direção da mira agora: ▲/▼ (▼ só no ar) somam com ◄►; sem nada, para a frente. Bots miram no rival mais perto.
func aim_vec(r) -> Vector2:
	if _is_bot(r.pid):
		return _bot_aim(r)
	var up := PlayerInput.held(r.pid, "up")
	var dn: bool = PlayerInput.held(r.pid, "down") and not r.is_on_floor()
	var ax := PlayerInput.axis_x(r.pid)
	var sx := 0 if absf(ax) < 0.4 else int(signf(ax))
	var vy := -1 if up else (1 if dn else 0)
	if vy == 0:
		return Vector2(sx if sx != 0 else r.facing, 0)
	if sx == 0:
		return Vector2(0, vy)
	return Vector2(sx, vy).normalized()

func _bot_aim(r) -> Vector2:
	var best = null
	var bd := 1e9
	for o in main.robots:
		if o != r and o.alive:
			var d: float = o.position.distance_to(r.position)
			if d < bd:
				bd = d
				best = o
	if best == null:
		return Vector2(r.facing, 0)
	var v: Vector2 = best.rect().get_center() - r.rect().get_center()
	var ang := snappedf(v.angle(), PI / 4.0)
	var out := Vector2.from_angle(ang).round()
	if out.y > 0.0 and r.is_on_floor():
		out = Vector2(signf(v.x) if v.x != 0.0 else r.facing, 0)
	return out.normalized() if out != Vector2.ZERO else Vector2(r.facing, 0)

## Mira guardada na spell (atualiza no preparo; gira aos poucos nas de segurar). Vira o robô para o lado da mira.
func _set_aim(r, s: Dictionary, v: Vector2, turn := -1.0, dt := 0.0) -> void:
	var cur: Vector2 = s.get("aim", Vector2(r.facing, 0))
	if turn > 0.0:
		var a := cur.angle()
		v = Vector2.from_angle(rotate_toward(a, v.angle(), turn * dt))
	s["aim"] = v
	if absf(v.x) > 0.1:
		r.facing = int(signf(v.x))

## Ângulo da mira no espaço do robô (0 = frente, −π/2 = cima, π/2 = baixo).
func aim_local(r) -> float:
	if not slot.has(r.pid):
		return 0.0
	var v: Vector2 = slot[r.pid].get("aim", Vector2(r.facing, 0))
	return atan2(v.y, v.x * r.facing) if absf(v.x) > 0.01 else atan2(v.y, 0.0)

func aim_dir(r) -> Vector2:
	var a := aim_local(r)
	return Vector2(r.facing * cos(a), sin(a))

## Sólido de verdade (para tiros e feixes): paredes, chão, blocos e a laje do Canteiro. Plataformas vazadas
## (andaimes, vigas, tábuas, ponte, andaime relâmpago) NÃO param tiros.
const HARD_CH := ["#", "o", "I", "d", "T", "<", ">", "F", "f", "P", "B", "a", "D", "J"]
func _hard_at(p: Vector2) -> bool:
	var lv = main.level
	var c := Vector2i(int(floor(p.x / T)), int(floor(p.y / T)))
	if (c.x < 0 or c.y < 0 or c.x >= lv.cols or c.y >= lv.rows):
		return not lv.props.has("ko")
	if lv.ch_at(c) in HARD_CH:
		return true
	if main.events != null and main.events.hard_at(p):
		return true   # entulho e tapumes (eventos) são cobertura
	var ct = demo.canteiro
	if ct != null and is_instance_valid(ct):
		for pt in ct.parts:
			if pt["kind"] == "laje" and not pt["fallen"] and pt["rect"].has_point(p):
				return true
	return false

## Onde a garra do gancho/carga grudam: sólido de verdade OU qualquer plataforma (é assim que se sobe).
func _grab_at(p: Vector2) -> bool:
	if _hard_at(p) or _solid_at(p) or main.level.ch_at(Vector2i(int(floor(p.x / T)), int(floor(p.y / T)))) == "=":
		return true
	if main.events != null and main.events.grab_at(p):
		return true
	for pl in platforms:
		if pl["rect"].grow(4).has_point(p):
			return true
	var c17: Dictionary = sc("A06")   # coluna de concreto do Bate-Estaca (de pé)
	for pl in piles:
		if pl.get("done", false) and not pl.get("gone", false) and pl.get("shp") != null:
			var hh: float = pl["shp"].size.y
			var hw: float = float(c17["largura_tiles"]) * T / 2.0
			if Rect2(pl["x"] - hw, pl["floor_y"] - hh, hw * 2.0, hh).grow(4).has_point(p):
				return true
	return false

## Segmento a→b encosta no retângulo (com folga rad)?
func _seg_rect(a: Vector2, b: Vector2, rr: Rect2, rad: float) -> bool:
	var g := rr.grow(rad)
	var n := maxi(int(a.distance_to(b) / 10.0), 1)
	for i in n + 1:
		if g.has_point(a.lerp(b, float(i) / n)):
			return true
	return false

func hand(r) -> Vector2:
	return r.position + Vector2(r.facing * 32.0, -40.0)

# ---------------------------------------------------------------- usar
func use(r) -> void:
	var s: Dictionary = slot[r.pid]
	if s["cd"] > 0.0 or s["prep"] >= 0.0 or s.has("empty_t") or s["channel"] or s.has("beam") or int(s.get("burst", 0)) > 0:
		return
	if r.poeira_t > 0.0:   # D04: dentro da poeira não usa engenhoca
		return
	var c: Dictionary = sc(s["id"])
	_set_aim(r, s, aim_vec(r))
	main.add_stat(r.pid, "engenhocas")   # estatística dos resultados (desfeita em _fail se não deu para usar)
	_uso = [r.pid, Engine.get_physics_frames()]
	match s["id"]:
		"A01":   # auditoria 2026-11-27: SEGURAR carrega a pressão (até carga_max_s); soltar = soco (força pela carga)
			s["prep"] = 0.0
			s["prep_len"] = float(c["carga_max_s"])
			s["carga_hold"] = true
			if _is_bot(r.pid):
				bot_hold[r.pid] = randf_range(0.25, float(c["carga_max_s"]))
			Audio.play("pistao_aviso", 1.1, -4.0)
		"A03", "A02", "A08":
			s["prep"] = 0.0
			s["prep_len"] = float(c["preparo"])
			if s["id"] == "A02" and _is_bot(r.pid):
				bot_hold[r.pid] = float(c["preparo"]) + 0.9
			Audio.play({"A01": "pistao_aviso", "A03": "gelo", "A02": "laser_carga", "A08": "pulo_mola"}[s["id"]], 1.3 if s["id"] != "A08" else 0.6, -4.0)
		"A04":   # só apoiado no chão (no ar avisa e não gasta)
			if not r.is_on_floor():
				_fail(r, "SÓ NO CHÃO")
				return
			s["prep"] = 0.0
			s["prep_len"] = float(c["preparo"])
			Audio.play("marreta_vento", 0.7, -2.0)
		"A05":   # auditoria 2026-11-27: RAJADA de 3 rebites em brasa (1 carga por rajada)
			s["burst"] = int(c["rajada"])
			s["burst_t"] = 0.0
			_spend(r, s)
			_fire_rivet(r, s)
		"A06":
			if _is_bot(r.pid):
				_drop_pile(r, s, r.position.x + r.facing * float(c["distancia_tiles"]) * T)
			else:   # segura: marca no chão anda com o direcional; solta: a estaca desce lá
				s["channel"] = true
				pile_aims[r.pid] = {"x": r.position.x + r.facing * float(c["distancia_tiles"]) * T, "t": 0.0}
				r.spell_lock = true
				Audio.play("alarme", 1.8, -12.0)
		"A07":
			if r.hammer_out:
				return
			_throw_hammer(r, s)
		"D01":   # DEFESA (2026-11-27): crava o contrapeso — ninguém te empurra por duracao_s; anda devagar
			if s["t"] > 0.0:
				return
			if not r.is_on_floor():
				_fail(r, "SÓ NO CHÃO")
				return
			s["t"] = float(c["duracao_s"])
			anchors[r.pid] = {"t": 0.0, "len": float(c["duracao_s"]) + RobotVis.ANCORA_CRAVA_S, "pos": r.position + Vector2(-r.facing * 34.0, 0),
				"cravou": false, "tranco": 0.0, "arrasta": false, "sulcos": [], "fc": r.facing}
			r.spell_speed = float(c["vel_mult"])
			r.ancora_t = 1.0
			Audio.play("marreta_vento", 0.6, -4.0)
		"D02":   # passivo: dispara sozinho (ver _update_airbag)
			_fail(r, "DISPARA SOZINHO")
		"D03":   # DEFESA lote D2: molas em volta por duracao_s — rebate golpe e tiro
			if s["t"] > 0.0:
				return
			s["t"] = float(c["duracao_s"])
			bumpers[r.pid] = {"t": 0.0, "len": float(c["duracao_s"]), "tranco": 0.0, "cd": {}}
			r.mola_t = 1.0
			main.shake(3.0)
			Audio.play("pulo_mola", 1.2, -2.0)
		"D05":   # DEFESA lote D3: capacete de aço — absorve os próximos golpes/tiros
			if s["t"] > 0.0:
				return
			s["t"] = 1.0
			helmets[r.pid] = {"t": 0.0, "cd": 0.0, "tranco": 0.0, "fc": r.facing}
			r.capacete_n = int(c["protecoes"])
			main.shake(3.0)
			main.float_text(r.position + Vector2(0, -140), "CLANC!", FAM_COR["defesa"])
			Audio.play("chave", 0.6, 0.0)
		"D06":   # DEFESA lote D3: deixa o boneco de teste no lugar e recua num pulo
			decoys.append({"owner": r.pid, "pos": r.position, "t": 0.0, "len": float(c["duracao_s"]), "fc": r.facing, "morre": -1.0})
			r.forced_t = 0.2   # pulo para trás garantido (sem o freio do chão)
			r.forced_vel = Vector2(-r.facing * float(c["recuo_vx"]), -float(c["recuo_vy"]))
			main.dust(r.position, 1.0)
			Audio.play("pulo_mola", 1.1, -2.0)
			_spend(r, s)
		"D04":   # DEFESA lote D2: rasga o saco de cimento → nuvem de pó (intocável, não ataca)
			if s["t"] > 0.0:
				return
			s["t"] = float(c["duracao_s"]) + float(c["rasga_s"])
			dusts[r.pid] = {"t": 0.0, "len": float(c["duracao_s"]), "rasga": float(c["rasga_s"]), "puf": false, "pts": []}
			Audio.play("arremesso", 0.7, -4.0)
		"T02", "T03", "T05", "T06", "T07":
			if s["t"] < 0.0:
				_start_form(r, s)
			elif s["id"] == "T02":
				_fork_action(r, s)
			elif s["id"] == "T03":
				s["channel"] = true   # segura: fecha em bola e rola (A30/A33)
				if _is_bot(r.pid):
					bot_hold[r.pid] = 1.4
			elif s["id"] == "T05":
				s["channel"] = true   # segura: DASH furando (A30)
				if _is_bot(r.pid):
					bot_hold[r.pid] = 0.9
			elif s["id"] == "T06":
				s["channel"] = true   # segura: raio em cadeia (A30)
				if _is_bot(r.pid):
					bot_hold[r.pid] = 0.8
			elif s["id"] == "T07":
				s["channel"] = true   # segura: ARRANCADA (A36)
				if _is_bot(r.pid):
					bot_hold[r.pid] = 0.7
		"T04":
			if s["t"] < 0.0:
				s["t"] = float(c["duracao_s"])
				Audio.play("foguete", 0.7, -2.0)
			if _is_bot(r.pid):
				bot_hold[r.pid] = 0.8
		"C02":   # segura: sopra enquanto a barra dura
			s["channel"] = true
			if _is_bot(r.pid):
				bot_hold[r.pid] = 1.2
			Audio.play("ventilador", 1.0, -2.0)
		"C03":
			_fire_hook(r, s)
		"C05":
			_fire_lasso(r, s)
		"E02":
			_use_charge(r, s)
		"E03":
			var tg = remote_target(r)
			if tg == null:
				_fail(r, "NADA AO ALCANCE")
				return
			_remote_drop(r, tg)
			s["fire"] = 0.0
			_spend(r, s)
		"C01":   # segura: o ímã liga e vai gastando a barra
			s["channel"] = true
			if _is_bot(r.pid):
				bot_hold[r.pid] = s["energy"]
			Audio.play("ima", 0.8, 0.0)
		"E01":
			var pr := scaffold_rect(r)
			if not scaffold_ok(r, pr):
				_fail(r, "SEM ESPAÇO")
				return
			_build_scaffold(r, pr)
			s["fire"] = 0.0
			_spend(r, s)
		"C04":
			if _is_bot(r.pid):   # bot: vai direto para a frente (ou para cima, caindo)
				var dest = teleport_dest(r)
				if dest == null:
					return
				_teleport(r, dest)
				_spend(r, s)
				return
			s["channel"] = true   # segura: mira com o direcional, solta para ir
			var start: Vector2 = r.position + Vector2(r.facing * 3.0 * T, 0)
			aims[r.pid] = {"pos": start, "t": 0.0, "ok": _free_at(start)}
			r.spell_lock = true
			Audio.play("teleporte", 0.7, -8.0)
		"T01":
			if s["t"] < 0.0:
				_start_armor(r, s)
			else:
				s["channel"] = true   # segura: jato de fogo contínuo
				if _is_bot(r.pid):
					bot_hold[r.pid] = 0.9
				flames[r.pid] = flames.get(r.pid, {"k": 0.0, "hitcd": {}})

func _stop_channel(r) -> void:
	if not slot.has(r.pid):
		return
	var s: Dictionary = slot[r.pid]
	s["channel"] = false
	if s["id"] == "C01":
		r.spell_speed = 1.0
	elif s["id"] == "T01" and s["t"] > 0.0:
		r.spell_speed = float(sc("T01")["vel_mult"])

func _fire(r, s: Dictionary) -> void:
	var c: Dictionary = sc(s["id"])
	s["fire"] = 0.0
	s["cd"] = float(c.get("intervalo_s", 0.3))
	if s["id"] in ["A02", "A04", "A08"]:
		_fire2(r, s)
		return
	if s["id"] == "A01":
		# braço de tesoura estica numa linha reta até bater em parede; acerta todos os alinhados (1 vez cada)
		var h := muzzle(r, "A01")
		var dv := aim_dir(r)
		var maxd := float(c["alcance_tiles"]) * T
		var d := 0.0
		while d < maxd:
			var nx: Vector2 = h + dv * (d + 12.0)
			if _hard_at(nx):
				break
			d += 12.0
		var kc := float(s.get("carga", 0.0))
		fists.append({"owner": r.pid, "t": 0.0, "reach": maxf(d, 40.0), "dir": r.facing, "dirv": dv, "hit": [], "wall": d < maxd - 12.0, "impact": -1.0, "carga": kc})
		Audio.play("arremesso", 0.7, 2.0)
		Audio.play("pistao", 1.3 - 0.4 * kc, -2.0 + 3.0 * kc)
		r.own_vx -= dv.x * (160.0 + 360.0 * kc)   # coice (maior com a carga cheia)
		main.dust(r.position + Vector2(-r.facing * 16.0, 0), 0.6 + 0.8 * kc)
		if dv.y > 0.5 and not r.is_on_floor():
			r.velocity.y = minf(r.velocity.y, -180.0)   # socão para baixo no ar dá um pulinho
		main.shake(4.0 + 6.0 * kc)
		s["carga"] = 0.0
		_spend(r, s)
	elif s["id"] == "A03":
		var dv3 := aim_dir(r)
		shots.append({"pos": muzzle(r, "A03"), "vel": dv3 * float(c["vel"]), "owner": r.pid, "t": 0.0})
		Audio.play("gelo", 1.6, -2.0)
		r.own_vx -= dv3.x * 140.0   # coice
		for k in 6:
			main.spark(muzzle(r, "A03"), 1)
		_spend(r, s)

## A04: área da cratera (à frente de quem bate, na altura do piso; 2,5 tiles de largura, 1 de altura)
func crater_rect(r) -> Rect2:
	var c: Dictionary = sc("A04")
	var x0: float = r.position.x + r.facing * float(c["cratera_frente_px"])
	var w := float(c["cratera_tiles"]) * T
	return Rect2(minf(x0, x0 + r.facing * w), r.position.y - 48.0, w, 72.0)   # rente ao piso: quem pulou no preparo escapa

## E01: onde o andaime vai aparecer. No chão: 2 tiles à frente, 2 tiles acima dos pés (degrau);
## no ar: logo embaixo dos pés (salvamento).
func scaffold_rect(r) -> Rect2:
	var w := float(sc("E01")["largura_tiles"]) * T
	if r.is_on_floor():
		var cx: float = r.position.x + r.facing * 2.4 * T
		return Rect2(cx - w / 2.0, r.position.y - 2.0 * T, w, 20)
	return Rect2(r.position.x - w / 2.0, r.position.y + 30.0, w, 20)

func scaffold_ok(r, pr: Rect2) -> bool:
	var ko: Rect2 = main.level.ko_rect()
	if ko.has_area() and not ko.grow(-96).encloses(pr):
		return false
	for x in range(int(floor(pr.position.x / T)), int(floor(pr.end.x / T)) + 1):
		if main.level.is_solid(Vector2i(x, int(floor((pr.position.y + 10.0) / T)))):
			return false
	for o in main.robots:
		if o.alive and o.rect().intersects(pr.grow(-4)):
			return false
	return true

## Altura das pernas do andaime: até o chão (máx. 3 tiles); sem chão, pernas curtas penduradas.
func _leg_len(pr: Rect2) -> float:
	var y0 := pr.position.y + 22.0
	for k in 48:
		var yy := y0 + k * 4.0
		var hit := false
		for xx in [pr.position.x + 26.0, pr.end.x - 26.0]:
			if main.level.is_solid(Vector2i(int(floor(xx / T)), int(floor(yy / T)))):
				hit = true
		if hit:
			return yy - y0
	return 34.0

func _build_scaffold(r, pr: Rect2) -> void:
	var c: Dictionary = sc("E01")
	for p in platforms.duplicate():
		if p["owner"] == r.pid:
			_remove_platform(p)   # 1 por jogador: o antigo dobra
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = pr.size
	cs.shape = shp
	cs.position = pr.get_center()
	cs.one_way_collision = true
	body.add_child(cs)
	add_child(body)
	platforms.append({"rect": pr, "body": body, "t": float(c["duracao_s"]), "len": float(c["duracao_s"]), "owner": r.pid,
		"k": 0.0, "from": hand(r), "leg": _leg_len(pr), "landed": false})
	Audio.play("arremesso", 1.4, -4.0)

func _remove_platform(p: Dictionary) -> void:
	if is_instance_valid(p["body"]):
		p["body"].queue_free()
	platforms.erase(p)
	main.dust(p["rect"].get_center(), 0.7)

## C04 (bot / teste): destino à frente (ou ▲ para cima); tenta mais perto se o ponto estiver ocupado. null = nada livre.
func teleport_dest(r):
	var c: Dictionary = sc("C04")
	var up: bool = PlayerInput.held(r.pid, "up") or (not r.is_on_floor() and r.velocity.y > 200.0)
	for k in [0.7, 0.55, 0.4]:
		var d: float = float(c["alcance_tiles"]) * T * k
		var dest: Vector2 = r.position + (Vector2(0, -d) if up else Vector2(r.facing * d, 0))
		if _free_at(dest):
			return dest
	return null

func _free_at(feet: Vector2) -> bool:
	var ko: Rect2 = main.level.ko_rect()
	if ko.has_area() and not ko.grow(-128).has_point(feet):
		return false
	for xx in [feet.x - 22.0, feet.x + 22.0]:
		for yy in [feet.y - 4.0, feet.y - 36.0, feet.y - 68.0]:
			if main.level.is_solid(Vector2i(int(floor(xx / T)), int(floor(yy / T)))):
				return false
	return true

## Teletransporte: o robô vira um fio de luz, some, e se remonta no destino.
func _teleport(r, dest: Vector2) -> void:
	teles.append({"pid": r.pid, "a": r.position, "b": dest, "t": 0.0, "moved": false})
	r.spell_lock = true
	r.vis.s_sqx[0] = 0.15   # afina até virar um fio
	r.vis.s_sqy[0] = 1.5
	Audio.play("teleporte", 1.2, -1.0)

func _update_aims(dt: float) -> void:
	var c: Dictionary = sc("C04")
	for pid in aims.keys():
		var r = main.robots[pid]
		var a: Dictionary = aims[pid]
		a["t"] += dt
		var dir := Vector2(PlayerInput.axis_x(pid), 0)
		if PlayerInput.held(pid, "up"):
			dir.y -= 1.0
		if PlayerInput.held(pid, "down"):
			dir.y += 1.0
		if dir.length() > 0.2:
			a["pos"] += dir.normalized() * float(c["mira_vel"]) * dt
		var off: Vector2 = a["pos"] - r.position
		var maxd := float(c["alcance_tiles"]) * T
		if off.length() > maxd:
			a["pos"] = r.position + off.normalized() * maxd
		a["ok"] = _free_at(a["pos"])
		# mirando: o robô para (no ar, cai devagar)
		r.own_vx *= 0.8
		r.velocity.y = minf(r.velocity.y, 70.0)
		if not held(r) or a["t"] >= float(c["mira_max_s"]):
			aims.erase(pid)
			var s: Dictionary = slot[pid]
			s["channel"] = false
			if a["ok"]:
				_teleport(r, a["pos"])
				s["fire"] = 0.0
				_spend(r, s)
			else:
				r.spell_lock = false
				_fail(r, "DESTINO BLOQUEADO")

func _update_teles(dt: float) -> void:
	for e in teles:
		e["t"] += dt
		var r = main.robots[e["pid"]]
		r.velocity = Vector2.ZERO
		r.own_vx = 0.0
		if e["t"] >= 0.07 and not e["moved"]:
			e["moved"] = true
			r.position = e["b"]
			r.reset_physics_interpolation()
			r.vis.visible = false
			for k in 8:
				main.spark(e["a"] + Vector2(randf_range(-14, 14), randf_range(-80, 0)), 1)
		if e["t"] >= 0.15 and not r.vis.visible:
			r.vis.visible = true
			r.vis.s_sqx[0] = 0.2   # se remonta: fio que engorda e assenta na mola
			r.vis.s_sqy[0] = 1.55
			main.dust(e["b"], 0.6)
		if e["t"] >= 0.26:
			r.spell_lock = false
			r.atk_cd = maxf(r.atk_cd, float(sc("C04")["recupera_s"]))
	teles = teles.filter(func(e): return e["t"] < 0.26)

# ---------------------------------------------------------------- A03: congelado
func freeze(o, by: int) -> void:
	var c: Dictionary = sc("A03")
	o.frozen_t = float(c["congela_s"])
	o.hanging = false
	o.own_vx *= 0.25
	o.last_attacker = by
	o.last_hit = 0.0
	o.last_cause = "congelado"
	frozen[o.pid] = {"len": o.frozen_t, "age": 0.0, "shake": 0.0, "last_ax": 0}
	main.float_text(o.position + Vector2(0, -120), "CONGELOU!", Color("#8fd3f0"))
	Audio.play("gelo", 0.8, 2.0)

## O gelo estilhaça (soltou sozinho, agitou até quebrar ou levou pancada).
func shatter(o) -> void:
	var c: Vector2 = o.rect().get_center()
	Audio.play("gelo_quebra")
	for k in 18:
		var a := randf_range(-PI, 0.0)
		shards.append({"pos": c + Vector2(randf_range(-24, 24), randf_range(-36, 30)), "vel": Vector2.from_angle(a) * randf_range(180, 520) + Vector2(0, -80),
			"rot": randf() * TAU, "spin": randf_range(-14, 14), "t": 0.0, "size": randf_range(6, 15)})
	frozen.erase(o.pid)
	o.frozen_t = 0.0

func _update_frozen(dt: float) -> void:
	var c: Dictionary = sc("A03")
	for o in main.robots:
		if o.frozen_t <= 0.0:
			if frozen.has(o.pid):
				frozen.erase(o.pid)
			continue
		if not o.alive:
			o.frozen_t = 0.0
			continue
		if not frozen.has(o.pid):
			frozen[o.pid] = {"len": o.frozen_t, "age": 0.0, "shake": 0.0, "last_ax": 0}
		var f: Dictionary = frozen[o.pid]
		f["age"] += dt
		f["shake"] = maxf(f["shake"] - dt * 6.0, 0.0)
		# agitar o direcional (esquerda ↔ direita) ou apertar pulo quebra o gelo mais rápido
		var ax := PlayerInput.axis_x(o.pid)
		var sg := 0 if absf(ax) < 0.5 else int(signf(ax))
		var mash: bool = (sg != 0 and sg != f["last_ax"]) or PlayerInput.pressed(o.pid, "jump")
		if sg != 0:
			f["last_ax"] = sg
		if _is_bot(o.pid) and main.rng.randf() < 0.12:
			mash = true
		if mash:
			o.frozen_t -= float(c["agitar_reduz_s"])
			f["shake"] = 1.0
			Audio.play("gelo", 1.8 + main.rng.randf() * 0.3, -14.0)
		o.frozen_t -= dt
		o.stun_t = maxf(o.stun_t, 0.05)   # preso no gelo: sem controle (desliza e cai)
		if o.frozen_t <= 0.0:
			shatter(o)
	for sh in shards:
		sh["t"] += dt
		sh["vel"].y += 1500.0 * dt
		sh["pos"] += sh["vel"] * dt
		sh["rot"] += sh["spin"] * dt
	shards = shards.filter(func(sh): return sh["t"] < 0.9)

# ---------------------------------------------------------------- C01 Superímã (segurar)
func _update_magnet(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("C01")
	if not held(r) or s["energy"] <= 0.0:
		_stop_channel(r)
		if s["energy"] <= 0.0:
			s["empty_t"] = 0.35
			Audio.play("ima", 1.6, -4.0)
		return
	s["energy"] -= dt
	r.spell_speed = float(c["dono_vel_mult"])
	var orig := muzzle(r, "C01")
	var rng := float(c["alcance_tiles"]) * T
	for o in main.robots:
		if o == r or not o.alive or o.invuln > 0.0 or o.guard_t > 0.0 or o.god:
			continue
		var oc: Vector2 = o.rect().get_center()
		var d: Vector2 = orig - oc
		var ad := aim_dir(r)
		var along: float = (oc - orig).dot(ad)
		var side: float = absf((oc - orig).dot(ad.orthogonal()))
		if along < -30.0 or along > rng or side > 2.0 * T + along * 0.3:
			continue   # fora do cone (gira com a mira: puxa de cima, de baixo, na diagonal)
		var k := 1.0 - 0.45 * d.length() / rng
		if d.length() < 44.0:
			o.own_vx = 0.0   # grudou no ímã
			o.velocity.y = 0.0
		else:
			var pull := d.normalized() * float(c["vel_max"]) * k
			o.own_vx = move_toward(o.own_vx, pull.x, float(c["forca"]) * dt)
			o.velocity.y = move_toward(o.velocity.y, pull.y if absf(pull.y) > 60.0 else clampf(d.y * 5.0, -380.0, 380.0), float(c["forca"]) * 0.8 * dt)
		o.stun_t = maxf(o.stun_t, 0.08)
		o.hanging = false
		o.last_hit = 0.0
		o.last_attacker = r.pid
		o.last_cause = "superímã"

# ---------------------------------------------------------------- T01 Armadura Fornalha
func _start_armor(r, s: Dictionary) -> void:
	var c: Dictionary = sc("T01")
	s["t"] = float(c["duracao_s"])
	s["data"]["assemble"] = 0.0
	r.spell_speed = float(c["vel_mult"])
	r.spell_push = float(c["empurrao_mult"])
	main.shake(6.0)
	Audio.play("caixote_pancada", 0.6, 2.0)
	main.float_text(r.position + Vector2(0, -150), "BLINDADO!", FAM_COR["transformacao"])

func _update_flame(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("T01")
	var fl: Dictionary = flames.get(r.pid, {"k": 0.0, "hitcd": {}})
	flames[r.pid] = fl
	var on: bool = s["channel"] and held(r) and s["energy"] > 0.0
	if s["channel"] and not on:
		_stop_channel(r)
	fl["k"] = move_toward(fl["k"], 1.0 if on else 0.0, dt * (8.0 if on else 5.0))
	if not on:
		if fl["k"] <= 0.0:
			flames.erase(r.pid)
		return
	s["energy"] -= dt
	r.spell_speed = float(c["vel_mult"]) * 0.55
	if fmod(t, 0.12) < dt:
		Audio.play("chama", 0.8 + main.rng.randf() * 0.2, -4.0)
	for oid in fl["hitcd"].keys():
		fl["hitcd"][oid] -= dt
	var reach: float = float(c["fogo_alcance_tiles"]) * T * fl["k"]
	var o0: Vector2 = mecha_muzzle(r)   # sai da boca do lança-chamas do mecha (A29)
	var ad := aim_dir(r)
	# partículas do jato (A30: "o mais animado possível"): ~140/s, saem da boca na mira e espalham
	var nps: int = int(float(fl.get("acc", 0.0)) + dt * 140.0)
	fl["acc"] = fl.get("acc", 0.0) + dt * 140.0 - nps
	for i in nps:
		var ang: float = ad.angle() + main.rng.randf_range(-0.16, 0.16)
		var spd: float = main.rng.randf_range(430.0, 600.0) * float(fl["k"])
		fire_ps.append({"pos": o0 + ad * main.rng.randf_range(0, 10), "vel": Vector2.from_angle(ang) * spd + r.velocity * 0.3,
			"t": 0.0, "life": main.rng.randf_range(0.32, 0.48), "s": main.rng.randf_range(0.8, 1.25), "em": false})
		if main.rng.randf() < 0.3:   # brasas que caem
			fire_ps.append({"pos": o0, "vel": Vector2.from_angle(ang + main.rng.randf_range(-0.5, 0.5)) * main.rng.randf_range(200, 420),
				"t": 0.0, "life": main.rng.randf_range(0.6, 0.9), "s": 1.0, "em": true})
	for o in main.robots:
		if o != r and o.alive and _seg_rect(o0, o0 + ad * reach, o.rect(), 20.0) and float(fl["hitcd"].get(o.pid, 0.0)) <= 0.0:
			fl["hitcd"][o.pid] = float(c["fogo_tick_s"])
			_hit_dir(o, r.pid, ad, "spell_fogo")
	if s["energy"] <= 0.0:
		_explode_armor(r)

## Acabou o carvão (ou o tempo): a fornalha explode, empurra quem está perto e as placas voam.
func _explode_armor(r) -> void:
	var c: Dictionary = sc("T01")
	var ctr: Vector2 = r.rect().get_center()
	demo.booms.append({"pos": ctr, "t": 0.0})
	main.impact_fx(ctr, 0, 1.4)
	main.shake(12.0)
	Audio.play("explosao", 1.1, 0.0)
	for o in main.robots:
		if o != r and o.alive and o.rect().get_center().distance_to(ctr) < float(c["explosao_raio_tiles"]) * T:
			o.take_hit(1 if o.position.x >= r.position.x else -1, "spell_explosao", r.pid)
	_end_armor(r, true)

func _end_armor(r, natural: bool) -> void:
	r.spell_speed = 1.0
	r.spell_push = 1.0
	flames.erase(r.pid)
	if slot.has(r.pid):
		slot[r.pid]["t"] = -1.0
		slot[r.pid]["channel"] = false
	_mecha_explode(r)   # o mecha desmonta: estouro de faíscas, fumaça e poeira (A29)
	Audio.play("caixote_quebra", 1.2, -2.0)
	if natural:
		slot.erase(r.pid)

# ---------------------------------------------------------------- quadro a quadro
var fire_ps: Array = []   # partículas de fogo da Fornalha (A30)
var mecha_fx: Array = []  # rastros e ondas dos golpes leve/pesado do mecha (A33)
var trans_fx: Array = []  # fecho da transformação: clarão, raios, onda de choque no chão, nome (A29)

## Mecha montado (fim da transformação estilo Transformers): o olho acende, clarão, onda de choque, poeira e o NOME.
func _assembled(r, id: String) -> void:
	var fy := _floor_below(r.position.x, r.position.y - 10.0, 4)
	trans_fx.append({"pos": r.position + Vector2(0, -66), "ground": Vector2(r.position.x, fy if fy > 0.0 else r.position.y), "t": 0.0})
	main.float_text(r.position + Vector2(0, -175), NOMES.get(id, id) + "!", FAM_COR["transformacao"])
	main.dust(r.position, 1.8)
	main.shake(9.0)
	for k in 14:
		main.spark(r.position + Vector2(randf_range(-45, 45), randf_range(-120, -15)), 1)
	Audio.play("caixote_pancada", 0.7, 0.0)

func update(dt: float, alive: Array) -> void:
	t += dt
	for fp in fire_ps:
		fp["t"] += dt
		fp["pos"] += fp["vel"] * dt
		if fp["em"]:
			fp["vel"].y += 700.0 * dt
		else:
			fp["vel"] *= 0.985
			fp["vel"].y -= 160.0 * dt   # o fogo sobe
	fire_ps = fire_ps.filter(func(fp): return fp["t"] < fp["life"])
	for e in mecha_fx:
		e["t"] += dt
	mecha_fx = mecha_fx.filter(func(e): return e["t"] < 0.45)
	for tf in trans_fx:
		tf["t"] += dt
	trans_fx = trans_fx.filter(func(tf): return tf["t"] < 0.7)
	for pid in bot_hold.keys():
		bot_hold[pid] -= dt
		if bot_hold[pid] <= 0.0:
			bot_hold.erase(pid)
	_update_boxes(dt, alive)
	_update_holds(dt)
	_update_aims(dt)
	_update_pile_aims(dt)
	for r in main.robots:   # E03: ▲ troca qual viga fica na mira
		if r.alive and slot.has(r.pid) and slot[r.pid]["id"] == "E03" and PlayerInput.pressed(r.pid, "up"):
			slot[r.pid]["data"]["tgt_i"] = int(slot[r.pid]["data"].get("tgt_i", 0)) + 1
			Audio.play("menu_mover", 1.4, -6.0)
	_update_teles(dt)
	_update_frozen(dt)
	_update_pinned(dt)
	_update_decoys(dt)
	for hf in helmet_fly:
		hf["t"] += dt
		hf["vel"].y += 1400.0 * dt
		hf["pos"] += hf["vel"] * dt
		hf["rot"] += dt * 14.0
	helmet_fly = helmet_fly.filter(func(hf): return hf["t"] < 1.2)
	for e in sinks:
		e["t"] += dt
	sinks = sinks.filter(func(e): return e["t"] < 0.8)
	for e in pops:
		e["t"] += dt
	pops = pops.filter(func(e): return e["t"] < 0.5)
	for r in main.robots:
		if not slot.has(r.pid):
			continue
		if not r.alive:
			clear(r)
			continue
		var s: Dictionary = slot[r.pid]
		s["cd"] = maxf(s["cd"] - dt, 0.0)
		if s["fire"] >= 0.0:
			s["fire"] += dt
		if s.has("empty_t"):
			s["empty_t"] -= dt
			if s["empty_t"] <= 0.0:
				slot.erase(r.pid)
				continue
		if s["prep"] >= 0.0:
			s["prep"] += dt
			_set_aim(r, s, aim_vec(r))
			if r.stun_t > 0.0:
				s["prep"] = -1.0   # levou golpe na preparação: cancela (sem gastar carga)
				s.erase("carga_hold")
			elif s.get("carga_hold", false):
				var cmax: float = s["prep_len"]
				if (not held(r) and s["prep"] >= float(sc("A01")["carga_min_s"])) or s["prep"] >= cmax + float(sc("A01")["segura_max_s"]):
					s["carga"] = clampf(s["prep"] / cmax, 0.0, 1.0)
					s["prep"] = -1.0
					s.erase("carga_hold")
					_fire(r, s)
				elif s["prep"] >= cmax and fmod(s["prep"], 0.25) < dt:
					main.spark(muzzle(r, "A01"), 1)   # cheio: chiando, esperando soltar
			elif s["prep"] >= s["prep_len"]:
				s["prep"] = -1.0
				_fire(r, s)
		if s.has("beam"):
			_update_beam(r, s, dt)
		if s["id"] == "D01" and anchors.has(r.pid):
			_update_anchor(r, s, dt)
		if s["id"] == "D02":
			_update_airbag(r, s, dt)
		if s["id"] == "D03" and bumpers.has(r.pid):
			_update_bumper(r, s, dt)
		if s["id"] == "D05" and helmets.has(r.pid):
			helmets[r.pid]["t"] += dt
			helmets[r.pid]["cd"] = maxf(float(helmets[r.pid]["cd"]) - dt, 0.0)
			helmets[r.pid]["tranco"] = maxf(float(helmets[r.pid]["tranco"]) - dt * 4.0, 0.0)
			if not r.alive:
				helmets.erase(r.pid)
				r.capacete_n = 0
		if s["id"] == "D04" and dusts.has(r.pid):
			_update_dust(r, s, dt)
		if int(s.get("burst", 0)) > 0 and s["id"] == "A05":
			s["burst_t"] -= dt
			if r.stun_t > 0.0:
				s["burst"] = 0
				s["cd"] = float(sc("A05")["intervalo_s"])
			elif s["burst_t"] <= 0.0:
				_fire_rivet(r, s)
		if s["channel"] and s["id"] in ["C01", "C02"] or (s["id"] == "T01" and flames.has(r.pid) and s["channel"]):
			_set_aim(r, s, aim_vec(r), 7.0, dt)
		if s["id"] == "C01" and s["channel"]:
			_update_magnet(r, s, dt)
		if s["id"] == "C02" and s["channel"]:
			_update_fan(r, s, dt)
		if s["id"] in FORMS and s["t"] > 0.0:
			_update_form(r, s, dt)
			if not slot.has(r.pid):
				continue
		if s["id"] == "T04" and s["t"] > 0.0:
			var ab4: float = float(s["data"].get("assemble", 0.0))
			s["data"]["assemble"] = minf(ab4 + dt / 0.9, 1.0)
			if ab4 < 1.0 and s["data"]["assemble"] >= 1.0:
				_assembled(r, "T04")
			_update_jet(r, s, dt)
			if not slot.has(r.pid):
				continue
		if s["id"] == "T01" and s["t"] > 0.0:
			var ab1: float = float(s["data"].get("assemble", 0.0))
			s["data"]["assemble"] = minf(ab1 + dt / 0.9, 1.0)
			if ab1 < 1.0 and s["data"]["assemble"] >= 1.0:
				_assembled(r, "T01")
			_update_flame(r, s, dt)
			if slot.has(r.pid) and s["t"] > 0.0:
				s["t"] -= dt
				if s["t"] <= 0.0:
					_explode_armor(r)
	_update_fists(dt)
	_update_shots(dt)
	_update_attack2(dt)
	_update_etapa3(dt)
	_update_etapa4(dt)
	for p in platforms.duplicate():
		p["t"] -= dt
		p["k"] = minf(p["k"] + dt / 0.32, 1.0)
		if p["k"] >= 0.35 and not p["landed"]:
			p["landed"] = true
			main.dust(p["rect"].get_center() + Vector2(0, 10), 0.9)
			Audio.play("alavanca", 1.5)
			Audio.play("caixote_pancada", 1.4, -6.0)
		if p["t"] <= 0.0:
			_remove_platform(p)
	for e in feedback:
		e["t"] += dt
	feedback = feedback.filter(func(e): return e["t"] < 1.0)
	queue_redraw()
	if ghost != null:
		ghost.queue_redraw()

## Punho: sai rápido com passada do ponto (mola), segura um instante e recolhe.
const FIST_OUT := 0.09
const FIST_HOLD := 0.08
const FIST_BACK := 0.16

func fist_ext(f: Dictionary) -> float:
	var tt: float = f["t"]
	if tt < FIST_OUT:
		var u := tt / FIST_OUT
		return 1.0 + 2.70158 * pow(u - 1.0, 3) + 1.70158 * pow(u - 1.0, 2)   # ease-out-back (passa e volta)
	if tt < FIST_OUT + FIST_HOLD:
		return 1.0
	var v := clampf((tt - FIST_OUT - FIST_HOLD) / FIST_BACK, 0.0, 1.0)
	return 1.0 - v * v

func _update_fists(dt: float) -> void:
	for f in fists:
		f["t"] += dt
		var r = main.robots[f["owner"]]
		var from := muzzle(r, "A01")
		var ext := minf(fist_ext(f), 1.0)
		var tip: Vector2 = from + f["dirv"] * f["reach"] * ext
		if f["t"] <= FIST_OUT + FIST_HOLD:
			for o in main.robots:
				if o.pid == f["owner"] or not o.alive or o.pid in f["hit"]:
					continue
				if _seg_rect(from, tip, o.rect(), 22.0):
					f["hit"].append(o.pid)
					if _hit_dir(o, f["owner"], f["dirv"], "spell_punho"):
						var kc: float = f.get("carga", 0.0)
						var c1: Dictionary = sc("A01")
						o.own_vx *= lerpf(1.0, float(c1["mult_cheio"]), kc)
						if absf(f["dirv"].y) < 0.5:
							o.velocity.y = lerpf(o.velocity.y, -float(c1["sobe_cheio"]), kc)   # carga cheia: voo mais reto
						o.hitstop = 0.08 + 0.06 * kc
						r.hitstop = 0.06 + 0.05 * kc
						f["impact"] = 0.0
						main.shake(5.0 + 9.0 * kc)
						if kc >= float(c1["quique_min_carga"]):
							punch_fly.append({"pid": o.pid, "owner": f["owner"], "t": 0.0, "dir": int(signf(o.own_vx)) if absf(o.own_vx) > 1.0 else r.facing})
		if f["impact"] >= 0.0:
			f["impact"] += dt
		if f["t"] >= FIST_OUT and not f.get("done", false):
			f["done"] = true
			if f["wall"]:
				f["impact"] = 0.0
				main.spark(tip, 5)
				Audio.play("bonk", 0.8, -2.0)
				var ct = demo.canteiro
				if ct != null and is_instance_valid(ct):
					for p in ct.parts:
						if not p["fallen"] and p["state"] >= 1 and p["rect"].grow(8).has_point(tip + f["dirv"] * 14.0):
							ct.damage(p, 1, tip)   # rompe só peça já fragilizada
	fists = fists.filter(func(f): return f["t"] < FIST_OUT + FIST_HOLD + FIST_BACK)
	# voo do soco carregado: bateu em parede/bloco → quica de volta e racha a peça
	var c1: Dictionary = sc("A01")
	for pf in punch_fly:
		pf["t"] += dt
		var o = main.robots[pf["pid"]]
		if not o.alive:
			pf["t"] = 99.0
			continue
		var d: int = pf["dir"]
		var fr: Vector2 = o.position + Vector2(d * 30.0, -36.0)
		if absf(o.own_vx) > 260.0 and (o.is_on_wall() or _hard_at(fr)):
			o.own_vx = -d * absf(o.own_vx) * float(c1["quique_perda"])
			o.velocity.y = minf(o.velocity.y, -220.0)
			pf["t"] = 99.0
			main.spark(fr, 10)
			main.dust(fr, 1.2)
			main.shake(10.0)
			Audio.play("caixote_pancada", 0.5, 2.0)
			Audio.play("bonk", 0.7, 0.0)
			bonks.append({"pos": fr, "t": 0.0})
			var ct = demo.canteiro
			if ct != null and is_instance_valid(ct):
				for p in ct.parts:
					if not p["fallen"] and ct.hit_rect(p).grow(14).has_point(fr):
						ct.damage(p, int(c1["dano_bloco"]), fr)   # o bloco racha
						break
	punch_fly = punch_fly.filter(func(pf): return pf["t"] < float(c1["quique_s"]))
	for b in bonks:
		b["t"] += dt
	bonks = bonks.filter(func(b): return b["t"] < 0.3)

func _update_shots(dt: float) -> void:
	var c: Dictionary = sc("A03")
	for s in shots:
		s["t"] += dt
		s["pos"] += s["vel"] * dt
		var hit = null
		for o in main.robots:
			if o.pid != s["owner"] and o.alive and o.invuln <= 0.0 and not o.god and not _intangivel(o) and o.rect().grow(6).has_point(s["pos"]):
				hit = o
				break
		if hit != null and _rebate_tiro(hit, s):
			hit = null
		var wall: bool = _hard_at(s["pos"])
		if hit != null:
			var was_frozen: bool = hit.frozen_t > 0.0
			var gx := int(signf(s["vel"].x)) if absf(s["vel"].x) > 1.0 else 1
			if hit.take_hit(gx, "spell_gelo", s["owner"]) and not was_frozen:
				freeze(hit, s["owner"])
			s["dead"] = true
		elif wall or s["t"] > float(c["alcance_tiles"]) * T / float(c["vel"]):
			s["dead"] = true
		if s.get("dead", false):
			for k in 8:
				shards.append({"pos": s["pos"], "vel": Vector2(-signf(s["vel"].x) * randf_range(60, 320), randf_range(-380, -60)),
					"rot": randf() * TAU, "spin": randf_range(-14, 14), "t": 0.2, "size": randf_range(4, 9)})
			Audio.play("gelo", 1.2, -6.0)
	shots = shots.filter(func(s): return not s.get("dead", false))

## Para o desenho do robô (robot_visual): arma na mão, preparação, disparo, canal (segurando), armadura.
func flags(r) -> Dictionary:
	if not slot.has(r.pid):
		return {}
	var s: Dictionary = slot[r.pid]
	var out := {"spell": s["id"], "fire": s["fire"], "prep": minf(s["prep"] / maxf(s["prep_len"], 0.01), 1.0) if s["prep"] >= 0.0 else -1.0,
		"channel": s["channel"], "aim_a": aim_local(r), "beam": s.has("beam"), "defesa_ativa": anchors.has(r.pid) or airbags.has(r.pid) or bumpers.has(r.pid) or dusts.has(r.pid),
		"ancora_t": float(anchors[r.pid]["t"]) if anchors.has(r.pid) else -1.0, "ancora_tranco": float(anchors[r.pid]["tranco"]) if anchors.has(r.pid) else 0.0,
		"arrasta": anchors.has(r.pid) and anchors[r.pid]["arrasta"], "airbag_k": clampf(float(airbags[r.pid]["t"]) / 0.15, 0.0, 1.0) if airbags.has(r.pid) else 0.0,
		"rasga_k": clampf(float(dusts[r.pid]["t"]) / float(dusts[r.pid]["rasga"]), 0.0, 1.0) if dusts.has(r.pid) and not dusts[r.pid]["puf"] else -1.0,
		"molas": bumpers.has(r.pid), "capacete_n": r.capacete_n, "capacete_tranco": float(helmets[r.pid]["tranco"]) if helmets.has(r.pid) else 0.0}
	if s["id"] == "T01":
		out["armor"] = s["t"] > 0.0
		out["assemble"] = float(s["data"].get("assemble", 0.0))
		var low: float = minf(s["t"], s["energy"] * 2.0)
		out["armor_end"] = clampf(1.0 - low / 1.2, 0.0, 1.0) if s["t"] > 0.0 else 0.0
		out["flame"] = float(flames.get(r.pid, {}).get("k", 0.0))
		if out["armor"]:
			out["mecha"] = "T01"
	for f in fists:
		if f["owner"] == r.pid:
			out["fist"] = minf(fist_ext(f), 1.0)
	if s.has("empty_t"):
		out["fading"] = true
	if s["id"] == "E02":
		out["placed"] = charges_placed.any(func(c): return c["owner"] == r.pid)
	if s["id"] in FORMS and s["t"] > 0.0:
		out["form"] = s["id"]
		out["fk"] = float(s["data"].get("assemble", 1.0))
		if s["id"] in ["T02", "T05", "T06", "T07"]:   # armaduras: o robô veste a máquina (desenhado por robot_visual)
			out["armor"] = true
			out["armor_set"] = s["id"]
			out["assemble"] = out["fk"]
			out["armor_end"] = clampf(1.0 - s["t"] / 1.2, 0.0, 1.0)
			out["arc"] = s["data"].get("arc", false)
			out["busy"] = s["data"].get("arc", false) or s["id"] == "T05" or (s["id"] == "T07" and s["data"].get("dash", false))
			out["drill_dash"] = s["data"].get("dash", false) and s["id"] == "T05"
			out["arrancada"] = s["data"].get("dash", false) and s["id"] == "T07"
			out["mecha"] = s["id"]
	if s["id"] == "T03" and s["t"] > 0.0 and r.spell_form != "bola":
		out["mecha"] = "T03"
		out["assemble"] = float(s["data"].get("assemble", 1.0))
		out["armor_end"] = clampf(1.0 - s["t"] / 1.2, 0.0, 1.0)
	if out.has("mecha") and r.atk != "":   # golpe leve/pesado do mecha (A33): fase para a animação
		var pre: float = float(r._atk_cfg()["preparo"])
		out["matk"] = r.atk
		out["matk_t"] = r.atk_t
		out["matk_pre"] = pre
		out["matk_tot"] = r._atk_total()
	if s["id"] == "T04" and s["t"] > 0.0:
		out["flying_on"] = s["data"].get("thrust", false) or (not r.is_on_floor() and r.velocity.y < 300.0)
		out["fly_vx"] = r.velocity.x
		out["mecha"] = "T04"
		out["assemble"] = float(s["data"].get("assemble", 1.0))
	return out

## HUD: {id, fam, charges, frac} do jogador (ou vazio). frac = barra de energia/duração.
func hud_info(pid: int) -> Dictionary:
	if not slot.has(pid):
		return {}
	var s: Dictionary = slot[pid]
	var frac := 1.0
	if s["id"] in ["C01", "C02"]:
		frac = s["energy"] / float(sc(s["id"])["energia_s"])
	elif s["id"] == "T01" and s["t"] > 0.0:
		frac = s["energy"] / float(sc("T01")["combustivel_s"])
	elif (s["id"] in FORMS or s["id"] in ["D01", "D03", "D04"]) and s["t"] > 0.0:
		frac = s["t"] / float(sc(s["id"])["duracao_s"])
	elif s["id"] == "D05" and helmets.has(pid):
		frac = float(main.robots[pid].capacete_n) / float(sc("D05")["protecoes"])
	elif s["id"] == "T04":
		frac = s["energy"] / float(sc("T04")["combustivel_s"])
	return {"id": s["id"], "fam": s["fam"], "charges": s["charges"] if not s["id"] in ["C01", "C02"] else 0, "frac": clampf(frac, 0.0, 1.0),
		"nome": NOMES.get(s["id"], s["id"])}

# ---------------------------------------------------------------- desenho (mundo)
const INK := Color("#2a1a2e")
const ICE := Color(0.74, 0.92, 1.0)
const ICE_D := Color("#5aa9d6")

func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_engenhocas", _pf)

func _draw_perf() -> void:
	for p in platforms:
		_draw_scaffold(p)
	_draw_boxes()
	# prévia do andaime (holograma) para quem tem a spell
	for r in main.robots:
		if r.alive and slot.has(r.pid) and slot[r.pid]["id"] == "E01" and not slot[r.pid].has("empty_t"):
			var pr := scaffold_rect(r)
			var ok := scaffold_ok(r, pr)
			_draw_scaffold_shape(pr, 1.0, _leg_len(pr), Color(0.45, 0.92, 1.0, 0.38 + 0.1 * sin(t * 6.0)) if ok else Color(1, 0.35, 0.35, 0.4), true)
	_draw_holds()
	_draw_magnets()
	_draw_flames()
	_draw_trans_fx()
	_draw_mecha_fx()
	_draw_fists()
	_draw_attack2()
	_draw_etapa3()
	_draw_etapa4()
	_draw_shots()
	for r in main.robots:
		if frozen.has(r.pid) and r.alive and r.frozen_t > 0.0:
			_draw_ice(r, frozen[r.pid])
	for sh in shards:
		var a: float = 1.0 - sh["t"] / 0.9
		draw_set_transform(sh["pos"], sh["rot"])
		var z: float = sh["size"]
		var tri := PackedVector2Array([Vector2(-z, -z * 0.4), Vector2(z, -z * 0.2), Vector2(-z * 0.1, z * 0.7)])
		draw_colored_polygon(tri, Color(ICE, a))
		draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(1, 1, 1, a), 1.6, true)
		draw_set_transform(Vector2.ZERO)
	_draw_teleports()
	_draw_bars()
	for e in feedback:
		var a: float = 1.0 - e["t"]
		Kit.text(self, e["pos"] + Vector2(-160, -e["t"] * 30.0), e["text"], 26, Color(1, 0.4, 0.4, a), HORIZONTAL_ALIGNMENT_CENTER, 320, 6, Color(0.16, 0.1, 0.18, a))

## Caixas: quicam ao pousar, flutuam, brilham com a cor da família; a especial desce de paraquedas.
func _draw_boxes() -> void:
	for b in boxes:
		var life: float = float(cfg["caixa"]["vida_s"]) - b["t"]
		if life < 3.0 and fmod(t, 0.3) < 0.12:
			continue
		var land: float = b["land_t"]
		var sq := 1.0
		if land < 0.35:
			sq = 1.0 + sin(land / 0.35 * PI * 2.0) * 0.2 * (1.0 - land / 0.35)
		var p: Vector2 = b["pos"] + Vector2(0, sin(t * 3.0 + b["pos"].x) * 3.0 if b["vy"] == 0.0 else 0.0)
		var col: Color = FAM_COR[b["fam"]]
		var pulse := 0.5 + 0.5 * sin(t * 4.0 + b["pos"].x)
		draw_circle(p, 46.0 + pulse * 6.0, Color(col.r, col.g, col.b, 0.18))
		if b["special"] and b["vy"] > 0.0:
			draw_texture_rect(Data.tex("spells/g10_capsula"), Rect2(p + Vector2(-64, -150), Vector2(128, 160)), false)
		else:
			draw_set_transform(p, sin(t * 2.0 + b["pos"].x) * 0.05, Vector2(2.0 - sq, sq))
			draw_texture_rect(Data.tex("spells/caixa_" + b["fam"]), Rect2(-40, -40, 80, 80), false)
			draw_set_transform(Vector2.ZERO)
		var sa: float = t * 2.0 + b["pos"].x
		var sp: Vector2 = p + Vector2.from_angle(sa) * 46.0
		draw_line(sp - Vector2(4, 0), sp + Vector2(4, 0), Color("#fff4c8"), 2.0, true)
		draw_line(sp - Vector2(0, 4), sp + Vector2(0, 4), Color("#fff4c8"), 2.0, true)

## Troca segurando: anel verde enchendo sobre a cabeça.
func _draw_holds() -> void:
	for pid in holds:
		var h: Dictionary = holds[pid]
		var r = main.robots[pid]
		var k := clampf(h["t"] / float(cfg["caixa"]["troca_s"]), 0.0, 1.0)
		var c: Vector2 = r.position + Vector2(0, -150)
		draw_arc(c, 22.0, 0, TAU, 28, Color(0.85, 0.87, 0.9, 0.9), 7.0, true)
		draw_arc(c, 22.0, -PI / 2.0, -PI / 2.0 + TAU * k, 28, Color("#5cc45c"), 7.0, true)
		draw_texture_rect(Data.tex("spells/icone_" + h["box"]["fam"]), Rect2(c - Vector2(13, 13), Vector2(26, 26)), false)

## Barrinha de energia sobre a cabeça enquanto segura (ímã, jato da fornalha).
func _draw_bars() -> void:
	for r in main.robots:
		if not r.alive or not slot.has(r.pid):
			continue
		var s: Dictionary = slot[r.pid]
		var show: bool = s["channel"] or (s["id"] in ["T01", "T04"] and s["t"] > 0.0)
		if not show or s["id"] in ["C04", "A06"]:
			continue
		var full := float(sc(s["id"]).get("energia_s", sc(s["id"]).get("combustivel_s", 1.0)))
		var k := clampf(s["energy"] / full, 0.0, 1.0)
		var bx := Rect2(r.position + Vector2(-34, -126), Vector2(68, 12))
		draw_rect(bx.grow(3), INK)
		draw_rect(bx, Color(1, 1, 1, 0.85))
		var col: Color = FAM_COR[s["fam"]] if k > 0.25 or fmod(t, 0.2) < 0.1 else Color("#ff5a5a")
		draw_rect(Rect2(bx.position, Vector2(bx.size.x * k, bx.size.y)), col)
		draw_rect(Rect2(bx.position, Vector2(bx.size.x * k, 4)), Color(1, 1, 1, 0.45))

# ---------------------------------------------------------------- A01 braço de tesoura + luva
func _draw_fists() -> void:
	for f in fists:
		# tudo desenhado no "quadro do braço": x = direção da mira (8 direções); para a esquerda espelha em y
		var r = main.robots[f["owner"]]
		var dv: Vector2 = f["dirv"]
		var base := Transform2D(dv.angle(), Vector2(1.0, -1.0 if dv.x < -0.1 else 1.0), 0.0, muzzle(r, "A01"))
		var ext := fist_ext(f)
		var L: float = maxf(f["reach"] * ext, 6.0)
		var n := 9
		var w := L / n
		var bar := sqrt(pow(f["reach"] / n, 2) + 22.0 * 22.0)   # barra de tamanho fixo: esticado ainda mostra o X, recolhido abre
		var hh := sqrt(maxf(bar * bar - w * w, 9.0)) / 2.0
		draw_set_transform_matrix(base)
		for pass_i in 2:   # barras em X (contorno escuro + metal)
			for i in n:
				var a := Vector2(w * i, -hh)
				var b := Vector2(w * (i + 1), hh)
				var c := Vector2(w * i, hh)
				var e := Vector2(w * (i + 1), -hh)
				if pass_i == 0:
					draw_line(a, b, INK, 8.0, true)
					draw_line(c, e, INK, 8.0, true)
				else:
					draw_line(a, b, Color("#b9c3cc"), 4.0, true)
					draw_line(c, e, Color("#8e9aa6"), 4.0, true)
		for i in n + 1:   # pinos
			draw_circle(Vector2(w * i, -hh), 3.2, Color("#f2c84b"))
			draw_circle(Vector2(w * i, hh), 3.2, Color("#f2c84b"))
			if i < n:
				draw_circle(Vector2(w * (i + 0.5), 0), 2.6, Color("#f2c84b"))
		if f["t"] < FIST_OUT + 0.04:   # linhas de velocidade
			for k in 4:
				var yy := -22.0 + k * 15.0
				draw_line(Vector2(L - 40.0 - k * 9.0, yy), Vector2(L - 110.0 - k * 14.0, yy), Color(1, 1, 1, 0.85), 3.0, true)
		if f["impact"] >= 0.0 and f["impact"] < 0.16:   # estrela de impacto
			var u: float = f["impact"] / 0.16
			var star := PackedVector2Array()
			for k in 16:
				var rad := (34.0 if k % 2 == 0 else 14.0) * (0.6 + 0.6 * u)
				star.append(Vector2(L + 50.0, 0) + Vector2.from_angle(k * TAU / 16.0 + 0.2) * rad)
			draw_colored_polygon(star, Color(1, 0.95, 0.6, 1.0 - u))
		# luva: estica na saída, achata no impacto
		var sq := Vector2(1.0, 1.0)
		if f["t"] < FIST_OUT:
			sq = Vector2(1.25, 0.85)
		if f["impact"] >= 0.0 and f["impact"] < 0.12:
			var u2: float = f["impact"] / 0.12
			sq = Vector2(0.7 + 0.3 * u2, 1.3 - 0.3 * u2)
		draw_set_transform_matrix(base * Transform2D(0.0, sq, 0.0, Vector2(L, 0)))
		draw_texture_rect(Data.tex("spells/s01_luva"), Rect2(-8, -26, 62, 50), false)
		draw_set_transform(Vector2.ZERO)
	# preparo: luva espiando no cano tremendo + vapor
	for r in main.robots:
		if not slot.has(r.pid) or slot[r.pid]["id"] != "A01" or slot[r.pid]["prep"] < 0.0:
			continue
		var k: float = minf(slot[r.pid]["prep"] / maxf(slot[r.pid]["prep_len"], 0.01), 1.0)
		var dvp := aim_dir(r)
		var h := muzzle(r, "A01") + dvp * (6.0 - 8.0 * k) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (2.0 + 2.5 * k) * k
		# barra de pressão sobre a cabeça (padrão de "segurar"); cheia pisca branca
		var bp: Vector2 = r.position + Vector2(-22, -150)
		draw_rect(Rect2(bp - Vector2(2, 2), Vector2(48, 11)), INK)
		var full := k >= 1.0 and fmod(t, 0.16) < 0.08
		draw_rect(Rect2(bp, Vector2(44.0 * k, 7)), Color.WHITE if full else Color("#ff8a2a").lerp(Color("#ff3b2f"), k))
		draw_set_transform(h, dvp.angle(), Vector2(0.75, -0.75 if dvp.x < -0.1 else 0.75))
		draw_texture_rect(Data.tex("spells/s01_luva"), Rect2(-8, -26, 62, 50), false)
		draw_set_transform(Vector2.ZERO)
		for j in 3:
			var u := fposmod(t * 3.0 + j * 0.33, 1.0)
			draw_circle(h + Vector2(-r.facing * (10.0 + 6.0 * j), -12.0 - u * 26.0), 4.0 + u * 7.0, Color(1, 1, 1, 0.55 * (1.0 - u) * k))
	for b in bonks:   # soco carregado: o rival bateu na parede
		var u: float = b["t"] / 0.3
		var star := PackedVector2Array()
		for k in 16:
			star.append(b["pos"] + Vector2.from_angle(k * TAU / 16.0) * ((40.0 if k % 2 == 0 else 16.0) * (0.6 + 0.7 * u)))
		draw_colored_polygon(star, Color(1, 0.95, 0.6, 1.0 - u))
		draw_arc(b["pos"], 20.0 + 60.0 * u, 0, TAU, 24, Color(1, 1, 1, 1.0 - u), 4.0, true)

# ---------------------------------------------------------------- A03 tiro e bloco de gelo
func _draw_shots() -> void:
	for r in main.robots:   # carga: flocos convergindo para o bico
		if slot.has(r.pid) and slot[r.pid]["id"] == "A03" and slot[r.pid]["prep"] >= 0.0:
			var k: float = slot[r.pid]["prep"] / maxf(slot[r.pid]["prep_len"], 0.01)
			var m := muzzle(r, "A03")
			for j in 8:
				var a := j * TAU / 8.0 + t * 3.0
				var rad := 40.0 * (1.0 - k)
				_flake(m + Vector2.from_angle(a) * rad, 4.0, t * 4.0 + j)
			draw_circle(m, 6.0 + 10.0 * k, Color(ICE, 0.5 + 0.3 * k))
			draw_circle(m, 3.0 + 5.0 * k, Color(1, 1, 1, 0.9))
	for s in shots:
		var dv: Vector2 = s["vel"].normalized()
		var nv := dv.orthogonal()
		# rastro de névoa e flocos (atrás, na linha do tiro)
		for k in 6:
			var q: Vector2 = s["pos"] - dv * (18.0 + k * 13.0) + nv * sin(s["t"] * 30.0 + k) * 3.0
			draw_circle(q, 11.0 - k * 1.4, Color(0.85, 0.96, 1.0, 0.55 - k * 0.08))
		for k in 3:
			_flake(s["pos"] - dv * (30.0 + k * 26.0) + nv * (k - 1) * 12.0, 4.0, s["t"] * 10.0 + k)
		# lança de cristal apontada para onde vai
		draw_set_transform(s["pos"], dv.angle(), Vector2(1, -1 if dv.x < -0.1 else 1))
		var spear := PackedVector2Array([Vector2(26, 0), Vector2(4, -11), Vector2(-20, -7), Vector2(-14, 0), Vector2(-20, 7), Vector2(4, 11)])
		draw_colored_polygon(spear, ICE_D)
		draw_colored_polygon(PackedVector2Array([Vector2(22, 0), Vector2(4, -8), Vector2(-14, -4), Vector2(-8, 0)]), ICE)
		draw_colored_polygon(PackedVector2Array([Vector2(22, 0), Vector2(-8, 0), Vector2(-14, 4), Vector2(4, 8)]), Color(0.62, 0.86, 0.97))
		var gl := fposmod(s["t"] * 6.0, 1.0)
		draw_line(Vector2(-14 + 30 * gl, -4), Vector2(-6 + 30 * gl, -6), Color(1, 1, 1, 0.9), 2.5, true)
		draw_polyline(PackedVector2Array([spear[0], spear[1], spear[2], spear[3], spear[4], spear[5], spear[0]]), Color("#2a5a80"), 2.0, true)
		draw_set_transform(Vector2.ZERO)

func _flake(p: Vector2, z: float, rot: float) -> void:
	for k in 3:
		var a := rot + k * PI / 3.0
		draw_line(p - Vector2.from_angle(a) * z, p + Vector2.from_angle(a) * z, Color(1, 1, 1, 0.9), 1.6, true)

## Bloco de gelo facetado em volta do robô: cresce de baixo, treme quando o jogador agita, racha até quebrar.
func _draw_ice(r, f: Dictionary) -> void:
	var rr: Rect2 = r.rect().grow_individual(14, 16, 14, 4)
	var grow := clampf(f["age"] / 0.14, 0.0, 1.0)
	var top := rr.end.y - rr.size.y * grow
	var sh: Vector2 = Vector2(sin(t * 70.0), cos(t * 63.0)) * 3.0 * f["shake"]
	var seed := float(r.pid) * 1.7
	var j := func(i: int) -> float: return sin(seed + i * 2.3) * 5.0
	var x0: float = rr.position.x + sh.x
	var x1: float = rr.end.x + sh.x
	var y1 := rr.end.y
	var poly := PackedVector2Array([Vector2(x0 + j.call(0), y1), Vector2(x0 - 4 + j.call(1), lerpf(y1, top, 0.45)), Vector2(x0 + 6 + j.call(2), top + 6),
		Vector2(lerpf(x0, x1, 0.4) + j.call(3), top - 4 + j.call(4)), Vector2(x1 - 8 + j.call(5), top + 2), Vector2(x1 + 4 + j.call(6), lerpf(y1, top, 0.5)), Vector2(x1 + j.call(7), y1)])
	draw_colored_polygon(poly, Color(ICE, 0.55))
	# faces internas (luz de cima à esquerda) e reflexos
	var mid := Vector2(lerpf(x0, x1, 0.45), lerpf(top, y1, 0.42))
	draw_colored_polygon(PackedVector2Array([poly[1], poly[2], poly[3], mid]), Color(1, 1, 1, 0.22))
	draw_colored_polygon(PackedVector2Array([poly[4], poly[5], poly[6], mid]), Color(0.35, 0.65, 0.88, 0.2))
	draw_line(poly[2] + Vector2(6, 8), poly[2] + Vector2(14, 34), Color(1, 1, 1, 0.85), 4.0, true)
	draw_line(poly[2] + Vector2(16, 6), poly[2] + Vector2(20, 16), Color(1, 1, 1, 0.7), 3.0, true)
	var outline := poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, ICE_D, 3.5, true)
	# geada na base
	for i in 5:
		var bx := lerpf(x0, x1, (i + 0.5) / 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 9, y1), Vector2(bx, y1 - 10 - sin(seed + i) * 4.0), Vector2(bx + 9, y1)]), Color(1, 1, 1, 0.75))
	# rachaduras: aparecem com o tempo e com a agitação
	var k := 1.0 - clampf(r.frozen_t / maxf(f["len"], 0.01), 0.0, 1.0)
	var cracks := [[Vector2(0.55, 0.0), Vector2(0.45, 0.3), Vector2(0.62, 0.5), Vector2(0.5, 0.75)],
		[Vector2(0.0, 0.4), Vector2(0.25, 0.48), Vector2(0.32, 0.7)], [Vector2(1.0, 0.3), Vector2(0.78, 0.42), Vector2(0.72, 0.62), Vector2(0.85, 0.9)]]
	for ci in cracks.size():
		if k < 0.25 + ci * 0.22:
			continue
		var line := PackedVector2Array()
		for q in cracks[ci]:
			line.append(Vector2(lerpf(x0, x1, q.x), lerpf(top, y1, q.y)))
		draw_polyline(line, Color(1, 1, 1, 0.95), 2.4, true)
	# dica de agitar (jogador humano)
	if not _is_bot(r.pid) and f["age"] > 0.3:
		var a := 0.6 + 0.4 * sin(t * 10.0)
		var c := Vector2(rr.get_center().x, top - 30.0)
		var wob := sin(t * 18.0) * 8.0
		Kit.text(self, c + Vector2(-60 + wob, 0), "◄ ►", 26, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 120, 6, Color(0.16, 0.1, 0.18, a))

# ---------------------------------------------------------------- C01 campo do ímã (buraco negro)
func _draw_magnets() -> void:
	for r in main.robots:
		if not r.alive or not slot.has(r.pid) or slot[r.pid]["id"] != "C01" or not slot[r.pid]["channel"]:
			continue
		var ow := muzzle(r, "C01")
		var adw := aim_dir(r)
		var base := Transform2D(adw.angle(), Vector2(1.0, -1.0 if adw.x < -0.1 else 1.0), 0.0, ow)
		var d := 1.0
		var o := Vector2.ZERO
		var rng := float(sc("C01")["alcance_tiles"]) * T
		# redemoinho: anéis achatados girando e encolhendo para dentro do polo (no quadro da mira)
		for i in 4:
			var u := fposmod(t * 1.8 + i * 0.25, 1.0)
			var rad := 110.0 * (1.0 - u) + 18.0
			var a0 := t * 9.0 + i * 1.3
			draw_set_transform_matrix(base * Transform2D(0.0, Vector2(0.55, 1.0), 0.0, Vector2.ZERO))
			draw_arc(Vector2.ZERO, rad, a0, a0 + 4.2, 24, Color(0.85, 0.29, 0.35, 0.75 * u), 3.0, true)
		draw_set_transform_matrix(base)
		# riscos de sucção vindo de longe (só para a frente) e parafusinhos voando para o polo
		for i in 16:
			var u := fposmod(t * 2.2 + i * 0.137, 1.0)
			var ang := (float(i) / 15.0 - 0.5) * 1.5
			var far := rng * (1.0 - u)
			var q := o + Vector2(d * cos(ang), sin(ang) * 0.6) * far
			var q2 := o + Vector2(d * cos(ang), sin(ang) * 0.6) * (far + 26.0 + 30.0 * (1.0 - u))
			draw_line(q, q2, Color(1, 1, 1, 0.75 * u), 2.0, true)
			if i % 4 == 0:
				draw_circle(q, 3.0, Color("#9aa4ae"))
		draw_set_transform(Vector2.ZERO)
		o = ow
		# núcleo: anel escuro pulsando com borda vermelha
		var pz := 16.0 + 3.0 * sin(t * 20.0)
		draw_circle(o, pz + 6.0, Color(0.85, 0.29, 0.35, 0.35))
		draw_circle(o, pz, Color(0.16, 0.1, 0.18, 0.85))
		draw_arc(o, pz, 0, TAU, 20, Color("#ff8a96"), 2.5, true)
		# faísquinhas nos robôs presos
		for v in main.robots:
			if v != r and v.alive and v.last_cause == "superímã" and v.last_hit < 0.1:
				var c: Vector2 = v.rect().get_center()
				for k in 2:
					var a0 := t * 12.0 + k * PI
					draw_arc(c, 34.0, a0, a0 + 1.0, 6, Color(1, 0.9, 0.5, 0.9), 2.5, true)

# ---------------------------------------------------------------- T01 jato da fornalha
const FOGO_GRAD := [[0.0, Color("#fffbe0")], [0.15, Color("#ffe35a")], [0.38, Color("#ff9a1f")], [0.62, Color("#e8401a")], [0.8, Color("#6b4a44")], [1.0, Color("#8a8a90")]]

static func _fogo_cor(u: float) -> Color:
	for i in range(FOGO_GRAD.size() - 1):
		var a: Array = FOGO_GRAD[i]
		var b: Array = FOGO_GRAD[i + 1]
		if u <= float(b[0]):
			return (a[1] as Color).lerp(b[1], (u - float(a[0])) / (float(b[0]) - float(a[0])))
	return FOGO_GRAD[-1][1]

func _draw_trans_fx() -> void:
	for tf in trans_fx:
		var u: float = tf["t"] / 0.7
		var c: Vector2 = tf["pos"]
		if u < 0.35:   # clarão + raios de luz
			var k := 1.0 - u / 0.35
			for i in 14:
				var ang := i * TAU / 14.0 + u * 2.0
				draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(ang) * 320.0, c + Vector2.from_angle(ang + 0.16) * 320.0]), Color(1, 0.95, 0.7, 0.4 * k))
			draw_circle(c, 60.0 + 200.0 * u, Color(1, 1, 1, 0.65 * k))
		var g: Vector2 = tf["ground"]   # onda de choque achatada no chão
		draw_set_transform(g, 0.0, Vector2(1.0, 0.2))
		draw_arc(Vector2.ZERO, 40.0 + 330.0 * (1.0 - pow(1.0 - u, 3.0)), 0, TAU, 48, Color(1, 1, 1, 1.0 - u), 14.0 * (1.0 - u) + 2.0, true)
		draw_set_transform(Vector2.ZERO)

## T01 lança-chamas (A30): jato de PARTÍCULAS (branco → amarelo → laranja → vermelho → fumaça), núcleo claro, brasas
## caindo, clarão na boca e luz no chão. As partículas vivem em fire_ps (update) e nascem em _update_flame.
func _draw_flames() -> void:
	for pid in flames:
		var fl: Dictionary = flames[pid]
		var r = main.robots[pid]
		var k: float = fl["k"]
		if k <= 0.01 or not r.alive:
			continue
		var o0 := mecha_muzzle(r)
		var fy := _floor_below(o0.x, o0.y, 6)
		if fy > 0.0:   # luz do fogo no chão
			draw_set_transform(Vector2(o0.x + aim_dir(r).x * 120.0, fy), 0.0, Vector2(1.0, 0.18))
			draw_circle(Vector2.ZERO, 150.0, Color(1.0, 0.65, 0.25, 0.22 * k))
			draw_set_transform(Vector2.ZERO)
	# fumaça e fogo velho primeiro, núcleo por cima
	for pass_i in 2:
		for fp in fire_ps:
			var u: float = fp["t"] / fp["life"]
			if fp["em"]:
				if pass_i == 1:
					draw_circle(fp["pos"], 2.6 * (1.0 - u) + 0.8, Color(1.0, 0.82, 0.35, 1.0 - u))
				continue
			if (pass_i == 0) != (u > 0.55):
				continue
			var rad: float = (6.0 + 26.0 * pow(u, 0.8)) * float(fp["s"])
			var col := _fogo_cor(u)
			col.a = pow(1.0 - u, 0.7) * (0.95 if u < 0.75 else 0.5)
			draw_circle(fp["pos"], rad, col)
			if u < 0.4:
				draw_circle(fp["pos"], rad * 0.45, Color(1, 0.99, 0.88, 0.7 * (1.0 - u / 0.4)))
	for pid in flames:
		var fl2: Dictionary = flames[pid]
		var r2 = main.robots[pid]
		if fl2["k"] <= 0.01 or not r2.alive:
			continue
		var o2 := mecha_muzzle(r2)
		var flick := 0.8 + 0.2 * sin(t * 60.0)
		draw_circle(o2, 50.0 * flick, Color(1.0, 0.7, 0.25, 0.3 * fl2["k"]))
		draw_circle(o2, 24.0 * flick, Color(1.0, 0.96, 0.7, 0.85 * fl2["k"]))

# ---------------------------------------------------------------- E01 andaime relâmpago
func _ease_back(u: float) -> float:
	return 1.0 + 2.70158 * pow(u - 1.0, 3) + 1.70158 * pow(u - 1.0, 2)

func _draw_scaffold(p: Dictionary) -> void:
	var pr: Rect2 = p["rect"]
	var k: float = p["k"]
	if k < 0.35:   # a trouxa voa da mão até o lugar
		var u := k / 0.35
		var q: Vector2 = Vector2(p["from"]).lerp(pr.get_center(), u) + Vector2(0, -sin(u * PI) * 50.0)
		draw_set_transform(q, u * TAU * 1.5, Vector2.ONE)
		draw_texture_rect(Data.tex("spells/s10_trouxa"), Rect2(-24, -16, 48, 32), false)
		draw_set_transform(Vector2.ZERO)
		return
	var open := _ease_back(clampf((k - 0.35) / 0.65, 0.0, 1.0))
	var fold_t := 0.35
	if p["t"] < fold_t:   # dobra no fim
		open = clampf(p["t"] / fold_t, 0.0, 1.0)
	var mod := Color.WHITE
	if p["t"] < 1.2 and p["t"] >= fold_t and fmod(t, 0.2) < 0.1:
		mod = Color(1, 0.7, 0.6)   # piscando: vai dobrar
	var wob := sin(t * 40.0) * 1.5 if p["t"] < 1.2 else 0.0
	_draw_scaffold_shape(Rect2(pr.position + Vector2(wob, 0), pr.size), open, p["leg"], mod, false)

## Andaime: tábua central fixa + duas abas que deslizam para os lados, pernas tubulares que giram para baixo.
func _draw_scaffold_shape(pr: Rect2, open: float, leg: float, mod: Color, holo: bool) -> void:
	var tex := Data.tex("spells/s10_tabua")
	var cx := pr.get_center().x
	var y := pr.position.y
	var w := pr.size.x
	var th := 24.0
	var side := w / 3.0
	var slide := side * clampf(open, 0.0, 1.15)
	# pernas (A): giram de deitadas (0) para em pé (1)
	var ang := (1.0 - clampf(open, 0.0, 1.1)) * (PI / 2.0)
	var tube := Color("#71829a") if not holo else mod
	var dark := INK if not holo else Color(mod, mod.a * 0.6)
	for sx in [-1.0, 1.0]:
		var hip := Vector2(cx + sx * (side * 0.5 + slide * 0.55), y + th)
		var dirv := Vector2(sin(ang) * sx, cos(ang))
		var foot := hip + dirv * leg
		var spread := Vector2(dirv.y, -dirv.x) * 12.0
		for q in [hip - spread * 0.4, hip + spread * 0.4]:
			draw_line(q, foot + (q - hip) * 2.2, dark, 9.0, true)
		for q in [hip - spread * 0.4, hip + spread * 0.4]:
			draw_line(q, foot + (q - hip) * 2.2, tube.lightened(0.1) if not holo else mod, 5.0, true)
		if leg > 40.0:   # travessa em X
			var m1 := hip.lerp(foot, 0.3)
			var m2 := hip.lerp(foot, 0.75)
			draw_line(m1 - spread * 0.7, m2 + spread * 1.6, dark, 5.0, true)
			draw_line(m1 + spread * 0.7, m2 - spread * 1.6, dark, 5.0, true)
			draw_line(m1 - spread * 0.7, m2 + spread * 1.6, tube, 2.5, true)
			draw_line(m1 + spread * 0.7, m2 - spread * 1.6, tube, 2.5, true)
		if not holo:
			draw_rect(Rect2(foot + (-spread) * 2.4 - Vector2(4, 3), Vector2(absf(spread.x) * 4.8 + 8, 6)), Color("#4a5566"))
			draw_circle(hip, 5.0, Color("#f2c84b"))
			draw_circle(hip, 2.0, INK)
	# tábua: miolo + abas deslizando (pedaços da textura)
	var tw := float(tex.get_width())
	var thh := float(tex.get_height())
	var src_side := Rect2(0, 0, tw / 3.0, thh)
	var src_mid := Rect2(tw / 3.0, 0, tw / 3.0, thh)
	var src_r := Rect2(tw * 2.0 / 3.0, 0, tw / 3.0, thh)
	draw_texture_rect_region(tex, Rect2(cx - side / 2.0 - slide, y, side, th), src_side, mod)
	draw_texture_rect_region(tex, Rect2(cx + side / 2.0 + slide - side, y, side, th), src_r, mod)
	draw_texture_rect_region(tex, Rect2(cx - side / 2.0, y, side, th), src_mid, mod)

# ---------------------------------------------------------------- C04 mira e teletransporte
func _draw_teleports() -> void:
	var col := Color("#b59cff")
	for pid in aims:
		var a: Dictionary = aims[pid]
		var r = main.robots[pid]
		var c: Color = col if a["ok"] else Color("#ff6a6a")
		# linha pontilhada em arco do robô até o destino
		var p0: Vector2 = r.position + Vector2(0, -40)
		var p1: Vector2 = a["pos"] + Vector2(0, -40)
		var n := 12
		for i in n:
			var u := (i + fposmod(t * 3.0, 1.0)) / n
			var q := p0.lerp(p1, u) + Vector2(0, -sin(u * PI) * 40.0)
			draw_circle(q, 3.0, Color(c, 0.85))
		# anel no chão do destino
		draw_set_transform(a["pos"], 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, 34.0 + 4.0 * sin(t * 8.0), 0, TAU, 24, Color(c, 0.9), 4.0, true)
		draw_set_transform(Vector2.ZERO)
	for e in teles:
		var tt: float = e["t"]
		# saída: coluna de luz afinando até virar fio; chegada: fio engorda e some
		if tt < 0.12:
			var u := tt / 0.12
			_beam(e["a"], 30.0 * (1.0 - u) + 2.0, 1.0 - u * 0.3, col)
		if tt > 0.05 and tt < 0.16:   # risco de luz ligando os dois pontos
			var u := (tt - 0.05) / 0.11
			var a0: Vector2 = e["a"] + Vector2(0, -40)
			var b0: Vector2 = e["b"] + Vector2(0, -40)
			draw_line(a0.lerp(b0, maxf(u - 0.4, 0.0)), a0.lerp(b0, minf(u * 1.4, 1.0)), Color(1, 1, 1, 0.9), 6.0, true)
			draw_line(a0.lerp(b0, maxf(u - 0.4, 0.0)), a0.lerp(b0, minf(u * 1.4, 1.0)), Color(col, 0.8), 12.0, true)
		if tt > 0.09:
			var u := clampf((tt - 0.09) / 0.17, 0.0, 1.0)
			_beam(e["b"], 4.0 + 34.0 * sin(u * PI * 0.5), 1.0 - u, col)
			for k in 6:   # anéis subindo
				var v := fposmod(u + k / 6.0, 1.0)
				draw_set_transform(e["b"] + Vector2(0, -v * 90.0), 0.0, Vector2(1.0, 0.3))
				draw_arc(Vector2.ZERO, 26.0, 0, TAU, 16, Color(col, (1.0 - u) * 0.8), 3.0, true)
				draw_set_transform(Vector2.ZERO)

func _beam(feet: Vector2, w: float, a: float, col: Color) -> void:
	draw_rect(Rect2(feet + Vector2(-w / 2.0 - 6.0, -110), Vector2(w + 12.0, 110)), Color(col, 0.35 * a))
	draw_rect(Rect2(feet + Vector2(-w / 2.0, -104), Vector2(w, 104)), Color(1, 1, 1, 0.85 * a))
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, w + 18.0, Color(col, 0.5 * a))
	draw_set_transform(Vector2.ZERO)

## Silhueta holográfica do robô no destino (o nó "ghost" tem transparência própria).
func _draw_ghost() -> void:
	for pid in aims:
		var a: Dictionary = aims[pid]
		var r = main.robots[pid]
		ghost.material.set_shader_parameter("tint", Color(0.72, 0.6, 1.0, 0.65) if a["ok"] else Color(1.0, 0.4, 0.4, 0.6))
		var pose: Dictionary = RobotVis.idle_pose(t)
		var off := Vector2(0, sin(t * 6.0) * 3.0)
		RobotVis.draw_robot(ghost, r.vis.look(), pose, Transform2D(0.0, Vector2(r.facing, 1.0), 0.0, a["pos"] + off))

# ================================================================ ETAPA 2: ataque
func _hit(o, owner: int, dir: int, kind: String) -> bool:
	if o.pid == owner or not o.alive:
		return false
	var ok: bool = o.take_hit(dir, kind, owner)
	if ok:
		main.impact_fx(o.rect().get_center(), dir, 0.8)
	return ok

## Golpe com direção da mira: lateral pelo sinal; mirado para cima joga mais alto, para baixo crava para baixo.
func _hit_dir(o, owner: int, dirv: Vector2, kind: String) -> bool:
	var dx := int(signf(dirv.x)) if absf(dirv.x) > 0.1 else (1 if o.position.x >= main.robots[owner].position.x else -1)
	var ok := _hit(o, owner, dx, kind)
	if ok:
		if dirv.y < -0.5:
			o.velocity.y -= 260.0
		elif dirv.y > 0.5:
			o.velocity.y = maxf(o.velocity.y, 620.0)
	return ok

func _solid_at(p: Vector2) -> bool:
	return main.level.is_solid(Vector2i(int(floor(p.x / T)), int(floor(p.y / T))))

## Chão sob x a partir de y (procura até n tiles abaixo). -1 = sem chão.
func _floor_below(x: float, y: float, n := 8) -> float:
	var cy := int(floor(y / T))
	for k in n:
		if main.level.is_solid(Vector2i(int(floor(x / T)), cy + k)):
			return (cy + k) * T
	return -1.0

## D03 Para-choque: conta o tempo; acabou → recolhe
func _update_bumper(r, s: Dictionary, dt: float) -> void:
	var bp: Dictionary = bumpers[r.pid]
	bp["t"] += dt
	bp["tranco"] = maxf(float(bp["tranco"]) - dt * 4.0, 0.0)
	for k in bp["cd"].keys():
		bp["cd"][k] -= dt
	s["t"] = maxf(bp["len"] - bp["t"], 0.0)
	r.mola_t = 1.0
	if bp["t"] >= bp["len"] or not r.alive:
		bumpers.erase(r.pid)
		r.mola_t = 0.0
		s["t"] = -1.0
		_spend(r, s)

## D03: um golpe bateu no Para-choque → as molas comprimem e quem bateu (perto) é rebatido para longe
func bumper_rebate(o, by: int) -> void:
	if not bumpers.has(o.pid) or by < 0 or by >= main.robots.size():
		return
	var bp: Dictionary = bumpers[o.pid]
	bp["tranco"] = 1.0
	var a = main.robots[by]
	if bumpers.has(by) or float(bp["cd"].get(by, 0.0)) > 0.0:
		return
	bp["cd"][by] = 0.35
	main.float_text(o.position + Vector2(0, -140), "BOING!", FAM_COR["defesa"])
	Audio.play("pulo_mola", 0.8, 2.0)
	main.shake(6.0)
	if a.alive and a.position.distance_to(o.position) < float(sc("D03")["rebate_raio"]):
		a.take_hit(1 if a.position.x >= o.position.x else -1, "defesa_rebate", o.pid)
		a.hitstop = 0.08
	o.hitstop = 0.06

## D05: o capacete de aço absorveu um golpe/tiro: amassa, faísca; a última proteção faz o capacete voar e acaba
func helmet_absorb(o, by: int) -> void:
	if not helmets.has(o.pid):
		o.capacete_n = 0
		return
	var hm: Dictionary = helmets[o.pid]
	if float(hm["cd"]) > 0.0:
		return   # o mesmo golpe acertando várias vezes conta 1
	hm["cd"] = float(sc("D05")["intervalo_s"])
	hm["tranco"] = 1.0
	o.capacete_n -= 1
	var top: Vector2 = o.position + Vector2(0, -78)
	main.spark(top, 8)
	main.shake(4.0)
	o.hitstop = 0.06
	Audio.play("chave", 0.9 + 0.1 * o.capacete_n, 2.0)
	if o.capacete_n <= 0:
		var dirx: float = 1.0 if by < 0 or by >= main.robots.size() else signf(o.position.x - main.robots[by].position.x + 0.01)
		helmet_fly.append({"pos": top, "vel": Vector2(dirx * 380.0, -620.0), "rot": 0.0, "t": 0.0})
		main.float_text(o.position + Vector2(0, -150), "PLONC!", FAM_COR["defesa"])
		helmets.erase(o.pid)
		o.capacete_n = 0
		if slot.has(o.pid) and slot[o.pid]["id"] == "D05":
			slot[o.pid]["t"] = -1.0
			_spend(o, slot[o.pid])

## D06: posição do boneco de teste de um robô (para os bots mirarem) ou null
func decoy_of(pid: int):
	for d in decoys:
		if d["owner"] == pid and d["morre"] < 0.0:
			return d["pos"]
	return null

## D06: um golpe (hit = área da marretada) pegou o boneco? → estoura em serragem e joga quem bateu
func decoy_hit(r, hit: Rect2, heavy: bool) -> bool:
	for d in decoys:
		if d["morre"] >= 0.0 or d["owner"] == r.pid:
			continue
		if hit.intersects(Rect2(d["pos"] + Vector2(-22, -88), Vector2(44, 88))):
			_decoy_pop(d, r)
			return true
	return false

func _decoy_pop(d: Dictionary, r) -> void:
	d["morre"] = 0.0
	main.float_text(d["pos"] + Vector2(0, -120), "PUF!", FAM_COR["defesa"])
	main.shake(6.0)
	Audio.play("caixote_quebra", 1.2, 0.0)
	for j in 16:
		puffs.append({"pos": d["pos"] + Vector2(randf_range(-26, 26), -randf_range(10, 80)), "vel": Vector2(randf_range(-260, 260), randf_range(-260, 40)),
			"r": randf_range(8, 16), "t": 0.0, "life": randf_range(0.5, 0.9)})
	if r != null and r.alive:
		r.take_hit(1 if r.position.x >= d["pos"].x else -1, "defesa_serragem", d["owner"])

func _update_decoys(dt: float) -> void:
	for d in decoys:
		d["t"] += dt
		if d["morre"] >= 0.0:
			d["morre"] += dt
			continue
		for sh in shots + rivets + springs:   # tiro no boneco também estoura
			if Rect2(d["pos"] + Vector2(-22, -88), Vector2(44, 88)).has_point(sh["pos"]) and sh["owner"] != d["owner"]:
				sh["dead"] = true
				_decoy_pop(d, null)
				break
		if d["t"] >= d["len"] and d["morre"] < 0.0:
			d["morre"] = 0.0
			d["tomba"] = true
	decoys = decoys.filter(func(d): return d["morre"] < 0.7)

## DEFESA: um tiro chegou num robô. Cortina → passa direto (true = ignora); Para-choque → volta com dono novo.
func _intangivel(o) -> bool:
	return o.poeira_t > 0.0

func _rebate_tiro(o, p: Dictionary) -> bool:
	if not bumpers.has(o.pid):
		return false
	p["vel"] = -p["vel"] * 1.1
	p["owner"] = o.pid
	if p.has("hit"):
		p["hit"].clear()
	p["pos"] += p["vel"].normalized() * 30.0
	bumpers[o.pid]["tranco"] = 1.0
	main.spark(p["pos"], 5)
	Audio.play("pulo_mola", 1.4, -2.0)
	return true

## D04 Cortina de Poeira: rasga o saco (rasga_s) → PUF → intocável por duracao_s → assenta
func _update_dust(r, s: Dictionary, dt: float) -> void:
	var d: Dictionary = dusts[r.pid]
	d["t"] += dt
	s["t"] = maxf(d["len"] + d["rasga"] - d["t"], 0.0)
	if not d["puf"]:
		if d["t"] >= d["rasga"]:
			d["puf"] = true
			main.shake(4.0)
			Audio.play("vento", 0.7, 0.0)
			for j in 26:   # nuvem: bolhas de pó na cor do concreto em volta do robô
				var a := randf() * TAU
				d["pts"].append({"o": Vector2(cos(a), sin(a) * 0.8) * randf_range(30, 64), "r": randf_range(12, 24), "ph": randf() * TAU})
		return
	r.poeira_t = 1.0
	if d["t"] >= d["rasga"] + d["len"] or not r.alive:
		dusts.erase(r.pid)
		r.poeira_t = 0.0
		s["t"] = -1.0
		for j in 10:   # assenta: a poeira se espalha baixa
			puffs.append({"pos": r.position + Vector2(randf_range(-50, 50), -randf_range(0, 50)), "vel": Vector2(randf_range(-120, 120), randf_range(-20, 30)),
				"r": randf_range(14, 24), "t": 0.0, "life": randf_range(0.6, 1.0)})
		_spend(r, s)

static func _smoothf(u: float) -> float:
	return u * u * (3.0 - 2.0 * u)

## D01 Âncora de Contrapeso: conta o tempo; caiu do chão (laje sumiu) ou acabou → solta
func _update_anchor(r, s: Dictionary, dt: float) -> void:
	var an: Dictionary = anchors[r.pid]
	an["t"] += dt
	s["t"] = maxf(an["len"] - an["t"], 0.0)
	r.ancora_t = 1.0
	r.spell_speed = float(sc("D01")["vel_mult"]) if an["cravou"] else 0.0
	if not an["cravou"]:
		an["pos"] = r.position + Vector2(-an["fc"] * 34.0, 0)
		if an["t"] >= RobotVis.ANCORA_CRAVA_S:   # BATE no chão: tranco, poeira, rachaduras, lascas
			an["cravou"] = true
			main.shake(9.0)
			main.dust(an["pos"], 1.6)
			Audio.play("caixote_pancada", 0.45, 3.0)
			Audio.play("chave", 0.6, -4.0)
			for j in 8:
				rocks.append({"pos": an["pos"] + Vector2(randf_range(-20, 20), -4), "vel": Vector2(randf_range(-220, 220), randf_range(-420, -160)),
					"t": 0.0, "rot": randf() * TAU, "size": randf_range(3, 7)})
			for j in 6:
				puffs.append({"pos": an["pos"] + Vector2(randf_range(-24, 24), -6), "vel": Vector2(randf_range(-160, 160), randf_range(-90, -20)),
					"r": randf_range(9, 15), "t": 0.0, "life": randf_range(0.4, 0.7)})
		return
	an["tranco"] = maxf(float(an["tranco"]) - dt * 3.0, 0.0)
	if r.last_hit < dt * 1.5:   # levou golpe: a corrente estica e solta faísca, mas ele não sai do lugar
		an["tranco"] = 1.0
		main.spark(r.position.lerp(an["pos"], 0.5) + Vector2(0, -24), 6)
		Audio.play("chave", 0.8, -2.0)
	an["arrasta"] = absf(r.own_vx) > 30.0 and r.is_on_floor()
	if absf(r.position.x - an["pos"].x) > 40.0:   # o contrapeso é ARRASTADO atrás (deixa sulco)
		an["pos"].x = r.position.x - signf(r.position.x - an["pos"].x) * 40.0
		if fmod(an["t"], 0.1) < dt:
			main.dust(an["pos"], 0.35)
			an["sulcos"].append({"x": an["pos"].x, "y": r.position.y, "t": 0.0})
	for sl in an["sulcos"]:
		sl["t"] += dt
	an["sulcos"] = an["sulcos"].filter(func(sl): return sl["t"] < 1.5)
	an["pos"].y = r.position.y
	if an["t"] >= an["len"] or not r.alive or (not r.is_on_floor() and r.velocity.y > 200.0):
		_end_anchor(r)
		s["t"] = -1.0
		_spend(r, s)

func _end_anchor(r) -> void:
	var an: Dictionary = anchors.get(r.pid, {})
	anchors.erase(r.pid)
	r.ancora_t = 0.0
	r.spell_speed = 1.0
	if not an.is_empty():
		sinks.append({"pos": an["pos"], "t": 0.0, "waist": r.position + Vector2(-r.facing * 8.0, -34.0)})
		main.dust(an["pos"], 1.0)
		Audio.play("chave", 1.2, -6.0)

## D02 Airbag de Obra (passivo): 1º arremesso forte (velocidade >= dispara_vel com o robô sem controle) ou caindo no
## vazio → INFLA: corta o voo e desce devagar até o chão; se embaixo for vazio, deriva para o chão mais perto.
func _update_airbag(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("D02")
	if not r.alive:
		airbags.erase(r.pid)
		return
	if not airbags.has(r.pid):
		var spd: float = Vector2(r.own_vx, r.velocity.y).length()
		var vazio: bool = not r.is_on_floor() and r.velocity.y > 300.0 and _floor_below(r.position.x, r.position.y, 7) < 0.0
		var fly: float = float(s.get("voo_t", 0.0))
		fly = fly + dt if (r.last_hit < 1.2 and spd >= float(c["dispara_vel"])) else 0.0   # lançado rápido (no ar OU deslizando) logo após um golpe
		s["voo_t"] = fly
		if fly >= float(c["apos_voo_s"]) or vazio:
			airbags[r.pid] = {"t": 0.0, "alvo_x": _airbag_target_x(r), "pouso": -1.0, "fc": r.facing}
			r.own_vx = 0.0
			r.velocity = Vector2(0, -260.0 if r.is_on_floor() else 0.0)   # no chão: o balão quica para cima e assenta
			main.shake(5.0)
			main.float_text(r.position + Vector2(0, -150), "FUMP!", FAM_COR["defesa"])
			Audio.play("pulo_mola", 0.6, 0.0)
		return
	var ab: Dictionary = airbags[r.pid]
	ab["t"] += dt
	r.stun_t = maxf(r.stun_t, 0.05)
	if ab["pouso"] >= 0.0:   # achatou no chão: segura um instante e murcha
		ab["pouso"] += dt
		r.velocity = Vector2.ZERO
		r.own_vx = 0.0
		if ab["pouso"] >= 0.2:
			airbags.erase(r.pid)
			r.stun_t = 0.0
			pops.append({"pos": r.position + Vector2(0, -38), "t": 0.0})
			Audio.play("vento", 1.6, -6.0)
			_spend(r, s)
		return
	r.velocity.y = minf(r.velocity.y + 400.0 * dt, float(c["desce_vel"]))
	var tx: float = ab["alvo_x"] + sin(ab["t"] * 3.2) * 18.0   # balança ao descer
	r.own_vx = clampf((tx - r.position.x) * 4.0, -float(c["deriva_vel"]), float(c["deriva_vel"])) if absf(tx - r.position.x) > 3.0 else 0.0
	if (r.is_on_floor() and ab["t"] > 0.15) or ab["t"] >= float(c["max_s"]):
		ab["pouso"] = 0.0
		main.dust(r.position, 0.8)
		Audio.play("pulo_mola", 0.9, -4.0)
		return

## Chão mais perto para o airbag pousar: a própria coluna se tem chão embaixo, senão procura dos lados (até 6 tiles).
func _airbag_target_x(r) -> float:
	if _floor_below(r.position.x, r.position.y, 9) >= 0.0:
		return r.position.x
	for k in range(1, 13):
		for sd in [-1.0, 1.0]:
			var x: float = r.position.x + sd * k * T * 0.5
			if _floor_below(x, r.position.y, 9) >= 0.0:
				return x + sd * 20.0
	return r.position.x

## A06 (sessão 6): altura da coluna (0..1) em função de u = tempo/sobe_s: acelera saindo do buraco, passa ~7% do
## ponto em 75% do tempo e assenta (tranco)
func pile_rise(u: float) -> float:
	if u <= 0.0:
		return 0.0
	if u < 0.75:
		var v := u / 0.75
		return 1.07 * (1.0 - pow(1.0 - v, 2.2))
	return lerpf(1.07, 1.0, ease(clampf((u - 0.75) / 0.25, 0.0, 1.0), 0.5))

## A02 (auditoria 2026-11-27): feixe contínuo. Segura = continua (feixe_min_s..feixe_max_s); ▲▼ varre a mira; quem
## toca leva 1 acerto e é ARRASTADO na direção do feixe; andaime/viga/plataforma/tábua/grelha atravessados por
## corte_s são CORTADOS (despencam na hora) e ficam com a marca em brasa.
func _update_beam(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("A02")
	var b: Dictionary = s["beam"]
	b["t"] += dt
	s["fire"] = 0.0   # pose de mira enquanto o feixe sai
	if dt > 0.0:
		_set_aim(r, s, aim_vec(r), float(c["varre_rad_s"]), dt)
	var a := muzzle(r, "A02")
	var dv := aim_dir(r)
	var maxd := float(c["alcance_tiles"]) * T
	var d := 0.0
	while d < maxd and not _hard_at(a + dv * (d + 8.0)):
		d += 8.0
	var bp := a + dv * d
	var e: Dictionary = b["laser"]
	e["a"] = a
	e["b"] = bp
	e["t"] = minf(e["t"], 0.1)   # mantém o feixe cheio
	for o in main.robots:
		if o.pid == r.pid or not o.alive or not _seg_rect(a, bp, o.rect(), 10.0):
			continue
		if not (o.pid in b["hit"]):
			b["hit"].append(o.pid)
			_hit_dir(o, r.pid, dv, "spell_laser")
		elif dt > 0.0 and o.invuln <= 0.0:   # arrastado pelo feixe
			var mx := float(c["arrasto_max"])
			o.own_vx = clampf(o.own_vx + dv.x * float(c["arrasto"]) * dt, -mx, mx)
			o.velocity.y += dv.y * float(c["arrasto"]) * dt
	b["mark"] -= dt
	if d < maxd and b["mark"] <= 0.0:
		scorch.append({"pos": bp, "t": 0.0})
		b["mark"] = 0.06
	var ct = demo.canteiro
	if ct != null and is_instance_valid(ct) and dt > 0.0:
		for p in ct.parts:
			if p["fallen"] or not (p["kind"] in c["corta"]) or p["nucleo"]:
				continue
			var hr: Rect2 = ct.hit_rect(p)
			if not _seg_rect(a, bp, hr, 0.0):
				continue
			var k: int = int(p["idx"]) if p.has("idx") else ct.parts.find(p)
			b["cut"][k] = float(b["cut"].get(k, 0.0)) + dt
			var cp: Vector2 = Geometry2D.get_closest_point_to_segment(hr.get_center(), a, bp)
			if fmod(b["t"], 0.05) < dt:
				main.spark(cp, 2)
			if b["cut"][k] >= float(c["corte_s"]):
				ct.damage(p, 9999, cp)
				if p["crit_t"] > 0.0:
					p["crit_t"] = 0.0
					ct._collapse(p)
				for j in 4:
					scorch.append({"pos": cp + Vector2(randf_range(-6, 6), randf_range(-10, 10)), "t": 0.0})
				Audio.play("serra", 1.4, -6.0)
	var dmin := float(c["feixe_min_s"])
	if dt > 0.0 and (r.stun_t > 0.0 or b["t"] >= float(c["feixe_max_s"]) or (b["t"] >= dmin and not held(r))):
		e["hold"] = false
		s.erase("beam")
		s["fire"] = 0.0
		r.own_vx -= dv.x * 90.0
		_spend(r, s)

## A05 (auditoria 2026-11-27): 3 acertos seguidos de rebite = PREGADO (preso onde está, sem controle) por pino_s.
## Outro golpe solta o pregado (ele voa normalmente).
func _rivet_hit(o, owner: int) -> void:
	var c: Dictionary = sc("A05")
	var rh: Dictionary = rivet_hits.get(o.pid, {"n": 0, "t": 0.0})
	rh["n"] = int(rh["n"]) + 1
	rh["t"] = 0.0
	rivet_hits[o.pid] = rh
	if rh["n"] >= int(c["pino_n"]) and not pinned.has(o.pid):
		rivet_hits.erase(o.pid)
		pinned[o.pid] = {"t": 0.0, "len": float(c["pino_s"]), "pos": o.position, "owner": owner}
		o.velocity = Vector2.ZERO
		o.own_vx = 0.0
		main.float_text(o.position + Vector2(0, -130), "PREGADO!", Color("#ffb24a"))
		Audio.play("pistao", 0.8, 0.0)
		main.shake(5.0)

func _update_pinned(dt: float) -> void:
	for pid in rivet_hits.keys():
		rivet_hits[pid]["t"] += dt
		if rivet_hits[pid]["t"] > float(sc("A05")["pino_janela_s"]):
			rivet_hits.erase(pid)
	for pid in pinned.keys():
		var pn: Dictionary = pinned[pid]
		var o = main.robots[pid] if pid < main.robots.size() else null
		pn["t"] += dt
		if o == null or not o.alive or pn["t"] >= pn["len"] or (pn["t"] > 0.05 and o.last_hit < 0.03):
			pinned.erase(pid)   # acabou ou levou outro golpe: solta (o golpe joga normalmente)
			continue
		o.stun_t = maxf(o.stun_t, 0.05)
		o.velocity = Vector2.ZERO
		o.own_vx = 0.0
		o.position = pn["pos"]

## Disparos com preparo: laser (A02), marreta sísmica (A04), canhão de molas (A08).
func _fire2(r, s: Dictionary) -> void:
	var c: Dictionary = sc(s["id"])
	match s["id"]:
		"A02":   # auditoria 2026-11-27: feixe CONTÍNUO enquanto segura (varre, arrasta, corta) — ver _update_beam
			var e := {"owner": r.pid, "t": 0.0, "a": muzzle(r, "A02"), "b": muzzle(r, "A02"), "hold": true}
			lasers.append(e)
			s["beam"] = {"t": 0.0, "hit": [], "cut": {}, "laser": e, "mark": 0.0}
			_update_beam(r, s, 0.0)
			Audio.play("laser", 1.0, 0.0)
			main.shake(3.0)
		"A04":   # onda pela superfície contínua, para em buracos e paredes
			if not r.is_on_floor():
				_fail(r, "SÓ NO CHÃO")
				s["cd"] = 0.0
				return
			var y: float = r.position.y
			var maxd := float(c["alcance_tiles"]) * T
			var ends := []
			for dir in [-1.0, 1.0]:
				var x: float = r.position.x
				var dd := 0.0
				while dd < maxd:
					var nx: float = r.position.x + dir * (dd + 16.0)
					if not _solid_at(Vector2(nx, y + 8.0)) or _solid_at(Vector2(nx, y - 24.0)):
						break
					dd += 16.0
				ends.append(r.position.x + dir * dd)
			var wv := {"owner": r.pid, "x0": r.position.x, "y": y, "l_end": ends[0], "r_end": ends[1], "t": 0.0, "hit": []}
			waves.append(wv)
			# CRATERA (auditoria 2026-11-27): quem está na área voa longe; as peças da área despencam na hora
			var zr := crater_rect(r)
			for o in main.robots:
				if o.pid != r.pid and o.alive and zr.intersects(o.rect()):
					wv["hit"].append(o.pid)
					_hit(o, r.pid, r.facing, "spell_cratera")
					o.hitstop = 0.1
			var ct = demo.canteiro
			var pe: Vector2 = r.position + Vector2(0, 8)
			if ct != null and is_instance_valid(ct):
				for p in ct.parts:
					if p["fallen"] or not ct.hit_rect(p).intersects(zr) or ct.hit_rect(p).grow(2).has_point(pe):
						continue
					ct.damage(p, 9999, ct.hit_rect(p).get_center())
					if p["crit_t"] > 0.0:   # desaba NO golpe (sem o estado de aviso com fita zebrada)
						p["crit_t"] = 0.0
						ct._collapse(p)
			craters.append({"rect": zr, "t": 0.0})
			for j in 22:   # nuvem de poeira subindo da cratera
				var px := randf_range(zr.position.x, zr.end.x)
				puffs.append({"pos": Vector2(px, y - randf_range(0, 20)), "vel": Vector2(randf_range(-90, 90) + (px - zr.get_center().x) * 0.8, randf_range(-260, -60)),
					"r": randf_range(12, 26), "t": 0.0, "life": randf_range(0.6, 1.1)})
			for j in 14:
				rocks.append({"pos": Vector2(randf_range(zr.position.x, zr.end.x), y - 4.0), "vel": Vector2(randf_range(-240, 240) + r.facing * 100.0, randf_range(-780, -320)),
					"t": 0.0, "rot": randf() * TAU, "size": randf_range(4, 10)})
			main.dust(zr.get_center() + Vector2(0, zr.size.y * 0.3), 2.2)
			r.hitstop = 0.09
			main.shake(18.0)
			Audio.play("terremoto", 1.3, 0.0)
			Audio.play("martelao", 0.8, 0.0)
			main.dust(r.position + Vector2(r.facing * 40.0, 0), 1.4)
			_spend(r, s)
		"A08":   # mola saltitante: primeiro robô leva o BOING
			# 3 ângulos: reto (quica no chão), ▲ arco alto (pega quem está em cima), ▼ no ar (desce na diagonal)
			var av := aim_dir(r)
			var v20 := Vector2(r.facing * float(c["vel"]), -float(c["subida"]))
			if av.y < -0.3:
				v20 = Vector2(r.facing * float(c["vel"]) * 0.55, -float(c["subida"]) * 2.6)
			elif av.y > 0.3:
				v20 = Vector2(r.facing * float(c["vel"]) * 0.6, 420.0)
			var m20 := muzzle(r, "A08")
			m20.y = maxf(m20.y, r.position.y - 42.0)   # sai na altura da cintura (ombro alto de alguns robôs = mola passava por cima)
			springs.append({"owner": r.pid, "pos": m20, "vel": v20, "t": 0.0, "sq": 0.0})
			Audio.play("pulo_mola", 1.3, 2.0)
			r.own_vx -= r.facing * 260.0
			main.shake(4.0)
			_spend(r, s)

## A05: rebite em linha (▲/▼ inclinam 45°), ricocheteia até 2 vezes perdendo força.
func _fire_rivet(r, s: Dictionary) -> void:
	var c: Dictionary = sc("A05")
	var dirv := aim_dir(r)
	rivets.append({"owner": r.pid, "pos": muzzle(r, "A05"), "vel": dirv * float(c["vel"]), "bounces": 0, "t": 0.0, "hit": [], "trail": []})
	s["fire"] = 0.0
	s["burst"] = int(s.get("burst", 1)) - 1
	s["burst_t"] = float(c["rajada_intervalo_s"])
	if s["burst"] <= 0:
		s["cd"] = float(c["intervalo_s"])
	Audio.play("chave", 1.6 + randf() * 0.2, -2.0)
	Audio.play("pistao", 1.9, -10.0)
	tings.append({"pos": muzzle(r, "A05"), "t": 0.0, "big": true})
	r.own_vx -= r.facing * 70.0   # coice a cada tiro
	for k in 2:
		main.spark(muzzle(r, "A05"), 1)

## A06: marca uma faixa à frente (no chão) e a estaca desce lá depois do aviso.
func _pile_floor(r, x: float) -> float:
	var fy := _floor_below(x, r.position.y - 2.0 * T, 9)
	return fy if fy >= 0.0 else r.position.y + 2.0 * T

func _update_pile_aims(dt: float) -> void:
	var c: Dictionary = sc("A06")
	for pid in pile_aims.keys():
		var r = main.robots[pid]
		var a: Dictionary = pile_aims[pid]
		a["t"] += dt
		a["x"] += PlayerInput.axis_x(pid) * float(c["mira_vel"]) * dt
		var off: float = a["x"] - r.position.x
		var maxd := float(c["mira_alcance_tiles"]) * T
		a["x"] = r.position.x + clampf(off, -maxd, maxd)
		if absf(a["x"] - r.position.x) > 20.0:
			r.facing = int(signf(a["x"] - r.position.x))
		r.own_vx *= 0.8
		if not held(r) or a["t"] >= float(c["mira_max_s"]):
			pile_aims.erase(pid)
			r.spell_lock = false
			var s: Dictionary = slot[pid]
			s["channel"] = false
			_drop_pile(r, s, a["x"])

func _drop_pile(r, s: Dictionary, x: float) -> void:
	var c: Dictionary = sc("A06")
	var fy := _floor_below(x, r.position.y - 2.0 * T, 9)
	if fy < 0.0:
		fy = r.position.y + 2.0 * T
	piles.append({"owner": r.pid, "x": x, "floor_y": fy, "t": 0.0, "hit": [], "done": false})
	s["fire"] = 0.0
	Audio.play("alarme", 1.4, -6.0)
	_spend(r, s)

## Escavadeira (A41): a caçamba despeja TERRA em leque: empurra quem está no raio e voa terra; depois a caçamba volta.
func _terra(h: Dictionary, owner, c19: Dictionary) -> void:
	var rad := float(c19["raio_terra_tiles"]) * T
	for o in main.robots:
		if o.pid != h["owner"] and o.alive and o.rect().get_center().distance_to(h["pos"]) < rad:
			_hit_dir(o, h["owner"], Vector2(signf(o.position.x - h["pos"].x) if o.position.x != h["pos"].x else float(h["dir"]), -0.5), "spell_bumerangue")
	for k in 22:
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		rocks.append({"pos": h["pos"], "vel": Vector2.from_angle(a) * randf_range(220, 560), "t": 0.0, "rot": randf() * TAU, "size": randf_range(4, 9), "cor": Color("#8a6a4a")})
	for k in 10:
		puffs.append({"pos": h["pos"] + Vector2(randf_range(-30, 30), randf_range(-10, 10)), "vel": Vector2(randf_range(-200, 200), randf_range(-160, -20)),
			"r": randf_range(14, 24), "t": 0.0, "life": randf_range(0.5, 0.9)})
	main.shake(6.0)
	Audio.play("caixote_quebra", 1.1, -2.0)
	h["phase"] = "volta"
	h["t"] = 0.6
	h["hit"].clear()

## A07 (A41): cada robô arremessa a SUA arma (Data.MODELS): marretao/chave = bumerangue; picareta (Guindaste) = gancho
## na corrente que agarra e PUXA; britadeira (Brita) = crava no chão e VIBRA; pa (Escavadeira) = caçamba espalha TERRA.
func _throw_hammer(r, s: Dictionary) -> void:
	var c: Dictionary = sc("A07")
	var dh := aim_vec(r)
	var kind: String = Data.MODELS[posmod(int(r.vis.model), Data.MODELS.size())]
	var vh: Vector2 = dh * float(c["vel"]) + (Vector2(0, -180.0) if absf(dh.y) < 0.1 else Vector2.ZERO)
	if kind == "picareta":   # gancho: reto e rápido
		vh = dh * float(c["vel"]) * 1.15
	elif kind in ["britadeira", "pa"]:   # pesados: em arco
		vh = dh * float(c["vel"]) * 0.38 + Vector2(0, -330.0 if absf(dh.y) < 0.1 else -200.0)   # cai a ~4 blocos
	hammers.append({"owner": r.pid, "pos": hand(r) + Vector2(0, -10), "vel": vh, "phase": "ida", "kind": kind, "start": hand(r),
		"t": 0.0, "hit": [], "rot": 0.0, "dir": r.facing})
	r.hammer_out = true
	s["fire"] = 0.0
	Audio.play("marreta_vento", 1.0 if kind != "picareta" else 1.5, 0.0)
	_spend(r, s)

func _update_attack2(dt: float) -> void:
	# A02 feixe e marcas de solda
	for e in lasers:
		e["t"] += dt
	lasers = lasers.filter(func(e): return e["t"] < 0.34)
	for e in craters:
		e["t"] += dt
	craters = craters.filter(func(e): return e["t"] < 0.5)
	for e in scorch:
		e["t"] += dt
	scorch = scorch.filter(func(e): return e["t"] < 2.5)
	# A04 onda: a frente anda nas duas direções e acerta quem está apoiado no mesmo trecho
	var c4: Dictionary = sc("A04")
	for w in waves:
		w["t"] += dt
		var front: float = w["t"] * float(c4["vel"])
		for o in main.robots:
			if o.pid == w["owner"] or not o.alive or o.pid in w["hit"] or not o.is_on_floor():
				continue
			if absf(o.position.y - w["y"]) > 6.0:
				continue
			var dx: float = o.position.x - w["x0"]
			var lim: float = (w["r_end"] - w["x0"]) if dx >= 0.0 else (w["x0"] - w["l_end"])
			if front > lim + 80.0:
				continue   # a onda já parou (buraco/parede): não fica acertando quem pousa ali depois
			if absf(dx) <= minf(front, lim) + 20.0 and absf(dx) >= minf(front, lim) - 60.0:
				w["hit"].append(o.pid)
				_hit(o, w["owner"], 1 if dx >= 0.0 else -1, "spell_sismo")
		if fmod(w["t"], 0.04) < dt:
			for dir in [-1.0, 1.0]:
				var lim2: float = (w["r_end"] - w["x0"]) if dir > 0.0 else (w["x0"] - w["l_end"])
				if front < lim2:
					var fx: float = w["x0"] + dir * front
					puffs.append({"pos": Vector2(fx + randf_range(-8, 8), w["y"] - 6.0), "vel": Vector2(dir * randf_range(20, 90), randf_range(-120, -40)),
						"r": randf_range(8, 15), "t": 0.0, "life": randf_range(0.45, 0.7)})
					for j in 2:
						rocks.append({"pos": Vector2(fx + randf_range(-10, 10), w["y"] - 4.0), "vel": Vector2(dir * randf_range(40, 220), randf_range(-520, -260)),
							"t": 0.0, "rot": randf() * TAU, "size": randf_range(4, 9)})
	waves = waves.filter(func(w): return w["t"] < 1.1)
	for rk in rocks:
		rk["t"] += dt
		rk["vel"].y += 1700.0 * dt
		rk["pos"] += rk["vel"] * dt
		rk["rot"] += dt * 10.0
	rocks = rocks.filter(func(rk): return rk["t"] < 0.8)
	for pf in puffs:
		pf["t"] += dt
		pf["vel"] *= 1.0 - 2.2 * dt
		pf["pos"] += pf["vel"] * dt
	puffs = puffs.filter(func(pf): return pf["t"] < pf["life"])
	# A05 rebites
	var c5: Dictionary = sc("A05")
	for rv in rivets:
		rv["t"] += dt
		rv["trail"].push_front(rv["pos"])
		if rv["trail"].size() > 6:
			rv["trail"].pop_back()
		var np: Vector2 = rv["pos"] + rv["vel"] * dt
		if _hard_at(np):
			if rv["bounces"] >= int(c5["ricochetes"]):
				rv["dead"] = true
			else:
				# reflete no eixo que bateu
				var hx := _hard_at(Vector2(np.x, rv["pos"].y))
				var hy := _hard_at(Vector2(rv["pos"].x, np.y))
				if hx or not hy:
					rv["vel"].x = -rv["vel"].x
				if hy:
					rv["vel"].y = -rv["vel"].y
				rv["vel"] *= float(c5["perda"])
				rv["bounces"] += 1
				rv["hit"].clear()
				Audio.play("chave", 2.0 + rv["bounces"] * 0.3, -6.0)
				tings.append({"pos": rv["pos"], "t": 0.0, "big": false})
			main.spark(rv["pos"], 4)
		else:
			rv["pos"] = np
		for o in main.robots:
			if o.pid != rv["owner"] and o.alive and not (o.pid in rv["hit"]) and not _intangivel(o) and o.rect().grow(4).has_point(rv["pos"]):
				if _rebate_tiro(o, rv):
					break
				rv["hit"].append(o.pid)
				if _hit_dir(o, rv["owner"], rv["vel"].normalized(), "spell_rebite"):
					_rivet_hit(o, rv["owner"])
				rv["dead"] = true
		if rv["t"] > float(c5["vida_s"]):
			rv["dead"] = true
	rivets = rivets.filter(func(rv): return not rv.get("dead", false))
	for e in tings:
		e["t"] += dt
	tings = tings.filter(func(e): return e["t"] < 0.18)
	# A06 (A41): aviso (chão treme) → CRAVA a estaca → COLUNA de concreto dispara (lança quem está em cima) → fica de
	# plataforma sólida coluna_s → racha no último segundo e DESABA
	var c17: Dictionary = sc("A06")
	var mark: float = float(c17["marca_s"])
	var colH: float = float(c17["coluna_tiles"]) * T
	var hw17: float = float(c17["largura_tiles"]) * T / 2.0
	var stay17: float = float(c17["coluna_s"])
	for p in piles:
		p["t"] += dt
		var tt: float = p["t"]
		if tt < mark:
			if fmod(tt, 0.1) < dt:
				main.shake(1.5)
			continue
		if not p["done"]:
			p["done"] = true
			var fy: float = p["floor_y"]
			var zona := Rect2(p["x"] - hw17, fy - colH - T, hw17 * 2.0, colH + T)
			p["sobre"] = []   # quem está em cima vai SUBINDO com a coluna e é lançado no fim da subida
			for o in main.robots:
				if o.alive and zona.intersects(o.rect()):
					p["sobre"].append(o.pid)
					if o.pid != p["owner"]:
						_hit(o, p["owner"], 1 if o.position.x >= p["x"] else -1, "spell_estaca")
						o.own_vx *= 0.25   # o golpe não tira de cima: a coluna é que lança
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			var cs := CollisionShape2D.new()
			var shp := RectangleShape2D.new()
			shp.size = Vector2(hw17 * 2.0, 8.0)
			cs.shape = shp
			cs.position = Vector2(p["x"], fy - 4.0)
			body.add_child(cs)
			add_child(body)
			p["body"] = body
			p["shp"] = shp
			p["cs"] = cs
			main.shake(7.0)
			Audio.play("pistao", 0.7, 2.0)
			Audio.play("terremoto", 1.6, -6.0)
			for k in 6:   # o chão estoura na boca do buraco
				rocks.append({"pos": Vector2(p["x"] + randf_range(-hw17, hw17), fy - 4.0), "vel": Vector2(randf_range(-240, 240), randf_range(-520, -200)),
					"t": 0.0, "rot": randf() * TAU, "size": randf_range(4, 8)})
		# sessão 6: a coluna SOBE em sobe_s (sai do buraco, passa um pouco do ponto e assenta com tranco)
		var sobe: float = float(c17["sobe_s"])
		var hgt17: float = colH * pile_rise((tt - mark) / sobe)
		var shp17 = p.get("shp")
		if shp17 != null and not p.get("gone", false) and tt - mark <= sobe + 0.1:
			shp17.size = Vector2(hw17 * 2.0, maxf(hgt17, 8.0))
			p["cs"].position = Vector2(p["x"], p["floor_y"] - maxf(hgt17, 8.0) / 2.0)
		if p.has("sobre") and not p.get("lancou", false) and not p.get("gone", false):
			var u17: float = (tt - mark) / sobe
			for pid in p["sobre"]:
				var o = main.robots[pid]
				if not o.alive:
					continue
				o.position.y = p["floor_y"] - hgt17 - 1.0   # colado no topo enquanto sobe
				o.position.x = clampf(o.position.x, p["x"] - hw17 - 10.0, p["x"] + hw17 + 10.0)
				o.velocity.y = -colH / sobe
				if u17 >= 0.6:
					o.velocity.y = -float(c17["lanca_vel"]) * (1.0 if pid != p["owner"] else 0.8)
			if u17 >= 0.6:
				p["lancou"] = true
		if tt - mark < sobe and fmod(tt, 0.03) < dt:   # poeira subindo junto, dos dois lados
			for sd in [-1.0, 1.0]:
				puffs.append({"pos": Vector2(p["x"] + sd * (hw17 + randf_range(0, 10)), p["floor_y"] - randf_range(0, hgt17 * 0.6)), "vel": Vector2(sd * randf_range(30, 110), randf_range(-160, -40)),
					"r": randf_range(9, 16), "t": 0.0, "life": randf_range(0.5, 0.8)})
		if tt - mark >= sobe * 0.82 and not p.get("assentou", false):   # tranco ao assentar
			p["assentou"] = true
			main.shake(10.0)
			Audio.play("caixote_pancada", 0.55, 0.0)
			for sd in [-1.0, 1.0]:
				for k in 4:
					puffs.append({"pos": Vector2(p["x"] + sd * (hw17 + 6.0), p["floor_y"] - 6.0), "vel": Vector2(sd * randf_range(80, 220), randf_range(-60, -10)),
						"r": randf_range(10, 18), "t": 0.0, "life": randf_range(0.5, 0.9)})
		if tt > mark + float(c17["sobe_s"]) + stay17 and not p.get("gone", false):   # desaba
			p["gone"] = true
			var b17 = p.get("body")
			if b17 != null and is_instance_valid(b17):
				b17.queue_free()
			p["body"] = null
			var fy2: float = p["floor_y"]
			for k in 16:
				rocks.append({"pos": Vector2(p["x"] + randf_range(-hw17, hw17), fy2 - randf_range(0, colH)), "vel": Vector2(randf_range(-220, 220), randf_range(-320, -40)),
					"t": 0.0, "rot": randf() * TAU, "size": randf_range(6, 12)})
			main.dust(Vector2(p["x"], fy2), 1.6)
			main.shake(6.0)
			Audio.play("caixote_quebra", 0.8, 0.0)
	piles = piles.filter(func(p): return p["t"] < mark + float(c17["sobe_s"]) + stay17 + 0.6)
	# A07 (A41): arremesso da arma de cada robô; todos VOLTAM para a mão no fim (fase "volta", atravessa tudo)
	var c19: Dictionary = sc("A07")
	for h in hammers:
		h["t"] += dt
		var owner = main.robots[h["owner"]]
		var kind: String = h.get("kind", "marretao")
		var ph: String = h["phase"]
		if ph == "ida":
			match kind:
				"picareta":   # gancho: vai reto até o alcance; agarrou → PUXA
					h["pos"] += h["vel"] * dt
					h["rot"] = h["vel"].angle()
					if h["pos"].distance_to(h["start"]) > float(c19["alcance_tiles"]) * T or _hard_at(h["pos"]):
						h["phase"] = "volta"
						h["t"] = 0.6
				"britadeira", "pa":   # arco com gravidade até tocar o chão (ou um rival)
					h["vel"].y += 1400.0 * dt
					h["rot"] += dt * 12.0 * h["dir"]
					var np: Vector2 = h["pos"] + h["vel"] * dt
					if (_solid_at(np + Vector2(0, 16)) and h["vel"].y > 0.0) or _hard_at(np):
						if kind == "britadeira":
							h["phase"] = "crava"
							h["pt"] = 0.0
							h["rot"] = 0.0
							h["pos"].y = floor((np.y + 16.0) / T) * T - 18.0
							main.shake(5.0)
							main.dust(h["pos"] + Vector2(0, 18), 1.0)
							Audio.play("furadeira", 0.8, 0.0)
						else:
							_terra(h, owner, c19)
					else:
						h["pos"] = np
				_:   # marreta e chave: bumerangue (freia na ida e volta)
					var dec := float(c19["vel"]) * float(c19["vel"]) / (2.0 * float(c19["alcance_tiles"]) * T)
					h["vel"] = h["vel"].move_toward(Vector2.ZERO, dec * dt)
					h["vel"].y += 260.0 * dt
					h["pos"] += h["vel"] * dt
					h["rot"] += dt * 22.0 * h["dir"]
					if h["vel"].length() < 60.0:
						h["phase"] = "volta"
						h["hit"].clear()
						Audio.play("marreta_vento", 1.3, -2.0)
		elif ph == "puxa":   # Guindaste: traz o rival preso no gancho até perto do dono
			var vic = main.robots[int(h["vic"])]
			var alvo: Vector2 = owner.position + Vector2(owner.facing * 80.0, 0)
			var dv: Vector2 = alvo - vic.position
			if not vic.alive or dv.length() < 30.0 or h["t"] > 1.6:
				if vic.alive:
					_hit(vic, h["owner"], owner.facing, "spell_bumerangue")
				h["phase"] = "volta"
				h["t"] = 0.6
			else:
				vic.position += dv.normalized() * minf(float(c19["puxa_vel"]) * dt, dv.length())
				vic.velocity = Vector2.ZERO
				vic.stun_t = maxf(vic.stun_t, 0.15)
				h["pos"] = vic.rect().get_center()
				if fmod(h["t"], 0.08) < dt:
					main.spark(h["pos"], 1)
		elif ph == "crava":   # Brita: a britadeira crava e VIBRA, empurrando quem está perto a cada pulso
			h["pt"] = float(h["pt"]) + dt
			if fmod(h["pt"], float(c19["pulso_s"])) < dt:
				var rad := float(c19["raio_vibra_tiles"]) * T
				h["ring"] = 0.0
				main.shake(2.5)
				for o in main.robots:
					if o.pid != h["owner"] and o.alive and o.rect().get_center().distance_to(h["pos"]) < rad and o.is_on_floor():
						_hit_dir(o, h["owner"], Vector2(signf(o.position.x - h["pos"].x) if o.position.x != h["pos"].x else 1.0, -0.6), "spell_bumerangue")
				for k in 3:
					rocks.append({"pos": h["pos"] + Vector2(randf_range(-20, 20), 16), "vel": Vector2(randf_range(-200, 200), randf_range(-380, -160)), "t": 0.0, "rot": randf() * TAU, "size": randf_range(3, 6)})
			h["ring"] = float(h.get("ring", 1.0)) + dt * 4.0
			if h["pt"] > float(c19["vibra_s"]):
				h["phase"] = "volta"
				h["t"] = 0.6
		else:   # volta para a mão
			var to: Vector2 = hand(owner) - h["pos"]
			var sp := minf(float(c19["vel"]) * minf(h["t"], 1.6), 1400.0)
			h["pos"] += to.normalized() * minf(sp * dt, to.length())
			h["rot"] += dt * 18.0 * h["dir"]
			if to.length() < 28.0 or h["t"] > float(c19["max_s"]) + 1.6 or not owner.alive:
				h["dead"] = true
				owner.hammer_out = false
				owner.vis.s_sqx[0] = 1.25   # PEGOU: tranco na mão, faíscas e anel
				owner.vis.s_sqy[0] = 0.85
				main.spark(hand(owner), 6)
				main.ring_fx(hand(owner), 0.6)
				Audio.play("chave", 0.8, 0.0)
		if h["phase"] in ["ida", "volta"]:
			for o in main.robots:
				if o.pid != h["owner"] and o.alive and not (o.pid in h["hit"]) and o.rect().grow(22.0 if kind in ["britadeira", "pa"] else 10.0).has_point(h["pos"]):
					h["hit"].append(o.pid)
					if kind == "picareta" and h["phase"] == "ida":   # AGARROU
						h["phase"] = "puxa"
						h["vic"] = o.pid
						h["t"] = 0.0
						main.float_text(o.position + Vector2(0, -120), "PEGOU!", Color("#ffd23a"))
						Audio.play("cola", 1.0, 0.0)
						break
					if kind == "pa" and h["phase"] == "ida":
						_terra(h, owner, c19)
						break
					if kind == "britadeira" and h["phase"] == "ida":   # acertou em cheio: bate e cai cravando ao lado
						_hit(o, h["owner"], int(h["dir"]), "spell_bumerangue")
						h["vel"] = Vector2(-float(h["dir"]) * 120.0, 0.0)
						break
					_hit(o, h["owner"], int(signf(o.position.x - owner.position.x)) if o.position.x != owner.position.x else 1, "spell_bumerangue")
	hammers = hammers.filter(func(h): return not h.get("dead", false))
	# A08 mola saltitante
	var c20: Dictionary = sc("A08")
	for m in springs:
		m["t"] += dt
		m["sq"] = maxf(m["sq"] - dt * 4.0, 0.0)
		m["vel"].y += 1500.0 * dt
		var np: Vector2 = m["pos"] + m["vel"] * dt
		# física da mola (lote 3, refeita): o EIXO acompanha a velocidade girando suave; o comprimento é uma mola amortecida
		# (c = 1 comprimida no voo); o impacto dá um tranco → amassa, passa do ponto e ESTICA (BOING), e assenta.
		var cc: float = float(m.get("c", 1.0))
		var cv: float = float(m.get("cv", 0.0))
		cv += (-900.0 * (cc - 1.0) - 13.0 * cv) * dt
		cc = clampf(cc + cv * dt, 0.35, 3.0)
		m["c"] = cc
		m["cv"] = cv
		if float(m.get("hit_t", -1.0)) >= 0.0:   # acertou: estica TODA, ricocheteia para trás e cai com gravidade
			m["hit_t"] = float(m["hit_t"]) + dt
			m["vel"].y += 1500.0 * dt
			m["pos"] += m["vel"] * dt
			m["ang"] = lerp_angle(float(m["ang"]), m["vel"].angle(), 1.0 - exp(-dt * 5.0))
			if m["hit_t"] > 0.7 or _solid_at(m["pos"] + Vector2(0, 10)):
				m["dead"] = true
				main.dust(m["pos"], 0.4)
			continue
		var alvo_ang: float = m["vel"].angle()
		m["ang"] = lerp_angle(float(m.get("ang", alvo_ang)), alvo_ang, 1.0 - exp(-dt * 12.0))
		if (_hard_at(np + Vector2(0, 14)) or (_solid_at(np + Vector2(0, 14)) and not _solid_at(m["pos"] + Vector2(0, 14)))) and m["vel"].y > 0.0:
			m["vel"].y = -absf(m["vel"].y) * float(c20["quique"])
			m["cv"] = cv - 9.0 * clampf(absf(m["vel"].y) / 500.0, 0.4, 1.2)   # tranco do impacto: amassa e depois estica
			m["sq"] = 1.0
			Audio.play("pulo_mola", 1.6, -8.0)
			main.dust(m["pos"] + Vector2(0, 12), 0.5)
			np = m["pos"]
		if _hard_at(np + Vector2(signf(m["vel"].x) * 16.0, 0)):
			m["dead"] = true   # obstáculo consome o tiro
			main.dust(np, 0.6)
		m["pos"] = np
		for o in main.robots:
			if o.pid != m["owner"] and o.alive and not _intangivel(o) and o.rect().grow(8).has_point(m["pos"]):
				if _rebate_tiro(o, m):
					break
				if _hit(o, m["owner"], int(signf(m["vel"].x)), "spell_mola"):
					main.float_text(o.position + Vector2(0, -120), "BOING!", Color("#ffd23a"))
					o.vis.s_sqx[0] = 0.5
					o.vis.s_sqy[0] = 1.5
					Audio.play("pulo_mola", 0.7, 4.0)
				m["hit_t"] = 0.0   # estica TODA contra o rival (lote 3): tranco forte para esticar, depois ricocheteia
				m["cv"] = float(m.get("cv", 0.0)) + 24.0
				m["ang"] = (o.rect().get_center() - m["pos"]).angle()
				m["vel"] = Vector2(-signf(m["vel"].x) * 160.0, -320.0)
				break
		if m["t"] > float(c20["vida_s"]):
			m["dead"] = true
	springs = springs.filter(func(m): return not m.get("dead", false))

# ---------------------------------------------------------------- desenho da Etapa 2
func _draw_attack2() -> void:
	# A02: linha de mira fina tracejada durante o preparo; lente esquentando
	for r in main.robots:
		if not r.alive or not slot.has(r.pid):
			continue
		var s: Dictionary = slot[r.pid]
		if s["prep"] < 0.0:
			continue
		var k: float = s["prep"] / maxf(s["prep_len"], 0.01)
		match s["id"]:
			"A02":
				var a := muzzle(r, "A02")
				var dv := aim_dir(r)
				var maxd := float(sc("A02")["alcance_tiles"]) * T
				var d := 0.0
				while d < maxd and not _hard_at(a + dv * (d + 8.0)):
					d += 8.0
				var n := int(d / 22.0)
				for i in n:
					var q0: Vector2 = a + dv * (i * 22.0 + fposmod(t * 120.0, 22.0))
					draw_line(q0, q0 + dv * 11.0, Color(1, 0.25, 0.2, 0.35 + 0.5 * k), 2.0, true)
				draw_circle(a, 5.0 + 9.0 * k, Color(1, 0.4, 0.25, 0.4 + 0.4 * k))
				draw_circle(a, 3.0 + 4.0 * k, Color(1, 0.95, 0.8, 0.9))
			"A04":
				pass
			"A08":   # mola comprimindo: anéis apertando na boca
				var m := muzzle(r, "A08")
				var a0 := -PI / 2.0 if r.facing > 0 else PI / 2.0
				for j in 3:
					draw_arc(m, 14.0 + j * 6.0 - 6.0 * k, a0, a0 + PI, 10, Color(1, 1, 1, 0.5 * k), 2.0, true)
	# A04 (auditoria 2026-11-27): marreta sísmica gigante (spells/a04_marreta): arqueia e ergue para trás tremendo,
	# desce num arco com rastro, crava à frente com repique e fica cravada; faixa vermelha marca a cratera no preparo
	var mtex: Texture2D = Data.tex("spells/a04_marreta")
	for r in main.robots:
		if not r.alive or not slot.has(r.pid) or slot[r.pid]["id"] != "A04":
			continue
		var s4: Dictionary = slot[r.pid]
		var ang := 0.0
		var glow := 0.0
		var gp := Vector2(4, -62)
		var smear := -1.0
		if s4["prep"] >= 0.0:
			var k: float = minf(s4["prep"] / maxf(s4["prep_len"], 0.01), 1.0)
			ang = lerpf(0.3, -0.95, ease(k, 0.3)) + (sin(t * 70.0) * 0.05 * k if k > 0.6 else 0.0)
			glow = k
			var zr := crater_rect(r)   # faixa de perigo pulsando onde a cratera vai abrir
			var pa := 0.35 + 0.25 * sin(t * 18.0)
			draw_rect(Rect2(zr.position.x, r.position.y - 4.0, zr.size.x, 10.0), Color(1, 0.23, 0.18, pa * k))
			var nst := int(zr.size.x / 18.0)
			for i in nst:
				var xx: float = zr.position.x + i * 18.0
				draw_line(Vector2(xx, r.position.y + 6.0), Vector2(xx + 10.0, r.position.y - 4.0), Color(1, 0.23, 0.18, 0.9 * k), 2.5, true)
		elif s4["fire"] >= 0.0 and s4["fire"] < 0.55:
			var f: float = s4["fire"]
			if f < 0.06:
				ang = lerpf(-0.95, 1.8, ease(f / 0.06, 0.4))
				smear = f / 0.06
			elif f < 0.14:
				ang = 1.8 - 0.14 * sin((f - 0.06) / 0.08 * PI)
			elif f < 0.42:
				ang = 1.78
			else:
				ang = lerpf(1.78, 1.0, (f - 0.42) / 0.13)
			gp = Vector2(4, -62).lerp(Vector2(24, -20), clampf(f / 0.06, 0.0, 1.0))
			glow = maxf(0.0, 1.0 - f / 0.2)
		else:
			continue
		var grip: Vector2 = r.position + Vector2(r.facing * gp.x, gp.y)
		if smear >= 0.0:   # rastro do arco
			var poly := PackedVector2Array()
			var a0 := -0.95
			var a1 := lerpf(-0.95, 1.8, smear)
			for i in 11:
				var aa: float = lerpf(a0, a1, i / 10.0) * r.facing
				poly.append(grip + Vector2(sin(aa), -cos(aa)) * 100.0)
			for i in range(10, -1, -1):
				var aa: float = lerpf(a0, a1, i / 10.0) * r.facing
				poly.append(grip + Vector2(sin(aa), -cos(aa)) * (100.0 - 46.0 * pow(i / 10.0, 0.6)))
			draw_colored_polygon(poly, Color(1, 1, 1, 0.6))
		var hd := grip + Vector2(sin(ang * r.facing), -cos(ang * r.facing)) * 95.0
		if glow > 0.0:
			draw_circle(hd, 22.0 + 18.0 * glow, Color(1, 0.7, 0.3, 0.35 * glow))
		if mtex != null:
			draw_set_transform(grip, ang * r.facing, Vector2(r.facing * 0.224, 0.224))
			draw_texture(mtex, -Vector2(224, 480))
			draw_set_transform(Vector2.ZERO)
	for e in craters:   # impacto: lampejo curtíssimo na cabeça da marreta + anel de poeira baixo rente ao chão
		var u: float = e["t"] / 0.5
		var c0: Vector2 = Vector2(e["rect"].get_center().x, e["rect"].end.y - 24.0)
		if e["t"] < 0.07:
			draw_circle(c0 + Vector2(0, -14), 46.0 * (1.0 - e["t"] / 0.07), Color(1, 1, 0.95, 0.55))
		draw_set_transform(c0, 0.0, Vector2(1.0, 0.22))
		draw_arc(Vector2.ZERO, 50.0 + 200.0 * u, PI, TAU, 28, Color(0.93, 0.89, 0.81, 0.7 * (1.0 - u)), 22.0 * (1.0 - u) + 4.0, true)
		draw_set_transform(Vector2.ZERO)
	# A02 feixe: dispara da lente até a parede em 0,04 s; tubo de luz com borda tremendo, anéis correndo, clarão na
	# boca e na parede; depois afina de cima para baixo e deixa calor
	for e in lasers:
		var tt: float = e["t"]
		var a: Vector2 = e["a"]
		var full: Vector2 = e["b"]
		var dirv: Vector2 = (full - a).normalized() if full.distance_to(a) > 1.0 else Vector2.RIGHT
		var ang := dirv.angle()
		var reach := clampf(tt / 0.04, 0.0, 1.0)
		var Lfull := a.distance_to(full)
		var L := Lfull * reach
		var b: Vector2 = a + dirv * L
		var thin := clampf((tt - 0.12) / 0.22, 0.0, 1.0)
		var w := 15.0 * (1.0 - thin * thin)
		if w > 0.5:
			var n := maxi(int(L / 18.0), 2)
			draw_set_transform(a, ang)   # quadro do feixe: x ao longo do tiro
			for layer in [[w + 7.0, Color(0.16, 0.1, 0.18, 0.85)], [w + 3.0, Color(0.92, 0.18, 0.16)], [w * 0.7, Color(1, 0.55, 0.25)], [w * 0.34, Color(1, 0.97, 0.85)]]:
				var hw: float = layer[0] / 2.0
				var poly := PackedVector2Array()
				for i in n + 1:
					poly.append(Vector2(L * i / n, -hw - sin(i * 1.7 + tt * 90.0) * hw * 0.18))
				for i in range(n, -1, -1):
					poly.append(Vector2(L * i / n, hw + sin(i * 2.1 + tt * 80.0) * hw * 0.18))
				draw_colored_polygon(poly, layer[1])
			for k in 4:   # anéis de energia correndo pelo feixe
				var u := fposmod(tt * 7.0 + k * 0.25, 1.0)
				draw_set_transform(a + dirv * L * u, ang, Vector2(0.35, 1.0))
				draw_arc(Vector2.ZERO, w * 0.9, 0, TAU, 14, Color(1, 0.95, 0.75, 0.8 * (1.0 - thin)), 2.0, true)
			draw_set_transform(Vector2.ZERO)
		# clarão na lente
		var fl := (1.0 - clampf(tt / 0.2, 0.0, 1.0))
		if fl > 0.0:
			var star := PackedVector2Array()
			for k in 12:
				star.append(a + Vector2.from_angle(k * TAU / 12.0 + tt * 6.0) * ((26.0 if k % 2 == 0 else 10.0) * fl))
			draw_colored_polygon(star, Color(1, 0.9, 0.6, fl))
			draw_circle(a, 8.0 * fl, Color.WHITE)
		# impacto: bola incandescente + faíscas em leque voltando
		if reach >= 1.0 and w > 0.5:
			draw_circle(b, w * 1.3, Color(1, 0.55, 0.25, 0.9))
			draw_circle(b, w * 0.7, Color(1, 0.97, 0.85))
			for k in 6:
				var sa := ang + PI + (k - 2.5) * 0.35
				var ln := 14.0 + fposmod(tt * 80.0 + k * 7.0, 22.0)
				draw_line(b + Vector2.from_angle(sa) * 6.0, b + Vector2.from_angle(sa) * ln, Color(1, 0.85, 0.4, 0.9), 2.0, true)
		# calor subindo depois que o feixe some
		if thin > 0.0:
			for k in 5:
				var q: Vector2 = a + dirv * Lfull * (k + 0.5) / 5.0
				draw_line(q + Vector2(0, -4.0 - thin * 20.0), q + Vector2(sin(tt * 30.0 + k) * 4.0, -14.0 - thin * 30.0), Color(1, 1, 1, 0.35 * (1.0 - thin)), 2.0, true)
	for e in scorch:   # mancha de solda: branca → laranja → escura
		var u: float = e["t"] / 2.5
		var col := Color(1, 0.95, 0.7).lerp(Color(1, 0.45, 0.15), minf(u * 4.0, 1.0)).lerp(Color(0.2, 0.15, 0.15), clampf(u * 2.0 - 0.5, 0.0, 1.0))
		draw_circle(e["pos"], 9.0, Color(col, 1.0 - u))
		if u < 0.4 and fmod(t, 0.08) < 0.04:
			main.spark(e["pos"], 1)
	# A04 impacto (revisto 2026-11-27: "a linha amarela em zigue-zague está artificial"): nada de traço desenhado no
	# chão — poeira na cor do concreto subindo e rolando com a onda, pedaços de concreto com borda escura girando
	for pf in puffs:
		var u: float = pf["t"] / pf["life"]
		var rr: float = pf["r"] * (0.6 + 0.9 * u)
		draw_circle(pf["pos"], rr + 2.0, Color(0.55, 0.48, 0.4, 0.25 * (1.0 - u)))
		draw_circle(pf["pos"], rr, Color(0.93, 0.89, 0.81, 0.85 * (1.0 - u * u)))
		draw_circle(pf["pos"] + Vector2(-rr * 0.25, -rr * 0.3), rr * 0.55, Color(1, 0.98, 0.93, 0.6 * (1.0 - u)))
	for rk in rocks:   # pedaços de concreto: borda escura + face clara (mesmas cores da laje)
		var a: float = clampf((0.8 - rk["t"]) / 0.25, 0.0, 1.0)
		draw_set_transform(rk["pos"], rk["rot"])
		var z: float = rk["size"]
		var pts := PackedVector2Array([Vector2(-z, -z * 0.3), Vector2(-z * 0.2, -z), Vector2(z * 0.9, -z * 0.5), Vector2(z * 0.7, z * 0.6), Vector2(-z * 0.5, z * 0.8)])
		var big := PackedVector2Array()
		for q in pts:
			big.append(q * 1.25)
		draw_colored_polygon(big, Color(0.36, 0.3, 0.26, a))
		var rc: Color = rk.get("cor", Color(0.80, 0.75, 0.65))   # terra da caçamba (A07 Escavadeira) é marrom
		draw_colored_polygon(pts, Color(rc, a) if int(z * 10.0) % 3 != 0 else Color(rc.darkened(0.18), a))
		draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[2], Vector2.ZERO]), Color(rc.lightened(0.15), a))
		draw_set_transform(Vector2.ZERO)
	# DEFESA D01: ergue o contrapeso e crava atrás (rachaduras), corrente até as mãos na cintura (estica e brilha no
	# tranco), arrasta deixando sulcos; no fim a corrente solta e ele afunda
	var ctex: Texture2D = Data.tex("spells/d01_contrapeso")
	for pid in anchors:
		var ro = main.robots[pid]
		var an: Dictionary = anchors[pid]
		var waist: Vector2 = ro.position + Vector2(ro.facing * 4.0, -36.0)
		if not an["cravou"]:   # na mão, fazendo o arco
			var hp: Vector2 = RobotVis.ancora_mao(clampf(an["t"] / RobotVis.ANCORA_CRAVA_S, 0.0, 1.0))
			var hw: Vector2 = ro.position + Vector2(ro.facing * hp.x, hp.y)
			if ctex != null:
				draw_set_transform(hw + Vector2(0, 20), -0.4 * ro.facing * sin(an["t"] / RobotVis.ANCORA_CRAVA_S * PI))
				draw_texture_rect(ctex, Rect2(-26, -46, 52, 52), false)
				draw_set_transform(Vector2.ZERO)
			continue
		var cp: Vector2 = an["pos"]
		var dt0: float = an["t"] - RobotVis.ANCORA_CRAVA_S
		for sl in an["sulcos"]:   # sulcos do arrasto
			draw_line(Vector2(sl["x"] - 10, sl["y"] + 2), Vector2(sl["x"] + 10, sl["y"] + 2), Color(0.42, 0.36, 0.3, 0.7 * (1.0 - sl["t"] / 1.5)), 3.0, true)
		if dt0 < 1.6:   # rachaduras do impacto (cor do concreto escuro)
			var ca := 0.8 * (1.0 - dt0 / 1.6)
			for k in 5:
				var dv := Vector2.from_angle(PI + (k - 2) * 0.32 * (1.0 if k % 2 == 0 else -1.0)) * Vector2(1.0, 0.25)
				draw_polyline(PackedVector2Array([cp + Vector2(0, 2), cp + Vector2(0, 2) + dv * 18.0 + Vector2(0, 2), cp + Vector2(0, 2) + dv * 34.0]), Color(0.32, 0.26, 0.22, ca), 2.5, true)
				draw_polyline(PackedVector2Array([cp + Vector2(0, 2), cp + Vector2(0, 2) + Vector2(-dv.x, dv.y) * 18.0, cp + Vector2(0, 2) + Vector2(-dv.x, dv.y) * 30.0]), Color(0.32, 0.26, 0.22, ca), 2.5, true)
		var tilt: float = (0.14 * signf(ro.position.x - cp.x)) if an["arrasta"] else 0.0
		var top: Vector2 = cp + Vector2(sin(tilt) * 44.0, -44.0)
		var tr: float = an["tranco"]
		var n := int(top.distance_to(waist) / 7.0)
		var sag := 0.0 if an["arrasta"] or tr > 0.0 else 6.0
		for i in n + 1:
			var u := float(i) / maxf(n, 1)
			var q := top.lerp(waist, u) + Vector2(0, sin(u * PI) * sag)
			draw_set_transform(q, (waist - top).angle() + (PI / 2.0 if i % 2 else 0.0), Vector2(1.0, 0.7))
			draw_arc(Vector2.ZERO, 3.6, 0, TAU, 10, INK, 3.0, true)
			draw_arc(Vector2.ZERO, 3.6, 0, TAU, 10, Color("#9aa4ae").lerp(Color.WHITE, tr), 1.4, true)
		draw_set_transform(Vector2.ZERO)
		if ctex != null:
			draw_set_transform(cp + Vector2(0, -2), tilt)
			draw_texture_rect(ctex, Rect2(-26, -44, 52, 52), false)
			draw_set_transform(Vector2.ZERO)
		var left: float = an["len"] - an["t"]
		if left < 1.0 and fmod(t, 0.2) < 0.1:   # piscando: vai soltar
			draw_circle(top, 8.0, Color(1, 1, 1, 0.6))
	for e in sinks:   # fim: elos voando + contrapeso afundando em poeira
		var u: float = e["t"] / 0.8
		if ctex != null:
			draw_texture_rect(ctex, Rect2(e["pos"] - Vector2(26, 44 - 40.0 * u), Vector2(52, 52 * (1.0 - u * 0.8))), false, Color(1, 1, 1, 1.0 - u))
		if e.has("waist"):
			for k in 6:
				var q: Vector2 = e["pos"].lerp(e["waist"], k / 5.0) + Vector2((k - 2.5) * 30.0 * u, -60.0 * u + 160.0 * u * u)
				draw_arc(q, 3.6, 0, TAU, 8, Color(0.6, 0.64, 0.68, 1.0 - u), 2.0, true)
	# DEFESA D02: balão sai da MOCHILA e cresce em volta do robô encolhido, balança descendo, ACHATA no pouso e murcha
	for pid in airbags:
		var ro = main.robots[pid]
		var ab: Dictionary = airbags[pid]
		var k: float = clampf(ab["t"] / 0.15, 0.0, 1.0)
		var back: Vector2 = ro.position + Vector2(-ab["fc"] * 18.0, -36.0)
		var cc: Vector2 = back.lerp(ro.position + Vector2(0, -38), _smoothf(k))
		var rr := 72.0 * (0.25 + 0.75 * _smoothf(k)) * (1.0 + 0.1 * sin(ab["t"] * 22.0) * (1.0 - k))
		var sx := 1.0 + 0.05 * sin(ab["t"] * 5.0)
		var sy := 1.0 - 0.05 * sin(ab["t"] * 5.0)
		if ab["pouso"] >= 0.0:
			var pz: float = sin(clampf(ab["pouso"] / 0.2, 0.0, 1.0) * PI)
			sx = 1.0 + 0.3 * pz
			sy = 1.0 - 0.3 * pz
			cc.y += 72.0 * 0.3 * pz
		draw_set_transform(cc, sin(ab["t"] * 3.2) * 0.08, Vector2(sx, sy))
		draw_circle(Vector2.ZERO, rr, Color(0.98, 0.82, 0.3, 0.38))
		draw_arc(Vector2.ZERO, rr + 1.5, 0, TAU, 40, Color(0.54, 0.42, 0.1, 0.9), 4.0, true)
		draw_line(Vector2(-rr * 0.97, 0), Vector2(rr * 0.97, 0), Color(0.79, 0.6, 0.16, 0.55), 2.0, true)
		draw_arc(Vector2(-rr * 0.2, -rr * 0.25), rr * 0.55, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.75), 5.0, true)
		draw_set_transform(Vector2.ZERO)
		if k < 1.0:   # FUMP: linhas de estouro
			for j in 8:
				var a := j * TAU / 8.0
				draw_line(cc + Vector2.from_angle(a) * (rr + 6.0), cc + Vector2.from_angle(a) * (rr + 26.0), Color(1, 1, 1, 1.0 - k), 3.0, true)
	for e in pops:   # murchando: o pano encolhe tremendo + sopros de ar
		var u: float = e["t"] / 0.5
		var pts := PackedVector2Array()
		for j in 14:
			var a := j * TAU / 14.0
			pts.append(e["pos"] + Vector2.from_angle(a) * (44.0 * (1.0 - u) * (1.0 + 0.25 * sin(j * 2.3 + e["t"] * 40.0))) + Vector2(0, 30.0 * u))
		draw_colored_polygon(pts, Color(0.95, 0.78, 0.29, 0.75 * (1.0 - u)))
		for j in 3:
			draw_arc(e["pos"] + Vector2(34.0 + 12.0 * j, -18.0 - 10.0 * j - 30.0 * u), 6.0, PI, TAU, 8, Color(1, 1, 1, 0.7 * (1.0 - u)), 2.0, true)
	# DEFESA D03: molas com batente em leque em volta do corpo; brotam, comprimem no tranco, recolhem no fim
	for pid in bumpers:
		var ro = main.robots[pid]
		var bp: Dictionary = bumpers[pid]
		var sai: float = _smoothf(clampf(bp["t"] / 0.12, 0.0, 1.0)) * (1.0 - _smoothf(clampf((bp["t"] - bp["len"] + 0.18) / 0.18, 0.0, 1.0)))
		var cc: Vector2 = ro.position + Vector2(0, -40)
		var arm: bool = (fmod(t, 0.24) < 0.12) and float(bp["len"]) - float(bp["t"]) < 0.5
		for i in 7:
			var a := deg_to_rad(-200.0 + i * 220.0 / 6.0)
			var dv := Vector2(cos(a), sin(a))
			var L: float = (18.0 + 30.0 * sai) * (1.0 - 0.5 * float(bp["tranco"])) + sin(t * 30.0 + i) * 1.5
			var p0: Vector2 = cc + dv * Vector2(18, 24)
			var p1: Vector2 = p0 + dv * L
			var nv := dv.orthogonal()
			var pts := PackedVector2Array()
			for j in 11:
				var u := j / 10.0
				pts.append(p0.lerp(p1, u) + nv * (3.4 if j % 2 else -3.4))
			if sai > 0.05:
				draw_polyline(pts, INK, 4.0, true)
				draw_polyline(pts, Color("#9aa4ae"), 2.0, true)
				draw_set_transform(p1, a + PI / 2.0)
				draw_rect(Rect2(-8, -4, 16, 8), INK)
				draw_rect(Rect2(-7, -3, 14, 3.5), Color.WHITE if arm else Color("#f2c84b"))
				draw_rect(Rect2(-7, 0.5, 14, 2.5), Color("#2b2b33"))
				draw_set_transform(Vector2.ZERO)
	# DEFESA D04: saco de cimento rasgando sobre a cabeça → nuvem de pó cor de concreto em volta (robô meio sumido)
	var stex: Texture2D = Data.tex("spells/d04_saco")
	for pid in dusts:
		var ro = main.robots[pid]
		var d: Dictionary = dusts[pid]
		var cc: Vector2 = ro.position + Vector2(0, -42)
		if not d["puf"]:
			var k: float = d["t"] / d["rasga"]
			var sp: Vector2 = ro.position + Vector2(ro.facing * 4.0, -78.0 - 18.0 * k)
			if stex != null:
				draw_set_transform(sp, sin(k * 20.0) * 0.15, Vector2(1.0 + 0.2 * k, 1.0 - 0.15 * k))
				draw_texture_rect(stex, Rect2(-13, -16, 26, 32), false)
				draw_set_transform(Vector2.ZERO)
			for j in int(3 + 5 * k):
				draw_circle(sp + Vector2(sin(j * 2.1) * 12.0, -16.0 - j * 4.0 * k), 3.0 + j, Color(0.93, 0.9, 0.84, 0.8))
			continue
		var u: float = (d["t"] - d["rasga"]) / d["len"]
		var cresce: float = _smoothf(clampf((float(d["t"]) - float(d["rasga"])) / 0.15, 0.0, 1.0))
		var fade: float = 1.0 - _smoothf(clampf((u - 0.8) / 0.2, 0.0, 1.0))
		for bp2 in d["pts"]:
			var q: Vector2 = cc + bp2["o"] * cresce + Vector2(sin(t * 1.7 + bp2["ph"]) * 5.0, cos(t * 1.3 + bp2["ph"]) * 4.0)
			var rr: float = bp2["r"] * (0.5 + 0.5 * cresce)
			draw_circle(q + Vector2(0, 4), rr, Color(0.66, 0.6, 0.48, 0.18 * fade))
			draw_circle(q, rr, Color(0.9, 0.87, 0.8, 0.36 * fade))
		if cresce < 1.0:
			for j in 8:
				var a := j * TAU / 8.0
				draw_line(cc + Vector2.from_angle(a) * (60.0 + 30.0 * cresce), cc + Vector2.from_angle(a) * (80.0 + 40.0 * cresce), Color(1, 1, 1, 1.0 - cresce), 3.0, true)
	# DEFESA D05: capacete voando no fim
	for hf in helmet_fly:
		var htx: Texture2D = Data.tex("spells/d05_capacete2")
		if htx != null:
			draw_set_transform(hf["pos"], hf["rot"])
			draw_texture_rect(htx, Rect2(-32, -20, 64, 32), false, Color(1, 1, 1, clampf(1.2 - hf["t"], 0.0, 1.0)))
			draw_set_transform(Vector2.ZERO)
	# DEFESA D06: boneco de teste balançando (pisca no fim); estoura em serragem ou tomba
	var btx: Texture2D = Data.tex("spells/d06_boneco")
	for d in decoys:
		if btx == null:
			break
		var p0: Vector2 = d["pos"]
		if d["morre"] >= 0.0:
			if d.get("tomba", false):
				var u: float = clampf(d["morre"] / 0.35, 0.0, 1.0)
				draw_set_transform(p0, -d["fc"] * u * u * PI / 2.0, Vector2(d["fc"], 1.0))
				draw_texture_rect(btx, Rect2(-24, -92, 48, 96), false, Color(1, 1, 1, 1.0 - clampf((d["morre"] - 0.4) / 0.3, 0.0, 1.0)))
				draw_set_transform(Vector2.ZERO)
			else:
				var u2: float = d["morre"] / 0.7
				for j in 12:
					var a := j * TAU / 12.0
					var q: Vector2 = p0 + Vector2(0, -44) + Vector2(cos(a), sin(a) * 0.8) * (24.0 + 90.0 * u2) + Vector2(0, 120.0 * u2 * u2)
					draw_set_transform(q, j * 0.7 + u2 * 8.0)
					draw_rect(Rect2(-4, -2, 8, 4), Color(0.85, 0.66, 0.41, 1.0 - u2))
					draw_set_transform(Vector2.ZERO)
			continue
		var wob: float = sin(d["t"] * 4.0) * 0.06 * (1.0 + 2.0 * maxf(0.0, 1.0 - d["t"] / 0.3))
		var pisca: bool = d["len"] - d["t"] < 1.0 and fmod(t, 0.2) < 0.1
		draw_set_transform(p0, wob, Vector2(d["fc"], 1.0))
		draw_texture_rect(btx, Rect2(-24, -92, 48, 96), false, Color(1.6, 1.6, 1.6) if pisca else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
	# A05 rebites: rastro claro, rebite grande (cabeça abaulada dourada + haste de aço) apontando para onde vai
	for rv in rivets:
		var tr: Array = rv["trail"]
		if tr.size() > 1:
			var line := PackedVector2Array([rv["pos"]])
			line.append_array(PackedVector2Array(tr))
			draw_polyline(line, Color(1, 0.85, 0.4, 0.45), 9.0, true)
			draw_polyline(line, Color(1, 1, 0.9, 0.9), 3.5, true)
		draw_set_transform(rv["pos"], rv["vel"].angle())
		draw_rect(Rect2(-16, -4.5, 16, 9), INK)
		draw_rect(Rect2(-15, -3, 14, 6), Color("#c9d1d8"))
		draw_circle(Vector2(2, 0), 13.0, Color(1, 0.55, 0.15, 0.3))   # em brasa: halo laranja
		draw_circle(Vector2(2, 0), 9.0, INK)
		draw_circle(Vector2(2, 0), 7.5, Color("#ff9a2a"))
		draw_circle(Vector2(3, -1.5), 4.0, Color("#ffd27a"))
		draw_circle(Vector2(4, -2.5), 2.0, Color(1, 1, 0.9, 0.95))
		draw_set_transform(Vector2.ZERO)
	for pid in rivet_hits:   # A05: acertos seguidos (pontinhos sobre a cabeça; o 3º prega)
		var ro = main.robots[pid]
		if not ro.alive:
			continue
		var n: int = rivet_hits[pid]["n"]
		var c0: Vector2 = ro.position + Vector2(-16, -112)
		for k in 3:
			draw_circle(c0 + Vector2(k * 16.0, 0), 6.5, INK)
			draw_circle(c0 + Vector2(k * 16.0, 0), 4.8, Color("#ff9a2a") if k < n else Color(0.85, 0.85, 0.85, 0.7))
	for pid in pinned:   # A05 pregado: 3 rebites cravados em volta + estrelas girando + tremidinha
		var ro = main.robots[pid]
		var pn: Dictionary = pinned[pid]
		var fr := 1.0 - clampf(pn["t"] / pn["len"], 0.0, 1.0)
		var cc: Vector2 = ro.position + Vector2(0, -36)
		for k in 3:
			var off := Vector2(-26.0 if k != 1 else 26.0, -24.0 + k * 22.0)
			draw_set_transform(cc + off, 0.0 if off.x < 0.0 else PI)
			draw_rect(Rect2(-4, -2.5, 16, 5), Color("#c9d1d8"))
			draw_circle(Vector2(-4, 0), 7.0, INK)
			draw_circle(Vector2(-4, 0), 5.5, Color("#ff9a2a").lerp(Color("#8a8f99"), 1.0 - fr))
			draw_set_transform(Vector2.ZERO)
		for k in 3:
			var a := t * 7.0 + k * TAU / 3.0
			var sp: Vector2 = ro.position + Vector2(cos(a) * 26.0, -92.0 + sin(a) * 8.0)
			var st := PackedVector2Array()
			for j in 10:
				st.append(sp + Vector2.from_angle(j * TAU / 10.0) * (7.0 if j % 2 == 0 else 3.0))
			draw_colored_polygon(st, Color(1, 0.9, 0.4, 0.9))
	for e in tings:   # estrelinha no ricochete / sopro de ar na boca
		var u: float = e["t"] / 0.18
		var rad := (26.0 if e["big"] else 18.0) * (0.5 + u)
		var star := PackedVector2Array()
		for k in 8:
			star.append(e["pos"] + Vector2.from_angle(k * TAU / 8.0 + 0.4) * (rad if k % 2 == 0 else rad * 0.35))
		draw_colored_polygon(star, Color(1, 0.95, 0.7, 1.0 - u))
		if e["big"]:
			draw_arc(e["pos"], rad * 1.2, 0, TAU, 14, Color(1, 1, 1, 0.6 * (1.0 - u)), 2.0, true)
	# A06 mira: marca andando no chão + coluna tracejada
	var c17a: Dictionary = sc("A06")
	for pid in pile_aims:
		var a17: Dictionary = pile_aims[pid]
		var r17 = main.robots[pid]
		var fy17 := _pile_floor(r17, a17["x"])
		var hw17 := float(c17a["largura_tiles"]) * T / 2.0
		draw_rect(Rect2(a17["x"] - hw17, fy17 - 5.5 * T, hw17 * 2.0, 5.5 * T), Color(1, 0.9, 0.3, 0.1))
		for i in 4:
			var xx: float = a17["x"] - hw17 + i * hw17 * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(xx, fy17 - 4), Vector2(xx + hw17 * 0.25, fy17 - 4), Vector2(xx + hw17 * 0.5, fy17 + 4), Vector2(xx + hw17 * 0.25, fy17 + 4)]), Color(0.95, 0.78, 0.29, 0.9))
		var ay := fy17 - 5.5 * T + 20.0 + absf(sin(t * 6.0)) * 12.0
		draw_colored_polygon(PackedVector2Array([Vector2(a17["x"] - 18, ay), Vector2(a17["x"] + 18, ay), Vector2(a17["x"], ay + 22)]), Color("#f2c84b"))
		draw_polyline(PackedVector2Array([Vector2(a17["x"] - 18, ay), Vector2(a17["x"] + 18, ay), Vector2(a17["x"], ay + 22), Vector2(a17["x"] - 18, ay)]), INK, 3.0, true)
	# A06 (A41): aviso zebrado no chão + fantasma da coluna; depois a COLUNA de concreto (sobe rápido, fica, racha, some)
	var c17: Dictionary = sc("A06")
	var mark := float(c17["marca_s"])
	var colH := float(c17["coluna_tiles"]) * T
	var stay := float(c17["coluna_s"])
	for p in piles:
		var hw := float(c17["largura_tiles"]) * T / 2.0
		var fy: float = p["floor_y"]
		var x: float = p["x"]
		var tt: float = p["t"]
		if tt < mark:
			var k := clampf(tt / mark, 0.0, 1.0)
			var blink := fmod(t, 0.2 - 0.12 * k) < (0.1 - 0.06 * k)
			for i in 4:
				var xx := x - hw + i * hw * 0.5
				draw_colored_polygon(PackedVector2Array([Vector2(xx, fy - 4), Vector2(xx + hw * 0.25, fy - 4), Vector2(xx + hw * 0.5, fy + 4), Vector2(xx + hw * 0.25, fy + 4)]), Color(0.95, 0.78, 0.29, 0.9 if blink else 0.5))
			draw_rect(Rect2(x - hw, fy - colH, hw * 2.0, colH), Color(1, 0.9, 0.3, 0.06 + 0.1 * k))
			draw_rect(Rect2(x - 5, fy - 12 + 6.0 * k, 10, 12), Color("#8e98a4"))   # a estaca entrando
			continue
		if p.get("gone", false):
			continue
		var sobe := float(c17["sobe_s"])
		var rise := clampf((tt - mark) / sobe, 0.0, 1.0)
		var hgt := colH * pile_rise((tt - mark) / sobe)
		var crack := clampf((tt - (mark + sobe + stay - 1.0)) / 1.0, 0.0, 1.0)
		# boca do buraco no chão + rachaduras escuras abrindo a partir da estaca (cor do concreto, não amarelo)
		var ab := clampf((tt - mark) / (sobe * 0.6), 0.0, 1.0)
		var fade := clampf(1.0 - (tt - mark - sobe - 1.5) / 1.0, 0.25, 1.0)
		for sd in [-1.0, 1.0]:
			var pts := PackedVector2Array([Vector2(x + sd * hw, fy)])
			var xx2: float = x + sd * hw
			for i in 4:
				xx2 += sd * (10.0 + 6.0 * i) * ab
				pts.append(Vector2(xx2, fy + (3.0 if i % 2 == 0 else -1.0) * ab))
			draw_polyline(pts, Color(0.32, 0.26, 0.22, 0.85 * fade), 3.0, true)
			draw_line(Vector2(x + sd * (hw + 14.0 * ab), fy + 1), Vector2(x + sd * (hw + 22.0 * ab), fy + 10.0 * ab), Color(0.32, 0.26, 0.22, 0.7 * fade), 2.0, true)
		draw_rect(Rect2(x - hw - 6.0 * ab, fy - 2, hw * 2.0 + 12.0 * ab, 6), Color(0.22, 0.18, 0.16, 0.8 * fade))
		var jx := sin(t * 70.0) * 2.5 * crack
		var top := fy - hgt
		var rr := Rect2(x - hw + jx, top, hw * 2.0, hgt)
		draw_rect(rr.grow(2.0), Color("#8a7a5e"))
		draw_rect(rr, Color("#cdbfa3"))
		draw_rect(Rect2(rr.position, Vector2(rr.size.x, minf(8.0, hgt))), Color("#e3d7bf"))
		if hgt > 24.0:   # faixa zebrada no alto (mais grossa, contornada)
			draw_rect(Rect2(rr.position.x, top + 8, rr.size.x, 14), INK)
			draw_rect(Rect2(rr.position.x + 1, top + 9.5, rr.size.x - 2, 11), Color("#f2c84b"))
			var nz := 5
			for i in nz:
				var xx := rr.position.x + 1 + i * (rr.size.x - 2) / nz
				var wz := (rr.size.x - 2) / nz
				draw_colored_polygon(PackedVector2Array([Vector2(xx, top + 9.5), Vector2(xx + wz * 0.5, top + 9.5), Vector2(xx + wz, top + 20.5), Vector2(xx + wz * 0.5, top + 20.5)]), Color("#2b2233"))
		var yy := top + 34.0
		while yy < fy - 6.0:   # juntas da forma
			draw_line(Vector2(rr.position.x + 5, yy), Vector2(rr.end.x - 5, yy), Color("#a8987a"), 2.0)
			yy += 30.0
		draw_line(Vector2(x - 8 + jx, top), Vector2(x - 8 + jx, top - 8), Color("#8a5a3a"), 2.4)   # ferragem
		draw_line(Vector2(x + 8 + jx, top), Vector2(x + 8 + jx, top - 10), Color("#8a5a3a"), 2.4)
		if crack > 0.0:
			draw_polyline(PackedVector2Array([Vector2(x - 6 + jx, top + 18), Vector2(x + 4 + jx, top + 40), Vector2(x - 4 + jx, top + 66), Vector2(x + 8 + jx, top + 100), Vector2(x + jx, fy - 10)]), Color(0.3, 0.24, 0.2, crack), 3.0, true)
		if rise < 1.0:   # bordas do buraco por cima da base da coluna (ela SAI de dentro do chão)
			draw_rect(Rect2(x - hw - 4, fy - 3, 8, 7), Color("#a8987a"))
			draw_rect(Rect2(x + hw - 4, fy - 3, 8, 7), Color("#a8987a"))
	# A07: voa a FERRAMENTA DO PRÓPRIO ROBÔ (com a skin), girando, com rastro de cópias, arco de energia e faíscas
	for h in hammers:
		var ow = main.robots[h["owner"]]
		var kd: String = h.get("kind", "marretao")
		if kd == "picareta":
			# Guindaste: CORRENTE da mão até o gancho (elos), gancho amarelo na ponta
			var a0: Vector2 = hand(ow)
			var b0: Vector2 = h["pos"]
			var n := int(a0.distance_to(b0) / 10.0)
			for i in n:
				var q: Vector2 = a0.lerp(b0, (i + 0.5) / maxf(n, 1)) + Vector2(0, sin(PI * (i + 0.5) / maxf(n, 1)) * (12.0 if h["phase"] == "volta" else 4.0))
				draw_set_transform(q, (b0 - a0).angle() + (PI / 2.0 if i % 2 else 0.0), Vector2(1.0, 0.7))
				draw_arc(Vector2.ZERO, 4.2, 0, TAU, 10, INK, 3.0, true)
				draw_arc(Vector2.ZERO, 4.2, 0, TAU, 10, Color("#9aa4ae"), 1.4, true)
			draw_set_transform(b0, (b0 - a0).angle())
			draw_rect(Rect2(-8, -7, 14, 14), INK)
			draw_rect(Rect2(-6, -5, 10, 10), Color("#f2c84b"))
			draw_arc(Vector2(10, 6), 9.0, -PI * 0.6, PI * 0.9, 12, INK, 6.0, true)
			draw_arc(Vector2(10, 6), 9.0, -PI * 0.6, PI * 0.9, 12, Color("#c9d1d8"), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			continue
		if kd == "britadeira" and h["phase"] == "crava":   # vibra: treme e solta ondas no chão
			var rg: float = clampf(float(h.get("ring", 1.0)), 0.0, 1.0)
			draw_set_transform(h["pos"] + Vector2(0, 18), 0.0, Vector2(1.0, 0.25))
			draw_arc(Vector2.ZERO, 20.0 + float(sc("A07")["raio_vibra_tiles"]) * T * rg, 0, TAU, 32, Color(1, 1, 1, 1.0 - rg), 8.0, true)
			draw_set_transform(Vector2.ZERO)
			h["rot"] = sin(t * 90.0) * 0.12
		var mname: String = Data.MODELS[posmod(ow.vis.model, Data.MODELS.size())]
		var g: Dictionary = Data.model_meta(ow.vis.model)
		var htx := Data.tex("robo/ferramenta_" + mname + RobotVis._sk(ow.vis.look(), mname))
		var tsz := Vector2(float(g["tool"][0]), float(g["tool"][1])) * 1.25
		for i in 5:
			var aa: float = h["rot"] - (i + 1) * 0.3 * h["dir"]
			draw_set_transform(h["pos"] - h.get("vel", Vector2.ZERO).normalized() * i * 6.0, aa)
			draw_texture_rect(htx, Rect2(-tsz / 2.0, tsz), false, Color(1, 0.8, 0.5, 0.22 - i * 0.04))
		draw_set_transform(h["pos"], h["rot"])
		draw_texture_rect(htx, Rect2(-tsz / 2.0, tsz), false)
		draw_set_transform(Vector2.ZERO)
		var rr := maxf(tsz.y, tsz.x) * 0.55
		draw_arc(h["pos"], rr, h["rot"], h["rot"] + 1.9 * h["dir"], 14, Color(1.0, 0.62, 0.2, 0.75), 5.0, true)
		draw_arc(h["pos"], rr, h["rot"] + PI, h["rot"] + PI + 1.9 * h["dir"], 14, Color(1.0, 0.85, 0.35, 0.55), 3.0, true)
		if fmod(t, 0.06) < 0.02:
			main.spark(h["pos"] + Vector2.from_angle(h["rot"]) * rr, 1)
	# A08 (lote 3): mola de aço em ESPIRAL, eixo na direção do movimento; comprime e estica pela física (c, cv)
	for m in springs:
		var cc: float = float(m.get("c", 1.0))
		var ang: float = float(m.get("ang", m["vel"].angle()))
		if cc > 1.45:
			var bo := clampf((cc - 1.45) / 0.6, 0.0, 1.0)
			Kit.text(self, m["pos"] + Vector2(-60, -76), "BOING!", 18 + int(10.0 * bo), Color("#ffd23a"), HORIZONTAL_ALIGNMENT_CENTER, 120, 5, INK)
		_draw_mola(m["pos"], ang, cc, float(m.get("sq", 0.0)))
		draw_set_transform(Vector2.ZERO)

## Mola em espiral (lote 3, arma C): eixo x local = sentido do movimento (ang); compr 1 = comprimida, >1 esticada, <1 amassada.
## A mola cresce a partir da ARRUELA de trás (o batente vai à frente), como uma mola de verdade.
func _draw_mola(p: Vector2, ang: float, compr: float, wsq := 0.0) -> void:
	# wsq = achatamento NO MUNDO a partir do ponto de contato com o chão (quique): achata na vertical e alarga
	var k := 1.0
	var W := Transform2D.IDENTITY
	if wsq > 0.0:
		var e := sin(wsq * PI * 0.5)
		var piv := p + Vector2(0, 14)
		W = Transform2D(0.0, piv) * Transform2D(0.0, Vector2(1.0 + 0.35 * e, 1.0 - 0.45 * e), 0.0, Vector2.ZERO) * Transform2D(0.0, -piv)
	var L := 26.0 * compr
	var back := -13.0
	var B := W * Transform2D(ang, p) * Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(B)
	var voltas := 4.5
	var n := 54
	var ry := 10.0 * clampf(1.15 - 0.15 * compr, 0.8, 1.1)
	var pts: Array = []
	for i in n + 1:
		var tt := float(i) / n
		var a := tt * voltas * TAU
		pts.append([Vector2(back + L * tt, ry * sin(a)), cos(a) >= 0.0])
	for pass_i in 2:
		var run := PackedVector2Array()
		for i in pts.size():
			var front: bool = pts[i][1]
			if front == (pass_i == 1):
				run.append(pts[i][0])
			if (front != (pass_i == 1) or i == pts.size() - 1) and run.size() > 1:
				if pass_i == 0:
					draw_polyline(run, Color("#5a616c"), 3.4, true)
				else:
					draw_polyline(run, Color("#2b2f38"), 5.6, true)
					draw_polyline(run, Color("#c9d1d8"), 2.0, true)
				run = PackedVector2Array()
			elif front != (pass_i == 1):
				run = PackedVector2Array()
	draw_set_transform_matrix(B * Transform2D(0.0, Vector2(0.28, 1.0), 0.0, Vector2(back - 2.0, 0)))
	draw_circle(Vector2.ZERO, 11.5, Color("#8e98a4"))
	draw_set_transform_matrix(B * Transform2D(0.0, Vector2(back + L + 1.0, 0)))
	var dome := PackedVector2Array()
	for q in 13:
		var a2 := -PI / 2.0 + PI * q / 12.0
		dome.append(Vector2(cos(a2) * 18.0, sin(a2) * 13.0))
	draw_colored_polygon(dome, Color("#e54b3c"))
	draw_polyline(dome, Color("#9a2a22"), 1.6, true)
	draw_line(Vector2(6, -12), Vector2(6, 12), Color("#f2c84b"), 3.0, true)
	draw_arc(Vector2(4, 0), 9.0, -1.2, -0.2, 6, Color("#ff9a8a"), 2.4, true)
	draw_set_transform(Vector2.ZERO)

# ================================================================ ETAPA 3: controle e engenharia
## C02: cone de vento à frente; empurra (sem tirar o controle); o dono anda devagar e sente o recuo.
func _update_fan(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("C02")
	if not held(r) or s["energy"] <= 0.0:
		s["channel"] = false
		r.spell_speed = 1.0
		if s["energy"] <= 0.0:
			s["empty_t"] = 0.35
			Audio.play("ventilador", 1.5, -6.0)
		return
	s["energy"] -= dt
	r.spell_speed = float(c["dono_vel_mult"])
	r.own_vx -= aim_dir(r).x * float(c["recuo"]) * dt * 3.0
	var o0 := muzzle(r, "C02")
	var ad := aim_dir(r)
	var rng := float(c["alcance_tiles"]) * T
	for o in main.robots:
		if o == r or not o.alive or o.invuln > 0.0 or o.god:
			continue
		var oc: Vector2 = o.rect().get_center()
		var dx: float = (oc - o0).dot(ad)
		var side: float = absf((oc - o0).dot(ad.orthogonal()))
		if dx < -10.0 or dx > rng or side > 40.0 + dx * 0.35:
			continue
		var k := 1.0 - 0.5 * dx / rng
		var ev: Vector2 = ext_v.get(o.pid, Vector2.ZERO)
		ev.x = move_toward(ev.x, ad.x * float(c["vel_max"]) * k, float(c["forca"]) * k * dt * 2.0)
		ext_v[o.pid] = ev
		if absf(ad.y) > 0.3:   # soprando para cima levanta; para baixo, empurra para o chão
			o.velocity.y = move_toward(o.velocity.y, ad.y * float(c["vel_max"]) * 1.1 * k, float(c["forca"]) * 1.4 * k * dt)
			o.hanging = false
		o.last_hit = 0.0
		o.last_attacker = r.pid
		o.last_cause = "turboventilador"
	if fmod(t, 0.25) < dt:
		Audio.play("ventilador", 1.1, -8.0)

## C03: garra com corrente (▲ inclina 45°). Parede/plataforma: puxa o dono até lá. Rival: tranco curto para perto.
func _fire_hook(r, s: Dictionary) -> void:
	for h in hooks:
		if h["owner"] == r.pid:
			return
	var c: Dictionary = sc("C03")
	var dirv := aim_dir(r)
	if not r.is_on_floor() and r.velocity.y > 120.0 and not _aim_held(r):
		var auto := _hook_auto(r, float(c["alcance_tiles"]) * T)   # caindo sem mirar: salvamento automático
		if auto != Vector2.ZERO:
			dirv = auto
	hooks.append({"owner": r.pid, "pos": muzzle(r, "C03"), "vel": dirv * float(c["vel"]), "phase": "ida", "t": 0.0, "anchor": Vector2.ZERO, "dir": dirv})
	s["fire"] = 0.0
	Audio.play("gancho", 1.0, 0.0)
	r.own_vx -= dirv.x * 80.0
	_spend(r, s)

## O jogador está mirando (◄►/▲/▼)? Bots: nunca (usam a mira própria).
func _aim_held(r) -> bool:
	if _is_bot(r.pid):
		return true
	return absf(PlayerInput.axis_x(r.pid)) >= 0.4 or PlayerInput.held(r.pid, "up") or PlayerInput.held(r.pid, "down")

## C03 automático (caindo sem mirar): a direção da borda/parede/plataforma agarrável mais perto (nunca para baixo;
## prefere para cima). ZERO = nada ao alcance.
func _hook_auto(r, alcance: float) -> Vector2:
	var o := muzzle(r, "C03")
	var best := Vector2.ZERO
	var bd := 1e9
	for k in 24:
		var dv := Vector2.from_angle(-PI + k * TAU / 24.0)
		if dv.y > 0.3:
			continue
		var d := 24.0
		while d < alcance:
			if _grab_at(o + dv * d):
				var score := d + (0.0 if dv.y < -0.25 else 90.0)
				if score < bd:
					bd = score
					best = dv
				break
			d += 16.0
	return best

## C03 chegou na garra: passa POR CIMA da plataforma/borda agarrada (topo livre na coluna da garra ou na beirada mais
## perto, até 2,5 tiles para o lado). Sessão 6 (pedido do usuário): agarrou EMBAIXO/na quina de uma estrutura alta
## (coluna, beirada de laje, parede) → o robô é jogado para CIMA dela (salva-vidas) — busca o topo até topo_tiles acima.
## Sem topo livre: só o pulinho de antes.
func _hook_finish(owner, an: Vector2) -> void:
	owner.spell_lock = false
	var kmax := int(float(sc("C03")["topo_tiles"]) * T / 8.0)
	for dx in [0.0, 32.0, -32.0, 64.0, -64.0, 96.0, -96.0, 128.0, -128.0, 160.0, -160.0]:
		var x: float = an.x + dx
		var y: float = an.y
		var k := 0
		while k < kmax and _grab_at(Vector2(x, y - 2.0)):
			y -= 8.0
			k += 1
		if k == 0 or k >= kmax:
			continue   # coluna sem estrutura ou alta demais
		y = floor(y / 8.0) * 8.0 + 8.0
		while _grab_at(Vector2(x, y - 1.0)):
			y -= 1.0
		if not _grab_at(Vector2(x, y - 40.0)) and not _grab_at(Vector2(x, y - 70.0)) and y > owner.position.y - float(sc("C03")["topo_tiles"]) * T - 80.0:
			owner.climb_onto(Vector2(x, y - 1.0), 1 if x >= owner.position.x else -1)
			Audio.play("parede", 1.1, -4.0)
			return
	owner.velocity = Vector2(owner.velocity.x * 0.3, -420.0)
	owner.own_vx = owner.velocity.x

func _fire_lasso(r, s: Dictionary) -> void:
	var c: Dictionary = sc("C05")
	var dl := aim_dir(r)
	lassos.append({"owner": r.pid, "pos": muzzle(r, "C05"), "vel": dl * float(c["vel"]), "t": 0.0})
	s["fire"] = 0.0
	Audio.play("arremesso", 1.4, -2.0)
	_spend(r, s)

## E02: 1º toque instala a carga nos pés (pisca na cor do dono); depois de armada, o próximo toque detona.
func _use_charge(r, s: Dictionary) -> void:
	for ch in charges_placed:
		if ch["owner"] == r.pid:
			if ch["armed"]:
				_detonate(ch)
				_spend(r, s)
			else:
				_fail(r, "ARMANDO…")
			return
	# SEMPRE arremessa (2026-11-25): acertou um rival → GRUDA nele; senão gruda na primeira superfície (chão, parede,
	# teto, plataforma). ▲/▼ mudam o arco.
	var av := aim_vec(r)
	var vel := Vector2(r.facing * 640.0, -360.0)
	if absf(av.y) > 0.3:
		vel = av * 760.0 + Vector2(r.facing * 120.0, -120.0)
	charges_placed.append({"owner": r.pid, "pos": hand(r), "t": 0.0, "armed": false, "drop": 1.0, "flying": true, "vel": vel, "rot": 0.0})
	Audio.play("arremesso", 1.2, -2.0)
	s["fire"] = 0.0

func _detonate(ch: Dictionary) -> void:
	var c: Dictionary = sc("E02")
	var p: Vector2 = ch["pos"] + Vector2(0, -16)
	charges_placed.erase(ch)
	demo.booms.append({"pos": p, "t": 0.0})
	main.impact_fx(p, 0, 1.6)
	main.shake(14.0)
	Audio.play("explosao", 1.0, 2.0)
	for k in 10:
		rocks.append({"pos": p + Vector2(randf_range(-20, 20), 0), "vel": Vector2(randf_range(-380, 380), randf_range(-700, -300)), "t": 0.0, "rot": randf() * TAU, "size": randf_range(5, 10)})
	var rad := float(c["raio_tiles"]) * T
	for o in main.robots:
		if o.alive and o.pid != ch["owner"] and o.rect().get_center().distance_to(p) < rad:
			_hit(o, ch["owner"], 1 if o.position.x >= p.x else -1, "spell_carga")
	# lote 3 (auditoria): as peças no raio DESABAM na hora (como a cratera da A04); nunca a que está sob o dono
	var ct = demo.canteiro
	var dono = main.robots[int(ch["owner"])] if int(ch["owner"]) < main.robots.size() else null
	if ct != null and is_instance_valid(ct):
		for pt in ct.parts:
			if pt["fallen"]:
				continue
			var hr: Rect2 = ct.hit_rect(pt)
			var cp: Vector2 = Vector2(clampf(p.x, hr.position.x, hr.end.x), clampf(p.y, hr.position.y, hr.end.y))
			if cp.distance_to(p) > rad * 0.75:
				continue
			if dono != null and dono.alive and hr.grow(2).has_point(dono.position + Vector2(0, 8)):
				continue
			ct.damage(pt, 9999, cp)
			if pt["crit_t"] > 0.0:
				pt["crit_t"] = 0.0
				ct._collapse(pt)
	for j in 18:
		puffs.append({"pos": p + Vector2(randf_range(-40, 40), randf_range(-20, 20)), "vel": Vector2(randf_range(-260, 260), randf_range(-300, -40)),
			"r": randf_range(14, 28), "t": 0.0, "life": randf_range(0.6, 1.1)})

## E03 CONTROLE REMOTO (ampliado 2026-11-25): alvos ao alcance = vigas penduradas (cabo estala e cai), andaimes e
## plataformas sobre estaca (derruba) e as MÁQUINAS da cena (aciona como se marretasse o painel: betoneira despeja,
## bate-estaca bate, gerador desliga, água drena…). Cada alvo: {rect, part} ou {rect, mec}. null = nenhum.
const REMOTE_KINDS := ["viga", "andaime", "estaca"]
func remote_target(r):
	var cands := []
	var maxd := float(sc("E03")["alcance_tiles"]) * T
	var ct = demo.canteiro
	if ct != null and is_instance_valid(ct):
		for p in ct.parts:
			if not (p["kind"] in REMOTE_KINDS) or p["fallen"] or p["crit_t"] > 0.0 or p["evt"] != "" or int(p["etapa"]) != ct.etapa_now():
				continue
			var d: float = p["rect"].get_center().distance_to(r.position)
			if d < maxd:
				cands.append([d, {"rect": p["rect"], "part": p}])
	var mc = demo.mecs
	if mc != null and is_instance_valid(mc):
		for inst in mc.list:
			if not mc._on(inst) or not inst["d"].has("alvo"):
				continue
			var a: Array = inst["d"]["alvo"]
			var ar := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
			var d2: float = ar.get_center().distance_to(r.position)
			if d2 < maxd:
				cands.append([d2, {"rect": ar, "mec": inst}])
	if cands.is_empty():
		return null
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var i := 0
	if slot.has(r.pid):
		i = int(slot[r.pid]["data"].get("tgt_i", 0))
	return cands[posmod(i, cands.size())][1]

func _remote_drop(r, tg: Dictionary) -> void:
	if tg.has("mec"):   # máquina: aciona de longe (o mesmo efeito da marretada no painel, crédito do dono)
		demo.mecs.hammer_hit(tg["rect"], true, r.pid)
		main.spark(tg["rect"].get_center(), 8)
		Audio.play("alarme", 1.4, -4.0)
		return
	var p: Dictionary = tg["part"]
	if p["kind"] != "viga":   # andaime / plataforma: as travas soltam e ela despenca
		demo.canteiro.damage(p, 99, p["rect"].get_center())
		drops.append({"part": p, "owner": r.pid, "t": 0.0, "hit": []})
		Audio.play("alarme", 1.2, -2.0)
		return
	p["hp"] = 0
	p["state"] = 2
	p["crit_t"] = 0.35   # o cabo estala e a viga despenca
	drops.append({"part": p, "owner": r.pid, "t": 0.0, "hit": []})
	Audio.play("alarme", 1.2, -2.0)
	Audio.play("gancho", 0.6, 0.0)

func _update_etapa3(dt: float) -> void:
	# empurrões externos (vento/elástico): somam na velocidade do robô sem brigar com o controle; somem aos poucos
	for pid in ext_v.keys():
		var ev: Vector2 = ext_v[pid]
		if pid < main.robots.size() and main.robots[pid].alive:
			main.robots[pid].push_vx += ev.x
		ev = ev.move_toward(Vector2.ZERO, 900.0 * dt)
		if ev.length() < 1.0:
			ext_v.erase(pid)
		else:
			ext_v[pid] = ev
	var c8: Dictionary = sc("C03")
	for h in hooks:
		h["t"] += dt
		h["snap"] = maxf(float(h.get("snap", 0.0)) - dt * 5.0, 0.0)
		var owner = main.robots[h["owner"]]
		var mz := muzzle(owner, "C03") if slot.has(h["owner"]) and slot[h["owner"]]["id"] == "C03" else hand(owner)
		match h["phase"]:
			"ida":
				var np: Vector2 = h["pos"] + h["vel"] * dt
				# puxa QUASE TUDO: robô, caixa de spell, bomba; estrutura puxa o dono
				var grabbed := false
				for o in main.robots:
					if o.pid != h["owner"] and o.alive and o.rect().grow(10).has_point(np):
						h["phase"] = "reboque"
						h["what"] = o
						grabbed = true
						_hit(o, h["owner"], -1 if o.position.x > owner.position.x else 1, "spell_gancho")
						break
				if not grabbed:
					for bx in boxes:
						if bx["pos"].distance_to(np) < 40.0:
							h["phase"] = "caixa"
							h["what"] = bx
							grabbed = true
							break
				if not grabbed:
					for ch in charges_placed:
						if ch["pos"].distance_to(np) < 34.0:
							h["phase"] = "bomba"
							h["what"] = ch
							grabbed = true
							break
				if grabbed:
					h["snap"] = 1.0
					h["t"] = 0.0
					Audio.play("chave", 0.8, 0.0)
					main.spark(np, 4)
				elif _grab_at(np):
					h["phase"] = "puxa"
					h["anchor"] = h["pos"]
					h["t"] = 0.0
					h["snap"] = 1.0
					owner.spell_lock = true
					Audio.play("chave", 0.9, 0.0)
					main.spark(h["pos"], 5)
				elif h["pos"].distance_to(mz) > float(c8["alcance_tiles"]) * T:
					h["phase"] = "volta"
				else:
					h["pos"] = np
			"puxa":   # o dono voa até a garra
				var to: Vector2 = h["anchor"] - owner.rect().get_center()
				owner.velocity = to.normalized() * float(c8["puxa_vel"])
				owner.own_vx = owner.velocity.x
				owner.hanging = false
				if to.length() < 48.0 or h["t"] > float(c8["puxa_max_s"]) or not owner.alive:
					if owner.alive:
						_hook_finish(owner, h["anchor"])   # passa por cima da plataforma/borda
					else:
						owner.spell_lock = false
					h["dead"] = true
			"reboque":   # o rival vem arrastado até o dono (sem controle) e solta na frente dele
				var o = h["what"]
				var to2: Vector2 = mz - o.rect().get_center()
				h["pos"] = o.rect().get_center()
				if not o.alive or to2.length() < 64.0 or h["t"] > 0.9:
					o.velocity *= 0.3
					o.own_vx *= 0.3
					h["dead"] = true
				else:
					o.velocity = to2.normalized() * float(c8["puxa_vel"]) * 0.9
					o.own_vx = o.velocity.x
					o.stun_t = maxf(o.stun_t, 0.1)
					o.hanging = false
			"caixa", "bomba":   # caixas e bombas vêm voando para a mão
				var it: Dictionary = h["what"]
				var to3: Vector2 = mz - it["pos"]
				it["pos"] += to3.normalized() * minf(1300.0 * dt, to3.length())
				if it.has("vy"):
					it["vy"] = 0.0
				h["pos"] = it["pos"]
				if to3.length() < 30.0 or h["t"] > 1.2:
					if it.has("vy"):
						it["pos"] = owner.position + Vector2(owner.facing * 30.0, -30.0)
					h["dead"] = true
			"volta":
				var to4: Vector2 = mz - h["pos"]
				h["pos"] += to4.normalized() * minf(1800.0 * dt, to4.length())
				if to4.length() < 20.0:
					h["dead"] = true
	hooks = hooks.filter(func(h): return not h.get("dead", false))
	# C05 laço: tiro → elástico entre os dois
	var c21: Dictionary = sc("C05")
	for l in lassos:
		l["t"] += dt
		l["pos"] += l["vel"] * dt   # esfera de energia: voa reto
		for o in main.robots:
			if o.pid != l["owner"] and o.alive and o.invuln <= 0.0 and o.rect().grow(8).has_point(l["pos"]):
				tethers.append({"a": l["owner"], "b": o.pid, "t": 0.0})
				tings.append({"pos": l["pos"], "t": 0.0, "big": true})
				o.vis.s_sqx[0] = 0.8
				o.vis.s_sqy[0] = 1.15
				l["dead"] = true
				main.float_text(o.position + Vector2(0, -120), "PRESO!", Color("#3fc1c9"))
				Audio.play("pulo_mola", 1.4, -2.0)
				break
		if _hard_at(l["pos"]) or l["t"] > float(c21["alcance_tiles"]) * T / float(c21["vel"]):
			l["dead"] = true
	lassos = lassos.filter(func(l): return not l.get("dead", false))
	for e in tethers:
		e["t"] += dt
		var a = main.robots[e["a"]]
		var b = main.robots[e["b"]]
		if not a.alive or not b.alive or e["t"] > float(c21["duracao_s"]):
			e["dead"] = true
			snaps.append({"a": a.rect().get_center(), "b": b.rect().get_center(), "t": 0.0})
			Audio.play("pulo_mola", 2.0, -6.0)
			continue
		var d: Vector2 = b.rect().get_center() - a.rect().get_center()
		var over: float = d.length() - float(c21["folga_tiles"]) * T
		if over > 0.0:   # esticou: puxa os DOIS um para o outro (ninguém controla o outro)
			var k := clampf(over / T, 0.0, 2.0)
			var u := d.normalized()
			for pair in [[a, u], [b, -u]]:
				var rob = pair[0]
				var dirv: Vector2 = pair[1]
				var ev: Vector2 = ext_v.get(rob.pid, Vector2.ZERO)
				ev.x = move_toward(ev.x, dirv.x * 560.0 * k, float(c21["forca"]) * dt)
				ext_v[rob.pid] = ev
				rob.velocity.y = move_toward(rob.velocity.y, dirv.y * 400.0 * k, float(c21["forca"]) * 0.6 * dt)
	tethers = tethers.filter(func(e): return not e.get("dead", false))
	for e in snaps:
		e["t"] += dt
	snaps = snaps.filter(func(e): return e["t"] < 0.18)
	# E02 cargas
	var c12: Dictionary = sc("E02")
	for ch in charges_placed.duplicate():
		if ch.get("flying", false):
			ch["vel"].y += 1400.0 * dt
			ch["rot"] += dt * 12.0
			var np: Vector2 = ch["pos"] + ch["vel"] * dt
			var hit_r = null
			for o in main.robots:
				if o.alive and o.pid != ch["owner"] and o.rect().grow(8).has_point(np):
					hit_r = o
					break
			if hit_r != null:   # grudou no rival: vai junto com ele até explodir
				ch["flying"] = false
				ch["on"] = hit_r.pid
				ch["off"] = np - hit_r.position
				ch["t"] = 0.0
				ch["rot"] = 0.0
				main.float_text(hit_r.position + Vector2(0, -120), "GRUDOU!", Color("#ff8a6a"))
				Audio.play("cola", 1.2, 0.0)
				main.spark(np, 4)
			elif _grab_at(np):
				ch["flying"] = false
				ch["t"] = 0.0
				ch["rot"] = 0.0
				Audio.play("alavanca", 1.6, -4.0)
				main.spark(np, 3)
			else:
				ch["pos"] = np
				if ch["pos"].y > main.level.rows * T + 300.0:
					ch["flying"] = false   # caiu no abismo: explode lá embaixo quando der o tempo
			continue
		if ch.has("on"):   # presa num robô: acompanha; se ele cair/eliminar, a carga despenca no lugar
			var o2 = main.robots[int(ch["on"])]
			if o2.alive:
				ch["pos"] = o2.position + Vector2(o2.facing * absf(ch["off"].x) * 0.6, ch["off"].y)
			else:
				ch.erase("on")
				ch["flying"] = true
				ch["vel"] = Vector2.ZERO
		ch["t"] += dt
		ch["drop"] = minf(ch["drop"] + dt / 0.2, 1.0)
		if not ch["armed"] and ch["t"] >= float(c12["arma_s"]):
			ch["armed"] = true
			Audio.play("alarme", 1.8, -8.0)
		var beep: float = lerpf(0.5, 0.07, clampf(ch["t"] / float(c12["auto_s"]), 0.0, 1.0))   # bipe ACELERA
		ch["bt"] = float(ch.get("bt", 0.0)) + dt
		if ch["bt"] >= beep:
			ch["bt"] = 0.0
			ch["blink"] = 0.06
			Audio.play("menu_mover", 2.0 + ch["t"] * 0.15, -10.0)
		ch["blink"] = maxf(float(ch.get("blink", 0.0)) - dt, 0.0)
		if ch["t"] >= float(c12["auto_s"]):
			var ow: int = ch["owner"]
			_detonate(ch)
			if slot.has(ow) and slot[ow]["id"] == "E02":
				_spend(main.robots[ow], slot[ow])
	# E03 viga despencando: acerta quem estiver embaixo
	for e in drops:
		e["t"] += dt
		var p: Dictionary = e["part"]
		if p["fallen"]:
			var col := Rect2(p["rect"].position.x, p["rect"].position.y, p["rect"].size.x, 5.0 * T)
			for o in main.robots:
				if o.alive and not (o.pid in e["hit"]) and col.intersects(o.rect()) and e["t"] < 1.4:
					e["hit"].append(o.pid)
					var dx := 1 if o.position.x >= p["rect"].get_center().x else -1
					o.take_hit(dx, "spell_viga", e["owner"]) if o.pid != e["owner"] else null
	drops = drops.filter(func(e): return e["t"] < 1.6)
# ---------------------------------------------------------------- desenho da Etapa 3
func _draw_etapa3() -> void:
	# C02 vento: riscos correndo no cone, poeira e hélice borrada
	for r in main.robots:
		if not r.alive or not slot.has(r.pid) or slot[r.pid]["id"] != "C02" or not slot[r.pid]["channel"]:
			continue
		var ow := muzzle(r, "C02")
		var adw := aim_dir(r)
		var rng := float(sc("C02")["alcance_tiles"]) * T
		if fmod(t, 0.06) < 0.02:
			var gp := ow + adw * randf_range(60, rng)
			main.dust(Vector2(gp.x, r.position.y) if absf(adw.y) < 0.3 else gp, 0.4)
		# tudo no quadro do vento (x = direção da mira)
		draw_set_transform(ow, adw.angle(), Vector2(1.0, -1.0 if adw.x < -0.1 else 1.0))
		var o := Vector2.ZERO
		var d := 1.0
		# cone de ar claro + rajadas em espiral (contorno escuro fino para ler sobre qualquer fundo) + poeira
		var cone := PackedVector2Array([o + Vector2(0, -16), o + Vector2(d * rng, -40.0 - rng * 0.35), o + Vector2(d * rng, 40.0 + rng * 0.35), o + Vector2(0, 16)])
		draw_colored_polygon(cone, Color(1, 1, 1, 0.12))
		for i in 9:
			var u := fposmod(t * 2.2 + i * 0.111, 1.0)
			var dx := rng * u
			var spread := 26.0 + dx * 0.3
			var yy := o.y + sin(i * 2.3) * spread
			var x0 := o.x + d * dx
			var pts := PackedVector2Array()
			for j in 9:   # risco ondulado que termina num caracol
				var v := float(j) / 8.0
				if v < 0.7:
					pts.append(Vector2(x0 + d * v * 70.0, yy + sin(v * 7.0 + t * 10.0) * 4.0))
				else:
					var ca := (v - 0.7) / 0.3 * PI * 1.5
					pts.append(Vector2(x0 + d * (49.0 + sin(ca) * 10.0), yy - 10.0 + cos(ca) * 10.0))
			var al := sin(u * PI)
			draw_polyline(pts, Color(0.16, 0.1, 0.18, 0.35 * al), 6.0, true)
			draw_polyline(pts, Color(1, 1, 1, 0.95 * al), 3.0, true)
		for i in 4:   # anéis de pressão correndo no cone
			var u := fposmod(t * 2.8 + i * 0.25, 1.0)
			var dx := rng * u
			var hh := 22.0 + dx * 0.33
			draw_set_transform(ow + adw * dx, adw.angle(), Vector2(0.28, 1.0))
			draw_arc(Vector2.ZERO, hh, 0, TAU, 20, Color(1, 1, 1, 0.55 * (1.0 - u)), 3.0, true)
		draw_set_transform(ow, adw.angle(), Vector2(1.0, -1.0 if adw.x < -0.1 else 1.0))
		for i in 7:   # sucata e folhas voando junto
			var u := fposmod(t * 1.9 + i * 0.143, 1.0)
			var q := Vector2(rng * u, sin(i * 2.7 + t * 5.0) * (18.0 + rng * u * 0.25))
			draw_set_transform(ow + (q.rotated(adw.angle()) if adw.x >= -0.1 else Vector2(q.x, -q.y).rotated(adw.angle())), t * 12.0 + i)
			if i % 2 == 0:
				draw_rect(Rect2(-4, -2, 8, 4), Color(0.6, 0.65, 0.7, 1.0 - u))
			else:
				draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)]), Color(0.55, 0.75, 0.35, 1.0 - u))
		draw_set_transform(ow, adw.angle(), Vector2(1.0, -1.0 if adw.x < -0.1 else 1.0))
		# hélice: disco borrado + 3 pás girando rápido (vistas de lado: achatadas)
		draw_set_transform_matrix(Transform2D(adw.angle(), Vector2(1.0, -1.0 if adw.x < -0.1 else 1.0), 0.0, ow) * Transform2D(0.0, Vector2(0.3, 1.0), 0.0, Vector2(-10, 0)))
		draw_circle(Vector2.ZERO, 18.0, Color(1, 1, 1, 0.25))
		for k in 3:
			var ba := t * 45.0 + k * TAU / 3.0
			draw_line(Vector2.ZERO, Vector2.from_angle(ba) * 17.0, Color(0.85, 0.9, 0.95, 0.85), 5.0, true)
		draw_set_transform(Vector2.ZERO)
		if fmod(t, 0.1) < 0.02:   # o dono escorrega para trás: poeira nos pés
			main.dust(r.position + Vector2(-r.facing * 10.0, 0), 0.35)
		for v in main.robots:   # quem está no vento tremula
			if v != r and v.alive and v.last_cause == "turboventilador" and v.last_hit < 0.05:
				v.vis.s_sqx[0] = 1.0 + randf_range(-0.06, 0.06)
				v.vis.s_sqy[0] = 1.0 + randf_range(-0.05, 0.05)
	# C03 corrente de elos (ovais alternados, com barriga enquanto sai) + garra de 3 dentes que abre em voo e fecha ao pegar
	for h in hooks:
		var owner = main.robots[h["owner"]]
		var a := muzzle(owner, "C03") if slot.has(h["owner"]) and slot[h["owner"]]["id"] == "C03" else hand(owner)
		var b: Vector2 = h["pos"]
		var L := a.distance_to(b)
		var dirv := (b - a).normalized() if L > 1.0 else Vector2(owner.facing, 0)
		var sag := 18.0 if h["phase"] == "ida" else (sin(t * 60.0) * 2.0 if h["phase"] in ["puxa", "reboque", "caixa", "bomba"] else 8.0)
		var n := maxi(int(L / 11.0), 1)
		for i in n:
			var u := (i + 0.5) / n
			var q := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag)
			var ang := dirv.angle()
			if i % 2 == 0:
				draw_set_transform(q, ang)
				draw_arc(Vector2.ZERO, 6.5, 0, TAU, 12, INK, 4.5, true)
				draw_set_transform(q, ang, Vector2(1.0, 0.6))
				draw_arc(Vector2.ZERO, 6.5, 0, TAU, 12, Color("#c9d1d8"), 2.4, true)
			else:
				draw_set_transform(q, ang, Vector2(1.0, 0.35))
				draw_arc(Vector2.ZERO, 6.5, 0, TAU, 12, INK, 4.0, true)
				draw_arc(Vector2.ZERO, 6.5, 0, TAU, 12, Color("#8e9aa6"), 2.0, true)
		draw_set_transform(Vector2.ZERO)
		var open: float = 0.75 if h["phase"] == "ida" or h["phase"] == "volta" else 0.12
		var hang := dirv.angle()
		draw_set_transform(b, hang, Vector2(1.0 + 0.3 * h.get("snap", 0.0), 1.0))
		for k in 3:   # dentes curvos
			var side := float(k - 1)
			var spread := side * open * 0.9
			var tip := Vector2(22, 0).rotated(spread) + Vector2(0, side * 4.0)
			var mid := Vector2(10, side * 8.0 * open + side * 2.0)
			var hook := tip + Vector2(-6, -side * 6.0) if k != 1 else tip + Vector2(2, 0)
			for pass_i in 2:
				var w := 7.0 if pass_i == 0 else 3.5
				var col := INK if pass_i == 0 else Color("#e0e6ea")
				draw_polyline(PackedVector2Array([Vector2.ZERO, mid, tip, hook]), col, w, true)
		draw_circle(Vector2.ZERO, 8.0, INK)
		draw_circle(Vector2.ZERO, 6.0, Color("#8a63d2"))
		draw_circle(Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.7))
		draw_set_transform(Vector2.ZERO)
		if h.get("snap", 0.0) > 0.0:   # estalo ao fechar
			var u: float = 1.0 - h["snap"]
			draw_arc(b, 14.0 + 22.0 * u, 0, TAU, 16, Color(1, 1, 1, 1.0 - u), 3.0, true)
	# C05 laço de energia: esfera elétrica com rastro; acertou → algema de energia em cada robô e um raio entre eles
	# (frouxo: ondula; esticado: mais grosso, mais claro e estalando); soltou → descarga nas duas pontas
	var c21: Dictionary = sc("C05")
	for l in lassos:
		var p: Vector2 = l["pos"]
		var dv: Vector2 = l["vel"].normalized()
		for k in 5:   # rastro elétrico
			draw_circle(p - dv * (10.0 + k * 10.0), 9.0 - k * 1.5, Color(0.25, 0.76, 0.79, 0.45 - k * 0.08))
		_draw_bolt(p - dv * 54.0, p, 0.3, 4.0, l["t"])
		draw_circle(p, 15.0, Color(0.54, 0.39, 0.82, 0.35))
		draw_circle(p, 11.0, Color("#3fc1c9"))
		draw_circle(p, 6.5, Color("#bff6ff"))
		draw_circle(p, 3.0, Color.WHITE)
		for k in 3:   # arquinhos estalando em volta
			var a0 := t * 9.0 + k * TAU / 3.0
			_draw_bolt(p + Vector2.from_angle(a0) * 8.0, p + Vector2.from_angle(a0 + 0.6) * 20.0, 0.0, 3.0, t + k)
	for e in tethers:
		var ra = main.robots[e["a"]]
		var rb = main.robots[e["b"]]
		var pa: Vector2 = ra.rect().get_center()
		var pb: Vector2 = rb.rect().get_center()
		var folga := float(c21["folga_tiles"]) * T
		var dist := pa.distance_to(pb)
		var stretch := clampf((dist - folga) / (2.0 * T), 0.0, 1.0)
		var left: float = float(c21["duracao_s"]) - e["t"]
		var flick := 0.55 if left < 0.8 and fmod(t, 0.16) < 0.08 else 1.0
		var slack := maxf(folga - dist, 0.0) * 0.35
		_draw_bolt(pa, pb, stretch, slack, e["t"], flick)
		for q in [pa, pb]:   # algema de energia: anel achatado girando + nós de faísca
			draw_set_transform(q, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 30.0, 0, TAU, 24, Color(0.25, 0.76, 0.79, 0.5 * flick), 7.0, true)
			draw_arc(Vector2.ZERO, 30.0, 0, TAU, 24, Color(0.75, 0.96, 1.0, 0.9 * flick), 2.5, true)
			draw_set_transform(Vector2.ZERO)
			for k in 3:
				var a1 := t * (6.0 + stretch * 6.0) + k * TAU / 3.0
				draw_circle(q + Vector2(cos(a1) * 30.0, sin(a1) * 13.5), 3.5, Color(1, 1, 1, flick))
	for e in snaps:   # soltou: descarga nas pontas
		var u: float = e["t"] / 0.18
		for q in [e["a"], e["b"]]:
			draw_circle(q, 10.0 + 30.0 * u, Color(0.75, 0.96, 1.0, 0.8 * (1.0 - u)))
			for k in 5:
				var a2 := k * TAU / 5.0 + u
				_draw_bolt(q, q + Vector2.from_angle(a2) * (16.0 + 26.0 * u), 0.0, 4.0, t + k, 1.0 - u)
	# E02 cargas: cai e gruda, luz pisca na cor do dono (mais rápido perto de explodir), círculo de alcance quando armada
	var c12: Dictionary = sc("E02")
	var ctex := Data.tex("spells/s12_carga")
	for ch in charges_placed:   # lote 3: dinamite com detonador de antena; luz pisca a cada bipe; anel da contagem
		var p: Vector2 = ch["pos"]
		var drop: float = ch["drop"]
		var sq := 1.0 + 0.25 * sin(drop * PI) if drop < 1.0 else 1.0
		draw_set_transform(p + Vector2(0, -24.0 * (1.0 - drop)), float(ch.get("rot", 0.0)), Vector2(sq, 2.0 - sq))
		draw_texture_rect(ctex, Rect2(-17.6, -49.6, 35.2, 51.2), false)
		var on: bool = float(ch.get("blink", 0.0)) > 0.0
		draw_circle(Vector2(4.0, -27.2), 7.0 if on else 2.4, Color(1.0, 0.23, 0.18, 0.9 if on else 0.6))
		if on:
			draw_circle(Vector2(4.0, -27.2), 14.0, Color(1.0, 0.3, 0.2, 0.3))
		draw_set_transform(Vector2.ZERO)
		var pc: Color = main.player_color(ch["owner"])
		if not ch.get("flying", false):
			var left: float = clampf(1.0 - ch["t"] / float(c12["auto_s"]), 0.0, 1.0)
			draw_arc(p + Vector2(0, -24), 30.0, -PI / 2.0, -PI / 2.0 + TAU * left, 28, Color("#ff3b2f"), 3.0, true)
		if ch["armed"]:
			draw_set_transform(p, 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, float(c12["raio_tiles"]) * T * 0.75, 0, TAU, 40, Color(pc, 0.35 + (0.3 if on else 0.0)), 4.0, true)
			draw_set_transform(Vector2.ZERO)
	# E03 mira na viga mais perto (retícula) para quem tem o controle
	for r in main.robots:
		if r.alive and slot.has(r.pid) and slot[r.pid]["id"] == "E03" and not slot[r.pid].has("empty_t"):
			# todas as vigas que dá para soltar ganham um receptor piscando no cabo (fica claro onde a spell funciona)
			var ct2 = demo.canteiro
			if ct2 != null and is_instance_valid(ct2):
				for pv in ct2.parts:
					if pv["kind"] in REMOTE_KINDS and not pv["fallen"] and pv["crit_t"] <= 0.0 and pv["evt"] == "" and int(pv["etapa"]) == ct2.etapa_now():
						var top: Vector2 = Vector2(pv["rect"].get_center().x, pv["rect"].position.y - 30.0)
						draw_rect(Rect2(top - Vector2(10, 8), Vector2(20, 16)), INK)
						draw_rect(Rect2(top - Vector2(8, 6), Vector2(16, 12)), Color("#f2c84b"))
						draw_circle(top + Vector2(0, -1), 3.5, Color("#d94a3a") if fmod(t, 0.6) < 0.3 else Color("#5a2a20"))
						draw_line(top + Vector2(6, -8), top + Vector2(10, -18), INK, 2.0, true)
			var tg = remote_target(r)
			if tg != null:
				var c: Vector2 = tg["rect"].get_center()
				Kit.text(self, c + Vector2(-90, -62), "ESPECIAL: acionar  ·  ▲: outro", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 180, 5, INK)
				var rad := 40.0 + 6.0 * sin(t * 8.0)
				draw_arc(c, rad, 0, TAU, 24, Color("#d94a3a"), 3.0, true)
				for k in 4:
					var a := k * PI / 2.0 + t
					draw_line(c + Vector2.from_angle(a) * (rad - 10.0), c + Vector2.from_angle(a) * (rad + 10.0), Color("#d94a3a"), 3.0, true)
	for e in drops:   # cabo estalando
		var p: Dictionary = e["part"]
		if not p["fallen"] and e["t"] < 0.35:
			var top: Vector2 = Vector2(p["rect"].get_center().x, p["rect"].position.y)
			draw_line(top, top + Vector2(0, -60), Color(1, 0.85, 0.4), 3.0, true)
			for k in 3:
				main.spark(top + Vector2(0, -20 - k * 12), 1)
## Raio de energia de a até b: zigue-zague que muda a cada 1/20 s, com brilho largo ciano e miolo branco.
## stretch 0..1 (esticado: mais grosso/claro, puxa para o magenta), slack = barriga para baixo, alpha = piscar.
func _draw_bolt(a: Vector2, b: Vector2, stretch: float, slack: float, seed_t: float, alpha := 1.0) -> void:
	var n := maxi(int(a.distance_to(b) / 16.0), 3)
	var nrm := (b - a).normalized().orthogonal()
	var frame := int(t * 20.0)
	var pts := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		var bell := sin(u * PI)
		var jit := 0.0 if i == 0 or i == n else sin(float(frame) * 12.9898 + i * 78.233 + seed_t * 3.1) * (7.0 + 5.0 * stretch)
		pts.append(a.lerp(b, u) + Vector2(0, bell * slack + sin(u * 9.0 + t * 8.0) * slack * 0.15) + nrm * jit)
	var glow := Color(0.25, 0.76, 0.79).lerp(Color(0.85, 0.35, 0.85), stretch * 0.6)
	draw_polyline(pts, Color(glow, 0.35 * alpha), 14.0 + 6.0 * stretch, true)
	draw_polyline(pts, Color(glow, 0.9 * alpha), 5.0 + 2.0 * stretch, true)
	draw_polyline(pts, Color(1, 1, 1, alpha), 2.0, true)

# ================================================================ ETAPA 4: transformações
func _start_form(r, s: Dictionary) -> void:
	var c: Dictionary = sc(s["id"])
	s["t"] = float(c["duracao_s"])
	s["data"]["assemble"] = 0.0
	match s["id"]:
		"T02":
			r.spell_speed = float(c["vel_mult"])
			r.spell_push = float(c["empurrao_mult"])
		"T03":   # A33: começa EM PÉ (mecha gorila); segurar o especial fecha numa bola e rola
			s["data"]["bk"] = 0.0
		"T05":
			r.spell_speed = float(c["vel_mult"])
			r.spell_push = float(c["empurrao_mult"])
			s["energy"] = float(c["combustivel_s"])
		"T06":
			s["energy"] = float(c["combustivel_s"])
		"T07":   # A36: mecha Corredor
			r.spell_speed = float(c["vel_mult"])
			r.spell_push = float(c["empurrao_mult"])
			r.spell_jump = float(c["pulo_mult"])
			s["energy"] = float(c["combustivel_s"])
	main.dust(r.position + Vector2(0, -20), 1.0)   # o NOME aparece no fim da montagem (_assembled)
	main.shake(5.0)
	Audio.play("caixote_pancada", 0.8, 0.0)
	for k in 8:
		main.spark(r.rect().get_center() + Vector2(randf_range(-30, 30), randf_range(-40, 20)), 1)

func _end_form(r, natural: bool) -> void:
	var id: String = slot[r.pid]["id"] if slot.has(r.pid) else ""
	var d: Dictionary = slot[r.pid]["data"] if slot.has(r.pid) else {}
	if d.get("lift") is Object and is_instance_valid(d["lift"]):
		d["lift"].stun_t = 0.0
	r.spell_speed = 1.0
	r.spell_push = 1.0
	r.spell_hit = 1.0
	r.spell_jump = 1.0
	r.spell_form = ""
	r.vis.visible = true
	if r.size_k != 1.0:
		r.set_size(1.0)
		r.vis.s_sqy[0] = 0.6   # volta ao tamanho com mola
		r.vis.s_sqx[0] = 1.4
	if slot.has(r.pid):
		slot[r.pid]["t"] = -1.0
		slot[r.pid]["channel"] = false
	if id in ["T02", "T03", "T05", "T06", "T07"]:
		_mecha_explode(r)
	else:
		main.dust(r.position + Vector2(0, -20), 1.0)
	Audio.play("caixote_quebra", 1.3, -4.0)
	if natural:
		slot.erase(r.pid)

## Modo mecha (A33): id do mecha que o robô está pilotando JÁ MONTADO ("" se não está). A bola fechada não conta como
## "em pé" para golpes, mas mantém os atributos.
func mecha_of(r) -> String:
	if r == null or not slot.has(r.pid):
		return ""
	var s: Dictionary = slot[r.pid]
	var id: String = s["id"]
	if not (id in ["T01", "T02", "T03", "T04", "T05", "T06", "T07"]) or float(s["t"]) <= 0.0:
		return ""
	if float(s["data"].get("assemble", 0.0)) < 1.0:
		return ""
	return id

## Atributos do modo mecha do robô (recebe, empurrao, causa, alcances, área) ou {} se não está de mecha.
func mecha_cfg(r) -> Dictionary:
	var id := mecha_of(r)
	if id == "":
		return {}
	return demo.cfg.get("modo_mecha", {}).get(id, {})

## Golpe do mecha (A33), chamado por demolicao.attack: devolve [área, tipo] e solta os efeitos do golpe.
func mecha_strike(r, kind: String) -> Array:
	var id := mecha_of(r)
	var m: Dictionary = mecha_cfg(r)
	var heavy := kind == "pesado"
	var rr: Rect2 = r.rect()
	var cx: float = rr.get_center().x
	var reach: float = float(m.get("alcance_pesado" if heavy else "alcance_leve", 120))
	var hit: Rect2
	if heavy and String(m.get("area_pesado", "frente")) == "volta":
		hit = Rect2(cx - reach, rr.position.y - 40.0, reach * 2.0, rr.size.y + 40.0)
	else:
		var w := reach + rr.size.x / 2.0
		hit = Rect2(cx if r.facing > 0 else cx - w, rr.position.y - 40.0, w, rr.size.y + 40.0)
	if heavy:
		_mecha_heavy_fx(r, id, reach)
	else:
		mecha_fx.append({"kind": "leve", "id": id, "pos": r.position + Vector2(r.facing * (reach * 0.8), -55.0), "f": r.facing, "t": 0.0})
	return [hit, "mecha_pesado" if heavy else "mecha_leve"]

func _mecha_heavy_fx(r, id: String, reach: float) -> void:
	var g: Vector2 = r.position
	match id:
		"T01":   # pisão em chamas: fogo correndo pelo chão para os dois lados
			for side in [-1.0, 1.0]:
				for i in 26:
					fire_ps.append({"pos": g + Vector2(side * main.rng.randf_range(10, 40), -6.0), "vel": Vector2(side * main.rng.randf_range(260, 520), main.rng.randf_range(-260, -60)),
						"t": 0.0, "life": main.rng.randf_range(0.35, 0.55), "s": main.rng.randf_range(0.9, 1.3), "em": false})
		"T05":   # perfuração: chuva de faíscas na frente
			for i in 16:
				main.spark(g + Vector2(r.facing * main.rng.randf_range(60, reach), main.rng.randf_range(-80, -20)), 1)
		"T07":   # voadora deslizante: desliza rente ao chão para a frente
			r.forced_t = 0.28
			r.forced_vel = Vector2(r.facing * 950.0, 0.0 if r.is_on_floor() else 600.0)
			for i in 10:
				main.spark(g + Vector2(r.facing * main.rng.randf_range(0, 60), -4.0), 1)
		"T04":   # mergulho: se está no ar, desce em diagonal
			if not r.is_on_floor():
				r.forced_t = 0.22
				r.forced_vel = Vector2(r.facing * 700.0, 900.0)
	mecha_fx.append({"kind": "pesado", "id": id, "pos": g, "f": r.facing, "t": 0.0, "reach": reach})
	main.dust(g, 1.6)
	main.shake(8.0)

func _draw_mecha_fx() -> void:
	for e in mecha_fx:
		var u: float = e["t"] / 0.45
		var p: Vector2 = e["pos"]
		var f: float = e["f"]
		if e["kind"] == "leve":   # rastro curto do golpe + estrelinha
			var cor := Color(1, 0.7, 0.3) if e["id"] == "T01" else (Color(0.6, 0.95, 1.0) if e["id"] in ["T06", "T04"] else Color.WHITE)
			draw_arc(p - Vector2(f * 30.0, 0), 42.0, -0.9 if f > 0 else PI - 0.9, 0.9 if f > 0 else PI + 0.9, 12, Color(cor, 0.8 * (1.0 - u)), 10.0 * (1.0 - u) + 2.0, true)
			draw_circle(p, 16.0 * (1.0 - u) + 4.0, Color(1, 1, 0.85, 0.8 * (1.0 - u)))
			if e["id"] == "T06" and u < 0.6:
				_draw_bolt(p - Vector2(f * 50.0, 0), p + Vector2(f * 20.0, 0), 0.4, 0.0, t, 1.0 - u)
			continue
		var R0: float = float(e.get("reach", 150.0))
		draw_set_transform(p, 0.0, Vector2(1.0, 0.22))   # onda de choque no chão
		draw_arc(Vector2.ZERO, 30.0 + R0 * 1.3 * (1.0 - pow(1.0 - u, 3.0)), 0, TAU, 48, Color(1, 1, 1, 1.0 - u), 14.0 * (1.0 - u) + 2.0, true)
		draw_set_transform(Vector2.ZERO)
		match String(e["id"]):
			"T06":   # descarga em anel: raios saindo em volta
				if u < 0.7:
					for k in 8:
						var ang := k * TAU / 8.0 + t
						_draw_bolt(p + Vector2(0, -50), p + Vector2(0, -50) + Vector2.from_angle(ang) * R0 * (0.5 + 0.5 * u), 0.6, 0.0, t + k, 1.0 - u)
					draw_circle(p + Vector2(0, -50), 40.0 * (1.0 - u) + 10.0, Color(0.6, 0.95, 1.0, 0.5 * (1.0 - u)))
			"T03":   # socão no chão: rachaduras e pedras
				for k in 6:
					var a2 := PI + 0.25 + k * (PI - 0.5) / 5.0
					draw_line(p, p + Vector2.from_angle(a2) * R0 * 0.6 * minf(u * 3.0, 1.0) * Vector2(1, 0.25), Color(0.25, 0.2, 0.2, 1.0 - u), 3.0, true)
			"T02":   # garfada cravada: lascas
				draw_line(p + Vector2(f * 80.0, -120.0 * (1.0 - minf(u * 4.0, 1.0))), p + Vector2(f * 80.0, 0), Color(1, 1, 1, 0.8 * (1.0 - u)), 8.0, true)
			"T05":
				draw_line(p + Vector2(f * 40.0, -60.0), p + Vector2(f * R0, -60.0), Color(1, 0.9, 0.5, 0.7 * (1.0 - u)), 14.0 * (1.0 - u) + 2.0, true)
			"T04":
				draw_circle(p + Vector2(0, -20), 50.0 * u + 10.0, Color(0.75, 0.9, 1.0, 0.5 * (1.0 - u)))

## Ponta da arma do MECHA (A29) no mundo: ombro + ponta girada pela mira (mesmos números do desenho, mechas.json).
func mecha_muzzle(r) -> Vector2:
	var M: Dictionary = Data.mecha_meta
	var id: String = slot[r.pid]["id"] if slot.has(r.pid) else "T06"
	if not M.get("mechas", {}).has(id):
		return r.position + Vector2(r.facing * 40.0, -60.0)
	var m: Dictionary = M["mechas"][id]
	var px := RobotVis.mecha_px()
	var sh := Vector2(float(m["ombro"][0]), float(m["ombro"][1]))
	var off := Vector2(float(m["ponta"][0]), float(m["ponta"][1])).rotated(aim_local(r))
	var p := (sh + off) * px
	return r.position + Vector2(p.x * r.facing, p.y)

## Fim da armadura-mecha: as peças se soltam num estouro de faíscas, fumaça e poeira.
func _mecha_explode(r) -> void:
	var c: Vector2 = r.position + Vector2(0, -55)
	for k in 18:
		main.spark(c + Vector2(randf_range(-50, 50), randf_range(-60, 50)), 1)
	for k in 8:
		smokes.append({"pos": c + Vector2(randf_range(-40, 40), randf_range(-40, 40)), "vel": Vector2(randf_range(-140, 140), randf_range(-160, -20)), "t": 0.0, "size": randf_range(12, 20)})
	main.dust(r.position + Vector2(0, -20), 1.6)
	main.shake(5.0)

## Ponta do garfo da empilhadeira (sobe com `lift` 0..1).
func _fork_tip(r, lift: float) -> Vector2:
	return r.position + Vector2(r.facing * 58.0, -12.0 - lift * 58.0)

## T02: garfo sobe; se tem rival (ou caixa) na frente, ergue; 2º toque (ou tempo) joga para a frente (▲ mais alto).
func _fork_action(r, s: Dictionary) -> void:
	var c: Dictionary = sc("T02")
	var d: Dictionary = s["data"]
	if d.get("lift_t", -1.0) >= 0.0:
		_fork_toss(r, s)
		return
	if s["cd"] > 0.0:
		return
	d["lift_t"] = 0.0
	d["lift"] = _fork_grab(r, c)
	if d["lift"] == null:   # ninguém na ponta: a empilhadeira AVANÇA com o garfo baixo e pega quem encostar (2026-11-25:
		d["seek_t"] = float(c["investida_s"])   # "difícil de acertar o alvo")
		r.own_vx = r.facing * float(c["investida_vel"])
	Audio.play("elevador", 1.6, -2.0)

## T02: rival (ou caixa) na área do garfo — larga e alta (a mais perto ganha).
func _fork_grab(r, c: Dictionary):
	var L := float(c["garfo_alcance"])
	var front := Rect2(r.position.x + (10.0 if r.facing > 0 else -10.0 - L), r.position.y - float(c["garfo_altura"]), L, float(c["garfo_altura"]) + 20.0)
	var best = null
	var bd := 1e9
	for o in main.robots:
		if o != r and o.alive and o.guard_t <= 0.0 and o.invuln <= 0.0 and front.intersects(o.rect()):
			var dd: float = absf(o.position.x - r.position.x)
			if dd < bd:
				bd = dd
				best = o
	if best != null:
		main.float_text(best.position + Vector2(0, -120), "ERGUIDO!", Color("#f2c84b"))
		return best
	for b in boxes:
		if front.has_point(b["pos"] + Vector2(0, 20)):
			return b
	return null

func _fork_toss(r, s: Dictionary) -> void:
	var c: Dictionary = sc("T02")
	var d: Dictionary = s["data"]
	var tg = d.get("lift")
	var up := aim_vec(r).y < -0.5
	var v := Vector2(r.facing * float(c["joga_vel"]), -500.0) if not up else Vector2(r.facing * 260.0, -float(c["joga_vel"]) * 1.05)
	if tg is Object and is_instance_valid(tg) and tg.alive:
		_hit(tg, r.pid, r.facing, "spell_empilhadeira")
		tg.velocity = v
		tg.own_vx = v.x
		tg.stun_t = maxf(tg.stun_t, 0.35)
		Audio.play("arremesso", 0.9, 2.0)
	elif tg is Dictionary and tg in boxes:
		tg["vy"] = v.y * 0.8
		tg["pos"].x += r.facing * 40.0
	d["lift_t"] = -1.0
	d["lift"] = null
	d["drop_t"] = 0.0   # garfo desce
	s["cd"] = float(c["intervalo_s"])
	s["fire"] = 0.0
	main.shake(4.0)

## T04 Jetpack: segurar = voar (sobe; ◄► pilota de lado; ▲ sobe mais rápido, ▼ desce devagar) gastando combustível.
func _update_jet(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc("T04")
	var d: Dictionary = s["data"]
	var thrust: bool = held(r) and s["energy"] > 0.0 and r.alive
	d["thrust"] = thrust
	r.spell_fly = thrust
	if thrust:
		s["energy"] -= dt
		var tgt := -float(c["sobe_vel"])
		if PlayerInput.held(r.pid, "up"):
			tgt *= 1.35
		elif PlayerInput.held(r.pid, "down"):
			tgt = float(c["desce_vel"])
		r.velocity.y = move_toward(r.velocity.y, tgt, float(c["sobe_acel"]) * dt)
		r.hanging = false
		r.var_jump = 0.0
		d["power"] = minf(float(d.get("power", 0.0)) + dt * 6.0, 1.0)
		if fmod(t, 0.05) < dt:
			smokes.append({"pos": r.position + Vector2(-r.facing * 17.0, 20.0), "vel": Vector2(randf_range(-40, 40) - r.velocity.x * 0.2, 180.0), "t": 0.0, "size": randf_range(7, 12)})
		if fmod(t, 0.12) < dt:
			Audio.play("foguete", 0.9 + randf() * 0.2, -6.0)
	else:
		d["power"] = maxf(float(d.get("power", 0.0)) - dt * 5.0, 0.0)
	s["t"] -= dt
	if s["energy"] <= 0.0 or s["t"] <= 0.0:
		r.spell_fly = false
		var parts := [{"tex": [Data.tex("spells/a16_jato")], "rect": Rect2(-19, -22, 38, 44), "mod": Color.WHITE}]
		var dbr: Node2D = main.Debris.new()
		dbr.setup(parts, r.position + Vector2(-r.facing * 14.0, -40.0), -r.facing, Vector2(-r.facing * 120.0, -200.0))
		main.world.add_child(dbr)
		for k in 6:
			smokes.append({"pos": r.position + Vector2(0, -40), "vel": Vector2(randf_range(-80, 80), randf_range(-120, -20)), "t": 0.0, "size": 12.0})
		Audio.play("menu_negado", 0.6, -2.0)
		slot.erase(r.pid)

func _update_form(r, s: Dictionary, dt: float) -> void:
	var c: Dictionary = sc(s["id"])
	var d: Dictionary = s["data"]
	var a_before: float = float(d.get("assemble", 0.0))
	d["assemble"] = minf(a_before + dt / 0.9, 1.0)   # transformação estilo Transformers (A29)
	if a_before < 1.0 and d["assemble"] >= 1.0:
		_assembled(r, s["id"])
	if a_before < 1.0 and d["assemble"] >= 1.0:   # travou: clarão, faíscas, robô dá uma achatada
		for k in 10:
			main.spark(r.rect().get_center() + Vector2(randf_range(-26, 26), randf_range(-36, 26)), 1)
		r.vis.s_sqy[0] = 0.78
		r.vis.s_sqx[0] = 1.18
		main.shake(4.0)
		Audio.play("caixote_pancada", 1.1, -2.0)
		d["flash"] = 1.0
	d["flash"] = maxf(float(d.get("flash", 0.0)) - dt * 4.0, 0.0)
	s["t"] -= dt
	match s["id"]:
		"T02":   # garfo erguendo: segura o rival na ponta por pouco tempo e joga
			if d.get("lift_t", -1.0) >= 0.0:
				d["lift_t"] += dt
				if d.get("lift") == null and float(d.get("seek_t", 0.0)) > 0.0:   # investida: pega quem encostar
					d["seek_t"] = float(d["seek_t"]) - dt
					r.own_vx = r.facing * float(c["investida_vel"])
					d["lift"] = _fork_grab(r, c)
					d["lift_t"] = 0.0 if d["lift"] != null else minf(d["lift_t"], 0.1)
				var k := minf(d["lift_t"] / 0.25, 1.0)
				var tg = d.get("lift")
				if tg is Object and is_instance_valid(tg) and tg.alive:
					tg.position = _fork_tip(r, k) + Vector2(0, 2)
					tg.velocity = Vector2.ZERO
					tg.own_vx = 0.0
					tg.stun_t = maxf(tg.stun_t, 0.1)
					tg.hanging = false
				elif tg is Dictionary and tg in boxes:
					tg["pos"] = _fork_tip(r, k) + Vector2(0, -34)
					tg["vy"] = 0.0
				if d["lift_t"] >= float(c["segura_max_s"]) + 0.25:
					_fork_toss(r, s)
			elif d.has("drop_t"):
				d["drop_t"] += dt
		"T03":   # A33: gorila em pé; SEGURANDO o especial fecha em bola (bk 0→1) e rola; soltou, abre e fica em pé
			var want: bool = s["channel"] and held(r) and float(d.get("assemble", 0.0)) >= 1.0
			if s["channel"] and not want:
				s["channel"] = false
			var bk0: float = float(d.get("bk", 0.0))
			d["bk"] = move_toward(bk0, 1.0 if want else 0.0, dt / 0.25)
			if bk0 < 0.75 and float(d["bk"]) >= 0.75:
				r.spell_form = "bola"
				r.own_vx = r.facing * maxf(absf(r.own_vx), 300.0)
				main.dust(r.position, 1.0)
				Audio.play("caixote_pancada", 1.3, -6.0)
			elif bk0 >= 0.75 and float(d["bk"]) < 0.75:
				r.spell_form = ""
				for k in 6:
					main.spark(r.position + Vector2(randf_range(-30, 30), randf_range(-60, -10)), 1)
			r.vis.visible = r.spell_form != "bola"
			d["roll"] = float(d.get("roll", 0.0)) + r.velocity.x * dt / 36.0
			var hc: Dictionary = d.get("hitcd", {})
			for oid in hc.keys():
				hc[oid] -= dt
			d["hitcd"] = hc
			if absf(r.own_vx) > float(c["dano_min_vel"]):
				for o in main.robots:
					if o != r and o.alive and r.rect().grow(6).intersects(o.rect()) and float(hc.get(o.pid, 0.0)) <= 0.0:
						hc[o.pid] = 0.5
						if _hit(o, r.pid, int(signf(r.own_vx)), "spell_bola"):
							d["squash"] = 1.0
							r.own_vx *= 0.7
				if fmod(t, 0.05) < dt and r.is_on_floor():
					main.dust(r.position + Vector2(-signf(r.own_vx) * 20.0, 0), 0.5)
			d["squash"] = maxf(float(d.get("squash", 0.0)) - dt * 5.0, 0.0)
		"T05":   # broca-braço: mira em 8 direções (▼ no chão fura para baixo); fura rival e trecho do Canteiro
			var hc2: Dictionary = d.get("hitcd", {})
			for oid in hc2.keys():
				hc2[oid] -= dt
			d["hitcd"] = hc2
			var dashing: bool = s["channel"] and held(r) and s["energy"] > 0.0 and float(d.get("assemble", 0.0)) >= 1.0
			if s["channel"] and not dashing:
				s["channel"] = false
				if d.get("dash", false):   # derrapa: faíscas sob os pés
					for k in 6:
						main.spark(r.position + Vector2(randf_range(-20, 20), -4), 1)
					main.dust(r.position, 1.0)
			d["dash"] = dashing
			if dashing:
				s["energy"] -= dt
				r.forced_t = dt * 2.0
				r.forced_vel = Vector2(r.facing * float(c["dash_vel"]), 0.0 if r.is_on_floor() else 120.0)
				_set_aim(r, s, Vector2(r.facing, 0), 30.0, dt)
				# fura o que estiver na frente e atropela quem estiver no caminho
				var front := Rect2(r.position + Vector2(r.facing * 20.0 - 40.0, -90.0), Vector2(80, 84))
				d["dt_t"] = float(d.get("dt_t", 0.0)) - dt
				if d["dt_t"] <= 0.0:
					d["dt_t"] = float(c["dash_tick_s"])
					var ctd = demo.canteiro
					if ctd != null and is_instance_valid(ctd):
						for p in ctd.parts:
							if not p["fallen"] and p["rect"].intersects(front.grow(6)):
								ctd.damage(p, 1, front.get_center())
								for k in 4:
									rocks.append({"pos": front.get_center(), "vel": Vector2(r.facing * randf_range(60, 300), randf_range(-320, -80)), "t": 0.0, "rot": randf() * TAU, "size": randf_range(5, 10)})
								main.shake(3.0)
				for o in main.robots:
					if o != r and o.alive and front.intersects(o.rect()) and float(hc2.get(o.pid, 0.0)) <= 0.0:
						hc2[o.pid] = 0.45
						if _hit_dir(o, r.pid, Vector2(r.facing, -0.3), "spell_broca_dash"):
							main.shake(6.0)
				if fmod(t, 0.03) < dt:
					main.spark(r.position + Vector2(r.facing * 70.0, -50.0), 1)
				if fmod(t, 0.05) < dt:
					main.dust(r.position + Vector2(-r.facing * 24.0, 0), 0.7)
				if fmod(t, 0.12) < dt:
					Audio.play("furadeira", 1.3, -4.0)
				d["trail"] = (d.get("trail", []) as Array) + [r.position]
				if (d["trail"] as Array).size() > 5:
					(d["trail"] as Array).pop_front()
			else:
				d["trail"] = []
			var av: Vector2 = aim_vec(r)
			if PlayerInput.held(r.pid, "down") and r.is_on_floor():
				av = Vector2(0, 1)
			if not dashing:
				_set_aim(r, s, av, 10.0, dt)
			var tip := muzzle(r, "F31")
			var root: Vector2 = r.position + Vector2(r.facing * 6.0, -40.0)
			for o in main.robots:
				if not dashing and o != r and o.alive and _seg_rect(root, tip + aim_dir(r) * 8.0, o.rect(), 10.0) and float(hc2.get(o.pid, 0.0)) <= 0.0:
					hc2[o.pid] = float(c["tick_s"])
					_hit_dir(o, r.pid, aim_dir(r), "spell_broca")
			d["st"] = float(d.get("st", 0.0)) - dt
			if d["st"] <= 0.0:
				d["st"] = float(c["estrutura_tick_s"])
				var pt := tip + aim_dir(r) * 10.0
				var hit_any := false
				var ct = demo.canteiro
				if ct != null and is_instance_valid(ct):
					for p in ct.parts:
						if not p["fallen"] and p["rect"].grow(4).has_point(pt):
							ct.damage(p, 1, pt)
							hit_any = true
				if hit_any or _hard_at(pt):
					for k in 3:
						rocks.append({"pos": pt, "vel": -aim_dir(r) * randf_range(120, 280) + Vector2(randf_range(-80, 80), -200), "t": 0.0, "rot": randf() * TAU, "size": randf_range(4, 8)})
					Audio.play("furadeira", 1.0, -6.0)
			if fmod(t, 0.04) < dt:
				main.spark(tip, 1)
		"T06":   # PARA-RAIOS (A30): segurar = raio na mira que pula de robô em robô (até 3) e conduz no metal
			var on: bool = s["channel"] and held(r) and s["energy"] > 0.0 and float(d.get("assemble", 0.0)) >= 1.0
			if s["channel"] and not on:
				s["channel"] = false
			d["arc"] = on
			d["chain"] = []
			d["metal"] = []
			if on:
				s["energy"] -= dt
				var hc3: Dictionary = d.get("hitcd", {})
				for oid in hc3.keys():
					hc3[oid] -= dt
				d["hitcd"] = hc3
				_set_aim(r, s, aim_vec(r), 10.0, dt)
				var a := mecha_muzzle(r)
				var dirv := aim_dir(r)
				# 1º alvo: robô mais perto dentro do cone da mira
				var chain: Array = [a]
				var used := {}
				var best = null
				var bd := float(c["raio_alcance"])
				for o in main.robots:
					if o == r or not o.alive:
						continue
					var v: Vector2 = o.rect().get_center() - a
					if v.length() < bd and v.normalized().dot(dirv) > 0.55:
						bd = v.length()
						best = o
				var victims: Array = []
				var cur = best
				while cur != null and victims.size() < int(c["raio_alvos"]):
					victims.append(cur)
					used[cur.pid] = true
					chain.append(cur.rect().get_center())
					var nxt = null
					var nd := float(c["raio_salto"])
					for o in main.robots:
						if o == r or not o.alive or used.has(o.pid):
							continue
						var dd: float = o.rect().get_center().distance_to(cur.rect().get_center())
						if dd < nd:
							nd = dd
							nxt = o
					cur = nxt
				if victims.is_empty():
					chain.append(a + dirv * float(c["raio_alcance"]) * 0.6)
				d["chain"] = chain
				for i in victims.size():
					var o = victims[i]
					if float(hc3.get(o.pid, 0.0)) <= 0.0:
						hc3[o.pid] = float(c["tick_s"])
						_hit_dir(o, r.pid, (o.rect().get_center() - (chain[i] as Vector2)).normalized(), "spell_raio%d" % (i + 1))
						o.vis.hurt(0.4, int(signf(o.position.x - r.position.x)))
				# conduz no metal (grelha/estaca) perto do último ponto da cadeia
				var lastp: Vector2 = chain[-1]
				var ctm = demo.canteiro
				if ctm != null and is_instance_valid(ctm):
					var metal: Array = []
					for p in ctm.parts:
						if not p["fallen"] and String(p["kind"]) in ["grelha", "estaca"] and p["rect"].get_center().distance_to(lastp) < float(c["metal_alcance"]):
							metal.append(p["rect"].get_center())
							d["mt"] = float(d.get("mt", 0.0)) - dt
							if float(d["mt"]) <= 0.0:
								d["mt"] = float(c["tick_s"]) * 2.0
								ctm.damage(p, 1, p["rect"].get_center())
								main.spark(p["rect"].get_center(), 1)
							break
					d["metal"] = metal
				if fmod(t, 0.08) < dt:
					Audio.play("laser", 2.2, -8.0)
				if fmod(t, 0.05) < dt:
					main.spark(lastp, 1)
			# conserto: parado, segurando ▼ + especial em cima de um trecho rachado
			var rep_ok: bool = not d.get("repaired", false) and r.is_on_floor() and absf(r.velocity.x) < 30.0 and PlayerInput.held(r.pid, "down") and held(r)
			var part = null
			if rep_ok:
				var ct2 = demo.canteiro
				if ct2 != null and is_instance_valid(ct2):
					for p in ct2.parts:
						if not p["fallen"] and p["crit_t"] <= 0.0 and int(p["hp"]) < int(p["max"]) and p["rect"].grow(8).has_point(r.position + Vector2(0, 6)):
							part = p
			if part != null:
				d["rep_t"] = float(d.get("rep_t", 0.0)) + dt
				if d["rep_t"] >= float(c["reparo_s"]):
					part["hp"] = mini(int(part["hp"]) + 1, int(part["max"]))
					var frac := float(part["hp"]) / float(part["max"])
					part["state"] = 0 if frac > 0.67 else (1 if frac > 0.34 else 2)
					d["repaired"] = true
					main.float_text(r.position + Vector2(0, -130), "CONSERTADO!", Color("#5cc45c"))
					Audio.play("item", 1.4)
			else:
				d["rep_t"] = 0.0
		"T07":   # A36 ARRANCADA: segurando o especial dispara em linha reta, atropela, sobe parede correndo
			var hc7: Dictionary = d.get("hitcd", {})
			for oid in hc7.keys():
				hc7[oid] -= dt
			d["hitcd"] = hc7
			var corre: bool = s["channel"] and held(r) and s["energy"] > 0.0 and float(d.get("assemble", 0.0)) >= 1.0
			if s["channel"] and not corre:
				s["channel"] = false
				if d.get("dash", false):   # freia derrapando
					for k in 6:
						main.spark(r.position + Vector2(randf_range(-20, 20), -4), 1)
					main.dust(r.position, 1.0)
			d["dash"] = corre
			if corre:
				s["energy"] -= dt
				var parede: bool = r.is_on_wall() and int(signf(r.get_wall_normal().x)) == -r.facing
				r.forced_t = dt * 2.0
				if parede:   # sobe a parede correndo
					r.forced_vel = Vector2(r.facing * 60.0, -float(c["sobe_parede_vel"]))
				else:
					r.forced_vel = Vector2(r.facing * float(c["arrancada_vel"]), 0.0 if r.is_on_floor() else 160.0)
				var front7 := Rect2(r.position + Vector2(r.facing * 14.0 - 34.0, -84.0), Vector2(68, 80))
				for o in main.robots:
					if o != r and o.alive and front7.intersects(o.rect()) and float(hc7.get(o.pid, 0.0)) <= 0.0:
						hc7[o.pid] = float(c["arrancada_tick_s"])
						if _hit_dir(o, r.pid, Vector2(r.facing, -0.45), "spell_arrancada"):
							main.shake(5.0)
				for side in [-1.0, -0.6]:   # fogo dos escapamentos (atrás, em cima)
					fire_ps.append({"pos": r.position + Vector2(-r.facing * 34.0, -78.0 + side * 6.0), "vel": Vector2(-r.facing * randf_range(260, 420), randf_range(-60, 40)),
						"t": 0.0, "life": randf_range(0.18, 0.3), "s": randf_range(0.5, 0.8), "em": false})
				if fmod(t, 0.05) < dt and r.is_on_floor():
					main.dust(r.position + Vector2(-r.facing * 24.0, 0), 0.7)
				if fmod(t, 0.14) < dt:
					Audio.play("foguete", 1.4, -8.0)
	if s["t"] <= 0.0:
		_end_form(r, true)

## Quando a bola bate forte na parede: racha trecho frágil do Canteiro.
func ball_bump(r, vx: float) -> void:
	var ct = demo.canteiro
	var pt: Vector2 = r.position + Vector2(signf(vx) * 40.0, -30.0)
	main.spark(pt, 5)
	if ct != null and is_instance_valid(ct):
		for p in ct.parts:
			if not p["fallen"] and p["state"] >= 1 and p["rect"].grow(10).has_point(pt):
				ct.damage(p, 1, pt)
	if slot.has(r.pid):
		slot[r.pid]["data"]["squash"] = 1.0

func _update_etapa4(dt: float) -> void:
	for e in jets:
		e["t"] += dt
	jets = jets.filter(func(e): return e["t"] < 0.3)
	for m in smokes:
		m["t"] += dt
		m["pos"] += m["vel"] * dt
		m["vel"] *= 0.94
		m["vel"].y -= 30.0 * dt
	smokes = smokes.filter(func(m): return m["t"] < 0.9)

# ---------------------------------------------------------------- desenho da Etapa 4
func _draw_etapa4() -> void:
	for r in main.robots:
		if not r.alive or not slot.has(r.pid):
			continue
		var s: Dictionary = slot[r.pid]
		var d: Dictionary = s["data"]
		if not (s["id"] in FORMS) or s["t"] <= 0.0:
			continue
		var fk: float = float(d.get("assemble", 1.0))
		var end_blink: bool = s["t"] < 1.0 and fmod(t, 0.16) < 0.08
		var mod := Color(1.5, 1.4, 1.3) if end_blink else Color.WHITE
		match s["id"]:
			"T03":
				if float(d.get("bk", 0.0)) > 0.0:
					_draw_ball(r, d, float(d["bk"]) * 0.75 if r.spell_form != "bola" else 1.0, mod)
			"T05": _draw_drill_dash(r, d)
			"T06": _draw_welder(r, d, fk, mod)
	# T04 jetpack: dois jatos saindo dos bicos (grandes acelerando, chama-piloto no resto), inclinados com o corpo
	for r in main.robots:
		if not r.alive or not slot.has(r.pid) or slot[r.pid]["id"] != "T04" or slot[r.pid]["t"] <= 0.0:
			continue
		var pw: float = float(slot[r.pid]["data"].get("power", 0.0))
		var tilt := clampf(r.velocity.x / 600.0, -1.0, 1.0) * 0.38
		var back := Vector2(0, 1).rotated(-tilt * 0.6)
		# bicos na BASE DA MOCHILA de cada robô (mesma âncora do desenho: ombro de trás + (-12, 10); mochila 38x44)
		var sh0: Vector2 = RobotVis._v(Data.model_meta(r.vis.model)["shoulders"][0])
		var bp := sh0 + Vector2(-12.0, 10.0 + 20.0)
		for nz in [-8.0, 8.0]:
			var o: Vector2 = r.position + Vector2(r.facing * (bp.x + nz * 0.8), bp.y) + Vector2(r.facing * tilt * 20.0, 0)
			var L := 10.0 + 52.0 * pw * (0.85 + 0.15 * sin(t * 50.0 + nz))
			var side := back.orthogonal() * (5.0 + 4.0 * pw)
			draw_colored_polygon(PackedVector2Array([o - side, o + back * L, o + side]), Color(0.95, 0.4, 0.15, 0.9))
			draw_colored_polygon(PackedVector2Array([o - side * 0.6, o + back * L * 0.75, o + side * 0.6]), Color(1, 0.75, 0.3))
			draw_colored_polygon(PackedVector2Array([o - side * 0.3, o + back * L * 0.4, o + side * 0.3]), Color(1, 0.98, 0.85))
			if pw > 0.5:
				draw_circle(o + back * L, 5.0, Color(1, 0.9, 0.5, 0.5))
	for m in smokes:
		var u: float = m["t"] / 0.9
		draw_circle(m["pos"], m["size"] * (0.6 + u), Color(0.42, 0.4, 0.44, 0.5 * (1.0 - u)))
		draw_circle(m["pos"] + Vector2(-3, -3), m["size"] * 0.4 * (0.6 + u), Color(0.7, 0.7, 0.72, 0.4 * (1.0 - u)))
	_draw_trails()
func _ptag(r, at: Vector2) -> void:   # marcador "P1" quando o robô está escondido dentro da transformação
	var pc: Color = main.player_color(r.pid)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-10, -14), at + Vector2(10, -14), at]), INK)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-7, -12), at + Vector2(7, -12), at + Vector2(0, -3)]), pc)
	Kit.text(self, at + Vector2(-30, -20), "P%d" % (r.pid + 1), 22, pc, HORIZONTAL_ALIGNMENT_CENTER, 60, 5, INK)

## T02: mastro preso na frente da armadura-cabine, garfo subindo nele (o robô veste a cabine — robot_visual).
func _draw_forklift(r, d: Dictionary, fk: float, mod: Color) -> void:
	var f := float(r.facing)
	var lift := 0.0
	if d.get("lift_t", -1.0) >= 0.0:
		lift = minf(d["lift_t"] / 0.25, 1.0)
	elif d.has("drop_t"):
		lift = maxf(1.0 - d["drop_t"] / 0.25, 0.0)
	var drop := (1.0 - ease(fk, 0.5)) * -50.0   # o mastro desce e trava junto com a cabine
	var shake := Vector2(sin(t * 70.0), 0) * 1.2 if absf(r.velocity.x) > 40.0 else Vector2.ZERO
	draw_set_transform(r.position + Vector2(0, drop) + shake, 0.0, Vector2(f, 1.0))
	draw_texture_rect(Data.tex("spells/a14_mastro"), Rect2(Vector2(30, -76), Vector2(20, 72)), false, mod)
	var fy := -10.0 - lift * 58.0
	draw_rect(Rect2(34, fy - 10, 10, 14), INK)   # carro do garfo
	draw_rect(Rect2(36, fy - 8, 6, 10), Color("#f2c84b"))
	for k in 2:   # 2 dentes do garfo
		var yy := fy + k * 6.0 - 3.0
		draw_rect(Rect2(40, yy - 2, 34, 5), INK)
		draw_rect(Rect2(41, yy - 1, 32, 3), Color("#c9d1d8"))
	draw_set_transform(Vector2.ZERO)

## T03: bola — enquanto monta, duas cascas fecham sobre o robô; depois esfera rolando com olhos espiando.
func _draw_ball(r, d: Dictionary, fk: float, mod: Color) -> void:
	var c: Vector2 = r.position + Vector2(0, -36)
	var M: Dictionary = Data.mecha_meta
	var tex := Data.tex("mecha/T03_bola_p%d" % (posmod(int(r.vis.color_idx), 4) + 1))
	var px := float(M.get("px", 0.84))
	var bx: Array = M.get("caixa", [-150, -280, 340, 300])
	var box := Rect2(float(bx[0]) * px, (float(bx[1]) + 46.0) * px, float(bx[2]) * px, float(bx[3]) * px)
	var grow := 1.0
	var spin := float(d.get("roll", 0.0))
	if fk < 0.75:   # o gorila se encolhe: a bola cresce girando e as placas fecham
		var u := ease(fk / 0.75, 0.4)
		grow = lerpf(0.35, 1.0, u)
		spin = (1.0 - u) * 6.0
		draw_circle(c, 70.0 * (1.0 - u) + 20.0, Color(1, 0.97, 0.8, 0.5 * (1.0 - u)))
	var sq: float = float(d.get("squash", 0.0))
	var vx: float = r.own_vx
	if grow >= 1.0 and absf(vx) > 220.0:   # rolando rápido (A30): rastro de bolas, arco de giro e faíscas no chão
		var dirx := signf(vx)
		for k in 3:
			var gp: Vector2 = c - Vector2(dirx * (26.0 + k * 26.0), 0) - r.velocity * Vector2(0, 0.02 * k)
			draw_circle(gp, 38.0, Color(0.75, 0.9, 1.0, 0.22 - k * 0.06))
		draw_arc(c, 46.0, PI * 0.55 if dirx > 0 else -PI * 0.45, PI * 1.15 if dirx > 0 else PI * 0.15, 16, Color(1, 1, 1, 0.65), 6.0, true)
		if r.is_on_floor():
			var g: Vector2 = r.position + Vector2(-dirx * 18.0, -2.0)
			for k in 7:
				var u := fposmod(t * 6.0 + k * 0.14, 1.0)
				var sp := g + Vector2(-dirx * (u * 90.0 + k * 4.0), -sin(u * PI) * (24.0 + k * 3.0))
				draw_line(sp, sp + Vector2(-dirx * 7.0, -2.0), Color(1, 0.84, 0.4, 1.0 - u), 2.5, true)
			for k in 4:
				var u2 := fposmod(t * 3.0 + k * 0.25, 1.0)
				draw_circle(g + Vector2(-dirx * (20.0 + u2 * 70.0), -6.0 - u2 * 10.0), 8.0 + u2 * 12.0, Color(0.85, 0.78, 0.66, 0.5 * (1.0 - u2)))
	draw_set_transform(c, spin, Vector2(1.0 + 0.2 * sq, 1.0 - 0.2 * sq) * grow)
	draw_texture_rect(tex, box, false, mod)
	draw_set_transform(Vector2.ZERO)
	if grow >= 1.0:   # o piloto na vigia, sempre em pé
		RobotVis._mecha_piloto(self, Transform2D(0.0, Vector2(px, px), 0.0, c + Vector2(0, 46.0 * px)), {"cockpit": [0.0, -46.0, 26.0, 26.0]},
			Data.MODELS[posmod(int(r.vis.model), Data.MODELS.size())], posmod(int(r.vis.color_idx), 4), r.vis.look(), {"expr": "esforco"})
	if absf(r.own_vx) > 400.0:
		for k in 3:
			var yy: float = c.y - 20.0 + k * 20.0
			draw_line(Vector2(c.x - signf(r.own_vx) * 44.0, yy), Vector2(c.x - signf(r.own_vx) * (80.0 + k * 10.0), yy), Color(1, 1, 1, 0.7), 3.0, true)
	if float(d.get("flash", 0.0)) > 0.0:
		draw_circle(c, 44.0, Color(1, 1, 1, 0.5 * d["flash"]))
	_ptag(r, c + Vector2(0, -50))

## T05 dash furando (A30): vultos do mecha ficando para trás, linhas de velocidade, faíscas na broca e poeira.
func _draw_drill_dash(r, d: Dictionary) -> void:
	if not d.get("dash", false):
		return
	var f := float(r.facing)
	var tr: Array = d.get("trail", [])
	for i in tr.size():
		var p: Vector2 = tr[i]
		var k := float(i + 1) / float(tr.size() + 1)
		draw_rect(Rect2(p + Vector2(-34, -125), Vector2(68, 125)), Color(0.75, 0.9, 1.0, 0.10 + 0.12 * k))
	for k in 10:   # linhas de velocidade
		var yy: float = r.position.y - 120.0 + fmod(k * 37.0, 120.0)
		var ln := 60.0 + fmod(k * 53.0 + t * 900.0, 120.0)
		var x0: float = r.position.x - f * (60.0 + fmod(k * 71.0 + t * 1400.0, 260.0))
		draw_line(Vector2(x0, yy), Vector2(x0 - f * ln, yy), Color(1, 1, 1, 0.75), 3.0 + fmod(k, 3.0), true)
	var tip: Vector2 = r.position + Vector2(f * 74.0, -62.0)
	draw_circle(tip, 22.0 + sin(t * 70.0) * 5.0, Color(1, 0.95, 0.6, 0.45))
	for k in 6:   # faíscas espirrando da broca
		var ang := (PI if f > 0 else 0.0) + sin(t * 40.0 + k * 1.7) * 1.1
		var L := 20.0 + fmod(k * 13.0 + t * 300.0, 40.0)
		draw_line(tip, tip + Vector2.from_angle(ang) * L, Color(1, 0.85, 0.35, 0.9), 2.5, true)

## T06: arco de solda saindo do maçarico-braço (o robô veste a armadura de soldador — robot_visual).
func _draw_welder(r, d: Dictionary, fk: float, mod: Color) -> void:
	var a0 := mecha_muzzle(r)
	var en: float = float(slot[r.pid].get("energy", 0.0)) if slot.has(r.pid) else 0.0
	# bobina das costas estalando sempre que tem carga
	if en > 0.0 and fk >= 1.0:
		var coil: Vector2 = r.position + Vector2(-r.facing * 34.0, -112.0)
		draw_circle(coil, 14.0 + sin(t * 40.0) * 3.0, Color(0.5, 0.9, 1.0, 0.35))
		for k in 2:
			var ang := t * 9.0 + k * 2.6
			_draw_bolt(coil, coil + Vector2.from_angle(ang) * 26.0, 0.2, 0.0, t + k, 0.8)
	if not d.get("arc", false):
		return
	var chain: Array = d.get("chain", [])
	for i in range(chain.size() - 1):
		var pa: Vector2 = chain[i]
		var pb: Vector2 = chain[i + 1]
		var k := 1.0 - i * 0.3
		_draw_bolt(pa, pb, k, 0.0, t + i * 1.7, 1.0)
		_draw_bolt(pa, pb, k * 0.5, 0.0, t * 1.3 + i * 3.1 + 7.0, 0.6)   # 2º fio, mais fino
		draw_circle(pb, 26.0 * k + sin(t * 50.0) * 4.0, Color(0.6, 0.95, 1.0, 0.35))
		draw_circle(pb, 9.0 * k, Color(1, 1, 1, 0.9))
	for mp in d.get("metal", []):
		var last: Vector2 = chain[-1]
		_draw_bolt(last, mp, 0.4, 0.0, t + 5.0, 0.9)
		for k in 3:
			var u := fposmod(t * 2.5 + k * 0.33, 1.0)
			draw_circle(mp + Vector2(sin(k * 3.0) * 20.0, u * 50.0), 2.4, Color(1, 0.9, 0.4, 1.0 - u))
	draw_circle(a0, 16.0 + sin(t * 60.0) * 4.0, Color(0.6, 0.95, 1.0, 0.45))
	draw_circle(a0, 7.0, Color.WHITE)
	var rep: float = float(d.get("rep_t", 0.0))
	if rep > 0.0:   # anel de progresso do conserto
		var k := clampf(rep / float(sc("T06")["reparo_s"]), 0.0, 1.0)
		var c: Vector2 = r.position + Vector2(0, -140)
		draw_arc(c, 18.0, 0, TAU, 24, Color(0.85, 0.87, 0.9, 0.9), 6.0, true)
		draw_arc(c, 18.0, -PI / 2.0, -PI / 2.0 + TAU * k, 24, Color("#5cc45c"), 6.0, true)

## T07 correndo rápido: vultos do robô ficando para trás (nó "trail" com transparência própria).
var trail_pts := {}
func _draw_trails() -> void:
	if trail_node == null:
		return
	trail_node.queue_redraw()

func _draw_trail_node() -> void:
	for r in main.robots:
		if not r.alive or not slot.has(r.pid) or slot[r.pid]["id"] != "T07" or slot[r.pid]["t"] <= 0.0:
			trail_pts.erase(r.pid)
			continue
		var arr: Array = trail_pts.get(r.pid, [])
		if absf(r.velocity.x) > 700.0:   # A36: vultos só correndo muito (Corredor)
			if arr.is_empty() or arr[-1].distance_to(r.position) > 22.0:
				arr.append(r.position)
		if arr.size() > 4 or (absf(r.velocity.x) <= 700.0 and arr.size() > 0 and fmod(t, 0.05) < 0.02):
			arr.pop_front()
		trail_pts[r.pid] = arr
		var pose: Dictionary = r.vis.current_pose() if r.vis.has_method("current_pose") else RobotVis.idle_pose(t)
		for i in arr.size():
			RobotVis.draw_robot(trail_node, r.vis.look(), pose, Transform2D(0.0, Vector2(r.facing, 1.0), 0.0, arr[i]))
