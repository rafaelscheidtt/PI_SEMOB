import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// Alertas: dias fora do padrão no período (US08, RN09 a RN11), agrupados por data.
class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key, required this.filtros, required this.repository});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  Alertas? _dados;
  String? _erro;
  bool _carregando = true;
  _Filtro _filtro = _Filtro.todos;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(AlertasPage anterior) {
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
      final a = await widget.repository.alertas(inicio: f.inicio, fim: f.fim, linha: f.linha);
      if (!mounted || f != widget.filtros) return;
      setState(() => _dados = a);
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
            titulo: 'Alertas',
            subtitulo: '${f.descricaoPeriodo}${f.linha == null ? '' : ' · linha ${f.linha}'} · cumprimento baixo, desvio do histórico e excesso de ocorrências',
          ),
          const SizedBox(height: 18),
          if (_erro != null) MensagemErro(_erro!),
          if (_carregando) const Carregando(),
          if (!_carregando && _erro == null && d != null) ..._corpo(faixa, d),
        ]),
      );
    });
  }

  List<Widget> _corpo(FaixaLargura faixa, Alertas d) {
    final cartoes = [
      KpiCard(
        titulo: 'Críticos',
        valor: fmtInteiro(d.criticos),
        detalhe: d.criticos == 0 ? 'nenhum desvio grave no período' : 'cumprimento abaixo de 90% ou desvio acima de 35%',
        cor: Cores.vermelho,
      ),
      KpiCard(
        titulo: 'Avisos',
        valor: fmtInteiro(d.avisos),
        detalhe: d.avisos == 0 ? 'nenhum aviso no período' : 'cumprimento abaixo de 95% ou desvio acima de 20%',
        cor: Cores.ambar,
      ),
      KpiCard(
        titulo: 'Dias fora do padrão',
        valor: fmtInteiro(d.diasComAlerta),
        detalhe: 'dias com pelo menos um alerta',
        cor: Cores.destaque,
      ),
    ];
    final visiveis = d.alertas.where(_filtro.aceita).toList();
    return [
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: faixa == FaixaLargura.compacto ? 1 : 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 158,
        ),
        children: cartoes,
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Dias com desvio',
        subtitulo: 'Cumprimento baixo, movimento fora do padrão do mesmo dia da semana ou ocorrências acima do normal',
        acao: d.total == 0 ? null : _seletorFiltro(),
        child: d.total == 0
            ? const AvisoSemDados(texto: 'Nenhum alerta no período: a operação ficou dentro do padrão')
            : visiveis.isEmpty
                ? const AvisoSemDados(texto: 'Nenhum alerta com esse filtro')
                : _Lista(alertas: visiveis, compacto: faixa == FaixaLargura.compacto),
      ),
    ];
  }

  Widget _seletorFiltro() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_Filtro>(
        key: const Key('alertas-filtro'),
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: _Filtro.todos, label: Text('Todos')),
          ButtonSegment(value: _Filtro.criticos, label: Text('Críticos')),
          ButtonSegment(value: _Filtro.avisos, label: Text('Avisos')),
        ],
        selected: {_filtro},
        onSelectionChanged: (s) => setState(() => _filtro = s.first),
      ),
    );
  }
}

enum _Filtro {
  todos,
  criticos,
  avisos;

  bool aceita(Alerta a) => switch (this) {
        todos => true,
        criticos => a.severidade == Severidade.critico,
        avisos => a.severidade == Severidade.aviso,
      };
}

class _Lista extends StatelessWidget {
  const _Lista({required this.alertas, required this.compacto});

  final List<Alerta> alertas;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final porDia = <DateTime, List<Alerta>>{};
    for (final a in alertas) {
      porDia.putIfAbsent(a.data, () => []).add(a);
    }
    final diaSemana = DateFormat('EEEE', 'pt_BR');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final entrada in porDia.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            '${fmtData(entrada.key)} · ${diaSemana.format(entrada.key)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cores.texto2, letterSpacing: 0.4),
          ),
        ),
        for (final a in entrada.value) _ItemAlerta(alerta: a, compacto: compacto),
      ],
    ]);
  }
}

class _ItemAlerta extends StatelessWidget {
  const _ItemAlerta({required this.alerta, required this.compacto});

  final Alerta alerta;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final critico = alerta.severidade == Severidade.critico;
    final cor = critico ? Cores.vermelho : Cores.ambar;
    final etiquetas = Wrap(spacing: 6, runSpacing: 4, children: [
      Etiqueta(alerta.severidade.rotulo, tom: critico ? TomEtiqueta.negativo : TomEtiqueta.aviso),
      Etiqueta(alerta.tipoRotulo, tom: TomEtiqueta.info),
      if (alerta.linha != null) Etiqueta('Linha ${alerta.linha}'),
    ]);
    final mensagem = Text(alerta.mensagem, key: Key('alerta-${alerta.data.toIso8601String().substring(0, 10)}-${alerta.indicador}'), style: TextStyle(fontSize: 13.5, color: Cores.tinta));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Cores.linha))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 10),
          child: Container(width: 9, height: 9, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        ),
        Expanded(
          child: compacto
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [mensagem, const SizedBox(height: 6), etiquetas])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: mensagem), const SizedBox(width: 12), etiquetas]),
        ),
      ]),
    );
  }
}
