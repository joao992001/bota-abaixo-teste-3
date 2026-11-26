# Contrato do PERFIL SALVO (Derruba v2) — `PROPOSTO` (etapa C, 2026-11-26) · implementação na etapa D4

Perfil **local** (sem contas, sem rede — `CLAUDE.md` proíbe online). Base: `progressao.md` §4. Este arquivo fixa o
formato para a D4 e para o online futuro não exigir migração difícil.

## 1. Onde e como grava
- Arquivo `user://perfil.json` (Godot: pasta do usuário do sistema). Um perfil = a "conta responsável" do local.
- Escrita segura: grava em `perfil.json.tmp` e renomeia; guarda o anterior em `perfil.json.bak`.
- Leitura: arquivo ausente → perfil novo. JSON quebrado → tenta `.bak`; se falhar, perfil novo e o quebrado vira
  `perfil.json.corrompido` (nunca apaga sem guardar).
- Grava em 3 momentos: fim da partida (resultados), ao confirmar uma configuração e ao sair do jogo.
- `versao` do esquema: o código migra versões antigas para a atual ao ler (uma função por versão).

## 2. Esquema v1
```json
{
  "versao": 1,
  "criado": "2026-11-26T12:00:00Z",
  "gangorra": {"valor": 0, "extremo_verde": "skin", "extremo_vermelho": "spell"},
  "desbloqueados": {"mapas": ["canteiro_obras"], "spells": ["*"], "eventos": ["*"], "skins": ["*"]},
  "novos": ["T03"],
  "cenas_visitadas": {"canteiro_obras": ["terreo", "fundacao"]},
  "pontos_exploracao": 4,
  "estrelas": {"canteiro_obras": 7},
  "ultima_config": {
    "mapa": "canteiro_obras", "vidas": 4,
    "spells": ["A01", "A02", "C01", "E02", "T03"], "eventos": ["G01", "G02", "V1"],
    "jogadores": [{"dispositivo": "pad0", "robo": 2, "skin": "", "bot": false}]
  },
  "estatisticas": {"partidas": 12, "vitorias_por_slot": [5, 3, 2, 2]}
}
```

| Campo | Para quê | Regra |
|---|---|---|
| `gangorra.valor` | agulha −100…+100 | limitado ao intervalo; extremos sorteiam categoria nova depois do prêmio |
| `desbloqueados.*` | travas futuras | `"*"` = tudo liberado (**hoje**, A9); com travas vira lista de ids |
| `novos` | marcar **NEW** nas telas | sai da lista quando o item aparece selecionado pela 1ª vez |
| `cenas_visitadas` | ✓/? no cartão do mapa e o +2 de cena inédita | id da cena do manifesto; só entra quem chegou na cena |
| `pontos_exploracao` | Projetos de Demolição | +1 partida válida, +2 cena inédita (`progressao.md` §2) |
| `estrelas` | "Jogar de novo: estrelas vão somando" | por mapa; zera ao trocar de mapa? → **DECIDIR** |
| `ultima_config` | "Jogar de novo" e "Configurar mapa" sem refazer as telas | ids estáveis; item que sumiu do manifesto é ignorado |

## 3. Ids estáveis (não renomear depois de gravados)
`map_id` (`canteiro_obras`), `id` das cenas (`terreo`, `fundacao`, `fachada`), spells `A##/C##/E##/T##`, eventos
`G##/V##`, skins `K#`. Renomear um id exige uma migração de versão (§1).

## 4. Preparado para o online (sem implementar)
- Tudo que é "da conta" já está aqui (gangorra, desbloqueados, exploração, skins). No online, cada jogador terá o seu
  perfil; o anfitrião usa o dele para mapas/spells/eventos (`progressao.md` §3).
- Campos reservados (não usar agora): `conta_id`, `sincronizado_em`.
- Bots e convidados locais **não** têm perfil: a partida local credita só o perfil local.

## 5. Testes da D4 (para o `driver.gd`)
Perfil novo; ida e volta (grava → lê igual); JSON quebrado → `.bak`; migração v0→v1; `ultima_config` com item removido;
+2 só na 1ª visita da cena; gangorra presa em −100/+100.
