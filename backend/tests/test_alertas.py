"""US08: alertas de desvio (RN09 cumprimento, RN10 padrão histórico, RN11 ocorrências)."""
from datetime import date, datetime, timedelta

from app.ingestao.gravacao import chaves_do_dia
from app.services.alertas import gerar_alertas


def _dia(db, d: date, km=1000.0, realizadas=100, programadas=100, passageiros=5000, linha_id=None):
    doc = {"data": datetime(d.year, d.month, d.day), **chaves_do_dia(d), "km_total": km,
           "viagens_realizadas": realizadas, "viagens_programadas": programadas}
    if linha_id is None:
        doc["passageiros"] = {"total": passageiros}
        db.operacao_diaria.insert_one(doc)
    else:
        db.operacao_linha_diaria.insert_one({**doc, "linha_id": linha_id})


def _historico(db, alvo: date, semanas=8, **kw):
    for s in range(1, semanas + 1):
        _dia(db, alvo - timedelta(weeks=s), **kw)


def test_rn09_cumprimento_baixo_vira_aviso_ou_critico(db):
    _dia(db, date(2026, 9, 7), realizadas=93)   # 93% -> aviso
    _dia(db, date(2026, 9, 8), realizadas=88)   # 88% -> crítico
    _dia(db, date(2026, 9, 9), realizadas=96)   # ok
    r = gerar_alertas(db, date(2026, 9, 7), date(2026, 9, 9))
    assert r["total"] == 2 and r["criticos"] == 1 and r["avisos"] == 1
    assert [(a["data"], a["severidade"]) for a in r["alertas"]] == [(date(2026, 9, 8), "critico"), (date(2026, 9, 7), "aviso")]
    assert r["alertas"][0]["mensagem"].startswith("Cumprimento de 88,0%")


def test_rn10_desvio_do_mesmo_dia_da_semana(db):
    alvo = date(2026, 9, 7)  # segunda
    _historico(db, alvo, km=1000.0, passageiros=5000)
    _dia(db, alvo, km=700.0, passageiros=3000)  # km 30% abaixo (aviso), passageiros 40% abaixo (crítico)
    r = gerar_alertas(db, alvo, alvo)
    por_indicador = {a["indicador"]: a for a in r["alertas"]}
    assert set(por_indicador) == {"km_total", "passageiros_total"}
    assert por_indicador["km_total"]["severidade"] == "aviso" and por_indicador["km_total"]["desvio"] == -30.0
    assert por_indicador["passageiros_total"]["severidade"] == "critico" and por_indicador["passageiros_total"]["esperado"] == 5000.0
    assert "segunda" in por_indicador["km_total"]["mensagem"]
    assert r["alertas"][0]["severidade"] == "critico"  # crítico vem antes no mesmo dia


def test_rn10_precisa_de_pelo_menos_tres_semanas_de_historico(db):
    alvo = date(2026, 9, 7)
    _historico(db, alvo, semanas=2, km=1000.0)
    _dia(db, alvo, km=500.0)
    assert gerar_alertas(db, alvo, alvo)["total"] == 0


def test_rn11_excesso_de_ocorrencias_no_dia(db):
    inicio, fim = date(2026, 9, 1), date(2026, 9, 10)
    for i in range(10):
        _dia(db, inicio + timedelta(days=i))
    for _ in range(9):  # 9 no dia 5 e 1 por dia nos outros: média 1,8/dia
        db.ocorrencias_viagem.insert_one({"data": datetime(2026, 9, 5), "tipo": "nao_realizada"})
    for i in range(9):
        db.ocorrencias_viagem.insert_one({"data": datetime(2026, 9, 1 + i if i < 4 else 2 + i), "tipo": "nao_iniciada"})
    r = gerar_alertas(db, inicio, fim)
    assert r["total"] == 1
    a = r["alertas"][0]
    assert a["tipo"] == "ocorrencias" and a["data"] == date(2026, 9, 5) and a["valor"] == 9 and a["severidade"] == "critico"


def test_us08_filtro_por_linha_usa_a_operacao_da_linha(db):
    linha = db.linhas.insert_one({"codigo": "02", "nome": "Circular", "ativa": True}).inserted_id
    alvo = date(2026, 9, 7)
    _historico(db, alvo, km=500.0, linha_id=linha)
    _dia(db, alvo, km=200.0, linha_id=linha)
    _dia(db, alvo, km=5000.0)  # o sistema está normal
    r = gerar_alertas(db, alvo, alvo, linha="02")
    assert r["linha"] == "02" and r["total"] == 1 and r["alertas"][0]["indicador"] == "km_total" and r["alertas"][0]["linha"] == "02"
    assert gerar_alertas(db, alvo, alvo, linha="99")["total"] == 0  # linha inexistente


def test_us08_rota_e_periodo_sem_dados(client, anonimo):
    r = client.get("/alertas", params={"inicio": "2026-09-01", "fim": "2026-09-30"})
    assert r.status_code == 200 and r.json() == {"inicio": "2026-09-01", "fim": "2026-09-30", "linha": None,
                                                 "total": 0, "criticos": 0, "avisos": 0, "alertas": []}
    assert client.get("/alertas", params={"inicio": "2026-09-30", "fim": "2026-09-01"}).status_code == 400  # RN07
    assert anonimo.get("/alertas", params={"inicio": "2026-09-01", "fim": "2026-09-30"}).status_code == 401  # US11


def test_us08_rota_com_o_pacote_de_exemplo(client, pacote):
    client.post("/importacoes", files=[("arquivos", (nome, conteudo, "text/html")) for nome, conteudo in pacote])
    r = client.get("/alertas", params={"inicio": "2026-09-01", "fim": "2026-09-30"})
    assert r.status_code == 200
    corpo = r.json()
    assert corpo["total"] == corpo["criticos"] + corpo["avisos"] == len(corpo["alertas"])
    for a in corpo["alertas"]:
        assert a["severidade"] in ("aviso", "critico") and a["mensagem"]
