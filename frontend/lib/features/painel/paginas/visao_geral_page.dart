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
import '../widgets/grafico_colunas.dart';
import '../widgets/kpi_card.dart';
import '../widgets/tabela_linhas.dart';

/// Visão Geral: os quatro indicadores principais, pagantes × gratuidades, FCV, faixas horárias
/// e o monitoramento por linha (US02 a US05).
class VisaoGeralPage extends StatefulWidget {
  const VisaoGeralPage({super.key, required this.filtros, required this.repository, this.onAbrirLinha});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  /// Chamado ao clicar em uma linha da tabela de monitoramento.
  final ValueChanged<String>? onAbrirLinha;

  @override
  State<VisaoGeralPage> createState() => _VisaoGeralPageState();
}

class _VisaoGeralPageState extends State<VisaoGeralPage> {
  Indicadores? _dados;
  DetalhesOperacao _detalhes = DetalhesOperacao.vazio;
  List<ResumoLinha> _linhas = const [];
  String? _erro;
  bool _carregando = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(VisaoGeralPage anterior) {
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
        widget.repository.detalhes(inicio: f.inicio, fim: f.fim, linha: f.linha),
        if (f.linha == null) widget.repository.resumoPorLinha(inicio: f.inicio, fim: f.fim),
      ]);
      if (!mounted || f != widget.filtros) return;
      setState(() {
        _dados = resultados[0] as Indicadores;
        _detalhes = resultados[1] as DetalhesOperacao;
        _linhas = resultados.length > 2 ? resultados[2] as List<ResumoLinha> : const [];
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
      final conteudo = <Widget>[
        CabecalhoTela(
          titulo: f.linha == null ? 'Painel consolidado de desempenho' : 'Linha ${f.linha} no período',
          subtitulo: _subtitulo(d),
          acoes: [if (d != null && !d.semDados) const Etiqueta('● Dados atualizados', tom: TomEtiqueta.ok)],
        ),
        const SizedBox(height: 18),
        if (_erro != null) MensagemErro(_erro!),
        if (_carregando) const Carregando(),
        if (!_carregando && _erro == null && d != null) ..._corpo(faixa, d),
      ];
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: conteudo),
      );
    });
  }

  String _subtitulo(Indicadores? d) {
    final partes = [widget.filtros.descricaoPeriodo];
    if (d?.totais != null) {
      if (widget.filtros.linha == null && _linhas.isNotEmpty) partes.add('${_linhas.length} linhas');
      partes.add('${d!.totais!.diasComDados} dias com dados');
    }
    partes.add('relatórios do Smart Report');
    return partes.join(' · ');
  }

  List<Widget> _corpo(FaixaLargura faixa, Indicadores d) {
    if (d.semDados) return const [AvisoSemDados()];
    final t = d.totais!;
    final ant = d.anterior;
    final rotuloAnt = ant == null ? 'vs. anterior' : rotuloComparacao(ant.inicio, ant.fim);
    final porLinha = widget.filtros.linha != null;
    final expandido = faixa == FaixaLargura.expandido;

    final cartoes = [
      KpiCard(
        titulo: 'Quilometragem',
        valor: fmtInteiro(t.kmTotal.round()),
        unidade: 'km',
        detalhe: _detalheKm(t),
        variacao: variacaoPercentual(t.kmTotal, ant?.totais.kmTotal),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.kmTotal],
      ),
      KpiCard(
        titulo: 'Viagens realizadas',
        valor: fmtInteiro(t.viagens),
        detalhe: t.viagensProgramadas == null
            ? '${fmtDecimal(t.viagens / (t.diasComDados == 0 ? 1 : t.diasComDados))} por dia'
            : '${fmtInteiro(t.viagensProgramadas!)} programadas · FCV ${fmtPercentual(t.fcv ?? 0)}',
        variacao: variacaoPercentual(t.viagens, ant?.totais.viagens),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.viagens.toDouble()],
      ),
      KpiCard(
        titulo: 'Passageiros',
        valor: t.total == null ? null : fmtInteiro(t.total!),
        detalhe: t.total == null
            ? null
            : '${fmtInteiro((t.total! / (t.diasComPassageiros == 0 ? 1 : t.diasComPassageiros)).round())} por dia · '
                '${t.mediaPorViagem == null ? '—' : fmtDecimal(t.mediaPorViagem!)} por viagem',
        etiqueta: _etiquetaPassageiros(t, ant, rotuloAnt),
        serie: [for (final p in d.serie) (p.total ?? 0).toDouble()],
        cor: Cores.verde,
      ),
      KpiCard(
        titulo: 'Gratuidades',
        valor: t.naoPagantes == null ? null : fmtInteiro(t.naoPagantes!),
        detalhe: t.pagantes == null ? null : 'Pagantes: ${fmtInteiro(t.pagantes!)}',
        etiqueta: t.naoPagantes == null || t.total == null || t.total == 0
            ? null
            : Etiqueta('${fmtDecimal(t.naoPagantes! / t.total! * 100)}% do total', tom: TomEtiqueta.info),
        serie: [for (final p in d.serie) (p.naoPagantes ?? 0).toDouble()],
        cor: Cores.ambar,
      ),
    ];

    final graficoPassageiros = Cartao(
      titulo: 'Pagantes × Gratuidades por ${widget.filtros.granularidade.rotulo.toLowerCase()}',
      subtitulo: porLinha
          ? 'A bilhetagem é do sistema inteiro'
          : '${widget.filtros.descricaoPeriodo} · bilhetagem do sistema (os dados de passageiros não são detalhados por linha)',
      acao: porLinha || t.total == null ? null : LegendaSeries(_seriesPassageiros(d)),
      child: porLinha
          ? const Aviso('Passageiros são consolidados pela bilhetagem para o sistema inteiro e não estão disponíveis por linha.',
              chave: Key('aviso-passageiros-linha'))
          : t.total == null
              ? const AvisoSemDados(texto: 'Sem bilhetagem importada para o período')
              : GraficoColunas(
                  rotulos: [for (final p in d.serie) rotuloPeriodo(p.periodo)],
                  series: _seriesPassageiros(d),
                  altura: 230,
                ),
    );

    final fcv = _CartaoCumprimento(totais: t, turnos: _detalhes.turnos, serie: d.serie, granularidade: widget.filtros.granularidade);

    final faixas = _detalhes.faixasHorarias;
    final pico = _detalhes.pico;
    final graficoFaixas = Cartao(
      titulo: 'Viagens por faixa horária',
      subtitulo: '${widget.filtros.descricaoPeriodo} · ${porLinha ? 'linha ${widget.filtros.linha}' : 'todas as linhas'} · soma das viagens por hora de início',
      acao: pico == null ? null : Etiqueta('Pico ${pico.faixa.toString().padLeft(2, '0')}h · ${fmtInteiro(pico.viagens)} viagens', tom: TomEtiqueta.info),
      child: faixas.isEmpty
          ? const AvisoSemDados(texto: 'Sem o relatório de faixa horária no período')
          : GraficoColunas(
              rotulos: [for (final x in faixas) '${x.faixa.toString().padLeft(2, '0')}h'],
              series: [SerieColunas(nome: 'Viagens', valores: [for (final x in faixas) x.viagens.toDouble()], cor: Cores.navy)],
              altura: 200,
            ),
    );

    final linhasFiltradas = _busca.isEmpty
        ? _linhas
        : _linhas.where((l) => '${l.codigo} ${l.nome}'.toLowerCase().contains(_busca.toLowerCase())).toList();

    return [
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
      if (expandido)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: graficoPassageiros),
          const SizedBox(width: 18),
          Expanded(child: fcv),
        ])
      else ...[
        graficoPassageiros,
        const SizedBox(height: 18),
        fcv,
      ],
      const SizedBox(height: 18),
      graficoFaixas,
      if (!porLinha) ...[
        const SizedBox(height: 18),
        Cartao(
          titulo: 'Monitoramento por linha',
          subtitulo: '${widget.filtros.descricaoPeriodo} · clique na linha para ver o detalhamento',
          acao: SizedBox(
            width: 200,
            child: TextField(
              key: const Key('busca-linha'),
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Buscar linha',
                border: OutlineInputBorder(borderSide: BorderSide(color: Cores.linha)),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          child: _linhas.isEmpty
              ? const AvisoSemDados(texto: 'Sem o resumo por linha no período')
              : TabelaLinhas(
                  linhas: linhasFiltradas,
                  onSelecionar: widget.onAbrirLinha == null ? null : (l) => widget.onAbrirLinha!(l.codigo),
                ),
        ),
      ],
    ];
  }

  String _detalheKm(Totais t) {
    if (t.kmProdutiva == null || t.kmTotal == 0) {
      return '${t.viagens == 0 ? '—' : fmtDecimal(t.kmTotal / t.viagens)} km por viagem';
    }
    return '${fmtInteiro(t.kmProdutiva!.round())} km produtiva · ${fmtDecimal(t.kmImprodutiva! / t.kmTotal * 100)}% improdutiva';
  }

  List<SerieColunas> _seriesPassageiros(Indicadores d) => [
        SerieColunas(nome: 'Pagantes (catraca + antecipados)', valores: [for (final p in d.serie) (p.pagantes ?? 0).toDouble()], cor: Cores.navy),
        SerieColunas(nome: 'Gratuidades', valores: [for (final p in d.serie) (p.naoPagantes ?? 0).toDouble()], cor: Cores.verde),
      ];

  /// Passageiros comparam com o período anterior só quando ele tem bilhetagem completa.
  Widget? _etiquetaPassageiros(Totais t, PeriodoAnterior? ant, String rotuloAnt) {
    if (t.total == null || ant == null || ant.totais.total == null) return null;
    if (ant.totais.diasComPassageiros < ant.totais.diasComDados) {
      return Etiqueta('${rotuloAnt.replaceFirst('vs. ', '')} parcial');
    }
    final v = variacaoPercentual(t.total, ant.totais.total);
    return v == null ? null : EtiquetaVariacao(v, rotulo: rotuloAnt);
  }
}

/// Cartão do cumprimento de viagens: percentual do período, por turno e os piores dias.
class _CartaoCumprimento extends StatelessWidget {
  const _CartaoCumprimento({super.key, required this.totais, required this.turnos, required this.serie, required this.granularidade});

  final Totais totais;
  final List<Turno> turnos;
  final List<PontoIndicador> serie;
  final Granularidade granularidade;

  @override
  Widget build(BuildContext context) {
    final piores = [...serie.where((p) => p.fcv != null)]..sort((a, b) => a.fcv!.compareTo(b.fcv!));
    final unidade = switch (granularidade) {
      Granularidade.dia => 'Dias',
      Granularidade.semana => 'Semanas',
      Granularidade.mes => 'Meses',
    };
    return Cartao(
      titulo: 'Cumprimento de viagens (FCV)',
      subtitulo: 'Realizadas ÷ programadas',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (totais.fcv == null)
          const Text('Sem dados', key: Key('kpi-FCV'), style: TextStyle(color: Cores.texto2, fontWeight: FontWeight.w600))
        else
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(fmtPercentual(totais.fcv!), key: const Key('kpi-FCV'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Cores.verde)),
            const SizedBox(width: 8),
            Text('no período', style: Theme.of(context).textTheme.bodySmall),
          ]),
        if (turnos.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final tr in turnos) _LinhaTurno(tr),
        ],
        if (piores.isNotEmpty) ...[
          const SizedBox(height: 14),
          Rotulo('$unidade com menor cumprimento'),
          const SizedBox(height: 6),
          for (final p in piores.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 56, child: Text(rotuloPeriodo(p.periodo), style: const TextStyle(fontSize: 12.5))),
                Expanded(
                  child: Text(fmtPercentual(p.fcv!), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                Text(
                  p.viagensNaoRealizadas == null ? '' : '${fmtInteiro(p.viagensNaoRealizadas!)} viagens a menos',
                  style: const TextStyle(fontSize: 11.5, color: Cores.texto2),
                ),
              ]),
            ),
        ],
      ]),
    );
  }
}

class _LinhaTurno extends StatelessWidget {
  const _LinhaTurno(this.turno, {super.key});

  final Turno turno;

  @override
  Widget build(BuildContext context) {
    final fracao = turno.programadas == 0 ? 0.0 : (turno.realizadas / turno.programadas).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 56, child: Text(turno.rotulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          Expanded(
            child: Text('${fmtInteiro(turno.realizadas)} / ${fmtInteiro(turno.programadas)}', style: const TextStyle(fontSize: 12, color: Cores.texto2)),
          ),
          Text(turno.fcv == null ? '—' : fmtPercentual(turno.fcv!), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: fracao, minHeight: 5, backgroundColor: Cores.fundo, color: Cores.verde),
        ),
      ]),
    );
  }
}
