from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.db import criar_indices, get_db
from app.routers import importacoes, indicadores


@asynccontextmanager
async def ciclo_de_vida(app: FastAPI):
    """Cria os índices ao subir a API (usa o banco dos testes quando há override)."""
    obter = app.dependency_overrides.get(get_db, get_db)
    try:
        criar_indices(obter())
    except Exception as exc:  # banco indisponível: a API sobe, mas avisa
        print(f"[aviso] não foi possível criar os índices: {exc}")
    yield


app = FastAPI(
    title="DashMOB API",
    description="API do painel de operação de transporte da SEMOB-SCS. "
                "Importa os relatórios do Smart Report e consolida os indicadores por dia, semana e mês.",
    version="0.2.0",
    lifespan=ciclo_de_vida,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",")],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(indicadores.router)
app.include_router(importacoes.router)


@app.get("/health", tags=["infra"])
def health() -> dict[str, str]:
    return {"status": "ok"}

