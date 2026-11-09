import 'package:flutter/material.dart';

import '../../core/filtros.dart';
import '../../core/layout.dart';
import '../../core/periodo.dart';
import '../../core/tema.dart';
import '../../core/tema_controle.dart';
import '../../data/auth_repository.dart';
import '../../data/indicadores_repository.dart';
import '../../data/models.dart';
import '../usuarios/usuarios_page.dart';
import 'paginas/cumprimento_page.dart';
import 'paginas/em_construcao_page.dart';
import 'paginas/importacao_page.dart';
import 'paginas/linhas_page.dart';
import 'paginas/monitoramento_page.dart';
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
    this.tema,
    this.menuRetratil = true,
    this.intervaloMonitoramento = const Duration(minutes: 5),
  });

  final IndicadoresRepository repository;
  final Usuario usuario;
  final VoidCallback onSair;

  /// Só o administrador precisa dele (tela Usuários).
  final AuthRepository? authRepository;
  final FiltrosPainel? filtrosIniciais;
  final Tela telaInicial;

  /// Modo claro/escuro (botão no rodapé do menu); sem ele o botão não aparece.
  final ControleTema? tema;

  /// Menu recolhido que abre ao passar o mouse (desktop). Desligado nos testes, que tocam direto nos itens.
  final bool menuRetratil;

  /// Intervalo de atualização automática da tela Monitoramento (`null` desliga, usado nos testes).
  final Duration? intervaloMonitoramento;

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

  void _trocarGranularidade(Granularidade g) => setState(() => _filtros = _filtros.copyWith(granularidade: g));

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
          onGranularidade: _trocarGranularidade,
        );
      case Tela.monitoramento:
        return MonitoramentoPage(key: const ValueKey('tela-monitoramento'), filtros: _filtros, repository: widget.repository, intervaloAtualizacao: widget.intervaloMonitoramento);
      case Tela.cumprimento:
        return CumprimentoPage(key: const ValueKey('tela-cumprimento'), filtros: _filtros, repository: widget.repository, onGranularidade: _trocarGranularidade);
      case Tela.passageiros:
        return PassageirosPage(key: const ValueKey('tela-passageiros'), filtros: _filtros, repository: widget.repository, onGranularidade: _trocarGranularidade);
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
      void selecionar(Tela t) {
        _irPara(t);
        if (faixa != FaixaLargura.expandido) Navigator.of(context).maybePop();
      }

      final menu = faixa == FaixaLargura.expandido && widget.menuRetratil
          ? MenuRetratil(selecionada: _tela, usuario: widget.usuario, onSair: widget.onSair, onSelecionar: selecionar, tema: widget.tema)
          : MenuLateral(selecionada: _tela, usuario: widget.usuario, onSair: widget.onSair, onSelecionar: selecionar, tema: widget.tema);
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
