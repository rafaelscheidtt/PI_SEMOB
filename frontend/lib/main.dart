import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/sessao.dart';
import 'core/tema.dart';
import 'core/tema_controle.dart';
import 'data/auth_repository.dart';
import 'data/indicadores_repository.dart';
import 'data/models.dart';
import 'features/login/login_page.dart';
import 'features/painel/painel_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final sessao = SessaoAtual();
  final dio = criarDio(sessao);
  final tema = ControleTema();
  await tema.carregar();
  runApp(DashMobApp(
    sessao: sessao,
    armazenamento: ArmazenamentoLocal(),
    auth: AuthRepositoryHttp(dio),
    repository: IndicadoresRepositoryHttp(dio: dio),
    tema: tema,
  ));
}

class DashMobApp extends StatelessWidget {
  const DashMobApp({super.key, required this.sessao, required this.armazenamento, required this.auth, required this.repository, required this.tema});

  final SessaoAtual sessao;
  final ArmazenamentoSessao armazenamento;
  final AuthRepository auth;
  final IndicadoresRepository repository;
  final ControleTema tema;

  @override
  Widget build(BuildContext context) {
    // ao trocar o modo, o app inteiro é reconstruído com a paleta nova (claro/escuro)
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: tema,
      builder: (context, modo, _) => MaterialApp(
        title: 'DashMOB',
        debugShowCheckedModeBanner: false,
        theme: temaDashMob(),
        darkTheme: temaDashMobEscuro(),
        themeMode: modo,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AppRaiz(sessao: sessao, armazenamento: armazenamento, auth: auth, repository: repository, tema: tema),
      ),
    );
  }
}

/// Decide entre a tela de login e o painel (US11): tenta a sessão guardada, senão pede login;
/// quando a API responde 401 (token vencido ou usuário desativado) volta para o login.
class AppRaiz extends StatefulWidget {
  const AppRaiz({super.key, required this.sessao, required this.armazenamento, required this.auth, required this.repository, this.tema, this.menuRetratil = true});

  final SessaoAtual sessao;
  final ArmazenamentoSessao armazenamento;
  final AuthRepository auth;
  final IndicadoresRepository repository;

  /// Modo claro/escuro; sem ele o botão de alternar não aparece.
  final ControleTema? tema;

  /// Menu lateral recolhido que abre ao passar o mouse (desligado nos testes).
  final bool menuRetratil;

  @override
  State<AppRaiz> createState() => _AppRaizState();
}

class _AppRaizState extends State<AppRaiz> {
  Usuario? _usuario;
  bool _conferindo = true;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    widget.sessao.aoExpirar = () => _sair(aviso: 'Sua sessão expirou. Entre de novo.');
    _retomarSessao();
  }

  Future<void> _retomarSessao() async {
    final token = await widget.armazenamento.ler();
    if (token != null) {
      widget.sessao.token = token;
      try {
        final u = await widget.auth.quemSou();
        if (mounted) setState(() => _usuario = u);
      } catch (_) {
        widget.sessao.token = null;
        await widget.armazenamento.gravar(null);
      }
    }
    if (mounted) setState(() => _conferindo = false);
  }

  Future<void> _entrou(Sessao s) async {
    widget.sessao.token = s.token;
    await widget.armazenamento.gravar(s.token);
    if (mounted) {
      setState(() {
        _usuario = s.usuario;
        _aviso = null;
      });
    }
  }

  Future<void> _sair({String? aviso}) async {
    widget.sessao.token = null;
    await widget.armazenamento.gravar(null);
    if (mounted) {
      setState(() {
        _usuario = null;
        _aviso = aviso;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_conferindo) {
      return const Scaffold(backgroundColor: Cores.navy, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    final u = _usuario;
    if (u == null) return LoginPage(repository: widget.auth, onEntrou: _entrou, aviso: _aviso, tema: widget.tema);
    return PainelShell(
      key: ValueKey('painel-${u.id}'),
      repository: widget.repository,
      authRepository: widget.auth,
      usuario: u,
      onSair: _sair,
      tema: widget.tema,
      menuRetratil: widget.menuRetratil,
    );
  }
}
