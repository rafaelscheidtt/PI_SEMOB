// testes de widget do termo de uso (LGPD) e da tela Sobre
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

const _novato = Usuario(id: 'u9', nome: 'Nina Novata', email: 'nina@semob.teste', papel: Papel.gestor, termoPendente: true);

Future<void> _logar(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-senha')), 'senha123');
  await tester.tap(find.byKey(const Key('login-entrar')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('LGPD quem ainda não aceitou o termo só entra no painel depois de aceitar', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso(usuarios: const [admin, _novato]);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await _logar(tester, 'nina@semob.teste');

    expect(find.byKey(const Key('tela-termo')), findsOneWidget);
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsNothing);
    expect(find.text('2. Dados pessoais tratados'), findsOneWidget);
    // sem marcar "li e estou de acordo" o botão não funciona
    expect(tester.widget<FilledButton>(find.byKey(const Key('termo-aceitar'))).onPressed, isNull);
    expect(auth.aceites, 0);

    await tester.tap(find.byKey(const Key('termo-li')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('termo-aceitar')));
    await tester.pumpAndSettle();
    expect(auth.aceites, 1);
    expect(find.byKey(const Key('tela-termo')), findsNothing);
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LGPD dá para sair sem aceitar, e erro no registro mantém a tela do termo', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso(usuarios: const [admin, _novato])..falharNoTermo = true;
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await _logar(tester, 'nina@semob.teste');
    await tester.tap(find.byKey(const Key('termo-li')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('termo-aceitar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
    expect(find.byKey(const Key('tela-termo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('termo-sair')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
  });

  testWidgets('LGPD quem já aceitou o termo entra direto no painel', (tester) async {
    janela(tester, 390);
    final auth = AuthFalso(usuarios: const [admin, gestor, _novato]);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await _logar(tester, 'gestor@semob.teste');
    expect(find.byKey(const Key('tela-termo')), findsNothing);
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LGPD o termo cabe na tela do celular', (tester) async {
    janela(tester, 390);
    final auth = AuthFalso(usuarios: const [admin, _novato]);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await _logar(tester, 'nina@semob.teste');
    expect(find.byKey(const Key('tela-termo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sobre explica os cálculos, os perfis e abre o termo para consulta', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-sobre')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-sobre')), findsOneWidget);
    expect(find.byKey(const Key('botao-intervalo')), findsNothing); // sem a barra de filtros
    expect(find.text('Como os indicadores são calculados'), findsOneWidget);
    expect(find.text('Perfis de acesso'), findsOneWidget);
    expect(find.text(Papel.executivo.descricao), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('sobre-termo')));
    await tester.tap(find.byKey(const Key('sobre-termo')));
    await tester.pumpAndSettle();
    expect(find.text('7. Seus direitos'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('7. Seus direitos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sobre abre para o executivo e cabe no celular; as telas não mostram códigos internos', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: executivo, tela: Tela.sobre));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-sobre')), findsOneWidget);
    expect(find.textContaining(RegExp(r'RN\d\d')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tela Usuários ficou só com a lista, sem a legenda dos perfis', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: admin, tela: Tela.usuarios));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('usuario-gestor@semob.teste')), findsOneWidget);
    expect(find.textContaining(Papel.gestor.descricao), findsNothing);
  });

  testWidgets('Passageiros, Cumprimento, Financeiro e Alertas não mostram códigos internos de requisito', (tester) async {
    janela(tester, 1400);
    for (final tela in [Tela.passageiros, Tela.cumprimento, Tela.financeiro, Tela.alertas]) {
      await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: app(RepositorioFalso(comDados), tela: tela)));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'RN\d\d')), findsNothing, reason: tela.name);
      expect(find.textContaining(RegExp(r'US\d\d')), findsNothing, reason: tela.name);
    }
  });
}
