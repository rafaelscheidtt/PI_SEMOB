import 'package:flutter/material.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/models.dart';

/// Barra superior com o título e os filtros compartilhados: intervalo, granularidade e linha (US05).
class BarraFiltros extends StatelessWidget {
  const BarraFiltros({
    super.key,
    required this.filtros,
    required this.linhas,
    required this.compacto,
    required this.onFiltros,
    this.titulo = 'Gestão Operacional de Transporte Público',
  });

  final FiltrosPainel filtros;
  final List<Linha> linhas;
  final bool compacto;
  final ValueChanged<FiltrosPainel> onFiltros;
  final String titulo;

  Future<void> _escolherIntervalo(BuildContext context) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: filtros.inicio, end: filtros.fim),
      locale: const Locale('pt', 'BR'),
    );
    if (r != null) onFiltros(filtros.copyWith(inicio: r.start, fim: r.end));
  }

  @override
  Widget build(BuildContext context) {
    final botaoIntervalo = OutlinedButton.icon(
      key: const Key('botao-intervalo'),
      onPressed: () => _escolherIntervalo(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Cores.tinta,
        side: const BorderSide(color: Cores.linha),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 15),
      label: Text('${fmtData(filtros.inicio)} – ${fmtData(filtros.fim)}'),
    );
    final seletorGranularidade = SegmentedButton<Granularidade>(
      segments: [for (final g in Granularidade.values) ButtonSegment(value: g, label: Text(g.rotulo))],
      selected: {filtros.granularidade},
      onSelectionChanged: (s) => onFiltros(filtros.copyWith(granularidade: s.first)),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Cores.navy,
        selectedForegroundColor: Colors.white,
        foregroundColor: Cores.texto2,
        side: const BorderSide(color: Cores.linha),
        textStyle: const TextStyle(fontSize: 13),
        visualDensity: VisualDensity.compact,
      ),
    );
    final seletorLinha = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: Cores.linha), borderRadius: BorderRadius.circular(7)),
      child: DropdownButton<String?>(
        key: const Key('seletor-linha'),
        value: filtros.linha,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: const TextStyle(fontSize: 13, color: Cores.tinta),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text('Todas as linhas${linhas.isEmpty ? '' : ' (${linhas.length})'}')),
          for (final l in linhas) DropdownMenuItem<String?>(value: l.codigo, child: Text('${l.codigo} — ${l.nome}')),
        ],
        onChanged: (v) => onFiltros(filtros.copyWith(linha: v, limparLinha: v == null)),
      ),
    );

    final controles = [botaoIntervalo, seletorGranularidade, seletorLinha];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 14 : 28, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Cores.linha))),
      child: compacto
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final c in controles) Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
            ])
          : Row(children: [
              Flexible(
                child: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: controles,
                ),
              ),
            ]),
    );
  }
}
