# Biblioteca do mapa — FASE 2 do Derruba: CARGUEIRO PERDIDO

| Campo | Valor |
|---|---|
| Estado | `PROPOSTO` (conceito e cenas APROVADOS em 2026-11-28; estruturas/perigos/eventos aguardam o esquema) |
| Modo | Derruba (`docs/manuais/derruba/README.md`) |
| `map_id` | `cargueiro_perdido` · arte `game/assets/cargueiro/` |
| Manifesto | `data/mapas/derruba/cargueiro_perdido.json` (estrutura do Canteiro; conteúdo próprio) |
| Geometria | `levels/cargueiro_perdido.lvl` (`etapa1..3`, `ko`, `buraco`, nascimentos) |
| Topologia | **3 cenas** (APROVADO: este mapa fica com 3; a árvore de 7 fica para um mapa futuro que combine melhor) |
| Esquema | `art/out/fase2/esquema.png` (fonte `art/src/cenarios/f2_catalogo.py`) |

**Conceito (APROVADO, 2026-11-28):** tema **fundo do mar** — a viagem é DESCER O MAR, da superfície até Atlântida
(Atlântida = os últimos momentos). Regra dos temas A54: estrutura + mundo + regra-assinatura. **Toda cena precisa de
estrutura coerente para pisar e quebrar** (pedido do usuário: "no final das contas é isso que o jogador vai destruir,
pisar, jogar").
**Regra-assinatura (APROVADO na ideia; números PROPOSTOS):** a **ÁGUA** — onde está alagado: anda devagar, pulo flutua alto,
golpe joga longe. Quanto mais fundo, mais água (cresce cena a cena).

| Cena | Arquivo | Próxima |
|---|---|---|
| 1 · Cargueiro no Alto-Mar | `cenas/conves.md` | 2a aos 40% no tempo (o navio encalha) · 2b ao bater 65% (o navio parte e afunda) |
| 2a · Destroços do Cargueiro | `cenas/destrocos.md` | — (último nível) |
| 2b · Atlântida | `cenas/atlantida.md` | — (último nível) |

Inventários: `eventos.md` · `perigos_mecanismos.md` · `spells.md` · `skins.md` · `decisoes_testes.md`.
