extends CharacterBody2D
## Robô: velocidade calculada à mão com os números de data/controller.json + move_and_slide.
## Ordem por frame: input → timers → forças de peças → horizontal → pulo/parede → sustain → gravidade → mover → contatos.

const Vis := preload("res://player/robot_visual.gd")

var pid := 0
var color_idx := 0
var main: Node
var c: Dictionary
var active := false
var alive := true
var finished := false
var own_vx := 0.0
var ext_vx := 0.0
var coyote := 0.0
var buffer := 0.0
var var_jump := 0.0
var wall_lock := 0.0
var hammer_anim := 0.0        # (legado) tempo restante do golpe atual, para quem só quer saber "está golpeando"
# golpes: "rapido" (golpe rápido, botão hammer) ou "pesado" (marretada pesada, botão heavy); fases preparo → ativo → recuperação
var atk := ""
var atk_t := 0.0              # tempo desde o começo do golpe
var atk_hit := false          # o impacto já aconteceu (uma vez por golpe, no fim do preparo)
var atk_landed := false       # o impacto pegou alguém
var atk_cd := 0.0
var atk_dir := "frente"        # golpe rápido: "frente", "cima", "baixo" (no ar), "corrida"; pesado: "frente", "cima", "baixo"
var heavy_charge := 0.0        # A47: segundos de carga do golpe pesado (segurando)
var hit_mult := 1.0            # A47: multiplicador do golpe que está saindo (carga/crítico), lido por take_hit do alvo
var crash_cd := 0.0            # A47: arremessado contra parede/pouso forte racha a obra (1x a cada 0,4 s)
var combo_i := 0              # sequência de golpes rápidos: 0, 1, 2 (o 3º arremessa)
var combo_t := 0.0            # janela para encadear o próximo golpe
var heavy_cd := 0.0           # recarga só da marretada pesada (o golpe rápido segue livre)
# esquiva: impulso curto; nos primeiros instantes protege SÓ contra golpes de robôs (não contra cenário)
var dodge_t := 0.0            # tempo restante da esquiva
var dodge_len := 0.0
var dodge_dir := Vector2.ZERO
var dodge_carry := Vector2.ZERO   # parte do arremesso que continua valendo durante a esquiva
var dodge_cd := 0.0
var guard_t := 0.0            # janela de proteção contra golpes de robôs
var air_dodge := 1            # 1 esquiva por período no ar; volta SÓ ao pousar no chão
# arremesso: stun_t = sem controle (curto); depois o controle volta aos poucos (recover_t)
var recover_t := 0.0
var recover_len := 0.0
var hitstop := 0.0            # congelamento curtinho no impacto (atacante e atingido)
var land_v := 0.0             # velocidade de queda no quadro do pouso (força do amortecimento)
var hammer_left := 1
var facing := 1
var spring := false
var floor_piece = null
var was_on_floor := true
var spin := 0.0
var wall_sliding := false
var stun_t := 0.0            # atordoado: ignora o controle (pisão na cabeça, marretada)
var spell_speed := 1.0         # multiplicador de corrida de spells/transformações (modes/spells.gd)
var env_slow := 1.0            # mecanismos da fase (concreto fresco, água): corrida e pulo mais fracos; volta a 1 sozinho
var spell_push := 1.0          # multiplicador de empurrão recebido (armadura resiste)
var caught := false           # Fuga: foi pego pela tela ou pela lama (esse sai de vez)
var speed_k := 1.0            # multiplicador da corrida (Rei da Obra: o rei anda mais devagar)
var forced_t := 0.0           # movimento forçado (investida da furadeira, carga do laser, teletransporte)
var forced_vel := Vector2.ZERO
var grip := 1.0               # aderência na parede/borda (1 = cheia); gasta segurando, recarrega no chão
var wall_side := 0            # lado da parede em que está escorregando (desenho)
var frozen_t := 0.0           # congelado (A03 Canhão Criogênico): preso no gelo; agitar o direcional quebra mais rápido
var size_k := 1.0             # T07 Minirobô: tamanho (a hitbox acompanha o desenho)
var spell_hit := 1.0          # força dos golpes DESTE robô nos outros
var spell_jump := 1.0         # pulo de spells/transformações (T07 mecha Corredor, A36)
var spell_fly := false        # T04 jetpack ligado: sem gravidade (o jetpack controla a subida)
var spell_form := ""          # transformação que muda o movimento ("bola" = T03 rola com inércia)
var body_cs: CollisionShape2D
var hammer_out := false       # A07: a marreta está voando (sem marretada pesada até voltar)
var spell_lock := false       # mirando/viajando (C04 Teleporte): ignora movimento, pulo e golpes
var god := false              # Laboratório: invencível (não leva golpe)
var push_vx := 0.0            # empurrão externo deste quadro (ímã); zera a cada quadro
var mola_t := 0.0            # D03 Para-choque de Mola: quem bate é rebatido (golpe não passa)
var capacete_n := 0           # D05 Capacete de Aço: proteções restantes (cada golpe/tiro gasta 1, sem dano nem empurrão)
var poeira_t := 0.0          # D04 Cortina de Poeira: intocável (golpe e tiro passam direto); não ataca
var ancora_t := 0.0          # D01 Âncora de Contrapeso: ninguém empurra (golpe, vento, ímã, onda, gancho); anda devagar, não pula
var fall_reason := ""
var last_hit := 99.0
var stomp_immune := 0.0
var dmg := 0.0                # Amassômetro (%): quanto mais amassado, mais longe cada golpe arremessa
var invuln := 0.0             # invulnerável (começo da rodada, voltando da água/vida)
var air_jumps := 1            # pulo duplo do propulsor (recarrega no chão, na parede e na borda)
var plank_t := 0.0            # descendo por uma tábua fina (▼)
var drop_t := 0.0             # descendo pendurado no guindaste (desenho do cabo)
var hanging := false          # agarrado na borda de um caixote
var hang_dir := 0
var hang_t := 0.0
var hang_from := Vector2.ZERO   # posição de onde o robô veio ao agarrar (desliza até a borda, sem tranco)
var climb_t := -1.0             # subindo na borda (0..1); -1 = não está subindo
var climb_from := Vector2.ZERO
var climb_to := Vector2.ZERO
var climb_len := 0.16          # duração da subida (a do gancho C03 é mais longa: passa por cima da plataforma)
const GRAB_CHARS := ["d", "T", "#", "o", "<", ">", "F", "f", "B", "P"]   # bordas que dá para agarrar (fixas no mapa)
var last_cause := ""          # o que atingiu este robô por último (marretada, pisão, explosão, bola, chão quebrado...)
var last_attacker := -1       # quem causou (jogador), -1 = cenário      # depois de levar pisão, um tempo sem poder levar outro         # segundos desde o último golpe (para saber se caiu sozinho)
var wall_dust := 0.0
var vis: Node2D

func setup(p: int, col_idx: int, m: Node, model := 0) -> void:
	pid = p
	color_idx = col_idx
	main = m
	c = Data.ctrl
	hammer_left = 999
	collision_layer = 0
	collision_mask = 1 | 2 | (1 << (2 + p))
	var hb: Array = c["hitbox"]
	# caixa com os cantos chanfrados: desliza sobre a emenda de caixotes empilhados (o canto reto
	# "tropeçava" na emenda e o robô ficava preso no meio da parede, como se fosse chão)
	var cs := CollisionShape2D.new()
	var shp := ConvexPolygonShape2D.new()
	var w := float(hb[0]) / 2.0
	var h := float(hb[1])
	shp.points = PackedVector2Array([Vector2(-w + 4, -h), Vector2(w - 4, -h), Vector2(w, -h + 8), Vector2(w, -8),
		Vector2(w - 4, 0), Vector2(-w + 4, 0), Vector2(-w, -8), Vector2(-w, -h + 8)])
	cs.shape = shp
	add_child(cs)
	body_cs = cs
	floor_snap_length = 6.0
	floor_block_on_wall = false   # a Godot marcava a parede como "chão" e o robô descia grudado nela
	vis = Vis.new()
	vis.setup(col_idx, model)
	add_child(vis)

func rect() -> Rect2:
	var hb: Array = c["hitbox"]
	return Rect2(position.x - hb[0] * size_k / 2.0, position.y - hb[1] * size_k, hb[0] * size_k, hb[1] * size_k)

## T07: muda o tamanho do robô (colisão e hitbox juntas; os pés ficam no lugar).
func set_size(k: float) -> void:
	size_k = k
	if body_cs != null:
		body_cs.scale = Vector2(k, k)

func f(key: String) -> float:
	return float(c[key])

func _physics_process(dt: float) -> void:
	if main.paused:
		return
	if not alive:
		_dead_fall(dt)
		return
	if not active or finished:
		vis.tick(self, dt)
		return
	if hitstop > 0.0:
		hitstop -= dt
		vis.tick(self, dt)
		return
	var ix := _ix()
	var on_floor := is_on_floor()
	stun_t = maxf(stun_t - dt, 0.0)
	if stun_t <= 0.0:
		recover_t = maxf(recover_t - dt, 0.0)
	atk_cd = maxf(atk_cd - dt, 0.0)
	combo_t = maxf(combo_t - dt, 0.0)
	heavy_cd = maxf(heavy_cd - dt, 0.0)
	dodge_cd = maxf(dodge_cd - dt, 0.0)
	guard_t = maxf(guard_t - dt, 0.0)
	invuln = maxf(invuln - dt, 0.0)
	drop_t = maxf(drop_t - dt, 0.0) if not is_on_floor() else 0.0
	# ▼ em cima de uma tábua fina: desce por ela (desliga a colisão de mão única por um instante)
	if plank_t > 0.0:
		plank_t -= dt
		if plank_t <= 0.0 and collision_mask != 0:
			collision_mask |= 2
	elif on_floor and _held("down") and stun_t <= 0.0:
		var lv = main.level
		var under := Vector2i(int(position.x / 64.0), int((position.y + 4.0) / 64.0))
		if lv.ch_at(under) == "=":
			plank_t = 0.28
			collision_mask &= ~2
			position.y += 6.0
			velocity.y = 220.0
			vis.stretch()
			main.dust(position, 0.6)
	last_hit += dt
	if climb_t >= 0.0:
		_climb_update(dt)
		vis.tick(self, dt)
		return
	if forced_t > 0.0:
		forced_t -= dt
		hanging = false
		velocity = forced_vel
		own_vx = forced_vel.x
		move_and_slide()
		if forced_t <= 0.0 and forced_vel.y < -100.0:
			velocity.y = forced_vel.y * 0.4
		was_on_floor = is_on_floor()
		main.check_contacts(self)
		vis.tick(self, dt)
		return
	if hanging:
		_hang_update(dt)
		vis.tick(self, dt)
		return
	if dodge_t > 0.0:
		_dodge_update(dt)
		vis.tick(self, dt)
		return
	if spell_form == "bola":
		_ball_update(dt, ix, on_floor)
		return
	if _pressed("item") and main.demo.spells != null:
		main.demo.spells.press(self)   # botão de especial (spell equipada / troca segurando sobre a caixa)
	# timers
	coyote = maxf(coyote - dt, 0.0)
	buffer = maxf(buffer - dt, 0.0)
	wall_lock = maxf(wall_lock - dt, 0.0)
	hammer_anim = maxf(hammer_anim - dt, 0.0)
	if _pressed("jump"):
		buffer = f("jump_buffer_time")
	if on_floor and not spring:
		coyote = f("coyote_time")
	# forças de peças (esteira)
	ext_vx = 0.0
	if on_floor and floor_piece != null and is_instance_valid(floor_piece):
		ext_vx = floor_piece.belt_vx(self, ix)
	ext_vx += push_vx
	push_vx = 0.0
	if main.events != null and main.events.wind != 0.0 and hanging == false and invuln <= 0.0:   # voltando (protegido): o vento não empurra
		ext_vx += main.events.wind * (0.55 if on_floor else 1.2)   # evento Ventania (no chão segura mais)
	# horizontal
	if wall_lock <= 0.0:
		if ix != 0.0:
			facing = int(signf(ix))
		var a := f("accel_ground") if ix != 0.0 else f("decel_ground")
		if not on_floor:
			a *= f("air_mult")
		var tgt_k := 1.0
		if stun_t > 0.0:
			a *= 0.15   # arremessado, sem controle: segue o impulso
		elif recover_t > 0.0:
			# o controle volta aos poucos: corrige a rota sem cancelar o arremesso de uma vez
			var ar: Dictionary = c["arremesso"]
			a *= lerpf(float(ar["controle_inicial"]), 1.0, 1.0 - recover_t / maxf(recover_len, 0.01))
		if atk == "rapido":
			tgt_k = float(c["ataque_rapido"]["mov_mult"])
		elif atk == "pesado":
			var hp: Dictionary = c["ataque_pesado"]
			if not atk_hit:
				tgt_k = float(hp["mov_mult_preparo"])
			elif not atk_landed and atk_t > float(hp["preparo"]) + float(hp["ativo"]):
				tgt_k = float(hp["mov_mult_recupera_erro"])   # errou: fica exposto
		own_vx = move_toward(own_vx, tgt_k * ix * f("max_run") * speed_k * spell_speed * env_slow, a * dt)
	# pulo / parede
	var wall_dir := 0 if on_floor else _wall_dir()
	if on_floor:
		air_jumps = 1
		air_dodge = 1
	if buffer > 0.0 and not spring and not (atk == "pesado" and not atk_hit):
		if on_floor or coyote > 0.0:
			_jump(ix)
		elif wall_dir != 0 and grip > 0.05:
			_wall_jump(wall_dir)
			if main.mode == "demolicao":
				grip = maxf(grip - 0.2, 0.0)   # cada pulo de parede gasta um pouco
		elif air_jumps > 0 and stun_t <= 0.0 and main.mode == "demolicao":
			_air_jump(ix)
	# sustain: velocidade de subida mantida enquanto segura, até var_jump_time
	if var_jump > 0.0:
		if _held("jump"):
			velocity.y = minf(velocity.y, -_jump_speed())
			var_jump -= dt
		else:
			var_jump = 0.0
	# gravidade
	if var_jump <= 0.0 and not spell_fly:
		var g := f("gravity")
		if main.events != null:
			g *= main.events.gravity_mult   # evento Gravidade Baixa
		g *= float(get_meta("grav_cena", 1.0))   # transição de cena: queda lenta e legível só de quem ainda está caindo
		if not spring and _held("jump") and absf(velocity.y) < f("half_grav_threshold"):
			g *= 0.5
		velocity.y += g * dt
	if spring and velocity.y >= 0.0:
		spring = false
	var max_fall := f("fast_max_fall") if _held("down") else f("max_fall")
	wall_sliding = wall_dir != 0 and int(signf(ix)) == wall_dir and velocity.y > 0.0 and grip > 0.0
	wall_side = wall_dir if wall_sliding else 0
	if main.mode == "demolicao":
		var ad: Dictionary = main.demo.cfg["aderencia"]
		if on_floor:
			grip = move_toward(grip, 1.0, dt / float(ad["recarga_s"]))
		elif wall_sliding:
			grip = maxf(grip - dt / float(ad["parede_s"]), 0.0)
			if grip <= 0.0:
				Audio.play("parede", _pitch() * 0.8)   # escorregou: a mão soltou
	if wall_sliding:
		air_jumps = 1
		max_fall = f("wall_slide_speed")
		wall_dust -= dt
		if wall_dust <= 0.0:
			wall_dust = 0.08
			main.dust(position + Vector2(wall_dir * 24, -40), 0.5)
			Audio.play("parede", _pitch(), -4.0)
	velocity.y = minf(velocity.y, max_fall)
	# golpes e esquiva
	if _pressed("dodge") and _can_dodge(on_floor):
		_start_dodge(on_floor)
		vis.tick(self, dt)
		return
	if atk == "" and atk_cd <= 0.0 and poeira_t <= 0.0:   # D04: dentro da poeira não ataca
		if _pressed("heavy"):
			if heavy_cd <= 0.0 and not hammer_out:
				_start_attack("pesado")
			else:
				vis.denied()   # ainda recarregando: a marreta treme e faz "clanc"
		elif _pressed("hammer"):
			_pick_quick(on_floor)
	# acertou o golpe rápido: pode encadear o próximo já na recuperação (sequência de 3)
	if atk == "rapido" and atk_hit and atk_landed and combo_i < 2 and _pressed("hammer"):
		combo_t = float(c["combo"]["janela_s"])
		atk = ""
		_pick_quick(on_floor)
	if atk != "":
		_attack_update(dt, on_floor)
	# mover
	land_v = velocity.y
	if ancora_t > 0.0:   # D01: preso ao contrapeso — só o próprio passo (devagar), nada de fora move
		ext_vx = 0.0
		var vmax := f("max_run") * spell_speed
		own_vx = clampf(own_vx, -vmax, vmax)
		if on_floor:
			velocity.y = maxf(velocity.y, 0.0)
	velocity.x = own_vx + ext_vx
	_corner_correction(dt)
	var vx_pre := velocity.x
	crash_cd = maxf(crash_cd - dt, 0.0)
	move_and_slide()
	if is_on_wall() and (stun_t > 0.0 or recover_t > 0.0) and absf(vx_pre) > 620.0 and crash_cd <= 0.0 and main.mode == "demolicao":
		crash_cd = 0.4   # A47: ARREMESSADO contra parede/bloco: racha
		main.demo.luta_quebra(self, position + Vector2(signf(vx_pre) * 30.0, -36.0), 2 if absf(vx_pre) > 1000.0 else 1)
	if is_on_wall():
		var n := get_wall_normal()
		if signf(own_vx) == -signf(n.x):
			own_vx = 0.0
	if is_on_ceiling():
		var_jump = 0.0
		velocity.y = maxf(velocity.y, 0.0)
	floor_piece = null
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var o := col.get_collider()
		if o != null and o.has_meta("piece") and col.get_normal().y < -0.7:
			floor_piece = o.get_meta("piece")
	if not is_on_floor() and main.mode == "demolicao":
		_try_grab(ix)
	var landed := is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()
	if landed:
		_on_landed()
	if floor_piece != null and is_instance_valid(floor_piece):
		floor_piece.on_stand(self)
	main.check_contacts(self)
	vis.tick(self, dt)

func _held(a: String) -> bool:
	return stun_t <= 0.0 and not spell_lock and PlayerInput.held(pid, a)

func _pressed(a: String) -> bool:
	return stun_t <= 0.0 and not spell_lock and PlayerInput.pressed(pid, a)

func _ix() -> float:
	return 0.0 if stun_t > 0.0 or spell_lock else PlayerInput.axis_x(pid)

func _jump_speed() -> float:
	var js := float(c["jump_speed"]) * spell_jump
	return js * (0.55 + 0.45 * env_slow)

## T03 Bola de Demolição (revista 2026-11-25: "só vai para a frente, difícil de controlar, não pula"): ainda rola com
## peso, mas acelera e freia firme, vira rápido (contra-esterço forte), PULA de verdade (~2 tiles, com tolerância de
## borda e de aperto) e tem um quique no ar (pulo duplo).
func _ball_update(dt: float, ix: float, on_floor: bool) -> void:
	var bc: Dictionary = main.demo.cfg["spells"]["T03"]
	if ix != 0.0:
		var same := signf(ix) == signf(own_vx) or absf(own_vx) < 10.0
		own_vx = move_toward(own_vx, ix * float(bc["vel_max"]), float(bc["acel"]) * (1.0 if same else float(bc["contra_mult"])) * dt)
		facing = int(signf(ix))
	else:
		own_vx = move_toward(own_vx, 0.0, float(bc["freio"]) * dt)
	coyote = float(bc["tolerancia_s"]) if on_floor else maxf(coyote - dt, 0.0)
	if _pressed("jump"):
		buffer = float(bc["tolerancia_s"])
	else:
		buffer = maxf(buffer - dt, 0.0)
	if on_floor:
		air_jumps = 1
	if buffer > 0.0 and (on_floor or coyote > 0.0):
		velocity.y = -float(bc["pulo"])
		buffer = 0.0
		coyote = 0.0
		vis.stretch()
		Audio.play("ba_salto")
	elif buffer > 0.0 and air_jumps > 0 and not on_floor:
		velocity.y = -float(bc["pulo"]) * float(bc["pulo_ar_mult"])
		air_jumps -= 1
		buffer = 0.0
		main.ring_fx(position, 0.8)
		Audio.play("ba_salto_duplo")
	velocity.y = minf(velocity.y + f("gravity") * dt, f("max_fall"))
	velocity.x = own_vx + push_vx
	push_vx = 0.0
	var vx_before := own_vx
	move_and_slide()
	if is_on_wall() and absf(vx_before) > 200.0:
		own_vx = -vx_before * 0.4   # bate e volta
		main.shake(4.0)
		if main.demo.spells != null:
			main.demo.spells.ball_bump(self, vx_before)
	var landed := is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()
	if landed:
		main.dust(position, 0.8)
	main.check_contacts(self)
	vis.tick(self, dt)

## Estado visual da spell (arma na mão, transformação…), montado por modes/spells.gd.
func fx_flags() -> Dictionary:
	return main.demo.spells.flags(self) if main.mode == "demolicao" and main.demo.spells != null else {}

## Pulo duplo do propulsor (um no ar; recarrega no chão, na parede e na borda).
func _air_jump(ix: float) -> void:
	air_jumps -= 1
	Audio.play("ba_salto_duplo")
	velocity.y = -_jump_speed() * float(main.demo.cfg["recuperacao"]["pulo_duplo"])
	own_vx = maxf(absf(own_vx), absf(ix) * f("max_run") * 0.8) * (signf(ix) if ix != 0.0 else signf(own_vx))
	var_jump = f("var_jump_time") * 0.6
	buffer = 0.0
	vis.double_jump()
	main.dust(position + Vector2(0, -6), 0.7)

## Agarra a quina de um caixote: caindo, segurando na direção dela, com as mãos na altura do topo.
## Só bordas fixas do mapa (não plataforma que anda nem gangorra) e com espaço para ficar em pé em cima.
func _try_grab(ix: float) -> void:
	if velocity.y < -40.0 or stun_t > 0.0 or ix == 0.0 or PlayerInput.held(pid, "down") or grip < 0.15:
		return
	var dir := int(signf(ix))
	var lv = main.level
	var cell := Vector2i(int(floor((position.x + dir * 32.0) / 64.0)), int(floor((position.y - 66.0) / 64.0)))
	if not (lv.ch_at(cell) in GRAB_CHARS or (lv.grab_solid.is_valid() and lv.grab_solid.call(cell))) or not _room_above(cell):
		return
	var top := cell.y * 64.0
	var head := position.y - 72.0
	if head < top - 26.0 or head > top + 16.0:
		return
	var target := Vector2(cell.x * 64.0 + (-24.0 if dir > 0 else 64.0 + 24.0), top + 58.0)
	for yy in [target.y - 70.0, target.y - 36.0, target.y - 2.0]:
		for xx in [target.x - 22.0, target.x + 22.0]:
			if lv.is_solid(Vector2i(int(floor(xx / 64.0)), int(floor(yy / 64.0)))):
				return   # a posição de pendurar está ocupada
	hanging = true
	wall_sliding = false   # não está mais escorregando: o desenho vira para a parede
	wall_side = 0
	hang_dir = dir
	hang_t = 0.0
	hang_from = position
	facing = dir
	air_jumps = 1
	velocity = Vector2.ZERO
	own_vx = 0.0
	position = target
	reset_physics_interpolation()
	vis.hang_snap = hang_from - target   # o desenho desliza da posição antiga até a borda
	Audio.play("parede", _pitch())

## Em cima da célula cabe o robô inteiro (72 px = 2 células livres; fora do mapa no alto conta como livre).
func _room_above(cell: Vector2i) -> bool:
	var lv = main.level
	for k in [1, 2]:
		var c2 := cell + Vector2i(0, -k)
		if c2.y < 0 or lv.is_solid(c2):
			return false
	return true

func _hang_update(dt: float) -> void:
	hang_t += dt
	velocity = Vector2.ZERO
	var lv = main.level
	var cell := Vector2i(int(floor((position.x + hang_dir * 32.0) / 64.0)), int(floor((position.y - 58.0) / 64.0)))
	var max_t := float(main.demo.cfg["recuperacao"]["borda_max_s"])
	grip = maxf(grip - dt / max_t, 0.0)   # segurar a borda cansa (o medidor acima da cabeça esvazia)
	if not lv.is_solid(cell) or grip <= 0.0 or PlayerInput.pressed(pid, "down") or PlayerInput.axis_x(pid) == -hang_dir:
		hanging = false   # caixote quebrou, cansou ou soltou
		if PlayerInput.axis_x(pid) == -hang_dir:
			own_vx = -hang_dir * 220.0   # soltou para trás: afasta um pouco da parede
		return
	if PlayerInput.pressed(pid, "jump") or PlayerInput.pressed(pid, "up"):
		if not _room_above(cell):
			# sem espaço para subir: pula para longe da parede
			hanging = false
			velocity.y = -_jump_speed() * 0.8
			own_vx = -hang_dir * f("wall_jump_h_speed") * 0.7
			wall_lock = f("wall_jump_lock_time")
			Audio.play("ba_salto")
			return
		# escalada animada: sobe e passa por cima da quina (~0,16 s), sem teletransporte
		hanging = false
		climb_t = 0.0
		climb_from = position
		climb_to = Vector2(cell.x * 64.0 + 32.0 - hang_dir * 6.0, cell.y * 64.0 - 1.0)
		Audio.play("ba_salto", 1.0, -4.0)
		vis.stretch()

## Sobe por cima de uma plataforma/borda até `to` (gancho C03): mesma animação da escalada, mais longa.
func climb_onto(to: Vector2, dir: int) -> void:
	hanging = false
	hang_dir = dir
	facing = dir
	climb_from = position
	climb_to = to
	climb_len = clampf(position.distance_to(to) / 900.0, 0.16, 0.32)
	climb_t = 0.0
	air_jumps = 1
	vis.stretch()

func _climb_update(dt: float) -> void:
	climb_t = minf(climb_t + dt / climb_len, 1.0)
	var k := climb_t
	# primeiro sobe (corpo passa da quina), depois avança por cima
	var up := clampf(k / 0.6, 0.0, 1.0)
	var fwd := clampf((k - 0.35) / 0.65, 0.0, 1.0)
	var y := lerpf(climb_from.y, climb_to.y, 1.0 - pow(1.0 - up, 2.0))
	var x := lerpf(climb_from.x, climb_to.x, fwd * fwd * (3.0 - 2.0 * fwd))
	position = Vector2(x, y)
	velocity = Vector2.ZERO
	if climb_t >= 1.0:
		climb_t = -1.0
		climb_len = 0.16
		position = climb_to
		velocity = Vector2(0, -120)
		own_vx = hang_dir * 160.0
		main.dust(position, 0.6)

## Golpe com o Amassômetro: soma dano e o empurrão cresce com ele. kind = chave em demolicao.amassometro.
## Retorna false se não pegou (invulnerável ou capacete).
const ROBOT_HITS := ["rapido", "pesado", "martelao", "marretada", "combo", "combo_final", "cima", "baixo", "corrida",
	"spell_punho", "spell_gelo", "spell_fogo", "spell_explosao",
	"spell_laser", "spell_sismo", "spell_cratera", "spell_rebite", "spell_estaca", "spell_bumerangue", "spell_mola",
	"spell_gancho", "spell_carga", "spell_viga",
	"spell_bola", "spell_empilhadeira", "spell_broca", "spell_solda", "spell_broca_dash", "spell_arrancada", "spell_raio1", "spell_raio2", "spell_raio3", "mecha_leve", "mecha_pesado"]

const LEVES := ["rapido", "combo", "combo_final", "cima", "baixo", "corrida"]

func take_hit(dir: int, kind: String, by := -1) -> bool:
	if invuln > 0.0 or god:
		return false
	if poeira_t > 0.0:   # D04: passa direto
		return false
	if mola_t > 0.0 and by >= 0 and by != pid:   # D03: rebate quem bateu
		if main.demo.spells != null:
			main.demo.spells.bumper_rebate(self, by)
		return false
	if capacete_n > 0 and main.demo.spells != null:   # D05: o capacete de aço absorve
		main.demo.spells.helmet_absorb(self, by)
		return false
	if guard_t > 0.0 and by >= 0 and by != pid and kind in ROBOT_HITS:
		_dodged()
		return false
	if atk == "pesado" and not atk_hit and heavy_charge > 0.0 and kind in LEVES:   # A47: carregando = armadura contra o leve
		var am0: Dictionary = main.demo.cfg["amassometro"]
		dmg += float(am0[kind]["dano"]) * 0.5
		main.float_text(position + Vector2(0, -100), "+%d%%" % maxi(int(float(am0[kind]["dano"]) * 0.5), 1), main.dmg_color(dmg))
		main.float_text(position + Vector2(0, -150), "ARMADURA!", Color("#ffd23a"))
		vis.hurt(0.2, dir)
		return true
	last_hit = 0.0
	last_cause = {"marretada": "marretada", "martelao": "marretada", "explosao": "explosão", "bola": "bola",
		"spell_punho": "punho pneumático", "spell_gelo": "canhão criogênico", "spell_fogo": "armadura fornalha",
		"spell_explosao": "fornalha explodiu", "spell_laser": "laser de corte", "spell_sismo": "marreta sísmica", "spell_cratera": "cratera da marreta sísmica",
		"spell_rebite": "rebite", "spell_estaca": "bate-estaca", "spell_bumerangue": "marreta-bumerangue",
		"spell_mola": "canhão de molas", "spell_gancho": "gancho", "spell_carga": "carga de demolição", "spell_viga": "viga do guindaste",
		"spell_bola": "bola de demolição", "spell_empilhadeira": "empilhadeira", "spell_broca": "broca", "spell_solda": "solda", "spell_broca_dash": "dash da broca", "spell_raio1": "para-raios", "spell_raio2": "para-raios", "spell_raio3": "para-raios", "mecha_leve": "golpe de mecha", "mecha_pesado": "golpe pesado de mecha",
		"evento_entulho": "entulho", "evento_rebite": "chuva de rebites", "evento_viga": "viga do cabo rompido", "evento_carga": "carga do guindaste",
		"mec_tubo": "tubo rolando", "mec_serra": "serra de bancada", "mec_estaca": "bate-estaca", "mec_vagonete": "vagonete", "mec_choque": "choque"}.get(kind, kind)
	last_attacker = by
	hanging = false
	var am: Dictionary = main.demo.cfg["amassometro"]
	var k: Dictionary = am[kind]
	# modo mecha (A33): quem está no mecha recebe menos dano/empurrão; quem ataca de mecha causa mais
	var sp_m = main.demo.spells if main.demo != null else null
	var mv: Dictionary = sp_m.mecha_cfg(self) if sp_m != null else {}
	var ma: Dictionary = sp_m.mecha_cfg(main.robots[by]) if sp_m != null and by >= 0 and by < main.robots.size() and by != pid else {}
	var hm: float = main.robots[by].hit_mult if by >= 0 and by < main.robots.size() and by != pid else 1.0
	var dano := float(k["dano"]) * float(mv.get("recebe", 1.0)) * float(ma.get("causa", 1.0)) * hm
	dmg += dano
	var kx := minf(float(k["kx"]) + dmg * float(k["kx_por"]), float(am["max_kx"]))
	var ky := float(k["ky"]) + dmg * float(k["ky_por"])
	var push := float(mv.get("empurrao", spell_push)) * float(ma.get("causa", 1.0)) * hm
	if ancora_t > 0.0:
		push = 0.0   # D01 Âncora: o dano conta, o empurrão não
	kx *= push   # armadura/mecha: empurrão bem menor
	ky *= push
	if by >= 0 and by < main.robots.size():
		kx *= main.robots[by].spell_hit   # minirobô bate mais fraco
		ky *= main.robots[by].spell_hit
	if frozen_t > 0.0 and main.demo.spells != null:
		# pancada em quem está congelado: o gelo estilhaça e o empurrão é maior
		var mult := float(main.demo.cfg["spells"]["A03"]["quebra_mult"])
		kx = minf(kx * mult, float(am["max_kx"]) * 1.2)
		ky *= mult
		main.demo.spells.shatter(self)
	if main.demo.rule() == "fuga":   # na Fuga o empurrão atrapalha, mas não decide sozinho
		kx *= 0.6
		ky *= 0.7
	var ar: Dictionary = c["arremesso"]
	var stun := minf(float(ar["sem_controle_base"]) + dmg * float(ar["sem_controle_por"]), float(ar["sem_controle_max"]))
	if ancora_t > 0.0:
		stun = minf(stun, 0.12)   # ancorado: só o tranco, segue no controle
	main.float_text(position + Vector2(0, -100), "+%d%%" % maxi(int(round(dano)), 1), main.dmg_color(dmg))
	_apply_knock(dir, kx, ky, stun)
	vis.hurt(clampf((kx + ky) / 1400.0, 0.25, 1.0), dir)
	PlayerInput.vibrate(pid, 0.35 + dmg / 300.0, 0.15 + dmg / 250.0, 0.12 + minf(dmg, 150.0) / 1000.0)
	return true

## Empurrão direto (modo Clássico e mecânicas antigas).
func knock(dir: int, vx: float, vy: float, stun: float) -> void:
	if invuln > 0.0:
		return
	last_hit = 0.0
	hanging = false
	_apply_knock(dir, vx, vy, stun)

func _apply_knock(dir: int, vx: float, vy: float, stun: float) -> void:
	own_vx = dir * vx
	velocity.y = -vy
	var_jump = 0.0   # sem "ai!" a cada golpe (barulho demais); a pancada já diz que acertou
	stun_t = maxf(stun_t, stun)
	recover_len = float(c["arremesso"]["retorno_s"])
	recover_t = recover_len
	# golpe interrompe o que estava fazendo (marretada no preparo: INTERROMPIDO!)
	if atk == "pesado" and not atk_hit:
		_cancel_heavy()
		main.float_text(position + Vector2(0, -140), "INTERROMPIDO!", Color("#f2c84b"))
	atk = ""
	hammer_anim = 0.0
	dodge_t = 0.0
	hanging = false
	vis.launch(Vector2(dir * vx, -vy))

## Tom dos sons do robô por jogador (P1 mais grave → P4 mais agudo).
func _pitch() -> float:
	return 0.92 + pid * 0.08

func _jump(ix: float) -> void:
	Audio.play("ba_salto")
	velocity.y = -_jump_speed()
	own_vx += ix * f("jump_h_boost")
	var_jump = f("var_jump_time")
	buffer = 0.0
	coyote = 0.0
	vis.stretch()
	main.dust(position)

func _wall_jump(wd: int) -> void:
	Audio.play("ba_salto")
	velocity.y = -_jump_speed()
	own_vx = -wd * f("wall_jump_h_speed")
	facing = -wd
	wall_lock = f("wall_jump_lock_time")
	var_jump = f("var_jump_time")
	buffer = 0.0
	vis.stretch()

func _wall_dir() -> int:
	for d in [1, -1]:
		if test_move(global_transform, Vector2(2 * d, 0)) and _real_wall(d):
			return d
	return 0

## Na Demolição, a parede invisível da borda do mapa não serve para escorregar/pular (parecia grudar no nada).
func _real_wall(d: int) -> bool:
	if main.mode != "demolicao":
		return true
	var lv = main.level
	var x := int(floor((position.x + d * 27.0) / 64.0))
	var hits := 0
	for yy in [position.y - 60.0, position.y - 36.0, position.y - 10.0]:
		var c := Vector2i(x, int(floor(yy / 64.0)))
		var ch: String = lv.ch_at(c)
		if ch == "I":
			return false
		if lv.is_solid(c):
			hits += 1
	return hits > 0 or lv.extra_solid.is_valid()   # plataforma que anda também é parede

func _corner_correction(dt: float) -> void:
	if velocity.y >= 0.0:
		return
	var up := Vector2(0, velocity.y * dt)
	if not test_move(global_transform, up):
		return
	for s in range(1, int(f("corner_correction_px")) + 1):
		for d in [-1, 1]:
			var shift := Vector2(d * s, 0)
			if not test_move(global_transform, shift) and not test_move(global_transform.translated(shift), up):
				position.x += d * s
				return

func launch(tiles: float) -> void:
	Audio.play("pulo_mola", _pitch())
	# + g·dt/2 compensa a integração por passos (altura final = tiles)
	velocity.y = -sqrt(2.0 * f("gravity") * tiles * 64.0) - f("gravity") / (2.0 * Engine.physics_ticks_per_second)
	spring = true
	var_jump = 0.0
	coyote = 0.0
	buffer = 0.0
	vis.stretch()

## Eliminado: o robô desmonta em peças (main.break_robot) e some.
func eliminate() -> void:
	PlayerInput.vibrate(pid, 0.8, 1.0, 0.45)
	if not get_meta("ko_fora", false):   # KO fora da arena já tocou a explosão (main.ko_blast): som único
		Audio.play("eliminado", _pitch())
	remove_meta("ko_fora")
	alive = false
	active = false
	collision_mask = 0
	main.break_robot(self)
	visible = false

func _dead_fall(_dt: float) -> void:
	pass

## Chegou: dá um pulinho de alegria, anda até o meio do elevador e some lá dentro.
func finish() -> void:
	finished = true
	active = false
	vis.expression = "vitoria"
	Audio.play("elevador")
	Audio.voice("voz_eba", vis.model)
	var g: Rect2 = main.level.goal_rect
	var floor_pos := Vector2(g.get_center().x, g.end.y)
	facing = 1 if floor_pos.x >= position.x else -1
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# desce até o chão (se chegou pulando), pulinho de alegria no centro da porta, entra e some
	tw.tween_property(self, "position", floor_pos, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(vis, "position", Vector2(0, -16), 0.13).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(vis, "position", Vector2.ZERO, 0.13).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.25)
	tw.parallel().tween_property(self, "modulate", Color(0.35, 0.3, 0.3, 0.0), 0.25)
	tw.tween_callback(func(): visible = false)

# ---------------------------------------------------------------- golpes, esquiva e pouso

## Começa um golpe. O impacto acontece no fim do preparo (sincronizado com a animação).
func _start_attack(kind: String) -> void:
	atk = kind
	atk_t = 0.0
	heavy_charge = 0.0
	atk_hit = false
	atk_landed = false
	hammer_anim = _atk_total()
	# sem som no balanço: a pancada toca APENAS no impacto confirmado (modes/demolicao.gd); golpe no vazio é mudo
	if kind != "rapido":
		var_jump = minf(var_jump, 0.04)
	vis.attack(kind)

## Golpe rápido com direção (▲ cima, ▼ no ar = baixo, correndo = investida) ou a sequência de 3 para a frente.
func _pick_quick(on_floor: bool) -> void:
	var cc: Dictionary = c["combo"]
	if PlayerInput.held(pid, "up"):
		atk_dir = "cima"
	elif not on_floor and PlayerInput.held(pid, "down"):
		atk_dir = "baixo"
	elif on_floor and absf(own_vx) > f("max_run") * float(cc["corrida_vel"]):
		atk_dir = "corrida"
		own_vx += facing * 220.0
	else:
		atk_dir = "frente"
	if atk_dir == "frente":
		combo_i = (combo_i + 1) % 3 if combo_t > 0.0 else 0
		if on_floor:   # A47: avanço curto até o rival (acertar fica fácil)
			own_vx = facing * maxf(own_vx * facing, float(c["ataque_rapido"]["avanco_px_s"]))
	else:
		combo_i = 0
	combo_t = 0.0
	_start_attack("rapido")

func _atk_cfg() -> Dictionary:
	return c["ataque_rapido"] if atk == "rapido" else c["ataque_pesado"]

func _atk_total() -> float:
	var ac := _atk_cfg()
	var rec := float(ac["recupera"]) if atk == "rapido" else (float(ac["recupera_acerto"]) if atk_landed else float(ac["recupera_erro"]))
	return float(ac["preparo"]) + float(ac["ativo"]) + rec

func _attack_update(dt: float, on_floor: bool) -> void:
	atk_t += dt
	var ac := _atk_cfg()
	# A47: segurando o pesado, o preparo fica no ponto alto e CARREGA (até carga_max_s)
	if atk == "pesado" and not atk_hit and atk_t >= float(ac["preparo"]) * 0.85 and _held("heavy") and heavy_charge < float(ac["carga_max_s"]):
		heavy_charge += dt
		atk_t = float(ac["preparo"]) * 0.85
		hammer_anim = _atk_total()
		return
	if not atk_hit and atk_t >= float(ac["preparo"]):
		if atk == "pesado":   # direção escolhida na hora do golpe
			atk_dir = "cima" if PlayerInput.held(pid, "up") else ("baixo" if (not on_floor and PlayerInput.held(pid, "down")) else "frente")
		atk_hit = true
		atk_landed = main.try_attack(self, atk)
		if atk == "pesado" and on_floor:
			own_vx += facing * float(ac["avanco_px_s"])   # o peso do golpe leva o corpo junto
	hammer_anim = maxf(_atk_total() - atk_t, 0.0)
	if atk_t >= _atk_total():
		if atk == "rapido" and atk_landed:
			combo_t = float(c["combo"]["janela_s"])
		if atk == "pesado":
			heavy_cd = float(ac["recarga"])
		atk = ""
		hammer_anim = 0.0
		atk_cd = float(c["ataque_rapido"]["recarga"])

func _can_dodge(on_floor: bool) -> bool:
	if dodge_cd > 0.0 or stun_t > 0.0 or hanging or climb_t >= 0.0:
		return false
	# a esquiva cancela o PREPARO da marretada (finta); depois do impacto, não
	if (atk == "pesado" and atk_hit and not atk_landed) or (atk == "rapido" and not atk_hit):
		return false
	return on_floor or air_dodge > 0

func _start_dodge(on_floor: bool) -> void:
	var dc: Dictionary = c["esquiva"]
	var ix := PlayerInput.axis_x(pid)
	var iy := 0.0
	if not on_floor:
		iy = (1.0 if PlayerInput.held(pid, "down") else 0.0) - (1.0 if PlayerInput.held(pid, "up") else 0.0)
	var d := Vector2(ix, iy)
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	dodge_dir = d.normalized()
	if dodge_dir.x != 0.0:
		facing = int(signf(dodge_dir.x))
	# arremessado: parte do impulso continua (a esquiva ajuda, mas não anula um golpe forte)
	dodge_carry = Vector2(own_vx, velocity.y) * (0.6 * recover_t / maxf(recover_len, 0.01) if recover_t > 0.0 else 0.0)
	dodge_len = float(dc["duracao"])
	dodge_t = dodge_len
	guard_t = float(dc["protecao"])
	dodge_cd = float(dc["recarga"])
	if not on_floor:
		air_dodge = 0
	if atk == "pesado":
		_cancel_heavy()
	atk = ""
	hammer_anim = 0.0
	var_jump = 0.0
	buffer = 0.0
	Audio.play("ba_dash_solo" if on_floor else "ba_dash_aereo")   # dash e esquiva são a MESMA ação: um som só
	main.dust(position + Vector2(-dodge_dir.x * 14.0, -4.0), 0.6 if on_floor else 0.4)
	vis.dodge(dodge_dir, on_floor)

func _dodge_update(dt: float) -> void:
	var dc: Dictionary = c["esquiva"]
	dodge_t = maxf(dodge_t - dt, 0.0)
	var k := 1.0 - dodge_t / maxf(dodge_len, 0.01)          # 0 → 1
	var spd := float(dc["vel"]) * lerpf(1.0, float(dc["vel_final"]), k * k)
	velocity = dodge_dir * spd + dodge_carry * (1.0 - k * 0.5)
	if was_on_floor and dodge_dir.y >= 0.0:
		velocity.y = maxf(velocity.y, 0.0) + 40.0   # no chão: desliza grudado (desce rampa/borda naturalmente)
	land_v = velocity.y
	move_and_slide()   # colide normalmente: a esquiva não atravessa parede nem chão
	own_vx = velocity.x
	if is_on_wall():
		own_vx = 0.0
	if dodge_t <= 0.0:
		own_vx = velocity.x
		velocity.y *= float(dc["vel_final"])
	var landed := is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()
	if is_on_floor():
		air_dodge = 1
		air_jumps = 1
	if landed:
		_on_landed()
	main.check_contacts(self)

## Esquivou de um golpe de robô na janela de proteção.
func _dodged() -> void:
	Audio.play("menu_mover", 1.5, -2.0)
	main.float_text(position + Vector2(0, -112), "ESQUIVOU!", Color.WHITE)
	vis.dodged_flash = 1.0

func _on_landed() -> void:
	air_dodge = 1
	var hard := clampf((land_v - 300.0) / 900.0, 0.0, 1.0)
	if land_v > 1050.0 and (stun_t > 0.0 or recover_t > 0.0) and crash_cd <= 0.0 and main.mode == "demolicao":
		crash_cd = 0.4   # A47: POUSO forte de quem foi arremessado racha o chão
		main.demo.luta_quebra(self, position + Vector2(0, 10), 1)
	if hard > 0.5 and (stun_t > 0.0 or recover_t > 0.0):   # só quem foi ARREMESSADO e bate no chão; pouso comum é mudo
		Audio.play("ba_aterrissa_pesada", 1.0, -4.0)
	vis.land(hard, stun_t > 0.0 or recover_t > 0.0)
	main.dust(position, 1.0 + hard * 0.8)

## Marretada cancelada no preparo (esquiva ou golpe do rival): paga parte da recarga.
func _cancel_heavy() -> void:
	var hp: Dictionary = c["ataque_pesado"]
	heavy_cd = float(hp["recarga"]) * float(hp["recarga_cancelada"])
	vis.heavy_cancel()
