"""Importação pela linha de comando.

    python -m app.cli caminho/da/pasta        # todos os .html da pasta (recursivo)
    python -m app.cli pacote.zip              # o .zip disponibilizado pela SEMOB
    python -m app.cli Mensal_202608.html ...  # um ou mais relatórios
"""
import json
import sys
from pathlib import Path

from app.db import criar_indices, get_db
from app.ingestao.servico import importar_pacote


def coletar(caminhos: list[str]) -> list[tuple[str, bytes]]:
    arquivos = []
    for c in caminhos:
        p = Path(c)
        if p.is_dir():
            for h in sorted(p.rglob("*.htm*")):
                arquivos.append((str(h.relative_to(p.parent)), h.read_bytes()))
        else:
            arquivos.append((p.name, p.read_bytes()))
    return arquivos


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    db = get_db()
    criar_indices(db)
    resultado = importar_pacote(db, coletar(argv[1:]))
    for r in resultado["relatorios"]:
        print(f"{r['status']:9s} {r['tipo_relatorio'] or '-':24s} {r['importados']:7d} registros  {r['arquivo']}")
    resumo = {k: v for k, v in resultado.items() if k != "relatorios"}
    print(json.dumps(resumo, ensure_ascii=False, indent=2, default=str))
    return 0 if resultado["status"] != "falha" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
