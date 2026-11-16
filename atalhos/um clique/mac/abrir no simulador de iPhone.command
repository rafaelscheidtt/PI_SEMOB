#!/bin/bash
# DashMOB - um clique: sobe a API e abre o aplicativo de iPhone no Simulador do Mac (um iPhone na tela
# do computador). Não precisa de cabo, de conta da Apple nem de mexer no celular: só do Xcode instalado.
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

cd frontend
# A pasta Documentos sincronizada com o iCloud marca os arquivos de um jeito que faz a assinatura
# da Apple falhar ("resource fork, Finder information, or similar detritus not allowed").
# Por isso o aplicativo é montado numa cópia do frontend fora do iCloud; o projeto não sai do lugar.
RAIZ="$(cd .. && pwd)"
OBRA="$HOME/Library/Caches/dashmob/frontend"
echo "== copiando o app para uma pasta fora do iCloud"
mkdir -p "$OBRA"
rsync -a --delete --exclude 'build' --exclude 'build.nosync' --exclude 'build 2' --exclude '.dart_tool' ./ "$OBRA/" || fechar 1
xattr -cr "$OBRA" 2>/dev/null
cd "$OBRA" || fechar 1
# O macOS às vezes põe as ferramentas do Flutter em quarentena e mata o compilador no meio do caminho
# ("impellerc ... failed with exit code -9"); tirar a marca resolve.
FLUTTER_RAIZ="$(dirname "$(dirname "$(command -v flutter)")")"
xattr -dr com.apple.quarantine "$FLUTTER_RAIZ/bin/cache/artifacts/engine" 2>/dev/null
echo "== baixando os pacotes do app"
flutter pub get || fechar 1

echo "== abrindo o Simulador (um iPhone na tela do Mac)"
open -a Simulator || { echo "Não achei o Simulador. Abra o Xcode uma vez e, em Settings > Components, baixe o iOS."; fechar 1; }
APARELHO=""
for tentativa in 1 2 3 4 5 6 7 8 9 10 11 12; do
  LISTA=$(mktemp)
  flutter devices --machine > "$LISTA" 2>/dev/null
  APARELHO=$("$RAIZ/backend/.venv/bin/python" "$RAIZ/scripts/primeiro_celular.py" "$LISTA" simulador)
  rm -f "$LISTA"
  [ -n "$APARELHO" ] && break
  sleep 5
done
if [ -z "$APARELHO" ]; then
  echo
  echo "O Simulador abriu, mas nenhum iPhone ligou nele."
  echo "No Simulador, vá em File > Open Simulator e escolha um iPhone. Se a lista estiver vazia,"
  echo "abra o Xcode, entre em Settings > Components e baixe o iOS. Depois rode este atalho de novo."
  fechar 1
fi

echo "== montando e instalando no Simulador (a primeira vez demora alguns minutos)"
echo "== feche esta janela para encerrar"
flutter run -d "$APARELHO" --dart-define=API_URL=http://localhost:8000 || { echo "Não consegui abrir. Rode 'flutter doctor' pra ver o que falta."; fechar 1; }
fechar 0
