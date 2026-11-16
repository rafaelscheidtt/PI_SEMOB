"""Login, perfil do próprio usuário e cadastro de usuários pelo administrador."""
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


class EdicaoPerfil(BaseModel):
    nome: str | None = None
    senha_atual: str | None = None
    nova_senha: str | None = None
    foto: str | None = None  # data URL da imagem; texto vazio apaga a foto


@router.post("/login")
def login(credenciais: Credenciais, db: Database = Depends(get_db)):
    """Confere e-mail e senha e devolve o token e o papel do usuário."""
    usuario = repo.buscar_por_email(db, credenciais.email)
    if usuario is None or not conferir_senha(credenciais.senha, usuario["senha_hash"]):
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
    if not usuario.get("ativo", False):
        raise HTTPException(status_code=401, detail="Usuário desativado, fale com o administrador")
    return {"token": gerar_token(usuario), "usuario": repo.publico(usuario)}


@router.get("/me")
def quem_sou(usuario: dict = Depends(usuario_atual)):
    """Dados do usuário logado (o app usa para validar a sessão guardada)."""
    return usuario


@router.put("/me")
def editar_perfil(edicao: EdicaoPerfil, db: Database = Depends(get_db), usuario: dict = Depends(usuario_atual)):
    """O usuário logado muda o próprio nome, a foto e a senha. Papel e situação continuam com o administrador."""
    if edicao.nome is not None and not edicao.nome.strip():
        raise HTTPException(status_code=422, detail="Informe o nome")
    if edicao.nova_senha:
        guardado = repo.buscar_por_email(db, usuario["email"])
        # 422 e não 401: o app trata 401 como sessão vencida e voltaria para o login
        if not edicao.senha_atual or not conferir_senha(edicao.senha_atual, guardado["senha_hash"]):
            raise HTTPException(status_code=422, detail="A senha atual não confere")
    try:
        return repo.atualizar(db, usuario["_id"], nome=edicao.nome, senha=edicao.nova_senha or None, foto=edicao.foto)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@router.post("/me/termo")
def aceitar_termo(db: Database = Depends(get_db), usuario: dict = Depends(usuario_atual)):
    """Registra o aceite do termo de uso e aviso de privacidade (LGPD) pelo usuário logado."""
    return repo.aceitar_termo(db, usuario["_id"])


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
