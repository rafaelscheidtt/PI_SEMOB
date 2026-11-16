// testes de widget da Visão executiva (US09)
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US09 a visão executiva resume o período com a variação e os alertas', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comAnterior), tela: Tela.executiva));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-executiva')), findsOneWidget);
    expect(kpi(tester, 'Quilometragem'), '1.250');
    expect(kpi(tester, 'Viagens realizadas'), '100');
    expect(kpi(tester, 'Cumprimento de viagens'), '98,04%');
    expect(kpi(tester, 'Passageiros'), '1.500');
    expect(kpi(tester, 'Vendas de créditos'), 'R\$ 72.448');
    expect(kpi(tester, 'Alertas críticos'), '1');
    expect(find.text('+25,0% vs. anterior'), findsOneWidget); // km 1.000 -> 1.250 no destaque
    expect(tester.widget<Text>(find.byKey(const Key('comparativo-Passageiros'))).data, '1.500');
    expect(find.textContaining('Cumprimento de 88,0%'), findsOneWidget); // ponto de atenção crítico
    expect(find.byKey(const Key('executiva-ver-alertas')), findsOneWidget);
  });

  testWidgets('US09 sem alertas críticos a visão executiva diz que está dentro do padrão', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados, respostaAlertas: Alertas.vazio), tela: Tela.executiva));
    await tester.pumpAndSettle();
    expect(kpi(tester, 'Alertas críticos'), '0');
    expect(find.byKey(const Key('executiva-sem-criticos')), findsOneWidget);
    expect(find.text('sem desvio grave'), findsOneWidget);
  });

  testWidgets('US09 o botão da visão executiva abre a tela de Alertas', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.executiva));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('executiva-ver-alertas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('executiva-ver-alertas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-alertas')), findsOneWidget);
  });

  testWidgets('US09 o executivo entra e cai direto na visão executiva', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login-email')), 'exec@semob.teste');
    await tester.enterText(find.byKey(const Key('login-senha')), 'senha123');
    await tester.tap(find.byKey(const Key('login-entrar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-executiva')), findsOneWidget);
    expect(find.byKey(const Key('menu-financeiro')), findsOneWidget);
    expect(find.byKey(const Key('menu-linhas')), findsNothing);
    expect(Tela.inicialPara(Papel.gestor), Tela.visaoGeral);
  });

  testWidgets('RN06 período sem dados na visão executiva', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(Indicadores.vazio), tela: Tela.executiva));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-sem-dados')), findsOneWidget);
    expect(find.byKey(const Key('kpi-Quilometragem')), findsNothing);
  });

  testWidgets('US06 visão executiva em tela de celular fica em uma coluna', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comAnterior), tela: Tela.executiva));
    await tester.pumpAndSettle();
    final grade = tester.widget<GridView>(find.byType(GridView).first).gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(grade.crossAxisCount, 1);
    expect(tester.takeException(), isNull);
  });
}
