// apoio dos testes de widget: repositório falso, dados de exemplo e a montagem do app
import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/core/periodo.dart';
import 'package:dashmob/data/indicadores_repository.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/painel_shell.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class RepositorioFalso implements IndicadoresRepository {
  RepositorioFalso(this.resposta);
  final Indicadores resposta;
  Granularidade? ultimaGranularidade;
  String? ultimaLinha;
  bool? ultimoComparar;
  int consultas = 0;

  @override
  Future<Indicadores> obter({required DateTime inicio, required DateTime fim, required Granularidade granularidade, String? linha, bool comparar = false}) async {
    consultas++;
    ultimaGranularidade = granularidade;
    ultimaLinha = linha;
    ultimoComparar = comparar;
    return resposta;
  }

  @override
  Future<List<Linha>> linhas() async => const [Linha(codigo: '01', nome: 'B. Santa Maria'), Linha(codigo: '02', nome: 'Circular Gerty')];

  @override
  Future<List<ResumoLinha>> resumoPorLinha({required DateTime inicio, required DateTime fim}) async => const [
        ResumoLinha(codigo: '01', nome: 'B. Santa Maria', kmTotal: 700, viagens: 60, diasComDados: 1, naoRealizadas: 2),
        ResumoLinha(codigo: '02', nome: 'Circular Gerty', kmTotal: 500.5, viagens: 40, diasComDados: 1, naoIniciadas: 1),
      ];

  @override
  Future<List<Ocorrencia>> ocorrencias({required DateTime inicio, required DateTime fim, String? linha, TipoOcorrencia? tipo}) async => linha != '02'
      ? const []
      : [
          Ocorrencia(tipo: TipoOcorrencia.naoRealizada, data: DateTime(2026, 9, 3), linha: '02', atendimento: 'Circular Gerty Sentido Ida', sentido: 'I', tabela: '3A', inicioProgramado: DateTime(2026, 9, 3, 6, 20), fimProgramado: DateTime(2026, 9, 3, 6, 53)),
          Ocorrencia(tipo: TipoOcorrencia.naoTerminada, data: DateTime(2026, 9, 7), linha: '02', atendimento: 'Circular Gerty Sentido Volta', sentido: 'V', tabela: '7B', inicioProgramado: DateTime(2026, 9, 7, 22, 0), inicioRealizado: DateTime(2026, 9, 7, 22, 1)),
        ];

  @override
  Future<DetalhesOperacao> detalhes({required DateTime inicio, required DateTime fim, String? linha}) async => DetalhesOperacao(
        linha: linha,
        turnos: linha != null ? const [] : const [Turno(turno: 'manha', programadas: 50, realizadas: 49, fcv: 98), Turno(turno: 'tarde', programadas: 52, realizadas: 51, fcv: 98.08)],
        faixasHorarias: const [FaixaHoraria(faixa: 5, viagens: 10), FaixaHoraria(faixa: 6, viagens: 30), FaixaHoraria(faixa: 7, viagens: 20)],
      );

  @override
  Future<List<Importacao>> importacoes() async => const [];

  @override
  Future<ResultadoImportacao> importar(List<ArquivoEnvio> arquivos) async => throw UnimplementedError();
}

const comDados = Indicadores(
  semDados: false,
  serie: [
    PontoIndicador(periodo: '2026-09-15', kmTotal: 1250.0, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1, diasComPassageiros: 1),
  ],
  totais: Totais(kmTotal: 1250.0, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1, diasComPassageiros: 1),
);

final comAnterior = Indicadores(
  semDados: false,
  serie: comDados.serie,
  totais: comDados.totais,
  anterior: PeriodoAnterior(
    inicio: DateTime(2026, 8, 2),
    fim: DateTime(2026, 8, 31),
    totais: const Totais(kmTotal: 1000.0, viagens: 125, viagensProgramadas: 130, fcv: 96.15, pagantes: 1000, naoPagantes: 250, total: 1250, mediaPorViagem: 10, diasComDados: 1, diasComPassageiros: 1),
  ),
);

const porLinha = Indicadores(
  semDados: false,
  serie: [PontoIndicador(periodo: '2026-09-15', kmTotal: 400.0, viagens: 40, diasComDados: 1)],
  totais: Totais(kmTotal: 400.0, viagens: 40, diasComDados: 1),
);

final filtrosPadrao = FiltrosPainel(inicio: DateTime(2026, 9, 1), fim: DateTime(2026, 9, 30));

Widget app(IndicadoresRepository repo, {FiltrosPainel? filtros, Tela tela = Tela.visaoGeral}) => MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: PainelShell(repository: repo, filtrosIniciais: filtros ?? filtrosPadrao, telaInicial: tela),
    );

/// Define a largura da janela de teste (o layout usa LayoutBuilder, então MediaQuery não basta).
void janela(WidgetTester tester, double largura) {
  tester.view.physicalSize = Size(largura, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String kpi(WidgetTester tester, String titulo) => tester.widget<Text>(find.byKey(Key('kpi-$titulo'))).data!;
