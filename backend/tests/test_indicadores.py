"""US02 a US05: agregação por período e regras RN02, RN03, RN06, RN07 e RN08."""
from datetime import date

import pytest

from app.ingestao.servico import importar_pacote
from app.services.indicadores import detalhar_operacao, obter_indicadores, periodo_anterior


@pytest.fixture
def db_carregado(db, pacote):
    importar_pacote(db, pacote)
    return db


def test_us02_us03_totais_do_sistema(db_carregado):
    r = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes")
    assert r["sem_dados"] is False
    t = r["totais"]
    assert t["km_total"] == pytest.approx(sum(p["km_total"] for p in r["serie"]))
    assert t["viagens_programadas"] >= t["viagens_realizadas"] > 0
    assert 0 < t["fcv"] <= 100  # RN08
    assert t["dias_com_dados"] == 7


def test_us04_rn02_rn03_passageiros(db_carregado):
    t = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes")["totais"]
    assert t["passageiros_total"] == t["passageiros_pagantes"] + t["passageiros_nao_pagantes"]  # RN02
    assert t["media_passageiros_por_viagem"] == pytest.approx(t["passageiros_total"] / t["viagens_realizadas"], abs=0.01)  # RN03


def test_us05_granularidade_dia_semana_mes(db_carregado):
    dia = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "dia")
    sem = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "semana")
    mes = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes")
    assert [p["periodo"] for p in dia["serie"]][:2] == ["2026-09-07", "2026-09-08"]
    assert [p["periodo"] for p in sem["serie"]] == ["2026-W37"]
    assert [p["periodo"] for p in mes["serie"]] == ["2026-09"]
    assert dia["totais"]["km_total"] == pytest.approx(sem["totais"]["km_total"])
    assert sem["totais"]["km_total"] == pytest.approx(mes["totais"]["km_total"])


def test_us05_filtro_por_linha_usa_resumo_por_linha_sem_passageiros(db_carregado):
    r = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes", linha="02")
    assert r["linha"] == "02" and r["sem_dados"] is False
    t = r["totais"]
    assert t["km_total"] > 0 and t["viagens_realizadas"] > 0
    assert t["passageiros_total"] is None and t["media_passageiros_por_viagem"] is None  # bilhetagem não é por linha
    assert t["km_total"] < obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes")["totais"]["km_total"]


def test_us05_linha_inexistente_e_sem_dados(db_carregado):
    r = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes", linha="99")
    assert r["sem_dados"] is True and r["totais"] is None


def test_rn06_periodo_sem_dados_nao_e_zero(db_carregado):
    r = obter_indicadores(db_carregado, date(2026, 10, 1), date(2026, 10, 31), "mes")
    assert r["sem_dados"] is True and r["serie"] == [] and r["totais"] is None


def test_rn06_dias_sem_bilhetagem_deixam_passageiros_nulos(db, pacote):
    por_nome = dict(pacote)
    importar_pacote(db, [("Mensal_202609.html", por_nome["Mensal_202609.html"])])
    t = obter_indicadores(db, date(2026, 9, 7), date(2026, 9, 13), "mes")["totais"]
    assert t["km_total"] > 0 and t["passageiros_total"] is None


def test_rn07_intervalo_invertido(db_carregado):
    with pytest.raises(ValueError):
        obter_indicadores(db_carregado, date(2026, 9, 13), date(2026, 9, 7), "dia")


def test_periodo_anterior_mes_cheio_e_intervalo_livre():
    assert periodo_anterior(date(2026, 8, 1), date(2026, 8, 31)) == (date(2026, 7, 1), date(2026, 7, 31))
    assert periodo_anterior(date(2026, 9, 7), date(2026, 9, 13)) == (date(2026, 8, 31), date(2026, 9, 6))


def test_comparativo_com_periodo_anterior(db_carregado):
    r = obter_indicadores(db_carregado, date(2026, 9, 10), date(2026, 9, 13), "dia", comparar=True)
    assert r["anterior"]["inicio"] == date(2026, 9, 6) and r["anterior"]["fim"] == date(2026, 9, 9)
    assert r["anterior"]["totais"]["dias_com_dados"] == 3  # 06/09 não tem dados


def test_rn03_media_por_viagem_usa_so_dias_com_bilhetagem(db, pacote):
    """Com bilhetagem só em parte do período, a média não pode dividir pelas viagens dos dias sem passageiros."""
    por_nome = dict(pacote)
    importar_pacote(db, [("Mensal_202609.html", por_nome["Mensal_202609.html"])])
    importar_pacote(db, [("Passageiros_Mensal.html", por_nome["Passageiros_Mensal.html"])])
    db.operacao_diaria.update_one({"periodo_dia": "2026-09-13"}, {"$unset": {"passageiros": ""}})
    t = obter_indicadores(db, date(2026, 9, 7), date(2026, 9, 13), "mes")["totais"]
    assert t["dias_com_dados"] == 7 and t["dias_com_passageiros"] == 6
    viagens_com_bilhetagem = sum(
        d["viagens_realizadas"] for d in db.operacao_diaria.find({"passageiros.total": {"$exists": True}}))
    assert t["media_passageiros_por_viagem"] == pytest.approx(t["passageiros_total"] / viagens_com_bilhetagem, abs=0.01)


def test_us03_cumprimento_por_turno(db_carregado):
    r = detalhar_operacao(db_carregado, date(2026, 9, 7), date(2026, 9, 13))
    assert [t["turno"] for t in r["turnos"]] == ["manha", "tarde", "noite"]
    t = obter_indicadores(db_carregado, date(2026, 9, 7), date(2026, 9, 13), "mes")["totais"]
    assert sum(x["programadas"] for x in r["turnos"]) == t["viagens_programadas"]
    assert sum(x["realizadas"] for x in r["turnos"]) == t["viagens_realizadas"]
    for x in r["turnos"]:
        assert x["fcv"] == pytest.approx(x["realizadas"] / x["programadas"] * 100, abs=0.01)  # RN08


def test_us03_viagens_por_faixa_horaria_do_sistema_e_da_linha(db_carregado):
    sistema = detalhar_operacao(db_carregado, date(2026, 9, 7), date(2026, 9, 13))
    faixas = sistema["faixas_horarias"]
    assert faixas and [f["faixa"] for f in faixas] == sorted(f["faixa"] for f in faixas)
    assert sistema["pico"]["viagens"] == max(f["viagens"] for f in faixas)
    linha = detalhar_operacao(db_carregado, date(2026, 9, 7), date(2026, 9, 13), linha="02")
    assert linha["turnos"] == []  # o FCV por turno só existe para o sistema inteiro
    assert linha["faixas_horarias"] and sum(f["viagens"] for f in linha["faixas_horarias"]) < sum(f["viagens"] for f in faixas)


def test_detalhes_sem_dados_e_intervalo_invertido(db_carregado):
    r = detalhar_operacao(db_carregado, date(2026, 10, 1), date(2026, 10, 31))
    assert r["turnos"] == [] and r["faixas_horarias"] == [] and r["pico"] is None
    with pytest.raises(ValueError):
        detalhar_operacao(db_carregado, date(2026, 9, 13), date(2026, 9, 7))
