# Perigos e mecanismos — Canteiro de Obras (instâncias: manifesto → `cenas[].mecanismos`)

| Id | Tipo | Cena | Classe | Estado | Nota |
|---|---|---|---|---|---|
| M1 | betoneira | Térreo | mecanismo perigoso (concreto fresco deixa lento) | APROVADO | |
| M2 | elevador | Térreo | mecanismo (carona, nunca esmaga) | APROVADO | |
| M3 | esteira | — | — | REPROVADO (2026-11-24) | composição sem sentido |
| M4 | tubos | Térreo | mecanismo perigoso (rolam) | APROVADO | |
| M5 | serra (bancada no chão) | Térreo | mecanismo perigoso | APROVADO | antes numa passarela solta (reprovado) |
| M6 | bate_estaca (torre) | Fundação | mecanismo perigoso | APROVADO | torre apoiada no piso (2026-11-25) |
| M7 | agua | Fundação | perigo (lentidão) + choque com M9 | APROVADO | cachoeiras e jorros (2026-11-25) |
| M8 | vagonete | Fundação | mecanismo perigoso | APROVADO | só na laje esquerda |
| M9 | gerador | Fundação | perigo (faísca) | APROVADO | |
| M7+ | agua (enchente) | Fundação | a bomba falha e a água sobe alto (ex-evento V3) | A IMPLEMENTAR (A14, 2026-11-26) | ciclo raro do M7 |
| M13 | andaime cede | Fachada | um trecho inteiro de andaime cai, com fita zebrada antes (ex-"V4") | APROVADO (conceito) | ver `cenas/fachada.md` |
| M14 | concretagem da grua | Térreo | a grua despeja concreto: quem pisa fica lento (ex-evento V1) | A IMPLEMENTAR (A14) | |
| M15 | desmoronamento | Fundação | pedaços do Térreo caem pelo poço (ex-evento V2) | A IMPLEMENTAR (A14) | |
Perigo estrutural: vãos do piso da Fundação e bordas do Térreo (cair = KO).
