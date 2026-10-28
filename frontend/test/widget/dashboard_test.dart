// testes de widget do painel usando um repositório falso
import 'package:dashmob/core/periodo.dart';
import 'package:dashmob/data/indicadores_repository.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class RepositorioFalso implements IndicadoresRepository {
  RepositorioFalso(this.resposta);
  final Indicadores resposta;
  Granularidade? ultimaGranularidade;
  String? ultimaLinha;

  @override
  Future<Indicadores> obter({required DateTime inicio, required DateTime fim, required Granularidade granularidade, String? linha, bool comparar = false}) async {
    ultimaGranularidade = granularidade;
    ultimaLinha = linha;
    return resposta;
  }

  @override
  Future<List<Linha>> linhas() async => const [Linha(codigo: '01', nome: 'B. Santa Maria'), Linha(codigo: '02', nome: 'Circular Gerty')];

  @override
  Future<List<ResumoLinha>> resumoPorLinha({required DateTime inicio, required DateTime fim}) async => const [];

  @override
  Future<List<Ocorrencia>> ocorrencias({required DateTime inicio, required DateTime fim, String? linha, TipoOcorrencia? tipo}) async => const [];

  @override
  Future<DetalhesOperacao> detalhes({required DateTime inicio, required DateTime fim, String? linha}) async => DetalhesOperacao.vazio;

  @override
  Future<List<Importacao>> importacoes() async => const [];

  @override
  Future<ResultadoImportacao> importar(List<ArquivoEnvio> arquivos) async => throw UnimplementedError();
}

const _comDados = Indicadores(
  semDados: false,
  serie: [
    PontoIndicador(periodo: '2026-09-15', kmTotal: 1200.5, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1),
  ],
  totais: Totais(kmTotal: 1200.5, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1),
);

const _porLinha = Indicadores(
  semDados: false,
  serie: [PontoIndicador(periodo: '2026-09-15', kmTotal: 400.0, viagens: 40, diasComDados: 1)],
  totais: Totais(kmTotal: 400.0, viagens: 40, diasComDados: 1),
);

Widget _app(IndicadoresRepository repo, {double largura = 1280}) => MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: MediaQuery(
        data: MediaQueryData(size: Size(largura, 900)),
        child: DashboardPage(repository: repo, inicioInicial: DateTime(2026, 9, 1), fimInicial: DateTime(2026, 9, 30)),
      ),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US04 exibe pagantes, não pagantes e total', (tester) async {
    await tester.pumpWidget(_app(RepositorioFalso(_comDados)));
    await tester.pumpAndSettle();
    String valor(String titulo) => tester.widget<Text>(find.byKey(Key('kpi-$titulo'))).data!;
    expect(valor('Passageiros pagantes'), '1.200');
    expect(valor('Gratuidades'), '300');
    expect(valor('Passageiros no total'), '1.500'); // RN02
  });

  testWidgets('RN06 período sem dados exibe "Sem dados" e nenhum zero', (tester) async {
    await tester.pumpWidget(_app(RepositorioFalso(Indicadores.vazio)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-sem-dados')), findsOneWidget);
    expect(find.text('Sem dados'), findsNWidgets(7));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('US05 trocar a granularidade reconsulta a API', (tester) async {
    final repo = RepositorioFalso(_comDados);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();
    expect(repo.ultimaGranularidade, Granularidade.semana);
  });

  testWidgets('US05 selecionar uma linha envia o filtro', (tester) async {
    final repo = RepositorioFalso(_comDados);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seletor-linha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 — Circular Gerty').last);
    await tester.pumpAndSettle();
    expect(repo.ultimaLinha, '02');
  });

  testWidgets('US04 consulta por linha mostra "Sem dados" nos passageiros e explica o motivo', (tester) async {
    final repo = RepositorioFalso(_porLinha);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seletor-linha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 — Circular Gerty').last);
    await tester.pumpAndSettle();
    expect(find.text('400,0'), findsOneWidget);
    expect(find.byKey(const Key('aviso-passageiros-linha')), findsOneWidget);
    expect(find.text('Sem dados'), findsNWidgets(5)); // FCV, pagantes, gratuidades, total, média
  });

  testWidgets('RN08 exibe o cumprimento de viagens em percentual', (tester) async {
    await tester.pumpWidget(_app(RepositorioFalso(_comDados)));
    await tester.pumpAndSettle();
    expect(find.text('98,04%'), findsOneWidget);
    expect(find.text('102 programadas'), findsOneWidget);
  });

  testWidgets('US06 em tela compacta os filtros empilham em coluna', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(RepositorioFalso(_comDados), largura: 400));
    await tester.pumpAndSettle();
    expect(find.byType(Wrap), findsNothing);
  });
}
