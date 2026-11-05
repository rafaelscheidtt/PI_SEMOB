// tela de linhas: tabela de monitoramento, detalhamento e ocorrências (US05)
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('lista as linhas com os totais e abre o detalhamento ao clicar', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.linhas));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabela-linhas')), findsOneWidget);
    expect(find.text('Total · 2 linhas'), findsOneWidget);
    expect(find.text('1.200,5'), findsOneWidget); // km do sistema: 700 + 500,5

    await tester.ensureVisible(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    expect(find.text('Linha 02 — Circular Gerty'), findsOneWidget);
    expect(kpi(tester, 'Viagens realizadas'), '100');
    expect(kpi(tester, 'Participação na oferta'), '100,0%'); // 100 de 100 viagens do resumo
    expect(kpi(tester, 'Ocorrências'), '2');
    expect(find.byKey(const Key('tabela-ocorrencias')), findsOneWidget);
    expect(find.text('Não realizada'), findsOneWidget);
    expect(find.text('Não terminada'), findsOneWidget);
    expect(find.text('06:20 – 06:53'), findsOneWidget);
  });

  testWidgets('busca filtra a tabela e "Voltar às linhas" sai do detalhamento', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.linhas));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('busca-linha')), 'gerty');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('linha-02')), findsOneWidget);
    expect(find.byKey(const Key('linha-01')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-voltar-linhas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabela-linhas')), findsOneWidget);
  });

  testWidgets('a linha escolhida na barra de filtros abre direto no detalhamento', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(porLinha);
    await tester.pumpWidget(app(repo, tela: Tela.linhas));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seletor-linha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 — Circular Gerty').last);
    await tester.pumpAndSettle();
    expect(find.text('Linha 02 — Circular Gerty'), findsOneWidget);
    expect(repo.ultimaLinha, '02');
    expect(kpi(tester, 'Quilometragem'), '400');
  });
}
