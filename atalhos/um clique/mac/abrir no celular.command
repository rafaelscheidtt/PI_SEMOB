#!/bin/bash
# DashMOB - um clique: sobe a API e o app liberados pra rede Wi-Fi e mostra o QR code
# pra abrir no celular (o celular precisa estar na MESMA rede Wi-Fi deste computador).
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

# endereço deste computador na rede Wi-Fi
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
IP=$(ipconfig getifaddr "${IFACE:-en0}" 2>/dev/null)
[ -n "$IP" ] || IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
[ -n "$IP" ] || { echo "Não achei o endereço deste computador na rede. Conecte no Wi-Fi e tente de novo."; fechar 1; }

# API em segundo plano, aberta pra rede (morre junto com esta janela)
echo "== preparando a API"
( cd backend && { [ -d .venv ] || python3 -m venv .venv; } && .venv/bin/pip install -q -r requirements.txt qrcode ) || fechar 1
lsof -ti tcp:8000 | xargs kill 2>/dev/null
( cd backend && exec .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 ) &
API_PID=$!
trap 'kill $API_PID 2>/dev/null' EXIT

# app apontando pra API pelo endereço da rede
cd frontend
echo "== baixando os pacotes do app"
flutter pub get || fechar 1
echo "== compilando o app (leva cerca de 1 minuto)"
flutter build web --release --dart-define=API_URL="http://$IP:8000" || { echo "Erro na compilação."; fechar 1; }
lsof -ti tcp:8080 | xargs kill 2>/dev/null
clear
echo "== DashMOB no celular: aponte a câmera pro QR code ou digite  http://$IP:8080"
echo "== (se o Mac perguntar se o python pode receber conexões, clique em Permitir)"
echo
../backend/.venv/bin/python - "http://$IP:8080" <<'PY'
import sys, qrcode
qr = qrcode.QRCode(border=1); qr.add_data(sys.argv[1]); qr.make()
qr.print_ascii(invert=True)
PY
echo
echo "== no Chrome do celular dá pra usar 'Adicionar à tela de início' e virar ícone de app"
echo "== feche esta janela para encerrar"
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
