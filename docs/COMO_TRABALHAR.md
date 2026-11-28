# Como trabalhar neste projeto (comportamento de TODA sessão do Claude)

Vale para qualquer conta e qualquer conversa nova. Ordem de leitura ao começar: **`CLAUDE.md` → este arquivo →
`docs/BASTAO.md` (quem está fazendo o quê) → "▶ Retomar aqui" do `docs/ESTADO.md`** (e só o que ele mandar abrir). O que não está escrito no repositório se perde:
por isso a passagem de bastão (§6) é obrigatória.

## 1. Conversa com o usuário
- Português do Brasil, **curto e direto** (relatório de marco ≤ 15 linhas). O usuário fala por voz: interprete a
  intenção; se algo estiver ambíguo, **pergunte com opções A/B e recomende uma** (ele responde "A", "sim", "pode seguir").
- Quando ele disser "não entendi", reexplique com **exemplo concreto** e sem jargão.
- Ele já aprovou trabalhar sem pedir licença a cada passo ("não precisa ficar perguntando"): execute; pergunte só
  decisões de **design** (o que é dele) e ações irreversíveis.
- Decisões dele viram registro na hora: `docs/revisoes/reformulacao_derruba.md` (tabela APROVADO A##) e no manual certo.
- Avaliações dele (prints + falas) → `docs/avaliacoes/<data>_<tema>/` (imagens + `AVALIACAO.md`).

## 2. Ordem de trabalho para qualquer coisa visual
1. **Prancha para aprovar antes do código** (gerador Python em `art/src/…`, PNG em `art/out/…`, faixa de notas
   APROVADO/PROPOSTA/DECIDIR). Olhe a imagem antes de mandar. Mande com `SendUserFile`.
2. Aprovou → código. **O resultado tem de ficar IGUAL à prancha aprovada** (não "reinterprete" sem perguntar — já
   aconteceu na tela de mapas e o usuário reclamou).
3. Confira **dentro do jogo**: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path game -- --menus=DIR` (telas),
   `--fase=DIR` (transição; `ROTA=moderada`), `--intro=DIR` (abertura) e `tools/captura_etapas.sh` (teclado real,
   pega crash que o teste sem tela não pega). Olhe as capturas; corrija sobreposição/texto vazando antes de entregar.

## 3. Código e testes
- Godot 4.7.1 (`godot`). Máquina nova: `godot --headless --path game --import` antes de tudo.
- GDScript: tipar variáveis vindas de Dictionary/Array (`var x: float = …`), senão o parse quebra o jogo inteiro.
- Testes: `godot --headless --path game --fixed-fps 60 -- --autotest --so=a,b` durante; **bateria completa 1×** no fim
- **Desempenho:** elemento novo (engenhoca, evento, mecanismo, cena, efeito) → `--perf-derruba=DIR --perf-dur=45` antes de entregar e anote em `docs/manuais/desempenho.md` (seção 5); a bateria inclui `--so=desempenho`. Queda de FPS relatada → seção 4 do mesmo manual.
  (~20 min, rode em segundo plano; referência atual: ~443 verificações, 0 falhas). Teste novo para cada coisa nova.
- Testes não podem depender da ordem: quem cria bots/estado volta ao menu no fim (`main.go_menu()`).
- **Arte nova copiada para `game/assets/` SÓ vale depois de `godot --headless --path game --import`** (sem isso o jogo
  continua com a imagem antiga — já aconteceu no lote 3 e o usuário viu a arma antiga). Confira de PERTO numa captura
  recortada (o robô ocupa ~5% da tela cheia) antes de dizer que está igual à prancha.
- Commit + push no fim de cada etapa que funciona: `git pull -q --rebase origin claude/practical-maxwell-hldv9n && git push -q origin claude/practical-maxwell-hldv9n` (nunca force; conflito = merge). O hook de
  "uncommitted changes": `art/out/.jobs.json` é lixo do gerador → `git checkout -- art/out/.jobs.json`.

## 4. Entregas que o usuário pede com frequência
- **Vídeo de gameplay:** `--video=DIR --arena=canteiro_obras --virada=16 --rota=total|moderada --dur=42`
  **com `--fixed-fps 60`** + `python3 tools/mixar_video.py DIR out/videos/x.mp4`.
- **.exe:** `bash tools/exportar.sh` (modelos 4.7.1 em `~/.local/share/godot/export_templates/4.7.1.stable`; se
  faltarem, baixar `Godot_v4.7.1-stable_export_templates.tpz` do godot-builds e conferir SHA512) → zip de
  `out/build/windows/Bota-Abaixo.exe`. Teste o build Linux com `tools/captura_etapas.sh` antes de entregar.
- `out/` não vai para o git; entregue com `SendUserFile`.

## 5. Vocabulário fixo (não trocar)
JOGO → MODO → MAPA → NÍVEL → CENA → ELEMENTOS. **Engenhoca** = o que o código chama de *spell* (A20). Evento = do
mapa, vale em todas as cenas; o que é de uma cena só é **perigo da cena** (A14). Interface = **"Canteiro vivo"** (A21).

## 6. Passagem de bastão CONTÍNUA (vários chats ao mesmo tempo; qualquer um pode parar no meio)
Até 3 chats trabalham na mesma branch, e o contêiner de cada um some quando ele para (limite de uso, reinício, conversa
nova). O mecanismo:
- **Quadro `docs/BASTAO.md`**: um bloco por tarefa em andamento — quem, desde quando, pedido do usuário (a frase dele),
  **arquivos reservados**, passos com `[x]` + commit, **Próximo passo exato** e decisões pendentes. Seções: EM ANDAMENTO,
  AGUARDANDO USUÁRIO, FILA, CONCLUÍDO.
- **Gancho de início de sessão** (`.claude/hooks/session-start.sh`, registrado em `.claude/settings.json`): todo chat novo
  já começa vendo o quadro e um aviso se o contêiner está atrás do GitHub (outro chat enviou trabalho).
- **Regras (obrigatórias):**
  1. Começou: `git pull --rebase origin <branch>` → quadro → bloco da tarefa → os arquivos que ele aponta.
  2. Pegou tarefa: escreva o bloco e faça commit+push ANTES de trabalhar ("bastão: pega …").
  3. Não mexa em arquivo reservado por outro bloco sem o usuário mandar.
  4. Passos de ≤ ~20 min; ao fim de cada um: `[x]` + commit, novo **Próximo passo exato**, commit+push junto com o
     trabalho. Nunca encerre um turno com trabalho só no contêiner. Sempre `git pull --rebase` antes do push.
  5. Continuar o trabalho de outro chat: assuma o bloco (troque Quem/Desde) e siga do Próximo passo exato.
  6. Esperando resposta: bloco vai para AGUARDANDO USUÁRIO com a pergunta exata.
  7. Terminou: 1 linha em CONCLUÍDO + "Retomar aqui" do `docs/ESTADO.md` atualizado; apague o bloco.
- **Fim de conversa** (o usuário disse "faz a passagem"): além do quadro, reescreva o "▶ Retomar aqui" do
  `docs/ESTADO.md`, registre decisões (A##), commit+push e responda com o texto para colar na conversa nova:
  > Leia o CLAUDE.md, o docs/COMO_TRABALHAR.md, o docs/BASTAO.md e o "Retomar aqui" do docs/ESTADO.md e continue de onde parou.

## 7. Ambiente na nuvem (conta nova ou máquina nova)
`tools/setup_nuvem.sh` instala Godot 4.7.1 + RTK (checksums conferidos) e importa o projeto. Se a sessão começar sem
`godot`, rode-o (`bash tools/setup_nuvem.sh` a partir da pasta que contém o repositório) e proponha salvá-lo como
setup script do ambiente da conta (ferramentas de ambiente do Claude), para as próximas sessões já nascerem prontas.

## 8. Kit de ferramentas (o mesmo que as sessões anteriores usaram) — copie os comandos
**Economia de contexto (obrigatório):** a saída dos comandos já vem condensada (RTK, `tools/setup_nuvem.sh` instala); procure
com `grep -n`/Grep e leia só o trecho (`sed -n a,bp`), nunca o arquivo grande inteiro (`mecanismos.gd`, `driver.gd`, `ESTADO.md`).
Comando longo (teste de Godot, gravação) → em segundo plano + Monitor/notificação; não fique relendo a saída. Imagens: abra
recortes/folhas (`tools/folha_quadros.py`), não quadros cheios um por um. Subagentes só para lote grande de arte (CLAUDE.md).

| Para quê | Comando / arquivo |
|---|---|
| Arte (papel e giz) | Python gera SVG → Chromium rasteriza: `NODE_PATH=$(npm root -g) python3 art/src/<pasta>/<gerador>.py` (usa `svg.queue/render_all`, filtro `papel.rough`, formas `f2_prancha.R/E/S/PL`, robôs `elenco.py`). **Abra o PNG e olhe** antes de mandar. |
| Prancha para aprovação | gerador próprio em `art/src/…` → `art/out/<fase>/<nome>.png`; antes × depois com a captura real do jogo (modelo: `art/src/cenarios/f2_plataformas.py --prancha`). Envie com `SendUserFile`. |
| Levar arte ao jogo | gerador de jogo (ex.: `art/src/cenarios/f2_jogo.py`) → `art/out/game/<cena>/` → copiar para `game/assets/<cena>/` → **`godot --headless --path game --import`**. |
| Teste da parte mexida | `godot --headless --path game --fixed-fps 60 -- --autotest --so=a,b` (≈1–3 min; `--so=` lista em `game/tests/driver.gd`). |
| Captura/vitrine | `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path game --fixed-fps 60 -- --cargueiro=DIR` (fase 2), `--menus=DIR`, `--fase=DIR`. |
| Vídeo de um perigo | `... -- --cargueiro-video=DIR --video-cena=1 --video-so=<tipo> --video-passo=1 [--video-uma]` → `ffmpeg -framerate 60 -i DIR/%04d.png -vf scale=1280:-2 -c:v libx264 -crf 22 -pix_fmt yuv420p out/videos/x.mp4` (lento: `-framerate 15`; `git add -f` para versionar). |
| Revisar animação | `python3 tools/folha_quadros.py DIR folha.png X0 Y0 LARG ALT 100,120,…` → abrir a folha; checklist `docs/manuais/animacao.md`. |
| Higiene antes do commit | `git checkout -- art/src/__pycache__ art/src/robos/__pycache__ art/out/.jobs.json`; restaure SVGs regenerados sem relação (`art/src/cenarios/svg/f2_jogo/`). |

**Processos aprovados pelo usuário (seguir sem perguntar):**
- Visual: prancha → aprovação → código → captura no jogo → vídeo (§2). Animação: `docs/manuais/animacao.md` (5 batidas,
  procedural, revisão em câmera lenta). **Plataformas e cenário: `docs/manuais/derruba/mapa.md` §5 "vocabulário do tema +
  sustentação"** (A57: toda peça é do tema e tem apoio visível; fases RECHEADAS de plataformas).
- `data/modos.json` e manifestos `data/mapas/...json`: edição pontual (trecho exato), nunca reescrever o arquivo.

## 9. Primeira vez neste repositório (Claude novo assumindo o projeto) — passo a passo
1. `git pull --rebase origin claude/practical-maxwell-hldv9n` (branch de trabalho; **nunca** envie para o teste-2).
2. Sem `godot`? `bash tools/setup_nuvem.sh` a partir da pasta acima do repositório (Godot 4.7.1 + RTK + `--import`).
   Confira: `godot --version` (4.7.1) e `node -e "require('playwright')"` com `NODE_PATH=$(npm root -g)`.
3. Leia **só** isto, nesta ordem: `CLAUDE.md` → este arquivo (§1–§9) → `docs/BASTAO.md` → "▶ Retomar aqui" do `docs/ESTADO.md`.
   O resto (manuais, skills, dossiês) você abre quando a tarefa pedir — o índice é `docs/manuais/README.md`.
4. Assuma o bloco de EM ANDAMENTO (troque Quem/Desde, commit+push "bastão: assume …") e siga o **Próximo passo exato**.
5. Skills (`.claude/skills/*`) carregam pelo nome da tarefa (tabela "Roteamento" do `CLAUDE.md`); agentes em `.claude/agents/`.
6. A cada passo: `[x]` + commit no bloco, novo Próximo passo exato, commit+push. Responda ao usuário em ≤ 15 linhas.
