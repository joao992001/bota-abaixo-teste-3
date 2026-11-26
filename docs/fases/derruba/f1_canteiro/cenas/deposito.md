# Cena 3 — DEPÓSITO (`deposito`) · Canteiro de Obras · nível 2, **Rota Moderada** — `PROPOSTO` (etapa C, 2026-11-26)

> Ficha para aprovar (passo 1 do método `docs/manuais/derruba/mapa.md`). Depois da aprovação: fotografia conceitual
> (passo 2). Storyboard da chegada: `art/out/etapa_c/c7_storyboard_rotas.png`. Nada disto está no jogo.

**Conceito:** a obra **não cai inteira** — só o lado da rua cede. A laje vira um tobogã e todos escorregam para o
**telhado do galpão de materiais** vizinho, ao entardecer. A luta começa no telhado; quebrando as telhas, ela desce para
dentro do galpão, entre pilhas de material. Moderada = meia destruição, meia descida, para o lado (Total = tudo, para
baixo, no escuro).

**Ficha:** composição em 2 andares (telhado em serrilha em cima, piso do galpão embaixo) · área nova `etapa3` (40×22, ao
lado da `etapa1`, para a câmera ir para a direita e descer) · fim de tarde · paleta céu `#f7c38c`→`#ef9472`, telha
fibrocimento `#c9cdd3`, claraboia `#a7d3e8`, estrutura metálica `#4f6d8f`, tijolo `#c8643c` · assinatura: **a laje torta
da obra encostada no galpão** + a grua amarela ao fundo (continuidade com o Térreo) · câmera fixa · som: telha rachando,
eco metálico do galpão, rádio da obra ao longe.

| Estrutura | Tipo | Na conta do manômetro? |
|---|---|---|
| Tesouras e pilares metálicos do galpão (topo das águas do telhado) | **BASE FIXA** | não |
| Piso do galpão e plataformas das laterais (platibanda) | **BASE FIXA** | não |
| ~10 trechos de telha de fibrocimento (hp 2; racham com quem fica parado, como o caixote) | destrutível | sim |
| 4 claraboias (vidro, hp 1; quem pisa cai para dentro) | destrutível | sim |
| 3 pilhas de tijolos paletizados (hp 3; viram degraus/escudos) | destrutível | sim |
| Caixa d'água sobre torre (hp 3; quebrada vira cachoeira, igual à M7) | destrutível | sim |
| Laje torta da obra (entrada da cena, à esquerda) | gerada na transição | não |

**KO:** cair para fora do telhado pelas laterais (rua) ou ser lançado para fora da tela. O piso do galpão não é KO — é
o segundo andar da luta (verticalidade que a destruição cria).

**Perigos/mecanismos (reaproveitar tipos que já existem; tipo novo só se aprovado):**
| Id | O quê | Apoio físico | Tipo no código |
|---|---|---|---|
| M10 | Esteira de tijolos (leva para a beirada; botão inverte) | piso do galpão, sobre pés | `esteira` (existe) |
| M11 | Empilhadeira automática que vai e volta empurrando | trilho pintado no piso | `vagonete` (existe) |
| M12 | Monta-carga entre piso e telhado | poço lateral com cremalheira | `elevador` (existe) |
| M13 | Água da caixa d'água quebrada (escorrega/lento) | torre da caixa | `agua` (existe) |

**Eventos (biblioteca do mapa):** G01 Sirene, G02 Ventania (telhado exposto), G03 Gravidade, G05 Operação Guindaste (a
grua da obra alcança o galpão), G06 Entrega de Entulho, G10 Carga Especial (cai pelas claraboias), G13 Cabo Rompido.
Específico proposto: **V4 Telhado Cede** — uma água inteira do telhado cai de uma vez (aviso com fita zebrada).
**Última cena** (mapa de 3): sem transição; luta até sobrar 1. "Nenhum evento" não quebra a cena (mecanismos seguem).

**Chegada (transição Térreo → Depósito):** "A LAJE VAI ESCORREGAR!" → escoras e andaime do lado da rua quebram (a base
fixa do Térreo fica) → a laje inclina e vira tobogã → câmera vai para a direita e desce → todos caem no telhado
(telhas voam, poeira) → "DEPÓSITO!". Robôs sem dano durante a transição, como na Rota Total.

**Alternativa (se o Depósito não agradar): FACHADA** — só a frente do prédio desaba e todos ficam pendurados nos
andaimes da fachada e em balancins (plataformas suspensas por cabos). Mais vertical; risco maior de câmera e de KO
injusto; repete os andaimes do Térreo. Recomendo o Depósito.

**Pontos para o usuário decidir:** conceito (Depósito × Fachada) · piso do galpão como 2º andar (sim/não) · V4 Telhado
Cede (sim/não).
