extends Control
## HUD e telas da partida no estilo cartoon (ui/kit.gd): cartões dos jogadores embaixo (retrato, estrelas, % de dano,
## item), título da rodada no topo, entrada de jogadores, placar da rodada e vitória. Menus em ui/menus.gd.

const Kit := preload("res://ui/kit.gd")
const Obra := preload("res://ui/obra.gd")
const RobotVis := preload("res://player/robot_visual.gd")
const Retrato := preload("res://ui/retrato.gd")
const DIM := Color(0.16, 0.1, 0.18, 0.45)
const DARK := Color("#2a1a2e")
const CARD_W := 290.0
const CARD_H := 62.0
const CARD_Y := 6.0

var main: Node
var t := 0.0
var _banner := ""
var bare := false   # capturas para as propostas de interface: só o cenário, sem HUD
var _banner_age := 0.0
var _heads: Array = []          # retratos redondos (nós com recorte), reaproveitados a cada quadro
var _heads_used := 0
var _heads_root := Node2D.new()
var _over := Node2D.new()       # desenhos por cima dos retratos (slot da spell, "FORA!")
var _over_cmds: Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_heads_root)
	add_child(_over)
	_over.draw.connect(func():
		for c in _over_cmds:
			c.call(_over))

func _process(dt: float) -> void:
	t += dt
	_banner_age += dt
	var et = _etapas()
	if et != null:   # manômetro: agulha persegue o valor; quando algo cai, dá um tranco (A6)
		var alvo: float = et.progresso
		if alvo < gauge_v - 0.15:
			gauge_v = alvo   # cena nova: zera na hora
		elif alvo > gauge_v + 0.002:
			gauge_kick = 1.0
		gauge_v = lerpf(gauge_v, alvo, minf(1.0, dt * 6.0))
		gauge_kick = maxf(0.0, gauge_kick - dt * 2.5)

## Cenas do Derruba (o manômetro só existe onde há troca de cena).
func _etapas():
	var et = main.demo.etapas if main.mode == "demolicao" and main.demo != null else null
	return et if et != null and is_instance_valid(et) else null

const GAUGE_ARC := 240.0
var gauge_v := 0.0      # valor mostrado pela agulha (0..1)
var gauge_kick := 0.0   # tranco da agulha quando a destruição sobe

## Manômetro circular da destruição da cena (Derruba v2, A6/A16/A18): mostrador de 10% a 90% em 6 zonas
## (verde → vermelho); abaixo de 10% a agulha fica no começo, em 90% encosta no fim (= rota total); traço em 50%;
## número embaixo da agulha.
func draw_gauge(c: Vector2, r: float, v: float, kick := 0.0) -> void:
	var dc: Dictionary = main.demo.etapas.dcfg if _etapas() != null else {}
	var mm: Array = dc.get("mostrador", [0.1, 0.9])
	var cols: Array = dc.get("zonas", ["#2e9e4f", "#8fd46a", "#f2d04b", "#f39a3a", "#ec6448", "#a8233a"])
	var lo := float(mm[0])
	var hi := float(mm[1])
	var ang := func(p: float) -> float: return deg_to_rad(150.0 + GAUGE_ARC * (clampf(p, lo, hi) - lo) / (hi - lo))
	draw_circle(c + Vector2(0, r * 0.12), r, Kit.INK)
	draw_circle(c, r, Kit.CREAM)
	var rm := r * 0.73
	var wz := r * 0.26
	for k in 6:
		var a0: float = ang.call(lo + (hi - lo) * k / 6.0)
		var a1: float = ang.call(lo + (hi - lo) * (k + 1) / 6.0)
		draw_arc(c, rm, a0, a1, 10, Color(String(cols[k])), wz, true)
	draw_arc(c, rm + wz * 0.5, ang.call(lo), ang.call(hi), 40, Kit.INK, maxf(2.0, r * 0.05), true)
	draw_arc(c, rm - wz * 0.5, ang.call(lo), ang.call(hi), 40, Kit.INK, maxf(2.0, r * 0.05), true)
	for k in 7:
		var a: float = ang.call(lo + (hi - lo) * k / 6.0)
		draw_line(c + Vector2.from_angle(a) * (rm - wz * 0.5), c + Vector2.from_angle(a) * (rm + wz * 0.5), Kit.INK, maxf(2.0, r * 0.04), true)
	var a50: float = ang.call(float(dc.get("limiar_moderada", 0.5)))
	draw_line(c + Vector2.from_angle(a50) * (rm - wz * 0.7), c + Vector2.from_angle(a50) * (rm + wz * 0.85), Kit.INK, maxf(3.0, r * 0.08), true)
	draw_arc(c, r, 0.0, TAU, 48, Kit.INK, maxf(3.0, r * 0.08), true)
	var an: float = ang.call(v) + sin(t * 40.0) * 0.07 * kick
	var tip := c + Vector2.from_angle(an) * r * 0.72
	var b1 := c + Vector2.from_angle(an + PI * 0.5) * r * 0.11
	var b2 := c + Vector2.from_angle(an - PI * 0.5) * r * 0.11
	draw_colored_polygon(PackedVector2Array([tip, b1, b2]), Kit.INK)
	draw_circle(c, r * 0.15, Kit.INK)
	draw_circle(c, r * 0.1, Kit.YEL)
	Kit.title(self, Vector2(c.x - 120, c.y + r * 0.78), "%d%%" % int(round(v * 100.0)), int(r * 0.4) + int(kick * 4.0), Color.WHITE, 240)

func text(pos: Vector2, s: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, outline := 0) -> void:
	Kit.text(self, pos, s, sz, col, align, w, outline)

func panel(r: Rect2, tint := Color.WHITE) -> void:
	Kit.paper(self, r, tint)

func _look(p: Dictionary) -> Dictionary:
	return {"color": p["color"], "model": p["model"], "skin": String(p.get("skin", ""))}

## Nome do jogador: "P1".."P4" (o modelo do robô aparece na entrada e na vitória).
func pname(i: int) -> String:
	return "P%d" % (i + 1)

## Retrato redondo do jogador i centrado em c (desenhado por cima deste quadro).
func _head(i: int, c: Vector2, r: float, ring := Kit.INK, bg := Kit.CREAM, expr := "normal", alpha := 1.0) -> void:
	if _heads_used >= _heads.size():
		var n := Retrato.new()
		_heads_root.add_child(n)
		_heads.append(n)
	var h = _heads[_heads_used]
	_heads_used += 1
	h.look = _look(main.players[i])
	h.position = c
	h.radius = r
	h.ring = ring
	h.bg = bg
	h.expr = expr
	h.modulate = Color(1, 1, 1, alpha)
	h.visible = true

## Texto ajustado: diminui a fonte até caber na largura.
func fit_text(pos: Vector2, s: String, size: int, col: Color, w: float, outline := 0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var sz := size
	while sz > 14 and Kit.font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
		sz -= 2
	Kit.text(self, pos, s, sz, col, align, w, outline)

func _draw() -> void:
	_heads_used = 0
	_over_cmds.clear()
	_draw_all()
	for n in range(_heads_used, _heads.size()):
		_heads[n].visible = false
	_over.queue_redraw()

func _draw_all() -> void:
	var S = main.S
	if bare:
		if main.state in main.MENU_STATES:
			main.menus._draw_scene(self, [1.0, 1.0, 1.0, 1.0])
		return
	if main.state in main.MENU_STATES:
		main.menus.draw(self)
		_draw_toasts()
		return
	match main.state:
		S.JOIN: _draw_join()
		S.RUN: _draw_run()
		S.SCORE: _draw_score()
		S.WIN: _draw_win()
	if not main.paused and main.state == S.RUN:
		_draw_tags()
	for fl in main.floaters:
		var k: float = fl["t"] / 1.2
		var c: Color = fl["color"]
		c.a = 1.0 - k * k
		var p: Vector2 = main.to_screen(fl["pos"]) + Vector2(-260, -k * 60)
		Kit.text(self, p, fl["text"], 40, c, HORIZONTAL_ALIGNMENT_CENTER, 520, 10, Color(Kit.INK, c.a))
	if main.sandbox and not main.paused:
		main.tester().draw(self)
	if main.paused:
		main.menus.draw(self)
	_draw_toasts()
	if main.debug:
		text(Vector2(20, 1060), "DEBUG  F2 pula fase · F5 jogador parado · F6 lento", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 6)

# ---------------------------------------------------------------- cartões dos jogadores (embaixo) e topo
func _draw_tags() -> void:
	var S = main.S
	var n: int = main.players.size()
	var xs: Array = card_slots(n)
	for i in n:
		_card(i, Rect2(xs[i], CARD_Y, CARD_W, CARD_H))
	# topo, no meio: manômetro da cena no Derruba com cenas (substitui o "RODADA", A6); nos outros, o título da rodada
	if _etapas() != null:
		draw_gauge(Vector2(960, 62), 52, gauge_v, gauge_kick)
	else:
		Kit.title(self, Vector2(0, 42), "RODADA %d" % main.round_no, 34)
	if main.mode == "demolicao" and main.state == S.RUN:
		_draw_event_note()
	# avisos de derrubada (embaixo dos cartões da direita)
	if main.mode == "demolicao":
		var fy := CARD_Y + CARD_H + 44.0
		for f in main.demo.feed:
			var a: float = clampf((4.5 - f["t"]) / 0.5, 0.0, 1.0)
			var fr := Rect2(1920.0 - 14.0 - 330.0, fy, 330, 36)
			Kit.chunk(self, fr, Color(Kit.CREAM, a * 0.92), 18, 4, 3.0)
			var p2: Dictionary = main.players[f["col"]] if f["col"] < main.players.size() else {"color": 0}
			fit_text(Vector2(fr.position.x + 12, fy + 25), f["text"], 20, Color(Data.TEXT_COLORS[p2["color"]], a), fr.size.x - 24, 0, HORIZONTAL_ALIGNMENT_CENTER)
			fy += 42.0

## Posição x de cada cartão: os primeiros à esquerda, os outros à direita (o meio fica para o título).
func card_slots(n: int) -> Array:
	var l0 := 14.0
	var l1 := l0 + CARD_W + 10.0
	var r1 := 1920.0 - 14.0 - CARD_W
	var r0 := r1 - CARD_W - 10.0
	match n:
		1: return [l0]
		2: return [l0, r1]
		3: return [l0, l1, r1]
	return [l0, l1, r0, r1]

## Cartão compacto de um jogador (topo): retrato, nome, estrelas, vidas, % de dano e item.
## Fica translúcido quando um robô passa por trás dele.
func _card(i: int, r: Rect2) -> void:
	var S = main.S
	var p: Dictionary = main.players[i]
	var col: Color = Data.COLORS[p["color"]]
	var robot = main.robots[i] if i < main.robots.size() else null
	var out: bool = main.state == S.RUN and robot != null and not robot.alive
	var a := 1.0
	for rb in main.robots:
		if rb.alive and r.grow(26).has_point(main.to_screen(rb.position)):
			a = 0.35
	Kit.chunk(self, r, Color(Color("#b8aeb4") if out else col, a * 0.95), 18, 4, 4.0)
	_head(i, r.position + Vector2(31, r.size.y / 2.0), 24, Kit.INK, Kit.CREAM, "eliminado" if out else "normal", a)
	var tc := Color(1, 1, 1, a)
	var oc := Color(Kit.INK, a)
	var nm := ("P%d  %s" % [i + 1, pname(i)]) if pname(i) != "P%d" % (i + 1) else "P%d" % (i + 1)
	fit_text(Vector2(r.position.x + 62, r.position.y + 25), nm, 19, tc, 130, 5)
	var x2 := r.position.x + 68.0
	if main.mode == "demolicao":
		var goal := int(main.demo.cfg["rounds_to_win"])
		if main.demo.partida_unica():   # Derruba v2: estrelas = vitórias da sessão (sem meta)
			if int(p["score"]) > 0:
				Kit.star(self, Vector2(x2, r.position.y + 46), 15, true)
				Kit.text(self, Vector2(x2 + 10, r.position.y + 52), "%d" % int(p["score"]), 16, tc, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
				x2 += 34.0
			goal = 0
		elif goal > 10:   # metas enormes (testes): número em vez de estrelas
			Kit.star(self, Vector2(x2, r.position.y + 46), 15, true)
			Kit.text(self, Vector2(x2 + 10, r.position.y + 52), "%d" % int(p["score"]), 16, tc, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
			goal = 0
			x2 += 40.0
		for k in goal:
			var sc := Vector2(x2 + k * 15.0, r.position.y + 46)
			if k < int(p["score"]):
				Kit.star(self, sc, 15.0, true)
			else:
				draw_colored_polygon(_star_pts(sc, 15.0), Color(Kit.INK, 0.3 * a))
		x2 += goal * 15.0 + 6.0
		var d = main.demo
		if d.rule() == "derruba" and d.lives_setting > 1:
			var nl: int = int(d.lives.get(i, 0))
			for k in d.lives_setting:
				_heart(Vector2(x2 + 4 + k * 15.0, r.position.y + 47), 6.5, k < nl)
		if robot != null and robot.alive and not out:
			var dc: Color = main.dmg_color(robot.dmg)
			Kit.text(self, Vector2(r.position.x, r.position.y + 45), "%d%%" % int(robot.dmg), 32, Color(dc, a), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12, 8, oc)
		if robot != null and main.state == S.RUN and robot.alive:
			var info: Dictionary = main.demo.spells.hud_info(i) if main.demo.spells != null else {}
			if not info.is_empty():
				# slot da spell: ícone na cor da família + cargas (pontinhos) ou barra da transformação
				var hc := r.position + Vector2(50, r.size.y - 10)
				var fc: Color = main.demo.spells.FAM_COR[info["fam"]]
				var tex := Data.tex("spells/icone_" + info["fam"])
				var ch: int = info["charges"]
				var frac: float = info["frac"]
				_over_cmds.append(func(ci: CanvasItem):
					ci.draw_circle(hc, 17, Color(Kit.INK, a))
					ci.draw_circle(hc, 14.5, Color(fc, a))
					if frac < 1.0:
						ci.draw_arc(hc, 17.5, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, Color(1, 1, 1, a), 3.5, true)
					ci.draw_texture_rect(tex, Rect2(hc - Vector2(11, 11), Vector2(22, 22)), false, Color(1, 1, 1, a))
					for k in ch:
						var dp := hc + Vector2(24 + k * 10.0, 8)
						ci.draw_circle(dp, 4.6, Color(Kit.INK, a))
						ci.draw_circle(dp, 3.2, Color(fc.lightened(0.3), a)))
		if main.state in [S.RUN, S.SCORE]:
			_draw_sub_badge(i, r)
	if out:
		var cc := r.get_center()
		_over_cmds.append(func(ci: CanvasItem):
			ci.draw_set_transform(cc + Vector2(30, 0), -0.1)
			Kit.sticker(ci, Vector2(-100, 12), "FORA", 32, Color("#ff5a5a"), HORIZONTAL_ALIGNMENT_CENTER, 200)
			ci.draw_set_transform(Vector2.ZERO))

func _star_pts(c: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * size * (0.5 if k % 2 == 0 else 0.22))
	return pts

## Selo pequeno embaixo do cartão: segundos do rei, pavio da dinamite.
func _draw_sub_badge(i: int, r: Rect2) -> void:
	var d = main.demo
	match d.rule():
		"rei":
			var secs: float = float(d.king_time.get(i, 0.0))
			var b3 := Rect2(r.end.x - 130, r.end.y + 4, 120, 30)
			Kit.chunk(self, b3, Color("#ffe48a") if d.king == i else Kit.CREAM, 15, 3, 0.0)
			draw_texture_rect(Data.tex("itens/capacete"), Rect2(b3.position.x + 6, b3.position.y + 2, 26, 26), false, Color(1.0, 0.82, 0.25))
			Kit.text(self, Vector2(b3.position.x + 36, b3.position.y + 22), "%d/%d s" % [int(secs), int(d.king_goal())], 18, DARK)
		"batata":
			if d.bomb_holder == i:
				var b2 := Rect2(r.end.x - 110, r.end.y + 4, 100, 30)
				Kit.chunk(self, b2, Color("#ffd0c8"), 15, 3, 0.0)
				draw_texture_rect(Data.tex("itens/dinamite"), Rect2(b2.position.x + 8, b2.position.y + 3, 24, 24), false)
				Kit.text(self, Vector2(b2.position.x + 38, b2.position.y + 22), "%ds" % ceili(d.bomb_fuse), 20, Color("#d42035"))

func _heart(c: Vector2, s: float, full: bool) -> void:   # s = meia largura
	var pts := PackedVector2Array()
	for k in 33:
		var a := k * TAU / 32.0
		var hx := 16.0 * pow(sin(a), 3)
		var hy := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(c + Vector2(hx, hy) * s / 16.0)
	if full:
		draw_colored_polygon(pts, Color("#e5484d"))
	else:
		draw_colored_polygon(pts, Color(0.75, 0.72, 0.68, 0.6))
	draw_polyline(pts, Kit.INK, maxf(1.5, s * 0.22), true)

## Evento ativo (nome + barra de tempo), no canto de cima à esquerda.
func _draw_event_note() -> void:
	var ev = main.events
	var n: int = ev.active.size()
	for i in n:
		var a: Dictionary = ev.active[i]
		var r := Rect2(960 - 185 * n + i * 370 + 5, 58, 360, 44)
		var warn: bool = a["phase"] == "aviso"
		Kit.chunk(self, r, Color("#ffd0c8") if warn else Kit.CREAM, 18, 4, 3.0)
		var nm := String(a["e"].get("nome", "")).to_upper()
		fit_text(Vector2(r.position.x + 12, r.position.y + (30 if warn else 26)), ("EM BREVE: " if warn else "") + nm, 22, Color("#d42035") if warn else DARK, r.size.x - 24, 0, HORIZONTAL_ALIGNMENT_CENTER)
		if a["phase"] == "ativo":
			var k: float = clampf(a["t"] / maxf(a["len"], 0.01), 0.0, 1.0)
			draw_rect(Rect2(r.position.x + 20, r.position.y + 33, (r.size.x - 40) * k, 6), Color("#f2c84b"))

## Avisos de controle conectado/desconectado (canto de baixo, à esquerda).
func _draw_toasts() -> void:
	var y := 850.0   # canto de baixo à esquerda, subindo (não cobre títulos nem cartões)
	for i in range(PlayerInput.toasts.size() - 1, -1, -1):
		var tt: Dictionary = PlayerInput.toasts[i]
		var a := clampf((4.0 - float(tt["t"])) / 0.4, 0.0, 1.0)
		var slide := (1.0 - clampf(float(tt["t"]) / 0.18, 0.0, 1.0)) * -720.0
		var tw: float = Kit.font().get_string_size(String(tt["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var r := Rect2(24 + slide, y, tw + 110.0, 64)
		panel(r, Color(1, 1, 1, a) if tt["ok"] else Color(1, 0.86, 0.82, a))
		var dev: String = tt.get("dev", "")
		Kit.pad_btn(self, r.position + Vector2(44, 32), 18, "baixo", PlayerInput.pad_type(dev) if tt["ok"] else "generico")
		Kit.text(self, Vector2(r.position.x + 76, r.position.y + 42), String(tt["text"]), 26, Color(0.17, 0.29, 0.32, a) if tt["ok"] else Color(0.63, 0.08, 0.16, a))
		y -= 76.0

## Faixa de aviso que "salta" quando o texto muda.
func _ribbon_pop(txt: String, y: float, w: float, size: int, alpha := 1.0) -> void:
	if txt != _banner:
		_banner = txt
		_banner_age = 0.0
		if txt != "":
			Audio.play("locutor", 1.0, -6.0)   # "locutor" de bipes robóticos
	var k := clampf(_banner_age / 0.22, 0.0, 1.0)
	var s := lerpf(1.45, 1.0, 1.0 - pow(1.0 - k, 3.0))
	draw_set_transform(Vector2(960, y), sin(_banner_age * 3.0) * 0.01, Vector2(s, s))
	Kit.ribbon(self, Rect2(-w / 2.0, -64, w, 128), txt, size)
	draw_set_transform(Vector2.ZERO)

# ---------------------------------------------------------------- entrada
func _draw_join() -> void:
	var etapas: bool = main.selecao.ativo_para(main.arena_choice)
	if etapas:   # etapa 4 de 5 (A21): fundo de obra, placa e trilha
		Obra.fundo(self, t, 0.12)
		Obra.titulo(self, "QUEM VAI JOGAR?", "%s  ·  ETAPA 4 DE 5" % String(MapaReg.manifesto("derruba", main.arena_choice).get("nome", "")).to_upper())
		Obra.trilha(self, 3)
	else:
		draw_rect(Rect2(0, 0, 1920, 1080), DIM)
		_ribbon_pop("QUEM VAI JOGAR?", 100, 1200, 64)
	var W := 400.0
	var H := 600.0
	var gap := 36.0
	var x0 := (1920.0 - (4 * W + 3 * gap)) / 2.0
	var st: String = PlayerInput.main_pad_type()
	for i in 4:
		var r := Rect2(x0 + i * (W + gap), 262.0 if etapas else 196.0, W, H)
		var rot: float = [-0.026, 0.021, -0.017, 0.026][i]
		draw_set_transform(r.get_center(), rot)
		var lr := Rect2(-r.size / 2.0, r.size)
		if i < main.players.size():
			var p: Dictionary = main.players[i]
			var col: Color = Data.COLORS[p["color"]]
			Kit.chunk(self, lr, Kit.CREAM, 28)
			draw_circle(Vector2(0, -40), 150, Color("#ffe48a"))
			Kit.text(self, Vector2(lr.position.x, lr.position.y + 84), "P%d" % (i + 1), 76, col, HORIZONTAL_ALIGNMENT_CENTER, W, 15)
			var lab: String = PlayerInput.label(p["dev"])
			if p.get("bot", false):
				lab = "BOT · %s" % main.bots.LEVEL_NAMES[p.get("level", 1)]
			fit_text(Vector2(lr.position.x + 20, lr.position.y + 120), lab, 22, Kit.SOFT, W - 40, 0, HORIZONTAL_ALIGNMENT_CENTER)
			var nm: String = Data.MODEL_NAMES[p["model"]]
			Kit.text(self, Vector2(lr.position.x, lr.end.y - 104), nm, 42, DARK, HORIZONTAL_ALIGNMENT_CENTER, W)
			var skn: String = main.skin_nome(int(p["model"]), String(p.get("skin", "")))
			if main.skins_do_robo(int(p["model"])).size() > 1:   # há skin deste mapa para este robô
				Kit.text(self, Vector2(lr.position.x, lr.position.y + 166), ("✦ " + skn) if skn != "" else "visual padrão", 24, Color("#b85a1e") if skn != "" else Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, W)
			var pr := Rect2(lr.position.x + 30, lr.end.y - 82, W - 60, 58)
			Kit.chunk(self, pr, col, 20, 5, 0.0)
			Kit.text(self, Vector2(pr.position.x, pr.get_center().y + 10), "◄ cor ►   ▲▼ robô", 27, DARK, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
			draw_set_transform(Vector2.ZERO)
			RobotVis.draw_robot(self, _look(p), RobotVis.idle_pose(t + i * 0.77), Transform2D(rot, Vector2(2.6, 2.6), 0.0, r.get_center() + Vector2(0, 150)))
			draw_set_transform(Vector2.ZERO)
		else:
			Kit.chunk(self, lr, Color(Kit.CREAM, 0.55), 28)
			Kit.text(self, Vector2(lr.position.x, -40), "P%d" % (i + 1), 84, Color("#f2c84b"), HORIZONTAL_ALIGNMENT_CENTER, W, 16)
			draw_set_transform(Vector2.ZERO)
			Kit.pad_hint(self, r.get_center().x, r.get_center().y + 40, [["baixo"], " entrar"], 36, DARK, st)
			Kit.pad_hint(self, r.get_center().x, r.get_center().y + 104, [["cima"], " + bot"], 30, DARK, st)
			Kit.text(self, Vector2(r.position.x, r.get_center().y + 170), "teclado: Espaço / Ctrl dir.", 22, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_set_transform(Vector2.ZERO)
	if Input.get_connected_joypads().is_empty():
		Kit.sticker(self, Vector2(0, 950), "nenhum controle detectado  ·  OPÇÕES ▸ TESTAR CONTROLES", 26, Color("#ff8a8a"), HORIZONTAL_ALIGNMENT_CENTER, 1920)
	Kit.pad_hint(self, 960, 1030, [["baixo"], " entrar   ", "◄► cor   ▲▼ robô   ", ["esquerda"], " skin   ", ["cima"], " + bot   ", ["direita"], " sair   ", ["start"], " começar"], 30, Color.WHITE, st, 7)

# ---------------------------------------------------------------- corrida / rodada
func _draw_run() -> void:
	if main.mode == "demolicao" and main.demo.banner_t > 0.0:
		_ribbon_pop(main.demo.banner, 330, 1000, 62)
		if main.countdown > 0.0:
			var note := Rect2(360, 740, 1200, 116)
			panel(note)
			Kit.text(self, Vector2(note.position.x, note.position.y + 50), String(main.demo.arena.get("dica", "")), 34, DARK, HORIZONTAL_ALIGNMENT_CENTER, note.size.x)
			Kit.text(self, Vector2(note.position.x, note.position.y + 90), "GOLPE rápido  ·  MARRETADA pesada quebra  ·  ESQUIVA escapa  ·  ITEM usa", 24, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, note.size.x)
	if main.countdown > 0.0:
		var go: bool = main.countdown <= 0.6
		var s := "VAI!" if go else "PRONTOS?"
		var k := clampf((0.6 - main.countdown) / 0.15, 0.0, 1.0) if go else 1.0
		var sc := lerpf(1.6, 1.0, k)
		draw_set_transform(Vector2(960, 600), 0.0, Vector2(sc, sc))
		Kit.sticker(self, Vector2(-600, 40), s, 140, Color("#f2c84b") if go else Color("#4f86d9"), HORIZONTAL_ALIGNMENT_CENTER, 1200)
		draw_set_transform(Vector2.ZERO)

# ---------------------------------------------------------------- placar
func _draw_demo_score() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), DIM)
	_ribbon_pop(main.demo.banner, 96, 1400, 64)
	var goal := int(main.demo.cfg["rounds_to_win"])
	var order: Array = range(main.players.size())
	order.sort_custom(func(x, y): return int(main.players[x]["score"]) > int(main.players[y]["score"]) or (int(main.players[x]["score"]) == int(main.players[y]["score"]) and x < y))
	var n: int = order.size()
	var rowh := 140.0
	var y0 := 540.0 - (n * (rowh + 30.0)) / 2.0 + 40.0
	for k in n:
		var i: int = order[k]
		var p: Dictionary = main.players[i]
		var win: bool = i == main.demo.round_winner
		var r := Rect2(420, y0 + k * (rowh + 30.0), 1080, rowh)
		var rot: float = [-0.017, 0.017, -0.01, 0.014][k % 4]
		draw_set_transform(r.get_center(), rot)
		var lr := Rect2(-r.size / 2.0, r.size)
		Kit.chunk(self, lr, Color("#ffe48a") if win else Kit.CREAM, 28)
		Kit.text(self, Vector2(lr.position.x + 150, lr.position.y + 60), "P%d" % (i + 1), 38, Data.COLORS[p["color"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
		if pname(i) != "P%d" % (i + 1):
			fit_text(Vector2(lr.position.x + 150, lr.position.y + 106), pname(i), 34, DARK, 290)
		var sz := minf(66.0, 560.0 / goal)
		for s2 in mini(goal, 10):
			Kit.star(self, Vector2(lr.position.x + 490 + s2 * sz, 0), sz * 0.95, s2 < int(p["score"]))
		draw_set_transform(Vector2.ZERO)
		_head(i, r.position + Vector2(76, rowh / 2.0), 54, Kit.INK, Color.WHITE, "vitoria" if win else "normal")
		if win:
			var bc := r.position + Vector2(r.size.x + 10, 8)
			_over_cmds.append(func(ci: CanvasItem):
				Kit.burst(ci, bc, 64, t * 0.6, 6.0)
				Kit.text(ci, bc + Vector2(-80, 18), "+1", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 160, 12))

func _draw_score() -> void:
	_draw_demo_score()

# ---------------------------------------------------------------- vitória
func _draw_win() -> void:
	if main.demo.partida_unica():
		main.fim.draw(self)   # gangorra → Projetos → resultados (ui/fim.gd)
		return
	draw_rect(Rect2(0, 0, 1920, 1080), DIM)
	for k in 70:   # confete
		var x := fposmod(k * 137.0 + t * (40 + k % 7 * 15), 1920.0)
		var y := fposmod(k * 71.0 + t * (120 + k % 5 * 30), 1080.0)
		draw_set_transform(Vector2(x, y), t * (2.0 + k % 3) + k)
		draw_rect(Rect2(-9, -12, 18, 24), Kit.INK)
		draw_rect(Rect2(-7, -10, 14, 20), Data.COLORS[k % 4])
	draw_set_transform(Vector2.ZERO)
	var w: int = main.winner
	var pw: Dictionary = main.players[w]
	Kit.burst(self, Vector2(960, 640), 330, t * 0.15, 8.0)
	_ribbon_pop("%s VENCEU!" % pname(w).to_upper(), 100, 1600, 86)
	var goal := mini(int(main.demo.cfg["rounds_to_win"]), 10)
	var sw := 46.0 * goal
	var px := 960.0 - (90.0 + sw) / 2.0
	Kit.text(self, Vector2(px, 222), "P%d" % (w + 1), 44, Data.COLORS[pw["color"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	for k in goal:
		Kit.star(self, Vector2(px + 110 + k * 46, 206), 42, k < int(pw["score"]))
	RobotVis.draw_robot(self, _look(pw), RobotVis.victory_pose(t, int(Data.model_meta(pw["model"])["danca"])), Transform2D(0.0, Vector2(5.2, 5.2), 0.0, Vector2(960, 930)))
	draw_set_transform(Vector2.ZERO)
	if main.mode == "demolicao":
		_draw_titles()
	Kit.pad_hint(self, 960, 1040, [["baixo"], " jogar de novo      ", ["direita"], " menu"], 32, Color.WHITE, PlayerInput.main_pad_type(), 8)

## Títulos da partida (a partir das estatísticas), em cartões dos lados do vencedor.
func _draw_titles() -> void:
	var titles := [["MARRETEIRO", "derrubadas", "mais derrubou rivais", "derrubada"], ["DEMOLIDOR", "caixotes", "mais quebrou caixotes", "caixote"],
		["DESASTRADO", "quedas", "mais caiu sozinho", "queda"]]
	var spots := [Rect2(70, 330, 390, 236), Rect2(1460, 330, 390, 236), Rect2(1460, 610, 390, 236)]
	for k in titles.size():
		var tt: Array = titles[k]
		var best := -1
		var bv := 0
		for i in main.players.size():
			var v: int = int(main.players[i]["stats"][tt[1]])
			if v > bv:
				bv = v
				best = i
		var r: Rect2 = spots[k]
		var rot: float = [-0.035, 0.035, -0.026][k]
		draw_set_transform(r.get_center(), rot)
		var lr := Rect2(-r.size / 2.0, r.size)
		Kit.chunk(self, lr, Kit.CREAM, 26)
		Kit.text(self, Vector2(lr.position.x + 24, lr.position.y + 54), tt[0], 38, Kit.YEL, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
		Kit.text(self, Vector2(lr.position.x + 24, lr.position.y + 86), tt[2], 22, Kit.SOFT)
		if best >= 0:
			fit_text(Vector2(lr.position.x + 124, lr.position.y + 156), pname(best), 32, DARK, 240)
			Kit.text(self, Vector2(lr.position.x + 124, lr.position.y + 188), "%d %s%s" % [bv, tt[3], "" if bv == 1 else "s"], 22, Kit.SOFT)
		else:
			Kit.text(self, Vector2(lr.position.x + 24, lr.position.y + 170), "ninguém", 30, Kit.SOFT)
		draw_set_transform(Vector2.ZERO)
		if best >= 0:
			_head(best, r.get_center() + Vector2(-r.size.x / 2.0 + 64, 44).rotated(rot), 40, Kit.INK, Color.WHITE)
