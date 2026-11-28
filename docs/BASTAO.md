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

### Correções urgentes do mapa 1 (Canteiro) + controle principal
- Quem: sessão 017desNJLabnbh98EwrZ9vQj · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "a obra cede em 20 s… tem que ter um equilíbrio dos 90 s (estudo de proporção jogando partidas)…
  travação no subterrâneo quando ativa a gravidade… ficando sem engenhocas no subterrâneo… só o controle principal
  (o 1º conectado) mexe nos menus; na configuração de controles o P1 escolhe o controle do P2, ele assume e depois volta"
- Arquivos reservados: `data/modos.json` (destruicao, canteiro), `game/modes/etapas.gd`, `game/modes/canteiro.gd`,
  `game/modes/spells.gd` (spawn), `game/modes/eventos.gd` (G03), `game/autoload/player_input.gd`, `game/ui/menus.gd` (controles)
- Passos:
  - [x] 1. Estudo da destruição (`--estudo-destruicao=N [--estudo-nivel=2 --estudo-eventos=3]`): a cena virava em ~20 s
        pelo A53b (65% a qualquer momento); platô natural ~67% (parte de cima cai); aos 90 s médios 64–67%, difíceis 67–86%
  - [x] 2. Regra A56 em `data/modos.json`: só a verificação decide (`total_imediato` false), 1ª aos 90 s (3 vidas),
        moderada 35%, total 70%, mostrador até 70% + testes etapas/verificacao (commit deste passo)
  - [x] 3. Engenhocas no subterrâneo: `spells.spawn_points` usa o chão firme da cena quando faltam peças + teste `--so=caixas_subsolo`
  - [x] 4. FPS G03: porcas viraram atlas (1 textura) + teto 24 → CPU 8,5→6,9 ms, chamadas 991→763, picos 3,8%→0,7%
  - [x] 5. Controle principal (`PlayerInput.principal/manda_no_menu`, `menus.dono`) + teste `--so=principal`
  - [ ] 6. Medir a regra com a transição ligada (várias partidas), registrar A56 em reformulacao_derruba.md, manual de
        desempenho §4/§5, bateria completa, .exe, relatório
- **Próximo passo exato:** passo 6 — estudo com `etapas.ativo=true` (tempo e rota de virada), depois A56 no
  `docs/revisoes/reformulacao_derruba.md`, linha nova no `docs/manuais/desempenho.md` §4, bateria `--autotest`, .exe.
- Decisões pendentes do usuário: nenhuma (o estudo decide os números; reportar).


## AGUARDANDO USUÁRIO

(nenhum)

## FILA (pedido pelo usuário, ninguém pegou ainda)
- **Fase 2 · bloco B (arte da cena viva)** — próximo da fase (usuário aprovou tudo, A55). Método `docs/manuais/derruba/mapa.md`
  §3 B: copiar `art/src/cenarios/fase1_jogo.py` → `f2_jogo.py`, tirar as camadas PARADAS das fotografias
  (`art/src/cenarios/f2_prancha.py`: c1_ceu/c1_longe/c1_navio_fundo, c2_ceu/c2_navio_fundo, c3_agua/c3_cidade_fundo/c3_cupula)
  para `game/assets/cargueiro/`, `--import`, props `cena: cargueiro` no `.lvl`; generalizar `game/modes/cena.gd` (as listas da
  fase 1). Conferir com `--cargueiro=DIR` (captura atual, arte provisória: `art/out/fase2/jogo/bloco_a_cenas.png`).
- **Fase 2 · bloco C (água + perigos M1–M10)** e **D (contêineres)**, **E (eventos G15–G19)**, **F (entrega)** — ver `DOSSIE.md` §3.
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · Fase 2 bloco A: `.lvl` + manifesto + teste `--so=cargueiro` (2 rotas de verdade) + vitrine `--cargueiro=DIR` — sessão 017desNJ…
- 2026-11-28 · Dossiê da Fase 2 completo e APROVADO pelo usuário (A55) — sessão 017desNJ…
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
