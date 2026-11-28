# Cena 1 — CARGUEIRO NO ALTO-MAR (`conves`) · fotografia v3 APROVADA (2026-11-28)

**Ficha:** navio porta-contêineres no alto-mar · área `etapa1` · fim de tarde com nuvens de chuva chegando · paleta
azul-marinho do mar, casco vermelho-ferrugem, contêineres coloridos · assinatura: o navio inteiro como MOLDURA (ponte de
comando + pilhas de contêineres ao fundo) · câmera fixa · som: ondas, gaivotas, buzina do navio ·
fotografia: `art/out/fase2/cena1_conves.png`. **Princípio de palco (usuário):** o navio é moldura e não se pisa; a luta é
nas plataformas abertas na frente dele.

| Estrutura (rótulos da fotografia) | Tipo | Na conta da destruição? |
|---|---|---|
| 2 balsas (esq. e dir., rentes ao mar) | **BASE FIXA** | não |
| Pilar de atracação (centro) | **BASE FIXA** (núcleo) | não |
| 2 torres de andaime e a torre da grua | **BASE FIXA** (apoio dos níveis altos) | não |
| Pilhas de contêineres separadas | destrutível | sim |
| Tábuas dos níveis 9 e 6 | destrutível | sim |
| Contêiner no gancho (M2) · viga içada (nível 3) · bote pendurado | destrutível | sim |

**KO:** mar embaixo (dos dois lados das balsas) + bordas laterais e topo.
**Perigos/mecanismos (prancha `art/out/fase2/perigos.png`):** M1 contêiner despenca (lugar sorteado nas plataformas),
M2 gancho balança (preso na torre da grua), M3 onda estoura na balsa (só as balsas) — ver `../perigos_mecanismos.md`.
**Eventos (todos do mapa, A14):** G15 Onda Gigante, G16 Tempestade, G18 Polvo da Grua (`../eventos.md`).
**Regra-assinatura — água:** só as balsas molham (onda M3); o resto é seco.

### Fundo vivo (A) — APROVADO
| Camada | Conteúdo e animação |
|---|---|
| C0 | céu de fim de tarde com nuvens de chuva chegando da direita (escurecem aos poucos com a luta); sol baixo |
| C1 | mar aberto com ondas andando, outro navio pequeno no horizonte, gaivotas, farol piscando ao longe |
| C2 | o cargueiro (moldura): fumaça na chaminé, luzes da ponte de comando, marinheiros-robôs NPC na amurada que **reagem** (apontam e se escondem quando algo cai); bandeira tremulando; o navio balança devagar |
| C4 | cordas e boia salva-vidas passando na frente; respingos de onda no canto de baixo |

### Transições (cena intermediária = DUAS saídas, v2)
| Rota | Gatilho | Cinematografia (storyboard em `art/out/fase2/transicoes.png`) |
|---|---|---|
| **Moderada → 2a Destroços** | verificação no tempo com **≥ 40%** | sirene do navio + faixa "O NAVIO VAI ENCALHAR!" → o navio é arrastado pela corrente e bate nas rochas → tranco: todos são lançados num arco **para a direita** (deslize, como a Fachada) e pousam nos destroços; a câmera acompanha de lado |
| **Total → 2b Atlântida** | **≥ 70% na verificação (A56)** | rachadura corre pelo casco + faixa "O NAVIO VAI AFUNDAR!" → o navio parte ao meio e afunda → **queda lenta pelo porão aberto** descendo o mar (bolhas, peixes, luz escurecendo) com a câmera descendo junto → pousam em Atlântida; contêineres afundando viram pedaços do navio lá embaixo |
