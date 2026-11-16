"""Coleção `usuarios` (US11/US13): quem pode entrar no painel e com qual papel."""
import base64
import binascii
from datetime import datetime, timezone

from bson import ObjectId
from pymongo.database import Database

from app.seguranca import PAPEIS, gerar_hash

CAMPOS_PUBLICOS = {"senha_hash": 0}

# A foto do perfil fica no próprio documento, como data URL. O app já manda reduzida (160 px),
# então o limite é folgado: 200 mil caracteres dão uns 150 KB de imagem.
FOTO_FORMATOS = ("data:image/png;base64,", "data:image/jpeg;base64,")
FOTO_TAMANHO_MAXIMO = 200_000


def validar_foto(foto: str) -> None:
    if not foto.startswith(FOTO_FORMATOS):
        raise ValueError("a foto precisa ser uma imagem PNG ou JPEG")
    if len(foto) > FOTO_TAMANHO_MAXIMO:
        raise ValueError("a foto é grande demais")
    try:
        base64.b64decode(foto.split(",", 1)[1], validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("não foi possível ler a foto") from exc


def _publico(doc: dict | None) -> dict | None:
    if doc is None:
        return None
    return {**{k: v for k, v in doc.items() if k != "senha_hash"}, "_id": str(doc["_id"])}


def buscar_por_email(db: Database, email: str) -> dict | None:
    """Documento completo (com o hash), para conferir a senha no login."""
    return db.usuarios.find_one({"email": email.strip().lower()})


def buscar_por_id(db: Database, usuario_id: str) -> dict | None:
    try:
        return _publico(db.usuarios.find_one({"_id": ObjectId(usuario_id)}))
    except Exception:
        return None


def listar(db: Database) -> list[dict]:
    return [_publico(d) for d in db.usuarios.find().sort("nome", 1)]


def criar(db: Database, nome: str, email: str, senha: str, papel: str) -> dict:
    if papel not in PAPEIS:
        raise ValueError(f"papel inválido: {papel}")
    if len(senha) < 6:
        raise ValueError("a senha precisa ter pelo menos 6 caracteres")
    email = email.strip().lower()
    if "@" not in email or " " in email:
        raise ValueError("e-mail inválido")
    if buscar_por_email(db, email):
        raise ValueError("já existe um usuário com este e-mail")
    doc = {
        "nome": nome.strip(),
        "email": email,
        "senha_hash": gerar_hash(senha),
        "papel": papel,
        "ativo": True,
        "criado_em": datetime.now(timezone.utc),
    }
    doc["_id"] = db.usuarios.insert_one(doc).inserted_id
    return _publico(doc)


def atualizar(db: Database, usuario_id: str, *, nome: str | None = None, papel: str | None = None,
              ativo: bool | None = None, senha: str | None = None, foto: str | None = None) -> dict | None:
    """Muda só o que foi informado. Em `foto`, texto vazio apaga a foto atual."""
    mudancas: dict = {}
    apagar: dict = {}
    if nome is not None:
        mudancas["nome"] = nome.strip()
    if papel is not None:
        if papel not in PAPEIS:
            raise ValueError(f"papel inválido: {papel}")
        mudancas["papel"] = papel
    if ativo is not None:
        mudancas["ativo"] = ativo
    if senha is not None:
        if len(senha) < 6:
            raise ValueError("a senha precisa ter pelo menos 6 caracteres")
        mudancas["senha_hash"] = gerar_hash(senha)
    if foto is not None:
        if foto == "":
            apagar["foto"] = ""
        else:
            validar_foto(foto)
            mudancas["foto"] = foto
    if not mudancas and not apagar:
        return buscar_por_id(db, usuario_id)
    try:
        oid = ObjectId(usuario_id)
    except Exception:
        return None
    operacao = {}
    if mudancas:
        operacao["$set"] = mudancas
    if apagar:
        operacao["$unset"] = apagar
    db.usuarios.update_one({"_id": oid}, operacao)
    return buscar_por_id(db, usuario_id)


def garantir_admin_inicial(db: Database, nome: str, email: str, senha: str) -> dict | None:
    """Cria o primeiro administrador se a coleção ainda estiver vazia (usado pela CLI e pelo .env)."""
    if db.usuarios.count_documents({}) > 0:
        return None
    return criar(db, nome, email, senha, "administrador")
