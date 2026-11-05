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

/// Passageiros: pagantes, gratuidades, total e média por viagem (US04, RN02, RN03).
class PassageirosPage extends StatefulWidget {
  const PassageirosPage({super.key, required this.filtros, required this.repository});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  @override
  State<PassageirosPage> createState() => _PassageirosPageState();
}

class _PassageirosPageState extends State<PassageirosPage> {
  Indicadores? _dados;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(PassageirosPage anterior) {
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
      final d = await widget.repository.obter(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, comparar: true);
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
            titulo: 'Passageiros',
            subtitulo: '${f.descricaoPeriodo} · bilhetagem do sistema inteiro (catraca, antecipados e gratuidades)',
          ),
          const SizedBox(height: 18),
          if (f.linha != null) ...[
            const Aviso('Passageiros são consolidados pela bilhetagem para o sistema inteiro e não estão disponíveis por linha. Os números abaixo são de todas as linhas.',
                chave: Key('aviso-passageiros-linha')),
            const SizedBox(height: 18),
          ],
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
    final anteriorParcial = ant != null && ant.totais.total != null && ant.totais.diasComPassageiros < ant.totais.diasComDados;

    Widget? etiqueta(num? atual, num? anterior) {
      if (atual == null || anterior == null) return null;
      if (anteriorParcial) return Etiqueta('${rotuloAnt.replaceFirst('vs. ', '')} parcial');
      final v = variacaoPercentual(atual, anterior);
      return v == null ? null : EtiquetaVariacao(v, rotulo: rotuloAnt);
    }

    final dias = t.diasComPassageiros == 0 ? 1 : t.diasComPassageiros;
    final cartoes = [
      KpiCard(
        titulo: 'Passageiros no total',
        valor: t.total == null ? null : fmtInteiro(t.total!),
        detalhe: t.total == null ? null : '${fmtInteiro((t.total! / dias).round())} por dia · ${t.diasComPassageiros} dias com bilhetagem',
        etiqueta: etiqueta(t.total, ant?.totais.total),
        serie: [for (final p in d.serie) (p.total ?? 0).toDouble()],
      ),
      KpiCard(
        titulo: 'Pagantes',
        valor: t.pagantes == null ? null : fmtInteiro(t.pagantes!),
        detalhe: t.pagantes == null || t.total == null || t.total == 0 ? null : '${fmtDecimal(t.pagantes! / t.total! * 100)}% do total · catraca + antecipados',
        etiqueta: etiqueta(t.pagantes, ant?.totais.pagantes),
        serie: [for (final p in d.serie) (p.pagantes ?? 0).toDouble()],
      ),
      KpiCard(
        titulo: 'Gratuidades',
        valor: t.naoPagantes == null ? null : fmtInteiro(t.naoPagantes!),
        detalhe: t.naoPagantes == null || t.total == null || t.total == 0 ? null : '${fmtDecimal(t.naoPagantes! / t.total! * 100)}% do total',
        etiqueta: etiqueta(t.naoPagantes, ant?.totais.naoPagantes),
        serie: [for (final p in d.serie) (p.naoPagantes ?? 0).toDouble()],
        cor: Cores.ambar,
      ),
      KpiCard(
        titulo: 'Média de passageiros por viagem',
        valor: t.mediaPorViagem == null ? null : fmtDecimal(t.mediaPorViagem!),
        detalhe: t.mediaPorViagem == null ? null : 'só nos dias com bilhetagem (RN03)',
        etiqueta: etiqueta(t.mediaPorViagem, ant?.totais.mediaPorViagem),
        serie: [for (final p in d.serie) p.mediaPorViagem ?? 0],
        cor: Cores.verde,
      ),
    ];

    final series = [
      SerieColunas(nome: 'Pagantes (catraca + antecipados)', valores: [for (final p in d.serie) (p.pagantes ?? 0).toDouble()], cor: Cores.navy),
      SerieColunas(nome: 'Gratuidades', valores: [for (final p in d.serie) (p.naoPagantes ?? 0).toDouble()], cor: Cores.verde),
    ];

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
      Cartao(
        titulo: 'Pagantes × Gratuidades por ${widget.filtros.granularidade.rotulo.toLowerCase()}',
        subtitulo: 'Períodos sem o relatório de passageiros ficam em branco, nunca em zero (RN06)',
        acao: t.total == null ? null : LegendaSeries(series),
        child: t.total == null
            ? const AvisoSemDados(texto: 'Sem bilhetagem importada para o período')
            : GraficoColunas(rotulos: [for (final p in d.serie) rotuloPeriodo(p.periodo)], series: series, altura: 260),
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Média de passageiros por viagem',
        subtitulo: 'Passageiros do período ÷ viagens realizadas nos dias com bilhetagem',
        child: t.mediaPorViagem == null
            ? const AvisoSemDados(texto: 'Sem bilhetagem importada para o período')
            : GraficoColunas(
                rotulos: [for (final p in d.serie) rotuloPeriodo(p.periodo)],
                series: [SerieColunas(nome: 'Por viagem', valores: [for (final p in d.serie) p.mediaPorViagem ?? 0], cor: Cores.verde)],
                formato: fmtDecimal,
                altura: 200,
              ),
      ),
    ];
  }
}
