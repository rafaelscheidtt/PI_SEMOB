import 'package:flutter/material.dart';

import '../../../core/formatos.dart';
import '../../../core/tema.dart';
import 'cartao.dart';
import 'sparkline.dart';

/// Cartão de indicador: rótulo, valor grande, linha de detalhe e tendência.
/// Exibe "Sem dados" quando o valor é nulo (RN06).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.unidade,
    this.detalhe,
    this.variacao,
    this.rotuloVariacao = 'vs. anterior',
    this.etiqueta,
    this.serie = const [],
    this.cor = Cores.navy,
  });

  final String titulo;

  /// Valor já formatado; `null` quando não há dado.
  final String? valor;
  final String? unidade;

  /// Texto pequeno abaixo do valor ("261.887 km produtiva · 5,0% improdutiva").
  final String? detalhe;

  /// Variação percentual em relação ao período anterior; `null` esconde a etiqueta.
  final double? variacao;
  final String rotuloVariacao;

  /// Etiqueta personalizada, no lugar da variação (ex.: "72,5% do total").
  final Widget? etiqueta;
  final List<double> serie;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final etiquetaVariacao = etiqueta ?? (variacao == null || valor == null ? null : EtiquetaVariacao(variacao!, rotulo: rotuloVariacao));
    return Cartao(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Rotulo(titulo)),
            if (etiquetaVariacao != null) ...[const SizedBox(width: 6), etiquetaVariacao],
          ]),
          const SizedBox(height: 6),
          if (valor == null)
            Text('Sem dados', key: Key('kpi-$titulo'), style: tema.titleMedium?.copyWith(color: Cores.texto2))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    valor!,
                    key: Key('kpi-$titulo'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Cores.tinta, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unidade != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(unidade!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Cores.texto2)),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            valor == null ? 'Nenhum registro no período' : (detalhe ?? ''),
            style: tema.bodySmall?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Sparkline(valores: valor == null ? const [] : serie, cor: cor),
        ],
      ),
    );
  }
}

/// Etiqueta "+4,9% vs. jul." verde para alta, vermelha para queda, cinza quando não muda.
class EtiquetaVariacao extends StatelessWidget {
  const EtiquetaVariacao(this.variacao, {super.key, this.rotulo = 'vs. anterior', this.quedaEBoa = false});

  final double variacao;
  final String rotulo;

  /// Para indicadores em que cair é bom (ocorrências), inverte as cores.
  final bool quedaEBoa;

  @override
  Widget build(BuildContext context) {
    final sinal = variacao > 0 ? '+' : (variacao < 0 ? '−' : '');
    final texto = '$sinal${fmtDecimal(variacao.abs())}% $rotulo';
    if (variacao.abs() < 0.05) return Etiqueta(texto);
    final subiu = variacao > 0;
    final bom = quedaEBoa ? !subiu : subiu;
    return Etiqueta(texto, tom: bom ? TomEtiqueta.ok : TomEtiqueta.negativo);
  }
}
