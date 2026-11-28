extends RefCounted
## Ícones de botão e desenhos dos controles em papel e giz (art/src/ui/controles_export.py, prancha controles_v2).
## Modelos: ps5 (DualSense) · ps4 (DualShock 4) · xbox · switch (Pro) · gen (genérico).
## Glifos: baixo/dir/esq/cima (botões de ação por posição), lb rb lt rt, start select, ls rs, d (direcional),
## d-cima.. (direcional numa direção), l-cima.. / r-cima.. (analógico numa direção).

const DIR := "res://assets/ui/controles/"
static var _tex := {}
static var _lay := {}

static func _t(nome: String) -> Texture2D:
	if not _tex.has(nome):
		_tex[nome] = load(DIR + nome + ".png") if ResourceLoader.exists(DIR + nome + ".png") else null
	return _tex[nome]

static func layout() -> Dictionary:
	if _lay.is_empty():
		var f := FileAccess.open(DIR + "layout.json", FileAccess.READ)
		if f:
			_lay = JSON.parse_string(f.get_as_text())
	return _lay

static func _font() -> Font:
	return load("res://ui/kit.gd").font()

static func ok() -> bool:
	return _t("glifos_xbox") != null and not layout().is_empty()

## Ícone do botão. r = raio do botão na tela (o desenho tem 34 px de raio numa célula de 128).
static func glyph(ci: CanvasItem, c: Vector2, model: String, id: String, r: float, lit := false) -> void:
	var L := layout()
	var tex := _t("glifos_" + model)
	var i: int = L.get("glifos", []).find(id)
	if tex == null or i < 0:
		return
	if lit:
		ci.draw_circle(c, r * 1.42, Color("#2a1a2e"))
		ci.draw_circle(c, r * 1.3, Color("#f2c84b"))
	var cel := float(L["cel"])
	var cols := int(L["colunas"])
	var s := r / 34.0 * cel
	ci.draw_texture_rect_region(tex, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), Rect2((i % cols) * cel, (i / cols) * cel, cel, cel))

## Sinal do controle → glifo ("" se não houver desenho para ele).
static func spec_glyph(spec) -> String:
	if not (spec is Array) or spec.is_empty():
		return ""
	if spec[0] == "b":
		return {JOY_BUTTON_A: "baixo", JOY_BUTTON_B: "dir", JOY_BUTTON_X: "esq", JOY_BUTTON_Y: "cima", JOY_BUTTON_BACK: "select",
			JOY_BUTTON_START: "start", JOY_BUTTON_LEFT_STICK: "ls", JOY_BUTTON_RIGHT_STICK: "rs", JOY_BUTTON_LEFT_SHOULDER: "lb",
			JOY_BUTTON_RIGHT_SHOULDER: "rb", JOY_BUTTON_DPAD_UP: "d-cima", JOY_BUTTON_DPAD_DOWN: "d-baixo",
			JOY_BUTTON_DPAD_LEFT: "d-esq", JOY_BUTTON_DPAD_RIGHT: "d-dir"}.get(int(spec[1]), "")
	var ax := int(spec[1])
	var neg := float(spec[2]) < 0.0
	match ax:
		JOY_AXIS_LEFT_X: return "l-esq" if neg else "l-dir"
		JOY_AXIS_LEFT_Y: return "l-cima" if neg else "l-baixo"
		JOY_AXIS_RIGHT_X: return "r-esq" if neg else "r-dir"
		JOY_AXIS_RIGHT_Y: return "r-cima" if neg else "r-baixo"
		JOY_AXIS_TRIGGER_LEFT: return "lt"
		JOY_AXIS_TRIGGER_RIGHT: return "rt"
	return ""

## Ponto do desenho do controle que acende para o glifo (l-* = analógico esquerdo, r-* = direito).
static func lit_point(id: String) -> String:
	if id.begins_with("l-"):
		return "ls"
	if id.begins_with("r-"):
		return "rs"
	return id

## Nome curto da tecla (no layout do teclado do jogador: no ABNT2 a tecla ao lado do L aparece como Ç).
static func key_name(k) -> String:
	if k == null:
		return ""
	if k is String:
		return {"ctrl_r": "CTRL DIR.", "shift_l": "SHIFT ESQ."}.get(k, k)
	match int(k):
		KEY_SPACE: return "ESPAÇO"
		KEY_ESCAPE: return "ESC"
		KEY_ENTER: return "ENTER"
		KEY_KP_ENTER: return "ENTER N"
		KEY_BACKSPACE: return "⌫"
		KEY_TAB: return "TAB"
		KEY_DELETE: return "DEL"
		KEY_UP: return "▲"
		KEY_DOWN: return "▼"
		KEY_LEFT: return "◄"
		KEY_RIGHT: return "►"
	if int(k) >= KEY_KP_0 and int(k) <= KEY_KP_9:
		return "N%d" % (int(k) - KEY_KP_0)
	var lab := DisplayServer.keyboard_get_label_from_physical(int(k)) if DisplayServer.get_name() != "headless" else int(k)
	var t := OS.get_keycode_string(lab if lab != 0 else int(k))
	t = {"Semicolon": ";", "Comma": ",", "Period": ".", "Slash": "/", "Apostrophe": "'", "BracketLeft": "[", "BracketRight": "]",
		"Backslash": "\\", "Minus": "-", "Equal": "=", "QuoteLeft": "`"}.get(t, t)
	return t.to_upper().substr(0, 9)

## Tecla de papel com o nome escrito.
static func key(ci: CanvasItem, c: Vector2, k, r: float, lit := false) -> void:
	var nm := key_name(k)
	var larga := nm.length() > 2
	var tex := _t("tecla_larga" if larga else "tecla")
	var s := r / 34.0 * 128.0
	var sz := Vector2(s * (2.0 if larga else 1.0), s)
	if lit:
		var w := sz.x * (0.4 if larga else 0.36)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#f2c84b")
		sb.border_color = Color("#2a1a2e")
		sb.set_border_width_all(int(maxf(2.0, r * 0.08)))
		sb.set_corner_radius_all(int(r * 0.45))
		sb.draw(ci.get_canvas_item(), Rect2(c - Vector2(w, r * 1.05), Vector2(w * 2.0, r * 2.2)))
	if tex:
		ci.draw_texture_rect(tex, Rect2(c - sz / 2.0, sz), false)
	var fs := int(r * (0.8 if nm.length() <= 2 else (0.6 if nm.length() <= 5 else 0.5)))
	var f: Font = _font()
	var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(f, Vector2(c.x - tw / 2.0, c.y + fs * 0.3), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#2a1a2e"))

## Um mapeamento (sinal do controle ou tecla) desenhado no estilo do dispositivo; "—" se vazio.
static func bind(ci: CanvasItem, c: Vector2, dev: String, model: String, b, r: float, lit := false) -> void:
	var f: Font = _font()
	if b == null:
		var w := f.get_string_size("—", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.2)).x
		ci.draw_string(f, Vector2(c.x - w / 2.0, c.y + r * 0.4), "—", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.2), Color("#6b5a70"))
		return
	if not dev.begins_with("joy"):
		key(ci, c, b, r * 1.15, lit)
		return
	var id := spec_glyph(b)
	if id != "":
		glyph(ci, c, model, id, r, lit)
		return
	var t := ("B%d" % int(b[1])) if b[0] == "b" else ("EIXO %d%s" % [int(b[1]), "+" if float(b[2]) > 0 else "−"])
	var fs := int(r * 0.7)
	var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_circle(c, r, Color("#f2c84b") if lit else Color("#2f3238"))
	ci.draw_string(f, Vector2(c.x - tw / 2.0, c.y + fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)

## Desenho do controle (PNG 660×470) centrado em c, com anéis amarelos nos pontos de `lit` (ids do layout).
static func controller(ci: CanvasItem, c: Vector2, model: String, escala: float, lit: Array = [], pulse := 1.0) -> void:
	var tex := _t("controle_" + model)
	if tex == null:
		return
	var sz := tex.get_size() * escala
	var o := c - sz / 2.0
	ci.draw_texture_rect(tex, Rect2(o, sz), false)
	var pts: Dictionary = layout().get("modelos", {}).get(model, {})
	for id in lit:
		var p = pts.get(lit_point(id))
		if p == null:
			continue
		var pc := o + Vector2(p[0], p[1]) * escala
		var rr: float = float(p[2]) * escala * pulse
		ci.draw_arc(pc, rr + 7.0 * escala, 0, TAU, 32, Color("#2a1a2e"), 9.0 * escala, true)
		ci.draw_arc(pc, rr + 7.0 * escala, 0, TAU, 32, Color("#f2c84b"), 6.0 * escala, true)
