"""Senhas e tokens de acesso (US11).

Tudo com a biblioteca padrão do Python: a senha é guardada com PBKDF2 (sal aleatório)
e o token é um JSON assinado com HMAC-SHA256, no mesmo formato de um JWT HS256.
"""
import base64
import hashlib
import hmac
import json
import secrets
from datetime import datetime, timedelta, timezone

from app.config import settings

PAPEIS = ("administrador", "gestor", "executivo")
_ITERACOES = 200_000


def gerar_hash(senha: str) -> str:
    sal = secrets.token_hex(16)
    resumo = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal.encode(), _ITERACOES).hex()
    return f"pbkdf2${_ITERACOES}${sal}${resumo}"


def conferir_senha(senha: str, guardado: str) -> bool:
    try:
        _, iteracoes, sal, resumo = guardado.split("$")
    except ValueError:
        return False
    calculado = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal.encode(), int(iteracoes)).hex()
    return hmac.compare_digest(calculado, resumo)


def _b64(dados: bytes) -> str:
    return base64.urlsafe_b64encode(dados).rstrip(b"=").decode()


def _de_b64(texto: str) -> bytes:
    return base64.urlsafe_b64decode(texto + "=" * (-len(texto) % 4))


def _assinar(parte: str) -> str:
    return _b64(hmac.new(settings.token_secret.encode(), parte.encode(), hashlib.sha256).digest())


def gerar_token(usuario: dict, horas: int | None = None) -> str:
    """Token com e-mail, papel e validade (em horas, `TOKEN_HORAS` no .env)."""
    expira = datetime.now(timezone.utc) + timedelta(hours=horas or settings.token_horas)
    cabecalho = _b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    corpo = _b64(json.dumps({"sub": usuario["email"], "papel": usuario["papel"], "exp": int(expira.timestamp())}).encode())
    return f"{cabecalho}.{corpo}.{_assinar(f'{cabecalho}.{corpo}')}"


def ler_token(token: str) -> dict | None:
    """Devolve o conteúdo do token, ou None se a assinatura não bater ou ele tiver vencido."""
    try:
        cabecalho, corpo, assinatura = token.split(".")
    except ValueError:
        return None
    if not hmac.compare_digest(_assinar(f"{cabecalho}.{corpo}"), assinatura):
        return None
    try:
        dados = json.loads(_de_b64(corpo))
    except (ValueError, UnicodeDecodeError):
        return None
    if dados.get("exp", 0) < datetime.now(timezone.utc).timestamp():
        return None
    return dados
