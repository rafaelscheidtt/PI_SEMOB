"""Validação dos registros lidos dos relatórios (RN05)."""
from datetime import date
from typing import Any

from pydantic import BaseModel

CAMPOS_NAO_NEGATIVOS = (
    "veiculos", "veiculos_max_faixa", "viagens_programadas", "viagens_realizadas",
    "km_produtiva", "km_improdutiva", "km_total", "viagens", "catraca", "antecipados",
    "pagantes", "nao_pagantes", "total", "creditos_transferidos", "saldo_final", "vendas", "utilizacao",
)
TIPOS_POR_LINHA = ("resumo_linha", "partidas_faixa_horaria", "viagens_nao_realizadas",
                   "viagens_nao_iniciadas", "viagens_nao_terminadas")


class LinhaRejeitada(BaseModel):
    numero: int
    motivo: str


def _motivos(tipo: str, r: dict[str, Any]) -> list[str]:
    motivos = []
    if not isinstance(r.get("data"), date):
        motivos.append("data: ausente ou inválida")
    if tipo in TIPOS_POR_LINHA and not r.get("linha"):
        motivos.append("linha: código ausente")
    for campo in CAMPOS_NAO_NEGATIVOS:
        v = r.get(campo)
        if isinstance(v, (int, float)) and v < 0:
            motivos.append(f"{campo}: valor não pode ser negativo")
    if tipo == "resumo_geral" and r.get("viagens_realizadas") is not None and r.get("viagens_programadas") is not None \
            and r["viagens_realizadas"] > r["viagens_programadas"]:
        motivos.append("viagens_realizadas: maior que as programadas")
    return motivos


def validar_registros(tipo: str, registros: list[dict[str, Any]]) -> tuple[list[dict], list[LinhaRejeitada]]:
    """Separa os registros em aceitos e rejeitados. A numeração começa em 1."""
    aceitos: list[dict] = []
    rejeitados: list[LinhaRejeitada] = []
    for i, r in enumerate(registros, start=1):
        motivos = _motivos(tipo, r)
        if motivos:
            rejeitados.append(LinhaRejeitada(numero=i, motivo="; ".join(motivos)))
        else:
            aceitos.append(r)
    return aceitos, rejeitados
