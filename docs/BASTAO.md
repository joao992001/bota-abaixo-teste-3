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

### Fase 2 · bloco C (água + perigos M1–M10)
- Quem: sessão 018QUPBQj4sLX3w64QQJCiVt (assumiu do 017desNJ…) · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "as fotografias estão muito boas… falta substituir as plataformas pelos elementos do tema (→ bloco D)…
  já podemos avançar para a próxima parte". Bugs/gameplay do mapa 1 relatados por ele passam na FRENTE.
- Arquivos reservados: `game/modes/agua.gd` (novo), `game/player/robot.gd` (agua_*), `game/modes/mecanismos.gd`,
  `data/mapas/derruba/cargueiro_perdido.json`, `data/modos.json` (demolicao.agua)
- Passos:
  - [x] 1. Água: `agua.gd` (zonas por cena do manifesto, alagado/molhado, respingo/bolhas/gotas), números em
        `modos.json demolicao.agua`, ganchos no `robot.gd` (agua_grav/agua_queda/agua_empurra + env_slow) + teste `--so=agua`
  - [x] 2. M-perigos da cena 1 (M1–M3), um por commit, com teste — M1 contêiner despenca FEITO (`conteiner_cai`, `--so=m1`); M2 gancho balança FEITO (`gancho_balanca`, `--so=m2`); M3 onda na balsa FEITO (`onda_balsa`, `--so=m3`) — cena 1 completa
  - [ ] 3. M-perigos da cena 2a (M4 maré etc.) e 2b (M7 cúpula etc.) + M10 tubarão
  - [x] (pedido do usuário, adiantado do bloco D) TEXTURAS DO TEMA: base fixa das fotos (`e1/e2/e3_palco`, tiles invisíveis
        `sem_arte_de: 0`), contêineres como peça nova do canteiro (`conteineres` no manifesto, `conteiner_hp`), tábuas (Alto-Mar)
        e lajes de mármore (Atlântida) no lugar de andaimes/pranchas; M1 usa a arte do contêiner. Captura `art/out/fase2/jogo/palco_tema.png`
- **Próximo passo exato:** Destroços COMPLETOS (M4 maré, M5 boia, M6 rede, M10 tubarão; `--so=m4,m5,m6,m10`). Próximo:
  Atlântida (cena 2 no .lvl): **M7 racha da cúpula** (zona de água já existe em `cenas[atlantida].agua`: a racha
  pinga/brilha; marretada no vidro faz a água crescer — mexer no `topo` da zona como o `mare`), **M8 lustre despenca**
  (peça `p2_prancha_7`: marretada na corrente → estala + SOMBRA VERMELHA 1 s → cai, esmaga e racha a plataforma embaixo),
  **M9 concha-trampolim** (hoje desenho no `e2_palco`: tirar de lá, tipo `concha` em `mecanismos.gd`: pisou → lança alto;
  depois FECHA 2 s e prende; marretada abre). Pendente pequeno: "KO no mar = abocanhado" (animação) do M10; som de respingo.
- Decisões pendentes do usuário: nenhuma (água aprovada no A55; números ajustam jogando).

## AGUARDANDO USUÁRIO

### M11 Gêiser (Atlântida) — ideia do usuário
- Pergunta enviada (2026-11-28): aprova a prancha `art/out/fase2/perigo_geiser.png` (borbulha 1,5 s → jorra ~2,5 s: quem
  cai na fenda é jogado de volta; o jato também serve de elevador; sem dano; ~10 s alternando entre as 2 fendas)?
- Aprovado → tipo `geiser` em `mecanismos.gd` (fendas = colunas 6–12 e 18–24 da cena 2), teste `--so=m11`, vitrine.

## FILA (pedido pelo usuário, ninguém pegou ainda)
- **Fase 2 · bloco D (contêineres + ARTE DO PALCO no tema: o usuário pediu trocar caixotes/andaimes do canteiro pelos do mar)**, **E (eventos G15–G19)**, **F (entrega)** — ver `DOSSIE.md` §3.
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · Fase 2 bloco B: cena viva do Cargueiro (`cena_cargueiro.gd`, `f2_jogo.py`); usuário aprovou a composição — sessão 017desNJ…
- 2026-11-28 · Correções urgentes do Canteiro (A56 regra dos 90 s, caixas no subterrâneo, FPS da G03, controle principal); bateria 623 ok, .exe — sessão 017desNJ…
- 2026-11-28 · Fase 2 bloco A: `.lvl` + manifesto + teste `--so=cargueiro` (2 rotas de verdade) + vitrine `--cargueiro=DIR` — sessão 017desNJ…
- 2026-11-28 · Dossiê da Fase 2 completo e APROVADO pelo usuário (A55) — sessão 017desNJ…
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
