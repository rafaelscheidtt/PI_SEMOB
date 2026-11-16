// testes de widget do "Meu perfil": nome, foto e senha do próprio usuário (US13)
import 'package:dashmob/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

Future<void> _entrarComoGestor(WidgetTester tester, AuthFalso auth) async {
  await tester.pumpWidget(appCompleto(RepositorioFalso(comDados), auth));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('login-email')), 'gestor@semob.teste');
  await tester.enterText(find.byKey(const Key('login-senha')), 'senha123');
  await tester.tap(find.byKey(const Key('login-entrar')));
  await tester.pumpAndSettle();
}

Future<void> _abrirPerfil(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('menu-perfil')));
  await tester.pumpAndSettle();
  expect(find.text('Meu perfil'), findsOneWidget);
}

Future<void> _salvar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('perfil-salvar')));
  await tester.tap(find.byKey(const Key('perfil-salvar')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('US13 o usuário troca o próprio nome e o menu passa a mostrar o novo', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await _entrarComoGestor(tester, auth);
    expect(find.text('GG'), findsOneWidget); // sem foto, o avatar mostra as iniciais

    await _abrirPerfil(tester);
    expect(find.text('gestor@semob.teste'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('perfil-nome')), 'Gil Souza');
    await _salvar(tester);

    expect(find.text('Meu perfil'), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('menu-usuario-nome'))).data, 'Gil Souza');
    expect(find.text('GS'), findsOneWidget);
    expect(auth.perfilSalvo!.nome, 'Gil Souza');
    expect(auth.perfilSalvo!.foto, isNull); // a foto não foi mexida
    expect(auth.perfilSalvo!.novaSenha, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('US13 nome vazio não é salvo', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await _entrarComoGestor(tester, auth);
    await _abrirPerfil(tester);
    await tester.enterText(find.byKey(const Key('perfil-nome')), '   ');
    await _salvar(tester);
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(auth.perfilSalvo, isNull);
  });

  testWidgets('US13 trocar a senha pede a atual e a nova repetida', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso();
    await _entrarComoGestor(tester, auth);
    await _abrirPerfil(tester);

    // as duas senhas novas diferentes: nem chama a API
    await tester.enterText(find.byKey(const Key('perfil-senha-atual')), 'errada');
    await tester.enterText(find.byKey(const Key('perfil-nova-senha')), 'nova1234');
    await tester.enterText(find.byKey(const Key('perfil-confirmar-senha')), 'outra123');
    await _salvar(tester);
    expect(find.text('As senhas não são iguais'), findsOneWidget);
    expect(auth.perfilSalvo, isNull);

    // senha atual errada: a API recusa e o perfil continua aberto
    await tester.enterText(find.byKey(const Key('perfil-confirmar-senha')), 'nova1234');
    await _salvar(tester);
    expect(find.text('A senha atual não confere'), findsOneWidget);
    expect(find.text('Meu perfil'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('perfil-senha-atual')), 'senha123');
    await _salvar(tester);
    expect(find.text('Meu perfil'), findsNothing);
    expect(auth.perfilSalvo!.novaSenha, 'nova1234');
    expect(auth.perfilSalvo!.nome, isNull); // o nome não mudou
  });

  testWidgets('US13 o usuário escolhe, remove e salva a foto do perfil', (tester) async {
    janela(tester, 1400);
    final auth = AuthFalso()..logado = gestor;
    Usuario? salvo;
    await tester.pumpWidget(app(RepositorioFalso(comDados), auth: auth, escolherFoto: () async => fotoDeTeste, onUsuarioAtualizado: (u) => salvo = u));
    await tester.pumpAndSettle();
    await _abrirPerfil(tester);
    expect(find.byKey(const Key('avatar-foto')), findsNothing);
    expect(find.text('Escolher foto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('perfil-foto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar-foto')), findsOneWidget);
    expect(find.text('Trocar foto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('perfil-remover-foto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar-foto')), findsNothing);

    await tester.tap(find.byKey(const Key('perfil-foto')));
    await tester.pumpAndSettle();
    await _salvar(tester);
    expect(auth.perfilSalvo!.foto, fotoDeTeste);
    expect(salvo!.foto, fotoDeTeste);
    expect(salvo!.nome, 'Gil Gestor');
  });

  testWidgets('US13 quem já tem foto vê a foto no menu e consegue apagar', (tester) async {
    janela(tester, 1400);
    const comFoto = Usuario(id: 'u2', nome: 'Gil Gestor', email: 'gestor@semob.teste', papel: Papel.gestor, foto: fotoDeTeste);
    final auth = AuthFalso(usuarios: const [admin, comFoto, executivo])..logado = comFoto;
    Usuario? salvo;
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: comFoto, auth: auth, onUsuarioAtualizado: (u) => salvo = u));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('avatar-foto')), findsOneWidget); // no rodapé do menu
    expect(find.text('GG'), findsNothing);

    await _abrirPerfil(tester);
    await tester.tap(find.byKey(const Key('perfil-remover-foto')));
    await tester.pumpAndSettle();
    await _salvar(tester);
    expect(auth.perfilSalvo!.foto, ''); // texto vazio manda a API apagar
    expect(salvo!.foto, isNull);
  });

  testWidgets('US13 o perfil cabe na tela do celular', (tester) async {
    janela(tester, 390);
    final auth = AuthFalso()..logado = gestor;
    await tester.pumpWidget(app(RepositorioFalso(comDados), auth: auth));
    await tester.pumpAndSettle();
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pumpAndSettle();
    await _abrirPerfil(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('US13 a tela Usuários mostra a foto de quem tem e as iniciais de quem não tem', (tester) async {
    janela(tester, 1400);
    const comFoto = Usuario(id: 'u2', nome: 'Gil Gestor', email: 'gestor@semob.teste', papel: Papel.gestor, foto: fotoDeTeste);
    final auth = AuthFalso(usuarios: const [admin, comFoto, executivo]);
    await tester.pumpWidget(app(RepositorioFalso(comDados), usuario: admin, auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-usuarios')));
    await tester.pumpAndSettle();
    Finder naLinha(String email, Finder oQue) => find.descendant(of: find.byKey(Key('usuario-$email')), matching: oQue);
    expect(naLinha('gestor@semob.teste', find.byKey(const Key('avatar-foto'))), findsOneWidget);
    expect(naLinha('exec@semob.teste', find.byKey(const Key('avatar-foto'))), findsNothing);
    expect(naLinha('exec@semob.teste', find.text('EE')), findsOneWidget);
  });
}
