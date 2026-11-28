extends RefCounted
## M3 ONDA (Fase 2 · Alto-Mar) — animação PROCEDURAL (manual docs/manuais/animacao.md).
## A onda é o próprio MAR: nasce da linha d'água na borda de fora da balsa e nunca se descola dela.
##   aviso  (aviso_s)  o mar incha na borda, sobe até o convés, cospe espuma e respingos (antecipação legível)
##   quebra (quebra_s) a parede dispara para o alto, a crista ENCURVA para dentro e o lábio BATE no convés
##                     → estouro: leque de gotas, névoa, tremor; quem está na zona é arremessado para dentro
##   varre  (onda_s)   a lâmina d'água corre pelo convés por cima dos contêineres (cabeça de espuma na frente),
##                     arrasta quem toca; a parede afunda de volta no mar
##   escoa  (escoa_s)  a lâmina afina e cai pelas duas bordas (cascatas até o mar); o convés fica molhado e pinga
## Desenho: recorte de papel em camadas (fundo, corpo, faixa clara, espuma) — sem contorno, bordas tremidas.
## Desempenho: 1 contorno de ~70 pontos + 1 lâmina de ~30 colunas + ≤140 partículas; o piso é lido UMA vez no aviso.

const T := 64.0
const DU := 16.0
const C_FUNDO := Color("#2f587f")
const C_CORPO := Color("#46759f")
const C_MEIO := Color("#5b8dbb")
const C_CLARO := Color("#8fc0dc")
const C_ESPUMA := Color("#eef5f1")
const C_NEVOA := Color(0.93, 0.97, 0.98, 0.45)

var mc                      # mecanismos.gd (helpers: _chao_em, _robots, main)
var main
var d: Dictionary
var qual := 0
var lado := 1.0             # +1: mar à DIREITA (a onda entra para a esquerda)
var E := 0.0                # x da borda de fora da balsa
var B := 0.0                # largura da balsa
var ys := 0.0               # linha do mar
var yd := 0.0               # convés (topo do casco) na borda de fora
var Ht := 0.0               # altura da crista no pico (acima do mar)
var chao := PackedFloat32Array()   # piso (y) por coluna da lâmina, u = (i + 0,5)·DU
var chao_s := PackedFloat32Array() # piso suavizado (rampa nas quinas) para o topo da lâmina
var fase := ""
var k := 0.0
var hit := {}
var bits: Array = []        # {p, v, t, life, r, k: gota|nevoa|espuma}
var molhado_t := 0.0        # brilho de convés molhado depois que a água vai embora
var t := 0.0

func setup(m, dd: Dictionary) -> void:
	mc = m
	main = m.main
	d = dd

func wx(u: float) -> float:
	return E - lado * u

## Começa uma onda na balsa `q` (lê o piso uma vez).
func comecar(q: int, o: Vector2) -> void:
	qual = q
	var b: Array = d["balsas"][q]
	lado = float(b[3])
	var x0 := o.x + float(b[0]) * T
	var x1 := o.x + float(b[1]) * T
	B = x1 - x0
	E = x1 if lado > 0.0 else x0
	ys = o.y + float(d.get("mar_px", 990.0))
	chao = PackedFloat32Array()
	var n := int(ceil(B / DU))
	var topo := o.y + float(b[2]) * T - float(d["altura_t"]) * T - 96.0
	var alto := ys
	for i in n:
		var x := wx((i + 0.5) * DU)
		var g: float = mc._chao_em(Rect2(x - 2.0, topo, 4.0, 1.0), ys)
		chao.append(g)
		if i < n * 0.6:
			alto = minf(alto, g)
	var col := int(b[1]) - 1 if lado > 0.0 else int(b[0])   # o casco: primeiro TILE sólido na borda (sem os contêineres)
	var row := int(b[2])
	while row < int(b[2]) + 4 and not main.level.is_solid(Vector2i(int(o.x / T) + col, int(o.y / T) + row)):
		row += 1
	yd = o.y + row * T
	# piso "drapeado": a água desce da quina em rampa em vez de ficar em pé (envelope inferior com inclinação ~1)
	chao_s = PackedFloat32Array()
	for i in n:
		var m := chao[i]
		for j in range(maxi(i - 3, 0), mini(i + 4, n)):
			m = minf(m, chao[j] + absf(float(i - j)) * DU * 1.6)
		chao_s.append(m)
	Ht = ys - alto + 70.0        # a crista passa ~1 tile acima do mais alto perto da borda
	fase = "aviso"
	k = 0.0
	hit = {}

func ativa() -> bool:
	return fase != "" or not bits.is_empty() or molhado_t > 0.0

func chao_u(u: float) -> float:
	if chao.is_empty():
		return ys
	if u < 0.0 or u > B:
		return ys
	var i := clampi(int(u / DU), 0, chao.size() - 1)
	return chao[i]

func chao_suave(u: float) -> float:
	if chao_s.is_empty():
		return chao_u(u)
	var f := clampf(u / DU - 0.5, 0.0, chao_s.size() - 1.0)
	var i := int(f)
	return lerpf(chao_s[i], chao_s[mini(i + 1, chao_s.size() - 1)], f - i)

# ------------------------------------------------------------------ forma da parede
## Pontos de controle (u, altura acima do mar) por pose; a animação interpola entre poses com suavização.
func _pose(nome: String) -> Array:
	var D := ys - yd                      # altura do casco (convés acima do mar)
	var hl := ys - chao_u(0.62 * B)       # onde o lábio bate
	match nome:
		"liso":
			return [[-0.3 * B, 0], [-0.1 * B, 3], [0.05 * B, 6], [0.12 * B, 5], [0.1 * B, 3], [0.2 * B, 2], [0.35 * B, 0]]
		"incha":   # o mar estufa NA FRENTE do casco (contra o casco escuro: legível)
			return [[-0.35 * B, 0], [-0.12 * B, 0.35 * D], [0.08 * B, 0.95 * D], [0.17 * B, 0.9 * D], [0.13 * B, 0.7 * D], [0.28 * B, 0.32 * D], [0.46 * B, 0]]
		"suga":    # passa da altura do convés, a crista começa a virar
			return [[-0.36 * B, 0], [-0.12 * B, 0.6 * D], [0.1 * B, D + 46], [0.24 * B, D + 34], [0.17 * B, D + 4], [0.32 * B, 0.5 * D], [0.5 * B, 0]]
		"ergue":   # parede alta, lábio encurvado para dentro
			return [[-0.4 * B, 0], [-0.16 * B, 0.55 * Ht], [0.12 * B, Ht], [0.4 * B, Ht - 34], [0.24 * B, Ht - 86], [0.3 * B, 0.48 * Ht], [0.56 * B, 0]]
		"bate":    # o lábio desaba no convés
			return [[-0.4 * B, 0], [-0.16 * B, 0.45 * Ht], [0.16 * B, 0.84 * Ht], [0.62 * B, hl], [0.44 * B, 0.62 * Ht], [0.42 * B, 0.36 * Ht], [0.62 * B, 0]]
		"afunda":  # a parede volta para o mar
			return [[-0.4 * B, 0], [-0.16 * B, 0.2 * Ht], [0.12 * B, 0.36 * Ht], [0.34 * B, D], [0.26 * B, D - 20], [0.36 * B, 0.4 * D], [0.56 * B, 0]]
		"some":
			return [[-0.3 * B, 0], [-0.1 * B, 3], [0.05 * B, 6], [0.12 * B, 5], [0.1 * B, 3], [0.2 * B, 2], [0.35 * B, 0]]
	return []

static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)

func _mix(pa: Array, pb: Array, w: float) -> Array:
	var out: Array = []
	for i in pa.size():
		out.append(Vector2(lerpf(float(pa[i][0]), float(pb[i][0]), w), lerpf(float(pa[i][1]), float(pb[i][1]), w)))
	return out

## Controle atual (u, h) da parede, ou [] quando não há parede.
func _parede() -> Array:
	match fase:
		"aviso":
			if k < 0.7:
				return _mix(_pose("liso"), _pose("incha"), _ease(k / 0.7))
			return _mix(_pose("incha"), _pose("suga"), _ease((k - 0.7) / 0.3))
		"quebra":
			if k < 0.5:
				return _mix(_pose("suga"), _pose("ergue"), 1.0 - pow(1.0 - k / 0.5, 2.0))   # dispara (sai rápido)
			return _mix(_pose("ergue"), _pose("bate"), pow((k - 0.5) / 0.5, 1.6))       # cai acelerando
		"varre":
			if k < 0.3:
				return _mix(_pose("bate"), _pose("afunda"), _ease(k / 0.3))
			if k < 0.75:
				return _mix(_pose("afunda"), _pose("some"), _ease((k - 0.3) / 0.45))
	return []

## Catmull-Rom (aberta) por pontos de mundo.
static func _spline(p: PackedVector2Array, seg: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := p.size()
	for i in n - 1:
		var p0 := p[maxi(i - 1, 0)]
		var p1 := p[i]
		var p2 := p[i + 1]
		var p3 := p[mini(i + 2, n - 1)]
		for j in seg:
			var s := float(j) / seg
			var s2 := s * s
			var s3 := s2 * s
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s3))
	out.append(p[n - 1])
	return out

func _mundo(c: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in c:
		p.append(Vector2(wx(v.x), ys - v.y))
	return p

# ------------------------------------------------------------------ lâmina no convés
## Frente da lâmina (u) e espessura no ponto u.
func _frente() -> float:
	match fase:
		"varre":
			return lerpf(0.55 * B, B + 70.0, 1.0 - pow(1.0 - k, 2.2))
		"escoa":
			return B + 70.0
	return -1.0

func _espessura(u: float) -> float:
	var f := _frente()
	if f < 0.0 or u > f:
		return 0.0
	var vol := 1.0
	var cauda := 0.0   # a borda de fora seca primeiro (a água volta para o mar)
	if fase == "varre":
		vol = lerpf(1.0, 0.7, k)
		cauda = lerpf(-40.0, 0.25 * B, maxf(k - 0.4, 0.0) / 0.6)
	elif fase == "escoa":
		vol = lerpf(0.7, 0.0, k)
		cauda = lerpf(0.25 * B, B * 0.9, _ease(k))
	var base := 22.0 * vol
	var cabeca_h := (lerpf(84.0, 34.0, k) if fase == "varre" else 30.0 * vol)
	var cabeca := cabeca_h * exp(-pow((u - f + 34.0) / 46.0, 2.0))
	var corpo := base + 30.0 * vol * exp(-pow((u - f + 120.0) / 120.0, 2.0))
	var seca := smoothstep(cauda - 30.0, cauda + 50.0, u)
	return (corpo + cabeca) * seca * smoothstep(f, f - 26.0, u)

# ------------------------------------------------------------------ jogo
func update(dt: float) -> void:
	t += dt
	molhado_t = maxf(molhado_t - dt, 0.0)
	var dur := {"aviso": float(d["aviso_s"]), "quebra": float(d.get("quebra_s", 0.35)), "varre": float(d["onda_s"]), "escoa": float(d.get("escoa_s", 0.6))}
	if fase != "":
		k += dt / float(dur[fase])
		if fase == "aviso":
			main.shake(0.6 + 1.8 * k * k)   # o mar ronca crescendo
			if k > 0.45 and randf() < 26.0 * dt:   # cospe espuma por cima da borda
				var c := _crista()
				_gota(c, Vector2(-lado * randf_range(60, 220), randf_range(-420, -220)), randf_range(4, 8))
		elif fase == "quebra":
			var c := _crista()
			if randf() < 40.0 * dt:
				_gota(c, Vector2(-lado * randf_range(80, 300), randf_range(-300, -80)), randf_range(4, 9))
		elif fase == "varre":
			_arrasta(dt)
			var f := _frente()
			if f < B and randf() < 34.0 * dt:   # spray da cabeça
				var x := wx(f - 20.0)
				_gota(Vector2(x, chao_u(f - 20.0) - _espessura(f - 30.0)), Vector2(-lado * randf_range(120, 320), randf_range(-320, -120)), randf_range(3, 7))
		if fase in ["varre", "escoa"] and _frente() >= B - 10.0 and randf() < 30.0 * dt:   # cascata de volta ao mar
			var x2 := wx(B + 8.0)
			bits.append({"p": Vector2(x2, chao_u(B - 4.0)), "v": Vector2(-lado * randf_range(40, 120), randf_range(-40, 40)), "t": 0.0, "life": 0.7, "r": randf_range(4, 8), "k": "gota"})
		if k >= 1.0:
			k = 0.0
			match fase:
				"aviso":
					fase = "quebra"
					Audio.play("soprador", 1.4, -8.0)
				"quebra":
					fase = "varre"
					_estouro()
				"varre":
					fase = "escoa"
				"escoa":
					fase = ""
					molhado_t = 3.0
	var i := bits.size() - 1
	while i >= 0:
		var b: Dictionary = bits[i]
		b["t"] += dt
		b["p"] += b["v"] * dt
		if b["k"] == "gota":
			b["v"].y += 1500.0 * dt
			if b["p"].y > ys + 10.0:
				b["t"] = b["life"]
		elif b["k"] == "nevoa":
			b["v"] *= 1.0 - 2.5 * dt
		if b["t"] >= b["life"]:
			bits.remove_at(i)
		i -= 1

func _crista() -> Vector2:
	var c := _parede()
	if c.is_empty():
		return Vector2(wx(0.0), yd)
	var v: Vector2 = c[3]
	return Vector2(wx(v.x), ys - v.y)

func _gota(p: Vector2, v: Vector2, r: float) -> void:
	if bits.size() < 140:
		bits.append({"p": p, "v": v, "t": 0.0, "life": 1.1, "r": r, "k": "gota"})

## O lábio bate no convés: estouro (leque de gotas + névoa + tremor) e pancada em quem está na zona.
func _estouro() -> void:
	var u0 := 0.62 * B
	var p := Vector2(wx(u0), chao_u(u0))
	Audio.play("explosao", 1.5, -6.0)
	Audio.play("agua", 0.8, 0.0)
	main.shake(9.0)
	for n in 34:
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		var sp := randf_range(260, 760)
		var v := Vector2.from_angle(a) * sp
		v.x = v.x * 0.8 - lado * 160.0   # o leque vai para dentro
		_gota(p + Vector2(randf_range(-60, 60), randf_range(-20, 0)), v, randf_range(4, 11))
	for n in 7:
		bits.append({"p": p + Vector2(randf_range(-70, 70), randf_range(-50, 0)), "v": Vector2(-lado * randf_range(40, 160), randf_range(-140, -40)),
			"t": 0.0, "life": randf_range(0.35, 0.6), "r": randf_range(12, 20), "k": "nevoa"})
	var e: Array = d["empurrao"]
	for r in mc._robots():
		var rr: Rect2 = r.rect()
		var u := (E - rr.get_center().x) * lado
		if u < -30.0 or u > 0.72 * B or rr.end.y < ys - Ht - 30.0 or rr.position.y > chao_u(clampf(u, 0.0, B)) + 8.0:
			continue
		hit[r.pid] = true
		r.knock(int(-lado), float(e[0]), float(e[1]) * 1.25, 0.3)   # o voo vem da altura e da reação, não da distância (o vão atrás mata)
		r.hitstop = 0.08
		r.vis.hurt(0.7, int(-lado))
		_molha(r)
		_respingo_robo(r, 14)

## A lâmina toca o robô: um tranco (uma vez) e depois correnteza enquanto ele estiver dentro dela.
func _arrasta(dt: float) -> void:
	var e: Array = d["empurrao"]
	for r in mc._robots():
		var px: float = r.position.x
		var u := (E - px) * lado
		if u < 0.0 or u > B + 10.0:
			continue
		var h := _espessura(u)
		if h < 6.0:
			continue
		var g := chao_u(u)
		if r.position.y < g - h - 12.0 or r.position.y > g + 14.0:
			continue
		if not hit.has(r.pid):
			hit[r.pid] = true
			r.knock(int(-lado), float(e[0]), float(e[1]), 0.15)
			r.vis.hurt(0.4, int(-lado))
			_molha(r)
			_respingo_robo(r, 9)
		elif r.is_on_floor():
			r.own_vx = move_toward(r.own_vx, -lado * float(d.get("correnteza", 260.0)), 1400.0 * dt)

func _molha(r) -> void:
	var ag = main.demo.agua
	if ag != null and is_instance_valid(ag):
		ag.molhar(r)

func _respingo_robo(r, n: int) -> void:
	for j in n:
		_gota(r.position + Vector2(randf_range(-20, 20), randf_range(-70, -10)), Vector2(randf_range(-260, 260) - lado * 120.0, randf_range(-480, -160)), randf_range(4, 8))

## Retângulo de perigo (bots fogem): a balsa da vez inteira enquanto houver onda.
func area(o: Vector2) -> Rect2:
	var b: Array = d["balsas"][qual]
	var alt := float(d["altura_t"]) * T + 96.0
	return Rect2(o.x + float(b[0]) * T, o.y + float(b[2]) * T - alt, (float(b[1]) - float(b[0])) * T, alt + 64.0)

# ------------------------------------------------------------------ desenho
func draw(ci: CanvasItem) -> void:
	if molhado_t > 0.0 and not chao.is_empty():
		_draw_molhado(ci)
	var c := _parede()
	if not c.is_empty():
		_draw_parede(ci, c)
	if fase in ["varre", "escoa"]:
		_draw_lamina(ci)
	for b in bits:
		var w: float = 1.0 - float(b["t"]) / float(b["life"])
		match b["k"]:
			"gota":
				var v: Vector2 = b["v"]
				var r: float = b["r"]
				if v.length() > 300.0:   # gota rápida estica na direção do movimento
					var dirv := v.normalized()
					ci.draw_set_transform(b["p"], dirv.angle(), Vector2(1.0 + minf(v.length() / 900.0, 0.9), 0.8))
					ci.draw_circle(Vector2.ZERO, r, C_ESPUMA if r < 6.0 else C_CLARO.lerp(C_ESPUMA, 0.5))
					ci.draw_set_transform(Vector2.ZERO)
				else:
					ci.draw_circle(b["p"], r, C_ESPUMA)
			"nevoa":
				var col := C_NEVOA
				col.a *= w
				ci.draw_circle(b["p"], float(b["r"]) * (1.0 + 0.6 * (1.0 - w)), col)

func _draw_parede(ci: CanvasItem, c: Array) -> void:
	var pts := _spline(_mundo(c), 7)
	var fundo := ys + 80.0   # fecha dentro do mar (a onda da frente da cena cobre a junção)
	var poly := PackedVector2Array(pts)
	poly.append(Vector2(pts[pts.size() - 1].x, fundo))
	poly.append(Vector2(pts[0].x, fundo))
	if Geometry2D.triangulate_polygon(poly).is_empty():
		return
	ci.draw_colored_polygon(poly, C_FUNDO)   # borda escura (papel de baixo)
	for camada in [[-12.0, C_CORPO], [-40.0, C_CORPO.lerp(C_MEIO, 0.55)]]:   # papéis recortados por cima, cada um menor
		for pp in Geometry2D.offset_polygon(poly, float(camada[0])):
			if pp.size() >= 3 and not Geometry2D.triangulate_polygon(pp).is_empty():
				ci.draw_colored_polygon(pp, camada[1])
	var n := pts.size()
	# dorso claro e espuma no lábio
	var dorso := PackedVector2Array()
	for i in range(int(n * 0.12), int(n * 0.55)):
		dorso.append(pts[i] + Vector2(0, 6))
	if dorso.size() > 1:
		ci.draw_polyline(dorso, C_CLARO, 9.0)
	var j := int(n * 0.28)
	while j < int(n * 0.62):
		var p := pts[j]
		var rr := 7.0 + 6.0 * absf(sin(j * 1.7 + t * 9.0))
		ci.draw_circle(p + Vector2(0, 3), rr, C_ESPUMA)
		j += 2
	# espuma escorrendo pela face (riscos de giz)
	for s in 4:
		var a := pts[int(n * (0.58 + 0.07 * s)) % n]
		var comp := 18.0 + 14.0 * sin(t * 6.0 + s)
		ci.draw_line(a + Vector2(0, 6), a + Vector2(lado * 4.0, 6.0 + comp), C_ESPUMA, 4.0)

func _draw_lamina(ci: CanvasItem) -> void:
	var f := _frente()
	var topo := PackedVector2Array()
	var base := PackedVector2Array()
	var n := chao.size()
	var u := 0.0
	var tem := false
	while u <= minf(f, B) + 0.1:
		var h := _espessura(u)
		var g := chao_u(minf(u, B - 1.0))
		var gs := lerpf(g, minf(g, chao_suave(minf(u, B - 1.0))), clampf(h / 30.0, 0.0, 1.0))   # lâmina fina não deixa rampa
		topo.append(Vector2(wx(u), gs - h))
		base.append(Vector2(wx(u), g + 6.0))
		if h > 2.0:
			tem = true
		u += DU * 0.5
	if not tem or topo.size() < 2:
		return
	var poly := PackedVector2Array(topo)
	for i in range(base.size() - 1, -1, -1):
		poly.append(base[i])
	if not Geometry2D.triangulate_polygon(poly).is_empty():
		ci.draw_colored_polygon(poly, Color(C_CORPO, 0.88))   # dá para ver o robô dentro d'água
	var trecho := PackedVector2Array()   # linha clara só onde ainda há água
	for i in topo.size():
		if base[i].y - 6.0 - topo[i].y > 2.0:
			trecho.append(topo[i])
		elif trecho.size() > 0:
			if trecho.size() > 1:
				ci.draw_polyline(trecho, C_CLARO, 5.0)
			trecho = PackedVector2Array()
	if trecho.size() > 1:
		ci.draw_polyline(trecho, C_CLARO, 5.0)
	# cabeça de espuma (bolhas na frente) e flocos no corpo
	var fx := minf(f, B)
	for i in 6:
		var uu := fx - 8.0 - i * 13.0
		if uu < 0.0:
			break
		var hh := _espessura(uu)
		if hh < 4.0:
			continue
		var g2 := chao_u(uu)
		var r := 6.0 + hh * 0.18 + 3.0 * sin(t * 12.0 + i)
		ci.draw_circle(Vector2(wx(uu), g2 - hh + r * 0.4), r, C_ESPUMA)
	var w := 0.0
	while w < fx - 40.0:
		var hh2 := _espessura(w)
		if hh2 > 10.0:
			var off := fposmod(w * 0.37 + t * 90.0, 26.0)
			ci.draw_circle(Vector2(wx(w + off * 0.3), chao_u(w) - hh2 * 0.55), 3.5, Color(C_ESPUMA, 0.8))
		w += 28.0
	# cascatas: a lâmina cai pela borda de dentro (até o mar) quando passa dela
	if f >= B - 6.0:
		var vol := 1.0 if fase == "varre" else maxf(1.0 - k, 0.0)
		var gx := wx(B)
		var gy := chao_u(B - 4.0)
		var larg := 26.0 * vol + 4.0
		var q := PackedVector2Array()
		for s in 9:
			var a := float(s) / 8.0
			q.append(Vector2(gx - lado * (8.0 + 40.0 * a * a), lerpf(gy - larg * 0.5, ys + 20.0, a)))
		for s in range(8, -1, -1):
			var a := float(s) / 8.0
			q.append(Vector2(gx - lado * (8.0 + larg + 40.0 * a * a), lerpf(gy + 4.0, ys + 20.0, a)))
		if not Geometry2D.triangulate_polygon(q).is_empty():
			ci.draw_colored_polygon(q, Color(C_CORPO, 0.9))
		ci.draw_circle(Vector2(gx - lado * (larg + 30.0), ys + 6.0), 10.0 + 6.0 * sin(t * 14.0), C_ESPUMA)

func _draw_molhado(ci: CanvasItem) -> void:
	var a := clampf(molhado_t / 3.0, 0.0, 1.0)
	var col := Color(0.2, 0.32, 0.5, 0.28 * a)
	var u := 0.0
	while u < B:
		var g := chao_u(u)
		var x := wx(u)
		ci.draw_rect(Rect2(minf(x, x - lado * DU), g, DU, 7.0), col)
		if fmod(u, 64.0) < DU and fmod(t * 1.7 + u * 0.13, 1.0) < 0.5 * a:   # pingos brilhando
			ci.draw_circle(Vector2(x, g + 3.0), 2.5, Color(1, 1, 1, 0.7 * a))
		u += DU
