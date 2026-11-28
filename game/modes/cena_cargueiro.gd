extends "res://modes/cena.gd"
## CENA VIVA da Fase 2 — CARGUEIRO PERDIDO (prop "cena: cargueiro" no .lvl; docs/fases/derruba/f2_cargueiro/).
## Camadas paradas das fotografias aprovadas (art/src/cenarios/f2_jogo.py → assets/cargueiro/) com paralaxe + o que mexe:
## Alto-Mar (etapa1): gaivotas, ondas na linha do mar (atrás e na frente: quem cai some na água).
## Atlântida (etapa2, embaixo): bolhas subindo, peixes, águas-vivas boiando. Destroços (etapa3, à direita): gaivotas e ondas.
## Entre as cenas: o mar (a queda da rota total atravessa a água escurecendo, com bolhas).
## Reaproveita _layer/_par/_view da cena da fase 1 (generalização pedida pelo manual na 2ª fase).

const FOTO_H := 1080.0 / 1920.0      # proporção da fotografia (a camada cobre a cena + a faixa do mar embaixo)
const MAR_Y := 15 * 64.0              # linha do mar nas cenas de superfície (KO embaixo)
var gulls: Array = []      # {x, y, v, ph, area}
var fish: Array = []       # {x, y, v, tex, ph}
var jellies: Array = []    # {x, y0, ph}
var bubbles: Array = []    # {x, y, v, r, ph}

func setup(m: Node) -> void:
	main = m
	key = "cargueiro"
	a1 = m.level.etapa_rect(1)
	a2 = m.level.etapa_rect(2)
	if String(m.level.prop("etapa3", "")) != "":
		a3 = m.level.etapa_rect(3)
	for n in ["e1_longe", "e2_longe", "e3_longe", "gaivota", "onda_tarde", "onda_manha", "agua_viva", "peixe_a", "peixe_b"]:
		tex[n] = Data.tex("%s/%s" % [key, n])
	_rng.seed = 91
	for i in 7:
		var ar: Rect2 = a1 if i < 4 or a3.size.x <= 0.0 else a3
		gulls.append({"x": _rng.randf_range(0, ar.size.x), "y": _rng.randf_range(120, 380), "v": _rng.randf_range(60, 110) * (1 if i % 2 == 0 else -1),
			"ph": _rng.randf() * TAU, "area": 1 if ar == a1 else 3})
	for i in 6:
		fish.append({"x": _rng.randf_range(0, a2.size.x), "y": _rng.randf_range(160, 560), "v": _rng.randf_range(50, 120) * (1 if i % 2 == 0 else -1),
			"tex": "peixe_a" if i % 2 == 0 else "peixe_b", "ph": _rng.randf() * TAU})
	for i in 3:
		jellies.append({"x": [260.0, 1180.0, 1700.0][i], "y0": [300.0, 220.0, 420.0][i], "ph": _rng.randf() * TAU})
	for i in 36:
		bubbles.append({"x": _rng.randf_range(0, a2.size.x), "y": _rng.randf_range(-200, a2.size.y), "v": _rng.randf_range(40, 110),
			"r": _rng.randf_range(3, 9), "ph": _rng.randf() * TAU})
	front = Node2D.new()
	front.z_index = 3
	front.draw.connect(_draw_front)
	add_child(front)

func _process_perf(dt: float) -> void:
	if main == null or main.paused:
		return
	t += dt
	for g in gulls:
		var w: float = (a1 if g["area"] == 1 else a3).size.x
		g["x"] = fposmod(g["x"] + g["v"] * dt, w + 200.0)
	for f in fish:
		f["x"] = fposmod(f["x"] + f["v"] * dt, a2.size.x + 200.0)
	for b in bubbles:
		b["y"] -= b["v"] * dt
		if b["y"] < -260.0:
			b["y"] = a2.size.y + 40.0
	queue_redraw()
	front.queue_redraw()

## Camada da fotografia sobre a cena (largura da cena; altura na proporção da foto).
func _foto(name: String, area: Rect2, f: float, grow: float) -> void:
	var tx: Texture2D = tex.get(name)
	if tx == null:
		return
	var r := Rect2(area.position, Vector2(area.size.x, area.size.x * FOTO_H))
	r = r.grow_individual(r.size.x * grow, r.size.y * grow, r.size.x * grow, r.size.y * grow)
	r.position += _par(area, f)
	draw_texture_rect(tx, r, false)

func _draw_perf() -> void:
	var v := _view()
	draw_rect(v, Color("#1f5f78"))   # o mar entre as cenas (o que a câmera mostra além das fotografias)
	var py := a1.end.y
	if v.end.y > py and v.position.y < a2.position.y:   # a coluna de água da queda: escurece descendo, com bolhas
		draw_polygon(PackedVector2Array([Vector2(v.position.x, py), Vector2(v.end.x, py), Vector2(v.end.x, a2.position.y), Vector2(v.position.x, a2.position.y)]),
			PackedColorArray([Color("#3a6f9a"), Color("#3a6f9a"), Color("#2a8fa8"), Color("#2a8fa8")]))
	if v.intersects(a1.grow(400)):
		draw_rect(Rect2(a1.position.x - 900.0, v.position.y, a1.size.x + 1036.0, a1.position.y + 320.0 - v.position.y), Color("#f4ad80"))   # céu além da foto
		_foto("e1_longe", a1, 0.06, 0.03)
		_ondas("onda_tarde", a1, 1.0)
		_gaivotas(1, a1)
	if a3.size.x > 0.0 and v.intersects(a3.grow(400)):
		draw_rect(Rect2(a3.position.x - 120.0, v.position.y, a3.size.x + 900.0, a3.position.y + 320.0 - v.position.y), Color("#ffe2b0"))   # não invade o Alto-Mar
		_foto("e3_longe", a3, 0.06, 0.03)
		_ondas("onda_manha", a3, 0.8)
		_gaivotas(3, a3)
	if v.intersects(a2.grow(300)):
		_foto("e2_longe", a2, 0.05, 0.03)
		_atlantida()

## Ondas atrás do palco na linha do mar (deslizam e balançam; a da frente fica em _draw_front_perf).
func _ondas(name: String, area: Rect2, vel: float) -> void:
	var tx: Texture2D = tex.get(name)
	if tx == null:
		return
	var y := area.position.y + MAR_Y - 46.0 + sin(t * 1.3) * 6.0
	var off := fposmod(t * 40.0 * vel, 960.0)
	var x := area.position.x - 960.0 - off
	while x < area.end.x + 200.0:
		draw_texture_rect(tx, Rect2(x, y, 960, 140), false, Color(1, 1, 1, 0.85))
		x += 958.0

func _gaivotas(qual: int, area: Rect2) -> void:
	var tx: Texture2D = tex.get("gaivota")
	if tx == null:
		return
	for g in gulls:
		if g["area"] != qual:
			continue
		var p := area.position + Vector2(g["x"] - 100.0, g["y"] + sin(t * 2.0 + g["ph"]) * 10.0) + _par(area, 0.04)
		var bat := 0.75 + 0.25 * absf(sin(t * 6.0 + g["ph"]))   # bater de asas: achata e estica
		draw_texture_rect(tx, Rect2(p.x, p.y + 24.0 * (1.0 - bat), 64.0, 48.0 * bat), false)

func _atlantida() -> void:
	var o := a2.position
	for b in bubbles:
		var p := o + Vector2(b["x"] + sin(t * 2.0 + b["ph"]) * 8.0, b["y"])
		draw_arc(p, b["r"], 0.0, TAU, 10, Color(1, 1, 1, 0.55), 2.0)
	for f in fish:
		var tx: Texture2D = tex.get(f["tex"])
		if tx == null:
			continue
		var p := o + Vector2(f["x"] - 100.0, f["y"] + sin(t * 1.5 + f["ph"]) * 14.0)
		var w := 64.0 if f["v"] > 0.0 else -64.0   # vira para o lado em que nada
		draw_texture_rect(tx, Rect2(p.x if w > 0.0 else p.x + 64.0, p.y, w, 40.0), false, Color(1, 1, 1, 0.8))
	var jt: Texture2D = tex.get("agua_viva")
	if jt != null:
		for j in jellies:
			var s := 1.0 + 0.08 * sin(t * 2.4 + j["ph"])   # pulsa nadando
			var p := o + Vector2(j["x"], j["y0"] + sin(t * 0.7 + j["ph"]) * 40.0)
			draw_texture_rect(jt, Rect2(p.x - 40.0 * s, p.y, 80.0 * s, 110.0 / s), false, Color(1, 1, 1, 0.7))

func _draw_front_perf() -> void:
	var v := _view()
	for e in [[a1, "onda_tarde"], [a3, "onda_manha"]]:   # onda da frente: quem cai no mar some atrás dela
		var area: Rect2 = e[0]
		if area.size.x <= 0.0 or not v.intersects(area):
			continue
		var tx: Texture2D = tex.get(e[1])
		if tx == null:
			continue
		var y := area.position.y + MAR_Y + 10.0 + sin(t * 1.1 + 1.0) * 8.0
		var off := fposmod(t * 70.0, 960.0)
		var x := area.position.x - off
		while x < area.end.x + 200.0:
			front.draw_texture_rect(tx, Rect2(x, y, 960, 140), false)
			x += 958.0
