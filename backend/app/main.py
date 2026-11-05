from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.auth import usuario_atual
from app.config import settings
from app.db import criar_indices, get_db
from app.repositories.usuarios import garantir_admin_inicial
from app.routers import importacoes, indicadores, usuarios


@asynccontextmanager
async def ciclo_de_vida(app: FastAPI):
    """Cria os índices ao subir a API (usa o banco dos testes quando há override)."""
    obter = app.dependency_overrides.get(get_db, get_db)
    try:
        db = obter()
        criar_indices(db)
        if settings.admin_inicial_email and settings.admin_inicial_senha:
            if garantir_admin_inicial(db, settings.admin_inicial_nome, settings.admin_inicial_email, settings.admin_inicial_senha):
                print(f"[info] administrador inicial criado: {settings.admin_inicial_email}")
    except Exception as exc:  # banco indisponível: a API sobe, mas avisa
        print(f"[aviso] não foi possível preparar o banco: {exc}")
    yield


app = FastAPI(
    title="DashMOB API",
    description="API do painel de operação de transporte da SEMOB-SCS. "
                "Importa os relatórios do Smart Report e consolida os indicadores por dia, semana e mês.",
    version="0.3.0",
    lifespan=ciclo_de_vida,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",")],
    allow_methods=["*"],
    allow_headers=["*"],
)

# todas as rotas de dados exigem login (US11); /login e /health ficam abertas
app.include_router(usuarios.router)
app.include_router(indicadores.router, dependencies=[Depends(usuario_atual)])
app.include_router(importacoes.router, dependencies=[Depends(usuario_atual)])


@app.get("/health", tags=["infra"])
def health() -> dict[str, str]:
    return {"status": "ok"}

