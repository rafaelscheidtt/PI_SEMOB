"""RN01 e RN07: chave de período e validação de intervalo."""
from datetime import date

import pytest

from app.services.periodo import chave_periodo, chaves_do_dia, validar_intervalo


def test_rn01_chave_diaria_e_a_propria_data():
    assert chave_periodo(date(2026, 9, 15), "dia") == "2026-09-15"


def test_rn01_semana_vai_de_segunda_a_domingo():
    segunda, domingo = date(2026, 9, 14), date(2026, 9, 20)
    assert chave_periodo(segunda, "semana") == chave_periodo(domingo, "semana") == "2026-W38"
    assert chave_periodo(date(2026, 9, 21), "semana") == "2026-W39"


def test_rn01_semana_iso_na_virada_do_ano():
    # 1/jan/2027 é sexta-feira e pertence à última semana ISO de 2026
    assert chave_periodo(date(2027, 1, 1), "semana") == "2026-W53"
    assert chave_periodo(date(2027, 1, 4), "semana") == "2027-W01"


def test_rn01_mes_calendario():
    assert chave_periodo(date(2026, 9, 1), "mes") == chave_periodo(date(2026, 9, 30), "mes") == "2026-09"
    assert chave_periodo(date(2026, 10, 1), "mes") == "2026-10"


def test_granularidade_invalida_e_rejeitada():
    with pytest.raises(ValueError):
        chave_periodo(date(2026, 9, 1), "ano")


def test_chaves_do_dia_gera_as_tres_granularidades():
    assert chaves_do_dia(date(2026, 9, 15)) == {
        "periodo_dia": "2026-09-15", "periodo_semana": "2026-W38", "periodo_mes": "2026-09",
    }


def test_rn07_intervalo_invertido_e_rejeitado():
    with pytest.raises(ValueError, match="anterior ou igual"):
        validar_intervalo(date(2026, 9, 20), date(2026, 9, 10))


def test_rn07_datas_iguais_sao_aceitas():
    validar_intervalo(date(2026, 9, 10), date(2026, 9, 10))
