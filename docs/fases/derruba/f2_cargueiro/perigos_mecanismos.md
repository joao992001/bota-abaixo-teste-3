# Perigos e mecanismos — CARGUEIRO PERDIDO (instâncias: manifesto → `cenas[].mecanismos`; prancha `art/out/fase2/perigos.png`)

| Id | Elemento | Cena | Classe | Aviso (1 s) → efeito | Estado |
|---|---|---|---|---|---|
| M1 | Contêiner despenca do navio | 1 | perigo | amarras estalam + SOMBRA VERMELHA (1,5 s) → golpe forte, racha a plataforma; fica como plataforma nova (ou afunda no mar); ~20 s, lugar sorteado | APROVADO (ideia do usuário) |
| M2 | Gancho balança | 1 | mecanismo perigoso | grua range + arco tracejado → o contêiner varre o arco e empurra; marretada inverte; ~12 s | APROVADO |
| M3 | Onda estoura na balsa | 1 | perigo | água incha na borda (1 s) → empurra + MOLHADO (lento) 2 s; só balsas; ~15 s alternando | APROVADO |
| M4 | Maré sobe e desce | 2a | perigo | seta + som → até a linha da maré alta fica ALAGADO (lento, pulo flutua); o que boia sobe; ~8 s; a cada ~25 s | APROVADO |
| M5 | Contêiner boiando vira | 2a | mecanismo perigoso | 2+ robôs: range e afunda um lado → em 1 s vira e joga na água; volta em ~4 s | APROVADO |
| M6 | Rede de carga rasga | 2a | mecanismo perigoso | marretada pesada → rasga, caixas caem em quem está embaixo; vira saco vazio | APROVADO |
| M7 | Racha da cúpula alaga | 2b | perigo | racha pinga/brilha → lado direito alagado; marretada no vidro faz crescer; evento Bolhão de Ar baixa | APROVADO |
| M8 | Lustre despenca | 2b | mecanismo perigoso | marretada na corrente → estala + SOMBRA VERMELHA (1 s) → esmaga e racha a plataforma; some | APROVADO |
| M10 | Tubarão | 2a | perigo | barbatana ronda o mar fundo; acelera para a plataforma baixa + anel vermelho + som (1,5 s) → salta e morde (joga para cima/lado; racha contêiner boiando); marretada no focinho espanta; só plataformas rentes à água; KO no mar = abocanhado (só animação) | APROVADO (ideia do usuário, prancha `perigo_tubarao.png`) |
| M11 | Gêiser na fenda | 2b | mecanismo (salva-vidas) | o fundo da fenda BORBULHA e brilha (1,5 s) → JORRA um jato (~2,5 s): quem cai ali é jogado de volta para cima (não cai, sem dano); quem entra no jato sobe até as lajes altas (elevador); ~10 s alternando entre as 2 fendas | PROPOSTO (ideia do usuário 2026-11-28) — prancha `art/out/fase2/perigo_geiser.png` (fonte `f2_geiser.py`) |
| M9 | Concha-trampolim | 2b | mecanismo | pisou: lança alto; depois FECHA 2 s e prende (marretada abre) | APROVADO |
Perigo estrutural (KO): mar embaixo (1, 2a) e Fenda Abissal (2b); bordas abertas. 
