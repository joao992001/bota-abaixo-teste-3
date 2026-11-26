# Cena 1 — TÉRREO (`terreo`) · Canteiro de Obras

**Ficha:** composição Ponte (palco largo, vãos embaixo) · 40×22 tiles (`etapa1: 0,0,40,22`) · manhã ensolarada · paleta céu
`#bfe9ef`, concreto `#d8ccb6`, madeira/laranja `#c98a4b`/`#f08a3d` · assinatura: a grua amarela gigante · fotografia:
`art/out/fase1_etapa1.png`.

| Estrutura | Tipo | Na conta dos 90%? |
|---|---|---|
| Núcleo: 2 trechos de laje sobre pilares (`lajes.nucleo`) | **BASE FIXA** (nunca leva dano) | não |
| Chão do térreo dos lados (`terreos`) | **BASE FIXA** | não |
| 4 trechos de laje sobre escoras (hp 4 + escoras 2) | destrutível | sim (peso 8 cada) |
| 2 andaimes laterais (hp 3) | destrutível | sim (peso 5) |
| 5 vigas penduradas (hp 2) | destrutível | sim (peso 8/4/4/4/4) |

Perigos/mecanismos: M1 betoneira, M2 elevador, M4 tubos, M5 serra de bancada ([`../perigos_mecanismos.md`](../perigos_mecanismos.md)).
Eventos: G05, G06, G10, G12, G13, G02, V1 ([`../eventos.md`](../eventos.md)).
Deterioração espontânea: **nenhuma** (diretor removido na D1, 2026-11-26); "sirene + fita → o trecho cede" só com o evento G01.
**Rotas (v2):** total → Fundação (implementada) · moderada → Fachada (aprovada, entra na D5; até lá 50–90% fica).
**Transição:** aos 90% → "A OBRA VAI CEDER!" → a cena inteira (inclusive núcleo e térreo) desaba → queda lenta pelo poço
(`buraco1: 10,30`) com a câmera descendo junto → Fundação. Pedaços da laje viram entulhos lá embaixo.
