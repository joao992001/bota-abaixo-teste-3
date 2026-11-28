# Biblioteca do mapa — FASE 2 do Derruba: CARGUEIRO PERDIDO

**Situação, pendências do usuário e plano de construção: [`DOSSIE.md`](DOSSIE.md).**

| Campo | Valor |
|---|---|
| Estado | `APROVADO` (2026-11-28: "Aprovo tudo") — em construção (código, blocos A–F; ver `docs/BASTAO.md`) |
| Modo | Derruba (`docs/manuais/derruba/README.md`) |
| `map_id` | `cargueiro_perdido` · arte `game/assets/cargueiro/` |
| Manifesto | `data/mapas/derruba/cargueiro_perdido.json` (estrutura do Canteiro; conteúdo próprio) |
| Geometria | `levels/cargueiro_perdido.lvl` (`etapa1..3`, `ko`, `buraco`, nascimentos) |
| Topologia | **3 cenas** (APROVADO: este mapa fica com 3; a árvore de 7 fica para um mapa futuro que combine melhor) |
| Esquema | `art/out/fase2/esquema.png` (fonte `art/src/cenarios/f2_catalogo.py`) |
| Fotografias | `art/out/fase2/cena1_conves.png` (APROVADA), `cena2a_destrocos.png`, `cena2b_atlantida.png` (APROVADAS) — fonte `art/src/cenarios/f2_prancha.py` |
| Transições | `art/out/fase2/transicoes.png` (fonte `art/src/cenarios/f2_transicoes.py`) — APROVADO |

**Conceito (APROVADO, 2026-11-28):** tema **fundo do mar** — a viagem é DESCER O MAR, da superfície até Atlântida
(Atlântida = os últimos momentos). Regra dos temas A54: estrutura + mundo + regra-assinatura. **Toda cena precisa de
estrutura coerente para pisar e quebrar** (pedido do usuário: "no final das contas é isso que o jogador vai destruir,
pisar, jogar").
**Regra-assinatura (APROVADO, ideia e números):** a **ÁGUA** — onde está alagado: anda devagar, pulo flutua alto,
golpe joga longe. Quanto mais fundo, mais água (cresce cena a cena).

| Cena | Arquivo | Próxima |
|---|---|---|
| 1 · Cargueiro no Alto-Mar | `cenas/conves.md` | 2a aos 40% no tempo (o navio encalha) · 2b ao bater 65% (o navio parte e afunda) |
| 2a · Destroços do Cargueiro | `cenas/destrocos.md` | — (último nível) |
| 2b · Atlântida | `cenas/atlantida.md` | — (último nível) |

### Regra-assinatura: ÁGUA (APROVADO, ideia e números — vão para `data/modos.json`, nunca no código)
| Estado | Onde | Efeito proposto |
|---|---|---|
| **ALAGADO** | abaixo da linha d'água: maré alta (2a, M4), lado direito de Atlântida (2b, M7) | corrida ×0,6 (`env_slow`); gravidade ×0,55 e queda máx ×0,5 (**pulo flutua alto**); golpe recebido empurra ×1,25 (**joga longe**); respingo ao entrar/sair |
| **MOLHADO** | onda na balsa (1, M3), Onda Gigante (G15) | corrida ×0,8 por 2 s; gotas pingando do robô (leitura em 1 s) |
| Escala por cena | 1 → 2a → 2b | 1: só molha · 2a: alaga com a maré (~8 s a cada ~25 s) · 2b: lado direito sempre alagado e cresce |
Leitura: a água alagada é desenhada POR CIMA do palco, translúcida, com linha clara na superfície; robô alagado solta bolhas.
Desempenho: a água é um retângulo por cena (sem física de fluido); teste de "está na água" = 1 comparação de altura por robô.

Inventários: `eventos.md` · `perigos_mecanismos.md` · `spells.md` · `skins.md` · `decisoes_testes.md`.
