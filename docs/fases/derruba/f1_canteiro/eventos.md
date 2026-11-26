# Eventos — Canteiro de Obras (autorização: manifesto → `eventos_permitidos`)

**Regra v2 (APROVADA 2026-11-26, A14):** evento é **do mapa** e acontece em **todas as 3 cenas** (Térreo, Fundação,
Fachada), cada uma com o visual dela. O que só cabe numa cena virou **perigo da cena** ([`perigos_mecanismos.md`](perigos_mecanismos.md)).
**Implementado no Térreo e na Fundação (2026-11-26, teste `--so=eventos_cenas`)**; na Fachada entra com a D5. Manifesto:
`cenas[].eventos` guarda só os V# (perigos). Na Fundação: G12 move as plataformas sobre estaca; G13 desce uma viga pelo
poço (peça gerada, fora do manômetro). Coluna "Nas 3 cenas" = como cada evento fica em cada cena.

| Id | Evento | Estado | Nas 3 cenas (PROPOSTO) |
|---|---|---|---|
| G01 | Sirene de Demolição | APROVADO (volta como evento, A5) | marca um trecho destrutível de qualquer cena |
| G02 | Ventania | APROVADO | Térreo/Fachada: vento de rua · Fundação: exaustores do subsolo |
| G03 | Gravidade em Pane | APROVADO | igual nas 3 |
| G04 | Sobrecarga Magnética | APROVADO | a bobina desce pendurada num cabo em cada cena |
| G05 | Operação Guindaste | APROVADO | Térreo/Fachada: a grua · Fundação: a carga desce pelo poço |
| G06 | Entrega de Entulho | APROVADO | igual nas 3 |
| G10 | Carga Especial | APROVADO (2026-11-25) | igual nas 3 (1–3 ARMADURAS nos holofotes) |
| G11 | Interdição de Área | APROVADO | tapumes sobem do piso / da prancha do andaime |
| G12 | Troca de Andaimes | APROVADO | Térreo/Fachada: andaimes · Fundação: plataformas sobre estaca sobem e descem |
| G13 | Cabo Rompido | APROVADO | Térreo/Fachada: viga da grua · Fundação: viga cai pelo poço |
| G14 | Chuva de Rebites | APROVADO | Fundação: pelo poço · Térreo/Fachada: da estrutura de cima |
| V1 | Concretagem | **SUBSTITUÍDO (A14)** | virou perigo do Térreo (M14) |
| V2 | Desmoronamento | **SUBSTITUÍDO (A14)** | virou perigo da Fundação (M15) |
| V3 | Enchente | **SUBSTITUÍDO (A14)** | virou parte do perigo da água da Fundação (M7) |
| G09 | Inspeção (drone) | REPROVADO no jogo (2026-11-25) | código removido |
