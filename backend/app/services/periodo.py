"""Chave de período (RN01) e validação de intervalo (RN07)."""
from datetime import date

GRANULARIDADES = ("dia", "semana", "mes")


def chave_periodo(d: date, granularidade: str) -> str:
    """Chave que agrupa um dia na granularidade pedida.

    - `dia`:    `2026-09-15`
    - `semana`: `2026-W38` (semana ISO, segunda a domingo)
    - `mes`:    `2026-09`
    """
    if granularidade == "dia":
        return d.isoformat()
    if granularidade == "semana":
        ano_iso, semana_iso, _ = d.isocalendar()
        return f"{ano_iso}-W{semana_iso:02d}"
    if granularidade == "mes":
        return f"{d.year}-{d.month:02d}"
    raise ValueError(f"granularidade inválida: {granularidade!r}; use uma de {GRANULARIDADES}")


def chaves_do_dia(d: date) -> dict[str, str]:
    """As três chaves de um dia, gravadas junto com o registro para agregação direta no banco."""
    return {f"periodo_{g}": chave_periodo(d, g) for g in GRANULARIDADES}


def validar_intervalo(inicio: date, fim: date) -> None:
    """RN07: a data inicial deve ser anterior ou igual à final."""
    if inicio > fim:
        raise ValueError("A data inicial deve ser anterior ou igual à final")
