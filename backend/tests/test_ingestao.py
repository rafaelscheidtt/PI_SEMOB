"""US01: importação, validação (RN05) e reimportação (RN04)."""
from datetime import date

from app.ingestao.servico import importar, importar_pacote
from app.ingestao.validacao import validar_registros


def test_rn05_rejeita_valor_negativo_data_invalida_e_linha_ausente():
    registros = [
        {"data": date(2026, 9, 1), "linha": "01", "km_total": 10, "viagens_realizadas": 2},
        {"data": date(2026, 9, 2), "linha": "01", "km_total": -1, "viagens_realizadas": 2},
        {"data": None, "linha": "01", "km_total": 10, "viagens_realizadas": 2},
        {"data": date(2026, 9, 3), "linha": None, "km_total": 10, "viagens_realizadas": 2},
    ]
    aceitos, rejeitados = validar_registros("resumo_linha", registros)
    assert len(aceitos) == 1
    assert [r.numero for r in rejeitados] == [2, 3, 4]
    assert "km_total" in rejeitados[0].motivo
    assert "data" in rejeitados[1].motivo
    assert "linha" in rejeitados[2].motivo


def test_rn05_realizadas_acima_das_programadas_e_rejeitado():
    _, rejeitados = validar_registros("resumo_geral", [{"data": date(2026, 9, 1), "viagens_programadas": 10, "viagens_realizadas": 11}])
    assert len(rejeitados) == 1 and "programadas" in rejeitados[0].motivo


def test_us01_importa_resumo_geral_um_documento_por_dia(db, resumo_geral):
    r = importar(db, resumo_geral, "Mensal_202609.html")
    assert r["status"] == "concluida" and r["tipo_relatorio"] == "resumo_geral"
    assert r["importados"] == 7 and r["rejeitados"] == 0 and r["inseridos"] == 7
    assert db.operacao_diaria.count_documents({}) == 7
    doc = db.operacao_diaria.find_one({"periodo_dia": "2026-09-07"})
    assert doc["viagens_programadas"] == 500 and doc["periodo_semana"] == "2026-W37" and doc["periodo_mes"] == "2026-09"
    assert db.importacoes.count_documents({"status": "concluida"}) == 1


def test_us01_importacao_parcial_rejeita_so_as_invalidas(db, resumo_geral_com_erros):
    r = importar(db, resumo_geral_com_erros, "Mensal_202609.html")
    assert r["status"] == "parcial"
    assert r["importados"] == 6 and r["rejeitados"] == 2
    assert db.operacao_diaria.count_documents({}) == 6
    motivos = " ".join(e["motivo"] for e in r["erros"])
    assert "negativo" in motivos and "data" in motivos


def test_us01_arquivo_desconhecido_gera_importacao_com_falha(db):
    r = importar(db, b"<html><body><h1>Planilha de frota</h1></body></html>", "frota.html")
    assert r["status"] == "falha" and r["tipo_relatorio"] is None
    assert db.importacoes.find_one({"status": "falha"})["arquivo_origem"] == "frota.html"


def test_us01_pacote_completo_alimenta_todas_as_colecoes(db, pacote):
    r = importar_pacote(db, pacote)
    assert r["status"] == "concluida" and r["arquivos"] == 11
    assert r["periodo_inicio"] == date(2026, 9, 7) and r["periodo_fim"] == date(2026, 9, 13)
    assert db.operacao_diaria.count_documents({}) == 7
    assert db.operacao_linha_diaria.count_documents({}) == 21  # 7 dias x 3 linhas
    assert db.linhas.count_documents({}) == 3
    assert db.ocorrencias_viagem.count_documents({"tipo": "nao_realizada"}) == 5
    assert db.ocorrencias_viagem.count_documents({}) == 7
    assert db.viagens.count_documents({}) == 42
    dia = db.operacao_diaria.find_one({"periodo_dia": "2026-09-07"})
    assert dia["passageiros"]["pagantes"] == dia["passageiros"]["catraca"] + dia["passageiros"]["antecipados"]
    assert dia["financeiro"]["saldo_final"] > 0 and dia["turnos"]["manha"]["programadas"] > 0
    assert len(dia["faixas_horarias"]) == 20
    assert set(dia["fontes"]) == {"resumo_geral", "fcv", "resumo_faixa_horaria", "passageiros", "saldos"}
    linha_dia = db.operacao_linha_diaria.find_one({"periodo_dia": "2026-09-07"})
    assert linha_dia["km_total"] > 0 and len(linha_dia["faixas_horarias"]) == 3


def test_us01_zip_do_pacote_e_expandido(db, pacote):
    import io
    import zipfile

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        for nome, conteudo in pacote:
            z.writestr(f"Setembro_2026/Mensal/{nome}", conteudo)
        z.writestr("Setembro_2026/leia-me.txt", "ignorado")
    r = importar_pacote(db, [("Setembro_2026.zip", buf.getvalue())])
    assert r["arquivos"] == 11 and r["status"] == "concluida"


def test_rn04_reimportar_nao_duplica(db, pacote):
    importar_pacote(db, pacote)
    r2 = importar_pacote(db, pacote)
    assert db.operacao_diaria.count_documents({}) == 7
    assert db.operacao_linha_diaria.count_documents({}) == 21
    assert db.ocorrencias_viagem.count_documents({}) == 7
    assert r2["inseridos"] == 0
    assert db.importacoes.count_documents({}) == 22


def test_rn04_reimportar_atualiza_o_registro(db, resumo_geral):
    importar(db, resumo_geral, "a.html")
    alterado = resumo_geral.replace(b"<td align='right'>500</td>", b"<td align='right'>510</td>", 1)
    r = importar(db, alterado, "b.html")
    assert r["atualizados"] >= 1
    assert db.operacao_diaria.find_one({"periodo_dia": "2026-09-07"})["viagens_programadas"] == 510


def test_rn04_relatorios_de_tipos_diferentes_somam_campos_no_mesmo_dia(db, pacote):
    por_nome = dict(pacote)
    importar(db, por_nome["Passageiros_Mensal.html"], "Passageiros_Mensal.html")
    importar(db, por_nome["Mensal_202609.html"], "Mensal_202609.html")
    doc = db.operacao_diaria.find_one({"periodo_dia": "2026-09-07"})
    assert doc["passageiros"]["total"] > 0 and doc["km_total"] > 0
    assert db.operacao_diaria.count_documents({}) == 7
