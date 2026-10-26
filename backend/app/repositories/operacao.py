"""Consultas de agregação nas coleções de operação."""
from datetime import date, datetime

from pymongo.database import Database

from app.services.periodo import GRANULARIDADES


def _dt(d: date) -> datetime:
    return datetime(d.year, d.month, d.day)  # datas são gravadas como UTC à meia-noite


def _filtro_datas(inicio: date, fim: date) -> dict:
    return {"data": {"$gte": _dt(inicio), "$lte": _dt(fim)}}


def _validar(granularidade: str) -> None:
    if granularidade not in GRANULARIDADES:
        raise ValueError(f"granularidade inválida: {granularidade!r}")


def _linha_id(db: Database, codigo: str):
    linha = db.linhas.find_one({"codigo": codigo})
    return linha["_id"] if linha else None


def agregar_sistema(db: Database, inicio: date, fim: date, granularidade: str) -> list[dict]:
    """Série do sistema inteiro a partir de operacao_diaria."""
    _validar(granularidade)
    pipeline = [
        {"$match": _filtro_datas(inicio, fim)},
        {"$group": {
            "_id": f"$periodo_{granularidade}",
            "km_total": {"$sum": "$km_total"},
            "km_produtiva": {"$sum": "$km_produtiva"},
            "km_improdutiva": {"$sum": "$km_improdutiva"},
            "viagens_programadas": {"$sum": "$viagens_programadas"},
            "viagens_realizadas": {"$sum": "$viagens_realizadas"},
            "passageiros_pagantes": {"$sum": "$passageiros.pagantes"},
            "passageiros_nao_pagantes": {"$sum": "$passageiros.nao_pagantes"},
            "dias_com_dados": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}},
    ]
    # média por viagem só com os dias que têm bilhetagem
    com_passageiros = {d["_id"]: d for d in db.operacao_diaria.aggregate([
        {"$match": {**_filtro_datas(inicio, fim), "passageiros.total": {"$exists": True}}},
        {"$group": {"_id": f"$periodo_{granularidade}", "n": {"$sum": 1},
                    "viagens": {"$sum": "$viagens_realizadas"}}},
    ])}
    saida = []
    for d in db.operacao_diaria.aggregate(pipeline):
        cp = com_passageiros.get(d["_id"], {})
        saida.append({"periodo": d["_id"], "dias_com_passageiros": cp.get("n", 0),
                      "viagens_com_passageiros": cp.get("viagens", 0),
                      **{k: v for k, v in d.items() if k != "_id"}})
    return saida


def agregar_linha(db: Database, inicio: date, fim: date, granularidade: str, linha_codigo: str) -> list[dict]:
    """Série de uma linha a partir de operacao_linha_diaria (sem passageiros: a bilhetagem não é por linha)."""
    _validar(granularidade)
    linha_id = _linha_id(db, linha_codigo)
    if linha_id is None:
        return []
    pipeline = [
        {"$match": {**_filtro_datas(inicio, fim), "linha_id": linha_id}},
        {"$group": {
            "_id": f"$periodo_{granularidade}",
            "km_total": {"$sum": "$km_total"},
            "viagens_realizadas": {"$sum": "$viagens_realizadas"},
            "dias_com_dados": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}},
    ]
    return [{"periodo": d["_id"], **{k: v for k, v in d.items() if k != "_id"}} for d in db.operacao_linha_diaria.aggregate(pipeline)]


def resumo_por_linha(db: Database, inicio: date, fim: date) -> list[dict]:
    """Totais de km, viagens e ocorrências de cada linha no intervalo."""
    totais = {d["_id"]: d for d in db.operacao_linha_diaria.aggregate([
        {"$match": _filtro_datas(inicio, fim)},
        {"$group": {"_id": "$linha_id", "km_total": {"$sum": "$km_total"},
                    "viagens_realizadas": {"$sum": "$viagens_realizadas"}, "dias_com_dados": {"$sum": 1}}},
    ])}
    ocorrencias: dict = {}
    for d in db.ocorrencias_viagem.aggregate([
        {"$match": _filtro_datas(inicio, fim)},
        {"$group": {"_id": {"linha_id": "$linha_id", "tipo": "$tipo"}, "n": {"$sum": 1}}},
    ]):
        ocorrencias.setdefault(d["_id"]["linha_id"], {})[d["_id"]["tipo"]] = d["n"]

    saida = []
    for linha in db.linhas.find({"ativa": True}).sort("codigo"):
        t = totais.get(linha["_id"])
        if not t:
            continue
        oc = ocorrencias.get(linha["_id"], {})
        saida.append({
            "codigo": linha["codigo"], "nome": linha.get("nome", linha["codigo"]),
            "km_total": round(t["km_total"], 2), "viagens_realizadas": t["viagens_realizadas"],
            "dias_com_dados": t["dias_com_dados"],
            "nao_realizadas": oc.get("nao_realizada", 0),
            "nao_iniciadas": oc.get("nao_iniciada", 0),
            "nao_terminadas": oc.get("nao_terminada", 0),
        })
    return saida


TURNOS = ("manha", "tarde", "noite")


def fcv_por_turno(db: Database, inicio: date, fim: date) -> list[dict]:
    """Viagens programadas e realizadas por turno (manhã, tarde e noite) no intervalo.

    O relatório de FCV só existe para o sistema inteiro, por isso não há versão por linha.
    """
    soma = {t: {"programadas": 0, "realizadas": 0} for t in TURNOS}
    for d in db.operacao_diaria.find({**_filtro_datas(inicio, fim), "turnos": {"$exists": True}}):
        for t in TURNOS:
            v = (d.get("turnos") or {}).get(t) or {}
            soma[t]["programadas"] += v.get("programadas") or 0
            soma[t]["realizadas"] += v.get("realizadas") or 0
    return [{"turno": t, **soma[t]} for t in TURNOS if soma[t]["programadas"] or soma[t]["realizadas"]]


def viagens_por_faixa_horaria(db: Database, inicio: date, fim: date, linha_codigo: str | None = None) -> list[dict]:
    """Soma das viagens por hora de início no intervalo, do sistema ou de uma linha."""
    if linha_codigo:
        linha_id = _linha_id(db, linha_codigo)
        if linha_id is None:
            return []
        docs = db.operacao_linha_diaria.find({**_filtro_datas(inicio, fim), "linha_id": linha_id,
                                              "faixas_horarias": {"$exists": True}})
    else:
        docs = db.operacao_diaria.find({**_filtro_datas(inicio, fim), "faixas_horarias": {"$exists": True}})
    acumulado: dict[int, dict] = {}
    for d in docs:
        for f in d.get("faixas_horarias") or []:
            faixa = f.get("faixa")
            if faixa is None:
                continue
            item = acumulado.setdefault(faixa, {"faixa": faixa, "viagens": 0, "veiculos": 0})
            item["viagens"] += f.get("viagens") or 0
            item["veiculos"] = max(item["veiculos"], f.get("veiculos") or 0)
    return [acumulado[k] for k in sorted(acumulado)]


def listar_ocorrencias(db: Database, inicio: date, fim: date, linha_codigo: str | None = None, tipo: str | None = None) -> list[dict]:
    filtro = _filtro_datas(inicio, fim)
    if linha_codigo:
        linha_id = _linha_id(db, linha_codigo)
        if linha_id is None:
            return []
        filtro["linha_id"] = linha_id
    if tipo:
        filtro["tipo"] = tipo
    nomes = {l["_id"]: l["codigo"] for l in db.linhas.find({}, {"codigo": 1})}
    saida = []
    for d in db.ocorrencias_viagem.find(filtro).sort([("data", 1), ("inicio_programado", 1)]):
        saida.append({
            "tipo": d["tipo"], "data": d["data"].date(), "linha": nomes.get(d["linha_id"]),
            "atendimento": d.get("atendimento"), "prefixo": d.get("prefixo"), "sentido": d.get("sentido"),
            "tabela": d.get("tabela"), "inicio_programado": d.get("inicio_programado"),
            "inicio_realizado": d.get("inicio_realizado"), "fim_programado": d.get("fim_programado"),
            "fim_realizado": d.get("fim_realizado"),
        })
    return saida


def listar_linhas(db: Database) -> list[dict]:
    return [{"codigo": l["codigo"], "nome": l.get("nome", l["codigo"]), "atendimentos": l.get("atendimentos", [])}
            for l in db.linhas.find({"ativa": True}).sort("codigo")]
