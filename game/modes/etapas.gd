extends Node2D
## CENAS DO MAPA (modo Derruba v2; docs/manuais/derruba/README.md). Um mapa é uma árvore de cenas por nível (3 = 1→2,
## 7 = 1→2→4; geometria etapaN no .lvl; conteúdo e rotas no manifesto data/mapas/<modo>/<mapa>.json).
## O TEMPO decide QUANDO verificar; a DESTRUIÇÃO decide PARA ONDE (aprovado A3): na verificação, < 50% fica e verifica de
## novo depois; 50–90% → rota moderada; ≥ 90% → rota total. Chegar a 90% antes não antecipa. Sem cronômetro no HUD.
## 1ª verificação e intervalo vêm das VIDAS (modos[derruba].destruicao.verificacao; a cena pode sobrescrever).
## Transição: AVISO (texto da rota, tudo treme) → DESABA → QUEDA (sem KO, sem controle, lenta) → CENA DE DESTINO.
## SEM diretor (A5): nada cai sozinho; destruição fora dos jogadores só por evento escolhido (ex.: G01 Sirene).

var main: Node
var cfg: Dictionary            # cinemática da transição (demolicao.etapas)
var dcfg: Dictionary           # regra do modo (destruicao)
var etapa := 1                 # cena atual (ordem)
var destino := -1              # ordem da cena para onde a transição atual leva
var rota := ""                 # "moderada" | "total" (transição atual)
var n_cenas := 1
var state := "etapa"           # etapa · aviso · queda
var st_t := 0.0
var hole := Vector2.ZERO       # faixa x (px) do buraco por onde se cai da cena atual para a de destino
var ativo := true              # testes longos desligam a verificação/transição
var t_cena := 0.0              # tempo na cena atual (interno; nunca aparece no HUD)
var prox_verif := 0.0          # t_cena da próxima verificação
var verificacoes := 0          # verificações feitas nesta cena (testes/medição)
var progresso := 0.0           # destruição elegível da cena atual (0..1)
var visitadas: Array = [1]     # ordens das cenas por onde a luta passou (exploração nos resultados)

func setup(m: Node) -> void:
	main = m
	cfg = m.demo.cfg["etapas"]
	dcfg = MapaReg.modo_cfg(m.game_mode).get("destruicao", {"limiar_moderada": 0.5, "limiar_total": 0.9,
		"verificacao": {"vidas_base": 3, "primeira_base_s": 30, "por_vida_s": 20, "intervalo_frac": 0.3334, "vidas_min": 3, "vidas_max": 6}})
	n_cenas = 1
	while String(m.level.prop("etapa%d" % (n_cenas + 1), "")) != "":
		n_cenas += 1
	_nova_cena()

func _cena() -> Dictionary:
	return MapaReg.cena(main.game_mode, main.level.id, etapa)

## Tempos de verificação da cena atual: [1ª, intervalo] (s). Vidas 3–6 (A4); a cena pode trazer os seus.
func tempos() -> Array:
	var v: Dictionary = _cena().get("verificacao", {})
	var vc: Dictionary = dcfg["verificacao"]
	var vidas := clampi(int(main.demo.lives_setting), int(vc["vidas_min"]), int(vc["vidas_max"]))
	var p1 := float(v.get("primeira_s", float(vc["primeira_base_s"]) + float(vc["por_vida_s"]) * (vidas - int(vc["vidas_base"]))))
	return [p1, float(v.get("intervalo_s", p1 * float(vc["intervalo_frac"])))]

func _nova_cena() -> void:
	t_cena = 0.0
	verificacoes = 0
	progresso = 0.0
	prox_verif = float(tempos()[0])

func limiar_moderada() -> float:
	return float(dcfg["limiar_moderada"])

func limiar_total() -> float:
	return float(dcfg["limiar_total"])

## Ordem da cena de destino da rota a partir da cena atual (-1 = não há / pendente).
func destino_de(tipo: String) -> int:
	var d := MapaReg.rota(main.game_mode, main.level.id, etapa, tipo)
	if d < 0 and tipo == "total" and _cena().is_empty() and etapa < n_cenas:
		d = etapa + 1   # mapa sem manifesto (ferramentas/arenas de teste): sequência simples pelo .lvl
	return d if d > 0 and d <= n_cenas else -1

func tem_proxima() -> bool:
	return destino_de("moderada") > 0 or destino_de("total") > 0

func _ct():
	var ct = main.demo.canteiro
	return ct if ct != null and is_instance_valid(ct) else null

## A verificação: decide a rota pela destruição; sem rota possível, fica e marca a próxima.
func verificar() -> void:
	verificacoes += 1
	var tipo := ""
	if progresso >= limiar_total():
		tipo = "total"
	elif progresso >= limiar_moderada():
		tipo = "moderada"
	if tipo != "" and destino_de(tipo) > 0:
		_aviso(tipo)
	else:
		prox_verif = t_cena + float(tempos()[1])

func update(dt: float) -> void:
	if main.state != main.S.RUN or main.countdown > 0.0:
		return
	var lv = main.level
	var ct = _ct()
	match state:
		"etapa":
			progresso = ct.progresso(etapa) if ct != null else 0.0   # o manômetro mostra sempre
			if not ativo:
				return
			t_cena += dt
			if tem_proxima() and t_cena >= prox_verif:
				verificar()
		"aviso":
			st_t -= dt
			main.shake(1.5 + 4.0 * (1.0 - st_t / float(cfg["aviso_s"])))
			if fmod(st_t, 0.6) < dt:
				Audio.play("pistao_aviso", 0.7, -4.0)
			if st_t <= 0.0:
				_desaba()
		"queda" when rota == "moderada" and _deslize_dur > 0.0:
			_desliza(dt)
		"queda":
			st_t += dt
			main.events.gravity_mult *= float(cfg["gravidade_queda"])
			var a2: Rect2 = lv.etapa_rect(destino)
			var landed := true
			for r in main.robots:
				if not r.alive:
					continue
				r.invuln = maxf(r.invuln, 0.5)
				r.velocity.y = minf(r.velocity.y, float(cfg["queda_vmax"]))   # queda lenta e legível (cena)
				# arco natural: a velocidade de lado calculada no desabamento leva cada um para dentro do buraco
				if r.position.y < a2.position.y + 120.0:
					var vx: float = r.get_meta("queda_vx", 0.0)
					var tx := clampf(r.position.x, hole.x + 60.0, hole.y - 60.0)
					if absf(tx - r.position.x) > 1.0 and r.position.y > a2.position.y - 220.0:
						vx = clampf((tx - r.position.x) * 4.0, -float(cfg["funil_vel"]), float(cfg["funil_vel"]))   # correção final suave
					r.push_vx = vx
				if not (r.is_on_floor() and a2.has_point(r.position)):
					landed = false
			if (landed and st_t > 0.5) or st_t >= float(cfg["queda_max_s"]):
				_chega()

## Vitrines/vídeos: começa a transição já (se houver próxima cena).
func forcar(tipo := "total") -> void:
	if state == "etapa" and destino_de(tipo) > 0:
		_aviso(tipo)

func _aviso(tipo: String) -> void:
	rota = tipo
	destino = destino_de(tipo)
	var h := String(main.level.prop("buraco%d_%s" % [etapa, tipo], main.level.prop("buraco%d" % etapa, "") if tipo == "total" else "")).split(",")
	if h.size() >= 2:
		hole = Vector2(float(h[0]) * 64.0, float(h[1]) * 64.0)
	else:
		var an: Rect2 = main.level.etapa_rect(destino)
		hole = Vector2(an.position.x, an.end.x)
	state = "aviso"
	st_t = float(cfg["aviso_s"])
	main.demo.banner = String(_cena().get("aviso_" + tipo, "A OBRA VAI CEDER!"))
	main.demo.banner_t = st_t
	Audio.play("alarme", 0.8, 0.0)
	var ct = _ct()
	if ct != null:
		ct.warn_all(st_t, etapa)

## A cena inteira desaba: começa a queda para a próxima.
## ROTA MODERADA (storyboard aprovado, art/out/etapa_c/c7): só a frente cede, a laje inclina para a rua e todos
## ESCORREGAM num arco até as pranchas da cena de destino (ao lado), com a câmera abrindo para mostrar as duas.
## Sem controle e sem dano; cada um pousa num ponto diferente com piso firme (nunca teletransporte).
var _deslize_dur := 0.0

func _alvos_deslize(a2: Rect2, n: int) -> Array:
	var lv = main.level
	var cand := []
	for row in range(int(a2.position.y / 64.0) + 2, int(a2.end.y / 64.0)):
		for col in range(int(a2.position.x / 64.0) + 1, int(a2.end.x / 64.0) - 1):
			var c := Vector2i(col, row)
			if lv.is_solid(c) and lv.is_solid(c + Vector2i.LEFT) and lv.is_solid(c + Vector2i.RIGHT) \
					and not lv.is_solid(c + Vector2i.UP) and not lv.is_solid(c + Vector2i(0, -2)):
				cand.append(Vector2(col * 64.0 + 32.0, row * 64.0))
	if cand.is_empty():
		return []
	cand.sort_custom(func(p, q): return p.y < q.y if absf(p.y - q.y) > 1.0 else p.x < q.x)   # pranchas de cima primeiro
	var alto: Array = cand.filter(func(p): return p.y <= cand[0].y + 1.0)
	var usa: Array = alto if alto.size() >= n * 2 else cand
	var out := []
	for i in n:
		out.append(usa[int((i + 0.5) * usa.size() / float(n))])
	return out

func _desliza(dt: float) -> void:
	st_t += dt
	var k := clampf(st_t / _deslize_dur, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	for r in main.robots:
		if not r.alive or not r.has_meta("desliza"):
			continue
		var pth: Array = r.get_meta("desliza")
		var p0: Vector2 = pth[0]
		var p1: Vector2 = pth[1]
		var ctrl := Vector2((p0.x + p1.x) * 0.5, minf(p0.y, p1.y) - 360.0)
		var pos := p0.lerp(ctrl, e).lerp(ctrl.lerp(p1, e), e)
		r.invuln = maxf(r.invuln, 0.5)
		if k < 1.0:
			r.position = pos
			r.velocity = Vector2.ZERO
			r.reset_physics_interpolation()
		elif r.has_meta("desliza"):
			r.position = p1 - Vector2(0, 4)
			r.velocity = Vector2.ZERO
			r.remove_meta("desliza")
	if st_t >= _deslize_dur + 0.4:
		_chega()

func _desaba() -> void:
	var lv = main.level
	state = "queda"
	st_t = 0.0
	var ct = _ct()
	if ct != null:
		ct.collapse_all(etapa)
	main.events.stop_all()
	lv.ko_off = true
	lv.area = lv.etapa_rect(etapa).merge(lv.etapa_rect(destino))
	main.shake(18.0)
	Audio.play("terremoto", 1.0, 2.0)
	Audio.play("explosao", 0.6, -2.0)
	var a2: Rect2 = lv.etapa_rect(destino)
	var g: float = float(Data.ctrl["gravity"]) * float(cfg["gravidade_queda"])
	var vivos: Array = main.robots.filter(func(r): return r.alive)
	_deslize_dur = 0.0
	if rota == "moderada" and absf(a2.position.y - lv.etapa_rect(etapa).position.y) < a2.size.y * 0.5:   # destino AO LADO: escorrega
		_deslize_dur = float(cfg.get("deslize_s", 2.4))
		var alvos := _alvos_deslize(a2, vivos.size())
		vivos.sort_custom(func(p, q): return p.position.x < q.position.x)
		for i in vivos.size():
			var r = vivos[i]
			r.hanging = false
			r.invuln = maxf(r.invuln, 1.0)
			r.spell_lock = true
			r.set_meta("desliza", [r.position, alvos[i] if i < alvos.size() else a2.get_center()])
		_fim_desaba(vivos, a2)
		main.demo.banner = ""
		return
	for i in vivos.size():
		var r = vivos[i]
		r.hanging = false
		r.invuln = maxf(r.invuln, 1.0)
		r.spell_lock = true   # sem controle durante a queda (cena)
		# cada um cai num ponto diferente do buraco, no tempo que leva para chegar ao teto
		var tx: float = lerpf(hole.x + 140.0, hole.y - 140.0, (i + 0.5) / maxf(vivos.size(), 1.0))
		if absf(r.position.x - tx) < 200.0:
			tx = clampf(r.position.x, hole.x + 100.0, hole.y - 100.0)
		tx = _over_floor(tx, a2)   # cai sempre em cima de piso (nunca num vão)
		var dy: float = maxf(a2.position.y - r.position.y, 120.0)
		var vm := float(cfg["queda_vmax"])
		var d1 := vm * vm / (2.0 * maxf(g, 1.0))   # acelera até a velocidade limite e depois cai constante
		var tf := sqrt(2.0 * dy / maxf(g, 1.0)) if dy <= d1 else vm / maxf(g, 1.0) + (dy - d1) / vm
		r.set_meta("queda_vx", clampf((tx - r.position.x) / tf, -float(cfg["funil_vel"]), float(cfg["funil_vel"])))
		r.velocity.y = minf(r.velocity.y, -180.0)   # pulinho de susto antes de cair
	_fim_desaba(vivos, a2)

## Fim comum da virada: os mecanismos da cena que caiu somem; voo/transformações acabam; caixas vão para a cena nova.
func _fim_desaba(vivos: Array, a2: Rect2) -> void:
	var mc = main.demo.mecs
	if mc != null and is_instance_valid(mc):
		mc.desaba(etapa)
	var sp = main.demo.spells
	if sp != null and is_instance_valid(sp):
		for r in vivos:   # voo (jetpack) e transformações acabam: ninguém escapa da queda
			var sid: String = sp.flags(r).get("spell", "")
			if sid in ["T04", "T01", "T02", "T03", "T05", "T06", "T07"]:
				sp.clear(r)
		for b in sp.boxes:   # caixas da cena que caiu vão pelo buraco (nunca ficam em cima do teto da próxima)
			b["pos"].x = _over_floor(clampf(b["pos"].x, hole.x + 80.0, hole.y - 80.0), a2)
			b["vy"] = 0.0

## x mais perto de tx que tem piso embaixo na cena a2 (os vãos entre as lajes são KO).
func _over_floor(tx: float, a2: Rect2) -> float:
	var lv = main.level
	for k in 24:
		for sg in [1, -1]:
			var x: float = tx + sg * k * 32.0
			var c := int(floor(x / 64.0))
			for row in range(int(a2.position.y / 64.0) + 4, int(a2.end.y / 64.0)):
				if lv.is_solid(Vector2i(c, row)) and lv.is_solid(Vector2i(c - 1, row)) and lv.is_solid(Vector2i(c + 1, row)):
					return x
	return tx

## Todos pousaram na cena seguinte: câmera, KO e área de jogo passam para ela.
func _chega() -> void:
	var lv = main.level
	state = "etapa"
	etapa = destino
	destino = -1
	if not etapa in visitadas:
		visitadas.append(etapa)
	lv.etapa_n = etapa
	lv.area = lv.etapa_rect(etapa)
	lv.ko_off = false
	var cn := MapaReg.cena(main.game_mode, lv.id, etapa)
	main.demo.banner = String(cn.get("nome", "CENA %d" % etapa)).to_upper() + "!"
	main.demo.banner_t = 2.0
	main.shake(10.0)
	Audio.play("caixote_quebra", 0.6, 0.0)
	_nova_cena()
	for r in main.robots:
		r.spell_lock = false
		if r.has_meta("queda_vx"):
			r.remove_meta("queda_vx")
		if r.alive:
			r.invuln = maxf(r.invuln, float(cfg["invuln_chegada_s"]))
			main.dust(r.position, 1.2)
			if not lv.area.grow(64).has_point(r.position) or r.position.y < lv.area.position.y + 140.0:   # ficou fora ou em cima do teto: nasce embaixo
				main.demo.respawn(r)

## Testes/vitrines: leva a luta direto para a cena n (sem transição): área, KO e câmera passam para ela; todos renascem lá.
func pular_para(n: int) -> void:
	var lv = main.level
	state = "etapa"
	etapa = n
	destino = -1
	if not n in visitadas:
		visitadas.append(n)
	lv.etapa_n = n
	lv.area = lv.etapa_rect(n)
	lv.ko_off = false
	_nova_cena()
	for r in main.robots:
		if r.alive:
			main.demo.respawn(r)

## Nascimento na cena atual (nascimentos 1–4 na cena 1, 5–8 na cena 2, 9–12 na 3…).
func spawn_index(i: int) -> int:
	return i + 4 * (etapa - 1)
