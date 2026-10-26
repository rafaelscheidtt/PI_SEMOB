#!/bin/bash
# DashMOB - atalho para Mac: clique duas vezes no Finder.
cd "$(dirname "$0")/../.." || exit 1
# Flutter instalado fora do PATH padrão (ajuste aqui se o seu estiver em outro lugar)
for d in "$HOME/Documents/develop/flutter/bin" "$HOME/development/flutter/bin" "$HOME/flutter/bin" /opt/homebrew/bin; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
fechar() { echo; read -n 1 -s -r -p "Pressione qualquer tecla para fechar..."; exit "${1:-0}"; }

# Compila o app e abre no navegador padrão. Antes, deixe o "2 - subir API" rodando.
command -v flutter >/dev/null || { echo "Flutter não encontrado. Instale pelo docs.flutter.dev."; fechar 1; }
cd frontend
PORTA=8080
echo "== baixando os pacotes do app"
flutter pub get || fechar 1
echo "== compilando o app (leva cerca de 1 minuto)"
flutter build web --release --dart-define=API_URL=http://localhost:8000 || { echo "Erro na compilação."; fechar 1; }
# libera a porta se uma execução anterior ficou aberta
lsof -ti tcp:$PORTA | xargs kill 2>/dev/null
( sleep 2; open "http://localhost:$PORTA" ) &
echo
echo "== DashMOB em http://localhost:$PORTA  (feche esta janela para encerrar)"
python3 -m http.server $PORTA --bind 127.0.0.1 --directory build/web
