"""Importação de relatórios: lê, valida, grava e registra em importacoes.
Aceita um HTML, vários HTMLs ou o .zip do pacote.
"""
import io
import zipfile
from datetime import datetime, timezone

from pymongo.database import Database

from app.ingestao.gravacao import gravar_registros
from app.ingestao.smartreport import ler_relatorio, normalizar
from app.ingestao.validacao import validar_registros

EXTENSOES_ACEITAS = (".html", ".htm", ".zip")


def _dt(d) -> datetime | None:
    return datetime(d.year, d.month, d.day) if d else None


def importar(db: Database, conteudo: bytes, nome_arquivo: str, fonte: str = "smart_report") -> dict:
    """Importa um relatório HTML. Arquivo não reconhecido gera importação com status 'falha'."""
    agora = datetime.now(timezone.utc)
    try:
        relatorio = ler_relatorio(conteudo)
        registros = normalizar(relatorio)
    except ValueError as exc:
        db.importacoes.insert_one({"arquivo_origem": nome_arquivo, "fonte": fonte, "tipo_relatorio": None,
                                   "status": "falha", "erros": [{"numero": 0, "motivo": str(exc)}],
                                   "total_registros": 0, "importados": 0, "rejeitados": 0, "importado_em": agora})
        return {"arquivo": nome_arquivo, "tipo_relatorio": None, "status": "falha", "total_registros": 0,
                "importados": 0, "rejeitados": 0, "inseridos": 0, "atualizados": 0,
                "erros": [{"numero": 0, "motivo": str(exc)}]}

    aceitos, rejeitados = validar_registros(relatorio.tipo, registros)
    total = len(registros)
    if total == 0:
        status = "concluida"  # relatório legítimo sem ocorrências (ex.: nenhuma viagem não iniciada)
    elif not aceitos:
        status = "falha"
    elif rejeitados:
        status = "parcial"
    else:
        status = "concluida"

    datas = [r["data"] for r in aceitos]
    registro = {
        "arquivo_origem": nome_arquivo,
        "fonte": fonte,
        "tipo_relatorio": relatorio.tipo,
        "titulo": relatorio.titulo,
        "periodicidade": relatorio.periodicidade,
        "gerado_em": relatorio.gerado_em,
        "periodo_inicio": _dt(min(datas)) if datas else None,
        "periodo_fim": _dt(max(datas)) if datas else None,
        "total_registros": total,
        "importados": len(aceitos),
        "rejeitados": len(rejeitados),
        "erros": [e.model_dump() for e in rejeitados],
        "status": status,
        "importado_em": agora,
    }
    importacao_id = db.importacoes.insert_one(registro).inserted_id
    contagem = gravar_registros(db, relatorio.tipo, aceitos, importacao_id)
    db.importacoes.update_one({"_id": importacao_id}, {"$set": contagem})

    return {
        "importacao_id": str(importacao_id),
        "arquivo": nome_arquivo,
        "tipo_relatorio": relatorio.tipo,
        "periodo_inicio": min(datas) if datas else None,
        "periodo_fim": max(datas) if datas else None,
        "status": status,
        "total_registros": total,
        "importados": len(aceitos),
        "rejeitados": len(rejeitados),
        **contagem,
        "erros": [e.model_dump() for e in rejeitados],
    }


def expandir_zip(conteudo: bytes) -> list[tuple[str, bytes]]:
    """Devolve (nome, conteúdo) de cada HTML dentro de um .zip, ignorando pastas e outros tipos."""
    arquivos = []
    with zipfile.ZipFile(io.BytesIO(conteudo)) as z:
        for info in z.infolist():
            nome = info.filename
            if info.is_dir() or nome.rsplit("/", 1)[-1].startswith(".") or "__MACOSX" in nome:
                continue
            if nome.lower().endswith((".html", ".htm")):
                arquivos.append((nome, z.read(info)))
    return sorted(arquivos)


def importar_pacote(db: Database, arquivos: list[tuple[str, bytes]]) -> dict:
    """Importa vários arquivos (HTML ou .zip) e consolida o resultado."""
    resultados = []
    for nome, conteudo in arquivos:
        if nome.lower().endswith(".zip"):
            for nome_interno, conteudo_interno in expandir_zip(conteudo):
                resultados.append(importar(db, conteudo_interno, f"{nome}/{nome_interno}"))
        else:
            resultados.append(importar(db, conteudo, nome))

    status = "concluida"
    if resultados and all(r["status"] == "falha" for r in resultados):
        status = "falha"
    elif any(r["status"] in ("falha", "parcial") for r in resultados):
        status = "parcial"
    datas_ini = [r["periodo_inicio"] for r in resultados if r.get("periodo_inicio")]
    datas_fim = [r["periodo_fim"] for r in resultados if r.get("periodo_fim")]
    return {
        "status": status,
        "arquivos": len(resultados),
        "periodo_inicio": min(datas_ini) if datas_ini else None,
        "periodo_fim": max(datas_fim) if datas_fim else None,
        "total_registros": sum(r["total_registros"] for r in resultados),
        "importados": sum(r["importados"] for r in resultados),
        "rejeitados": sum(r["rejeitados"] for r in resultados),
        "inseridos": sum(r["inseridos"] for r in resultados),
        "atualizados": sum(r["atualizados"] for r in resultados),
        "relatorios": resultados,
    }
