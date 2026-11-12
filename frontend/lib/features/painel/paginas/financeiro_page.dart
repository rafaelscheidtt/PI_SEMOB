import 'package:flutter/material.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/layout.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/indicadores_repository.dart';
import '../../../data/models.dart';
import '../widgets/barra_filtros.dart';
import '../widgets/cartao.dart';
import '../widgets/estados.dart';
import '../widgets/grafico_colunas.dart';
import '../widgets/kpi_card.dart';

/// Financeiro: vendas, utilização, crédito circulante e saldo de créditos da bilhetagem (US07, RN12).
/// A bilhetagem é do sistema inteiro e só existe desde o fim do Tarifa Zero (15/07/2026).
class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key, required this.filtros, required this.repository, this.onGranularidade});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  /// Troca a granularidade dos gráficos (dia, semana, mês); os cartões de total não dependem dela.
  final ValueChanged<Granularidade>? onGranularidade;

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  Financeiro? _dados;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(FinanceiroPage anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filtros != widget.filtros) _consultar();
  }

  Future<void> _consultar() async {
    final f = widget.filtros;
    final erroIntervalo = validarIntervalo(f.inicio, f.fim); // RN07
    if (erroIntervalo != null) {
      setState(() {
        _erro = erroIntervalo;
        _carregando = false;
      });
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // a bilhetagem é do sistema inteiro, então a consulta ignora o filtro de linha
      final d = await widget.repository.financeiro(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, comparar: true);
      if (!mounted || f != widget.filtros) return;
      setState(() => _dados = d);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted && f == widget.filtros) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filtros;
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      final d = _dados;
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CabecalhoTela(
            titulo: 'Financeiro',
            subtitulo: '${f.descricaoPeriodo} · bilhetagem do sistema inteiro, em reais',
          ),
          const SizedBox(height: 18),
          if (f.linha != null) ...[
            const Aviso('Os valores financeiros vêm da bilhetagem do sistema inteiro e não existem por linha. Os números abaixo são de todas as linhas.',
                chave: Key('aviso-financeiro-linha')),
            const SizedBox(height: 18),
          ],
          if (_erro != null) MensagemErro(_erro!),
          if (_carregando) const Carregando(),
          if (!_carregando && _erro == null && d != null) ..._corpo(faixa, d),
        ]),
      );
    });
  }

  /// Aviso sobre o Tarifa Zero quando o período começa antes da bilhetagem.
  Widget? _avisoBilhetagem(Financeiro d) {
    final inicio = d.inicioBilhetagem;
    if (inicio == null || !widget.filtros.inicio.isBefore(inicio)) return null;
    return Aviso(
      'A bilhetagem começou em ${fmtData(inicio)}, com o fim do Tarifa Zero para quem não é cadastrado. '
      'Antes disso o ônibus era gratuito para todos e não existe dado financeiro.',
      chave: const Key('aviso-tarifa-zero'),
    );
  }

  static String _nomePeriodo(Granularidade g) => switch (g) {
        Granularidade.dia => 'dia',
        Granularidade.semana => 'semana',
        Granularidade.mes => 'mês',
      };

  List<Widget> _corpo(FaixaLargura faixa, Financeiro d) {
    final avisoBilhetagem = _avisoBilhetagem(d);
    if (d.semDados) {
      return [
        if (avisoBilhetagem != null) ...[avisoBilhetagem, const SizedBox(height: 18)],
        const AvisoSemDados(texto: 'Sem bilhetagem no período selecionado'),
      ];
    }
    final t = d.totais!;
    final ant = d.anterior;
    final rotuloAnt = ant == null ? 'vs. anterior' : rotuloComparacao(ant.inicio, ant.fim);
    final rotulos = [for (final p in d.serie) rotuloPeriodo(p.periodo)];

    final cartoes = [
      KpiCard(
        titulo: 'Vendas',
        valor: fmtMoeda(t.vendas, semCentavos: true),
        detalhe: t.vendasPorDia == null ? null : '${fmtMoeda(t.vendasPorDia!, semCentavos: true)} por dia · ${t.diasComDados} dias com bilhetagem',
        variacao: variacaoPercentual(t.vendas, ant?.totais.vendas),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.vendas],
      ),
      KpiCard(
        titulo: 'Utilização',
        valor: fmtMoeda(t.utilizacao, semCentavos: true),
        detalhe: t.utilizacaoPorDia == null ? null : '${fmtMoeda(t.utilizacaoPorDia!, semCentavos: true)} por dia · créditos usados nas catracas',
        variacao: variacaoPercentual(t.utilizacao, ant?.totais.utilizacao),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.utilizacao],
        cor: Cores.verde,
      ),
      KpiCard(
        titulo: 'Crédito circulante',
        valor: fmtMoeda(t.creditoCirculante, semCentavos: true),
        detalhe: 'vendas − utilização no período (RN12)',
        etiqueta: Etiqueta(t.creditoCirculante >= 0 ? 'mais vendido que usado' : 'mais usado que vendido',
            tom: t.creditoCirculante >= 0 ? TomEtiqueta.ok : TomEtiqueta.aviso),
        serie: [for (final p in d.serie) p.creditoCirculante],
        cor: Cores.ambar,
      ),
      KpiCard(
        titulo: 'Saldo de créditos',
        valor: t.saldoFinal == null ? null : fmtMoeda(t.saldoFinal!, semCentavos: true),
        detalhe: 'no fim do período · ${fmtMoeda(t.creditosTransferidos, semCentavos: true)} transferidos para cartões',
        variacao: variacaoPercentual(t.saldoFinal, ant?.totais.saldoFinal),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.saldoFinal ?? 0],
        cor: Cores.azul,
      ),
    ];

    final series = [
      SerieColunas(nome: 'Vendas', valores: [for (final p in d.serie) p.vendas], cor: Cores.destaque),
      SerieColunas(nome: 'Utilização', valores: [for (final p in d.serie) p.utilizacao], cor: Cores.verde),
    ];

    return [
      if (avisoBilhetagem != null) ...[avisoBilhetagem, const SizedBox(height: 18)],
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunasDeCartoes(faixa),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 158,
        ),
        children: cartoes,
      ),
      const SizedBox(height: 18),
      CabecalhoGraficos(granularidade: widget.filtros.granularidade, onChanged: widget.onGranularidade, texto: 'Evolução no período'),
      const SizedBox(height: 12),
      Cartao(
        titulo: 'Vendas × Utilização por ${widget.filtros.granularidade.rotulo.toLowerCase()}',
        subtitulo: 'Em reais. Períodos sem o relatório de saldos ficam em branco, nunca em zero (RN06)',
        acao: LegendaSeries(series),
        child: GraficoColunas(rotulos: rotulos, series: series, formato: (v) => fmtMoeda(v, semCentavos: true), altura: 260),
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Saldo de créditos no fim de cada ${_nomePeriodo(widget.filtros.granularidade)}',
        subtitulo: 'Créditos ainda não utilizados pelos passageiros',
        child: GraficoColunas(
          rotulos: rotulos,
          series: [SerieColunas(nome: 'Saldo final', valores: [for (final p in d.serie) p.saldoFinal ?? 0], cor: Cores.azul)],
          formato: (v) => fmtMoeda(v, semCentavos: true),
          altura: 200,
        ),
      ),
    ];
  }
}
