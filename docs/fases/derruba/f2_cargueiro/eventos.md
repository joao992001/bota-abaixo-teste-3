# Eventos — CARGUEIRO PERDIDO (valem em TODAS as cenas do mapa, A14; ids novos continuam a biblioteca G##)

Cada evento: aviso legível em 1 s → efeito → fim. Duração e intervalo vêm de `data/modos.json` (números APROVADOS, ajustam jogando).

| Id | Evento | Cenas | Aviso (1 s) | Efeito | Duração | Estado |
|---|---|---|---|---|---|---|
| G15 | **Onda Gigante** | todas | a água sobe no horizonte + som grave + seta na direção | atravessa a tela e empurra todos para um lado; quem está na beira cai; deixa MOLHADO. Em Atlântida vira CORRENTE (mesmo empurrão, com bolhas) | 3 s | APROVADO |
| G16 | **Tempestade** | 1 · 2a | céu escurece + trovão; antes de cada raio, um círculo amarelo pisca no chão (1 s) | 3–5 raios caem em estruturas destrutíveis: racham (dano 1) — **ajuda a destruir**; robô atingido toma dano leve e fica tonto | 8 s | APROVADO |
| G17 | **Cardume** | 2a · 2b | sombra de peixes aparece numa borda + som de bolhas | um cardume atravessa na altura do meio empurrando de leve quem estiver no caminho (dá para usar para voltar ao palco) | 4 s | APROVADO |
| G18 | **Polvo da Grua** | todas | um tentáculo sai da água/fenda e balança no lugar marcado com anel vermelho | agarra o robô mais perto do anel e o arremessa para o lado oposto; marretada no tentáculo solta | 5 s | APROVADO (a grua adaptada ao mar) |
| G19 | **Bolhão de Ar** | 2b | uma bolha gigante sobe do fundo com brilho | a água do lado direito baixa por alguns segundos (respiro do alagamento M7) | 6 s | APROVADO |

Eventos da biblioteca atual que podem valer aqui (provar NA cena antes de autorizar, `mapa.md` §3 E): G02 Ventania (1),
G10 Carga Especial (todas), G06 Entrega de Entulho → vira "Carga que Cai do Navio" (1, 2a). Os outros do Canteiro não combinam.
