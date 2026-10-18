/// Modelos das respostas da API.
/// Passageiros podem vir nulos (consulta por linha ou período sem bilhetagem).
class Medidas {
  const Medidas({
    required this.kmTotal,
    required this.viagens,
    this.kmProdutiva,
    this.viagensProgramadas,
    this.fcv,
    this.pagantes,
    this.naoPagantes,
    this.total,
    this.mediaPorViagem,
    this.diasComDados = 0,
  });

  final double kmTotal;
  final double? kmProdutiva;
  final int? viagensProgramadas;
  final int viagens;
  final double? fcv;
  final int? pagantes;
  final int? naoPagantes;
  final int? total;
  final double? mediaPorViagem;
  final int diasComDados;

  static Medidas fromJson(Map<String, dynamic> j) => Medidas(
        kmTotal: (j['km_total'] as num).toDouble(),
        kmProdutiva: (j['km_produtiva'] as num?)?.toDouble(),
        viagensProgramadas: j['viagens_programadas'] as int?,
        viagens: j['viagens_realizadas'] as int,
        fcv: (j['fcv'] as num?)?.toDouble(),
        pagantes: j['passageiros_pagantes'] as int?,
        naoPagantes: j['passageiros_nao_pagantes'] as int?,
        total: j['passageiros_total'] as int?,
        mediaPorViagem: (j['media_passageiros_por_viagem'] as num?)?.toDouble(),
        diasComDados: (j['dias_com_dados'] as int?) ?? 0,
      );
}

class PontoIndicador extends Medidas {
  const PontoIndicador({
    required this.periodo,
    required super.kmTotal,
    required super.viagens,
    super.kmProdutiva,
    super.viagensProgramadas,
    super.fcv,
    super.pagantes,
    super.naoPagantes,
    super.total,
    super.mediaPorViagem,
    super.diasComDados,
  });

  final String periodo;

  factory PontoIndicador.fromJson(Map<String, dynamic> j) {
    final m = Medidas.fromJson(j);
    return PontoIndicador(
      periodo: j['periodo'] as String,
      kmTotal: m.kmTotal,
      viagens: m.viagens,
      kmProdutiva: m.kmProdutiva,
      viagensProgramadas: m.viagensProgramadas,
      fcv: m.fcv,
      pagantes: m.pagantes,
      naoPagantes: m.naoPagantes,
      total: m.total,
      mediaPorViagem: m.mediaPorViagem,
      diasComDados: m.diasComDados,
    );
  }
}

typedef Totais = Medidas;

class PeriodoAnterior {
  const PeriodoAnterior({required this.inicio, required this.fim, required this.totais});
  final DateTime inicio;
  final DateTime fim;
  final Totais totais;

  factory PeriodoAnterior.fromJson(Map<String, dynamic> j) => PeriodoAnterior(
        inicio: DateTime.parse(j['inicio'] as String),
        fim: DateTime.parse(j['fim'] as String),
        totais: Medidas.fromJson(j['totais'] as Map<String, dynamic>),
      );
}

class Indicadores {
  const Indicadores({required this.semDados, required this.serie, this.totais, this.anterior});

  final bool semDados;
  final List<PontoIndicador> serie;
  final Totais? totais;
  final PeriodoAnterior? anterior;

  factory Indicadores.fromJson(Map<String, dynamic> j) => Indicadores(
        semDados: j['sem_dados'] as bool,
        serie: (j['serie'] as List).map((e) => PontoIndicador.fromJson(e as Map<String, dynamic>)).toList(),
        totais: j['totais'] == null ? null : Medidas.fromJson(j['totais'] as Map<String, dynamic>),
        anterior: j['anterior'] == null ? null : PeriodoAnterior.fromJson(j['anterior'] as Map<String, dynamic>),
      );

  static const vazio = Indicadores(semDados: true, serie: []);
}

class Linha {
  const Linha({required this.codigo, required this.nome});
  final String codigo;
  final String nome;

  factory Linha.fromJson(Map<String, dynamic> j) => Linha(codigo: j['codigo'] as String, nome: j['nome'] as String);
}
