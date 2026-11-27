# Manual — criar uma SPELL (modo Derruba)

> No jogo, o nome que o jogador vê é **ENGENHOCA** (A20, 2026-11-26); "spell" ficou como nome interno.

Spell = item da caixa: 1 por robô, botão de ESPECIAL. 26 aprovadas (A01–T07, ver `NOMES` em `game/modes/spells.gd`).
Princípios gerais: [`../spells.md`](../spells.md). **Classes = do modo** (`modos[derruba].classes_spells`: ataque,
controle, engenharia, transformação). **Disponibilidade = do mapa**: uma spell só sai nas caixas de um mapa se estiver em
`spells_permitidas` do manifesto dele (`data/mapas/derruba/<mapa>.json`). Canteiro: as 26. Laboratório (ferramenta): todas.

## Códigos (renumerados por classe em 2026-11-25; antigo → novo)
| Ataque | Controle | Engenharia | Transformação |
|---|---|---|---|
| S01→A01 Punho Pneumático · S02→A02 Laser de Corte · S03→A03 Canhão Criogênico · S04→A04 Marreta Sísmica · S05→A05 Rebiteira Ricochete · S17→A06 Bate-Estaca · S19→A07 Marreta-Bumerangue · S20→A08 Canhão de Molas | S06→C01 Superímã · S07→C02 Turboventilador · S08→C03 Gancho de Arrasto · S11→C04 Teleporte · S21→C05 Laço de Energia | S10→E01 Andaime Relâmpago · S12→E02 Carga Remota · S27→E03 Controle Remoto | S13→T01 Armadura Fornalha · S14→T02 Mecha Empilhadeira · S15→T03 Bola de Demolição · S16→T04 Propulsor Gambiarra · S31→T05 Modo Broca · S33→T06 Modo Soldador · S34→T07 Minirrobô Veloz |
As texturas de arte mantêm os nomes antigos em minúsculas (`spells/s13_frente.png` etc.): o código só mudou nos dados e no jogo.
**REPROVADAS (nunca voltam):** S09, S22, S23, S24, S26, S29, S30, S32 e, em 2026-11-25, **S18 Disco de Corte, S25 Ponte Dobrável, S28 Escudo de Solda** (código removido).
Armaduras (Transformação) são **raras** nas caixas normais (peso 7) — o momento delas é a **Carga Especial (G10)**.

## 1. Regras de desenho (o que o usuário aprovou — seguir desde a 1ª versão)
1. **Arma tem arte própria** e é carregada com as **duas mãos**; a ferramenta do robô vai para as costas. Ao dar golpe
   normal, a arma vai para as costas e a ferramenta volta. Sem arma: objeto nas costas ou na mão de trás. Nunca um ícone
   balançando.
2. **Tiro/feixe sai do bico real** da arte (`muzzle(r, id)`). Projétil grande, com contorno escuro e rastro.
3. **Segurar** = barra de energia sobre a cabeça (`channel` + `energy`, desenhada por `_draw_bars`) e `bot_hold` para bots.
4. **Precisa de lugar** (teleporte, estaca, ponte…)? Segurar mostra a prévia/holograma e o direcional mira; soltar executa;
   toque rápido = padrão à frente.
5. **Animação em 4 tempos:** preparo visível (carga, tremor, vapor) → ação com mola (passa do ponto) → impacto (achata,
   estrela, faíscas, tremor de tela) → recuperação. Efeito no chão rico (placas, pedras, poeira, anel), nunca só uma linha.
6. **Alcance generoso.** Sem ajuda a quem está perdendo.
7. **Mira em 8 direções** (`aim_vec` / `aim_dir` / `aim_local`): ◄► + ▲/▼ (▼ só no ar); sem nada = frente. Braço e arma
   giram em volta do ombro (`RobotVis.SHOULDER` / `ARM`). Algumas ficam fixas de propósito (marreta sísmica, disco,
   bate-estaca, andaime relâmpago) — decida e escreva no relatório.
8. **Plataformas:** tiros/feixes param em sólido de verdade (`_hard_at`: paredes, chão, blocos, laje, entulho e tapume
   dos eventos); plataformas vazadas (andaimes, vigas, tábuas, ponte) são atravessadas; garras/cargas agarram em tudo
   (`_grab_at`); só o Escudo de Solda (`shield_block`) segura tiro além do sólido.
9. **Transformação = VESTIR a máquina** (molde da Armadura Fornalha): frente/costas/membros/janela do rosto em
   `RobotVis.ARMOR_SETS`, ferramenta que vira braço em `FORM_TOOLS`; antes de usar, o kit fica **nas costas** (`KITS`).
   Veículo separado do robô foi reprovado.
10. Empurrão suave (vento, elástico) via `ext_v` → `push_vx`; golpe de verdade via `r.take_hit(dir, "spell_<nome>", dono)`.

## 2. Onde fica cada coisa
| O quê | Arquivo |
|---|---|
| Números (cargas, preparo, alcance, energia…) e sorteio | `data/modos.json` → `demolicao.spells` (`S##`, `raridade`, `caixa`; `pools.derruba` = só mapas-ferramenta) e `demolicao.modos[derruba].classes_spells` (pesos das classes) |
| Autorização por mapa | manifesto do mapa → `spells_permitidas` (+ `spells.md` da biblioteca do mapa: origem e estado) |
| Dano/empurrão do golpe | `data/modos.json` → `demolicao.amassometro.spell_<nome>` (`dano, kx, kx_por, ky, ky_por`) |
| Lógica | `game/modes/spells.gd`: `NOMES`, `use()` (início), `update()` → `_update_attack2/_etapa3/_etapa4` (quadro a quadro), `_draw()`, `flags()` (o que o visual precisa), `clear()` (limpar tudo), `hud_info()` |
| Visual no robô | `game/player/robot_visual.gd`: `SPELL_TOOLS` + `WEAPONS` (armas), `BACK_PROPS`, `HAND_PROPS`, `KITS`, `ARMOR_SETS`, `FORM_TOOLS`; pose no bloco de spells de `current_pose()` |
| Golpe no robô | `game/player/robot.gd`: `ROBOT_HITS` (golpes de robô que a esquiva protege) e `last_cause` (nome no placar) |
| Bots | `game/modes/bots.gd`: condição `it_ok` por spell (+ `bot_hold` se segura) |
| Arte | `art/src/efeitos/spells.py` → `PIECES` (`python3 art/src/efeitos/spells.py` e `cp art/out/game/spells/*.png game/assets/spells/`) |
| Testes / vitrine | `game/tests/driver.gd`: `spells_test` (`--so=spells`) e `spells_frames` (`--spells=DIR --so-spells=A01+A03`) |
| Laboratório | automático: a linha SPELL lista o que está em `pools` |

## 3. Passo a passo
1. **Ficha curta para o usuário** (antes do código): família (ataque/controle/engenharia/transformação), o que faz,
   toque × segurar, mira, alcance, como o rival reage, desenho da arma/objeto. Confira que não repete uma reprovada.
2. **Dados:** `S##` em `demolicao.spells` com `familia` (uma das classes do modo), `raridade`, `cargas` (ou
   `duracao_s`/`energia_s`) e os números próprios; inclua em `pools.derruba` (laboratório) e em `spells_permitidas` dos
   mapas onde o usuário autorizou (o validador acusa classe fora do modo); se acerta robô, crie `amassometro.spell_<nome>`.
3. **Arte:** função em `spells.py` (papel e giz, peça grande e legível, bico/pegada nos pontos certos) + `PIECES`.
   Gere, abra a imagem e olhe. Arma → `SPELL_TOOLS[id] = [textura, tamanho, pegada, bico]` e `WEAPONS`.
4. **Lógica em `spells.gd`:** nome em `NOMES`; início em `use()` (`prep`, `fire`, `channel`, `energy`, `charges`); o
   quadro a quadro na função da etapa; desenho em `_draw`; estado visual em `flags()`; **tudo o que a spell cria tem que
   ser desfeito em `clear(r)`** (morte, troca, fim de rodada: `spell_lock`, `spell_fly`, corpos, ganchos…).
5. **Golpe:** `r.take_hit(dir, "spell_<nome>", dono)`; acrescente o tipo em `ROBOT_HITS` (se for golpe de robô) e em
   `last_cause`. Respeite `shield_block` e `_hard_at`.
6. **Pose no robô:** caso no bloco de spells de `current_pose()` (preparo → ação → coice), usando a mira
   (`aim_a`) quando houver.
7. **Bot:** regra `it_ok` em `bots.gd` (distância/altura em que vale usar) e `bot_hold` se precisa segurar.
8. **Teste** em `spells_test` (use o `place` que zera vidas/escudos): faz o que promete, respeita parede/plataforma,
   limpa ao morrer. `--so=spells`.
9. **Vitrine:** segmento em `spells_frames` → prancha de quadros-chave → olhe de perto (preparo, ação, impacto,
   recuperação; mira para cima/baixo se tiver). Depois GIF + `.exe`.
10. Atualize `docs/ESTADO.md` e, se surgiu regra nova, a seção 1 deste manual.

## 4. Lições (reprovado → regra)
- Arma de uma mão / ícone balançando → arma de duas mãos com arte própria (1).
- Laço "de borracha" → laço de ENERGIA (o usuário prefere visual elétrico/energia a borracha).
- Transformação como veículo → armadura vestida (9); kit na mão → kit nas costas.
- Jetpack em pulsos → voo segurando com combustível e inclinação.
- Gancho que puxa pouco → puxa quase tudo (robô, caixa, bomba; estrutura puxa você).
- Alcance curto (disco, bumerangue) → mais alcance (6).


## Visual das armaduras (transformações T##) — A29, obrigatório para as novas
Toda armadura é um **mecha humanoide pilotado e ameaçador**: cabeça do piloto visível no cockpit do peito; faixa na cor do jogador no mesmo lugar do casco; ~2× o robô; ombreiras com espetos, fenda de olho vermelha, pés com garras; **silhueta própria** (não repetir corpo); o tema vira o braço-arma da frente ou o corpo todo; papel e giz, brasa/fumaça/faísca quando ligado. Referência: `art/out/robos_v2/armaduras_v2_final.png` (gerador `art/src/robos/armaduras_conceito.py`, função `mecha(...)`).
