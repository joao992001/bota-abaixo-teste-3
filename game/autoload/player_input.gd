extends Node
## Entrada por jogador. O jogo pergunta sempre held/pressed(jogador, ação); nunca lê o dispositivo direto.
## Teclado A: WASD + Espaço (pular) + F/E (marreta). Teclado B: setas + Ctrl direito/Num0/L (pular) + . / Enter num./K (marreta).
## Sem Shift: no Windows, com NumLock ligado, as setas mandam um Shift "fantasma" (era a marreta sozinha).
## Teclas lidas por evento (_input), para separar Ctrl esquerdo/direito; "ctrl_r" = só o Ctrl direito.
## Controle (Xbox, PlayStation, Nintendo, genéricos — mapeamento SDL da Godot, por posição do botão):
##   analógico/direcional anda · botão de baixo (A / ✕) pula · esquerda (X / □), RB ou RT marreta ·
##   cima (Y / △), direita (B / ○), LB ou LT item · Start pausa/começa · B / ○ ou Select volta nos menus.
## Conectar/desconectar a qualquer hora: aviso na tela; se cair no meio da partida, o jogo pausa.

## hammer = golpe rápido · heavy = marretada pesada · dodge = esquiva
## Teclado (2026-11-28, prancha controles_v2): andar e PULAR em mãos diferentes, nada de Shift/Ctrl.
##   A: WASD anda · G pula (ou Espaço) · H golpe · J marretada · Y esquiva · U especial · Enter/Esc pausa.
##   B: setas · numérico 1 pula · 2 golpe · 3 marretada · 4 esquiva · 5 especial · Enter do numérico pausa;
##      sem numérico (notebook): K pula · L golpe · Ç marretada · O esquiva · P especial.
## Cada ação tem PRINCIPAL e ALTERNATIVO; cada controle/lado do teclado pode ser remapeado (só ele) em OPÇÕES ▸ CONTROLES.
const ACTIONS := ["left", "right", "up", "down", "jump", "hammer", "heavy", "dodge", "item", "start", "back",
	"nav_left", "nav_right", "nav_up", "nav_down"]
const MAP_ACTIONS := ["left", "right", "up", "down", "jump", "hammer", "heavy", "dodge", "item", "start"]
const KEYMAP := {
	"kb_a": {"left": [KEY_A, null], "right": [KEY_D, null], "up": [KEY_W, null], "down": [KEY_S, null],
		"jump": [KEY_G, KEY_SPACE], "hammer": [KEY_H, null], "heavy": [KEY_J, null], "dodge": [KEY_Y, null], "item": [KEY_U, null],
		"start": [KEY_ENTER, null], "back": [KEY_ESCAPE, KEY_BACKSPACE]},
	"kb_b": {"left": [KEY_LEFT, null], "right": [KEY_RIGHT, null], "up": [KEY_UP, null], "down": [KEY_DOWN, null],
		"jump": [KEY_KP_1, KEY_K], "hammer": [KEY_KP_2, KEY_L], "heavy": [KEY_KP_3, KEY_SEMICOLON], "dodge": [KEY_KP_4, KEY_O], "item": [KEY_KP_5, KEY_P],
		"start": [KEY_KP_ENTER, null], "back": [KEY_DELETE, null]},
}
## Controle (posições SDL): ["b", botão] ou ["a", eixo, sinal]. Direções: analógico esquerdo + direcional.
const PAD_DEFAULT := {
	"left": [["a", JOY_AXIS_LEFT_X, -1], ["b", JOY_BUTTON_DPAD_LEFT]], "right": [["a", JOY_AXIS_LEFT_X, 1], ["b", JOY_BUTTON_DPAD_RIGHT]],
	"up": [["a", JOY_AXIS_LEFT_Y, -1], ["b", JOY_BUTTON_DPAD_UP]], "down": [["a", JOY_AXIS_LEFT_Y, 1], ["b", JOY_BUTTON_DPAD_DOWN]],
	"jump": [["b", JOY_BUTTON_A], null], "hammer": [["b", JOY_BUTTON_X], null], "heavy": [["b", JOY_BUTTON_Y], null],
	"dodge": [["b", JOY_BUTTON_RIGHT_SHOULDER], ["a", JOY_AXIS_TRIGGER_RIGHT, 1]], "item": [["b", JOY_BUTTON_LEFT_SHOULDER], ["a", JOY_AXIS_TRIGGER_LEFT, 1]],
	"start": [["b", JOY_BUTTON_START], null],
}
const DIRS := ["left", "right", "up", "down"]

var slots: Array = []   # dispositivo de cada jogador (índice = jogador)
var virtual := {}       # dispositivos simulados (testes): nome -> {ação: bool}
var _cur := {}
var _prev := {}
var jump_frame := {}    # dispositivo -> quadro de física em que PULAR foi apertado
var aliases := {}       # dispositivo "gêmeo" ignorado -> dispositivo real (mesmo controle visto 2x no Windows)
const TWIN_FRAMES := 2
var _jb := {}           # controle -> {botão: apertado}, pelos eventos (além da leitura direta)
var _ja := {}           # controle -> {eixo: valor}, pelos eventos
var last_raw := {}      # controle -> último botão/eixo cru recebido (tela TESTAR CONTROLES)
var custom := {}        # mapeamento de cada dispositivo: chave (pad_key / "kb_a") -> {ação: [principal, alternativo]}
const CUSTOM_PATH := "user://controles.cfg"
var toasts: Array = []  # avisos de controle conectado/desconectado: {text, t, ok}
var vibration := true   # OPÇÕES: vibração dos controles
signal pad_changed(dev: String, connected: bool)

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy)
	load_custom()

## Mapeamentos por dispositivo. Chave de controle = GUID#n (n = ordem entre controles IGUAIS conectados), então
## mapear um DualSense não muda o outro DualSense. Seções antigas (só GUID, valendo para todos do modelo) ainda são lidas.
func load_custom() -> void:
	custom.clear()
	var cf := ConfigFile.new()
	if cf.load(CUSTOM_PATH) != OK:
		return
	for key in cf.get_sections():
		var m := {}
		for a in cf.get_section_keys(key):
			var v = cf.get_value(key, a)
			if v is Array and v.size() == 3 and v[0] is String:
				v = [_spec_norm(v), null]   # formato antigo: um sinal só
			m[a] = v
		custom[key] = m

func save_custom(key: String, m: Dictionary) -> void:
	var cf := ConfigFile.new()
	cf.load(CUSTOM_PATH)
	if cf.has_section(key):
		cf.erase_section(key)
	if m.is_empty():
		custom.erase(key)
	else:
		custom[key] = m
		for a in m:
			cf.set_value(key, a, m[a])
	cf.save(CUSTOM_PATH)

static func _spec_norm(v: Array) -> Array:
	return ["b", int(v[1])] if v[0] == "b" else ["a", int(v[1]), int(signf(float(v[2])))]

## Chave do mapeamento deste dispositivo.
func dev_key(dev: String) -> String:
	if dev.begins_with("joy"):
		return pad_key(int(dev.substr(3)))
	return dev

## GUID / nome / info só de controles conectados de verdade (os de mentira dos testes respondem "fake").
func joy_guid(j: int) -> String:
	return Input.get_joy_guid(j) if Input.get_connected_joypads().has(j) else "fake"

func joy_name(j: int) -> String:
	return Input.get_joy_name(j) if Input.get_connected_joypads().has(j) else ""

func joy_info(j: int) -> Dictionary:
	return Input.get_joy_info(j) if Input.get_connected_joypads().has(j) else {}

func pad_key(j: int) -> String:
	var g := joy_guid(j)
	var n := 1
	for o in _joys():
		if o < j and joy_guid(o) == g:
			n += 1
	return "%s#%d" % [g, n]

func _joys() -> Array:
	var js: Array = Input.get_connected_joypads().duplicate()
	for j in fake_joys:
		if not j in js:
			js.append(j)
	js.sort()
	return js

## Padrão de fábrica do dispositivo: {ação: [principal, alternativo]}.
func default_map(dev: String) -> Dictionary:
	var src: Dictionary = KEYMAP[dev] if KEYMAP.has(dev) else PAD_DEFAULT
	var m := {}
	for a in MAP_ACTIONS:
		m[a] = src[a].duplicate(true)
	return m

## Mapeamento em uso (o salvo deste dispositivo; senão o antigo do modelo; senão o padrão), completo.
func current_map(dev: String) -> Dictionary:
	var m := default_map(dev)
	var cm: Dictionary = custom.get(dev_key(dev), {})
	if cm.is_empty() and dev.begins_with("joy"):
		cm = custom.get(joy_guid(int(dev.substr(3))), {})
	for a in cm:
		if m.has(a) and cm[a] is Array and cm[a].size() == 2:
			m[a] = cm[a].duplicate(true)
	return m

func has_custom(dev: String) -> bool:
	if custom.has(dev_key(dev)):
		return true
	return dev.begins_with("joy") and custom.has(joy_guid(int(dev.substr(3))))

func _custom_on(j: int, spec) -> bool:
	if not (spec is Array) or spec.is_empty():
		return false
	if spec[0] == "b":
		return jbtn(j, int(spec[1]))
	var lim := 0.45 if int(spec[1]) <= JOY_AXIS_RIGHT_Y else 0.5
	return jaxis(j, int(spec[1])) * float(spec[2]) > lim

## Sinais crus que estão chegando agora deste controle (diagnóstico): botões e eixos, pela leitura direta e por evento.
func raw_now(j: int) -> String:
	var bs := []
	for b in 32:
		if jbtn(j, b):
			bs.append(str(b))
	var ax := []
	for a in 10:
		var v := jaxis(j, a)
		if absf(v) > 0.3:
			ax.append("%d:%+.1f" % [a, v])
	return "botões [%s]  eixos [%s]" % [", ".join(bs), ", ".join(ax)]

## CONTROLE PRINCIPAL (pedido 2026-11-28): o 1º controle conectado (ainda ligado) é o único CONTROLE que mexe nos menus
## e configurações; o teclado do PC e os dispositivos virtuais dos testes também mexem. Saiu o principal → o próximo assume.
var ordem_con: Array = []      # controles ("joyN") na ordem em que conectaram
var _princ := ""
var _princ_f := -1

func principal() -> String:
	var f := Engine.get_physics_frames()
	if f == _princ_f:
		return _princ
	_princ_f = f
	var js := _joys()
	var i := ordem_con.size() - 1
	while i >= 0:
		if not int(String(ordem_con[i]).substr(3)) in js:
			ordem_con.remove_at(i)
		i -= 1
	for j in js:
		var d := "joy%d" % j
		if not d in ordem_con:
			ordem_con.append(d)
	_princ = ordem_con[0] if not ordem_con.is_empty() else ""
	return _princ

## Este dispositivo pode mexer nos menus? (dono = aparelho que assumiu agora, ex.: o controle sendo configurado)
func manda_no_menu(dev: String, dono := "") -> bool:
	if dev.begins_with("bot") or dev.begins_with("boneco"):
		return false
	if is_keyboard(dev) or virtual.has(dev):
		return true
	if dono != "":
		return dev == dono
	return dev == principal()

func _on_joy(j: int, connected: bool) -> void:
	var dev := "joy%d" % j
	if connected and not dev in ordem_con:
		ordem_con.append(dev)
	elif not connected:
		ordem_con.erase(dev)
	_princ_f = -1
	_log_pad(j, connected)
	var nm := pad_name(dev) if connected else "controle %d" % (j + 1)
	toasts.append({"text": ("Conectado: %s" if connected else "Desconectado: %s") % nm, "t": 0.0, "ok": connected, "dev": dev})
	if not connected:
		_cur.erase(dev)
		_prev.erase(dev)
		aliases.erase(dev)
		_jb.erase(j)
		_ja.erase(j)
	pad_changed.emit(dev, connected)

func _process(dt: float) -> void:
	for tt in toasts:
		tt["t"] += dt
	toasts = toasts.filter(func(tt): return tt["t"] < 4.0)

## Nome amigável do controle: o MODELO reconhecido (ex.: "DualSense"); se não reconhecer, o nome que o sistema informa.
func pad_name(dev: String) -> String:
	if not dev.begins_with("joy"):
		return label(dev)
	var j := int(dev.substr(3))
	var m := pad_model(dev)
	if m != "gen":
		return model_title(dev)
	var nm := joy_name(j).strip_edges()
	return nm.substr(0, 30) if nm != "" else "controle %d" % (j + 1)

## Nome do modelo com a geração quando o produto diz (Xbox Series / One / 360; Switch Pro).
func model_title(dev: String) -> String:
	var m := pad_model(dev)
	if m == "xbox" and not fake_models.has(int(dev.substr(3))):
		var p: int = joy_ids(int(dev.substr(3)))[1]
		if p in [0x0b12, 0x0b13, 0x0b20, 0x0b21, 0x0b22]:
			return "Xbox Series"
		if p in [0x02d1, 0x02dd, 0x02e0, 0x02ea, 0x02fd, 0x0b00, 0x0b05]:
			return "Xbox One"
		if p in [0x028e, 0x028f, 0x0291, 0x0719]:
			return "Xbox 360"
	return MODEL_NAMES.get(m, "Controle")

const MODEL_NAMES := {"ps5": "DualSense", "ps4": "DualShock 4", "xbox": "Xbox", "switch": "Switch Pro", "gen": "Controle genérico"}
const MODEL_FAMILY := {"ps5": "PlayStation 5", "ps4": "PlayStation 4", "xbox": "Xbox", "switch": "Nintendo Switch", "gen": "botões como Xbox"}

## Modelo do controle: ps5 / ps4 / xbox / switch / gen — pelo fabricante e produto (USB/Bluetooth) e, na falta, pelo nome.
## Muda os desenhos (controle e ícones); a posição dos botões é a mesma (mapeamento SDL).
func pad_model(dev: String) -> String:
	if not dev.begins_with("joy"):
		return ""
	var j := int(dev.substr(3))
	if fake_models.has(j):
		return fake_models[j]
	var ids := joy_ids(j)
	return model_from(ids[0], ids[1], joy_name(j))

var fake_models := {}   # testes/capturas: controle de mentira -> modelo

## [fabricante, produto] do controle: das informações do sistema ou, se faltar, de dentro do GUID SDL.
func joy_ids(j: int) -> Array:
	var info: Dictionary = joy_info(j)
	var v := _num(info.get("vendor_id", 0))
	var p := _num(info.get("product_id", 0))
	if v == 0:
		var g := joy_guid(j)
		if g.length() >= 20:
			v = ("0x" + g.substr(10, 2) + g.substr(8, 2)).hex_to_int()
			p = ("0x" + g.substr(18, 2) + g.substr(16, 2)).hex_to_int()
	return [v, p]

static func _num(x) -> int:
	if x is int:
		return x
	var t := str(x).strip_edges()
	return t.hex_to_int() if t.begins_with("0x") else t.to_int()

static func model_from(vendor: int, product: int, nm: String) -> String:
	match vendor:
		0x054c:
			return "ps5" if product in [0x0ce6, 0x0df2] else "ps4"
		0x045e:
			return "xbox"
		0x057e:
			return "switch"
	var n := nm.to_lower()
	for k in ["dualsense", "ps5"]:
		if k in n:
			return "ps5"
	match type_from_name(nm):
		"ps": return "ps4"
		"xbox": return "xbox"
		"nintendo": return "switch"
	return "gen"

## Família antiga (ps / xbox / nintendo / generico) — usada pelos desenhos simples dos botões.
func pad_type(dev: String) -> String:
	if not dev.begins_with("joy"):
		return ""
	return {"ps5": "ps", "ps4": "ps", "xbox": "xbox", "switch": "nintendo"}.get(pad_model(dev), "generico")

static func type_from_name(nm: String) -> String:
	var n := nm.to_lower().strip_edges()
	for k in ["xbox", "xinput", "x-box", "microsoft"]:
		if k in n:
			return "xbox"
	if n == "wireless controller":
		return "ps"   # DualShock 4 no Windows aparece só assim
	for k in ["dualsense", "dualshock", "ps5", "ps4", "ps3", "playstation", "sony"]:
		if k in n:
			return "ps"
	for k in ["nintendo", "switch", "pro controller", "joy-con", "joycon"]:
		if k in n:
			return "nintendo"
	return "generico"

## Família que aparece nas dicas gerais da tela: a do primeiro controle conectado (Xbox se não houver).
func main_pad_type() -> String:
	for j in Input.get_connected_joypads():
		return pad_type("joy%d" % j)
	return "xbox"

func main_pad_model() -> String:
	for j in Input.get_connected_joypads():
		return pad_model("joy%d" % j)
	return "xbox"

## Conexão (para o cartão do controle), quando o sistema informa.
func pad_conexao(dev: String) -> String:
	if not dev.begins_with("joy"):
		return ""
	var nm := joy_name(int(dev.substr(3))).to_lower()
	var info: Dictionary = joy_info(int(dev.substr(3)))
	if "bluetooth" in str(info).to_lower() or "wireless" in nm:
		return "sem fio"
	return ""

## Vibra o controle do jogador (se for controle e a opção estiver ligada).
func vibrate(p: int, weak: float, strong: float, dur: float) -> void:
	if not vibration or p < 0 or p >= slots.size():
		return
	var dev: String = slots[p]
	if dev.begins_with("joy"):
		Input.start_joy_vibration(int(dev.substr(3)), clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), dur)

func _physics_process(_dt: float) -> void:
	for dev in all_devices():
		_prev[dev] = _cur.get(dev, {})
		_cur[dev] = _read(dev)
		if dev_pressed(dev, "jump"):
			jump_frame[dev] = Engine.get_physics_frames()

var fake_joys: Array = []   # testes: controles "conectados" de mentira (recebem eventos de verdade)

func all_devices() -> Array:
	var list: Array = ["kb_a", "kb_b"]
	for j in _joys():
		list.append("joy%d" % j)
	list.append_array(virtual.keys())
	return list

func _read(dev: String) -> Dictionary:
	var s := {}
	if virtual.has(dev):
		for a in ACTIONS:
			s[a] = bool(virtual[dev].get(a, false))
		for d in DIRS:
			s["nav_" + d] = s[d] or s["nav_" + d]
		return s
	var m := current_map(dev)
	if KEYMAP.has(dev):
		for a in MAP_ACTIONS:
			s[a] = key_down(m[a][0]) or key_down(m[a][1])
		s["back"] = key_down(KEYMAP[dev]["back"][0]) or key_down(KEYMAP[dev]["back"][1])
		for d in DIRS:   # menus: as teclas de fábrica sempre navegam (ninguém fica preso)
			s["nav_" + d] = s[d] or key_down(KEYMAP[dev][d][0])
	elif dev.begins_with("joy"):
		var j := int(dev.substr(3))
		var usa_b := false
		for a in MAP_ACTIONS:
			s[a] = _custom_on(j, m[a][0]) or _custom_on(j, m[a][1])
			usa_b = usa_b or m[a].has(["b", JOY_BUTTON_B])
		# VOLTAR nos menus: Select/View, e o B/○ se ele não tiver virado outra ação no mapeamento
		s["back"] = jbtn(j, JOY_BUTTON_BACK) or (jbtn(j, JOY_BUTTON_B) and not usa_b)
		for d in DIRS:   # menus: analógico esquerdo e direcional sempre navegam
			s["nav_" + d] = s[d] or _custom_on(j, PAD_DEFAULT[d][0]) or _custom_on(j, PAD_DEFAULT[d][1])
	return s

## Teclas/ botões recém-apertados (tela MAPEAR "aperte o novo botão"): o último evento de tecla.
var key_hits: Array = []   # [código físico] apertados desde a última leitura

var _keys := {}   # "tecla:posição" -> apertada (posição separa Ctrl/Shift esquerdo e direito)

## Botão do controle: leitura direta OU o último evento recebido (qualquer um dos dois basta).
func jbtn(j: int, b: int) -> bool:
	return Input.is_joy_button_pressed(j, b) or bool(_jb.get(j, {}).get(b, false))

func jaxis(j: int, a: int) -> float:
	var p := Input.get_joy_axis(j, a)
	var ev: float = _ja.get(j, {}).get(a, 0.0)
	return p if absf(p) >= absf(ev) else ev

## Relatório para diagnóstico (user://controles.txt): nome, GUID, se a Godot reconhece o mapeamento.
func _log_pad(j: int, connected: bool) -> void:
	var f := FileAccess.open("user://controles.txt", FileAccess.READ_WRITE if FileAccess.file_exists("user://controles.txt") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("%s  controle %d %s  nome=\"%s\"  guid=%s  reconhecido=%s  info=%s" % [Time.get_datetime_string_from_system(), j,
		"CONECTOU" if connected else "DESCONECTOU", Input.get_joy_name(j), Input.get_joy_guid(j), Input.is_joy_known(j), str(Input.get_joy_info(j))])
	f.close()

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton:
		if not _jb.has(e.device):
			_jb[e.device] = {}
		_jb[e.device][e.button_index] = e.pressed
		if e.pressed:
			last_raw[e.device] = "botão %d" % e.button_index
	elif e is InputEventJoypadMotion:
		if not _ja.has(e.device):
			_ja[e.device] = {}
		_ja[e.device][e.axis] = e.axis_value if absf(e.axis_value) > 0.2 else 0.0
		if absf(e.axis_value) > 0.5:
			last_raw[e.device] = "eixo %d: %+.2f" % [e.axis, e.axis_value]
	if e is InputEventKey and not e.echo:
		var k: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
		_keys["%d:%d" % [k, e.location]] = e.pressed
		if e.pressed:
			key_hits.append(k)
			if key_hits.size() > 8:
				key_hits.pop_front()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_keys.clear()   # janela perdeu o foco: nenhuma tecla fica "presa"

func key_down(k) -> bool:
	if k == null:
		return false
	if k is String:
		match k:
			"ctrl_r": return _keys.get("%d:%d" % [KEY_CTRL, KEY_LOCATION_RIGHT], false)
			"shift_l": return _keys.get("%d:%d" % [KEY_SHIFT, KEY_LOCATION_LEFT], false)
		return false
	for loc in [KEY_LOCATION_UNSPECIFIED, KEY_LOCATION_LEFT, KEY_LOCATION_RIGHT]:
		if _keys.get("%d:%d" % [k, loc], false):
			return true
	return false

func is_keyboard(dev: String) -> bool:
	return KEYMAP.has(dev)

## Outro controle já em uso que apertou PULAR no mesmo instante (é o mesmo controle físico aparecendo 2x).
func twin_of(dev: String) -> String:
	if is_keyboard(dev) or not jump_frame.has(dev):
		return ""
	for other in slots:
		if other != dev and not is_keyboard(other) and jump_frame.has(other):
			if absi(int(jump_frame[other]) - int(jump_frame[dev])) <= TWIN_FRAMES:
				return other
	return ""

func label(dev: String) -> String:
	match dev:
		"kb_a": return "teclado A"
		"kb_b": return "teclado B"
	if dev.begins_with("bot"):
		return "BOT"
	if dev.begins_with("boneco"):
		return "BONECO DE TREINO"
	if dev.begins_with("joy"):
		return "controle %d: %s" % [int(dev.substr(3)) + 1, pad_name(dev)]
	if dev.begins_with("v"):
		return "controle virtual"
	return dev

func dev_held(dev: String, a: String) -> bool:
	return _cur.get(dev, {}).get(a, false)

func dev_pressed(dev: String, a: String) -> bool:
	return dev_held(dev, a) and not _prev.get(dev, {}).get(a, false)

func held(p: int, a: String) -> bool:
	if p >= slots.size():
		return false
	if dev_held(slots[p], a):
		return true
	for tw in aliases:
		if aliases[tw] == slots[p] and dev_held(tw, a):
			return true
	return false

func pressed(p: int, a: String) -> bool:
	if p >= slots.size():
		return false
	if dev_pressed(slots[p], a):
		return true
	for tw in aliases:
		if aliases[tw] == slots[p] and dev_pressed(tw, a):
			return true
	return false

## Controle que a Godot reconhece (mapeamento conhecido) — preferido quando o Windows mostra o mesmo controle 2x.
func is_known(dev: String) -> bool:
	return dev.begins_with("joy") and Input.is_joy_known(int(dev.substr(3)))

func axis_x(p: int) -> float:
	return float(held(p, "right")) - float(held(p, "left"))
