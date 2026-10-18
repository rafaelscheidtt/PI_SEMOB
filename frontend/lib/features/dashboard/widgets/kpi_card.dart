import 'package:flutter/material.dart';

/// Cartão de indicador (KPI). Exibe "Sem dados" quando o valor é nulo (RN06).
class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.titulo, required this.valor, this.unidade, this.icone});

  final String titulo;
  final String? valor;
  final String? unidade;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              if (icone != null) ...[Icon(icone, size: 18, color: tema.colorScheme.primary), const SizedBox(width: 6)],
              Expanded(child: Text(titulo, style: tema.textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Text(
              valor ?? 'Sem dados',
              key: Key('kpi-$titulo'),
              style: valor == null
                  ? tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.outline)
                  : tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (unidade != null && valor != null)
              Text(unidade!, style: tema.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
