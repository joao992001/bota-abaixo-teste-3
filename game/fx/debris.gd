extends Node2D
## Robô desmontando: cada parte voa girando, quica uma vez e some (eliminação "engraçada").

var pieces: Array = []   # {tex: [Texture2D], rect, mod, pos, vel, rot, spin}
var t := 0.0
const LIFE := 1.8

func setup(parts: Array, origin: Vector2, facing: int, kick: Vector2) -> void:
	position = origin
	for p in parts:
		var r: Rect2 = p["rect"]
		var c := r.get_center() * Vector2(facing, 1)
		var away := c.normalized() if c.length() > 1.0 else Vector2.UP
		pieces.append({"tex": p["tex"], "rect": Rect2(r.position - r.get_center(), r.size), "mod": p["mod"], "mods": p.get("mods", []),
			"pos": c, "vel": away * randf_range(260, 520) + Vector2(randf_range(-160, 160), randf_range(-760, -420)) + kick,
			"rot": 0.0, "spin": randf_range(-14, 14), "flip": facing})

func _process(dt: float) -> void:
	var _pf := Perf.t0()
	_process_perf(dt)
	Perf.add("destrocos", _pf)

func _process_perf(dt: float) -> void:
	t += dt
	for p in pieces:
		p["vel"].y += 2600.0 * dt
		p["pos"] += p["vel"] * dt
		p["rot"] += p["spin"] * dt
	if t > LIFE:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var _pf := Perf.t0()
	_draw_perf()
	Perf.add("draw_destrocos", _pf)

func _draw_perf() -> void:
	var a := clampf((LIFE - t) / 0.5, 0.0, 1.0)
	for p in pieces:
		var r: Rect2 = p["rect"]
		draw_set_transform(p["pos"], p["rot"], Vector2(p["flip"], 1))
		var mods: Array = p["mods"]
		for k in p["tex"].size():
			var tx: Texture2D = p["tex"][k]
			if tx != null:
				var m: Color = mods[k] if k < mods.size() else p["mod"]
				draw_texture_rect(tx, r, false, Color(m.r, m.g, m.b, a))
	draw_set_transform(Vector2.ZERO)
