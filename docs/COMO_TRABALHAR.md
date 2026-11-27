# Como trabalhar neste projeto (comportamento de TODA sessão do Claude)

Vale para qualquer conta e qualquer conversa nova. Ordem de leitura ao começar: **`CLAUDE.md` → este arquivo →
"▶ Retomar aqui" do `docs/ESTADO.md`** (e só o que ele mandar abrir). O que não está escrito no repositório se perde:
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
  (~20 min, rode em segundo plano; referência atual: ~443 verificações, 0 falhas). Teste novo para cada coisa nova.
- Testes não podem depender da ordem: quem cria bots/estado volta ao menu no fim (`main.go_menu()`).
- **Arte nova copiada para `game/assets/` SÓ vale depois de `godot --headless --path game --import`** (sem isso o jogo
  continua com a imagem antiga — já aconteceu no lote 3 e o usuário viu a arma antiga). Confira de PERTO numa captura
  recortada (o robô ocupa ~5% da tela cheia) antes de dizer que está igual à prancha.
- Commit + push no fim de cada etapa que funciona (`git -c push.negotiate=true push origin main`). O hook de
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

## 6. Passagem de bastão (quando o usuário disser "faz a passagem" ou antes de a conversa acabar)
1. Reescreva o **"▶ Retomar aqui"** do `docs/ESTADO.md`: o que foi feito agora (commits), o que está pela metade,
   **o próximo passo exato** e as decisões que esperam o usuário. Curto; detalhes nos arquivos apontados.
2. Registre decisões novas (A##) e avaliações pendentes.
3. Commit + push. Responda ao usuário com o texto para colar na conversa nova:
   > Leia o CLAUDE.md, o docs/COMO_TRABALHAR.md e o "Retomar aqui" do docs/ESTADO.md e continue de onde parou.

## 7. Ambiente na nuvem (conta nova ou máquina nova)
`tools/setup_nuvem.sh` instala Godot 4.7.1 + RTK (checksums conferidos) e importa o projeto. Se a sessão começar sem
`godot`, rode-o (`bash tools/setup_nuvem.sh` a partir da pasta que contém o repositório) e proponha salvá-lo como
setup script do ambiente da conta (ferramentas de ambiente do Claude), para as próximas sessões já nascerem prontas.
