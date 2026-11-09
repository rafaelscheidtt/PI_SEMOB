import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatos.dart';
import '../../../core/tema.dart';

/// Uma série do gráfico de colunas. Com mais de uma série, as colunas ficam empilhadas.
class SerieColunas {
  const SerieColunas({required this.nome, required this.valores, required this.cor});

  final String nome;
  final List<double> valores;
  final Color cor;
}

/// Gráfico de colunas (simples ou empilhado) com rótulos no eixo e tooltip.
class GraficoColunas extends StatelessWidget {
  const GraficoColunas({
    super.key,
    required this.rotulos,
    required this.series,
    this.altura = 240,
    this.formato,
    this.maximoY,
    this.minimoY,
  });

  final List<String> rotulos;
  final List<SerieColunas> series;
  final double altura;

  /// Formatação dos valores no eixo e no tooltip (padrão: inteiro).
  final String Function(double)? formato;

  /// Teto fixo do eixo (ex.: 100 para percentuais); sem ele, 15% acima do maior valor.
  final double? maximoY;

  /// Piso do eixo. Útil quando os valores variam pouco (FCV entre 97% e 99%): as colunas
  /// começam no piso e a diferença entre elas fica visível. Veja [pisoDoEixo].
  final double? minimoY;

  double _valor(SerieColunas s, int i) => i < s.valores.length ? s.valores[i] : 0;

  @override
  Widget build(BuildContext context) {
    final n = rotulos.length;
    final fmt = formato ?? fmtInteiro;
    var maximo = 0.0;
    for (var i = 0; i < n; i++) {
      var soma = 0.0;
      for (final s in series) {
        soma += _valor(s, i);
      }
      if (soma > maximo) maximo = soma;
    }
    final passo = (n / 10).ceil().clamp(1, 31);
    final largura = n > 40 ? 4.0 : (n > 20 ? 7.0 : 16.0);

    return SizedBox(
      height: altura,
      child: BarChart(
        BarChartData(
          maxY: maximoY ?? (maximo == 0 ? 1 : maximo * 1.15),
          minY: minimoY ?? 0,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Cores.linha, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(fmt(v), style: TextStyle(fontSize: 10, color: Cores.texto2), textAlign: TextAlign.right),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= n || i % passo != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(rotulos[i], style: TextStyle(fontSize: 10, color: Cores.texto2)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (grupo, _, rod, __) {
                final i = grupo.x;
                final linhas = [
                  for (final s in series) '${s.nome}: ${fmt(_valor(s, i))}',
                ];
                return BarTooltipItem(
                  '${rotulos[i]}\n${linhas.join('\n')}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < n; i++) _grupo(i, largura),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _grupo(int i, double largura) {
    final piso = minimoY ?? 0;
    if (series.length == 1) {
      final v = _valor(series.first, i);
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(fromY: piso, toY: v < piso ? piso : v, color: series.first.cor, width: largura, borderRadius: BorderRadius.circular(2)),
      ]);
    }
    var acumulado = 0.0;
    final pilha = <BarChartRodStackItem>[];
    for (final s in series) {
      final v = _valor(s, i);
      pilha.add(BarChartRodStackItem(acumulado, acumulado + v, s.cor));
      acumulado += v;
    }
    return BarChartGroupData(x: i, barRods: [
      BarChartRodData(toY: acumulado, color: Colors.transparent, width: largura, borderRadius: BorderRadius.circular(2), rodStackItems: pilha),
    ]);
  }
}

/// Legenda com uma bolinha colorida por série.
class LegendaSeries extends StatelessWidget {
  const LegendaSeries(this.series, {super.key});

  final List<SerieColunas> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final s in series)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: s.cor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Flexible(child: Text(s.nome, style: TextStyle(fontSize: 12, color: Cores.texto2), overflow: TextOverflow.ellipsis)),
          ]),
      ],
    );
  }
}

/// Piso para o eixo de um gráfico que varia pouco (FCV entre 99,6% e 99,9%, por exemplo):
/// começa um pouco abaixo do menor valor, deixando como folga a própria variação observada,
/// arredondado para um passo redondo (0,5, 1 ou 5 conforme a amplitude), nunca abaixo de zero.
/// Ex.: 99,66..99,92 -> 99,0 · 97,5..99,1 -> 95 · 82..99 -> 65 · 12..50 -> 0.
double pisoDoEixo(Iterable<double> valores, {double teto = 100}) {
  final validos = valores.where((v) => v > 0).toList();
  if (validos.isEmpty) return 0;
  final menor = validos.reduce((a, b) => a < b ? a : b);
  final maior = validos.reduce((a, b) => a > b ? a : b);
  final amplitude = maior - menor;
  final folga = amplitude < 0.2 ? 0.2 : amplitude;
  final passo = amplitude < 1 ? 0.5 : (amplitude < 5 ? 1.0 : 5.0);
  final piso = ((menor - folga) / passo).floor() * passo;
  return piso.clamp(0.0, teto - passo).toDouble();
}
