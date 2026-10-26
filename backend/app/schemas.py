"""Contratos das respostas da API."""
from datetime import date, datetime

from pydantic import BaseModel


class Ponto(BaseModel):
    periodo: str
    km_total: float
    km_produtiva: float | None
    viagens_programadas: int | None
    viagens_realizadas: int
    fcv: float | None
    passageiros_pagantes: int | None
    passageiros_nao_pagantes: int | None
    passageiros_total: int | None
    media_passageiros_por_viagem: float | None
    dias_com_dados: int
    dias_com_passageiros: int = 0


class Totais(BaseModel):
    km_total: float
    km_produtiva: float | None
    viagens_programadas: int | None
    viagens_realizadas: int
    fcv: float | None
    passageiros_pagantes: int | None
    passageiros_nao_pagantes: int | None
    passageiros_total: int | None
    media_passageiros_por_viagem: float | None
    dias_com_dados: int
    dias_com_passageiros: int = 0


class PeriodoAnterior(BaseModel):
    inicio: date
    fim: date
    totais: Totais


class RespostaIndicadores(BaseModel):
    granularidade: str
    inicio: date
    fim: date
    linha: str | None
    sem_dados: bool
    serie: list[Ponto]
    totais: Totais | None
    anterior: PeriodoAnterior | None = None


class Turno(BaseModel):
    turno: str
    programadas: int
    realizadas: int
    fcv: float | None


class FaixaHoraria(BaseModel):
    faixa: int
    viagens: int
    veiculos: int


class Pico(BaseModel):
    faixa: int
    viagens: int


class DetalhesOperacao(BaseModel):
    linha: str | None
    turnos: list[Turno]
    faixas_horarias: list[FaixaHoraria]
    pico: Pico | None


class ResumoLinha(BaseModel):
    codigo: str
    nome: str
    km_total: float
    viagens_realizadas: int
    dias_com_dados: int
    nao_realizadas: int
    nao_iniciadas: int
    nao_terminadas: int


class Ocorrencia(BaseModel):
    tipo: str
    data: date
    linha: str | None
    atendimento: str | None
    prefixo: str | None
    sentido: str | None
    tabela: str | None
    inicio_programado: datetime | None
    inicio_realizado: datetime | None
    fim_programado: datetime | None
    fim_realizado: datetime | None


class ErroLinha(BaseModel):
    numero: int
    motivo: str


class ResultadoRelatorio(BaseModel):
    importacao_id: str | None = None
    arquivo: str
    tipo_relatorio: str | None
    periodo_inicio: date | None = None
    periodo_fim: date | None = None
    status: str
    total_registros: int
    importados: int
    rejeitados: int
    inseridos: int
    atualizados: int
    erros: list[ErroLinha]


class RespostaImportacao(BaseModel):
    status: str
    arquivos: int
    periodo_inicio: date | None
    periodo_fim: date | None
    total_registros: int
    importados: int
    rejeitados: int
    inseridos: int
    atualizados: int
    relatorios: list[ResultadoRelatorio]


class Linha(BaseModel):
    codigo: str
    nome: str
    atendimentos: list[str] = []
