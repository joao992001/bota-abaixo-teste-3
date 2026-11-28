# Manual de ANIMAÇÃO — perigos, mecanismos e efeitos

Criado em 2026-11-28 depois da crítica do usuário ao vídeo da cena 1 do Cargueiro ("a onda desconecta do mar, não tem
impacto nenhum sobre o personagem, a movimentação e a queda do contêiner muito ruins — ficou muito aquém do projeto").
Vale para TODO perigo/mecanismo/evento animado. Leia junto com `perigos_mecanismos.md` e `desempenho.md`.

## 1. O que deu errado (não repetir)
- **Troca de 3–5 desenhos parados** para coisa grande e fluida (onda, queda). Fica "slide show". Sprite parado só para
  objeto rígido; o MOVIMENTO vem do código, a 60 quadros/s.
- **Elemento descolado do mundo**: a onda aparecia flutuando no convés, sem sair do mar. Todo elemento nasce de algo
  que já está na tela (água sai do mar, contêiner sai do gancho/navio, pedra sai da parede) e volta para algum lugar.
- **Sem reação no personagem**: o golpe só mudava um número. Toda pancada mostra o robô sendo atingido.
- **Revisão só por foto parada**. Animação se revisa em vídeo, em câmera lenta.

## 2. As 5 batidas obrigatórias (todo perigo)
| Batida | O que é | Exemplo (onda) |
|---|---|---|
| 1. Antecipação | aviso legível em 1 s, que cresce (som + tremor crescente) | o mar incha na borda, sobe até o convés, cospe espuma |
| 2. Ação | movimento rápido, com arco e aceleração (nada linear) | a parede dispara para cima e a crista encurva |
| 3. Impacto | 1 quadro forte: estouro, partículas, tremor, som, congelamento | o lábio bate: leque de gotas + névoa + tremor 9 |
| 4. Reação | o robô atingido VOA/estica/pisca (hitstop 0,06–0,1 s, `vis.hurt`, `knock`), partículas nele | arremessado para dentro, respingo no corpo, fica molhado |
| 5. Assentamento | o elemento volta ao mundo e deixa rastro | a lâmina escoa em cascata para o mar; convés molhado pinga |

## 3. Princípios aplicados (checar um por um)
- **Tempo e espaçamento**: ease-in na queda (acelera), ease-out na subida (sai rápido e desacelera). Nada de `lerp` linear.
- **Achatar e esticar**: o que bate achata (contêiner ~12% no impacto), gota rápida estica na direção do movimento.
- **Arcos**: pêndulo, gotas, crista — tudo em curva.
- **Ação secundária**: cabos balançam, poeira, lascas, gotas, névoa, rachadura.
- **Continuação**: depois do pico o elemento passa um pouco do ponto e volta (quique do contêiner, balanço do cabo).
- **Camadas de papel**: corpo + faixa clara + sombra + espuma/destaque, sem contorno, bordas tremidas (estilo do jogo).

## 4. Técnica
- Deformação procedural: contorno por pontos de controle em POSES nomeadas, interpoladas com suavização e desenhadas
  com spline (ex.: `game/modes/mec_onda.gd`: poses liso → incha → suga → ergue → bate → afunda → some).
- Um arquivo por perigo grande (`mec_<nome>.gd`), com `update(dt)`, `draw(ci)` e a regra de jogo junto (o que o robô
  sente bate exatamente com o que se vê).
- Ler o mundo (piso, peças) **uma vez** no início do aviso, nunca por quadro. ≤150 partículas por perigo.

## 5. Revisão antes de mostrar ao usuário (obrigatório)
1. `godot --headless --path game --import` (sem isso a arte não carrega).
2. Vídeo normal e câmera lenta do perigo, com robôs no caminho:
   `godot --path game -- --cargueiro-video=DIR --video-cena=1 --video-so=onda_balsa --video-passo=1`
   → ffmpeg 60 fps (normal) e 15 fps (¼ de velocidade).
3. Folha de quadros das 5 batidas; conferir a tabela da seção 2 e os princípios da seção 3, item por item.
4. Só então enviar: vídeo normal + lento, e o que ainda está fraco (honesto).
