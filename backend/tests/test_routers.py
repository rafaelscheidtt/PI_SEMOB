"""Testes de integração das rotas da API."""


def _enviar(client, pacote):
    return client.post("/importacoes", files=[("arquivos", (nome, conteudo, "text/html")) for nome, conteudo in pacote])


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_us01_post_importacao_do_pacote(client, pacote):
    r = _enviar(client, pacote)
    assert r.status_code == 201
    corpo = r.json()
    assert corpo["status"] == "concluida" and corpo["arquivos"] == 11
    assert {x["tipo_relatorio"] for x in corpo["relatorios"]} >= {"resumo_geral", "passageiros", "saldos", "viagens"}
    assert len(client.get("/importacoes").json()) == 11


def test_us01_extensao_invalida_e_recusada(client):
    r = client.post("/importacoes", files=[("arquivos", ("relatorio.pdf", b"x", "application/pdf"))])
    assert r.status_code == 400


def test_us01_relatorio_desconhecido_vira_falha_no_resultado(client):
    r = client.post("/importacoes", files=[("arquivos", ("frota.html", b"<html><body><h1>Frota</h1></body></html>", "text/html"))])
    assert r.status_code == 201 and r.json()["status"] == "falha"


def test_us05_consulta_por_intervalo_e_granularidade(client, pacote):
    _enviar(client, pacote)
    r = client.get("/indicadores", params={"inicio": "2026-09-01", "fim": "2026-09-30", "granularidade": "semana"})
    assert r.status_code == 200
    corpo = r.json()
    assert corpo["sem_dados"] is False
    assert [p["periodo"] for p in corpo["serie"]] == ["2026-W37"]
    assert corpo["totais"]["passageiros_total"] == corpo["totais"]["passageiros_pagantes"] + corpo["totais"]["passageiros_nao_pagantes"]


def test_us05_filtro_por_linha_na_api(client, pacote):
    _enviar(client, pacote)
    assert [l["codigo"] for l in client.get("/linhas").json()] == ["01", "02", "03"]
    r = client.get("/indicadores", params={"inicio": "2026-09-01", "fim": "2026-09-30", "granularidade": "mes", "linha": "02"})
    assert r.json()["linha"] == "02" and r.json()["sem_dados"] is False
    assert r.json()["totais"]["passageiros_total"] is None


def test_us05_resumo_por_linha_e_ocorrencias(client, pacote):
    _enviar(client, pacote)
    linhas = client.get("/indicadores/linhas", params={"inicio": "2026-09-01", "fim": "2026-09-30"}).json()
    assert [l["codigo"] for l in linhas] == ["01", "02", "03"]
    assert sum(l["nao_realizadas"] for l in linhas) == 5
    assert next(l for l in linhas if l["codigo"] == "02")["nao_terminadas"] == 1
    oc = client.get("/ocorrencias", params={"inicio": "2026-09-01", "fim": "2026-09-30", "linha": "02", "tipo": "nao_iniciada"}).json()
    assert len(oc) == 1 and oc[0]["linha"] == "02" and oc[0]["inicio_realizado"] is None


def test_us03_detalhes_por_turno_e_faixa_horaria_na_api(client, pacote):
    _enviar(client, pacote)
    r = client.get("/indicadores/detalhes", params={"inicio": "2026-09-01", "fim": "2026-09-30"})
    assert r.status_code == 200
    corpo = r.json()
    assert [t["turno"] for t in corpo["turnos"]] == ["manha", "tarde", "noite"]
    assert corpo["pico"]["faixa"] in {f["faixa"] for f in corpo["faixas_horarias"]}
    por_linha = client.get("/indicadores/detalhes", params={"inicio": "2026-09-01", "fim": "2026-09-30", "linha": "02"}).json()
    assert por_linha["linha"] == "02" and por_linha["turnos"] == [] and por_linha["faixas_horarias"]
    assert client.get("/indicadores/detalhes", params={"inicio": "2026-09-20", "fim": "2026-09-10"}).status_code == 400


def test_comparativo_na_api(client, pacote):
    _enviar(client, pacote)
    r = client.get("/indicadores", params={"inicio": "2026-09-10", "fim": "2026-09-13", "granularidade": "dia", "comparar": "true"})
    assert r.json()["anterior"]["inicio"] == "2026-09-06"


def test_rn07_intervalo_invertido_retorna_400(client):
    r = client.get("/indicadores", params={"inicio": "2026-09-20", "fim": "2026-09-10"})
    assert r.status_code == 400
    assert "anterior ou igual" in r.json()["detail"]


def test_rn06_periodo_sem_dados_na_api(client):
    r = client.get("/indicadores", params={"inicio": "2026-08-01", "fim": "2026-08-31", "granularidade": "mes"})
    assert r.status_code == 200 and r.json()["sem_dados"] is True and r.json()["totais"] is None


def test_granularidade_invalida_retorna_422(client):
    r = client.get("/indicadores", params={"inicio": "2026-09-01", "fim": "2026-09-02", "granularidade": "ano"})
    assert r.status_code == 422
