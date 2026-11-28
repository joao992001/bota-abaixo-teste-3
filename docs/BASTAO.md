# BASTÃO — quem está fazendo o quê AGORA (todo chat lê isto antes de qualquer coisa)

Vários chats (contas/sessões) trabalham na MESMA branch (`claude/practical-maxwell-hldv9n`). O contêiner de cada chat
some quando ele para (limite de uso, reinício, conversa encerrada): **o que não está commitado e enviado se perde.**
Este quadro é o que permite outro chat continuar EXATAMENTE de onde o anterior parou. Regras em `docs/COMO_TRABALHAR.md` §6.

## Regras rápidas
1. **Ao começar:** `git pull --rebase origin claude/practical-maxwell-hldv9n` → leia este quadro → leia o bloco da tarefa.
2. **Pegar tarefa:** crie/atualize o seu bloco em EM ANDAMENTO (tarefa, arquivos reservados, passos, próximo passo) e
   faça commit+push **antes** de mexer no resto ("bastão: pega <tarefa>").
3. **Arquivos reservados** por outro bloco EM ANDAMENTO: não mexa sem o usuário mandar (evita conflito entre chats).
4. **Passos pequenos (≤ ~20 min).** Terminou um passo → marque `[x]` com o commit, reescreva **Próximo passo exato**,
   commit+push **junto com o trabalho**. Nunca termine um turno com trabalho só no contêiner.
5. **Continuar o de outro chat:** se o usuário pedir ("continue de onde o outro parou") ou o bloco estiver parado e o
   usuário falar da mesma tarefa, assuma: troque "Quem" e "Desde", siga do **Próximo passo exato**. O que não tinha
   commit está perdido — refaça a partir do último `[x]`.
6. **Esperando o usuário:** mova o bloco para AGUARDANDO USUÁRIO com a pergunta exata (e o que foi enviado a ele).
7. **Terminou:** 1 linha em CONCLUÍDO (o resto vai para o "Retomar aqui" do `docs/ESTADO.md`) e apague o bloco.

## Modelo de bloco (copie)
```
### <tarefa curta>
- Quem: <chat/conta ou id da sessão> · Desde: <data hora> · Última atualização: <data hora>
- Pedido do usuário: "<frase dele>"
- Arquivos reservados: <pastas/arquivos que só este chat mexe>
- Passos:
  - [x] 1. ... (commit abc1234)
  - [ ] 2. ...
- **Próximo passo exato:** <o que fazer, com arquivo e comando>
- Decisões pendentes do usuário: <ou "nenhuma">
```

## EM ANDAMENTO

### Fase 2 · lapidar ARTE e ANIMAÇÃO dos perigos (antes das transições)
- Quem: sessão 018QUPBQj4sLX3w64QQJCiVt · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "lapidar as artes e as animações de cada etapa… a onda tá muito feia, o tubarão não tá bonito, os
  andaimes, os contêineres caindo não tão legal… um trabalho mais minucioso e detalhado das animações e das artes dos perigos,
  para que a gente avance para as animações de transição de cena".
- Arquivos reservados: `game/modes/mecanismos.gd` (desenhos `_draw_*`), `art/src/cenarios/f2_jogo.py` (SPRITES), `art/src/cenarios/f2_lapida*.py` (novo),
  `game/assets/cargueiro/` (sprites novos dos perigos)
- Método (igual ao outro chat): por cena, PRANCHA com quadro a quadro da animação → aprovação → arte+código → captura no jogo (após `--import`).
- Passos:
  - [ ] 1. Cena 1: prancha M1 contêiner caindo, M2 gancho, M3 onda (+ tábuas/andaimes) → aprovação
  - [ ] 2. Cena 1 no jogo (sprites + animação) + capturas
  - [ ] 3. Cena 2a: prancha M4 maré, M5 boia, M6 rede, M10 tubarão → aprovação → jogo
  - [ ] 4. Cena 2b: prancha M7 racha, M8 lustre (corrente partindo), M9 concha (valva inteira), M11 gêiser → aprovação → jogo
- **Próximo passo exato:** passo 1 — ver capturas atuais `art/out/fase2/uso/cena1.png`, fazer `art/src/cenarios/f2_lapida1.py` → `art/out/fase2/lapida_cena1.png`.
- Decisões pendentes do usuário: aprovar cada prancha.

## AGUARDANDO USUÁRIO

## FILA (pedido pelo usuário, ninguém pegou ainda)
- (em andamento acima) **Lapidar o visual dos perigos M1–M11 no jogo** (usuário 2026-11-28, vendo `art/out/fase2/uso/*.png`: "os perigos existem, mas pelas fotos faltam muitos ajustes visuais, estão bem ruins — pode continuar o fluxo, depois a gente lapida"). Fazer depois de M8/M9: prancha de cada perigo no tema (como a do tubarão) → arte no jogo.
- **Fase 2 · bloco D (contêineres + ARTE DO PALCO no tema: o usuário pediu trocar caixotes/andaimes do canteiro pelos do mar)**, **E (eventos G15–G19)**, **F (entrega)** — ver `DOSSIE.md` §3.
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · Fase 2 bloco C: água + perigos M1–M11 no jogo (`--so=agua,m1..m11` verdes; capturas `art/out/fase2/uso/`); visual a lapidar (FILA) — sessões 017desNJ… e 018QUPBQ…
- 2026-11-28 · Fase 2 bloco B: cena viva do Cargueiro (`cena_cargueiro.gd`, `f2_jogo.py`); usuário aprovou a composição — sessão 017desNJ…
- 2026-11-28 · Correções urgentes do Canteiro (A56 regra dos 90 s, caixas no subterrâneo, FPS da G03, controle principal); bateria 623 ok, .exe — sessão 017desNJ…
- 2026-11-28 · Fase 2 bloco A: `.lvl` + manifesto + teste `--so=cargueiro` (2 rotas de verdade) + vitrine `--cargueiro=DIR` — sessão 017desNJ…
- 2026-11-28 · Dossiê da Fase 2 completo e APROVADO pelo usuário (A55) — sessão 017desNJ…
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
