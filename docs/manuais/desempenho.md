# Manual — DESEMPENHO (protocolo: medir antes de mexer, medir depois de criar)

Objetivo: o jogo **não pode engasgar** numa partida local de 4 (humanos ou bots), em nenhum mapa, evento, engenhoca ou
transformação. O protocolo tem duas partes:
1. **Corretiva** (o que já existe): achar e remover quedas de FPS do jogo atual — seção 4.
2. **Preventiva** (o que vai ser criado): todo elemento novo é medido antes de ser aprovado — seção 3.

## 1. Orçamento (`data/desempenho.json`)
A 60 FPS o quadro tem **16,7 ms**. Metade fica para o render/GPU e o sistema; o jogo (lógica + geração de desenho) tem:
- **8 ms em média** por quadro e **pico tolerado de 12 ms**; no máximo **0,5 %** dos quadros acima do pico.
- Orçamento por sistema (ms/quadro, média) no mesmo arquivo (`orcamento_por_sistema_ms`); chamadas de desenho ≤ 2500.
- Os números absolutos valem para ESTA máquina de medição (contêiner, GL por software, CPU lenta — 3–5× mais lenta que um
  PC comum). O que importa é **antes × depois na mesma máquina** e **picos** (um pico aqui de 15 ms é ~4 ms num PC, mas
  um pico de 15 ms que se repete toda vez que algo acontece é sempre um problema real).

## 2. Ferramentas
**Sonda `Perf`** (`game/autoload/perf.gd`): desligada no jogo normal (custo de um `if`). Cada sistema soma o tempo do
quadro: `var _pf := Perf.t0()` … `Perf.add("nome", _pf)`. Já medidos: lógica e `_draw` de robôs, nível, fundo, canteiro,
engenhocas, eventos, mecanismos, cena, HUD (cartões, manômetro, avisos, textos), retratos, overlay; e por dentro:
`sub_bot_*` (decide, sobe, busca, seguro, queda), `sub_eng_*` (cada `_update_*` das engenhocas, `disparo_<id>`),
`sub_rob_*` (mover, golpe, contatos, engenhoca, visual), `ev_<id>_<fase>` (cada evento ativo), `ev_anuncio`,
`sub_canteiro_dano/desaba`. Nomes `sub_`, `ev_`, `hud_` são PARTES de outro sistema (não somam duas vezes).

**Cenário de medição** (`game/tests/driver.gd → perf_derruba`):
```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path game --rendering-driver opengl3 --fixed-fps 60 -- \
  --perf-derruba=DIR [--perf-dur=S] [--perf-rota=total|moderada] [--perf-normal] [--perf-partidas=N]
```
Partida de 4 bots no Canteiro (`--perf-cena=2` mede já na cena 2; `--perf-evento=G03` mantém um evento ligado), eventos em ALTA, todas as engenhocas, caixas frequentes (pior caso; `--perf-normal` =
configuração padrão), virada de cena no meio. `--perf-partidas=N` = sessão longa (N partidas seguidas: acha vazamento).
A simulação é **repetível** (mesma semente): o mesmo pico no mesmo quadro em duas rodadas = problema real; pico que muda de
lugar = engasgo da máquina. Grava `DIR/relatorio.md` (médias, p95/p99, ranking por sistema e por contexto, os 15 piores
quadros com o que estava acontecendo, tabela por partida) e `DIR/quadros.json` (cada quadro, para cruzar).

**Achar o culpado dentro de um sistema:** marcadores temporários `Perf.add("DBG_parte", _q)` em volta dos pedaços,
`--perf-dur=45`, ver os 5 maiores de cada `DBG_` no `quadros.json`, corrigir e **apagar os DBG_ antes do commit**.

## 3. Protocolo PREVENTIVO — todo elemento novo (engenhoca, evento, mecanismo, cena, mapa, transformação, efeito, tela)
1. **Antes de pedir aprovação do comportamento**, rode `--perf-derruba=DIR --perf-dur=45` com o elemento ligado e
   compare com a última medição registrada (seção 5). Some o marcador do elemento (`sub_eng_disparo_<id>`, `ev_<id>_*`
   ou um `Perf.add` novo no `update`/`_draw` dele).
2. **Aprovado para desempenho** se: média do elemento ≤ 0,5 ms/quadro, **nenhum pico do elemento > 2 ms** e a CPU do
   jogo continua no orçamento. Senão, otimize antes de entregar (lista da seção 4) ou explique o custo ao usuário.
3. Registre a linha na tabela da seção 5 (data, o que entrou, média/p99/% acima do pico).
4. Mudou algo em `bots.gd`, `eventos.gd` (sorteio), `level.gd` (`is_solid`/`ch_at`), `canteiro.gd` ou no desenho dos
   robôs? Meça — são os caminhos mais quentes do jogo.

**Regras de ouro (o que já derrubou o FPS aqui):**
- **Nunca ler/interpretar arquivo no meio da partida** (`Data.read_json`, `FileAccess`): guarde na abertura ou no
  `setup`. (`MapaReg.modo_cfg` relia os 39 KB do `modos.json` a cada chamada → ~10 ms por caixa sorteada e por eliminação.)
- **Nada de varrer o mapa inteiro num quadro.** Varra só a cena atual (`level.area` / `play_rect`) e, se ainda for
  caro, **fatie** (um pedaço por quadro com limite de tempo — ver `bots._avanca_busca`) ou **espalhe** (no máximo N
  testes por quadro — ver `eventos._sorteia_aos_poucos`).
- **Guarde o que não muda** (cache com validade curta) e **no máximo um recálculo caro por quadro** para todos os bots.
- Em funções chamadas milhares de vezes (`is_solid`, `ch_at`, `_standable`, `_reach`): **sem lista/dicionário literal
  criado a cada chamada** (use `const` de tabela), sem `filter`/`map` que alocam.
- **Forma que não muda, calcule uma vez** (corações do placar, estrelas, polígonos de ícones) — nada de trigonometria
  por ponto a cada quadro; polígono sem ponto repetido (triangulação que falha custa caro e enche o log).
- **Objetos de cena** (nós, corpos de física): reaproveite; `queue_free` tudo que o elemento criou ao acabar
  (sessão longa acusa vazamento). Partículas como listas de dicionários, removidas por tempo.
- **Desenho:** `queue_redraw()` só no nó que muda; texto com contorno é caro — evite muitos por quadro e tamanhos de
  fonte variando todo quadro (cada tamanho novo gera letras de novo).

## 4. Protocolo CORRETIVO — o que foi achado e corrigido
| Data | Problema | Custo medido (aqui) | Correção |
|---|---|---|---|
| 11-27 | Corações de vida do placar: triangulação falhando a cada quadro | ~7 ms (36 corações) | forma e triângulos calculados uma vez |
| 11-27 | Chave do cache de estilos (`Kit._sb`) com `to_html` por chamada | ~0,5 ms | chave direta |
| 11-27/28 | Bots: uma rota para os 4, busca no mapa inteiro de uma vez | picos de 13–16 ms | rota por alvo (vale 0,6 s); só a cena atual; busca **fatiada** (≤ 1,2 ms/quadro, inclusive a lista de pisos) |
| 11-28 | Sorteio de evento testava os 14 eventos (lugares livres, guindaste, andaimes) no mesmo quadro | picos de 8–19 ms | fila embaralhada, ≤ 2 testes por quadro (mesma chance para todos que cabem) |
| 11-28 | `MapaReg.modo_cfg` relendo o `modos.json` a cada chamada (sorteio de caixa, eliminação, HUD) | picos de ~10 ms | lido uma vez (`MapaReg._modos()`, somente leitura) |
| 11-28 | `level.is_solid` criando lista de 14 textos por chamada (milhares por quadro) | custo espalhado | tabela `const SOLIDOS` |
| 11-28 | Renascimento varrendo o mapa inteiro (cenas empilhadas) | 6–8 ms por volta | só a área de jogo |
| 11-28 | **Vazamento**: cache de estilos (`Kit._sb`, `Obra._sb`) com a cor EXATA na chave — cada transparência de animação virava um estilo novo guardado para sempre | +3 mil objetos e ~13 MB **por partida** (a sessão piorava) | cor arredondada (transparência em 32 níveis) + teto de 1500 estilos |
| 11-28 | **Vazamento**: nível criava uma forma de colisão antes do `if` e a dos trechos de parede ficava órfã | +13 nós órfãos por partida | forma criada só onde é usada |
| 11-28 | G03 Gravidade: ~45 porcas no ar, cada uma polígono + contorno suavizado + 2 círculos (Fundação "travando") | +1,3 ms/quadro, +210 chamadas, picos 0,6 %→3,8 % | atlas de 6 giros desenhado 1× (1 retângulo por porca, em lote) + teto de 24 → 6,9 ms (igual sem evento), 763 chamadas, 0,7 % |

## 5. Histórico de medições (pior caso, 4 bots, Canteiro, esta máquina)
| Data | Estado | CPU média | p99 | quadros > 12 ms | maiores picos de lógica |
|---|---|---|---|---|---|
| 11-27 | antes (linha de base) | 5,6 ms | 12,7 ms | 2,0 % | bots 14 · eventos 11,4 · engenhocas 7,6 |
| 11-28 | depois das correções da seção 4 | 7,2 ms* | 11,1 ms | **0,3 %** | bots 3,7 · física 3,5 · engenhocas 2,1 · eventos 2,1 |
| 11-28 | sessão longa (4–6 partidas seguidas) | estável | — | — | objetos por partida: antes +2,5–3,3 mil → depois +5–20; órfãos 0 |

\* A média subiu porque o HUD novo (A50: retrato animado, número de dano vivo) entrou entre as duas medições e a máquina
oscila ±1 ms; os picos (o que o jogador sente como "queda de FPS") caíram.

## 6. Teste automático (`--so=desempenho`, dentro da bateria completa)
Guarda as correções contra regressão com limites generosos: `modo_cfg` cacheado, `is_solid` barato, busca dos bots
fatiada, sorteio de evento espalhado, 10 s de partida com 4 bots sem pico de lógica > 15 ms, 3 partidas seguidas sem nó
órfão nem crescimento de objetos, cache de estilos arredondado. **Elemento novo que derrube um desses = não entra.**
Vazamento detalhado: `godot --headless --path game -- --perf-vaza` (lista os nós órfãos por tipo/nome).

## 7. O que ainda pesa (próximos alvos)
- **HUD**: cartões ~1,2 ms/quadro (fundos e textos com contorno redesenhados todo quadro) → desenhar os cartões numa
  camada própria que só redesenha quando o conteúdo muda (cuidado: o HUD está sendo refeito — A50).
- **Desenho dos robôs** ~1,0 ms com 4 (a pose e as texturas por robô); retratos animados ~0,7 ms.
- **Render** (GPU): ~800–1100 chamadas de desenho por quadro — dentro do orçamento; vigiar ao criar efeitos.
