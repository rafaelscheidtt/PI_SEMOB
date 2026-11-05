#!/bin/bash
# DashMOB - um clique: sobe a API e abre o app no navegador deste computador.
cd "$(dirname "$0")/../../.." || exit 1
for d in "$HOME/Documents/develop/flutter/bin" "$HOME/development/flutter/bin" "$HOME/flutter/bin" /opt/homebrew/bin; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
fechar() { echo; read -n 1 -s -r -p "Pressione qualquer tecla para fechar..."; exit "${1:-0}"; }
command -v flutter >/dev/null || { echo "Flutter não encontrado. Instale pelo docs.flutter.dev."; fechar 1; }

# banco
if [ ! -f backend/.env ]; then
  printf 'MONGODB_URL=COLE_AQUI_A_URL_QUE_O_GUILHERME_MANDOU\nMONGODB_DB=dashmob\nCORS_ORIGINS=*\n' > backend/.env
fi
if grep -q COLE_AQUI backend/.env; then
  echo "Falta configurar o banco. Vai abrir o backend/.env no TextEdit:"
  echo "troque a primeira linha pela MONGODB_URL que o Guilherme mandou, salve e rode este atalho de novo."
  open -e backend/.env
  fechar 1
fi

# API em segundo plano (morre junto com esta janela)
echo "== preparando a API"
( cd backend && { [ -d .venv ] || python3 -m venv .venv; } && .venv/bin/pip install -q -r requirements.txt ) || fechar 1
lsof -ti tcp:8000 | xargs kill 2>/dev/null
( cd backend && exec .venv/bin/python -m uvicorn app.main:app --port 8000 ) &
API_PID=$!
trap 'kill $API_PID 2>/dev/null' EXIT

# app
cd frontend
echo "== baixando os pacotes do app"
flutter pub get || fechar 1
echo "== compilando o app (leva cerca de 1 minuto)"
flutter build web --release --dart-define=API_URL=http://localhost:8000 || { echo "Erro na compilação."; fechar 1; }
lsof -ti tcp:8080 | xargs kill 2>/dev/null
( sleep 2; open "http://localhost:8080" ) &
echo
echo "== DashMOB em http://localhost:8080   API em http://localhost:8000/docs"
echo "== feche esta janela para encerrar os dois"
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
