import 'package:flutter/material.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/layout.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/indicadores_repository.dart';
import '../../../data/models.dart';
import '../widgets/cartao.dart';
import '../widgets/estados.dart';
import '../widgets/kpi_card.dart';

/// Visão executiva: resumo do período para o secretário apresentar.
class ExecutivaPage extends StatefulWidget {
  const ExecutivaPage({super.key, required this.filtros, required this.repository, this.onAbrirAlertas});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;
  final VoidCallback? onAbrirAlertas;

  @override
  State<ExecutivaPage> createState() => _ExecutivaPageState();
}

class _ExecutivaPageState extends State<ExecutivaPage> {
  Indicadores? _dados;
  Financeiro? _financeiro;
  Alertas _alertas = Alertas.vazio;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(ExecutivaPage anterior) {
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
      final resultados = await Future.wait<Object>([
        widget.repository.obter(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, linha: f.linha, comparar: true),
        widget.repository.financeiro(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, comparar: true),
        widget.repository.alertas(inicio: f.inicio, fim: f.fim, linha: f.linha),
      ]);
      if (!mounted || f != widget.filtros) return;
      setState(() {
        _dados = resultados[0] as Indicadores;
        _financeiro = resultados[1] as Financeiro;
        _alertas = resultados[2] as Alertas;
      });
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
            titulo: 'Visão executiva',
            subtitulo: '${f.descricaoPeriodo}${f.linha == null ? ' · sistema inteiro' : ' · linha ${f.linha}'} · resumo para apresentação, com o comparativo do período anterior',
          ),
          const SizedBox(height: 18),
          if (_erro != null) MensagemErro(_erro!),
          if (_carregando) const Carregando(),
          if (!_carregando && _erro == null && d != null) ..._corpo(faixa, d),
        ]),
      );
    });
  }

  List<Widget> _corpo(FaixaLargura faixa, Indicadores d) {
    if (d.semDados) return const [AvisoSemDados()];
    final t = d.totais!;
    final ant = d.anterior;
    final rotuloAnt = ant == null ? 'vs. anterior' : rotuloComparacao(ant.inicio, ant.fim);
    final fin = _financeiro?.totais;
    final finAnt = _financeiro?.anterior?.totais;

    final destaques = [
      KpiCard(
        titulo: 'Quilometragem',
        valor: fmtInteiro(t.kmTotal.round()),
        unidade: 'km',
        detalhe: '${t.diasComDados} dias com dados',
        variacao: variacaoPercentual(t.kmTotal, ant?.totais.kmTotal),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.kmTotal],
      ),
      KpiCard(
        titulo: 'Viagens realizadas',
        valor: fmtInteiro(t.viagens),
        detalhe: t.viagensProgramadas == null ? null : 'de ${fmtInteiro(t.viagensProgramadas!)} programadas',
        variacao: variacaoPercentual(t.viagens, ant?.totais.viagens),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.viagens.toDouble()],
      ),
      KpiCard(
        titulo: 'Cumprimento de viagens',
        valor: t.fcv == null ? null : fmtPercentual(t.fcv!),
        detalhe: t.fcv == null ? null : (t.fcv! >= 95 ? 'dentro da meta de 95%' : 'abaixo da meta de 95%'),
        variacao: variacaoPercentual(t.fcv, ant?.totais.fcv),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.fcv ?? 0],
        cor: Cores.verde,
      ),
      KpiCard(
        titulo: 'Passageiros',
        valor: t.total == null ? null : fmtInteiro(t.total!),
        detalhe: t.total == null || t.naoPagantes == null || t.total == 0 ? null : '${fmtDecimal(t.naoPagantes! / t.total! * 100)}% gratuidades',
        variacao: variacaoPercentual(t.total, ant?.totais.total),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) (p.total ?? 0).toDouble()],
        cor: Cores.ambar,
      ),
      KpiCard(
        titulo: 'Vendas de créditos',
        valor: fin == null ? null : fmtMoeda(fin.vendas, semCentavos: true),
        detalhe: fin == null ? null : 'utilização de ${fmtMoeda(fin.utilizacao, semCentavos: true)}',
        variacao: variacaoPercentual(fin?.vendas, finAnt?.vendas),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in _financeiro?.serie ?? const <PontoFinanceiro>[]) p.vendas],
        cor: Cores.azul,
      ),
      KpiCard(
        titulo: 'Alertas críticos',
        valor: fmtInteiro(_alertas.criticos),
        detalhe: _alertas.total == 0 ? 'operação dentro do padrão' : '${_alertas.total} alertas em ${_alertas.diasComAlerta} dias',
        etiqueta: _alertas.criticos == 0 ? const Etiqueta('sem desvio grave', tom: TomEtiqueta.ok) : const Etiqueta('atenção', tom: TomEtiqueta.negativo),
        cor: Cores.vermelho,
      ),
    ];

    final criticos = _alertas.alertas.where((a) => a.severidade == Severidade.critico).take(5).toList();

    return [
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: switch (faixa) { FaixaLargura.compacto => 1, FaixaLargura.medio => 2, FaixaLargura.expandido => 3 },
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 158,
        ),
        children: destaques,
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Comparativo com o período anterior',
        subtitulo: ant == null ? 'Sem dados do período anterior para comparar' : '${fmtData(ant.inicio)} a ${fmtData(ant.fim)}',
        child: _Comparativo(rows: [
          ('Quilometragem (km)', fmtInteiro(t.kmTotal.round()), ant == null ? null : fmtInteiro(ant.totais.kmTotal.round()), variacaoPercentual(t.kmTotal, ant?.totais.kmTotal)),
          ('Viagens realizadas', fmtInteiro(t.viagens), ant == null ? null : fmtInteiro(ant.totais.viagens), variacaoPercentual(t.viagens, ant?.totais.viagens)),
          ('Cumprimento de viagens', t.fcv == null ? 'Sem dados' : fmtPercentual(t.fcv!), ant?.totais.fcv == null ? null : fmtPercentual(ant!.totais.fcv!), variacaoPercentual(t.fcv, ant?.totais.fcv)),
          ('Passageiros', t.total == null ? 'Sem dados' : fmtInteiro(t.total!), ant?.totais.total == null ? null : fmtInteiro(ant!.totais.total!), variacaoPercentual(t.total, ant?.totais.total)),
          ('Gratuidades', t.naoPagantes == null ? 'Sem dados' : fmtInteiro(t.naoPagantes!), ant?.totais.naoPagantes == null ? null : fmtInteiro(ant!.totais.naoPagantes!), variacaoPercentual(t.naoPagantes, ant?.totais.naoPagantes)),
          ('Vendas de créditos', fin == null ? 'Sem dados' : fmtMoeda(fin.vendas), finAnt == null ? null : fmtMoeda(finAnt.vendas), variacaoPercentual(fin?.vendas, finAnt?.vendas)),
          ('Utilização de créditos', fin == null ? 'Sem dados' : fmtMoeda(fin.utilizacao), finAnt == null ? null : fmtMoeda(finAnt.utilizacao), variacaoPercentual(fin?.utilizacao, finAnt?.utilizacao)),
        ], rotuloAnt: rotuloAnt),
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Pontos de atenção',
        subtitulo: _alertas.total == 0 ? 'Nenhum dia fora do padrão no período' : '${_alertas.criticos} críticos e ${_alertas.avisos} avisos no período',
        acao: _alertas.total == 0 || widget.onAbrirAlertas == null
            ? null
            : TextButton(key: const Key('executiva-ver-alertas'), onPressed: widget.onAbrirAlertas, child: const Text('Ver todos os alertas')),
        child: criticos.isEmpty
            ? Row(children: [
                const Icon(Icons.check_circle_outline, color: Cores.verde, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_alertas.total == 0 ? 'A operação ficou dentro do padrão em todo o período.' : 'Nenhum desvio grave; só avisos no período.', key: const Key('executiva-sem-criticos'))),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final a in criticos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(padding: EdgeInsets.only(top: 4, right: 10), child: Icon(Icons.warning_amber_rounded, color: Cores.vermelho, size: 18)),
                      Expanded(child: Text('${fmtData(a.data)}${a.linha == null ? '' : ' · linha ${a.linha}'} — ${a.mensagem}', style: const TextStyle(fontSize: 13.5))),
                    ]),
                  ),
              ]),
      ),
      const SizedBox(height: 12),
      Text(
        'Fonte: relatórios do Smart Report importados no DashMOB. Passageiros e valores financeiros são da bilhetagem do sistema inteiro.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
}

/// Tabela compacta indicador | período | anterior | variação.
class _Comparativo extends StatelessWidget {
  const _Comparativo({required this.rows, required this.rotuloAnt});

  final List<(String, String, String?, double?)> rows;
  final String rotuloAnt;

  @override
  Widget build(BuildContext context) {
    final cabecalho = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: Cores.texto2);
    final celula = TextStyle(fontSize: 13.5, color: Cores.tinta);
    return LayoutBuilder(builder: (context, c) {
      final compacto = c.maxWidth < 560;
      return Table(
        columnWidths: compacto
            ? const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.3)}
            : const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(1.3)},
        border: TableBorder(horizontalInside: BorderSide(color: Cores.linha)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('INDICADOR', style: cabecalho)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('PERÍODO', style: cabecalho, textAlign: TextAlign.right)),
            if (!compacto) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('ANTERIOR', style: cabecalho, textAlign: TextAlign.right)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(rotuloAnt.replaceFirst('vs. ', 'VS. ').toUpperCase(), style: cabecalho, textAlign: TextAlign.right)),
          ]),
          for (final (nome, atual, anterior, variacao) in rows)
            TableRow(children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Text(nome, style: celula)),
              Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Text(atual, key: Key('comparativo-$nome'), style: celula.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              if (!compacto) Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Text(anterior ?? '—', style: celula.copyWith(color: Cores.texto2), textAlign: TextAlign.right)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: variacao == null ? Text('—', style: TextStyle(color: Cores.texto2)) : EtiquetaVariacao(variacao, rotulo: ''),
                ),
              ),
            ]),
        ],
      );
    });
  }
}
