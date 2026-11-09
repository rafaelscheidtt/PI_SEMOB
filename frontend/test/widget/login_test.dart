// testes de widget do login, dos papéis e do cadastro de usuários (US11, US13)
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

Future<void> _logar(WidgetTester tester, String email, String senha) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-senha')), senha);
  await tester.tap(find.byKey(const Key('login-entrar')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US11 sem sessão guardada o app abre na tela de login', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsNothing);
  });

  testWidgets('US11 senha errada mostra a mensagem e continua no login', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await _logar(tester, 'gestor@semob.teste', 'errada');
    expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
    expect(auth.logins, 1);
  });

  testWidgets('US11 campos vazios não chamam a API', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-entrar')));
    await tester.pumpAndSettle();
    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(auth.logins, 0);
  });

  testWidgets('US11 gestor entra, cai na Visão Geral e vê seu nome no menu; Sair volta ao login', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso()));
    await tester.pumpAndSettle();
    await _logar(tester, 'gestor@semob.teste', 'senha123');
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('menu-usuario-nome'))).data, 'Gil Gestor');
    expect(find.byKey(const Key('menu-importacao')), findsOneWidget);
    expect(find.byKey(const Key('menu-usuarios')), findsNothing); // só o administrador

    await tester.tap(find.byKey(const Key('menu-sair')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
  });

  testWidgets('US11 sessão guardada válida pula o login; inválida pede login', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso(sessaoGuardada: admin), tokenGuardado: 'token-u1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget);
    expect(find.byKey(const Key('menu-usuarios')), findsOneWidget);

    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso(), tokenGuardado: 'token-vencido'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
  });

  testWidgets('US11 executivo vê só a visão resumida: sem Linhas, Importação e Usuários', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: executivo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-visaoGeral')), findsOneWidget);
    expect(find.byKey(const Key('menu-cumprimento')), findsOneWidget);
    expect(find.byKey(const Key('menu-passageiros')), findsOneWidget);
    expect(find.byKey(const Key('menu-linhas')), findsNothing);
    expect(find.byKey(const Key('menu-importacao')), findsNothing);
    expect(find.byKey(const Key('menu-usuarios')), findsNothing);
    expect(find.byKey(const Key('menu-financeiro')), findsNothing);
    expect(Tela.permitidas(Papel.executivo), [Tela.visaoGeral, Tela.monitoramento, Tela.cumprimento, Tela.passageiros]);
  });

  testWidgets('US11 executivo não abre uma tela proibida nem pela tabela de linhas', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: executivo, tela: Tela.linhas));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-visaoGeral')), findsOneWidget); // tela inicial proibida cai na Visão Geral
    await tester.ensureVisible(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linha-02')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-linhas')), findsNothing);
  });

  testWidgets('US13 administrador cadastra um usuário pela tela Usuários', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: admin, auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-usuarios')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-usuarios')), findsOneWidget);
    expect(find.byKey(const Key('usuario-gestor@semob.teste')), findsOneWidget);
    expect(find.text('Ana Admin (você)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('usuarios-novo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('usuario-nome')), 'Novo Usuário');
    await tester.enterText(find.byKey(const Key('usuario-email')), 'novo@semob.teste');
    await tester.enterText(find.byKey(const Key('usuario-senha')), 'senha123');
    await tester.tap(find.byKey(const Key('usuario-salvar')));
    await tester.pumpAndSettle();
    expect(auth.lista.last.email, 'novo@semob.teste');
    expect(auth.lista.last.papel, Papel.gestor); // papel padrão do formulário
    expect(find.byKey(const Key('usuario-novo@semob.teste')), findsOneWidget);
  });

  testWidgets('US13 senha curta e e-mail repetido são barrados no cadastro', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: admin, auth: auth, tela: Tela.usuarios));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usuarios-novo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('usuario-nome')), 'Alguém');
    await tester.enterText(find.byKey(const Key('usuario-email')), 'gestor@semob.teste');
    await tester.enterText(find.byKey(const Key('usuario-senha')), '123');
    await tester.tap(find.byKey(const Key('usuario-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('Pelo menos 6 caracteres'), findsOneWidget);
    expect(auth.lista.length, 3);

    await tester.enterText(find.byKey(const Key('usuario-senha')), 'senha123');
    await tester.tap(find.byKey(const Key('usuario-salvar')));
    await tester.pumpAndSettle();
    expect(find.text('já existe um usuário com este e-mail'), findsOneWidget);
    expect(auth.lista.length, 3);
  });

  testWidgets('US13 administrador desativa um usuário', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: admin, auth: auth, tela: Tela.usuarios));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usuario-exec@semob.teste')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usuario-ativo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usuario-salvar')));
    await tester.pumpAndSettle();
    expect(auth.lista.firstWhere((u) => u.email == 'exec@semob.teste').ativo, isFalse);
    expect(find.text('Desativado'), findsOneWidget);
  });

  testWidgets('US06 login cabe numa tela de celular', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), AuthFalso()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
