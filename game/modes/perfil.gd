extends RefCounted
## PERFIL SALVO LOCAL do Derruba v2 (D4). Contrato: docs/manuais/derruba/perfil_salvo.md (esquema v1).
## user://perfil.json, escrita segura (.tmp → renomeia; anterior vira .bak); JSON quebrado → .bak → perfil novo (o
## quebrado vira .corrompido). Sem contas/rede (CLAUDE.md). Estrelas NÃO ficam aqui (placar da sessão, A13).
## Gangorra (progressao.md §1, A17): anda pela cor do manômetro em que a partida terminou; partida válida = vencedor e
## luta ≥ 1 min. Projetos de Demolição (§2): +1 por partida válida, +2 por cena inédita (uma vez).

const VERSAO := 1
const CATEGORIAS := ["skin", "spell", "evento"]

var caminho := "user://perfil.json"
var dados: Dictionary = {}
var rng := RandomNumberGenerator.new()

func novo() -> Dictionary:
	var cat := _sorteia_extremos()
	return {"versao": VERSAO, "criado": Time.get_datetime_string_from_system(true) + "Z",
		"gangorra": {"valor": 0, "extremo_verde": cat[0], "extremo_vermelho": cat[1]},
		"desbloqueados": {"mapas": ["*"], "spells": ["*"], "eventos": ["*"], "skins": ["*"]},
		"novos": [], "premios": [], "cenas_visitadas": {}, "pontos_exploracao": 0,
		"ultima_config": {}, "estatisticas": {"partidas": 0, "partidas_validas": 0}}

func _sorteia_extremos() -> Array:
	var c := CATEGORIAS.duplicate()
	var a: String = c[rng.randi_range(0, c.size() - 1)]
	c.erase(a)
	return [a, c[rng.randi_range(0, c.size() - 1)]]

func carregar() -> void:
	var d = _ler(caminho)
	if d == null and FileAccess.file_exists(caminho):
		DirAccess.rename_absolute(caminho, caminho + ".corrompido")   # nunca apaga sem guardar
		d = _ler(caminho + ".bak")
	dados = migrar(d) if d is Dictionary else novo()

func _ler(p: String):
	if not FileAccess.file_exists(p):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if d is Dictionary and d.has("versao") else null

## Migração de versões antigas para a atual (uma etapa por versão). v0 = antes do campo "versao".
func migrar(d: Dictionary) -> Dictionary:
	var base := novo()
	if int(d.get("versao", 0)) < 1:
		d["versao"] = 1
	for k in base:   # campos que faltam ganham o padrão
		if not d.has(k):
			d[k] = base[k]
	return d

func salvar() -> void:
	var tmp := caminho + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Perfil: não consegui gravar " + tmp)
		return
	f.store_string(JSON.stringify(dados, " "))
	f.close()
	if FileAccess.file_exists(caminho):
		if FileAccess.file_exists(caminho + ".bak"):
			DirAccess.remove_absolute(caminho + ".bak")
		DirAccess.rename_absolute(caminho, caminho + ".bak")
	DirAccess.rename_absolute(tmp, caminho)

## Zona do manômetro (0..5) de uma destruição 0..1: mostrador 10–90% em 6 zonas iguais (A16).
static func zona(prog: float, mostrador := [0.1, 0.9]) -> int:
	var lo := float(mostrador[0])
	var hi := float(mostrador[1])
	return clampi(int(floor((prog - lo) / (hi - lo) * 6.0)), 0, 5)

## Fim de partida: aplica gangorra e Projetos, grava e devolve o que a tela de resultados mostra.
## cfg = modos[derruba].progressao; visitadas = ids das cenas por onde a luta passou.
func fim_de_partida(map_id: String, visitadas: Array, prog_final: float, duracao_s: float, tem_vencedor: bool,
		cfg: Dictionary, mostrador: Array) -> Dictionary:
	var g: Dictionary = dados["gangorra"]
	var antes := int(g["valor"])
	var valida := tem_vencedor and duracao_s >= float(cfg.get("partida_valida_min_s", 60.0))
	var z := zona(prog_final, mostrador)
	var delta := int(cfg["gangorra_deltas"][z]) if valida else 0
	var depois := clampi(antes + delta, -100, 100)
	var premio := ""
	if depois <= -100:
		premio = String(g["extremo_verde"])
	elif depois >= 100:
		premio = String(g["extremo_vermelho"])
	if premio != "":   # prêmio revelado: hoje tudo já está liberado (A9), fica registrado; a agulha volta ao centro
		dados["premios"].append({"categoria": premio, "lado": "verde" if depois < 0 else "vermelho"})
		var cat := _sorteia_extremos()
		g["extremo_verde"] = cat[0]
		g["extremo_vermelho"] = cat[1]
		g["valor"] = 0
	else:
		g["valor"] = depois
	var cv: Dictionary = dados["cenas_visitadas"]
	if not cv.has(map_id):
		cv[map_id] = []
	var novas := []
	if valida:   # só partida válida registra a visita (senão uma luta curta gastaria o +2 da cena nova)
		for c in visitadas:
			if not c in cv[map_id]:
				cv[map_id].append(c)
				novas.append(c)
	var pts := 0
	if valida:
		pts = int(cfg.get("pontos_partida", 1)) + int(cfg.get("pontos_cena_nova", 2)) * novas.size()
	dados["pontos_exploracao"] = int(dados["pontos_exploracao"]) + pts
	dados["estatisticas"]["partidas"] = int(dados["estatisticas"]["partidas"]) + 1
	if valida:
		dados["estatisticas"]["partidas_validas"] = int(dados["estatisticas"]["partidas_validas"]) + 1
	salvar()
	return {"valida": valida, "zona": z, "antes": antes, "depois": depois, "delta": delta, "premio": premio,
		"novas": novas, "pontos": pts, "total": int(dados["pontos_exploracao"]),
		"por_mapa": int(cfg.get("pontos_por_mapa", 6))}

func guardar_config(cfgp: Dictionary) -> void:
	dados["ultima_config"] = cfgp
	salvar()
