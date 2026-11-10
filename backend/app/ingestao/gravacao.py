"""Gravação dos registros no MongoDB com upsert (RN04).

operacao_diaria tem um documento por dia e cada relatório grava só os seus campos,
então a ordem de importação não importa.
"""
import re
from collections import defaultdict
from datetime import date, datetime, timezone

from pymongo import UpdateOne
from pymongo.database import Database

from app.services.periodo import chaves_do_dia


def _dt(d: date) -> datetime:
    return datetime(d.year, d.month, d.day)  # datas são gravadas como UTC à meia-noite


def nome_a_partir_do_atendimento(atendimento: str | None) -> str | None:
    """'B. SANTA MARIA SENTIDO ESTAÇÃO' -> 'B. Santa Maria'"""
    if not atendimento:
        return None
    base = re.split(r"\s+SENTIDO\s+", atendimento, maxsplit=1)[0].strip()
    return base.title() if base else None


def obter_ou_criar_linha(db: Database, codigo: str, atendimento: str | None = None):
    """Devolve o _id da linha com esse código, criando o cadastro se necessário."""
    doc = db.linhas.find_one({"codigo": codigo})
    nome_padrao = f"Linha {codigo}"
    if doc:
        alteracoes: dict = {}
        if atendimento and atendimento not in doc.get("atendimentos", []):
            alteracoes["$addToSet"] = {"atendimentos": atendimento}
        if atendimento and doc.get("nome", nome_padrao) == nome_padrao and nome_a_partir_do_atendimento(atendimento):
            alteracoes["$set"] = {"nome": nome_a_partir_do_atendimento(atendimento)}
        if alteracoes:
            db.linhas.update_one({"_id": doc["_id"]}, alteracoes)
        return doc["_id"]
    novo = {"codigo": codigo, "nome": nome_a_partir_do_atendimento(atendimento) or nome_padrao,
            "atendimentos": [atendimento] if atendimento else [], "ativa": True}
    return db.linhas.insert_one(novo).inserted_id


def _resultado(res) -> dict[str, int]:
    return {"inseridos": res.upserted_count, "atualizados": res.modified_count}


def _executar(colecao, operacoes) -> dict[str, int]:
    if not operacoes:
        return {"inseridos": 0, "atualizados": 0}
    return _resultado(colecao.bulk_write(operacoes, ordered=False))


def _upsert_dia(db: Database, registros: list[dict], campos_por_registro, fonte: str, importacao_id, agora) -> dict[str, int]:
    ops = []
    for r in registros:
        campos = campos_por_registro(r)
        campos.update({f"fontes.{fonte}": importacao_id, "atualizado_em": agora, **chaves_do_dia(r["data"])})
        ops.append(UpdateOne({"data": _dt(r["data"])}, {"$set": campos, "$setOnInsert": {"criado_em": agora}}, upsert=True))
    return _executar(db.operacao_diaria, ops)


def _gravar_resumo_geral(db, registros, importacao_id, agora):
    return _upsert_dia(db, registros, lambda r: {k: r[k] for k in (
        "dia_semana", "veiculos", "veiculos_max_faixa", "viagens_programadas", "viagens_realizadas",
        "km_produtiva", "km_improdutiva", "km_total")}, "resumo_geral", importacao_id, agora)


def _gravar_fcv(db, registros, importacao_id, agora):
    return _upsert_dia(db, registros, lambda r: {"turnos": r["turnos"], "viagens_programadas": r["viagens_programadas"],
                                                 "viagens_realizadas": r["viagens_realizadas"]}, "fcv", importacao_id, agora)


def _gravar_passageiros(db, registros, importacao_id, agora):
    return _upsert_dia(db, registros, lambda r: {"passageiros": {k: r[k] for k in ("catraca", "antecipados", "pagantes", "nao_pagantes", "total")}},
                       "passageiros", importacao_id, agora)


def _gravar_saldos(db, registros, importacao_id, agora):
    chaves = ("creditos_transferidos", "saldo_final", "vendas", "utilizacao", "credito_circulante")
    return _upsert_dia(db, registros, lambda r: {f"financeiro.{k}": r[k] for k in chaves if k in r}, "saldos", importacao_id, agora)


def _gravar_resumo_faixa(db, registros, importacao_id, agora):
    por_dia: dict[date, list] = defaultdict(list)
    for r in registros:
        por_dia[r["data"]].append({"faixa": r["faixa"], "veiculos": r["veiculos"], "viagens": r["viagens"]})
    dias = [{"data": d, "faixas": sorted(f, key=lambda x: x["faixa"] if x["faixa"] is not None else -1)} for d, f in por_dia.items()]
    return _upsert_dia(db, dias, lambda r: {"faixas_horarias": r["faixas"]}, "resumo_faixa_horaria", importacao_id, agora)


def _gravar_resumo_linha(db, registros, importacao_id, agora):
    ops = []
    for r in registros:
        linha_id = obter_ou_criar_linha(db, r["linha"])
        campos = {"km_total": r["km_total"], "viagens_realizadas": r["viagens_realizadas"],
                  "fontes.resumo_linha": importacao_id, "atualizado_em": agora, **chaves_do_dia(r["data"])}
        ops.append(UpdateOne({"data": _dt(r["data"]), "linha_id": linha_id},
                             {"$set": campos, "$setOnInsert": {"criado_em": agora}}, upsert=True))
    return _executar(db.operacao_linha_diaria, ops)


def _gravar_partidas_faixa(db, registros, importacao_id, agora):
    por_dia_linha: dict[tuple, list] = defaultdict(list)
    for r in registros:
        por_dia_linha[(r["data"], r["linha"])].append(
            {"faixa": r["faixa"], "veiculos": r["veiculos"], "viagens": r["viagens"], "partidas": r["partidas"]})
    ops = []
    for (d, linha), faixas in por_dia_linha.items():
        linha_id = obter_ou_criar_linha(db, linha)
        campos = {"faixas_horarias": sorted(faixas, key=lambda x: x["faixa"] if x["faixa"] is not None else -1),
                  "fontes.partidas_faixa_horaria": importacao_id, "atualizado_em": agora, **chaves_do_dia(d)}
        ops.append(UpdateOne({"data": _dt(d), "linha_id": linha_id}, {"$set": campos, "$setOnInsert": {"criado_em": agora}}, upsert=True))
    return _executar(db.operacao_linha_diaria, ops)


def _gravar_ocorrencias(db, registros, importacao_id, agora):
    ops = []
    for r in registros:
        linha_id = obter_ou_criar_linha(db, r["linha"], r.get("atendimento"))
        chave = {"tipo": r["tipo"], "data": _dt(r["data"]), "linha_id": linha_id, "sentido": r["sentido"],
                 "tabela": r["tabela"], "inicio_programado": r["inicio_programado"]}
        campos = {k: r[k] for k in ("atendimento", "prefixo", "atividade", "status_saida", "status_chegada",
                                    "inicio_realizado", "fim_programado", "fim_realizado")}
        campos.update({"importacao_id": importacao_id, "atualizado_em": agora, **chaves_do_dia(r["data"])})
        ops.append(UpdateOne(chave, {"$set": campos, "$setOnInsert": {"criado_em": agora}}, upsert=True))
    return _executar(db.ocorrencias_viagem, ops)


def _gravar_viagens(db, registros, importacao_id, agora):
    ops = []
    cache: dict[str, object] = {}
    for r in registros:
        linha_id = None
        if r["linha"]:
            linha_id = cache.get(r["linha"]) or cache.setdefault(r["linha"], obter_ou_criar_linha(db, r["linha"]))
        chave = {"data": _dt(r["data"]), "linha_id": linha_id, "prefixo": r["prefixo"], "inicio_realizado": r["inicio_realizado"]}
        campos = {k: r[k] for k in ("atividade", "sentido", "faixa", "fim_realizado", "km_produtiva", "km_improdutiva", "km_total")}
        campos.update({"importacao_id": importacao_id, "atualizado_em": agora, **chaves_do_dia(r["data"])})
        ops.append(UpdateOne(chave, {"$set": campos, "$setOnInsert": {"criado_em": agora}}, upsert=True))
    return _executar(db.viagens, ops)


GRAVADORES = {
    "resumo_geral": _gravar_resumo_geral,
    "fcv": _gravar_fcv,
    "resumo_faixa_horaria": _gravar_resumo_faixa,
    "passageiros": _gravar_passageiros,
    "saldos": _gravar_saldos,
    "resumo_linha": _gravar_resumo_linha,
    "partidas_faixa_horaria": _gravar_partidas_faixa,
    "viagens_nao_realizadas": _gravar_ocorrencias,
    "viagens_nao_iniciadas": _gravar_ocorrencias,
    "viagens_nao_terminadas": _gravar_ocorrencias,
    "viagens": _gravar_viagens,
}


def gravar_registros(db: Database, tipo: str, registros: list[dict], importacao_id) -> dict[str, int]:
    """Upsert dos registros aceitos de um relatório. Devolve contagem de inseridos e atualizados."""
    if not registros:
        return {"inseridos": 0, "atualizados": 0}
    return GRAVADORES[tipo](db, registros, importacao_id, datetime.now(timezone.utc))
