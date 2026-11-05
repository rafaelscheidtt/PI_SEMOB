import 'package:flutter/material.dart';

import '../../core/filtros.dart';
import '../../core/layout.dart';
import '../../core/tema.dart';
import '../../data/auth_repository.dart';
import '../../data/indicadores_repository.dart';
import '../../data/models.dart';
import '../usuarios/usuarios_page.dart';
import 'paginas/cumprimento_page.dart';
import 'paginas/em_construcao_page.dart';
import 'paginas/importacao_page.dart';
import 'paginas/linhas_page.dart';
import 'paginas/passageiros_page.dart';
import 'paginas/visao_geral_page.dart';
import 'telas.dart';
import 'widgets/barra_filtros.dart';
import 'widgets/menu_lateral.dart';

/// Casca do painel: menu lateral, barra de filtros e a tela selecionada (US05, US06).
/// Os filtros são um só para todas as telas, como no protótipo. O menu e as telas
/// disponíveis dependem do papel do [usuario] logado (US11).
class PainelShell extends StatefulWidget {
  const PainelShell({
    super.key,
    required this.repository,
    required this.usuario,
    required this.onSair,
    this.authRepository,
    this.filtrosIniciais,
    this.telaInicial = Tela.visaoGeral,
  });

  final IndicadoresRepository repository;
  final Usuario usuario;
  final VoidCallback onSair;

  /// Só o administrador precisa dele (tela Usuários).
  final AuthRepository? authRepository;
  final FiltrosPainel? filtrosIniciais;
  final Tela telaInicial;

  @override
  State<PainelShell> createState() => _PainelShellState();
}

class _PainelShellState extends State<PainelShell> {
  late FiltrosPainel _filtros;
  late Tela _tela;
  List<Linha> _linhas = const [];

  /// Linha aberta na tela de linhas (vinda da tabela de monitoramento ou da própria lista).
  String? _linhaAberta;

  @override
  void initState() {
    super.initState();
    _filtros = widget.filtrosIniciais ?? FiltrosPainel.padrao();
    _tela = widget.telaInicial.permitidaPara(widget.usuario.papel) ? widget.telaInicial : Tela.visaoGeral;
    _carregarLinhas();
  }

  Future<void> _carregarLinhas() async {
    try {
      final l = await widget.repository.linhas();
      if (mounted) setState(() => _linhas = l);
    } catch (_) {
      // sem a lista de linhas o painel continua funcionando com "Todas as linhas"
    }
  }

  void _irPara(Tela t, {String? linha}) {
    if (!t.disponivel || !t.permitidaPara(widget.usuario.papel)) return;
    setState(() {
      _tela = t;
      _linhaAberta = linha;
    });
  }

  Widget _conteudo() {
    switch (_tela) {
      case Tela.visaoGeral:
        return VisaoGeralPage(
          key: const ValueKey('tela-visaoGeral'),
          filtros: _filtros,
          repository: widget.repository,
          onAbrirLinha: (codigo) => _irPara(Tela.linhas, linha: codigo),
        );
      case Tela.cumprimento:
        return CumprimentoPage(key: const ValueKey('tela-cumprimento'), filtros: _filtros, repository: widget.repository);
      case Tela.passageiros:
        return PassageirosPage(key: const ValueKey('tela-passageiros'), filtros: _filtros, repository: widget.repository);
      case Tela.linhas:
        return LinhasPage(
          key: const ValueKey('tela-linhas'),
          filtros: _filtros,
          repository: widget.repository,
          linhaAberta: _linhaAberta,
          onAbrirLinha: (codigo) => setState(() => _linhaAberta = codigo),
          onVoltar: () => setState(() {
            _linhaAberta = null;
            _filtros = _filtros.copyWith(limparLinha: true);
          }),
        );
      case Tela.importacao:
        return ImportacaoPage(key: const ValueKey('tela-importacao'), repository: widget.repository);
      case Tela.usuarios:
        return UsuariosPage(key: const ValueKey('tela-usuarios'), repository: widget.authRepository!, usuarioLogado: widget.usuario);
      case Tela.financeiro:
      case Tela.alertas:
      case Tela.relatorios:
        return EmConstrucaoPage(key: ValueKey('tela-${_tela.name}'), tela: _tela);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      final menu = MenuLateral(
        selecionada: _tela,
        usuario: widget.usuario,
        onSair: widget.onSair,
        onSelecionar: (t) {
          _irPara(t);
          if (faixa != FaixaLargura.expandido) Navigator.of(context).maybePop();
        },
      );
      final barra = BarraFiltros(
        filtros: _filtros,
        linhas: _linhas,
        compacto: faixa == FaixaLargura.compacto,
        onFiltros: (f) => setState(() => _filtros = f),
      );
      final corpo = Column(children: [if (_tela != Tela.usuarios) barra, Expanded(child: _conteudo())]);

      if (faixa == FaixaLargura.expandido) {
        return Scaffold(body: Row(children: [menu, Expanded(child: corpo)]));
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Cores.navy,
          foregroundColor: Colors.white,
          title: Text(_tela.rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        drawer: Drawer(backgroundColor: Cores.navy, width: 272, child: SafeArea(child: menu)),
        body: corpo,
      );
    });
  }
}
