"""Fixtures: banco em memória (mongomock) e o pacote de exemplo de dados/exemplo."""
import pathlib

import mongomock
import pytest
from fastapi.testclient import TestClient

from app.db import get_db
from app.main import app

EXEMPLOS = pathlib.Path(__file__).resolve().parents[2] / "dados" / "exemplo"
PACOTE = EXEMPLOS / "Setembro_2026" / "Mensal"


def ler(nome: str) -> bytes:
    return (PACOTE / nome).read_bytes()


@pytest.fixture
def db():
    return mongomock.MongoClient()["dashmob_test"]


@pytest.fixture
def client(db):
    app.dependency_overrides[get_db] = lambda: db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def resumo_geral() -> bytes:
    return ler("Mensal_202609.html")


@pytest.fixture
def resumo_geral_com_erros() -> bytes:
    return (EXEMPLOS / "com_erros" / "Mensal_202609.html").read_bytes()


@pytest.fixture
def pacote() -> list[tuple[str, bytes]]:
    """Todos os relatórios do pacote de exemplo, como (nome, conteúdo)."""
    return [(p.name, p.read_bytes()) for p in sorted(PACOTE.glob("*.html"))]
