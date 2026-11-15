// testes da exportação em PDF (US10): o gerador (Dart puro) e a tela Relatórios
import 'dart:typed_data';

import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:dashmob/features/relatorios/gerador_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  test('US10 o PDF sai com todas as seções e começa com o cabeçalho PDF', () async {
    final bytes = await gerarRelatorioPdf(ConteudoRelatorio(
      filtros: filtrosPadrao,
      geradoEm: DateTime(2026, 11, 5, 14, 30),
      geradoPor: 'Gil Gestor',
      indicadores: comAnterior,
      detalhes: await RepositorioFalso(comDados).detalhes(inicio: filtrosPadrao.inicio, fim: filtrosPadrao.fim),
      financeiro: comFinanceiro,
      alertas: comAlertas,
      linhas: await RepositorioFalso(comDados).resumoPorLinha(inicio: filtrosPadrao.inicio, fim: filtrosPadrao.fim),
    ));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(2000));
    expect(nomeArquivoPdf(filtrosPadrao), 'dashmob_2026-09-01_2026-09-30.pdf');
    expect(nomeArquivoPdf(filtrosPadrao.copyWith(linha: '02')), 'dashmob_2026-09-01_2026-09-30_linha-02.pdf');
  });

  test('US10 sem dados o PDF ainda é gerado, com "Sem dados" em vez de zero (RN06)', () async {
    final bytes = await gerarRelatorioPdf(ConteudoRelatorio(
      filtros: FiltrosPainel(inicio: DateTime(2026, 7, 1), fim: DateTime(2026, 7, 14)),
      geradoEm: DateTime(2026, 11, 5),
      indicadores: Indicadores.vazio,
      financeiro: Financeiro.vazio,
      alertas: Alertas.vazio,
    ));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  testWidgets('US10 a tela Relatórios gera o PDF com as seções marcadas e entrega o arquivo', (tester) async {
    janela(tester, 1400);
    Uint8List? recebido;
    String? nome;
    final repo = RepositorioFalso(comAnterior);
    await tester.pumpWidget(app(repo, tela: Tela.relatorios, salvarPdf: (b, n) async {
      recebido = b;
      nome = n;
    }));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tela-relatorios')), findsOneWidget);
    expect(find.text('Arquivo: dashmob_2026-09-01_2026-09-30.pdf'), findsOneWidget);

    await tester.tap(find.byKey(const Key('secao-financeiro'))); // desmarca o financeiro
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pdf-gerar')));
    await tester.pumpAndSettle();
    expect(nome, 'dashmob_2026-09-01_2026-09-30.pdf');
    expect(recebido, isNotNull);
    expect(String.fromCharCodes(recebido!.take(4)), '%PDF');
    expect(repo.consultasFinanceiro, 0); // seção desmarcada não é consultada
    expect(repo.consultas, 1);
    expect(find.byKey(const Key('pdf-resultado')), findsOneWidget);
  });

  testWidgets('US10 sem nenhuma seção marcada o botão fica desativado', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.relatorios));
    await tester.pumpAndSettle();
    for (final s in ['indicadores', 'cumprimento', 'financeiro', 'alertas', 'linhas']) {
      await tester.tap(find.byKey(Key('secao-$s')));
    }
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('pdf-gerar'))).onPressed, isNull);
  });

  testWidgets('US06 Relatórios cabe numa tela de celular', (tester) async {
    janela(tester, 390);
    await tester.pumpWidget(app(RepositorioFalso(comDados), tela: Tela.relatorios));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pdf-gerar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
