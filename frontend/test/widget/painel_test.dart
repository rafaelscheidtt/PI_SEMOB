// testes de widget do painel (menu, filtros e telas) usando um repositório falso
import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/core/periodo.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US04 Visão Geral exibe passageiros e gratuidades; a tela de passageiros fecha o total (RN02)', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(kpi(tester, 'Passageiros'), '1.500');
    expect(kpi(tester, 'Gratuidades'), '300');
    expect(repo.ultimoComparar, isTrue);

    await tester.tap(find.byKey(const Key('menu-passageiros')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-passageiros')), findsOneWidget);
    expect(kpi(tester, 'Pagantes'), '1.200');
    expect(kpi(tester, 'Gratuidades'), '300');
    expect(kpi(tester, 'Passageiros no total'), '1.500');
    expect(kpi(tester, 'Média de passageiros por viagem'), '15,0'); // RN03
  });

  testWidgets('US02 compara com o período anterior quando a API devolve o anterior', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comAnterior)));
    await tester.pumpAndSettle();
    expect(find.text('+25,0% vs. anterior'), findsOneWidget); // km: 1.000 -> 1.250
    expect(find.text('−20,0% vs. anterior'), findsOneWidget); // viagens: 125 -> 100
    expect(find.text('+20,0% vs. anterior'), findsOneWidget); // passageiros: 1.250 -> 1.500
  });

  testWidgets('RN06 período sem dados exibe "Sem dados" e nenhum zero', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(Indicadores.vazio)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-sem-dados')), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.byKey(const Key('kpi-Quilometragem')), findsNothing);
  });

  testWidgets('US05 trocar a granularidade reconsulta a API', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();
    expect(repo.ultimaGranularidade, Granularidade.semana);
  });

  testWidgets('US05 selecionar uma linha envia o filtro e os passageiros ficam "Sem dados"', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(porLinha);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seletor-linha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 — Circular Gerty').last);
    await tester.pumpAndSettle();
    expect(repo.ultimaLinha, '02');
    expect(kpi(tester, 'Quilometragem'), '400');
    expect(kpi(tester, 'Passageiros'), 'Sem dados');
    expect(kpi(tester, 'Gratuidades'), 'Sem dados');
    expect(find.byKey(const Key('aviso-passageiros-linha')), findsOneWidget);
    expect(find.byKey(const Key('tabela-linhas')), findsNothing); // o monitoramento por linha só faz sentido no sistema inteiro
  });

  testWidgets('RN07 intervalo invertido mostra a mensagem e não consulta a API', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo, filtros: FiltrosPainel(inicio: DateTime(2026, 8, 20), fim: DateTime(2026, 8, 10))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
    expect(find.text(mensagemIntervaloInvalido), findsOneWidget);
    expect(repo.consultas, 0);
  });

  testWidgets('RN08 exibe o cumprimento de viagens em percentual na Visão Geral e na tela própria', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    expect(kpi(tester, 'FCV'), '98,04%');
    expect(find.text('102 programadas · FCV 98,04%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-cumprimento')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-cumprimento')), findsOneWidget);
    expect(kpi(tester, 'Cumprimento (FCV)'), '98,04%');
    expect(kpi(tester, 'Viagens não realizadas'), '2');
    expect(find.text('Manhã'), findsOneWidget);
  });

  testWidgets('US05 clicar em uma linha da tabela de monitoramento abre a tela de linhas', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabela-linhas')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-linhas')), findsOneWidget);
  });

  testWidgets('menu não abre as telas previstas para a Sprint 2', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-financeiro')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget);
    expect(find.text('Sprint 2'), findsNWidgets(3));
  });

  testWidgets('US06 tela expandida tem o menu fixo e quatro colunas de cartões', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    expect(find.byType(MenuLateral), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    final grade = tester.widget<GridView>(find.byType(GridView).first).gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(grade.crossAxisCount, 4);
  });

  testWidgets('US06 tela compacta: filtros empilhados, menu na gaveta e uma coluna de cartões', (tester) async {
    janela(tester, 400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(MenuLateral), findsNothing);
    final grade = tester.widget<GridView>(find.byType(GridView).first).gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(grade.crossAxisCount, 1);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(MenuLateral), findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-passageiros')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-passageiros')), findsOneWidget);
    expect(find.byType(MenuLateral), findsNothing);
  });
}
