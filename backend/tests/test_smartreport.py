"""US01: leitura dos relatórios HTML do Smart Report."""
from datetime import date, datetime

import pytest

from app.ingestao import smartreport as sr
from tests.conftest import ler


def test_converte_numeros_no_formato_brasileiro():
    assert sr.numero("6.889,4") == 6889.4
    assert sr.numero("5.168") == 5168
    assert sr.numero("20.434.667,35") == 20434667.35
    assert sr.numero("") is None and sr.numero("-") is None
    assert sr.faixa_horaria("4hs") == 4 and sr.faixa_horaria("23hs") == 23


def test_identifica_o_tipo_pelo_titulo():
    assert sr.identificar_tipo("Mensal - Resumo Geral") == "resumo_geral"
    assert sr.identificar_tipo("Quinzenal - Fator de Cumprimento de Viagem") == "fcv"
    assert sr.identificar_tipo("Mensal - Viagens") == "viagens"
    assert sr.identificar_tipo("Mensal - Viagens não Realizadas") == "viagens_nao_realizadas"
    assert sr.identificar_tipo("São Caetano do Sul - Passageiros do Sistema") == "passageiros"
    assert sr.identificar_tipo("Relatório de frota") is None


def test_us01_resumo_geral_le_um_registro_por_dia(resumo_geral):
    r = sr.ler_relatorio(resumo_geral)
    assert r.tipo == "resumo_geral" and r.periodicidade == "mensal"
    assert r.gerado_em == "15/09/2026 08:00"
    regs = sr.normalizar(r)
    assert len(regs) == 7  # a linha "Total Geral" não vira registro
    assert regs[0]["data"] == date(2026, 9, 7)
    assert regs[0]["viagens_programadas"] == 500 and regs[0]["viagens_realizadas"] == 499
    assert regs[0]["km_total"] == pytest.approx(regs[0]["km_produtiva"] + regs[0]["km_improdutiva"], abs=0.11)


def test_us01_passageiros_combina_mes_e_dia_e_soma_pagantes():
    regs = sr.normalizar(sr.ler_relatorio(ler("Passageiros_Mensal.html")))
    assert len(regs) == 7  # a linha "Total Mês" é ignorada
    assert regs[0]["data"] == date(2026, 9, 7)
    assert regs[0]["pagantes"] == regs[0]["catraca"] + regs[0]["antecipados"]  # RN02
    assert regs[0]["total"] == regs[0]["pagantes"] + regs[0]["nao_pagantes"]


def test_us01_saldos_junta_as_duas_tabelas_por_dia():
    regs = sr.normalizar(sr.ler_relatorio(ler("Saldos_Mensal.html")))
    assert len(regs) == 7
    assert set(regs[0]) >= {"creditos_transferidos", "saldo_final", "vendas", "utilizacao", "credito_circulante"}


def test_us01_ocorrencias_tem_horarios_e_nao_guardam_o_motorista():
    regs = sr.normalizar(sr.ler_relatorio(ler("Mensal_Viag_NTerm_202609.html")))
    assert regs[0]["tipo"] == "nao_terminada"
    assert isinstance(regs[0]["inicio_programado"], datetime)
    assert regs[0]["fim_realizado"] is None
    assert "motorista" not in regs[0]


def test_us01_partidas_por_faixa_viram_lista():
    regs = sr.normalizar(sr.ler_relatorio(ler("Mensal_FxHr_202609.html")))
    assert regs[0]["linha"] == "01" and regs[0]["faixa"] == 6
    assert len(regs[0]["partidas"]) == regs[0]["viagens"]


def test_arquivo_desconhecido_e_recusado():
    with pytest.raises(ValueError):
        sr.ler_relatorio(b"<html><head><title>Planilha</title></head><body><table class='data'><th>a</th></table></body></html>")
