"""Indicadores por período.

RN02 total = pagantes + não pagantes (pagantes = catraca + antecipados)
RN03 média por viagem = total / viagens realizadas
RN06 sem dados -> campos nulos, nunca zero
RN08 FCV = realizadas / programadas
"""
from datetime import date, timedelta

from pymongo.database import Database

from app.repositories.operacao import agregar_linha, agregar_sistema, fcv_por_turno, viagens_por_faixa_horaria
from app.services.periodo import validar_intervalo


def _fcv(realizadas, programadas):
    return round(realizadas / programadas * 100, 2) if programadas else None


def _ponto(doc: dict) -> dict:
    viagens = doc.get("viagens_realizadas") or 0
    com_passageiros = doc.get("dias_com_passageiros", 0) > 0
    pagantes = doc.get("passageiros_pagantes") if com_passageiros else None
    nao_pagantes = doc.get("passageiros_nao_pagantes") if com_passageiros else None
    total = (pagantes or 0) + (nao_pagantes or 0) if com_passageiros else None  # RN02
    programadas = doc.get("viagens_programadas")
    return {
        "periodo": doc["periodo"],
        "km_total": round(doc.get("km_total") or 0, 2),
        "km_produtiva": round(doc["km_produtiva"], 2) if doc.get("km_produtiva") is not None else None,
        "viagens_programadas": programadas or None,
        "viagens_realizadas": viagens,
        "fcv": _fcv(viagens, programadas),  # RN08
        "passageiros_pagantes": pagantes,
        "passageiros_nao_pagantes": nao_pagantes,
        "passageiros_total": total,
        "media_passageiros_por_viagem": _media(total, doc.get("viagens_com_passageiros", viagens)),  # RN03
        "dias_com_dados": doc.get("dias_com_dados", 0),
        "dias_com_passageiros": doc.get("dias_com_passageiros", 0),
        "_viagens_com_passageiros": doc.get("viagens_com_passageiros", 0),
    }


def _media(total, viagens):
    return round(total / viagens, 2) if total is not None and viagens else None


def _totais(serie: list[dict]) -> dict:
    km = round(sum(p["km_total"] for p in serie), 2)
    km_prod = [p["km_produtiva"] for p in serie if p["km_produtiva"] is not None]
    viagens = sum(p["viagens_realizadas"] for p in serie)
    programadas = sum(p["viagens_programadas"] or 0 for p in serie) or None
    com_pass = [p for p in serie if p["passageiros_total"] is not None]
    pagantes = sum(p["passageiros_pagantes"] for p in com_pass) if com_pass else None
    nao_pagantes = sum(p["passageiros_nao_pagantes"] for p in com_pass) if com_pass else None
    total = pagantes + nao_pagantes if com_pass else None
    return {
        "km_total": km,
        "km_produtiva": round(sum(km_prod), 2) if km_prod else None,
        "viagens_programadas": programadas,
        "viagens_realizadas": viagens,
        "fcv": _fcv(viagens, programadas),
        "passageiros_pagantes": pagantes,
        "passageiros_nao_pagantes": nao_pagantes,
        "passageiros_total": total,
        "media_passageiros_por_viagem": _media(total, sum(p["_viagens_com_passageiros"] for p in com_pass)),
        "dias_com_dados": sum(p["dias_com_dados"] for p in serie),
        "dias_com_passageiros": sum(p["dias_com_passageiros"] for p in serie),
    }


def _serie(db: Database, inicio: date, fim: date, granularidade: str, linha: str | None) -> list[dict]:
    docs = agregar_linha(db, inicio, fim, granularidade, linha) if linha else agregar_sistema(db, inicio, fim, granularidade)
    return [_ponto(d) for d in docs]


def periodo_anterior(inicio: date, fim: date) -> tuple[date, date]:
    """Intervalo imediatamente anterior, com a mesma duração (mês cheio vira o mês anterior)."""
    if inicio.day == 1 and (fim + timedelta(days=1)).day == 1:
        fim_ant = inicio - timedelta(days=1)
        return fim_ant.replace(day=1), fim_ant
    dias = (fim - inicio).days + 1
    return inicio - timedelta(days=dias), inicio - timedelta(days=1)


def obter_indicadores(db: Database, inicio: date, fim: date, granularidade: str, linha: str | None = None,
                      comparar: bool = False) -> dict:
    validar_intervalo(inicio, fim)  # RN07
    serie = _serie(db, inicio, fim, granularidade, linha)
    publica = [{k: v for k, v in p.items() if not k.startswith("_")} for p in serie]
    resposta = {"granularidade": granularidade, "inicio": inicio, "fim": fim, "linha": linha,
                "sem_dados": not serie, "serie": publica, "totais": _totais(serie) if serie else None, "anterior": None}
    if comparar and serie:
        ini_ant, fim_ant = periodo_anterior(inicio, fim)
        serie_ant = _serie(db, ini_ant, fim_ant, granularidade, linha)
        if serie_ant:
            resposta["anterior"] = {"inicio": ini_ant, "fim": fim_ant, "totais": _totais(serie_ant)}
    return resposta


def detalhar_operacao(db: Database, inicio: date, fim: date, linha: str | None = None) -> dict:
    """Cumprimento por turno e viagens por faixa horária, para os painéis de detalhe."""
    validar_intervalo(inicio, fim)  # RN07
    turnos = [] if linha else [{**t, "fcv": _fcv(t["realizadas"], t["programadas"])} for t in fcv_por_turno(db, inicio, fim)]
    faixas = viagens_por_faixa_horaria(db, inicio, fim, linha)
    pico = max(faixas, key=lambda f: f["viagens"]) if faixas else None
    return {"linha": linha, "turnos": turnos, "faixas_horarias": faixas,
            "pico": None if pico is None else {"faixa": pico["faixa"], "viagens": pico["viagens"]}}
