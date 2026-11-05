"""Fixtures: banco em memória (mongomock) e o pacote de exemplo de dados/exemplo."""
import pathlib

import mongomock
import pytest
from fastapi.testclient import TestClient

from app.db import get_db
from app.main import app
from app.repositories import usuarios as repo_usuarios

EXEMPLOS = pathlib.Path(__file__).resolve().parents[2] / "dados" / "exemplo"
PACOTE = EXEMPLOS / "Setembro_2026" / "Mensal"


def ler(nome: str) -> bytes:
    return (PACOTE / nome).read_bytes()


@pytest.fixture
def db():
    return mongomock.MongoClient()["dashmob_test"]


ADMIN = {"nome": "Ana Admin", "email": "admin@semob.teste", "senha": "segredo1", "papel": "administrador"}


def token_de(client, email: str, senha: str) -> str:
    r = client.post("/login", json={"email": email, "senha": senha})
    assert r.status_code == 200, r.text
    return r.json()["token"]


@pytest.fixture
def client(db):
    """Cliente já logado como administrador (as rotas de dados exigem login, US11)."""
    app.dependency_overrides[get_db] = lambda: db
    repo_usuarios.criar(db, ADMIN["nome"], ADMIN["email"], ADMIN["senha"], ADMIN["papel"])
    with TestClient(app) as c:
        c.headers["Authorization"] = f"Bearer {token_de(c, ADMIN['email'], ADMIN['senha'])}"
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def anonimo(db):
    """Cliente sem login."""
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
