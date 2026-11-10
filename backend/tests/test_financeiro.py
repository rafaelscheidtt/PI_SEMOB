"""US07: indicadores financeiros por período (vendas, utilização, crédito circulante e saldo)."""
from datetime import datetime

from app.ingestao.gravacao import chaves_do_dia
from app.services.financeiro import obter_financeiro


def _enviar(client, pacote):
    return client.post("/importacoes", files=[("arquivos", (nome, conteudo, "text/html")) for nome, conteudo in pacote])


def test_us07_financeiro_do_pacote_de_exemplo(client, pacote):
    _enviar(client, pacote)
    r = client.get("/indicadores/financeiro", params={"inicio": "2026-09-01", "fim": "2026-09-30", "granularidade": "mes"})
    assert r.status_code == 200, r.text
    corpo = r.json()
    assert corpo["sem_dados"] is False and corpo["inicio_bilhetagem"] == "2026-09-07"
    assert [p["periodo"] for p in corpo["serie"]] == ["2026-09"]
    t = corpo["totais"]
    assert t["vendas"] == 32448.0 and t["utilizacao"] == 34320.0
    assert t["credito_circulante"] == -1872.0  # RN12 vendas - utilização
    assert t["creditos_transferidos"] == 39000.0
    assert t["saldo_final"] == 961000.0  # saldo do último dia com relatório
    assert t["dias_com_dados"] == 7 and t["vendas_por_dia"] == round(32448 / 7, 2)


def test_us07_serie_diaria_e_semanal(client, pacote):
    _enviar(client, pacote)
    dia = client.get("/indicadores/financeiro", params={"inicio": "2026-09-07", "fim": "2026-09-08", "granularidade": "dia"}).json()
    assert [p["periodo"] for p in dia["serie"]] == ["2026-09-07", "2026-09-08"]
    assert dia["serie"][0]["vendas"] == 6487.0 and dia["serie"][0]["saldo_final"] == 993762.5
    semana = client.get("/indicadores/financeiro", params={"inicio": "2026-09-01", "fim": "2026-09-30", "granularidade": "semana"}).json()
    assert [p["periodo"] for p in semana["serie"]] == ["2026-W37"]
    assert semana["serie"][0]["dias_com_dados"] == 7


def test_us07_periodo_sem_bilhetagem_devolve_sem_dados(client, pacote):
    """RN06: antes da bilhetagem (Tarifa Zero) não existe dado financeiro, e a resposta não inventa zero."""
    _enviar(client, pacote)
    r = client.get("/indicadores/financeiro", params={"inicio": "2026-07-01", "fim": "2026-07-14"}).json()
    assert r["sem_dados"] is True and r["totais"] is None and r["serie"] == []
    assert r["inicio_bilhetagem"] == "2026-09-07"  # o app usa isso para explicar o período vazio


def test_us07_comparacao_com_o_periodo_anterior(db):
    for dia, vendas, util in [(1, 100.0, 80.0), (2, 100.0, 80.0), (3, 300.0, 100.0), (4, 300.0, 100.0)]:
        data = datetime(2026, 8, dia)
        db.operacao_diaria.insert_one({"data": data, **chaves_do_dia(data.date()),
                                       "financeiro": {"vendas": vendas, "utilizacao": util, "credito_circulante": vendas - util,
                                                      "creditos_transferidos": 10.0, "saldo_final": 1000.0 + dia}})
    r = obter_financeiro(db, datetime(2026, 8, 3).date(), datetime(2026, 8, 4).date(), "dia", comparar=True)
    assert r["totais"]["vendas"] == 600.0 and r["totais"]["saldo_final"] == 1004.0
    assert r["anterior"]["inicio"].isoformat() == "2026-08-01" and r["anterior"]["totais"]["vendas"] == 200.0
    sem_anterior = obter_financeiro(db, datetime(2026, 8, 1).date(), datetime(2026, 8, 2).date(), "dia", comparar=True)
    assert sem_anterior["anterior"] is None


def test_us07_intervalo_invertido_e_recusado(client):
    assert client.get("/indicadores/financeiro", params={"inicio": "2026-09-10", "fim": "2026-09-01"}).status_code == 400  # RN07
