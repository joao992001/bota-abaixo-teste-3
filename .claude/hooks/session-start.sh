#!/bin/bash
# PASSAGEM DE BASTÃO (docs/BASTAO.md): todo chat novo — de qualquer conta — começa vendo quem está fazendo o quê,
# os arquivos reservados e o "próximo passo exato" de cada tarefa. O texto que este script imprime entra no
# contexto da sessão. Rápido (sem instalar nada) e nunca falha a sessão.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
br="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
timeout 20 git fetch -q origin "$br" 2>/dev/null || true
atras="$(git rev-list --count "HEAD..origin/$br" 2>/dev/null || echo 0)"
echo "=== PASSAGEM DE BASTÃO (docs/BASTAO.md) — leia antes de qualquer coisa ==="
echo "Branch: $br"
if [ "${atras:-0}" != "0" ]; then
  echo "ATENÇÃO: este contêiner está $atras commit(s) ATRÁS do GitHub (outro chat enviou trabalho)."
  echo "Rode antes de tudo: git pull --rebase origin $br"
fi
if [ -f docs/BASTAO.md ]; then
  sed -n '/^## EM ANDAMENTO/,/^## CONCLUÍDO/p' docs/BASTAO.md | sed '$d'
else
  echo "(docs/BASTAO.md não existe neste contêiner — faça git pull)"
fi
echo "Regras: docs/COMO_TRABALHAR.md §6. Pegou tarefa → atualize o bloco e faça commit+push ANTES; a cada passo,"
echo "marque [x] + 'Próximo passo exato' e envie junto com o trabalho. O contêiner some: o que não foi enviado se perde."
command -v godot >/dev/null 2>&1 || echo "Godot não está instalada aqui: bash tools/setup_nuvem.sh (a partir da pasta acima do repositório)."
exit 0
