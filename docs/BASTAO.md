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
- **Próximo passo exato:** passo 2b: reescrever as poses/tempo de `game/modes/mec_onda.gd` para A58 (frente da onda viaja: entra da borda → quebra na quina → espuma corre pelo convés até a ponta de dentro → escoa); regra de empurrão acompanha a frente; `--so=m3` + vídeo normal/lento.
- Decisões pendentes do usuário: <ou "nenhuma">
```

## EM ANDAMENTO

### Fase 2 · cena 1 (Alto-Mar): plataformas no tema (A57) no jogo + animação dos perigos no padrão novo
- Quem: sessão 01HthQDxRkYCgN9XMLafZiZ5 (assumiu da 018QUPBQ…) · Desde: 2026-11-28 · Última atualização: 2026-11-28
- Pedido do usuário: "lapidar as artes e as animações… a onda tá feia, os contêineres caindo não tão legal" + "o contexto
  visual das plataformas não se encaixa no tema" + "agora vamos colocar mais plataformas" → **"extremamente aprovado, é esse o
  caminho"** (A57: peças do tema + apoio visível; fases recheadas de plataformas).
- Arquivos reservados: `art/src/cenarios/f2_plataformas.py`, `art/src/cenarios/f2_jogo.py`, `game/assets/cargueiro/`,
  `game/modes/mec_onda.gd`, `game/modes/mecanismos.gd` (M1/M2), cena 1 do manifesto `data/mapas/derruba/cargueiro_perdido.json`
- Feito (commits na branch): manual `docs/manuais/animacao.md`; **M3 onda procedural APROVADA** ("aceitável; dá para melhorar
  depois") `game/modes/mec_onda.gd` + vídeos `out/videos/cargueiro_onda_v2(_lento).mp4`; prancha das plataformas APROVADA
  `art/out/fase2/plataformas_cena1_novas.png` (fonte `f2_plataformas.py`); contêiner de cima da boia REMOVIDO do manifesto.
- Passos:
  - [x] 1. (commit d1a7adc; `--so=cargueiro,mapa,m1,m2,m3,agua,bots` 0 falhas; captura igual à prancha) **Plataformas aprovadas → jogo.** (a) `f2_jogo.py`: `e1_palco()` passa a devolver `f2_plataformas.e1_palco_mar()` e
    `_pecas_e1()` passa a devolver `f2_plataformas.pecas_mar()` (import `f2_plataformas as fpl`); (b) manifesto, cena `alto_mar`,
    `estruturas` (edição pontual): `andaimes` += `[5, 9, 2]`, `[22, 9, 2]`, `[26, 3, 2]` (viram p1_andaime_4/5/6) e `vigas` +=
    `[2, 3, 4]` (p1_viga_1, o bote nos turcos) — confira em `canteiro.gd` (`_add` de andaime/viga) se o retângulo bate com o desenho
    (passarela: x−6, y−4, larg+12, 28 px; bote: topo em 3T); (c) `NODE_PATH=$(npm root -g) python3 art/src/cenarios/f2_jogo.py` →
    copiar `art/out/game/cargueiro/*` para `game/assets/cargueiro/` → `godot --headless --path game --import`; (d) teste
    `--so=cargueiro,mapa,m1,m2,m3` (no `driver.gd` a contagem do Alto-Mar sobe de 11 para 15 peças); (e) captura
    `--cargueiro=DIR` e conferir de perto que cada peça está onde a prancha mostra; bots alcançam (`--so=bots`).
  - [x] 2. (commit c194334; **APROVADO** pelo usuário 2026-11-28: "ficou muito bom"; vídeo `out/videos/cargueiro_conteiner_v2(_lento).mp4`) M1 contêiner no padrão `animacao.md` (`game/modes/mec_conteiner.gd`, como `mec_onda.gd`): sai da PILHA de carga do
    navio no fundo (amarras estalam, balança, escorrega), cai girando e acelerando, achata e quica, poeira/lascas, robô
    esmagado/arremessado (hitstop + `vis.hurt`); vídeo `--video-so=conteiner_cai --video-passo=1` + folha de quadros → usuário.
  - [ ] 2b. **Onda (M3): melhorar a COMPOSIÇÃO** (usuário 2026-11-28: "a física está muito boa, mas a animação está meio estranha: ela sobe, aí para… vem de um lado, ou só pega nos cantos — vamos melhorar a composição"). Diagnóstico: nasce no canto, cresce PARADA (parede), tomba só no canto. Usuário escolheu **A58 "vem e varre"** → código em `mec_onda.gd` → vídeo.
  - [ ] 3. M2 gancho no mesmo padrão (pêndulo com cabo que verga, antecipação puxando, pancada com hitstop) → vídeo → usuário.
  - [ ] 4. Aplicar A57 nas cenas Destroços e Atlântida (prancha antes × depois, mais plataformas) → aprovação → jogo.
  - [ ] 5. Depois: perigos da cena 2 (M4 maré, M5 boia, M6 rede, M10 tubarão) e 3 (M7, M8, M9, M11) no padrão de animação.
- **Próximo passo exato:** esperar o usuário aprovar o vídeo do M1 (`game/modes/mec_conteiner.gd`: sai do topo da pilha do navio no fundo, salta, cai girando, achata, quica; quem está embaixo é cuspido para o lado; coluna 14 tirada porque atravessava o gancho). Ajustar o que ele pedir; aprovado → passo 3 (M2 gancho, mesmo padrão: `mec_gancho.gd`).
- Decisões pendentes do usuário: nenhuma (próxima: aprovar a proposta da onda).

## AGUARDANDO USUÁRIO

## FILA (pedido pelo usuário, ninguém pegou ainda)
- (em andamento acima, passos 2–5) **Lapidar o visual dos perigos M1–M11 no jogo** (usuário 2026-11-28, vendo `art/out/fase2/uso/*.png`: "os perigos existem, mas pelas fotos faltam muitos ajustes visuais, estão bem ruins — pode continuar o fluxo, depois a gente lapida"). Fazer depois de M8/M9: prancha de cada perigo no tema (como a do tubarão) → arte no jogo.
- **Fase 2 · bloco D (contêineres + ARTE DO PALCO no tema: o usuário pediu trocar caixotes/andaimes do canteiro pelos do mar)**, **E (eventos G15–G19)**, **F (entrega)** — ver `DOSSIE.md` §3.
- Desempenho: cartões do HUD (~1,2 ms/quadro constante) — ver `docs/manuais/desempenho.md` §7.

## CONCLUÍDO (últimos; detalhes no "Retomar aqui" do ESTADO)
- 2026-11-28 · M3 onda procedural aprovada; manual de animação; plataformas da cena 1 no tema aprovadas (A57, prancha); kit de passagem de bastão (`COMO_TRABALHAR.md` §8–§9, `PROMPT_UNIVERSAL.md`, `tools/folha_quadros.py`) — sessão 018QUPBQ…
- 2026-11-28 · Fase 2 bloco C: água + perigos M1–M11 no jogo (`--so=agua,m1..m11` verdes; capturas `art/out/fase2/uso/`); visual a lapidar (FILA) — sessões 017desNJ… e 018QUPBQ…
- 2026-11-28 · Fase 2 bloco B: cena viva do Cargueiro (`cena_cargueiro.gd`, `f2_jogo.py`); usuário aprovou a composição — sessão 017desNJ…
- 2026-11-28 · Correções urgentes do Canteiro (A56 regra dos 90 s, caixas no subterrâneo, FPS da G03, controle principal); bateria 623 ok, .exe — sessão 017desNJ…
- 2026-11-28 · Fase 2 bloco A: `.lvl` + manifesto + teste `--so=cargueiro` (2 rotas de verdade) + vitrine `--cargueiro=DIR` — sessão 017desNJ…
- 2026-11-28 · Dossiê da Fase 2 completo e APROVADO pelo usuário (A55) — sessão 017desNJ…
- 2026-11-28 · Protocolo de desempenho (2ª passada) + 2 vazamentos — sessão 017desNJ…
- 2026-11-28 · Projetos de Demolição v2 (A53), Controles (A51), Bots editáveis (A52), HUD vivo (A50) — outro chat
