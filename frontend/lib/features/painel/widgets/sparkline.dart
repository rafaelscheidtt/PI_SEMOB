import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/tema.dart';

/// Linha pequena com a tendência da série, sem eixos, usada dentro dos cartões de indicador.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.valores, this.cor = Cores.navy, this.altura = 34});

  final List<double> valores;
  final Color cor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (valores.length < 2) return SizedBox(height: altura);
    var maior = 0.0;
    for (final v in valores) {
      if (v > maior) maior = v;
    }
    return SizedBox(
      height: altura,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (valores.length - 1).toDouble(),
          minY: 0,
          maxY: maior <= 0 ? 1 : maior * 1.1,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < valores.length; i++) FlSpot(i.toDouble(), valores[i])],
              isCurved: true,
              curveSmoothness: 0.25,
              color: cor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: cor.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
