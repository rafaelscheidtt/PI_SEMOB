import 'package:flutter/material.dart';

import '../../../core/formatos.dart';
import '../../../core/periodo.dart';
import '../../../data/models.dart';

/// Barra de filtros: granularidade, intervalo de datas e linha (US05).
class Filtros extends StatelessWidget {
  const Filtros({
    super.key,
    required this.granularidade,
    required this.inicio,
    required this.fim,
    required this.linhas,
    required this.linha,
    required this.compacto,
    required this.onGranularidade,
    required this.onIntervalo,
    required this.onLinha,
  });

  final Granularidade granularidade;
  final DateTime inicio;
  final DateTime fim;
  final List<Linha> linhas;
  final String? linha;
  final bool compacto;
  final ValueChanged<Granularidade> onGranularidade;
  final void Function(DateTime inicio, DateTime fim) onIntervalo;
  final ValueChanged<String?> onLinha;

  Future<void> _escolherIntervalo(BuildContext context) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: inicio, end: fim),
      locale: const Locale('pt', 'BR'),
    );
    if (r != null) onIntervalo(r.start, r.end);
  }

  @override
  Widget build(BuildContext context) {
    final seletorGranularidade = SegmentedButton<Granularidade>(
      segments: [for (final g in Granularidade.values) ButtonSegment(value: g, label: Text(g.rotulo))],
      selected: {granularidade},
      onSelectionChanged: (s) => onGranularidade(s.first),
      showSelectedIcon: false,
    );
    final botaoIntervalo = OutlinedButton.icon(
      key: const Key('botao-intervalo'),
      onPressed: () => _escolherIntervalo(context),
      icon: const Icon(Icons.date_range, size: 18),
      label: Text('${fmtData(inicio)} – ${fmtData(fim)}'),
    );
    final seletorLinha = DropdownButton<String?>(
      key: const Key('seletor-linha'),
      value: linha,
      hint: const Text('Todas as linhas'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todas as linhas')),
        for (final l in linhas) DropdownMenuItem<String?>(value: l.codigo, child: Text('${l.codigo} — ${l.nome}')),
      ],
      onChanged: onLinha,
    );

    final itens = [seletorGranularidade, botaoIntervalo, seletorLinha];
    return compacto
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final i in itens) Padding(padding: const EdgeInsets.only(bottom: 8), child: i)])
        : Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: itens);
  }
}
