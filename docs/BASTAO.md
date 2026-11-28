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

### Fase 2 · Cargueiro Perdido — bloco A (cenas: .lvl + manifesto)
- Quem: sessão 017desNJLabnbh98EwrZ9vQj · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "Aprovo tudo" (dossiê `docs/fases/derruba/f2_cargueiro/DOSSIE.md`) → construir a fase (método
  `docs/manuais/derruba/mapa.md` §3, blocos A–F; este bloco = A)
- Arquivos reservados: `levels/cargueiro_perdido.lvl`, `data/mapas/derruba/cargueiro_perdido.json`,
  `docs/fases/derruba/f2_cargueiro/`, `art/src/cenarios/f2_*.py`, `art/out/fase2/`
- Passos:
  - [x] 1. Geometria tirada das 3 fotografias (64 px = 1 casa; medidas anotadas no passo 2)
  - [x] 2. `levels/cargueiro_perdido.lvl` FEITO (commit "bastão: F2 bloco A passos 1–2"): etapa1 (Alto-Mar, em cima), etapa2 (Atlântida, EMBAIXO = rota total, queda),
        etapa3 (Destroços, À DIREITA = rota moderada, deslize); ko1..3, buraco1 (porão), nascimentos 1–12, `canteiro: 1`
  - [ ] 3. Manifesto `data/mapas/derruba/cargueiro_perdido.json` (cenas com rotas e avisos, estruturas com os tipos que já
        existem: pranchas/vigas/lajes/pilares; spells e eventos que já existem); fase escondida dos menus até ficar jogável
  - [ ] 4. Testes: `--so=mapa` + teste novo que carrega as 3 cenas, KO, nascimentos e as 2 rotas; captura de cada área
- **Próximo passo exato:** passo 3 — manifesto `data/mapas/derruba/cargueiro_perdido.json` copiando o esqueleto do
  `canteiro_obras.json`. Estruturas (tiles; origem de cada cena: etapa1 0,0 · etapa2 0,20 · etapa3 34,2):
  cena 1 `lajes {seg_x:[],nucleo:[],linha:13}`, `andaimes` (tábuas) [[8,9,5],[17,9,4],[5,6,3],[22,6,6]], `vigas` [[20,3,5]];
  cena 2 Atlântida `pranchas` (abs) [[0,26,5],[5,29,7],[11,27,7],[12,24,5],[18,23,3],[23,26,6],[21,29,3]];
  cena 3 Destroços `pranchas` (abs) [[43,14,3],[52,14,3],[45,10,8],[52,11,5],[55,7,8],[38,7,3],[46,6,3],[41,16,2],[43,16,3]].
  Rotas: terreo→ moderada `destrocos` (ordem 3), total `atlantida` (ordem 2). Esconder dos menus até ficar jogável.
- Decisões pendentes do usuário: nenhuma.


## AGUARDANDO USUÁRIO

(nenhum)

## FILA (pedido pelo usuário, ninguém pegou ainda)
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · Dossiê da Fase 2 completo e APROVADO pelo usuário (A55) — sessão 017desNJ…
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
