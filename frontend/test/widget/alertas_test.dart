// testes de widget da tela Alertas e do destaque na Visão Geral (US08)
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US08 Alertas lista os dias fora do padrão com gravidade, tipo e linha', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.alertas));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-alertas')), findsOneWidget);
    expect(kpi(tester, 'Críticos'), '1');
    expect(kpi(tester, 'Avisos'), '2');
    expect(kpi(tester, 'Dias fora do padrão'), '2');
    expect(find.byKey(const Key('alerta-2026-09-08-fcv')), findsOneWidget);
    expect(find.byKey(const Key('alerta-2026-09-05-ocorrencias')), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.text('Padrão histórico'), findsOneWidget);
    expect(find.text('Linha 02'), findsOneWidget);
    expect(find.textContaining('08/09/2026'), findsOneWidget);
  });

  testWidgets('US08 o filtro de gravidade esconde os outros alertas', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.alertas));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Críticos').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alerta-2026-09-08-fcv')), findsOneWidget);
    expect(find.byKey(const Key('alerta-2026-09-08-km_total')), findsNothing);
    expect(find.byKey(const Key('alerta-2026-09-05-ocorrencias')), findsNothing);
  });

  testWidgets('US08 período dentro do padrão mostra a mensagem positiva', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados, respostaAlertas: Alertas.vazio), tela: Tela.alertas));
    await tester.pumpAndSettle();
    expect(kpi(tester, 'Críticos'), '0');
    expect(find.text('Nenhum alerta no período: a operação ficou dentro do padrão'), findsOneWidget);
    expect(find.byKey(const Key('alertas-filtro')), findsNothing);
  });

  testWidgets('US08 a Visão Geral destaca os alertas e o botão leva à tela', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo, filtros: filtrosPadrao.copyWith(linha: '02')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('faixa-alertas'))).data, '3 alertas no período (1 crítico) · 2 dias fora do padrão');
    expect(repo.ultimaLinhaAlertas, '02'); // o destaque respeita o filtro de linha
    await tester.tap(find.byKey(const Key('faixa-alertas-ver')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-alertas')), findsOneWidget);
  });

  testWidgets('US08 sem alertas a Visão Geral não mostra a faixa', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados, respostaAlertas: Alertas.vazio)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('faixa-alertas')), findsNothing);
  });

  testWidgets('US06 Alertas em tela de celular empilha as etiquetas sem estourar', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.alertas));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alerta-2026-09-08-fcv')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
