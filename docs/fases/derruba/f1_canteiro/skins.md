# Skins originadas no Canteiro de Obras

Processo: `docs/manuais/skins.md`. Prancha: `art/out/prancha_skins_canteiro.png` (gerador `art/src/robos/skins_canteiro.py`:
camadas por cima do robô; mesma silhueta e hitbox; cor do jogador dominante; sem efeito de jogo).
Manifesto: `skins_originadas` = K1–K5 (arte aprovada). Recurso no jogo (seletor etc.): NÃO autorizado ainda.

| Id | Robô | Skin | O que muda | Estado |
|---|---|---|---|---|
| v1 (10 skins: adesivos, faixas, coletes laterais) | todos | — | camadas pequenas por cima | REPROVADO (2026-11-25): "mudanças muito sutis" |
| K1 | Marretão | Mestre de Obras | uniforme laranja refletivo no tronco, capacete grande na cor do jogador com lanterna, marreta zebrada | APROVADO — arte (2026-11-25) |
| K2 | Picareta | Topógrafo | colete limão, luneta de teodolito no olho, picareta-baliza vermelho/branco | APROVADO — arte (2026-11-25) |
| K3 | Chave | Soldador | avental de couro com tachas, máscara de solda grande na cor do jogador, chave de cobre | APROVADO — arte (2026-11-25) |
| K4 | Britadeira | Concreteiro | corpo coberto de cimento, capacete respingado, máscara de pó, britadeira suja | APROVADO — arte (2026-11-25) |
| K5 | Pá | Operador de Escavadeira | corpo de máquina nº 01 com zebra, cabine com santo-antônio e giroflex, pá-caçamba com dentes | APROVADO — arte (2026-11-25) |
Regra nova da v2 (APROVADA em 2026-11-25): o uniforme pode cobrir o tronco inteiro; a COR DO JOGADOR passa para o capacete/cabine
grande (e segue nos braços e pernas). Aplicação em movimento (2026-11-25): no jogo as skins só trocam texturas (`corpo_<robô>_<k#>_p<cor>.png`,
`ferramenta_<robô>_<k#>.png`, geradas por `python3 art/src/robos/skins_canteiro.py --jogo`); `robot_visual.skin = "k1"`.
Vitrines: `--elenco=DIR --skins` (13 poses) e `--equipa=DIR --skins` (armas, kits, armaduras) → AGUARDANDO_APROVAÇÃO.
Escolha no jogo APROVADA (2026-11-25): na entrada dos personagens, X/□ alterna padrão ↔ skin do Canteiro.

## Skins v2 — estilo atual do elenco (2026-11-27)
As K1–K5 da tabela acima eram do elenco antigo; foram refeitas no estilo atual (robo_uch / elenco_uch) por
`art/src/robos/skins_v2.py` (K1) e `art/src/robos/skins_lote.py` (lote) → `art/out/skins_v2/`.
Regra: fantasia completa (forma e material), cor do jogador no capacete/cabine e nos braços e pernas, mesma silhueta.

| Id | Robô | Skin | Estado |
|---|---|---|---|
| K1 | Marretão | Mestre de Obras (capacete de aba total com lanterna, bigodão, colete refletivo, marreta vermelha com nível) | APROVADO — arte (2026-11-27) |
| K6 | Marretão | Brigadista (capacete de bombeiro, japona areia, machado-marreta) | APROVADO — arte (2026-11-27) |
| K7 | Marretão | Sucateiro (balde de capacete, tambor de óleo, pneu de cinto, marreta de entulho) | APROVADO — arte (2026-11-27) |
| K2 | Guindaste | Topógrafo (chapéu com nuca, olho de teodolito, colete limão, baliza) | APROVADO — arte (2026-11-27) |
| K8 | Guindaste | Grua Clássica (cabeça = cabine com contrapeso, treliça vermelha/branca) | APROVADO — arte (2026-11-27) |
| K9 | Guindaste | Pintor (chapéu de jornal, jardineira respingada, rolo + lata) | APROVADO — arte (2026-11-27) |
| K3 | Solda | Soldador Caprichado (máscara na cor com chamas, avental tachado, chave de cobre) | APROVADO — arte (2026-11-27) |
| K10 | Solda | Eletricista (capacete com raio, protetor facial, bobina, alicate) | APROVADO — arte (2026-11-27) |
| K11 | Solda | Mergulhador de Poço (escafandro com latão, tanque amarelo, chave de bronze) | APROVADO — arte (2026-11-27) |
| K4 | Brita | Concreteiro (cimento escorrendo, máscara de pó, britadeira suja) | APROVADO — arte (2026-11-27) |
| K12 | Brita | Asfaltador (asfalto, chaminé, colete, compactador "sapo") | APROVADO — arte (2026-11-27) |
| K13 | Brita | Mineiro (barril de madeira, capacete com farol, xadrez, perfuratriz) | APROVADO — arte (2026-11-27) |
| K5 | Escavadeira | Operador nº 01 (santo-antônio com giroflex, zebrado, placa 01) | APROVADO — arte (2026-11-27) |
| K14 | Escavadeira | Velho de Guerra (ferrugem, remendos, fumaça preta) | APROVADO — arte (2026-11-27) |
| K15 | Escavadeira | Demolidora (grade na tela, placas, pinça hidráulica) | APROVADO — arte (2026-11-27) |

**Todas as 15 APROVADAS (2026-11-27) e no jogo:** `python3 art/src/robos/skins_lote.py --jogo` gera, por skin,
`corpo_/tronco_/cabeca_<robô>_<k#>_p1..4`, `rosto_<robô>_<k#>_<expr>`, `antena_<robô>_<k#>`, `ferramenta_<robô>_<k#>`,
`mao_<robô>_<k#>` e `pe_<robô>_<k#>` → copiar para `game/assets/robo/` → `--import`. A cabeça da skin também balança com mola.
Na entrada, X/□ passa pelas 3 skins do robô e volta ao padrão. Vitrine: `--elenco=DIR --skins=0|1|2`.
