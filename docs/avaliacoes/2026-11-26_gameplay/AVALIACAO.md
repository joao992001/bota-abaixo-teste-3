# Avaliação do usuário — gameplay no .exe (2026-11-26, sessão 2)

## Etapa 1 — correções (fazer primeiro) · FEITA (2026-11-26, sessão 2)
O que foi feito: (1) bots com reação/recarga mais lentas e PAUSAS (`bots.pausa`, `pausa_s` em data/modos.json); (2) G03 e a
elegibilidade dos eventos varriam o mapa inteiro várias vezes por quadro → só a cena atual, com cache de 0,25 s; (3) renascimento
evita mecanismos (`mecanismos.zonas_perigo`) e beira de buraco, caminho livre na descida, vento não empurra quem está protegido,
3 s invulnerável (`--so=renascer`); (4) recompensas só com confirmação; (5) cada robô volta a jogar AO POUSAR (Fundação e
Fachada), sem esperar os outros nem teletransportar, com poses de queda/deslize (`--so=transicao`); (6) temas antigos fora do
pré-carregamento (~400 MB de vídeo a menos), texturas da fase "aquecidas" na contagem, G05 sem erro a cada quadro.
Medição: `--perf-canteiro` (com xvfb). Nesta máquina sem GPU o desenho domina; a física fica em ~3 ms por passo.
1. **Bots acelerados demais**: difícil testar o ritmo sem baixar a dificuldade (menos importante).
2. **Evento de GRAVIDADE trava o jogo** (FPS cai).
3. **Renascimento seguro**: quem cai volta num lugar COM CHÃO, dentro da parte jogável, e fica INVULNERÁVEL alguns segundos
   (sem resposta → recomendação: 3 s).
4. **Telas de recompensa só passam com confirmação** (sem avanço automático; qualquer jogador confirma — recomendação).
5. **Transições para Fundação e Fachada mais orgânicas**: mostrar os robôs CAINDO/ESCORREGANDO; onde cada um cair, fica e
   já começa dali (sem teletransporte, sem travar e depois começar).
6. **Quedas de FPS** nas mudanças de cenário e em algumas modificações do cenário (medir: computador × otimização).

Pergunta respondida na hora: a 74% foi para a Fachada porque hoje é <50% fica · 50–89% Fachada · ≥90% Fundação
(o 30%/70% proposto ainda não foi aplicado).

## Etapa 2 — combate (só depois da etapa 1)
7. **Golpe pesado** não é fluido; falta algo que dê vontade de usar.
8. **Golpe leve**: as animações não acompanham; não dá prazer de atacar.
9. **Arte e animação dos robôs** não agradam: pouco articuladas, sem sensação de prazer nos movimentos (prancha/vídeo antes).
10. **Destruição natural pela luta**: arremesso, golpe crítico etc. quebram o cenário; hoje é preciso ficar parado marretando.
    O jogador deve poder "se segurar" para destruir menos (escolher a rota pela forma de lutar).
