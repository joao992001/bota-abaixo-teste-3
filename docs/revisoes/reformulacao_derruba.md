# Reformulação do modo DERRUBA — registro de decisões (V1, 2026-11-25)

Origem: proposta do usuário `proposta_reformulacao_derruba_v1_usuario.md` (nesta pasta) + respostas dele na conversa de
2026-11-25. Este arquivo separa o que foi **APROVADO**, o que é **PROVISÓRIO** (número de partida a calibrar) e o que é
**PENDENTE**. **Nada daqui está implementado no jogo ainda** (Etapa B = só documentação). Regras vigentes de criação:
`docs/manuais/derruba/README.md` (versão 2, com a coluna "no jogo hoje").

## Visão
O Derruba é o **modo principal**. A rejogabilidade vem de: (1) rotas dentro do mapa decididas pela destruição; (2) a
partida configurável (spells e eventos escolhidos em telas visuais); (3) progressão persistente (gangorra de recompensas e
Projetos de Demolição) — esta última documentada para o futuro.

## APROVADO pelo usuário
| # | Decisão |
|---|---|
| A1 | Hierarquia e vocabulário: **JOGO → MODO → MAPA → NÍVEL (profundidade) → CENA → ELEMENTOS**. Não trocar os termos. |
| A2 | **Mapa pequeno = 3 cenas** (nível 1: Início → nível 2: Rota Moderada ou Rota Total). **Mapa grande = 7 cenas** (1 → 2 → 4, árvore: cada cena do nível 2 tem as suas duas). Transição só para o próximo nível; o último nível não tem transição. |
| A3 | **Regra de transição:** o TEMPO decide QUANDO verificar; a DESTRUIÇÃO decide PARA ONDE. Na verificação: < 50% fica e verifica de novo depois; ≥ 50% e < 90% → **Rota Moderada**; ≥ 90% → **Rota Total**. Chegar a 90% antes da verificação não antecipa. Sem cronômetro no HUD. A nova cena zera tempo e medição. Vence por KO; mudar de cena nunca é condição de vitória. Transição física (desabamento/queda/câmera), nunca teletransporte. |
| A4 | **Partida = uma luta** até sobrar um robô (sem rodadas internas). **Vidas ajustáveis de 3 a 6**; o tempo de verificação acompanha as vidas (tabela P1). |
| A5 | **Sistema adaptativo (diretor de destruição) SAI.** Não existe destruição aleatória fora de evento. Destruição por **evento** pode existir (ex.: **G01 Sirene de Demolição** volta como evento selecionável), porque o jogador escolhe ligar os eventos. |
| A6 | **HUD da partida:** só os retratos com % de dano (já existe) + **manômetro circular no topo, no estilo da arte do jogo**, com a destruição da cena atual em 6 zonas de cor (verde → vermelho); zera na troca de cena. Nada de cronômetro, gangorra, exploração ou missão no HUD. |
| A7 | **Fim da partida (tela de resultados):** ranking 1º/2º/3º (ordem de eliminação) e **estrela para o vencedor**; progresso da partida (destruição moderada × total → gangorra); exploração (descobriu cena nova ou ficou na inicial). Opções: **Jogar de novo** (mesmo mapa, recomeça na cena inicial, estrelas vão somando) · **Configurar mapa** (spells, eventos, robô e skin) · **Selecionar mapa** · **Menu principal**. |
| A8 | **Fluxo:** JOGAR → MODOS → DERRUBA → MAPAS → SPELLS → EVENTOS → PERSONAGENS/SKINS → PARTIDA → RESULTADOS. |
| A9 | **Telas de seleção de spells e de eventos ENTRAM AGORA** (mosaico visual, por controle, acender/apagar, Aleatório; eventos com "nenhum"), **com tudo liberado**. Travas por conta, anfitrião e online ficam **documentadas para o futuro** (`docs/manuais/derruba/progressao.md`). |
| A10 | **Canteiro de Obras = mapa de 3 cenas:** Térreo (Início) → **Fundação = Rota Total** (a obra cede inteira, já aprovada) ou **cena nova = Rota Moderada** (conceito a criar e aprovar). |
| A11 | Skins: cada jogador escolhe robô e skin (exceção à autoridade do anfitrião no online futuro). |
| A13 | **Estrelas = placar da sessão** (2026-11-26): continuam em Jogar de novo, Configurar mapa e Selecionar mapa; **só Menu principal zera**. Não são salvas no perfil. |
| A18 | Eventos: **sem máximo** de ligados. Manômetro **mostra o número** (%) embaixo da agulha (2026-11-26). |
| A19 | Card **ALEATÓRIO** das spells acende **8 sorteadas, 2 de cada família**; depois o jogador ainda ajusta (2026-11-26). |
| A12 | Online, contas e sincronização: **não implementar**; só desenhar os dados para o futuro (`CLAUDE.md` continua proibindo online). |
| A14 | **EVENTO × PERIGO DA CENA (2026-11-26):** evento é **do mapa** e selecionável; tem de acontecer em **todas as cenas** do mapa (ex.: um terremoto vale nas 3). O que é específico de uma cena é **perigo/mecanismo da cena** (ex.: a enchente da Fundação, a serra do Térreo), não evento. Os antigos `V#` viram perigos da cena. |
| A15 | Spells na tela de seleção: **mínimo 4, sem máximo** (2026-11-26). |
| A16 | **Manômetro de 10% a 90%** (2026-11-26): abaixo de 10 a agulha fica no começo; em 90 encosta no fim (= Rota Total). 6 zonas iguais: 10–23 · 23–37 · 37–50 (fica) · 50–63 · 63–77 · 77–90. Traço em 50%. |
| A17 | **Gangorra usa a cor do manômetro** em que a partida terminou (cena final). **Partida válida** para pontos = terminou com vencedor e durou **≥ 1 min** (2026-11-26). Deltas por cor seguem PROVISÓRIOS (P3). |

## PROVISÓRIO (aprovado como ponto de partida; calibrar com bots antes de fechar)
| # | Parâmetro | Valor inicial |
|---|---|---|
| P1 | 1ª verificação e intervalo × vidas | 6 vidas: 90 s / 30 s · 5: 70 s / 23 s · 4: 50 s / 17 s · 3: 30 s / 10 s (1ª = 30 s + 20 s por vida acima de 3; intervalo = 1/3 da 1ª). Padrão sugerido: 4 vidas. Cada cena pode ter tempo próprio. |
| P2 | Limiares de rota | 50% e 90% da destruição elegível (fórmula atual por HP e largura — auditar). |
| P3 | Gangorra (−100 a +100) | deltas de exemplo −75/−35/−15/+15/+35/+75 por faixa de cor; **faixas % ainda não definidas**. |
| P4 | Projetos de Demolição | +1 por partida válida, +2 por cena inédita visitada (uma vez); pontos por mapa ainda não definidos. |

## PENDENTE (decidir antes do código da parte correspondente)
- Simetria real da gangorra (deltas por cor, P3) — calibrar com bots.
- Economia: pontos por mapa, recompensas esgotadas, duplicatas.
- Fotografia conceitual da cena FACHADA (conceito aprovado em 2026-11-26).
- Selecionar mapa na tela de resultados: o usuário citou como possível ("poderia até ter") — tratar como incluída, confirmar na prancha.

## Plano por etapas
| Etapa | O quê | Estado |
|---|---|---|
| B | Documentação no GitHub (este arquivo, manuais do Derruba, progressão futura, biblioteca do Canteiro, esquema do manifesto v2) | **feito em 2026-11-25** |
| C | Conceito para aprovar: pranchas das telas (mapas, mosaico de spells, mosaico de eventos, manômetro, resultados), grafos 3/7, storyboard das transições por rota, contrato do perfil salvo, ficha da cena Rota Moderada | **APROVADA 2026-11-26** (`art/out/etapa_c/c1–c7`, `docs/manuais/derruba/perfil_salvo.md`, `f1_canteiro/cenas/fachada.md` — Fachada aprovada) |
| D1 | Lógica: verificação por tempo × vidas, rotas Moderada/Total no manifesto v2, retirar o diretor (G01 volta como evento), manômetro | **feita 2026-11-26** (rota moderada do Canteiro espera a Fachada, D5) |
| D2 | Partida única com vidas 3–6, tela de resultados com ranking/estrelas/progresso e as 4 opções | **feita 2026-11-26** (gangorra e Projetos entram com o perfil, D4) |
| D3 | Telas de seleção de spells e eventos (tudo liberado) + "configurar mapa" | **feita 2026-11-26** (falta: eventos G# valendo nas 3 cenas, A14) |
| D4 | Perfil salvo local (cenas descobertas, pontos, gangorra) — sem contas/online | |
| D5 | Cena Rota Moderada do Canteiro (método de fase `mapa.md`) | |
Cada parte termina com o jogo jogável, testes da parte e commit; bateria completa no fim.
