"""Leitura dos relatórios HTML do Smart Report (pacote mensal/quinzenal da SEMOB).

Os arquivos vêm em Windows-1252 e o tipo de cada relatório é identificado pelo título.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date, datetime
from html.parser import HTMLParser

CODIFICACAO = "cp1252"

_TIPOS = (
    ("resumo geral", "resumo_geral"),
    ("fator de cumprimento", "fcv"),
    ("resumo por linha", "resumo_linha"),
    ("resumo por faixa hor", "resumo_faixa_horaria"),
    ("partidas por faixa hor", "partidas_faixa_horaria"),
    ("viagens não realizadas", "viagens_nao_realizadas"),
    ("viagens não iniciadas", "viagens_nao_iniciadas"),
    ("viagens não terminadas", "viagens_nao_terminadas"),
    ("passageiros do sistema", "passageiros"),
    ("saldo de créditos", "saldos"),
    ("venda x utilização", "saldos"),
)


@dataclass
class Tabela:
    titulo: str
    cabecalho: list[str]
    linhas: list[list[str]] = field(default_factory=list)


@dataclass
class Relatorio:
    tipo: str
    titulo: str
    periodicidade: str | None  # "mensal" | "quinzenal" | None
    gerado_em: str | None
    tabelas: list[Tabela]


class _Extrator(HTMLParser):
    """Captura títulos (<title>/<h1>) e as tabelas de dados (class="data")."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.titulos: list[str] = []
        self.tabelas: list[Tabela] = []
        self._texto: list[str] | None = None
        self._tag_texto: str | None = None
        self._tabela: Tabela | None = None
        self._linha: list[str] | None = None
        self._celula: list[str] | None = None
        self._eh_th = False

    # utilidades
    def _fechar_linha(self) -> None:
        if self._tabela is not None and self._linha:
            if self._eh_th and not self._tabela.cabecalho:
                self._tabela.cabecalho = self._linha
            else:
                self._tabela.linhas.append(self._linha)
        self._linha = None
        self._eh_th = False

    # eventos do parser
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in ("title", "h1"):
            self._texto, self._tag_texto = [], tag
        elif tag == "table" and a.get("class") == "data":
            self._tabela = Tabela(titulo=self.titulos[-1] if self.titulos else "", cabecalho=[])
        elif self._tabela is not None:
            if tag == "tr":
                self._fechar_linha()
                self._linha = []
            elif tag in ("th", "td"):
                if self._linha is None:
                    self._linha = []
                self._celula = []
                if tag == "th":
                    self._eh_th = True
            elif tag == "br" and self._celula is not None:
                self._celula.append(" ")

    def handle_endtag(self, tag):
        if tag in ("title", "h1") and self._texto is not None:
            t = _limpar(" ".join(self._texto))
            if t and (not self.titulos or self.titulos[-1] != t):
                self.titulos.append(t)
            self._texto = self._tag_texto = None
        elif self._tabela is not None:
            if tag in ("th", "td") and self._celula is not None:
                self._linha.append(_limpar(" ".join(self._celula)))
                self._celula = None
            elif tag == "tr":
                self._fechar_linha()
            elif tag == "table":
                self._fechar_linha()
                self.tabelas.append(self._tabela)
                self._tabela = None

    def handle_data(self, data):
        if self._texto is not None:
            self._texto.append(data)
        elif self._celula is not None:
            self._celula.append(data)


def _limpar(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def identificar_tipo(titulo: str) -> str | None:
    t = titulo.lower()
    for trecho, tipo in _TIPOS:
        if trecho in t:
            return tipo
    if re.search(r"\b(mensal|quinzenal)\s*-\s*viagens$", t):
        return "viagens"
    return None


def ler_relatorio(conteudo: bytes) -> Relatorio:
    """Converte o HTML de um relatório em `Relatorio`. Lança ValueError se não for reconhecido."""
    texto = conteudo.decode(CODIFICACAO, errors="replace")
    extrator = _Extrator()
    extrator.feed(texto)
    extrator.close()

    tipo = None
    titulo = ""
    for t in extrator.titulos:
        tipo = identificar_tipo(t)
        if tipo:
            titulo = t
            break
    if not tipo or not extrator.tabelas:
        raise ValueError("O arquivo não é um relatório Smart Report conhecido")

    periodicidade = None
    inicio = titulo.lower()
    if inicio.startswith("mensal"):
        periodicidade = "mensal"
    elif inicio.startswith("quinzenal"):
        periodicidade = "quinzenal"

    gerado = re.search(r"Gerado por [^<]*</td>\s*<td[^>]*>([^<]+)<", texto)
    return Relatorio(
        tipo=tipo,
        titulo=titulo,
        periodicidade=periodicidade,
        gerado_em=_limpar(gerado.group(1)) if gerado else None,
        tabelas=[t for t in extrator.tabelas if t.cabecalho and not _eh_cabecalho_do_relatorio(t)],
    )


def _eh_cabecalho_do_relatorio(t: Tabela) -> bool:
    """A primeira tabela de alguns relatórios é só o rodapé 'Gerado por Smart Report'."""
    return any("smartdatasource" in c.lower() for c in t.cabecalho)


# conversão de valores

def numero(valor: str | None) -> float | int | None:
    """'6.889,4' -> 6889.4 ; '5.168' -> 5168 ; '' -> None (formato brasileiro)."""
    if valor is None:
        return None
    v = valor.strip()
    if not v or v == "-":
        return None
    v = v.replace(".", "").replace(",", ".")
    try:
        f = float(v)
    except ValueError:
        return None
    return int(f) if f.is_integer() and "." not in v else f


def inteiro(valor: str | None) -> int | None:
    n = numero(valor)
    return int(n) if n is not None else None


def data_br(valor: str | None) -> date | None:
    if not valor:
        return None
    try:
        return datetime.strptime(valor.strip(), "%d/%m/%Y").date()
    except ValueError:
        return None


PULAR = object()  # linha de totais ou cabeçalho repetido: não é um registro


def _dia(valor: str | None):
    """Data dd/mm/aaaa. Linhas de total (sem padrão de data) são puladas; datas inválidas viram None (RN05)."""
    if not valor or not re.match(r"\s*\d{1,2}/\d{1,2}/\d{4}\s*$", valor):
        return PULAR
    return data_br(valor)


def _dia_mes(mes: str | None, dia: str | None):
    if not mes or not dia or not dia.strip().isdigit():
        return PULAR
    return data_mes_dia(mes, dia)


def data_mes_dia(mes: str | None, dia: str | None) -> date | None:
    """Relatórios de bilhetagem trazem 'Mês' (2026-08) e 'Dia' (01) em colunas separadas."""
    if not mes or not dia or not dia.strip().isdigit():
        return None
    try:
        return datetime.strptime(f"{mes.strip()}-{int(dia):02d}", "%Y-%m-%d").date()
    except ValueError:
        return None


def data_hora(valor: str | None) -> datetime | None:
    if not valor:
        return None
    try:
        return datetime.strptime(valor.strip(), "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


def faixa_horaria(valor: str | None) -> int | None:
    """'4hs' -> 4 ; '23' -> 23."""
    if not valor:
        return None
    m = re.match(r"\s*(\d{1,2})", valor)
    return int(m.group(1)) if m else None


# normalização por tipo

def _dicts(tabela: Tabela) -> list[dict[str, str]]:
    n = len(tabela.cabecalho)
    return [dict(zip(tabela.cabecalho, linha)) for linha in tabela.linhas if len(linha) == n]


def _col(d: dict[str, str], *nomes: str) -> str | None:
    """Busca tolerante a acentos/maiúsculas pelo nome da coluna."""
    chaves = {_chave(k): k for k in d}
    for nome in nomes:
        k = chaves.get(_chave(nome))
        if k is not None:
            return d[k]
    return None


def _chave(s: str) -> str:
    s = s.lower()
    for a, b in (("á", "a"), ("ã", "a"), ("â", "a"), ("é", "e"), ("ê", "e"), ("í", "i"), ("ó", "o"), ("õ", "o"), ("ô", "o"), ("ú", "u"), ("ç", "c")):
        s = s.replace(a, b)
    return re.sub(r"[^a-z0-9]", "", s)


def normalizar(relatorio: Relatorio) -> list[dict]:
    """Devolve os registros do relatório com campos padronizados (sem linhas de total)."""
    fn = _NORMALIZADORES.get(relatorio.tipo)
    if fn is None:
        raise ValueError(f"tipo sem normalizador: {relatorio.tipo}")
    return fn(relatorio)


def _resumo_geral(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        out.append({
            "data": dia,
            "dia_semana": _col(d, "diaSem"),
            "veiculos": inteiro(_col(d, "nrVeiculos")),
            "veiculos_max_faixa": inteiro(_col(d, "nrMaxVeicFx")),
            "viagens_programadas": inteiro(_col(d, "nrViagensProgr")),
            "viagens_realizadas": inteiro(_col(d, "nrViagensRealiz")),
            "km_produtiva": numero(_col(d, "kmProd")),
            "km_improdutiva": numero(_col(d, "kmImprod")),
            "km_total": numero(_col(d, "kmTotal")),
        })
    return out


def _fcv(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        out.append({
            "data": dia,
            "turnos": {
                turno: {"programadas": inteiro(_col(d, f"{turno}_p")), "realizadas": inteiro(_col(d, f"{turno}_r"))}
                for turno in ("manha", "tarde", "noite")
            },
            "viagens_programadas": inteiro(_col(d, "programadas")),
            "viagens_realizadas": inteiro(_col(d, "realizadas")),
        })
    return out


def _resumo_linha(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        out.append({
            "data": dia,
            "linha": _col(d, "Linha"),
            "km_total": numero(_col(d, "kmTotal")),
            "viagens_realizadas": inteiro(_col(d, "nrViagens")),
        })
    return out


def _resumo_faixa(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        out.append({
            "data": dia,
            "faixa": faixa_horaria(_col(d, "Fx_Hor")),
            "veiculos": inteiro(_col(d, "Nr_Veiculos")),
            "viagens": inteiro(_col(d, "Nr_Viagens")),
        })
    return out


def _partidas_faixa(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        partidas = _col(d, "Partidas") or ""
        out.append({
            "data": dia,
            "linha": _col(d, "Linha"),
            "faixa": faixa_horaria(_col(d, "Fx_Hor")),
            "veiculos": inteiro(_col(d, "Nr_Veiculos")),
            "viagens": inteiro(_col(d, "Nr_Viagens")),
            "partidas": [p.strip() for p in partidas.split(">") if p.strip()],
        })
    return out


def _viagens(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia(_col(d, "Data"))
        if dia is PULAR:
            continue
        out.append({
            "data": dia,
            "linha": _col(d, "Linha") or None,  # deslocamentos improdutivos não têm linha
            "prefixo": _col(d, "Prefixo"),
            "atividade": _col(d, "Atividade"),
            "sentido": _col(d, "Sentido"),
            "faixa": faixa_horaria(_col(d, "Fx_Hor")),
            "inicio_realizado": data_hora(_col(d, "inicioRealizado")),
            "fim_realizado": data_hora(_col(d, "fimRealizado")),
            "km_produtiva": numero(_col(d, "kmProd")),
            "km_improdutiva": numero(_col(d, "kmImprod")),
            "km_total": numero(_col(d, "kmTotal")),
        })
    return out


def _ocorrencias(tipo: str):
    def fn(r: Relatorio) -> list[dict]:
        out = []
        for d in _dicts(r.tabelas[0]):
            dia = _dia(_col(d, "Data"))
            if dia is PULAR:
                continue
            # "Motorista" não é gravado (dado pessoal)
            out.append({
                "tipo": tipo,
                "data": dia,
                "linha": _col(d, "Linha"),
                "atendimento": _col(d, "Atendimento"),
                "prefixo": _col(d, "Prefixo") or None,
                "atividade": _col(d, "Atividade"),
                "sentido": _col(d, "Sentido"),
                "tabela": _col(d, "Tabela"),
                "status_saida": _col(d, "statusSaida") or None,
                "status_chegada": _col(d, "statusChegada") or None,
                "inicio_programado": data_hora(_col(d, "inicioProgramado")),
                "inicio_realizado": data_hora(_col(d, "inicioRealizado")),
                "fim_programado": data_hora(_col(d, "fimProgramado")),
                "fim_realizado": data_hora(_col(d, "fimRealizado")),
            })
        return out

    return fn


def _passageiros(r: Relatorio) -> list[dict]:
    out = []
    for d in _dicts(r.tabelas[0]):
        dia = _dia_mes(_col(d, "Mês"), _col(d, "Dia"))
        if dia is PULAR:
            continue
        catraca = inteiro(_col(d, "Catraca")) or 0
        antecipados = inteiro(_col(d, "Antecipados")) or 0
        nao_pagantes = inteiro(_col(d, "Não Pagantes")) or 0
        out.append({
            "data": dia,
            "catraca": catraca,
            "antecipados": antecipados,
            "pagantes": catraca + antecipados,
            "nao_pagantes": nao_pagantes,
            "total": inteiro(_col(d, "Total Passageiros")) or catraca + antecipados + nao_pagantes,
        })
    return out


def _saldos(r: Relatorio) -> list[dict]:
    por_dia: dict[date, dict] = {}
    for tabela in r.tabelas:
        for d in _dicts(tabela):
            dia = _dia_mes(_col(d, "Mês"), _col(d, "Dia"))
            if dia is PULAR:
                continue
            if dia is None:
                continue  # data inválida em relatório de saldo: ignorada
            reg = por_dia.setdefault(dia, {"data": dia})
            if "saldo" in tabela.titulo.lower():
                reg["creditos_transferidos"] = numero(_col(d, "Créditos transferidos para cartões"))
                reg["saldo_final"] = numero(_col(d, "Saldo Final"))
            else:
                reg["vendas"] = numero(_col(d, "Total Vendas"))
                reg["utilizacao"] = numero(_col(d, "Total Utilização"))
                reg["credito_circulante"] = numero(_col(d, "Crédito Circulante"))
    return [por_dia[k] for k in sorted(por_dia)]


_NORMALIZADORES = {
    "resumo_geral": _resumo_geral,
    "fcv": _fcv,
    "resumo_linha": _resumo_linha,
    "resumo_faixa_horaria": _resumo_faixa,
    "partidas_faixa_horaria": _partidas_faixa,
    "viagens": _viagens,
    "viagens_nao_realizadas": _ocorrencias("nao_realizada"),
    "viagens_nao_iniciadas": _ocorrencias("nao_iniciada"),
    "viagens_nao_terminadas": _ocorrencias("nao_terminada"),
    "passageiros": _passageiros,
    "saldos": _saldos,
}
