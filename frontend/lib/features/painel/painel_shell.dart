import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/filtros.dart';
import '../../core/layout.dart';
import '../../core/periodo.dart';
import '../../core/tema.dart';
import '../../core/tema_controle.dart';
import '../../data/auth_repository.dart';
import '../../data/indicadores_repository.dart';
import '../../data/models.dart';
import '../relatorios/relatorios_page.dart';
import '../usuarios/usuarios_page.dart';
import 'paginas/alertas_page.dart';
import 'paginas/cumprimento_page.dart';
import 'paginas/executiva_page.dart';
import 'paginas/financeiro_page.dart';
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
    this.salvarPdf = salvarPdfNoAparelho,
    this.brasaoPdf = carregarBrasao,
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
  /// Como o PDF da tela Relatórios chega ao usuário (nos testes é substituído).
  final SalvarPdf salvarPdf;
  final Future<Uint8List?> Function() brasaoPdf;

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
    if (!t.permitidaPara(widget.usuario.papel)) return;
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
          onAbrirAlertas: () => _irPara(Tela.alertas),
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
      case Tela.executiva:
        return ExecutivaPage(
          key: const ValueKey('tela-executiva'),
          filtros: _filtros,
          repository: widget.repository,
          onAbrirAlertas: () => _irPara(Tela.alertas),
        );
      case Tela.financeiro:
        return FinanceiroPage(key: const ValueKey('tela-financeiro'), filtros: _filtros, repository: widget.repository, onGranularidade: _trocarGranularidade);
      case Tela.alertas:
        return AlertasPage(key: const ValueKey('tela-alertas'), filtros: _filtros, repository: widget.repository);
      case Tela.relatorios:
        return RelatoriosPage(key: const ValueKey('tela-relatorios'), filtros: _filtros, repository: widget.repository, usuario: widget.usuario, salvar: widget.salvarPdf, brasao: widget.brasaoPdf);
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
        titulo: _tela.rotulo,
        grupo: _tela.grupo,
        cor: _tela.cor,
        onFiltros: (f) => setState(() => _filtros = f),
      );
      // cada tela entra com um esmaecimento curto, para a troca não ser seca
      final corpo = Column(children: [
        if (_tela != Tela.usuarios) barra,
        Expanded(child: _Entrada(key: ValueKey('entrada-${_tela.name}'), child: _conteudo())),
      ]);

      if (faixa == FaixaLargura.expandido) {
        return Scaffold(body: Row(children: [menu, Expanded(child: corpo)]));
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Cores.navy,
          foregroundColor: Colors.white,
          bottom: FileteDaTela(cor: _tela.cor),
          title: Text(_tela.rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        drawer: Drawer(backgroundColor: Cores.navy, width: 272, child: SafeArea(child: menu)),
        body: corpo,
      );
    });
  }
}

/// Faz o conteúdo aparecer aos poucos (esmaece e sobe alguns pixels) quando a tela é trocada.
class _Entrada extends StatefulWidget {
  const _Entrada({super.key, required this.child});

  final Widget child;

  @override
  State<_Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<_Entrada> with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();
  late final Animation<double> _curva = CurvedAnimation(parent: _controle, curve: Curves.easeOut);

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.012), end: Offset.zero).animate(_curva),
        child: widget.child,
      ),
    );
  }
}
