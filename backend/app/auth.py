"""Dependências de autenticação das rotas (US11).

    usuario = Depends(usuario_atual)                 -> qualquer usuário logado
    usuario = Depends(exigir_papel("administrador")) -> só os papéis indicados
"""
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pymongo.database import Database

from app.db import get_db
from app.repositories import usuarios as repo
from app.seguranca import ler_token

# aparece como o botão "Authorize" do /docs
_bearer = HTTPBearer(auto_error=False, description="Cole o token devolvido pelo POST /login")


def usuario_atual(credencial: HTTPAuthorizationCredentials | None = Depends(_bearer), db: Database = Depends(get_db)) -> dict:
    if credencial is None or not credencial.credentials:
        raise HTTPException(status_code=401, detail="Faça login para acessar o painel")
    dados = ler_token(credencial.credentials)
    if dados is None:
        raise HTTPException(status_code=401, detail="Sessão inválida ou expirada, faça login de novo")
    usuario = repo.buscar_por_email(db, dados["sub"])
    if usuario is None or not usuario.get("ativo", False):
        raise HTTPException(status_code=401, detail="Usuário desativado, fale com o administrador")
    return {**{k: v for k, v in usuario.items() if k != "senha_hash"}, "_id": str(usuario["_id"])}


def exigir_papel(*papeis: str):
    def verificar(usuario: dict = Depends(usuario_atual)) -> dict:
        if usuario["papel"] not in papeis:
            raise HTTPException(status_code=403, detail="Seu perfil não tem acesso a esta função")
        return usuario

    return verificar
