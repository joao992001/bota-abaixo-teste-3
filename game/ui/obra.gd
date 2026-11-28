extends RefCounted
## Kit de desenho da interface "CANTEIRO VIVO" (direção A, aprovada em 2026-11-26; pranchas art/out/menus_v2/).
## O menu acontece dentro da obra: fundo = camadas reais do Canteiro; títulos e botões = placas de obra penduradas;
## conteúdo = quadro de compensado; ajustes = pranchetas; trilha de ETAPAS OBRIGATÓRIAS no topo (A21).
const Kit := preload("res://ui/kit.gd")
const INK := Color("#2a1a2e")
const YEL := Color("#f2c84b")
const CREAM := Color("#fff6e4")
const CHAPA := Color("#e9e2d0")
const MADEIRA := Color("#d9a35f")
const MADEIRA_D := Color("#b57a3e")
const VERDE := Color("#5fc95f")
const CINZA := Color("#cfc8b8")
const ETAPAS := ["ENGENHOCAS", "EVENTOS", "VIDAS", "JOGADORES", "DETONAR"]

## Fundo: céu, cidade, grua e prédio do Canteiro (camadas da fase) + laje de concreto embaixo. t = tempo (nuvens).
static func fundo(ci: CanvasItem, t: float, escurece := 0.0) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color("#bfe9ef"))
	for n in ["fase1/e1_longe", "fase1/e1_perto"]:
		var tx: Texture2D = Data.tex(n)
		if tx != null:
			ci.draw_texture_rect(tx, Rect2(0, -20, 1920, 1056), false)
	for k in 3:   # nuvenzinhas andando
		var x := fposmod(k * 700.0 + t * (14.0 + k * 5.0), 2300.0) - 200.0
		var y := 90.0 + k * 70.0
		for c in [[0, 0, 46], [44, -16, 40], [86, 0, 38]]:
			ci.draw_circle(Vector2(x + c[0], y + c[1]), c[2], Color(1, 1, 1, 0.75))
	ci.draw_rect(Rect2(0, 1000, 1920, 80), Color("#b9ab8f"))
	ci.draw_rect(Rect2(0, 994, 1920, 12), Color("#e5dccb"))
	if escurece > 0.0:
		ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(INK, escurece))

static func corrente(ci: CanvasItem, x: float, y0: float, y1: float) -> void:
	var y := y0
	while y < y1:
		ci.draw_arc(Vector2(x, y + 7), 6.0, 0.0, TAU, 10, Color("#6b7783"), 3.0, true)
		y += 13.0

## Placa de obra pendurada (título ou botão). sel = amarela com fita zebrada; senão chapa creme.
static func placa(ci: CanvasItem, c: Vector2, w: float, h: float, txt: String, sel := false, rot := 0.0, size := 0, sub := "") -> void:
	ci.draw_set_transform(c, rot)
	var r := Rect2(-w / 2.0, 0, w, h)
	ci.draw_style_box(_sb(Color(INK, 0.35), 12), Rect2(r.position + Vector2(6, 10), r.size))
	ci.draw_style_box(_sb(YEL if sel else CHAPA, 12, 7), r)
	for bx in [r.position.x + 18, r.end.x - 18]:
		ci.draw_circle(Vector2(bx, 18), 6.0, Color("#8d98a4"))
	if sel:
		zebra(ci, Rect2(r.position.x + 12, h - 24, w - 24, 12))
	var sz := size if size > 0 else (44 if sel else 36)
	Kit.text(ci, Vector2(r.position.x, h / 2.0 + sz * 0.36 - (10 if sub != "" else 0)), txt, sz, INK, HORIZONTAL_ALIGNMENT_CENTER, w)
	if sub != "":
		Kit.text(ci, Vector2(r.position.x, h - 22), sub, 18, Kit.SOFT, HORIZONTAL_ALIGNMENT_CENTER, w)
	ci.draw_set_transform(Vector2.ZERO)

static func zebra(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, YEL)
	var x := r.position.x - r.size.y
	while x < r.end.x:
		var pts := PackedVector2Array([Vector2(x, r.end.y), Vector2(x + r.size.y, r.position.y), Vector2(x + r.size.y * 1.8, r.position.y), Vector2(x + r.size.y * 0.8, r.end.y)])
		for i in pts.size():
			pts[i].x = clampf(pts[i].x, r.position.x, r.end.x)
		ci.draw_colored_polygon(pts, INK)
		x += r.size.y * 2.0

## Título da tela: placa amarela pendurada por correntes + subtítulo (mapa · etapa).
static func titulo(ci: CanvasItem, txt: String, sub := "") -> void:
	corrente(ci, 700, -4, 26)
	corrente(ci, 1220, -4, 26)
	placa(ci, Vector2(960, 24), 660, 92, txt, true, 0.0, 48)
	if sub != "":
		Kit.text(ci, Vector2(0, 146), sub, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1920, 6)

## Trilha de ETAPAS OBRIGATÓRIAS (A21): feitas = verde com OK; atual = amarela; próximas = cinza com cadeado.
static func trilha(ci: CanvasItem, atual: int) -> void:
	var n := ETAPAS.size()
	var w := 300.0
	var gap := 40.0
	var x0 := (1920.0 - (n * w + (n - 1) * gap)) / 2.0
	ci.draw_rect(Rect2(x0 + 40, 186, n * w + (n - 1) * gap - 80, 10), Color("#8d98a4"))
	for k in n:
		var r := Rect2(x0 + k * (w + gap), 162, w, 56)
		var fill: Color = VERDE if k < atual else (YEL if k == atual else CINZA)
		ci.draw_style_box(_sb(Color(INK, 0.35), 14), Rect2(r.position + Vector2(5, 7), r.size))
		ci.draw_style_box(_sb(fill, 14, 5), r)
		var tc: Color = Color.WHITE if k < atual else (INK if k == atual else Kit.SOFT)
		Kit.text(ci, Vector2(r.position.x + 10, r.position.y + 38), "%d · %s" % [k + 1, ETAPAS[k]], 24, tc, HORIZONTAL_ALIGNMENT_CENTER, w - 10, 5 if k < atual else 0)
		if k < atual:   # carimbo OK
			var c := Vector2(r.end.x - 8, r.position.y + 12)
			ci.draw_circle(c, 22.0, Color.WHITE)
			ci.draw_arc(c, 22.0, 0, TAU, 24, Color("#2e7d32"), 4.0, true)
			Kit.text(ci, c + Vector2(-22, 7), "OK", 18, Color("#2e7d32"), HORIZONTAL_ALIGNMENT_CENTER, 44)
		elif k > atual:   # cadeado
			var lp := r.position + Vector2(22, 28)
			ci.draw_arc(lp + Vector2(0, -6), 8.0, PI, TAU, 10, INK, 4.0, true)
			ci.draw_style_box(_sb(Color("#8d98a4"), 4, 3), Rect2(lp + Vector2(-12, -6), Vector2(24, 20)))

## Quadro de compensado (onde fica o conteúdo de cada tela).
static func quadro(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_style_box(_sb(Color(INK, 0.35), 18), Rect2(r.position + Vector2(8, 14), r.size))
	ci.draw_style_box(_sb(MADEIRA, 16, 8), r)
	for k in int(r.size.x / 170.0):
		var x := r.position.x + 40.0 + k * 170.0
		ci.draw_line(Vector2(x, r.position.y + 12), Vector2(x - 12, r.end.y - 12), Color(MADEIRA_D, 0.35), 3.0)
	for p in [r.position + Vector2(26, 26), Vector2(r.end.x - 26, r.position.y + 26), Vector2(r.position.x + 26, r.end.y - 26), r.end - Vector2(26, 26)]:
		ci.draw_circle(p, 9.0, Color("#8d98a4"))
		ci.draw_line(p - Vector2(5, 0), p + Vector2(5, 0), INK, 3.0)

## Prancheta de obra: base de compensado, folha creme, prendedor e faixa colorida do título.
static func prancheta(ci: CanvasItem, r: Rect2, titulo_txt: String, cor: Color, sel := false) -> Rect2:
	if sel:
		ci.draw_style_box(_sb(YEL, 22, 6), r.grow(16))
	ci.draw_style_box(_sb(Color(INK, 0.35), 16), Rect2(r.position + Vector2(8, 12), r.size))
	ci.draw_style_box(_sb(MADEIRA_D, 14, 6), r)
	var folha := Rect2(r.position + Vector2(18, 30), r.size - Vector2(36, 48))
	ci.draw_style_box(_sb(CREAM, 6, 4), folha)
	ci.draw_rect(Rect2(folha.position + Vector2(2, 2), Vector2(folha.size.x - 4, 58)), cor)
	Kit.text(ci, Vector2(folha.position.x, folha.position.y + 44), titulo_txt, 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, folha.size.x, 6, INK)
	var cx := r.get_center().x
	ci.draw_style_box(_sb(Color("#9aa3ad"), 10, 5), Rect2(cx - 70, r.position.y - 10, 140, 40))
	ci.draw_style_box(_sb(Color("#c9d1d8"), 8, 4), Rect2(cx - 40, r.position.y - 24, 80, 22))
	return Rect2(folha.position + Vector2(0, 60), folha.size - Vector2(0, 60))

static func capacete(ci: CanvasItem, c: Vector2, s: float, aceso: bool) -> void:
	var col: Color = YEL if aceso else CINZA
	var pts := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		pts.append(c + Vector2(cos(a) * 40.0 * s, sin(a) * 44.0 * s))
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(pts, INK, 4.0, true)
	ci.draw_rect(Rect2(c + Vector2(-6 * s, -40 * s), Vector2(12 * s, 40 * s)), col.darkened(0.2))
	ci.draw_style_box(_sb(col, 7, 4), Rect2(c + Vector2(-52 * s, -6), Vector2(104 * s, 14)))

## Botão redondo de metal com seta (◄ ►).
static func seta(ci: CanvasItem, c: Vector2, d: int) -> void:
	ci.draw_circle(c, 27.0, INK)
	ci.draw_circle(c, 23.0, Color("#4a5060"))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9 * d, -15), c + Vector2(13 * d, 0), c + Vector2(-9 * d, 15)]), YEL)

## Detonador de TNT; k = 0 (alavanca em cima) … 1 (apertada).
static func detonador(ci: CanvasItem, c: Vector2, s: float, k := 0.0) -> void:
	var top := c.y - (130.0 - 90.0 * k) * s
	ci.draw_line(Vector2(c.x, top), Vector2(c.x, c.y - 20 * s), Color("#c9d1d8"), 20.0 * s)
	ci.draw_style_box(_sb(Color("#c9d1d8"), 14, 6), Rect2(c.x - 110 * s, top - 20 * s, 220 * s, 34 * s))
	var box := Rect2(c.x - 170 * s, c.y - 24 * s, 340 * s, 150 * s)
	ci.draw_style_box(_sb(Color("#d42035"), 16, 7), box)
	zebra(ci, Rect2(box.position.x + 15 * s, box.end.y - 40 * s, box.size.x - 30 * s, 26 * s))
	Kit.text(ci, Vector2(box.position.x, box.position.y + 86 * s), "TNT", int(70 * s), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	ci.draw_polyline(PackedVector2Array([Vector2(box.end.x, c.y + 60 * s), Vector2(box.end.x + 80 * s, c.y + 60 * s), Vector2(box.end.x + 60 * s, c.y - 120 * s), Vector2(box.end.x + 90 * s, c.y - 160 * s)]), Color("#2a2f3a"), 8.0 * s, true)

## Plaquinha de dicas no rodapé (na laje).
static func dica(ci: CanvasItem, txt: String) -> void:
	var w := maxf(800.0, txt.length() * 13.0 + 60.0)
	var r := Rect2(960 - w / 2.0, 1008, w, 56)
	ci.draw_style_box(_sb(CHAPA, 8, 4), r)
	Kit.text(ci, Vector2(r.position.x, r.position.y + 38), txt, 24, INK, HORIZONTAL_ALIGNMENT_CENTER, w)

## Chip do jogador (P1…) na cor dele.
static func chip(ci: CanvasItem, p: Vector2, n := 1) -> void:
	ci.draw_style_box(_sb(Data.COLORS[(n - 1) % 4], 12, 5), Rect2(p, Vector2(70, 44)))
	Kit.text(ci, p + Vector2(0, 33), "P%d" % n, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 70, 5, INK)

static var _sbs := {}
static func _sb(fill: Color, radius: int, border := 0) -> StyleBoxFlat:
	fill = Kit.cor_cache(fill)   # mesma regra do Kit: sem cor exata na chave (vazamento com transparência animada)
	var k := [fill.to_rgba32(), radius, border]
	if not _sbs.has(k):
		if _sbs.size() >= Kit.SB_MAX:
			_sbs.clear()
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(radius)
		sb.set_border_width_all(border)
		sb.border_color = INK
		sb.anti_aliasing = true
		_sbs[k] = sb
	return _sbs[k]
