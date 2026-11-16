#!/bin/bash
# DashMOB - um clique: instala o aplicativo de verdade no celular ligado no cabo (Android ou iPhone)
# e sobe a API liberada pra rede Wi-Fi. O celular precisa estar na MESMA rede Wi-Fi deste computador.
#
# Antes da primeira vez:
#   Android: ligar "Opções do desenvolvedor" e "Depuração USB" no celular e ter o Android Studio instalado.
#   iPhone:  ter o Xcode instalado, abrir frontend/ios/Runner.xcworkspace uma vez e escolher a sua conta
#            em Runner > Signing & Capabilities > Team. No iPhone, confiar no computador e no desenvolvedor.
#   Dúvida sobre o que falta instalar: rode "flutter doctor" no Terminal.
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

# endereço deste computador na rede Wi-Fi (é pra onde o app do celular vai ligar)
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
IP=$(ipconfig getifaddr "${IFACE:-en0}" 2>/dev/null)
[ -n "$IP" ] || IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
[ -n "$IP" ] || { echo "Não achei o endereço deste computador na rede. Conecte no Wi-Fi e tente de novo."; fechar 1; }

# API em segundo plano, aberta pra rede (morre junto com esta janela)
echo "== preparando a API"
( cd backend && { [ -d .venv ] || python3 -m venv .venv; } && .venv/bin/pip install -q -r requirements.txt ) || fechar 1
lsof -ti tcp:8000 | xargs kill 2>/dev/null
( cd backend && exec .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 ) &
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

# primeiro celular (Android ou iPhone) que o Flutter enxergar
echo "== procurando o celular"
LISTA=$(mktemp)
flutter devices --machine > "$LISTA" 2>/dev/null
APARELHO=$("$RAIZ/backend/.venv/bin/python" "$RAIZ/scripts/primeiro_celular.py" "$LISTA")
rm -f "$LISTA"
if [ -z "$APARELHO" ]; then
  echo
  echo "Não achei nenhum celular. Confira:"
  echo "  - o cabo está ligado e o celular desbloqueado;"
  echo "  - Android: Depuração USB ligada e o aviso 'Permitir depuração' aceito;"
  echo "  - iPhone: 'Confiar neste computador' aceito."
  echo "O que o Flutter está enxergando agora:"
  flutter devices
  fechar 1
fi

echo "== instalando no celular (a primeira vez demora alguns minutos)"
echo "== a API fica em http://$IP:8000 ; feche esta janela para encerrar"
# instala e abre; o "flutter run" termina quando o cabo é tirado, mas a API precisa continuar no ar
flutter run --release -d "$APARELHO" --dart-define=API_URL="http://$IP:8000"
echo
echo "== Se o app abriu no celular, pode tirar o cabo: ele continua funcionando enquanto esta janela"
echo "== ficar aberta e o celular estiver no mesmo Wi-Fi. Se não abriu, veja o erro acima"
echo "== (o 'flutter doctor' mostra o que falta instalar)."
echo "== Para encerrar, aperte qualquer tecla ou feche esta janela."
fechar 0
