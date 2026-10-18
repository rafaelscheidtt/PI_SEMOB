"""Conexão com o MongoDB e criação dos índices."""
from functools import lru_cache

from pymongo import ASCENDING, MongoClient
from pymongo.database import Database

from app.config import settings


@lru_cache
def _client() -> MongoClient:
    return MongoClient(settings.mongodb_url, serverSelectionTimeoutMS=3000)


def get_db() -> Database:
    return _client()[settings.mongodb_db]


def criar_indices(db: Database) -> None:
    """Índices do modelo lógico (seção 5 da documentação)."""
    db.operacao_diaria.create_index([("data", ASCENDING)], unique=True)
    db.operacao_linha_diaria.create_index([("data", ASCENDING), ("linha_id", ASCENDING)], unique=True)
    db.operacao_linha_diaria.create_index([("linha_id", ASCENDING), ("data", ASCENDING)])
    db.linhas.create_index([("codigo", ASCENDING)], unique=True)
    db.ocorrencias_viagem.create_index(
        [("tipo", ASCENDING), ("data", ASCENDING), ("linha_id", ASCENDING), ("sentido", ASCENDING),
         ("tabela", ASCENDING), ("inicio_programado", ASCENDING)], unique=True)
    db.ocorrencias_viagem.create_index([("data", ASCENDING), ("linha_id", ASCENDING)])
    db.viagens.create_index([("data", ASCENDING), ("linha_id", ASCENDING), ("prefixo", ASCENDING), ("inicio_realizado", ASCENDING)], unique=True)
    db.importacoes.create_index([("importado_em", ASCENDING)])
