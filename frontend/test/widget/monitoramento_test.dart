// testes de widget da tela Monitoramento (US14), do menu retrátil, do modo escuro e dos ajustes de leitura (US06)
import 'package:dashmob/core/periodo.dart';
import 'package:dashmob/core/tema.dart';
import 'package:dashmob/core/tema_controle.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/login/login_page.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:dashmob/features/painel/widgets/cartao.dart';
import 'package:dashmob/features/painel/widgets/grafico_colunas.dart';
import 'package:dashmob/features/painel/widgets/menu_lateral.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));
  tearDown(() => Cores.aplicar(ThemeMode.light));

  testWidgets('US14 Monitoramento mostra os seis números grandes numa tela só', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comAnterior), tela: Tela.monitoramento));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-monitoramento')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Quilometragem'))).data, '1.250');
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Viagens realizadas'))).data, '100');
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Cumprimento de viagens'))).data, '98,0');
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Passageiros'))).data, '1.500');
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Gratuidades'))).data, '20,0');
    expect(tester.widget<Text>(find.byKey(const Key('monitor-Viagens não realizadas'))).data, '2');
    expect(find.text('▲ 25,0% vs. período anterior'), findsOneWidget); // km 1.000 -> 1.250
    expect(find.byKey(const Key('monitor-ok')), findsOneWidget);
    expect(find.byKey(const Key('monitor-piores')), findsOneWidget);
    expect(find.textContaining('atualizado às'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing); // no desktop cabe na tela, sem rolagem
    expect(tester.takeException(), isNull);
  });

  testWidgets('RN06 Monitoramento sem dados não mostra zero', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(Indicadores.vazio), tela: Tela.monitoramento));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-sem-dados')), findsOneWidget);
    expect(find.byKey(const Key('monitor-Quilometragem')), findsNothing);
  });

  testWidgets('US14 o executivo também vê o Monitoramento no menu', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: executivo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-monitoramento')), findsOneWidget);
    expect(Tela.monitoramento.permitidaPara(Papel.executivo), isTrue);
  });

  testWidgets('US06 Monitoramento em tela de celular rola e não estoura', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comAnterior), tela: Tela.monitoramento));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monitor-Quilometragem')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('US06 o menu fica recolhido e abre quando o mouse passa por cima', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), menuRetratil: true));
    await tester.pumpAndSettle();
    expect(find.byType(MenuRetratil), findsOneWidget);
    expect(tester.widget<MenuLateral>(find.byType(MenuLateral)).compacto, isTrue);
    expect(find.byKey(const Key('menu-usuario-nome')), findsNothing); // só ícones
    expect(find.byKey(const Key('menu-passageiros')), findsOneWidget); // mas os ícones já navegam

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('menu-passageiros'))));
    await tester.pumpAndSettle();
    expect(tester.widget<MenuLateral>(find.byType(MenuLateral)).compacto, isFalse);
    expect(find.byKey(const Key('menu-usuario-nome')), findsOneWidget);
    expect(tester.getSize(find.byType(MenuLateral)).width, larguraMenuAberto);

    await mouse.moveTo(const Offset(900, 500));
    await tester.pumpAndSettle();
    expect(tester.widget<MenuLateral>(find.byType(MenuLateral)).compacto, isTrue);
    expect(tester.getSize(find.byType(MenuLateral)).width, larguraMenuRecolhido);
  });

  testWidgets('US06 o botão do menu alterna o modo escuro e os cartões trocam de cor', (tester) async {
    janela(tester, 1400);
    final tema = ControleTema(persistir: false);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: tema,
      builder: (context, modo, _) => app(RepositorioFalso(comDados), tema: tema),
    ));
    await tester.pumpAndSettle();
    Color corDoCartao() => (tester.widget<Container>(find.descendant(of: find.byType(Cartao).first, matching: find.byType(Container)).first).decoration! as BoxDecoration).color!;
    expect(Cores.paleta.escura, isFalse);
    expect(corDoCartao(), Paleta.clara.superficie);

    await tester.tap(find.byKey(const Key('menu-tema')));
    await tester.pumpAndSettle();
    expect(tema.escuro, isTrue);
    expect(Theme.of(tester.element(find.byType(Cartao).first)).brightness, Brightness.dark);
    expect(corDoCartao(), Paleta.escuro.superficie);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('menu-tema')));
    await tester.pumpAndSettle();
    expect(tema.escuro, isFalse);
    expect(corDoCartao(), Paleta.clara.superficie);
  });

  testWidgets('US06 o modo escuro também dá para ligar na tela de login', (tester) async {
    janela(tester, 1400);
    final tema = ControleTema(persistir: false);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: tema,
      builder: (context, modo, _) => MaterialApp(
        theme: temaDashMob(),
        darkTheme: temaDashMobEscuro(),
        themeMode: modo,
        home: LoginPage(repository: AuthFalso(), onEntrou: (_) {}, tema: tema),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-tema')));
    await tester.pumpAndSettle();
    expect(tema.escuro, isTrue);
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
  });

  test('RN08 pisoDoEixo começa logo abaixo dos valores, para a variação dos décimos aparecer', () {
    expect(pisoDoEixo([99.66, 99.72, 99.92]), 99.0); // variação de 0,26 ponto -> folga de 0,26, passo 0,5
    expect(pisoDoEixo([98.2, 97.5, 99.1]), 95);
    expect(pisoDoEixo([82.0, 99.0]), 65);
    expect(pisoDoEixo([12.0, 50.0]), 0); // não fica negativo
    expect(pisoDoEixo([3.0]), 2.5);
    expect(pisoDoEixo([0, 0]), 0); // períodos sem dado não contam
    expect(pisoDoEixo([]), 0);
  });

  testWidgets('RN08 o gráfico de cumprimento vai de 0 a 100% por padrão e aproxima a escala no botão', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.cumprimento));
    await tester.pumpAndSettle();
    expect(find.textContaining('eixo de 0 a 100%'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('fcv-aproximar')));
    await tester.tap(find.byKey(const Key('fcv-aproximar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('eixo a partir de 97,5%'), findsOneWidget); // FCV de 98,04% -> piso 97,5
  });

  testWidgets('US05 a granularidade saiu da barra e fica em cima dos gráficos, que são o que ela muda', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados);
    await tester.pumpWidget(app(repo, tela: Tela.cumprimento));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seletor-granularidade')), findsOneWidget);
    expect(find.text('Evolução no período'), findsOneWidget);
    await tester.ensureVisible(find.text('Mensal'));
    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();
    expect(repo.ultimaGranularidade, Granularidade.mes);
  });
}
