"""Cria o primeiro administrador do painel pela linha de comando.

    python -m app.usuarios_cli criar-admin "Nome" email@semob.gov.br
    (a senha é pedida na hora, sem aparecer na tela)

Se já existir algum usuário, não faz nada: os demais são cadastrados pelo
administrador dentro do app, na tela Usuários.
"""
import getpass
import sys

from app.db import criar_indices, get_db
from app.repositories.usuarios import garantir_admin_inicial


def main(argv: list[str]) -> int:
    if len(argv) < 4 or argv[1] != "criar-admin":
        print(__doc__)
        return 2
    nome, email = argv[2], argv[3]
    senha = argv[4] if len(argv) > 4 else getpass.getpass("Senha do administrador: ")
    db = get_db()
    criar_indices(db)
    try:
        criado = garantir_admin_inicial(db, nome, email, senha)
    except ValueError as exc:
        print(f"erro: {exc}")
        return 1
    if criado is None:
        print("já existe usuário cadastrado; use a tela Usuários do app para criar outros")
        return 1
    print(f"administrador criado: {criado['email']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
