# DOSSIÊ — Fase 2 do Derruba: CARGUEIRO PERDIDO → 1º PROTÓTIPO JOGÁVEL

**Para a sessão que vai construir.** Leia antes: `CLAUDE.md`, `docs/COMO_TRABALHAR.md`, `docs/manuais/derruba/mapa.md`
(ordem, blocos A–F, CHECKLIST §5, erros §7) e o exemplo vivo do Canteiro (`data/mapas/derruba/canteiro_obras.json`,
`levels/canteiro_obras.lvl`, `art/src/cenarios/fase1_jogo.py`). Mapa = **dados (manifesto + .lvl) + arte**; código novo só
para tipo novo de mecanismo.

## 1. O que está aprovado (2026-11-28)
- Tema fundo do mar, descendo da superfície até Atlântida (A54: estrutura + mundo + regra-assinatura). Nome **Cargueiro Perdido**,
  `map_id` `cargueiro_perdido`, arte em `game/assets/cargueiro/`.
- **3 cenas** (topologia pequena): `conves` (1) → `destrocos` (2a, rota moderada: ≥ 40% no tempo) / `atlantida` (2b, rota total: bateu 65%).
- **Princípio de palco:** a estrutura grande (navio, templo) é MOLDURA de fundo e NÃO se pisa; a luta é em plataformas abertas —
  pouca parte fixa, o resto plataforma destrutível; KO = mar / fenda embaixo + bordas abertas.
- **Coerência física:** peça pendurada = cabo → gancho → lingas nas quinas (ou 2 cabos nas pontas); peça apoiada = 2 pontas
  apoiadas; objeto solto sempre sobre superfície.
- Regra-assinatura: **ÁGUA** (alagado = anda devagar, pulo flutua, golpe joga longe).

## 2. Referência visual (layout medido no grid de 64 px — copie as posições)
| Cena | Fotografia aprovada | Fonte (posições exatas em código) |
|---|---|---|
| 1 Cargueiro no Alto-Mar | `art/out/fase2/cena1_conves.png` | `art/src/cenarios/f2_prancha.py` → `c1_*` |
| 2a Destroços do Cargueiro | `art/out/fase2/cena2a_destrocos.png` | `c2_*` (constantes `R2_ESQ`, `R2_MEIO`, `BALSA2`, `MAR2`) |
| 2b Atlântida | `art/out/fase2/cena2b_atlantida.png` | `c3_*` (`TOPO3`) |
Perigos: `art/out/fase2/perigos.png` + `perigo_tubarao.png`. Biblioteca: `docs/fases/derruba/f2_cargueiro/` (README, `cenas/*.md`,
`perigos_mecanismos.md`, `eventos.md`, `spells.md`, `skins.md`).

## 3. Peças por cena (FIXO · QUEBRA · KO)
- **1 Convés:** FIXO = 2 balsas (nível 13), pilar de atracação (nível 11), 2 torres de andaime, torre da grua · QUEBRA = pilhas de
  contêineres (3×1 tiles), tábuas níveis 9 e 6, contêiner içado no gancho (nível 5), viga içada (nível 3), bote pendurado · KO = mar (linha 15) + bordas.
- **2a Destroços:** FIXO = rocha esq. (topo nível 12), rocha-arco (nível 11), balsa + torre · QUEBRA = 2 contêineres na rocha, bote
  virado e jangada boiando, 2 convés quebrados encravados na rocha-arco (nível 12), pedaço do convés sobre escoras (nível 8),
  mastro-ponte, contêiner e rede de carga içados, tábuas penduradas (níveis 9 e 5), contêineres da balsa · KO = mar fundo.
- **2b Atlântida:** FIXO = 3 pilares de mármore sobre picos (níveis 12/11/12), grua presa no pilar esq. · QUEBRA = tambores,
  cabeça de estátua, lajes entalhadas (níveis 9, 7, 6, 4), laje-ponte, lustre (nível 4), bloco na corrente (nível 9), prancha do
  navio (nível 3), contêiner + baú · KO = Fenda Abissal.

## 4. Perigos/mecanismos (M1–M10, valores iniciais — calibrar jogando)
M1 contêiner despenca (sombra vermelha 1,5 s, ~20 s) · M2 gancho balança (~12 s) · M3 onda na balsa (molhado 2 s, ~15 s) ·
M4 maré sobe/desce (~8 s alagado, ~25 s) · M5 contêiner boiando vira com 2+ robôs · M6 rede rasga na marretada pesada ·
M7 racha da cúpula alaga (marretada aumenta) · M8 lustre despenca (marretada na corrente) · M9 concha-trampolim (fecha 2 s) ·
M10 tubarão (anel vermelho 1,5 s, só plataformas baixas; marretada no focinho espanta). Detalhes: `perigos_mecanismos.md`.

## 5. Escopo do 1º PROTÓTIPO (fazer nesta ordem, commit por bloco)
1. **Bloco A — dados:** `data/mapas/derruba/cargueiro_perdido.json` (3 cenas, `rota_moderada`/`rota_total`, `base_fixa`,
   estruturas) + `levels/cargueiro_perdido.lvl` (`etapa1..3`, `ko1..3`, `buraco`, 12 nascimentos em chão firme). Validar `--so=mapa`.
2. **Bloco B — peças destrutíveis:** reaproveitar os tipos do `canteiro.gd` (laje/viga/andaime/prancha…) mapeando contêiner/tábua/
   laje de mármore como tipos existentes; arte provisória simples (cores das fotografias) é aceitável no protótipo.
3. **Bloco C — transição** 1 → 2a/2b pelo motor pronto (`modes/etapas.gd`), sem cinemática nova.
4. **Bloco D — 2–3 mecanismos** mais baratos primeiro: M1 (contêiner caindo), M4 (maré, reusar tipo `agua`), M9 (trampolim).
   O resto (M2, M3, M5–M8, M10) fica para depois do playtest.
5. Liberar no jogo pela lista `progressao.mapas_a_liberar` em `data/modos.json` (Projetos de Demolição).
6. Testes: `--so=mapa,etapas,mecanismos,bots` (bots precisam terminar as rodadas = há KO) + `--so=desempenho`; bateria 1× no fim;
   GIF `--fase=DIR`; `.exe` por `tools/exportar.sh`.

**Fora do protótipo:** arte final por peça, eventos do mapa, skins e engenhocas novas (Escafandro, Torpedo), animação do tubarão.

## 6. Cuidados
- Arte: `NODE_PATH=$(npm root -g)`; importar com `godot --headless --path game --import`; reverter `art/src/__pycache__`,
  `art/out/.jobs.json` antes do commit. Editar `data/modos.json` só pontualmente.
- Outra sessão também empurra para esta branch (`claude/practical-maxwell-hldv9n`): em push rejeitado, `fetch` + `merge` (sem force).
- Atualize "▶ Retomar aqui" em `docs/ESTADO.md` ao fim.
