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
    this.diasComPassageiros = 0,
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
  final int diasComPassageiros;

  /// Quilometragem improdutiva, quando a API informa a produtiva.
  double? get kmImprodutiva => kmProdutiva == null ? null : kmTotal - kmProdutiva!;

  /// Viagens que estavam programadas e não aconteceram.
  int? get viagensNaoRealizadas => viagensProgramadas == null ? null : viagensProgramadas! - viagens;

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
        diasComPassageiros: (j['dias_com_passageiros'] as int?) ?? 0,
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
    super.diasComPassageiros,
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
      diasComPassageiros: m.diasComPassageiros,
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

/// Variação percentual de um valor em relação ao período anterior.
/// Devolve `null` quando não dá para comparar (sem período anterior ou base zero).
double? variacaoPercentual(num? atual, num? anterior) {
  if (atual == null || anterior == null || anterior == 0) return null;
  return (atual - anterior) / anterior * 100;
}

class Linha {
  const Linha({required this.codigo, required this.nome});
  final String codigo;
  final String nome;

  factory Linha.fromJson(Map<String, dynamic> j) => Linha(codigo: j['codigo'] as String, nome: j['nome'] as String);
}

/// Totais de uma linha no período (GET /indicadores/linhas).
class ResumoLinha {
  const ResumoLinha({
    required this.codigo,
    required this.nome,
    required this.kmTotal,
    required this.viagens,
    required this.diasComDados,
    this.naoRealizadas = 0,
    this.naoIniciadas = 0,
    this.naoTerminadas = 0,
  });

  final String codigo;
  final String nome;
  final double kmTotal;
  final int viagens;
  final int diasComDados;
  final int naoRealizadas;
  final int naoIniciadas;
  final int naoTerminadas;

  int get ocorrencias => naoRealizadas + naoIniciadas + naoTerminadas;
  double? get kmPorViagem => viagens == 0 ? null : kmTotal / viagens;

  factory ResumoLinha.fromJson(Map<String, dynamic> j) => ResumoLinha(
        codigo: j['codigo'] as String,
        nome: j['nome'] as String,
        kmTotal: (j['km_total'] as num).toDouble(),
        viagens: j['viagens_realizadas'] as int,
        diasComDados: (j['dias_com_dados'] as int?) ?? 0,
        naoRealizadas: (j['nao_realizadas'] as int?) ?? 0,
        naoIniciadas: (j['nao_iniciadas'] as int?) ?? 0,
        naoTerminadas: (j['nao_terminadas'] as int?) ?? 0,
      );
}

/// Tipos de ocorrência de viagem, com o texto exibido no painel.
enum TipoOcorrencia {
  naoRealizada('nao_realizada', 'Não realizada'),
  naoIniciada('nao_iniciada', 'Não iniciada'),
  naoTerminada('nao_terminada', 'Não terminada');

  const TipoOcorrencia(this.valorApi, this.rotulo);
  final String valorApi;
  final String rotulo;

  static TipoOcorrencia daApi(String v) => values.firstWhere((t) => t.valorApi == v, orElse: () => naoRealizada);
}

/// Uma viagem programada que não foi realizada, iniciada ou terminada (GET /ocorrencias).
class Ocorrencia {
  const Ocorrencia({
    required this.tipo,
    required this.data,
    this.linha,
    this.atendimento,
    this.prefixo,
    this.sentido,
    this.tabela,
    this.inicioProgramado,
    this.inicioRealizado,
    this.fimProgramado,
    this.fimRealizado,
  });

  final TipoOcorrencia tipo;
  final DateTime data;
  final String? linha;
  final String? atendimento;
  final String? prefixo;
  final String? sentido;
  final String? tabela;
  final DateTime? inicioProgramado;
  final DateTime? inicioRealizado;
  final DateTime? fimProgramado;
  final DateTime? fimRealizado;

  factory Ocorrencia.fromJson(Map<String, dynamic> j) => Ocorrencia(
        tipo: TipoOcorrencia.daApi(j['tipo'] as String),
        data: DateTime.parse(j['data'] as String),
        linha: j['linha'] as String?,
        atendimento: j['atendimento'] as String?,
        prefixo: j['prefixo'] as String?,
        sentido: j['sentido'] as String?,
        tabela: j['tabela'] as String?,
        inicioProgramado: _dataHora(j['inicio_programado']),
        inicioRealizado: _dataHora(j['inicio_realizado']),
        fimProgramado: _dataHora(j['fim_programado']),
        fimRealizado: _dataHora(j['fim_realizado']),
      );
}

DateTime? _dataHora(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Viagens programadas e realizadas de um turno (GET /indicadores/detalhes).
class Turno {
  const Turno({required this.turno, required this.programadas, required this.realizadas, this.fcv});

  final String turno;
  final int programadas;
  final int realizadas;
  final double? fcv;

  String get rotulo => switch (turno) {
        'manha' => 'Manhã',
        'tarde' => 'Tarde',
        'noite' => 'Noite',
        _ => turno,
      };

  factory Turno.fromJson(Map<String, dynamic> j) => Turno(
        turno: j['turno'] as String,
        programadas: j['programadas'] as int,
        realizadas: j['realizadas'] as int,
        fcv: (j['fcv'] as num?)?.toDouble(),
      );
}

/// Soma das viagens de uma faixa horária (hora de início) no período.
class FaixaHoraria {
  const FaixaHoraria({required this.faixa, required this.viagens, this.veiculos = 0});

  final int faixa;
  final int viagens;
  final int veiculos;

  factory FaixaHoraria.fromJson(Map<String, dynamic> j) => FaixaHoraria(
        faixa: j['faixa'] as int,
        viagens: j['viagens'] as int,
        veiculos: (j['veiculos'] as int?) ?? 0,
      );
}

class DetalhesOperacao {
  const DetalhesOperacao({this.linha, this.turnos = const [], this.faixasHorarias = const []});

  final String? linha;
  final List<Turno> turnos;
  final List<FaixaHoraria> faixasHorarias;

  FaixaHoraria? get pico {
    if (faixasHorarias.isEmpty) return null;
    var maior = faixasHorarias.first;
    for (final f in faixasHorarias) {
      if (f.viagens > maior.viagens) maior = f;
    }
    return maior;
  }

  factory DetalhesOperacao.fromJson(Map<String, dynamic> j) => DetalhesOperacao(
        linha: j['linha'] as String?,
        turnos: (j['turnos'] as List).map((e) => Turno.fromJson(e as Map<String, dynamic>)).toList(),
        faixasHorarias: (j['faixas_horarias'] as List).map((e) => FaixaHoraria.fromJson(e as Map<String, dynamic>)).toList(),
      );

  static const vazio = DetalhesOperacao();
}

/// Um relatório importado (GET /importacoes).
class Importacao {
  const Importacao({
    required this.arquivo,
    required this.status,
    required this.totalRegistros,
    required this.importados,
    required this.rejeitados,
    this.tipoRelatorio,
    this.titulo,
    this.periodicidade,
    this.periodoInicio,
    this.periodoFim,
    this.importadoEm,
  });

  final String arquivo;
  final String status;
  final int totalRegistros;
  final int importados;
  final int rejeitados;
  final String? tipoRelatorio;
  final String? titulo;
  final String? periodicidade;
  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final DateTime? importadoEm;

  factory Importacao.fromJson(Map<String, dynamic> j) => Importacao(
        arquivo: (j['arquivo_origem'] ?? j['arquivo'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        totalRegistros: (j['total_registros'] as int?) ?? 0,
        importados: (j['importados'] as int?) ?? 0,
        rejeitados: (j['rejeitados'] as int?) ?? 0,
        tipoRelatorio: j['tipo_relatorio'] as String?,
        titulo: j['titulo'] as String?,
        periodicidade: j['periodicidade'] as String?,
        periodoInicio: _dataHora(j['periodo_inicio']),
        periodoFim: _dataHora(j['periodo_fim']),
        importadoEm: _dataHora(j['importado_em']),
      );
}

/// Resultado de um envio de arquivos (POST /importacoes).
class ResultadoImportacao {
  const ResultadoImportacao({
    required this.status,
    required this.arquivos,
    required this.totalRegistros,
    required this.importados,
    required this.rejeitados,
    required this.inseridos,
    required this.atualizados,
    this.periodoInicio,
    this.periodoFim,
    this.relatorios = const [],
  });

  final String status;
  final int arquivos;
  final int totalRegistros;
  final int importados;
  final int rejeitados;
  final int inseridos;
  final int atualizados;
  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final List<Importacao> relatorios;

  factory ResultadoImportacao.fromJson(Map<String, dynamic> j) => ResultadoImportacao(
        status: j['status'] as String,
        arquivos: j['arquivos'] as int,
        totalRegistros: (j['total_registros'] as int?) ?? 0,
        importados: (j['importados'] as int?) ?? 0,
        rejeitados: (j['rejeitados'] as int?) ?? 0,
        inseridos: (j['inseridos'] as int?) ?? 0,
        atualizados: (j['atualizados'] as int?) ?? 0,
        periodoInicio: _dataHora(j['periodo_inicio']),
        periodoFim: _dataHora(j['periodo_fim']),
        relatorios: ((j['relatorios'] as List?) ?? const []).map((e) => Importacao.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Arquivo escolhido pelo gestor para importar.
class ArquivoEnvio {
  const ArquivoEnvio({required this.nome, required this.bytes});
  final String nome;
  final List<int> bytes;
}
