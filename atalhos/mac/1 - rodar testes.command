#!/bin/bash
# DashMOB - atalho para Mac: clique duas vezes no Finder.
cd "$(dirname "$0")/../.." || exit 1
# Flutter instalado fora do PATH padrão (ajuste aqui se o seu estiver em outro lugar)
for d in "$HOME/Documents/develop/flutter/bin" "$HOME/development/flutter/bin" "$HOME/flutter/bin" /opt/homebrew/bin; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
fechar() { echo; read -n 1 -s -r -p "Pressione qualquer tecla para fechar..."; exit "${1:-0}"; }

# Roda os testes da API e do app.
bash scripts/setup_backend.sh testes
echo
if command -v flutter >/dev/null; then
  bash scripts/bootstrap_frontend.sh
else
  echo "Flutter não encontrado: os testes do app ficaram de fora (instale pelo docs.flutter.dev)."
fi
fechar
