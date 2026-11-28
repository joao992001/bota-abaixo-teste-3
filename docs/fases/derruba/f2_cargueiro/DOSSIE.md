# DOSSIÊ — FASE 2 do Derruba: CARGUEIRO PERDIDO (página única de situação)

Método obrigatório: `docs/manuais/derruba/mapa.md` (biblioteca → fotografias → código A–F → vitrine → correções).
**Onde estamos:** passos 1 e 2 do método **APROVADOS pelo usuário (2026-11-28: "Aprovo tudo")**. Passo 3 (código,
blocos A–F) em andamento — ver `docs/BASTAO.md`. Bastão: `docs/BASTAO.md`.

## 1. Situação de cada item
| Item | Onde | Estado |
|---|---|---|
| Tema "fundo do mar descendo, da superfície até Atlântida" | `README.md` | **APROVADO** (2026-11-28) |
| Nome "Cargueiro Perdido" · topologia de 3 cenas | `README.md` | **APROVADO** |
| Gatilhos: 40% no tempo → Destroços · 65% a qualquer momento → Atlântida | `README.md` | **APROVADO** |
| Princípio de palco: estrutura grande = moldura; luta em plataformas abertas | `decisoes_testes.md` | **APROVADO** |
| KO por cena (mar, mar fundo, Fenda Abissal) | `decisoes_testes.md` | **APROVADO** |
| Fotografia da cena 1 (Cargueiro no Alto-Mar) | `art/out/fase2/cena1_conves.png` | **APROVADO** (v3) |
| Fotografia da cena 2a (Destroços, 3 andares) | `art/out/fase2/cena2a_destrocos.png` | **APROVADO** (2026-11-28) |
| Fotografia da cena 2b (Atlântida, proa furando a cúpula) | `art/out/fase2/cena2b_atlantida.png` | **APROVADO** (2026-11-28) |
| Perigos/mecanismos M1–M9 (3 por cena) + M10 Tubarão | `perigos_mecanismos.md`, `art/out/fase2/perigos.png`, `perigo_tubarao.png` | **APROVADO** (2026-11-28) (M1 e M10 são ideias dele) |
| Storyboard das 2 transições | `cenas/conves.md`, `art/out/fase2/transicoes.png` | **APROVADO** (2026-11-28) |
| Regra-assinatura ÁGUA (ideia) · números (lento ×0,6, pulo flutua, golpe ×1,25) | `README.md` | ideia e números **APROVADOS** (ajustam jogando) |
| Eventos G15 Onda Gigante · G16 Tempestade · G17 Cardume · G18 Polvo da Grua · G19 Bolhão de Ar | `eventos.md` | **APROVADO** (números ajustam jogando) |
| Engenhocas: todas + A03/T01 reagem à água + A09 Torpedo + D07 Escafandro | `spells.md` | **APROVADO** — Torpedo/Escafandro DEPOIS da fase jogável |
| Skins K16–K20 (Marinheiro, Pescador, Água-viva, Coral, Pirata Afogado) | `skins.md` | **APROVADO** — prancha e jogo DEPOIS da fase jogável |
| Fundo vivo C0–C4 das 3 cenas | `cenas/*.md` | **APROVADO** |
| Esquema geral | `art/out/fase2/esquema.png` | feito (outro chat) |

## 2. Respostas do usuário (2026-11-28: "Aprovo tudo")
1. Aprova as fotografias **2a Destroços** e **2b Atlântida**?
2. Aprova os **perigos M1–M10** (ou tira/troca algum)?
3. Aprova as **2 transições** (encalha → desliza para a direita · parte e afunda → queda pelo mar)?
4. Números da **água** e **eventos G15–G19**: pode seguir como proposto (ajustamos jogando)?
5. Engenhocas novas (**Torpedo**, **Escafandro**) e skins K16–K20: entram agora ou depois da fase jogável?
→ 1–4 APROVADOS; 5 = depois da fase jogável (a recomendação, aprovada).

## 3. Plano de construção (blocos A–F do `mapa.md` §3, depois das respostas)
| Bloco | O que é novo neste mapa | Arquivos |
|---|---|---|
| **A Cenas** | `levels/cargueiro_perdido.lvl` com 3 áreas no mesmo mundo: `etapa1` (superfície), `etapa2` **ao lado** (o deslize da moderada, como a Fachada), `etapa3` **embaixo** (a queda da total, como a Fundação); `ko1..3`, `buraco1` (porão); nascimentos 1–12. Manifesto `data/mapas/derruba/cargueiro_perdido.json` com `rota_moderada`/`rota_total`. | `levels/`, `data/mapas/derruba/`; validar `--so=mapa` |
| **B Cena viva** | `art/src/cenarios/f2_jogo.py` (cópia de `fase1_jogo.py`) tira as camadas paradas das fotografias; o que mexe vira sprite (ondas, gaivotas, navio balançando, águas-vivas, bolhas). `modes/cena.gd`: generalizar as listas da fase 1 (o manual manda fazer na 2ª fase). | `art/src/cenarios/`, `game/assets/cargueiro/`, `game/modes/cena.gd` |
| **C Perigos** | 10 tipos novos em `modes/mecanismos.gd` (conteiner_cai, gancho_balanca, onda_balsa, mare, conteiner_boia, rede_carga, racha_cupula, lustre, concha, tubarao) + a **zona de ÁGUA** (alagado/molhado, números em `data/modos.json`). Um por commit, com teste e medição de desempenho. | `game/modes/mecanismos.gd`, `game/player/robot.gd` (`env_slow`, gravidade na água) |
| **D Demolições** | Estruturas do mapa como tipos do `canteiro.gd`: tábua = `pranchas`; viga içada = `vigas`; lajes de mármore = `lajes`; colunas = `pilares`; **tipos novos**: contêiner (empilha, racha, boia) e peça pendurada (rede, contêiner içado, bloco na corrente). | `game/modes/canteiro.gd`, manifesto |
| **E Eventos** | G15–G19 novos em `modes/eventos.gd` + provar NA cena os da biblioteca que entram (G02, G06, G10). | `game/modes/eventos.gd`, `data/modos.json` |
| **F Entrega** | testes, vitrine `--fase=DIR` das 2 rotas (`ROTA=moderada`), GIF, `.exe`, manual atualizado. | `game/tests/driver.gd` |

**Desempenho (protocolo `docs/manuais/desempenho.md`, obrigatório):** cada mecanismo/evento novo medido com
`--perf-derruba` adaptado ao mapa (`--perf-mapa=cargueiro_perdido`, a acrescentar no bloco F): média ≤ 0,5 ms e nenhum
pico > 2 ms por elemento; água = retângulo por cena (1 comparação de altura por robô); tubarão e cardume como listas, não nós.
**Checklist §5 do `mapa.md`** antes de cada imagem e do build. Meta: no máximo 1 rodada de correção depois de jogar.
