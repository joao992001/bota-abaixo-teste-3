# Manual — DESEMPENHO (medir antes de mexer)

Orçamento em `data/desempenho.json`: CPU do jogo (lógica + geração de desenho) **8 ms** por quadro em média, pico
tolerado **12 ms** (a 60 FPS o quadro tem 16,7 ms; o resto é do render/GPU e do sistema). Orçamento por sistema no mesmo arquivo.

## Como medir
```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path game -- --perf-derruba=DIR [--perf-dur=S] [--perf-rota=total|moderada] [--perf-normal]
```
Partida de 4 bots no Canteiro, eventos em ALTA, todas as engenhocas, caixas frequentes (pior caso) e virada de cena.
Grava `DIR/relatorio.md` (médias, p95/p99, ranking por sistema e por contexto, os 15 piores quadros com o que estava
acontecendo) e `DIR/quadros.json`.

- A sonda é o autoload `Perf` (`game/autoload/perf.gd`): desligada no jogo normal (custo de um `if`). Cada sistema soma
  `Perf.add("nome", Perf.t0())` na lógica e no `_draw`.
- **Para achar o culpado dentro de um sistema**, divida com marcadores temporários `Perf.add("DBG_parte", _q)`, rode
  com `--perf-dur=12..20` e **tire os marcadores** antes do commit.
- **Atenção:** neste contêiner o GL é por software e a CPU é lenta. Os ms absolutos saem 3–5× maiores que num PC;
  compare SEMPRE antes × depois na mesma máquina. Um quadro com TODOS os sistemas inflados é engasgo da máquina, não do jogo.

## O que já foi achado (2026-11-27)
| Problema | Custo medido | Correção |
|---|---|---|
| Corações de vida do placar: polígono com o 1º ponto repetido → triangulação FALHAVA a cada quadro (o erro "triangulation failed" do log) + contorno suavizado | ~7 ms (36 corações) | formato e triângulos calculados uma vez; desenho com `canvas_item_add_triangle_array` (borda = coração escuro maior atrás) |
| Chave do cache de estilos (`Kit._sb`) montava texto com `to_html` a cada chamada | ~0,5 ms | chave direta `[cor, raio, borda, cor]` |
| Bots: UM cache de rota para os 4 → cada alvo novo refazia a busca no mapa todo (~80 mil verificações) e os outros usavam a rota do alvo errado | picos de 16–30 ms | rota por célula-alvo (vale 1 s), no máximo 1 recálculo por quadro, células "em pé" cacheadas |

Resultado no pior caso (mesma máquina): CPU média **41,8 → 28 ms**, p99 **88 → 56 ms**; placar **11,9 → 5,7 ms**.

## O que ainda pesa (próximos alvos, se precisar)
- Desenho dos robôs ~5 ms com 4 (desenho 0,65 ms/robô, pose 1,3 ms no total, etiqueta P1/P2 0,7 ms).
- Cartões do placar ~4 ms (fundos com `draw_style_box` suavizado, textos com contorno).
- Picos isolados de eventos ao criar objetos (G10 Carga Especial, G05) ~10 ms num quadro.
- Física dos robôs com picos de até ~18 ms em colisões em grupo.
