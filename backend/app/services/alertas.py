"""Alertas de desvio na operação (US08).

RN09 cumprimento baixo: dia com FCV abaixo de 95% vira aviso; abaixo de 90%, crítico.
RN10 fora do padrão histórico: km, viagens e passageiros do dia são comparados com a média
     do mesmo dia da semana nas 8 semanas anteriores (precisa de pelo menos 3 semanas com dado);
     desvio acima de 20% vira aviso, acima de 35% vira crítico.
RN11 ocorrências: dia com viagens não realizadas, não iniciadas e não terminadas acima do dobro
     da média diária do período (e pelo menos 3) vira aviso; acima do triplo, crítico.
"""
from collections import defaultdict
from datetime import date, datetime, timedelta

from pymongo.database import Database

from app.services.periodo import validar_intervalo

FCV_AVISO = 95.0
FCV_CRITICO = 90.0
DESVIO_AVISO = 20.0
DESVIO_CRITICO = 35.0
SEMANAS_HISTORICO = 8
MINIMO_SEMANAS = 3
OCORRENCIAS_MINIMO = 3

DIAS_SEMANA = ("segunda", "terça", "quarta", "quinta", "sexta", "sábado", "domingo")
INDICADORES = {"km_total": "Quilometragem", "viagens_realizadas": "Viagens", "passageiros_total": "Passageiros"}


def _dt(d: date) -> datetime:
    return datetime(d.year, d.month, d.day)


def _fmt(v: float, casas: int = 0) -> str:
    """1234567.8 -> '1.234.568' (ou '1.234.567,8' com casas), no jeito brasileiro."""
    texto = f"{v:,.{casas}f}"
    return texto.replace(",", "X").replace(".", ",").replace("X", ".")


def _valores(doc: dict) -> dict:
    """Os três indicadores de um dia, só os que existem no documento."""
    v = {}
    if doc.get("km_total") is not None:
        v["km_total"] = doc["km_total"]
    if doc.get("viagens_realizadas") is not None:
        v["viagens_realizadas"] = doc["viagens_realizadas"]
    total = (doc.get("passageiros") or {}).get("total")
    if total is not None:
        v["passageiros_total"] = total
    return v


def _linha_id(db: Database, codigo: str | None):
    if not codigo:
        return None
    linha = db.linhas.find_one({"codigo": codigo})
    return linha["_id"] if linha else None


def _dias(db: Database, inicio: date, fim: date, linha_id) -> dict[date, dict]:
    colecao = db.operacao_linha_diaria if linha_id is not None else db.operacao_diaria
    filtro = {"data": {"$gte": _dt(inicio), "$lte": _dt(fim)}}
    if linha_id is not None:
        filtro["linha_id"] = linha_id
    return {d["data"].date(): d for d in colecao.find(filtro)}


def _ocorrencias_por_dia(db: Database, inicio: date, fim: date, linha_id) -> dict[date, int]:
    filtro = {"data": {"$gte": _dt(inicio), "$lte": _dt(fim)}}
    if linha_id is not None:
        filtro["linha_id"] = linha_id
    contagem: dict[date, int] = defaultdict(int)
    for d in db.ocorrencias_viagem.aggregate([{"$match": filtro}, {"$group": {"_id": "$data", "n": {"$sum": 1}}}]):
        contagem[d["_id"].date()] += d["n"]
    return contagem


def _alerta(dia: date, tipo: str, indicador: str, severidade: str, valor: float, esperado: float | None,
            desvio: float | None, mensagem: str, linha: str | None) -> dict:
    return {"data": dia, "tipo": tipo, "indicador": indicador, "severidade": severidade, "valor": valor,
            "esperado": esperado, "desvio": desvio, "mensagem": mensagem, "linha": linha}


def _cumprimento(dia: date, doc: dict, linha: str | None) -> dict | None:
    programadas = doc.get("viagens_programadas") or 0
    realizadas = doc.get("viagens_realizadas") or 0
    if not programadas:
        return None
    fcv = round(realizadas / programadas * 100, 2)
    if fcv >= FCV_AVISO:
        return None
    severidade = "critico" if fcv < FCV_CRITICO else "aviso"
    msg = f"Cumprimento de {_fmt(fcv, 1)}% ({_fmt(realizadas)} de {_fmt(programadas)} viagens programadas)"
    return _alerta(dia, "cumprimento", "fcv", severidade, fcv, FCV_AVISO, round(fcv - 100, 2), msg, linha)


def _historico(dia: date, doc: dict, todos: dict[date, dict], linha: str | None) -> list[dict]:
    saida = []
    atuais = _valores(doc)
    for indicador, nome in INDICADORES.items():
        if indicador not in atuais:
            continue
        base = []
        for semanas in range(1, SEMANAS_HISTORICO + 1):
            anterior = todos.get(dia - timedelta(weeks=semanas))
            if anterior is not None and indicador in _valores(anterior):
                base.append(_valores(anterior)[indicador])
        if len(base) < MINIMO_SEMANAS:
            continue
        media = sum(base) / len(base)
        if media <= 0:
            continue
        desvio = round((atuais[indicador] - media) / media * 100, 1)
        if abs(desvio) < DESVIO_AVISO:
            continue
        severidade = "critico" if abs(desvio) >= DESVIO_CRITICO else "aviso"
        direcao = "acima" if desvio > 0 else "abaixo"
        unidade = " km" if indicador == "km_total" else ""
        msg = (f"{nome} {_fmt(abs(desvio))}% {direcao} do normal de uma {DIAS_SEMANA[dia.weekday()]} "
               f"({_fmt(atuais[indicador])}{unidade} vs. {_fmt(media)}{unidade} em média nas últimas {len(base)} semanas)")
        saida.append(_alerta(dia, "historico", indicador, severidade, atuais[indicador], round(media, 2), desvio, msg, linha))
    return saida


def _ocorrencias(contagem: dict[date, int], inicio: date, fim: date, linha: str | None) -> list[dict]:
    if not contagem:
        return []
    dias = (fim - inicio).days + 1
    media = sum(contagem.values()) / dias
    saida = []
    for dia, n in contagem.items():
        if n < OCORRENCIAS_MINIMO or n <= 2 * media:
            continue
        severidade = "critico" if n > 3 * media else "aviso"
        vezes = n / media if media else float(n)
        msg = f"{n} viagens com ocorrência no dia, {_fmt(vezes, 1)}x a média do período ({_fmt(media, 1)} por dia)"
        saida.append(_alerta(dia, "ocorrencias", "ocorrencias", severidade, n, round(media, 2), round((vezes - 1) * 100, 1), msg, linha))
    return saida


def gerar_alertas(db: Database, inicio: date, fim: date, linha: str | None = None) -> dict:
    validar_intervalo(inicio, fim)  # RN07
    linha_id = _linha_id(db, linha)
    if linha and linha_id is None:
        return {"inicio": inicio, "fim": fim, "linha": linha, "total": 0, "criticos": 0, "avisos": 0, "alertas": []}

    # o histórico começa 8 semanas antes do período, para comparar cada dia com o mesmo dia da semana
    todos = _dias(db, inicio - timedelta(weeks=SEMANAS_HISTORICO), fim, linha_id)
    alertas: list[dict] = []
    for dia in sorted(d for d in todos if inicio <= d <= fim):
        doc = todos[dia]
        if linha_id is None:  # o FCV só existe para o sistema inteiro
            a = _cumprimento(dia, doc, linha)
            if a:
                alertas.append(a)
        alertas.extend(_historico(dia, doc, todos, linha))
    alertas.extend(_ocorrencias(_ocorrencias_por_dia(db, inicio, fim, linha_id), inicio, fim, linha))

    alertas.sort(key=lambda a: (a["data"], a["severidade"] == "critico"), reverse=True)
    criticos = sum(1 for a in alertas if a["severidade"] == "critico")
    return {"inicio": inicio, "fim": fim, "linha": linha, "total": len(alertas), "criticos": criticos,
            "avisos": len(alertas) - criticos, "alertas": alertas}
