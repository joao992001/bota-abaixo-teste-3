# Bota-Abaixo — documento do jogo (GDD)

Atualizado em 2026-11-21. Estado técnico e como rodar: `docs/ESTADO.md`. Problemas de fase em aberto: `docs/dossie_fases.md`.

## 1. Visão
Party game de plataforma, **multiplayer local de 2 a 4 jogadores** (com bots para completar a mesa).
Robôs de demolição se enfrentam com marretas em obras, fábricas, portos e minas.
- **Gênero:** brawler/party de plataforma 2D (referências de estilo: BattleBlock Theater, Heave Ho, Ultimate Chicken Horse).
- **Plataforma:** PC (Windows/Linux), Godot 4. Controle (Xbox/PlayStation) ou teclado dividido.
- **Sessão:** partidas curtas, rodadas de 30 s a 2 min; quem vencer 5 rodadas leva a partida (padrão).
- **Fora do escopo:** online, campanha e editor de mapas.

**Pilares**
1. Jogável na hora: apertou PULAR, entrou.
2. Controle responsivo antes de animação bonita.
3. Caos legível: em 1 s cada um entende o que é perigoso para ele.
4. Visual cartoon de papel e giz, com contorno grosso e cores fortes por cenário.

## 2. Controles
| Ação | Controle | Teclado A (esquerda) | Teclado B (direita) |
|---|---|---|---|
| Andar / subir / descer | analógico esquerdo · direcional | W A S D | setas |
| Pular (segurar = mais alto) | A / ✕ | G · Espaço | 1 numérico · K |
| Golpe rápido | X / □ | H | 2 numérico · L |
| Marretada pesada | Y / △ | J | 3 numérico · Ç (;) |
| Esquiva | RB / R1 · RT / R2 | Y | 4 numérico · O |
| Especial (engenhoca) | LB / L1 · LT / L2 | U | 5 numérico · P |
| Pausa | START / OPTIONS | Enter · Esc | Enter numérico |

Sem Shift/Ctrl (o Windows manda "fantasmas" deles). **Cada aparelho remapeia só ele** em OPÇÕES ▸ CONTROLES
(principal + alternativo por ação; o jogo reconhece DualSense, DualShock 4, Xbox, Switch Pro e genérico e mostra os ícones de cada um).

Movimento: corrida, pulo variável, tempo de "coiote", buffer de pulo, deslizar e pular na parede (com medidor de aderência), pisão na cabeça.

## 3. Regras comuns
- **Marreta:** empurra o rival e quebra caixotes. **Amassômetro (%):** cada golpe soma dano; quanto maior o %, mais longe o golpe joga (estilo Smash).
- **Caixotes:** quebráveis (2 golpes; 1 na Batata). Blocos fixos nunca quebram.
- **Itens:** caem de paraquedas em cima de qualquer chão; encostou, pegou. Uns ligam na hora (botas, patins, escudo), outros se usam com o botão ITEM.
- **Eventos:** a cada tanto tempo um evento muda a fase (frequência nos Ajustes: desligado, baixa, média, alta).
- **Câmera:** arena inteira na tela (Derruba, Batata, Rei); na Fuga a câmera rola.
- **Rodízio:** a 1ª rodada é na fase escolhida, as seguintes passam para a próxima fase do modo (ou "Sorteio").
- **Bots:** 3 níveis; jogam todos os modos (na Fuga ainda não chegam ao elevador).

## 4. Modos
| Modo | Objetivo | Como se perde | Ajustes |
|---|---|---|---|
| **Derruba** | Ser o último de pé | Cair em espinho/poço gasta 1 vida | Vidas 1–5 |
| **Batata-Dinamite** | Não estar com a dinamite quando o pavio acaba | Encostar ou marretar passa a bomba; explodiu, sai da rodada | Pavio curto (10–14 s), normal (14–20 s), longo (20–28 s) |
| **Rei da Obra** | Segurar o capacete de ouro até somar o tempo | Qualquer golpe derruba o capacete; o rei anda mais devagar | Meta 20 / 30 / 45 s |
| **Fuga** | Chegar primeiro ao elevador | A tela (ou a lama) que alcança você tira da rodada; cair só atrasa | — |

Batata e Rei têm **mapa vivo**: itens a cada 3–5 s (até 3 na fase), eventos quase 2× mais frequentes e alavancas que se acionam sozinhas a cada ~12 s (com aviso "!").

## 5. Itens
**Derruba (12):** dinamite, martelão, botas de mola, bota-foguete, furadeira, cola, ímã, teletransporte, raio laser, bomba de vórtice, soprador, raio congelante.

**Batata-Dinamite (8)**
| Item | Efeito |
|---|---|
| Estilingue de TNT | Arremessa a bomba para a frente; se errar, ela continua com você |
| Patins | +40% de velocidade por 7 s |
| Escudo de borracha | Por 6 s ninguém passa a bomba para você |
| Teletransporte | Troca de lugar com alguém |
| Relógio | Com a bomba: +4 s no pavio. Sem ela: −3 s no pavio de quem está |
| Ímã · Soprador · Raio congelante | Puxa rivais · empurra para longe · congela |

**Rei da Obra (9)**
| Item | Efeito |
|---|---|
| Onda de choque | Intocável por 1,6 s, depois joga longe quem está perto (300 px) |
| Laço | Laça o primeiro rival à frente (7 tiles) e puxa até colar em você; se for o rei, o capacete voa |
| Patins · Cola · Raio congelante | Velocidade · poça que deixa lento · congela |
| Soprador · Botas de mola · Bota-foguete · Vórtice | Afasta quem chega · pula mais · voa · puxa todos |

**Fuga (9)**
| Item | Efeito |
|---|---|
| Barreira | Muro de 2 caixotes atrás de você |
| Gancho | Puxa você até a beirada mais alta à frente (até 7 tiles) |
| Patins · Bota-foguete · Botas de mola | Correr, voar, pular mais |
| Cola · Teletransporte · Raio congelante · Soprador | Atrasar quem vem atrás ou alcançar o líder |

## 6. Fases (6 por modo, 12 cenários)
| Modo | Fases (cenário · interação principal) |
|---|---|
| Derruba (30×16) | Canteiro (canteiro · ilhas de caixote, terremoto) · Guindastes (porto · plataformas móveis) · Gangorras (serraria · gangorras sobre estacas) · Fábrica de Esteiras (fábrica · esteiras que invertem) · Prensa (ferro-velho · prensas e alçapão) · Fornalha (fundição · chamas e barris) |
| Batata (44×24, sem espinho) | Obra de Concreto (portas que trocam) · Galerias da Mina (túneis e tubos) · Prédio Velho (volta pelos andares, alçapão) · Sob o Viaduto (plataformas e ventilador) · Palafitas (pontes e trampolins) · Telhados (trampolins nos becos) |
| Rei (44×24, trono `K`) | Trono do Canteiro (torre com portas) · Linha de Montagem (esteiras, ventilador, prensas) · Rei do Cais (guindastes) · Mina de Ouro (elevador e tubos) · Serraria Real (pirâmide de toras) · Prédio em Demolição (bola de demolição) |
| Fuga | Torre em Ruínas (sobe) · Obra Subindo (sobe) · Descida da Fundição (desce) · Viaduto em Obras (avança) · Ferro-Velho (avança) · Pântano Subindo (lama sobe) |

**Elementos de fase:** caixote, TNT, tábua fina (sobe por baixo, desce com ▼), espinho, água, rede, esteira, ventilador, chama, prensa, barril, alavanca + alçapão, porta (aberta/fechada; a alavanca inverte), trampolim (6 tiles), tubos de teletransporte (pares), plataformas móveis, gangorra, bola de demolição, elevador de chegada.
Mapas em texto (`levels/*.lvl`, formato em `levels/README.md`); geradores em `tools/mapas/`.

**Regras de level design** (detalhes em `docs/dossie_fases.md`): uma ideia principal por fase; centro disputado com voltas; degraus de 3 tiles, vãos até 4; alavanca perto do que controla; nada flutuando sem motivo; spawns justos.

## 7. Eventos
Chuva de Caixas · Gravidade Baixa · Ventania · Apagão · Chão Ensaboado · Hora do Martelão · Chuva de Dinamite · Tremores · Vigas Desgovernadas. Cada um avisa 2 s antes.

## 8. Personagens e personalização
**8 modelos de robô** (Lata, TV, Baixinho, Pescoção, Brutamontes, Varapau, Barril, Bolha), cada um com silhueta, voz e comemoração próprias. São **só aparência**: a hitbox e os números de jogo são iguais. Cada jogador escolhe o modelo na entrada (▲▼); o corpo sai na cor do jogador. Sem personalização (Garagem removida em 2026-11-23).

## 9. Interface e áudio
Estilo cartoon (cartões com contorno grosso). HUD discreto no topo: retrato, nome, estrelas de rodadas, vidas/% e pílula do modo (segundos de rei, pavio). Menus: Modo → Arena → Ajustes → Entrada; Opções, Controles, Garagem, Oficina (fase de testes).
Música "funk de obra" e efeitos "retrô limpo", gerados por código (`tools/musica.py`, `tools/sfxforge.py`); sem IA geradora de imagem ou áudio.

## 10. Números de referência
Resolução lógica 1920×1080 · grade de 64 px · hitbox do robô 48×72 · física a 60 ticks · pulo ~3,9 tiles · trampolim ~6 tiles.
Valores ajustáveis em `data/controller.json` (controle) e `data/modos.json` (modos, itens, arenas, eventos).
