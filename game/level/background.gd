extends Node2D
## Fundo da arena (camada própria, com paralaxe): imagem do tema (assets/temas/<tema>/fundo.png, ou o fundo antigo
## do Canteiro) e animações leves de ambiente por tema. Coordenadas da tela 1920x1080.
##   fábrica: poeira na luz · porto: gaivotas e brilho no mar · cidade: estrelas e neon · canteiro/viaduto: pássaros
##   demolição/mina: poeira caindo · pântano: vaga-lumes · serraria: folhas caindo · ferro-velho/fundição: faíscas

var texture: Texture2D = null
var theme := "canteiro"
var t := 0.0
var _rng := RandomNumberGenerator.new()
var motes: Array = []      # partículas: {pos, vel, a, r, col, sway, ph}
var gulls: Array = []      # pássaros: {x, y, s, ph}
var stars: Array = []      # cidade: {pos, r, ph}
var bird_col := Color("#f8f5ee")

## Partículas de ambiente por tema: [quantidade, cor, raio min, raio max, velocidade min, velocidade max, balanço, faixa y]
const MOTES := {
	"fabrica": [46, "#fff7e0", 2.6, 2.6, Vector2(-8, -14), Vector2(8, -4), 0.0, Vector2(160, 900)],
	"demolicao": [60, "#efe6dc", 1.6, 3.4, Vector2(-6, 18), Vector2(6, 46), 6.0, Vector2(0, 1080)],
	"mina": [40, "#e8d2b0", 1.2, 2.4, Vector2(-3, 20), Vector2(3, 40), 2.0, Vector2(0, 1080)],
	"pantano": [26, "#e9ff8a", 2.4, 3.6, Vector2(-14, -10), Vector2(14, 10), 20.0, Vector2(300, 950)],
	"serraria": [22, "#d98a3a", 3.0, 4.6, Vector2(10, 30), Vector2(30, 60), 26.0, Vector2(0, 1080)],
	"ferro_velho": [18, "#ffd36a", 1.4, 2.4, Vector2(-30, -60), Vector2(30, -20), 0.0, Vector2(500, 1000)],
	"fundicao": [55, "#ffb347", 1.5, 3.2, Vector2(-10, -80), Vector2(10, -30), 10.0, Vector2(200, 1080)],
}

func _ready() -> void:
	set_theme("canteiro")

func set_theme(name: String) -> void:
	theme = name
	var tex := Data.tex("temas/%s/fundo" % name)
	texture = tex if tex != null else Data.tex("cenario/fundo_canteiro")
	_rng.seed = hash(name)
	motes.clear()
	gulls.clear()
	stars.clear()
	if MOTES.has(name):
		var m: Array = MOTES[name]
		for i in int(m[0]):
			var v0: Vector2 = m[4]
			var v1: Vector2 = m[5]
			var yr: Vector2 = m[7]
			motes.append({"pos": Vector2(_rng.randf_range(0, 1920), _rng.randf_range(yr.x, yr.y)),
				"vel": Vector2(_rng.randf_range(v0.x, v1.x), _rng.randf_range(v0.y, v1.y)), "a": _rng.randf_range(0.25, 0.7),
				"r": _rng.randf_range(m[2], m[3]), "ph": _rng.randf() * TAU})
	match name:
		"porto", "canteiro", "concreto", "viaduto":
			bird_col = Color("#f8f5ee") if name == "porto" else Color("#4a4458")
			for i in (5 if name == "porto" else 3):
				gulls.append({"x": _rng.randf_range(0, 1920), "y": _rng.randf_range(80, 380), "s": _rng.randf_range(40, 90), "ph": _rng.randf() * TAU})
		"cidade":
			for i in 60:
				stars.append({"pos": Vector2(_rng.randf_range(0, 1920), _rng.randf_range(0, 500)), "r": _rng.randf_range(1.5, 3.2), "ph": _rng.randf() * TAU})
	queue_redraw()

func _process(dt: float) -> void:
	var _pf := Perf.t0()
	_process_perf(dt)
	Perf.add("fundo", _pf)

func _process_perf(dt: float) -> void:
	if motes.is_empty() and gulls.is_empty() and stars.is_empty():
		return
	t += dt
	var yr: Vector2 = MOTES[theme][7] if MOTES.has(theme) else Vector2(0, 1080)
	for m in motes:
		m["pos"] += m["vel"] * dt
		if m["pos"].y < yr.x - 10.0:
			m["pos"] = Vector2(_rng.randf_range(0, 1920), yr.y)
		elif m["pos"].y > yr.y + 10.0:
			m["pos"] = Vector2(_rng.randf_range(0, 1920), yr.x)
		m["pos"].x = fposmod(m["pos"].x, 1920.0)
	for g in gulls:
		g["x"] += g["s"] * dt
		if g["x"] > 2000.0:
			g["x"] = -80.0
			g["y"] = _rng.randf_range(80, 380)
	queue_redraw()

func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_fundo", _pf)

func _draw_perf() -> void:
	if texture != null:
		draw_texture_rect(texture, Rect2(0, 0, 1920, 1080), false)
	else:
		draw_rect(Rect2(0, 0, 1920, 1080), Color("#3aa7a3"))
	if MOTES.has(theme):
		var cfg: Array = MOTES[theme]
		var col := Color(cfg[1])
		var sway: float = cfg[6]
		for m in motes:
			var p: Vector2 = m["pos"] + Vector2(sin(t * 1.7 + m["ph"]) * sway, 0)
			var a: float = m["a"]
			match theme:
				"pantano":   # vaga-lume piscando com halo
					a *= 0.3 + 0.7 * absf(sin(t * 2.2 + m["ph"]))
					draw_circle(p, m["r"] * 3.0, Color(col, a * 0.25))
				"fabrica":
					a *= 0.6 + 0.4 * sin(t * 2.0 + p.x)
				"ferro_velho", "fundicao":   # faísca: risquinho na direção do movimento
					a *= clampf(1.0 - fposmod(t * 0.7 + m["ph"], 1.0) * 0.6, 0.0, 1.0)
					draw_line(p, p - m["vel"] * 0.06, Color(col, a), m["r"], true)
					continue
				"serraria":   # folha girando
					var ang: float = t * 2.0 + m["ph"]
					var d: Vector2 = Vector2.from_angle(ang) * float(m["r"])
					draw_colored_polygon(PackedVector2Array([p - d, p + d.orthogonal() * 0.5, p + d, p - d.orthogonal() * 0.5]), Color(col, a))
					continue
			draw_circle(p, m["r"], Color(col, a))
	for g in gulls:
		var gp := Vector2(g["x"], g["y"] + sin(t * 1.5 + g["ph"]) * 10.0)
		var flap := sin(t * 7.0 + g["ph"]) * 8.0
		draw_polyline(PackedVector2Array([gp + Vector2(-16, -flap), gp + Vector2(-6, 0), gp, gp + Vector2(6, 0), gp + Vector2(16, -flap)]), bird_col, 3.0, true)
	match theme:
		"porto":
			for k in 14:   # brilho no mar
				var x := fposmod(k * 151.0 + t * 30.0, 1960.0) - 20.0
				var y := 700.0 + (k % 5) * 40.0
				draw_line(Vector2(x, y), Vector2(x + 26, y), Color(1, 1, 1, 0.35 + 0.3 * sin(t * 3.0 + k)), 3.0)
		"cidade":
			for s in stars:
				draw_circle(s["pos"], s["r"], Color(1.0, 0.97, 0.86, 0.35 + 0.55 * absf(sin(t * 1.3 + s["ph"]))))
			var on := 0.55 + 0.45 * absf(sin(t * 2.2))   # neon do outdoor pulsando
			draw_rect(Rect2(772, 432, 276, 96), Color(1.0, 0.48, 0.72, 0.25 * on), false, 10.0)
