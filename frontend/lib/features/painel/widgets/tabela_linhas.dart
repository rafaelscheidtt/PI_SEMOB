import 'package:flutter/material.dart';

import '../../../core/formatos.dart';
import '../../../core/tema.dart';
import '../../../data/models.dart';
import 'cartao.dart';

/// Tabela de monitoramento por linha (km, viagens, participação e ocorrências), com linha de total.
class TabelaLinhas extends StatelessWidget {
  const TabelaLinhas({super.key, required this.linhas, this.onSelecionar});

  final List<ResumoLinha> linhas;
  final ValueChanged<ResumoLinha>? onSelecionar;

  static const _cabecalho = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Cores.texto2);
  static const _celula = TextStyle(fontSize: 13, color: Cores.tinta);
  static const _total = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Cores.tinta);

  @override
  Widget build(BuildContext context) {
    final kmSistema = linhas.fold<double>(0, (a, l) => a + l.kmTotal);
    final viagensSistema = linhas.fold<int>(0, (a, l) => a + l.viagens);
    final naoRealizadas = linhas.fold<int>(0, (a, l) => a + l.naoRealizadas);
    final outras = linhas.fold<int>(0, (a, l) => a + l.naoIniciadas + l.naoTerminadas);

    DataCell numero(String t, {bool total = false}) => DataCell(Align(alignment: Alignment.centerRight, child: Text(t, style: total ? _total : _celula)));
    DataColumn coluna(String t, {bool numerica = false}) => DataColumn(label: Text(t.toUpperCase(), style: _cabecalho), numeric: numerica);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabela-linhas'),
        columnSpacing: 20,
        horizontalMargin: 10,
        headingRowHeight: 36,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48,
        dividerThickness: 0.6,
        showCheckboxColumn: false,
        columns: [
          coluna('Linha'),
          coluna('Km rodados', numerica: true),
          coluna('Viagens', numerica: true),
          coluna('Km/viagem', numerica: true),
          coluna('Part. da oferta', numerica: true),
          coluna('Não realizadas', numerica: true),
          coluna('Não iniciadas / não terminadas', numerica: true),
        ],
        rows: [
          for (final l in linhas)
            DataRow(
              onSelectChanged: onSelecionar == null ? null : (_) => onSelecionar!(l),
              cells: [
                DataCell(Row(key: Key('linha-${l.codigo}'), mainAxisSize: MainAxisSize.min, children: [
                  CodigoLinha(l.codigo),
                  const SizedBox(width: 8),
                  Text(l.nome, style: _celula),
                ])),
                numero(fmtDecimal(l.kmTotal)),
                numero(fmtInteiro(l.viagens)),
                numero(l.kmPorViagem == null ? '—' : fmtDecimal(l.kmPorViagem!)),
                numero(viagensSistema == 0 ? '—' : '${fmtDecimal(l.viagens / viagensSistema * 100)}%'),
                numero(l.naoRealizadas == 0 ? '—' : fmtInteiro(l.naoRealizadas)),
                numero(l.naoIniciadas + l.naoTerminadas == 0 ? '—' : fmtInteiro(l.naoIniciadas + l.naoTerminadas)),
              ],
            ),
          DataRow(
            color: const WidgetStatePropertyAll(Cores.fundo),
            cells: [
              DataCell(Text('Total · ${linhas.length} linhas', style: _total)),
              numero(fmtDecimal(kmSistema), total: true),
              numero(fmtInteiro(viagensSistema), total: true),
              numero(viagensSistema == 0 ? '—' : fmtDecimal(kmSistema / viagensSistema), total: true),
              numero('100%', total: true),
              numero(fmtInteiro(naoRealizadas), total: true),
              numero(fmtInteiro(outras), total: true),
            ],
          ),
        ],
      ),
    );
  }
}
