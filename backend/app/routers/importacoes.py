from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pymongo.database import Database

from app.db import get_db
from app.ingestao.servico import EXTENSOES_ACEITAS, importar_pacote
from app.schemas import RespostaImportacao

router = APIRouter(tags=["importacoes"])


@router.post("/importacoes", response_model=RespostaImportacao, status_code=201)
async def criar_importacao(arquivos: list[UploadFile] = File(...), db: Database = Depends(get_db)):
    """Recebe um ou mais relatórios HTML do Smart Report, ou o .zip do pacote."""
    entrada = []
    for arquivo in arquivos:
        nome = arquivo.filename or ""
        if not nome.lower().endswith(EXTENSOES_ACEITAS):
            raise HTTPException(status_code=400, detail=f"Envie relatórios .html do Smart Report ou o pacote .zip ({nome})")
        entrada.append((nome, await arquivo.read()))
    try:
        return importar_pacote(db, entrada)
    except Exception as exc:  # zip corrompido ou arquivo ilegível
        raise HTTPException(status_code=400, detail=f"Não foi possível ler os arquivos: {exc}") from exc


@router.get("/importacoes")
def listar_importacoes(db: Database = Depends(get_db)):
    docs = db.importacoes.find({}, {"erros": 0}).sort("importado_em", -1).limit(100)
    return [{**d, "_id": str(d["_id"])} for d in docs]
