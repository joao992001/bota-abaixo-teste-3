# Bota-Abaixo — regras do projeto

Plataforma competitivo, **multiplayer local 2–4**, Godot 4. Party game de robôs de demolição com **modos independentes** (Derruba, Batata-Dinamite, Rei da Obra, Fuga), cada um com suas arenas. (O antigo modo de peças com dono foi removido em 2026-11-20.) **Comece lendo `docs/ESTADO.md`** (estado atual e o que fazer a seguir). **Vai criar ou mudar fase, spell, evento, perigo/mecanismo, robô, skin ou som? Comece pelo índice `docs/manuais/README.md`** (pedido → manual → biblioteca do mapa → testes) — obrigatório; atualize manual e biblioteca quando o usuário aprovar algo novo. Princípio: o MAPA define a experiência, o MODO define as regras; conteúdo de cada mapa no manifesto `data/mapas/<modo>/<mapa>.json`. **O Derruba é o modo principal** e foi reformulado (v2, aprovado em 2026-11-25, implementação pendente): `docs/revisoes/reformulacao_derruba.md`. Detalhes: `docs/GDD.md`. Visual: topo de `docs/estilo_visual.md` + `docs/referencias/`.

## Prioridades (nesta ordem)
1. **Sempre jogável** — cada etapa termina com o jogo abrindo, testes rodando e commit.
2. **Visual muito próximo das referências** — personagens e cenário são a vitrine do jogo. Compare sempre lado a lado com `docs/referencias/`.
3. **Controle responsivo** — nunca sacrifique resposta do controle por animação.
4. **Caos legível** — cada jogador entende em 1 s o que é perigoso para ele.

## Economia de uso (obrigatório)
- **A sessão principal faz tudo** (código, mapas, regras e arte ligada ao código). Subagentes só para lotes grandes de arte em paralelo (`artista-personagens`, `artista-cenarios`) e `revisor` no fim de uma etapa grande. Máximo 3 ao mesmo tempo.
- **Mesma sessão sempre** (pedido do usuário, 2026-11-26): só troque de sessão com motivo plausível. Gaste o necessário para chegar ao objetivo com qualidade, nada além. Antes de encerrar, atualize "Retomar aqui" em `docs/ESTADO.md`.
- Testes: só a parte mexida (`--autotest --so=...`) durante o trabalho; a bateria completa 1× no fim. Poucas capturas de tela.
- Delegue com 3 linhas: objetivo · arquivos que pode mexer · como saber que ficou pronto.
- **Não construa ferramentas antecipadamente.** Escreva um script só quando o mesmo problema aparecer duas vezes.
- Não releia arquivos grandes sem necessidade; carregue skills só quando a tarefa pedir.
- Relatório de marco: **até 15 linhas**. Sem documentos que ninguém vai ler.
- Commit no fim de cada etapa que funciona.

## Honestidade
Não diga que algo funciona sem ter rodado. Se a Godot não estiver instalada ou algo não pôde ser testado, diga claramente. Ao gerar arte, **abra a imagem e olhe** antes de seguir.

## Números do projeto
- Resolução lógica **1920×1080** (`stretch_mode = canvas_items`, aspecto `keep`), filtro linear (arte vetorial).
- Grade de **64 px**; arena **30×16 tiles** (1920×1024) + faixa de placar de 56 px.
- Robô ~80 px de altura; hitbox **48×72**.
- Física 60 ticks. Valores iniciais em `data/controller.json` (pulo `sustain`: velocidade mantida enquanto segura o botão). Pode usar `CharacterBody2D` com velocidade calculada à mão.
- Regras dos modos, arenas e itens lidas de `data/modos.json` (nunca números fixos no código).

## Nunca
- Copiar personagens, logotipos, nomes, emblemas ou fundos exatos das referências. **Copie o estilo** (traço, formas, cores, efeitos), não o conteúdo.
- Usar IA geradora de imagem ou áudio (desligado neste projeto).
- Adicionar online, campanha ou editor de mapas. (Bots: liberados pelo usuário em 2026-11-20, para jogar contra o computador no Modo Festa.)

## Estrutura
```
docs/        GDD, estilo_visual, plano, decisoes, referencias/
data/        controller.json, modos.json
levels/      mapas em texto .lvl (formato em levels/README.md); a Godot lê estes arquivos
art/src/     fontes SVG (ou scripts que geram SVG) — fonte editável da arte
art/out/     PNG/prévias geradas
audio/       efeitos e música (tools/sfxforge.py)
game/        projeto Godot
tools/       sfxforge.py + scripts criados quando necessários
```

## Roteamento
| Tarefa | Skill | Quem |
|---|---|---|
| Regras, modos, rodada, pontuação | `regras-do-jogo` | sessão principal |
| Nova spell / evento / perigo-mecanismo / skin | `criar-elemento` + `docs/manuais/README.md` | sessão principal |
| Movimento e sensação do robô | `controle-do-robo` | sessão principal |
| 2–4 jogadores, controles | `multiplayer-local` | sessão principal |
| Mapas / fases novas (Derruba) | `criar-fase` + `docs/manuais/derruba/README.md` → `mapa.md` | sessão principal |
| Projeto Godot, importar arte, animação cut-out | `godot` | sessão principal |
| Direção de arte e comparação com referências | `estilo-visual` | artistas e revisor |
| Robôs (elenco de 5), expressões, golpes próprios | `personagens-e-acessorios` + `docs/manuais/personagem.md` | sessão principal |
| Blocos, fundos, peças, efeitos | `cenarios-e-pecas` | artista-cenarios |
| Sons e música | `audio` | sessão principal |
| Testar com pessoas | `playtest` | sessão principal |
