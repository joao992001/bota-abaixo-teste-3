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

### Dossiê da Fase 2 · Cargueiro Perdido (completar a biblioteca do mapa)
- Quem: sessão 017desNJLabnbh98EwrZ9vQj · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "o outro chat chegou até a concluir o dossiê para a criação da segunda fase… se ele não montou,
  terminar de montar"
- Arquivos reservados: `docs/fases/derruba/f2_cargueiro/`, `art/src/cenarios/f2_*.py`, `art/out/fase2/`
- Passos:
  - [x] 0. Conferir o que o outro chat deixou: biblioteca, esquema, 3 fotografias (cena 1 APROVADA; 2a/2b aguardando),
        prancha de perigos M1–M10 (proposta). Faltava pelo método (`docs/manuais/derruba/mapa.md` §1–2): fichas 2a/2b
        desatualizadas, fundo vivo (C0–C4), storyboard das 2 transições, eventos com id/aviso/efeito, números da água,
        engenhocas por cena, skins por robô, página de situação (DOSSIÊ).
  - [x] 1. Fichas das 3 cenas iguais às fotografias (fixo × destrutível, KO, perigos, eventos, fundo vivo C0–C4,
        transições da cena 1) (commit: ver "bastão: dossiê F2 passo 1")
  - [x] 2. Regra da água com números propostos (README da fase) (commit "bastão: dossiê F2 passos 2–3")
  - [x] 3. Eventos G15–G19 com aviso/efeito/duração/cenas; engenhocas (A03/T01 na água, A09 Torpedo, D07 Escafandro);
        skins K16–K20 por robô (mesmo commit)
  - [x] 4. Prancha do storyboard das 2 transições `art/out/fase2/transicoes.png` (gerador `art/src/cenarios/f2_transicoes.py`)
        (commit "bastão: dossiê F2 passo 4")
  - [ ] 5. `DOSSIE.md` da fase: o que está APROVADO, o que espera o usuário (com as pranchas) e o plano A–F
  - [ ] 6. Mandar ao usuário as pranchas pendentes + perguntas; mover o bloco para AGUARDANDO USUÁRIO
- **Próximo passo exato:** passo 5 — escrever `docs/fases/derruba/f2_cargueiro/DOSSIE.md` (situação: APROVADO × aguardando,
  lista das pranchas para o usuário, plano dos blocos A–F do `mapa.md` §3, desempenho) e apontar no README da fase.
- Decisões pendentes do usuário: aprovar fotografias 2a/2b e a prancha de perigos (já enviadas pelo outro chat).

## AGUARDANDO USUÁRIO
(nenhum)

## FILA (pedido pelo usuário, ninguém pegou ainda)
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
