# Manuais de criação — Bota-Abaixo (ÍNDICE: comece aqui)

**Princípio:** o MAPA define a experiência; o MODO define as regras; o sistema geral define padrões; os MANUAIS ensinam o
processo; a BIBLIOTECA do mapa registra o conteúdo aprovado; os DADOS (`data/`) fazem o jogo obedecer.
Antes de criar qualquer coisa, leia [`sistema_criacao.md`](sistema_criacao.md) (hierarquia, estados, aprovações).

## 1. O usuário pediu… → o que abrir
| Pedido | Manual (como fazer) | Biblioteca / dados (o que já existe) | Testes |
|---|---|---|---|
| **"Crie a fase N do Derruba"** (mapa novo) | [`derruba/README.md`](derruba/README.md) → [`derruba/mapa.md`](derruba/mapa.md) (+ [`mapa_cartilha.md`](derruba/mapa_cartilha.md)) · skill `criar-fase` | copie `docs/fases/derruba/_modelo/` → `fN_<nome>/`; manifesto `data/mapas/derruba/<mapa>.json` | `--so=mapa,etapas,diretor,mecanismos,eventos` |
| Já deu **parte do conceito** (tema, cenas, eventos, spells, estilo) | o mesmo; registre o que ele DEFINIU como `APROVADO` na biblioteca e só proponha o que falta | idem | idem |
| **Spell** nova (ou levar uma spell para outro mapa) | [`spells.md`](spells.md) → [`derruba/spell.md`](derruba/spell.md) | `data/modos.json` (definição) + `spells_permitidas` do manifesto do mapa (autorização) | `--so=spells,mapa` |
| **Evento** novo / corrigir evento | [`eventos.md`](eventos.md) → [`derruba/evento.md`](derruba/evento.md) | biblioteca de eventos (`data/modos.json` → `eventos.lista`) + `cenas[].eventos` do manifesto | `--so=eventos,lab` |
| **Perigo / mecanismo / armadilha** | [`perigos_mecanismos.md`](perigos_mecanismos.md) → [`derruba/perigos_mecanismos.md`](derruba/perigos_mecanismos.md) | `cenas[].mecanismos` do manifesto | `--so=mecanismos` |
| **Robô** (personagem) | [`personagem.md`](personagem.md) — global, não pertence a modo nem mapa | `art/src/robos/elenco.py`, `modelos.json` | `--so=robos` + `--equipa=DIR` |
| **Skin** | [`skins.md`](skins.md) — origem no MAPA; **ainda não implementar** | `docs/fases/<modo>/<mapa>/skins.md` | — |
| **Som** | [`audio.md`](audio.md) | packs aprovados em `audio/pack_*` | `--so=som` |
| **Desempenho** (queda de FPS, ou TODO elemento novo antes de entregar) | [`desempenho.md`](desempenho.md) — protocolo corretivo + preventivo | orçamento `data/desempenho.json` | `--so=desempenho` + `--perf-derruba=DIR` |
| **Animação** de perigo/mecanismo/efeito (TODO elemento que se mexe) | [`animacao.md`](animacao.md) — 5 batidas, técnica procedural, revisão em vídeo lento | `game/modes/mec_onda.gd` (exemplo) | `--cargueiro-video=DIR --video-so=<tipo> --video-passo=1` |
| **Plataformas e cenário** de uma cena (trocar/adicionar peças do palco) | [`derruba/mapa.md`](derruba/mapa.md) §5 "vocabulário do tema + sustentação" (A57) | modelo `art/src/cenarios/f2_plataformas.py` | prancha antes × depois + `--so=cargueiro,mapa` |
| Mexer numa fase **existente** | a biblioteca do mapa (`docs/fases/<modo>/<mapa>/README.md`) + o manual do tipo de elemento | manifesto do mapa | regressão da fase |

## 2. Mapa dos documentos
| Nível | Documento | Vale para |
|---|---|---|
| Jogo | `sistema_criacao.md`, `personagem.md`, `skins.md`, `spells.md`, `eventos.md`, `perigos_mecanismos.md`, `audio.md` | todos os modos |
| Modo Derruba | `derruba/README.md` (regras do modo) · `derruba/mapa.md` (método VALIDADO de fase) · `derruba/mapa_cartilha.md` · `derruba/spell.md` · `derruba/evento.md` · `derruba/perigos_mecanismos.md` | só o Derruba |
| Mapa | `docs/fases/derruba/f1_canteiro/` (biblioteca da Fase 1) · `docs/fases/derruba/_modelo/` (modelo vazio) | um mapa |
| Dados | `data/modos.json` (modo: classes, destruição, bibliotecas de spells/eventos) · `data/mapas/<modo>/<mapa>.json` (manifesto) · `data/mapas/ferramentas.json` · `levels/*.lvl` (geometria) | código lê |

## 3. Regras que valem para todos
1. **Aprovação antes de código grande:** arte e comportamento novos começam por imagem/ficha para o usuário aprovar.
2. **Números no `data/`**, nunca fixos no código. Conteúdo de mapa no **manifesto** (fonte única).
3. **Arte em papel e giz** gerada por Python/SVG (`art/src/…`), sem IA de imagem. Gere, **abra a imagem e olhe**.
4. **Teste só a parte mexida** (`--autotest --so=<nome>`); bateria completa 1× no fim.
5. **Desempenho:** todo elemento novo passa pelo protocolo de [`desempenho.md`](desempenho.md) (medir com
   `--perf-derruba`, sem pico > 2 ms do elemento, `--so=desempenho` verde) antes de ser entregue.
6. **Entrega:** GIF/vídeo curto + `.exe` (`GODOT=… tools/exportar.sh`) + relatório de até 15 linhas.
7. **Commit e push** por etapa; atualize "Retomar aqui" em `docs/ESTADO.md`.
8. **Manual é vivo:** aprovou/reprovou algo → atualize o manual certo E a biblioteca do mapa no mesmo commit, com o estado.

## 4. Comandos
```
G=/caminho/Godot_v4.7.1-stable_linux.x86_64
$G --headless --path game --import                                   # depois de PNG ou script novo (class_name)
$G --headless --path game --fixed-fps 60 -- --autotest --so=mapa      # testes de uma parte
xvfb-run -a -s "-screen 0 1920x1080x24" $G --path game --fixed-fps 60 --resolution 1920x1080 -- --fase=DIR   # vitrines
```
