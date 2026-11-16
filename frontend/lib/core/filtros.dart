import 'package:intl/intl.dart';

import 'formatos.dart';
import 'periodo.dart';

/// Filtros escolhidos na barra superior e compartilhados por todas as telas.
class FiltrosPainel {
  const FiltrosPainel({required this.inicio, required this.fim, this.granularidade = Granularidade.dia, this.linha});

  final DateTime inicio;
  final DateTime fim;
  final Granularidade granularidade;

  final String? linha;

  factory FiltrosPainel.padrao([DateTime? hoje]) {
    final h = hoje ?? DateTime.now();
    final fim = DateTime(h.year, h.month, h.day);
    return FiltrosPainel(inicio: fim.subtract(const Duration(days: 29)), fim: fim);
  }

  FiltrosPainel copyWith({DateTime? inicio, DateTime? fim, Granularidade? granularidade, String? linha, bool limparLinha = false}) =>
      FiltrosPainel(
        inicio: inicio ?? this.inicio,
        fim: fim ?? this.fim,
        granularidade: granularidade ?? this.granularidade,
        linha: limparLinha ? null : (linha ?? this.linha),
      );

  bool get mesInteiro =>
      inicio.day == 1 && inicio.year == fim.year && inicio.month == fim.month && fim.day == DateTime(fim.year, fim.month + 1, 0).day;

  String get descricaoPeriodo {
    if (mesInteiro) {
      final nome = DateFormat('MMMM', 'pt_BR').format(inicio);
      return '${nome[0].toUpperCase()}${nome.substring(1)} de ${inicio.year}';
    }
    return '${fmtData(inicio)} – ${fmtData(fim)}';
  }

  @override
  bool operator ==(Object other) =>
      other is FiltrosPainel &&
      other.inicio == inicio &&
      other.fim == fim &&
      other.granularidade == granularidade &&
      other.linha == linha;

  @override
  int get hashCode => Object.hash(inicio, fim, granularidade, linha);
}

/// Nome curto de um período anterior para a etiqueta de variação: "vs. jul." ou "vs. anterior".
String rotuloComparacao(DateTime inicio, DateTime fim) {
  final mesInteiro = inicio.day == 1 && inicio.year == fim.year && inicio.month == fim.month && fim.day == DateTime(fim.year, fim.month + 1, 0).day;
  if (mesInteiro) return 'vs. ${DateFormat('MMM', 'pt_BR').format(inicio)}';
  return 'vs. anterior';
}
