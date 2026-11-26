# Manual — criar um EVENTO GLOBAL (modo Derruba)

> **REGRA (APROVADA 2026-11-26, A14):** evento é **do mapa**, escolhido na tela de eventos, e tem de funcionar em
> **TODAS as cenas do mapa** (com o visual de cada cena). Algo que só existe numa cena **não é evento**: é
> **perigo/mecanismo da cena** (`perigos_mecanismos.md`). Os antigos `V#` (Concretagem, Desmoronamento, Enchente) viram
> perigos das suas cenas na etapa D. Não criar `V#` novos.

Evento = acontecimento da arena que muda a luta por alguns segundos. 12 aprovados: G01 Sirene, G05 Guindaste,
G06 Entulho, G11 Interdição, G12 Troca de Andaimes, G13 Cabo Rompido, G02 Ventania, G03 Gravidade, G04 Sobrecarga
Magnética, G14 Chuva de Rebites, G10 Carga Especial (= chuva de 1–3 ARMADURAS).
**Nunca reintroduzir os reprovados:** G07, G08, G15, G16, G17, G18 e **G09 Inspeção (drone)** (2026-11-25, código removido).
Princípios gerais: [`../eventos.md`](../eventos.md). **Autorização:** um evento só acontece num mapa/cena se estiver em
`eventos_permitidos` e em `cenas[].eventos` do manifesto do mapa (`data/mapas/derruba/<mapa>.json`); mapa sem manifesto
não tem evento; o Laboratório (ferramenta) tem a biblioteca inteira. Específicos de um mapa = `V#`.
**G01 no Canteiro:** `SUBSTITUÍDO` (2026-11-25) — o ciclo "sirene + fita → o trecho cede" virou a ferramenta do **diretor
adaptativo da destruição** (regra do modo, `README.md`); G01 segue na biblioteca para outros mapas.

## 1. Regras (valem para todo evento)
1. **Três fases sempre:** AVISO (o LUGAR e o MOMENTO do perigo marcados: faixa zebrada/vermelha, sombra listrada,
   fantasma do destino, holofote, setas, luzes piscando + faixa de nome + som) → ATIVO → FIM com **restauração**
   (tudo volta ao normal; nada fica preso).
2. **Nunca injusto:** não cai em nascimento (`_ground_spots` já evita), não nasce dentro de robô (empurra para o lado),
   não fecha a única rota, deixa sempre faixa segura (rebites ≤ 45% da tela), força com teto, densidade com limite.
3. **Golpe do ambiente nunca finge ser de jogador:** `r.take_hit(dir, "evento_<nome>", -1)` + entrada
   `amassometro.evento_<nome>` + nome em `last_cause` (`robot.gd`). No máximo 1 acerto por robô por onda.
4. **Até 2 eventos juntos**, só se compatíveis: pares proibidos em `conflitos` (data). Evento novo que mexe na mesma
   peça de outro (mesmas vigas, andaimes, chão) → acrescente o par.
5. **Intensidade** (AJUSTES: baixa/normal/alta) multiplica força e quantidade por `K()`; baixa = 1 evento por vez.
6. Elementos de "interface" do evento (exaustores, medidor, drone, faixas de rebite) usam `_vr()` = **o que a câmera mostra**,
   não a borda do mapa inteiro (a câmera é adaptativa; na borda do mapa ficam fora da tela).
7. Nome comprido demais para a faixa → campo `curto` no data (ex.: "Ventania").
8. Arte em papel e giz com peça de verdade (exaustor, bobina, tapume, moitão, drone…), animada por código.

## 2. Onde fica cada coisa
| O quê | Arquivo |
|---|---|
| Lista, números, ritmo, intensidade, conflitos | `data/modos.json` → `demolicao.eventos` (`lista`, `primeiro_s`, `intervalo_s`, `intensidade`, `max_simultaneos`, `vento_max`, `conflitos`) |
| Onde pode acontecer | manifesto do mapa → `eventos_permitidos` + `cenas[].eventos` (filtro em `eligible()` via `MapaReg.eventos`) + pré-requisito físico em `eligible()` |
| Lógica e desenho | `game/modes/eventos.gd` |
| Estrutura do Canteiro (vigas, andaimes, laje) | `game/modes/canteiro.gd`: `parts` (`evt` marca a peça ocupada por um evento), `move_part`, `drop_body`, `restore_body`, `damage` |
| Saídas que outros sistemas leem | `events.wind` e `events.gravity_mult` (robô), `events.inspecao` (máquinas e estrutura), `hard_at` (tiros param), `grab_at` (gancho agarra), `hammer_hit` (marreta quebra) |
| Arte | `art/src/efeitos/spells.py` → peças `g##_*` em `PIECES` |
| Testes / vitrine | `driver.gd`: `eventos_test` (`--so=eventos`) e `eventos_frames` (`--eventos=DIR --so-eventos=G02+G05`) |
| Automáticos | Laboratório (linha EVENTO), tela ESCOLHER EVENTOS, faixa do HUD com até 2 avisos |

## 3. Passo a passo
1. **Ficha curta para o usuário:** disparo e aviso (como o jogador vê ONDE e QUANDO), efeito, reação esperada, animação,
   segurança, se depende do Canteiro ou é universal, com quem conflita.
2. **Autorize** nas cenas certas do manifesto (`cenas[].eventos` e `eventos_permitidos`) — sem isso o evento nunca aparece.
   **Dados:** entrada em `lista` com `id`, `nome`, (`curto`), `dica` (aparece no menu), `aviso_s`, `dur`, `fim_s` e os números
   próprios (força, raio, quantidade, ondas…). Conflitos novos em `conflitos`.
3. **Código em `eventos.gd`** — cada fase é um `match` por id:
   - `eligible(e)`: a arena tem o que o evento precisa? (Canteiro, chão livre, viga com chão embaixo…)
   - `_on_aviso(a)`: escolhe o lugar e guarda em `a["d"]`; **retorne `false` se não achar lugar** (o evento não começa).
   - `_tick_aviso` / `_tick_ativo` / `_tick_fim`: animação e efeito; força/gravidade somam em `wind` / `gravity_mult`
     (zeradas a cada quadro).
   - `_on_ativo` / `_on_fim`: criar/soltar corpos (`StaticBody2D`, `AnimatableBody2D` para o que se move), sons, faixa.
   - `_cleanup(a)`: **desfaz tudo** (corpos, `evt` das peças, posições). É chamado no fim, ao trocar de rodada e quando o
     Laboratório dispara outro evento — o jogo nunca pode ficar com sobra.
   - Desenho: `_draw()` (atrás dos robôs: objetos, sombras, faixas no chão) e `_draw_front()` (na frente: vento, rebites,
     drone, medidor, partículas `bits`).
4. **Se mexe no Canteiro:** marque a peça com `p["evt"] = "G##"` (o ciclo G01, o Controle Remoto e o dano passam a
   ignorá-la), use `move_part` / `drop_body` / `restore_body`, e limpe `evt` no `_cleanup`.
5. **Se cria sólido:** inclua em `hard_at` (cobertura) e, se agarrável, em `grab_at`; se quebrável, em `hammer_hit`.
   Objeto apoiado no chão some/cai se o chão some (laje que desaba).
6. **Arte:** peças em `spells.py` (`g##_*`), gere, olhe, copie para `game/assets/spells/`, `--import`.
7. **Teste** em `eventos_test`: `go.call("G##")` dispara com `manual = true`; confira aviso antes do efeito, o efeito,
   segurança (não prende, não cai em nascimento) e restauração no fim. Confira também `todos os eventos funcionam na fase
   do Laboratório` (`--so=lab`).
8. **Vitrine:** `--eventos=DIR --so-eventos=G##` → olhe aviso, ativo e fim no tamanho da tela (a câmera mostra o evento?).
   GIF + `.exe` + relatório.
9. Atualize `docs/ESTADO.md` e este manual (lista de aprovados, lições).

## 4. Lições (reprovado/corrigido → regra)
- Exaustores e medidor presos na borda do mapa ficavam fora da tela → usar `_vr()` (regra 6).
- Vento empurrava robô parado para fora da arena → no chão o vento pesa 0,55 (no ar 1,2) e há teto (`vento_max`).
- Textos flutuantes no início brigavam com a faixa do nome → não escrever por cima da faixa.
- Guindaste (G05) e Drone (G09) tinham pouca função de jogo → todo evento precisa de um **motivo claro para o jogador agir**
  (prêmio, risco, rota nova), não só enfeite. Aprovado (2026-11-24): a carga traz uma caixa especial de spell em cima e
  marretar o gancho (1 pesada ou 2 rápidas) solta a carga em quem está embaixo (crédito de quem marretou); o drone conserta
  um estágio de rachadura das peças que carimba e recolhe o entulho com raio trator.
