# Cena 2a — DESTROÇOS DO CARGUEIRO (`destrocos`) · cena APROVADA · fotografia v3 aguardando aprovação

**Ficha:** o navio partiu ao meio e encalhou num ilhéu de rochas · área `etapa2` · manhã dourada depois da tempestade ·
paleta areia, rocha cinza, casco ferrugem, mar verde-claro · assinatura: as duas metades do navio (ESTRELA DO SUL) tortas
ao fundo, como MOLDURA · câmera fixa · som: maré, madeira rangendo, gaivotas · fotografia: `art/out/fase2/cena2a_destrocos.png`.
Composição em **3 andares**: rochas e balsa (baixo) · pedaço do convés e tábuas (meio) · contêiner içado, rede e tábua alta (alto).

| Estrutura (rótulos da fotografia) | Tipo | Na conta da destruição? |
|---|---|---|
| Rocha da esquerda · rocha-arco (centro) · balsa da direita | **BASE FIXA** | não |
| Navio partido (as duas metades) | moldura de fundo — não se pisa | não |
| Carga derramada (contêineres empilhados na rocha esq.) · contêineres da balsa dir. | destrutível | sim |
| Pedaço do convés (sobre 2 pilares, no meio) | destrutível | sim (peso 2) |
| Convés quebrado (encravado nos dois lados da rocha-arco) | destrutível | sim |
| Mastro-ponte (inclinado da rocha esq. ao navio) | destrutível | sim |
| Tábua (baixa) · tábua alta (presas no braço da grua) | destrutível | sim |
| Contêiner içado · rede de carga (penduradas na grua) | destrutível | sim |
| Bote virado · jangada (rentes ao mar) | destrutível (boiam) | sim |
| Grua amarela (braço por cima de tudo) | **BASE FIXA** (apoio do que está pendurado) | não |

**KO:** mar fundo (esquerda, meio e direita); a maré (M4) só alaga o raso — linha tracejada "maré alta" na fotografia.
**Perigos/mecanismos:** M4 maré sobe e desce · M5 contêiner boiando vira (os da balsa) · M6 rede de carga rasga (rede na
grua) · **M10 tubarão** (barbatana no mar fundo; ataca só plataformas rentes à água: bote, jangada, balsa) — prancha
`art/out/fase2/perigo_tubarao.png`.
**Eventos:** G15 Onda Gigante, G16 Tempestade, G17 Cardume, G18 Polvo da Grua.
**Regra-assinatura — água:** com a maré alta, tudo abaixo da linha fica ALAGADO (lento, pulo flutua, golpe joga longe).
Último nível (sem transição).

### Fundo vivo (A) — PROPOSTO
| Camada | Conteúdo e animação |
|---|---|
| C0 | céu da manhã limpando, sol baixo à esquerda, nuvens da tempestade indo embora |
| C1 | mar calmo até o horizonte, ilhéus distantes, arco-íris fraco, gaivotas pousando e levantando |
| C2 | as duas metades do navio (moldura) rangendo e soltando ferrugem; caranguejos andando nas rochas; boia girando; a ponte de comando torta com luz piscando (curto-circuito); **reagem**: o casco treme e solta poeira quando algo cai |
| C4 | espuma da maré no canto de baixo; corda pendurada da grua passando na frente |
