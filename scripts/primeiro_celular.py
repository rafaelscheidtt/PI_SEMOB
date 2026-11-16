"""Lê a saída de `flutter devices --machine` e mostra o id do primeiro celular ligado.

Usado pelos atalhos "instalar no celular (cabo)":
    python scripts/primeiro_celular.py aparelhos.json            -> Android ou iPhone
    python scripts/primeiro_celular.py aparelhos.json android    -> só Android
    python scripts/primeiro_celular.py aparelhos.json simulador  -> só simulador de iPhone aberto no Mac
Não mostra nada se não houver celular (ou se o arquivo não for um JSON válido).
"""
import json
import sys


def primeiro(caminho: str, plataformas: tuple[str, ...], so_simulador: bool = False) -> str:
    try:
        with open(caminho, encoding="utf-8") as arquivo:
            aparelhos = json.load(arquivo)
    except (OSError, ValueError):
        return ""
    for aparelho in aparelhos if isinstance(aparelhos, list) else []:
        plataforma = str(aparelho.get("targetPlatform", ""))
        if plataforma.startswith(plataformas) and (not so_simulador or aparelho.get("emulator")):
            return str(aparelho.get("id", ""))
    return ""


if __name__ == "__main__":
    opcoes = sys.argv[2:]
    if opcoes == ["simulador"]:
        print(primeiro(sys.argv[1], ("ios",), so_simulador=True))
    else:
        print(primeiro(sys.argv[1], tuple(opcoes) or ("android", "ios")))
