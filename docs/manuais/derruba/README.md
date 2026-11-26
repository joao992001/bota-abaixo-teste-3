# Modo DERRUBA — regras do modo e acesso aos manuais (VERSÃO 2, 2026-11-25)

> **Atenção:** a versão 2 foi APROVADA pelo usuário em 2026-11-25 (reformulação: rotas por destruição, partida única,
> manômetro, telas de seleção). **A implementação ainda não foi feita** — a coluna "No jogo hoje" diz o que o código faz
> agora. Ao implementar uma linha, atualize a coluna. Registro completo das decisões (aprovado × provisório × pendente):
> [`docs/revisoes/reformulacao_derruba.md`](../../revisoes/reformulacao_derruba.md).

**O Derruba é o modo principal do jogo.** Objetivo: tirar os rivais da arena (KO ao cair do palco ou sair da zona); vence
quem sobra. Dano acumulado (Amassômetro %) aumenta o arremesso. Motor: `game/modes/demolicao.gd`.

## Vocabulário (não trocar os termos)
**JOGO → MODO → MAPA → NÍVEL (profundidade) → CENA → ELEMENTOS.** *Mapa* = experiência temática escolhida no menu.
*Nível* = profundidade dentro do mapa (não é mapa novo nem rodada). *Cena* = arena física de um nível. *Rota Moderada /
Rota Total* = os dois destinos possíveis de uma transição. *Evento/modificação* = ocorrência opcional escolhida na
configuração. *Partida* = uma luta até sobrar um robô.

## Regras do modo (valem para TODO mapa do Derruba)
| Tema | Regra (v2, APROVADA) | No jogo hoje |
|---|---|---|
| **Topologia** | **Mapa pequeno: 3 cenas** (nível 1 Início → nível 2: Moderada ou Total). **Mapa grande: 7 cenas** (1 → 2 → 4: cada cena do nível 2 tem as suas duas). Só avança para o próximo nível; o último nível não tem transição. | **D1 (2026-11-26):** manifesto v2 (`nivel`, `rota_moderada`, `rota_total`, `topologia`, `cenas_pendentes`); Canteiro: Térreo → Fundação (total), Fachada pendente (D5) |
| **Quando verificar** | o **tempo** decide QUANDO: 1ª verificação e intervalo dependem das **vidas** (PROVISÓRIO: 6 → 90 s / 30 s · 5 → 70/23 · 4 → 50/17 · 3 → 30/10); cada cena pode ter tempo próprio; sem cronômetro no HUD; a nova cena zera o tempo | **D1:** `etapas.gd` (`tempos()`, `verificar()`); números em `modos[derruba].destruicao.verificacao` |
| **Para onde ir** | a **destruição elegível** decide PARA ONDE: < 50% fica (verifica de novo no intervalo) · ≥ 50% e < 90% → **Rota Moderada** · ≥ 90% → **Rota Total**. Chegar a 90% antes da verificação não antecipa. | **D1:** igual à regra; 50–90% fica enquanto a rota moderada estiver pendente |
| **Medida da destruição** | soma(peso × HP perdido) / soma(peso) das peças destrutíveis da cena; caída = 100%; peso = largura em tiles (laje ×2); fora: base fixa, pedaços gerados, outras cenas, decoração. Do estado (nada conta 2×). A auditar antes da v2. | igual (`canteiro.progresso(n)`) |
| **Destruição espontânea** | **NÃO existe** (o diretor adaptativo saiu). Destruição "de sorte" só por **evento** escolhido na configuração (ex.: G01 Sirene de Demolição volta como evento). | **D1:** diretor removido; G01 nos eventos do Canteiro |
| **Partida** | **uma luta** até sobrar um robô; **vidas de 3 a 6** (padrão sugerido 4). Chegar a outra cena nunca é condição de vitória. | **D2 (2026-11-26):** uma luta só nos mapas reais (`demolicao.partida_unica()`), vidas 3–6 (padrão 4); mapas-ferramenta seguem em rodadas |
| **Transição** | física e cinematográfica (aviso, desabamento, queda/deslocamento, câmera junto), própria de cada rota; nunca teletransporte | cinemática "a obra cede" pronta (`etapas.gd`), linear |
| **HUD** | só retratos com % de dano + **manômetro circular no topo** (estilo do jogo), destruição da cena atual em 6 zonas (verde → vermelho), zera na troca de cena | **D1:** manômetro no topo (`hud.gd draw_gauge`), 10–90%, traço em 50%, número embaixo; substitui o "RODADA" |
| **Fim da partida** | resultados: ranking 1º/2º/3º, **estrela para o vencedor** (placar da sessão: só o Menu principal zera), destruição da partida (moderada × total → gangorra), exploração (cena nova?) → **Jogar de novo** (mesmo mapa, cena inicial, estrelas somam) · **Configurar mapa** · **Selecionar mapa** · **Menu principal** | **D2:** tela de resultados (`hud._draw_resultados`): ranking por eliminação, estrela da sessão, resumo (destruição final + exploração), 4 opções; gangorra/Projetos na D4 |
| **Fluxo de telas** | JOGAR → MODOS → DERRUBA → MAPAS → SPELLS → EVENTOS → PERSONAGENS/SKINS → PARTIDA → RESULTADOS | **D3 (2026-11-26):** menu → modos → mapas → **spells → eventos** → ajustes (vidas) → entrada; Configurar mapa → spells (`ui/selecao.gd`) |
| **Seleção de spells/eventos** | telas em **mosaico**, por controle, acender/apagar, Aleatório (eventos: também "nenhum"); **tudo liberado por enquanto**. "Nenhum evento" nunca desliga mecanismos da cena. Travas por conta: ver `progressao.md` (futuro). | **D3:** mosaicos de spells (mín. 4, ALEATÓRIO 8 = 2/família, ATACAR tudo/nada) e de eventos (NENHUM, ALEATÓRIO); caixas só sorteiam as acesas |
| **Classes de spell** | Ataque, Controle, Engenharia, Transformação (pesos do sorteio). O mapa não cria classe. | igual (`classes_spells`) |
| **Spells/eventos por mapa** | o manifesto lista o que o mapa permite; a configuração da partida escolhe um subconjunto | **D3:** manifesto ∩ seleção da partida (`main.spells_on`, `events.enabled`) |
| **Eventos × perigos (A14, 2026-11-26)** | **evento = do mapa**, selecionável, acontece em **todas as cenas**; o que é de uma cena só é **perigo/mecanismo da cena** (sem `V#`) | **D3:** tela mostra só eventos do mapa; `V1–V3` sempre ligados como perigos da cena. **Pendente:** cada G# funcionar nas 3 cenas (hoje a cena ainda filtra pela sua lista) |
| **Perigos/mecanismos** | instâncias por cena no manifesto, presas à arquitetura; fazem parte da cena (não são opcionais) | igual |
| **KO** | cair do piso em qualquer ponto = KO rápido; saída para KO em ≥ 2 lados por cena | igual |
| **Skins** | cada jogador escolhe robô e skin; skins têm origem no mapa | igual (X/□ na entrada) |
| **Progressão** | gangorra de recompensas e Projetos de Demolição: **documentados para o futuro** (`progressao.md`) | não existe |

## Manuais do modo
- **Fase (mapa):** [`mapa.md`](mapa.md) — método VALIDADO (obrigatório) · regras de desenho: [`mapa_cartilha.md`](mapa_cartilha.md)
- **Spell:** [`spell.md`](spell.md) · **Evento:** [`evento.md`](evento.md) · **Perigos/mecanismos:** [`perigos_mecanismos.md`](perigos_mecanismos.md)
- **Progressão, desbloqueios e online (futuro):** [`progressao.md`](progressao.md)
- **Perfil salvo local (formato para a D4):** [`perfil_salvo.md`](perfil_salvo.md) — PROPOSTO
- Bibliotecas dos mapas: `docs/fases/derruba/` (Fase 1: [`f1_canteiro/`](../../fases/derruba/f1_canteiro/README.md); modelo: `_modelo/`)

## Histórico de decisões do modo
- 2026-11-25 — `APROVADO` (v2): reformulação do Derruba (rotas Moderada/Total por destruição verificada no tempo, 3 ou 7
  cenas, partida única com 3–6 vidas, manômetro, resultados com estrelas e 4 opções, telas de seleção). Implementação pendente.
- 2026-11-25 — `SUBSTITUÍDO` (pela v2): transição imediata aos 90% + **diretor adaptativo** (destruição espontânea para
  chegar aos 90%). Motivo: a rota passa a depender do mérito dos jogadores; destruição de sorte só por evento escolhido.
- 2026-11-25 — `SUBSTITUÍDO` (pela v2): partida em rodadas com estrelas (3/5/7) → partida única; estrelas viram placar das
  revanches na tela de resultados.
- 2026-11-25 — `SUBSTITUÍDO`: transição **cronometrada** (90 s, `etapas.virada_s`) → 90% de destruição (depois substituído pela v2).
- 2026-11-25 — `APROVADO`: classes de spell no modo; spells/eventos/mecanismos autorizados no manifesto do mapa;
  sem herança silenciosa de spells/eventos entre modos (só mapas-ferramenta recebem tudo, explícito).
