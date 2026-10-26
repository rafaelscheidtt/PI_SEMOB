from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pymongo.database import Database

from app.db import get_db
from app.repositories.operacao import listar_linhas, listar_ocorrencias, resumo_por_linha
from app.schemas import DetalhesOperacao, Linha, Ocorrencia, RespostaIndicadores, ResumoLinha
from app.services.indicadores import detalhar_operacao, obter_indicadores
from app.services.periodo import validar_intervalo

router = APIRouter(tags=["indicadores"])


@router.get("/indicadores", response_model=RespostaIndicadores)
def indicadores(
    inicio: date,
    fim: date,
    granularidade: str = Query("dia", pattern="^(dia|semana|mes)$"),
    linha: str | None = None,
    comparar: bool = False,
    db: Database = Depends(get_db),
):
    try:
        return obter_indicadores(db, inicio, fim, granularidade, linha, comparar)
    except ValueError as exc:  # RN07
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/indicadores/linhas", response_model=list[ResumoLinha])
def indicadores_por_linha(inicio: date, fim: date, db: Database = Depends(get_db)):
    try:
        validar_intervalo(inicio, fim)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return resumo_por_linha(db, inicio, fim)


@router.get("/indicadores/detalhes", response_model=DetalhesOperacao)
def detalhes_da_operacao(inicio: date, fim: date, linha: str | None = None, db: Database = Depends(get_db)):
    """Cumprimento por turno (só do sistema) e viagens por faixa horária (sistema ou linha)."""
    try:
        return detalhar_operacao(db, inicio, fim, linha)
    except ValueError as exc:  # RN07
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/ocorrencias", response_model=list[Ocorrencia])
def ocorrencias(
    inicio: date,
    fim: date,
    linha: str | None = None,
    tipo: str | None = Query(None, pattern="^(nao_realizada|nao_iniciada|nao_terminada)$"),
    db: Database = Depends(get_db),
):
    try:
        validar_intervalo(inicio, fim)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return listar_ocorrencias(db, inicio, fim, linha, tipo)


@router.get("/linhas", response_model=list[Linha])
def linhas(db: Database = Depends(get_db)):
    return listar_linhas(db)
