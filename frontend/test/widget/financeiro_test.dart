// testes de widget da tela Financeiro (US07, RN06, RN12)
import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/core/formatos.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  test('fmtMoeda formata em reais no padrão brasileiro', () {
    expect(fmtMoeda(1234.5), 'R\$ 1.234,50');
    expect(fmtMoeda(32448, semCentavos: true), 'R\$ 32.448');
  });

  testWidgets('US07 Financeiro mostra vendas, utilização, crédito circulante e saldo com a variação', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo, tela: Tela.financeiro));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-financeiro')), findsOneWidget);
    expect(repo.consultasFinanceiro, 1);
    expect(kpi(tester, 'Vendas'), 'R\$ 72.448');
    expect(kpi(tester, 'Utilização'), 'R\$ 64.320');
    expect(kpi(tester, 'Crédito circulante'), 'R\$ 8.128'); // RN12 vendas − utilização
    expect(kpi(tester, 'Saldo de créditos'), 'R\$ 971.000');
    expect(find.textContaining('+20,7% vs.'), findsOneWidget); // vendas: 60.000 -> 72.448
    expect(find.text('mais vendido que usado'), findsOneWidget);
    expect(find.text('Vendas × Utilização por diária'), findsOneWidget);
    expect(find.byKey(const Key('aviso-tarifa-zero')), findsNothing); // o período começa depois da bilhetagem
  });

  testWidgets('US07 período que começa antes da bilhetagem explica o Tarifa Zero', (tester) async {
    janela(tester, 1400);
    final filtros = FiltrosPainel(inicio: DateTime(2026, 7, 1), fim: DateTime(2026, 7, 31));
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.financeiro, filtros: filtros));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-tarifa-zero')), findsOneWidget);
    expect(find.textContaining('15/07/2026'), findsOneWidget);
  });

  testWidgets('RN06 período sem bilhetagem mostra "Sem dados" e nenhum valor', (tester) async {
    janela(tester, 1400);
    final filtros = FiltrosPainel(inicio: DateTime(2026, 7, 1), fim: DateTime(2026, 7, 14));
    final repo = RepositorioFalso(comDados, respostaFinanceira: Financeiro(semDados: true, serie: const [], inicioBilhetagem: DateTime(2026, 7, 15)));
    await tester.pumpWidget(app(repo, tela: Tela.financeiro, filtros: filtros));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-sem-dados')), findsOneWidget);
    expect(find.byKey(const Key('aviso-tarifa-zero')), findsOneWidget);
    expect(find.byKey(const Key('kpi-Vendas')), findsNothing);
  });

  testWidgets('US07 filtro de linha avisa que o financeiro é do sistema inteiro', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.financeiro, filtros: filtrosPadrao.copyWith(linha: '02')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-financeiro-linha')), findsOneWidget);
    expect(kpi(tester, 'Vendas'), 'R\$ 72.448');
  });

  testWidgets('US07 Financeiro entra no menu e as outras telas de gestão seguem como Sprint 2', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-financeiro')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-financeiro')), findsOneWidget);
    expect(find.text('Sprint 2'), findsNWidgets(2));
  });

  testWidgets('US06 Financeiro em tela de celular fica em uma coluna', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.financeiro));
    await tester.pumpAndSettle();
    final grade = tester.widget<GridView>(find.byType(GridView).first).gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(grade.crossAxisCount, 1);
    expect(tester.takeException(), isNull);
  });
}
