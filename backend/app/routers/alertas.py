from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pymongo.database import Database

from app.db import get_db
from app.schemas import RespostaAlertas
from app.services.alertas import gerar_alertas

router = APIRouter(tags=["alertas"])


@router.get("/alertas", response_model=RespostaAlertas)
def alertas(inicio: date, fim: date, linha: str | None = None, db: Database = Depends(get_db)):
    """Dias fora do padrão no período (US08): cumprimento baixo, desvio do histórico e excesso de ocorrências."""
    try:
        return gerar_alertas(db, inicio, fim, linha)
    except ValueError as exc:  # RN07
        raise HTTPException(status_code=400, detail=str(exc)) from exc
