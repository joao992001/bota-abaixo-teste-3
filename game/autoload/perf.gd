extends Node
## SONDA DE DESEMPENHO (protocolo: docs/manuais/desempenho.md). Desligada no jogo normal (custo ~zero: um "if").
## Ligada (--perf-derruba=DIR), cada sistema soma quantos ms gastou no quadro: lógica (update/_physics_process) e
## geração de desenho (_draw). O driver lê e zera `acc` a cada quadro e cruza com o que estava acontecendo.
var on := false
var acc := {}   # nome -> ms no quadro atual

func t0() -> int:
	return Time.get_ticks_usec() if on else 0

func add(nome: String, desde: int) -> void:
	if on:
		acc[nome] = float(acc.get(nome, 0.0)) + (Time.get_ticks_usec() - desde) / 1000.0

func take() -> Dictionary:
	var a := acc
	acc = {}
	return a
