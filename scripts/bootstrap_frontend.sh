#!/usr/bin/env bash
# Instala as dependências do app e roda a análise e os testes.
set -euo pipefail
cd "$(dirname "$0")/../frontend"

command -v flutter >/dev/null || { echo "Flutter não encontrado no PATH"; exit 1; }

if [ ! -d web ]; then
  echo "==> Gerando arquivos de plataforma (web, android, ios, macos)"
  tinha_teste_padrao=0; [ -f test/widget_test.dart ] && tinha_teste_padrao=1
  flutter create . --project-name dashmob --org br.gov.sp.saocaetano.semob --platforms=web,android,ios,macos
  # o teste de exemplo do flutter create referencia um app que não existe no projeto
  [ "$tinha_teste_padrao" = 0 ] && rm -f test/widget_test.dart
fi

echo "==> Dependências"
flutter pub get

echo "==> Análise estática"
flutter analyze || echo "(o analyze apontou avisos, mas dá pra rodar)"

echo "==> Testes"
flutter test --coverage
