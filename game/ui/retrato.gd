extends Node2D
## Retrato redondo do robô (a cabeça, recortada num círculo com clip_children), com aro de contorno.
## O HUD posiciona estes nós a cada quadro (ver hud.gd: _head); fora de uso ficam invisíveis.

const RobotVis := preload("res://player/robot_visual.gd")
const Kit := preload("res://ui/kit.gd")

var look := {}
var radius := 50.0
var ring := Kit.INK
var bg := Kit.CREAM
var expr := "normal"
var t := 0.0
var robo := Node2D.new()

func _init() -> void:
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(robo)
	robo.draw.connect(_draw_robo)

func _process(dt: float) -> void:
	t += dt
	queue_redraw()
	robo.queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, bg)

func _draw_robo() -> void:
	var _pf := Perf.t0()
	_draw_robo_perf()
	Perf.add("draw_retratos", _pf)

func _draw_robo_perf() -> void:
	if look.is_empty() or Data.robot_meta.is_empty():
		return
	var g: Dictionary = Data.model_meta(look["model"])
	var ey: Array = g["eyes"]
	var ec := (Vector2(float(ey[0][0]), float(ey[0][1])) + Vector2(float(ey[1][0]), float(ey[1][1]))) / 2.0 - RobotVis.ORIGIN
	var s := radius / 21.0
	var pose: Dictionary = RobotVis.idle_pose(t)
	pose["expr"] = expr if expr != "normal" else pose["expr"]
	RobotVis.draw_robot(robo, look, pose, Transform2D(0.0, Vector2(s, s), 0.0, -ec * s + Vector2(0, radius * 0.18)))
	robo.draw_set_transform(Vector2.ZERO)
	var w := maxf(4.0, radius * 0.1)
	robo.draw_arc(Vector2.ZERO, radius - w / 2.0, 0, TAU, 48, ring, w, true)
