extends RefCounted
## Kit visual da interface (estilo cartoon chapado): cartões gordinhos com contorno grosso e sombra dura,
## títulos com contorno, estrelas desenhadas, explosão de raios atrás do vencedor. Fonte Fredoka.
## Funções estáticas: todas as telas (menus, entrada, HUD, placar, vitória) usam este kit.

const INK := Color("#2a1a2e")         # contorno e sombra de tudo
const CREAM := Color("#fff6e4")       # fundo dos cartões
const YEL := Color("#ffd34d")         # destaque (selecionado, estrelas)
const SOFT := Color("#6b5a70")        # texto secundário sobre o creme
static var _font: Font = null
static var _flat := {}

static func font() -> Font:
	if _font == null:
		# carrega como recurso importado (é o que vai junto no jogo exportado; o arquivo .woff2 cru não vai)
		var path := "res://assets/fonts/fredoka-700.woff2"
		var f: FontFile = load(path) if ResourceLoader.exists(path) else null
		if f != null:
			f = f.duplicate()
			f.fallbacks = [ThemeDB.fallback_font]   # setas ◄►▲▼ e outros símbolos
			_font = f
		else:
			_font = ThemeDB.fallback_font
	return _font

static func _sb(fill: Color, radius: int, border: int, bcol: Color) -> StyleBoxFlat:
	var key := [fill, radius, border, bcol]   # desempenho: chave direta (antes montava texto com to_html a cada quadro)
	if not _flat.has(key):
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(radius)
		sb.set_border_width_all(border)
		sb.border_color = bcol
		sb.anti_aliasing = true
		sb.corner_detail = 10
		_flat[key] = sb
	return _flat[key]

## Cartão cartoon: preenchimento, contorno grosso e sombra dura embaixo.
static func chunk(ci: CanvasItem, r: Rect2, fill: Color, radius := 26, border := 6, shadow := 10.0) -> void:
	var ink := Color(INK, INK.a * fill.a)
	if shadow > 0.0:
		ci.draw_style_box(_sb(ink, radius, 0, ink), Rect2(r.position + Vector2(0, shadow), r.size))
	ci.draw_style_box(_sb(fill, radius, border, ink), r)

## Cartão creme (tint multiplica a cor; alfa do tint deixa translúcido).
static func paper(ci: CanvasItem, r: Rect2, tint := Color.WHITE) -> void:
	chunk(ci, r, Color(CREAM.r * tint.r, CREAM.g * tint.g, CREAM.b * tint.b, tint.a))

## Placa de destaque (amarela).
static func wood(ci: CanvasItem, r: Rect2) -> void:
	chunk(ci, r, YEL)

## Título grande: letras brancas com contorno grosso e sombra (sem faixa por trás), centrado em r.
static func ribbon(ci: CanvasItem, r: Rect2, txt: String, size := 56) -> void:
	title(ci, Vector2(r.position.x, r.get_center().y + size * 0.45), txt, int(size * 1.3), Color.WHITE, r.size.x)

static func title(ci: CanvasItem, pos: Vector2, s: String, size: int, col := Color.WHITE, w := 1920.0) -> void:
	var o := maxi(int(size * 0.17), 4)
	text(ci, pos + Vector2(0, size * 0.09), s, size, INK, HORIZONTAL_ALIGNMENT_CENTER, w, o, INK)
	text(ci, pos, s, size, col, HORIZONTAL_ALIGNMENT_CENTER, w, o, INK)

## Texto com contorno (escuro por padrão).
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, outline := 0, ocol := INK) -> void:
	var f := font()
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, w, size, outline, ocol)
	ci.draw_string(f, pos, s, align, w, size, col)

## Texto "adesivo": cor com contorno grosso escuro e sombra.
static func sticker(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER, w := -1.0) -> void:
	if col.get_luminance() < 0.35:
		col = Color(1, 1, 1, col.a)   # letra escura com contorno escuro some: vira clara
	var o := maxi(int(size * 0.2), 4)
	text(ci, pos + Vector2(0, size * 0.08), s, size, Color(INK, col.a), align, w, o, Color(INK, col.a))
	text(ci, pos, s, size, col, align, w, o, Color(INK, col.a))

## Texto que cabe em uma largura: quebra em até max_lines linhas e diminui a fonte se ainda não couber.
## pos = canto de cima à esquerda da área; centraliza cada linha em w.
static func text_box(ci: CanvasItem, pos: Vector2, w: float, s: String, size: int, col: Color, max_lines := 2, outline := 0) -> void:
	var f := font()
	var sz := size
	var lines: Array = []
	while sz >= 12:
		lines = _wrap(f, s, sz, w)
		if lines.size() <= max_lines:
			break
		sz -= 2
	var lh := sz * 1.15
	for k in lines.size():
		text(ci, Vector2(pos.x, pos.y + sz + k * lh), lines[k], sz, col, HORIZONTAL_ALIGNMENT_CENTER, w, outline)

static func _wrap(f: Font, s: String, sz: int, w: float) -> Array:
	var out: Array = []
	var cur := ""
	for word in s.split(" "):
		var cand := word if cur == "" else cur + " " + word
		if f.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x <= w or cur == "":
			cur = cand
		else:
			out.append(cur)
			cur = word
	if cur != "":
		out.append(cur)
	return out

## Estrela desenhada (cheia: amarela com contorno; vazia: sombra translúcida).
static func star(ci: CanvasItem, c: Vector2, size: float, filled: bool) -> void:
	if size < 3.0:
		return   # pequena demais: o polígono degenera (erro de triangulação a cada quadro)
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		var rr := size * (0.5 if k % 2 == 0 else 0.22)
		pts.append(c + Vector2.from_angle(a) * rr)
	if filled:
		ci.draw_colored_polygon(pts, YEL)
		pts.append(pts[0])
		ci.draw_polyline(pts, INK, maxf(2.0, size * 0.08), true)
	else:
		ci.draw_colored_polygon(pts, Color(INK, 0.28))

## Explosão de raios amarelos (atrás do vencedor e do "+1").
static func burst(ci: CanvasItem, c: Vector2, radius: float, spin := 0.0, border := 6.0) -> void:
	ci.draw_circle(c, radius + border, INK)
	ci.draw_circle(c, radius, Color("#ffe48a"))
	var n := 18
	for k in n:
		var a0 := spin + k * TAU / n
		ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * radius, c + Vector2.from_angle(a0 + TAU / n / 2.0) * radius]), YEL)

## Pílula (botão pequeno arredondado) com texto centrado.
static func pill(ci: CanvasItem, r: Rect2, fill: Color, s: String, size: int, col := INK) -> void:
	chunk(ci, r, fill, int(r.size.y / 2.0), 5, 0.0)
	text(ci, Vector2(r.position.x, r.get_center().y + size * 0.36), s, size, col, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

# ---------------------------------------------------------------- botões de controle
## Botão do controle desenhado (sem depender de fonte): pos = "baixo" | "direita" | "esquerda" | "cima"
## (posição física, igual em todos os controles) ou "start" / "lb" / "rb"; estilo = xbox | ps | nintendo | generico.
const PAD_LETTER := {"xbox": {"baixo": "A", "direita": "B", "esquerda": "X", "cima": "Y"},
	"generico": {"baixo": "A", "direita": "B", "esquerda": "X", "cima": "Y"},
	"nintendo": {"baixo": "B", "direita": "A", "esquerda": "Y", "cima": "X"}}
const PAD_COLOR := {"baixo": Color("#5cc45c"), "direita": Color("#e5484d"), "esquerda": Color("#4f86d9"), "cima": Color("#f2c84b")}
const PS_COLOR := {"baixo": Color("#8fb4f0"), "direita": Color("#ff7a8a"), "esquerda": Color("#f39ad9"), "cima": Color("#5fd6b0")}

static func pad_btn(ci: CanvasItem, c: Vector2, r: float, pos: String, style: String, lit := false) -> void:
	var dark := Color("#2f3640")
	var ob := maxf(2.0, r * 0.16)
	ci.draw_circle(c + Vector2(0, r * 0.18), r + ob, INK)
	if pos in ["start", "lb", "rb", "select"]:
		var w := r * 2.4
		var rr := Rect2(c - Vector2(w / 2.0, r * 0.75), Vector2(w, r * 1.5))
		chunk(ci, rr, Color("#f2c84b") if lit else dark, int(r * 0.4), int(ob), r * 0.18)
		var lab: String = {"start": "START", "select": "SELECT", "lb": "LB", "rb": "RB"}[pos]
		if style == "ps":
			lab = {"start": "OPTIONS", "select": "SHARE", "lb": "L1", "rb": "R1"}[pos]
		elif style == "nintendo":
			lab = {"start": "+", "select": "−", "lb": "L", "rb": "R"}[pos]
		text(ci, Vector2(rr.position.x, c.y + r * 0.32), lab, int(r * (0.62 if lab.length() > 3 else 0.9)), dark if lit else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
		return
	if style == "ps":
		ci.draw_circle(c, r + ob, INK)
		ci.draw_circle(c, r, Color("#f2c84b") if lit else dark)
		var col: Color = dark if lit else PS_COLOR[pos]
		var k := r * 0.48
		var wd := maxf(2.0, r * 0.2)
		match pos:
			"baixo":
				ci.draw_line(c + Vector2(-k, -k), c + Vector2(k, k), col, wd, true)
				ci.draw_line(c + Vector2(-k, k), c + Vector2(k, -k), col, wd, true)
			"direita":
				ci.draw_arc(c, k, 0, TAU, 24, col, wd, true)
			"esquerda":
				ci.draw_rect(Rect2(c - Vector2(k, k) * 0.9, Vector2(k, k) * 1.8), col, false, wd)
			"cima":
				ci.draw_polyline(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, k * 0.75), c + Vector2(-k, k * 0.75), c + Vector2(0, -k)]), col, wd, true)
		return
	var st: String = style if PAD_LETTER.has(style) else "xbox"
	var fill: Color = Color("#f2c84b") if lit else (dark if st == "nintendo" else PAD_COLOR[pos])
	ci.draw_circle(c, r + ob, INK)
	ci.draw_circle(c, r, fill)
	text(ci, Vector2(c.x - r, c.y + r * 0.36), PAD_LETTER[st][pos], int(r * 1.05), dark if lit else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)

## Linha de dica com botões: partes = ["texto", ["baixo"], "pula", ...]; centralizada em cx.
static func pad_hint(ci: CanvasItem, cx: float, y: float, parts: Array, size: int, col: Color, style: String, outline := 0) -> void:
	var f := font()
	var r := size * 0.62
	var w := 0.0
	for p in parts:
		w += (r * 2.0 + 8.0) if p is Array else f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := cx - w / 2.0
	for p in parts:
		if p is Array:
			var big: bool = p[0] in ["start", "lb", "rb", "select"]
			var bw := r * (2.4 if big else 2.0)
			pad_btn(ci, Vector2(x + bw / 2.0 + 4.0, y - size * 0.34), r, p[0], style)
			x += bw + 8.0
		else:
			text(ci, Vector2(x, y), p, size, col, HORIZONTAL_ALIGNMENT_LEFT, -1, outline)
			x += f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
