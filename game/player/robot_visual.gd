extends Node2D
## Visual cut-out do robô (estilo papel e giz). Partes em PNG 4x (art/out/game/robo); pernas e braços desenhados aqui.
## A animação é toda por código e só lê o estado do robô: nunca atrasa nem trava o controle.
## Tela das partes: 128x128 (px de jogo), origem do robô (pés no chão) em (64,120). Frente local = +x.
##
## Pose (Dictionary) usada pelo desenho:
##   expr, body_off (Vector2), lean (rad, + = para a frente), feet [Vector2, Vector2] (deslocamento dos pés),
##   knee [Vector2, Vector2] (dobra das pernas), hb_off / hf_off (mão de trás / da frente), hammer_ang, ant (antena)

const Kit := preload("res://ui/kit.gd")
const ORIGIN := Vector2(64, 120)
const GRIP := Vector2(32, 56)          # pega dentro da textura da marreta (64x64)
const HAMMER_REST := 0.35
const STRIDE := 46.0
## Spells (modes/spells.gd). Armas: [textura, tamanho na tela, pega e bico (px da arte de design)]. Com arma, a marreta
## vai para as costas e o robô carrega a arma com as duas mãos; ao dar golpe, a arma vai para as costas e a marreta volta.
const SPELL_TOOLS := {"A01": ["s01_canhao", Vector2(52, 26), Vector2(30, 34), Vector2(100, 33)],
	"A03": ["s03_canhao", Vector2(56, 28), Vector2(26, 40), Vector2(124, 31)],
	"C01": ["s06_ima", Vector2(44, 31), Vector2(14, 40), Vector2(106, 40)],
	"A02": ["s02_laser", Vector2(58, 29), Vector2(19, 50), Vector2(122, 31)],
	"A05": ["s05_rebiteira", Vector2(56, 28), Vector2(40, 52), Vector2(127, 25)],
	"A08": ["s20_canhao", Vector2(60, 30), Vector2(25, 48), Vector2(126, 31)],   # lote 3: Pistão-mola (arma C)
	"C02": ["s07_ventilador", Vector2(60, 30), Vector2(29, 52), Vector2(126, 32)],
	"C03": ["s08_gancho", Vector2(58, 29), Vector2(33, 50), Vector2(126, 30)],
	"C05": ["s21_laco", Vector2(56, 28), Vector2(29, 52), Vector2(124, 32)],
	"F31": ["a31_braco", Vector2(70, 35), Vector2(16, 28), Vector2(110, 28)],
	"F33": ["a33_tocha", Vector2(58, 24), Vector2(14, 20), Vector2(94, 20)]}
const WEAPONS := ["A01", "A02", "A03", "A05", "C01", "A08", "C02", "C03", "C05"]
## Armaduras de transformação (o robô VESTE a máquina): frente/costas no molde da Fornalha (150x130, janela em 75,50),
## cor dos membros, tipo de janela do rosto (circle = vigia, rect = cabine, visor = solda) e cor do aro.
const ARMOR_SETS := {
	"T01": {"front": "s13_frente", "back": "s13_costas", "limb": "#5f4438", "window": "circle", "ring": "#c9a03a"},
	"T02": {"front": "a14_frente", "back": "a14_costas", "limb": "#4a5566", "window": "rect", "ring": "#2a1a2e"},
	"T05": {"front": "a31_frente", "back": "a31_costas", "limb": "#71829a", "window": "circle", "ring": "#9aa4ae"},
	"T06": {"front": "a33_frente", "back": "a33_costas", "limb": "#3e4752", "window": "visor", "ring": "#2a1a2e"},
}
## Ferramenta que vira o braço da frente na transformação (mesmo formato de SPELL_TOOLS).
const FORM_TOOLS := {"T05": "F31", "T06": "F33"}
const CARRY_HF := Vector2(17, -31)      # mão da frente carregando a arma (baixa, pronta)
const AIM_HF := Vector2(21, -38)        # mão da frente mirando reto
const SHOULDER := Vector2(3, -38)       # ombro da frente: a mão gira em volta dele para mirar em 8 direções
const ARM := 18.0
## Ombro da frente de CADA modelo (o SHOULDER acima é o do desenho das spells): armas, mira e armaduras usam este.
static func shoulder_of(model: int, armor := false) -> Vector2:
	var g: Dictionary = Data.model_meta(model)
	if armor:   # de armadura o braço sai da lateral da máquina, abaixo da vigia (nunca cruza o rosto)
		return armor_shoulder(Data.MODELS[posmod(model, Data.MODELS.size())])
	return _v(g["shoulders"][1]) + Vector2(-2, 5)

static func armor_shoulder(mname: String) -> Vector2:
	return armor_fit(mname)[0] + Vector2(18, 18)

## Encaixe da armadura em cada corpo: a placa (72x62) é centrada no CORPO (não no rosto — o Marretão, largo e com o
## rosto lá na frente, sobrava pelas costas) e alargada se o corpo não couber; o rosto vai para a vigia.
## Devolve [vigia (relativa aos pés), escala x]. Medido uma vez no recorte do corpo.
static var _fit := {}
static func armor_fit(mname: String) -> Array:
	if _fit.has(mname):
		return _fit[mname]
	var g: Dictionary = Data.robot_meta["modelos"][mname]
	var eye: Vector2 = (_v(g["eyes"][0]) + _v(g["eyes"][1])) / 2.0
	var res := [eye, 1.0]
	var t: Texture2D = Data.tex("robo/corpo_%s_p1" % mname)
	if t != null:
		var k := 128.0 / float(t.get_width())
		var ur := t.get_image().get_used_rect()
		var b := Rect2(Vector2(ur.position) * k - ORIGIN, Vector2(ur.size) * k)
		var wy := clampf(eye.y, b.end.y - 36.0, b.position.y + 22.0) if b.size.y < 58.0 else b.position.y + b.size.y * 0.39
		res = [Vector2(b.get_center().x, wy), maxf(1.0, (b.size.x + 10.0) / 72.0)]
	_fit[mname] = res
	return res
## Spells sem arma: objeto nas costas (andaime dobrado, marreta sísmica, fornalha desmontada) ou na mão de trás.
const BACK_PROPS := {"A04": ["a04_marreta", Vector2(48, 60), -0.5], "E01": ["s10_trouxa", Vector2(34, 23), 1.35]}
## Kit da transformação levado NAS COSTAS antes de usar (como a Fornalha): peça de costas no meio das costas,
## placa da frente dobrada por cima espiando no ombro (dá para reconhecer a máquina) e alças pelo peito.
## [textura de costas, tamanho, giro, placa da frente ("" = nenhuma), tamanho, giro]
const KITS := {}   # A35/A36: os mechas vão no CARTUCHO (MECHA_CART); o T07 deixou de ser o kit do raio encolhedor
const HAND_PROPS := {"E02": ["s12_carga", Vector2(20, 29)], "E03": ["s27_controle", Vector2(18, 24)]}
# aparência
var color_idx := 0
var model := 0
var skin := ""                 # skin vestida (ex.: "k1" = Mestre de Obras do Canteiro); "" = padrão. Só troca texturas.
var has_hammer := true
# estado da animação
var expression := "normal"
var sq := Vector2.ONE                  # squash/stretch visual (saída das molas)
var shown_facing := 1.0                # vira passando por 0 (giro rápido)
var phase := 0.0
var run_k := 0.0
var air_k := 0.0
var wall_k := 0.0
var vy := 0.0
var lean := 0.0
var ant := 0.0
var ant_v := 0.0
var blink_t := 2.0
var t := 0.0
var prev_vel := Vector2.ZERO
var robot = null
var hanging := false
var grip := 1.0
var on_wall := false
var sweat_t := 0.0
var drops: Array = []                  # gotas de suor quando a aderência está acabando
var hang_snap := Vector2.ZERO          # ao agarrar a borda: o desenho começa onde o robô estava e desliza até a quina
var smoke_t := 0.0
# molas: [valor, velocidade]. Tudo que muda de pose passa por uma mola: chega com inércia e um leve "passar do ponto".
var s_lean := [0.0, 0.0]
var s_bob := [0.0, 0.0]
var s_sqx := [1.0, 0.0]
var s_sqy := [1.0, 0.0]
var s_hb := [Vector2.ZERO, Vector2.ZERO]
var s_hf := [Vector2.ZERO, Vector2.ZERO]
var s_ham := [HAMMER_REST, 0.0]
var s_rot := [0.0, 0.0]
# ações
var atk_kind := ""
var jab_alt := false                   # golpes rápidos alternam (de cima / de baixo)
var smear_from := 0.0                  # rastro do golpe: do ângulo do preparo até o atual
var smear_a := 0.0
var hurt_t := 0.0
var hurt_s := 0.0
var hurt_lean := 0.0
var flash_t := 0.0
var tumble := 0.0                      # giro acumulado do arremesso (rad)
var cena_pose := ""                    # transição de cena: "cai" (pânico, se debatendo) ou "desliza" (surfando a laje)
var tumbling := false
var walk_d := 0.0                      # distância andada no chão (px): a passada do MECHA segue o chão sem escorregar (A34)
var flip_t := -1.0                     # pulo duplo (0..1): chute, cambalhota, abre
var heavy_was_cd := false
var land_t := 0.0                      # amortecimento depois de pousar arremessado
var dodge_ground := false
var dodge_dir := Vector2.ZERO
var dodged_flash := 0.0
var idle_t := 0.0
var fidget_t := -1.0
var fidget_kind := 0
var next_fidget := 5.0
var dmg_level := 0
var spark_t := 0.0
var panel := [0.0, 0.0]               # plaquinha solta (amassado forte) balançando como pêndulo
var ghosts: Array = []                 # rastro (esquiva, arremesso forte, marretada)
var ghost_i := 0
var ghost_tick := 0
const DMG_STEPS := [35.0, 75.0, 120.0]
const PIVOT := Vector2(0, -44)

func setup(col_idx: int, mdl := 0) -> void:
	color_idx = col_idx
	model = mdl
	blink_t = randf_range(0.5, 3.0)
	next_fidget = randf_range(4.0, 7.0)

func _ready() -> void:
	for k in 5:
		var g := Node2D.new()
		g.top_level = true
		g.z_index = -1
		g.visible = false
		g.set_meta("snap", {})
		g.draw.connect(_draw_ghost.bind(g))
		add_child(g)
		ghosts.append(g)

# ---------------------------------------------------------------- gatilhos (chamados pelo robô)
func land(hard := 0.0, launched := false) -> void:
	s_sqx[0] = 1.18 + 0.3 * hard + (0.12 if launched else 0.0)
	s_sqy[0] = 0.84 - 0.22 * hard - (0.08 if launched else 0.0)
	s_bob[1] += 90.0 + 160.0 * hard
	if launched:
		land_t = 0.28
		tumbling = false
		tumble = round(tumble / TAU) * TAU

func stretch() -> void:
	s_sqx[0] = 0.8
	s_sqy[0] = 1.24

## Pulo duplo do propulsor em 3 tempos: CHUTE (pernas esticadas, braços para cima, jato nos pés),
## CAMBALHOTA encolhida (abraça os joelhos, marreta colada) e ABRE (braços abertos, volta a cair).
const DJ_LEN := 0.42
const DJ_KICK := 0.12
const DJ_OPEN := 0.72

func double_jump() -> void:
	flip_t = 0.0
	s_sqx[0] = 0.72
	s_sqy[0] = 1.34
	if robot != null:
		var m = robot.main
		m.ring_fx(robot.position + Vector2(0, 10), 1.0)
		m.ring_fx(robot.position + Vector2(0, 26), 0.6)
		m.dust(robot.position + Vector2(-10, 14), 0.5)
		m.dust(robot.position + Vector2(10, 14), 0.5)

## Apertou a marretada ainda recarregando: a marreta treme e faz "clanc".
func denied() -> void:
	s_ham[1] += 18.0
	Audio.play("menu_negado", 0.8, -8.0)

## Marretada cancelada no preparo: a marreta desce de volta (a mola leva) e some o rastro.
func heavy_cancel() -> void:
	smear_a = 0.0
	s_sqx[0] = 0.9
	s_sqy[0] = 1.08
	Audio.play("marreta_vento", 0.6, -10.0)

func attack(kind: String) -> void:
	atk_kind = kind
	if kind == "rapido":
		jab_alt = not jab_alt
	idle_t = 0.0
	fidget_t = -1.0

func dodge(dir: Vector2, ground: bool) -> void:
	dodge_dir = dir
	dodge_ground = ground
	flip_t = -1.0
	s_sqx[0] = 1.3
	s_sqy[0] = 0.78
	_snap_ghost(0.55)

func hurt(strength: float, dir: int) -> void:
	hurt_t = 0.24
	hurt_s = strength
	flash_t = 0.08
	var fs := signf(shown_facing) if shown_facing != 0.0 else 1.0
	hurt_lean = (float(dir) * fs if dir != 0 else -1.0) * (0.25 + 0.3 * strength)
	s_sqx[0] = 0.72
	s_sqy[0] = 1.22
	s_lean[1] += hurt_lean * 14.0
	flip_t = -1.0
	fidget_t = -1.0

func launch(v: Vector2) -> void:
	tumbling = v.length() >= float(Data.ctrl["arremesso"]["giro_min_vel"])
	flip_t = -1.0
	if tumbling:
		_snap_ghost(0.4)

func look() -> Dictionary:
	var lk := {"color": color_idx, "model": model, "hammer": has_hammer, "dmg": dmg_level, "skin": skin,
		"ham_cd": robot != null and robot.get("heavy_cd") != null and robot.heavy_cd > 0.0}
	if robot != null and robot.has_method("fx_flags"):
		lk["fx"] = robot.fx_flags()
	return lk

static func _spring(sp: Array, target, dt: float, f: float, z: float):
	var w := TAU * f
	sp[1] += (-2.0 * z * w * sp[1] - w * w * (sp[0] - target)) * dt
	sp[0] += sp[1] * dt
	return sp[0]

static func _ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)

# ---------------------------------------------------------------- quadro a quadro
func tick(r, dt: float) -> void:
	robot = r
	if r.hitstop > 0.0:
		# impacto: tudo congela por um instante; quem apanhou treme
		var amp := 3.0 if hurt_t > 0.0 else 1.0
		position = hang_snap + Vector2(randf_range(-amp, amp), randf_range(-amp, amp) * 0.5)
		flash_t = maxf(flash_t - dt * 0.3, 0.0)
		queue_redraw()
		return
	if r.get("frozen_t") != null and r.frozen_t > 0.0:
		# congelado: pose travada, azulado (o bloco de gelo é desenhado por modes/spells.gd)
		modulate = Color(0.62, 0.84, 1.0)
		queue_redraw()
		return
	t += dt
	var c: Dictionary = Data.ctrl
	var v: Vector2 = r.velocity
	var on_floor: bool = r.is_on_floor()
	var spd := absf(v.x)
	var face_to := float(r.facing)
	if r.wall_sliding and r.wall_side != 0 and not r.hanging:
		face_to = -float(r.wall_side)   # de costas para a parede, pronto para o pulo de parede
	if signf(face_to) != signf(shown_facing):
		# virada: troca de lado na hora (controle responsivo) com um "pivô" achatado que volta na mola
		shown_facing = face_to
		s_sqx[0] = 0.7
		s_sqy[0] = 1.06
		s_lean[1] -= 3.0
	run_k = move_toward(run_k, clampf(spd / float(c["max_run"]), 0.0, 1.0) if on_floor else 0.0, dt * 7.0)
	air_k = move_toward(air_k, 0.0 if on_floor else 1.0, dt * 9.0)
	wall_k = move_toward(wall_k, 1.0 if r.wall_sliding else 0.0, dt * 12.0)
	vy = v.y
	hurt_t = maxf(hurt_t - dt, 0.0)
	flash_t = maxf(flash_t - dt, 0.0)
	land_t = maxf(land_t - dt, 0.0)
	dodged_flash = maxf(dodged_flash - dt * 3.0, 0.0)
	if flip_t >= 0.0:
		flip_t += dt / DJ_LEN
		if flip_t >= 1.0 or on_floor or r.stun_t > 0.0:
			# acabou (ou pousou no meio): termina o giro PARA A FRENTE até ficar de pé, nunca desgira
			var cur := float(s_rot[0])
			tumble = ceil(cur / TAU - 0.15) * TAU if flip_t < 1.0 else round(cur / TAU) * TAU
			flip_t = -1.0
	if r.atk == "":
		atk_kind = ""
	if on_floor and r.dodge_t <= 0.0:
		walk_d += spd * dt
	# passada pela distância percorrida + poeirinha a cada passo
	if on_floor and spd > 30.0 and r.dodge_t <= 0.0:
		var before := int(phase / PI)
		phase += spd * dt / STRIDE * TAU
		if int(phase / PI) != before:
			pass   # passos SEM som (pedido do usuário em 2026-11-25: barulho demais)
			if spd > 300.0:
				r.main.dust(r.position + Vector2(-r.facing * 10, 0), 0.45)
	has_hammer = (r.hammer_left > 0 or r.atk != "") and not r.hammer_out
	# marretada pesada recarregou: brilho na marreta + "plim"
	if heavy_was_cd and r.heavy_cd <= 0.0:
		r.main.spark(r.position + Vector2(r.facing * 22, -78), 3)
		Audio.play("item", 1.7, -12.0)
	heavy_was_cd = r.heavy_cd > 0.0
	# arremesso: gira enquanto voa rápido sem controle; ao recuperar, volta de pé com um "pop"
	if tumbling:
		var sp := v.length()
		if r.stun_t <= 0.0 and (r.recover_t < r.recover_len * 0.55 or sp < 420.0):
			tumbling = false
			tumble = round(tumble / TAU) * TAU
			s_sqx[0] = 1.15
			s_sqy[0] = 0.85
			r.main.ring_fx(r.position + Vector2(0, -44), 0.55)
		else:
			var fs := signf(shown_facing) if shown_facing != 0.0 else 1.0
			tumble += signf(v.x) * fs * clampf(sp / 85.0, 4.0, 22.0) * dt
			ghost_tick += 1
			if sp > 900.0 and ghost_tick % 3 == 0:
				_snap_ghost(0.32)
	if r.dodge_t > 0.0:
		ghost_tick += 1
		if ghost_tick % 2 == 0:
			_snap_ghost(0.45)
	if r.atk == "pesado" and r.atk_hit and r.atk_t < float(c["ataque_pesado"]["preparo"]) + float(c["ataque_pesado"]["ativo"]) + 0.03:
		_snap_ghost(0.3)
	# antena como mola (reage à aceleração)
	var a := (v - prev_vel) / maxf(dt, 0.001)
	prev_vel = v
	var ax := clampf(a.x * float(r.facing), -9000.0, 9000.0)
	ant_v += (-150.0 * ant - 6.0 * ant_v - ax * 0.0045 - clampf(a.y, -9000, 9000) * 0.0008) * dt
	ant = clampf(ant + ant_v * dt, -0.9, 0.9)
	# plaquinha solta (muito amassado): pêndulo que reage ao movimento
	panel[1] += (-60.0 * sin(panel[0]) - 2.5 * panel[1] - ax * 0.004) * dt
	panel[0] = clampf(panel[0] + panel[1] * dt, -1.4, 1.4)
	# ocioso: depois de um tempo parado, um tique (gira a marreta / espreguiça)
	if on_floor and run_k < 0.05 and r.atk == "" and r.dodge_t <= 0.0 and hurt_t <= 0.0 and not r.hanging:
		idle_t += dt
		if fidget_t < 0.0 and idle_t > next_fidget:
			fidget_t = 0.0
			fidget_kind = (fidget_kind + 1) % 2
			next_fidget = randf_range(5.0, 8.0)
			idle_t = 0.0
	else:
		idle_t = 0.0
		fidget_t = -1.0
	if fidget_t >= 0.0:
		fidget_t += dt / 1.1
		if fidget_t >= 1.0:
			fidget_t = -1.0
	_update_damage(r, dt)
	# piscar
	blink_t -= dt
	if blink_t < -0.12:
		blink_t = randf_range(1.8, 4.2) * (0.5 if dmg_level >= 2 else 1.0)
	if r.alive and not r.finished:
		if hurt_t > 0.0:
			expression = "eliminado" if hurt_s > 0.6 and hurt_t > 0.1 else "susto"
		elif tumbling or r.stun_t > 0.0:
			expression = "susto"
		elif land_t > 0.0 or r.atk != "" or r.dodge_t > 0.0 or (v.y < -200.0 and not on_floor):
			expression = "esforco"
		elif r.main.danger_near(r) or v.y > 1000.0:
			expression = "susto"
		elif fidget_t >= 0.0 and fidget_kind == 1:
			expression = "vitoria"
		else:
			expression = "piscar" if blink_t < 0.0 else "normal"
	hang_snap = hang_snap.lerp(Vector2.ZERO, minf(dt * 18.0, 1.0))
	position = hang_snap
	if land_t > 0.0 and hurt_t <= 0.0:
		position += Vector2(randf_range(-0.6, 0.6), 0)
	hanging = r.hanging
	grip = r.grip
	on_wall = r.wall_sliding
	if r.hanging or (r.wall_sliding and r.grip < 0.5):
		expression = "esforco"
	if (r.hanging or r.wall_sliding) and r.grip < 0.35:
		expression = "susto"
		sweat_t -= dt
		if sweat_t <= 0.0:
			sweat_t = 0.25
			drops.append({"p": Vector2(randf_range(-14, 14), -86), "v": Vector2(randf_range(-40, 40), -60), "t": 0.0})
	for d in drops:
		d["t"] += dt
		d["v"].y += 500.0 * dt
		d["p"] += d["v"] * dt
	drops = drops.filter(func(d): return d["t"] < 0.6)
	# piscando enquanto invulnerável; clarão branco no golpe
	var al := 0.45 if r.invuln > 0.0 and fmod(t, 0.16) < 0.08 else 1.0
	var fl := 1.0 + 2.2 * (flash_t / 0.08) + 0.8 * dodged_flash
	modulate = Color(fl, fl, fl, al)
	_pose_springs(r, dt, on_floor, v)
	var szk: float = r.size_k if r.get("size_k") != null else 1.0
	scale = Vector2(sq.x * signf(shown_facing + 0.0001), sq.y) * szk
	queue_redraw()

## Dano visível: o corpo vai ficando amassado (3 estágios), solta faísca, fumaça e parafusos.
func _update_damage(r, dt: float) -> void:
	var lvl := 0
	for k in DMG_STEPS.size():
		if r.dmg >= DMG_STEPS[k]:
			lvl = k + 1
	if lvl > dmg_level and r.alive:
		# passou de estágio: tranco, parafuso voando e barulho de lata
		s_sqx[0] = 1.2
		s_sqy[0] = 0.82
		r.main.spark(r.position + Vector2(0, -56), 4 + lvl * 2)
		r.main.pop_bolt(r.position + Vector2(randf_range(-12, 12), -60), -r.facing)
		Audio.play("caixote_pancada", 1.5 - lvl * 0.15, -3.0)
	dmg_level = lvl
	if lvl >= 2 and r.alive:
		spark_t -= dt
		if spark_t <= 0.0:
			spark_t = randf_range(0.9, 1.6) if lvl == 2 else randf_range(0.3, 0.7)
			r.main.spark(r.position + Vector2(randf_range(-14, 14), randf_range(-70, -30)), 1)
	if lvl >= 3 and r.alive:
		smoke_t -= dt
		if smoke_t <= 0.0:
			smoke_t = 0.45 if r.dmg < 160.0 else 0.22
			r.main.dust(r.position + Vector2(randf_range(-10, 10), -78), 0.55)

## Calcula os alvos de inclinação, quique, squash, mãos e marreta e passa tudo pelas molas.
func _pose_springs(r, dt: float, on_floor: bool, v: Vector2) -> void:
	var c: Dictionary = Data.ctrl
	var spd := absf(v.x)
	var lean_t := run_k * 0.16
	if on_floor and spd > 160.0 and signf(v.x) != float(r.facing) and r.dodge_t <= 0.0:
		lean_t = -0.22   # freando / virando: derrapa
		if fmod(t, 0.08) < dt:
			r.main.dust(r.position + Vector2(float(r.facing) * 14.0, 0), 0.4)
	lean_t += wall_k * 0.12
	if not on_floor and r.dodge_t <= 0.0:
		lean_t += clampf(v.x * float(r.facing) / 2400.0, -0.12, 0.18)
	var sqx_t := 1.0
	var sqy_t := 1.0
	# respiração parada / passada correndo
	sqy_t += sin(t * 2.3) * 0.018 * (1.0 - run_k) * (1.0 - air_k)
	sqx_t -= sin(t * 2.3) * 0.012 * (1.0 - run_k) * (1.0 - air_k)
	if on_floor and run_k > 0.1:
		var contact := pow(absf(cos(phase)), 6.0)
		sqy_t -= 0.05 * contact * run_k
		sqx_t += 0.04 * contact * run_k
	if not on_floor and r.dodge_t <= 0.0 and flip_t < 0.0:
		var st := clampf(absf(v.y) / 1400.0, 0.0, 0.16)
		sqy_t += st
		sqx_t -= st * 0.7
	var ham_t := HAMMER_REST
	if on_floor and run_k > 0.1:
		ham_t += sin(phase) * 0.22 * run_k
	elif not on_floor:
		ham_t = lerpf(HAMMER_REST, -0.9 if v.y > 0.0 else 0.9, clampf(absf(v.y) / 900.0, 0.0, 1.0))
	# golpes
	var hp: Dictionary = c["ataque_pesado"]
	var rp: Dictionary = c["ataque_rapido"]
	if r.atk == "pesado":
		var pre := float(hp["preparo"])
		if not r.atk_hit:
			var k := clampf(r.atk_t / pre, 0.0, 1.0)
			lean_t = -0.3 * _ease_out(k)
			sqx_t = 1.0 + 0.1 * k
			sqy_t = 1.0 - 0.1 * k
		elif r.atk_t < pre + float(hp["ativo"]):
			lean_t = 0.5
			sqx_t = 0.9
			sqy_t = 1.12
		else:
			lean_t = 0.42 if not r.atk_landed else 0.1
	elif r.atk == "rapido":
		var pre := float(rp["preparo"])
		lean_t = -0.08 if not r.atk_hit else (0.26 if r.atk_t < pre + float(rp["ativo"]) + 0.04 else 0.08)
	if r.dodge_t > 0.0:
		lean_t = 0.55 if dodge_ground else 0.2
		sqx_t = 1.22
		sqy_t = 0.82
	if hurt_t > 0.0:
		lean_t = hurt_lean
	if land_t > 0.0:
		sqx_t = 1.12
		sqy_t = 0.88
		lean_t = 0.2
	lean = _spring(s_lean, lean_t, dt, 3.6, 0.42)
	var bob_t := 0.0
	if r.dodge_t > 0.0 and dodge_ground:
		bob_t = 9.0
	_spring(s_bob, bob_t, dt, 4.5, 0.35)
	sq = Vector2(_spring(s_sqx, sqx_t, dt, 4.2, 0.28), _spring(s_sqy, sqy_t, dt, 4.2, 0.28))
	sq = sq.clamp(Vector2(0.55, 0.55), Vector2(1.6, 1.6))
	if tumbling:
		s_rot[0] = tumble
		s_rot[1] = 0.0
	else:
		_spring(s_rot, tumble, dt, 7.0 if on_floor else 3.2, 0.5 if on_floor else 0.38)   # volta de pé com um balanço

## Rastro: copia a pose atual para um "fantasma" na cor do jogador que some aos poucos.
func _snap_ghost(alpha: float) -> void:
	if ghosts.is_empty() or not is_inside_tree():
		return
	var g: Node2D = ghosts[ghost_i % ghosts.size()]
	ghost_i += 1
	g.set_meta("snap", {"xf": get_global_transform(), "pose": current_pose(), "look": look(), "a": alpha, "t": 0.0})
	g.visible = true
	g.queue_redraw()

func _draw_ghost(g: Node2D) -> void:
	var sn: Dictionary = g.get_meta("snap")
	if sn.is_empty():
		return
	draw_robot(g, sn["look"], sn["pose"], sn["xf"])

func _process(dt: float) -> void:
	var col: Color = Data.COLORS[color_idx % Data.COLORS.size()]
	for g in ghosts:
		if not g.visible:
			continue
		var sn: Dictionary = g.get_meta("snap")
		sn["t"] = float(sn["t"]) + dt
		var k: float = sn["t"] / 0.22
		if k >= 1.0:
			g.visible = false
			continue
		g.modulate = Color(col.r * 1.3, col.g * 1.3, col.b * 1.3, float(sn["a"]) * (1.0 - k))

## Pose do elenco: cada robô tem quadros-chave próprios (art/src/robos/elenco.py → modelos.json "poses"):
## parado, corre, ar, rapido_prep/rapido, rapido2_prep/rapido2, cima, baixo, pesado_prep/pesado_golpe, esquiva, esquiva_ar.
## A animação mistura esses quadros no ritmo exato dos tempos do controle (preparo/ativo/recupera de data/controller.json):
## o desenho nunca atrasa o golpe. Ferramenta sempre nas DUAS mãos (a de trás vai para a pegada de trás do cabo).
func _g() -> Dictionary:
	return Data.model_meta(model)

func _frame(name: String) -> Dictionary:
	var ps: Dictionary = _g()["poses"]
	return ps.get(name, ps["parado"])

static func _a2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func _def_foot(i: int) -> Vector2:
	var hips: Array = _g()["hips"]
	return Vector2(_v(hips[i]).x + (-1.0 if i == 0 else 1.0) * 4.0, -4.0)

## Mistura o estado st na direção do quadro fr com peso w. fwd: +1 gira a ferramenta para a frente (por cima),
## -1 para trás, 0 pelo caminho mais curto.
func _blend(st: Dictionary, fr: Dictionary, w: float, fwd := 0) -> void:
	if w <= 0.0:
		return
	st["hf"] = (st["hf"] as Vector2).lerp(_a2(fr["hf"]), w)
	var a0: float = st["a"]
	var a1 := float(fr["a"])
	if fwd > 0:
		a1 = a0 + fposmod(a1 - a0, TAU)
	elif fwd < 0:
		a1 = a0 - fposmod(a0 - a1, TAU)
	else:
		a1 = a0 + wrapf(a1 - a0, -PI, PI)
	st["a"] = lerpf(a0, a1, w)
	st["lean"] = lerpf(float(st["lean"]), float(fr["lean"]), w)
	st["bob"] = lerpf(float(st["bob"]), float(fr["dy"]), w)
	if fr.has("feet"):
		var ft: Array = st["feet"]
		for i in 2:
			ft[i] = (ft[i] as Vector2).lerp(_a2(fr["feet"][i]) - _def_foot(i), w)

func current_pose() -> Dictionary:
	var p := idle_pose(t)
	p.erase("rest")
	p["expr"] = expression
	var g := _g()
	var r := run_k
	var c: Dictionary = Data.ctrl
	var ant_extra := 0.0
	var bob := -absf(sin(phase)) * 5.0 * r + sin(t * 2.3) * 1.0 * (1.0 - r) + float(s_bob[0])
	var feet := [Vector2.ZERO, Vector2.ZERO]
	var kd := float(g.get("knee", 1))
	var knee := [Vector2(1.5 * kd, 0), Vector2(1.5 * kd, 0)]
	var hfr := _v(g["hand_front"])
	var hbr := _v(g["hand_back"])
	var two_hand := true
	# base: parado → corre → ar (a ferramenta muda de jeito: apoiada, no ombro, erguida)
	var fp0 := _frame("parado")
	var fr_run := _frame("corre")
	var fr_air := _frame("ar")
	var hf: Vector2 = _a2(fp0["hf"]).lerp(_a2(fr_run["hf"]), r)
	var ang: float = float(fp0["a"]) + wrapf(float(fr_run["a"]) - float(fp0["a"]), -PI, PI) * r
	var stand := (1.0 - r) * (1.0 - air_k)
	if fp0.has("feet"):
		for i in 2:
			feet[i] = (_a2(fp0["feet"][i]) - _def_foot(i)) * stand
	# corrida: pés em elipse, joelho dobra na subida; a ferramenta balança com a passada
	for i in 2:
		var ph := phase + (0.0 if i == 0 else PI)
		var lift := maxf(sin(ph), 0.0)
		feet[i] += Vector2(cos(ph) * 11.0 * r, -lift * 10.0 * r - maxf(-sin(ph), 0.0) * 1.2 * r)
		knee[i] = Vector2((1.5 + 7.0 * r * lift) * kd, 0)
	hf += Vector2(cos(phase) * 2.0, -absf(sin(phase)) * 3.0) * r + Vector2(0, sin(t * 2.3 + 1.1) * 0.6 * (1.0 - r))
	ang += sin(phase) * 0.14 * r
	var hb := hbr + Vector2(-cos(phase) * 9.0 * r, -2.0 * r)
	# ar: encolhe subindo, abre no alto, estica caindo; a ferramenta vai para cima e balança na queda
	var a := air_k
	if a > 0.0:
		var fall := clampf(vy / 800.0, -1.0, 1.0)
		var up := maxf(-fall, 0.0)
		var down := maxf(fall, 0.0)
		var apex := 1.0 - clampf(absf(vy) / 260.0, 0.0, 1.0)
		for i in 2:
			var sg := -1.0 if i == 0 else 1.0
			var air_f := Vector2(2.0 + sg * 1.0, -11.0) * up + Vector2(sg * 5.0, 3.0) * down + Vector2(sg * 7.0, -5.0) * apex
			feet[i] = feet[i].lerp(air_f, a)
			knee[i] = knee[i].lerp(Vector2(7.0 * kd, 0) * up + Vector2(0.5 * kd, 0) * down + Vector2(4.0 * kd, 0) * apex, a)
		hf = hf.lerp(_a2(fr_air["hf"]) + Vector2(0, -2.0 * up + 3.0 * down), a)
		ang = lerpf(ang, ang + wrapf(float(fr_air["a"]) - ang, -PI, PI) + 0.35 * down - 0.2 * up, a)
		hb = hb.lerp(hbr + Vector2(sin(t * 24.0) * 6.0, -18.0 + cos(t * 24.0) * 5.0) * down + Vector2(-12, -8) * apex, a)
	# transição de cena (avaliação 2026-11-26): o robô MOSTRA que está caindo/escorregando
	if cena_pose == "cai" and not (robot != null and robot.is_on_floor()):
		p["expr"] = "susto"
		two_hand = false
		for i in 2:
			var ph := t * 16.0 + i * PI
			feet[i] = Vector2(sin(ph) * 9.0, -6.0 + cos(ph) * 7.0)
			knee[i] = Vector2((5.0 + 4.0 * maxf(sin(ph), 0.0)) * kd, 0)
		hb = hbr + Vector2(sin(t * 20.0) * 10.0, -34.0 + cos(t * 20.0) * 6.0)
		hf = hfr + Vector2(cos(t * 18.0) * 6.0, -30.0 + sin(t * 18.0) * 6.0)
		ang = -PI * 0.5 + sin(t * 9.0) * 0.6
		bob += sin(t * 12.0) * 2.0
	elif cena_pose == "desliza":
		p["expr"] = "esforco" if fmod(t, 1.4) < 0.9 else "vitoria"
		two_hand = false
		feet[0] = Vector2(14.0, -2.0)
		feet[1] = Vector2(-10.0, 0.0)
		knee[0] = Vector2(6.0 * kd, 0)
		knee[1] = Vector2(8.0 * kd, 0)
		hb = hbr + Vector2(-16.0, -26.0 + sin(t * 8.0) * 3.0)
		hf = hfr + Vector2(10.0, -20.0 + cos(t * 8.0) * 3.0)
		bob += 6.0
	# pulo duplo: chute com jato → cambalhota encolhida (ferramenta colada) → abre
	if flip_t >= 0.0:
		var k := flip_t
		var fr_t := _frame("esquiva_ar")
		if k < DJ_KICK:
			var u := _ease_out(k / DJ_KICK)
			for i in 2:
				feet[i] = feet[i].lerp(Vector2(-3.0 + i * 6.0, 6.0), u)
				knee[i] = knee[i].lerp(Vector2(0.5 * kd, 0), u)
			p["jet"] = 1.0
			p["rot"] = 0.0
		elif k < DJ_OPEN:
			var v := (k - DJ_KICK) / (DJ_OPEN - DJ_KICK)
			var e := v * v * v * (v * (v * 6.0 - 15.0) + 10.0)
			p["rot"] = TAU * e
			var tuck := clampf(sin(PI * v) * 1.6, 0.0, 1.0)
			for i in 2:
				feet[i] = Vector2(-3.0 + i * 6.0, 6.0).lerp(Vector2(3.0 + i * 5.0, -24.0), tuck)
				knee[i] = Vector2(0.5 * kd, 0).lerp(Vector2(12.0 * kd, 0), tuck)
			hf = hf.lerp(_a2(fr_t["hf"]), tuck)
			ang = lerpf(ang, ang + wrapf(float(fr_t["a"]) - ang, -PI, PI), tuck)
			p["jet"] = maxf(1.0 - v * 2.5, 0.0)
			p["tuck"] = tuck
			bob += 6.0 * tuck
		else:
			var w := _ease_out((k - DJ_OPEN) / (1.0 - DJ_OPEN))
			p["rot"] = TAU
			for i in 2:
				feet[i] = Vector2(3.0 + i * 5.0, -24.0).lerp(feet[i], w)
				knee[i] = Vector2(12.0 * kd, 0).lerp(knee[i], w)
	# ocioso: gira a ferramenta e pega de volta / espreguiça
	if fidget_t >= 0.0:
		var k := fidget_t
		if fidget_kind == 0:
			hf += Vector2(0, -16.0 * sin(PI * k))
			ang += TAU * smoothstep(0.1, 0.8, k)
			two_hand = k < 0.05 or k > 0.9
			hb = hbr + Vector2(-6, -10) * sin(PI * k)
		else:
			var u := sin(PI * k)
			hf += Vector2(2, -22) * u
			bob -= 3.0 * u
			ant_extra = sin(t * 10.0) * 0.3 * u
	# pendurado na borda: as duas mãos na quina, ferramenta pendurada para trás
	var tremble := 0.0
	if hanging or on_wall:
		tremble = clampf((0.45 - grip) / 0.45, 0.0, 1.0)
	if hanging:
		two_hand = false
		var slip := clampf((0.3 - grip) / 0.3, 0.0, 1.0) * 6.0
		p["hb_abs"] = Vector2(14, -60 + slip) + Vector2(sin(t * 55.0), cos(t * 47.0)) * 1.5 * tremble
		hf = Vector2(23, -61 + slip) + Vector2(cos(t * 51.0), sin(t * 43.0)) * 1.5 * tremble
		lean = lerpf(lean, 0.1, 0.5)
		bob = 5.0 + sin(t * 3.0) * 1.0
		var scr := 2.0 + 10.0 * tremble
		for i in 2:
			var ph := t * (6.0 + 14.0 * tremble) + i * PI
			feet[i] = Vector2(8.0 + i * 3.0, -2.0 - maxf(sin(ph), 0.0) * scr)
			knee[i] = Vector2(5 * kd, 0)
		ang = PI * 0.92
	if wall_k > 0.0 and not hanging:
		var shake := Vector2(sin(t * 60.0), cos(t * 53.0)) * 1.6 * tremble
		if wall_k > 0.5:
			two_hand = false
			p["hb_abs"] = Vector2(-16, -40) + shake
		hf = hf.lerp(Vector2(8, -34), wall_k)
		ang = lerpf(ang, ang + wrapf(-0.4 - ang, -PI, PI), wall_k)
		feet[0] = feet[0].lerp(Vector2(-12, -10), wall_k)
		feet[1] = feet[1].lerp(Vector2(4, 0), wall_k)
	# spells (igual para todos): a mão da frente segura a arma / aponta; a ferramenta vai para as costas
	var sf: Dictionary = robot.fx_flags() if robot != null and robot.has_method("fx_flags") else {}
	var sid: String = sf.get("spell", "")
	var prep: float = sf.get("prep", -1.0)
	var fire: float = sf.get("fire", -1.0)
	var aiming: bool = prep >= 0.0 or (fire >= 0.0 and fire < (0.55 if sid == "A04" else 0.32)) or (sf.get("channel", false) and sid in ["C01", "C04", "C02", "A06"])
	var hf_set := false
	if sid != "" and aiming and not sf.get("armor", false):
		var kick := clampf(1.0 - fire / 0.22, 0.0, 1.0) if fire >= 0.0 and prep < 0.0 and not sf.get("beam", false) else 0.0   # A02: arma firme durante o feixe
		var buzz := Vector2(sin(t * 80.0), cos(t * 71.0)) * 1.4 * maxf(prep, 0.0)
		var aa := float(sf.get("aim_a", 0.0))
		two_hand = false
		match sid:
			"A01":
				var ad := Vector2.from_angle(aa)
				if prep >= 0.0:
					hf = SHOULDER + ad * lerpf(ARM, 2.0, ease(prep, 0.5)) + buzz
					p["hb_abs"] = SHOULDER + Vector2(-6, 6) + buzz * 0.5
					lean = lerpf(lean, -0.16 * prep, 0.5)
				else:
					hf = SHOULDER + ad * (ARM + 6.0 - 8.0 * (1.0 - kick))
					p["hb_abs"] = Vector2(-10, -32)
					lean = lerpf(lean, (0.18 * kick + 0.04) * cos(aa), 0.6)
				p["tool"] = "A01"
				p["tool_ang"] = aa
				hf_set = true
			"A04":
				if prep >= 0.0:
					ang = lerpf(-0.6, -2.7, ease(prep, 0.4))
					hf = Vector2(4, -62) + buzz
					p["hb_abs"] = Vector2(-2, -60) + buzz
					lean = lerpf(lean, -0.18 * prep, 0.5)
				else:
					ang = 1.75
					hf = Vector2(24, -18)
					p["hb_abs"] = Vector2(18, -16)
					lean = lerpf(lean, 0.3, 0.6)
				hf_set = true
				for i in 2:
					feet[i] = feet[i].lerp(Vector2(-12.0 + i * 20.0, 0), 0.7)
			"A07":
				var u := clampf(fire / 0.2, 0.0, 1.0)
				hf = Vector2(-16, -52).lerp(Vector2(28, -38), ease(u, 0.3))
				lean = lerpf(lean, -0.1 + 0.25 * u, 0.5)
				hf_set = true
			"A06":
				hf = Vector2(26, -30)
				hf_set = true
			"E02", "E03":
				hf = Vector2(24, -34 + 4.0 * kick)
				hf_set = true
			"A03", "C01", "A02", "A05", "A08", "C03", "C05", "C02":
				var ad := Vector2.from_angle(aa)
				var hold := Vector2(sin(t * 70.0), cos(t * 61.0)) * 1.4 if sf.get("channel", false) else Vector2.ZERO
				hf = SHOULDER + ad * (ARM - 9.0 * kick) + buzz + hold
				p["hb_abs"] = hf + Vector2(-9, 4).rotated(aa)
				p["tool"] = sid
				p["tool_ang"] = aa - 0.35 * kick
				var back := -0.2 if sid == "C01" and sf.get("channel", false) else (0.16 if sid == "C02" and sf.get("channel", false) else 0.06 - 0.14 * kick)
				lean = lerpf(lean, back - 0.12 * clampf(-sin(aa), 0.0, 1.0), 0.5)
				hf_set = true
			"E01":
				hf = Vector2(24, -46 - 10.0 * kick)
				hf_set = true
			"C04":
				if sf.get("channel", false):
					hf = Vector2(8, -66) + Vector2(sin(t * 50.0), 0) * 1.2
					p["hb_abs"] = Vector2(-10, -64)
				else:
					hf = Vector2(10, -62 + 6.0 * kick)
					p["hb_abs"] = Vector2(-8, -60 + 6.0 * kick)
				hf_set = true
		for i in 2:
			feet[i] = feet[i].lerp(Vector2(-6.0 + i * 10.0, 0), 0.6)
	elif sid == "A07" and robot != null and robot.atk == "" and not robot.hammer_out and not sf.get("fading", false):
		# MARRETA-BUMERANGUE equipada (2026-11-25: "não dá para perceber que está equipado"): a ferramenta fica ERGUIDA
		# atrás da cabeça, pronta para o arremesso, balançando de leve; o desenho põe um brilho girando na cabeça dela
		var fpr := _frame("pesado_prep")
		var wob := sin(t * 5.0) * 0.08
		hf = hf.lerp(_a2(fpr["hf"]), 0.6)
		ang = lerpf(ang, ang + wrapf(float(fpr["a"]) - ang, -PI, PI), 0.6) + wob
		lean = lerpf(lean, float(fpr["lean"]) * 0.5, 0.5)
		p["a07_pronto"] = true
		hf_set = true
	elif sid in WEAPONS and robot != null and robot.atk == "" and not sf.get("fading", false):
		var cbob := sin(t * 12.0) * 1.6 * run_k
		hf = CARRY_HF + Vector2(0, cbob)
		p["hb_abs"] = CARRY_HF + Vector2(-9, 4 + cbob)
		p["tool"] = sid
		p["tool_ang"] = 0.32 - 0.12 * air_k
		two_hand = false
		hf_set = true
	elif sf.get("armor", false) and FORM_TOOLS.has(String(sf.get("armor_set", ""))):
		var aa2 := float(sf.get("aim_a", 0.0))
		var shake2 := Vector2(sin(t * 80.0), cos(t * 73.0)) * (1.6 if sf.get("busy", false) else 0.4)
		hf = SHOULDER + Vector2.from_angle(aa2) * ARM + shake2
		p["hb_abs"] = Vector2(-12, -30)
		p["tool"] = FORM_TOOLS[String(sf["armor_set"])]
		p["tool_ang"] = aa2
		lean = lerpf(lean, 0.08 if sf.get("busy", false) else 0.0, 0.4)
		two_hand = false
		hf_set = true
	elif sf.get("armor", false) and String(sf.get("armor_set", "")) == "T02":
		hf = Vector2(20, -32)
		p["hb_abs"] = Vector2(12, -30)
		two_hand = false
		hf_set = true
	elif sf.get("flying_on", false):
		var vxk := clampf(float(sf.get("fly_vx", 0.0)) / 600.0, -1.0, 1.0) * float(robot.facing if robot != null else 1)
		lean = lerpf(lean, 0.38 * vxk, 0.25)
		# voando (2026-11-25: "animação bugada"): a ferramenta não fica mais erguida cruzando a cabeça; vai na mão da
		# frente apontando para trás e para baixo (como quem segura firme no voo); a de trás segura a alça da mochila
		p["hb_abs"] = Vector2(-10, -30 + sin(t * 9.0) * 2.0)
		hf = Vector2(16, -24 + cos(t * 9.0) * 2.0)
		ang = lerpf(ang, ang + wrapf(3.9 - ang, -PI, PI), 0.7)
		two_hand = false
		hf_set = true
		for i in 2:
			feet[i] = feet[i].lerp(Vector2(-10.0 - vxk * 6.0 + i * 8.0, -6.0 + sin(t * 7.0 + i * 1.7) * 5.0), 0.5)
	elif sf.get("armor", false) and float(sf.get("flame", 0.0)) > 0.05:
		var fk := float(sf.get("flame", 0.0))
		lean = lerpf(lean, -0.14 * fk, 0.5)
		hf = SHOULDER + Vector2.from_angle(float(sf.get("aim_a", 0.0))) * ARM + Vector2(sin(t * 60.0), cos(t * 55.0)) * 1.5 * fk
		p["hb_abs"] = Vector2(-14, -30)
		two_hand = false
		hf_set = true
		for i in 2:
			feet[i] = feet[i].lerp(Vector2(-10.0 + i * 14.0, 0), 0.6)
	elif sf.get("armor", false):
		two_hand = false
	if hf_set:   # poses das spells foram feitas para o ombro padrão: leva mãos para o ombro deste robô
		var dsh := shoulder_of(model, sf.get("armor", false)) - SHOULDER
		hf += dsh
		if p.has("hb_abs"):
			p["hb_abs"] += dsh
	# subindo na borda
	if robot != null and robot.climb_t >= 0.0:
		var k: float = robot.climb_t
		p["hb_abs"] = Vector2(10, -48 + 40 * k)
		hf = Vector2(18, -50 + 40 * k)
		feet[1] = Vector2(10, -22 * (1.0 - k))
		knee[1] = Vector2(9 * kd, 0)
		lean = 0.3
		two_hand = false
		hf_set = true
	# ---- golpes e esquiva: quadros-chave do robô no ritmo do controle
	var esp: Dictionary = g.get("especial", {})
	if robot != null and not hf_set:
		var at: float = robot.atk_t
		var st := {"hf": hf, "a": ang, "lean": lean, "bob": 0.0, "feet": feet.duplicate()}
		var used := false
		if robot.atk == "pesado":
			var hp: Dictionary = c["ataque_pesado"]
			var pre := float(hp["preparo"])
			var act := float(hp["ativo"])
			var fpre := _frame("pesado_prep")
			var fhit := _frame("pesado_golpe")
			used = true
			# o golpe ACERTA no fim do preparo: a descida começa nos últimos 15% do preparo, então no impacto (e no
			# hitstop) a ferramenta já está quase no alvo; o "ativo" termina o movimento.
			if not robot.atk_hit:
				var k := clampf(at / pre, 0.0, 1.0)
				_blend(st, fpre, _ease_out(minf(k / 0.85, 1.0)), -1)
				var sw := clampf((k - 0.85) / 0.15, 0.0, 1.0)
				if sw > 0.0:
					smear_from = float(st["a"])
					_blend(st, fhit, 0.6 * sw * sw, 1)
					smear_a = sw
				else:
					smear_from = float(st["a"])
					smear_a = 0.0
					if k > 0.6:
						st["hf"] += Vector2(sin(t * 90.0), cos(t * 83.0)) * 1.2
				p["glint"] = clampf((k - 0.5) / 0.35, 0.0, 1.0) * (1.0 - sw)
				if String(esp.get("pesado", "")) == "giro":
					p["spin"] = cos(sw * 0.6 * TAU)
			elif at < pre + act:
				var k := clampf((at - pre) / act, 0.0, 1.0)
				_blend(st, fpre, 1.0, -1)
				smear_from = float(st["a"])
				_blend(st, fhit, 0.6 + 0.4 * _ease_out(k), 1)
				smear_a = 1.0
				if String(esp.get("pesado", "")) == "giro":
					p["spin"] = cos((0.6 + 0.4 * k) * TAU)
			else:
				var rec := at - pre - act
				var stuck := 0.0 if robot.atk_landed else clampf(1.0 - rec / (float(hp["recupera_erro"]) * 0.7), 0.0, 1.0)
				var back_w := 1.0 - clampf(rec / float(hp["recupera_acerto"] if robot.atk_landed else hp["recupera_erro"]), 0.0, 1.0)
				_blend(st, fhit, maxf(back_w, stuck), 0)
				if stuck > 0.0:   # errou: a ferramenta fica cravada e ele puxa com esforço
					st["a"] = float(st["a"]) + sin(t * 40.0) * 0.04 * stuck
					st["hf"] += Vector2(-2, 0) * sin(t * 30.0) * stuck
				smear_a = maxf(smear_a - 0.25, 0.0)
		elif robot.atk == "rapido":
			var rp: Dictionary = c["ataque_rapido"]
			var pre := float(rp["preparo"])
			var act := float(rp["ativo"])
			var pn := "rapido_prep" if not jab_alt else "rapido2_prep"
			var hn := "rapido" if not jab_alt else "rapido2"
			match String(robot.atk_dir):
				"cima":
					pn = "rapido_prep"
					hn = "cima"
				"baixo":
					pn = "rapido2_prep"
					hn = "baixo"
				"corrida":
					pn = "rapido_prep"
					hn = "rapido"
				_:
					if int(robot.combo_i) == 2:
						pn = "rapido2_prep"
						hn = "rapido2"
			var fpre := _frame(pn)
			var fhit := _frame(hn)
			used = true
			# preparo curtíssimo: metade puxando, metade já batendo; no impacto a ferramenta está a 65% do golpe
			if not robot.atk_hit:
				var u := clampf(at / pre, 0.0, 1.0)
				_blend(st, fpre, _ease_out(minf(u / 0.5, 1.0)), 0)
				smear_from = float(st["a"])
				var sw := clampf((u - 0.5) / 0.5, 0.0, 1.0)
				_blend(st, fhit, 0.65 * sw, 1)
				smear_a = sw
			elif at < pre + act:
				_blend(st, fpre, 1.0, 0)
				smear_from = float(st["a"])
				_blend(st, fhit, 0.65 + 0.35 * _ease_out((at - pre) / act), 1)
				smear_a = 1.0 if (int(robot.combo_i) == 2 or String(robot.atk_dir) != "frente") else 0.8
			else:
				var rec := at - pre - act
				_blend(st, fhit, 1.0 - clampf(rec / float(rp["recupera"]), 0.0, 1.0), 0)
				smear_a = maxf(smear_a - 0.3, 0.0)
		else:
			smear_a = maxf(smear_a - 0.3, 0.0)
		if robot.dodge_t > 0.0:
			var dl: float = maxf(float(robot.get("dodge_len") if robot.get("dodge_len") != null else 0.17), 0.01)
			var u := clampf(1.0 - robot.dodge_t / dl, 0.0, 1.0)
			var kind := String(esp.get("esquiva", ""))
			used = true
			if dodge_ground:
				_blend(st, _frame("esquiva"), _ease_out(minf(u * 3.0, 1.0)), 0)
				match kind:
					"mortal":   # Picareta: mortal para trás
						p["rot"] = -TAU * smoothstep(0.0, 1.0, u)
						st["bob"] = float(st["bob"]) * 0.5 - sin(PI * u) * 14.0
					"salto", "pulinho":   # Pá apoia na pá e salta / Britadeira pula de lado
						st["bob"] = float(st["bob"]) * (1.0 if kind == "salto" else 0.6) - sin(PI * u) * (6.0 if kind == "salto" else 12.0)
			else:
				_blend(st, _frame("esquiva_ar"), _ease_out(minf(u * 3.0, 1.0)), 0)
				if kind == "mortal":
					p["rot"] = -TAU * smoothstep(0.0, 1.0, u)
				else:
					p["rot"] = atan2(dodge_dir.y, absf(dodge_dir.x) + 0.001) * 0.7 + 0.35
			p["guard"] = clampf(robot.guard_t / 0.13, 0.0, 1.0)
		if used:
			hf = st["hf"]
			ang = st["a"]
			lean = st["lean"]
			bob += float(st["bob"])
			feet = st["feet"]
			s_ham[0] = ang
			s_ham[1] = 0.0
			s_hf[0] = hf
			s_hf[1] = Vector2.ZERO
		# atingido / arremessado: solta a mão de trás, braços e pernas se debatendo
		if hurt_t > 0.0 or tumbling or robot.stun_t > 0.0:
			var fl := 1.0 if tumbling else 0.6
			two_hand = false
			hb = Vector2(-16, -44) + Vector2(sin(t * 31.0), cos(t * 27.0)) * 6.0 * fl
			hf = hfr + Vector2(4, -14) + Vector2(cos(t * 29.0), sin(t * 33.0)) * 6.0 * fl
			for i in 2:
				feet[i] = Vector2(-10.0 + i * 20.0, -6.0) + Vector2(sin(t * 25.0 + i), 0) * 4.0 * fl
				knee[i] = Vector2((-3.0 + i * 6.0) * kd, 0)
			ang = float(s_ham[0]) + sin(t * 20.0) * 0.5 * fl
		elif not robot.is_on_floor() and robot.recover_t > 0.0:
			var u: float = robot.recover_t / maxf(robot.recover_len, 0.01)
			hb = hb.lerp(Vector2(-20, -40), u)
			two_hand = u < 0.4
		if land_t > 0.0:
			var u := land_t / 0.28
			for i in 2:
				feet[i] = Vector2(-9.0 + i * 18.0, 0)
				knee[i] = Vector2(10 * kd, 0) * u + knee[i] * (1.0 - u)
			bob += 8.0 * u
			hf = hf.lerp(hfr + Vector2(4, 10), u)
	# mãos com inércia (molinha) fora dos golpes; dano deixa os braços bambos
	var wob := Vector2(sin(t * 13.0), cos(t * 11.0)) * (1.2 if dmg_level >= 2 else 0.0)
	var dt := 1.0 / 60.0
	var attacking: bool = robot != null and (robot.atk != "" or robot.dodge_t > 0.0)
	if not attacking:
		s_ham[0] = ang + wrapf(float(s_ham[0]) - ang, -PI, PI)
		ang = _spring(s_ham, ang, dt * 0.5, 5.0, 0.45)
		hf = _spring(s_hf, hf, dt * 0.5, 6.0, 0.5) + wob
	hb = _spring(s_hb, hb, dt * 0.5, 6.0, 0.5) - wob
	if not p.has("rot") and absf(float(s_rot[0]) - round(float(s_rot[0]) / TAU) * TAU) > 0.001:
		p["rot"] = s_rot[0]
	elif p.has("rot"):
		s_rot[0] = p["rot"]
		s_rot[1] = 0.0
		tumble = round(float(p["rot"]) / TAU) * TAU if flip_t < 0.0 else tumble
	p["spring_k"] = 1.0 + 0.5 * air_k - 0.4 * clampf(1.0 - sq.y, 0.0, 1.0)
	p["body_off"] = Vector2(0, bob)
	p["lean"] = lean
	p["feet"] = feet
	p["knee"] = knee
	p["hf_abs"] = hf
	if not p.has("hb_abs") and not two_hand:
		p["hb_abs"] = hb
	p["two_hand"] = two_hand
	p["hammer_ang"] = ang
	p["ant"] = ant + ant_extra + 0.12 * dmg_level
	p["smear"] = [smear_from, ang, smear_a]
	p["panel"] = panel[0]
	# estado de movimento para os MECHAS (A34): passada, ar, pulo duplo, dash, parede, pouso
	p["mv"] = {"dist": walk_d, "phase": phase, "run": run_k, "air": air_k, "vy": vy, "flip": flip_t, "land": land_t, "wall": on_wall,
		"dodge": (robot.dodge_t / maxf(robot.dodge_len, 0.01)) if robot != null and robot.get("dodge_t") != null and robot.dodge_t > 0.0 else 0.0,
		"hurt": hurt_t, "t": t}
	return p

func _draw() -> void:
	draw_robot(self, look(), current_pose())
	_draw_tag()
	# suor
	for d in drops:
		draw_circle(d["p"], 2.6, Color(0.55, 0.8, 1.0, 1.0 - d["t"] / 0.6))
	# medidor de aderência (parede/borda): anel que esvazia acima da cabeça
	if (hanging or on_wall or (robot != null and not robot.is_on_floor() and grip < 0.999)) and grip < 0.999 and robot != null and robot.alive:
		var c := Vector2(0, -104)
		var col := Color("#5cc45c").lerp(Color("#f2c84b"), clampf((0.7 - grip) / 0.35, 0.0, 1.0)).lerp(Color("#d42035"), clampf((0.35 - grip) / 0.3, 0.0, 1.0))
		if grip < 0.3 and fmod(t, 0.2) < 0.1:
			col = Color.WHITE
		var sx := signf(scale.x) if scale.x != 0.0 else 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / maxf(absf(scale.x), 0.2) * sx, 1.0 / maxf(scale.y, 0.2)))
		draw_circle(c, 13.0, Color(0.12, 0.18, 0.2, 0.55))
		draw_arc(c, 10.0, -PI / 2.0, -PI / 2.0 + TAU * grip, 24, col, 5.0, true)
		draw_set_transform(Vector2.ZERO)

## Setinha na cor do jogador acima da cabeça ("P1"): identifica quem é quem (fica acima do topo de cada modelo).
func _draw_tag() -> void:
	if robot == null or not robot.alive or not robot.get("active"):
		return
	var sx := signf(scale.x) if scale.x != 0.0 else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / maxf(absf(scale.x), 0.2) * sx, 1.0 / maxf(scale.y, 0.2)))
	var meter: bool = (hanging or on_wall or not robot.is_on_floor()) and grip < 0.999
	var top := float(Data.model_meta(model)["top"]) - ORIGIN.y
	if robot.has_method("fx_flags") and String(robot.fx_flags().get("mecha", "")) != "":
		top = minf(top, -138.0)   # pilotando um mecha (A29): a etiqueta vai acima da cabeça da máquina
	var y := (top - 48.0) if meter else (top - 14.0)
	var col: Color = Data.COLORS[color_idx % Data.COLORS.size()]
	draw_colored_polygon(PackedVector2Array([Vector2(-9, y), Vector2(9, y), Vector2(0, y + 10)]), col)
	draw_polyline(PackedVector2Array([Vector2(-9, y), Vector2(9, y), Vector2(0, y + 10), Vector2(-9, y)]), Data.INK, 2.0, true)
	Kit.text(self, Vector2(-30, y - 4), "P%d" % (robot.pid + 1), 22, col, HORIZONTAL_ALIGNMENT_CENTER, 60, 5, Data.INK)
	draw_set_transform(Vector2.ZERO)

## Poses prontas para telas (entrada e vitória).
static func idle_pose(time: float) -> Dictionary:
	return {"expr": "piscar" if fmod(time, 3.3) < 0.12 else "normal", "body_off": Vector2(0, sin(time * 2.4) * 0.8),
		"lean": 0.0, "feet": [Vector2.ZERO, Vector2.ZERO], "knee": [Vector2(1.5, 0), Vector2(1.5, 0)],
		"hb_off": Vector2(0, sin(time * 2.4) * 0.6), "hf_off": Vector2.ZERO, "hammer_ang": HAMMER_REST,
		"ant": sin(time * 3.1) * 0.12, "rest": true}

static func victory_pose(time: float, danca := 0) -> Dictionary:
	var hop := -absf(sin(time * 6.0)) * 8.0
	var p := idle_pose(time)
	match danca:
		1:   # marreteiro: bate a ferramenta no chão sem parar
			var k := fposmod(time * 2.2, 1.0)
			var sw := -2.4 + 2.6 * smoothstep(0.0, 0.35, k) - 2.6 * smoothstep(0.55, 1.0, k)
			p["expr"] = "vitoria" if k > 0.3 else "esforco"
			p["lean"] = 0.18 * smoothstep(0.0, 0.35, k)
			p["body_off"] = Vector2(0, -3.0 * (1.0 - smoothstep(0.0, 0.3, k)))
			p["hammer_ang"] = sw
			p["hf_off"] = Vector2(6, -14 + 16 * smoothstep(0.0, 0.35, k))
			p["hb_off"] = Vector2(-2, -18)
			p["ant"] = sin(time * 14.0) * 0.4
			return p
		2:   # pião: gira no lugar (o desenho vira de lado a lado) com os braços abertos
			p["expr"] = "vitoria"
			p["spin"] = cos(time * 9.0)
			p["body_off"] = Vector2(0, -absf(sin(time * 9.0)) * 4.0)
			p["hb_off"] = Vector2(-10, -12)
			p["hf_off"] = Vector2(10, -12)
			p["hammer_ang"] = -1.2
			p["ant"] = sin(time * 18.0) * 0.5
			return p
		3:   # robozinho: braços travados em ângulos, cabeça para os lados
			var st := int(time * 4.0) % 4
			p["expr"] = "vitoria" if st % 2 == 0 else "normal"
			p["lean"] = [-0.12, 0.0, 0.12, 0.0][st]
			p["hb_off"] = [Vector2(-6, -20), Vector2(-4, 0), Vector2(-6, -20), Vector2(-4, 0)][st]
			p["hf_off"] = [Vector2(4, 0), Vector2(6, -20), Vector2(4, 0), Vector2(6, -20)][st]
			p["feet"] = [Vector2(-2, [0, -6, 0, 0][st]), Vector2(2, [0, 0, 0, -6][st])]
			p["hammer_ang"] = [0.35, -1.0, 0.35, -1.0][st]
			p["ant"] = [0.4, -0.4, 0.4, -0.4][st]
			return p
	p["expr"] = "vitoria"
	p["body_off"] = Vector2(0, hop)
	p["feet"] = [Vector2(-1, hop * 0.6), Vector2(1, hop * 0.6)]
	p["knee"] = [Vector2(4, 0), Vector2(4, 0)]
	p["hb_off"] = Vector2(-2, -22 + sin(time * 12.0) * 4.0)
	p["hf_off"] = Vector2(2, -16 + cos(time * 12.0) * 4.0)
	p["hammer_ang"] = -0.3 + sin(time * 12.0) * 0.35
	p["ant"] = sin(time * 12.0) * 0.35
	return p

## Desenha o robô montado em qualquer CanvasItem. look = {color, model, hammer, fx}; pose = ver topo.
static func draw_robot(ci: CanvasItem, lk: Dictionary, pose: Dictionary, base := Transform2D.IDENTITY) -> void:
	var col_idx: int = lk["color"]
	var mname: String = Data.MODELS[posmod(int(lk["model"]), Data.MODELS.size())]
	var sk := _sk(lk, mname)
	var body := Data.tex("robo/corpo_%s%s_p%d" % [mname, sk, col_idx + 1])
	if body == null or Data.robot_meta.is_empty():
		return
	var fxm: Dictionary = lk.get("fx", {})
	if String(fxm.get("mecha", "")) != "" and Data.mecha_meta.get("mechas", {}).has(String(fxm["mecha"])):
		_draw_mecha(ci, lk, pose, base, fxm, mname, col_idx)
		return
	if pose.has("rot"):   # mortal, giro do arremesso, esquiva no ar: gira em torno do meio do corpo
		base = base * Transform2D(float(pose["rot"]), PIVOT) * Transform2D(0.0, -PIVOT)
	var tk := float(pose.get("tuck", 0.0))
	if tk > 0.0:   # cambalhota: achata no eixo do próprio corpo (depois do giro), não no da tela
		base = base * Transform2D(0.0, Vector2(1.0 + 0.2 * tk, 1.0 - 0.3 * tk), 0.0, PIVOT * Vector2(0, 1) * (0.3 * tk))
	if pose.has("spin"):   # comemoração "pião": achata na horizontal passando pelo meio
		var sp: float = pose["spin"]
		base = base * Transform2D(0.0, Vector2(signf(sp) * maxf(absf(sp), 0.32), 1.0), 0.0, Vector2.ZERO)
	var g: Dictionary = Data.robot_meta["modelos"][mname]
	var limb := Color(Data.robot_meta["membros"][col_idx])
	var lw := float(g["limb_w"])
	var q := Vector2(0.25, 0.25)
	var hand_q: Vector2 = q * float(g["hand_s"])
	# corpo inclina em torno do quadril
	var hips: Array = g["hips"]
	var pivot := (_v(hips[0]) + _v(hips[1])) / 2.0
	var bx := Transform2D(0.0, pose["body_off"] + pivot) * Transform2D(pose["lean"], Vector2.ZERO) * Transform2D(0.0, -pivot)
	var sh: Array = g["shoulders"]
	var ham_ang := float(pose["hammer_ang"])
	var hf: Vector2
	if pose.has("hf_abs"):
		hf = pose["hf_abs"]
	elif pose.get("rest", false):   # telas (entrada, vitória): parte da pose "parado" do robô
		var fp0: Dictionary = g["poses"]["parado"]
		hf = bx * Vector2(float(fp0["hf"][0]), float(fp0["hf"][1])) + pose["hf_off"]
		ham_ang = float(fp0["a"]) + (ham_ang - HAMMER_REST)
	else:
		hf = bx * _v(g["hand_front"]) + pose["hf_off"]
	var fx: Dictionary = lk.get("fx", {})
	var tool: String = pose.get("tool", "")
	var armor0: bool = fx.get("armor", false)
	var hb: Vector2
	if pose.has("hb_abs"):
		hb = pose["hb_abs"]
	elif pose.get("two_hand", true) and tool == "" and lk.get("hammer", true) and not armor0:
		hb = hf + Vector2(float(g["grip2"][0]), float(g["grip2"][1])).rotated(ham_ang)   # as duas mãos no cabo
	else:
		hb = bx * _v(g["hand_back"]) + pose["hb_off"]
	var ttex := Data.tex("robo/ferramenta_" + mname + sk)
	var tsz := Vector2(float(g["tool"][0]), float(g["tool"][1]))
	var tgr := Vector2(float(g["tool_grip"][0]), float(g["tool_grip"][1]))
	var reach := float(g.get("reach", 40.0))
	# rastro do golpe (arco branco por onde a cabeça da marreta passou)
	var smear: Array = pose.get("smear", [0.0, 0.0, 0.0])
	if float(smear[2]) > 0.01 and tool == "":
		var a0 := float(smear[0])
		var a1 := float(smear[1])
		var poly := PackedVector2Array()
		var n := 10
		for i in n + 1:
			var aa := lerpf(a0, a1, float(i) / n)
			poly.append(hf + Vector2(sin(aa), -cos(aa)) * (reach + 8.0))
		for i in range(n, -1, -1):
			var aa := lerpf(a0, a1, float(i) / n)
			var w := reach + 8.0 - 20.0 * pow(float(i) / n, 0.5)
			poly.append(hf + Vector2(sin(aa), -cos(aa)) * w)
		ci.draw_set_transform_matrix(base)
		if poly.size() >= 3 and absf(a1 - a0) > 0.2:
			ci.draw_colored_polygon(poly, Color(1, 1, 1, 0.55 * float(smear[2])))
	var sf: Dictionary = fx
	var armor: bool = sf.get("armor", false)
	var aspec: Dictionary = ARMOR_SETS.get(String(sf.get("armor_set", "T01")), ARMOR_SETS["T01"])
	var asm := float(sf.get("assemble", 1.0)) if armor else 0.0
	if armor:   # armadura: membros grossos no metal da máquina
		lw *= 1.0 + 0.9 * asm
		limb = limb.lerp(Color(aspec["limb"]), 0.75 * asm)
	var sid0: String = String(sf.get("spell", ""))
	if lk.get("hammer", true) and tool != "" and not armor:
		# arma na mão: a marreta fica presa nas costas, na diagonal
		ci.draw_set_transform_matrix(base * bx * Transform2D(2.45, Vector2(0.8, 0.8), 0.0, _v(sh[0]) + Vector2(-8, 6)))
		ci.draw_texture_rect(ttex, Rect2(-tgr, tsz), false)
	if sid0 in WEAPONS and tool == "" and not armor and not sf.get("fading", false):
		# golpeando com a marreta: a arma vai para as costas
		var spec0: Array = SPELL_TOOLS[sid0]
		ci.draw_set_transform_matrix(base * bx * Transform2D(-2.2, Vector2.ONE, 0.0, _v(sh[0]) + Vector2(-10, 8)))
		ci.draw_texture_rect(Data.tex("spells/" + spec0[0]), Rect2(-spec0[1] * 0.4, spec0[1] * 0.8), false)
	var kit_on: bool = KITS.has(sid0) and not armor and not sf.has("form") and not sf.get("fading", false)
	if kit_on:   # kit nas costas (atrás do corpo): peça de costas + placa da frente dobrada espiando no ombro
		var kd: Array = KITS[sid0]
		var anchor: Vector2 = (_v(sh[0]) + _v(hips[0])) / 2.0 + Vector2(-9, 3) + (Vector2(-2, -16) if sid0 == "T07" else Vector2.ZERO)
		if String(kd[3]) != "":
			ci.draw_set_transform_matrix(base * bx * Transform2D(float(kd[5]), anchor + Vector2(-2, -20)))
			ci.draw_texture_rect(Data.tex("spells/" + kd[3]), Rect2(-kd[4] / 2.0, kd[4]), false)
		ci.draw_set_transform_matrix(base * bx * Transform2D(float(kd[2]), anchor))
		ci.draw_texture_rect(Data.tex("spells/" + kd[0]), Rect2(-kd[1] / 2.0, kd[1]), false)
	var moch_on: bool = sid0 in MECHA_CART and not armor and not sf.has("form") and not sf.get("fading", false) and not sf.has("mecha")
	var moch_anc: Vector2 = (_v(sh[0]) + _v(hips[0])) / 2.0 + Vector2(-13, -4) + MOCH_OFF.get(mname, Vector2.ZERO)
	if moch_on:   # A aprovada (2026-11-27): a cápsula do mecha vai nas COSTAS, como mochila (nada na mão)
		_draw_mochila(ci, base * bx, sid0, moch_anc, 1.0, -0.12)
	if BACK_PROPS.has(sid0) and not armor and not sf.get("fading", false) and not (sid0 == "A04" and (float(sf.get("prep", -1.0)) >= 0.0 or float(sf.get("fire", -1.0)) >= 0.0)):
		var bp: Array = BACK_PROPS[sid0]
		ci.draw_set_transform_matrix(base * bx * Transform2D(float(bp[2]), _v(sh[0]) + Vector2(-12, 10)))
		ci.draw_texture_rect(Data.tex("spells/" + bp[0]), Rect2(-bp[1] / 2.0, bp[1]), false)
	var eye: Vector2 = (_v(g["eyes"][0]) + _v(g["eyes"][1])) / 2.0
	var afit: Array = armor_fit(mname) if armor else [eye, 1.0]
	var aw: Vector2 = afit[0]
	var asx: float = afit[1]
	if armor:   # costas da armadura (tanque + chaminé) atrás do corpo
		_armor_piece(ci, base * bx, aspec["back"], asm, aw + Vector2(-5, 0), sf, asx)
	# pernas + botas (grossura, dobra do joelho e bota de cada robô)
	var foot := Data.tex("robo/pe")
	var legw := float(g.get("leg_w", lw)) * (1.0 + 0.9 * asm)
	var foot_s := float(g.get("foot_s", 1.0))
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var hip: Vector2 = bx * _v(hips[i])
		var fp: Vector2 = Vector2(_v(hips[i]).x + s * 4.0, -4.0) + pose["feet"][i]
		_limb(ci, base, hip, fp, limb.darkened(0.12) if i == 0 else limb, pose["knee"][i], legw)
		if armor and String(sf.get("armor_set", "")) == "T02" and asm > 0.5:   # mecha empilhadeira: rodas no lugar dos pés
			ci.draw_set_transform_matrix(base)
			var wc := fp + Vector2(s * 1.5, -4.0)
			ci.draw_circle(wc, 9.5, Color("#2a1a2e"))
			ci.draw_circle(wc, 6.5, Color("#71829a"))
			var sp_a := Time.get_ticks_msec() / 90.0
			for k in 3:
				ci.draw_line(wc, wc + Vector2.from_angle(sp_a + k * TAU / 3.0) * 6.0, Color("#2a1a2e"), 1.6, true)
			ci.draw_circle(wc, 2.4, Color("#f2c84b"))
		else:
			ci.draw_set_transform_matrix(base * Transform2D(0.0, q * (0.72 + 0.2 * asm) * foot_s, 0.0, fp + Vector2(s * 1.5, 0.5)))
			ci.draw_texture(foot, -Vector2(12, 7) * 4.0, limb.darkened(0.12) if i == 0 else limb)
	# jato do propulsor saindo dos pés (pulo duplo)
	var jet := float(pose.get("jet", 0.0))
	if jet > 0.01:
		ci.draw_set_transform_matrix(base)
		var flick := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 25.0)
		for i in 2:
			var fp2: Vector2 = Vector2(_v(hips[i]).x + (-1.0 if i == 0 else 1.0) * 4.0, -4.0) + pose["feet"][i] + Vector2(0, 6)
			var L := 30.0 * jet * flick
			ci.draw_colored_polygon(PackedVector2Array([fp2 + Vector2(-6, 0), fp2 + Vector2(6, 0), fp2 + Vector2(0, L)]), Color("#f6a23a"))
			ci.draw_colored_polygon(PackedVector2Array([fp2 + Vector2(-3, 0), fp2 + Vector2(3, 0), fp2 + Vector2(0, L * 0.55)]), Color("#fff1b8"))
	_limb(ci, base, bx * _v(sh[0]), hb, limb.darkened(0.12), Vector2(0, 3), lw)
	# corpo + rosto + antena (mola)
	ci.draw_set_transform_matrix(base * bx * Transform2D(0.0, q, 0.0, -ORIGIN))
	ci.draw_texture(body, Vector2.ZERO)
	var dl: int = lk.get("dmg", 0)
	if dl > 0:
		var dtex := Data.tex("robo/dano%d_%s" % [dl, mname])
		if dtex != null:
			ci.draw_texture(dtex, Vector2.ZERO)
	ci.draw_texture(Data.tex("robo/rosto_%s_%s" % [mname, pose["expr"]]), Vector2.ZERO)
	if dl >= 3:
		# plaquinha solta pendurada por um parafuso, balançando
		var hinge := (_v(sh[1]) + _v(hips[1])) / 2.0 + Vector2(-2, -4)
		ci.draw_set_transform_matrix(base * bx * Transform2D(float(pose.get("panel", 0.0)) + 0.35, hinge))
		ci.draw_rect(Rect2(-5, 0, 11, 14), limb.lightened(0.25))
		ci.draw_rect(Rect2(-5, 11, 11, 3), limb)
		ci.draw_circle(Vector2(0, 2), 1.8, Color("#c9d1d8"))
	if moch_on:   # alça da mochila cruzando o peito
		ci.draw_set_transform_matrix(base * bx)
		var s0: Vector2 = _v(sh[0]) + Vector2(-1, -2)
		var s1: Vector2 = (_v(sh[1]) + _v(hips[1])) / 2.0 + Vector2(2, 3)
		var sc: Vector2 = s0.lerp(s1, 0.5) + Vector2(5, -5)
		var pts := PackedVector2Array()
		for i in 9:
			var u := i / 8.0
			pts.append(s0.lerp(sc, u).lerp(sc.lerp(s1, u), u))
		ci.draw_polyline(pts, Color("#2b2b33"), 3.4, true)
		ci.draw_circle(s1, 2.6, Color("#5d6672"))
	var ab := _v(g["antenna"])
	ci.draw_set_transform_matrix(base * bx * Transform2D(pose["ant"], ab) * Transform2D(0.0, q, 0.0, -ab - ORIGIN))
	ci.draw_texture(Data.tex("robo/antena_" + mname), Vector2.ZERO)
	var tnow := Time.get_ticks_msec() / 1000.0
	if lk.get("hammer", true) and tool == "" and not armor:
		var seis: bool = sf.get("spell", "") == "A04" and (float(sf.get("prep", -1.0)) >= 0.0 or (float(sf.get("fire", -1.0)) >= 0.0 and float(sf.get("fire", -1.0)) < 0.55))
		if not seis:   # ferramenta nas mãos, na frente do corpo (na marretada sísmica a marreta gigante é de modes/spells.gd)
			ci.draw_set_transform_matrix(base * Transform2D(ham_ang, hf))
			var hcol := Color(0.58, 0.62, 0.72) if lk.get("ham_cd", false) else Color.WHITE
			ci.draw_texture_rect(ttex, Rect2(-tgr, tsz), false, hcol)
			if pose.get("a07_pronto", false):   # A07 equipada: energia girando em volta da cabeça da ferramenta
				var hd := hf + Vector2(sin(ham_ang), -cos(ham_ang)) * reach * 0.85
				ci.draw_set_transform_matrix(base)
				ci.draw_arc(hd, 22.0, tnow * 9.0, tnow * 9.0 + 2.2, 12, Color(1.0, 0.62, 0.2, 0.9), 4.0, true)
				ci.draw_arc(hd, 22.0, tnow * 9.0 + PI, tnow * 9.0 + PI + 2.2, 12, Color(1.0, 0.85, 0.35, 0.9), 4.0, true)
				for k in 3:
					var aa := tnow * 6.0 + k * TAU / 3.0
					ci.draw_circle(hd + Vector2(cos(aa), sin(aa)) * 28.0, 3.0, Color("#ffd36b"))
	if armor:   # frente da armadura por cima do corpo; o rosto do robô aparece na vigia
		_armor_piece(ci, base * bx, aspec["front"], asm, aw, sf, asx)
		var drop := Vector2(0, -(1.0 - asm) * 30.0)
		var eye_real := eye
		eye = aw
		var win: String = aspec["window"]
		ci.draw_set_transform_matrix(base * bx)
		if win == "circle":
			ci.draw_circle(eye + drop, 10.0, Color("#2b3d4f"))
		else:
			ci.draw_rect(Rect2(eye + drop - Vector2(13, 8), Vector2(26, 16)), Color("#2b3d4f") if win == "rect" else Color("#1d3a22"))
		ci.draw_set_transform_matrix(base * bx * Transform2D(0.0, q, 0.0, -ORIGIN + (aw - eye_real) * asm + drop))   # rosto na vigia
		ci.draw_texture(Data.tex("robo/rosto_%s_%s" % [mname, pose["expr"]]), Vector2.ZERO)
		ci.draw_set_transform_matrix(base * bx)
		var ring := Color(aspec["ring"])
		match win:
			"circle":
				ci.draw_arc(eye + drop, 10.4, 0, TAU, 20, ring, 3.0, true)
				ci.draw_arc(eye + drop + Vector2(-1.5, -1.5), 6.4, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.6), 1.6, true)
			"rect":   # cabine: moldura + reflexo
				ci.draw_rect(Rect2(eye + drop - Vector2(13, 8), Vector2(26, 16)), ring, false, 2.5)
				ci.draw_line(eye + drop + Vector2(-9, -5), eye + drop + Vector2(-4, -8), Color(1, 1, 1, 0.6), 1.6, true)
			"visor":  # visor de solda: vidro verde escuro por cima do rosto; acende com o arco
				var glow: bool = sf.get("arc", false)
				ci.draw_rect(Rect2(eye + drop - Vector2(13, 8), Vector2(26, 16)), Color(0.2, 0.9, 0.4, 0.55) if glow else Color(0.08, 0.25, 0.12, 0.55))
				ci.draw_rect(Rect2(eye + drop - Vector2(13, 8), Vector2(26, 16)), ring, false, 2.5)
				ci.draw_line(eye + drop + Vector2(-10, -5), eye + drop + Vector2(10, -5), Color(1, 1, 1, 0.35), 1.4, true)
	if kit_on:   # alças passando pela frente do peito (por cima do corpo) com fivela
		ci.draw_set_transform_matrix(base * bx)
		var s0: Vector2 = _v(sh[0]) + Vector2(1, -4)
		var h1: Vector2 = _v(hips[1]) + Vector2(-1, -7)
		ci.draw_line(s0, h1, Color("#2a1a2e"), 5.5, true)
		ci.draw_line(s0, h1, Color("#8f5a2c"), 3.0, true)
		var bk := s0.lerp(h1, 0.55)
		ci.draw_rect(Rect2(bk - Vector2(3.5, 3.5), Vector2(7, 7)), Color("#2a1a2e"))
		ci.draw_rect(Rect2(bk - Vector2(2, 2), Vector2(4, 4)), Color("#f2c84b"))
	if HAND_PROPS.has(sid0) and not armor and not sf.has("form") and not sf.get("flying_on", false) and not sf.get("fading", false) and float(sf.get("fire", -1.0)) < 0.0:
		var hp: Array = HAND_PROPS[sid0] if not (sid0 == "E02" and sf.get("placed", false)) else ["s12_detonador", Vector2(12, 25)]   # lote 3: dinamite na mão; depois de jogar, o detonador de antena
		ci.draw_set_transform_matrix(base * Transform2D(-0.4, hb + Vector2(-2, -4)))
		ci.draw_texture_rect(Data.tex("spells/" + hp[0]), Rect2(-hp[1] / 2.0, hp[1]), false)
	if sid0 == "A06" and not sf.get("fading", false):   # controle remoto do bate-estaca, luz piscando
		ci.draw_set_transform_matrix(base * Transform2D(-0.2, hb + Vector2(-1, -6)))
		ci.draw_rect(Rect2(-6, -9, 12, 18), Color("#2a1a2e"))
		ci.draw_rect(Rect2(-4.5, -7.5, 9, 15), Color("#f2c84b"))
		ci.draw_circle(Vector2(0, -2), 3.0, Color("#d94a3a") if fmod(tnow, 0.5) < 0.25 else Color("#7a2a20"))
		ci.draw_line(Vector2(3, -9), Vector2(5, -16), Color("#2a1a2e"), 1.6, true)
	if sid0 == "C04" and not sf.get("fading", false):   # faísquinhas roxas orbitando a mão
		ci.draw_set_transform_matrix(base)
		for k in 3:
			var a := tnow * 5.0 + k * TAU / 3.0
			ci.draw_circle(hf + Vector2(cos(a), sin(a) * 0.6) * 10.0, 2.2, Color(0.72, 0.6, 1.0, 0.9))
	if tool != "" and SPELL_TOOLS.has(tool):
		# arma da spell presa na mão da frente (ponto de pega embaixo da mão)
		var spec: Array = SPELL_TOOLS[tool]
		var tx := Data.tex("spells/" + spec[0])
		var sz: Vector2 = spec[1]
		var dsz := Vector2(tx.get_width(), tx.get_height()) / 2.0   # tamanho de design
		var grip: Vector2 = spec[2] * sz / dsz
		var txf := base * Transform2D(float(pose.get("tool_ang", 0.0)), hf)
		ci.draw_set_transform_matrix(txf)
		ci.draw_texture_rect(tx, Rect2(-grip, sz), false)
		# bico desenhado neste quadro (mundo): tiros e feixes saem exatamente daqui (modes/spells.gd muzzle)
		ci.set_meta("bico", [tool, ci.get_global_transform() * (txf * (spec[3] * sz / dsz - grip)), Engine.get_process_frames()])
		if tool == "F31":   # broca girando: sulcos correndo do colar até a ponta
			var tn := Time.get_ticks_msec() / 1000.0
			var sc2 := sz.x / dsz.x
			for k in 4:
				var u := fposmod(tn * 5.0 + k * 0.25, 1.0)
				var x: float = (32.0 + u * 74.0 - spec[2].x) * sc2
				var hh := 22.0 * (1.0 - u) * sc2
				ci.draw_line(Vector2(x, -hh), Vector2(x + 5.0, hh), Color(0.25, 0.28, 0.33, 0.9), 2.2, true)
		if tool == "C01" and float(sf.get("fire", -1.0)) >= 0.0:
			for k in 3:
				var rr := 8.0 + fposmod(tnow * 60.0 + k * 7.0, 20.0)
				ci.draw_arc(Vector2(sz.x - grip.x, 0), rr, -0.9, 0.9, 8, Color(0.85, 0.29, 0.35, 1.0 - rr / 28.0), 2.0, true)
		var pk := float(sf.get("prep", -1.0))
		if pk > 0.0 and tool == "A01":   # pistão carregando: vapor saindo
			for k in 3:
				var u := fposmod(tnow * 3.0 + k * 0.33, 1.0)
				ci.draw_circle(Vector2(-grip.x + 4.0, -6.0 - u * 18.0), 3.0 + u * 4.0, Color(1, 1, 1, 0.6 * (1.0 - u) * pk))
	_limb(ci, base, bx * (_v(sh[1]).lerp(armor_shoulder(mname), asm) if armor else _v(sh[1])), hf, limb, Vector2(0, 3), lw)
	# brilho na cabeça da marreta no fim do preparo da pesada
	var gl := float(pose.get("glint", 0.0))
	if gl > 0.0:
		var head := hf + Vector2(sin(ham_ang), -cos(ham_ang)) * reach
		ci.draw_set_transform_matrix(base * Transform2D(Time.get_ticks_msec() / 200.0, head))
		var st := Data.tex("cenario/brilho")
		var sz := 10.0 + 18.0 * gl
		ci.draw_texture_rect(st, Rect2(-sz / 2, -sz / 2, sz, sz), false, Color(1, 1, 0.8, gl))
	# janela de proteção da esquiva: contorno branco discreto
	var gd := float(pose.get("guard", 0.0))
	if gd > 0.0:
		ci.draw_set_transform_matrix(base)
		ci.draw_arc(PIVOT, 46.0, 0, TAU, 32, Color(1, 1, 1, 0.45 * gd), 3.0, true)
	var hand := Data.tex("robo/mao")
	for p in [hb, hf]:
		ci.draw_set_transform_matrix(base * Transform2D(0.0, hand_q, 0.0, p))
		ci.draw_texture(hand, -Vector2(8, 8) * 4.0)
	ci.draw_set_transform_matrix(base)

## MOCHILA DO MECHA (proposta A aprovada 2026-11-27, substitui o cartucho na mão + holograma): a cápsula do mecha vai
## presa nas COSTAS com uma alça no peito; o núcleo pulsa. Arte: art/src/robos/mecha_porte.py --jogo (spells/mochila_T0x).
const MOCH_OFF := {"britadeira": Vector2(-3, 9)}   # a betoneira da Brita cobre as costas: mochila mais baixa e recuada
const MECHA_CART := ["T01", "T02", "T03", "T04", "T05", "T06", "T07"]

static func _draw_mochila(ci: CanvasItem, xf: Transform2D, id: String, at: Vector2, k := 1.0, rot := 0.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var mt: Texture2D = Data.tex("spells/mochila_" + id)
	if mt == null:
		return
	var sc := 0.135 * k
	ci.draw_set_transform_matrix(xf * Transform2D(rot, Vector2(sc, sc), 0.0, at))
	ci.draw_texture(mt, -Vector2(192, 352))
	ci.draw_circle(Vector2(0, -20), 70.0 + 22.0 * sin(now * 6.0), Color(1, 0.95, 0.75, 0.22))
	ci.draw_set_transform_matrix(xf)

## Placa da Armadura Fornalha (T01): arte de design 150x130 em escala 0,48 (o robô "vira" a fornalha), vigia (75,50) em `at`.
## Montagem: cai de cima e assenta; nos últimos instantes pisca avisando que vai desmontar.
## ---------------------------------------------------------------- ARMADURAS-MECHA (A29/A34): o robô PILOTA um mecha
## Peças de art/src/robos/armaduras_export.py (mesma caixa e origem; pés em 0,0; unidades do desenho). O mecha é um
## ESQUELETO: pelve/tronco (B), pernas coxa→canela→pé e braço de trás braço→antebraço resolvidos por cinemática
## inversa (o pé PLANTA no chão durante o apoio: não escorrega), cabeça com atraso, braço-arma girando no ombro.
## Cada mecha tem um jeito próprio (MECHA_ESTILO) de ficar parado, andar/correr, pular, pousar, dar pulo duplo, dash e
## golpear (MECHA_GOLPES: antecipação → impacto → continuação → volta).
const MECHA_CHEGADA := {   # grupo: [início, fim, de onde vem dx, dy, giro em graus] (tempo da montagem 0.3→1.2)
	"perna_b": [0.40, 0.62, -160, 120, -90], "perna_f": [0.44, 0.66, 160, 120, 90], "tronco": [0.52, 0.76, 0, -260, 25],
	"cabine": [0.58, 0.82, 0, -60, 0], "peito": [0.62, 0.84, 0, -200, -20], "braco_b": [0.70, 0.90, -220, -40, -140],
	"ombro_b": [0.74, 0.94, -200, -160, -120], "arma": [0.80, 1.0, 260, -30, 160], "ombro_f": [0.84, 1.04, 220, -170, 140],
	"costas": [0.88, 1.08, -120, -240, -60], "cabeca": [0.98, 1.16, 0, -300, 200]}
const MECHA_GRUPO := {"coxa_b": "perna_b", "canela_b": "perna_b", "pe_b": "perna_b", "coxa_f": "perna_f", "canela_f": "perna_f",
	"pe_f": "perna_f", "braco_b_sup": "braco_b", "braco_b_inf": "braco_b"}
const MECHA_MIRA := ["T01", "T04", "T06"]
## Escala de jogo do mecha (A32): ~2 blocos de altura; a colisão continua a do robô.
const MECHA_ESCALA := 0.74

static func mecha_px() -> float:
	return float(Data.mecha_meta.get("px", 0.84)) * MECHA_ESCALA

## Jeito de cada mecha. ciclo = px andados por ciclo (2 passos); duty = fração do ciclo com o pé no chão; passo_h =
## altura do pé no passo; queda = afunda ao pisar; quica = sobe no voo da corrida; incl = inclina correndo; ginga =
## balança de lado; agacha = joelho dobrado parado; braco = balanço do braço de trás; cab = atraso da cabeça (graus).
const MECHA_ESTILO := {
	"T01": {"tipo": "pesado", "ciclo": 120.0, "duty": 0.62, "passo_h": 9.0, "queda": 6.0, "quica": 3.0, "incl": 6.0, "ginga": 5.0, "agacha": 3.0, "braco": 8.0, "cab": 6.0, "resp": 1.8},
	"T02": {"tipo": "mecanico", "ciclo": 150.0, "duty": 0.55, "passo_h": 14.0, "queda": 2.0, "quica": 2.0, "incl": 3.0, "ginga": 0.0, "agacha": 1.5, "braco": 5.0, "cab": 2.0, "resp": 0.8},
	"T03": {"tipo": "gorila", "ciclo": 130.0, "duty": 0.6, "passo_h": 8.0, "queda": 7.0, "quica": 4.0, "incl": 14.0, "ginga": 4.0, "agacha": 4.0, "braco": 0.0, "cab": 7.0, "resp": 2.2},
	"T04": {"tipo": "voo", "ciclo": 160.0, "duty": 0.5, "passo_h": 6.0, "queda": 0.0, "quica": 0.0, "incl": 16.0, "ginga": 0.0, "agacha": 0.0, "braco": 6.0, "cab": 4.0, "resp": 2.5},
	"T05": {"tipo": "corredor", "ciclo": 190.0, "duty": 0.42, "passo_h": 20.0, "queda": 3.0, "quica": 6.0, "incl": 13.0, "ginga": 2.0, "agacha": 6.0, "braco": 16.0, "cab": 4.0, "resp": 1.2},
	"T06": {"tipo": "corcunda", "ciclo": 95.0, "duty": 0.55, "passo_h": 7.0, "queda": 3.0, "quica": 2.0, "incl": 16.0, "ginga": 3.0, "agacha": 5.0, "braco": 9.0, "cab": 8.0, "resp": 1.5},
	# A36 Corredor: passada enorme e rápida, pouco tempo no chão, quica muito, inclinado como velocista
	"T07": {"tipo": "velocista", "ciclo": 260.0, "duty": 0.34, "passo_h": 26.0, "queda": 2.0, "quica": 10.0, "incl": 20.0, "ginga": 1.5, "agacha": 7.0, "braco": 22.0, "cab": 5.0, "resp": 2.0}}

## Golpes: [antecipação, impacto]. bx/by = corpo (unidades), br = giro do corpo, ar/ax = giro/avanço do braço-arma,
## hbx/hby = mão de trás, ffx/ffy = pé da frente, fbx = pé de trás, cr = cabeça (graus).
const MECHA_GOLPES := {
	"pesado_rapido": [{"bx": -6, "br": -8, "ar": -40, "ax": -16, "hbx": 6, "cr": -5}, {"bx": 10, "br": 10, "ar": 14, "ax": 30, "hbx": -12, "ffx": 10, "cr": 6}],
	"pesado_pesado": [{"by": -8, "br": -12, "ar": -70, "hby": -24, "ffx": 6, "ffy": -30, "cr": -8}, {"by": 12, "br": 8, "ar": 24, "hby": 8, "ffx": 12, "cr": 8}],
	"mecanico_rapido": [{"bx": -8, "br": -4, "ax": -20}, {"bx": 14, "br": 8, "ax": 46, "ffx": 14}],
	"mecanico_pesado": [{"by": -8, "br": -14, "ar": -125}, {"by": 10, "br": 16, "ar": 38, "ax": 16, "ffx": 16}],
	"gorila_rapido": [{"bx": -6, "br": -6, "ar": -30, "ax": -12, "hbx": -16}, {"bx": 12, "br": 12, "ar": 10, "ax": 26, "hbx": 70, "hby": -34, "ffx": 12}],
	"gorila_pesado": [{"by": -18, "br": -16, "ar": -150, "hbx": 30, "hby": -100, "cr": -10}, {"by": 14, "br": 26, "ar": 66, "hbx": 70, "hby": 24, "ffx": 10}],
	"corredor_rapido": [{"bx": -6, "br": -5, "ax": -18}, {"bx": 16, "br": 10, "ax": 42, "ffx": 16}],
	"corredor_pesado": [{"bx": -14, "by": 6, "br": -14, "ax": -26, "ar": -10, "ffx": -6}, {"bx": 30, "by": 4, "br": 18, "ax": 52, "ffx": 28, "fbx": -10}],
	"corcunda_rapido": [{"bx": -4, "br": -10, "ar": -28, "ax": -10}, {"bx": 10, "br": 8, "ar": 6, "ax": 30, "ffx": 10}],
	"corcunda_pesado": [{"by": -14, "br": -20, "ar": -115, "hbx": -10, "hby": -74, "cr": -14}, {"by": 6, "br": 14, "ar": 42, "hbx": -30, "hby": 20, "cr": 10}],
	"velocista_rapido": [{"bx": -4, "br": -6, "ffx": -8, "ffy": 0}, {"bx": 12, "br": 6, "ffx": 26, "ffy": -44, "ax": 14, "cr": 6}],   # joelhada-relâmpago
	"velocista_pesado": [{"bx": -12, "by": 8, "br": -10, "ffx": -10, "fbx": -6}, {"bx": 34, "by": 30, "br": -18, "ffx": 46, "ffy": -10, "fbx": -24, "ar": -30, "cr": 10}],   # voadora deslizante
	"voo_rapido": [{"bx": -8, "br": -8, "ar": -22, "ax": -14}, {"bx": 16, "br": 12, "ax": 46}],
	"voo_pesado": [{"by": 6, "br": -16, "ar": 60, "ax": -10}, {"by": -14, "br": -10, "ar": -85, "ax": 30}]}

static func _ease_back(u: float) -> float:
	var s := 1.9
	u -= 1.0
	return u * u * ((s + 1.0) * u + s) + 1.0

static func _smooth(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

static func _jv(j) -> Vector2:
	return Vector2(float(j[0]), float(j[1]))

## Cinemática inversa de 2 ossos: raiz a, alvo c, comprimentos l1/l2, lado da dobra sgn. Devolve [junta do meio, ponta].
static func _ik2(a: Vector2, c: Vector2, l1: float, l2: float, sgn: float) -> Array:
	var v := c - a
	var d := clampf(v.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var dir := v.normalized() if v.length() > 0.001 else Vector2.DOWN
	var c2 := a + dir * d
	var x := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - x * x, 0.0))
	return [a + dir * x + Vector2(-dir.y, dir.x) * h * sgn, c2]

static func _dobra(a: Vector2, b: Vector2, c: Vector2) -> float:
	return 1.0 if (b - a).cross(c - a) < 0.0 else -1.0

## Transformação de um osso: o segmento p0→q0 do desenho vai para p1→q1 (gira em volta da junta).
static func _osso(p0: Vector2, q0: Vector2, p1: Vector2, q1: Vector2) -> Transform2D:
	var ang := (q1 - p1).angle() - (q0 - p0).angle()
	return Transform2D(0.0, p1) * Transform2D(ang, Vector2.ZERO) * Transform2D(0.0, -p0)

static func _golpe(st: Dictionary, fx: Dictionary) -> Dictionary:
	var ak := String(fx.get("matk", ""))
	if ak == "":
		return {}
	var key := String(st["tipo"]) + "_" + ("pesado" if ak == "pesado" else "rapido")
	if not MECHA_GOLPES.has(key):
		return {}
	var kf: Array = MECHA_GOLPES[key]
	var at := float(fx.get("matk_t", 0.0))
	var pre := maxf(float(fx.get("matk_pre", 0.1)), 0.01)
	var tot := maxf(float(fx.get("matk_tot", 0.3)), pre + 0.1)
	var out := {}
	var ant: Dictionary = kf[0]
	var hit: Dictionary = kf[1]
	for k in ["bx", "by", "br", "ar", "ax", "hbx", "hby", "ffx", "ffy", "fbx", "cr"]:
		var va := float(ant.get(k, 0.0))
		var vh := float(hit.get(k, 0.0))
		var v := 0.0
		if at < pre:   # antecipação: vai juntando força (devagar no começo)
			v = va * _smooth(at / pre)
		elif at < pre + 0.07:   # impacto: rápido, passa um pouco do ponto
			v = lerpf(va, vh, _ease_back((at - pre) / 0.07))
		else:   # continuação e volta com mola amortecida
			var u := clampf((at - pre - 0.07) / (tot - pre - 0.07), 0.0, 1.0)
			v = vh * (1.0 - _smooth(u)) * (1.0 + 0.12 * sin(u * 9.0) * (1.0 - u))
		out[k] = v
	return out

static func _draw_mecha(ci: CanvasItem, lk: Dictionary, pose: Dictionary, base: Transform2D, fx: Dictionary, mname: String, col_idx: int) -> void:
	var mid := String(fx["mecha"])
	var M: Dictionary = Data.mecha_meta
	var m: Dictionary = M["mechas"][mid]
	if not m.has("juntas"):
		return
	var px := mecha_px()
	var cx: Array = M["caixa"]
	var box := Rect2(float(cx[0]), float(cx[1]), float(cx[2]), float(cx[3]))
	var J: Dictionary = m["juntas"]
	var st: Dictionary = MECHA_ESTILO.get(mid, MECHA_ESTILO["T01"])
	var tipo := String(st["tipo"])
	var a := clampf(float(fx.get("assemble", 1.0)), 0.0, 1.0)
	var tt := lerpf(0.3, 1.2, a)
	var mv: Dictionary = pose.get("mv", {})
	var now := float(mv.get("t", Time.get_ticks_msec() / 1000.0))
	var dist := float(mv.get("dist", 0.0))
	var run := clampf(float(mv.get("run", 0.0)), 0.0, 1.0)
	var air := clampf(float(mv.get("air", 0.0)), 0.0, 1.0)
	var vyy := float(mv.get("vy", 0.0))
	var flip := float(mv.get("flip", -1.0))
	var dge := float(mv.get("dodge", 0.0))
	var land := clampf(float(mv.get("land", 0.0)) / 0.28, 0.0, 1.0)
	var hurt := clampf(float(mv.get("hurt", 0.0)) / 0.24, 0.0, 1.0)
	var ground := 1.0 - air
	var w := clampf(run * 1.4, 0.0, 1.0) * ground
	var g := _golpe(st, fx)
	if a < 0.32:   # ATIVAÇÃO: o robô crava o cartucho no peito (clarão) e as peças explodem para fora
		var ua := a / 0.32
		var lk2 := lk.duplicate()
		lk2["fx"] = {}
		draw_robot(ci, lk2, pose, base)
		var mp := Vector2(-16, -36).lerp(Vector2(-2, -92), _smooth(ua * 2.0)).lerp(Vector2(2, -46), _smooth(ua * 2.0 - 1.0))
		_draw_mochila(ci, base, mid, mp, 1.0 + 0.4 * ua, lerpf(-0.12, TAU, _smooth(ua)))
		if ua > 0.55:
			var f2 := (ua - 0.55) / 0.45
			ci.draw_set_transform_matrix(base)
			ci.draw_circle(Vector2(2, -50), 20.0 + 90.0 * f2, Color(1, 1, 1, 0.85 * (1.0 - f2 * 0.6)))
			ci.draw_arc(Vector2(2, -50), 30.0 + 140.0 * f2, 0, TAU, 32, Color(1, 0.9, 0.5, 1.0 - f2), 8.0, true)
	var U := base * Transform2D(0.0, Vector2(px, px), 0.0, Vector2.ZERO)
	var blink := Color(1.6, 1.5, 1.4) if float(fx.get("armor_end", 0.0)) > 0.0 and fmod(now, 0.16) < 0.08 else Color.WHITE
	# ---------------- juntas do desenho (repouso)
	var hip0 := _jv(J["quadril"])
	var lb: Dictionary = J["perna_b"]
	var lf: Dictionary = J["perna_f"]
	var ab_: Dictionary = J["braco_b"]
	var sh0 := _jv(m["ombro"])
	var head0 := _jv(J.get("cabeca", [10, -130]))
	# ---------------- corpo (pelve/tronco): respiração, passada, ar, pouso, golpe, dash, dano
	var ph := dist / float(st["ciclo"])   # ciclos andados
	var bx := 0.0
	var by := 0.0
	var br := 0.0
	var cr := 0.0
	by += sin(now * float(st["resp"]) * 2.0) * 1.2 * (1.0 - w) * ground + float(st["agacha"]) * ground
	# passada: afunda ao pisar, sobe no "voo" da corrida, inclina e ginga
	var u0 := fposmod(ph, 1.0)
	var pulse := 0.0
	for off in [0.0, 0.5]:
		var uu := fposmod(ph + off, 1.0)
		if uu < 0.22:
			pulse = maxf(pulse, 1.0 - uu / 0.22)
	by += (float(st["queda"]) * pulse - float(st["quica"]) * absf(sin(TAU * u0)) * (1.0 - pulse)) * w
	br += deg_to_rad(float(st["incl"])) * w + deg_to_rad(float(st["ginga"])) * sin(TAU * u0) * w
	cr += deg_to_rad(float(st["cab"])) * sin(TAU * u0 * 2.0 - 1.2) * w
	if tipo == "voo" and ground > 0.5:   # Jato paira: não pisa
		by += -6.0 + sin(now * 4.0) * 2.0
		br = deg_to_rad(float(st["incl"])) * run
	if air > 0.05:
		br += deg_to_rad(clampf(vyy / 45.0, -12.0, 14.0)) * air
	by += 9.0 * land
	br += deg_to_rad(5.0) * land
	if hurt > 0.0:
		br -= deg_to_rad(14.0) * hurt
		cr -= deg_to_rad(14.0) * hurt
		bx -= 6.0 * hurt
	if not g.is_empty():
		bx += g["bx"]
		by += g["by"]
		br += deg_to_rad(g["br"])
		cr += deg_to_rad(g["cr"])
	# pulo duplo (flip 0..1) e dash (dge 1..0): cada tipo do seu jeito
	var spin := 0.0
	var sq := Vector2.ONE
	var tuck := sin(clampf(flip, 0.0, 1.0) * PI) if flip >= 0.0 else 0.0
	if flip >= 0.0:
		match tipo:
			"corredor", "velocista":
				spin = -TAU * _smooth(flip)
			"corcunda":
				spin = TAU * _smooth(flip)
			"mecanico":
				sq = Vector2(1.0 - 0.1 * tuck, 1.0 + 0.18 * tuck)
			"voo":
				sq = Vector2(0.9, 1.15).lerp(Vector2.ONE, flip)
			_:
				sq = Vector2(1.0 + 0.14 * tuck, 1.0 - 0.18 * tuck)
	if dge > 0.0:
		var dl := {"pesado": 26.0, "mecanico": 14.0, "gorila": 34.0, "corredor": 22.0, "velocista": 26.0, "corcunda": 18.0, "voo": 40.0}
		br += deg_to_rad(float(dl.get(tipo, 20.0))) * _smooth(dge * 1.4)
		by += (6.0 if tipo == "gorila" else 2.0) * dge
	# habilidade em uso: postura firme (fogo, raio) ou disparada (dash da broca)
	var fire_k := float(fx.get("flame", 0.0))
	if fire_k > 0.05 or fx.get("arc", false):
		by += 4.0
		br -= deg_to_rad(6.0)
		bx += sin(now * 70.0) * 1.2
	var drill_dash: bool = fx.get("drill_dash", false)
	if drill_dash:
		br += deg_to_rad(22.0)
		by += 3.0
	if fx.get("arrancada", false):   # A36: ARRANCADA, deitado para a frente como velocista na largada
		br += deg_to_rad(16.0)
		by += 4.0 + sin(now * 40.0) * 1.5
	var cen := Vector2(0.0, -60.0)
	var G := Transform2D.IDENTITY
	if spin != 0.0 or sq != Vector2.ONE:
		G = Transform2D(spin, cen) * Transform2D(0.0, sq, 0.0, Vector2.ZERO) * Transform2D(0.0, -cen)
	U = U * G
	var B := Transform2D(0.0, hip0 + Vector2(bx, by)) * Transform2D(br, Vector2.ZERO) * Transform2D(0.0, -hip0)
	# ---------------- pernas: alvo do tornozelo (passada plantada, ar, pulo duplo, dash, golpe)
	var feet := {}
	for side in ["b", "f"]:
		var L: Dictionary = lb if side == "b" else lf
		var h0 := _jv(L["quadril"])
		var k0 := _jv(L["joelho"])
		var a0 := _jv(L["tornozelo"])
		var l1 := h0.distance_to(k0)
		var l2 := k0.distance_to(a0)
		var hipw: Vector2 = B * h0
		var reach := l1 + l2
		var off := 0.0 if side == "f" else 0.5
		var uu := fposmod(ph + off, 1.0)
		# passo: tamanho limitado pelo alcance da perna; o pé anda para trás exatamente com o chão no apoio
		var hh := absf(a0.y - h0.y)
		var max_s := 2.0 * sqrt(maxf(reach * reach * 0.94 - hh * hh * 0.7, 1.0))
		var S := minf(float(st["duty"]) * float(st["ciclo"]) / px, max_s)
		var de := S * px / float(st["ciclo"])
		var fxo := 0.0
		var fyo := 0.0
		var frot := 0.0
		if uu < de:
			fxo = S * 0.5 - (uu / de) * S
			if uu > de * 0.8:
				frot = -0.25 * (uu / de - 0.8) / 0.2   # empurra com o calcanhar subindo
		else:
			var s := (uu - de) / (1.0 - de)
			fxo = -S * 0.5 + _smooth(s) * S
			fyo = -float(st["passo_h"]) * sin(PI * s)
			frot = 0.35 * sin(PI * s) * (1.0 if s > 0.5 else -0.6)
		fxo *= w
		fyo *= w
		frot *= w
		if tipo == "voo" and ground > 0.5:   # pernas soltas, balançando como pêndulo
			fxo = -6.0 * run + sin(now * 3.0 + off * 3.0) * 2.0
			fyo = -4.0
			frot = 0.2
		var tgt := a0 + Vector2(fxo + (bx * 0.3 if side == "f" else 0.0), fyo)
		if air > 0.05:   # no ar: sobe estendido, encolhe no alto, abre para pousar
			var t_up := clampf(-vyy / 600.0, 0.0, 1.0)
			var t_dn := clampf(vyy / 600.0, 0.0, 1.0)
			var apex := 1.0 - maxf(t_up, t_dn)
			var sgn_s := 1.0 if side == "f" else -1.0
			var air_t := Vector2(-6.0 * t_up + 6.0 * t_dn + 5.0 * sgn_s, -16.0 * apex - 2.0 * t_up)
			tgt = tgt.lerp((B * h0) + (a0 - h0) + air_t + Vector2(0, -float(st["agacha"])), air)
			frot = lerpf(frot, 0.3 * apex - 0.25 * t_up, air)
		if tuck > 0.0:
			tgt += Vector2(4.0 if side == "f" else -2.0, -18.0 * tuck)
		if dge > 0.0:
			var dd := _smooth(dge * 1.4)
			tgt += Vector2((14.0 if side == "f" else -22.0) * dd, (-6.0 if side == "f" else 0.0) * dd)
		if not g.is_empty():
			if side == "f":
				tgt += Vector2(g["ffx"], g["ffy"])
			else:
				tgt += Vector2(g["fbx"], 0.0)
		if fire_k > 0.05 or fx.get("arc", false) or drill_dash:   # firma as pernas (base larga)
			tgt.x += (10.0 if side == "f" else -10.0)
		var sol := _ik2(hipw, tgt, l1, l2, _dobra(h0, k0, a0))
		feet[side] = [h0, k0, a0, hipw, sol[0], sol[1], frot]
	# ---------------- braço de trás: balança com a passada (ou anda apoiado nos nós dos dedos: gorila)
	var s0 := _jv(ab_["ombro"])
	var e0 := _jv(ab_["cotovelo"])
	var hnd0 := _jv(ab_["mao"])
	var la1 := s0.distance_to(e0)
	var la2 := e0.distance_to(hnd0)
	var sw: Vector2 = B * s0
	var htgt: Vector2 = B * hnd0
	if tipo == "gorila":
		var ua := fposmod(ph + 0.25, 1.0)
		var Sa := 26.0
		if ua < 0.55:
			htgt = hnd0 + Vector2((Sa * 0.5 - ua / 0.55 * Sa) * w, 0.0)
		else:
			var sa := (ua - 0.55) / 0.45
			htgt = hnd0 + Vector2((-Sa * 0.5 + _smooth(sa) * Sa) * w, -12.0 * sin(PI * sa) * w)
		htgt += Vector2(bx, by * 0.5)
	else:
		htgt += Vector2(-float(st["braco"]) * sin(TAU * u0) * w, 0.0)
	if air > 0.05:
		htgt += Vector2(-6.0, -10.0 * clampf(-vyy / 600.0, 0.0, 1.0) - 4.0) * air
	if tuck > 0.0:
		htgt += (Vector2(10.0, -70.0) if tipo == "gorila" else Vector2(-8.0, -10.0)) * tuck
	if dge > 0.0:
		htgt += (Vector2(40.0, 6.0) if tipo == "gorila" else Vector2(10.0, -14.0)) * _smooth(dge * 1.4)
	if hurt > 0.0:
		htgt += Vector2(-10.0, -18.0) * hurt
	if not g.is_empty():
		htgt += Vector2(g["hbx"], g["hby"])
	var arm := _ik2(sw, htgt, la1, la2, _dobra(s0, e0, hnd0))
	# braço-arma: mira + balanço + golpe + recuo da habilidade
	var aim := float(fx.get("aim_a", 0.0)) if mid in MECHA_MIRA else 0.0
	var a_rot := aim + deg_to_rad(4.0) * sin(TAU * u0 + PI) * w
	var a_dx := 0.0
	if not g.is_empty():
		a_rot += deg_to_rad(g["ar"])
		a_dx += g["ax"]
	if fire_k > 0.05:
		a_dx -= 3.0 + sin(now * 60.0) * 1.5
	if dge > 0.0 and tipo in ["mecanico", "corredor", "velocista"]:
		a_rot = lerpf(a_rot, 0.0, dge)
		a_dx += 12.0 * dge
	# ---------------- fundo: raios da montagem, rastro do dash, propulsores
	ci.draw_set_transform_matrix(U)
	if a < 1.0:
		var ck: Array = m["cockpit"]
		var c := Vector2(float(ck[0]), float(ck[1]) - 20.0)
		var op := 0.55 * sin(a * PI)
		for k in 12:
			var ang := deg_to_rad(now * 90.0 + k * 30.0)
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(ang) * 240.0, c + Vector2.from_angle(ang + 0.18) * 240.0]), Color(1, 0.95, 0.7, op * 0.5))
		ci.draw_circle(c, 80.0 + 60.0 * a, Color(1, 0.97, 0.85, op))
	if dge > 0.05:
		var dcol := Color(0.55, 0.85, 1.0) if tipo in ["corcunda", "voo"] else (Color(1.0, 0.7, 0.35) if tipo == "pesado" else Color(0.85, 0.92, 1.0))
		for k in 3:
			ci.draw_rect(Rect2(-70.0 - k * 36.0, -150.0 + k * 8.0, 74.0, 150.0 - k * 14.0), Color(dcol, 0.2 * dge * (1.0 - k * 0.3)))
		for k in 7:
			var yy := -150.0 + k * 22.0
			var x0 := -60.0 - fmod(k * 37.0 + now * 900.0, 70.0)
			ci.draw_line(Vector2(x0, yy), Vector2(x0 - 50.0 - k * 6.0, yy), Color(1, 1, 1, 0.75 * dge), 4.0, true)
		if tipo == "corcunda":
			for k in 3:
				var y2 := -40.0 - k * 36.0
				ci.draw_polyline(PackedVector2Array([Vector2(-150, y2), Vector2(-110, y2 - 8), Vector2(-80, y2 + 6), Vector2(-40, y2 - 4)]), Color(0.8, 0.97, 1.0, 0.9 * dge), 3.0, true)
	var jet := 0.0
	if flip >= 0.0:
		jet = 1.0 - clampf(flip, 0.0, 1.0)
	if tipo == "voo":
		jet = maxf(jet, 0.35 + 0.55 * maxf(run, air))
	if jet > 0.02:
		var fl := 0.8 + 0.2 * sin(now * 50.0)
		for side in ["b", "f"]:
			var an: Vector2 = feet[side][5]
			var L2 := (60.0 if tipo != "voo" else 46.0) * jet * fl
			ci.draw_colored_polygon(PackedVector2Array([an + Vector2(-11, 10), an + Vector2(11, 10), an + Vector2(0, 10 + L2)]), Color(1.0, 0.58, 0.18, 0.92))
			ci.draw_colored_polygon(PackedVector2Array([an + Vector2(-5, 10), an + Vector2(5, 10), an + Vector2(0, 10 + L2 * 0.55)]), Color(1.0, 0.97, 0.75, 0.95))
	if tipo == "corcunda" and flip >= 0.0:   # anel elétrico do giro
		ci.draw_arc(cen, 70.0 + 30.0 * tuck, 0, TAU, 32, Color(0.7, 0.95, 1.0, 0.8 * tuck), 4.0, true)
	# ---------------- peças
	var parts_xf := {}
	for side in ["b", "f"]:
		var F: Array = feet[side]
		parts_xf["coxa_" + side] = _osso(F[0], F[1], F[3], F[4])
		parts_xf["canela_" + side] = _osso(F[1], F[2], F[4], F[5])
		parts_xf["pe_" + side] = Transform2D(0.0, F[5]) * Transform2D(float(F[6]), Vector2.ZERO) * Transform2D(0.0, -F[2])
	parts_xf["braco_b_sup"] = _osso(s0, e0, sw, arm[0])
	parts_xf["braco_b_inf"] = _osso(e0, hnd0, arm[0], arm[1])
	for p in ["costas", "tronco", "cabine", "peito", "ombro_b", "ombro_f"]:
		parts_xf[p] = B
	parts_xf["cabeca"] = B * Transform2D(cr, head0) * Transform2D(0.0, -head0)
	parts_xf["arma"] = B * Transform2D(0.0, Vector2(a_dx, 0.0)) * Transform2D(a_rot, sh0) * Transform2D(0.0, -sh0)
	var mod := blink
	if dge > 0.0 and tipo == "corcunda":   # piscada elétrica: fica meio transparente e azulado
		mod = Color(0.75, 0.95, 1.2, 1.0 - 0.45 * sin(dge * PI))
	for p in M["pecas"]:
		if not (p in m["tem"]) or not parts_xf.has(p):
			continue
		var tx: Texture2D = Data.tex("mecha/%s_%s%s" % [mid, p, ("_p%d" % (col_idx + 1)) if p == "tronco" else ""])
		if tx == null:
			continue
		var xf: Transform2D = parts_xf[p]
		var grp := String(MECHA_GRUPO.get(p, p))
		var al := 1.0
		if MECHA_CHEGADA.has(grp):   # transformação: o grupo chega voando e encaixa
			var ch: Array = MECHA_CHEGADA[grp]
			var u := clampf((tt - float(ch[0])) / (float(ch[1]) - float(ch[0])), 0.0, 1.0)
			if u <= 0.0:
				continue
			var k := 1.0 - _ease_back(u)
			var piv := _jv(m["pivos"].get(p, [0, -60]))
			xf = Transform2D(0.0, Vector2(float(ch[2]), float(ch[3])) * k) * Transform2D(deg_to_rad(float(ch[4])) * k, piv) * Transform2D(0.0, -piv) * xf
			al = clampf(u * 4.0, 0.0, 1.0)
		ci.draw_set_transform_matrix(U * xf)
		ci.draw_texture_rect(tx, box, false, Color(mod, mod.a * al))
		if p == "cabine" and al >= 0.99:
			_mecha_piloto(ci, U * B, m, mname, col_idx, lk, pose)
	# ---------------- frente: poeira dos passos, vapor, faíscas, olho acendendo
	ci.draw_set_transform_matrix(U)
	if w > 0.3 and tipo != "voo":
		for side in ["b", "f"]:
			var uu2 := fposmod(ph + (0.0 if side == "f" else 0.5), 1.0)
			if uu2 < 0.16:
				var k2 := 1.0 - uu2 / 0.16
				var an2: Vector2 = feet[side][5]
				for q in 3:
					ci.draw_circle(an2 + Vector2(-16.0 + q * 16.0 - (1.0 - k2) * 10.0, 6.0 - (1.0 - k2) * 6.0), (5.0 + q * 2.0) * (1.4 if tipo in ["pesado", "gorila"] else 0.9) * (0.5 + k2), Color(0.86, 0.79, 0.67, 0.6 * k2))
	if tipo == "pesado":   # vapor saindo da chaminé, mais forte correndo
		for q in 3:
			var uq := fposmod(now * (0.8 + w) + q * 0.33, 1.0)
			var cs: Vector2 = B * Vector2(-44.0, -150.0)
			ci.draw_circle(cs + Vector2(-14.0 * uq - 20.0 * w * uq, -40.0 * uq), 5.0 + 12.0 * uq, Color(0.55, 0.55, 0.58, 0.45 * (1.0 - uq)))
	if tipo == "corcunda" and fmod(now, 0.5) < 0.12:   # faísca solta da bobina
		var cs2: Vector2 = B * Vector2(-50.0, -186.0)
		ci.draw_polyline(PackedVector2Array([cs2, cs2 + Vector2(10, -8), cs2 + Vector2(4, -16), cs2 + Vector2(14, -24)]), Color(0.85, 0.98, 1.0, 0.9), 2.0, true)
	if tipo == "mecanico" and w > 0.3:   # chiado hidráulico nos joelhos
		var kn: Vector2 = feet["f"][4]
		var uq2 := fposmod(now * 3.0, 1.0)
		ci.draw_circle(kn + Vector2(-8.0 - 10.0 * uq2, -4.0 * uq2), 3.0 + 4.0 * uq2, Color(1, 1, 1, 0.5 * (1.0 - uq2)))
	if a < 1.0 and a > 0.85:
		var ol: Array = m["olho"]
		var e := (a - 0.85) / 0.15
		ci.draw_circle(B * Vector2(float(ol[0]), float(ol[1])), 6.0 + 26.0 * e, Color(1, 0.25, 0.2, 0.55 * (1.0 - e)))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)

static func _mecha_piloto(ci: CanvasItem, U: Transform2D, m: Dictionary, mname: String, col_idx: int, lk: Dictionary, pose: Dictionary) -> void:
	var ck: Array = m["cockpit"]
	var w := float(ck[2])
	var h := float(ck[3])
	var dst := Rect2(float(ck[0]) - w / 2.0, float(ck[1]) - h / 2.0, w, h)
	var g: Dictionary = Data.robot_meta["modelos"][mname]
	var eye: Vector2 = (_v(g["eyes"][0]) + _v(g["eyes"][1])) / 2.0 + ORIGIN
	var top := float(g["top"])
	var hh := maxf(eye.y + 14.0 - top, 24.0)
	var src128 := Rect2(eye.x - hh * 0.62, top - 2.0, hh * 1.24, hh * 0.98)
	ci.draw_set_transform_matrix(U)
	var sk := _sk(lk, mname)
	var body := Data.tex("robo/corpo_%s%s_p%d" % [mname, sk, col_idx + 1])
	var kq := float(body.get_width()) / 128.0
	ci.draw_texture_rect_region(body, dst, Rect2(src128.position * kq, src128.size * kq))
	var ex := String(pose.get("expr", "normal"))
	var face := Data.tex("robo/rosto_%s_%s" % [mname, ex])
	if face == null:
		face = Data.tex("robo/rosto_%s_normal" % mname)
	if face != null:
		var kf := float(face.get_width()) / 128.0
		ci.draw_texture_rect_region(face, dst, Rect2(src128.position * kf, src128.size * kf))
	ci.draw_rect(Rect2(dst.position + Vector2(3, 3), Vector2(w * 0.4, 2.5)), Color(1, 1, 1, 0.6))   # brilho do vidro

static func _armor_piece(ci: CanvasItem, xf: Transform2D, name: String, asm: float, at: Vector2, sf: Dictionary, sx := 1.0) -> void:
	var drop := Vector2(0, -(1.0 - asm) * 30.0)
	var mod := Color(1, 1, 1, asm)
	if float(sf.get("armor_end", 0.0)) > 0.0 and fmod(Time.get_ticks_msec() / 1000.0, 0.16) < 0.08:
		mod = Color(1.6, 1.4, 1.2, asm)
	ci.draw_set_transform_matrix(xf)
	ci.draw_texture_rect(Data.tex("spells/" + name), Rect2(at - Vector2(36.0 * sx, 24) + drop, Vector2(72.0 * sx, 62.4)), false, mod)

## Sufixo das texturas da skin ("_k1") se ela existir para este robô; senão "" (padrão).
static func _sk(lk: Dictionary, mname: String) -> String:
	var k := String(lk.get("skin", ""))
	if k == "" or Data.tex("robo/corpo_%s_%s_p1" % [mname, k]) == null:
		return ""
	return "_" + k

static func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1])) - ORIGIN

## Membro grosso de "macarrão" com risco de giz.
static func _limb(ci: CanvasItem, base: Transform2D, a: Vector2, b: Vector2, col: Color, bend: Vector2, w := 3.4) -> void:
	var m := (a + b) / 2.0 + bend
	var pts := PackedVector2Array()
	for i in 7:
		var k := i / 6.0
		pts.append(a.lerp(m, k).lerp(m.lerp(b, k), k))
	ci.draw_set_transform_matrix(base)
	ci.draw_polyline(pts, col, w, true)
	var streak := PackedVector2Array()
	for p in pts:
		streak.append(p + Vector2(-0.6, 0))
	ci.draw_polyline(streak, col.lightened(0.15), w * 0.18, true)

## Partes soltas para o robô "desmontar" na eliminação: [{tex, rect (local), modulate}].
static func parts(lk: Dictionary) -> Array:
	var mname: String = Data.MODELS[posmod(int(lk["model"]), Data.MODELS.size())]
	var g: Dictionary = Data.robot_meta["modelos"][mname]
	var limb := Color(Data.robot_meta["membros"][lk["color"]])
	var out := []
	var sk := _sk(lk, mname)
	out.append({"tex": [Data.tex("robo/corpo_%s%s_p%d" % [mname, sk, lk["color"] + 1]), Data.tex("robo/rosto_%s_eliminado" % mname)],
		"rect": Rect2(-ORIGIN, Vector2(128, 128)), "mod": Color.WHITE})
	out.append({"tex": [Data.tex("robo/antena_" + mname)], "rect": Rect2(-ORIGIN, Vector2(128, 128)), "mod": Color.WHITE})
	if lk.get("hammer", true):
		var tsz2 := Vector2(float(g["tool"][0]), float(g["tool"][1]))
		out.append({"tex": [Data.tex("robo/ferramenta_" + mname + sk)], "rect": Rect2(_v(g["hand_front"]) - Vector2(float(g["tool_grip"][0]), float(g["tool_grip"][1])), tsz2), "mod": Color.WHITE})
	var hs := 16.0 * float(g["hand_s"])
	for hp in [g["hand_back"], g["hand_front"]]:
		out.append({"tex": [Data.tex("robo/mao")], "rect": Rect2(_v(hp) - Vector2(hs, hs) / 2.0, Vector2(hs, hs)), "mod": Color.WHITE})
	for hip in g["hips"]:
		out.append({"tex": [Data.tex("robo/pe")], "rect": Rect2(Vector2(_v(hip).x - 9, -9), Vector2(17, 10)), "mod": limb})
	return out
