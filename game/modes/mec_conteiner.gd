extends RefCounted
## M1 CONTÊINER DESPENCA (Fase 2 · Alto-Mar) — animação PROCEDURAL (manual docs/manuais/animacao.md, 5 batidas).
##   aviso  (aviso_s)  a carga do TOPO da pilha do navio lá no fundo treme cada vez mais forte; as cintas estalam
##                     (faíscas + pedaços de cinta) e ela inclina e escorrega para fora (alvo zebrado cresce no chão)
##   salta  (salta_s)  ela se solta da pilha: sai em arco para a frente e para cima (cresce do fundo para o palco,
##                     girando) e passa do alto da tela, já em cima do alvo
##   cai               cai reto no alvo ACELERANDO (gravidade), estica na velocidade e endireita para bater chapado
##   impacto           achata ~14%, congela 0,06 s, tremor, poeira dos dois lados, lascas; quem está embaixo é atingido
##                     (mecanismos.gd aplica a regra) e quem está do lado é arremessado pela pancada
##   assenta           quica (continuação) com um segundo achatamento menor e fica como plataforma; no mar: espirra e afunda
## Desenho em camadas de papel: sombra + corpo (arte cont_N) + faixa clara, sem contorno.

const T := 64.0
const CINTA := Color("#e6b23a")
const CINTA_D := Color("#a87a1e")
const POEIRA := Color("#d9c8ad")
const LASCAS := [Color("#7a5a3c"), Color("#9a7450"), Color("#6d7d91"), Color("#4b5869")]
const GOTA := Color("#cfe9f4")

var mc
var main
var d: Dictionary
var fase := ""          # aviso, salta, cai, assenta ("" = parado/sem animação)
var k := 0.0            # tempo na fase
var alvo := Rect2()
var mar := false
var cor := 0
var pilha_img := Vector2.ZERO   # topo do contêiner solto na fotografia e1_longe (coordenadas do PNG)
var tam0 := Vector2(159, 44)    # tamanho na pilha (fundo)
var pos := Vector2.ZERO          # centro do contêiner no mundo
var rot := 0.0
var sx := 1.0
var sy := 1.0
var esc := 0.0                   # 0 = no fundo (tamanho/cor da pilha) → 1 = no palco
var vy := 0.0
var y_alto := 0.0
var x_ini := 0.0
var y_ini := 0.0
var rot_ini := 0.0
var cintas_ok := true
var congela := 0.0
var espirrou := false
var quicou := false
var bits: Array = []             # partículas {p, v, t, life, k, r, c, a, va}

func setup(m, dd: Dictionary) -> void:
	mc = m
	main = m.main
	d = dd

func ativa() -> bool:
	return fase != "" or not bits.is_empty()

## Ponto da fotografia de fundo (PNG 1920×1080 de e1_longe) → mundo, com a mesma escala/paralaxe de cena_cargueiro._foto.
func _foto_pt(p: Vector2) -> Vector2:
	var a: Rect2 = main.level.etapa_rect(int(d.get("etapa", 1)))
	var g := float(d.get("foto_grow", 0.03))
	var sz := Vector2(a.size.x, a.size.x * 1080.0 / 1920.0)
	var par: Vector2 = (main.cam_center - a.get_center()) * float(d.get("foto_par", 0.06))
	return a.position - sz * g + p * (sz.x * (1.0 + 2.0 * g) / 1920.0) + par

func _escala_foto() -> float:
	var a: Rect2 = main.level.etapa_rect(int(d.get("etapa", 1)))
	return a.size.x * (1.0 + 2.0 * float(d.get("foto_grow", 0.03))) / 1920.0

## Escolhe na pilha do fundo o contêiner do topo mais perto da coluna do alvo.
func comecar(a: Rect2, no_mar: bool, c: int) -> void:
	alvo = a
	mar = no_mar
	cor = c
	var pilhas: Array = d.get("pilha_img", [])
	var melhor := Vector2(960, 150)
	var dist := INF
	for p in pilhas:
		var pi: Array = p
		var topo := Vector2(float(pi[0]), 290.0 - float(pi[1]) * 42.0)
		var w := _foto_pt(topo)
		if absf(w.x - a.get_center().x) < dist:
			dist = absf(w.x - a.get_center().x)
			melhor = topo
	pilha_img = melhor
	tam0 = Vector2(150, 42) * _escala_foto()
	esc = 0.0
	rot = 0.0
	sx = 1.0
	sy = 1.0
	vy = 0.0
	cintas_ok = true
	congela = 0.0
	fase = "aviso"
	k = 0.0
	pos = _foto_pt(pilha_img + Vector2(0, 21))

func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)

func _ease_io(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func tamanho() -> Vector2:
	return tam0.lerp(alvo.size, esc)

## Caixa que bate nos robôs durante a queda (o que se vê é o que acerta).
func caixa() -> Rect2:
	var s := alvo.size
	return Rect2(alvo.position.x, pos.y - s.y / 2.0, s.x, s.y)

## Avança a animação; devolve "solta" (saiu da pilha), "impacto" (bateu no chão/peça), "afundou" ou "".
func update(dt: float) -> String:
	var ev := ""
	_bits(dt)
	if congela > 0.0:   # hitstop do próprio contêiner no impacto
		congela -= dt
		return ""
	k += dt
	match fase:
		"aviso":
			var av := float(d["aviso_s"])
			var u := k / av
			var base := _foto_pt(pilha_img + Vector2(0, 21))
			var amp := 1.0 + 6.0 * u * u
			pos = base + Vector2(sin(k * 38.0) * amp, -absf(sin(k * 19.0)) * amp * 0.6)
			rot = sin(k * 27.0) * 0.02 * (1.0 + 3.0 * u)
			if cintas_ok and u >= 0.6:
				cintas_ok = false
				_estala()
			if not cintas_ok:   # sem as cintas: inclina e escorrega para o lado do alvo
				var lado := signf(alvo.get_center().x - base.x) if absf(alvo.get_center().x - base.x) > 8.0 else 1.0
				var w := _ease_io((u - 0.6) / 0.4)
				pos += Vector2(lado * 14.0 * w, -4.0 * w)
				rot += lado * 0.22 * w
			if k >= av:
				fase = "salta"
				k = 0.0
				x_ini = pos.x
				y_ini = pos.y
				rot_ini = rot
				y_alto = main.view_rect().position.y - alvo.size.y * 1.4
				Audio.play("alarme", 1.4, -8.0)
				Audio.play("gancho", 1.3, -4.0)
				ev = "solta"
		"salta":
			var ss := float(d.get("salta_s", 0.42))
			var u := k / ss
			pos.x = lerpf(x_ini, alvo.get_center().x, _ease_io(u))
			pos.y = lerpf(y_ini, y_alto, _ease_out(u))
			esc = _ease_io(u)
			rot = rot_ini + signf(rot_ini if rot_ini != 0.0 else 1.0) * 2.4 * _ease_out(u)   # tomba para a frente
			if k >= ss:
				fase = "cai"
				k = 0.0
				vy = 0.0
				rot_ini = fmod(rot, TAU)
				if rot_ini > PI:
					rot_ini -= TAU
				elif rot_ini < -PI:
					rot_ini += TAU
				y_ini = pos.y
				esc = 1.0
		"cai":
			vy = minf(vy + 4000.0 * dt, float(d["vel_queda"]))
			var chao_c := alvo.get_center().y if not mar else alvo.get_center().y + 400.0
			pos.x = alvo.get_center().x
			pos.y = minf(pos.y + vy * dt, chao_c)
			var p := clampf((pos.y - y_ini) / maxf(alvo.get_center().y - y_ini, 1.0), 0.0, 1.0)
			rot = rot_ini * pow(1.0 - p, 2.0)            # endireita para bater chapado
			var st := 0.09 * clampf(vy / float(d["vel_queda"]), 0.0, 1.0)
			sy = 1.0 + st
			sx = 1.0 - st * 0.6
			if not mar and pos.y >= alvo.get_center().y:
				_impacto()
				ev = "impacto"
			elif mar and pos.y >= alvo.get_center().y - 30.0 and not espirrou:
				espirrou = true
				_espirro()
			if mar and pos.y >= chao_c:
				espirrou = false
				fase = ""
				ev = "afundou"
		"assenta":
			# achatado → volta (mola amortecida) com um pulinho (continuação) e um segundo achatamento menor
			var q := k
			var hop := 0.0
			if q < 0.12:
				var w := q / 0.12
				sy = lerpf(0.84, 1.06, _ease_out(w))
				sx = lerpf(1.14, 0.97, _ease_out(w))
			elif q < 0.36:
				var w2 := (q - 0.12) / 0.24
				hop = 18.0 * 4.0 * w2 * (1.0 - w2)
				sy = lerpf(1.06, 1.0, w2)
				sx = lerpf(0.97, 1.0, w2)
				rot = 0.05 * sin(w2 * PI)
			elif q < 0.5:
				var w3 := (q - 0.36) / 0.14
				sy = 1.0 - 0.07 * sin(w3 * PI)
				sx = 1.0 + 0.05 * sin(w3 * PI)
				rot = 0.0
				if w3 > 0.0 and not quicou:
					quicou = true
					Audio.play("caixote_pancada", 1.3, -10.0)
					_poeira(Vector2(alvo.get_center().x, alvo.end.y), 6, 0.6)
			else:
				sx = 1.0
				sy = 1.0
				rot = 0.0
				quicou = false
				fase = ""
			pos = alvo.get_center() + Vector2(0, -hop)
	return ev

func _estala() -> void:
	Audio.play("gancho", 0.6, 0.0)
	var t := tamanho()
	for sx0 in [-0.3, 0.3]:
		var p: Vector2 = pos + Vector2(t.x * float(sx0), -t.y * 0.5)
		for n in 6:
			bits.append({"p": p, "v": Vector2(randf_range(-260, 260), randf_range(-380, -120)), "t": 0.0, "life": randf_range(0.18, 0.35),
				"k": "faisca", "r": randf_range(2, 4), "c": Color("#ffe08a"), "a": 0.0, "va": 0.0})
		for n in 2:   # pedaços da cinta voando
			bits.append({"p": p, "v": Vector2(randf_range(-160, 160), randf_range(-320, -160)), "t": 0.0, "life": 0.7,
				"k": "cinta", "r": randf_range(12, 18), "c": CINTA, "a": randf_range(0, TAU), "va": randf_range(-14, 14)})

func _impacto() -> void:
	fase = "assenta"
	k = 0.0
	congela = 0.06
	sx = 1.14
	sy = 0.84
	rot = 0.0
	pos = alvo.get_center()
	main.shake(10.0)
	Audio.play("caixote_pancada", 0.6, 0.0)
	Audio.play("explosao", 2.0, -10.0)
	var chao := Vector2(alvo.get_center().x, alvo.end.y)
	_poeira(chao, 16, 1.0)
	for n in 12:   # lascas da peça em que bateu + chapas
		var lado := -1.0 if n % 2 == 0 else 1.0
		bits.append({"p": chao + Vector2(lado * randf_range(10, alvo.size.x * 0.5), -randf_range(0, 10)),
			"v": Vector2(lado * randf_range(120, 420), randf_range(-520, -200)), "t": 0.0, "life": randf_range(0.5, 0.9),
			"k": "lasca", "r": randf_range(5, 11), "c": LASCAS[n % LASCAS.size()], "a": randf_range(0, TAU), "va": randf_range(-18, 18)})

func _poeira(chao: Vector2, n: int, f: float) -> void:
	for j in n:
		var lado := -1.0 if j % 2 == 0 else 1.0
		bits.append({"p": chao + Vector2(lado * (alvo.size.x * 0.45 + randf_range(-10, 10)), -randf_range(2, 14)),
			"v": Vector2(lado * randf_range(140, 380) * f, -randf_range(10, 90) * f), "t": 0.0, "life": randf_range(0.45, 0.8),
			"k": "poeira", "r": randf_range(10, 22) * (0.6 + 0.4 * f), "c": POEIRA, "a": 0.0, "va": 0.0})

func _espirro() -> void:
	Audio.play("agua", 0.8, 0.0)
	main.shake(5.0)
	var p := Vector2(alvo.get_center().x, alvo.get_center().y)
	for n in 28:
		bits.append({"p": p + Vector2(randf_range(-alvo.size.x * 0.5, alvo.size.x * 0.5), 0), "v": Vector2(randf_range(-320, 320), randf_range(-760, -260)),
			"t": 0.0, "life": randf_range(0.5, 0.9), "k": "gota", "r": randf_range(4, 9), "c": GOTA, "a": 0.0, "va": 0.0})

func _bits(dt: float) -> void:
	var vivos: Array = []
	for b in bits:
		b["t"] = float(b["t"]) + dt
		if float(b["t"]) >= float(b["life"]):
			continue
		var v: Vector2 = b["v"]
		match String(b["k"]):
			"poeira":
				v *= pow(0.04, dt)
				v.y -= 30.0 * dt
			_:
				v.y += 1500.0 * dt
		b["v"] = v
		b["p"] = (b["p"] as Vector2) + v * dt
		b["a"] = float(b["a"]) + float(b["va"]) * dt
		vivos.append(b)
	bits = vivos.slice(0, 150)

# ------------------------------------------------------------------ desenho
func draw(ci: CanvasItem, tex_cont: Texture2D) -> void:
	if fase != "":
		var t := tamanho()
		var escuro := lerpf(0.8, 1.0, esc)   # no fundo ele tem o tom apagado da pilha
		var cmod := Color(escuro, escuro * 0.97, escuro * 0.95)
		if fase in ["cai", "assenta"] and not mar:   # sombra no chão que aperta conforme chega
			var dist := clampf((alvo.get_center().y - pos.y) / 600.0, 0.0, 1.0)
			var sw := alvo.size.x * (1.0 - 0.4 * dist)
			ci.draw_set_transform(Vector2(alvo.get_center().x, alvo.end.y - 3.0), 0.0, Vector2(1.0, 0.22))
			ci.draw_circle(Vector2.ZERO, sw * 0.55, Color(0.1, 0.06, 0.05, 0.35 * (1.0 - dist * 0.6)))
		var ancora := pos
		var pv := Vector2(0, t.y * 0.5) if fase == "assenta" else Vector2.ZERO   # achata a partir da base
		ci.draw_set_transform(ancora + pv, rot, Vector2(sx, sy))
		var r := Rect2(-t * 0.5 - pv, t)
		ci.draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0.12, 0.06, 0.05, 0.25))   # sombra de papel
		if tex_cont != null:
			ci.draw_texture_rect(tex_cont, r, false, cmod)
		else:
			ci.draw_rect(r, Color("#c8413a") * cmod)
		ci.draw_rect(Rect2(r.position + Vector2(6, 4), Vector2(r.size.x - 12, 5)), Color(1, 1, 1, 0.18))   # faixa clara
		if fase == "aviso" and cintas_ok:
			for sx0 in [-0.3, 0.3]:
				var x: float = r.position.x + r.size.x * (0.5 + float(sx0))
				ci.draw_rect(Rect2(x - 3, r.position.y - 2, 6, r.size.y + 14), CINTA_D)
				ci.draw_rect(Rect2(x - 2, r.position.y - 2, 3, r.size.y + 14), CINTA)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for b in bits:
		var p: Vector2 = b["p"]
		var u := float(b["t"]) / float(b["life"])
		var c: Color = b["c"]
		match String(b["k"]):
			"poeira":
				var rr := float(b["r"]) * (1.0 + 1.2 * u)
				ci.draw_circle(p, rr, Color(c.r, c.g, c.b, 0.55 * (1.0 - u)))
				ci.draw_circle(p + Vector2(-rr * 0.25, -rr * 0.25), rr * 0.55, Color(1, 1, 1, 0.18 * (1.0 - u)))
			"faisca":
				var v: Vector2 = b["v"]
				ci.draw_line(p, p - v * 0.03, Color(c.r, c.g, c.b, 1.0 - u), float(b["r"]), true)
			"gota":
				var v2: Vector2 = b["v"]
				var dir := v2.normalized()
				var st := clampf(v2.length() / 900.0, 0.0, 1.0)
				ci.draw_set_transform(p, dir.angle(), Vector2(1.0 + st, 1.0 - 0.3 * st))
				ci.draw_circle(Vector2.ZERO, float(b["r"]), Color(c.r, c.g, c.b, 0.9 * (1.0 - u * u)))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:   # lasca / cinta: retângulo girando
				var rr2 := float(b["r"])
				var sz := Vector2(rr2, rr2 * (0.45 if b["k"] == "lasca" else 0.3))
				ci.draw_set_transform(p, float(b["a"]), Vector2.ONE)
				ci.draw_rect(Rect2(-sz * 0.5, sz), Color(c.r, c.g, c.b, 1.0 - u * u))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
