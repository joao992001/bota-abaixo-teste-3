# Manual — criar uma FASE (mapa) do modo DERRUBA · MÉTODO VALIDADO (OBRIGATÓRIO)

> **Escopo: modo Derruba.** A **Fase 1 do Derruba (Canteiro de Obras)** foi criada exatamente neste molde, e **todas as
> próximas fases do Derruba têm de ser criadas neste mesmo molde**: mesma ordem, mesmos pontos de aprovação, mesmos
> blocos A–F, mesmo checklist (§5) e o registro de erros (§7) consultado antes de começar. Os outros modos (Batata-Dinamite,
> Rei da Obra, Fuga) ainda não têm método de fase validado: não aplique este sem o usuário pedir.

**Status: validado em 2026-11-25** com a Fase 1 (Canteiro de Obras), que o usuário deu como fechada. O método levou
1 catálogo + 1 prancha + 6 blocos de código + **3 rodadas de correção depois de o usuário jogar**. As 3 rodadas vieram
de erros que estão no **registro (§7)** e que o **checklist (§5)** agora pega antes da entrega. Meta para a próxima fase:
no máximo 1 rodada de correção.

Leia também: **regras do modo** em [`README.md`](README.md) (cenas, rotas 50/90% na verificação por tempo, autorização), regras de desenho em
[`mapa_cartilha.md`](mapa_cartilha.md) e o exemplo completo: biblioteca [`f1_canteiro/`](../../fases/derruba/f1_canteiro/README.md),
manifesto `data/mapas/derruba/canteiro_obras.json` e arte `art/src/cenarios/fase1_*.py`. Skill: `criar-fase`.

## 0. Atualização v2 (APROVADA em 2026-11-25 — implementação pendente; ver `README.md` do modo)
- **Topologia:** escolha na biblioteca do mapa: **3 cenas** (Início → Rota Moderada | Rota Total) ou **7 cenas**
  (Início → Moderada | Total → cada uma com a sua Moderada | Total). Nada de saltar níveis nem 3ª rota.
- **Cada cena de nível intermediário precisa de DUAS transições** (para a Moderada e para a Total), cada uma com
  cinematografia própria coerente com a destruição (ex.: Total = a obra cede inteira; Moderada = desmoronamento parcial que
  leva a outra parte do mapa). Storyboard das duas na prancha.
- **Manifesto v2 (esquema a implementar na etapa D1):** por cena `nivel`, `rota_moderada` e `rota_total` (ids da próxima
  cena; nulos no último nível), `verificacao` opcional {`primeira_s`, `intervalo_s`} que sobrescreve a tabela por vidas;
  validação: árvore (sem ciclo, sem salto, 3 ou 7 cenas, cada intermediária com as duas rotas).
- **Geometria:** cada cena tem área própria no `.lvl` (`etapaN`) e, por transição, o lugar por onde se vai (`buracoN`
  hoje; a v2 terá um por rota).
- **Sem destruição espontânea:** não desenhe a fase contando com o diretor (saiu). A cena precisa ser destrutível pelos
  jogadores em tempo razoável: confira com bots que 50% e 90% são alcançáveis no tempo das vidas padrão.
- Checklist extra: a cena tem as duas saídas bem diferentes e legíveis? O manômetro faz sentido nela (estruturas
  elegíveis suficientes)? "Nenhum evento" não quebra a cena?

## 1. Ordem obrigatória e pontos de aprovação (o usuário aprova cada um antes do próximo)
| # | Entrega | O usuário aprova… | Arquivos |
|---|---|---|---|
| 1 | **Biblioteca do mapa** (copie `docs/fases/derruba/_modelo/` → `fN_<nome>/`) + esquema em imagem: tema, direção artística, **topologia (3 ou 7 cenas, v2)**, por cena estruturas fixas × destrutíveis, perigos/mecanismos, eventos coerentes com a arquitetura, spells autorizadas | tudo isso; o que o usuário JÁ definiu entra como `APROVADO` e não é reaberto | `docs/fases/derruba/fN_<nome>/`, `art/src/cenarios/fN_catalogo.py` |
| 2 | **Fotografia conceitual de CADA cena** (tela de jogo com o elenco), já com a posição e o apoio físico dos principais perigos/mecanismos | composição e visual (é aqui que "não faz sentido" tem de aparecer) | `art/src/cenarios/fN_prancha.py` |
| 3 | **Código em 6 blocos A–F** (§3), cada um testado e com commit | — (só avisar o andamento) | ver §3 |
| 4 | **Vitrine para jogar**: GIF da transição + 4 quadros de cada cena + `.exe` | jogo de verdade; voltam correções | §4 |
| 5 | **Correções** do playtest → atualizar §7 deste manual no mesmo commit | fase fechada | — |

Antes dos passos 2 e 4, passe o **checklist do §5** nas imagens. Não mande sem passar.

## 2. Catálogo e prancha (antes de qualquer código)
- Copie `docs/fases/derruba/_modelo/` (README, cenas/, eventos, perigos_mecanismos, spells, skins, decisoes_testes). Para cada
  cena preencha: ficha (composição, paleta, horário, assinatura, câmera, som), **E** estruturas (marque a BASE FIXA), **D** demolições,
  **M** perigos/mecanismos, **V** eventos (biblioteca + específicos), **A** fundo vivo (C0–C4) e o storyboard da transição. Exemplo: Canteiro.
- Regras do usuário (valem para toda fase): demolições e eventos **aleatórios + dependentes da batalha**; a transição de cena
  é **verificada por tempo** (vidas) e a **destruição escolhe a rota** (v2, §0); eventos são **do mapa** e valem em todas as cenas (A14).
- Prancha: cada etapa numa tela de 2560×1408 (40×22 tiles), com o elenco de `art/src/robos/elenco.py` em ação. **Para cada
  objeto, responda: onde ele se apoia? para que serve no jogo?** Se a resposta for "em nada" ou "para nada", ele sai.

## 3. Código: 6 blocos, nesta ordem (commit por bloco)
| Bloco | O que fazer | Onde |
|---|---|---|
| **A Cenas** | `.lvl` cresce para baixo/ao lado (todas as cenas no mesmo mundo). Props: `etapaN` (col,linha,larg,alt), `koN`, `buracoN` (cols por onde se cai da cena N para a N+1), nascimentos `4·(N−1)+1…4·N`. Manifesto `data/mapas/derruba/<mapa>.json` com `cenas[]` (id, ordem, nome, eventos, mecanismos, estruturas, base_fixa, proxima) — valide com `--so=mapa`. | `levels/<mapa>.lvl`, `data/mapas/derruba/<mapa>.json`; motor pronto: `modes/etapas.gd`, `modes/mapa.gd` (MapaReg), `level.area` |
| **B Cena viva** | Camadas PARADAS saem da prancha (céu, cidade, prédio, fundo e palco da etapa 2) e as peças que MEXEM viram sprites, por um `fN_jogo.py` (copie `fase1_jogo.py`) → `game/assets/<cena>/` → `--import`. Props `cena: <cena>` e `sem_arte_de: <linha>`. Animação em `modes/cena.gd` (generalize as listas da fase1 ao fazer a 2ª fase). | `art/src/cenarios/`, `game/modes/cena.gd` |
| **C Perigos/mecanismos** | Instâncias em `cenas[].mecanismos` do manifesto (tipo, posições em px, ciclo, `alvo` = onde a marretada aciona). Tipos prontos: betoneira, elevador, esteira, tubos, serra (bancada), bate_estaca (torre), agua (cachoeiras), vagonete, gerador. Tipo novo: [`perigos_mecanismos.md`](perigos_mecanismos.md). | `modes/mecanismos.gd`, manifesto |
| **D Demolições** | Estruturas em `cenas[].estruturas` do manifesto: `lajes` (seg_x, núcleo = base fixa, linha), `andaimes`, `vigas`, `pilares`, `terreos` (base fixa), `estacas`, `grelhas`, `piso`, `entulhos` (pedaços que caem da cena anterior). HP em `demolicao.canteiro`. Limitação atual: laje+andaimes+vigas+térreo numa cena só; tipo novo = código em `canteiro.gd`. A transição derruba a cena inteira (`collapse_all(n)`). | manifesto, `modes/canteiro.gd` |
| **E Eventos** | `eventos_permitidos` do mapa + `cenas[].eventos` (G## da biblioteca + V## do mapa). Evento novo: `evento.md`. **Cada evento da biblioteca tem de ser provado NA cena** (o drone G09 travava e era inútil no Canteiro e saiu). | `modes/eventos.gd`, manifesto |
| **F Entrega** | Testes, vitrine `--fase=DIR`, GIF, `.exe`, este manual atualizado, "Retomar aqui" em `docs/ESTADO.md`. | `tests/driver.gd` |

**A transição (motor pronto em `etapas.gd`; não reinventar):** na verificação por tempo, a destruição elegível escolhe a
rota (`verificar()`: ≥ 90% total, 50–90% moderada) → aviso com sirene → `_desaba` (a cena inteira + os mecanismos dela caem;
jetpack, armaduras e kits desligam; caixas de spell vão para cima do piso da próxima cena) → queda **sem controle, lenta**
(`gravidade_queda` 0.35, `queda_vmax` 640) em arco até um ponto com piso embaixo; a câmera **desce junto** já no
enquadramento da próxima cena (`camera_queda_mola`) → `_chega` (KO e área passam para ela; quem ficou fora renasce lá).
Rota moderada com destino AO LADO (Fachada do Canteiro): em vez da queda, todos escorregam num arco (`deslize_s`) até as
pranchas de cima da cena nova, sem controle nem dano, e a câmera vai para o lado junto (`etapas._desliza`).
Para ver: `ROTA=moderada … -- --fase=DIR`. Última cena: sem transição. Regras completas em [`README.md`](README.md).

## 4. Testes, capturas e entrega
- **Durante o trabalho, só a parte mexida:** `--so=mapa` (manifesto válido, spells/eventos/mecanismos por cena), `--so=etapas` (base fixa fora, dano parcial,
  marretada conta, abaixo/no limiar, 90%, desaba, queda sem KO, chegada, jetpack, caixas, última cena), `--so=verificacao`, `--so=mecanismos`, `--so=eventos`, `--so=canteiro`, `--so=bots` (rodadas só de bots precisam
  terminar: é a prova de que há saída para KO), `--so=lab`. Bateria completa **1× no fim**. Nos testes longos verificação e transição ficam
  desligados (`demo_round` → `etapas.ativo = false`); `etapas.forcar()` dispara a transição em vitrines (`--virada=N` no vídeo).
- **Vitrines** (`xvfb-run … -- --fase=DIR`): bots lutando + virada, 1 quadro a cada 4. Monte **uma prancha** com os
  quadros-chave (ex.: 24 quadros da queda em grade 4×6, com PIL) e 4 quadros da etapa 2 em tamanho real — não olhe o vídeo
  todo. Outras vitrines úteis: `--equipa=DIR` (spells nos corpos), `--eventos=DIR`, `--elenco=DIR`.
- **Depois de gerar PNG:** `$G --headless --path game --import` (sem isso o jogo mostra a arte velha).
- **Entrega ao usuário:** GIF da virada (720×405, ~100 quadros, paleta de 128 cores), prancha da etapa 2, `.exe` em zip,
  relatório de até 15 linhas.

## 5. CHECKLIST antes de mandar qualquer imagem ou build (olhe como uma pessoa olhando a tela)
**Composição e ligação com o cenário**
- [ ] Cada objeto **se apoia em algo** (piso, teto, cano, parede): nada pendurado no nada, nenhum poste terminando no ar.
- [ ] Cordas, cabos e trilhos **terminam no teto/estrutura mais próxima**, nunca no topo do mapa (atravessando outra etapa).
- [ ] Lâmpadas só onde há teto; placas presas a algo (penduradas no cano, pregadas na parede).
- [ ] Máquinas **inteiras e apoiadas no chão** (base + corpo), e cada uma faz sentido onde está (serra na bancada, não numa
      passarela solta; nada largado num canto). Sprite espelhado não pode parecer outra ação (a esteira "pulava").
- [ ] Nada desenhado em **paralaxe** que precise casar com o mundo (buraco, céu do buraco, poço): isso vai em coordenadas
      do mundo, senão descola quando a câmera anda.
- [ ] O que fica **entre as etapas** (terra) tem o buraco por onde se cai: ninguém atravessa terra maciça.
- [ ] Água/líquido **se comporta como líquido**: transborda pelas bordas, escorre, tem origem visível. Lâmina parada com
      borda reta parece vidro.
- [ ] Brilho de lâmpada em camadas suaves, não disco chapado.
- [ ] Cada máquina e cada ponto de perigo é lido **em 1 s** (prioridade 4 do CLAUDE.md).

**Regras de jogo do palco**
- [ ] Em toda etapa, **cair do piso em qualquer ponto = KO, rápido**. Palco sobre o vazio, vãos abertos e visíveis. Nada de
      bordas pretas que matam, paredes até o teto ou poço com parede (o robô se agarrava na fresta).
- [ ] Saída para KO em **pelo menos 2 lados** em cada etapa (`--so=bots` termina as rodadas).
- [ ] Renascimento só em **chão firme**; nada de pilar em cima de peça que quebra.
- [ ] Peças, caixas, eventos e inspeções da outra etapa **não entram nos sorteios** (filtro por `etapa`).

**Virada**
- [ ] Base fixa de cada cena marcada e indestrutível; a transição acontece por destruição (90%), nunca por tempo.
- [ ] A câmera não afasta para o mapa inteiro nem pula: um movimento só, para baixo, seguindo o grupo.
- [ ] A queda dá para acompanhar (~2 s), sem controle; ninguém escapa voando (jetpack/armadura) nem fica preso em cima.
- [ ] Mecanismos da etapa 1 caem junto; as caixas de spell chegam na etapa 2; ninguém é eliminado na queda.
- [ ] Sem travadas: câmera em mola + zona morta, tremor pequeno (seno, não ruído por quadro), poucas camadas grandes.

## 6. Economia (o que funcionou)
- Uma fase nova é sobretudo **DADOS + arte**: `.lvl` (geometria das cenas) + manifesto `data/mapas/derruba/<mapa>.json`
  (spells, eventos, mecanismos e estruturas por cena) + biblioteca `docs/fases/derruba/fN_<nome>/`.
  Código novo só para tipo novo de mecanismo, peça ou evento.
- **Não leia arquivos grandes inteiros** (`spells.gd`, `eventos.gd`, `driver.gd`, `robot_visual.gd`, `mecanismos.gd`):
  `grep -n` no ponto de encaixe e edição com âncora única (script Python com `assert old in s`).
- Arte sai da prancha aprovada (mesmas funções); reaproveite os tipos de mecanismo e demolição.
- Uma vitrine por bloco, olhando 4–24 quadros numa prancha. Capturas e testes podem rodar em paralelo.
- Commit por bloco; atualize "Retomar aqui" em `docs/ESTADO.md` ao fim.

## 7. Registro de erros da Fase 1 (o que deu errado, por quê e a regra que evita)
**Processo**
| Erro | Causa | Regra |
|---|---|---|
| Mapa feito direto no código, sem pensar a cena | não havia cartilha nem catálogo | ordem do §1: catálogo → prancha → código |
| 3 rodadas de correção depois do playtest | a composição só foi "lida" pelo usuário | checklist do §5 antes de mandar |
| Evento da biblioteca inútil e travando na fase (drone G09) | evento entrou na lista sem ser provado na fase | bloco E: provar cada evento na fase; senão sai da lista |

**Composição (o usuário reprovou)**
| Erro | Regra |
|---|---|
| Esteira jogada num canto; sprite espelhado parecia pular; caminhão sem função; canto esquerdo confuso | todo objeto responde "onde se apoia / para que serve" |
| Serra em cima de passarela solta | máquina em lugar que faça sentido (bancada no chão) |
| Placa "ALAGA!" e placa de aviso com poste terminando no ar | placas presas a algo |
| Bate-estaca: trilho amarelo saindo pelo topo da tela, sem máquina | máquina inteira apoiada no piso |
| Água parada com borda reta "presa" na borda da laje | líquido transborda/escorre, com origem visível |
| Cordas das tábuas subiam até o topo do mapa (atravessando a etapa 1); lâmpadas penduradas onde não há teto | cordas até o teto mais próximo; lâmpadas só sob teto |
| Céu do buraco em paralaxe descolado do buraco; terra maciça entre as etapas | o que casa com o mundo é desenhado no mundo; poço aberto na terra |

**Jogo do palco**
| Erro | Regra |
|---|---|
| Fundação v1 fechada por paredes até o teto: rodadas de bots não acabavam | KO em 2+ lados; `--so=bots` |
| Bordas pretas que matavam; poço com parede onde o robô se agarrava; 2 buracos (um não funcionava) | palco = lajes sobre o vazio; cair em qualquer ponto = KO |
| Grelha embaixo do pilar central | nada de pilar sobre peça que quebra |
| KO embaixo "flutuando" longe do piso; renascimento sem chão | KO perto do piso (`ko1/ko2`); renascer só em chão firme |
| Caixas de spell paravam em cima do teto da etapa 2 | caixas nascem abaixo do teto (`spells.sky_y`) e são levadas na virada |
| Peças da outra etapa nos sorteios (caixas, ciclo G01, inspeção) | filtrar por `etapa` |

**Virada e câmera**
| Erro | Regra |
|---|---|
| Robôs presos em cima e puxados de repente | queda em arco calculado até um ponto com piso; sem controle |
| Jetpack/armadura na queda escapavam e "bugavam" o jogo | `_desaba` desliga voo, armaduras e kits |
| Mecanismos da etapa 1 continuavam de pé | `mecs.desaba(1)` |
| Queda rápida demais; câmera afastava para o mapa inteiro, ia e voltava e caía de uma vez | queda lenta com velocidade limitada; câmera em roteiro que desce junto, já no zoom da etapa 2 |
| Câmera tremendo/"lag" | mola + zona morta; antecipa só arremesso forte; tremor em seno, pequeno; menos camadas |

**Técnico (Godot/GDScript)**
| Erro | Regra |
|---|---|
| Gravidade dos eventos acumulando quadro a quadro | zerar gravidade/vento ANTES de qualquer saída antecipada em `eventos.update` |
| `_init` como nome de função | é o construtor: use outro nome (`_prepara`) |
| "Cannot infer the type" com `main.algo` | `main` não tem tipo: declare `var x: float = main…` |
| Jogo mostrando a arte antiga | `--import` depois de gerar PNG |
| Teste longo disparava a virada | `demo_round` zera o cronômetro da virada |
| Lambdas de teste capturando objetos já liberados | não reiniciar a rodada no meio de um teste com lambdas vivas |
| `remove_meta(...) if … else null` (void em ternário) | usar `if` normal |
| Spell que nasce no ombro (A08) passou a errar com corpos novos | projéteis "de chão" saem na altura da cintura; conferir `--equipa` ao mudar o elenco |
