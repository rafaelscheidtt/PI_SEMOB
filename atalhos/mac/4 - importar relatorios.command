#!/bin/bash
# DashMOB - atalho para Mac: clique duas vezes no Finder.
cd "$(dirname "$0")/../.." || exit 1
# Flutter instalado fora do PATH padrão (ajuste aqui se o seu estiver em outro lugar)
for d in "$HOME/Documents/develop/flutter/bin" "$HOME/development/flutter/bin" "$HOME/flutter/bin" /opt/homebrew/bin; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
fechar() { echo; read -n 1 -s -r -p "Pressione qualquer tecla para fechar..."; exit "${1:-0}"; }

# a API precisa do backend/.env com a MONGODB_URL do Atlas
if [ ! -f backend/.env ]; then
  printf 'MONGODB_URL=COLE_AQUI_A_URL_QUE_O_GUILHERME_MANDOU\nMONGODB_DB=dashmob\nCORS_ORIGINS=*\n' > backend/.env
fi
if grep -q COLE_AQUI backend/.env; then
  echo "Falta configurar o banco. Vai abrir o backend/.env no TextEdit:"
  echo "troque a primeira linha pela MONGODB_URL que o Guilherme mandou, salve e rode este atalho de novo."
  open -e backend/.env
  fechar 1
fi

# Importa todos os relatórios de dados/semob para o banco. Só precisa quando chegarem relatórios novos;
# importar de novo o mesmo período não duplica nada.
bash scripts/setup_backend.sh importar
echo
echo "== importação concluída"
fechar
