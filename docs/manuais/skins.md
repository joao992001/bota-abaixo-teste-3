# Manual — SKINS

**Estado do recurso:** `APROVADO` (2026-11-25) — escolha na ENTRADA, depois de modo e mapa. Loja, desbloqueio ou
progressão continuam **não autorizados**. O elenco implementado tem **5 robôs** ("15 robôs" é perspectiva, não quantidade implementada).

## Regras aprovadas (2026-11-25)
1. Personagens continuam **globais**. A **origem e a direção visual** de uma skin pertencem ao **MAPA** (nunca ao modo).
   Ex.: uma skin temática de um mapa "Hollywood" seria concebida na biblioteca desse mapa, sem criar personagem novo.
2. Skin **não altera** hitbox, dano, mobilidade nem equilíbrio. Zero efeito de jogo.
3. Preserva a **identidade e a silhueta** do robô e a **legibilidade da cor do jogador** (P1–P4).
   **Skin = fantasia completa (aprovado 2026-11-25, Canteiro v2):** o uniforme pode cobrir o tronco inteiro, a ferramenta
   ganha acabamento temático e acessórios grandes (capacete, lanterna, máscara, santo-antônio); a **cor do jogador vai para
   o capacete/cabine grande** e continua nos braços e pernas. Mudança sutil (adesivos, faixinhas) foi REPROVADA.
4. Compatível com ataques, ferramenta, armas, spells, armaduras/transformações, expressões e dano visual.
5. Duas aprovações: **arte** (prancha estática) e **aplicação em movimento** (GIF com as 13 poses e spells).

## Skins v2 (2026-11-27): 3 por robô, estilo atual
Geradores: `art/src/robos/skins_v2.py` (K1, amostra) e `art/src/robos/skins_lote.py` (lote de 15 + `--jogo`). Biblioteca: `docs/fases/derruba/f1_canteiro/skins.md`.

## Exemplo aprovado (v1, elenco antigo — substituído pelas v2)
Canteiro de Obras (K1–K5): `art/src/robos/skins_canteiro.py` → `art/out/prancha_skins_canteiro.png` (recorta o uniforme no
contorno do tronco, troca capacete e ferramenta por cima do desenho do robô).

## Como funciona no jogo (aprovado 2026-11-25)
- Ordem das telas: **modo → mapa → ajustes → entrada dos personagens**. Na entrada, **X/□ (golpe rápido)** alterna entre
  "visual padrão" e as skins que **nasceram no mapa escolhido** para aquele robô (`main.skins_do_robo`); trocar de robô volta
  ao padrão; "sorteio" num modo de mapa único usa esse mapa. O cartão mostra "✦ NOME DA SKIN".
- Na partida, `robot_visual.skin = "k#"` troca só as texturas `corpo_<robô>_<k#>_p<cor>.png` e `ferramenta_<robô>_<k#>.png`
  (geradas por `art/src/robos/skins_canteiro.py --jogo` → copiar para `game/assets/robo/` → `--import`). Bots: padrão.
- Teste: `--so=skins`. Vitrines: `--elenco=DIR --skins`, `--equipa=DIR --skins`, tela `--menus=DIR` (m5_entrada).

## Skin nova num mapa: onde registrar
- Biblioteca do mapa de origem: `docs/fases/<modo>/<mapa>/skins.md` (id, robô, conceito, estado, compatibilidade).
- Manifesto do mapa: `skins_originadas` (ids). A implementação (camadas de arte por modelo em `art/src/robos/`) será
  especificada aqui quando o usuário aprovar o sistema.
