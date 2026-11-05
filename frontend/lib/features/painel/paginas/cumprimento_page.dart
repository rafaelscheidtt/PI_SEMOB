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

/// Cumprimento de viagens: FCV do período, por turno e ao longo do tempo (US03, RN08).
class CumprimentoPage extends StatefulWidget {
  const CumprimentoPage({super.key, required this.filtros, required this.repository});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  @override
  State<CumprimentoPage> createState() => _CumprimentoPageState();
}

class _CumprimentoPageState extends State<CumprimentoPage> {
  Indicadores? _dados;
  DetalhesOperacao _detalhes = DetalhesOperacao.vazio;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(CumprimentoPage anterior) {
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
      ]);
      if (!mounted || f != widget.filtros) return;
      setState(() {
        _dados = resultados[0] as Indicadores;
        _detalhes = resultados[1] as DetalhesOperacao;
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
            titulo: 'Cumprimento de viagens',
            subtitulo: '${f.descricaoPeriodo} · ${f.linha == null ? 'todas as linhas' : 'linha ${f.linha}'} · viagens realizadas ÷ programadas (RN08)',
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
    if (t.viagensProgramadas == null) {
      return [
        const Aviso('O cumprimento de viagens vem do relatório de FCV, que é do sistema inteiro: escolha "Todas as linhas" para ver este indicador.',
            chave: Key('aviso-fcv-linha')),
      ];
    }
    final naoRealizadas = t.viagensNaoRealizadas ?? 0;
    final naoRealizadasAnt = ant?.totais.viagensNaoRealizadas;
    final cartoes = [
      KpiCard(
        titulo: 'Cumprimento (FCV)',
        valor: t.fcv == null ? null : fmtPercentual(t.fcv!),
        detalhe: '${fmtInteiro(t.viagens)} de ${fmtInteiro(t.viagensProgramadas!)} viagens',
        variacao: variacaoPercentual(t.fcv, ant?.totais.fcv),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.fcv ?? 0],
        cor: Cores.verde,
      ),
      KpiCard(
        titulo: 'Viagens programadas',
        valor: fmtInteiro(t.viagensProgramadas!),
        detalhe: '${fmtDecimal(t.viagensProgramadas! / (t.diasComDados == 0 ? 1 : t.diasComDados))} por dia',
        variacao: variacaoPercentual(t.viagensProgramadas, ant?.totais.viagensProgramadas),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) (p.viagensProgramadas ?? 0).toDouble()],
      ),
      KpiCard(
        titulo: 'Viagens realizadas',
        valor: fmtInteiro(t.viagens),
        detalhe: '${fmtDecimal(t.viagens / (t.diasComDados == 0 ? 1 : t.diasComDados))} por dia',
        variacao: variacaoPercentual(t.viagens, ant?.totais.viagens),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.viagens.toDouble()],
      ),
      KpiCard(
        titulo: 'Viagens não realizadas',
        valor: fmtInteiro(naoRealizadas),
        detalhe: 'programadas que não aconteceram',
        etiqueta: naoRealizadasAnt == null || naoRealizadasAnt == 0
            ? null
            : EtiquetaVariacao(variacaoPercentual(naoRealizadas, naoRealizadasAnt)!, rotulo: rotuloAnt, quedaEBoa: true),
        serie: [for (final p in d.serie) (p.viagensNaoRealizadas ?? 0).toDouble()],
        cor: Cores.vermelho,
      ),
    ];

    final turnos = _detalhes.turnos;
    final piores = [...d.serie.where((p) => p.fcv != null)]..sort((a, b) => a.fcv!.compareTo(b.fcv!));

    final graficoFcv = Cartao(
      titulo: 'Cumprimento por ${widget.filtros.granularidade.rotulo.toLowerCase()}',
      subtitulo: 'Percentual de viagens realizadas em cada período',
      child: GraficoColunas(
        rotulos: [for (final p in d.serie) rotuloPeriodo(p.periodo)],
        series: [SerieColunas(nome: 'FCV', valores: [for (final p in d.serie) p.fcv ?? 0], cor: Cores.verde)],
        formato: (v) => '${fmtDecimal(v)}%',
        maximoY: 100,
        altura: 230,
      ),
    );

    final cartaoTurnos = Cartao(
      titulo: 'Por turno',
      subtitulo: 'Manhã, tarde e noite',
      child: turnos.isEmpty
          ? const AvisoSemDados(texto: 'Sem o relatório de FCV no período')
          : Column(children: [
              for (final tr in turnos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 64, child: Text(tr.rotulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: tr.programadas == 0 ? 0 : (tr.realizadas / tr.programadas).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Cores.fundo,
                          color: Cores.verde,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: Text(
                        '${fmtInteiro(tr.realizadas)} / ${fmtInteiro(tr.programadas)} · ${tr.fcv == null ? '—' : fmtPercentual(tr.fcv!)}',
                        style: const TextStyle(fontSize: 12.5),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ]),
                ),
            ]),
    );

    final cartaoPiores = Cartao(
      titulo: 'Períodos com menor cumprimento',
      subtitulo: 'Onde faltaram mais viagens',
      child: Column(children: [
        for (final p in piores.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(width: 64, child: Text(rotuloPeriodo(p.periodo), style: const TextStyle(fontSize: 13))),
              Expanded(child: Text(fmtPercentual(p.fcv!), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text(
                p.viagensNaoRealizadas == null ? '' : '${fmtInteiro(p.viagensNaoRealizadas!)} viagens a menos',
                style: const TextStyle(fontSize: 12, color: Cores.texto2),
              ),
            ]),
          ),
      ]),
    );

    final expandido = faixa == FaixaLargura.expandido;
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
      graficoFcv,
      const SizedBox(height: 18),
      if (expandido)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: cartaoTurnos),
          const SizedBox(width: 18),
          Expanded(child: cartaoPiores),
        ])
      else ...[
        cartaoTurnos,
        const SizedBox(height: 18),
        cartaoPiores,
      ],
    ];
  }
}
