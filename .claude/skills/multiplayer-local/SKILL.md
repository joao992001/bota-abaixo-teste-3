---
name: multiplayer-local
description: "Entrada de 2–4 jogadores locais em Bota-Abaixo na Godot 4: tela de entrada, um dispositivo por jogador, teclado dividido, controles (SDL3), bots, escolha de cor e de modelo de robô. Use para qualquer coisa de input e entrada de jogadores."
---

# Multiplayer local

- Autoload `PlayerInput`: cada jogador tem um `device` (índice do controle ou `TECLADO_A`/`TECLADO_B`). O jogo pergunta sempre `PlayerInput.pressed(jogador, acao)`; nunca lê o dispositivo direto.
- Teclado A: WASD + G/Espaço pula · H golpe · J pesada · Y esquiva · U especial. Teclado B: setas + numérico 1–5 (notebook: K L Ç O P), Enter do numérico pausa. **Nunca usar Shift/Ctrl**: no Windows, com NumLock ligado, as setas mandam Shift "fantasma". Teclas lidas por evento (código físico = posição, vale para qualquer layout).
- **Controles (2026-11-28):** modelo reconhecido pelo fabricante/produto (`PlayerInput.pad_model`: ps5/ps4/xbox/switch/gen; fallback pelo nome). Mapeamento **por aparelho** (`dev_key`: GUID#ordem entre controles iguais; "kb_a"/"kb_b"), ação → [principal, alternativo], em `user://controles.cfg`. Telas em OPÇÕES ▸ CONTROLES (central, MAPEAR, TESTAR) em `game/ui/menus.gd`; ícones/controles em papel e giz `game/ui/glifos.gd` (arte: `art/src/ui/controles_export.py`). Menus andam por `nav_*` (mapeado OU analógico/direcional/teclas de fábrica).
- Ações: `mover_x`, `mover_y`, `pular`, `marreta`, `girar`, `confirmar`, `voltar`, `pausa`.
- **Entrada:** qualquer botão de um dispositivo livre ocupa o próximo slot; cada jogador escolhe **cor** (4) e **modelo de robô** (8); Start com 2+ começa.
- **Bots:** na entrada, Y/△ (ITEM) adiciona; nível de dificuldade por bot; código em `game/modes/bots.gd`.
- Código: `game/autoload/player_input.gd`; a entrada fica em `main.gd` (`_join_update`, `add_player`, `cycle_robot`).
- Controle desconectado: pausa com aviso; reconectar retoma.
- Teste: simular eventos de 2 dispositivos diferentes e conferir que cada robô só responde ao seu.
