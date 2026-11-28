extends Node2D
## ÁGUA — regra-assinatura da Fase 2 (Cargueiro Perdido; A55, docs/fases/derruba/f2_cargueiro/README.md).
## ALAGADO (abaixo da linha d'água de uma zona): corrida ×0,6, gravidade ×0,55 e queda máx ×0,5 (o pulo flutua alto),
## golpe recebido empurra ×1,25 (joga longe); respingo ao entrar/sair, bolhas saindo do robô.
## MOLHADO (onda, Onda Gigante: molhar(r, s)): corrida ×0,8 por alguns segundos, gotas pingando.
## Zonas por cena no manifesto (cenas[].agua.zonas = [[x, y, w, h], ...] em tiles relativos à cena); números em
## modos.json → demolicao.agua. Desempenho: zona = retângulo; "está na água" = 1 teste de ponto por robô (sem fluido).
## A superfície de cada zona (`topo`) pode mexer (maré M4, cúpula M7): perigos mudam `topo` e o resto segue sozinho.

var main: Node
var cfg: Dictionary
var zonas: Array = []      # {cena: int, rect: Rect2 (mundo), topo: float (y da superfície agora)}
var dentro := {}           # robô → estava alagado no quadro anterior
var molhado := {}          # robô → segundos molhado restantes
var bits: Array = []       # {p, v, t, life, k: "gota"|"bolha"|"respingo"}
var t := 0.0

func setup(m: Node) -> void:
	main = m
	cfg = m.demo.cfg.get("agua", {"corrida": 0.6, "gravidade": 0.55, "queda_max": 0.5, "empurrao": 1.25, "molhado_corrida": 0.8, "molhado_s": 2.0})
	z_index = 2   # por cima do palco e dos robôs, translúcida (quem está dentro parece submerso)
	var man: Dictionary = MapaReg.manifesto(m.game_mode, m.level.id)
	for c in man.get("cenas", []):
		var ordem := int(c.get("ordem", 1))
		if String(m.level.prop("etapa%d" % ordem, "")) == "":
			continue
		var o: Vector2 = m.level.etapa_rect(ordem).position
		for z in c.get("agua", {}).get("zonas", []):
			var r := Rect2(o + Vector2(float(z[0]), float(z[1])) * 64.0, Vector2(float(z[2]), float(z[3])) * 64.0)
			zonas.append({"cena": ordem, "rect": r, "topo": r.position.y})

static func tem_agua(m: Node) -> bool:
	for c in MapaReg.manifesto(m.game_mode, m.level.id).get("cenas", []):
		if not c.get("agua", {}).get("zonas", []).is_empty():
			return true
		for mc in c.get("mecanismos", []):   # onda que molha (M3) precisa do "molhado" mesmo sem zona alagada
			if String(mc.get("tipo", "")) == "onda_balsa":
				return true
	return false

## O ponto está debaixo d'água (alguma zona, abaixo da superfície atual)?
func alagado(p: Vector2) -> bool:
	for z in zonas:
		var r: Rect2 = z["rect"]
		if p.x >= r.position.x and p.x <= r.end.x and p.y >= float(z["topo"]) and p.y <= r.end.y:
			return true
	return false

## Onda/respingo de evento ou perigo: deixa o robô molhado por s segundos.
func molhar(r: Node, s := -1.0) -> void:
	molhado[r] = maxf(float(molhado.get(r, 0.0)), float(cfg["molhado_s"]) if s < 0.0 else s)

func update(dt: float) -> void:
	t += dt
	for r in main.robots:
		if not is_instance_valid(r):
			continue
		var peito: Vector2 = r.position + Vector2(0, -36)
		var no: bool = r.alive and alagado(peito)
		r.agua_grav = float(cfg["gravidade"]) if no else 1.0
		r.agua_queda = float(cfg["queda_max"]) if no else 1.0
		r.agua_empurra = float(cfg["empurrao"]) if no else 1.0
		if no:
			r.env_slow = minf(r.env_slow, float(cfg["corrida"]))
			molhado[r] = float(cfg["molhado_s"])   # sai da água ainda pingando
			if randf() < 3.0 * dt:
				bits.append({"p": peito + Vector2(randf_range(-14, 14), -20), "v": Vector2(0, -70), "t": 0.0, "life": 1.2, "k": "bolha"})
		elif float(molhado.get(r, 0.0)) > 0.0:
			molhado[r] = float(molhado[r]) - dt
			r.env_slow = minf(r.env_slow, float(cfg["molhado_corrida"]))
			if randf() < 8.0 * dt:
				bits.append({"p": r.position + Vector2(randf_range(-20, 20), -60), "v": Vector2(0, 60), "t": 0.0, "life": 0.5, "k": "gota"})
		if r.alive and no != bool(dentro.get(r, false)):
			_respingo(Vector2(r.position.x, _topo_em(r.position.x)))
		dentro[r] = no
	var i := bits.size() - 1
	while i >= 0:   # sem filter (não aloca lista nova por quadro)
		var b: Dictionary = bits[i]
		b["t"] += dt
		b["p"] += b["v"] * dt
		if b["k"] != "bolha":
			b["v"].y += 900.0 * dt
		if b["t"] >= b["life"]:
			bits.remove_at(i)
		i -= 1
	queue_redraw()

func _topo_em(x: float) -> float:
	for z in zonas:
		var r: Rect2 = z["rect"]
		if x >= r.position.x and x <= r.end.x:
			return float(z["topo"])
	return 0.0

func _respingo(p: Vector2) -> void:
	Audio.play("agua", 1.0, -4.0)
	for k in 8:
		bits.append({"p": p, "v": Vector2(randf_range(-160, 160), randf_range(-420, -200)), "t": 0.0, "life": 0.6, "k": "respingo"})

func _draw() -> void:
	var _pf := Perf.t0()
	var v: Rect2 = main.view_rect().grow(100)
	for z in zonas:
		var r: Rect2 = z["rect"]
		var topo: float = z["topo"]
		if topo >= r.end.y or not v.intersects(r):
			continue
		var a := Rect2(r.position.x, topo, r.size.x, r.end.y - topo)
		draw_rect(a, Color(0.25, 0.78, 0.86, 0.32))
		var pts := PackedVector2Array()   # linha clara da superfície, ondulando
		var x := r.position.x
		while x <= r.end.x + 0.1:
			pts.append(Vector2(x, topo + sin(t * 2.4 + x * 0.03) * 4.0))
			x += 24.0
		draw_polyline(pts, Color(1, 1, 1, 0.85), 4.0)
	for b in bits:
		var k: float = 1.0 - float(b["t"]) / float(b["life"])
		match b["k"]:
			"bolha":
				draw_arc(b["p"], 5.0, 0.0, TAU, 8, Color(1, 1, 1, 0.7 * k), 2.0)
			"gota":
				draw_circle(b["p"], 3.0, Color(0.55, 0.88, 0.96, k))
			"respingo":
				draw_circle(b["p"], 5.0 * k + 2.0, Color(0.85, 0.97, 1.0, k))
	Perf.add("agua", _pf)
