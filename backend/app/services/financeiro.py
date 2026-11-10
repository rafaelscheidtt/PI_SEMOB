"""Indicadores financeiros por período (US07).

Os valores vêm dos relatórios de saldo de créditos e de venda x utilização do Smart Report
(em reais). A bilhetagem só começou em 15/07/2026, com o fim do Tarifa Zero para quem não
é cadastrado; antes disso não há dado financeiro, e o painel mostra "Sem dados" (RN06).

RN12 crédito circulante = vendas - utilização (vem pronto no relatório; aqui só é somado)
"""
from datetime import date

from pymongo.database import Database

from app.repositories.operacao import agregar_financeiro, primeiro_dia_com_financeiro
from app.services.indicadores import periodo_anterior
from app.services.periodo import validar_intervalo


def _ponto(doc: dict) -> dict:
    return {
        "periodo": doc["periodo"],
        "vendas": round(doc.get("vendas") or 0, 2),
        "utilizacao": round(doc.get("utilizacao") or 0, 2),
        "credito_circulante": round(doc.get("credito_circulante") or 0, 2),
        "creditos_transferidos": round(doc.get("creditos_transferidos") or 0, 2),
        "saldo_final": round(doc["saldo_final"], 2) if doc.get("saldo_final") is not None else None,
        "dias_com_dados": doc.get("dias_com_dados", 0),
    }


def _totais(serie: list[dict]) -> dict:
    vendas = round(sum(p["vendas"] for p in serie), 2)
    utilizacao = round(sum(p["utilizacao"] for p in serie), 2)
    com_saldo = [p["saldo_final"] for p in serie if p["saldo_final"] is not None]
    dias = sum(p["dias_com_dados"] for p in serie)
    return {
        "vendas": vendas,
        "utilizacao": utilizacao,
        "credito_circulante": round(sum(p["credito_circulante"] for p in serie), 2),
        "creditos_transferidos": round(sum(p["creditos_transferidos"] for p in serie), 2),
        "saldo_final": com_saldo[-1] if com_saldo else None,
        "vendas_por_dia": round(vendas / dias, 2) if dias else None,
        "utilizacao_por_dia": round(utilizacao / dias, 2) if dias else None,
        "dias_com_dados": dias,
    }


def obter_financeiro(db: Database, inicio: date, fim: date, granularidade: str, comparar: bool = False) -> dict:
    validar_intervalo(inicio, fim)  # RN07
    serie = [_ponto(d) for d in agregar_financeiro(db, inicio, fim, granularidade)]
    resposta = {
        "granularidade": granularidade, "inicio": inicio, "fim": fim,
        "sem_dados": not serie, "serie": serie, "totais": _totais(serie) if serie else None, "anterior": None,
        "inicio_bilhetagem": primeiro_dia_com_financeiro(db),
    }
    if comparar and serie:
        ini_ant, fim_ant = periodo_anterior(inicio, fim)
        serie_ant = [_ponto(d) for d in agregar_financeiro(db, ini_ant, fim_ant, granularidade)]
        if serie_ant:
            resposta["anterior"] = {"inicio": ini_ant, "fim": fim_ant, "totais": _totais(serie_ant)}
    return resposta
