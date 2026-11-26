# Cena 3 — FACHADA (`fachada`) · Canteiro de Obras · nível 2, **Rota Moderada**

| Item | Estado |
|---|---|
| Conceito FACHADA (escolhido em vez do Depósito) | `APROVADO` pelo usuário em 2026-11-26 |
| Luta pendurada nos andaimes da fachada + balancins; cair na rua = KO | `APROVADO` 2026-11-26 |
| Chegada: só a frente do prédio desaba, a laje inclina para a rua, todos escorregam até os andaimes | `APROVADO` 2026-11-26 |
| **Andaime Cede** (era "V4") | `APROVADO` 2026-11-26 — é **perigo da cena (M13)**, não evento (regra A14) |
| Números, posições e arte abaixo | `PROPOSTO` — fecham na fotografia conceitual (passo 2 do método) |

> Próximo passo: **fotografia conceitual** desta cena (`docs/manuais/derruba/mapa.md` §1, passo 2), com o elenco e os
> perigos posicionados; depois o storyboard da chegada é refeito com ela (o de `art/out/etapa_c/c7_storyboard_rotas.png`
> ainda mostra o Depósito). Nada disto está no jogo.

**Conceito:** destruição moderada → a obra não cai inteira; **só a frente do prédio desaba**. A laje do Térreo inclina
para a rua e todos escorregam até os **andaimes da fachada**. A luta continua pendurada na frente do prédio, em vários
andares de andaime e em balancins (plataformas suspensas por cabos) que sobem e descem. Total = tudo cai para baixo, no
escuro; Moderada = só a frente cede e a luta vai para fora, no alto, ao ar livre.

**Ficha (PROPOSTO):** composição vertical em 3–4 andares de andaime + 2–3 balancins · área nova `etapa3` (40×22, a câmera
gira para a frente do prédio) · fim de tarde (diferencia do Térreo de manhã e da Fundação escura) · paleta céu
`#f7c38c`→`#ef9472`, andaime `#e0883a`, tela de proteção verde `#5fae6a`, concreto `#d8ccb6`, rua lá embaixo `#5d6b7d` ·
assinatura: **a laje torta encostada nos andaimes** + a grua amarela ao lado · câmera fixa · som: tubos de andaime
batendo, vento, trânsito lá embaixo.

| Estrutura | Tipo | Na conta do manômetro? |
|---|---|---|
| Parede do prédio com janelas/varandas (pontos de apoio fixos) | **BASE FIXA** | não |
| Pilares de andaime presos à parede (montantes) | **BASE FIXA** | não |
| Pranchas de andaime em 3–4 andares (hp 2; racham com quem fica parado, como o caixote) | destrutível | sim |
| Telas de proteção (rasgam; quem cai nelas freia) | destrutível | sim |
| Pilhas de material nas pranchas (hp 2) | destrutível | sim |
| Laje torta (entrada da cena) | gerada na transição | não |

**KO:** cair na rua (fundo da tela) ou ser lançado para fora pelas laterais. **Cuidado (checklist):** cena vertical →
conferir com bots que não há queda injusta (cada andar tem chão alcançável abaixo).

**Perigos/mecanismos (reaproveitar tipos existentes):**
| Id | O quê | Apoio físico | Tipo no código |
|---|---|---|---|
| M10 | Balancins que sobem e descem | cabos presos no alto da fachada | `elevador` (existe) |
| M11 | Guincho de material (sobe carga; empurra) | braço preso à laje do andar de cima | `tubos`/`martelo` (avaliar) |
| M12 | Serra de bancada num andar | prancha reforçada | `serra` (existe) |

**Eventos (do mapa, valem em todas as cenas):** G01 Sirene, G02 Ventania (fachada exposta ao vento), G03 Gravidade, G05 Operação
Guindaste (a grua está ao lado), G06 Entrega de Entulho, G10 Carga Especial, G13 Cabo Rompido — e os demais eventos
do mapa, que valem nas 3 cenas (regra A14). Perigo próprio: **M13 Andaime Cede** — um trecho inteiro de andaime cai de
uma vez, com aviso de fita zebrada antes (`APROVADO`).
**Última cena** (mapa de 3): sem transição; luta até sobrar 1. "Nenhum evento" não quebra a cena.

**Chegada (Térreo → Fachada, `APROVADO`):** "A LAJE VAI ESCORREGAR!" → escoras do lado da rua quebram (a base fixa do
Térreo fica) → a laje inclina para a rua → todos escorregam até os andaimes → a câmera gira para a frente do prédio →
nome da cena na tela. Robôs sem dano durante a transição, como na Rota Total.
