# Bota-Abaixo — estado do projeto (2026-11-24)

Leia isto primeiro ao retomar o projeto numa sessão nova. Histórico de decisões: `docs/decisoes.md`.
Repositórios (GitHub privado, ramo `main`): `joao992001/bota-abaixo` = versão estável (não mexer) ·
`joao992001/bota-abaixo-teste-2` = cópia anterior (congelada) · **`joao992001/bota-abaixo-teste-3` = cópia para as mudanças estruturais grandes (trabalhe aqui).**

## ▶ Retomar aqui (sessão nova) — atualizado 2026-11-27 (fim da sessão 4)
**Comece por `docs/COMO_TRABALHAR.md`.** Branch de trabalho: `claude/practical-maxwell-hldv9n` (tudo commitado e enviado;
bateria completa 488/488 OK no último commit). O usuário APROVOU todos os visuais até aqui (lotes 1 e 2 + mochila + Corredor).

**▶ SESSÃO 7 (cont.): RECOMPENSAS + MAPAS FEITO — A49** (pranchas `art/out/recompensas/g1–g3, m1`, aprovadas 2026-11-27):
gangorra = A · Balança da grua (`game/ui/fim.gd`, arte `art/src/ui/premio_export.py` → `game/assets/premio/`); caixas sem texto
que dizem o prêmio (skin = figurino com cabide; engenhoca = maleta de aço; evento = caixote com sirene); presente em 5 tempos
(decide → sai de cena → voa ao centro → treme e abre → prêmio grande no pedestal com nome e NOVO; vídeo
`art/out/recompensas/v_gangorra_presente.mp4`). Mapas em grade 3 × 3 com páginas (◄► na borda desliza; `game/ui/menus.gd`).
Skin revelada aparece com o visual padrão até as skins K1–K5 serem refeitas.
**▶ SESSÃO 7: D (combate) FEITO — A47; A (animação dos robôs no jogo) FEITO — A48 (poses das animações aprovadas, cabeça com mola, jeito de andar)** (prancha `combate_r3.png`, vídeo `out/videos/combate_r3.mp4`). Pendências que sobram: C) skins K1–K5. (Os 7 pontos da avaliação de interface JÁ estavam feitos desde a sessão 2 — A22–A26; conferido em 2026-11-27, captura `out/videos/interface_atual.png`.) Perguntar ao usuário qual segue.
**▶ PRÓXIMO PASSO:** Auditoria das engenhocas — ATAQUE CONCLUÍDO (lotes 1–4, A38–A41) e a subida da coluna do A06 REFEITA
(sessão 6, A42: sai de um buraco em 0,35 s, passa do ponto e assenta com tranco, rachaduras escuras, poeira dos dois lados,
o rival sobe COLADO no topo e é lançado aos 60% da subida; colisão cresce junto; faixa zebrada grossa; ícone = cravadeira;
vídeos `out/videos/a06_coluna*.mp4`). **Controle FEITO** (A43: só o C03 Gancho muda — agarrou embaixo/na quina de estrutura alta → sobe por cima; o resto fica).
**Defesa lote D1 FEITO** (A44: classe nova verde/cúpula/capacete; D01 Âncora de Contrapeso, D02 Airbag de Obra passivo;
vídeos `out/videos/defesa_lote1*.mp4`) e **lote D2 FEITO** (A45: D03 Para-choque de Mola; D04 Cortina de Poeira — o
Remendo Rápido foi reprovado; vídeos `out/videos/defesa_lote2*.mp4`) e **lote D3 FEITO** (A46: D05 Capacete de Aço,
D06 Boneco de Teste; vídeos `out/videos/defesa_lote3*.mp4`). Defesa = 6 engenhocas (D01–D06), APROVADAS pelo usuário. **A auditoria das engenhocas (Ataque, Controle,
Defesa) está CONCLUÍDA e APROVADA pelo usuário (2026-11-27).** Próximo: o usuário escolher entre as pendências; pendências antigas abaixo (skins K1–K5, prancha de
combate r2, números provisórios, 7 pontos da avaliação de interface).
**Lição da sessão 5:** arte copiada para `game/assets` só aparece depois de `godot --headless --path game --import`; conferir
SEMPRE de perto (recorte) antes de entregar — o usuário reprovou o lote 3 na 1ª entrega por isso.
APROVADAS em `docs/revisoes/auditoria_engenhocas.md`, seção "Propostas APROVADAS"). Depois lote 4 = A06 Bate-Estaca (vira
lançador: coluna de concreto que lança para cima e fica de plataforma) + A07 (cada robô arremessa a SUA arma). Depois: pedir
ao usuário as notas do CONTROLE (C01–C05; proposta: C04 Teleporte → Defesa) e criar a classe nova DEFESA (ideias levadas:
Âncora de Contrapeso, Airbag de Obra, Para-choque de Mola, Remendo Rápido, Botas Magnéticas; PROIBIDO escudo na mão — S28).
**Fluxo que o usuário aprovou (repetir igual por lote de 2):**
1. Prancha 4 tempos (preparo → ação → impacto → resultado) + arte nova da arma em `art/src/robos/eng_ataques.py`
   (`prancha()` = lote 1, `prancha2()`/`--l2` = lote 2; criar `prancha3()`/`--l3`). Render: `NODE_PATH=$(npm root -g) python3
   art/src/robos/eng_ataques.py --l3` → `art/out/robos_v2/eng_ataques_l3.png`. Mandar ao usuário e ESPERAR aprovação.
2. Código em `game/modes/spells.gd` (+ pose em `game/player/robot_visual.gd`), números em `data/modos.json` (edição
   PONTUAL; nunca regravar o JSON inteiro), arte exportada por `exportar_jogo()` (`--jogo`) no espaço de design 128x64 com
   a pega/bico de `RobotVis.SPELL_TOOLS` → copiar para `game/assets/spells/`.
3. Testes em `game/tests/driver.gd` (`spells_test`), rodar `--so=spells,combate,bots`; captura `--spells=DIR
   --so-spells=ID+...` (há segmentos extras: A01cheio, A02corte) → vídeo com ffmpeg (30 fps = tempo real; 10–12 = lento).
4. Commit + push, registrar decisão (A40…) em `docs/revisoes/reformulacao_derruba.md`, marcar o lote na auditoria.
**Lições desta sessão:** impacto tem que parecer do cenário (poeira cor de concreto, lascas com borda escura — o usuário
reprovou rachadura amarela em zigue-zague e a textura `laje_2` com fita zebrada: peça destruída por engenhoca desaba direto
com `ct._collapse(p)`); tiros saem do bico DESENHADO (`muzzle()` lê o meta "bico" gravado em `draw_robot`); testes que
dependem de sorteio precisam de `seed()` (bots e renascer já têm). A laje cai por TRECHO de 4 tiles; o núcleo nunca cai.

**Feito nesta sessão (decisões A28–A35 em `docs/revisoes/reformulacao_derruba.md`):**
- Elenco A27 no jogo; Guindaste (G2 Lança) e Escavadeira (E2 Trator) refeitos (A28). Ids internos antigos mantidos:
  picareta=Guindaste, chave=Solda, britadeira=Brita, pa=Escavadeira.
- Engenhocas em 3 classes (A31): sai Andaime Relâmpago e Controle Remoto; Carga Remota → Ataque; Propulsor → MECHA JATO.
- ARMADURAS = MECHAS pilotados ameaçadores (A29) com silhueta própria; Bola sem corrente, fica em pé e fecha em bola
  SEGURANDO o especial. Habilidades (A30): Broca dash furando (segurar), Para-Raios (ex-Soldador) raio em cadeia 3 alvos
  + metal, Fornalha fogo de partículas 8 direções, Empilhadeira agarra/arremessa, Jato voa. Tamanho ≈ 2 blocos (A32).
  Modo mecha (A33): atributos recebe/empurrão/causa por mecha (`demolicao.modo_mecha`), golpe LEVE/PESADO próprios.
- Animação ARTICULADA (A34): `RobotVis._draw_mecha` = esqueleto com IK (coxa/canela/pé, braço/antebraço), pé plantado
  (`walk_d`), estilos `MECHA_ESTILO` e golpes `MECHA_GOLPES`. Peças: `art/src/robos/armaduras_export.py` → `game/assets/mecha`.
- Cartucho de Mecha na mão + holograma, ativação cravando no peito, ícones = cartucho, duração +50% (A35).
- Vitrines: `--mechas=DIR` (grava pos.json para recortar; `MECHAS_SO=T07` filtra), `--equipa=DIR` (inclui kits T01–T06). Vídeos em `out/videos/`.
- **Sessão 4 (A36):** T07 Minirrobô Veloz virou **MECHA CORREDOR** (variante A Velocista: pernas-lâmina, aerofólio, escapes).
  Velocidade ×1,7, pulo ×1,15; SEGURAR especial = ARRANCADA (3 s de combustível, sobe parede, atropela). Golpes:
  joelhada-relâmpago (leve) e voadora deslizante (pesado). Arte `art/src/robos/mecha_corredor.py` (prancha) → export `--so=T07`.
  `selecao_test` agora calcula as contagens pelos dados (estava desatualizado desde a A31). Vídeo `out/videos/mecha_corredor.mp4`.
- **Auditoria das engenhocas** (`docs/revisoes/auditoria_engenhocas.md`): Ataque decidido; **lote 1 FEITO (A38: A04 cratera +
  A01 carregado), lote 2 FEITO (A39: A02 feixe que corta, A05 rajada que prega)**; próximos lotes A08+E02 → A06+A07; depois notas do Controle e a classe nova DEFESA.
- **A37:** o mecha vai como MOCHILA nas costas antes de ativar (sai o cartucho na mão + holograma). Vitrine:
  `MECHAS_SO=T07 MECHAS_SEGURA=120 MECHAS_MODELO=0..4 ... --mechas=DIR` (anda carregando, card da seleção, ativação).

**PRÓXIMO passo (esperando o usuário jogar o último .exe):** ajustar o que ele apontar na animação dos mechas
(estilos/golpes em `robot_visual.gd`), depois os 7 pontos da avaliação de interface (`docs/avaliacoes/2026-11-26_interface/AVALIACAO.md`).
**Decisões pendentes:** atributos do Corredor (A36) PROVISÓRIOS até o usuário jogar; skins K1–K5 a refazer no
estilo novo; prancha de combate `r2_combate.png` (A/B) sem resposta; números PROVISÓRIOS (atributos dos mechas, 100/60/35%
do raio, limiares 30/70%). Animações do elenco (robôs a pé) no jogo ainda usam as poses antigas, não as dos vídeos.

---
### Histórico (sessões anteriores)
**REFORMULAÇÃO DO DERRUBA v2 (APROVADA 2026-11-25, etapa B = documentação FEITA):** `docs/revisoes/reformulacao_derruba.md`
(aprovado × provisório × pendente + plano C/D) e regras em `docs/manuais/derruba/README.md` (coluna "no jogo hoje").
**Etapa C ENTREGUE (2026-11-26), aguardando aprovação do usuário:** pranchas `art/out/etapa_c/c1–c7` (gerador
`art/src/ui/etapa_c.py`; quadros reais da Rota Total em `quadros_total/`), contrato `docs/manuais/derruba/perfil_salvo.md`,
ficha da Rota Moderada `docs/fases/derruba/f1_canteiro/cenas/fachada.md` (**FACHADA aprovada** 2026-11-26; Andaime Cede = perigo M13).
**Regra nova A14 (2026-11-26): evento = do mapa, vale em TODAS as cenas; o que é de uma cena só é PERIGO da cena (V1–V3 viram
perigos).** Também aprovados: spells mín. 4 sem máx. (A15), manômetro 10–90% (A16), gangorra pela cor final + partida válida ≥ 1 min (A17). Cada prancha lista o que falta DECIDIR. Fotografia da Fachada e storyboard APROVADOS (2026-11-26). **ETAPA C FECHADA (2026-11-26).** **D1 FEITA (2026-11-26):** verificação por tempo × vidas, rotas no manifesto v2 (Fachada pendente → 50–90% fica), diretor removido, G01 de volta, manômetro no HUD; testes `--so=mapa,etapas,verificacao`. **D2 FEITA (2026-11-26):** partida única (vidas 3–6, padrão 4) no Canteiro; resultados com ranking, estrela da sessão, resumo e 4 opções (`--so=resultados`). **D3 FEITA (2026-11-26):** telas de seleção de spells e eventos em mosaico (`ui/selecao.gd`, `--so=selecao`); caixas só sorteiam as acesas; V1–V3 sempre ligados (perigos). **Pendente da A14:** cada evento G# funcionar nas 3 cenas. **D4 FEITA (2026-11-26):** perfil local (`modes/perfil.gd`), gangorra e Projetos nos resultados, cenas descobertas na seleção de mapas (`--so=perfil`). **A14 FEITA (2026-11-26):** os 11 eventos do mapa valem no Térreo e na Fundação (`--so=eventos_cenas`). **D5 FEITA (2026-11-26): FACHADA no jogo** (cena 3, rota moderada por deslize; perigos M10–M13; 11 eventos; `--so=fachada,moderada`; GIF `art/out/fase1_rota_moderada.gif`). **Reformulação do Derruba v2 (C + D1–D5) CONCLUÍDA.** Próximo: o usuário jogar (playtest) e calibrar os números PROVISÓRIOS (P1 tempos, P3 gangorra, P4/P6 pontos).
**Avaliação do usuário no .exe (2026-11-26):** (1) escolher o mapa direto fechava o jogo → CORRIGIDO (`3b40986`: tela de
spells dependia da partida). (2) Pelo SORTEIO as telas de spells/eventos eram puladas → FEITO: o "?" sorteia o mapa e segue para as mesmas telas. (3) Transição para a FACHADA "parece teletransporte" → REFEITA (a laje vira rampa até a Fachada e todos deslizam por ela). (4) Com 3 vidas a verificação chega cedo / 90% é
exagero → proposta do usuário 30%/70% (fica <30, moderada 30–70, total ≥70) A VALIDAR com mais testes (não mudar ainda).
(5) Layout das telas e a abertura não agradam → direção **A "Canteiro vivo"** escolhida (2026-11-26); pranchas `art/out/menus_v2/` (gerador `art/src/ui/menus_v2.py`): menu, mapas, AJUSTES EM ETAPAS OBRIGATÓRIAS (1 Engenhocas → 2 Eventos → 3 Vidas → 4 Detonar) e abertura — APROVADA (A21: trilha 1 Engenhocas → 2 Eventos → 3 Vidas → 4 Jogadores → 5 Detonar; placas em coluna; abertura com robô sorteado). **CÓDIGO FEITO (2026-11-26):** `ui/obra.gd` (kit), menu com placas, mapas no tapume, 5 etapas (`ui/selecao.gd`), abertura nova (`menus._draw_intro`).
**Spells agora se chamam ENGENHOCAS** para o jogador (A20, 2026-11-26); nome interno no código segue `spell`.
**Entregues ao usuário (2026-11-26):** vídeos `out/videos/canteiro_rota_total.mp4` e `canteiro_rota_moderada.mp4` (captura `--video=DIR --arena=canteiro_obras --virada=16 --rota=… --dur=42` **com `--fixed-fps 60`** + `tools/mixar_video.py`) e o `.exe` (`tools/exportar.sh`; modelos 4.7.1 instalados com checksum). `out/` não vai para o git.
**PAUSA DE 2026-11-25 → leia primeiro `docs/RETOMADA_2026-11-25.md`** (o que foi feito, estado no commit `7556692`, decisões pendentes e verificação).
**LIMPA DE SPELLS/EVENTOS (anotações, NÃO executar sem pedido):** `docs/revisoes/limpa_spells_eventos.md`.
**REORGANIZAÇÃO MODULAR (2026-11-25, branch `reorg-modular` → `main`):** comece por `docs/manuais/README.md`. Conteúdo de
cada mapa no manifesto `data/mapas/<modo>/<mapa>.json` (lido por `game/modes/mapa.gd` = MapaReg); classes de spell no
modo; transição de cena aos 90% de destruição com diretor adaptativo (sem cronômetro); biblioteca da Fase 1 em
`docs/fases/derruba/f1_canteiro/`, modelo em `_modelo/`. Pendente (usuário segurou): mapa de teste com 3 cenas para provar
N cenas (o código já lê etapaN/buracoN/koN; só 2 cenas testadas).
**MANUAIS DE CRIAÇÃO (2026-11-24):** `docs/manuais/` — `personagem.md` (universal), `derruba/spell.md`,
`derruba/evento.md`. Seguir SEMPRE ao criar robô/spell/evento e atualizar quando algo novo for aprovado. Mapa: ainda sem manual
(o usuário acha que o mapa do Derruba não está fechado).
**CARTILHA DO MAPA (PROPOSTA, 2026-11-24):** `docs/manuais/derruba/mapa_cartilha.md` + esquema `art/out/cartilha_mapa_derruba.png`.
Fase = cena viva em 2 atos com virada cinematográfica; camadas C0–C4; palco Z1–Z8; mecanismos por fase; composições.
Conceito APROVADO; virada escolhida = A (a obra cede, todos caem e a luta segue na Fundação). Eventos passam a ser DA FASE.
**CATÁLOGO DA FASE 1 (PROPOSTA):** `docs/fases/derruba/f1_canteiro.md` + `art/out/fase1_canteiro_catalogo.png` —
estruturas E1–E18, demolições D1–D12, mecanismos M1–M9, eventos por etapa (+ V1 Concretagem, V2 Desmoronamento, V3 Enchente),
fundo vivo por camada e storyboard da queda. Regras do usuário: demolições e eventos ALEATÓRIOS + dependentes da batalha;
virada CRONOMETRADA (roteiro fixo). **Prancha de arte das 2 etapas feita** (`art/out/fase1_etapa1.png`, `fase1_etapa2.png`) —
**FASE 1 IMPLEMENTADA (2026-11-24, blocos A–E):** virada cronometrada (`modes/etapas.gd`, `level.area`), cena viva
(`modes/cena.gd` + camadas de `art/src/cenarios/fase1_jogo.py`), 9 mecanismos (`modes/mecanismos.gd`), demolições novas
(escoras, passarela, estacas, grelha/poço, entulho da laje), eventos por etapa + V1–V3. Manual oficial: `docs/manuais/derruba/mapa.md`;
skill `criar-fase`. Vitrine `--fase=DIR`. Aguardando o usuário jogar.
**Ajustes pós-playtest (2026-11-25):** drone G09 fora da Fase 1 (travava e era inútil; só volta redesenhado); spells
encaixadas nos 5 corpos (`RobotVis.shoulder_of`, vitrine `--equipa=DIR`); na virada jetpack/armaduras desligam e caixas
caem pelo buraco; caixas nascem abaixo do teto da Fundação (`spells.sky_y`). Pendente: resposta do usuário sobre a S12
(Carga Remota "acerta em tudo").
**Revisão da Fundação (2026-11-25):** transição com câmera em roteiro e queda lenta; poço na terra; bate-estaca com torre;
água transbordando em cachoeiras + jorros do teto; placas/lâmpadas/cordas presas ao cenário. **FASE 1 FECHADA pelo usuário.**
**Método de fases VALIDADO (2026-11-25):** `docs/manuais/derruba/mapa.md` (ordem com aprovações, checklist §5, registro de
erros §7). Próxima fase: seguir a skill `criar-fase` desde o catálogo.
**SOM — pack aprovado VB integrado (2026-11-25):** movimento (passo, pulo, pulo duplo, pouso, dash), golpes (impacto no robô ×
clang na estrutura, nada no vazio), KO fora da arena (1 explosão + música abaixa) e tema Rock Cartoon em loop. Manual
`docs/manuais/audio.md`; teste `--so=som`; prévia com som `tools/mixar_video.py`. Próximo: packs de spells/eventos/cenário
(o usuário vai mandar); até lá não mexer nesses sons.
G05/G09 ganharam função (caixa na carga + gancho que solta; drone conserta e recolhe) — FEITO.
**ÚLTIMO (2026-11-24): ELENCO NOVO DE 5 ROBÔS** (pedido do usuário: os 8 modelos "olhavam para a câmera e batiam com
uma mão"). Marretão (marreta de 2 mãos), Picareta (pernas de pássaro), Chave (mecânico, chave inglesa), Britadeira
(baixinho, monta na britadeira), Pá (cabeça de cabine; a Garra-veículo foi vetada: SEMPRE humanoides). Fonte única:
`art/src/robos/elenco.py` → prancha `art/out/prancha_elenco5.png` (aprovada) + texturas `robo/*_<robô>` e `modelos.json`
com geometria, pegadas (`tool_grip`, `grip2` = mão de trás no cabo), `especial` e 13 QUADROS-CHAVE por robô (parado, corre,
ar, rapido_prep/rapido, rapido2_prep/rapido2, cima, baixo, pesado_prep/pesado_golpe, esquiva, esquiva_ar). O motor
(`robot_visual.current_pose`) mistura esses quadros no ritmo de `controller.json`; o golpe ACERTA no fim do preparo, então a
descida começa dentro do preparo (no impacto a ferramenta já está a 60–65% do golpe). Especiais: Chave gira 360° na pesada,
Britadeira sobe na britadeira, Picareta dá mortal para trás na esquiva, Pá salta apoiada na pá, Marretão dispara agachado
com a marreta de escudo. Regras do golpe iguais para todos. Vitrine: `-- --elenco=DIR [--so-elenco=0+3]`; prancha do motor:
`--robos=DIR`. `robos.py` agora só gera luva/bota/parafuso/marreta (a da spell S19). Aguardando o usuário jogar.
Pendente de resposta: Carga Remota (S12) "acerta em tudo".

Reforma grande em andamento no `teste-2`, pedida pelo usuário em 2026-11-23, nesta ordem:
1. **Robôs: 8 modelos só de aparência** no lugar da Garagem — FEITO (commit 6b089e1); TROCADOS pelo elenco de 5 (acima).
2. **Movimento, combate e animação** — FEITO (2026-11-24), relatório em `docs/relatorio_personagem_combate.md`.
   Golpe rápido (X/□) × marretada pesada (Y/△, preparo/impacto/recuperação, só ela quebra caixote/chão/barril);
   esquiva (RB/RT) no chão e 1× no ar (volta só ao pousar; protege só de golpe/pisão de robô); arremesso com perda de controle
   curta e retorno gradual; hitstop. Animação por molas em tudo (idle com tique, corrida, derrapagem, pivô na virada, pulo,
   mortal no pulo duplo, esquiva com rastro, golpes com arco, atingido com clarão, giro no arremesso, pouso amortecido) e dano
   no corpo em 3 estágios (`dano1..3_<modelo>.png`, faísca, fumaça, plaquinha solta, parafuso voando). Números: `data/controller.json`
   (`ataque_rapido`, `ataque_pesado`, `esquiva`, `arremesso`, `hitstop`) e `modos.json` (`amassometro.rapido/pesado`) —
   VALORES INICIAIS, a calibrar jogando. Vitrine: `-- --combate=DIR` (quadros → GIF). Testes: `--autotest --so=combate`.
2a. **Ajustes do usuário (2026-11-24):** marretada pesada mais custosa (preparo 0,40 s, lentidão no preparo, recarga própria
   de 0,9 s com marreta acinzentada e "plim" ao ficar pronta) e **cancelável**: golpe do rival no preparo INTERROMPE; a
   esquiva cancela o próprio preparo (finta, paga `recarga_cancelada` × recarga). Pulo duplo refeito: chute com jato →
   cambalhota encolhida no eixo do corpo → abre os braços; pousar no meio termina o giro para a frente (antes desgirava no chão).
   Captura quadro a quadro: `-- --pulo=DIR`.
2b. **LABORATÓRIO** (menu principal) — FEITO (2026-11-24): `game/ui/laboratorio.gd` + `levels/laboratorio.lvl`. Medidores,
   bonecos com comportamento, 32 números ajustáveis ao vivo; o usuário calibra jogando e manda os valores (COPIAR) para virar
   o padrão nos JSON. Ajustes salvos ficam em `user://laboratorio.json` e valem no jogo todo (PADRÃO apaga). Testes: `--so=lab`.
3. **Fases e câmera — Relatório 02** (`docs/relatorio_02_cameras_arenas.md`) — FEITO o núcleo (2026-11-24): `levels/canteiro_obras.lvl`
   + `game/modes/canteiro.gd` (laje/andaimes/viga, estados, colisão, pedaços, ciclo), KO no mundo (`level.ko_rect`, `main.ko_blast`,
   explosão `_draw_ko`), câmera adaptativa (`camera: adaptativa`, números em `demolicao.camera`), fases antigas apagadas,
   Batata/Rei/Fuga EM BREVE. Testes `--so=canteiro` (13). Vitrine `--canteiro=DIR`. PENDENTE: IA dos bots em arena aberta
   (caem sozinhos ~40-70% das mortes: freiam tarde na beira, ficam em trecho que cai, recuperação fora do palco); indicador de
   robô fora da tela (só se o teste pedir); calibrar números jogando. Fases só de teste: demolicao, canteiro, mare, piramide.
   Decisões do usuário (2026-11-24):
   - Apagar TODAS as fases do Derruba no teste-2 (e `tools/mapas/`, prévias `ui/arena_*.png`); Batata, Rei e Fuga ficam
     "EM BREVE" no menu (bloqueados). LABORATÓRIO continua (a OFICINA foi incorporada nele em 2026-11-24). Fazer a remoção JUNTO com a entrada do Canteiro.
   - Arena-piloto **Canteiro de Obras** (Derruba), **opção A**: mundo 40x22 tiles (~1,3x a tela), câmera ADAPTATIVA
     (enquadra todos os vivos, antecipa arremesso forte pela velocidade, zoom limitado, nunca decide o KO).
   - **KO no mundo** nos 4 lados (inclusive em cima), declarado no .lvl (`ko:`), sem paredes invisíveis no Derruba;
     espinhos opcionais. Animação de KO: voa girando com rastro → explosão cartoon na linha de KO → peças/parafusos.
   - **Laje central em 6 trechos de 4x2 tiles** (cols 8..31, topo na linha 13): os 2 do meio (núcleo, sobre pilares)
     NUNCA caem; os 4 de fora (sobre escoras) caem DE VEZ. Andaimes (cols 3-7 e 32-36, topo linha 10 = 3 tiles acima)
     e viga pendurada (cols 16-23, linha 8 = 5 tiles acima) também caem de vez. Destruição permanente até o fim da
     rodada; no fim sobra só o núcleo.
   - Estados do trecho: íntegro → rachado → crítico (fita zebrada, treme, range, solta pedrinha) → desaba (pedaços com
     física); a colisão some no quadro em que começa a cair. Gatilhos: SÓ golpes fortes (marretada pesada) + robô
     arremessado batendo forte; ciclo da obra (sirene + luzes + fita zebrada marcando o trecho que vai ceder),
     alternando calma e atividade. Números iniciais no modos.json e no LABORATÓRIO.
   - Arte aprovada: `art/src/cenarios/canteiro_derruba.py` (laje em 3 estados, pedaços, pilares, escoras, andaimes, viga,
     fundo) e pranchas `art/out/prancha_canteiro_derruba_*.png`; robôs por cima: `-- --prancha=DIR`.
   - Ordem: KO + câmera + animação de KO → laje em trechos → gatilhos/ciclo → andaimes/viga → remover fases/EM BREVE →
     testes 2–4 jogadores + bots → GIF + .exe. Priorizar animação/visual da destruição (é a referência dos mapas).
   - Entrega final no formato da seção 11 do relatório (estado anterior, mudanças, parâmetros, testes, pendências, como testar).
4. **Spells + eventos — Relatório 04** (arquivo do usuário; decisões abaixo). Itens e eventos antigos APAGADOS (código, arte,
   testes; sobraram só `itens/dinamite.png` da Batata e `itens/capacete.png` do Rei). **Etapa 1 FEITA (2026-11-24):**
   `game/modes/spells.gd` (caixa mostra a FAMÍLIA, sorteio família→spell com raridade, slot único, encostar pega com slot
   vazio, SEGURAR especial ~0,3 s sobre outra caixa troca e a antiga cai com as cargas e anti-recaptura, toque = usa, eliminação
   limpa) + S01 Punho Pneumático, S03 Canhão Criogênico, S06 Superímã, S10 Andaime Relâmpago, S11 Teleporte, S13 Armadura
   Fornalha (o robô veste a fornalha, rosto na vigia). **Revisão 1 do usuário (2026-11-24) aplicada:** punho com braço de
   tesoura + luva (sai com mola, achata no impacto); canhão volta a CONGELAR (bloco de gelo facetado, agitar ◄► quebra mais
   rápido, golpe no congelado estilhaça com empurrão extra; gelo no chão removido); ímã = 1 carga, SEGURAR puxa todos à frente
   (redemoinho) enquanto a barra dura; andaime arremessado como trouxa que desdobra (tábua em 3 partes + pernas tubulares);
   teleporte = SEGURAR mira (holograma do robô) e SOLTAR vai (vira fio de luz e se remonta); armadura: toque veste, SEGURAR
   solta um jato contínuo com barra de combustível e, acabou, EXPLODE. `game/modes/eventos.gd` novo: aviso→ativo→término, intensidade
   DESLIGADOS/BAIXA/NORMAL/ALTA; G01 Sirene de Demolição (= ciclo do Canteiro, agora disparado pelo evento) e G10 Carga
   Especial (holofotes + 2 cápsulas de paraquedas). Números: `modos.json → demolicao.spells`, `demolicao.eventos`,
   `amassometro.spell_*`. Arte: `art/src/efeitos/spells.py`. Testes `--so=spells` (26). Vitrine `-- --spells=DIR`.
   LABORATÓRIO absorveu a Oficina (removida): DAR SPELL, CAIXA DO CÉU, CAIXAS AUTOMÁTICAS, EVENTO AGORA, ARENA, BOT e os
   números das spells ao vivo; medidores escondem com VOLTAR (B/○, Backspace) ou H.
   **Etapa 1 APROVADA pelo usuário (2026-11-24, "todos muito aprovados").**
   **Etapa 2 FEITA (2026-11-24), aguardando aprovação:** S02 Laser de Corte (mira tracejada → feixe que atravessa robôs, solda
   na parede), S04 Marreta Sísmica (só no chão; marreta gigante dourada; onda pela superfície contínua, para em buraco/parede;
   pular escapa), S05 Rebiteira (rebite reto, ▲/▼ 45°, até 2 ricochetes), S17 Bate-Estaca (faixa zebrada → estaca desce e
   lança para cima, danifica peça do Canteiro), S18 Disco de Corte (rola no chão, bate e volta para a mão), S19
   Marreta-Bumerangue (sem pesada enquanto voa, volta garantido), S20 Canhão de Molas (mola saltitante, BOING forte).
   **Revisão 2 do usuário (2026-11-24) aplicada:** armas carregadas com as duas mãos (marreta vai para as costas; ao
   golpear, a arma vai para as costas), objetos de spell nas costas/mão (marreta sísmica, trouxa do andaime, fornalha,
   disco, controle remoto do bate-estaca); tiros saem do bico de cada arma (`muzzle`); feixe do laser refeito; marreta
   sísmica com arte própria e tremor rico (placas do piso levantando, rachadura incandescente, pedras, anel de choque);
   rebiteira e rebite novos; bate-estaca com mira segurando (como o teleporte); disco e marreta-bumerangue com mais alcance.
   **Etapa 2 APROVADA pelo usuário (2026-11-24, "todos muito bom").**
   **PADRÃO DAS SPELLS (lições das revisões — seguir desde a 1ª versão, para evitar retrabalho):**
   1. Arma = arte própria (SVG em `art/src/efeitos/spells.py`) em `RobotVis.SPELL_TOOLS` + `WEAPONS`: carregada com as 2 mãos,
      marreta nas costas; ao golpear, arma nas costas. Sem arma: objeto em `BACK_PROPS`/`HAND_PROPS`. Nunca ícone balançando.
   2. Tiro/feixe sai de `muzzle(r, id)` (bico real da arte). Projétil grande, com contorno escuro e rastro: fácil de ler.
   3. Segurar = barra de energia sobre a cabeça (`channel` + `energy` + `_draw_bars`) + `bot_hold` para bots.
   4. Precisa de lugar? Segurar mira com o direcional (prévia/holograma), soltar executa; toque = padrão à frente.
   5. Animação: preparo visível (carga, tremor, vapor) → ação com mola (passa do ponto) → impacto (achata, estrela,
      faíscas, tremor de tela) → recuperação. Efeito no chão rico (placas, pedras, poeira, anel), nunca só uma linha.
   6. Alcances generosos (o usuário pediu mais alcance em disco e bumerangue). Sem ajuda a quem perde.
   7. Conferir 1 prancha de quadros-chave antes de entregar; GIF + .exe no fim.
   8. **Mira em 8 direções** (2026-11-24): `aim_vec`/`aim_dir`/`aim_local` — ▲/▼ (▼ só no ar) somam com ◄►; sem nada =
      frente. Braço e arma giram em volta do ombro (`RobotVis.SHOULDER/ARM`), bico idem. Segurar = a mira gira aos poucos.
      Aplicado: punho, laser, gelo, rebiteira, ímã, ventilador, gancho, laço, bumerangue, jato da fornalha; mola 3 ângulos;
      carga com ▲/▼ é arremessada e gruda; escudo com ▲ vira teto; ponte com ▲ vira rampa; controle remoto ▲ troca a viga;
      teleporte 7 tiles. Ficam fixas: marreta sísmica, disco, bate-estaca, andaime relâmpago.
   9. **Plataformas:** `_hard_at` (paredes, chão, blocos, laje) para tiros e feixes; plataformas vazadas (andaimes, vigas,
      tábuas, ponte, andaime relâmpago) são atravessadas por tiros; `_grab_at` (gancho/carga) agarra em tudo; o que rola
      usa a plataforma como chão vindo de cima; só o escudo de solda segura tiro além do sólido.
   **Etapa 3 FEITA (2026-11-24), aguardando aprovação:** S07 Turboventilador (segurar, cone de vento com rajadas, empurra
   sem tirar o controle), S08 Gancho (▲ 45°; parede puxa o dono, rival leva tranco), S21 Laço Elástico (liga os dois; esticado
   puxa ambos), S12 Carga Remota (instala, arma em 0,5 s, 2º toque detona; danifica o Canteiro), S25 Ponte Dobrável (painéis
   desdobrando sobre o vão, prévia), S27 Controle Remoto (derruba a viga pendurada mais perto; acerta quem está embaixo),
   S28 Escudo de Solda (placa soldada que bloqueia tiros, 3 acertos). Empurrões suaves via `ext_v` → `push_vx`.
   **Revisão 3 (2026-11-24) aplicada:** gancho puxa QUASE TUDO (robô vem arrastado até você, caixa de spell e bomba vêm
   voando para a mão, estrutura puxa você), corrente de elos e garra que abre/fecha; laço virou LAÇO DE ENERGIA (esfera elétrica, algemas
   de energia e raio entre os robôs; emissor com bobinas — o usuário recusou o visual de borracha); muro de solda em 3 painéis que encaixam um por um
   (cordão de solda esfriando, maçarico com faíscas, racha e cai em pedaços; teto abre do meio para os lados); ventilador com
   anéis de pressão, sucata voando, hélice girando, dono escorregando e rival tremulando; ponte encosta na altura exata do
   chão (dá para andar sem pular); controle remoto mostra receptor piscando em cada viga + dica; no Laboratório avisa para
   trocar a arena para CANTEIRO.
   **Etapa 3 APROVADA (2026-11-24).** **Etapa 4 REFEITA (2026-11-24) após crítica dura do usuário** ("pior entrega"): transformação = o robô VESTE a
   máquina (molde da Fornalha). `RobotVis.ARMOR_SETS` (frente/costas/membros/janela: vigia, cabine ou visor) +
   `FORM_TOOLS` (a ferramenta vira o braço e mira em 8 direções). Antes de usar: miniatura da máquina na mão
   (HAND_PROPS). S14 armadura-cabine com santo-antônio, rodas nos pés, mastro e garfo na frente; S15 bola (aprovada) agora
   com cascas fechando; S31 armadura laranja com vigia e BROCA-BRAÇO girando (▼ no chão fura para baixo); S33 armadura de
   soldador com VISOR verde que acende e maçarico-braço; S34 raio encolhedor (anel escaneando de cima a baixo) + vultos de
   velocidade; S16 virou JETPACK DE VOO (segurar = voar com combustível, ◄► pilota inclinando, ▲ sobe mais, ▼ desce
   devagar; `robot.spell_fly` desliga a gravidade). Aguardando aprovação.
   **Laboratório simplificado (2026-11-24, pedido do usuário):** fase de teste pequena e DESTRUTÍVEL
   (`levels/laboratorio.lvl`, Canteiro no layout "lab": laje em 6 trechos com núcleo fixo, 2 andaimes, 2 vigas penduradas,
   vão + plataforma firme + parede à direita). Menu curto: SPELL, EVENTO, BOTS, BONECOS, BONECO FAZ, REINICIAR FASE,
   INVENCÍVEL, CÂMERA LENTA, MEDIDORES, SAIR. Saíram: números ao vivo/SALVAR/COPIAR/PADRÃO, hitbox, régua, troca de arena.
   **Kits nas costas (2026-11-24, pedido do usuário):** antes de usar, toda transformação fica como a Fornalha — peça de
   costas no meio das costas, placa da frente dobrada espiando no ombro (reconhece a máquina) e alça com fivela pelo
   peito (`RobotVis.KITS`); bola presa nas costas; raio encolhedor de pé com o prato sobre o ombro.
   **Etapa 5 — eventos globais (2026-11-24):** os 12 eventos em `modes/eventos.gd` (aviso com o LUGAR marcado → ativo →
   fim/restauração). Agendador com até `max_simultaneos` (baixa 1, normal/alta 2) eventos COMPATÍVEIS (matriz `conflitos`
   em `demolicao.eventos`) e `intensidade` [0, .7, 1, 1.35] que escala força/quantidade. Estrutura (Canteiro): G05 carga do
   guindaste desce e vira plataforma (trava solta antes de subir); G12 deques dos andaimes sobem/descem com correntes
   (`canteiro.move_part`, corpo AnimatableBody2D); G13 viga cai na faixa vermelha, vira plataforma no chão e o guindaste
   pendura de volta; G09 drone vistoriador carimba ✓, estrutura reforçada (`canteiro.damage` ignora) e máquinas da arena
   param. Universais: G06 entulho cai nas sombras e vira cobertura (marreta quebra, some em 14 s); G11 tapume sobe na faixa
   zebrada (empurra quem está dentro, bloqueia tiros via `events.hard_at`); G02 3 exaustores na borda da CÂMERA + setas
   (vento com teto; no chão pesa 0,55); G03 medidor G + porcas flutuando; G04 bobina com campo e pulsos (teto com o ímã);
   G14 faixas vermelhas por onda (≤45% da tela, 1 acerto por robô por onda). Golpes do ambiente: `evento_*` no Amassômetro,
   sempre `by = -1`. HUD mostra até 2 avisos lado a lado. Teste: `--so=eventos`; vitrine: `--eventos=DIR --so-eventos=G02+G05`.
   Arte: g02_exaustor/helice/grade, g04_bobina, g05_carga/moitao, g06_caixa/sucata, g11_tapume, g14_rebite, g09_drone.
   Aguardando aprovação. REJEITADOS (nunca reintroduzir): S09,S22,S23,S24,S26,S29,S30,S32; G07,G08,G15,G16,G17,G18.
**Economia (pedido do usuário):** mesma sessão sempre, salvo motivo plausível (2026-11-26); sessão principal faz tudo (agentes só para lotes grandes
de arte em paralelo); rodar só a parte dos testes que mudou (`--so=`) e a bateria completa 1× no fim; poucas capturas.
**Ambiente na nuvem:** Godot 4.7.1 + modelos de exportação não vêm instalados; baixe de github.com/godotengine/godot/releases
(`Godot_v4.7.1-stable_linux.x86_64.zip` e `..._export_templates.tpz`, extrair só `windows_release_x86_64.exe`,
`linux_release.x86_64` e `version.txt` para `~/.local/share/godot/export_templates/4.7.1.stable/`). Arte: `pip install cairosvg`.

## O que é hoje
Party game de briga e plataforma, **2–4 jogadores locais** (teclado e controles), com bots. Tudo roda no modo interno
`demolicao` (código em `game/modes/demolicao.gd`); o antigo modo de peças com dono foi removido em 2026-11-20.
- **4 modos (sem submodos; o Clássico de peças foi removido):** fluxo Modo → Arena do modo → Ajustes do modo → Entrada.
  - **Derruba** (vidas 1–5, dano %): Canteiro, Guindastes, Gangorras (serraria), Esteiras, Prensa (ferro-velho), Fornalha (fundição).
  - **Batata-Dinamite** (pavio curto/normal/longo; encostar ou marretar passa; 44×24, sem espinho): Obra de Concreto (portas que trocam), Galerias da Mina (túneis e tubos), Prédio Velho (alçapões), Sob o Viaduto (plataformas e ventilador), Palafitas (gangorras), Telhados (trampolins).
  - **Rei da Obra** (capacete de ouro no `K`; 20/30/45 s; golpe derruba; 1,2 s de proteção; 44×24): Trono do Canteiro, Linha de Montagem, Rei do Cais, Mina de Ouro, Serraria Real, Prédio em Demolição.
  - **Fuga** (tela/lama persegue; cair só atrasa; pego pela tela sai; elevador `E` vence): Torre, Obra Subindo, Descida da Fundição (tela desce), Viaduto em Obras, Ferro-Velho, Pântano Subindo.
  - Regras e listas em `data/modos.json` (`demolicao.modos`); bots sabem cada modo (`modes/bots.gd`: `_climb` + busca de caminho `_nav_step`).
  - Fases geradas por `tools/mapas/` (gerar.py, variedade.py, fuga2.py). Antigas (Paiol, Galpão, Andaime, Bola, Laje, Pirâmide, Ponte, Maré) ficam em levels/ mas fora das listas.
- **Spells (Relatório 04, Etapa 1):** caixas por família (ataque/controle/engenharia/transformação), 1 slot, botão ESPECIAL;
  6 spells (S01, S03, S06, S10, S11, S13). **Eventos:** G01 Sirene de Demolição e G10 Carga Especial, intensidade nos AJUSTES.
  Amassômetro (dano % aumenta o empurrão); aderência limitada na parede/borda com medidor.
- **Temas de arena:** Canteiro, Fábrica, Porto e Cidade à noite (blocos, tábuas e fundo animado por tema; `tema:` no .lvl).
- **Robôs: 8 modelos só de aparência** (Lata, TV, Baixinho, Pescoção, Brutamontes, Varapau, Barril, Bolha), na cor do jogador; ▲▼ na entrada.
  Garagem, chapéus, padrões, itens de rosto e ferramentas foram removidos (2026-11-23). Prancha: `-- --robos=DIR`.
  A cor do jogador só identifica (setinha "P1" acima da cabeça, placar). Bots sorteiam um robô.
- **Interface (estilo cartoon, escolhido entre 3 propostas):** kit em `game/ui/kit.gd` (cartões com contorno grosso e
  sombra dura, títulos contornados, estrelas desenhadas). Cartões dos jogadores EMBAIXO na partida (retrato redondo
  `ui/retrato.gd`, estrelas, % grande, item no selo; ficam translúcidos quando um robô passa por trás). Placar em ranking,
  vitória com o nome do robô. Captura de apoio para novas propostas: `-- --maquete=DIR`.
- **Menus:** intro animada, cenário próprio do menu, LABORATÓRIO (painel de testes: medidores que somem com VOLTAR/H, spells, caixas, eventos, arena Laboratório/Canteiro, bots, bonecos, números ao vivo), opções (vibração, testar/configurar controle).
- **Arte:** personagens e cenário em **papel e giz** (recorte sem contorno preto, textura de giz, bordas tremidas; definido no chat
  de 2026-11-20 com versoes.png). Só a **interface** usa contorno grosso e sombra dura (`ui/kit.gd`). Tudo gerado por código em
  `art/src` (SVG → PNG pelo Chromium, `tools/render_svg.js`), cópias em `game/assets`. **Som:** `tools/sfxforge.py` (efeitos, com acabamento) e `tools/musica.py` (compositor de músicas longas).

## Como rodar e testar
- Jogar: `godot --path game` · bateria de testes: `godot --headless --path game --fixed-fps 60 -- --autotest` (199 verificações, 0 falhas).
- Só uma parte: `-- --autotest --so=spells,canteiro,parede` · ritmo com bots: `-- --stats=4`.
- Capturas: `-- --espiar=DIR,arena,modo,segundos` (bots, foto a cada 10 s), `-- --menus=DIR`, `--spells=DIR`, `--lab=DIR`, `--intro=DIR` (com xvfb-run e `--rendering-driver opengl3`).

## Como gerar o executável (IMPORTANTE)
- Exportar com a **mesma versão da Godot do editor do usuário: 4.7.1**. Exportado na 4.3, o controle DualShock/DualSense
  não funcionava (a partir da 4.5 os controles usam SDL3). A 4.7 também grava o ícone no `.exe`.
- Linux/cloud: `GODOT=/caminho/godot-4.7.1 tools/exportar.sh` (exporta numa cópia temporária, leva `data/` e `levels/`,
  gera `out/build/windows/Bota-Abaixo.exe`, `out/build/linux/...` e o instalador `out/Instalar-Bota-Abaixo.exe` via makensis).
- Windows: `exportar_windows.bat` (ajustar o caminho da Godot dentro dele).
- Depois de exportar: rodar a bateria no executável Linux numa pasta vazia (`./Bota-Abaixo.x86_64 --headless --fixed-fps 60 -- --autotest`).

## Pendências e próximos passos
1. Reforma do `teste-2` (ver "Retomar aqui").
2. Rodada de teste com amigos → lista de ajustes; fechar o escopo do beta.
3. Atualizar o `docs/plano.md` (ainda descreve os 4 marcos do jogo antigo de peças) e o `docs/estilo_visual.md` (seções de robôs e
   contorno são da v2; a verdade atual está no topo dele e nas skills).
4. Depois do beta: inglês, Steam, demo/Next Fest, online por convite (Steamworks/GodotSteam). Online ainda proibido no `CLAUDE.md`
   até o usuário liberar.
