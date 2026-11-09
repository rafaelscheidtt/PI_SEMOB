import 'package:flutter/material.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/models.dart';

/// Barra superior com o título e os filtros que valem para a tela inteira: intervalo e linha (US05).
/// A granularidade (dia, semana, mês) só muda os gráficos, por isso fica junto deles ([SeletorGranularidade]).
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
        side: BorderSide(color: Cores.linha),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 15),
      label: Text('${fmtData(filtros.inicio)} – ${fmtData(filtros.fim)}'),
    );
    final seletorLinha = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: Cores.linha), borderRadius: BorderRadius.circular(7)),
      child: DropdownButton<String?>(
        key: const Key('seletor-linha'),
        value: filtros.linha,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: TextStyle(fontSize: 13, color: Cores.tinta),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text('Todas as linhas${linhas.isEmpty ? '' : ' (${linhas.length})'}')),
          for (final l in linhas) DropdownMenuItem<String?>(value: l.codigo, child: Text('${l.codigo} — ${l.nome}')),
          // linha escolhida antes de a lista chegar da API (ou fora dela): continua selecionável
          if (filtros.linha != null && !linhas.any((l) => l.codigo == filtros.linha))
            DropdownMenuItem<String?>(value: filtros.linha, child: Text('Linha ${filtros.linha}')),
        ],
        onChanged: (v) => onFiltros(filtros.copyWith(linha: v, limparLinha: v == null)),
      ),
    );

    final controles = [botaoIntervalo, seletorLinha];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 14 : 28, vertical: 12),
      decoration: BoxDecoration(color: Cores.superficie, border: Border(bottom: BorderSide(color: Cores.linha))),
      child: compacto
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final c in controles) Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
            ])
          : Row(children: [
              // o título ocupa só o que precisa; os filtros ficam encostados na direita
              Expanded(
                child: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: controles,
                  ),
                ),
              ),
            ]),
    );
  }
}

/// Seletor de granularidade dos gráficos (RN01): diária, semanal ou mensal.
/// Fica em cima dos gráficos, porque os cartões de indicador mostram o total do período e não mudam com ele.
class SeletorGranularidade extends StatelessWidget {
  const SeletorGranularidade({super.key, required this.granularidade, required this.onChanged});

  final Granularidade granularidade;
  final ValueChanged<Granularidade> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Granularidade>(
      key: const Key('seletor-granularidade'),
      segments: [for (final g in Granularidade.values) ButtonSegment(value: g, label: Text(g.rotulo))],
      selected: {granularidade},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Cores.destaque,
        selectedForegroundColor: Cores.sobreDestaque,
        foregroundColor: Cores.texto2,
        side: BorderSide(color: Cores.linha),
        textStyle: const TextStyle(fontSize: 13),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Linha "Gráficos por período" com o [SeletorGranularidade], colocada logo acima dos gráficos de cada tela.
class CabecalhoGraficos extends StatelessWidget {
  const CabecalhoGraficos({super.key, required this.granularidade, required this.onChanged, this.texto = 'Gráficos por período'});

  final Granularidade granularidade;
  final ValueChanged<Granularidade>? onChanged;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final seletor = onChanged == null ? null : SeletorGranularidade(granularidade: granularidade, onChanged: onChanged!);
    return LayoutBuilder(builder: (context, c) {
      final titulo = Text(texto, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Cores.tinta));
      if (seletor == null) return titulo;
      if (c.maxWidth < 480) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titulo, const SizedBox(height: 8), seletor]);
      }
      return Row(children: [Expanded(child: titulo), seletor]);
    });
  }
}
