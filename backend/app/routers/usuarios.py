"""Login (US11) e cadastro de usuários pelo administrador (US13)."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from pymongo.database import Database

from app.auth import exigir_papel, usuario_atual
from app.db import get_db
from app.repositories import usuarios as repo
from app.seguranca import PAPEIS, conferir_senha, gerar_token

router = APIRouter(tags=["usuarios"])


class Credenciais(BaseModel):
    email: str
    senha: str


class NovoUsuario(BaseModel):
    nome: str
    email: str
    senha: str
    papel: str


class EdicaoUsuario(BaseModel):
    nome: str | None = None
    papel: str | None = None
    ativo: bool | None = None
    senha: str | None = None


@router.post("/login")
def login(credenciais: Credenciais, db: Database = Depends(get_db)):
    """Confere e-mail e senha e devolve o token e o papel do usuário."""
    usuario = repo.buscar_por_email(db, credenciais.email)
    if usuario is None or not conferir_senha(credenciais.senha, usuario["senha_hash"]):
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
    if not usuario.get("ativo", False):
        raise HTTPException(status_code=401, detail="Usuário desativado, fale com o administrador")
    publico = {**{k: v for k, v in usuario.items() if k != "senha_hash"}, "_id": str(usuario["_id"])}
    return {"token": gerar_token(usuario), "usuario": publico}


@router.get("/me")
def quem_sou(usuario: dict = Depends(usuario_atual)):
    """Dados do usuário logado (o app usa para validar a sessão guardada)."""
    return usuario


@router.get("/usuarios", dependencies=[Depends(exigir_papel("administrador"))])
def listar_usuarios(db: Database = Depends(get_db)):
    return repo.listar(db)


@router.post("/usuarios", status_code=201, dependencies=[Depends(exigir_papel("administrador"))])
def criar_usuario(novo: NovoUsuario, db: Database = Depends(get_db)):
    if novo.papel not in PAPEIS:
        raise HTTPException(status_code=422, detail=f"Papel inválido. Use um de: {', '.join(PAPEIS)}")
    try:
        return repo.criar(db, novo.nome, novo.email, novo.senha, novo.papel)
    except ValueError as exc:
        raise HTTPException(status_code=409 if "e-mail" in str(exc) else 422, detail=str(exc)) from exc


@router.put("/usuarios/{usuario_id}")
def editar_usuario(usuario_id: str, edicao: EdicaoUsuario, db: Database = Depends(get_db),
                   admin: dict = Depends(exigir_papel("administrador"))):
    if usuario_id == admin["_id"] and (edicao.ativo is False or (edicao.papel and edicao.papel != "administrador")):
        raise HTTPException(status_code=422, detail="Você não pode desativar nem rebaixar o seu próprio usuário")
    try:
        atualizado = repo.atualizar(db, usuario_id, nome=edicao.nome, papel=edicao.papel, ativo=edicao.ativo, senha=edicao.senha)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    if atualizado is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return atualizado
