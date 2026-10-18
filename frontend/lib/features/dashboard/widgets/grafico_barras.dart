import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatos.dart';
import '../../../core/periodo.dart';
import '../../../data/models.dart';

/// Gráfico de barras de um indicador ao longo dos períodos.
class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.serie,
    required this.granularidade,
    required this.valor,
    required this.titulo,
  });

  final List<PontoIndicador> serie;
  final Granularidade granularidade;
  final double Function(PontoIndicador) valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    final maximo = serie.map(valor).fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maximo == 0 ? 1 : maximo * 1.15,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (v, _) => Text(fmtInteiro(v), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= serie.length) return const SizedBox.shrink();
                          // evita sobreposição de rótulos em séries longas
                          final passo = (serie.length / 10).ceil().clamp(1, 31);
                          if (i % passo != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(rotuloPeriodo(serie[i].periodo, granularidade), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (grupo, _, rod, __) => BarTooltipItem(
                        '${rotuloPeriodo(serie[grupo.x].periodo, granularidade)}\n${fmtDecimal(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < serie.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(toY: valor(serie[i]), color: cor, width: serie.length > 20 ? 6 : 14,
                            borderRadius: BorderRadius.circular(2)),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
