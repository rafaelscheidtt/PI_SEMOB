import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/filtros.dart';
import '../../core/formatos.dart';
import '../../core/periodo.dart';
import '../../data/models.dart';

/// O que entra no relatório. Cada parte é opcional: só as seções marcadas são consultadas.
class ConteudoRelatorio {
  const ConteudoRelatorio({
    required this.filtros,
    required this.geradoEm,
    this.indicadores,
    this.detalhes,
    this.financeiro,
    this.alertas,
    this.linhas,
    this.geradoPor,
    this.brasao,
  });

  final FiltrosPainel filtros;
  final DateTime geradoEm;
  final Indicadores? indicadores;
  final DetalhesOperacao? detalhes;
  final Financeiro? financeiro;
  final Alertas? alertas;
  final List<ResumoLinha>? linhas;
  final String? geradoPor;

  final Uint8List? brasao;
}

/// Nome sugerido do arquivo: dashmob_2026-09-01_2026-09-30.pdf
String nomeArquivoPdf(FiltrosPainel f) => 'dashmob_${fmtDataApi(f.inicio)}_${fmtDataApi(f.fim)}${f.linha == null ? '' : '_linha-${f.linha}'}.pdf';

const _navy = PdfColor.fromInt(0xFF181949);
const _cinza = PdfColor.fromInt(0xFF6B7280);
const _linha = PdfColor.fromInt(0xFFE6E8EF);

String _periodo(FiltrosPainel f) => f.mesInteiro ? f.descricaoPeriodo : '${fmtData(f.inicio)} a ${fmtData(f.fim)}';

String _semDados(num? v, String Function(num) fmt) => v == null ? 'Sem dados' : fmt(v);

String _variacao(num? atual, num? anterior) {
  final v = variacaoPercentual(atual, anterior);
  if (v == null) return '-';
  return '${v > 0 ? '+' : ''}${fmtDecimal(v)}%';
}

/// Monta o PDF com as seções presentes em [c]. É Dart puro, por isso roda nos testes.
Future<Uint8List> gerarRelatorioPdf(ConteudoRelatorio c) async {
  final doc = pw.Document(title: 'DashMOB - ${_periodo(c.filtros)}', author: 'SEMOB São Caetano do Sul', creator: 'DashMOB');
  final brasao = c.brasao == null ? null : pw.MemoryImage(c.brasao!);
  final titulo = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy);
  final cabecalhoTabela = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _navy);
  const celula = pw.TextStyle(fontSize: 9);

  pw.Widget secao(String nome, List<pw.Widget> filhos) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(height: 14),
        pw.Text(nome, style: titulo),
        pw.Divider(color: _linha, thickness: 0.8),
        ...filhos,
      ]);

  pw.Widget tabela(List<String> cabecalho, List<List<String>> dados, {Map<int, pw.Alignment>? alinhamentos}) => pw.TableHelper.fromTextArray(
        headers: cabecalho,
        data: dados,
        headerStyle: cabecalhoTabela,
        cellStyle: celula,
        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F6FA)),
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _linha, width: 0.5), bottom: pw.BorderSide(color: _linha, width: 0.5)),
        cellAlignments: alinhamentos ?? const {},
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      );

  final direita = {for (var i = 1; i < 8; i++) i: pw.Alignment.centerRight};
  final partes = <pw.Widget>[];

  final ind = c.indicadores;
  if (ind != null) {
    final t = ind.totais;
    final ant = ind.anterior?.totais;
    partes.add(secao('Indicadores do período', [
      if (t == null)
        pw.Text('Sem dados para o período selecionado.', style: celula)
      else
        tabela(['Indicador', 'Período', 'Período anterior', 'Variação'], [
          ['Quilometragem (km)', fmtDecimal(t.kmTotal), _semDados(ant?.kmTotal, fmtDecimal), _variacao(t.kmTotal, ant?.kmTotal)],
          ['Viagens realizadas', fmtInteiro(t.viagens), _semDados(ant?.viagens, fmtInteiro), _variacao(t.viagens, ant?.viagens)],
          ['Viagens programadas', _semDados(t.viagensProgramadas, fmtInteiro), _semDados(ant?.viagensProgramadas, fmtInteiro), _variacao(t.viagensProgramadas, ant?.viagensProgramadas)],
          ['Cumprimento de viagens (FCV)', _semDados(t.fcv, fmtPercentual), _semDados(ant?.fcv, fmtPercentual), _variacao(t.fcv, ant?.fcv)],
          ['Passageiros no total', _semDados(t.total, fmtInteiro), _semDados(ant?.total, fmtInteiro), _variacao(t.total, ant?.total)],
          ['Pagantes', _semDados(t.pagantes, fmtInteiro), _semDados(ant?.pagantes, fmtInteiro), _variacao(t.pagantes, ant?.pagantes)],
          ['Gratuidades', _semDados(t.naoPagantes, fmtInteiro), _semDados(ant?.naoPagantes, fmtInteiro), _variacao(t.naoPagantes, ant?.naoPagantes)],
          ['Média de passageiros por viagem', _semDados(t.mediaPorViagem, fmtDecimal), _semDados(ant?.mediaPorViagem, fmtDecimal), _variacao(t.mediaPorViagem, ant?.mediaPorViagem)],
        ], alinhamentos: direita),
      if (t != null && ind.serie.length > 1) ...[
        pw.SizedBox(height: 8),
        pw.Text('Por ${c.filtros.granularidade.rotulo.toLowerCase()}', style: cabecalhoTabela),
        pw.SizedBox(height: 4),
        tabela(['Período', 'Km', 'Viagens', 'FCV', 'Passageiros', 'Pagantes', 'Gratuidades'], [
          for (final p in ind.serie)
            [rotuloPeriodo(p.periodo), fmtDecimal(p.kmTotal), fmtInteiro(p.viagens), _semDados(p.fcv, fmtPercentual), _semDados(p.total, fmtInteiro), _semDados(p.pagantes, fmtInteiro), _semDados(p.naoPagantes, fmtInteiro)],
        ], alinhamentos: direita),
      ],
    ]));
  }

  final det = c.detalhes;
  if (det != null && (det.turnos.isNotEmpty || det.faixasHorarias.isNotEmpty)) {
    partes.add(secao('Cumprimento de viagens', [
      if (det.turnos.isNotEmpty)
        tabela(['Turno', 'Programadas', 'Realizadas', 'FCV'], [
          for (final t in det.turnos) [t.rotulo, fmtInteiro(t.programadas), fmtInteiro(t.realizadas), _semDados(t.fcv, fmtPercentual)],
        ], alinhamentos: direita),
      if (det.faixasHorarias.isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text('Viagens por faixa horária', style: cabecalhoTabela),
        pw.SizedBox(height: 4),
        tabela(['Faixa', 'Viagens'], [
          for (final f in det.faixasHorarias) ['${f.faixa.toString().padLeft(2, '0')}h', fmtInteiro(f.viagens)],
        ], alinhamentos: direita),
      ],
    ]));
  }

  final fin = c.financeiro;
  if (fin != null) {
    final t = fin.totais;
    final ant = fin.anterior?.totais;
    partes.add(secao('Financeiro (bilhetagem do sistema inteiro)', [
      if (t == null)
        pw.Text('Sem bilhetagem no período selecionado${fin.inicioBilhetagem == null ? '' : ' (a bilhetagem começou em ${fmtData(fin.inicioBilhetagem!)})'}.', style: celula)
      else
        tabela(['Indicador', 'Período', 'Período anterior', 'Variação'], [
          ['Vendas', fmtMoeda(t.vendas), _semDados(ant?.vendas, fmtMoeda), _variacao(t.vendas, ant?.vendas)],
          ['Utilização', fmtMoeda(t.utilizacao), _semDados(ant?.utilizacao, fmtMoeda), _variacao(t.utilizacao, ant?.utilizacao)],
          ['Crédito circulante', fmtMoeda(t.creditoCirculante), _semDados(ant?.creditoCirculante, fmtMoeda), '-'],
          ['Créditos transferidos para cartões', fmtMoeda(t.creditosTransferidos), _semDados(ant?.creditosTransferidos, fmtMoeda), _variacao(t.creditosTransferidos, ant?.creditosTransferidos)],
          ['Saldo de créditos no fim do período', _semDados(t.saldoFinal, fmtMoeda), _semDados(ant?.saldoFinal, fmtMoeda), _variacao(t.saldoFinal, ant?.saldoFinal)],
        ], alinhamentos: direita),
    ]));
  }

  final al = c.alertas;
  if (al != null) {
    partes.add(secao('Alertas (${al.total == 0 ? 'nenhum' : '${al.criticos} críticos, ${al.avisos} avisos'})', [
      if (al.total == 0)
        pw.Text('Nenhum dia fora do padrão no período.', style: celula)
      else
        pw.TableHelper.fromTextArray(
          headers: const ['Data', 'Gravidade', 'Tipo', 'Linha', 'Descrição'],
          data: [for (final a in al.alertas) [fmtData(a.data), a.severidade.rotulo, a.tipoRotulo, a.linha ?? 'Sistema', a.mensagem]],
          headerStyle: cabecalhoTabela,
          cellStyle: celula,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F6FA)),
          border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _linha, width: 0.5), bottom: pw.BorderSide(color: _linha, width: 0.5)),
          columnWidths: const {0: pw.FixedColumnWidth(58), 1: pw.FixedColumnWidth(50), 2: pw.FixedColumnWidth(70), 3: pw.FixedColumnWidth(44), 4: pw.FlexColumnWidth()},
        ),
    ]));
  }

  final linhas = c.linhas;
  if (linhas != null && linhas.isNotEmpty) {
    partes.add(secao('Monitoramento por linha', [
      tabela(['Linha', 'Km', 'Viagens', 'Km por viagem', 'Não realizadas', 'Não iniciadas', 'Não terminadas'], [
        for (final l in linhas)
          ['${l.codigo} ${l.nome}', fmtDecimal(l.kmTotal), fmtInteiro(l.viagens), _semDados(l.kmPorViagem, fmtDecimal), fmtInteiro(l.naoRealizadas), fmtInteiro(l.naoIniciadas), fmtInteiro(l.naoTerminadas)],
      ], alinhamentos: direita),
    ]));
  }

  if (partes.isEmpty) partes.add(pw.Padding(padding: const pw.EdgeInsets.only(top: 20), child: pw.Text('Nenhuma seção selecionada.', style: celula)));

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
    header: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 1.2))),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (brasao != null) pw.Padding(padding: const pw.EdgeInsets.only(right: 10), child: pw.Image(brasao, width: 34, height: 34)),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('DashMOB · Painel de operação do transporte', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.Text('Prefeitura de São Caetano do Sul · Secretaria de Mobilidade Urbana (SEMOB)', style: const pw.TextStyle(fontSize: 9, color: _cinza)),
          ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(_periodo(c.filtros), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.Text(c.filtros.linha == null ? 'Sistema inteiro' : 'Linha ${c.filtros.linha}', style: const pw.TextStyle(fontSize: 9, color: _cinza)),
        ]),
      ]),
    ),
    footer: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Gerado em ${fmtData(c.geradoEm)} às ${c.geradoEm.hour.toString().padLeft(2, '0')}:${c.geradoEm.minute.toString().padLeft(2, '0')}${c.geradoPor == null ? '' : ' por ${c.geradoPor}'} · fonte: relatórios do Smart Report', style: const pw.TextStyle(fontSize: 8, color: _cinza)),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _cinza)),
      ]),
    ),
    build: (ctx) => partes,
  ));
  return doc.save();
}
