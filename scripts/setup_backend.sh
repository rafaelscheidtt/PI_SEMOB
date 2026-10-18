#!/usr/bin/env bash
# Prepara o ambiente do back-end e roda os testes.
#   ./scripts/setup_backend.sh          -> cria o venv, instala as dependências, roda o pytest
#   ./scripts/setup_backend.sh importar -> além disso, importa os relatórios de dados/semob (precisa do MongoDB no .env)
#   ./scripts/setup_backend.sh api      -> sobe a API em http://localhost:8000/docs
set -e
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ/backend"

if [ ! -d .venv ]; then
  echo "== criando o ambiente virtual"
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

echo "== instalando dependências"
pip install -q --upgrade pip
pip install -q -r requirements.txt

if [ ! -f .env ]; then
  cp .env.example .env
  echo "== .env criado a partir do .env.example (edite MONGODB_URL se for usar o Atlas)"
fi

case "${1:-testes}" in
  testes)
    echo "== rodando os testes"
    pytest --cov=app --cov-report=term-missing
    ;;
  importar)
    echo "== importando os relatórios de dados/semob"
    for pasta in "$RAIZ"/dados/semob/*/*/; do
      python -m app.cli "$pasta"
    done
    ;;
  api)
    echo "== API em http://localhost:8000/docs  (Ctrl+C para parar)"
    uvicorn app.main:app --reload
    ;;
  *)
    echo "uso: $0 [testes|importar|api]"; exit 2 ;;
esac
