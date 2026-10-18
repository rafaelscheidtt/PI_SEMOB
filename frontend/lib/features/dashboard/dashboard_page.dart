import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../core/layout.dart';
import '../../core/periodo.dart';
import '../../data/indicadores_repository.dart';
import '../../data/models.dart';
import 'widgets/filtros.dart';
import 'widgets/grafico_barras.dart';
import 'widgets/kpi_card.dart';

/// Painel principal: filtros, cartões de indicadores e gráficos (US02 a US06).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.repository, this.inicioInicial, this.fimInicial});

  final IndicadoresRepository repository;
  final DateTime? inicioInicial;
  final DateTime? fimInicial;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _inicio;
  late DateTime _fim;
  Granularidade _granularidade = Granularidade.dia;
  String? _linha;
  List<Linha> _linhas = const [];

  Indicadores? _dados;
  String? _erro;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _fim = widget.fimInicial ?? DateTime(hoje.year, hoje.month, hoje.day);
    _inicio = widget.inicioInicial ?? _fim.subtract(const Duration(days: 29));
    _carregarLinhas();
    _consultar();
  }

  Future<void> _carregarLinhas() async {
    try {
      final l = await widget.repository.linhas();
      if (mounted) setState(() => _linhas = l);
    } catch (_) {
      // sem lista de linhas o painel continua funcionando com "Todas as linhas"
    }
  }

  Future<void> _consultar() async {
    final erroIntervalo = validarIntervalo(_inicio, _fim); // RN07
    if (erroIntervalo != null) {
      setState(() => _erro = erroIntervalo);
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final d = await widget.repository.obter(inicio: _inicio, fim: _fim, granularidade: _granularidade, linha: _linha);
      if (mounted) setState(() => _dados = d);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DashMOB — Operação de transporte')),
      body: LayoutBuilder(
        builder: (context, c) {
          final faixa = faixaDeLargura(c.maxWidth);
          return SingleChildScrollView(
            padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Filtros(
                  granularidade: _granularidade,
                  inicio: _inicio,
                  fim: _fim,
                  linhas: _linhas,
                  linha: _linha,
                  compacto: faixa == FaixaLargura.compacto,
                  onGranularidade: (g) {
                    setState(() => _granularidade = g);
                    _consultar();
                  },
                  onIntervalo: (i, f) {
                    setState(() {
                      _inicio = i;
                      _fim = f;
                    });
                    _consultar();
                  },
                  onLinha: (l) {
                    setState(() => _linha = l);
                    _consultar();
                  },
                ),
                const SizedBox(height: 16),
                if (_erro != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.error_outline),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_erro!, key: const Key('mensagem-erro'))),
                      ]),
                    ),
                  ),
                if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                if (!_carregando && _erro == null && _dados != null) ..._conteudo(faixa, _dados!),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _conteudo(FaixaLargura faixa, Indicadores d) {
    final t = d.totais;
    final cartoes = [
      KpiCard(titulo: 'Quilometragem', valor: t == null ? null : fmtDecimal(t.kmTotal), unidade: 'km', icone: Icons.route),
      KpiCard(
        titulo: 'Viagens realizadas',
        valor: t == null ? null : fmtInteiro(t.viagens),
        unidade: t?.viagensProgramadas == null ? null : '${fmtInteiro(t!.viagensProgramadas!)} programadas',
        icone: Icons.directions_bus,
      ),
      KpiCard(titulo: 'Cumprimento de viagens', valor: t?.fcv == null ? null : fmtPercentual(t!.fcv!), icone: Icons.task_alt),
      KpiCard(titulo: 'Passageiros pagantes', valor: t?.pagantes == null ? null : fmtInteiro(t!.pagantes!), icone: Icons.person),
      KpiCard(titulo: 'Gratuidades', valor: t?.naoPagantes == null ? null : fmtInteiro(t!.naoPagantes!), icone: Icons.person_outline),
      KpiCard(titulo: 'Passageiros no total', valor: t?.total == null ? null : fmtInteiro(t!.total!), icone: Icons.groups),
      KpiCard(
        titulo: 'Média de passageiros por viagem',
        valor: t?.mediaPorViagem == null ? null : fmtDecimal(t!.mediaPorViagem!),
        icone: Icons.stacked_line_chart,
      ),
    ];
    final colunas = colunasDeCartoes(faixa);
    return [
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunas,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 132,
        ),
        children: cartoes,
      ),
      const SizedBox(height: 16),
      if (d.semDados)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('Sem dados para o período selecionado', key: const Key('aviso-sem-dados'), style: Theme.of(context).textTheme.titleMedium)),
        )
      else ...[
        GraficoBarras(serie: d.serie, granularidade: _granularidade, valor: (p) => p.kmTotal, titulo: 'Quilometragem por ${_granularidade.rotulo.toLowerCase()}'),
        const SizedBox(height: 12),
        GraficoBarras(serie: d.serie, granularidade: _granularidade, valor: (p) => p.viagens.toDouble(), titulo: 'Viagens por ${_granularidade.rotulo.toLowerCase()}'),
        if (_linha == null && d.serie.any((p) => p.total != null)) ...[
          const SizedBox(height: 12),
          GraficoBarras(serie: d.serie, granularidade: _granularidade, valor: (p) => (p.total ?? 0).toDouble(), titulo: 'Passageiros por ${_granularidade.rotulo.toLowerCase()}'),
        ] else if (_linha != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Passageiros são consolidados pela bilhetagem para o sistema inteiro e não estão disponíveis por linha.',
                key: const Key('aviso-passageiros-linha'), style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ],
    ];
  }
}
